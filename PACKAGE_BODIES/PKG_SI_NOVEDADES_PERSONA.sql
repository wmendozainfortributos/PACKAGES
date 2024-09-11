--------------------------------------------------------
--  DDL for Package Body PKG_SI_NOVEDADES_PERSONA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SI_NOVEDADES_PERSONA" as
  /*
  * @Descripci¿n    : Gesti¿n de Novedades de personas (Incripci¿n, Actualizaci¿n Activaci¿n, y Cancelaci¿n)
  * @Autor      : Ing. Shirley Romero
  * @Creaci¿n     : 06/05/2020
  * @Modificaci¿n   : 19/07/2021   -- Rechazo desde tarea incial
    *                   : 04/08/2021   -- Omisos
  */

  procedure prc_rg_novedad_persona(p_cdgo_clnte        in number,
                                   p_ssion             in number,
                                   p_id_impsto         in number,
                                   p_id_impsto_sbmpsto in number,
                                   p_id_sjto_impsto    in number default null,
                                   p_id_instncia_fljo  in number,
                                   p_cdgo_nvdad_tpo    in varchar2,
                                   p_obsrvcion         in varchar2,
                                   p_id_usrio_rgstro   in number,
                                   -- Datos de Inscripcion --
                                   p_tpo_prsna               in varchar2 default null,
                                   p_cdgo_idntfccion_tpo     in varchar2 default null,
                                   p_idntfccion              in number default null,
                                   p_prmer_nmbre             in varchar2 default null,
                                   p_sgndo_nmbre             in varchar2 default null,
                                   p_prmer_aplldo            in varchar2 default null,
                                   p_sgndo_aplldo            in varchar2 default null,
                                   p_nmbre_rzon_scial        in varchar2 default null,
                                   p_drccion                 in varchar2 default null,
                                   p_id_pais                 in number default null,
                                   p_id_dprtmnto             in number default null,
                                   p_id_mncpio               in number default null,
                                   p_drccion_ntfccion        in varchar2 default null,
                                   p_id_pais_ntfccion        in number default null,
                                   p_id_dprtmnto_ntfccion    in number default null,
                                   p_id_mncpio_ntfccion      in number default null,
                                   p_email                   in varchar2 default null,
                                   p_tlfno                   in varchar2 default null,
                                   p_cllar                   in varchar2 default null,
                                   p_nmro_rgstro_cmra_cmrcio in varchar2 default null,
                                   p_fcha_rgstro_cmra_cmrcio in date default null,
                                   p_fcha_incio_actvddes     in date default null,
                                   p_nmro_scrsles            in number default null,
                                   p_drccion_cmra_cmrcio     in varchar2 default null,
                                   p_id_actvdad_ecnmca       in number default null,
                                   p_id_sjto_tpo             in number default null,
                                   -- Fin Datos de Inscripcion --
                                   o_id_nvdad_prsna out number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
  
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar las novedades de personas !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl number;
  
    v_type_rspsta           varchar2(1);
    v_id_fljo_trea          number;
    v_error                 varchar2(1000);
    v_id_fljo_trea_orgen    number;
    v_id_slctud             number;
    v_id_instncia_fljo_pdre number;
    v_prmer_nmbre           varchar2(100);
    v_prmer_aplldo          varchar2(100);
    v_id_pais               df_s_paises.id_pais%type;
    v_id_pais_ntfccion      df_s_paises.id_pais%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_novedades_persona.prc_rg_novedad_persona');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_novedad_persona',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se valida si la novedad fue registrada por un pqr
    begin
      select a.id_slctud, a.id_instncia_fljo
        into v_id_slctud, v_id_instncia_fljo_pdre
        from v_pq_g_solicitudes a
       where a.id_instncia_fljo_gnrdo = p_id_instncia_fljo;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro informaci¿n de la solicitud PQR ' ||
                          sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
  
    -- Registro de la novedad
    begin
      insert into si_g_novedades_persona
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         obsrvcion,
         id_instncia_fljo,
         fcha_rgstro,
         id_usrio_rgstro,
         cdgo_nvdad_tpo,
         cdgo_nvdad_prsna_estdo,
         id_instncia_fljo_pdre,
         id_slctud)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         p_obsrvcion,
         p_id_instncia_fljo,
         systimestamp,
         p_id_usrio_rgstro,
         p_cdgo_nvdad_tpo,
         'RGS',
         v_id_instncia_fljo_pdre,
         v_id_slctud)
      returning id_nvdad_prsna into o_id_nvdad_prsna;
    
      -- Se consultan los adjunto para guardarlos
      for c_adjntos in (select seq_id,
                               n001,
                               n002    id_nvdad_prsna_adjnto_tpo,
                               c002    filename,
                               c003    mime_type,
                               blob001 blob
                          from apex_collections a
                         where collection_name =
                               'ADJUNTOS_NOVEDADES_PERSONA'
                           and n001 = p_id_instncia_fljo) loop
      
        -- Se insertan los adjuntos de la novedad
        begin
          insert into si_g_novedades_prsna_adjnto
            (id_nvdad_prsna,
             file_blob,
             file_name,
             file_mimetype,
             id_nvdad_prsna_adjnto_tpo)
          values
            (o_id_nvdad_prsna,
             c_adjntos.blob,
             c_adjntos.filename,
             c_adjntos.mime_type,
             c_adjntos.id_nvdad_prsna_adjnto_tpo);
        
          apex_collection.delete_member(p_collection_name => 'ADJUNTOS_NOVEDADES_PERSONA',
                                        p_seq             => c_adjntos.seq_id);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al registrar la Novedad.' || sqlcode ||
                              ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end loop; -- Fin Se consultan los adjunto para guardarlos
    
      --##
      -- Se consultan las sucursales
      for c_sucursales in (select *
                             from apex_collections a
                            where collection_name = 'SUCURSALES'
                              and n001 = p_id_instncia_fljo
                              and c012 != 'EXISTENTE') loop
      
        -- Se insertan las sucursales de la novedad
        begin
          insert into si_g_nvddes_prsna_scrsal
            (id_nvdad_prsna,
             cdgo_scrsal,
             nmbre,
             drccion,
             id_dprtmnto_ntfccion,
             id_mncpio_ntfccion,
             tlfno,
             cllar,
             email,
             actvo,
             estdo)
          values
            (o_id_nvdad_prsna,
             c_sucursales.c004,
             c_sucursales.c002,
             c_sucursales.c007,
             c_sucursales.c005,
             c_sucursales.c006,
             c_sucursales.c009,
             c_sucursales.c010,
             c_sucursales.c008,
             c_sucursales.c011,
             c_sucursales.c012);
        
          apex_collection.delete_member(p_collection_name => 'SUCURSALES',
                                        p_seq             => c_sucursales.seq_id);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al registrar las sucursales.' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end loop; -- Fin Se consultan las sucursales
      --##
    
      -- Si la novedad es de Inscripci¿n
      if p_cdgo_nvdad_tpo = 'INS' then
        -- Se registran los datos del nuevo sujeto
      
        if p_tpo_prsna = 'J' then
          v_prmer_nmbre  := p_nmbre_rzon_scial;
          v_prmer_aplldo := '.';
        else
          v_prmer_nmbre  := p_prmer_nmbre;
          v_prmer_aplldo := p_prmer_aplldo;
        end if;
      
        if p_id_pais is null then
          select id_pais
            into v_id_pais
            from df_s_clientes
           where cdgo_clnte = p_cdgo_clnte;
        else
          v_id_pais := p_id_pais;
        end if;
      
        if p_id_pais_ntfccion is null then
          select id_pais
            into v_id_pais_ntfccion
            from df_s_clientes
           where cdgo_clnte = p_cdgo_clnte;
        else
          v_id_pais := p_id_pais_ntfccion;
        end if;
      
        insert into si_g_novedades_persona_sjto
          (cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           nmbre_rzon_scial,
           drccion,
           id_pais,
           id_dprtmnto,
           id_mncpio,
           drccion_ntfccion,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           email,
           tlfno,
           cllar,
           nmro_rgstro_cmra_cmrcio,
           fcha_rgstro_cmra_cmrcio,
           fcha_incio_actvddes,
           nmro_scrsles,
           drccion_cmra_cmrcio,
           id_actvdad_ecnmca,
           id_nvdad_prsna,
           tpo_prsna,
           id_sjto_tpo)
        values
          (p_cdgo_idntfccion_tpo,
           p_idntfccion,
           v_prmer_nmbre,
           p_sgndo_nmbre,
           v_prmer_aplldo,
           p_sgndo_aplldo,
           p_nmbre_rzon_scial,
           p_drccion,
           v_id_pais,
           p_id_dprtmnto,
           p_id_mncpio,
           p_drccion_ntfccion,
           p_id_pais_ntfccion,
           p_id_dprtmnto_ntfccion,
           p_id_mncpio_ntfccion,
           p_email,
           p_tlfno,
           p_cllar,
           p_nmro_rgstro_cmra_cmrcio,
           p_fcha_rgstro_cmra_cmrcio,
           p_fcha_incio_actvddes,
           p_nmro_scrsles,
           p_drccion_cmra_cmrcio,
           p_id_actvdad_ecnmca,
           o_id_nvdad_prsna,
           p_tpo_prsna,
           p_id_sjto_tpo);
      
        -- Se registran los Responsables
        for c_rspnsble in (select *
                             from apex_collections a
                            where collection_name = 'RESPONSABLES'
                              and n001 = p_id_instncia_fljo
                              and c022 in ('NUEVO', 'ACTUALIZADO')) loop
          begin
            insert into si_g_novddes_prsna_rspnsble
              (id_nvdad_prsna,
               id_sjto_rspnsble,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               prcntje_prtcpcion,
               orgen_dcmnto,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               cllar,
               actvo,
               id_trcro,
               estdo)
            values
              (o_id_nvdad_prsna,
               c_rspnsble.c001,
               c_rspnsble.c003,
               c_rspnsble.c004,
               c_rspnsble.c005,
               c_rspnsble.c006,
               c_rspnsble.c007,
               c_rspnsble.c008,
               c_rspnsble.c009,
               c_rspnsble.c010,
               c_rspnsble.c011,
               c_rspnsble.c012,
               c_rspnsble.c013,
               c_rspnsble.c014,
               c_rspnsble.c015,
               c_rspnsble.c016,
               c_rspnsble.c017,
               c_rspnsble.c018,
               c_rspnsble.c019,
               c_rspnsble.c020,
               c_rspnsble.c021,
               c_rspnsble.c022);
            apex_collection.delete_member(p_collection_name => 'RESPONSABLES',
                                          p_seq             => c_rspnsble.seq_id);
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al insertar los responsables.' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        end loop; -- Fin Se registran los Responsables
      
        -- Se consultan las actividades economicas
        for actvdad_ecnmca in (select seq_id, n002, d001
                                 from apex_collections a
                                where collection_name =
                                      'ACTIVIDADES_ECONOMICAS'
                                  and n001 = p_id_instncia_fljo) loop
        
          -- Se insertan las actividades economicas
          begin
            insert into si_g_nvddes_prsna_actvd_eco
              (id_nvdad_prsna, id_actvdad_ecnmca, fcha_incio_actvdad)
            values
              (o_id_nvdad_prsna, actvdad_ecnmca.n002, actvdad_ecnmca.d001);
          
            apex_collection.delete_member(p_collection_name => 'ACTIVIDADES_ECONOMICAS',
                                          p_seq             => actvdad_ecnmca.seq_id);
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Error al registrar la Novedad.' || sqlcode ||
                                ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        end loop; -- Fin Se consultan los adjunto para guardarlos
      
      end if; -- Fin Si la novedad es de Inscripci¿n
    
      -- Si la novedad es de Actualizaci¿n se consultan los cambios realizados para guardarlos en el detalle de la novedad
      if p_cdgo_nvdad_tpo = 'ACT' then
        for c_cmbios in (select a.id_tmpral,
                                a.c001 atrbto,
                                a.c004 lbel_atrbto,
                                nvl(a.c002, ' ') vlor_antrior,
                                nvl(a.c003, ' ') vlor_nvo,
                                nvl(a.c006, nvl(a.c002, ' ')) txto_vlor_antrior,
                                nvl(a.c007, nvl(a.c003, ' ')) txto_vlor_nvo
                           from gn_g_temporal a
                          where n001 = p_id_instncia_fljo
                            and c005   = 'SUJETO'
                            and (c002 != c003 or
                                (c002 is null and c003 is not null) or
                                (c003 is null and c002 is not null))) loop
        
          begin
            insert into si_g_novedades_prsna_dtlle
              (id_nvdad_prsna,
               atrbto,
               lbel_atrbto,
               vlor_antrior,
               vlor_nvo,
               txto_vlor_antrior,
               txto_vlor_nvo)
            values
              (o_id_nvdad_prsna,
               c_cmbios.atrbto,
               c_cmbios.lbel_atrbto,
               c_cmbios.vlor_antrior,
               c_cmbios.vlor_nvo,
               c_cmbios.txto_vlor_antrior,
               c_cmbios.txto_vlor_nvo);
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'Error al registrar el detalle de la novedad.' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        end loop;
      
        begin
          delete from gn_g_temporal
           where n001 = p_id_instncia_fljo;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'Error al eliminar los datos de la temporal.' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
        --Se Guardan los Responsables Nuevo y Actualizados
        for c_rspnsble in (select *
                             from apex_collections a
                            where collection_name = 'RESPONSABLES'
                              and n001 = p_id_instncia_fljo
                              and c022 in ('NUEVO', 'ACTUALIZADO')) loop
          begin
            insert into si_g_novddes_prsna_rspnsble
              (id_nvdad_prsna,
               id_sjto_rspnsble,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               prcntje_prtcpcion,
               orgen_dcmnto,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               cllar,
               actvo,
               id_trcro,
               estdo)
            values
              (o_id_nvdad_prsna,
               c_rspnsble.c001,
               c_rspnsble.c003,
               c_rspnsble.c004,
               c_rspnsble.c005,
               c_rspnsble.c006,
               c_rspnsble.c007,
               c_rspnsble.c008,
               c_rspnsble.c009,
               c_rspnsble.c010,
               c_rspnsble.c011,
               c_rspnsble.c012,
               c_rspnsble.c013,
               c_rspnsble.c014,
               c_rspnsble.c015,
               c_rspnsble.c016,
               c_rspnsble.c017,
               c_rspnsble.c018,
               c_rspnsble.c019,
               c_rspnsble.c020,
               c_rspnsble.c021,
               c_rspnsble.c022);
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al insertar los responsables.' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        end loop;
        -- Se elimina la colecci¿n
        apex_collection.delete_collection(p_collection_name => 'RESPONSABLES');
      end if;
    
      -- Se consulta la informaci¿n del flujo para hacer la transicion a la siguiente tarea.
      begin
        select a.id_fljo_trea_orgen
          into v_id_fljo_trea_orgen
          from wf_g_instancias_transicion a
         where a.id_instncia_fljo = p_id_instncia_fljo
           and a.id_estdo_trnscion in (1, 2);
      
        -- Se cambia la etapa de flujo
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => p_id_instncia_fljo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => o_mnsje_rspsta,
                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                         o_error            => v_error);
        if v_type_rspsta = 'N' then
        
          update si_g_novedades_persona
             set id_fljo_trea = v_id_fljo_trea
           where id_nvdad_prsna = o_id_nvdad_prsna;
        
          -- se radica la PQR
          pkg_pq_pqr.prc_rg_radicar_solicitud(v_id_slctud, p_cdgo_clnte);
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Registro de Novedad Exitoso';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
        else
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al cambiar de etapa. ' || o_mnsje_rspsta ||
                            ' - ' || v_error;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                            ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- FIN Se consulta la informaci¿n del flujo para hacer la transicion a la siguiente tarea.
    
      ----
      --Consultamos los envios programados
      declare
        v_json_parametros clob;
      begin
        select json_object(key 'ID_NVDAD_PRSNA' is o_id_nvdad_prsna)
          into v_json_parametros
          from dual;
      
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'REGISTRO_NOVEDAD',
                                              p_json_prmtros => v_json_parametros);
                                              
        o_mnsje_rspsta := 'Novedad Registrada Exitosamente.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error en los envios programados, ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --Fin Consultamos los envios programados
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al registrar la Novedad.' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_novedad_persona',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_ap_novedad_persona(p_cdgo_clnte     in number,
                                   p_id_nvdad_prsna in number,
                                   p_id_usrio       in number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para aprobar las novedades de personas !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_si_novedades_persona.prc_ap_novedad_persona';
    v_indcdor  varchar2(100);
  
    r_si_g_novedades_persona      si_g_novedades_persona%rowtype;
    r_si_g_novedades_persona_sjto si_g_novedades_persona_sjto%rowtype;
    v_cdna_update_sjto            clob := '';
    v_cdna_update_sjto_impsto     clob := '';
    v_cdna_update_prsna           clob := '';
    v_cdna_update_trcro           clob := '';
    v_cdna_update_rspnsble        clob := '';
    v_id_sjto                     si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto              si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_pais                     df_s_paises.id_pais%type;
    v_id_prsna                    si_i_personas.id_prsna%type;
    v_id_trcro                    si_c_terceros.id_trcro%type;
    v_id_acto                     number;
    v_id_instncia_fljo            number;
    v_id_mtvo                     number;
    v_idntfccion_sjto             number;
    v_tpo_prsna                   varchar2(1);
    v_id_sjto_estdo               si_i_sujetos_impuesto.id_sjto_estdo%type;
  
    v_cdgo_rspsta si_d_novedades_prsna_estdo.cdgo_rspsta%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    -- DE ACUERDO AL TIPO DE NOVEDAD SE TOMAN LAS ACCIONES --
  
    --Copiado del paquete que entrego Shirley a QA
    --##
    if r_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' then
      -- Se consultan los datos del nuevo sujeto
      begin
        select *
          into r_si_g_novedades_persona_sjto
          from si_g_novedades_persona_sjto
         where id_nvdad_prsna = p_id_nvdad_prsna;
      
        -- Se valida si el sujeto ya existe
        begin
          select id_sjto
            into v_id_sjto
            from si_c_sujetos
           where cdgo_clnte = p_cdgo_clnte
             and idntfccion = r_si_g_novedades_persona_sjto.idntfccion;
        
          -- Consultamos si el Sujeto impuesto Existe
          begin
            select id_sjto_impsto
              into v_id_sjto_impsto
              from si_i_sujetos_impuesto
             where id_sjto = v_id_sjto
               and id_impsto = r_si_g_novedades_persona.id_impsto;
          
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := ' la solicitud de inscripci¿n no se puede aplicar  debido a que el contribuyente ya existe';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta || ' v_id_sjto_impsto: ' ||
                                  v_id_sjto_impsto,
                                  1);
            rollback;
            return;
          exception
            when no_data_found then
              if r_si_g_novedades_persona.id_sjto_impsto is null then
                -- Se registrar el sujeto impuesto
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
                     fcha_rgstro,
                     id_usrio,
                     id_sjto_estdo,
                     fcha_ultma_nvdad)
                  values
                    (v_id_sjto,
                     r_si_g_novedades_persona.id_impsto,
                     'N',
                     r_si_g_novedades_persona_sjto.id_pais_ntfccion,
                     r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                     r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                     r_si_g_novedades_persona_sjto.drccion_ntfccion,
                     r_si_g_novedades_persona_sjto.email,
                     r_si_g_novedades_persona_sjto.tlfno,
                     systimestamp,
                     p_id_usrio,
                     1,
                     systimestamp)
                  returning id_sjto_impsto into v_id_sjto_impsto;
                exception
                  when others then
                    o_cdgo_rspsta  := 15;
                    o_mnsje_rspsta := 'Error al insertar la informaci¿n del sujeto impuesto. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Cod Respuesta: ' ||
                                          o_cdgo_rspsta || '. ' ||
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- FIN Se registrar el sujeto impuesto
              
                -- Se registran los datos de la persona
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
                     id_actvdad_ecnmca,
                     id_sjto_tpo)
                  values
                    (v_id_sjto_impsto,
                     r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                     r_si_g_novedades_persona_sjto.tpo_prsna,
                     r_si_g_novedades_persona_sjto.nmbre_rzon_scial,
                     r_si_g_novedades_persona_sjto.nmro_rgstro_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.fcha_rgstro_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.fcha_incio_actvddes,
                     r_si_g_novedades_persona_sjto.nmro_scrsles,
                     r_si_g_novedades_persona_sjto.drccion_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.id_actvdad_ecnmca,
                     r_si_g_novedades_persona_sjto.id_sjto_tpo)
                  returning id_prsna into v_id_prsna;
                exception
                  when others then
                    o_cdgo_rspsta  := 16;
                    o_mnsje_rspsta := 'Error al insertar la informaci¿n de persona. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Cod Respuesta: ' ||
                                          o_cdgo_rspsta || '. ' ||
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- FIN Se registran los datos de la persona
              
                -- Se registran los responsables
                -- Si el tipo de persona es natural, se guarda como responsable principal
                if r_si_g_novedades_persona_sjto.tpo_prsna = 'N' then
                  begin
                    select id_trcro
                      into v_id_trcro
                      from si_c_terceros
                     where cdgo_clnte = p_cdgo_clnte
                       and idntfccion =
                           r_si_g_novedades_persona_sjto.idntfccion;
                  
                    -- Actualizamos el tercero
                    begin
                      update si_c_terceros
                         set cdgo_idntfccion_tpo  = r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                             idntfccion           = r_si_g_novedades_persona_sjto.idntfccion,
                             prmer_nmbre          = r_si_g_novedades_persona_sjto.prmer_nmbre,
                             sgndo_nmbre          = r_si_g_novedades_persona_sjto.sgndo_nmbre,
                             prmer_aplldo         = r_si_g_novedades_persona_sjto.prmer_aplldo,
                             sgndo_aplldo         = r_si_g_novedades_persona_sjto.sgndo_aplldo,
                             drccion              = r_si_g_novedades_persona_sjto.drccion,
                             id_pais              = r_si_g_novedades_persona_sjto.id_pais,
                             id_dprtmnto          = r_si_g_novedades_persona_sjto.id_dprtmnto,
                             id_mncpio            = r_si_g_novedades_persona_sjto.id_mncpio,
                             drccion_ntfccion     = r_si_g_novedades_persona_sjto.drccion_ntfccion,
                             id_pais_ntfccion     = r_si_g_novedades_persona_sjto.id_pais_ntfccion,
                             id_dprtmnto_ntfccion = r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                             id_mncpio_ntfccion   = r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                             email                = r_si_g_novedades_persona_sjto.email,
                             tlfno                = r_si_g_novedades_persona_sjto.tlfno,
                             cllar                = r_si_g_novedades_persona_sjto.cllar,
                             indcdor_cntrbynte    = 'N',
                             indcdr_fncnrio       = 'N'
                       where id_trcro = v_id_trcro;
                    exception
                      when others then
                        o_cdgo_rspsta  := 25;
                        o_mnsje_rspsta := 'Error al actualizar el tercero ' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' ||
                                              o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end;
                    -- Fin Actualizamos el tercero
                  
                  exception
                    when no_data_found then
                      -- Se inserta el tercero
                      begin
                        insert into si_c_terceros
                          (cdgo_clnte,
                           cdgo_idntfccion_tpo,
                           idntfccion,
                           prmer_nmbre,
                           sgndo_nmbre,
                           prmer_aplldo,
                           sgndo_aplldo,
                           drccion,
                           id_pais,
                           id_dprtmnto,
                           id_mncpio,
                           drccion_ntfccion,
                           id_pais_ntfccion,
                           id_dprtmnto_ntfccion,
                           id_mncpio_ntfccion,
                           email,
                           tlfno,
                           cllar,
                           indcdor_cntrbynte,
                           indcdr_fncnrio)
                        values
                          (p_cdgo_clnte,
                           r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                           r_si_g_novedades_persona_sjto.idntfccion,
                           r_si_g_novedades_persona_sjto.prmer_nmbre,
                           r_si_g_novedades_persona_sjto.sgndo_nmbre,
                           r_si_g_novedades_persona_sjto.prmer_aplldo,
                           r_si_g_novedades_persona_sjto.sgndo_aplldo,
                           r_si_g_novedades_persona_sjto.drccion,
                           r_si_g_novedades_persona_sjto.id_pais,
                           r_si_g_novedades_persona_sjto.id_dprtmnto,
                           r_si_g_novedades_persona_sjto.id_mncpio,
                           r_si_g_novedades_persona_sjto.drccion_ntfccion,
                           r_si_g_novedades_persona_sjto.id_pais_ntfccion,
                           r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                           r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                           r_si_g_novedades_persona_sjto.email,
                           r_si_g_novedades_persona_sjto.tlfno,
                           r_si_g_novedades_persona_sjto.cllar,
                           'N',
                           'N')
                        returning id_trcro into v_id_trcro;
                      exception
                        when others then
                          o_cdgo_rspsta  := 17;
                          o_mnsje_rspsta := 'Error al insertar el tercero ' ||
                                            sqlerrm;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                'Cod Respuesta: ' ||
                                                o_cdgo_rspsta || '. ' ||
                                                o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                      end; -- FIN Se inserta el tercero
                    when others then
                      o_cdgo_rspsta  := 18;
                      o_mnsje_rspsta := 'Error al consultar el id del tercero ' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end;
                
                  -- Se registra el responsable
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
                       id_pais_ntfccion,
                       id_dprtmnto_ntfccion,
                       id_mncpio_ntfccion,
                       drccion_ntfccion,
                       tlfno,
                       cllar,
                       id_trcro,
                       orgen_dcmnto)
                    values
                      (v_id_sjto_impsto,
                       r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                       r_si_g_novedades_persona_sjto.idntfccion,
                       r_si_g_novedades_persona_sjto.prmer_nmbre,
                       r_si_g_novedades_persona_sjto.sgndo_nmbre,
                       r_si_g_novedades_persona_sjto.prmer_aplldo,
                       r_si_g_novedades_persona_sjto.sgndo_aplldo,
                       'S',
                       'L',
                       v_id_pais,
                       r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                       r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                       r_si_g_novedades_persona_sjto.drccion_ntfccion,
                       r_si_g_novedades_persona_sjto.tlfno,
                       r_si_g_novedades_persona_sjto.cllar,
                       v_id_trcro,
                       1);
                  exception
                    when others then
                      o_cdgo_rspsta  := 19;
                      o_mnsje_rspsta := 'Error al insertar el responsable ' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end; -- FIN Se registra el responsable
                else
                  -- Consulta de resposables
                  for c_rspnsbles in (select *
                                        from si_g_novddes_prsna_rspnsble
                                       where id_nvdad_prsna =
                                             p_id_nvdad_prsna) loop
                    -- Se consulta el tercero
                    begin
                      select id_trcro
                        into v_id_trcro
                        from si_c_terceros
                       where cdgo_clnte = p_cdgo_clnte
                         and idntfccion = c_rspnsbles.idntfccion;
                    
                      -- Actualizamos el tercero
                      begin
                        update si_c_terceros
                           set cdgo_idntfccion_tpo  = c_rspnsbles.cdgo_idntfccion_tpo,
                               idntfccion           = c_rspnsbles.idntfccion,
                               prmer_nmbre          = c_rspnsbles.prmer_nmbre,
                               sgndo_nmbre          = c_rspnsbles.sgndo_nmbre,
                               prmer_aplldo         = c_rspnsbles.prmer_aplldo,
                               sgndo_aplldo         = c_rspnsbles.sgndo_aplldo,
                               drccion              = c_rspnsbles.drccion_ntfccion,
                               id_pais              = c_rspnsbles.id_pais_ntfccion,
                               id_dprtmnto          = c_rspnsbles.id_dprtmnto_ntfccion,
                               id_mncpio            = c_rspnsbles.id_mncpio_ntfccion,
                               drccion_ntfccion     = c_rspnsbles.drccion_ntfccion,
                               id_pais_ntfccion     = c_rspnsbles.id_pais_ntfccion,
                               id_dprtmnto_ntfccion = c_rspnsbles.id_dprtmnto_ntfccion,
                               id_mncpio_ntfccion   = c_rspnsbles.id_mncpio_ntfccion,
                               email                = c_rspnsbles.email,
                               tlfno                = c_rspnsbles.tlfno,
                               cllar                = c_rspnsbles.cllar,
                               indcdor_cntrbynte    = 'N',
                               indcdr_fncnrio       = 'N'
                         where id_trcro = v_id_trcro;
                      exception
                        when others then
                          o_cdgo_rspsta  := 25;
                          o_mnsje_rspsta := 'Error al actualizar el tercero ' ||
                                            sqlerrm;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                'Cod Respuesta: ' ||
                                                o_cdgo_rspsta || '. ' ||
                                                o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                      end;
                      -- Fin Actualizamos el tercero
                    
                    exception
                      when no_data_found then
                        -- Se registra el tercero
                        begin
                          insert into si_c_terceros
                            (cdgo_clnte,
                             cdgo_idntfccion_tpo,
                             idntfccion,
                             prmer_nmbre,
                             sgndo_nmbre,
                             prmer_aplldo,
                             sgndo_aplldo,
                             drccion,
                             id_pais,
                             id_dprtmnto,
                             id_mncpio,
                             drccion_ntfccion,
                             id_pais_ntfccion,
                             id_dprtmnto_ntfccion,
                             id_mncpio_ntfccion,
                             email,
                             tlfno,
                             cllar,
                             indcdor_cntrbynte,
                             indcdr_fncnrio)
                          values
                            (p_cdgo_clnte,
                             c_rspnsbles.cdgo_idntfccion_tpo,
                             c_rspnsbles.idntfccion,
                             c_rspnsbles.prmer_nmbre,
                             c_rspnsbles.sgndo_nmbre,
                             c_rspnsbles.prmer_aplldo,
                             c_rspnsbles.sgndo_aplldo,
                             c_rspnsbles.drccion_ntfccion,
                             c_rspnsbles.id_pais_ntfccion,
                             c_rspnsbles.id_dprtmnto_ntfccion,
                             c_rspnsbles.id_mncpio_ntfccion,
                             c_rspnsbles.drccion_ntfccion,
                             c_rspnsbles.id_pais_ntfccion,
                             c_rspnsbles.id_dprtmnto_ntfccion,
                             c_rspnsbles.id_mncpio_ntfccion,
                             c_rspnsbles.email,
                             c_rspnsbles.tlfno,
                             c_rspnsbles.cllar,
                             'N',
                             'N')
                          returning id_trcro into v_id_trcro;
                        exception
                          when others then
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := 'Error al insertar el tercero ' ||
                                              sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  v_nmbre_up,
                                                  v_nl,
                                                  'Cod Respuesta: ' ||
                                                  o_cdgo_rspsta || '. ' ||
                                                  o_mnsje_rspsta,
                                                  1);
                            rollback;
                            return;
                        end; -- Fin Se registra el tercero
                      when others then
                        o_cdgo_rspsta  := 21;
                        o_mnsje_rspsta := 'Error al consultar el tercero' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' ||
                                              o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- FIN Se consulta el tercero
                  
                    -- Se registra el responsable
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
                         id_pais_ntfccion,
                         id_dprtmnto_ntfccion,
                         id_mncpio_ntfccion,
                         drccion_ntfccion,
                         tlfno,
                         cllar,
                         id_trcro,
                         orgen_dcmnto)
                      values
                        (v_id_sjto_impsto,
                         c_rspnsbles.cdgo_idntfccion_tpo,
                         c_rspnsbles.idntfccion,
                         c_rspnsbles.prmer_nmbre,
                         c_rspnsbles.sgndo_nmbre,
                         c_rspnsbles.prmer_aplldo,
                         c_rspnsbles.sgndo_aplldo,
                         c_rspnsbles.prncpal_s_n,
                         c_rspnsbles.cdgo_tpo_rspnsble,
                         v_id_pais,
                         c_rspnsbles.id_dprtmnto_ntfccion,
                         c_rspnsbles.id_mncpio_ntfccion,
                         c_rspnsbles.drccion_ntfccion,
                         c_rspnsbles.tlfno,
                         c_rspnsbles.cllar,
                         v_id_trcro,
                         1);
                    exception
                      when others then
                        o_cdgo_rspsta  := 22;
                        o_mnsje_rspsta := 'Error al insertar el responsable' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' ||
                                              o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- FIN Se registra el responsable
                  end loop; -- Fin consulta de resposables
                end if; -- Fin Se registran los responsables
              
                -- Registro de las actividades economicas
                for c_actvddes in (select *
                                     from si_g_nvddes_prsna_actvd_eco
                                    where id_nvdad_prsna = p_id_nvdad_prsna) loop
                  begin
                    insert into si_i_prsnas_actvdad_ecnmca
                      (id_prsna, id_actvdad_ecnmca, fcha_incio_actvdad)
                    values
                      (v_id_prsna,
                       c_actvddes.id_actvdad_ecnmca,
                       c_actvddes.fcha_incio_actvdad);
                  exception
                    when others then
                      o_cdgo_rspsta  := 23;
                      o_mnsje_rspsta := 'Error al insertar la actividad economica' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end;
                end loop; -- FIN Registro de las actividades economicas
              
              else
                v_id_sjto_impsto := r_si_g_novedades_persona.id_sjto_impsto;
              end if;
            when others then
              o_cdgo_rspsta  := 24;
              o_mnsje_rspsta := ' Error al consultar informaci¿n del sujeto Impuesto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
          -- Fin Consultamos si el Sujeto impuesto Existe
        
        exception
          when no_data_found then
            -- si no existe creamos el sujeto
            begin
              select id_pais
                into v_id_pais
                from df_s_clientes
               where cdgo_clnte = p_cdgo_clnte;
            
              if r_si_g_novedades_persona.id_sjto_impsto is null then
                -- Se registrar el sujeto
                begin
                  insert into si_c_sujetos
                    (cdgo_clnte,
                     idntfccion,
                     idntfccion_antrior,
                     id_pais,
                     id_dprtmnto,
                     id_mncpio,
                     drccion,
                     fcha_ingrso,
                     estdo_blqdo)
                  values
                    (p_cdgo_clnte,
                     r_si_g_novedades_persona_sjto.idntfccion,
                     r_si_g_novedades_persona_sjto.idntfccion,
                     v_id_pais,
                     r_si_g_novedades_persona_sjto.id_dprtmnto,
                     r_si_g_novedades_persona_sjto.id_mncpio,
                     r_si_g_novedades_persona_sjto.drccion,
                     sysdate,
                     'N')
                  returning id_sjto into v_id_sjto;
                exception
                  when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'Error al insertar la informaci¿n del sujeto. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Cod Respuesta: ' ||
                                          o_cdgo_rspsta || '. ' ||
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- FIN Se registrar el sujeto
              
                -- Se registrar el sujeto impuesto
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
                     fcha_rgstro,
                     id_usrio,
                     id_sjto_estdo,
                     fcha_ultma_nvdad)
                  values
                    (v_id_sjto,
                     r_si_g_novedades_persona.id_impsto,
                     'N',
                     r_si_g_novedades_persona_sjto.id_pais_ntfccion,
                     r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                     r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                     r_si_g_novedades_persona_sjto.drccion_ntfccion,
                     r_si_g_novedades_persona_sjto.email,
                     r_si_g_novedades_persona_sjto.tlfno,
                     systimestamp,
                     p_id_usrio,
                     1,
                     systimestamp)
                  returning id_sjto_impsto into v_id_sjto_impsto;
                exception
                  when others then
                    o_cdgo_rspsta  := 6;
                    o_mnsje_rspsta := 'Error al insertar la informaci¿n del sujeto impuesto. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Cod Respuesta: ' ||
                                          o_cdgo_rspsta || '. ' ||
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- FIN Se registrar el sujeto impuesto
              
                -- Se registran los datos de la persona
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
                     id_actvdad_ecnmca,
                     id_sjto_tpo)
                  values
                    (v_id_sjto_impsto,
                     r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                     r_si_g_novedades_persona_sjto.tpo_prsna,
                     r_si_g_novedades_persona_sjto.nmbre_rzon_scial,
                     r_si_g_novedades_persona_sjto.nmro_rgstro_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.fcha_rgstro_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.fcha_incio_actvddes,
                     r_si_g_novedades_persona_sjto.nmro_scrsles,
                     r_si_g_novedades_persona_sjto.drccion_cmra_cmrcio,
                     r_si_g_novedades_persona_sjto.id_actvdad_ecnmca,
                     r_si_g_novedades_persona_sjto.id_sjto_tpo)
                  returning id_prsna into v_id_prsna;
                exception
                  when others then
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := 'Error al insertar la informaci¿n de persona. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          'Cod Respuesta: ' ||
                                          o_cdgo_rspsta || '. ' ||
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- FIN Se registran los datos de la persona
              
                -- Se registran los responsables
                -- Si el tipo de persona es natural, se guarda como responsable principal
                if r_si_g_novedades_persona_sjto.tpo_prsna = 'N' then
                  begin
                    select id_trcro
                      into v_id_trcro
                      from si_c_terceros
                     where cdgo_clnte = p_cdgo_clnte
                       and idntfccion =
                           r_si_g_novedades_persona_sjto.idntfccion;
                  exception
                    when no_data_found then
                      -- Se inserta el tercero
                      begin
                        insert into si_c_terceros
                          (cdgo_clnte,
                           cdgo_idntfccion_tpo,
                           idntfccion,
                           prmer_nmbre,
                           sgndo_nmbre,
                           prmer_aplldo,
                           sgndo_aplldo,
                           drccion,
                           id_pais,
                           id_dprtmnto,
                           id_mncpio,
                           drccion_ntfccion,
                           id_pais_ntfccion,
                           id_dprtmnto_ntfccion,
                           id_mncpio_ntfccion,
                           email,
                           tlfno,
                           cllar,
                           indcdor_cntrbynte,
                           indcdr_fncnrio)
                        values
                          (p_cdgo_clnte,
                           r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                           r_si_g_novedades_persona_sjto.idntfccion,
                           r_si_g_novedades_persona_sjto.prmer_nmbre,
                           r_si_g_novedades_persona_sjto.sgndo_nmbre,
                           r_si_g_novedades_persona_sjto.prmer_aplldo,
                           r_si_g_novedades_persona_sjto.sgndo_aplldo,
                           r_si_g_novedades_persona_sjto.drccion,
                           r_si_g_novedades_persona_sjto.id_pais,
                           r_si_g_novedades_persona_sjto.id_dprtmnto,
                           r_si_g_novedades_persona_sjto.id_mncpio,
                           r_si_g_novedades_persona_sjto.drccion_ntfccion,
                           r_si_g_novedades_persona_sjto.id_pais_ntfccion,
                           r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                           r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                           r_si_g_novedades_persona_sjto.email,
                           r_si_g_novedades_persona_sjto.tlfno,
                           r_si_g_novedades_persona_sjto.cllar,
                           'N',
                           'N')
                        returning id_trcro into v_id_trcro;
                      exception
                        when others then
                          o_cdgo_rspsta  := 9;
                          o_mnsje_rspsta := 'Error al insertar el tercero ' ||
                                            sqlerrm;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                'Cod Respuesta: ' ||
                                                o_cdgo_rspsta || '. ' ||
                                                o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                      end; -- FIN Se inserta el tercero
                    when others then
                      o_cdgo_rspsta  := 8;
                      o_mnsje_rspsta := 'Error al consultar el id del tercero ' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end;
                
                  -- Se registra el responsable
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
                       id_pais_ntfccion,
                       id_dprtmnto_ntfccion,
                       id_mncpio_ntfccion,
                       drccion_ntfccion,
                       tlfno,
                       cllar,
                       id_trcro,
                       orgen_dcmnto)
                    values
                      (v_id_sjto_impsto,
                       r_si_g_novedades_persona_sjto.cdgo_idntfccion_tpo,
                       r_si_g_novedades_persona_sjto.idntfccion,
                       r_si_g_novedades_persona_sjto.prmer_nmbre,
                       r_si_g_novedades_persona_sjto.sgndo_nmbre,
                       r_si_g_novedades_persona_sjto.prmer_aplldo,
                       r_si_g_novedades_persona_sjto.sgndo_aplldo,
                       'S',
                       'L',
                       v_id_pais,
                       r_si_g_novedades_persona_sjto.id_dprtmnto_ntfccion,
                       r_si_g_novedades_persona_sjto.id_mncpio_ntfccion,
                       r_si_g_novedades_persona_sjto.drccion_ntfccion,
                       r_si_g_novedades_persona_sjto.tlfno,
                       r_si_g_novedades_persona_sjto.cllar,
                       v_id_trcro,
                       1);
                  exception
                    when others then
                      o_cdgo_rspsta  := 10;
                      o_mnsje_rspsta := 'Error al insertar el responsable ' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end; -- FIN Se registra el responsable
                else
                  -- Consulta de resposables
                  for c_rspnsbles in (select *
                                        from si_g_novddes_prsna_rspnsble
                                       where id_nvdad_prsna =
                                             p_id_nvdad_prsna) loop
                    -- Se consulta el tercero
                    begin
                      select id_trcro
                        into v_id_trcro
                        from si_c_terceros
                       where cdgo_clnte = p_cdgo_clnte
                         and idntfccion = c_rspnsbles.idntfccion;
                    exception
                      when no_data_found then
                        -- Se registra el tercero
                        begin
                          insert into si_c_terceros
                            (cdgo_clnte,
                             cdgo_idntfccion_tpo,
                             idntfccion,
                             prmer_nmbre,
                             sgndo_nmbre,
                             prmer_aplldo,
                             sgndo_aplldo,
                             drccion,
                             id_pais,
                             id_dprtmnto,
                             id_mncpio,
                             drccion_ntfccion,
                             id_pais_ntfccion,
                             id_dprtmnto_ntfccion,
                             id_mncpio_ntfccion,
                             email,
                             tlfno,
                             cllar,
                             indcdor_cntrbynte,
                             indcdr_fncnrio)
                          values
                            (p_cdgo_clnte,
                             c_rspnsbles.cdgo_idntfccion_tpo,
                             c_rspnsbles.idntfccion,
                             c_rspnsbles.prmer_nmbre,
                             c_rspnsbles.sgndo_nmbre,
                             c_rspnsbles.prmer_aplldo,
                             c_rspnsbles.sgndo_aplldo,
                             c_rspnsbles.drccion_ntfccion,
                             c_rspnsbles.id_pais_ntfccion,
                             c_rspnsbles.id_dprtmnto_ntfccion,
                             c_rspnsbles.id_mncpio_ntfccion,
                             c_rspnsbles.drccion_ntfccion,
                             c_rspnsbles.id_pais_ntfccion,
                             c_rspnsbles.id_dprtmnto_ntfccion,
                             c_rspnsbles.id_mncpio_ntfccion,
                             c_rspnsbles.email,
                             c_rspnsbles.tlfno,
                             c_rspnsbles.cllar,
                             'N',
                             'N')
                          returning id_trcro into v_id_trcro;
                        exception
                          when others then
                            o_cdgo_rspsta  := 12;
                            o_mnsje_rspsta := 'Error al insertar el tercero ' ||
                                              sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  v_nmbre_up,
                                                  v_nl,
                                                  'Cod Respuesta: ' ||
                                                  o_cdgo_rspsta || '. ' ||
                                                  o_mnsje_rspsta,
                                                  1);
                            rollback;
                            return;
                        end; -- Fin Se registra el tercero
                      when others then
                        o_cdgo_rspsta  := 11;
                        o_mnsje_rspsta := 'Error al consultar el tercero' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' ||
                                              o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- FIN Se consulta el tercero
                  
                    -- Se registra el responsable
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
                         id_pais_ntfccion,
                         id_dprtmnto_ntfccion,
                         id_mncpio_ntfccion,
                         drccion_ntfccion,
                         tlfno,
                         cllar,
                         id_trcro,
                         orgen_dcmnto)
                      values
                        (v_id_sjto_impsto,
                         c_rspnsbles.cdgo_idntfccion_tpo,
                         c_rspnsbles.idntfccion,
                         c_rspnsbles.prmer_nmbre,
                         c_rspnsbles.sgndo_nmbre,
                         c_rspnsbles.prmer_aplldo,
                         c_rspnsbles.sgndo_aplldo,
                         c_rspnsbles.prncpal_s_n,
                         c_rspnsbles.cdgo_tpo_rspnsble,
                         v_id_pais,
                         c_rspnsbles.id_dprtmnto_ntfccion,
                         c_rspnsbles.id_mncpio_ntfccion,
                         c_rspnsbles.drccion_ntfccion,
                         c_rspnsbles.tlfno,
                         c_rspnsbles.cllar,
                         v_id_trcro,
                         1);
                    exception
                      when others then
                        o_cdgo_rspsta  := 13;
                        o_mnsje_rspsta := 'Error al insertar el responsable' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'Cod Respuesta: ' ||
                                              o_cdgo_rspsta || '. ' ||
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- FIN Se registra el responsable
                  end loop; -- Fin consulta de resposables
                end if; -- Fin Se registran los responsables
              
                -- Registro de las actividades economicas
                for c_actvddes in (select *
                                     from si_g_nvddes_prsna_actvd_eco
                                    where id_nvdad_prsna = p_id_nvdad_prsna) loop
                  begin
                    insert into si_i_prsnas_actvdad_ecnmca
                      (id_prsna, id_actvdad_ecnmca, fcha_incio_actvdad)
                    values
                      (v_id_prsna,
                       c_actvddes.id_actvdad_ecnmca,
                       c_actvddes.fcha_incio_actvdad);
                  exception
                    when others then
                      o_cdgo_rspsta  := 14;
                      o_mnsje_rspsta := 'Error al insertar la actividad economica' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            'Cod Respuesta: ' ||
                                            o_cdgo_rspsta || '. ' ||
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end;
                end loop; -- FIN Registro de las actividades economicas
              else
                v_id_sjto_impsto := r_si_g_novedades_persona.id_sjto_impsto;
              end if;
            end;
          
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := ' Error al consultar informaci¿n del sujeto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin Se valida si el sujeto  ya existe
      
        --##
        -- Registro de las sucursales
        for c_sucursales in (select *
                               from si_g_nvddes_prsna_scrsal
                              where id_nvdad_prsna = p_id_nvdad_prsna
                              and estdo != 'EXISTENTE') loop
          begin
            insert into si_i_sujetos_sucursal
              (id_sjto_impsto,
               id_sjto,
               cdgo_scrsal,
               nmbre,
               drccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               tlfno,
               cllar,
               email,
               actvo)
            values
              (v_id_sjto_impsto,
               v_id_sjto,
               c_sucursales.cdgo_scrsal,
               c_sucursales.nmbre,
               c_sucursales.drccion,
               c_sucursales.id_dprtmnto_ntfccion,
               c_sucursales.id_mncpio_ntfccion,
               c_sucursales.tlfno,
               c_sucursales.cllar,
               c_sucursales.email,
               c_sucursales.actvo);
          
          exception
            when others then
              o_cdgo_rspsta  := 23;
              o_mnsje_rspsta := 'Error al insertar las sucursales' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        end loop; -- FIN Registro de las sucursales
        --##
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontro informaci¿n del sujeto a inscribir. ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al consultar la informaci¿n del sujeto a inscribir. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- FIN Se consultan los datos del nuevo sujeto
    end if; -- FIN Si el tipo de novedad es INSCRIPCI¿N
  
    -- Fin Copiado del paquete que entrego Shirley a QA
    --##
  
    -- Si el tipo de novedad es ACTUALIZACI¿N, se actualizan los datos del sujeto, sujeto impuesto, persona actividades economicas y responsables
    if r_si_g_novedades_persona.cdgo_nvdad_tpo = 'ACT' then
    
      --Si vefirica si el sujeto es Omiso para cambiarlo a estado activo
      begin
      
        select id_sjto_estdo
          into v_id_sjto_estdo
          from si_i_sujetos_impuesto
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      
        if v_id_sjto_estdo = 3 then
          -- Estado Omiso
          begin
            pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                    p_id_usrio       => p_id_usrio,
                                                                    o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta   => o_mnsje_rspsta);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  6);
          
            if o_cdgo_rspsta = 0 then
              update si_i_sujetos_impuesto
                 set id_sjto_estdo = 1, fcha_ultma_nvdad = systimestamp
               where id_sjto_impsto =
                     r_si_g_novedades_persona.id_sjto_impsto;
            else
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    6);
              rollback;
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error al actualizar el sujeto impuesto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al actualizar el estado del sujeto . ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; --Fin Si es un sujeto Omiso, se cambia a estado activo
    
      -- Se conusltan los cambios realizados a sujeto, sujeto impuesto y persona para armar las cadenas de actualizaci¿n
      for c_cmbios in (select *
                         from si_g_novedades_prsna_dtlle a
                        where id_nvdad_prsna = p_id_nvdad_prsna) loop
        -- Sujetos
        if c_cmbios.atrbto in ('P34_IDNTFCCION') then
          v_cdna_update_sjto := v_cdna_update_sjto ||
                                'IDNTFCCION_ANTRIOR = IDNTFCCION, ' ||
                                lower(substr(c_cmbios.atrbto, 5)) || ' = ' || '''' ||
                                c_cmbios.vlor_nvo || '''' || ' ,';
        elsif c_cmbios.atrbto in
              ('P34_DRCCION', 'P34_ID_DPRTMNTO', 'P34_ID_MNCPIO') then
          v_cdna_update_sjto := v_cdna_update_sjto ||
                                lower(substr(c_cmbios.atrbto, 5)) || ' = ' || '''' ||
                                c_cmbios.vlor_nvo || '''' || ' ,';
        elsif c_cmbios.atrbto in ('P122_IDNTFCCION',
                                  'P122_DRCCION',
                                  'P122_ID_DPRTMNTO',
                                  'P122_ID_MNCPIO') then
          v_cdna_update_sjto := v_cdna_update_sjto ||
                                lower(substr(c_cmbios.atrbto, 6)) || ' = ' || '''' ||
                                c_cmbios.vlor_nvo || '''' || ' ,';
        
          -- Sujeto Impuesto
        elsif c_cmbios.atrbto in ('P34_ID_DPRTMNTO_NTFCCION',
                                  'P34_ID_MNCPIO_NTFCCION',
                                  'P34_DRCCION_NTFCCION',
                                  'P34_TLFNO',
                                  'P34_EMAIL') then
          v_cdna_update_sjto_impsto := v_cdna_update_sjto_impsto ||
                                       lower(substr(c_cmbios.atrbto, 5)) ||
                                       ' = ' || '''' || c_cmbios.vlor_nvo || '''' || ' ,';
        
        elsif c_cmbios.atrbto in ('P122_ID_DPRTMNTO_NTFCCION',
                                  'P122_ID_MNCPIO_NTFCCION',
                                  'P122_DRCCION_NTFCCION',
                                  'P122_TLFNO',
                                  'P122_EMAIL') then
          v_cdna_update_sjto_impsto := v_cdna_update_sjto_impsto ||
                                       lower(substr(c_cmbios.atrbto, 6)) ||
                                       ' = ' || '''' || c_cmbios.vlor_nvo || '''' || ' ,';
          -- Persona
        elsif c_cmbios.atrbto in
              ('P34_TPO_PRSNA',
               'P34_CDGO_IDNTFCCION_TPO',
               'P34_NMBRE_RZON_SCIAL',
               'P34_ID_SJTO_TPO',
               'P34_NMRO_RGSTRO_CMRA_CMRCIO',
               'P34_FCHA_RGSTRO_CMRA_CMRCIO',
               'P34_FCHA_INCIO_ACTVDDES',
               'P34_NMRO_SCRSLES',
               'P34_DRCCION_CMRA_CMRCIO',
               'P34_ID_ACTVDAD_ECNMCA') then
          v_cdna_update_prsna := v_cdna_update_prsna ||
                                 lower(substr(c_cmbios.atrbto, 5)) || ' = ' || '''' ||
                                 c_cmbios.vlor_nvo || '''' || ' ,';
        elsif c_cmbios.atrbto in
              ('P122_TPO_PRSNA',
               'P122_CDGO_IDNTFCCION_TPO',
               'P122_NMBRE_RZON_SCIAL',
               'P122_ID_SJTO_TPO',
               'P122_NMRO_RGSTRO_CMRA_CMRCIO',
               'P122_FCHA_RGSTRO_CMRA_CMRCIO',
               'P122_FCHA_INCIO_ACTVDDES',
               'P122_NMRO_SCRSLES',
               'P122_DRCCION_CMRA_CMRCIO',
               'P122_ID_ACTVDAD_ECNMCA') then
          v_cdna_update_prsna := v_cdna_update_prsna ||
                                 lower(substr(c_cmbios.atrbto, 6)) || ' = ' || '''' ||
                                 c_cmbios.vlor_nvo || '''' || ' ,';
          --##
          -- Terceros - Sujetos Responsable
        elsif c_cmbios.atrbto in ('P34_PRMER_NMBRE',
                                  'P34_SGNDO_NMBRE',
                                  'P34_PRMER_APLLDO',
                                  'P34_SGNDO_APLLDO') then
          v_cdna_update_trcro    := v_cdna_update_trcro ||
                                    lower(substr(c_cmbios.atrbto, 5)) ||
                                    ' = ' || '''' || c_cmbios.vlor_nvo || '''' || ' ,';
          v_cdna_update_rspnsble := v_cdna_update_rspnsble ||
                                    lower(substr(c_cmbios.atrbto, 5)) ||
                                    ' = ' || '''' || c_cmbios.vlor_nvo || '''' || ' ,';
          --##
        
        end if;
      end loop;
    
      -- Se completan cada una de las cadenas de cambios realizados.
      -- Cadena de Sujeto
      if v_cdna_update_sjto is not null then
        begin
          select a.id_sjto
            into v_id_sjto
            from si_i_sujetos_impuesto a
           where a.id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
        
          v_cdna_update_sjto := substr(v_cdna_update_sjto,
                                       1,
                                       length(v_cdna_update_sjto) - 1);
          v_cdna_update_sjto := 'begin
                                                update si_c_sujetos set ' ||
                                v_cdna_update_sjto || ' where id_sjto = ' ||
                                v_id_sjto || '; ' || 'end;';
          o_mnsje_rspsta     := 'v_cdna_update_sjto: ' ||
                                v_cdna_update_sjto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          begin
            pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto(p_cdgo_clnte     => p_cdgo_clnte,
                                                                   p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                   p_id_usrio       => p_id_usrio,
                                                                   o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                   o_mnsje_rspsta   => o_mnsje_rspsta);
            if o_cdgo_rspsta = 0 then
              execute immediate v_cdna_update_sjto;
            else
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error al actualizar el sujeto. ' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'No se encontro el id del sujeto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error al conusltar el id del sujeto' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end if;
    
      -- Cadena de sujeto Impuesto
      if v_cdna_update_sjto_impsto is not null then
        v_cdna_update_sjto_impsto := substr(v_cdna_update_sjto_impsto,
                                            1,
                                            length(v_cdna_update_sjto_impsto) - 1);
        v_cdna_update_sjto_impsto := 'begin
                                                    update si_i_sujetos_impuesto set ' ||
                                     v_cdna_update_sjto_impsto ||
                                     ' where id_sjto_impsto = ' ||
                                     r_si_g_novedades_persona.id_sjto_impsto || ';
                                             ' ||
                                     'end;';
      
        o_mnsje_rspsta := 'v_cdna_update_sjto_impsto: ' ||
                          v_cdna_update_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        begin
          pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                  p_id_usrio       => p_id_usrio,
                                                                  o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta   => o_mnsje_rspsta);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          if o_cdgo_rspsta = 0 then
            execute immediate v_cdna_update_sjto_impsto;
          else
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error al actualizar el sujeto impuesto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end if;
    
      -- Cadena de persona
      if v_cdna_update_prsna is not null then
        v_cdna_update_prsna := substr(v_cdna_update_prsna,
                                      1,
                                      length(v_cdna_update_prsna) - 1);
        v_cdna_update_prsna := 'begin
                                            update si_i_personas set ' ||
                               v_cdna_update_prsna ||
                               ' where id_sjto_impsto = ' ||
                               r_si_g_novedades_persona.id_sjto_impsto || '; ' ||
                               'end;';
      
        o_mnsje_rspsta := 'v_cdna_update_prsna: ' || v_cdna_update_prsna;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        begin
          pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna(p_cdgo_clnte     => p_cdgo_clnte,
                                                                 p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                 p_id_usrio       => p_id_usrio,
                                                                 o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta   => o_mnsje_rspsta);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          if o_cdgo_rspsta = 0 then
            execute immediate v_cdna_update_prsna;
          
            o_mnsje_rspsta := 'execute immediate v_cdna_update_prsna: ' ||
                              v_cdna_update_prsna;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
          else
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'Error al actualizar la persona. ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
        end;
      end if;
    
      --##
      begin
      
        select a.idntfccion_sjto, b.tpo_prsna
          into v_idntfccion_sjto, v_tpo_prsna
          from v_si_i_sujetos_impuesto a
          join si_i_personas b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      
        if v_cdna_update_trcro is not null then
        
          v_cdna_update_trcro := substr(v_cdna_update_trcro,
                                        1,
                                        length(v_cdna_update_trcro) - 1);
          v_cdna_update_trcro := 'begin
                                                update si_c_terceros set ' ||
                                 v_cdna_update_trcro ||
                                 ' where idntfccion = ' || '''' ||
                                 v_idntfccion_sjto || '''' || '; ' ||
                                 'end;';
        
          o_mnsje_rspsta := 'v_cdna_update_trcro: ' || v_cdna_update_trcro;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          execute immediate v_cdna_update_trcro;
        
        end if;
      
        --Actualiza la informacion del responsable si es persona Natural
        if v_cdna_update_rspnsble is not null and v_tpo_prsna = 'N' then
        
          begin
            pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                    p_id_usrio       => p_id_usrio,
                                                                    o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta   => o_mnsje_rspsta);
            -- Validaci¿n de la respuesta del registro de los historico de los responsables
            if o_cdgo_rspsta = 0 then
            
              v_cdna_update_rspnsble := substr(v_cdna_update_rspnsble,
                                               1,
                                               length(v_cdna_update_rspnsble) - 1);
              v_cdna_update_rspnsble := 'begin
                                                            update si_i_sujetos_responsable set ' ||
                                        v_cdna_update_rspnsble ||
                                        ' where id_sjto_impsto = ' ||
                                        r_si_g_novedades_persona.id_sjto_impsto ||
                                        ' and idntfccion = ' ||
                                        v_idntfccion_sjto || '; ' || 'end;';
            
              o_mnsje_rspsta := 'v_cdna_update_rspnsble: ' ||
                                v_cdna_update_rspnsble;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              execute immediate v_cdna_update_rspnsble;
            else
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al registrar el historico de responsables . ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    6);
              rollback;
              return;
            end if; -- Fin Validaci¿n de la respuesta del registro de los historico de los responsables
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al actualizar el responsables. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    6);
              rollback;
              return;
          end;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al actualizar el tercero y responsables . ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- FIN   --Actualiza la informacion del responsable si es persona Natural
    
      --##
    
      -- Actualizaci¿n de los datos de los responsables
      begin
        pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb(p_cdgo_clnte     => p_cdgo_clnte,
                                                                p_id_nvdad_prsna => p_id_nvdad_prsna,
                                                                p_id_usrio       => p_id_usrio,
                                                                o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                o_mnsje_rspsta   => o_mnsje_rspsta);
        -- Validaci¿n de la respuesta del registro de los historico de los responsables
        if o_cdgo_rspsta = 0 then
          -- Se consultan la informaci¿n de los responsbales agregados y modificados
          for c_rspnsbles in (select *
                                from si_g_novddes_prsna_rspnsble a
                               where id_nvdad_prsna = p_id_nvdad_prsna) loop
            -- Si el responsable es nuevo, se inserta en la tabla de responsable
            if c_rspnsbles.estdo = 'NUEVO' then
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
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion,
                 email,
                 tlfno,
                 cllar,
                 actvo,
                 id_trcro,
                 prcntje_prtcpcion,
                 orgen_dcmnto)
              values
                (r_si_g_novedades_persona.id_sjto_impsto,
                 c_rspnsbles.cdgo_idntfccion_tpo,
                 c_rspnsbles.idntfccion,
                 c_rspnsbles.prmer_nmbre,
                 c_rspnsbles.sgndo_nmbre,
                 c_rspnsbles.prmer_aplldo,
                 c_rspnsbles.sgndo_aplldo,
                 c_rspnsbles.prncpal_s_n,
                 c_rspnsbles.cdgo_tpo_rspnsble,
                 c_rspnsbles.id_pais_ntfccion,
                 c_rspnsbles.id_dprtmnto_ntfccion,
                 c_rspnsbles.id_mncpio_ntfccion,
                 c_rspnsbles.drccion_ntfccion,
                 c_rspnsbles.email,
                 c_rspnsbles.tlfno,
                 c_rspnsbles.cllar,
                 c_rspnsbles.actvo,
                 c_rspnsbles.id_trcro,
                 c_rspnsbles.prcntje_prtcpcion,
                 nvl(c_rspnsbles.orgen_dcmnto, 1));
              -- Si el responsable ya existe, se actualizan los datos en la tabla de responsable
            else
              update si_i_sujetos_responsable a
                 set cdgo_idntfccion_tpo  = c_rspnsbles.cdgo_idntfccion_tpo,
                     idntfccion           = c_rspnsbles.idntfccion,
                     prmer_nmbre          = c_rspnsbles.prmer_nmbre,
                     sgndo_nmbre          = c_rspnsbles.sgndo_nmbre,
                     prmer_aplldo         = c_rspnsbles.prmer_aplldo,
                     sgndo_aplldo         = c_rspnsbles.sgndo_aplldo,
                     prncpal_s_n          = c_rspnsbles.prncpal_s_n,
                     cdgo_tpo_rspnsble    = c_rspnsbles.cdgo_tpo_rspnsble,
                     id_pais_ntfccion     = c_rspnsbles.id_pais_ntfccion,
                     id_dprtmnto_ntfccion = c_rspnsbles.id_dprtmnto_ntfccion,
                     id_mncpio_ntfccion   = c_rspnsbles.id_mncpio_ntfccion,
                     drccion_ntfccion     = c_rspnsbles.drccion_ntfccion,
                     email                = c_rspnsbles.email,
                     tlfno                = c_rspnsbles.tlfno,
                     cllar                = c_rspnsbles.cllar,
                     actvo                = c_rspnsbles.actvo,
                     id_trcro             = c_rspnsbles.id_trcro,
                     prcntje_prtcpcion    = c_rspnsbles.prcntje_prtcpcion,
                     orgen_dcmnto         = nvl(c_rspnsbles.orgen_dcmnto, 1)
               where id_sjto_rspnsble = c_rspnsbles.id_sjto_rspnsble;
            end if; -- Fin de registro o actualizaci¿n de la informaci¿n de los responsables
          end loop; -- FIN Se consultan la informaci¿n de los responsbales agregados y modificados
        
        else
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
        end if; -- Fin Validaci¿n de la respuesta del registro de los historico de los responsables
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al actualizar el responsables. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- FIN Actualizaci¿n de los datos de los responsables
    
      --##
      -- Actualizaci¿n de los datos de las sucursales
      begin
        select a.id_sjto
          into v_id_sjto
          from si_i_sujetos_impuesto a
         where a.id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      
        -- Se consultan la informaci¿n de las sucursales agregadas y modificadas
        for c_sucursales in (select *
                               from si_g_nvddes_prsna_scrsal a
                              where id_nvdad_prsna = p_id_nvdad_prsna) loop
                              
          -- Si la sucursal es nueva, se inserta en la tabla 
          if c_sucursales.estdo = 'NUEVO' then
            insert into si_i_sujetos_sucursal
              (id_sjto_impsto,
               id_sjto,
               cdgo_scrsal,
               nmbre,
               drccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               tlfno,
               cllar,
               email,
               actvo)
            values
              (r_si_g_novedades_persona.id_sjto_impsto,
               v_id_sjto,
               c_sucursales.cdgo_scrsal,
               c_sucursales.nmbre,
               c_sucursales.drccion,
               c_sucursales.id_dprtmnto_ntfccion,
               c_sucursales.id_mncpio_ntfccion,
               c_sucursales.tlfno,
               c_sucursales.cllar,
               c_sucursales.email,
               c_sucursales.actvo);
            -- Si la sucursal ya existe, se actualizan los datos en la tabla de sucursales
          else
            update si_i_sujetos_sucursal
               set nmbre                = c_sucursales.nmbre,
                   drccion              = c_sucursales.drccion,
                   id_dprtmnto_ntfccion = c_sucursales.id_dprtmnto_ntfccion,
                   id_mncpio_ntfccion   = c_sucursales.id_mncpio_ntfccion,
                   tlfno                = c_sucursales.tlfno,
                   cllar                = c_sucursales.cllar,
                   email                = c_sucursales.email,
                   actvo                = c_sucursales.actvo
             where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto
               and cdgo_scrsal = c_sucursales.cdgo_scrsal;
          
          end if; -- Fin de registro o actualizaci¿n de la informaci¿n de las sucursales
        end loop; -- FIN Se consultan la informaci¿n de las sucursales agregadas y modificadas
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al actualizar las sucursales. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- FIN Actualizaci¿n de los datos de las sucursales
    
    end if; -- FIN Si el tipo de novedad es ACTUALIZACI¿N
  
    -- Si el tipo de novedad es CANCELACI¿N, se cambia el estado del sujeto impuesto y se actualiza la  fecha de cancelaci¿n y de ultima novedad.
    if r_si_g_novedades_persona.cdgo_nvdad_tpo = 'CNC' then
      begin
        update si_i_sujetos_impuesto
           set id_sjto_estdo    = 2,
               fcha_ultma_nvdad = systimestamp,
               fcha_cnclcion    = systimestamp
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
        o_mnsje_rspsta := 'Se Actualizo el estado del sujeto impuesto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al actualizar el sujeto impuesto. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin actualizacion de datos del sujeto impuesto
    end if; -- FIN Si el tipo de novedad es CANCELACI¿N
  
    -- Si el tipo de novedad es ACTIVACI¿N, se cambia el estado del sujeto impuesto y se actualiza la fecha de la ¿ltima novedad
    if r_si_g_novedades_persona.cdgo_nvdad_tpo = 'ACV' then
      begin
        update si_i_sujetos_impuesto
           set id_sjto_estdo = 1, fcha_ultma_nvdad = systimestamp
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al actualizar el sujeto impuesto. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin actualizacion de datos del sujeto impuesto
    end if; -- FIN Si el tipo de novedad es ACTIVACI¿N
  
    -- Se actualizan los datos de la novedad
    begin
      update si_g_novedades_persona
         set fcha_aplco             = systimestamp,
             id_usrio_aplco         = p_id_usrio,
             id_sjto_impsto         = nvl(r_si_g_novedades_persona.id_sjto_impsto,
                                          v_id_sjto_impsto),
             cdgo_nvdad_prsna_estdo = 'APL'
       where id_nvdad_prsna = p_id_nvdad_prsna;
    
      o_mnsje_rspsta := 'Se actualizo la novedad ' || p_id_nvdad_prsna;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'Error al actualizar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualizan los datos de la novedad
  
    -- Se genera el acto de aplicaci¿n
    begin
      o_mnsje_rspsta := 'Antes de crear el acto';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_si_novedades_persona.prc_gn_acto_novedades_persona(p_cdgo_clnte             => p_cdgo_clnte,
                                                             p_id_nvdad_prsna         => p_id_nvdad_prsna,
                                                             p_cdgo_cnsctvo           => 'NPR',
                                                             p_cdgo_nvdad_prsna_estdo => 'APL',
                                                             p_id_usrio               => p_id_usrio,
                                                             o_id_acto                => v_id_acto,
                                                             o_cdgo_rspsta            => o_cdgo_rspsta,
                                                             o_mnsje_rspsta           => o_mnsje_rspsta);
      o_mnsje_rspsta := 'v_id_acto: ' || v_id_acto || ' o_cdgo_rspsta: ' ||
                        o_cdgo_rspsta || ' o_mnsje_rspsta: ' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Error al generar el acto de la novedad. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se genera el acto de aplicaci¿n
  
    -- Valida creaci¿n del acto
    if o_cdgo_rspsta = 0 and v_id_acto > 0 then
      -- Adicionamos las propiedades a PQR
      o_mnsje_rspsta := 'p_id_nvdad_prsna ' || p_id_nvdad_prsna;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
      if r_si_g_novedades_persona.id_slctud is not null then
        begin
          select a.id_instncia_fljo, b.id_mtvo, c.cdgo_rspsta
            into v_id_instncia_fljo, v_id_mtvo, v_cdgo_rspsta
            from si_g_novedades_persona a
            join pq_g_solicitudes_motivo b
              on a.id_slctud = b.id_slctud
            join si_d_novedades_prsna_estdo c
              on a.cdgo_nvdad_prsna_estdo = c.cdgo_nvdad_prsna_estdo
           where a.id_nvdad_prsna = p_id_nvdad_prsna;
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'MTV',
                                                      p_vlor             => v_id_mtvo);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'ACT',
                                                      p_vlor             => v_id_acto);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'USR',
                                                      p_vlor             => p_id_usrio);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'RSP',
                                                      p_vlor             => v_cdgo_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'Error al cerrar propiedades PQR ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin Adicionamos las propiedades a PQR
      end if;
      -- Se finaliza el flujo de la novedad
      begin
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => r_si_g_novedades_persona.id_instncia_fljo,
                                                       p_id_fljo_trea     => r_si_g_novedades_persona.id_fljo_trea,
                                                       p_id_usrio         => p_id_usrio,
                                                       o_error            => v_indcdor,
                                                       o_msg              => o_mnsje_rspsta);
      
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'Error al cerrar el flujo' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se finaliza el flujo de la novedad
    
      --Consultamos los envios programados
      declare
        v_json_parametros clob;
      begin
        select json_object(key 'ID_NVDAD_PRSNA' is p_id_nvdad_prsna)
          into v_json_parametros
          from dual;
      
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'PKG_SI_NOVEDADES_PERSONA.PRC_AP_NOVEDAD_PERSONA',
                                              p_json_prmtros => v_json_parametros);
        o_mnsje_rspsta := 'Realizo envios';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error en los envios programados, ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --Fin Consultamos los envios programados
    else
      o_cdgo_rspsta  := 16;
      o_mnsje_rspsta := 'No se genero el acto, ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if; -- FIn valida creaci¿n del acto
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Novedad Aplicada Exitosamente';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'o_mnsje_rspsta ' || o_mnsje_rspsta,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rc_novedad_persona(p_cdgo_clnte     in number,
                                   p_id_nvdad_prsna in number,
                                   p_id_usrio       in number,
                                   p_obsrvcion      in varchar2,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
  
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para Rechazar las novedades de personas !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl               number;
    v_indcdor          varchar2(100);
    v_id_acto          gn_g_actos.id_acto%type;
    v_id_instncia_fljo number;
    v_id_mtvo          number;
    v_cdgo_rspsta      si_d_novedades_prsna_estdo.cdgo_rspsta%type;
    v_error            varchar2(1000);
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_novedades_persona.prc_rc_novedad_persona');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rc_novedad_persona',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rc_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rc_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    -- Se actualizan los datos de la novedad
    begin
      update si_g_novedades_persona
         set fcha_rchzo             = systimestamp,
             id_usrio_rchzo         = p_id_usrio,
             obsrvcion_rchzo        = p_obsrvcion,
             cdgo_nvdad_prsna_estdo = 'RCH'
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error al actualizar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rc_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Se actualizan los datos de la novedad
  
    begin
      pkg_si_novedades_persona.prc_gn_acto_novedades_persona(p_cdgo_clnte             => p_cdgo_clnte,
                                                             p_id_nvdad_prsna         => p_id_nvdad_prsna,
                                                             p_cdgo_cnsctvo           => 'NPR',
                                                             p_cdgo_nvdad_prsna_estdo => 'RCH',
                                                             p_id_usrio               => p_id_usrio,
                                                             o_id_acto                => v_id_acto,
                                                             o_cdgo_rspsta            => o_cdgo_rspsta,
                                                             o_mnsje_rspsta           => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al generar el acto de la novedad. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rc_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Se genera el acto de aplicaci¿n
  
    if o_cdgo_rspsta = 0 and v_id_acto > 0 then
      -- Adicionamos las propiedades a PQR
    
      if r_si_g_novedades_persona.id_slctud is not null then
        begin
          select a.id_instncia_fljo, c.id_mtvo, d.cdgo_rspsta
            into v_id_instncia_fljo, v_id_mtvo, v_cdgo_rspsta
            from si_g_novedades_persona a
            join pq_g_solicitudes_motivo c
              on a.id_slctud = c.id_slctud
            join si_d_novedades_prsna_estdo d
              on a.cdgo_nvdad_prsna_estdo = d.cdgo_nvdad_prsna_estdo
           where a.id_nvdad_prsna = p_id_nvdad_prsna;
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'MTV',
                                                      p_vlor             => v_id_mtvo);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'ACT',
                                                      p_vlor             => v_id_acto);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'USR',
                                                      p_vlor             => p_id_usrio);
        
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'RSP',
                                                      p_vlor             => v_cdgo_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'Error al cerrar propiedades PQR ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rc_novedad_persona',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
        end; -- Fin Adicionamos las propiedades a PQR
      end if;
    
      -- Se finaliza el flujo de la novedad
      begin
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => r_si_g_novedades_persona.id_instncia_fljo,
                                                       p_id_fljo_trea     => r_si_g_novedades_persona.id_fljo_trea,
                                                       p_id_usrio         => p_id_usrio,
                                                       o_error            => v_error,
                                                       o_msg              => o_mnsje_rspsta);
      
        if v_error = 'N' then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error al cerrar el flujo. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rc_novedad_persona',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := 'Error al cerrar el flujo' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rc_novedad_persona',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- Fin Se finaliza el flujo de la novedad
    
      --Consultamos los envios programados
      declare
        v_json_parametros clob;
      begin
        select json_object(key 'ID_NVDAD_PRSNA' is p_id_nvdad_prsna)
          into v_json_parametros
          from dual;
      
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'PKG_SI_NOVEDADES_PERSONA.PRC_RC_NOVEDAD_PERSONA',
                                              p_json_prmtros => v_json_parametros);
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error al cerrar el flujo' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rc_novedad_persona',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; --Fin Consultamos los envios programados
    else
      o_cdgo_rspsta  := 13;
      o_mnsje_rspsta := 'Error al generar el acto. ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rc_novedad_persona',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
      return;
    end if;
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Novedad Rechazada Exitosamente';
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rc_novedad_persona',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          6);
  end;

  procedure prc_ac_novedad_persona(p_cdgo_clnte        in number,
                                   p_id_nvdad_prsna    in number,
                                   p_id_instncia_fljo  in number,
                                   p_id_impsto         in number,
                                   p_id_impsto_sbmpsto in number,
                                   p_id_sjto_impsto    in number,
                                   p_cdgo_nvdad_tpo    in varchar2,
                                   p_obsrvcion         in varchar2,
                                   p_id_usrio          in number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para Actualizar las novedades de personas !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl      number;
    v_indcdor number;
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'prc_ac_novedad_persona.prc_ap_novedad_persona');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_ap_novedad_persona',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se actualizan los datos de la novedad
    begin
      update si_g_novedades_persona
         set id_impsto         = p_id_impsto,
             id_impsto_sbmpsto = p_id_impsto_sbmpsto,
             id_sjto_impsto    = p_id_sjto_impsto,
             cdgo_nvdad_tpo    = p_cdgo_nvdad_tpo,
             obsrvcion         = p_obsrvcion
       where id_nvdad_prsna = p_id_nvdad_prsna;
    
      -- Se eliminan los adjunto de las novedades
      delete from si_g_novedades_prsna_adjnto
       where id_nvdad_prsna = p_id_nvdad_prsna;
    
      -- Se agregan los nuevos adjunto a la novedad
      for c_adjntos in (select n001,
                               c002    filename,
                               c003    mime_type,
                               blob001 blob
                          from apex_collections a
                         where collection_name =
                               'ADJUNTOS_NOVEDADES_PERSONA'
                           and n001 = p_id_instncia_fljo) loop
      
        -- Se insertan los adjuntos de la novedad
        begin
          insert into si_g_novedades_prsna_adjnto
            (id_nvdad_prsna, file_blob, file_name, file_mimetype)
          values
            (p_id_nvdad_prsna,
             c_adjntos.blob,
             c_adjntos.filename,
             c_adjntos.mime_type);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al registrar la Novedad.' || sqlcode ||
                              ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end loop;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Novedad actualizada Exitosamente';
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al actualizar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'prc_ac_novedad_persona.prc_rg_novedad_persona',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualizan los datos de la novedad
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_ap_novedad_persona',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_rg_novedad_persona_sujeto(p_cdgo_clnte     in number,
                                          p_id_nvdad_prsna in number,
                                          p_id_usrio       in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar el historico de sujeto            !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl      number;
    v_indcdor number;
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
    v_id_sjto                si_c_sujetos.id_sjto%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'prc_ac_novedad_persona.prc_rg_novedad_persona_sujeto');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_novedad_persona_sujeto',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consultan los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    -- Se sonulta el id del sujeto asociado a la novedad
    begin
      select a.id_sjto
        into v_id_sjto
        from si_i_sujetos_impuesto a
       where a.id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se encontro el sujeto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error al consultar el sujeto. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se sonulta el id del sujeto asociado a la novedad
  
    -- Se registra el hostorico del sujeto
    begin
      insert into si_h_sujetos
        (id_sjto,
         cdgo_clnte,
         idntfccion,
         idntfccion_antrior,
         id_pais,
         id_dprtmnto,
         id_mncpio,
         drccion,
         fcha_ingrso,
         cdgo_pstal,
         estdo_blqdo,
         id_nvdad)
        select id_sjto,
               cdgo_clnte,
               idntfccion,
               idntfccion_antrior,
               id_pais,
               id_dprtmnto,
               id_mncpio,
               drccion,
               fcha_ingrso,
               cdgo_pstal,
               estdo_blqdo,
               p_id_nvdad_prsna
          from si_c_sujetos
         where id_sjto = v_id_sjto;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de Historico de Sujeto exitasamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al registrar el historico del sujeto. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Se registra el hostorico del sujeto
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_novedad_persona_sujeto',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rg_nvdad_prsna_sjto_impsto(p_cdgo_clnte     in number,
                                           p_id_nvdad_prsna in number,
                                           p_id_usrio       in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar el historico de sujeto impuestos  !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl      number;
    v_indcdor number;
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_impsto');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_impsto',
                          v_nl,
                          'Entrando ' || systimestamp,
                          6);
  
    -- Se consultan los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    -- Se registra el historico del sujeto impuesto
    begin
      insert into si_h_sujetos_impuesto
        (id_sjto_impsto,
         id_sjto,
         id_impsto,
         id_sjto_estdo,
         estdo_blqdo,
         id_pais_ntfccion,
         id_dprtmnto_ntfccion,
         id_mncpio_ntfccion,
         drccion_ntfccion,
         email,
         tlfno,
         fcha_rgstro,
         usrio_rgstro,
         id_nvdad)
        select id_sjto_impsto,
               id_sjto,
               id_impsto,
               id_sjto_estdo,
               estdo_blqdo,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               fcha_rgstro,
               id_usrio,
               p_id_nvdad_prsna
          from si_i_sujetos_impuesto
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de historico de sujeto impuesto exitasamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto',
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al registrar el historico del sujeto impuesto. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Se registra el historico del sujeto impuesto
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_impsto',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          6);
  end;

  procedure prc_rg_nvdad_prsna_sjto_prsna(p_cdgo_clnte     in number,
                                          p_id_nvdad_prsna in number,
                                          p_id_usrio       in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar el historico de sujeto persona    !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl      number;
    v_indcdor number;
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_prsna');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_prsna',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consultan los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    -- Se registra el historico del sujeto persona
    begin
      insert into si_h_personas
        (id_prsna,
         id_sjto_impsto,
         cdgo_idntfccion_tpo,
         id_sjto_tpo,
         tpo_prsna,
         nmbre_rzon_scial,
         nmro_rgstro_cmra_cmrcio,
         fcha_rgstro_cmra_cmrcio,
         fcha_incio_actvddes,
         nmro_scrsles,
         drccion_cmra_cmrcio,
         id_actvdad_ecnmca,
         id_nvdad_prsna)
        select id_prsna,
               id_sjto_impsto,
               cdgo_idntfccion_tpo,
               id_sjto_tpo,
               tpo_prsna,
               nmbre_rzon_scial,
               nmro_rgstro_cmra_cmrcio,
               fcha_rgstro_cmra_cmrcio,
               fcha_incio_actvddes,
               nmro_scrsles,
               drccion_cmra_cmrcio,
               id_actvdad_ecnmca,
               p_id_nvdad_prsna
          from si_i_personas
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de Historico de Sujeto Persona exitosamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna',
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al registrar el historico del sujeto persona. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se registra el historico del sujeto persona
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_prsna',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rg_nvdad_prsna_sjto_rspnsb(p_cdgo_clnte     in number,
                                           p_id_nvdad_prsna in number,
                                           p_id_usrio       in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2) as
    -- !! -------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar el historico de sujeto persona    !! --
    -- !! -------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl      number;
    v_indcdor number;
  
    r_si_g_novedades_persona si_g_novedades_persona%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_rspnsb');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ac_novedad_persona.prc_rg_nvdad_prsna_sjto_rspnsb',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consultan los datos de la novedad
    begin
      select *
        into r_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro la novedad';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar la novedad. ' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta los datos de la novedad
  
    begin
      insert into si_i_sujetos_rspnsble_hstrco
        (id_sjto_rspnsble_hstrco,
         id_sjto_impsto,
         cdgo_idntfccion_tpo,
         idntfccion,
         prmer_nmbre,
         sgndo_nmbre,
         prmer_aplldo,
         sgndo_aplldo,
         prncpal_s_n,
         cdgo_tpo_rspnsble,
         id_pais_ntfccion,
         id_dprtmnto_ntfccion,
         id_mncpio_ntfccion,
         drccion_ntfccion,
         email,
         tlfno,
         cllar,
         actvo,
         id_trcro,
         prcntje_prtcpcion,
         orgen_dcmnto,
         id_nvdad)
        select sq_si_i_sjetos_rspnsble_hstrco.nextval,
               id_sjto_impsto,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               cllar,
               actvo,
               id_trcro,
               prcntje_prtcpcion,
               orgen_dcmnto,
               p_id_nvdad_prsna
          from si_i_sujetos_responsable
         where id_sjto_impsto = r_si_g_novedades_persona.id_sjto_impsto;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de Historico de sujeto responsables exitasamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb',
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al registrar el historico del sujeto persona. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_rspnsb',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se registra el historico del sujeto resposable
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_nvdad_prsna_sjto_prsna',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_gn_acto_novedades_persona(p_cdgo_clnte             in number,
                                          p_id_nvdad_prsna         in number,
                                          p_cdgo_cnsctvo           in varchar2,
                                          p_cdgo_nvdad_prsna_estdo in varchar2,
                                          p_id_usrio               in number,
                                          o_id_acto                in out number,
                                          o_cdgo_rspsta            in out number,
                                          o_mnsje_rspsta           in out varchar2) as
  
    -- !! ---------------------------------------------------------- !! --
    -- !! -- Procedimiento para generar de las novedad de persona -- !! --
    -- !! ---------------------------------------------------------- !! --
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_si_novedades_persona.prc_gn_acto_novedades_persona';
    v_error    exception;
  
    t_si_g_novedades_persona si_g_novedades_persona%rowtype;
    v_slct_sjto_impsto       clob;
    v_slct_rspnsble          clob;
    v_id_acto_tpo            number;
    v_json_acto              clob;
    v_cdgo_acto_tpo          varchar2(3);
    v_dcmnto                 clob;
    v_id_plntlla             number;
  
    v_blob             blob;
    v_gn_d_reportes    gn_d_reportes%rowtype;
    v_app_page_id      number := v('APP_PAGE_ID');
    v_app_id           number := v('APP_ID');
    v_id_impsto        number;
    v_tpo_prsna        si_g_novedades_persona_sjto.tpo_prsna%type;
    v_cntdad_rspnsbles number := 0;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select *
        into t_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' No se encontro informaci¿n de la novedad';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' Error al consultar la informaci¿n de la novedad. ' ||
                          sqlerrm;
        raise v_error;
    end;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') or
       (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      -- Select para obtener el sub-tributo y sujeto impuesto
      v_slct_sjto_impsto := 'select id_impsto_sbmpsto,
                       id_sjto_impsto
                    from si_g_novedades_persona
                   where id_nvdad_prsna = ' ||
                            p_id_nvdad_prsna;
    
    else
      v_slct_sjto_impsto := null;
    end if;
  
    o_mnsje_rspsta := 'v_slct_sjto_impsto: ' || v_slct_sjto_impsto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Select para obtener los responsables de un acto
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') then
      begin
        select tpo_prsna
          into v_tpo_prsna
          from si_g_novedades_persona_sjto
         where id_nvdad_prsna = p_id_nvdad_prsna;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                            ' No se encontro informaci¿n de la novedad sujeto';
          raise v_error;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                            ' Error al consultar la informaci¿n de la novedad sujeto. ' ||
                            sqlerrm;
          raise v_error;
      end;
    
      if v_tpo_prsna = 'N' then
      
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novedades_persona_sjto a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                                 a.idntfccion,
                                                 a.prmer_nmbre,
                                                 a.sgndo_nmbre,
                                                 a.prmer_aplldo,
                                                 a.sgndo_aplldo,
                                                 a.drccion_ntfccion,
                                                 a.id_pais_ntfccion,
                                                 a.id_dprtmnto_ntfccion,
                                                 a.id_mncpio_ntfccion,
                                                 a.email,
                                                 a.tlfno
                                            from si_g_novedades_persona_sjto a
                                           where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      else
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novddes_prsna_rspnsble a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                             a.idntfccion,
                                             a.prmer_nmbre,
                                             a.sgndo_nmbre,
                                             a.prmer_aplldo,
                                             a.sgndo_aplldo,
                                             a.drccion_ntfccion,
                                             a.id_pais_ntfccion,
                                             a.id_dprtmnto_ntfccion,
                                             a.id_mncpio_ntfccion,
                                             a.email,
                                             a.tlfno
                                        from si_g_novddes_prsna_rspnsble a
                                       where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      end if;
    else
      v_slct_rspnsble := null;
    end if;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      begin
        select count(1)
          into v_cntdad_rspnsbles
          from si_i_sujetos_responsable a
          join si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = t_si_g_novedades_persona.id_sjto_impsto;
      end;
    
      if v_cntdad_rspnsbles > 0 then
        v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                       a.idntfccion,
                       a.prmer_nmbre,
                       a.sgndo_nmbre,
                       a.prmer_aplldo,
                       a.sgndo_aplldo,
                       nvl(a.drccion_ntfccion, b.drccion_ntfccion) drccion_ntfccion,
                       a.id_pais_ntfccion,
                       a.id_dprtmnto_ntfccion,
                       a.id_mncpio_ntfccion,
                       a.email,
                       a.tlfno
                    from si_i_sujetos_responsable   a
                    join si_i_sujetos_impuesto    b on a.id_sjto_impsto = b.id_sjto_impsto
                     where a.id_sjto_impsto = ' ||
                           t_si_g_novedades_persona.id_sjto_impsto;
      
      end if;
    end if;
  
    o_mnsje_rspsta := 'v_slct_rspnsble : ' || v_slct_rspnsble;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Consulta el id del tipo del acto
    if p_cdgo_nvdad_prsna_estdo = 'APL' then
      v_cdgo_acto_tpo := 'NVA';
    elsif p_cdgo_nvdad_prsna_estdo = 'RCH' then
      v_cdgo_acto_tpo := 'NVR';
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                        ' No se puede determinar el tipo de acto';
      raise v_error;
    end if;
  
    o_mnsje_rspsta := 'v_cdgo_acto_tpo ' || v_cdgo_acto_tpo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = v_cdgo_acto_tpo;
    
      o_mnsje_rspsta := 'v_id_acto_tpo ' || v_id_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' Error al encontrar el tipo de acto: ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin 3 Consulta el id del tipo del acto
  
    -- Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'NPR',
                                                           p_id_orgen            => p_id_nvdad_prsna,
                                                           p_id_undad_prdctra    => p_id_nvdad_prsna,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => 'NPS',
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
      --  o_mnsje_rspsta := ' Json Acto: ' || v_json_acto;
      --  insert into gti_aux (col1, col2) values ('Plantilla del acto de novedades', o_mnsje_rspsta);
    
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' Error al Generar el json para el acto. Error: ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Generacion del json para el Acto
  
    -- Generacion del Acto
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'o_cdgo_rspsta: ' || o_cdgo_rspsta,
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'o_mnsje_rspsta: ' || o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta || o_mnsje_rspsta ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Generacion del Acto
  
    if o_cdgo_rspsta = 0 and o_id_acto > 0 then
      -- Se actualizael id del acto en la novedad
      begin
        update si_g_novedades_persona
           set id_acto = o_id_acto
         where cdgo_clnte = p_cdgo_clnte
           and id_nvdad_prsna = p_id_nvdad_prsna;
      
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := ' Actualizo si_g_novedades_persona  ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                            ' Error al actualizar el id_acto en novedades persona:' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Actualizacion del id del acto en la tabla novedades persona
    
      -- Se genera el html de la plantilla
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            ' v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
      begin
        select a.id_plntlla
          into v_id_plntlla
          from gn_d_plantillas a
         where id_acto_tpo = v_id_acto_tpo;
      
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_nvdad_prsna":"' ||
                                                       p_id_nvdad_prsna || '"}',
                                                       v_id_plntlla);
      
        insert into gti_aux
          (col1, col2)
        values
          ('Plantilla del acto de novedades', v_dcmnto);
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                            ' Error al consultar la plantilla. ' || sqlerrm;
          raise v_error;
      end; -- Fin Se genera el html de la plantilla
    
      if v_dcmnto is not null then
        -- Actualizacion del acto en la tabla novedades persona
        begin
          update si_g_novedades_persona
             set dcmnto_html = v_dcmnto
           where cdgo_clnte = p_cdgo_clnte
             and id_nvdad_prsna = p_id_nvdad_prsna;
        
          o_mnsje_rspsta := ' Actualizo si_g_novedades_persona  ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                              ' Error al actualizar el acto en novedades persona. Error:' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Actualizacion del acto en la tabla novedades persona
      
        -- Generacion del Reporte
        -- Consultamos los datos del reporte
        begin
          select b.*
            into v_gn_d_reportes
            from gn_d_plantillas a
            join gn_d_reportes b
              on a.id_rprte = b.id_rprte
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_plntlla = v_id_plntlla;
        
          o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
                            v_gn_d_reportes.nmbre_plntlla || ', ' ||
                            v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
                            v_gn_d_reportes.cdgo_frmto_tpo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                              ' Problemas al consultar reporte id_rprte: ' ||
                              v_gn_d_reportes.id_rprte;
            raise v_error;
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                              ' Problemas al consultar reporte, ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            raise v_error;
        end; -- Fin Consultamos los datos del reporte
      
        --Si existe la Sesion
        apex_session.attach(p_app_id     => 66000,
                            p_page_id    => 37,
                            p_session_id => v('APP_SESSION'));
      
        apex_util.set_session_state('P37_JSON',
                                    '{"id_nvdad_prsna":"' ||
                                    p_id_nvdad_prsna || '"}');
        apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
        apex_util.set_session_state('P37_ID_RPRTE',
                                    v_gn_d_reportes.id_rprte);
      
        begin
          v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                                 p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                                 p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                                 p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                                 p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
        exception
          when others then
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta || ' Error: ' ||
                              sqlerrm;
            raise v_error;
        end;
      
        if v_blob is not null then
          -- Generaci¿n blob
          begin
            pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                             p_id_acto         => o_id_acto,
                                             p_ntfccion_atmtca => 'N');
          exception
            when others then
              o_cdgo_rspsta  := 15;
              o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                                'Problemas al actualizar acto ' || sqlerrm;
              raise v_error;
          end;
        else
          o_cdgo_rspsta  := 16;
          o_mnsje_rspsta := 'Problemas al generar blob, ' || sqlerrm;
          raise v_error;
        end if;
      
        -- Bifurcacion
        apex_session.attach(p_app_id     => v_app_id,
                            p_page_id    => v_app_page_id,
                            p_session_id => v('APP_SESSION'));
      else
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta || o_mnsje_rspsta ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
    else
      o_cdgo_rspsta  := 18;
      o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                        ' No se genero el acto: ' || o_mnsje_rspsta ||
                        sqlerrm;
      raise v_error;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when v_error then
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
                            'Saliendo ' || systimestamp,
                            1);
      rollback;
      return;
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta || 'Error: ' || sqlerrm;
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
                            'Saliendo ' || systimestamp,
                            1);
      rollback;
      return;
  end;

  -- !! -- Procedimiento para registrar un sujeto impuesto a partir de un sujeto ya registrado -- !! --
  procedure prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte        in number,
                                           p_id_sjto           in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number default null,
                                           p_id_usrio          in number default null,
                                           o_id_sjto_impsto    out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
  
    v_nl                    number;
    v_nmbre_up              varchar2(70) := 'pkg_si_novedades_persona.prc_rg_sjto_impsto_sjto_exstnt';
    t_si_c_sujetos          si_c_sujetos%rowtype;
    t_si_i_suejtos_impuesto si_i_sujetos_impuesto%rowtype;
    t_si_i_personas         si_i_personas%rowtype;
    v_id_sjto_impsto        si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_sjto_impsto_nvo    si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_usrio_sstma        sg_g_usuarios.id_usrio%type;
    v_user_name             sg_g_usuarios.user_name%type;
    v_id_nvdad_prsna        number;
    v_obsrvcion             varchar2(100) := 'Novedad de Inscripci¿n. Sujeto Impuesto a partir de una ya existente';
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
    if p_id_usrio is null then
      -- Se consulta el id del usuario de sistema
      begin
        v_user_name := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                       p_cdgo_dfncion_clnte        => 'USR');
        select id_usrio
          into v_id_usrio_sstma
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = v_user_name;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'o_cdgo_rspsta ' || o_cdgo_rspsta || ' Error: ' ||
                            o_mnsje_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end; -- Fin consulta el id del usuario de sistema
    else
      v_id_usrio_sstma := p_id_usrio;
    end if; -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
  
    -- Se valida que el sujeto existe
    begin
      select *
        into t_si_c_sujetos
        from si_c_sujetos
       where cdgo_clnte = p_cdgo_clnte
         and id_sjto = p_id_sjto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                          ' Error al consultar el sujeto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se valida que el sujeto existe
  
    -- Se valida si el sujeto existe para el impuesto
    begin
      select id_sjto_impsto
        into o_id_sjto_impsto
        from si_i_sujetos_impuesto
       where id_sjto = p_id_sjto
         and id_impsto = p_id_impsto;
    
      -- Se existe se retorna el sujeto impuesto existente
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Cod. Respuesta: ' || o_cdgo_rspsta || ' - ' ||
                        ' El sujeto impuesto ya existe';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      return;
    
    exception
      when no_data_found then
        -- Se consulta el ultimo sujeto impuesto registrado para el sujeto
        begin
          select max(id_sjto_impsto)
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto
           where id_sjto = p_id_sjto;
        
          -- Se consulta la informaci¿n del sujeto impuesto para crear el nuevo sujeto
          begin
            select *
              into t_si_i_suejtos_impuesto
              from si_i_sujetos_impuesto
             where id_sjto_impsto = v_id_sjto_impsto;
          
            select *
              into t_si_i_personas
              from si_i_personas
             where id_sjto_impsto = v_id_sjto_impsto;
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                                ' Error al consultar el sujeto impuesto';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              return;
          end;
        
          -- Se registra una novedad e inscripci¿n
          begin
            insert into si_g_novedades_persona
              (cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               obsrvcion,
               fcha_rgstro,
               id_usrio_rgstro,
               cdgo_nvdad_tpo,
               cdgo_nvdad_prsna_estdo)
            values
              (p_cdgo_clnte,
               p_id_impsto,
               p_id_impsto_sbmpsto,
               NVL(v_obsrvcion, 'SIN OBSERVACIÓN.'),
               systimestamp,
               v_id_usrio_sstma,
               'INS',
               'APL')
            returning id_nvdad_prsna into v_id_nvdad_prsna;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                                ' Error al registrar la novedad. ' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              return;
          end; -- FIN Se registra una novedad e inscripci¿n
        
          -- Se registrar el sujeto impuesto
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
               fcha_rgstro,
               id_usrio,
               id_sjto_estdo,
               fcha_ultma_nvdad)
            values
              (p_id_sjto,
               p_id_impsto,
               'N',
               t_si_i_suejtos_impuesto.id_pais_ntfccion,
               t_si_i_suejtos_impuesto.id_dprtmnto_ntfccion,
               t_si_i_suejtos_impuesto.id_mncpio_ntfccion,
               t_si_i_suejtos_impuesto.drccion_ntfccion,
               t_si_i_suejtos_impuesto.email,
               t_si_i_suejtos_impuesto.tlfno,
               systimestamp,
               v_id_usrio_sstma,
               1,
               systimestamp)
            returning id_sjto_impsto into v_id_sjto_impsto_nvo;
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al cinsertat la informaci¿n del sujeto impuesto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se registrar el sujeto impuesto
        
          -- Se registran los datos de la persona
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
               id_actvdad_ecnmca,
               id_sjto_tpo)
            values
              (v_id_sjto_impsto_nvo,
               t_si_i_personas.cdgo_idntfccion_tpo,
               t_si_i_personas.tpo_prsna,
               t_si_i_personas.nmbre_rzon_scial,
               t_si_i_personas.nmro_rgstro_cmra_cmrcio,
               t_si_i_personas.fcha_rgstro_cmra_cmrcio,
               t_si_i_personas.fcha_incio_actvddes,
               t_si_i_personas.nmro_scrsles,
               t_si_i_personas.drccion_cmra_cmrcio,
               t_si_i_personas.id_actvdad_ecnmca,
               t_si_i_personas.id_sjto_tpo);
          exception
            when others then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'Error al cinsertat la informaci¿n de persona. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se registran los datos de la persona
        
          -- Consulta de responsables
          for c_rspnsbles in (select *
                                from si_i_sujetos_responsable
                               where id_sjto_impsto = v_id_sjto_impsto) loop
            -- Se registra el responsable
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
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion,
                 tlfno,
                 cllar,
                 id_trcro,
                 orgen_dcmnto)
              values
                (v_id_sjto_impsto_nvo,
                 c_rspnsbles.cdgo_idntfccion_tpo,
                 c_rspnsbles.idntfccion,
                 c_rspnsbles.prmer_nmbre,
                 c_rspnsbles.sgndo_nmbre,
                 c_rspnsbles.prmer_aplldo,
                 c_rspnsbles.sgndo_aplldo,
                 c_rspnsbles.prncpal_s_n,
                 c_rspnsbles.cdgo_tpo_rspnsble,
                 c_rspnsbles.id_pais_ntfccion,
                 c_rspnsbles.id_dprtmnto_ntfccion,
                 c_rspnsbles.id_mncpio_ntfccion,
                 c_rspnsbles.drccion_ntfccion,
                 c_rspnsbles.tlfno,
                 c_rspnsbles.cllar,
                 c_rspnsbles.id_trcro,
                 nvl(c_rspnsbles.orgen_dcmnto, 1));
            exception
              when others then
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := 'Error al insertar el responsable ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- FIN Se registra el responsable
          end loop; -- FIN Consulta de responsables
          o_mnsje_rspsta := 'id_jto_impsto: ' || v_id_sjto_impsto_nvo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          o_id_sjto_impsto := v_id_sjto_impsto_nvo;
          o_cdgo_rspsta    := 0;
          o_mnsje_rspsta   := 'Registro de Sujeto impuesto exitoso ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                              ' Error al consultar el sujeto impuesto';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end; --  Fin Se consulta el ultimo sujeto impuesto registrado para el sujeto
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                          ' Error al consultar el sujeto impuesto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin  Se valida si el sujeto existe para el impuesto
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rg_sjto_impsto(p_cdgo_clnte      in number,
                               p_ssion           in number,
                               p_id_impsto       in number,
                               p_id_usrio_rgstro in number,
                               -- Datos de Inscripcion --
                               p_tpo_prsna           in varchar2,
                               p_cdgo_idntfccion_tpo in varchar2,
                               p_idntfccion          in number,
                               p_prmer_nmbre         in varchar2,
                               p_sgndo_nmbre         in varchar2,
                               p_prmer_aplldo        in varchar2,
                               p_sgndo_aplldo        in varchar2,
                               p_nmbre_rzon_scial    in varchar2,
                               p_drccion             in varchar2,
                               p_id_pais             in number,
                               p_id_dprtmnto         in number,
                               p_id_mncpio           in number,
                               p_email               in varchar2,
                               p_tlfno               in varchar2,
                               p_cllar               in varchar2,
                               p_id_sjto_tpo         in number,
                               -- Fin Datos de Inscripcion --
                               o_id_sjto_impsto out number,
                               o_id_nvdad_prsna out number,
                               o_cdgo_rspsta    out number,
                               o_mnsje_rspsta   out varchar2) as
  
    v_nl number;
  
    v_id_usrio_sstma sg_g_usuarios.id_usrio%type;
    v_user_name      sg_g_usuarios.user_name%type;
    v_id_nvdad_prsna number;
    v_obsrvcion      varchar2(100) := 'Novedad de Inscripci¿n. Sujeto Impuesto desde el portal  - Rentas';
    v_id_sjto        number;
    v_id_sjto_impsto number;
    v_id_prsna       number;
    v_id_trcro       number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_novedades_persona.prc_rg_sjto_impsto');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
    if p_id_usrio_rgstro is null then
      -- Se consulta el id del usuario de sistema
      begin
        v_user_name := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                       p_cdgo_dfncion_clnte        => 'USR');
        select id_usrio
          into v_id_usrio_sstma
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = v_user_name;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'o_cdgo_rspsta ' || o_cdgo_rspsta || ' Error: ' ||
                            o_mnsje_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end; -- Fin consulta el id del usuario de sistema
    else
      v_id_usrio_sstma := p_id_usrio_rgstro;
    end if; -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
  
    -- Se consulta si el sujeto ya existe
    begin
      select id_sjto
        into v_id_sjto
        from si_c_sujetos
       where cdgo_clnte = p_cdgo_clnte
         and idntfccion = to_char(p_idntfccion);
    exception
      when others then
        null;
    end; -- Fin Se valida que el sujeto existe
  
    if v_id_sjto is not null then
      -- Se valida si el sujeto existe para el impuesto
      begin
        select id_sjto_impsto
          into o_id_sjto_impsto
          from si_i_sujetos_impuesto
         where id_sjto = v_id_sjto
           and id_impsto = p_id_impsto;
      
        -- Se existe se retorna el sujeto impuesto existente
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Cod. Respuesta: ' || o_cdgo_rspsta || ' - ' ||
                          ' El sujeto impuesto ya existe';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_sjto_impsto_sjto_exstnt',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      exception
        when no_data_found then
          prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte     => p_cdgo_clnte,
                                         p_id_sjto        => v_id_sjto,
                                         p_id_impsto      => p_id_impsto,
                                         p_id_usrio       => v_id_usrio_sstma,
                                         o_id_sjto_impsto => o_id_sjto_impsto,
                                         o_cdgo_rspsta    => o_cdgo_rspsta,
                                         o_mnsje_rspsta   => o_mnsje_rspsta);
          if o_cdgo_rspsta = 0 then
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Se creo el sujeto impuesto exitosamente';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_sjto_impsto_sjto_exstnt',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
          end if;
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                            ' Error al consultar el sujeto impuesto. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'prc_ac_novedad_persona.prc_rg_sjto_impsto',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    end if;
    -- Se registra una novedad e inscripci¿n
    begin
      insert into si_g_novedades_persona
        (cdgo_clnte,
         id_impsto,
         obsrvcion,
         fcha_rgstro,
         id_usrio_rgstro,
         cdgo_nvdad_tpo,
         cdgo_nvdad_prsna_estdo)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         NVL(v_obsrvcion, 'SIN OBSERVACIÓN.'),
         systimestamp,
         v_id_usrio_sstma,
         'INS',
         'APL')
      returning id_nvdad_prsna into v_id_nvdad_prsna;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                          ' Error al registrar la novedad. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'prc_ac_novedad_persona.prc_rg_sjto_impsto',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- FIN Se registra una novedad e inscripci¿n
  
    -- Se registrar el sujeto
    begin
      insert into si_c_sujetos
        (cdgo_clnte,
         idntfccion,
         idntfccion_antrior,
         id_pais,
         id_dprtmnto,
         id_mncpio,
         drccion,
         fcha_ingrso,
         estdo_blqdo)
      values
        (p_cdgo_clnte,
         p_idntfccion,
         p_idntfccion,
         p_id_pais,
         p_id_dprtmnto,
         p_id_mncpio,
         p_drccion,
         sysdate,
         'N')
      returning id_sjto into v_id_sjto;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al cinsertat la informaci¿n del sujeto. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- FIN Se registrar el sujeto
  
    -- Se registrar el sujeto impuesto
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
         fcha_rgstro,
         id_usrio,
         id_sjto_estdo,
         fcha_ultma_nvdad)
      values
        (v_id_sjto,
         p_id_impsto,
         'N',
         p_id_pais,
         p_id_dprtmnto,
         p_id_mncpio,
         p_drccion,
         p_email,
         p_tlfno,
         systimestamp,
         v_id_usrio_sstma,
         1,
         systimestamp)
      returning id_sjto_impsto into v_id_sjto_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error al insertar la informaci¿n del sujeto impuesto. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- FIN Se registrar el sujeto impuesto
  
    -- Se registran los datos de la persona
    begin
      insert into si_i_personas
        (id_sjto_impsto,
         cdgo_idntfccion_tpo,
         tpo_prsna,
         nmbre_rzon_scial,
         id_sjto_tpo)
      values
        (v_id_sjto_impsto,
         p_cdgo_idntfccion_tpo,
         p_tpo_prsna,
         p_nmbre_rzon_scial,
         p_id_sjto_tpo)
      returning id_prsna into v_id_prsna;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al insertar la informaci¿n de persona. ' ||
                          sqlcode || ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- FIN Se registran los datos de la persona
  
    -- Se registran los responsables
    -- Si el tipo de persona es natural, se guarda como responsable principal
    if p_tpo_prsna = 'N' then
      o_mnsje_rspsta := 'p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' - p_idntfccion: ' || p_idntfccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                            v_nl,
                            'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta,
                            1);
      begin
        select id_trcro
          into v_id_trcro
          from si_c_terceros
         where cdgo_clnte = p_cdgo_clnte
           and idntfccion = to_char(p_idntfccion)
           and cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo;
      exception
        when no_data_found then
          -- Se inserta el tercero
          begin
            insert into si_c_terceros
              (cdgo_clnte,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               drccion,
               id_pais,
               id_dprtmnto,
               id_mncpio,
               drccion_ntfccion,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               email,
               tlfno,
               cllar,
               indcdor_cntrbynte,
               indcdr_fncnrio)
            values
              (p_cdgo_clnte,
               p_cdgo_idntfccion_tpo,
               p_idntfccion,
               p_prmer_nmbre,
               p_sgndo_nmbre,
               p_prmer_aplldo,
               p_sgndo_aplldo,
               p_drccion,
               p_id_pais,
               p_id_dprtmnto,
               p_id_mncpio,
               p_drccion,
               p_id_pais,
               p_id_dprtmnto,
               p_id_mncpio,
               p_email,
               p_tlfno,
               p_cllar,
               'N',
               'N')
            returning id_trcro into v_id_trcro;
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al insertar el tercero ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se inserta el tercero
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al consultar el id del tercero' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    
      -- Se registra el responsable
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
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           drccion_ntfccion,
           tlfno,
           cllar,
           id_trcro,
           orgen_dcmnto)
        values
          (v_id_sjto_impsto,
           p_cdgo_idntfccion_tpo,
           p_idntfccion,
           p_prmer_nmbre,
           p_sgndo_nmbre,
           p_prmer_aplldo,
           p_sgndo_aplldo,
           'S',
           'P',
           p_id_pais,
           p_id_dprtmnto,
           p_id_mncpio,
           p_drccion,
           p_tlfno,
           p_cllar,
           v_id_trcro,
           1);
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'Error al insertar el responsable ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- FIN Se registra el responsable
    else
      -- Consulta de resposables
      for c_rspnsbles in (select *
                            from apex_collections a
                           where collection_name = 'RESPONSABLES'
                             and c022 in ('NUEVO', 'ACTUALIZADO') ) loop
        -- Se consulta el tercero
        begin
          select id_trcro
            into v_id_trcro
            from si_c_terceros
           where cdgo_clnte = p_cdgo_clnte
             and idntfccion = to_char(c_rspnsbles.c004)
             and cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo;
        exception
          when no_data_found then
            -- Se registra el tercero
            begin
              insert into si_c_terceros
                (cdgo_clnte,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 prmer_nmbre,
                 sgndo_nmbre,
                 prmer_aplldo,
                 sgndo_aplldo,
                 drccion,
                 id_pais,
                 id_dprtmnto,
                 id_mncpio,
                 drccion_ntfccion,
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 email,
                 tlfno,
                 cllar,
                 indcdor_cntrbynte,
                 indcdr_fncnrio)
              values
                (p_cdgo_clnte,
                 c_rspnsbles.c003,
                 c_rspnsbles.c004,
                 c_rspnsbles.c005,
                 c_rspnsbles.c006,
                 c_rspnsbles.c007,
                 c_rspnsbles.c008,
                 c_rspnsbles.c016,
                 c_rspnsbles.c013,
                 c_rspnsbles.c014,
                 c_rspnsbles.c015,
                 c_rspnsbles.c016,
                 c_rspnsbles.c013,
                 c_rspnsbles.c014,
                 c_rspnsbles.c015,
                 c_rspnsbles.c017,
                 c_rspnsbles.c018,
                 c_rspnsbles.c019,
                 'S',
                 'N')
              returning id_trcro into v_id_trcro;
            exception
              when others then
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := 'Error al insertat el tercero ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                      v_nl,
                                      'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- Fin Se registra el tercero
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Error al consultar el tercero' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- FIN Se consulta el tercero
      
        -- Se registra el responsable
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
             orgen_dcmnto,
             id_pais_ntfccion,
             id_dprtmnto_ntfccion,
             id_mncpio_ntfccion,
             drccion_ntfccion,
             tlfno,
             cllar,
             id_trcro)
          values
            (v_id_sjto_impsto,
             c_rspnsbles.c003,
             c_rspnsbles.c004,
             c_rspnsbles.c005,
             c_rspnsbles.c006,
             c_rspnsbles.c007,
             c_rspnsbles.c008,
             c_rspnsbles.c009,
             c_rspnsbles.c010,
             c_rspnsbles.c011,
             1,
             c_rspnsbles.c013,
             c_rspnsbles.c014,
             c_rspnsbles.c015,
             c_rspnsbles.c016,
             c_rspnsbles.c018,
             c_rspnsbles.c019,
             v_id_trcro);
          apex_collection.delete_member(p_collection_name => 'RESPONSABLES',
                                        p_seq             => c_rspnsbles.seq_id);
        exception
          when others then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'Error al insertar el responsable' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- FIN Se registra el responsable
      end loop; -- Fin consulta de resposables
    end if; -- Fin Se registran los responsables
  
    -- Se registran las sucursales
    for c_sucursales in (select *
                           from apex_collections a
                          where collection_name = 'SUCURSALES') loop
      begin
      
        insert into si_i_sujetos_sucursal
          (id_sjto_impsto,
           id_sjto,
           cdgo_scrsal,
           nmbre,
           drccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           tlfno,
           cllar,
           email,
           actvo)
        values
          (v_id_sjto_impsto,
           v_id_sjto,
           c_sucursales.c004,
           c_sucursales.c002,
           c_sucursales.c007,
           c_sucursales.c005,
           c_sucursales.c006,
           c_sucursales.c009,
           c_sucursales.c010,
           c_sucursales.c008,
           c_sucursales.c011);
      
        apex_collection.delete_member(p_collection_name => 'SUCURSALES',
                                      p_seq             => c_sucursales.seq_id);
      
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error al insertar la informaci¿n de las sucursales. ' ||
                            sqlcode || ' -- ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    end loop; -- FIN Registro de las sucursales
  
    o_id_sjto_impsto := v_id_sjto_impsto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_novedades_persona.prc_rg_sjto_impsto',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_rg_novedad_persona_rechazo(p_cdgo_clnte        in number,
                                           p_ssion             in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_sjto_impsto    in number default null,
                                           p_id_instncia_fljo  in number,
                                           p_cdgo_nvdad_tpo    in varchar2,
                                           p_id_usrio_rgstro   in number,
                                           p_obsrvcion         in varchar2,
                                           o_id_nvdad_prsna    out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
  
    -- !! ------------------------------------------------------------------------- !! --
    -- !! Procedimiento para registrar las novedades de personas y luego rechazarla !! --
    -- !! ------------------------------------------------------------------------- !! --
  
    -- Variables de Log
    v_nl                    number;
    v_nmbre_up              varchar2(70) := 'pkg_si_novedades_persona.prc_rg_novedad_persona_rechazo';
    v_id_slctud             number;
    v_id_instncia_fljo_pdre number;
    v_type_rspsta           varchar2(1);
    v_error                 varchar2(1000);
    v_id_mtvo               number;
  
    v_cdgo_rspsta si_d_novedades_prsna_estdo.cdgo_rspsta%type;
  
    v_id_instncia_fljo   number;
    v_id_fljo_trea       number;
    v_id_fljo_trea_orgen number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_novedades_persona.prc_rg_novedad_persona_rechazo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          6);
  
    o_cdgo_rspsta := 0;
    -- Se valida si la novedad fue registrada por un pqr
    begin
      select a.id_slctud, a.id_instncia_fljo
        into v_id_slctud, v_id_instncia_fljo_pdre
        from v_pq_g_solicitudes a
       where a.id_instncia_fljo_gnrdo = p_id_instncia_fljo;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro informaci¿n de la solicitud PQR ' ||
                          sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end;
  
    -- Registro de la novedad
    begin
      insert into si_g_novedades_persona
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         obsrvcion,
         id_instncia_fljo,
         fcha_rgstro,
         id_usrio_rgstro,
         cdgo_nvdad_tpo,
         cdgo_nvdad_prsna_estdo,
         id_instncia_fljo_pdre,
         id_slctud,
         fcha_rchzo,
         id_usrio_rchzo,
         obsrvcion_rchzo)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         p_obsrvcion,
         p_id_instncia_fljo,
         systimestamp,
         p_id_usrio_rgstro,
         p_cdgo_nvdad_tpo,
         'RCH',
         v_id_instncia_fljo_pdre,
         v_id_slctud,
         systimestamp,
         p_id_usrio_rgstro,
         p_obsrvcion)
      returning id_nvdad_prsna into o_id_nvdad_prsna;
    
      o_mnsje_rspsta := 'Inserto en si_g_novedades_persona';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al registrar la Novedad.' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end;
  
    -- Se consulta la informaci¿n del flujo para hacer la transicion a la siguiente tarea.
    begin
      select a.id_fljo_trea_orgen
        into v_id_fljo_trea_orgen
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1, 2);
    
      -- Se actualiza la tarea en la novedad
      begin
        update si_g_novedades_persona
           set id_fljo_trea = v_id_fljo_trea_orgen
         where id_nvdad_prsna = o_id_nvdad_prsna;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al actualizar la tarea en novedades persona ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
      o_mnsje_rspsta := ' v_id_fljo_trea_orgen ' || v_id_fljo_trea_orgen;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                          ' -- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- FIN Se consulta la informaci¿n del flujo para hacer la transicion a la siguiente tarea.
  
    -- Adicionamos las propiedades a PQR
    if v_id_slctud is not null then
    
      -- Se actualiza la observacion de rechazo en la PQR
      begin
        update pq_g_solicitudes
           set obsrvcion_rspsta = obsrvcion_rspsta || ' ' || p_obsrvcion
         where id_slctud = v_id_slctud;
      
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := ' Error al actualizar la observaci¿n de respuesta en la solicitud ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- Fin Adicionamos las propiedades a PQR
    
      begin
        select a.id_instncia_fljo, c.id_mtvo, d.cdgo_rspsta
          into v_id_instncia_fljo, v_id_mtvo, v_cdgo_rspsta
          from si_g_novedades_persona a
          join pq_g_solicitudes_motivo c
            on a.id_slctud = c.id_slctud
          join si_d_novedades_prsna_estdo d
            on a.cdgo_nvdad_prsna_estdo = d.cdgo_nvdad_prsna_estdo
         where a.id_nvdad_prsna = o_id_nvdad_prsna;
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'MTV',
                                                    p_vlor             => v_id_mtvo);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'USR',
                                                    p_vlor             => p_id_usrio_rgstro);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'RSP',
                                                    p_vlor             => v_cdgo_rspsta);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'OBS',
                                                    p_vlor             => p_obsrvcion);
      
        o_mnsje_rspsta := 'Cerro las propiedades PQR ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al cerrar propiedades PQR ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- Fin Adicionamos las propiedades a PQR
    end if;
  
    -- Se finaliza el flujo de la novedad
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo,
                                                     p_id_fljo_trea     => v_id_fljo_trea_orgen, --v_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio_rgstro,
                                                     o_error            => v_error,
                                                     o_msg              => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_error = 'N' then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Error al cerrar el flujo. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'Error al cerrar el flujo' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Se finaliza el flujo de la novedad
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          6);
  end;

end;

/
