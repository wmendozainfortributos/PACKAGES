--------------------------------------------------------
--  DDL for Package Body PKG_NT_NOTIFICACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_NT_NOTIFICACION" as
  
  procedure prc_co_min_orden(
    p_id_ntfccion   in number,
    o_min_orden     out number,
    o_cant_mdios    out number,
    o_mnsje_tpo     out varchar2,
    o_mnsje         out varchar2
  )is
    v_error exception;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_co_min_orden';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --/Consultamos la cantidad de medios parametrizados
    begin
        select count(*)
        into o_cant_mdios
        from nt_d_acto_medio_orden a
        inner join v_nt_g_notfccnes_gn_g_actos b on p_id_ntfccion = b.id_ntfccion and a.id_acto_tpo = b.id_acto_tpo;
    end;

    --/Obtenemos el orden min
    begin
        select orden into o_min_orden from (
            select a.orden
            from nt_d_acto_medio_orden a
            inner join nt_d_medio b on a.id_mdio = b.id_mdio
            inner join v_nt_g_notfccnes_gn_g_actos c on p_id_ntfccion = c.id_ntfccion 
            where a.id_acto_tpo  = c.id_acto_tpo and
                  ((o_cant_mdios  > 1 and  a.id_mdio not in (select id_mdio 
                                                              from nt_g_notificaciones_detalle
                                                              where id_ntfccion = p_id_ntfccion)) or (o_cant_mdios = 1))
            order by a.orden asc
        ) where rownum = 1;
    exception
        when others then
            o_mnsje  := 'Problemas al consultar el siguiente orden Id_ntfccion: '||p_id_ntfccion||' , '||'Cant:'||o_cant_mdios||':::::'||SQLERRM;
            raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;  
  end prc_co_min_orden;

  procedure prc_rg_notificacion_automatica(
    p_id_acto in  number
  ) is
    v_mnsje_tpo varchar2(20);
    v_mnsje     varchar2(3200);

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificacion_automatica';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Recorremos los actos que tienen asociado el acto que viene por parametros como requerido
    for c_actos in (
        select *
        from v_nt_g_notfccnes_gn_g_actos
        where id_acto_rqrdo_ntfccion = p_id_acto
    )loop
        declare
          v_id_ntfccion         nt_g_notificaciones.id_ntfccion%type;
          v_id_ntfccion_dtlle   nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
          v_error               exception;
        begin

            --//Consultamos si el acto seleccionado tiene responsables
            declare
                v_cant_responsables number;
            begin
                select count(*)
                into v_cant_responsables
                from gn_g_actos_responsable
                where id_acto = c_actos.id_acto;

                if(v_cant_responsables < 1)then
                   v_mnsje := 'El acto No. '||c_actos.nmro_acto||' no tiene responsables por favor verifique..!!';
                   raise v_error; 
                end if;
            end;

            --//Consultamos y/o Insertamos en Notificaciones
            pkg_nt_notificacion.prc_rg_notificaciones(
                p_cdgo_clnte        => c_actos.cdgo_clnte,
                p_id_ntfccion       => v_id_ntfccion,
                p_id_acto           => c_actos.id_acto,
                p_cdgo_estdo        => 'NGN',--Notificacion Generada
                p_indcdor_ntfcdo    => 'N',
                p_id_fncnrio        => null,
                o_mnsje_tpo         => v_mnsje_tpo,
                o_mnsje             => v_mnsje
            );

            --Validamos si hubo errores al insertar en 'NT_G_NOTIFICACIONES'
            if(v_mnsje_tpo = 'ERROR')then
                raise v_error;
            end if;

        exception
            when v_error then
                null;
        end;
    end loop;
  end prc_rg_notificacion_automatica;

  procedure prc_gn_detalle_notificacion is
    v_mnsje_tpo varchar2(20);
    v_mnsje     varchar2(3200);

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_gn_detalle_notificacion';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Cursor para verificar las notificaciones que se encuentran vencidas
    for c_detalle_notificacion in (
        select  cdgo_clnte, 
                id_acto, 
                nmro_acto, 
                id_ntfccion, 
                id_ntfccion_dtlle,
                id_entdad_clnte_mdio, 
                id_mdio, 
                id_acto_tpo 
        from v_nt_g_notificaciones_detalle
        where cdgo_estdo            in ('NEP','NGN')    and
              trunc(fcha_fin_trmno) < trunc(sysdate)
    )loop
        declare
            v_error             exception;
            v_count_mdios       number;
            v_min_orden         number;
        begin

            -------------------------------------
            --//Obtenemos el Min orden
            pkg_nt_notificacion.prc_co_min_orden(
                p_id_ntfccion   => c_detalle_notificacion.id_ntfccion,
                o_min_orden     => v_min_orden,
                o_cant_mdios    => v_count_mdios,
                o_mnsje_tpo     => v_mnsje_tpo,
                o_mnsje         => v_mnsje
            );

            if(v_mnsje_tpo = 'ERROR')then
                raise v_error;
            end if;
            -------------------------------------
            for c_medios in (
                select a.id_mdio,
                       a.indcdor_autmtco,
                       a.drcion,
                       a.undad_drcion,
                       a.dia_tpo
                from nt_d_acto_medio_orden a
                inner join nt_d_medio b on a.id_mdio = b.id_mdio
                where a.id_acto_tpo  = c_detalle_notificacion.id_acto_tpo and
                      ((v_count_mdios  > 1 and  a.id_mdio not in (select id_mdio 
                                                                  from nt_g_notificaciones_detalle
                                                                  where id_ntfccion = c_detalle_notificacion.id_ntfccion)) or (v_count_mdios = 1)) and
                      a.orden = v_min_orden
                order by a.orden asc
            )loop
                declare
                    v_id_ntfccion_dtlle nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
                begin
                    if(c_medios.indcdor_autmtco = 'S')then
                        pkg_nt_notificacion.prc_rg_notificacion_detalle(
                            p_id_ntfccion_dtlle     => v_id_ntfccion_dtlle,
                            p_id_ntfccion           => c_detalle_notificacion.id_ntfccion,
                            p_id_mdio               => c_medios.id_mdio,
                            p_id_entdad_clnte_mdio  => null,
                            p_fcha_gnrcion          => sysdate,
                            p_fcha_fin_trmno        => pk_util_calendario.fnc_cl_fecha_final(
                                                        p_cdgo_clnte    => c_detalle_notificacion.cdgo_clnte, 
                                                        p_fecha_inicial => systimestamp, 
                                                        p_undad_drcion  => c_medios.undad_drcion, 
                                                        p_drcion        => c_medios.drcion, 
                                                        p_dia_tpo       => c_medios.dia_tpo
                                                       ),
                            p_id_fncnrio_gnrcion    => null,
                            o_mnsje_tpo             => v_mnsje_tpo,
                            o_mnsje                 => v_mnsje
                        );

                        if(v_mnsje_tpo = 'ERROR')then
                            raise v_error;
                        end if; 

                        --Registramos los responsables del detalle
                        pkg_nt_notificacion.prc_rg_notificacion_respnsbles(
                            p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                            p_id_acto                   => c_detalle_notificacion.id_acto,
                            p_indca_notfcdo             => 'S',
                            o_mnsje_tpo                 => v_mnsje_tpo,
                            o_mnsje                     => v_mnsje
                        );


                        if(v_mnsje_tpo = 'ERROR')then
                            raise v_error;
                        end if;

                    else
                        begin
                            update nt_g_notificaciones
                            set cdgo_estdo = 'NPR'
                            where id_ntfccion = c_detalle_notificacion.id_ntfccion;
                        exception
                            when others then
                                v_mnsje := 'Problemas al actualizar estado de la notificacion';
                                raise v_error;
                        end;
                    end if;

                    commit;--//Confimarmos si no hay errores

                end;
            end loop;
        exception
            when v_error then

                if(v_mnsje is null)then
                    v_mnsje := SQLERRM;
                end if;
                if(v_mnsje_tpo is null)then
                    v_mnsje_tpo := 'ERROR';
                end if;  
        end;
    end loop;
  end prc_gn_detalle_notificacion;

  procedure prc_ac_edicto(
    p_id_lte        in  nt_g_lote.id_lte%type,
    p_fcha_fin      in  timestamp,
    p_file_evdncia  in  varchar2,
    p_id_fncnrio    in  number,
    o_mnsje_tpo     out varchar2,
    o_mnsje         out varchar2
  ) is
    v_error                     exception;
    v_id_edcto                  nt_g_edicto.id_edcto%type;
    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;
    --Evidencia
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_ac_edicto';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Consultamos el Edicto y la Evidencia Asociada al Lote
    begin
        select b.id_edcto,
               a.id_ntfcion_mdio_evdncia
        into   v_id_edcto,
               v_id_ntfcion_mdio_evdncia       
        from nt_g_lote a
        inner join nt_g_edicto b on a.id_ntfcion_mdio_evdncia = b.id_ntfcion_mdio_evdncia
        where a.id_lte = p_id_lte;
    exception
        when others then
            o_mnsje     := 'Problemas al consultar lote a actualizar, '||sqlerrm;
            raise v_error; 
    end;

    --Obtenemos el archivo subido
    pkg_nt_notificacion.pr_co_archivo_evidencia(
        p_file_name     => p_file_evdncia,
        p_file_mimetype	=> v_file_mimetype,
        p_file_blob     => v_file_blob,
        o_mnsje_tpo     => o_mnsje_tpo,
        o_mnsje         => o_mnsje
    );

    if(o_mnsje_tpo = 'ERROR')then
        raise v_error;
    end if;

    --Actualizamos la Evidencia
    begin
        update nt_g_medio_entidad_evdncia
        set file_name       = substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
            file_mimetype   = v_file_mimetype,
            file_blob       = v_file_blob
        where id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia;
    exception   
        when others then
            o_mnsje := 'Problemas al Actualizar Evidencia Asociada al Lote, '||SQLERRM;
            raise v_error;
    end;

    --Actualizamos el Edicto
    begin
        update nt_g_edicto
        set fcha_fin = P_FCHA_FIN
        where id_edcto = v_id_edcto;
    exception
        when others then
            o_mnsje := 'Problemas al Actualizar Edicto, '||SQLERRM;
            raise v_error;
    end;

    --Actualizamos el Estado del Lote
    begin
        update nt_g_lote
        set fcha_prcsmnto       = sysdate,
            id_fncnrio_prcsmnto = p_id_fncnrio,
            cdgo_estdo_lte      = 'PRO' --PROCESADO
        where id_lte = p_id_lte;
    exception
        when others then
            o_mnsje := 'Problemas al Actualizar Lote';
            raise v_error;
    end;

  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;  
  end prc_ac_edicto;

  procedure prc_rg_edicto(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_fcha_incio            in  timestamp,
    p_ubccion               in  varchar2,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  ) is
    v_error                     exception;
    v_csal                      nt_d_causales%rowtype;
    v_cdgo_clnte                number;
    --Edicto
    v_id_mdio                   nt_d_medio.id_mdio%type;
    v_undad_drcion              nt_d_acto_medio_orden.undad_drcion%type; 
    v_drcion                    nt_g_edicto.drcion_dias%type;
    v_dia_tpo                   nt_g_edicto.dia_tpo%type;

    --Evidencia
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;
    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;

    v_id_entdad_clnte_mdio      nt_d_entidad_cliente_medio.id_entdad_clnte_mdio%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_edicto';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--

  begin
    --Consultamos el Id_Medio de EDT - Edicto
    begin
        select a.cdgo_clnte,
               b.id_mdio,
               c.drcion,
               c.dia_tpo,
               c.undad_drcion,
               a.id_entdad_clnte_mdio 
        into v_cdgo_clnte,
             v_id_mdio,
             v_drcion,
             v_dia_tpo,
             v_undad_drcion,
             v_id_entdad_clnte_mdio
        from nt_g_lote a
        inner join v_nt_d_ntfccion_mdio_entdd b on a.id_entdad_clnte_mdio = b.id_entdad_clnte_mdio
        inner join nt_d_acto_medio_orden      c on b.id_mdio              = c.id_mdio and
                                                   a.id_acto_tpo        = c.id_acto_tpo
        where a.id_lte = p_id_lte; 
    exception
        when others then
            o_mnsje := 'Problemas al consultar el medio asociado al acto, '||SQLERRM;
            raise v_error;
    end;

    --Obtenemos el archivo subido
    pkg_nt_notificacion.pr_co_archivo_evidencia(
        p_file_name     => p_file_evdncia,
        p_file_mimetype	=> v_file_mimetype,
        p_file_blob     => v_file_blob,
        o_mnsje_tpo     => o_mnsje_tpo,
        o_mnsje         => o_mnsje
    );

    if(o_mnsje_tpo = 'ERROR')then
        raise v_error;
    end if;

    --Registramos la evidencia
    begin
        insert into nt_g_medio_entidad_evdncia(
            cdgo_clnte,
            id_mdio,
            file_blob,
            file_name,
            file_mimetype,
            fcha_ntfccion
        )values(
            v_cdgo_clnte,
            v_id_mdio,
            v_file_blob,
            substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
            v_file_mimetype,
            sysdate
        )  returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
    exception
        when others then
            o_mnsje := 'Problemas al insertar evidencia Id_Mdio: '||v_id_mdio||' , '||SQLERRM;
            raise v_error;  
    end;

    --Registramos en Edicto
    begin
        insert into nt_g_edicto(
            id_ntfcion_mdio_evdncia,
            fcha_incio,
            drcion_dias,
            dia_tpo,
            ubccion,
            fcha_rgstro
        ) values(
            v_id_ntfcion_mdio_evdncia,
            p_fcha_incio,
            v_drcion,
            v_dia_tpo,
            p_ubccion,
            sysdate
        );
    exception
        when others then
            o_mnsje := 'Problemas al insertar Edicto, '||SQLERRM;
            raise v_error;  
    end;

    --Consultamos causal que da por notificado
    begin
        select *
        into v_csal
        from nt_d_causales
        where indcdor_ntfcdo = 'S';
    exception
        when others then
            o_mnsje := 'Problemas al consultar causal para notificar, '||SQLERRM;
            raise v_error;    
    end;



    --Cargamos la evidencia a los responsables del lote
    for c_responsables in(
        select id_ntfccion_rspnsble
        from nt_d_lote_detalle
        where id_lte = p_id_lte
    )loop
        begin
            update nt_g_ntfccnes_rspnsble
            set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
                indcdor_ntfcdo          = 'S',
                fcha_ntfccion           = p_fcha_incio,
                cdgo_csal               = v_csal.cdgo_csal,
                id_fncnrio              = p_id_fncnrio
            where id_ntfccion_rspnsble = c_responsables.id_ntfccion_rspnsble;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar responsables asociados al lote, Id_Lote: '||p_id_lte||', '||SQLERRM;
                raise v_error;  
        end;
    end loop;

    --Actualizamos el lote
    begin
        update nt_g_lote
        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia
        where id_lte  =  p_id_lte;
    exception
        when others then
            o_mnsje := 'Problemas al Actualizar Lote, '||SQLERRM;
            raise v_error;
    end;

    ---Actualizamos el estado del intento de notificacion
    for c_notificacion_dtlle in(
        select a.id_ntfccion_dtlle 
        from v_nt_g_ntfccnes_rspnsble a
        inner join nt_d_lote_detalle b on a.id_ntfccion_rspnsble = b.id_ntfccion_rspnsble
        where b.id_lte = p_id_lte
        group by a.id_ntfccion_dtlle 
    )loop 
        begin
            update nt_g_notificaciones_detalle
            set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio,
                id_fncnrio_prcsmnto  = p_id_fncnrio
            where id_ntfccion_dtlle = c_notificacion_dtlle.id_ntfccion_dtlle;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar estado del intento de notificacion, '||SQLERRM;
                raise v_error;  
        end;
    end loop;


  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_rg_edicto;

  procedure prc_rg_gaceta(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_nmro_gceta            in  nt_g_gaceta.nmro_gceta%type,
    p_fcha_pblccion         in  timestamp,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  ) is
    v_error exception;
    v_csal  nt_d_causales%rowtype;
    v_cdgo_clnte                number;
    v_id_mdio                   nt_d_medio.id_mdio%type;

    --Evidencia
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;
    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;

    v_id_entdad_clnte_mdio      nt_d_entidad_cliente_medio.id_entdad_clnte_mdio%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_gaceta';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--

  begin

    --Consultamos el Id_Medio de GCT - Gaceta
    begin
        select a.cdgo_clnte,
               b.id_mdio,
               a.id_entdad_clnte_mdio 
        into v_cdgo_clnte,
             v_id_mdio,
             v_id_entdad_clnte_mdio
        from nt_g_lote a
        inner join v_nt_d_ntfccion_mdio_entdd b on a.id_entdad_clnte_mdio = b.id_entdad_clnte_mdio
        inner join nt_d_acto_medio_orden      c on b.id_mdio              = c.id_mdio and
                                                   a.id_acto_tpo        = c.id_acto_tpo
        where a.id_lte = p_id_lte; 
    exception
        when others then
            o_mnsje := 'Problemas al consultar el medio asociado al acto, '||SQLERRM||','||p_id_lte;
            raise v_error;
    end;

    --Obtenemos el archivo subido
    pkg_nt_notificacion.pr_co_archivo_evidencia(
        p_file_name     => p_file_evdncia,
        p_file_mimetype	=> v_file_mimetype,
        p_file_blob     => v_file_blob,
        o_mnsje_tpo     => o_mnsje_tpo,
        o_mnsje         => o_mnsje
    );

    if(o_mnsje_tpo = 'ERROR')then
        raise v_error;
    end if;

    --Registramos la evidencia
    begin
        insert into nt_g_medio_entidad_evdncia(
            cdgo_clnte,
            id_mdio,
            file_blob,
            file_name,
            file_mimetype,
            fcha_ntfccion
        )values(
            v_cdgo_clnte,
            v_id_mdio,
            v_file_blob,
            substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
            v_file_mimetype,
            p_fcha_pblccion
        )  returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
    exception
        when others then
            o_mnsje := 'Problemas al insertar evidencia Id_Mdio: '||v_id_mdio||' , '||SQLERRM;
            raise v_error;  
    end;

    --Registramos en Gaceta
    begin
        insert into nt_g_gaceta(
            id_ntfcion_mdio_evdncia,
            nmro_gceta,
            fcha_pblccion
        )values(
            v_id_ntfcion_mdio_evdncia,
            p_nmro_gceta,
            p_fcha_pblccion
        );
    exception
        when others then
            o_mnsje := 'Problemas al insertar Gaceta, '||SQLERRM;
            raise v_error; 
    end;

    --Consultamos causal que da por notificado
    begin
        select *
        into v_csal
        from nt_d_causales
        where indcdor_ntfcdo = 'S';
    exception
        when others then
            o_mnsje := 'Problemas al consultar causal para notificar, '||SQLERRM;
            raise v_error;    
    end;

    --Cargamos la evidencia a los responsables del lote
    for c_responsables in(
        select id_ntfccion_rspnsble
        from nt_d_lote_detalle
        where id_lte = p_id_lte
    )loop
        begin
            update nt_g_ntfccnes_rspnsble
            set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
                indcdor_ntfcdo          = 'S',
                fcha_ntfccion           = p_fcha_pblccion,
                cdgo_csal               = v_csal.cdgo_csal,
                id_fncnrio              = p_id_fncnrio
            where id_ntfccion_rspnsble = c_responsables.id_ntfccion_rspnsble;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar responsables asociados al lote, Id_Lote: '||p_id_lte||', '||SQLERRM;
                raise v_error;  
        end;
    end loop;

    --Actualizamos el lote
    begin
        update nt_g_lote
        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
            fcha_prcsmnto           = sysdate,
            id_fncnrio_prcsmnto     = p_id_fncnrio,
            cdgo_estdo_lte          = 'PRO' --Procesado
        where id_lte  =  p_id_lte;
    exception
        when others then
            o_mnsje := 'Problemas al Actualizar Lote, '||SQLERRM;
            raise v_error;
    end;

    ---Actualizamos el estado del intento de notificacion
    for c_notificacion_dtlle in(
        select a.id_ntfccion_dtlle 
        from v_nt_g_ntfccnes_rspnsble a
        inner join nt_d_lote_detalle b on a.id_ntfccion_rspnsble = b.id_ntfccion_rspnsble
        where b.id_lte = p_id_lte
        group by a.id_ntfccion_dtlle 
    )loop 
        begin
            update nt_g_notificaciones_detalle
            set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio,
                id_fncnrio_prcsmnto  = p_id_fncnrio
            where id_ntfccion_dtlle = c_notificacion_dtlle.id_ntfccion_dtlle;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar estado del intento de notificacion, '||SQLERRM;
                raise v_error;  
        end;
    end loop;
  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_rg_gaceta;

  procedure prc_rg_prensa(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_ubccion               in  varchar2,
    p_fcha_rgstro           in  timestamp,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  ) is
    v_error exception;
    v_csal  nt_d_causales%rowtype;

    v_id_mdio                   nt_d_medio.id_mdio%type;
    v_cdgo_clnte                number;
    --Evidencia
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;
    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;

    v_id_entdad_clnte_mdio      nt_d_entidad_cliente_medio.id_entdad_clnte_mdio%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_prensa';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin

    --Consultamos el Id_Medio de Prensa
    begin
        select a.cdgo_clnte,
               b.id_mdio,
               a.id_entdad_clnte_mdio 
        into v_cdgo_clnte,
             v_id_mdio,
             v_id_entdad_clnte_mdio
        from nt_g_lote a
        inner join v_nt_d_ntfccion_mdio_entdd b on a.id_entdad_clnte_mdio = b.id_entdad_clnte_mdio
        inner join nt_d_acto_medio_orden      c on b.id_mdio              = c.id_mdio and
                                                   a.id_acto_tpo        = c.id_acto_tpo
        where a.id_lte = p_id_lte; 
    exception
        when others then
            o_mnsje := 'Problemas al consultar el medio asociado al acto, '||SQLERRM;
            raise v_error;
    end;

    --Obtenemos el archivo subido
    pkg_nt_notificacion.pr_co_archivo_evidencia(
        p_file_name     => p_file_evdncia,
        p_file_mimetype	=> v_file_mimetype,
        p_file_blob     => v_file_blob,
        o_mnsje_tpo     => o_mnsje_tpo,
        o_mnsje         => o_mnsje
    );

    if(o_mnsje_tpo = 'ERROR')then
        raise v_error;
    end if;

    --Registramos la evidencia
    begin
        insert into nt_g_medio_entidad_evdncia(
            cdgo_clnte,
            id_mdio,
            file_blob,
            file_name,
            file_mimetype,
            fcha_ntfccion
        )values(
            v_cdgo_clnte,
            v_id_mdio,
            v_file_blob,
            substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
            v_file_mimetype,
            p_fcha_rgstro
        )  returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
    exception
        when others then
            o_mnsje := 'Problemas al insertar evidencia Id_Mdio: '||v_id_mdio||' , '||SQLERRM;
            raise v_error;  
    end;

   --Registramos en Prensa
    begin
        insert into nt_g_prensa(
            id_ntfcion_mdio_evdncia,
            ubccion,
            fcha_rgstro
        )values(
            v_id_ntfcion_mdio_evdncia,
            p_ubccion,
            p_fcha_rgstro
        );
    exception
        when others then
            o_mnsje := 'Problemas al insertar Prensa, '||SQLERRM;
            raise v_error; 
    end;

    --Consultamos causal que da por notificado
    begin
        select *
        into v_csal
        from nt_d_causales
        where indcdor_ntfcdo = 'S';
    exception
        when others then
            o_mnsje := 'Problemas al consultar causal para notificar, '||SQLERRM;
            raise v_error;    
    end;

    --Cargamos la evidencia a los responsables del lote
    for c_responsables in(
        select id_ntfccion_rspnsble
        from nt_d_lote_detalle
        where id_lte = p_id_lte
    )loop
        begin
            update nt_g_ntfccnes_rspnsble
            set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
                indcdor_ntfcdo          = 'S',
                fcha_ntfccion           = p_fcha_rgstro,
                cdgo_csal               = v_csal.cdgo_csal,
                id_fncnrio              = p_id_fncnrio
            where id_ntfccion_rspnsble = c_responsables.id_ntfccion_rspnsble;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar responsables asociados al lote, Id_Lote: '||p_id_lte||', '||SQLERRM;
                raise v_error;  
        end;
    end loop;

    --Actualizamos el lote
    begin
        update nt_g_lote
        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
            fcha_prcsmnto           = sysdate,
            id_fncnrio_prcsmnto     = p_id_fncnrio,
            cdgo_estdo_lte          = 'PRO' --Procesado
        where id_lte  =  p_id_lte;
    exception
        when others then
            o_mnsje := 'Problemas al Actualizar Lote, '||SQLERRM;
            raise v_error;
    end;

    ---Actualizamos el estado del intento de notificacion
    for c_notificacion_dtlle in(
        select a.id_ntfccion_dtlle 
        from v_nt_g_ntfccnes_rspnsble a
        inner join nt_d_lote_detalle b on a.id_ntfccion_rspnsble = b.id_ntfccion_rspnsble
        where b.id_lte = p_id_lte
        group by a.id_ntfccion_dtlle 
    )loop 
        begin
            update nt_g_notificaciones_detalle
            set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio,
                id_fncnrio_prcsmnto  = p_id_fncnrio
            where id_ntfccion_dtlle = c_notificacion_dtlle.id_ntfccion_dtlle;
        exception
            when others then
                o_mnsje := 'Problemas al actualizar estado del intento de notificacion, '||SQLERRM;
                raise v_error;  
        end;
    end loop;
  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_rg_prensa;

  procedure prc_rg_notificacion__puntual(
    p_cdgo_clnte			in  number,
    p_id_acto               in  number,
    p_id_ntfccion           in  nt_g_notificaciones.id_ntfccion%type,
    p_json_rspnsbles        in  clob,
    p_cdgo_rspnsble_tpo     in df_s_responsables_tipo.cdgo_rspnsble_tpo%type        default null, 
    p_cdgo_idntfccion_tpo   in df_s_identificaciones_tipo.cdgo_idntfccion_tpo%type  default null,
    p_nmro_idntfccion       in nt_g_presentacion_personal.nmro_idntfccion%type      default null,
    p_cdgo_mncpio           in  varchar2                                            default null,
    p_nmro_trjeta_prfsnal   in  varchar2                                            default null,
    p_prmer_nmbre           in  varchar2                                            default null,
    p_sgndo_nmbre           in  varchar2                                            default null,
    p_prmer_aplldo          in  varchar2                                            default null,
    p_sgndo_aplldo          in  varchar2                                            default null,
    p_file_evdncia          in  varchar2,
    p_fcha_prsntccion       in  timestamp                                           default null,
    p_id_fncnrio            in  number,
    p_cdgo_mdio             in  varchar2,
    o_cdgo_rspsta			out number,
    o_mnsje_rspsta          out varchar2
  ) is
    --Manejo de errores en el proceso de notificacion
    v_error                     exception;
    v_mnsje_tpo                 varchar2(20);

    --------------------------------

    --Informacion del acto seleccionado
    v_id_acto_tpo             gn_g_actos.id_acto_tpo%type;
    --------------------------------

    --Vigencia Notificacion
    v_undad_drcion              nt_d_acto_medio_orden.undad_drcion%type; 
    v_dia_tpo                   nt_d_acto_medio_orden.dia_tpo%type;
    v_drcion                    nt_d_acto_medio_orden.drcion%type;
    --------------------------------

    --Variables para el intento de notificacion
    v_id_entdad_clnte_mdio      nt_d_entidad_cliente_medio.id_entdad_clnte_mdio%type;
    v_id_mdio                   nt_d_entidad_cliente_medio.id_mdio%type;
    v_rt_csal                   nt_d_causales%rowtype;
    v_fcha_fin                  date;
    --------------------------------

    v_id_ntfccion_dtlle         nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;

    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;
    v_rspnsble                  nt_g_ntfccnes_rspnsble%rowtype;
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificacion_puntual';
    v_t_start   number;
    v_t_end     number;
    v_cdgo_csal nt_d_causales.cdgo_csal%type;    
    --+---------------------------------+--
  begin
    o_cdgo_rspsta := 0;
    --Consultamos el acto a notificar
    begin
        select id_acto_tpo
        into v_id_acto_tpo
        from v_gn_g_actos
        where id_acto = p_id_acto;
    exception
        when others then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al consultar el acto seleccionado Id_Acto: '||p_id_acto;
            raise v_error;
    end;
/*
 delete muerto;
  insert into muerto (c_001)values ('Entrando '||
		   '	p_cdgo_clnte        ' ||p_cdgo_clnte      ||
           '	p_id_acto           ' ||p_id_acto         ||
           '	p_id_ntfccion       ' ||p_id_ntfccion     ||
           '	p_fcha_prsntccion   ' ||p_fcha_prsntccion ||
           '	p_json_rspnsbles    ' ||p_json_rspnsbles  ||
           '	p_id_fncnrio        ' ||p_id_fncnrio      ||
           '	p_file_evdncia      ' ||p_file_evdncia    ||
           '	p_cdgo_mdio         ' ||p_cdgo_mdio       ||
           '	o_cdgo_rspsta       ' ||o_cdgo_rspsta     ||
           '	o_mnsje_rspsta      ' ||o_mnsje_rspsta    
);commit;*/



    --Validamos si el acto a notificar tiene responsables pendientes por notificar
    declare
        v_responsables varchar2(1);
    begin
        select case when count(a.id_acto_rspnsble) > 0 then 'S'
                    when count(a.id_acto_rspnsble) < 1 then 'N'
               end 
        into v_responsables
        from gn_g_actos_responsable a
        where a.id_acto          = p_id_acto and
              a.indcdor_ntfccion = 'N';
        if(v_responsables = 'N')then
            o_cdgo_rspsta   := 2;
            o_mnsje_rspsta  := 'El acto a notificar no tiene responsables pendientes por notificar por favor verifique, Id_Acto: '||p_id_acto;
            raise v_error;
        end if;
    end;

    --Consultamos el medio y la entidad cliente
    begin
        select id_entdad_clnte_mdio,id_mdio 
        into v_id_entdad_clnte_mdio,v_id_mdio
        from v_nt_d_ntfccion_mdio_entdd
        where cdgo_clnte    = p_cdgo_clnte and
              cdgo_mdio     = p_cdgo_mdio;
    exception
        when others then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := 'Problemas al consultar medio de notificacion puntual: '||p_cdgo_mdio||', '||SQLERRM;
            raise v_error;
    end;

    if p_cdgo_mdio = 'PPN' then
      v_cdgo_csal := 'NOT';
    elsif p_cdgo_mdio = 'CEL' then
      v_cdgo_csal := 'CEL';
    elsif p_cdgo_mdio = 'PWE' then
      v_cdgo_csal := 'PWE';
    elsif p_cdgo_mdio = 'CCY' then
      v_cdgo_csal := 'NOT';
    end if;
  

    --Consultamos causal que da por notificado
    begin
        select *
        into v_rt_csal
        from nt_d_causales
        where indcdor_ntfcdo = 'S' 
        and cdgo_csal = v_cdgo_csal;
    exception
        when others then
            o_cdgo_rspsta := 4;
            o_mnsje_rspsta := 'Problemas al consultar causal para notificar, '||SQLERRM;
            raise v_error;    
    end;

    --Consultamos termino de tiempo para la notificacion personal
    begin
        select undad_drcion, 
               dia_tpo, 
               drcion
        into v_undad_drcion, 
             v_dia_tpo, 
             v_drcion
        from nt_d_acto_medio_orden
        where id_acto_tpo   = v_id_acto_tpo and
              id_mdio       = v_id_mdio;
    exception
        when no_data_found then
           v_undad_drcion   := null;
           v_dia_tpo        := null;
           v_drcion         := null;
        when others then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := 'Problemas al consultar termino de tiempo para la notificacion puntual: '||p_cdgo_mdio||', id_acto_tpo: '||v_id_acto_tpo||' , '||SQLERRM;
            raise v_error; 
    end;

    --Consultamos si existe el intento de notificacion
    begin
        select id_ntfccion_dtlle
        into v_id_ntfccion_dtlle
        from v_nt_g_notificaciones_detalle
        where id_acto = p_id_acto and
              id_mdio = v_id_mdio;
    exception   
        when no_data_found then
            null;
        when others then
            o_cdgo_rspsta := 6;
            o_mnsje_rspsta := 'Problemas al consultar el intento de notificacion para el acto Id_Acto: '||p_id_acto||' Id_Medio: '||v_id_mdio;
            raise v_error; 
    end;
    --Validamos si existe el intento de notificacion
    if(v_id_ntfccion_dtlle is null)then



        if(v_dia_tpo is not null and v_drcion is not null)then
            v_fcha_fin := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte, 
                                                                p_fecha_inicial => systimestamp, 
                                                                p_undad_drcion  => v_undad_drcion, 
                                                                p_drcion        => v_drcion, 
                                                                p_dia_tpo       => v_dia_tpo);

        end if;
        --Registramos el intento de notificacion
        pkg_nt_notificacion.prc_rg_notificacion_detalle(p_id_ntfccion_dtlle     => v_id_ntfccion_dtlle,
                                                        p_id_ntfccion           => p_id_ntfccion,
                                                        p_id_mdio               => v_id_mdio,
                                                        p_id_entdad_clnte_mdio  => v_id_entdad_clnte_mdio,
                                                        p_fcha_gnrcion          => sysdate,
                                                        p_fcha_fin_trmno        => v_fcha_fin,
                                                        p_id_fncnrio_gnrcion    => p_id_fncnrio,
                                                        o_mnsje_tpo             => v_mnsje_tpo,
                                                        o_mnsje                 => o_mnsje_rspsta);

        --Validamos si hubo errores al registrar el intento de notificacion
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 7;
            raise v_error;
        end if;
        --Obtenemos el archivo subido
        pkg_nt_notificacion.pr_co_archivo_evidencia(p_file_name     => p_file_evdncia,
                                                    p_file_mimetype	=> v_file_mimetype,
                                                    p_file_blob     => v_file_blob,
                                                    o_mnsje_tpo     => v_mnsje_tpo,
                                                    o_mnsje         => o_mnsje_rspsta);

        --Validamos si hubo errores al consultar el archivo   
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 8;
            raise v_error;
        end if;

        --Registramos la Evidencia
        pkg_nt_notificacion.prc_rg_evidencia(p_cdgo_clnte                => p_cdgo_clnte,
                                             p_id_mdio                   => v_id_mdio,
                                             p_fcha_ntfccion             => systimestamp,
                                             p_file_blob                 => v_file_blob,
                                             p_file_name                 => substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
                                             p_file_mimetype             => v_file_mimetype,
                                             o_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                             o_cdgo_rspsta               => o_cdgo_rspsta,
                                             o_mnsje_rspsta              => o_mnsje_rspsta);
        if(o_cdgo_rspsta != 0)then
            raise v_error;
        end if;


        --Insertamos en la tabla de evidicencia de presentacion personal o conducta concluyente
        if(p_cdgo_mdio = 'PPN')then
            begin
                insert into nt_g_presentacion_personal(
                    id_ntfcion_mdio_evdncia,
                    cdgo_idntfccion_tpo,
                    nmro_idntfccion,
                    prmer_nmbre,
                    sgndo_nmbre,
                    prmer_aplldo,
                    sgndo_aplldo,
                    cdgo_rspnsble_tpo,
                    nmro_trjeta_prfsnal,
                    cdgo_mncpio
                ) values(
                    v_id_ntfcion_mdio_evdncia,                
                    p_cdgo_idntfccion_tpo,
                    p_nmro_idntfccion,
                    p_prmer_nmbre,
                    p_sgndo_nmbre,
                    p_prmer_aplldo,
                    p_sgndo_aplldo,
                    p_cdgo_rspnsble_tpo,
                    p_nmro_trjeta_prfsnal,
                    p_cdgo_mncpio
                );
            exception
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en presentacion personal, '||SQLERRM;
                    raise v_error;
            end;
        elsif(p_cdgo_mdio = 'CCY')then
            begin
                insert into nt_g_conducta_concluyente(
                    id_ntfcion_mdio_evdncia,
                    fcha_prsntcion,
                    fcha_rgstro
                ) values(
                    v_id_ntfcion_mdio_evdncia,
                    p_fcha_prsntccion,
                    sysdate
                );
            exception
                when others then
                    o_cdgo_rspsta := 11;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en conducta concluyente, '||SQLERRM;
                    raise v_error; 
            end;
        end if;

        --Registramos los responsables al detalle
        pkg_nt_notificacion.prc_rg_notificacion_respnsbles(p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                                                           p_id_acto                   => p_id_acto,
                                                           p_json_rspnsbles            => p_json_rspnsbles,
                                                           p_indca_notfcdo             => 'S',
                                                           p_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                                           p_cdgo_csal                 => v_rt_csal.cdgo_csal,
                                                           o_mnsje_tpo                 => v_mnsje_tpo,
                                                           o_mnsje                     => o_mnsje_rspsta);
        --Validamos si hubo errores al registrar responsables al detalle
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 12;
            raise v_error;
        end if;

    else


        --Registramos la Evidencia
        pkg_nt_notificacion.prc_rg_evidencia(p_cdgo_clnte                => p_cdgo_clnte,
                                             p_id_mdio                   => v_id_mdio,
                                             p_fcha_ntfccion             => systimestamp,
                                             p_file_blob                 => v_file_blob,
                                             p_file_name                 => substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
                                             p_file_mimetype             => v_file_mimetype,
                                             o_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                             o_cdgo_rspsta               => o_cdgo_rspsta,
                                             o_mnsje_rspsta              => o_mnsje_rspsta);
        if(o_cdgo_rspsta != 0)then
            raise v_error;
        end if;

        --Insertamos en la tabla de evidicencia de presentacion personal o conducta concluyente
        if(p_cdgo_mdio = 'PPN')then
            begin
                insert into nt_g_presentacion_personal(
                    id_ntfcion_mdio_evdncia,
                    cdgo_idntfccion_tpo,
                    nmro_idntfccion,
                    prmer_nmbre,
                    sgndo_nmbre,
                    prmer_aplldo,
                    sgndo_aplldo,
                    cdgo_rspnsble_tpo,
                    nmro_trjeta_prfsnal,
                    cdgo_mncpio
                ) values(
                    v_id_ntfcion_mdio_evdncia,                
                    p_cdgo_idntfccion_tpo,
                    p_nmro_idntfccion,
                    p_prmer_nmbre,
                    p_sgndo_nmbre,
                    p_prmer_aplldo,
                    p_sgndo_aplldo,
                    p_cdgo_rspnsble_tpo,
                    p_nmro_trjeta_prfsnal,
                    p_cdgo_mncpio
                );
            exception
                when others then
                    o_cdgo_rspsta := 13;
                    o_cdgo_rspsta := 'Problemas al insertar evidencia en presentacion personal, '||SQLERRM;
                    raise v_error;
            end;
        elsif(p_cdgo_mdio = 'CCY')then
            begin

                insert into nt_g_conducta_concluyente(
                    id_ntfcion_mdio_evdncia,
                    fcha_prsntcion,
                    fcha_rgstro
                ) values(
                    v_id_ntfcion_mdio_evdncia,
                    p_fcha_prsntccion,
                    sysdate
                );
            exception
                when others then
                    o_cdgo_rspsta := 14;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en conducta concluyente, '||SQLERRM;
                    raise v_error; 
            end;
        end if;

        --Actualizamos el estado de la notificacion
        begin


            update nt_g_notificaciones
            set cdgo_estdo = 'NEP'
            where id_ntfccion = p_id_ntfccion;
        exception
            when others then
                o_cdgo_rspsta := 15;
                o_mnsje_rspsta := 'Problemas al actualizar estado de la notificacion Id_ntfccion: '||p_id_ntfccion||' , '||SQLERRM;
                raise v_error; 
        end;

        ---Actualizamos el estado del intento de notificacion
        begin
            update nt_g_notificaciones_detalle
            set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio
            where id_ntfccion_dtlle = v_id_ntfccion_dtlle;
        exception
            when others then
                o_cdgo_rspsta := 16;
                o_mnsje_rspsta := 'Problemas al actualizar estado del intento de notificacion Id_ntfccion_dtlle:'||v_id_ntfccion_dtlle;
                raise v_error;  
        end;


        --Actualizamos los responsables asociandolos con la evidencia creada
        for c_responsables in (select a.*
                              from gn_g_actos_responsable a
                              inner join(select id_acto_rspnsble
                                         from json_table(p_json_rspnsbles,'$[*]'columns id_acto_rspnsble PATH '$.ID_ACTO_RSPNSBLE')) b on a.id_acto_rspnsble = b.id_acto_rspnsble
                              where a.id_acto = p_id_acto and
                                    a.indcdor_ntfccion = 'N')loop

            --Consultamos si se encuentra en los responsables del intento de notificacion
            declare
                v_id_ntfccion_rspnsble number;
            begin

            --  select v_id_ntfccion_rspnsble  
                select id_ntfccion_rspnsble 
                into v_id_ntfccion_rspnsble
                from nt_g_ntfccnes_rspnsble
                where id_ntfccion_dtlle = v_id_ntfccion_dtlle and
                      id_acto_rspnsble  = c_responsables.id_acto_rspnsble and
                      indcdor_ntfcdo    = 'N';
                --Actualizamos el responsable del intento de notificacion
                begin





                    update nt_g_ntfccnes_rspnsble
                    set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia, 
                        indcdor_ntfcdo          = 'S', 
                        fcha_ntfccion           = sysdate, 
                        cdgo_csal               = v_rt_csal.cdgo_csal,
                        id_fncnrio              = p_id_fncnrio
                    where id_ntfccion_rspnsble = v_id_ntfccion_rspnsble;
                exception
                    when others then    
                        o_cdgo_rspsta   := 17;
                        o_mnsje_rspsta  := 'Problemas al actualizar responsable del intento de notifiacion Id_Notificacion_Responsable: '||v_id_ntfccion_rspnsble;
                        raise v_error;
                end;
            exception
                when no_data_found then
                    --Registramos el responsable en el intento de notificacion
                    pkg_nt_notificacion.prc_rg_notificacion_respnsbles(p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                                                                       p_id_acto                   => p_id_acto,
                                                                       p_id_acto_rspnsble          => c_responsables.id_acto_rspnsble,
                                                                       p_indca_notfcdo             => 'S',
                                                                       p_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                                                       p_cdgo_csal                 => v_rt_csal.cdgo_csal,
                                                                       o_mnsje_tpo                 => v_mnsje_tpo,
                                                                       o_mnsje                     => o_mnsje_rspsta);
                    --Validamos si hubo errores al registrar responsables al detalle
                    if(v_mnsje_tpo = 'ERROR')then
                        o_cdgo_rspsta := 18;
                        raise v_error;
                    end if;
            end;
        end loop;
    end if;

  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al registrar notificacion puntual';
        end if ;
    when others then
      o_cdgo_rspsta := 1;
      o_mnsje_rspsta := sqlerrm;
  end prc_rg_notificacion__puntual;

  procedure prc_el_lote(
    p_id_lote    in     number,
    o_mnsje_tpo  out    varchar2,
    o_mnsje      out    varchar2
  ) is
    v_error exception;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_el_lote';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Elimina el detalle del lote
    begin
        delete from nt_d_lote_detalle
        where id_lte = p_id_lote;
    exception
        when others then
            o_mnsje := 'Problemas al eliminar detalle del Lote No. '||p_id_lote;
            raise v_error;
    end;

    --Elimina el lote
    begin
        delete from nt_g_lote
        where id_lte = p_id_lote;
    exception
        when others then
            o_mnsje := 'Problemas al eliminar Lote No. '||p_id_lote;
            raise v_error;   
    end;
  exception 
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_el_lote;

  procedure prc_ac_lote(
    p_id_lote    in     number,
    p_id_fncnrio in     nt_g_lote.id_fncnrio_prcsmnto%type,
    o_mnsje_tpo  out    varchar2,
    o_mnsje      out    varchar2
  ) is
    v_error     exception;
    v_id_entdad_clnte_mdio nt_g_lote.id_entdad_clnte_mdio%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_ac_lote';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Verificamos si el lote tiene actos a procesar
    declare
        v_cntdad_actos number;
    begin
        select count(*)
        into v_cntdad_actos
        from nt_d_lote_detalle
        where id_lte = p_id_lote
        group by id_lte;
    exception
        when no_data_found then
            o_mnsje := 'El lote a confirmar no tiene actos.';
            raise v_error;
    end;

    --Consultamos el ID_ENTDAD_CLNTE_MDIO asociado al lote
    begin
        select id_entdad_clnte_mdio
        into v_id_entdad_clnte_mdio
        from nt_g_lote
        where id_lte = p_id_lote;
    exception
        when others then
            o_mnsje := 'Problemas al consultar Lote';
            raise v_error;
    end;

    --Actualizamos los detalles
    begin
        update nt_g_notificaciones_detalle a
        set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio
        where id_ntfccion_dtlle in (
            select b.id_ntfccion_dtlle  
            from nt_d_lote_detalle a
            inner join v_nt_g_ntfccnes_rspnsble b on a.id_acto_rspnsble = b.id_acto_rspnsble
            where a.id_lte = p_id_lote
            group by b.id_ntfccion_dtlle
        );
    exception
        when others then
            o_mnsje := 'Problemas al actualizar intentos de notificacion';
            raise v_error;   
    end;

    --Actualizamos el estado de los actos del lote en NT_G_NOTIFICACIONES
    begin
        update nt_g_notificaciones
        set cdgo_estdo = 'NEP'
        where id_acto in (select id_acto 
                          from nt_d_lote_detalle
                          where id_lte = p_id_lote
                          group by id_acto);
    exception
        when others then
            o_mnsje := 'Problemas al actualizar notificaciones';
            raise v_error;
    end;

    --Actualizamos el estado del lote
    begin
        update nt_g_lote
        set cdgo_estdo_lte  = 'EPR'
        where id_lte = p_id_lote;
    exception
        when others then
            o_mnsje := 'Problemas al actualizar lote No.'||p_id_lote;
            raise v_error;    
    end;

  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_ac_lote;

  procedure prc_rg_detalle_lotes(
    p_id_lote                   in     number,
    p_id_ntfccion_dtlle_json    in     clob,
    o_mnsje_tpo                 out    varchar2,
    o_mnsje                     out    varchar2
  ) is
    v_error     exception;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_detalle_lotes';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--    
  begin
    insert into nt_d_lote_detalle(
        id_lte_dtlle,
        id_lte,
        id_acto,
        id_acto_rspnsble,
        id_ntfccion_rspnsble
    )select nvl(c.max_id_lte_dtlle, 0 ) + rownum,
           p_id_lote,
           id_acto,
           id_acto_rspnsble,
           id_ntfccion_rspnsble
    from(
        select a.id_acto,
               a.id_acto_rspnsble,
               a.id_ntfccion_rspnsble
        from v_nt_g_ntfccnes_rspnsble a
        inner join (
          Select ID_NTFCCION_DTLLE From json_table(p_id_ntfccion_dtlle_json,'$[*]'columns ID_NTFCCION_DTLLE PATH '$.ID_NTFCCION_DTLLE')  
        ) b on a.id_ntfccion_dtlle = b.id_ntfccion_dtlle
        order by 1,2
    ) a
    left join (
        select max(id_lte_dtlle) as max_id_lte_dtlle
        from nt_d_lote_detalle    
    ) c on c.max_id_lte_dtlle = c.max_id_lte_dtlle;
  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;
  end prc_rg_detalle_lotes;

  procedure prc_rg_notificaciones_actos(p_cdgo_clnte in varchar2,
                                        p_id_acto    in number default null,
                                        p_json_actos in clob default null,
                                        p_id_usrio   in number default null,
                                        p_id_fncnrio in nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type default null,
                                        o_mnsje_tpo  out varchar2,
                                        o_mnsje      out varchar2) is
    v_error exception;
  
    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificaciones_actos';
    v_t_start   number;
    v_t_end     number;
    v_mnsje_tpo varchar2(50);
    v_mnsje     varchar2(400);
    --+---------------------------------+--  
  begin
  
    v_nivel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nivel,
                          'Entrando a ' || v_nmbre_up || ' - ' ||
                          systimestamp,
                          1);
  
    if (p_id_acto is null and p_json_actos is null) then
      o_mnsje := 'No hay acto(s) para notificar por favor verifique el parametro p_id_acto / p_json_actos.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, o_mnsje || systimestamp, 1);
      raise v_error;
    end if;
  
    if (p_id_acto is not null) then
      --Proceso de Notificacion del acto seleccionado
      declare
        v_id_ntfccion       nt_g_notificaciones.id_ntfccion%type;
        v_id_ntfccion_dtlle nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
      begin
      
        --//Consultamos si el acto seleccionado tiene responsables
        declare
          v_cant_responsables number;
        begin
          select count(*)
            into v_cant_responsables
            from gn_g_actos_responsable
           where id_acto = p_id_acto
             and indcdor_ntfccion = 'N';
             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'mirar si hay responsables' || v_cant_responsables ||' '|| systimestamp, 1);
        
          if (v_cant_responsables < 1) then
            pkg_nt_notificacion.prc_ac_actos_responsables(p_cdgo_clnte => p_cdgo_clnte,
                                                          p_id_acto    => p_id_acto,
                                                          o_mnsje_tpo  => o_mnsje_tpo,
                                                          o_mnsje      => o_mnsje);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel,  'entro al if de v_cant_responsables ' ||' '|| systimestamp, 1);
          end if;
          
        end;
      
        if (v_mnsje_tpo = 'ERROR') then
          o_mnsje_tpo := v_mnsje_tpo;
          o_mnsje     := v_mnsje;
          raise v_error;
        end if;
      
        --//Consultamos y/o Insertamos en Notificaciones
        pkg_nt_notificacion.prc_rg_notificaciones(p_cdgo_clnte     => p_cdgo_clnte,
                                                  p_id_ntfccion    => v_id_ntfccion,
                                                  p_id_acto        => p_id_acto,
                                                  p_cdgo_estdo     => 'NGN', --Notificacion Generada
                                                  p_indcdor_ntfcdo => 'N',
                                                  p_id_fncnrio     => p_id_fncnrio,
                                                  o_mnsje_tpo      => o_mnsje_tpo,
                                                  o_mnsje          => o_mnsje);
      
        --Validamos si hubo errores al insertar en 'NT_G_NOTIFICACIONES'
        if (o_mnsje_tpo = 'ERROR') then
          raise v_error;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'entra al if de error' || o_mnsje_tpo ||' '|| systimestamp, 1);
        end if;
      
      end;
    else
      --Recorremos los actos seleccionados
      for c_actos in (select a.id_acto, a.nmro_acto
                        from gn_g_actos a
                        join gn_d_actos_tipo b
                          on a.id_acto_tpo = b.id_acto_tpo
                        join (select id_acto
                               from json_table(p_json_actos,
                                               '$[*]' columns id_acto path
                                               '$.ID_ACTO')) c
                          on a.id_acto = c.id_acto
                        join nt_d_notificaciones_cnfgrcn d
                          on a.cdgo_clnte = d.cdgo_clnte
                       where a.cdgo_clnte = p_cdgo_clnte
                         and p_id_usrio =
                             decode(d.indcdor_prfil_ntfcdor,
                                    'S',
                                    (select id_usrio
                                       from sg_g_perfiles_usuario
                                      where id_prfil = d.id_prfil_ntfca
                                        and id_usrio = p_id_usrio),
                                    'N',
                                    a.id_usrio)
                         and b.indcdor_ntfccion = 'S') loop
       pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'entra al loop que recorre actos', 1);
        --Proceso de Notificacion de los actos seleccionados
        declare
          v_id_ntfccion       nt_g_notificaciones.id_ntfccion%type;
          v_id_ntfccion_dtlle nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
        begin
        
          --//Consultamos si el acto seleccionado tiene responsables
          declare
            v_cant_responsables number;
          begin
            select count(*)
              into v_cant_responsables
              from gn_g_actos_responsable
             where id_acto = c_actos.id_acto
               and indcdor_ntfccion = 'N';
           pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'Consultamos si el acto seleccionado tiene responsables' || v_cant_responsables, 1);
            if (v_cant_responsables < 1) then
              pkg_nt_notificacion.prc_ac_actos_responsables(p_cdgo_clnte => p_cdgo_clnte,
                                                            p_id_acto    => c_actos.id_acto,
                                                            o_mnsje_tpo  => v_mnsje_tpo,
                                                            o_mnsje      => v_mnsje);
            
            end if;
            if (v_mnsje_tpo = 'ERROR') then
              o_mnsje_tpo := v_mnsje_tpo;
              o_mnsje     := v_mnsje;
              raise v_error;
            end if;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nivel,
                                  'Salió de registar los responsables con mensaje: ' ||
                                  o_mnsje,
                                  1);
          end;
        
          --//Consultamos y/o Insertamos en Notificaciones
          pkg_nt_notificacion.prc_rg_notificaciones(p_cdgo_clnte     => p_cdgo_clnte,
                                                    p_id_ntfccion    => v_id_ntfccion,
                                                    p_id_acto        => c_actos.id_acto,
                                                    p_cdgo_estdo     => 'NGN', --Notificacion Generada
                                                    p_indcdor_ntfcdo => 'N',
                                                    p_id_fncnrio     => p_id_fncnrio,
                                                    o_mnsje_tpo      => o_mnsje_tpo,
                                                    o_mnsje          => o_mnsje);
        
          --Validamos si hubo errores al insertar en 'NT_G_NOTIFICACIONES'
          if (o_mnsje_tpo = 'ERROR') then
            raise v_error;
             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'Validamos si hubo errores al insertar en NT_G_NOTIFICACIONES', 1);
          end if;
        
        end;
      end loop;
    end if;
  exception
    when v_error then
      if (o_mnsje is null) then
        o_mnsje := SQLERRM;
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nivel, 'entra a la excepcion' || o_mnsje, 1);
      end if;
      if (o_mnsje_tpo is null) then
        o_mnsje_tpo := 'ERROR';
      end if;
    when others then
      o_mnsje_tpo := 'ERROR';
      o_mnsje     := SQLERRM;
  end prc_rg_notificaciones_actos;


  procedure prc_rg_notificaciones(
    p_id_ntfccion           out     nt_g_notificaciones.id_ntfccion%type,
    p_id_acto               in      number,
    p_cdgo_estdo            in      varchar2,
    p_indcdor_ntfcdo        in      varchar2,
    p_id_fncnrio            in      nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
    p_cdgo_clnte            in      df_s_clientes.cdgo_clnte%type,
    o_mnsje_tpo             out     varchar2,
    o_mnsje                 out     varchar2
  ) is
    v_error             exception;
    v_id_mdio           number;
    v_count_mdios       number;
    v_id_acto           gn_g_actos.id_acto%type;
    v_id_acto_tpo       gn_g_actos.id_acto_tpo%type;
    v_nmro_acto         gn_g_actos.nmro_acto%type;
    v_id_ntfccion_dtlle nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
    v_cdgo_clnte        gn_g_actos.cdgo_clnte%type;
    v_min_orden         number;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificaciones';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--  
  begin
      begin
        --Consultamos si existe en notificaciones el acto
        select nmro_acto,
               id_ntfccion, 
               id_acto, 
               id_acto_tpo,
               cdgo_clnte
        into   v_nmro_acto,
               p_id_ntfccion,
               v_id_acto,
               v_id_acto_tpo,
               v_cdgo_clnte
        from v_nt_g_notfccnes_gn_g_actos
        where id_acto = p_id_acto and
              id_ntfccion is not null;

        --Consultamos si el tipo de acto se encuentra parametrizado en secuencia por tipo de actos
        declare
            v_existe number;
        begin
            select 1
            into v_existe
            from nt_d_acto_medio_orden
            where id_acto_tpo = v_id_acto_tpo
            group by id_acto_tpo;
        exception
            when others then
                o_mnsje_tpo := 'ERROR';
                o_mnsje := 'El tipo de acto, del acto No.'||v_nmro_acto||',Id.'||p_id_acto||', No se encuentra parametrizado en Secuencia Medios x Tipo de Acto';
                raise v_error;
        end;

        begin
            update nt_g_notificaciones
            set cdgo_estdo = 'NGN',
                indcdor_ntfcdo = 'N'
            where id_ntfccion = p_id_ntfccion;
        exception
            when others then
                o_mnsje_tpo := 'ERROR';
                o_mnsje := 'Problemas al Actualizar notificacion del acto No.'||p_id_acto;
                raise v_error;
        end;

        -------------------------------------
        --//Obtenemos el Min orden
        pkg_nt_notificacion.prc_co_min_orden(
            p_id_ntfccion   => p_id_ntfccion,
            o_min_orden     => v_min_orden,
            o_cant_mdios    => v_count_mdios,
            o_mnsje_tpo     => o_mnsje_tpo,
            o_mnsje         => o_mnsje
        );

        if(o_mnsje_tpo = 'ERROR')then
            raise v_error;
        end if;
        -------------------------------------

        for c_medios in (
            select a.id_mdio,
                   a.drcion,
                   a.undad_drcion,
                   a.dia_tpo,
                   a.indcdor_autmtco
            from nt_d_acto_medio_orden a
            inner join nt_d_medio b on a.id_mdio = b.id_mdio
            where a.id_acto_tpo  = v_id_acto_tpo and
                  ((v_count_mdios  > 1 and  a.id_mdio not in (select id_mdio 
                                                              from nt_g_notificaciones_detalle
                                                              where id_ntfccion = p_id_ntfccion)) or (v_count_mdios = 1)) and
                  a.orden = v_min_orden
            order by a.orden asc
        ) loop
            pkg_nt_notificacion.prc_rg_notificacion_detalle(
                p_id_ntfccion_dtlle     => v_id_ntfccion_dtlle,
                p_id_ntfccion           => p_id_ntfccion,
                p_id_mdio               => c_medios.id_mdio,
                p_id_entdad_clnte_mdio  => null,
                p_fcha_gnrcion          => sysdate,
                p_fcha_fin_trmno        => pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => v_cdgo_clnte, 
                                                                                 p_fecha_inicial => systimestamp, 
                                                                                 p_undad_drcion  => c_medios.undad_drcion, 
                                                                                 p_drcion        => c_medios.drcion, 
                                                                                 p_dia_tpo       => c_medios.dia_tpo),
                p_id_fncnrio_gnrcion    => null,
                o_mnsje_tpo             => o_mnsje_tpo,
                o_mnsje                 => o_mnsje
            );

            if(o_mnsje_tpo = 'ERROR')then
                raise v_error;
            end if;

            --Registramos los responsables del detalle
            pkg_nt_notificacion.prc_rg_notificacion_respnsbles(
                p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                p_id_acto                   => v_id_acto,
                p_indca_notfcdo             => c_medios.indcdor_autmtco,
                o_mnsje_tpo                 => o_mnsje_tpo,
                o_mnsje                     => o_mnsje
            );

            if(o_mnsje_tpo = 'ERROR')then
                raise v_error;
            end if;
        end loop;
        ---------------------
      exception
            when no_data_found then

                --Consultamos el Acto
                begin
                    select id_acto_tpo,
                           nmro_acto
                    into v_id_acto_tpo,
                         v_nmro_acto
                    from gn_g_actos 
                    where id_acto = p_id_acto;
                exception
                    when others then
                        o_mnsje := 'Problemas al consultar acto No.'||p_id_acto;
                        raise v_error;  
                end;

                --Consultamos si el tipo de acto se encuentra parametrizado en secuencia por tipo de actos
                declare
                    v_existe number;
                begin
                    select 1
                    into v_existe
                    from nt_d_acto_medio_orden
                    where id_acto_tpo = v_id_acto_tpo
                    group by id_acto_tpo;
                exception
                    when others then
                        o_mnsje_tpo := 'ERROR';
                        o_mnsje := 'El tipo de acto, del acto No.'||v_nmro_acto||' ,Id.'||p_id_acto||', No se encuentra parametrizado en Secuencia Medios x Tipo de Acto';
                        raise v_error;
                end;

                begin
                    insert into nt_g_notificaciones(id_acto, cdgo_estdo, indcdor_ntfcdo) 
                    values(p_id_acto, p_cdgo_estdo, p_indcdor_ntfcdo) returning id_ntfccion into p_id_ntfccion;
                exception
                    when others then
                        o_mnsje_tpo := 'ERROR';
                        o_mnsje := 'Problemas al registrar notificacion del acto No.'||p_id_acto||' , '||SQLERRM;
                        raise v_error;
                end;

                -------------------------------------
                --//Obtenemos el Min orden
                pkg_nt_notificacion.prc_co_min_orden(
                    p_id_ntfccion   => p_id_ntfccion,
                    o_min_orden     => v_min_orden,
                    o_cant_mdios    => v_count_mdios,
                    o_mnsje_tpo     => o_mnsje_tpo,
                    o_mnsje         => o_mnsje
                );

                if(o_mnsje_tpo = 'ERROR')then
                    raise v_error;
                end if;
                -------------------------------------
                for c_medios in (
                    select a.id_mdio,
                           a.drcion,
                           a.undad_drcion,
                           a.dia_tpo,
                           a.indcdor_autmtco
                    from nt_d_acto_medio_orden a
                    inner join nt_d_medio b on a.id_mdio = b.id_mdio
                    where a.id_acto_tpo  = v_id_acto_tpo and
                          ((v_count_mdios  > 1 and  a.id_mdio not in (select id_mdio 
                                                                      from nt_g_notificaciones_detalle
                                                                      where id_ntfccion = p_id_ntfccion)) or (v_count_mdios = 1)) and
                          a.orden = v_min_orden
                    order by a.orden asc
                ) loop
                    pkg_nt_notificacion.prc_rg_notificacion_detalle(
                        p_id_ntfccion_dtlle     => v_id_ntfccion_dtlle,
                        p_id_ntfccion           => p_id_ntfccion,
                        p_id_mdio               => c_medios.id_mdio,
                        p_id_entdad_clnte_mdio  => null,
                        p_fcha_gnrcion          => sysdate,
                        p_fcha_fin_trmno        => pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte, 
                                                                                         p_fecha_inicial => systimestamp, 
                                                                                         p_undad_drcion  => c_medios.undad_drcion, 
                                                                                         p_drcion        => c_medios.drcion, 
                                                                                         p_dia_tpo       => c_medios.dia_tpo),
                        p_id_fncnrio_gnrcion    => p_id_fncnrio,
                        o_mnsje_tpo             => o_mnsje_tpo,
                        o_mnsje                 => o_mnsje
                    );

                    if(o_mnsje_tpo = 'ERROR')then
                        raise v_error;
                    end if; 

                    --Registramos los responsables del detalle
                    pkg_nt_notificacion.prc_rg_notificacion_respnsbles(
                        p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                        p_id_acto                   => p_id_acto,
                        p_indca_notfcdo             => c_medios.indcdor_autmtco,
                        o_mnsje_tpo                 => o_mnsje_tpo,
                        o_mnsje                     => o_mnsje
                    );

                    if(o_mnsje_tpo = 'ERROR')then
                        raise v_error;
                    end if;
                end loop;
      end;
  exception
    when  v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;

  end prc_rg_notificaciones;

  procedure prc_rg_notificacion_detalle(
    p_id_ntfccion_dtlle     out     nt_g_notificaciones_detalle.id_ntfccion_dtlle%type,
    p_id_ntfccion           in      nt_g_notificaciones_detalle.id_ntfccion%type,
    p_id_mdio               in      nt_g_notificaciones_detalle.id_mdio%type,
    p_id_entdad_clnte_mdio  in      nt_g_notificaciones_detalle.id_entdad_clnte_mdio%type,
    p_fcha_gnrcion          in      nt_g_notificaciones_detalle.fcha_gnrcion%type,
    p_fcha_fin_trmno        in      nt_g_notificaciones_detalle.fcha_fin_trmno%type,
    p_id_fncnrio_gnrcion    in      nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
    o_mnsje_tpo             out     varchar2,
    o_mnsje                 out     varchar2
  ) is

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificacion_detalle';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+-- 
  begin
    insert into nt_g_notificaciones_detalle(id_ntfccion, id_mdio, id_entdad_clnte_mdio, fcha_gnrcion, fcha_fin_trmno,id_fncnrio_gnrcion) 
    values(p_id_ntfccion, p_id_mdio, p_id_entdad_clnte_mdio, p_fcha_gnrcion, p_fcha_fin_trmno, p_id_fncnrio_gnrcion) returning id_ntfccion_dtlle into p_id_ntfccion_dtlle;
  exception
    when others then
      o_mnsje_tpo := 'ERROR';
      o_mnsje := 'Problemas al registrar detalle de notificacion';
  end prc_rg_notificacion_detalle;

  procedure prc_rg_notificacion_respnsbles(
    p_id_ntfccion_dtlle         in      nt_g_notificaciones_detalle.id_ntfccion_dtlle%type,
    p_id_acto                   in      gn_g_actos.id_acto%type,
    p_id_acto_rspnsble          in      gn_g_actos_responsable.id_acto_rspnsble%type default null,
    p_json_rspnsbles            in      clob default null,
    p_indca_notfcdo             in      varchar2 default 'N',
    p_id_ntfcion_mdio_evdncia   in      nt_g_ntfccnes_rspnsble.id_ntfcion_mdio_evdncia%type default null,
    p_cdgo_csal                 in      nt_g_ntfccnes_rspnsble.cdgo_csal%type default null,
    o_mnsje_tpo                 out     varchar2,
    o_mnsje                     out     varchar2
  ) is
    v_error exception;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificacion_respnsbles';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+-- 
    v_rt_gn_g_actos             gn_g_actos%rowtype;
  begin
    --Consultamos el acto
    begin
        select *
        into v_rt_gn_g_actos 
        from gn_g_actos
        where id_acto = p_id_acto;
    exception
        when others then
            o_mnsje := 'Problemas al consultar acto, Id.'||p_id_acto;
            raise v_error;
    end;

    --Validamos JSON de Responsables
    if(p_json_rspnsbles is null)then
        for c_actos_responsables in(
            select id_acto_rspnsble, cdgo_idntfccion_tpo, idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,
                   drccion_ntfccion, id_pais_ntfccion, id_dprtmnto_ntfccion, id_mncpio_ntfccion, email, tlfno
            from gn_g_actos_responsable a
            where a.id_acto          = p_id_acto and
                  a.indcdor_ntfccion = 'N' and
                  a.id_acto_rspnsble = nvl(p_id_acto_rspnsble, a.id_acto_rspnsble)
        )loop
        --Valida Campos Obligatorios Notificaciones Responsables
            if(
                c_actos_responsables.cdgo_idntfccion_tpo    is null or
                c_actos_responsables.prmer_nmbre            is null or
                c_actos_responsables.prmer_aplldo           is null or
                c_actos_responsables.drccion_ntfccion       is null or
                c_actos_responsables.id_pais_ntfccion       is null or
                c_actos_responsables.id_dprtmnto_ntfccion   is null or
                c_actos_responsables.id_mncpio_ntfccion     is null
            )then
                o_mnsje := 'Campos Vacios en el responsable con identificacion '||c_actos_responsables.idntfccion||' del acto No. '||v_rt_gn_g_actos.nmro_acto||' , ';
                if(c_actos_responsables.cdgo_idntfccion_tpo is null) then
                    o_mnsje := o_mnsje ||'Tipo de Identificacion, ';
                end if;
                if(c_actos_responsables.prmer_nmbre is null) then
                    o_mnsje := o_mnsje ||'Primer Nombre, ';
                end if;
                if(c_actos_responsables.prmer_aplldo is null) then
                    o_mnsje := o_mnsje ||'Primer Apellido, ';
                end if;
                if(c_actos_responsables.drccion_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Direccion de Notificacion, ';
                end if;
                if(c_actos_responsables.id_pais_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Pais de Notificacion, ';
                end if;
                if(c_actos_responsables.id_dprtmnto_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Departamento, ';
                end if;
                if(c_actos_responsables.id_mncpio_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Municipio, ';
                end if;

                o_mnsje := o_mnsje ||'Por favor verifique!';
                raise v_error;
            end if;
          begin
            insert into nt_g_ntfccnes_rspnsble(
                id_ntfccion_dtlle, 
                id_acto_rspnsble, 
                cdgo_idntfccion_tpo, 
                nmro_idntfccion, 
                prmer_nmbre, 
                sgndo_nmbre, 
                prmer_aplldo, 
                sgndo_aplldo, 
                drccion_ntfccion, 
                id_pais_ntfccion,
                id_dprtmnto_ntfccion,
                id_mncpio_ntfccion,
                email,
                tlfno,
                id_ntfcion_mdio_evdncia,
                indcdor_ntfcdo,
                cdgo_csal,
                fcha_ntfccion
            )values(
                p_id_ntfccion_dtlle,
                c_actos_responsables.id_acto_rspnsble,
                c_actos_responsables.cdgo_idntfccion_tpo,
                c_actos_responsables.idntfccion,
                c_actos_responsables.prmer_nmbre,
                c_actos_responsables.sgndo_nmbre,
                c_actos_responsables.prmer_aplldo,
                c_actos_responsables.sgndo_aplldo,
                c_actos_responsables.drccion_ntfccion,
                c_actos_responsables.id_pais_ntfccion,
                c_actos_responsables.id_dprtmnto_ntfccion,
                c_actos_responsables.id_mncpio_ntfccion,
                c_actos_responsables.email,
                c_actos_responsables.tlfno,
                p_id_ntfcion_mdio_evdncia,
                p_indca_notfcdo,
                p_cdgo_csal,
                case p_indca_notfcdo when 'S' then sysdate end 
            );
          exception
            when others then
                o_mnsje := 'Problemas al registrar responsable Id: '||c_actos_responsables.id_acto_rspnsble||' , '||SQLERRM;
                raise v_error;
          end;
        end loop;
    else
       for c_actos_responsables in(
            select a.id_acto_rspnsble, a.cdgo_idntfccion_tpo, a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,
                   a.drccion_ntfccion, a.id_pais_ntfccion, a.id_dprtmnto_ntfccion, a.id_mncpio_ntfccion, a.email, a.tlfno
            from gn_g_actos_responsable a
            inner join(select id_acto_rspnsble
                       from json_table(p_json_rspnsbles,'$[*]'columns id_acto_rspnsble PATH '$.ID_ACTO_RSPNSBLE')) b on a.id_acto_rspnsble = b.id_acto_rspnsble
            where a.id_acto          = p_id_acto and
                  a.indcdor_ntfccion = 'N'
        )loop
        --Valida Campos Obligatorios Notificaciones Responsables
            if(
                c_actos_responsables.cdgo_idntfccion_tpo    is null or
                c_actos_responsables.prmer_nmbre            is null or
                c_actos_responsables.prmer_aplldo           is null or
                c_actos_responsables.drccion_ntfccion       is null or
                c_actos_responsables.id_pais_ntfccion       is null or
                c_actos_responsables.id_dprtmnto_ntfccion   is null or
                c_actos_responsables.id_mncpio_ntfccion     is null
            )then
                o_mnsje := 'Campos Vacios en el responsable con identificacion '||c_actos_responsables.idntfccion||' del acto No. '||v_rt_gn_g_actos.nmro_acto||' , ';
                if(c_actos_responsables.cdgo_idntfccion_tpo is null) then
                    o_mnsje := o_mnsje ||'Tipo de Identificacion, ';
                end if;
                if(c_actos_responsables.prmer_nmbre is null) then
                    o_mnsje := o_mnsje ||'Primer Nombre, ';
                end if;
                if(c_actos_responsables.prmer_aplldo is null) then
                    o_mnsje := o_mnsje ||'Primer Apellido, ';
                end if;
                if(c_actos_responsables.drccion_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Direccion de Notificacion, ';
                end if;
                if(c_actos_responsables.id_pais_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Pais de Notificacion, ';
                end if;
                if(c_actos_responsables.id_dprtmnto_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Departamento, ';
                end if;
                if(c_actos_responsables.id_mncpio_ntfccion is null) then
                    o_mnsje := o_mnsje ||'Municipio, ';
                end if;

                o_mnsje := o_mnsje ||'Por favor verifique!';
                raise v_error;
            end if;
          begin
            insert into nt_g_ntfccnes_rspnsble(
                id_ntfccion_dtlle, 
                id_acto_rspnsble, 
                cdgo_idntfccion_tpo, 
                nmro_idntfccion, 
                prmer_nmbre, 
                sgndo_nmbre, 
                prmer_aplldo, 
                sgndo_aplldo, 
                drccion_ntfccion, 
                id_pais_ntfccion,
                id_dprtmnto_ntfccion,
                id_mncpio_ntfccion,
                email,
                tlfno,
                id_ntfcion_mdio_evdncia,
                indcdor_ntfcdo,
                cdgo_csal,
                fcha_ntfccion
            )values(
                p_id_ntfccion_dtlle,
                c_actos_responsables.id_acto_rspnsble,
                c_actos_responsables.cdgo_idntfccion_tpo,
                c_actos_responsables.idntfccion,
                c_actos_responsables.prmer_nmbre,
                c_actos_responsables.sgndo_nmbre,
                c_actos_responsables.prmer_aplldo,
                c_actos_responsables.sgndo_aplldo,
                c_actos_responsables.drccion_ntfccion,
                c_actos_responsables.id_pais_ntfccion,
                c_actos_responsables.id_dprtmnto_ntfccion,
                c_actos_responsables.id_mncpio_ntfccion,
                c_actos_responsables.email,
                c_actos_responsables.tlfno,
                p_id_ntfcion_mdio_evdncia,
                p_indca_notfcdo,
                p_cdgo_csal,
                case p_indca_notfcdo when 'S' then sysdate end 
            );
          exception
            when others then
                o_mnsje := 'Problemas al registrar responsable Id: '||c_actos_responsables.id_acto_rspnsble||' , '||SQLERRM;
                raise v_error;
          end;
        end loop; 
    end if;
  exception
    when  v_error then
        if(o_mnsje is null)then
            o_mnsje := SQLERRM;
        end if;
        if(o_mnsje_tpo is null)then
            o_mnsje_tpo := 'ERROR';
        end if;   
  end prc_rg_notificacion_respnsbles;

  procedure pr_co_archivo_evidencia(
    p_file_name     in     varchar2,
    p_file_mimetype	in out varchar2,
    p_file_blob     in out nocopy blob,
    o_mnsje_tpo        out varchar2,
    o_mnsje            out varchar2
  ) is
    v_error exception;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.pr_co_archivo_evidencia';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+-- 

  begin
    select mime_type, blob_content 
    into p_file_mimetype, p_file_blob
    from apex_application_temp_files
    where name = p_file_name;
  exception
    when others then
        o_mnsje_tpo := 'ERROR';
        o_mnsje := 'Problemas al consultar archivo de evidencia'; 
  end pr_co_archivo_evidencia;

  procedure prc_rg_evidencia_puntual(
    p_cdgo_clnte           in   number,
    p_id_entdad_clnte_mdio in   number,
    p_id_ntfccion_rspnsble in   number,
    p_file_evdncia         in   varchar2,
    p_id_fncnrio           in   number,
    p_xml                  in   clob,
    p_id_mdio              in   number,
    o_mnsje                out  varchar2
  ) as
    v_error exception;
    v_msnje_tpo varchar2(50);
    --Evidencia
    v_file_name     varchar2(500);
    v_file_mimetype varchar2(300);
    v_file_blob     blob;
    v_id_ntfcion_mdio_evdncia number;
    --Entidad
    v_cdgo_entdad nt_d_entidad.cdgo_entdad%type;
    v_cdgo_csal nt_d_causales.cdgo_csal%type;
    v_indcdor_ntfcdo varchar2(1);
    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_evidencia_puntual';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Determinamos el nivel del log
    v_nivel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );
    --
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel, 'Entrando ' || systimestamp, 1); 
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel, 'Consultando archivo Subido, ' || systimestamp, 1); 
    --Consultamos el archivo subido
    pkg_nt_notificacion.pr_co_archivo_evidencia(
        p_file_name     => p_file_evdncia,
        p_file_mimetype	=> v_file_mimetype,
        p_file_blob     => v_file_blob,
        o_mnsje_tpo     => v_msnje_tpo,
        o_mnsje         => o_mnsje
    );

    --Validamos si hubo errores al consultar archivo subido
    if(v_msnje_tpo = 'ERROR')then
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel, o_mnsje, 1); 
        raise v_error;
    end if;

    v_file_name := substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 );

    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel, 'Registramos la evidencia,'||systimestamp, 1);
    --Registramos la evidencia
    begin
        insert into nt_g_medio_entidad_evdncia(
            cdgo_clnte,
            id_mdio,
            fcha_ntfccion,
            file_blob,
            file_name,
            file_mimetype
        )values(
            p_cdgo_clnte,
            p_id_mdio,
            systimestamp,
            v_file_blob,
            v_file_name,
            v_file_mimetype
        )  returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
    exception
        when others then
            o_mnsje := 'Problemas al insertar evidencia Id_Mdio: '||p_id_mdio||' , '||SQLERRM;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel, o_mnsje||' ,'||systimestamp, 1);
            raise v_error;  
    end;

    --Segun el medio insertamos en las tablas de medios de notificacion
    if(p_id_mdio = 1)then--Correo Certificado
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nivel,'Inseramos en nt_g_correo_certificado, '||systimestamp, 1);
        begin
            insert into nt_g_correo_certificado(
                id_ntfcion_mdio_evdncia,
                nmro_orden,
                nmro_guia,
                cdgo_csal_entdad,
                nmro_idntfccion,
                nmbre_ntfccion
            )values(
                v_id_ntfcion_mdio_evdncia,
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'nmro_orden'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'nmro_guia'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'cdgo_csal_entdad'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'nmro_idntfccion'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'nmbre_ntfccion')
            );
        exception
            when others then
                o_mnsje := 'Problemas al Registrar Evidencia Correo Certificado, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,o_mnsje, 1);
                raise v_error;
        end;

        --Consultamos la entidad
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,'Consultamos el entidad', 1);
        begin
            select cdgo_entdad
            into v_cdgo_entdad
            from v_nt_d_ntfccion_mdio_entdd
            where cdgo_clnte = p_cdgo_clnte and 
                 id_entdad_clnte_mdio = p_id_entdad_clnte_mdio;
        exception   
            when others then
                o_mnsje := 'Problemas al consultar Entidad, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,o_mnsje, 1);
                raise v_error;
        end;

        --Consultamos la causal
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,'Consultamos la causal', 1);
        begin
            select cdgo_csal
            into v_cdgo_csal
            from nt_d_causales_entidad
            where cdgo_entdad = v_cdgo_entdad and
                 cdgo_csal_entdad =  pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'cdgo_csal_entdad');
        exception
            when others then
                o_mnsje := 'Problemas al consultar Causal, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,'Consultamos si la causal notifica', 1);
        --Consultamos si la causal notifica
        begin
            select indcdor_ntfcdo
            into v_indcdor_ntfcdo
            from nt_d_causales
            where cdgo_csal = v_cdgo_csal;
        exception
            when others then
               o_mnsje := 'Problemas al consultar indicador si notifica al responsable, '||sqlerrm;
               pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
               raise v_error;
        end;

    elsif(p_id_mdio = 3)then--Edicto
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Insertamos en Edicto', 1);
        begin
            v_indcdor_ntfcdo := 'S';
            insert into nt_g_edicto(
                id_ntfcion_mdio_evdncia,
                fcha_incio,
                fcha_fin,
                drcion_dias,
                dia_tpo,
                ubccion,
                fcha_rgstro
            )values(
                v_id_ntfcion_mdio_evdncia,
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_incio'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_fin'),
                trunc(to_date(pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_fin'),'DD-MON-YYYY'))-trunc(to_date(pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_incio'),'DD-MON-YYYY')),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'dia_tpo'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ubccion'),
                systimestamp
            );
        exception   
            when others then
                o_mnsje := 'Problemas al regsitrar edicto, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;
        --Consultamos causal que notifica
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Consultamos la causal que notifica', 1);
        begin
            select cdgo_csal
            into v_cdgo_csal
            from nt_d_causales
            where indcdor_ntfcdo = 'S';
        exception
            when others then
                o_mnsje := 'Problemas al consultar causal que notifica, '||sqlerrm;
                 pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;
    elsif(p_id_mdio = 4)then--Prensa
        v_indcdor_ntfcdo := 'S';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Insertamos en Prensa', 1);
        begin
            insert into nt_g_prensa(
                id_ntfcion_mdio_evdncia,
                ubccion,
                fcha_rgstro
            )values(
                v_id_ntfcion_mdio_evdncia,
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ubccion'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_rgstro')
            );
        exception   
            when others then
                o_mnsje := 'Problemas al registrar en prensa, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;   
        end;
        --Consultamos causal que notifica
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Consultamos la causal que notifica', 1);
        begin
            select cdgo_csal
            into v_cdgo_csal
            from nt_d_causales
            where indcdor_ntfcdo = 'S';
        exception
            when others then
                o_mnsje := 'Problemas al consultar causal que notifica, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;
    elsif(p_id_mdio = 9)then--Gaceta
        v_indcdor_ntfcdo := 'S';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Insertamos en Gaceta', 1);
        begin
            insert into nt_g_gaceta(
                id_ntfcion_mdio_evdncia,
                nmro_gceta,
                fcha_pblccion
            )values(
                v_id_ntfcion_mdio_evdncia,
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'nmro_gceta'),
                pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_pblccion')
            );
        exception
            when others then
                o_mnsje := 'Problemas al registrar en gaceta, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;
        --Consultamos causal que notifica
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Consultamos la causal que notifica', 1);
        begin
            select cdgo_csal
            into v_cdgo_csal
            from nt_d_causales
            where indcdor_ntfcdo = 'S';
        exception
            when others then
                o_mnsje := 'Problemas al consultar causal que notifica, '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, o_mnsje, 1);
                raise v_error;
        end;
    else
       o_mnsje := 'Medio no encontrado';
       raise v_error;
    end if;

    --Actualizamos el Responsable
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, 'Actualizamos el Responsable', 1);
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel, v_id_ntfcion_mdio_evdncia||','||v_indcdor_ntfcdo||','||p_id_fncnrio||','||v_cdgo_csal||','||p_id_ntfccion_rspnsble, 1);

    begin
        update nt_g_ntfccnes_rspnsble
        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia,
            indcdor_ntfcdo = v_indcdor_ntfcdo,
            id_fncnrio = p_id_fncnrio,
            fcha_ntfccion = sysdate,--to_date(pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'fcha_ntfccion'),'DD-MON-YYYY'),
            cdgo_csal = v_cdgo_csal
        where id_ntfccion_rspnsble = p_id_ntfccion_rspnsble;
    exception
        when others then
           o_mnsje := 'Problemas al actualizar responsable de la notificacion, '||sqlerrm;
           pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,o_mnsje, 1);
           raise v_error; 
    end;
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nivel,'Saliendo, '||systimestamp, 1);

  exception
    when v_error then
        if(o_mnsje is null)then
            o_mnsje := sqlerrm;
        end if;
    when others then
        o_mnsje := sqlerrm;
  end prc_rg_evidencia_puntual;

  PROCEDURE prc_rg_evidencia(
                            p_cdgo_clnte             IN NUMBER,
                            p_id_mdio                IN nt_g_medio_entidad_evdncia.id_mdio%TYPE,
                            p_fcha_ntfccion          IN nt_g_medio_entidad_evdncia.fcha_ntfccion%TYPE DEFAULT systimestamp,
                            p_file_blob              IN nt_g_medio_entidad_evdncia.file_blob%TYPE,
                            p_file_name              IN nt_g_medio_entidad_evdncia.file_name%TYPE,
                            p_file_mimetype          IN nt_g_medio_entidad_evdncia.file_mimetype%TYPE,
                            o_id_ntfcion_mdio_evdncia OUT NUMBER,
                            o_cdgo_rspsta            OUT NUMBER,
                            o_mnsje_rspsta           OUT VARCHAR2
                        ) as
    -- Manejo de errores
    v_error exception;
    
    v_directorio             VARCHAR2(20) :='TS_GUIAS'; -- 'TS_NTFCCION';
    v_bfile                  BFILE;
    v_cdgo_rspsta            NUMBER;
    v_mnsje_rspsta           VARCHAR2(32767); -- Aumenta el tamaño máximo permitido para el mensaje
--  v_file_name              nt_g_medio_entidad_evdncia.file_name%type;    

begin

    --Procedimiento para guardar en disco la guia o evidencia 14/05/2024 -Alcaba
    -- Registramos el blob como archivo en disco

    pkg_gd_utilidades.prc_rg_dcmnto_dsco(
                                        p_blob          => p_file_blob,
                                        p_directorio    => v_directorio,
                                        p_nmbre_archvo  => p_file_name,
                                        o_cdgo_rspsta   => v_cdgo_rspsta,
                                        o_mnsje_rspsta  => v_mnsje_rspsta
                                    );
    
    insert into muerto(n_001, v_001, v_002) values(0000, v_cdgo_rspsta, v_mnsje_rspsta); commit;
    
            if v_cdgo_rspsta = 0 then
                -- Actualizo columna bfile
                v_bfile := bfilename(v_directorio, p_file_name); -- Cambia p_file_blob a p_file_name
                

                --v_file_name := 'EVID_'||nvl(p_id_rnta, o_id_rnta)||'_'||v_cdgo_impsto_acto||'_'||c_adjntos.seq_id||'_'||c_adjntos.filename;
                
                o_cdgo_rspsta := 0;
                
                insert into nt_g_medio_entidad_evdncia (
                    cdgo_clnte,
                    id_mdio,
                    fcha_ntfccion,
                    file_name,
                    file_mimetype,
                    file_bfile
                ) values (
                    p_cdgo_clnte,
                    p_id_mdio,
                    p_fcha_ntfccion,
                    p_file_name,
                    p_file_mimetype,
                    v_bfile
                ) returning id_ntfcion_mdio_evdncia INTO o_id_ntfcion_mdio_evdncia;
            ELSE
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'Error al registrar el documento en el disco: ' || v_mnsje_rspsta;
            end if;
    exception
        when v_error then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Problemas al registrar evidencia, ' || SQLERRM;
        when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error inesperado: ' || SQLERRM;
            
end prc_rg_evidencia;

procedure prc_rg_guia_notificacion(p_cdgo_clnte     in number,
                                     p_id_fncnrio     in nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
                                     p_id_usrio       in number,
                                     p_id_prcso_crga  in et_g_procesos_carga.id_prcso_crga%type default null,
                                     p_guias_ntffcion in varchar2 default null,
                                     o_cdgo_rspsta    out number,
                                     o_mnsje_rspsta   out varchar2) as
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);
    v_nmbre_up  varchar2(4000) := 'pkg_nt_notificacion.prc_rg_guia_notificacion';
    v_nvl       number;
    --
    l_file                    apex_application_temp_files%rowtype;
    v_id_mdio                 number;
    v_id_ntfcion_mdio_evdncia number;
    v_cant_detalle_lote       number;
    v_cdgo_mtdo_carga_guias   varchar2(3) := p_guias_ntffcion; -- DFS: direccion fisica del servidor, ATF: apex_application_temp_files
    v_drctrio                 varchar2(20) := 'TS_GUIAS'; --'EVIDENCIAS';
    v_count                   number := 0;
    v_id_lte                  number;
  begin
  
    v_nvl := 1;
  
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, '01 Entrando:' || systimestamp, 1);
  
    --Consultamos el proceso carga
    declare
      v_exist varchar2(1);
    begin
      select 'S'
        into v_exist
        from et_g_procesos_carga a
       where a.id_prcso_crga = p_id_prcso_crga
         and a.indcdor_prcsdo = 'N';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'consulta proceso de carga v_exist:'|| v_exist || systimestamp, 1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - El proceso de carga no se encuentra o ya fue procesado el archivo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' - ' || sqlerrm,
                              1);
        return;
    end;
  
    -- borramos los registros en la tabla de error para ese lote
    
    begin
      delete from nt_g_ntfccnes_guia_error
       where id_lte =(select distinct id_lte
                         from v_nt_g_ntfccion_guia_lte_dtlle
                        where id_prcso_crga = p_id_prcso_crga);
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Borrando errores' || systimestamp, 1);
      commit;
       exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'no se pudo borrar proceso de carga';
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
    end;
    --Recorremos la guia de notificacion
    for c_guia_notificacion in (select id_lte,
                                       id_lte_dtlle,
                                       id_acto_rspnsble,
                                       id_ntfccion_rspnsble,
                                       nmro_guia,
                                       cdgo_csal_entdad,
                                       cdgo_csal,
                                       nmro_idntfccion,
                                       nmbre_ntfccion,
                                       fcha_ntfccion,
                                       indcdor_ntfcdo,
                                       orden_srvcio,
                                       nmbre_evdncia_cmplto
                                  from v_nt_g_ntfccion_guia_lte_dtlle
                                 where id_prcso_crga = p_id_prcso_crga
                                   and cdgo_csal is not null
                                   and indcdor_prcsdo = 'N'
                                    ) loop
    
      v_id_lte := c_guia_notificacion.id_lte;
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'entrando al loop' || p_id_prcso_crga , 1);
      --Actualizamos detalle lote
      begin
        update nt_d_lote_detalle
           set nmro_guia        = c_guia_notificacion.nmro_guia,
               orden_srvcio     = c_guia_notificacion.orden_srvcio,
               cdgo_csal_entdad = c_guia_notificacion.cdgo_csal_entdad,
               nmro_idntfccion  = c_guia_notificacion.nmro_idntfccion,
               nmbre_ntfccion   = c_guia_notificacion.nmbre_ntfccion,
               fcha_ntfccion    = c_guia_notificacion.fcha_ntfccion,
               indcdor_prcsdo   = 'S',
               intntos_prcso    = intntos_prcso + 1
         where id_lte_dtlle = c_guia_notificacion.id_lte_dtlle;
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'actualiza nt_d_lote_Detalle'  , 1);
      exception
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Problemas al actualizar detalle del lote id: ' ||
                            c_guia_notificacion.id_lte_dtlle;
          rollback;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
      --Consultamos el responsable
      begin
        select id_mdio
          into v_id_mdio
          from v_nt_g_ntfccnes_rspnsble
         where id_ntfccion_rspnsble =
               c_guia_notificacion.id_ntfccion_rspnsble
           and indcdor_ntfcdo = 'N';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Consulta medio responsable ' || v_id_mdio || systimestamp, 1);
      exception
        when no_data_found then
          continue;
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - v_id_mdio:' ||
                            c_guia_notificacion.id_ntfccion_rspnsble;
          rollback;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
        
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
        
      end;
      -- validamos si las guias fueron cargadas por el aplicativo 
      if v_cdgo_mtdo_carga_guias = 'ATF' then
      
        pkg_gn_generalidades.prc_co_archivo_apex_temp_file(p_nmbre_archvo  => c_guia_notificacion.nmbre_evdncia_cmplto,
                                                           o_file_blob     => l_file.blob_content,
                                                           o_file_name     => l_file.filename,
                                                           o_file_mimetype => l_file.mime_type,
                                                           o_cdgo_rspsta   => o_cdgo_rspsta,
                                                           o_mnsje_rspsta  => o_mnsje_rspsta);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'guias cargadas AFT ' || o_mnsje_rspsta, 1);
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          
          rollback;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp || 'AFT', 1);
        
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
        end if;
        -- Validamos si fueron cargadas al servidor          
      elsif v_cdgo_mtdo_carga_guias = 'DFS' then
        pkg_gn_generalidades.prc_co_archivo_disco_servidor(p_drctrio       => v_drctrio,
                                                           p_nmbre_archvo  => c_guia_notificacion.nmbre_evdncia_cmplto,
                                                           o_file_blob     => l_file.blob_content,
                                                           o_file_name     => l_file.filename,
                                                           o_file_mimetype => l_file.mime_type,
                                                           o_cdgo_rspsta   => o_cdgo_rspsta,
                                                           o_mnsje_rspsta  => o_mnsje_rspsta);
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp || 'DFS', 1);
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          rollback;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
        
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
        end if;
        -- temporal para el cargue de las determinaciones 2020 que estan en .tiff
        if l_file.mime_type is null then
          l_file.filename  := c_guia_notificacion.nmbre_evdncia_cmplto;
          l_file.mime_type := 'image/tiff';
        end if;
        -- validamos si no fueron cargadas      
      elsif v_cdgo_mtdo_carga_guias = 'NCG' then
        l_file := null;
      end if;
    
      --Insertamos en la tabla de evidencia 'NT_G_MEDIO_ENTIDAD_EVDNCIA' Validar Alcaba FILE_BFILE
      begin
        insert into nt_g_medio_entidad_evdncia
          (cdgo_clnte,
           id_mdio,
           file_blob,
           file_name,
           file_mimetype,
           fcha_ntfccion)
        values
          (p_cdgo_clnte,
           v_id_mdio,
           l_file.blob_content,
           l_file.filename,
           l_file.mime_type,
           systimestamp)
        returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto en nt_g_medio_entidad_evdncia' || systimestamp, 1);
      exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Problemas al registrar evidencia, ';
          rollback;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
        
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
      end;
    
      --Insertamos en la tabla de correo certificado 'NT_G_CORREO_CERTIFICADO'
      begin
        insert into nt_g_correo_certificado
          (id_ntfcion_mdio_evdncia,
           nmro_orden,
           nmro_guia,
           cdgo_csal_entdad,
           nmro_idntfccion,
           nmbre_ntfccion)
        values
          (v_id_ntfcion_mdio_evdncia,
           c_guia_notificacion.orden_srvcio,
           c_guia_notificacion.nmro_guia,
           c_guia_notificacion.cdgo_csal_entdad,
           c_guia_notificacion.nmro_idntfccion,
           c_guia_notificacion.nmbre_ntfccion);
           
           pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'inserto en nt_g_correo_certificado' || systimestamp, 1);
      exception
        when others then
          o_cdgo_rspsta  := 70;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Problemas al registrar evidencia correo certificado, ';
          rollback;
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
      end;
    
      --Actualizamos los responsables
      begin
        update nt_g_ntfccnes_rspnsble
           set id_fncnrio              = p_id_fncnrio,
               fcha_ntfccion           = c_guia_notificacion.fcha_ntfccion,
               indcdor_ntfcdo          = c_guia_notificacion.indcdor_ntfcdo,
               cdgo_csal               = c_guia_notificacion.cdgo_csal,
               id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia
         where id_ntfccion_rspnsble =
               c_guia_notificacion.id_ntfccion_rspnsble;
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Actualiza responsables' || systimestamp, 1);
      exception
        when others then
          o_cdgo_rspsta  := 80;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Problemas al actualizar responsable id:' ||
                            c_guia_notificacion.id_ntfccion_rspnsble;
          rollback;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
      end;
    
      --Consultamos si todos los responsables ya han sido notificados
      begin
        select count(a.id_lte_dtlle)
          into v_cant_detalle_lote
          from v_nt_g_ntfccion_guia_lte_dtlle a
         where a.id_lte = c_guia_notificacion.id_lte
           and a.indcdor_prcsdo = 'N';
         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Consultamos si todos los responsables ya han sido notificados' || systimestamp, 1);
      exception
        when others then
          o_cdgo_rspsta  := 90;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Problemas al consultar si se procesa el lote id_lote: ' ||
                            c_guia_notificacion.id_lte;
          rollback;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
          -- registramos el error
          prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                     p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                     p_mnsje_error  => o_mnsje_rspsta,
                                     p_id_usrio     => p_id_usrio,
                                     o_cdgo_rspsta  => o_cdgo_rspsta,
                                     o_mnsje_rspsta => o_mnsje_rspsta);
        
          continue;
      end;
      if (v_cant_detalle_lote < 1) then
        --Actualizamos el estado del lote
        begin
          update nt_g_lote
             set cdgo_estdo_lte      = 'PRO',
                 fcha_prcsmnto       = systimestamp,
                 id_fncnrio_prcsmnto = p_id_fncnrio
           where id_lte = c_guia_notificacion.id_lte;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Actualiza estado del lote' || p_id_fncnrio, 1);
        exception
          when others then
            o_cdgo_rspsta  := 100;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' - Problemas al actualizar el lote id_lote: ' ||
                              c_guia_notificacion.id_lte;
        
            rollback;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
            -- registramos el error
            prc_rg_ntfccnes_guia_error(p_id_lte       => c_guia_notificacion.id_lte,
                                       p_id_lte_dtlle => c_guia_notificacion.id_lte_dtlle,
                                       p_mnsje_error  => o_mnsje_rspsta,
                                       p_id_usrio     => p_id_usrio,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
          
            continue;
        end;
      end if;
    
      commit;
    end loop;
   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Saliendo del loop' || systimestamp, 1);
    --Actualizamos el estado del proceso de carga
    begin
      -- consultamos si faltaron por procesar registros
      select count(*)
        into v_count
        from v_nt_g_ntfccion_guia_lte_dtlle
       where id_lte = v_id_lte
         and indcdor_prcsdo = 'N';
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'consulta registros por procesar' || v_count, 1);
      -- si todos fueron procesados marcamos el proceso carga como procesado
      if v_count = 0 then
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Actualiza proceso de carga a S' || p_id_prcso_crga, 1);
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 110;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Problemas al actualizar proceso de carga id: ' ||
                          p_id_prcso_crga;
        rollback;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
        return;
    end;
  
    commit;
  
    -- se envia el correo con las estadisticas del proceso
    if v_cdgo_mtdo_carga_guias != 'ATF' then
      begin
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'FinProcesoRegistraGuiasNotificacion',
                                              p_json_prmtros => json_object('p_id_lte'
                                                                            value
                                                                            v_id_lte,
                                                                            'p_id_usrio'
                                                                            value
                                                                            p_id_usrio,
                                                                            'p_cdgo_clnte'
                                                                            value
                                                                            p_cdgo_clnte));
      end;
    end if;
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 120;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        ' - Problemas al procesar guia de notificacion';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta || systimestamp, 1);
  end prc_rg_guia_notificacion;

  procedure prc_ac_guias_notificacion(p_cdgo_clnte      in number,
                                      p_collection_name in varchar2,
                                      o_cdgo_rspsta     out number,
                                      o_mnsje_rspsta    out varchar2) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);
    v_nvl       number;
    --
    v_directorio             varchar2(20) :='TS_GUIAS'; -- 'TS_NTFCCION';
    v_bfile                  bfile;
    v_id_ntfcion_mdio_evdncia       number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_nt_notificacion.prc_ac_guias_notificacion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_nt_notificacion.prc_ac_guias_notificacion',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    /*Recorremos la coleccion para guardar las guias*/
  
    --c004: Numero de Guia
    --c002: Nombre del archivo
    --c003: MimeType
    --blob001: Archivo
  
    
    for c_guias in (select a.id_ntfcion_mdio_evdncia,
                           a.nmro_guia,
                           a.id_crreo_certificado,
                           c.c004,
                           c.c002,
                           c.c003,
                           c.blob001
                      from nt_g_correo_certificado a
                     inner join nt_g_medio_entidad_evdncia b
                        on a.id_ntfcion_mdio_evdncia =
                           b.id_ntfcion_mdio_evdncia
                     inner join apex_collections c
                        on a.nmro_guia = c.c004
                       and c.collection_name = p_collection_name
                     where b.cdgo_clnte = p_cdgo_clnte
                       and ( b.file_blob is  null and  b.file_bfile is null)) loop

      begin
        /*
            Se llama el  precedimiento pkg_gd_utilidades.prc_rg_dcmnto_dsco para guardar la guia en disco.
        */
         pkg_gd_utilidades.prc_rg_dcmnto_dsco(  p_blob          => c_guias.blob001,
                                                p_directorio    => v_directorio,
                                                p_nmbre_archvo  => c_guias.c002,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta );
									
			 o_mnsje_rspsta := o_cdgo_rspsta || '-'||o_mnsje_rspsta;
    	     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,'pkg_nt_notificacion.prc_ac_guias_notificacion',v_nl, o_mnsje_rspsta || systimestamp,6);
             
     exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Problemas al intentar guardar la guía en el servidor. ' ||
                            c_guias.nmro_guia || ', ' || sqlerrm;
          v_mnsje_log    := o_mnsje_rspsta || ' , ' || sqlerrm;
          v_nvl          := 1;
          raise v_error;
      end;
      
      /*Actualizamos el campo file_bfile, para poder consultar la guia guardada*/
      begin
        v_bfile := bfilename(v_directorio, c_guias.c002); -- Cambia p_file_blob a p_file_name
        update nt_g_medio_entidad_evdncia        
           set file_name     = c_guias.c002,
               file_mimetype = c_guias.c003,
               file_bfile = v_bfile
         where id_ntfcion_mdio_evdncia = c_guias.id_ntfcion_mdio_evdncia;
         
         -- linea de prueba vanessa
         update nt_g_ntfccnes_rspnsble 
         set indcdor_ntfcdo='S', 
         fcha_ntfccion = sysdate 
         where id_ntfcion_mdio_evdncia = c_guias.id_ntfcion_mdio_evdncia;          
         commit;
         
         
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Problemas al actualizar evidencia asociada a la guia No. ' ||
                            c_guias.nmro_guia || ', ' || sqlerrm;
          v_mnsje_log    := o_mnsje_rspsta || ' , ' || sqlerrm;
          v_nvl          := 1;
          raise v_error;
      end;
    end loop;
    
      if (o_cdgo_rspsta != 0) then
        raise v_error;
      end if;
  exception
    when v_error then
      if (o_mnsje_rspsta is null or o_cdgo_rspsta is null) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al procesar guia de notificacion';
      end if;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_nt_notificacion.prc_ac_guias_notificacion',
                            v_nl,
                            o_cdgo_rspsta || ' - ' || v_mnsje_log,
                            v_nvl);
    when others then
      if (o_mnsje_rspsta is null or o_cdgo_rspsta is null) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al procesar guia de notificacion';
      end if;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_nt_notificacion.prc_ac_guias_notificacion',
                            v_nl,
                            o_cdgo_rspsta || ' - ' || sqlerrm,
                            v_nvl);
  end prc_ac_guias_notificacion;
/********************* Procedimiento Notificacion de Actos Automaticamente prc_rg_notfccion_gnrda_atmtca   (No es exclusivo de Actos q esten asociados al usuario del sistema )  ****************************************/

 procedure prc_rg_notfccion_gnrda_atmtca  
   as
    v_mnsje_tpo 	   varchar2(20);
    v_mnsje_rspsta     varchar2(3200);

 /*v_cdgo_rspsta	                    number;
   v_mnsje_rspsta	                    varchar2(4000);   */
    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notfccion_gnrda_atmtca';
    v_t_start   number;
    v_t_end     number;
    --+---------------------------------+--
  begin
    --Recorremos los actos que tienen asociado el acto que viene por parametros como requerido
    for c_actos in (
        select *
        from v_nt_g_notfccnes_gn_g_actos
        where  indcdr_ntfccion_atmtca ='S'	
    )loop
        declare
          v_id_ntfccion         nt_g_notificaciones.id_ntfccion%type;
          v_id_ntfccion_dtlle   nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;
          v_error               exception;
        begin

            --//Consultamos si el acto seleccionado tiene responsables
            declare
                v_cant_responsables number;
            begin
                select count(*)
                into v_cant_responsables
                from gn_g_actos_responsable
                where id_acto = c_actos.id_acto;

                if(v_cant_responsables < 1)then
                  v_mnsje_rspsta := v_mnsje_rspsta ||' El acto No. '||c_actos.nmro_acto||' no tiene responsables por favor verifique..!!';
                   raise v_error; 
                end if;
            end;

            --//Consultamos y/o Insertamos en Notificaciones
            pkg_nt_notificacion.prc_rg_notificaciones(
                p_cdgo_clnte        => c_actos.cdgo_clnte,
                p_id_ntfccion       => v_id_ntfccion,
                p_id_acto           => c_actos.id_acto,
                p_cdgo_estdo        => 'NGN',--Notificacion Generada
                p_indcdor_ntfcdo    => 'N',
                p_id_fncnrio        => null,
                o_mnsje_tpo         => v_mnsje_tpo,
                o_mnsje             => v_mnsje_rspsta
            );

            --Validamos si hubo errores al insertar en 'NT_G_NOTIFICACIONES'
            if(v_mnsje_tpo = 'ERROR')then
                raise v_error;
            end if;

        exception
            when v_error then
               continue;
        end;
    end loop;
  end prc_rg_notfccion_gnrda_atmtca; 
/***  end prc_rg_notfccion_gnrda_atmtca  **/

 procedure prc_rg_notificaciones_email(p_cdgo_clnte    in number,
                                    p_id_lte        in number,  
                                    o_cdgo_rspsta   out number,
                                    o_mnsje_rspsta  out varchar2) as

    v_json_parametros clob;                                       
	v_nl                    	number;
	v_nmbre_up              	varchar2(70) := 'pkg_nt_notificacion.prc_rg_notificaciones_email';
    
  begin
   
    -- codigo de respesta exitoso
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';
    
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'Entrando',1);

    for c_notificar in ( select distinct b.id_acto, a.id_lte, e.id_sjto_impsto, f.id_envio_prgrmdo, f.idntfcdor
                          from v_nt_d_lote_detalle              a
                              join v_nt_g_notfccnes_gn_g_actos  b on a.id_acto = b.id_acto 
                              join gn_g_actos_sujeto_impuesto   d on d.id_acto = a.id_acto     
                              join si_i_sujetos_impuesto        e on e.id_sjto_impsto = d.id_sjto_impsto
                                                                     and email is not null  
                              join v_nt_d_acto_medio_orden      f on f.id_acto_tpo = a.id_acto_tpo 
                                                                    and upper(cdgo_mdio) = 'CEL'  
                            where a.id_lte = p_id_lte 
       ) loop

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'c_notificar.idntfcdor: '||c_notificar.idntfcdor,1);

            if c_notificar.idntfcdor is not null then
            
                select json_object(key 'P_ID_LOTE' is c_notificar.id_lte,  --9274587
                                   key 'P_ID_ACTO' is c_notificar.id_acto)  --48
                into v_json_parametros                       
                from dual;
                
               --DBMS_OUTPUT.PUT_LINE('v_json_parametros'||v_json_parametros);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'v_json_parametros: '||v_json_parametros,1);
               
               begin
                    --Consultamos los envios programados
                    pkg_ma_envios.prc_co_envio_programado( p_cdgo_clnte     => p_cdgo_clnte
                                                         , p_idntfcdor      => c_notificar.idntfcdor
                                                         , p_json_prmtros   => v_json_parametros
                                                         , p_id_sjto_impsto => c_notificar.id_sjto_impsto
                                                         , p_id_acto        => c_notificar.id_acto
                                                        );    
                    o_mnsje_rspsta  := 'Envios programados, ' || v_json_parametros;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'1 msg respuesta prc_co_envio_programado: '|| o_mnsje_rspsta, 1);                                                    
                                                      
                exception
                    when others then
                        o_cdgo_rspsta := 20;
                        o_mnsje_rspsta  := 'o_cdgo_rspsta: ' || o_cdgo_rspsta || ': Error en los envios programados de notificaciones ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'2 msg respuesta prc_co_envio_programado: '|| o_mnsje_rspsta, 1); 
                        rollback;
                        return;        
                end; --Fin Consultamos los envios programados
            else
                o_cdgo_rspsta := 30;
                o_mnsje_rspsta  := 'o_cdgo_rspsta: ' || o_cdgo_rspsta || ': No se encontro el identificador del envio programado ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'3 msg respuesta prc_co_envio_programado: '|| o_mnsje_rspsta, 1); 
                rollback;
                return;    
            end if;
        end loop;
 
        o_mnsje_rspsta  := 'Correo enviado exitosamente';
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Problemas al enviar las notificaciones por mail para el id_lote, ' ||p_id_lte  || ' - ' || SQLERRM;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'4 msg respuesta prc_co_envio_programado: '|| o_mnsje_rspsta, 1); 
  end prc_rg_notificaciones_email;

  procedure prc_rg_notificacion_puntual(
    p_cdgo_clnte			in  number,
    p_id_acto               in  number,
    p_id_ntfccion           in  nt_g_notificaciones.id_ntfccion%type,
    p_json_rspnsbles        in  clob,
    p_cdgo_rspnsble_tpo     in df_s_responsables_tipo.cdgo_rspnsble_tpo%type        default null, 
    p_cdgo_idntfccion_tpo   in df_s_identificaciones_tipo.cdgo_idntfccion_tpo%type  default null,
    p_nmro_idntfccion       in nt_g_presentacion_personal.nmro_idntfccion%type      default null,
    p_cdgo_mncpio           in  varchar2                                            default null,
    p_nmro_trjeta_prfsnal   in  varchar2                                            default null,
    p_prmer_nmbre           in  varchar2                                            default null,
    p_sgndo_nmbre           in  varchar2                                            default null,
    p_prmer_aplldo          in  varchar2                                            default null,
    p_sgndo_aplldo          in  varchar2                                            default null,
    p_file_evdncia          in  varchar2,
    p_fcha_prsntccion       in  timestamp                                           default null,
    p_id_fncnrio            in  number,
    p_cdgo_mdio             in  varchar2,
    p_indcdor_envia_email   in varchar2 default 'N',
    o_cdgo_rspsta			out number,
    o_mnsje_rspsta          out varchar2
  ) is
    --Manejo de errores en el proceso de notificación
    v_error                     exception;
    v_mnsje_tpo                 varchar2(20);

    --------------------------------

    --Información del acto seleccionado
    v_id_acto_tpo             gn_g_actos.id_acto_tpo%type;
    --------------------------------

    --Vigencia Notificación
    v_undad_drcion              nt_d_acto_medio_orden.undad_drcion%type; 
    v_dia_tpo                   nt_d_acto_medio_orden.dia_tpo%type;
    v_drcion                    nt_d_acto_medio_orden.drcion%type;
    --------------------------------

    --Variables para el intento de notificación
    v_id_entdad_clnte_mdio      nt_d_entidad_cliente_medio.id_entdad_clnte_mdio%type;
    v_id_mdio                   nt_d_entidad_cliente_medio.id_mdio%type;
    v_rt_csal                   nt_d_causales%rowtype;
    v_fcha_fin                  date;
    --------------------------------

    v_id_ntfccion_dtlle         nt_g_notificaciones_detalle.id_ntfccion_dtlle%type;

    v_id_ntfcion_mdio_evdncia   nt_g_medio_entidad_evdncia.id_ntfcion_mdio_evdncia%type;
    v_rspnsble                  nt_g_ntfccnes_rspnsble%rowtype;
    v_file_blob                 blob;
    v_file_mimetype             nt_g_medio_entidad_evdncia.file_mimetype%type;

    --+---------------------------------+--
    --|---------------Log---------------|--
    --+---------------------------------+--
    v_nivel     number;
    v_nl        number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_rg_notificacion_puntual';
    v_t_start   number;
    v_t_end     number;
    v_cdgo_csal nt_d_causales.cdgo_csal%type;    
    --+---------------------------------+--
  begin
  
   v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando Notificacion Puntual ' || systimestamp, 1);
   
    -- codigo de respesta exitoso
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';
    
    
    o_cdgo_rspsta := 0;
    --Consultamos el acto a notificar
    begin
        select id_acto_tpo, file_blob
        into v_id_acto_tpo, v_file_blob
        from v_gn_g_actos
        where id_acto = p_id_acto;
    exception
        when others then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al consultar el acto seleccionado Id_Acto: '||p_id_acto;
            raise v_error;
    end;
 
        if  p_cdgo_mdio   = 'CEL' 
       and v_file_blob is null then
        o_cdgo_rspsta   := 5;
        o_mnsje_rspsta  := 'No se puede realizar la notificación por Email por que el acto no tiene el Archivo Blob generado: '||p_id_acto; 
        raise v_error;
    end if;  
    
  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Consultamos el acto a notificar: :'||v_id_acto_tpo, 1);
/*
 delete muerto;
  insert into muerto (c_001)values ('Entrando '||
		   '	p_cdgo_clnte        ' ||p_cdgo_clnte      ||
           '	p_id_acto           ' ||p_id_acto         ||
           '	p_id_ntfccion       ' ||p_id_ntfccion     ||
           '	p_fcha_prsntccion   ' ||p_fcha_prsntccion ||
           '	p_json_rspnsbles    ' ||p_json_rspnsbles  ||
           '	p_id_fncnrio        ' ||p_id_fncnrio      ||
           '	p_file_evdncia      ' ||p_file_evdncia    ||
           '	p_cdgo_mdio         ' ||p_cdgo_mdio       ||
           '	o_cdgo_rspsta       ' ||o_cdgo_rspsta     ||
           '	o_mnsje_rspsta      ' ||o_mnsje_rspsta    
);commit;*/



    --Validamos si el acto a notificar tiene responsables pendientes por notificar
    declare
        v_responsables varchar2(1);
    begin
        select case when count(a.id_acto_rspnsble) > 0 then 'S'
                    when count(a.id_acto_rspnsble) < 1 then 'N'
               end 
        into v_responsables
        from gn_g_actos_responsable a
        where a.id_acto          = p_id_acto and
              a.indcdor_ntfccion = 'N';
        if(v_responsables = 'N')then
            o_cdgo_rspsta   := 2;
            o_mnsje_rspsta  := 'El acto a notificar no tiene responsables pendientes por notificar por favor verifique, Id_Acto: '||p_id_acto;
            raise v_error;
        end if;
    end;
  
    --Consultamos el medio y la entidad cliente
    begin
        select id_entdad_clnte_mdio,id_mdio 
        into v_id_entdad_clnte_mdio,v_id_mdio
        from v_nt_d_ntfccion_mdio_entdd
        where cdgo_clnte    = p_cdgo_clnte and
              cdgo_mdio     = p_cdgo_mdio;
    exception
        when others then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := 'Problemas al consultar medio de notificación puntual: '||p_cdgo_mdio||', '||SQLERRM;
            raise v_error;
    end;
   
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_entdad_clnte_mdio :'||v_id_entdad_clnte_mdio, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_mdio :'||v_id_mdio, 1);
    
    --Alcaba **Causal**
    if p_cdgo_mdio = 'PPN' then
      v_cdgo_csal := 'NOT';
    elsif p_cdgo_mdio = 'CEL' then
      v_cdgo_csal := 'CEL';
    elsif p_cdgo_mdio = 'PWE' then
      v_cdgo_csal := 'PWE';
    elsif p_cdgo_mdio = 'CCY' then
      v_cdgo_csal := 'NOT';
    end if;
  
    --Alcaba **Causal 
    --Consultamos causal que da por notificado
    begin
        select *
        into v_rt_csal
        from nt_d_causales
        where indcdor_ntfcdo = 'S'
        and cdgo_csal = v_cdgo_csal;
    exception
        when others then
            o_cdgo_rspsta := 4;
            o_mnsje_rspsta := 'Problemas al consultar causal para notificar, '||SQLERRM;
            raise v_error;    
    end;

    --Consultamos termino de tiempo para la notificación personal
    begin
        select undad_drcion, 
               dia_tpo, 
               drcion
        into v_undad_drcion, 
             v_dia_tpo, 
             v_drcion
        from nt_d_acto_medio_orden
        where id_acto_tpo   = v_id_acto_tpo and
              id_mdio       = v_id_mdio;
    exception
        when no_data_found then
           v_undad_drcion   := null;
           v_dia_tpo        := null;
           v_drcion         := null;
        when others then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := 'Problemas al consultar termino de tiempo para la notificación puntual: '||p_cdgo_mdio||', id_acto_tpo: '||v_id_acto_tpo||' , '||SQLERRM;
            raise v_error; 
    end;

    --Consultamos si existe el intento de notificación
    begin
        select id_ntfccion_dtlle
        into v_id_ntfccion_dtlle
        from v_nt_g_notificaciones_detalle
        where id_acto = p_id_acto and
              id_mdio = v_id_mdio
          and  rownum = 1; -- Linea agregada por michael rodriguez el enero/05/2022
    exception   
        when no_data_found then
            null;
        when others then
            o_cdgo_rspsta := 6;
            o_mnsje_rspsta := 'Problemas al consultar el intento de notificacion para el acto Id_Acto: '||p_id_acto||' Id_Medio: '||v_id_mdio;
            raise v_error; 
    end;
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_ntfccion_dtlle :'||v_id_ntfccion_dtlle, 1);
    
    
    --Validamos si existe el intento de notificación
    if(v_id_ntfccion_dtlle is null)then



        if(v_dia_tpo is not null and v_drcion is not null)then
            v_fcha_fin := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte, 
                                                                p_fecha_inicial => systimestamp, 
                                                                p_undad_drcion  => v_undad_drcion, 
                                                                p_drcion        => v_drcion, 
                                                                p_dia_tpo       => v_dia_tpo);

        end if;
        --Registramos el intento de notificación
        pkg_nt_notificacion.prc_rg_notificacion_detalle(p_id_ntfccion_dtlle     => v_id_ntfccion_dtlle,
                                                        p_id_ntfccion           => p_id_ntfccion,
                                                        p_id_mdio               => v_id_mdio,
                                                        p_id_entdad_clnte_mdio  => v_id_entdad_clnte_mdio,
                                                        p_fcha_gnrcion          => sysdate,
                                                        p_fcha_fin_trmno        => v_fcha_fin,
                                                        p_id_fncnrio_gnrcion    => p_id_fncnrio,
                                                        o_mnsje_tpo             => v_mnsje_tpo,
                                                        o_mnsje                 => o_mnsje_rspsta);

        --Validamos si hubo errores al registrar el intento de notificacion
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 7;
            raise v_error;
        end if;
        --Obtenemos el archivo subido
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'pr_co_archivo_evidencia v_id_ntfccion_dtlle is null v_file_mimetype :'||v_file_mimetype, 1);
 
        pkg_nt_notificacion.pr_co_archivo_evidencia(p_file_name     => p_file_evdncia,
                                                    p_file_mimetype	=> v_file_mimetype,
                                                    p_file_blob     => v_file_blob,
                                                    o_mnsje_tpo     => v_mnsje_tpo,
                                                    o_mnsje         => o_mnsje_rspsta);

        --Validamos si hubo errores al consultar el archivo   
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 8;
            raise v_error;
        end if;

        --Registramos la Evidencia
        pkg_nt_notificacion.prc_rg_evidencia(p_cdgo_clnte                => p_cdgo_clnte,
                                             p_id_mdio                   => v_id_mdio,
                                             p_fcha_ntfccion             => systimestamp,
                                             p_file_blob                 => v_file_blob,
                                             p_file_name                 => substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
                                             p_file_mimetype             => v_file_mimetype,
                                             o_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                             o_cdgo_rspsta               => o_cdgo_rspsta,
                                             o_mnsje_rspsta              => o_mnsje_rspsta);
        if(o_cdgo_rspsta != 0)then
            raise v_error;
        end if;


        --Registramos los responsables al detalle
        pkg_nt_notificacion.prc_rg_notificacion_respnsbles(p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                                                           p_id_acto                   => p_id_acto,
                                                           p_json_rspnsbles            => p_json_rspnsbles,
                                                                                        -- cuando el medio de notifiacion en correo electronico
                                                                                        -- y no va a enviar el correo, debe quedar notificado automaticamente,
                                                                                        -- en cambio, si se va a enviar el correo por MAILJET debe esperar
                                                                                        -- a que el proveedor de respuesta de si se pudo o no enviar el correo electronico
                                                           p_indca_notfcdo             =>  (case
                                                                                                when p_indcdor_envia_email = 'S' then
                                                                                                    'N'
                                                                                                else
                                                                                                    'S'
                                                                                                end), --'S',
                                                           p_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                                           p_cdgo_csal                 => v_rt_csal.cdgo_csal,
                                                           o_mnsje_tpo                 => v_mnsje_tpo,
                                                           o_mnsje                     => o_mnsje_rspsta);
        --Validamos si hubo errores al registrar responsables al detalle
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 12;
            raise v_error;
        end if;
        
        --Insertamos en la tabla de evidicencia de presentacion personal o conducta concluyente
        if(p_cdgo_mdio = 'PPN')then
            begin
                insert into nt_g_presentacion_personal(
                    id_ntfcion_mdio_evdncia,
                    cdgo_idntfccion_tpo,
                    nmro_idntfccion,
                    prmer_nmbre,
                    sgndo_nmbre,
                    prmer_aplldo,
                    sgndo_aplldo,
                    cdgo_rspnsble_tpo,
                    nmro_trjeta_prfsnal,
                    cdgo_mncpio
                ) values(
                    v_id_ntfcion_mdio_evdncia,                
                    p_cdgo_idntfccion_tpo,
                    p_nmro_idntfccion,
                    p_prmer_nmbre,
                    p_sgndo_nmbre,
                    p_prmer_aplldo,
                    p_sgndo_aplldo,
                    p_cdgo_rspnsble_tpo,
                    p_nmro_trjeta_prfsnal,
                    p_cdgo_mncpio
                );
            exception
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en presentacion personal, '||SQLERRM;
                    raise v_error;
            end;
        elsif(p_cdgo_mdio = 'CCY')then
            begin
                insert into nt_g_conducta_concluyente(
                    id_ntfcion_mdio_evdncia,
                    fcha_prsntcion,
                    fcha_rgstro
                ) values(
                    v_id_ntfcion_mdio_evdncia,
                    p_fcha_prsntccion,
                    sysdate
                );
            exception
                when others then
                    o_cdgo_rspsta := 11;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en conducta concluyente, '||SQLERRM;
                    raise v_error; 
            end;
        
        --Notificacion por pagina web
        elsif(p_cdgo_mdio = 'PWE')then
                begin
                    insert into nt_g_web(
                        id_ntfcion_mdio_evdncia,
                        fcha_prsntcion,
                        fcha_rgstro
                    ) values(
                        v_id_ntfcion_mdio_evdncia,
                        p_fcha_prsntccion,
                        sysdate
                    );
                exception
                    when others then
                        o_cdgo_rspsta := 11;
                        o_mnsje_rspsta := 'Problemas al insertar evidencia en Pagina Web, '||SQLERRM;
                        raise v_error; 
                end;
            
        -- Notificación por correo Electronico
        elsif (p_cdgo_mdio = 'CEL') then
              --Insertamos evidencia en la tabla nt_g_email_puntual (crear tabla)
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Insertando en nt_g_email_puntual', 1);
             
            begin
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Insertando evidencia en nt_g_email_puntual', 1);
                  
                        insert into nt_g_email(
                                    id_ntfcion_mdio_evdncia,
                                    fcha_prsntcion,
                                    fcha_rgstro 
                                    ) 
                             values(
                                    v_id_ntfcion_mdio_evdncia,
                                    p_fcha_prsntccion,
                                    sysdate 
                                    )  
                            returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
                       
            exception
                        when others then
                            o_cdgo_rspsta := 11;
                            o_mnsje_rspsta := 'Problemas al insertar evidencia en email puntual, '||SQLERRM;
                            raise v_error; 
            end;   
            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_cdgo_clnte:' || p_cdgo_clnte, 1);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_acto:' || p_id_acto, 1);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_ntfccion:' || p_id_ntfccion, 1);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_fncnrio:' || p_id_fncnrio, 1);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_indcdor_envia_email:' || p_indcdor_envia_email, 1);


            if p_indcdor_envia_email = 'S' then
                 pkg_nt_notificacion.prc_rg_notificaciones_email_puntual( p_cdgo_clnte   => p_cdgo_clnte,
                                                                        p_id_acto        => p_id_acto,
                                                                        p_id_ntfccion    => p_id_ntfccion,
                                                                        p_id_fncnrio     => p_id_fncnrio,
                                                                        p_cdgo_mdio      => p_cdgo_mdio,
                                                                        o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                        o_mnsje_rspsta   =>  o_mnsje_rspsta);
                                           
                if(o_cdgo_rspsta != 0) then
                    o_cdgo_rspsta := 15 ;
                    o_mnsje_rspsta := o_mnsje_rspsta;
                    raise v_error;            
                end if;
            end if;
         end if;

/*
        --Registramos los responsables al detalle
        pkg_nt_notificacion.prc_rg_notificacion_respnsbles(p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                                                           p_id_acto                   => p_id_acto,
                                                           p_json_rspnsbles            => p_json_rspnsbles,
                                                           p_indca_notfcdo             => 'S',
                                                           p_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                                           p_cdgo_csal                 => v_rt_csal.cdgo_csal,
                                                           o_mnsje_tpo                 => v_mnsje_tpo,
                                                           o_mnsje                     => o_mnsje_rspsta);
        --Validamos si hubo errores al registrar responsables al detalle
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 12;
            raise v_error;
        end if;
*/
    else  --if(v_id_ntfccion_dtlle is null)then

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'pr_co_archivo_evidencia v_id_ntfccion_dtlle is NOT null v_file_mimetype :'||v_file_mimetype, 1);
 
        pkg_nt_notificacion.pr_co_archivo_evidencia(p_file_name     => p_file_evdncia,
                                                    p_file_mimetype	=> v_file_mimetype,
                                                    p_file_blob     => v_file_blob,
                                                    o_mnsje_tpo     => v_mnsje_tpo,
                                                    o_mnsje         => o_mnsje_rspsta);

        --Validamos si hubo errores al consultar el archivo   
        if(v_mnsje_tpo = 'ERROR')then
            o_cdgo_rspsta := 8;
            raise v_error;
        end if;

        --Registramos la Evidencia
        pkg_nt_notificacion.prc_rg_evidencia(p_cdgo_clnte                => p_cdgo_clnte,
                                             p_id_mdio                   => v_id_mdio,
                                             p_fcha_ntfccion             => systimestamp,
                                             p_file_blob                 => v_file_blob,
                                             p_file_name                 => substr( p_file_evdncia , instr(p_file_evdncia , '/' ) + 1 ),
                                             p_file_mimetype             => v_file_mimetype,
                                             o_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                             o_cdgo_rspsta               => o_cdgo_rspsta,
                                             o_mnsje_rspsta              => o_mnsje_rspsta);
        if(o_cdgo_rspsta != 0)then
            raise v_error;
        end if;


        --Insertamos en la tabla de evidicencia de presentacion personal o conducta concluyente
        if(p_cdgo_mdio = 'PPN')then
            begin
                insert into nt_g_presentacion_personal(
                    id_ntfcion_mdio_evdncia,
                    cdgo_idntfccion_tpo,
                    nmro_idntfccion,
                    prmer_nmbre,
                    sgndo_nmbre,
                    prmer_aplldo,
                    sgndo_aplldo,
                    cdgo_rspnsble_tpo,
                    nmro_trjeta_prfsnal,
                    cdgo_mncpio
                ) values(
                    v_id_ntfcion_mdio_evdncia,                
                    p_cdgo_idntfccion_tpo,
                    p_nmro_idntfccion,
                    p_prmer_nmbre,
                    p_sgndo_nmbre,
                    p_prmer_aplldo,
                    p_sgndo_aplldo,
                    p_cdgo_rspnsble_tpo,
                    p_nmro_trjeta_prfsnal,
                    p_cdgo_mncpio
                );
            exception
                when others then
                    o_cdgo_rspsta := 13;
                    o_cdgo_rspsta := 'Problemas al insertar evidencia en presentacion personal, '||SQLERRM;
                    raise v_error;
            end;
        elsif(p_cdgo_mdio = 'CCY')then
            begin
                insert into nt_g_conducta_concluyente(
                    id_ntfcion_mdio_evdncia,
                    fcha_prsntcion,
                    fcha_rgstro
                ) values(
                    v_id_ntfcion_mdio_evdncia,
                    p_fcha_prsntccion,
                    sysdate
                );
            exception
                when others then
                    o_cdgo_rspsta := 14;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en conducta concluyente, '||SQLERRM;
                    raise v_error; 
            end;
       
        --Notificacion por pagina web
        elsif(p_cdgo_mdio = 'PWE')then
                begin
                    insert into nt_g_web(
                        id_ntfcion_mdio_evdncia,
                        fcha_prsntcion,
                        fcha_rgstro
                    ) values(
                        v_id_ntfcion_mdio_evdncia,
                        p_fcha_prsntccion,
                        sysdate
                    );
                exception
                    when others then
                        o_cdgo_rspsta := 11;
                        o_mnsje_rspsta := 'Problemas al insertar evidencia en Pagina Web, '||SQLERRM;
                        raise v_error; 
                end;     
                        
        --Notificacion por correo Electronico 
        elsif (p_cdgo_mdio = 'CEL')  then 
        
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Insertando en nt_g_email opcion 2', 1);
             
              begin
              
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Insertando v_id_mdio: '||v_id_mdio, 1);
               --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Insertando v_id_ntfcion_mdio_evdncia: '||v_id_ntfcion_mdio_evdncia, 1);
               
                        insert into nt_g_email(
                                    id_ntfcion_mdio_evdncia,
                                    fcha_prsntcion,
                                    fcha_rgstro 
                                    ) 
                             values(
                                    v_id_ntfcion_mdio_evdncia,
                                    p_fcha_prsntccion,
                                    sysdate 
                                    )  
                            returning id_ntfcion_mdio_evdncia into v_id_ntfcion_mdio_evdncia;
              
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_ntfcion_mdio_evdncia: '||v_id_ntfcion_mdio_evdncia, 1);         
            exception
                when others then
                    o_cdgo_rspsta := 11;
                    o_mnsje_rspsta := 'Problemas al insertar evidencia en email puntual, '||SQLERRM;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1); 
                    raise v_error; 
            end;        
                    
            begin
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 indicafor de email : '|| p_indcdor_envia_email, 1); 
                 
                 if p_indcdor_envia_email = 'S' then
                     pkg_nt_notificacion.prc_rg_notificaciones_email_puntual( p_cdgo_clnte   => p_cdgo_clnte,
                                                                            p_id_acto        => p_id_acto,
                                                                            p_id_ntfccion    => p_id_ntfccion,
                                                                            p_id_fncnrio     => p_id_fncnrio,
                                                                            p_cdgo_mdio      => p_cdgo_mdio,
                                                                            o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                            o_mnsje_rspsta   =>  o_mnsje_rspsta);
                                               
                    if(o_cdgo_rspsta != 0) then
                        o_cdgo_rspsta := 15;
                        o_mnsje_rspsta := o_mnsje_rspsta|| ' Error al intentar notificar el acto por email el id acto: '||p_id_acto;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 msg respuesta 1 email: '|| o_mnsje_rspsta, 1); 
                        raise v_error;            
                    end if;  
                end if;

            exception
                when others then
                    o_cdgo_rspsta := 11;
                    o_mnsje_rspsta := 'El sujeto impuesto no tiene Email registrado.  Por favor verifique ';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '2 email no encontrado: '||o_mnsje_rspsta, 1);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'3 msg respuesta 1 email: '||  o_mnsje_rspsta, 1);
                    rollback;
                    return; 
            end;   
        end if;

        --Actualizamos el estado de la notificación
        begin

            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'va a actualizar nt_g_notificaciones cdgo_estdo = NEP' , 1); 
            update nt_g_notificaciones
            set cdgo_estdo = 'NEP'
            where id_ntfccion = p_id_ntfccion;
        exception
            when others then
                o_cdgo_rspsta := 15;
                o_mnsje_rspsta := 'Problemas al actualizar estado de la notificación Id_ntfccion: '||p_id_ntfccion||' , '||SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'4 msg respuesta 1 email: '||  o_mnsje_rspsta, 1); 
                raise v_error; 
        end;

        ---Actualizamos el estado del intento de notificación
        begin
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'Actualizamos el estado del intento de notificación' , 1); 

            update nt_g_notificaciones_detalle
            set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio
            where id_ntfccion_dtlle = v_id_ntfccion_dtlle;
        exception
            when others then
                o_cdgo_rspsta := 16;
                o_mnsje_rspsta := 'Problemas al actualizar estado del intento de notificación Id_ntfccion_dtlle:'||v_id_ntfccion_dtlle;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 msg intentos noti: '||  o_mnsje_rspsta, 1); 
                raise v_error;  
        end;


        --Actualizamos los responsables asociandolos con la evidencia creada
        for c_responsables in (select a.*
                              from gn_g_actos_responsable a
                              inner join(select id_acto_rspnsble
                                         from json_table(p_json_rspnsbles,'$[*]'columns id_acto_rspnsble PATH '$.ID_ACTO_RSPNSBLE')) b on a.id_acto_rspnsble = b.id_acto_rspnsble
                              where a.id_acto = p_id_acto and
                                    a.indcdor_ntfccion = 'N')loop

            --Consultamos si se encuentra en los responsables del intento de notificacion
            declare
                v_id_ntfccion_rspnsble number;
            begin

            --  select v_id_ntfccion_rspnsble  
                select id_ntfccion_rspnsble 
                into v_id_ntfccion_rspnsble
                from nt_g_ntfccnes_rspnsble
                where id_ntfccion_dtlle = v_id_ntfccion_dtlle and
                      id_acto_rspnsble  = c_responsables.id_acto_rspnsble and
                      indcdor_ntfcdo    = 'N';
                --Actualizamos el responsable del intento de notificacion
                begin
                    if  p_indcdor_envia_email = 'N'  then                    
                        update nt_g_ntfccnes_rspnsble
                        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia, 
                            indcdor_ntfcdo          = 'S', 
                            fcha_ntfccion           = sysdate, 
                            cdgo_csal               = v_rt_csal.cdgo_csal,
                            id_fncnrio              = p_id_fncnrio
                        where id_ntfccion_rspnsble = v_id_ntfccion_rspnsble;
                    elsif p_indcdor_envia_email = 'S' then
                      update nt_g_ntfccnes_rspnsble
                        set id_ntfcion_mdio_evdncia = v_id_ntfcion_mdio_evdncia  
                        where id_ntfccion_rspnsble = v_id_ntfccion_rspnsble;
                    end if;
                exception
                    when others then    
                        o_cdgo_rspsta   := 17;
                        o_mnsje_rspsta  := 'Problemas al actualizar responsable del intento de notifiacion Id_Notificacion_Responsable: '||v_id_ntfccion_rspnsble;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 msg rta  noti responsable: '|| o_mnsje_rspsta, 1); 
                        raise v_error;
                end;
            exception
                when no_data_found then
                    --Registramos el responsable en el intento de notificacion
                    pkg_nt_notificacion.prc_rg_notificacion_respnsbles(p_id_ntfccion_dtlle         => v_id_ntfccion_dtlle,
                                                                       p_id_acto                   => p_id_acto,
                                                                       p_id_acto_rspnsble          => c_responsables.id_acto_rspnsble,
                                                                                                    -- cuando el medio de notifiacion en correo electronico
                                                                                                    -- y no va a enviar el correo, debe quedar notificado automaticamente,
                                                                                                    -- en cambio, si se va a enviar el correo por MAILJET debe esperar
                                                                                                    -- a que el proveedor de respuesta de si se pudo o no enviar el correo electronico 
                                                                       p_indca_notfcdo             => (case
                                                                                                        when p_indcdor_envia_email = 'S' then
                                                                                                            'N'
                                                                                                        else
                                                                                                            'S'
                                                                                                        end), --'S',
                                                                       p_id_ntfcion_mdio_evdncia   => v_id_ntfcion_mdio_evdncia,
                                                                       p_cdgo_csal                 => v_rt_csal.cdgo_csal,
                                                                       o_mnsje_tpo                 => v_mnsje_tpo,
                                                                       o_mnsje                     => o_mnsje_rspsta);
                    --Validamos si hubo errores al registrar responsables al detalle
                    if(v_mnsje_tpo = 'ERROR')then
                        o_cdgo_rspsta := 18;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'2 msg rta noti responsable: '|| o_cdgo_rspsta, 1); 
                        raise v_error;
                    end if;
            end;
        end loop;
    end if;
      update nt_g_notificaciones
           set indcdor_ntfcdo = 'S',      
               fcha_ntfccion  = sysdate  
    where id_acto = p_id_acto;  
    Commit;
    
   --Alex 
     update nt_g_ntfccnes_rspnsble 
     set indcdor_ntfcdo='S', 
     fcha_ntfccion = sysdate 
     where id_acto_rspnsble in
                (select b.id_acto_rspnsble from gn_g_actos_responsable b where b.id_acto = p_id_acto ) ;
           
    commit;

    o_mnsje_rspsta  := '¡Notificación puntual realizada exitosamente!';
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al registrar notificación puntual';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'3 msg rta noti puntual: '|| o_cdgo_rspsta, 1); 
        end if ;
    when others then
      o_cdgo_rspsta := 1;
      o_mnsje_rspsta := sqlerrm;
  end prc_rg_notificacion_puntual;
  
    procedure prc_rg_notificaciones_email_puntual(	p_cdgo_clnte    in number,
													p_id_acto       in number,
													p_id_ntfccion   in number,
													p_id_fncnrio    in number, 
													p_cdgo_mdio     in varchar2,
													o_cdgo_rspsta   out number,
													o_mnsje_rspsta  out varchar2) as

    v_json_parametros       clob;                                       
	v_nl                    number;
	v_nmbre_up              varchar2(70) := 'pkg_nt_notificacion.prc_rg_notificaciones_email_puntual';
    v_id_lte                number;
    v_mnsje_tpo             varchar2(100);
    v_mnsje                 varchar2(100);
    v_id_ntfccion_dtlle     number;
    v_id_acto_tpo           number;
    v_id_entdad_clnte_mdio  number;
    v_id_mdio               number;
    v_email                 varchar2(100);
    v_valida_email          varchar2(1);
    v_blob                  blob;
    
	begin
  
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando prc_rg_notificaciones_email_puntual ' || systimestamp, 1);

		-- codigo de respesta exitoso
		o_cdgo_rspsta := 0;
		o_mnsje_rspsta := 'OK';
		
		--Se busca la entidad cliente medio del correo electronico
		begin
			select 	b.id_entdad_clnte_mdio, a.id_mdio
			into 	v_id_entdad_clnte_mdio, v_id_mdio
			from	nt_d_medio a join nt_d_entidad_cliente_medio b on b.id_mdio = a.id_mdio
			where 	cdgo_mdio = 'CEL';
		exception   
			when no_data_found then
				o_cdgo_rspsta := 5;
				o_mnsje_rspsta := 'No se pudo Consultar el id entidad cliente medio';
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 msg respuesta v_id_entdad_clnte_mdio: ' ||o_mnsje_rspsta, 1);
				return; 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := 'Problemas al consultar el id entidad cliente medio '||' '||SQLERRM;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '2 msg respuesta v_id_entdad_clnte_mdio: ' ||o_mnsje_rspsta, 1);
				return; 
		 end;

     --Se busca el acto tipo de acto
       begin
            select 	id_acto_tpo
            into   v_id_acto_tpo
            from	gn_g_actos
            where   id_acto = p_id_acto;
		exception   
            when no_data_found then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'No se pudo Consultar el tipo de acto';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                rollback;
                return; 
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Problemas al consultar el tipo de acto '||' '||SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                rollback;
               return; 
		 end;

		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'id_entdad_clnte_mdio es: ' || v_id_entdad_clnte_mdio, 1);

		-- Se crea el lote enla tabla lote detalle  - Alcaba		    
					
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'El id acto es: ' || p_id_acto, 1);

		begin 

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'insertando en nt_g lote', 1);
                            
			insert  into nt_g_lote(cdgo_clnte
									,id_entdad_clnte_mdio
									,dscrpcion
									,fcha_gnrcion
									,cdgo_estdo_lte
									,id_fncnrio_gnrcion
									,nmro_rgstros
									,id_acto_tpo
									,fcha_prcsmnto
									,id_fncnrio_prcsmnto
									,id_ntfcion_mdio_evdncia)
					values
								   (p_cdgo_clnte
									,v_id_entdad_clnte_mdio--9
									,'Notificacion puntual email id_acto :  '||p_id_acto  --- ponerle el numero del acto
									,sysdate
									,'EPR'
									,p_id_fncnrio
									,null
									,v_id_acto_tpo
									,sysdate
									,null                 --p_id_fncnrio,
									,null)                -- v_id_ntfcion_mdio_evdncia);
					returning id_lte into v_id_lte;
								 									
		exception
			  when others then
			  o_cdgo_rspsta  :=15;
			  o_mnsje_rspsta := 'Problemas al  crear el lote '|| SQLERRM;
			  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 msg respuesta insert nt g actos: ' ||o_mnsje_rspsta, 1);
			  rollback ;
			  return;  
		end; 		 	
 				 
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto la tabla Lotes ', 1);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_fncnrio:' || p_id_fncnrio, 1);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_acto:' || p_id_acto, 1);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_entdad_clnte_mdio:' || v_id_entdad_clnte_mdio, 1);
						
		-- Se busca el id del detalle de la notificacion
		begin
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'va a hacer la select de v_nt_g_notificaciones_detalle ', 1);
			select id_ntfccion_dtlle
				   into v_id_ntfccion_dtlle
			from v_nt_g_notificaciones_detalle
			where id_acto = p_id_acto
				  and id_mdio = v_id_mdio
				  and rownum=1;
		exception   
			when no_data_found then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := 'No se pudo encontrar el id notificacion detalle';
				 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 mnsje_rspsta v_id_ntfccion_dtlle: '|| o_mnsje_rspsta, 1);
				 rollback;
				Return;
			when others then
				o_cdgo_rspsta := 25;
				o_mnsje_rspsta := 'Problemas al consultar el id notificacion detalle '||' '||SQLERRM;   
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '2 mnsje_rspsta v_id_ntfccion_dtlle:' || o_mnsje_rspsta, 1);
				rollback;
				return; 
		end;          
						  
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'id_ntfccion_dtlle:' || v_id_ntfccion_dtlle, 1);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_acto:' || p_id_acto, 1);        

		begin
			pkg_nt_notificacion.prc_rg_detalle_lotes(
				p_id_lote                  => v_id_lte,
				p_id_ntfccion_dtlle_json   => '[{"ID_NTFCCION_DTLLE":"' ||v_id_ntfccion_dtlle || '"}]',  --[{"ID_NTFCCION_DTLLE":"893024"}]
				o_mnsje_tpo                => v_mnsje_tpo,                                              --'[{"ID_NTFCCION_DTLLE":"' || ID_NTFCCION_DTLLE || '"}]',
				o_mnsje                    => v_mnsje       
			);

			 
			if(v_mnsje_tpo = 'ERROR') then
				 o_cdgo_rspsta := 30;
				 o_mnsje_rspsta := v_mnsje|| ' No se pudo registrar el detalle del lote';
				  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 mnsje_rspsta prc_rg_detalle_lotes:' || o_mnsje_rspsta, 1);
				Rollback;
				Return;                
			end if;
	
		exception
		when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := 'Error al registrar el detalle del lote';
				 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '2 mnsje_rspsta prc_rg_detalle_lotes:' || o_mnsje_rspsta, 1);
				rollback;
				return; 
		end;

	   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'prc_rg_detalle_lotes v_mnsje_tpo:' || v_mnsje_tpo, 1);
	   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'prc_rg_detalle_lotes v_mnsje:' || v_mnsje, 1);
						
		Begin           
			pkg_nt_notificacion.prc_ac_lote( p_id_lote       => v_id_lte,
											 p_id_fncnrio    => p_id_fncnrio,
											 o_mnsje_tpo     => v_mnsje_tpo,
											 o_mnsje         => v_mnsje
											);                       
 
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'prc_ac_lote:v_mnsje_tpo  ' || v_mnsje_tpo, 1);
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_mnsje v_mnsje:' || v_mnsje, 1);
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_lte:v_id_lte  ' || v_id_lte, 1);

	 
			if(v_mnsje_tpo = 'ERROR') then
				o_cdgo_rspsta := 35;
				o_mnsje_rspsta := v_mnsje|| ' No se pudo registrar el detalle del lote';
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 mnsje_rspsta prc_ac_lote:' || o_mnsje_rspsta, 1);
				rollback;
				return;  
            
			end if;
		    
		 exception
				 when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := 'No se pudo actualizar el lote '||' '||SQLERRM;
					 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, '1 mnsje_rspsta prc_ac_lote:' || o_mnsje_rspsta, 1);
					rollback;
					return; 
		 end;
		
		-- En esta parte se envia el correo electrónico Alcaba     
                                
		begin 

			v_valida_email :=  pkg_nt_notificacion.fnc_vl_enviar_email(p_id_lte => v_id_lte);

			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'valida si tiene email: '||v_valida_email , 1); 
		  
		exception   
			when no_data_found then
				 o_cdgo_rspsta := 5;
				 o_mnsje_rspsta := 'No se pudo Consultar el el correo electronico';
				 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 msg respuesta valida email: '||o_mnsje_rspsta, 1); 
				 rollback;
				 return; 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := 'Problemas al consultar el el correo electronico aspciado al sujeto impuesto - id acto '||' '||SQLERRM;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'2 msg respuesta valida email: '||o_mnsje_rspsta, 1);  
				rollback;
				return;             
		end;       
								 
		if v_valida_email = 'S' then
			commit;  --ojooo
			
			begin
				pkg_nt_notificacion.prc_rg_notificaciones_email(p_cdgo_clnte  	=> p_cdgo_clnte,
																p_id_lte        => v_id_lte, 
																o_cdgo_rspsta   => o_cdgo_rspsta,
																o_mnsje_rspsta  => o_mnsje_rspsta);
																
				  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'1 noti email msg codigo respuesta: '||o_cdgo_rspsta, 1);
				  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'2 noti email msg mensaje respuesta: '|| o_mnsje_rspsta, 1);
										   
				if  o_cdgo_rspsta != 0 then
					o_cdgo_rspsta := 45;
					o_mnsje_rspsta :=o_mnsje_rspsta||'Error al  enviar el email de notificacion del id lote: '||v_id_lte;
					 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'3 prc_rg_notificaciones email: '||o_mnsje_rspsta, 1);   
					rollback;
					return;  
                else           
                    update nt_g_lote 
                          set cdgo_estdo_lte ='PRO' 
                    where id_lte =v_id_lte ; 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Actualiza Lote a Procesado ', 1);
                
				 end if;
			exception  
				when others then
					o_cdgo_rspsta := 10;
					o_mnsje_rspsta := 'Problemas al enviar el correo '||' '||SQLERRM;
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'2 msg respuesta valida email: '||o_mnsje_rspsta, 1);  
					rollback;
					return;             
			end;       
		
		else
			o_cdgo_rspsta := 45;
			o_mnsje_rspsta := 'El sujeto impuesto no tiene Email asociado.  Por favor verifique ';
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'4 prc_rg_notificaciones email: '||o_mnsje_rspsta, 1); 
			rollback;
			return;   
		end if;
                                            
		                                                      
     exception
     when others then
      o_cdgo_rspsta  := 20;
      o_mnsje_rspsta := 'Problemas al enviar las notificaciones por mail para el id_acto, ' ||p_id_acto  || ' - ' || SQLERRM;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'6 prc_rg_notificaciones email: '||o_mnsje_rspsta, 1);   
  end prc_rg_notificaciones_email_puntual;
  
  function fnc_vl_enviar_email (p_id_lte in number) return varchar2 is
 
        v_sqlerrm       varchar2(2000);
        o_cdgo_rspsta   number;
        o_mnsje_rspsta varchar2(200);
        v_total_actos  number := 0;
        v_total_sujetos_impsto_email  number := 0;
        v_mostrar      number := 0;
        
        v_nl                    number;
        v_nmbre_up              varchar2(70) := 'pkg_nt_notificacion.fnc_vl_enviar_email';
  
    begin

    --v_nl := pkg_sg_log.fnc_ca_nivel_log( 8758, null, v_nmbre_up);
    --pkg_sg_log.prc_rg_log( 8758, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
    
        -- Total de actos en el lote        
        select count(*)
        into v_total_actos
        from nt_d_lote_detalle
        where id_lte = p_id_lte;
    
    --pkg_sg_log.prc_rg_log( 8758, null, v_nmbre_up,  v_nl, 'v_total_actos ' || v_total_actos, 1); 
        
        -- Total de sujetos impuestos con email
        select count(*)
        into v_total_sujetos_impsto_email
        from nt_d_lote_detalle a  join gn_g_actos_sujeto_impuesto b on b.id_acto = a.id_acto
                                  join si_i_sujetos_impuesto      c on c.id_sjto_impsto = b.id_sjto_impsto
                                       --and c.email is not null         
                                      and regexp_substr(c.email,'[a-zA-Z0-9.%-]+@[a-zA-Z0-9.%-]+\.[a-zA-Z]{2,4}') is not null    
        where  id_lte         = p_id_lte;
        
      --   pkg_sg_log.prc_rg_log( 8758, null, v_nmbre_up,  v_nl, 'v_total_sujetos_impsto_email ' || v_total_sujetos_impsto_email, 1); 
         
         
        if v_total_actos = v_total_sujetos_impsto_email then
            select count(*)
            into v_mostrar
            from nt_g_lote a
            join v_nt_d_ntfccion_mdio_entdd b on a.id_entdad_clnte_mdio = b.id_entdad_clnte_mdio
                                            and b.cdgo_mdio      = 'CEL'    -- Correo electronico
                                            and a.cdgo_estdo_lte = 'EPR'    -- En proceso
            join  nt_d_lote_detalle         c on c.id_lte = a.id_lte
            join v_gn_g_actos               d on d.id_acto = c.id_acto
                                          and (d.file_blob is not null or d.file_bfile is not null)
                                          and d.indcdor_ntfcdo = 'N'
          --   join gn_g_actos_sujeto_impuesto   e on e.id_acto = c.id_acto     
          --  join si_i_sujetos_impuesto        f on f.id_sjto_impsto = e.id_sjto_impsto
          --                                  and f.email is not null                                              
            where a.id_lte         = p_id_lte;
            
        -- pkg_sg_log.prc_rg_log( 8758, null, v_nmbre_up,  v_nl, 'v_mostrar ' || v_mostrar, 1); 
        
            if v_mostrar = v_total_actos and  v_mostrar > 0 then
                 return 'S';
            else
                 return 'N';
            end if;
        else
            return 'N';
        end if;
    
       exception when others then
            o_cdgo_rspsta := 200;
            o_mnsje_rspsta := ' Exception: ' || v_sqlerrm;
      end fnc_vl_enviar_email; 
      
        
procedure prc_rg_ntfccnes_guia_error(p_id_lte       in number,
                                     p_id_lte_dtlle in number,
                                     p_mnsje_error  in varchar2,
                                     p_id_usrio     in number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
begin
  -- codigo de respesta exitoso
  o_cdgo_rspsta := 0;

  -- insertamos el error
  insert into nt_g_ntfccnes_guia_error
    (id_lte, id_lte_dtlle, mnsje_error, id_usrio)
  values
    (p_id_lte, p_id_lte_dtlle, p_mnsje_error, p_id_usrio);

  -- Actualizamos los intentos de proceso de ese detalle
  update nt_d_lote_detalle
     set intntos_prcso = intntos_prcso + 1
   where id_lte_dtlle = p_id_lte_dtlle;

  -- confirmamos los cambios 
  commit;
exception
  when others then
    o_cdgo_rspsta  := 10;
    o_mnsje_rspsta := 'Problemas al registrar el error del detalle, ' ||
                      p_id_lte_dtlle || ' - ' || SQLERRM;
end prc_rg_ntfccnes_guia_error;


procedure prc_rg_pag_web (
    p_cdgo_clnte   in number,
    p_pblccion     in date,
    p_json_actos   in clob default null,
    o_mnsje        out varchar2
) is
    v_count          number;
    v_ntfcdo_pag_web varchar2(1);
begin
    o_mnsje := ''; -- Inicializar el mensaje de salida
    
    -- Recorremos los actos seleccionados
    for c_actos in (
        select a.id_acto, a.nmro_acto
        from gn_g_actos a
        join gn_d_actos_tipo b on a.id_acto_tpo = b.id_acto_tpo
        join (
            select id_acto
            from json_table(p_json_actos, '$[*]' columns id_acto path '$.ID_ACTO')
        ) c on a.id_acto = c.id_acto
    ) loop
            v_count :=0;
        
        -- Verificar si el acto ya está notificado
        begin
            begin
            select 1
            into v_count
            from nt_g_notificaciones
            where id_acto = c_actos.id_acto
            and indcdor_ntfcdo = 'N';
            
            o_mnsje := o_mnsje || 'entro al select ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                       
                        
                         pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'mensaje:' || o_mnsje,
                              1);
                              
            exception
                    when others then
                    v_count:=0;
                        o_mnsje := o_mnsje || 'Error al entrar al select ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                       
                        
                         pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'mensaje:' || o_mnsje,
                              1);
            end;
            
             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'entrando al begin:' || v_count,
                              1);
            -- Si el acto no está notificado
            if v_count = 1 then
                begin
                    update gn_g_actos
                    set fcha_ntfccion = p_pblccion,
                        indcdor_ntfccion = 'S',
                        ntfcdo_pag_web = 'S',
                        fcha_pblccion = p_pblccion
                    where id_acto = c_actos.id_acto;
                commit;
                    o_mnsje := o_mnsje || 'El acto ' || c_actos.nmro_acto || ' ha sido notificado por página web exitosamente.' || chr(10);
                exception
                    when others then
                        o_mnsje := o_mnsje || 'Error al actualizar el acto ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                        raise;
                end;
                begin 
                update nt_g_notificaciones
                    set indcdor_ntfcdo = 'S',
                        cdgo_estdo = 'NPR',
                        fcha_ntfccion = p_pblccion
                    where id_acto = c_actos.id_acto;
                commit;
                    o_mnsje := o_mnsje || 'El acto ' || c_actos.nmro_acto || ' ha sido notificado por página web exitosamente.' || chr(10);
                exception
                    when others then
                        o_mnsje := o_mnsje || 'Error al actualizar el acto ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                        raise;
                end;
            else
             begin
                select ntfcdo_pag_web
                into v_ntfcdo_pag_web
                from gn_g_actos
                where id_acto = c_actos.id_acto; 
                
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'entrando al else2 : ' || v_ntfcdo_pag_web,
                              1);
                exception
                    when others then
                        o_mnsje := o_mnsje || 'Error al actualizar estado pagina web ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                       pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'entrando a la excepcion : ' || o_mnsje,
                              1);
             end;
            
            if v_ntfcdo_pag_web = 'S' and v_count=0 then
             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'entrando a la validacion Notificado pagina web : ' || v_ntfcdo_pag_web,
                              1);
          -- Si ya tiene notificado por página web, enviar mensaje de excepción
          --  raise_application_error(-20001, 'El acto ' || c_actos.nmro_acto || ' ya está notificado por página web.');
            else
             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'entrando al else: ' || v_count,
                              1);
                    -- Actualizar el acto solo si no está notificado por página web
                update gn_g_actos
                set ntfcdo_pag_web = 'S',
                    fcha_pblccion = p_pblccion
                where id_acto = c_actos.id_acto;
                    
                    o_mnsje := o_mnsje || 'El acto ' || c_actos.nmro_acto || ' ha sido notificado por página web exitosamente.' || chr(10);
               commit;
               end if;
            end if;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'saliendo del if' || v_count,
                              1); 
        exception
            when no_data_found then
                o_mnsje := o_mnsje || 'No hay información del acto ' || c_actos.nmro_acto || chr(10);
            when others then
                o_mnsje := o_mnsje || 'Error al procesar el acto ' || c_actos.nmro_acto || ': ' || SQLERRM || chr(10);
                raise;
        end; -- Fin de la verificación de notificación
        
    end loop; -- Fin del loop
         pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_nt_notificacion.prc_rg_pag_web',
                              6,
                              'saliendo del loop' || v_count,
                              1);
exception
    when others then
        o_mnsje := 'Error en el procedimiento prc_rg_pag_web: ' || SQLERRM || chr(10);
        raise;
end prc_rg_pag_web;

procedure prc_ac_actos_responsables(p_cdgo_clnte in number,
                                      p_id_acto    in number,
                                      o_mnsje_tpo  out varchar2,
                                      o_mnsje      out varchar2) as
  
    v_nl               number;
    v_nmbre_up         sg_d_configuraciones_log.nmbre_up%type := 'pkg_nt_notificacion.prc_ac_actos_responsables';
    v_error            exception;
    v_id_acto_rspnsble gn_g_actos_responsable.id_acto_rspnsble%type;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a ' || v_nmbre_up || ' - ' ||
                          systimestamp,
                          1);
  
    for repnsbles in (select c.id_sjto_rspnsble,
                             c.cdgo_idntfccion_tpo,
                             c.idntfccion,
                             c.prmer_nmbre,
                             c.sgndo_nmbre,
                             c.prmer_aplldo,
                             c.sgndo_aplldo,
                             c.prncpal_s_n,
                             c.cdgo_tpo_rspnsble,
                             c.prcntje_prtcpcion,
                             c.orgen_dcmnto,
                             c.id_pais_ntfccion,
                             c.id_dprtmnto_ntfccion,
                             c.id_mncpio_ntfccion,
                             c.drccion_ntfccion,
                             c.email,
                             nvl(c.tlfno, c.cllar) tlfno
                        from si_i_sujetos_responsable c
                       where c.id_sjto_impsto in
                             (select b.id_sjto_impsto
                                from gn_g_actos a
                                join gn_g_actos_sujeto_impuesto b
                                  on b.id_acto = a.id_acto
                               where a.id_acto = p_id_acto)) loop
    
      if (repnsbles.drccion_ntfccion is null or
         repnsbles.id_pais_ntfccion is null or
         repnsbles.id_dprtmnto_ntfccion is null or
         repnsbles.id_mncpio_ntfccion is null) then
        o_mnsje_tpo := 'ERROR';
        o_mnsje     := 'EL responsable ' || repnsbles.id_sjto_rspnsble ||
                       ' le faltan datos requeridos para la notificación, por favor actualicelos antes de continuar';
      
        raise v_error;
      end if;
    
      begin
        insert into gn_g_actos_responsable
          (id_acto,
           cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           drccion_ntfccion,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           email,
           tlfno)
        values
          (p_id_acto,
           repnsbles.cdgo_idntfccion_tpo,
           repnsbles.idntfccion,
           repnsbles.prmer_nmbre,
           repnsbles.sgndo_nmbre,
           repnsbles.prmer_aplldo,
           repnsbles.sgndo_aplldo,
           repnsbles.drccion_ntfccion,
           repnsbles.id_pais_ntfccion,
           repnsbles.id_dprtmnto_ntfccion,
           repnsbles.id_mncpio_ntfccion,
           repnsbles.email,
           repnsbles.tlfno)
        returning id_acto_rspnsble into v_id_acto_rspnsble;
      
        if v_id_acto_rspnsble is not null then
          o_mnsje_tpo := 'OK';
          o_mnsje     := 'Responsables registrados con éxito';
        end if;
      exception
        when others then
          o_mnsje_tpo := 'ERROR';
          o_mnsje     := 'Error al insertar los responsables del acto - ' ||
                         sqlerrm;
          raise v_error;
      end;
    end loop;
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje,
                            1);
    
  end prc_ac_actos_responsables;

   --Publicacion WEB
  procedure prc_rg_pag_web(p_cdgo_clnte   in number,
                           p_pblccion     in date,
                           p_id_crtfcdo_json in number,
                           p_json_actos   in clob default null,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2) as
  
    v_count          number;
    v_ntfcdo_pag_web varchar2(1);
    v_nl             number;
    v_nmbre_up       varchar2(4000) := 'pkg_nt_notificacion.prc_rg_pag_web';
    v_error          exception;
    v_json_crtfcdos  clob;
    v_indcdor_ntfcdo nt_g_notificaciones.indcdor_ntfcdo%type;
  
  begin
  
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Actos publicados con éxito.';
    
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a ' || v_nmbre_up || ' Hora:' ||
                          systimestamp,
                          6);
  
    -- Recorremos los actos seleccionados
    begin
        select json_crtfcdos
        into v_json_crtfcdos
        from nt_g_certificados_json a 
        where a.id_nt_crtfcdo_json = p_id_crtfcdo_json;
    exception when no_data_found then
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := 'Error No. '||o_cdgo_rspsta||
                          '. Id json'||p_id_crtfcdo_json||' de los actos no encontrado con id. ';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6); 
                          
       raise v_error;                        
    end;
    
    for c_actos in (select a.id_acto, a.nmro_acto
                      from gn_g_actos a
                      join gn_d_actos_tipo b
                        on a.id_acto_tpo = b.id_acto_tpo
                      join (select id_acto
                             from json_table(v_json_crtfcdos,--p_json_actos,
                                             '$[*]' columns id_acto path
                                             '$.ID_ACTO')) c
                        on a.id_acto = c.id_acto) loop
         
      -- Verificar si el acto ya está notificado
   --   begin
        begin
          select indcdor_ntfcdo
            into v_indcdor_ntfcdo
            from nt_g_notificaciones
           where id_acto = c_actos.id_acto;
        
        exception        
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                              '. Error al consultar el id_acto ' ||
                              c_actos.nmro_acto || ', o ya esta notificado. Verifique!!!.' ;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta||'. '||sqlerrm,
                                  6);
          
            raise v_error;
          
        end;
      
        -- Si el acto no está notificado
        if(v_indcdor_ntfcdo is null or v_indcdor_ntfcdo ='N')then
          begin
            update gn_g_actos
               set fcha_ntfccion    = p_pblccion,
                   indcdor_ntfccion = 'S',
                   ntfcdo_pag_web   = 'S',
                   fcha_pblccion    = p_pblccion
             where id_acto = c_actos.id_acto;
          
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                                ' Al actualizar el acto ' ||
                                c_actos.nmro_acto || ':. ' || SQLERRM;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              raise v_error;
          end;
        
          begin
            update nt_g_notificaciones
               set indcdor_ntfcdo = 'S',
                   cdgo_estdo     = 'NPR',
                   fcha_ntfccion  = p_pblccion
             where id_acto = c_actos.id_acto;
            commit;
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                                'Error actualizando el acto ' ||
                                c_actos.nmro_acto || ': ' || SQLERRM;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              raise v_error;
          end;
        else
          begin
            select ntfcdo_pag_web
              into v_ntfcdo_pag_web
              from gn_g_actos
             where id_acto = c_actos.id_acto;          
          exception
            when others then            
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                                'Al actualizar estado pagina web ' ||
                                c_actos.nmro_acto || ': ' || SQLERRM;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              raise v_error;
          end;
        
          if (v_ntfcdo_pag_web = 'S' and  v_indcdor_ntfcdo = 'S') then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_nt_notificacion.prc_rg_pag_web',
                                  6,
                                  'entrando a la validacion Notificado pagina web : ' ||
                                  v_ntfcdo_pag_web,
                                  6);
            
              o_cdgo_rspsta  := 41;
              o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                                'El acto '||
                                c_actos.nmro_acto ||' ya esta publicado en pagina web ';
            raise v_error;
            -- Si ya tiene notificado por página web, enviar mensaje de excepción
            --  raise_application_error(-20001, 'El acto ' || c_actos.nmro_acto || ' ya está notificado por página web.');
          else
          
            -- Actualizar el acto solo si no está notificado por página web
            begin
              update gn_g_actos
                 set ntfcdo_pag_web = 'S', fcha_pblccion = p_pblccion
               where id_acto = c_actos.id_acto;
            exception
              when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                                  'Al actualizar estado en gn_g_actos ' ||
                                  c_actos.nmro_acto || ': ' || SQLERRM;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
              
                raise v_error;
            end;
          
          end if;
        end if;
      
     /* exception
        when no_data_found then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                            'No hay información del acto ' ||
                            c_actos.nmro_acto || '. ' || sqlerrm;
          raise v_error;
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                            'Error consultando la información del acto ' ||
                            c_actos.nmro_acto || '. ' || SQLERRM;
          raise v_error;
      end;*/ -- Fin de la verificación de notificación
    
    end loop; -- Fin del loop
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          6,
                          'saliendo de la up ' || v_nmbre_up,
                          6);
  exception
    when v_error then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            6,
                            o_mnsje_rspsta,
                            6);
                            return;
  when others then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            6,
                            o_mnsje_rspsta,
                            6); 
                            return;
  end prc_rg_pag_web;

  procedure prc_rg_certificados_json(p_cdgo_clnte         in number,
                                     p_json_actos         in clob,
                                     o_id_nt_crtfcdo_json out number,
                                     o_cdgo_rspsta        out number,
                                     o_mnsje_rspsta       out varchar2) as
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_nt_notificacion.prc_rg_certificados_json';
    v_error    exception;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a ' || v_nmbre_up || ' Hora:' ||
                          systimestamp,
                          6);
  
    begin
      insert into nt_g_certificados_json
        (cdgo_clnte, json_crtfcdos)
      values
        (p_cdgo_clnte, p_json_actos)
      returning id_nt_crtfcdo_json into o_id_nt_crtfcdo_json;
    end;
  
    if (o_id_nt_crtfcdo_json is null) then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                        '. Error al insertar en nt_g_certificados_json ' ||
                        sqlerrm;
      raise v_error;
    else
      o_cdgo_rspsta   := 0;
      o_mnsje_rspsta := 'registro exitoso.';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          6,
                          'saliendo de la up ' || v_nmbre_up || ' Hora:' ||
                          systimestamp,
                          6);
  exception
    when v_error then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            6,
                            o_mnsje_rspsta,
                            6);
  end prc_rg_certificados_json;
  
  procedure prc_rg_pag_web_job(p_cdgo_clnte      in number,
                               p_pblccion        in date,
                               p_id_crtfcdo_json in number,
                               p_id_usuario      in number) as
                             
    
  v_json_parametros VARCHAR2(4000);
  v_nvel          NUMBER;
  v_nmbre_up      sg_d_configuraciones_log.nmbre_up%TYPE := 'pkg_nt_notificacion.prc_rg_pag_web_job'; 
  o_cdgo_rspsta   number;
  o_mnsje_rspsta  varchar2(4000);  
  
  begin  
     
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(
                p_cdgo_clnte => p_cdgo_clnte, 
                p_id_impsto => NULL, 
                p_nmbre_up => v_nmbre_up
              );
              
   pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            6,
                            'Entrando a la up '||v_nmbre_up||', '||systimestamp,
                            6);           
              
    pkg_nt_notificacion.prc_rg_pag_web(p_cdgo_clnte,
                                       p_pblccion,
                                       p_id_crtfcdo_json,
                                       null,
                                       o_cdgo_rspsta,
                                       o_mnsje_rspsta);
  if (o_cdgo_rspsta = 0)then
        -- Consultamos los envíos programados
        begin
            select json_object(
               key 'p_id_usuario' value p_id_usuario
            ) into v_json_parametros from dual;

            pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte => p_cdgo_clnte,
                                                  p_idntfcdor => 'NOTIWEB',
                                                  p_json_prmtros => v_json_parametros
            );
            
            o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
            
            pkg_sg_log.prc_rg_log(
                p_cdgo_clnte => p_cdgo_clnte,
                p_id_impsto => NULL,
                p_nmbre_up => v_nmbre_up,
                p_nvel_log => v_nvel,
                p_txto_log => o_mnsje_rspsta,
                p_nvel_txto => 6
            );
        exception
            when others then
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error en los envios programados, ' || sqlerrm;
                pkg_sg_log.prc_rg_log(
                    p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto => NULL,
                    p_nmbre_up => v_nmbre_up,
                    p_nvel_log => v_nvel,
                    p_txto_log => o_mnsje_rspsta,
                    p_nvel_txto => 6
                );
                rollback;
                return;
        end; -- Fin Consultamos los envios programados

    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_nt_notificacion.prc_rg_pag_web_job',--v_nmbre_up,
                            6,
                            o_mnsje_rspsta,
                            6);
  else
    --falló
    o_cdgo_rspsta := 10;
    o_mnsje_rspsta := 'Error No. '||o_cdgo_rspsta||' al intentar publicar los actos';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_nt_notificacion.prc_rg_pag_web_job',--v_nmbre_up,
                            6,
                            o_mnsje_rspsta,
                            6);
                            return;
  end if;
  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            6,
                            'Saliendo de la up '||v_nmbre_up||', '||systimestamp,
                            6);
  end prc_rg_pag_web_job;
  
end pkg_nt_notificacion;

/
