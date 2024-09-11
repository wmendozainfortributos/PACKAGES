--------------------------------------------------------
--  DDL for Package Body PKG_SG_SEGURIDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SG_SEGURIDAD" as	

	--SG10
	procedure prc_rg_usrio_sjto_impsto	(
											p_cdgo_clnte			in	number,
											p_id_usrio_slctud   	in	number,
											p_cdgo_rspsta_slctud    in	varchar2,
											p_obsrvcion_rspsta  	in	varchar2,
											p_id_usrio_rspsta   	in	number,
											o_cdgo_rspsta       	out	number,
											o_mnsje_rspsta      	out	varchar2
										) as
		
		v_nl				number;
		v_prcdmnto          varchar2(200) := 'pkg_sg_seguridad.prc_rg_usrio_sjto_impsto';
		v_cdgo_prcso        varchar2(5) := 'SG10';

		v_cdgo_rspsta           varchar2(5);
		v_id_instncia_fljo		number;
		v_id_usrio              number;
		v_id_impsto             number;
		v_id_sjto_impsto        number;
		v_id_usrios_sjto_impsto number;
		v_id_mtvo				number;
	begin
		--Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_prcdmnto);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'Proceso iniciado', 1);
		o_cdgo_rspsta :=	0;

		--Se consulta la solicitud
		begin
			select  a.cdgo_rspsta,
					a.id_instncia_fljo
			into    v_cdgo_rspsta,
					v_id_instncia_fljo
			from    sg_g_usrios_slctud  a
			where   a.id_usrio_slctud   =   p_id_usrio_slctud;
		exception
			when others then
				o_cdgo_rspsta	:= 10;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser consultada, por favor intente nuevamente.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Se valida que no tiene una respuesta
		if (v_cdgo_rspsta is not null) then
			o_cdgo_rspsta	:= 20;
			o_mnsje_rspsta := '<details>' ||  
									'<summary>' || 'La solicitud ya ha sido resuelta.</summary>' ||
									'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
									'<p>' || sqlerrm || '.</p>' ||
									'<p>' || o_mnsje_rspsta || '.</p>' ||
							  '</details>';
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
			return;
		end if;

		--Se actualiza la respuesta de la solicitud
		begin
			update  sg_g_usrios_slctud  a
			set     a.cdgo_rspsta       =   p_cdgo_rspsta_slctud,
					a.obsrvcion_rspsta  =   p_obsrvcion_rspsta,
					a.id_usrio_rspsta   =   p_id_usrio_rspsta,
					a.fcha_rspsta       =   sysdate
			where   a.id_usrio_slctud   =   p_id_usrio_slctud;
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 30;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no ha podido actualizarse, por favor intente nuevamente.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Si la solicitud es aceptada se registra la relacion entre usuarios y sujetos impuestos.
		if (p_cdgo_rspsta_slctud   =   'A') then
			--Se obtiene el usuario, el impuesto y el sujeto impuesto de la solicitud
			begin
				select  b.id_usrio,
						d.id_impsto,
						d.id_sjto_impsto
				into    v_id_usrio,
						v_id_impsto,
						v_id_sjto_impsto
				from    sg_g_usrios_slctud          a
				join    pq_g_solicitudes            b   on  b.id_slctud     =   a.id_slctud
				join    pq_g_solicitudes_motivo     c   on  c.id_slctud     =   b.id_slctud
				join    pq_g_slctdes_mtvo_sjt_impst d   on  d.id_slctud_mtvo=   c.id_slctud_mtvo
				where   a.id_usrio_slctud   =   p_id_usrio_slctud;
			exception
				when others then
					rollback;
					o_cdgo_rspsta	:= 40;
					o_mnsje_rspsta := '<details>' ||  
											'<summary>' || 'La solicitud no pudo ser consultada, por favor intente nuevamente.</summary>' ||
											'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
											'<p>' || sqlerrm || '.</p>' ||
											'<p>' || o_mnsje_rspsta || '.</p>' ||
									  '</details>';
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
					return;
			end;

			--Se valida si existe la relación
			begin
				select  a.id_usrios_sjto_impsto
				into    v_id_usrios_sjto_impsto
				from    sg_g_usrios_sjto_impsto a
				where   a.id_usrio          =   v_id_usrio
				and     a.id_sjto_impsto    =   v_id_sjto_impsto;
			exception
				when no_data_found then
					null;
				when others then
					rollback;
					o_cdgo_rspsta	:= 50;
					o_mnsje_rspsta := '<details>' ||  
											'<summary>' || 'No pudo validarse si la relación ya existe, por favor intente nuevamente.</summary>' ||
											'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
											'<p>' || sqlerrm || '.</p>' ||
											'<p>' || o_mnsje_rspsta || '.</p>' ||
									  '</details>';
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
					return;
			end;


			if (v_id_usrios_sjto_impsto is null) then
				--Se registra la relacion
				begin
					insert into sg_g_usrios_sjto_impsto (
															id_usrio_slctud,
															id_usrio,
															id_impsto,
															id_sjto_impsto,
															id_usrio_rgistra,
															actvo
														)
												values  (
															p_id_usrio_slctud,
															v_id_usrio,
															v_id_impsto,
															v_id_sjto_impsto,
															p_id_usrio_rspsta,
															'S'                                                
														);
				exception
					when others then
						rollback;
						o_cdgo_rspsta	:= 60;
						o_mnsje_rspsta := '<details>' ||  
												'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
												'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
												'<p>' || sqlerrm || '.</p>' ||
												'<p>' || o_mnsje_rspsta || '.</p>' ||
										  '</details>';
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
						return;
				end;
			else
				begin
					update  sg_g_usrios_sjto_impsto a
					set     a.id_usrio_mdfca        =   p_id_usrio_rspsta,
							a.actvo                 =   'S'
					where   a.id_usrios_sjto_impsto =   v_id_usrios_sjto_impsto;
				exception
					when others then
						rollback;
						o_cdgo_rspsta	:= 70;
						o_mnsje_rspsta := '<details>' ||  
												'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
												'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
												'<p>' || sqlerrm || '.</p>' ||
												'<p>' || o_mnsje_rspsta || '.</p>' ||
										  '</details>';
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
						return;
				end;
			end if;
		end if;

		--Se registran las propiedades del flujo

		--Se valida el motivo de la solicitud
		begin
			select  b.id_mtvo
			into    v_id_mtvo
			from    wf_g_instancias_flujo   a
			join	pq_d_motivos            b   on  b.id_fljo   = a.id_fljo
			where   a.id_instncia_fljo  = v_id_instncia_fljo;

			--Se registra la propiedad MTV utilizada por el manejador de PQR
			pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo, 'MTV', v_id_mtvo);
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 80;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Se registra la propiedad de la respuesta de la PQR
		begin
			pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo, 'RSP', p_cdgo_rspsta_slctud);
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 90;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Se registra la propiedad del ultimo usuario del flujo
		begin
			pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo, 'USR', p_id_usrio_slctud);
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 100;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Se registran las propiedades observacion
		begin
			pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo, 'FCH', to_char(systimestamp, 'dd/mm/yyyy hh:mi:ss'));
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 110;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

		--Se registran las propiedades fecha final del flujo
		begin
			pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo, 'OBS', nvl(p_obsrvcion_rspsta, 'Sin observaciones.'));
		exception
			when others then
				rollback;
				o_cdgo_rspsta	:= 120;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'La solicitud no pudo ser gestionada.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
				return;
		end;

	end prc_rg_usrio_sjto_impsto;


	--SG20
	procedure prc_rg_usuario_fnlza_fljo	(
											p_id_instncia_fljo		in	number,
											p_id_fljo_trea			in	number
										)
	as

		v_cdgo_prcso	varchar2(5) := 'SG20';	
		o_cdgo_rspsta	number := 0;
		o_mnsje_rspsta	varchar2(2000);

		v_id_usrio		number;
		v_o_error		varchar2(500);

		v_error			exception;

	begin
		--Se identifica el usuario
		begin
			select  a.id_usrio_rspsta
			into	v_id_usrio
			from    sg_g_usrios_slctud  a
			where   a.id_instncia_fljo  =   p_id_instncia_fljo;
		exception
			when others then
				o_cdgo_rspsta	:= 10;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'No se pudo identificar el usuario que responde la solicitud.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				raise v_error;
		end;

		--Se finaliza el flujo
		begin
			pkg_pl_workflow_1_0.prc_rg_finalizar_instancia	(
																p_id_instncia_fljo => p_id_instncia_fljo,
																p_id_fljo_trea     => p_id_fljo_trea,
																p_id_usrio         => v_id_usrio,
																o_error            => v_o_error,
																o_msg              => o_mnsje_rspsta
															);
			if v_o_error = 'N' then
				o_cdgo_rspsta	:= 20;
				o_mnsje_rspsta := '<details>' ||  
										'<summary>' || 'No se pudo finalizar el flujo de la solicitud.</summary>' ||
										'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
										'<p>' || sqlerrm || '.</p>' ||
										'<p>' || o_mnsje_rspsta || '.</p>' ||
								  '</details>';
				raise v_error;
			end if;
		end;

	exception
		when v_error then
			rollback;
			raise_application_error(-20001, o_mnsje_rspsta);
	end prc_rg_usuario_fnlza_fljo;
    
    -- Funcion para encriptar
	-- v_input lo que se va a encriptar
	-- v_hash_typ tipo de encriptacion 
		-- Ej : 1 si es HASH_MD4
		-- Ej : 4 si es HASH_SH256
    function crypto_hash (v_input 		varchar2
                        , v_hash_typ 	binary_integer) 
                        
    return raw deterministic
    as
       pragma udf;
    begin
		--	v_hash_typ
        --	HASH_MD4   CONSTANT PLS_INTEGER := 1;
        --	HASH_MD5   CONSTANT PLS_INTEGER := 2;
        --	HASH_SH1   CONSTANT PLS_INTEGER := 3;
        --	HASH_SH256 CONSTANT PLS_INTEGER := 4;
        --	HASH_SH384 CONSTANT PLS_INTEGER := 5;
        --	HASH_SH512 CONSTANT PLS_INTEGER := 6;
       return dbms_crypto.hash(utl_raw.cast_to_raw(v_input), v_hash_typ);
	   
	   -- Llamado crypto_hash(V_INPUT => v_input, V_HASH_TYP => 4); HASH_SH256

    end crypto_hash ;

end pkg_sg_seguridad;

/
