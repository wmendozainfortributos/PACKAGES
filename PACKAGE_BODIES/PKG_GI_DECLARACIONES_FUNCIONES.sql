--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES_FUNCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES_FUNCIONES" as

  --Funcion de declaraciones que retorna el valor de intereses de un concepto
  --FDCL100
  function fnc_co_concepto_interes(p_id_dclrcion_vgncia_frmlrio number,
                                   p_item_acto_cncpto           varchar2,
                                   p_vlor_acto_cncpto           number,
                                   p_idntfccion                 varchar2,
                                   p_id_sjto_tpo                number default null,
                                   p_fcha_pryccion              varchar2)
    return number as
    v_id_frmlrio_rgion_atrbto number;
    v_fla                     number;
    v_id_cncpto               number;
    v_gnra_intres_mra         varchar2(1);
    v_cdgo_clnte              number;
    v_id_impsto               number;
    v_id_impsto_sbmpsto       number;
    v_vgncia                  number;
    v_id_prdo                 number;
    v_fcha_fnal               timestamp;
  
    v_vlor_intres number := 0;
  begin
    --Se identifica el atributo en el item
    select to_number(regexp_substr(regexp_substr(p_item_acto_cncpto,
                                                 'ATR[1-9][0-9]*'),
                                   '[0-9]+'))
      into v_id_frmlrio_rgion_atrbto
      from dual;
  
    --Se identifica la fila en el item
    select nvl(to_number(regexp_substr(regexp_substr(p_item_acto_cncpto,
                                                     'FLA[1-9][0-9]*'),
                                       '[0-9]+')),
               1)
      into v_fla
      from dual;
  
    --Se identifica el concepto
    select b.id_cncpto, b.gnra_intres_mra
      into v_id_cncpto, v_gnra_intres_mra
      from df_i_impuestos_acto_concepto b
     where exists
     (select 1
              from gi_d_dclrcnes_acto_cncpto c
             where c.id_dclrcion_vgncia_frmlrio =
                   p_id_dclrcion_vgncia_frmlrio
               and c.id_frmlrio_rgion_atrbto = v_id_frmlrio_rgion_atrbto
               and c.fla = v_fla
               and c.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto);
  
    if (v_gnra_intres_mra = 'N') then
      return v_vlor_intres;
    end if;
  
    --Se consultan los datos necesarios para calcular la sancion
    select c.cdgo_clnte,
           c.id_impsto,
           c.id_impsto_sbmpsto,
           b.vgncia,
           b.id_prdo
      into v_cdgo_clnte,
           v_id_impsto,
           v_id_impsto_sbmpsto,
           v_vgncia,
           v_id_prdo
      from gi_d_dclrcnes_vgncias_frmlr a
     inner join gi_d_dclrcnes_tpos_vgncias b
        on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
     inner join gi_d_declaraciones_tipo c
        on c.id_dclrcn_tpo = b.id_dclrcn_tpo
     where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
  
    --Se consulta la fecha limite de declaracion
    select pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                          p_idntfccion                 => p_idntfccion,
                                                          p_id_sjto_tpo                => p_id_sjto_tpo)
      into v_fcha_fnal
      from dual;
  
    --Se calcula el valor de los interes
    select pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte         => v_cdgo_clnte,
                                                             p_id_impsto          => v_id_impsto,
                                                             p_id_impsto_sbmpsto  => v_id_impsto_sbmpsto,
                                                             p_vgncia             => v_vgncia,
                                                             p_id_prdo            => v_id_prdo,
                                                             p_id_cncpto          => v_id_cncpto,
                                                             p_vlor_cptal         => p_vlor_acto_cncpto,
                                                             p_indcdor_clclo      => 'PRY',
                                                             p_fcha_incio_vncmnto => v_fcha_fnal,
                                                             p_fcha_pryccion      => to_timestamp(p_fcha_pryccion,
                                                                                                  'dd/mm/yyyy'))
      into v_vlor_intres
      from dual;
  
    return v_vlor_intres;
  
  exception
    when others then
      return v_vlor_intres;
  end fnc_co_concepto_interes;

  --Funcion de declaraciones que retorna si existe una declaracion presentada o aplicada
  --para la identificacion de un sujeto-impuesto
  --FDCL110
  function fnc_co_declaracion(p_id_dclrcion_vgncia_frmlrio number,
                              p_idntfccion                 varchar2)
    return number as
  
    v_id_dclrcion_crrccion number := 0;
    v_id_sjto_impsto       number;
  
    v_error exception;
  
  begin
  
    --Se calcula el sujeto impuesto
    begin
      select a.id_sjto_impsto
        into v_id_sjto_impsto
        from v_si_i_sujetos_impuesto a
       where exists
       (select 1
                from gi_d_dclrcnes_vgncias_frmlr b
               inner join gi_d_dclrcnes_tpos_vgncias c
                  on c.id_dclrcion_tpo_vgncia = b.id_dclrcion_tpo_vgncia
               inner join gi_d_declaraciones_tipo d
                  on d.id_dclrcn_tpo = c.id_dclrcn_tpo
               where b.id_dclrcion_vgncia_frmlrio =
                     p_id_dclrcion_vgncia_frmlrio
                 and d.cdgo_clnte = a.cdgo_clnte
                 and d.id_impsto = a.id_impsto)
         and a.idntfccion_sjto = p_idntfccion;
    exception
      when others then
        raise v_error;
    end;
  
    --Se valida si existe una declaracion presentada o aplicada
    begin
      select a.id_dclrcion
        into v_id_dclrcion_crrccion
        from gi_g_declaraciones a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and a.id_sjto_impsto = v_id_sjto_impsto
         and (a.indcdor_mgrdo not in ('C') or a.indcdor_mgrdo is null)
         and a.cdgo_dclrcion_estdo in ('APL', 'PRS');
    exception
      when others then
        raise v_error;
    end;
  
    return v_id_dclrcion_crrccion;
  
  exception
    when v_error then
      return v_id_dclrcion_crrccion;
  end fnc_co_declaracion;

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
    return number as
    v_vlor_sncion number := 0;
  begin
  
    --Se hace el llamado a la funcion de sanciones que retorna el valor
    v_vlor_sncion := pkg_gi_sanciones.fnc_ca_valor_sancion(p_cdgo_clnte                 => p_cdgo_clnte,
                                                           p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                           p_idntfccion                 => p_idntfccion,
                                                           p_fcha_prsntcion             => to_timestamp(p_fcha_prsntcion,
                                                                                                        'dd/mm/yyyy'),
                                                           p_id_sjto_tpo                => p_id_sjto_tpo,
                                                           p_cdgo_sncion_tpo            => p_cdgo_sncion_tpo,
                                                           p_cdgo_dclrcion_uso          => p_cdgo_dclrcion_uso,
                                                           p_id_dclrcion_incial         => p_id_dclrcion_incial,
                                                           p_impsto_crgo                => p_impsto_crgo,
                                                           p_ingrsos_brtos              => p_ingrsos_brtos,
                                                           p_saldo_favor                => p_saldo_favor);
  
    return v_vlor_sncion;
  
  exception
    when others then
      return v_vlor_sncion;
  end fnc_co_valor_sancion;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL130
  function fnc_co_valor_descuento(p_id_dclrcion_vgncia_frmlrio number,
                                  p_id_dclrcion_crrccion       number,
                                  p_item_cncpto                varchar2,
                                  p_vlor_cncpto                number,
                                  p_idntfccion                 varchar2,
                                  p_fcha_pryccion              varchar2)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined as
  
    v_id_frmlrio_rgion_atrbto number;
    v_fla                     number;
    v_id_cncpto               number;
    v_cdgo_clnte              number;
    v_id_impsto               number;
    v_id_impsto_sbmpsto       number;
    v_vgncia                  number;
    v_id_prdo                 number;
    v_id_sjto_impsto          number;
  
    v_dscnto pkg_re_documentos.g_dtos_dscntos := pkg_re_documentos.g_dtos_dscntos();
  begin
    --Se identifica el atributo en el item
    select to_number(regexp_substr(regexp_substr(p_item_cncpto, 'ATR[1-9][0-9]*'), '[0-9]+'))
      into v_id_frmlrio_rgion_atrbto
      from dual;
  
    --Se identifica la fila en el item
    select nvl(to_number(regexp_substr(regexp_substr(p_item_cncpto, 'FLA[1-9][0-9]*'), '[0-9]+')), 1)
      into v_fla
      from dual;
  
    --Se identifica el concepto
    select e.id_cncpto
      into v_id_cncpto
      from v_gi_d_declaraciones_concepto e
     where e.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
       and e.id_frmlrio_rgion_atrbto    = v_id_frmlrio_rgion_atrbto
       and e.fla = v_fla;
  
    --Se calcula el descuento
    select a.id_dscnto_rgla,
           a.prcntje_dscnto,
           a.vlor_dscnto,
           a.id_cncpto_dscnto,
           a.id_cncpto_dscnto_grpo,
           null,
           null,
           null,
           null
      bulk collect
      into v_dscnto
      from table(pkg_gi_declaraciones
                    .fnc_co_valor_descuento(
                        p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                        p_id_dclrcion_crrccion       => p_id_dclrcion_crrccion,
                        p_id_cncpto                  => v_id_cncpto,
                        p_vlor_cncpto                => p_vlor_cncpto,
                        p_idntfccion                 => p_idntfccion,
                        p_fcha_pryccion              => p_fcha_pryccion)) a;
                        
    for i in 1 .. v_dscnto.count loop
      pipe row(v_dscnto(i));
    end loop;
  exception
    when others then
      null;
  end fnc_co_valor_descuento;

  --Funcion que valida la fecha maxima de presentacion de una declaracion
  --FDCL150
  function fnc_co_fcha_mxma_prsntcion(p_id_dclrcion_vgncia_frmlrio number,
                                      p_idntfccion                 varchar2,
                                      p_id_sjto_tpo                number default null,
                                      p_lcncia                     varchar2 default null)
    return timestamp as
  
    v_fcha_fnal         timestamp;
    v_cdgo_clnte        number;
    v_id_impsto         number;
    v_fcha_mxma_tsa_mra timestamp;
  
    v_error exception;
  
  begin
  
    --Se consulta la fecha limite de declaracion
    v_fcha_fnal := pkg_gi_declaraciones
                        .fnc_co_fcha_lmte_dclrcion(
                            p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                            p_idntfccion                 => p_idntfccion,
                            p_id_sjto_tpo                => p_id_sjto_tpo,
                            p_lcncia                     => p_lcncia);
  
    v_fcha_mxma_tsa_mra := v_fcha_fnal;
    --Si la fecha de declaracion supera la fecha actual
    if (v_fcha_fnal < trunc(systimestamp)) then
      --Se identifica el cliente y el impuesto
      begin
        select c.cdgo_clnte, c.id_impsto
          into v_cdgo_clnte, v_id_impsto
          from gi_d_dclrcnes_vgncias_frmlr      a
         inner join gi_d_dclrcnes_tpos_vgncias  b on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
         inner join gi_d_declaraciones_tipo     c on c.id_dclrcn_tpo = b.id_dclrcn_tpo
         where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
      exception
        when others then
          raise v_error;
      end;
    
      --Se consulta la fecha maxima de tasa mora
      begin
        select max(a.fcha_hsta)
          into v_fcha_mxma_tsa_mra
          from df_i_tasas_mora a
         where cdgo_clnte = v_cdgo_clnte
           and id_impsto = v_id_impsto;
      exception
        when others then
          raise v_error;
      end;
    end if;
  
    return v_fcha_mxma_tsa_mra;
  exception
    when v_error then
      return systimestamp - 1;
  end fnc_co_fcha_mxma_prsntcion;

  --Funcion que calcula el digito de verificacion de una identificacion
  --FDCL160
  function fnc_ca_digito_verificacion(p_identificacion varchar2)
    return number as
  
    v_identificacion   varchar2(100);
    v_tmnio_idntfccion number;
    x                  number := 0;
    y                  number := 0;
  
    type array_t is varray(15) of number;
    v_array_t array_t := array_t(3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71);
  
  begin
    --Se limpia la identificacion
    v_identificacion := replace(p_identificacion, ' ', ''); --Espacios
    v_identificacion := replace(v_identificacion, ',', ''); --Comas
    v_identificacion := replace(v_identificacion, '.', ''); --Puntos
    v_identificacion := replace(v_identificacion, '-', ''); --Guiones
  
    --Se valida que haya una identificacion
    if (v_identificacion is null) then
      dbms_output.put_line('return null');
    end if;
  
    v_tmnio_idntfccion := length(v_identificacion);
  
    --Procedimiento
    for i in 1 .. v_tmnio_idntfccion loop
      y := substr(v_identificacion, i, 1);
      x := x + (y * v_array_t((v_tmnio_idntfccion + 1) - i));
    end loop;
  
    y := mod(x, 11);
  
    if (y > 1) then
      return 11 - y;
    else
      return y;
    end if;
  end fnc_ca_digito_verificacion;
    
    function fnc_co_cncpto_intrs_vlddo(
									p_id_dclrcion_vgncia_frmlrio	number,
									p_item_acto_cncpto				varchar2,
									p_vlor_acto_cncpto              number,
									p_dclrcion_uso                  varchar2 default null,
									p_id_dclrcion_antrior			number default null,
									p_idntfccion                    varchar2,
									p_id_sjto_tpo					number default null,
									p_fcha_pryccion                 varchar2,
									p_vlor_ttal						number default null)
	
									
		return number as
		
        
        v_id_frmlrio_rgion_atrbto	    number;
		v_vlr_total_inicial			    number;
		v_fla                           number;
		v_id_cncpto                     number;
		v_gnra_intres_mra               varchar2(1);
		v_cdgo_clnte                    number;
		v_id_impsto                     number;
		v_id_impsto_sbmpsto             number;
		v_vgncia                        number;
		v_id_prdo                       number;
		v_fcha_fnal                     timestamp;
        v_nl                            number := 6;
		v_vlor_intres                   number := 0;
		v_fcha_prsntcion_inicial	    timestamp;
        
        
	begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo');
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_id_dclrcion_vgncia_frmlrio' || p_id_dclrcion_vgncia_frmlrio,1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_item_acto_cncpto' || p_item_acto_cncpto,1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_vlor_acto_cncpto' || p_vlor_acto_cncpto,1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_idntfccion' || p_idntfccion,1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_id_sjto_tpo' || p_id_sjto_tpo,1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_fcha_pryccion' || p_fcha_pryccion,1);
        
        /*p_id_dclrcion_vgncia_frmlrio	:=9941;
        p_item_acto_cncpto				:='RGN1042ATR5128FLAX';
        p_vlor_acto_cncpto              :=500000;
        p_dclrcion_uso                  :='DCO';
        p_id_dclrcion_antrior		   :=773392;
        p_idntfccion                   :=860020369;
        p_id_sjto_tpo					:=345;
        p_fcha_pryccion                 :='15/04/2022';*/
        
        --if(p_dclrcion_uso is null or p_fcha_pryccion is null or p_id_sjto_tpo is null) then
        if(p_dclrcion_uso is null or p_fcha_pryccion is null) then
                pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_dclrcion_uso is null or p_fcha_pryccion is null or p_id_sjto_tpo is null',1);

            return 0;
        end if;
		--Se identifica el atributo en el item
		select  to_number(regexp_substr(regexp_substr(p_item_acto_cncpto, 'ATR[1-9][0-9]*'), '[0-9]+'))
		into    v_id_frmlrio_rgion_atrbto
		from    dual;
        
        
		--Se identifica la fila en el item
		select  nvl(to_number(regexp_substr(regexp_substr(p_item_acto_cncpto, 'FLA[1-9][0-9]*'), '[0-9]+')), 1)
		into    v_fla
		from    dual;
        
        DBMS_OUTPUT.PUT_LINE('v_fla : '||v_fla) ;
        
		--Se identifica el concepto
		select  b.id_cncpto,
				b.gnra_intres_mra
		into    v_id_cncpto,
				v_gnra_intres_mra
		from    df_i_impuestos_acto_concepto    b
		where   exists(select  1
					  from    gi_d_dclrcnes_acto_cncpto   c
					  where   c.id_dclrcion_vgncia_frmlrio    =   p_id_dclrcion_vgncia_frmlrio
					  and     c.id_frmlrio_rgion_atrbto       =   v_id_frmlrio_rgion_atrbto
					  and     c.fla                           =   v_fla
					  and     c.id_impsto_acto_cncpto         =   b.id_impsto_acto_cncpto);


		if (v_gnra_intres_mra = 'N') then
			pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'v_gnra_intres_mra = N' ,1);
  
			return v_vlor_intres;

		end if;

        --DBMS_OUTPUT.PUT_LINE('COMENZANDO 3') ;--retorna 0
		--Se consultan los datos necesarios para calcular la sancion
		select      c.cdgo_clnte,
					c.id_impsto,
					c.id_impsto_sbmpsto,
					b.vgncia,
					b.id_prdo
		into        v_cdgo_clnte,
					v_id_impsto,
					v_id_impsto_sbmpsto,
					v_vgncia,
					v_id_prdo
		from        gi_d_dclrcnes_vgncias_frmlr a
		inner join  gi_d_dclrcnes_tpos_vgncias  b   on  b.id_dclrcion_tpo_vgncia    =   a.id_dclrcion_tpo_vgncia
		inner join  gi_d_declaraciones_tipo     c   on  c.id_dclrcn_tpo             =   b.id_dclrcn_tpo
		where       a.id_dclrcion_vgncia_frmlrio    =   p_id_dclrcion_vgncia_frmlrio;

		--Se consulta la fecha limite de declaracion
        DBMS_OUTPUT.PUT_LINE('v_cdgo_clnte : '||v_cdgo_clnte||'v_id_impsto : '||v_id_impsto_sbmpsto||'v_vgncia: '||v_vgncia||'v_id_prdo: '||v_id_prdo) ;
		
        select  pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio	=>  p_id_dclrcion_vgncia_frmlrio,
															   p_idntfccion					=>  p_idntfccion,
															   p_id_sjto_tpo				=>	p_id_sjto_tpo)
		into    v_fcha_fnal
		from    dual;
        		DBMS_OUTPUT.PUT_LINE('v_fcha_fnal: '||v_fcha_fnal) ;

	
		
        if (p_dclrcion_uso = 'DCO') then
        --se calcula el valor total de la declaracion inicial
					pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_dclrcion_uso = DCO' ,1);

        
        
        
                    begin
                         select vlor_ttal 
                        into v_vlr_total_inicial 
                        from gi_g_declaraciones a
                        where a.nmro_cnsctvo = p_id_dclrcion_antrior;
                        
                        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'v_vlr_total_inicial: ' || v_vlr_total_inicial ,1);
            
                    exception
                        when no_data_found then
                            return v_vlor_intres;
                            --null;
                        when too_many_rows then 
                         return v_vlor_intres;
                            --null;
                    end;
                    
                    --se calcula la fecha de la presentación de la declaracion inicial
                   
                    begin
                        select a.fcha_prsntcion
                        into v_fcha_prsntcion_inicial 
                        from gi_g_declaraciones a
                        where a.nmro_cnsctvo = p_id_dclrcion_antrior;
                    
                    exception
                        when no_data_found then
                             return v_vlor_intres;
                        when too_many_rows then 
                            return v_vlor_intres;
                    end;
                    
                    --Se calcula el valor de los interes en base a las condiciones del cliente		
                    --1.
                    pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_vlor_ttal: ' || p_vlor_ttal, 6);
                    pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'v_vlr_total_inicial: ' || v_vlr_total_inicial, 6);
                    
                    if( (p_vlor_ttal <= v_vlr_total_inicial or p_vlor_ttal >= v_vlr_total_inicial) and p_fcha_pryccion < v_fcha_fnal) then
                        
                       pkg_sg_log.prc_rg_log( 23001, null, 'pkg_gi_declaraciones_funciones.fnc_co_cncpto_intrs_vlddo',  v_nl, 'p_dclrcion_uso = DCO. hmz' ,1);

                        return v_vlor_intres;
                        
                    end if;
                    
                    --2.Cuando la declaración inicial se presenta dentro del plazo y la declaración de corrección se presenta fuera del plazo.
                    if(v_fcha_prsntcion_inicial <= v_fcha_fnal and p_fcha_pryccion > v_fcha_fnal ) then
                        
                         
                        --¿Qué sucede si el nuevo valor a pagar es mayor?
                        --En este caso, cuando es mayor valor a pagar, 
                        --SI se genera intereses de mora sobre ese mayor valor,
                        if(p_vlor_ttal > v_vlr_total_inicial) then
                        
                       
                            
                            select  pkg_gf_movimientos_financiero.fnc_cl_interes_mora (p_cdgo_clnte   => v_cdgo_clnte,
                                                                               p_id_impsto            => v_id_impsto,
                                                                               p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                               p_vgncia               => v_vgncia,
                                                                               p_id_prdo              => v_id_prdo,
                                                                               p_id_cncpto            => v_id_cncpto,
                                                                               p_vlor_cptal           => p_vlor_acto_cncpto,
                                                                               p_indcdor_clclo        => 'PRY',
                                                                               p_fcha_incio_vncmnto   => v_fcha_fnal,
                                                                               p_fcha_pryccion        => to_timestamp(p_fcha_pryccion, 'dd/mm/yyyy'))
                                                                               into    v_vlor_intres
                                                                               from    dual;
            
                            return v_vlor_intres;
                            
                        
                        end if;
                        
                        if(p_vlor_ttal <= v_vlr_total_inicial) then			
                            
                            return v_vlor_intres;
                            
                        end if;
                    
                    end if;
                    
                    --3.Cuando la declaración inicial se presenta fuera del plazo y la declaración de corrección se presenta fuera del plazo.
                    if(v_fcha_prsntcion_inicial > v_fcha_fnal and p_fcha_pryccion > v_fcha_fnal) then
                        
                        
                        if(p_vlor_ttal > v_vlr_total_inicial) then
                        
                         
                            select  pkg_gf_movimientos_financiero.fnc_cl_interes_mora (p_cdgo_clnte           => v_cdgo_clnte,
                                                                               p_id_impsto            => v_id_impsto,
                                                                               p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                               p_vgncia               => v_vgncia,
                                                                               p_id_prdo              => v_id_prdo,
                                                                               p_id_cncpto            => v_id_cncpto,
                                                                               p_vlor_cptal           => p_vlor_acto_cncpto,
                                                                               p_indcdor_clclo        => 'PRY',
                                                                               p_fcha_incio_vncmnto   => v_fcha_fnal,
                                                                               p_fcha_pryccion        => to_timestamp(p_fcha_pryccion, 'dd/mm/yyyy'))
                            into    v_vlor_intres
                            from    dual;
                            
                            return v_vlor_intres;
                        
                        end if;
                        
                        if(p_vlor_ttal <= v_vlr_total_inicial)then
                           
						   return v_vlor_intres;	
                            
                        end if;
                    
                    end if;
                    
                    
            end if;
            
            if(p_dclrcion_uso= 'DIN')then
            
                select  pkg_gf_movimientos_financiero.fnc_cl_interes_mora (p_cdgo_clnte           => v_cdgo_clnte,
																   p_id_impsto            => v_id_impsto,
																   p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
																   p_vgncia               => v_vgncia,
																   p_id_prdo              => v_id_prdo,
																   p_id_cncpto            => v_id_cncpto,
																   p_vlor_cptal           => p_vlor_acto_cncpto,
																   p_indcdor_clclo        => 'PRY',
																   p_fcha_incio_vncmnto   => v_fcha_fnal,
																   p_fcha_pryccion        => to_timestamp(p_fcha_pryccion, 'dd/mm/yyyy'))
                into    v_vlor_intres
                from    dual;

                return v_vlor_intres;
                
            end if;
                
           --return v_vlor_intres;

 exception
     when others then
         return v_vlor_intres;
            
end fnc_co_cncpto_intrs_vlddo;
    
end pkg_gi_declaraciones_funciones;

/
