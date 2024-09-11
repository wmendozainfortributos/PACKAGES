--------------------------------------------------------
--  DDL for Package PKG_GD_UTILIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GD_UTILIDADES" IS

  function fnc_vl_archvo_exstnte (p_directorio varchar2, p_nmbre_archvo varchar2)
    return varchar2;

  function fnc_vl_archvo_blqdo (p_directorio varchar2, p_nmbre_archvo varchar2)
    return varchar2;

  procedure prc_co_archco_dsco (p_directorio    varchar2    default null
                              , p_nmbre_archvo  varchar2    default null
                              , p_bfile         bfile       default null
                              , o_archvo_blob   out blob
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2);

  procedure prc_co_archco_dsco_id (p_id_dcmnto      number
                                 , o_archvo_blob    out blob
                                 , o_cdgo_rspsta    out number
                                 , o_mnsje_rspsta   out varchar2);

  procedure prc_rg_dcmnto_dsco (p_blob          in blob
                              , p_directorio    in varchar2
                              , p_nmbre_archvo  in varchar2
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2);

  procedure prc_el_archvo_dsco (p_directorio    varchar2
                              , p_nmbre_archvo  varchar2
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2);


  /* fnc_vl_archvo_exstnte
     Funcion que retorna S si el archivo p_file_bfile existe en el directorio
    de lo contrario retorna  N */
  function fnc_vl_archvo_exstnte (p_bfile bfile) return varchar2;


  function fnc_co_blob (p_id_acto number)  return blob;  


  -- get_nombre_directorio
  -- Obtiene el Nombre de la Carpeta del BFILE
  function fnc_co_nombre_directorio ( p_file_bfile bfile ) return varchar2;


  -- get_nombre_archivo
  -- Obtiene el Nombre del Archivo del BFILE
  function fnc_co_nombre_archivo ( p_file_bfile bfile ) return varchar2;


END pkg_gd_utilidades;

/
