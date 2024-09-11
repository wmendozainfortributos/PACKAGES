--------------------------------------------------------
--  DDL for Package Body PKG_MM_MIGRACION_MODULO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MM_MIGRACION_MODULO" as 
    
    function fnc_co_replace_db_link(p_db_link       in varchar2
                                  , p_id_mdlo       in varchar2
                                  , p_cdgo_clnte    in number
                                  , p_bsqda         in varchar2)    
    return clob
    is
    type        t_type is record( key    varchar2(50), value  varchar2(500));    
    type        g_type is table of t_type;
    v_type      g_type;
    v_sql       clob;
    v_cnslta    mm_d_modulos.cnslta%type;

    begin
        begin
            select cnslta
              into v_cnslta 
              from mm_d_modulos
             where id_mdlo = p_id_mdlo;
        exception
            when others then 
                return null;
        end;

        select /*+ RESULT_CACHE */  
               lower(object_name) 
             , nvl2(p_db_link, '@' || p_db_link, '') 
          bulk collect 
          into v_type
          from all_objects 
         where object_type in ('TABLE', 'VIEW')
           and upper(owner) = upper('genesys');

        for c_parts in ( select regexp_substr(v_cnslta, '\S+', 1,level) part
                           from dual 
                     connect by regexp_substr(v_cnslta, '\S+',1, level) is not null 
                       )
        loop
            for i in 1..v_type.count loop
                c_parts.part := case when lower(c_parts.part) = v_type(i).key then  c_parts.part || v_type(i).value else c_parts.part end ;
            end loop;
            v_sql := v_sql || ' ' || c_parts.part;
        end loop;

        v_sql := replace(v_sql, ':P_BSQDA', p_bsqda);
        v_sql := replace(v_sql, ':F_CDGO_CLNTE', p_cdgo_clnte);
        return v_sql;
    end fnc_co_replace_db_link;

    procedure prc_vl_existe_modulo(p_db_link            in varchar2
                                 , p_id_mdlo            in varchar2
                                 , p_cdgo_clnte_orgen   in number                                 
                                 , p_cdgo_clnte_dstno   in number
                                 , p_bsqda              in varchar2
                                 , o_cdgo_rspsta        out number
                                 , o_mnsje_rspsta       out varchar2 )
    as
        v_sql           clob;
        v_count         number := 0;
        v_nmbre         mm_d_modulos.nmbre%type;
        v_nmbre_prmtro  mm_d_modulos.nmbre_prmtro%type;
    begin
        o_cdgo_rspsta := 0;

        --VALIDAMOS SI EXISTE LA PARAMÉTRICA DE LA MIGRACIÓN DE MODULOS
        begin
            select nmbre
                 , nmbre_prmtro 
              into v_nmbre
                 , v_nmbre_prmtro
              from mm_d_modulos
             where id_mdlo = p_id_mdlo;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontro paramétrica para migrar módulo.';                
        end;        

        --2. GENERAR CONSULTA CLIENTE DESTINO
        begin
            v_sql := 'select count(1)  from ('  || pkg_mm_migracion_modulo.fnc_co_replace_db_link(p_db_link      => ''
                                                                                                , p_id_mdlo      => p_id_mdlo
                                                                                                , p_cdgo_clnte   => p_cdgo_clnte_dstno
                                                                                                , p_bsqda        => p_bsqda) 
                                                || ')'; 
        exception
            when others then 
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar la consulta para validar el módulo destino';
        end;

        --3. VALIDAR EXISTENCIA DEL MÓDULO EN EL CLIENTE DESTINO
        begin
            execute immediate v_sql into v_count;
            if v_count > 0 then
                o_cdgo_rspsta   := 3;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Ya existe registro para el módulo ' || v_nmbre || ' con ' || v_nmbre_prmtro || ' igual a ' || p_bsqda || ' del cliente destino.';
                return;
            end if;
        exception
            when others then 
                o_cdgo_rspsta   := 3;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo obtener datos para el módulo ' || v_nmbre || ' del cliente destino.';
        end;

        v_sql   := null;
        v_count := 0;
        --4. GENERAR CONSULTA CLIENTE ORIGEN
        begin
            v_sql := 'select count(1)  from ('  || pkg_mm_migracion_modulo.fnc_co_replace_db_link(p_db_link      => p_db_link
                                                                                                , p_id_mdlo      => p_id_mdlo
                                                                                                , p_cdgo_clnte   => p_cdgo_clnte_orgen
                                                                                                , p_bsqda        => p_bsqda) 
                                                || ')'; 
        exception
            when others then 
                o_cdgo_rspsta   := 4;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar la consulta para validar el módulo ' || v_nmbre || ' del cliente origen';
        end;

        --5. VALIDAR EXISTENCIA DEL MÓDULO EN EL CLIENTE ORIGEN
        begin
            execute immediate v_sql into v_count;
            if (v_count = 0) then
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No existe registro para el módulo ' || v_nmbre || ' con ' || v_nmbre_prmtro || ' igual a ' || p_bsqda || ' del cliente origen.';
                return;
            end if;

            if v_count > 1 then
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Existe mas de un registro para el módulo ' || v_nmbre || ' con ' || v_nmbre_prmtro || ' igual a ' || p_bsqda || ' del cliente origen.';
                return;
            end if;

        exception
            when others then 
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo obtener datos para el módulo ' || v_nmbre || ' con ' || v_nmbre_prmtro || ' igual a ' || p_bsqda || ' del cliente origen. ' || v_sql;
        end;

    end prc_vl_existe_modulo;

    procedure prc_rg_ejecutar_migracion(p_db_link            in varchar2
                                      , p_id_mdlo            in varchar2
                                      , p_cdgo_clnte_orgen   in number                                 
                                      , p_cdgo_clnte_dstno   in number
                                      , p_bsqda              in varchar2
                                      , o_cdgo_rspsta        out number
                                      , o_mnsje_rspsta       out varchar2)
    as
        v_nmbre_up  mm_d_modulos.nmbre_up%type;
        v_nmbre     mm_d_modulos.nmbre%type;


    begin
        --1. VALIDAMOS LA EXISTENCIA DEL MÃ“DULO 
        pkg_mm_migracion_modulo.prc_vl_existe_modulo(p_db_link          => p_db_link
                                                   , p_id_mdlo          => p_id_mdlo
                                                   , p_cdgo_clnte_orgen => p_cdgo_clnte_orgen
                                                   , p_cdgo_clnte_dstno => p_cdgo_clnte_dstno
                                                   , p_bsqda            => p_bsqda
                                                   , o_cdgo_rspsta      => o_cdgo_rspsta
                                                   , o_mnsje_rspsta     => o_mnsje_rspsta );

        if (o_cdgo_rspsta != 0) then 
            return;
        end if;

        --1. BUSCAMOS LA UP PARA REALIZAR LA MIGRACIÓN DEL MÓDULO
        begin
            select nmbre_up
                 , nmbre
              into v_nmbre_up
                 , v_nmbre
              from mm_d_modulos
             where id_mdlo = p_id_mdlo;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontro paramétrica para migrar módulo.';  
        end;

        begin
            execute immediate 'pkg_mm_migracion_modulo.' || v_nmbre_up 
                    using in p_db_link
                        , in p_cdgo_clnte_orgen
                        , in p_cdgo_clnte_dstno 
                        , in p_bsqda
                        , out o_cdgo_rspsta
                        , out o_mnsje_rspsta;
        exception
            when others then
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se ejecutar la migración del módulo.' || sqlerrm ;              
        end;
    end prc_rg_ejecutar_migracion;

    procedure prc_rg_migrar_flujo(p_db_link          in varchar2
                                , p_cdgo_clnte_orgen in number
                                , p_cdgo_clnte_dstno in number
                                , p_bsqda            in varchar2
                                , o_cdgo_rspsta      out number
                                , o_mnsje_rspsta     out varchar2 )
    as
        v_sql   clob;
    begin
        v_sql := 
                ' declare
                    v_cdgo_clnte        number := ' || p_cdgo_clnte_orgen || ';
                    v_cdgo_clnte_dst    number := ' || p_cdgo_clnte_dstno || ';
                    v_obj_fljo              json_array_t    := json_array_t(''[]'');
                    v_obj_trea              json_array_t    := json_array_t(''[]'');
                    v_obj_trns              json_array_t    := json_array_t(''[]'');
                    v_obj_evnt              json_array_t    := json_array_t(''[]'');
                    v_obj_evnt_mnj          json_array_t    := json_array_t(''[]'');

                    v_json_fljo              clob;
                    v_json_trea              clob;
                    v_json_trns              clob;
                    v_json_evnt              clob;
                    v_json_evnt_mnj          clob;

                    v_id_fljo               number;
                    v_id_fljo_trea          number;
                    v_id_fljo_trnscion      number;
                    v_id_fljo_evnto_mnjdor  number;
                begin

                    --MIGRAMOS LAS TAREAS DE TODOS LOS FLUJOS   
                    begin
                        for c_t in ( select a.* 
                                       from wf_d_tareas@' || p_db_link || ' a 
                                  left join wf_d_tareas b
                                         on b.id_trea = a.id_trea
                                      where a.cdgo_clnte = v_cdgo_clnte
                                        and b.id_trea is null      
                                        )
                        loop
                            insert into wf_d_tareas( id_trea           , cdgo_clnte         , nmbre_trea
                                                   , dscrpcion_trea    , cdgo_accion_tpo    , id_aplccion
                                                   , nmro_pgna         , nmbre_up           , nmbre_rprte
                                                   , ntfccion_crreo    , indcdor_enviar     ) 
                                             values( c_t.id_trea       , v_cdgo_clnte_dst   , c_t.nmbre_trea
                                                   , c_t.dscrpcion_trea, c_t.cdgo_accion_tpo, c_t.id_aplccion
                                                   , c_t.nmro_pgna     , c_t.nmbre_up       , c_t.nmbre_rprte
                                                   , c_t.ntfccion_crreo, c_t.indcdor_enviar );
                        end loop;    
                    end;

                    --MIGRAMOS LOS EVENTOS GENERALES DEL SISTEMA 
                    begin
                        for c_evnto in ( select a.* 
                                           from gn_d_eventos@' || p_db_link || ' a
                                      left join gn_d_eventos b
                                             on a.id_evnto = b.id_evnto
                                          where b.id_evnto is null
                                            and a.cdgo_evnto = ''' || p_bsqda || ''')
                        loop            
                            insert into gn_d_eventos( id_evnto          , id_prcso
                                                    , cdgo_evnto        , dscrpcion) 
                                              values( c_evnto.id_evnto  , c_evnto.id_prcso
                                                    , c_evnto.cdgo_evnto, c_evnto.dscrpcion);

                            insert into gn_d_eventos_propiedad
                                 select a.id_evnto_prpdad
                                      , a.id_evnto
                                      , a.cdgo_prpdad
                                      , a.dscrpcion
                                   from gn_d_eventos_propiedad@' || p_db_link || '   a
                              left join gn_d_eventos_propiedad              b on b.id_evnto_prpdad = a.id_evnto_prpdad 
                                  where b.id_evnto_prpdad is null
                                    and a.id_evnto = c_evnto.id_evnto;
                        end loop;                  
                    end;

                    --MIGRAMOS LOS FLUJOS DE TRABAJO 
                    begin
                        for c_flujos in ( select a.* 
                                            from wf_d_flujos@' || p_db_link || ' a 
                                       left join wf_d_flujos b
                                              on b.cdgo_fljo = a.cdgo_fljo
                                           where a.cdgo_clnte = v_cdgo_clnte 
                                             and a.cdgo_fljo = ''' || p_bsqda|| '''
                                             and b.id_fljo is null)
                        loop

                            insert into wf_d_flujos( cdgo_clnte                  , cdgo_fljo 
                                                   , dscrpcion_fljo              , undad_drcion         , drcion    
                                                   , undad_drcion_optma          , drcion_optma         , actvo
                                                   , id_fljo_trea_incial         , id_prcso             , indcdor_incia_usrio_fnal) 
                                             values( v_cdgo_clnte_dst            , c_flujos.cdgo_fljo 
                                                   , c_flujos.dscrpcion_fljo     , c_flujos.undad_drcion, c_flujos.drcion    
                                                   , c_flujos.undad_drcion_optma , c_flujos.drcion_optma, c_flujos.actvo
                                                   , c_flujos.id_fljo_trea_incial, c_flujos.id_prcso    , c_flujos.indcdor_incia_usrio_fnal)
                                           returning id_fljo 
                                                into v_id_fljo;

                            v_obj_fljo.append(json_object_t(json_object( key ''id_fljo_o''  value c_flujos.id_fljo
                                                                       , key ''id_fljo_d'' value v_id_fljo)));
                            --MIGRAMOS LAS TAREAS DEL FLUJO
                            for c_fljos_trea in (select * 
                                                   from wf_d_flujos_tarea@' || p_db_link || ' 
                                                  where id_fljo = c_flujos.id_fljo)
                            loop
                                insert into wf_d_flujos_tarea( id_fljo                           , id_trea                             , undad_drcion
                                                             , drcion                            , undad_drcion_optma                  , drcion_optma
                                                             , tpo_dia                           , indcdor_incio                       , actvo
                                                             , indcdor_procsar_estdo             , indcdor_trnscion_atmtca             , indcdor_vldar_tdos_fljos) 
                                                       values( v_id_fljo                         , c_fljos_trea.id_trea                , c_fljos_trea.undad_drcion
                                                             , c_fljos_trea.drcion               , c_fljos_trea.undad_drcion_optma     , c_fljos_trea.drcion_optma
                                                             , c_fljos_trea.tpo_dia              , c_fljos_trea.indcdor_incio          , c_fljos_trea.actvo
                                                             , c_fljos_trea.indcdor_procsar_estdo, c_fljos_trea.indcdor_trnscion_atmtca, c_fljos_trea.indcdor_vldar_tdos_fljos)
                                                     returning id_fljo_trea
                                                          into v_id_fljo_trea;

                                v_obj_trea.append(json_object_t(json_object( key ''id_fljo_trea_o'' value c_fljos_trea.id_fljo_trea
                                                                           , key ''id_fljo_trea_d'' value v_id_fljo_trea)));
                                --MIGRAMOS LOS ESTADOS DE UNA TAREA DEL FLUJO
                                insert into wf_d_flujos_tarea_estado
                                     select (select nvl(max(id_fljo_trea_estdo), 0) from wf_d_flujos_tarea_estado) + rownum as id_fljo_trea_estdo
                                          , v_id_fljo_trea as id_fljo_trea
                                          , dscrpcion
                                          , orden
                                          , actvo
                                          , dscrpcion_vsble  
                                       from wf_d_flujos_tarea_estado@' || p_db_link || '
                                      where id_fljo_trea = c_fljos_trea.id_fljo_trea;
                            end loop;

                            --MIGRAMOS LOS EVENTOS DE UN FLUJO
                            for c_flujo_evn in (select (select nvl(max(id_fljo_evnto), 0) from wf_d_flujos_evento ) + rownum as id
                                                     , id_fljo_evnto
                                                     , id_fljo
                                                     , id_evnto
                                                     , actvo 
                                                  from wf_d_flujos_evento@' || p_db_link || ' a
                                                 where a.id_fljo = c_flujos.id_fljo )
                            loop
                                insert into wf_d_flujos_evento( id_fljo_evnto       , id_fljo
                                                              , id_evnto            , actvo            )
                                                        values( c_flujo_evn.id      , v_id_fljo 
                                                              , c_flujo_evn.id_evnto, c_flujo_evn.actvo);

                                v_obj_evnt.append(json_object_t(json_object( key ''id_fljo_evnto_o'' value c_flujo_evn.id_fljo_evnto
                                                                           , key ''id_fljo_evnto_d'' value c_flujo_evn.id)));
                            end loop;

                            v_json_trea := v_obj_trea.to_clob();
                            --MIGRACIÃ“N DE TRANSICIONES
                            for c_trn in ( select id_fljo_trnscion
                                                , v_id_fljo as id_fljo
                                                , b.id_fljo_trea_d as id_fljo_trea
                                                , c.id_fljo_trea_d as id_fljo_trea_dstno
                                                , a.orden
                                                , a.nmbre_trnscion
                                                , a.cdgo_mtdo_asgncion
                                                , a.indcdor_aprbar_tdo_prtcpntes
                                                , a.indcdor_actlzar
                                             from wf_d_flujos_transicion@' || p_db_link || ' a
                                             join json_table(v_json_trea, ''$[*]'' columns(id_fljo_trea_o path ''$.id_fljo_trea_o'',
                                                                                         id_fljo_trea_d path ''$.id_fljo_trea_d'')) b on b.id_fljo_trea_o = a.id_fljo_trea
                                             join json_table(v_json_trea, ''$[*]'' columns(id_fljo_trea_o path ''$.id_fljo_trea_o'',
                                                                                         id_fljo_trea_d path ''$.id_fljo_trea_d'')) c on c.id_fljo_trea_o = a.id_fljo_trea_dstno
                                            where a.id_fljo = c_flujos.id_fljo )
                            loop
                                insert into wf_d_flujos_transicion ( id_fljo                           , id_fljo_trea         , id_fljo_trea_dstno
                                                                   , orden                             , nmbre_trnscion       , cdgo_mtdo_asgncion
                                                                   , indcdor_aprbar_tdo_prtcpntes      , indcdor_actlzar      ) 
                                                            values ( c_trn.id_fljo                     , c_trn.id_fljo_trea   , c_trn.id_fljo_trea_dstno
                                                                   , c_trn.orden                       , c_trn.nmbre_trnscion , c_trn.cdgo_mtdo_asgncion
                                                                   , c_trn.indcdor_aprbar_tdo_prtcpntes, c_trn.indcdor_actlzar)
                                                           returning id_fljo_trnscion 
                                                                into v_id_fljo_trnscion;

                                v_obj_trns.append(json_object_t(json_object( key ''id_fljo_trnscion_o'' value c_trn.id_fljo_trnscion
                                                                           , key ''id_fljo_trnscion_d'' value v_id_fljo_trnscion)));
                                --INSERTAMOS LOS PARAMETROS DE LA TRANSICION
                                insert into wf_d_flujos_trnscion_prmtro
                                    select (select nvl(max(id_fljo_trnscion_prmtro), 0)  from wf_d_flujos_trnscion_prmtro ) + rownum as id_fljo_trnscion_prmtro 
                                         , v_id_fljo_trnscion as id_fljo_trnscion 
                                         , prmtro_orgen
                                         , prmtro_dstno
                                         , actvo  
                                      from wf_d_flujos_trnscion_prmtro@' || p_db_link || ' a
                                     where a.id_fljo_trnscion = c_trn.id_fljo_trnscion; 
                                --INSERTAMOS LAS CONDICIONES DE LA TRANSICION
                                insert into wf_d_flujos_trnscion_cndcion
                                     select (select nvl(max(id_fljo_trnscion_cndcion), 0) from wf_d_flujos_trnscion_cndcion) + rownum as id_fljo_trnscion_cndcion
                                          , v_id_fljo_trnscion as id_fljo_trnscion
                                          , tpo_cndcion
                                          , id_trea_atrbto
                                          , objto_cndcion
                                          , id_oprdor_tpo
                                          , vlor1
                                          , vlor2
                                          , cmprta_lgca
                                          , orden_agrpcion
                                          , mnsje
                                       from wf_d_flujos_trnscion_cndcion@' || p_db_link || '
                                      where id_fljo_trnscion = c_trn.id_fljo_trnscion;
                            end loop;
                        end loop;

                        v_json_fljo     := v_obj_fljo.to_clob();
                        v_json_trea     := v_obj_trea.to_clob();
                        v_json_trns     := v_obj_trns.to_clob();
                        v_json_evnt     := v_obj_evnt.to_clob();       

                        --MIGRACION DE MANEJADORES DE EVENTOS DE UN FLUJO
                        for c_fljo_mnjdor in ( select id_fljo_evnto_mnjdor
                                                    , d.id_fljo_d  as id_fljo
                                                    , c.id_fljo_trea_d id_fljo_trea
                                                    , id_fljo_evnto_d as id_fljo_evnto
                                                    , fncion
                                                 from wf_d_flujos_evento_manejdor@' || p_db_link || ' a
                                                 join json_table(v_json_evnt, ''$[*]'' columns ( id_fljo_evnto_o path ''$.id_fljo_evnto_o''
                                                                                             , id_fljo_evnto_d path ''$.id_fljo_evnto_d'')) b
                                                   on b.id_fljo_evnto_o = a.id_fljo_evnto
                                                 join json_table(v_json_trea, ''$[*]'' columns ( id_fljo_trea_o path ''$.id_fljo_trea_o''
                                                                                             , id_fljo_trea_d path ''$.id_fljo_trea_d'')) c
                                                   on c.id_fljo_trea_o = a.id_fljo_trea
                                                 join json_table(v_json_fljo, ''$[*]'' columns ( id_fljo_o path ''$.id_fljo_o''
                                                                                             , id_fljo_d path ''$.id_fljo_d'')) d
                                                   on d.id_fljo_o = a.id_fljo)
                        loop
                            insert into wf_d_flujos_evento_manejdor( id_fljo                    , id_fljo_trea
                                                                   , id_fljo_evnto              , fncion      )
                                                             values( c_fljo_mnjdor.id_fljo      , c_fljo_mnjdor.id_fljo_trea
                                                                   , c_fljo_mnjdor.id_fljo_evnto, c_fljo_mnjdor.fncion      )
                                                           returning id_fljo_evnto_mnjdor 
                                                                into v_id_fljo_evnto_mnjdor;


                            v_obj_evnt_mnj.append(json_object_t(json_object( key ''id_fljo_evnto_mnjdor_o'' value c_fljo_mnjdor.id_fljo_evnto_mnjdor
                                                                           , key ''id_fljo_evnto_mnjdor_d'' value v_id_fljo_evnto_mnjdor)));

                        end loop;
                    end;
                end; ';

        begin
            execute immediate v_sql;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo ejecutar la migracion. ERROR => ' || sqlerrm;  
        end;
        rollback;
    end prc_rg_migrar_flujo;

    procedure prc_rg_migrar_plantilla(p_db_link          in varchar2
                                    , p_cdgo_clnte_orgen in number
                                    , p_cdgo_clnte_dstno in number
                                    , p_bsqda            in varchar2
                                    , o_cdgo_rspsta      out number
                                    , o_mnsje_rspsta     out varchar2 )
    as
        v_sql clob;
    begin
        v_sql :=    'declare
                        v_id_plntlla        number := ' || p_bsqda || ';
                        v_cdgo_clnte_o      number := ' || p_cdgo_clnte_orgen || ';
                        v_cdgo_clnte_d      number := ' || p_cdgo_clnte_dstno || ';
                        v_id_plntlla_cnslta number;
                        v_array_cnslta      json_array_t    := json_array_t(''[]'');
                        v_obj_cnslta        json_object_t;

                    begin

                        --MIGRAMOS LAS VARIABLES DE LAS PLANTILLAS
                        begin
                            for v in ( select a.* 
                                        from gn_d_plantillas_variable@' || p_db_link || ' a 
                                    left join gn_d_plantillas_variable b
                                        on b.cdgo_plntlla_vrble = a.cdgo_plntlla_vrble
                                        where b.cdgo_plntlla_vrble is null       
                                    )
                            loop
                                insert into gn_d_plantillas_variable( cdgo_plntlla_vrble  , nmbre  , dscrpcion  , tpo  , fncion  ) 
                                                            values( v.cdgo_plntlla_vrble, v.nmbre, v.dscrpcion, v.tpo, v.fncion);
                            end loop;    
                        end;

                        --MIGRAMOS LA PLANTILLA DINÁMICA    
                        begin
                            for c in (select a.* 
                                        from gn_d_plantillas@' || p_db_link || ' a 
                                left join gn_d_plantillas b
                                        on b.id_plntlla = a.id_plntlla
                                    where a.cdgo_clnte = v_cdgo_clnte_o
                                        and a.id_plntlla = v_id_plntlla
                                        and b.id_plntlla is null)
                            loop
                                insert into gn_d_plantillas( id_plntlla  , cdgo_clnte    , id_acto_tpo 
                                                        , dscrpcion   , actvo         , dfcto 
                                                        , id_rprte    , fcha_incio    , fcha_fin 
                                                        , id_prcso    , tpo_plntlla   )
                                                    values( c.id_plntlla, v_cdgo_clnte_d, c.id_acto_tpo 
                                                        , c.dscrpcion , c.actvo       , c.dfcto 
                                                        , c.id_rprte  , c.fcha_incio  , c.fcha_fin 
                                                        , c.id_prcso  , c.tpo_plntlla);

                                --MIGRAMOS LA CONSULTAS DE LA PLANTILLA DINÁMICA   
                                for s in (select * 
                                            from gn_d_plantillas_consulta@' || p_db_link || '
                                        where id_plntlla = v_id_plntlla)
                                loop
                                    insert into gn_d_plantillas_consulta( id_plntlla  , dscrpcion       , cnslta
                                                                        , prmtros     , dscrpcion_crta  , tpo_cnslta )
                                                                values( s.id_plntlla, s.dscrpcion     , s.cnslta
                                                                        , s.prmtros   , s.dscrpcion_crta, s.tpo_cnslta)
                                                                returning id_plntlla_cnslta 
                                                                    into v_id_plntlla_cnslta;
                                    v_array_cnslta.append(json_object_t(json_object( key ''id_plntlla_cnslta_o''  value s.id_plntlla_cnslta
                                                                                , key ''id_plntlla_cnslta_d''  value v_id_plntlla_cnslta)));
                                end loop;

                                --MIGRAMOS LOS PARRAFOS DE LA  PLANTILLA DINÁMICA   
                                for p in (select *
                                            from gn_d_plantillas_parrafo@' || p_db_link || '
                                        where id_plntlla = v_id_plntlla )
                                loop

                                for i in 0..v_array_cnslta.get_size -1 
                                    loop
                                        v_obj_cnslta := json_object_t(v_array_cnslta.get(i));
                                        p.prrfo := replace( p.prrfo 
                                                        , ''<a href="''|| v_obj_cnslta.get_Number(''id_plntlla_cnslta_o'') ||  ''">''
                                                        , ''<a href="''|| v_obj_cnslta.get_Number(''id_plntlla_cnslta_d'') ||  ''">'');
                                    end loop;
                                    insert into gn_d_plantillas_parrafo( id_plntlla  , dscrpcion  , prrfo  , orden  ) 
                                                                values( p.id_plntlla, p.dscrpcion, p.prrfo, p.orden);
                                end loop;
                            end loop;
                        end;
                    end;';

        begin
            execute immediate v_sql;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo ejecutar la migracion. ERROR => ' || sqlerrm;  
        end;
    end prc_rg_migrar_plantilla;

end pkg_mm_migracion_modulo;

/
