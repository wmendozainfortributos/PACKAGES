--------------------------------------------------------
--  DDL for Package PKG_MA_ENVIOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MA_ENVIOS" as

  /*Procedimiento para la gestion de medio de envio programado*/
  procedure prc_cd_envios_programado_medio(
    p_cdgo_clnte              in  number,
    p_id_usrio                in  number,
    p_request                 in  varchar2,
    p_id_envio_prgrmdo_mdio   in  ma_g_envios_programado_mdio.id_envio_prgrmdo_mdio%type default null,
    p_id_envio_prgrmdo        in  ma_g_envios_programado_mdio.id_envio_prgrmdo%type,
    p_cdgo_envio_mdio         in  ma_g_envios_programado_mdio.cdgo_envio_mdio%type,
    p_asnto                   in  ma_g_envios_programado_mdio.asnto%type,
    p_txto_mnsje              in  ma_g_envios_programado_mdio.txto_mnsje%type,
    p_actvo                   in  ma_g_envios_programado_mdio.actvo%type              default 'S',
    o_cdgo_rspsta			  out number,
    o_mnsje_rspsta            out varchar2
  );

  --Type Destinatarios
  type t_dstntrio is record(
    id_usrio        number,
    nmbre           varchar2(500),
    nmro_cllar      varchar2(20),
    email           varchar2(500)
  );
  --Type Archivos Adjuntos
  type t_archvo is record(
    file_name       varchar2(150),
    file_mimetype   varchar2(512),
    file_blob       blob
  );

  type g_archvos_adjntos is table of t_archvo;
  type g_dstntrios is table of t_dstntrio;

  /*Procedimiento para registrar un envio*/
    procedure prc_rg_envio(
    p_cdgo_clnte                in  number,
    p_id_envio_prgrmdo          in  ma_g_envios_programado_mdio.id_envio_prgrmdo%type,
    p_fcha_rgstro               in  ma_g_envios.fcha_rgstro%type     default systimestamp,
    p_fcha_prgrmda              in  ma_g_envios.fcha_prgrmda%type    default systimestamp,
    p_json_prfrncia             in  ma_g_envios.json_prfrncia%type   default null,
    p_id_sjto_impsto            in  number default null,
    p_id_acto                   in  number default null,
    o_id_envio                  out number,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  );

  /*Procedimiento para registrar archivos adjuntos*/
  procedure prc_rg_envio_adjntos(
    p_id_envio                  in  ma_g_envios_medio.id_envio%type,
    p_file_blob                 in  ma_g_envios_adjntos.file_blob%type,
    p_file_name                 in  ma_g_envios_adjntos.file_name%type,
    p_file_mimetype             in  ma_g_envios_adjntos.file_mimetype%type,
    o_id_envio_adjnto           out ma_g_envios_adjntos.id_envio_adjnto%type,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  );

  /*Procedimiento para registrar un envio medio*/
  procedure prc_rg_envio_mdio(
    p_id_envio                  in ma_g_envios_medio.id_envio%type,
    p_cdgo_envio_mdio           in ma_g_envios_medio.cdgo_envio_mdio%type,
    p_dstno                     in ma_g_envios_medio.dstno%type,
    p_asnto                     in ma_g_envios_medio.asnto%type,
    p_txto_mnsje                in ma_g_envios_medio.txto_mnsje%type,
    o_id_envio_mdio             out ma_g_envios_medio.id_envio_mdio%type,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  );

  /*Procedimiento para registrar estado asociado a un envio*/
  procedure prc_rg_envio_estado(
    p_id_envio_mdio             in  ma_g_envios_mdio_trza_estdo.id_envio_mdio%type,
    p_cdgo_envio_estdo          in  ma_g_envios_mdio_trza_estdo.cdgo_envio_estdo%type,
    p_obsrvcion                 in  ma_g_envios_mdio_trza_estdo.obsrvcion%type          default null,
    o_cdgo_rspsta			    out number,
    o_mnsje_rspsta              out varchar2
  );

  /*Procedimiento para registrar envio */
      procedure prc_rg_envios(
    p_id_envio_prgrmdo          in ma_g_envios_programado.id_envio_prgrmdo%type,
    p_json_prmtros              in  clob  default null,
    p_id_sjto_impsto            in number default null,
    p_id_acto                   in number default null 
  );

  /*Procedimiento para la gestion de envios programados*/
  procedure prc_ge_envios_programados;

  /*Funcion para validar si se registra un envio*/
  function fnc_vl_registra_envio(p_id_envio_prgrmdo in ma_g_envios_programado.id_envio_prgrmdo%type) return boolean;

  /*Funcion para validar si las condiciones de un envio programado se cumplen
  function fnc_vl_condiciones_envio(
    p_id_envio_prgrmdo  in ma_g_envios_programado.id_envio_prgrmdo%type,
    p_json              in clob                                         default null
  ) return boolean;*/

  /*Funcion para obtener el valor de una clave en un JSON*/
  function fnc_co_valor_json(
    p_json in clob,
    p_prmtro in varchar2
  )return varchar2;

  /*Procedimiento para consultar envio programado*/
   /*Procedimiento para consultar envio programado*/
  procedure prc_co_envio_programado(
    p_cdgo_clnte                in  number,
    p_idntfcdor                 in varchar2,
    p_json_prmtros              in  clob default null,
    p_id_sjto_impsto            in  number default null,
    p_id_acto                   in  number default null
  );

  /*Procedimiento para gestionar los envios*/
  procedure prc_ge_envios;

  /*Procedimiento para consultar las configuraciones de un medio de envio*/
  procedure prc_co_configuraciones(
    p_id_envio_mdio                     in  ma_g_envios_medio.id_envio_mdio%type,
    o_rt_ma_g_envios_medio              out ma_g_envios_medio%rowtype,
    o_rt_ma_d_envios_medio_cnfgrcion    out ma_d_envios_medio_cnfgrcion%rowtype,
    o_json_parametros                   out clob,
    o_json_preferencias                 out clob,
    o_cdgo_rspsta			            out number,
    o_mnsje_rspsta                      out varchar2
  );

  procedure prc_co_configuraciones(
    p_cdgo_clnte                        in  number,
    p_cdgo_envio_mdio                   in  ma_g_envios_medio.cdgo_envio_mdio%type,   
    o_rt_ma_d_envios_medio_cnfgrcion    out ma_d_envios_medio_cnfgrcion%rowtype,
    o_cdgo_rspsta			            out number,
    o_mnsje_rspsta                      out varchar2
  );

  /*Funcion para consular columnas requeridas segun los medios de un envio programado*/
  function fnc_co_columnas_json_envios_programado(
    p_id_envio_prgrmdo                  in  ma_g_envios_programado.id_envio_prgrmdo%type
  ) return varchar2;

  /*Funcion para consultar JSON de preferencias de un medio de envio*/
  function fnc_co_json_medio_preferencias(
    p_id_envio_prgrmdo             in  ma_g_envios.id_envio%type
  ) return clob;

  /*Funcion para consultar JSON de configuraciones*/
  function fnc_co_json_configuraciones(
    p_id_envio_mdio_cnfgrcion  in  number
  ) return clob;

  /*Funcion para validar la confirmacion de un envio programado*/
  function fnc_vl_valida_confirmacion_envio_programado(p_id_envio_prgrmdo in  ma_g_envios_programado.id_envio_prgrmdo%type) return varchar2;

end pkg_ma_envios;

/
