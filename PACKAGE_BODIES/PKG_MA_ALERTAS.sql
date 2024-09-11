--------------------------------------------------------
--  DDL for Package Body PKG_MA_ALERTAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MA_ALERTAS" as
  /*Procedimiento para registrar alerta*/
  procedure prc_rg_alerta(
    p_id_alrta_tpo          in  ma_g_alertas.id_alrta_tpo%type,
    p_id_envio_mdio         in  ma_g_alertas.id_envio_mdio%type,
    p_id_usrio              in  ma_g_alertas.id_usrio%type,
    p_ttlo                  in  ma_g_alertas.ttlo%type,
    p_dscrpcion             in  ma_g_alertas.dscrpcion%type,
    p_url                   in  ma_g_alertas.url%type               default null,
    p_fcha_rgstro           in  ma_g_alertas.fcha_rgstro%type       default systimestamp,
    p_indcdor_vsto          in  ma_g_alertas.indcdor_vsto%type      default 'N',
    p_id_alrta_estdo        in  ma_g_alertas.id_alrta_estdo%type    default null,
    o_id_alrta              out ma_g_alertas.id_alrta%type,
    o_cdgo_rspsta	        out number,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                             exception;
    --Registro en Log
    v_nl                                number;
    v_mnsje_log                         varchar2(4000);
    v_nvl                               number;
    v_id_alrta_estdo                    ma_d_alertas_estado.id_alrta_estdo%type;
  begin
    o_cdgo_rspsta := 0;
    
    --Consultamos el estado enviado si p_id_alrta_estdo viene vacio
    begin
        select id_alrta_estdo
        into v_id_alrta_estdo
        from ma_d_alertas_estado
        where cdgo_estdo = 'ENV' and
              actvo      = 'S';
    exception
        when no_data_found then
            raise_application_error(-20001, 'Problemas consultar estado de alerta, '||sqlerrm);
    end;
    
    insert into ma_g_alertas(          
        id_alrta_tpo,	           
        id_envio_mdio,	       
        id_usrio,		        
        ttlo,			
        dscrpcion,		
        url,			
        fcha_rgstro,	   
        indcdor_vsto,	     		
        id_alrta_estdo
    ) values(
        p_id_alrta_tpo,	           
        p_id_envio_mdio,	       
        p_id_usrio,		        
        p_ttlo,			
        p_dscrpcion,		
        p_url,			
        p_fcha_rgstro,	   
        p_indcdor_vsto,	     		
        nvl(p_id_alrta_estdo, v_id_alrta_estdo)
    )returning id_alrta into o_id_alrta;
    
    commit;
  exception
    when others then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Problemas al registrar alerta, '||sqlerrm;
        rollback;
  end prc_rg_alerta;
  
  /*Actualiza estado de la alerta*/
  procedure prc_ac_alerta_estado(
    p_id_alrta             in   ma_g_alertas.id_alrta%type
  )as
    v_id_alrta_estdo                    ma_d_alertas_estado.id_alrta_estdo%type;
  begin
  
    --Consultamos el estado de la alerta
    begin
        select id_alrta_estdo
        into v_id_alrta_estdo
        from ma_d_alertas_estado
        where cdgo_estdo = 'VST' and
              actvo      = 'S';
    exception
        when no_data_found then
            raise_application_error(-20001, 'Problemas consultar estado de alerta, '||sqlerrm);
    end;
    
    --Actualizamos el estado de la alerta
    update ma_g_alertas
    set indcdor_vsto    = 'S',
        fcha_vsto       = systimestamp,
        id_alrta_estdo  = v_id_alrta_estdo
    where id_alrta = p_id_alrta and
          id_usrio = v('F_ID_USRIO');
          
  exception
    when others then
        DBMS_OUTPUT.PUT_LINE(sqlerrm);
  end prc_ac_alerta_estado;
end pkg_ma_alertas;

/
