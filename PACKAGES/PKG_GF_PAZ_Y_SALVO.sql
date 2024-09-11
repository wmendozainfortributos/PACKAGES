--------------------------------------------------------
--  DDL for Package PKG_GF_PAZ_Y_SALVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_PAZ_Y_SALVO" AS

  --Funcion para consultar los responsables del paz y salvo de predial
  function fnc_co_rspnsbles_paz_y_slvo(p_cdgo_clnte     in number,
                                       p_id_sjto_impsto in number,
                                       p_id_impsto      in number)
    return clob;

  --Funcion para consultar datos del sujeto  tributo
  function fnc_co_sjto_trbto(p_cdgo_clnte     in number,
                             p_id_sjto_impsto in number,
                             p_id_impsto      in number) return clob;

  --procedimiento para registrar los paz y salvos
  procedure prc_rg_paz_salvo(p_cdgo_clnte        in number,
                             p_id_impsto         in gf_g_paz_y_salvo.id_impsto%type,
                             p_id_impsto_sbmpsto in gf_g_paz_y_salvo.id_impsto_sbmpsto%type,
                             p_id_sjto_impsto    in gf_g_paz_y_salvo.id_sjto_impsto%type,
                             p_id_usrio          in number,
                             p_cnsctvo           in gf_g_paz_y_salvo.cnsctvo%type,
                             p_cdgo_cnsctvo      in varchar2, 
                             p_id_plntlla        in gn_d_plantillas.id_plntlla%type,
                             p_txto_ascda        in varchar2 default null,
                             p_id_dcmnto         in number default null,
                             o_id_acto           out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out varchar2);

  --Funcion Encabezado--
  type t_dtos_dtlle is record(
    id_fsclzcion_expdnte number,
    nmro_acto            number,
    fcha_crcion          TIMESTAMP,
    tpo_acto             varchar2(400));

  type g_dtos_dtlle is table of t_dtos_dtlle;

  function fnc_co_ultmo_acto(p_id_fsclzcion_expdnte number)
    return g_dtos_dtlle
    pipelined;

  -- registrar estados de cuenta
  procedure prc_rg_estdo_cnta(p_cdgo_clnte       in number,
                              p_cnsctvo          in number,
                              p_id_sjto_rspnsble in si_i_sujetos_responsable.id_sjto_rspnsble%type,
                              p_id_usrio_rgstro  in sg_g_usuarios.id_usrio%type,
                              o_cdgo_rspsta      out number,
                              o_mnsje_rspsta     out varchar2);

  --registrat certificado
  procedure prc_rg_certificado(p_cdgo_clnte       in number,
                               p_id_impsto        in gf_g_certificados.id_impsto%type,
                               p_id_sjto_impsto   in gf_g_certificados.id_sjto_impsto%type,
                               p_id_sjto_rspnsble in gf_g_certificados.id_sjto_rspnsble%type,
                               p_cnsctvo          in gf_g_certificados.cnsctvo%type,
                               p_indcdr_prtal     in gf_g_certificados.indcdor_prtal%type,
                               p_cdgo_crtfcdo_tpo in gf_g_certificados.cdgo_crtfcdo_tpo%type,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2);

  --Funcion para consultar datos de las sucursales del sujeto
  function fnc_co_sjto_scrsal(p_id_sjto_impsto in number) return clob;

  	procedure prc_gn_acto_paz_y_salvo(p_cdgo_clnte           in number,
                                       p_id_pz_slvo         in number,
                                       p_id_impsto          in number,
                                       p_id_impsto_sbmpsto  in number,
                                       p_id_sjto_impsto     in number,
                                       p_cnsctvo            in number,
                                       p_cdgo_cnsctvo       in varchar2,  
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       p_cdgo_acto_tpo	    in varchar2,  
                                       p_txto_ascda         in varchar2 default null,
                                       p_id_dcmnto          in number default null,
                                       o_id_acto            out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2);





 PROCEDURE PRC_GENERA_PAZ_SALVO_MASIVO(
                                            p_cdgo_clnte    IN NUMBER,
                                            p_id_usuario    IN NUMBER,
                                            p_id_session    IN NUMBER,
                                            p_id_plntlla    IN gn_d_plantillas.id_plntlla%TYPE,
                                            o_cdgo_rspsta   OUT NUMBER,
                                            o_mnsje_rspsta  OUT VARCHAR2
                                            );

PROCEDURE PRC_GENERA_PAZ_SALVO_MASIVO_JOB(
                                        p_cdgo_clnte    IN NUMBER,
                                        p_id_usuario    IN NUMBER,
                                        p_id_session    IN NUMBER,
                                        p_id_plntlla    IN gn_d_plantillas.id_plntlla%TYPE
                                       -- o_cdgo_rspsta   OUT NUMBER,
                                       -- o_mnsje_rspsta  OUT VARCHAR2
                                        );





END PKG_GF_PAZ_Y_SALVO;


/
