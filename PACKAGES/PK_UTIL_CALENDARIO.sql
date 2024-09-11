--------------------------------------------------------
--  DDL for Package PK_UTIL_CALENDARIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PK_UTIL_CALENDARIO" AS 

--  Autor : AURUETA
--  Creado : 28/02/2018
--  Descripción: Paquete donde se encuentra funciones y procedimeintos para el manejo de calendarioy calculos de días hábiles
    procedure generar_calendario(p_cdgo_clnte number, p_vigencia number);
    function proximo_dia_habil(p_cdgo_clnte number, p_fecha in date) return date ;
    function calcular_fecha_final(p_cdgo_clnte number, p_fecha_inicial date, p_tpo_dias varchar2, p_nmro_dias number, p_undad_drcion varchar2 default null) return date;
    function fnc_cl_fecha_habil (p_cdgo_clnte number, p_fcha date) return varchar2;
    
    --Autor: Juan C. Cuao
    --Fecha: 04/04/2019
    --Funcion que permite calcular fecha final tomando en cuenta dias habiles, unidad de duracion: MN, HR, DI, SM, MS
    function fnc_cl_fecha_final(
      p_cdgo_clnte      number default null, 
      p_fecha_inicial   timestamp,
      p_undad_drcion    varchar2,
      p_drcion          number,
      p_dia_tpo         varchar2 default null
    )return timestamp;
    
    /*
      Autor : BVILLEGAS
      Creado : 21/09/2023
      Descripción: Función que devuelve el anterior día hábil a partir de una fecha
    */
    function fnc_cl_antrior_dia_habil(p_cdgo_clnte number, p_fecha in date) return date;
    
end pk_util_calendario;

/
