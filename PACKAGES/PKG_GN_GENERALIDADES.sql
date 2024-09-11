--------------------------------------------------------
--  DDL for Package PKG_GN_GENERALIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GN_GENERALIDADES" as

  function fnc_cl_consecutivo(p_cdgo_clnte number, p_cdgo_cnsctvo varchar2)
    return number;

  function fnc_cl_defniciones_cliente(p_cdgo_clnte                number,
                                      p_cdgo_dfncion_clnte_ctgria varchar2,
                                      p_cdgo_dfncion_clnte        varchar2)
    return varchar2;

  function fnc_vl_fcha_vncmnto_tsas_mra(p_cdgo_clnte   number,
                                        p_id_impsto    number,
                                        p_fcha_vncmnto date) return varchar2;

  function fnc_cl_id_acto_tpo(p_cdgo_clnte    number,
                              p_cdgo_acto_tpo varchar2) return number;

  function fnc_cl_json_acto(p_cdgo_clnte          number,
                            p_cdgo_acto_orgen     varchar2,
                            p_id_orgen            number,
                            p_id_undad_prdctra    number,
                            p_id_acto_tpo         number,
                            p_acto_vlor_ttal      number,
                            p_cdgo_cnsctvo        varchar2,
                            p_id_acto_rqrdo_hjo   number default null,
                            p_id_acto_rqrdo_pdre  number default null,
                            p_fcha_incio_ntfccion varchar2 default null,
                            p_id_usrio            number,
                            p_slct_sjto_impsto    in clob default null,
                            p_slct_vgncias        in clob default null,
                            p_slct_rspnsble       in clob default null)
    return clob;

  procedure prc_rg_acto(p_cdgo_clnte   in number,
                        p_json_acto    in clob,
                        o_id_acto      out number,
                        o_cdgo_rspsta  out number,
                        o_mnsje_rspsta out varchar2);

  procedure prc_ac_acto(p_id_acto         in gn_g_actos.id_acto%type,
                        p_ntfccion_atmtca gn_d_actos_tipo_tarea.ntfccion_atmtca%type,
                        p_file_blob       in blob default null,
                        p_directory       in varchar2 default null,
                        p_file_name_dsco  in varchar2 default null);

  function fnc_cl_texto_codigo_barra(p_cdgo_clnte        number,
                                     p_id_impsto         number,
                                     p_id_impsto_sbmpsto number,
                                     p_nmro_dcmnto       number,
                                     p_vlor_ttal         number,
                                     p_fcha_vncmnto      date)
    return varchar2;

  function fnc_cl_formato_texto(p_txto           varchar2,
                                p_frmto          varchar2,
                                p_crcter_dlmtdor varchar2) return varchar2;

  function fnc_cl_convertir_blob_a_base64(p_blob blob) return clob;
  
  function fnc_cl_convertir_blob_a_clob (blob_in in blob) return clob;

  function fnc_co_bancos_recaudadores(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number)
    return varchar2;
  type t_dtos_vgncias_sldo is record(
    vgncia_sldo varchar2(2000),
    vlor_ttal   number);

  type g_dtos_vgncias_sldo is table of t_dtos_vgncias_sldo;

  function fnc_co_vigencias_con_saldo(p_cdgo_clnte     number,
                                      p_id_sjto_impsto number)
    return g_dtos_vgncias_sldo
    pipelined;

  function fnc_co_vigencias_con_saldo(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number,
                                      p_id_sjto_impsto    number)
    return g_dtos_vgncias_sldo
    pipelined;

  type t_split is record(
    vlor number,
    cdna varchar2(4000));

  type g_split is table of t_split;

  function fnc_ca_split_table(p_cdna clob, p_crcter_dlmtdor varchar2)
    return g_split
    pipelined;

  procedure prc_cd_reportes_cliente(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                    p_json         in clob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion    : Calcula el Valor de un Nodo de un XML
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 26/10/2018
  * @Modificacion   : 26/10/2018
  */

  function fnc_ca_extract_value(p_xml  in varchar2,
                                p_nodo in varchar2,
                                p_path in varchar2 default '[1]')
    return varchar2;

  --Separador de Parametro
  g_sprdor_p_xml_prmtro constant varchar2(1) := ';';
  --Separador de Valor
  g_sprdor_v_xml_prmtro constant varchar2(1) := '|';

  /*
  * @Descripcion    : Genera el XML Apartir del Estandar (parametro:valor#)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 26/10/2018
  * @Modificacion   : 26/10/2018
  * @Nota           : '#' Separador de Parametros
  */

  function fnc_ge_xml_prmtro(p_cdna in varchar2) return varchar2;

  function fnc_ge_dcmnto(p_xml        in varchar2,
                         p_id_plntlla in gn_d_plantillas_consulta.id_plntlla%type)
    return clob;
  /*
    * @Descripcion    : Reemplaza la numeracion de las variables
    * @Autor          : Analista de desarrollo Carlos Nova
    * @Creacion       : 08/05/2019
    * @Modificacion   : 08/05/2019
  */
  function fnc_ca_variables(p_dcmnto in clob) return clob;

  function fnc_clob_replace(p_source  in clob,
                            p_search  in varchar2,
                            p_replace in clob) return clob;
  /*p_expresion round( :1 , numero )*/
  function fnc_ca_expresion(p_vlor in number, p_expresion in varchar2)
    return number;

  /*Crea Una Session en APEX*/
  procedure prc_rg_apex_session(p_app_id      in apex_applications.application_id%type,
                                p_app_user    in apex_workspace_activity_log.apex_user%type,
                                p_app_page_id in apex_application_pages.page_id%type default 1);
  /*Encode Base64*/
  function fnc_ge_to_base64(t in varchar2) return varchar2;

  /*Decode Base64*/
  function fnc_ge_from_base64(t in varchar2) return varchar2;

  /*funcion para pasar Numeros a letras*/
  function fnc_number_to_text(v_numero in number, v_tpo in varchar2)
    return varchar2;

  function fnc_date_to_text(p_fcha date) return varchar2;

  type t_rspstas is record(
    id_orgen         number,
    indcdor_vldccion varchar2(1),
    mnsje            varchar2(4000));

  type g_rspstas is table of t_rspstas;

  procedure prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion in clob,
                                  p_xml                        in varchar2,
                                  o_indcdor_vldccion           out varchar2,
                                  o_rspstas                    out pkg_gn_generalidades.g_rspstas);

  --Up del Proceso de Aplicacion - (Imprimir_Multiples_Reportes)
  procedure prc_ge_reportes_multiples;

  procedure prc_ge_excel_sql(p_sql            in clob,
                             o_file_blob      out blob,
                             o_msgerror       out varchar2,
                             p_column_headers in boolean default true,
                             p_sheet          in pls_integer default null);

  function fnc_co_formatted_type(p_tipo varchar2, p_valor varchar2)
    return varchar2;

  function fnc_cl_fecha_texto(p_fecha date) return varchar2;

  ---Procedimiento para generar el id de la tabla de parametros xml para reportes 
  function fnc_ge_id_rprte_prmtro return varchar2;

  -- procedimiento para insertar en la tabla temporal para generar reteportes
  procedure prc_rg_t_reportes_parametro(p_id_rprte_prmtro in varchar2,
                                        p_dta             in clob,
                                        o_cdgo_rspsta     out number,
                                        o_mnsje_rspsta    out varchar2);

  /*
    * @Descripcion    : Procedimiento utilizado en la creacion de JOBS
    * @Autor          : Julio Diaz
    * @Creacion       : 29/05/2019
    * @Modificacion   : 29/05/2019
  */
  type t_prmtrs is table of varchar2(4000);
  procedure prc_rg_creacion_jobs(p_cdgo_clnte      in number,
                                 p_job_name        in varchar2,
                                 p_job_action      in varchar2,
                                 p_t_prmtrs        in t_prmtrs,
                                 p_start_date      in timestamp with time zone,
                                 p_repeat_interval in varchar2 default null,
                                 p_end_date        in timestamp with time zone default null,
                                 p_auto_drop       in boolean default true,
                                 p_comments        in varchar2,
                                 o_cdgo_rspsta     out number,
                                 o_mnsje_rspsta    out varchar2);

  /*
    * @Descripcion    : Valida si la Cadena es Valida (1/0)
    * @Autor          : Ing. Nelson Ardila
    * @Creacion       : 01/11/2019
    * @Modificacion   : 01/11/2019
  */

  function fnc_vl_regexp(cadena in varchar2, expresion in varchar2)
    return number;

  /*
    * @Descripcion    : Valida si una cadena cumple con una expresion regular.
    * @Creacion       : 01/11/2019
    * @Modificacion   : 01/11/2019
  */
  function fnc_vl_expresion(p_cdgo_exp   in varchar2,
                            p_cdgo_clnte in number default v('F_CDGO_CLNTE'),
                            p_mnsje      in varchar2 default null,
                            p_vlor       in varchar2) return varchar2;

  procedure prc_rg_migracion(p_cdgo_clnte   in number,
                             p_cdgo_mgrcion in varchar2,
                             p_obj_arr      in json_array_t,
                             v_key          in varchar2 default null,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2);

  function fnc_co_html(p_html clob) return clob;
  function fnc_vl_html( p_html in clob) return boolean;
  
  procedure prc_html_dividir( p_html 			in clob
                            , p_tmno			in number 	default 10000
                            , o_cdgo_mnsje	    out number
                            , o_mnsje_rspsta	out varchar2);
                            

  function fnc_html_escape ( p_html in clob ) return clob;

  -- Migrada de Pruebas por JAGUAS 23/04/2021
  function fnc_vl_pago_pse(p_cdgo_clnte          in number,
                           p_cdgo_impsto         in varchar2,
                           p_cdgo_impsto_sbmpsto in number default null)
    return varchar2;

  -- Procedimiento que consulta un archivo de la tabla temporal APEX_APPLICATION_TEMP_FILES
  procedure prc_co_archivo_apex_temp_file(p_nmbre_archvo  in varchar2,
                                          o_file_blob     out blob,
                                          o_file_name     out varchar2,
                                          o_file_mimetype out varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2);

  -- Procedimiento que consulta un archivo alojado en el servidor
  procedure prc_co_archivo_disco_servidor(p_drctrio       in varchar2,
                                          p_nmbre_archvo  in varchar2,
                                          o_file_blob     out blob,
                                          o_file_name     out varchar2,
                                          o_file_mimetype out varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2);

  procedure prc_rg_registros_impresion(p_json_regstros in clob,
                                       p_cdgo_imprsion in varchar2,
                                       p_id_usrio      in number,
                                       p_id_session    in number default v('APP_SESSION'),
                                       o_ttal_rgstros  out number,
                                       o_cdgo_rspsta   out number,
                                       o_mnsje_rspsta  out varchar2);

  /*
      Descripcion: Permitir seleccion de candidatos mediante archivo Excel 
                   a quellos procesos que usen lotes de seleccion.
      Creacion:       30-09-2021
      Modificacion:   30-09-2021
  */
  procedure prc_rg_seleccion_cnddts_archvo(p_cdgo_clnte    in number,
                                           p_id_prcso_crga in number,
                                           p_id_lte        in number,
                                           o_cdgo_rspsta   out number,
                                           o_mnsje_rspsta  out varchar2);

    /*
      Autor : BVILLEGAS
      Creado : 21/09/2023
      Descripción: Función que devuelve el anterior día hábil a partir de una fecha
    */
    function fnc_cl_antrior_dia_habil(p_cdgo_clnte number, p_fecha in date) return date;
    
end pkg_gn_generalidades;

/
