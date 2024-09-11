--------------------------------------------------------
--  DDL for Package PKG_WF_FLUJO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WF_FLUJO" as 
    
    procedure prc_rg_instancias_flujo(p_id_fljo in wf_d_flujos.id_fljo%type, 
                                      p_id_usrio in sg_g_usuarios.id_usrio%type,
                                      p_id_prtcpte in sg_g_usuarios.id_usrio%type
                                      );
    
    function fnc_co_instancias_prtcpnte(p_id_fljo in wf_d_flujos.id_fljo%type )
        return number;

end pkg_wf_flujo;

/
