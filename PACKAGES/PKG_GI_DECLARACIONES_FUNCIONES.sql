--------------------------------------------------------
--  DDL for Package PKG_GI_DECLARACIONES_FUNCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DECLARACIONES_FUNCIONES" as

  --Funcion de declaraciones que retorna el valor de intereses de un concepto
  --FDCL100
  function fnc_co_concepto_interes(p_id_dclrcion_vgncia_frmlrio number,
                                   p_item_acto_cncpto           varchar2,
                                   p_vlor_acto_cncpto           number,
                                   p_idntfccion                 varchar2,
                                   p_id_sjto_tpo                number default null,
                                   p_fcha_pryccion              varchar2)
    return number;

  --Funcion de declaraciones que retorna si existe una declaracion presentada o aplicada
  --para la identificacion de un sujeto-impuesto
  --FDCL110
  function fnc_co_declaracion(p_id_dclrcion_vgncia_frmlrio number,
                              p_idntfccion                 varchar2)
    return number;

  --Funcion de declaraciones que consulta el valor de la sancion de la declaracion
  --FDCL120
  function fnc_co_valor_sancion(p_cdgo_clnte                 number,
                                p_id_dclrcion_vgncia_frmlrio number,
                                p_idntfccion                 varchar2,
                                p_id_sjto_tpo                number default null,
                                p_fcha_prsntcion             varchar2,
                                p_cdgo_sncion_tpo            varchar2,
                                p_cdgo_dclrcion_uso          varchar2,
                                p_id_dclrcion_incial         number,
                                p_impsto_crgo                number,
                                p_ingrsos_brtos              number,
                                p_saldo_favor                number)
    return number;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL130
  function fnc_co_valor_descuento(p_id_dclrcion_vgncia_frmlrio number,
                                  p_id_dclrcion_crrccion       number,
                                  p_item_cncpto                varchar2,
                                  p_vlor_cncpto                number,
                                  p_idntfccion                 varchar2,
                                  p_fcha_pryccion              varchar2)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined;

  --Funcion que valida la fecha maxima de presentacion de una declaracion
  --FDCL150
  function fnc_co_fcha_mxma_prsntcion(p_id_dclrcion_vgncia_frmlrio number,
                                      p_idntfccion                 varchar2,
                                      p_id_sjto_tpo                number default null,
                                      p_lcncia                     varchar2 default null)
    return timestamp;

  --Funcion que calcula el digito de verificacion de una identificacion
  --FDCL160
  function fnc_ca_digito_verificacion(p_identificacion varchar2)
    return number;
    
    function fnc_co_cncpto_intrs_vlddo(
									p_id_dclrcion_vgncia_frmlrio	number,
									p_item_acto_cncpto				varchar2,
									p_vlor_acto_cncpto              number,
									p_dclrcion_uso                  varchar2 default null,
									p_id_dclrcion_antrior			number default null,
									p_idntfccion                    varchar2,
									p_id_sjto_tpo					number default null,
									p_fcha_pryccion                 varchar2,
                                    p_vlor_ttal                     number default null)
	return number; 
    
end pkg_gi_declaraciones_funciones;

/
