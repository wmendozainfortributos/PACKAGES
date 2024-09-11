--------------------------------------------------------
--  DDL for Package PKG_GI_DETERMINACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DETERMINACION" as

  function fnc_co_detalle_determinacion(p_id_dtrmncion in number) return clob;

  procedure prc_gn_procesar_archivo(p_cdgo_clnte        in number,
                                    p_id_ssion          in number,
                                    p_blob              in blob,
                                    p_id_impsto         in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia_dsde       in number,
                                    p_prdo_dsde         in number,
                                    p_vgncia_hsta       in number,
                                    p_prdo_hsta         in number,
                                    p_dda_dsde          in number,
                                    p_dda_hsta          in number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  procedure prc_rg_lote_determinacion(p_cdgo_clnte                 in number,
                                      p_id_ssion                   in number,
                                      p_id_impsto                  in number,
                                      p_id_impsto_sbmpsto          in number,
                                      p_cdgo_dtrmncion_tpo_slccion in varchar2,
                                      p_vgncia_dsde                in number,
                                      p_prdo_dsde                  in varchar2,
                                      p_vgncia_hsta                in number,
                                      p_prdo_hsta                  in varchar2,
                                      p_dda_dsde                   in number,
                                      p_dda_hsta                   in number,
                                      p_id_usrio                   in number,
                                      p_id_plntlla                 in number);

  procedure prc_gn_determinacion(p_cdgo_clnte        in number,
                                 p_id_dtrmncion_lte  in number default null,
                                 p_id_impsto         in number,
                                 p_id_impsto_sbmpsto in number,
                                 p_id_sjto_impsto    in number,
                                 p_cdna_vgncia_prdo  in varchar2,
                                 p_tpo_orgen         in varchar2 default null,
                                 p_id_orgen          in number default null,
                                 p_id_usrio          in number,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  procedure prc_rg_determinacion_adicional(p_cdgo_clnte     in number,
                                           p_id_sjto_impsto in number,
                                           p_id_dtrmncion   in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2);

  procedure prc_rg_determinacion_ad_predio(p_cdgo_clnte     in number,
                                           p_id_sjto_impsto in number,
                                           p_id_dtrmncion   in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2);

  procedure prc_rg_determinacion_ad_prsna(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2);

  procedure prc_rg_determinacion_ad_vhclo(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2);

  procedure prc_rg_determinacion_rspnsble(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2);

  procedure prc_gn_acto_determinacion(p_cdgo_clnte        in number,
                                      p_id_dtrmncion      in number,
                                      p_id_dtrmncion_lte  in number,
                                      p_id_impsto         in number,
                                      p_id_impsto_sbmpsto in number,
                                      p_id_sjto_impsto    in number,
                                      p_id_usrio          in number,
                                      o_id_acto           out number,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2);

  procedure prc_ac_acto_determinacion(p_id_dtrmncion in number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  -- Genera los documentos masivos y llama a la UP para generar los blobs : prc_gn_determinacion_blob 
  procedure prc_gn_determinacion_documento(p_cdgo_clnte       in number,
                                           p_id_dtrmncion_lte in number,
                                           p_id_usrio         in number,
                                           o_id_dcmnto_lte    out number,
                                           o_cntdad_dcmnto    out number,
                                           o_cdgo_rspsta      out number,
                                           o_mnsje_rspsta     out varchar2);

  -- Genera los blobs del lote de determinacion masivo o desde el job                                     
  procedure prc_gn_determinacion_blob(p_cdgo_clnte       in number,
                                      p_id_dtrmncion_lte in number,
                                      p_id_usrio         in number,
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2);

  -- Genera los blobs masivos sin job                                      
  procedure prc_ac_acto_determinacion_job(p_cdgo_clnte           in number,
                                          p_id_usrio             in number,
                                          p_id_dtrmncion_lte     in number,
                                          p_id_dtrm_lte_blob     in number default null,
                                          p_dtrmncion_dtlle_blob in number default null,
                                          p_id_dtrmncion_ini     in number default null,
                                          p_id_dtrmncion_fin     in number default null,
                                          p_indcdor_prcsmnto     in varchar2,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  -- Crea los jobs para generar los blobs por lotes llamando a prc_ac_acto_determinacion_job                                 
  procedure prc_gn_jobs_determinacion(p_cdgo_clnte       in number,
                                      p_id_dtrm_lte_blob in number,
                                      p_id_dtrmncion_lte in number,
                                      p_id_usrio         in number,
                                      p_nmro_jobs        in number default 1,
                                      p_hora_job         in number,
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2);

  procedure prc_rg_dtrmncion_archvo_plno(p_cdgo_clnte    in number,
                                         p_id_dcmnto_lte in number,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2);

  procedure prc_gn_dtrmncion_archvo_plno(p_cdgo_clnte    in number,
                                         p_id_dcmnto_lte in number,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2);

  function fnc_rg_determinacion_error(p_cdgo_clnte               number,
                                      p_id_dtrmncion_lte         number,
                                      p_id_dtrmncion             number,
                                      p_cdgo_dtrmncion_error_tip varchar2,
                                      p_id_sjto_impsto           number,
                                      p_vgncia                   number,
                                      p_prdo                     number,
                                      p_mnsje_error              varchar2)
    return varchar2;

  function fnc_cl_detalle_vigencia_acto(p_cdgo_clnte   number,
                                        p_id_dtrmncion number) return clob;

  type t_dtrmncn_rspbl_nmbr_tpid is record(
    rspnsble_nombre    varchar2(500),
    tipoidentificacion varchar2(100));

  type g_dtrmncn_rspbl_nmbr_tpid is table of t_dtrmncn_rspbl_nmbr_tpid;

  function fnc_co_dtrmncn_rspbl_nmbr_tpid(p_id_dtrmncion number)
    return g_dtrmncn_rspbl_nmbr_tpid
    pipelined;

  type t_dtos_dtrmncn_dtlle is record(
    vgncia_dscrpcion varchar2(100),
    avluo            number,
    trfa             varchar2(20),
    vlor_cptal       number,
    vlor_intres      number,
    saldo_total      number);

  type g_dtos_dtrmncn_dtlle is table of t_dtos_dtrmncn_dtlle;

  function fnc_co_dtrmncn_dtos_dtlle(p_id_dtrmncion number)
    return g_dtos_dtrmncn_dtlle
    pipelined;

  function fnc_cl_ejecutoriedad(p_cdgo_clnte     number,
                                p_id_sjto_impsto number,
                                p_vgncia         number,
                                p_id_prdo        number,
                                p_id_concpto     number) return varchar2;

  function fnc_cl_ejecutividad(p_cdgo_clnte     number,
                               p_id_sjto_impsto number,
                               p_vgncia         number,
                               p_id_prdo        number,
                               p_id_concpto     number) return varchar2;

  type t_dtos_dcmnto_dtlle_v2 is record(
    vgncia      number,
    id_prdo     number,
    cdgo_cncpto varchar2(3),
    dscrpcion   varchar2(50),
    avluo       number,
    txto_trfa   varchar2(50),
    vlor_captal number);

  type g_dtos_dcmnto_dtlle_v2 is table of t_dtos_dcmnto_dtlle_v2;

  function fnc_dtos_dcmnto_dtlle(p_id_dcmnto number)
    return g_dtos_dcmnto_dtlle_v2
    pipelined;

  function fnc_co_dtrmncn_responsables(p_id_dtrmncion number) return clob;

  type t_dcmnto_dtlle_acmldo_crzal is record(
    id_dcmnto re_g_documentos_detalle.id_dcmnto%type,
    --id_mvmnto_dtlle       re_g_documentos_detalle.id_mvmnto_dtlle%type,
    vgncia       df_s_vigencias.vgncia%type,
    txto_trfa    gi_g_liquidaciones_concepto.txto_trfa%type,
    avluo        gi_g_liquidaciones_concepto.bse_cncpto%type,
    predial      re_g_documentos_detalle.vlor_hber%type,
    sobretasa    re_g_documentos_detalle.vlor_hber%type,
    proelect     re_g_documentos_detalle.vlor_hber%type,
    vlor_cptal   re_g_documentos_detalle.vlor_hber%type,
    vlor_intres  re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto  re_g_documentos_detalle.vlor_hber%type,
    vlor_subttal re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal    re_g_documentos_detalle.vlor_hber%type);

  type g_dcmnto_dtlle_acmldo_crzal is table of t_dcmnto_dtlle_acmldo_crzal;

  function fnc_cl_dcmnto_dtlle_acmldo_crzal(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_crzal
    pipelined;

  type t_documento_total_crzal is record(
    id_dcmnto    re_g_documentos.id_dcmnto%type,
    vlor_cptal   re_g_documentos_detalle.vlor_hber%type,
    vlor_intres  re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto  re_g_documentos_detalle.vlor_hber%type,
    vlor_subttal re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal    re_g_documentos_detalle.vlor_hber%type);

  type g_documento_total_crzal is table of t_documento_total_crzal;

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Funcion que retorna los valores totales de un documentos          !! --
  -- !! ----------------------------------------------------------------- !! --
  function fnc_cl_documento_total_crzal(p_id_dcmnto number)
    return g_documento_total_crzal
    pipelined;

  type t_dcmnto_dtlle_acmldo_sldad is record(
    id_dcmnto    re_g_documentos_detalle.id_dcmnto%type,
    vgncia       df_s_vigencias.vgncia%type,
    txto_trfa    gi_g_liquidaciones_concepto.txto_trfa%type,
    avluo        gi_g_liquidaciones_concepto.bse_cncpto%type,
    predial      re_g_documentos_detalle.vlor_hber%type,
    sobretasa    re_g_documentos_detalle.vlor_hber%type,
    vlor_cptal   re_g_documentos_detalle.vlor_hber%type,
    vlor_intres  re_g_documentos_detalle.vlor_hber%type,
    vlor_dscnto  re_g_documentos_detalle.vlor_hber%type,
    vlor_subttal re_g_documentos_detalle.vlor_hber%type,
    vlor_ttal    re_g_documentos_detalle.vlor_hber%type);

  type g_dcmnto_dtlle_acmldo_sldad is table of t_dcmnto_dtlle_acmldo_sldad;

  function fnc_cl_dcmnto_dtlle_acmldo_sldad(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_sldad
    pipelined;

  -- !! ----------------------------------------------------------------- !! --        
  -- !! Funcion que retorna los valores totales de un documentos          !! --
  -- !! ----------------------------------------------------------------- !! --
  function fnc_cl_documento_total_sldad(p_id_dcmnto number)
    return g_documento_total_crzal
    pipelined;

  function fnc_cl_tiene_determinacion(p_xml clob) return varchar2;
    
    -- Genera los blobs para los actos de la determinación  
    procedure prc_gn_acto_blob_determinacion (  p_cdgo_clnte		number , 
                                                p_id_usrio			number ,
                                                p_id_dtrmncion_lte	number ,
                                                p_id_plntlla	    number ,
                                                p_id_gnra_acto_tpo	varchar2
                                             );
                                             
end pkg_gi_determinacion; ---- Fin encabezado del Paquete pkg_gi_determinacion

/
