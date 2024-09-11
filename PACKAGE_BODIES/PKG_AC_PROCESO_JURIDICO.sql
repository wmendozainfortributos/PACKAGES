--------------------------------------------------------
--  DDL for Package Body PKG_AC_PROCESO_JURIDICO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_AC_PROCESO_JURIDICO" as

/*********************Body  Reconstruccion de procesos juridicos basados en Archivo excel enviado por la Administracion de Valledupar **************************/
procedure prc_ac_proceso_juridico (	p_cdgo_clnte 				number,
									p_id_usrio					number,
									o_mnsje_rspsta              out varchar2,
									o_cdgo_rspsta				out number) as

v_nl                    	number;
v_nmbre_up              	varchar2(70) := 'pkg_ac_proceso_juridico.prc_ac_proceso_juridico';
v_id_fncnrio				number;
v_cnsctvo_lte_pj			number;
v_id_prcso_jrdco_lte_pj     number;
v_id_fljo					number;	
v_id_instncia_fljo			number;	
v_id_fljo_trea				number;
v_cdgo_prcso_jrdco_estdo 	varchar2(10);
v_id_prcso_jrdco			number;
v_id_embrgos_crtra			number;	
v_id_embrgos_rslcion        number;	
v_count_commit				number;

begin
v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
o_cdgo_rspsta   := 0;
v_count_commit	:= 0;
--o_mnsje_rspsta := 'Actualizacion Completa';	
/*	begin
		select id_fncnrio
		  into v_id_fncnrio
		  from v_sg_g_usuarios 
		 where id_usrio = p_id_usrio; -- id_usuario = 1 que es el de sistema.
    exception   
		when no_data_found then
			o_cdgo_rspsta  := 10;
			o_mnsje_rspsta := o_cdgo_rspsta || '. .';
			return;       
    end;*/
	begin

		v_cnsctvo_lte_pj := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LPJ');

		insert into cb_g_procesos_juridico_lote (cdgo_clnte     ,cnsctvo_lte        ,fcha_lte       ,obsrvcion_lte                          ,tpo_lte,id_fncnrio)
										 values (p_cdgo_clnte   ,v_cnsctvo_lte_pj   ,trunc(sysdate) ,'Lote de proceso juridico de fecha ' ||to_char(trunc(sysdate),'dd/mm/yyyy')  ,'LPJ'  ,p_id_usrio)
		returning id_prcso_jrdco_lte into v_id_prcso_jrdco_lte_pj;
   --     pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'generacion del lote '|| v_id_prcso_jrdco_lte_pj, 1);
	--	commit;
	exception 
		when others then
			o_cdgo_rspsta  := 20;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problema al general el lote del Proceso Juridico '||sqlerrm;
			rollback;
			return;       
    end;
	begin
 		select id_fljo
		  into v_id_fljo
		  from wf_d_flujos 
		 where cdgo_fljo = 'CBM'
		   and cdgo_clnte = p_cdgo_clnte;
  --  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'calculo el id_fljo '|| v_id_fljo, 1);
	exception 
		when no_data_found then
			o_cdgo_rspsta  := 30;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al consultar el identificador del Flujo de cobro juridico';
			rollback;
			return;
	end;
	begin
  --  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'entrando al begin del for ', 1);
		for c_cnstrccion_prcso_jrdco in ( 
										select numeroresolucion,
											   numeroexpediente,
											   numeroexpedienteexterno,
											   fecharesolucion,
											   desembargoresolucion 
										from   temp_embargos 
										where  numeroresolucion  in (select nmro_acto from  mc_g_embargos_resolucion)
										and   to_char(numeroexpediente) not in (select nmro_prcso_jrdco from  cb_g_procesos_juridico)
										and   to_char(numeroexpedienteexterno) not in (select nmro_prcso_jrdco from  cb_g_procesos_juridico)
										--and numeroexpediente = 
                                        and	  indcdor_prcsdo is null
                                       -- and   ROWNUM  < 1001
										)loop

			begin
             pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'entrando al for '||v_count_commit, 1); 
				/*pkg_pl_workflow_1_0.prc_rg_instancias_flujo( p_id_fljo          => v_id_fljo
														   , p_id_usrio         => p_id_usrio
														   , p_id_prtcpte       => p_id_usrio
														   , o_id_instncia_fljo => v_id_instncia_fljo 
														   , o_id_fljo_trea     => v_id_fljo_trea
														   , o_mnsje            => o_mnsje_rspsta);*/
                insert into wf_g_instancias_flujo (	 id_fljo  
                                                    ,fcha_incio	
                                                    ,fcha_fin_plnda 
                                                    ,fcha_fin_optma	
                                                    ,id_usrio	
                                                    ,estdo_instncia 
                                                    ,obsrvcion) 
                                            values (v_id_fljo       
                                                    ,sysdate   		 
                                                    ,sysdate         
                                                    ,sysdate        
                                                    ,p_id_usrio		 
                                                    ,'INICIADA'		
                                                    ,'Flujo Cobro-Proceso Jurídico Manual reconstruccion, basado en Archivo Excel'	 )
											returning id_instncia_fljo into v_id_instncia_fljo;     			                                           
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'generacion de la instancia del flujo '|| v_id_instncia_fljo, 1);                                           
			exception 
				when others then
					o_cdgo_rspsta  := 40;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al generar la instancia del flujo de Proceso Juridico' ||o_mnsje_rspsta;
					 pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'problemas generacion de la instancia del flujo '||o_mnsje_rspsta , 1); 
                    rollback;
					return;
			end;
			/* este begin se hizo con el fin de controlar que dos o mas resoluciones de embargo estan asociadas 
			   a un mismo proceso juridico */
			begin
				select id_prcsos_jrdco
				into   v_id_prcso_jrdco
				from   cb_g_procesos_juridico
				where  to_char(nmro_prcso_jrdco) = c_cnstrccion_prcso_jrdco.numeroexpediente;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'condicion si ya en una interacion anterior del for se genero e proceso juridico '|| v_id_prcso_jrdco, 1);
			exception 
				when no_data_found then
					v_id_prcso_jrdco:= null;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'aun no se ha generado el proceso juridico en la iteraccion actual del for ', 1);
					--continue; 
			end;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'antes de entrar al if que genera el proceso juridico '|| v_id_prcso_jrdco, 1);
			if v_id_prcso_jrdco is null then 
				begin
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'entrando al if que genera el proceso juridico ', 1);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'mostrando la fecha '||c_cnstrccion_prcso_jrdco.fecharesolucion, 1);
                  
					insert into cb_g_procesos_juridico( cdgo_clnte   
													  ,	nmro_prcso_jrdco 
													  ,	fcha
													  , vlor_ttal_dda
													  , id_instncia_fljo  
													  , cdgo_prcsos_jrdco_estdo  
													  , id_fncnrio   
													  , msvo  
													  , id_prcso_jrdco_lte
													  , tpo_plntlla  
													  , etpa_actual_mgra  )
												values( p_cdgo_clnte 
													  ,(nvl2(c_cnstrccion_prcso_jrdco.numeroexpediente,c_cnstrccion_prcso_jrdco.numeroexpediente,c_cnstrccion_prcso_jrdco.numeroexpedienteexterno))  
													  --, c_cnstrccion_prcso_jrdco.fecharesolucion 
                                                      --,to_char(c_cnstrccion_prcso_jrdco.fecharesolucion,'DD/MM/YYYY')
                                                      --,to_timestamp('11/02/13 12:00:00,000000000 AM', 'DD/MM/RR HH12:MI:SSXFF AM'),
													  ,to_char(to_date(substr(c_cnstrccion_prcso_jrdco.fecharesolucion,0,10),'yyyy/mm/dd'),'dd/mm/yyyy')
                                                      , 0           
													  , v_id_instncia_fljo
													  , 'R' -- R = RECONSTRUIDO
													  , p_id_usrio 
													  , 'S'
													  , v_id_prcso_jrdco_lte_pj
													  , null         
													  , '10')-- 10-para marcarlos que son los del excel. -no se  tiene etapa actual )
											 returning id_prcsos_jrdco 
												  into v_id_prcso_jrdco; 
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'Se genera el proceso juridico '|| v_id_prcso_jrdco, 1);
				exception 
					when others then
						o_cdgo_rspsta  := 50;
						o_mnsje_rspsta := o_cdgo_rspsta || ' problema al generar el proceso juridico '|| sqlerrm;
						rollback;
						return; 
				end;
			end if;
			/*  Ya tenemos el v_id_prcso_jrdco para poder realcionarlo en la tabla mc_g_embrgos_crt_prc_jrd
			  - ahora necesitamos buscar el id_cartera que estan relacionados con ese proceso, eso 
			  -lo hacemos por medio de la temporral buscando la resolucion de embargo. */

			begin
				select  id_embrgos_crtra
					   ,id_embrgos_rslcion						   
				into    v_id_embrgos_crtra
					   ,v_id_embrgos_rslcion
				from   mc_g_embargos_resolucion 
				where nmro_acto = c_cnstrccion_prcso_jrdco.numeroresolucion;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'select de mc_g_embargos_resolucion'||v_id_embrgos_crtra, 1); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,' numeroresolucion; '||c_cnstrccion_prcso_jrdco.numeroresolucion, 1); 
			exception 
                when no_data_found then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := o_cdgo_rspsta || 'problemas a encontrar la cartera '|| c_cnstrccion_prcso_jrdco.numeroresolucion;
                rollback;
                return;            
            when others then
				o_cdgo_rspsta  := 65;
				o_mnsje_rspsta := o_cdgo_rspsta || 'problemas a encontrar la cartera '|| c_cnstrccion_prcso_jrdco.numeroresolucion;
				rollback;
				return; 
			end;				
			 /* hacemos el insert para asociar el id_cartera con el id_proceso_juridico */

			begin
				insert into  mc_g_embrgos_crt_prc_jrd ( id_embrgos_crtra
													   ,id_prcsos_jrdco)
												values( v_id_embrgos_crtra
													   ,v_id_prcso_jrdco);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl,'Se genera el la relacion entre el proceso juridico y el embargo ', 1);
			exception 
				when others then
					o_cdgo_rspsta  := 70;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al generar la relacion proceso juridico con resolucion de embargo '|| sqlerrm;
					rollback;
					return; 
			end;
			begin
				update   temp_embargos
				set 	 indcdor_prcsdo	= 'S'
				where    numeroexpediente = c_cnstrccion_prcso_jrdco.numeroexpediente
				or       numeroexpedienteexterno = c_cnstrccion_prcso_jrdco.numeroexpedienteexterno;
                
			exception 
				when others then
					o_cdgo_rspsta  := 80;
					o_mnsje_rspsta := o_cdgo_rspsta || 'problemas al actualizar el indicador de registro a procesado en la tabla temporal '|| sqlerrm ;
					rollback;
					return; 
			end;
			v_count_commit := v_count_commit + 1;

			if v_count_commit = 1000 then
				commit;
				v_count_commit:= 0;
			end if;
		end loop;
	end;
	--o_mnsje_rspsta := 'Actualizacion Completa';	
end;	

/*****************************************************************************************/


procedure prc_ac_oficio_resolucion_embargo (p_cdgo_clnte 				number,
											p_id_usrio					number,
											o_mnsje_rspsta              out varchar2,
											o_cdgo_rspsta				out number) as

v_nl                    	number;
v_nmbre_up              	varchar2(70) := 'pkg_ac_proceso_juridico.prc_ac_oficio_resolucion_embargo';
v_id_lte_mdda_ctlar			number;
v_count_lotes				number;	
v_count_commit				number;

begin
v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
o_cdgo_rspsta   := 0;
v_count_commit	:= 0;
v_count_lotes   := 0;
/* Generar los lotes para asociar los consecutivos de oficios a bancos que existen en el archivo excel, para luego relacionarlos con sus embargos */	
/*	for c_gen_lote_mc in (
							select  distinct(numerooficio) numerooficio
							from temp_embargos
							where numerooficio not in (select to_char(nmro_cnsctvo) from mc_g_lotes_mdda_ctlar)
							and numerooficio <> 'NULL'
							) loop
		begin
		v_count_lotes	:= v_count_lotes + 1;
		--	v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');

			insert into mc_g_lotes_mdda_ctlar( 	 cdgo_clnte
												,nmro_cnsctvo
												,fcha_lte
                                                ,tpo_lte
												,id_fncnrio
												,obsrvcion_lte)
									   values( 	 p_cdgo_clnte
												,c_gen_lote_mc.numerooficio
												,sysdate
												,'E'
												,p_id_usrio
											    ,'Lote creado a partir de archivo Excel administracion');
									-- returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creacion de Lotes iteracion no:  ' || v_count_lotes, 1);	
		exception 
			when others then
				o_cdgo_rspsta  := 10;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problema al general el lote del Medida Cautelar '||sqlerrm;
				rollback;
				return;       
		end;	
	end loop;
-- Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2017 
	begin
		insert into mc_g_lotes_mdda_ctlar( 	 cdgo_clnte
											,nmro_cnsctvo
											,fcha_lte
                                            ,tpo_lte
											,id_fncnrio
											,obsrvcion_lte)
								   values( 	 p_cdgo_clnte
											,1765
											,sysdate
											,'E'
											,p_id_usrio
											,'Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2017');
									 --returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creacion de Lotes con consecutivo: 1765' , 1);		
	exception 
		when others then
			o_cdgo_rspsta  := 20;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problema al general el lote del Medida Cautelar '||sqlerrm;
			rollback;
			return;       
	end;
-- Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2016 --
	begin
		insert into mc_g_lotes_mdda_ctlar( 	 cdgo_clnte
											,nmro_cnsctvo
											,fcha_lte
                                            ,tpo_lte
											,id_fncnrio
											,obsrvcion_lte)
								   values( 	 p_cdgo_clnte
											,2016190120161781
											,sysdate
											,'E'
											,p_id_usrio
											,'Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2016');
									 --returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creacion de Lotes con consecutivo: 2016190120161781' , 1);		
	exception 
		when others then
			o_cdgo_rspsta  := 30;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problema al general el lote del Medida Cautelar '||sqlerrm;
			rollback;
			return;       
	end;
-- Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2015 --
	begin
		insert into mc_g_lotes_mdda_ctlar( 	 cdgo_clnte
											,nmro_cnsctvo
											,fcha_lte
											,tpo_lte
											,id_fncnrio
											,obsrvcion_lte)
								   values( 	 p_cdgo_clnte
											,25083338 
											,sysdate
											,'E'
											,p_id_usrio
											,'Lote creado a partir de archivo Excel administracion considerando los embargos que teiene la referencia a oficio nula de la vigencia 2015');
									 --returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creacion de Lotes con consecutivo: 25083338' , 1);	
	exception 
		when others then
			o_cdgo_rspsta  := 40;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problema al general el lote del Medida Cautelar '||sqlerrm;
			rollback;
			return;       
	end;
 --   commit;
*/	for c_ac_id_lte_mdda_ctlr in ( 
									select  numeroresolucion
										   ,numeroexpediente
										   ,numeroexpedienteexterno
										   ,fecharesolucion
										   ,numerooficio
									from    temp_embargos 
									where   numeroresolucion  in (select nmro_acto from  mc_g_embargos_resolucion)
									and     indcdor_ofcio_prcsdo is null
								 -- and   ROWNUM  < 1001
									)loop
	-- condiciones para actualizar los id lotes de las resoluciones de embargo
	if (trim(c_ac_id_lte_mdda_ctlr.numerooficio) <> 'NULL') /*or (c_ac_id_lte_mdda_ctlr.numerooficio is not null)*/ then
		begin
			select id_lte_mdda_ctlar
			into   v_id_lte_mdda_ctlar
			from   mc_g_lotes_mdda_ctlar
			where  to_char(nmro_cnsctvo) = c_ac_id_lte_mdda_ctlr.numerooficio;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'seleccionando el id_lte_mdda_ctlar cuando el numero de oficio no es nulo  '||v_id_lte_mdda_ctlar , 1);	
		exception 
			when no_data_found then
				o_cdgo_rspsta  := 50;
				o_mnsje_rspsta := o_cdgo_rspsta || 'No se encontraron datos del id_lte_mdda_ctlar de medida cautelar numerooficio '||c_ac_id_lte_mdda_ctlr.numerooficio||' - '||sqlerrm;
				rollback;
				return;      
			when others then
				o_cdgo_rspsta  := 60;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al consultar el id_lte_mdda_ctlar de medida cautelar numerooficio '||c_ac_id_lte_mdda_ctlr.numerooficio||' - '||sqlerrm;
				rollback;
				return;      
		end;
		/* despues de obtener el id del lote se debe actualizar en la tabla de resolucion de embargo el id_lte_mdda_ctlar */
		begin
			update mc_g_embargos_resolucion
			set    id_lte_mdda_ctlar = 	v_id_lte_mdda_ctlar
			where  nmro_acto = c_ac_id_lte_mdda_ctlr.numeroresolucion;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'actualizando el id_lte_mdda_ctlar en mc_g_embargos_resolucion '||v_id_lte_mdda_ctlar , 1);
		exception 
			when others then
				o_cdgo_rspsta  := 70;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas actualizando el id_lte_mdda_ctlar en mc_g_embargos_resolucion '||sqlerrm;
				rollback;
				return;      
		end;
	end if; /*fin condicional if (c_ac_id_lte_mdda_ctlr.numerooficio <> 'NULL') or (c_ac_id_lte_mdda_ctlr.numerooficio is not null) */
	if (trim(c_ac_id_lte_mdda_ctlr.numerooficio) = 'NULL') /*or (c_ac_id_lte_mdda_ctlr.numerooficio is null)*/ then 
		
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'condicional cuando el numero de oficio es nulo  '||v_id_lte_mdda_ctlar , 1);	
		
		if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2017' then
			begin
				select id_lte_mdda_ctlar
				into   v_id_lte_mdda_ctlar
				from   mc_g_lotes_mdda_ctlar
				where  nmro_cnsctvo = 1765;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 1765 '||v_id_lte_mdda_ctlar , 1);
			exception 
				when no_data_found then
					o_cdgo_rspsta  := 80;
					o_mnsje_rspsta := o_cdgo_rspsta || 'no se encontraron datos seleccionando  el id_lte_mdda_ctlar cuando nmro_cnsctvo = 1765 '||sqlerrm;
					rollback;
					return;      
				when others then
					o_cdgo_rspsta  := 90;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 1765 '||sqlerrm;
					rollback;
					return;      
			end;
			begin
				update mc_g_embargos_resolucion
				set    id_lte_mdda_ctlar = 	v_id_lte_mdda_ctlar
				where  nmro_acto         = c_ac_id_lte_mdda_ctlr.numeroresolucion;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'actualizando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 1765 en mc_g_embargos_resolucion '||v_id_lte_mdda_ctlar , 1);
			exception 
				when others then
					o_cdgo_rspsta  := 100;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas actualizando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 1765 en mc_g_embargos_resolucion  '||sqlerrm;
					rollback;
					return;      
			end;
		end if; /* fin del condicional if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2017' */
		if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2016' then
			begin
				select id_lte_mdda_ctlar
				into   v_id_lte_mdda_ctlar
				from   mc_g_lotes_mdda_ctlar
				where  nmro_cnsctvo = 2016190120161781;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 2016190120161781 '||v_id_lte_mdda_ctlar , 1);
			exception 
				when no_data_found then
					o_cdgo_rspsta  := 110;
					o_mnsje_rspsta := o_cdgo_rspsta || 'no se encontraron datos seleccionando  el id_lte_mdda_ctlar cuando nmro_cnsctvo = 2016190120161781  '||sqlerrm;
					rollback;
					return;      
				when others then
					o_cdgo_rspsta  := 120;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 2016190120161781 '||sqlerrm;
					rollback;
					return;      
			end;
			begin
				update mc_g_embargos_resolucion
				set    id_lte_mdda_ctlar = 	v_id_lte_mdda_ctlar
				where  nmro_acto         = c_ac_id_lte_mdda_ctlr.numeroresolucion;
			exception 
				when others then
					o_cdgo_rspsta  := 130;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas actualizando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 2016190120161781 en mc_g_embargos_resolucion  '||sqlerrm;
					rollback;
					return;      
			end;
		end if; /* fin del condicional if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2016' */
		if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2015' then
			begin
				select id_lte_mdda_ctlar
				into   v_id_lte_mdda_ctlar
				from   mc_g_lotes_mdda_ctlar
				where  nmro_cnsctvo = 25083338;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 25083338 '||v_id_lte_mdda_ctlar , 1);
			exception 
				when no_data_found then
					o_cdgo_rspsta  := 140;
					o_mnsje_rspsta := o_cdgo_rspsta || 'no se encontraron datos seleccionando  el id_lte_mdda_ctlar cuando nmro_cnsctvo = 25083338  '||sqlerrm;
					rollback;
					return;      
				when others then
					o_cdgo_rspsta  := 150;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas seleccionando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 25083338 '||sqlerrm;
					rollback;
					return;      
			end;
			begin
				update mc_g_embargos_resolucion
				set    id_lte_mdda_ctlar = 	v_id_lte_mdda_ctlar
				where  nmro_acto         = c_ac_id_lte_mdda_ctlr.numeroresolucion;
			exception 
				when others then
					o_cdgo_rspsta  := 160;
					o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas actualizando el id_lte_mdda_ctlar cuando nmro_cnsctvo = 25083338 en mc_g_embargos_resolucion  '||sqlerrm;
					rollback;
					return;      
			end;
		end if;/* fin del condicional if substr(c_ac_id_lte_mdda_ctlr.numeroresolucion,0,4) = '2015' */
		
	end if; /*  fin condicional if c_ac_id_lte_mdda_ctlr.numerooficio = 'NULL') or (c_ac_id_lte_mdda_ctlr.numerooficio is null) */
	begin
		update   temp_embargos
		set 	 indcdor_ofcio_prcsdo	= 'S'
		where    numeroresolucion = c_ac_id_lte_mdda_ctlr.numeroresolucion;
	exception 
		when others then
			o_cdgo_rspsta  := 170;
			o_mnsje_rspsta := o_cdgo_rspsta || 'problemas al actualizar el indicador de registro a procesado en la tabla temporal '|| sqlerrm ;
			rollback;
			return; 
	end;
    v_count_commit := v_count_commit + 1;
	if v_count_commit > 100 then
		commit;
		v_count_commit := 0;
	end if;
	end loop;
end;	

/**************************************************************************************************************************/

procedure prc_ac_oficio_dsmbrgo_msvo_bnco ( p_cdgo_clnte 				number,
											p_id_lte_mdda_ctlar         number,
											o_mnsje_rspsta              out varchar2,
											o_cdgo_rspsta				out number) as
											
/*Bloque para actualizar oficio a bancos con identificacion*/
	v_cnsctivo_lte 		number;
	v_id_lte_mdda_ctlar number;
	v_id_fncnrio        number;
	v_nl                number;
	v_nmbre_up          varchar2(70) := 'pkg_ac_proceso_juridico.prc_ac_oficio_dsmbrgo_msvo_bnco';
	v_count_commit		number;
	
begin

	v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
	o_cdgo_rspsta   := 0;
	v_count_commit	:= 0;

	/*Select para sacar el id del funcionario*/
	begin
		select  a.id_fncnrio
		into 	v_id_fncnrio
		from    mc_g_lotes_mdda_ctlar a
		where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar;
		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'seleccionando el id_fncnrio '||v_id_fncnrio , 1);	
	exception
		when no_data_found then
			o_cdgo_rspsta  := 10;
			o_mnsje_rspsta := o_cdgo_rspsta || 'No se encontraron del id del funcionario'||v_id_fncnrio||' - '||sqlerrm;
			rollback;
			return;      
		when others then
			o_cdgo_rspsta  := 20;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al consultar el id del funcionario '||v_id_fncnrio||' - '||sqlerrm;
			rollback;
			return;
	end;
	
	for c_actlzcion_ofcio_bnco  in ( select  distinct(a.idntfccion),
											 trunc(a.fcha_acto) fecha 
									 from    v_mc_g_desembargos_resolucion a
									 where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar
                                     --and rownum  < 11
                                     ) 	
	loop
	v_count_commit := v_count_commit + 1;
	

--	 1. Crear el consecutivo del lote

	 v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');

--	 2.Creamos los lotes por identificaicon del sujeto,

	begin
		Insert into mc_g_lotes_mdda_ctlar (nmro_cnsctvo,
										   fcha_lte,
										   tpo_lte,
										   id_fncnrio,
										   cdgo_clnte,
										   obsrvcion_lte,
										   cntdad_dsmbrgo_lote,
										   dsmbrgo_tpo,
										   json,
										   nmro_rgstro_prcsar,
										   cdgo_estdo_lte) 
									values ( v_cnsctivo_lte,
											 c_actlzcion_ofcio_bnco.fecha,
											'D',
											v_id_fncnrio,
											p_cdgo_clnte,
											'ofico a banco desembargo de masivo fecha ' ||c_actlzcion_ofcio_bnco.fecha ,
											null,
											null, 
											null,
											null,
											'TRM')
											returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
				
	exception
		when others then
			o_cdgo_rspsta  := 30;
			o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al insertar en la tabla mc_g_lotes_mdda_ctlar '||' - '||sqlerrm;
			rollback;
			return; 
	end; 

--	3.Actualizar en la tabla resolucion de desembargo con el nuevo lote a esas resoluciones 

		for c_resolucion_dsmbargo in (select  a.id_dsmbrgos_rslcion
                                      from    v_mc_g_desembargos_resolucion a
								      where  a.idntfccion = c_actlzcion_ofcio_bnco.idntfccion)
		loop
			begin
				update mc_g_desembargos_resolucion
				set   id_lte_mdda_ctlar   = v_id_lte_mdda_ctlar
				where id_dsmbrgos_rslcion = c_resolucion_dsmbargo.id_dsmbrgos_rslcion
				and   id_lte_mdda_ctlar   = p_id_lte_mdda_ctlar;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'actualizando el id_lte_mdda_ctlar en mc_g_dembargos_resolucion '||v_id_lte_mdda_ctlar , 1);
			exception
				when others then
				o_cdgo_rspsta  := 40;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas actualizando el id_lte_mdda_ctlar  en mc_g_dembargos_resolucion  '||sqlerrm;
				rollback;
				return;
			end;
		end loop;		
		
/*	
--	4. Se borra los actos de vigencias
	
        begin
			delete
			from gn_g_actos_vigencia
			where id_acto in ( select distinct(id_acto)
								from mc_g_desembargos_oficio
								where id_dsmbrgos_rslcion in (select  distinct(a.id_dsmbrgos_rslcion) 
															  from    v_mc_g_desembargos_resolucion a
															  where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar));
		exception
			when others then
				o_cdgo_rspsta  := 50;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al eliminar  id_acto  en gn_g_actos_vigencia  '||sqlerrm;
				rollback;
				return;
        end;
	
	
--	5. borramos actos responsables
		
		begin
			delete
			from gn_g_actos_responsable
			where id_acto in ( select distinct(id_acto)
								 from mc_g_desembargos_oficio
								 where id_dsmbrgos_rslcion in (select  distinct(a.id_dsmbrgos_rslcion) 
															  from    v_mc_g_desembargos_resolucion a
															  where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar));
		exception
			when others then
				o_cdgo_rspsta  := 60;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al eliminar  id_acto  en gn_g_actos_responsable  '||sqlerrm;
				rollback;
				return;
		end;

--	6. se borra los actos de sujetos impuestos

		begin
			delete 
			from gn_g_actos_sujeto_impuesto
			where id_acto in ( select distinct(id_acto)
								 from mc_g_desembargos_oficio
								 where id_dsmbrgos_rslcion in (select  distinct(a.id_dsmbrgos_rslcion) 
															  from    v_mc_g_desembargos_resolucion a
															  where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar));
		exception
			when others then
				o_cdgo_rspsta  := 70;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al eliminar  id_acto  en gn_g_actos_sujeto_impuesto  '||sqlerrm;
				rollback;
				return;
		end;
		

--	7. se inserta en la tabla actos eliminar los id_actos de desembargo oficios

		
		begin
			
			insert into gn_g_actos_eliminar 
				select distinct(id_acto)
				from mc_g_desembargos_oficio
				where id_dsmbrgos_rslcion in (select  distinct(a.id_dsmbrgos_rslcion) 
											  from    v_mc_g_desembargos_resolucion a
											  where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar);
		exception
			when others then
				o_cdgo_rspsta  := 80;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al insertar  el id_acto  en gn_g_actos_eliminar  '||sqlerrm;
				rollback;
				return;
		end; 

--	8. Borrar los desembargos oficios del id lote del medida cautelar 262

    
		begin
			delete 
			from mc_g_desembargos_oficio 
			where id_dsmbrgos_rslcion in (select  distinct(a.id_dsmbrgos_rslcion) 
										  from    v_mc_g_desembargos_resolucion a
										  where   a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar);
		exception
			when others then
				o_cdgo_rspsta  := 90;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al eliminar el id_acto  en mc_g_desembargos_oficio  '||sqlerrm;
				rollback;
				return;
		end;	
	

--	9. Borrar los actos del lote del medida cautelar 262

		begin
			delete 
			from gn_g_actos 
			where id_acto in ( select distinct(id_acto)
							   from gn_g_actos_eliminar);
		exception
			when others then
				o_cdgo_rspsta  := 100;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas al eliminar el id_acto  en gn_g_actos  '||sqlerrm;
				rollback;
				return;
		end;
	
	
*/
--	10.Crear los actos de cada lote y creacion del cada blob

    
		begin
			pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo(    p_cdgo_clnte        => p_cdgo_clnte
																	  , p_id_usuario        => v_id_fncnrio
																	  , p_id_lte_mdda_ctlar => v_id_lte_mdda_ctlar
																	  , o_cdgo_rspsta		=> o_cdgo_rspsta
																	  , o_mnsje_rspsta		=> o_mnsje_rspsta);
		exception
			when others then
				o_cdgo_rspsta  := 110;
				o_mnsje_rspsta := o_cdgo_rspsta || 'Problemas en la creacion de actos y blog '||sqlerrm;
				rollback;
				return;
		end;
        
		if(v_count_commit = 100) then
			commit;
			v_count_commit := 0;
		end if;
	end loop;
end  prc_ac_oficio_dsmbrgo_msvo_bnco ;

/********************************************************************************************************************************/
	
end pkg_ac_proceso_juridico;

/
