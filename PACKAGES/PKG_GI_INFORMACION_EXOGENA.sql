--------------------------------------------------------
--  DDL for Package PKG_GI_INFORMACION_EXOGENA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_INFORMACION_EXOGENA" as
    
    /*
        Autor: Jose Aguas, Brayan Villegas
        Creada el: 23-07-2021
        Modificada en: 23-07-2021
        Descripcion: Procedimiento que traslada informacion exogena 
					 hacia las tablas de gestion de exogena.
    */
    procedure prc_rg_informacion_exogena(p_cdgo_clnte           in number,
                                         p_id_infrmcion_exgna   in number,
                                         p_id_usrio             in number,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);
                                         
    -- Funcion para validar datos numericos
    function fnc_vl_dato_numerico(v_vlor in varchar2) return varchar2;
    
    procedure prc_gn_rprte_rtncnes_rd(p_cdgo_clnte   number,
                                    p_idntfccion   in varchar2,
                                    p_vgncia       in varchar2,
                                    p_tpo_rtncion  in varchar2,
                                    o_file_blob    out blob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);

end pkg_gi_informacion_exogena;

/
