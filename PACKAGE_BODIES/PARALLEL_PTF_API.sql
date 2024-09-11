--------------------------------------------------------
--  DDL for Package Body PARALLEL_PTF_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PARALLEL_PTF_API" as

    function fnc_gn_mg_g_intermedia (p_cursor in t_mg_g_intermedia_cursor) return t_mg_g_intermedia_tab pipelined
        parallel_enable(partition p_cursor by hash (clmna2)) is
        
        v_prueba  parallel_ptf_api.t_mg_g_intermedia_tab;
        
    begin
        loop fetch p_cursor bulk collect into v_prueba limit 2000;
            exit when v_prueba.count = 0;
            for i in 1 .. v_prueba.count loop
                pipe row(v_prueba(i));
            end loop;
        end loop;
    end fnc_gn_mg_g_intermedia;
    
    /*Up para migrar establecimientos*/
    procedure prc_mg_estblcmnts_pndntes(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2) as
                                             
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        --c_intrmdia              pkg_mg_migracion.t_mg_g_intermedia_2_cursor;
        
        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;
        
        v_hmlgcion              pkg_mg_migracion.r_hmlgcion;
        
        c_estblcmntos_cursor    pkg_mg_migracion.t_mg_g_intermedia_tab;
        
        v_cntdor                number;
        
        v_id_sjto               number;
        v_id_pais_esblcmnto     number;
        v_id_dprtmnto_esblcmnto number;
        v_id_mncpio_esblcmnto   number;
        
        v_id_pais_esblcmnto_ntfccion        number;
        v_id_dprtmnto_esblcmnto_ntfccion    number;
        v_id_mncpio_esblcmnto_ntfccion      number;
        v_id_sjto_estdo                     number;
        v_id_impsto                         number;
        v_id_sjto_impsto                    number;
        
        v_id_prsna                          number;
        v_id_sjto_tpo                       number;
        v_id_actvdad_ecnmca                 number;
        
        v_id_trcro_estblcmnto               number;
        
        v_json_rspnsbles                    json_array_t;
        v_id_trcro_rspnsble                 number;
        v_id_pais_rspnsble                  number;
        v_id_dprtmnto_rspnsble              number;
        v_id_mncpio_rspnsble                number;
    begin
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        --Se abre el cursor que tiene los registros a procesar
        --open c_intrmdia for select  /*+ parallel(a, id_entdad) */ *
        --                    from    migra.mg_g_intermedia_2   a
        --                    where   a.cdgo_clnte        =   p_cdgo_clnte
        --                    and     a.id_entdad         =   p_id_entdad
        --                    and     a.cdgo_estdo_rgstro =   'L';
            begin
                select  *
                into    v_cdgo_clnte_tab
                from    v_df_s_clientes a
                where   a.cdgo_clnte  =   p_cdgo_clnte;
            exception
                when others then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Problemas al consultar el cliente ' || sqlerrm;
                    return;
            end;

            --Carga los Datos de la Homologación
            v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                               p_id_entdad  =>  p_id_entdad);
        
            --Cursor del establecimiento
            for c_estblcmntos in (
                                    select  /*+ parallel(a, clmna2) */
                                            min(a.id_intrmdia) id_intrmdia,
                                            --si_c_sujetos
                                            a.clmna2,   --Identificación del establecimiento IDNTFCCION
                                            a.clmna3,   --Identificación del establecimiento anterior IDNTFCCION_ANTRIOR
                                            a.clmna4,   --País del establecimiento CDGO_PAIS
                                            a.clmna5,   --Departamento del establecimiento CDGO_DPRTMNTO
                                            a.clmna6,   --Municipio del Establecimiento CDGO_MNCPIO
                                            a.clmna7,   --Dirección del establecimiento DRCCION
                                            a.clmna8,   --Fecha de ingreso del establecimiento Por defecto sysdate FCHA_INGRSO
                                            a.clmna9,   --Código postal del establecimiento CDGO_PSTAL
                                            --si_i_sujetos_impuesto
                                            a.clmna10,  --Código del impuesto CDGO_IMPSTO
                                            a.clmna11,  --País de notificación del establecimiento CDGO_PAIS
                                            a.clmna12,  --Departamento de notificación del establecimiento CDGO_DPRTMNTO
                                            a.clmna13,  --Municipio notificación del Establecimiento CDGO_MNCPIO
                                            a.clmna14,  --Dirección de notificación del establecimiento
                                            a.clmna15,  --Email del establecimiento EMAIL
                                            a.clmna16,  --Teléfono del Establecimiento TLFNO
                                            a.clmna17,  --Código estado de establecimiento CDGO_SJTO_ESTDO
                                            a.clmna18,  --Fecha ultima novedad del establecimiento FCHA_ULTMA_NVDAD
                                            a.clmna19,  --Fecha cancelación del establecimiento FCHA_CNCLCION
                                            --si_i_personas
                                            a.clmna1,   --Tipo identificación del establecimiento CDGO_IDNTFCCION_TPO
                                            a.clmna20,  --Tipo de establecimiento TPO_PRSNA
                                            a.clmna21,  --Primer nombre establecimiento PRMER_NMBRE
                                            a.clmna22,  --Segundo nombre establecimiento SGNDO_NMBRE
                                            a.clmna23,  --Primer apellido establecimiento PRMER_APLLDO
                                            a.clmna24,  --Segundo apellido establecimiento SGNDO_APLLDO
                                            a.clmna25,  --Numero registro cámara de comercio establecimiento NMRO_RGSTRO_CMRA_CMRCIO
                                            a.clmna26,  --Fecha registro cámara de comercio establecimiento FCHA_RGSTRO_CMRA_CMRCIO
                                            a.clmna27,  --Fecha inicio de actividades establecimiento FCHA_INCIO_ACTVDDES
                                            a.clmna28,  --Numero sucursales establecimiento NMRO_SCRSLES
                                            a.clmna29,  --Código tipo de sujeto del establecimiento CDGO_SJTO_TPO
                                            a.clmna30,  --Código actividad económica del establecimiento CDGO_ACTVDAD_ECNMCA,
                                            json_arrayagg(
                                                json_object(
                                                            'id_intrmdia'	value a.id_intrmdia,
                                                            'clmna31' 		value	a.clmna31,
                                                            'clmna32' 		value	a.clmna32,
                                                            'clmna33' 		value	a.clmna33,
                                                            'clmna34' 		value	a.clmna34,
                                                            'clmna35' 		value	a.clmna35,
                                                            'clmna36' 		value	a.clmna36,
                                                            'clmna37' 		value	a.clmna37,
                                                            'clmna38' 		value	a.clmna38,
                                                            'clmna39' 		value	a.clmna39,
                                                            'clmna40' 		value	a.clmna40,
                                                            'clmna41' 		value	a.clmna41,
                                                            'clmna42' 		value	a.clmna42,
                                                            'clmna43' 		value	a.clmna43,
                                                            'clmna44' 		value	a.clmna44,
                                                            'clmna45' 		value	a.clmna45,
                                                            'clmna46' 		value	a.clmna46,
                                                            'clmna47' 		value	a.clmna47
                                                            returning clob
                                                           )
                                                           returning clob
                                                        ) json_rspnsbles
                                    from    migra.mg_g_intermedia_2   a
                                    where   a.cdgo_clnte        =   p_cdgo_clnte
                                    and     a.id_entdad         =   p_id_entdad
                                    and     a.cdgo_estdo_rgstro =   'L'
                                    group by    --si_c_sujetos
                                                a.clmna2,   --Identificación del establecimiento IDNTFCCION
                                                a.clmna3,   --Identificación del establecimiento anterior IDNTFCCION_ANTRIOR
                                                a.clmna4,   --País del establecimiento CDGO_PAIS
                                                a.clmna5,   --Departamento del establecimiento CDGO_DPRTMNTO
                                                a.clmna6,   --Municipio del Establecimiento CDGO_MNCPIO
                                                a.clmna7,   --Dirección del establecimiento DRCCION
                                                a.clmna8,   --Fecha de ingreso del establecimiento Por defecto sysdate FCHA_INGRSO
                                                a.clmna9,   --Código postal del establecimiento CDGO_PSTAL
                                                --si_i_sujetos_impuesto
                                                a.clmna10,  --Código del impuesto CDGO_IMPSTO
                                                a.clmna11,  --País de notificación del establecimiento CDGO_PAIS
                                                a.clmna12,  --Departamento de notificación del establecimiento CDGO_DPRTMNTO
                                                a.clmna13,  --Municipio notificación del Establecimiento CDGO_MNCPIO
                                                a.clmna14,  --Dirección de notificación del establecimiento
                                                a.clmna15,  --Email del establecimiento EMAIL
                                                a.clmna16,  --Teléfono del Establecimiento TLFNO
                                                a.clmna17,  --Código estado de establecimiento CDGO_SJTO_ESTDO
                                                a.clmna18,  --Fecha ultima novedad del establecimiento FCHA_ULTMA_NVDAD
                                                a.clmna19,  --Fecha cancelación del establecimiento FCHA_CNCLCION
                                                --si_i_personas
                                                a.clmna1,   --Tipo identificación del establecimiento CDGO_IDNTFCCION_TPO
                                                a.clmna20,  --Tipo de establecimiento TPO_PRSNA
                                                a.clmna21,  --Primer nombre establecimiento PRMER_NMBRE
                                                a.clmna22,  --Segundo nombre establecimiento SGNDO_NMBRE
                                                a.clmna23,  --Primer apellido establecimiento PRMER_APLLDO
                                                a.clmna24,  --Segundo apellido establecimiento SGNDO_APLLDO
                                                a.clmna25,  --Numero registro cámara de comercio establecimiento NMRO_RGSTRO_CMRA_CMRCIO
                                                a.clmna26,  --Fecha registro cámara de comercio establecimiento FCHA_RGSTRO_CMRA_CMRCIO
                                                a.clmna27,  --Fecha inicio de actividades establecimiento FCHA_INCIO_ACTVDDES
                                                a.clmna28,  --Numero sucursales establecimiento NMRO_SCRSLES
                                                a.clmna29,  --Código tipo de sujeto del establecimiento CDGO_SJTO_TPO
                                                a.clmna30  --Código actividad económica del establecimiento CDGO_ACTVDAD_ECNMCA
                                 )
            loop
                --Se limpian las variables
                v_id_sjto := null;
                
                v_id_sjto               := null;
                v_id_pais_esblcmnto     := null;
                v_id_dprtmnto_esblcmnto := null;
                v_id_mncpio_esblcmnto   := null;
                
                v_id_pais_esblcmnto_ntfccion        := null;
                v_id_dprtmnto_esblcmnto_ntfccion    := null;
                v_id_mncpio_esblcmnto_ntfccion      := null;
                v_id_sjto_estdo                     := null;
                v_id_impsto                         := null;
                v_id_sjto_impsto                    := null;
                
                v_id_prsna                          := null;
                v_id_sjto_tpo                       := null;
                v_id_actvdad_ecnmca                 := null;
                
                v_id_trcro_estblcmnto               := null;
                
                --REGISTRO EN SI_C_SUJETOS
                --Se valida si existe el SI_C_SUJETOS
                begin
                    select  a.id_sjto
                    into    v_id_sjto
                    from    si_c_sujetos    a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.idntfccion    =   c_estblcmntos.clmna2;
                exception
                    when no_data_found then
                        null;
                    when others then
                        o_cdgo_rspsta   := 2;
                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_sujetos. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
                
                --Se continua con el proceso de SI_C_SUJETOS si no existe
                if (v_id_sjto is null) then
                    if (c_estblcmntos.clmna3 is null) then --IDNTFCCION_ANTRIOR
                        c_estblcmntos.clmna3 := c_estblcmntos.clmna2;
                    end if;
                    
                    --Se valida el país el departamento y el municipio
                    if (c_estblcmntos.clmna4 is null) then --País
                        v_id_pais_esblcmnto := v_cdgo_clnte_tab.id_pais;
                    else
                        begin
                            select  a.id_pais
                            into    v_id_pais_esblcmnto
                            from    df_s_paises a
                            where   a.cdgo_pais =   c_estblcmntos.clmna4;
                        exception
                            when others then
                                o_cdgo_rspsta   := 3;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el país del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    c_estblcmntos.clmna5 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 5,
                                                                                 p_vlor    => c_estblcmntos.clmna5,
                                                                                 p_hmlgcion=> v_hmlgcion);
                    
                    if (c_estblcmntos.clmna5 is null) then --Departamento
                        v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
                    else
                        begin
                            select  a.id_dprtmnto
                            into    v_id_dprtmnto_esblcmnto
                            from    df_s_departamentos  a
                            where   a.id_pais       =   v_id_pais_esblcmnto
                            and     a.cdgo_dprtmnto =   c_estblcmntos.clmna5;
                        exception
                            when no_data_found then
                                v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
                            when others then
                                o_cdgo_rspsta   := 4;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    if (c_estblcmntos.clmna6 is null) then --Municipio
                        v_id_mncpio_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
                    else
                        begin
                            select  a.id_mncpio
                            into    v_id_mncpio_esblcmnto
                            from    df_s_municipios a
                            where   a.id_dprtmnto   =   v_id_dprtmnto_esblcmnto 
                            and     a.cdgo_mncpio   =   c_estblcmntos.clmna6;
                        exception
                            when no_data_found then
                                v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
                                v_id_mncpio_esblcmnto := v_cdgo_clnte_tab.id_mncpio;
                            when others then
                                o_cdgo_rspsta   := 5;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    --Se inserta el establecimiento en si_c_sujetos
                    begin
                        insert into si_c_sujetos (cdgo_clnte,
                                                  idntfccion,
                                                  idntfccion_antrior,
                                                  id_pais,
                                                  id_dprtmnto,
                                                  id_mncpio,
                                                  drccion,
                                                  fcha_ingrso,
                                                  cdgo_pstal,
                                                  estdo_blqdo)
                                         values  (p_cdgo_clnte,
                                                  c_estblcmntos.clmna2,
                                                  c_estblcmntos.clmna3,
                                                  v_id_pais_esblcmnto,
                                                  v_id_dprtmnto_esblcmnto,
                                                  v_id_mncpio_esblcmnto,
                                                  c_estblcmntos.clmna7,
                                                  systimestamp,
                                                  c_estblcmntos.clmna9,
                                                  'N') returning id_sjto into v_id_sjto;
                    exception
                        when others then
                            o_cdgo_rspsta   := 6;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_sujetos del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                --REGISTRO EN SI_I_SUJETOS_IMPUESTO
                --Se valida el impuesto
                begin
                    select  a.id_impsto
                    into    v_id_impsto
                    from    df_c_impuestos  a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.cdgo_impsto   =   c_estblcmntos.clmna10;
                exception
                    when others then
                        o_cdgo_rspsta   := 7;
                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el impuesto del establecimiento. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
                
                --Se valida si existe el si_i_sujetos_impuesto
                begin
                    select  a.id_sjto_impsto
                    into    v_id_sjto_impsto
                    from    si_i_sujetos_impuesto   a
                    where   a.id_sjto   =   v_id_sjto
                    and     a.id_impsto =   v_id_impsto;
                exception
                    when no_data_found then
                        null;
                    when others then
                        o_cdgo_rspsta   := 8;
                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_sujetos_impuesto. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
                
                
               --Se continua con el proceso de SI_I_SUJETOS_IMPUESTO si no existe
                if (v_id_sjto_impsto is null) then 
                    --Se valida el país el departamento y el municipio de notificación
                    if (c_estblcmntos.clmna11 is null) then --País de notificación
                        v_id_pais_esblcmnto_ntfccion := v_id_pais_esblcmnto;
                    else
                        begin
                            select  a.id_pais
                            into    v_id_pais_esblcmnto_ntfccion
                            from    df_s_paises a
                            where   a.cdgo_pais =   c_estblcmntos.clmna11;
                        exception
                            when others then
                                o_cdgo_rspsta   := 9;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el país de notificación del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    if (c_estblcmntos.clmna12 is null) then --Departamento de notificación
                        v_id_dprtmnto_esblcmnto_ntfccion := v_id_dprtmnto_esblcmnto;
                    else
                        begin
                            select  a.id_dprtmnto
                            into    v_id_dprtmnto_esblcmnto_ntfccion
                            from    df_s_departamentos  a
                            where   a.id_pais       =   v_id_pais_esblcmnto_ntfccion
                            and     a.cdgo_dprtmnto =   c_estblcmntos.clmna12;
                        exception
                            when no_data_found then
                                null;
                            when others then
                                o_cdgo_rspsta   := 10;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento de notificación del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    if (c_estblcmntos.clmna13 is null) then --Municipio de notificación                        
                        v_id_mncpio_esblcmnto_ntfccion := v_id_mncpio_esblcmnto;                        
                    else                            
                        begin
                            select  a.id_mncpio
                            into    v_id_mncpio_esblcmnto_ntfccion
                            from    df_s_municipios a
                            where   a.id_dprtmnto   =   v_id_dprtmnto_esblcmnto_ntfccion
                            and     a.cdgo_mncpio   =   c_estblcmntos.clmna13;
                        exception
                            when no_data_found then
                                v_id_dprtmnto_esblcmnto_ntfccion := v_id_dprtmnto_esblcmnto;
                                v_id_mncpio_esblcmnto_ntfccion := v_id_mncpio_esblcmnto;
                            when others then
                                o_cdgo_rspsta   := 11;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    --Se valida el estado
                    begin
                        select  a.id_sjto_estdo
                        into    v_id_sjto_estdo
                        from    df_s_sujetos_estado a
                        where   a.cdgo_sjto_estdo   =   c_estblcmntos.clmna17;
                    exception
                        when others then
                            o_cdgo_rspsta   := 12;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el estado del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                    
                    --Se inserta el establecimiento en si_c_sujetos
                    begin
                        insert into si_i_sujetos_impuesto (id_sjto,
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
                                                           fcha_ultma_nvdad,
                                                           fcha_cnclcion)
                                                   values (v_id_sjto,
                                                           v_id_impsto,
                                                           'N',
                                                           v_id_pais_esblcmnto_ntfccion,
                                                           v_id_dprtmnto_esblcmnto_ntfccion,
                                                           v_id_mncpio_esblcmnto_ntfccion,
                                                           c_estblcmntos.clmna14,
                                                           c_estblcmntos.clmna15,
                                                           c_estblcmntos.clmna16,
                                                           systimestamp,
                                                           p_id_usrio,
                                                           v_id_sjto_estdo,
                                                           c_estblcmntos.clmna18,
                                                           c_estblcmntos.clmna19) returning id_sjto_impsto into v_id_sjto_impsto;
                    exception
                        when others then
                            o_cdgo_rspsta   := 13;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_impuesto del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                --REGISTRO EN SI_I_PERSONAS
                --Se valida el objeto persona
                begin
                    select  a.id_prsna
                    into    v_id_prsna
                    from    si_i_personas   a
                    where   a.id_sjto_impsto    =   v_id_sjto_impsto;
                exception
                    when no_data_found then
                        null;
                    when others then
                        o_cdgo_rspsta   := 14;
                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_personas. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
                
                --Se continua con el proceso de si_i_personas si no existe
                if (v_id_prsna is null) then
                    
                    --Se identifica el ID_SJTO_TPO
                    v_id_sjto_tpo := null;
                    begin
                        c_estblcmntos.clmna29 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 29,
                                                                                      p_vlor    => c_estblcmntos.clmna29,
                                                                                      p_hmlgcion=> v_hmlgcion);
                    
                        select  a.id_sjto_tpo
                        into    v_id_sjto_tpo
                        from    df_i_sujetos_tipo   a
                        where   a.cdgo_clnte    =   p_cdgo_clnte
                        and     a.id_impsto     =   v_id_impsto
                        and     a.cdgo_sjto_tpo =   nvl(c_estblcmntos.clmna29, 'N');
                    exception
                        when no_data_found then
                            null;
                        when others then
                            o_cdgo_rspsta   := 15;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el tipo de sujeto (régimen) establecimiento en la tabla id_sjto_tpo. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                    
                    --Se identifica la actividad economica
                    v_id_actvdad_ecnmca := null;
                    begin
                        select      a.id_actvdad_ecnmca
                        into        v_id_actvdad_ecnmca
                        from        gi_d_actividades_economica  a
                        inner join  gi_d_actividades_ecnmca_tpo b   on  b.id_actvdad_ecnmca_tpo =   a.id_actvdad_ecnmca_tpo
                        where       b.cdgo_clnte            =   p_cdgo_clnte
                        and         a.cdgo_actvdad_ecnmca   =   c_estblcmntos.clmna30
                        and         systimestamp between a.fcha_dsde and a.fcha_hsta;
                    exception
                        when no_data_found then
                            null;
                        when others then
                            o_cdgo_rspsta   := 16;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la actividad económica del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                    
                    --Se inserta el establecimiento en si_i_personas
                    begin
                        insert into si_i_personas (id_sjto_impsto,
                                                   cdgo_idntfccion_tpo,
                                                   tpo_prsna,
                                                   nmbre_rzon_scial,
                                                   nmro_rgstro_cmra_cmrcio,
                                                   fcha_rgstro_cmra_cmrcio,
                                                   fcha_incio_actvddes,
                                                   nmro_scrsles,
                                                   drccion_cmra_cmrcio,
                                                   id_sjto_tpo,
                                                   id_actvdad_ecnmca)
                                           values (v_id_sjto_impsto,
                                                   c_estblcmntos.clmna1,
                                                   c_estblcmntos.clmna20,
                                                   c_estblcmntos.clmna21,
                                                   c_estblcmntos.clmna25,
                                                   c_estblcmntos.clmna26,
                                                   c_estblcmntos.clmna27,
                                                   c_estblcmntos.clmna28,
                                                   c_estblcmntos.clmna7,
                                                   v_id_sjto_tpo,
                                                   v_id_actvdad_ecnmca) returning id_prsna into v_id_prsna;
                    exception
                        when others then
                            o_cdgo_rspsta   := 17;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_personas del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                --REGISTRO EN SI_C_TERCEROS
                --Se valida el objeto terceros
                begin
                    select  a.id_trcro
                    into    v_id_trcro_estblcmnto
                    from    si_c_terceros   a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.idntfccion    =   c_estblcmntos.clmna2;
                exception
                    when no_data_found then
                        null;
                    when others then
                        o_cdgo_rspsta   := 18;
                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_terceros. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
                
                --Se continua con el proceso de si_c_terceros si no existe
                if (v_id_trcro_estblcmnto is null) then
                    --Se inserta el establecimiento en si_c_terceros
                    begin
                        insert into si_c_terceros (cdgo_clnte,
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
                                                   indcdor_cntrbynte,
                                                   indcdr_fncnrio,
                                                   cllar)
                                           values (p_cdgo_clnte,
                                                   c_estblcmntos.clmna1,
                                                   c_estblcmntos.clmna2,
                                                   c_estblcmntos.clmna21,
                                                   c_estblcmntos.clmna22,
                                                   nvl(c_estblcmntos.clmna23, '.'),
                                                   c_estblcmntos.clmna24,
                                                   c_estblcmntos.clmna7,
                                                   v_id_pais_esblcmnto,
                                                   v_id_dprtmnto_esblcmnto,
                                                   v_id_mncpio_esblcmnto,
                                                   c_estblcmntos.clmna14,
                                                   v_id_pais_esblcmnto_ntfccion,
                                                   v_id_dprtmnto_esblcmnto_ntfccion,
                                                   v_id_mncpio_esblcmnto_ntfccion,
                                                   c_estblcmntos.clmna15,
                                                   c_estblcmntos.clmna16,
                                                   'S',
                                                   'N',
                                                   c_estblcmntos.clmna16) returning id_trcro into v_id_trcro_estblcmnto;
                    exception
                        when others then
                            o_cdgo_rspsta   := 19;
                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                if (c_estblcmntos.clmna20 = 'J') then
                    --v_json_rspnsbles                    := new json_array_t(c_estblcmntos.json_rspnsbles);
                    v_id_trcro_rspnsble                 := null;
                    v_id_pais_rspnsble                  := null;
                    v_id_dprtmnto_rspnsble              := null;
                    v_id_mncpio_rspnsble                := null;
                    
                    for c_rspnsbles in (
                                            select  a.*
                                            from    json_table(c_estblcmntos.json_rspnsbles, '$[*]'
                                                               columns (id_intrmdia number          path '$.id_intrmdia',
                                                                        clmna31     varchar2(4000)  path '$.clmna31',
                                                                        clmna32     varchar2(4000)  path '$.clmna32',
                                                                        clmna33     varchar2(4000)  path '$.clmna33',
                                                                        clmna34     varchar2(4000)  path '$.clmna34',
                                                                        clmna35     varchar2(4000)  path '$.clmna35',
                                                                        clmna36     varchar2(4000)  path '$.clmna36',
                                                                        clmna37     varchar2(4000)  path '$.clmna37',
                                                                        clmna38     varchar2(4000)  path '$.clmna38',
                                                                        clmna39     varchar2(4000)  path '$.clmna39',
                                                                        clmna40     varchar2(4000)  path '$.clmna40',
                                                                        clmna41     varchar2(4000)  path '$.clmna41',
                                                                        clmna42     varchar2(4000)  path '$.clmna42',
                                                                        clmna43     varchar2(4000)  path '$.clmna43',
                                                                        clmna44     varchar2(4000)  path '$.clmna44',
                                                                        clmna45     varchar2(4000)  path '$.clmna45',
                                                                        clmna46     varchar2(4000)  path '$.clmna46',
                                                                        clmna47     varchar2(4000)  path '$.clmna47'))  a
                                        )
                    loop
                        if (c_rspnsbles.clmna32 is not null) then
                            v_id_trcro_rspnsble     := null;
                            v_id_pais_rspnsble      := null;
                            v_id_dprtmnto_rspnsble  := null;
                            v_id_mncpio_rspnsble    := null;
                            
                            --Se valida el responsable  terceros
                            begin
                                select  a.id_trcro
                                into    v_id_trcro_rspnsble
                                from    si_c_terceros   a
                                where   a.cdgo_clnte    =   p_cdgo_clnte
                                and     a.idntfccion    =   c_rspnsbles.clmna32 ;
                            exception
                                when no_data_found then
                                    null;
                                when others then
                                    o_cdgo_rspsta   := 20;
                                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el responsable en la tabla si_c_terceros. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                            
                            --Si el responsable no existe en si_c_terceros se crea
                            if (v_id_trcro_rspnsble is null) then
                                --Se valida el país el departamento y el municipio de notificación
                                if (c_rspnsbles.clmna38 is null) then --País responsable
                                    v_id_pais_rspnsble := v_id_pais_esblcmnto;
                                else
                                    declare
                                        v_cdgo_pais_rspnsble varchar2(20) := c_rspnsbles.clmna38;
                                    begin
                                        select  a.id_pais
                                        into    v_id_pais_rspnsble
                                        from    df_s_paises a
                                        where   a.cdgo_pais =   v_cdgo_pais_rspnsble;
                                    exception
                                        when others then
                                            o_cdgo_rspsta   := 21;
                                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el país del responsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                            continue;
                                    end;
                                end if;
                                
                                if (c_rspnsbles.clmna39 is null) then --Departamento responsable
                                    v_id_dprtmnto_rspnsble := v_id_dprtmnto_esblcmnto;
                                else
                                    declare
                                        v_cdgo_dprtmnto_rspnsble varchar2(20) := c_rspnsbles.clmna39;
                                    begin
                                        select  a.id_dprtmnto
                                        into    v_id_dprtmnto_rspnsble
                                        from    df_s_departamentos  a
                                        where   a.id_pais       =   v_id_pais_rspnsble
                                        and     a.cdgo_dprtmnto =   v_cdgo_dprtmnto_rspnsble;
                                    exception
                                        when others then
                                            o_cdgo_rspsta   := 22;
                                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del responsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                            continue;
                                    end;
                                end if;
                                if (c_rspnsbles.clmna40 is null) then --Municipio de notificación
                                    v_id_mncpio_rspnsble := v_id_mncpio_esblcmnto;
                                else
                                    declare
                                        v_cdgo_mncpio_rspnsble varchar2(20) := c_rspnsbles.clmna40;
                                    begin
                                        select  a.id_mncpio
                                        into    v_id_mncpio_rspnsble
                                        from    df_s_municipios a
                                        where   a.id_dprtmnto   =   v_id_dprtmnto_rspnsble
                                        and     a.cdgo_mncpio   =   v_cdgo_mncpio_rspnsble;
                                    exception
                                        when no_data_found then
                                            v_id_dprtmnto_rspnsble := v_id_dprtmnto_esblcmnto;
                                            v_id_mncpio_rspnsble := v_id_mncpio_esblcmnto;
                                        when others then
                                            o_cdgo_rspsta   := 23;
                                            o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del reponsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                            continue;
                                    end;
                                end if;
                                
                                --Se registra el responsable en si_c_terceros
                                begin
                                    insert into si_c_terceros (cdgo_clnte,
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
                                                               indcdor_cntrbynte,
                                                               indcdr_fncnrio,
                                                               cllar)
                                                       values (p_cdgo_clnte,
                                                               nvl(c_rspnsbles.clmna31, 'X'),
                                                               c_rspnsbles.clmna32,
                                                               c_rspnsbles.clmna33,
                                                               c_rspnsbles.clmna34,
                                                               nvl(c_rspnsbles.clmna35, '.'),
                                                               c_rspnsbles.clmna36,
                                                               c_rspnsbles.clmna37,
                                                               v_id_pais_rspnsble,
                                                               v_id_dprtmnto_rspnsble,
                                                               v_id_mncpio_rspnsble,
                                                               c_rspnsbles.clmna37,
                                                               v_id_pais_rspnsble,
                                                               v_id_dprtmnto_rspnsble,
                                                               v_id_mncpio_rspnsble,
                                                               c_rspnsbles.clmna41,
                                                               c_rspnsbles.clmna42,
                                                               'N',
                                                               'N',
                                                               c_rspnsbles.clmna42) returning id_trcro into v_id_trcro_rspnsble;
                                exception
                                    when others then
                                        o_cdgo_rspsta   := 24;
                                        o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del responsable. ' || sqlerrm;
                                        --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                        continue;
                                end;
                            end if;
                            
                            --Se insertan el responsable en la tabla si_i_sujetos_responsable
                            begin
                                insert into si_i_sujetos_responsable (id_sjto_impsto,
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
                                                                      actvo,
                                                                      id_trcro)
                                                              values (v_id_sjto_impsto, --id_sjto_impsto
                                                                      nvl(c_rspnsbles.clmna31, 'X'), --cdgo_idntfccion_tpo
                                                                      c_rspnsbles.clmna32, --idntfccion
                                                                      c_rspnsbles.clmna33, --prmer_nmbre
                                                                      c_rspnsbles.clmna34, --sgndo_nmbre
                                                                      nvl(c_rspnsbles.clmna35, '.'), --prmer_aplldo
                                                                      c_rspnsbles.clmna36, --sgndo_aplldo
                                                                      c_rspnsbles.clmna44, --prncpal_s_n
                                                                      c_rspnsbles.clmna45, --cdgo_tpo_rspnsble
                                                                      c_rspnsbles.clmna46, --prcntje_prtcpcion
                                                                      0, --orgen_dcmnto
                                                                      v_id_pais_rspnsble,
                                                                      v_id_dprtmnto_rspnsble,
                                                                      v_id_mncpio_rspnsble,
                                                                      c_rspnsbles.clmna37, --drccion_ntfccion
                                                                      c_rspnsbles.clmna41, --email
                                                                      c_rspnsbles.clmna42, --tlfno
                                                                      c_rspnsbles.clmna47, --actvo
                                                                      v_id_trcro_rspnsble);
                            exception
                                when others then
                                    o_cdgo_rspsta   := 25;
                                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. '
                                    /*|| 'id_sjto_impsto: ' ||v_id_sjto_impsto || ' '
                                    || 'cdgo_idntfccion_tpo: ' ||nvl(c_rspnsbles.clmna31, 'X')  || ' '
                                    || 'idntfccion: ' ||c_rspnsbles.clmna32  || ' '
                                    || 'prmer_nmbre: ' ||c_rspnsbles.clmna33  || ' '
                                    || 'sgndo_nmbre: ' ||c_rspnsbles.clmna34  || ' '
                                    || 'prmer_aplldo: ' ||c_rspnsbles.clmna35  || ' '
                                    || 'sgndo_aplldo: ' ||c_rspnsbles.clmna36  || ' '
                                    || 'prncpal_s_n: ' ||c_rspnsbles.clmna44  || ' '
                                    || 'cdgo_tpo_rspnsble: ' ||c_rspnsbles.clmna45  || ' '
                                    || 'prcntje_prtcpcion: ' ||c_rspnsbles.clmna46  || ' '
                                    || 'v_id_pais_rspnsble: ' ||v_id_pais_rspnsble  || ' '
                                    || 'v_id_dprtmnto_rspnsble: ' ||v_id_dprtmnto_rspnsble  || ' '
                                    || 'v_id_mncpio_rspnsble: ' ||v_id_mncpio_rspnsble  || ' '
                                    || 'drccion_ntfccion: ' ||c_rspnsbles.clmna37  || ' '
                                    || 'email: ' ||c_rspnsbles.clmna41  || ' '
                                    || 'tlfno: ' ||c_rspnsbles.clmna42  || ' '
                                    || 'actvo: ' ||c_rspnsbles.clmna47  || ' '
                                    || 'v_id_trcro_rspnsble: ' ||v_id_trcro_rspnsble || ' '*/
                                    || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_rspnsbles.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end loop;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                --Si el establecimiento es de tipo persona natural
                else
                    declare
                        v_id_sjto_rspnsble number;
                    begin
                        
                        --Se valida el tercero en responsables
                        begin
                            select  a.id_sjto_rspnsble
                            into    v_id_sjto_rspnsble
                            from    si_i_sujetos_responsable    a
                            where   a.id_sjto_impsto    =   v_id_sjto_impsto
                            and     a.idntfccion        =   c_estblcmntos.clmna2
                            and     a.cdgo_tpo_rspnsble =   'L';
                        exception
                            when no_data_found then
                                null;
                            when others then
                                o_cdgo_rspsta   := 26;
                                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                        
                        --Se continua con el proceso de si_i_sujetos_responsable si no existe
                        if (v_id_sjto_rspnsble is null) then
                            begin
                                insert into si_i_sujetos_responsable (id_sjto_impsto,
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
                                                                      actvo,
                                                                      id_trcro)
                                                              values (v_id_sjto_impsto,
                                                                      c_estblcmntos.clmna1,
                                                                      c_estblcmntos.clmna2,
                                                                      c_estblcmntos.clmna21,
                                                                      c_estblcmntos.clmna22,
                                                                      nvl(c_estblcmntos.clmna23, '.'),
                                                                      c_estblcmntos.clmna24,
                                                                      'S',
                                                                      'L',
                                                                      '0',
                                                                      0,
                                                                      v_id_pais_esblcmnto_ntfccion,
                                                                      v_id_dprtmnto_esblcmnto_ntfccion,
                                                                      v_id_mncpio_esblcmnto_ntfccion,
                                                                      c_estblcmntos.clmna14,
                                                                      c_estblcmntos.clmna15,
                                                                      c_estblcmntos.clmna16,
                                                                      'S',
                                                                      v_id_trcro_estblcmnto);
                            exception
                                when others then
                                    o_cdgo_rspsta   := 27;
                                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del establecimiento. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                end if;
                
                --Se asegura el commit;
                commit;
            end loop;
            
            --Se actualiza el estado de los registros procesados en la tabla MIGRA.mg_g_intermedia_2
            begin
                update  migra.mg_g_intermedia_2   a
                set     a.cdgo_estdo_rgstro =   'S'
                where   a.cdgo_clnte        =   p_cdgo_clnte
                and     id_entdad           =   p_id_entdad
                and     cdgo_estdo_rgstro   =   'L';
            exception
                when others then
                    o_cdgo_rspsta   := 28;
                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Procesos con Errores
                o_ttal_error   := v_errors.count;
            begin                    
                forall i in 1 .. o_ttal_error
                    insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                                     values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
            exception
                when others then
                    o_cdgo_rspsta   := 29;
                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Se actualizan en la tabla MIGRA.mg_g_intermedia_2 como error
            begin
                forall j in 1 .. o_ttal_error
                    update  migra.mg_g_intermedia_2   a
                    set     a.cdgo_estdo_rgstro =   'E'
                    where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
            exception
                when others then
                    o_cdgo_rspsta   := 30;
                    o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;        
            end;
            
            commit;
            --Se actualizan y recorren los errores
                --Respuesta Exitosa
                o_cdgo_rspsta  := 0;
                o_mnsje_rspsta := 'Exito';
                
        --close c_intrmdia;
    end prc_mg_estblcmnts_pndntes;

end parallel_ptf_api;

/
