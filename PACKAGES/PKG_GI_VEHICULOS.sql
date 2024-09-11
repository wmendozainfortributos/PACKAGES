--------------------------------------------------------
--  DDL for Package PKG_GI_VEHICULOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_VEHICULOS" AS
  /*R.R:R.R*/
  /*
  Procedimiento para registrar: Sujeto, sujeto impuesto y responsables.
  Registra vehiculo puntualmente.
  */
  procedure prc_rg_sujeto_impuesto_vehiculos(p_json_v       in clob,
                                             o_sjto_impsto  out number,
                                             o_cdgo_rspsta  out number,
                                             o_mnsje_rspsta out varchar2);

  -- Procedimiento para registrar Vehiculo en si_i_vehiculos
  procedure prc_rg_vehiculos(p_json         in json_object_t,
                             o_id_vhclo     out si_i_personas.id_prsna%type,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2);

  --Procedimiento para registrar Vehiculo masivo en si_i_vehiculos
  procedure prc_rg_msvo_vehiculos(p_json_v       in clob,
                                  o_sjto_impsto  out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  --procedimiento para realizar el calculo del avaluoc por vigencias
  procedure prc_cl_avaluos_vehiculo(p_cdgo_clnte        in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia            in number,
                                    p_id_clse_ctgria    in number,
                                    p_cdgo_mrca         in varchar2,
                                    p_id_lnea           in number,
                                    p_cldrje            in number,
                                    p_cpcdad            in number,
                                    p_cdgo_srvcio       in number,
                                    p_cdgo_oprcion      in number,
                                    p_cdgo_crrcria      in number,
                                    p_mdlo              in number,
                                    p_vlor_factura      in number,
                                    p_fcha_mtrcla       in date,
                                    p_fcha_cmpra        in date,
                                    p_fcha_imprtcion    in date,
                                    p_indcdor_blnddo    in varchar2,
                                    p_indcdor_clsco     in varchar2,
                                    p_indcdor_intrndo   in varchar2,
                                    o_trfa              out number,
                                    o_fraccion          out number,
                                    o_avluo_clcldo      out number,
                                    o_grupo             out number,
                                    o_avluo             out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  --procedimiento  para registrar liquidacion vehiculos..
  procedure prc_rg_liquidacion_vehiculo(p_cdgo_clnte          in number,
                                        p_id_impsto           in number,
                                        p_id_impsto_sbmpsto   in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_prdo             in number,
                                        p_lqdcion_vgncia      in number,
                                        p_cdgo_lqdcion_tpo    in varchar2,
                                        p_bse_grvble          in number,
                                        p_id_vhclo_grpo       in number,
                                        p_cdgo_prdcdad        in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                        p_id_usrio            in number,
                                        p_id_vhclo_lnea       in number,
                                        p_clndrje             in number,
                                        p_cdgo_vhclo_blndje   in varchar2,
                                        p_fraccion            in number,
                                        p_bse_grvble_clda     in number,
                                        p_trfa                in number,
                                        o_id_lqdcion          out number,
                                        o_id_lqdcion_ad_vhclo out number,
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2);

  /*liquidacion general de vehiculos */

  procedure prc_rg_liquidacion_vehiculo_general(p_cdgo_clnte         in number,
                                                p_id_impsto          in number,
                                                p_id_impsto_sbmpsto  in number,
                                                p_id_sjto_impsto     in number,
                                                p_vgncia             in number,
                                                p_id_vhclo_lnea      in number,
                                                p_clndrje            in number,
                                                p_cdgo_vhclo_blndje  in varchar2,
                                                p_id_prdo            in number,
                                                p_cdgo_lqdcion_tpo   in varchar2,
                                                p_id_usrio           in number,
                                                p_cdgo_prdcdad       in varchar2,
                                                p_clse_ctgria        in varchar2,
                                                p_cdgo_vhclo_mrca    in varchar2,
                                                p_cdgo_vhclo_srvcio  in varchar2,
                                                p_cdgo_vhclo_oprcion in varchar2,
                                                p_cdgo_vhclo_crrcria in varchar2,
                                                p_mdlo               in number,
                                                p_avluo              in number,
                                                o_id_lqdcion         out number,
                                                o_cdgo_rspsta        out number,
                                                o_mnsje_rspsta       out varchar2);

  /* procedure prc_rg_liquidacion_vehiculo_general(p_cdgo_clnte        in number,
  p_id_impsto         in number,
  p_id_impsto_sbmpsto in number,
  p_id_sjto_impsto    in number,
  p_vgncia            in number,
  p_id_vhclo_lnea     in number,
  p_clndrje           in number,
  p_cdgo_vhclo_blndje in varchar2,
  p_id_prdo           in number,
  p_cdgo_lqdcion_tpo  in varchar2,
  p_id_usrio          in number,
  p_cdgo_prdcdad      in varchar2,
  o_id_lqdcion        out number,
  o_cdgo_rspsta       out number,
  o_mnsje_rspsta      out varchar2);*/

  /* consulta de datos de vehiculos */
  procedure prc_co_datos_vehiculo(p_id_sjto_impsto in number,
                                  p_vehiculos      out sys_refcursor);

  --Funcion para consultar placa asociada a un vehiclo existente
  function fnc_co_vehiculo_placa(p_cdgo_clnte in number,
                                 p_id_impsto  in number,
                                 p_plca       in varchar2) return number;

  --Funcion para validar numero de motor existente
  function fnc_co_vehiculo_nmro_mtor(p_cdgo_clnte in number,
                                     p_id_impsto  in number,
                                     p_nmro_mtor  in varchar2)
    return varchar2;

  --Funcion para validar numero de chasis existente
  function fnc_co_vehiculo_nmro_chsis(p_cdgo_clnte in number,
                                      p_id_impsto  in number,
                                      p_nmro_chsis in varchar2)
    return varchar2;

  --Funcion para validar numero de matricula existente
  function fnc_co_vehiculo_nmro_mtrcla(p_cdgo_clnte  in number,
                                       p_id_impsto   in number,
                                       p_nmro_mtrcla in varchar2)
    return varchar2;
  --funcion consulta grupo al que pertenece el vehiculo.
  function fnc_co_vehiculo_grupo(p_cdgo_clnte           in number,
                                 p_vgncia               in number,
                                 p_id_vhclo_clse_ctgria in number,
                                 p_cdgo_vhclo_mrca      in varchar2,
                                 p_id_vhclo_lnea        in number,
                                 p_cldrje               in number,
                                 p_cpcdad               in number,
                                 p_cdgo_vhclo_srvcio    in number,
                                 p_cdgo_vhclo_oprcion   in number,
                                 p_cdgo_vhclo_crrcria   in number)
    return number;

  --funcion consulta de avaluos de vehiculos
  function fnc_co_vehiculo_avaluos(p_cdgo_clnte in number,
                                   p_grpo       in number,
                                   p_mdlo       in number) return number;

  --funcion consulta tarifa de vehiculos
  function fnc_co_vehiculo_tarifa(p_cdgo_clnte        in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_clse_ctgria    in number,
                                  p_bse               in number,
                                  p_vgncia            in number)
    return number;

  ---calculamos fecha fraccion de vehiculos.
  function fnc_co_vehiculo_fraccion(p_cdgo_clnte     in number,
                                    p_vgncia         in number,
                                    p_fecha_vehiculo in date) return number;

  -- funcion para inactivar una liquidacion
  function fnc_ac_liquidacion_vehiculo(p_lquidcion          in number,
                                       p_cdgo_lqdcion_estdo in varchar2)
    return number;

  type reg_dtos_liquidado is record(
    id_lqdcion number,
    vgncia     number,
    bse_grvble gi_g_liquidaciones_concepto.bse_cncpto%type,
    vlor_ttal  number,
    tarifa     gi_g_liquidaciones_concepto.trfa%type);

  type tab_dtos_liquidado is table of reg_dtos_liquidado;

  /* Funcion que consulta la liquidacion por vigncias (Declaraciones)  */
  function fnc_co_liquidacion_vgncia(p_id_sjto_impsto             in number,
                                     p_id_dclrcion_vgncia_frmlrio in number)
    return tab_dtos_liquidado
    pipelined;
  /* Funcion que consulta la tarifa anterior  */
  function fnc_co_tarifa_anterior(p_cdgo_clnte     in number,
                                  p_id_impsto      in number,
                                  p_id_sjto_impsto in number,
                                  p_vgncia         in number) return number;

  /* Funcion que calcula el avaluo de variacion  */
  function fnc_co_vehiculo_variacion(p_cdgo_clnte in number,
                                     p_vgncia     in number,
                                     p_avaluo     in number,
                                     p_blndado    in varchar2,
                                     p_clasico    in varchar2,
                                     p_internado  in varchar2) return number;

  /* procedimiento  */
  procedure prc_co_estdo_lqdcion_vehiculos(p_cdgo_clnte        in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_sjto_impsto    in number,
                                           p_vgncia            in number,
                                           p_id_prdo           in number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  /* Funcion que consulta si el estado de las liquidaciondes de un sujeto impuesto
     si esta en cartera o cuenta con liquidacion valida
  */
  type reg_estdo_lqdcion is record(
    dscrpcion  varchar2(50),
    indcdor    number,
    id_lqdcion number);
  type tab_estdo_lqdcion is table of reg_estdo_lqdcion;

  function fnc_co_liquidacion_estado(p_id_sjto_impsto in number,
                                     p_vgncia         in number,
                                     p_id_priodo      in number)
    return tab_estdo_lqdcion
    pipelined;

  /* Funcion reporte de liquidacion oficial de vehiculos */
  type reg_lqudacion_ofcl is record(
    nombres        varchar2(200),
    identificacion varchar2(50),
    direccion      varchar2(100),
    departamento   varchar2(100),
    municipio      varchar2(100),
    email          varchar2(100),
    cdgo_postal    varchar2(100),
    telefono       number,
    /*vehiculo */
    placa         varchar2(50),
    marca         varchar2(50),
    motor         varchar2(50),
    linea         varchar2(50),
    modelo        number,
    clase         varchar2(50),
    carroceria    varchar2(50),
    blindado      varchar2(100),
    pasajero      number,
    carga         number,
    cilindraje    number,
    municipio_veh varchar2(50),
    cdgo_munc     number,
    /* declaracion - liquidacion  */
    avaluo    number,
    tarifa    number,
    impuesto  number,
    intereses number,
    sancion   number,
    descuento number,
    total     number);

  type tab_lqudacion_ofcl is table of reg_lqudacion_ofcl;

  function fnc_co_liquidacion_oficial(p_cdgo_clnte        in number,
                                      p_id_impsto         in number,
                                      p_id_impsto_sbmpsto in number,
                                      p_id_sjto_impsto    in number,
                                      p_vgncia            in number)
    return tab_lqudacion_ofcl
    pipelined;

  /* Funcion reporte de documento de pago vehiculos */
  type reg_dcmto_vhclo is record(
    nombres             varchar2(200),
    tipo_identificacion varchar2(50),
    identificacion      varchar2(50),
    direccion           varchar2(100),
    departamento        varchar2(100),
    municipio           varchar2(100),
    email               varchar2(100),
    telefono            number,
    /*vehiculo */
    placa         varchar2(50),
    marca         varchar2(50),
    linea         varchar2(50),
    modelo        number,
    clase         varchar2(50),
    carroceria    varchar2(50),
    blindado      varchar2(100),
    pasajero      number,
    carga         number,
    cilindraje    number,
    municipior    varchar2(50),
    departamentor varchar2(50),
    /* documento - liquidacion  */
    impuesto  number,
    intereses number,
    sancion   number,
    descuento number,
    total     number);

  type tab_dcmnto_vhclo is table of reg_dcmto_vhclo;

  function fnc_co_dcmnto_vhclo(p_cdgo_clnte        in number,
                               p_id_impsto         in number,
                               p_id_impsto_sbmpsto in number,
                               p_id_sjto_impsto    in number,
                               p_vgncia            in number)
    return tab_dcmnto_vhclo
    pipelined;

  function fnc_co_acto_determinacion(p_id_lqdcion in number) return number;

  -- Procedimiento para generar acto de determinacion (liquidacion oficial)
  procedure prc_gn_blob_determinacion(p_id_rprte     in number,
                                      p_json         in clob,
                                      o_blob         out blob,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);
  --procedieminto para genrar datos adjunto de vehiculos
  procedure prc_a_adjunto_doc(p_id_sjto_impsto number default null,
                              p_file_blob      blob,
                              p_file_name      varchar2,
                              p_file_mimetype  varchar2,
                              p_estdo          varchar2,
                              p_orgn           varchar2,
                              o_cdgo_rspsta    out number,
                              o_mnsje_rspsta   out varchar2);
  --calcula el total de d?as entre 2 fechas
  function fnc_co_calculodias(p_fecini date, p_fecfin date) return number;

  /* calculo de la sancion en vehiculos */
  function fnc_co_clclar_sancion(p_fechpyccion date, tpo_esqma in varchar2)
    return number;

  --procedimiento genaracion de informacion de ministerio */
  type reg_datos_mnstrio_marca is record(
    cdgo_marca varchar2(4000),
    dscrpcion  varchar2(4000));

  type reg_datos_mnstrio_lnea is record(
    cdgo_marca varchar2(4000),
    dscrpcion  varchar2(4000));

  type reg_datos_mnstrio_grpo is record(
    vgncia     varchar2(4000),
    cdgo_marca varchar2(4000),
    linea      varchar2(4000),
    cilindraje varchar2(4000),
    clase      varchar2(4000),
    desc_marca varchar2(4000));

  type tab_datos_mnstrio_marca is table of reg_datos_mnstrio_marca;
  type tab_datos_mnstrio_lnea is table of reg_datos_mnstrio_lnea;
  type tab_datos_mnstrio_grupo is table of reg_datos_mnstrio_grpo;

  procedure prc_rg_infrmcion_mnstrio(p_cdgo_clnte    in number,
                                     p_id_prcso_crga in number);
  function fnc_rg_crga_marca(p_id_prcso_crga in number) return number;
  function fnc_rg_crga_linea(p_id_prcso_crga in number) return number;
  function fnc_rg_crga_grupo(p_cdgo_clnte    in number,
                             p_id_prcso_crga in number) return number;
  function fnc_rg_carga_avaluo(p_id_prcso_crga in number,
                               p_id_grpo       number,
                               p_mdlo_ini      in number,
                               p_column_ini    in number,
                               p_column_fin    number) return number;

  -- procedimiento registro de gestion de novedades de vehiculos
  procedure prc_rg_nvdds_vhclos_general(p_cdgo_clnte            in number,
                                        p_id_impsto             in number,
                                        p_id_impsto_sbmpsto     in number,
                                        p_id_sjto_impsto        in number,
                                        p_cdgo_nvda             in varchar2,
                                        p_id_acto_tpo           in number,
                                        p_fcha_incio_aplccion   in date,
                                        p_obsrvcion             in varchar2,
                                        p_id_slctud             in number,
                                        p_id_instncia_fljo      in number,
                                        p_id_instncia_fljo_pdre in number,
                                        p_id_usrio              in number,
                                        p_id_prcso_crga         in number,
                                        p_fcha_nvdad_vhclo      in date,
                                        p_id_usrio_aplco        in number,
                                        o_id_nvdad_vhclo        out number,
                                        o_cdgo_rspsta           out number,
                                        o_mnsje_rspsta          out varchar2);
  --procedimiento de actulizacion datos vehiculos
  procedure prc_ac_datos_vehiculo(p_id_sjto_impsto          in number,
                                  p_cdgo_vhclo_clse         in varchar2,
                                  p_cdgo_vhclo_mrca         in varchar2,
                                  p_id_vhclo_lnea           in number,
                                  p_nmro_mtrcla             in varchar2,
                                  p_fcha_mtrcla             in date,
                                  p_cdgo_vhclo_srvcio       in varchar2,
                                  p_vlor_cmrcial            in number,
                                  p_fcha_cmpra              in date,
                                  p_avluo                   in number,
                                  p_clndrje                 in number,
                                  p_cpcdad_crga             in number,
                                  p_cpcdad_psjro            in number,
                                  p_cdgo_vhclo_crrcria      in varchar2,
                                  p_nmro_chsis              in varchar2,
                                  p_nmro_mtor               in varchar2,
                                  p_mdlo                    in number,
                                  p_cdgo_vhclo_cmbstble     in varchar2,
                                  p_nmro_dclrcion_imprtcion in varchar2,
                                  p_fcha_imprtcion          in date,
                                  p_id_orgnsmo_trnsto       in number,
                                  p_cdgo_vhclo_blndje       in varchar2,
                                  p_cdgo_vhclo_ctgtria      in varchar2,
                                  p_cdgo_vhclo_oprcion      in varchar2,
                                  p_id_asgrdra              in number,
                                  p_nmro_soat               in number,
                                  p_fcha_vncmnto_soat       in date,
                                  p_cdgo_vhclo_trnsmsion    in varchar2,
                                  p_indcdor_blnddo          in varchar2,
                                  p_indcdor_clsco           in varchar2,
                                  p_indcdor_intrndo         in varchar2,
                                  o_cdgo_rspsta             out number,
                                  o_mnsje_rspsta            out varchar2);

  -- procediemiento de validacion datos vehiculos
  procedure prc_vl_nvdds_vhclos(p_id_sjto_impsto     in number,
                                p_vhclo_clse         in varchar2,
                                p_vhclo_mrca         in varchar2,
                                p_vhclo_lnea         in varchar2,
                                p_clndrje            in varchar2,
                                p_mdlo               in varchar2,
                                p_fcha_cmpra         in varchar2,
                                p_fcha_mtrcla        in varchar2,
                                p_fcha_imprtcion     in varchar2,
                                p_blnddo             in varchar2,
                                p_vhclo_crrcria      in varchar2,
                                p_vhclo_srvcio       in varchar2,
                                p_vhclo_oprcion      in varchar2,
                                p_cpcdad_crga        in varchar2,
                                p_cpcdad_psjro       in varchar2,
                                p_nmro_mtor          in varchar2,
                                p_nmro_chsis         in varchar2,
                                p_dclrcion_imprtcion in varchar2,
                                p_nmro_mtrcla        in varchar2,
                                p_avluo              in varchar2,
                                p_vlor_cmrcial       in varchar2,
                                p_orgnsmo_trnsto     in varchar2,
                                p_vhclo_cmbstble     in varchar2,
                                p_vhclo_trnsmsion    in varchar2,
                                p_clsco_s_n          in varchar2,
                                p_intrndo_s_n        in varchar2,
                                p_dprtmnto           in varchar2,
                                p_mncpio             in varchar2,
                                p_cdgo_nvda          in varchar2,
                                p_fcha_nvvdad        in varchar2,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2);

  --- procedimiento generacion determinacion de vehiculos
  procedure prc_rg_dtmncion_vhclo(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_sjto_impsto    in number,
                                  p_vgncia            in number,
                                  p_fcha_mtrcla       in date,
                                  p_id_lqdcion        in number,
                                  p_id_usrio          in number,
                                  o_cdgo_rspsta       out varchar2,
                                  o_mnsje_rspsta      out varchar2);

  ---- informacion  cargue vehiculo
  type tab_vehiculo is table of migra.mg_g_intermedia_veh_vehiculo%rowtype;
  procedure prc_rg_crga_json_vhc(o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  procedure prc_cl_trfa_adcnal(p_vgncia       in number,
                               p_vlor_lqddo   in number,
                               o_vlor_lqddo   out number,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);
  type tab_vehiculo_msvo is table of si_i_vehiculos%rowtype;
  --informacion de preliquidacion de vehiculos                         
  procedure prc_preliquidacion_vehiculo(p_cdgo_clnte        in number,
                                        p_id_impsto         in number,
                                        p_id_impsto_sbmpsto in number,
                                        p_vgncia            in number,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2);

  --informacion de liquidacion masiva de vigencia actual de vehiculos                                 
  procedure prc_rg_liquidacion_msva(p_cdgo_clnte        in number,
                                    p_id_impsto         in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia            in number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  --- consulta de ggrupo de liqueidacion de vehiculo   
  procedure prc_co_grupo_liquidacion(p_grupo        in out number,
                                     o_cdgo_clse    out varchar2,
                                     o_cdgo_marca   out varchar2,
                                     o_id_lnea      out number,
                                     o_cilindraje   out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);
                                     
   procedure prc_co_grupo_adicional(p_id_sjto_impsto in number,
                                     o_marca out varchar,
                                     o_linea out number,
                                     o_cilindraje out number,
                                     o_clase      out number);
  --- Registro de reliquidacion  puntual de vehiculo 
  procedure prc_rg_reliquidacion_vehiculo(p_cdgo_clnte         in number,
                                          p_id_impsto          in number,
                                          p_id_impsto_sbmpsto  in number,
                                          p_id_sjto_impsto     in number,
                                          p_cdgo_lqdcion_tpo   in varchar2,
                                          p_id_usrio           in number,
                                          p_cdgo_prdcdad       in varchar2,
                                          p_cdgo_vhclo_mrca    in varchar2,
                                          p_cdgo_vhclo_clse    in varchar2,
                                          p_cdgo_vhclo_srvcio  in varchar2,
                                          p_cdgo_vhclo_oprcion in varchar2,
                                          p_cdgo_vhclo_crrcria in varchar2,
                                          p_mdlo               in number,
                                          p_avluo              in number,
                                          p_json               in clob,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspstas      out varchar2);
   
  
  procedure prc_rg_liquidacion_vehiculo_v2(p_cdgo_clnte          in number,
                                        p_id_impsto           in number,
                                        p_id_impsto_sbmpsto   in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_prdo             in number,
                                        p_lqdcion_vgncia      in number,
                                        p_cdgo_lqdcion_tpo    in varchar2,
                                        p_bse_grvble          in number,
                                        p_id_vhclo_grpo       in number,
                                        p_cdgo_prdcdad        in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                        p_id_usrio            in number,
                                        p_id_vhclo_lnea       in number,
                                        p_clndrje             in number,
                                        p_cdgo_vhclo_blndje   in varchar2,
                                        p_fraccion            in number,
                                        p_bse_grvble_clda     in number,
                                        p_trfa                in number,
                                        p_cdgo_vhclo_clse     in varchar2,
                                        p_cdgo_vhclo_mrca     in varchar2,
                                        p_cdgo_vhclo_srvcio   in varchar2,
                                        p_cpcdad_crga         in number,
                                        p_cpcdad_psjro        in number,
                                        p_mdlo                in number,
                                        p_cdgo_vhclo_crrcria  in varchar2, 
                                        p_cdgo_vhclo_oprcion   in varchar2,
                                        o_id_lqdcion          out number,
                                        o_id_lqdcion_ad_vhclo out number,
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2);

END PKG_GI_VEHICULOS;

/
