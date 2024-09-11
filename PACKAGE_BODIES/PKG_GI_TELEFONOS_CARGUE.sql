--------------------------------------------------------
--  DDL for Package Body PKG_GI_TELEFONOS_CARGUE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_TELEFONOS_CARGUE" as

    function fnc_co_asociada(p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number) return number is
    v_id_sbmpsto_ascda number;
    begin

        -- Consultamos el Municipio
        begin
            select  id_sbmpsto_ascda
            into    v_id_sbmpsto_ascda
            from    gi_d_subimpuestos_asociada
            where   id_impsto = p_id_impsto
            and     id_impsto_sbmpsto = p_id_impsto_sbmpsto;
        exception
            when others then
                v_id_sbmpsto_ascda := null;
        end;
        return v_id_sbmpsto_ascda;

    end fnc_co_asociada;

    function fnc_validar_telefono (p_telefono in number) return boolean is
    begin
            if regexp_like(p_telefono, '^[3][0-9]{9}$') then
             return true;
    else
             return false;
    end if;
         exception
              when others then
              return false;
    end fnc_validar_telefono;

    function fnc_validar_numerico(p_numero in varchar2) return boolean is
    v_number number;
    begin
        v_number := to_number(p_numero);
        return true;
    exception
        when others then
            return false;
    end fnc_validar_numerico;

 function fnc_validar_caracter(p_caracter in varchar2) return boolean is
    begin
         if regexp_like(p_caracter, '^[A-Za-z]+$') then
            return true;
        else
            return false;
        end if;
    exception
        when others then
            return false;
    end fnc_validar_caracter;   

    function fnc_validar_correo(p_correo in varchar2) return boolean is
        begin
            return regexp_like(p_correo, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');
        exception
            when others then
                return false;
        end fnc_validar_correo;

    /* procedure prc_rg_observacion(p_id_rentas_cargue in number,
                                p_obsrvcion        in clob,
                                p_estdo            in varchar2,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2) is
    PRAGMA autonomous_transaction;

    begin
        begin
            o_cdgo_rspsta := 0;

            update  gi_g_rentas_cargue
            set     obsrvcion    = p_obsrvcion,
                    nmro_intntos = nmro_intntos + 1,
                    estdo        = p_estdo
            where   id_rentas_cargue = p_id_rentas_cargue;
            commit;
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al actualizar la observacion del proceso - id_rentas_cargue -' ||
                                p_id_rentas_cargue || '-' ;
        end;

    exception
        when others then
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := 'Error al actualizar la observacion del proceso. ';

    end prc_rg_observacion;*/

    procedure prc_rg_observacion(p_id_tlfno_pre_lqdcion in number,
                                    p_obsrvcion           in clob,
                                    p_estdo               in varchar2,
                                    o_cdgo_rspsta         out number,
                                    o_mnsje_rspsta        out varchar2) is
    PRAGMA autonomous_transaction;

    begin
        begin
            o_cdgo_rspsta := 0;

            update  gi_g_telefono_pre_lqdcion
            set     obsrvcion_lqdcion    = p_obsrvcion,
                    nmro_intntos = nmro_intntos + 1,
                    indcdor_prcsdo        = p_estdo
            where   id_tlfno_pre_lqdcion = p_id_tlfno_pre_lqdcion;
            commit;
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al actualizar la observacion del proceso - id_tlfno_pre_lqdcion -' ||
                                p_id_tlfno_pre_lqdcion || '-' ;
        end;

    exception
        when others then
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := 'Error al actualizar la observacion del proceso. ';

    end prc_rg_observacion;

     procedure prc_rg_observacion_recaudo(  p_id_tlfno_rcdo in number,
                                            p_obsrvcion           in clob,
                                            p_estdo               in varchar2,
                                            o_cdgo_rspsta         out number,
                                            o_mnsje_rspsta        out varchar2) is
    PRAGMA autonomous_transaction;

    begin
        begin
            o_cdgo_rspsta := 0;

            update  gi_g_telefono_recaudo
            set     obsrvcion_rcdo     = p_obsrvcion,
                    indcdor_prcsdo     = p_estdo
            where   id_tlfno_rcdo      = p_id_tlfno_rcdo;
            commit;
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al actualizar la observacion del proceso -  id_tlfno_rcdo -' ||
                                    p_id_tlfno_rcdo || '-' ;
        end;

    exception
        when others then
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := 'Error al actualizar la observacion del proceso. ';

    end prc_rg_observacion_recaudo;

   /* procedure prc_rg_cargue ( p_cdgo_clnte                in number,
                              p_id_ssion                  in number,
                              p_id_app                    in number,
                              p_id_page_app               in number,
                              p_id_usrio                  in number,
                              p_id_cnfgrcion_crgue_impsto in number,
                              p_id_prcso_crga             in number,
                              o_cdgo_rspsta               out number,
                              o_mnsje_rspsta              out varchar2 ) 
    as    
        v_nl                number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_cargue';

        t_et_d_cnfgrcion_crgue_impsto v_et_d_cnfgrcion_crgue_impsto%rowtype;
        v_id_sjto_impsto    number;
        v_id_lqdcion        number;
        --v_id_rnta         number;
        v_id_dcmnto         number;
        v_id_fljo           wf_d_flujos.id_fljo%type;    
        v_id_sesion         number;
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Inicia: '||p_id_prcso_crga,
                              1);
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := ' Liquidaciones registradas exitosamente ';

        --Se consulta la configuracion del cargue
        begin
            select  *
            into    t_et_d_cnfgrcion_crgue_impsto
            from    v_et_d_cnfgrcion_crgue_impsto
            where   id_cnfgrcion_crgue_impsto = p_id_cnfgrcion_crgue_impsto;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar la configuracion de cargue. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        -- Se consulta el id del flujo de novedades persona
        begin
            select  id_fljo
            into    v_id_fljo
            from    wf_d_flujos
            where   cdgo_fljo = 'NPR';
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el flujo de Novedades Persona. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        begin
            --Se actualiza el impuesto, subimpsto, acto 
            update  gi_g_rentas_cargue
            set     id_impsto         = t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                    id_impsto_sbmpsto = t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto
            where id_prcso_crga = p_id_prcso_crga;
        exception
            when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al actualizar el impuesto, subimpuesto y acto en la tabla de cargue. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        commit;

        -- Se actualiza el id_sjto_impsto en la tabla de cargue
        for c_rentas in (   select  id_rentas_cargue, idntfccion, id_impsto
                            from    gi_g_rentas_cargue
                            where   id_prcso_crga = p_id_prcso_crga
                            and     estdo != 'PROCESADO'
                            and     id_sjto_impsto is null ) 
        loop

            begin
                select  id_sjto_impsto
                into    v_id_sjto_impsto
                from    v_si_i_sujetos_impuesto
                where   idntfccion_sjto = to_char(c_rentas.idntfccion)
                and     id_impsto = c_rentas.id_impsto;

                update  gi_g_rentas_cargue
                set     id_sjto_impsto = v_id_sjto_impsto
                where   id_rentas_cargue = c_rentas.id_rentas_cargue;

            exception
                when no_data_found then
                    begin
                        -- Se crean los sujetos impuestos
                        pkg_gi_telefonos_cargue.prc_rg_sujeto_impuesto (  p_cdgo_clnte          => p_cdgo_clnte,
                                                                          p_id_ssion            => p_id_ssion,
                                                                          p_id_app_nvddes_prsna => t_et_d_cnfgrcion_crgue_impsto.id_app_nvddes_prsna, 
                                                                          p_id_app_page_nvd_prs => t_et_d_cnfgrcion_crgue_impsto.id_app_page_nvd_prs, 
                                                                          p_id_usrio            => p_id_usrio,
                                                                          p_id_impsto           => t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                                                                          p_id_impsto_sbmpsto   => t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto,
                                                                          p_id_tlfno_pre_lqdcion=> c_rentas.id_tlfno_pre_lqdcion,
                                                                          p_id_fljo             => v_id_fljo,
                                                                          o_id_sjto_impsto      => v_id_sjto_impsto,
                                                                          o_cdgo_rspsta         => o_cdgo_rspsta,
                                                                          o_mnsje_rspsta        => o_mnsje_rspsta );

                        if o_cdgo_rspsta = 0 then
                            update  gi_g_rentas_cargue
                            set     id_sjto_impsto = v_id_sjto_impsto
                            where   id_rentas_cargue = c_rentas.id_rentas_cargue;

                            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'ACTUALIZADO SUJETO: '||v_id_sjto_impsto, 1);
                        else
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||': Error al crear sujeto-impuesto ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                            -- Registrar la respuesta de la transacción
                            prc_rg_observacion(p_id_rentas_cargue => c_rentas.id_rentas_cargue,
                                               p_obsrvcion        => o_mnsje_rspsta,
                                               p_estdo            => 'ERROR',
                                               o_cdgo_rspsta      => o_cdgo_rspsta,
                                               o_mnsje_rspsta     => o_mnsje_rspsta);
                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;

                    exception
                        when others then
                            o_cdgo_rspsta  := 30;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al crear sujeto impuesto ID['||c_rentas.idntfccion||'] - ' ||o_mnsje_rspsta||' - Error:';
                            pkg_sg_log.prc_rg_log ( p_cdgo_clnte,  null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                            prc_rg_observacion ( p_id_rentas_cargue => c_rentas.id_rentas_cargue,
                                                 p_obsrvcion        => o_mnsje_rspsta,
                                                 p_estdo            => 'ERROR',
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta );

                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                                continue;
                            end if;
                            continue;        
                    end;

                when others then
                    o_cdgo_rspsta  := 40;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al consultar/actualizar sujeto impuesto ID['||c_rentas.idntfccion||'] - ' ;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte,  null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                    prc_rg_observacion ( p_id_rentas_cargue => c_rentas.id_rentas_cargue,
                                         p_obsrvcion        => o_mnsje_rspsta,
                                         p_estdo            => 'ERROR',
                                         o_cdgo_rspsta      => o_cdgo_rspsta,
                                         o_mnsje_rspsta     => o_mnsje_rspsta );

                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                        continue;
                    end if;
                    continue;        
            end;          

            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'FOR PASA AL SIGUIENTE', 1);                                          
        end loop;

        commit; --ojo

        -- Registra liquidaciones y/o documentos             
        for c_rentas in ( select  *
                          from    gi_g_rentas_cargue
                          where   id_prcso_crga = p_id_prcso_crga
                          and     estdo != 'PROCESADO'
                          and     id_sjto_impsto is not null ) 
        loop
            begin

                v_id_dcmnto  := 0;
                --v_id_rnta    := 0;
                v_id_lqdcion := 0;

                -- Si no se debe liquidar, es decir, la informacion enviada ya viene liquidada
                -- y solo se debe registrar
                if t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'N' then 
                    begin
                        -- Se pasa a liquidacion y movimiento financiero
                        pkg_gi_telefonos_cargue.prc_rg_liquidacion_telefonos ( p_cdgo_clnte        => p_cdgo_clnte,
                                                                               p_id_rentas_cargue  => c_rentas.id_rentas_cargue, 
                                                                               p_cdgo_indcdor_tpo  => t_et_d_cnfgrcion_crgue_impsto.cdgo_indcdor_tpo,
                                                                               p_id_usrio          => p_id_usrio,
                                                                               p_entrno            => 'PRVDO',
                                                                               o_id_lqdcion        => v_id_lqdcion,
                                                                               o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                               o_mnsje_rspsta      => o_mnsje_rspsta);

                        --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_id_lqdcion : ' || v_id_lqdcion, 6);

                        if o_cdgo_rspsta <> 0 then
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al registrar la liquidacion -' || o_mnsje_rspsta;
                            pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                            prc_rg_observacion ( p_id_rentas_cargue => c_rentas.id_rentas_cargue,
                                                 p_obsrvcion        => o_mnsje_rspsta,
                                                 p_estdo            => 'ERROR',
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta );

                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                                pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                                        null,
                                                        v_nmbre_up,
                                                        v_nl,
                                                        o_mnsje_rspsta,
                                                        1 );
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;  

                    exception
                        when others then
                            o_cdgo_rspsta  := 60;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al registrar las liquidaciones. ' ||o_mnsje_rspsta||' - Error: ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                            rollback;
                            return;
                    end;                    
                else
                    --if t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'N' then
                    --t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'S'
                    null;
                end if;

                -- Si debe generar documento
                if t_et_d_cnfgrcion_crgue_impsto.indcdor_gnra_dcmnto = 'S' then
                    begin
                        pkg_gi_telefonos_cargue.prc_rg_documento (  p_cdgo_clnte        => p_cdgo_clnte,
                                                                    p_id_impsto         => c_rentas.id_impsto,
                                                                    p_id_impsto_sbmpsto => c_rentas.id_impsto_sbmpsto,
                                                                    p_id_sjto_impsto    => c_rentas.id_sjto_impsto,
                                                                    p_id_lqdcion        => v_id_lqdcion,
                                                                    p_fcha_vncmnto      => sysdate, --c_rentas.fcha_vncmnto_dcmnto,
                                                                    p_nmro_dcmnto       => v_id_lqdcion,
                                                                    p_cdgo_dcmnto_tpo   => 'DNO',
                                                                    p_entrno            => 'PRVDO',
                                                                    o_id_dcmnto         => v_id_dcmnto,
                                                                    o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => o_mnsje_rspsta ); 

                        if o_cdgo_rspsta <> 0 then
                            o_cdgo_rspsta  := 70;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '-' || o_mnsje_rspsta;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                            prc_rg_observacion(p_id_rentas_cargue => c_rentas.id_rentas_cargue,
                                               p_obsrvcion        => o_mnsje_rspsta,
                                               p_estdo            => 'ERROR',
                                               o_cdgo_rspsta      => o_cdgo_rspsta,
                                               o_mnsje_rspsta     => o_mnsje_rspsta);
                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;

                    exception
                        when others then
                            o_cdgo_rspsta  := 80;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                              ': Error al registrar el documento Sujeto.' ||c_rentas.idntfccion||' - ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                            rollback;
                            return;
                    end;                
                end if;

                if o_cdgo_rspsta = 0 then
                    update  gi_g_rentas_cargue
                    set     estdo        = 'PROCESADO',
                            obsrvcion    = 'Registro procesado con éxito',
                            nmro_intntos = nmro_intntos + 1,
                            id_lqdcion   = v_id_lqdcion
                    where   id_rentas_cargue = c_rentas.id_rentas_cargue;
                    commit;
                end if;

            exception
                when others then
                    o_cdgo_rspsta  := 90;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                      ': Error al registrar las liquidaciones.' ;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end;            
        end loop;

        begin
          apex_session.attach(p_app_id     => p_id_app, -- 70000,
                              p_page_id    => p_id_page_app, -- 325,
                              p_session_id => p_id_ssion -- v('APP_SESSION')
                              );
        end;     

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo', 1);

    exception
        when others then
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al realizar el proceso de registro de la liquidación de teléfono ' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;
            return;

    end prc_rg_cargue;*/

 procedure prc_rg_sujeto_impuesto (    p_cdgo_clnte             in number,
                                       p_id_ssion               in number,
                                       p_id_app_nvddes_prsna    in number, 
                                       p_id_app_page_nvd_prs    in number, 
                                       p_id_usrio               in number,
                                       p_id_impsto              in number,
                                       p_id_impsto_sbmpsto      in number,
                                       p_id_tlfno_pre_lqdcion   in number,
                                       p_id_fljo                in number,
                                       o_id_sjto_impsto         out number,
                                       o_cdgo_rspsta            out number,
                                       o_mnsje_rspsta           out varchar2 ) 
    as
        v_nl                    number;
        v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_sujeto_impuesto';
        v_json                  clob;
        v_error                 varchar2(4000);
        v_fcha_crcion           date;
        t_gi_g_telefono_pre_lqdcion    gi_g_telefono_pre_lqdcion%rowtype;
        v_id_sesion             number;
        o_id_nvdad_prsna        number;
        v_id_instncia_fljo      number;
        v_id_fljo_trea          number;
        v_mnsje                 varchar2(1000);
        v_id_fljo_trea_orgen    number;
        v_type_rspsta           varchar2(10);
        v_trea                  number;
        v_seq_id                number;
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);

        -- Se buscan los datos del sujeto
        begin
            select  *
            into    t_gi_g_telefono_pre_lqdcion
            from    gi_g_telefono_pre_lqdcion 
            where   id_tlfno_pre_lqdcion = p_id_tlfno_pre_lqdcion;

            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se consulta datos sujeto',
                              1);
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  ' - Error al consultar el registro a procesar en la tabla gi_g_telefono_pre_lqdcion . id_tlfno_pre_lqdcion ' ||
                                  p_id_tlfno_pre_lqdcion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
               -- return;
        end;

        --Valida que el sujeto no se encuentre registrado
        begin
            select  a.id_sjto_impsto
            into    o_id_sjto_impsto
            from    v_si_i_sujetos_impuesto a
            where   idntfccion_sjto = to_char(t_gi_g_telefono_pre_lqdcion.idntfccion)
            and     cdgo_clnte = p_cdgo_clnte
            and     id_impsto = p_id_impsto;

            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Existe sujeto: ' ||
                                t_gi_g_telefono_pre_lqdcion.idntfccion || '-' ||
                                o_id_sjto_impsto,
                                1);

        exception
            when no_data_found then  

                begin
                    apex_session.attach(p_app_id     => p_id_app_nvddes_prsna,
                                        p_page_id    => p_id_app_page_nvd_prs,
                                        p_session_id => p_id_ssion);
                end;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'APEX_UTIL.SET_SESSION_STATE',
                                      1);  

                /*-----------------------------------*/

                -- Se instancia el flujo de novedades persona
                pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => p_id_fljo,
                                                            p_id_usrio         => p_id_usrio,
                                                            p_id_prtcpte       => null,
                                                            p_obsrvcion        => 'Creación Sujeto Impuestos Cargue Masivo de Teléfono/Telégrafo',
                                                            o_id_instncia_fljo => v_id_instncia_fljo,
                                                            o_id_fljo_trea     => v_id_fljo_trea,
                                                            o_mnsje            => v_mnsje);

                if v_id_instncia_fljo is null then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta ||
                                    ' - Error al registrar la Novedad para crear el sujeto impuesto. ' || v_mnsje;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6 );
                    rollback; 
                   -- return;
                else
                    commit;
                end if;


                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'v_id_instncia_fljo: '||v_id_instncia_fljo||' - v_id_fljo_trea: '||v_id_fljo_trea,
                                      1);

                APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_CDGO_NVDAD_TPO',
                                            p_value => 'INS');

                APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_RECHAZAR',
                                            p_value => 'N');

                -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                /*pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'Antes de Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.' ||
                                      systimestamp,
                                      1);*/

                -- Pasa a la siguiente tarea Tipo de Novedades
                begin
                    select  a.id_fljo_trea_orgen
                    into    v_id_fljo_trea_orgen
                    from    wf_g_instancias_transicion a
                    where   a.id_instncia_fljo = v_id_instncia_fljo
                    and     a.id_estdo_trnscion in (1, 2);

                   pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'la informacion del flujo v_id_fljo_trea_orgen,v_id_instncia_fljo: ' ||
                                            v_id_fljo_trea_orgen || '-' || v_id_instncia_fljo,
                                            1 );

                    -- Se cambia la etapa de flujo
                    begin
                    pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                     p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                                     p_json             => '[]',
                                                                     o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                                     o_mnsje            => o_mnsje_rspsta,
                                                                     o_id_fljo_trea     => v_id_fljo_trea,
                                                                     o_error            => v_error);
                    exception
                        when others then 
                         pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Error al llamar al paquete de workflow' ||
                                            v_id_fljo_trea_orgen || '-' || v_id_instncia_fljo,
                                            1 );
                    end;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Despues de o_mnsje_rspsta,o_id_fljo_trea,v_error=>' ||
                                          o_mnsje_rspsta || '-' || v_id_fljo_trea || '-' || v_error,
                                          1);                             

                exception
                    when others then
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                                      ' -- ' ;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                       -- return;
                end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.	

                while v_trea <= 2 loop
                    -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                    begin
                        select  a.id_fljo_trea_orgen
                        into    v_id_fljo_trea_orgen
                        from    wf_g_instancias_transicion a
                        where   a.id_instncia_fljo = v_id_instncia_fljo
                        and     a.id_estdo_trnscion in (1, 2);

                        -- Se cambia la etapa de flujo
                        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                                         p_json             => '[]',
                                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                                         o_mnsje            => o_mnsje_rspsta,
                                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                                         o_error            => v_error);
                    exception
                        when others then
                          o_cdgo_rspsta  := 30;
                          o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode || ' -- ' ;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' || o_mnsje_rspsta,
                                                1);
                          rollback;
                         -- return;
                    end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.

                    v_trea := v_trea + 1;
                end loop;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null, v_nmbre_up, v_nl, 'DESPUES DE  while v_trea', 1);

                -- Si es persona Jurídica, se crea la colección para el responsbale
                if ( t_gi_g_telefono_pre_lqdcion.tpo_prsna = 'J' ) then
                    if ( not apex_collection.collection_exists(p_collection_name => 'RESPONSABLES') ) then
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Se crea la colección',  1);                    
                        apex_collection.create_collection(p_collection_name => 'RESPONSABLES');
                    end if;   

                    begin
                        select  seq_id
                        into    v_seq_id
                        from    apex_collections a
                        where   collection_name = 'RESPONSABLES'
                        and     a.n001 = v_id_instncia_fljo
                        and     a.c004 = t_gi_g_telefono_pre_lqdcion.idntfccion;
                    exception
                        when no_data_found then
                            v_seq_id := null;                    
                    end;

                    if v_seq_id is null then
                        begin
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Se adiciona responsable', 1);
                            apex_collection.add_member ( p_collection_name => 'RESPONSABLES',
                                                         p_n001            => v_id_instncia_fljo,
                                                         p_c003            => t_gi_g_telefono_pre_lqdcion.cdgo_idntfccion_tpo,
                                                         p_c004            => t_gi_g_telefono_pre_lqdcion.idntfccion,
                                                         p_c005            => t_gi_g_telefono_pre_lqdcion.prmer_nmbre,
                                                         p_c006            => t_gi_g_telefono_pre_lqdcion.sgndo_nmbre,
                                                         p_c007            => t_gi_g_telefono_pre_lqdcion.prmer_aplldo,
                                                         p_c008            => t_gi_g_telefono_pre_lqdcion.sgndo_aplldo,
                                                         p_c009            => 'S',
                                                         p_c010            => 'R',
                                                         p_c013            => t_gi_g_telefono_pre_lqdcion.id_pais,
                                                         p_c014            => t_gi_g_telefono_pre_lqdcion.id_dprtmnto,
                                                         p_c015            => t_gi_g_telefono_pre_lqdcion.id_mncpio,
                                                         p_c016            => t_gi_g_telefono_pre_lqdcion.drccion_lnea,
                                                         p_c017            => t_gi_g_telefono_pre_lqdcion.email,
                                                         p_c018            => null,
                                                         p_c019            => t_gi_g_telefono_pre_lqdcion.nmro_lnea_tlfno,
                                                         p_c020            => 'S',
                                                         p_c022            => 'NUEVO' );

                        exception
                            when others then
                                o_cdgo_rspsta  := 40;
                                o_mnsje_rspsta := 'Error al agregar reponsable a coleccion RESPONSABLES';
                               -- return;
                        end;                    
                    else

                        begin
                            apex_collection.update_member ( p_collection_name => 'RESPONSABLES',
                                                            p_seq             => v_seq_id,
                                                            p_n001            => v_id_instncia_fljo,
                                                            p_c003            => t_gi_g_telefono_pre_lqdcion.cdgo_idntfccion_tpo,
                                                            p_c004            => t_gi_g_telefono_pre_lqdcion.idntfccion,
                                                            p_c005            => t_gi_g_telefono_pre_lqdcion.prmer_nmbre,
                                                            p_c006            => t_gi_g_telefono_pre_lqdcion.sgndo_nmbre,
                                                            p_c007            => t_gi_g_telefono_pre_lqdcion.prmer_aplldo,
                                                            p_c008            => t_gi_g_telefono_pre_lqdcion.sgndo_aplldo,
                                                            p_c009            => 'S',
                                                            p_c010            => 'R',
                                                            p_c013            => t_gi_g_telefono_pre_lqdcion.id_pais,
                                                            p_c014            => t_gi_g_telefono_pre_lqdcion.id_dprtmnto,
                                                            p_c015            => t_gi_g_telefono_pre_lqdcion.id_mncpio,
                                                            p_c016            => t_gi_g_telefono_pre_lqdcion.drccion_lnea,
                                                            p_c017            => t_gi_g_telefono_pre_lqdcion.email,
                                                            p_c018            => null,
                                                            p_c019            => t_gi_g_telefono_pre_lqdcion.nmro_lnea_tlfno,
                                                            p_c020            => 'S',
                                                            p_c022            => 'ACTUALIZADO' ); 

                        exception
                            when others then
                                o_cdgo_rspsta  := 45;
                                o_mnsje_rspsta := 'Error al actualizar coleccion RESPONSABLES';
                              --  return;
                        end;
                    end if;

                end if;
                -------------------------------------------------------------------

                -- Si no existe, se registra la novedad de INSCRIPCION
                pkg_si_novedades_persona.prc_rg_novedad_persona(p_cdgo_clnte            	=> p_cdgo_clnte,
                                                                p_ssion                 	=> v_id_sesion,
                                                                p_id_impsto             	=> p_id_impsto,
                                                                p_id_impsto_sbmpsto     	=> p_id_impsto_sbmpsto,
                                                                p_id_sjto_impsto        	=> null,
                                                                p_id_instncia_fljo      	=> v_id_instncia_fljo,
                                                                p_cdgo_nvdad_tpo        	=> 'INS', -- Inscripcion
                                                                p_obsrvcion             	=> 'Sujeto Impuesto creado desde proceso de teléfono cargue',
                                                                p_id_usrio_rgstro       	=> p_id_usrio,
                                                                -- Datos de Inscripcion --
                                                                p_tpo_prsna               	=> t_gi_g_telefono_pre_lqdcion.tpo_prsna,
                                                                p_cdgo_idntfccion_tpo     	=> t_gi_g_telefono_pre_lqdcion.cdgo_idntfccion_tpo,
                                                                p_idntfccion              	=> t_gi_g_telefono_pre_lqdcion.idntfccion,
                                                                p_prmer_nmbre             	=> t_gi_g_telefono_pre_lqdcion.prmer_nmbre,
                                                                p_sgndo_nmbre             	=> t_gi_g_telefono_pre_lqdcion.sgndo_nmbre,
                                                                p_prmer_aplldo            	=> t_gi_g_telefono_pre_lqdcion.prmer_aplldo,
                                                                p_sgndo_aplldo            	=> nvl(t_gi_g_telefono_pre_lqdcion.sgndo_aplldo,'.'),
                                                                p_nmbre_rzon_scial        	=> t_gi_g_telefono_pre_lqdcion.prmer_nmbre || ' ' ||
																								t_gi_g_telefono_pre_lqdcion.sgndo_nmbre || ' ' ||
																								t_gi_g_telefono_pre_lqdcion.prmer_aplldo || ' ' ||
																								t_gi_g_telefono_pre_lqdcion.sgndo_aplldo,
                                                                p_drccion                 	=> t_gi_g_telefono_pre_lqdcion.drccion_lnea,
                                                                p_id_pais                 	=> t_gi_g_telefono_pre_lqdcion.id_pais,
                                                                p_id_dprtmnto             	=> t_gi_g_telefono_pre_lqdcion.id_dprtmnto,
                                                                p_id_mncpio               	=> t_gi_g_telefono_pre_lqdcion.id_mncpio,
                                                                p_drccion_ntfccion        	=> t_gi_g_telefono_pre_lqdcion.drccion_lnea,
                                                                p_id_pais_ntfccion        	=> t_gi_g_telefono_pre_lqdcion.id_pais,
                                                                p_id_dprtmnto_ntfccion    	=> t_gi_g_telefono_pre_lqdcion.id_dprtmnto,
                                                                p_id_mncpio_ntfccion      	=> t_gi_g_telefono_pre_lqdcion.id_mncpio,
                                                                p_email                   	=> t_gi_g_telefono_pre_lqdcion.email,
                                                                p_tlfno                   	=> null,
                                                                p_cllar                   	=> t_gi_g_telefono_pre_lqdcion.nmro_lnea_tlfno,
                                                                p_nmro_rgstro_cmra_cmrcio	=> null,
                                                                p_fcha_rgstro_cmra_cmrcio 	=> null,
                                                                p_nmro_scrsles            	=> null,
                                                                p_drccion_cmra_cmrcio     	=> null,
                                                                p_id_actvdad_ecnmca       	=> null,
                                                                p_id_sjto_tpo             	=> null,
                                                                -- Fin Datos de Inscripcion --
                                                                o_id_nvdad_prsna 			=> o_id_nvdad_prsna,
                                                                o_cdgo_rspsta    			=> o_cdgo_rspsta,
                                                                o_mnsje_rspsta   			=> o_mnsje_rspsta );

            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'DESPUES DE: prc_rg_novedad_persona  cdgo: ' || o_cdgo_rspsta || ' mnsje: ' || o_mnsje_rspsta, 1);

            if o_cdgo_rspsta <> 0 then
                o_cdgo_rspsta  := 40 ;--|| '-' || o_cdgo_rspsta;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' - Error al registrar la Novedad para crear el sujeto impuesto. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
                rollback;
                return;
            end if;

            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'ANTES DE: prc_ap_novedad_persona', 1);

            pkg_si_novedades_persona.prc_ap_novedad_persona(p_cdgo_clnte     => p_cdgo_clnte,
                                                            p_id_nvdad_prsna => o_id_nvdad_prsna,
                                                            p_id_usrio       => p_id_usrio,
                                                            o_cdgo_rspsta    => o_cdgo_rspsta,
                                                            o_mnsje_rspsta   => o_mnsje_rspsta);

            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'DESPUES DE: prc_ap_novedad_persona', 1);

            --Se busca el sujeto impuesto creado
            select  id_sjto_impsto
            into    o_id_sjto_impsto
            from    si_g_novedades_persona
            where   id_nvdad_prsna = o_id_nvdad_prsna;

            if o_cdgo_rspsta <> 0 then
                o_cdgo_rspsta  := 50 || '-' || o_cdgo_rspsta;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' - Error al aplicar la Novedad para crear el sujeto impuesto. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
                rollback;
                return;
            end if;
    /***
            begin
                apex_session.attach(p_app_id     => 69000,
                                    p_page_id    => 28,
                                    p_session_id => v_id_sesion);
            end; 
        ***/
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Fin del procedimiento - Sujeto creado exitosamente: ' || o_id_sjto_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        end;

    exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al crear sujeto-impuesto ' ;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;

    end prc_rg_sujeto_impuesto;

   /* procedure prc_rg_sujeto_impuesto ( p_cdgo_clnte             in number,
                                       p_id_ssion               in number,
                                       p_id_app_nvddes_prsna    in number, 
                                       p_id_app_page_nvd_prs    in number, 
                                       p_id_usrio               in number,
                                       p_id_impsto              in number,
                                       p_id_impsto_sbmpsto      in number,
                                       p_id_rentas_cargue       in number,
                                       p_id_fljo                in number,
                                       o_id_sjto_impsto         out number,
                                       o_cdgo_rspsta            out number,
                                       o_mnsje_rspsta           out varchar2 ) 
    as
        v_nl                    number;
        v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_sujeto_impuesto';
        v_json                  clob;
        v_error                 varchar2(4000);
        v_fcha_crcion           date;
        t_gi_g_rentas_cargue    gi_g_rentas_cargue%rowtype;
        v_id_sesion             number;
        o_id_nvdad_prsna        number;
        v_id_instncia_fljo      number;
        v_id_fljo_trea          number;
        v_mnsje                 varchar2(1000);
        v_id_fljo_trea_orgen    number;
        v_type_rspsta           varchar2(10);
        v_trea                  number;
        v_seq_id                number;
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);

        -- Se buscan los datos del sujeto
        begin
            select  *
            into    t_gi_g_rentas_cargue
            from    gi_g_rentas_cargue a
            where   id_rentas_cargue = p_id_rentas_cargue;
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  ' - Error al consultar el registro a procesar en la tabla gi_g_rentas_cargue . id_rentas_cargue ' ||
                                  p_id_rentas_cargue;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
        end;

        --Valida que el sujeto no se encuentre registrado
        begin
            select  a.id_sjto_impsto
            into    o_id_sjto_impsto
            from    v_si_i_sujetos_impuesto a
            where   idntfccion_sjto = to_char(t_gi_g_rentas_cargue.idntfccion)
            and     cdgo_clnte = p_cdgo_clnte
            and     id_impsto = p_id_impsto;

            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Existe sujeto: ' ||
                                t_gi_g_rentas_cargue.idntfccion || '-' ||
                                o_id_sjto_impsto,
                                1);

        exception
            when no_data_found then  

                begin
                    apex_session.attach(p_app_id     => p_id_app_nvddes_prsna,
                                        p_page_id    => p_id_app_page_nvd_prs,
                                        p_session_id => p_id_ssion);
                end;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'APEX_UTIL.SET_SESSION_STATE',
                                      1);  

                /*-----------------------------------

                -- Se instancia el flujo de novedades persona
                pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => p_id_fljo,
                                                            p_id_usrio         => p_id_usrio,
                                                            p_id_prtcpte       => null,
                                                            p_obsrvcion        => 'Creación Sujeto Impuestos Cargue Masivo de Teléfono/Telégrafo',
                                                            o_id_instncia_fljo => v_id_instncia_fljo,
                                                            o_id_fljo_trea     => v_id_fljo_trea,
                                                            o_mnsje            => v_mnsje);

                if v_id_instncia_fljo is null then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta ||
                                    ' - Error al registrar la Novedad para crear el sujeto impuesto. ' || v_mnsje;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6 );
                    rollback; 
                    return;
                else
                    commit;
                end if;


                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'v_id_instncia_fljo: '||v_id_instncia_fljo||' - v_id_fljo_trea: '||v_id_fljo_trea,
                                      1);

                APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_CDGO_NVDAD_TPO',
                                            p_value => 'INS');

                APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_RECHAZAR',
                                            p_value => 'N');

                -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                /*pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'Antes de Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.' ||
                                      systimestamp,
                                      1);

                -- Pasa a la siguiente tarea Tipo de Novedades
                begin
                    select  a.id_fljo_trea_orgen
                    into    v_id_fljo_trea_orgen
                    from    wf_g_instancias_transicion a
                    where   a.id_instncia_fljo = v_id_instncia_fljo
                    and     a.id_estdo_trnscion in (1, 2);

                   /*pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Despues de Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea. v_id_fljo_trea_orgen,v_id_instncia_fljo: ' ||
                                            v_id_fljo_trea_orgen || '-' || v_id_instncia_fljo,
                                            1 );

                    -- Se cambia la etapa de flujo
                    pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                     p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                                     p_json             => '[]',
                                                                     o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                                     o_mnsje            => o_mnsje_rspsta,
                                                                     o_id_fljo_trea     => v_id_fljo_trea,
                                                                     o_error            => v_error);

                    /*pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Despues de o_mnsje_rspsta,o_id_fljo_trea,v_error=>' ||
                                          o_mnsje_rspsta || '-' || v_id_fljo_trea || '-' || v_error,
                                          1);                             

                exception
                    when others then
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                                      ' -- ' ;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.	

                while v_trea <= 2 loop
                    -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                    begin
                        select  a.id_fljo_trea_orgen
                        into    v_id_fljo_trea_orgen
                        from    wf_g_instancias_transicion a
                        where   a.id_instncia_fljo = v_id_instncia_fljo
                        and     a.id_estdo_trnscion in (1, 2);

                        -- Se cambia la etapa de flujo
                        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                                         p_json             => '[]',
                                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                                         o_mnsje            => o_mnsje_rspsta,
                                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                                         o_error            => v_error);
                    exception
                        when others then
                          o_cdgo_rspsta  := 30;
                          o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode || ' -- ' ;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' || o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                    end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.

                    v_trea := v_trea + 1;
                end loop;

                --pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null, v_nmbre_up, v_nl, 'DESPUES DE  while v_trea', 1);

                -- Si es persona Jurídica, se crea la colección para el responsbale
                if ( t_gi_g_rentas_cargue.tpo_prsna = 'J' ) then
                    if ( not apex_collection.collection_exists(p_collection_name => 'RESPONSABLES') ) then
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Se crea la colección',  1);                    
                        apex_collection.create_collection(p_collection_name => 'RESPONSABLES');
                    end if;   

                    begin
                        select  seq_id
                        into    v_seq_id
                        from    apex_collections a
                        where   collection_name = 'RESPONSABLES'
                        and     a.n001 = v_id_instncia_fljo
                        and     a.c004 = t_gi_g_rentas_cargue.idntfccion;
                    exception
                        when no_data_found then
                            v_seq_id := null;                    
                    end;

                    if v_seq_id is null then
                        begin
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Se adiciona responsable', 1);
                            apex_collection.add_member ( p_collection_name => 'RESPONSABLES',
                                                         p_n001            => v_id_instncia_fljo,
                                                         p_c003            => t_gi_g_rentas_cargue.cdgo_idntfccion_tpo,
                                                         p_c004            => t_gi_g_rentas_cargue.idntfccion,
                                                         p_c005            => t_gi_g_rentas_cargue.prmer_nmbre,
                                                         p_c006            => t_gi_g_rentas_cargue.sgndo_nmbre,
                                                         p_c007            => t_gi_g_rentas_cargue.prmer_aplldo,
                                                         p_c008            => t_gi_g_rentas_cargue.sgndo_aplldo,
                                                         p_c009            => 'S',
                                                         p_c010            => 'R',
                                                         p_c013            => t_gi_g_rentas_cargue.id_pais,
                                                         p_c014            => t_gi_g_rentas_cargue.id_dprtmnto,
                                                         p_c015            => t_gi_g_rentas_cargue.id_mncpio,
                                                         p_c016            => t_gi_g_rentas_cargue.drccion,
                                                         p_c017            => t_gi_g_rentas_cargue.email,
                                                         p_c018            => t_gi_g_rentas_cargue.tlfno,
                                                         p_c019            => t_gi_g_rentas_cargue.cllar,
                                                         p_c020            => 'S',
                                                         p_c022            => 'NUEVO' );

                        exception
                            when others then
                                o_cdgo_rspsta  := 40;
                                o_mnsje_rspsta := 'Error al agregar reponsable a coleccion RESPONSABLES';
                                return;
                        end;                    
                    else

                        begin
                            apex_collection.update_member ( p_collection_name => 'RESPONSABLES',
                                                            p_seq             => v_seq_id,
                                                            p_n001            => v_id_instncia_fljo,
                                                            p_c003            => t_gi_g_rentas_cargue.cdgo_idntfccion_tpo,
                                                            p_c004            => t_gi_g_rentas_cargue.idntfccion,
                                                            p_c005            => t_gi_g_rentas_cargue.prmer_nmbre,
                                                            p_c006            => t_gi_g_rentas_cargue.sgndo_nmbre,
                                                            p_c007            => t_gi_g_rentas_cargue.prmer_aplldo,
                                                            p_c008            => t_gi_g_rentas_cargue.sgndo_aplldo,
                                                            p_c009            => 'S',
                                                            p_c010            => 'R',
                                                            p_c013            => t_gi_g_rentas_cargue.id_pais,
                                                            p_c014            => t_gi_g_rentas_cargue.id_dprtmnto,
                                                            p_c015            => t_gi_g_rentas_cargue.id_mncpio,
                                                            p_c016            => t_gi_g_rentas_cargue.drccion,
                                                            p_c017            => t_gi_g_rentas_cargue.email,
                                                            p_c018            => t_gi_g_rentas_cargue.tlfno,
                                                            p_c019            => t_gi_g_rentas_cargue.cllar,
                                                            p_c020            => 'S',
                                                            p_c022            => 'ACTUALIZADO' ); 

                        exception
                            when others then
                                o_cdgo_rspsta  := 45;
                                o_mnsje_rspsta := 'Error al actualizar coleccion RESPONSABLES';
                                return;
                        end;
                    end if;

                end if;
                -------------------------------------------------------------------

                -- Si no existe, se registra la novedad de INSCRIPCION
                pkg_si_novedades_persona.prc_rg_novedad_persona(p_cdgo_clnte            	=> p_cdgo_clnte,
                                                                p_ssion                 	=> v_id_sesion,
                                                                p_id_impsto             	=> p_id_impsto,
                                                                p_id_impsto_sbmpsto     	=> p_id_impsto_sbmpsto,
                                                                p_id_sjto_impsto        	=> null,
                                                                p_id_instncia_fljo      	=> v_id_instncia_fljo,
                                                                p_cdgo_nvdad_tpo        	=> 'INS', -- Inscripcion
                                                                p_obsrvcion             	=> 'Sujeto Impuesto creado desde proceso de teléfono cargue',
                                                                p_id_usrio_rgstro       	=> p_id_usrio,
                                                                -- Datos de Inscripcion --
                                                                p_tpo_prsna               	=> t_gi_g_rentas_cargue.tpo_prsna,
                                                                p_cdgo_idntfccion_tpo     	=> t_gi_g_rentas_cargue.cdgo_idntfccion_tpo,
                                                                p_idntfccion              	=> t_gi_g_rentas_cargue.idntfccion,
                                                                p_prmer_nmbre             	=> t_gi_g_rentas_cargue.prmer_nmbre,
                                                                p_sgndo_nmbre             	=> t_gi_g_rentas_cargue.sgndo_nmbre,
                                                                p_prmer_aplldo            	=> t_gi_g_rentas_cargue.prmer_aplldo,
                                                                p_sgndo_aplldo            	=> nvl(t_gi_g_rentas_cargue.sgndo_aplldo,'.'),
                                                                p_nmbre_rzon_scial        	=> t_gi_g_rentas_cargue.prmer_nmbre || ' ' ||
																								t_gi_g_rentas_cargue.sgndo_nmbre || ' ' ||
																								t_gi_g_rentas_cargue.prmer_aplldo || ' ' ||
																								t_gi_g_rentas_cargue.sgndo_aplldo,
                                                                p_drccion                 	=> t_gi_g_rentas_cargue.drccion,
                                                                p_id_pais                 	=> t_gi_g_rentas_cargue.id_pais,
                                                                p_id_dprtmnto             	=> t_gi_g_rentas_cargue.id_dprtmnto,
                                                                p_id_mncpio               	=> t_gi_g_rentas_cargue.id_mncpio,
                                                                p_drccion_ntfccion        	=> t_gi_g_rentas_cargue.drccion,
                                                                p_id_pais_ntfccion        	=> t_gi_g_rentas_cargue.id_pais,
                                                                p_id_dprtmnto_ntfccion    	=> t_gi_g_rentas_cargue.id_dprtmnto,
                                                                p_id_mncpio_ntfccion      	=> t_gi_g_rentas_cargue.id_mncpio,
                                                                p_email                   	=> t_gi_g_rentas_cargue.email,
                                                                p_tlfno                   	=> t_gi_g_rentas_cargue.tlfno,
                                                                p_cllar                   	=> t_gi_g_rentas_cargue.cllar,
                                                                p_nmro_rgstro_cmra_cmrcio	=> t_gi_g_rentas_cargue.nmro_rgstro_cmra_cmrcio,
                                                                p_fcha_rgstro_cmra_cmrcio 	=> to_date(t_gi_g_rentas_cargue.fcha_rgstro_cmra_cmrcio, 'dd/mm/yyyy'),
                                                                p_nmro_scrsles            	=> t_gi_g_rentas_cargue.nmro_scrsles,
                                                                p_drccion_cmra_cmrcio     	=> t_gi_g_rentas_cargue.drccion_cmra_cmrcio,
                                                                p_id_actvdad_ecnmca       	=> replace(t_gi_g_rentas_cargue.id_actvdad_ecnmca, 0, null),
                                                                p_id_sjto_tpo             	=> t_gi_g_rentas_cargue.id_sjto_tpo,
                                                                -- Fin Datos de Inscripcion --
                                                                o_id_nvdad_prsna 			=> o_id_nvdad_prsna,
                                                                o_cdgo_rspsta    			=> o_cdgo_rspsta,
                                                                o_mnsje_rspsta   			=> o_mnsje_rspsta );

            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'DESPUES DE: prc_rg_novedad_persona  cdgo: ' || o_cdgo_rspsta || ' mnsje: ' || o_mnsje_rspsta, 1);

            if o_cdgo_rspsta <> 0 then
                o_cdgo_rspsta  := 40 ;--|| '-' || o_cdgo_rspsta;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' - Error al registrar la Novedad para crear el sujeto impuesto. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
                rollback;
                return;
            end if;

            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'ANTES DE: prc_ap_novedad_persona', 1);

            pkg_si_novedades_persona.prc_ap_novedad_persona(p_cdgo_clnte     => p_cdgo_clnte,
                                                            p_id_nvdad_prsna => o_id_nvdad_prsna,
                                                            p_id_usrio       => p_id_usrio,
                                                            o_cdgo_rspsta    => o_cdgo_rspsta,
                                                            o_mnsje_rspsta   => o_mnsje_rspsta);

            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'DESPUES DE: prc_ap_novedad_persona', 1);

            --Se busca el sujeto impuesto creado
            select  id_sjto_impsto
            into    o_id_sjto_impsto
            from    si_g_novedades_persona
            where   id_nvdad_prsna = o_id_nvdad_prsna;

            if o_cdgo_rspsta <> 0 then
                o_cdgo_rspsta  := 50 || '-' || o_cdgo_rspsta;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' - Error al aplicar la Novedad para crear el sujeto impuesto. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
                rollback;
                return;
            end if;
    /***
            begin
                apex_session.attach(p_app_id     => 69000,
                                    p_page_id    => 28,
                                    p_session_id => v_id_sesion);
            end; 

            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Fin del procedimiento - Sujeto creado exitosamente: ' || o_id_sjto_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        end;

    exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al crear sujeto-impuesto ' ;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;

    end prc_rg_sujeto_impuesto;*/

     procedure prc_rg_liquidacion_telefonos(    p_cdgo_clnte          in number,
                                            p_id_tlfno_pre_lqdcion    in number, 
                                            p_cdgo_indcdor_tpo    in varchar2,
                                            p_id_usrio            in number,
                                            p_entrno              in varchar2 default 'PRVADO',
                                            o_id_lqdcion          out number,
                                            o_cdgo_rspsta         out number,
                                            o_mnsje_rspsta        out varchar2 )
    as    
        --Registra la liquidaci?n de teléfonos*/
        v_nl                    number;
        v_nmbre_up              varchar2(70) := 'pkg_gi_telefonos_cargue.prc_rg_liquidacion_telefonos';
        t_gi_g_telefono_pre_lqdcion    gi_g_telefono_pre_lqdcion%rowtype;
        v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
        v_fcha_vncmnto          df_i_impuestos_acto_concepto.fcha_vncmnto%type;
        v_id_prdo               v_df_i_impuestos_acto_concepto.id_prdo%type;
        v_cdgo_prdcdad          v_df_i_impuestos_acto_concepto.cdgo_prdcdad%type;
        v_vlor_ttal_lqdcion     number;
        v_id_lqdcion_tpo        number;
        v_contador              number := 0;
        --v_indcdor_nrmlza_crtra  gi_d_rntas_cnfgrcion_sbmpst.indcdor_nrmlza_crtra%type;    
    begin

        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entrando id_tlfno_pre_lqdcion: '||p_id_tlfno_pre_lqdcion ,
                              1);

        o_cdgo_rspsta := 0; 

        -- Información del registro
        begin
            select  *
            into    t_gi_g_telefono_pre_lqdcion
            from    gi_g_telefono_pre_lqdcion 
            where   id_tlfno_pre_lqdcion = p_id_tlfno_pre_lqdcion;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el registro a procesar ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;    

        --Se obtiene el tipo de liquidacion
        begin
            select  id_lqdcion_tpo
            into    v_id_lqdcion_tpo
            from    df_i_liquidaciones_tipo
            where   cdgo_clnte = p_cdgo_clnte
            and     id_impsto = t_gi_g_telefono_pre_lqdcion.id_impsto
            and     cdgo_lqdcion_tpo = 'LB';
        exception
            when no_data_found then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al obtener el tipo de liquidaci?n. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;

        -- Se obtiene concepto y fecha de vencimiento
        begin
            select  id_impsto_acto_cncpto   , fcha_vncmnto   , id_prdo   , cdgo_prdcdad
            into    v_id_impsto_acto_cncpto , v_fcha_vncmnto , v_id_prdo , v_cdgo_prdcdad
            from    v_df_i_impuestos_acto_concepto
            where   id_impsto_acto  = t_gi_g_telefono_pre_lqdcion.id_impsto_acto
            and     vgncia          = t_gi_g_telefono_pre_lqdcion.vgncia
            and     id_prdo         = t_gi_g_telefono_pre_lqdcion.id_prdo;
        exception
            when others then
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el impuesto acto concepto. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;

        --Si en el archivo la fecha de vencimiento viene nula, se toma de la parametrica
        --v_fcha_vncmnto := nvl(t_gi_g_telefono_pre_lqdcion.fcha_vncmnto_dcmnto,v_fcha_vncmnto) ;

        -- Se registra la liquidacion
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
               vlor_ttal,
               cdgo_prdcdad,
               id_lqdcion_tpo,
               id_usrio)
            values
              (p_cdgo_clnte,
               t_gi_g_telefono_pre_lqdcion.id_impsto,
               t_gi_g_telefono_pre_lqdcion.id_impsto_sbmpsto,
               t_gi_g_telefono_pre_lqdcion.vgncia,
               v_id_prdo,
               t_gi_g_telefono_pre_lqdcion.id_sjto_impsto,
               sysdate,
               'L',
               t_gi_g_telefono_pre_lqdcion.vlor_bse_grvble,
               t_gi_g_telefono_pre_lqdcion.vlor_cptal,
               v_cdgo_prdcdad,
               v_id_lqdcion_tpo,
               p_id_usrio)
            returning id_lqdcion into o_id_lqdcion;

        exception
            when others then
                o_cdgo_rspsta  := 30;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al registrar la liquidaci?n' ;
                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                rollback;
                return;
        end; -- Fin Se registra la liquidacion


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
                     fcha_vncmnto)
            values
                (o_id_lqdcion,
                 v_id_impsto_acto_cncpto,
                 t_gi_g_telefono_pre_lqdcion.vlor_cptal,
                 t_gi_g_telefono_pre_lqdcion.vlor_cptal,
                 t_gi_g_telefono_pre_lqdcion.trfa,
                 t_gi_g_telefono_pre_lqdcion.vlor_bse_grvble,
                 t_gi_g_telefono_pre_lqdcion.trfa||' '||p_cdgo_indcdor_tpo,
                 0,
                 'N',
                 v_fcha_vncmnto
                 );

        exception
            when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al registrar los conceptos de la liquidaci?n' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; -- Fin Se registran los conceptos de la liquidacion

    end prc_rg_liquidacion_telefonos;


   /* procedure prc_rg_liquidacion_telefonos( p_cdgo_clnte          in number,
                                            p_id_rentas_cargue    in number, 
                                            p_cdgo_indcdor_tpo    in varchar2,
                                            p_id_usrio            in number,
                                            p_entrno              in varchar2 default 'PRVADO',
                                            o_id_lqdcion          out number,
                                            o_cdgo_rspsta         out number,
                                            o_mnsje_rspsta        out varchar2 )
    as    
        --Registra la liquidaci?n de teléfonos
        v_nl                    number;
        v_nmbre_up              varchar2(70) := 'pkg_gi_telefonos_cargue.prc_rg_liquidacion_telefonos';
        t_gi_g_rentas_cargue    gi_g_rentas_cargue%rowtype;
        v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
        v_fcha_vncmnto          df_i_impuestos_acto_concepto.fcha_vncmnto%type;
        v_id_prdo               v_df_i_impuestos_acto_concepto.id_prdo%type;
        v_cdgo_prdcdad          v_df_i_impuestos_acto_concepto.cdgo_prdcdad%type;
        v_vlor_ttal_lqdcion     number;
        v_id_lqdcion_tpo        number;
        v_contador              number := 0;
        v_indcdor_nrmlza_crtra  gi_d_rntas_cnfgrcion_sbmpst.indcdor_nrmlza_crtra%type;    
    begin

        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entrando id_rnta_crgue: '||p_id_rentas_cargue ,
                              1);

        o_cdgo_rspsta := 0; 

        -- Información del registro
        begin
            select  *
            into    t_gi_g_rentas_cargue
            from    gi_g_rentas_cargue
            where   id_rentas_cargue = p_id_rentas_cargue;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el registro a procesar ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;    

        --Se obtiene el tipo de liquidacion
        begin
            select  id_lqdcion_tpo
            into    v_id_lqdcion_tpo
            from    df_i_liquidaciones_tipo
            where   cdgo_clnte = p_cdgo_clnte
            and     id_impsto = t_gi_g_rentas_cargue.id_impsto
            and     cdgo_lqdcion_tpo = 'LB';
        exception
            when no_data_found then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al obtener el tipo de liquidaci?n. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;

        -- Se obtiene concepto y fecha de vencimiento
        begin
            select  id_impsto_acto_cncpto   , fcha_vncmnto   , id_prdo   , cdgo_prdcdad
            into    v_id_impsto_acto_cncpto , v_fcha_vncmnto , v_id_prdo , v_cdgo_prdcdad
            from    v_df_i_impuestos_acto_concepto
            where   id_impsto_acto  = t_gi_g_rentas_cargue.id_impsto_acto
            and     vgncia          = t_gi_g_rentas_cargue.vgncia
            and     prdo            = t_gi_g_rentas_cargue.id_prdo;
        exception
            when others then
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el impuesto acto concepto. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;

        --Si en el archivo la fecha de vencimiento viene nula, se toma de la parametrica
        --v_fcha_vncmnto := nvl(t_gi_g_rentas_cargue.fcha_vncmnto_dcmnto,v_fcha_vncmnto) ;

        -- Se registra la liquidacion
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
               vlor_ttal,
               cdgo_prdcdad,
               id_lqdcion_tpo,
               id_usrio)
            values
              (p_cdgo_clnte,
               t_gi_g_rentas_cargue.id_impsto,
               t_gi_g_rentas_cargue.id_impsto_sbmpsto,
               t_gi_g_rentas_cargue.vgncia,
               v_id_prdo,
               t_gi_g_rentas_cargue.id_sjto_impsto,
               sysdate,
               'L',
               t_gi_g_rentas_cargue.vlor_bse_grvble,
               t_gi_g_rentas_cargue.vlor_cptal,
               v_cdgo_prdcdad,
               v_id_lqdcion_tpo,
               p_id_usrio)
            returning id_lqdcion into o_id_lqdcion;

        exception
            when others then
                o_cdgo_rspsta  := 30;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al registrar la liquidaci?n' ;
                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                rollback;
                return;
        end; -- Fin Se registra la liquidacion


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
                     fcha_vncmnto)
            values
                (o_id_lqdcion,
                 v_id_impsto_acto_cncpto,
                 t_gi_g_rentas_cargue.vlor_cptal,
                 t_gi_g_rentas_cargue.vlor_cptal,
                 t_gi_g_rentas_cargue.trfa,
                 t_gi_g_rentas_cargue.vlor_bse_grvble,
                 t_gi_g_rentas_cargue.trfa||' '||p_cdgo_indcdor_tpo,
                 0,
                 'N',
                 v_fcha_vncmnto
                 );

        exception
            when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al registrar los conceptos de la liquidaci?n' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; -- Fin Se registran los conceptos de la liquidacion


        -- Se realiza el paso a movimientos financieros
        begin
            pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto ( p_cdgo_clnte        => p_cdgo_clnte,
                                                                           p_id_lqdcion        => o_id_lqdcion,
                                                                           p_cdgo_orgen_mvmnto => 'LQ',
                                                                           p_id_orgen_mvmnto   => o_id_lqdcion,
                                                                           o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                           o_mnsje_rspsta      => o_mnsje_rspsta );
            if (o_cdgo_rspsta <> 0) then
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error realizando el paso a movimientos financieros' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
            end if;

        exception
            when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al registrar el paso a movimientos financieros' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; -- Se realiza el paso a movimientos financieros

        o_mnsje_rspsta := 'Liquidacion exitosa ID: :' || o_id_lqdcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

    exception
        when others then
            o_cdgo_rspsta  := 70;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar liquidación: ' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;

    end prc_rg_liquidacion_telefonos;*/


    procedure prc_rg_documento ( p_cdgo_clnte        in number,
                                 p_id_impsto         in number,
                                 p_id_impsto_sbmpsto in number,
                                 p_id_sjto_impsto    in number,
                                 p_id_lqdcion        in number,
                                 p_fcha_vncmnto      in timestamp,
                                 p_nmro_dcmnto       in number,
                                 p_cdgo_dcmnto_tpo   in varchar2,
                                 p_entrno            in varchar2,
                                 o_id_dcmnto         out number,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2 ) 
    as    
        v_nl               number;
        v_nmbre_up         sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_documento';
        v_vlor_ttal_dcmnto re_g_documentos.vlor_ttal%type;
        v_vgncia_prdo      clob;
        v_nmro_dcmnto      varchar2(50);
        v_id_dcmnto        re_g_documentos.id_dcmnto%type;
        v_mnsje_rspsta     varchar2(2000);    
    begin

        -- Codigo respuesta exitoso
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entrando a la UP: ' || v_nmbre_up,
                              1);

        --GENERACION DEL DOCUMENTO 
        begin
            select  sum(vlor_sldo_cptal + vlor_intres) ttal
            into    v_vlor_ttal_dcmnto
            from    v_gf_g_cartera_x_vigencia
            where   id_sjto_impsto = p_id_sjto_impsto
            and     id_orgen = p_id_lqdcion;
        end;
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Total del documento: '||v_vlor_ttal_dcmnto, 1);

        -- Se valida que el total de la cartera sea mayor que cero
        if v_vlor_ttal_dcmnto > 0 then
            -- Se consulta y se genera un json con las vigencias de la cartera
            begin
                select  json_object('VGNCIA_PRDO' value
                                   JSON_ARRAYAGG(json_object('vgncia' value vgncia,
                                                             'prdo' value prdo,
                                                             'id_orgen' value
                                                             id_orgen))) vgncias_prdo
                into    v_vgncia_prdo
                from    (select vgncia, prdo, id_orgen
                         from   v_gf_g_movimientos_financiero
                         where  cdgo_clnte = p_cdgo_clnte
                         and    id_orgen   = p_id_lqdcion);

                -- Se valida que el json tenga informacion
                if v_vgncia_prdo is null then
                    o_cdgo_rspsta  := 1;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                    ': Json con las vigencias de la cartera es nulo';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                    rollback;
                    return;
                end if; -- Fin Se valida que el json tenga informacion

            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_vgncia_prdo: '||v_vgncia_prdo, 1);

            exception
                when others then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                    ': Error al consultar y se crear un json con las vigencias de la cartera' ||
                                    sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1 );
                    rollback;
                    return;
            end; -- Fin Se consulta y se genera un json con las vigencias de la cartera

            -- Generacion del documento
            begin

                v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                         p_cdgo_cnsctvo => 'DOC');

                begin
                    v_mnsje_rspsta := 'p_cdgo_clnte: ' || p_cdgo_clnte ||
                                    ' p_id_impsto: ' || p_id_impsto ||
                                    ' p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                                    ' p_cdna_vgncia_prdo: ' || v_vgncia_prdo ||
                                    ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                                    ' p_fcha_vncmnto: ' || p_fcha_vncmnto ||
                                    ' p_cdgo_dcmnto_tpo: ' || p_cdgo_dcmnto_tpo ||
                                    ' p_nmro_dcmnto: ' || v_nmro_dcmnto ||
                                    ' p_vlor_ttal_dcmnto: ' || v_vlor_ttal_dcmnto ||
                                    ' p_indcdor_entrno: ' || p_entrno;

                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);

                    v_id_dcmnto := pkg_re_documentos.fnc_gn_documento ( p_cdgo_clnte          => p_cdgo_clnte,
                                                                        p_id_impsto           => p_id_impsto,
                                                                        p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                                        p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                                        p_cdna_vgncia_prdo_ps => null,
                                                                        p_id_dcmnto_lte       => null,
                                                                        p_id_sjto_impsto      => p_id_sjto_impsto,
                                                                        p_fcha_vncmnto        => p_fcha_vncmnto,
                                                                        p_cdgo_dcmnto_tpo     => p_cdgo_dcmnto_tpo,
                                                                        p_nmro_dcmnto         => v_nmro_dcmnto,
                                                                        p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                                        p_indcdor_entrno      => p_entrno,
                                                                        p_id_orgen_gnra       => p_id_lqdcion,
                                                                        p_cdgo_mvmnto_orgn    => 'LQ' );

                    if v_id_dcmnto is null then
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                          ': Error al generar el documento. p_nmro_dcmnto:' ||
                                          p_nmro_dcmnto || ' v_id_dcmnto: ' ||
                                          v_id_dcmnto;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end if;

                    o_id_dcmnto := v_id_dcmnto;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'p_nmro_dcmnto: ' || p_nmro_dcmnto ||
                                            ' v_id_dcmnto' || v_id_dcmnto,
                                            1);

                exception
                    when others then
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                          ': Error al generar el documento. ' ||
                                          p_fcha_vncmnto || ' - ' ;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                end;
            end; -- FIN Generacion del documento
        end if;

    exception
        when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al generar el documento: ' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
            rollback;

    end prc_rg_documento;

procedure prc_rg_informacion_telefono(
                                            p_cdgo_clnte              in number,
                                            p_id_infrmcion_telefono   in number,
                                            p_id_usrio                in number,
                                            p_impsto                  in number,
                                            p_impsto_sbmpsto          in number)
    as
    v_nl                         number;
    nmbre_up                     varchar2(200) := 'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono';
    v_gi_g_informacion_telefono  gi_g_informacion_telefono%rowtype;
    v_extnsion_archvo            varchar2(10);
    v_lneas_encbzdo              number;
    v_id_impsto_sbmpsto          number;
    v_id_prdo                    number;       
    v_nmbre_archvo               varchar2(100);
    v_tpo_archvo                 number;
    v_count                      number := 0;
    v_cant_hojas                 number;
    v_error_msg                  varchar2(4000);
    v_id_lqdcion                 number;
    v_tpo_prsna                  varchar(20);  
    o_cdgo_rspsta                number;
    o_mnsje_rspsta               varchar2(4000);
begin
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';

    --Determinamos el nivel de log
   v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono', v_nl, 'Entrando:' || systimestamp, 1);

    -- Obtener informacion cargada del impuesto telefonía y telegrafo(Archivo)
    begin
        select *
        into v_gi_g_informacion_telefono
        from gi_g_informacion_telefono
        where id_infrmcion_telefono = p_id_infrmcion_telefono;
    exception
        when no_data_found then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := 'Error al intentar obtener la informacion de archivo de Telefonía.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
            return;
        when others then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo de Telefonía.';
           pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
            return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'se obtuvo el archivo:' || systimestamp, 1);
    v_extnsion_archvo := substr(v_gi_g_informacion_telefono.file_name, (instr(v_gi_g_informacion_telefono.file_name, '.', -3) + 1), instr(v_gi_g_informacion_telefono.file_name, '.', -3));

    --hallar nombre, encabezado y cantidad de hojas del tipo de archivo EXCEL para darle procesamiento a la información
    begin
        select b.nmbre, b.lneas_encbzdo, b.cant_hojas, b.id_telefono_archvo_tpo
        into v_nmbre_archvo, v_lneas_encbzdo, v_cant_hojas, v_tpo_archvo
        from gi_g_informacion_telefono a
        join df_i_telefono_archivo_tipo b on a.id_telefono_archvo_tpo = b.id_telefono_archvo_tpo 
        where a.id_infrmcion_telefono = p_id_infrmcion_telefono;
    exception
        when no_data_found then
            o_cdgo_rspsta := 11;
            o_mnsje_rspsta := 'Error al intentar obtener nombre archivo, lineas del encabezado o cantidad des hojas a procesar.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
            return;
        when others then
            o_cdgo_rspsta := 11;
            o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo de telefonía.';
     --       pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
            return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'se encontro la data:' || systimestamp, 1);
    --PROCESAR ARCHIVO DE EXCEL   
  if v_extnsion_archvo = 'xlsx' and v_cant_hojas = 1 and v_tpo_archvo= 1 then
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'entrando al if:' || systimestamp, 1);
        -- Obtener informacion cargada(Archivo)
        begin
            select 
                *
            into v_gi_g_informacion_telefono
            from gi_g_informacion_telefono
            where id_infrmcion_telefono = p_id_infrmcion_telefono;
        exception
            when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al intentar obtener la informacion del archivo';
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Problemas al consultar la informacion del archivo.' ;
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        -- Procesar la hoja encontrada en el archivo
            -- Procesar hoja
            for c_datos in (
                select line_number,
                       decode(col001, 'ENERO',1597,'FEBRERO',1598,'MARZO',1599,'ABRIL',1600,
                       'MAYO',1601,'JUNIO',1602,'JULIO',1603,'AGOSTO',1604,'SEPTIEMBRE',1605,'OCTUBRE',1606,
                       'NOVIEMBRE',1607,'DICIEMBRE',1608) as periodo,
                       col002,
                       col003,
                       col004,
                       col005,
                       col006,
                       col007,
                       col008,
                       decode(col009,'HABITACIONAL - 1',396,'HABITACIONAL - 2',397
                        ,'HABITACIONAL - 3',398,'HABITACIONAL - 4',399,'HABITACIONAL - 5',400,
                        'HABITACIONAL - 6',401,'INDUSTRIAL',403,'COMERCIAL - SERVICIOS',402,
                        'OTROS NO RESIDENCIALES',404) as destinacion,
                       col010,
                       col011,
                       col012,
                       to_number(replace(col013,'.',','))as col013,
                       col014,
                       to_number(trunc(replace(col015,'.',','))) as col015
                from gi_g_informacion_telefono a
                cross join table(
                    apex_data_parser.parse(
                        p_content => a.file_blob,
                        p_file_name => a.file_name,
                        p_xlsx_sheet_name => 'sheet1.xml',
                        p_skip_rows => 1                       
                    )
                )
                where a.id_infrmcion_telefono = p_id_infrmcion_telefono
                and not (col001 is null and col002 is null and col003 is  null
                and col004 is  null and col005 is  null and col006 is null and col007 is  null
                and col008 is  null and col009 is  null and col010 is  null
                and col011 is  null and col012 is null and col013 is  null and col014 is  null
                and col015 is  null)
            ) loop
                -- Inicializar mensaje de error
                v_error_msg := null;

               if  c_datos.col004 = 'C' then 
                    v_tpo_prsna := 'N';
               elsif c_datos.col004 = 'N' then
                    v_tpo_prsna := 'J';
                else
                     v_tpo_prsna := 'N';
                end if;

                -- Validar que los datos no vengan vacíos
                if c_datos.periodo is null or
                   c_datos.col002 is null or
                   c_datos.col003 is null or
                   c_datos.col004 is null or
                   c_datos.col005 is null or
                   c_datos.col006 is null or
                   c_datos.col007 is null or
                   c_datos.col008 is null or
                   c_datos.destinacion is null or
                   c_datos.col010 is null or
                   c_datos.col011 is null or
                   c_datos.col012 is null or
                   c_datos.col013 is null or
                   c_datos.col014 is null or
                   c_datos.col015 is null then
                   v_error_msg := 'Dato o Datos vacíos en la fila ' || c_datos.line_number;
                end if;

                -- Validar tipos de datos de cada columna que no pueda estár vacia
                if v_error_msg is null then
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Entrando al if del mensaje de error:' || systimestamp, 6);
                    if not fnc_validar_numerico  (c_datos.periodo) then
                       v_error_msg:= v_error_msg || 'El tipo de dato no es valido columna 1, fila ' || c_datos.line_number;
                       c_datos.periodo := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.col002) then
                       v_error_msg:= v_error_msg || 'El tipo de dato no es valido columna 2, fila ' || c_datos.line_number;
                       c_datos.col002 := null; 
                    end if;
                    if not fnc_validar_caracter(c_datos.col004) then
                        v_error_msg:= v_error_msg ||'El tipo de dato no es valido, columna 4, fila ' || c_datos.line_number;
                        c_datos.col004 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col005) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido, columna 5, fila ' || c_datos.line_number;
                         c_datos.col005 := null; 
                    end if;
                    if not fnc_validar_correo(c_datos.col006) then
                         v_error_msg:= v_error_msg ||'No es un correo valido, columna 6, fila ' || c_datos.line_number;
                         c_datos.col006 := null; 
                    end if;
                    if not fnc_validar_telefono(c_datos.col008) then
                        v_error_msg:= v_error_msg || 'No es un teléfono valido, columna 8, fila ' || c_datos.line_number;
                        c_datos.col008 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col010) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido, columna 10, fila ' || c_datos.line_number;
                         c_datos.col010 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col012) then 
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido, columna 12, fila ' || c_datos.line_number;
                         c_datos.col012 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col013) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,Columna 13, fila' || c_datos.line_number;
                         c_datos.col013 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col014) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido, columna 14, fila ' || c_datos.line_number;
                         c_datos.col014 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col015) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es Valido,columna 15, fila ' || c_datos.line_number;
                         c_datos.col015 := null; 
                    end if;
                end if;

                -- Insertar en la tabla con estado y observación
                insert into gi_g_telefono_pre_lqdcion (
                    id_prdo, -- 1
                    vgncia, -- 2
                    prmer_nmbre, -- 3
                    sgndo_nmbre, -- .
                    prmer_aplldo, -- .
                    sgndo_aplldo,-- . 
                    cdgo_idntfccion_tpo, -- 4
                    idntfccion, -- 5
                    email, -- 6
                    drccion_lnea, -- 7
                    nmro_lnea_tlfno, -- 8
                    id_impsto_acto, -- 9
                    estrato, --10
                    nmro_cntrto, --12
                    trfa, -- 13
                    vlor_bse_grvble, --14
                    vlor_cptal, --15
                    id_impsto,
                    id_impsto_sbmpsto,
                    nmero_lnea,
                    id_dprtmnto, --21
                    id_mncpio, -- 22
                    tpo_prsna,   
                    estdo,
                    obsrvcion,
                    id_infrmcion_telefono
                ) values (
                    c_datos.periodo,
                    c_datos.col002,
                    c_datos.col003,
                    null,
                    '.',
                    null,
                    c_datos.col004,
                    c_datos.col005, 
                    c_datos.col006,
                    c_datos.col007,
                    c_datos.col008,
                    c_datos.destinacion,
                    c_datos.col010,
                    c_datos.col012,
                    c_datos.col013,
                    c_datos.col014,
                    c_datos.col015,
                    p_impsto,
                    p_impsto_sbmpsto,
                    null,
                    null,
                    null,
                    v_tpo_prsna,
                    case 
                        when v_error_msg is null then 'PROCESADO'
                        else 'SIN PROCESAR'
                    end,
                    v_error_msg,
                    p_id_infrmcion_telefono
                );
                commit;
            end loop;

     elsif v_extnsion_archvo = 'xlsx' and v_cant_hojas = 1 and v_tpo_archvo= 2 then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'entrando al if archivo tipo 2:' || systimestamp, 1);
        -- Obtener informacion cargada(Archivo)
        begin
            select 
                *
            into v_gi_g_informacion_telefono
            from gi_g_informacion_telefono
            where id_infrmcion_telefono = p_id_infrmcion_telefono;
        exception
            when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al intentar obtener la informacion del archivo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Problemas al consultar la informacion del archivo.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        -- Procesar la hoja encontrada en el archivo
            -- Procesar hoja
            begin
            for c_datos in (
                select line_number,
                       col001,
                       decode(col002, 'ENERO',1597,'FEBRERO',1598,'MARZO',1599,'ABRIL',1600,
                       'MAYO',1601,'JUNIO',1602,'JULIO',1603,'AGOSTO',1604,'SEPTIEMBRE',1605,'OCTUBRE',1606,
                       'NOVIEMBRE',1607,'DICIEMBRE',1608) as periodo,
                       col003,
                       col004,
                       col005,
                       col006,
                       decode(col007,'HABITACIONAL - 1',396,'HABITACIONAL - 2',397
                        ,'HABITACIONAL - 3',398,'HABITACIONAL - 4',399,'HABITACIONAL - 5',400,
                        'HABITACIONAL - 6',401,'INDUSTRIAL',403,'COMERCIAL - SERVICIOS',402,
                        'OTROS NO RESIDENCIALES',404) as destinacion,
                       col008,
                       col009,
                       col010,
                       col011,
                       col012,
                       to_number(replace(col013,'.',','))as col013,
                       to_number(trunc(replace(col014,'.',','))) as col014
                from gi_g_informacion_telefono a
                cross join table(
                    apex_data_parser.parse(
                        p_content => a.file_blob,
                        p_file_name => a.file_name,
                        p_xlsx_sheet_name => 'sheet1.xml',
                        p_skip_rows => 1                       
                    )
                )
                where a.id_infrmcion_telefono = p_id_infrmcion_telefono
                and not (col001 is null and col002 is null and col003 is  null
                and col004 is  null and col005 is  null and col006 is null and col007 is  null
                and col008 is  null and col009 is  null and col010 is  null
                and col011 is  null and col012 is null and col013 is  null and col014 is null)
            ) loop
                -- Inicializar mensaje de error
                v_error_msg := null;
                v_id_lqdcion := null;
            -- insert into muerto (d_001,c_001,v_001,v_002) values (sysdate,v_error_msg,'PRUEBA1',c_datos.col005 );
                -- Validar que los datos no vengan vacíos
               if  c_datos.col001 is null or
                   c_datos.periodo is null or
                   c_datos.col003 is null or
                   c_datos.col004 is null or
                   c_datos.col005 is null or
                   c_datos.col006 is null or
                   c_datos.destinacion is null or
                   c_datos.col008 is null or
                   c_datos.col009 is null or
                   c_datos.col010 is null or
                   c_datos.col011 is null or
                   c_datos.col012 is null or
                   c_datos.col013 is null or
                   c_datos.col014 is null then
                   v_error_msg := 'Dato o Datos vacíos en la fila ' || c_datos.line_number;
          --  insert into muerto (d_001,c_001,v_001,v_002) values (sysdate,v_error_msg,'PRUEBA2',c_datos.col005 );
                end if;

                -- Validar tipos de datos de cada columna que no pueda estár vacia
              --  if v_error_msg is null then
                begin 
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Entrando al if del mensaje de error:' || systimestamp, 1);
                    if not fnc_validar_numerico(c_datos.col001) then
                       v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 1, fila ' || c_datos.line_number;
                       c_datos.col001 := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.periodo) then
                       v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 2, fila  ' || c_datos.line_number;
                       c_datos.periodo := null;
                    end if;
                    if not fnc_validar_caracter(c_datos.col004) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 4, fila  ' || c_datos.line_number;
                         c_datos.col004 := null;
                   end if;
                    if not fnc_validar_numerico(c_datos.col005) then
                        v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 5, fila  ' || c_datos.line_number;
                        c_datos.col005 := null;
                    end if;
                    if not fnc_validar_correo(c_datos.col006) then
                         v_error_msg:= v_error_msg || 'No es un correo valido, columna 6, fila ' || c_datos.line_number; 
                         c_datos.col006 := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.col008) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 8, fila ' || c_datos.line_number;
                         c_datos.col008 := null;
                    end if;
                    if not fnc_validar_telefono(c_datos.col010) then
                         v_error_msg:= v_error_msg || 'No es un telefono valido, columna 10, fila ' || c_datos.line_number;
                         c_datos.col010 := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.col012) then 
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 12, fila  ' || c_datos.line_number;
                         c_datos.col012 := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.col013) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 13, fila  ' || c_datos.line_number;
                         c_datos.col013 := null;
                    end if;
                    if not fnc_validar_numerico(c_datos.col014) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 14, fila  ' || c_datos.line_number;
                         c_datos.col014 := null;
                    end if;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Saiento del if del mensaje de error:' || systimestamp, 1);
                    exception 
                        when others then
                         o_cdgo_rspsta := 50;
                         o_mnsje_rspsta := 'Error al validar los datos';
                         pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta ||' '|| sqlerrm, 6);
                    end;

               -- end if;
                    --   insert into muerto (d_001,c_001,v_001,v_002) values (sysdate,v_error_msg,'PRUEBA3',c_datos.col005 );
                   begin 
                    select id_lqdcion
                    into   v_id_lqdcion
                    from   gi_g_telefono_pre_lqdcion
                    where  vgncia = c_datos.col001 and  nmro_cntrto = c_datos.col012
                            and id_prdo = c_datos.periodo;  
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Consulta liquidacion' || v_id_lqdcion, 1);
                    exception
                        when no_data_found then
                          --  o_cdgo_rspsta := 10;
                            begin -- Insertar en la tabla con estado y observación
                                insert into gi_g_telefono_recaudo (
                                    id_prdo, --2
                                    vgncia ,-- 1
                                    prmer_nmbre, --3
                                    prmer_apllido, -- '.'
                                    cdgo_idntfccion_tpo, --4
                                    idntfccion, -- 5
                                    email, --6
                                    id_impsto_acto, --7
                                    estrato,-- 8
                                    drccion, --9
                                    nmro_lnea_tlfno, -- 10
                                    nmro_cntrto ,--12
                                    trfa, --13
                                    vlor_rcdo, --14 
                                    id_lqdcion,
                                    id_impsto,
                                    id_impsto_sbmpsto,
                                    cdgo_clnte,
                                    drccion_instlcion, --11
                                    estdo,
                                    obsrvcion,
                                    id_infrmcion_telefono
                                   ) values (
                                    c_datos.periodo,
                                    c_datos.col001,
                                    c_datos.col003,
                                    '.',
                                    c_datos.col004,
                                    c_datos.col005,
                                    c_datos.col006,
                                    c_datos.destinacion,
                                    c_datos.col008,
                                    c_datos.col009,
                                    c_datos.col010,
                                    c_datos.col012,
                                    to_number(replace(c_datos.col013,'.',',')),
                                    to_number(trunc(replace(c_datos.col014,'.',','))),
                                    null,
                                    p_impsto,
                                    p_impsto_sbmpsto,
                                    p_cdgo_clnte,
                                    c_datos.col011,
                                    'SIN PROCESAR',
                                    'No existe una liquidación para esta identificación '|| c_datos.col005,
                                    p_id_infrmcion_telefono
                                );
                                commit;

                            exception
                                when others then
                                o_cdgo_rspsta := 10;
                                o_mnsje_rspsta := 'Error al insertar datos en el archivo 2';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
                                rollback;
                             --   return;

                         end;
                           --  o_mnsje_rspsta := 'Error al intentar obtener el id de la liquidacion';          
                        end; 


              if v_id_lqdcion is not null then 
               begin -- Insertar en la tabla con estado y observación
                insert into gi_g_telefono_recaudo (
                    id_prdo, --2
                    vgncia ,-- 1
                    prmer_nmbre, --3
                    prmer_apllido, -- '.'
                    cdgo_idntfccion_tpo, --4
                    idntfccion, -- 5
                    email, --6
                    id_impsto_acto, --7
                    estrato,-- 8
                    drccion, --9
                    nmro_lnea_tlfno, -- 10
                    nmro_cntrto ,--12
                    trfa, --13
                    vlor_rcdo, --14 
                    id_lqdcion,
                    id_impsto,
                    id_impsto_sbmpsto,
                    cdgo_clnte,
                    drccion_instlcion, --11
                    estdo,
                    obsrvcion,
                    id_infrmcion_telefono
                   ) values (
                    c_datos.periodo,
                    c_datos.col001,
                    c_datos.col003,
                    '.',
                    c_datos.col004,
                    c_datos.col005,
                    c_datos.col006,
                    c_datos.destinacion,
                    c_datos.col008,
                    c_datos.col009,
                    c_datos.col010,
                    c_datos.col012,
                    to_number(replace(c_datos.col013,'.',',')),
                    to_number(trunc(replace(c_datos.col014,'.',','))),
                    v_id_lqdcion,
                    p_impsto,
                    p_impsto_sbmpsto,
                    p_cdgo_clnte,
                    c_datos.col011,
                    case 
                        when v_error_msg is null then 'PROCESADO'
                        else 'SIN PROCESAR'
                    end,
                    v_error_msg,
                    p_id_infrmcion_telefono
                );
                commit;
            exception
                when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al insertar datos en el archivo 2';
               -- rollback;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta || sqlerrm, 1);
             --   return;
                end;
            end if;
            end loop;

            exception
            when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al procesar Archivo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
                return;
          end;


    elsif v_extnsion_archvo = 'xlsx' and v_cant_hojas = 1 and v_tpo_archvo= 3 then
    begin 
         --   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'entrando al if archivo tipo 2:' || systimestamp, 6);
        -- Obtener informacion cargada(Archivo)
        begin
            select 
                *
            into v_gi_g_informacion_telefono
            from gi_g_informacion_telefono
            where id_infrmcion_telefono = p_id_infrmcion_telefono;
        exception
            when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al intentar obtener la informacion del archivo';
            --    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Problemas al consultar la informacion del archivo.';
             --   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        -- Procesar la hoja encontrada en el archivo de cartera
            -- Procesar hoja
            for c_datos in (
                select line_number,
                       col001,
                       decode(col002, 'ENERO',1597,'FEBRERO',1598,'MARZO',1599,'ABRIL',1600,
                       'MAYO',1601,'JUNIO',1602,'JULIO',1603,'AGOSTO',1604,'SEPTIEMBRE',1605,'OCTUBRE',1606,
                       'NOVIEMBRE',1607,'DICIEMBRE',1608) as periodo,
                       col003,
                       col004,
                       col005,
                       col006,
                      decode(col007,'HABITACIONAL - 1',396,'HABITACIONAL - 2',397
                        ,'HABITACIONAL - 3',398,'HABITACIONAL - 4',399,'HABITACIONAL - 5',400,
                        'HABITACIONAL - 6',401,'INDUSTRIAL',403,'COMERCIAL - SERVICIOS',402,
                        'OTROS NO RESIDENCIALES',404) as destinacion,
                       col008,
                       col009,
                       col010,
                       col011,
                       col012,
                       to_number(replace(col013,'.',',')) as col013
                from gi_g_informacion_telefono a
                cross join table(
                    apex_data_parser.parse(
                        p_content => a.file_blob,
                        p_file_name => a.file_name,
                        p_xlsx_sheet_name => 'sheet1.xml',
                        p_skip_rows => 1                       
                    )
                )
                where a.id_infrmcion_telefono = p_id_infrmcion_telefono
                 and not (col001 is null and col002 is null and col003 is  null
                and col004 is  null and col005 is  null and col006 is null and col007 is  null
                and col008 is  null and col009 is  null and col010 is  null
                and col011 is  null and col012 is null and col013 is  null)
            ) loop
                -- Inicializar mensaje de error
                v_error_msg := null;
                v_id_lqdcion := null;

                -- Validar que los datos no vengan vacíos
                if c_datos.col001 is null or
                   c_datos.periodo is null or
                   c_datos.col003 is null or
                   c_datos.col004 is null or
                   c_datos.col005 is null or
                   c_datos.col006 is null or
                   c_datos.destinacion is null or
                   c_datos.col008 is null or
                   c_datos.col009 is null or
                   c_datos.col010 is null or
                   c_datos.col011 is null or
                   c_datos.col012 is null or
                   c_datos.col013 is null then
                   v_error_msg := 'Datos vacíos en la fila ' || c_datos.line_number;
                end if;

                -- Validar tipos de datos de cada columna que no pueda estár vacia
                if v_error_msg is null then
             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Entrando al if del mensaje de error:' || systimestamp, 6);
                    if not fnc_validar_numerico(c_datos.col001) then
                       v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 1, fila ' || c_datos.line_number;
                       c_datos.col001 := null; 
                    end if;
                    if not fnc_validar_caracter(c_datos.col004) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 4, fila ' || c_datos.line_number;
                         c_datos.col004 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col005) then
                        v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 5, fila  ' || c_datos.line_number;
                        c_datos.col005 := null; 
                    end if;
                    if not fnc_validar_correo(c_datos.col006) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 6, fila  ' || c_datos.line_number;
                         c_datos.col006 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col008) then
                         v_error_msg:= v_error_msg ||'El tipo de dato no es valido,columna 8, fila  ' || c_datos.line_number;
                         c_datos.col008 := null; 
                    end if;
                    if not fnc_validar_telefono(c_datos.col010) then
                         v_error_msg:= v_error_msg || 'No es un telefono valido, columna en la fila ' || c_datos.line_number;
                         c_datos.col010 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col011) then 
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 11, fila  ' || c_datos.line_number;
                         c_datos.col011 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col012) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 12, fila  ' || c_datos.line_number;
                         c_datos.col012 := null; 
                    end if;
                    if not fnc_validar_numerico(c_datos.col013) then
                         v_error_msg:= v_error_msg || 'El tipo de dato no es valido,columna 13, fila  ' || c_datos.line_number;
                         c_datos.col013 := null; 
                    end if;
                end if;


                begin 
                    select id_lqdcion
                    into   v_id_lqdcion
                    from   gi_g_telefono_pre_lqdcion
                    where  vgncia = c_datos.col001 and  nmro_cntrto = c_datos.col011
                            and id_prdo = c_datos.periodo;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Consulta liquidacion' || v_id_lqdcion, 1);
                    exception
                        when no_data_found then
                          --  o_cdgo_rspsta := 10;
                          --  o_mnsje_rspsta := 'Error al intentar obtener el id de la liquidacion';
                         --   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                        -- return; 
                    begin -- Insertar en la tabla con estado y observación
                            insert into gi_g_telefono_cartera (
                                id_prdo, --2
                                vgncia ,-- 1
                                prmer_nmbre, --3
                                cdgo_idntfccion_tpo, --4
                                idntfccion, -- 5
                                email, --6
                                id_impsto_acto, --7
                                estrato,-- 8
                                drccion_lnea, --9
                                nmro_lnea_tlfno, -- 10
                                nmro_cntrto ,--11
                                nmro_fctras, --12,
                                trfa, --13
                                id_lqdcion,
                                id_impsto,
                                id_impsto_sbmpsto,
                                cdgo_clnte,
                                estdo,
                                obsrvcion,
                                id_infrmcion_telefono
                               ) values (
                                c_datos.periodo,
                                c_datos.col001, -- vigencia
                                c_datos.col003, -- prmer_nmbre
                                c_datos.col004, -- cdgo_indentificacion
                                c_datos.col005, -- idntfccion
                                c_datos.col006, -- correo
                                c_datos.destinacion,
                                c_datos.col008, -- estrato
                                c_datos.col009, --drccion
                                c_datos.col010, -- nmro_lnea_tlfno
                                c_datos.col011, -- contrato
                                c_datos.col012, --nmro_facturas
                                to_number(replace(c_datos.col013,'.',',')),
                                null,
                                p_impsto,
                                p_impsto_sbmpsto,
                                p_cdgo_clnte,
                                'SIN PROCESAR',
                                'No existe una liquidación para esta identificación ' || c_datos.col005,
                                p_id_infrmcion_telefono
                            );
                            commit;
                        exception
                            when others then
                            o_cdgo_rspsta := 10;
                            o_mnsje_rspsta := 'Error al insertar datos en el archivo de cartera';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
                            rollback;
                         --   return;
                            end;
                end; 

               if v_id_lqdcion is not null then
               begin -- Insertar en la tabla con estado y observación
                insert into gi_g_telefono_cartera (
                    id_prdo, --2
                    vgncia ,-- 1
                    prmer_nmbre, --3
                    cdgo_idntfccion_tpo, --4
                    idntfccion, -- 5
                    email, --6
                    id_impsto_acto, --7
                    estrato,-- 8
                    drccion_lnea, --9
                    nmro_lnea_tlfno, -- 10
                    nmro_cntrto ,--11
                    nmro_fctras, --12,
                    trfa, --13
                    id_lqdcion,
                    id_impsto,
                    id_impsto_sbmpsto,
                    cdgo_clnte,
                    estdo,
                    obsrvcion,
                    id_infrmcion_telefono
                   ) values (
                    c_datos.periodo,
                    c_datos.col001, -- vigencia
                    c_datos.col003, -- prmer_nmbre
                    c_datos.col004, -- cdgo_indentificacion
                    c_datos.col005, -- idntfccion
                    c_datos.col006, -- correo
                    c_datos.destinacion,
                    c_datos.col008, -- estrato
                    c_datos.col009, --drccion
                    c_datos.col010, -- nmro_lnea_tlfno
                    c_datos.col011, -- contrato
                    c_datos.col012, --nmro_facturas
                    to_number(replace(c_datos.col013,'.',',')),
                    v_id_lqdcion,
                    p_impsto,
                    p_impsto_sbmpsto,
                    p_cdgo_clnte,
                    case 
                        when v_error_msg is null then 'PROCESADO'
                        else 'SIN PROCESAR'
                    end,
                    v_error_msg,
                    p_id_infrmcion_telefono
                );
                commit;
            exception
                when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al insertar datos en el archivo de cartera';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
              --  rollback;
             --   return;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta || sqlerrm, 1);
                end;
            end if;
            end loop;
             exception
            when no_data_found then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al procesar Archivo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
                return;
         end;

     end if;

        --cambiar el indicador procesado al archivo
        update gi_g_informacion_telefono 
        set indcdor_prcsdo = 'S' 
        where id_infrmcion_telefono = p_id_infrmcion_telefono;

        commit;
        				---- Consulta envio programado
 declare
      v_json_parametros clob;
    begin
      select json_object (key 'P_ID_USRIO' is p_id_usrio)
        into v_json_parametros
        from dual;

       pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'EJECUCION_TERMINADA',
                                              p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;
       -- o_mnsje_rspsta := 'Actualizar indicador procesado para: ' || p_id_infrmcion_telefono ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
    exception
        when others then
            rollback;
            o_cdgo_rspsta := 99;
--            o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar información de impuesto de telefonía. ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Error al registrar informacion', 6);
            return;

end prc_rg_informacion_telefono;

procedure prc_rg_informacion_telefono_job   (p_cdgo_clnte           in number,
                                              p_id_infrmcion_telefono in number,
                                              p_id_usrio              in number,
                                              p_impsto                in number,
                                              p_impsto_sbmpsto        in number,
                                              o_cdgo_rspsta           out number,
                                              o_mnsje_rspsta          out varchar2)
as  
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono_job';


  -- Se crea el Job 
    begin
     o_cdgo_rspsta:= 0;
     o_mnsje_rspsta:='OK';
        v_nmbre_job := 'IT_PRC_RG_INFO_TELEFONO';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando al segundo begin' || systimestamp, 1);
    begin
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_GI_TELEFONOS_CARGUE.PRC_RG_INFORMACION_TELEFONO',
                                number_of_arguments => 5,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);

      -- Se le asignan al job los parametros para ejecutarse
  dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                           argument_position  => 1,
                                            argument_value    => p_cdgo_clnte);

  dbms_scheduler.set_job_argument_value   (job_name           => v_nmbre_job,
                                           argument_position  => 2,
                                            argument_value    => p_id_infrmcion_telefono);

  dbms_scheduler.set_job_argument_value     (job_name          => v_nmbre_job,
                                             argument_position => 3,
                                             argument_value    => p_id_usrio);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                             argument_position  => 4,
                                             argument_value     => p_impsto);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                              argument_position => 5,
                                              argument_value    => p_impsto_sbmpsto);


      -- Se habilita el job
     dbms_scheduler.enable(name => v_nmbre_job);
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'activando job' || systimestamp, 1);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
       --- return; 
   end;

  end prc_rg_informacion_telefono_job;


-- Procedimiento para registrar la liquidacion cargada en el archivo Pre-liquidacion
procedure prc_rg_telefonos_cargue_liquidacion ( p_cdgo_clnte           in number,
                                                p_id_ssion                  in number,
                                                p_id_app                    in number,
                                                p_id_page_app               in number,
                                                p_id_usrio                  in number,
                                                p_id_impsto                 in number,
                                                p_id_infrmcion_telefono     in number,
                                                p_idntfccion                in varchar2) 
    as    
        v_nl                number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_telefonos_cargue_liquidacion';

        t_et_d_cnfgrcion_crgue_impsto v_et_d_cnfgrcion_crgue_impsto%rowtype;
        v_id_sjto_impsto    number;
        v_id_lqdcion        number;
        --v_id_rnta         number;
        v_id_dcmnto         number;
        v_id_fljo           wf_d_flujos.id_fljo%type;    
        v_id_sesion         number;
        o_cdgo_rspsta       number;        
       o_mnsje_rspsta       varchar(4000);
    begin
        -- insert into muerto (d_001,v_001) values(sysdate,'entrando al begin de cargue liquidacion');
        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Inicia: '||p_id_infrmcion_telefono,
                              1);
        o_cdgo_rspsta  := 0;
--        o_mnsje_rspsta := 'Liquidaciones registradas exitosamente';
      --  insert into muerto (d_001,c_001) values(sysdate, o_mnsje_rspsta);

        --Se consulta la configuracion del cargue
        begin
             select  *
              into    t_et_d_cnfgrcion_crgue_impsto
              from    v_et_d_cnfgrcion_crgue_impsto
              where   id_impsto = p_id_impsto;

             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Consulta cargue '|| t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                              1);
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar la configuracion de cargue. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        -- Se consulta el id del flujo de novedades persona
        begin
            select  id_fljo
            into    v_id_fljo
            from    wf_d_flujos
            where   cdgo_fljo = 'NPR';

            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Consulta flujo '||v_id_fljo,
                              1);
        exception
            when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar el flujo de Novedades Persona. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        begin
            --Se actualiza el impuesto, subimpsto
            update  gi_g_telefono_pre_lqdcion
            set     id_impsto         = t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                    id_impsto_sbmpsto = t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto
            where   id_infrmcion_telefono = p_id_infrmcion_telefono;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Actualiza impsto-subimpsto',
                              1);
        exception
            when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al actualizar el impuesto y subimpuesto en la tabla de cargue. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        commit;

        -- Se actualiza el id_sjto_impsto en la tabla de cargue
        for c_rentas in (   select  id_tlfno_pre_lqdcion, idntfccion, id_impsto
                            from    gi_g_telefono_pre_lqdcion
                            where   id_infrmcion_telefono = p_id_infrmcion_telefono
                            and     indcdor_prcsdo != 'S'
                            and     id_sjto_impsto is null) 
        loop
         pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entro al loop de rentas' ||v_id_sjto_impsto ,
                              1);

            begin

            select  id_sjto_impsto
            into    v_id_sjto_impsto
            from    v_si_i_sujetos_impuesto
            where   idntfccion_sjto = to_char(c_rentas.idntfccion)
            and     id_impsto = c_rentas.id_impsto;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Busca sjto_impsto' ||v_id_sjto_impsto ,
                              1);

                update  gi_g_telefono_pre_lqdcion
                set     id_sjto_impsto = v_id_sjto_impsto
                where   id_tlfno_pre_lqdcion = c_rentas.id_tlfno_pre_lqdcion;

                 pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Actualiza sjto_impsto si lo encuentra' ||v_id_sjto_impsto ,
                              1);

            exception
                when no_data_found then
                    begin
                        -- Se crean los sujetos impuestos
                        pkg_gi_telefonos_cargue.prc_rg_sujeto_impuesto (  p_cdgo_clnte          => p_cdgo_clnte,
                                                                          p_id_ssion            => p_id_ssion,
                                                                          p_id_app_nvddes_prsna => t_et_d_cnfgrcion_crgue_impsto.id_app_nvddes_prsna, 
                                                                          p_id_app_page_nvd_prs => t_et_d_cnfgrcion_crgue_impsto.id_app_page_nvd_prs, 
                                                                          p_id_usrio            => p_id_usrio,
                                                                          p_id_impsto           => t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                                                                          p_id_impsto_sbmpsto   => t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto,
                                                                          p_id_tlfno_pre_lqdcion=> c_rentas.id_tlfno_pre_lqdcion,
                                                                          p_id_fljo             => v_id_fljo,
                                                                          o_id_sjto_impsto      => v_id_sjto_impsto,
                                                                          o_cdgo_rspsta         => o_cdgo_rspsta,
                                                                          o_mnsje_rspsta        => o_mnsje_rspsta );

                             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Creo sjto impsto' ||v_id_sjto_impsto ,
                              1);

                        if o_cdgo_rspsta = 0 then
                            update  gi_g_telefono_pre_lqdcion
                            set     id_sjto_impsto = v_id_sjto_impsto
                            where   id_tlfno_pre_lqdcion = c_rentas.id_tlfno_pre_lqdcion;

                             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Actualiza sjto_impsto tabla de liquidacion' ||v_id_sjto_impsto ,
                              1);

                            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'ACTUALIZADO SUJETO: '||v_id_sjto_impsto, 1);
                        else
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||': Error al crear sujeto-impuesto ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                            -- Registrar la respuesta de la transacción
                            prc_rg_observacion(p_id_tlfno_pre_lqdcion => c_rentas.id_tlfno_pre_lqdcion,
                                               p_obsrvcion        => o_mnsje_rspsta,
                                               p_estdo            => 'ERROR',
                                               o_cdgo_rspsta      => o_cdgo_rspsta,
                                               o_mnsje_rspsta     => o_mnsje_rspsta);
                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;

                    exception
                        when others then
                            o_cdgo_rspsta  := 30;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al crear sujeto impuesto ID['||c_rentas.idntfccion||'] - ' ||o_mnsje_rspsta||' - Error:';
                            pkg_sg_log.prc_rg_log ( p_cdgo_clnte,  null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                            prc_rg_observacion ( p_id_tlfno_pre_lqdcion => c_rentas.id_tlfno_pre_lqdcion,
                                                 p_obsrvcion        => o_mnsje_rspsta,
                                                 p_estdo            => 'ERROR',
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta );

                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                                continue;
                            end if;
                            continue;        
                    end;

                when others then
                    o_cdgo_rspsta  := 40;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al consultar/actualizar sujeto impuesto ID['||c_rentas.idntfccion||'] - ' ;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte,  null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                    prc_rg_observacion ( p_id_tlfno_pre_lqdcion => c_rentas.id_tlfno_pre_lqdcion,
                                         p_obsrvcion        => o_mnsje_rspsta,
                                         p_estdo            => 'ERROR',
                                         o_cdgo_rspsta      => o_cdgo_rspsta,
                                         o_mnsje_rspsta     => o_mnsje_rspsta );

                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );
                        continue;
                    end if;
                    continue;        
            end;          

            --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'FOR PASA AL SIGUIENTE', 1);                                          
        end loop;

        commit; --ojo

        -- Registra liquidaciones              
        for c_rentas in ( select  *
                          from    gi_g_telefono_pre_lqdcion
                          where   id_infrmcion_telefono = p_id_infrmcion_telefono
                          and     indcdor_prcsdo != 'S'
                          and     id_sjto_impsto is not null ) 
        loop
            begin
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entra begin de cursor de rentas' ||p_id_infrmcion_telefono ,
                              1);

                v_id_dcmnto  := 0;
                --v_id_rnta    := 0;
                v_id_lqdcion := 0;

                -- Si no se debe liquidar, es decir, la informacion enviada ya viene liquidada
                -- y solo se debe registrar
                if t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'N' then 
                    begin
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entra begin de liquidacion' ||p_id_infrmcion_telefono ,
                              1);
                        -- Se pasa a liquidacion 
                        pkg_gi_telefonos_cargue.prc_rg_liquidacion_telefonos ( p_cdgo_clnte        => p_cdgo_clnte,
                                                                               p_id_tlfno_pre_lqdcion  => c_rentas.id_tlfno_pre_lqdcion, 
                                                                               p_cdgo_indcdor_tpo  => t_et_d_cnfgrcion_crgue_impsto.cdgo_indcdor_tpo,
                                                                               p_id_usrio          => p_id_usrio,
                                                                               p_entrno            => 'PRVDO',
                                                                               o_id_lqdcion        => v_id_lqdcion,
                                                                               o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                               o_mnsje_rspsta      => o_mnsje_rspsta);
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'se crea la liquidacion' ||v_id_lqdcion ,
                              1);

                        --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_id_lqdcion : ' || v_id_lqdcion, 6);

                        if o_cdgo_rspsta <> 0 then
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error al registrar la liquidacion -' || o_mnsje_rspsta;
                            pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1 );

                            prc_rg_observacion ( p_id_tlfno_pre_lqdcion => c_rentas.id_tlfno_pre_lqdcion,
                                                 p_obsrvcion        => o_mnsje_rspsta,
                                                 p_estdo            => 'ERROR',
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta );

                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- Error registrando observación - ' || o_mnsje_rspsta;
                                pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                                        null,
                                                        v_nmbre_up,
                                                        v_nl,
                                                        o_mnsje_rspsta,
                                                        1 );
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;  

                    exception
                        when others then
                            o_cdgo_rspsta  := 60;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error al registrar las liquidaciones. ' ||o_mnsje_rspsta||' - Error: ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                            rollback;
                            return;
                    end;                    
                else
                    --if t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'N' then
                    --t_et_d_cnfgrcion_crgue_impsto.indcdor_lqdar = 'S'
                    null;
                end if;

                -- Si debe generar documento
                if t_et_d_cnfgrcion_crgue_impsto.indcdor_gnra_dcmnto = 'S' then
                    begin
                        pkg_gi_telefonos_cargue.prc_rg_documento (  p_cdgo_clnte        => p_cdgo_clnte,
                                                                    p_id_impsto         => c_rentas.id_impsto,
                                                                    p_id_impsto_sbmpsto => c_rentas.id_impsto_sbmpsto,
                                                                    p_id_sjto_impsto    => c_rentas.id_sjto_impsto,
                                                                    p_id_lqdcion        => v_id_lqdcion,
                                                                    p_fcha_vncmnto      => sysdate, --c_rentas.fcha_vncmnto_dcmnto,
                                                                    p_nmro_dcmnto       => v_id_lqdcion,
                                                                    p_cdgo_dcmnto_tpo   => 'DNO',
                                                                    p_entrno            => 'PRVDO',
                                                                    o_id_dcmnto         => v_id_dcmnto,
                                                                    o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => o_mnsje_rspsta ); 

                        if o_cdgo_rspsta <> 0 then
                            o_cdgo_rspsta  := 70;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '-' || o_mnsje_rspsta;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                            prc_rg_observacion(p_id_tlfno_pre_lqdcion => c_rentas.id_tlfno_pre_lqdcion,
                                               p_obsrvcion        => o_mnsje_rspsta,
                                               p_estdo            => 'ERROR',
                                               o_cdgo_rspsta      => o_cdgo_rspsta,
                                               o_mnsje_rspsta     => o_mnsje_rspsta);
                            if o_cdgo_rspsta <> 0 then
                                rollback;
                                continue;
                            end if;

                            rollback;
                            continue;
                        end if;

                    exception
                        when others then
                            o_cdgo_rspsta  := 80;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                              ': Error al registrar el documento Sujeto.' ||c_rentas.idntfccion||' - ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                            rollback;
                            return;
                    end;                
                end if;

                if o_cdgo_rspsta = 0 then
                    update  gi_g_telefono_pre_lqdcion
                    set     indcdor_prcsdo   = 'S',
                            obsrvcion_lqdcion    = 'Registro procesado con éxito',
                            nmro_intntos = nmro_intntos + 1,
                            id_lqdcion   = v_id_lqdcion
                    where   id_tlfno_pre_lqdcion = c_rentas.id_tlfno_pre_lqdcion;

                     pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se registra la liquidacion' ||v_id_lqdcion ,
                              1);
                    commit;

                     update gi_g_informacion_telefono
                     set    indcdor_prcsdo = 'E'
                     where  id_infrmcion_telefono = p_id_infrmcion_telefono;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'se cambia indicador a E' ||p_id_infrmcion_telefono ,
                              1);
                     commit;

                end if;

            exception
                when others then
                    o_cdgo_rspsta  := 90;
                    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                      ': Error al registrar las liquidaciones.' ;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end; 

        end loop;

        begin
          apex_session.attach(p_app_id     => p_id_app, -- 70000,
                              p_page_id    => p_id_page_app, -- 333,
                              p_session_id => p_id_ssion -- v('APP_SESSION')
                              );
        end;     

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo', 1);

        commit;
        ---- Consulta envio programado
         declare
              v_json_parametros clob;
            begin
              select json_object(key 'NIT' is p_idntfccion)
                into v_json_parametros
                from dual;

               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'LIQUIDACION_TELEFONIA',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;
    declare
      v_json_parametros clob;
    begin
      select json_object (key 'P_ID_USRIO' is p_id_usrio)
        into v_json_parametros
        from dual;

       pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'EJECUCION_TERMINADA',
                                              p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;      
        --   insert into muerto (d_001,c_001,v_001) values(sysdate, o_mnsje_rspsta,'PRUEBA2');
                
    exception
        when others then
            o_cdgo_rspsta  := 99;
--            o_mnsje_rspsta := 'No.' || o_cdgo_rspsta ||
                        --    ': Error al realizar el proceso de registro de la liquidacion de telefono' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Error al registrar liquidacion', 1);
       --     insert into muerto (d_001,c_001,v_001) values(sysdate, o_mnsje_rspsta,'PRUEBA3');
            rollback;
            return;

    end prc_rg_telefonos_cargue_liquidacion;

     procedure prc_rg_recaudo_telefono (      p_cdgo_clnte          in  number
                                             , p_id_infrmcion_telefono  in number
                                             , p_id_impsto         in  number                                   
                                             , p_id_usrio          in  number                               
                                             , p_id_bnco           in  number                                      
                                             , p_id_bnco_cnta      in  number)                                                   
    as
        v_nvel              number;
        v_nmbre_up          varchar2(200) := 'pkg_gi_telefonos_cargue.prc_rg_recaudo_telefono';
        v_mnsje_rspsta      varchar2(4000);
		v_id_dcmnto         number;
		v_rcdo_cntrol       number;
		v_id_rcdo           number;
        v_nl                number;
        o_cdgo_rspsta       number;
        o_mnsje_rspsta     varchar2(4000);

		t_gi_g_telefono_rcdo            gi_g_telefono_recaudo%rowtype;
		t_et_d_cnfgrcion_crgue_impsto   v_et_d_cnfgrcion_crgue_impsto%rowtype;
		v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;

	 begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Inicia: '||p_id_infrmcion_telefono,
                              1);
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Recaudo Registrado Exitosamente';

        ---Se consulta la configuracion del cargue
        begin
             select  *
              into    t_et_d_cnfgrcion_crgue_impsto
              from    v_et_d_cnfgrcion_crgue_impsto
              where   id_impsto = p_id_impsto;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar la configuracion de cargue. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
        end;	

		 begin
            --Se actualiza el impuesto, subimpsto
            update  gi_g_telefono_recaudo
            set     id_impsto         = t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                    id_impsto_sbmpsto = t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto
            where   id_infrmcion_telefono =  p_id_infrmcion_telefono;
			commit;
        exception
            when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al actualizar el impuesto y subimpuesto en la tabla de cargue de recaudo. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
        end;



		--- se recorre la tabla de gestión de Recaudo
		-- Se actualiza el id_sjto_impsto en la tabla de cargue
        for c_recaudo in (   select  id_tlfno_rcdo, idntfccion, id_prdo , vgncia, nmro_lnea_tlfno, nmro_cntrto, id_lqdcion, id_impsto_sbmpsto, vlor_rcdo
                             ,id_impsto
                             from    gi_g_telefono_recaudo
                             where   id_infrmcion_telefono = p_id_infrmcion_telefono
                             and     indcdor_prcsdo != 'S') 


		loop
               v_id_dcmnto := 0;
				  begin
						select  id_sjto_impsto  into v_id_sjto_impsto
						from    v_si_i_sujetos_impuesto
						where   cdgo_clnte        = p_cdgo_clnte
						and     id_impsto         = p_id_impsto
						and     idntfccion_sjto   = TO_CHAR(c_recaudo.idntfccion);


						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'dentro del bloque sujeto-impuesto', 6);

					exception
						when no_data_found then 
						o_mnsje_rspsta := 'La identificaci?n no existe en el sistema.' ;
						 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
						 rollback;
						 return;  
                    end;
				 -- Se realiza el paso a movimientos financieros
				begin
					pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto ( p_cdgo_clnte        => p_cdgo_clnte,
																				   p_id_lqdcion        => c_recaudo.id_lqdcion,
																				   p_cdgo_orgen_mvmnto => 'LQ',
																				   p_id_orgen_mvmnto   => c_recaudo.id_lqdcion,
																				   o_cdgo_rspsta       => o_cdgo_rspsta,
																				   o_mnsje_rspsta      => o_mnsje_rspsta );
					if (o_cdgo_rspsta <> 0) then
						o_cdgo_rspsta  := 50;
						o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
										  ': Error realizando el paso a movimientos financieros' || o_mnsje_rspsta;
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

					end if;

				exception
					when others then
						o_cdgo_rspsta  := 60;
						o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
										  ': Error al registrar el paso a movimientos financieros' ;
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
						rollback;
						return;
				end; -- Se realiza el paso a movimientos financieros

                --- se genera el documento
                 begin  --  1
                    pkg_gi_telefonos_cargue.prc_rg_documento (  p_cdgo_clnte        => p_cdgo_clnte,
                                                                p_id_impsto         => c_recaudo.id_impsto,
                                                                p_id_impsto_sbmpsto => c_recaudo.id_impsto_sbmpsto,
                                                                p_id_sjto_impsto    => v_id_sjto_impsto,
                                                                p_id_lqdcion        => c_recaudo.id_lqdcion,
                                                                p_fcha_vncmnto      => sysdate,
                                                                p_nmro_dcmnto       => c_recaudo.id_lqdcion,
                                                                p_cdgo_dcmnto_tpo   => 'DNO',
                                                                p_entrno            => 'PRVDO',
                                                                o_id_dcmnto         => v_id_dcmnto,
                                                                o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                o_mnsje_rspsta      => o_mnsje_rspsta ); 

                    if o_cdgo_rspsta <> 0 then -- if 1
                        o_cdgo_rspsta  := 70;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '-' || o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                        prc_rg_observacion_recaudo( p_id_tlfno_rcdo => c_recaudo.id_tlfno_rcdo,
                                                       p_obsrvcion        => o_mnsje_rspsta,
                                                       p_estdo            => 'ERROR',
                                                       o_cdgo_rspsta      => o_cdgo_rspsta,
                                                       o_mnsje_rspsta     => o_mnsje_rspsta);
                        if o_cdgo_rspsta <> 0 then
                            rollback;
                            continue;
                        end if;
                     end if;
                    exception
                        when others then
                            o_cdgo_rspsta  := 80;
                            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                              ': Error al registrar el documento Sujeto.' ||c_recaudo.idntfccion||' - ';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

                        end; 

				-- Se reconstruye el recaudo
                -- se registra el recaudo control
                begin

                    pkg_re_recaudos.prc_rg_recaudo_control( p_cdgo_clnte        =>  p_cdgo_clnte
                                                          , p_id_impsto         =>  p_id_impsto
                                                          , p_id_impsto_sbmpsto =>  c_recaudo.id_impsto_sbmpsto
                                                          , p_id_bnco           =>  p_id_bnco
                                                          , p_id_bnco_cnta      =>  p_id_bnco_cnta 
                                                          , p_fcha_cntrol       =>  sysdate
                                                          , p_obsrvcion         =>  'Control de recaudo impuesto de Telefonía y Telegrafo.'                                                          
                                                          , p_cdgo_rcdo_orgen   =>  'AT'   -- Archivo Telefonía                                                     
                                                          , p_id_usrio          =>  p_id_usrio
                                                          , o_id_rcdo_cntrol    =>  v_rcdo_cntrol
                                                          , o_cdgo_rspsta       =>  o_cdgo_rspsta
                                                          , o_mnsje_rspsta      =>  o_mnsje_rspsta);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => 'v_rcdo_cntrol: '||v_rcdo_cntrol , p_nvel_txto => 3 );

                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo control'|| ' - '||o_mnsje_rspsta ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );  
                    end if;

                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo control '||c_recaudo.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );


                end; 

                -- se registra el recaudo
        begin
                    pkg_re_recaudos.prc_rg_recaudo( p_cdgo_clnte         => p_cdgo_clnte
                                                  , p_id_rcdo_cntrol     => v_rcdo_cntrol
                                                  , p_id_sjto_impsto     => v_id_sjto_impsto
                                                  , p_cdgo_rcdo_orgn_tpo => 'DC'
                                                  , p_id_orgen           => v_id_dcmnto --id del documento
                                                  , p_vlor               => c_recaudo.vlor_rcdo 
                                                  , p_obsrvcion          => 'Recaudo impuesto de telefonia'
                                                  , p_cdgo_frma_pgo      => 'EF'      
                                                  , p_cdgo_rcdo_estdo    => 'RG' -- Se coloca RG para que se pueda aplicar.
                                                  , o_id_rcdo            => v_id_rcdo
                                                  , o_cdgo_rspsta        => o_cdgo_rspsta
                                                  , o_mnsje_rspsta       => o_mnsje_rspsta );
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                         , p_nvel_log => v_nvel , p_txto_log => 'v_id_rcdo: '||v_id_rcdo , p_nvel_txto => 3 );

                   if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo para: '||c_recaudo.idntfccion|| ' - '||o_mnsje_rspsta ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );  
                    end if;

                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 60;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo para: '||c_recaudo.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );

         end; 

		begin		 
				update  gi_g_liquidaciones
                set     fcha_lqdcion   = sysdate
                where   id_lqdcion   = c_recaudo.id_lqdcion;

          pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => 'Actualiza fecha de liqudiaci?n: '||c_recaudo.id_lqdcion , p_nvel_txto => 3 );
          exception
                 when others then
                    rollback;
                    o_cdgo_rspsta  := 80;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar la fecha de liquidación ' || ' Error: ' ;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
         end;


        begin 
                update  gf_g_movimientos_detalle
                set     fcha_mvmnto        = sysdate
                where   cdgo_mvmnto_orgn = 'LQ'
                and     id_orgen         = c_recaudo.id_lqdcion;
                /*pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up);*/

            exception
                 when others then
                    rollback;
                    o_cdgo_rspsta  := 80;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No fue actualizar la fecha de movimiento detalle ' || ' Error: ' ;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );                           
                                       --, p_nvel_log => v_nvel , p_txto_log => 'Actualiza fecha de cartera: '||c_recaudo.id_lqdcion , p_nvel_txto => 3 );  
            end;

                --Indica si se Aplica el Recaudo de la liquidacion 
                if ( c_recaudo.vlor_rcdo > 0 ) then

                    for c_crtra in ( select * from gf_g_movimientos_detalle
                                     where  cdgo_mvmnto_orgn = 'LQ'
                                     and    id_orgen         = c_recaudo.id_lqdcion
                                     and    vlor_dbe         > 0 )
                    loop

                        --Inserta los Movimientos Financiero de Capital(PC)
                        begin
                            insert into gf_g_movimientos_detalle ( id_mvmnto_fncro         , cdgo_mvmnto_orgn       , id_orgen        , cdgo_mvmnto_tpo    , vgncia
                                                                 , id_prdo                 , cdgo_prdcdad           , fcha_mvmnto     , id_cncpto          , id_cncpto_csdo
                                                                 , vlor_dbe                , vlor_hber              , actvo           , gnra_intres_mra    , fcha_vncmnto            , id_impsto_acto_cncpto )
                                                          values ( c_crtra.id_mvmnto_fncro , 'RE'             , v_id_rcdo       , 'PC'               , c_crtra.vgncia
                                                                 , c_crtra.id_prdo         , c_crtra.cdgo_prdcdad   , c_crtra.fcha_mvmnto    , c_crtra.id_cncpto  , c_crtra.        id_cncpto_csdo  , 0  , c_crtra.vlor_dbe  , 'S'  , 'N'  , c_crtra.fcha_vncmnto  , c_crtra.id_impsto_acto_cncpto );
                        exception
                             when others then
                                rollback;
                                o_cdgo_rspsta  := 80;
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero para la liquidacion ' || ' Error: ' ;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );

                        end;

                    end loop;

                end if;

			  --Actualiza el Consolidado de Cartera Despues de Aplicar Recaudo
        begin --1
            pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_id_sjto_impsto => v_id_sjto_impsto);
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 90;
                        o_mnsje_rspsta := 'No fue posible actualizar el consolidado del sujeto impuesto.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                              p_id_impsto  => null,
                                              p_nmbre_up   => v_nmbre_up,
                                              p_nvel_log   => v_nvel,
                                              p_txto_log   => (o_cdgo_rspsta|| '-' ||o_mnsje_rspsta || '.' || sqlerrm),
                                              p_nvel_txto  => 3);
                        return;
                end;
  begin
                --Actualiza los Datos del Recaudo Aplicado
                update re_g_recaudos a
                   set cdgo_rcdo_estdo = 'AP',
                       fcha_apliccion  = systimestamp,
                       mnsje_rspsta    = nvl(o_mnsje_rspsta, 'Aplicado'),
                       id_usrio_aplco  = p_id_usrio,
                       fcha_ingrso_bnco= sysdate
                 where id_rcdo         = v_id_rcdo
                   and cdgo_rcdo_estdo = 'RG';                       


				exception
					when others then
						rollback;
						o_cdgo_rspsta  := 100;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo procesar el recaudo '|| ' Error: ' ;
						pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
										   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );

	end; --1		 
                if o_cdgo_rspsta = 0 then
                    update  gi_g_telefono_recaudo
                    set     indcdor_prcsdo   = 'S',
                            obsrvcion_rcdo    = 'Registro procesado con éxito',
                            id_rcdo   = v_id_rcdo,
							id_dcmnto = v_id_dcmnto
                    where   id_tlfno_rcdo = c_recaudo.id_tlfno_rcdo;
                    commit;

					-- Si se procesaron todos los registros, se marca el proceso de carga como Exitoso
					 update gi_g_informacion_telefono
                     set    indcdor_prcsdo = 'E'
                     where  id_infrmcion_telefono = p_id_infrmcion_telefono;
                     commit;
                end if;
 end loop;				
				---- Consulta envio programado
 declare
      v_json_parametros clob;
    begin
      select json_object (key 'P_ID_INFRMCION_TELEFONO' is p_id_infrmcion_telefono)
        into v_json_parametros
        from dual;
        commit;
       pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'RECAUDO_TELEFONIA',
                                              p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;
         declare
      v_json_parametros clob;
    begin
      select json_object (key 'P_ID_USRIO' is p_id_usrio)
        into v_json_parametros
        from dual;

       pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'EJECUCION_TERMINADA',
                                              p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;
            exception
                when others then
                    rollback;
                    o_cdgo_rspsta  := 200;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. Error al procesar carga';
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta||' - '||sqlerrm , p_nvel_txto => 3 );

end prc_rg_recaudo_telefono; 

procedure prc_rg_telefonos_cartera ( p_cdgo_clnte           in number,
                                    p_id_usrio                  in number,
                                    p_id_impsto                 in number,
                                    p_id_infrmcion_telefono     in number)
    as    
        v_nl                number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rg_telefonos_cartera';
        v_nvel              number;
        t_et_d_cnfgrcion_crgue_impsto v_et_d_cnfgrcion_crgue_impsto%rowtype;
        v_id_sjto_impsto    number;
        v_id_lqdcion        number;
        v_id_dcmnto         number;
        v_id_fljo           wf_d_flujos.id_fljo%type;    
        v_id_sesion         number;
        o_cdgo_rspsta       number;
        o_mnsje_rspsta      varchar2(4000);
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Inicia: '||p_id_infrmcion_telefono,
                              1);
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Carteras registradas exitosamente';

        --Se consulta la configuracion del cargue
        begin
             select  *
              into    t_et_d_cnfgrcion_crgue_impsto
              from    v_et_d_cnfgrcion_crgue_impsto
              where   id_impsto = p_id_impsto;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar la configuracion de cargue. ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        begin
            --Se actualiza el impuesto, subimpsto
            update  gi_g_telefono_cartera
            set     id_impsto         = t_et_d_cnfgrcion_crgue_impsto.id_impsto,
                    id_impsto_sbmpsto = t_et_d_cnfgrcion_crgue_impsto.id_impsto_sbmpsto
            where   id_infrmcion_telefono = p_id_infrmcion_telefono;
        exception
            when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al actualizar el impuesto y subimpuesto en la tabla de cargue. ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
        end;

        commit;

        --- se consulta el id_sjto_impsto
        for c_cartera in (  select  id_tlfno_cartera, idntfccion, id_impsto, id_lqdcion
							from    gi_g_telefono_cartera
							where   id_infrmcion_telefono = p_id_infrmcion_telefono
							and     indcdor_prcsdo != 'S') 
        loop

		begin
			select  id_sjto_impsto 
			into    v_id_sjto_impsto
			from    v_si_i_sujetos_impuesto
			where   cdgo_clnte        = p_cdgo_clnte
			and     id_impsto         = p_id_impsto
			and     idntfccion_sjto   = TO_CHAR(c_cartera.idntfccion);	


			begin 	
			update gi_g_telefono_cartera
			set id_sjto_impsto = v_id_sjto_impsto
			where id_tlfno_cartera = c_cartera.id_tlfno_cartera;

			exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := o_cdgo_rspsta || 'No se pudo actualizar sjto_impsto en la tabla de cargue '|| ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
			end;

			exception
				when no_data_found then 
				o_mnsje_rspsta := 'La identificaci?n no existe en el sistema.' ;
				 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				 rollback;
				 return;  	
			end;

			begin
					pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto ( p_cdgo_clnte        => p_cdgo_clnte,
																				   p_id_lqdcion        => c_cartera.id_lqdcion,
																				   p_cdgo_orgen_mvmnto => 'LQ',
																				   p_id_orgen_mvmnto   => c_cartera.id_lqdcion,
																				   o_cdgo_rspsta       => o_cdgo_rspsta,
																				   o_mnsje_rspsta      => o_mnsje_rspsta );
					if (o_cdgo_rspsta <> 0) then
						o_cdgo_rspsta  := 50;
						o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
										  ': Error realizando el paso a movimientos financieros' || o_mnsje_rspsta;
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

					end if;

				exception
					when others then
						o_cdgo_rspsta  := 60;
						o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
										  ': Error al registrar el paso a movimientos financieros' ;
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
						rollback;
						return;
				end; -- Se realiza el paso a movimientos financieros

                   if o_cdgo_rspsta = 0 then
                    update  gi_g_telefono_cartera
                    set     indcdor_prcsdo   = 'S',
                            obsrvcion_crtra    = 'Cartera creada con éxito'
                    where   id_tlfno_cartera = c_cartera.id_tlfno_cartera;
                    commit;

					-- Si se procesaron todos los registros, se marca el proceso de carga como Exitoso
					 update gi_g_informacion_telefono
                     set    indcdor_prcsdo = 'E'
                     where  id_infrmcion_telefono = p_id_infrmcion_telefono;
                     commit;
                end if;

        end loop;



        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo', 1);

        commit;
        ---- Consulta envio programado
         declare
              v_json_parametros clob;
            begin
              select json_object(key 'P_ID_INFRMCION_TELEFONO' is p_id_infrmcion_telefono)
                into v_json_parametros
                from dual;

               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'CARTERA_TELEFONIA',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;

         declare
      v_json_parametros clob;
    begin
      select json_object (key 'P_ID_USRIO' is p_id_usrio)
        into v_json_parametros
        from dual;
        commit;
       pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'EJECUCION_TERMINADA',
                                              p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_telefonos_cargue.prc_rg_informacion_telefono',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
                end;

    exception
        when others then
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al realizar el proceso de registro cartera ' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;
            return;

    end prc_rg_telefonos_cartera;

procedure prc_rchzar_lqdcion (      p_cdgo_clnte                number,
                                    p_idntfccion                varchar2,
                                    p_id_infrmcion_tlfno        number,
                                    o_cdgo_rspsta               out number,
                                    o_mnsje_rspsta              out varchar2) 
as								

 v_json_parametros clob;
 v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rchzar_lqdcion';
 v_nl                number;

     begin
              select json_object(key 'NIT' is p_idntfccion)
                into v_json_parametros
                from dual;

              --  insert into muerto (n_001, c_001) values (5082024,v_json_parametros );
                commit;
               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'RECHAZAR_LIQUIDACION',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'PROCESO RECHAZADO';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);

           begin                         
            update gi_g_informacion_telefono
            set    indcdor_prcsdo = 'R'
            where id_infrmcion_telefono = p_id_infrmcion_tlfno;
            end;
            o_cdgo_rspsta  := 0;

            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;

end prc_rchzar_lqdcion;

procedure prc_rchzar_rcdo    (      p_cdgo_clnte                number,
                                    p_idntfccion                varchar2,
                                    p_id_infrmcion_tlfno        number,
                                    o_cdgo_rspsta               out number,
                                    o_mnsje_rspsta              out varchar2) 
as								

 v_json_parametros clob;
 v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rchzar_rcdo';
 v_nl                number;

     begin
              select json_object(key 'NIT' is p_idntfccion)
                into v_json_parametros
                from dual;

               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'RECHAZAR_RECAUDO',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'PROCESO RECHAZADO';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);

           begin                         
            update gi_g_informacion_telefono
            set    indcdor_prcsdo = 'R'
            where id_infrmcion_telefono = p_id_infrmcion_tlfno;
            end;
            o_cdgo_rspsta  := 0;

            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;

end prc_rchzar_rcdo;

procedure prc_rchzar_cartera    (   p_cdgo_clnte                number,
                                    p_idntfccion                varchar2,
                                    p_id_infrmcion_tlfno        number,
                                    o_cdgo_rspsta               out number,
                                    o_mnsje_rspsta              out varchar2) 
as								

 v_json_parametros clob;
 v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_rchzar_cartera';
 v_nl                number;

     begin
              select json_object(key 'NIT' is p_idntfccion)
                into v_json_parametros
                from dual;

               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'RECHAZAR_CARTERA',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'PROCESO RECHAZADO';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);

           begin                         
            update gi_g_informacion_telefono
            set    indcdor_prcsdo = 'R'
            where id_infrmcion_telefono = p_id_infrmcion_tlfno;
            end;
            o_cdgo_rspsta  := 0;

            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;

end prc_rchzar_cartera;


procedure prc_cargue_archivos_portal (      p_cdgo_clnte                number,
                                            p_id_usuario_telefonia       number,
                                            p_archivo_tipo               number,
                                            p_id_prdo                    number,
                                            p_vgncia                     number,
                                            o_cdgo_rspsta               out number,
                                            o_mnsje_rspsta              out varchar2)

as

v_json_parametros clob;
v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_telefonos_cargue.prc_cargue_archivos_portal';
v_nl                number;
v_id_rprte          number;

 begin 
 if p_archivo_tipo = 1 then


     select json_object(key 'id_usrio_tlfnia' is p_id_usuario_telefonia,
                        key 'p_id_telefono_archvo_tpo' is p_archivo_tipo,
                        key 'p_id_prdo' is p_id_prdo,
                        key 'p_vgncia' is p_vgncia)
        into v_json_parametros
        from dual;

      --  insert into muerto (n_001, n_002, v_001, v_002) values (p_id_usuario_telefonia,p_archivo_tipo,p_id_prdo,p_vgncia);
       commit;
   pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                          p_idntfcdor    => 'CARGUE_ARCHIVO_LIQUIDACION',
                                          p_json_prmtros => v_json_parametros);
     o_mnsje_rspsta := 'ARCHIVO CARGADO EXITOSAMENTE';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                 1);       
  elsif p_archivo_tipo = 2 then

         select json_object(key 'id_usrio_tlfnia' is p_id_usuario_telefonia,
                            key 'p_id_telefono_archvo_tpo' is p_archivo_tipo,
                            key 'p_id_prdo' is p_id_prdo,
                            key 'p_vgncia' is p_vgncia)
                into v_json_parametros
                from dual;

      --  insert into muerto (c_001,n_001, n_002, v_001, v_002) values ('ARCHIVO RECAUDO',p_id_usuario_telefonia,p_archivo_tipo,p_id_prdo,p_vgncia);
       commit;
               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'CARGUE_ARCHIVO_RECAUDO',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'ARCHIVO CARGADO EXITOSAMENTE';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                     1);  
     elsif p_archivo_tipo = 3 then

     select json_object(key 'id_usrio_tlfnia' is p_id_usuario_telefonia,
                        key 'p_id_telefono_archvo_tpo' is p_archivo_tipo,
                        key 'p_id_prdo' is p_id_prdo,
                        key 'p_vgncia' is p_vgncia)
                into v_json_parametros
                from dual;

     --   insert into muerto (c_001,n_001, n_002, v_001, v_002) values ('ARCHIVO CARTERA',p_id_usuario_telefonia,p_archivo_tipo,p_id_prdo,p_vgncia);
        commit;
               pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_idntfcdor    => 'CARGUE_ARCHIVO_CARTERA',
                                                      p_json_prmtros => v_json_parametros);
              o_mnsje_rspsta := 'ARCHIVO CARGADO EXITOSAMENTE';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                      1);  
  end if;
  


      
    exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en el envio programado ' ;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;

  end prc_cargue_archivos_portal;

   procedure prc_rg_recaudo_telefono_job      (    p_cdgo_clnte          in  number
                                                 , p_id_infrmcion_telefono  in number
                                                 , p_id_impsto         in  number                                   
                                                 , p_id_usrio          in  number                               
                                                 , p_id_bnco           in  number                                      
                                                 , p_id_bnco_cnta      in  number
                                                 , o_cdgo_rspsta       out number
                                                 , o_mnsje_rspsta      out varchar2)  
as  
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_gi_telefonos_cargue.prc_rg_recaudo_telefono_job';

  -- Se crea el Job 
    begin
       v_nmbre_job := 'IT_PRC_RECAUDO_TELEFONO';
       o_cdgo_rspsta:= 0;
      o_mnsje_rspsta:='OK';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando al segundo begin' || systimestamp, 1);
    begin
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_GI_TELEFONOS_CARGUE.PRC_RG_RECAUDO_TELEFONO',
                                number_of_arguments => 6,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);

      -- Se le asignan al job los parametros para ejecutarse
  dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                           argument_position => 1,
                                            argument_value    => p_cdgo_clnte);

  dbms_scheduler.set_job_argument_value   (job_name          => v_nmbre_job,
                                           argument_position => 2,
                                            argument_value    => p_id_infrmcion_telefono);

  dbms_scheduler.set_job_argument_value     (job_name          => v_nmbre_job,
                                             argument_position => 3,
                                             argument_value    => p_id_impsto);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                             argument_position => 4,
                                             argument_value    => p_id_usrio);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                              argument_position => 5,
                                              argument_value    => p_id_bnco);

    dbms_scheduler.set_job_argument_value    (job_name           => v_nmbre_job,
                                              argument_position  => 6,
                                              argument_value     => p_id_bnco_cnta);


      -- Se habilita el job
     dbms_scheduler.enable(name => v_nmbre_job);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'activando job' || systimestamp, 1);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
       --- return; 
   end;
  end prc_rg_recaudo_telefono_job;

   procedure prc_rg_telefonos_cartera_job      ( p_cdgo_clnte               in number,
												 p_id_usrio                  in number,
												 p_id_impsto                 in number,
												 p_id_infrmcion_telefono     in number,
												 o_cdgo_rspsta               out number,
												 o_mnsje_rspsta              out varchar2) 
    as    
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_gi_telefonos_cargue.prc_rg_telefonos_cartera_job';

  -- Se crea el Job 
    begin
    o_cdgo_rspsta:= 0;
    o_mnsje_rspsta:='OK';
        v_nmbre_job := 'IT_RG_CARTERA_TELEFONO';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando al segundo begin' || systimestamp, 1);
    begin
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_GI_TELEFONOS_CARGUE.PRC_RG_TELEFONOS_CARTERA',
                                number_of_arguments => 4,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);

      -- Se le asignan al job los parametros para ejecutarse
  dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                           argument_position  => 1,
                                            argument_value    => p_cdgo_clnte);

  dbms_scheduler.set_job_argument_value   (job_name           => v_nmbre_job,
                                           argument_position  => 2,
                                            argument_value    => p_id_usrio);

  dbms_scheduler.set_job_argument_value     (job_name          => v_nmbre_job,
                                             argument_position => 3,
                                             argument_value    => p_id_impsto);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                             argument_position  => 4,
                                             argument_value     => p_id_infrmcion_telefono);


      -- Se habilita el job
     dbms_scheduler.enable(name => v_nmbre_job);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'activando job' || systimestamp, 1);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
       --- return;

    end; 

  end prc_rg_telefonos_cartera_job;

 procedure prc_rg_tlfns_crgue_lqdcion_job      ( p_cdgo_clnte               in number,
                                                 p_id_ssion                  in number,
                                                 p_id_app                    in number,
                                                 p_id_page_app               in number,
                                                 p_id_usrio                  in number,
                                                 p_id_impsto                 in number,
                                                 p_id_infrmcion_telefono     in number,
                                                 p_idntfccion                in varchar2,
                                                 o_cdgo_rspsta               out number,
                                                 o_mnsje_rspsta              out varchar)
	as

    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_gi_telefonos_cargue.prc_rg_tlfns_crgue_lqdcion_job';

  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);

    v_mnsje := 'Datos - p_cdgo_clnte: ' || p_cdgo_clnte || ' - p_id_usuario: ' || p_id_usrio||'-' || p_id_app||'-'|| p_id_page_app;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';

    -- Se crea el Job 
    begin
       v_nmbre_job := 'IT_PRC_RG_TLFNS_CRGUE_LQDCION';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando al segundo begin' || systimestamp, 1);

      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_GI_TELEFONOS_CARGUE.PRC_RG_TELEFONOS_CARGUE_LIQUIDACION',
                                number_of_arguments => 8,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);

      -- Se le asignan al job los parametros para ejecutarse
  dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                           argument_position => 1,
                                            argument_value    => p_cdgo_clnte);

  dbms_scheduler.set_job_argument_value   (job_name          => v_nmbre_job,
                                           argument_position => 2,
                                            argument_value    => p_id_ssion);

  dbms_scheduler.set_job_argument_value     (job_name          => v_nmbre_job,
                                             argument_position => 3,
                                             argument_value    => p_id_app);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                             argument_position => 4,
                                             argument_value    => p_id_page_app);

    dbms_scheduler.set_job_argument_value    (job_name          => v_nmbre_job,
                                              argument_position => 5,
                                              argument_value    => p_id_usrio);

    dbms_scheduler.set_job_argument_value    (job_name           => v_nmbre_job,
                                              argument_position  => 6,
                                              argument_value     => p_id_impsto);

     dbms_scheduler.set_job_argument_value   (job_name            => v_nmbre_job,
                                              argument_position   => 7,
                                              argument_value      => p_id_infrmcion_telefono);

    dbms_scheduler.set_job_argument_value     (job_name          => v_nmbre_job,
                                              argument_position  => 8,
                                              argument_value     => p_idntfccion);												  

      -- Se habilita el job
     dbms_scheduler.enable(name => v_nmbre_job);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'activando job' || systimestamp, 1);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
       --- return;

    end; 

  end prc_rg_tlfns_crgue_lqdcion_job;   
  
  
end pkg_gi_telefonos_cargue;

/
