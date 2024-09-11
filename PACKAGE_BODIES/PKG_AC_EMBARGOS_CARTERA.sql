--------------------------------------------------------
--  DDL for Package Body PKG_AC_EMBARGOS_CARTERA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_AC_EMBARGOS_CARTERA" as 

procedure prc_ac_embrgos_crtra        ( p_cdgo_clnte        in	number
									   ,o_mnsje_rspsta	    out	varchar2
									   ,o_cdgo_rspsta       out number) as
                                    
v_vlor_mdda_ctlar		number;
vlor_mdda_ctlar_temp	number;
v_count					number;
begin 
o_cdgo_rspsta	:= 0;
v_count			:= 0;
	for c_ac_embrgos_crtra_dtlle in ( 	
										select 	 numero_resolucion           
												,referencia_catastral        
												,vigencia                    
												,periodo                     
												,valor_capital               
												,valor_interes               
												,id_embrgos_crtra
												,cdgo_estdo_rgstro
										from    temp_embargos_cartera a
										where   id_embrgos_crtra is not null
                                        and     cdgo_estdo_rgstro is null)
	loop
	/* se selecciona el valor de la medida cautelar en la tabla de gestion referente a ese id_embrgos_crtra */
		begin
			select vlor_mdda_ctlar
			into   v_vlor_mdda_ctlar
			from   mc_g_embargos_cartera 
			where  cdgo_clnte 				= p_cdgo_clnte
			and    id_embrgos_crtra 		= c_ac_embrgos_crtra_dtlle.id_embrgos_crtra; 

		exception
			when no_data_found then 
				o_cdgo_rspsta   := 10;
				o_mnsje_rspsta  := o_cdgo_rspsta || ' No se encontro el valor de medida cautelar referente al id_embrgos_crtra: ' ||c_ac_embrgos_crtra_dtlle.id_embrgos_crtra;
			--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
			when others then 
				o_cdgo_rspsta   := 20;
				o_mnsje_rspsta  := o_cdgo_rspsta || ' Error al consultar el valor de medida cautelar ' || sqlerrm;
			--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
		end;-- se selecciona el valor de la medida cautelar en la tabla de gestion referente a ese id_embrgos_crtra

	/* se selecciona el valor de la medida cautelar en la tabla de gestion referente a ese id_embrgos_crtra */	
		begin
			select  (sum(a.valor_capital)*2) + sum(a.valor_interes) 
			into    vlor_mdda_ctlar_temp
			from 	temp_embargos_cartera a
			where 	id_embrgos_crtra =  c_ac_embrgos_crtra_dtlle.id_embrgos_crtra; 

		exception
			when no_data_found then 
				o_cdgo_rspsta   := 30;
				o_mnsje_rspsta  := o_cdgo_rspsta || ' No se encontro el valor de medida cautelar en la tabla temporal ';
			--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
			when others then 
				o_cdgo_rspsta   := 40;
				o_mnsje_rspsta  := o_cdgo_rspsta || ' Error al consultar el valor de medida cautelar en la tabla temporal' || sqlerrm;
			--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
				return;
		end;
		/* se comparan los valores de la medida cuatelar de la tabla temporal con la tabla temp_embargos_cartera */
		if (vlor_mdda_ctlar_temp <> v_vlor_mdda_ctlar) then
			/*  si los valores de la medida cautelar difieren , se actualiza este valor en la tabla mc_g_embargos_cartera*/
			begin
				update  mc_g_embargos_cartera
				set 	vlor_mdda_ctlar  = vlor_mdda_ctlar_temp
				where 	id_embrgos_crtra = c_ac_embrgos_crtra_dtlle.id_embrgos_crtra; 
			exception
				when others then 
					o_cdgo_rspsta   := 50;
					o_mnsje_rspsta  := o_cdgo_rspsta || ' Error al actualizar  el valor de medida cautelar en la tabla mc_g_embargos_cartera id_embrgos_crtra: '||c_ac_embrgos_crtra_dtlle.id_embrgos_crtra||' - ' || sqlerrm;
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					return;	
			end;
			/* se marca el registro en la tabla temporal como 'M' para entender que este registro modifico la tabla de gestion mc_g_embargos_cartera
				en el presente  id_embrgos_crtra y luego poder identificarlo.	
			*/
			begin
				update  temp_embargos_cartera
				set 	cdgo_estdo_rgstro  = 'M'
				where 	id_embrgos_crtra = c_ac_embrgos_crtra_dtlle.id_embrgos_crtra; 
			exception
				when others then 
					o_cdgo_rspsta   := 60;
					o_mnsje_rspsta  := o_cdgo_rspsta || ' Error al actualizar  el valor de medida cautelar en la tabla mc_g_embargos_cartera' || sqlerrm;
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					return;	
			end;

		end if;
		if o_cdgo_rspsta = 0 then 
			v_count := v_count + 1;
			/* se Marca el registro en la tabla temporal como 'E' para entender que ya se proceso aunque no hizo ninguna modificacion 
				en la tabla  mc_g_embargos_cartera
			*/
			begin
				update  temp_embargos_cartera
				set 	cdgo_estdo_rgstro  = 'E'
				where 	id_embrgos_crtra = c_ac_embrgos_crtra_dtlle.id_embrgos_crtra
				and 	cdgo_estdo_rgstro is null; 
			exception
				when others then 
					o_cdgo_rspsta   := 60;
					o_mnsje_rspsta  := o_cdgo_rspsta || ' Error al actualizar  el valor de medida cautelar en la tabla mc_g_embargos_cartera' || sqlerrm;
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
					return;	
			end;
		end if;
		if v_count = 1000 then 
			commit;
			v_count := 0 ;
		end if;

	end loop;
end;	
end pkg_ac_embargos_cartera;

/
