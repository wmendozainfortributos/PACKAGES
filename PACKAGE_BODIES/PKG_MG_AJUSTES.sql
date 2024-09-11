--------------------------------------------------------
--  DDL for Package Body PKG_MG_AJUSTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_AJUSTES" as

/********************* Procedure No. 10 Registro de Motivos de Ajsute Proveniente de Migracion**************************/
procedure prc_rg_ajustes_motivos_migra (p_cdgo_clnte 				number,
										p_id_entdad_mtvo			number,  --2267
										p_id_ajste_mstro			number,  --2272
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number) as

	v_id_impsto	number;									
	begin

			for c_ajste_mtvo_mgra in (
										select id_intrmdia   ,
										   cdgo_clnte        ,   --cdgo_clnte     
											CLMNA1           ,   --cdgo_impsto    
											CLMNA2           ,   --Mn_o_Atmatco   
											CLMNA3           ,   --crdto_dbto     
											CLMNA4           ,   --dscripcion_mtvo
											CLMNA5               --cdgo_mtvo   
										from 	mg_g_intermedia_ajustes 
										where 	id_entdad 	= p_id_entdad_mtvo
								--		and 	CLMNA5 		in (select distinct(CLMNA10) from mg_g_intermedia_ajustes where id_entdad = p_id_ajste_mstro )
			)
			loop 

				/* Buscar el id_impuesto con codigo del Impuesto migrado */
				begin 
					select distinct(id_impsto) 
					into 	v_id_impsto
					from 	df_c_impuestos
					where 	cdgo_impsto = c_ajste_mtvo_mgra.CLMNA1
					and 	cdgo_clnte 	= p_cdgo_clnte ;
				exception
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |AJT_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'no se encontro id_impsto asociado al cdgo_impsto '||c_ajste_mtvo_mgra.CLMNA1||' - '|| SQLERRM; 
						--v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;	

		        end;
    /*    insert into muerto (C_001) values (v_id_impsto ||' - '|| c_ajste_mtvo_mgra.CLMNA2 ||' - '|| c_ajste_mtvo_mgra.CLMNA3 ||' - '||c_ajste_mtvo_mgra.CLMNA2 ||' - '|| c_ajste_mtvo_mgra.CLMNA5);
        commit;*/
				begin 
					insert into gf_d_ajuste_motivo (	            cdgo_clnte			,
																	id_impsto			,
																	orgen				,
																	tpo_ajste			,
																	dscrpcion			,
																	cdgo_ajste_mtvo)
														values 	 (	p_cdgo_clnte,
																	v_id_impsto					,
																	c_ajste_mtvo_mgra.CLMNA2 	,
																	c_ajste_mtvo_mgra.CLMNA3	,
																	c_ajste_mtvo_mgra.CLMNA4 ||' - Motivo de Nota de Ajuste Migracion.',
																	substr(  replace(replace(replace(replace( c_ajste_mtvo_mgra.CLMNA5, 'NOTA' ,''),'AJUSTE',''),'CREDITO','CR'),'DEBITO','DB'),1,5)
                                                            );
                     	update mg_g_intermedia_ajustes 
                        set cdgo_estdo_rgstro = 'S'
                        where id_intrmdia = c_ajste_mtvo_mgra.id_intrmdia;

				exception
					when others then
                 /*     insert into muerto (C_001) values (v_id_impsto ||' - '|| c_ajste_mtvo_mgra.CLMNA2 ||' - '|| c_ajste_mtvo_mgra.CLMNA3 ||' - '||c_ajste_mtvo_mgra.CLMNA4 ||' - '|| c_ajste_mtvo_mgra.CLMNA5);
                        commit; */
						o_cdgo_rspsta := 20;
						o_mnsje_rspsta := ' |AJT_MIG_01-Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| '- no se inserto el motivo de ajuste '||c_ajste_mtvo_mgra.CLMNA1 ||' - '||c_ajste_mtvo_mgra.CLMNA2 ||' - '||c_ajste_mtvo_mgra.CLMNA3||' - '|| c_ajste_mtvo_mgra.CLMNA5||' - '|| SQLERRM; 
				end;
                commit;
			end loop;

	end;


--end;
/********************* Procedure No. 20 Registro de Ajsute y su DetalleProveniente de Migracion**************************/
procedure prc_rg_ajuste_maestro_migra ( p_cdgo_clnte 				number,
										p_id_entdad_mtvo			number,  --2267
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_entdad_ajste_dtlle		number, 
										p_id_usrio 					number, -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number							
										) as

	type mg_g_intrmdia_ajste_clmnas is record
			(
				cdgo_clnte				MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.cdgo_clnte%TYPE			,
				id_intrmdia   			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.id_intrmdia%TYPE		,
				clmna1 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna1%TYPE				,	--	  id_ajuste_migra          
				clmna2 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna2%TYPE				,  --    cod_impsto               
				clmna3 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna3%TYPE				,  --    cod_subimpsto            
				clmna4 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna4%TYPE				,  --    Manual_o_Automatico      
				clmna5 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna5%TYPE				,  --    identificacion_sjto      
				clmna6 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna6%TYPE				,  --    fcha_resgistro           
				clmna7 		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna7%TYPE				,  --    tipo_ajuste_cr_db        
				clmna8		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna8%TYPE				,  --    observacion              
				clmna9       			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna9%TYPE				,  --    valor_total_ajste        
				clmna10      			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna10%TYPE			,  --    cod_motivo_ajste_migrado 
				clmna11      			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna11%TYPE			,  --    fcha_aplccion            
				clmna12      			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna12%TYPE			,  --    estado_ajuste            
				clmna13      			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna13%TYPE			,  --    numero_solicitud    
				clmna14		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna14%TYPE			,--    numero_ajuste_migrado_consecutivo
				clmna20		 			MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.clmna20%TYPE			,--- ajustes repetidos con id_ajste e iden
				cdgo_estdo_rgstro		MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES.cdgo_estdo_rgstro%TYPE
			);	

	type mg_g_intrmdia_ajste_clmn_inf_t is table of mg_g_intrmdia_ajste_clmnas;
--    type mg_g_intrmdia_ajste_clmn_det_t is table of mg_g_intrmdia_ajste_clmnas;

	c_ajste_mstro_mgra   			mg_g_intrmdia_ajste_clmn_inf_t;
--	c_ajste_dtlle_mgra				mg_g_intrmdia_ajste_clmn_det_t;
	v_id_cnsctvo					number;
    p_numro_ajste_mig               number;
	p_id_cnsctvo_null				exception;	
	p_numro_ajste_migo_null			exception;	
	v_id_impsto						number;	
	v_id_impsto_sbmpsto				number;	
	v_id_sjto_impsto				number;
    v_id_ajste_mtvo                 number;
	v_cdgo_ajste_mtvo				varchar(5);
	v_id_fljo						number;
	v_id_instncia_fljo				number;
	v_id_fljo_trea					number;
	v_mnsje_instncia_fljo 			varchar2(4000);	
	v_id_instncia_fljo_null 		exception;
    v_id_ajste                      number;
    v_id_ajste_null                 exception;
	v_id_prdo						number;
    v_id_cncpto                     number;
    v_ctgria_cncpto                 varchar2(1);
	v_id_mvmnto_dtlle				number;
	v_ttal_ajste_mgrdo				number;

	begin	


                -- Generar instancia del flujo 
				begin
					select 	id_fljo 
					into 	v_id_fljo
					from 	wf_d_flujos
					where 	cdgo_fljo 	= 'AJG'
					and 	cdgo_clnte 	= p_cdgo_clnte;

				exception
                    when  no_data_found then
                        o_cdgo_rspsta	:= 50;
                        o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_fljo asociado al cdgo_clnte '|| p_cdgo_clnte ||' - '|| SQLERRM; 
                        return;
					when others then
                        o_cdgo_rspsta	:= 50;
                        o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_fljo asociado al cdgo_clnte '|| p_cdgo_clnte ||' - '|| SQLERRM; 
                        return;
				end;

			v_ttal_ajste_mgrdo:= 0;
	
			select 	cdgo_clnte	 		,
					id_intrmdia  		,
					clmna1 		 		,	--	  id_ajuste_migra          
					clmna2 		 		,  --    cod_impsto               
					clmna3 		 		,  --    cod_subimpsto            
					clmna4 		 		,  --    Manual_o_Automatico      
					clmna5 		 		,  --    identificacion_sjto      
					clmna6 		 		,  --    fcha_resgistro           
					clmna7 		 		,  --    tipo_ajuste_cr_db        
					clmna8		 		,  --    observacion              
					clmna9       		,  --    valor_total_ajste        
					clmna10      		,  --    cod_motivo_ajste_migrado 
					clmna11      		,  --    fcha_aplccion            
					clmna12      		,  --    estado_ajuste            
					clmna13      		,  --    numero_solicitud    
					clmna14		 		,--    numero_ajuste_migrado_consecutivo	
					clmna20		 		,
					cdgo_estdo_rgstro
			bulk collect into c_ajste_mstro_mgra
			from MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES
			where cdgo_clnte        = p_cdgo_clnte 
			and id_entdad           = p_id_entdad_ajste_mstro
		--	and clmna20	            = '1'
			and cdgo_estdo_rgstro   = 'L';

			for i in 1 ..c_ajste_mstro_mgra.count
			loop    

				-- Buscar el impuesto id_impuesto con codigo del Impuesto migrado 
				begin 
					select 	/*+ RESULT_CACHE */ 
                            id_impsto
					into 	v_id_impsto
					from 	df_c_impuestos
					where cdgo_clnte 		= p_cdgo_clnte 
                    and cdgo_impsto   	    = c_ajste_mstro_mgra(i).CLMNA2;
				exception
                    when  no_data_found then
                        o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto asociado al cdgo_impsto '||c_ajste_mstro_mgra(i).CLMNA2||' - '|| SQLERRM; 
                        update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
					when others then
						o_cdgo_rspsta := 10;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto asociado al cdgo_impsto '||c_ajste_mstro_mgra(i).CLMNA2||' - '|| SQLERRM; 
                         update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;							
						continue;
						--v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;	
				end;
				-- Buscar el subimpuesto (id_impsto_sbmpsto) con codigo del Sub-Impuesto migrado 
				begin 
					select  /*+ RESULT_CACHE */  
                            id_impsto_sbmpsto
					into 	v_id_impsto_sbmpsto
					from 	df_i_impuestos_subimpuesto
					where 	id_impsto 				= v_id_impsto 
                    and     cdgo_impsto_sbmpsto 	= c_ajste_mstro_mgra(i).CLMNA3;
				exception
                    when  no_data_found then
                        o_cdgo_rspsta 	:= 20;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto_sbmpsto asociado al cdgo_impsto_sbmpsto '||c_ajste_mstro_mgra(i).CLMNA3||' - '|| SQLERRM;
                        update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
					when others then
						o_cdgo_rspsta 	:= 20;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_impsto_sbmpsto asociado al cdgo_impsto_sbmpsto '||c_ajste_mstro_mgra(i).CLMNA3||' - '|| SQLERRM; 
                         update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
						--v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;	
				end;
				-- Buscar el sujeto impuesto (id_sjto_impsto) con la identificacion migrada 
				begin
					select 	id_sjto_impsto
					into 	v_id_sjto_impsto
					from 	v_si_i_sujetos_impuesto
					where	cdgo_clnte				= p_cdgo_clnte	
                    and     id_impsto 				= v_id_impsto
					and		((idntfccion_sjto 		= c_ajste_mstro_mgra(i).CLMNA5) or (idntfccion_antrior = c_ajste_mstro_mgra(i).CLMNA5 ));	 

				exception
                    when  no_data_found then
                        o_cdgo_rspsta 	:= 30;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto asociado a la identificacion del sujeto '||c_ajste_mstro_mgra(i).CLMNA5||' - '|| SQLERRM;
                        update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;							
						continue;
					when others then
						o_cdgo_rspsta 	:= 30;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_sjto_impsto asociado la identificacion del sujeto '||c_ajste_mstro_mgra(i).CLMNA5||' - '|| SQLERRM; 
                         update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
						--v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;	
				end;
				-- Buscar el id_ajste_mtvo con el codigo de lmotivo migrado 
				/*  
			Motivos insertados para la migracion de ajustes monteria.
						insert into gf_d_ajuste_motivo (cdgo_clnte			,
											id_impsto			,
											orgen				,
											tpo_ajste			,
											dscrpcion			,
											cdgo_ajste_mtvo)
								values 	 (	23001,
											230011				,
											'A' 	            ,
											'CR'            	,
											'Motivo de Nota de Ajuste Migracion - Credito',
											'APMCR'
									);
                        
						insert into gf_d_ajuste_motivo (cdgo_clnte			,
														id_impsto			,
														orgen				,
														tpo_ajste			,
														dscrpcion			,
														cdgo_ajste_mtvo)
											values 	 (	23001,
														230011				,
														'A' 	            ,
														'DB'            	,
														'Motivo de Nota de Ajuste Migracion - Debito',
														'APMDB'
												); 
			
			*/ 
			-- SE BUSCAN EL ID MOTIVO DE AJUSTE
				if 	trim(c_ajste_mstro_mgra(i).CLMNA7) = 'CR'	then
					v_cdgo_ajste_mtvo := 'APMCR';
				else 
					v_cdgo_ajste_mtvo := 'APMDB';
				end if; 
				begin 
					select 	 /*+ RESULT_CACHE */
                            id_ajste_mtvo 
					into   	v_id_ajste_mtvo 
					from   	gf_d_ajuste_motivo
					where 	cdgo_clnte				= 	p_cdgo_clnte 
			    	and 	id_impsto 				= 	v_id_impsto      -- se encontro motivos de ajuste que vivien con impuesto diferente con el que se definieste motivo
					and 	cdgo_ajste_mtvo 		= 	v_cdgo_ajste_mtvo; --c_ajste_mstro_mgra(i).CLMNA10;
			--		and 	tpo_ajste 				=	c_ajste_mstro_mgra.CLMNA7
			--		and 	orgen					=	c_ajste_mstro_mgra.CLMNA4;
				exception
                 when  no_data_found then
                        o_cdgo_rspsta 	:= 40;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_ajste_mtvo  asociado al cdgo_ajste_mtvo '||c_ajste_mstro_mgra(i).CLMNA10 ||' - impsto -'||v_id_impsto||' - tpo_ajste -'|| c_ajste_mstro_mgra(i).CLMNA7||' - orgen -'|| c_ajste_mstro_mgra(i).CLMNA4||' - '||' - c_ajste_mstro_mgra(i).clmna20 -'||c_ajste_mstro_mgra(i).clmna20||	 SQLERRM;
                        update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
                when others then
						o_cdgo_rspsta 	:= 40;
						o_mnsje_rspsta 	:= ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_ajste_mtvo  asociado al cdgo_ajste_mtvo '||c_ajste_mstro_mgra(i).CLMNA10 ||' - impsto -'||v_id_impsto||' - tpo_ajste -'|| c_ajste_mstro_mgra(i).CLMNA7||' - orgen -'|| c_ajste_mstro_mgra(i).CLMNA4||' - '||' - c_ajste_mstro_mgra(i).clmna20 -'||c_ajste_mstro_mgra(i).clmna20|| SQLERRM; 
                        return;
				end;


				--  Instancia flujo de Ajuste Generado por migracion 
				begin
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
														'FINALIZADA'	,--'INICIADA'		,
														'Flujo de Ajsute Generado por Migracion de Notas de Ajuste'	 )
											returning id_instncia_fljo into v_id_instncia_fljo;     											   

					if v_id_instncia_fljo is null then
						raise v_id_instncia_fljo_null;
					end if;
				exception
					when v_id_instncia_fljo_null then
					o_cdgo_rspsta:= 60;
					o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la instancia de flujo generado de Ajsute por Migracion - '|| SQLERRM;
                     update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;	
                    when others then
					o_cdgo_rspsta:= 70;
					o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la instancia de flujo generado de Ajsute por Migracion - '|| SQLERRM; 
                    update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;						
						continue;
				end;					   

			-- insertar transiciones en WF_G_INSTANCIAS_TRANSICION con ambas transiciones transiciones terminadas 	

				for c_fljo_gen_trea in (select 	id_fljo_trea						   
										from 	wf_d_flujos_tarea
										where 	id_fljo = v_id_fljo)
				loop
					begin
						 insert into wf_g_instancias_transicion (	id_instncia_fljo		    , 
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
																			3);

					exception
						when others then
							o_cdgo_rspsta:= 80;
							o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la transicion de la instancia de flujo generado de Ajsute por migracion - v_id_instncia_fljo - '||v_id_instncia_fljo|| ' - id_fljo_trea - '|| c_fljo_gen_trea.id_fljo_trea ||' - SQLERRM - '||SQLERRM; 
							 update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;							
							continue;
					end;
                    v_id_fljo_trea:= c_fljo_gen_trea.id_fljo_trea;
				end loop;
			/* 
			fcha  			= trunc(to_date(c_ajste_mstro_mgra(i).clmna6,'DD/MM/YYYY'),'YY'),
			fcha_aplccion	= trunc(to_date(c_ajste_mstro_mgra(i).clmna6,'DD/MM/YYYY'),'YY')
			*/
			
				-- Se realiza la insercion del ajuste 
			 begin

					insert into gf_g_ajustes ( 			        cdgo_clnte														,	
																id_impsto														, 
																id_impsto_sbmpsto												, 
																id_sjto_impsto													,
																orgen                                                       	,
                                                                fcha                                                        	, 	
																tpo_ajste														, 
																vlor															,	
																id_ajste_mtvo													,
																obsrvcion														,
																cdgo_ajste_estdo												,
																fcha_aplccion                                               	,
                                                                tpo_dcmnto_sprte												,
																nmro_dcmto_sprte												,												
																fcha_dcmnto_sprte												,
																nmro_slctud														,	
																id_usrio														,	
																id_instncia_fljo												,
																id_fljo_trea													,
																id_instncia_fljo_pdre											, 
																numro_ajste														,	
																ind_ajste_prcso													,
																fcha_pryccion_intrs												,
																id_ajste_mgrdo)	

													values (	p_cdgo_clnte													,
																v_id_impsto														,
																v_id_impsto_sbmpsto												,
																v_id_sjto_impsto												,
																c_ajste_mstro_mgra(i).CLMNA4									,
                                                                trunc(to_date(c_ajste_mstro_mgra(i).clmna6,'DD/MM/YYYY'),'YY')  ,									
																c_ajste_mstro_mgra(i).CLMNA7									,
																to_number(c_ajste_mstro_mgra(i).CLMNA9)							,
																v_id_ajste_mtvo													,  
																c_ajste_mstro_mgra(i).CLMNA8 ||' - Nota de Ajuste Migrado'		,
																c_ajste_mstro_mgra(i).CLMNA12									,
                                                                trunc(to_date(c_ajste_mstro_mgra(i).clmna11,'DD/MM/YYYY'),'YY') ,									
																'Soporte Notas de Ajuste Migracion'								,	
																'10000000001'													,
																sysdate 														,
																c_ajste_mstro_mgra(i).CLMNA13									,	
																p_id_usrio														,	
																v_id_instncia_fljo												,
																v_id_fljo_trea													,  
																null															, 
																nvl(c_ajste_mstro_mgra(i).CLMNA14,c_ajste_mstro_mgra(i).CLMNA1)	,	
																'MG'															,
																null															,
																c_ajste_mstro_mgra(i).CLMNA1)
									returning id_ajste into v_id_ajste;
              	if v_id_ajste is null then
						raise v_id_ajste_null;
					end if;
				exception
                    when v_id_ajste_null then
                        
						o_cdgo_rspsta:= 90;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la insercion del Registro Maestro del Ajuste generado por migracion - '|| c_ajste_mstro_mgra(i).CLMNA1 ||' - v_id_sjto_impsto-'||v_id_sjto_impsto||' -v_id_ajste_mtvo- '||v_id_ajste_mtvo||' - v_id_instncia_fljo-'||v_id_instncia_fljo  ||' - v_id_fljo_trea '||v_id_fljo_trea ||' - - '||	 SQLERRM;
                        update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;							
						continue;
					when others then
						--rollback;
						o_cdgo_rspsta:= 90;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la insercion del Registro Maestro del Ajuste generado por migracion - '|| c_ajste_mstro_mgra(i).CLMNA1 ||' - v_id_sjto_impsto-'||v_id_sjto_impsto||' -v_id_ajste_mtvo- '||v_id_ajste_mtvo||' - v_id_instncia_fljo-'||v_id_instncia_fljo  ||' - v_id_fljo_trea '||v_id_fljo_trea ||' - - '||	 SQLERRM;
                         update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
						set     cdgo_estdo_rgstro   = 'E',
								CLMNA50 = o_mnsje_rspsta
						where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;					
						continue;
				end;					


		
		
            v_ttal_ajste_mgrdo:= v_ttal_ajste_mgrdo + 1;

			update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
			set     cdgo_estdo_rgstro   = 'S'
			where   id_intrmdia         = c_ajste_mstro_mgra(i).id_intrmdia;
--
            update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
			set     clmna31             = v_id_ajste
			where  id_entdad            = p_id_entdad_ajste_dtlle
            and     clmna8	 		    = c_ajste_mstro_mgra(i).clmna1
        	and 	clmna12	 		    = c_ajste_mstro_mgra(i).clmna5;
			--if v_ttal_ajste_mgrdo > 100 then
            commit;
			--	v_ttal_ajste_mgrdo:= 0;

			--end if;
        end loop; -- fin del cursor del llenado del maestro del ajuste



	end; --prc_rg_ajuste_maestro_migra
/********************* Procedure No. 30 Registro de Detalle Ajuste de Migracion**************************/
procedure prc_rg_ajuste_dtlle_migra ( p_cdgo_clnte 				    number,
										p_id_entdad_mtvo			number,  --2267
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_entdad_ajste_dtlle		number, 
										p_id_usrio 					number, -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number							
										) as



    v_id_ajste                      number;
	v_id_prdo						number;
    v_id_cncpto                     number;
    v_ctgria_cncpto                 varchar2(1);
    v_idntfccion_antrior            varchar2(25);
	v_id_mvmnto_dtlle				number;
	v_ttal_ajste_mgrdo				number;

	begin	
        for c_ajste_dtlle_mgra in (
									select  id_intrmdia         ,
                                            clmna1             	,	--vgncia        
										    clmna2             ,    --periodo
                                            clmna3             	,   --cod_concepto      
											clmna4             	,   --saldo_capital 
											clmna5             	,   --valor_ajuste  
											clmna6              ,
											clmna7				,	--capital_o_interes 
											clmna9           	, 	--id_ajuste_migra 
											clmna11      		,	--periocidad
                                            clmna12  			,	--identificacion_sjto
                                            clmna22  			,   --id_prdo
                                            clmna23  			,   --id_cncpto
                                            clmna24  			,  --ctgria_cncpto,
                                            clmna25             ,   --id_impsto       
                                            clmna26             ,   --id_impsto_sbmpsto
                                            clmna28             ,    --id_sjto_impsto
                                            clmna29             ,  --v_id_mvmnto_dtlle
											clmna31               --id_ajste
									from 	MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
									where   cdgo_clnte              = p_cdgo_clnte 
                                    and     id_entdad         		= p_id_entdad_ajste_dtlle								
                                    and 	clmna29					is not null
                                    and     clmna31                 is not null
									and 	cdgo_estdo_rgstro 	    = 'L'
                                   -- and     rownum < 1000
                                    )
		loop

			begin
					insert into gf_g_ajuste_detalle     ( 			id_ajste							,
																	vgncia								, 
																	id_prdo								, 
																	id_cncpto							,												 
																	sldo_cptal							,
																	vlor_ajste							,
																	id_mvmnto_orgn						,
																	vlor_intres							,
																	ajste_dtlle_tpo) 
												values  (          	c_ajste_dtlle_mgra.clmna31		,			--- c_ajste_mstro_mgra(i).id_ajste		,		--v_id_ajste	
																	c_ajste_dtlle_mgra.clmna1		    ,
																	c_ajste_dtlle_mgra.clmna22          ,       --v_id_prdo	    						,
																	c_ajste_dtlle_mgra.clmna23          ,       --v_id_cncpto							,												 
																	c_ajste_dtlle_mgra.clmna4		    ,
																	c_ajste_dtlle_mgra.clmna5 		    ,
																	c_ajste_dtlle_mgra.clmna29          ,       --v_id_mvmnto_dtlle	    				,
																	0			            			,
																	'M') ; 
			exception
				when others then
					rollback;
					o_cdgo_rspsta:= 130;
					o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||' no se puedo insertar el detalle del Ajuste - '|| c_ajste_dtlle_mgra.clmna31		 || ' generado por migracion - '|| SQLERRM; 
					return;	
			end;

			update MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
			set cdgo_estdo_rgstro = 'S'
			where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;

			v_ttal_ajste_mgrdo:= v_ttal_ajste_mgrdo + 1;
			commit;

		end loop; -- fin del cursor del llenado del detalle del ajuste
			--	Actualizar el estdo_instncia a "FINALIZADA" 
	end; --prc_rg_ajuste_maestro_migra	
	
	
/***************************************************************************************************************************************/

/*********************************************  PRC_UP_AJUSTE_MIGRA   ************************************************/
procedure prc_up_ajuste_migra ( p_cdgo_clnte 					number,
                                o_mnsje_rspsta              out varchar2,
								o_cdgo_rspsta				out number	)			
										 as

v_id_impsto             number;
v_id_impsto_sbmpsto     number;
v_id_sjto_impsto        number;
v_id_cncpto             number;  
v_id_prdo               number;
v_ctgria_cncpto         varchar2(1);
count_comiit            number;

begin

 
      
    for c_ajste_mstro_mgra in (select 	cdgo_clnte	 		,
                        id_intrmdia  		,
                        clmna1 		 		,	--	  id_ajuste_migra          
                        clmna2 		 		,  --    cod_impsto               
                        clmna3 		 		,  --    cod_subimpsto            
                        clmna4 		 		,  --    Manual_o_Automatico      
                        clmna5 		 		,  --    identificacion_sjto      
                        clmna6 		 		,  --    fcha_resgistro           
                        clmna7 		 		,  --    tipo_ajuste_cr_db        
                        clmna8		 		,  --    observacion              
                        clmna9       		,  --    valor_total_ajste        
                        clmna10      		,  --    cod_motivo_ajste_migrado 
                        clmna11      		,  --    fcha_aplccion            
                        clmna12      		,  --    estado_ajuste            
                        clmna13      		,  --    numero_solicitud    
                        clmna14		 		,--    numero_ajuste_migrado_consecutivo	
                        clmna20		 		,
                        cdgo_estdo_rgstro
                from MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
                where cdgo_clnte = p_cdgo_clnte
                and id_entdad = 2272
             --   and clmna20	= '1' --18651407
                and cdgo_estdo_rgstro = 'S'
                and CLMNA23 is null
                )
    loop
        begin
          count_comiit:=0;
         
          for c_ajste_dtlle_mgra in (
                                                    select  cdgo_clnte 				,
                                                            id_intrmdia             ,
                                                            clmna1             	    ,	--vgncia        
                                                            case when clmna2 = '0' 
                                                            then '1'
                                                            else clmna2
                                                            end clmna2              ,    --periodo
                                                            clmna3              	,   --cod_concepto      
                                                            clmna4             	    ,   --saldo_capital 
                                                            clmna5             	    ,   --valor_ajuste  
                                                            clmna6                  ,
                                                            clmna7				    ,	--capital_o_interes 
                                                            clmna9           	    , 	--id_ajuste_migra 
                                                            clmna11      		    ,	--periocidad
                                                            clmna12  				--identificacion_sjto
                                                    from 	MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES 
                                                    where   cdgo_clnte            	= p_cdgo_clnte
                                                    and     id_entdad           	= 	2342
                                                    and     CLMNA8	 				= c_ajste_mstro_mgra.clmna1 
                                                    and 	CLMNA12	 				= c_ajste_mstro_mgra.clmna5--v_idntfccion_antrior
                                                    and 	cdgo_estdo_rgstro 	= 'L'
                                                    and     CLMNA20	 	is null
                                                    and     CLMNA23	 	is null
                                                    and     CLMNA24	 	is null
                                                    and     CLMNA22	 	is null
                                                    and     clmna25  	is null
                                                    and     clmna26  	is null
                                                    and     clmna27  	is null
                                                    and     clmna28  	is null
                                                   -- and rownum < 5000)
                                                   )
                        loop
                           begin
                            /*  
							230011	23001	IPU	IMPUESTO PREDIAL UNIFICADO
							230012	23001	ICA	IMPUESTO DE INDUSTRIA Y COMERCIO
							
							*/
                             if   c_ajste_mstro_mgra.clmna2 = 'IPU' then
                                    v_id_impsto             :=  c_ajste_mstro_mgra.cdgo_clnte||1;
                                  v_id_impsto_sbmpsto       :=  c_ajste_mstro_mgra.cdgo_clnte||11;
                             elsif c_ajste_mstro_mgra.clmna2 = 'ICA' then 
                                    v_id_impsto             :=  c_ajste_mstro_mgra.cdgo_clnte||2;
                                  v_id_impsto_sbmpsto       :=  c_ajste_mstro_mgra.cdgo_clnte||22;
                             end if;
                   
                        -- Homologar el Periodo y buscar el id_prdo       ---
        
                            begin				  
                                select  /*+ RESULT_CACHE */
                                        id_prdo
                                into 	v_id_prdo
                                from 	df_i_periodos
                                where  	cdgo_clnte 			= p_cdgo_clnte					
                                and 	id_impsto 			= v_id_impsto			
                                and 	id_impsto_sbmpsto 	= v_id_impsto_sbmpsto
                                and 	vgncia 				= c_ajste_dtlle_mgra.CLMNA1
                                and 	prdo 				= to_number( c_ajste_dtlle_mgra.clmna2)						
                                and     cdgo_prdcdad        = 'ANU';--c_ajste_dtlle_mgra.clmna11;-- se coloco anual por q es migracion de predial 	
                            exception
                                when others then
                              
                                    o_cdgo_rspsta:= 10;
                                 /*   o_mnsje_rspsta:=' v_cdgo_rspsta: '||o_cdgo_rspsta||' - v_id_impsto -' || v_id_impsto || '- v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto || ' - vgncia  -' || c_ajste_dtlle_mgra.CLMNA1 || ' - prdo - ' ||to_number( c_ajste_dtlle_mgra.clmna2)	||
                                                      '-cdgo_prdcdad-' ||c_ajste_dtlle_mgra.CLMNA11 || ' - '||SQLERRM;   */
                                    update MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES  
                                    set clmna20 = '4' ,
                                    clmna21 = ' |AJT_UP_MIG_02-Proceso No. 40 - Codigo: 10  no se encontro id_prdo asociado al  id_entdad   = 	2342  '	||' - c_ajste_dtlle_mgra.id_intrmdia - '|| - c_ajste_dtlle_mgra.id_intrmdia ||' - v_id_impsto -' || v_id_impsto || '- v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto || ' - vgncia  -' || c_ajste_dtlle_mgra.CLMNA1 || ' - prdo - ' ||to_number( c_ajste_dtlle_mgra.clmna2)	||
                                             '-cdgo_prdcdad-' ||c_ajste_dtlle_mgra.CLMNA11 
                                    where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                                    continue;
                            
                            end;
                            
                            begin
                                select 	id_sjto_impsto
                                into 	v_id_sjto_impsto
                                from 	v_si_i_sujetos_impuesto
                                where	cdgo_clnte				= p_cdgo_clnte	
                                and     id_impsto 				= v_id_impsto
                              --  and		idntfccion_antrior      = c_ajste_mstro_mgra.CLMNA5;	 
                                and		((idntfccion_sjto 		= c_ajste_mstro_mgra.CLMNA5) or (idntfccion_antrior = c_ajste_mstro_mgra.CLMNA5 ));
                            exception
                               when others then
                                    o_cdgo_rspsta 	:= 20;
                               --     o_mnsje_rspsta:=' v_cdgo_rspsta: '||o_cdgo_rspsta||' - v_id_impsto -' || v_id_impsto ||  ' - c_ajste_dtlle_mgra.CLMNA5 -' || c_ajste_dtlle_mgra.CLMNA5 ||   ' - '||SQLERRM;   
                                    update MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES  
                                    set clmna20 = '4' ,
                                    clmna21 = ' |AJT_UP_MIG_02-Proceso No. 40 - Codigo: 20 no se encontro id_sjto_impsto asociado al  id_entdad  = 2342  '	||' - v_id_impsto -' || v_id_impsto || '- idntfccion_antrior - '||  c_ajste_mstro_mgra.CLMNA5 
                                    where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                                    continue;
                                 --   return;
                                
                            end;
                          
                        -- Homologar el concepto  y buscar el id_cncpto   ---
                            begin
                                select  /*+ RESULT_CACHE */
                                        id_cncpto,
                                        ctgria_cncpto
                                into 	v_id_cncpto,
                                        v_ctgria_cncpto
                                from 	df_i_conceptos
                                where 	cdgo_clnte       = p_cdgo_clnte	
                                and 	id_impsto        = v_id_impsto
                                and 	cdgo_cncpto      = c_ajste_dtlle_mgra.CLMNA3;
                            exception
                                when others then
                               
                                     o_cdgo_rspsta:= 30;
                                    update MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES  
                                    set clmna20 = '4' ,
                                    clmna21 = ' |AJT_UP_MIG_02-Proceso No. 40 - Codigo: 30 no se encontro id_cncpto,  ctgria_cncpto asociado al  id_entdad  = 2342  '	||' - v_id_impsto -' || v_id_impsto || '- cdgo_cncpto  - '||  c_ajste_dtlle_mgra.CLMNA3
                                    where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                                    continue;
                               --      o_mnsje_rspsta:=   ' v_cdgo_rspsta: '||o_cdgo_rspsta||' - v_id_impsto -' || v_id_impsto ||  ' - c_ajste_dtlle_mgra.CLMNA5 -' || c_ajste_dtlle_mgra.CLMNA5 ||   ' - '||SQLERRM;   
                               --     return;	
                            end;
                    
                            update  MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES  
                            set     CLMNA20	 	= 	1		,
                                    CLMNA23	 	= 	v_id_cncpto			,
									CLMNA24	 	= 	v_ctgria_cncpto		,
									CLMNA22	 	= 	v_id_prdo		    ,
									clmna25  	= 	v_id_impsto			, 
									clmna26  	= 	v_id_impsto_sbmpsto	,
									clmna27  	= 	v_id_impsto_sbmpsto	,
									clmna28  	= 	v_id_sjto_impsto
                            where 	id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                  
                       end;
                          count_comiit:= count_comiit+1;
                        commit;
                    end loop;
       
    end;
    end loop; 
end;
 /********************* Procedure No. 50 actualizacion movimineto detalle*************************/
procedure prc_up_ajuste_migra_mvmto_dtalle ( p_cdgo_clnte 				number,
                                             o_mnsje_rspsta         out varchar2,
                                             o_cdgo_rspsta			out number	)
                                             as
v_id_mvmnto_dtlle           number;

begin

          for c_ajste_dtlle_mgra in (
                                                    select  cdgo_clnte              ,
                                                            id_intrmdia             ,
                                                            clmna1             	    ,	--vgncia        
                                                            clmna2                  ,    --periodo
                                                            clmna3              	,   --cod_concepto      
                                                            clmna4             	    ,   --saldo_capital 
                                                            clmna5             	    ,   --valor_ajuste  
                                                            clmna6                  ,
                                                            clmna7				    ,	--capital_o_interes 
                                                            clmna9           	    , 	--id_ajuste_migra 
                                                            clmna11      		    ,	--periocidad
                                                            clmna12  				,   --identificacion_sjto
                                                            clmna22 				,
                                                            clmna23 				,
                                                            clmna24 				,
                                                            clmna25 				,
                                                            clmna26  				,
                                                            clmna28  				
                                                    from 	MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES   
                                                    where   cdgo_clnte            = p_cdgo_clnte
                                                    and     id_entdad             = 	2342
                                                    and     clmna20               = 1
                                              --    and     CLMNA9	 		      = c_ajste_mstro_mgra.clmna1 
                                              --    and 	CLMNA12	 		      = c_ajste_mstro_mgra.clmna5--v_idntfccion_antrior
                                                    and 	cdgo_estdo_rgstro 	= 'L'
                                                    and     clmna29 is null
                                                  --  and     rownum < 10000
                                                    )
            loop
            -- En busca el movimiento financiero origen 
			  		begin
					

                               select a.id_mvmnto_dtlle 
                                 into v_id_mvmnto_dtlle
                                 from gf_g_movimientos_detalle  a
                                 join gf_g_movimientos_financiero b   on a.id_mvmnto_fncro = b.id_mvmnto_fncro
                                 join df_i_impuestos_acto_concepto c  on a.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
                                where b.cdgo_clnte        = p_cdgo_clnte
                                  and b.id_impsto         = c_ajste_dtlle_mgra.clmna25  --v_id_impsto
                                  and b.id_impsto_sbmpsto = c_ajste_dtlle_mgra.clmna26  --v_id_impsto_sbmpsto
                                  and b.id_sjto_impsto    = c_ajste_dtlle_mgra.clmna28  --v_id_sjto_impsto
                                  and b.vgncia            = c_ajste_dtlle_mgra.clmna1 
                                  and b.id_prdo           = c_ajste_dtlle_mgra.clmna22                                
                              --    and decode( c_ajste_dtlle_mgra.clmna24 , 'C' , a.id_cncpto , 'I' , c.id_cncpto_intres_mra ) = c_ajste_dtlle_mgra.clmna23  -- v_id_cncpto
                                   and ((c_ajste_dtlle_mgra.clmna24 = 'C' and a.id_cncpto = c_ajste_dtlle_mgra.clmna23 )or((c_ajste_dtlle_mgra.clmna24 = 'I' and c.id_cncpto_intres_mra  = c_ajste_dtlle_mgra.clmna23)))
                                  
                                  and a.cdgo_mvmnto_tpo  = 'IN' 
                                  and a.cdgo_mvmnto_orgn in ( 'LQ' , 'DL' ); 

					exception
							when others then
								update MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES   
                                set  cdgo_estdo_rgstro 	= 'E'
                                    ,clmna20 = '2' 
                                    ,clmna21 = ' |AJT_MIG_02-Proceso No. 20 - Codigo:  no se encontro id_mvmnto_dtlle asociado al  Ajuste  migracion - id_impsto '|| c_ajste_dtlle_mgra.clmna25 || ' - id_impsto_sbmpsto - ' || c_ajste_dtlle_mgra.clmna26 ||' - id_sjto_impsto '|| 
                                    c_ajste_dtlle_mgra.clmna28  ||' - vgncia - '||c_ajste_dtlle_mgra.CLMNA1||' - id_prdo - '||c_ajste_dtlle_mgra.clmna22||' - v_id_cncpto - '||c_ajste_dtlle_mgra.clmna23||' - vlor_sldo_cptal - '||c_ajste_dtlle_mgra.clmna4 ||' - v_ctgria_cncpto - '|| c_ajste_dtlle_mgra.clmna24 ||' - SQLERRM '
                                where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                                continue;
									
					end;
                    
                      update   MIGRA.MG_G_INTERMEDIA_IPU_AJUSTES   
                      set   clmna29   =  v_id_mvmnto_dtlle
                      where id_intrmdia = c_ajste_dtlle_mgra.id_intrmdia;
                     commit;               
                end loop;    

end;                                           
/**************************************Proceso 600***************************************************/

procedure prc_up_fcha_ajste_mstr_mgra ( p_cdgo_clnte 				number,
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_usrio 					number, -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number							
										) as

	type mg_g_intrmdia_ajste_clmnas is record
			(
				cdgo_clnte				mg_g_intermedia_ajustes.cdgo_clnte%TYPE			,
				id_intrmdia   			mg_g_intermedia_ajustes.id_intrmdia%TYPE		,
				clmna1 		 			mg_g_intermedia_ajustes.clmna1%TYPE				,	--	  id_ajuste_migra          
				clmna2	 		 		mg_g_intermedia_ajustes.clmna1%TYPE,  --    cod_impsto      
				clmna5 		 			mg_g_intermedia_ajustes.clmna5%TYPE				,  --    identificacion_sjto      
				clmna6 		 			mg_g_intermedia_ajustes.clmna6%TYPE				,  --    fcha_resgistro           
				clmna14		 			mg_g_intermedia_ajustes.clmna14%TYPE			,--    numero_ajuste_migrado_consecutivo
				clmna20		 			mg_g_intermedia_ajustes.clmna20%TYPE			,--- ajustes repetidos con id_ajste e iden
				cdgo_estdo_rgstro		mg_g_intermedia_ajustes.cdgo_estdo_rgstro%TYPE
			);	

	type mg_g_intrmdia_ajste_clmn_inf_t is table of mg_g_intrmdia_ajste_clmnas;
--    type mg_g_intrmdia_ajste_clmn_det_t is table of mg_g_intrmdia_ajste_clmnas;

	c_ajste_mstro_mgra   			mg_g_intrmdia_ajste_clmn_inf_t;
--	c_ajste_dtlle_mgra				mg_g_intrmdia_ajste_clmn_det_t;
	v_id_cnsctvo					number;
    p_numro_ajste_mig               number;
	p_id_cnsctvo_null				exception;	
	p_numro_ajste_migo_null			exception;	
	v_id_impsto						number;	
	v_id_impsto_sbmpsto				number;	
	v_id_sjto_impsto				number;
    v_id_ajste_mtvo                 number;
	v_id_fljo						number;
	v_id_instncia_fljo				number;
	v_id_fljo_trea					number;
	v_mnsje_instncia_fljo 			varchar2(4000);	
	v_id_instncia_fljo_null 		exception;
    v_id_ajste                      number;
    v_id_ajste_null                 exception;
	v_id_prdo						number;
    v_id_cncpto                     number;
    v_ctgria_cncpto                 varchar2(1);
	v_id_mvmnto_dtlle				number;
	v_ttal_ajste_mgrdo				number;

	begin	


			v_ttal_ajste_mgrdo:= 0;
	
			select 	cdgo_clnte	 		,
					id_intrmdia  		,
					clmna1 		 		,
					clmna2				,		--	  id_ajuste_migra          
					clmna5 		 		,  --    identificacion_sjto      
					clmna6 		 		,  --    fcha_resgistro           
					clmna14		 		,--    numero_ajuste_migrado_consecutivo	
					clmna20		 		,
					cdgo_estdo_rgstro
			bulk collect into c_ajste_mstro_mgra
			from mg_g_intermedia_ajustes
			where cdgo_clnte        = p_cdgo_clnte 
			and id_entdad           = p_id_entdad_ajste_mstro
			and clmna20	            = '1'
			and cdgo_estdo_rgstro   = 'S';

			for i in 1 .. c_ajste_mstro_mgra.count
			loop    
			
			    if   c_ajste_mstro_mgra(i).clmna2 = 'IPU' then
                                    v_id_impsto             :=  c_ajste_mstro_mgra(i).cdgo_clnte||1;
                                  v_id_impsto_sbmpsto       :=  c_ajste_mstro_mgra(i).cdgo_clnte||11;
				elsif c_ajste_mstro_mgra(i).clmna2 = 'ICA' then 
									v_id_impsto             :=  c_ajste_mstro_mgra(i).cdgo_clnte||2;
									v_id_impsto_sbmpsto     :=  c_ajste_mstro_mgra(i).cdgo_clnte||22;
				end if;
			begin
                                select 	id_sjto_impsto
                                into 	v_id_sjto_impsto
                                from 	v_si_i_sujetos_impuesto
                                where	cdgo_clnte				= p_cdgo_clnte	
                                and     id_impsto 				= v_id_impsto
                                and		idntfccion_antrior      = c_ajste_mstro_mgra(i).CLMNA5;	 

                            exception
                               when others then
							   rollback;
                                   o_cdgo_rspsta 	:= 20;
                                   o_mnsje_rspsta:=' v_cdgo_rspsta: '||o_cdgo_rspsta||' - v_id_impsto -' || v_id_impsto ||  ' - c_ajste_dtlle_mgra.CLMNA5 -' || c_ajste_mstro_mgra(i).CLMNA5 ||   ' - '||SQLERRM;   
                                
                                 --   continue;
                                   return;
                                
                            end;
				-- Se realiza la insercion del ajuste 
			begin
						update  gf_g_ajustes
						set    	fcha  			= trunc(to_date(c_ajste_mstro_mgra(i).clmna6,'DD/MM/YYYY'),'YY'),
								fcha_aplccion	= trunc(to_date(c_ajste_mstro_mgra(i).clmna6,'DD/MM/YYYY'),'YY')
						where   id_sjto_impsto	= v_id_sjto_impsto	
                        and     ind_ajste_prcso = 'MG'
						and 	id_ajste_mgrdo  = c_ajste_mstro_mgra(i).clmna1;
					
					
				
				exception
                /*    when v_id_ajste_null then
                        rollback;
						o_cdgo_rspsta:= 90;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizo la insercion del Registro Maestro del Ajuste generado por migracion - '|| c_ajste_mstro_mgra(i).CLMNA1 ||' - v_id_sjto_impsto-'||v_id_sjto_impsto||' -v_id_ajste_mtvo- '||v_id_ajste_mtvo||' - v_id_instncia_fljo-'||v_id_instncia_fljo  ||' - v_id_fljo_trea '||v_id_fljo_trea ||' - - '||	 SQLERRM;
                      return;	*/  
					when others then
						rollback;
						o_cdgo_rspsta:= 90;
						o_mnsje_rspsta := ' |AJT_MIG_02-Proceso No. 60 - Codigo: '||o_cdgo_rspsta|| ' no se realizo update del Registro Maestro del Ajuste generado por migracion - '|| c_ajste_mstro_mgra(i).CLMNA1 ||' - v_id_sjto_impsto-'||v_id_sjto_impsto||' -v_id_ajste_mtvo- '||v_id_ajste_mtvo||' - v_id_instncia_fljo-'||v_id_instncia_fljo  ||' - v_id_fljo_trea '||v_id_fljo_trea ||' - - '||	 SQLERRM;
                        return;	
				end;					
	
            commit;
			
        end loop; -- fin del cursor del llenado del maestro del ajuste



	end; --prc_up_fcha_ajste_mstr_mgra

end pkg_mg_ajustes;

/
