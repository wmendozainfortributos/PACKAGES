--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_DCL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_DCL" as
    

/*******************************  Procedimiento No 20 Migracion Fecha de Presentacion Decalraciones **************************************/ 										  
procedure prc_mg_d_dclrcnes_fcha_prsntc (p_id_entdad			in  number,
                                        --  p_id_prcso_instncia   in  number,
                                          p_id_usrio          	in  number,
                                          p_cdgo_clnte        	in  number,
                                          o_ttal_extsos	    	out number,
                                          o_ttal_error	    	out number,
                                          o_cdgo_rspsta	    	out number,
                                          o_mnsje_rspsta	    out varchar2)											  
										  as

v_errors            		pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();										  
v_cdgo_tpo_dclrcn			varchar2(5);
v_id_dclrcn_tpo				number(15);
v_id_impsto					number(15);
v_id_impsto_sbmpsto			number(15);
v_id_prdo                   number(15);
v_cdgo_prdcdad				varchar2(5);
v_id_dclrcion_tpo_vgncia	number(15);

begin
o_ttal_extsos 	:= 0;
o_ttal_error 	:= 0;

  for c_dclrcnes_fcha_prsntc in (
                            select  a.id_intrmdia					,
                                    a.clmna1						,   --Código Declaracion
                                    a.clmna2						,   --Vigencia
                                    a.clmna3						,   --Código del Periodo
                                    a.clmna4						,   --Fecha Maxima Presentación
                                    a.clmna5						,   --Ultimo Digito identificacion
                                    a.clmna6						    --Código Tipo Sujeto Impuesto                                    
                            from    migra.mg_g_intermedia_declara   a
                            where   a.cdgo_clnte    =   p_cdgo_clnte
                            and     a.id_entdad     =   p_id_entdad
							and     cdgo_estdo_rgstro   =   'L'
                          )
        loop
			/*Con el codigo del tipo de declaración y el cliente tienes el tipo de declaracion,
			eso te da impuesto y sub-impuesto y periodicidad, con eso, 
			vas a la tabla de periodo y consultas con el cliente, impuesto, sub-impesto, periodicidad, y codigo del periodo
			ah la vigencia que ya la tienes */

			if 		(c_dclrcnes_fcha_prsntc.clmna1 = '2002') then 
					v_cdgo_tpo_dclrcn := 'VA361';
			elsif 	(c_dclrcnes_fcha_prsntc.clmna1 = '4002') then 	
					v_cdgo_tpo_dclrcn := 'VA181';
			elsif 	(c_dclrcnes_fcha_prsntc.clmna1 = '5002') then	
					v_cdgo_tpo_dclrcn := 'VA182'; 
            else 
                    v_cdgo_tpo_dclrcn := c_dclrcnes_fcha_prsntc.clmna1;
			end if;

			begin 
				/* se realiza en el 36 - esta tabla en el servidor de valledupar no tiene el campo cdgo_dclrcn_tpo */
				select 	/*+ RESULT_CACHE */
						id_dclrcn_tpo			,
						id_impsto				,
						id_impsto_sbmpsto		,
						cdgo_prdcdad
				into 	v_id_dclrcn_tpo			,
						v_id_impsto				,
						v_id_impsto_sbmpsto		,
						v_cdgo_prdcdad
				from gi_d_declaraciones_tipo  
				where cdgo_clnte  	= p_cdgo_clnte 
				and cdgo_dclrcn_tpo = v_cdgo_tpo_dclrcn;
			exception
				when others then
					o_cdgo_rspsta:= 10;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' -  cdgo_tpo_dclrcn  - '|| v_cdgo_tpo_dclrcn ||' -  '|| SQLERRM; 
					update migra.mg_g_intermedia_declara 
                    set clmna20 = '10' ,
                        clmna21 = o_mnsje_rspsta 
                    where id_intrmdia = c_dclrcnes_fcha_prsntc.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes_fcha_prsntc.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
			end;

			begin				  
				select  /*+ RESULT_CACHE */
						id_prdo
				into 	v_id_prdo
				from 	df_i_periodos 
				where  	cdgo_clnte 			= p_cdgo_clnte					
				and 	id_impsto 			= v_id_impsto         -- no lo tengo impuesto industria y comercio  v_id_impsto			
				and 	id_impsto_sbmpsto 	= v_id_impsto_sbmpsto -- no lo tengo sub impuesto industria y comercio v_id_impsto_sbmpsto
				and 	vgncia 				= c_dclrcnes_fcha_prsntc.clmna2
				and 	prdo 				= c_dclrcnes_fcha_prsntc.clmna3					
				and     cdgo_prdcdad        = v_cdgo_prdcdad; 	
			exception
				when others then
					o_cdgo_rspsta:= 20;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro el id_prdo  por migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_dclrcnes_fcha_prsntc.clmna2 ||' -  cdgo_prdcdad  - '|| v_cdgo_prdcdad||' -  '|| SQLERRM;  
					update migra.mg_g_intermedia_declara 
                    set clmna20 = '20' ,
                        clmna21 = o_mnsje_rspsta 
                    where id_intrmdia = c_dclrcnes_fcha_prsntc.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes_fcha_prsntc.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
			end;
			begin
			--gi_d_dclrcnes_tpos_vgncias (id_dclrcion_tpo_vgncia) --- necesito la vigencia y el periodo
				select 	id_dclrcion_tpo_vgncia
				into 	v_id_dclrcion_tpo_vgncia
				from 	gi_d_dclrcnes_tpos_vgncias 
				where 	id_dclrcn_tpo 	= v_id_dclrcn_tpo
				and 	vgncia 			= c_dclrcnes_fcha_prsntc.clmna2
				and 	id_prdo 		= v_id_prdo;
			exception
				when others then
					o_cdgo_rspsta:= 30;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_dclrcion_tpo_vgncia  por migracion - id_dclrcn_tpo - '|| v_id_dclrcn_tpo ||' - vgncia - '|| c_dclrcnes_fcha_prsntc.clmna2  ||' -  id_prdo - '|| v_id_prdo ||' -  '|| SQLERRM;
					update migra.mg_g_intermedia_declara 
                    set clmna20 = '30' ,
                        clmna21 = o_mnsje_rspsta 
                    where id_intrmdia = c_dclrcnes_fcha_prsntc.id_intrmdia;
					v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes_fcha_prsntc.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;	
			end;			
			begin
				insert into gi_d_dclrcnes_fcha_prsntcn  (id_dclrcion_tpo_vgncia			,
																					dscrpcion						,
																					fcha_incial						,
																					fcha_fnal						,
																					vlor							,
																					actvo							,
																					id_sjto_tpo)
																			values (v_id_dclrcion_tpo_vgncia,
																					'MIG - FECHA PRESENTACION - VIGENCIA - '|| c_dclrcnes_fcha_prsntc.clmna2 ||' PERIODICIDAD - '|| c_dclrcnes_fcha_prsntc.clmna2 ,
																					null,
																				--	trunc(to_date(c_dclrcnes_fcha_prsntc.clmna4,'DD/MM/YYYY'),'YY'),
                                                                                    to_date(c_dclrcnes_fcha_prsntc.clmna4,'DD/MM/YYYY'),
																					null,
																					'N',
																					null);
			exception
				when others then
					o_cdgo_rspsta:= 40;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizao insert de fecha de presentacion de la declaracion - id_dclrcion_tpo_vgncia - '|| v_id_dclrcion_tpo_vgncia  || ' -  '|| SQLERRM;  
					update migra.mg_g_intermedia_declara 
                    set clmna20 = '40' ,
                        clmna21 = o_mnsje_rspsta 
                    where id_intrmdia = c_dclrcnes_fcha_prsntc.id_intrmdia;
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes_fcha_prsntc.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
			end;	


			--Se actualiza el estado de los registros procesados en la tabla migra.mg_g_intermedia_declara
			begin
				update  migra.mg_g_intermedia_declara   a
				set     a.cdgo_estdo_rgstro =   'S'
				where   a.cdgo_clnte        =   p_cdgo_clnte
				and     id_entdad           =   p_id_entdad
				and 	id_intrmdia			= 	c_dclrcnes_fcha_prsntc.id_intrmdia
				and     cdgo_estdo_rgstro   =   'L';
			exception
				when others then
					o_cdgo_rspsta   := 50;
					o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || ' -  '|| SQLERRM; 

					return;
			end;
               --Se actualiza el estado de los registros procesados en la tabla migra.mg_g_intermedia_declara
            begin
                update  migra.mg_g_intermedia_declara   a
                set     a.cdgo_estdo_rgstro =   'S'
                where   a.cdgo_clnte        =   p_cdgo_clnte
                and     a.id_entdad         =   p_id_entdad
                and 	id_intrmdia			= 	c_dclrcnes_fcha_prsntc.id_intrmdia
                and     cdgo_estdo_rgstro   =   'L';
                o_ttal_extsos 	:= o_ttal_extsos + 1;
            exception
                when others then
                    o_cdgo_rspsta   := 60;
                    o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' ||' -  '|| SQLERRM; 
                    --v_errors.extend;  
                    --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    return;
            end;

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
                o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM; 
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.mg_g_intermedia_declara   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_entdad           =   p_id_entdad
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
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



end prc_mg_d_dclrcnes_fcha_prsntc;

/*************************************************************************************************************/

	
/***********************************Procedimiento 20 (Utilizado por todos los procesos)*************************/

	--Migracion de declaraciones con codigo:
	procedure prc_co_datos_migracion	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_json					out	clob,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as
										 
		v_json_object_t					json_object_t := json_object_t();
		
		v_hmlgcion          			pkg_mg_migracion.r_hmlgcion;
		v_cdgo_dclrcn_tpo				varchar2(5);		
		v_id_dclrcn_tpo     			number;
		v_id_impsto						number;
		v_id_impsto_sbmpsto				number;
		v_cdgo_prdcdad					varchar2(5);
		v_id_prdo						number;
		v_id_dclrcion_tpo_vgncia		number;
		v_id_dclrcion_vgncia_frmlrio	number;
		v_id_frmlrio					number;
		v_id_sjto_impsto				number;
		
	begin
		o_cdgo_rspsta := 0;
		
		--Carga los Datos de la Homologación
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);
		
		--Se homologa el codigo tipo de declaración
		begin
			v_cdgo_dclrcn_tpo := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 1,
																	  p_vlor    => p_type_dclrcnes.clmna1,
																	  p_hmlgcion=> v_hmlgcion);
		exception
			when others then
				o_cdgo_rspsta   := 1;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo homologarse el tipo de declaración. ' || sqlerrm;
				return;
		end;
		
		--Se valida el tipo de declaracion
		begin
			select  a.id_dclrcn_tpo,
					a.id_impsto,
					a.id_impsto_sbmpsto,
					a.cdgo_prdcdad
			into    v_id_dclrcn_tpo,
					v_id_impsto,
					v_id_impsto_sbmpsto,
					v_cdgo_prdcdad
			from    gi_d_declaraciones_tipo a
			where   a.cdgo_clnte        =   p_cdgo_clnte
			and     a.cdgo_dclrcn_tpo   =   v_cdgo_dclrcn_tpo;		
		exception
			when others then
				o_cdgo_rspsta   := 2;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el tipo de declaración. ' || sqlerrm;
				return;
		end;
		
		begin
			v_json_object_t.put('id_dclrcn_tpo', v_id_dclrcn_tpo);
			v_json_object_t.put('id_impsto', v_id_impsto);
			v_json_object_t.put('id_impsto_sbmpsto', v_id_impsto_sbmpsto);
			v_json_object_t.put('cdgo_prdcdad', v_cdgo_prdcdad);
		exception
			when others then
				o_cdgo_rspsta   := 2.5;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el tipo de declaración. ' || sqlerrm;
				return;
		end;
		
		--Se valida el periodo
		begin
			select  a.id_prdo
			into	v_id_prdo
			from    df_i_periodos a
			where   a.cdgo_clnte        =   p_cdgo_clnte
			and     a.id_impsto         =   v_id_impsto
			and     a.id_impsto_sbmpsto =   v_id_impsto_sbmpsto
			and     a.vgncia            =   to_char(p_type_dclrcnes.clmna2)
			and     a.prdo              =   to_char(p_type_dclrcnes.clmna3)
			and     a.cdgo_prdcdad      =   v_cdgo_prdcdad;
			
			v_json_object_t.put('id_prdo', v_id_prdo);
			
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo. ' || chr(13) ||
									'p_cdgo_clnte: ' || p_cdgo_clnte || chr(13) ||
									'v_id_impsto: ' || v_id_impsto || chr(13) ||
									'v_id_impsto_sbmpsto: ' || v_id_impsto_sbmpsto || chr(13) ||
									'p_type_dclrcnes.clmna2: ' || p_type_dclrcnes.clmna2 || chr(13) ||
									'p_type_dclrcnes.clmna3: ' || p_type_dclrcnes.clmna3 || chr(13) ||
									'v_cdgo_prdcdad: ' || v_cdgo_prdcdad || chr(13) ||
									sqlerrm;
				return;
		end;
		
		--Se valida el periodo en el tipo de declaración
		begin
			select  a.id_dclrcion_tpo_vgncia
			into	v_id_dclrcion_tpo_vgncia
			from    gi_d_dclrcnes_tpos_vgncias a
			where   a.id_dclrcn_tpo =   v_id_dclrcn_tpo
			and     a.id_prdo       =   v_id_prdo;
			
			v_json_object_t.put('id_dclrcion_tpo_vgncia', v_id_dclrcion_tpo_vgncia);
			
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo en el tipo de declaración. ' || sqlerrm;
				return;
		end;
		
		--Se valida el formulario
		v_id_frmlrio := case when v_cdgo_dclrcn_tpo = '2001'			then 305
							 when v_cdgo_dclrcn_tpo = 'VA361'			then 305
							 when v_cdgo_dclrcn_tpo in ('4001','5001')	then 324
							 when v_cdgo_dclrcn_tpo in ('4002','5002')	then 344
						else null
						end;
		
		if (v_id_frmlrio is null) then
			o_cdgo_rspsta   := 5;
			o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el formulario. ' || sqlerrm;
			return;
		end if;
		
		--Se valida la vigencia formulario
		begin
			select  a.id_dclrcion_vgncia_frmlrio
			into	v_id_dclrcion_vgncia_frmlrio
			from    gi_d_dclrcnes_vgncias_frmlr a
			where   a.id_dclrcion_tpo_vgncia    =   v_id_dclrcion_tpo_vgncia
			and     a.id_frmlrio                =   v_id_frmlrio;
			
			v_json_object_t.put('id_frmlrio', v_id_frmlrio);
			v_json_object_t.put('id_dclrcion_vgncia_frmlrio', v_id_dclrcion_vgncia_frmlrio);
			
		exception
			when no_data_found then
				null;
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la relación entre el periodo en el tipo de declaración y el formulario. ' || sqlerrm;
				return;
		end;
		
		--Si la relación entre el periodo en el tipo de declaración y el formulario no existe se registra
		if (v_id_dclrcion_vgncia_frmlrio is null) then
			begin
				insert into gi_d_dclrcnes_vgncias_frmlr	(
															id_dclrcion_tpo_vgncia,
															id_frmlrio,
															cdgo_vslzcion,
															actvo,
															cdgo_tpo_dscnto_crrccion
														)
												values	(
															v_id_dclrcion_tpo_vgncia,
															v_id_frmlrio,
															'T',
															'N',
															'V'
														) returning id_dclrcion_vgncia_frmlrio into v_id_dclrcion_vgncia_frmlrio;
			exception
				when others then
					o_cdgo_rspsta   := 7;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la relación entre el periodo en el tipo de declaración y el formulario. ' || sqlerrm;
					return;
			end;
			
			--Se valida la vigencia formulario
			--En este momento se de esta forma porque el returning no función en un insert desde un db_link
			/*begin
				select  a.id_dclrcion_vgncia_frmlrio
				into	v_id_dclrcion_vgncia_frmlrio
				from    gi_d_dclrcnes_vgncias_frmlr a
				where   a.id_dclrcion_tpo_vgncia    =   v_id_dclrcion_tpo_vgncia
				and     a.id_frmlrio                =   v_id_frmlrio;
				
				v_json_object_t.put('id_frmlrio', v_id_frmlrio);
				v_json_object_t.put('id_dclrcion_vgncia_frmlrio', v_id_dclrcion_vgncia_frmlrio);
			exception
				when others then
					o_cdgo_rspsta   := 8;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la relación entre el periodo en el tipo de declaración y el formulario. ' || sqlerrm;
					return;
			end;*/
		end if;
		
		--Se valida el sujeto impuesto
		begin
			select      b.id_sjto_impsto
			into        v_id_sjto_impsto
			from        si_c_sujetos            a
			inner join  si_i_sujetos_impuesto   b   on  b.id_sjto   =   a.id_sjto
			where       a.cdgo_clnte    =   p_cdgo_clnte
			and         a.idntfccion    =   to_char(p_type_dclrcnes.clmna4)
			and         b.id_impsto     =   v_id_impsto;
			
			v_json_object_t.put('id_sjto_impsto', v_id_sjto_impsto);
			
		exception
			when others then
				o_cdgo_rspsta   := 9;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el sujeto impuesto. ' || sqlerrm;
				return;
		end;
		
		o_json := v_json_object_t.to_clob;
		
	end prc_co_datos_migracion;	
/***********************************************************************************************************************************/

/******************************Registro del detalle de la declaración para el formulario 305****************************************************/
	--Registro del detalle de la declaración para el formulario 305
	procedure prc_rg_dtlle_frmlrio_324	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as
	
		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;
		
		v_idntfccion_sjto			varchar(1000);
		v_ttal_sldo_crgo			number;
		v_nto_avsos_tblros			number;
		v_nto_sbrtsa_bmbril			number;
		v_nto_sncion				number;
		v_itm_impsto_ica			number;
		
	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaración de los items netos
		begin
			for c_dtlle in	(
								select  a.clmna16,
										a.clmna17,
										a.clmna18
								from    json_table  (
														p_type_dclrcnes.items, '$[*]' columns  (
																				clmna16 number path '$.clmna16',
																				clmna17 varchar2(4000) path '$.clmna17',
																				clmna18 varchar2(4000) path '$.clmna18'
																			)
													)   a
								order by clmna16
							)
			loop
				
				
			--Se validan los items con los atributos parametrizados
				if 	  (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '2306';
				elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '2307';
				elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '2308';
				elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '2309';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '2310';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '2311';
				elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '2312';
				elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '2313';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '2314';
				elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '2315';
				elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '2316,2319';
					v_nto_avsos_tblros			:= to_number(c_dtlle.clmna18);
				elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '2357,2360';
					v_nto_sbrtsa_bmbril			:= to_number(c_dtlle.clmna18);
				elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '2322';
				elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '2323';
				elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '2324';
				elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '2326';
				elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '2332,2335';
					v_nto_sncion				:= to_number(c_dtlle.clmna18);	
				elsif (c_dtlle.clmna16 = 30) then
					v_id_frmlrio_rgion_atrbto	:= '2336';
					v_ttal_sldo_crgo 			:= to_number(c_dtlle.clmna18);	
				elsif (c_dtlle.clmna16 = 31) then
					v_id_frmlrio_rgion_atrbto	:= '2344';
				elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '2345';
				elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '2346';
				end if;								
			
				
				--Se recorren los atributos por items
				for c_atrbto in	(
									select  regexp_substr(v_id_frmlrio_rgion_atrbto,'[^,]+', 1, level) as id_frmlrio_rgion_atrbto
									from    dual
									connect by  regexp_substr(v_id_frmlrio_rgion_atrbto, '[^,]+', 1, level) is not null
								)
				loop
					--Se valida la region del atributo
					begin
						select  a.id_frmlrio_rgion
						into	v_id_frmlrio_rgion
						from    gi_d_frmlrios_rgion_atrbto  a
						where   a.id_frmlrio_rgion_atrbto   =   c_atrbto.id_frmlrio_rgion_atrbto;
					exception
						when others then
							o_cdgo_rspsta   := 1;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;
					
					v_orden := v_orden + 1;
					
					--Se inserta el registro del detalle de la declaración
					begin
						insert into gi_g_declaraciones_detalle  (
																	id_dclrcion,
																	id_frmlrio_rgion,
																	id_frmlrio_rgion_atrbto,
																	fla,
																	orden,
																	vlor,
																	vlor_dsplay
																)
														values  (
																	p_id_dclrcion,
																	v_id_frmlrio_rgion,
																	c_atrbto.id_frmlrio_rgion_atrbto,
																	1,
																	v_orden,
																	c_dtlle.clmna18,
																	c_dtlle.clmna18
																);
					exception
						when others then
							o_cdgo_rspsta   := 2;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaración. ' || sqlerrm;
							return;
					end;
					
				end loop;
			end loop;
		end;
		
		
		-- calculo del valor del item impuesto ica
		v_itm_impsto_ica:= v_ttal_sldo_crgo - v_nto_avsos_tblros - v_nto_sbrtsa_bmbril - v_nto_sncion;
		if v_itm_impsto_ica < 0 then
			v_itm_impsto_ica := 0;
		end if;
		begin
			v_orden := v_orden + 1;
			insert into gi_g_declaraciones_detalle  (
														id_dclrcion,
														id_frmlrio_rgion,
														id_frmlrio_rgion_atrbto,
														fla,
														orden,
														vlor,
														vlor_dsplay
													)
											values  (
														p_id_dclrcion,
														532,
														2341,
														1,
														v_orden,
														v_itm_impsto_ica,
														v_itm_impsto_ica
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaración. ' || sqlerrm;
				return;
		end;
		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaración. ' || sqlerrm;
				return;
		end;
		
				
		--Se registra la identificación
		begin
			v_orden := v_orden + 1;
			insert into gi_g_declaraciones_detalle  (
														id_dclrcion,
														id_frmlrio_rgion,
														id_frmlrio_rgion_atrbto,
														fla,
														orden,
														vlor,
														vlor_dsplay
													)
											values  (
														p_id_dclrcion,
														528,
														2289,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaración. ' || sqlerrm;
				return;
		end;
		
	end prc_rg_dtlle_frmlrio_324;	

/************************************************Procedimiento No. 30**********************************************************/	
	
procedure prc_rg_dclrcnes_encbzdo	(	 p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_id_dclrcion			out	number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as
										 
		v_json_object_t					json_object_t := json_object_t();
		
		v_hmlgcion          			pkg_mg_migracion.r_hmlgcion;
		v_cdgo_dclrcn_tpo				varchar2(5);
		v_json							clob;
		v_id_dclrcn_tpo     			number;
		v_id_impsto						number;
		v_id_impsto_sbmpsto				number;
		v_cdgo_prdcdad					varchar2(5);
		v_id_prdo						number;
		v_id_dclrcion_tpo_vgncia		number;
		v_id_dclrcion_vgncia_frmlrio	number;
		v_id_frmlrio					number;
		v_id_sjto_impsto				number;
		v_id_dclrcion_uso				number;
		v_type_dclrcnes					pkg_mg_migracion_dcl2.type_dclrcnes;
		v_id_dclrcion_crrccion			number;
		
		c_dclrcnes						sys_refcursor;
		v_table_dclrcnes				pkg_mg_migracion_dcl2.table_dclrcnes;
		
	begin
		o_cdgo_rspsta := 0;
		
		--Carga los Datos de la Homologación
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);
		
		--Se homologa el codigo tipo de declaración
		begin
			v_cdgo_dclrcn_tpo := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 1,
																	  p_vlor    => p_type_dclrcnes.clmna1,
																	  p_hmlgcion=> v_hmlgcion);
		exception
			when others then
				o_cdgo_rspsta   := 1;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo homologarse el tipo de declaración. ' || sqlerrm;
				return;
		end;
		
		--Se validan los datos de la declaracion para obtener la vigencia formulario
		begin
			pkg_mg_migracion_dcl.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
															 p_id_prcso_instncia	=>	p_id_prcso_instncia,
															 p_id_usrio          	=>	p_id_usrio,
															 p_cdgo_clnte        	=>	p_cdgo_clnte,
															 p_type_dclrcnes		=>	p_type_dclrcnes,
															 o_json					=>	v_json,
															 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
															 o_mnsje_rspsta			=>	o_mnsje_rspsta);
															 
			if (o_cdgo_rspsta <> 0) then
				o_cdgo_rspsta   := 2;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaración. ' || sqlerrm;
				return;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaración. ' || sqlerrm;
				return;
		end;
		
		v_id_dclrcn_tpo 			:= json_object_t(v_json).get_number('id_dclrcn_tpo');
		v_id_impsto					:= json_object_t(v_json).get_number('id_impsto');
		v_id_impsto_sbmpsto			:= json_object_t(v_json).get_number('id_impsto_sbmpsto');
		v_cdgo_prdcdad				:= json_object_t(v_json).get_string('cdgo_prdcdad');
		v_id_prdo					:= json_object_t(v_json).get_number('id_prdo');
		v_id_dclrcion_tpo_vgncia	:= json_object_t(v_json).get_number('id_dclrcion_tpo_vgncia');
		v_id_dclrcion_vgncia_frmlrio:= json_object_t(v_json).get_number('id_dclrcion_vgncia_frmlrio');
		v_id_frmlrio				:= json_object_t(v_json).get_number('id_frmlrio');
		v_id_sjto_impsto			:= json_object_t(v_json).get_number('id_sjto_impsto');
		
		--se valida el uso de la declaración
		begin
			select  a.id_dclrcion_uso
			into    v_id_dclrcion_uso
			from    gi_d_declaraciones_uso a
			where   a.cdgo_clnte        =   p_cdgo_clnte
			and     a.cdgo_dclrcion_uso =   to_char(p_type_dclrcnes.clmna7);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el uso de la declaración. ' || sqlerrm;
				return;
		end;
		
		--En caso de ser necesario se valida la declaracion que se corrige
		if (p_type_dclrcnes.clmna8 is not null) then
			begin
				select  a.id_dclrcion
				into	v_id_dclrcion_crrccion
				from    gi_g_declaraciones a
				where   a.id_dclrcion_vgncia_frmlrio=   v_id_dclrcion_vgncia_frmlrio
				and     a.nmro_cnsctvo              =   to_char(p_type_dclrcnes.clmna8);
			exception
				when others then
					o_cdgo_rspsta   := 5;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la declaración que se corrige. ' || sqlerrm;
					return;
			end;
		end if;
		
		--Se registra la declaracion
		begin
			insert into gi_g_declaraciones	(
												id_dclrcion_vgncia_frmlrio,
												cdgo_clnte,
												id_impsto,
												id_impsto_sbmpsto,
												id_sjto_impsto,
												vgncia,
												id_prdo,
												nmro_cnsctvo,
												cdgo_dclrcion_estdo,
												id_dclrcion_uso,
												id_dclrcion_crrccion,
												fcha_rgstro,
												fcha_prsntcion,
												bse_grvble,
												vlor_ttal,
												vlor_pago
											)
									values	(
												v_id_dclrcion_vgncia_frmlrio,
												p_cdgo_clnte,
												v_id_impsto,
												v_id_impsto_sbmpsto,
												v_id_sjto_impsto,
												to_char(p_type_dclrcnes.clmna2),
												v_id_prdo,
												to_char(p_type_dclrcnes.clmna5),
												to_char(p_type_dclrcnes.clmna6),
												v_id_dclrcion_uso,
												v_id_dclrcion_crrccion,
												to_timestamp(to_char(p_type_dclrcnes.clmna9), 'DD/MM/YYYY HH24:MI:SS'),
												to_timestamp(to_char(p_type_dclrcnes.clmna10), 'DD/MM/YYYY HH24:MI:SS'),
												to_number(p_type_dclrcnes.clmna13),
												to_number(p_type_dclrcnes.clmna14),
												0
											) returning id_dclrcion into o_id_dclrcion;
		exception
			when others then
					o_cdgo_rspsta   := 10;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaración. ' || sqlerrm;
					return;
		end;
		
		--Se obtiene de forma temporal la declaracion
		--Cuando se quiten los dblink debe hacer por medio del returning
		/*begin
			select  a.id_dclrcion
			into	o_id_dclrcion
			from    gi_g_declaraciones	a
			where   a.cdgo_clnte    =   p_cdgo_clnte
			and     a.nmro_cnsctvo  =   to_char(p_type_dclrcnes.clmna5);
		exception
			when others then
					o_cdgo_rspsta   := 11;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la declaración registrada. ' || sqlerrm;
					return;
		end;*/
		
		/*
		==============================
		Detalle de la declaracion segun formulario
		*/
		
		--Se registra el el detalle
		if (v_id_frmlrio = 324) then
			begin
				pkg_mg_migracion_dcl.prc_rg_dtlle_frmlrio_324	(p_id_entdad			=>	p_id_entdad,
																 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);
				 if (o_cdgo_rspsta <> 0) then
					o_cdgo_rspsta   := 11;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el detalle la declaración. ' || sqlerrm || chr(13) ||
					o_mnsje_rspsta;
					return;
				 end if;
			exception
				when others then
					o_cdgo_rspsta   := 12;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el detalle la declaración. ' || sqlerrm;
					return;
			end;
		end if;
				
		--Se marca la declaracion que inserta en intermedia
		begin
			for c_item in	(
								select  a.id_intrmdia
								from    json_table  (p_type_dclrcnes.items, '$[*]' columns (
																			id_intrmdia number path '$.id_intrmdia'
																		)
													)   a
							)
			loop
				update	MIGRA.mg_g_intermedia_declara   a
				set		clmna30				= 	o_id_dclrcion
				where	a.id_intrmdia		=	c_item.id_intrmdia;
			end loop;
		exception
			when others then
				o_cdgo_rspsta   := 11;
				o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo marcarse en la tabla intermedia. ' || sqlerrm;
				return;
		end;
		
		--Se recorren las declaraciones de correccion
		for c_dclrcnes in	(
								select  min(a.id_intrmdia) id_intrmdia,
										a.clmna1,	--Código Declaración
										a.clmna2,	--Vigencia
										a.clmna3,	--Código del periodo
										a.clmna4,	--Identificación del declarante
										a.clmna5,	--Numero de declaración
										a.clmna6,	--Código de estado de la declaración
										a.clmna7,	--Código de uso de la declaración
										a.clmna8,	--Numero de declaración de corrección
										a.clmna9,	--Fecha de registro de la declaración
										a.clmna10,	--Fecha de presentación de la declaración
										a.clmna11,	--Fecha proyectada de presentación de la declaración
										a.clmna12,	--Fecha de aplicación de la declaración
										a.clmna13,	--Base gravable de la declaración
										a.clmna14,	--Valor total de la declaración
										a.clmna15,	--Valor pago de la declaración
										json_arrayagg(
														json_object(
																	'id_intrmdia'   value   a.id_intrmdia,
																	'clmna16'       value   a.clmna16,		--Reglón Declaración
																	'clmna17'       value   a.clmna17,		--Descripción Renglón Declaración
																	'clmna18'       value   a.clmna18		--Valor Renglón Declaración
																	returning clob
																   )
														returning clob
													 ) as items
								from    MIGRA.mg_g_intermedia_declara   a
								where   a.cdgo_clnte		=   p_cdgo_clnte
								and     a.id_entdad 		=   p_id_entdad
								and     a.cdgo_estdo_rgstro =	'L'
								and		a.clmna4			=	to_char(p_type_dclrcnes.clmna4)
								and     a.clmna8    		=	to_char(p_type_dclrcnes.clmna5)
								group by    a.clmna1,
											a.clmna2,
											a.clmna3,
											a.clmna4,
											a.clmna5,
											a.clmna6,
											a.clmna7,
											a.clmna8,
											a.clmna9,
											a.clmna10,
											a.clmna11,  
											a.clmna12,
											a.clmna13,
											a.clmna14,
											a.clmna15
							)
		loop
			--Se setea a nivel de vairable el registro que corresponde a la declaración
			begin
				select	to_number(c_dclrcnes.id_intrmdia),
						to_clob(c_dclrcnes.clmna1),
						to_clob(c_dclrcnes.clmna2),
						to_clob(c_dclrcnes.clmna3),
						to_clob(c_dclrcnes.clmna4),
						to_clob(c_dclrcnes.clmna5),
						to_clob(c_dclrcnes.clmna6),
						to_clob(c_dclrcnes.clmna7),
						to_clob(c_dclrcnes.clmna8),
						to_clob(c_dclrcnes.clmna9),
						to_clob(c_dclrcnes.clmna10),
						to_clob(c_dclrcnes.clmna11),
						to_clob(c_dclrcnes.clmna12),
						to_clob(c_dclrcnes.clmna13),
						to_clob(c_dclrcnes.clmna14),
						to_clob(c_dclrcnes.clmna15),
						to_clob(c_dclrcnes.items)
				into	v_type_dclrcnes
				from	dual;
			exception
				when others then
					o_cdgo_rspsta   := 13;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo setearse a nivel de vairable el registro que corresponde a la declaración. ' || sqlerrm;
			end;
			
			--Se busca la correccion de la declaración
			begin
				pkg_mg_migracion_dcl.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
																 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_type_dclrcnes		=>	v_type_dclrcnes,
																 o_id_dclrcion			=>	v_id_dclrcion_crrccion,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);
				
				if (o_cdgo_rspsta <> 0) then
					o_cdgo_rspsta   := 14;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de corrección. ' || sqlerrm;
				end if;
			exception
				when others then
					o_cdgo_rspsta   := 15;
					o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de corrección. ' || sqlerrm;
			end;
			
			--En caso de errores se hace rollback y retorna
			if (o_cdgo_rspsta <> 0) then
				
				rollback;
				
				for c_item in	(
									select  a.id_intrmdia
									from    json_table  (v_type_dclrcnes.items, '$[*]' columns (
																				id_intrmdia number path '$.id_intrmdia'
																			)
														)   a
								)
				loop
					update	MIGRA.mg_g_intermedia_declara   a
					set		a.cdgo_estdo_rgstro	=	'E',
							clmna48				= 	o_cdgo_rspsta,
							clmna49				= 	o_mnsje_rspsta
					where	a.id_intrmdia		=	c_item.id_intrmdia;
				end loop;
				
				commit;
				return;
			else
				for c_item in	(
									select  a.id_intrmdia
									from    json_table  (v_type_dclrcnes.items, '$[*]' columns (
																				id_intrmdia number path '$.id_intrmdia'
																			)
														)   a
								)
				loop
					update	MIGRA.mg_g_intermedia_declara   a
					set		a.cdgo_estdo_rgstro	=	'S'
					where	a.id_intrmdia		=	c_item.id_intrmdia;
				end loop;
			end if;
		end loop;
	end prc_rg_dclrcnes_encbzdo;		
/******************************* Procedimiento 10 ******************************/

procedure prc_rg_declaraciones_ICA2     (p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 o_ttal_extsos	    	out number,
										 o_ttal_error	    	out number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as
										 
		v_hmlgcion          			pkg_mg_migracion.r_hmlgcion;
    
        v_errors            			pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
		v_exitos						pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        
        c_dclrcnes						sys_refcursor;
		v_table_dclrcnes				pkg_mg_migracion_dcl2.table_dclrcnes;
		
		v_json							clob;
		v_id_dclrcn_tpo     			number;
		v_id_impsto						number;
		v_id_impsto_sbmpsto				number;
		v_cdgo_prdcdad					varchar2(5);
		v_id_prdo						number;
		v_id_dclrcion_tpo_vgncia		number;
		v_id_dclrcion_vgncia_frmlrio	number;
		v_id_frmlrio					number;
		v_id_sjto_impsto				number;
		v_id_dclrcion_uso				number;
		v_id_dclrcion_crrccion			number;
		v_id_dclrcion					number;
		
		v_cntdor_commit					number := 0;
	begin
		o_cdgo_rspsta 	:= 0;
		o_ttal_extsos 	:= 0;
        o_ttal_error 	:= 0;
        
        --Carga los Datos de la Homologación
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);
														   
		--Se recorren las declaraciones iniciales
		open c_dclrcnes for	select  min(a.id_intrmdia) id_intrmdia,
									a.clmna1,	--Código Declaración
									a.clmna2,	--Vigencia
									a.clmna3,	--Código del periodo
									a.clmna4,	--Identificación del declarante
									a.clmna5,	--Numero de declaración
									a.clmna6,	--Código de estado de la declaración
									a.clmna7,	--Código de uso de la declaración
									a.clmna8,	--Numero de declaración de corrección
									a.clmna9,	--Fecha de registro de la declaración
									a.clmna10,	--Fecha de presentación de la declaración
									a.clmna11,	--Fecha proyectada de presentación de la declaración
									a.clmna12,	--Fecha de aplicación de la declaración
									a.clmna13,	--Base gravable de la declaración
									a.clmna14,	--Valor total de la declaración
									a.clmna15,	--Valor pago de la declaración
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglón Declaración
																'clmna17'       value   a.clmna17,		--Descripción Renglón Declaración
																'clmna18'       value   a.clmna18		--Valor Renglón Declaración
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.mg_g_intermedia_declara   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1    		in  ('4001', '5001')
							and     a.clmna8    		is  null
							group by    a.clmna1,
										a.clmna2,
										a.clmna3,
										a.clmna4,
										a.clmna5,
										a.clmna6,
										a.clmna7,
										a.clmna8,
										a.clmna9,
										a.clmna10,
										a.clmna11,  
										a.clmna12,
										a.clmna13,
										a.clmna14,
										a.clmna15
							/*order by 1 fetch first 1 rows only*/;
			
			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 300;
				exit when v_table_dclrcnes.count = 0;				
				for i in 1..v_table_dclrcnes.count loop
				
					v_json						:= null;
					v_id_dclrcn_tpo 			:= null;
					v_id_impsto					:= null;
					v_id_impsto_sbmpsto			:= null;
					v_cdgo_prdcdad				:= null;
					v_id_prdo					:= null;
					v_id_dclrcion_tpo_vgncia	:= null;
					v_id_dclrcion_vgncia_frmlrio:= null;
					v_id_frmlrio				:= null;
					v_id_sjto_impsto			:= null;
					v_id_dclrcion_uso			:= null;
					v_id_dclrcion_crrccion		:= null;
					v_id_dclrcion				:= null;
					
					--Se validan los datos de la declaracion para obtener la vigencia formulario
					begin
						pkg_mg_migracion_dcl.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
																		 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																		 p_id_usrio          	=>	p_id_usrio,
																		 p_cdgo_clnte        	=>	p_cdgo_clnte,
																		 p_type_dclrcnes		=>	v_table_dclrcnes(i),
																		 o_json					=>	v_json,
																		 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																		 o_mnsje_rspsta			=>	o_mnsje_rspsta);
																		 
						if (o_cdgo_rspsta <> 0) then
							rollback;
							o_cdgo_rspsta   := 1;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaración. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;
							
							update  migra.mg_g_intermedia_declara
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;
							
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
						end if;
					exception
						when others then
							rollback;
							o_cdgo_rspsta   := 2.5;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaración. ' || sqlerrm;
							
							update  migra.mg_g_intermedia_declara
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;
							
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
					
					v_id_dclrcn_tpo 			:= json_object_t(v_json).get_number('id_dclrcn_tpo');
					v_id_impsto					:= json_object_t(v_json).get_number('id_impsto');
					v_id_impsto_sbmpsto			:= json_object_t(v_json).get_number('id_impsto_sbmpsto');
					v_cdgo_prdcdad				:= json_object_t(v_json).get_string('cdgo_prdcdad');
					v_id_prdo					:= json_object_t(v_json).get_number('id_prdo');
					v_id_dclrcion_tpo_vgncia	:= json_object_t(v_json).get_number('id_dclrcion_tpo_vgncia');
					v_id_dclrcion_vgncia_frmlrio:= json_object_t(v_json).get_number('id_dclrcion_vgncia_frmlrio');
					v_id_frmlrio				:= json_object_t(v_json).get_number('id_frmlrio');
					v_id_sjto_impsto			:= json_object_t(v_json).get_number('id_sjto_impsto');
					
					--Se valida si existe una declaración de ese sujeto impuesto en esa vigencia formulario
					begin
						select  a.id_dclrcion
						into	v_id_dclrcion
						from    gi_g_declaraciones a
						where   a.id_dclrcion_vgncia_frmlrio    =   v_id_dclrcion_vgncia_frmlrio
						and     a.id_sjto_impsto                =   v_id_sjto_impsto
						and     a.cdgo_dclrcion_estdo           not in ('REG', 'AUT', 'ANU')
						order by a.fcha_rgstro fetch next 1 rows only;
					exception
						when no_data_found then
							null;
						when others then
							rollback;
							o_cdgo_rspsta   := 3;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse si existe una declaración de ese sujeto impuesto en esa vigencia formulario. ' || sqlerrm;
							
							update  migra.mg_g_intermedia_declara
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;
							
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
					
					--Si existe una declaracion para la vigencia formularios se marcan como error los 
					--registros relacionados a la declaracion y se continua con la siguiente
					if (v_id_dclrcion is not null) then
						begin
							rollback;
							
							for c_item in	(
												select  a.id_intrmdia
												from    json_table  (v_table_dclrcnes(i).items, '$[*]' columns (
																							id_intrmdia number path '$.id_intrmdia'
																						)
																	)   a
											)
							loop
								begin
									update	MIGRA.mg_g_intermedia_declara   a
									set		a.clmna50			=	v_id_dclrcion,
											a.cdgo_estdo_rgstro	=	'E'
									where	a.id_intrmdia		=	c_item.id_intrmdia;
									
									commit;
									
									o_cdgo_rspsta   := 4;
									o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo y ha sido marcada en la columna 50. ' || sqlerrm;
									
									update  migra.mg_g_intermedia_declara
									set     clmna48		= o_cdgo_rspsta,
											clmna49		= o_mnsje_rspsta
									where   id_intrmdia = c_item.id_intrmdia;
									commit;
									
									v_errors.extend;  
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_item.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								exception
									when others then
										o_cdgo_rspsta   := 5;
										o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;
										v_errors.extend;  
										v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_item.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
										continue;
								end;
							end loop;
							
							continue;
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 6;
								o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;
								
								update  migra.mg_g_intermedia_declara
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;
							
								v_errors.extend;  
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								continue;
						end;
					end if;
					
					commit;
				end loop;
			end loop;
										
		close c_dclrcnes;
		
		--Se recorren las declaraciones iniciales sin problemas
		open c_dclrcnes for	select  min(a.id_intrmdia) id_intrmdia,
									a.clmna1,	--Código Declaración
									a.clmna2,	--Vigencia
									a.clmna3,	--Código del periodo
									a.clmna4,	--Identificación del declarante
									a.clmna5,	--Numero de declaración
									a.clmna6,	--Código de estado de la declaración
									a.clmna7,	--Código de uso de la declaración
									a.clmna8,	--Numero de declaración de corrección
									a.clmna9,	--Fecha de registro de la declaración
									a.clmna10,	--Fecha de presentación de la declaración
									a.clmna11,	--Fecha proyectada de presentación de la declaración
									a.clmna12,	--Fecha de aplicación de la declaración
									a.clmna13,	--Base gravable de la declaración
									a.clmna14,	--Valor total de la declaración
									a.clmna15,	--Valor pago de la declaración
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglón Declaración
																'clmna17'       value   a.clmna17,		--Descripción Renglón Declaración
																'clmna18'       value   a.clmna18		--Valor Renglón Declaración
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.mg_g_intermedia_declara   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1    		in  ('4001', '5001')-- añadir tipos de declaraciones 4001 4002 5001 5002
							and     a.clmna8    		is  null
							group by    a.clmna1,
										a.clmna2,
										a.clmna3,
										a.clmna4,
										a.clmna5,
										a.clmna6,
										a.clmna7,
										a.clmna8,
										a.clmna9,
										a.clmna10,
										a.clmna11,  
										a.clmna12,
										a.clmna13,
										a.clmna14,
										a.clmna15
							/*order by 1 fetch first 10 rows only*/;
			
			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 300;
				exit when v_table_dclrcnes.count = 0;
				for i in 1..v_table_dclrcnes.count loop
					
					begin
						pkg_mg_migracion_dcl.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
																		 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																		 p_id_usrio          	=>	p_id_usrio,
																		 p_cdgo_clnte        	=>	p_cdgo_clnte,
																		 p_type_dclrcnes		=>	v_table_dclrcnes(i),
																		 o_id_dclrcion			=>	v_id_dclrcion_crrccion,
																		 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																		 o_mnsje_rspsta			=>	o_mnsje_rspsta);
						
						if (o_cdgo_rspsta <> 0) then
							rollback;
							o_cdgo_rspsta   := 7;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaración. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;
												
							update  migra.mg_g_intermedia_declara
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;
							
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end if;
					exception
						when others then
							rollback;
							o_cdgo_rspsta   := 8;
							o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de corrección. ' || sqlerrm;
							
							update  migra.mg_g_intermedia_declara
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;
							
							v_errors.extend;  
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					end;
					
					--Se marcan las declaraciones con error o exito
					for c_item in	(
										select  a.id_intrmdia
										from    json_table  (v_table_dclrcnes(i).items, '$[*]' columns (
																					id_intrmdia number path '$.id_intrmdia'
																				)
															)   a
									)
					loop
						update	MIGRA.mg_g_intermedia_declara   a
						set		a.cdgo_estdo_rgstro	=	case
															when o_cdgo_rspsta = 0 then 'S'
															else 'E'
														end,
								a.clmna49			=	o_cdgo_rspsta,
								a.clmna50			=	o_mnsje_rspsta
						where	a.id_intrmdia		=	c_item.id_intrmdia;
					end loop;
					
					commit;
					
				end loop;
			end loop;
										
		close c_dclrcnes;
		
		--Se actualiza el estado de los registros procesados en la tabla migra.mg_g_intermedia_declara
        /*begin
            update  migra.mg_g_intermedia_declara   a
            set     a.cdgo_estdo_rgstro =   'S'
            where   a.cdgo_clnte        =   p_cdgo_clnte
            and     id_entdad           =   p_id_entdad
			and     cdgo_estdo_rgstro   =   'L'
			and     a.clmna1    		in  ('2001', '2002');
        exception
            when others then
                o_cdgo_rspsta   := 9;
                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;*/
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        begin
			delete muerto;
            forall i in 1 .. o_ttal_error
			insert into muerto	(
									n_001,					n_002,						c_001
								)
						 values (
									p_id_prcso_instncia,	v_errors(i).id_intrmdia,	v_errors(i).mnsje_rspsta
								);
								
			/*insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
        exception
            when others then
                o_cdgo_rspsta   := 10;
                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;
        
        --Se actualizan en la tabla migra.mg_g_intermedia_declara como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.mg_g_intermedia_declara   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 11;
                o_mnsje_rspsta  := 'Código: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;  
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;
        
        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
		
		
	end prc_rg_declaraciones_ICA2;
	



end pkg_mg_migracion_dcl;-- Fin del Paquete

/
