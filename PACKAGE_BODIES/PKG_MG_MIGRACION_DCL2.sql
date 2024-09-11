--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_DCL2
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_DCL2" as

	/*Up para migrar establecimientos*/
    procedure prc_mg_sjtos_impsts_estblcmnts(p_id_entdad			in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2) as

        v_errors                r_errors := r_errors();
        --c_intrmdia              pkg_mg_migracion.t_mg_g_intermedia_otimp_sujetos_cursor;

        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;

        v_hmlgcion              pkg_mg_migracion.r_hmlgcion;

        c_estblcmntos_cursor    pkg_mg_migracion.t_mg_g_intermedia_tab;

        v_cntdor                number;

        v_id_sjto               number;
        v_id_pais_esblcmnto     number;
        v_id_dprtmnto_esblcmnto number;
        v_id_mncpio_esblcmnto   number;

        v_id_pais_esblcmnto_ntfccion        number;
        v_id_dprtmnto_esblcmnto_ntfccion    number;
        v_id_mncpio_esblcmnto_ntfccion      number;
        v_id_sjto_estdo                     number;
        v_id_impsto                         number;
        v_id_sjto_impsto                    number;

        v_id_prsna                          number;
        v_id_sjto_tpo                       number;
        v_id_actvdad_ecnmca                 number;

        v_id_trcro_estblcmnto               number;

        v_json_rspnsbles                    json_array_t;
        v_id_trcro_rspnsble                 number;
        v_id_pais_rspnsble                  number;
        v_id_dprtmnto_rspnsble              number;
        v_id_mncpio_rspnsble                number;
    begin
        o_ttal_extsos := 0;
        o_ttal_error  := 0;

        --Se abre el cursor que tiene los registros a procesar
        --open c_intrmdia for select  /*+ parallel(a, id_entdad) */ *
        --                    from    migra.mg_g_intermedia_otimp_sujetos   a
        --                    where   a.cdgo_clnte        =   p_cdgo_clnte
        --                    and     a.id_entdad         =   p_id_entdad
        --                    and     a.cdgo_estdo_rgstro =   'L';
		begin
			select  *
			into    v_cdgo_clnte_tab
			from    v_df_s_clientes a
			where   a.cdgo_clnte  =   p_cdgo_clnte;
		exception
			when others then
				o_cdgo_rspsta   := 1;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Problemas al consultar el cliente ' || sqlerrm;
				return;
		end;

		--Carga los Datos de la Homologacion
		v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
														   p_id_entdad  =>  p_id_entdad);

		--Cursor del establecimiento
		for c_estblcmntos in (
								select  /*+ parallel(a, clmna2) */
										min(a.id_intrmdia) id_intrmdia,
										--si_c_sujetos
										a.clmna2,   --Identificacion del establecimiento IDNTFCCION
										a.clmna3,   --Identificacion del establecimiento anterior IDNTFCCION_ANTRIOR
										a.clmna4,   --Pais del establecimiento CDGO_PAIS
										a.clmna5,   --Departamento del establecimiento CDGO_DPRTMNTO
										a.clmna6,   --Municipio del Establecimiento CDGO_MNCPIO
										a.clmna7,   --Direccion del establecimiento DRCCION
										a.clmna8,   --Fecha de ingreso del establecimiento Por defecto sysdate FCHA_INGRSO
										a.clmna9,   --Codigo postal del establecimiento CDGO_PSTAL
										--si_i_sujetos_impuesto
										a.clmna10,  --Codigo del impuesto CDGO_IMPSTO
										a.clmna11,  --Pais de notificacion del establecimiento CDGO_PAIS
										a.clmna12,  --Departamento de notificacion del establecimiento CDGO_DPRTMNTO
										a.clmna13,  --Municipio notificacion del Establecimiento CDGO_MNCPIO
										a.clmna14,  --Direccion de notificacion del establecimiento
										a.clmna15,  --Email del establecimiento EMAIL
										a.clmna16,  --Telefono del Establecimiento TLFNO
										a.clmna17,  --Codigo estado de establecimiento CDGO_SJTO_ESTDO
										a.clmna18,  --Fecha ultima novedad del establecimiento FCHA_ULTMA_NVDAD
										a.clmna19,  --Fecha cancelacion del establecimiento FCHA_CNCLCION
										--si_i_personas
										a.clmna1,   --Tipo identificacion del establecimiento CDGO_IDNTFCCION_TPO
										a.clmna20,  --Tipo de establecimiento TPO_PRSNA
										a.clmna21,  --Primer nombre establecimiento PRMER_NMBRE
										a.clmna22,  --Segundo nombre establecimiento SGNDO_NMBRE
										a.clmna23,  --Primer apellido establecimiento PRMER_APLLDO
										a.clmna24,  --Segundo apellido establecimiento SGNDO_APLLDO
										a.clmna25,  --Numero registro camara de comercio establecimiento NMRO_RGSTRO_CMRA_CMRCIO
										a.clmna26,  --Fecha registro camara de comercio establecimiento FCHA_RGSTRO_CMRA_CMRCIO
										a.clmna27,  --Fecha inicio de actividades establecimiento FCHA_INCIO_ACTVDDES
										a.clmna28,  --Numero sucursales establecimiento NMRO_SCRSLES
										a.clmna29,  --Codigo tipo de sujeto del establecimiento CDGO_SJTO_TPO
										a.clmna30,  --Codigo actividad economica del establecimiento CDGO_ACTVDAD_ECNMCA,
										json_arrayagg(
											json_object(
														'id_intrmdia'	value a.id_intrmdia,
														'clmna31' 		value	a.clmna31,
														'clmna32' 		value	a.clmna32,
														'clmna33' 		value	a.clmna33,
														'clmna34' 		value	a.clmna34,
														'clmna35' 		value	a.clmna35,
														'clmna36' 		value	a.clmna36,
														'clmna37' 		value	a.clmna37,
														'clmna38' 		value	a.clmna38,
														'clmna39' 		value	a.clmna39,
														'clmna40' 		value	a.clmna40,
														'clmna41' 		value	a.clmna41,
														'clmna42' 		value	a.clmna42,
														'clmna43' 		value	a.clmna43,
														'clmna44' 		value	a.clmna44,
														'clmna45' 		value	a.clmna45,
														'clmna46' 		value	a.clmna46,
														'clmna47' 		value	a.clmna47
														returning clob
													   )
													   returning clob
													) json_rspnsbles
								from    migra.MG_G_INTERMEDIA_ICA_ESTABLEC   a
								where   a.cdgo_clnte        =   p_cdgo_clnte
								and     a.id_entdad         =   p_id_entdad
								and     a.cdgo_estdo_rgstro =   'L'
								and		a.clmna10			=	'ICA'
								group by    --si_c_sujetos
											a.clmna2,   --Identificacion del establecimiento IDNTFCCION
											a.clmna3,   --Identificacion del establecimiento anterior IDNTFCCION_ANTRIOR
											a.clmna4,   --Pais del establecimiento CDGO_PAIS
											a.clmna5,   --Departamento del establecimiento CDGO_DPRTMNTO
											a.clmna6,   --Municipio del Establecimiento CDGO_MNCPIO
											a.clmna7,   --Direccion del establecimiento DRCCION
											a.clmna8,   --Fecha de ingreso del establecimiento Por defecto sysdate FCHA_INGRSO
											a.clmna9,   --Codigo postal del establecimiento CDGO_PSTAL
											--si_i_sujetos_impuesto
											a.clmna10,  --Codigo del impuesto CDGO_IMPSTO
											a.clmna11,  --Pais de notificacion del establecimiento CDGO_PAIS
											a.clmna12,  --Departamento de notificacion del establecimiento CDGO_DPRTMNTO
											a.clmna13,  --Municipio notificacion del Establecimiento CDGO_MNCPIO
											a.clmna14,  --Direccion de notificacion del establecimiento
											a.clmna15,  --Email del establecimiento EMAIL
											a.clmna16,  --Telefono del Establecimiento TLFNO
											a.clmna17,  --Codigo estado de establecimiento CDGO_SJTO_ESTDO
											a.clmna18,  --Fecha ultima novedad del establecimiento FCHA_ULTMA_NVDAD
											a.clmna19,  --Fecha cancelacion del establecimiento FCHA_CNCLCION
											--si_i_personas
											a.clmna1,   --Tipo identificacion del establecimiento CDGO_IDNTFCCION_TPO
											a.clmna20,  --Tipo de establecimiento TPO_PRSNA
											a.clmna21,  --Primer nombre establecimiento PRMER_NMBRE
											a.clmna22,  --Segundo nombre establecimiento SGNDO_NMBRE
											a.clmna23,  --Primer apellido establecimiento PRMER_APLLDO
											a.clmna24,  --Segundo apellido establecimiento SGNDO_APLLDO
											a.clmna25,  --Numero registro camara de comercio establecimiento NMRO_RGSTRO_CMRA_CMRCIO
											a.clmna26,  --Fecha registro camara de comercio establecimiento FCHA_RGSTRO_CMRA_CMRCIO
											a.clmna27,  --Fecha inicio de actividades establecimiento FCHA_INCIO_ACTVDDES
											a.clmna28,  --Numero sucursales establecimiento NMRO_SCRSLES
											a.clmna29,  --Codigo tipo de sujeto del establecimiento CDGO_SJTO_TPO
											a.clmna30  --Codigo actividad economica del establecimiento CDGO_ACTVDAD_ECNMCA
							 )
		loop
			--Se limpian las variables
			v_id_sjto := null;

			v_id_sjto               := null;
			v_id_pais_esblcmnto     := null;
			v_id_dprtmnto_esblcmnto := null;
			v_id_mncpio_esblcmnto   := null;

			v_id_pais_esblcmnto_ntfccion        := null;
			v_id_dprtmnto_esblcmnto_ntfccion    := null;
			v_id_mncpio_esblcmnto_ntfccion      := null;
			v_id_sjto_estdo                     := null;
			v_id_impsto                         := null;
			v_id_sjto_impsto                    := null;

			v_id_prsna                          := null;
			v_id_sjto_tpo                       := null;
			v_id_actvdad_ecnmca                 := null;

			v_id_trcro_estblcmnto               := null;

			--REGISTRO EN SI_C_SUJETOS
			--Se valida si existe el SI_C_SUJETOS
			begin
				select  a.id_sjto
				into    v_id_sjto
				from    si_c_sujetos    a
				where   a.cdgo_clnte    =   p_cdgo_clnte
				and     a.idntfccion    =   c_estblcmntos.clmna2;
			exception
				when no_data_found then
					null;
				when others then
					o_cdgo_rspsta   := 2;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_sujetos. ' || sqlerrm;
					--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
					v_errors.extend;
					v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se continua con el proceso de SI_C_SUJETOS si no existe
			if (v_id_sjto is null) then
				if (c_estblcmntos.clmna3 is null) then --IDNTFCCION_ANTRIOR
					c_estblcmntos.clmna3 := c_estblcmntos.clmna2;
				end if;

				--Se valida el pais el departamento y el municipio
				if (c_estblcmntos.clmna4 is null) then --Pais
					v_id_pais_esblcmnto := v_cdgo_clnte_tab.id_pais;
				else
					begin
						select  a.id_pais
						into    v_id_pais_esblcmnto
						from    df_s_paises a
						where   a.cdgo_pais =   c_estblcmntos.clmna4;
					exception
						when others then
							o_cdgo_rspsta   := 3;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;

				if (c_estblcmntos.clmna5 is null) then --Departamento
					v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
				else
					begin
						select  a.id_dprtmnto
						into    v_id_dprtmnto_esblcmnto
						from    df_s_departamentos  a
						where   a.id_pais       =   v_id_pais_esblcmnto
						and     a.cdgo_dprtmnto =   c_estblcmntos.clmna5;
					exception
						when others then
							o_cdgo_rspsta   := 4;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;
				if (c_estblcmntos.clmna6 is null) then --Municipio
					v_id_mncpio_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
				else
					begin
						select  a.id_mncpio
						into    v_id_mncpio_esblcmnto
						from    df_s_municipios a
						where   a.id_dprtmnto   =   v_id_dprtmnto_esblcmnto
						and     a.cdgo_mncpio   =   c_estblcmntos.clmna6;
					exception
						when no_data_found then
							v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
							v_id_mncpio_esblcmnto := v_cdgo_clnte_tab.id_mncpio;
						when others then
							o_cdgo_rspsta   := 5;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;

				--Se inserta el establecimiento en si_c_sujetos
				begin
					insert into si_c_sujetos (cdgo_clnte,
											  idntfccion,
											  idntfccion_antrior,
											  id_pais,
											  id_dprtmnto,
											  id_mncpio,
											  drccion,
											  fcha_ingrso,
											  cdgo_pstal,
											  estdo_blqdo)
									 values  (p_cdgo_clnte,
											  c_estblcmntos.clmna2,
											  c_estblcmntos.clmna3,
											  v_id_pais_esblcmnto,
											  v_id_dprtmnto_esblcmnto,
											  v_id_mncpio_esblcmnto,
											  c_estblcmntos.clmna7,
											  systimestamp,
											  c_estblcmntos.clmna9,
											  'N') returning id_sjto into v_id_sjto;
				exception
					when others then
						o_cdgo_rspsta   := 6;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_sujetos del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
			end if;

			--REGISTRO EN SI_I_SUJETOS_IMPUESTO
			--Se valida el impuesto
			begin
				c_estblcmntos.clmna10 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 10,
																			  p_vlor    => c_estblcmntos.clmna10,
																			  p_hmlgcion=> v_hmlgcion);
				select  a.id_impsto
				into    v_id_impsto
				from    df_c_impuestos  a
				where   a.cdgo_clnte    =   p_cdgo_clnte
				and     a.cdgo_impsto   =   c_estblcmntos.clmna10;
			exception
				when others then
					rollback;
					o_cdgo_rspsta   := 7;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el impuesto del establecimiento. ' || sqlerrm;
					--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
					v_errors.extend;
					v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se valida si existe el si_i_sujetos_impuesto
			begin
				select  a.id_sjto_impsto
				into    v_id_sjto_impsto
				from    si_i_sujetos_impuesto   a
				where   a.id_sjto   =   v_id_sjto
				and     a.id_impsto =   v_id_impsto;
			exception
				when no_data_found then
					null;
				when others then
					rollback;
					o_cdgo_rspsta   := 8;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_sujetos_impuesto. ' || sqlerrm;
					--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
					v_errors.extend;
					v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;


		   --Se continua con el proceso de SI_I_SUJETOS_IMPUESTO si no existe
			if (v_id_sjto_impsto is null) then
				--Se valida el pais el departamento y el municipio de notificacion
				if (c_estblcmntos.clmna11 is null) then --Pais de notificacion
					v_id_pais_esblcmnto_ntfccion := v_id_pais_esblcmnto;
				else
					begin
						select  a.id_pais
						into    v_id_pais_esblcmnto_ntfccion
						from    df_s_paises a
						where   a.cdgo_pais =   c_estblcmntos.clmna11;
					exception
						when others then
							rollback;
							o_cdgo_rspsta   := 9;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais de notificacion del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;

				if (c_estblcmntos.clmna12 is null) then --Departamento de notificacion
					v_id_dprtmnto_esblcmnto_ntfccion := v_id_dprtmnto_esblcmnto;
				else
					begin
						select  a.id_dprtmnto
						into    v_id_dprtmnto_esblcmnto_ntfccion
						from    df_s_departamentos  a
						where   a.id_pais       =   v_id_pais_esblcmnto_ntfccion
						and     a.cdgo_dprtmnto =   c_estblcmntos.clmna12;
					exception
						when no_data_found then
							null;
						when others then
							rollback;
							o_cdgo_rspsta   := 10;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento de notificacion del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;
				if (c_estblcmntos.clmna13 is null) then --Municipio de notificacion
					v_id_mncpio_esblcmnto_ntfccion := v_id_mncpio_esblcmnto;
				else
					begin
						select  a.id_mncpio
						into    v_id_mncpio_esblcmnto_ntfccion
						from    df_s_municipios a
						where   a.id_dprtmnto   =   v_id_dprtmnto_esblcmnto_ntfccion
						and     a.cdgo_mncpio   =   c_estblcmntos.clmna13;
					exception
						when no_data_found then
							v_id_dprtmnto_esblcmnto_ntfccion := v_id_dprtmnto_esblcmnto;
							v_id_mncpio_esblcmnto_ntfccion := v_id_mncpio_esblcmnto;
						when others then
							rollback;
							o_cdgo_rspsta   := 11;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;
				end if;

				--Se valida el estado
				begin
					select  a.id_sjto_estdo
					into    v_id_sjto_estdo
					from    df_s_sujetos_estado a
					where   a.cdgo_sjto_estdo   =   c_estblcmntos.clmna17;
				exception
					when others then
						rollback;
						o_cdgo_rspsta   := 12;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el estado del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				--Se inserta el establecimiento en si_c_sujetos
				begin
					insert into si_i_sujetos_impuesto (id_sjto,
													   id_impsto,
													   estdo_blqdo,
													   id_pais_ntfccion,
													   id_dprtmnto_ntfccion,
													   id_mncpio_ntfccion,
													   drccion_ntfccion,
													   email,
													   tlfno,
													   fcha_rgstro,
													   id_usrio,
													   id_sjto_estdo,
													   fcha_ultma_nvdad,
													   fcha_cnclcion)
											   values (v_id_sjto,
													   v_id_impsto,
													   'N',
													   v_id_pais_esblcmnto_ntfccion,
													   v_id_dprtmnto_esblcmnto_ntfccion,
													   v_id_mncpio_esblcmnto_ntfccion,
													   c_estblcmntos.clmna14,
													   c_estblcmntos.clmna15,
													   c_estblcmntos.clmna16,
													   systimestamp,
													   p_id_usrio,
													   v_id_sjto_estdo,
													   c_estblcmntos.clmna18,
													   c_estblcmntos.clmna19) returning id_sjto_impsto into v_id_sjto_impsto;
				exception
					when others then
						rollback;
						o_cdgo_rspsta   := 13;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_impuesto del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
			end if;

			--REGISTRO EN SI_I_PERSONAS
			--Se valida el objeto persona
			begin
				select  a.id_prsna
				into    v_id_prsna
				from    si_i_personas   a
				where   a.id_sjto_impsto    =   v_id_sjto_impsto;
			exception
				when no_data_found then
					null;
				when others then
					rollback;
					o_cdgo_rspsta   := 14;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_personas. ' || sqlerrm;
					--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
					v_errors.extend;
					v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se continua con el proceso de si_i_personas si no existe
			if (v_id_prsna is null) then

				--Se identifica el ID_SJTO_TPO
				v_id_sjto_tpo := null;
				begin
					c_estblcmntos.clmna29 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 29,
																				  p_vlor    => c_estblcmntos.clmna29,
																				  p_hmlgcion=> v_hmlgcion);

					select  a.id_sjto_tpo
					into    v_id_sjto_tpo
					from    df_i_sujetos_tipo   a
					where   a.cdgo_clnte    =   p_cdgo_clnte
					and     a.id_impsto     =   v_id_impsto
					and     a.cdgo_sjto_tpo =   c_estblcmntos.clmna29;
				exception
					when no_data_found then
						null;
					when others then
						rollback;
						o_cdgo_rspsta   := 15;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el tipo de sujeto (regimen) establecimiento en la tabla id_sjto_tpo. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				--Se identifica la actividad economica
				v_id_actvdad_ecnmca := null;
				begin
					select      a.id_actvdad_ecnmca
					into        v_id_actvdad_ecnmca
					from        gi_d_actividades_economica  a
					inner join  gi_d_actividades_ecnmca_tpo b   on  b.id_actvdad_ecnmca_tpo =   a.id_actvdad_ecnmca_tpo
					where       b.cdgo_clnte            =   p_cdgo_clnte
					and         a.cdgo_actvdad_ecnmca   =   c_estblcmntos.clmna30
					and         systimestamp between a.fcha_dsde and a.fcha_hsta;
				exception
					when no_data_found then
						null;
					when others then
						rollback;
						o_cdgo_rspsta   := 16;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la actividad economica del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;

				--Se inserta el establecimiento en si_i_personas
				begin
					insert into si_i_personas (id_sjto_impsto,
											   cdgo_idntfccion_tpo,
											   tpo_prsna,
											   nmbre_rzon_scial,
											   nmro_rgstro_cmra_cmrcio,
											   fcha_rgstro_cmra_cmrcio,
											   fcha_incio_actvddes,
											   nmro_scrsles,
											   drccion_cmra_cmrcio,
											   id_sjto_tpo,
											   id_actvdad_ecnmca)
									   values (v_id_sjto_impsto,
											   c_estblcmntos.clmna1,
											   c_estblcmntos.clmna20,
											   c_estblcmntos.clmna21,
											   c_estblcmntos.clmna25,
											   c_estblcmntos.clmna26,
											   c_estblcmntos.clmna27,
											   c_estblcmntos.clmna28,
											   c_estblcmntos.clmna7,
											   v_id_sjto_tpo,
											   v_id_actvdad_ecnmca) returning id_prsna into v_id_prsna;
				exception
					when others then
						rollback;
						o_cdgo_rspsta   := 17;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_personas del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
			end if;

			--REGISTRO EN SI_C_TERCEROS
			--Se valida el objeto terceros
			begin
				select  a.id_trcro
				into    v_id_trcro_estblcmnto
				from    si_c_terceros   a
				where   a.cdgo_clnte    =   p_cdgo_clnte
				and     a.idntfccion    =   c_estblcmntos.clmna2;
			exception
				when no_data_found then
					null;
				when others then
					rollback;
					o_cdgo_rspsta   := 18;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_terceros. ' || sqlerrm;
					--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
					v_errors.extend;
					v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se continua con el proceso de si_c_terceros si no existe
			if (v_id_trcro_estblcmnto is null) then
				--Se inserta el establecimiento en si_c_terceros
				begin
					insert into si_c_terceros (cdgo_clnte,
											   cdgo_idntfccion_tpo,
											   idntfccion,
											   prmer_nmbre,
											   sgndo_nmbre,
											   prmer_aplldo,
											   sgndo_aplldo,
											   drccion,
											   id_pais,
											   id_dprtmnto,
											   id_mncpio,
											   drccion_ntfccion,
											   id_pais_ntfccion,
											   id_dprtmnto_ntfccion,
											   id_mncpio_ntfccion,
											   email,
											   tlfno,
											   indcdor_cntrbynte,
											   indcdr_fncnrio,
											   cllar)
									   values (p_cdgo_clnte,
											   c_estblcmntos.clmna1,
											   c_estblcmntos.clmna2,
											   c_estblcmntos.clmna21,
											   c_estblcmntos.clmna22,
											   nvl(c_estblcmntos.clmna23, '.'),
											   c_estblcmntos.clmna24,
											   c_estblcmntos.clmna7,
											   v_id_pais_esblcmnto,
											   v_id_dprtmnto_esblcmnto,
											   v_id_mncpio_esblcmnto,
											   c_estblcmntos.clmna14,
											   v_id_pais_esblcmnto_ntfccion,
											   v_id_dprtmnto_esblcmnto_ntfccion,
											   v_id_mncpio_esblcmnto_ntfccion,
											   c_estblcmntos.clmna15,
											   c_estblcmntos.clmna16,
											   'N',
											   'N',
											   c_estblcmntos.clmna16) returning id_trcro into v_id_trcro_estblcmnto;
				exception
					when others then
						rollback;
						o_cdgo_rspsta   := 19;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del establecimiento. ' || sqlerrm;
						--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
						v_errors.extend;
						v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
			end if;

			--Se asegura el sujeto impuesto
			commit;

			--RESPONSABLES
			if (c_estblcmntos.clmna20 = 'J') then
				--v_json_rspnsbles                    := new json_array_t(c_estblcmntos.json_rspnsbles);
				v_id_trcro_rspnsble                 := null;
				v_id_pais_rspnsble                  := null;
				v_id_dprtmnto_rspnsble              := null;
				v_id_mncpio_rspnsble                := null;

				for c_rspnsbles in (
										select  a.*
										from    json_table(c_estblcmntos.json_rspnsbles, '$[*]'
														   columns (id_intrmdia number          path '$.id_intrmdia',
																	clmna31     varchar2(4000)  path '$.clmna31',
																	clmna32     varchar2(4000)  path '$.clmna32',
																	clmna33     varchar2(4000)  path '$.clmna33',
																	clmna34     varchar2(4000)  path '$.clmna34',
																	clmna35     varchar2(4000)  path '$.clmna35',
																	clmna36     varchar2(4000)  path '$.clmna36',
																	clmna37     varchar2(4000)  path '$.clmna37',
																	clmna38     varchar2(4000)  path '$.clmna38',
																	clmna39     varchar2(4000)  path '$.clmna39',
																	clmna40     varchar2(4000)  path '$.clmna40',
																	clmna41     varchar2(4000)  path '$.clmna41',
																	clmna42     varchar2(4000)  path '$.clmna42',
																	clmna43     varchar2(4000)  path '$.clmna43',
																	clmna44     varchar2(4000)  path '$.clmna44',
																	clmna45     varchar2(4000)  path '$.clmna45',
																	clmna46     varchar2(4000)  path '$.clmna46',
																	clmna47     varchar2(4000)  path '$.clmna47'))  a
									)
				loop
					v_id_trcro_rspnsble     := null;
					v_id_pais_rspnsble      := null;
					v_id_dprtmnto_rspnsble  := null;
					v_id_mncpio_rspnsble    := null;

					--Se valida el responsable  terceros
					begin
						select  a.id_trcro
						into    v_id_trcro_rspnsble
						from    si_c_terceros   a
						where   a.cdgo_clnte    =   p_cdgo_clnte
						and     a.idntfccion    =   c_rspnsbles.clmna32 ;
					exception
						when no_data_found then
							null;
						when others then
							rollback;
							o_cdgo_rspsta   := 20;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el responsable en la tabla si_c_terceros. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					--Si el responsable no existe en si_c_terceros se crea
					if (v_id_trcro_rspnsble is null) then
						--Se valida el pais el departamento y el municipio de notificacion
						if (c_rspnsbles.clmna38 is null) then --Pais responsable
							v_id_pais_rspnsble := v_id_pais_esblcmnto;
						else
							declare
								v_cdgo_pais_rspnsble varchar2(20) := c_rspnsbles.clmna38;
							begin
								select  a.id_pais
								into    v_id_pais_rspnsble
								from    df_s_paises a
								where   a.cdgo_pais =   v_cdgo_pais_rspnsble;
							exception
								when others then
									rollback;
									o_cdgo_rspsta   := 21;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais del responsable del establecimiento. ' || sqlerrm;
									--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
									v_errors.extend;
									v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
									continue;
							end;
						end if;

						if (c_rspnsbles.clmna39 is null) then --Departamento responsable
							v_id_dprtmnto_rspnsble := v_id_dprtmnto_esblcmnto;
						else
							declare
								v_cdgo_dprtmnto_rspnsble varchar2(20) := c_rspnsbles.clmna39;
							begin
								select  a.id_dprtmnto
								into    v_id_dprtmnto_rspnsble
								from    df_s_departamentos  a
								where   a.id_pais       =   v_id_pais_rspnsble
								and     a.cdgo_dprtmnto =   v_cdgo_dprtmnto_rspnsble;
							exception
								when others then
									rollback;
									o_cdgo_rspsta   := 22;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del responsable del establecimiento. ' || sqlerrm;
									--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
									v_errors.extend;
									v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
									continue;
							end;
						end if;

						if (c_rspnsbles.clmna40 is null) then --Municipio de notificacion
							v_id_mncpio_rspnsble := v_id_mncpio_esblcmnto;
						else
							declare
								v_cdgo_mncpio_rspnsble varchar2(20) := c_rspnsbles.clmna40;
							begin
								select  a.id_mncpio
								into    v_id_mncpio_rspnsble
								from    df_s_municipios a
								where   a.id_dprtmnto   =   v_id_dprtmnto_rspnsble
								and     a.cdgo_mncpio   =   v_cdgo_mncpio_rspnsble;
							exception
								when no_data_found then
									v_id_dprtmnto_rspnsble := v_id_dprtmnto_esblcmnto;
									v_id_mncpio_rspnsble := v_id_mncpio_esblcmnto;
								when others then
									rollback;
									o_cdgo_rspsta   := 23;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del reponsable del establecimiento. ' || sqlerrm;
									--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
									v_errors.extend;
									v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
									continue;
							end;
						end if;

						--Se registra el responsable en si_c_terceros
						begin
							insert into si_c_terceros (cdgo_clnte,
													   cdgo_idntfccion_tpo,
													   idntfccion,
													   prmer_nmbre,
													   sgndo_nmbre,
													   prmer_aplldo,
													   sgndo_aplldo,
													   drccion,
													   id_pais,
													   id_dprtmnto,
													   id_mncpio,
													   drccion_ntfccion,
													   id_pais_ntfccion,
													   id_dprtmnto_ntfccion,
													   id_mncpio_ntfccion,
													   email,
													   tlfno,
													   indcdor_cntrbynte,
													   indcdr_fncnrio,
													   cllar)
											   values (p_cdgo_clnte,
													   nvl(c_rspnsbles.clmna31, 'X'),
													   c_rspnsbles.clmna32,
													   c_rspnsbles.clmna33,
													   c_rspnsbles.clmna34,
													   nvl(c_rspnsbles.clmna35, '.'), --PRIMER APELLIDO
													   c_rspnsbles.clmna36,
													   c_rspnsbles.clmna37,
													   v_id_pais_rspnsble,
													   v_id_dprtmnto_rspnsble,
													   v_id_mncpio_rspnsble,
													   c_rspnsbles.clmna37,
													   v_id_pais_rspnsble,
													   v_id_dprtmnto_rspnsble,
													   v_id_mncpio_rspnsble,
													   c_rspnsbles.clmna41,
													   c_rspnsbles.clmna42,
													   'N',
													   'N',
													   c_rspnsbles.clmna42) returning id_trcro into v_id_trcro_rspnsble;
						exception
							when others then
                o_mnsje_rspsta := 'Mensaje: No pudo insertarse el si_c_terceros del responsable. '||sqlerrm;
                update migra.mg_g_intermedia_ica_establec t set t.clmna48 = o_mnsje_rspsta
                where t.id_intrmdia = c_rspnsbles.id_intrmdia;
								--rollback;
								--o_cdgo_rspsta   := 24;
								--o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del responsable. ' || sqlerrm;
								--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							  --v_errors.extend;
								--v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								continue;
						end;
					end if;

					--Se insertan el responsable en la tabla si_i_sujetos_responsable
					begin
						insert into si_i_sujetos_responsable (id_sjto_impsto,
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
															  id_pais_ntfccion,
															  id_dprtmnto_ntfccion,
															  id_mncpio_ntfccion,
															  drccion_ntfccion,
															  email,
															  tlfno,
															  actvo,
															  id_trcro)
													  values (v_id_sjto_impsto, --id_sjto_impsto
															  nvl(c_rspnsbles.clmna31, 'X'), --cdgo_idntfccion_tpo
															  nvl(c_rspnsbles.clmna32, c_estblcmntos.clmna3), --idntfccion
															  nvl(c_rspnsbles.clmna33, c_rspnsbles.clmna34), --prmer_nmbre
															  c_rspnsbles.clmna34, --sgndo_nmbre
															  nvl(c_rspnsbles.clmna35, '.'), --prmer_aplldo
															  c_rspnsbles.clmna36, --sgndo_aplldo
															  c_rspnsbles.clmna44, --prncpal_s_n
															  c_rspnsbles.clmna45, --cdgo_tpo_rspnsble
															  c_rspnsbles.clmna46, --prcntje_prtcpcion
															  0, --orgen_dcmnto
															  v_id_pais_rspnsble,
															  v_id_dprtmnto_rspnsble,
															  v_id_mncpio_rspnsble,
															  c_rspnsbles.clmna37, --drccion_ntfccion
															  c_rspnsbles.clmna41, --email
                                replace(replace(replace(replace(c_rspnsbles.clmna42, '(', ''), ')', ''), ' ', ''), '-', ''), --tlfno
															  c_rspnsbles.clmna47, --actvo
															  v_id_trcro_rspnsble);
					exception
						when others then
							rollback;
							o_cdgo_rspsta   := 25;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. '
							/*|| 'id_sjto_impsto: ' ||v_id_sjto_impsto || ' '
							|| 'cdgo_idntfccion_tpo: ' ||nvl(c_rspnsbles.clmna31, 'X')  || ' '
							|| 'idntfccion: ' ||c_rspnsbles.clmna32  || ' '
							|| 'prmer_nmbre: ' ||c_rspnsbles.clmna33  || ' '
							|| 'sgndo_nmbre: ' ||c_rspnsbles.clmna34  || ' '
							|| 'prmer_aplldo: ' ||c_rspnsbles.clmna35  || ' '
							|| 'sgndo_aplldo: ' ||c_rspnsbles.clmna36  || ' '
							|| 'prncpal_s_n: ' ||c_rspnsbles.clmna44  || ' '
							|| 'cdgo_tpo_rspnsble: ' ||c_rspnsbles.clmna45  || ' '
							|| 'prcntje_prtcpcion: ' ||c_rspnsbles.clmna46  || ' '
							|| 'v_id_pais_rspnsble: ' ||v_id_pais_rspnsble  || ' '
							|| 'v_id_dprtmnto_rspnsble: ' ||v_id_dprtmnto_rspnsble  || ' '
							|| 'v_id_mncpio_rspnsble: ' ||v_id_mncpio_rspnsble  || ' '
							|| 'drccion_ntfccion: ' ||c_rspnsbles.clmna37  || ' '
							|| 'email: ' ||c_rspnsbles.clmna41  || ' '
							|| 'tlfno: ' ||c_rspnsbles.clmna42  || ' '
							|| 'actvo: ' ||c_rspnsbles.clmna47  || ' '
							|| 'v_id_trcro_rspnsble: ' ||v_id_trcro_rspnsble || ' '*/
							|| sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_rspnsbles.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					--Se actualiza el registro como exitoso
					update  migra.MG_G_INTERMEDIA_ICA_ESTABLEC   a
					set     a.cdgo_estdo_rgstro =   'S'
					where   a.id_intrmdia       =   c_rspnsbles.id_intrmdia;

				end loop;

				--Indicador de Registros Exitosos
				o_ttal_extsos := o_ttal_extsos + 1;

				commit;


			else	--Si el establecimiento es de tipo persona natural

				declare
					v_id_sjto_rspnsble number;
				begin

					--Se valida el tercero en responsables
					begin
						select  a.id_sjto_rspnsble
						into    v_id_sjto_rspnsble
						from    si_i_sujetos_responsable    a
						where   a.id_sjto_impsto    =   v_id_sjto_impsto
						and     a.idntfccion        =   c_estblcmntos.clmna2
						and     a.cdgo_tpo_rspnsble =   'L';
					exception
						when no_data_found then
							null;
						when others then
							rollback;
							o_cdgo_rspsta   := 26;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. ' || sqlerrm;
							--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
							v_errors.extend;
							v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;

					--Se continua con el proceso de si_i_sujetos_responsable si no existe
					if (v_id_sjto_rspnsble is null) then
						begin
							insert into si_i_sujetos_responsable (id_sjto_impsto,
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
																  id_pais_ntfccion,
																  id_dprtmnto_ntfccion,
																  id_mncpio_ntfccion,
																  drccion_ntfccion,
																  email,
																  tlfno,
																  actvo,
																  id_trcro)
														  values (v_id_sjto_impsto,
																  c_estblcmntos.clmna1,
																  c_estblcmntos.clmna2,
																  c_estblcmntos.clmna21,
																  c_estblcmntos.clmna22,
																  nvl(c_estblcmntos.clmna23, '.'),
																  c_estblcmntos.clmna24,
																  'S',
																  'L',
																  '0',
																  0,
																  v_id_pais_esblcmnto_ntfccion,
																  v_id_dprtmnto_esblcmnto_ntfccion,
																  v_id_mncpio_esblcmnto_ntfccion,
																  c_estblcmntos.clmna14,
																  c_estblcmntos.clmna15,
                                  replace(replace(replace(replace(c_estblcmntos.clmna16, '(', ''), ')', ''), ' ', ''), '-', ''), --tlfno
																  'S',
																  v_id_trcro_estblcmnto);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 27;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del establecimiento. ' || sqlerrm;
								--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
								v_errors.extend;
								v_errors( v_errors.count ) := t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								continue;
						end;
					end if;
				end;

				--Se actualiza el registro como exitoso
				update  migra.MG_G_INTERMEDIA_ICA_ESTABLEC   a
				set     a.cdgo_estdo_rgstro =   'S'
				where   a.id_intrmdia       =   c_estblcmntos.id_intrmdia;

				--Indicador de Registros Exitosos
				o_ttal_extsos := o_ttal_extsos + 1;

				commit;
			end if;
		end loop;

		--Procesos con Errores
		o_ttal_error   := v_errors.count;

		--Se actualizan en la tabla MIGRA.mg_g_intermedia_otimp_sujetos como error
		begin
			forall j in 1 .. o_ttal_error
				update  migra.MG_G_INTERMEDIA_ICA_ESTABLEC   a
				set     a.cdgo_estdo_rgstro =   'E',
						a.clmna49           =   v_errors(j).mnsje_rspsta
				where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
		exception
			when others then
				o_cdgo_rspsta   := 28;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
				--insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
				return;
		end;

		commit;
		--Se actualizan y recorren los errores
		--Respuesta Exitosa
		o_cdgo_rspsta  := 0;
		o_mnsje_rspsta := 'Exito';

        --close c_intrmdia;
    end prc_mg_sjtos_impsts_estblcmnts;

    procedure prc_rg_declaraciones_tipos (p_id_entdad			in  number,
                                          p_cdgo_clnte        	in  number,
                                          o_ttal_extsos	    	out number,
                                          o_ttal_error	    	out number,
                                          o_cdgo_rspsta	    	out number,
                                          o_mnsje_rspsta	    out varchar2) as


        v_errors            		pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();

        v_id_dclrcn_tpo     		number;
        v_id_impsto         		number;
        v_id_impsto_sbmpsto 		number;
        v_cdgo_prdcdad      		varchar2(5);
        v_id_impsto_acto    		number;
        v_actvo             		varchar2(1);
        v_id_prdo					number;
		v_dscrpcion					varchar2(4000);
        v_id_dclrcion_tpo_vgncia	number;
        v_id_sjto_tpo				number;
        v_id_dclrcion_tpo_sjto		number;
        v_cntdor_commit				number;
        v_cdgo_tpo_dclrcion   varchar2(5);


    begin
        o_ttal_extsos := 0;
        o_ttal_error := 0;

        --Carga los Datos de la Homologacion

        for c_dclrcnes in (
                            select  min (a.id_intrmdia) id_intrmdia,
                                    a.clmna1,   --Codigo Impuesto
                                    a.clmna2,   --Codigo SubImpuesto
                                    a.clmna3,   --Codigo Tipo Declaracion
                                    a.clmna4,   --Descripcion Tipo Declaracion
                                    a.clmna5,   --Estado Tipo Declaracion
                                    a.clmna7,   --Codigo Periodicidad
                                  --  a.clmna20,  --Impuesto acto
                                    json_arrayagg(
                                                    json_object(
																'id_intrmdia'	value   a.id_intrmdia,  --Intermedia
                                                                'clmna6'    	value   a.clmna6,   	--Vigencia
                                                                'clmna8'    	value   a.clmna8,   	--Codigo Periodo
                                                                'clmna9'    	value   a.clmna9    	--Codigo Tipo sujeto
                                                                returning clob
                                                               )
                                                    returning clob
                                                 ) as prdos
                            from    migra.MG_G_INTERMEDIA_DECLARA_2   a
                            where   a.cdgo_clnte    	=   p_cdgo_clnte
                            and     a.id_entdad     	=   p_id_entdad
							and		a.cdgo_estdo_rgstro =   'L'
						--	and		a.clmna3			in	('DEC001')
							--and		a.clmna7			=	'ANU'
							--and     a.clmna6			=   '2012'
							--and		a.clmna8    		=   '1'
                            group by a.clmna1,
                                     a.clmna2,
                                     a.clmna3,
                                     a.clmna4,
                                     a.clmna5,
                                     a.clmna7
                                  --   a.clmna20
                          )
        loop
            v_id_dclrcn_tpo 	:= null;
            v_id_impsto			:= 230012;
            v_id_impsto_sbmpsto	:= null;
            v_cdgo_prdcdad		:= null;
            --Registro en tabla gi_d_declaraciones_tipo

            if c_dclrcnes.clmna2 = 'ICA' then
              v_id_impsto_sbmpsto := '2300122';
            else
              v_id_impsto_sbmpsto := '23001154';
            end if;

            if c_dclrcnes.clmna2 = 'ICA' and c_dclrcnes.clmna3 = '02' and c_dclrcnes.clmna7 = 'BIM' then
              v_cdgo_tpo_dclrcion := 'ICA2B';
            elsif c_dclrcnes.clmna2 = 'ICA' and c_dclrcnes.clmna3 = '02' and c_dclrcnes.clmna7 = 'ANU' then
              v_cdgo_tpo_dclrcion := 'ICA2A';
            elsif c_dclrcnes.clmna2 = 'RETEICA' then
              v_cdgo_tpo_dclrcion := 'RTCA4';
            else
              v_cdgo_tpo_dclrcion := c_dclrcnes.clmna2||c_dclrcnes.clmna3;
            end if;

            v_id_impsto_acto := 2;

            if c_dclrcnes.clmna2 = 'RETEICA' then
              v_id_impsto_acto := 136;
            end if;


				--Se registra el tipo de declaracion
				begin
					insert into gi_d_declaraciones_tipo (
															cdgo_clnte,
															cdgo_dclrcn_tpo,
															id_impsto,
															id_impsto_sbmpsto,
															cdgo_prdcdad,
															dscrpcion,
															actvo,
															id_impsto_acto,
                              indcdor_prsntcion_web
														)
												 values (
															p_cdgo_clnte,
															v_cdgo_tpo_dclrcion,
															v_id_impsto,
															v_id_impsto_sbmpsto,
															c_dclrcnes.clmna7,
															c_dclrcnes.clmna4,
															'N',--c_dclrcnes.clmna5,
															v_id_impsto_acto,
                              'N'
														) returning id_dclrcn_tpo into v_id_dclrcn_tpo;
				exception
					when others then
						o_cdgo_rspsta   := 6;
						o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el tipo de declaracion. ' || chr(13) ||
											'p_cdgo_clnte: ' || p_cdgo_clnte || chr(13) ||
											'c_dclrcnes.clmna3: ' || c_dclrcnes.clmna3 || chr(13) ||
											'v_id_impsto: ' || v_id_impsto || chr(13) ||
											'v_id_impsto_sbmpsto: ' || v_id_impsto_sbmpsto || chr(13) ||
											sqlerrm;
						v_errors.extend;
						v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;



            --Se recorren los periodos del tipo de declaracion
            begin
                for c_prdos in	(
                                    select  a.clmna6,   --vgncia
                                            a.clmna8    --periodo
                                    from    json_table  (
                                                            c_dclrcnes.prdos, '$[*]' columns (
                                                                                    clmna6 varchar2 path '$.clmna6',
                                                                                    clmna8 varchar2 path '$.clmna8'
                                                                                )
                                                        )   a
                                    group by    clmna6,
                                                clmna8
                                )
                loop
                    v_id_prdo 					:= null;
                    v_id_dclrcion_tpo_vgncia	:= null;

					--Se actualiza el periodo
					if (c_prdos.clmna8 = '0') then
						c_prdos.clmna8 := '1';
					end if;

                    --Se valida el periodo
                    begin
                        select  a.id_prdo
                        into	v_id_prdo
                        from    df_i_periodos   a
                        where   a.cdgo_clnte        =   p_cdgo_clnte
                        and     a.id_impsto         =   v_id_impsto
                        and     a.id_impsto_sbmpsto =   v_id_impsto_sbmpsto
                        and     a.vgncia            =   c_prdos.clmna6
                        and     a.prdo              =   c_prdos.clmna8
                        and     a.cdgo_prdcdad      =   c_dclrcnes.clmna7;
                    exception
						when no_data_found then
							--Si no existe se registra el periodo

							--Se valida el periodo
							v_dscrpcion := null;

							begin
								if (c_dclrcnes.clmna7 = 'ANU') then
									v_dscrpcion := 'ANUAL';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 1) then
									v_dscrpcion := 'ENERO - FEBRERO';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 2) then
									v_dscrpcion := 'MARZO - ABRIL';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 3) then
									v_dscrpcion := 'MAYO - JUNIO';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 4) then
									v_dscrpcion := 'JULIO - AGOSTO';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 5) then
									v_dscrpcion := 'SEPTIEMBRE - OCTUBRE';
								elsif (c_dclrcnes.clmna7 = 'BIM' and to_number(c_prdos.clmna8) = 6) then
									v_dscrpcion := 'NOVIEMBRE - DICIEMBRE';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 1) then
									v_dscrpcion := 'ENERO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 2) then
									v_dscrpcion := 'FEBRERO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 3) then
									v_dscrpcion := 'MARZO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 4) then
									v_dscrpcion := 'ABRIL';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 5) then
									v_dscrpcion := 'MAYO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 6) then
									v_dscrpcion := 'JUNIO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 7) then
									v_dscrpcion := 'JULIO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 8) then
									v_dscrpcion := 'AGOSTO';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 9) then
									v_dscrpcion := 'SEPTIEMBRE';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 10) then
									v_dscrpcion := 'OCTUBRE';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 11) then
									v_dscrpcion := 'NOVIEMBRE';
								elsif (c_dclrcnes.clmna7 = 'MNS' and to_number(c_prdos.clmna8) = 12) then
									v_dscrpcion := 'DICIEMBRE';
								end if;
							exception
								when others then
									o_cdgo_rspsta   := 7;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo en el tipo de declaracion. ' || sqlerrm;
									v_errors.extend;
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
									continue;
							end;

							--Se registra el periodo
							begin
								insert into df_i_periodos   (
																cdgo_clnte,
																id_impsto,
																id_impsto_sbmpsto,
																vgncia,
																prdo,
																dscrpcion,
																indcdor_crre_lqdcion,
																indcdor_inctvcion_prdios,
																cdgo_prdcdad
															)
													values  (
																p_cdgo_clnte,
																v_id_impsto,
																v_id_impsto_sbmpsto,
																to_number(c_prdos.clmna6),
																to_number(c_prdos.clmna8),
																v_dscrpcion,
																'N',
																'N',
																c_dclrcnes.clmna7
															) returning id_prdo into v_id_prdo;
							exception
								when others then
									o_cdgo_rspsta   := 8;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el periodo en el tipo de declaracion. ' || sqlerrm;
									v_errors.extend;
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
									continue;
							end;

                        when others then
                            o_cdgo_rspsta   := 9;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo. ' || chr(13) ||
												'p_cdgo_clnte: ' || p_cdgo_clnte || chr(13) ||
												'v_id_impsto: ' || v_id_impsto || chr(13) ||
												'v_id_impsto_sbmpsto: ' || v_id_impsto_sbmpsto || chr(13) ||
												'c_prdos.clmna6: ' || c_prdos.clmna6 || chr(13) ||
												'c_prdos.clmna8: ' || c_prdos.clmna8 || chr(13) ||
												'c_dclrcnes.clmna7: ' || c_dclrcnes.clmna7 || chr(13) ||
												sqlerrm;
                            v_errors.extend;
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;

                    if (v_id_prdo is not null) then
                        --Se valida el periodo en el tipo de declaracion
                        begin
                            select  a.id_dclrcion_tpo_vgncia
                            into	v_id_dclrcion_tpo_vgncia
                            from    gi_d_dclrcnes_tpos_vgncias  a
                            where   a.id_dclrcn_tpo =   v_id_dclrcn_tpo
                            and     a.id_prdo       =   v_id_prdo;
                        exception
                            when no_data_found then
                                null;
                            when others then
                                o_cdgo_rspsta   := 10;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo en el tipo de declaracion. ' || sqlerrm;
                                v_errors.extend;
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;

                        --Se registra el periodo en el tipo de declaracion en caso de ser necesario
                        if (v_id_dclrcion_tpo_vgncia is null) then
                            begin
                                insert into gi_d_dclrcnes_tpos_vgncias (
                                                                            id_dclrcn_tpo,
                                                                            vgncia,
                                                                            id_prdo,
                                                                            actvo
                                                                       )
                                                                values (
                                                                            v_id_dclrcn_tpo,
                                                                            c_prdos.clmna6,
                                                                            v_id_prdo,
                                                                            'N'--c_dclrcnes.clmna5
                                                                       );
                            exception
                                when others then
                                    o_cdgo_rspsta   := 11;
                                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el periodo en el tipo de declaracion. ' || chr(13) ||
														'v_id_dclrcn_tpo: ' || v_id_dclrcn_tpo || chr(13) ||
														sqlerrm;
                                    v_errors.extend;
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end if;

                end loop;
            exception
                when others then
                    o_cdgo_rspsta   := 12;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo recorrerse los periodos en el tipo de declaracion. ' || sqlerrm;
                    v_errors.extend;
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
            end;
            --Fin se recorren los periodos del tipo de declaracion

            --Se recorren los sujetos del tipo de declaracion
            begin
                for c_sjtos in	(
                                    select  a.clmna9
                                    from    json_table  (
                                                            c_dclrcnes.prdos, '$[*]' columns (
                                                                                    clmna9 varchar2 path '$.clmna9'
                                                                                )
                                                        )   a
                                    group by    clmna9
                                )
                loop
                    v_id_sjto_tpo := null;
                    v_id_dclrcion_tpo_sjto := null;

                    if c_sjtos.clmna9 = 'C' then
                      v_id_sjto_tpo := 363;
                    elsif c_sjtos.clmna9 = 'S' then
                      v_id_sjto_tpo := 361;
                    elsif c_sjtos.clmna9 = 'G' then
                      v_id_sjto_tpo := 365;
                    end if;

                    --Se valida si existe el tipo de sujeto en el tipo de declaracion
                    begin
                        select  a.id_dclrcion_tpo_sjto
                        into	v_id_dclrcion_tpo_sjto
                        from    gi_d_dclrcnes_tpos_sjto a
                        where   a.id_dclrcn_tpo =   v_id_dclrcn_tpo
                        and     a.id_sjto_tpo   =   v_id_sjto_tpo;
                    exception
                        when no_data_found then
                            null;
                        when others then
                            o_cdgo_rspsta   := 14;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el tipo de sujeto en el tipo de declaracion. ' || sqlerrm;
                            v_errors.extend;
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;

                    --Si no se encuentra los registra el tipo de sujeto en el tipo de declaracion
					if (v_id_dclrcion_tpo_sjto is null) then
						begin
							insert into gi_d_dclrcnes_tpos_sjto (
																			id_dclrcn_tpo,
																			id_sjto_tpo
																		)
																 values (
																			v_id_dclrcn_tpo,
																			v_id_sjto_tpo
																		);
						exception
							when others then
								o_cdgo_rspsta   := 15;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el tipo de sujeto en el tipo de declaracion. ' || sqlerrm;
								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								continue;
						end;
					end if;
                end loop;
            exception
                when others then
                    o_cdgo_rspsta   := 16;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo recorrerse los tipos de sujeto en el tipo de declaracion. ' || sqlerrm;
                    v_errors.extend;
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
            end;

			--Se marca como exitoso todo
			--Se recorren los periodos del tipo de declaracion
            begin
                for c_prdos in	(
                                    select  a.id_intrmdia
                                    from    json_table  (
                                                            c_dclrcnes.prdos, '$[*]' columns (
                                                                                    id_intrmdia number path '$.id_intrmdia'
                                                                                )
                                                        )   a
                                )
                loop
					update  MIGRA.MG_G_INTERMEDIA_DECLARA_2 a
					set     a.cdgo_estdo_rgstro =   'S'
					where   a.id_intrmdia       =   c_prdos.id_intrmdia;
				end loop;
			end;
            --Fin recorren los sujetos del tipo de declaracion

			--v_cntdor_commit := v_cntdor_commit + 1;
            --if (mod(v_cntdor_commit, 20) = 0) then
                commit;
            --end if;
        end loop;



        --Procesos con Errores
        o_ttal_error   := v_errors.count;



        --Se actualizan en la tabla migra.MG_G_INTERMEDIA_DECLARA como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.MG_G_INTERMEDIA_DECLARA_2   a
            set     a.cdgo_estdo_rgstro =   'E',
					a.clmna49			=	v_errors(j).mnsje_rspsta
            where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 17;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
    end prc_rg_declaraciones_tipos;


	procedure prc_mg_d_dclrcnes_fcha_prsntc (p_id_entdad			in  number,
											 p_id_prcso_instncia	in  number,
											 p_id_usrio				in  number,
											 p_cdgo_clnte			in  number,
											 o_ttal_extsos			out number,
											 o_ttal_error			out number,
											 o_cdgo_rspsta			out number,
											 o_mnsje_rspsta			out varchar2) as

		v_errors            		pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
		v_hmlgcion          		pkg_mg_migracion.r_hmlgcion;
		v_cdgo_tpo_dclrcn			varchar2(5);
		v_id_dclrcn_tpo				number;
		v_id_impsto					number;
		v_id_impsto_sbmpsto			number;
		v_id_prdo                   number;
		v_id_dclrcion_tpo_vgncia	number;
		v_id_sjto_tpo				number;

	begin
		o_ttal_extsos 	:= 0;
		o_ttal_error 	:= 0;
		o_cdgo_rspsta	:= 0;

		--Carga los Datos de la Homologacion
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);

		for c_fcha in	(
							select  a.id_intrmdia,
									a.clmna1,   	--Codigo Declaracion
									a.clmna2,   	--Vigencia
									a.clmna3,   	--Codigo del Periodo
									a.clmna4,   	--Fecha Maxima Presentacion
									a.clmna5,   	--Ultimo Digito identificacion
									a.clmna6,		--Codigo Tipo Sujeto Impuesto
									a.clmna7		--Codigo periodicidad
							from    migra.MG_G_INTERMEDIA_DURB_DECLARA   a
							where   a.cdgo_clnte    	=   p_cdgo_clnte
							and     a.id_entdad     	=   p_id_entdad
							and     cdgo_estdo_rgstro   =   'L'
							--and		a.clmna1			in	('096')
							--and		a.clmna7			=	'ANU'
							--and     a.clmna2			=   '2012'
							--and		a.clmna3    		=   '1'
						)
		loop
			/*Con el codigo del tipo de declaracion y el cliente tienes el tipo de declaracion,
			eso te da impuesto y sub-impuesto y periodicidad, con eso,
			vas a la tabla de periodo y consultas con el cliente, impuesto, sub-impesto, periodicidad, y codigo del periodo
			ah la vigencia que ya la tienes */

			--Se homologa el tributo, sub-tributo y el tipo de declaracion
            begin
				c_fcha.clmna1 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 1,
																	  p_vlor    => c_fcha.clmna1,
																	  p_hmlgcion=> v_hmlgcion);
			exception
				when others then
					o_cdgo_rspsta:= 5;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' -  cdgo_tpo_dclrcn  - '|| v_cdgo_tpo_dclrcn ||' -  '|| SQLERRM;
					update migra.MG_G_INTERMEDIA_DURB_DECLARA
					set clmna20 = '5' ,
						clmna21 = o_mnsje_rspsta
					where id_intrmdia = c_fcha.id_intrmdia;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			if (c_fcha.clmna1 = '2002') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '4002') then
				v_cdgo_tpo_dclrcn := 'VA181';
			elsif (c_fcha.clmna1 = '5002') then
				v_cdgo_tpo_dclrcn := 'VA182';
			elsif (c_fcha.clmna1 = '005' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '007' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '006' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '037' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '038' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '039' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '39B' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';
			elsif (c_fcha.clmna1 = '096' and c_fcha.clmna7 = 'ANU') then
				v_cdgo_tpo_dclrcn := 'VA361';

			--Bimestral
			elsif (c_fcha.clmna1 = '006' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := '4001';
			elsif (c_fcha.clmna1 = '036' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := '4001';
			elsif (c_fcha.clmna1 = '038' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := 'VA181';
			elsif (c_fcha.clmna1 = '38B' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := 'VA181';
			elsif (c_fcha.clmna1 = '039' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := 'VA181';
			elsif (c_fcha.clmna1 = '39B' and c_fcha.clmna7 = 'BIM') then
				v_cdgo_tpo_dclrcn := 'VA181';

			--Mensual
			elsif (c_fcha.clmna1 = '006' and c_fcha.clmna7 = 'MNS') then
				v_cdgo_tpo_dclrcn := '5001';
			elsif (c_fcha.clmna1 = '036' and c_fcha.clmna7 = 'MNS') then
				v_cdgo_tpo_dclrcn := '5001';
			elsif (c_fcha.clmna1 = '038' and c_fcha.clmna7 = 'MNS') then
				v_cdgo_tpo_dclrcn := 'VA182';
			elsif (c_fcha.clmna1 = '38B' and c_fcha.clmna7 = 'MNS') then
				v_cdgo_tpo_dclrcn := 'VA182';
			elsif (c_fcha.clmna1 = '007' and c_fcha.clmna7 = 'MNS') then
				v_cdgo_tpo_dclrcn := 'VA182';
			else
				v_cdgo_tpo_dclrcn := c_fcha.clmna1;
			end if;

			begin
				/* se realiza en el 36 - esta tabla en el servidor de valledupar no tiene el campo cdgo_dclrcn_tpo */
				select 	/*+ RESULT_CACHE */
						id_dclrcn_tpo			,
						id_impsto				,
						id_impsto_sbmpsto
				into 	v_id_dclrcn_tpo			,
						v_id_impsto				,
						v_id_impsto_sbmpsto
				from	gi_d_declaraciones_tipo
				where	cdgo_clnte  	=	p_cdgo_clnte
				and		cdgo_dclrcn_tpo	=	v_cdgo_tpo_dclrcn
				and     cdgo_prdcdad    =	c_fcha.clmna7;
			exception
				when others then
					o_cdgo_rspsta:= 10;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' -  cdgo_tpo_dclrcn  - '|| v_cdgo_tpo_dclrcn ||' -  '|| SQLERRM;
					update migra.MG_G_INTERMEDIA_DURB_DECLARA
					set clmna20 = '10' ,
						clmna21 = o_mnsje_rspsta
					where id_intrmdia = c_fcha.id_intrmdia;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se actualiza el periodo
			if (c_fcha.clmna3 = '13') then
				c_fcha.clmna3 := '1';
			end if;

			begin
				select  /*+ RESULT_CACHE */
						id_prdo
				into 	v_id_prdo
				from 	df_i_periodos
				where  	cdgo_clnte 			= p_cdgo_clnte
				and 	id_impsto 			= v_id_impsto         -- no lo tengo impuesto industria y comercio  v_id_impsto
				and 	id_impsto_sbmpsto 	= v_id_impsto_sbmpsto -- no lo tengo sub impuesto industria y comercio v_id_impsto_sbmpsto
				and 	vgncia 				= c_fcha.clmna2
				and 	prdo 				= c_fcha.clmna3
				and     cdgo_prdcdad        = c_fcha.clmna7;
			exception
				when others then
					o_cdgo_rspsta:= 20;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro el id_prdo  por migracion - v_id_impsto - '|| v_id_impsto ||' - v_id_impsto_sbmpsto - '|| v_id_impsto_sbmpsto  ||' -  vgncia - '|| c_fcha.clmna2 ||' -  cdgo_prdcdad  - '|| c_fcha.clmna7 ||' -  '|| SQLERRM;
					update migra.MG_G_INTERMEDIA_DURB_DECLARA
					set clmna20 = '20' ,
						clmna21 = o_mnsje_rspsta
					where id_intrmdia = c_fcha.id_intrmdia;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			begin
			--gi_d_dclrcnes_tpos_vgncias (id_dclrcion_tpo_vgncia) --- necesito la vigencia y el periodo
				select 	id_dclrcion_tpo_vgncia
				into 	v_id_dclrcion_tpo_vgncia
				from 	gi_d_dclrcnes_tpos_vgncias
				where 	id_dclrcn_tpo 	= v_id_dclrcn_tpo
				and 	vgncia 			= c_fcha.clmna2
				and 	id_prdo 		= v_id_prdo;
			exception
				when others then
					o_cdgo_rspsta:= 30;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se encontro id_dclrcion_tpo_vgncia  por migracion - id_dclrcn_tpo - '|| v_id_dclrcn_tpo ||' - vgncia - '|| c_fcha.clmna2  ||' -  id_prdo - '|| v_id_prdo ||' -  '|| SQLERRM;
					update migra.MG_G_INTERMEDIA_DURB_DECLARA
					set clmna20 = '30' ,
						clmna21 = o_mnsje_rspsta
					where id_intrmdia = c_fcha.id_intrmdia;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se homologa el tipo de sujeto
			begin
				v_id_sjto_tpo:= to_number	(
												pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 6,
																					 p_vlor    => c_fcha.clmna6,
																					 p_hmlgcion=> v_hmlgcion)
											);
			exception
				when others then
					o_cdgo_rspsta   := 35;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo homologarse el tipo de sujeto. ' || sqlerrm;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;

			--Se registra la declaracion
			begin
				insert into gi_d_dclrcnes_fcha_prsntcn  (id_dclrcion_tpo_vgncia			,
														dscrpcion						,
														fcha_incial						,
														fcha_fnal						,
														vlor							,
														actvo							,
														id_sjto_tpo)
												values (v_id_dclrcion_tpo_vgncia,
														'MIG - FECHA PRESENTACION - VIGENCIA - '|| c_fcha.clmna2 ||' PERIODICIDAD - '|| c_fcha.clmna2 ,
														null,
														to_date(c_fcha.clmna4,'DD/MM/YYYY'),
														null,
														'N',
														v_id_sjto_tpo);
			exception
				when others then
					o_cdgo_rspsta:= 40;
					o_mnsje_rspsta := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: '||o_cdgo_rspsta|| ' no se realizao insert de fecha de presentacion de la declaracion - id_dclrcion_tpo_vgncia - '|| v_id_dclrcion_tpo_vgncia  || ' -  '|| SQLERRM;
					update migra.MG_G_INTERMEDIA_DURB_DECLARA
					set clmna20 = '40' ,
						clmna21 = o_mnsje_rspsta
					where id_intrmdia = c_fcha.id_intrmdia;
					v_errors.extend;
					v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_fcha.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;


			--Se actualiza el estado de los registros procesados en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA
			begin
				update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
				set     a.cdgo_estdo_rgstro =   'S'
				where   a.cdgo_clnte        =   p_cdgo_clnte
				and     id_entdad           =   p_id_entdad
				and 	id_intrmdia			= 	c_fcha.id_intrmdia
				and     cdgo_estdo_rgstro   =   'L';

				o_ttal_extsos 	:= o_ttal_extsos + 1;
			exception
				when others then
					o_cdgo_rspsta   := 50;
					o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || ' -  '|| SQLERRM;
					continue;
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
				o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM;
				--v_errors.extend;
				--v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
				return;
		end;

		--Se actualizan en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA como error
		begin
			forall j in 1 .. o_ttal_error
			update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
			set     a.cdgo_estdo_rgstro =   'E'
			where   a.id_entdad           =   p_id_entdad
			and    a.id_intrmdia       =   v_errors(j).id_intrmdia;
		exception
			when others then
				o_cdgo_rspsta   := 80;
				o_mnsje_rspsta  := '|DCLRCNES_FCHA_PRSNTC_MIG_02-Proceso No. 20 - Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || ' -  '|| SQLERRM;
				--v_errors.extend;
				--v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
				return;
		end;

		commit;
		--Se actualizan y recorren los errores
		--Respuesta Exitosa
		o_mnsje_rspsta := 'Exito';



	end prc_mg_d_dclrcnes_fcha_prsntc;


	/*===================================================*/
	/*=========MIGRACION DECLARACIONES ICA===============*/
	/*===================================================*/

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
		v_cdgo_dclrcn_tpo				varchar2(5);
		v_id_dclrcn_tpo     			number;
		v_id_impsto						number;
		v_id_impsto_sbmpsto				number;
		v_prdo							varchar2(100);
		v_cdgo_prdcdad					varchar2(5);
		v_id_prdo						number;
		v_id_dclrcion_tpo_vgncia		number;
		v_id_dclrcion_vgncia_frmlrio	number;
		v_id_frmlrio					number;
		v_id_sjto_impsto				number;
		v_id_sjto						number;

	begin
		o_cdgo_rspsta := 0;


			if p_type_dclrcnes.clmna1 = '02' and p_type_dclrcnes.clmna21 = 'ANU' then
				v_cdgo_dclrcn_tpo := 'ICA2A';
			elsif p_type_dclrcnes.clmna1 = '02' and p_type_dclrcnes.clmna21 = 'BIM' then
				v_cdgo_dclrcn_tpo := 'ICA2B';
			elsif p_type_dclrcnes.clmna1 = '03' and p_type_dclrcnes.clmna2 not in ('2004', '2005') then
				v_cdgo_dclrcn_tpo := 'RTCA3';
      elsif p_type_dclrcnes.clmna1 = '03' and p_type_dclrcnes.clmna2 in ('2004', '2005') then
				v_cdgo_dclrcn_tpo := 'RTCA4';
			elsif p_type_dclrcnes.clmna1 = '04' then
				v_cdgo_dclrcn_tpo := 'ICA04';
			elsif p_type_dclrcnes.clmna1 = '05' then
				v_cdgo_dclrcn_tpo := 'ICA05';
			elsif p_type_dclrcnes.clmna1 = '08' then
				v_cdgo_dclrcn_tpo := 'ICA08';
			elsif p_type_dclrcnes.clmna1 = '09' then
				v_cdgo_dclrcn_tpo := 'ICA09';
			elsif p_type_dclrcnes.clmna1 = '10' then
				v_cdgo_dclrcn_tpo := 'ICA10';
      elsif p_type_dclrcnes.clmna1 = '11' then
				v_cdgo_dclrcn_tpo := 'ICA11';
      elsif p_type_dclrcnes.clmna1 = '12' then
				v_cdgo_dclrcn_tpo := 'ICA12';
      end if;

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
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el tipo de declaracion. ' || sqlerrm;
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
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el tipo de declaracion. ' || sqlerrm;
				return;
		end;

		v_prdo := p_type_dclrcnes.clmna3;

		if (v_prdo = '0') then
			v_prdo := '1';
		end if;

		--Se valida el periodo
		begin
			select  a.id_prdo
			into	v_id_prdo
			from    df_i_periodos a
			where   a.cdgo_clnte        =   p_cdgo_clnte
			and     a.id_impsto         =   v_id_impsto
			and     a.id_impsto_sbmpsto =   v_id_impsto_sbmpsto
			and     a.vgncia            =   to_char(p_type_dclrcnes.clmna2)
			and     a.prdo              =   v_prdo
			and     a.cdgo_prdcdad      =   v_cdgo_prdcdad;

		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo. ' || chr(13) ||
									'p_cdgo_clnte: ' || p_cdgo_clnte || chr(13) ||
									'v_id_impsto: ' || v_id_impsto || chr(13) ||
									'v_id_impsto_sbmpsto: ' || v_id_impsto_sbmpsto || chr(13) ||
									'p_type_dclrcnes.clmna2: ' || p_type_dclrcnes.clmna2 || chr(13) ||
									'p_type_dclrcnes.clmna3: ' || p_type_dclrcnes.clmna3 || chr(13) ||
									'v_prdo: ' || v_prdo || chr(13) ||
									' Prueba v_cdgo_prdcdad: ' || v_cdgo_prdcdad || chr(13) ||
									sqlerrm;
				return;
		end;

		begin
			v_json_object_t.put('id_prdo', v_id_prdo);
		exception
			when others then
				o_cdgo_rspsta   := 3.5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo. ' || chr(13) ||
									'p_cdgo_clnte: ' || p_cdgo_clnte || chr(13) ||
									'v_id_impsto: ' || v_id_impsto || chr(13) ||
									'v_id_impsto_sbmpsto: ' || v_id_impsto_sbmpsto || chr(13) ||
									'p_type_dclrcnes.clmna2: ' || p_type_dclrcnes.clmna2 || chr(13) ||
									'p_type_dclrcnes.clmna3: ' || p_type_dclrcnes.clmna3 || chr(13) ||
									'v_cdgo_prdcdad: ' || v_cdgo_prdcdad || chr(13) ||
									sqlerrm;
				return;
		end;

		--Se valida el periodo en el tipo de declaracion
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
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el periodo en el tipo de declaracion. ' || sqlerrm;
				return;
		end;

		--Se valida el formulario
		v_id_frmlrio := case when v_cdgo_dclrcn_tpo = 'ICA2A'	then 733
							 when v_cdgo_dclrcn_tpo = 'ICA2B'	then 733
							 when v_cdgo_dclrcn_tpo = 'RTCA3'	then 724
               when v_cdgo_dclrcn_tpo = 'RTCA4'	then 744
							 when v_cdgo_dclrcn_tpo = 'ICA04'	then 725
							 when v_cdgo_dclrcn_tpo = 'ICA05' then 726
							 when v_cdgo_dclrcn_tpo = 'ICA08'	then 727
							 when v_cdgo_dclrcn_tpo = 'ICA09'	then 728
							 when v_cdgo_dclrcn_tpo = 'ICA10'	then 729
							 when v_cdgo_dclrcn_tpo = 'ICA11'	then 730
							 when v_cdgo_dclrcn_tpo = 'ICA12'	then 731
						else null
						end;

		if (v_id_frmlrio is null) then
			o_cdgo_rspsta   := 5;
			o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el formulario. ' || sqlerrm;
			return;
		end if;

		--Se valida la vigencia formularios
		begin
			select  a.id_dclrcion_vgncia_frmlrio
			into	v_id_dclrcion_vgncia_frmlrio
			from    gi_d_dclrcnes_vgncias_frmlr a
			where   a.id_dclrcion_tpo_vgncia    =   v_id_dclrcion_tpo_vgncia
			and     a.id_frmlrio                =   v_id_frmlrio;
		exception
			when no_data_found then
				null;
			when others then
				o_cdgo_rspsta   := 8;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la relacion entre el periodo en el tipo de declaracion y el formulario. ' || sqlerrm;
				return;
		end;

		--Se valida que no haya una vigencia formulario con un formulario diferente
		/*if (v_id_dclrcion_vgncia_frmlrio in (121, 161)) then
			v_id_frmlrio := 66;
		end if;*/

		--Si la relacion entre el periodo en el tipo de declaracion y el formulario no existe se registra
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
					o_cdgo_rspsta   := 9;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la relacion entre el periodo en el tipo de declaracion y el formulario. ' || sqlerrm;
					return;
			end;

			--Se valida la vigencia formulario
			--En este momento se de esta forma porque el returning no funcion en un insert desde un db_link
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
					o_cdgo_rspsta   := 10;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la relacion entre el periodo en el tipo de declaracion y el formulario. ' || sqlerrm;
					return;
			end;*/
		end if;

		v_json_object_t.put('id_dclrcion_vgncia_frmlrio', v_id_dclrcion_vgncia_frmlrio);
		v_json_object_t.put('id_frmlrio', v_id_frmlrio);

		--Se valida el sujeto impuesto
		begin
			select      b.id_sjto_impsto
			into        v_id_sjto_impsto
			from        si_c_sujetos            a
			inner join  si_i_sujetos_impuesto   b   on  b.id_sjto   =   a.id_sjto
			where       a.cdgo_clnte    =   p_cdgo_clnte
			and         (a.idntfccion    =   to_char(p_type_dclrcnes.clmna4) or a.idntfccion_antrior = to_char(p_type_dclrcnes.clmna4))
			and         b.id_impsto     =   v_id_impsto;
		exception
			when no_data_found then
				null;
			when others then
				o_cdgo_rspsta   := 11;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el sujeto impuesto. ' || sqlerrm;
				return;
		end;

		--Si no existe se registra el sujeto impuesto con datos basicos
		if (v_id_sjto_impsto is null) then
			--Se registra el sujeto
			begin
				select  a.id_sjto
				into    v_id_sjto
				from    si_c_sujetos    a
				where   a.cdgo_clnte        =   p_cdgo_clnte
				and		(
							a.idntfccion = to_char(p_type_dclrcnes.clmna4) or
							a.idntfccion_antrior = to_char(p_type_dclrcnes.clmna4)
						);
			exception
				when no_data_found then
					begin
						insert into si_c_sujetos	(
														cdgo_clnte,
														idntfccion,
														idntfccion_antrior,
														estdo_blqdo
													)
											values	(
														p_cdgo_clnte,
														to_char(p_type_dclrcnes.clmna4),
														to_char(p_type_dclrcnes.clmna4),
														'S'

													) returning id_sjto into v_id_sjto;
					exception
						when others then
							o_cdgo_rspsta   := 12;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el sujeto. ' || sqlerrm;
							return;
					end;
				when others then
					o_cdgo_rspsta   := 13;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el sujeto. ' || sqlerrm;
					return;
			end;

			--Se registra el sujeto impuesto
			begin
				insert into si_i_sujetos_impuesto	(
														id_sjto,
														id_impsto,
														estdo_blqdo,
														fcha_rgstro,
														id_usrio,
														id_sjto_estdo
													)
											values	(
														v_id_sjto,
														v_id_impsto,
														'S',
														systimestamp,
														1,
														2
													) returning id_sjto_impsto into v_id_sjto_impsto;
			exception
				when others then
					o_cdgo_rspsta   := 14;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el sujeto impuesto. ' || sqlerrm;
					return;
			end;
		end if;

		v_json_object_t.put('id_sjto_impsto', v_id_sjto_impsto);

		o_json := v_json_object_t.to_clob;

	end prc_co_datos_migracion;

	--Registro del detalle de la declaracion para el formulario 305
	procedure prc_rg_dtlle_frmlrio_ICA02	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number := 0;
		v_vlor_avsos_tblros			number := 0;
		v_vlor_sbrtsa_bmbril		number := 0;
		v_vlor_sbrtsa_sgrdad		number := 0;
		v_vlor_sncnes				number := 0;
		v_vlor_ica					number := 0;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4591';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4592';
				elsif (c_dtlle.clmna16 = 11) then
					v_id_frmlrio_rgion_atrbto	:= '4593';
				elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4594';
				elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4595';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4596';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4597';
        elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4632';
				elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4599';
				--	v_vlor_avsos_tblros			:= to_number(c_dtlle.clmna18);
				elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4600';
				elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4601';
				--	v_vlor_sbrtsa_bmbril		:= to_number(c_dtlle.clmna18);
				elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4602';
				--	v_vlor_sbrtsa_sgrdad		:= to_number(c_dtlle.clmna18);
				elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4603';
				elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4604';
				elsif (c_dtlle.clmna16 = 30) then
					v_id_frmlrio_rgion_atrbto	:= '4605';
				elsif (c_dtlle.clmna16 = 31) then
					v_id_frmlrio_rgion_atrbto	:= '4606';
				elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '4608';
				elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '4610';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
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
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														983,
														4494,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA02;

	--Registro del detalle de la declaracion para el formulario 344
	procedure prc_rg_dtlle_frmlrio_RETEICA	(p_id_entdad			in  number,
								--		 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4582';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4583';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4584';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4585';
				elsif (c_dtlle.clmna16 = 11) then
					v_id_frmlrio_rgion_atrbto	:= '4586';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4587';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4588';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4590';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
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
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														967,
														4365,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_RETEICA;

  procedure prc_rg_dtlle_frmlrio_RETEICA04  (p_id_entdad      in  number,
                --     p_id_prcso_instncia  in  number,
                     p_id_usrio           in  number,
                     p_cdgo_clnte         in  number,
                     p_id_dclrcion      in  number,
                     p_type_dclrcnes    in  pkg_mg_migracion_dcl2.type_dclrcnes,
                     o_cdgo_rspsta        out number,
                     o_mnsje_rspsta     out varchar2) as

    v_id_frmlrio_rgion      number;
    v_id_frmlrio_rgion_atrbto varchar2(4000);
    v_orden           number := 0;

    v_vlor_sldo_pgar      number;
    v_vlor_avsos_tblros     number;
    v_vlor_sncnes       number;
    v_vlor_ica          number;

    v_idntfccion_sjto     varchar(1000);

  begin
    o_cdgo_rspsta := 0;
    --Se recorre el detalle de la declaracion de los items netos
    begin
      for c_dtlle in  (
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
        if (c_dtlle.clmna16 = 7) then
          v_id_frmlrio_rgion_atrbto := '4626';
        elsif (c_dtlle.clmna16 = 8) then
          v_id_frmlrio_rgion_atrbto := '4627';
        elsif (c_dtlle.clmna16 = 9) then
          v_id_frmlrio_rgion_atrbto := '4628';
        elsif (c_dtlle.clmna16 = 10) then
          v_id_frmlrio_rgion_atrbto := '4629';
        elsif (c_dtlle.clmna16 = 11) then
          v_id_frmlrio_rgion_atrbto := '4630';
        elsif (c_dtlle.clmna16 = 21) then
          v_id_frmlrio_rgion_atrbto := '4631';
        end if;

        --Se recorren los atributos por items
        for c_atrbto in (
                  select  regexp_substr(v_id_frmlrio_rgion_atrbto,'[^,]+', 1, level) as id_frmlrio_rgion_atrbto
                  from    dual
                  connect by  regexp_substr(v_id_frmlrio_rgion_atrbto, '[^,]+', 1, level) is not null
                )
        loop
          --Se valida la region del atributo
          begin
            select  a.id_frmlrio_rgion
            into  v_id_frmlrio_rgion
            from    gi_d_frmlrios_rgion_atrbto  a
            where   a.id_frmlrio_rgion_atrbto   =   c_atrbto.id_frmlrio_rgion_atrbto;
          exception
            when others then
              o_cdgo_rspsta   := 1;
              o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
              return;
          end;

          v_orden := v_orden + 1;

          --Se inserta el registro del detalle de la declaracion
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
              o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
              return;
          end;

        end loop;
      end loop;
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
        o_cdgo_rspsta   := 6;
        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
        return;
    end;

    --Se registra la identificacion
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
                            987,
                            4625,
                            1,
                            v_orden,
                            v_idntfccion_sjto,
                            v_idntfccion_sjto
                          );
    exception
      when others then
        o_cdgo_rspsta   := 7;
        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
        return;
    end;

  end prc_rg_dtlle_frmlrio_RETEICA04;

	--Registro del detalle de la declaracion para el formulario 364
	procedure prc_rg_dtlle_frmlrio_ICA04	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4371';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4372';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4373';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4374';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4375';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4376';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4377';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4378';
        elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4379';
        elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4380';
        elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4381';
         elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4382';
         elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4383';
          elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4384';
         elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4385';
         elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4386';
         elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4387';
        elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4388';
        elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4389';
        elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4390';
        elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4391';
        elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4392';
        elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4393';
         elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4394';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														969,
														4366,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA04;

	--Registro del detalle de la declaracion para el formulario 364
	procedure prc_rg_dtlle_frmlrio_ICA05	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4395';
				elsif (c_dtlle.clmna16 = 4) then
					v_id_frmlrio_rgion_atrbto	:= '4396';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4397';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4398';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4399';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4400';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4401';
				elsif (c_dtlle.clmna16 = 11) then
					v_id_frmlrio_rgion_atrbto	:= '4402';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4403';
        elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4404';
        elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4405';
       elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4406';
       elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4407';
       elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4408';
       elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4409';
       elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4410';
       elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4411';
       elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4412';
       elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4413';
       elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4414';
      elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4415';
      elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4416';
      elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4417';
      elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4418';
      elsif (c_dtlle.clmna16 = 30) then
					v_id_frmlrio_rgion_atrbto	:= '4419';
      elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '4420';
      elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '4421';
      elsif (c_dtlle.clmna16 = 34) then
					v_id_frmlrio_rgion_atrbto	:= '4422';
      elsif (c_dtlle.clmna16 = 35) then
					v_id_frmlrio_rgion_atrbto	:= '4423';
      elsif (c_dtlle.clmna16 = 36) then
					v_id_frmlrio_rgion_atrbto	:= '4424';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														971,
														4367,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA05;

	--Registro del detalle de la declaracion para el formulario 404
	procedure prc_rg_dtlle_frmlrio_ICA08	(p_id_entdad			in  number,
									--	 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4425';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4426';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4427';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4428';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4429';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4430';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4431';
				elsif (c_dtlle.clmna16 = 11) then
					v_id_frmlrio_rgion_atrbto	:= '4432';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4433';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4434';
       	elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4435';
       	elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4436';
       	elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4437';
       	elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4438';
       	elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4439';
        elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4440';
        elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4441';
        elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4442';
        elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4443';
        elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4444';
        elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4445';
        elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4446';
        elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4447';
        elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4448';
        elsif (c_dtlle.clmna16 = 31) then
					v_id_frmlrio_rgion_atrbto	:= '4449';
        elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '4450';
        elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '4451';
        elsif (c_dtlle.clmna16 = 34) then
					v_id_frmlrio_rgion_atrbto	:= '4452';
        elsif (c_dtlle.clmna16 = 35) then
					v_id_frmlrio_rgion_atrbto	:= '4453';
        elsif (c_dtlle.clmna16 = 84) then
					v_id_frmlrio_rgion_atrbto	:= '4633';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														973,
														4368,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA08;

	--Registro del detalle de la declaracion para el formulario 424
	procedure prc_rg_dtlle_frmlrio_ICA09	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4454';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4455';
				elsif (c_dtlle.clmna16 = 4) then
					v_id_frmlrio_rgion_atrbto	:= '4456';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4457';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4458';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4459';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4460';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4461';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4462';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4463';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4465';
				elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4466';
				elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4467';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4468';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4469';
				elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4470';
				elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4471';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4472';
				elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4473';
				elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4483';
				elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4485';
				elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4486';
				elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4478';
				elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4479';
				elsif (c_dtlle.clmna16 = 30) then
					v_id_frmlrio_rgion_atrbto	:= '4480';
				elsif (c_dtlle.clmna16 = 31) then
					v_id_frmlrio_rgion_atrbto	:= '4481';
				elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '4487';
				elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '4474';
				elsif (c_dtlle.clmna16 = 34) then
					v_id_frmlrio_rgion_atrbto	:= '4476';
				elsif (c_dtlle.clmna16 = 35) then
					v_id_frmlrio_rgion_atrbto	:= '4477';
				elsif (c_dtlle.clmna16 = 36) then
					v_id_frmlrio_rgion_atrbto	:= '4482';
				elsif (c_dtlle.clmna16 = 38) then
					v_id_frmlrio_rgion_atrbto	:= '4488';
        elsif (c_dtlle.clmna16 = 39) then
					v_id_frmlrio_rgion_atrbto	:= '4489';
       elsif (c_dtlle.clmna16 = 40) then
					v_id_frmlrio_rgion_atrbto	:= '4490';
      elsif (c_dtlle.clmna16 = 41) then
					v_id_frmlrio_rgion_atrbto	:= '4491';
      elsif (c_dtlle.clmna16 = 42) then
					v_id_frmlrio_rgion_atrbto	:= '4492';
       elsif (c_dtlle.clmna16 = 43) then
					v_id_frmlrio_rgion_atrbto	:= '4493';
       elsif (c_dtlle.clmna16 = 44) then
					v_id_frmlrio_rgion_atrbto	:= '4494';
       elsif (c_dtlle.clmna16 = 45) then
					v_id_frmlrio_rgion_atrbto	:= '4495';
       elsif (c_dtlle.clmna16 = 46) then
					v_id_frmlrio_rgion_atrbto	:= '4496';
       elsif (c_dtlle.clmna16 = 47) then
					v_id_frmlrio_rgion_atrbto	:= '4497';
       elsif (c_dtlle.clmna16 = 48) then
					v_id_frmlrio_rgion_atrbto	:= '4498';
       elsif (c_dtlle.clmna16 = 49) then
					v_id_frmlrio_rgion_atrbto	:= '4499';
       elsif (c_dtlle.clmna16 = 51) then
					v_id_frmlrio_rgion_atrbto	:= '4500';
       elsif (c_dtlle.clmna16 = 52) then
					v_id_frmlrio_rgion_atrbto	:= '4501';
       elsif (c_dtlle.clmna16 = 53) then
					v_id_frmlrio_rgion_atrbto	:= '4502';
       elsif (c_dtlle.clmna16 = 54) then
					v_id_frmlrio_rgion_atrbto	:= '4503';
       elsif (c_dtlle.clmna16 = 55) then
					v_id_frmlrio_rgion_atrbto	:= '4504';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														975,
														4369,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA09;

	--Registro del detalle de la declaracion para el formulario 424
	procedure prc_rg_dtlle_frmlrio_ICA10	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4505';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4506';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4507';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4508';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4509';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4510';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4511';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4512';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4513';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4514';
				elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4515';
				elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4516';
				elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4517';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4518';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4519';
				elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4520';
				elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4521';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4522';
				elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4523';
				elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4524';
				elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4525';
        elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4526';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														977,
														4370,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA10;

	--Registro del detalle de la declaracion para el formulario 464
	procedure prc_rg_dtlle_frmlrio_ICA11	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4527';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4528';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4529';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4530';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4531';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4532';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4533';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4534';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4535';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4536';
				elsif (c_dtlle.clmna16 = 14) then
					v_id_frmlrio_rgion_atrbto	:= '4537';
				elsif (c_dtlle.clmna16 = 15) then
					v_id_frmlrio_rgion_atrbto	:= '4538';
				elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4539';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4542';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4543';
				elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4544';
				elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4545';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4546';
				elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4547';
				elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4548';
				elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4549';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														979,
														4464,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA11;

	--Registro del detalle de la declaracion para el formulario 484
	procedure prc_rg_dtlle_frmlrio_ICA12	(p_id_entdad			in  number,
										-- p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_id_dclrcion			in	number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_id_frmlrio_rgion			number;
		v_id_frmlrio_rgion_atrbto	varchar2(4000);
		v_orden						number := 0;

		v_vlor_sldo_pgar			number;
		v_vlor_avsos_tblros			number;
		v_vlor_sncnes				number;
		v_vlor_ica					number;

		v_idntfccion_sjto			varchar(1000);

	begin
		o_cdgo_rspsta := 0;
		--Se recorre el detalle de la declaracion de los items netos
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
				if (c_dtlle.clmna16 = 2) then
					v_id_frmlrio_rgion_atrbto	:= '4550';
				elsif (c_dtlle.clmna16 = 3) then
					v_id_frmlrio_rgion_atrbto	:= '4551';
				elsif (c_dtlle.clmna16 = 5) then
					v_id_frmlrio_rgion_atrbto	:= '4552';
				elsif (c_dtlle.clmna16 = 6) then
					v_id_frmlrio_rgion_atrbto	:= '4553';
				elsif (c_dtlle.clmna16 = 7) then
					v_id_frmlrio_rgion_atrbto	:= '4554';
				elsif (c_dtlle.clmna16 = 8) then
					v_id_frmlrio_rgion_atrbto	:= '4555';
				elsif (c_dtlle.clmna16 = 9) then
					v_id_frmlrio_rgion_atrbto	:= '4556';
				elsif (c_dtlle.clmna16 = 10) then
					v_id_frmlrio_rgion_atrbto	:= '4557';
				elsif (c_dtlle.clmna16 = 11) then
					v_id_frmlrio_rgion_atrbto	:= '4558';
				elsif (c_dtlle.clmna16 = 12) then
					v_id_frmlrio_rgion_atrbto	:= '4559';
				elsif (c_dtlle.clmna16 = 13) then
					v_id_frmlrio_rgion_atrbto	:= '4560';
				elsif (c_dtlle.clmna16 = 16) then
					v_id_frmlrio_rgion_atrbto	:= '4561';
				elsif (c_dtlle.clmna16 = 17) then
					v_id_frmlrio_rgion_atrbto	:= '4562';
				elsif (c_dtlle.clmna16 = 18) then
					v_id_frmlrio_rgion_atrbto	:= '4563';
				elsif (c_dtlle.clmna16 = 19) then
					v_id_frmlrio_rgion_atrbto	:= '4564';
				elsif (c_dtlle.clmna16 = 20) then
					v_id_frmlrio_rgion_atrbto	:= '4565';
				elsif (c_dtlle.clmna16 = 21) then
					v_id_frmlrio_rgion_atrbto	:= '4566';
				elsif (c_dtlle.clmna16 = 22) then
					v_id_frmlrio_rgion_atrbto	:= '4567';
				elsif (c_dtlle.clmna16 = 23) then
					v_id_frmlrio_rgion_atrbto	:= '4568';
				elsif (c_dtlle.clmna16 = 24) then
					v_id_frmlrio_rgion_atrbto	:= '4569';
				elsif (c_dtlle.clmna16 = 25) then
					v_id_frmlrio_rgion_atrbto	:= '4570';
				elsif (c_dtlle.clmna16 = 26) then
					v_id_frmlrio_rgion_atrbto	:= '4571';
				elsif (c_dtlle.clmna16 = 27) then
					v_id_frmlrio_rgion_atrbto	:= '4572';
        elsif (c_dtlle.clmna16 = 28) then
					v_id_frmlrio_rgion_atrbto	:= '4573';
        elsif (c_dtlle.clmna16 = 29) then
					v_id_frmlrio_rgion_atrbto	:= '4574';
       elsif (c_dtlle.clmna16 = 30) then
					v_id_frmlrio_rgion_atrbto	:= '4575';
       elsif (c_dtlle.clmna16 = 31) then
					v_id_frmlrio_rgion_atrbto	:= '4576';
      elsif (c_dtlle.clmna16 = 32) then
					v_id_frmlrio_rgion_atrbto	:= '4577';
       elsif (c_dtlle.clmna16 = 33) then
					v_id_frmlrio_rgion_atrbto	:= '4578';
       elsif (c_dtlle.clmna16 = 34) then
					v_id_frmlrio_rgion_atrbto	:= '4579';
       elsif (c_dtlle.clmna16 = 35) then
					v_id_frmlrio_rgion_atrbto	:= '4580';
       elsif (c_dtlle.clmna16 = 36) then
					v_id_frmlrio_rgion_atrbto	:= '4581';
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la region del atributo. ' || sqlerrm;
							return;
					end;

					v_orden := v_orden + 1;

					--Se inserta el registro del detalle de la declaracion
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
							return;
					end;

				end loop;
			end loop;
		end;

		--Se obtiene el valor ica
		/*begin
			v_vlor_ica := v_vlor_sldo_pgar - v_vlor_avsos_tblros - v_vlor_sncnes;

			if (v_vlor_ica < 0) then
				v_vlor_ica := 0;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo obtenerse el valor ica. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica neto
		/*begin
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
														552,
														2419,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA neto. ' || sqlerrm;
				return;
		end;*/

		--se registra el valor de ica
		/*begin
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
														552,
														2422,
														1,
														v_orden,
														to_clob(v_vlor_ica),
														to_clob(v_vlor_ica)
													);
		exception
			when others then
				o_cdgo_rspsta   := 5;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el valor de ICA. ' || sqlerrm;
				return;
		end;*/

		--Se valida la identificacion
		begin
			select  b.idntfccion_sjto
			into    v_idntfccion_sjto
			from    gi_g_declaraciones      a
			join    v_si_i_sujetos_impuesto b   on  b.id_sjto_impsto    =   a.id_sjto_impsto
			where   a.id_dclrcion   =   p_id_dclrcion;
		exception
			when others then
				o_cdgo_rspsta   := 6;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

		--Se registra la identificacion
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
														981,
														4475,
														1,
														v_orden,
														v_idntfccion_sjto,
														v_idntfccion_sjto
													);
		exception
			when others then
				o_cdgo_rspsta   := 7;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el atributo en el detalle de la declaracion. ' || sqlerrm;
				return;
		end;

	end prc_rg_dtlle_frmlrio_ICA12;

	procedure prc_rg_dclrcnes_encbzdo	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 p_type_dclrcnes		in	pkg_mg_migracion_dcl2.type_dclrcnes,
										 o_id_dclrcion			out	number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		v_json_object_t					json_object_t := json_object_t();

		--v_hmlgcion          			pkg_mg_migracion.r_hmlgcion;
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

		--Carga los Datos de la Homologacion
       /* v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);*/

		--Se homologa el codigo tipo de declaracion

    if p_type_dclrcnes.clmna1 = '02' and p_type_dclrcnes.clmna21 = 'ANU' then
        v_cdgo_dclrcn_tpo := 'ICA2A';
      elsif p_type_dclrcnes.clmna1 = '02' and p_type_dclrcnes.clmna21 = 'BIM' then
        v_cdgo_dclrcn_tpo := 'ICA2B';
      elsif p_type_dclrcnes.clmna1 = '03' and p_type_dclrcnes.clmna2 not in ('2004', '2005') then
        v_cdgo_dclrcn_tpo := 'RTCA3';
      elsif p_type_dclrcnes.clmna1 = '03' and p_type_dclrcnes.clmna2 in ('2004', '2005') then
        v_cdgo_dclrcn_tpo := 'RTCA4';
      elsif p_type_dclrcnes.clmna1 = '04' then
        v_cdgo_dclrcn_tpo := 'ICA04';
      elsif p_type_dclrcnes.clmna1 = '05' then
        v_cdgo_dclrcn_tpo := 'ICA05';
      elsif p_type_dclrcnes.clmna1 = '08' then
        v_cdgo_dclrcn_tpo := 'ICA08';
      elsif p_type_dclrcnes.clmna1 = '09' then
        v_cdgo_dclrcn_tpo := 'ICA09';
      elsif p_type_dclrcnes.clmna1 = '10' then
        v_cdgo_dclrcn_tpo := 'ICA10';
      elsif p_type_dclrcnes.clmna1 = '11' then
        v_cdgo_dclrcn_tpo := 'ICA11';
      elsif p_type_dclrcnes.clmna1 = '12' then
        v_cdgo_dclrcn_tpo := 'ICA12';
      end if;

		--Se validan los datos de la declaracion para obtener la vigencia formulario
		begin
			pkg_mg_migracion_dcl2.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
															 p_id_prcso_instncia	=>	p_id_prcso_instncia,
															 p_id_usrio          	=>	p_id_usrio,
															 p_cdgo_clnte        	=>	p_cdgo_clnte,
															 p_type_dclrcnes		=>	p_type_dclrcnes,
															 o_json					=>	v_json,
															 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
															 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			if (o_cdgo_rspsta <> 0) then
				o_cdgo_rspsta   := 2;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || chr(13) ||
									o_mnsje_rspsta || chr(13) ||
									sqlerrm;
				return;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 3;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || sqlerrm;
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

		--se valida el uso de la declaracion
		begin
			select  a.id_dclrcion_uso
			into    v_id_dclrcion_uso
			from    gi_d_declaraciones_uso a
			where   a.cdgo_clnte        =   p_cdgo_clnte
			and     a.cdgo_dclrcion_uso =   to_char(p_type_dclrcnes.clmna7);
		exception
			when others then
				o_cdgo_rspsta   := 4;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse el uso de la declaracion. ' || sqlerrm;
				return;
		end;

		--En caso de ser necesario se valida la declaracion que se corrige
		if (p_type_dclrcnes.clmna8 is not null) then
			begin
				select  a.id_dclrcion
				into	v_id_dclrcion_crrccion
				from    gi_g_declaraciones a
				where   a.id_sjto_impsto            =   v_id_sjto_impsto
				and     a.nmro_cnsctvo              =   to_char(p_type_dclrcnes.clmna8);
			exception
				when others then
					o_cdgo_rspsta   := 5;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse la declaracion que se corrige. clmna8: ''' || to_char(p_type_dclrcnes.clmna8) || '''' || chr(13) ||
										sqlerrm;
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
												nvl(to_timestamp(to_char(p_type_dclrcnes.clmna9), 'DD/MM/YYYY HH24:MI:SS'), to_timestamp(to_char(p_type_dclrcnes.clmna10), 'DD/MM/YYYY HH24:MI:SS')),
												nvl(to_timestamp(to_char(p_type_dclrcnes.clmna10), 'DD/MM/YYYY HH24:MI:SS'), to_timestamp(to_char(p_type_dclrcnes.clmna9), 'DD/MM/YYYY HH24:MI:SS')),
												to_number(p_type_dclrcnes.clmna13),
												to_number(p_type_dclrcnes.clmna14),
												0
											) returning id_dclrcion into o_id_dclrcion;
		exception
			when others then
					o_cdgo_rspsta   := 6;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion. ' || sqlerrm;
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
					o_cdgo_rspsta   := 7;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la declaracion registrada. ' || sqlerrm;
					return;
		end;*/

		/*
		==============================
		Detalle de la declaracion segun formulario
		*/

		--Se registra el el detalle
    /*
		begin
			if (v_id_frmlrio = 733) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA02	(p_id_entdad			=>	p_id_entdad,
											--					 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 724) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_RETEICA	(p_id_entdad			=>	p_id_entdad,
													--			 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

      elsif (v_id_frmlrio = 744) then
        pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_RETEICA04  (p_id_entdad      =>  p_id_entdad,
                          --       p_id_prcso_instncia  =>  p_id_prcso_instncia,
                                 p_id_usrio           =>  p_id_usrio,
                                 p_cdgo_clnte         =>  p_cdgo_clnte,
                                 p_id_dclrcion      =>  o_id_dclrcion,
                                 p_type_dclrcnes    =>  p_type_dclrcnes,
                                 o_cdgo_rspsta        =>  o_cdgo_rspsta,
                                 o_mnsje_rspsta     =>  o_mnsje_rspsta);

			elsif (v_id_frmlrio = 725) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA04	(p_id_entdad			=>	p_id_entdad,
														--		 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 726) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA05	(p_id_entdad			=>	p_id_entdad,
															--	 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 727) then --ICA08
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA08	(p_id_entdad			=>	p_id_entdad,
															--	 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 728) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA09	(p_id_entdad			=>	p_id_entdad,
															--	 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 729) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA10	(p_id_entdad			=>	p_id_entdad,
															--	 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 730) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA11	(p_id_entdad			=>	p_id_entdad,
															--	 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

			elsif (v_id_frmlrio = 731) then
				pkg_mg_migracion_dcl2.prc_rg_dtlle_frmlrio_ICA12	(p_id_entdad			=>	p_id_entdad,
																-- p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_id_dclrcion			=>	o_id_dclrcion,
																 p_type_dclrcnes		=>	p_type_dclrcnes,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);
			else
				o_cdgo_rspsta   := 8;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Formulario invalido v_id_frmlrio: ' || v_id_frmlrio || chr(13) ||
									o_mnsje_rspsta || chr(13) ||
									sqlerrm;

				return;
			end if;

			if (o_cdgo_rspsta <> 0) then
				o_cdgo_rspsta   := 9;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el detalle la declaracion. ' || sqlerrm || chr(13) ||
				o_mnsje_rspsta;
				return;
			end if;
		exception
			when others then
				o_cdgo_rspsta   := 10;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse el detalle la declaracion. ' || sqlerrm;
				return;
		end;

    */

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
				update	MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
				set		clmna30				= 	o_id_dclrcion
				where	a.id_intrmdia		=	c_item.id_intrmdia;
			end loop;
		exception
			when others then
				o_cdgo_rspsta   := 11;
				o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo marcarse en la tabla intermedia. ' || sqlerrm;
				return;
		end;

		--Se recorren las declaraciones de correccion
		for c_dclrcnes in	(
								select  min(a.id_intrmdia) id_intrmdia,
										a.clmna1,	--Codigo Declaracion
										a.clmna2,	--Vigencia
										a.clmna3,	--Codigo del periodo
										a.clmna4,	--Identificacion del declarante
										a.clmna5,	--Numero de declaracion
										a.clmna6,	--Codigo de estado de la declaracion
										a.clmna7,	--Codigo de uso de la declaracion
										a.clmna8,	--Numero de declaracion de correccion
										a.clmna9,	--Fecha de registro de la declaracion
										a.clmna10,	--Fecha de presentacion de la declaracion
										a.clmna11,	--Fecha proyectada de presentacion de la declaracion
										a.clmna12,	--Fecha de aplicacion de la declaracion
										a.clmna13,	--Base gravable de la declaracion
										a.clmna14,	--Valor total de la declaracion
										a.clmna15,	--Valor pago de la declaracion
										a.clmna21,	--Periodicidad
										json_arrayagg(
														json_object(
																	'id_intrmdia'   value   a.id_intrmdia,
																	'clmna16'       value   a.clmna16,		--Reglon Declaracion
																	'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																	'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																	returning clob
																   )
														returning clob
													 ) as items
								from    MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
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
											a.clmna15,
											a.clmna21
							)
		loop
			--Se setea a nivel de vairable el registro que corresponde a la declaracion
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
						to_clob(c_dclrcnes.clmna21),
						to_clob(c_dclrcnes.items)
				into	v_type_dclrcnes
				from	dual;
			exception
				when others then
					o_cdgo_rspsta   := 12;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo setearse a nivel de vairable el registro que corresponde a la declaracion. ' || sqlerrm;
			end;

			--Se busca la correccion de la declaracion
			begin
				pkg_mg_migracion_dcl2.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
																 p_id_prcso_instncia	=>	p_id_prcso_instncia,
																 p_id_usrio          	=>	p_id_usrio,
																 p_cdgo_clnte        	=>	p_cdgo_clnte,
																 p_type_dclrcnes		=>	v_type_dclrcnes,
																 o_id_dclrcion			=>	v_id_dclrcion_crrccion,
																 o_cdgo_rspsta	    	=>	o_cdgo_rspsta,
																 o_mnsje_rspsta			=>	o_mnsje_rspsta);

				if (o_cdgo_rspsta <> 0) then
					o_cdgo_rspsta   := 13;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || chr(13) ||
										sqlerrm || chr(13) ||
										o_mnsje_rspsta
										;
				end if;
			exception
				when others then
					o_cdgo_rspsta   := 14;
					o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;
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
					update	MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
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
					update	MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
					set		a.cdgo_estdo_rgstro	=	'S'
					where	a.id_intrmdia		=	c_item.id_intrmdia;
				end loop;
			end if;
		end loop;
	end prc_rg_dclrcnes_encbzdo;

	--Migracion de declaraciones con codigo:
	--004	FORMULARIO PRESENTACION 2007 A 2009 (004)
	procedure prc_rg_declaraciones_ICA7	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 o_ttal_extsos	    	out number,
										 o_ttal_error	    	out number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2) as

		--v_hmlgcion          			pkg_mg_migracion.r_hmlgcion;

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
		o_cdgo_rspsta := 0;
		o_ttal_extsos := 0;
    o_ttal_error := 0;

        --Carga los Datos de la Homologacion
       /* v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);*/

		--Se recorren las declaraciones iniciales
		open c_dclrcnes for	select  min(a.id_intrmdia) id_intrmdia,
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
						--	and     a.clmna8    		is  null
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
										a.clmna15,
										a.clmna21
							/*order by 1 fetch first 1 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
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
						pkg_mg_migracion_dcl2.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DECLARA_2
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DECLARA_2
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

					--Se valida si existe una declaracion de ese sujeto impuesto en esa vigencia formulario
					/*begin
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse si existe una declaracion de ese sujeto impuesto en esa vigencia formulario. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DECLARA
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;

							v_errors.extend;
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
							continue;
					end;*/

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
									update	MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
									set		a.clmna50			=	v_id_dclrcion,
											a.cdgo_estdo_rgstro	=	'E'
									where	a.id_intrmdia		=	c_item.id_intrmdia;

									commit;

									o_cdgo_rspsta   := 4;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo y ha sido marcada en la columna 50. ' || sqlerrm;

									update  migra.MG_G_INTERMEDIA_DECLARA_2
									set     clmna48		= o_cdgo_rspsta,
											clmna49		= o_mnsje_rspsta
									where   id_intrmdia = c_item.id_intrmdia;
									commit;

									v_errors.extend;
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_item.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								exception
									when others then
										o_cdgo_rspsta   := 5;
										o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;
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
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DECLARA_2
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
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
						--	and     a.clmna8    		is  null
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
										a.clmna15,
										a.clmna21
							/*order by 1 fetch first 10 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
				exit when v_table_dclrcnes.count = 0;
				for i in 1..v_table_dclrcnes.count loop

					begin
						pkg_mg_migracion_dcl2.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DECLARA_2
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DECLARA_2
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
						update	MIGRA.MG_G_INTERMEDIA_DECLARA_2   a
						set		a.cdgo_estdo_rgstro	=	case
															when o_cdgo_rspsta = 0 then 'S'
															else 'E'
														end,
								a.clmna48			=	o_cdgo_rspsta,
								a.clmna49			=	o_mnsje_rspsta
						where	a.id_intrmdia		=	c_item.id_intrmdia;
					end loop;

					commit;

				end loop;
			end loop;

		close c_dclrcnes;

		--Se actualiza el estado de los registros procesados en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA
        /*begin
            update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
            set     a.cdgo_estdo_rgstro =   'S'
            where   a.cdgo_clnte        =   p_cdgo_clnte
            and     id_entdad           =   p_id_entdad
			and     cdgo_estdo_rgstro   =   'L'
			and     a.clmna1    		in  ('4002', '5002');
        exception
            when others then
                o_cdgo_rspsta   := 9;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
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
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.MG_G_INTERMEDIA_DECLARA_2   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 11;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa


	end prc_rg_declaraciones_ICA7;

	--Especial para anticipos del impuesto de delineacion urbana
	procedure prc_rg_declaraciones_ICA8	(p_id_entdad			in  number,
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
		v_mg_g_intermedia_durb_declara  migra.mg_g_intermedia_durb_declara%rowtype;
		v_orden							number;

		v_cntdor_commit					number := 0;
	begin
		o_cdgo_rspsta := 0;
		o_ttal_extsos := 0;
        o_ttal_error := 0;

        --Carga los Datos de la Homologacion
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);

		--Se recorren las declaraciones iniciales
		open c_dclrcnes for	select  min(a.id_intrmdia) id_intrmdia,
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna27	clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1        	in	('ANT001')
							--and     a.clmna21       	=   'ANU'
							--and     a.clmna2			=   '2012'
							--and		a.clmna3    		=   '1'
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
										a.clmna15,
										a.clmna27
							/*order by 1 fetch first 1 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
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
						pkg_mg_migracion_dcl2.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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

					--Se valida si existe una declaracion de ese sujeto impuesto en esa vigencia formulario
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse si existe una declaracion de ese sujeto impuesto en esa vigencia formulario. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
									update	MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
									set		a.clmna50			=	v_id_dclrcion,
											a.cdgo_estdo_rgstro	=	'E'
									where	a.id_intrmdia		=	c_item.id_intrmdia;

									commit;

									o_cdgo_rspsta   := 4;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo y ha sido marcada en la columna 50. ' || sqlerrm;

									update  migra.MG_G_INTERMEDIA_DURB_DECLARA
									set     clmna48		= o_cdgo_rspsta,
											clmna49		= o_mnsje_rspsta
									where   id_intrmdia = c_item.id_intrmdia;
									commit;

									v_errors.extend;
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_item.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								exception
									when others then
										o_cdgo_rspsta   := 5;
										o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;
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
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna27	clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1        	in	('ANT001')
							--and     a.clmna21       	=   'ANU'
							--and     a.clmna2			=   '2012'
							--and		a.clmna3    		=   '1'
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
										a.clmna15,
										a.clmna27
							/*order by 1 fetch first 1 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
				exit when v_table_dclrcnes.count = 0;
				for i in 1..v_table_dclrcnes.count loop

					begin
						pkg_mg_migracion_dcl2.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;

							v_errors.extend;
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					end;

					--Se identifica la fila
					if (o_cdgo_rspsta = 0) then
						begin
							select  a.*
							into    v_mg_g_intermedia_durb_declara
							from    migra.mg_g_intermedia_durb_declara   a
							where   a.id_intrmdia   =   v_table_dclrcnes(i).id_intrmdia;
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 9;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--Maximo orden
					if (o_cdgo_rspsta = 0) then
						begin
							select	max(a.orden)
							into	v_orden
							from	gi_g_declaraciones_detalle	a
							where	a.id_dclrcion	=	v_id_dclrcion_crrccion;
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 10;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--Se registran item especiales de delineacion urbana
					--clmna22,    --Direccion de la obra
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		469,
																		1776,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna22,
																		v_mg_g_intermedia_durb_declara.clmna22
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 11;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--clmna23,    --Fecha final de la obra
					--clmna24,    --Matricula inmobiliaria
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		469,
																		1777,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna24,
																		v_mg_g_intermedia_durb_declara.clmna24
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 12;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;
					--clmna25,    --Licencia
					--clmna26,    --Objeto licencia
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		470,
																		1782,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna26,
																		v_mg_g_intermedia_durb_declara.clmna26
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 13;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;
					--clmna27,    --Fecha expedicion licencia
					--clmna28,    --Curaduria
					--clmna29,    --Referencia catastral

					--Se marcan las declaraciones con error o exito
					for c_item in	(
										select  a.id_intrmdia
										from    json_table  (v_table_dclrcnes(i).items, '$[*]' columns (
																					id_intrmdia number path '$.id_intrmdia'
																				)
															)   a
									)
					loop
						update	MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
						set		a.cdgo_estdo_rgstro	=	case
															when o_cdgo_rspsta = 0 then 'S'
															else 'E'
														end,
								a.clmna48			=	o_cdgo_rspsta,
								a.clmna49			=	o_mnsje_rspsta
						where	a.id_intrmdia		=	c_item.id_intrmdia;
					end loop;

					commit;

				end loop;
			end loop;

		close c_dclrcnes;

		--Se actualiza el estado de los registros procesados en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA
        /*begin
            update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
            set     a.cdgo_estdo_rgstro =   'S'
            where   a.cdgo_clnte        =   p_cdgo_clnte
            and     id_entdad           =   p_id_entdad
			and     cdgo_estdo_rgstro   =   'L'
			and     a.clmna1    		in  ('4002', '5002');
        exception
            when others then
                o_cdgo_rspsta   := 9;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
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
                o_cdgo_rspsta   := 14;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 15;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa


	end prc_rg_declaraciones_ICA8;

	--Especial para el impuesto de delineacion urbana
	procedure prc_rg_declaraciones_ICA9	(p_id_entdad			in  number,
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
		v_mg_g_intermedia_durb_declara  migra.mg_g_intermedia_durb_declara%rowtype;
		v_orden							number;

		v_cntdor_commit					number := 0;
	begin
		o_cdgo_rspsta := 0;
		o_ttal_extsos := 0;
        o_ttal_error := 0;

        --Carga los Datos de la Homologacion
        v_hmlgcion := pkg_mg_migracion.fnc_ge_homologacion(p_cdgo_clnte =>  p_cdgo_clnte,
                                                           p_id_entdad  =>  p_id_entdad);

		--Se recorren las declaraciones iniciales
		open c_dclrcnes for	select  min(a.id_intrmdia) id_intrmdia,
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna27	clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1        	in	('DEC001')
							--and     a.clmna21       	=   'ANU'
							--and     a.clmna2			=   '2012'
							--and		a.clmna3    		=   '1'
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
										a.clmna15,
										a.clmna27
							/*order by 1 fetch first 1 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
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
						pkg_mg_migracion_dcl2.prc_co_datos_migracion	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
							o_cdgo_rspsta   := 2;
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse los datos de la declaracion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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

					--Se valida si existe una declaracion de ese sujeto impuesto en esa vigencia formulario
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo validarse si existe una declaracion de ese sujeto impuesto en esa vigencia formulario. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
									update	MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
									set		a.clmna50			=	v_id_dclrcion,
											a.cdgo_estdo_rgstro	=	'E'
									where	a.id_intrmdia		=	c_item.id_intrmdia;

									commit;

									o_cdgo_rspsta   := 4;
									o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo y ha sido marcada en la columna 50. ' || sqlerrm;

									update  migra.MG_G_INTERMEDIA_DURB_DECLARA
									set     clmna48		= o_cdgo_rspsta,
											clmna49		= o_mnsje_rspsta
									where   id_intrmdia = c_item.id_intrmdia;
									commit;

									v_errors.extend;
									v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_item.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
								exception
									when others then
										o_cdgo_rspsta   := 5;
										o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;
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
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: Ya existe una declaracion para este perdiodo pero no ha podido identificarse. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
									a.clmna1,	--Codigo Declaracion
									a.clmna2,	--Vigencia
									a.clmna3,	--Codigo del periodo
									a.clmna4,	--Identificacion del declarante
									a.clmna5,	--Numero de declaracion
									a.clmna6,	--Codigo de estado de la declaracion
									a.clmna7,	--Codigo de uso de la declaracion
									a.clmna8,	--Numero de declaracion de correccion
									a.clmna9,	--Fecha de registro de la declaracion
									a.clmna10,	--Fecha de presentacion de la declaracion
									a.clmna11,	--Fecha proyectada de presentacion de la declaracion
									a.clmna12,	--Fecha de aplicacion de la declaracion
									a.clmna13,	--Base gravable de la declaracion
									a.clmna14,	--Valor total de la declaracion
									a.clmna15,	--Valor pago de la declaracion
									a.clmna27	clmna21,	--Periodicidad
									json_arrayagg(
													json_object(
																'id_intrmdia'   value   a.id_intrmdia,
																'clmna16'       value   a.clmna16,		--Reglon Declaracion
																'clmna17'       value   a.clmna17,		--Descripcion Renglon Declaracion
																'clmna18'       value   a.clmna18		--Valor Renglon Declaracion
																returning clob
															   )
													returning clob
												 ) as items
							from    MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
							where   a.cdgo_clnte		=   p_cdgo_clnte
							and     a.id_entdad 		=   p_id_entdad
							and     a.cdgo_estdo_rgstro =	'L'
							and     a.clmna1        	in	('DEC001')
							--and     a.clmna21       	=   'ANU'
							--and     a.clmna2			=   '2012'
							--and		a.clmna3    		=   '1'
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
										a.clmna15,
										a.clmna27
							/*order by 1 fetch first 1 rows only*/;

			loop fetch c_dclrcnes bulk collect into v_table_dclrcnes limit 400;
				exit when v_table_dclrcnes.count = 0;
				for i in 1..v_table_dclrcnes.count loop

					begin
						pkg_mg_migracion_dcl2.prc_rg_dclrcnes_encbzdo	(p_id_entdad			=>	p_id_entdad,
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion. ' || chr(13) ||
												o_mnsje_rspsta || chr(13) ||
												sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
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
							o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

							update  migra.MG_G_INTERMEDIA_DURB_DECLARA
							set     clmna48 = o_cdgo_rspsta,
									clmna49 = o_mnsje_rspsta
							where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
							commit;

							v_errors.extend;
							v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					end;

					--Se identifica la fila
					if (o_cdgo_rspsta = 0) then
						begin
							select  a.*
							into    v_mg_g_intermedia_durb_declara
							from    migra.mg_g_intermedia_durb_declara   a
							where   a.id_intrmdia   =   v_table_dclrcnes(i).id_intrmdia;
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 9;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--Maximo orden
					if (o_cdgo_rspsta = 0) then
						begin
							select	max(a.orden)
							into	v_orden
							from	gi_g_declaraciones_detalle	a
							where	a.id_dclrcion	=	v_id_dclrcion_crrccion;
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 10;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--Se registran item especiales de delineacion urbana
					--clmna19,    --Direccion de la obra
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		789,
																		3342,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna19,
																		v_mg_g_intermedia_durb_declara.clmna19
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 11;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--clmna20,    --Fecha final de la obra
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		789,
																		3393,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna20,
																		v_mg_g_intermedia_durb_declara.clmna20
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 12;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--clmna21,    --Matricula inmobiliaria
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		789,
																		3343,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna21,
																		v_mg_g_intermedia_durb_declara.clmna21
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 13;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--clmna22,    --Licencia
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		790,
																		3346,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna22,
																		v_mg_g_intermedia_durb_declara.clmna22
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 14;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;

					--clmna23,    --Objeto licencia
					if (o_cdgo_rspsta = 0) then
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
																		v_id_dclrcion_crrccion,
																		790,
																		3348,
																		1,
																		v_orden,
																		v_mg_g_intermedia_durb_declara.clmna23,
																		v_mg_g_intermedia_durb_declara.clmna23
																	);
						exception
							when others then
								rollback;
								o_cdgo_rspsta   := 15;
								o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo registrarse la declaracion de correccion. ' || sqlerrm;

								update  migra.MG_G_INTERMEDIA_DURB_DECLARA
								set     clmna48 = o_cdgo_rspsta,
										clmna49 = o_mnsje_rspsta
								where   id_intrmdia = v_table_dclrcnes(i).id_intrmdia;
								commit;

								v_errors.extend;
								v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_table_dclrcnes(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						end;
					end if;
					--clmna24,    --Fecha expedicion licencia
					--clmna25,    --Curaduria
					--clmna26,    --Referencia catastral

					--Se marcan las declaraciones con error o exito
					for c_item in	(
										select  a.id_intrmdia
										from    json_table  (v_table_dclrcnes(i).items, '$[*]' columns (
																					id_intrmdia number path '$.id_intrmdia'
																				)
															)   a
									)
					loop
						update	MIGRA.MG_G_INTERMEDIA_DURB_DECLARA   a
						set		a.cdgo_estdo_rgstro	=	case
															when o_cdgo_rspsta = 0 then 'S'
															else 'E'
														end,
								a.clmna48			=	o_cdgo_rspsta,
								a.clmna49			=	o_mnsje_rspsta
						where	a.id_intrmdia		=	c_item.id_intrmdia;
					end loop;

					commit;

				end loop;
			end loop;

		close c_dclrcnes;

		--Se actualiza el estado de los registros procesados en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA
        /*begin
            update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
            set     a.cdgo_estdo_rgstro =   'S'
            where   a.cdgo_clnte        =   p_cdgo_clnte
            and     id_entdad           =   p_id_entdad
			and     cdgo_estdo_rgstro   =   'L'
			and     a.clmna1    		in  ('4002', '5002');
        exception
            when others then
                o_cdgo_rspsta   := 9;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
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
                o_cdgo_rspsta   := 16;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        --Se actualizan en la tabla migra.MG_G_INTERMEDIA_DURB_DECLARA como error
        begin
            forall j in 1 .. o_ttal_error
            update  migra.MG_G_INTERMEDIA_DURB_DECLARA   a
            set     a.cdgo_estdo_rgstro =   'E'
            where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
        exception
            when others then
                o_cdgo_rspsta   := 17;
                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                --v_errors.extend;
                --v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_dclrcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                return;
        end;

        commit;
        --Se actualizan y recorren los errores
        --Respuesta Exitosa


	end prc_rg_declaraciones_ICA9;


	/*
		Vigencia formulario
		Registro encabezado
		Homologar Items
		Dejar lista UP de homologacion
		Registro detalle

		Tener en cuenta parametrizacion de actos conceptos para
		vigencias formularios, reportes de formularios y demas
		parametrizacion necesaria en declaraciones migradas.

	*/

    /*===================================================*/
	/*=====FIN MIGRACION DECLARACIONES ICA===============*/
	/*===================================================*/

end pkg_mg_migracion_dcl2;-- Fin del Paquete


/
