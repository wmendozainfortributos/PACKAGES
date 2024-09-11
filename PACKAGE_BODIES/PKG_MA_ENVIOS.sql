--------------------------------------------------------
--  DDL for Package Body PKG_MA_ENVIOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MA_ENVIOS" as

  /*Procedimiento para la gestion de medio de envio programado*/
  procedure prc_cd_envios_programado_medio(
      p_cdgo_clnte              in  number,
      p_id_usrio                in  number,
      p_request                 in  varchar2,
      p_id_envio_prgrmdo_mdio   in  ma_g_envios_programado_mdio.id_envio_prgrmdo_mdio%type default null,
      p_id_envio_prgrmdo        in  ma_g_envios_programado_mdio.id_envio_prgrmdo%type,
      p_cdgo_envio_mdio         in  ma_g_envios_programado_mdio.cdgo_envio_mdio%type,
      p_asnto                   in  ma_g_envios_programado_mdio.asnto%type,
      p_txto_mnsje              in  ma_g_envios_programado_mdio.txto_mnsje%type,
      p_actvo                   in  ma_g_envios_programado_mdio.actvo%type              default 'S',
      o_cdgo_rspsta			    out number,
      o_mnsje_rspsta            out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;

    --Validamos el request
    case p_request
        when 'BTN_CREAR' then
        /*Insertamos en medio de envio programado*/
            begin
                insert into ma_g_envios_programado_mdio(
                    id_envio_prgrmdo_mdio,
                    id_envio_prgrmdo,
                    cdgo_envio_mdio,
                    asnto,
                    txto_mnsje,
                    actvo
                )values(
                    p_id_envio_prgrmdo_mdio,
                    p_id_envio_prgrmdo,
                    p_cdgo_envio_mdio,
                    p_asnto,
                    p_txto_mnsje,
                    p_actvo
                );
            exception
                when others then
                    o_cdgo_rspsta := 1;
                    o_mnsje_rspsta := 'Problemas al registrar medio de envio programado, '||sqlerrm;
                    raise v_error;
            end;
        when 'BTN_GUARDAR' then
        /*Actualizamos en medio de envio programado*/
            begin
                update ma_g_envios_programado_mdio
                set id_envio_prgrmdo    = p_id_envio_prgrmdo,
                    cdgo_envio_mdio     = p_cdgo_envio_mdio,
                    asnto               = p_asnto,
                    txto_mnsje          = p_txto_mnsje,
                    actvo               = p_actvo
                where id_envio_prgrmdo_mdio = p_id_envio_prgrmdo_mdio;
            exception
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta := 'Problemas al actualizar medio de envio programado, '||sqlerrm;
                    raise v_error;
            end;
        when 'BTN_ELIMINAR' then
        /*Eliminamos en medio de envio programado*/
            begin
                delete from ma_g_envios_programado_mdio where id_envio_prgrmdo_mdio = p_id_envio_prgrmdo_mdio;
            exception
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta := 'Problemas al eliminar medio de envio programado, '||sqlerrm;
                    raise v_error;
            end;
    else
       o_cdgo_rspsta := 2;
       o_mnsje_rspsta := 'Problemas al gestionar medio envio programado, request no encontrado'||sqlerrm;
       raise v_error;
    end case;
  exception
    when v_error then
        if(o_cdgo_rspsta is null)then o_cdgo_rspsta := 1;end if;
        if(o_mnsje_rspsta is null)then o_mnsje_rspsta := 'Problemas al gestionar medio de envio programado';end if;
  end prc_cd_envios_programado_medio;

  /*Procedimiento para registrar un envio*/
  procedure prc_rg_envio(
    p_cdgo_clnte                in  number,
    p_id_envio_prgrmdo          in  ma_g_envios_programado_mdio.id_envio_prgrmdo%type,
    p_fcha_rgstro               in  ma_g_envios.fcha_rgstro%type                        default systimestamp,
    p_fcha_prgrmda              in  ma_g_envios.fcha_prgrmda%type                       default systimestamp,
    p_json_prfrncia             in  ma_g_envios.json_prfrncia%type                      default null,
    p_id_sjto_impsto            in  number default null,
    p_id_acto                   in  number default null,    
    o_id_envio                  out number,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    nmbre_up                        varchar2(200) := 'pkg_ma_envios.prc_rg_envio';
  begin
    o_cdgo_rspsta := 0;
    
    --Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);
    
    insert into ma_g_envios(
        cdgo_clnte,
        id_envio_prgrmdo,
        json_prfrncia,
        fcha_rgstro,
        fcha_prgrmda,
        id_sjto_impsto,
        id_acto
    )values(
        p_cdgo_clnte,
        p_id_envio_prgrmdo,
        p_json_prfrncia,
        p_fcha_rgstro,
        p_fcha_prgrmda,
        p_id_sjto_impsto,
        p_id_acto
    )returning id_envio into o_id_envio;
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Despues del Insert - id_envio: '||o_id_envio, 6);
    
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al registrar envio, '||sqlerrm;
  end prc_rg_envio;

  /*Procedimiento para registrar un envio medio*/
  procedure prc_rg_envio_mdio(
    p_id_envio                  in ma_g_envios_medio.id_envio%type,
    p_cdgo_envio_mdio           in ma_g_envios_medio.cdgo_envio_mdio%type,
    p_dstno                     in ma_g_envios_medio.dstno%type,
    p_asnto                     in ma_g_envios_medio.asnto%type,
    p_txto_mnsje                in ma_g_envios_medio.txto_mnsje%type,
    o_id_envio_mdio             out ma_g_envios_medio.id_envio_mdio%type,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;

    insert into ma_g_envios_medio(
        id_envio,
        cdgo_envio_mdio,
        dstno,
        asnto,
        txto_mnsje
    )values(
        p_id_envio,
        p_cdgo_envio_mdio,
        p_dstno,
        p_asnto,
        p_txto_mnsje
    )returning id_envio_mdio into o_id_envio_mdio;
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al registrar medio de envio, '||sqlerrm;
  end prc_rg_envio_mdio;

  /*Procedimiento para registrar estado asociado a un envio*/
  procedure prc_rg_envio_estado(
    p_id_envio_mdio             in  ma_g_envios_mdio_trza_estdo.id_envio_mdio%type,
    p_cdgo_envio_estdo          in  ma_g_envios_mdio_trza_estdo.cdgo_envio_estdo%type,
    p_obsrvcion                 in  ma_g_envios_mdio_trza_estdo.obsrvcion%type          default null,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  ) as
  begin
    o_cdgo_rspsta := 0;
    insert into ma_g_envios_mdio_trza_estdo(
        id_envio_mdio,    
        cdgo_envio_estdo,
        obsrvcion,
        fcha_rgstro
    )values(
        p_id_envio_mdio,
        p_cdgo_envio_estdo,
        p_obsrvcion,
        systimestamp
    );
    --Actualizamos el estado del envio
    begin
        update ma_g_envios_medio
        set cdgo_envio_estdo = p_cdgo_envio_estdo
        where id_envio_mdio = p_id_envio_mdio;
    exception
        when others then
            o_cdgo_rspsta := 2;
            o_mnsje_rspsta := 'Problemas al actulizar estado, '||sqlerrm;
    end;
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al registrar estado, '||sqlerrm;
  end prc_rg_envio_estado;

  /*Procedimiento para registrar archivos adjuntos*/
  procedure prc_rg_envio_adjntos(
    p_id_envio                  in  ma_g_envios_medio.id_envio%type,
    p_file_blob                 in  ma_g_envios_adjntos.file_blob%type,
    p_file_name                 in  ma_g_envios_adjntos.file_name%type,
    p_file_mimetype             in  ma_g_envios_adjntos.file_mimetype%type,
    o_id_envio_adjnto           out ma_g_envios_adjntos.id_envio_adjnto%type,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
     o_cdgo_rspsta := 0;
     insert into ma_g_envios_adjntos(
        id_envio,
        file_blob,
        file_name,
        file_mimetype
     )values(
        p_id_envio,
        p_file_blob,
        p_file_name,
        p_file_mimetype
     ) returning id_envio_adjnto into o_id_envio_adjnto;
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al registrar archivo adjunto, '||sqlerrm;
  end prc_rg_envio_adjntos;

  /*Procedimiento para registrar un envio*/  
  procedure prc_rg_envios(
    p_id_envio_prgrmdo          in ma_g_envios_programado.id_envio_prgrmdo%type,
    p_json_prmtros              in clob   default null,
    p_id_sjto_impsto            in number default null,
    p_id_acto                   in number default null
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    nmbre_up                        varchar2(200) := 'pkg_ma_envios.prc_rg_envios';
    --
    rt_ma_g_envios_programado       ma_g_envios_programado%rowtype;     -->Envio Programado
    rt_ma_g_envios_prgrmdo_cnslta_p ma_g_envios_prgrmdo_cnslta%rowtype; -->Consulta principal
    rt_ma_g_envios_prgrmdo_cnslta_d ma_g_envios_prgrmdo_cnslta%rowtype; -->Consulta destinatarios    
    rt_ma_g_envios_prgrmdo_cnslta_a ma_g_envios_prgrmdo_cnslta%rowtype; -->Consulta adjuntos
    --
    v_sql                           clob;
    v_c_columnas                    number;
    v_dscrpcion_tbla                dbms_sql.desc_tab2;
    v_nmro_clmna                    integer;
    v_columnas_json                 clob;
    v_sql_json                      clob;
    v_sql_adjuntos                  clob;
    v_cursor                        sys_refcursor;
    
    --
    v_cdgo_rspsta                   number;
    v_mnsje_rspsta                  varchar2(3000);
    --
    v_cant_registros                number := 0;
    --
    v_id_envio                      ma_g_envios.id_envio%type;
    v_fcha_rgstro                   varchar2(60); 
  begin
    v_cdgo_rspsta := 0;
    
    v_nl := pkg_sg_log.fnc_ca_nivel_log(8758, null, nmbre_up);
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);
    --Consultamos el envio programado
    begin
        select *
        into rt_ma_g_envios_programado
        from ma_g_envios_programado
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
    exception
        when others then
           v_mnsje_rspsta := 'Problemas al consultar envio programado';
           raise v_error; 
    end;
    
    v_mnsje_log := 'Consultamos el envio programado - '||rt_ma_g_envios_programado.dscrpcion;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    
    v_mnsje_log := 'Consultamos el id consulta principal - '||rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_prncpal;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    --Actualizamos el estado del envio programado
    begin
        update ma_g_envios_programado
        set actvo = 'S'
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
        commit;
    exception   
        when others then
            v_mnsje_rspsta := 'Problemas al actualizar el estado del envio programado, '||sqlerrm;
            raise v_error;
    end;
    
    --Consultamos la consulta principal asociada al envio programado
    begin

      select *
        into rt_ma_g_envios_prgrmdo_cnslta_p
        from ma_g_envios_prgrmdo_cnslta
        where id_envio_prgrmdo_cnslta = rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_prncpal;
    exception
        when others then
            v_mnsje_rspsta := 'Problemas al consultar la consulta principal asociada al envio programado, '||sqlerrm;
            raise v_error;
    end;
    
    v_mnsje_log := 'Consultamos la consulta principal asociada al envio programado - '||rt_ma_g_envios_prgrmdo_cnslta_p.cnslta||
                    ' - rt_ma_g_envios_prgrmdo_cnslta_p.id_cnslta_mstro: '||rt_ma_g_envios_prgrmdo_cnslta_p.id_cnslta_mstro;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    
    --Validamos el tipo de consulta
    if (rt_ma_g_envios_prgrmdo_cnslta_p.id_cnslta_mstro is null) then
        v_sql := rt_ma_g_envios_prgrmdo_cnslta_p.cnslta;
        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'IF----is null-Validamos el tipo de consulta v_sql:=>'||v_sql, 6);

    else
        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'else----Validamos el tipo de consulta', 6);
        v_sql := pkg_cs_constructorsql.fnc_co_sql_dinamica(
            p_id_cnslta_mstro => rt_ma_g_envios_prgrmdo_cnslta_p.id_cnslta_mstro, 
            p_cdgo_clnte      => rt_ma_g_envios_programado.cdgo_clnte, 
            p_rturn_alias     => 'S'
        );
    end if;
   pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Salimos del if', 6);
    
    v_c_columnas := dbms_sql.open_cursor;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'despues de v_c_columnas=>'||v_c_columnas, 6);
    
    dbms_sql.parse( v_c_columnas, v_sql , dbms_sql.native );
    
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'despues de dbms_sql.parse', 6);
    
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'datos:=>'||to_char(v_c_columnas)||'-'||to_char(v_nmro_clmna), 6);
    
    
    
    --pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'datos:=>'||v_c_columnas||v_nmro_clmna||v_dscrpcion_tbla, 6);
    
    dbms_sql.describe_columns2( v_c_columnas, v_nmro_clmna, v_dscrpcion_tbla );
    
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, ' despues de dbms_sql.describe_columns2', 6);
    
     pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Antes del cursor', 6);
     
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Entrando al cursor c_columnas', 6);
    for c_columnas in 1 .. v_nmro_clmna loop
         v_columnas_json := 
            v_columnas_json || case when v_columnas_json is null then '' else ', ' end ||
            'key '''||v_dscrpcion_tbla( c_columnas ).col_name||''' value "'||v_dscrpcion_tbla( c_columnas ).col_name||'"';
            
                 pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl,' dentro del cursor'||v_columnas_json, 6);

    end loop;
    
    --quedamos aqui
    
    v_mnsje_log := 'Despues del for columnas - v_nmro_clmna: '||v_nmro_clmna||
                    ' - v_columnas_json: '||v_columnas_json;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
   
    --Consultamos el ultimo envio asociado al envio programado
    begin
    
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Consultamos el ultimo envio asociado al envio programado', 6);
        select id_envio, to_char (fcha_rgstro, 'DD-Mon-RR HH24:MI:SS.FF')
        into v_id_envio, v_fcha_rgstro
        from(
            select ma_g_envios.id_envio, ma_g_envios.fcha_rgstro 
            from ma_g_envios 
            where id_envio_prgrmdo = rt_ma_g_envios_programado.id_envio_prgrmdo
            order by fcha_rgstro desc)
        where rownum = 1;
    exception
        when no_data_found then
            v_id_envio := null;
            v_fcha_rgstro := null;
    end;
    v_mnsje_log := 'Consultamos el ultimo envio asociado al envio programado -  v_id_envio: '||v_id_envio|| 
                    ' - v_fcha_rgstro: '||v_fcha_rgstro;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    
    --Remplazamos las variables en la SQL
    v_sql := replace(v_sql, ':F_CDGO_CLNTE', rt_ma_g_envios_programado.cdgo_clnte);
    v_sql := replace(v_sql, ':USRIO_ENVIO_PRGRMDO', rt_ma_g_envios_programado.id_usrio);
    v_sql := replace(v_sql, ':FCHA_ENVIO', 'to_timestamp('''||v_fcha_rgstro||''',''DD-Mon-RR HH24:MI:SS.FF'')');
    
    --Remplazamos las variables asociadas al JSON de parametros
    if(p_json_prmtros is not null)then
        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'IF -Remplazamos las variables asociadas al JSON de parametros', 6);

    
        declare
            v_json_object   json_object_t;
            v_jsonKeys      json_key_list;
        begin
            v_json_object := new json_object_t();
            v_json_object   := json_object_t.parse(p_json_prmtros);
            v_jsonKeys      := v_json_object.get_keys;
            for i in 1 .. v_jsonKeys.count loop
                v_sql := replace(v_sql, ':'||v_jsonKeys(i), ''''||v_json_object.get_string (v_jsonKeys (i))||'''');
            end loop; 
        end;
    end if;       
    
    v_sql_json := 'select json_object('||v_columnas_json||') as json_row from ('||v_sql||')';
    
    v_mnsje_log := 'Saliendo de IF -v_sql_json: '||v_sql_json;
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    --DBMS_OUTPUT.PUT_LINE(v_sql_json);
    
    --Recorremos los registros del cursor
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Recorremos los registros del cursor v_cursor', 6);
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, '********************v_sql_json '||v_sql_json, 6);

    open v_cursor for v_sql_json;
    loop
        declare
            v_json clob;
            v_dstntrios           g_dstntrios; --> Arreglo de destinatarios
            v_archvos_adjntos     g_archvos_adjntos;--> Arreglo de archivos adjuntos
            --
            v_id_envio            ma_g_envios.id_envio%type;
            v_json_prfrncias      clob;
        begin
        v_mnsje_log := 'Dentro del cursor,v_cursor : ';
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
            fetch v_cursor into v_json;
            exit when v_cursor%notfound;
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, '********************v_json : '||v_json, 6);
          
            DBMS_OUTPUT.PUT_LINE(v_json);
            v_mnsje_log := 'Error: v_cursor%notfound';
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
            
            v_cant_registros := v_cant_registros + 1;
            
            --Inicializamos los arreglos
            v_dstntrios         := g_dstntrios();
            v_archvos_adjntos   := g_archvos_adjntos();
            
            --Validamos el tipo de origen de los destinatarios
            begin
            
            v_mnsje_log := 'Validamos el tipo de origen de los destinatarios, antes del case: '||rt_ma_g_envios_programado.orgen_tpo_dstntrio;
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                case rt_ma_g_envios_programado.orgen_tpo_dstntrio
                    when 'SQL' then --> Consulta SQL
                        declare
                            v_columnas_json             varchar(3200);
                            v_sql_origen_destinarios    clob;
                            v_sql_destinatarios         clob;
                            v_json_destinatarios        clob;
                        begin
                            --Consultamos las columnas requeridas
                            v_columnas_json := pkg_ma_envios.fnc_co_columnas_json_envios_programado(p_id_envio_prgrmdo => p_id_envio_prgrmdo);
                            
                            if(v_columnas_json is null)then
                                raise_application_error( -20001, 'Problemas al consultar columnas requeridas' );
                            end if;
                            
                            v_mnsje_log := 'Consultamos la SQL origen: '||rt_ma_g_envios_prgrmdo_cnslta_d.cnslta;
                            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                            --Consultamos la SQL origen
                            begin
                                select *
                                into rt_ma_g_envios_prgrmdo_cnslta_d
                                from ma_g_envios_prgrmdo_cnslta
                                where id_envio_prgrmdo_cnslta = rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_dstntr;
                            exception
                                when others then
                                    raise_application_error( -20001, 'Problemas al consultar la consulta de destinatarios asociada al envio programado' );
                                    
                            end;
                            
                            v_mnsje_log := 'Antes del if: '||rt_ma_g_envios_prgrmdo_cnslta_d.id_cnslta_mstro;
                            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                            
                            if (rt_ma_g_envios_prgrmdo_cnslta_d.id_cnslta_mstro is null) then
                                v_sql_origen_destinarios := rt_ma_g_envios_prgrmdo_cnslta_d.cnslta;
                            else
                                v_sql_origen_destinarios := pkg_cs_constructorsql.fnc_co_sql_dinamica(
                                    p_id_cnslta_mstro => rt_ma_g_envios_prgrmdo_cnslta_d.id_cnslta_mstro, 
                                    p_cdgo_clnte      => rt_ma_g_envios_programado.cdgo_clnte, 
                                    p_rturn_alias     => 'S'
                                );
                            end if;
                            
                            --Consultamos el ultimo envio asociado al envio programado
                            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Consultamos el ultimo envio asociado al envio programado', 6);
                            begin
                                select id_envio, fcha_rgstro
                                into v_id_envio, v_fcha_rgstro
                                from(
                                    select ma_g_envios.id_envio, ma_g_envios.fcha_rgstro 
                                    from ma_g_envios 
                                    where id_envio_prgrmdo = rt_ma_g_envios_programado.id_envio_prgrmdo
                                    order by fcha_rgstro desc)
                                where rownum = 1;
                            exception
                                when no_data_found then
                                    v_id_envio := null;
                                    v_fcha_rgstro := null;
                            end;
                            
                            v_mnsje_log := 'Consultamos el ultimo envio asociado al envio programado -  v_id_envio: '||v_id_envio|| 
                                           ' - v_fcha_rgstro: '||v_fcha_rgstro;
                            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                            
                            --Remplazamos las variables en la SQL de  destinatarios
                            v_sql_destinatarios := replace(v_sql_destinatarios, ':F_CDGO_CLNTE', rt_ma_g_envios_programado.cdgo_clnte);
                            v_sql_destinatarios := replace(v_sql_destinatarios, ':USRIO_ENVIO_PRGRMDO', rt_ma_g_envios_programado.id_usrio);
                            v_sql_destinatarios := replace(v_sql_destinatarios, ':FCHA_ENVIO ', v_fcha_rgstro);
                            
                            --Remplazamos las variables asociadas al JSON de parametros
                            declare
                                v_json_object   json_object_t;
                                v_jsonKeys      json_key_list;
                            begin
                                v_json_object := json_object_t(p_json_prmtros);
                                v_jsonKeys := v_json_object.get_keys;
                                for i in 1 .. v_jsonKeys.count loop
                                    v_sql := replace(v_sql_destinatarios, ':'||v_jsonKeys(i), ''''||v_json_object.get_string (v_jsonKeys (i))||'''');
                                end loop; 
                            end;
                            
                            --Generamos la consulta para obtener el JSON
                            v_sql_destinatarios := 'select json_arrayagg(json_object('||v_columnas_json||'))from('||v_sql_origen_destinarios||')';
                            
                            v_mnsje_log := 'Generamos la consulta para obtener el JSON -  v_sql_destinatarios: '||v_sql_destinatarios;
                            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                            
                            --Ejecutamos la consulta generada y almacenamos el JSON obtenido
                            execute immediate v_sql_destinatarios into v_json_destinatarios;
                            
                            --Guardamos los destinatarios asociados al JSON
                            select id_usrio, nmbre, nmro_cllar, email--, id_sjto_impsto  --##
                            bulk collect into v_dstntrios
                            from json_table(v_json_destinatarios, '$'columns (id_usrio          path '$.ID_USRIO', 
                                                                              nmbre             path '$.NMBRE', 
                                                                              nmro_cllar        path '$.NMRO_CLLAR', 
                                                                              email             path '$.EMAIL'));
                                                                              --id_sjto_impsto    path '$.ID_SJTO_IMPSTO')); --##
                            
                        end;
                    when 'FNC' then --> Funcion
                        null;
                    when 'LST' then --> Lista
                        --Consultamos en la tabla de destinatarios asociados al envio programado
                        select id_usrio, nmbre, nmro_cllar, email --, NULL  --##
                        bulk collect into v_dstntrios
                        from ma_g_envios_prgrmdo_dstntrs
                        where id_envio_prgrmdo = rt_ma_g_envios_programado.id_envio_prgrmdo and
                              actvo = 'S';
                    when 'DCP' then --> Definido en Consulta Principal
                        --Guardamos el destinatario en el arreglo de destinatarios
                        select id_usrio, nmbre, nmro_cllar, email--, id_sjto_impsto  --##
                        bulk collect into v_dstntrios
                        from json_table(v_json, '$'columns (id_usrio            path '$.ID_USRIO', 
                                                            nmbre               path '$.NMBRE', 
                                                            nmro_cllar          path '$.NMRO_CLLAR', 
                                                            email               path '$.EMAIL'));
                                                          --  id_sjto_impsto      path '$.ID_SJTO_IMPSTO'));  --##
                end case;
            exception
                when others then
                    raise_application_error(-20001, 'Problemas al cargar los destinatarios, '||sqlerrm);
            end;
            
            v_mnsje_log := 'Validamos si hay destinatarios: '||v_dstntrios.count;
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
            
            --Validamos si hay destinatarios
            if(v_dstntrios.count < 1)then
                raise_application_error(-20001, 'No hay destinatarios cargados para realizar el envio.');
            end if;
            
             --Remplazamos las variables asociadas al JSON de parametros
            declare
                v_json_object   json_object_t;
                v_jsonKeys      json_key_list;
            begin
                v_json_prfrncias := fnc_co_json_medio_preferencias(p_id_envio_prgrmdo => rt_ma_g_envios_programado.id_envio_prgrmdo);
                
                v_json_object := json_object_t(v_json);
                v_jsonKeys := v_json_object.get_keys;
                for i in 1 .. v_jsonKeys.count loop
                    v_json_prfrncias := replace(v_json_prfrncias, '#'||v_jsonKeys(i)||'#', v_json_object.get_string (v_jsonKeys (i)));
                end loop;         
            end;
            
            v_mnsje_log := 'Remplazamos las variables asociadas al JSON de parametro: '||to_char(v_json_prfrncias);
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
            
            --DBMS_OUTPUT.PUT_LINE(v_json_prfrncias);
            --Registramos el envio
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Registramos el envio', 6);

            pkg_ma_envios.prc_rg_envio( p_cdgo_clnte                => rt_ma_g_envios_programado.cdgo_clnte,
                                        p_id_envio_prgrmdo          => rt_ma_g_envios_programado.id_envio_prgrmdo,
                                        p_fcha_rgstro               => systimestamp,
                                        p_fcha_prgrmda              => systimestamp,
                                        p_json_prfrncia             => v_json_prfrncias,
                                        p_id_sjto_impsto            => p_id_sjto_impsto,
                                        p_id_acto                   => p_id_acto,
                                        o_id_envio                  => v_id_envio,
                                        o_cdgo_rspsta			    => v_cdgo_rspsta,
                                        o_mnsje_rspsta              => v_mnsje_rspsta);
            
            v_mnsje_log := 'Llamamos al pkg_ma_envios.prc_rg_envio - o_cdgo_rspsta: '||v_cdgo_rspsta||' - o_mnsje_rspsta: '||v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
            
            --Validamos si hubo errores
            
            
            
            if(v_cdgo_rspsta != 0)then
                raise_application_error(-20001, v_mnsje_rspsta);
            end if;
            
          pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, 'Consultamos el ultimo envio asociado al envio programado', 6);

            --Registramos los destinatarios asociado a cada medio
            for x in 1 .. v_dstntrios.count loop
                for c_medios_programados in (select * 
                                             from ma_g_envios_programado_mdio
                                             where id_envio_prgrmdo = rt_ma_g_envios_programado.id_envio_prgrmdo and
                                                   actvo = 'S') loop
                    declare
                        v_id_envio_mdio ma_g_envios_medio.id_envio_mdio%type;
                        v_txto_mnsje clob;
                        v_asnto      ma_g_envios_programado_mdio.asnto%type;
                        --
                        v_json_object   json_object_t;
                        v_jsonKeys      json_key_list;
                    begin
                        
                        v_txto_mnsje := c_medios_programados.txto_mnsje;
                        v_asnto := c_medios_programados.asnto;
                        
                        v_json_object := json_object_t(v_json);
                        v_jsonKeys := v_json_object.get_keys;
                        for i in 1 .. v_jsonKeys.count loop
                            v_txto_mnsje := replace(v_txto_mnsje, '#'||v_jsonKeys(i)||'#', v_json_object.get_string (v_jsonKeys (i)));
                            v_asnto := replace(v_asnto, '#'||v_jsonKeys(i)||'#', v_json_object.get_string (v_jsonKeys (i)));
                        end loop; 
                        
                        v_mnsje_log := 'Antes de pkg_ma_envios.prc_rg_envio_mdio - v_id_envio: '||v_id_envio||' - cdgo_envio_mdio: '||c_medios_programados.cdgo_envio_mdio;
                        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                        
                        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, ' datos->     v_id_envio=>'||v_id_envio||'-'
                                                                                         ||c_medios_programados.cdgo_envio_mdio
                                                                                         ||'-'||v_dstntrios(x).email
                                                                                         , 6);
                        
                        
                        pkg_ma_envios.prc_rg_envio_mdio(p_id_envio                  => v_id_envio,
                                                        p_cdgo_envio_mdio           => c_medios_programados.cdgo_envio_mdio,
                                                        p_dstno                     => case c_medios_programados.cdgo_envio_mdio
                                                                                        when 'SMS' then
                                                                                            v_dstntrios(x).nmro_cllar
                                                                                        when 'EML' then
                                                                                            v_dstntrios(x).email
                                                                                        when 'ALR' then
                                                                                            '' || v_dstntrios(x).id_usrio
                                                                                       end,
                                                        p_asnto                     => v_asnto,
                                                        p_txto_mnsje                => v_txto_mnsje,
                                                      --  p_id_sjto_impsto            => v_dstntrios(x).id_sjto_impsto,  --##
                                                        o_id_envio_mdio             => v_id_envio_mdio,
                                                        o_cdgo_rspsta			    => v_cdgo_rspsta,
                                                        o_mnsje_rspsta              => v_mnsje_rspsta);
                                                        
                        v_mnsje_log := 'Despues de pkg_ma_envios.prc_rg_envio_mdio - o_cdgo_rspsta: '||v_cdgo_rspsta||' - o_mnsje_rspsta: '||v_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                        
                        --Validamos si hubo errores
                        if(v_cdgo_rspsta != 0)then
                           raise_application_error(-20001, v_mnsje_rspsta);
                        end if;
                        
                        v_mnsje_log := 'Antes de prc_rg_envio_estado - v_id_envio_mdio: '||v_id_envio_mdio;
                        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                        
                        --Registramos el estado
                        prc_rg_envio_estado(p_id_envio_mdio             => v_id_envio_mdio,
                                            p_cdgo_envio_estdo          => 'ENC',
                                            o_cdgo_rspsta			    => v_cdgo_rspsta,
                                            o_mnsje_rspsta              => v_mnsje_rspsta);
                        
                        v_mnsje_log := 'Despues de prc_rg_envio_estado - o_cdgo_rspsta: '||v_cdgo_rspsta||' - o_mnsje_rspsta: '||v_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                                            
                       --Validamos si hubo errores
                        if(v_cdgo_rspsta != 0)then
                           raise_application_error(-20001, v_mnsje_rspsta);
                        end if;
                    exception
                        when others then
                            continue;
                    end;
                end loop;
            end loop;
            
            --Validamos el tipo de origen de archivos adjuntos
            begin
                case rt_ma_g_envios_programado.orgen_tpo_adjunto
                    when 'SQL' then
                        begin
                            --Consultamos la SQL origen
                            select *
                            into rt_ma_g_envios_prgrmdo_cnslta_a
                            from ma_g_envios_prgrmdo_cnslta
                            where id_envio_prgrmdo_cnslta = rt_ma_g_envios_programado.id_envio_prgrmdo_cnslta_adjnto;
                            
                            if (rt_ma_g_envios_prgrmdo_cnslta_a.id_cnslta_mstro is null) then
                                v_sql_adjuntos := rt_ma_g_envios_prgrmdo_cnslta_a.cnslta;
                            else
                                v_sql_adjuntos := pkg_cs_constructorsql.fnc_co_sql_dinamica(
                                    p_id_cnslta_mstro => rt_ma_g_envios_prgrmdo_cnslta_a.id_cnslta_mstro, 
                                    p_cdgo_clnte      => rt_ma_g_envios_programado.cdgo_clnte, 
                                    p_rturn_alias     => 'S'
                                );
                            end if;
                            
                            DBMS_OUTPUT.PUT_LINE(v_sql_adjuntos);
                            if(p_json_prmtros is not null)then
                                --Remplazamos las variables asociadas al JSON de parametros
                                declare
                                    v_json_object   json_object_t;
                                    v_jsonKeys      json_key_list;
                                begin
                                    v_json_object := json_object_t(p_json_prmtros);
                                    v_jsonKeys := v_json_object.get_keys;
                                    for i in 1 .. v_jsonKeys.count loop
                                        v_sql_adjuntos := replace(v_sql_adjuntos, ':'||v_jsonKeys(i), ''''||v_json_object.get_string (v_jsonKeys (i))||'''');
                                    end loop; 
                                end;
                            end if;

                            execute immediate v_sql_adjuntos bulk collect into v_archvos_adjntos;
                        exception
                            when others then 
                                DBMS_OUTPUT.PUT_LINE(sqlerrm);
                                v_mnsje_log := 'Despues execute immediate v_sql_adjuntos : '||sqlerrm;
                                 pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                       
                        end;
                    when 'LST' then
                        null;
                else
                    null;
                end case;
            exception
                when others then
                    DBMS_OUTPUT.PUT_LINE(sqlerrm);
            end;
            
            DBMS_OUTPUT.PUT_LINE(v_archvos_adjntos.count);
            --Registramos los archivos adjuntos al envio programado
            for x in 1 .. v_archvos_adjntos.count loop
                declare
                    v_id_envio_adjnto   number;
                begin
                    pkg_ma_envios.prc_rg_envio_adjntos(
                        p_id_envio                  => v_id_envio,
                        p_file_blob                 => v_archvos_adjntos(x).file_blob,
                        p_file_name                 => v_archvos_adjntos(x).file_name,
                        p_file_mimetype             => v_archvos_adjntos(x).file_mimetype,
                        o_id_envio_adjnto           => v_id_envio_adjnto,
                        o_cdgo_rspsta			    => v_cdgo_rspsta,
                        o_mnsje_rspsta              => v_mnsje_rspsta
                    );
                    
                    v_mnsje_log := 'Despues de pkg_ma_envios.prc_rg_envio_adjntos - o_cdgo_rspsta: '||v_cdgo_rspsta||' - o_mnsje_rspsta: '||v_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
                    
                    --Validamos si hubo errores
                    if(v_cdgo_rspsta != 0)then
                        DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
                        raise_application_error(-20001, v_mnsje_rspsta);
                    end if;    
                end;
            end loop;
        end;
        
    end loop;
    close v_cursor;
    /*
    --Validamos el tipo de origen de archivos adjuntos
    begin
        case rt_ma_g_envios_programado.orgen_tpo_adjunto
            when 'CSQ' then
                null;
            when 'FNC' then
                null;
            when 'LST' then
                null;
            when 'DEB' then
                v_archvos_adjntos := p_archvos_adjntos;
        else
            null;
        end case;
    exception
        when others then
            o_mnsje_rspsta := 'Problemas al cargar los archivos adjuntos';
            raise v_error;
    end;
    

    
    
    --Registramos los archivos adjuntos al envio programado
    for x in 1 .. v_archvos_adjntos.count loop
        declare
            v_id_envio_adjnto   number;
        begin
            pkg_ma_envios.prc_rg_envio_adjntos(
                p_id_envio                  => v_id_envio,
                p_file_blob                 => v_archvos_adjntos(x).file_blob,
                p_file_name                 => v_archvos_adjntos(x).file_name,
                p_file_mimetype             => v_archvos_adjntos(x).file_mimetype,
                o_id_envio_adjnto           => v_id_envio_adjnto,
                o_cdgo_rspsta			    => o_cdgo_rspsta,
                o_mnsje_rspsta              => o_mnsje_rspsta
            );
            
            --Validamos si hubo errores
            if(o_cdgo_rspsta != 0)then
                raise v_error;
            end if;    
        end;
    end loop;
    */
    
    --Actualizamos el estado del envio programado
    begin
        update ma_g_envios_programado
        set actvo = 'N'
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
        commit;
    exception   
        when others then
            v_mnsje_rspsta := 'Problemas al actualizar el estado del envio programado, '||sqlerrm;
            raise v_error;
    end;
    
    v_mnsje_log := 'Despues de actualizar el envio programado a N.';
    pkg_sg_log.prc_rg_log(8758, null, nmbre_up,  v_nl, v_mnsje_log, 6);
    
  exception
    when v_error then
        --Actualizamos el estado del envio programado
        update ma_g_envios_programado
        set actvo = 'N'
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
        commit;
        
        if(v_cdgo_rspsta = 0)then
            v_cdgo_rspsta := 1;
        end if;
        DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
    when others then
        --Actualizamos el estado del envio programado
        update ma_g_envios_programado
        set actvo = 'N'
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
        commit;
        
        v_mnsje_rspsta := 1;
        v_mnsje_rspsta := 'Problemas al registrar envio, '||sqlerrm;
        
        DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
  end prc_rg_envios;

  /*Procedimiento para la gestion de envios programados*/
  procedure prc_ge_envios_programados as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    --Recorremos los envios programados que se encuentran activos y confirmados para enviar
    --Tipo ejecucion: 'INM-Inmediato','UNV-Una vez','RPT-Repeticion'

    for c_envio_programado in (select a.*
                               from ma_g_envios_programado a
                               where a.actvo            != 'S' and
                                     a.cnfrmcion_envio   = 'S' and
                                     a.ejccion_tpo      in ('INM','UNV','RPT')) loop
        declare
            v_cdgo_rspsta   number;
            v_mnsje_rspsta  varchar2(32000);
            v_job_name      varchar2(1000);
        begin
            --Validamos si registra envio
            if(not pkg_ma_envios.fnc_vl_registra_envio(p_id_envio_prgrmdo => c_envio_programado.id_envio_prgrmdo))then
                 DBMS_OUTPUT.put_line('No se cumplen las condiciones');
                continue;
            end if;

            -->Definimos el nombre para el JOB
            v_job_name := 'IT_MA_ENVIOS_PROGRAMADO_NUM_' || c_envio_programado.id_envio_prgrmdo;

            --Creamos el JOB para la gestion del envio programado
            begin
                dbms_scheduler.create_job (
                    job_name             =>  v_job_name,
                    job_type             =>  'STORED_PROCEDURE',
                    job_action           =>  'PKG_MA_ENVIOS.PRC_RG_ENVIOS',
                    auto_drop            =>  true,
                    comments             =>  'JOB de mensajeria y alerta para la gestion del envio programado No. '||c_envio_programado.id_envio_prgrmdo,
                    number_of_arguments  => 1
                );
            exception
                when others then
                    DBMS_OUTPUT.put_line(sqlerrm);
                    continue;
            end;

            --Definimos los argumento al JOB creado
            begin
                dbms_scheduler.set_job_argument_value(
                    job_name            => v_job_name,
                    argument_position   => 1,
                    argument_value      => c_envio_programado.id_envio_prgrmdo
                );
            exception
                when others then
                    raise v_error;
            end;

            --Habilitamos el JOB
            begin
                dbms_scheduler.enable(name => v_job_name);
            exception
                when others then
                    raise v_error;
            end;

        exception
            when v_error then
                DBMS_OUTPUT.put_line(v_mnsje_rspsta);
                --Borramos el JOB creado
                dbms_scheduler.drop_job(job_name => v_job_name);
                rollback;  
        end;

        --Confirmamos la Transaccion
        commit;
        DBMS_OUTPUT.put_line('Transaccion Confirmada');

    end loop;
  end prc_ge_envios_programados;

  /*Funcion para validar si se registra un envio*/
  function fnc_vl_registra_envio(p_id_envio_prgrmdo in ma_g_envios_programado.id_envio_prgrmdo%type) return boolean as
    rt_ma_g_envios_programado ma_g_envios_programado%rowtype;
    v_existe_envio varchar2(1) := 'N';
  begin
    --Consultamos el envio programado
    begin
        select *
        into rt_ma_g_envios_programado
        from ma_g_envios_programado
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
    exception
        when no_data_found then
            return false;
    end;

    --Validamos el tipo de ejecucion
    case rt_ma_g_envios_programado.ejccion_tpo
        when 'INM' then/*Inmediado*/
            --Validamos que exista un registro asociado al envio programado
            begin
                select 'S'
                into v_existe_envio
                from ma_g_envios
                where id_envio_prgrmdo = p_id_envio_prgrmdo;
                --Si existe el envio
                return false;
            exception
                when no_data_found then
                    return true;
                when others then
                    return false;
            end;
        when 'UNV' then/*Una Vez*/
            begin
                select 'S'
                into v_existe_envio
                from ma_g_envios
                where id_envio_prgrmdo = p_id_envio_prgrmdo;
                --Si existe el envio
                return false;
            exception
                when no_data_found then
                    --Validamos si la fecha programada es mayor o igual a la actual
                    return systimestamp >= rt_ma_g_envios_programado.fcha_incio;
                when others then
                    return false;
            end;
        when 'RPT' then/*Repeticion*/
            --Validamos si la fecha actual se encuentra dentro de la fecha inicio y la fecha final
            if(systimestamp between rt_ma_g_envios_programado.fcha_incio and rt_ma_g_envios_programado.fcha_fin)then
                declare
                    v_fcha_rgstro       timestamp;
                  --v_fcha_prgrmda      timestamp;
                    v_fecha_validacion  timestamp;
                    v_undad_drcion      varchar2(2);
                    v_drcion            number;
                begin
                    select fcha_rgstro--, fcha_prgrmda
                    into v_fcha_rgstro--, v_fcha_prgrmda
                    from(
                        select fcha_rgstro, fcha_prgrmda
                        from ma_g_envios
                        where id_envio_prgrmdo = p_id_envio_prgrmdo
                        order by fcha_rgstro desc
                    )where rownum = 1;

                    /*Homalogamos la unidad de duracion con el intervalo de repeticion*/
                    case rt_ma_g_envios_programado.intrvlo_rptcion
                        when 'AN' then
                            v_undad_drcion := 'MS';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo * 12;
                        when 'MN' then
                            v_undad_drcion := 'MS';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo;
                        when 'SM' then
                            v_undad_drcion := 'SM';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo;
                        when 'DI' then
                            v_undad_drcion := 'DI';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo;
                        when 'HR' then
                            v_undad_drcion := 'HR';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo;
                        when 'MI' then
                            v_undad_drcion := 'MN';
                            v_drcion := rt_ma_g_envios_programado.vlor_intrvlo;
                    end case;

                    v_fecha_validacion := pk_util_calendario.fnc_cl_fecha_final( 
                        p_fecha_inicial   => v_fcha_rgstro,
                        p_undad_drcion    => v_undad_drcion,
                        p_drcion          => v_drcion,
                        p_dia_tpo         => 'C'
                    );

                    if(systimestamp >= v_fecha_validacion)then
                        return true;
                    else
                        return false;
                    end if;

                exception
                    when no_data_found then
                        return true;
                end;
            else
                return false;
            end if;
    end case; 

    return false;

  end;

  /*Funcion para validar si las condiciones de un envio programado se cumplen
  function fnc_vl_condiciones_envio(
    p_id_envio_prgrmdo  in ma_g_envios_programado.id_envio_prgrmdo%type,
    p_json              in clob                                         default null
  ) return boolean as
    v_condicion         varchar2(4000);
    v_orden_agrpcion    number;
    v_sql_condicion     varchar2(4000);
    v_cmprta_lgca       varchar2(3);

  begin
    for c_condiciones in (
        select listagg(
            case
                when b.cndcion_tpo in ('FNC','PRM') then
                    decode(b.cndcion_tpo,
                        'FNC','PKG_MA_FUNCIONES.'||b.fncion||'(p_json_parametros => :p_json)',
                        'PRM',' PKG_MA_ENVIOS.FNC_CO_VALOR_JSON(p_json=>:p_json,p_prmtro=>'||chr(39)||d.prmtro||chr(39)||') ')||
                    decode(c.oprdor,
                        'BETWEEN',' BETWEEN '||chr(39)||b.vlor1||chr(39)||' AND '||chr(39)||b.vlor2||chr(39)||' ',
                        ' '||c.oprdor||' '||chr(39)||b.vlor2||chr(39)||' ')
                when b.cndcion_tpo in ('FSQ', 'NFS') then
                    decode(b.cndcion_tpo,
                        'FSQ',' 0 < ',
                        'NFS',' 0 = ')||
                    '( select count(*) from ('||
                    case
                        when e.cnslta is null then
                            pkg_cs_constructorsql.fnc_co_sql_dinamica(
                                p_id_cnslta_mstro => e.id_envio_prgrmdo_cnslta,
                                p_cdgo_clnte => a.cdgo_clnte,
                                p_rturn_alias => 'S',
                                p_json => p_json
                            )
                    else
                        to_char(e.cnslta) 
                    end||')) '
            end||b.cmprta_lgca,'')within group(order by b.orden_agrpcion) as fnc ,b.orden_agrpcion
        from ma_g_envios_programado a
        inner join ma_g_envios_prgrmdo_cndcion b on a.id_envio_prgrmdo = b.id_envio_prgrmdo
        left join df_s_operadores_tipo  c on b.id_oprdor_tpo    = c.id_oprdor_tpo
        left join ma_d_envios_parametro d on b.id_envio_prmtro  = d.id_envio_prmtro
        left join ma_g_envios_prgrmdo_cnslta e on b.id_envio_prgrmdo_cnslta = e.id_envio_prgrmdo_cnslta
        where a.id_envio_prgrmdo = p_id_envio_prgrmdo and
              b.actvo            = 'S'
        group by b.orden_agrpcion
    ) loop
        v_condicion := upper(c_condiciones.fnc);
        if v_orden_agrpcion != c_condiciones.orden_agrpcion or v_orden_agrpcion is null then
            v_orden_agrpcion := c_condiciones.orden_agrpcion ;
            if upper(v_condicion) like '%AND' then
                v_condicion :=  '(' || substr(v_condicion, 0 ,length(v_condicion)-3) || ') ';
                v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||  v_condicion || ' ' ;
                v_cmprta_lgca := 'AND';            
            elsif upper(v_condicion) like '%OR' then
                v_condicion :=  '(' || substr(v_condicion, 0 ,length(v_condicion)-2) || ') ';
                v_sql_condicion :=  v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' || v_condicion || ' ';
                v_cmprta_lgca := 'OR';
            end if;    
        end if;
    end loop;

    if v_sql_condicion is not null then              
        v_sql_condicion := 'select case when (' || v_sql_condicion || ') then 0 else 1 end from dual'; 
        execute immediate v_sql_condicion into v_condicion; 
    end if;            

    --SI NO SE CUMPLE LA CONDICION
    if v_condicion <> 0 then
        return false;
    end if;

    v_sql_condicion  := null;
    v_orden_agrpcion := null;
    v_cmprta_lgca    := null;

    return true;
  end;*/

  /*Funcion para obtener el valor de una clave en un JSON*/
  function fnc_co_valor_json(
      p_json in clob,
      p_prmtro in varchar2
  )return varchar2 as
    v_valor varchar2(255);
  begin
    select valor
    into v_valor
    from json_table (p_json, '$[*]'
        columns ( clave varchar2 path '$.parametro', valor varchar2 path  '$.valor')
    )where clave = p_prmtro and rownum = 1;
    return v_valor;
  exception
    when others then
        return null;
  end fnc_co_valor_json;

  /*Procedimiento para validar envios programados*/  
  procedure prc_co_envio_programado(
    p_cdgo_clnte                in  number,
    p_idntfcdor                 in varchar2,
    p_json_prmtros              in  clob default null,
    p_id_sjto_impsto            in  number default null,
    p_id_acto                   in  number default null
  ) as
    pragma autonomous_transaction;
    v_nl                number;
    v_mensaje          varchar2(4000);
    nmbre_up            varchar2(200) := 'pkg_ma_envios.prc_co_envio_programado';
  begin
    -- Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);

    /*Consultamos los envios programados asociados al identificador que se encuentren confirmados*/
    for c_envios_programados in (
        select *
        from ma_g_envios_programado
        where cdgo_clnte        = p_cdgo_clnte and
              idntfcdor         = p_idntfcdor and
              ejccion_tpo       = 'EVN' and
              cnfrmcion_envio   = 'S'
    )loop
        declare
        begin
            v_mensaje := 'For de envios programados - c_envios_programados.id_envio_prgrmdo: '||c_envios_programados.id_envio_prgrmdo||' - p_json_prmtros: '||p_json_prmtros;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, v_mensaje, 6);
            DBMS_OUTPUT.PUT_LINE('Envio:'||c_envios_programados.id_envio_prgrmdo);
            pkg_ma_envios.prc_rg_envios(
                p_id_envio_prgrmdo          => c_envios_programados.id_envio_prgrmdo,
                p_json_prmtros              => p_json_prmtros,
                p_id_sjto_impsto            => p_id_sjto_impsto,
                p_id_acto                   => p_id_acto       
            );
        end;
    end loop;
    /*--Consultamos envios programados activos y listos para enviar
    for c_envios_programados in (
        select *
        from ma_g_envios_programado
        where cdgo_clnte = p_cdgo_clnte and
              ejccion_tpo = 'EVB' and
              upper(nmbre_up) = upper(p_nmbre_up) and
              actvo = 'S' and
              cnfrmcion_envio = 'S'
    ) loop
        declare
            v_cdgo_rspsta               number;
            v_mnsje_rspsta              varchar2(32000);
            v_error_envio_programado    exception;
        begin

            --Validamos si se cumplen las condiciones
            if(not pkg_ma_envios.fnc_vl_condiciones_envio(p_id_envio_prgrmdo => c_envios_programados.id_envio_prgrmdo, p_json => p_json_prmtros))then
                v_mnsje_rspsta := 'No se cumplen las condiciones para realizar el envio';
                raise v_error_envio_programado;
            end if;

            --Registramos el envio
            pkg_ma_envios.prc_rg_envios(
                p_id_envio_prgrmdo          => c_envios_programados.id_envio_prgrmdo,
                p_dstntrios                 => p_dstntrios,
                p_archvos_adjntos           => p_archvos_adjntos,
                o_cdgo_rspsta			    => v_cdgo_rspsta,
                o_mnsje_rspsta              => v_mnsje_rspsta
            );
            --Validamos si hubo errores
            if(v_cdgo_rspsta != 0)then
                raise v_error_envio_programado;
            end if;

        exception
            when v_error_envio_programado then
                rollback;
            when others then
                rollback;
        end;

    end loop;*/
  end prc_co_envio_programado;

  /*Procedimiento para gestionar los envios*/
  procedure prc_ge_envios as
    v_rt_ma_d_envios_medio_cnfgrcion    ma_d_envios_medio_cnfgrcion%rowtype;
    v_cdgo_rspsta                       number;
    v_mnsje_rspsta                      varchar2(3200);
    v_bloque_pl                         varchar2(1000);
  begin

    --Recorremos los envios que se encuentran en cola
    for c_envios in (select b.cdgo_clnte, a.id_envio_mdio, a.id_envio, a.cdgo_envio_mdio
                     from ma_g_envios_medio a
                     inner join ma_g_envios b on a.id_envio = b.id_envio
                     where a.cdgo_envio_estdo = 'ENC')loop

        --Consultamos la UP para realizar el envio
        pkg_ma_envios.prc_co_configuraciones(
            p_cdgo_clnte                        => c_envios.cdgo_clnte,
            p_cdgo_envio_mdio                   => c_envios.cdgo_envio_mdio,   
            o_rt_ma_d_envios_medio_cnfgrcion    => v_rt_ma_d_envios_medio_cnfgrcion,
            o_cdgo_rspsta			            => v_cdgo_rspsta,
            o_mnsje_rspsta                      => v_mnsje_rspsta
        );

        if(v_cdgo_rspsta != 0)then
            DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
            continue;
        end if;

        --Definimos la UP a utilizar
        v_bloque_pl :=' begin
                            PKG_MA_ENVIOS_MEDIO.'||v_rt_ma_d_envios_medio_cnfgrcion.undad_prgrma||'(
                                p_id_envio_mdio => :id_envio_mdio,
                                o_cdgo_rspsta	=> :cdgo_rspsta,
                                o_mnsje_rspsta  => :mnsje_rspsta
                            );
                        end;';
        --Ejecutamos la UP
        begin
            execute immediate v_bloque_pl using in c_envios.id_envio_mdio, out v_cdgo_rspsta, out v_mnsje_rspsta;
        exception
            when others then
                v_cdgo_rspsta   := 1;
                v_mnsje_rspsta  := 'Problemas al ejecutar UP, '||sqlerrm;
                DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
        end;

        --Validamos si hubo errores al ejecutar UP
        if(v_cdgo_rspsta != 0)then
            DBMS_OUTPUT.PUT_LINE(v_mnsje_rspsta);
            rollback;
            continue;
        end if;

        commit;
    end loop;

  end prc_ge_envios;

  /*Procedimiento para consultar las configuraciones de un medio de envio*/
  procedure prc_co_configuraciones(
    p_id_envio_mdio                     in  ma_g_envios_medio.id_envio_mdio%type,
    o_rt_ma_g_envios_medio              out ma_g_envios_medio%rowtype,
    o_rt_ma_d_envios_medio_cnfgrcion    out ma_d_envios_medio_cnfgrcion%rowtype,
    o_json_parametros                   out clob,
    o_json_preferencias                 out clob,
    o_cdgo_rspsta			            out number,
    o_mnsje_rspsta                      out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;

    v_cdgo_clnte                    number;
    v_id_envio                      ma_g_envios_medio.id_envio%type;
    v_cdgo_envio_mdio               ma_g_envios_medio.cdgo_envio_mdio%type;
    v_dstno                         ma_g_envios_medio.dstno%type;
    v_asnto                         ma_g_envios_medio.asnto%type;
    v_txto_mnsje                    ma_g_envios_medio.txto_mnsje%type;

  begin

    o_cdgo_rspsta := 0;

    --Consultamos el envio
    begin
        select b.cdgo_clnte, a.id_envio, a.cdgo_envio_mdio, a.dstno, a.asnto, a.txto_mnsje, b.json_prfrncia
        into v_cdgo_clnte, v_id_envio, v_cdgo_envio_mdio, v_dstno, v_asnto, v_txto_mnsje, o_json_preferencias
        from ma_g_envios_medio a
        inner join ma_g_envios b on a.id_envio = b.id_envio
        where id_envio_mdio = p_id_envio_mdio;
    exception
        when others then
            o_mnsje_rspsta := 'Problemas al consultar envio, '||sqlerrm;
            raise v_error;
    end;

    o_rt_ma_g_envios_medio.id_envio         := v_id_envio;
    o_rt_ma_g_envios_medio.cdgo_envio_mdio  := v_cdgo_envio_mdio;
    o_rt_ma_g_envios_medio.dstno            := v_dstno;
    o_rt_ma_g_envios_medio.asnto            := v_asnto;
    o_rt_ma_g_envios_medio.txto_mnsje       := v_txto_mnsje;

    begin
        select *
        into o_rt_ma_d_envios_medio_cnfgrcion
        from ma_d_envios_medio_cnfgrcion
        where cdgo_clnte      = v_cdgo_clnte      and
              cdgo_envio_mdio = v_cdgo_envio_mdio and
              actvo           = 'S';
    exception
        when others then
            o_mnsje_rspsta := 'Problemas al consultar envio, '||sqlerrm;
            raise v_error;
    end;

    --Generamos JSON de Configuraciones
    o_json_parametros := fnc_co_json_configuraciones( p_id_envio_mdio_cnfgrcion  => o_rt_ma_d_envios_medio_cnfgrcion.id_envio_mdio_cnfgrcion);

  exception
    when v_error then
        if(o_cdgo_rspsta = 0)then
            o_cdgo_rspsta := 1;
        end if;
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := sqlerrm;
  end prc_co_configuraciones;

  procedure prc_co_configuraciones(
    p_cdgo_clnte                        in  number,
    p_cdgo_envio_mdio                   in  ma_g_envios_medio.cdgo_envio_mdio%type,   
    o_rt_ma_d_envios_medio_cnfgrcion    out ma_d_envios_medio_cnfgrcion%rowtype,
    o_cdgo_rspsta			            out number,
    o_mnsje_rspsta                      out varchar2
  ) as
  begin
    o_cdgo_rspsta := 0;
    select *
    into o_rt_ma_d_envios_medio_cnfgrcion
    from ma_d_envios_medio_cnfgrcion
    where cdgo_clnte      = p_cdgo_clnte      and
          cdgo_envio_mdio = p_cdgo_envio_mdio and
          actvo           = 'S';
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al consultar configuraciones de envio, '||sqlerrm;
  end prc_co_configuraciones;

  /*Funcion para consular columnas requeridas segun los medios de un envio programado*/
  function fnc_co_columnas_json_envios_programado(
    p_id_envio_prgrmdo                  in  ma_g_envios_programado.id_envio_prgrmdo%type
  ) return varchar2 as
    v_columnas_json varchar2(32000);
  begin
    --Consultamos las columnas requeridas
    select listagg('key '||chr(39)||c.clmna_dstno||chr(39)||' value '||c.clmna_dstno,' ,')within group (order by clmna_dstno) as columns
    into v_columnas_json
    from ma_g_envios_programado_mdio a
    inner join ma_g_envios_programado b on a.id_envio_prgrmdo = b.id_envio_prgrmdo
    inner join ma_d_envios_medio_cnfgrcion c on a.cdgo_envio_mdio = c.cdgo_envio_mdio and
                                                c.cdgo_clnte = b.cdgo_clnte and
                                                c.actvo = 'S'
    where a.id_envio_prgrmdo = p_id_envio_prgrmdo and
          a.actvo = 'S';
    return v_columnas_json;

  exception
    when no_data_found then
        return null;
  end;

  function fnc_co_json_medio_preferencias(
     p_id_envio_prgrmdo             in  ma_g_envios.id_envio%type
  ) return clob as
    v_json clob;
  begin
    select json_arrayagg(json_object (
                key 'parametro' value d.prmtro,
                key 'valor' value c.vlor 
    ))into v_json
    from ma_g_envios_programado a
    inner join ma_g_envios_programado_mdio b on a.id_envio_prgrmdo = b.id_envio_prgrmdo
    inner join ma_g_envios_prgrmdo_mdio_pf c on b.id_envio_prgrmdo_mdio = c.id_envio_prgrmdo_mdio
    inner join ma_d_envios_mdio_cnfgrcn_pf d on c.id_envio_mdio_cnfgrcion_pf = d.id_envio_mdio_cnfgrcion_pf
    where a.id_envio_prgrmdo = p_id_envio_prgrmdo and
          b.actvo            = 'S';
    return v_json;   
  end fnc_co_json_medio_preferencias;

  function fnc_co_json_configuraciones(
    p_id_envio_mdio_cnfgrcion  in  number
  ) return clob AS
    v_json_prmtros clob;
  begin
    --Generamos JSON de Configuraciones
    select json_arrayagg( json_object (
        key 'parametro' value prmtro,
        key 'valor' value vlor
    ))into v_json_prmtros
    from ma_d_envios_mdio_cnfgrcn_pr
    where id_envio_mdio_cnfgrcion = p_id_envio_mdio_cnfgrcion and
          actvo = 'S';

    return v_json_prmtros;
  end fnc_co_json_configuraciones;


   /*Funcion para validar la confirmacion de un envio programado*/
  function fnc_vl_valida_confirmacion_envio_programado(p_id_envio_prgrmdo in  ma_g_envios_programado.id_envio_prgrmdo%type) return varchar2 as
    rt_ma_g_envios_programado ma_g_envios_programado%rowtype;
  begin
    --Consultamos el envio programado
    begin
        select *
        into rt_ma_g_envios_programado
        from ma_g_envios_programado
        where id_envio_prgrmdo = p_id_envio_prgrmdo;
    exception
        when no_data_found then
            return 'No se encuentra el envio programado No.'||p_id_envio_prgrmdo;
    end;

    --Validamos la consulta principal;
    if(rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_prncpal is null)then
        return 'No se ha definido la consulta principal para el envio programado, por favor verifique';
    end if;

    --Validamos los destinatarios
    case rt_ma_g_envios_programado.orgen_tpo_dstntrio
        when 'SQL' then --> Consulta
            --Validamos que la consulta se encuentre y activa
            declare
                v_exist_c varchar2(1);
            begin
                select 'S'
                into v_exist_c
                from ma_g_envios_prgrmdo_cnslta
                where id_envio_prgrmdo_cnslta = rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_dstntr and
                      actvo = 'S';
            exception
                when no_data_found then
                    return 'La consulta asociada a los destinatarios no se encuentra y/o se encuentra inactiva, por favor verifique';
            end;
        when 'FNC' then --> Funcion
            --Validamos la funcion seleccionada
            if(rt_ma_g_envios_programado.orgen_dstntrio is  null)then
                return 'Por favor seleccione una función';
            end if;
        when 'LST' then --> Lista
            --Validamos que la lista de destinatarios devuelva por lo menos un destinatario
            declare
                v_cant_d number;
            begin
                select count(id_envio_prgrmdo_dstntr) as cant
                into v_cant_d
                from ma_g_envios_prgrmdo_dstntrs
                where id_envio_prgrmdo = p_id_envio_prgrmdo;

                if(v_cant_d = 0)then
                    return 'No hay destinatarios definidos en la lista, por favor verifique.';
                end if;
            end;
        when 'DCP' then --> Definido en Consulta Principal
            --Validamos que en la consulta principal se encuentren las columnas necesarias para el envio
            declare
                rt_ma_g_envios_prgrmdo_cnslta   ma_g_envios_prgrmdo_cnslta%rowtype;
                v_mnsje                         varchar2(5000);

                --Manejos de errores
                v_error                         exception;

                v_sql                           clob;
                v_c_columnas                    number;
                v_dscrpcion_tbla                dbms_sql.desc_tab2;
                v_nmro_clmna                    integer;
            begin
                 --Validamos la consulta
                 begin
                    select *
                    into rt_ma_g_envios_prgrmdo_cnslta
                    from ma_g_envios_prgrmdo_cnslta
                    where id_envio_prgrmdo_cnslta = rt_ma_g_envios_programado.id_envio_prgrmd_cnslta_prncpal and
                          actvo = 'S';
                exception
                    when no_data_found then
                        return 'La consulta asociada no se encuentra por favor verifique.';
                end;

                --Validamos el tipo de consulta
                if (rt_ma_g_envios_prgrmdo_cnslta.id_cnslta_mstro is null) then
                    v_sql := rt_ma_g_envios_prgrmdo_cnslta.cnslta;
                else
                    v_sql := pkg_cs_constructorsql.fnc_co_sql_dinamica(
                        p_id_cnslta_mstro => rt_ma_g_envios_prgrmdo_cnslta.id_cnslta_mstro, 
                        p_cdgo_clnte      => rt_ma_g_envios_programado.cdgo_clnte, 
                        p_rturn_alias     => 'S'
                    );
                end if;

                v_c_columnas := dbms_sql.open_cursor;
                dbms_sql.parse( v_c_columnas, v_sql , dbms_sql.native );
                dbms_sql.describe_columns2( v_c_columnas, v_nmro_clmna, v_dscrpcion_tbla );

                --Recorremos los medios asociados al envio programado
                for c_medios in (select * 
                                 from ma_g_envios_programado_mdio
                                 where id_envio_prgrmdo = rt_ma_g_envios_prgrmdo_cnslta.id_envio_prgrmdo and
                                       actvo = 'S') loop
                    --Consultamos la columna asociada al medio de envio
                    declare
                        v_clmna_dstno ma_d_envios_medio_cnfgrcion.clmna_dstno%type;
                        v_exste_clmna varchar2(1) := 'N';
                    begin
                        select clmna_dstno
                        into v_clmna_dstno
                        from ma_d_envios_medio_cnfgrcion
                        where cdgo_clnte = rt_ma_g_envios_programado.cdgo_clnte and
                              cdgo_envio_mdio = c_medios.cdgo_envio_mdio and
                              actvo = 'S';

                        --Recorremos las columnas de la consulta asociada
                        for c_columnas in 1 .. v_nmro_clmna loop
                            if( upper(v_dscrpcion_tbla( c_columnas ).col_name) = v_clmna_dstno)then
                                v_exste_clmna := 'S';
                                continue;
                            end if;
                        end loop;

                        --Validamos que la columna se encuentre en las columnas asociadas a la consulta
                        if(v_exste_clmna != 'S')then
                           return 'La columna '||v_clmna_dstno||' del medio '||c_medios.cdgo_envio_mdio||' no se encuentra en la consulta principal, por favor verifique';
                        end if;
                    exception
                        when no_data_found then
                            return 'Problemas al consultar las configuraciones del medio de envio: '||c_medios.cdgo_envio_mdio;
                            raise v_error;
                    end;
                end loop;
            end;
    end case;



    return null;
  end fnc_vl_valida_confirmacion_envio_programado;



end pkg_ma_envios;

/
