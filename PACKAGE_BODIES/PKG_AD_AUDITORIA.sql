--------------------------------------------------------
--  DDL for Package Body PKG_AD_AUDITORIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_AD_AUDITORIA" as

  function fnc_gn_json(p_table_name varchar2) return varchar2 as
    v_json clob;
  begin
    v_json := '"campos": [';
    -- Recorremos todas las columnas de la tabla
  
    for i in (select column_name
                from user_tab_columns
               where table_name = p_table_name
                 and data_type not in ('BLOB', 'LONG RAW')
               order by column_id) loop
    
      v_json := v_json || '{"nmbre_cmpo": "' || i.column_name || '",';
      v_json := v_json || ' "old": "'' || :old.' || i.column_name ||
                ' || ''",';
      v_json := v_json || ' "new": "'' || :new.' || i.column_name ||
                ' || ''"},';
    end loop;
  
    v_json := substr(v_json, 1, length(v_json) - 1);
    v_json := v_json || ']}' || ''';';
  
    return v_json;
  end;

  --  ****************************************************
  --
  --  ****************************************************
  function fnc_gn_triggers_audtoria return varchar2 as
  
    v_ddl            clob;
    v_dd2            clob;
    v_temp           varchar2(50);
    v_nombre_trigger varchar2(50);
    v_json           clob;
    v_c              number;
    v_r              number;
  
    v_rspsta varchar2(500);
  
  begin
  
    for i in (select upper(nmbre_tbla_adtda) table_name
                from ad_d_tablas_auditada
               where actvo = 'S'
              /*and (upper(nmbre_tbla_adtda) like 'DF_S_%' 
              or upper(nmbre_tbla_adtda) like 'DF_C_%' 
              or upper(nmbre_tbla_adtda) like 'DF_I_%' )*/
              ) loop
    
      v_rspsta := fnc_gn_triggers_audtoria_tabla(p_table_name    => i.table_name,
                                                 p_indcdor_actvo => 'S');
    
    end loop; -- For i
  
    for k in (select nmbre_tbla_adtda table_name
                from ad_d_tablas_auditada
               where actvo = 'N') loop
    
      v_rspsta := fnc_gn_triggers_audtoria_tabla(p_table_name    => k.table_name,
                                                 p_indcdor_actvo => 'N');
    
    end loop; -- For k
    return v_rspsta;
  end;

  --  ****************************************************
  --
  --  ****************************************************
  function fnc_gn_triggers_audtoria_tabla(p_table_name    varchar2,
                                          p_indcdor_actvo varchar2)
    return varchar2 as
  
    v_ddl            clob;
    v_dd2            clob;
    v_temp           varchar2(50);
    v_nombre_trigger varchar2(50);
    v_json           clob;
    v_c              number;
    v_r              number;
  
    v_rspsta varchar2(500);
  
  begin
  
    if p_indcdor_actvo = 'S' then
      -- Procedemos a crear el triger de Auditoria
    
      v_ddl := null;
    
      -- Solo si la Tabla tiene llave primaria --> procedemos a crear Trigger
      for j in (select b.column_name column_name_pk
                  from user_constraints a, user_cons_columns b
                 where a.constraint_name = b.constraint_name
                   and a.constraint_type = 'P'
                   and a.table_name = p_table_name) loop
      
        -- JSON.  Armamos la estructura que armara el JSON dentro del trigger
        v_json := fnc_gn_json(p_table_name);
      
        v_ddl := v_ddl || 'create or replace trigger ' || p_table_name ||
                 '_ad ';
        v_ddl := v_ddl || 'for insert or update or delete on ' ||
                 p_table_name || ' ';
        v_ddl := v_ddl || 'compound trigger
          
          v_id_auditoria ad_g_audit_trail.id_auditoria%type;
          v_json varchar2(4000);
          v_tpo_oprcion   varchar2(1);
                    v_operacion     varchar2(50);
          after each row is
          begin
                            case true
                                when inserting then
                                    v_tpo_oprcion := ''I'';
                                    v_operacion   := ''Inserción'';
                                when updating then
                                    v_tpo_oprcion := ''U'';
                                    v_operacion   := ''Actualización'';
                                else
                                    v_tpo_oprcion := ''D'';
                                    v_operacion   := ''Eliminación'';
                            end case;
                            v_json := ' ||
                 '''{"operacion": "''|| v_operacion || ''", ' || v_json || '
              
                            v_id_auditoria := sq_ad_g_audit_trail.nextval;
              
              insert into ad_g_audit_trail(
                  id_auditoria
                , nmbre_tbla
                , id_llve_prmria
                , tpo_oprcion
                , json
                , usrio
                , fecha
                , host
                , ip_address
                , server_host
                , os_user
                , terminal
                , authentication_method
                , proxy_user
                , proxy_userid)
              values(v_id_auditoria' || ', ' || '''' ||
                 p_table_name || ''', ' || 'nvl(:new.' || j.column_name_pk ||
                 ', :old.' || j.column_name_pk || '),
                 v_tpo_oprcion,
                 v_json,
                 coalesce( sys_context(''APEX$SESSION'',''app_user''), regexp_substr(sys_context(''userenv'',''client_identifier''),''^[^:]*''), sys_context(''userenv'',''session_user'') )' || ', ' ||
                 'systimestamp,
                 sys_context(''userenv'',''host''), 
                 sys_context(''userenv'',''ip_address''),
                 sys_context(''userenv'',''server_host''),
                 sys_context(''userenv'',''os_user''),
                 sys_context(''userenv'',''terminal''),
                 sys_context(''userenv'',''authentication_method''),
                 sys_context(''userenv'',''proxy_user''),
                 sys_context(''userenv'',''proxy_userid'') );

          end after each row;

          end;';
      
        --execute immediate v_ddl;
        v_c := dbms_sql.open_cursor;
        dbms_sql.parse(v_c, v_ddl, dbms_sql.native);
        v_r := dbms_sql.execute(v_c);
        dbms_sql.close_cursor(v_c);
      
        v_rspsta := 'OK. Trigger creado con Éxito';
      end loop; -- For j
    
      if v_ddl is null then
        v_rspsta := 'Tabla No Existe ó No tiene llave Primaria';
      end if;
    
    elsif p_indcdor_actvo = 'N' then
      -- Procedemos a eliminar el triger de Auditoria
    
      v_ddl            := null;
      v_nombre_trigger := p_table_name || '_AD';
    
      begin
        select table_name
          into v_temp
          from all_triggers
         where trigger_name = v_nombre_trigger;
      
        v_ddl := v_ddl || 'alter trigger ' || p_table_name ||
                 '_AD disable ';
        v_c   := dbms_sql.open_cursor;
        dbms_sql.parse(v_c, v_ddl, dbms_sql.native);
        v_r := dbms_sql.execute(v_c);
        dbms_sql.close_cursor(v_c);
      
        v_rspsta := 'OK. Trigger deshabilitado con Éxito';
      exception
        when no_data_found then
          v_rspsta := 'Trigger No existe';
        when others then
          v_rspsta := sqlerrm;
      end;
    
    end if;
  
    return v_rspsta;
  
  end;

  function fnc_co_tabla_auditoria(p_nmbre_tbla  in varchar2,
                                  p_tpo_oprcion in varchar2 default null,
                                  p_fcha_incio  in date,
                                  p_fcha_fin    in date,
                                  p_id_usrio    in varchar2 default null)
    return clob
  
   is
  
    v_column clob;
    v_sql    clob := 'select 1 from dual';
  begin
  
    select listagg(chr(39) || nmbre_cmpo || chr(39) || ' as "' ||
                   nmbre_cmpo || '"',
                   ', ') within group(order by nmbre_cmpo)
      into v_column
      from (select nmbre_cmpo
              from ad_g_audit_trail a
              left join v_sg_g_usuarios c
                on to_char(c.user_name) = a.usrio
              join json_table(json, '$.campos[*]' columns(nmbre_cmpo varchar2 path '$.nmbre_cmpo', old varchar2 path '$.old', new varchar2 path '$.new')) b
                on 1 = 1
             where a.nmbre_tbla = upper(p_nmbre_tbla)
               and a.tpo_oprcion = nvl(p_tpo_oprcion, a.tpo_oprcion)
               and a.usrio = nvl(p_id_usrio, a.usrio)
               and a.fecha between p_fcha_incio and p_fcha_fin
             group by nmbre_cmpo) a;
  
    v_sql := 'select * from (
                            select a.id_auditoria "Numero Auditoria"                            
                                 , nvl(c.nmbre_trcro, a.usrio) as "Usuario Operación"
                                 , a.fecha as "Fecha Operación"
                                 , decode(a.tpo_oprcion, ''I'', ''Registro'', ''U'', ''Actualización'', ''Eliminación'' ) as "Operación"
                                 , b.* 
                              from ad_g_audit_trail a
                         left join v_sg_g_usuarios c 
                                on to_char(c.user_name) = a.usrio
                              join json_table(json, ''$.campos[*]'' 
                                            columns (nmbre_cmpo varchar2 path ''$.nmbre_cmpo'',
                                                     old        varchar2 path ''$.old'',    
                                                     new        varchar2 path ''$.new''
                                                    )
                                             ) b on 1 = 1 
                             where nmbre_tbla = upper(''' ||
             p_nmbre_tbla || ''')
                              and a.usrio = nvl(''' ||
             p_id_usrio ||
             ''', a.usrio) 
                              and a.tpo_oprcion =  nvl(''' ||
             p_tpo_oprcion || ''',a.tpo_oprcion)
                              and a.fecha 
                          between ''' || p_fcha_incio || '''
                              and ''' || p_fcha_fin || '''
                            )
                            pivot 
                                (
                                   max(old) as anterior ,max(new) as nuevo
                                   for nmbre_cmpo in ( ' ||
             v_column || ' )
                                )
                  ;';
    return v_sql;
  
  end fnc_co_tabla_auditoria;

end;

/
