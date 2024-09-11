--------------------------------------------------------
--  DDL for Package Body PKG_MG_NOVEDADES_ICA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_NOVEDADES_ICA" as 
/**********************************************************************************************************************/
procedure prc_mg_si_g_novedades_persona(p_id_entdad			in  number,                                    
										p_id_usrio          in  number,
										p_cdgo_clnte        in  number,
										o_ttal_extsos	    out number,
										o_ttal_error	    out number,
										o_cdgo_rspsta	    out number,
										o_mnsje_rspsta	    out varchar2)as											  


v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_id_impsto						number(15);
v_id_impsto_sbmpsto				number(15);
v_id_sjto_impsto				number(15);
v_id_usrio_rgstro				number(15);
v_id_usrio_aplco				number(15);
v_id_usrio_rchzo				number(15);
v_cdgo_nvdad_prsna_estdo        varchar2(3);
v_cdgo_nvdad_tpo				varchar2(3);
v_cdgo_nvdad_tpo_ex         	exception;
v_cdgo_nvdad_prsna_estdo_ex		exception;
v_id_nvdad_prsna				number(15);  

p_id_entdad_adj 				number(15); 
p_id_entdad_h_sjto_impsto		number(15); 
p_id_entdad_si_h_personas		number(15); 
p_id_entd_h_prsn_actvd_ecnmca	number(15);
p_id_entdad_si_h_sujetos		number(15); 
p_id_entdad_sjto_rspnsble_h		number(15);


begin
p_id_entdad_adj 				:= 2904;
p_id_entdad_h_sjto_impsto		:= 2856;
p_id_entdad_si_h_personas		:= 2870;
p_id_entd_h_prsn_actvd_ecnmca	:= 2883;
p_id_entdad_si_h_sujetos		:= 2982;
p_id_entdad_sjto_rspnsble_h		:= 2994;
o_ttal_extsos 					:= 1;
o_ttal_error 					:= 1;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;
				begin 
					select  /*+ RESULT_CACHE */  
                            id_impsto_sbmpsto
					into 	v_id_impsto_sbmpsto
					from 	df_i_impuestos_subimpuesto
					where 	id_impsto 				= v_id_impsto 
                    and     cdgo_impsto_sbmpsto 	= 'ICA' ;--c_ajste_mstro_mgra(i).CLMNA3;
				exception
                	when others then
						o_cdgo_rspsta 	:= 20;
						o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto_sbmpsto asociado al cdgo_impsto_sbmpsto - '|| SQLERRM; 
                        return;
				end;


  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --Identificacion de la novedad										Numerico	Si
                                    a.clmna2						,   --codigo impuesto													Caracter	Si
                                    a.clmna3						,   --codigo subimpuesto												Caracter	Si
                                    a.clmna4						,   --identificacion del sujeto impuesto								Caracter	Si
                                    a.clmna5						,   --observacion 														Caracter	No
                                    a.clmna6						,   --Fecha de registro de la novedad									Fecha		Si
                                    a.clmna7						,   --Identificacion funcionario que registra la novedad				Caracter	No
									a.clmna8						,   --Fecha de aplicación de la novedad									Fecha		No
                                    a.clmna9						,   --Identificacion funcionario que aplica la novedad					Caracter	No
                                    a.clmna10						,   --Tipo de novedad (inscripcion - actualizacion - cancelacion)		Caracter	No
                                    a.clmna11						,   --Estado de la Solicitud(Registrada -Aplicada-Rechazada)			Caracter	Si
                                    a.clmna12						,   --Identificador de que se va o mdifico en la novedad				Caracter	No
									a.clmna13						,   --observacion de rechazo											Caracter	Si
                                    a.clmna14						,   --Fecha rechazo solicitud											Fecha		No
									a.clmna15						,   --identificacion usuario que rechaza 'SI' - 'PR' - 'AC'  - 'RS'     Caracter	No
                                    a.clmna16           	           -- llave primaria de la maestro de novedades

                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop
			-- Buscar el id Sujeto Impuesto 
			begin
				select 	id_sjto_impsto
				into 	v_id_sjto_impsto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(idntfccion_sjto 		= c_nvdds_mig.clmna4 or idntfccion_antrior = c_nvdds_mig.clmna4);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto asociado la identificacion del sujeto '||c_nvdds_mig.clmna4||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Buscar Id Ususario ususario que registra la novedad
			begin 
				select id_usrio 
				into   v_id_usrio_rgstro
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna7;               
			exception
				when  no_data_found then
					v_id_usrio_rgstro	:= p_id_usrio;
			--		continue;
				when others then
					o_cdgo_rspsta 	:= 40;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de registro'||c_nvdds_mig.clmna7||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Buscar Id Ususario ususario que Aplica la novedad
			begin 
				select id_usrio 
				into   v_id_usrio_aplco
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna9;
			exception
				when  no_data_found then
					v_id_usrio_aplco	:= p_id_usrio;
			--		continue;
				when others then
					o_cdgo_rspsta 	:= 50;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de aplicacion'||c_nvdds_mig.clmna7||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Buscar Id Ususario ususario que Rechaza la novedad
			begin 
				select id_usrio 
				into   v_id_usrio_rchzo
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna9;
			exception
				when  no_data_found then
					v_id_usrio_rgstro	:= p_id_usrio;
				--	continue;
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de Rechazo'||c_nvdds_mig.clmna7||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Homologacion del Tipo de Novedad
			  /*  
				'INS', 'Inscripcion'
				'ACT', 'Actualizacion'
				'CNC', 'Cancelacion'
			  */
	/*		begin

				if	c_nvdds_mig.clmna10 = '1' then
					v_cdgo_nvdad_tpo := 'INS';
				elsif	c_nvdds_mig.clmna10 = '2' then 
					v_cdgo_nvdad_tpo := 'ACT';
				elsif	c_nvdds_mig.clmna10 = '3' then 
					v_cdgo_nvdad_tpo := 'CNC';
				else
					raise v_cdgo_nvdad_tpo_ex;  
				end if;				

			exception
				when v_cdgo_nvdad_tpo_ex then
					o_cdgo_rspsta 	:= 70;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro codigo para el tipo de novedad'||c_nvdds_mig.clmna10 ; 
					update migra.mg_g_intermedia_novedades_ica
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			--	Homologacion del Estado de la Novedad
			  /*  
				'RGS', 'Registrada'
				'RCH', 'Rechazada',
				'APL', 'Aplicada',
			  */
	/*		begin 
				if	c_nvdds_mig.clmna11 = '1' then
					v_cdgo_nvdad_prsna_estdo := 'RGS';
				elsif	c_nvdds_mig.clmna11 = '2' then 
					v_cdgo_nvdad_prsna_estdo := 'RCH';
				elsif	c_nvdds_mig.clmna11 = '3' then 
					v_cdgo_nvdad_prsna_estdo := 'APL';
				else
					raise v_cdgo_nvdad_prsna_estdo_ex;  
				end if;				

			exception
				when  no_data_found then
					v_id_usrio_rgstro	:= p_id_usrio;
					continue;
				when v_cdgo_nvdad_prsna_estdo_ex then
					o_cdgo_rspsta 	:= 80;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro codigo para el estado de la novedad'||c_nvdds_mig.clmna11 ; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;*/
			-- 	Insert en la Tabla Maestro de Novedades
			begin	
			insert into si_g_novedades_persona (cdgo_clnte,
												id_impsto,
												id_impsto_sbmpsto,
												id_sjto_impsto,
												obsrvcion,
												id_instncia_fljo,
												id_instncia_fljo_pdre,
												id_slctud,
												fcha_rgstro,
												id_usrio_rgstro,
												fcha_aplco,
												id_usrio_aplco,
												cdgo_nvdad_tpo,
												cdgo_nvdad_prsna_estdo,
												id_fljo_trea,
												fcha_rchzo,
												id_usrio_rchzo,
												obsrvcion_rchzo)
										values (p_cdgo_clnte,                                          				--cdgo_clnte,
												v_id_impsto,                                           				--id_impsto,
												v_id_impsto_sbmpsto,                                   				--id_impsto_sbmpsto,
												v_id_sjto_impsto,                                      				--id_sjto_impsto,
												'MIG - NOVEDAD INDUSTRIA Y COMERCIO - ' || c_nvdds_mig.clmna5,      --obsrvcion,
												null,        	                                     				--id_instncia_fljo,
												null,                                                  				--id_instncia_fljo_pdre,
												null,                                                  				--id_slctud,
											--	to_timestamp(c_nvdds_mig.clmna6,'dd/mm/rr hh12:mi:ssxff am'),       --fcha_rgstro,
												to_date(c_nvdds_mig.clmna6,'DD/MM/YYYY'),
												v_id_usrio_rgstro,                                   				--id_usrio_rgstro,
											--	to_timestamp(c_nvdds_mig.clmna8,'dd/mm/rr hh12:mi:ssxff am'),   	--fcha_aplco,
												to_date(c_nvdds_mig.clmna8,'DD/MM/YYYY'),
												v_id_usrio_aplco,             										--id_usrio_aplco,
												c_nvdds_mig.clmna10,                                      			--cdgo_nvdad_tpo,
												c_nvdds_mig.clmna11,                                 				--cdgo_nvdad_prsna_estdo,
												null,                                                  				--id_fljo_trea,
											--	to_timestamp(c_nvdds_mig.clmna11,'dd/mm/rr hh12:mi:ssxff am'),      --fcha_rchzo,
												to_date(c_nvdds_mig.clmna14,'DD/MM/YYYY'),
												v_id_usrio_rchzo,                                      				--id_usrio_rchzo,
												c_nvdds_mig.clmna13)												--obsrvcion_rchzo)
										returning id_nvdad_prsna into v_id_nvdad_prsna;  
			exception
				when others then
                	insert into muerto	(n_001,c_001)
						 values (
								p_id_entdad,'v_id_impsto - '||v_id_impsto||' - v_id_impsto_sbmpsto - '||v_id_impsto_sbmpsto||' -v_id_sjto_impsto- '||v_id_sjto_impsto||' -to_date(c_nvdds_mig.clmna6- '||to_date(c_nvdds_mig.clmna6,'DD/MM/YYYY')
								||' - v_id_usrio_rgstro - ' ||v_id_usrio_rgstro|| ' -to_date(c_nvdds_mig.clmna8- '||to_date(c_nvdds_mig.clmna8,'DD/MM/YYYY')||' -v_id_usrio_aplco- '||v_id_usrio_aplco||' - c_nvdds_mig.clmna10 -'
                                || c_nvdds_mig.clmna10||' - c_nvdds_mig.clmna11 - '||c_nvdds_mig.clmna11 ||' - to_date(c_nvdds_mig.clmna11 - ' ||to_date(c_nvdds_mig.clmna11,'DD/MM/YYYY'));
					o_cdgo_rspsta 	:= 90;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_nvdad_prsna is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica 
				set 	clmna25 			= v_id_nvdad_prsna, 
						cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
				  -- Actualiza en la entidad Soporte Adjuntos de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica
				set 	clmna25 			= v_id_nvdad_prsna 
				where 	id_entdad			= p_id_entdad_adj
				and		clmna7		 		= c_nvdds_mig.clmna16
                and     clmna9              = c_nvdds_mig.clmna10;
				  -- Actualiza en la entidad Histórico Sujeto Impuesto de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica
				set 	clmna25 			= v_id_nvdad_prsna  
				where 	id_entdad			= p_id_entdad_h_sjto_impsto
				and		clmna13		 		= c_nvdds_mig.clmna16
                and     clmna14             = c_nvdds_mig.clmna10;
				  -- Actualiza en la entidad Histórico Personas de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica 
				set 	clmna25 			= v_id_nvdad_prsna
				where 	id_entdad			= p_id_entdad_si_h_personas
				and		clmna12		 		= c_nvdds_mig.clmna16
                and     clmna13             = c_nvdds_mig.clmna10;
				  -- Actualiza en la entidad Historico actividades economicas de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica
				set 	clmna25 			= v_id_nvdad_prsna
				where 	id_entdad			= p_id_entd_h_prsn_actvd_ecnmca
				and		clmna7		 		= c_nvdds_mig.clmna16
                and     clmna8             = c_nvdds_mig.clmna10;                
				  -- Actualiza en la entidad Historicos si_h_sujetos de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica
				set 	clmna25 			= v_id_nvdad_prsna
				where 	id_entdad			= p_id_entdad_si_h_sujetos
				and		clmna11		 		= c_nvdds_mig.clmna16
                and     clmna12             = c_nvdds_mig.clmna10;  
				  -- Actualiza en la entidad Historicos sjto_rspnsble_h de las Novedades el estado de registro a 'Successful' y  el id novedad persona de nuestra tabla de gestion en la clmna25.
				update migra.mg_g_intermedia_novedades_ica
				set 	clmna25 			= v_id_nvdad_prsna
				where 	id_entdad			= p_id_entdad_sjto_rspnsble_h
				and		clmna21 	 		= c_nvdds_mig.clmna16
                and		clmna22		 		= c_nvdds_mig.clmna10;
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
                o_cdgo_rspsta   := 70;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_g_novedades_persona;
/*****************************************************************************************************************************************************/
procedure prc_mg_si_g_nvdad_prsna_adjnto (	p_id_entdad_adj 	in  number,                                    
											p_id_usrio          in  number, -- usuario migracion
											p_cdgo_clnte        in  number,
											o_ttal_extsos	    out number,
											o_ttal_error	    out number,
											o_cdgo_rspsta	    out number,
											o_mnsje_rspsta	    out varchar2)as											  


v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_user_dgta						number(15);
v_user_mdfca					number(15);
v_id_nvdad_prsna_adjnto			number(15);

begin
o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;


  for c_nvdds_adj_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --File_name													Caracter	Si
                                    a.clmna51						,   --File_blob													blob		Si
									a.clmna2						,   --File_mimetype												Caracter	Si
                                    a.clmna3						,   --Identificación Usuario Digitador							Caracter	Si
                                    a.clmna4						,   --Fecha de registro											Fecha		Si
                                    a.clmna5						,   --Identificación usuario modificación						Caracter	No
                                    a.clmna6						,   --Fecha de modificacion										Fecha		No
                                   	a.clmna7						,   --Identificador de la novedad -- relación tabla maestro     Caracter	Si
                                    a.clmna8                        ,   -- Descripcion tipo de documento
									a.clmna25 							-- v_id_nvdad_prsna (tabla de Gestion)						Numero		Si					
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_adj
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop

			--	Buscar Id Ususario que registra adjunto de la novedad
			begin 
				select id_usrio 
				into   v_user_dgta
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_adj_mig.clmna3;
			exception
				when  no_data_found then
					v_user_dgta	:= p_id_usrio;
			--		continue;
				when others then
					o_cdgo_rspsta 	:= 10;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de registro'||c_nvdds_adj_mig.clmna3||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_adj_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_adj_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			--	Buscar Id Ususario ususario que Modifica adjunto de la novedad
			begin 
				select id_usrio 
				into   v_user_mdfca
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_adj_mig.clmna5;
			exception
				when  no_data_found then
					v_user_mdfca	:= p_id_usrio;
				--	continue;
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de Modificacion'||c_nvdds_adj_mig.clmna5||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_adj_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_adj_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			-- 	Insert en la Tabla si_g_novedades_prsna_adjnto
			begin
				insert into si_g_novedades_prsna_adjnto(id_nvdad_prsna,
														file_blob,
														file_name,
														file_mimetype,
														user_dgta,
														fcha_dgta,
														user_mdfca,
														fcha_mdfca)
												values (c_nvdds_adj_mig.clmna25,                                                       --id_nvdad_prsna,
														c_nvdds_adj_mig.clmna51,                                                       --file_blob,
														c_nvdds_adj_mig.clmna1,                                                        --file_name,
														c_nvdds_adj_mig.clmna2,    													   --file_mimetype,
														v_user_dgta,		                                                           --user_dgta,
														to_date(c_nvdds_adj_mig.clmna4,'DD/MM/YYYY'),								   --fcha_dgta,
														v_user_mdfca,                                                                  --user_mdfca,
													--	to_timestamp(c_nvdds_adj_mig.clmna6,'dd/mm/rr hh12:mi:ssxff am') );                                                                          --fcha_mdfca)
														to_date(c_nvdds_adj_mig.clmna6,'DD/MM/YYYY') )  							   --user_mdfca,
						returning id_nvdad_prsna_adjnto into v_id_nvdad_prsna_adjnto;
			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se inserto el adjunto de la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_adj_mig.id_intrmdia;
					continue;			
			end;

			if v_id_nvdad_prsna_adjnto is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad_adj
				and		id_intrmdia 		= c_nvdds_adj_mig.id_intrmdia;
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
									p_id_entdad_adj,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 70;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad_adj
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_g_nvdad_prsna_adjnto ;
/*****************************************************************************************************************************************************/
procedure prc_mg_si_h_sujetos_impuesto(	p_id_entdad_h_sjto_impsto   		in  number,                                    
										p_id_usrio          				in  number,
										p_cdgo_clnte        				in  number,
										o_ttal_extsos	    				out number,
										o_ttal_error	    				out number,
										o_cdgo_rspsta	    				out number,
										o_mnsje_rspsta	    				out varchar2)as											  

/* insertar para ica: select * from df_i_sujetos_estado (Inactivo - Activo ) */
v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_id_impsto						number(15);
v_id_sjto_estdo                 number(15);
v_id_sjto_impsto				number(15);
v_id_sjto						number(15);
v_id_pais_ntfccion 				number(15);
v_id_dprtmnto 					number(15);
v_id_mncpio						number(15);
v_user_rgstra_nvdad				number(15);
v_id_sjto_impsto_hstrco			number(15);


begin

o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;



  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --identificación del sujeto											Numerico	Si
                                    a.clmna2						,   --codigo impuesto													Caracter	Si
                                    a.clmna3						,   --Estado del Sujeto -- id_sjto_estdo	(Activo- Inactivo)			Caracter	Si
                                    a.clmna4						,   --estado bloqueado													Caracter	Si
                                    a.clmna5						,   --código país notificación											Caracter	No
                                    a.clmna6						,   --código Departamento Notificación									Fecha		Si
                                    a.clmna7						,   --código municipio de notificaron									Caracter	No
									a.clmna8						,   --Dirección Notificacion											Fecha		No
                                    a.clmna9						,   --Email																Caracter	No
                                    a.clmna10						,   --Telefono															Caracter	No
                                    a.clmna11						,   --fecha de registro novedad											Caracter	Si
                                    a.clmna12						,   --usuario q registro la novedad										Caracter	No
									a.clmna13						,   --Identificado de la novedad (Relación con la tabla Maestro)	    Caracter	No
									a.clmna25 							-- v_id_nvdad_prsna (tabla de Gestion)								Numero		Si	
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_h_sjto_impsto
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop
		/*	begin 
				select 	id_impsto
				into 	v_id_impsto
				from 	df_c_impuestos
				where 	cdgo_impsto = c_nvdds_mig.clmna2 --'ICA'--c_ajste_mtvo_mgra.CLMNA1
				and 	cdgo_clnte 	= p_cdgo_clnte ;
			exception
				when others then
					o_cdgo_rspsta := 20;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| c_nvdds_mig.clmna2 ||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26			= o_cdgo_rspsta,
							clmna27			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;*/
            begin 
				select 	id_sjto_estdo
				into 	v_id_sjto_estdo
				from 	df_i_sujetos_estado
				where 	id_impsto = v_id_impsto
				and 	dscrpcion_sjto_estdo 	= c_nvdds_mig.clmna3;
			exception
				when others then
					o_cdgo_rspsta := 20;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_sjto_estdo asociado al dscrpcion_sjto_estdo - '|| c_nvdds_mig.clmna3 ||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26			= o_cdgo_rspsta,
							clmna27			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			-- Buscar el id Sujeto Impuesto y el Sujeto
			begin
				select 	id_sjto_impsto,
						id_sjto
				into 	v_id_sjto_impsto,
						v_id_sjto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(/*idntfccion_sjto 		= c_nvdds_mig.clmna4 or*/ idntfccion_antrior = c_nvdds_mig.clmna1);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto , id_sjto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			-- Pais de Notificacion --
			begin 
				select 	id_pais 
				into 	v_id_pais_ntfccion 
				from 	df_s_paises
				where 	cdgo_pais = c_nvdds_mig.clmna3;			
			exception
                when  no_data_found then
					v_id_pais_ntfccion 	:= null;
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_pais  asociado al cdgo_pais - '||c_nvdds_mig.clmna3||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			-- Departamento de Notificacion --
			begin 
				select 	id_dprtmnto  
				into 	v_id_dprtmnto  
				from 	df_s_departamentos
				where 	cdgo_dprtmnto = c_nvdds_mig.clmna6
				and 	id_pais 	  = v_id_pais_ntfccion; 
			exception
                when  no_data_found then
					v_id_dprtmnto	:= null;
				when others then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_dprtmnto   asociado al cdgo_dprtmnto - '||c_nvdds_mig.clmna6||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

				-- Municipio de Notificacion --
			begin 
				select 	id_mncpio 
				into 	v_id_mncpio  
				from 	df_s_municipios
				where 	cdgo_mncpio  = c_nvdds_mig.clmna7
				and 	id_dprtmnto	 = v_id_dprtmnto;
			exception
              when  no_data_found then
					v_id_mncpio	:= null;
				when others then
					o_cdgo_rspsta := 60;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_mncpio asociado al cdgo_mncpio  - '||c_nvdds_mig.clmna7||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;
			 -- Usuario que registra la Novedad --
			begin 
				select id_usrio 
				into   v_user_rgstra_nvdad
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna12;
			exception
				when  no_data_found then
					v_user_rgstra_nvdad	:= p_id_usrio;
				--	continue;
				when others then
					o_cdgo_rspsta 	:= 70;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario registra la Novedad'||c_nvdds_mig.clmna12||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			-- 	Insert en la Tabla si_h_sujetos_impuesto
			begin	

			insert into si_h_sujetos_impuesto (id_sjto_impsto,					
											   id_sjto,                         
											   id_impsto,                       
											   id_sjto_estdo,					
											   estdo_blqdo,                     
											   id_pais_ntfccion,                
											   id_dprtmnto_ntfccion,            
											   id_mncpio_ntfccion,              
											   drccion_ntfccion,                
											   email,                           
											   tlfno,                           
											   fcha_rgstro,                     
											   usrio_rgstro ,                        
											   id_nvdad)											  
									   values (v_id_sjto_impsto,												--id_sjto_impsto
											   v_id_sjto,                                       				--id_sjto
											   v_id_impsto,                                     				--id_impsto
										       v_id_sjto_estdo,                                 				--id_sjto_estdo
											   c_nvdds_mig.clmna4,                              				--estdo_blqdo
											   v_id_pais_ntfccion,                              				--id_pais_ntfccion
											   v_id_dprtmnto,                                   				--id_dprtmnto_ntfccion
											   v_id_mncpio,                                     				--id_mncpio_ntfccion
											   c_nvdds_mig.clmna8,                              				--drccion_ntfccion
											   c_nvdds_mig.clmna9,                              				--email
											   c_nvdds_mig.clmna10,                             				--tlfno
											   --to_timestamp(c_nvdds_mig.clmna11,'dd/mm/rr hh12:mi:ssxff am'),   --fcha_rgstro
											   to_date(c_nvdds_mig.clmna11,'DD/MM/YYYY'),	
											   v_user_rgstra_nvdad,                                            	--usrio_rgstro
											   c_nvdds_mig.clmna25)                                   			--id_nvdad_prsna		
						returning id_sjto_impsto_hstrco into v_id_sjto_impsto_hstrco;

			exception
				when others then
					o_cdgo_rspsta 	:= 80;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_sjto_impsto_hstrco is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad_h_sjto_impsto
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
			end if;



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
									p_id_entdad_h_sjto_impsto,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 90;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad_h_sjto_impsto
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 100;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_h_sujetos_impuesto;
/*****************************************************************************************************************************************************/
procedure prc_mg_si_h_personas(	p_id_entdad_si_h_personas		in  number,                                    
								p_id_usrio          				in  number,
								p_cdgo_clnte        				in  number,
								o_ttal_extsos	    				out number,
								o_ttal_error	    				out number,
								o_cdgo_rspsta	    				out number,
								o_mnsje_rspsta	    				out varchar2)as											  

/* insertar para ica: select * from df_i_sujetos_estado (Inactivo - Activo ) */
v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();	
v_id_impsto						number(15);
v_id_sjto_impsto				number(15);									  
v_id_prsna						number(15);
v_id_sjto_tpo                   number(15);
v_id_prsna_hstrco				number(15);
v_id_actvdad_ecnmca				number(15);

/*
v_id_sjto_impsto				number(15);
v_id_sjto						number(15);
v_id_pais_ntfccion 				number(15);
v_id_dprtmnto 					number(15);
v_id_mncpio						number(15);
v_user_rgstra_nvdad				number(15);
v_id_sjto_impsto_hstrco			number(15);
*/

begin

o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;



  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --identificación del sujeto											
                                    a.clmna2						,   --código tipo de identificación										
                                    a.clmna3						,   --tipo de sujeto	(S -REGIMEN SIMPLIFICADO- C -REGIMEN COMUN -A-AGENTE RETENEDOR -N-REGIMEN NO DETERMINADO)											Caracter	Si
                                    a.clmna4						,   --tipo de persona   (J o N)
                                    a.clmna5						,   --nombre de la razón social
                                    a.clmna6						,   --numero de registro camara de comercio
                                    a.clmna7						,   --fecha de registro cámara de comercio
									a.clmna8						,   --fecha de inicio actividades
                                    a.clmna9						,   --números de sucursales
                                    a.clmna10						,   --dirección en cámara de comercio
                                    a.clmna11						,   --código actividad económica
                                    a.clmna12						,   --Identificación de la novedad -- relación con la tabla maestro
									a.clmna25 							-- v_id_nvdad_prsna (tabla de Gestion)	
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_si_h_personas
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop

			-- Buscar el id Sujeto Impuesto y el Sujeto
			begin
				select 	id_sjto_impsto
				into 	v_id_sjto_impsto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(idntfccion_sjto 		= c_nvdds_mig.clmna4 or idntfccion_antrior = c_nvdds_mig.clmna1);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto , id_sjto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			-- Buscar el id persona si_i_persona --
			begin
				select 	id_prsna
				into 	v_id_prsna
				from    si_i_personas
				where	id_sjto_impsto			= v_id_sjto_impsto;	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto , id_sjto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			-- Buscar el  id_sjto_tpo --
			begin 
				select 	id_sjto_tpo
				into 	v_id_sjto_tpo 
				from 	df_i_sujetos_tipo
				where 	id_impsto 				= v_id_impsto
				and		cdgo_sjto_tpo 			= decode(c_nvdds_mig.clmna3,null,'N',c_nvdds_mig.clmna3);

			exception
                when no_data_found then
                v_id_sjto_tpo:= 181;
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_sjto_tpo asociado al cdgo_sjto_tpo  - '||c_nvdds_mig.clmna3||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			-- Homologar Actividad Economica  --
			/* 
			Nombre                ¿Nulo?   Tipo           
			--------------------- -------- -------------- 
			ID_ACTVDAD_ECNMCA     NOT NULL NUMBER         
			ID_ACTVDAD_ECNMCA_TPO NOT NULL NUMBER         
			CDGO_ACTVDAD_ECNMCA   NOT NULL VARCHAR2(4)    
			DSCRPCION             NOT NULL VARCHAR2(1000) 
			TRFA                  NOT NULL NUMBER         
			FCHA_DSDE             NOT NULL DATE           
			FCHA_HSTA             NOT NULL DATE           

			*/
			begin 
				select 	id_actvdad_ecnmca
				into 	v_id_actvdad_ecnmca
				from 	gi_d_actividades_economica
				where 	cdgo_actvdad_ecnmca 	= c_nvdds_mig.clmna11;

			exception
              	when  no_data_found then
					v_id_actvdad_ecnmca	:= null;
				when others then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_pais  asociado al cdgo_pais - '||c_nvdds_mig.clmna3||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;
			-- 	Insert en la Tabla si_h_sujetos_impuesto
			begin	

			insert into si_h_personas (id_prsna,
									   id_sjto_impsto,
									   cdgo_idntfccion_tpo,
									   id_sjto_tpo,
									   tpo_prsna,
									   nmbre_rzon_scial,
									   nmro_rgstro_cmra_cmrcio,
									   fcha_rgstro_cmra_cmrcio,
									   fcha_incio_actvddes,
									   nmro_scrsles,
									   drccion_cmra_cmrcio,
									   id_actvdad_ecnmca,
									   id_nvdad_prsna) 
							   values ( v_id_prsna,
										v_id_sjto_impsto,
										c_nvdds_mig.clmna2,
										v_id_sjto_tpo ,
										c_nvdds_mig.clmna4,
										TRIM(c_nvdds_mig.clmna5),
                                        TRIM(c_nvdds_mig.clmna6),
									--	to_timestamp(c_nvdds_mig.clmna7,'dd/mm/rr hh12:mi:ssxff am'),   --fcha_rgstro,
									--	to_timestamp(c_nvdds_mig.clmna8,'dd/mm/rr hh12:mi:ssxff am'),   --fcha_rgstro,
										to_date(c_nvdds_mig.clmna7,'DD/MM/YYYY'),	
										to_date(c_nvdds_mig.clmna8,'DD/MM/YYYY'),	
										c_nvdds_mig.clmna9,
										c_nvdds_mig.clmna10,
										v_id_actvdad_ecnmca,
                                     	c_nvdds_mig.clmna25)	
						returning id_prsna_hstrco into v_id_prsna_hstrco;

			exception
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_prsna_hstrco is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad_si_h_personas
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
			end if;



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
									p_id_entdad_si_h_personas,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 70;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad_si_h_personas
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_h_personas;

/***************************************************************************************************************************************************************************************/
procedure prc_mg_si_h_prsnas_actvdad_ecnmca(p_id_entd_h_prsn_actvd_ecnmca			in  number,                                    
											p_id_usrio          				in  number,
											p_cdgo_clnte        				in  number,
											o_ttal_extsos	    				out number,
											o_ttal_error	    				out number,
											o_cdgo_rspsta	    				out number,
											o_mnsje_rspsta	    				out varchar2)as											  

/* insertar para ica: select * from df_i_sujetos_estado (Inactivo - Activo ) */
v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();	
v_id_impsto						number(15);
v_id_sjto_impsto				number(15);
v_id_actvdad_ecnmca             number(15);
v_id_prsna						number(15);
v_id_prsna_actvdad_ecnmca       number(15);
v_user_dgta						number(15);
v_user_mdfca					number(15);

begin

o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;



  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --identificación del sujeto											
                                    a.clmna2						,   --Código de la actividad CIIU									
                                    a.clmna3						,   --identificación usuario registra											
                                    a.clmna4						,   --fecha de registro
                                    a.clmna5						,   --identificación usuario que modifica
                                    a.clmna6						,   --fecha de modificación
                                    a.clmna7						,   --Identificación de la novedad -- relación tabla maestra
									a.clmna25 							-- v_id_nvdad_prsna (tabla de Gestion)	
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entd_h_prsn_actvd_ecnmca
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop

			-- Buscar el id Sujeto Impuesto y el Sujeto
			begin
				select 	id_sjto_impsto
				into 	v_id_sjto_impsto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(/*idntfccion_sjto 		= c_nvdds_mig.clmna4 or*/ idntfccion_antrior = c_nvdds_mig.clmna1);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			-- Buscar el id persona si_i_persona --
			begin
				select 	id_prsna
				into 	v_id_prsna
				from    si_i_personas
				where	id_sjto_impsto			= v_id_sjto_impsto;	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_prsna asociado la identificacion del sujeto impuesto '||v_id_sjto_impsto||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;

			-- Homologar Actividad Economica  --
			begin 
				select 	max(id_actvdad_ecnmca)
				into 	v_id_actvdad_ecnmca
				from 	gi_d_actividades_economica
				where 	cdgo_actvdad_ecnmca 	= ltrim(c_nvdds_mig.clmna2, '0');

			exception
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_actvdad_ecnmca  asociado al cdgo_actvdad_ecnmca- '||c_nvdds_mig.clmna2||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26			= o_cdgo_rspsta,
							clmna27			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;
					--	Buscar Id Ususario ususario que Modifica adjunto de la novedad
			begin 
				select id_usrio 
				into   v_user_dgta
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna3;
			exception
				when  no_data_found then
					v_user_dgta  := p_id_usrio;
			--		continue;
				when others then
					o_cdgo_rspsta 	:= 50;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario que digita'||c_nvdds_mig.clmna3||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			begin 
				select id_usrio 
				into   v_user_mdfca
				from   v_sg_g_usuarios
				where  cdgo_clnte = p_cdgo_clnte
				and    idntfccion = c_nvdds_mig.clmna5;
			exception
				when  no_data_found then
					v_user_mdfca	:= p_id_usrio;
		--			continue;
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_usrio asociado la identificacion del funcionario de Modificacion'||c_nvdds_mig.clmna5||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26			= o_cdgo_rspsta,
							clmna27			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;


			-- 	Insert en la Tabla si_h_sujetos_impuesto
			begin	

				insert into si_h_prsnas_actvdad_ecnmca ( id_prsna,									 
														 id_actvdad_ecnmca,
														 user_dgta,  
														 fcha_dgta,  
														 user_mdfca, 
														 fcha_mdfca, 
														 id_nvdad_prsna) 
											   values (  v_id_prsna,									 
														 v_id_actvdad_ecnmca,
														 v_user_dgta,  
													--	 to_timestamp(c_nvdds_mig.clmna4,'dd/mm/rr hh12:mi:ssxff am'),
														 to_date(c_nvdds_mig.clmna4,'DD/MM/YYYY'),	
														 v_user_mdfca, 
													--	 to_timestamp(c_nvdds_mig.clmna6,'dd/mm/rr hh12:mi:ssxff am'), 
														 to_date(c_nvdds_mig.clmna6,'DD/MM/YYYY'),				
														 c_nvdds_mig.clmna25) 	
							returning id_prsna_actvdad_ecnmca into v_id_prsna_actvdad_ecnmca;

			exception
				when others then
					o_cdgo_rspsta 	:= 70;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_prsna_actvdad_ecnmca is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entd_h_prsn_actvd_ecnmca
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
			end if;



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
									p_id_entd_h_prsn_actvd_ecnmca,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entd_h_prsn_actvd_ecnmca
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 90;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_h_prsnas_actvdad_ecnmca;
/****************************************************************************************************************************************************************************************/
procedure prc_mg_si_h_sujetos(	p_id_entdad_si_h_sujetos			in  number,                                    
								p_id_usrio          				in  number,
								p_cdgo_clnte        				in  number,
								o_ttal_extsos	    				out number,
								o_ttal_error	    				out number,
								o_cdgo_rspsta	    				out number,
								o_mnsje_rspsta	    				out varchar2)as											  

/* insertar para ica: select * from df_i_sujetos_estado (Inactivo - Activo ) */
v_errors            		pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();	
v_id_impsto                 number(15);
v_id_sjto					number(15);
v_id_sjto_impsto            number(15);
v_id_sjto_hstrco			number(15);
v_idntfccion_sjto			number(15);
v_idntfccion_antrior		number(15);
v_id_pais       			number(15);
v_id_dprtmnto				number(15);
v_id_mncpio					number(15);

begin
o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;



  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --identificación del sujeto											
                                    a.clmna2						,   --codigo del pais del suejeto										
                                    a.clmna3						,   --código del departamento del sujeto		
                                    a.clmna4						,   --codigo del municipio del sujeto												
                                    a.clmna5						,   --dirección del sujeto										
                                    a.clmna6						,   --fecha de ingreso								
                                    a.clmna7						,   --fecha de cancelacion								
									a.clmna8						,   --fecha de ultima novedad											
                                    a.clmna9						,   --código postal															
                                    a.clmna10						,   --estado Bloqueado															
                                    a.clmna11						,   --id de la novedad relacion tabla mestro										
									a.clmna25 							--v_id_nvdad_prsna (tabla de Gestion)								
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_si_h_sujetos
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop

			-- Buscar el id Sujeto Impuesto y el Sujeto
			begin
				select 	id_sjto_impsto,
						id_sjto,
						idntfccion_sjto,
						idntfccion_antrior						
				into 	v_id_sjto_impsto,
						v_id_sjto,
						v_idntfccion_sjto,
						v_idntfccion_antrior						
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(idntfccion_sjto 		= c_nvdds_mig.clmna4 or idntfccion_antrior = c_nvdds_mig.clmna1);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 20;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto , id_sjto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			-- Pais de Notificacion --
			begin 
				select 	id_pais 
				into 	v_id_pais
				from 	df_s_paises
				where 	cdgo_pais = c_nvdds_mig.clmna2;

			exception
				when others then
					o_cdgo_rspsta := 30;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_pais  asociado al cdgo_pais - '||c_nvdds_mig.clmna2||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			-- Departamento de Notificacion --
			begin 
				select 	id_dprtmnto  
				into 	v_id_dprtmnto  
				from 	df_s_departamentos
			---	where 	cdgo_dprtmnto = c_nvdds_mig.clmna3
                where   cdgo_dprtmnto = decode( c_nvdds_mig.clmna3,5,05,8,08,c_nvdds_mig.clmna3)
				and 	id_pais 	  = v_id_pais; 
			exception
               when  no_data_found then
					v_id_dprtmnto 	:= 20;
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_dprtmnto   asociado al cdgo_dprtmnto - '||c_nvdds_mig.clmna3||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

				-- Municipio de Notificacion --
			begin 
				select 	id_mncpio 
				into 	v_id_mncpio  
				from 	df_s_municipios
				where 	cdgo_mncpio  = decode( c_nvdds_mig.clmna3,5,05,8,08,c_nvdds_mig.clmna3)||c_nvdds_mig.clmna4
				and 	id_dprtmnto	 = v_id_dprtmnto;
			exception
            when  no_data_found then
					v_id_mncpio	:= null;

				when others then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_mncpio asociado al cdgo_mncpio  - '||c_nvdds_mig.clmna4||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;


			-- 	Insert en la Tabla si_h_sujetos_impuesto
			begin	

				insert into si_h_sujetos (id_sjto,
										  cdgo_clnte,
										  idntfccion,
										  idntfccion_antrior,
										  id_pais,
										  id_dprtmnto,
										  id_mncpio,
										  drccion,
										  fcha_ingrso,
										  fcha_cnclcion,
										  fcha_ultma_nvdad,
										  cdgo_pstal,
										  estdo_blqdo,
										  id_nvdad) 
								  values (v_id_sjto,
										  p_cdgo_clnte,
										  v_idntfccion_sjto,
										  v_idntfccion_antrior,
										  v_id_pais,
										  v_id_dprtmnto,
										  v_id_mncpio,
										  c_nvdds_mig.clmna5,
										  to_date(c_nvdds_mig.clmna6,'DD/MM/YYYY'),		--v_fcha_ingrso,
										  to_date(c_nvdds_mig.clmna7,'DD/MM/YYYY'),		--v_fcha_cnclcion,
										  to_date(c_nvdds_mig.clmna8,'DD/MM/YYYY'),		--v_fcha_ultma_nvdad,
										  c_nvdds_mig.clmna9,
										  c_nvdds_mig.clmna10,
										  c_nvdds_mig.clmna25)
							returning id_sjto_hstrco into v_id_sjto_hstrco;

			exception
				when others then
					o_cdgo_rspsta 	:= 60;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
                            clmna28             =v_id_mncpio,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_sjto_hstrco is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad_si_h_sujetos
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
			end if;



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
									p_id_entdad_si_h_sujetos,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 70;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad_si_h_sujetos
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 80;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_h_sujetos;
/***********************************************************************************************************************************************************************Aqui**************/
procedure prc_mg_si_i_sujetos_rspnsble_hstrco(	p_id_entdad_sjto_rspnsble_h   		in  number,                                    
												p_id_usrio          				in  number,
												p_cdgo_clnte        				in  number,
												o_ttal_extsos	    				out number,
												o_ttal_error	    				out number,
												o_cdgo_rspsta	    				out number,
												o_mnsje_rspsta	    				out varchar2)as											  

/* insertar para ica: select * from df_i_sujetos_estado (Inactivo - Activo ) */
v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  

v_id_impsto                     number(15);
v_id_impsto_sbmpsto             number(15);
v_id_sjto_impsto				number(15);
v_id_sjto                       number(15);
v_id_sjto_rspnsble_hstrco		number(15);
v_id_prdo						number(15);
v_id_pais_ntfccion				number(15);
v_id_dprtmnto_ntfccion		    number(15);
v_id_mncpio_ntfccion			number(15);


begin

o_ttal_extsos 				:= 0;
o_ttal_error 				:= 0;

/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select 	id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto - '|| SQLERRM; 
				end;
				begin 
					select 	id_impsto_sbmpsto
					into 	v_id_impsto_sbmpsto
					from 	df_i_impuestos_subimpuesto
					where 	cdgo_impsto_sbmpsto 	= 'ICA'--c_ajste_mtvo_mgra.CLMNA1
					and 	id_impsto 				= v_id_impsto
					and 	cdgo_clnte				= p_cdgo_clnte;
				exception
                 	when others then
						o_cdgo_rspsta 	:= 20;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto_sbmpsto asociado al cdgo_impsto_sbmpsto  - '|| SQLERRM; 
                end;


  for c_nvdds_mig in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --identificación del sujeto											
                                    a.clmna2						,   --código tipo de identificación										
                                    a.clmna3						,   --identificación del responsable
                                    a.clmna4						,   --primer nombre
                                    a.clmna5						,   --Segundo Nombre
                                    a.clmna6						,   --primer apellido
                                    a.clmna7						,   --segundo apellido
									a.clmna8						,   --si es responsable principal - 'N' o 'S'
                                    a.clmna9						,   --codigo tipo de responsable  - 'P' o 'R'
                                    a.clmna10						,   --porcentaje de participación
                                    a.clmna11						,   --periodo
                                    a.clmna12						,   --código de periodicidad
									a.clmna13						,   --código de país de notificación
									a.clmna14						,   --código departamento de notificación
                                    a.clmna15						,   --código de municipio de notificacion
                                    a.clmna16						,   --direccion de notificacion
                                    a.clmna17						,   --Email
									a.clmna18						,   --telefono
                                    a.clmna19						,   --celular
                                    a.clmna20						,   --activo
									a.clmna21						,   --identificador de la novedad
									a.clmna25 							-- v_id_nvdad_prsna (tabla de Gestion)								
                            from    migra.mg_g_intermedia_novedades_ica   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad_sjto_rspnsble_h
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop

			-- Buscar el id Sujeto Impuesto y el Sujeto
			begin
				select 	id_sjto_impsto,
						id_sjto
				into 	v_id_sjto_impsto,
						v_id_sjto
				from 	v_si_i_sujetos_impuesto
				where	cdgo_clnte				= p_cdgo_clnte	
				and     id_impsto 				= v_id_impsto
				and		(/*idntfccion_sjto 		= c_nvdds_mig.clmna4 or*/ idntfccion_antrior = c_nvdds_mig.clmna1);	 

			exception
				when others then
					o_cdgo_rspsta 	:= 30;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto , id_sjto asociado la identificacion del sujeto '||c_nvdds_mig.clmna1||' - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica
                    set 	clmna26			= o_cdgo_rspsta,
							clmna27			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;			
			end;
			begin				  
				select  /*+ RESULT_CACHE */
						max(id_prdo)
				into 	v_id_prdo
				from 	df_i_periodos
				where  	cdgo_clnte 			= p_cdgo_clnte					
				and 	id_impsto 			= v_id_impsto			
				and 	id_impsto_sbmpsto 	= v_id_impsto_sbmpsto
			--	and 	vgncia 				= c_nvdds_mig.clmna5
				and 	prdo 				= c_nvdds_mig.clmna11						
				and     cdgo_prdcdad        = c_nvdds_mig.clmna12; 	
			exception
                when  no_data_found then
					v_id_prdo:= null;
				when others then
					o_cdgo_rspsta:= 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' no se encontro el id_prdo del detalle del  Ajuste generado por migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_nvdds_mig.clmna5 || ' -  prdo  - '|| c_nvdds_mig.clmna8||' -  cdgo_prdcdad  - '|| c_nvdds_mig.clmna7|| SQLERRM; 
					update migra.mg_g_intermedia_prescripcion 
                    set 	clmna26			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;	
			end;
			-- Pais de Notificacion --
			begin 
				select 	id_pais 
				into 	v_id_pais_ntfccion 
				from 	df_s_paises
				where 	cdgo_pais = c_nvdds_mig.clmna13;

			exception
                 when  no_data_found then
					v_id_pais_ntfccion := null;
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_pais  asociado al cdgo_pais - '||c_nvdds_mig.clmna13||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			-- Departamento de Notificacion --
			begin 
				select 	id_dprtmnto  
				into 	v_id_dprtmnto_ntfccion  
				from 	df_s_departamentos
				where 	cdgo_dprtmnto = c_nvdds_mig.clmna14
				and 	id_pais 	  = v_id_pais_ntfccion; 
			exception
                  when  no_data_found then
					v_id_dprtmnto_ntfccion := null;
				when others then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_dprtmnto   asociado al cdgo_dprtmnto - '||c_nvdds_mig.clmna14||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

				-- Municipio de Notificacion --
			begin 
				select 	id_mncpio 
				into 	v_id_mncpio_ntfccion  
				from 	df_s_municipios
			--	where 	cdgo_mncpio  = '20'||c_nvdds_mig.clmna15
                where 	cdgo_mncpio  = decode( c_nvdds_mig.clmna14,5,05,8,08,c_nvdds_mig.clmna14)||c_nvdds_mig.clmna15
				and 	id_dprtmnto	 = v_id_dprtmnto_ntfccion;
			exception
                when no_data_found then 
                    v_id_mncpio_ntfccion := null;
				when others then
					o_cdgo_rspsta := 60;
					o_mnsje_rspsta := ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_mncpio asociado al cdgo_mncpio  - '||c_nvdds_mig.clmna15||' - '|| SQLERRM;
					update migra.mg_g_intermedia_novedades_ica 
					set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
					where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_nvdds_mig.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;						
			end;

			begin	

			insert into si_i_sujetos_rspnsble_hstrco (id_sjto_impsto,
													  cdgo_idntfccion_tpo,
													  idntfccion,
													  prmer_nmbre,
													  sgndo_nmbre,
													  prmer_aplldo,
													  sgndo_aplldo,
													  prncpal_s_n,
													  cdgo_tpo_rspnsble,
													  prcntje_prtcpcion,
													  orgen_dcmnto,
													  id_prdo,
													  id_pais_ntfccion,
													  id_dprtmnto_ntfccion,
													  id_mncpio_ntfccion,
													  drccion_ntfccion,
													  email,
													  tlfno,
													  cllar,
													  actvo,
													  id_trcro,
													  id_nvdad)
											  values (v_id_sjto_impsto,
													  c_nvdds_mig.clmna2,
													  c_nvdds_mig.clmna3,
													  c_nvdds_mig.clmna4,
													  c_nvdds_mig.clmna5,
													  c_nvdds_mig.clmna6,
													  c_nvdds_mig.clmna7,
													  c_nvdds_mig.clmna8,
													  'R',
													  c_nvdds_mig.clmna10,
													  '2-MIG', --v_orgen_dcmnto,
													  v_id_prdo,
													  v_id_pais_ntfccion,
													  v_id_dprtmnto_ntfccion,
													  v_id_mncpio_ntfccion,
													  'MIG - '||c_nvdds_mig.clmna16,
													  c_nvdds_mig.clmna17,
													  c_nvdds_mig.clmna18,
													  c_nvdds_mig.clmna19,
													  c_nvdds_mig.clmna20,
													  null,
													  c_nvdds_mig.clmna25)
						returning id_sjto_rspnsble_hstrco into v_id_sjto_rspnsble_hstrco;

			exception
				when others then
					o_cdgo_rspsta 	:= 80;
					o_mnsje_rspsta 	:= ' |NVD_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| ' no se inserto la novedad en tabla de gestion  - '|| SQLERRM; 
					update migra.mg_g_intermedia_novedades_ica 
                    set 	clmna26 			= o_cdgo_rspsta,
							clmna27 			= o_mnsje_rspsta,
							cdgo_estdo_rgstro 	= 'E'
                    where 	id_intrmdia 		= c_nvdds_mig.id_intrmdia;
					continue;			
			end;

			if v_id_sjto_rspnsble_hstrco is not null then
				  -- Actualiza en la entidad maestro el estado de registro a 'Successful' y el id novedad persona de nuestra tabla de gestion en la clmna25.
				update  migra.mg_g_intermedia_novedades_ica 
				set 	cdgo_estdo_rgstro 	= 'S'
				where 	id_entdad			= p_id_entdad_sjto_rspnsble_h
				and		id_intrmdia 		= c_nvdds_mig.id_intrmdia;
			end if;



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
									p_id_entdad_sjto_rspnsble_h,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);

			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 90;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update migra.mg_g_intermedia_novedades_ica  a
            set    a.cdgo_estdo_rgstro =   'E'
            where  a.id_entdad         =   p_id_entdad_sjto_rspnsble_h
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 100;
                o_mnsje_rspsta  := '|NVD_MIG_01-Proceso No. 10 - Código:  ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';	



end  prc_mg_si_i_sujetos_rspnsble_hstrco;
/****************************************************************************************************************************************************************************************/
end;

/
