--------------------------------------------------------
--  DDL for Package PKG_SI_SUJETO_IMPUESTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SI_SUJETO_IMPUESTO" as

  procedure prc_rg_general_sujeto_impuesto(p_json         in clob,
                                           o_sjto_impsto  out number,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2);

  procedure prc_rg_sujeto(p_json         in json_object_t,
                          o_id_sjto      out si_c_sujetos.id_sjto%type,
                          o_cdgo_rspsta  out number,
                          o_mnsje_rspsta out varchar2);

  procedure prc_rg_sujeto_impuesto(p_json           in json_object_t,
                                   o_id_sjto_impsto out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  procedure prc_rg_personas(p_json         in json_object_t,
                            o_id_prsna     out si_i_personas.id_prsna%type,
                            o_cdgo_rspsta  out number,
                            o_mnsje_rspsta out varchar2);

  procedure prc_rg_terceros(p_json         in json_object_t,
                            o_id_trcro     out si_c_terceros.id_trcro%type,
                            o_cdgo_rspsta  out number,
                            o_mnsje_rspsta out varchar2);

  procedure prc_rg_sujetos_responsable(p_json             in json_object_t,
                                       o_id_sjto_rspnsble out si_i_sujetos_responsable.id_sjto_rspnsble%type,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2);

  procedure prc_rg_sjto_impsto_exstnte(p_cdgo_clnte     in number,
                                       p_idntfccion     in varchar2,
                                       p_impsto         in number,
                                       p_id_usrio       in number,
                                       o_id_sjto_impsto out number,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2);

  procedure prc_rg_sujeto_impuesto(p_id_sjto_impsto          in out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_cdgo_clnte              in si_c_sujetos.cdgo_clnte%type,
                                   p_id_usrio                in si_i_sujetos_impuesto.id_usrio%type default null,
                                   p_idntfccion              in si_c_sujetos.idntfccion%type,
                                   p_id_dprtmnto             in si_c_sujetos.id_dprtmnto%type default null,
                                   p_id_mncpio               in si_c_sujetos.id_mncpio%type default null,
                                   p_drccion                 in si_c_sujetos.drccion%type,
                                   p_drccion_ntfccion        in si_i_sujetos_impuesto.drccion_ntfccion%type default null,
                                   p_id_impsto               in si_i_sujetos_impuesto.id_impsto%type,
                                   p_email                   in si_i_sujetos_impuesto.email%type default null,
                                   p_tlfno                   in si_i_sujetos_impuesto.tlfno%type default null,
                                   p_cdgo_idntfccion_tpo     in si_i_personas.cdgo_idntfccion_tpo%type,
                                   p_id_rgmen_tpo            in si_i_personas.id_sjto_tpo%type,
                                   p_tpo_prsna               in si_i_personas.tpo_prsna%type,
                                   p_nmbre_rzon_scial        in si_i_personas.nmbre_rzon_scial%type,
                                   p_prmer_nmbre             in si_i_sujetos_responsable.prmer_nmbre%type,
                                   p_sgndo_nmbre             in si_i_sujetos_responsable.sgndo_nmbre%type default null,
                                   p_prmer_aplldo            in si_i_sujetos_responsable.prmer_aplldo%type,
                                   p_sgndo_aplldo            in si_i_sujetos_responsable.sgndo_aplldo%type default null,
                                   p_prncpal_s_n             in si_i_sujetos_responsable.prncpal_s_n%type default 'S',
                                   p_nmro_rgstro_cmra_cmrcio in si_i_personas.nmro_rgstro_cmra_cmrcio%type default null,
                                   p_fcha_rgstro_cmra_cmrcio in si_i_personas.fcha_rgstro_cmra_cmrcio%type default null,
                                   p_fcha_incio_actvddes     in si_i_personas.fcha_incio_actvddes%type default null,
                                   p_nmro_scrsles            in si_i_personas.nmro_scrsles%type default null,
                                   p_drccion_cmra_cmrcio     in si_i_personas.drccion_cmra_cmrcio%type default null,
                                   p_id_actvdad_ecnmca       in gi_d_actividades_economica.id_actvdad_ecnmca%type default null,
                                   p_json_rspnsble           in clob,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2);

  -- Procedimiento que actualiza el Responsable  
  procedure prc_ac_sujeto_responsable(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                      p_id_sjto_rspnsble     in si_i_sujetos_responsable.id_sjto_rspnsble%type -- nn
                                     ,
                                      p_id_sjto_impsto       in si_i_sujetos_responsable.id_sjto_impsto%type -- nn
                                     ,
                                      p_cdgo_idntfccion_tpo  in si_i_sujetos_responsable.cdgo_idntfccion_tpo%type,
                                      p_idntfccion           in si_i_sujetos_responsable.idntfccion%type -- nn
                                     ,
                                      p_prmer_nmbre          in si_i_sujetos_responsable.prmer_nmbre%type -- nn
                                     ,
                                      p_sgndo_nmbre          in si_i_sujetos_responsable.sgndo_nmbre%type,
                                      p_prmer_aplldo         in si_i_sujetos_responsable.prmer_aplldo%type -- nn
                                     ,
                                      p_sgndo_aplldo         in si_i_sujetos_responsable.sgndo_aplldo%type,
                                      p_prncpal_s_n          in si_i_sujetos_responsable.prncpal_s_n%type -- nn
                                     ,
                                      p_cdgo_tpo_rspnsble    in si_i_sujetos_responsable.cdgo_tpo_rspnsble%type,
                                      p_prcntje_prtcpcion    in si_i_sujetos_responsable.prcntje_prtcpcion%type,
                                      p_orgen_dcmnto         in si_i_sujetos_responsable.orgen_dcmnto%type -- nn
                                     ,
                                      p_id_pais_ntfccion     in si_i_sujetos_responsable.id_pais_ntfccion%type,
                                      p_id_dprtmnto_ntfccion in si_i_sujetos_responsable.id_dprtmnto_ntfccion%type,
                                      p_id_mncpio_ntfccion   in si_i_sujetos_responsable.id_mncpio_ntfccion%type,
                                      p_drccion_ntfccion     in si_i_sujetos_responsable.drccion_ntfccion%type,
                                      p_email                in si_i_sujetos_responsable.email%type,
                                      p_tlfno                in si_i_sujetos_responsable.tlfno%type,
                                      p_cllar                in si_i_sujetos_responsable.cllar%type,
                                      p_actvo                in si_i_sujetos_responsable.actvo%type -- nn
                                     ,
                                      p_id_trcro             in si_i_sujetos_responsable.id_trcro%type,
                                      p_indcdor_mgrdo        in si_i_sujetos_responsable.indcdor_mgrdo%type default 'N',
                                      p_indcdor_cntrbynte    in si_c_terceros.indcdor_cntrbynte%type default 'N',
                                      p_indcdr_fncnrio       in si_c_terceros.indcdr_fncnrio%type default 'N',
                                      p_accion               in varchar2 -- I: Insertar, A: Actualizar
                                     ,
                                      o_cdgo_rspsta          out number,
                                      o_mnsje_rspsta         out varchar2);
  -- funcion que valida si existe el representante legal o contador
  function fnc_vl_valida_responsable(p_id_dclrcion in number) return clob;
end pkg_si_sujeto_impuesto;

/
