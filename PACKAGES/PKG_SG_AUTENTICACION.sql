--------------------------------------------------------
--  DDL for Package PKG_SG_AUTENTICACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SG_AUTENTICACION" is

    g_signature_key constant raw(500) := utl_raw.cast_to_raw('PMI1Y3VP3QIH53J4UB44DBBN1CIZW9');

/*
Paquete que contiene todas las unidades de programas del modulo de seguridad
Esquema de Autenticación
*/

-- Función que encripta  la clave de un usuario - 
-- gti_seg_hash
function fnc_sg_hash (p_username in varchar2, 
                      p_password in varchar2)
return varchar2;

function fnc_ge_token(p_cdna in varchar2)
return varchar2;

/*Procedimiento para la generacion de token
    30/07/2019
*/
procedure prc_cd_token(
    p_cdgo_clnte      in     number,
    p_id_usrio        in     number,
    p_app_session     in     varchar2,
    p_accion          in     varchar2,
    o_id_usrio_tken   in out varchar2,
    o_cdgo_rspsta	     out number,
    o_mnsje_rspsta       out varchar2
);

-- Función para la sutenticación de un usuario 
-- gti_seg_autenticar
function fnc_sg_autenticar (--p_cdgo_clnte	in number, 
                            p_username		in number, 
                            p_password		in varchar2) 
return boolean;

function fnc_gti_breadcrumbs(p_aplicacion  in number,
                             p_id_menu    in number,
                             p_sesion      in number,
                             p_inicial     in varchar2,
                             p_iteraciones in number) return varchar2;

function fnc_gti_generar_breadcrumbs(p_cod_cliente in number, 
                                     p_aplicacion  in number, 
                                     p_pagina      in number,
                                     p_sesion      in number) return varchar2 ;

procedure process_recaptcha_reply(p_token varchar2, p_message_out out varchar2);

  procedure prc_sg_autenticar( p_cdgo_clnte    in number
                             , p_username      in varchar2
                             , p_password      in varchar2
                             , o_cdgo_rspsta   out number
                             , o_mnsje_rspsta  out varchar2 );

end pkg_sg_autenticacion;

/
