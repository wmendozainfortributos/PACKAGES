--------------------------------------------------------
--  DDL for Package Body PK_UTIL_CALENDARIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PK_UTIL_CALENDARIO" as

  procedure generar_calendario(p_cdgo_clnte number, p_vigencia number) as

/*  
  Autor : AURUETA
  Creado : 28/02/2018
  Descripción: Procedimiento que a partir de las configuraciones de calendario genera los registros de fechas hábiles 
               y no hábiles en el calendario general
*/
 -----------------------------
 --Declaración de variables
------------------------------ 
    v_fecha date;
    v_dia_semana varchar2(1);
    v_laboral varchar2(1);
    v_dias_laborales varchar2(15);
------------------------------
--Declaración de cursores
------------------------------
    cursor c_festivos(r_fecha date, r_cdgo_clnte number) is
  
    select 1
      from df_c_feriados
     where cdgo_clnte = r_cdgo_clnte
       and fcha = r_fecha;
       
    cursor c_dias_laborales(r_cdgo_clnte number) is
    
    select ','||replace(dias_hbles,':',',')||',' dias_hbles
      from df_c_calendario_configuracion
     where cdgo_clnte = r_cdgo_clnte
       and indcdor_actvo = 'S'
       and indcdor_prncpal = 'S';
       
  begin
    
    delete 
      from df_c_calendario_general 
     where año = p_vigencia 
       and cdgo_clnte = p_cdgo_clnte ;
    commit;
    
          v_fecha := to_date('01/01/'||p_vigencia,'dd/mm/yyyy');
   
    while v_fecha <= to_date('31/12/'||p_vigencia,'dd/mm/yyyy')  loop
      
      v_dia_semana := to_char(v_fecha, 'D', 'NLS_DATE_LANGUAGE=SPANISH');
      v_laboral := 'S';
      
      for r_dias_laborales in c_dias_laborales(p_cdgo_clnte) loop
        v_dias_laborales:=r_dias_laborales.dias_hbles;
       end loop;
       
      if(instr(v_dias_laborales,(','||v_dia_semana||','))=0)then
        v_laboral:='N';        
      else
              
        for r_festivos in c_festivos(v_fecha, p_cdgo_clnte) loop
          v_laboral:='N';
        end loop;
      
      end if;
      
      insert into df_c_calendario_general(cdgo_clnte,fcha,indcdor_lboral,año,mes)
           values(p_cdgo_clnte,v_fecha,v_laboral,p_vigencia,extract(month from v_fecha));
      commit;
      
      v_fecha:=v_fecha+1;
    
    end loop;
    
  end generar_calendario;
  
  function proximo_dia_habil(p_cdgo_clnte number, p_fecha in date) return date is
    
/*
  Autor : AURUETA
  Creado : 01/03/2018
  Última Modificación: SROMERO 11/12/2018
  Descripción: Función que devuelve el próximo día hábil a partir de una fecha
*/  

-----------------------------
 --Declaración de variables
------------------------------ 

    v_habil df_c_calendario_general.indcdor_lboral%type;
    v_fecha_habil  date;
  /*  select max(fcha) fecha_habil
      from df_c_calendario_general
     where to_number(to_char(fcha,'ddmmyyyy'))>= to_number(to_char(r_fecha,'ddmmyyyy'))
       and indcdor_lboral = 'S'
       and cdgo_clnte = r_cdgo_clnte ;*/

    begin        
        for c_calendario_general in (select min(fcha) fecha_habil
                                       from df_c_calendario_general
                                      where trunc(fcha) >=  trunc(p_fecha)
                                        and indcdor_lboral = 'S'
                                        and cdgo_clnte = p_cdgo_clnte) loop
            
            v_fecha_habil := c_calendario_general.fecha_habil;
        end loop;

        
        return v_fecha_habil;
    end proximo_dia_habil;
  
  
  function es_dia_habil(p_cdgo_clnte number, p_fecha in date) return boolean is
    
/*
  Autor : AURUETA
  Creado : 01/03/2018
  Descripción: Función que devuelve true si es día es laboral y false si no es laboral
*/  

-----------------------------
 --Declaración de variables
------------------------------ 

    v_habil df_c_calendario_general.indcdor_lboral%type;
    
-----------------------------
 --Declaración de cursores
------------------------------ 
    cursor c_calendario_general(r_cdgo_clnte number, r_fecha date) is
      
    select indcdor_lboral habil
      from df_c_calendario_general
     where to_number(to_char(fcha,'ddmmyyyy')) = to_number(to_char(r_fecha,'ddmmyyyy'))
       and cdgo_clnte = r_cdgo_clnte
       and indcdor_lboral = 'S';


  begin
      for r_calendario_general in c_calendario_general(p_cdgo_clnte , p_fecha) loop
        v_habil := r_calendario_general.habil;
      end loop;
      
      if(v_habil = 'S')then 
        return true;
      else
        return false;
      end if;

  end es_dia_habil;
  
  -- !! ---------------------------------------------------------------- !! --
  -- !! Función para calcular una fecha a partir de una unidad de tiempo !! --
  -- !! ---------------------------------------------------------------- !! --
  function calcular_fecha_final(p_cdgo_clnte number, p_fecha_inicial date, p_tpo_dias varchar2, p_nmro_dias number, p_undad_drcion varchar2 default null) return date is
       
    v_contador_dias_habiles number;
    v_fecha date;
     
  begin
    if(p_fecha_inicial is null)then
        return null;
    end if;
    
    --Si la unidad de tiempo es por minutos
    if (p_undad_drcion = 'MN') then
        v_fecha := p_fecha_inicial + (1 / 1440 * p_nmro_dias);
        
    --Si la unidad de tiempo es por horas
    elsif (p_undad_drcion = 'HR') then
        v_fecha := p_fecha_inicial + (p_nmro_dias / 24);
    
    --Si la unidad de tiempo es por dias
    elsif (p_undad_drcion = 'DI' or p_undad_drcion is null) then
        if(p_nmro_dias > 0) then
    
      if(p_tpo_dias='C') then        
         v_fecha := p_fecha_inicial  +  p_nmro_dias;
      
          elsif(p_tpo_dias = 'H') then
          v_fecha := p_fecha_inicial ;
          v_contador_dias_habiles := 0;
          --v_fecha := p_fecha_inicial + p_nmro_dias;
               
            while p_nmro_dias > v_contador_dias_habiles loop
             
              if es_dia_habil(p_cdgo_clnte, v_fecha) then
                v_contador_dias_habiles := v_contador_dias_habiles + 1;
              else
                  --exit;
                  v_fecha := v_fecha + 1;
                  continue;
              end if;
              
              exit when p_nmro_dias = v_contador_dias_habiles;
              v_fecha := v_fecha + 1;
            
            end loop;
          end if;
        end if;
    
    --Si la unidad de tiempo es por semanas
    elsif (p_undad_drcion = 'SM') then
        v_fecha := p_fecha_inicial + (p_nmro_dias * 7);
        
    --Si la unidad de tiempo es por meses
    elsif (p_undad_drcion = 'MS') then
        v_fecha := add_months(p_fecha_inicial, p_nmro_dias);
    end if;
      
    return v_fecha;
      
  end calcular_fecha_final;
  
  function fnc_cl_fecha_habil (p_cdgo_clnte number, p_fcha date) return varchar2 is
  
  -- !! ------------------------------------------- !! --
  -- !! Función para calcular si una fecha es habil !! --
  -- !! ------------------------------------------- !! --
  v_fcha_hbil     varchar2(1);
  
  begin 
    begin 
        select 'S'
          into v_fcha_hbil
          from df_c_calendario_general
         where trunc(fcha) =  trunc(p_fcha)
           and indcdor_lboral = 'S'
           and cdgo_clnte = p_cdgo_clnte;
    exception 
        when others then
            v_fcha_hbil := 'N';
    end;
    return v_fcha_hbil;
  end fnc_cl_fecha_habil;
  
  function fnc_cl_fecha_final(
      p_cdgo_clnte      number default null, 
      p_fecha_inicial   timestamp,
      p_undad_drcion    varchar2,
      p_drcion          number,
      p_dia_tpo         varchar2 default null
    )return timestamp as
    v_fcha              timestamp;
    v_cont_dias_h       number := 0;
  begin
    --Validamos la unidad de duración
    --> 1 SM = 7 DI = 24 HR = 1440 MN = 86400 segundos
    case p_undad_drcion
        --Minutos
        when 'MN' then
            v_fcha := p_fecha_inicial + p_drcion / 1440;
        --Horas
        when 'HR' then 
            v_fcha := p_fecha_inicial + p_drcion / 24;
        --Dias
        when 'DI'then
            if(p_dia_tpo = 'C')then--Calendario
                v_fcha := p_fecha_inicial + p_drcion;
            elsif(p_dia_tpo = 'H' and p_cdgo_clnte is not null)then--Habiles
                --Validamos si el año
                declare 
                    v_exist number;
                begin
                    select 1
                    into v_exist
                    from df_c_calendario_general 
                    where cdgo_clnte = p_cdgo_clnte and
                          año = to_number(to_char(p_fecha_inicial,'YYYY'))
                    group by año;
                exception
                    when no_data_found then
                        return null;
                end;
                v_fcha := p_fecha_inicial;
                while nvl(p_drcion,0) > v_cont_dias_h loop
                    v_fcha := v_fcha + 1;
                    if(es_dia_habil(p_cdgo_clnte, v_fcha))then
                        v_cont_dias_h := v_cont_dias_h + 1;
                    end if;
                end loop;
            else
               return null; 
            end if;
        --Semanas
        when 'SM' then
            v_fcha := p_fecha_inicial + p_drcion * 7;
        --Meses
        when 'MS' then
            v_fcha := ADD_MONTHS(p_fecha_inicial, p_drcion);
    else
        return null;
    end case;
    return v_fcha;
  end fnc_cl_fecha_final;

  function fnc_cl_antrior_dia_habil(p_cdgo_clnte number, p_fecha in date) return date is
		
        /*
          Autor : BVILLEGAS
          Creado : 21/09/2023
          Descripción: Función que devuelve el anterior día hábil a partir de una fecha
        */
        v_fecha_habil  date;
    
    begin        
        for c_calendario_general in (select max(a.fcha) as fecha_habil
                                       from df_c_calendario_general a
                                      where a.cdgo_clnte = p_cdgo_clnte
                                        and trunc(a.fcha) <=  trunc(p_fecha)
                                        and a.indcdor_lboral = 'S') loop
            
            v_fecha_habil := c_calendario_general.fecha_habil;
        end loop;
        
        return v_fecha_habil;
    end fnc_cl_antrior_dia_habil;

end pk_util_calendario;

/
