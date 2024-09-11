--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_CARTERA_VAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_CARTERA_VAL" as

    --Tipo para el Est¿ndar de Error
    type t_errors is record(
     id_intrmdia  number,
     mnsje_rspsta varchar2(4000)
    );

    type r_errors is table of t_errors;

    procedure prc_mg_actualizar_id_cartera( p_id_entdad         in number,
											p_cdgo_clnte		in number );

    procedure prc_mg_movimiento_financiero ( p_id_entdad    in  number,
											p_cdgo_clnte    in number );

    procedure prc_mg_movimiento_detalle ( p_id_entdad   in  number );

    procedure prc_mg_ejecutar_cartera(  p_id_entdad     in number,
                                        p_cdgo_clnte    in number,
                                        p_id_impsto     in number,
                                        p_id_usrio      in number );

    procedure prc_rg_liquidacion_cartera ( p_cdgo_clnte in number,
                                           p_id_impsto  in number,
                                           p_id_usrio   in number );

end pkg_mg_migracion_cartera_val;

/
