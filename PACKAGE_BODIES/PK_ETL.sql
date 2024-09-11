--------------------------------------------------------
--  DDL for Package Body PK_ETL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PK_ETL" as

  procedure prc_carga_intermedia_from_dir (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number) as
  
    cursor c1 is
    select a.*
    from v_et_g_procesos_carga a
    where id_prcso_crga = p_id_prcso_crga;

    v_c1 c1%rowtype;
    v_nl number;

    v_line        varchar2 (32767) := null;
    v_rows        number;
    v_si_no       number := 1;

    v_num_linea     number(8) := 0;
    v_columnas      varchar2(4000);
    v_datos       varchar2(4000);
    v_dato        varchar2(4000);
    v_dml       varchar2(4000);
    pos_ini       number;
    v_respuesta     varchar2(2000);
    v_cont_error    number;
    v_ddl_validacion  varchar2(4000);
    v_validacion    varchar2(500);
        v_nmbre_up          varchar2(50) := 'pk_etl.prc_carga_intermedia_from_dir';
    v_fcha_incio    timestamp;
    v_sw_datos_error  number;
    v_rgstros_extsos  number;
    v_rgstros_error   number;

    v_cdgo_estdo_lnea et_g_procesos_intermedia.cdgo_estdo_lnea%type;
    TYPE typ_texto_varray IS varray(1000000000) of varchar2(1000);
    v_vector      typ_texto_varray := typ_texto_varray(null);
    v_cont        number;
    v_cursor      number;
    v_row       number;

    v_archivo utl_file.file_type;
    --v_linea varchar2(1024);

  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir' );
    -- Traza
    v_fcha_incio  := systimestamp;
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, 'Incia prc_carga_intermedia. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

    -- Abrimos el cursor que trae el proceso de carga
    open c1;
    fetch c1 into v_c1;
    if c1%found then

            --Incluido por Nelson Ardila - Funcionalidad que permite el cargue del XLS o XLSX
            --Nota: Este Proceso Trabaja con las Colecciones de Apex - Datos de la Sesion 
            if v_c1.cdgo_archvo_tpo = 'EX'  then
                 declare
                    v_cndcion           varchar2(500);
                    v_clmna_vlda        boolean;
                    v_collection_name   varchar2(50) := 'ETLEXC';
                 begin

                    --Inicializa las Variables Acumuladoras
                    v_rgstros_error  := 0;
                    v_rgstros_extsos := 0;
                    v_num_linea      := v_c1.lneas_encbzdo;

                    -- Determinamos el nivel del Log de la UPv
                    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );

                    if( apex_collection.collection_member_count( p_collection_name => v_collection_name ) > 0 ) then

                        for c_dtos in (
                                           select seq_id 
                                             from apex_collections
                                            where collection_name = v_collection_name
                                              and seq_id > v_c1.lneas_encbzdo
                                         order by seq_id
                                      ) loop

                            --Indica el Numero de Linea del Archivo
                            v_num_linea      := ( v_num_linea + 1 );

                            --Limpia las Variables
                            v_datos          := '';
                            v_columnas       := '';
                            v_sw_datos_error := 0; 
                            v_dml            := '';

                            --Cursor de Columnas de la Fila
                            for c_clmnas in (
                                                 select a.nmbre_clmna
                                                      , b.vlor
                                                      , ( select m.oprdor from df_s_operadores_tipo m where m.id_oprdor_tpo = a.id_oprdor_tpo ) as oprdor 
                                                      , a.vlor1
                                                      , a.vlor2
                                                      , a.indcdor_vlda
                                                      , a.cdgo_dto_tpo
                                                      , decode( a.cdgo_dto_tpo , 'C' , 'varchar2' , 'N' , 'number' , 'F' , 'date' , 'varchar2' ) as tpo_clmna
                                                   from et_d_reglas_intermedia a
                                              left join (
                                                             select seq_id
                                                                  , c001 , c002 , c003 , c004 , c005 , c006 , c007 , c008 , c009 , c010
                                                                  , c011 , c012 , c013 , c014 , c015 , c016 , c017 , c018 , c019 , c020
                                                                  , c021 , c022 , c023 , c024 , c025 , c026 , c027 , c028 , c029 , c030 
                                                                  , c031 , c032 , c033 , c034 , c035 , c036 , c037 , c038 , c039 , c040
                                                                  , c041 , c042 , c043 , c044 , c045 , c046 , c047 , c048 , c049
                                                                  , c050
                                                               from apex_collections
                                                              where collection_name = v_collection_name
                                                                and seq_id          = c_dtos.seq_id
                                                        )
                                                 unpivot (
                                                            vlor
                                                            for clmna in ( c001 , c002 , c003 , c004 , c005 , c006 , c007 , c008 , c009 , c010
                                                                         , c011 , c012 , c013 , c014 , c015 , c016 , c017 , c018 , c019 , c020
                                                                         , c021 , c022 , c023 , c024 , c025 , c026 , c027 , c028 , c029 , c030 
                                                                         , c031 , c032 , c033 , c034 , c035 , c036 , c037 , c038 , c039 , c040
                                                                         , c041 , c042 , c043 , c044 , c045 , c046 , c047 , c048 , c049
                                                                         , c050 ) 
                                                         ) b
                                                        on 'C' || lpad( replace( a.nmbre_clmna , 'CLUMNA' ) , 3 , 0 ) = b.clmna
                                                     where a.id_crga = v_c1.id_crga
                                                  order by to_number( substr( a.nmbre_clmna , 7 ))
                                            ) loop

                                --Asigna el Tipo de Formato del Valor
                                c_clmnas.vlor := pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                            , p_valor => c_clmnas.vlor );

                                if( c_clmnas.indcdor_vlda = 'S' ) then
                                    --Constructor de Condiciones
                                    v_cndcion := c_clmnas.vlor || ' '  
                                                               || ( case when c_clmnas.oprdor = 'LIKE'    then
                                                                          'like ' || chr(39) || '%' || c_clmnas.vlor1 || '%' || chr(39) 
                                                                         when c_clmnas.oprdor = 'LIKE I'  then
                                                                          'like ' || chr(39) || c_clmnas.vlor1 || '%' || chr(39) 
                                                                         when c_clmnas.oprdor = 'LIKE T'  then
                                                                          'like ' || chr(39) || '%' || c_clmnas.vlor1 || chr(39) 
                                                                         else
                                                                          c_clmnas.oprdor || ( case when c_clmnas.oprdor in ( 'IN' , 'NOT IN' ) then
                                                                                                     ' ( ' || c_clmnas.vlor1 || ')'
                                                                                                    when c_clmnas.oprdor not in ( 'IS NULL' , 'IS NOT NULL' ) then
                                                                                                     ' (' || pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                                                                                        , p_valor => c_clmnas.vlor1 ) || ')'
                                                                                                end )
                                                                    end ) || ( case when c_clmnas.oprdor = 'BETWEEN' then
                                                                                  ' and ' || pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                                                                        , p_valor => c_clmnas.vlor2 )
                                                                                end );

                                    --Valida la Condición
                                    begin
                                       execute immediate 'begin :result := ' || v_cndcion || '; end;'
                                         using out v_clmna_vlda; 
                                    exception
                                         when others then
                                              v_sw_datos_error := 1;
                                              --Contadora de Registro con Error
                                              v_rgstros_error  := v_rgstros_error + 1;

                                              --Registra el Error
                                              insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                                   values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , c_clmnas.nmbre_clmna , v_cndcion );

                                              v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion ||  ' Error: ' || sqlerrm;
                                              pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                              exit;
                                    end;

                                    --Verifica si la Condición es Valida
                                    if( not v_clmna_vlda ) then
                                        v_sw_datos_error := 1;
                                        --Contadora de Registro con Error
                                        v_rgstros_error  := v_rgstros_error + 1;

                                        --Registra el Error
                                        insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                             values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , c_clmnas.nmbre_clmna , v_cndcion );

                                        v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                        exit;
                                    end if;

                                end if;

                                v_datos    := v_datos || ' , ' || c_clmnas.vlor;
                                v_columnas := v_columnas || ' , ' || c_clmnas.nmbre_clmna;

                            end loop;

                            if( v_sw_datos_error = 0 ) then
                                --Construccion del comando DML de Proceso Intermedia
                                v_dml := 'insert into et_g_procesos_intermedia (id_prcso_crga, nmero_lnea, cdgo_estdo_lnea, indcdor_error_in ';
                                v_dml := v_dml || v_columnas || ') values (';
                                v_dml := v_dml || p_id_prcso_crga || ', ' || v_num_linea || ', ''SP'',' || v_sw_datos_error || v_datos || ')';

                                --Ejecuta la el Comando (DML)
                                begin
                                    execute immediate v_dml;

                                    --Contadora de Registro con Exito
                                    v_rgstros_extsos := v_rgstros_extsos + 1;
                                    --Registra Log de los DML
                                    v_respuesta := 'v_dml: ' || v_dml;
                                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up , v_nl , v_respuesta , 6 );
                                exception
                                     when others then
                                          --Contadora de Registro con Error
                                          v_rgstros_error  := v_rgstros_error + 1;

                                          v_respuesta := 'Linea # ' || v_num_linea || ' DML ' || v_dml ||  ' Error: ' || sqlerrm; 

                                          --Registra el Error
                                          insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                               values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , 'DML' , v_respuesta );

                                          v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion ||  ' Error: ' || sqlerrm;
                                          pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                end;                         
                            end if;
                        end loop;

                        --Limpia la coleccion 
                        apex_collection.delete_collection ( p_collection_name => v_collection_name );

                        --Inserta la Traza de la Carga
                        insert into et_g_procesos_carga_traza ( id_prcso_crga , orgen , rgstros_prcsdos , rgstros_extsos 
                                                              , rgstros_error , fcha_incio, fcha_fin )
                                                       values ( p_id_prcso_crga , 'INTERMEDIA', v_num_linea , v_rgstros_extsos 
                                                              , v_rgstros_error , v_fcha_incio , systimestamp);

                        --Actualiza el estado del Proceso Carga
                        update et_g_procesos_carga 
                           set cdgo_prcso_estdo = 'CI'
                         where id_prcso_crga    = p_id_prcso_crga;

                    end if;
                 end;
               --Exit UP           
               return;
            end if;

      -- Se hallo el proceso de carga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, 'Hallado proceso de cargar: ' || p_id_prcso_crga, 5);

      -- Determinamos si Existe el Archivo

      -- Abrimos el Archivo
      v_archivo := utl_file.fopen ('ETL_CARGA', v_c1.file_name, 'r');

      -- Iniciamos los contadores de registros exitosos y erróneos
      v_rgstros_extsos  := 0;
      v_rgstros_error   := 0;
      -- Recorremos el archivo 
      loop
        utl_file.get_line (v_archivo, v_line);
        begin
          v_num_linea := v_num_linea +1;
          v_columnas := '';
          v_datos := '';

          -- Se valida si la v_num_linea corresponde a las lineas es de encabezado
          if v_c1.lneas_encbzdo < v_num_linea then 

            -- Asumimos que la validación del Registro es exitosa
            v_sw_datos_error := 0;



            -- **************************************************************
            -- Procesamos la linea dependiendo del tipo de archivo
            -- **************************************************************
            v_respuesta := ' Tipo de archivo ' || v_c1.cdgo_archvo_tpo;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 6);

                        if v_c1.cdgo_archvo_tpo = 'AF'  then
              -- Si es ancho fijo
              for i  in ( select  a.*, 
                        (select m.oprdor from df_s_operadores_tipo m where m.id_oprdor_tpo = a.id_oprdor_tpo) oprdor
                    from et_d_reglas_intermedia a
                    where id_crga = v_c1.id_crga 
                    order by to_number(substr(nmbre_clmna,7)) ) loop

                -- Extraemos Datos.  Recorremos las columnas de reglas por CARCATERES DE INICIO y FIN
                v_columnas  := v_columnas || i.nmbre_clmna || ', ';
                v_dato := replace( substr(v_line, i.crcter_incial, i.crcter_fnal - i.crcter_incial + 1) , chr(39), chr(49844)) ;
                v_datos := v_datos || '''' || v_dato || ''', ';

                -- Validamos Contenidos (Datos)
                if i.indcdor_vlda = 'S' then
                  --v_ddl_validacion := 'Select 1 from dual where ''' ||  v_datos || ''' ' || i.oprdor || ' ';
                  v_ddl_validacion := 'Select 1 a from dual where ' ||  v_dato || ' ' || i.oprdor || ' ';
                  if i.oprdor in  ('=', '>=', '<=', '>', '<', '<>') then
                    v_validacion := i.vlor1;
                  elsif i.oprdor in ('IN', 'NOT IN') then
                    v_validacion := '(' || i.vlor1 || ')';
                  elsif i.oprdor in ('BETWEEN') then
                    v_validacion := i.vlor1 || ' and ' || i.vlor2;
                  end if;
                  v_ddl_validacion := v_ddl_validacion || v_validacion;

                  -- Ejecutamos Validación
                  v_cursor := dbms_sql.open_cursor;

                                    v_respuesta :=  'Linea # ' || v_num_linea || '  v_ddl_validacion: ' || v_ddl_validacion;
                                    -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 4);

                  dbms_sql.parse(v_cursor, v_ddl_validacion, dbms_sql.native);
                  v_row := dbms_sql.execute(v_cursor);
                  if dbms_sql.fetch_rows(v_cursor) = 0 then
                    -- Validación del Dato No Paso
                    v_sw_datos_error := 1;

                    -- Registramos el Error
                    insert into et_g_procesos_carga_error (id_prcso_crga, orgen, nmero_lnea, clmna_orgen, vldcion_error) 
                    values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, i.nmbre_clmna, v_dato || ' ' || i.oprdor || v_validacion);

                    -- Generar LOG -Para critica-
                    v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || i.nmbre_clmna || ': ' || v_dato || ' ' || i.oprdor || ' ' || v_validacion;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 4);
                  end if;
                  dbms_sql.close_cursor(v_cursor);


                end if;
              end loop;
              --null;
            elsif v_c1.cdgo_archvo_tpo = 'DC'  then
              -- Si es Caracter Delimitador

              -- Poblamos el Vector
              v_cont := 0;
              pos_ini := 1;


              while (pos_ini < length(v_line)) loop    
                v_cont := v_cont + 1;
                v_vector.extend ;

                if instr( v_line, v_c1.crcter_dlmtdo, pos_ini) > 0 then
                  v_vector(v_cont) := substr(  v_line, pos_ini, instr( v_line, v_c1.crcter_dlmtdo, pos_ini) - pos_ini );  
                  pos_ini := instr( v_line, v_c1.crcter_dlmtdo, pos_ini) + 1;

                else
                  v_vector(v_cont) := substr(  v_line, pos_ini, length(v_line)+2 - pos_ini );
                   pos_ini :=  length(v_line);
                end if;
                --pos_ini := instr( v_line, v_c1.crcter_dlmtdo, pos_ini) + 1;

              end loop;

              -- Recorremos las columnas de reglas por POSICION
              for i  in (select * from et_d_reglas_intermedia where id_crga = v_c1.id_crga order by pscion) loop
                -- Recorremos las columnas de reglas
                v_columnas  := v_columnas || i.nmbre_clmna || ', ';
                v_vector(i.pscion) := replace(v_vector(i.pscion) , chr(39), chr(49844)) ;
                v_vector(i.pscion) := substr(v_vector(i.pscion),0,i.tmno) ;
                v_datos := v_datos || '''' || v_vector(i.pscion)  || ''', ';

                -- Validamos el Contenidos (Datos)
              end loop;
              --null;
            end if;

          else 
          -- La linea corresponde al encabezado del archivo
          v_respuesta := ' Linea #  ' || v_num_linea || ' es del encabezado';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 6);

          end if;

          v_respuesta :=  'Linea # ' || v_num_linea ||' v_sw_datos_error: ' || v_sw_datos_error || ' Columnas: ' || v_columnas || ' Datos: ' || v_datos;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 6);

          -- Eliminamos caracteres demás  e Insertamos regsitro en tabla Intermedia
          if length(v_columnas) > 0 then
            -- Eliminamos el último carcater (, )
            v_columnas  := substr(v_columnas, 1, length(v_columnas)-2);
            v_datos  := substr(v_datos, 1, length(v_datos)-2);

            -- Construimos DML
            v_dml := 'insert into et_g_procesos_intermedia (id_prcso_crga, nmero_lnea, cdgo_estdo_lnea, indcdor_error_in, ';
            v_dml := v_dml || v_columnas || ') values (';
            v_dml := v_dml || p_id_prcso_crga || ', ' || v_num_linea || ', ''SP'',' || v_sw_datos_error || ', ' || v_datos || ')';

            v_respuesta := ' v_dml: ' || v_dml;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 6);

            -- Ejecutamos el DML        
            v_cursor := dbms_sql.open_cursor;
            dbms_sql.parse(v_cursor, v_dml, dbms_sql.native);
            v_row := dbms_sql.execute(v_cursor);
            dbms_sql.close_cursor(v_cursor);

            -- Actualizamos los contadores de registros Exitosos y Erróneos
            if v_sw_datos_error = 0 then
              v_rgstros_extsos := v_rgstros_extsos + 1;
            else
              v_rgstros_error := v_rgstros_error + 1;
            end if;
          end if;

          -- **************************************************************

          -- limpiamos la variable que alberga cada registro
          v_line := null;
                   -- v_vector.delete;

          /*if mod(v_num_linea, 300) = 0 then
            -- Salvamos
            commit;
          end if;*/

        exception
          when others then
            -- Aseguramos el cierre del cursor en presencia de Error DML
            if dbms_sql.is_open(v_cursor) then
              dbms_sql.close_cursor(v_cursor);
            end if;

            -- Registramos el Error
                        v_respuesta :=  'Error en Linea # ' || v_num_linea || '. DML: ' || v_dml || '  Error: ' || sqlerrm;
            v_sw_datos_error := v_sw_datos_error + 1;
            v_rgstros_error := v_rgstros_error + 1;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, v_respuesta, 3);

                       insert into et_g_procesos_carga_error (id_prcso_crga, orgen, nmero_lnea, vldcion_error) 
                            values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, v_respuesta);
        end;

      end loop;

    else
      -- No se hallo proceso de carga p_id_prcso_crga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, 'No se hallo del proceso de carga:' || p_id_prcso_crga, 1);
      null;
    end if;
    close c1;

    -- Traza 
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, 'Fin prc_carga_intermedia. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

  exception 
    when no_data_found then
      -- Actualizamos Trazas / Críticas del Proceso de Carga INTERMEDIA
      insert into et_g_procesos_carga_traza (id_prcso_crga, orgen, rgstros_prcsdos, rgstros_extsos, rgstros_error, fcha_incio, fcha_fin)
      values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, v_rgstros_extsos, v_rgstros_error, v_fcha_incio, systimestamp);

            -- Actualizamos Estado de Proceso
            update et_g_procesos_carga set cdgo_prcso_estdo = 'CI' where id_prcso_crga = p_id_prcso_crga;

      -- Cerramos el Archivo
      utl_file.fclose(v_archivo);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_intermedia_from_dir',  v_nl, 'Cierre del Archivo de Carga' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 5);

  end;


  procedure prc_carga_gestion (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number) as

    cursor c1 is
      select a.*
        from v_et_g_procesos_carga a
       where id_prcso_crga = p_id_prcso_crga;

    v_ddl               varchar2(4000);
    p_columnas_origen   varchar2(4000);
    p_columnas_destino  varchar2(4000);
    p_columnas_value  varchar2(4000);
    v_id_crga           number;
    v_cursor          number;
    v_row         number;

    v_nl                number;
    v_cont_error    number;
    v_respuesta     varchar2(4000);
    v_c1        c1%rowtype;
    v_fcha_incio_prcso timestamp;



  begin

        v_error_crga_gstion := 0;
        v_crga_gstion := 0;

    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion');
    -- Traza
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, 'Incia prc_carga_gestion. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

    v_fcha_incio_prcso := systimestamp; 

        open c1;
    fetch c1 into v_c1;
    if c1%found then
      -- Se hallo el proceso de carga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, 'Hallado proceso de cargar: ' || p_id_prcso_crga, 3);

      -- obtenemos las tablas de destino que estan parametrizadas en las reglas del proceso de gestión de carga
      for a in (select /*+ RESULT_CACHE */ nmbre_tbla_dstno,
               min(nmro_orden) nmro_orden 
            from et_g_reglas_gestion m  
             where m.id_crga = v_c1.id_crga  
          group by nmbre_tbla_dstno 
          order by nmro_orden) loop

        -- Obtenemos las columnas Origen y Destino de cada una de las tablas de las tablas origen
        prc_get_columnas(a.nmbre_tbla_dstno, v_c1.id_crga  , p_columnas_origen, p_columnas_destino, p_columnas_value);

        -- Se crea el ddl para insertar los datos en las tablas de gestion 
        v_ddl := 'declare 

              cursor c1 is 
                          select /*+ RESULT_CACHE */ nmero_lnea, id_prcso_intrmdia, ' || p_columnas_origen || '
                from et_g_procesos_intermedia r1
               where id_prcso_crga = ' || p_id_prcso_crga || '
                 and indcdor_error_in = 0
                 and indcdor_prcsdo = 0
               for update of indcdor_prcsdo;



               v_count number;
               v_error number;
               v_respuesta varchar2(2000);

               begin
                for R1 in C1 loop
                  begin
                    insert into ' ||  a.nmbre_tbla_dstno || ' ( id_prcso_crga, id_prcso_intrmdia , nmero_lnea, ' || p_columnas_destino || ')
                       values ( ' || p_id_prcso_crga || ', r1.id_prcso_intrmdia , r1.nmero_lnea , ' || p_columnas_value ||');
                    update et_g_procesos_intermedia set indcdor_prcsdo = 1 where current of C1;
                    pk_etl.v_crga_gstion :=  pk_etl.v_crga_gstion + 1;
                  exception
                    when others then
                      v_respuesta :=  '' Error en registro de la linea: '' || r1.nmero_lnea || ''  Error: '' || sqlerrm;
                      pkg_sg_log.prc_rg_log( 1, 1, ''pk_etl.prc_carga_gestion'',  6 , v_respuesta, 1);
                      pk_etl.v_error_crga_gstion :=  pk_etl.v_error_crga_gstion + 1;
                      insert into et_g_procesos_carga_error (id_prcso_crga, orgen, nmero_lnea, vldcion_error) 
                                                     values (' || p_id_prcso_crga || ', ''GESTION'', r1.nmero_lnea, v_respuesta);
                  end;
                end loop;
              end;';

        -- Ejecutamos el comando DDL
        begin

          v_cursor := dbms_sql.open_cursor;
          dbms_sql.parse(v_cursor, v_ddl, dbms_sql.native);
          v_row := dbms_sql.execute(v_cursor);
          dbms_sql.close_cursor(v_cursor);

          v_respuesta :=  'Se insertaron: ' || pk_etl.v_crga_gstion || ' Registro(s), ' || v_error_crga_gstion || ' Registro(s) no Cargaron';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, v_respuesta, 1);

          -- Traza de Procesos Carga de Gestión
          insert into et_g_procesos_carga_traza (id_prcso_crga, orgen, rgstros_prcsdos, rgstros_extsos, rgstros_error, fcha_incio, fcha_fin)
                                         values (p_id_prcso_crga, 'GESTION', v_crga_gstion + v_error_crga_gstion, v_crga_gstion, v_error_crga_gstion, v_fcha_incio_prcso,systimestamp );

                    -- Actualizamos Estado de Proceso
                    update et_g_procesos_carga set cdgo_prcso_estdo = 'FI' where id_prcso_crga = p_id_prcso_crga;

          pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, 'v_ddl =  ' || v_ddl, 6);

        exception
          when others then
          -- Aseguramos el cierre del cursor en presencia de Error DML
          if dbms_sql.is_open(v_cursor) then
            dbms_sql.close_cursor(v_cursor);
          end if;

          v_respuesta :=  'Error DML: ' || v_ddl || '  Error: ' || sqlerrm;
          v_cont_error := v_cont_error + 1;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, v_respuesta, 1);
        end;

      end loop;  -- Fin For a :  tablas destino
    else
      -- No se hallo proceso de carga p_id_prcso_crga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, 'No se hallo del proceso de carga:' || p_id_prcso_crga, 1);
      null;
    end if; 
    close c1;

        --Procesamiento de Archivo Resolucion Igac
        declare
            v_cdgo_rspsta  number;
            v_mnsje_rspsta varchar2(32767);
        begin
            --Registro de Resolucion Igac
            begin
                pkg_si_resolucion_predio.prc_rg_resolucion_etl( p_cdgo_clnte    => p_cdgo_clnte
                                                              , p_id_prcso_crga => p_id_prcso_crga
                                                              , o_cdgo_rspsta   => v_cdgo_rspsta
                                                              , o_mnsje_rspsta  => v_mnsje_rspsta );
            exception
                 when others then 
                      raise_application_error( -20001 , 'No fue posible registrar la resolucion.' || sqlerrm );
            end;

            --Verifica si hay Error                                              
            if( v_cdgo_rspsta <> 0 ) then 
                 raise_application_error( -20001 , v_mnsje_rspsta );
            end if;
        end;

    pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, 'pk_etl.prc_carga_gestion',  v_nl, 'Fin pk_etl.prc_carga_gestion. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

  end;


  procedure prc_get_columnas(p_nmbre_tbla_dstno         varchar2,
                               p_id_crga                    number,
                               p_columnas_origen        out varchar2, 
                               p_columnas_destino       out varchar2, 
                               p_columnas_value         out varchar2) as

  cursor c1 (v_clmna_orgen in et_d_reglas_transformacion.clmna_orgen%type) is 
  select * 
    from v_et_d_reglas_transformacion 
   where id_crga = p_id_crga 
     and clmna_orgen = v_clmna_orgen;


  v_nl                number;
  v_respuesta     varchar2(4000);
  v_c1        c1%rowtype;    

  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, 1, 'pk_etl.prc_get_columnas');
    -- Traza
    pkg_sg_log.prc_rg_log( 1, 1, 'pk_etl.prc_get_columnas',  v_nl, 'Incia prc_get_columnas. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

    -- Recorremos las columnas a Migrar de la entidad
    for a in (
                      --Incluido por Nelson Ardila - Funcionalidad que permite convertir a timestamp
                      select clmna_orgen
                           , ( case when cdgo_dto_tpo = 'F' then 
                                     'to_timestamp( ' || clmna_orgen_vlue || ' , ' || chr(39)  || frmto ||  chr(39) || ')'
                                    when cdgo_dto_tpo = 'N' then
                                     'to_number( ' || clmna_orgen_vlue || ')'
                                    else
                                      clmna_orgen_vlue
                               end ) as clmna_orgen_vlue
                           , nmbre_clmna_dstno
                        from (
                                      select case when tpo_orgen = 'FIJO'  then
                                                   chr(39) || vlor_fjo || chr(39) || ' ' || nmbre_clmna_dstno
                                              when tpo_orgen = 'COLUMNA' then
                                                    'R1.' || clmna_orgen
                                            end as clmna_orgen, 
                                         case when tpo_orgen = 'FIJO'  then
                                                   chr(39) || vlor_fjo || chr(39)
                                              when tpo_orgen = 'COLUMNA' then
                                                   'R1.' || clmna_orgen
                                            end as clmna_orgen_vlue,
                                            nmbre_clmna_dstno,
                                            tpo_orgen,
                                            frmto,
                                            cdgo_dto_tpo
                                       from et_g_reglas_gestion 
                                      where nmbre_tbla_dstno = p_nmbre_tbla_dstno
                                        and id_crga = p_id_crga
                                   order by nmro_orden 
                             )) loop

        if c1 %isopen then
          close c1 ;
        end if;

        open c1(a.clmna_orgen);
        fetch c1 into v_c1;
        if c1%found then
          p_columnas_origen := p_columnas_origen || 'case when ' ||  v_c1.clmna_orgen || ' ' || v_c1.dscrpcion_oprdor_tpo || ' then '|| v_c1.vlor_trnsfrmdo || 'end as '  || v_c1.clmna_orgen;
        else
          p_columnas_origen  := p_columnas_origen || a.clmna_orgen || ', ';
        end if;     

        p_columnas_destino := p_columnas_destino || a.nmbre_clmna_dstno || ', ';
        p_columnas_value := p_columnas_value || a.clmna_orgen_vlue || ', ';
    end loop;   -- Fin For a :  Columnas oriden y destinos 

    if length(p_columnas_origen) > 0 then
      -- Eliminamos el último carcater (, )
      p_columnas_origen  := substr(p_columnas_origen, 1, length(p_columnas_origen)-2);
      p_columnas_destino := substr(p_columnas_destino, 1, length(p_columnas_destino)-2);
      p_columnas_value := substr(p_columnas_value, 1, length(p_columnas_value)-2);


      v_respuesta := 'p_columnas_origen --> ' || p_columnas_origen || ' p_columnas_destino ' || p_columnas_destino || ' p_columnas_value ' || p_columnas_value;  
      pkg_sg_log.prc_rg_log( 1, 1, 'pk_etl.prc_get_columnas',  v_nl, v_respuesta, 1);
    end if;
    close c1;

    pkg_sg_log.prc_rg_log( 1, 1, 'pk_etl.prc_get_columnas',  v_nl, 'Fin pk_etl.prc_get_columnas. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

  end;

  procedure prc_carga_archivo_directorio (p_file_blob in blob, p_file_name in varchar2) as

     l_blob_length     integer;
     l_out_file        utl_file.file_type;
     l_buffer          raw (32767);
     l_chunk_size      binary_integer := 32767;
     l_blob_position   integer := 1;
     l_drctrio     df_s_definiciones.vlor%type;

  begin

    select vlor
      into l_drctrio 
    from df_s_definiciones 
    where cdgo_dfncion = 'DIR_ETL';

    -- retrieve the size of the blob
    l_blob_length := dbms_lob.getlength (p_file_blob);

    -- open a handle to the location where you are going to write the blob 
    -- to file.
    -- note: the 'wb' parameter means "write in byte mode" and is only
    --       available in the utl_file package with oracle 10g or later
    l_out_file :=
      utl_file.fopen (
         l_drctrio
        ,p_file_name
        ,'wb' -- important. if ony w then extra carriage return/line brake
        ,l_chunk_size
      );

    -- write the blob to file in chunks
    while l_blob_position <= l_blob_length
    loop
      if l_blob_position + l_chunk_size - 1 > l_blob_length
      then
        l_chunk_size := l_blob_length - l_blob_position + 1;
      end if;

      dbms_lob.read (
        p_file_blob, 
        l_chunk_size,
        l_blob_position,
        l_buffer
      );
      utl_file.put_raw (l_out_file, l_buffer, true);
      l_blob_position := l_blob_position + l_chunk_size;
    end loop;

    -- close the file handle
    utl_file.fclose (l_out_file);
  end prc_carga_archivo_directorio;
    
    procedure prc_carga_intermedia_from_db (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number) as
  
    cursor c1 is
    select a.*
    from v_et_g_procesos_carga a
    where id_prcso_crga = p_id_prcso_crga;

    v_c1 c1%rowtype;
    v_nl number;

    v_line        varchar2 (32767) := null;
    v_rows        number;
    v_si_no       number := 1;

    v_num_linea     number(8) := 0;
    v_columnas      varchar2(4000);
    v_datos       varchar2(4000);
    v_dato        varchar2(4000);
    v_dml       varchar2(4000);
    pos_ini       number;
    v_respuesta     varchar2(2000);
    v_cont_error    number;
    v_ddl_validacion  varchar2(4000);
    v_validacion    varchar2(500);
        v_nmbre_up          varchar2(50) := 'PK_ETL.PRC_CARGA_INTERMEDIA_FROM_DB';
    v_fcha_incio    timestamp;
    v_sw_datos_error  number;
    v_rgstros_extsos  number;
    v_rgstros_error   number;
        
        v_clob              clob;
        v_inicial           number;
        v_actual            number;
        v_final             number;
        v_linea             varchar2(32767);
        v_sqlerrm           varchar2(1000);

    v_cdgo_estdo_lnea et_g_procesos_intermedia.cdgo_estdo_lnea%type;
    TYPE typ_texto_varray IS varray(1000000000) of varchar2(1000);
    v_vector      typ_texto_varray := typ_texto_varray(null);
    v_cont        number;
    v_cursor      number;
    v_row       number;

    v_archivo utl_file.file_type;
    --v_linea varchar2(1024);
        
        v_dest_offset  INTEGER;
        v_src_offset   INTEGER; 
        v_lang_context INTEGER;
        v_warning      INTEGER;
        
        v_cant_caracteres   number;
        v_crcter_espcial    number;
  begin
        
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up );
        
        --insert into muerto(v_001, v_002) VALUES ('p_cdgo_clnte', p_cdgo_clnte); commit;
        --insert into muerto(v_001, v_002) VALUES ('p_id_impsto', p_id_impsto); commit;
        --insert into muerto(v_001, v_002) VALUES ('v_nmbre_up', v_nmbre_up); commit;
        --insert into muerto(v_001, v_002) VALUES ('v_nl', v_nl); commit;
        
    -- Traza
    v_fcha_incio  := systimestamp;
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Incia prc_carga_intermedia. Espectante ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

    -- Abrimos el cursor que trae el proceso de carga
    open c1;
    fetch c1 into v_c1;
    if c1%found then

            --Incluido por Nelson Ardila - Funcionalidad que permite el cargue del XLS o XLSX
            --Nota: Este Proceso Trabaja con las Colecciones de Apex - Datos de la Sesion 
            if v_c1.cdgo_archvo_tpo = 'EX'  then  
                --insert into muerto(v_001, v_002) VALUES ('cdgo_archvo_tpo', v_c1.cdgo_archvo_tpo); commit;
                 declare
                    v_cndcion           varchar2(500); 
                    v_clmna_vlda        boolean;
                    v_collection_name   varchar2(50) := 'ETLEXC';
                 begin

                    --Inicializa las Variables Acumuladoras
                    v_rgstros_error  := 0;
                    v_rgstros_extsos := 0;
                    v_num_linea      := v_c1.lneas_encbzdo;

                    -- Determinamos el nivel del Log de la UPv
                    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );

                    if( apex_collection.collection_member_count( p_collection_name => v_collection_name ) > 0 ) then

                        for c_dtos in (
                                           select seq_id 
                                             from apex_collections
                                            where collection_name = v_collection_name
                                              and seq_id > v_c1.lneas_encbzdo
                                         order by seq_id
                                      ) loop

                            --Indica el Numero de Linea del Archivo
                            v_num_linea      := ( v_num_linea + 1 );

                            --Limpia las Variables
                            v_datos          := '';
                            v_columnas       := '';
                            v_sw_datos_error := 0; 
                            v_dml            := '';

                            --Cursor de Columnas de la Fila
                            for c_clmnas in (
                                                 select a.nmbre_clmna
                                                      , b.vlor
                                                      , ( select m.oprdor from df_s_operadores_tipo m where m.id_oprdor_tpo = a.id_oprdor_tpo ) as oprdor 
                                                      , a.vlor1
                                                      , a.vlor2
                                                      , a.indcdor_vlda
                                                      , a.cdgo_dto_tpo
                                                      , decode( a.cdgo_dto_tpo , 'C' , 'varchar2' , 'N' , 'number' , 'F' , 'date' , 'varchar2' ) as tpo_clmna
                                                   from et_d_reglas_intermedia a
                                              left join (
                                                             select seq_id
                                                                  , c001 , c002 , c003 , c004 , c005 , c006 , c007 , c008 , c009 , c010
                                                                  , c011 , c012 , c013 , c014 , c015 , c016 , c017 , c018 , c019 , c020
                                                                  , c021 , c022 , c023 , c024 , c025 , c026 , c027 , c028 , c029 , c030 
                                                                  , c031 , c032 , c033 , c034 , c035 , c036 , c037 , c038 , c039 , c040
                                                                  , c041 , c042 , c043 , c044 , c045 , c046 , c047 , c048 , c049
                                                                  , c050
                                                               from apex_collections
                                                              where collection_name = v_collection_name
                                                                and seq_id          = c_dtos.seq_id
                                                        )
                                                 unpivot (
                                                            vlor
                                                            for clmna in ( c001 , c002 , c003 , c004 , c005 , c006 , c007 , c008 , c009 , c010
                                                                         , c011 , c012 , c013 , c014 , c015 , c016 , c017 , c018 , c019 , c020
                                                                         , c021 , c022 , c023 , c024 , c025 , c026 , c027 , c028 , c029 , c030 
                                                                         , c031 , c032 , c033 , c034 , c035 , c036 , c037 , c038 , c039 , c040
                                                                         , c041 , c042 , c043 , c044 , c045 , c046 , c047 , c048 , c049
                                                                         , c050 ) 
                                                         ) b
                                                        on 'C' || lpad( replace( a.nmbre_clmna , 'CLUMNA' ) , 3 , 0 ) = b.clmna
                                                     where a.id_crga = v_c1.id_crga
                                                  order by to_number( substr( a.nmbre_clmna , 7 ))
                                            ) loop

                                --Asigna el Tipo de Formato del Valor
                                c_clmnas.vlor := pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                            , p_valor => c_clmnas.vlor );

                                if( c_clmnas.indcdor_vlda = 'S' ) then
                                    --Constructor de Condiciones
                                    v_cndcion := c_clmnas.vlor || ' '  
                                                               || ( case when c_clmnas.oprdor = 'LIKE'    then
                                                                          'like ' || chr(39) || '%' || c_clmnas.vlor1 || '%' || chr(39) 
                                                                         when c_clmnas.oprdor = 'LIKE I'  then
                                                                          'like ' || chr(39) || c_clmnas.vlor1 || '%' || chr(39) 
                                                                         when c_clmnas.oprdor = 'LIKE T'  then
                                                                          'like ' || chr(39) || '%' || c_clmnas.vlor1 || chr(39) 
                                                                         else
                                                                          c_clmnas.oprdor || ( case when c_clmnas.oprdor in ( 'IN' , 'NOT IN' ) then
                                                                                                     ' ( ' || c_clmnas.vlor1 || ')'
                                                                                                    when c_clmnas.oprdor not in ( 'IS NULL' , 'IS NOT NULL' ) then
                                                                                                     ' (' || pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                                                                                        , p_valor => c_clmnas.vlor1 ) || ')'
                                                                                                end )
                                                                    end ) || ( case when c_clmnas.oprdor = 'BETWEEN' then
                                                                                  ' and ' || pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_clmnas.tpo_clmna
                                                                                                                                        , p_valor => c_clmnas.vlor2 )
                                                                                end );

                                    --Valida la Condición
                                    begin
                                       execute immediate 'begin :result := ' || v_cndcion || '; end;'
                                         using out v_clmna_vlda; 
                                    exception
                                         when others then
                                              v_sw_datos_error := 1;
                                              --Contadora de Registro con Error
                                              v_rgstros_error  := v_rgstros_error + 1;

                                              --Registra el Error
                                              insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                                   values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , c_clmnas.nmbre_clmna , v_cndcion );

                                              v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion ||  ' Error: ' || sqlerrm;
                                              pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                              exit;
                                    end;

                                    --Verifica si la Condición es Valida
                                    if( not v_clmna_vlda ) then
                                        v_sw_datos_error := 1;
                                        --Contadora de Registro con Error
                                        v_rgstros_error  := v_rgstros_error + 1;

                                        --Registra el Error
                                        insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                             values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , c_clmnas.nmbre_clmna , v_cndcion );

                                        v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                        exit;
                                    end if;

                                end if;

                                v_datos    := v_datos || ' , ' || c_clmnas.vlor;
                                v_columnas := v_columnas || ' , ' || c_clmnas.nmbre_clmna;

                            end loop;

                            if( v_sw_datos_error = 0 ) then
                                --Construccion del comando DML de Proceso Intermedia
                                v_dml := 'insert into et_g_procesos_intermedia (id_prcso_crga, nmero_lnea, cdgo_estdo_lnea, indcdor_error_in ';
                                v_dml := v_dml || v_columnas || ') values (';
                                v_dml := v_dml || p_id_prcso_crga || ', ' || v_num_linea || ', ''SP'',' || v_sw_datos_error || v_datos || ')';

                                --Ejecuta la el Comando (DML)
                                begin
                                    execute immediate v_dml;

                                    --Contadora de Registro con Exito
                                    v_rgstros_extsos := v_rgstros_extsos + 1;
                                    --Registra Log de los DML
                                    v_respuesta := 'v_dml: ' || v_dml;
                                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up , v_nl , v_respuesta , 6 );
                                exception
                                     when others then
                                          --Contadora de Registro con Error
                                          v_rgstros_error  := v_rgstros_error + 1;

                                          v_respuesta := 'Linea # ' || v_num_linea || ' DML ' || v_dml ||  ' Error: ' || sqlerrm; 

                                          --Registra el Error
                                          insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , clmna_orgen , vldcion_error ) 
                                               values ( p_id_prcso_crga , 'INTERMEDIA' , v_num_linea , 'DML' , v_respuesta );

                                          v_respuesta :=  'Linea # ' || v_num_linea || '  Registro No Valido: ' || v_cndcion ||  ' Error: ' || sqlerrm;
                                          pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up , v_nl , v_respuesta , 4 );
                                end;                         
                            end if;
                        end loop;

                        --Limpia la coleccion 
                        apex_collection.delete_collection ( p_collection_name => v_collection_name );

                        --Inserta la Traza de la Carga
                        insert into et_g_procesos_carga_traza ( id_prcso_crga , orgen , rgstros_prcsdos , rgstros_extsos 
                                                              , rgstros_error , fcha_incio, fcha_fin )
                                                       values ( p_id_prcso_crga , 'INTERMEDIA', v_num_linea , v_rgstros_extsos 
                                                              , v_rgstros_error , v_fcha_incio , systimestamp);

                        --Actualiza el estado del Proceso Carga
                        update et_g_procesos_carga 
                           set cdgo_prcso_estdo = 'CI'
                         where id_prcso_crga    = p_id_prcso_crga;

                    end if;
                 end;
               --Exit UP           
               return;
            end if;

      -- Se hallo el proceso de carga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Hallado proceso de cargar: ' || p_id_prcso_crga, 5);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Tamaño Blob: ' || dbms_lob.getlength(v_c1.file_blob), 5);

      -- Determinamos si Existe el Archivo

      -- Abrimos el Archivo
      --v_archivo := utl_file.fopen ('ETL_CARGA', v_c1.file_name, 'r');
            --v_clob := pkg_gn_generalidades.fnc_cl_convertir_blob_a_clob(v_c1.file_blob);
            
            v_dest_offset  := 1;
            v_src_offset   := 1; 
            v_lang_context := dbms_lob.default_lang_ctx;
            
            dbms_lob.createtemporary(v_clob, true);
            
            DBMS_LOB.CONVERTTOCLOB(
                       dest_lob       =>    v_clob,                 --IN OUT NOCOPY  CLOB CHARACTER SET ANY_CS,
                       src_blob       =>    v_c1.file_blob,         --             BLOB,
                       amount         =>    dbms_lob.lobmaxsize,    --IN             INTEGER,
                       dest_offset    =>    v_dest_offset,          --IN OUT         INTEGER,
                       src_offset     =>    v_src_offset,           --IN OUT         INTEGER, 
                       blob_csid      =>    dbms_lob.default_csid,  --IN             NUMBER,
                       lang_context   =>    v_lang_context,         --IN OUT         INTEGER,
                       warning        =>    v_warning);             --OUT            INTEGER);
            
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Conversion: ' || v_warning, 5);
            
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, v_clob, 5);

      -- Iniciamos los contadores de registros exitosos y erróneos
      v_rgstros_extsos  := 0;
      v_rgstros_error   := 0;
            --insert into muerto(v_001, v_002, c_001) VALUES ('Antes del While', v_c1.cdgo_archvo_tpo, v_clob); commit;
            
            v_respuesta := ' Tipo de archivo ' || v_c1.cdgo_archvo_tpo;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_respuesta, 5);
                            
      -- Recorremos el archivo 
            v_inicial   := 1;
            v_actual    := 1;
            --v_final     := UTL_RAW.length( v_c1.file_blob );
            v_final     := dbms_lob.getlength(v_clob);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_final: ' || v_final , 5);
            
            while v_actual <= v_final
      loop
                
                -- Si es fin de Linea
                -- Procesamos la Linea
                if ascii( substr(v_clob, v_actual, 1) ) = 13 or ascii( substr(v_clob, v_actual, 1) ) = 10 then   -- Enter o Retorno de linea
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_num_linea INI: ' || v_num_linea , 6); 
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_crcter_espcial INICIAL: ' || v_crcter_espcial , 6);
                    
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Ascci Actual: ' || ascii( substr(v_clob, v_actual, 1) ) || '  Carac Actul: ' || substr(v_clob, v_actual, 1)  || ' Pos Actual: ' || v_actual, 6);
                    
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, 'ENTER en CARACTER: ' || v_actual , 6);
                    
                    v_cant_caracteres := v_actual - v_inicial;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_inicial: ' || v_inicial || ' v_actual-v_inicial: ' || v_cant_caracteres , 6);
                                        
                    v_linea := trim(substr(v_clob, v_inicial, v_actual - v_inicial)) ;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_linea : ' || v_linea , 6);
                    
                    ------
                    ------v_linea := trim(substr(v_clob, v_inicial, v_actual - v_inicial)) ;
                    if ( ascii( substr(v_clob, v_actual, 1) ) = 13 ) then
                        v_linea := substr( replace( v_linea, chr(13), '' ), 1, length(v_linea) );
                       -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_linea 13: ' || v_linea , 6);
                        v_crcter_espcial := v_crcter_espcial + 1;
                    end if;
                    
                    if ( ascii( substr(v_clob, v_actual+1, 1) ) = 10 ) then
                        v_linea := substr( replace( v_linea, chr(10), '' ), 1, length(v_linea) );
                        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_linea 10: ' || v_linea , 6);
                        v_crcter_espcial := v_crcter_espcial + 1;
                    end if;
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_crcter_espcial: ' || v_crcter_espcial , 6);
                    v_inicial := v_actual + v_crcter_espcial;  
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_inicial: ' || v_inicial , 6);                   
                    
                    
                    --------
                    /***
                    --v_linea := substr( replace( v_linea, chr(13), '' ), 1, length(v_linea) );
                    v_linea := substr( v_linea,1, length(v_linea)-1 );
                    
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'LINEA : ' || v_linea , 6);
                    dbms_output.put_line( v_linea );
                    
                    
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Ascci Siguiente: ' || ascii( substr(v_clob, v_actual+1, 1) ) || '  Carac Siguiente: ' || substr(v_clob, v_actual+1, 1)   || ' Pos Siguiente: ' || (v_actual+1), 6);

                    -- Actualizamos el Inicial incrementado 1 , por el caracter 13 o 10, encontrado
                    v_inicial := v_actual + 1;
                    
                    if ascii( substr(v_clob, v_actual+1, 1) ) = 13 or ascii( substr(v_clob, v_actual+1, 1) ) = 10 then -- Enter o Retorno de linea  
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ENCONTRAMOS OTRO 13 ó 10 : ' || v_linea , 6); 
                        -- Al incial actualizado ... le adicionamos 1, dado que encontramos otro Caracter Especial
                        -- otro caracter especial Ascii(10)  o  Ascii(13)
                        v_linea := substr( v_linea,1, length(v_linea)-1 );
                        v_inicial := v_inicial + 1; 
                    end if;
                    ***/
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 
                                            'Ascci Inicial prox. linea: ' || ascii( substr(v_clob, v_inicial, 1) ) || 
                                            ' - Carac Inicial prox. linea: ' || substr(v_clob, v_inicial, 1)   || 
                                            ' - Pos Inicial prox. linea: ' || v_inicial, 6);                    
                    
                    v_line := v_linea;
                    --utl_file.get_line (v_archivo, v_line);
        
                    begin
                        v_num_linea := v_num_linea +1;                        
                        v_columnas := '';
                        v_datos := '';
    
                        -- Se valida si la v_num_linea corresponde a las lineas es de encabezado
                        if v_c1.lneas_encbzdo < v_num_linea then 
    
                            -- Asumimos que la validación del Registro es exitosa
                            v_sw_datos_error := 0;
    
                            -- **************************************************************
                            -- Procesamos la linea dependiendo del tipo de archivo
                            -- **************************************************************
                            
    
                            if v_c1.cdgo_archvo_tpo = 'AF'  then
                                -- Si es ancho fijo
                                for i  in ( select  a.*, 
                                                    (select m.oprdor from df_s_operadores_tipo m where m.id_oprdor_tpo = a.id_oprdor_tpo) oprdor
                                            from et_d_reglas_intermedia a
                                            where id_crga = v_c1.id_crga 
                                            order by to_number(substr(nmbre_clmna,7)) ) loop
    
                                    -- Extraemos Datos.  Recorremos las columnas de reglas por CARCATERES DE INICIO y FIN
                                    v_columnas  := v_columnas || i.nmbre_clmna || ', ';
                                    --v_dato := replace( substr(v_line, i.crcter_incial, i.crcter_fnal - i.crcter_incial + 1) , chr(39), chr(49844)) ;
                                    v_dato := substr(v_line, i.crcter_incial, i.crcter_fnal - i.crcter_incial + 1) ;
                                    v_datos := v_datos || '''' || v_dato || ''', ';
                                    
                                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, 'i.crcter_incial: ' || i.crcter_incial || ' i.crcter_fnal: ' || i.crcter_fnal, 5);
                                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, 'Columna: ' || i.nmbre_clmna || ' Dato: ' || v_dato || ' Valida: ' || i.indcdor_vlda, 5);
                                    
                                    
                                    -- Validamos Contenidos (Datos)
                                    if i.indcdor_vlda = 'S' then
                                        --v_ddl_validacion := 'Select 1 from dual where ''' ||  v_datos || ''' ' || i.oprdor || ' ';
                                        v_ddl_validacion := 'Select 1 a from dual where ' ||  v_dato || ' ' || i.oprdor || ' ';
                                        if i.oprdor in  ('=', '>=', '<=', '>', '<', '<>') then
                                            v_validacion := i.vlor1;
                                        elsif i.oprdor in ('IN', 'NOT IN') then
                                            v_validacion := '(' || i.vlor1 || ')';
                                        elsif i.oprdor in ('BETWEEN') then
                                            v_validacion := i.vlor1 || ' and ' || i.vlor2;
                                        end if;
                                        v_ddl_validacion := v_ddl_validacion || v_validacion;
    
                                        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, 'VALIDAMOS COLUMNA: ' || i.nmbre_clmna, 5);                              
                                        
                                        -- Ejecutamos Validación
                                        v_cursor := dbms_sql.open_cursor;
    
                                        v_respuesta :=  'Linea # ' || v_num_linea || '  v_ddl_validacion: ' || v_ddl_validacion;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_respuesta, 6);
    
                                        dbms_sql.parse(v_cursor, v_ddl_validacion, dbms_sql.native);
                                        v_row := dbms_sql.execute(v_cursor);
                                        if dbms_sql.fetch_rows(v_cursor) = 0 then
                                            -- Validación del Dato No Paso
                                            v_sw_datos_error := 1;
    
                                            -- Registramos el Error
                                            insert into et_g_procesos_carga_error (id_prcso_crga, orgen, nmero_lnea, clmna_orgen, vldcion_error) 
                                            values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, i.nmbre_clmna, v_dato || ' ' || i.oprdor || v_validacion);
    
                                            -- Generar LOG -Para critica-
                                            v_respuesta :=  'Linea # ' || v_num_linea || '  Validacion Columna : ' || i.nmbre_clmna || 'No Valida. Dato: ' || v_dato || ' ' || i.oprdor || ' ' || v_validacion;
                                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_respuesta, 6);
                                        else
                                            v_respuesta :=  'Linea # ' || v_num_linea || '  Validacion Columna : ' || i.nmbre_clmna || 'Valida.';
                                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, v_respuesta, 6);
                                        end if;
                                        dbms_sql.close_cursor(v_cursor);
    
                                        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto, v_nmbre_up,  v_nl, 'FIN VALIDCION COLUMNA: ' || i.nmbre_clmna, 5);
                                    end if;
                                end loop;
                                --null;
                            elsif v_c1.cdgo_archvo_tpo = 'DC'  then
                                -- Si es Caracter Delimitador
    
                                -- Poblamos el Vector
                                v_cont := 0;
                                pos_ini := 1;
    
    
                                while (pos_ini < length(v_line)) loop    
                                    v_cont := v_cont + 1;
                                    v_vector.extend ;
    
                                    if instr( v_line, v_c1.crcter_dlmtdo, pos_ini) > 0 then
                                        v_vector(v_cont) := substr(  v_line, pos_ini, instr( v_line, v_c1.crcter_dlmtdo, pos_ini) - pos_ini );  
                                        pos_ini := instr( v_line, v_c1.crcter_dlmtdo, pos_ini) + 1;
    
                                    else
                                        v_vector(v_cont) := substr(  v_line, pos_ini, length(v_line)+2 - pos_ini );
                                         pos_ini :=  length(v_line);
                                    end if;
                                    --pos_ini := instr( v_line, v_c1.crcter_dlmtdo, pos_ini) + 1;
    
                                end loop;
    
                                -- Recorremos las columnas de reglas por POSICION
                                for i  in (select * from et_d_reglas_intermedia where id_crga = v_c1.id_crga order by pscion) loop
                                    -- Recorremos las columnas de reglas
                                    v_columnas  := v_columnas || i.nmbre_clmna || ', ';
                                    v_vector(i.pscion) := replace(v_vector(i.pscion) , chr(39), chr(49844)) ;
                                    v_vector(i.pscion) := substr(v_vector(i.pscion),0,i.tmno) ;
                                    v_datos := v_datos || '''' || v_vector(i.pscion)  || ''', ';
    
                                    -- Validamos el Contenidos (Datos)
                                end loop;
                                --null;
                            end if;
    
                        else 
                            -- La linea corresponde al encabezado del archivo
                            v_respuesta := ' Linea #  ' || v_num_linea || ' es del encabezado';
                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto,  v_nmbre_up,  v_nl, v_respuesta, 6);
    
                        end if;
    
                        v_respuesta :=  'Linea # ' || v_num_linea ||' v_sw_datos_error: ' || v_sw_datos_error || ' Columnas: ' || v_columnas || ' Datos: ' || v_datos;
                        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto,  v_nmbre_up,  v_nl, v_respuesta, 6);
    
                        -- Eliminamos caracteres demás  e Insertamos regsitro en tabla Intermedia
                        if length(v_columnas) > 0 then
                            -- Eliminamos el último carcater (, )
                            v_columnas  := substr(v_columnas, 1, length(v_columnas)-2);
                            v_datos  := substr(v_datos, 1, length(v_datos)-2);
    
                            -- Construimos DML
                            v_dml := 'insert into et_g_procesos_intermedia (id_prcso_crga, nmero_lnea, cdgo_estdo_lnea, indcdor_error_in, ';
                            v_dml := v_dml || v_columnas || ') values (';
                            v_dml := v_dml || p_id_prcso_crga || ', ' || v_num_linea || ', ''SP'',' || v_sw_datos_error || ', ' || v_datos || ')';
    
                            v_respuesta := 'INSERTAMOS LINEA v_dml: ' || v_dml;
                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto,  v_nmbre_up,  v_nl, v_respuesta, 6);
    
                            -- Ejecutamos el DML        
                            v_cursor := dbms_sql.open_cursor;
                            dbms_sql.parse(v_cursor, v_dml, dbms_sql.native);
                            v_row := dbms_sql.execute(v_cursor);
                            
                            v_respuesta := 'Respuesta despues de insertar v_row: ' || v_row;
                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, p_id_impsto,  v_nmbre_up,  v_nl, v_respuesta, 6);
                            
                            dbms_sql.close_cursor(v_cursor);
    
                            -- Actualizamos los contadores de registros Exitosos y Erróneos
                            if v_sw_datos_error = 0 then
                                v_rgstros_extsos := v_rgstros_extsos + 1;
                            else
                                v_rgstros_error := v_rgstros_error + 1;
                            end if;
                        end if;
    
                        -- **************************************************************
    
                        -- limpiamos la variable que alberga cada registro
                        v_line := null;
                       -- v_vector.delete;
    
                        /*if mod(v_num_linea, 300) = 0 then
                            -- Salvamos
                            commit;
                        end if;*/
    
                   exception
                        when others then
                            -- Aseguramos el cierre del cursor en presencia de Error DML
                            if dbms_sql.is_open(v_cursor) then
                                dbms_sql.close_cursor(v_cursor);
                            end if;
    
                            -- Registramos el Error
                            v_respuesta :=  'Error en Linea # ' || v_num_linea || '. DML: ' || v_dml || '  Error: ' || sqlerrm;
                            v_sw_datos_error := v_sw_datos_error + 1;
                            v_rgstros_error := v_rgstros_error + 1;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pk_etl.prc_carga_intermedia_from_db',  v_nl, v_respuesta, 3);
    
                           insert into et_g_procesos_carga_error (id_prcso_crga, orgen, nmero_lnea, vldcion_error) 
                                values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, v_respuesta);
                    end;
               
                    --
                    v_actual := v_inicial-1;
                end if;
                
                v_actual := v_actual + 1;
                v_crcter_espcial    := 0;                
                
      end loop;
            
            -- Actualizamos Trazas / Criticas del Proceso de Carga INTERMEDIA
      insert into et_g_procesos_carga_traza (id_prcso_crga, orgen, rgstros_prcsdos, rgstros_extsos, rgstros_error, fcha_incio, fcha_fin)
      values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, v_rgstros_extsos, v_rgstros_error, v_fcha_incio, systimestamp);

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'INSERTADA TRAZA DE CARGA. Lineas:' || v_num_linea || ' v_rgstros_extsos:' || v_rgstros_extsos || ' v_rgstros_error:' || v_rgstros_error, 4);
    else
      -- No se hallo proceso de carga p_id_prcso_crga
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'No se hallo del proceso de carga:' || p_id_prcso_crga, 1);
      null;
    end if;
    close c1;

    -- Traza 
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Fin prc_carga_intermedia. ' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 1);

  exception 
    when no_data_found then
      -- Actualizamos Trazas / Críticas del Proceso de Carga INTERMEDIA
      insert into et_g_procesos_carga_traza (id_prcso_crga, orgen, rgstros_prcsdos, rgstros_extsos, rgstros_error, fcha_incio, fcha_fin)
      values (p_id_prcso_crga, 'INTERMEDIA', v_num_linea, v_rgstros_extsos, v_rgstros_error, v_fcha_incio, systimestamp);

            -- Actualizamos Estado de Proceso
            update et_g_procesos_carga set cdgo_prcso_estdo = 'CI' where id_prcso_crga = p_id_prcso_crga;

      -- Cerramos el Archivo
      utl_file.fclose(v_archivo);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Cierre del Archivo de Carga' || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 5);
      when others  then 
        v_sqlerrm := sqlerrm;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Error: ' || v_sqlerrm || to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'), 5);
        raise_application_error(-20099,v_sqlerrm);
  end;

end pk_etl;

/
