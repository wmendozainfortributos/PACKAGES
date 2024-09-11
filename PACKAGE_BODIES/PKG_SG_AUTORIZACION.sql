--------------------------------------------------------
--  DDL for Package Body PKG_SG_AUTORIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SG_AUTORIZACION" is

  function fnc_get_select_menu(p_app_session   in varchar2,
                               p_app_user      in varchar2,
                               p_cdgo_clnte    in number,
                               p_aplccion_grpo in number) return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que retorna select dinamico para armar el menu de un usuario            !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
    v_sql      varchar2(4000);
    v_usuario  number;
    v_id_usrio sg_g_usuarios.id_usrio%type;
  begin
  
    select id_usrio
      into v_id_usrio
      from v_sg_g_usuarios a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.user_name = p_app_user;
  
    v_sql := '   select level,
						title as label,
						case
							when dstno_tpo_mnu = 1 then
								''f?p='' ||  nmro_aplccion || '':'' || nmro_pgna  || '':'' ||' ||
             p_app_session || '|| ''::NO:'' || clear || '':'' || nvl2(prmtro_cmpo, prmtro_cmpo || '','','''') || ''F_ID_MNU'' || '':''|| nvl2(prmtro_vlor, prmtro_vlor || '','','''') ||  mnu  
							else
								replace(url, ''APP_SESSION'', ' || p_app_session || ')
								--url
						end as target,
						nmro_pgna is_current ,
						case
							when level = 1 then ''fa-folder''
							when connect_by_isleaf = 1 then ''fa-folder-o''
							else ''fa-folder''
						end as image
					   from (select id_aplccion + 1000000	id_mnu,			nmbre_aplccion	title,			null			id_mnu_pdre,
									nmbre_aplccion			tooltip,		orden			orden,			nmro_aplccion	nmro_aplccion,
									pgna_incio				nmro_pgna,		null			prmtro_cmpo,	null			prmtro_vlor,
									null					clear,			1				dstno_tpo_mnu,	null 			url,
                                    null                    mnu
							   from v_sg_g_aplicaciones_cliente
							  where cdgo_clnte 			= ' || p_cdgo_clnte || '
								and id_aplccion_grpo 	= ' || p_aplccion_grpo || '
								and actvo 				= ''S'' 
								and actvo_app 			= ''S''
								and id_aplccion IN ( select distinct id_aplccion from v_sg_g_menu_x_usuario where id_usrio = ' ||
             v_id_usrio || ' and cdgo_clnte = ' || p_cdgo_clnte || ')  
						union
							 select a.id_mnu				id_mnu,			a.nmbre_mnu		title,			a.id_aplccion + 1000000	id_mnu_pdre,
									a.nmbre_mnu				tooltip,		a.orden			orden,			a.nmro_aplccion			nmro_aplccion,
									a.nmro_pgna				nmro_pgna,		a.prmtro_cmpo	prmtro_cmpo,	a.prmtro_vlor			prmtro_vlor,
									clear_cache				clear,			a.dstno_tpo		dstno_tpo_mnu,	a.url					url,
                                    a.id_mnu                mnu
							   from v_sg_g_menu				a
							   join v_sg_g_menu_x_usuario	b on a.id_mnu = b.id_mnu 
							    and a.cdgo_clnte 		= b.cdgo_clnte
								and a.id_aplccion_grpo	= b.id_aplccion_grpo
							  where a.cdgo_clnte		= ' || p_cdgo_clnte || '
								and b.id_aplccion_grpo	= ' || p_aplccion_grpo || '
								and a.id_mnu_pdre is null
								and a.id_mnu			= b.id_mnu 
								and a.actvo				= ''S''
								and a.indcdor_vsble		= 1
								--and b.user_name		= ' || p_app_user || '
								and b.id_usrio			= ' || v_id_usrio || ' 
						union
							 select a.id_mnu				id_mnu,			a.nmbre_mnu		title,			a.id_mnu_pdre			id_mnu_pdre,
									a.nmbre_mnu				tooltip,		a.orden			orden,			a.nmro_aplccion			nmro_aplccion,
									a.nmro_pgna				nmro_pgna,		a.prmtro_cmpo	prmtro_cmpo,	a.prmtro_vlor			prmtro_vlor,
									clear_cache				clear,			a.dstno_tpo		dstno_tpo_mnu,	a.url					url,
                                    a.id_mnu                 mnu
							   from v_sg_g_menu a, v_sg_g_menu_x_usuario b
							  where a.id_mnu_pdre is not null
								and a.id_mnu = b.id_mnu 
								and a.actvo = ''S''
								and a.indcdor_vsble = 1
								--and b.user_name = ' || p_app_user || '
								and b.id_usrio = ' || v_id_usrio || ' )
			 start with id_mnu_pdre is null
	   connect by prior id_mnu = id_mnu_pdre
	  order siblings by orden';
  
    return(v_sql);
  
  end;

  function fnc_valida_pagina_x_perfil(p_cdgo_clnte in number,
                                      p_id_prfil   in number,
                                      p_id_mnu     in number) return number as
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un perfil tiene permiso sobre un menu               !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
    v_indcdor_asgndo number := 0;
    v_id_mnu         sg_g_menu.id_mnu%type;
  
  begin
    -- Consulta de menu por perfil
    begin
      select id_mnu
        into v_id_mnu
        from v_sg_g_menu_x_perfil
       where id_prfil = p_id_prfil
         and id_mnu = p_id_mnu
         and cdgo_clnte = p_cdgo_clnte;
      v_indcdor_asgndo := 1;
    exception
      when others then
        v_indcdor_asgndo := 0;
    end; -- Fin Consulta de menu por perfil
    return(v_indcdor_asgndo);
  end fnc_valida_pagina_x_perfil;

  function fnc_valida_region_x_perfil(p_id_prfil      in number,
                                      p_nmro_aplccion in number,
                                      p_nmro_pgna     in number,
                                      p_id_rgion      in number,
                                      p_nmbre_rgion   in varchar2)
    return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un perfil tiene permiso sobre una region              !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
    v_msj varchar2(5);
  
  begin
    -- Verificar si el perfil tiene restricci??n a una regi??n de la p?!gina 
    v_msj := 'true';
    for c_rgion in (select nmbre_rgion
                      from sg_g_perfiles_region
                     where id_prfil = p_id_prfil
                       and id_aplccion =
                           (select id_aplccion
                              from sg_g_aplicaciones
                             where nmro_aplccion = p_nmro_aplccion)
                       and nmro_pgna = p_nmro_pgna
                       and id_rgion = p_id_rgion
                       and nmbre_rgion = p_nmbre_rgion) loop
    
      if c_rgion.nmbre_rgion is not null then
        v_msj := 'false';
      else
        -- si no encuentra un registro significa que el perfil tiene permiso sobre esa regi??n
        v_msj := 'true';
      end if;
    end loop;
    return(v_msj);
  
  end fnc_valida_region_x_perfil;

  function fnc_valida_boton_x_perfil(p_id_prfil      in number,
                                     p_nmro_aplccion in number,
                                     p_nmro_pgna     in number,
                                     p_id_bton       in number,
                                     p_nmbre_bton    in varchar2)
    return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un perfil tiene permiso sobre un bot??n               !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_nmbre_bton sg_g_perfiles_boton.nmbre_bton%type;
    v_msj        varchar2(10);
  
  begin
    v_msj := 'true';
  
    begin
      select nmbre_bton
        into v_nmbre_bton
        from sg_g_perfiles_boton
       where id_prfil = p_id_prfil
         and id_aplccion =
             (select id_aplccion
                from sg_g_aplicaciones
               where nmro_aplccion = p_nmro_aplccion)
         and nmro_pgna = p_nmro_pgna
         and id_bton = p_id_bton
         and nmbre_bton = p_nmbre_bton;
    
      v_msj := 'false';
    
    exception
      -- si no encuentra un registro significa que el perfil tiene permiso sobre el bot??n
      when no_data_found then
        v_msj := 'true';
      when others then
        v_msj := 'false';
    end;
  
    return(v_msj);
  
  end fnc_valida_boton_x_perfil;

  function fnc_valida_pagina_x_usuario(p_cdgo_clnte    in number,
                                       p_user_name     in number,
                                       p_nmro_aplccion in number,
                                       p_nmro_pgna     in number)
    return boolean is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un usuario tiene permiso sobre un menu                !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
    v_id_usrio sg_g_usuarios.id_usrio%type;
  
    v_msj boolean;
  
  begin
    begin
      select id_usrio
        into v_id_usrio
        from v_sg_g_usuarios
       where cdgo_clnte = p_cdgo_clnte
         and user_name = p_user_name;
      for c_mnu in (select *
                      from v_sg_g_menu_x_usuario
                     where id_usrio = v_id_usrio
                       and nmro_aplccion = p_nmro_aplccion
                       and (nmro_pgna = p_nmro_pgna or
                           instr(pgnas_breadcrum,
                                  (',' || p_nmro_pgna || ',')) > 0)) loop
        if c_mnu.nmro_aplccion is null then
          v_msj := false;
        else
          v_msj := true;
        end if;
      
      end loop;
    exception
      when others then
        v_msj := false;
    end;
    return(v_msj);
  end fnc_valida_pagina_x_usuario;

  function fnc_valida_region_x_usuario(p_cdgo_clnte    in number,
                                       p_user_name     in number,
                                       p_nmro_aplccion in number,
                                       p_nmro_pgna     in number,
                                       p_nmbre_rgion   in varchar2)
    return boolean is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un usuario tiene permiso sobre una regi??n              !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_id_usrio sg_g_usuarios.id_usrio%type;
    v_msj      boolean;
    v_rstrngdo varchar2(1);
    v_count    number;
  
  begin
    select id_usrio
      into v_id_usrio
      from v_sg_g_usuarios
     where cdgo_clnte = p_cdgo_clnte
       and user_name = p_user_name;
  
    v_rstrngdo := 'N';
    v_msj      := false;
    v_count    := 0;
  
    for c_prfles in (select id_prfil
                       from sg_g_perfiles_usuario a
                      where id_usrio = v_id_usrio) loop
      begin
        select 1
          into v_rstrngdo
          from v_sg_g_perfiles_region a
         where a.id_prfil = c_prfles.id_prfil
           and a.nmro_aplccion = p_nmro_aplccion
           and a.nmro_pgna = p_nmro_pgna
           and a.nmbre_rgion = p_nmbre_rgion;
      exception
        when no_data_found then
          v_count := v_count + 1;
      end;
    end loop;
  
    if v_count > 0 then
      v_msj := true;
    else
      v_msj := false;
    end if;
  
    return v_msj;
  
  end fnc_valida_region_x_usuario;

  function fnc_valida_boton_x_usuario(p_cdgo_clnte    in number,
                                      p_user_name     in number,
                                      p_nmro_aplccion in number,
                                      p_nmro_pgna     in number,
                                      p_nmbre_bton    in varchar2)
    return boolean is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que valida si un usuario tiene permiso sobre un bot??n                !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
  v_msj       boolean := true;
  v_id_usrio      v_sg_g_usuarios.id_usrio%type;
  v_count_true    number := 0;
  v_count_false   number := 0;
  v_id_prfil      sg_g_perfiles_boton.id_prfil%type;
    

  begin
    begin 
      select id_usrio
        into v_id_usrio
        from v_sg_g_usuarios
       where cdgo_clnte = p_cdgo_clnte
         and user_name = p_user_name; 

      for c_prfles in (select id_prfil from sg_g_perfiles_usuario where id_usrio = v_id_usrio)loop
        begin
          select count(*)--id_prfil
            into v_id_prfil
            from v_sg_g_perfiles_boton 
           where id_prfil     = c_prfles.id_prfil
             and nmro_aplccion  = p_nmro_aplccion
             and nmro_pgna    = p_nmro_pgna
             and nmbre_bton     = p_nmbre_bton;
            
                        -- Si no esta en la tabla, no tiene permiso para el bot¿n
                        if v_id_prfil = 0 then
                            v_count_false := v_count_false + 1; 
                        else -- Si lo encuentra, es porque si tiene permiso para el bot¿n
                            v_count_true := v_count_true + 1;
                        end if;
           
        exception
          when others then
                        return false; 
        end;
      end loop;

       -- if v_count_true >  0 then
        if v_count_true >  0 then
      return true;
    else
      return false;
    end if;
        
    exception
      when no_data_found then
        return false; 
      when others then
        return false; 
    end;


  end fnc_valida_boton_x_usuario;



  function fnc_paginas_llamadas_x_boton(p_cdgo_clnte       in number,
                                        p_id_aplccion_grpo in number,
                                        p_nmro_aplccion    in number,
                                        p_page_id          in number,
                                        p_region_id        in number,
                                        p_id_prfil         in number,
                                        p_app_session      in number)
    return clob is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que lista las paginas que con llamdas por los botones de la pagina (p_page_id)  !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_nmro_pgna    clob;
    v_check_pagina varchar2(1000); -- Variable donde se guarda (true/false) si una pagina esta asignada para el perfil (p_id_prfil) ingresado
    v_count        number := 0;
    v_id_mnu       number;
    v_id_aplccion  number;
    v_link         varchar2(1000);
  
  begin
    v_nmro_pgna := '<table width="100%" border="1" style=" border-collapse: collapse;">
						<tbody>
						  <tr>
							<th>Bot??n</th>
							<th>Dirige a</th>
							<th>Pagina Asignada?</th>
							<th>Ir</th>
						  </tr>';
    begin
      select id_aplccion
        into v_id_aplccion
        from sg_g_aplicaciones
       where nmro_aplccion = p_nmro_aplccion;
    exception
      when others then
        v_link := '';
    end;
  
    v_link := '';
    for c_bton in (select b.button_id,
                          b.button_name,
                          b.button_action_code,
                          b.redirect_url,
                          SUBSTR(SUBSTR(b.redirect_url,
                                        0,
                                        INSTR(b.redirect_url, ':', 1, 2) - 1),
                                 14) nmro_pgna,
                          b.label,
                          b.region_id,
                          (select page_name
                             from apex_application_pages
                            where application_id = b.application_id
                              and page_id = SUBSTR(SUBSTR(b.redirect_url,
                                                          0,
                                                          INSTR(b.redirect_url,
                                                                ':',
                                                                1,
                                                                2) - 1),
                                                   14)) page_name
                     from apex_application_page_buttons b
                    where b.application_id = p_nmro_aplccion
                      and b.page_id = p_page_id
                      and b.region_id = p_region_id) loop
      if c_bton.button_action_code = 'REDIRECT_PAGE' then
        v_count := v_count + 1;
      
        begin
          select id_mnu
            into v_id_mnu
            from v_sg_g_menu
           where cdgo_clnte = p_cdgo_clnte
             and id_aplccion_grpo = p_id_aplccion_grpo
             and nmro_aplccion = p_nmro_aplccion
             and nmro_pgna = c_bton.nmro_pgna;
        
          v_link := 'javacript:apex.navigation.dialog(''f?p=' ||
                    p_nmro_aplccion || ':118:' || p_app_session ||
                    '::NO:118:P118_ID_MNU,P118_ID_APLCCION,P118_ID_PRFIL:' ||
                    v_id_mnu || ',' || v_id_aplccion || ',' || p_id_prfil || ')';
          --'f?p=' || p_nmro_aplccion || ':118:' || p_app_session || '::NO:118:P118_ID_MNU,P118_ID_APLCCION,P118_ID_PRFIL:'|| v_id_mnu || ',' ||v_id_aplccion || ',' ||p_id_prfil;
        exception
          when no_data_found then
            v_id_mnu       := 0;
            v_check_pagina := '';
        end;
      
        v_check_pagina := fnc_valida_pagina_x_perfil(p_cdgo_clnte,
                                                     p_id_prfil,
                                                     v_id_mnu);
      
        if v_check_pagina = 1 then
          v_check_pagina := 'Si';
        else
          v_check_pagina := 'No';
        end if;
      
        v_nmro_pgna := v_nmro_pgna || '<tr>
											<td>' || c_bton.label ||
                       '</td>
											<td style="text-align: center;" >' ||
                       c_bton.nmro_pgna || ' - ' || c_bton.page_name ||
                       '</td>
											<td style="text-align: center;" >' ||
                       v_check_pagina ||
                       '</td>
											<td style="text-align: center;" > <a href="' ||
                       v_link || '">Ver</a> </td>
										  </th>';
      end if;
      v_check_pagina := '';
    end loop;
  
    if v_count > 0 then
      v_nmro_pgna := v_nmro_pgna || '</tbody></table>';
    
    else
      v_nmro_pgna := '';
    end if;
  
    return(v_nmro_pgna);
  
  end fnc_paginas_llamadas_x_boton;

  function fnc_get_html_x_pgna_btn_x_pgna(p_cdgo_clnte       in number,
                                          p_id_aplccion_grpo in number default null,
                                          p_id_prfil         in number,
                                          p_id_aplccion      in number,
                                          p_id_mnu           in number,
                                          p_app_session      in number)
    return clob is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Esta funcion retorna un html con las regiones y botones de la pagina (p_id_mnu),     !! --
    -- !! ademas tambien se??ala las regiones y botones que estan restringida para         !! --
    -- !! el perfil (p_id_prfil).                                  !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_html                clob := ''; -- Variable donde se almacena el html 
    v_check_region        varchar2(1000) := ''; -- Variable donde se guarda (true/false) si una region esta restringida para el perfil (p_id_prfil) ingresado
    v_region_style        varchar2(1000) := ''; -- Variable donde se guarda
    v_region_style_1      varchar2(1000) := ''; -- Variable donde se guarda
    v_boton_restringido   varchar2(1000); -- Variable donde se guarda (true/false) si un bot??n esta restringido para el perfil (p_id_prfil) ingresado
    v_existe              boolean := false;
    v_pagina_botones      clob;
    v_region_restringida  varchar2(10);
    v_botones_restringido varchar2(10);
  
  begin
    -- Consultar las regiones de la p?!gina ingresada (p_id_mnu)
    for c_rgion in (select region_id,
                           region_name,
                           display_sequence,
                           application_id,
                           page_id
                      from apex_application_page_regions
                     where application_id =
                           (select nmro_aplccion
                              from sg_g_aplicaciones
                             where id_aplccion = p_id_aplccion)
                       and page_id = (select nmro_pgna
                                        from sg_g_menu
                                       where id_mnu = p_id_mnu)
                     order by display_sequence) loop
      v_existe := true;
      -- Se valida que regiones estan restringidas para el perfil ingresado (p_id_prfil)
      v_region_restringida := fnc_valida_region_x_perfil(p_id_prfil,
                                                         c_rgion.application_id,
                                                         c_rgion.page_id,
                                                         c_rgion.region_id,
                                                         c_rgion.region_name);
    
      if v_region_restringida = 'false' then
        v_check_region   := 'checked';
        v_region_style   := 't-Region-header-restringida';
        v_region_style_1 := 't-Region-restringida';
      else
        v_check_region   := '';
        v_region_style   := 'checked';
        v_region_style_1 := '';
      end if;
    
      v_html := v_html || '<div class="' || v_region_style_1 ||
                ' t-Region t-Region--scrollBody lto38123805254396901_0" id="' ||
                c_rgion.region_id || '" role="group" aria-labelledby="R38123805254396901_heading">
						<div class="' || v_region_style ||
                ' t-Region-header" id="' || c_rgion.region_id ||
                '-header">
							<div class="t-Region-headerItems t-Region-headerItems--title">
								<table width="100%" border="0">
									<tr>
										<td>' || c_rgion.region_name ||
                '</td>
										<td style="text-align: right;">Restringida?  
											<input type="checkbox" name="checkRegiones" value="' ||
                c_rgion.region_id || '" ' || v_check_region ||
                ' onchange="cambiarRestriccionRegion(this, this.value)"> 
										</td>
									</tr>
								</table>
							</div>
							<div class="t-Region-headerItems t-Region-headerItems--buttons"><span class="js-maximizeButtonContainer"></span></div>
						</div>
						<div class="t-Region-bodyWrap">
							<div class="t-Region-buttons t-Region-buttons--top">
								<div class="t-Region-buttons-left"></div>
								<div class="t-Region-buttons-right"></div>
							</div>
						<div class="t-Region-body">';
    
      -- Consultar los botones de la p?!gina ingresada (p_id_mnu)
      for c_bton in (select button_id,
                            button_name,
                            button_sequence,
                            label,
                            button_action_code,
                            redirect_url,
                            region,
                            region_id
                       from apex_application_page_buttons
                      where application_id =
                            (select nmro_aplccion
                               from sg_g_aplicaciones
                              where id_aplccion = p_id_aplccion)
                        and page_id = (select nmro_pgna
                                         from sg_g_menu
                                        where id_mnu = p_id_mnu)
                        and region_id = c_rgion.region_id
                      order by button_sequence) loop
      
        -- Se valida que botones estan restringido para el perfil ingresado (p_id_prfil)
        v_botones_restringido := fnc_valida_boton_x_perfil(p_id_prfil,
                                                           c_rgion.application_id,
                                                           c_rgion.page_id,
                                                           c_bton.button_id,
                                                           c_bton.button_name);
      
        if v_botones_restringido = 'false' then
          v_boton_restringido := 't-Button-restringido';
        else
          v_boton_restringido := 't-Button-Norestringido';
        end if;
      
        v_html := v_html || '<button class=" ' || v_boton_restringido ||
                  '" type="button" name = "botonesRegion" id="' ||
                  c_bton.button_id || '" onclick = "cambiarRestriccionBoton(this);">
						<span class="t-Button-label">' || c_bton.label ||
                  '</span>
					 </button>';
      end loop;
    
      v_html := v_html || '</div>
					<div class="t-Region-buttons t-Region-buttons--bottom">
						<div class="t-Region-buttons-left"></div> 
						<div class="t-Region-buttons-right"></div>';
    
      --  se crea tabla con la listas de p?!ginas que son llamadas desde los botones        
      v_pagina_botones := fnc_paginas_llamadas_x_boton(p_cdgo_clnte,
                                                       c_rgion.application_id,
                                                       p_id_aplccion_grpo,
                                                       c_rgion.page_id,
                                                       c_rgion.region_id,
                                                       p_id_prfil,
                                                       p_app_session);
    
      v_html := v_html || ' <div class="t-Region-body">' ||
                v_pagina_botones || '</div> ';
    
      v_html := v_html || '</div> </div> </div>';
    end loop;
  
    if not v_existe then
      v_html := 'P?!gina sin Elementos ';
    end if;
  
    return(v_html);
  
  end fnc_get_html_x_pgna_btn_x_pgna;

  function fnc_asigna_usuario_perfil(p_cdgo_clnte        in number,
                                     p_id_prfil          in number,
                                     p_usuarios          in varchar2,
                                     p_username_modifica in varchar2,
                                     p_fecha_modifica    in timestamp)
    return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que asigna los usuarios que estan en la cadena p_usuarios al perfil (p_id_prfil)  !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_respuesta               varchar2(1000);
    v_indcdor_prfil_admnstdor sg_g_perfiles.indcdor_prfil_admnstdor%type;
    v_user_name               sg_g_usuarios.user_name%type;
    v_exste                   number;
    
  begin
    begin
      select indcdor_prfil_admnstdor
        into v_indcdor_prfil_admnstdor
        from sg_g_perfiles
       where id_prfil = p_id_prfil;
    exception
      when others then
        v_indcdor_prfil_admnstdor := 'N';
    end;
  
    if v_indcdor_prfil_admnstdor = 'S' then
      -- Se actualiza el indicador de administrador del usuario a 0   
      for c_usrio in (select id_usrio
                        from sg_g_perfiles_usuario
                       where id_prfil = p_id_prfil) loop
        update sg_g_usuarios
           set admin = 0
         where id_usrio = c_usrio.id_usrio;
      
        delete from sg_g_perfiles_usuario
         where id_prfil = p_id_prfil
           and id_usrio = c_usrio.id_usrio;
      end loop;
    end if;
  
    for c_usurio_prfil in (select cdna
                             from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_usuarios,
                                                                                p_crcter_dlmtdor => ':'))) loop
      if (c_usurio_prfil.cdna is not null) then
        begin
          select user_name
            into v_user_name
            from sg_g_usuarios
           where id_usrio = c_usurio_prfil.cdna;
          apex_application.g_print_success_message := v_respuesta;
        
         begin
            select 1
            into v_exste
            from sg_g_perfiles_usuario
            where  id_prfil = p_id_prfil
                and id_usrio = c_usurio_prfil.cdna;
             
             -- Usuario encontrado en el perfil
             continue;
                
         exception
            when no_data_found then        
                begin
                    insert into sg_g_perfiles_usuario
                      (id_prfil, id_usrio, username_modifica, fecha_modifica)
                    values
                      (p_id_prfil,
                       c_usurio_prfil.cdna,
                       p_username_modifica,
                       p_fecha_modifica);
                    v_respuesta := 'Registro Exitoso';
                    commit;
                exception
                when others then
                  v_respuesta := 'Error al insertar el perfil al usuario. Usuario' ||
                                 v_user_name || '. Perfil: ' || p_id_prfil ||
                                 ' -- ' || SQLCODE || ' -- ' || SQLERRM;
                  rollback;
                end;
           end;
        
          -- Los usuarios son marcados como administrador. 
          if (c_usurio_prfil.cdna is not null and
             v_indcdor_prfil_admnstdor = 'S') then
            update sg_g_usuarios
               set admin = 1
             where id_usrio = c_usurio_prfil.cdna;
          end if;
        
        exception
          when no_data_found then
            v_respuesta := 'No se encontro el usuario: ' ||
                           c_usurio_prfil.cdna;
            apex_error.add_error(v_respuesta,
                                 p_display_location => apex_error.c_inline_in_notification);
            rollback;
          when others then
            v_respuesta := 'Error al asignar el perfil al usuario: ' ||
                           c_usurio_prfil.cdna || '. ' || SQLCODE || '--' || '--' ||
                           SQLERRM;
            apex_error.add_error(v_respuesta,
                                 p_display_location => apex_error.c_inline_in_notification);
            rollback;
        end;
      end if;
    end loop;
  
    return(v_respuesta);
  end fnc_asigna_usuario_perfil;

  function fnc_asigna_pagina_perfil(p_cdgo_clnte        in number,
                                    p_id_aplccion_grpo  in number,
                                    p_id_prfil          in number,
                                    p_id_mnu            in number,
                                    p_username_modifica in varchar,
                                    p_fecha_modifica    in timestamp)
    return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que asigna al perfil (p_id_prfil) el menu (p_id_mnu)                !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    v_respuesta   varchar2(1000);
    v_id_mnu_pdre number;
  
  begin
    delete from gti_aux;
    commit;
  
    v_id_mnu_pdre := 0;
    for c_mnu in (select *
                    from v_sg_g_menu
                   where id_aplccion_grpo = p_id_aplccion_grpo
                     and cdgo_clnte = p_cdgo_clnte
                     and id_mnu = p_id_mnu) loop
    
      -- Se agregan los men??s al perfil
      begin
        insert into sg_g_perfiles_menu
          (id_prfil, id_mnu, username_modifica, fecha_modifica)
        values
          (p_id_prfil, c_mnu.id_mnu, p_username_modifica, p_fecha_modifica);
      
        insert into gti_aux
          (col1, col2)
        values
          (c_mnu.id_mnu, c_mnu.nmbre_mnu);
      
        -- Se Buscan los menu padre del menu asignando, para ser asignado
        begin
          select id_mnu_pdre
            into v_id_mnu_pdre
            from v_sg_g_menu
           where id_aplccion_grpo = p_id_aplccion_grpo
             and cdgo_clnte = p_cdgo_clnte
             and id_mnu = c_mnu.id_mnu
             and id_mnu_pdre not in
                 (select id_mnu
                    from sg_g_perfiles_menu
                   where id_prfil = p_id_prfil);
          -- Registro del menu padre
          begin
            insert into sg_g_perfiles_menu
              (id_prfil, id_mnu, username_modifica, fecha_modifica)
            values
              (p_id_prfil,
               v_id_mnu_pdre,
               p_username_modifica,
               p_fecha_modifica);
          exception
            when others then
              insert into gti_aux
                (col1, col2)
              values
                (c_mnu.id_mnu,
                 'Error al insert el menu padre ' || v_id_mnu_pdre);
          end; -- Fin Registro del menu padre
        exception
          when no_data_found then
            insert into gti_aux
              (col1, col2)
            values
              (c_mnu.id_mnu,
               'No se encontro padre para el menu ' || c_mnu.nmbre_mnu);
        end; -- Fin consulta de Men?? padre
      
        v_respuesta                              := 'Registro Exitoso del menu: ' ||
                                                    c_mnu.nmbre_mnu;
        apex_application.g_print_success_message := v_respuesta;
      
      exception
        when others then
          v_respuesta := 'Error al insertar en sg_g_perfiles_menu (perfil: ' ||
                         p_id_prfil || ', menu : ' || c_mnu.id_mnu ||
                         ') - ' || SQLCODE || '--' || '--' || SQLERRM;
          apex_error.add_error(v_respuesta,
                               p_display_location => apex_error.c_inline_in_notification);
          rollback;
      end; -- Sin registro del men??
    end loop;
  
    -- Agregando menus hijos al perfil 
    for c_mnu_hjo in (select *
                        from v_sg_g_menu
                       where id_mnu not in
                             (select id_mnu
                                from sg_g_perfiles_menu
                               where id_prfil = p_id_prfil)
                         and id_aplccion_grpo = p_id_aplccion_grpo
                         and cdgo_clnte = p_cdgo_clnte
                       start with id_mnu_pdre = p_id_mnu
                      connect by prior id_mnu = id_mnu_pdre
                       order siblings by orden) loop
    
      begin
        insert into sg_g_perfiles_menu
          (id_prfil, id_mnu, username_modifica, fecha_modifica)
        values
          (p_id_prfil,
           c_mnu_hjo.id_mnu,
           p_username_modifica,
           p_fecha_modifica);
      
        insert into gti_aux
          (col1, col2)
        values
          ('c_mnu_hjo ' || c_mnu_hjo.id_mnu, c_mnu_hjo.nmbre_mnu);
      exception
        when others then
          v_respuesta := 'Error al insertar en sg_g_perfiles_menu (perfil: ' ||
                         p_id_prfil || ', menu: ' || c_mnu_hjo.id_mnu ||
                         ') - ' || SQLCODE || '--' || '--' || SQLERRM;
          insert into gti_aux
            (col1, col2)
          values
            ('c_mnu_hjo Error ' || c_mnu_hjo.id_mnu, v_respuesta);
          apex_error.add_error(v_respuesta,
                               p_display_location => apex_error.c_inline_in_notification);
          rollback;
      end;
    end loop;
  
    return(v_respuesta);
  end fnc_asigna_pagina_perfil;

  -- fn_gti_seg_eliminar_pagina
  function fnc_eliminar_pagina_perfil(p_cdgo_clnte  in number,
                                      p_id_prfil    in number,
                                      p_id_aplccion in number,
                                      p_id_mnu      in number)
  
   return varchar2 as
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n que elimina del perfil (p_id_prfil) la pagina (p_id_mnu)junto           !! --
    -- !! con sus regiones y botones                               !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    cursor C1 is
      select *
        from v_sg_g_menu
       where id_mnu in (select id_mnu
                          from sg_g_perfiles_menu
                         where id_prfil = p_id_prfil)
       start with id_mnu_pdre = p_id_mnu
      connect by prior id_mnu = id_mnu_pdre
       order siblings by orden;
  
    v_respuesta varchar2(1000);
    v_nmro_pgna number;
  
  begin
    -- 1. Se guarda en le variable v_nmro_pgna el n??mero de la p?!gina que corressponde al id_mnu (p_id_mnu)
    select nmro_pgna
      into v_nmro_pgna
      from sg_g_menu
     where id_aplccion = p_id_aplccion
       and id_mnu = p_id_mnu;
  
    -- 2. Se eliminan las regiones que estan restringidas para el men?? (p_id_mnu)
    begin
      delete from sg_g_perfiles_region
       where id_prfil = p_id_prfil
         and id_aplccion = p_id_aplccion
         and nmro_pgna = v_nmro_pgna;
      commit;
      v_respuesta                              := 'Se elimino Correctamente la pagina ' ||
                                                  v_nmro_pgna;
      apex_application.g_print_success_message := v_respuesta;
    exception
      when others then
        v_respuesta := 'Error al eliminar regiones en sg_g_perfiles_region (perfil: ' ||
                       p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                       ', P?!gina : ' || v_nmro_pgna || ') - ' || SQLCODE || '--' || '--' ||
                       SQLERRM;
        apex_error.add_error(v_respuesta,
                             p_display_location => apex_error.c_inline_in_notification);
        rollback;
    end;
  
    -- 3. Se eliminan los botones que estan restringidos para el men?? (p_id_mnu)
    begin
      delete from sg_g_perfiles_boton
       where id_prfil = p_id_prfil
         and id_aplccion = p_id_aplccion
         and nmro_pgna = v_nmro_pgna;
      commit;
      v_respuesta := 'Se elimino Correctamente la pagina ' || v_nmro_pgna;
    exception
      when others then
        v_respuesta := 'Error al eliminar botones en sg_g_perfiles_boton (perfil: ' ||
                       p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                       ', P?!gina : ' || v_nmro_pgna || ') - ' || SQLCODE || '--' || '--' ||
                       SQLERRM;
        apex_error.add_error(v_respuesta,
                             p_display_location => apex_error.c_inline_in_notification);
        rollback;
    end;
  
    -- 4. Se elimina el menu de la tabla sg_g_perfiles_menu
    begin
      delete from sg_g_perfiles_menu
       where id_prfil = p_id_prfil
         and id_mnu = p_id_mnu;
      commit;
      v_respuesta := 'Se elimino Correctamente la pagina ' || v_nmro_pgna;
    exception
      when others then
        v_respuesta := 'Error al eliminar menu en sg_g_perfiles_menu (perfil: ' ||
                       p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                       ', P?!gina : ' || v_nmro_pgna || ') - ' || SQLCODE || '--' || '--' ||
                       SQLERRM;
        apex_error.add_error(v_respuesta,
                             p_display_location => apex_error.c_inline_in_notification);
        rollback;
    end;
  
    -- 5. Se eliminan los menus hijo en caso de que existan
    for R1 in C1 loop
      begin
        v_respuesta := fnc_eliminar_pagina_perfil(p_cdgo_clnte,
                                                  p_id_prfil,
                                                  p_id_aplccion,
                                                  r1.id_mnu);
      exception
        when others then
          v_respuesta := 'Error al eliminar menu en sg_g_perfiles_menu (perfil: ' ||
                         p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                         ', P?!gina : ' || r1.nmro_pgna || ') - ' ||
                         SQLCODE || '--' || '--' || SQLERRM;
          apex_error.add_error(v_respuesta,
                               p_display_location => apex_error.c_inline_in_notification);
          rollback;
      end;
    end loop;
    return(v_respuesta);
  end fnc_eliminar_pagina_perfil;

  function fnc_restriciones_perfil(p_cdgo_clnte            in number,
                                   p_id_prfil              in number,
                                   p_id_aplccion           in number,
                                   p_id_mnu                in number,
                                   p_regiones_restringidas in clob,
                                   p_botones_restringidos  in clob,
                                   p_username_modifica     in varchar2,
                                   p_fecha_modifica        in timestamp)
    return clob is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Esta Funci??n Elimina las regiones y los botones de la pagina ingresada (p_id_mnu) y     !! --
    -- !! agrega las regiones restringidas (p_regiones_restringidas) a la tabla sg_g_perfiles_region!! -- 
    -- !! y los botones restringidos (p_botones_restringidos) a la tabla sg_g_perfiles_boton   !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
  
    -- Cursor C1: Extre regiones/botones de las cadena que se le mande por parametro
  
    cursor C1(v_cadena in varchar2) is
      select distinct regexp_substr(v_cadena, '[^:]+', 1, level) cadena
        from dual
      connect by level <= length(regexp_replace(v_cadena, '[^:]*')) + 1
       order by cadena;
  
    -- Cursor C2: Busca la informaci??n b?!sica de una regi??n
    cursor C2(v_region_id in number) is
      select region_id, region_name
        from apex_application_page_regions
       where application_id =
             (select nmro_aplccion
                from sg_g_aplicaciones
               where id_aplccion = p_id_aplccion)
         and page_id =
             (select nmro_pgna from sg_g_menu where id_mnu = p_id_mnu)
         and region_id = v_region_id
       order by region_id;
  
    -- Cursor C3: Busca la informaci??n b?!sica de un bot??n
    cursor C3(v_button_id in number) is
      select button_id, button_name
        from apex_application_page_buttons
       where application_id =
             (select nmro_aplccion
                from sg_g_aplicaciones
               where id_aplccion = p_id_aplccion)
         and page_id =
             (select nmro_pgna from sg_g_menu where id_mnu = p_id_mnu)
         and button_id = v_button_id
       order by button_id;
  
    v_respuesta varchar2(1000) := ''; -- Variable para guardar la respuesta de la funci??n
    v_nmro_pgna number := 0; -- Variable para almacenar el n??mero de la pagina del id_mnu ingresado
  
  begin
  
    -- Se guarda en le variable v_nmro_pgna el n??mero de la p?!gina que corressponde al id_mnu (p_id_mnu)
    select nmro_pgna
      into v_nmro_pgna
      from sg_g_menu
     where id_aplccion = p_id_aplccion
       and id_mnu = p_id_mnu;
  
    -- 1. Se eliminan las regiones que estan restringidas para el men?? (p_id_mnu)
    begin
      delete from sg_g_perfiles_region
       where id_prfil = p_id_prfil
         and id_aplccion = p_id_aplccion
         and nmro_pgna = v_nmro_pgna;
      commit;
    exception
      when others then
        v_respuesta := 'Error al eliminar regiones en sg_g_perfiles_region (perfil: ' ||
                       p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                       ', P?!gina : ' || v_nmro_pgna || ') - ' || SQLCODE || '--' || '--' ||
                       SQLERRM;
        apex_error.add_error(v_respuesta,
                             p_display_location => apex_error.c_inline_in_notification);
        rollback;
    end;
  
    -- 2. Se eliminan los botones que estan restringidos para el men?? (p_id_mnu)
    begin
      delete from sg_g_perfiles_boton
       where id_prfil = p_id_prfil
         and id_aplccion = p_id_aplccion
         and nmro_pgna = v_nmro_pgna;
      commit;
    exception
      when others then
        v_respuesta := 'Error al eliminar botones en sg_g_perfiles_boton (perfil: ' ||
                       p_id_prfil || ', Aplicaci??n : ' || p_id_aplccion ||
                       ', P?!gina : ' || v_nmro_pgna || ') - ' || SQLCODE || '--' || '--' ||
                       SQLERRM;
        apex_error.add_error(v_respuesta,
                             p_display_location => apex_error.c_inline_in_notification);
        rollback;
    end;
  
    -- 3. Se insertan las regiones restringidas 
    for R1 in (select cdna
                 from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_regiones_restringidas,
                                                                    p_crcter_dlmtdor => ':'))) loop
      for R2 in (select region_id, region_name
                   from apex_application_page_regions
                  where application_id =
                        (select nmro_aplccion
                           from sg_g_aplicaciones
                          where id_aplccion = p_id_aplccion)
                    and page_id = (select nmro_pgna
                                     from sg_g_menu
                                    where id_mnu = p_id_mnu)
                    and region_id = r1.cdna
                  order by region_id) loop
        begin
          insert into sg_g_perfiles_region
            (id_prfil,
             id_aplccion,
             nmro_pgna,
             nmbre_rgion,
             id_rgion,
             username_modifica,
             fecha_modifica)
          values
            (p_id_prfil,
             p_id_aplccion,
             v_nmro_pgna,
             r2.region_name,
             r1.cdna,
             p_username_modifica,
             p_fecha_modifica);
        
          v_respuesta                              := 'Registro Exitoso';
          apex_application.g_print_success_message := v_respuesta;
        exception
          when others then
            v_respuesta := 'Error al insertar en sg_g_perfiles_region (perfil: ' ||
                           p_id_prfil || ', regi??n : ' || r1.cdna ||
                           ') - ' || SQLCODE || '--' || '--' || SQLERRM;
            apex_error.add_error(v_respuesta,
                                 p_display_location => apex_error.c_inline_in_notification);
            rollback;
        end;
        commit;
      end loop;
    end loop;
  
    -- 4. Se insertan los botones restringidos 
    for R3 in (select cdna
                 from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_botones_restringidos,
                                                                    p_crcter_dlmtdor => ':'))) loop
      for R4 in (select button_id, button_name
                   from apex_application_page_buttons
                  where application_id =
                        (select nmro_aplccion
                           from sg_g_aplicaciones
                          where id_aplccion = p_id_aplccion)
                    and page_id = (select nmro_pgna
                                     from sg_g_menu
                                    where id_mnu = p_id_mnu)
                    and button_id = r3.cdna
                  order by button_id) loop
        begin
          insert into sg_g_perfiles_boton
            (id_prfil,
             id_aplccion,
             nmro_pgna,
             nmbre_bton,
             id_bton,
             username_modifica,
             fecha_modifica)
          values
            (p_id_prfil,
             p_id_aplccion,
             v_nmro_pgna,
             r4.button_name,
             r3.cdna,
             p_username_modifica,
             p_fecha_modifica);
        
          v_respuesta                              := 'Registro Exitoso';
          apex_application.g_print_success_message := v_respuesta;
        exception
          when others then
            v_respuesta := 'Error al insertar en sg_g_perfiles_boton (perfil: ' ||
                           p_id_prfil || ', bot??n : ' || r3.cdna || ') - ' ||
                           SQLCODE || '--' || '--' || SQLERRM;
            apex_error.add_error(v_respuesta,
                                 p_display_location => apex_error.c_inline_in_notification);
            rollback;
        end;
        commit;
      end loop;
    end loop;
    return(v_respuesta);
  end fnc_restriciones_perfil;

  function fnc_breadcrums(p_cdgo_clnte in number,
                          p_aplicacion in number,
                          p_pagina     in number) return varchar2 is
    -- !! ----------------------------------------------------------------------------------------- !! --
    -- !! Funci??n quere retorna el breadcrums                           !! --
    -- !! ----------------------------------------------------------------------------------------- !! --
    cursor cApp(R_NUM_APLICACION number) is
      select id_aplccion, nmbre_aplccion
        from sg_g_aplicaciones
       where nmro_aplccion = R_NUM_APLICACION;
  
    cursor cMenu(R_COD_CIA        number,
                 R_COD_APLICACION number,
                 R_PAGINA         number) is
      select m.nmbre_mnu,
             m.id_mnu_pdre,
             (select m2.nmro_pgna
                from sg_g_menu m2
               where m2.id_mnu = m.id_mnu_pdre) pag_padre
        from sg_g_menu m
       where m.id_aplccion = R_COD_APLICACION
         and m.dstno_tpo = 1
         and m.nmro_pgna = R_PAGINA;
  
    v_breadcrumb     varchar2(2000);
    v_id_aplccion    sg_g_aplicaciones.id_aplccion%type;
    v_nmbre_aplccion sg_g_aplicaciones.nmbre_aplccion%type;
  
  begin
    -- Se obtiene la informaci??n de la aplicaci??n
    begin
      select id_aplccion, nmbre_aplccion
        into v_id_aplccion, v_nmbre_aplccion
        from sg_g_aplicaciones
       where nmro_aplccion = p_aplicacion;
    
      for c_mnu in (select m.nmbre_mnu,
                           m.id_mnu_pdre,
                           (select m2.nmro_pgna
                              from sg_g_menu m2
                             where m2.id_mnu = m.id_mnu_pdre) mnu_pdre
                      from sg_g_menu m
                     where m.id_aplccion = v_id_aplccion
                       and m.dstno_tpo = 1
                       and m.nmro_pgna = p_pagina) loop
        v_breadcrumb := c_mnu.nmbre_mnu;
      
        if (c_mnu.id_mnu_pdre is not null) then
          v_breadcrumb := fnc_breadcrums(p_cdgo_clnte,
                                         p_aplicacion,
                                         c_mnu.mnu_pdre) || '/' ||
                          v_breadcrumb;
        else
          v_breadcrumb := v_nmbre_aplccion || '/' || v_breadcrumb;
        end if;
      
      end loop;
    exception
      when others then
        v_breadcrumb := '';
    end;
    return v_breadcrumb;
  end fnc_breadcrums;

  function fnc_sub_impuestos_x_usuario(p_cdgo_clnte in number,
                                       p_id_usrio   in number)
    return g_sub_impuestos_x_usurio
    pipelined is
  
    v_count_sbmpsto number := 0;
  
  begin
  
    -- null;
    for c_impsto in (select *
                       from sg_g_usuarios_impuesto a
                      where a.id_usrio = p_id_usrio
                        and a.actvo = 'S') loop
      select count(*)
        into v_count_sbmpsto
        from sg_g_usuarios_subimpuesto a
       where a.id_usrio = p_id_usrio
         and a.id_impsto = c_impsto.id_impsto
         and a.actvo = 'S';
    
      if v_count_sbmpsto > 0 then
        for c_sbmpsto in (select a.id_impsto,
                                 a.nmbre_impsto,
                                 a.id_impsto_sbmpsto,
                                 a.nmbre_impsto_sbmpsto
                            from v_sg_g_usuarios_subimpuesto a
                           where a.id_usrio = p_id_usrio
                             and a.id_impsto = c_impsto.id_impsto
                             and a.actvo = 'S'
                           order by 2, 4) loop
          dbms_output.put_line('Impuesto: ' || c_impsto.id_impsto ||
                               ' Sub-Impuesto: ' ||
                               c_sbmpsto.id_impsto_sbmpsto);
          pipe row(c_sbmpsto);
        end loop;
      else
        for c_sbmpsto in (select a.id_impsto,
                                 upper(a.nmbre_impsto || ' [' ||
                                       a.cdgo_impsto || ']') nmbre_impsto,
                                 a.id_impsto_sbmpsto,
                                 upper(a.nmbre_impsto_sbmpsto || ' [' ||
                                       a.cdgo_impsto_sbmpsto || ']') nmbre_impsto_sbmpsto
                            from v_df_i_impuestos_subimpuesto a
                           where a.cdgo_clnte = p_cdgo_clnte
                             and a.id_impsto = c_impsto.id_impsto
                           order by 2, 4) loop
          dbms_output.put_line('Impuesto: ' || c_impsto.id_impsto ||
                               ' Sub-Impuesto: ' ||
                               c_sbmpsto.id_impsto_sbmpsto);
          pipe row(c_sbmpsto);
        end loop;
      end if;
    end loop;
  
  end fnc_sub_impuestos_x_usuario;
end pkg_sg_autorizacion;

/
