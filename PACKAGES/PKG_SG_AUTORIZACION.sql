--------------------------------------------------------
--  DDL for Package PKG_SG_AUTORIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SG_AUTORIZACION" is
  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! PAQUETE QUE CONTIENE TODAS LAS UNIDADES DE PROGRAMAS DEL MODULO DE SEGURIDAD         !! --
  -- !! ESQUEMA DE AUTORIZACI??N, ESQUEMA DE AUTORIZACI??N, MENU PARA UN USUARIO         !! --
  -- !! ----------------------------------------------------------------------------------------- !! --

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que retorna select dinamico para armar el menu de un usuario            !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_get_select_menu(p_app_session   in varchar2,
                               p_app_user      in varchar2,
                               p_cdgo_clnte    in number,
                               p_aplccion_grpo in number) return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un perfil tiene permiso sobre un menu               !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_pagina_x_perfil(p_cdgo_clnte in number,
                                      p_id_prfil   in number,
                                      p_id_mnu     in number) return number;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un perfil tiene permiso sobre una region              !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_region_x_perfil(p_id_prfil      in number,
                                      p_nmro_aplccion in number,
                                      p_nmro_pgna     in number,
                                      p_id_rgion      in number,
                                      p_nmbre_rgion   in varchar2)
    return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un perfil tiene permiso sobre un bot??n               !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_boton_x_perfil(p_id_prfil      in number,
                                     p_nmro_aplccion in number,
                                     p_nmro_pgna     in number,
                                     p_id_bton       in number,
                                     p_nmbre_bton    in varchar2)
    return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un usuario tiene permiso sobre un menu                !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_pagina_x_usuario(p_cdgo_clnte    in number,
                                       p_user_name     in number,
                                       p_nmro_aplccion in number,
                                       p_nmro_pgna     in number)
    return boolean;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un usuario tiene permiso sobre una regi??n              !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_region_x_usuario(p_cdgo_clnte    in number,
                                       p_user_name     in number,
                                       p_nmro_aplccion in number,
                                       p_nmro_pgna     in number,
                                       p_nmbre_rgion   in varchar2)
    return boolean;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que valida si un usuario tiene permiso sobre un bot??n                !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_valida_boton_x_usuario(p_cdgo_clnte    in number,
                                      p_user_name     in number,
                                      p_nmro_aplccion in number,
                                      p_nmro_pgna     in number,
                                      p_nmbre_bton    in varchar2)
    return boolean;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que lista las paginas que con llamdas por los botones de la pagina (p_page_id)  !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_paginas_llamadas_x_boton(p_cdgo_clnte       in number,
                                        p_id_aplccion_grpo in number,
                                        p_nmro_aplccion    in number,
                                        p_page_id          in number,
                                        p_region_id        in number,
                                        p_id_prfil         in number,
                                        p_app_session      in number)
    return clob;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Esta funcion retorna un html con las regiones y botones de la pagina (p_id_mnu),     !! --
  -- !! ademas tambien se??ala las regiones y botones que estan restringida para         !! --
  -- !! el perfil (p_id_prfil).                                  !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_get_html_x_pgna_btn_x_pgna(p_cdgo_clnte       in number,
                                          p_id_aplccion_grpo in number default null,
                                          p_id_prfil         in number,
                                          p_id_aplccion      in number,
                                          p_id_mnu           in number,
                                          p_app_session      in number)
    return clob;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que asigna los usuarios que estan en la cadena p_usuarios al perfil (p_id_prfil)  !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_asigna_usuario_perfil(p_cdgo_clnte        in number,
                                     p_id_prfil          in number,
                                     p_usuarios          in varchar2,
                                     p_username_modifica in varchar2,
                                     p_fecha_modifica    in timestamp)
    return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que asigna al perfil (p_id_prfil) el menu (p_id_mnu)                !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_asigna_pagina_perfil(p_cdgo_clnte        in number,
                                    p_id_aplccion_grpo  in number,
                                    p_id_prfil          in number,
                                    p_id_mnu            in number,
                                    p_username_modifica in varchar,
                                    p_fecha_modifica    in timestamp)
    return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n que elimina del perfil (p_id_prfil) la pagina (p_id_mnu)junto           !! --
  -- !! con sus regiones y botones                               !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_eliminar_pagina_perfil(p_cdgo_clnte  in number,
                                      p_id_prfil    in number,
                                      p_id_aplccion in number,
                                      p_id_mnu      in number)
    return varchar2;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Esta Funci??n Elimina las regiones y los botones de la pagina ingresada (p_id_mnu) y     !! --
  -- !! agrega las regiones restringidas (p_regiones_restringidas) a la tabla sg_g_perfiles_region!! -- 
  -- !! y los botones restringidos (p_botones_restringidos) a la tabla sg_g_perfiles_boton   !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_restriciones_perfil(p_cdgo_clnte            in number,
                                   p_id_prfil              in number,
                                   p_id_aplccion           in number,
                                   p_id_mnu                in number,
                                   p_regiones_restringidas in clob,
                                   p_botones_restringidos  in clob,
                                   p_username_modifica     in varchar2,
                                   p_fecha_modifica        in timestamp)
    return clob;

  -- !! ----------------------------------------------------------------------------------------- !! --
  -- !! Funci??n quere retorna el breadcrums                           !! --
  -- !! ----------------------------------------------------------------------------------------- !! --
  function fnc_breadcrums(p_cdgo_clnte in number,
                          p_aplicacion in number,
                          p_pagina     in number) return varchar2;

  type t_sub_impuestos_x_usurio is record(
    id_impsto            number,
    nmbre_impsto         varchar2(1000),
    id_impsto_sbmpsto    df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
    nmbre_impsto_sbmpsto varchar2(1000));

  type g_sub_impuestos_x_usurio is table of t_sub_impuestos_x_usurio;

  function fnc_sub_impuestos_x_usuario(p_cdgo_clnte in number,
                                       p_id_usrio   in number)
    return g_sub_impuestos_x_usurio
    pipelined;

end pkg_sg_autorizacion;

/
