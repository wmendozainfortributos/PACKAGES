--------------------------------------------------------
--  DDL for Package Body PKG_PQ_PQR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PQ_PQR" as

    procedure prc_rg_solicitud_pqr(   p_id_tpo                  in pq_g_solicitudes.id_tpo%type
                                    , p_id_usrio                in pq_g_solicitudes.id_usrio%type
                                    , p_id_prsntcion_tpo        in pq_g_solicitudes.id_prsntcion_tpo%type
                                    , p_cdgo_clnte              in number
                                    , p_id_instncia_fljo        in pq_g_solicitudes.id_instncia_fljo%type
                                    , p_nmro_flio               in pq_g_solicitudes.nmro_flio%type
                                    , p_id_rdcdor               in pq_g_radicador.id_rdcdor%type
                                    , p_cdgo_rspnsble_tpo       in pq_g_solicitantes.cdgo_rspnsble_tpo%type
                                    , p_cdgo_idntfccion_tpo     in pq_g_radicador.cdgo_idntfccion_tpo%type
                                    , p_idntfccion              in pq_g_radicador.idntfccion%type
                                    , p_prmer_nmbre             in pq_g_radicador.prmer_nmbre%type
                                    , p_sgndo_nmbre             in pq_g_radicador.sgndo_nmbre%type
                                    , p_prmer_aplldo            in pq_g_radicador.prmer_aplldo%type
                                    , p_sgndo_aplldo            in pq_g_radicador.sgndo_aplldo%type  
                                    , p_cdgo_idntfccion_tpo_s   in pq_g_solicitantes.cdgo_idntfccion_tpo%type
                                    , p_idntfccion_s            in pq_g_solicitantes.idntfccion%type
                                    , p_prmer_nmbre_s           in pq_g_solicitantes.prmer_nmbre%type
                                    , p_sgndo_nmbre_s           in pq_g_solicitantes.sgndo_nmbre%type
                                    , p_prmer_aplldo_s          in pq_g_solicitantes.prmer_aplldo%type
                                    , p_sgndo_aplldo_s          in pq_g_solicitantes.sgndo_aplldo%type
                                    , p_id_pais_ntfccion        in pq_g_solicitantes.id_pais_ntfccion%type
                                    , p_id_dprtmnto_ntfccion    in pq_g_solicitantes.id_dprtmnto_ntfccion%type
                                    , p_id_mncpio_ntfccion      in pq_g_solicitantes.id_mncpio_ntfccion%type
                                    , p_drccion_ntfccion        in pq_g_solicitantes.drccion_ntfccion%type
                                    , p_email                   in pq_g_solicitantes.email%type
                                    , p_tlfno                   in pq_g_solicitantes.tlfno%type
                                    , p_cllar                   in pq_g_solicitantes.cllar%type
                                    , p_id_motivo               in number
                                    , p_idntfccion_sjto         in varchar2
                                    , p_id_impsto               in number
                                    , p_id_impsto_sbmpsto       in number
                                    , p_obsrvcion               in varchar2
                                    , p_trnscion                in varchar2 default 'S'
                                    , p_inddor_dcmnto_pdnte     in varchar2 default 'N' -- req. 22309
                                    , p_fcha_rdcdo              in date     default null -- req.0023223
                                    , p_ntfca_emil              in pq_g_solicitantes.ntfca_emil%type default null
                                    , o_cdgo_rspsta             out number
                                   , o_mnsje_rspsta            out varchar2) 
    as
        v_nl                      number;
        v_nmbre_up                  varchar(70)     := 'pkg_pq_pqr.prc_rg_solicitud_pqr';
        v_id_slctud                 pq_g_solicitudes.id_slctud%type;
        v_id_rdcdor                 pq_g_radicador.id_rdcdor%type := p_id_rdcdor;
        v_mnsje                     varchar2(4000);
        v_fcha_lmte_ley             pq_g_solicitudes.fcha_lmte_ley%type;
        v_fcha_pryctda              pq_g_solicitudes.fcha_pryctda%type;
        v_id_estdo                  pq_g_solicitudes.id_estdo%type;
        v_anio                      pq_g_solicitudes.anio%type := extract(year from sysdate);
        v_nmro_rdcdo                pq_g_solicitudes.nmro_rdcdo%type;
        v_id_fljo                   pq_d_motivos.id_fljo%type;
        v_id_instncia_fljo          wf_g_instancias_flujo.id_instncia_fljo%type; 
        v_id_fljo_trea              v_wf_d_flujos_transicion.id_fljo_trea%type;
        v_vldar_sjto_impsto         pq_d_motivos.vldar_sjto_impsto%type;
        v_id_sjto_impsto            v_si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_indcdor_rdccion_atmtca    pq_d_motivos.indcdor_rdccion_atmtca%type := 'N';
        v_nmro_rdcdo_dsplay         pq_g_solicitudes.nmro_rdcdo_dsplay%type;
        v_fcha_rdcdo                pq_g_solicitudes.fcha_rdcdo%type  :=  p_fcha_rdcdo;-- req.0023223
        v_id_slctud_mtvo            pq_g_solicitudes_motivo.id_slctud_mtvo%type;       

    begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Entrando ' || systimestamp, 1);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_fcha_rdcdo: ' || v_fcha_rdcdo, 6);-- req.0023223

        o_cdgo_rspsta := 0;
        --BUSCAMOS SI EXISTE UNA SOLICITUD DE PQR CON EL FLUJO
        begin
            select id_slctud
              into v_id_slctud
              from pq_g_solicitudes
             where id_instncia_fljo = p_id_instncia_fljo;
        exception 
            when no_data_found then
                v_id_slctud := null;
        end;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud: ' || v_id_slctud, 6);

        begin
            if v_id_rdcdor is null then
                --SE CREA EL RADICADOR EN CASO QUE NO EXISTA
                insert into pq_g_radicador( cdgo_idntfccion_tpo  , idntfccion      , prmer_nmbre  , 
                                            sgndo_nmbre        , prmer_aplldo         , sgndo_aplldo                   )
                                    values( p_cdgo_idntfccion_tpo, p_idntfccion    , p_prmer_nmbre, 
                                            p_sgndo_nmbre      , p_prmer_aplldo       , p_sgndo_aplldo                 )
                                  returning id_rdcdor into v_id_rdcdor;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto el radicador: ' || v_id_rdcdor, 6);
            else
                --SE ACTUALIZA EL RADICADOR EN CASO QUE EXISTA
                update pq_g_radicador 
                   set cdgo_idntfccion_tpo  = p_cdgo_idntfccion_tpo
                     , idntfccion           = p_idntfccion      
                     , prmer_nmbre          = p_prmer_nmbre  
                     , sgndo_nmbre          = p_sgndo_nmbre
                     , prmer_aplldo         = p_prmer_aplldo
                     , sgndo_aplldo         = p_sgndo_aplldo 
                 where id_rdcdor            = v_id_rdcdor;
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se actualizo el radicador: ' || v_id_rdcdor, 6);
            end if;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo procesar el radicador de la solicitud.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                return;
        end;

        if v_id_slctud is null then                                 

            --BUSCAMOS EL PRIMER ESTADO DE LA SOLICITUD SEGUN LA PARAMETRIZACION
            begin 
                select distinct first_value(id_estdo) over(order by orden )
                  into v_id_estdo
                  from pq_d_estados
                 where cdgo_clnte = p_cdgo_clnte
                   and orden = decode(v_indcdor_rdccion_atmtca, 'S', 2, 1);
                   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_estdo ' || v_id_estdo, 6);
            exception
                when others then
                    o_cdgo_rspsta   := 2;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se Encontraron Datos para el Estado de la Solicitud';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end;                                

            --REGISTRAMOS LA SOLICITUD
            begin    
                insert into pq_g_solicitudes( id_estdo      , id_tpo             , id_usrio      , id_instncia_fljo  
                                            , id_rdcdor     , anio               , cdgo_clnte    , nmro_flio   
                                            , nmro_rdcdo    , nmro_rdcdo_dsplay  , fcha_rdcdo    , id_prsntcion_tpo)
                                            --, inddor_dcmnto_pdnte   )
                                      values( v_id_estdo    , p_id_tpo           , p_id_usrio    , p_id_instncia_fljo
                                            , v_id_rdcdor   , v_anio             , p_cdgo_clnte  , p_nmro_flio    
                                            , v_nmro_rdcdo  , v_nmro_rdcdo_dsplay, v_fcha_rdcdo  , p_id_prsntcion_tpo)
                                           -- , p_inddor_dcmnto_pdnte   )
                                    returning id_slctud into v_id_slctud;                            
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud ' || v_id_slctud, 6);
            exception
                when others then 
                    o_cdgo_rspsta   := 3;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar la solicitud.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end;

            --REGISTRAMOS LA OBSERVACION DE LA SOLICITUD
            if p_obsrvcion is not null then 
                declare                    
                    v_id_fljo_trea  number := nvl(v('F_ID_FLJO_TREA'), pkg_pq_pqr.g_id_fljo_trea);
                begin
                    insert into pq_g_solicitudes_obsrvcion( id_slctud  , id_fljo_trea  , id_usrio  , fcha   , obsrvcion  )
                                                    values( v_id_slctud, v_id_fljo_trea, p_id_usrio, sysdate, p_obsrvcion);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inseto la observacion ', 6);
                exception
                    when others then
                        o_cdgo_rspsta   := 4;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar la observacion de la solicitud.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;
            end if;

            --REGISTRAMOS LOS DATOS DEL SOLICITANTE
            begin
                insert into pq_g_solicitantes( id_slctud             , cdgo_idntfccion_tpo    , idntfccion         , prmer_nmbre
                                             , sgndo_nmbre           , prmer_aplldo           , sgndo_aplldo       , id_pais_ntfccion
                                             , id_dprtmnto_ntfccion  , id_mncpio_ntfccion     , drccion_ntfccion   , email
                                             , tlfno                 , cllar                  , cdgo_rspnsble_tpo  , ntfca_emil)
                                       values( v_id_slctud           , p_cdgo_idntfccion_tpo_s, p_idntfccion_s     , p_prmer_nmbre_s
                                             , p_sgndo_nmbre_s       , p_prmer_aplldo_s       , p_sgndo_aplldo_s   , p_id_pais_ntfccion
                                             , p_id_dprtmnto_ntfccion, p_id_mncpio_ntfccion   , p_drccion_ntfccion , p_email
                                             , p_tlfno               , p_cllar                , p_cdgo_rspnsble_tpo, p_ntfca_emil );
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inseto el solicitante ', 6);
            exception
                when others then 
                    o_cdgo_rspsta   := 5;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el solicitante.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;

            end;

            --CONSULTAMOS LOS TERMINOS DE LEY Y PROYECTADOS
            begin
                select id_fljo
                     , pk_util_calendario.fnc_cl_fecha_final( p_cdgo_clnte      => p_cdgo_clnte
                                                            , p_fecha_inicial   => nvl(v_fcha_rdcdo, systimestamp) -- req.0023223
                                                            , p_undad_drcion    => undad_drcion_pryctda
                                                            , p_drcion          => drcion_pryctda
                                                            , p_dia_tpo         => tpo_dia ) fcha_pryctda
                     , pk_util_calendario.fnc_cl_fecha_final( p_cdgo_clnte      => p_cdgo_clnte
                                                            , p_fecha_inicial   => nvl(v_fcha_rdcdo, systimestamp) -- req.0023223
                                                            , p_undad_drcion    => undad_drcion_lmte_ley
                                                            , p_drcion          => drcion_lmte_ley
                                                            , p_dia_tpo         => tpo_dia ) fcha_lmte_ley
                     , vldar_sjto_impsto
                     , indcdor_rdccion_atmtca
                  into v_id_fljo
                     , v_fcha_pryctda
                     , v_fcha_lmte_ley
                     , v_vldar_sjto_impsto
                     , v_indcdor_rdccion_atmtca
                  from pq_d_motivos 
                 where id_mtvo = p_id_motivo;
                 o_mnsje_rspsta := 'v_id_fljo: ' || v_id_fljo || ' v_fcha_pryctda: ' || v_fcha_pryctda 
                                   || ' v_fcha_lmte_ley: ' || v_fcha_lmte_ley || ' v_vldar_sjto_impsto: ' || v_vldar_sjto_impsto 
                                   || ' v_indcdor_rdccion_atmtca: ' || v_indcdor_rdccion_atmtca ;
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 6);
            exception 
                when others then 
                    o_cdgo_rspsta   := 7;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudieron Generar las Fechas Proyectada y Limite de Ley.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end;

            --CREAMOS EL MOTIVO PARA LA SOLICITUD 
            begin
                insert into pq_g_solicitudes_motivo( id_slctud  , id_mtvo  )
                                             values( v_id_slctud, p_id_motivo)
                                           returning id_slctud_mtvo into v_id_slctud_mtvo;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud_mtvo: ' || v_id_slctud_mtvo, 6);
            exception
                when others then 
                    o_cdgo_rspsta   := 8;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el motivo de la solicitud.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;  
            end;

            --BUSCAMOS EL SUJETO_IMPUESTO
            begin
                select id_sjto_impsto
                  into v_id_sjto_impsto
                  from v_si_i_sujetos_impuesto
                 where cdgo_clnte      = p_cdgo_clnte
                   and idntfccion_sjto = p_idntfccion_sjto
                   and id_impsto       = p_id_impsto;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_sjto_impsto: ' || v_id_sjto_impsto, 6);
            exception
                when no_data_found then
                    if v_vldar_sjto_impsto = 'S' then
                        o_cdgo_rspsta   := 9;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se Encontraron Datos para la Identificacion del Sujeto.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                    end if;
            end;

            if p_idntfccion_sjto is not null then 
                --CREAMOS EL SUJETO IMPUESTO DE LA SOLICITUD
                begin
                    insert into pq_g_slctdes_mtvo_sjt_impst ( id_slctud_mtvo     , id_sjto_impsto
                                                            , id_impsto          , id_impsto_sbmpsto
                                                            , idntfccion         )
                                                     values ( v_id_slctud_mtvo   , v_id_sjto_impsto
                                                            , p_id_impsto        , p_id_impsto_sbmpsto
                                                            , p_idntfccion_sjto );
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se registro el sujeto y motivo', 6);
                exception
                    when others then
                        o_cdgo_rspsta   := 10;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el sujeto impuesto de la solicitud.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;            
            end if;
            --BUSCAMOS EL PRIMER ESTADO DE LA SOLICITUD SEGUN LA PARAMETRIZACION
            begin 
                select distinct first_value(id_estdo) over(order by orden )
                  into v_id_estdo
                  from pq_d_estados
                 where cdgo_clnte = p_cdgo_clnte
                   and orden = decode(v_indcdor_rdccion_atmtca, 'S', 2, 1);
                   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_estdo: ' || v_id_estdo, 6);
            exception
                when others then
                    o_cdgo_rspsta   := 11;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos para el estado de la solicitud.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end;         

            --GENERAMOS EL NUMERO DEL RADICADO DE LA SOLICITUD
            if v_indcdor_rdccion_atmtca = 'S' then
                begin
                    v_nmro_rdcdo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'PQR');
                    v_nmro_rdcdo_dsplay := v_anio || '-' || v_nmro_rdcdo;

          if v_fcha_rdcdo is null then
            v_fcha_rdcdo := systimestamp;
                    end if;

                    o_mnsje_rspsta  := 'v_nmro_rdcdo: ' || v_nmro_rdcdo || ' v_nmro_rdcdo_dsplay: ' || v_nmro_rdcdo_dsplay || ' v_fcha_rdcdo: ' || v_fcha_rdcdo ;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 6);
                exception
                    when others then
                        o_cdgo_rspsta   := 12;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar el numero del radicado.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;
            end if;

            --ACTUALIZAMOS LA SOLICITUD CON LOS DATOS DEL RADICADO Y FECHAS (PROYECTADA Y DE LEY )
            begin
                update pq_g_solicitudes
                       set nmro_rdcdo           = v_nmro_rdcdo
                         , nmro_rdcdo_dsplay    = v_nmro_rdcdo_dsplay
                         , fcha_pryctda         = v_fcha_pryctda
                         , fcha_lmte_ley        = v_fcha_lmte_ley
                         , fcha_rdcdo           = v_fcha_rdcdo
                         , id_estdo             = v_id_estdo
                     where id_slctud            = v_id_slctud;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se actualizo la solicitud', 6);
            exception
                when others then
                    o_cdgo_rspsta   := 14;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar la solicitud con el numero del radicado.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;                   
            end;

            --RECORREMOS LOS ADJUNTOS DE LA SOLICITUD
            for c_documentos in (select c001 obsrvcion
                                      , c002 filename
                                      , c003 mime_type
                                      , n001 id_mtvo_dcmnto
                                      , blob001 file_blob
                                   from apex_collections
                                  where collection_name = 'DOCUMENTOS'
                                 )
            loop

                --CREAMOS LOS DOCUMENTOS DE LA SOLICITUD
                begin
                    insert into pq_g_documentos ( id_slctud            , id_mtvo_dcmnto             , file_blob              
                                                , file_name            , file_mimetype              , obsrvcion              )
                                         values ( v_id_slctud          , c_documentos.id_mtvo_dcmnto, c_documentos.file_blob 
                                                , c_documentos.filename, c_documentos.mime_type     ,  c_documentos.obsrvcion);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto el docuemento: ' || c_documentos.filename, 6);
                exception
                    when others then
                        o_cdgo_rspsta   := 15;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el documento de la solicitud. '|| sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;                        
                end;
            end loop; 

            if apex_collection.collection_exists(p_collection_name => 'DOCUMENTOS') then 
                apex_collection.delete_collection( p_collection_name => 'DOCUMENTOS');            
            end if;            
            if (p_trnscion = 'S') then 
                commit;
            end if;
            if v_nmro_rdcdo_dsplay is not null then                
                prc_rg_mensaje_radicado(p_id_slctud => v_id_slctud, p_nmro_rdcdo_dsplay => v_nmro_rdcdo_dsplay);
            end if;
        end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Saliendo ' || systimestamp, 1);
    end prc_rg_solicitud_pqr;


    procedure prc_rg_solicitud_portal( p_id_tpo                  in pq_g_solicitudes.id_tpo%type
                                     , p_id_usrio                in pq_g_solicitudes.id_usrio%type
                                     , p_id_prsntcion_tpo        in pq_g_solicitudes.id_prsntcion_tpo%type 
                                     , p_cdgo_clnte              in number
                                     , p_nmro_flio               in pq_g_solicitudes.nmro_flio%type
                                     , p_id_motivo               in number
                                     , p_idntfccion_sjto         in varchar2
                                     , p_id_impsto               in number
                                     , p_id_impsto_sbmpsto       in number
                                     , p_obsrvcion               in varchar2
                                     , o_cdgo_rspsta             out number
                                     , o_mnsje_rspsta            out varchar2  
                                     , o_id_slctud               out number                                
                                     )
    as
        v_id_fljo               number;
        v_id_fljo_trea          number;
        v_id_fljo_trea_dstno    number; 
        v_id_instncia_fljo      number;
        v_id_instncia_trnscion  number;
        v_id_rdcdor             number;
        r_si_g_solicitantes     v_si_g_solicitantes%rowtype;
        v_mnsje                 varchar2(4000);
        v_id_fljo_trea_hja      number;
        v_id_instncia_fljo_hjo  number;
        v_id_fljo_hjo           number;

    begin
        --1. BUSCAMOS EL FLUJO A INSTANCIAR
        begin
            select id_fljo 
              into v_id_fljo
              from wf_d_flujos 
             where cdgo_clnte = p_cdgo_clnte
               and cdgo_fljo = 'PQR';
        exception
            when others then 
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos del flujo.';
                return;
        end;

        --2. BUSCAMOS LA PRIMERA TAREA DEL FLUJO. 
        begin
            select id_fljo_trea
                 , id_fljo_trea_dstno 
              into v_id_fljo_trea
                 , v_id_fljo_trea_dstno
              from wf_d_flujos_transicion
             where id_fljo = v_id_fljo
             order by orden 
             fetch first 1 rows only;
        exception
            when others then 
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos de la primera tarea del flujo.';
                return;
        end;

        --3. CREAMOS LA INSTANCIA DEL FLUJO
        begin
            pkg_pq_pqr.g_id_fljo_trea := v_id_fljo_trea;
            insert into wf_g_instancias_flujo( id_fljo       , fcha_incio, fcha_fin_plnda, 
                                               fcha_fin_optma, id_usrio  , estdo_instncia, obsrvcion) 
                                       values( v_id_fljo     , sysdate   , sysdate       , 
                                               sysdate       , p_id_usrio , 'INICIADA', 'Flujo de PQR portal. ' || p_obsrvcion    )
                                     returning id_instncia_fljo 
                                          into v_id_instncia_fljo;

            insert into wf_g_instancias_transicion( id_instncia_fljo  , id_fljo_trea_orgen, fcha_incio   ,
                                                    fcha_fin_plnda    , fcha_fin_optma    , fcha_fin_real, 
                                                    id_usrio          , id_estdo_trnscion) 
                                            values( v_id_instncia_fljo, v_id_fljo_trea    , sysdate      , 
                                                    sysdate           , sysdate           , sysdate      , 
                                                    p_id_usrio        , 1)
                                          returning id_instncia_trnscion 
                                               into v_id_instncia_trnscion;
        exception
            when others then
                o_cdgo_rspsta   := 3;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar la instancia del flujo.';
                return;
        end;

        --4. CONSULTAMOS LOS DATOS DEL TERCERO
        begin
            select b.cdgo_idntfccion_tpo
                 , b.idntfccion
                 , b.prmer_nmbre
                 , b.sgndo_nmbre
                 , b.prmer_aplldo
                 , b.sgndo_aplldo
                 , nvl(case when b.id_pais_ntfccion is null then
                             b.id_pais
                        else b.id_pais_ntfccion     
                   end,c.id_pais) as id_pais_ntfccion      
                 , nvl(case when b.id_dprtmnto_ntfccion is null then
                             b.id_dprtmnto
                        else b.id_dprtmnto_ntfccion     
                   end, c.id_dprtmnto) as id_dprtmnto_ntfccion   
                 , nvl(case when b.id_mncpio_ntfccion is null then
                             b.id_mncpio
                        else b.id_mncpio_ntfccion     
                   end, c.id_mncpio) as id_mncpio_ntfccion    
                 , b.drccion_ntfccion                
                 , b.email
                 , b.tlfno
                 , b.cllar
              into r_si_g_solicitantes
              from v_sg_g_usuarios a
              join si_c_terceros   b on b.id_trcro   = a.id_trcro
              join df_s_clientes   c on a.cdgo_clnte = c.cdgo_clnte
             where a.id_usrio = p_id_usrio;
        exception
            when others then 
                o_cdgo_rspsta   := 4;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos de la primera tarea del flujo.';
                return;
        end;

        --5. CONSULTAMOS EL RADICADOR DE LA SOLICITUD
        begin
            select id_rdcdor
              into v_id_rdcdor
              from pq_g_radicador
             where cdgo_idntfccion_tpo  = r_si_g_solicitantes.cdgo_idntfccion_tpo
               and idntfccion           = r_si_g_solicitantes.idntfccion;        
        exception
            when others then
                v_id_rdcdor := null;
        end;

        --6. CREAMOS LA SOLICITUD DE PQR
        pkg_pq_pqr.prc_rg_solicitud_pqr( p_id_tpo                  => p_id_tpo
                                       , p_id_usrio                => p_id_usrio
                                       , p_id_prsntcion_tpo        => p_id_prsntcion_tpo
                                       , p_cdgo_clnte              => p_cdgo_clnte
                                       , p_id_instncia_fljo        => v_id_instncia_fljo
                                       , p_nmro_flio               => p_nmro_flio
                                       , p_id_rdcdor               => v_id_rdcdor
                                       , p_cdgo_rspnsble_tpo       => 'R'
                                       , p_cdgo_idntfccion_tpo     => r_si_g_solicitantes.cdgo_idntfccion_tpo
                                       , p_idntfccion              => r_si_g_solicitantes.idntfccion
                                       , p_prmer_nmbre             => r_si_g_solicitantes.prmer_nmbre
                                       , p_sgndo_nmbre             => r_si_g_solicitantes.sgndo_nmbre
                                       , p_prmer_aplldo            => r_si_g_solicitantes.prmer_aplldo
                                       , p_sgndo_aplldo            => r_si_g_solicitantes.sgndo_aplldo
                                       , p_cdgo_idntfccion_tpo_s   => r_si_g_solicitantes.cdgo_idntfccion_tpo
                                       , p_idntfccion_s            => r_si_g_solicitantes.idntfccion
                                       , p_prmer_nmbre_s           => r_si_g_solicitantes.prmer_nmbre
                                       , p_sgndo_nmbre_s           => r_si_g_solicitantes.sgndo_nmbre
                                       , p_prmer_aplldo_s          => r_si_g_solicitantes.prmer_aplldo
                                       , p_sgndo_aplldo_s          => r_si_g_solicitantes.sgndo_aplldo
                                       , p_id_pais_ntfccion        => r_si_g_solicitantes.id_pais_ntfccion
                                       , p_id_dprtmnto_ntfccion    => r_si_g_solicitantes.id_dprtmnto_ntfccion
                                       , p_id_mncpio_ntfccion      => r_si_g_solicitantes.id_mncpio_ntfccion
                                       , p_drccion_ntfccion        => r_si_g_solicitantes.drccion_ntfccion
                                       , p_email                   => r_si_g_solicitantes.email
                                       , p_tlfno                   => r_si_g_solicitantes.tlfno
                                       , p_cllar                   => r_si_g_solicitantes.cllar
                                       , p_id_motivo               => p_id_motivo
                                       , p_idntfccion_sjto         => p_idntfccion_sjto
                                       , p_id_impsto               => p_id_impsto
                                       , p_id_impsto_sbmpsto       => p_id_impsto_sbmpsto
                                       , p_obsrvcion               => p_obsrvcion
                                       , p_trnscion                => 'N'
                                       , o_cdgo_rspsta             => o_cdgo_rspsta
                                       , o_mnsje_rspsta            => o_mnsje_rspsta
                                       );
        if (o_cdgo_rspsta != 0) then
                o_cdgo_rspsta   := 6;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. PQR-' || o_mnsje_rspsta;
                return;
        end if;

        --7. CONSULTAMOS LOS DATOS DEL SIGUIENTE FLUJO
        begin
            select m.id_fljo
                 , s.id_slctud
              into v_id_fljo_hjo
                 , o_id_slctud
              from pq_g_solicitudes s
              join pq_g_solicitudes_motivo sm
                on sm.id_slctud = s.id_slctud
              join v_pq_d_motivos m
                on m.id_mtvo = sm.id_mtvo
             where s.id_instncia_fljo = v_id_instncia_fljo;

        exception 
            when others then
                o_cdgo_rspsta   := 7;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos del siguiente flujo.';
                return;    
        end ;

        --8. GENERAMOS EL SIGUIENTE FLUJO
        begin
            pkg_pl_workflow_1_0.prc_rg_instancias_flujo( p_id_fljo          => v_id_fljo_hjo
                                                       , p_id_usrio         => p_id_usrio
                                                       , p_id_prtcpte       => null
                                                       , o_id_instncia_fljo => v_id_instncia_fljo_hjo
                                                       , o_id_fljo_trea     => v_id_fljo_trea_hja
                                                       , o_mnsje            => v_mnsje); 
            if v_id_instncia_fljo_hjo is null then
                rollback;
                o_cdgo_rspsta   := 8;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar el siguiente flujo. ' || v_mnsje;
                return;       
            end if;

            insert into wf_g_instancias_flujo_gnrdo( id_instncia_fljo  , id_fljo_trea        , id_instncia_fljo_gnrdo_hjo)
                                             values( v_id_instncia_fljo, v_id_fljo_trea_dstno, v_id_instncia_fljo_hjo    );    
        exception
            when others then
                rollback;
                o_cdgo_rspsta   := 8;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar el siguiente flujo.';
                return;    
        end;

        --9. GENERAMOS LA TAREA SIGUIENTE DEL FLUJO
        begin
            update wf_g_instancias_transicion
               set id_estdo_trnscion = 3 
             where id_instncia_fljo  = v_id_instncia_fljo;

            insert into wf_g_instancias_transicion( id_instncia_fljo  , id_fljo_trea_orgen  , fcha_incio   ,
                                                    fcha_fin_plnda    , fcha_fin_optma      , fcha_fin_real, 
                                                    id_usrio          , id_estdo_trnscion   ) 
                                            values( v_id_instncia_fljo, v_id_fljo_trea_dstno, sysdate      , 
                                                    sysdate           , sysdate             , sysdate      , 
                                                    p_id_usrio        , 1);
        exception
            when others then
                o_cdgo_rspsta   := 9;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar la siguiente tarea del flujo.';
                return;
        end;
    end prc_rg_solicitud_portal;                          


    procedure prc_rg_mensaje_radicado( p_id_slctud          in pq_g_solicitudes.id_slctud%type 
                                     , p_nmro_rdcdo_dsplay  in pq_g_solicitudes.nmro_rdcdo_dsplay%type  default null)
    as
        v_cdgo_clnte        number;
        v_json_parametros   clob;

    begin
        --CONSULTAMOS EL CODIGO DEL CLIENTE DE LA SOLICITUD
        select a.cdgo_clnte
          into v_cdgo_clnte
          from pq_g_solicitudes a
         where a.id_slctud = p_id_slctud ;

        --GENERAMOS EL JSON DE PARAMETROS
        begin
            v_json_parametros := json_object( key 'p_id_slctud'       value p_id_slctud
                                            , key 'nmro_rdcdo_dsplay' value p_nmro_rdcdo_dsplay);

            --CONSULTAMOS SI HAY ENVIOS PROGRAMADOS
            pkg_ma_envios.prc_co_envio_programado( p_cdgo_clnte     => v_cdgo_clnte
                                                 , p_idntfcdor      => 'pkg_pq_pqr.prc_rg_mensaje_radicado'
                                                 , p_json_prmtros   => v_json_parametros
                                                 );
        end;
    exception
        when others then
            null;
    end prc_rg_mensaje_radicado;

    procedure prc_rg_instancia_flujo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type
                                    , p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type)
    as
        v_id_instncia_fljo  wf_g_instancias_flujo.id_instncia_fljo%type; 
        v_id_fljo_trea      v_wf_d_flujos_transicion.id_fljo_trea%type;
        v_id_fljo           pq_d_motivos.id_fljo%type;
        v_mnsje             varchar2(4000);
        v_id_usrio          sg_g_usuarios.id_usrio%type;

    begin
        begin
            select m.id_fljo 
              into v_id_fljo
              from pq_g_solicitudes s
              join pq_g_solicitudes_motivo sm
                on sm.id_slctud = S.id_slctud
              join v_pq_d_motivos m
                on m.id_mtvo = sm.id_mtvo
             where s.id_instncia_fljo = p_id_instncia_fljo;

            exception 
                when others then
                    v_mnsje := 'No se Encontraron Datos de la Solicitud' ;
                    apex_error.add_error (  p_message          => v_mnsje,
                                            p_display_location => apex_error.c_inline_in_notification );
                    raise_application_error( -20001 , v_mnsje );       
            end ;

            begin
                select id_usrio
                  into v_id_usrio
                  from wf_g_instancias_transicion
                 where id_instncia_fljo     = p_id_instncia_fljo
                   and id_fljo_trea_orgen   = p_id_fljo_trea
                   and id_estdo_trnscion    in (1,2);
            exception
                when others then
                    v_mnsje := 'No se encontraron datos del usuario'  ;
                    apex_error.add_error (  p_message          => v_mnsje
                                         ,  p_display_location => apex_error.c_inline_in_notification );
                    raise_application_error( -20001 , v_mnsje );        
            end;

            begin
                select id_instncia_fljo_gnrdo
                  into v_id_instncia_fljo
                  from v_wf_g_instancias_flujo_gnrdo
                 where id_instncia_fljo = p_id_instncia_fljo
                   and id_fljo_gnrdo    = v_id_fljo;

            exception 
                when no_data_found then                    
                    pkg_pl_workflow_1_0.prc_rg_instancias_flujo(  p_id_fljo          => v_id_fljo
                                                                , p_id_usrio         => v_id_usrio
                                                                , p_id_prtcpte       => null
                                                                , o_id_instncia_fljo => v_id_instncia_fljo 
                                                                , o_id_fljo_trea     => v_id_fljo_trea
                                                                , o_mnsje            => v_mnsje); 
                    if v_id_instncia_fljo is null then
                        rollback;
                        v_mnsje := 'No se pudo Realizar la Solicitud, Error Creando el Nuevo Flujo ' || v_mnsje  ;
                        apex_error.add_error (  p_message          => v_mnsje,
                                                p_display_location => apex_error.c_inline_in_notification );
                        raise_application_error( -20001 , v_mnsje );            
                    end if;

                    insert into wf_g_instancias_flujo_gnrdo( id_instncia_fljo  , id_fljo_trea  , id_instncia_fljo_gnrdo_hjo)
                                                     values( p_id_instncia_fljo, p_id_fljo_trea, v_id_instncia_fljo        );
            end;
    exception 
        when others then
            rollback;
            v_mnsje := 'No se pudo crear la nueva Instancia del Flujo' || sqlerrm  ;
            apex_error.add_error (  p_message          => v_mnsje,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , v_mnsje ); 
    end prc_rg_instancia_flujo;

    procedure prc_rg_radicar_solicitud( p_id_slctud pq_g_solicitudes.id_slctud%type
                                      , p_cdgo_clnte              in number)
    as
        v_nmro_rdcdo        pq_g_solicitudes.nmro_rdcdo%type; 
        v_mnsje             varchar2(4000);
        v_id_estdo          pq_g_solicitudes.id_estdo%type;
        v_nmro_rdcdo_dsplay pq_g_solicitudes.nmro_rdcdo_dsplay%type;

    begin 

        --BUSCAMOS EL PRIMER ESTADO DE LA SOLICITUD SEGUN LA PARAMETRIZACION
        begin 
            select distinct first_value(id_estdo) over(order by orden )
              into v_id_estdo
              from pq_d_estados
             where cdgo_clnte = p_cdgo_clnte
               and orden = 2;
        exception
            when others then
                v_mnsje := 'No se Encontraron Datos para el Estado de la Solicitud';
                apex_error.add_error (  p_message          => v_mnsje,
                                        p_display_location => apex_error.c_inline_in_notification );
                raise_application_error( -20001 , v_mnsje );
        end;

        v_nmro_rdcdo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'PQR');
        update pq_g_solicitudes
           set nmro_rdcdo        = v_nmro_rdcdo
             , nmro_rdcdo_dsplay = anio || '-' || v_nmro_rdcdo
             , fcha_rdcdo        = systimestamp
             , id_estdo          = v_id_estdo
         where id_slctud         = p_id_slctud
           and nmro_rdcdo is null
     returning nmro_rdcdo_dsplay 
          into v_nmro_rdcdo_dsplay;

        --SE ENVIA UN MENSAJE DE TEXTO A EL SOLICITANTE        
        pkg_pq_pqr.prc_rg_mensaje_radicado(p_id_slctud => p_id_slctud , p_nmro_rdcdo_dsplay => v_nmro_rdcdo_dsplay);

    exception 
        when others then
            v_mnsje := 'No se Pudo Radicar la Solicitud'; 
            raise_application_error( -20001 , v_mnsje );
    end prc_rg_radicar_solicitud;

    procedure prc_ac_solicitud( p_id_slctud     in pq_g_solicitudes.id_slctud%type
                              , p_cdgo_clnte    in number
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2) 

    as
        v_id_estdo  pq_d_estados.id_estdo%type;

    begin
        o_cdgo_rspsta := 0;
         --BUSCAMOS EL PRIMER ESTADO DE LA SOLICITUD SEGUN LA PARAMETRIZACION
        begin 
            select distinct first_value(id_estdo) over(order by orden )
              into v_id_estdo
              from pq_d_estados
             where cdgo_clnte = p_cdgo_clnte
               and orden = 3;

        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'No se Encontraron Datos para el Estado de la Solicitud';
                return;
        end;

        begin
            update pq_g_solicitudes
               set id_estdo  = v_id_estdo 
             where id_slctud = p_id_slctud;
        exception
            when others then 
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := 'No se pudo actualizar la solicitud.' || sqlerrm;
                return;                
        end;
    end prc_ac_solicitud; 

    procedure prc_ac_solicitud( p_id_slctud     in pq_g_solicitudes.id_slctud%type
                              , p_cdgo_clnte    in number
                              , p_id_mtvo       in pq_g_solicitudes_motivo.id_mtvo%type
                              , p_id_acto       in gn_g_actos.id_acto%type
                              , p_id_usrio      in sg_g_usuarios.id_usrio%type
                              , p_fcha_real     in timestamp default systimestamp  
                              , p_obsrvcion     in pq_g_solicitudes_obsrvcion.obsrvcion%type
                              , p_cdgo_rspsta   in varchar2)
    as 
        v_nmro_rdcdo            pq_g_solicitudes.nmro_rdcdo%type; 
        v_mnsje                 varchar2(4000);
        v_id_estdo              pq_g_solicitudes.id_estdo%type;
        v_id_fljo_trea_orgen    wf_g_instancias_transicion.id_fljo_trea_orgen%type;
        v_id_fljo_trea          wf_g_instancias_transicion.id_fljo_trea_orgen%type;
        v_id_instncia_fljo      wf_g_instancias_transicion.id_instncia_fljo%type;
        v_type                  varchar2(1);
        v_error                 varchar2(4000);
        v_id_slctud_mtvo_acto   pq_g_solicitudes_mtvo_acto.id_slctud_mtvo_acto%type;
        v_id_slctud_mtvo        pq_g_solicitudes_motivo.id_slctud_mtvo%type;

    begin 

        --BUSCAMOS EL PRIMER ESTADO DE LA SOLICITUD SEGUN LA PARAMETRIZACION
        begin 
            select distinct first_value(id_estdo) over(order by orden )
              into v_id_estdo
              from pq_d_estados
             where cdgo_clnte = p_cdgo_clnte
               and orden = 4;

        exception
            when others then
                v_mnsje := 'No se Encontraron Datos para el Estado de la Solicitud';               
                raise_application_error( -20001 , v_mnsje );
        end;

        --BUSCAMOS SI ESE ACTO EXISTE PARA EL MOTIVO DE LA SOLICITUD
        begin
            select a.id_slctud_mtvo_acto
                 , m.id_slctud_mtvo
              into v_id_slctud_mtvo_acto
                 , v_id_slctud_mtvo
              from pq_g_solicitudes_motivo m
         left join pq_g_solicitudes_mtvo_acto a
                on m.id_slctud_mtvo = a.id_slctud_mtvo
               and a.id_acto = p_id_acto
             where id_slctud = p_id_slctud
               and m.id_mtvo = p_id_mtvo;

        exception
            when others then
                v_mnsje := 'Ocurrio un error al tratar de actualizar la solicitud.';
                raise_application_error( -20001 , v_mnsje );   
        end;

        --BUSCAMOS LA TAREA ACTUAL DEL FLUJO
        begin
            select t.id_fljo_trea_orgen
                 , s.id_instncia_fljo 
              into v_id_fljo_trea_orgen
                 , v_id_instncia_fljo
              from pq_g_solicitudes s
              join wf_g_instancias_transicion t on t.id_instncia_fljo = s.id_instncia_fljo  
             where s.id_slctud = p_id_slctud
               and t.id_estdo_trnscion in (1,2);

        exception 
            when others then
                v_mnsje := 'No se Encontraron Datos del Flujo para esta Solicitud';
                raise_application_error( -20001 , v_mnsje );   
        end;

        if v_id_slctud_mtvo_acto is null and p_id_acto is not null then
            insert into pq_g_solicitudes_mtvo_acto (id_slctud_mtvo  , id_acto  ) 
                                            values (v_id_slctud_mtvo, p_id_acto);                

            if p_obsrvcion is not null then
                begin                

                    insert into pq_g_solicitudes_obsrvcion( id_slctud   , id_fljo_trea        , id_usrio  
                                                          , fcha        , obsrvcion           )
                                                   values ( p_id_slctud , v_id_fljo_trea_orgen, p_id_usrio
                                                          , p_fcha_real , p_obsrvcion         );
                exception 
                    when others then
                        v_mnsje := 'No se Pudo registrar el detalle de la solicitud';
                        raise_application_error( -20001 , v_mnsje );
                end;
            end if;

        end if;

        update pq_g_solicitudes
           set id_estdo     = v_id_estdo
             , fcha_real    = p_fcha_real
             , cdgo_rspsta  = p_cdgo_rspsta
         where id_slctud    = p_id_slctud; 

    exception 
        when others then 
            v_mnsje := nvl(v_mnsje, 'No se pudo actualizar la solicitud ')  || p_id_acto;
            raise_application_error( -20001 , v_mnsje );
    end prc_ac_solicitud;

    procedure prc_ac_documentos(p_id_slctud     in pq_g_solicitudes.id_slctud%type,
                                p_json clob)
    as
        v_mnsje varchar2(4000);
    begin
        for c_documentos in (
                              select id_dcmnto 
                                from json_table( p_json, '$[*]'
                                                 columns ( 
                                                           id_dcmnto varchar2 path '$.id_dcmnto'
                                                         )
                                                )
                           )
        loop
            update pq_g_documentos
               set indcdor_actlzar  = 'S'
                 , actvo            = 'S'
             where id_slctud        = p_id_slctud                 
               and id_dcmnto        = c_documentos.id_dcmnto;

        end loop;

    exception 
        when others then
            v_mnsje := 'Ocurrio un error al tratar de actualizar el documento.';
            apex_error.add_error (  p_message          => v_mnsje,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , v_mnsje );
    end prc_ac_documentos;

    procedure prc_rg_manejador(  p_id_instncia_fljo     in wf_g_instancias_transicion.id_instncia_fljo%type
                               , p_id_fljo_trea         in v_wf_d_flujos_tarea.id_fljo_trea%type
                               , p_id_instncia_fljo_hjo in wf_g_instancias_transicion.id_instncia_fljo%type
                               , o_cdgo_rspsta          out number
                               , o_mnsje_rspsta         out varchar2)
    as
        v_id_slctud                 pq_g_solicitudes.id_slctud%type;
        v_cdgo_clnte                number;
        v_id_mtvo                   pq_g_solicitudes_motivo.id_mtvo%type;
        v_id_acto                   gn_g_actos.id_acto%type;
        v_id_usrio                  sg_g_usuarios.id_usrio%type;
        v_fcha_real                 timestamp;
        v_obsrvcion                 pq_g_solicitudes_obsrvcion.obsrvcion%type;
        v_mnsje                     varchar2(4000);
        v_id_instncia_fljo_gnrdo    number;
        v_cdgo_rspsta               varchar2(3);

    begin
         o_cdgo_rspsta := 0;
         --Se valida que el evento no haya sido manejado
        begin
            select  a.id_instncia_fljo_gnrdo
            into    v_id_instncia_fljo_gnrdo
            from    wf_g_instancias_flujo_gnrdo a
            where   a.id_instncia_fljo          =   p_id_instncia_fljo
            and     a.id_fljo_trea              =   p_id_fljo_trea
            and     a.id_instncia_fljo_gnrdo_hjo=   p_id_instncia_fljo_hjo
            and     a.indcdor_mnjdo             <>  'S';
        exception
            when no_data_found then
                return;        
        end;
        --OBTENEMOS LAS PROPIEDADES DEL EVENTO 
        begin
            select acto
                 , nvl(to_timestamp(fcha, 'dd/MM/YYYY HH:MI:SS'), systimestamp) 
                 , mtvo
                 , obsvcion
                 , usrio
                 , cdgo_rspsta
              into v_id_acto
                 , v_fcha_real
                 , v_id_mtvo
                 , v_obsrvcion
                 , v_id_usrio
                 , v_cdgo_rspsta
              from (
                    select b.vlor
                         , c.cdgo_prpdad  
                      from wf_g_instancias_flujo_evnto a    
                      join wf_g_instncias_flj_evn_prpd b
                        on b.id_instncia_fljo_evnto = a.id_instncia_fljo_evnto
                      join v_gn_d_eventos_propiedad c
                        on b.id_evnto_prpdad = c.id_evnto_prpdad
                      join v_wf_g_instancias_flujo_gnrdo d
                        on d.id_instncia_fljo_gnrdo = a.id_instncia_fljo  
                     where d.id_instncia_fljo       = p_id_instncia_fljo
                   )
             pivot (
                     max(vlor)
                     for cdgo_prpdad in ('ACT' acto,'FCH' fcha,'MTV' mtvo,'OBS' obsvcion , 'USR'  usrio , 'RSP'  cdgo_rspsta)
                   );
        exception
            when others then
                --v_mnsje := 'No se pudo obtener las propiedades del evento' || sqlerrm;
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'Manejador:1 No se pudo obtener las propiedades del evento' || sqlerrm;
                --raise_application_error( -20001 , v_mnsje );
                return;
        end;

        --VALIDAMOS SI EL MOTIVO NO ES NULL
        if v_id_mtvo is null then
            o_cdgo_rspsta   := 2;
            o_mnsje_rspsta  := 'Manejador:2 No se encontro motivo de la solicitud en las propiedades del evento';
            --v_mnsje         := 'No se encontro motivo de la solicitud en las propiedades del evento';
            --raise_application_error( -20001 , v_mnsje );
            return;
        end if;

        --VALIDAMOS SI EL USUARIO NO ES NULL
        if v_id_usrio is null then
            --v_mnsje := 'No se encontro usuario en las propiedades del evento';
            o_cdgo_rspsta   := 3;
            o_mnsje_rspsta  := 'Manejador:3 No se encontro usuario en las propiedades del evento';
           -- raise_application_error( -20001 , v_mnsje );
           return;
        end if;

        if v_cdgo_rspsta is null then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  := 'Manejador:4 No se encontro respuesta en las propiedades del evento';
            return;
        end if;

        --BUSCAMOS LOS DATOS DE LA SOLICITUD
        begin
           select id_slctud
                , cdgo_clnte
             into v_id_slctud
                , v_cdgo_clnte
             from v_pq_g_solicitudes 
            where id_instncia_fljo = p_id_instncia_fljo;

        exception
            when others then
                --v_mnsje := 'No se pudo obtener datos de la solicitud';
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := 'Manejador:5 No se pudo obtener datos de la solicitud';
                --raise_application_error( -20001 , v_mnsje );
                return;
        end; 
        begin

            pkg_pq_pqr.prc_ac_solicitud( p_id_slctud    => v_id_slctud
                                       , p_cdgo_clnte   => v_cdgo_clnte
                                       , p_id_mtvo      => v_id_mtvo
                                       , p_id_acto      => v_id_acto
                                       , p_id_usrio     => v_id_usrio
                                       , p_fcha_real    => v_fcha_real
                                       , p_obsrvcion    => v_obsrvcion
                                       , p_cdgo_rspsta  => v_cdgo_rspsta);
        exception
            when others then
                 o_cdgo_rspsta   := 6;
                 o_mnsje_rspsta  := 'Manejador:6 ' || sqlerrm ;
        end;

        o_mnsje_rspsta  := 'Me ejecute sin errores';
    end prc_rg_manejador;

    procedure prc_rg_finalizar_flujo( p_id_instncia_fljo    in number
                                    , p_id_fljo_trea        in number)
    as
        v_id_usrio  number;
        v_mnsje     varchar2(4000);
        v_error     varchar2(1);
    begin
        begin
            select distinct first_value(a.id_usrio) over (order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo  =   p_id_instncia_fljo
         and a.id_fljo_trea_orgen=   p_id_fljo_trea;

            pkg_pl_workflow_1_0.prc_rg_finalizar_instancia( p_id_instncia_fljo => p_id_instncia_fljo
                              , p_id_fljo_trea     => p_id_fljo_trea
                                                          , p_id_usrio         => v_id_usrio
                                                          , o_error            => v_error
                                                          , o_msg              => v_mnsje );

            if v_error = 'N' then
                raise_application_error( -20001 , v_mnsje );
            end if;
        exception
            when others then
                v_mnsje := 'No se pudo finalizar el flujo ERROR => ' || sqlerrm; 
                raise_application_error( -20001 , v_mnsje );
        end; 
    end prc_rg_finalizar_flujo;

    procedure prc_ac_quejas_reclamo( p_id_instncia_fljo in number
                                   , p_id_fljo_trea     in number)
    as         
    pragma autonomous_transaction;

        v_id_fncnrio_frma   number;
        v_id_orgen          number;
        v_id_acto           number;
        v_anio              varchar2(4);
        v_id_acto_tpo       number;
        v_id_usrio          number;
        v_cdgo_clnte        number;
        v_id_mtvo           number;
        v_id_dcmnto         number; 
        v_nmro_acto         varchar2(30);
        v_nmro_acto_dsplay  varchar2(30);
        v_blob              blob;

        v_gn_d_reportes     gn_d_reportes%rowtype;
        v_app_id            number := v('APP_ID');
        v_page_id           number := v('APP_PAGE_ID');

    procedure execute_job(p_id_instncia_fljo in number) 
    as
        pragma autonomous_transaction;
        v_nmbre_job  varchar2(42) := 'IT_WF_MC_' || to_char(systimestamp,'ddmmyyyyhhmissFF6');
    begin
        --CREAMOS EL JOB PARA EJECUTAR EN SEGUNDO PLANO
        begin
            dbms_scheduler.create_job ( job_name            => v_nmbre_job
                                      , job_type            => 'STORED_PROCEDURE' 
                                      , job_action          => 'PKG_PQ_PQR.PRC_AC_QUEJAS_RECLAMO_FLUJO'
                                      , number_of_arguments => 1
                                      , start_date          => null
                                      , repeat_interval     => null
                                      , end_date            => null
                                      , enabled             => false
                                      , auto_drop           => true
                                      , comments            => v_nmbre_job);

            --PASAMOS EL ARGUMENTO DE LA INSTANCIA DEL FLUJO AL JOBS
            dbms_scheduler.set_job_argument_value( job_name          => v_nmbre_job 
                                                 , argument_position => 1
                                                 , argument_value    => p_id_instncia_fljo); 

            --ACTUALIZAMOS LA FECHA DE INICIO DEL JOBS
            dbms_scheduler.set_attribute( name      => v_nmbre_job
                                        , attribute => 'start_date'
                                        , value     => current_timestamp + interval '5' second );

            --HABILITAMOS EL JOBS
            dbms_scheduler.enable(name => v_nmbre_job);
        exception
            when others then
                null;
        end;        
    end execute_job;

    begin
        begin
            select a.id_qja_rclmo
                 , a.cdgo_clnte  
                 , b.id_mtvo  
              into v_id_orgen
                 , v_cdgo_clnte
                 , v_id_mtvo
              from pq_g_quejas_reclamo a
              join pq_g_solicitudes_motivo b
                on b.id_slctud = a.id_slctud
             where a.id_instncia_fljo = p_id_instncia_fljo;
        exception
            when others then
                rollback;
                return;
        end;

        begin
            select a.id_fncnrio
                 , extract(year from sysdate)
                 , a.id_acto_tpo
                 , c.id_usrio
              into v_id_fncnrio_frma
                 , v_anio
                 , v_id_acto_tpo
                 , v_id_usrio
              from gn_d_actos_funcionario_frma a
              join gn_d_actos_tipo b
                on a.id_acto_tpo = b.id_acto_tpo
              join v_sg_g_usuarios c
                on c.id_fncnrio = a.id_fncnrio
             where b.cdgo_acto_tpo = 'QRE' 
               and b.cdgo_clnte = v_cdgo_clnte
               and a.actvo = 'S'
               and trunc (sysdate) 
           between a.fcha_incio 
               and a.fcha_fin
               and 0 
           between a.rngo_dda_incio 
               and a.rngo_dda_fin;
        exception
            when others then
                rollback;
                return;
        end;

        v_nmro_acto := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte => v_cdgo_clnte, p_cdgo_cnsctvo => 'PQR');

        -- 4.2 Construcci??n del Consecutivo del acto display
        v_nmro_acto_dsplay := 'QRE' || '-' || v_anio || '-' || v_nmro_acto;

        begin
            insert into gn_g_actos ( cdgo_clnte         , cdgo_acto_orgen, id_orgen         , id_undad_prdctra      ,
                                     id_acto_tpo        , nmro_acto      , anio             , nmro_acto_dsplay      ,
                                     fcha               , id_usrio       , id_fncnrio_frma  , id_acto_rqrdo_ntfccion,
                   fcha_incio_ntfccion, vlor           )
                            values ( v_cdgo_clnte       , 'QRE'          , v_id_orgen       , v_id_orgen              ,
                                     v_id_acto_tpo      , v_nmro_acto    , v_anio           , v_nmro_acto_dsplay      ,
                                     systimestamp       , v_id_usrio     , v_id_fncnrio_frma, null                    ,
                   systimestamp       , 0              )
                           returning id_acto 
                                into v_id_acto; 
        exception
            when others then
            v_nmro_acto_dsplay := sqlerrm;
                insert into muerto2(v_001) values('Error al insertar el acto: '||v_nmro_acto_dsplay); commit;
                --null;
        end;

        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'ACT', v_id_acto);
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'FCH', to_char(sysdate, 'DD/MM/YYYY'));
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'MTV', v_id_mtvo);
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'RSP', 'A');
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'USR', v_id_usrio);
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,'OBS', '!');        


        begin
            apex_session.attach( p_app_id     => 66000
                               , p_page_id    => 2
                               , p_session_id => v('APP_SESSION') );

            select /*+ RESULT_CACHE */
                           r.*
                      into v_gn_d_reportes 
                      from gn_d_reportes r
                     where r.id_rprte = 558;

            apex_util.set_session_state('P2_XML'      , '<data><id_qja_rclmo>' || v_id_orgen ||'</id_qja_rclmo></data>');
            apex_util.set_session_state('P2_ID_RPRTE' , 558);
            apex_util.set_session_state('F_CDGO_CLNTE', v_cdgo_clnte);

            --GENERAMOS EL DOCUMENTO 
            v_blob := apex_util.get_print_document( p_application_id     => 66000, 
                                                    p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                                    p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                                    p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                                    p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo );


            insert into muerto2(v_001, v_002, b_001) values(p_id_instncia_fljo, v_id_acto, v_blob); commit;

            if v_blob is null then
                raise_application_error( -20001 , 'el v_blob viene nula' );    
            end if;

            pkg_gn_generalidades.prc_ac_acto( p_file_blob       => v_blob
                                            , p_id_acto         => v_id_acto
                                            , p_ntfccion_atmtca => 'N');

            begin
                select id_dcmnto
                  into v_id_dcmnto
                  from gn_g_actos
                where id_acto = v_id_acto;
            exception
                when others then
                    insert into muerto2(v_001, v_002) values(20, 'No se encontro el id_dcmnto de acto ' || v_id_acto); commit;
            end;                                            


            apex_session.attach( p_app_id     => v_app_id
                               , p_page_id    => v_page_id
                               , p_session_id => v('APP_SESSION') );
        exception
            when others then 
                null;
        end;

        update pq_g_quejas_reclamo
         set id_dcmnto = v_id_dcmnto
        where id_qja_rclmo = v_id_orgen;
        commit;        
        execute_job(p_id_instncia_fljo => p_id_instncia_fljo);

    end prc_ac_quejas_reclamo;


    procedure prc_ac_quejas_reclamo_flujo( p_id_instncia_fljo in number)
    as    
    begin

        update wf_g_instancias_transicion
          set id_estdo_trnscion = 3
        where id_instncia_fljo = p_id_instncia_fljo;

        update wf_g_instancias_flujo
           set estdo_instncia = 'FINALIZADA'
         where id_instncia_fljo = p_id_instncia_fljo;

    end prc_ac_quejas_reclamo_flujo;

    procedure prc_rg_paz_salvo( p_id_instncia_fljo in number
                              , p_cdgo_rspsta      in varchar2 
                              , p_blob             in blob
                              , o_cdgo_rspsta      out number
                              , o_mnsje_rspsta     out varchar2 )
    as 
        v_id_fncnrio_frma   number;
        v_id_orgen          number;
        v_id_acto           number;
        v_anio              varchar2(4);
        v_id_acto_tpo       number;
        v_id_usrio          number;
        v_cdgo_clnte        number;
        v_id_mtvo           number;
        v_id_dcmnto         number; 
        v_nmro_acto         varchar2(30);
        v_nmro_acto_dsplay  varchar2(30);

        v_gn_d_reportes     gn_d_reportes%rowtype;
        v_app_id            number := v('APP_ID');
        v_page_id           number := v('APP_PAGE_ID');

    begin
        o_cdgo_rspsta := 0;
        --1. CONSULTAMOS LOS DATOS DEL PAZ Y SALVO
        begin
                select a.id_instncia_fljo_gnrdo
                    , b.cdgo_clnte  
                    , c.id_mtvo  
                into v_id_orgen
                    , v_cdgo_clnte
                    , v_id_mtvo
                from wf_g_instancias_flujo_gnrdo a
                join pq_g_solicitudes b
                    on b.id_instncia_fljo = a.id_instncia_fljo
                join pq_g_solicitudes_motivo c
                    on c.id_slctud = b.id_slctud
                where a.id_instncia_fljo_gnrdo_hjo =  p_id_instncia_fljo;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos para realizar el paz y salvo.';
                return;
        end;

        --2. BUSCASMOS LOS DATOS DEL ACTO
        begin
            select a.id_fncnrio
                 , extract(year from sysdate)
                 , a.id_acto_tpo
                 , c.id_usrio
              into v_id_fncnrio_frma
                 , v_anio
                 , v_id_acto_tpo
                 , v_id_usrio
              from gn_d_actos_funcionario_frma a
              join gn_d_actos_tipo b
                on a.id_acto_tpo = b.id_acto_tpo
              join v_sg_g_usuarios c
                on c.id_fncnrio = a.id_fncnrio
             where b.cdgo_acto_tpo = 'PYS' 
               and b.cdgo_clnte = v_cdgo_clnte
               and a.actvo = 'S'
               and trunc (sysdate) 
           between a.fcha_incio 
               and a.fcha_fin
               and 0 
           between a.rngo_dda_incio 
               and a.rngo_dda_fin;
        exception
            when others then
                o_cdgo_rspsta   := 2;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos para realizar el acto paz y salvo.';
                return;
        end;

        v_nmro_acto := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte => v_cdgo_clnte, p_cdgo_cnsctvo => 'PQR');

        v_nmro_acto_dsplay := 'PYS' || '-' || v_anio || '-' || v_nmro_acto;

        --3. CREAMOS EL ACTO ADMINISTRATIVO 
        begin
            insert into gn_g_actos ( cdgo_clnte         , cdgo_acto_orgen, id_orgen         , id_undad_prdctra      ,
                                     id_acto_tpo        , nmro_acto      , anio             , nmro_acto_dsplay      ,
                                     fcha               , id_usrio       , id_fncnrio_frma  , id_acto_rqrdo_ntfccion,
                   fcha_incio_ntfccion, vlor           )
                            values ( v_cdgo_clnte       , 'QRE'          , v_id_orgen       , v_id_orgen              ,
                                     v_id_acto_tpo      , v_nmro_acto    , v_anio           , v_nmro_acto_dsplay      ,
                                     systimestamp       , v_id_usrio     , v_id_fncnrio_frma, null                    ,
                   systimestamp       , 0              )
                           returning id_acto 
                                into v_id_acto; 
        exception
            when others then
                o_cdgo_rspsta   := 3;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo generar el acto.';
                return;
        end;

        --4. REGISTRAMOS LOS DATOS DEL EVENTO Y EL ARCHIVO (BLOB)
        begin
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'ACT', v_id_acto);
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'FCH', to_char(sysdate, 'DD/MM/YYYY'));
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'MTV', v_id_mtvo);
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'RSP', p_cdgo_rspsta);
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'OBS', '!');        
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo, 'USR', v_id_usrio);

            pkg_gn_generalidades.prc_ac_acto( p_file_blob       => p_blob
                                            , p_id_acto         => v_id_acto
                                            , p_ntfccion_atmtca => 'N');

        exception
            when others then 
                o_cdgo_rspsta   := 4;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo guardar el archivo.';
                rollback;
                return;
        end;

        --5. ACTUALIZAMOS LA INSTANCIA DEL FLUJO
        begin
            pkg_pq_pqr.prc_ac_quejas_reclamo_flujo( p_id_instncia_fljo => p_id_instncia_fljo);
        exception
            when others then 
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar la instancia del flujo de trabajo.';
                rollback;
                return;
        end;
        commit;

    end prc_rg_paz_salvo;


    function fnc_cl_url_portal(p_id_slctud in number)
    return varchar2
    is 
        v_id_instncia_fljo  number;
        v_id_fljo_trea      number;
        v_url               varchar2(4000);
    begin
        begin
            select c.id_instncia_fljo
                 , c.id_fljo_trea_orgen
              into v_id_instncia_fljo
                 , v_id_fljo_trea
              from pq_g_solicitudes a
              join wf_g_instancias_flujo_gnrdo b
                on b.id_instncia_fljo = a.id_instncia_fljo
              join wf_g_instancias_transicion c
                on c.id_instncia_fljo = b.id_instncia_fljo_gnrdo_hjo
             where a.id_slctud = p_id_slctud
          order by c.id_instncia_trnscion desc 
             fetch first 1 row only;

            v_url := pkg_pl_workflow_1_0.fnc_gn_tarea_url( p_id_instncia_fljo => v_id_instncia_fljo
                                                    , p_id_fljo_trea     => v_id_fljo_trea);
            if v_url not like '%f?p='|| v('APP_ID') ||'%' then
                v_url := '#';
            end if;

        exception
            when others then 
                v_url := '#';
        end;

        return v_url;

    end fnc_cl_url_portal;

    procedure prc_rg_documento_pendiente_pqr ( p_cdgo_clnte             number
                                             , p_id_slctud              number   
                                             , p_id_usrio             number   
                                             , p_inddor_dcmnto_pdnte    varchar2
                                             , o_cdgo_rspsta          out number
                                             , o_mnsje_rspsta         out varchar2 )
    as
        v_nl            number;
        v_nmbre_up      varchar(70)     := 'pkg_pq_pqr.prc_rg_documento_pendiente_pqr';
        v_id_dcmnto   number;
        v_json_envio    clob;

    begin


        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Entrando ' || systimestamp, 1);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Solicitud ID: ' || p_id_slctud, 1);

        o_cdgo_rspsta := 0;

        --RECORREMOS LOS ADJUNTOS DE LA SOLICITUD
        for c_documentos in (select c001 obsrvcion
                                  , c002 filename
                                  , c003 mime_type
                                  , n001 id_mtvo_dcmnto
                                  , blob001 file_blob
                               from apex_collections
                              where collection_name = 'DOCUMENTOS_P'
                             )
        loop

            -- Validar si el tipo de documento se registro antes y se va a cambiar
            begin
                select  id_dcmnto 
                into    v_id_dcmnto
                from    pq_g_documentos
                where   id_slctud      = p_id_slctud
                and     id_mtvo_dcmnto = c_documentos.id_mtvo_dcmnto;

                --Guardar en tabla temporal
                insert into pq_g_documentos_hist 
                (   id_dcmnto        
                    ,id_slctud        
                    ,id_mtvo_dcmnto   
                    ,file_blob        
                    ,file_name        
                    ,file_mimetype    
                    ,file_bfile       
                    ,obsrvcion        
                    ,fcha             
                    ,indcdor_actlzar  
                    ,actvo            
                    ,id_usrio 
                    ,fcha_rgstro 
                    ,id_usrio_rgstra
                )
                (select  id_dcmnto        
                        ,id_slctud        
                        ,id_mtvo_dcmnto   
                        ,file_blob        
                        ,file_name        
                        ,file_mimetype    
                        ,file_bfile       
                        ,obsrvcion        
                        ,fcha             
                        ,indcdor_actlzar  
                        ,actvo            
                        ,id_usrio
                        ,systimestamp
                        ,p_id_usrio
                 from   pq_g_documentos
                where   id_slctud      = p_id_slctud
                and     id_mtvo_dcmnto = c_documentos.id_mtvo_dcmnto);

                -- se borra el documento anterior
                delete  from pq_g_documentos
                where   id_dcmnto = v_id_dcmnto ; 

            exception 
                when others then
                    null;
            end;

            --CREAMOS LOS DOCUMENTOS DE LA SOLICITUD
            begin
                insert into pq_g_documentos ( id_slctud            , id_mtvo_dcmnto             , file_blob              
                                            , file_name            , file_mimetype              , obsrvcion              
                                            , id_usrio             )
                                     values ( p_id_slctud          , c_documentos.id_mtvo_dcmnto, c_documentos.file_blob 
                                            , c_documentos.filename, c_documentos.mime_type     ,  c_documentos.obsrvcion
                                            , p_id_usrio           );
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Se inserto el documento: ' || c_documentos.filename, 6);
            exception
                when others then
                    o_cdgo_rspsta   := 10;
                    o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el documento de la solicitud. '|| sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;                        
            end;
        end loop; 

        if apex_collection.collection_exists(p_collection_name => 'DOCUMENTOS_P') then 
            apex_collection.delete_collection( p_collection_name => 'DOCUMENTOS_P');            
        end if; 

        begin
        update pq_g_solicitudes 
        set    indcdor_dcmnto_pndnte = 'N'  --p_inddor_dcmnto_pdnte
        where  id_slctud = p_id_slctud;

        exception
                when others then
                o_cdgo_rspsta   := 10;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar  el indicador de documentos pendientes. '|| sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;                        
        end;

       -- ENVIO PROGRAMADO DE EMAIL 
          begin

               select json_object(key 'p_id_slctud' value p_id_slctud)
                   into v_json_envio
               from dual;

               --SE NOTIFICA AL CLIENTE DE LA ACTUALIZACION DE DOCUMENTOS EN EL RADIOCADO

               pkg_ma_envios.prc_co_envio_programado( p_cdgo_clnte        => p_cdgo_clnte,
                                                   p_idntfcdor         => 'documento.pendiente.registrado.pqr',
                                                   p_json_prmtros      => v_json_envio);

               --SE NOTIFICA AL FUNCIONARIO DE LA ACTUALIZACION DE DOCUMENTOS EN EL RADIOCADO 

               pkg_ma_envios.prc_co_envio_programado( p_cdgo_clnte        => p_cdgo_clnte,
                                                   p_idntfcdor         => 'documento.pendiente.reg.pqr.func',
                                                   p_json_prmtros      => v_json_envio);

               exception
                when others then
                     o_cdgo_rspsta := 31;
                     o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error en los envios programados, ' || sqlerrm;
                     pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;        
             end;

   exception
        when others then
        rollback; 
             o_cdgo_rspsta   := 90;
             o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el documento de la solicitud. '|| sqlerrm;
             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);


    end prc_rg_documento_pendiente_pqr; 
    -- Procedimiento que cierra las solicitudes que esten en la tarea inicial del flujo hijo
    -- es llamada desde el trigger de la tabla pq_g_solicitudes_cierre
    procedure prc_rg_cierre_radicado  ( p_id_slctud in pq_g_solicitudes.id_slctud%type
                    , o_cdgo_rspsta      out number
                    , o_mnsje_rspsta     out varchar2 ) as   

    v_id_instncia_fljo      v_pq_g_solicitudes.id_instncia_fljo%type;
    v_id_instncia_fljo_gnrdo  v_pq_g_solicitudes.id_instncia_fljo_gnrdo%type;

    begin

    begin
      -- Se consultan los datos de la solicitud
      select id_instncia_fljo, id_instncia_fljo_gnrdo
      into v_id_instncia_fljo, v_id_instncia_fljo_gnrdo
      from v_pq_g_solicitudes 
      where id_slctud = p_id_slctud; 

    exception
      when no_data_found then
        o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se encontraron datos de la solicitud.';
                return;     
            when others then
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Error al buscar los datos de la solicitud.';
                return;
        end;    


    begin
      -- Se finaliza el Flujo de PQR y el flujo generado
      update  wf_g_instancias_flujo 
      set   estdo_instncia = 'FINALIZADA' 
      where   id_instncia_fljo in (v_id_instncia_fljo,v_id_instncia_fljo_gnrdo);

      if not sql%found then
        o_cdgo_rspsta   := 10;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar el estado de la instancia del flujo a FINALIZADA.';
                return;
      end if;
    exception
            when others then
                o_cdgo_rspsta   := 15;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Error al finalizar los flujos.';
                return;
        end;  

    begin
      -- Se finalizan las transiciones
      update wf_g_instancias_transicion 
      set id_estdo_trnscion = 3 
      where id_instncia_fljo in (v_id_instncia_fljo,v_id_instncia_fljo_gnrdo);

      if not sql%found then
        o_cdgo_rspsta   := 20;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo finalizar las transiciones.';
                return;
      end if;

    exception
            when others then
                o_cdgo_rspsta   := 25;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Error al finalizar las transiciones.';
                return;
        end;  

    begin
      -- Se cierra la PQR
      update pq_g_solicitudes
      set id_estdo = 5
                ,fcha_real = sysdate
      where id_slctud = p_id_slctud; 

      if not sql%found then
        o_cdgo_rspsta   := 30;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar el estado de la solicitud a CERRADA.';
                return;
      end if;

    exception
            when others then
                o_cdgo_rspsta   := 35;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. Error al actualizar el estado de la solicitud a CERRADA.';
                return;
        end;  

        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := ' Solicitud cerrada exitosamente.';

    end prc_rg_cierre_radicado; 

 procedure prc_ac_solicitud_pqr(   p_id_tpo                  in pq_g_solicitudes.id_tpo%type
                                    , p_id_usrio                in pq_g_solicitudes.id_usrio%type
                                    , p_id_prsntcion_tpo        in pq_g_solicitudes.id_prsntcion_tpo%type
                                    , p_cdgo_clnte              in number
                                    , p_id_instncia_fljo        in pq_g_solicitudes.id_instncia_fljo%type
                                    , p_nmro_flio               in pq_g_solicitudes.nmro_flio%type
                                    , p_id_rdcdor               in pq_g_radicador.id_rdcdor%type
                                    , p_cdgo_rspnsble_tpo       in pq_g_solicitantes.cdgo_rspnsble_tpo%type
                                    , p_cdgo_idntfccion_tpo     in pq_g_radicador.cdgo_idntfccion_tpo%type
                                    , p_idntfccion              in pq_g_radicador.idntfccion%type
                                    , p_prmer_nmbre             in pq_g_radicador.prmer_nmbre%type
                                    , p_sgndo_nmbre             in pq_g_radicador.sgndo_nmbre%type
                                    , p_prmer_aplldo            in pq_g_radicador.prmer_aplldo%type
                                    , p_sgndo_aplldo            in pq_g_radicador.sgndo_aplldo%type  
                                    , p_cdgo_idntfccion_tpo_s   in pq_g_solicitantes.cdgo_idntfccion_tpo%type
                                    , p_idntfccion_s            in pq_g_solicitantes.idntfccion%type
                                    , p_prmer_nmbre_s           in pq_g_solicitantes.prmer_nmbre%type
                                    , p_sgndo_nmbre_s           in pq_g_solicitantes.sgndo_nmbre%type
                                    , p_prmer_aplldo_s          in pq_g_solicitantes.prmer_aplldo%type
                                    , p_sgndo_aplldo_s          in pq_g_solicitantes.sgndo_aplldo%type
                                    , p_id_pais_ntfccion        in pq_g_solicitantes.id_pais_ntfccion%type
                                    , p_id_dprtmnto_ntfccion    in pq_g_solicitantes.id_dprtmnto_ntfccion%type
                                    , p_id_mncpio_ntfccion      in pq_g_solicitantes.id_mncpio_ntfccion%type
                                    , p_drccion_ntfccion        in pq_g_solicitantes.drccion_ntfccion%type
                                    , p_email                   in pq_g_solicitantes.email%type
                                    , p_tlfno                   in pq_g_solicitantes.tlfno%type
                                    , p_cllar                   in pq_g_solicitantes.cllar%type
                                    , p_id_motivo               in number
                                    , p_idntfccion_sjto         in varchar2
                                    , p_id_impsto               in number
                                    , p_id_impsto_sbmpsto       in number
                                    , p_obsrvcion               in varchar2
                                    , p_trnscion                in varchar2 default 'S'
                                    , p_inddor_dcmnto_pdnte     in varchar2 default 'N' -- req. 22309
                                    , p_fcha_rdcdo              in date     default null -- req.0023223
                                    , p_ntfca_emil              in pq_g_solicitantes.ntfca_emil%type default null
                                    , o_cdgo_rspsta             out number
                                   , o_mnsje_rspsta            out varchar2) 
    as
        v_nl                      number;
        v_nmbre_up                  varchar(70)     := 'pkg_pq_pqr.prc_ac_solicitud_pqr';
        v_id_slctud                 pq_g_solicitudes.id_slctud%type;
        v_id_rdcdor                 pq_g_radicador.id_rdcdor%type := p_id_rdcdor;
        v_mnsje                     varchar2(4000);
        v_fcha_lmte_ley             pq_g_solicitudes.fcha_lmte_ley%type;
        v_fcha_pryctda              pq_g_solicitudes.fcha_pryctda%type;
        v_id_estdo                  pq_g_solicitudes.id_estdo%type;
        v_anio                      pq_g_solicitudes.anio%type := extract(year from sysdate);
        v_nmro_rdcdo                pq_g_solicitudes.nmro_rdcdo%type;
        v_id_fljo                   pq_d_motivos.id_fljo%type;
        v_id_instncia_fljo          wf_g_instancias_flujo.id_instncia_fljo%type; 
        v_id_fljo_trea              v_wf_d_flujos_transicion.id_fljo_trea%type := nvl(v('F_ID_FLJO_TREA'), pkg_pq_pqr.g_id_fljo_trea);
        v_vldar_sjto_impsto         pq_d_motivos.vldar_sjto_impsto%type;
        v_id_sjto_impsto            v_si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_indcdor_rdccion_atmtca    pq_d_motivos.indcdor_rdccion_atmtca%type := 'N';
        v_nmro_rdcdo_dsplay         pq_g_solicitudes.nmro_rdcdo_dsplay%type;
        v_fcha_rdcdo                pq_g_solicitudes.fcha_rdcdo%type  :=  p_fcha_rdcdo;-- req.0023223
        v_id_slctud_mtvo            pq_g_solicitudes_motivo.id_slctud_mtvo%type;
        v_exste_dcmnto              number;
        existe_obs                  number;
    begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Entrando' || systimestamp, 1);
        

        o_cdgo_rspsta := 0;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'p_id_instncia_fljo: ' || p_id_instncia_fljo, 6);-- req.0023223
        --BUSCAMOS SI EXISTE UNA SOLICITUD DE PQR CON EL FLUJO
        begin
            select id_slctud
              into v_id_slctud
              from pq_g_solicitudes
             where id_instncia_fljo = p_id_instncia_fljo;
        exception 
            when no_data_found then
                v_id_slctud := null;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Solicitud no encontrada : ' || p_id_instncia_fljo, 6);-- req.0023223
        end;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud: ' || v_id_slctud, 6);


        begin
            if v_id_rdcdor is null then
                --SE CREA EL RADICADOR EN CASO QUE NO EXISTA
                insert into pq_g_radicador( cdgo_idntfccion_tpo  , idntfccion      , prmer_nmbre  , 
                                            sgndo_nmbre        	 , prmer_aplldo    , sgndo_aplldo )
                                    values( p_cdgo_idntfccion_tpo, p_idntfccion    , p_prmer_nmbre, 
                                            p_sgndo_nmbre      	 , p_prmer_aplldo  , p_sgndo_aplldo)
                                  returning id_rdcdor into v_id_rdcdor;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto el radicador: ' || v_id_rdcdor, 6);
            else
                --SE ACTUALIZA EL RADICADOR EN CASO QUE EXISTA
                update pq_g_radicador 
                   set cdgo_idntfccion_tpo  = p_cdgo_idntfccion_tpo
                     , idntfccion           = p_idntfccion      
                     , prmer_nmbre          = p_prmer_nmbre  
                     , sgndo_nmbre          = p_sgndo_nmbre
                     , prmer_aplldo         = p_prmer_aplldo
                     , sgndo_aplldo         = p_sgndo_aplldo 
                 where id_rdcdor            = v_id_rdcdor;
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se actualizo el radicador: ' || v_id_rdcdor, 6);
            end if;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo procesar el radicador de la solicitud.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                return;
        end;

		--ACTUALIZAMOS LA SOLICITUD (si se necesita actualizar el radicador)
		If	v_id_rdcdor is not null and v_id_slctud is not null then
			begin    
				update pq_g_solicitudes
				   set id_rdcdor = v_id_rdcdor
				where  id_slctud = v_id_slctud
				  and  id_instncia_fljo = p_id_instncia_fljo;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud ' || v_id_slctud, 6);
			exception
				when others then 
					o_cdgo_rspsta   := 3;
					o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo Actualizar el radicador la solicitud.';
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
					rollback;
					return;
			end;
		end if;
        
		--ACTUALIZAMOS LA OBSERVACION DE LA SOLICITUD
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'p_obsrvcion' ||'- '|| p_obsrvcion, 6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_fljo_trea' ||'- '|| v_id_fljo_trea, 6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'v_id_slctud' ||'- '|| v_id_slctud, 6);
        
		if p_obsrvcion is not null and  v_id_fljo_trea is not null and v_id_slctud is not null then 
            
            select count(*)
            into existe_obs
            from pq_g_solicitudes_obsrvcion
            where id_slctud 	= v_id_slctud
              and id_fljo_trea = v_id_fljo_trea;
            

        
            if(existe_obs > 0) then
                begin
                    update pq_g_solicitudes_obsrvcion
                       set obsrvcion 	= p_obsrvcion
                     where id_slctud 	= v_id_slctud
                       and id_fljo_trea = v_id_fljo_trea;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se actualizo la observacion ', 6);
                    commit;
                exception
                    when others then
                        o_cdgo_rspsta   := 4;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar la observacion de la solicitud.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;
            else
                begin
                    insert into pq_g_solicitudes_obsrvcion( id_slctud  , id_fljo_trea  , id_usrio  , fcha   , obsrvcion  )
                                                    values( v_id_slctud, v_id_fljo_trea, p_id_usrio, sysdate, p_obsrvcion);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inseto la observacion ', 6);
                exception
                    when others then
                        o_cdgo_rspsta   := 4;
                        o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar la observacion de la solicitud.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;
            end if;
		end if;

		--REGISTRAMOS LOS DATOS DEL SOLICITANTE
		begin
			update pq_g_solicitantes
			   set cdgo_rspnsble_tpo 		= p_cdgo_rspnsble_tpo
				  ,prmer_nmbre				= p_prmer_nmbre_s
				  ,sgndo_nmbre        		= p_sgndo_nmbre_s
				  ,prmer_aplldo      		= p_prmer_aplldo_s
				  ,sgndo_aplldo      		= p_sgndo_aplldo_s
				  ,id_pais_ntfccion			= p_id_pais_ntfccion
				  ,id_dprtmnto_ntfccion  	= p_id_dprtmnto_ntfccion
				  ,id_mncpio_ntfccion    	= p_id_mncpio_ntfccion
				  ,drccion_ntfccion  		= p_drccion_ntfccion
				  ,email					= p_email
				  ,tlfno               		= p_tlfno
				  ,cllar     				= p_cllar
				  ,ntfca_emil				= p_ntfca_emil
			 where id_slctud 	= v_id_slctud 
			   and idntfccion 	= p_idntfccion_s;

			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se actualizo el solicitante ', 6);
		exception
			when others then 
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo actualizar el solicitante.';
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;

		end;
        
		--RECORREMOS LOS ADJUNTOS DE LA SOLICITUD
		for c_documentos in (select c001 obsrvcion
								  , c002 filename
								  , c003 mime_type
								  , n001 id_mtvo_dcmnto
								  , blob001 file_blob
							   from apex_collections
							  where collection_name = 'DOCUMENTOS'
								 )
    	loop

				select count(id_mtvo_dcmnto)
				into v_exste_dcmnto
				from	pq_g_documentos
				where id_slctud		= v_id_slctud
				  and id_mtvo_dcmnto   = c_documentos.id_mtvo_dcmnto;


				If(v_exste_dcmnto > 0) then
					--CREAMOS LOS DOCUMENTOS DE LA SOLICITUD
					begin
						update pq_g_documentos 
						   set file_blob 		= c_documentos.file_blob ,
							   file_name 		= c_documentos.filename  ,
							   file_mimetype 	= c_documentos.mime_type ,
							   obsrvcion	    = c_documentos.obsrvcion
						 where id_slctud		= v_id_slctud
						   and id_mtvo_dcmnto   = c_documentos.id_mtvo_dcmnto;
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto el docuemento: ' || c_documentos.filename, 6);
					exception
						when others then
							o_cdgo_rspsta   := 15;
							o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el documento de la solicitud. '|| sqlerrm;
							pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
							rollback;
							return;                        
					end;
				Else
					 --CREAMOS LOS DOCUMENTOS DE LA SOLICITUD
					begin
						insert into pq_g_documentos ( id_slctud            , id_mtvo_dcmnto             , file_blob              
													, file_name            , file_mimetype              , obsrvcion              )
											 values ( v_id_slctud          , c_documentos.id_mtvo_dcmnto, c_documentos.file_blob 
													, c_documentos.filename, c_documentos.mime_type     ,  c_documentos.obsrvcion);
						pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Se inserto el docuemento: ' || c_documentos.filename, 6);
					exception
						when others then
							o_cdgo_rspsta   := 15;
							o_mnsje_rspsta  := o_cdgo_rspsta || '. No se pudo registrar el documento de la solicitud. '|| sqlerrm;
							pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, o_mnsje_rspsta, 1);
							rollback;
							return;                        
					end;
				End if;
        end loop; 

            if apex_collection.collection_exists(p_collection_name => 'DOCUMENTOS') then 
                apex_collection.delete_collection( p_collection_name => 'DOCUMENTOS');            
            end if;            
            if (p_trnscion = 'S') then 
                commit;
            end if;
            if v_nmro_rdcdo_dsplay is not null then                
                prc_rg_mensaje_radicado(p_id_slctud => v_id_slctud, p_nmro_rdcdo_dsplay => v_nmro_rdcdo_dsplay);
            end if;
            commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Saliendo ' || systimestamp, 1);
    end prc_ac_solicitud_pqr;


   procedure prc_elm_archivos_adjuntos (
                                            p_id_slctud      in number,
                                            p_id_dcmnto      in number, 
                                            p_cdgo_clnte     in number,
                                            p_id_mtvo        in number,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2
                                            ) as   
        v_nl                     number;
        v_nmbre_up               varchar2(70) := 'pkg_pq_pqr.prc_elm_archivos_adjuntos';
        v_oblgtrio               varchar2(2);
    begin
        -- Inicialización de los valores de salida
        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := '0-Iniciando eliminación';

        -- Nivel de log
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta || '-' || systimestamp, 1);

        begin
            select a.indcdor_oblgtrio
            into v_oblgtrio
            from pq_d_motivos_documento a
            join pq_g_documentos b on a.id_mtvo_dcmnto = b.id_mtvo_dcmnto
            where a.id_mtvo   =  p_id_mtvo
              and b.id_slctud = p_id_slctud
              and b.id_dcmnto = p_id_dcmnto;
        end;
        -- Intentar eliminar el documento
        if(v_oblgtrio = 'N')then
            begin
                delete from pq_g_documentos
                where id_slctud = p_id_slctud
                  and id_dcmnto = p_id_dcmnto;
    
                -- Si la eliminación fue exitosa
                o_cdgo_rspsta  := 0;
                o_mnsje_rspsta := o_cdgo_rspsta ||' - '|| 'Documento eliminado con éxito';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta || '-' || systimestamp, 1);    
            exception
                when others then
                    -- En caso de error
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta ||' - '||'No se pudo eliminar el documento, el documento adjunto';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta || '-' || systimestamp, 6);
            end;
        else
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := o_cdgo_rspsta ||' - '||'No se pudo eliminar el documento, documento obligatorio';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta || '-' || systimestamp, 6);
        end if;
        
        If o_cdgo_rspsta = 0 then
            commit;
        end if;
        return;
    end;

end pkg_pq_pqr;

/
