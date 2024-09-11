--------------------------------------------------------
--  DDL for Package Body PKG_MA_ENVIOS_MEDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MA_ENVIOS_MEDIO" as
  /*Procedimiento para enviar SMS*/  
  procedure prc_rg_sms(
    p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
    o_cdgo_rspsta	out number,
    o_mnsje_rspsta  out varchar2
  ) as
    --Manejo de Errores
    v_error                             exception;
    --Registro en Log
    v_nl                                number;
    v_mnsje_log                         varchar2(4000);
    v_nvl                               number;
    --
    v_rt_ma_g_envios_medio              ma_g_envios_medio%rowtype;
    v_rt_ma_d_envios_medio_cnfgrcion    ma_d_envios_medio_cnfgrcion%rowtype;
    v_json_parametros                   clob;
    v_json_prfrncias                    clob;
    --Parametros
    v_api_url                           varchar2(2000);
    v_usrnme                            varchar2(500);
    v_password                          varchar2(500);
    v_indctvo                           varchar2(5);
    --
    v_json_request                      clob;
    v_json_respuesta                    clob;
    --
    v_cdgo_envio_estdo                  varchar2(3);
  begin
    o_cdgo_rspsta   := 0;

    --Consultamos las configuraciones
    pkg_ma_envios.prc_co_configuraciones(
        p_id_envio_mdio                     => p_id_envio_mdio,
        o_rt_ma_g_envios_medio              => v_rt_ma_g_envios_medio,
        o_rt_ma_d_envios_medio_cnfgrcion    => v_rt_ma_d_envios_medio_cnfgrcion,
        o_json_parametros                   => v_json_parametros,
        o_json_preferencias                 => v_json_prfrncias,
        o_cdgo_rspsta			            => o_cdgo_rspsta,
        o_mnsje_rspsta                      => o_mnsje_rspsta
    );
    
    --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;
    
    --Obtenermos los parametros de configuracion
    v_api_url   := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'API_URL');
    v_usrnme    := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'USRNME');
    v_password  := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'PASSWORD');
    v_indctvo   := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'INDCTVO');
    
    
    --Definimos el cuerpo de la peticion
    select json_object(
        key 'to'   is json_arrayagg(v_indctvo||v_rt_ma_g_envios_medio.dstno),
        key 'text' is v_rt_ma_g_envios_medio.txto_mnsje,
        key 'from' is 'msg'
    )into v_json_request
    from dual;
    
    --Definimos la cabecera de la peticion
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    apex_web_service.g_request_headers(2).name  := 'Authorization';
    apex_web_service.g_request_headers(2).value := 'Basic '||pkg_gn_generalidades.fnc_ge_to_base64(v_usrnme||':'||v_password);
    
    --Realizamos la peticion
    v_json_respuesta := apex_web_service.make_rest_request(
      p_url         => v_api_url,
      p_http_method => 'POST',
      p_body        => v_json_request
    );
    
    if(json_value(v_json_respuesta, '$.accepted' default 'false' on error) = 'true')then
        v_cdgo_envio_estdo := 'ENV';
    else
        v_cdgo_envio_estdo := 'ERR';
    end if;
    
    --Actualizamos el estado
    pkg_ma_envios.prc_rg_envio_estado(p_id_envio_mdio             => p_id_envio_mdio,
                                      p_cdgo_envio_estdo          => 'ENV',
                                      p_obsrvcion                 => v_json_respuesta,
                                      o_cdgo_rspsta			      => o_cdgo_rspsta,
                                      o_mnsje_rspsta              => o_mnsje_rspsta);
                        
   --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
       raise v_error;
    end if;
    
  exception
    when v_error then
        if(o_cdgo_rspsta = 0)then
           o_cdgo_rspsta := 1;
        end if;
    when others then
       o_cdgo_rspsta := 1;
       o_mnsje_rspsta := sqlerrm;
  end prc_rg_sms;
  
  procedure prc_rg_mail(
    p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
    o_cdgo_rspsta	out number,
    o_mnsje_rspsta  out varchar2
  ) as
    --Manejo de Errores
    v_error                             exception;
    --Registro en Log
    v_nl                                number;
    v_mnsje_log                         varchar2(4000);
    v_nvl                               number;
    --
    v_rt_ma_g_envios_medio              ma_g_envios_medio%rowtype;
    v_rt_ma_d_envios_medio_cnfgrcion    ma_d_envios_medio_cnfgrcion%rowtype;
    v_json_parametros                   clob;
    v_json_prfrncias                    clob;
    
    v_server_port                       varchar2(4);
    v_smtp_srver                        varchar2(1000);
    v_smtp_usrnme                       varchar2(1000);
    v_smtp_password                     varchar2(1000);
    v_workspace_id                      varchar2(1000);
    
    v_id_mail                           number;
    v_body                              clob;
    
    v_cdgo_prvdres_envio                ma_d_proveedores_envio.cdgo_prvdres_envio%type;
    v_id_prvdor                         ws_d_provedores_api.id_prvdor%type;
    v_cdgo_clnte                        number;
    o_location                          varchar2(4000);
    v_mnsje                             clob;
    v_total                             number;
    v_count                             number; 
    
     v_crlf                             varchar(10) := chr(13)||chr(10); 
     v_txto_mnsje                       ma_g_envios_medio.txto_mnsje%type;
     v_mnsaje_comprimido                ma_g_envios_medio.txto_mnsje%type;
     
  begin
    o_cdgo_rspsta   := 0;
    
   
    --consultamos el proveedor de correo electronico
    begin
        select a.cdgo_clnte, b.cdgo_prvdres_envio 
        into   v_cdgo_clnte, v_cdgo_prvdres_envio 
        from ma_d_envios_medio_cnfgrcion a join ma_d_proveedores_envio b 
                                on b.id_prvdres_envio = a.id_prvdres_envio
        where cdgo_envio_mdio = 'EML';
    exception
        when others then
            v_cdgo_prvdres_envio := 'APMAIL';
    end;
    
    --Consultamos las configuraciones
    pkg_ma_envios.prc_co_configuraciones(
        p_id_envio_mdio                     => p_id_envio_mdio,
        o_rt_ma_g_envios_medio              => v_rt_ma_g_envios_medio,
        o_rt_ma_d_envios_medio_cnfgrcion    => v_rt_ma_d_envios_medio_cnfgrcion,
        o_json_parametros                   => v_json_parametros,
        o_json_preferencias                 => v_json_prfrncias,
        o_cdgo_rspsta			            => o_cdgo_rspsta,
        o_mnsje_rspsta                      => o_mnsje_rspsta
    );

    --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;
    
    --Obtenermos los parametros de configuracion
    v_server_port       := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'SERVER_PORT');
    v_smtp_srver        := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'SMTP_SRVER');
    v_smtp_usrnme       := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'SMTP_USRNME');
    v_smtp_password     := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'SMTP_PASSWORD');
    v_workspace_id      := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'WORKSPACE_ID');
    
 
    v_body := 'Para ver el contenido de este mensaje, use un cliente de correo habilitado para HTML.';
    
    --Utilizamos el procedimiento para poder llamar apex_mail por fuera de Apex
    apex_util.set_security_group_id(p_security_group_id => v_workspace_id);
    
    if v_cdgo_prvdres_envio = 'APMAIL' then -- Si es APEX MAIL
    
            v_txto_mnsje := replace(v_rt_ma_g_envios_medio.txto_mnsje, v_crlf, '');
  
             --Enviamos el mail
            v_id_mail := apex_mail.send(p_to        => v_rt_ma_g_envios_medio.dstno,
                                        p_from      => v_smtp_usrnme,  
                                        p_subj      => v_rt_ma_g_envios_medio.asnto,
                                        p_body      => v_body,
                                        p_body_html => v_txto_mnsje);
                                       -- p_body_html => v_rt_ma_g_envios_medio.txto_mnsje);
            
            --Adjuntamos los archivos asociados al envio
            for c_adjuntos in (select file_blob,
                                      file_name,
                                      file_mimetype,
                                      file_bfile
                               from ma_g_envios_adjntos
                               where id_envio = v_rt_ma_g_envios_medio.id_envio) loop
                
                --Adjuntamos el archivo
                apex_mail.add_attachment(p_mail_id    => v_id_mail,
                                         p_attachment => c_adjuntos.file_blob,
                                         p_filename   => c_adjuntos.file_name,
                                         p_mime_type  => c_adjuntos.file_mimetype);
            end loop;
            
            --Realizamos el push
            apex_mail.push_queue(p_smtp_hostname => v_smtp_srver,
                                 p_smtp_portno   => v_server_port);
    
    elsif v_cdgo_prvdres_envio = 'MJET' then  -- Si es MailJet
    
      
        select  id_prvdor 
        into v_id_prvdor
        from ws_d_provedores_api a
        where  a.cdgo_api      = 'MJET';
        
        
  
         v_mnsje := substr(v_rt_ma_g_envios_medio.txto_mnsje,1,length(v_rt_ma_g_envios_medio.txto_mnsje)-2);
         v_mnsje := replace(v_mnsje, v_crlf, '');
         v_mnsje := replace(v_mnsje, chr(34), '');  --comilla doble
         v_mnsje := replace(v_mnsje, chr(32), ' '); 
         v_mnsje := replace(v_mnsje, chr(9), ''); 
         
         
         begin
         v_mnsaje_comprimido := pkg_ws_MailJet.fnc_minify_html(p_html => v_mnsje);
         exception
            when others then 
                raise v_error;
         end;
         
        v_body := '{
               "Messages":[
                  {
                     "From":{
                        "Email":"'||v_smtp_usrnme||'",
                        "Name":"'||v_smtp_usrnme||'"
                     },
                     "To":[
                        {
                           "Email":"'||v_rt_ma_g_envios_medio.dstno||'",
                           "Name":"'||v_rt_ma_g_envios_medio.dstno||'"
                        }
                     ],
                     "Subject":"'|| v_rt_ma_g_envios_medio.asnto||'",
                     "HTMLPart":"'||v_mnsaje_comprimido||'",
                     "TextPart":"Saludos desde Postman",' ||
                     '"EventPayload": "cdgo_clnte: ' || v_cdgo_clnte || '"';
                    
					select  count(1)
                    into v_total
					from ma_g_envios_adjntos
					where id_envio = v_rt_ma_g_envios_medio.id_envio;
			
					if v_total > 0 then 
                        v_count := 0 ;
						v_body :=  v_body || ',"Attachments": [';
							
						for c_adjuntos in (select file_blob,
                                                  file_name,
                                                  file_mimetype,
                                                  file_bfile
                                           from ma_g_envios_adjntos
                                           where id_envio = v_rt_ma_g_envios_medio.id_envio
                                           ) loop
					   
                            v_body :=  v_body || '
							{
                            "ContentType":"'||c_adjuntos.file_mimetype||'",
							"Filename":"'||c_adjuntos.file_name||'",
                            "Base64Content":"'||pkg_gn_generalidades.fnc_cl_convertir_blob_a_base64( p_blob => c_adjuntos.file_blob )||' "
							}'; 
                            
                            v_count := v_count + 1;
                            if v_count < v_total then
                                v_body := v_body || ',';
                            end if;
                            
						end loop; 
						v_body :=  v_body || '] ';
					end if;
							 
			v_body :=  v_body || '
                  }
               ]
            }'; 
---"Base64Content": "VGhpcyBpcyB5b3VyIGF0dGFjaGVkIGZpbGUhISEK"   
 /*       -- body bueno
        v_body := '{
               "Messages":[
                  {
                     "From":{
                        "Email":"notiindustriaycomercio@impuestosoledad-atlantico.gov.co",
                        "Name":"Soledad"
                     },
                     "To":[
                        {
                           "Email":"'||v_rt_ma_g_envios_medio.dstno||'",
                           "Name":"'||v_rt_ma_g_envios_medio.dstno||'"
                        }
                     ],
                     "Subject":"'|| v_rt_ma_g_envios_medio.asnto||'",
                     "HTMLPart":"'||v_mnsje||'",
                     "TextPart":"Saludos desde Postman" ,
                    
                    
                     "Attachments": [
							{
									"ContentType": "text/plain",    --c_adjuntos.file_mimetype
									"Filename": "test.txt",			-- c_adjuntos.file_name
									"Base64Content": "VGhpcyBpcyB5b3VyIGF0dGFjaGVkIGZpbGUhISEK"
							}
					]
                    
                    
                  }
               ]
            }'; 
*/

--"HTMLPart":"'||v_rt_ma_g_envios_medio.txto_mnsje||'"  -- genera error de formato de json  ojoooo le deja un espacio al final antes de poner las comillas dobles
 

   --insert into muerto (n_001, v_001, c_001, t_001) values (7777,'v_body',v_body, sysdate ); commit;
  -- insert into muerto (n_001, v_001, c_001, t_001) values (7777,'v_mnsje',v_mnsje, sysdate ); commit;
   --insert into muerto (n_001, v_001, c_001, t_001) values (7777,'txto_mnsje',v_rt_ma_g_envios_medio.txto_mnsje, sysdate ); commit;
   --insert into muerto (n_001, v_001, c_001, t_001) values (7777,'txto_mnsje ascii',ascii(SUBSTR(v_rt_ma_g_envios_medio.txto_mnsje,length(v_rt_ma_g_envios_medio.txto_mnsje),1)), sysdate ); commit;
            pkg_ws_mailjet.prc_ws_iniciar_transaccion(  p_cdgo_clnte    => v_cdgo_clnte,
                                                        p_id_prvdor     => v_id_prvdor,
                                                        p_cdgo_api      => v_cdgo_prvdres_envio, 
                                                        p_body          => v_body,
                                                        p_id_envio_mdio => p_id_envio_mdio,
                                                        o_location      => o_location,
                                                        o_cdgo_rspsta   => o_cdgo_rspsta,
                                                        o_mnsje_rspsta  => o_mnsje_rspsta
              );
              
                 --Validamos si hubo errores
                if(o_cdgo_rspsta != 0)then
                   raise v_error;
                end if;
  
    dbms_output.put_line('o_location: ' || o_location);
                    
      end if;
    
 
    --Actualizamos el estado
    pkg_ma_envios.prc_rg_envio_estado(p_id_envio_mdio             => p_id_envio_mdio,
                                      p_cdgo_envio_estdo          => 'ENV',
                                      p_obsrvcion                 => null,
                                      o_cdgo_rspsta			      => o_cdgo_rspsta,
                                      o_mnsje_rspsta              => o_mnsje_rspsta);
                        
   --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
       raise v_error;
    end if;
    
    dbms_output.put_line('Respuesta del cambio de estado: ' || o_cdgo_rspsta);
   
  exception
    when v_error then
        if(o_cdgo_rspsta = 0)then
           o_cdgo_rspsta := 1;
        end if;
    when others then
       o_cdgo_rspsta := 1;
       o_mnsje_rspsta := sqlerrm;   
  end prc_rg_mail;

 

  /*Procedimiento para registrar Alerta*/
  procedure prc_rg_alerta(
    p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
    o_cdgo_rspsta	out number,
    o_mnsje_rspsta  out varchar2
  ) as
    --Manejo de Errores
    v_error                             exception;
    --Registro en Log
    v_nl                                number;
    v_mnsje_log                         varchar2(4000);
    v_nvl                               number;
    --
    v_rt_ma_g_envios_medio              ma_g_envios_medio%rowtype;
    v_rt_ma_d_envios_medio_cnfgrcion    ma_d_envios_medio_cnfgrcion%rowtype;
    v_json_parametros                   clob;
    v_json_preferencias                 clob;
    v_id_alrta                          ma_g_alertas.id_alrta%type;
    v_id_alrta_tpo                      ma_g_alertas.id_alrta_tpo%type;
    v_url_alrta                         ma_g_alertas.url%type;
    v_url_server                        varchar2(1000);
    v_json_request                      clob;
    v_json_respuesta                    clob;
  begin
    o_cdgo_rspsta   := 0;
    
    --Consultamos las configuraciones
    pkg_ma_envios.prc_co_configuraciones(
        p_id_envio_mdio                     => p_id_envio_mdio,
        o_rt_ma_g_envios_medio              => v_rt_ma_g_envios_medio,
        o_rt_ma_d_envios_medio_cnfgrcion    => v_rt_ma_d_envios_medio_cnfgrcion,
        o_json_parametros                   => v_json_parametros,
        o_json_preferencias                 => v_json_preferencias,
        o_cdgo_rspsta			            => o_cdgo_rspsta,
        o_mnsje_rspsta                      => o_mnsje_rspsta
    );
    
    --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;
    
    --Obtenermos los parametros de configuracion
    v_url_server := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'URL_SERVER');
    
    --Obtenemos las preferencias
    v_id_alrta_tpo  := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_preferencias, p_prmtro => 'TPO_ALRTA');
    v_url_alrta     := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_preferencias, p_prmtro => 'URL');
    
    --Registramos la alerta
    pkg_ma_alertas.prc_rg_alerta(p_id_alrta_tpo         => v_id_alrta_tpo,
                                 p_id_envio_mdio        => p_id_envio_mdio,
                                 p_id_usrio             => v_rt_ma_g_envios_medio.dstno,
                                 p_ttlo                 => v_rt_ma_g_envios_medio.asnto,
                                 p_dscrpcion            => v_rt_ma_g_envios_medio.txto_mnsje,
                                 p_url                  => v_url_alrta,
                                 o_id_alrta             => v_id_alrta,
                                 o_cdgo_rspsta	        => o_cdgo_rspsta,
                                 o_mnsje_rspsta         => o_mnsje_rspsta);
    --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;
    
    
    --Definimos el cuerpo de la peticion
    select json_object(
        key 'title' is v_rt_ma_g_envios_medio.asnto,
        key 'body'  is v_rt_ma_g_envios_medio.txto_mnsje
    )into v_json_request
    from dual;
    
    
    
    --Definimos la cabecera de la peticion
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    
    
    insert into gti_aux (col1, col2) values ('v_url_server: ', v_url_server);
    insert into gti_aux (col1, col2) values ('v_rt_ma_g_envios_medio.dstno: ', v_rt_ma_g_envios_medio.dstno);
    insert into gti_aux (col1, col2) values ('v_json_request: ', v_json_request);
    commit;
    
    --Realizamos la peticion
    v_json_respuesta := apex_web_service.make_rest_request(
      p_url         => v_url_server||'/'||v_rt_ma_g_envios_medio.dstno,
      p_http_method => 'POST',
      p_body        => v_json_request
    );
    
    insert into gti_aux (col1, col2) values ('v_json_respuesta: ', v_json_respuesta);
    
    --Actualizamos el estado
    pkg_ma_envios.prc_rg_envio_estado(p_id_envio_mdio             => p_id_envio_mdio,
                                      p_cdgo_envio_estdo          => 'ENV',
                                      p_obsrvcion                 => null,
                                      o_cdgo_rspsta			      => o_cdgo_rspsta,
                                      o_mnsje_rspsta              => o_mnsje_rspsta);
                        
   --Validamos si hubo errores
    if(o_cdgo_rspsta != 0)then
       raise v_error;
    end if;
    
  exception
    when v_error then
        if(o_cdgo_rspsta = 0)then
           o_cdgo_rspsta := 1;
        end if;
         --Actualizamos el estado
        pkg_ma_envios.prc_rg_envio_estado(p_id_envio_mdio             => p_id_envio_mdio,
                                          p_cdgo_envio_estdo          => 'ERR',
                                          p_obsrvcion                 => o_mnsje_rspsta,
                                          o_cdgo_rspsta			      => o_cdgo_rspsta,
                                          o_mnsje_rspsta              => o_mnsje_rspsta);
    when others then
       o_cdgo_rspsta := 1;
       o_mnsje_rspsta := sqlerrm;
       --Actualizamos el estado
       pkg_ma_envios.prc_rg_envio_estado(p_id_envio_mdio             => p_id_envio_mdio,
                                          p_cdgo_envio_estdo          => 'ERR',
                                          p_obsrvcion                 => o_mnsje_rspsta,
                                          o_cdgo_rspsta			      => o_cdgo_rspsta,
                                          o_mnsje_rspsta              => o_mnsje_rspsta);
  end prc_rg_alerta;

  
end pkg_ma_envios_medio;

/
