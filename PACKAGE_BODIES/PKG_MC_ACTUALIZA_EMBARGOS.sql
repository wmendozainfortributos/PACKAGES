--------------------------------------------------------
--  DDL for Package Body PKG_MC_ACTUALIZA_EMBARGOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MC_ACTUALIZA_EMBARGOS" as

procedure prc_mc_vlda_embrgos (
    p_nmro_lte    in mc_g_actualizar_cnddtos.clmuna16%type,
    o_mnsje_rspsta out varchar2
)
as
    cursor c_act_sjto (p_nmro_lte mc_g_actualizar_cnddtos.clmuna16%type) is
        select 
            clumna1  as identificacion_sujeto,
            clumna2  as tipo,
            clumna3  as identificacion,
            clumna4  as tipo_responsable,
            clumna5  as primer_nombre,
            clumna6  as segundo_nombre,
            clumna7  as primer_apellido,
            clumna8  as segundo_apellido,
            clumna9  as pais,
            clumna10 as dpto,
            clumna11 as municipio,
            clumna12 as direccion,
            clumna13 as telefono,
            clumna14 as celular,
            clumna15 as email,
            clmuna16 as idlote
        from mc_g_actualizar_cnddtos
        where clmuna16 = p_nmro_lte
        and indcdor_prcsdo <> 'E';

    cursor c_duplicados (p_nmro_lte in mc_g_actualizar_cnddtos.clmuna16%type) is  
        select count(*) conteo,
               clumna3 identificador
        from mc_g_actualizar_cnddtos
        where clmuna16 = p_nmro_lte
        group by clumna3
        having count(*) > 1;

    v_counter number         := 0; -- contador para los commits
    v_commit_interval number := 100; -- intervalo de commit
    
begin
    -- manejo de duplicados
    for reg in c_duplicados(p_nmro_lte) loop
        update mc_g_actualizar_cnddtos
        set indcdor_prcsdo = 'E'
        where clumna3 = reg.identificador;
    end loop;

    -- procesamiento de registros
    for reg in c_act_sjto(p_nmro_lte) loop
        begin
            update mc_g_embargos_simu_rspnsble 
            set
                cdgo_idntfccion_tpo  = reg.tipo,
                prmer_nmbre         = reg.primer_nombre,
                sgndo_nmbre         = reg.segundo_nombre,
                prmer_aplldo        = reg.primer_apellido,
                sgndo_aplldo        = reg.segundo_apellido,
                id_pais_ntfccion    = to_number(reg.pais),
                id_dprtmnto_ntfccion = to_number(reg.dpto),
                id_mncpio_ntfccion  = to_number(reg.municipio),
                drccion_ntfccion    = reg.direccion,
                email               = reg.email,
                tlfno               = reg.telefono,
                cllar               = reg.celular,
                prncpal_s_n         = reg.tipo_responsable,
                cdgo_tpo_rspnsble   = reg.tipo_responsable
            where 
                idntfccion = reg.identificacion;
            
            -- incrementa el contador y hace commit si se alcanza el intervalo
            v_counter := v_counter + 1;
            if v_counter >= v_commit_interval then
                commit;
                v_counter := 0; -- reiniciar el contador
            end if;

            -- verificar si el registro fue actualizado
            if sql%rowcount = 0 then
                dbms_output.put_line('no se encontró registro para actualizar con identificacion: ' || reg.identificacion);
            else
                dbms_output.put_line('registro actualizado para identificacion: ' || reg.identificacion);
            end if;

        exception
            when others then
                -- manejo de errores
                dbms_output.put_line('error al actualizar identificacion: ' || reg.identificacion || ' - ' || sqlerrm);
        end;
    end loop;

    -- hacer commit al finalizar el proceso si no se hizo antes
    if v_counter > 0 then
        commit;
    end if;
    
    commit;

exception
    when others then
        -- manejo de errores generales
        dbms_output.put_line('error general: ' || sqlerrm);
        rollback; -- opcional, dependiendo de si deseas revertir en caso de error
end prc_mc_vlda_embrgos;
   
procedure prc_mc_actualiza_embrgos ( p_cdgo_clnte         in  number,
                                    p_id_prcso_crga      in  number,
                                    p_id_lte             in  number,
                                    p_id_usuario         in  number,
                                    o_cdgo_rspsta        out number,
                                    o_mnsje_rspsta       out varchar2)
    as
    e_no_encuentra_lote     exception;
    e_no_archivo_excel      exception;
    v_et_g_procesos_carga   et_g_procesos_carga%rowtype; 
    v_cdgo_prcso            varchar2(3);
    v_sldo_ttal_crtra       number;
    v_id_sjto_impsto        number;
    v_id_prcsos_smu_sjto    number;
    v_id_prgrma             number;
    v_id_sbprgrma           number;
    v_id_prdo			    number;
    v_id_cnddto			    number;
    v_id_cnddto_vgncia	    number;
    
    p_sjto_id                 si_c_sujetos.id_sjto%type;
    p_json_movimientos        clob;
    v_lte_simu                mc_g_embargos_simu_lote.id_embrgos_smu_lte%type := 0;
    v_id_embrgos_smu_sjto     mc_g_embargos_simu_sujeto.id_embrgos_smu_sjto%type;
    v_existe_tercero          varchar(1);
    v_mnsje	                  varchar2(4000);
    v_deuda_total             number(16,2);
    v_id_fncnrio              mc_g_embargos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio           v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion    si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion      si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion        si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion        si_c_terceros.drccion_ntfccion%type;
    -- LOG
    v_nl						number;
    v_nmbre_up					varchar2(70)	:= 'pkg_mc_actualiza_embargos.prc_mc_actualiza_embrgos';
    begin
    
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_id_lte: ' || p_id_lte, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_id_usuario: ' || p_id_lte, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_cdgo_clnte: ' || p_id_lte, 1);
    
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';
    
    -- Si no se especifica un lote
    /*if p_id_lte is null then
        raise e_no_encuentra_lote;
    end if;*/
    
    -- ****************** INICIO ETL ***************************************************
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, '00 p_id_prcso_crga: ' || p_id_prcso_crga, 1);
    
    begin
        select a.*
        into v_et_g_procesos_carga
        from et_g_procesos_carga a
        where id_prcso_crga = p_id_prcso_crga;
    exception
        when others then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := 'Error al consultar informacion de carga en ETL';
            return;
    end;
    
      --  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, '01 v_et_g_procesos_carga: ' || v_et_g_procesos_carga, 1);

    -- Cargar archivo al directorio
    pk_etl.prc_carga_archivo_directorio (p_file_blob => v_et_g_procesos_carga.file_blob, 
                                         p_file_name => v_et_g_procesos_carga.file_name);
    
    -- Ejecutar proceso de ETL para cargar a tabla intermedia
    pk_etl.prc_carga_intermedia_from_dir (p_cdgo_clnte 		=> p_cdgo_clnte, 
                                          p_id_prcso_crga 	=> p_id_prcso_crga);
                                          
    -- Cargar datos a Gestion
    pk_etl.prc_carga_gestion (p_cdgo_clnte    => p_cdgo_clnte, 
                              p_id_prcso_crga => p_id_prcso_crga);
    
    -- ****************** FIN ETL ******************************************************
    
    --- proceso de depuracion de los datos cargados
    prc_mc_vlda_embrgos ( p_id_lte , o_mnsje_rspsta);
    
    
    end prc_mc_actualiza_embrgos;
    
    end pkg_mc_actualiza_embargos;

/
