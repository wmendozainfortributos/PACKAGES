--------------------------------------------------------
--  DDL for Package PKG_RE_DOCUMENTOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_RE_DOCUMENTOS" as

  -- 01/06/2022  Insolvencia acuerdos de pago

  function fnc_gn_documento(p_cdgo_clnte                  number,
                            p_id_impsto                   number,
                            p_id_impsto_sbmpsto           number,
                            p_cdna_vgncia_prdo            varchar2,
                            p_cdna_vgncia_prdo_ps         varchar2,
                            p_id_dcmnto_lte               number,
                            p_id_sjto_impsto              number,
                            p_fcha_vncmnto                timestamp,
                            p_cdgo_dcmnto_tpo             varchar2,
                            p_nmro_dcmnto                 varchar2,
                            p_vlor_ttal_dcmnto            number,
                            p_indcdor_entrno              varchar2,
                            p_id_cnvnio                   number default null,
                            p_nmro_cta                    varchar2 default null,
                            p_id_orgen                    number default null,
                            p_id_orgen_gnra               number default null,
                            p_cdgo_mvmnto_orgn            varchar2 default null,
                            p_indcdor_cnvnio              varchar2 default null,
                            p_id_cnvnio_tpo               number default null,
                            p_cta_incial_prcntje_vgncia   number default null,
                            p_indcdor_aplca_dscnto_cnvnio varchar2 default null,
                            p_indcdor_inslvncia           varchar2 default 'N', -- Insolvencia acuerdos de pago
                            p_indcdor_clcla_intres        varchar2 default 'S', -- Insolvencia acuerdos de pago
                            p_fcha_cngla_intres           date default null) -- Insolvencia acuerdos de pago
  
   return varchar2;

  function fnc_rg_documentos_adicional(p_id_sjto_impsto number,
                                       p_id_dcmnto      number)
    return varchar2;

  function fnc_rg_documentos_ad_predio(p_id_sjto_impsto number,
                                       p_id_dcmnto      number)
    return varchar2;

  function fnc_rg_documentos_ad_persona(p_id_sjto_impsto number,
                                        p_id_dcmnto      number)
    return varchar2;

  function fnc_rg_documentos_ad_vehiculo(p_id_sjto_impsto number,
                                         p_id_dcmnto      number)
    return varchar2;

  function fnc_rg_documentos_responsable(p_id_sjto_impsto number,
                                         p_id_dcmnto      number)
    return varchar2;

  type t_dtos_dscntos is record(
    id_dscnto_rgla        re_g_descuentos_regla.id_dscnto_rgla%type,
    prcntje_dscnto        re_g_descuentos_regla.prcntje_dscnto%type,
    vlor_dscnto           number,
    id_cncpto_dscnto      df_i_conceptos.id_cncpto%type,
    id_cncpto_dscnto_grpo df_i_conceptos.id_cncpto%type,
    vlor_intres_bancario  number, -- Ley 2155. Inter¿s bancario si el descuento se aplica sobre este tipo de inter¿s
    vlor_sldo             number, -- Ley 2155. Saldo del inter¿s sobre el que se calcula el descuento - Convenios
    fcha_fin_dscnto       date, -- Ley 2155. Fecha fin de la vigencia del descuento - Convenios
    ind_extnde_tmpo       varchar2(1) -- Ley 2155. Si el descuento extiende el tiempo de vignecia para las cuotas fuera de la vigencia inicial - Convenios
    );

  type g_dtos_dscntos is table of t_dtos_dscntos;

  function fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  in number,
                                          p_id_impsto                   in number,
                                          p_id_impsto_sbmpsto           in number,
                                          p_vgncia                      in number,
                                          p_id_prdo                     in number,
                                          p_id_cncpto                   in number,
                                          p_id_orgen                    in number default null,
                                          p_id_sjto_impsto              in number default null,
                                          p_fcha_pryccion               in date,
                                          p_vlor                        in number,
                                          p_cdna_vgncia_prdo_pgo        in varchar2 default null,
                                          p_cdna_vgncia_prdo_ps         in varchar2 default null,
                                          p_fcha_incio_cnvnio           in date default null,
                                          p_id_cncpto_base              in number default null,
                                          p_cdgo_mvmnto_orgn            in varchar2 default null,
                                          p_vlor_cptal                  in number default null,
                                          p_indcdor_clclo               in varchar2 default null,
                                          p_indcdor_aplca_dscnto_cnvnio in varchar2 default null)
    return g_dtos_dscntos
    pipelined;

  procedure prc_rg_lote_documentos(p_cdgo_clnte          in number,
                                   p_id_impsto           in number,
                                   p_id_impsto_sbmpsto   in number,
                                   p_vgncia_dsde         in number,
                                   p_prdo_dsde           in varchar2,
                                   p_vgncia_hsta         in number,
                                   p_prdo_hsta           in varchar2,
                                   p_fcha_vncmnto        in date,
                                   p_tpo_slccion_pblcion in varchar2,
                                   p_id_dtrmncion_lte    in number,
                                   p_cdgo_cnsctvo        in varchar2,
                                   p_cdgo_dcmnto_lte_tpo in varchar2,
                                   p_obsrvcion           in varchar2,
                                   p_id_usrio            in number,
                                   p_indcdor_entrno      in varchar2,
                                   p_id_session          in number,
                                   p_mnsje               out varchar2,
                                   p_id_dcmnto_lte       out number);

  procedure prc_rg_lote_documentos(p_cdgo_clnte          in number,
                                   p_id_impsto           in number,
                                   p_id_impsto_sbmpsto   in number,
                                   p_vgncia_dsde         in number,
                                   p_prdo_dsde           in varchar2,
                                   p_vgncia_hsta         in number,
                                   p_prdo_hsta           in varchar2,
                                   p_fcha_vncmnto        in date default null,
                                   p_tpo_slccion_pblcion in varchar2,
                                   p_id_dtrmncion_lte    in number default null,
                                   p_cdgo_dcmnto_lte_tpo in varchar2,
                                   p_obsrvcion           in varchar2,
                                   p_id_usrio            in number,
                                   p_id_session          in number default null,
                                   o_id_dcmnto_lte       out number,
                                   o_cntdad_dcmnto_fcha  out number,
                                   o_cntdad_dcmnto       out number,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2);

  procedure prc_gn_lote_documentos_masivo(p_cdgo_clnte        in number,
                                          p_id_dcmnto_lte     in number,
                                          p_cdna_vgncia_prdo  in varchar2,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_fcha_vncmnto      in date,
                                          p_id_session        in varchar2,
                                          o_cntdad_dcmnto     out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);

  procedure prc_gn_lote_dcmnto_mltple_fcha(p_cdgo_clnte        in number,
                                           p_id_dcmnto_lte     in number,
                                           p_cdna_vgncia_prdo  in varchar2,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_session        in varchar2,
                                           o_cntdad_dcmnto     out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_gn_lote_dcmnto_dtrmncion(p_cdgo_clnte        in number,
                                         p_id_dcmnto_lte     in number,
                                         p_id_dtrmncion_lte  in number,
                                         p_cdna_vgncia_prdo  in varchar2,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         o_cntdad_dcmnto     out number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2);

  function fnc_gn_archivo_impresion(p_cdgo_clnte    number,
                                    p_id_dcmnto_lte number) return varchar2;

  function fnc_gn_archivo_impresion_v2(p_cdgo_clnte    number,
                                       p_id_dcmnto_lte number)
    return varchar2;

  function fnc_co_documentos_vigencias(p_id_dcmnto number) return varchar2;

  type t_dtos_dcmnto_dtlle is record(
    vgncia                     df_s_vigencias.vgncia%type,
    prdo_dtlle                 df_i_periodos.prdo%type,
    id_cncpto                  df_i_conceptos.id_cncpto%type,
    id_cncpto_cptal            df_i_conceptos.id_cncpto%type,
    dscrpcion_cncpto_dtlle     df_i_conceptos.dscrpcion%type,
    cdgo_mvnt_fncro_estdo      v_gf_g_movimientos_detalle.cdgo_mvnt_fncro_estdo%type,
    dscrpcion_mvnt_fncro_estdo v_gf_g_movimientos_detalle.dscrpcion_mvnt_fncro_estdo%type,
    vlor_cptal_ipu             number,
    vlor_intres_ipu            number,
    vlor_ttal                  number,
    bse_cncpto                 gi_g_liquidaciones_concepto.bse_cncpto%type,
    trfa                       gi_g_liquidaciones_concepto.trfa%type,
    txto_trfa                  gi_g_liquidaciones_concepto.txto_trfa%type);

  type g_dtos_dcmnto_dtlle is table of t_dtos_dcmnto_dtlle;

  function fnc_co_documento_detalle(p_id_dcmnto number)
    return g_dtos_dcmnto_dtlle
    pipelined;

  type t_dtos_ultmo_rcdo is record(
    nmro_dcmnto         re_g_documentos.nmro_dcmnto%type,
    fcha_rcdo           date, --re_g_recaudos.fcha_apliccion%type,
    vlor_dcmnto         varchar2(30),
    nmbre_bnco_mdio_pgo df_c_bancos.nmbre_bnco%type
    
    );

  type g_dtos_ultmo_rcdo is table of t_dtos_ultmo_rcdo;

  function fnc_co_ultmo_rcdo(p_id_sjto_impsto number)
    return g_dtos_ultmo_rcdo
    pipelined;

  type t_dtos_dcmnto_cnvnio_dtlle is record(
    id_dcmnto  number,
    cncpto     varchar2(100),
    ttal       number,
    bse_grvble number,
    txto_trfa  varchar2(100));

  type g_dtos_dcmnto_cnvnio_dtlle is table of t_dtos_dcmnto_cnvnio_dtlle;

  function fnc_co_dtos_dcmnto_cnvnio_dtll(p_id_dcmnto number)
    return g_dtos_dcmnto_cnvnio_dtlle
    pipelined;

  procedure prc_gn_recibo_couta_convenio(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                         p_id_cnvnio        in gf_g_convenios.id_cnvnio%type,
                                         p_cdnas_ctas       in varchar2,
                                         p_fcha_vncmnto     in re_g_documentos.fcha_vncmnto%type,
                                         p_indcdor_entrno   in varchar2,
                                         p_vlor_ttal_dcmnto in number,
                                         o_id_dcmnto        out re_g_documentos.id_dcmnto%type,
                                         o_nmro_dcmnto      out re_g_documentos.nmro_dcmnto%type,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  type t_dcmnto_dtlle_acmldo is record(
    id_dcmnto        re_g_documentos_detalle.id_dcmnto%type,
    id_mvmnto_dtlle  re_g_documentos_detalle.id_mvmnto_dtlle%type,
    vgncia           df_s_vigencias.vgncia%type,
    id_prdo          df_i_periodos.id_prdo%type,
    prdo             df_i_periodos.prdo%type,
    id_cncpto        df_i_conceptos.id_cncpto%type,
    cdgo_cncpto      df_i_conceptos.cdgo_cncpto%type,
    dscrpcion_cncpto df_i_conceptos.dscrpcion%type,
    vlor_cptal       re_g_documentos_detalle.vlor_hber%type,
    vlor_intres      re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto      re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal        re_g_documentos_detalle.vlor_hber%type,
    txto_trfa        gi_g_liquidaciones_concepto.txto_trfa%type, -- nuevo
    avluo            gi_g_liquidaciones_concepto.bse_cncpto%type -- nuevo
    );

  type g_dcmnto_dtlle_acmldo is table of t_dcmnto_dtlle_acmldo;

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Funcion que retorna el detallado de un documentos                 !! --
  -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
  -- !! valor descuentos y valor total                                    !! --
  -- !! ----------------------------------------------------------------- !! --
  function fnc_cl_dcmnto_dtlle_acmldo(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo
    pipelined;

  type t_dcmnto_dtlle_acmldo_v2 is record(
    vgncia_dscrpcion varchar2(1000),
    vgncia           df_s_vigencias.vgncia%type,
    vlor_cptal       re_g_documentos_detalle.vlor_hber%type,
    vlor_intres      re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto      re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal        re_g_documentos_detalle.vlor_hber%type,
    nmro             number,
    txto_trfa        gi_g_liquidaciones_concepto.txto_trfa%type, -- nuevo
    avluo            gi_g_liquidaciones_concepto.bse_cncpto%type -- nuevo
    );

  type g_dcmnto_dtlle_acmldo_v2 is table of t_dcmnto_dtlle_acmldo_v2;

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Funcion que retorna el detallado de un documentos                 !! --
  -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
  -- !! valor descuentos y valor total. se determina un limite para       !! --
  -- !! iniciar la acumulacion de vigencias                               !! --
  -- !! ----------------------------------------------------------------- !! --

  function fnc_cl_dcmnto_dtlle_acmldo_v2(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_v2
    pipelined;

  type t_documento_total is record(
    id_dcmnto   re_g_documentos.id_dcmnto%type,
    vlor_cptal  re_g_documentos_detalle.vlor_hber%type,
    vlor_intres re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal   re_g_documentos_detalle.vlor_hber%type);

  type g_documento_total is table of t_documento_total;

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Funcion que retorna los valores totales de un documentos          !! --
  -- !! ----------------------------------------------------------------- !! --

  function fnc_cl_documento_total(p_id_dcmnto number)
    return g_documento_total
    pipelined;

  /*type t_dtos_dcmnto_dtlle_v2 is record 
      (
          vgncia          number,
      id_prdo               number,
      cdgo_cncpto             varchar2(3),
      dscrpcion           varchar2(50),
      avluo             number,
      txto_trfa       varchar2(50),
          vlor_captal           number
      );
  
  type g_dtos_dcmnto_dtlle_v2 is table of t_dtos_dcmnto_dtlle_v2;     
  
  function fnc_dtos_dcmnto_dtlle (p_id_dcmnto number) return g_dtos_dcmnto_dtlle_v2 pipelined; */
  type t_ultima_liquidacion is record(
    id_lqdcion gi_g_liquidaciones_concepto.id_lqdcion%type,
    vgncia     number,
    id_prdo    number,
    bse_cncpto gi_g_liquidaciones_concepto.bse_cncpto%type,
    trfa       gi_g_liquidaciones_concepto.trfa%type,
    txto_trfa  gi_g_liquidaciones_concepto.txto_trfa%type);

  type g_ultima_liquidacion is table of t_ultima_liquidacion;

  type t_ultima_lqdcion is record(
    id_lqdcion gi_g_liquidaciones_concepto.id_lqdcion%type,
    vgncia     number,
    id_prdo    number,
    id_cncpto  df_i_conceptos.id_cncpto%type,
    bse_cncpto gi_g_liquidaciones_concepto.bse_cncpto%type,
    trfa       gi_g_liquidaciones_concepto.trfa%type,
    txto_trfa  gi_g_liquidaciones_concepto.txto_trfa%type);

  type g_ultima_lqdcion is table of t_ultima_lqdcion;

  -- !! ----------------------------------------------------------------------------- !! --        
  -- !! Funcion que retorna los valores de la ultima liqidacion de un sujeto impuesto !! --
  -- !! ----------------------------------------------------------------------------- !! --

  function fnc_cl_ultima_liquidacion(p_id_sjto_impsto number)
    return g_ultima_liquidacion
    pipelined;

  function fnc_cl_ultima_liquidacion(p_cdgo_clnte        number,
                                     p_id_impsto         number,
                                     p_id_impsto_sbmpsto number,
                                     p_id_prdo           number,
                                     p_id_sjto_impsto    number)
    return g_ultima_lqdcion
    pipelined;

  /* type t_dtos_dtlle is record (
               vgncia                  number,
               prdo          number,
               cncpto          varchar2(400),
               vlor_cptal        number,
               vlor_intres       number,
               saldo_total       number);
  
  type g_dtos_dtlle is table of t_dtos_dtlle;
  
    function fnc_co_dtlle_dcmnto (p_id_dcmnto number, p_lmte number)
       return g_dtos_dtlle pipelined;*/

  --Funcion Encabezado--  
  type t_dtos_dtlle is record(
    vgncia      number,
    prdo        number,
    cncpto      varchar2(400),
    vlor_cptal  number,
    vlor_intres number,
    saldo_total number,
    bse_cncpto  gi_g_liquidaciones_concepto.bse_cncpto%type,
    trfa        gi_g_liquidaciones_concepto.trfa%type,
    txto_trfa   gi_g_liquidaciones_concepto.txto_trfa%type,
    id_cncpto   number);

  type g_dtos_dtlle is table of t_dtos_dtlle;

  function fnc_co_dtlle_dcmnto(p_id_dcmnto number, p_lmte number)
    return g_dtos_dtlle
    pipelined;

  function fnc_vl_fcha_mxma_tsas_mra(p_cdgo_clnte            number,
                                     p_id_impsto             number,
                                     p_fcha_vncmnto          date,
                                     p_fcha_vncmnto_oblgcion date default null)
    return date;

  procedure prc_rg_documento_rpt(p_cdgo_clnte   in number,
                                 p_id_dcmnto    in number,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Procesamiento de recibos de pagos masivos                         !! --
  -- !! Creado: 27/12/2021                                                !! --
  -- !! Modificado: 27/12/2021                                            !! --
  -- !! ----------------------------------------------------------------- !! --                               
  procedure prc_gn_dcmnto_masivo_pago(p_cdgo_clnte           number,
                                      p_id_dcmnto_lte        number,
                                      p_id_rprte             number,
                                      p_nmbre_usrio          varchar2,
                                      p_frmto_mnda           varchar2,
                                      p_id_usrio             number,
                                      p_id_dcmnto_ini        number default null,
                                      p_id_dcmnto_fin        number default null,
                                      p_indcdor_prcsmnto     varchar2,
                                      p_id_dcmnto_lte_blob   number default null,
                                      p_id_dcmnto_dtlle_blob number default null);

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Procesamiento de recibo de pago individuales                      !! --
  -- !! Creado: 27/12/2021                                                !! --
  -- !! Modificado: 27/12/2021                                            !! --
  -- !! ----------------------------------------------------------------- !! --                                    
  procedure prc_gn_dcmnto_pago(p_id_rprte     number,
                               p_cdgo_clnte   number,
                               p_id_dcmnto    number,
                               p_nmbre_usrio  varchar2,
                               p_frmto_mnda   varchar2,
                               o_blob         out blob,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);

  procedure prc_gn_documentos_masivos_blob(p_cdgo_clnte          in number,
                                           p_id_dcmnto_lte       in number,
                                           p_id_usrio            in number,
                                           p_id_rprte            in number,
                                           p_nmbre_usrio         in varchar2,
                                           p_frmto_mnda          in varchar2,
                                           p_indcdor_hra_ejccion in varchar2 default null,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);

  procedure prc_gn_jobs_documentos_masivos(p_cdgo_clnte          in number,
                                           p_id_dcmnto_lte_blob  in number,
                                           p_id_dcmnto_lte       in number,
                                           p_id_usrio            in number,
                                           p_nmro_jobs           in number default 1,
                                           p_hora_job            in number,
                                           p_id_rprte            in number,
                                           p_nmbre_usrio         in varchar2,
                                           p_frmto_mnda          in varchar2,
                                           p_indcdor_hra_ejccion in varchar2,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);
end;

/
