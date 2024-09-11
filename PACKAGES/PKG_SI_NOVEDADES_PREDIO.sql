--------------------------------------------------------
--  DDL for Package PKG_SI_NOVEDADES_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SI_NOVEDADES_PREDIO" as

  /*
  * @Descripcion    : Generar Reliquidacion Puntual (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ge_rlqdcion_pntual_prdial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                          p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                          p_id_impsto            in df_c_impuestos.id_impsto%type,
                                          p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                          p_id_prdo              in df_i_periodos.id_prdo%type,
                                          p_vgncia               in df_s_vigencias.vgncia%type,
                                          p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                          p_bse                  in number,
                                          p_area_trrno           in si_i_predios.area_trrno%type,
                                          p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                          p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                          p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type,
                                          p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                          p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                          p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                          p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                          p_indicador_crtra      in boolean default false,
                                          o_indcdor_ajste        out varchar2,
                                          o_vlor_sldo_fvor       out number,
                                          o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  /*
  * @Descripcion    : Registro de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_novedad_predial(p_id_usrio            in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte          in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto           in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto   in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_id_entdad_nvdad     in df_i_entidades_novedad.id_entdad_nvdad%type,
                                   p_id_acto_tpo         in gn_d_actos_tipo.id_acto_tpo%type,
                                   p_nmro_dcmto_sprte    in si_g_novedades_predio.nmro_dcmto_sprte%type,
                                   p_fcha_dcmnto_sprte   in si_g_novedades_predio.fcha_dcmnto_sprte%type,
                                   p_fcha_incio_aplccion in si_g_novedades_predio.fcha_incio_aplccion%type,
                                   p_obsrvcion           in si_g_novedades_predio.obsrvcion%type,
                                   p_id_instncia_fljo    in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_prcso_crga       in et_g_procesos_carga.id_prcso_crga%type default null,
                                   p_json                in clob,
                                   o_id_nvdad_prdio      out si_g_novedades_predio.id_nvdad_prdio%type,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2);

  /*
  * @Descripcion    : Registro de Novedad de Predial Detalle
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_novedad_predial_dtlle(p_cdgo_clnte          in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto           in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto   in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_nvdad_prdio      in si_g_novedades_predio.id_nvdad_prdio%type,
                                         p_id_sjto_impsto      in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_id_prdio_dstno      in si_i_predios.id_prdio_dstno%type,
                                         p_cdgo_estrto         in si_i_predios.cdgo_estrto%type,
                                         p_id_prdio_uso_slo    in si_i_predios.id_prdio_uso_slo%type,
                                         p_fcha_incio_aplccion in si_g_novedades_predio.fcha_incio_aplccion%type,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);

  /*
  * @Descripcion    : Aplicacion de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ap_novedad_predial(p_id_usrio       in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type,
                                   p_id_nvdad_prdio in si_g_novedades_predio.id_nvdad_prdio%type,
                                   p_id_fljo_trea   in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                   p_indcdor_atmtco in varchar2 default 'N',
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  /*
  * @Descripcion    : Aplicacion de Novedad de Predial Puntual
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ap_novedad_predial_pntual(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                          p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                          p_id_impsto            in df_c_impuestos.id_impsto%type,
                                          p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                          p_id_nvdad_prdio_dtlle in si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type,
                                          p_id_acto_tpo          in gn_d_actos_tipo.id_acto_tpo%type,
                                          p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                          p_id_instncia_fljo     in wf_g_instancias_flujo.id_instncia_fljo%type,
                                          p_id_fljo_trea         in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_indcdor_atmtco       in varchar2 default 'N',
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  /*
  * @Descripcion    : Registro de Acto de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_acto_novedad_predial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                        p_id_acto_tpo          in gn_d_actos_tipo.id_acto_tpo%type,
                                        p_id_nvdad_prdio_dtlle in si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type,
                                        o_id_acto              out gn_g_actos.id_acto%type,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  /*
  * @Descripcion    : Registro de Flujo de Ajuste
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_flujo_ajuste(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_lqdcion        in gi_g_liquidaciones.id_lqdcion%type,
                                p_id_instncia_fljo  in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea      in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_acto_tpo       in gn_d_actos_tipo.id_acto_tpo%type,
                                p_nmro_dcmto_sprte  in varchar2,
                                p_fcha_dcmnto_sprte in date,
                                p_id_sjto_impsto    in number,
                                o_cdgo_rspsta       out number,
                                o_mnsje_rspsta      out varchar2);

  type t_vgncia_fcha is record(
    vgncia             df_s_vigencias.vgncia%type,
    prdo               df_i_periodos.prdo%type,
    id_prdo            df_i_periodos.id_prdo%type,
    indcdor_exste_prdo varchar2(1));

  type g_vgncia_fcha is table of t_vgncia_fcha;

  /*
  * @Descripcion    : Calcula las Vigencias de la Fecha
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  function fnc_ca_vigencias_fecha(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_fecha             in timestamp)
    return g_vgncia_fcha
    pipelined;
    
    /*
    * @Descripcion    : Aplicacion de Novedad de Predial Registrada
    * @Creacion       : 14/02/2022
    * @Modificacion   : 14/02/2022
    */ 

    procedure prc_ap_nvdd_predial_registrada( p_id_usrio               in  sg_g_usuarios.id_usrio%type 
                                            , p_cdgo_clnte             in  df_s_clientes.cdgo_clnte%type 
                                            , p_id_nvdad_prdio         in  si_g_novedades_predio.id_nvdad_prdio%type
                                            , p_id_nvdad_prdio_dtlle   in  si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type
                                            , p_id_fljo_trea           in  number
                                            , p_id_instncia_fljo       in  number
                                            , o_cdgo_rspsta    out number
                                            , o_mnsje_rspsta   out varchar2 );
    /*
    * @Descripcion    : Aplicacion de Cambio de Estratos Masivos
    * @Creacion       : 25/05/2022
    * @Modificacion   : 25/05/2022
    */
    procedure prc_ac_estratos_masivo( p_cdgo_clnte      in  df_s_clientes.cdgo_clnte%type
                                     , p_id_usrio     in  sg_g_usuarios.id_usrio%type
                                     , p_id_impsto      in  df_c_impuestos.id_impsto%type
                   , p_id_impsto_sbmpsto  in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                     , p_id_prcso_crga    in  et_g_procesos_carga.id_prcso_crga%type
                   , p_id_entdad_nvdad    in  df_i_entidades_novedad.id_entdad_nvdad%type
                                     /*, o_cdgo_rspsta      out number
                                     , o_mnsje_rspsta     out varchar2*/);

    procedure prc_ac_traza_prcso( p_cdgo_clnte        in  df_s_clientes.cdgo_clnte%type
                 , p_idntfccion_sjto      in  varchar2
                                 , p_id_nvdad_prdio_rsmen   in  number
                 , p_id_nvdad_prdio_crgue   in  number
                 , p_nmbre_up         in  varchar2
                 , p_nvel             in  number
                 , p_cdgo_rspsta      in  number
                 , p_mnsje_rspsta     in  varchar2 );

  procedure prc_rg_flujo_ajuste_automatico ( p_cdgo_clnte     in number,
                         p_id_usrio     in number,  
                         p_id_impsto      in number,  
                         p_id_impsto_sbmpsto  in number,  
                         p_id_sjto_impsto   in number,  
                         p_id_acto      in number, 
                         o_cdgo_rspsta      out number,
                         o_mnsje_rspsta     out varchar2 );
    
  
     -- Req. 024205                                                
    procedure prc_ap_novedad_numero_predial ( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                              p_id_prcso_crga     in varchar2,
                                              p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                                              --p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                              o_cdgo_rspsta       out number,
                                              o_mnsje_rspsta      out varchar2 ) ;

    procedure prc_ac_rfrncia_prdio ( p_cdgo_clnte           number,
                                     p_id_impsto            number,
                                     p_idntfccion_actual    varchar2,
                                     p_idntfccion_nva       varchar2,
                                     p_id_prcso_crga        number,
                                     o_id_sjto_impsto       out number,
                                     o_cdgo_rspsta          out number,
                                     o_mnsje_rspsta         out varchar2
                                    );  
    
    -- Fin Req. 024205     
                                              
end pkg_si_novedades_predio;

/
