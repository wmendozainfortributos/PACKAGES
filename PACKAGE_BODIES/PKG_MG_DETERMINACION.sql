--------------------------------------------------------
--  DDL for Package Body PKG_MG_DETERMINACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_DETERMINACION" as
	/*
	* @Descripción		: Migración de Determinación
	* @Autor			: Ing. Shirley Romero
	* @Creación			: 10/01/2021
	* @Modificación		: 25/01/2021
	*/

    -- UP Migración de Determinación Predial
	procedure prc_mg_determinacion_predial( p_id_entdad               	in  number
										  , p_id_prcso_instncia       	in  number
										  , p_id_usrio                	in  number
										  , p_cdgo_clnte              	in  number
										  , o_ttal_dtrmncion_mgrdas		out number
										  , o_ttal_extsos             	out number
										  , o_ttal_error              	out number
										  , o_cdgo_rspsta             	out number
										  , o_mnsje_rspsta            	out varchar2
										  ) as								  

    v_errors                    	pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_df_s_clientes             	df_s_clientes%rowtype;
    v_dtrmncion			      		r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion();
	t_v_df_i_impuestos_subimpuesto 	v_df_i_impuestos_subimpuesto%rowtype;
    v_mg_g_intrmdia             	pkg_mg_determinacion.r_mg_g_intrmdia_dtrmncion;
	v_cartera                   	migra.mg_g_intermedia_determina%rowtype;
    v_id_sjto_impsto				number;
	v_id_impsto						number      := 230011;
	v_id_impsto_sbmpsto				number      := 2300111;
	v_id_prdo						number;
	v_id_orgen						number;	
	v_id_cncpto			        	number;
    v_cntdad_dtrmncion_mgrdas       number      := 0;
    v_id_dtrmncion                  number;
	v_id_entdad_rspnsbles			number 		:= 2602;

	type t_intrmdia_rcrd is record
	(
	   r_cartera	r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion(),
	   r_extracto	r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion() 
	);

	type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);

	v_intrmdia_rcrd g_intrmdia_rcrd;

    begin
        --Limpia la Cache
        --dbms_result_cache.flush;
        o_ttal_extsos := 0;
        o_ttal_error  := 0;		

		begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con código #' || p_cdgo_clnte || ', no existe en el sistema.';
                  return;
        end;

        insert into gti_aux (col1, col2) values ('Inicio Determinación',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));

		--Llena la Coleccion de Intermedia
        select a.*
          bulk collect  
          into v_mg_g_intrmdia
          from migra.mg_g_intermedia_determina a
         where a.cdgo_clnte         = p_cdgo_clnte 
           and a.id_entdad          = p_id_entdad
           and a.cdgo_estdo_rgstro  = 'L'
           and a.clmna4             = 'IPU'			-- Código del impuesto
           and a.clmna1             is not null 	-- Consecutivo determinación
           and a.clmna6	            is not null 	-- Referencia Catastral
		   and a.clmna1				= 172
      order by a.clmna1
			 , a.clmna6;

		--Verifica si hay Registros Cargado
		if( v_mg_g_intrmdia.count = 0 ) then
			o_cdgo_rspsta  := 2;
			o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
			return;  
		end if;

		--Llena la Coleccion de Determinación
        for i in 1..v_mg_g_intrmdia.count loop            
			--Se definen los índices
            declare
                v_index number;
            begin			
				if( i = 1 or (i > 1 and v_mg_g_intrmdia(i).clmna6 <> v_mg_g_intrmdia(i-1).clmna6
							  )
				   ) then                  
				  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6) := t_intrmdia_rcrd();
				  v_dtrmncion.extend;
				  v_dtrmncion(v_dtrmncion.count) :=  v_mg_g_intrmdia(i);
				end if;

                if (v_mg_g_intrmdia(i).clmna15 is not null) then
                    v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera.count;
                    if (v_index > 0) then
                        v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera(v_index);                        
                        if(v_mg_g_intrmdia(i).clmna15 || v_mg_g_intrmdia(i).clmna16 != v_cartera.clmna15 || v_cartera.clmna16) then                                               
                            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera.extend;
                            v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera.count;
                            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera(v_index) := v_mg_g_intrmdia(i);
                        end if;
                    else
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera.extend;
                        v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera.count;
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera(v_index) := v_mg_g_intrmdia(i);
                    end if;

                    v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna6).r_cartera(1);                
				end if;
            end;
        end loop;

		for i in 1..v_dtrmncion.count loop
			--Insertar Determinación
			declare
				v_actvo						varchar2(1);
				v_fcha_dtrmncion			date 	:= to_date(v_dtrmncion(i).clmna2, 'DD/MM/YYYY');
				v_cdgo_prdio_clsfccion		gi_g_determinacion_ad_prdio.cdgo_prdio_clsfccion%type;
				v_id_prdio_uso_slo			gi_g_determinacion_ad_prdio.id_prdio_uso_slo%type;
				v_id_prdio_dstno			gi_g_determinacion_ad_prdio.id_prdio_dstno%type;
				v_cdgo_estrto				gi_g_determinacion_ad_prdio.cdgo_estrto%type;
				v_area_trrno				gi_g_determinacion_ad_prdio.area_trrno%type;
				v_area_cnstrda				gi_g_determinacion_ad_prdio.area_cnstrda%type;
				v_area_grvble				gi_g_determinacion_ad_prdio.area_grvble%type;
				v_mtrcla_inmblria			gi_g_determinacion_ad_prdio.mtrcla_inmblria%type;
			begin
                v_id_sjto_impsto    := v_dtrmncion(i).clmna20;
				if v_dtrmncion(i).clmna7 = 'A' then 
					v_actvo				:= 'S';
				else
					v_actvo				:= 'N';
				end if;

				begin
					select a.id_sjto_impsto
					  into v_id_sjto_impsto
					  from v_si_i_sujetos_impuesto        	a
					 where a.cdgo_clnte   					= p_cdgo_clnte
					   and (a.idntfccion_antrior            = v_dtrmncion(i).clmna6
						 or a.idntfccion_sjto               = v_dtrmncion(i).clmna6);				
				exception
					when others then 
						o_cdgo_rspsta  := 3;
						o_mnsje_rspsta := o_cdgo_rspsta || '. Error al el id del sujeto. '||v_dtrmncion(i).clmna6 || sqlerrm;					                    
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				insert into gi_g_determinaciones (cdgo_clnte,				id_impsto,		id_impsto_sbmpsto,
												  id_sjto_impsto,			tpo_orgen,		id_orgen,
												  fcha_dtrmncion,			actvo,			indcdor_mgrdo)
										  values (p_cdgo_clnte,				v_id_impsto,	v_id_impsto_sbmpsto,
												  v_id_sjto_impsto,			'MG',			to_number(v_dtrmncion(i).clmna1),
												  v_fcha_dtrmncion,			v_actvo,		'S')
						  returning id_dtrmncion into v_id_dtrmncion;					
                    --DBMS_OUTPUT.put_line('v_id_dtrmncion: ' || v_id_dtrmncion);

				-- COnuslta del id de uso del predio
				begin 
					select id_prdio_uso_slo
					  into v_id_prdio_uso_slo
					  from df_c_predios_uso_suelo
					 where cdgo_clnte				= p_cdgo_clnte
					   and cdgo_prdio_uso_slo		= v_dtrmncion(i).clmna8;
				exception
					when others then 
						o_cdgo_rspsta  := 3;
						o_mnsje_rspsta := o_cdgo_rspsta || '. Error al consultar el predio uso. '||v_dtrmncion(i).clmna8 || sqlerrm;					                    
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				-- COnuslta del id del destino
				begin 
					select id_prdio_dstno
					  into v_id_prdio_dstno
					  from df_i_predios_destino
					 where cdgo_clnte				= p_cdgo_clnte
					   and id_impsto				= v_id_impsto
					   and nmtcnco					= v_dtrmncion(i).clmna9;
				exception
					when others then 
						o_cdgo_rspsta  := 4;
						o_mnsje_rspsta := o_cdgo_rspsta || '. Error al consultar el destino. '||v_dtrmncion(i).clmna9 || sqlerrm;					                    
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				v_cdgo_estrto		:= v_dtrmncion(i).clmna10;
				v_area_trrno		:= to_number(v_dtrmncion(i).clmna11);
				v_area_cnstrda		:= to_number(v_dtrmncion(i).clmna12);
				v_area_grvble		:= to_number(v_dtrmncion(i).clmna13);
				v_mtrcla_inmblria	:= v_dtrmncion(i).clmna14;

				insert into gi_g_determinacion_ad_prdio (id_dtrmncion,		cdgo_prdio_clsfccion, 		id_prdio_uso_slo, 
														 id_prdio_dstno,	cdgo_estrto, 				area_trrno, 
														 area_cnstrda,		area_grvble,				mtrcla_inmblria,
														 indcdor_mgrdo)
												 values (v_id_dtrmncion,	v_cdgo_prdio_clsfccion, 	v_id_prdio_uso_slo, 
														 v_id_prdio_dstno,	v_cdgo_estrto, 				v_area_trrno, 
														 v_area_cnstrda,	v_area_grvble,				v_mtrcla_inmblria,
														 'S');
			exception
				when others then
					rollback;
					o_cdgo_rspsta  := 5;
					o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar la determinación Predial No. '||v_dtrmncion(i).clmna1 || sqlerrm;					                    
                    v_errors.extend;  
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					exit;
			end;

			for j in 1..v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera.count loop
                --Consultamos el id_prdo
				begin
					select 	id_prdo
					  into	v_id_prdo
					  from	df_i_periodos
					 where	cdgo_clnte              = p_cdgo_clnte
					   and	id_impsto               = v_id_impsto
					   and	id_impsto_sbmpsto       = v_id_impsto_sbmpsto
					   and	vgncia                  =  v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna15
					   and	prdo                    =  v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna16;				   
				exception
					when no_data_found then
						rollback;
						o_cdgo_rspsta  := 7;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontro el id del periodo para la vigencia: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna15 || ' y periodo: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna16;
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;


				-- Consultamos el origen del acuerdo
				begin
					 select id_cncpto
					   into v_id_cncpto
					   from df_i_conceptos
					  where cdgo_clnte          = p_cdgo_clnte
						and id_impsto           = v_id_impsto
						and cdgo_cncpto		   	= v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna17;
				exception
					when no_data_found then
						rollback;
						o_cdgo_rspsta  := 8;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontro el id del Concepto: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna17;
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						exit;
				end;

				--Insertamos los datos de cartera convenida
                declare
                    v_vgncia				number	:= v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna15;
					v_vlor_cptal            number  := nvl(v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna18, 1);
                    v_vlor_intres           number  := nvl(v_intrmdia_rcrd(v_dtrmncion(i).clmna6).r_cartera(j).clmna19, 1);

				begin
					insert into gi_g_determinacion_detalle (id_dtrmncion,		vgncia,			id_prdo,
														id_cncpto,			vlor_cptal,		vlor_intres,
                                                        indcdor_mgrdo) 
                                                values (v_id_dtrmncion,		v_vgncia,		v_id_prdo,
                                                        v_id_cncpto,		v_vlor_cptal,   v_vlor_intres,
                                                        'S');
				exception
					when others then
						rollback;
						o_cdgo_rspsta  := 9;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar el detalle de la determinacion' || sqlerrm;
						v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna4).r_extracto(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;						
				end;

			end loop;

			v_cntdad_dtrmncion_mgrdas    := v_cntdad_dtrmncion_mgrdas + 1;               
            commit;
			-- Resposable 
			for c_rspnsbles in (select *
								  from migra.mg_g_intermedia_determina
								 where cdgo_clnte						= p_cdgo_clnte
								   and id_entdad						= v_id_entdad_rspnsbles
								   and clmna1							= v_dtrmncion(i).clmna1 -- Num determinacion
								   and clmna2							= v_dtrmncion(i).clmna6 -- referencia
							   ) loop
				begin
					insert into gi_g_dtrmncn_rspnsble (id_dtrmncion,		id_sjto_impsto, 	cdgo_idntfccion_tpo,
													   idntfccion,			prmer_nmbre,		sgndo_nmbre,
													   prmer_aplldo,		sgndo_aplldo,		prncpal_s_n,
													   cdgo_tpo_rspnsble,	orgen_dcmnto,		indcdor_mgrdo)
												values (v_id_dtrmncion,		v_id_sjto_impsto,	c_rspnsbles.clmna3,
														c_rspnsbles.clmna4,	c_rspnsbles.clmna5,	c_rspnsbles.clmna6,
														nvl(c_rspnsbles.clmna7, '.'),	c_rspnsbles.clmna8,	c_rspnsbles.clmna9,
														'RSP',				'1',				'S');

				exception
					when others then
						rollback;
						o_cdgo_rspsta  := 5;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar el reposable '||c_rspnsbles.clmna4|| sqlerrm;					                    
						v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						exit;
				end;
			end loop;
		end loop;



		insert into gti_aux (col1, col2) values ('Termino Determinación',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
        commit;

		--Procesos con Errores
        o_ttal_dtrmncion_mgrdas   	:= v_cntdad_dtrmncion_mgrdas;
        o_ttal_error            	:= v_errors.count;
        o_ttal_extsos           	:= v_mg_g_intrmdia.count - v_errors.count;

        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';

        insert into gti_aux (col1, col2) values ('inicio insertar error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                         values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );

        insert into gti_aux (col1, col2) values ('termino insertar error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;

        forall j in 1..o_ttal_error
            update migra.mg_g_intermedia_determina
               set cdgo_estdo_rgstro = 'E'
                 , clmna46           = 'N'
             where id_intrmdia       = v_errors(j).id_intrmdia;
		insert into gti_aux (col1, col2) values ('termino actualizacion de interm con error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
    end prc_mg_determinacion_predial;

	procedure prc_mg_determinacion_predialv2( p_id_entdad               	in  number
										    , p_id_prcso_instncia       	in  number
										    , p_id_usrio                	in  number
										    , p_cdgo_clnte              	in  number
										    , o_ttal_dtrmncion_mgrdas		out number
										    , o_ttal_extsos             	out number
										    , o_ttal_error              	out number
										    , o_cdgo_rspsta             	out number
										    , o_mnsje_rspsta            	out varchar2
										  ) as								  

	v_nmbre_up						varchar2(70)    := 'pkg_mg_determinacion.prc_mg_determinacion_predialv2';
	v_errors                    	pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
	v_df_s_clientes             	df_s_clientes%rowtype;
	v_dtrmncion			      		r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion();
	t_v_df_i_impuestos_subimpuesto 	v_df_i_impuestos_subimpuesto%rowtype;
	v_mg_g_intrmdia             	pkg_mg_determinacion.r_mg_g_intrmdia_dtrmncion;
	v_cartera                   	migra.mg_g_intermedia_determina%rowtype;
	v_id_sjto_impsto				number;
	v_id_impsto						number          := 230011;
	v_id_impsto_sbmpsto				number          := 2300111;
	v_id_prdo						number;
	v_id_orgen						number;	
	v_id_cncpto			        	number;
	v_cntdad_dtrmncion_mgrdas       number          := 0;
	v_id_dtrmncion                  number;
	v_id_entdad_rspnsbles			number 		    := 2602;
	v_tmpo_incio       				timestamp       := systimestamp;
	v_tmpo_incio_for   				timestamp       := systimestamp;
	v_tmpo_fin         				timestamp       := systimestamp;
	v_drccion          				varchar2(100);
	v_drccion_ttal     				varchar2(100);
	v_cntdad_rgstros				number		    := 0;
	v_cntdad_rgstros_ttla			number		    := 0;

	type t_intrmdia_rcrd is record
	(
	   r_cartera	r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion(),
	   r_extracto	r_mg_g_intrmdia_dtrmncion := r_mg_g_intrmdia_dtrmncion() 
	);

	type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);

	v_intrmdia_rcrd g_intrmdia_rcrd;

	begin
		insert into gti_aux (col1, col2) values ('Entro UP',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;
		--Limpia la Cache
		dbms_result_cache.flush;
		o_ttal_extsos := 0;
		o_ttal_error  := 0;	

		begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con código #' || p_cdgo_clnte || ', no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                  return;
        end;

		v_tmpo_incio      := systimestamp;
		v_tmpo_incio_for  := systimestamp;
		insert into gti_aux (col1, col2) values ('Inicio For de Identificaciones',  to_char(v_tmpo_incio, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;

		for c_indtfccion in (select /*+ full(a) index(a mg_g_inter_det_cln_ent_ind) */
						   distinct clmna6 
								from migra.mg_g_intermedia_determina	a
							   where id_entdad							= p_id_entdad
								 and cdgo_clnte							= p_cdgo_clnte
								 and a.clmna6							is not null
								 and a.cdgo_estdo_rgstro				= 'L'
								 --and a.clmna6							in ( '0001000000050075000000000', '0001000000040119000000000')
							) loop
			v_dtrmncion := r_mg_g_intrmdia_dtrmncion();

			--Llena la Coleccion de Intermedia
			select a.*
			  bulk collect  
			  into v_mg_g_intrmdia
			  from migra.mg_g_intermedia_determina	a
			 where a.cdgo_clnte         			= p_cdgo_clnte 
			   and a.id_entdad          			= p_id_entdad
			   and a.cdgo_estdo_rgstro  			= 'L'
			   and a.clmna4             			= 'IPU'					-- Código del impuesto
			   and a.clmna1             			is not null 			-- Consecutivo determinación
			   and a.clmna6	            			= c_indtfccion.clmna6 	-- Referencia Catastral
		  order by a.clmna1
				 , a.clmna6;

			--Verifica si hay Registros Cargado
			if( v_mg_g_intrmdia.count = 0 ) then
				o_cdgo_rspsta  := 2;
				o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el Sujeto Impuesto: ' || c_indtfccion.clmna6;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
			end if;

			--Llena la Coleccion de Determinación
			for i in 1..v_mg_g_intrmdia.count loop
				--Se definen los índices
				declare
					v_index number;
				begin			
					if( i = 1 or (i > 1 and v_mg_g_intrmdia(i).clmna1 <> v_mg_g_intrmdia(i-1).clmna1
								  )
					   ) then                  
					  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1) := t_intrmdia_rcrd();
					  v_dtrmncion.extend;
					  v_dtrmncion(v_dtrmncion.count) :=  v_mg_g_intrmdia(i);  
					end if;

					if (v_mg_g_intrmdia(i).clmna15 is not null) then
						v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera.count;
						if (v_index > 0) then                            
							v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera(v_index);
								v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera.extend;
								v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera.count;
								v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera(v_index) := v_mg_g_intrmdia(i);
						else
							v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera.extend;
							v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera.count;
							v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera(v_index) := v_mg_g_intrmdia(i);
						end if;

						v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna1).r_cartera(1);
					end if;
				end;
			end loop;

			for i in 1..v_dtrmncion.count loop

				--Insertar Determinación
				declare
					v_actvo						varchar2(1);
					v_fcha_dtrmncion			date 	:= to_date(v_dtrmncion(i).clmna2, 'DD/MM/YYYY');
					v_cdgo_prdio_clsfccion		gi_g_determinacion_ad_prdio.cdgo_prdio_clsfccion%type;
					v_id_prdio_uso_slo			gi_g_determinacion_ad_prdio.id_prdio_uso_slo%type;
					v_id_prdio_dstno			gi_g_determinacion_ad_prdio.id_prdio_dstno%type;
					v_cdgo_estrto				gi_g_determinacion_ad_prdio.cdgo_estrto%type;
					v_area_trrno				gi_g_determinacion_ad_prdio.area_trrno%type;
					v_area_cnstrda				gi_g_determinacion_ad_prdio.area_cnstrda%type;
					v_area_grvble				gi_g_determinacion_ad_prdio.area_grvble%type;
					v_mtrcla_inmblria			gi_g_determinacion_ad_prdio.mtrcla_inmblria%type;
				begin
					v_id_sjto_impsto    := v_dtrmncion(i).clmna20;
					if v_dtrmncion(i).clmna7 = 'A' then 
						v_actvo				:= 'S';
					else
						v_actvo				:= 'N';
					end if;

					begin
						select a.id_sjto_impsto
						  into v_id_sjto_impsto
						  from v_si_i_sujetos_impuesto        	a
						 where a.cdgo_clnte   					= p_cdgo_clnte
                           and a.id_impsto                      = v_id_impsto
						   and a.idntfccion_sjto                = v_dtrmncion(i).clmna6;				
					exception
						when others then 
							v_id_dtrmncion	:= null;
							o_cdgo_rspsta  := 3;
							o_mnsje_rspsta := o_cdgo_rspsta || '. Error al consultar el id del sujeto impuesto:  '|| v_dtrmncion(i).clmna6 || ' - '|| sqlerrm;					                    
							pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                            v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					insert into gi_g_determinaciones (cdgo_clnte,				id_impsto,		id_impsto_sbmpsto,
													  id_sjto_impsto,			tpo_orgen,		id_orgen,
													  fcha_dtrmncion,			actvo,			indcdor_mgrdo)
											  values (p_cdgo_clnte,				v_id_impsto,	v_id_impsto_sbmpsto,
													  v_id_sjto_impsto,			'MG',			to_number(v_dtrmncion(i).clmna1),
													  v_fcha_dtrmncion,			v_actvo,		'S')
							  returning id_dtrmncion into v_id_dtrmncion;
					-- Conuslta del id de uso del predio
					begin 
						select id_prdio_uso_slo
						  into v_id_prdio_uso_slo
						  from df_c_predios_uso_suelo
						 where cdgo_clnte				= p_cdgo_clnte
						   and cdgo_prdio_uso_slo		= v_dtrmncion(i).clmna8;
					exception
						when others then 
							v_id_dtrmncion	:= null;
							o_cdgo_rspsta  := 3;
							o_mnsje_rspsta := o_cdgo_rspsta || '. Error al consultar el predio uso. '||v_dtrmncion(i).clmna8 || sqlerrm;					                    
							pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                            v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					-- COnuslta del id del destino
					begin 
						select id_prdio_dstno
						  into v_id_prdio_dstno
						  from df_i_predios_destino
						 where cdgo_clnte				= p_cdgo_clnte
						   and id_impsto				= v_id_impsto
						   and nmtcnco					= v_dtrmncion(i).clmna9;
					exception
						when others then 
							v_id_dtrmncion	:= null;
							o_cdgo_rspsta  := 4;
							o_mnsje_rspsta := o_cdgo_rspsta || '. Error al consultar el destino. '||v_dtrmncion(i).clmna9 || sqlerrm;					                    
							pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                            v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					v_cdgo_estrto		:= v_dtrmncion(i).clmna10;
					v_area_trrno		:= to_number(v_dtrmncion(i).clmna11);
					v_area_cnstrda		:= to_number(v_dtrmncion(i).clmna12);
					v_area_grvble		:= to_number(v_dtrmncion(i).clmna13);
					v_mtrcla_inmblria	:= v_dtrmncion(i).clmna14;

					insert into gi_g_determinacion_ad_prdio (id_dtrmncion,		cdgo_prdio_clsfccion, 		id_prdio_uso_slo, 
															 id_prdio_dstno,	cdgo_estrto, 				area_trrno, 
															 area_cnstrda,		area_grvble,				mtrcla_inmblria,
															 indcdor_mgrdo)
													 values (v_id_dtrmncion,	v_cdgo_prdio_clsfccion, 	v_id_prdio_uso_slo, 
															 v_id_prdio_dstno,	v_cdgo_estrto, 				v_area_trrno, 
															 v_area_cnstrda,	v_area_grvble,				v_mtrcla_inmblria,
															 'S');
				exception
					when others then
						v_id_dtrmncion	:= null;
						rollback;
						o_cdgo_rspsta  := 5;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar la determinación Predial No. '||v_dtrmncion(i).clmna1 || sqlerrm;					                    
						pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                        v_errors.extend;  
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						exit;
				end;

				for j in 1..v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera.count loop
					--Consultamos el id_prdo
					begin
						select 	id_prdo
						  into	v_id_prdo
						  from	df_i_periodos
						 where	cdgo_clnte              = p_cdgo_clnte
						   and	id_impsto               = v_id_impsto
						   and	id_impsto_sbmpsto       = v_id_impsto_sbmpsto
						   and	vgncia                  =  v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna15
						   and	prdo                    =  v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna16;				   
					exception
						when no_data_found then
							v_id_dtrmncion	:= null;
							rollback;
							o_cdgo_rspsta  := 7;
							o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontro el id del periodo para la vigencia: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna15 || ' y periodo: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna16;
							pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                            v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
					-- Consultamos el id del concepto
					if v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna17 != '5000' then 
                        begin
                             select id_cncpto
                               into v_id_cncpto
                               from df_i_conceptos
                              where cdgo_clnte          = p_cdgo_clnte
                                and id_impsto           = v_id_impsto
                                and cdgo_cncpto		   	= v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna17;
                        exception
                            when no_data_found then
                                v_id_dtrmncion	:= null;
                                rollback;
                                o_cdgo_rspsta  := 8;
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontro el id del Concepto: ' || v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna17;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                exit;
                        end;
                    end if;

					--Insertamos los datos de cartera determinada
                    declare
						v_vgncia				number	:= v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna15;
						v_vlor_cptal            number  := nvl(v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna18, 1);
						v_vlor_intres           number  := nvl(v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_cartera(j).clmna19, 1);

					begin
						insert into gi_g_determinacion_detalle (id_dtrmncion,		vgncia,			id_prdo,
															id_cncpto,			vlor_cptal,		vlor_intres,
															indcdor_mgrdo) 
													values (v_id_dtrmncion,		v_vgncia,		v_id_prdo,
															v_id_cncpto,		v_vlor_cptal,   v_vlor_intres,
															'S');
						v_cntdad_rgstros	:= v_cntdad_rgstros + 1;
					exception
						when others then
							v_id_dtrmncion	:= null;
							rollback;
							o_cdgo_rspsta  := 9;
							o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar el detalle de la determinacion' || sqlerrm;
							pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                            v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_intrmdia_rcrd(v_dtrmncion(i).clmna1).r_extracto(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;						
					end;

				end loop;

				v_cntdad_dtrmncion_mgrdas    := v_cntdad_dtrmncion_mgrdas + 1;
				commit;

				-- Resposable 
                if v_id_dtrmncion is not null then 
					for c_rspnsbles in (select *
										  from migra.mg_g_intermedia_determina
										 where cdgo_clnte						= p_cdgo_clnte
										   and id_entdad						= v_id_entdad_rspnsbles
										   and clmna1							= v_dtrmncion(i).clmna1 -- Num determinacion
										   and clmna2							= v_dtrmncion(i).clmna6 -- referencia
									   ) loop
						begin
							insert into gi_g_dtrmncn_rspnsble (id_dtrmncion,		id_sjto_impsto, 	cdgo_idntfccion_tpo,
															   idntfccion,			prmer_nmbre,		sgndo_nmbre,
															   prmer_aplldo,		sgndo_aplldo,		prncpal_s_n,
															   cdgo_tpo_rspnsble,	orgen_dcmnto,		indcdor_mgrdo)
														values (v_id_dtrmncion,		v_id_sjto_impsto,	c_rspnsbles.clmna3,
																c_rspnsbles.clmna4,	c_rspnsbles.clmna5,	c_rspnsbles.clmna6,
																nvl(c_rspnsbles.clmna7, '.'),	c_rspnsbles.clmna8,	c_rspnsbles.clmna9,
																'RSP',				'1',				'S');

						exception
							when others then
								rollback;
								o_cdgo_rspsta  := 5;
								o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar el reposable '||c_rspnsbles.clmna4|| sqlerrm;					                    
								pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                                v_errors.extend;  
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								exit;
						end;
					end loop;
				end if;

                begin 
                    update migra.mg_g_intermedia_determina
                       set cdgo_estdo_rgstro                = 'S'
                         , clmna22                          = v_id_dtrmncion
                     where id_entdad                        = p_id_entdad
                       and clmna1                           = v_dtrmncion(i).clmna1
                       and clmna6                           = v_dtrmncion(i).clmna6;
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 5;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. al actualizar intermedia '|| sqlerrm;					                    
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, 6, o_mnsje_rspsta, 6); 
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_dtrmncion(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        exit;
                end;

				if mod (v_cntdad_dtrmncion_mgrdas, 1000) = 0 then 
					v_drccion       	:= to_char(systimestamp - v_tmpo_incio);
                    v_drccion_ttal      := to_char(systimestamp - v_tmpo_incio_for); 
                    v_cntdad_rgstros_ttla   := v_cntdad_rgstros_ttla + v_cntdad_rgstros;
					insert into gti_aux (col1, col2, col3) 
								 values ('v_cntdad_dtrmncion_mgrdas: '	|| v_cntdad_dtrmncion_mgrdas,
										'v_cntdad_rgstros: '			|| v_cntdad_rgstros || ' v_cntdad_rgstros_ttla: ' || v_cntdad_rgstros_ttla, 
										'Duración: ' 					|| v_drccion || ' v_drccion_ttal: ' || v_drccion_ttal);
					v_tmpo_incio		:= systimestamp;					
                    v_cntdad_rgstros	:= 0;
				end if;
			end loop;

		end loop;


		insert into gti_aux (col1, col2) values ('Termino For de Identificaciones',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
        commit;

		--Procesos con Errores
        o_ttal_dtrmncion_mgrdas   	:= v_cntdad_dtrmncion_mgrdas;
        o_ttal_error            	:= v_errors.count;
        o_ttal_extsos           	:= v_mg_g_intrmdia.count - v_errors.count;

        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';

        if o_ttal_error > 0 then 
            insert into gti_aux (col1, col2) values ('o_ttal_error:',  o_ttal_error);commit;
            insert into gti_aux (col1, col2) values ('inicio insertar error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;

            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                             values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );

            insert into gti_aux (col1, col2) values ('termino insertar error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;

            insert into gti_aux (col1, col2) values ('Inicio actualizacion de interm con error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
            forall j in 1..o_ttal_error
            update migra.mg_g_intermedia_determina
               set cdgo_estdo_rgstro = 'E'
                 , clmna46           = 'N'
             where id_intrmdia       = v_errors(j).id_intrmdia;
            insert into gti_aux (col1, col2) values ('termino actualizacion de interm con error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
        end if;

    exception 
        when others then 
            o_cdgo_rspsta  := 99;
            o_mnsje_rspsta := o_cdgo_rspsta || '. Error #' || sqlerrm;
            return;
    end prc_mg_determinacion_predialv2;


	procedure prc_mg_determinacion_acto (p_id_entdad					in number
									   , p_id_prcso_instncia			in number
									   , p_id_usrio						in number
									   , p_cdgo_clnte					in number
									   , p_id_impsto					in number
									   , o_ttal_dtrmncion_prcsdas		out number
									   , o_ttal_extsos					out number
									   , o_ttal_error					out number
									   , o_cdgo_rspsta					out number
									   , o_mnsje_rspsta					out varchar2 ) as

	v_nmbre_up					varchar2(70)				:= 'pkg_mg_determinacion.prc_mg_determinacion_acto';
	v_errors					pkg_mg_migracion.r_errors	:= pkg_mg_migracion.r_errors();
	v_cdgo_rspsta				number;
	v_mnsje_rspsta				clob;

	v_tmpo_incio				timestamp					:= systimestamp;
	v_tmpo_incio_for			timestamp					:= systimestamp;
	v_tmpo_fin					timestamp					:= systimestamp;
	v_drccion					varchar2(100);
	v_drccion_ttal				varchar2(100);

	v_slct_sjto_impsto			clob;
	v_slct_vgncias				clob;
	v_slct_rspnsble				clob;
	v_ttal_dtrmncion			number;
	v_cdgo_acto_orgen			varchar2(3)					:= 'DTM';
	v_json_acto					clob;
	v_id_acto_tpo				number						:= pkg_gn_generalidades.fnc_cl_id_acto_tpo (p_cdgo_clnte	=> p_cdgo_clnte
																									  , p_cdgo_acto_tpo	=> 'DTM');
	v_id_acto					number;
	v_cntdad_vgncias			number;
	v_cntdad_rspnsble			number;

	begin 
		insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Entro UP',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;

		--Limpia la Cache
		dbms_result_cache.flush;
		o_ttal_extsos				:= 0;
		o_ttal_error				:= 0;
		o_ttal_dtrmncion_prcsdas	:= 0;
		v_cntdad_vgncias			:= 0;
		v_cntdad_rspnsble			:= 0;	

		for c_dtmncion in (select *
							from gi_g_determinaciones
						   where cdgo_clnte				= p_cdgo_clnte
							 and id_impsto				= p_id_impsto
							 and tpo_orgen				= 'MG'
							 and id_acto				is null
							 --and id_dtrmncion           = 546408
							) loop

			--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Entro al for',  c_dtmncion.id_dtrmncion); commit;
			-- Inicio de Variables
			o_ttal_dtrmncion_prcsdas	:= o_ttal_dtrmncion_prcsdas + 1;
			v_slct_sjto_impsto			:= null;
			v_slct_vgncias				:= null;
			v_slct_rspnsble				:= null;
			v_ttal_dtrmncion			:= 0;
			v_json_acto					:= null;
			v_id_acto					:= null;

			begin 
				v_slct_sjto_impsto	:= ' select id_impsto_sbmpsto, 
												id_sjto_impsto 
										   from gi_g_determinaciones 
										  where id_dtrmncion = ' || c_dtmncion.id_dtrmncion;

				--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Despues de v_slct_sjto_impsto',  v_slct_sjto_impsto); commit;
				begin 
					select count(*)
					   into v_cntdad_vgncias
					   from gi_g_determinaciones		a
					   join gi_g_determinacion_detalle	b on a.id_dtrmncion = b.id_dtrmncion
					  where a.id_dtrmncion				= c_dtmncion.id_dtrmncion;

					if v_cntdad_vgncias > 0 then 
						v_slct_vgncias		:= ' select a.id_sjto_impsto,
														b.vgncia,
														b.id_prdo,
														abs(trunc(sum(b.vlor_cptal))) vlor_cptal,
														abs(trunc(sum(b.vlor_intres)))vlor_intres
												   from gi_g_determinaciones a
												   join gi_g_determinacion_detalle b on a.id_dtrmncion = b.id_dtrmncion
												  where a.id_dtrmncion = ' || c_dtmncion.id_dtrmncion ||' 
											   group by a.id_sjto_impsto,
														b.vgncia,
														b.id_prdo';
					else
						v_cdgo_rspsta   := 1;
						o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' no existen vigencias ' || ' para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']';
						o_ttal_error	:= o_ttal_error + 1 ;
						insert into gti_aux (col1, col2, col3) values ('Determinación error:', o_mnsje_rspsta, v_mnsje_rspsta);
						continue;
					end if;
			exception
				when others then
					v_cdgo_rspsta   := 2;
					o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error al consultar las vigencias de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']';
					o_ttal_error	:= o_ttal_error + 1 ;
					rollback;
					insert into gti_aux (col1, col2, col3) values ('Determinación error:', o_mnsje_rspsta, v_mnsje_rspsta);
					continue;
			end;

			--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Despues de v_slct_vgncias',  v_slct_vgncias); commit;
			begin
				select count(*)
				  into v_cntdad_rspnsble
				  from gi_g_dtrmncn_rspnsble a
				  join si_i_sujetos_impuesto b on a.id_sjto_impsto = b.id_sjto_impsto
				 where a.id_dtrmncion = c_dtmncion.id_dtrmncion;

				if v_cntdad_rspnsble > 0 then
					v_slct_rspnsble		:= ' select a.cdgo_idntfccion_tpo, 
													a.idntfccion, 
													a.prmer_nmbre, 
													a.sgndo_nmbre, 
													a.prmer_aplldo, 
													a.sgndo_aplldo,
													nvl(b.drccion_ntfccion,''--'') drccion_ntfccion,
													b.id_pais_ntfccion,
													b.id_dprtmnto_ntfccion,
													b.id_mncpio_ntfccion,
													b.email,
													b.tlfno
											   from gi_g_dtrmncn_rspnsble a
											   join si_i_sujetos_impuesto b on a.id_sjto_impsto = b.id_sjto_impsto
											  where a.id_dtrmncion = ' || c_dtmncion.id_dtrmncion || 
										  'group by a.cdgo_idntfccion_tpo, 
													a.idntfccion, 
													a.prmer_nmbre, 
													a.sgndo_nmbre, 
													a.prmer_aplldo, 
													a.sgndo_aplldo,
													b.drccion_ntfccion, 
													b.id_pais_ntfccion,
													b.id_dprtmnto_ntfccion,
													b.id_mncpio_ntfccion,
													b.email,
													b.tlfno';
				else
					v_slct_rspnsble	:= null;
					v_mnsje_rspsta	:= 'La determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || '] no tiene responsables';
					insert into gti_aux (col1, col2, col3) values ('Determinación:', v_mnsje_rspsta,  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
				end if;
			exception
				when others then
					v_cdgo_rspsta   := 3;
					o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error al consultar los responsables de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']';
					o_ttal_error	:= o_ttal_error + 1 ;
					rollback;
					insert into gti_aux (col1, col2, col3) values ('Determinación error:', o_mnsje_rspsta, v_mnsje_rspsta);
					continue;
			end;
				--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Despues de v_slct_rspnsble',  v_slct_rspnsble); commit;
				begin 
					select trunc(nvl(sum(a.vlor_cptal) + sum (a.vlor_intres), 0))
					  into v_ttal_dtrmncion 
					  from gi_g_determinacion_detalle a 
					 where id_dtrmncion = c_dtmncion.id_dtrmncion
					   and a.vlor_cptal > 0;
				exception 
					when others then 
						v_ttal_dtrmncion	:= 0;
				end;
				--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Despues de v_ttal_dtrmncion',  v_ttal_dtrmncion); commit;

				v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto (p_cdgo_clnte				=> p_cdgo_clnte
																	, p_cdgo_acto_orgen			=> v_cdgo_acto_orgen
																	, p_id_orgen				=> c_dtmncion.id_dtrmncion 
																	, p_id_undad_prdctra		=> c_dtmncion.id_dtrmncion 
																	, p_id_acto_tpo				=> v_id_acto_tpo
																	, p_acto_vlor_ttal			=> v_ttal_dtrmncion
																	, p_cdgo_cnsctvo			=> 'ACT'
																	, p_id_acto_rqrdo_hjo		=> null
																	, p_id_acto_rqrdo_pdre		=> null
																	, p_fcha_incio_ntfccion		=> sysdate
																	, p_id_usrio 				=> p_id_usrio
																	, p_slct_sjto_impsto		=> v_slct_sjto_impsto
																	, p_slct_vgncias			=> v_slct_vgncias
																	, p_slct_rspnsble			=> v_slct_rspnsble);
				--insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Despues de v_json_acto',  v_json_acto); commit;
				begin
					pkg_gn_generalidades.prc_rg_acto (p_cdgo_clnte		=> p_cdgo_clnte
													, p_json_acto		=> v_json_acto
													, o_id_acto			=> v_id_acto
													, o_cdgo_rspsta		=> v_cdgo_rspsta
													, o_mnsje_rspsta	=> v_mnsje_rspsta);
					if v_cdgo_rspsta = 0 then 
						begin 
							update gi_g_determinaciones
							   set id_acto					= v_id_acto
							 where id_dtrmncion				= c_dtmncion.id_dtrmncion;

							update gn_g_actos
							set nmro_acto				= c_dtmncion.id_orgen
							  , anio					= extract (year from trunc(c_dtmncion.fcha_dtrmncion))
							  , nmro_acto_dsplay		= extract (year from trunc(c_dtmncion.fcha_dtrmncion)) || '-' || c_dtmncion.id_orgen
							  , fcha					= c_dtmncion.fcha_dtrmncion
							  , fcha_incio_ntfccion		= trunc(c_dtmncion.fcha_dtrmncion)
						  where id_acto					= v_id_acto;
						exception
							when others then 
								v_cdgo_rspsta	:= 1;
								o_mnsje_rspsta	:= 'N°: ' || v_cdgo_rspsta || ' Error al actualizar los datos del acto para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || '] ' || sqlerrm;
								o_ttal_error	:= o_ttal_error + 1 ;
								rollback;
								insert into gti_aux (col1, col2) values ('Determinación:', o_mnsje_rspsta);
								continue;
						end;
						o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Se registro el Acto. id: ' || v_id_acto || ' para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']';
						o_ttal_extsos	:= o_ttal_extsos + 1;
						--insert into gti_aux (col1) values (o_mnsje_rspsta);
						commit;
					else
						v_cdgo_rspsta   := 2;
						o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error al generar el Acto: ' || o_mnsje_rspsta || ' para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']';
						o_ttal_error	:= o_ttal_error + 1 ;
						rollback;
						insert into gti_aux (col1, col2, col3) values ('Determinación:', o_mnsje_rspsta, v_mnsje_rspsta);
						continue;
					end if;

				exception 
					when others then 
						v_cdgo_rspsta   := 3;
						o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error al generar el Acto: ' || o_mnsje_rspsta || ' para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
						o_ttal_error	:= o_ttal_error + 1 ;
						rollback;
						insert into gti_aux (col1, col2) values ('Determinación:', o_mnsje_rspsta);
						continue;
				end; 

				if mod (o_ttal_dtrmncion_prcsdas, 1000) = 0 then 
					v_drccion			:= to_char(systimestamp - v_tmpo_incio_for);
					v_drccion_ttal		:= to_char(systimestamp - v_tmpo_incio); 
					insert into gti_aux (col1, col2, col3, col4) 
								 values ('Determinación:', 
										'o_ttal_dtrmncion_prcsdas: '	|| o_ttal_dtrmncion_prcsdas,
										'Duración: '					|| v_drccion,
										'Duración Total: '				|| v_drccion_ttal);
					v_tmpo_incio_for	:= systimestamp;
				end if;
			exception
				when others then 
					v_cdgo_rspsta   := 99;
					o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
					o_ttal_error	:= o_ttal_error + 1 ;
					insert into gti_aux (col1, col2) values ('Determinación:', o_mnsje_rspsta);
			end;
		end loop;
		v_drccion_ttal	:= to_char(systimestamp - v_tmpo_incio); 
		o_cdgo_rspsta  	:= 0;
		o_mnsje_rspsta 	:= 'Exito';
		v_mnsje_rspsta	:= 'o_ttal_dtrmncion_prcsdas: ' || o_ttal_dtrmncion_prcsdas
						|| ' o_ttal_extsos: ' 			|| o_ttal_extsos
						|| ' o_ttal_error: ' 			|| o_ttal_error
						|| ' Duración Total: '			|| v_drccion_ttal;
		insert into gti_aux (col1, col2, col3) values ('Determinación:', v_mnsje_rspsta,  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;
		insert into gti_aux (col1, col2, col3) values ('Determinación:', 'Salio UP',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;
	exception
		when others then 
			v_cdgo_rspsta   := 999;
			o_mnsje_rspsta 	:= 'N°: ' || v_cdgo_rspsta || ' Error ' || sqlerrm;
			insert into gti_aux (col1, col2) values ('Determinación:', o_mnsje_rspsta);
	end;


	procedure prc_mg_determinacion_acto_v2(p_cdgo_clnte					in number
										 , p_id_impsto					in number
										 , p_id_usrio					in number
										 , o_ttal_dtrmncion_prcsdas		out number
										 , o_ttal_extsos				out number
										 , o_ttal_error					out number
										 , o_cdgo_rspsta				out number
										 , o_mnsje_rspsta				out varchar2
								) as

	v_nmbre_up					varchar2(70)				:= 'pkg_mg_determinacion.prc_mg_determinacion_acto_v2';
	v_cdgo_rspsta				number;
	v_mnsje_rspsta				clob;

	v_tmpo_incio				timestamp					:= systimestamp;
	v_tmpo_incio_for			timestamp					:= systimestamp;
	v_tmpo_fin					timestamp					:= systimestamp;
	v_drccion					varchar2(100);
	v_drccion_ttal				varchar2(100);

	v_ttal_dtrmncion			number;
	v_cdgo_acto_orgen			varchar2(3) := 'DTM';
	v_json_acto					clob;
	v_id_acto_tpo				number						:= pkg_gn_generalidades.fnc_cl_id_acto_tpo (p_cdgo_clnte	=> p_cdgo_clnte
																									  , p_cdgo_acto_tpo	=> 'DTM');
	v_id_acto					number;
	v_anio						number;
	v_nmro_acto_dsplay			varchar2(50);
	v_id_fncnrio_frma			number;
	begin 
		insert into gti_aux (col1, col2, col3) values ('Determinación v2', 'Entro UP',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;
		--Limpia la Cache
		dbms_result_cache.flush;
		o_ttal_extsos				:= 0;
		o_ttal_error				:= 0;
		v_id_acto					:= 0;
		v_anio						:= null;
		v_nmro_acto_dsplay			:= '';
		o_ttal_dtrmncion_prcsdas	:= 0;

		-- Se consulta el funcionario que firma
		begin 
			select id_fncnrio
			   into v_id_fncnrio_frma
			   from gn_d_actos_funcionario_frma
			  where id_acto_tpo			= v_id_acto_tpo
				and actvo				= 'S';
		exception
			when others then
				o_cdgo_rspsta	:= 1;
				o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' No se encontro funcionario parametrizado';
				insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
				commit;
				return;
		end;
		for c_dtmncion in (select *
							from gi_g_determinaciones
						   where cdgo_clnte				= p_cdgo_clnte
							 and id_impsto				= p_id_impsto
							 and tpo_orgen				= 'MG'
							 and id_acto				is null
							 --and id_dtrmncion			= 543693
						) loop
			-- Inicio de Variables
			o_ttal_dtrmncion_prcsdas	:= o_ttal_dtrmncion_prcsdas + 1;
			v_ttal_dtrmncion			:= 0;
			v_json_acto					:= '';
			v_id_acto					:= null;

			-- Se calcula el total de la determinacion
			begin 
				select nvl(sum(a.vlor_cptal) + sum (a.vlor_intres), 0)
				  into v_ttal_dtrmncion 
				  from gi_g_determinacion_detalle a 
				 where id_dtrmncion = c_dtmncion.id_dtrmncion ;
			exception 
				when others then 
					v_ttal_dtrmncion	:= 0;
			end;

			-- Se registra el Acto
			begin 
				v_anio					:= extract (year from trunc(c_dtmncion.fcha_dtrmncion));
				v_nmro_acto_dsplay		:= v_anio || '-' || c_dtmncion.id_orgen;

				insert into gn_g_actos( cdgo_clnte,					cdgo_acto_orgen,			id_orgen,
										id_undad_prdctra,			id_acto_tpo,				nmro_acto,
										anio,						nmro_acto_dsplay,			fcha,
										id_usrio,					id_fncnrio_frma,			id_acto_rqrdo_ntfccion,
										fcha_incio_ntfccion,		vlor)
								values (p_cdgo_clnte,				v_cdgo_acto_orgen,			c_dtmncion.id_dtrmncion,
										c_dtmncion.id_dtrmncion,	v_id_acto_tpo,				c_dtmncion.id_orgen,
										v_anio,						v_nmro_acto_dsplay,			c_dtmncion.fcha_dtrmncion,
										p_id_usrio,					v_id_fncnrio_frma,			null,
										c_dtmncion.fcha_dtrmncion,	v_ttal_dtrmncion)
				 returning id_acto into v_id_acto;
				 --insert into gti_aux (col1, col2) values ('Determinación v2 Error', 'Acto: ' || v_id_acto ); commit;
			exception
				when others then
					o_cdgo_rspsta	:= 2;
					o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error al insertar el Acto para la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
					o_ttal_error	:= + 1 ;
					rollback;
					insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
					commit;
					continue;
			end;
			-- Se registran los sujetos
			begin 
				insert into gn_g_actos_sujeto_impuesto (id_acto,	id_impsto_sbmpsto,					id_sjto_impsto)
												values (v_id_acto,	c_dtmncion.id_impsto_sbmpsto,		c_dtmncion.id_sjto_impsto);
				--insert into gti_aux (col1, col2) values ('Determinación v2 Error', 'Inserto sujeto' ); commit;
			exception
				when others then
					o_cdgo_rspsta	:= 3;
					o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error al insertar el sujeto impuesto de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
					o_ttal_error	:= + 1 ;
					rollback;
					insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
					commit;
					continue;
			end;
			-- Se registran los responsables
			begin 
				for c_rspnsbles in ( select a.cdgo_idntfccion_tpo
										  , a.idntfccion
										  , a.prmer_nmbre
										  , a.sgndo_nmbre
										  , a.prmer_aplldo
										  , a.sgndo_aplldo
										  , nvl(b.drccion_ntfccion, '--') drccion_ntfccion
										  , b.id_pais_ntfccion
										  , b.id_dprtmnto_ntfccion
										  , b.id_mncpio_ntfccion
										  , b.email
										  , b.tlfno
									   from gi_g_dtrmncn_rspnsble	a
									   join si_i_sujetos_impuesto	b on a.id_sjto_impsto = b.id_sjto_impsto
									  where a.id_dtrmncion 			= c_dtmncion.id_dtrmncion 
									  ) loop
					-- Se registra el responsables
					begin
						insert into gn_g_actos_responsable (id_acto,							cdgo_idntfccion_tpo,				idntfccion,
															prmer_nmbre,						sgndo_nmbre,						prmer_aplldo,
															sgndo_aplldo,						drccion_ntfccion,					id_pais_ntfccion,
															id_dprtmnto_ntfccion,				id_mncpio_ntfccion,					email,
															tlfno)
													 values (v_id_acto,							c_rspnsbles.cdgo_idntfccion_tpo,	c_rspnsbles.idntfccion,
															 c_rspnsbles.prmer_nmbre,			c_rspnsbles.sgndo_nmbre,			c_rspnsbles.prmer_aplldo,
															 c_rspnsbles.sgndo_aplldo,			c_rspnsbles.drccion_ntfccion,		c_rspnsbles.id_pais_ntfccion,
															 c_rspnsbles.id_dprtmnto_ntfccion,	c_rspnsbles.id_mncpio_ntfccion,		c_rspnsbles.email,
															 c_rspnsbles.tlfno);
					exception
						when others then
							o_cdgo_rspsta	:= 4;
							o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error al insertar el responsable de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || ' Responsable: ' || c_rspnsbles.idntfccion || '-' || sqlerrm;
							o_ttal_error	:= + 1 ;
							rollback;
							insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
							commit;
					end;
					--insert into gti_aux (col1, col2) values ('Determinación v2 Error', 'Inserto responsable' ); commit;
				end loop;
			exception
				when others then
					o_cdgo_rspsta	:= 5;
					o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error en los responsables de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
					o_ttal_error	:= + 1 ;
					rollback;
					insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
					commit;
					exit;
			end;
			-- Se consulta la información de las vigencias determinadas
			begin 
				for c_vgncias in (select a.id_sjto_impsto
									   , b.vgncia
									   , b.id_prdo
									   , sum(b.vlor_cptal)			vlor_cptal
									   , sum(b.vlor_intres)			vlor_intres
								   from gi_g_determinaciones		a
								   join gi_g_determinacion_detalle	b on a.id_dtrmncion = b.id_dtrmncion
								  where a.id_dtrmncion 				= c_dtmncion.id_dtrmncion
							   group by a.id_sjto_impsto
									   , b.vgncia
									   , b.id_prdo) loop
					-- Se insertan la vigencia
					begin 
						insert into gn_g_actos_vigencia (id_acto,				id_sjto_impsto,				vgncia,
														 id_prdo,				vlor_cptal,					vlor_intres)
												  values (v_id_acto,			c_vgncias.id_sjto_impsto,	c_vgncias.vgncia,
														  c_vgncias.id_prdo,	c_vgncias.vlor_cptal,		c_vgncias.vlor_cptal);
					exception
						when others then
							o_cdgo_rspsta	:= 6;
							o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error al insertar la vigencia de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || ' Responsable: ' || c_vgncias.vgncia || '-' || sqlerrm;
							o_ttal_error	:= + 1 ;
							rollback;
							insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
							commit;
					end;
					--insert into gti_aux (col1, col2) values ('Determinación v2 Error', 'Inserto vigencia' ); commit;
				end loop;
			exception
				when others then
					o_cdgo_rspsta	:= 7;
					o_mnsje_rspsta	:= 'N°: ' || o_cdgo_rspsta || ' Error en las vigencias de la determinación: ' || c_dtmncion.id_orgen || ' [' || c_dtmncion.id_dtrmncion || ']. ' || sqlerrm;
					o_ttal_error	:= + 1 ;
					rollback;
					insert into gti_aux (col1, col2) values ('Determinación v2 Error', o_mnsje_rspsta);
					commit;
					exit;
			end;
			update gi_g_determinaciones
						   set id_acto					= v_id_acto
						 where id_dtrmncion				= c_dtmncion.id_dtrmncion;
			o_ttal_extsos	:= o_ttal_extsos + 1;

			if mod (o_ttal_dtrmncion_prcsdas, 1000) = 0 then 
				v_drccion			:= to_char(systimestamp - v_tmpo_incio_for);
				v_drccion_ttal		:= to_char(systimestamp - v_tmpo_incio); 
				insert into gti_aux (col1, col2, col3) 
							 values ('o_ttal_dtrmncion_prcsdas: '	|| o_ttal_dtrmncion_prcsdas,
									'Duración: '					|| v_drccion,
									'Duración Total: '				|| v_drccion_ttal);
				v_tmpo_incio_for	:= systimestamp;
			end if;
			commit;

		end loop;

		o_cdgo_rspsta  := 0;
		o_mnsje_rspsta := 'Exito';

	exception
		when others then 
			o_cdgo_rspsta  := 1;
			o_mnsje_rspsta := 'Error: ' || sqlerrm;
			insert into gti_aux (col1) values (o_mnsje_rspsta);
	end;

end pkg_mg_determinacion;

/
