--------------------------------------------------------
--  DDL for Package Body PKG_SG_AUTENTICACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SG_AUTENTICACION" is 

-- fnc_sg_hash
function fnc_sg_hash (p_username in varchar2, 
                      p_password in varchar2)
return varchar2
is
  l_password varchar2(4000);
  l_salt varchar2(4000) := 'PMI1Y3VP3QIH53J4UB44DBBN1CIZW9';
begin

	-- This function should be wrapped, as the hash algorhythm is exposed here.
	-- You can change the value of l_salt or the method of which to call the
	-- DBMS_OBFUSCATOIN toolkit, but you much reset all of your passwords
	-- if you choose to do this.

	l_password :=	utl_raw.cast_to_raw(dbms_obfuscation_toolkit.md5
					(input_string => p_password || substr(l_salt,10,13) || p_username || substr(l_salt, 4,10)));

	return l_password;
end;

function fnc_ge_token(p_cdna in varchar2)
return varchar2
is
    l_salt varchar2(4000) := 'PMI1Y3VP3QIH53J4UB44DBBN1CIZW9';
begin
    return pkg_gn_generalidades.fnc_ge_to_base64( t => dbms_crypto.hash( utl_raw.cast_to_raw( substr( l_salt , 10 , 13 ) || p_cdna || substr( l_salt , 4 , 10 )), dbms_crypto.hash_sh1 /*hash_sh256*/ ));
end fnc_ge_token;

procedure prc_cd_token(
    p_cdgo_clnte      in     number,
    p_id_usrio        in     number,
    p_app_session     in     varchar2,
    p_accion          in     varchar2,
    o_id_usrio_tken   in out varchar2,
    o_cdgo_rspsta	     out number,
    o_mnsje_rspsta       out varchar2
) as
    v_id_usrio_tken sg_g_usuarios_token.id_usrio_tken%type;
    v_undad_drcion  df_c_definiciones_cliente.vlor%type;
    v_drcion        df_c_definiciones_cliente.vlor%type;
    v_time          number;
begin
    o_cdgo_rspsta := 0;

    --Consultamos las definiciones
    v_undad_drcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte 				    => p_cdgo_clnte,
                                                                      p_cdgo_dfncion_clnte_ctgria	=> 'SGR',
                                                                      p_cdgo_dfncion_clnte		    => 'UTK');

    --Valor por Defecto Hora
    v_undad_drcion := ( case when v_undad_drcion <> '-1' then v_undad_drcion else 'HR' end );

    v_drcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte 				=> p_cdgo_clnte,
                                                                p_cdgo_dfncion_clnte_ctgria	=> 'SGR',
                                                                p_cdgo_dfncion_clnte		=> 'DTK');

    --Valor por Defecto 24 horas
    v_drcion := ( case when v_drcion <> '-1' then v_drcion else '24' end );

    --Calcula el Tiempo en Segundo
    v_time := round(( cast( pk_util_calendario.fnc_cl_fecha_final( p_fecha_inicial => systimestamp
                                                                 , p_undad_drcion  => v_undad_drcion
                                                                 , p_drcion        => v_drcion ) as date ) - sysdate ) * (24 * 3600));

    --Genaramos el token
    o_id_usrio_tken := apex_jwt.encode ( p_iss           => p_app_session
                                       , p_sub           => p_id_usrio
                                       , p_exp_sec       => v_time
                                       , p_other_claims  => '"cdgo_clnte": '||apex_json.stringify(p_cdgo_clnte)
                                       , p_signature_key => pkg_sg_autenticacion.g_signature_key );
exception
    when others then
       o_cdgo_rspsta := 1;
       o_mnsje_rspsta := 'Error al gestionar token, '||sqlerrm;
end prc_cd_token;


-- gti_seg_autenticar
function fnc_sg_autenticar (p_username in number, 
                            p_password in varchar2) 
return boolean
is

	l_clave varchar2(4000);
	l_password varchar2(4000);
	l_stored_password varchar2(4000);
	l_expires_on date;
	l_admin number;
	l_count number;

    v_cdgo_clnte number;
    v_id_aplccion_grpo      sg_g_aplicaciones_grupo.id_aplccion_grpo%type;
	v_seg_autenticar boolean := false;

begin

	l_clave             := SUBSTR(p_password,1,INSTR(p_password,'|')-1) ;
    v_cdgo_clnte	    := SUBSTR(p_password,INSTR(p_password,'|',1,1)+1,(INSTR(p_password,'|',1,2) - INSTR(p_password,'|',1,1)-1));
    v_id_aplccion_grpo  := SUBSTR(p_password,INSTR(p_password,'|',1,2)+1);

	-- delete gti_aux;
	insert into gti_aux (col1, col2)
	values (1, 'p_username: ' || p_username || ' - l_clave: ' || l_clave || ' - v_cdgo_clnte: ' ||v_cdgo_clnte);
	commit;

	-- Primero, chequemaos si el usuario esta en la tabla de USUARIOS
	-- select count(*) into l_count from v_sg_g_usuarios where cdgo_clnte = v_cdgo_clnte and lower(user_name) = lower(p_username);
    select count(*) into l_count from v_sg_g_usuarios where cdgo_clnte = v_cdgo_clnte and user_name = lower(p_username);

	-- Usuario en Tabla de USUARIOS
	if l_count > 0 then

		-- Extraemos el password encriptado y la fecha de expiraciÃƒÂ³n
		select password, fcha_exprcion, admin  into l_stored_password, l_expires_on, l_admin
	  	  from v_sg_g_usuarios
		 where cdgo_clnte = v_cdgo_clnte and user_name = lower(p_username);

		-- Obtener el password encriptado y compararlo con el password encriptado almacenado
		l_password := fnc_sg_hash(lower(p_username), l_clave);

		-- Finalmente,  comparamos los password:  Almacenado e Introducido por el usuario
		if l_password = l_stored_password then
			v_seg_autenticar := true;
			insert into gti_aux (col1, col2) values (4, 'Claves iguales');
			commit;

			-- Si el Usuario es Administrador
			if l_admin = 1 then
				v_seg_autenticar := true;
			else
				-- Si Usuario No Es Administrador

				-- Chequemos si la Cuenta ha expridado
				if l_expires_on > sysdate or l_expires_on is null   then
					insert into gti_aux (col1, col2) values (3, 'Usuario Vigente');
					commit;
					v_seg_autenticar := true;
				else
					insert into gti_aux (col1, col2) values (6, 'Usuario Expiro');
					commit;
					-- Si ha expirado la cuenta retornamos FALSE
					v_seg_autenticar := false;

                    apex_error.add_error (p_message          => '¡La cuenta del usuario ha vencido!',
                                          p_display_location => apex_error.c_inline_in_notification );
				end if;
			end if;	
		else
			-- Password Erroneo
			v_seg_autenticar := false;
			insert into gti_aux (col1, col2) values (5, 'Claves diferentes');
			commit;
		end if;

    else
        -- El usuario No Existe en Tabla USUARIOS
		insert into gti_aux (col1, col2) values (7, 'Usuario No esta en tabla de USUARIOS');
		commit;
        v_seg_autenticar := false;
    end if;

	return v_seg_autenticar;

exception
	when others then
			return false;
end;

function fnc_gti_breadcrumbs(p_aplicacion  in number,
                             p_id_menu    in number,
                             p_sesion      in number,
                             p_inicial     in varchar2,
                             p_iteraciones in number) return varchar2 Is


    cursor cMenu(r_id_mnu number) is
    select m.nmbre_mnu,
           m.id_mnu_pdre,
           m.nmro_pgna,
           (select m2.nmro_pgna from sg_g_menu m2 where m2.id_mnu=m.id_mnu_pdre) pgna_pdre,
           m.id_aplccion,
           m.dstno_tpo,
           m.indcdor_vsble
      from sg_g_menu m
     where m.id_mnu = r_id_mnu;

    v_breadcrumb varchar2(4000);

begin

   if(p_iteraciones>100) then
     return 'mas de 100 iteraciones';
   end if;

-- Se recorre el cursor que trae el registro de menú
      for rMenu in cMenu(p_id_menu) loop


        if(p_inicial = 'S' or rMenu.nmro_pgna=0) then
          v_breadcrumb:='<li class="t-Breadcrumb-item is-active" style="display: inline-block !important;font-size: 1.6rem !important; line-height: 2rem !important;"><span class="t-Breadcrumb-label">'||rMenu.nmbre_mnu||'</span> </li>';
        else
          v_breadcrumb:='<li class="t-Breadcrumb-item"> <a href="f?p='||p_aplicacion||':'||rMenu.nmro_pgna||':'||p_sesion||'::NO:::" class="t-Breadcrumb-label">'||rMenu.nmbre_mnu||'</a></li>';
        end if;

        if(rMenu.id_mnu_pdre is not null)then
          --se busca la información del menú padre
          v_breadcrumb:=fnc_gti_breadcrumbs(p_aplicacion,rMenu.id_mnu_pdre, p_sesion, 'N',p_iteraciones+1)||v_breadcrumb;
        end if;

      end loop;

  return v_breadcrumb; 

exception
  when others then return null;
end;

function fnc_gti_generar_breadcrumbs(p_cod_cliente in number, 
                                     p_aplicacion  in number, 
                                     p_pagina      in number,
                                     p_sesion      in number) return varchar2 Is

    cursor cApp(r_nmro_aplicacion number)is
    select id_aplccion, 
           nmbre_aplccion
      from sg_g_aplicaciones 
     where nmro_aplccion =r_nmro_aplicacion;
    
    cursor cMenu(r_cdgo_clnte number, r_id_aplicacion number, r_pagina number) is
    select m.id_mnu,
           m.nmbre_mnu,
           m.id_mnu_pdre,
           m.dstno_tpo,
           m.indcdor_vsble
      from sg_g_menu m
     where m.id_aplccion = r_id_aplicacion
       and m.nmro_pgna = r_pagina
       and m.actvo = 'S'
       and m.indcdor_vsble = 1;
    
    cursor cMenuBreadcrumb(r_cdgo_clnte number, r_id_aplicacion number, r_pagina number) is
    
    select m.id_mnu,
           m.nmbre_mnu,
           m.id_mnu_pdre,
           m.dstno_tpo,
           m.indcdor_vsble
      from sg_g_menu m
     where m.id_aplccion = r_id_aplicacion
       and instr(m.pgnas_breadcrum,(','||r_pagina||','))>0
       and m.indcdor_mstrar_breadcrum=1;
    
    v_breadcrumb varchar2(4000);
    v_cod_app sg_g_aplicaciones.id_aplccion%type; 
    v_nom_app sg_g_aplicaciones.nmbre_aplccion%type;
    v_encontro_menu number;
    v_id_menu sg_g_menu.id_mnu%type;
    v_nom_menu sg_g_menu.nmbre_mnu%type;
    v_id_menu_padre sg_g_menu.id_mnu_pdre%type;
    v_tip_destino sg_g_menu.dstno_tpo%type;

begin

  v_encontro_menu:=0;
  -- Se obtiene la información de la aplicación
  for rApp in cApp(p_aplicacion) Loop
    v_cod_app:=rApp.id_aplccion;
    v_nom_app:=rApp.nmbre_aplccion;
  end loop;

  for rMenu in cMenu(p_cod_cliente, v_cod_app, p_pagina) loop

    v_encontro_menu:=1;
    v_id_menu       := rMenu.id_mnu;
    v_nom_menu       := rMenu.nmbre_mnu;
    v_id_menu_padre := rMenu.id_mnu_pdre;

  end loop;

  if(v_encontro_menu=0)then

    for rMenuBreadcrumb in cMenuBreadcrumb(p_cod_cliente, v_cod_app, p_pagina) loop

      v_encontro_menu := 1;

      v_id_menu       := rMenuBreadcrumb.id_mnu;
      v_nom_menu      := rMenuBreadcrumb.nmbre_mnu;
      v_id_menu_padre := rMenuBreadcrumb.id_mnu_pdre;

    end loop;

  end if;

  if (v_encontro_menu = 0) then
    v_breadcrumb:=null;
  else
    if(v_id_menu_padre is not null)then
      v_breadcrumb:=fnc_gti_breadcrumbs(p_aplicacion,v_id_menu, p_sesion, 'S',1)||v_breadcrumb;
    else
      v_breadcrumb:='<li class="t-Breadcrumb-item is-active" style="display: inline-block !important;font-size: 1.6rem !important; line-height: 2rem !important;"><span class="t-Breadcrumb-label">'||v_nom_menu||'</span> </li>';
    end if;

    v_breadcrumb:='<ol class="t-Breadcrumb"><li class="t-Breadcrumb-item"> <a href="f?p='||p_aplicacion||':'||1||':'||p_sesion||':NO:::" class="t-Breadcrumb-label">'||v_nom_app||'</a></li>'||v_breadcrumb||'</ol>';    
  end if;

  return v_breadcrumb; 

exception
  when others then return null;
end;

    procedure process_recaptcha_reply (p_token varchar2, p_message_out out varchar2)
    is   
    
      l_private_key     varchar2(4000) := APEX_APP_SETTING.GET_VALUE( p_name => 'RECAPTCHAV3_SECRET_KEY');
      l_wallet_path     varchar2(4000) := 'file:/u01/app/oracle/product/12.1.0.2/db_1/wallet/https_wallet';
      l_wallet_pwd      varchar2(4000) := '';
      l_error_msg       varchar2(4000) := 'Please Check the reCaptcha before proceeding.';
    
      l_parm_name_list  apex_application_global.vc_arr2;
      l_parm_value_list apex_application_global.vc_arr2;
      l_rest_result     varchar2(32767);
    
      l_result          apex_plugin.t_page_item_validation_result;
    begin
      -- Check if plug-in private key is set
      if l_private_key is null then
        raise_application_error(-20999, 'No Private Key has been set for the reCaptcha plug-in! Get one at https://www.google.com/recaptcha/admin/create');
      end if;
    
      -- Has the user checked the reCaptcha Box and responded to the challenge?
      if p_token is null then
        l_result.message := l_error_msg;
        --return l_result;
      end if;
    
      -- Build the parameters list for the post action.
      -- See https://developers.google.com/recaptcha/docs/verify?csw=1 for more details
    
      l_parm_name_list (1) := 'secret';
      l_parm_value_list(1) := l_private_key;
      l_parm_name_list (2) := 'response';
      l_parm_value_list(2) := p_token; 
      l_parm_name_list (3) := 'remoteip';
      l_parm_value_list(3) := owa_util.get_cgi_env('REMOTE_ADDR');
    
      -- Set web service header rest request
      apex_web_service.g_request_headers(1).name  := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
    
      -- Call the reCaptcha REST service to verify the response against the private key
      l_rest_result := wwv_flow_utilities.clob_to_varchar2(
                           apex_web_service.make_rest_request(
                               p_url         => 'https://www.google.com/recaptcha/api/siteverify',
                               p_http_method => 'POST',
                               p_parm_name   => l_parm_name_list,
                               p_parm_value  => l_parm_value_list--,
                               /*p_wallet_path => l_wallet_path--,
                               --p_wallet_pwd  => l_wallet_pwd
                               */));
    
      -- Delete the request header
      apex_web_service.g_request_headers.delete;
    
      -- Check the HTTPS status call
      if apex_web_service.g_status_code = '200' then -- sucessful call
        -- Check the returned json for successfull validation
        apex_json.parse(l_rest_result);
    
        if apex_json.get_varchar2(p_path => 'success') = 'false' then
          l_result.message := l_rest_result;
          apex_error.add_error (
            p_message          => 'Failed to verify your request 2!',
            p_display_location => apex_error.c_inline_in_notification );
          /* possible errors are :
             Error code	            Description
             ---------------------- ------------------------------------------------
             missing-input-secret 	The secret parameter is missing.
             invalid-input-secret 	The secret parameter is invalid or malformed.
             missing-input-response 	The response parameter is missing.
             invalid-input-response 	The response parameter is invalid or malformed.
             bad-request 	The request is invalid or malformed.
          */
        else -- success = 'true'
          l_result.message := 'VERIFIED'; --null
          --l_result.message := l_rest_result;
        end if;
      else -- unsucessful call
        l_result.message := 'reCaptcha HTTPS request status : ' || apex_web_service.g_status_code;
        apex_error.add_error (
            p_message          => 'Failed to verify your request 1!',
            p_display_location => apex_error.c_inline_in_notification ); 
      end if;  
    
     p_message_out := l_result.message;
    
    end process_recaptcha_reply;


    procedure prc_sg_autenticar( p_cdgo_clnte    in number
                               , p_username      in varchar2
                               , p_password      in varchar2
                               , o_cdgo_rspsta   out number
                               , o_mnsje_rspsta  out varchar2 ) 
    as

        v_password varchar2(4000);
        v_stored_password varchar2(4000);
        v_expires_on date;
        v_count number;

    begin
        o_cdgo_rspsta := 0; 
        begin
            --Verificamos los datos del usuario
            begin 
                select password 
                     , nvl(fcha_exprcion,  sysdate - 1)
                  into v_stored_password
                     , v_expires_on
                  from v_sg_g_usuarios
                 where cdgo_clnte = p_cdgo_clnte 
                   and lower(user_name) = lower(p_username);
            exception
                when others then
                    o_cdgo_rspsta  := 1;
                    o_mnsje_rspsta :=  '¡Los datos ingresados no son correctos!';
                    return;
            end;

            -- Obtener el password encriptado
            v_password := fnc_sg_hash(lower(p_username), p_password);

            -- Finalmente,  comparamos los password:  Almacenado e Introducido por el usuario
            if v_password = v_stored_password then
                -- Chequemos si la Cuenta ha expridado
                if (v_expires_on < sysdate) then
                    o_cdgo_rspsta  := 2;
                    o_mnsje_rspsta :=  '¡La cuenta del usuario ha vencido!';
                    return;
                end if; 
            else
                o_cdgo_rspsta  := 3;
                o_mnsje_rspsta :=  '¡Los datos ingresados no son correctos!';
                return;
            end if;            
        end;
    end prc_sg_autenticar;

end pkg_sg_autenticacion;

/
