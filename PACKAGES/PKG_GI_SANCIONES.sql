--------------------------------------------------------
--  DDL for Package PKG_GI_SANCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_SANCIONES" as
  /********************** Procedimiento para retornar si la fecha de presentacion de la declaracion sobrepaso la fecha limite de presentacion y el numero de meses que se sobrepso  ******************************************************************************************************************/
  procedure prc_vl_fecha_limite(p_id_dclrcion_vgncia_frmlrio in gi_d_dclrcnes_vgncias_frmlr.id_dclrcion_vgncia_frmlrio%type,
                                p_idntfccion                 in varchar2,
                                p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type,
                                p_id_sjto_tpo                in number default null,
                                o_sobrepaso_fecha_limite     out varchar2,
                                o_numero_meses_x_sancion     out number,
                                o_cdgo_rspsta                out number,
                                o_mnsje_rspsta               out varchar2);
  /********************** Procedimiento para retornar el valor minimo de la sancion  ***********************************************************************************************************/
  /*procedure prc_cl_valor_sancion_min (p_cdgo_sncion_tpo        in  gi_d_sanciones.cdgo_sncion_tpo%type,
  p_vgncia                in  gi_d_sanciones.vgncia%type,
  p_id_prdo                       in  gi_d_sanciones.id_prdo%type,
  p_undad_vlor_sncion_mnmo    in  gi_d_sanciones.undad_vlor_sncion_mnmo%type,
  o_vlor_sncion_mnmo        out gi_d_sanciones.undad_vlor_sncion_mnmo%type,
  o_cdgo_rspsta         out number,
  o_mnsje_rspsta          out varchar2);*/

  procedure prc_cl_valor(p_cdgo_sncion_tpo in gi_d_sanciones.cdgo_sncion_tpo%type,
                         p_vgncia          in gi_d_sanciones.vgncia%type,
                         p_id_prdo         in gi_d_sanciones.id_prdo%type,
                         p_cdgo_nmbre_vlor in gi_d_sanciones_calculo_valor.cdgo_nmbre_vlor%type, --'SNCMIN';  (parametro para recivir que valor se va a calcular)
                         o_vlor_clclo      out number, --- devulve el valor de lo calculado
                         o_cdgo_rspsta     out number,
                         o_mnsje_rspsta    out varchar2);

  /********************** Funcion Calcula el valor de la sancion de la declaracion por Extemporaneidad o Correccion******************************************************************************************************************/
  function fnc_ca_valor_sancion(p_cdgo_clnte                 in number,
                                p_id_dclrcion_vgncia_frmlrio in gi_d_dclrcnes_vgncias_frmlr.id_dclrcion_vgncia_frmlrio%type,
                                p_idntfccion                 in varchar2,
                                p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type, -- o date('DD/MM/YY')?
                                p_id_sjto_tpo                in number default null,
                                p_cdgo_sncion_tpo            in gi_d_sanciones.cdgo_sncion_tpo%type,
                                p_cdgo_dclrcion_uso          in gi_d_declaraciones_uso.cdgo_dclrcion_uso%type,
                                p_id_dclrcion_incial         in number default null,
                                p_impsto_crgo                in number default 0,
                                p_ingrsos_brtos              in number default 0,
                                p_saldo_favor                in number default 0) return number;
  /********************** Funcion que retorna si el sjto tiene un emplazamiento ******************************************************************************************************************/
  function fnc_vl_existe_emplazamiento(p_cdgo_clnte in number, p_id_sjto_impsto in number) return varchar2;
  /********************** ******************************************************************************************************************/
end pkg_gi_sanciones;

/
