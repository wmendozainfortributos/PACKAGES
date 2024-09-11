--------------------------------------------------------
--  DDL for Package Body PKG_GI_INFORMACION_EXOGENA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_INFORMACION_EXOGENA" as
      
    procedure prc_rg_informacion_exogena(p_cdgo_clnte           in number,
                                         p_id_infrmcion_exgna   in number,
                                         p_id_usrio             in number,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2)
    as
        v_nl                             number;
        nmbre_up                         varchar2(200) := 'pkg_gi_informacion_exogena.prc_rg_informacion_exogena';
        v_gi_g_informacion_exogena       gi_g_informacion_exogena%rowtype;
        v_extnsion_archvo                varchar2(10);
        v_lneas_encbzdo                  number;
        v_id_crga_etl                    number;
        v_id_impsto_sbmpsto              number;
        v_id_prdo                        number;
        v_id_prcso_crga                  number;
        v_prmtir_prcsar                  varchar2(1);
        v_cdgo_idntfccion_tpo            varchar2(1);
        v_pnta_stio                      varchar2(1);        
        v_nmbre_archvo                   varchar2(100);
        v_prcsr_inf_ppal                 varchar2(1);
        v_id_exgna_dto_prncpal           number;
        v_hoja                           varchar2(20);
        v_count                          number := 0;
        v_cant_hojas                     number;


    begin

        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';

        --Determinamos el nivel de log
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);

        -- Obtener informacione exogena(Archivo)
        begin
            select /*+ RESULT_CACHE */
                  *
            into v_gi_g_informacion_exogena
            from gi_g_informacion_exogena
            where id_infrmcion_exgna = p_id_infrmcion_exgna;
        exception
            when no_data_found then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'Error al intentar obtener la informacion de archivo exogena.'||' , '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo exogena.'||' , '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        v_extnsion_archvo := substr(v_gi_g_informacion_exogena.file_name,(instr(v_gi_g_informacion_exogena.file_name, '.', -3)+1),instr(v_gi_g_informacion_exogena.file_name, '.', -3));

        --hallar nombre, encabezado y cantidad de hojas del tipo de archivo EXCEL para darle procesamiento a la información
        begin
            select b.nmbre, b.lneas_encbzdo, b.cant_hojas
              into v_nmbre_archvo, v_lneas_encbzdo, v_cant_hojas
              from gi_g_informacion_exogena a
              join df_i_exogena_archivo_tipo b on a.id_exgna_archvo_tpo = b.id_exgna_archvo_tpo 
             where a.id_infrmcion_exgna = p_id_infrmcion_exgna;
         exception
            when no_data_found then
                o_cdgo_rspsta   := 11;
                o_mnsje_rspsta  := 'Error al intentar obtener nombre archivo, lineas del encabezado o cantidad des hojas a procesar.'||' , '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
            when others then
                o_cdgo_rspsta := 11;
                o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo exogena.'||' , '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        --PROCESAR ARCHIVO PLANO    
        if v_extnsion_archvo = 'txt' then
        /*
        -- **************************** PROCESO ETL ****************************
        -- NOTA: Para que esto funcione debe hacerse la parametrizacion del tipo
        -- de carga de archivos en el modulo de ETL y asociar el ID de la carga
        -- al parametro de configuracion de Informacion Exogena (Ref: df_i_exogena_archivo_tipo)
        begin

            --hallar  encabezado y id_carga ETL del tipo de archivo para darle procesamiento a la información
            begin
                select b.lneas_encbzdo, b.id_crga_etl
                  into v_lneas_encbzdo, v_id_crga_etl
                  from gi_g_informacion_exogena a
                  join df_i_exogena_archivo_tipo b on a.id_exgna_archvo_tpo = b.id_exgna_archvo_tpo 
                 where a.id_infrmcion_exgna = p_id_infrmcion_exgna;
             exception
                when no_data_found then
                    o_cdgo_rspsta   := 2;
                    o_mnsje_rspsta  := 'Error al intentar obtener las lineas de encabezado y id de carga ETL.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta := 'Problemas al consultar las lineas de encabezado y id de carga ETL.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
            end;

            --buscar impuesto subimpuesto para insertar en procesos carga        
             begin
                 select id_impsto_sbmpsto
                   into v_id_impsto_sbmpsto
                   from df_i_impuestos_subimpuesto
                  where cdgo_clnte = v_gi_g_informacion_exogena.cdgo_clnte
                    and id_impsto  = v_gi_g_informacion_exogena.id_impsto;
            exception
                when no_data_found then
                    v_id_impsto_sbmpsto := 0 ;
                    o_cdgo_rspsta   := 3;
                    o_mnsje_rspsta  := 'Error al intentar obtener el impuesto subimpuesto.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                when others then
                    v_id_impsto_sbmpsto := 0 ;
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta := 'Problemas al consultar el impuesto subimpuesto.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
            end;

            --buscar periodo para insertar en procesos carga
            begin
             select id_prdo
               into v_id_prdo
               from df_i_periodos
              where cdgo_clnte          = v_gi_g_informacion_exogena.cdgo_clnte
                and id_impsto           = v_gi_g_informacion_exogena.id_impsto
                and id_impsto_sbmpsto   = v_id_impsto_sbmpsto
                and vgncia              = v_gi_g_informacion_exogena.vgncia
                and cdgo_prdcdad        = 'ANU';
            exception
                when no_data_found then
                    v_id_prdo := 0;
                    o_cdgo_rspsta   := 4;
                    o_mnsje_rspsta  := 'Error al intentar obtener el id del periodo.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                when others then
                    v_id_prdo := 0;
                    o_cdgo_rspsta := 4;
                    o_mnsje_rspsta := 'Problemas al consultar el id del periodo.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
            end;


            insert into et_g_procesos_carga(id_crga
                                          , cdgo_clnte
                                          , id_impsto
                                          , vgncia
                                          , file_blob
                                          , file_name
                                          , file_mimetype
                                          , lneas_encbzdo
                                          , lneas_rsmen
                                          , id_impsto_sbmpsto
                                          , id_prdo
                                          , fcha_rgstro
                                          , id_usrio)
            values (v_id_crga_etl
                 , p_cdgo_clnte
                 , v_gi_g_informacion_exogena.id_impsto
                 , v_gi_g_informacion_exogena.vgncia
                 , v_gi_g_informacion_exogena.file_blob
                 , v_gi_g_informacion_exogena.file_name
                 , v_gi_g_informacion_exogena.file_mimetype
                 , v_lneas_encbzdo
                 , 0
                 , v_id_impsto_sbmpsto
                 , v_id_prdo
                 , systimestamp
                 , p_id_usrio)
            returning id_prcso_crga into v_id_prcso_crga;
        exception
            when others then
                o_cdgo_rspsta := 5;
                o_mnsje_rspsta := 'Error al intentar registrar archivo en ETL.'||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
        end;

        -- Cargar archivo al directorio
        pk_etl.prc_carga_archivo_directorio (p_file_blob => v_gi_g_informacion_exogena.file_blob, 
                                             p_file_name => v_gi_g_informacion_exogena.file_name);

        -- Ejecutar proceso de ETL para cargar a tabla intermedia
        pk_etl.prc_carga_intermedia_from_dir (p_cdgo_clnte => p_cdgo_clnte, 
                                              p_id_impsto  => v_gi_g_informacion_exogena.id_impsto, 
                                              p_id_prcso_crga => v_id_prcso_crga);

        -- Ejecutar proceso ETL para cargar a tabla de gestion
        pk_etl.prc_carga_gestion (p_cdgo_clnte => p_cdgo_clnte, 
                                  p_id_impsto => v_gi_g_informacion_exogena.id_impsto, 
                                  p_id_prcso_crga => v_id_prcso_crga);

        update gi_g_exogena_cargas
        set id_infrmcion_exgna = p_id_infrmcion_exgna 
        where id_prcso_crga = v_id_prcso_crga;

        o_mnsje_rspsta := 'Cargue a ETL finalizado: '||p_id_infrmcion_exgna || ' , ' ||v_id_prcso_crga ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);


        --commit; -- Confirmar proceso ETL
        -- *********************************************************************

        -- recorrer lineas del archivo exogena cargado
        for c_exgna in (select /*+ RESULT_CACHE *//*
                              *
                         from gi_g_exogena_cargas
                        where id_prcso_crga = v_id_prcso_crga
                          and tpo_rgstro   in ( 'I','RP','RD','IF' )
                     order by nmero_lnea
        ) loop

            --Validar si el tipo de registro puede ser procesado.
            begin
                select a.prcsar
                  into v_prmtir_prcsar
                  from gi_d_exogena_tipos_registro a
                  --join gi_g_informacion_exogena    b on b.id_exgna_archvo_tpo = a.id_exgna_archvo_tpo
                 where a.cdgo_exgna_tpo_rgstro     = c_exgna.tpo_rgstro
                   and a.id_exgna_archvo_tpo       = v_gi_g_informacion_exogena.id_exgna_archvo_tpo
                   ;--and rownum <= 1;
            exception
                when no_data_found then
                    v_prmtir_prcsar := 'N';
                    o_cdgo_rspsta   := 6;
                    o_mnsje_rspsta := 'El tipo de registro no se encuentra habilitado para su procesamiento: '|| v_prmtir_prcsar||', '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                when others then
                    v_prmtir_prcsar := 'N';
                    o_cdgo_rspsta := 6;
                    o_mnsje_rspsta := 'El tipo de registro no se encuentra habilitado para su procesamiento: '|| v_prmtir_prcsar||', '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
            end;

            -- Si el tipo de registro es C (Totalizados) y se permite procesar
            if( c_exgna.tpo_rgstro = 'C'  and v_prmtir_prcsar = 'S'  ) then
                continue;
            elsif (c_exgna.tpo_rgstro = 'I'  and v_prmtir_prcsar = 'S' ) then

                -- Homologar el tipo de identificacion
                begin
                    select cdgo_idntfccion_tpo
                    into v_cdgo_idntfccion_tpo
                    from df_s_identificaciones_tipo
                    where nmtcnco_idntfccion_tpo = c_exgna.clumna2;
                exception
                    when no_data_found then
                        v_cdgo_idntfccion_tpo := 'X';
                        o_cdgo_rspsta   := 6;
                        o_mnsje_rspsta := 'Codigo identificación tipo no homologado: '|| v_cdgo_idntfccion_tpo||', '||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    when others then
                        v_cdgo_idntfccion_tpo := 'X';
                        o_cdgo_rspsta := 6;
                        o_mnsje_rspsta := 'Codigo identificación tipo no homologado: '|| v_cdgo_idntfccion_tpo||', '||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                end;

                -- registrar los datos principales
                begin
                    insert into gi_g_exogena_datos_princpal(cdgo_clnte
                                                          , dscrpcion_rgmen
                                                          , vgncia
                                                          , cdgo_idntfccion_tpo
                                                          , idntfccion
                                                          , dv
                                                          , nmbre_rzon_scial
                                                          , id_exgna_crga
                                                          , id_infrmcion_exgna)
                    values(p_cdgo_clnte
                         , c_exgna.clumna5
                         , c_exgna.clumna1
                         , v_cdgo_idntfccion_tpo
                         , c_exgna.clumna3
                         , c_exgna.clumna4
                         , c_exgna.clumna6
                         , c_exgna.id_exgna_crga
                         , p_id_infrmcion_exgna
                         );
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 7;
                        o_mnsje_rspsta := 'Error al ingresar información principal.'||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                        return;
                end;
            continue;
            elsif (c_exgna.tpo_rgstro in ('RP','RD')  and v_prmtir_prcsar = 'S' ) then
                begin
                    insert into gi_g_exogena_retenciones(cdgo_exgna_tpo_rgstro
                                                       , idntfccion
                                                       , nmbre_rzon_scial
                                                       , dscrpcion_cncpto
                                                       , vlor_bse
                                                       , trfa
                                                       , vlor_rtncion
                                                       , vgncia_rtncion
                                                       , prdo
                                                       , id_infrmcion_exgna)
                    values(c_exgna.tpo_rgstro
                         , c_exgna.clumna1
                         , c_exgna.clumna2
                         , c_exgna.clumna3
                         , c_exgna.clumna4
                         , c_exgna.clumna5
                         , c_exgna.clumna6
                         , c_exgna.clumna7
                         , c_exgna.clumna8
                         , p_id_infrmcion_exgna
                         );
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 8;
                        o_mnsje_rspsta := 'Error al insertar retenciones practicadas o que le practicaron.'||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                        return;
                end;
            continue;
            elsif (c_exgna.tpo_rgstro = 'IF'  and v_prmtir_prcsar = 'S' ) then
                begin

                    v_pnta_stio := 'N';

                    if c_exgna.clumna5 = 'SI' then
                        v_pnta_stio := 'S';
                    end if;
                    insert into gi_g_exogena_ingr_fra_muni(cdgo_dane
                                                         , dscrpcion_dprmnto
                                                         , dscrpcion_mncpio
                                                         , vlor
                                                         , plnta_sitio
                                                         , id_infrmcion_exgna)
                    values(c_exgna.clumna1
                         , c_exgna.clumna2
                         , c_exgna.clumna3
                         , c_exgna.clumna4
                         , v_pnta_stio
                         , p_id_infrmcion_exgna
                         );
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 9;
                        o_mnsje_rspsta := 'Error al registrar ingresos fuera del municipio.'||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                        return;
                end;
            end if;
          end loop;
        */
        null;
        --PROCESAR ARCHIVOS INDIVIDUALES
        elsif v_cant_hojas = 1 and v_extnsion_archvo = 'xlsx' then

            -- Obtener informacione exogena(Archivo)
            begin
                select /*+ RESULT_CACHE */
                      *
                into v_gi_g_informacion_exogena
                from gi_g_informacion_exogena
                where id_infrmcion_exgna = p_id_infrmcion_exgna;
            exception
                when no_data_found then
                    o_cdgo_rspsta   := 10;
                    o_mnsje_rspsta  := 'Error al intentar obtener la informacion de archivo exogena.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo exogena.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
            end;

             begin

             --procesar primera hoja predeterminada
             for i in 1..v_cant_hojas  loop
               --v_count := v_count + 1;
               --v_hoja := 'sheet'||v_count||'.xml';

               for c_datos in (
                         select line_number
                               ,col001
                               ,col002
                               ,col003
                               ,col004
                               ,col005
                               ,col006
                               ,col007
                               ,col008
                               ,col009
                               ,col010
                               ,col011
                               ,col012
                               ,col013
                               ,col014
                               ,col015
                            from gi_g_informacion_exogena a
                            cross join table(
                                apex_data_parser.parse(
                                 p_content => a.file_blob
                                ,p_file_name => a.file_name
                                ,p_xlsx_sheet_name => v_hoja 
                                ,p_skip_rows => v_lneas_encbzdo                       
                                )
                            )
                            where a.id_infrmcion_exgna = p_id_infrmcion_exgna
                              and col001 is not null
                )loop 
                    if v_nmbre_archvo = 'Archivo 1' then --or (v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet1.xml')then
                       if c_datos.col001 is not null then
                          insert into gi_g_exogena_retenciones(cdgo_exgna_tpo_rgstro
                                                           ,idntfccion
                                                           ,nmbre_rzon_scial
                                                           ,dscrpcion_cncpto
                                                           ,vlor_bse
                                                           ,trfa
                                                           ,vlor_rtncion
                                                           ,vgncia_rtncion
                                                           ,prdo
                                                           ,id_infrmcion_exgna)
                            values('RP'
                                  ,c_datos.col001
                                  ,c_datos.col003
                                  ,c_datos.col007
                                  ,c_datos.col009
                                  ,c_datos.col010
                                  ,c_datos.col011
                                  ,c_datos.col012
                                  ,c_datos.col013
                                  ,p_id_infrmcion_exgna
                                  );
                        else    
                          continue;
                        end if;
                    elsif v_nmbre_archvo = 'Archivo 2' then --or (v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet2.xml') then
                        if c_datos.col001 is not null then
                        insert into gi_g_exogena_retenciones(cdgo_exgna_tpo_rgstro
                                                            ,idntfccion
                                                            ,nmbre_rzon_scial
                                                            ,dscrpcion_cncpto
                                                            ,vlor_bse
                                                            ,trfa
                                                            ,vlor_rtncion
                                                            ,vgncia_rtncion
                                                            ,prdo
                                                            ,id_infrmcion_exgna)
                             values('RD'
                                   ,c_datos.col001
                                   ,c_datos.col003
                                   ,c_datos.col007
                                   ,c_datos.col009
                                   ,c_datos.col010
                                   ,c_datos.col011
                                   ,c_datos.col012
                                   ,c_datos.col013
                                   ,p_id_infrmcion_exgna
                                   );
                            else    
                              continue;
                            end if;
                    elsif v_nmbre_archvo = 'Archivo 3' then --or (v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet3.xml') then
                        v_pnta_stio := 'N';
                        if c_datos.col009 = 'SI' then
                            v_pnta_stio := 'S';
                        end if;
                        if c_datos.col001 is not null then
                              insert into gi_g_exogena_ingr_fra_muni(dscrpcion_dprmnto
                                                                    ,dscrpcion_mncpio
                                                                    ,vlor
                                                                    ,plnta_sitio
                                                                    ,id_infrmcion_exgna)
                                   values(c_datos.col001
                                         ,c_datos.col003
                                         ,c_datos.col007
                                         ,v_pnta_stio
                                         ,p_id_infrmcion_exgna
                                         );
                            else    
                              continue;
                            end if;
                    elsif v_nmbre_archvo = 'Archivo 4' then --or (v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet4.xml') then
                        if c_datos.col001 is not null then
                        /*insert into gi_g_exogena_ingr_no_gravds(idntfccion
                                                               ,nmbre_rzon_scial
                                                               ,dscrpcion_cncpto
                                                               ,vlor_rtncion
                                                               ,vgncia_rtncion
                                                               ,prdo
                                                               ,id_infrmcion_exgna)
                            values(c_datos.col001
                                  ,c_datos.col003
                                  ,c_datos.col007
                                  ,c_datos.col009
                                  ,c_datos.col010
                                  ,c_datos.col011
                                  ,p_id_infrmcion_exgna
                                  );*/
                                  continue;
                            else    
                              continue;
                            end if;
                    else
                        continue;
                    end if;
                end loop;
              end loop;
            end;

        --PROCESAR ARCHIVOS POR HOJAS    
        elsif v_cant_hojas = 5 and v_extnsion_archvo = 'xlsx' then
            --v_count := v_count + 1;

            -- Obtener informacione exogena(Archivo)
            begin
                select /*+ RESULT_CACHE */
                      *
                into v_gi_g_informacion_exogena
                from gi_g_informacion_exogena
                where id_infrmcion_exgna = p_id_infrmcion_exgna;
            exception
                when no_data_found then
                    o_cdgo_rspsta   := 10;
                    o_mnsje_rspsta  := 'Error al intentar obtener la informacion de archivo exogena.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := 'Problemas al consultar la informacion de archivo exogena.'||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    return;
            end;

             begin

             for i in 1..v_cant_hojas  loop
               v_count := v_count + 1;
               v_hoja := 'sheet'||v_count||'.xml';

               for c_datos in (
                         select line_number
                               ,col001
                               ,col002
                               ,col003
                               ,col004
                               ,col005
                               ,col006
                               ,col007
                               ,col008
                               ,col009
                               ,col010
                               ,col011
                               ,col012
                               ,col013
                               ,col014
                               ,col015
                            from gi_g_informacion_exogena a
                            cross join table(
                                apex_data_parser.parse(
                                 p_content => a.file_blob
                                ,p_file_name => a.file_name
                                ,p_xlsx_sheet_name => v_hoja 
                                ,p_skip_rows => v_lneas_encbzdo                       
                                )
                            )
                            where a.id_infrmcion_exgna = p_id_infrmcion_exgna
                              and col001 is not null
                )loop 
                    if v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet1.xml' then
                       if c_datos.col001 is not null then
                          insert into gi_g_exogena_datos_princpal(tpo_cntrbynte
                                                                 ,vgncia
                                                                 ,cdgo_idntfccion_tpo
                                                                 ,idntfccion
                                                                 ,dv
                                                                 ,nmbre_rzon_scial
                                                                 ,drccion_ntfccion
                                                                 ,tlfno
                                                                 ,cllar
                                                                 ,email
                                                                 ,cdgo_act_ppal_ciiu
                                                                 ,vlor_rscsn_dvlcn_anlcn
                                                                 ,id_infrmcion_exgna)
                            values(c_datos.col001
                                  ,c_datos.col002
                                  ,case 
                                    when c_datos.col003 = 'C.C.' then 'C'
                                    when c_datos.col003 = 'NIT' then 'N'
                                    when c_datos.col003 = 'C.E.' then 'E'
                                    when c_datos.col003 = 'T.I' then 'T'
                                    when c_datos.col003 = 'PASAPORTE' then 'P'
                                    end                                    
                                  ,c_datos.col004
                                  ,c_datos.col005
                                  ,c_datos.col006
                                  ,c_datos.col007
                                  ,c_datos.col008
                                  ,c_datos.col009
                                  ,c_datos.col010
                                  ,c_datos.col011
                                  ,c_datos.col012
                                  ,p_id_infrmcion_exgna
                                  );
                        else    
                          continue;
                        end if;
                    elsif v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet2.xml' then
                       if c_datos.col001 is not null then
                          insert into gi_g_exogena_retenciones(cdgo_exgna_tpo_rgstro
                                                           ,idntfccion
                                                           ,nmbre_rzon_scial
                                                           ,dscrpcion_cncpto
                                                           ,vlor_bse
                                                           ,trfa
                                                           ,vlor_rtncion
                                                           ,vgncia_rtncion
                                                           ,prdo
                                                           ,mnto_rtndo_anual
                                                           ,id_infrmcion_exgna)
                            values('RP'
                                  ,c_datos.col001
                                  ,c_datos.col002
                                  ,c_datos.col003
                                  ,c_datos.col004
                                   --,c_datos.col005
                                   ,to_number(replace(c_datos.col005,'.',','))
                                  ,c_datos.col006
                                  ,c_datos.col007
                                  ,c_datos.col008
                                  ,c_datos.col009
                                  ,p_id_infrmcion_exgna
                                  );
                        else    
                          continue;
                        end if;
                    elsif v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet3.xml' then
                        if c_datos.col001 is not null then
                        insert into gi_g_exogena_retenciones(cdgo_exgna_tpo_rgstro
                                                            ,idntfccion
                                                            ,nmbre_rzon_scial
                                                            ,dscrpcion_cncpto
                                                            ,vlor_bse
                                                            ,trfa
                                                            ,vlor_rtncion
                                                            ,vgncia_rtncion
                                                            ,prdo
                                                            ,id_infrmcion_exgna)
                             values('RD'
                                   ,c_datos.col001
                                   ,c_datos.col002
                                   ,c_datos.col003
                                   ,c_datos.col004
                                   --,c_datos.col005
                                   ,to_number(replace(c_datos.col005,'.',','))
                                   ,c_datos.col006
                                   ,c_datos.col007
                                   ,c_datos.col008
                                   ,p_id_infrmcion_exgna
                                   );
                            else    
                              continue;
                            end if;
                    elsif v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet4.xml' then
                        v_pnta_stio := 'N';
                        if c_datos.col004 = 'SI' then
                            v_pnta_stio := 'S';
                        end if;
                        if c_datos.col001 is not null then
                              insert into gi_g_exogena_ingr_fra_muni(dscrpcion_dprmnto
                                                                    ,dscrpcion_mncpio
                                                                    ,vlor
                                                                    ,plnta_sitio
                                                                    ,cdgo_dane
                                                                    ,id_infrmcion_exgna)
                                   values(c_datos.col001
                                         ,c_datos.col002
                                         ,c_datos.col003
                                         ,v_pnta_stio
                                         ,c_datos.col006
                                         ,p_id_infrmcion_exgna
                                         );
                            else    
                              continue;
                            end if;
                    elsif v_nmbre_archvo = 'Archivo 1' and v_hoja = 'sheet5.xml' then
                        v_pnta_stio := 'N';
                        if c_datos.col004 = 'SI' then
                            v_pnta_stio := 'S';
                        end if;
                        if c_datos.col001 is not null then
                              insert into gi_g_exogena_ingr_dntr_muni(dscrpcion_dprmnto
                                                                     ,dscrpcion_mncpio
                                                                     ,vlor
                                                                     ,plnta_sitio
                                                                     ,cdgo_dane
                                                                     ,id_infrmcion_exgna)
                                   values(c_datos.col001
                                         ,c_datos.col002
                                         ,c_datos.col003
                                         ,v_pnta_stio
                                         ,c_datos.col006
                                         ,p_id_infrmcion_exgna
                                         );
                            else    
                              continue;
                            end if;
                    else
                        continue;
                    end if;
                end loop;
              end loop;
            end;
        end if;

        --cambiar el indicador procesado al archivo
        update gi_g_informacion_exogena 
           set indcdor_prcsdo = 'S' 
         where id_infrmcion_exgna = p_id_infrmcion_exgna;

        commit;

        o_mnsje_rspsta := 'Actualizar indicador procesado para: '||p_id_infrmcion_exgna ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);

    exception
        when others then
            rollback;
                o_cdgo_rspsta := 99;
                o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar información exógena. '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                return;
    end prc_rg_informacion_exogena;
    
    -- Funcion para validar datos numericos
  function fnc_vl_dato_numerico(v_vlor in varchar2) return varchar2 is
    v_number number;
  begin
    v_number := to_number(v_vlor);
    return 'S';
  exception
    when others then
      return 'N';
  end fnc_vl_dato_numerico;

  --Prc para descargar excel con reporte de retenciones practicadas y que le practicaron

  procedure prc_gn_rprte_rtncnes_rd(p_cdgo_clnte   number,
                                    p_idntfccion   in varchar2,
                                    p_vgncia       in varchar2,
                                    p_tpo_rtncion  in varchar2,
                                    o_file_blob    out blob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
    v_nl          number;
    v_nmbre_up    varchar2(100) := 'prc_gn_rprte_rtncnes_excl';
    v_num_fla     number := 5; -- numero de filas del excel
    v_bfile       bfile; -- apuntador del documento en disco
    v_directorio  clob := 'TS_GUIAS'; -- directorio donde caera el archivo
    v_file_name   varchar2(3000); -- nombre del archivo
    v_file_blob   blob;
    v_nmbre_clnte varchar2(1000);
    v_slgan       varchar2(1000);
    v_nit         varchar2(1000);
    v_rzon_scial  si_i_personas.nmbre_rzon_scial%type;
    v_borderId    number;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando' || systimestamp,
                          1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- datos del cliente
    select upper(nmbre_clnte), nmro_idntfccion, upper(slgan)
      into v_nmbre_clnte, v_nit, v_slgan
      from df_s_clientes
     where cdgo_clnte = p_cdgo_clnte;
  
    select a.nmbre_rzon_scial
      into v_rzon_scial
      from si_i_personas a
      join v_si_i_sujetos_impuesto b
        on b.id_sjto_impsto = a.id_sjto_impsto
     where b.idntfccion_sjto = p_idntfccion
       and b.id_impsto = 700012;
  
    v_file_blob := empty_blob(); -- inicializacion del blob
    v_file_name := 'Reporte_Retenciones_Paracticaron_' || p_idntfccion ||
                   '.xlsx'; -- nombre del archivo
  
    -- crear una hoja
    as_xlsx.new_sheet('hoja1');
  
    --borde para las celdas
    v_borderId := as_xlsx.get_border('thin', 'thin', 'thin', 'thin');
  
    -- combinamos celdas
    as_xlsx.mergecells(1, 1, 8, 1); -- cliente
    as_xlsx.mergecells(1, 2, 8, 2); -- nit
    as_xlsx.mergecells(1, 3, 8, 3); -- nombre del reporte
  
    -- estilos de encabezado
    as_xlsx.cell(1,
                 1,
                 v_nmbre_clnte,
                 p_alignment   => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid      => as_xlsx.get_font('Calibri',
                                                   p_bold     => true,
                                                   p_fontsize => 12));
  
    as_xlsx.cell(1,
                 2,
                 'Nit. ' || v_nit,
                 p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid => as_xlsx.get_font('Calibri',
                                              p_bold     => true,
                                              p_fontsize => 12));
  
    if p_tpo_rtncion = 'RD' then
    
      as_xlsx.cell(1,
                   3,
                   'RETENCIONES QUE LE PRACTICARON A ' || v_rzon_scial ||
                   ' - ' || p_idntfccion,
                   p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                   p_fontid => as_xlsx.get_font('Calibri',
                                                p_bold     => true,
                                                p_fontsize => 12));
    
    elsif p_tpo_rtncion = 'RP' then
    
      as_xlsx.cell(1,
                   3,
                   'RETENCIONES PRACTICADAS POR ' || v_rzon_scial || ' - ' ||
                   p_idntfccion,
                   p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                   p_fontid => as_xlsx.get_font('Calibri',
                                                p_bold     => true,
                                                p_fontsize => 12));
    end if;
  
    -- alinear fila 6 del excel y crear filtro
    as_xlsx.set_row(p_row       => 4,
                    p_alignment => as_xlsx.get_alignment(p_horizontal => 'center',
                                                         p_vertical   => 'center'),
                    p_fontid    => as_xlsx.get_font('Calibri',
                                                    p_bold     => true,
                                                    p_fontsize => 11),
                    p_borderId  => v_borderId);
  
    as_xlsx.cell(1,
                 v_num_fla,
                 'IDENTIFICACIÓN',
                 p_alignment     => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid        => as_xlsx.get_font('Calibri',
                                                     p_bold     => true,
                                                     p_fontsize => 12),
                 p_borderId      => v_borderId);
    as_xlsx.set_column_width(1, 20);
    as_xlsx.cell(2,
                 v_num_fla,
                 'RAZÓN SOCIAL',
                 p_alignment   => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid      => as_xlsx.get_font('Calibri',
                                                   p_bold     => true,
                                                   p_fontsize => 12),
                 p_borderId    => v_borderId);
    as_xlsx.set_column_width(2, 40);
    as_xlsx.cell(3,
                 v_num_fla,
                 'CONCEPTO',
                 p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid    => as_xlsx.get_font('Calibri',
                                                 p_bold     => true,
                                                 p_fontsize => 12),
                 p_borderId  => v_borderId);
    as_xlsx.set_column_width(3, 20);
    as_xlsx.cell(4,
                 v_num_fla,
                 'BASE RETENCIÓN',
                 p_alignment     => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid        => as_xlsx.get_font('Calibri',
                                                     p_bold     => true,
                                                     p_fontsize => 12),
                 p_borderId      => v_borderId);
    as_xlsx.set_column_width(4, 20);
    as_xlsx.cell(5,
                 v_num_fla,
                 'TARIFA',
                 p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid    => as_xlsx.get_font('Calibri',
                                                 p_bold     => true,
                                                 p_fontsize => 12),
                 p_borderId  => v_borderId);
    as_xlsx.set_column_width(5, 20);
    as_xlsx.cell(6,
                 v_num_fla,
                 'VALOR RETENCIÓN',
                 p_alignment      => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid         => as_xlsx.get_font('Calibri',
                                                      p_bold     => true,
                                                      p_fontsize => 12),
                 p_borderId       => v_borderId);
    as_xlsx.set_column_width(6, 20);
    as_xlsx.cell(7,
                 v_num_fla,
                 'VIGENCIA',
                 p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid    => as_xlsx.get_font('Calibri',
                                                 p_bold     => true,
                                                 p_fontsize => 12),
                 p_borderId  => v_borderId);
    as_xlsx.set_column_width(7, 10);
    as_xlsx.cell(8,
                 v_num_fla,
                 'PERÍODO',
                 p_alignment => as_xlsx.get_alignment(p_horizontal => 'center'),
                 p_fontid    => as_xlsx.get_font('Calibri',
                                                 p_bold     => true,
                                                 p_fontsize => 12),
                 p_borderId  => v_borderId);
    as_xlsx.set_column_width(8, 10);
  
    if p_tpo_rtncion = 'RD' then
      for retenciones in (select a.idntfccion_sjto,
                                 a.nmbre_rzon_scial,
                                 a.dscrpcion_cncpto,
                                 a.vlor_bse,
                                 a.trfa,
                                 a.vlor_rtncion,
                                 a.vgncia_rtncion,
                                 a.prdo
                            from v_rtncnes_prctcdas_rd a
                           where a.idntfccion = p_idntfccion
                             and (a.vgncia_rtncion = p_vgncia or
                                 p_vgncia is null)
                             and a.cdgo_exgna_tpo_rgstro = 'RP'
                           order by a.vgncia_rtncion, a.prdo) loop
      
        v_num_fla := v_num_fla + 1;
        as_xlsx.cell(1,
                     v_num_fla,
                     retenciones.idntfccion_sjto,
                     p_alignment                 => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId                  => v_borderId);
        as_xlsx.cell(2,
                     v_num_fla,
                     retenciones.nmbre_rzon_scial,
                     p_alignment                  => as_xlsx.get_alignment(p_horizontal => 'left'),
                     p_borderId                   => v_borderId);
        as_xlsx.cell(3,
                     v_num_fla,
                     retenciones.dscrpcion_cncpto,
                     p_alignment                  => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId                   => v_borderId);
        as_xlsx.cell(4,
                     v_num_fla,
                     retenciones.vlor_bse,
                     p_alignment          => as_xlsx.get_alignment(p_horizontal => 'right'),
                     p_borderId           => v_borderId);
        as_xlsx.cell(5,
                     v_num_fla,
                     retenciones.trfa,
                     p_alignment      => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId       => v_borderId);
        as_xlsx.cell(6,
                     v_num_fla,
                     retenciones.vlor_rtncion,
                     p_alignment              => as_xlsx.get_alignment(p_horizontal => 'right'),
                     p_borderId               => v_borderId);
        as_xlsx.cell(7,
                     v_num_fla,
                     retenciones.vgncia_rtncion,
                     p_alignment                => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId                 => v_borderId);
        as_xlsx.cell(8,
                     v_num_fla,
                     retenciones.prdo,
                     p_alignment      => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId       => v_borderId);
      end loop;
    
    elsif p_tpo_rtncion = 'RP' then
    
      for reteRp in (select d.idntfccion,
                            d.nmbre_rzon_scial,
                            d.dscrpcion_cncpto as Concepto,
                            ltrim(rtrim(to_char(d.vlor_bse,
                                                'FM$999G999G999G999G999G999G990'))) as base,
                            d.trfa as Tarifa,
                            ltrim(rtrim(to_char(d.vlor_rtncion,
                                                'FM$999G999G999G999G999G999G990'))) as vlor,
                            d.vgncia_rtncion as Vigencia,
                            d.prdo as Periodo
                       from v_gi_g_informacion_exogena a
                       join v_si_i_sujetos_impuesto b
                         on b.id_sjto_impsto = a.id_sjto_impsto
                       join si_i_personas p
                         on p.id_sjto_impsto = a.id_sjto_impsto
                       join gi_g_exogena_retenciones d
                         on d.id_infrmcion_exgna = a.id_infrmcion_exgna
                        and d.cdgo_exgna_tpo_rgstro = 'RP'
                      where b.idntfccion_sjto = p_idntfccion
                        and (a.vgncia = p_vgncia or p_vgncia is null)
                        and a.fcha_dgta =
                            (select max(c.fcha_dgta)
                               from gi_g_informacion_exogena c
                              where c.id_sjto_impsto = a.id_sjto_impsto
                                and c.vgncia = a.vgncia)
                      order by d.vgncia_rtncion, d.prdo) loop
      
        v_num_fla := v_num_fla + 1;
        as_xlsx.cell(1,
                     v_num_fla,
                     reteRp.idntfccion,
                     p_alignment       => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId        => v_borderId);
        as_xlsx.cell(2,
                     v_num_fla,
                     reteRp.nmbre_rzon_scial,
                     p_alignment             => as_xlsx.get_alignment(p_horizontal => 'left'),
                     p_borderId              => v_borderId);
      
        as_xlsx.cell(3,
                     v_num_fla,
                     reteRp.concepto,
                     p_alignment     => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId      => v_borderId);
        as_xlsx.cell(4,
                     v_num_fla,
                     reteRp.base,
                     p_alignment => as_xlsx.get_alignment(p_horizontal => 'right'),
                     p_borderId  => v_borderId);
        as_xlsx.cell(5,
                     v_num_fla,
                     reteRp.tarifa,
                     p_alignment   => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId    => v_borderId);
        as_xlsx.cell(6,
                     v_num_fla,
                     reteRp.vlor,
                     p_alignment => as_xlsx.get_alignment(p_horizontal => 'right'),
                     p_borderId  => v_borderId);
        as_xlsx.cell(7,
                     v_num_fla,
                     reteRp.vigencia,
                     p_alignment     => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId      => v_borderId);
        as_xlsx.cell(8,
                     v_num_fla,
                     reteRp.periodo,
                     p_alignment    => as_xlsx.get_alignment(p_horizontal => 'center'),
                     p_borderId     => v_borderId);
      
      end loop;
    
    end if;
  
    as_xlsx.save(v_directorio, v_file_name);
  
    -- cargar el archivo blob
    dbms_lob.createtemporary(lob_loc => o_file_blob,
                             cache   => true,
                             dur     => dbms_lob.call);
    dbms_lob.open(o_file_blob, dbms_lob.lob_readwrite);
  
    v_bfile := bfilename(v_directorio, v_file_name);
    dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
    dbms_lob.loadfromfile(o_file_blob,
                          v_bfile,
                          dbms_lob.getlength(v_bfile));
    dbms_lob.fileclose(v_bfile);
  
    dbms_lob.close(o_file_blob);
  
    -- mensaje de salida
    o_mnsje_rspsta := 'El archivo fue generado exitosamente';
  
  exception
    when others then
      o_cdgo_rspsta  := -1;
      o_mnsje_rspsta := 'Ha ocurrido un error: ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Error: ' || sqlerrm,
                            3);
      raise;
  end prc_gn_rprte_rtncnes_rd;
    
    
end pkg_gi_informacion_exogena;

/
