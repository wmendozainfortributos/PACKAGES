--------------------------------------------------------
--  DDL for Package Body PKG_MC_MEDIDAS_CAUTELARES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MC_MEDIDAS_CAUTELARES" as 

    -- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento que determina el tipo de procesamiento que se le -- !! --
    -- !! -- dara al lote de desembargo que se envia a procesar             -- !! --
    -- !! -- ************************************************************** -- !! --
    procedure pr_ca_prcsmnto_lte_dsmbrgo (p_cdgo_clnte          in number
                                        , p_csles_dsmbargo      in varchar2 -- **
                                        , p_dsmbrgo_tpo         in varchar2 -- **
                                        , p_json                in clob
                                        , p_id_usrio            in number
                                        , p_app_ssion           in  varchar2 default null
                                        , o_id_mdda_ctlar_lte   out number
                                        , o_nmro_mdda_ctlar_lte out number
                                        , o_cdgo_rspsta         out number
                                        , o_mnsje_rspsta        out varchar2) as

    v_nl                    	number;
	v_nmbre_up              	varchar2(70)    := 'pkg_mc_medidas_cautelares.prc_ca_prcsmnto_lte_dsmbrgo';
    v_nmro_rslcion_mxmo_sncrno  number          := 10;
	v_nmro_rgstro_prcsar		number			:= 0;
	v_id_fncnrio				number;
	v_nmro_job					number;			-- Determina el numero de job a crear
    v_hora_job                  number;         -- Determina la hora en que va a correr el job 

    begin 

        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);

		--insert into muerto(v_001, v_002, n_001, c_001) values('val_des_mas_valled_prc', 'v_id_lte_mdda_ctlar = '||v_id_lte_mdda_ctlar, 1, null, systimestamp); commit;

        o_mnsje_rspsta  := 'p_cdgo_clnte: '         || p_cdgo_clnte
                        || ' p_csles_dsmbargo: '    || p_csles_dsmbargo
                        || ' p_dsmbrgo_tpo: '       || p_dsmbrgo_tpo
                        --|| ' p_json: '              || p_json
                        || ' p_id_usrio: '          || p_id_usrio
                        || ' p_app_ssion: '         || p_app_ssion;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);

        -- Consultar el numero máximo de resoluciones de embargos a desembargar de menera sincrona
		-- y el numero de Jobs a crear
		begin
            select nmro_rslcion_mxmo_sncrno, nmro_job, hora_job
			  into v_nmro_rslcion_mxmo_sncrno, v_nmro_job, v_hora_job
              from mc_d_configuraciones_gnral
			 where cdgo_clnte                   = p_cdgo_clnte;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'v_nmro_rslcion_mxmo_sncrno '|| v_nmro_rslcion_mxmo_sncrno, 6);
		exception
			when no_data_found then
				o_cdgo_rspsta   := 10;
				o_mnsje_rspsta  := '|MCT_PRCSMNTO_DSMBRGO CDGO: '|| o_cdgo_rspsta || 'No se encontro ningun valor parametrizado para el numero maximo de procesamiento.';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				return;	
			when others then
				o_cdgo_rspsta   := 20;
				o_mnsje_rspsta  := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta || 'Problema al consultar numero maximo de procesamiento.' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				return;				
		end;-- Fin Consultar el numero máximo de resoluciones de embargos a desembargar de menera sincrona

	    -- Se calcular el número de registros del Json
		begin 
			select count(a.id_embrgos_rslcion)
			  into v_nmro_rgstro_prcsar
			  from json_table( p_json  ,'$[*]'
					 columns ( id_embrgos_rslcion number path '$.ID_ER')) a; 

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'Número de registros del Json: ' || v_nmro_rgstro_prcsar, 6);				
		exception
			when others then
				o_cdgo_rspsta := 50;
				o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' ||o_cdgo_rspsta|| 'Error al calcualar el numero de registros ene le json: ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
				return;		                                       
		end; -- Fin Se calcular el número de registros del Json


		-- Si el número de registros a desembargar es menor o igual al numero máximo de registros 
		-- a desembargar sincronicamente se genera el proceso de manera inmediata
		if (v_nmro_rgstro_prcsar <= v_nmro_rslcion_mxmo_sncrno) then
			begin	
				pkg_mc_medidas_cautelares.prc_rg_desembargo_masivo (p_cdgo_clnte        	=> p_cdgo_clnte
																  , p_id_usrio        		=> p_id_usrio
																  , p_json     				=> p_json
																  , p_nmro_rgstro_prcsar	=> v_nmro_rgstro_prcsar
																  , p_app_ssion         	=> p_app_ssion
																  , p_dsmbrgo_tpo       	=> p_dsmbrgo_tpo 
																  , p_indcdor_prcsmnto		=> 'ULTMO' 
																  , o_id_mdda_ctlar_lte 	=> o_id_mdda_ctlar_lte
																  , o_nmro_mdda_ctlar_lte	=> o_nmro_mdda_ctlar_lte
																  , o_cdgo_rspsta       	=> o_cdgo_rspsta
																  , o_mnsje_rspsta      	=> o_mnsje_rspsta);

				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
			exception
				when others then
					o_cdgo_rspsta	:= 60;
					o_mnsje_rspsta	:= '|MCT_PRCSMNTO_DSMBRGO CDGO: '|| o_cdgo_rspsta|| 'Problema al iniciar el desembargo masivo.'|| sqlerrm;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
					return;
			end;
		-- Si el número de registros a desembargar es mayoral numero máximo de registros 
		-- a desembargar sincronicamente se generan los job para ejecutarlos en BATCH
		else
		-- Se registra el lote de medidas cautelares (desmebargo) que quedara pendiente por ejecutar
			--Se consulta el id del funcionario
			begin
				select id_fncnrio
				  into v_id_fncnrio
				  from v_sg_g_usuarios
				 where id_usrio				=259949; -- p_id_usrio;

				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_fncnrio: ' || v_id_fncnrio, 6);   
			exception
				when no_data_found then 
					o_cdgo_rspsta  := 70;
					o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta|| ': No se encontraron datos del funcionario.';
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);   
					return;
				when others then
					o_cdgo_rspsta  := 80;
					o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta|| ': Error al consultar el funcionario.' || sqlerrm;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);   
					return;
			end;--Fin Se consulta el id del funcionario

			-- Se regista el lote de la medida cautelar
			begin
				o_nmro_mdda_ctlar_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');

				begin
                insert into mc_g_lotes_mdda_ctlar( cdgo_clnte,		nmro_cnsctvo,			fcha_lte,	
												   tpo_lte,	        id_fncnrio,         	dsmbrgo_tpo,
												   json,			nmro_rgstro_prcsar,		cdgo_estdo_lte)
										   values( p_cdgo_clnte,	o_nmro_mdda_ctlar_lte,	sysdate, 	
												  'D',		        v_id_fncnrio,       	p_dsmbrgo_tpo,
												  p_json,			v_nmro_rgstro_prcsar,	'PEJ')
										 returning id_lte_mdda_ctlar into o_id_mdda_ctlar_lte;
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 85;
                        o_mnsje_rspsta := 'Error al intentar crear lote de desemmbargo. '||sqlerrm;
                        return;
                end;
				o_mnsje_rspsta	:= 'v_nmro_rgstro_prcsar: ' || v_nmro_rgstro_prcsar || ' o_id_mdda_ctlar_lte: ' || o_id_mdda_ctlar_lte;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);   
			exception
				when others then
				o_cdgo_rspsta  := 90;
				o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta|| ': Error al registrar el lote de la medida cautelar. ' || sqlerrm; 
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
				rollback;
				return;
			end;-- Fin Se registra el lote de medida cautelar de desembargo 

			-- Se generan los jobs
			begin 
				pkg_mc_medidas_cautelares.prc_gn_jobs_desembargos (p_cdgo_clnte         	=> p_cdgo_clnte
																 , p_id_mdda_ctlar_lte		=> o_id_mdda_ctlar_lte
																 , p_id_usrio				=> p_id_usrio
																 , p_nmro_jobs				=> v_nmro_job
																 , p_hora_job				=> v_hora_job
                                                                 , p_app_ssion              => p_app_ssion
																 , o_cdgo_rspsta        	=> o_cdgo_rspsta
																 , o_mnsje_rspsta       	=> o_mnsje_rspsta);

				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
			exception
				when others then 
					o_cdgo_rspsta  := 100;
					o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta|| ': Error al generar los jobs. ' || sqlerrm; 
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
					return;
			end; -- Fin Se generan los jobs 	
		end if; 

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo ' || systimestamp, 1);
    exception
        when others then 
            o_cdgo_rspsta   := 99;
            o_mnsje_rspsta  := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta || 'Error: ' || sqlerrm;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
			rollback;
			return;
    end;


	-- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento para generar los jobs de desembargos masivos		-- !! --
    -- !! -- ************************************************************** -- !! --
	procedure prc_gn_jobs_desembargos (p_cdgo_clnte         	in number
									 , p_id_mdda_ctlar_lte		in number
									 , p_id_usrio				in number
									 , p_nmro_jobs				in number	default 1
									 , p_hora_job				in number
									 , p_app_ssion				in varchar2
                                     , o_cdgo_rspsta        	out number
                                     , o_mnsje_rspsta       	out varchar2) as
	v_nl                    	number;
	v_nmbre_up              	varchar2(70)    := 'pkg_mc_medidas_cautelares.prc_gn_jobs_desembargos';
	v_mnsje_rspsta				varchar2(70)	:= '|MCT_PRCSMNTO_DSMBRGO CDGO: ';
	t_mc_g_lotes_mdda_ctlar		mc_g_lotes_mdda_ctlar%rowtype;

    v_nmro_rgstro_x_job			number	:= 0;
    v_nmro_rgstro_ttal			number	:= 0;
    v_incio						number	:= 1;
    v_fin						number	:= 0;
    v_json_job          		clob;
	v_nmbre_job					varchar2(70);
	v_indcdor_prcsmnto			varchar2(10);
	v_id_mdda_ctlar_lte			number;
	v_nmro_mdda_ctlar_lte		number;
	v_id_dsmbrgo_dtlle_lte		number;
    v_fch_prgrmda_job           timestamp;

    begin 
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);

		-- Se consulta la información del lote de medidas cautelar (desembargo)
		begin 
			select *
			  into t_mc_g_lotes_mdda_ctlar
			  from mc_g_lotes_mdda_ctlar
			 where id_lte_mdda_ctlar		= p_id_mdda_ctlar_lte;
		exception
			when no_data_found then 
				o_cdgo_rspsta   := 10;
				o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' No se encontro el lote de medida cautelar (desmebargo): ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
			when others then 
				o_cdgo_rspsta   := 20;
				o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' Error al consultar el lote de medidas cautelar (desembargo): ' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
		end;-- Fin Se consulta la información del lote de medidas cautelar (desembargo)

		for i in 1..p_nmro_jobs loop
			if i = p_nmro_jobs then
				v_nmro_rgstro_x_job	:= t_mc_g_lotes_mdda_ctlar.nmro_rgstro_prcsar - v_nmro_rgstro_ttal;
				v_indcdor_prcsmnto	:= 'ULTMO';
			else
				if i = 1 then 
					v_indcdor_prcsmnto	:= 'PRMRO';
				end if;
				v_nmro_rgstro_x_job	:= round(t_mc_g_lotes_mdda_ctlar.nmro_rgstro_prcsar / p_nmro_jobs); 
				v_nmro_rgstro_ttal	:=  v_nmro_rgstro_ttal + v_nmro_rgstro_x_job;
			end if;

			v_fin	:= v_incio + v_nmro_rgstro_x_job - 1;

			-- Se Divide el json 
			begin
				select json_arrayagg( json_object( 'ID_ER' value id_embrgos_rslcion
												 , 'ID_EC' value id_embrgos_crtra
												 , 'ID_TE' value id_tpos_embrgo
												 , 'ID_CC' value cdgo_clnte
												 , 'CD_TD' value cdgo_csal
												 , 'ID_IF' value id_instncia_fljo
												 , 'ID_IT' value id_fljo_trea) returning clob ) json
				  into v_json_job
				  from (select *
						from ( select rownum nmro_rgstro
									, id_embrgos_rslcion 
									, id_embrgos_crtra 
									, id_tpos_embrgo 
									, cdgo_clnte 
									, cdgo_csal 
									, id_instncia_fljo 
									, id_fljo_trea
								 from json_table(t_mc_g_lotes_mdda_ctlar.json  ,'$[*]' columns (id_embrgos_rslcion		number		path '$.ID_ER'
																							  , id_embrgos_crtra		number		path '$.ID_EC'
																							  , id_tpos_embrgo			number		path '$.ID_TE'
																							  , cdgo_clnte				number		path '$.ID_CC'
																							  , cdgo_csal				varchar2	path '$.CD_TD'
																							  , id_instncia_fljo		number		path '$.ID_IF'
																							  , id_fljo_trea			number	    path '$.ID_IT'
																								)
												) a
							  )
					   where nmro_rgstro between v_incio and v_fin
					   );
			exception
				when others then 
					o_cdgo_rspsta   := 30;
					o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' Error al dividir el json: ' || sqlerrm;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					return;
			end;-- Fin Se Divide el json 


			o_mnsje_rspsta	:= 'v_nmro_rgstro_x_job: ' 	|| v_nmro_rgstro_x_job
							|| ' v_nmro_rgstro_ttal: ' 	|| v_nmro_rgstro_ttal
							|| ' v_incio: ' 			|| v_incio
							|| ' v_fin: ' 				|| v_fin;
						--	|| ' v_json_job: ' 			|| v_json_job;

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);


            -- Se crea el Job 
            begin 
                v_nmbre_job := 'IT_MC_DSMBRGO_LTE_' || p_id_mdda_ctlar_lte || '_' || to_char(systimestamp, 'DDMMYYYHHMI') || '_'|| v_incio || '_' || v_fin ;

                v_fch_prgrmda_job := trunc(sysdate)+p_hora_job/24;

                o_mnsje_rspsta	:= 'v_nmbre_job: ' 	|| v_nmbre_job ;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);

                --Se guarda el detalle de los registros a procesar por el job
                begin
                    insert into mc_g_desembargos_dtlle_lte( cdgo_clnte,			 id_lte_mdda_ctlar,		json_lte,	
                                                            incio_json,	      	 fin_json,         		nmro_rgstro_prcsar,
                                                            fcha_incio,			 cdgo_estdo_lte,        nmbre_job,
                                                            fcha_prgrmda_job)
                                                    values( p_cdgo_clnte,		 p_id_mdda_ctlar_lte,	v_json_job, 	
                                                            v_incio,		     v_fin,       			v_nmro_rgstro_x_job,
                                                            sysdate,			 'PEJ',                 v_nmbre_job,
                                                            v_fch_prgrmda_job)

                                                    returning id_dsmbrgo_dtlle_lte into v_id_dsmbrgo_dtlle_lte;

                        o_mnsje_rspsta	:= 'Se insertaron ' || sql%rowcount || ' registros en mc_g_desembargos_dtlle_lte. '||v_id_dsmbrgo_dtlle_lte;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);			
                exception
                    when others then
                    o_cdgo_rspsta  := 40;
                    o_mnsje_rspsta := '|MCT_PRCSMNTO_DSMBRGO CDGO: ' || o_cdgo_rspsta|| ': Error al registrar el detalle del lote de la medida cautelar. ' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
                    return;		
                end;	
                --Fin Se guarda el detalle de los registros a procesar por el job


                dbms_scheduler.create_job ( job_name            => v_nmbre_job
                                          , job_type            => 'STORED_PROCEDURE' 
										  , job_action          => 'PKG_MC_MEDIDAS_CAUTELARES.PRC_RG_DESEMBARGO_MASIVO'
                                          , number_of_arguments => 13
                                          , start_date          => null
                                          , repeat_interval     => null
                                          , end_date            => null
                                          , enabled             => false
                                          , auto_drop           => true
                                          , comments            => v_nmbre_job);

				-- Se le asigan al job los parametros para ejecutarse
				-- IN 
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 1, argument_value => p_cdgo_clnte);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 2, argument_value => p_id_mdda_ctlar_lte);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 3, argument_value => p_id_usrio);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 4, argument_value => v_json_job);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 5, argument_value => t_mc_g_lotes_mdda_ctlar.nmro_rgstro_prcsar);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 6, argument_value => null);  --p_app_ssion);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 7, argument_value => t_mc_g_lotes_mdda_ctlar.dsmbrgo_tpo);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 8, argument_value => v_indcdor_prcsmnto);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 9, argument_value => v_id_dsmbrgo_dtlle_lte);

				-- OUT
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 10, argument_value => v_id_mdda_ctlar_lte);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 11, argument_value => v_nmro_mdda_ctlar_lte);
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 12, argument_value => o_cdgo_rspsta);  
				dbms_scheduler.set_job_argument_value ( job_name => v_nmbre_job, argument_position => 13, argument_value => o_mnsje_rspsta);

				--Se le asigan al job la hora de inicio de ejecución
				--dbms_scheduler.set_attribute( name => v_nmbre_job, attribute => 'start_date', value => current_timestamp + interval '30' second );
				dbms_scheduler.set_attribute( name => v_nmbre_job, attribute => 'start_date', value => v_fch_prgrmda_job  + interval '30' second );

				-- Se habilita el job
				dbms_scheduler.enable(name => v_nmbre_job);
			exception
				when others then 
					o_cdgo_rspsta   := 50;
					o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					return;

			end;-- Fin se crea el Job 
	 		o_mnsje_rspsta	:= 'Termina v_nmbre_job: ' 	|| v_nmbre_job || to_char(systimestamp, 'DDMMYYYHHMI') || '_'|| v_incio || '_' || v_fin ;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);

			v_incio	:= v_fin + 1;
		end loop;

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo ' || systimestamp, 1);
	exception
        when others then 
            o_cdgo_rspsta   := 99;
            o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || 'Error: ' || sqlerrm;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
			rollback;
			return;
	end; 


	-- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento para desembargar de manera masivas				-- !! --
    -- !! -- ************************************************************** -- !! --
	procedure prc_rg_desembargo_masivo (p_cdgo_clnte        	in number
									  , p_id_mdda_ctlar_lte		in number	default null 
									  , p_id_usrio        		in sg_g_usuarios.id_usrio%type
									  , p_json     				in clob
									  , p_nmro_rgstro_prcsar	in number
                                      , p_app_ssion         	in varchar2 default null
                                      , p_dsmbrgo_tpo       	in varchar2 
									  , p_indcdor_prcsmnto		in varchar2
									  , p_id_dsmbrgo_dtlle_lte  in number	default null 
									  , o_id_mdda_ctlar_lte 	out number
									  , o_nmro_mdda_ctlar_lte	out number
									  , o_cdgo_rspsta       	out number
									  , o_mnsje_rspsta      	out varchar2 ) is
	v_nl                    	number;
	v_nmbre_up              	varchar2(70)    := 'pkg_mc_medidas_cautelares.prc_rg_desembargo_masivo';
	v_mnsje_rspsta				varchar2(70)   := '|MCT_DSMBRGO_MSVO ';

	v_id_fncnrio				number;
    v_nmbre_trcro               varchar2(1000);
	v_id_estdos_crtra			number;
	v_id_fljo_trea				number;
	v_id_mdda_ctlar_lte			number;

	v_count						number			:= 0;
	v_id_dsmbrgos_rslcion		number;
	v_cdgo_acto_tpo_rslcion		gn_d_plantillas.id_acto_tpo%type;
	v_cdgo_cnsctvo				df_c_consecutivos.cdgo_cnsctvo%type;
	v_id_plntlla_rslcion		mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
	v_id_rprte					gn_d_reportes.id_rprte%type; 

	v_id_acto					mc_g_solicitudes_y_oficios.id_acto_slctud%type;
	v_fcha						gn_g_actos.fcha%type;
	v_nmro_acto					gn_g_actos.nmro_acto%type;

	v_dcmnto_html				clob;		
	v_app_session				varchar2(50);


	begin 
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, '00 entrando Alcaba',  v_nl, 'se va a iniciar prc_rg_desembargo_masivo '|| systimestamp, 6);

		o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := 'p_cdgo_clnte - '        || p_cdgo_clnte
                        || 'p_id_mdda_ctlar_lte - ' || p_id_mdda_ctlar_lte
                        || 'p_id_usrio - '        	|| p_id_usrio
                        || 'p_app_ssion - '        	|| p_app_ssion
                        || 'p_dsmbrgo_tpo - '       || p_dsmbrgo_tpo;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);

	--Se consulta el id del funcionario
		begin
			select   id_fncnrio
                    ,nmbre_trcro             
            into     v_id_fncnrio
                    ,v_nmbre_trcro 
			from    v_sg_g_usuarios
			where   id_usrio				= p_id_usrio;

			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '01 Id funcionario firma: ' || v_id_fncnrio ||' - '||v_nmbre_trcro, 6);   

		exception
			when no_data_found then
				o_cdgo_rspsta  := 40;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se encontraron datos del usuario.';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);   
				return;
			when others then 
				o_cdgo_rspsta  := 50;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al consultar los datos del usuario.' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);   
				return;
		end;--Fin Se consulta el id del funcionario

		if p_app_ssion is null then


			begin
				-- Este procedimiento es llamado desde un job 
				apex_session.create_session (
										p_app_id => 66000,
										p_page_id => 2,
										p_username => '1111111112'/*'1111111111'*/ );

                apex_util.set_session_state('F_FRMTO_MNDA', 'FM$999G999G999G999G999G999G990');
                apex_util.set_session_state('F_NMBRE_USRIO', v_nmbre_trcro);
				v_app_session := v('APP_SESSION');

			exception 	
				when others then
				o_cdgo_rspsta  := 10;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al crear la sesscion.' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, to_char(sqlerrm) , 1);
				return; 
			end;

		else
			-- Este procedimiento es llamado desde APEX
			v_app_session := p_app_ssion;

		end if;

    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '02 Nombre Tercero: ' || v_id_fncnrio ||' - '||v_nmbre_trcro, 6);   

		begin 
			select b.id_estdos_crtra
				 , b.id_fljo_trea
			  into v_id_estdos_crtra
				 , v_id_fljo_trea
			  from mc_d_estados_cartera		b
			 where b.cdgo_estdos_crtra		= 'D'
			   and b.cdgo_clnte				= p_cdgo_clnte;

			o_mnsje_rspsta	:= '03 v_id_estdos_crtra: ' || v_id_estdos_crtra || ' v_id_fljo_trea: ' || v_id_fljo_trea;
            
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);   
		exception 
			when no_data_found then
				o_cdgo_rspsta  := 20;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se encontraron los datos del estado de la cartera.' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, to_char(sqlerrm) , 1);
				return; 
			when others then
				o_cdgo_rspsta  := 30;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al consultar los datos del estado de la cartera.' || sqlerrm;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, to_char(sqlerrm) , 1);
				return; 
		end;--Fin Se Consulta el id del estado de la cartera y el lfujo tarea del estado de desembargo		


		-- Se crear el lote de medidas cautelares si p_id_mdda_ctlar_lte is null
		if p_id_mdda_ctlar_lte is null then 
			-- Se registra el lote de medida cautelar de desembargo 
			begin
				o_nmro_mdda_ctlar_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');

   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '04 p_cdgo_clnte: ' || p_cdgo_clnte , 6);   
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '05 o_nmro_mdda_ctlar_lte: ' || o_nmro_mdda_ctlar_lte, 6);   
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '06 v_id_fncnrio: ' || v_id_fncnrio , 6);   
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '07 p_dsmbrgo_tpo: ' || p_dsmbrgo_tpo, 6);   
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '08 p_json: ' || p_json, 6);   
   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '09 p_nmro_rgstro_prcsar: ' || p_nmro_rgstro_prcsar, 6);  
   

				insert into mc_g_lotes_mdda_ctlar( cdgo_clnte,		nmro_cnsctvo,			fcha_lte,	
												   tpo_lte,	        id_fncnrio,         	dsmbrgo_tpo,
												   json,			nmro_rgstro_prcsar, 	cdgo_estdo_lte)
										   values( p_cdgo_clnte,	o_nmro_mdda_ctlar_lte,	sysdate, 	
												  'D',		        v_id_fncnrio,      	 	p_dsmbrgo_tpo,
												  p_json,			p_nmro_rgstro_prcsar,   'PEJ')
										 returning id_lte_mdda_ctlar into o_id_mdda_ctlar_lte;

				v_id_mdda_ctlar_lte	:= o_id_mdda_ctlar_lte;
				o_mnsje_rspsta	:= 'o_nmro_mdda_ctlar_lte: ' || o_nmro_mdda_ctlar_lte || ' o_id_mdda_ctlar_lte: ' || o_id_mdda_ctlar_lte;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);   
			exception
				when others then
				o_cdgo_rspsta  := 60;
				o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al registrar el lote de la medida cautelar. ' || sqlerrm; 
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
				return;
			end;-- Fin Se registra el lote de medida cautelar de desembargo
		else
			v_id_mdda_ctlar_lte	:= p_id_mdda_ctlar_lte;
			if p_indcdor_prcsmnto = 'PRMRO' then 
				update mc_g_lotes_mdda_ctlar
				  set cdgo_estdo_lte = 'EJC'
				where id_lte_mdda_ctlar =  p_id_mdda_ctlar_lte;
			end if;
		end if; -- Fin Se crear el lote de medidas cautelares si p_id_mdda_ctlar_lte is null


		-- !! -- SE REGISTRAN LAS RESOLUCIONES DE DESEMBARGO -- !! --
		o_mnsje_rspsta   := 'SE REGISTRAN LAS RESOLUCIONES DE DESEMBARGO';
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);
		-- Se recorre el json con los embargos a desembargar
		for c_embrgos in ( select a.id_embrgos_rslcion
							    , a.id_embrgos_crtra
							    , a.id_tpos_embrgo
							    , a.cdgo_clnte
							    , a.cdgo_csal
							    , b.id_csles_dsmbrgo
							    , a.id_instncia_fljo
							    , a.id_fljo_trea
							from json_table(p_json  ,'$[*]'
											columns (id_embrgos_rslcion		number		path '$.ID_ER'
 												   , id_embrgos_crtra		number		path '$.ID_EC'
												   , id_tpos_embrgo			number		path '$.ID_TE'
												   , cdgo_clnte				number		path '$.ID_CC'
												   , cdgo_csal				varchar2	path '$.CD_TD'
												   , id_instncia_fljo		number		path '$.ID_IF'
												   , id_fljo_trea			number	    path '$.ID_IT'
													)
											) a
							join mc_d_causales_desembargo	b on a.cdgo_clnte		= p_cdgo_clnte
							 and a.cdgo_csal				= b.cdgo_csal
							 and b.cdgo_clnte				= p_cdgo_clnte
						)loop
			v_count	:= v_count + 1;
			--Se registra el desembargo
			begin
            
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '10 c_embrgos.id_tpos_embrgo: ' || c_embrgos.id_tpos_embrgo, 6);  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '11 c_embrgos.id_csles_dsmbrgo: ' || c_embrgos.id_csles_dsmbrgo, 6);  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '12 v_id_fncnrio: ' || v_id_fncnrio, 6);  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '13 v_id_mdda_ctlar_lte: ' || v_id_mdda_ctlar_lte, 6);  
          
				insert into mc_g_desembargos_resolucion( cdgo_clnte,					id_tpos_mdda_ctlar,			fcha_rgstro_dsmbrgo
													   , id_csles_dsmbrgo,				id_fncnrio,					id_lte_mdda_ctlar)
												 values( c_embrgos.cdgo_clnte,			c_embrgos.id_tpos_embrgo,	systimestamp
													   , c_embrgos.id_csles_dsmbrgo,	v_id_fncnrio,				v_id_mdda_ctlar_lte)
											   returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;

				o_mnsje_rspsta	:= 'v_count: ' || v_count || ' v_id_dsmbrgos_rslcion: ' || v_id_dsmbrgos_rslcion;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);
			exception
				when others then
					o_cdgo_rspsta  := 70;
					o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo registrar la resolución de desembargo.' || sqlerrm; 
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
					return;
			end; -- Fin -Se registra el desembargo

			--Se registra la cartera del desembargo (cabecera)
			begin
            
     pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '15 v_id_dsmbrgos_rslcion: ' || v_id_dsmbrgos_rslcion, 6);  
     pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '16 c_embrgos.id_embrgos_crtra: ' || c_embrgos.id_embrgos_crtra, 6);  
            
				insert into mc_g_desembargos_cartera (id_dsmbrgos_rslcion,		id_embrgos_crtra)
											   values (v_id_dsmbrgos_rslcion,	c_embrgos.id_embrgos_crtra);

				o_mnsje_rspsta	:= 'Cabecera de cartera embargada registrada ';
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);
			exception
				when others then
					rollback;
					o_cdgo_rspsta  := 80;
					o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo registrar el encabezado de la cartera de embargo.' || sqlerrm; 
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
                    return;
			end; -- Fin Se registra la cartera del desembargo (cabecera)

			--Se consultan los datos de la plantilla de resolucion de desembargo        
			begin
            	o_mnsje_rspsta := 'id_tpos_embrgo ' 	|| c_embrgos.id_tpos_embrgo
							   || ' id_csles_dsmbrgo  ' || c_embrgos.id_csles_dsmbrgo;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);

				select a.id_acto_tpo
					 , c.cdgo_cnsctvo
					 , b.id_plntlla
                     , a.id_rprte
				  into v_cdgo_acto_tpo_rslcion 
					 , v_cdgo_cnsctvo
					 , v_id_plntlla_rslcion
                     , v_id_rprte
				 from gn_d_plantillas 				a
				 join mc_d_tipos_mdda_ctlr_dcmnto	b on b.id_plntlla 			= a.id_plntlla
				  and b.id_tpos_mdda_ctlar 			= c_embrgos.id_tpos_embrgo
				 join df_c_consecutivos				c on c.id_cnsctvo       	= b.id_cnsctvo
				where a.tpo_plntlla					= 'P'
				  and b.id_csles_dsmbrgo			= c_embrgos.id_csles_dsmbrgo
				  and a.actvo						= 'S'
				  and a.id_prcso					= 24
				  and b.tpo_dcmnto					= 'R'
				  and b.clse_dcmnto					= 'P'
			group by a.id_acto_tpo
				   , c.cdgo_cnsctvo
				   , b.id_plntlla
                   , a.id_rprte;

				o_mnsje_rspsta	:= 'v_cdgo_acto_tpo_rslcion: ' 	|| v_cdgo_acto_tpo_rslcion 
								|| ' v_cdgo_cnsctvo: ' 			|| v_cdgo_cnsctvo
								|| ' v_id_plntlla_rslcion: ' 	|| v_id_plntlla_rslcion
								|| ' v_id_rprte: ' 				|| v_id_rprte;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta , 6);
                
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '17 v_cdgo_cnsctvo: ' || v_cdgo_cnsctvo, 6);  
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '18 v_id_plntlla_rslcion: ' || v_id_plntlla_rslcion, 6);  
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '19  v_id_rprte: ' ||  v_id_rprte, 6);  
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '20 c_embrgos.id_csles_dsmbrgo: ' || c_embrgos.id_csles_dsmbrgo, 6);  
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, '20 c_embrgos.id_tpos_embrgo: ' || c_embrgos.id_tpos_embrgo, 6);  
                  
                
			exception
				when no_data_found then 
                    o_cdgo_rspsta  := 90;
                    o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta|| ': Entra aqui ' || sqlerrm; 
					o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se encontraron datos para la plantilla de resolucion de desembargo.'; 
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
					return;
                when others then
					o_cdgo_rspsta  := 100;
					o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al consultar los datos para la plantilla de resolucion de desembargo. ' || sqlerrm; 
					pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
					return;
			end; --Fin Se consultan los datos de la plantilla de resolucion de desembargo        

            -- !! -- GENERACIÓN DEL ACTO DE RESOLUCIÓN DE DESEMBARGO -- !! -- 			
            o_mnsje_rspsta   := 'GENERACIÓN DEL ACTO DE RESOLUCIÓN DE DESEMBARGO';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

            o_mnsje_rspsta	:= 'c_embrgos.id_embrgos_crtra: ' 		|| c_embrgos.id_embrgos_crtra 
                            || ' v_id_dsmbrgos_rslcion: ' 			|| v_id_dsmbrgos_rslcion
                            || ' v_cdgo_cnsctvo: ' 					|| v_cdgo_cnsctvo
                            || ' c_embrgos.id_embrgos_rslcion: '	|| c_embrgos.id_embrgos_rslcion;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

            -- Se registra el acto de resolución de desembargo
            begin
                pkg_cb_medidas_cautelares.prc_rg_acto( p_cdgo_clnte            =>  p_cdgo_clnte
													 , p_id_usuario            =>  p_id_usrio
													 , p_id_embrgos_crtra      =>  c_embrgos.id_embrgos_crtra
													 , p_id_embrgos_rspnsble   =>  null 
													 , p_id_slctd_ofcio        =>  v_id_dsmbrgos_rslcion
													 , p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo
													 , p_id_acto_tpo           =>  v_cdgo_acto_tpo_rslcion
													 , p_vlor_embrgo           =>  1
													 , p_id_embrgos_rslcion    =>  c_embrgos.id_embrgos_rslcion
													 , o_id_acto               =>  v_id_acto
													 , o_fcha                  =>  v_fcha
													 , o_nmro_acto             =>  v_nmro_acto); 

				o_mnsje_rspsta	:= 'v_id_acto: ' 			|| v_id_acto 
								|| ' v_fcha: ' 				|| v_fcha
								|| ' v_nmro_acto: ' 		|| v_nmro_acto;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
			exception
                when others then
                o_cdgo_rspsta  := 110;
                o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo generar el acto de resolución de desembargo. ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                rollback;
                return;
            end; -- Fin Se genera el acto de Resolución

            -- Se actualiza los datos de resolucion de desembargo
            begin
                update mc_g_desembargos_resolucion
                   set id_acto				= v_id_acto
                     , fcha_acto        	= v_fcha
                     , nmro_acto        	= v_nmro_acto
                 where id_dsmbrgos_rslcion	= v_id_dsmbrgos_rslcion;

                o_mnsje_rspsta	:= 'Se acualizaron ' || sql%rowcount || ' registros.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            exception 
                when others then 
                    o_cdgo_rspsta	:= 120;
                    o_mnsje_rspsta	:= v_mnsje_rspsta || o_cdgo_rspsta || 'Error al actualizar la información del acto a la resolución de desembargo. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;
            end;-- Fin Se actualiza los datos de resolucion de desembargo

			-- Se genera el html de la plantilla de resolucion de desembargo
            begin
              -- v_dcmnto_html := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| c_embrgos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgos_rslcion>'|| v_id_dsmbrgos_rslcion ||'</id_dsmbrgos_rslcion><id_acto>'||v_id_acto||'</id_acto>', v_id_plntlla_rslcion);
			   v_dcmnto_html := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":'|| c_embrgos.id_embrgos_crtra ||',"id_dsmbrgos_rslcion":'|| v_id_dsmbrgos_rslcion ||',"id_acto":'||v_id_acto||'}', v_id_plntlla_rslcion);                                  

			exception
                when others then 
                    o_cdgo_rspsta	:= 130;
                    o_mnsje_rspsta	:= v_mnsje_rspsta || o_cdgo_rspsta ||' Error al generar el html de la plantilla de la resolución de embargo. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;
            end; -- Fin Se genera el html de la plantilla de resolucion de desembargo

            -- Se actualiza los datos de resolucion de desembargo (html de la plantilla)
            begin
                update mc_g_desembargos_resolucion
                   set dcmnto_dsmbrgo	   = to_clob(v_dcmnto_html),
                       id_plntlla          = v_id_plntlla_rslcion
                 where id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;

                o_mnsje_rspsta	:= 'Se acualizaron ' || sql%rowcount || ' registros.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            exception 
                when others then 
                    o_cdgo_rspsta	:= 140;
                    o_mnsje_rspsta	:=  v_mnsje_rspsta || o_cdgo_rspsta ||' Error al actualizar los datos de la resolución desembargo (html de la plantilla). ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
            end;-- Fin Se actualiza los datos de resolucion de desembargo (html de la plantilla)

            -- Se genera el blob del acto de resolucion de desembargo
            begin
                pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo( c_embrgos.cdgo_clnte
                                                                  , v_id_acto
                                                                  , '<data><id_dsmbrgos_rslcion>' || v_id_dsmbrgos_rslcion || '</id_dsmbrgos_rslcion></data>'
																  , v_id_rprte
                                                                  , v_app_session
                                                                  , p_id_usrio);
                o_mnsje_rspsta	:= 'Se genero el blob del acto de resolución de desembargo';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            exception
                when others then 
                    o_cdgo_rspsta	:= 150;
                    o_mnsje_rspsta	:= v_mnsje_rspsta || o_cdgo_rspsta ||' Error al generar el blob de la resolucion de desembargo. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    rollback;
                    return;
            end;-- Fin Se genera el blob del acto de resolucion de desembargo

			o_mnsje_rspsta   := 'FIN GENERACIÓN DEL ACTO DE RESOLUCIÓN DE DESEMBARGO '||v_nmbre_up;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            -- FIN GENERACIÓN DE LA RESOLUCIÓN DE DESEMBARGO --

			o_mnsje_rspsta :=  'v_id_estdos_crtra : '|| v_id_estdos_crtra ||' '|| 'id_embrgos_crtra: ' || c_embrgos.id_embrgos_crtra;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

            -- Se actualiza el estado del embargo
            begin            
               update mc_g_embargos_cartera
                  set id_estdos_crtra  = v_id_estdos_crtra
                where id_embrgos_crtra = c_embrgos.id_embrgos_crtra;

				o_mnsje_rspsta	:= 'Se acualizaron ' || sql%rowcount || ' registros en mc_g_embargos_cartera.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

             exception
                when others then
                    o_cdgo_rspsta  := 160;
                    o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo actualizar el estado de la medida cautelar.' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;
            end;-- Fin Se actualiza el estado del embargo

            --Se actualiza la transición del flujo
            begin 
                update wf_g_instancias_transicion
                   set id_estdo_trnscion	= 3
                 where id_instncia_fljo 	= c_embrgos.id_instncia_fljo; 

				o_mnsje_rspsta	:= 'Se acualizaron ' || sql%rowcount || ' registros en wf_g_instancias_transicion.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

              exception
                when others then
                    o_cdgo_rspsta  := 170;
                    o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo actualizar la transición de la medida cautelar.' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;
            end;--Fin Se actualiza la transición del flujo


            --Se Genera la nueva transición del flujo
            begin
                insert into wf_g_instancias_transicion( id_instncia_fljo,           id_fljo_trea_orgen, fcha_incio, 
                                                        id_usrio,                   id_estdo_trnscion)
                                                values( c_embrgos.id_instncia_fljo,	v_id_fljo_trea,     systimestamp,
                                                        p_id_usrio,                 2);

				o_mnsje_rspsta	:= 'Se insertaron ' || sql%rowcount || ' registros en wf_g_instancias_transicion.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

              exception
                when others then
                    o_cdgo_rspsta  := 180;
                    o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo generar la transición de la medida cautelar.' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;
            end;--Fin Se Genera la nueva transición del flujo

            -- Se elimina el desembargo de la tabla de población
            begin
                delete from mc_g_desembargos_poblacion 
                 where id_instncia_fljo = c_embrgos.id_instncia_fljo;

				o_mnsje_rspsta	:= 'Se borraron ' || sql%rowcount || ' registros en mc_g_desembargos_poblacion.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

             exception
                when others then
                    o_cdgo_rspsta  := 190;
                    o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se pudo eliminar el candidato de la población.' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;                    
            end;-- Fin Se elimina el desembargo de la tabla de población

			-- Si fue el Job quien proceso los registros de desembargos
			if p_id_dsmbrgo_dtlle_lte is not null and v_count > 0 then
				--Se actualiza el total de registros procesados  
				begin
					update mc_g_desembargos_dtlle_lte
						set nmro_rgstro_prcsdos = v_count
							, cdgo_estdo_lte = 'EJC'
							, fcha_fin = sysdate
					where id_dsmbrgo_dtlle_lte =  p_id_dsmbrgo_dtlle_lte 
						and id_lte_mdda_ctlar  = v_id_mdda_ctlar_lte;

				exception
					when others then
						o_cdgo_rspsta	:= 200;
						o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al actualizar el total de registros que han sido procesados por el Job. ' || sqlerrm; 
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
						rollback;
						return;  			
				end;  --Fin Se actualiza el total de registros procesados 
			end if;  -- Fin Si fue el Job quien proceso los registros de desembargos

		   commit;

		end loop;-- Fin Se recorre el json con los embargos a desembargar

		o_mnsje_rspsta   := 'FIN SE REGISTRAN LAS RESOLUCIONES DE DESEMBARGO';
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
		-- FIN SE REGISTRAN LAS RESOLUCIONES DE DESEMBARGO -- 

		if v_id_mdda_ctlar_lte is not null and v_count > 0 then
			-- Se actualiza el numero de desembargo generados en la tabla de medidas cautelar lote (desmebargo)
            begin 
                update mc_g_lotes_mdda_ctlar
                  set cntdad_dsmbrgo_lote       = v_count + nvl(cntdad_dsmbrgo_lote,0)
                where id_lte_mdda_ctlar         = v_id_mdda_ctlar_lte;
            exception
				when others then
                    o_cdgo_rspsta	:= 210;
                    o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al actualizar el total de desembargos en el lote de desemnbargo. ' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    rollback;
                    return;  
            end;

      end if;-- Fin Se valida si se genero el lote de desemnargo y generaron desembargos

		if (v_count = 0) then
            o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': No se generaron desembargos.'; 
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            rollback;
            return;
        else 
            if p_indcdor_prcsmnto = 'ULTMO' then 

				-- Se generan los oficios de desembargos
				begin
					pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo( p_cdgo_clnte        => p_cdgo_clnte
																		  , p_id_usuario        => p_id_usrio
																		  , p_id_lte_mdda_ctlar => v_id_mdda_ctlar_lte
																		  , o_cdgo_rspsta		=> o_cdgo_rspsta
																		  , o_mnsje_rspsta		=> o_mnsje_rspsta);


					if o_cdgo_rspsta != 0 then 
						o_cdgo_rspsta	:= 220;
						o_mnsje_rspsta 	:= v_mnsje_rspsta || o_mnsje_rspsta; 
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
						rollback;
						return; 
					end if;
				exception
					when others then
						o_cdgo_rspsta  := 230;
						o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al consultar la información del tipo de acto de oficio por lote de desembargo. '||o_mnsje_rspsta||' - ' || sqlerrm; 
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
						rollback;
						return;            
				end;-- Fin Se generan los oficios de desembargos


				update mc_g_lotes_mdda_ctlar
				  set cdgo_estdo_lte = 'TRM'
				where id_lte_mdda_ctlar =  v_id_mdda_ctlar_lte;
			end if ;


			-- Si fue el Job quien proceso los registros de desembargos
			if p_id_dsmbrgo_dtlle_lte is not null then
				--Se actualiza el total de registros procesados  
				begin
					update mc_g_desembargos_dtlle_lte
						set nmro_rgstro_prcsdos = v_count
							, cdgo_estdo_lte = 'TRM'
							, fcha_fin = sysdate
					where id_dsmbrgo_dtlle_lte =  p_id_dsmbrgo_dtlle_lte 
						and id_lte_mdda_ctlar = v_id_mdda_ctlar_lte;

				exception
					when others then
						o_cdgo_rspsta	:= 240;
						o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta|| ': Error al actualizar el total de registros procesados por el Job. ' || sqlerrm; 
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
						rollback;
						return;  			
				end;  --Fin Se actualiza el total de registros procesados 
			end if;  -- Fin Si fue el Job quien proceso los registros de desembargos

			o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Se generaron ' || v_count|| ' desembargos.'; 
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            commit;
            return;                    
        end if;


		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo ' || systimestamp, 6);
	exception
        when others then 
            o_cdgo_rspsta   := 999;
            o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' Error: ' || sqlerrm;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);
			rollback;
			return;

	end;

	procedure prc_gn_rslcnes_dsmbrgo_msvo ( p_cdgo_clnte        	in number
										  , p_json     				in clob
										  , o_cdgo_rspsta       	out number
										  , o_mnsje_rspsta      	out varchar2 ) as 

	v_nl                    	number;
	v_nmbre_up              	varchar2(70)    := 'pkg_mc_medidas_cautelares.prc_gn_rslcnes_dsmbrgo_msvo';
	v_mnsje_rspsta				varchar2(70)	:= '|MCT_RSLCION_DSM_MSV CDGO: ';
    l_zip_file                  blob;
    v_nmbre_zip                 varchar2(100)	:= 'Resoluciones.zip';  
    v_count                     number          := 0;

    begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);

        -- Se recorre el json con las resoluciones de desembargo y se consulta el blob para agregarlo al zip
        for c_rslcnes in (select a.id_rslcion_dsmbrgo
                                , c.file_blob
                                , c.file_name
                             from json_table( p_json  ,'$[*]'
                                    columns ( id_rslcion_dsmbrgo number path '$.id_rslcion_dsmbrgo')) a
                            join mc_g_desembargos_resolucion    b on a.id_rslcion_dsmbrgo   = b.id_dsmbrgos_rslcion
                            join v_gn_g_actos                   c on b.id_acto              = c.id_acto ) loop

			v_count         := v_count + 1;
            o_mnsje_rspsta  := 'Resolución N°: ' || v_count;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

            -- Se agrega el blob al zip
            begin 
                apex_zip.add_file ( p_zipped_blob => l_zip_file
                                  , p_file_name   => c_rslcnes.file_name
                                  , p_content     => c_rslcnes.file_blob );

                o_mnsje_rspsta  := 'Se agrego la Resolución ID: ' || c_rslcnes.id_rslcion_dsmbrgo || ' al zip';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
            exception 
                when others then 
                    o_cdgo_rspsta	:= 1;
                    o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta || ': Error al agregar el blob de la resolución ' || c_rslcnes.id_rslcion_dsmbrgo || ' al zip ' || sqlerrm; 
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    return;  
            end;-- Fin Se agrega el blob al zip
		end loop;-- Fin Se recorre el json con las resoluciones de desembargo y se consulta el blob para agregarlo al zip

		o_mnsje_rspsta  := ' Se agregron ' || v_count || ' resoluciones al zip';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);

        -- Se finaliza el zip y se descarga
        begin 
            apex_zip.finish( p_zipped_blob =>  l_zip_file );
            /*owa_util.mime_header('application/zip', FALSE); 
            htp.p('Content-length: '|| dbms_lob.getlength(l_zip_file));
            htp.p('Content-Disposition: attachment; filename="' || v_nmbre_zip || '"');
            owa_util.http_header_close;
            wpg_docload.download_file(l_zip_file);*/
        exception 
            when others then 
                o_cdgo_rspsta	:= 2;
                o_mnsje_rspsta 	:= v_mnsje_rspsta || o_cdgo_rspsta || ': Error al finalizar el zip. ' || sqlerrm; 
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                return;  
        end;-- Se finaliza el zip y se descarga

        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  :=  v_mnsje_rspsta || o_cdgo_rspsta || ' Generación del Zip exitosa';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo ' || systimestamp, 1);
	exception
        when others then 
            o_cdgo_rspsta   := 999;
            o_mnsje_rspsta  := v_mnsje_rspsta || o_cdgo_rspsta || ' Error: ' || sqlerrm;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 6);
			rollback;
			return;
	end;

end pkg_mc_medidas_cautelares;

/
