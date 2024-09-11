--------------------------------------------------------
--  DDL for Package Body PKG_GF_EXENCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_EXENCIONES" as 
	procedure prc_rg_exenciones ( p_cdgo_clnte			in number
								, p_cdgo_exncion_orgen	in varchar2
								, p_id_orgen			in number
								, p_id_sjto_impsto		in number
								, p_id_usrio			in number
								, o_id_exncion_slctud	out number
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2)as
	
	-- Registrar solicitud exencion --  
	v_nl				number;

	begin
	-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rg_exenciones');
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rg_exenciones',  v_nl, 'Entrando ' || systimestamp, 1); 

		--Registrar la exencion
		begin 
			insert into gf_g_exenciones_solicitud (cdgo_exncion_orgen,		id_orgen, 		cdgo_exncion_estdo,
												   id_usrio_rgstra,			fcha_rgstro,	id_sjto_impsto)
											values (p_cdgo_exncion_orgen,	p_id_orgen,		'RGS',
													p_id_usrio,				sysdate,		p_id_sjto_impsto)
				   returning id_exncion_slctud into o_id_exncion_slctud
				   ;
			o_cdgo_rspsta	:= 0;
			o_mnsje_rspsta  := 'Registro de solicitud de Exencion exitoso'; 
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rg_exenciones', v_nl, o_mnsje_rspsta, 6);
		exception
			when others then 
				o_cdgo_rspsta	:= 1;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar la solicitud de exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rg_exenciones', v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Registrar la exencion

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rg_exenciones',  v_nl, 'Saliendo ' || systimestamp, 1); 
	end;


	procedure prc_rc_exenciones ( p_cdgo_clnte			in number
								, p_id_exncion_slctud	in number
								, p_id_usrio			in number
								, p_obsrvcion_rchzo		in varchar2
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2)as 

	-- Rechazo de solicitud de exencion
	v_nl				number;

	begin 
		-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rc_exenciones');
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rc_exenciones',  v_nl, 'Entrando ' || systimestamp, 1); 

		-- Rechazo de solicitud de exencion
		begin 
			update gf_g_exenciones_solicitud
			   set id_usrio_rspsta		= p_id_usrio
			     , fcha_rspsta			= sysdate
				 , obsrvcion_rchzo		= p_obsrvcion_rchzo
				 , cdgo_exncion_estdo	= 'RCH'
			 where id_exncion_slctud	= p_id_exncion_slctud;

			o_cdgo_rspsta	:= 0;
			o_mnsje_rspsta  := 'Rechazo de solicitud de Exencion exitoso'; 
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rc_exenciones', v_nl, o_mnsje_rspsta, 6);
		exception
			when others then 
				o_cdgo_rspsta	:= 1;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar la solicitud de exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rc_exenciones', v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Rechazo de solicitud de exencion

	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_rc_exenciones',  v_nl, 'Saliendo ' || systimestamp, 1); 
	end;


	procedure prc_gn_proyecion_exencion (p_cdgo_clnte			in number
									   , p_id_rnta				in number
									   , p_id_exncion_slctud	in number
									   , p_id_exncion			in number
									   , p_id_exncion_mtvo		in number
									   , p_id_plntlla			in number
									   , p_id_usrio				in number
									   , o_cdgo_rspsta			out number 
									   , o_mnsje_rspsta			out varchar2) as 

	-- Proyeción de exenciones --  
	v_nl							number;
	v_nmbre_up						varchar2(70)	:= 'pkg_gf_exenciones.prc_gn_proyecion_exencion';

	begin
		-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1); 

		-- Se elimina el detalle del a solicitud
		begin
			delete from gf_g_exncnes_slctud_dtlle where id_exncion_slctud = p_id_exncion_slctud;
		exception
			when others then 
				o_cdgo_rspsta	:= 1;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al eliminar los conceptos en el detalle de la exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return; 
		end; --Fin Se elimina el detalle del a solicitud

		--Registrar los conceptos en el detalle de la exencion
        begin 
            for c_exncion_cncpto in ( select e.id_exncion_cncpto
                                           , c.dscrpcion_cncpto
                                           , c.vlor_lqddo                   vlor_cncpto
                                           , e.prcntje_exncion
                                           , c.vlor_lqddo * (e.prcntje_exncion / 100) vlor_exnto
                                           , c.vlor_lqddo - c.vlor_lqddo  * (e.prcntje_exncion / 100) vlor_ttal
                                        from gi_g_rentas						a
                                        join gi_g_rentas_acto                   b on a.id_rnta      = b.id_rnta
                                        join v_gi_g_rentas_acto_concepto        c on b.id_rnta_acto = c.id_rnta_acto
                                        join df_i_exenciones                    d on a.cdgo_clnte   = d.cdgo_clnte
                                         and d.id_exncion                       = p_id_exncion
                                        join df_i_exenciones_concepto           e on d.id_exncion   = e.id_exncion
                                         and a.id_impsto                        = e.id_impsto
                                         and a.id_impsto_sbmpsto                = e.id_impsto_sbmpsto
                                         and c.id_cncpto                        = e.id_cncpto
                                       where a.id_rnta                          = P_id_rnta
                        )loop
                  -- Se registran los conceptos exencionados
                begin
                    insert into gf_g_exncnes_slctud_dtlle (id_exncion_slctud,                   id_exncion,							id_exncion_cncpto,
                                                            vlor_cncpto,                        prcntje_exncion,                	vlor_exnto)
                                                   values ( p_id_exncion_slctud,                p_id_exncion,                       c_exncion_cncpto.id_exncion_cncpto,
                                                            c_exncion_cncpto.vlor_cncpto,       c_exncion_cncpto.prcntje_exncion,   c_exncion_cncpto.vlor_exnto);

                    o_mnsje_rspsta  := 'Registro del detalle de la solicitud de Exencion exitoso'; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);

                exception
                    when others then 
                        o_cdgo_rspsta	:= 2;
                        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar los conceptos en el detalle de la exencion, ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;    
                end;-- Fin Registrar los conceptos en el detalle de la exencion
            end loop; -- Se consultan los conceptos - para registrar los conceptos en el detalle de la exencion
        end; -- Fin de Registrar el detalle de la exencion

        -- Se elimina el motivo de la exencion
		begin
			delete from gf_g_exenciones_slctud_mtvo where id_exncion_slctud = p_id_exncion_slctud;
		exception
			when others then 
				o_cdgo_rspsta	:= 3;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al eliminar motivo de la exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return; 
		end; --Fin Se elimina el motivo de la exencion

		--Registrar el motivo de la exencion
        begin 
			insert into gf_g_exenciones_slctud_mtvo (id_exncion_slctud,        id_exncion_mtvo)
                                           values (p_id_exncion_slctud,        p_id_exncion_mtvo);

                o_mnsje_rspsta  := 'Registro del motivo de exención exitoso'; 
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
            when others then 
                o_cdgo_rspsta    := 4;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar el motivo de exencion, ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;    
        end; -- Fin de Registrar el motivo de la exencion

		-- Se actualiza el estado de la renta a proyectada
		begin
			update gf_g_exenciones_solicitud
			   set id_plntlla			= p_id_plntlla
			     , id_usrio_prycta		= p_id_usrio
				 , fcha_pryccion		= systimestamp
			 where id_exncion_slctud	= p_id_exncion_slctud;
		exception
            when others then 
                o_cdgo_rspsta	:= 5;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al actualizar la plantilla en la solicitud de excención, ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
		end; -- Fin Se actualiza el estado de la renta a proyectada


		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo ' || systimestamp, 1); 
	end;


	procedure prc_ap_exenciones ( p_cdgo_clnte			in number
								, p_id_rnta				in number
								, p_id_exncion_slctud	in number
								, p_id_exncion			in number
								, p_id_exncion_mtvo		in number
								, p_id_usrio			in number
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2)as

	-- Aprobar la solicitud de exencion de renta --  
	v_nl							number;
	v_nmbre_up						varchar2(70)	:= 'pkg_gf_exenciones.prc_ap_exenciones';
	v_id_exncion_slctud				number;
	t_gi_g_rentas					gi_g_rentas%rowtype;
	v_df_i_impuestos_subimpuesto	df_i_impuestos_subimpuesto%rowtype;
	t_df_i_impuestos_acto			v_df_i_impuestos_acto%rowtype;
	v_id_lqdcion_tpo				number;
	v_vgncia_actual					number;
	v_id_prdo_actual				number;
	v_cdgo_prdcdad					df_i_periodos.cdgo_prdcdad%type;
	v_id_lqdcion					number; -- Id liquidación del certificado de exencion
	v_vlor_ttal_lqdcion				number;
    v_vgncia_prdo           		clob;
	v_fcha_vncmnto					date;
	v_id_dcmnto						number;
	v_id_ajste_mtvo					number;
	v_id_ajste						number;
	v_json_ajste					clob;
	v_id_impsto_acto				number;
	v_id_acto						number;
	v_id_plntlla					number;

	begin
	-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1); 

		-- Se consulta los datos de solicitud de exencion
		begin 
			select id_exncion_slctud
			     , id_plntlla
			  into v_id_exncion_slctud
			     , v_id_plntlla
			  from gf_g_exenciones_solicitud
			 where id_exncion_slctud		= p_id_exncion_slctud
			   and cdgo_exncion_estdo		= 'RGS';

			o_mnsje_rspsta  := 'v_id_exncion_slctud: ' || v_id_exncion_slctud;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);

		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 1;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ':No se encontro la solictud de exencion ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 
				o_cdgo_rspsta	:= 2;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la solictud de exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Se consulta los datos de solicitud de exencion

		-- Consulta de datos de la renta 
		begin 
			select *
			  into t_gi_g_rentas
			  from gi_g_rentas
			 where id_rnta 		= p_id_rnta;

			o_mnsje_rspsta  := 't_gi_g_rentas.id_rnta: ' || t_gi_g_rentas.id_rnta;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 3;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro datos de la renta';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 4;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la información de la renta';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end;-- Fin Consulta de datos de la renta 

		-- Consulta el impuesto acto de la renta
		begin 
			select distinct id_impsto_acto
			  into v_id_impsto_acto
			  from v_gi_g_rentas_acto_concepto
			 where id_rnta 	= p_id_rnta;

			o_mnsje_rspsta  := 'v_id_impsto_acto: ' || v_id_impsto_acto;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 5;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro el acto impuesto de la renta';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 6;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar el impuesto acto de la renta';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end;-- Fin  Consulta el impuesto acto de la renta


        -- Se consulta la vigencia actual
		begin 
			select pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte 				=> p_cdgo_clnte
																 , p_cdgo_dfncion_clnte_ctgria 	=> 'GFN'
																 , p_cdgo_dfncion_clnte 		=> 'VAC') vgncia_actual
			 into v_vgncia_actual
			 from dual; 
			o_mnsje_rspsta  := 'v_vgncia_actual: ' || v_vgncia_actual;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 7;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro la vigencia actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 8;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la vigencia actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- FIN Se consulta la vigencia actual

		-- Se consulta el periodo actual para el subimpuesto de la renta
		begin 
			select a.id_prdo
				 , a.cdgo_prdcdad
			 into v_id_prdo_actual
				, v_cdgo_prdcdad
			 from df_i_periodos			a
			where a.cdgo_clnte			= p_cdgo_clnte
			  and a.id_impsto			= t_gi_g_rentas.id_impsto
			  and a.id_impsto_sbmpsto	= t_gi_g_rentas.id_impsto_sbmpsto
			  and a.vgncia				= v_vgncia_actual
			  and a.prdo				= pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte 					=> p_cdgo_clnte
																						, p_cdgo_dfncion_clnte_ctgria 	=> 'GFN'
																						, p_cdgo_dfncion_clnte			=> 'PAC');
		o_mnsje_rspsta  := 'v_id_prdo_actual: ' || v_id_prdo_actual;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
			when no_data_found then 
				o_cdgo_rspsta	:= 9;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro el periodo actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 10;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar el periodo actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- FIN Se consulta el periodo actual


		-- GENERAR EL CERTIFICADO -- 
		begin 
			pkg_gf_exenciones.prc_gn_certificado_exencion(p_cdgo_clnte          => p_cdgo_clnte
														, p_id_exncion_slctud   => p_id_exncion_slctud
														, p_id_plntlla          => v_id_plntlla
														, p_id_usrio            => p_id_usrio
														, o_id_acto             => v_id_acto
														, o_cdgo_rspsta         => o_cdgo_rspsta
														, o_mnsje_rspsta        => o_mnsje_rspsta);

			if o_cdgo_rspsta!= 0 then 
				o_cdgo_rspsta	:= 13;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el cerfificado de la excención';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			else
				o_mnsje_rspsta  := 'generación del cerfificado exitoso. o_id_acto: ' || v_id_acto;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
			end if;
		end;
		-- FIN GENERAR EL CERTIFICADO -- 

		-- REALIZAR LOS AJSUTES DE LAS EXENCIONES -- 
		-- Se consulta el motivo del ajustes para exenciones
		begin 
			select id_ajste_mtvo
			  into v_id_ajste_mtvo
			  from gf_d_ajuste_motivo 
			 where cdgo_clnte				= p_cdgo_clnte
			   and id_impsto 				= t_gi_g_rentas.id_impsto 
			   and cdgo_ajste_mtvo 			= 'EXN';

			o_mnsje_rspsta  := 'v_id_ajste_mtvo: ' || v_id_ajste_mtvo;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 13;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro datos motivo de ajuste de exencion';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 14;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar el motivo de ajuste de exencion. ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;				
		end;-- Fin Se consulta el motivo del ajustes para exenciones

		-- Se construye el json con los conceptos a exencionar
		begin 
			select '[' || listagg ( json_object ('VGNCIA'           value vgncia
												, 'ID_PRDO'         value id_prdo
												, 'ID_CNCPTO'       value id_cncpto
												, 'VLOR_SLDO_CPTAL'	value vlor_sldo_cptal
												, 'VLOR_INTRES'     value vlor_intres
												, 'VLOR_AJSTE'      value vlor_ajste
												, 'AJSTE_DTLLE_TPO' value ajste_dtlle_tpo), ',' 
								   ) || ']' ajuste
			    into v_json_ajste
			  from (select v_vgncia_actual      vgncia
						 , v_id_prdo_actual		id_prdo
						 , id_cncpto               
						 , vlor_cncpto          vlor_sldo_cptal
						 , 0                    vlor_intres
						 , vlor_exnto           vlor_ajste
						 , 'C'                  ajste_dtlle_tpo
				    from v_gf_g_exncnes_slctud_dtlle 
				   where id_exncion_slctud    	= p_id_exncion_slctud
					);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 15;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro información de concepto exentos';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 16;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la información de concepto exentos. ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Se construye el json con los conceptos a exencionar

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Json ajuste: ' || v_json_ajste, 6);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_id_orgen_mvmnto: ' || t_gi_g_rentas.id_lqdcion, 6);
		dbms_output.put_line('json ajuste: ' || v_json_ajste);

		begin
			pkg_gf_ajustes.prc_ap_ajuste_automatico (p_cdgo_clnte 			=> p_cdgo_clnte
												   , p_id_impsto 			=> t_gi_g_rentas.id_impsto
												   , p_id_impsto_sbmpsto	=> t_gi_g_rentas.id_impsto_sbmpsto
												   , p_id_sjto_impsto 		=> t_gi_g_rentas.id_sjto_impsto
												   , p_tpo_ajste  			=> 'CR'
												   , p_id_ajste_mtvo  		=> v_id_ajste_mtvo
												   , p_obsrvcion  			=> 'Exención N° ' || p_id_exncion_slctud
												   , p_tpo_dcmnto_sprte		=> '116102'
												   , p_nmro_dcmto_sprte		=> '116102'
												   , p_fcha_dcmnto_sprte	=> sysdate
												   , p_nmro_slctud  		=> t_gi_g_rentas.nmro_rnta
												   , p_id_usrio  			=> p_id_usrio
												   , p_json              	=> v_json_ajste
												   , p_ind_ajste_prcso   	=> null

												   , p_id_orgen_mvmnto       => t_gi_g_rentas.id_lqdcion
												   , p_id_impsto_acto        => v_id_impsto_acto    

												   , o_id_ajste				=> v_id_ajste
												   , o_cdgo_rspsta			=> o_cdgo_rspsta
												   , o_mnsje_rspsta			=> o_mnsje_rspsta);					

			if o_cdgo_rspsta != 0 then 
				o_cdgo_rspsta	:= 17;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el ajuste: ' || o_mnsje_rspsta;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			else
				o_mnsje_rspsta  := 'Ajustes realizado exitosamente. v_id_ajste: ' || v_id_ajste;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
			end if;
		exception
			when others then 
				o_cdgo_rspsta	:= 18;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el ajuste: ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end;
		-- FIN REALIZAR LOS AJSUTES DE LAS EXENCIONES -- 

		-- LIQUIDAR EL CERTIFICADO DE EXENCION --
		-- Se consulta el impuesto y el subimpuesto de certificado de exencion
		begin
			select c.*
			  into t_df_i_impuestos_acto
			  from gi_d_rentas_configuracion     	a
			  join gi_d_rntas_cnfgrcion_sbmpst   	b on a.id_rnta_cnfgrcion 		= b.id_rnta_cnfgrcion
			  join v_df_i_impuestos_acto			c on b.id_impsto_acto_exncion   = c.id_impsto_acto
			 where a.cdgo_clnte                  	= t_gi_g_rentas.cdgo_clnte
			   and a.id_impsto						= t_gi_g_rentas.id_impsto
			   and b.id_impsto_sbmpsto           	= t_gi_g_rentas.id_impsto_sbmpsto;

			o_mnsje_rspsta  := 't_df_i_impuestos_acto.id_impsto_sbmpsto: ' || t_df_i_impuestos_acto.id_impsto_sbmpsto;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 19;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro datos del subimpuesto';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 20;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar los datos del subimpuesto';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	

		end; -- FIN Se consulta el impuesto y el subimpuesto de certificado de exencion

		-- Consulta el id del tipo de liquidación
		begin
             select id_lqdcion_tpo 
               into v_id_lqdcion_tpo 
               from df_i_liquidaciones_tipo
              where cdgo_clnte              = p_cdgo_clnte
                and id_impsto               = t_gi_g_rentas.id_impsto
                and cdgo_lqdcion_tpo        = 'LB';

			o_mnsje_rspsta  := 'v_id_lqdcion_tpo: ' || v_id_lqdcion_tpo;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
            when no_data_found then
                o_cdgo_rspsta   := 21;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al obtener el tipo de liquidación. ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
        end;-- Fin Consulta el id del tipo de liquidación

		-- Se consulta el periodo actual para el subimpuesto del cerfificado de la excención
		begin 
			select a.id_prdo
				 , a.cdgo_prdcdad
			 into v_id_prdo_actual
				, v_cdgo_prdcdad
			 from df_i_periodos			a
			where a.cdgo_clnte			= p_cdgo_clnte
			  and a.id_impsto			= t_df_i_impuestos_acto.id_impsto
			  and a.id_impsto_sbmpsto	= t_df_i_impuestos_acto.id_impsto_sbmpsto
			  and a.vgncia				= v_vgncia_actual
			  and a.prdo				= pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte 					=> p_cdgo_clnte
																						 , p_cdgo_dfncion_clnte_ctgria 	=> 'GFN'
																						 , p_cdgo_dfncion_clnte			=> 'PAC');
        o_mnsje_rspsta  := 'v_id_prdo_actual del cerfificado: ' || v_id_prdo_actual;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 22;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro el periodo actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 23;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar el periodo actual';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- FIN Se consulta el periodo actual


		-- Se registra la liquidación
		begin
			-- Se consulta el total de la liquidación 
			select sum(pkg_gn_generalidades.fnc_ca_expresion( p_vlor      => b.vlor_trfa_clcldo
														, p_expresion => b.exprsion_rdndeo ) )vlor_ttal_lqdccion
			  into v_vlor_ttal_lqdcion
			  from v_df_i_impuestos_acto_concepto	a
			  join v_gi_d_tarifas_esquema			b on a.id_impsto_acto_cncpto    = b.id_impsto_acto_cncpto
			 where a.id_impsto						= t_df_i_impuestos_acto.id_impsto
			   and a.id_impsto_sbmpsto				= t_df_i_impuestos_acto.id_impsto_sbmpsto
		       and a.id_impsto_acto					= t_df_i_impuestos_acto.id_impsto_acto; 

			insert into gi_g_liquidaciones (cdgo_clnte,         id_impsto,            				id_impsto_sbmpsto,      					vgncia,                 
											id_prdo,            id_sjto_impsto,         			fcha_lqdcion,           					cdgo_lqdcion_estdo, 
											bse_grvble,         vlor_ttal,              			cdgo_prdcdad,           					id_lqdcion_tpo,
											id_usrio)
									 values(p_cdgo_clnte,       t_df_i_impuestos_acto.id_impsto,	t_df_i_impuestos_acto.id_impsto_sbmpsto,	v_vgncia_actual,                   
											v_id_prdo_actual,  	t_gi_g_rentas.id_sjto_impsto,		sysdate,                 					'L',                
											1,       			v_vlor_ttal_lqdcion,    			v_cdgo_prdcdad, 							v_id_lqdcion_tpo,
											p_id_usrio) 
				  returning id_lqdcion into v_id_lqdcion;  

			o_mnsje_rspsta  := 'Registro Exitoso de la liquidación del cerfificado. v_id_lqdcion: ' || v_id_lqdcion;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when others then
				o_cdgo_rspsta   := 24;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar la liquidación' || sqlerrm;		
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Se registra la liquidación

		-- Se consultan los conceptos para el certificado de exencion
		begin
			for c_lqdccion_dtlle in (select a.id_impsto_acto_cncpto 
										, 1 									bse_cncpto
										, 'N' 									indcdor_lmta_impsto 
										, b.vlor_trfa
										, b.txto_trfa
                                        , pkg_gn_generalidades.fnc_ca_expresion( p_vlor      => b.vlor_trfa_clcldo
                                                                               , p_expresion => b.exprsion_rdndeo )vlor_lqddo
										, a.fcha_vncmnto
									 from v_df_i_impuestos_acto_concepto    a
									 join v_gi_d_tarifas_esquema            b on a.id_impsto_acto_cncpto    = b.id_impsto_acto_cncpto
									where a.id_impsto                       = t_df_i_impuestos_acto.id_impsto
									  and a.id_impsto_sbmpsto               = t_df_i_impuestos_acto.id_impsto_sbmpsto 
									  and a.id_impsto_acto					= t_df_i_impuestos_acto.id_impsto_acto) loop


				-- Registro del detalle de liquidación
				begin 
					insert into gi_g_liquidaciones_concepto (id_lqdcion,                    id_impsto_acto_cncpto,                  	vlor_lqddo,                     vlor_clcldo, 
                                                             trfa,                          bse_cncpto,                             	txto_trfa,                      vlor_intres,
                                                             indcdor_lmta_impsto,           fcha_vncmnto)
                                                      values(v_id_lqdcion,                  c_lqdccion_dtlle.id_impsto_acto_cncpto,		c_lqdccion_dtlle.vlor_lqddo,    c_lqdccion_dtlle.vlor_lqddo, 
                                                             c_lqdccion_dtlle.vlor_trfa,    c_lqdccion_dtlle.bse_cncpto,				c_lqdccion_dtlle.txto_trfa,     0,
                                                             'N',                           c_lqdccion_dtlle.fcha_vncmnto);
					v_fcha_vncmnto	:= trunc(c_lqdccion_dtlle.fcha_vncmnto);

					o_mnsje_rspsta  := 'Registro Exitoso del concepto de liquidación del cerfificado. id_impsto_acto_cncpto: ' || c_lqdccion_dtlle.id_impsto_acto_cncpto;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
				exception
					when others then
						o_cdgo_rspsta   := 25;
						o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al registrar el detalle de la liquidación' || sqlerrm;	
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);							
						rollback;
						return;	
				end;-- FIN Registro del detalle de liquidación
			end loop;
		end;-- FIN Se consultan los conceptos para el certificado de exencion		
		-- FIN LIQUIDAR EL CERTIFICADO DE EXENCION -- 

		-- PASO A MOVIMIENTO FINANCIERO
		begin
			pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte			=>  p_cdgo_clnte,	 
																		 p_id_lqdcion			=>  v_id_lqdcion,	                                                                                
																		 p_cdgo_orgen_mvmnto	=>  'LQ',
																		 p_id_orgen_mvmnto		=>  v_id_lqdcion,
																		 o_cdgo_rspsta			=>  o_cdgo_rspsta,	
																		 o_mnsje_rspsta			=>  o_mnsje_rspsta);

			o_mnsje_rspsta  := 'Paso a movimientos financieros Exitoso de la liquidación del cerfificado.' ;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when others then
				o_cdgo_rspsta   := 26;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al pasar a movimientos financieros' || sqlerrm;	
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; 
		-- FIN PASO A MOVIMIENTO FINANCIERO

		-- GENERAR EL DOCUMENTO DE PAGO DE EXENCION ---
		-- Se crea el json de cartera
		begin
			select json_object ('VGNCIA_PRDO'   value JSON_ARRAYAGG(
				   json_object ('vgncia'        value vgncia,
								'prdo'          value prdo,
								'id_orgen'      value id_orgen))) vgncias_prdo
						  into v_vgncia_prdo
						  from (select  vgncia
									  , prdo
									  , id_orgen
								  from v_gf_g_movimientos_financiero 
								 where cdgo_clnte    = p_cdgo_clnte
								   and id_orgen      = v_id_lqdcion
								);
			o_mnsje_rspsta  := 'v_vgncia_prdo: ' || v_vgncia_prdo;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta	:= 27;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro información de la cartera';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
			when others then 			
				o_cdgo_rspsta	:= 28;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la información de la cartera';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- FIn Se crea el json de cartera

		-- Se registra el documento
		begin
			v_id_dcmnto  := pkg_re_documentos.fnc_gn_documento ( p_cdgo_clnte           => p_cdgo_clnte
															   , p_id_impsto 			=> t_df_i_impuestos_acto.id_impsto
															   , p_id_impsto_sbmpsto 	=> t_df_i_impuestos_acto.id_impsto_sbmpsto
															   , p_cdna_vgncia_prdo		=> v_vgncia_prdo
															   , p_cdna_vgncia_prdo_ps	=> null
															   , p_id_dcmnto_lte		=> null
															   , p_id_sjto_impsto       => t_gi_g_rentas.id_sjto_impsto
															   , p_fcha_vncmnto			=> v_fcha_vncmnto
															   , p_cdgo_dcmnto_tpo      => 'DNO'
															   , p_nmro_dcmnto          => null
															   , p_vlor_ttal_dcmnto     => v_vlor_ttal_lqdcion
															   , p_indcdor_entrno       => 'PRVDO');
			o_mnsje_rspsta  := 'v_id_dcmnto: ' || v_id_dcmnto;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when others then 			
				o_cdgo_rspsta	:= 29;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el documento' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- FIn Se registra el documento
		-- FIN GENERAR EL DOCUMENTO DE PAGO DE EXENCION --

		--Actualizar el estado de la solicitud de exencion a Aprobada
		begin 
			update gf_g_exenciones_solicitud
			   set cdgo_exncion_estdo	= 'APB'
				 , id_usrio_rspsta 		= p_id_usrio
                 , fcha_rspsta  		= sysdate
				 , id_lqdcion			= v_id_lqdcion
				 , id_dcmnto			= v_id_dcmnto
				 , id_acto				= v_id_acto
				 , id_ajste				= v_id_ajste
			 where id_exncion_slctud	= p_id_exncion_slctud;

			o_cdgo_rspsta	:= 0;
			o_mnsje_rspsta  := 'Aprobacón de solicitud de exencion exitoso'; 
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		exception
			when others then 
				o_cdgo_rspsta	:= 30;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al actualizar el estado de la solicitud de exencion, ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;	
		end; -- Fin Actualizar el estado de la solicitud de exencion a Aprobada		

		-- Si tiene saldo por pagar, se genera el documento de la renta

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_exenciones.prc_ap_exenciones',  v_nl, 'Saliendo ' || systimestamp, 1); 
	end;	

	function fnc_co_certifado_exncion_dtlle (p_id_exncion_slctud	in number) return clob is

		-- Función que retorna el detalle del cerfificado de excención
		v_select 		    clob; 
		v_vlor_ttal_cnpto   number  := 0;
		v_vlor_ttal_exnto   number  := 0;
		v_vlor_ttal_pgo     number  := 0;
		v_id_acto_tpo		number;
		v_json_acto			clob;

	begin 
		-- Encabezado de la tabla
		v_select :=	'<table align="center" border="1px" style= "width: 550px; font-size:30px; font-family:''''Courier New''''; border-collapse: collapse; border-color: black !important;">
						<tr style="vertical-align:middle; background-color: #A9A9A9; font-weight: bold" ><td style="text-align:center;>
							<th style="padding: 10px !important; width:60%"><Font size=2><br>Concepto</th>
							<th style="padding: 10px !important; width:10%"><Font size=2>Valor de Concepto</th> 
							<th style="padding: 10px !important; width:10%"><Font size=2>% Exento</th> 
							<th style="padding: 10px !important; width:10%"><Font size=2>Valor Exento</th> 
							<th style="padding: 10px !important; width:10%"><Font size=2>Valor a Pagar</th> 
						</tr>';
		-- Se construye el cuerpo de la tabla con el detalle de la exencion
		for c_exncion in (select a.dscrpcion_cncpto
							   , a.vlor_cncpto
							   , a.prcntje_exncion
							   , a.vlor_exnto
							   , (a.vlor_cncpto - a.vlor_exnto) * (a.prcntje_exncion / 100) vlor_ttal
							from v_gf_g_exncnes_slctud_dtlle   	a 
                           where a.id_exncion_slctud            = p_id_exncion_slctud
						order by a.dscrpcion_cncpto) loop

			v_select := v_select ||'<tr><td style="text-align:left;">	<Font size=2>'||c_exncion.dscrpcion_cncpto||'</td>
										<td style="text-align:right;">	<Font size=2>'||to_char(c_exncion.vlor_cncpto,'FM$999G999G999G999G999G999G990')||'</td>
										<td style="text-align:center;">	<Font size=2>'||c_exncion.prcntje_exncion || '%' || '</td>
										<td style="text-align:right;">	<Font size=2>'||to_char(c_exncion.vlor_exnto,'FM$999G999G999G999G999G999G990')||'</td>
										<td style="text-align:right;">	<Font size=2>'||to_char(c_exncion.vlor_ttal,'FM$999G999G999G999G999G999G990')||'</td>
									</tr>';
			-- Se van acumulando los valores totales
			v_vlor_ttal_cnpto   := v_vlor_ttal_cnpto    + c_exncion.vlor_cncpto;
			v_vlor_ttal_exnto   := v_vlor_ttal_exnto    + c_exncion.vlor_exnto;
			v_vlor_ttal_pgo     := v_vlor_ttal_pgo      + c_exncion.vlor_ttal;

		end loop; 
		-- Se construye la fila de totales
		v_select := v_select ||'<tr style="background-color: #A9A9A9; font-weight: bold" ><td style="text-align:right;>
									<td style="text-align:left;">	<Font size=3>TOTAL</td>
									<td style="text-align:right;">	<Font size=3>'||to_char(v_vlor_ttal_cnpto,'FM$999G999G999G999G999G999G990')||'</td>
									<td style="text-align:center;">	<Font size=3></td>
									<td style="text-align:right;">	<Font size=3>'||to_char(v_vlor_ttal_exnto,'FM$999G999G999G999G999G999G990')||'</td>
									<td style="text-align:right;">	<Font size=3>'||to_char(v_vlor_ttal_pgo,'FM$999G999G999G999G999G999G990')||'</td>
								</tr>';

		-- Se finaliza la tabla
		v_select := v_select || '</table>';
		return v_select;
	end;


	procedure prc_gn_certificado_exencion (p_cdgo_clnte			in number
										 , p_id_exncion_slctud	in number
										 , p_id_plntlla			in number
										 , p_id_usrio			in number
										 , o_id_acto			out number
										 , o_cdgo_rspsta		out number 
										 , o_mnsje_rspsta		out varchar2) as
		-- Procedimiento que genera el acto y el reporte de cerfificado de excención 
		v_nl                 	number;
		v_nmbre_up				varchar2(70) := 'pkg_gf_exenciones.prc_gn_certificado_exencion';

		v_slct_sjto_impsto    	clob;
		v_slct_vngcias        	clob;
		v_slct_rspnsble       	clob;
		v_json_acto				clob;
		v_id_acto_tpo			number;
		v_id_acto             	number;
		v_dcmnto				clob;
		v_id_plntlla			number;
		v_gn_d_reportes			gn_d_reportes%rowtype;
		v_blob					blob;
		v_app_page_id			number := v('APP_PAGE_ID');
		v_app_id				number := v('APP_ID');
		v_id_orgen 				number;

	begin 
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Entrando ' || systimestamp, 1);

		-- GENERACIÓN DEL ACTO --
		-- Select para obtener el sub-tributo y sujeto impuesto
		v_slct_sjto_impsto := 'select distinct b.id_impsto_sbmpsto
									, a.id_sjto_impsto
								 from gf_g_exenciones_solicitud     a
								 join v_gf_g_exncnes_slctud_dtlle   b on a.id_exncion_slctud    = b.id_exncion_slctud
								where a.id_exncion_slctud     		= '|| p_id_exncion_slctud;

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_slct_sjto_impsto:' || v_slct_sjto_impsto, 6);
		-- Select para obtener los responsables de un acto
		v_slct_rspnsble   := 'select b.cdgo_idntfccion_tpo
								   , b.idntfccion
								   , b.prmer_nmbre
								   , b.sgndo_nmbre 
								   , b.prmer_aplldo
								   , b.sgndo_aplldo
								   , nvl(b.drccion_ntfccion, c.drccion_ntfccion)        drccion_ntfccion
								   , nvl(b.id_pais_ntfccion, c.id_pais_ntfccion)        id_pais_ntfccion
								   , nvl(b.id_dprtmnto_ntfccion, c.id_dprtmnto_ntfccion)id_dprtmnto_ntfccion
								   , nvl(b.id_mncpio_ntfccion, c.id_mncpio_ntfccion)    id_mncpio_ntfccion
								   , b.email
								   , b.tlfno
								from gf_g_exenciones_solicitud      a
								join si_i_sujetos_responsable    	b on a.id_sjto_impsto = b.id_sjto_impsto
								join si_i_sujetos_impuesto          c on a.id_sjto_impsto = c.id_sjto_impsto
							   where a.id_exncion_slctud     		= '|| p_id_exncion_slctud;


		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_slct_rspnsble:' || v_slct_rspnsble, 6);
		-- Se consulta el origen de la exencion
		begin
			select id_orgen
				into v_id_orgen
			from  gf_g_exenciones_solicitud
			where  id_exncion_slctud = p_id_exncion_slctud;

		exception
			when no_data_found then 
			o_cdgo_rspsta := 1;
			o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro e origen de la exencion';
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
			rollback;
			return;
		end;  -- Fin se consulta el origen de la exencion


		-- Se consulta el id del tipo del acto
		begin
			select id_acto_tpo
			  into v_id_acto_tpo
			  from gn_d_actos_tipo
			 where cdgo_clnte     	= p_cdgo_clnte
			   and cdgo_acto_tpo	= 'EXN';

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_acto_tpo: '|| v_id_acto_tpo, 6);        
		exception
			when no_data_found then 
			o_cdgo_rspsta := 2;
			o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro el tipo de acto';
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
			rollback;
			return;	
		end; -- Fin Se consulta el id del tipo del acto

		-- Generacion del json para el Acto
		begin
			v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto (p_cdgo_clnte				=> p_cdgo_clnte, 	
																  p_cdgo_acto_orgen			=> 'EXN',
																  p_id_orgen				=> p_id_exncion_slctud,
																  p_id_undad_prdctra		=> p_id_exncion_slctud,
																  p_id_acto_tpo				=> v_id_acto_tpo,
																  p_acto_vlor_ttal			=> 0,
																  p_cdgo_cnsctvo			=> 'EXN',
																  p_id_acto_rqrdo_hjo		=> null,
																  p_id_acto_rqrdo_pdre		=> null,
																  p_fcha_incio_ntfccion		=> sysdate,
																  p_id_usrio				=> p_id_usrio,
																  p_slct_sjto_impsto		=> v_slct_sjto_impsto,
																  p_slct_rspnsble			=> v_slct_rspnsble); 

			--pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ac_novedad_persona.prc_gn_acto_novedades_persona',  v_nl, '4 Json: '|| v_json_acto, 6);
			--insert into gti_aux (col1, col2) values ('v_json_acto', v_json_acto);
		exception 
			when others then 
				o_cdgo_rspsta := 3;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el json del acto' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
                return;
		end; -- Fin Generacion del json para el Acto

		-- Generacion del Acto  
		begin
			pkg_gn_generalidades.prc_rg_acto (p_cdgo_clnte		=> p_cdgo_clnte, 
                                              p_json_acto		=> v_json_acto,
											  o_id_acto			=> o_id_acto,
                                              o_cdgo_rspsta		=> o_cdgo_rspsta,
											  o_mnsje_rspsta	=> o_mnsje_rspsta);

			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Generación de Acto. o_cdgo_rspsta: '|| o_cdgo_rspsta || ' o_id_acto: ' || o_id_acto, 6);

			if o_cdgo_rspsta != 0 or o_id_acto < 1 or o_id_acto is null then 
				o_cdgo_rspsta 	:= 4;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el acto' || o_mnsje_rspsta;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
                return;
			end if;

		exception 
			when others then 
				o_cdgo_rspsta := 5;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el acto' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
                return;
		end; -- Fin Generacion del Acto  
		-- FIN GENERACIÓN DEL ACTO

		-- GENERACIÓN DE LA PLANTILLA Y REPORTE
		-- Se consulta el id de la plantilla
		begin 
			select a.id_plntlla
			  into v_id_plntlla
			  from gn_d_plantillas	a
			 where id_plntlla		= p_id_plntlla;
			 pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_id_plntlla: ' || v_id_plntlla, 6);
		exception
			when no_data_found then 
				o_cdgo_rspsta 	:= 6; 
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro la plantilla ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
			when others then 
				o_cdgo_rspsta 	:= 7; 
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la plantilla ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
		end; -- Fin Se consulta el id de la plantilla

		-- Generar el HTML combinado de la plantilla
		begin
			--v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_rnta":"' || p_id_orgen || '", "id_exncion_slctud":"' || p_id_exncion_slctud || '"}', v_id_plntlla);
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '{"id_orgen":"' || v_id_orgen || '", "id_exncion_slctud":"' || p_id_exncion_slctud || '"}' , 6);

			v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_orgen":"' || v_id_orgen || '", "id_exncion_slctud":"' || p_id_exncion_slctud || '"}', v_id_plntlla);

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Genero el html del documento' , 6);
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '' || length(v_dcmnto) , 6);
			insert into gti_aux (col1, col2) values ('v_dcmnto', v_dcmnto); --commit;

			if v_dcmnto is null then 
				o_cdgo_rspsta := 8; 
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se genero el html de la plantilla';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
			end if;

		exception
			when others then 
				o_cdgo_rspsta := 9; 
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el html de la plantilla ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
		end;-- Fin Generar el HTML combinado de la plantilla

		-- Se actualiza el id del acto en la tabla de solicitud de excención
		begin
			update gf_g_exenciones_solicitud
			   set id_acto				= o_id_acto
			 where id_exncion_slctud	= p_id_exncion_slctud;

			 o_mnsje_rspsta	:= 'Actualizo gf_g_exenciones_solicitud: ' || to_char(sql%rowcount);
			 pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);
			 insert into gti_aux (col1, col2) values ('sql%rowcount', o_mnsje_rspsta); --commit;
		exception 
			when others then 
				o_cdgo_rspsta := 10; 
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al actualizar el id del acto en la solicitud de exencion ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
		end; -- Fin Se actualiza el id del acto en la tabla de solicitud de excención

		-- Se Consultan los datos del reporte
		begin
			select b.*
			  into v_gn_d_reportes
			  from gn_d_plantillas	a
			  join gn_d_reportes	b on a.id_rprte = b.id_rprte
			 where a.cdgo_clnte 	= p_cdgo_clnte
			   and a.id_plntlla 	= v_id_plntlla;

			o_mnsje_rspsta := 'Reporte: '|| v_gn_d_reportes.nmbre_cnslta		|| ', '||
											v_gn_d_reportes.nmbre_plntlla		|| ', '||
											v_gn_d_reportes.cdgo_frmto_plntlla	|| ', '||
											v_gn_d_reportes.cdgo_frmto_tpo;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);

		exception
			when no_data_found then
				o_cdgo_rspsta  := 11;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se encontro información del reporte ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
			when others then
				o_cdgo_rspsta := 12;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al consultar la información del reporte ' ||  sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;
		end; -- Fin Consultamos los datos del reporte 

		-- Generación del reporte
		begin 
			-- Si existe la Sesion
			apex_session.attach( p_app_id		=> 66000,
								p_page_id		=> 37,
								p_session_id	=> v('APP_SESSION'));		

			apex_util.set_session_state('P37_JSON', '{"nmbre_rprte":"' 			|| v_gn_d_reportes.nmbre_rprte ||
													 '","id_orgen":"' 			|| v_id_orgen || 
													 '","id_exncion_slctud":"' 	|| p_id_exncion_slctud || 
													 '","id_plntlla":"'			|| p_id_plntlla || '"}');

			apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
			apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creo la sesión' , 6);

			v_blob := apex_util.get_print_document( p_application_id		=> 66000,
													p_report_query_name		=> v_gn_d_reportes.nmbre_cnslta,
													p_report_layout_name	=> v_gn_d_reportes.nmbre_plntlla,
													p_report_layout_type	=> v_gn_d_reportes.cdgo_frmto_plntlla,
													p_document_format		=> v_gn_d_reportes.cdgo_frmto_tpo);
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creo el blob' , 6);	
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Tamaño blob:' ||  length(v_blob), 6);
			--insert into gti_aux (col1, col2, blob) values ('Blob', 'Tamaño: ' || length(v_blob), v_blob ); --commit;			


			if v_blob is null then 
				o_cdgo_rspsta := 13;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se genero el blob de acto ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);  
				rollback;
				return;
			end if;
		exception
			when others then 
				o_cdgo_rspsta := 14;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al generar el blob ' ||  sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);  
				rollback;
				return;
		end;-- Fin Generación del reporte

		-- Actualizar el blob en la tabla de acto
		if v_blob is not null then
		-- Generación blob
			begin
				pkg_gn_generalidades.prc_ac_acto(p_file_blob			=> v_blob,
												 p_id_acto				=> o_id_acto,
												 p_ntfccion_atmtca		=> 'N');
			exception
				when others then
					o_cdgo_rspsta := 15;
					o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error al actualizar el blob ' ||  sqlerrm;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					rollback;
					return;
			end;
		else
			o_cdgo_rspsta := 16;
			o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': No se genero el bolb ' ||  sqlerrm;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
			rollback;
			return;
		end if;-- FIn Actualizar el blob en la tabla de acto


		-- Bifurcacion
		apex_session.attach( p_app_id		=> v_app_id,
							 p_page_id		=> v_app_page_id,
							 p_session_id	=> v('APP_SESSION'));		
		-- FIN GENERACIÓN DE LA PLANTILLA Y REPORTE

		o_cdgo_rspsta 	:= 0;
		o_mnsje_rspsta  := 'Generación del certificado exitoso';

		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,v_nl, 'Saliendo ' || systimestamp, 1);
		exception
			when others then
				o_cdgo_rspsta := 17;
				o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ': Error : ' ||  sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				rollback;
				return;		
	end;
end pkg_gf_exenciones;

/
