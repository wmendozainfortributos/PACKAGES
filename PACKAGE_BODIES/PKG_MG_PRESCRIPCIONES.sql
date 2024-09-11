--------------------------------------------------------
--  DDL for Package Body PKG_MG_PRESCRIPCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_PRESCRIPCIONES" as

/**************************Procedimiento 10 - PRC_MG_GF_G_PRESCRIPCIONES ***************************************/

procedure prc_mg_gf_g_prescripciones(	p_id_entdad			in  number,                                    
										p_id_usrio          in  number,
										p_cdgo_clnte        in  number,
										o_ttal_extsos	    out number,
										o_ttal_error	    out number,
										o_cdgo_rspsta	    out number,
										o_mnsje_rspsta	    out varchar2)as											  

-- cuando vengan incativas y sin respuesta no se migran solo se marcan. y en el in
v_errors            		pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_id_fljo					number(15);
v_id_prscrpcion_tpo			number(15);
v_estdo_instncia			varchar2(15);
v_prscrpcn_inctva			exception;
v_indcdor_incio				varchar2(1);
v_id_usrio_rspsta			varchar2(15);
v_id_estdo_trnscion         number(1);
v_id_instncia_fljo          number(15);
v_id_usrio_autrza_rspsta    number(15);
v_id_prscrpcion             number(15);
v_id_entdad_prsc_sjto_impsto number(4);

begin
v_id_entdad_prsc_sjto_impsto := 2751;
o_ttal_extsos 	:= 0;
o_ttal_error 	:= 0;

	begin
		select 	id_fljo 
		into 	v_id_fljo
		from 	wf_d_flujos
		where 	cdgo_fljo 	= 'PRC'
		and 	cdgo_clnte 	= p_cdgo_clnte;
	exception
		when others then
			o_cdgo_rspsta	:= 10;
			o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_fljo asociado al cdgo_clnte '|| p_cdgo_clnte ||' - '|| SQLERRM; 
			return;
	end;	


  for c_prscrpcn_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --Numero de prescripción								Numerico	Si
                                    a.clmna2						,   --Numero de solicitud de Prescripción (si existe)		Numerico	No
                                    a.clmna3						,   --código de respuesta de la Prescripción (CT - Concedida Totalmente - CP -Concedida Parcialment - RT -Rechazada Totalmente)			Caracter	Si
                                    a.clmna4						,   --Fecha de respuesta									Fecha		Si
                                    a.clmna5						,   --identificación funcionario respuesta					Caracter	No
                                    a.clmna6						,   --identificación funcionario autoriza respuesta			Caracter	No
                                    a.clmna7						,   --Fecha de autorización respuesta						Fecha		No
									a.clmna8						,   --Fecha registro de prescripción  						Fecha		No 
									a.clmna9						,	--prescripcion por solicitud o es masiva	('P','M')	
									a.clmna10							--prescripcion Activa Inactiva	('A','I')	
                            from    migra.mg_g_intermedia_prescripcion   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad
							and     cdgo_estdo_rgstro   =   'L'
                      --      and     rownum < 50
                          )
        loop
			-- Homologacon Tipo de Prescripcion (id_prscrpcion_tpo)
			begin 
				select  a.id_prscrpcion_tpo
				into	v_id_prscrpcion_tpo
				from    gf_d_prescripciones_tipo    a
				where   a.cdgo_clnte    		=   p_cdgo_clnte 
				and    	a.indcdor_msvo_pntual 	= 	c_prscrpcn_mig.clmna9;
        
			exception
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= '  |PRESC_MIG_01-Proceso No. 10 - Codigo:  '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de Rechazo'||c_prscrpcn_mig.clmna9||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
				--Generacion de Flujo de Prescripcion				
				begin
				--	if c_prscrpcn_mig.clmna3 is not null then 
                    if c_prscrpcn_mig.clmna3 in ('CT','RT','CP') then 
						v_estdo_instncia 	:= 'FINALIZADA';
						v_indcdor_incio		:= null;
						v_id_estdo_trnscion := 3;
					elsif (c_prscrpcn_mig.clmna3 = null) and (c_prscrpcn_mig.clmna10 = 'A')then 
						v_estdo_instncia 	:= 'INICIADA';
						v_indcdor_incio		:= 'S';
						v_id_estdo_trnscion := 2;
					else
						raise  v_prscrpcn_inctva;
					end if;

					insert into wf_g_instancias_flujo (	id_fljo    	    , 
														fcha_incio		,
														fcha_fin_plnda  , 
														fcha_fin_optma  ,	
														id_usrio		,
														estdo_instncia  ,
														obsrvcion) 
											values  (	v_id_fljo       ,
														sysdate   		, 
														sysdate         , 
														sysdate         ,
														p_id_usrio		, 
														v_estdo_instncia,
														'Flujo de Migracion de Prescripciones' )
											returning id_instncia_fljo into v_id_instncia_fljo;     											   

				exception
					when v_prscrpcn_inctva then
						o_cdgo_rspsta:= 30;
						o_mnsje_rspsta := ' |PRESC_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' Prescripciones Inactiva por Migracion - '|| SQLERRM;
						update migra.mg_g_intermedia_prescripcion 
						set 	clmna20 			= o_cdgo_rspsta,
								clmna21 			= o_mnsje_rspsta,
								cdgo_estdo_rgstro 	= 'E'
						where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
                    when others then
						o_cdgo_rspsta:= 40;
						o_mnsje_rspsta := ' |PRESC_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la instancia de flujo de Prescripciones por Migracion - '|| SQLERRM; 
						update migra.mg_g_intermedia_prescripcion 
						set 	clmna20 			= o_cdgo_rspsta,
								clmna21 			= o_mnsje_rspsta,
								cdgo_estdo_rgstro 	= 'E'
						where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;					   

			-- insertar transiciones en WF_G_INSTANCIAS_TRANSICION con ambas transiciones transiciones terminadas 	

				for c_fljo_gen_trea in (select 	id_fljo_trea						   
										from 	wf_d_flujos_tarea
										where 	id_fljo 	= v_id_fljo
										and 	indcdor_incio 	= nvl(v_indcdor_incio,indcdor_incio))
				loop
					begin
						 insert into wf_g_instancias_transicion (	id_instncia_fljo		    	, 
																	id_fljo_trea_orgen	  	        ,
																	fcha_incio   		 	        ,
																	fcha_fin_plnda		 	        ,
																	fcha_fin_optma       	        , 
																	fcha_fin_real		  	        , 
																	id_usrio              	        , 
																	id_estdo_trnscion) 
														values (	v_id_instncia_fljo		        , 
																	c_fljo_gen_trea.id_fljo_trea    ,
																	sysdate      			        , 
																	sysdate           		        , 
																	sysdate           		        , 
																	sysdate      			        , 
																	p_id_usrio	     		        ,
																	v_id_estdo_trnscion);

					exception
						when others then
							o_cdgo_rspsta:= 50;
							o_mnsje_rspsta := ' |PRESC_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la transicion de la instancia de flujo de Prescripciones por migracion - v_id_instncia_fljo - '||v_id_instncia_fljo|| ' - id_fljo_trea - '|| c_fljo_gen_trea.id_fljo_trea ||' - SQLERRM - '||SQLERRM; 
							update migra.mg_g_intermedia_prescripcion 
							set 	clmna20 			= o_cdgo_rspsta,
									clmna21 			= o_mnsje_rspsta,
									cdgo_estdo_rgstro 	= 'E'
							where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
                  --  v_id_fljo_trea:= c_fljo_gen_trea.id_fljo_trea;
				end loop;

			--	Buscar Id Ususario que da respuesta a la prescripcion
			begin 
				select id_usrio 
				into   v_id_usrio_rspsta
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_prscrpcn_mig.clmna5;
			exception
				when  no_data_found then
					v_id_usrio_rspsta	:= p_id_usrio;
				--	continue;
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 10- Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario que registra respuesta de la prescripcion'||c_prscrpcn_mig.clmna5||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Buscar Id Ususario que autoriza respuesta a la prescripcion
			begin 
				select id_usrio 
				into   v_id_usrio_autrza_rspsta
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_prscrpcn_mig.clmna6;
			exception
				when  no_data_found then
					v_id_usrio_autrza_rspsta	:= p_id_usrio;
					--continue;
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 10- Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario que registra respuesta de la prescripcion'||c_prscrpcn_mig.clmna6||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			-- Insert en la Tabla Maestro se Prescripcion
			begin	
				insert into gf_g_prescripciones(cdgo_clnte								 	,
												id_prscrpcion_tpo						 	,
												nmro_prscrpcion							 	,
												id_instncia_fljo						 	,
												id_instncia_fljo_pdre					 	,
												id_slctud								 	,
												cdgo_rspsta								 	,
												fcha_rspsta								 	,
												id_usrio_rspsta							 	,
												id_usrio_autrza_rspsta					 	,
												fcha_autrza_rspsta						 	,
												cdgo_csal_anlcion						 	,
												fcha_anlcion							 	,
												obsrvcion_anlcion						 	,
												fcha_rgstro)
										values (p_cdgo_clnte								,					--cdgo_clnte				
												v_id_prscrpcion_tpo							,           	   	--id_prscrpcion_tpo		
												c_prscrpcn_mig.clmna1						,           	    --nmro_prscrpcion			
												v_id_instncia_fljo							,           	    --id_instncia_fljo		
												null										,  					--id_instncia_fljo_pdre	
												null										,  					--id_slctud				
												c_prscrpcn_mig.clmna3						,           	   	--cdgo_rspsta				
												c_prscrpcn_mig.clmna4,           	    --fcha_rspsta
                                                --to_date(c_prscrpcn_mig.clmna4,'DD/MM/YYYY HH:MI:SS'),
												v_id_usrio_rspsta							,           	    --id_usrio_rspsta			
												v_id_usrio_autrza_rspsta					,           	    --id_usrio_autrza_rspsta	
												to_date(c_prscrpcn_mig.clmna7,'DD/MM/YYYY')	,              	   	--fcha_autrza_rspsta
                                                --to_date(c_prscrpcn_mig.clmna7,'DD/MM/YYYY HH:MI:SS'),
												null										,                   --cdgo_csal_anlcion		
												null										,                   --fcha_anlcion			
												null										,	               	--obsrvcion_anlcion		
												to_date(c_prscrpcn_mig.clmna8,'DD/MM/YYYY'))            	   	--fcha_rgstro)
                                                --to_date(c_prscrpcn_mig.clmna4,'DD/MM/YYYY HH:MI:SS'))
										returning id_prscrpcion into v_id_prscrpcion;  
			exception
				when others then
					o_cdgo_rspsta 	:= 70;
					o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 10- Codigo: '||o_cdgo_rspsta|| ' no se Inserto la Prescripcion Migrada en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					continue;	
			end	;							
			if v_id_prscrpcion is not null then
					  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id de la prescripcion de nuestra tabla de gestion en la clmna25.
					update migra.mg_g_intermedia_prescripcion 
					set 	clmna25 			= v_id_prscrpcion, 
							cdgo_estdo_rgstro 	= 'S'
					where 	id_entdad			= p_id_entdad
					and		id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id de la prescripcion de nuestra tabla de gestion en la clmna25.
					update migra.mg_g_intermedia_prescripcion 
					set 	clmna25 			= v_id_prscrpcion
					where 	id_entdad			= v_id_entdad_prsc_sjto_impsto
					and		clmna3				= c_prscrpcn_mig.clmna1;				
			end if;
        commit;
		end loop;




        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        begin
			delete muerto;
            forall i in 1 .. o_ttal_error
			insert into muerto	(
									n_001,					n_002,						c_001
								)
						 values (
									p_id_entdad,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := ' |PRESC_MIG_01-Proceso No. 10- Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.mg_g_intermedia_prescripcion   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_entdad         =   p_id_entdad
			and    a.id_intrmdia        =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 90;
                o_mnsje_rspsta  := ' |PRESC_MIG_01-Proceso No. 10- Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_gf_g_prescripciones;

/**************************Procedimiento 20 - PRC_MG_PRSCRPCNES_SJTO_IMPSTO ***********************************/
procedure prc_mg_prscrpcnes_sjto_impsto(p_id_entdad_prsc_sjto_impsto			in  number,                                    
										p_id_usrio         						in  number,
										p_cdgo_clnte       						in  number,
										o_ttal_extsos	   						out number,
										o_ttal_error	   						out number,
										o_cdgo_rspsta	   						out number,
										o_mnsje_rspsta	   						out varchar2)as											  

-- cuando vengan incativas y sin respuesta no se migran solo se marcan. y en el in
v_errors            		    pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_id_impsto					    number(15);
v_id_impsto_sbmpsto			    number(15);
v_id_sjto_impsto			    number(15);
v_id_prdo					    number(15);
v_id_ajste					    number(15);
v_count_insert                  number(15);
v_id_prscrpcion_sjto_impsto     number(15);
v_id_prscrpcion_vgncia          number(15);


begin
o_ttal_extsos 	:= 0;
o_ttal_error 	:= 0;

 
  for c_prscrpcn_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --cdgo_impuesto										Numerico	Si
                                    a.clmna2						,   --cdgo_subimpuesto									Numerico	Si
                                    a.clmna3						,   --Numero de prescripción							Numerico	Si
									a.clmna4						,   --identificación del contribuyente					Caracter	Si
									a.clmna5						,   --vgencia											Numerico	No
									a.clmna6						,   --periodo											Caracter	Si
									a.clmna7						,   --cdgo_periocidad									Caracter	Si
									a.clmna8						,   --Estado (aceptada = S, no aceptada = 'N')			Caracter	Si 
									a.clmna9						,   --Numero de Nota de Ajuste							Caracter	Si 
									a.clmna25							--id de la Prescripcion en n la tabla de gestion	Numerico	Si				
																--				
                            from    migra.mg_g_intermedia_prescripcion   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_prsc_sjto_impsto
							and 	a.clmna25           is not null
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop
			--Homologacion del Impuesto
			begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = c_prscrpcn_mig.clmna1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM;
						update migra.mg_g_intermedia_prescripcion 
						set 	clmna20 			= o_cdgo_rspsta,
								clmna21 			= o_mnsje_rspsta,
								cdgo_estdo_rgstro 	= 'E'
						where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;		
				end;
			--Homologacion del Impuesto	
			begin 
				select  /*+ RESULT_CACHE */  
						id_impsto_sbmpsto
				into 	v_id_impsto_sbmpsto
				from 	df_i_impuestos_subimpuesto
				where 	id_impsto 				= v_id_impsto 
				and     cdgo_impsto_sbmpsto 	= c_prscrpcn_mig.clmna2;
			exception
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto_sbmpsto asociado al cdgo_impsto_sbmpsto - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
					set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
			end;
			-- Buscar el id Sujeto Impuesto 
                     
			begin
				select 	/*+ RESULT_CACHE */
						id_sjto_impsto
				into 	v_id_sjto_impsto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(idntfccion_sjto 		= c_prscrpcn_mig.clmna4 or idntfccion_antrior = c_prscrpcn_mig.clmna4);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto asociado la identificacion del sujeto '||c_prscrpcn_mig.clmna4||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
            
			-- Homologacion del periodo
			begin				  
				select  /*+ RESULT_CACHE */
						id_prdo
				into 	v_id_prdo
				from 	df_i_periodos
				where  	cdgo_clnte 			= p_cdgo_clnte					
				and 	id_impsto 			= v_id_impsto			
				and 	id_impsto_sbmpsto 	= v_id_impsto_sbmpsto
				and 	vgncia 				= c_prscrpcn_mig.clmna5
				and 	prdo 				= c_prscrpcn_mig.clmna6						
				and     cdgo_prdcdad        = c_prscrpcn_mig.clmna7; 	
			exception
				when others then
					o_cdgo_rspsta:= 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' no se encontro el id_prdo  generado por migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_prscrpcn_mig.clmna5 || ' -  prdo  - '|| c_prscrpcn_mig.clmna8||' -  cdgo_prdcdad  - '|| c_prscrpcn_mig.clmna7|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
			end;  
          
			begin
              
				select 	distinct(a.id_ajste)
				into   	v_id_ajste
				from 	gf_g_ajustes a
              --  join    gf_g_ajuste_detalle  b on a.id_ajste = b.id_ajste
				where	a.cdgo_clnte 			= p_cdgo_clnte
				and 	a.id_impsto 			= v_id_impsto
				and 	a.id_impsto_sbmpsto	    = v_id_impsto_sbmpsto
                and     a.id_sjto_impsto        = v_id_sjto_impsto
				and 	a.numro_ajste 		    = c_prscrpcn_mig.clmna9
                and     a.ind_ajste_prcso       = 'MG';
             --   and     b.vgncia                = c_prscrpcn_mig.clmna5
             --   and     b.id_prdo               = v_id_prdo;
			exception
				when  no_data_found then
					v_id_ajste	:= null;
                when   too_many_rows then 
                	o_cdgo_rspsta:= 45;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' Excepcion Id_Ajuste relacionado con la Prescripcion migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_prscrpcn_mig.clmna5 || ' -  prdo  - '|| v_id_prdo ||' -  v_id_sjto_impsto- '|| v_id_sjto_impsto||' - nuemro del ajuste -'|| c_prscrpcn_mig.clmna9|| SQLERRM;  
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
                when others then
					o_cdgo_rspsta:= 45;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' Excepcion Id_Ajuste relacionado con la Prescripcion migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_prscrpcn_mig.clmna5 || ' -  prdo  - '|| v_id_prdo ||' -  v_id_sjto_impsto- '|| v_id_sjto_impsto||' - nuemro del ajuste -'|| c_prscrpcn_mig.clmna9|| SQLERRM;  
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
			end;	
			/*
			Condicional para hacer el insert
			*/  begin
                    select 	count(*) 
                    into 	v_count_insert
                    from    gf_g_prscrpcnes_sjto_impsto a
                    where   a.id_prscrpcion   =   c_prscrpcn_mig.clmna25 
                    and     a.id_sjto_impsto  =   v_id_sjto_impsto;
                exception
                     when   too_many_rows then 
                	o_cdgo_rspsta:= 47;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' Excepcion Id_Ajuste relacionado con la Prescripcion migracion - v_count_insert- '|| v_count_insert ||'  - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
                when others then
					o_cdgo_rspsta:= 49;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' Excepcion Id_Ajuste relacionado con la Prescripcion migracion - v_count_insert- '|| v_count_insert ||'  - '|| SQLERRM;  
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_prscrpcn_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
                end;
			--	si v_count_insert es mayor que 1 no se hace el insert 
				if v_count_insert < 1 then 


				-- Insert en la Tabla gf_g_prscrpcnes_sjto_impsto Prescripcion
					begin	
						insert into gf_g_prscrpcnes_sjto_impsto(id_prscrpcion				,
																cdgo_clnte					,
																id_impsto					,
																id_impsto_sbmpsto			,
																id_sjto_impsto) 
													values	(	c_prscrpcn_mig.clmna25 		,
																p_cdgo_clnte 				,
																v_id_impsto					,
																v_id_impsto_sbmpsto			,
																v_id_sjto_impsto)				

												returning id_prscrpcion_sjto_impsto into v_id_prscrpcion_sjto_impsto; 
					exception
						when others then
							o_cdgo_rspsta 	:= 70;
							o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 20- Codigo: '||o_cdgo_rspsta|| ' no se Inserto la Prescripcion Migrada en tabla de gestion  - '|| SQLERRM; 
							update migra.mg_g_intermedia_prescripcion
							set 	clmna20 			= o_cdgo_rspsta,
									clmna21 			= o_mnsje_rspsta,
									cdgo_estdo_rgstro 	= 'E'
							where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
							continue;								
					end;	
				end if;		
			begin

				insert into gf_g_prscrpcnes_vgncia (id_prscrpcion_sjto_impsto,
													cdgo_clnte,
													vgncia,
													id_prdo,
													indcdor_aprbdo,
													aplcdo,
													id_ajste)
											values (v_id_prscrpcion_sjto_impsto,
													p_cdgo_clnte,
													c_prscrpcn_mig.clmna5,
													v_id_prdo,
													c_prscrpcn_mig.clmna8,
													c_prscrpcn_mig.clmna8,
													v_id_ajste)
											returning id_prscrpcion_vgncia into v_id_prscrpcion_vgncia; 
			exception
				when others then
					o_cdgo_rspsta 	:= 80;
					o_mnsje_rspsta 	:= ' |PRESC_MIG_01-Proceso No. 20- Codigo: '||o_cdgo_rspsta|| ' no se Inserto la Prescripcion Migrada en tabla de gestion  - id_prscrpcion_sjto_impsto '|| v_id_prscrpcion_sjto_impsto||'- vgncia -'||c_prscrpcn_mig.clmna5||' - id_prdo - '||v_id_prdo||' - id_ajste - '||v_id_ajste||' - aplcdo - '||c_prscrpcn_mig.clmna8||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion
					set 	clmna20 			= o_cdgo_rspsta,
							clmna21 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;
					continue;								
			end;
			if v_id_prscrpcion_vgncia is not null then
					  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id de la prescripcion de nuestra tabla de gestion en la clmna25.
					update migra.mg_g_intermedia_prescripcion 
					set 	cdgo_estdo_rgstro 	= 'S'
					where 	id_entdad			= p_id_entdad_prsc_sjto_impsto
					and		id_intrmdia 		= c_prscrpcn_mig.id_intrmdia;

			end if;
		commit;
		end loop;




        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        begin
			delete muerto;
            forall i in 1 .. o_ttal_error
			insert into muerto	(
									n_001,					n_002,						c_001
								)
						 values (
									p_id_entdad_prsc_sjto_impsto,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 70;
                o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.mg_g_intermedia_prescripcion   a
            set     a.cdgo_estdo_rgstro =  'E'
            where   a.id_entdad         =  p_id_entdad_prsc_sjto_impsto	
			and    a.id_intrmdia        =  v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_prscrpcnes_sjto_impsto;	
 /************************************************************************************************************************/
end pkg_mg_prescripciones;	-- Fin de paquete

/
