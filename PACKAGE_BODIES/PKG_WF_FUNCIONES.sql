--------------------------------------------------------
--  DDL for Package Body PKG_WF_FUNCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WF_FUNCIONES" as

    /*Codigo de Error - Manejo de Errores de Workflow*/
    g_nmro_error number := -20999;

    /*Funcion Privada - Manejo de Errores de Workflow*/
   function fnc_wf_error( p_value in boolean
                         , p_mensaje in varchar2 )
    return varchar2
    is
    begin
        if( not p_value ) then
            raise_application_error( g_nmro_error , p_mensaje );
        end if;
        return 'S';
    end fnc_wf_error;

    /*Valida la tarea Pre-liquidar del Flujo de Liquidacion*/
    function fnc_vl_tarea_preliquidar( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    return varchar2
    is
        v_count  number;
        v_result varchar2(1);
    begin

        select count(*)
          into v_count
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro   in ( 'P' , 'L');

        return fnc_wf_error( p_value   => (v_count > 0)
                           , p_mensaje => 'No se puede continuar , Ya que no se encuentra predios preliquidados.' );

    end fnc_vl_tarea_preliquidar;

    /*Valida la tarea Criticas Pre-Liquidaci?n del Flujo de Liquidacion*/
    function fnc_vl_tarea_liquidar( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    return varchar2
    is
        v_count  number;
        v_result varchar2(1);
    begin

        select count(*)
          into v_count
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = 'L';

        return fnc_wf_error( p_value   => (v_count > 0)
                           , p_mensaje => 'No se puede continuar , Ya que no se encuentra predios liquidados.' );

    end fnc_vl_tarea_liquidar;

    /*Funcion para validar si existe el acto en un documento juridico*/
    function fnc_vl_acto(p_id_acto in gn_g_actos.id_acto%type)
    return varchar2
    is
        v_id_acto gn_g_actos.id_acto%type;
    begin
        select id_acto
          into v_id_acto
          from gn_g_actos
         where id_acto = p_id_acto
           and id_dcmnto is not null;
           --and file_name is not null;

        return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Para continuar, debe generar el acto correspondiente a la etapa.' );

    end fnc_vl_acto;
    
    --ALC
   /*
    Funcion para validar si el acto ya fue notificado 
    */
    function fnc_vl_notificacion_acto_cobro(p_cdgo_clnte         in number,
                                          p_id_fljo_trea       in number,
                                          p_id_instncia_fljo   in number) return varchar2 as

  v_id_prcsos_jrdco number;
  v_drcion              number;
  v_cntdor              number  := 0;
  v_undad_drcion        varchar2(30);
  v_dia_tpo             varchar2(10);
  v_fcha_fnal           timestamp;

  begin

    --Se obtiene la solicitud de saldo a favor
    begin
        select a.id_prcsos_jrdco
        into v_id_prcsos_jrdco
        from cb_g_procesos_juridico a
        where id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                 p_mensaje => 'No se pudo obtener la solicitud');
    end;

    --Se recorren todos los actos de la solicitud
    for acto_tipo in (select   a.dscrpcion,
                               a.id_acto_tpo,
                               a.indcdor_ntfccion,
                               d.fcha_ntfccion,
                               d.id_acto
                        from gn_d_actos_tipo                    a
                        inner join gn_d_actos_tipo_tarea        b   on  a.id_acto_tpo = b.id_acto_tpo
                        inner join cb_g_procesos_jrdco_dcmnto   c   on  a.id_acto_tpo = c.id_acto_tpo
                        left  join gn_g_actos                   d   on  c.id_acto     = d.id_acto
                        where a.cdgo_clnte = p_cdgo_clnte
                        and c.id_prcsos_jrdco = v_id_prcsos_jrdco
                        and b.id_fljo_trea = p_id_fljo_trea) loop

        v_cntdor := v_cntdor + 1;

        if acto_tipo.indcdor_ntfccion = 'S' and acto_tipo.fcha_ntfccion is not null then

            --Se obtiene termino del acto
            begin
                select undad_drcion,
                       drcion,
                       dia_tpo
                into  v_undad_drcion,
                      v_drcion,
                      v_dia_tpo
                from gn_d_actos_tipo_tarea
                where id_acto_tpo = acto_tipo.id_acto_tpo
                and id_fljo_trea = p_id_fljo_trea;
                    exception
                        when no_data_found then
                            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                                , p_mensaje => 'NO SE ENCONTRO PARAMETRIZADO EL ACTO ' || acto_tipo.dscrpcion || ' EN LA ETAPA DEL FLUJO EN LA QUE SE ENCUENTRA');
                        when others then
                            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                                , p_mensaje => 'PROBLEMA AL OBTENER EL TEMINO DEL ACTO');
            end;

            --Se obtiene la fecha final
            begin
                v_fcha_fnal :=  pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_fecha_inicial  => acto_tipo.fcha_ntfccion,
                                                                      p_undad_drcion   => v_undad_drcion,
                                                                      p_drcion         => v_drcion,
                                                                      p_dia_tpo        => v_dia_tpo);

                if v_fcha_fnal is not null then
                    if trunc(systimestamp) >= trunc(v_fcha_fnal) then
                        return 'S';
                    else
                        select
                        case v_undad_drcion
                            when 'MN' then 'MINUTOS'
                            when 'HR' then 'HORA'
                            when 'DI' then 'DIAS'
                            when 'SM' then 'SEMANA'
                            when 'MS' then 'MES'
                        end
                        into v_undad_drcion
                        from dual;

                        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                            p_mensaje => 'que el acto ' || lower(acto_tipo.dscrpcion) || ' cumpla el termino de ' || v_drcion ||' '|| lower(v_undad_drcion) ||','|| ' fecha del termino ' || to_char(trunc(v_fcha_fnal), 'dd/mm/yyyy'));
                    end if;
                else

                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'PROBLEMA AL CALCULAR LA FECHA DEL TERMINO DE NOTIFICACI?, VERIFIQUE LA DURACI? DEL ACTO');
                end if;

            exception
                when others then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => sqlerrm);
            end;

        elsif acto_tipo.indcdor_ntfccion = 'S' and acto_tipo.fcha_ntfccion is null then

            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                 p_mensaje => 'notifique ' || lower(acto_tipo.dscrpcion) );

        elsif acto_tipo.indcdor_ntfccion = 'N' then -- el acto no es notificable, sale OK 16/03/2022
            return 'S';
        end if;

    end loop;

    if v_cntdor = 0 then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'No se encontro parametrizado acto en la tarea');
    end if;

  end fnc_vl_notificacion_acto_cobro;

    /*Funcion para validar si existe el acto en un documento juridico*/
    function fnc_vl_acto( p_id_instncia_fljo in number,
                          p_id_fljo_trea     in number )
    return varchar2
    is
        v_id_acto gn_g_actos.id_acto%type;
    begin
        --return 'S';
        select c.id_acto
          into v_id_acto
          from cb_g_procesos_juridico a
          join cb_g_procesos_jrdco_dcmnto b
            on b.id_prcsos_jrdco = a.id_prcsos_jrdco
          join gn_g_actos c
            on c.id_acto = b.id_acto
         where a.id_instncia_fljo = p_id_instncia_fljo
           and b.id_fljo_trea     = p_id_fljo_trea
           and c.id_dcmnto    is not null;
           --and c.file_name  is not null;

        return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Para continuar, debe generar el acto correspondiente a la etapa.' );

    end fnc_vl_acto;

    function fnc_vl_acto_requerido_ntfcdo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                           p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
    return varchar2
    is

    v_id_acto_tpo_rqrdo     gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_id_prcsos_jrdco       cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_id_acto               cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_indcdor_ntfccion      gn_g_actos.indcdor_ntfccion%type;

    begin

        --- buscamos el tipo de acto requerido de la tarea ----
        select id_acto_tpo_rqrdo
          into v_id_acto_tpo_rqrdo
          from gn_d_actos_tipo_tarea
         where id_fljo_trea = p_id_fljo_trea;

        /*
        -- buscamos el proceso juridico asociado a la instacia de flujo ---
        select c.indcdor_ntfccion
          into v_indcdor_ntfccion
          from cb_g_procesos_juridico a
          join cb_g_procesos_jrdco_dcmnto b
            on b.id_prcsos_jrdco = a.id_prcsos_jrdco
          join gn_g_actos c
            on c.id_acto = b.id_acto
         where j.id_instncia_fljo = p_id_instncia_fljo;

        -- buscamos el acto del documento del tipo de acto requerido --
        select dc.id_acto
          into v_id_acto
          from cb_g_procesos_jrdco_dcmnto dc
         where dc.id_prcsos_jrdco = v_id_prcsos_jrdco
           and dc.id_acto_tpo = v_id_acto_tpo_rqrdo;

        -- buscamos el indicador de notificacion para saber si el acto esta o no notificado--
        select a.indcdor_ntfccion
          into v_indcdor_ntfccion
          from gn_g_actos a
         where a.id_acto = v_id_acto;
        */

        select c.indcdor_ntfccion
          into v_indcdor_ntfccion
          from cb_g_procesos_juridico a
          join cb_g_procesos_jrdco_dcmnto b
            on b.id_prcsos_jrdco  = a.id_prcsos_jrdco
          join gn_g_actos c
            on c.id_acto          = b.id_acto
         where a.id_instncia_fljo = p_id_instncia_fljo
           and b.id_acto_tpo      = v_id_acto_tpo_rqrdo;

        return fnc_wf_error( p_value   => v_indcdor_ntfccion = 'S'
                           , p_mensaje => 'No se puede pasar a la siguiente etapa ya que el acto requerido no esta notificado.' );

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar si el acto requerido esta notificado.');
    end fnc_vl_acto_requerido_ntfcdo;

    function fnc_vl_mdda_ctlar_en_prc_jrdco( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2
    is

        v_id_prcsos_jrdco       cb_g_procesos_juridico.id_prcsos_jrdco%type;
        v_mddas_asgndas         number := 0;
    begin

       -- buscamos el proceso juridico asociado a la instacia de flujo ---
       select j.id_prcsos_jrdco
         into v_id_prcsos_jrdco
         from cb_g_procesos_juridico j
        where j.id_instncia_fljo = p_id_instncia_fljo;

       -- buscamos si tiene medidas cautelares asociadas al proceso--
       select count(A.ID_PRCSOS_JRDCO_MDDA_CTLR)
         into v_mddas_asgndas
         from cb_g_prcsos_jrdco_mdda_ctlr a
        where A.ID_PRCSOS_JRDCO = v_id_prcsos_jrdco;


       return fnc_wf_error( p_value   => v_mddas_asgndas > 0
                          , p_mensaje => 'No se puede pasar a la siguiente etapa ya que el proceso jur?dico no tiene medidas cautelares asociadas.' );

       exception
           when others then
               return fnc_wf_error( p_value   => false
                                  , p_mensaje => 'Error al validar si el proceso jur?dico tiene medidas cautelares asociadas.' );
   end fnc_vl_mdda_ctlar_en_prc_jrdco;

    function fnc_vl_flujo_generado(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2
    is
        v_return varchar2(1) := 'N';
    begin

        for c_flujo_gnrdo in (select estdo_instncia_gnrdo
                                from v_wf_g_instancias_flujo_gnrdo
                               where id_instncia_fljo = p_id_instncia_fljo
                              )
        loop
            v_return := 'S';
            if (c_flujo_gnrdo.estdo_instncia_gnrdo = 'INICIADA') then
                return fnc_wf_error( p_value   => false
                                   , p_mensaje => 'Concluir los flujos de trabajo asociados al proceso, ' ||
                                                  'si ya fue concluido, esta etapa ser? finalizada de forma ' ||
                                                  'autom?tica en el transcurso de 1 hora aproximadamente.' );
            end if;
        end loop;

        return fnc_wf_error( p_value   => v_return = 'S'
                           , p_mensaje => 'No se ha generado el flujo' );

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Concluir los flujos de trabajo asociados al proceso, ' ||
                                              'si ya fue concluido, esta etapa ser? finalizada de forma ' ||
                                              'autom?tica en el transcurso de 1 hora aproximadamente.' );
    end fnc_vl_flujo_generado;

    /*<----------------------------------Funciones prescripcion------------------------------------------->*/
    /*Funcion de prescripciones que valida si han sido agregadas las vigencias de todos los sujeto-impuesto*/
    function fnc_vl_prsc_incio  (p_cdgo_clnte                in number,
                 p_id_instncia_fljo          in number)
    return varchar2
    is
    v_id_prscrpcion     number;
    v_id_prscrpcion_tpo number;
    v_count_vig         number;
    v_error             exception;

    begin
        --Valida si existe la instancia de la prescripcion
        begin
            select  a.id_prscrpcion,
                    a.id_prscrpcion_tpo
            into    v_id_prscrpcion,
                    v_id_prscrpcion_tpo
            from    gf_g_prescripciones a
            where   a.id_instncia_fljo  =   p_id_instncia_fljo;
            exception
                when others then
                    return fnc_wf_error(p_value   => false,
                                        p_mensaje => 'No se puede continuar, problemas consultando la prescripci?n.');
        end;

        --Valida que se haya seleccionado el tipo de prescripci?n
        if (v_id_prscrpcion_tpo is null) then
            return fnc_wf_error(p_value   => false,
                                p_mensaje => 'No se puede continuar, debe seleccionar el tipo de prescripci?n');
        end if;

    begin
      for c_inst in (select      a.id_instncia_fljo,
                     a.id_prscrpcion_sjto_impsto,
                     b.idntfccion_sjto
               from        v_gf_g_prscrpcnes_sjto_impsto   a
               inner join  v_si_c_sujetos                  b   on  b.id_sjto   =   a.id_sjto
               where       a.cdgo_clnte    =   p_cdgo_clnte
               and         a.id_prscrpcion =   v_id_prscrpcion)
      loop
        begin
          --Se cuentan las vigencias por sujeto-impuesto en prescripciones
          select      count(*)
          into        v_count_vig
          from        gf_g_prscrpcnes_vgncia a
          where       a.cdgo_clnte                =   p_cdgo_clnte
          and         a.id_prscrpcion_sjto_impsto =   c_inst.id_prscrpcion_sjto_impsto;
          --Si hay un sujeto-impuesto sin vigencia entonces no es valido
          if  (v_count_vig = 0) then
            return fnc_wf_error(p_value   => false,
                                            p_mensaje => 'Por favor seleccione las vigencias a proyectar en esta prescripci?n para el sujeto-tributo No.'||c_inst.idntfccion_sjto)||'.';
          end if;
        end;
      end loop;
    end;
    --Retorna la respuesta
        return 'S';

    end fnc_vl_prsc_incio;

    /*Funcion de prescripciones que valida si puede iniciar la etapa autorizacion*/
    function fnc_vl_prsc_atrzcion(p_cdgo_clnte                in number,
                                  p_id_prscrpcion       in number)
    return varchar2 is

    v_count                 number := 0;
    v_id_fljo_trea_orgen    number := 0;
  v_dcmntos_etpa      number := 0;

    begin
        /*Parte 1*/
        --Se valida si hay respuestas de vigencias de prescripci?n en estado P (pendiente)
        select      count(*)
    into        v_count
    from        gf_g_prscrpcnes_sjto_impsto     a
    inner join  gf_g_prscrpcnes_vgncia     b   on b.id_prscrpcion_sjto_impsto  =   a.id_prscrpcion_sjto_impsto
    where       a.id_prscrpcion =   p_id_prscrpcion
    and     b.indcdor_aprbdo= 'P';
        if v_count > 0 then
            return fnc_wf_error(p_value   => false
                               ,p_mensaje => 'No se puede continuar, todas las vigencias deben ser analizadas.');
        end if;

        /*Parte 2*/
        --Se valida respuesta de prescripci?n
        select      count(*)
    into        v_count
    from        gf_g_prescripciones a
    where       a.id_prscrpcion =   p_id_prscrpcion
    and         a.cdgo_rspsta   is  null;
        if v_count > 0 then
            return fnc_wf_error(p_value   => false
                               ,p_mensaje => 'No se puede continuar, la prescripcion debe tener una respuesta.');
        end if;

        return 'S';
    end fnc_vl_prsc_atrzcion;

    /*Funci?n de prescripciones que valida aprobaci?n de la respuesta*/
    function fnc_vl_prescripcion_aprobacion(p_cdgo_clnte        in number,
                    p_id_prscrpcion   in number)
    return varchar2 is
        v_cntdr number;
    begin
        --Se valida que exista la prescripci?n como aprobada
        begin
            select  a.id_prscrpcion
            into    v_cntdr
            from    gf_g_prescripciones a
            where   a.id_prscrpcion       = p_id_prscrpcion
            and     a.id_usrio_autrza_rspsta  is  not null
            and     a.fcha_autrza_rspsta    is  not null;
            exception
                when no_data_found then
                    return fnc_wf_error(p_value   => False,
                                        p_mensaje => 'No se puede continuar, la prescripci?n no se encuentra aprobada.');
                when others then
                    return fnc_wf_error(p_value   => False,
                                        p_mensaje => 'No se puede continuar, problemas al consultar aprobaci?n de la prescripci?n.');
        end;
        --Si todo est? bien retorna si
        return 'S';
    end fnc_vl_prescripcion_aprobacion;

    /*Funci?n de prescripciones que valida que todos los actos obligatorios por
  etapa existan en la tabla de documentos*/
    function fnc_vl_prescripcns_vlda_dcmnts (p_id_instncia_fljo in  number,
                       p_id_fljo_trea   in  number)
    return varchar2 is

        v_dcmnnts_gnrdos  number := 0;

    begin
    --Se consultan los documentos por etapa que deben generarse y que a?n no est?n
    begin
      select      count(*)
            into        v_dcmnnts_gnrdos
            from        gf_g_prescripciones         a
            inner join  gf_d_prescripciones_dcmnto  b on b.id_prscrpcion_tpo =  a.id_prscrpcion_tpo
            inner join  gn_d_actos_tipo_tarea       c on c.id_actos_tpo_trea =  b.id_actos_tpo_trea
            left  join  gf_g_prscrpcns_dcmnto       d on d.id_prscrpcion     =  a.id_prscrpcion
                                                     and d.id_fljo_trea      =  c.id_fljo_trea
                                                     and d.id_acto_tpo       =  c.id_acto_tpo
            where       a.id_instncia_fljo  =   p_id_instncia_fljo
            and         c.id_fljo_trea    =   p_id_fljo_trea
            and         (b.cdgo_rspsta    =   a.cdgo_rspsta or
                         b.cdgo_rspsta  is  null)
            and         d.id_dcmnto     is  null;
      exception
        when others then
          return fnc_wf_error(p_value   => False,
                    p_mensaje => 'No se puede continuar, problemas al consultar los actos que deben generarse en la etapa.');
    end;

    --Si no se han generado los documentos de los actos obligatorios en la etapa
    --entonces no se puede transitar
    if v_dcmnnts_gnrdos > 0 then
      return fnc_wf_error(p_value   => False,
                p_mensaje => 'Generar los actos obligatorios en esta etapa de la prescripci?n.<br>');
    end if;

    return 'S';
    end fnc_vl_prescripcns_vlda_dcmnts;

    /*Funci?n de prescripciones que valida que todos los documentos
  est?n confirmados en la tabla de actos*/
    function fnc_vl_prescripcns_dcmnts_acts (p_id_instncia_fljo in  number,
                       p_id_fljo_trea     in  number)
    return varchar2 is

        v_dcmnts_acts number := 0;

    begin
    --Se consultan documentos que no est?n en la tabla actos
    begin
      select      count(*)
            into        v_dcmnts_acts
            from        gf_g_prescripciones         a
            inner join  gf_d_prescripciones_dcmnto  b on b.id_prscrpcion_tpo =  a.id_prscrpcion_tpo
            inner join  gn_d_actos_tipo_tarea       c on c.id_actos_tpo_trea =  b.id_actos_tpo_trea
            inner join  gf_g_prscrpcns_dcmnto       d on d.id_prscrpcion     =  a.id_prscrpcion
                                                     and d.id_fljo_trea      =  c.id_fljo_trea
                                                     and d.id_acto_tpo       =  c.id_acto_tpo
            where       a.id_instncia_fljo      =   p_id_instncia_fljo
            and         (b.cdgo_rspsta          =   a.cdgo_rspsta or
                         b.cdgo_rspsta          is  null)
            and         b.id_fljo_trea_cnfrmcion=   p_id_fljo_trea
            and         d.id_acto               is  null;
      exception
        when others then
          return fnc_wf_error(p_value   => False,
                    p_mensaje => 'No se puede continuar, problemas al consultar documentos que no tengan un acto asociado.');
    end;

    --Si hay documentos no generados en actos entonces no se puede transitar
    if v_dcmnts_acts > 0 then
      return fnc_wf_error(p_value   => False,
                p_mensaje => 'No se puede continuar, todos los documentos deben estar confirmados en actos.');
    end if;

    --Se validan documentos en actos que tengan problemas con el campo blob
    begin
      select      count(*)
            into        v_dcmnts_acts
            from        gf_g_prescripciones         a
            inner join  gf_d_prescripciones_dcmnto  b on b.id_prscrpcion_tpo =  a.id_prscrpcion_tpo
            inner join  gn_d_actos_tipo_tarea       c on c.id_actos_tpo_trea =  b.id_actos_tpo_trea
            inner join  gf_g_prscrpcns_dcmnto       d on d.id_prscrpcion     =  a.id_prscrpcion
                                                     and d.id_fljo_trea      =  c.id_fljo_trea
                                                     and d.id_acto_tpo       =  c.id_acto_tpo
            inner join  v_gn_g_actos                  e on e.id_acto           =  d.id_acto
            where       a.id_instncia_fljo                  =   p_id_instncia_fljo
            and         (b.cdgo_rspsta                      =   a.cdgo_rspsta or
                         b.cdgo_rspsta                      is  null)
            and         b.id_fljo_trea_cnfrmcion            =   p_id_fljo_trea
            and         ( nvl(dbms_lob.getlength(e.file_blob),0)    =   0
                        );
      exception
        when others then
          return fnc_wf_error(p_value   => False,
                    p_mensaje => 'No se puede continuar, problemas al consultar documentos en actos que puedan tener problemas en su generaci?n.');
    end;

    --Se hay actos con problemas no se puede continuar
    if v_dcmnts_acts > 0 then
      return fnc_wf_error(p_value   => False,
                p_mensaje => 'No se puede continuar, todos los actos deben estar generados y sin problemas.');
    end if;

    return 'S';
    end fnc_vl_prescripcns_dcmnts_acts;

    /*Funci?n de prescripciones que valida que todos los documentos de una etapa especifica
  est?n confirmados en la tabla de actos*/
    function fnc_vl_prescripcn_dcmn_etp_act (p_cdgo_clnte   in  number,
                       p_id_prscrpcion  in  number,
                       p_id_fljo_trea   in  number)
    return varchar2 is

        v_dcmnts_acts number := 0;

    begin
    --Se consultan documentos que no est?n en la tabla actos
    begin
      select  count(*)
      into    v_dcmnts_acts
      from    gf_g_prscrpcns_dcmnto   a
      where   a.id_prscrpcion =   p_id_prscrpcion
      and   a.id_fljo_trea  = p_id_fljo_trea
      and     a.id_acto       is  null;
      exception
        when others then
          return fnc_wf_error(p_value   => False,
                    p_mensaje => 'No se puede continuar, problemas al consultar documentos que no tengan un acto asociado.');
    end;

    --Si hay documentos no generados en actos entonces no se puede transitar
    if v_dcmnts_acts > 0 then
      return fnc_wf_error(p_value   => False,
                p_mensaje => 'No se puede continuar, todos los documentos deben estar confirmados en actos.');
    end if;

    --Se validan documentos en actos que tengan problemas con el campo blob
    begin
      select      count(*)
      into        v_dcmnts_acts
      from        gf_g_prscrpcns_dcmnto   a
      inner join  v_gn_g_actos              b   on  b.id_acto   =   a.id_acto
      where       a.id_prscrpcion =   p_id_prscrpcion
      and     a.id_fljo_trea  = p_id_fljo_trea
      and         (dbms_lob.getlength(b.file_blob)    is  null or
             dbms_lob.getlength(b.file_blob)    =   0
            );
      exception
        when others then
          return fnc_wf_error(p_value   => False,
                    p_mensaje => 'No se puede continuar, problemas al consultar documentos en actos que puedan tener problemas en su generaci?n.');
    end;

    --Se hay actos con problemas no se puede continuar
    if v_dcmnts_acts > 0 then
      return fnc_wf_error(p_value   => False,
                p_mensaje => 'No se puede continuar, todos los actos deben estar generados y sin problemas.');
    end if;

    return 'S';
    end fnc_vl_prescripcn_dcmn_etp_act;

    /*Funci?n de prescripciones que valida que todos los documentos de la prescripci?n est?n notificados*/
    function fnc_vl_prescripcns_acts_ntfcds(p_id_instncia_fljo  in number)
    return varchar2 is
        v_dcmnts_ntfds  number := 0;
    begin
        --Se consulta si hay documentos que no est?n notificados
        begin
            select      count(*)
      into        v_dcmnts_ntfds
      from        gf_g_prscrpcns_dcmnto       a
      inner join  v_nt_g_notfccnes_gn_g_actos b   on  b.id_acto       =   a.id_acto
            inner join  gf_g_prescripciones         c   on  c.id_prscrpcion =   a.id_prscrpcion
      where       c.id_instncia_fljo= p_id_instncia_fljo
      and         b.indcdor_ntfcdo  = 'N';
            exception
                when others then
                    return fnc_wf_error(p_value   => False,
                                        p_mensaje => 'No se puede continuar, problemas al consultar si hay documentos que no est?n notificados.');
        end;

    --Se hay documentos no notificados entonces no se puede continuar la transici?n
    if v_dcmnts_ntfds > 0 then
      return fnc_wf_error(p_value   => False,
                                p_mensaje => 'Notificar todos los documentos generados en la prescripci?n.');
    else
            return 'S';
        end if;

        --Si todo est? bien retorna si
        --return 'S';
    end fnc_vl_prescripcns_acts_ntfcds;

    /*Funci?n de prescripciones que valida que todos los documentos
  de una etapa especifica de la prescripci?n est?n notificados*/
    function fnc_vl_prscrpcns_act_etp_ntfcd(p_cdgo_clnte        in number,
                      p_id_prscrpcion   in number,
                      p_id_fljo_trea    in number)
    return varchar2 is
        v_dcmnts_ntfds  number := 0;
    begin
        --Se consulta si hay documentos que no est?n notificados
        begin
            select      count(*)
      into        v_dcmnts_ntfds
      from        gf_g_prscrpcns_dcmnto   a
      inner join  v_nt_g_notfccnes_gn_g_actos b   on  b.id_acto   = a.id_acto
      where       a.id_prscrpcion     = p_id_prscrpcion
      and         a.id_fljo_trea      = p_id_fljo_trea
      and         b.indcdor_ntfcdo  = 'N';
            exception
                when others then
                    return fnc_wf_error(p_value   => False,
                                        p_mensaje => 'No se puede continuar, problemas al consultar si hay documentos que no est?n notificados.');
        end;

    --Se hay documentos no notificados entonces no se puede continuar la transici?n
    if v_dcmnts_ntfds > 0 then
      return fnc_wf_error(p_value   => False,
                                        p_mensaje => 'Notificar todos los documentos generados en la prescripci?n.');
    end if;

        --Si todo est? bien retorna si
        return 'S';
    end fnc_vl_prscrpcns_act_etp_ntfcd;

    /*Funci?n de prescripciones que valida si la respuesta es concedida totalmente (CT) o concedida parcialmente (CP)*/
    function fnc_vl_prescrpcns_rspsta_pstva(p_id_instncia_fljo       in number)
    return varchar2 is

        v_cdgo_rspsta varchar2(10);
  --Se consulta la respuesta de la prescripci?n
    begin
        begin
            select  a.cdgo_rspsta
      into    v_cdgo_rspsta
      from    gf_g_prescripciones a
      where   a.id_instncia_fljo = p_id_instncia_fljo;
            exception
                when others then
                    return fnc_wf_error(p_value   => false
                                       ,p_mensaje => 'No se puede continuar, problemas al consultar la prescripci?n.');
        end;
        return fnc_wf_error(p_value   => v_cdgo_rspsta in ('CT', 'CP')
                           ,p_mensaje => 'No se puede continuar, la respuesta de la prescripci?n debe ser concedida totalmente (CT) o condedida parcialmente (CP).');
    end fnc_vl_prescrpcns_rspsta_pstva;

    /*Funci?n de prescripciones que valida si la respuesta es rechazada (RT)*/
    function fnc_vl_prescrpcns_rspsta_ngtva(p_id_instncia_fljo       in number)
    return varchar2 is

        v_cdgo_rspsta varchar2(10);
  --Se consulta la respuesta de la prescripci?n
    begin
        begin
            select  a.cdgo_rspsta
      into    v_cdgo_rspsta
      from    gf_g_prescripciones a
      where   a.id_instncia_fljo = p_id_instncia_fljo;
            exception
                when others then
                    return fnc_wf_error(p_value   => false
                                       ,p_mensaje => 'No se puede continuar, problemas al consultar la prescripci?n.');
        end;
        return fnc_wf_error(p_value   => v_cdgo_rspsta = 'RT'
                           ,p_mensaje => 'No se puede continuar, la respuesta de la prescripci?n debe ser rechazada totalmente (RT).');
    end fnc_vl_prescrpcns_rspsta_ngtva;

    -- /*Funcion de prescripciones que valida si la prescripcion finaliza desde la respuesta concedida totalmente (CT) o concedida parcialmente (CP)*/
    -- function fnc_vl_prsc_fnlzcion(p_cdgo_clnte                in number
                                 -- ,p_id_instncia_fljo          in number)
        -- return varchar2 is

        -- v_count     number;

    -- begin
        -- begin
            -- select      count(*)
            -- into        v_count
            -- from        v_gf_g_prescripciones_vgncia        a
            -- where       a.cdgo_clnte        =       p_cdgo_clnte
            -- and         a.id_instncia_fljo  =       p_id_instncia_fljo
            -- and         a.indcdor_aprbdo    =       'S'
            -- and        (a.aplcdo            <>      'A' or
                        -- a.aplcdo            is      null);
            -- exception
                -- when others then
                    -- return fnc_wf_error(p_value   => false
                                       -- ,p_mensaje => 'No se puede continuar, problemas consultando el flujo.');
        -- end;
        -- return fnc_wf_error(p_value   =>    v_count = 0
                           -- ,p_mensaje =>    'No se puede continuar, se debe aplicar toda la prescripci?n.');
    -- end;--fnc_vl_prsc_fnlzcion

    -- /*Funcion de prescripciones que valida si la respuesta es rechazada totalmente (RT)*/
    -- function fnc_vl_prsc_fnlzcion_rt(p_cdgo_clnte                in number
                                    -- ,p_id_instncia_fljo          in number)
    -- return varchar2 is

        -- v_cod_prscrpcion_rspsta     varchar2(10);

    -- begin

        -- begin
            -- select      a.cod_prscrpcion_rspsta
            -- into        v_cod_prscrpcion_rspsta
            -- from        gf_g_prescripciones     a
            -- where       a.cdgo_clnte            =       p_cdgo_clnte
            -- and         a.id_instncia_fljo      =       p_id_instncia_fljo
            -- and         a.cod_prscrpcion_rspsta =       'RT';
            -- exception
                -- when others then
                    -- return fnc_wf_error(p_value   => false
                                       -- ,p_mensaje => 'No se puede continuar, problemas consultando el flujo.');
        -- end;
        -- return fnc_wf_error(p_value   => true
                           -- ,p_mensaje => 'No se puede continuar, el estado de la prescripcion debe ser rechazada totalmente (RT).');
    -- end;--fnc_vl_prsc_fnlzcion_rt

    -- /*Funcion de prescripciones que valida si todos los documentos fueron autorizados*/
    -- function fnc_vl_prsc_autr(p_cdgo_clnte                in number
                             -- ,p_id_prscrpcion             in number)
    -- return varchar2 is

    -- v_prsc_vlda number := 0;
    -- begin
        -- select      count(*)
        -- into        v_prsc_vlda
        -- from        gf_g_prescripciones_dcmnto    a
        -- left join   gn_g_actos                    b     on  b.id_acto   =   a.id_acto
        -- where       a.cdgo_clnte        =       p_cdgo_clnte
        -- and         a.id_prscrpcion     =       p_id_prscrpcion
        -- and         (dbms_lob.getlength(b.file_blob)    is null
                  -- or dbms_lob.getlength(b.file_blob)    <   1);
        -- if v_prsc_vlda = 0 then
            -- return 'S';
        -- else
            -- return 'N';
        -- end if;
    -- end;--Fin fnc_vl_prsc_autr

    /*Funci?n que valida que el manejador de los flujos hijos se ejecut? con ?xito*/
    function fnc_vl_manejador_flujo(p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number)
        return varchar2 is
            v_count     number;
        begin
            begin
                select count(*)
                into v_count
                from v_wf_g_instancias_flujo_gnrdo  a
                where a.id_instncia_fljo = p_id_instncia_fljo
                and  a.id_fljo_trea = p_id_fljo_trea
                and  a.indcdor_mnjdo in ('N', 'E');

            exception
                when others then
                    return fnc_wf_error( p_value   => false
                                       , p_mensaje => 'problemas al consultar el manejador de los flujos asociados.');
            end;

            if v_count = 0 then
                return 'S';
            else
                return fnc_wf_error( p_value   => false
                                   , p_mensaje => 'Concluir el proceso de Ajuste de la(s) Prescripciones asociadas ' ||
                                                  'al proceso, si ya fue concluido este proceso ser? finalizado de ' ||
                                                  'forma autom?tica en el transcurso de 1 hora aproximadamente.' );
            end if;
    end fnc_vl_manejador_flujo;
    
    /*Funcion de prescripciones que valida la respuesta en la etapa de autorizacion*/
    function fnc_vl_prsc_rspsta_rchzda(p_cdgo_clnte          in number,
                                       p_id_prscrpcion       in number)
    return varchar2 is

    v_count                 number := 0;
    v_id_fljo_trea_orgen    number := 0;
    v_dcmntos_etpa          number := 0;
    v_cdgo_rspsta           varchar2(3);

    begin
        
            select      a.cdgo_rspsta
            into        v_cdgo_rspsta
            from        gf_g_prescripciones a
            where       a.id_prscrpcion =   p_id_prscrpcion;
        
        if v_cdgo_rspsta = 'RT' then
            /*Parte 1*/
            --Se valida si hay respuestas de vigencias de prescripci?n en estado P (pendiente)
            select      count(*)
            into        v_count
            from        gf_g_prscrpcnes_sjto_impsto     a
            inner join  gf_g_prscrpcnes_vgncia          b   on b.id_prscrpcion_sjto_impsto  =   a.id_prscrpcion_sjto_impsto
            where       a.id_prscrpcion     =  p_id_prscrpcion
            and         b.indcdor_aprbdo    = 'P';
            
            if v_count > 0 then
                return fnc_wf_error(p_value   => false
                                   ,p_mensaje => 'No se puede continuar, todas las vigencias deben ser analizadas.');
            end if;
    
            /*Parte 2*/
            --Se valida respuesta de prescripci?n
            select      count(*)
            into        v_count
            from        gf_g_prescripciones a
            where       a.id_prscrpcion =   p_id_prscrpcion
            and         a.cdgo_rspsta   is  null;
            
            if v_count > 0 then
                return fnc_wf_error(p_value   => false
                                   ,p_mensaje => 'No se puede continuar, la prescripcion debe tener una respuesta.');
            end if;
            
            return 'N';
        end if;
        return 'S';    
    end fnc_vl_prsc_rspsta_rchzda;

    /*<------------------------------Fin Funciones prescripcion------------------------------------------->*/

    function fnc_vl_solicitud_pqr(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2
    is
        v_id_instncia_fljo wf_g_instancias_transicion.id_instncia_fljo%type;
    begin

        select id_instncia_fljo
          into v_id_instncia_fljo
          from v_pq_g_solicitudes
         where id_instncia_fljo = p_id_instncia_fljo;

         return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error no se encontraron datos de la solicitud. Intente registrar la solicitud.' );
    end;

 /*<----------------------------------Funciones Gestion Ajustes---------------------------------->*/
 function fnc_vl_instancia_ajuste( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
    return varchar2
    is


    v_id_instncia_fljo number;

    begin

        ---  ----
        select id_instncia_fljo into v_id_instncia_fljo
        from gf_g_ajustes
        where   id_instncia_fljo = p_id_instncia_fljo
                and    id_fljo_trea = p_id_fljo_trea;
              return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar registro del ajuste. ' || sqlerrm );
    end fnc_vl_instancia_ajuste;


  function fnc_vl_instncia_ajste_aplcdo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                           p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
  return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from gf_g_ajustes
        where   id_instncia_fljo = p_id_instncia_fljo and
            id_fljo_trea = p_id_fljo_trea and
            cdgo_ajste_estdo ='A';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado  aprobado del registro del ajuste.' );
    end fnc_vl_instncia_ajste_aplcdo;
 /*<---------------------------------- Fin Funciones Gestion Ajustes---------------------------------->*/

 /*<----------------------------------Funciones Acuerdos de Pago---------------------------------->*/
  function fnc_vl_instancia_acuerdo_slc (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

  return varchar2

  is


  v_id_fljo_trea_orgen number;
  v_error exception;

  begin

       select id_fljo_trea_orgen
          into v_id_fljo_trea_orgen
          from wf_g_instancias_transicion a
    inner join v_gf_g_convenios b
            on a.id_instncia_fljo = b.id_instncia_fljo_hjo
         where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1,2)
         and b.cdgo_cnvnio_estdo = 'SLC';

    return 'S';

  exception
    when others then
        return fnc_wf_error( p_value   => false,
                             p_mensaje => 'Error al validar aprobaci?n del acuerdo de pago');

  end fnc_vl_instancia_acuerdo_slc;

  function fnc_vl_instancia_acuerdo_apr (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

  return varchar2

  is

  v_id_fljo_trea_orgen number;
  v_error exception;

  begin

        select a.id_fljo_trea_orgen
          into v_id_fljo_trea_orgen
          from wf_g_instancias_transicion a
    inner join v_gf_g_convenios b
            on a.id_instncia_fljo = b.id_instncia_fljo_hjo
         where a.id_instncia_fljo = p_id_instncia_fljo
           and a.id_estdo_trnscion in (1,2)
           and b.cdgo_cnvnio_estdo = 'APB'
      group by a.id_fljo_trea_orgen;

    return 'S';

  exception
    when others then
        return fnc_wf_error( p_value   => false,
                             p_mensaje => 'Error al validar aprobaci?n del acuerdo de pago');

  end fnc_vl_instancia_acuerdo_apr;

    function fnc_vl_estado_acuerdo_slctdo (p_cdgo_clnte   number,
                                           p_id_cnvnio    number)
  return varchar2 is
  -- !! ---------------------------------------------- !! --
  -- !! Funci?n que valida si un acuerdo esta aprobado !! --
  -- !! ---------------------------------------------- !! --
  v_encntro_cnvnio      varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'SLC';
    exception
      when others then
        v_encntro_cnvnio := 'N';
    end;
    return v_encntro_cnvnio;
  end; -- Fin fnc_vl_estado_acuerdo_slctdo

    function fnc_vl_estado_acuerdo_aprobado (p_cdgo_clnte   number,
                                             p_id_cnvnio    number)
  return varchar2 is
  -- !! ---------------------------------------------- !! --
  -- !! Funci?n que valida si un acuerdo esta aprobado !! --
  -- !! ---------------------------------------------- !! --
  v_encntro_cnvnio      varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'APB';
    exception
      when others then
         return fnc_wf_error( p_value   => false,
                             p_mensaje => 'El Acuerdo de Pago no esta Aprobado');
    end;
    return v_encntro_cnvnio;
  end; -- Fin fnc_vl_estado_acuerdo_aprobado

    function fnc_vl_estado_acuerdo_rchzdo (p_cdgo_clnte   number,
                                             p_id_cnvnio    number)
  return varchar2 is
  -- !! ---------------------------------------------- !! --
  -- !! Funci?n que valida si un acuerdo esta aprobado !! --
  -- !! ---------------------------------------------- !! --
  v_encntro_cnvnio      varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'RCH';
    exception
      when others then
        v_encntro_cnvnio := 'N';
    end;
    return v_encntro_cnvnio;
  end; -- Fin fnc_vl_estado_acuerdo_rchzdo

    function fnc_vl_estado_acuerdo_aplicado (p_cdgo_clnte   number,
                                             p_id_cnvnio    number)
  return varchar2 is
  -- !! ---------------------------------------------- !! --
  -- !! Funci?n que valida si un acuerdo esta aprobado !! --
  -- !! ---------------------------------------------- !! --
  v_encntro_cnvnio      varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'APL';
    exception
      when others then
        v_encntro_cnvnio := 'N';
    end;
    return v_encntro_cnvnio;
  end; -- Fin fnc_vl_estado_acuerdo_aplicado

    function fnc_vl_sl_rvrsn_acrdo_rgstrdo (p_id_instncia_fljo    number)

  return varchar2 is

  -- !! --------------------------------------------------------------------------- !! --
  -- !! Funci?n que valida si la solicitud de reversion del acuerdo esta registrada !! --
  -- !! --------------------------------------------------------------------------- !! --

  v_encntro_cnvnio      varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro_cnvnio
        from gf_g_convenios_reversion
              where id_instncia_fljo_hjo = p_id_instncia_fljo;

    exception
      when others then
         return fnc_wf_error( p_value   => false,
                                      p_mensaje => 'La Solicitud de Reversi?n no ha sido registrada');
    end;

    return v_encntro_cnvnio;

  end fnc_vl_sl_rvrsn_acrdo_rgstrdo;

    function fnc_vl_mdfccion_acrdo_pgo_aprd(p_id_cnvnio_mdfccion    number)
  return varchar2 is
  -- !! ---------------------------------------------- !! --
  -- !! Funci?n que valida si la modificaci?n del acuerdo de pago esta aprobado !! --
  -- !! ---------------------------------------------- !! --
  v_encntro     varchar2(1);

  begin
    begin
      select 'S'
        into v_encntro
        from gf_g_convenios_modificacion
       where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and cdgo_cnvnio_mdfccion_estdo = 'RGS';
    exception
      when others then
        v_encntro := 'N';
    end;
    return v_encntro;
  end; -- Fin fnc_vl_mdfccion_acrdo_pgo_aprd

    function fnc_vl_acuerdo_pagado(p_cdgo_clnte           number,
                                   p_id_instncia_fljo   number)
    return varchar2 is

-- !! ------------------------------------------------------------- !! --
-- !! Funci?n que valida si un acuerdo ha sido pagado absolutamente !! --
-- !! ------------------------------------------------------------- !! --

    v_encntro_cnvnio      varchar2(1);

    begin
        begin
            select 'S'
              into v_encntro_cnvnio
              from gf_g_convenios a
              join (select id_cnvnio, count (id_cnvnio) cntdad
                      from gf_g_convenios_extracto
                  group by id_cnvnio) b on a.id_cnvnio = b.id_cnvnio
              join (select id_cnvnio, count (id_cnvnio) cntdad
                      from gf_g_convenios_extracto
                     where indcdor_cta_pgda = 'S'
                     group by id_cnvnio) c on c.id_cnvnio = b.id_cnvnio
                                          and c.cntdad = b.cntdad
             join gf_g_convenios_reversion d on a.id_cnvnio = d.id_cnvnio
            where a.cdgo_clnte = p_cdgo_clnte
              and d.id_instncia_fljo_hjo = p_id_instncia_fljo
              and a.cdgo_cnvnio_estdo = 'FNL';
        exception
            when no_data_found then
                v_encntro_cnvnio := 'N';
        end;
        return v_encntro_cnvnio;
    end fnc_vl_acuerdo_pagado;

    function fnc_vl_acuerdo_exista( p_cdgo_clnte           number
                                   ,p_id_impsto            number
                                   ,p_id_impsto_sbmpsto    number
                                   ,p_id_sjto_impsto       number
                                   ) return varchar2 is

    --------------------------------------------------
    -------- Funci?n valida si existe acuerdo --------
    --------------------------------------------------

    v_acrdo_exste       varchar2(1);

    begin

        begin
            select 'S'
              into v_acrdo_exste
              from v_gf_g_convenios a
              join (select id_cnvnio, count (id_cnvnio) cntdad
                      from gf_g_convenios_extracto
                  group by id_cnvnio) b on a.id_cnvnio = b.id_cnvnio
              join (select id_cnvnio, count (decode(indcdor_cta_pgda,'S',1,null)) cntdad
                      from gf_g_convenios_extracto
                     group by id_cnvnio) c on c.id_cnvnio = b.id_cnvnio
                                          and b.cntdad >= c.cntdad
         left join gf_g_convenios_reversion d on d.id_cnvnio = a.id_cnvnio
            where a.cdgo_clnte = p_cdgo_clnte
              and a.id_impsto = p_id_impsto
              and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
              and a.id_sjto_impsto = p_id_sjto_impsto
              and d.id_cnvnio is null
              and a.cdgo_cnvnio_estdo in ('APL', 'FNL');
        exception
            when no_data_found then
                v_acrdo_exste := 'N';
        end;

        return v_acrdo_exste;

    end;
 /*<--------------------------------Fin Funciones Acuerdos de Pago-------------------------------->*/

  /*<----------------------------------Funciones Gestion Juridica---------------------------------->
  function fnc_co_rcrsos_dcmntos_pndentes(p_id_rcrso_etpa in  gj_g_recursos_etapa.id_rcrso_etpa%type)
  return varchar2
  as
    v_pndntes  varchar2(1);
  begin
    select case when count(a.id_acto_tpo) = 0 then 'N'
                when count(a.id_acto_tpo) > 0 then 'S' end pndntes
    into v_pndntes
    from gn_d_actos_tipo_tarea          a
    inner join  gj_g_recursos_etapa     b on a.id_fljo_trea     = b.id_fljo_trea
    left join   gj_g_recursos_documento c on b.id_rcrso_etpa    = c.id_rcrso_etpa and
                                             a.id_acto_tpo      = c.id_acto_tpo
    where b.id_rcrso_etpa   = p_id_rcrso_etpa and
          c.id_rcrso_dcmnto is null;

    return v_pndntes;
  end fnc_co_rcrsos_dcmntos_pndentes;

  function fnc_co_actos_notificados_rcrso(p_id_rcrso in  gj_g_recursos_etapa.id_rcrso%type)
    return varchar2 AS
    v_pndntes varchar(2);
    v_cant_pndntes number;
  BEGIN
    select sum(b.cant_pend_ntfcar) as cant_pend_ntfcar
    into v_cant_pndntes
    from gj_g_recursos_etapa a
    left join(
        select count(a.id_rcrso_dcmnto) cant_pend_ntfcar, a.id_rcrso_etpa
        from gj_g_recursos_documento a
        inner join gn_g_actos b on a.id_acto = b.id_acto
        inner join gn_d_actos_tipo c on b.id_acto_tpo = c.id_acto_tpo and
                                        c.indcdor_ntfccion = 'S'
        where b.indcdor_ntfccion = 'N'
        group by a.id_rcrso_etpa
    ) b on a.id_rcrso_etpa = b.id_rcrso_etpa
    where a.id_rcrso = p_id_rcrso;

    if(nvl(v_cant_pndntes,0) = 0 )then
        v_pndntes := 'S';
    else
        v_pndntes := 'N';
    end if;

    return v_pndntes;
  END fnc_co_actos_notificados_rcrso;

  function fnc_co_actos_notificados_etpa(p_id_rcrso_etpa in  gj_g_recursos_etapa.id_rcrso_etpa%type)
    return varchar2 AS
    v_pndntes varchar(2);
    v_cant_pndntes number;
  BEGIN
    select sum(b.cant_pend_ntfcar) as cant_pend_ntfcar
    into v_cant_pndntes
    from gj_g_recursos_etapa a
    left join(
        select count(a.id_rcrso_dcmnto) cant_pend_ntfcar, a.id_rcrso_etpa
        from gj_g_recursos_documento a
        inner join gn_g_actos b on a.id_acto = b.id_acto
        inner join gn_d_actos_tipo c on b.id_acto_tpo = c.id_acto_tpo and
                                        c.indcdor_ntfccion = 'S'
        where b.indcdor_ntfccion = 'N'
        group by a.id_rcrso_etpa
    ) b on a.id_rcrso_etpa = b.id_rcrso_etpa
    where a.id_rcrso_etpa = p_id_rcrso_etpa;

    if(nvl(v_cant_pndntes,0) = 0 )then
        v_pndntes := 'S';
    else
        v_pndntes := 'N';
    end if;

    return v_pndntes;
  END fnc_co_actos_notificados_etpa;

  function fnc_co_dcmntos_actualizados(p_id_slctud in number)
    return varchar2 AS
    v_pndntes varchar(2);
  BEGIN
    select case when count(*) > 0 then 'S'
                when count(*) = 0 then 'N'
           end
    into v_pndntes
    from pq_g_documentos
    where id_slctud  = p_id_slctud and
          indcdor_actlzar = 'S';

    return v_pndntes;
  END fnc_co_dcmntos_actualizados;



  <--------------------------------Fin Funciones Gestion Juridica-------------------------------->*/

  /*<----------------------------------Funciones Tecnologia de la Informacion---------------------------------->*/
   /* Condicion para pasar a etapa de Desarrollo despues de generar el Paquete Funcional */
   function fnc_vl_gn_pf_desarrollo (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

    return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo IN ('GN','MD', 'RL');

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de Generado en la Etapa de Desarrollo.' );
    end;---fin fnc_vl_gn_pf_desarrollo

  /* Condicion de Aprobacion para pasar  el Paquete Funcional de etapa de Desarrollo a etapa de Calidad */
    function fnc_vl_ap_pf_desarrollo (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

    return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='AD';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de aprobado en la Etapa de Desarrollo.' );
    end;-- fin fnc_vl_ap_pf_desarrollo

  /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
    function fnc_vl_rc_pf_desarrollo(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

    return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='RD';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de Rechazado en la Etapa de Desarrollo' );
    end;-- fin fnc_vl_rc_pf_desarrollo

/*  Condicion de Aprobacion para pasar el Paquete Funcional de etapa de Calidad a etapa de Prueba */
function fnc_vl_ap_pf_calidad (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

    return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='AC';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de aprobado en la Etapa de Calidad.' );
  end;-- fnc_vl_ap_pf_calidad
/* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */

function fnc_vl_rc_pf_calidad(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
   return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='RC';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de Rechazado en la Etapa de Calidad' );
    end;-- fin fnc_vl_rc_pf_calidad

/*  Condicion de Aprobacion para pasar el Paquete Funcional de etapa de Calidad a etapa de Prueba */
function fnc_vl_ap_pf_prueba (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)

    return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='AP';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de aprobado en la Etapa de Prueba.' );
  end;-- fnc_vl_ap_pf_calidad

  /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
function fnc_vl_rc_pf_prueba(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
   return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='RP';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de Rechazado en la Etapa de Prueba' );
    end;-- fin fnc_vl_rc_pf_calidad

    /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
function fnc_vl_md_pf_prueba(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
   return varchar2

   is

  v_id_instncia_fljo number;

    begin

        --- ----
        select id_instncia_fljo into v_id_instncia_fljo
        from ti_g_paquetes_funcional
        where   id_instncia_fljo = p_id_instncia_fljo and
            cdgo_estdo ='MP';

               return 'S';

    exception
        when others then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Error al validar el estado de Modificacion de Desarrollo' );
    end;-- fin fnc_vl_rc_pf_calidad


   /*<---------------------------------- Fin Funciones Tecnologia de la Informacion---------------------------------->*/




    /*<---------------------------------- Inicio Funciones de Gestion Juridica---------------------------------->*/
     function fnc_vl_gj_recurso_vgncia (p_id_instncia_fljo         in  number)
    return varchar2 as
        v_vgncias varchar2(1);
    begin
        select case when count(a.id_rcrso_vgncia) > 0 then 'S'
                    when count(a.id_rcrso_vgncia) < 1 then 'N'
               end
        into v_vgncias
        from gj_g_recursos_vigencia a
        inner join gj_g_recursos b on a.id_rcrso = b.id_rcrso
        where b.id_instncia_fljo_hjo = p_id_instncia_fljo;
        if(v_vgncias = 'N')then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                         p_mensaje => 'Asociar las vigencias al recurso.');
        else
            return v_vgncias;
        end if;
    end fnc_vl_gj_recurso_vgncia;


     /*Funcion de gestion juridica que valida si el flujo ha sido instanciado en las tablas*/
function fnc_vl_gj_recurso (p_id_instncia_fljo       in  number)
     return varchar2
     is
        v_id_rcrso     number;
     begin
        select      a.id_rcrso
        into        v_id_rcrso
        from        gj_g_recursos       a
        where       a.id_instncia_fljo_hjo      =   p_id_instncia_fljo;
        return pkg_wf_funciones.fnc_wf_error(p_value   => (v_id_rcrso is not null)
                                            ,p_mensaje => 'Flujo de recursos consultado.');
        exception
            when no_data_found then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false
                                                    ,p_mensaje => 'El flujo no se encuentra registrado.');
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false
                                                    ,p_mensaje => 'Problemas consultando el flujo de recursos.');
     end;

     /*Funcion de gestion juridica que valida el estado air en caso de ser necesario*/
  function fnc_vl_gj_valida_air (p_id_instncia_fljo      in  number)
     return varchar2
     is
        v_a_i_r     varchar2(1);
     begin
        select      a.a_i_r
        into        v_a_i_r
        from        gj_g_recursos       a
        where       a.id_instncia_fljo_hjo      =   p_id_instncia_fljo;
        if v_a_i_r in ('A', 'I', 'R') then
            return v_a_i_r;
        elsif v_a_i_r is null then
            return 'N';
        else
            return pkg_wf_funciones.fnc_wf_error(p_value   => false
                                                ,p_mensaje => 'El estado no es valido.');
        end if;
        exception
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false
                                                    ,p_mensaje => 'Problemas consultando el flujo de recursos.');
     end;

    function fnc_vl_gj_valida_actos_tarea (p_id_instncia_fljo  in  number,
                                           p_id_fljo_trea      in  number)
    return varchar2 as
        v_actos varchar2(1);
    begin
        select case 
                when count(a.id_actos_tpo_trea) > 0 then 'S'
                when count(a.id_actos_tpo_trea) < 1 then 'N'
               end
        into v_actos
        from gn_d_actos_tipo_tarea a
        inner join gj_g_recursos          b on b.id_instncia_fljo_hjo   = p_id_instncia_fljo
        left join gj_g_recursos_documento c on b.id_rcrso               = c.id_rcrso and
                                               a.id_acto_tpo            = c.id_acto_tpo and
                                               a.id_fljo_trea           = c.id_fljo_trea
        where a.id_fljo_trea        = p_id_fljo_trea and
              a.indcdor_oblgtrio    = 'S' and
              c.id_acto is null;
        if(v_actos = 'S')then
             return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                  p_mensaje => 'Se tienen Actos pendientes por generar o confirmar en esta tarea, por favor verifique.');
        else
            return v_actos;
        end if;
    end fnc_vl_gj_valida_actos_tarea;

   function fnc_vl_gj_valida_dcmntos_tarea(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
    return varchar2 as
         v_dcmntos varchar2(1);
    begin
        select case 
                when count(a.id_actos_tpo_trea) > 0 then 'S'
                when count(a.id_actos_tpo_trea) < 1 then 'N'
               end
        into v_dcmntos
        from gn_d_actos_tipo_tarea a
        inner join gj_g_recursos          b on b.id_instncia_fljo_hjo   = p_id_instncia_fljo
        left join gj_g_recursos_documento c on b.id_rcrso               = c.id_rcrso and
                                               a.id_acto_tpo            = c.id_acto_tpo and
                                               a.id_fljo_trea           = c.id_fljo_trea
        where a.id_fljo_trea        = p_id_fljo_trea and
              a.indcdor_oblgtrio    = 'S' and
              c.id_rcrso_dcmnto is null;
        if(v_dcmntos = 'S')then
             return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                  p_mensaje => ' Generar Actos pendientes, por favor verifique.');
        else
            return v_dcmntos;
        end if;
    end fnc_vl_gj_valida_dcmntos_tarea;

    function fnc_vl_gj_valida_actos_ntfcdos(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
        return varchar2 as
        v_actos varchar2(1);
    begin
        select case 
                when count(a.id_rcrso_dcmnto) > 0 then 'N'
                when count(a.id_rcrso_dcmnto) < 1 then 'S'
               end 
        into v_actos
        from gj_g_recursos_documento    a
        inner join gj_g_recursos        b on a.id_rcrso = b.id_rcrso
        inner join gn_g_actos           c on a.id_acto  = c.id_acto
        where b.id_instncia_fljo_hjo = p_id_instncia_fljo  and
              a.id_fljo_trea         = p_id_fljo_trea      and
              c.fcha_ntfccion is null;
              
        if(v_actos = 'N')then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                 p_mensaje => 'Los actos generados en la tarea deben estar notificados, por favor verifique.');
        else
            return v_actos;
        end if;
    end fnc_vl_gj_valida_actos_ntfcdos;
    
    function fnc_vl_gj_acciones_exitosa(p_id_instncia_fljo  in  number,
                                         p_id_fljo_trea      in  number)
        return varchar2 as
        v_acciones varchar2(1);
    begin
        select case when count(a.id_rcrso_accion) > 0 then 'S'
                    when count(a.id_rcrso_accion) < 1 then 'N'
               end
        into v_acciones
        from gj_g_recursos_accion a
        inner join gj_g_recursos b on a.id_rcrso = b.id_rcrso
        where b.id_instncia_fljo_hjo = p_id_instncia_fljo and
              a.actvo = 'S' and
              nvl(a.indcdor_extso, 'N') = 'N';
        if(v_acciones = 'S')then
             return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                  p_mensaje => 'Gestionar Todas las acciones y/o generar la instancia, por favor verifique.');
        end if;
        return v_acciones;
    end fnc_vl_gj_acciones_exitosa;
    

    function fnc_vl_gj_vlda_ac_ctcion_ntfcd(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
     return varchar2 as
     v_actos varchar2(1);
    begin 
        select case 
                when count(a.id_rcrso_dcmnto) > 0 then 'S'
                when count(a.id_rcrso_dcmnto) < 1 then 'N'
               end
         into v_actos
         from gj_g_recursos_documento    a
         join gj_g_recursos              b on a.id_rcrso = b.id_rcrso
         join gn_g_actos                 c on a.id_acto  = c.id_acto
        where b.id_instncia_fljo_hjo = p_id_instncia_fljo  
          and a.id_fljo_trea         = p_id_fljo_trea              
          and c.fcha_ntfccion is not null;    
        
        if(v_actos = 'N')then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                 p_mensaje => 'El acto de citacion debe estar notificado, por favor verifique.');
        else
            return v_actos;
        end if;
    end fnc_vl_gj_vlda_ac_ctcion_ntfcd;

    --Funcion que valida que los documentos inadmitidos esten actualizados para poder avanzar a la siguiente tarea
   function fnc_vl_gj_vlda_dcmntos_actlzds(p_id_slctud        in number
                                          , p_id_instncia_fljo in number)
        return varchar2 as 	
        v_indicador varchar2(1);
        
    begin
    
        select case 
                when  count(a.indcdor_actlzar) >  0 then 'S'
                when  count(a.indcdor_actlzar) <= 0 then 'N'        
               end 
          into v_indicador
          from pq_g_documentos          a
          join v_pq_d_motivos_documento b    on a.id_mtvo_dcmnto = b.id_mtvo_dcmnto
          join gj_g_recursos            c    on a.id_slctud      = c.id_slctud
         where c.id_instncia_fljo_hjo = p_id_instncia_fljo 
           and a.id_slctud            = p_id_slctud
           and a.indcdor_actlzar      = 'S';   
    
        if (v_indicador = 'S') then 
            return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                 p_mensaje => 'Actualizar los documentos inadmitidos en la PQR, por favor verifique.');
        else
            return v_indicador;
        end if;
    
    end fnc_vl_gj_vlda_dcmntos_actlzds;
    
    function fnc_vl_acto_recurso(p_cdgo_clnte          in  number,
                                 p_id_acto             in  number) return varchar2 as
  
      v_id_acto                     number;
      v_id_rcrso                    number;
      v_fcha_fin          timestamp(6);
      v_a_i_r           varchar2(1);
      v_cdgo_rspta          varchar2(3);
      o_cdgo_rspsta                 number;
      o_mnsje_rspsta                varchar2(1000);
      o_estdo_instncia              varchar2(20);
      
      
      begin 
            --Se valida si el tipo de acto se encuentra en Gesti?n Jur?dica
            begin
                select a.id_rcrso,
                       a.a_i_r,   --  A         ,   R
                       a.cdgo_rspta,--(FVT,FVP,DFV) , (RCH)
                       a.fcha_fin
                into v_id_rcrso,
                     v_a_i_r,
                     v_cdgo_rspta,
                     v_fcha_fin
                from gj_g_recursos a
                where a.id_acto = p_id_acto;
            exception
                when no_data_found then
                    return 'N';
            end;
            
            --Se valida la recepci?n y respuestas de los Recursos para permitir a cada proceso avanzar o no.
            if v_id_rcrso is not null and v_a_i_r = 'R' and v_cdgo_rspta = 'RCH' and v_fcha_fin is not null then
                return 'N';
            elsif v_id_rcrso is not null and v_a_i_r = 'A' and v_cdgo_rspta = 'DFV' and v_fcha_fin is not null then
        return 'N';
            elsif v_id_rcrso is not null and v_a_i_r = 'A' and v_cdgo_rspta = 'FVP' and v_fcha_fin is not null then
        return 'N';
            elsif v_id_rcrso is not null and v_a_i_r = 'A' and v_cdgo_rspta = 'FVP' and v_fcha_fin is null then
        return 'S';
            elsif v_id_rcrso is not null and v_a_i_r = 'A' and v_cdgo_rspta = 'FVT' and v_fcha_fin is not null then
        return 'N';
            elsif v_id_rcrso is not null and v_a_i_r = 'A' and v_cdgo_rspta = 'FVT' and v_fcha_fin is null then
        return 'S';
            end if;
  
  end fnc_vl_acto_recurso;



     /*<---------------------------------- Finc Funciones de Gestion Juridica---------------------------------->*/

    function fnc_vl_proceso_juridico_acmldo(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
    return varchar2 as
        v_id_prcsos_jrdco       cb_g_procesos_juridico.id_prcsos_jrdco%type;
        v_id_prcso_jrdco_acmldo cb_g_procesos_jrdco_acmldo.id_prcso_jrdco_acmldo%type;
        v_count                 number;

    begin
        begin

            select b.id_prcso_jrdco_acmldo
              into v_id_prcso_jrdco_acmldo
              from cb_g_procesos_juridico a
              join cb_g_procesos_jrdco_acmldo b on b.id_prcso_jrdco_pdre = a.id_prcsos_jrdco
             where a.id_instncia_fljo = p_id_instncia_fljo;

            select count(1)
              into v_count
              from cb_g_prcsos_jrdc_acmld_dtll a
             where a.indcdor_acmldo = 'N'
               and a.id_prcso_jrdco_acmldo = v_id_prcso_jrdco_acmldo;

            return pkg_wf_funciones.fnc_wf_error( p_value   => (v_count = 0)
                                                , p_mensaje => 'Los procesos hijos no esta al mismo nivel del padre');

        exception
            when no_data_found then
                begin
                    select a.id_prcsos_jrdco
                      into v_id_prcsos_jrdco
                      from cb_g_procesos_juridico a
                      join cb_g_prcsos_jrdc_acmld_dtll b on a.id_prcsos_jrdco = b.id_prcsos_jrdco
                     where a.id_instncia_fljo = p_id_instncia_fljo;

                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'El proceso juridico se encuentra acumulado');
                exception
                    when no_data_found then
                        return 'S';
                    when others then
                        return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                            , p_mensaje => 'No se pudo verificar el proceso juridico');
                end;
            when others then
                return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                    , p_mensaje => 'No se pudo verificar el proceso juridico');
        end;
    end fnc_vl_proceso_juridico_acmldo;

 /*ALC*/
 /*Funcion que permite validar si un proceso juridico tiene saldo*/
 function fnc_vl_saldo_cartera_juridico  (p_id_instncia_fljo  in  number,
                                             p_id_fljo_trea      in  number)
    return varchar2 as
    
        v_sldo_crtera       number := 0;
        v_nmro_prcso_jrdco  cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    begin

      begin
      
        select a.nmro_prcso_jrdco
            into v_nmro_prcso_jrdco      
        from  v_cb_g_procesos_juridico a 
        where a.id_instncia_fljo = p_id_instncia_fljo;
           /* and a.cdgo_clnte = p_cdgo_clnte;*/
       
      exception
        when others then
        v_nmro_prcso_jrdco  := null;
      end;

        begin

          select nvl(sum(a.vlor_sldo_cptal),0) as vlor_crtra 
            into v_sldo_crtera
            from v_gf_g_cartera_x_concepto a
            join si_i_sujetos_impuesto b
            on b.id_sjto_impsto    = a.id_sjto_impsto
           where /*a.cdgo_clnte        = p_cdgo_clnte and*/
              exists (select 1
                     from v_cb_g_procesos_juridico c
                       join cb_g_procesos_jrdco_dcmnto h on h.Id_Prcsos_Jrdco = c.id_prcsos_jrdco
                       join gn_g_actos i on i.ID_ACTO = h.ID_ACTO
                       join gn_g_actos_sujeto_impuesto j on j.ID_ACTO = i.ID_ACTO
                     where c.nmro_prcso_jrdco = v_nmro_prcso_jrdco --3202300222 
                     and j.id_sjto_impsto = b.id_sjto_impsto)                                  
             and a.vlor_sldo_cptal   > 0;
        exception
          when others then
          v_sldo_crtera := 0;
        end;

        if v_sldo_crtera is null then
            v_sldo_crtera := 0;
        end if;

        if v_sldo_crtera > 0 then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'No es posible enviar a auto archivo ya que aun tiene saldo en cartera.' );
        elsif v_sldo_crtera = 0 then
            return 'S';
        end if;

end;    

 function fnc_co_dcmnto_gnrado_sldo_fvor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2 as
        v_id_sldo_fvor_dcmnto gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type;
  begin

    begin
        /*select a.id_sldo_fvor_dcmnto
        into   v_id_sldo_fvor_dcmnto
        from gf_g_saldos_favor_documento a
        where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;*/
        
        select  a.id_sldo_fvor_dcmnto
        into    v_id_sldo_fvor_dcmnto
        from    gf_g_saldos_favor_documento a
        join    gn_d_actos_tipo             b on a.id_acto_tpo = b.id_acto_tpo
        where   a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
        and     b.cdgo_acto_tpo = 'SAF' ;
        
        return 'S';

    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Genere la Resoluci?n de saldo a favor');

    end;

  end fnc_co_dcmnto_gnrado_sldo_fvor;

  function fnc_vl_dcmnto_sldo_fvor_cnfrdo(p_id_instncia_fljo in gf_g_saldos_favor_solicitud.id_instncia_fljo%type)
     return varchar2 as
     v_id_sldo_fvor_dcmnto  number;
     v_id_sldo_fvor_slctud  number;
     v_vldar                varchar2(1) := 'N';
     v_cdgo_clnte           number;
     v_ntfca_en_fljo        varchar2(1);
     v_fcha_ntfccion        date;
  begin

    -- se consulta el cliente
    begin
        select  cdgo_clnte into v_cdgo_clnte
        from    v_wf_g_instancias_flujos s
        where   s.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'No se pudo verificar el cliente');
    end;
    
    -- se consulta si se valida notificacion antes de finalizar el flujo
    begin
        select ntfca_en_fljo into v_ntfca_en_fljo
        from   gi_d_saldos_favor_cnfgrcion
        where  cdgo_clnte = v_cdgo_clnte;
    exception
        when others then
            v_ntfca_en_fljo := 'N';
    end;

	if v_ntfca_en_fljo = 'N' then
		v_vldar := 'S';
    else
	
		begin
			select a.id_sldo_fvor_slctud
			into   v_id_sldo_fvor_slctud
			from   gf_g_saldos_favor_solicitud a
			where  a.id_instncia_fljo = p_id_instncia_fljo;
		end;
        
		--begin
		for c_acto in (select distinct c.id_acto_tpo , indcdor_ntfccion
					   from   wf_g_instancias_transicion a
					   join   wf_d_flujos_tarea          b on a.id_fljo_trea_orgen = b.id_fljo_trea
					   join   gn_d_actos_tipo_tarea      c on b.id_fljo_trea       = c.id_fljo_trea
					   join   gn_d_actos_tipo            d on c.id_acto_tpo        = d.id_acto_tpo
					   where  a.id_instncia_fljo = p_id_instncia_fljo
					   and    a.id_estdo_trnscion = 3
					   --and    indcdor_ntfccion = 'S' 
						) 
		loop        
			begin
				select d.id_sldo_fvor_dcmnto, a.fcha_ntfccion
				into   v_id_sldo_fvor_dcmnto, v_fcha_ntfccion
				from   gf_g_saldos_favor_documento d
				join   gn_g_actos                  a on  d.id_acto       =   a.id_acto
				where  d.id_acto_tpo = c_acto.id_acto_tpo
				and    d.id_sldo_fvor_slctud = v_id_sldo_fvor_slctud
				and    d.id_acto is not null
				--and    a.fcha_ntfccion is not null
				;
				
				if c_acto.indcdor_ntfccion = 'S' and v_fcha_ntfccion is null then
					return pkg_wf_funciones.fnc_wf_error(p_value   => false,
														 p_mensaje => 'Confirme y notifique los documentos para continuar' );

				elsif c_acto.indcdor_ntfccion = 'N' then -- el acto no es notificable, sale OK 16/03/2022
					return 'S';
				end if;
				
				/***
				-- si se notifica despues del flujo, avanza enseguida sin validar nada mas
				if v_ntfca_en_fljo = 'N' then
					v_vldar := 'S';
				elsif v_ntfca_en_fljo = 'S' and v_fcha_ntfccion is not null then
					v_vldar := 'S';
				end if;
				--v_vldar := 'S';  
				***/				
			exception
				when no_data_found then        
					return pkg_wf_funciones.fnc_wf_error( p_value   => false
									, p_mensaje => 'Confirme y notifique los documentos para continuar.');        
			end;
		end loop;   
	end if;
	
	return pkg_wf_funciones.fnc_wf_error( p_value   => v_vldar = 'S'
										, p_mensaje => 'Confirme y notifique los documentos para continuar .');
    --end;
  end fnc_vl_dcmnto_sldo_fvor_cnfrdo;

  function fnc_vl_saldo_favor_aplicacion(p_id_instncia_fljo    in gf_g_saldos_favor_solicitud.id_instncia_fljo%type,
                                         p_id_fljo_trea        in wf_d_flujos_tarea.id_fljo_trea%type)
     return varchar2 as
     v_id_instncia_fljo     number;
     v_id_sldo_fvor_slctud  number;
     v_id_sldo_fvor_dvlcion number;
     v_id_sld_fvr_cmpnscion number;
     v_count                number;
  begin
    begin
        --Se obtiene el identificador de la solicitud de saldo a favor
        select a.id_sldo_fvor_slctud
        into    v_id_sldo_fvor_slctud
        from gf_g_saldos_favor_solicitud a
        where a.id_instncia_fljo = p_id_instncia_fljo;

        --Se obtiene el identificador de la devoluci?n de  saldo a favor
        select c.id_sldo_fvor_dvlcion,
               b.id_sld_fvr_cmpnscion
        into v_id_sldo_fvor_dvlcion,
             v_id_sld_fvr_cmpnscion
        from gf_g_saldos_favor_solicitud        a
        left join gf_g_saldos_favor_cmpnscion   b   on  a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        left join gf_g_saldos_favor_devlucion   c   on  a.id_sldo_fvor_slctud   = c.id_sldo_fvor_slctud
        where a.id_sldo_fvor_slctud = v_id_sldo_fvor_slctud;

        if v_id_sldo_fvor_dvlcion is not null and v_id_sld_fvr_cmpnscion is null then
            return 'S';
        elsif (v_id_sldo_fvor_dvlcion is not null and v_id_sld_fvr_cmpnscion is not null) or (v_id_sld_fvr_cmpnscion is not null) then

            begin

                select a.id_instncia_fljo
                into   v_id_instncia_fljo
                from wf_g_instancias_flujo_gnrdo a
                where a.id_instncia_fljo = p_id_instncia_fljo
                and   a.id_fljo_trea     = p_id_fljo_trea
                and   a.indcdor_mnjdo    = 'S'
                group by a.id_instncia_fljo;

                return 'S';
            exception
                when no_data_found then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'Debe aplicar la compensaci?n y esperar que realicen el ajuste, ' ||
                                                               'este proceso ser? finalizado de forma autom?tica');
            end;

        else
            return 'S';
        end if;

    end;
  end fnc_vl_saldo_favor_aplicacion;

  function fnc_vl_saldo_favor_devolucion(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2 as

     v_id_sldo_fvor_dvlcion number;
  begin
    begin
        select b.id_sldo_fvor_dvlcion
        into v_id_sldo_fvor_dvlcion
        from gf_g_saldos_favor_solicitud  a
        join gf_g_saldos_favor_devlucion b on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

        return 'S';
    exception
        when no_data_found then
             return 'N';

    end;
  end fnc_vl_saldo_favor_devolucion;



  function fnc_vl_saldo_favor_rcncmiento(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2 as
     v_id_sldo_fvor_dvlcion number;
     v_id_sld_fvr_cmpnscion number;
  begin

    begin
        select b.id_sldo_fvor_dvlcion,
               c.id_sld_fvr_cmpnscion
        into v_id_sldo_fvor_dvlcion,
             v_id_sld_fvr_cmpnscion
        from gf_g_saldos_favor_solicitud      a
        left join gf_g_saldos_favor_devlucion b on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        left join gf_g_saldos_favor_cmpnscion c on a.id_sldo_fvor_slctud = c.id_sldo_fvor_slctud
        where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

        if(v_id_sldo_fvor_dvlcion is null and v_id_sld_fvr_cmpnscion is null) then
             return 'S';
        else
            return 'N';
        end if;



    end;

  end fnc_vl_saldo_favor_rcncmiento;


  ---- funciones cautelar y coactivo ----

  function fnc_vl_saldo_cartera_cautelar (  p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number,
                                            p_cdgo_clnte       in number)  return varchar2 is

        v_sldo_crtera       number := 0;
        v_id_embrgos_crtra  mc_g_embargos_cartera.id_embrgos_crtra%type;
    begin

        begin
        select a.id_embrgos_crtra
          into v_id_embrgos_crtra
          from v_mc_g_embargos_cartera a
          join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
         where a.id_instncia_fljo = p_id_instncia_fljo
           and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_embrgos_crtra := null;
        end;

        begin

            select nvl(sum(a.vlor_sldo_cptal),0) as vlor_crtra --nvl(a.vlor_intres,0)
              into v_sldo_crtera
              from v_gf_g_cartera_x_concepto a
              join si_i_sujetos_impuesto b
                on b.id_sjto_impsto    = a.id_sjto_impsto
             where a.cdgo_clnte        = p_cdgo_clnte
               and exists (select 1
                             from mc_g_embargos_sjto c
                            where c.id_sjto = b.id_sjto
                              and c.id_embrgos_crtra = v_id_embrgos_crtra)
               and a.vlor_sldo_cptal   > 0
               and a.dscrpcion_mvnt_fncro_estdo = 'Normal'
               and exists (select 1
                             from gf_g_movimientos_financiero b
                            where a.cdgo_clnte = b.cdgo_clnte
                              and a.id_impsto = b.id_impsto
                              and a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
                              and a.id_sjto_impsto = b.id_sjto_impsto
                              and a.vgncia = b.vgncia
                              and a.id_prdo = b.id_prdo
                              --and trunc(b.fcha_vncmnto) <= trunc(sysdate)
                              and b.cdgo_mvnt_fncro_estdo = 'NO'
                              and a.vlor_sldo_cptal > 0);

        exception
            when others then
            v_sldo_crtera := 0;
        end;

        if v_sldo_crtera is null then
            v_sldo_crtera := 0;
        end if;

        if v_sldo_crtera > 0 then
            return 'S';
        elsif v_sldo_crtera = 0 then
            return 'N';
            /*return fnc_wf_error( p_value   => false
                               , p_mensaje => 'No es posible enviar a Secuestre ya que no tiene saldo en cartera.' );*/
        end if;

    end;

    function fnc_vl_saldo_cartera_cautelar_desem (  p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number,
                                            p_cdgo_clnte       in number)  return varchar2 is

        v_sldo_crtera       number := 0;
        v_id_embrgos_crtra  mc_g_embargos_cartera.id_embrgos_crtra%type;
    begin

        begin
        select a.id_embrgos_crtra
          into v_id_embrgos_crtra
          from v_mc_g_embargos_cartera a
          join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
         where a.id_instncia_fljo = p_id_instncia_fljo
           and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_embrgos_crtra := null;
        end;

        begin

            select nvl(sum(a.vlor_sldo_cptal),0) as vlor_crtra --nvl(a.vlor_intres,0)
              into v_sldo_crtera
              from v_gf_g_cartera_x_concepto a
              join si_i_sujetos_impuesto b
                on b.id_sjto_impsto    = a.id_sjto_impsto
             where a.cdgo_clnte        = p_cdgo_clnte
               and exists (select 1
                             from mc_g_embargos_sjto c
                            where c.id_sjto = b.id_sjto
                              and c.id_embrgos_crtra = v_id_embrgos_crtra)
               and a.vlor_sldo_cptal   > 0
               and a.dscrpcion_mvnt_fncro_estdo = 'Normal'
               and exists (select 1
                             from gf_g_movimientos_financiero b
                            where a.cdgo_clnte = b.cdgo_clnte
                              and a.id_impsto = b.id_impsto
                              and a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
                              and a.id_sjto_impsto = b.id_sjto_impsto
                              and a.vgncia = b.vgncia
                              and a.id_prdo = b.id_prdo
                              --and trunc(b.fcha_vncmnto) <= trunc(sysdate)
                              and b.cdgo_mvnt_fncro_estdo = 'NO'
                              and a.vlor_sldo_cptal > 0);

        exception
            when others then
            v_sldo_crtera := 0;
        end;

        if v_sldo_crtera is null then
            v_sldo_crtera := 0;
        end if;

        if v_sldo_crtera > 0 then
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'No es posible enviar a desembargo ya que aun tiene saldo en cartera.' );
        elsif v_sldo_crtera = 0 then
            return 'S';
        end if;

    end;

    function fnc_vl_tipo_embargo_prmte_scstre ( p_id_instncia_fljo in number,
                                                p_id_fljo_trea     in number,
                                                p_cdgo_clnte       in number)  return varchar2 is

        v_sldo_crtera           number := 0;
        v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
        v_cdgo_tpos_mdda_ctlar  mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
        v_prmte_scstro          mc_d_tipos_mdda_ctlar.prmte_scstro%type;

    begin

        begin

            select a.id_embrgos_crtra,c.cdgo_tpos_mdda_ctlar,c.prmte_scstro
              into v_id_embrgos_crtra,v_cdgo_tpos_mdda_ctlar,v_prmte_scstro
              from v_mc_g_embargos_cartera a
              join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
              join mc_d_tipos_mdda_ctlar c on c.id_tpos_mdda_ctlar = a.id_tpos_embrgo
             where a.id_instncia_fljo = p_id_instncia_fljo
               and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_embrgos_crtra := null;
            v_cdgo_tpos_mdda_ctlar := null;
            v_prmte_scstro := null;
        end;

        if v_prmte_scstro = 'S' then
            return 'S';
        else
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'El tipo de embargo no tiene permitido el paso a secuestre.' );
        end if;

    end;

    function fnc_vl_acto_embargo (  p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number,
                                    p_cdgo_clnte       in number)  return varchar2 is

        v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
        v_cdgo_tpos_mdda_ctlar  mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
        v_id_acto               mc_g_embargos_resolucion.id_acto%type;

    begin

        begin

            select a.id_embrgos_crtra,c.cdgo_tpos_mdda_ctlar,a.id_acto
              into v_id_embrgos_crtra,v_cdgo_tpos_mdda_ctlar,v_id_acto
              from v_mc_g_embargos_resolucion a
              join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
              join mc_d_tipos_mdda_ctlar c on c.id_tpos_mdda_ctlar = a.id_tpos_embrgo
             where a.id_instncia_fljo = p_id_instncia_fljo
               and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_embrgos_crtra := null;
            v_cdgo_tpos_mdda_ctlar := null;
            v_id_acto := null;
        end;

        if v_id_acto is not null then
            return 'S';
        else
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Debe generar los actos asociados al Embargo' );
        end if;

    end;

    function fnc_vl_acto_desembargo(p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number,
                                    p_cdgo_clnte       in number)  return varchar2 is

        v_id_dsmbrgos_rslcion   mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
        v_id_acto               mc_g_embargos_resolucion.id_acto%type;

    begin

        begin

            select a.id_dsmbrgos_rslcion, a.id_acto
              into v_id_dsmbrgos_rslcion, v_id_acto
              from v_mc_g_desembargos_resolucion a
             where a.id_instncia_fljo = p_id_instncia_fljo
               and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_dsmbrgos_rslcion := null;
            v_id_acto := null;
        end;

        if v_id_acto is not null then
            return 'S';
        else
            return fnc_wf_error( p_value   => false
                               , p_mensaje => 'Debe generar los actos asociados al Desembargo' );
        end if;

    end;

    function fnc_vl_entdds_embrgo_dsmbrgdas ( p_id_instncia_fljo in number,
                                              p_id_fljo_trea     in number,
                                              p_cdgo_clnte       in number)  return varchar2 is
        --funcion para validar si las entidades de un embargo estan desembargadas--
        -- retorna S si todas estan desembargadas y N si no lo estan
        v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
        v_entidades_embargo     number := 0;
        v_entidades_desembargo  number := 0;

    begin

        select b.id_embrgos_rslcion, count(a.id_slctd_ofcio), count(c.id_dsmbrgo_ofcio)
          into v_id_embrgos_rslcion, v_entidades_embargo, v_entidades_desembargo
          from mc_g_solicitudes_y_oficios a
          join v_mc_g_embargos_resolucion b on b.id_embrgos_crtra = a.id_embrgos_crtra
                                       and b.id_embrgos_rslcion = a.id_embrgos_rslcion
          left join mc_g_desembargos_oficio c on c.id_slctd_ofcio = a.id_slctd_ofcio
                                           and c.id_acto is not null
         where a.id_embrgos_rslcion is not null
           and b.id_instncia_fljo = p_id_instncia_fljo
           and b.cdgo_clnte = p_cdgo_clnte
         group by b.id_embrgos_rslcion;

         if v_entidades_embargo = v_entidades_desembargo then
            return 'S';
         elsif v_entidades_embargo > v_entidades_desembargo then
            return 'N';
         end if;

    end;

    function fnc_vl_permite_embargo ( p_id_instncia_fljo in number,
                                      p_id_fljo_trea     in number,
                                      p_cdgo_clnte       in number)  return varchar2 is

        v_cdgo_embrgos_tpo      mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
        v_rsponsbles_id_cero    number;
        v_entdades_activas      number;
        v_rspnsbles_actvos      number;
        v_prmte_embrgar         varchar2(2);
        v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
        v_mnsje                 varchar2(500);

    begin

        begin

            select a.id_embrgos_crtra
              into v_id_embrgos_crtra
              from v_mc_g_embargos_cartera a
              join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
             where a.id_instncia_fljo = p_id_instncia_fljo
               and a.cdgo_clnte = p_cdgo_clnte;

             --buscamos el tipo de embargo
          select a.cdgo_tpos_mdda_ctlar
            into v_cdgo_embrgos_tpo
            from mc_d_tipos_mdda_ctlar a
           inner join mc_g_embargos_cartera b on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
           where b.id_embrgos_crtra = v_id_embrgos_crtra;

        exception
            when others then
            v_id_embrgos_crtra := null;
        end;

         if v_id_embrgos_crtra is not null then
            ---
               --validamos que el tipo de embargo si es difernete de bien tenga responsables activos
               --y con identificacion valida para poder realizar el embargo
               if v_cdgo_embrgos_tpo <> 'BIM' then
                    v_rsponsbles_id_cero := 0;

                    select count(*)
                      into v_rsponsbles_id_cero
                      from mc_g_embargos_responsable a
                     where exists (select 1
                                    from mc_g_solicitudes_y_oficios b
                                   where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or b.id_embrgos_rspnsble is null)
                                     and b.id_embrgos_crtra = a.id_embrgos_crtra
                                     and b.activo = 'S')
                       and a.id_embrgos_crtra = v_id_embrgos_crtra
                       and a.activo = 'S'
                       and lpad(trim(a.idntfccion),12,'0') = '000000000000';

                    if v_rsponsbles_id_cero = 0 then
                        v_prmte_embrgar := 'S';
                    else
                        v_prmte_embrgar := 'N';
                        v_mnsje := v_mnsje ||'No es posible enviar a embargo ya que hay responsables con cedula 0. ';
                    end if;

                    if v_prmte_embrgar = 'S' then
                        --validamos que la cartera tenga entidades activas que no hayan sido embargadas

                        v_entdades_activas := 0;

                        select count(*)
                          into v_entdades_activas
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra = v_id_embrgos_crtra
                           and a.id_acto_ofcio is null
                           and a.activo = 'S'
                           and exists (select 1
                                         from mc_g_embargos_responsable b
                                        where b.id_embrgos_crtra = a.id_embrgos_crtra
                                          and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or a.id_embrgos_rspnsble is null)
                                          and b.activo = 'S');

                        if v_entdades_activas > 0 then
                            v_prmte_embrgar := 'S';
                        else
                            v_prmte_embrgar := 'N';
                            v_mnsje := v_mnsje ||'No es posible enviar a embargo ya que no hay entidades activas asociada a la cartera a embargar. ';
                        end if;

                    end if;

               else

                    select count(*)
                      into v_rspnsbles_actvos
                      from mc_g_embargos_responsable a
                     where a.id_embrgos_crtra = v_id_embrgos_crtra
                       and a.activo = 'S';

                    if v_rspnsbles_actvos > 0 then
                        v_prmte_embrgar := 'S';
                    else
                        v_prmte_embrgar := 'N';
                        v_mnsje := v_mnsje || 'No es posible enviar a embargo ya que no hay responsables activos para embargar. ';
                    end if;

                    if v_prmte_embrgar = 'S' then

                        select count(*)
                          into v_entdades_activas
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra = v_id_embrgos_crtra
                           and a.id_acto_ofcio is null
                           and a.activo = 'S';

                        if v_entdades_activas > 0 then
                            v_prmte_embrgar := 'S';
                        else
                            v_prmte_embrgar := 'N';
                            v_mnsje := v_mnsje || 'No es posible enviar a embargo ya que no hay entidades activas asociada a la cartera a embargar. ';
                        end if;

                    end if;

               end if;
            ---

            --insert into muerto (v_001) values('+p_id_instncia_fljo:'||p_id_instncia_fljo||' +p_id_fljo_trea;:'||p_id_fljo_trea||' +p_cdgo_clnte:'||p_cdgo_clnte||' +v_prmte_embrgar:'||v_prmte_embrgar);

            if v_prmte_embrgar = 'S' then
                return 'S';
            else
                return fnc_wf_error( p_value   => false
                                    , p_mensaje => v_mnsje );
            end if;

         end if;

    end;


    function fnc_vl_permite_desembargo( p_id_instncia_fljo in number,
                                        p_id_fljo_trea     in number,
                                        p_cdgo_clnte       in number)  return varchar2 is

        v_prmte_dsmbrgar    varchar2(1);
        v_vlor_sldo_cptal   number := 0;
        v_id_embrgos_crtra  mc_g_embargos_cartera.id_embrgos_crtra%type;
        v_tpo_desembargo    varchar2(10);
        v_mnsje             varchar2(500);
        v_id_csles_dsmbrgo  mc_g_desembargos_solicitud.id_csles_dsmbrgo%type;
    begin

        begin

            select a.id_embrgos_crtra
              into v_id_embrgos_crtra
              from v_mc_g_embargos_cartera a
              join mc_d_estados_cartera b on b.id_estdos_crtra = a.id_estdos_crtra
             where a.id_instncia_fljo = p_id_instncia_fljo
               and a.cdgo_clnte = p_cdgo_clnte;

        exception
            when others then
            v_id_embrgos_crtra := null;
        end;

         if v_id_embrgos_crtra is not null then


           v_prmte_dsmbrgar := 'N';
           v_vlor_sldo_cptal := 0;
           v_vlor_sldo_cptal := pkg_cb_medidas_cautelares.fnc_vl_saldo_cartera_desembrgo( p_tpo_crtra         => 'CT',--p_tpo_crtra,
                                                                                          p_id_embrgos_crtra  => v_id_embrgos_crtra,
                                                                                          p_cdgo_clnte        => p_cdgo_clnte);

            if v_vlor_sldo_cptal = 0 then

                v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra  => v_id_embrgos_crtra,
                                                                                            p_cdgo_clnte        => p_cdgo_clnte) ;

                --inserto en la coleccion con el causal
                if v_tpo_desembargo is not null then
                    v_prmte_dsmbrgar := 'S';
                else
                    v_mnsje := 'Saldo en cartera 0, por causal desconocida.';
                end if;

            elsif v_vlor_sldo_cptal > 0 then

                v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra  => v_id_embrgos_crtra,
                                                                                      p_cdgo_clnte        => p_cdgo_clnte);

                --inserto en la coleccion con el causal
                if v_tpo_desembargo is not null then
                    v_prmte_dsmbrgar := 'S';
                else
                    v_mnsje := 'No es posible enviar a desembargo ya que aun tiene saldo en cartera.';
                end if;

            end if;

            --funcion para determinar si esta en una solicitud aprobada
            if v_prmte_dsmbrgar = 'N' then

                v_id_csles_dsmbrgo := pkg_cb_medidas_cautelares.fnc_vl_slctud_dsmbrgo(p_id_embrgos_crtra  => v_id_embrgos_crtra,
                                                                                      p_cdgo_clnte        => p_cdgo_clnte);

                if v_id_csles_dsmbrgo is not null then
                    v_prmte_dsmbrgar := 'S';
                end if;

            end if;

            if v_prmte_dsmbrgar = 'S' then
                return 'S';
            else
                return fnc_wf_error( p_value   => false
                                    , p_mensaje => v_mnsje );
            end if;

        end if;

    end;

    function fnc_vl_estado_dcmnto_scstre (p_id_instncia_fljo in number,
                                          p_id_fljo_trea     in number,
                                          p_cdgo_clnte       in number) return varchar2 is

        v_id_scstre_estdo   mc_g_secuestre_estados.id_scstre_estdo%type;

    begin

        select a.id_scstre_estdo
        into v_id_scstre_estdo
        from mc_g_secuestre_estados a
        join mc_g_secuestre_gestion b on b.id_scstre_gstion = a.id_scstre_gstion
        where b.id_instncia_fljo = p_id_instncia_fljo
        and a.id_fljo_trea = p_id_fljo_trea
        and b.cdgo_clnte = p_cdgo_clnte;

        return 'S';

    exception
        when others then

        return 'N';

    end;


    /*<-------------------------------------Funciones T?tulo Judicial--------------------------------->*/
    function fnc_cl_anlisis_devolucion_ttlo(p_cdgo_clnte        in number,
                                            p_id_instncia_fljo  in number) return varchar2 as

    -------------------------------------------------------------------------
    ---&Funcion de t?tulos judiciales que valida la devoluci?n del t?tulo&---
    -------------------------------------------------------------------------

    v_cdgo_ttlo_jdcial_estdo    varchar2(5);

    begin

        select cdgo_ttlo_jdcial_estdo
          into v_cdgo_ttlo_jdcial_estdo
          from gf_g_titulos_judicial
         where cdgo_clnte = p_cdgo_clnte
           and id_instncia_fljo = p_id_instncia_fljo;

            if v_cdgo_ttlo_jdcial_estdo = 'ASL' then
                return 'S';
            else
                return 'N';
            end if;
    end fnc_cl_anlisis_devolucion_ttlo;

    /*<---------------------------------- Fin Funciones T?tulo Judicial ------------------------------>*/

    /*<-------------------------------------Funciones T?tulo Ejecutivo--------------------------------->*/
  --Funci?n que valida si el titulo ejecutivo fue revisado
  function fnc_vl_revision_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2 as

  v_id_usrio_aprbo  gi_g_titulos_ejecutivo.id_usrio_aprbo%type;

  begin

    begin
        select t.id_usrio_aprbo
        into     v_id_usrio_aprbo
        from gi_g_titulos_ejecutivo t
        where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;

        if v_id_usrio_aprbo is not null then
            return 'S';
        end if;

        return 'N';
    end;

  end fnc_vl_revision_titulo_ejctvo;

  function fnc_vl_aplicacion_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2 as

  --v_id_ttlo_ejctvo gi_g_titulos_ejecutivo.id_ttlo_ejctvo%type;
    v_ttlos number;
  begin

      select count(*)
        into v_ttlos
        from gi_g_liquidaciones l
        where l.id_ttlo_ejctvo = p_id_ttlo_ejctvo;

      return ( case when v_ttlos > 0 then 'S' else 'N' end );

  end fnc_vl_aplicacion_titulo_ejctvo;

  function fnc_vl_concepto_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2 as

    v_cncptos   number;

  begin

    select count(*)
    into v_cncptos
    from gi_g_titulos_ejctvo_cncpto tc
    where tc.id_ttlo_ejctvo = p_id_ttlo_ejctvo;

    if v_cncptos > 0 then
        return 'S';
    end if;

    return fnc_wf_error( p_value   => false
                       , p_mensaje => 'Agregue los conceptos al T?tulo Ejecutivo para continuar.');
  end fnc_vl_concepto_titulo_ejctvo;

     /*<-------------------------------------Fin Funciones T?tulo Ejecutivo--------------------------------->*/

  function fnc_co_saldo_favor_solicitud(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
      return varchar2 as

  v_dtlle number;

  begin

    begin
        select a.id_sldo_fvor_slctud
        into v_dtlle
        from gf_g_saldos_favor_solicitud a
        join gf_g_sldos_fvor_slctud_dtll          b on  a.id_sldo_fvor_slctud   = b.id_sldo_fvor_slctud
        where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
        when no_data_found then
            return 'S';
    end;

  end fnc_co_saldo_favor_solicitud;


  function fnc_vl_revision_saldo_favor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type) return varchar2 as

  v_id_usrio_rvso  number;


  begin
/*
    select a.id_usrio_rvso
    into   v_id_usrio_rvso
    from  gf_g_saldos_favor_documento a
    where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
*/

    select  a.id_usrio_rvso
    into    v_id_usrio_rvso
    from    gf_g_saldos_favor_documento a
    join    gn_d_actos_tipo             b on a.id_acto_tpo = b.id_acto_tpo
    where   a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
    and     b.cdgo_acto_tpo = 'SAF' ; 
    
    if v_id_usrio_rvso is not null then
        return 'S';
    end if;

    return 'N';

  end fnc_vl_revision_saldo_favor;

  function fnc_vl_aprobacion_saldo_favor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type) return varchar2 as

  v_id_usrio_frma  number;

  begin

/*
    select a.id_usrio_frma
    into   v_id_usrio_frma
    from  gf_g_saldos_favor_documento a
    where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
*/

    select  a.id_usrio_frma
    into    v_id_usrio_frma
    from    gf_g_saldos_favor_documento a
    join    gn_d_actos_tipo             b on a.id_acto_tpo = b.id_acto_tpo
    where   a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
    and     b.cdgo_acto_tpo = 'SAF' ;    
        
    if v_id_usrio_frma is not null then
        return 'S';
    end if;

    return 'N';
  end fnc_vl_aprobacion_saldo_favor;
  
  /*<------------------------------------- Funciones Fiscalizacion ----------------------------------->*/

 function fnc_vl_termino_acto(p_cdgo_clnte                in  number,
                               p_id_fljo_trea              in  number,
                               p_id_instncia_fljo          in  number) return varchar2 as
  
  pragma autonomous_transaction;
  
  v_result                  varchar2(100);
  v_undad_drcion            varchar2(10);
  v_dia_tpo                 varchar2(10);
  v_dscrpcion               varchar2(300);
  v_mnsje_rspsta            varchar2(500);
  v_fcha_incial             timestamp;
  v_fcha_fnal               timestamp;
  v_drcion                  number;
  v_id_acto                 number;
  v_id_acto_tpo             number;
  v_id_cnddto               number;
  v_id_sjto_impsto          number;
  v_id_fsclzcion_expdnte    number;
  v_id_prgrma               number;
  v_id_sbprgrma             number;
  v_cdgo_rspsta             number;
  v_id_fsclzcion_expdnte_acto number;
    
  begin
    
    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte,
               b.id_prgrma,
               b.id_sbprgrma
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte,
              v_id_prgrma,
              v_id_sbprgrma
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => '1. No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
    --Se obtiene el acto que se le va a validar el termino
    begin
        select a.id_acto_tpo,
               a.dscrpcion
        into v_id_acto_tpo,
             v_dscrpcion
        from gn_d_actos_tipo            a 
        join gn_d_actos_tipo_tarea      b   on  a.id_acto_tpo = b.id_acto_tpo
        inner join fi_d_programas_acto  c   on  a.id_acto_tpo = c.id_acto_tpo
        where a.cdgo_clnte = p_cdgo_clnte 
        and b.indcdor_oblgtrio = 'S'
        and b.id_fljo_trea = p_id_fljo_trea
        and c.id_prgrma = v_id_prgrma
        and c.id_sbprgrma = v_id_sbprgrma;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'No se encontro parametrizado acto obligatorio en la etapa del flujo en la que se encuentra');
        when too_many_rows then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Se encontro mas de un tipo de acto obligatorio y de notificacion automatica en la tarea en la que se encuentra');
    end;
    
    --Se valida si el acto fue generado en el expediente de fiscalizacion
    begin
        select id_acto,
               id_fsclzcion_expdnte_acto
        into   v_id_acto,
               v_id_fsclzcion_expdnte_acto
        from fi_g_fsclzcion_expdnte_acto
        where id_acto_tpo = v_id_acto_tpo
        and id_fsclzcion_expdnte = v_id_fsclzcion_expdnte;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Genere el acto ' || lower(v_dscrpcion));
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Otra Exception');                                                
    end;
    
    --Se obtiene termino del acto
    begin
        select undad_drcion,
               drcion,
               dia_tpo
        into  v_undad_drcion,
              v_drcion,
              v_dia_tpo
        from gn_d_actos_tipo_tarea
        where id_acto_tpo = v_id_acto_tpo;
            exception
                when no_data_found then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'No se encontro parametrizado el acto ' || v_dscrpcion || ' en la etapa del flujo en la que se encuentra');
                when too_many_rows then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'Se encontro mas de un registro parametrizado el acto ' || v_dscrpcion || ' en la etapa del flujo en la que se encuentra');
               
                when others then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'Otra Exception');      
    end;
    
    --Se obtiene la fecha de notificacion del acto
    begin
        select fcha_ntfccion 
        into v_fcha_incial
        from gn_g_actos a
        where a.id_acto = v_id_acto;
    exception
        when no_data_found then
           
           return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Genere el ' || v_dscrpcion);
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Problema al obtener la fecha de generancion del Acto');
    end;
    
    if v_fcha_incial is  null then
        return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                            , p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' haya sido notificado ');
    end if;
    
    --Se obtiene la fecha final
    begin
        v_fcha_fnal :=  pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte     => p_cdgo_clnte, 
                                                              p_fecha_inicial  => v_fcha_incial,
                                                              p_undad_drcion   => v_undad_drcion,
                                                              p_drcion         => v_drcion,
                                                              p_dia_tpo        => v_dia_tpo);
    
        if v_fcha_fnal is not null then
            
            --Se manda actualizar la fecha del vencimiento de termino
            begin
                pkg_fi_fiscalizacion.prc_ac_fcha_vncmnto_trmno(p_cdgo_clnte => p_cdgo_clnte,
                                                               p_id_fsclzcion_expdnte_acto => v_id_fsclzcion_expdnte_acto,
                                                               p_fcha_vncmnto_trmno => v_fcha_fnal,
                                                               o_cdgo_rspsta => v_cdgo_rspsta,
                                                               o_mnsje_rspsta => v_mnsje_rspsta);
                if v_cdgo_rspsta > 0 then
                     return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                           p_mensaje => v_mnsje_rspsta);
                end if;
            end;
        
        
        
            if trunc(systimestamp) >= trunc(v_fcha_fnal) then
                return 'S';
            end if;
        end if;

    exception
        when others then
            null;
    end;
    
    select 
        case v_undad_drcion
            when 'MN' then 'Minutos'
            when 'HR' then 'Hora'
            when 'DI' then 'Dias'
            when 'SM' then 'Semana'
            when 'MS' then 'Mes'
        end
    into v_undad_drcion  
    from dual;    
     return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                          p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' cumpla el termino de ' || v_drcion ||' '|| v_undad_drcion ||','|| ' fecha del termino ' || to_char(trunc(v_fcha_fnal), 'dd/mm/yyyy'));
    --return 'S';
  end fnc_vl_termino_acto;

  function fnc_vl_declaracion(p_cdgo_clnte          in  number,
                              p_id_instncia_fljo    in  number) return varchar2 as
                              
    v_id_dclrcion       number;
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    
  begin
    
    begin
        select b.id_cnddto,
               b.id_sjto_impsto
        into  v_id_cnddto,
              v_id_sjto_impsto
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
    for c_candidato in (select a.id_dclrcion_vgncia_frmlrio 
                        from v_fi_g_fiscalizacion_expdnte_dtlle a
                        where a.id_cnddto = v_id_cnddto) loop
                        
        --Se consulta la declaracion presentada
        begin
            select  id_dclrcion
            into    v_id_dclrcion
            from gi_g_declaraciones     a
            join gi_d_declaraciones_uso b   on a.id_dclrcion_uso = b.id_dclrcion_uso
            where id_dclrcion_vgncia_frmlrio = c_candidato.id_dclrcion_vgncia_frmlrio
            and id_sjto_impsto = v_id_sjto_impsto
            and cdgo_dclrcion_estdo in ('PRS', 'APL')
            and indcdor_mgrdo is null;
        exception 
            when no_data_found then
                return 'N';
        end;
        
    end loop;
    
   return 'S'; ---CAMBIAR A 'S'
    
  end fnc_vl_declaracion;
  
  function fnc_vl_declaracion_correcion(p_cdgo_clnte          in  number,
                                        p_id_instncia_fljo    in  number) return varchar2 as
                                        
    v_id_dclrcion       number;
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    
  begin
    
    begin
        select b.id_cnddto,
               b.id_sjto_impsto
        into  v_id_cnddto,
              v_id_sjto_impsto
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
    for c_candidato in (select a.id_dclrcion 
                        from v_fi_g_fiscalizacion_expdnte_dtlle a
                        where a.id_cnddto = v_id_cnddto) loop
                        
        --Se consulta la declaracion presentada
        begin
            select  id_dclrcion
            into    v_id_dclrcion
            from gi_g_declaraciones     a
            join gi_d_declaraciones_uso b   on a.id_dclrcion_uso = b.id_dclrcion_uso
            where a.id_dclrcion_crrccion = c_candidato.id_dclrcion
            and id_sjto_impsto = v_id_sjto_impsto
            and cdgo_dclrcion_estdo in ('PRS', 'APL');
        exception 
            when no_data_found then
                return 'N';
        end;
    
    end loop;
    
   return 'S';
    
  end fnc_vl_declaracion_correcion;
  
  function fnc_vl_sancion(p_cdgo_clnte          in  number,
                          p_id_instncia_fljo    in  number) return varchar2 as

    v_sncion_dclrcion       number;
    v_sncion                number;
    v_vlr_sncion            number;
    v_id_cnddto             number;
    v_id_sjto_impsto        number;
    v_id_fsclzcion_expdnte  number;
    v_dfrncia               number;
    v_id_dclrcion           gi_g_declaraciones.id_dclrcion%type;
    v_fcha_prsntcion        gi_g_declaraciones.fcha_prsntcion%type;
    v_id_dclrcion_crrccion  gi_g_declaraciones.id_dclrcion_crrccion%type;
    v_cdgo_dclrcion_uso     gi_d_declaraciones_uso.cdgo_dclrcion_uso%type;
    json_hmlgcion           json_object_t;

  begin

    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;

    --Se consulta el valor de la sancion del programa por el cual fue fiscalizado el candidato
    begin
        select b.vlr_sncion
        into v_vlr_sncion
        from fi_g_candidatos          a
        join fi_d_programas_sancion   b   on  a.id_prgrma =   b.id_prgrma
        where b.cdgo_clnte = p_cdgo_clnte 
        and a.id_cnddto = v_id_cnddto;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se encontro parametrizada el valor sancion minima por la cual '
                                                            ||' se va abrir un expediente del programa sancionatorio automaticamente');
    end;


    for c_candidato in (select a.id_dclrcion_vgncia_frmlrio 
                        from v_fi_g_fiscalizacion_expdnte_dtlle a
                        where a.id_cnddto = v_id_cnddto) loop

        --Se consulta la declaracion presentada
        begin
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
            where id_dclrcion_vgncia_frmlrio = c_candidato.id_dclrcion_vgncia_frmlrio
            and id_sjto_impsto = v_id_sjto_impsto
            and cdgo_dclrcion_estdo in ('PRS', 'APL');
        exception 
            when no_data_found then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'No se pudo validar si la delcaracion fue presentada');
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => sqlerrm);
        end;

        --Se obtiene la homologacion de la declaracion
        begin
            json_hmlgcion :=  new json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS', v_id_dclrcion));
            
            v_sncion_dclrcion := json_hmlgcion.get_string('VASA');
        exception
            when others then
                 return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se encontro parametrizado la homologacion del formulario');
        end;
        
        --Se calcula la sancion
        begin
            v_sncion := pkg_gi_sanciones.fnc_ca_valor_sancion(p_cdgo_clnte                  =>  p_cdgo_clnte,
                                                              p_id_dclrcion_vgncia_frmlrio  =>  c_candidato.id_dclrcion_vgncia_frmlrio,
                                                              p_idntfccion          =>  json_hmlgcion.get_string('IDEN'),
                                                              p_fcha_prsntcion        =>  v_fcha_prsntcion,
                                                              p_id_sjto_tpo                 =>  json_hmlgcion.get_string('SUTP'),
                                                              p_cdgo_sncion_tpo       =>  json_hmlgcion.get_string('CSTP'),
                                                              p_cdgo_dclrcion_uso       =>  v_cdgo_dclrcion_uso,
                                                              p_id_dclrcion_incial      =>  v_id_dclrcion_crrccion,
                                                              p_impsto_crgo         =>  json_hmlgcion.get_string('IMCA'),
                                                              p_ingrsos_brtos         =>  json_hmlgcion.get_string('INBR'),
                                                              p_saldo_favor         =>  json_hmlgcion.get_string('SAFV'));
        exception
            when others then 
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'No se pudo llamar la funcion que calcula la sancion');
        end;
        
        begin
            
            v_dfrncia := v_sncion - v_sncion_dclrcion;

            if v_sncion_dclrcion < v_sncion and v_dfrncia >=  v_vlr_sncion then                
                return 'S';
            end if;
        
        end;

    end loop;

    return 'N';

  end fnc_vl_sancion;
  
  function fnc_vl_sancion_correcion(p_cdgo_clnte          in  number,
                                    p_id_instncia_fljo    in  number) return varchar2 as
                          
    v_sncion_dclrcion       number;
    v_sncion                number;
    v_vlr_sncion            number;
    v_id_cnddto             number;
    v_id_sjto_impsto        number;
    v_id_fsclzcion_expdnte  number;
    v_dfrncia               number;
    v_fecha                 varchar2(1000);
    v_id_dclrcion           gi_g_declaraciones.id_dclrcion%type;
    v_fcha_prsntcion        gi_g_declaraciones.fcha_prsntcion%type;
    v_id_dclrcion_crrccion  gi_g_declaraciones.id_dclrcion_crrccion%type;
    v_cdgo_dclrcion_uso     gi_d_declaraciones_uso.cdgo_dclrcion_uso%type;
    json_hmlgcion           json_object_t;
    
  begin
    
    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
    
    --Se consulta el valor de la sancion del programa por el cual fue fiscalizado el candidato
    begin
        select b.vlr_sncion
        into v_vlr_sncion
        from fi_g_candidatos               a
        left join fi_d_programas_sancion   b   on  a.id_prgrma =   b.id_prgrma
        where b.cdgo_clnte = p_cdgo_clnte 
        and a.id_cnddto = v_id_cnddto;
    exception
        when no_data_found then
            null;
    end;
    
    for c_candidato in (select a.id_dclrcion,
                               a.id_dclrcion_vgncia_frmlrio
                        from v_fi_g_fiscalizacion_expdnte_dtlle a
                        where a.id_cnddto = v_id_cnddto
                        and not a.id_dclrcion is null) loop
                        
        --Se consulta la declaracion presentada
        begin
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
            where a.id_dclrcion_crrccion = c_candidato.id_dclrcion
            and id_sjto_impsto = v_id_sjto_impsto
            and cdgo_dclrcion_estdo in ('PRS', 'APL');
        exception 
            when others then
                null;        
        end;
        
        --Se valida si la sancion se liquido correctamente
        begin
            
            json_hmlgcion :=  new json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS', v_id_dclrcion));
        
            v_sncion_dclrcion := json_hmlgcion.get_string('VASA');
            
            v_sncion := pkg_gi_sanciones.fnc_ca_valor_sancion(p_cdgo_clnte                  =>  p_cdgo_clnte,
                                                              p_id_dclrcion_vgncia_frmlrio  =>  c_candidato.id_dclrcion_vgncia_frmlrio,
                                                              p_idntfccion          =>  json_hmlgcion.get_string('IDEN'),
                                                              p_fcha_prsntcion        =>  to_timestamp(json_hmlgcion.get_string('FLPA'), 'dd/mm/yyyy'),
                                                              p_id_sjto_tpo                 =>  json_hmlgcion.get_number('SUTP'),
                                                              p_cdgo_sncion_tpo       =>  json_hmlgcion.get_string('CSTP'),
                                                              p_cdgo_dclrcion_uso       =>  v_cdgo_dclrcion_uso,
                                                              p_id_dclrcion_incial      =>  v_id_dclrcion_crrccion,
                                                              p_impsto_crgo         =>  json_hmlgcion.get_number('IMCA'),
                                                              p_ingrsos_brtos         =>  json_hmlgcion.get_number('INBR'),
                                                              p_saldo_favor         =>  json_hmlgcion.get_string('SAFV'));
            
            v_dfrncia := v_sncion - v_sncion_dclrcion;
            
             /*return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                             p_mensaje => ' v_sncion_dclrcion ' || v_sncion);*/
            
                
            if v_vlr_sncion is not null then
                if v_sncion_dclrcion < v_sncion and v_dfrncia >=  v_vlr_sncion then                
                    return 'S';
                end if;
            end if;
        end;
    
    end loop;
    
    return 'N';
    
  end fnc_vl_sancion_correcion;

  
  --Funcion que valida que los actos opcionales se generen y notifiquen si son notificables
  function fnc_vl_acto_tarea(p_id_instncia_fljo    in number)return varchar2 as
  
  v_id_acto     number;
  v_dscrpcion   varchar2(100);
                                  
  begin
  
    begin
    
        for c_acto_tpo in (select  b.id_acto,
                                   c.dscrpcion,
                                   c.indcdor_ntfccion,
                                   d.fcha_ntfccion
                            from fi_g_fiscalizacion_expdnte    a
                            inner join fi_g_fsclzcion_expdnte_acto   b   on  a.id_fsclzcion_expdnte    =   b.id_fsclzcion_expdnte
                            inner join gn_d_actos_tipo               c   on  b.id_acto_tpo             =   c.id_acto_tpo
                            left  join gn_g_actos                    d   on  b.id_acto                 =   d.id_acto 
                            where a.id_instncia_fljo = p_id_instncia_fljo) loop
        
            if c_acto_tpo.indcdor_ntfccion = 'S' and c_acto_tpo.fcha_ntfccion is null then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'Genere, confirme y notifique el ' || lower(c_acto_tpo.dscrpcion)); 
            elsif c_acto_tpo.id_acto is null then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'Genere y confirme el ' || lower(c_acto_tpo.dscrpcion));
            end if;
        
        end loop;
        
       return 'S';
    
    end;
    
  end fnc_vl_acto_tarea;

  function fnc_vl_expediente_padre(p_id_instncia_fljo    in  number)return varchar2 as
  
  v_id_fsclzcion_expdnte_pdre   number;
  
  begin
  
    begin
        select id_fsclzcion_expdnte_pdre
        into v_id_fsclzcion_expdnte_pdre
        from fi_g_fiscalizacion_expdnte
        where id_fsclzcion_expdnte_pdre = (select id_fsclzcion_expdnte from fi_g_fiscalizacion_expdnte
                                           where id_instncia_fljo = p_id_instncia_fljo);
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'Genere el expediente del programa sancionatorio'); 
    
    end;
    
    return 'S';

  end fnc_vl_expediente_padre;

  --Funcion que valida que se generen todo los actos obligatorios de una tarea
  function fnc_vl_acto_fisca(p_cdgo_clnte         in number,
                             p_id_fljo_trea       in number,
                             p_id_instncia_fljo   in number)return varchar2 as
  
  v_id_fsclzcion_expdnte_acto number;
  v_id_prgrma                 number;
  v_id_sbprgrma               number;
  c_contador                  number := 0;
  
  begin
    
    --Se obtiene el programa y subprograma por el cual se esta fiscalizando
    begin
        select a.id_prgrma,
               a.id_sbprgrma
        into v_id_prgrma,
             v_id_sbprgrma
        from fi_g_candidatos            a
        join fi_g_fiscalizacion_expdnte b   on  a.id_cnddto =   b.id_cnddto
        where b.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el programa y subprograma'); 
         when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => sqlerrm); 
    end;
  
    for v_acto in (select a.dscrpcion,
                          a.id_acto_tpo
                   from gn_d_actos_tipo                    a 
                   inner join gn_d_actos_tipo_tarea        b   on  a.id_acto_tpo            = b.id_acto_tpo
                   inner join fi_d_programas_acto          c   on  a.id_acto_tpo            = c.id_acto_tpo
                   where a.cdgo_clnte = p_cdgo_clnte
                   and b.indcdor_oblgtrio = 'S'
                   and b.id_fljo_trea = p_id_fljo_trea
                   and c.id_prgrma = v_id_prgrma
                   and c.id_sbprgrma = v_id_sbprgrma) loop
                   
        begin
            select a.id_fsclzcion_expdnte_acto
            into v_id_fsclzcion_expdnte_acto
            from fi_g_fsclzcion_expdnte_acto    a
            join fi_g_fiscalizacion_expdnte     b   on  a.id_fsclzcion_expdnte  =   b.id_fsclzcion_expdnte
            where b.id_instncia_fljo = p_id_instncia_fljo
            and a.id_acto_tpo = v_acto.id_acto_tpo
            and a.id_fljo_trea = p_id_fljo_trea--agregar a desarrollo
            and  not a.id_acto is null;
            
            /*select a.id_fsclzcion_expdnte_acto
            into v_id_fsclzcion_expdnte_acto
            from fi_g_fsclzcion_expdnte_acto    a
            join fi_g_fiscalizacion_expdnte     b   on  a.id_fsclzcion_expdnte  =   b.id_fsclzcion_expdnte
            where b.id_instncia_fljo = p_id_instncia_fljo
            and a.id_acto_tpo = v_acto.id_acto_tpo
            and  not a.id_acto is null ;*/
        exception
            when no_data_found then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'Genere el ' || lower(v_acto.dscrpcion));
        end;
        
        c_contador := c_contador + 1;
    end loop;
    
    if c_contador = 0 then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                             p_mensaje => 'Parametrize los acto en la etapa en la que se encuentra');
    end if;
    
    return 'S';
  
  end fnc_vl_acto_fisca;

  function fnc_vl_recurso(p_cdgo_clnte          in  number,
                          p_id_instncia_fljo    in  number,
                          p_id_fljo_trea        in  number) return varchar2 as
  
  pragma autonomous_transaction;
  
  v_id_acto                     number;
  v_id_rcrso                    number;
  o_cdgo_rspsta                 number;
  v_id_cnddto                   number;
  v_id_sjto_impsto              number;
  v_id_fsclzcion_expdnte        number;
  v_nmro_acto                   number;
  v_id_fsclzcion_expdnte_acto   number;
  o_mnsje_rspsta                varchar2(1000);
  o_estdo_instncia              varchar2(20);
  
  
  begin
  
    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
  
    for c_acto in (select  b.id_acto_tpo,
                           b.dscrpcion,
                           a.indcdor_oblgtrio
                   from gn_d_actos_tipo_tarea  a
                   join gn_d_actos_tipo        b   on  a.id_acto_tpo   =   b.id_acto_tpo
                   where b.cdgo_clnte = p_cdgo_clnte 
                   and a.indcdor_oblgtrio = 'S'
                   and a.id_fljo_trea = p_id_fljo_trea) loop
        
        --Se valida si el tipo de acto fue generado en el expediente
        begin
            select a.id_acto,
                   a.id_rcrso,
                   b.nmro_acto,
                   a.id_fsclzcion_expdnte_acto
            into v_id_acto,
                 v_id_rcrso,
                 v_nmro_acto,
                 v_id_fsclzcion_expdnte_acto
            from fi_g_fsclzcion_expdnte_acto    a
            join gn_g_actos                     b   on  a.id_acto   =  b.id_acto
            where a.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
            and a.id_acto_tpo = c_acto.id_acto_tpo;
        exception
            when others then
                null;
        end;
        
        if v_id_acto is not null then
            begin
                pkg_fi_fiscalizacion.prc_ac_expdnte_acto_vgncia(p_cdgo_clnte   => p_cdgo_clnte,
                                                                p_id_acto        => v_id_acto,
                                                                o_estdo_instncia => o_estdo_instncia,
                                                                o_cdgo_rspsta  => o_cdgo_rspsta,
                                                                o_mnsje_rspsta   => o_mnsje_rspsta);
               
                
            exception
                when others then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                         p_mensaje => o_mnsje_rspsta); 
            end;
        end if;
        
        if v_id_rcrso is not null and o_estdo_instncia <> 'FINALIZADA' then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'Gestion Juridica le de respuesta al recurso interpuesto por el contribuyente al acto ' || v_nmro_acto);
        
        elsif  v_id_rcrso is not null and o_estdo_instncia = 'FINALIZADA' then
            
            for c_acto_vgncia in (select b.acptda_jrdca 
                                  from fi_g_fsclzcion_expdnte_acto    a
                                  join fi_g_fsclzcion_acto_vgncia     b   on  a.id_fsclzcion_expdnte_acto =   b.id_fsclzcion_expdnte_acto
                                  where a.id_fsclzcion_expdnte_acto = v_id_fsclzcion_expdnte_acto) loop
        
                if c_acto_vgncia.acptda_jrdca = 'N' then
                    return 'N';
                end if;
    
            end loop;
            
            return 'S';
        end if;
            
    end loop;
    
    --Se retorna N si no tiene un recurso
    return 'N';
  
  end fnc_vl_recurso;

  function fnc_vl_requerimiento_ordinario(p_cdgo_clnte        in  number,
                                          p_id_instncia_fljo  in  number,
                                          p_id_fljo_trea      in  number) return varchar2 as
  
  v_result                  varchar2(100);
  v_undad_drcion            varchar2(10);
  v_dia_tpo                 varchar2(10);
  v_dscrpcion               varchar2(300);
  v_fcha_incial             timestamp;
  v_fcha_fnal               timestamp;
  v_drcion                  number;
  v_id_acto                 number;
  v_id_acto_tpo             number;
  v_id_cnddto               number;
  v_id_sjto_impsto          number;
  v_id_fsclzcion_expdnte    number;
  
  begin
  
    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
    begin
        select b.id_acto_tpo,
               b.id_acto,
               c.dscrpcion
        into v_id_acto_tpo,
             v_id_acto,
             v_dscrpcion
        from fi_g_fiscalizacion_expdnte     a
        join fi_g_fsclzcion_expdnte_acto    b   on  a.id_fsclzcion_expdnte  =   b.id_fsclzcion_expdnte
        join gn_d_actos_tipo                c   on  b.id_acto_tpo           =   c.id_acto_tpo
        where a.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
        and b.id_acto_tpo = (
                                select a.id_acto_tpo 
                                from gn_d_actos_tipo a
                                where a.cdgo_clnte = p_cdgo_clnte
                                and a.cdgo_acto_tpo = 'ROO'
                            );
    exception
        when no_data_found then
            return 'S';
    end;
    
    --Se obtiene termino del acto
    begin
        select undad_drcion,
               drcion,
               dia_tpo
        into  v_undad_drcion,
              v_drcion,
              v_dia_tpo
        from gn_d_actos_tipo_tarea
        where id_acto_tpo = v_id_acto_tpo
        and id_fljo_trea = p_id_fljo_trea;
        
        if v_undad_drcion is null then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje => 'Que parametrice el termino del acto ' || v_dscrpcion); 
        end if;
        
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje => 'No se encontro parametrizado el acto ' || v_dscrpcion || ' en la etapa del flujo en la que se encuentra'); 
    end;
    
    --Se obtiene la fecha de notificacion del acto
    begin
        select fcha_ntfccion 
        into v_fcha_incial
        from gn_g_actos a
        where a.id_acto = v_id_acto;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Confirme el ' || v_dscrpcion);
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Problema al obtener la fecha de generancion del Acto');
    end;
    
    if v_fcha_incial is null then
        return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                            , p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' haya sido notificado ');
    end if;
    
    --Se obtiene la fecha final
    begin
        v_fcha_fnal :=  pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte     => p_cdgo_clnte, 
                                                              p_fecha_inicial  => v_fcha_incial,
                                                              p_undad_drcion   => v_undad_drcion,
                                                              p_drcion         => v_drcion,
                                                              p_dia_tpo        => v_dia_tpo);
    
        if v_fcha_fnal is not null then
            if systimestamp >= v_fcha_fnal then
                return 'S';
            end if;
        end if;

    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                            , p_mensaje => 'No se pudo llamar la funcion fnc_cl_fecha_final');
    end;
    
    select 
        case v_undad_drcion
            when 'MN' then 'Minutos'
            when 'HR' then 'Hora'
            when 'DI' then 'Dias'
            when 'SM' then 'Semana'
            when 'MS' then 'Mes'
        end
    into v_undad_drcion  
    from dual;
    
    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                          p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' cumpla el termino de ' || v_drcion ||' '|| v_undad_drcion);
  
  end fnc_vl_requerimiento_ordinario;

  function fnc_vl_finaliza_expediente(p_fnlzcion  in  varchar2) return varchar2 as
  
  begin
    
    if p_fnlzcion = 'S' then
        return 'S';
    end if;
    
    return 'N';
    
  end fnc_vl_finaliza_expediente;

    function fnc_vl_pago_pliego_cargo(p_id_instncia_fljo  in  number) return varchar2 as
    
    pragma autonomous_transaction;
    
    v_id_cnddto             number;
    v_id_fsclzcion_expdnte  number;
    v_cdgo_clnte            number;
    v_total                 number;
    v_cdgo_rspsta           number;
    v_mnsje_rspsta          number;
    v_contador              number := 0;
    
    begin
        
        --Se obtiene el candidato
        begin
            select a.id_cnddto,
                   a.id_fsclzcion_expdnte,
                   a.cdgo_clnte
            into v_id_cnddto,
                 v_id_fsclzcion_expdnte,
                 v_cdgo_clnte
            from v_fi_g_fiscalizacion_expdnte a
            where a.id_instncia_fljo = p_id_instncia_fljo;
            exception 
                when no_data_found then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                         p_mensaje => 'Que se encuentre el candidato para validar si realizo el pago');
                when others then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                         p_mensaje => sqlerrm);
        end;
        
        for c_vgncia in (select a.cdgo_clnte,
                                a.id_impsto,
                                a.id_impsto_sbmpsto,
                                a.id_sjto_impsto,
                                b.vgncia,
                                b.id_prdo,
                                b.id_lqdcion
                         from v_fi_g_candidatos            a
                         join v_fi_g_fiscalizacion_expdnte_dtlle b on  a.id_cnddto =   b.id_cnddto
                         where a.id_cnddto = v_id_cnddto) loop
    
            begin
                select sum(b.vlor_dbe) - sum(b.vlor_hber) as total
                into v_total
                from gf_g_movimientos_financiero    a
                join gf_g_movimientos_detalle       b   on  a.id_mvmnto_fncro   =   b.id_mvmnto_fncro
                where a.cdgo_clnte = c_vgncia.cdgo_clnte
                and a.id_impsto = c_vgncia.id_impsto
                and a.id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
                and a.id_sjto_impsto = c_vgncia.id_sjto_impsto
                and a.vgncia = c_vgncia.vgncia
                and a.id_prdo = c_vgncia.id_prdo
                and a.cdgo_mvmnto_orgn = 'LQ'
                and a.id_orgen = c_vgncia.id_lqdcion;
                
            exception
                when others then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                          p_mensaje => 'Se valide el pago del pliego de cargo');
            end;
            
            if v_total is null or v_total > 0 then
                return 'N';
            end if;
            
            v_contador := v_contador + 1;
            
        end loop;
     
        if v_contador = 0 then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'Se valide el pago del pliego de cargo');
        end if;
        
        begin
        
            pkg_fi_fiscalizacion.prc_ac_estdo_fsclz_exp_cnd_vgn(p_cdgo_clnte => v_cdgo_clnte,
                                                                p_id_fsclzcion_expdnte => v_id_fsclzcion_expdnte,
                                                                o_cdgo_rspsta => v_cdgo_rspsta,
                                                                o_mnsje_rspsta => v_mnsje_rspsta); 
                                                                
            if v_cdgo_rspsta > 0 then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => v_mnsje_rspsta);
            end if;
            
        end;
     
    return 'S';
    
    end fnc_vl_pago_pliego_cargo;
    
  function fnc_vl_dfncion_emplzmnto_crrcn(p_cdgo_clnte in  number) return varchar2 as
  
  v_vlor    varchar2(5);
  
  begin
    
    begin
        select b.vlor
        into v_vlor
        from df_c_definiciones_clnte_ctgria a
        join df_c_definiciones_cliente      b   on  a.id_dfncion_clnte_ctgria   =   b.id_dfncion_clnte_ctgria
        where a.cdgo_clnte =  p_cdgo_clnte
        and b.cdgo_dfncion_clnte = 'EMP';
    exception
        when no_data_found then
            return 'N';
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje =>  sqlerrm);
    end;
        
    return 'S';
  end fnc_vl_dfncion_emplzmnto_crrcn;
  
  function fnc_vl_trmno_acto_plgo_crgo(p_cdgo_clnte                in  number,
                                       p_id_fljo_trea              in  number,
                                       p_id_instncia_fljo          in  number) return varchar2 as
  v_result                  varchar2(100);
  v_undad_drcion            varchar2(10);
  v_dia_tpo                 varchar2(10);
  v_dscrpcion               varchar2(300);
  v_fcha_incial             timestamp;
  v_fcha_fnal               timestamp;
  v_drcion                  number;
  v_id_acto                 number;
  v_id_acto_tpo             number;
  v_id_cnddto               number;
  v_id_sjto_impsto          number;
  v_id_fsclzcion_expdnte    number;
    
  
  begin
    
    --Se obtiene el candidato y el sujeto impuesto
    begin
        select b.id_cnddto,
               b.id_sjto_impsto,
               a.id_fsclzcion_expdnte
        into  v_id_cnddto,
              v_id_sjto_impsto,
              v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
    for c_pliego in (select a.id_acto_tpo,
                            a.dscrpcion
                     from gn_d_actos_tipo        a 
                     join gn_d_actos_tipo_tarea  b   on  a.id_acto_tpo = b.id_acto_tpo
                     where a.cdgo_clnte = p_cdgo_clnte
                     and b.id_fljo_trea = p_id_fljo_trea) loop
                     
        --Se valida si el acto fue generado en el expediente de fiscalizacion
        begin
            select id_acto,
                   id_acto_tpo
            into   v_id_acto,
                   v_id_acto_tpo
            from fi_g_fsclzcion_expdnte_acto
            where id_acto_tpo = c_pliego.id_acto_tpo
            and id_fsclzcion_expdnte = v_id_fsclzcion_expdnte;
        exception
            when others then
                null;
        end;
        
        if v_id_acto is not null then
            exit;
        end if;
    
    end loop;
    
    --Se obtiene termino del acto
    begin
        select undad_drcion,
               drcion,
               dia_tpo
        into  v_undad_drcion,
              v_drcion,
              v_dia_tpo
        from gn_d_actos_tipo_tarea
        where id_acto_tpo = v_id_acto_tpo;
            exception
                when no_data_found then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'No se encontro parametrizado el acto ' || v_dscrpcion || ' en la etapa del flujo en la que se encuentra');
                when others then
                    return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                        , p_mensaje => 'Otra Exception');      
    end;
    
    --Se obtiene la fecha de notificacion del acto
    begin
        select fcha_ntfccion 
        into v_fcha_incial
        from gn_g_actos a
        where a.id_acto = v_id_acto;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Genere el ' || v_dscrpcion);
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                , p_mensaje => 'Problema al obtener la fecha de generancion del Acto');
    end;
    
    if v_fcha_incial is null then
        return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                            , p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' haya sido notificado ');
    end if;
    
    --Se obtiene la fecha final
    begin
        v_fcha_fnal :=  pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte     => p_cdgo_clnte, 
                                                              p_fecha_inicial  => v_fcha_incial,
                                                              p_undad_drcion   => v_undad_drcion,
                                                              p_drcion         => v_drcion,
                                                              p_dia_tpo        => v_dia_tpo);
    
        if v_fcha_fnal is not null then
            if trunc(systimestamp) + 30 >= trunc(v_fcha_fnal) then
                return 'S';
            end if;
        end if;

    exception
        when others then
            null;
    end;
    
    select 
        case v_undad_drcion
            when 'MN' then 'Minutos'
            when 'HR' then 'Hora'
            when 'DI' then 'Dias'
            when 'SM' then 'Semana'
            when 'MS' then 'Mes'
        end
    into v_undad_drcion  
    from dual;
    
     return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                          p_mensaje => 'Que el acto ' || lower(v_dscrpcion) || ' cumpla el termino de ' || v_drcion ||' '|| v_undad_drcion ||','|| ' fecha del termino ' || trunc(v_fcha_fnal));
                                          
  
  end fnc_vl_trmno_acto_plgo_crgo;

  function fnc_vl_impuesto_acto(p_id_instncia_fljo  in  number) return varchar2 as
  
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    v_cdgo_rspsta       number;
    v_mnsje_rspsta      varchar2(200);
    v_cdgo_sbprgrma     varchar2(5);
  begin
  
    begin
        select  a.id_cnddto,
                a.id_sjto_impsto,
                c.cdgo_sbprgrma      
                into v_id_cnddto,
                     v_id_sjto_impsto,
                     v_cdgo_sbprgrma      
                from fi_g_candidatos            a
                join fi_g_fiscalizacion_expdnte b   on  a.id_cnddto =   b.id_cnddto
                join fi_d_subprogramas          c   on  a.id_prgrma =   c.id_prgrma 
                                    and a.id_sbprgrma   =   c.id_sbprgrma
                where b.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false 
                                                    , p_mensaje => 'No se encontro el candidato y el sujeto impuesto');
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false 
                                                    , p_mensaje => sqlerrm);
    end;
    case 
        when v_cdgo_sbprgrma = 'SML' THEN
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
                                                select pkg_fi_fiscalizacion.fnc_co_sancion_mal_liquidada(v_id_cnddto, v_id_sjto_impsto) 
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
                                                  p_mensaje => c_sncion.mnsje_rspsta);*/
            v_cdgo_rspsta      := c_sncion.cdgo_rspsta;
            v_mnsje_rspsta     := c_sncion.mnsje_rspsta;                                      
        end if;
    
    end loop;
         when v_cdgo_sbprgrma = 'EXT' THEN
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
                                                select pkg_fi_fiscalizacion.fnc_co_sancion_extemporanea(v_id_cnddto, v_id_sjto_impsto) 
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
                           return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                                  p_mensaje => c_sncion.mnsje_rspsta);
                            /* v_cdgo_rspsta      := c_sncion.cdgo_rspsta;
                            v_mnsje_rspsta     := c_sncion.mnsje_rspsta;*/
                        end if;
    
            end loop;
        when v_cdgo_sbprgrma = 'NEI' THEN
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
                                                select pkg_fi_fiscalizacion.fnc_co_sancion_no_enviar_informacion(v_id_cnddto, v_id_sjto_impsto) 
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
                                                          p_mensaje => c_sncion.mnsje_rspsta);*/
                    v_cdgo_rspsta      := c_sncion.cdgo_rspsta;
                    v_mnsje_rspsta     := c_sncion.mnsje_rspsta;
                end if;
                
            end loop;
            
        end case;
            if v_cdgo_rspsta > 0 then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje => v_mnsje_rspsta);
            end if;
    
    
    return 'S';
    
  end fnc_vl_impuesto_acto;

  function fnc_vl_aplicacion_liquidacion(p_id_instncia_fljo  in  number) return varchar2 as
                                         
  v_indcdor_aplcdo varchar2(3);
  
  begin
  
    begin
        select b.indcdor_aplcdo
        into v_indcdor_aplcdo
        from fi_g_fiscalizacion_expdnte     a
        join fi_g_fsclzcion_expdnte_acto    b   on  a.id_fsclzcion_expdnte  =   b.id_fsclzcion_expdnte
        join gn_d_actos_tipo                c   on  b.id_acto_tpo           =   c.id_acto_tpo
        where a.id_instncia_fljo = p_id_instncia_fljo
        and c.cdgo_acto_tpo = 'LODA'
        and b.indcdor_aplcdo = 'S';
    exception
        when no_data_found then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje => 'Aplique la liquidacion de Aforo');
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje =>  sqlerrm);
    end;
  
    return 'S';
    
  end fnc_vl_aplicacion_liquidacion;
  
  function fnc_vl_dfncion_lqudcn_ofcl_afr(p_cdgo_clnte in  number) return varchar2 as
  
  v_vlor    varchar2(5);
  
  begin
  
    return 'N';
    
    begin
        select b.vlor
        into v_vlor
        from df_c_definiciones_clnte_ctgria a
        join df_c_definiciones_cliente      b   on  a.id_dfncion_clnte_ctgria   =   b.id_dfncion_clnte_ctgria
        where a.cdgo_clnte =  p_cdgo_clnte
        and b.cdgo_dfncion_clnte = 'LOA';
    exception
        when no_data_found then
            return 'N';
        when others then
            return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                  p_mensaje =>  sqlerrm);
    end;
        
    return 'S';
    
  end fnc_vl_dfncion_lqudcn_ofcl_afr;
 
     function fnc_vl_inscripcion(p_cdgo_clnte          in  number,
                              p_id_instncia_fljo    in  number) return varchar2 as
                              
    v_id_sjto_estdo       number;
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    
  begin
    
    begin
        select b.id_cnddto,
               b.id_sjto_impsto
        into  v_id_cnddto,
              v_id_sjto_impsto
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener el sujeto impuesto del flujo ' || p_id_instncia_fljo );
    end;
  
                          
        --Se consulta si el sujeto se encuentra activo (Estado 1)
        begin
            select  id_sjto_estdo 
      into  v_id_sjto_estdo
      from  si_i_sujetos_impuesto 
      where id_sjto_impsto = v_id_sjto_impsto and id_sjto_estdo = 1; 
        exception 
            when no_data_found then
                return 'N';
        end;
    
   return 'S';
    
  end fnc_vl_inscripcion;
  
  
  /*
    Funcion agregada para validar si existe una liquidacion pagada en rentas.
    01/08/22
    @LUIS ARIZA    
  */
  
  
  function fnc_vl_liquidacion_renta(p_cdgo_clnte          in  number,
                 p_id_instncia_fljo    in  number) return varchar2 as
                              
v_cdgo_clnte      number;
v_id_impsto             number;
v_id_impsto_sbmpsto     number;
v_id_sjto_impsto        number;
v_fcha_expdcion         date;
v_bse                   number;
v_id_acto_tpo           number;
v_indcdor_rnta_pgda   varchar2(1);
v_nmro_cntrto           varchar2(50);
    
  begin
    
    begin
    select   b.cdgo_clnte
        ,b.id_impsto
        ,b.id_impsto_sbmpsto
                ,d.id_acto_tpo
        ,b.id_sjto_impsto
                ,trunc(c.fcha_expdcion)
        ,d.bse
                ,e.nmro_cntrto
    into    
                v_cdgo_clnte
        ,v_id_impsto
        ,v_id_impsto_sbmpsto
                ,v_id_acto_tpo
        ,v_id_sjto_impsto
        ,v_fcha_expdcion
        ,v_bse
                ,v_nmro_cntrto
    from fi_g_fiscalizacion_expdnte a 
    join fi_g_candidatos b on a.id_cnddto = b.id_cnddto
    join fi_g_candidatos_vigencia c on b.id_cnddto = c.id_cnddto
    join fi_g_fiscalizacion_sancion d on a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
        join fi_g_fscalizacion_renta e on d.id_fsclzcn_rnta = e.id_fsclzcn_rnta
    where a.id_instncia_fljo = p_id_instncia_fljo
        and rownum = 1
    ;
    exception
        when others then
            return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'No se pudo obtener la informacion de la liquidacion del flujo : ' || p_id_instncia_fljo );
    end;
  
                        
        --Se consulta la declaracion presentada
    begin
    select  a.indcdor_rnta_pgda 
    into    v_indcdor_rnta_pgda
    from gi_g_rentas  a
    join gi_g_rentas_acto b on a.id_rnta = b.id_rnta
    join v_sg_g_usuarios c on a.id_usrio = c.id_usrio
    where a.cdgo_clnte          = v_cdgo_clnte
    and a.id_impsto         = v_id_impsto
    and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
    and b.id_impsto_acto    = v_id_acto_tpo
    and a.id_sjto_impsto    = v_id_sjto_impsto
        and a.txto_ascda        = v_nmro_cntrto
    --and a.fcha_expdcion     = v_fcha_expdcion
    and a.vlor_bse_grvble   = v_bse
    and a.indcdor_rnta_pgda  = 'S'
    and rownum = 1;           
              
                
    return 'S'; 
        exception 
            when no_data_found then
                return 'N';
        end; 
        
  
    
  end fnc_vl_liquidacion_renta;
  
  /*<------------------------------------- Fin Funciones Fiscalizacion -------------------------------->*/

/*<-------------------------------------- Funciones Vehiculos -------------------------------->*/
      /*Funcion indicador de novedades con reliquidacion */
       function fnc_vl_nvdd_rlqudcion(p_cdgo_nvdad_tpo in varchar2) return varchar2 is
          v_indcdor varchar2(1) := 'N';
       begin
          select s.indcdor
            into v_indcdor
            from si_d_novedades_tipo s
           where s.cdgo_nvdad_tpo = p_cdgo_nvdad_tpo
             and s.cdgo_sjto_tpo = 'V';
          return v_indcdor;
       exception
          when others then
             return v_indcdor;
       end;
       
     function fnc_vl_nvdd_trasicion(p_cdgo_valdccn varchar2) return varchar2 is
      
       begin
         if  p_cdgo_valdccn is null then 
             return 'N'; 
         elsif p_cdgo_valdccn = 'N' then 
              return 'N'; 
         else 
               return 'S';
         /*fnc_wf_error(p_value   => false
                           ,p_mensaje => 'No se puede continuar, la solicitud aun no ha sido resuelta.');*/
          end if; 
       exception
          when others then
            return fnc_wf_error(p_value   => false
                           ,p_mensaje => 'No se puede continuar, la solicitud aun no ha sido resuelta.');
       end;
    
      /*<-------------------------------------- Fin Funciones Vehiculos -------------------------------->*/



/*<----------------------------------------- Funciones Seguridad -------------------------------->*/
    /*Funcion de solicitud de relacion usuario sujeto-impuesto*/
    function fnc_vl_usrio_sjto_impsto(p_id_instncia_fljo       in number)
    return varchar2 is
    
        v_cdgo_rspsta varchar2(10);
    begin
        begin
            select  a.cdgo_rspsta
            into    v_cdgo_rspsta
            from    sg_g_usrios_slctud  a
            where   a.id_instncia_fljo  =   p_id_instncia_fljo;
        exception
            when others then
                return fnc_wf_error(p_value   => false
                                   ,p_mensaje => 'No se puede continuar, no se pudo validar la solicitud.');
            end;
        return fnc_wf_error(p_value   => v_cdgo_rspsta is not null
                           ,p_mensaje => 'No se puede continuar, la solicitud aun no ha sido resuelta.');
    end fnc_vl_usrio_sjto_impsto;
    /*<--------------------------------------Fin Funciones Seguridad -------------------------------->*/

    function fnc_vl_quejas_reclamo_rspsta(p_id_instncia_fljo  in  number)
    return varchar2
    as
        v_id_qja_rclmo  number;
    begin
        begin
            select id_qja_rclmo
              into v_id_qja_rclmo
              from pq_g_quejas_reclamo
             where id_instncia_fljo = p_id_instncia_fljo
               and rspsta is not null;

            return 'S';
        exception
            when others then
                return pkg_wf_funciones.fnc_wf_error( p_value   => false
                                                    , p_mensaje => 'Registrar una respuesta.');
        end;
    end fnc_vl_quejas_reclamo_rspsta;

function fnc_vl_exncion_rnta( p_cdgo_clnte         in number,
                                p_id_instncia_fljo   in number ) return varchar2 as

       v_indcdor_exncion                varchar(1); 

    begin

        --Se obtiene si la renta tiene exencion
        begin
            select  a.indcdor_exncion
            into    v_indcdor_exncion
            from    gi_g_rentas a
            where   id_instncia_fljo = p_id_instncia_fljo;
        exception
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                     p_mensaje => 'No se pudo consultar si la renta tiene Exencion');
        end;
    
        
        if v_indcdor_exncion = 'S' then 
      return 'S';
        else  
            return 'N';
        end if; 

    end fnc_vl_exncion_rnta;
  
  
  
  function fnc_vl_crtfccion_rnta_aprbda( p_cdgo_clnte          in number,
                                          p_id_rnta             in number,
                                          p_id_rnta_dcmnto      in number,
                                          p_id_instncia_fljo    in number ) return varchar2 as

       v_id_usrio_rvso                number; 

    begin

        --Se consulta si ya fue revisada la certificacion
        begin
            select  id_usrio_rvso
            into    v_id_usrio_rvso
            from    gi_g_rentas_documento a
            where   id_rnta_dcmnto = p_id_rnta_dcmnto
                    and id_rnta = p_id_rnta
                    and id_instncia_fljo = p_id_instncia_fljo;
        exception
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                     p_mensaje => 'No se pudo consultar si la certificacion esta Revisada');
        end;
    
        
        if v_id_usrio_rvso is not null then 
      return 'S';
        else  
            return 'N';
        end if; 

    end fnc_vl_crtfccion_rnta_aprbda;
    function fnc_vl_convenio_exista(p_cdgo_clnte number
                                  --,p_id_impsto            number
                                  --,p_id_impsto_sbmpsto    number
                                 ,
                                  p_id_sjto_impsto number) return varchar2 is
  
    v_acrdo_exste varchar2(1);
  
  begin
  
    begin
      select 'S'
        into v_acrdo_exste
        from gf_g_convenios
       where id_sjto_impsto = p_id_sjto_impsto
         and cdgo_cnvnio_estdo = 'APL'
         and cdgo_clnte = p_cdgo_clnte;
      if v_acrdo_exste = 'S' then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'No se puede seguir con la novedad ya que tiene un convenio asociado, Por favor finalice el flujo.');
      
      end if;
    exception
      when no_data_found then
        v_acrdo_exste := 'N';
    end;
  
    return v_acrdo_exste;
  
  end;

 function fnc_vl_convenio_exista_estrato(p_cdgo_clnte number
                                  --,p_id_impsto            number
                                  --,p_id_impsto_sbmpsto    number
                                 ,
                                  p_id_sjto_impsto number) return varchar2 is
  
    v_acrdo_exste varchar2(1);
  
  begin
  
    begin
      select 'S'
        into v_acrdo_exste
        from gf_g_convenios
       where id_sjto_impsto = p_id_sjto_impsto
         and cdgo_cnvnio_estdo = 'APB'
         and cdgo_clnte = p_cdgo_clnte;
      if v_acrdo_exste = 'S' then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'No se puede seguir con la novedad ya que tiene un convenio asociado, Por favor finalice el flujo.');
      
      end if;
    exception
      when no_data_found then
        v_acrdo_exste := 'N';
    end;
  
    return v_acrdo_exste;
  
  end;
  
  function fnc_vl_expediente_analisis(p_cdgo_clnte          in  number,
                                      p_id_expdnte_anlsis    in  number  default null,
                                      p_id_instncia_fljo       in number) return varchar2 as
                              
    v_indcdor_blqdo       varchar2(1);
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
	v_id_fsclzcion_expdnte	number;
    
  begin
        
         begin
                select b.id_cnddto,
                       b.id_sjto_impsto,
                       a.id_fsclzcion_expdnte
                into  v_id_cnddto,
                      v_id_sjto_impsto,
                      v_id_fsclzcion_expdnte
                from fi_g_fiscalizacion_expdnte a
                join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
                join fi_g_expedientes_analisis c on a.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                where c.id_expdnte_anlsis = p_id_expdnte_anlsis;
            exception
                when others then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                         p_mensaje => 'No se pudo consultar el expediente analisis ' || p_id_expdnte_anlsis );
            end;
           
    
                          
        --Se consulta el indicador bloqueado
        begin	
			select	indcdor_blqdo 
			into	v_indcdor_blqdo
			from	fi_g_expndnts_anlsis_dtlle  a
            join    fi_g_expedientes_analisis  d   on  a.id_expdnte_anlsis = d.id_expdnte_anlsis
			join	fi_g_fsclzc_expdn_cndd_vgnc b on a.id_fsclzc_expdn_cndd_vgnc = b.id_fsclzc_expdn_cndd_vgnc
			join    fi_g_candidatos_vigencia c on b.id_cnddto_vgncia = c.id_cnddto_vgncia
                                    and a.id_prdo = c.id_prdo
			where b.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
            and d.id_instncia_fljo = p_id_instncia_fljo
            fetch first 1 rows only   ;
			
			if v_indcdor_blqdo = 'S' then 
					return 'S';
			end if;
			
        exception 
            when no_data_found then
                return 'N';
			when others then
			 return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'Error al validar el indicador bloqueado del expediente ' || v_id_fsclzcion_expdnte );
        end;
		
		
    
   return 'N';
    
  end fnc_vl_expediente_analisis;
  
  /*
    Función que valida si existe un solicitud de análisis activa
    asociada a un expediente, en caso tal tenga una solicitud activa devolvera un 
    mensaje indicando que existe una solicut abierta por finalizar.

  */
   function fnc_vl_expediente_analisis_fisca(p_cdgo_clnte          in  number,
                                            p_id_instncia_fljo   in  number  default null) return varchar2 as
                              
    v_indcdor_blqdo       varchar2(1);
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    v_id_expdnte_anlsis number;
    v_id_instncia_fljo      number;
    v_nmro_rdcdo_dsplay varchar2(30);
	v_id_fsclzcion_expdnte	number;
    
  begin
        begin
            select b.id_cnddto,
                   b.id_sjto_impsto,
                   a.id_fsclzcion_expdnte,
                   d.id_instncia_fljo
            into  v_id_cnddto,
                  v_id_sjto_impsto,
                  v_id_fsclzcion_expdnte,
                  v_id_instncia_fljo
            from fi_g_fiscalizacion_expdnte a
            join fi_g_expedientes_analisis  d  on  a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
            join fi_g_fsclzc_expdn_cndd_vgnc e  on  a.id_fsclzcion_expdnte = e.id_fsclzcion_expdnte
                                                and  e.id_slctud =   d.id_slctud               
            join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
            where a.id_instncia_fljo = p_id_instncia_fljo ;
        exception
             when no_data_found then
                return 'N';
            when others then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                     p_mensaje => 'No se pudo consultar el expediente del flujo ' ||p_id_instncia_fljo);
        end;
                                      
        --Se consulta el indicador bloqueo
        begin	
			select	indcdor_blqdo,
                    a.id_expdnte_anlsis                    
			into	v_indcdor_blqdo,
                    v_id_expdnte_anlsis
			from	fi_g_expndnts_anlsis_dtlle  a
            join    fi_g_expedientes_analisis  d   on  a.id_expdnte_anlsis = d.id_expdnte_anlsis
			join	fi_g_fsclzc_expdn_cndd_vgnc b on a.id_fsclzc_expdn_cndd_vgnc = b.id_fsclzc_expdn_cndd_vgnc
			join    fi_g_candidatos_vigencia c on b.id_cnddto_vgncia = c.id_cnddto_vgncia
                                    and a.id_prdo = c.id_prdo
			where b.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
            and d.id_instncia_fljo = v_id_instncia_fljo ;		
        exception 
            when no_data_found then
                return 'N';
			when others then
			 return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'Error al validar el indicador bloqueado del expediente ' || v_id_fsclzcion_expdnte );
        end;
		
		if v_indcdor_blqdo = 'S' then 
            select b.nmro_rdcdo_dsplay            
            into   v_nmro_rdcdo_dsplay
            from fi_g_expedientes_analisis a
            join pq_g_solicitudes b on b.id_slctud = a.id_slctud
            where a.id_expdnte_anlsis = v_id_expdnte_anlsis ;        
           return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
           p_mensaje => 'Se encuentra activa en PQR una solicitud de análisis de expediente asociada al Radicado No. '||v_nmro_rdcdo_dsplay
           ||' relacionada a este expediente. <br> Para transitar a la siguiente etapa debe finalizar la solicitud.');
        end if;
    
        return 'N';
    
  end fnc_vl_expediente_analisis_fisca;
  
  /*
    Función que valida el tipo de respuesta del analisis de expediente asociada 
    a un flujo de fiscalización

  */
   function fnc_vl_expediente_analisis_rspta(p_cdgo_clnte          in  number,
                                            p_id_instncia_fljo    in  number) return varchar2 as
                              
    v_indcdor_blqdo       varchar2(1);
    v_id_cnddto         number;
    v_id_sjto_impsto    number;
    v_id_expdnte_anlsis number;
    v_id_instncia_fljo      number;
	v_id_fsclzcion_expdnte	number;
    v_cdgo_rspta        varchar2(5);
    
  begin
     begin
            select b.id_cnddto,
                   b.id_sjto_impsto,
                   a.id_fsclzcion_expdnte,
                   d.id_instncia_fljo,
                   d.cdgo_rspta
            into  v_id_cnddto,
                  v_id_sjto_impsto,
                  v_id_fsclzcion_expdnte,
                  v_id_instncia_fljo,
                  v_cdgo_rspta
            from fi_g_fiscalizacion_expdnte a
            join fi_g_expedientes_analisis  d  on  a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
            join fi_g_fsclzc_expdn_cndd_vgnc e  on  a.id_fsclzcion_expdnte = e.id_fsclzcion_expdnte
                                                and  e.id_slctud =   d.id_slctud               
            join fi_g_candidatos            b   on  a.id_cnddto =   b.id_cnddto
            where a.id_instncia_fljo = p_id_instncia_fljo ;
        exception
            when no_data_found then
                    return 'N';
            when others then
                    return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                         p_mensaje => 'No se pudo consultar el expediente del flujo ' ||p_id_instncia_fljo);
        end;
        
        --Se consulta el indicador bloqueo
        begin	
			select	indcdor_blqdo,
                    a.id_expdnte_anlsis                    
			into	v_indcdor_blqdo,
                    v_id_expdnte_anlsis
			from	fi_g_expndnts_anlsis_dtlle  a
            join    fi_g_expedientes_analisis  d   on  a.id_expdnte_anlsis = d.id_expdnte_anlsis
			join	fi_g_fsclzc_expdn_cndd_vgnc b on a.id_fsclzc_expdn_cndd_vgnc = b.id_fsclzc_expdn_cndd_vgnc
			join    fi_g_candidatos_vigencia c on b.id_cnddto_vgncia = c.id_cnddto_vgncia
                                    and a.id_prdo = c.id_prdo
			where b.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
            and d.id_instncia_fljo = v_id_instncia_fljo ;			
        exception 
            when no_data_found then
                return 'N';
			when others then
			 return pkg_wf_funciones.fnc_wf_error(p_value   => false, 
                                                 p_mensaje => 'Error al validar el indicador bloqueado del expediente ' || v_id_fsclzcion_expdnte );
        end;
		
		if  v_cdgo_rspta = 'APL' then 
            return 'S';
        end if;
    
        return 'N';
    
  end fnc_vl_expediente_analisis_rspta;
    
     /*<---------------------------------- Inicio Funciones Remanentes ------------------------------>*/
  function fnc_vl_acto_embrg_rmnnte(p_cdgo_clnte       in number,
                                    p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number)
    return varchar2 as
    v_id_acto           number;
    v_dscrpcion         varchar2(100);
    v_contador          number := 0;
    v_cdgo_estdo_embrgo varchar2(1);
  
  begin
  
    begin
      select a.cdgo_estdo_embrgo
        into v_cdgo_estdo_embrgo
        from mc_g_embargos_remanente a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when no_data_found then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'Genere la plantilla del acto ');
      
    end;
  
    -- begin
    for v_acto in (select c.dscrpcion, c.id_acto_tpo
                     from gn_d_plantillas a
                     join gn_d_actos_tipo_tarea b
                       on b.id_acto_tpo = a.id_acto_tpo
                     join gn_d_actos_tipo c
                       on b.id_acto_tpo = c.id_acto_tpo
                     join mc_d_remanentes_rspsta d
                       on a.id_plntlla = d.id_plntlla
                    where a.cdgo_clnte = p_cdgo_clnte
                      and b.id_fljo_trea = p_id_fljo_trea
                      and a.actvo = 'S'
                      and d.cdgo_rspsta = v_cdgo_estdo_embrgo) loop
      --end;
    
      /* for v_acto in (select a.dscrpcion, a.id_acto_tpo
       from gn_d_actos_tipo a
       join gn_d_actos_tipo_tarea b
         on a.id_acto_tpo = b.id_acto_tpo
      where b.id_fljo_trea = p_id_fljo_trea
        and b.indcdor_oblgtrio = 'S') loop*/
    
      -- if v_cdgo_estdo_embrgo = 'E' then
      begin
        select c.id_acto
          into v_id_acto
          from mc_g_embargos_remanente a
         inner join mc_g_embrg_remnte_dcmnto c
            on c.id_embrgos_rmnte = a.id_embrgos_rmnte
         where a.id_instncia_fljo = p_id_instncia_fljo
           and c.id_acto_tpo = v_acto.id_acto_tpo;
      
        if (v_id_acto is null) then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Confirme el acto ' ||
                                                            lower(v_acto.dscrpcion));
        
        end if;
      
      exception
        when no_data_found then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Genere la plantilla del acto ' ||
                                                            lower(v_acto.dscrpcion));
      end;
      v_contador := v_contador + 1;
    
    /*elsif v_cdgo_estdo_embrgo = 'R' then
            begin
              select c.id_acto
                into v_id_acto
                from mc_g_embargos_remanente a
               inner join mc_g_embrg_remnte_dcmnto c
                  on c.id_embrgos_rmnte = a.id_embrgos_rmnte
               where a.id_instncia_fljo = p_id_instncia_fljo
                 and c.id_acto_tpo = 183;
            exception
              when no_data_found then
                return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                                     p_mensaje => 'Genere la plantilla del acto de rechazo');
              
            end;
            v_contador := v_contador + 1;
          end if;*/
    end loop;
  
    if v_contador = 0 then
      return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                           p_mensaje => 'Parametrize los actos de la etapa en la que se encuentra');
    end if;
  
    return 'S';
  
  end fnc_vl_acto_embrg_rmnnte;

  function fnc_vl_acto_dsmbrg_rmnnte(p_id_instncia_fljo in number,
                                     p_id_fljo_trea     in number)
    return varchar2 as
    v_id_acto   number;
    v_dscrpcion varchar2(100);
    v_contador  number := 0;
  begin
    for v_acto in (select a.dscrpcion, a.id_acto_tpo
                     from gn_d_actos_tipo a
                     join gn_d_actos_tipo_tarea b
                       on a.id_acto_tpo = b.id_acto_tpo
                    where b.id_fljo_trea = p_id_fljo_trea
                      and b.indcdor_oblgtrio = 'S') loop
      begin
        select c.id_acto
          into v_id_acto
          from mc_g_dsmbrgs_remanente a
         inner join mc_g_dsmbrg_remnte_dcmnto c
            on c.id_dsmbrg_rmnte = a.id_dsmbrgos_rmnte
         where a.id_instncia_fljo = p_id_instncia_fljo
           and c.id_acto_tpo = v_acto.id_acto_tpo;
      
        if v_id_acto is null then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Confirme el acto ' ||
                                                            lower(v_acto.dscrpcion));
        end if;
      
      exception
        when no_data_found then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Genere la plantilla del acto ' ||
                                                            lower(v_acto.dscrpcion));
      end;
      v_contador := v_contador + 1;
    end loop;
  
    if v_contador = 0 then
      return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                           p_mensaje => 'Parametrize los actos de la etapa en la que se encuentra');
    end if;
  
    return 'S';
  
  end fnc_vl_acto_dsmbrg_rmnnte;

  function fnc_vl_rgstro_embrg_rmnnte(p_cdgo_clnte in number,
                                    p_id_instncia_fljo in number,
                                    p_idntfccion       in varchar2)
  return varchar2 is

  v_id_embrgos_rslcion number;
  v_embrgos_ascdos     number;
  v_embrgo_rchzdo      number;
  v_id_estdos_crtra    number;
  v_id_tpos_embrgo     number;
  v_nl                 number;

begin

  v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                      null,
                                      'fnc_vl_rgstro_embrg_rmnnte');
  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                        null,
                        'fnc_vl_rgstro_embrg_rmnnte',
                        v_nl,
                        'Entrando a la funcion con parametros: ' ||
                        p_id_instncia_fljo || ', ' || p_idntfccion,
                        6);

  begin
    select id_estdos_crtra
      into v_id_estdos_crtra
      from mc_d_estados_cartera
     where cdgo_estdos_crtra = 'E';
  exception
    when others then
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Error en la parametrización de los estados de embargo.');
  end;

  --validamos si existen medidas cautelares en etapa de embargo
  begin
    select count(*)
        into v_id_embrgos_rslcion
        from v_mc_g_embargos_resolucion e
        join mc_g_embargos_responsable r
          on r.id_embrgos_crtra = e.id_embrgos_crtra
        join mc_g_embargos_cartera c
          on c.id_embrgos_crtra = e.id_embrgos_crtra
       where ltrim(r.idntfccion, '0') = ltrim(p_idntfccion, '0')
         and c.id_estdos_crtra = v_id_estdos_crtra
         and e.id_tpos_embrgo in (select id_tpos_mdda_ctlar
          from mc_d_tipos_mdda_ctlar
         where cdgo_tpos_mdda_ctlar in ('BIM', 'EBF'));
  exception
    when no_data_found then
      v_id_embrgos_rslcion := 0;
  end;

  if v_id_embrgos_rslcion > 0 then
  
    begin
      select count(*)
        into v_embrgos_ascdos
        from mc_g_embargos_remanente a
        join mc_g_embrgo_remnte_dtlle b
          on b.id_embrgos_rmnte = a.id_embrgos_rmnte
       where a.id_instncia_fljo = p_id_instncia_fljo
         and rtrim(ltrim(a.idntfccion_dmnddo, '0')) =
             rtrim(ltrim(p_idntfccion, '0'))
         and exists
       (select 1
                from mc_g_embargos_resolucion c
                join mc_g_embargos_cartera d
                  on d.id_embrgos_crtra = c.id_embrgos_crtra
               where c.id_embrgos_rslcion = b.id_embrgos_rslcion
                 and d.id_estdos_crtra = v_id_estdos_crtra);
    exception
      when no_data_found then
        v_embrgos_ascdos := 0;
    end;
  
    if v_embrgos_ascdos > 0 then
      return 'S';
    else
      return 'N';
    end if;
  
  else
  
    begin
      select 1
        into v_embrgo_rchzdo
        from mc_g_embargos_remanente a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_estdo_embrgo = 'R';
    exception
      when others then
        v_embrgo_rchzdo := 0;
        return 'N';
    end;
  
    if v_embrgo_rchzdo > 0 then
      return 'S';
    end if;
  end if;

end fnc_vl_rgstro_embrg_rmnnte;

 function fnc_vl_rgstro_dsmbrg_rmnnte(p_id_instncia_fljo in number,
                                       p_idntfccion       in varchar2)
    return varchar2 is
    v_id_dsmbrgos_rslcion number;
    v_id_dsmbrgo_rmnte    number;
  begin
  
    --Valida que exista el embargo remanente
    begin
      select 1
        into v_id_dsmbrgo_rmnte
        from mc_g_embargos_remanente a
       where ltrim(a.idntfccion_dmnddo, '0') = ltrim(p_idntfccion, '0')
         and a.id_embrgos_rmnte not in
             (select z.id_embrgo_rmnte from mc_g_dsmbrgs_remanente z);
    exception
      when others then
        v_id_dsmbrgo_rmnte := 0;
    end;
  
    --validar si existe el desembargo remente
    begin
      select 1
        into v_id_dsmbrgos_rslcion
        from mc_g_dsmbrgs_remanente aa
       where aa.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_id_dsmbrgos_rslcion := 0;
    end;
  
    if (v_id_dsmbrgos_rslcion = 0) then
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Debe asociar 1 embargo para desembargar.');
    elsif (v_id_dsmbrgos_rslcion > 0) then
      return 'S';
    end if;
  
  end fnc_vl_rgstro_dsmbrg_rmnnte;


  /**Funcion que valida si remenente tiene asociado un embargo**/
  function fnc_vl_rmnte_ascdo_embrgo(p_id_instncia_fljo in number)
    return varchar2 is
    v_embrgo_rmnte   number := 0;
    v_embrgo_rslcion number := 0;
  begin
  
    begin
      select distinct a.id_embrgos_rslcion
        into v_embrgo_rslcion
        from v_mc_g_embargos_resolucion a
        join mc_g_embargos_responsable c
          on c.id_embrgos_crtra = a.id_embrgos_crtra
        join v_sg_g_usuarios b
          on b.id_fncnrio = a.id_fncnrio
        join mc_d_estados_cartera t
          on t.id_estdos_crtra = a.id_estdos_crtra
         and t.cdgo_estdos_crtra != 'D'
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_embrgo_rmnte := null;
    end;
  
    begin
    
      select z.id_embrgos_rslcion
        into v_embrgo_rmnte
        from mc_g_embrgo_remnte_dtlle z
        join mc_g_embargos_remanente y
          on y.id_embrgos_rmnte = z.id_embrgos_rmnte
       where z.id_embrgos_rslcion = v_embrgo_rslcion;
    
    exception
      when others then
        v_embrgo_rmnte := 0;
    end;
  
    if v_embrgo_rmnte is null then
      v_embrgo_rmnte := 0;
    end if;
  
    if v_embrgo_rmnte > 0 then
      /*return 'S';*/
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'No es posible enviar a desembargo ya que aun tiene remanente Asociado.');
    end if;
  
  end fnc_vl_rmnte_ascdo_embrgo;

  /** Funcion que valida si un remanente asociado a un embargo tiene una demanda por alimento**/
  function fnc_vl_rmnt_ascd_embrg_dmnda(p_id_instncia_fljo in number)
    return varchar2 is
    v_embrgo_rmnte   number := 0;
    v_embrgo_rslcion number := 0;
  begin
  
    begin
      select a.id_embrgos_rslcion
        into v_embrgo_rslcion
        from v_mc_g_embargos_resolucion a
        join mc_g_embargos_responsable c
          on c.id_embrgos_crtra = a.id_embrgos_crtra
        join v_sg_g_usuarios b
          on b.id_fncnrio = a.id_fncnrio
        join mc_d_estados_cartera t
          on t.id_estdos_crtra = a.id_estdos_crtra
         and t.cdgo_estdos_crtra != 'D'
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_embrgo_rmnte := null;
    end;
  
    begin
    
      select z.id_embrgos_rslcion
        into v_embrgo_rmnte
        from mc_g_embrgo_remnte_dtlle z
        join mc_g_embargos_remanente y
          on y.id_embrgos_rmnte = z.id_embrgos_rmnte
        join mc_d_procesos_remanente x
          on x.cdgo_tpo_prcso = y.cdgo_tpo_prcso
       where y.id_instncia_fljo = p_id_instncia_fljo
         and y.cdgo_tpo_prcso = 'RDA';
    
    exception
      when others then
        v_embrgo_rmnte := 0;
    end;
  
    if v_embrgo_rmnte is null then
      v_embrgo_rmnte := 0;
    end if;
  
    if v_embrgo_rmnte > 0 then
      return 'S';
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'El embargo tiene asociado un Remanente por demanda de alimento');
    end if;
  end fnc_vl_rmnt_ascd_embrg_dmnda;

  /**Funcion que valida si el registro a desembargar tiene asociado un remanete activo**/
  function fnc_vl_embrgo_ascdo_rmnte(p_id_instncia_fljo in number)
    return varchar2 is
    v_embrgo_rmnte   number := 0;
    v_embrgo_rslcion number := 0;
  begin
  
    begin
      select distinct a.id_embrgos_rslcion
        into v_embrgo_rslcion
        from v_mc_g_embargos_resolucion a
        left join wf_d_flujos_tarea_estado d
          on d.id_fljo_trea = a.id_fljo_trea
         and d.id_fljo_trea_estdo = a.id_fljo_trea_estdo
        left join mc_g_solicitudes_y_oficios e
          on e.id_embrgos_crtra = a.id_embrgos_crtra
        left join mc_g_embrgo_remnte_dtlle z
          on a.id_embrgos_rslcion = z.id_embrgos_rslcion
        left join mc_g_embargos_remanente y
          on y.id_embrgos_rmnte = z.id_embrgos_rmnte
         and z.id_embrgos_rslcion in
             (select m.id_embrgo_rslcion from gf_g_titulos_judicial m)
       where a.cdgo_estdos_crtra in ('E', 'S')
         and exists
       (select 1
                from v_mc_g_embargos_rspnsble_emb d
               where d.id_embrgos_crtra = a.id_embrgos_crtra
                 and d.id_embrgos_rslcion = a.id_embrgos_rslcion)
         and a.id_instncia_fljo = p_id_instncia_fljo; --2228957;
    exception
      when others then
        v_embrgo_rmnte := null;
    end;
  
    begin
    
      select z.id_embrgos_rslcion
        into v_embrgo_rmnte
        from mc_g_embrgo_remnte_dtlle z
        join mc_g_embargos_remanente y
          on y.id_embrgos_rmnte = z.id_embrgos_rmnte
       where z.id_embrgos_rslcion = v_embrgo_rslcion;
    
    exception
      when others then
        v_embrgo_rmnte := 0;
    end;
  
    if v_embrgo_rmnte is null then
      v_embrgo_rmnte := 0;
    end if;
  
    if v_embrgo_rmnte > 0 then
      /*return 'S';*/
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'El registro que se va a desembargar tiene un  remanente Asociado Activo.');
    end if;
  
  end fnc_vl_embrgo_ascdo_rmnte;

  /*<---------------------------------- Fin Funciones Remanentes  ------------------------------>*/

    /*<-------------------------------------Funciones Titulo Judicial--------------------------------->*/

  function fnc_vl_ttlo_ascdo_instncia(p_id_instncia_fljo in number)
    return varchar2 as
    v_idntfccion  number;
    v_estdo_ttlo  varchar2(100);
    v_count_ttlos number := 0;
    v_contador    number := 0;
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count_ttlos
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_count_ttlos := 0;
    end;
    for c_ttlos in (select a.idntfccion_dmnddo, a.cdgo_ttlo_jdcial_estdo
                      from gf_g_titulos_judicial a
                     where a.id_instncia_fljo = p_id_instncia_fljo) loop
    
      if c_ttlos.idntfccion_dmnddo is not null and
         c_ttlos.cdgo_ttlo_jdcial_estdo = 'RCH' then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'Existe una identificacion asociada a este flujo en estado Rechazado, por favor verifique la identificacion digitada y seleccione una accion para el titulo.');
      elsif c_ttlos.idntfccion_dmnddo is not null and
            c_ttlos.cdgo_ttlo_jdcial_estdo = 'TRO' then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'Usted selecciono traslado de oficina, utilice el boton Trasladar Titulo para continuar');
      end if;
    
      v_contador := v_contador + 1;
    
      if v_count_ttlos = v_contador and
         c_ttlos.cdgo_ttlo_jdcial_estdo <> 'RCH' then
        return 'S';
      end if;
    end loop;
  
    if v_count_ttlos = 0 then
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Asociar un Titulo a la instancia del flujo');
    end if;
  end fnc_vl_ttlo_ascdo_instncia;

  function fnc_vl_consignacion_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_count       number;
    v_count_estdo number;
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ACN';
    exception
      when others then
        return 'N';
    end;
    /*begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ACN';
    end;*/
    if v_count > 0 then
      return 'S';
    else
      return 'N';
    end if;
  
  end fnc_vl_consignacion_ttlo;

  function fnc_vl_fnlzcion_fljo_trsldo(p_id_instncia_fljo in number)
    return varchar2 as
    v_count number := 0;
  begin
    for titulos in (select id_ttlo_jdcial
                      from gf_g_titulos_judicial a
                     where a.id_instncia_fljo = p_id_instncia_fljo
                       and a.cdgo_ttlo_jdcial_estdo = 'TRO') loop
      begin
        select count(*)
          into v_count
          from gf_g_titulos_judicial_traslado a
         where a.id_ttlo_jdcial = titulos.id_ttlo_jdcial;
      exception
        when others then
          v_count := 0;
      end;
    end loop;
  
    if v_count > 0 then
      return 'S';
    else
      return 'N';
    end if;
  exception
    when others then
      return 'N';
  end fnc_vl_fnlzcion_fljo_trsldo;

  function fnc_vl_cnsgnar_dvlver(p_id_instncia_fljo in number)
    return varchar2 as
  
    v_count number := 0;
  begin
  
    begin
      select count(*)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ACN';
    exception
      when others then
        v_count := 0;
    end;
  
    if v_count > 0 then
      return 'S';
    else
      return 'N';
    end if;
  end fnc_vl_cnsgnar_dvlver;

  function fnc_vl_devolucion_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
  
    v_count       number := 0;
    v_count_estdo number;
  
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ASL';
    exception
      when others then
        return 'N';
    end;
  
    if v_count > 0 then
      return 'S';
    else
      return 'N';
    end if;
  
    /* begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ASL';
    end;
    
    if v_count = v_count_estdo then
      return 'S';
    else
      return 'N';
    end if;*/
  
  end fnc_vl_devolucion_ttlo;

  function fnc_vl_frccnmnto_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_count       number := 0;
    v_count_estdo number;
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'FRC';
    exception
      when others then
        return 'N';
    end;
  
    /* begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'FRC';
    end;*/
    if v_count > 0 then
      return 'S';
    else
      return 'N';
    end if;
  end fnc_vl_frccnmnto_ttlo;

  function fnc_vl_cnsgncn_dvlcn_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_count         number;
    v_count_estdo_1 number;
    v_count_estdo_2 number;
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    end;
    begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo_1
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ACN';
    end;
    begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo_2
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ASL';
    end;
  
    if v_count_estdo_1 > 0 and v_count_estdo_2 > 0 then
      return 'S';
    else
      return 'N';
    end if;
  end fnc_vl_cnsgncn_dvlcn_ttlo;

  function fnc_vl_rgstro_vgncia_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_cartera number;
  begin
    begin
      select 1
        into v_cartera
        from gf_g_titulos_jdcial_vgncia a
        join gf_g_titulos_jdcial_impsto b
          on a.id_ttlo_jdcial_impsto = b.id_ttlo_jdcial_impsto
        join gf_g_titulos_judicial c
          on c.id_ttlo_jdcial = b.id_ttlo_jdcial
       where c.id_instncia_fljo = p_id_instncia_fljo
         and rownum = 1;
    exception
      when no_data_found then
        begin
          select 1
            into v_cartera
            from gf_g_titulos_judicial_saldo_favor a
           where a.id_instncia_fljo = p_id_instncia_fljo;
        exception
          when no_data_found then
            return fnc_wf_error(p_value   => false,
                                p_mensaje => 'Para transitar a la siguiente etapa debe registrar al menos una vigencia-periodo a consignar.');
        end;
    end;
    if v_cartera is not null then
      return 'S';
    end if;
  end fnc_vl_rgstro_vgncia_ttlo;

  function fnc_vl_rgstro_frccn_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_frccn        number;
    v_vlor_frcnado number;
    v_vlor_ttlo    number;
  begin
    begin
      select count(a.id_ttlo_jdcial_frccn)
        into v_frccn
        from gf_g_titulos_jdcl_frccnmnto a
        join gf_g_titulos_judicial b
          on a.id_ttlo_jdcial = b.id_ttlo_jdcial
       where b.id_instncia_fljo = p_id_instncia_fljo;
      --and rownum = 1;
    exception
      when no_data_found then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'Para transitar a la siguiente etapa debe registrar al menos dos(2) fracciones.');
    end;
  
    if v_frccn >= 2 then
      -- se valida que el fraccionamiento sea igual al valor del titulo
      select nvl(sum(a.vlor), 0), nvl(b.vlor, 0)
        into v_vlor_frcnado, v_vlor_ttlo
        from gf_g_titulos_jdcl_frccnmnto a
        join gf_g_titulos_judicial b
          on a.id_ttlo_jdcial = b.id_ttlo_jdcial
       where b.id_instncia_fljo = p_id_instncia_fljo
       group by b.vlor;
    
      if v_vlor_frcnado < v_vlor_ttlo then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'La suma de las fracciones (' ||
                                         v_vlor_frcnado ||
                                         '), NO es igual al valor de titulo (' ||
                                         v_vlor_ttlo || ')');
      elsif v_vlor_frcnado > v_vlor_ttlo then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'La suma de las fracciones (' ||
                                         v_vlor_frcnado ||
                                         ') es mayor al valor de titulo (' ||
                                         v_vlor_ttlo || ')');
      else
        return 'S';
      end if;
    else
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Para transitar a la siguiente etapa debe registrar al menos dos(2) fracciones.');
    end if;
  end fnc_vl_rgstro_frccn_ttlo;

  function fnc_vl_acto_tarea_ttlo(p_id_instncia_fljo in number,
                                  p_id_fljo_trea     in number)
    return varchar2 as
    v_id_acto   number;
    v_dscrpcion varchar2(100);
    v_contador  number := 0;
  begin
    for v_acto in (select a.dscrpcion, a.id_acto_tpo
                     from gn_d_actos_tipo a
                     join gn_d_actos_tipo_tarea b
                       on a.id_acto_tpo = b.id_acto_tpo
                    where b.id_fljo_trea = p_id_fljo_trea
                      and b.indcdor_oblgtrio = 'S') loop
      begin
        select c.id_acto
          into v_id_acto
          from gf_g_titulos_judicial a
         inner join gf_g_ttls_jdcl_dcmnt_asccn b
            on b.id_ttlo_jdcial = a.id_ttlo_jdcial
         inner join gf_g_titulos_jdcial_dcmnto c
            on c.id_ttlo_jdcial_dcmnto = b.id_ttlo_jdcial_dcmnto
         where a.id_instncia_fljo = p_id_instncia_fljo
           and c.id_acto_tpo = v_acto.id_acto_tpo
         order by c.id_ttlo_jdcial_dcmnto desc
         fetch first 1 rows only;
        --and rownum = 1;
      
        if v_id_acto is null then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Confirme el acto ' ||
                                                            lower(v_acto.dscrpcion));
        end if;
      
      exception
        when no_data_found then
          return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                               p_mensaje => 'Genere la plantilla del acto ' ||
                                                            lower(v_acto.dscrpcion));
      end;
      v_contador := v_contador + 1;
    end loop;
  
    if v_contador = 0 then
      return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                           p_mensaje => 'Parametrize los actos de la etapa en la que se encuentra');
    end if;
  
    return 'S';
  
  end fnc_vl_acto_tarea_ttlo;

  function fnc_vl_rcbo_cnsgncn_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_documento    number;
    v_recaudo      number;
    v_count_dcmnto number := 0;
    v_contador     number := 0;
  begin
    begin
      select count(a.id_dcmnto)
        into v_count_dcmnto
        from gf_g_ttls_jdcl_impsto_dcmnt a
        join gf_g_titulos_judicial b
          on b.id_ttlo_jdcial = a.id_ttlo_jdcial
       where b.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_count_dcmnto := 0;
    end;
  
    if v_count_dcmnto = 0 then
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Generar Recibo(s) para el/los Titulo(s) asociado(s) a la instancia del flujo.');
    end if;
  
    for c_ttlo_dcmntos in (select a.id_dcmnto
                             from gf_g_ttls_jdcl_impsto_dcmnt a
                             join gf_g_titulos_judicial b
                               on b.id_ttlo_jdcial = a.id_ttlo_jdcial
                            where b.id_instncia_fljo = p_id_instncia_fljo
                              and b.cdgo_ttlo_jdcial_estdo in ('ACN', 'CNS')) loop
      begin
        select b.id_dcmnto, c.id_rcdo
          into v_documento, v_recaudo
          from re_g_documentos b
          left join re_g_recaudos c
            on c.id_orgen = b.id_dcmnto
           and c.cdgo_rcdo_orgn_tpo = 'DC'
           and c.cdgo_rcdo_estdo = 'AP'
         where b.id_dcmnto = c_ttlo_dcmntos.id_dcmnto;
      exception
        when no_data_found then
          v_documento := null;
          v_recaudo   := null;
      end;
    
      if v_documento is null and v_recaudo is null then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'Generar Recibo(s) para el/los Titulo(s) asociado(s) a la instancia del flujo.');
      end if;
      v_contador := v_contador + 1;
    end loop;
  
    if v_count_dcmnto = v_contador then
      return 'S';
    end if;
  end fnc_vl_rcbo_cnsgncn_ttlo;

  function fnc_vl_saldo_cartera_ttlo(p_id_instncia_fljo in number)
    return varchar2 is
  
    v_sldo_crtera       number;
    v_id_sjto_impsto    number;
    v_idntfccion_dmnddo gf_g_titulos_judicial.idntfccion_dmnddo%type;
  begin
  
    begin
      select idntfccion_dmnddo
        into v_idntfccion_dmnddo
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
       fetch first 1 rows only;
    exception
      when others then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'No se encontro la identificacion del Demandado.');
    end;
  
    for c_deuda in (select id_sjto_impsto
                      from v_si_i_sujetos_responsable
                     where idntfccion_rspnsble =
                           to_char(v_idntfccion_dmnddo)) loop
    
      select nvl(sum(a.vlor_sldo_cptal), 0)
        into v_sldo_crtera
        from v_gf_g_cartera_x_concepto a
        join v_si_i_sujetos_impuesto b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where a.id_sjto_impsto = c_deuda.id_sjto_impsto
         and a.cdgo_mvnt_fncro_estdo not in ('AN');
      --and a.fcha_vncmnto < sysdate;   Esta condicion esta por confirmar
    
      if v_sldo_crtera > 0 then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'El contribuyente tiene saldo en cartera, no se le puede devolver el titulo.');
      else
        continue;
      end if;
    end loop;
  
    return 'N';
  
  end fnc_vl_saldo_cartera_ttlo;

  function fnc_vl_aplccion_rcdo_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_documento    number;
    v_recaudo      number;
    v_count_dcmnto number := 0;
    v_contador     number := 0;
  begin
    begin
      select count(a.id_dcmnto)
        into v_count_dcmnto
        from gf_g_ttls_jdcl_impsto_dcmnt a
        join gf_g_titulos_judicial b
          on b.id_ttlo_jdcial = a.id_ttlo_jdcial
       where b.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_count_dcmnto := 0;
    end;
  
    if v_count_dcmnto = 0 then
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Generar Recibo(s) para el/los Titulo(s) asociado(s) a la instancia del flujo.');
    end if;
  
    for c_ttlo_dcmntos in (select a.id_dcmnto
                             from gf_g_ttls_jdcl_impsto_dcmnt a
                             join gf_g_titulos_judicial b
                               on b.id_ttlo_jdcial = a.id_ttlo_jdcial
                            where b.id_instncia_fljo = p_id_instncia_fljo
                              and b.cdgo_ttlo_jdcial_estdo = 'CNS') loop
      begin
        select b.id_dcmnto, c.id_rcdo
          into v_documento, v_recaudo
          from re_g_documentos b
          left join re_g_recaudos c
            on c.id_orgen = b.id_dcmnto
           and c.cdgo_rcdo_orgn_tpo = 'DC'
           and c.cdgo_rcdo_estdo = 'AP'
         where b.id_dcmnto = c_ttlo_dcmntos.id_dcmnto;
      exception
        when no_data_found then
          v_documento := null;
          v_recaudo   := null;
      end;
    
      if v_documento is not null and v_recaudo is null then
        return fnc_wf_error(p_value   => false,
                            p_mensaje => 'Realizar el pago de el/los Recibo(s) generado(s).');
      end if;
      v_contador := v_contador + 1;
    end loop;
  
    if v_count_dcmnto = v_contador then
      return 'S';
    else
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'Realizar el pago de el/los Recibo(s) generado(s).');
    end if;
  end fnc_vl_aplccion_rcdo_ttlo;

  /**Funcion que valida si el embargo asociado al titulo tiene un remanente**/
  function fnc_vl_embrgo_rmnte_ascdo_ttlo(p_id_instncia_fljo in number)
    return varchar2 is
    v_embrgo_rslcion_pdre number;
    v_embrgo_rslcion      number;
  begin
  
    begin
      select 1
        into v_embrgo_rslcion
        from gf_g_titulos_judicial a
        join mc_g_embrgo_remnte_dtlle b
          on a.id_embrgo_rslcion = b.id_embrgos_rslcion
        join mc_g_embargos_remanente c
          on b.id_embrgos_rmnte = c.id_embrgos_rmnte
       where a.id_instncia_fljo = p_id_instncia_fljo
         and c.cdgo_estdo_embrgo = 'E';
    exception
      when others then
        v_embrgo_rslcion := 0;
    end;
  
    begin
      select 1
        into v_embrgo_rslcion_pdre
        from gf_g_titulos_judicial a
        join mc_g_embrgo_remnte_dtlle b
          on a.id_embrgo_rslcion = b.id_embrgos_rslcion
        join mc_g_embargos_remanente c
          on b.id_embrgos_rmnte = c.id_embrgos_rmnte
        join gf_g_titulos_judicial d
          on d.id_ttlo_pdre = a.id_ttlo_jdcial
       where a.id_instncia_fljo = p_id_instncia_fljo
         and c.cdgo_estdo_embrgo = 'E';
    exception
      when others then
        v_embrgo_rslcion_pdre := 0;
    end;
  
    if v_embrgo_rslcion > 0 or /*then
                                                                                                                                                                                                                  return fnc_wf_error( p_value   => false
                                                                                                                                                                                                                                      ,p_mensaje => '1. Finalizar el embargo remanente que se encuentra asociado al embargo del titulo judicial.');
                                                                                                                                                                                                              elsif */
       v_embrgo_rslcion_pdre > 0 then
      /*
          return fnc_wf_error( p_value   => false
                              ,p_mensaje => '2. Finalizar el embargo remanente que se encuentra asociado al embargo del titulo judicial padre.');
      else  */
      return 'S';
    else
      return fnc_wf_error(p_value   => false,
                          p_mensaje => 'No tiene embargo remanente asociado al embargo del titulo judicial.');
    end if;
  end fnc_vl_embrgo_rmnte_ascdo_ttlo;

  function fnc_vl_cnsgncn_rmnnte_ttlo(p_id_instncia_fljo in number)
    return varchar2 as
    v_count       number;
    v_count_estdo number;
  begin
    begin
      select count(a.id_ttlo_jdcial)
        into v_count
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    end;
    begin
      select count(a.id_ttlo_jdcial)
        into v_count_estdo
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'CNR';
    end;
    if v_count = v_count_estdo then
      return 'S';
    else
      return 'N';
    end if;
  end fnc_vl_cnsgncn_rmnnte_ttlo;
  
  function fnc_vl_cnsgncion_ttlo_vlor(p_id_instncia_fljo in number)
    return varchar2 as
  
    v_vlor_ttlos       gf_g_titulos_judicial.vlor%type;
    v_vlor_ttal_aplcar gf_g_titulos_jdcial_vgncia.vlor_ttal_aplcar%type;
    v_vlor_sldo_fvor   gf_g_titulos_judicial_saldo_favor.vlor_sldo_fvor%type;
  
  begin
  
    --Obtenemos el valor de los titulos procesados
    begin
      select sum(a.vlor)
        into v_vlor_ttlos
        from gf_g_titulos_judicial a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_ttlo_jdcial_estdo = 'ACN';
    exception
      when others then
        v_vlor_ttlos := 0;
        return 'N';
    end;
  
    -- Buscamos el valor consignado con los titulos procesados
    begin
      select nvl(sum(t.vlor_ttal_aplcar),0)
        into v_vlor_ttal_aplcar
        from gf_g_titulos_jdcial_vgncia t
       where t.id_ttlo_jdcial_impsto in
             (select max(id_ttlo_jdcial_impsto)
                from gf_g_titulos_jdcial_impsto i
               where i.id_ttlo_jdcial in
                     (select t.id_ttlo_jdcial
                        from gf_g_titulos_judicial t
                       where t.id_instncia_fljo = p_id_instncia_fljo
                         and t.cdgo_ttlo_jdcial_estdo = 'ACN')
               group by id_sjto_impsto);
    exception
      when others then
        begin
          select nvl(sum(vlor_sldo_fvor),0)
            into v_vlor_sldo_fvor
            from gf_g_titulos_judicial_saldo_favor
           where id_instncia_fljo = p_id_instncia_fljo;
        exception
          when others then
            v_vlor_ttal_aplcar := 0;
            v_vlor_sldo_fvor   := 0;
           -- return 'N';
        end;
    end;
  
    begin
      select nvl(sum(vlor_sldo_fvor),0)
        into v_vlor_sldo_fvor
        from gf_g_titulos_judicial_saldo_favor
       where id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        v_vlor_sldo_fvor := 0;
    end;
  
    v_vlor_ttal_aplcar := v_vlor_ttal_aplcar + v_vlor_sldo_fvor;
  
    if v_vlor_ttlos = v_vlor_ttal_aplcar then
      return 'S';
    else
      return 'N';
    end if;
  
  end fnc_vl_cnsgncion_ttlo_vlor;


  /*<---------------------------------- Fin Funciones Titulo Judicial ------------------------------>*/

    
end pkg_wf_funciones;

/
