--------------------------------------------------------
--  DDL for Package Body PKG_SG_LOG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SG_LOG" as

  -- Inserta el texto de Log, de acuerdo al nivel configurado
  -- p_nvel_log  configuracion de nivel Log para la UP,
  -- p_txto_log   Texto del Log, 
  -- p_nvel_txto Nivel de log seteado por default por el programador para ese Texto. Este nivel esta a nivel de codigo duro

  procedure prc_rg_log(p_cdgo_clnte number,
                       p_id_impsto  number,
                       p_nmbre_up   varchar2,
                       p_nvel_log   number,
                       p_txto_log   sg_g_log.txto_log%type,
                       p_nvel_txto  varchar2) IS
    PRAGMA autonomous_transaction;

    -- Inserta el texto de Log, de acuerdo al nivel configurado
    -- p_nvel_log   configurado de nivel Log para la UP,
    -- p_txto_log   Texto del Log, 
    -- p_nvel_txto  Nivel de log seteado por default por el programador para ese Texto. Este nivel esta a nivel de codigo duro

    v_id_log sg_g_log.id_log%type;

  begin
    if p_nvel_log >= p_nvel_txto then
      -- Insertamos el texto de Log
      insert into sg_g_log
        (id_log, fcha_log, cdgo_clnte, id_impsto, nmbre_up, txto_log)
      values
        (scq_log.nextval,
         systimestamp,
         p_cdgo_clnte,
         p_id_impsto,
         p_nmbre_up,
         p_txto_log);
    end if;
    commit;
  end;

  -- Obtiene el nivel de Log configurado para la UP (p_nmbre_up) de un impuesto , de un cliente
  function fnc_ca_nivel_log(p_cdgo_clnte number,
                            p_id_impsto  number,
                            p_nmbre_up   varchar2) return number as

    v_nvel_log sg_d_configuraciones_log.nvel_log%type;

  begin
    begin
      select max(nvel_log)
        into v_nvel_log
        from sg_d_configuraciones_log
       where cdgo_clnte = p_cdgo_clnte
         and (id_impsto = p_id_impsto or p_id_impsto is null)
         and nmbre_up = upper(p_nmbre_up);
    exception
      when no_data_found then
        -- Si no existe configuracion de LOG para la UP (p_nmbre_up), seteamos el nivel de log en Cero (0)
        v_nvel_log := 0;
    end;

    return v_nvel_log;
  end;

  -- Esta unidad pobla la entidad de configuracion de Niveles Log a trazar por las Unidades de Programa
  procedure prc_rg_configuraciones_log(p_cdgo_clnte number,
                                       p_nmbre_up   varchar2 default null,
                                       p_nvel_log   number default 0) as

    v_nmbre_up            sg_d_configuraciones_log.nmbre_up%type;
    d                     number;
    v_count_cnfgrcnes_log number;

  begin
    -- Recorremos todas las Unidades de programas
    for i in (select object_name, procedure_name, object_type
                from (select *
                        from user_procedures
                       where object_type = 'PROCEDURE'
                      union
                      select *
                        from user_procedures
                       where object_type = 'FUNCTION'
                      union
                      select *
                        from user_procedures
                       where object_type = 'PACKAGE'
                         and object_name like 'PK%'
                         and subprogram_id > 0)
               where upper(object_name) like upper('%' || p_nmbre_up || '%')
                  or p_nmbre_up is null
               order by object_type, object_id, subprogram_id) loop

      -- Armamos el nombre de la UP,  i.procedure_name tiene dato solo para funciones o procedure de los paquetes
      v_nmbre_up := trim(i.object_name || '.' || i.procedure_name);

      -- Buscamos si la UP existe para ese cliente
      begin
        select 1
          into v_count_cnfgrcnes_log
          from sg_d_configuraciones_log
         where cdgo_clnte = p_cdgo_clnte
           and nmbre_up = v_nmbre_up;

      exception
        when no_data_found then
          select nvl(max(id_cnfgrcion_log) + 1, 1)
            into d
            from sg_d_configuraciones_log;

          -- Insertamos
          insert into sg_d_configuraciones_log
            (id_cnfgrcion_log, cdgo_clnte, nmbre_up, tpo_up, nvel_log)
          values
            (d, p_cdgo_clnte, v_nmbre_up, i.object_type, p_nvel_log);
      end;

    end loop;
    -- Comitamos el proceso
    commit;
  end;
end;

/
