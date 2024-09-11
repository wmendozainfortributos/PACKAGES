--------------------------------------------------------
--  DDL for Package PKG_CB_PROCESO_PERSUASIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_CB_PROCESO_PERSUASIVO" as

  /* Creacion: 14-07-2021
     Modificacion: 14-07-2021
     Autor(es): Jose Aguas
     Descripcion: Procedimiento que procesa la poblacion seleccionada
          para iniciar la gestion del proceso de cobro persuasivo.
  */
  procedure prc_rg_proceso_persuasivo(p_cdgo_clnte        in  number
                                      , p_id_usuario      in  number
                    , p_json_sjtos        in  clob
                    , p_msvo          in  varchar2
                                      , o_cdgo_rspsta       out number
                                      , o_mnsje_rspsta      out varchar2);
    /* Creacion: 16-07-2021
     Modificacion: 21-07-2021
     Autor(es): Jose Aguas
     Descripcion: Procedimiento que realiza la generacion de actos de cobro persuasivo.
  */
    procedure prc_gn_documento_persuasivo(p_cdgo_clnte           in number,
                                          p_json_dcmntos_prrsvo  in clob,
                                          p_id_usrio             in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

    /* Creacion: 21-07-2021
     Modificacion: 21-07-2021
     Autor(es): Jose Aguas
     Descripcion: Funcion que retorna valor de parametros de configuracion.
  */
    function fnc_cl_parametro_configuracion(p_cdgo_clnte in number,
                                            p_cdgo_cnfgrcion in varchar2)
    return clob;

end pkg_cb_proceso_persuasivo;

/
