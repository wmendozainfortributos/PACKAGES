--------------------------------------------------------
--  DDL for Package Body PKG_TI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_TI" AS
/* *********************** Procedimiento Aprobacion Lider de Desarrollo ** Proceso No. 10 ***********************************/
procedure prc_ap_pf_desarrollo (p_xml 			    clob,
						          o_cdgo_rspsta			out number,
						          o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');   
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_id_fljo_trea_orgen			number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  3 , null, 'pkg_ti.prc_ap_pf_desarrollo');
		--pkg_sg_log.prc_rg_log(  3 , null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
              into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			  from ti_g_paquetes_funcional
			 where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_ap_pf_desarrollo');
            pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta || p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 10 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 	   	   ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo 	       ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		       ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio			       ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual        ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	       ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                     ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		       ||'</OBSRVCION_TR>';
							
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
											
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 10 - Codigo: '||o_cdgo_rspsta||
								   'Error al insertar la traza del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'AD' /*,fcha = systimestamp ,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo ;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 10 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'AD' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 10 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		
		if (o_cdgo_rspsta = 0) then
			commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
         apex_util.set_session_state('F_ID_FLJO_TREA',null);
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje			=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error			=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI10-Proceso No. 10 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_desarrollo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;
		else
           rollback;
         
	    end if;
		
		
						
						
	end;-- prc_ap_pf_desarrollo;

/* ***************************** Procedimiento Rechazo Lider de Desarrollo ** Proceso No. 20 **********************************************/

procedure prc_rc_pf_desarrollo (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
						        o_mnsje_rspsta			out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_desarrollo');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo;
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_rc_pf_desarrollo');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 2;
				o_mnsje_rspsta := '|Proceso No. 20 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo	      ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio       		  ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr	          ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 3;
				o_mnsje_rspsta := '|Proceso No. 20 - Codigo: '||o_cdgo_rspsta||
								   'Error al insertar la traza del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( 3, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'RD'/*,fcha = systimestamp,  ESTADO RECHAZO POR LIDER DE DESARROLLO*,*/
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 20 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado de Rechazo del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'RD' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 20 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                 pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI20-Proceso No. 20 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_desarrollo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;
				end if;
			end;
        else
           rollback;
		end if;
    
		
	end;-- prc_rc_pf_desarrollo;

/* *********************** Procedimiento Aprobacion Lider de Calidad ** Proceso No. 30 ***********************************/
  procedure prc_ap_pf_calidad	 (p_xml 			    clob,
						          o_cdgo_rspsta			out number,
						          o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_calidad');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, 'Entrando ' || systimestamp, 6); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_ap_pf_calidad');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr	          ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'AC'/*,fcha = systimestamp ,  ESTADO APROBADO POR LIDER DE CALIDAD*,*/
			--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado aprobado del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'AC' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
            apex_util.set_session_state('F_ID_FLJO_TREA',null);
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI30-Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;		
        else
           rollback;
		end if;
    				
	end;-- prc_ap_pf_calidad;
/* ***************************** Procedimiento Rechazo Lider de Calidad ** Proceso No. 40 **********************************************/
procedure prc_rc_pf_calidad (p_xml	 			    clob,
							 o_cdgo_rspsta			out number,
							 o_mnsje_rspsta			out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_calidad');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo;
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_rc_pf_calidad');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 40 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
								
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 40 - Codigo: '||o_cdgo_rspsta||
								   'Error al insertar la traza del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'RC'/*,fcha = systimestamp ,  ESTADO RECHAZO POR LIDER DE DESARROLLO*,*/
			--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then	
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 40 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado de Rechazo del Paquete Funcional para etapa de Calidad de instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'RC' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
											where id_instncia_fljo =  p_id_instncia_fljo
											and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then	
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 40 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',  v_nl, o_mnsje_rspsta, 1);
				return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI40-Proceso No. 40 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_calidad',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;	
        else
           rollback;
		end if;
		

						
						
						
end;-- prc_rc_pf_calidad;

/* *********************** Procedimiento Aprobacion Analista de Prueba ** Proceso No. 50 ***********************************/
  procedure prc_ap_pf_prueba	 (p_xml 			    clob,
						          o_cdgo_rspsta			out number,
						          o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_prueba');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_ap_pf_prueba');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 50 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 	   	  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
								
		exception
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 50 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_calidad',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'AP'/*,fcha = systimestamp ,  ESTADO APROBADO POR ANALISTA DE PRUEBA *,*/
		--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 50 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobado del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'AP' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 50 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI50-Proceso No. 50 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_prueba',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;
        else
           rollback;
		end if;

						
	end;-- prc_ap_pf_prueba;
/* ***************************** Procedimiento Rechazo Analista de Prueba ** Proceso No. 60 **********************************************/

procedure prc_rc_pf_prueba (p_xml	 			    clob,
							o_cdgo_rspsta			out number,
						    o_mnsje_rspsta			out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_prueba');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_rc_pf_prueba');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 60 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                 pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 60 - Codigo: '||o_cdgo_rspsta||
								   'Error al insertar la traza del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'RP'/*,fcha = systimestamp ,  ESTADO RECHAZO POR ANALISTA DE PRUEBA*,*/
		--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 60 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado de Rechazo del Paquete Funcional para etapa de Prueba de instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'RP' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			 pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 60 - Codigo: '||o_cdgo_rspsta||
				   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
				return;	
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje			=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error			=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI60-Proceso No. 60 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_rc_pf_prueba',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;
        else
           rollback;
		end if;

		
	end;-- prc_rc_pf_prueba;
	
/* ************************* Procedimiento Aprobacion Operativo ** Proceso No. 70 ***********************************/
  procedure prc_ap_pf_operativo	 (p_xml 			    clob,
						          o_cdgo_rspsta			out number,
						          o_mnsje_rspsta		out	varchar2) as
								  
		
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;		
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_operativo');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_ap_pf_operativo');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
		exception 
			when others then	
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 70 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta, 1); 
               return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 70 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'AO'/*,fcha = systimestamp ,  ESTADO APROBADO POR OPERATIVO *,*/
		--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 70 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobado del Paquete Funcional para etapa de Operativo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta, 1); 
               	return;
		end;
						
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'AO' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 70 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI70-Proceso No. 70 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_ap_pf_operativo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;
        else
           rollback;
		end if;

	end;-- prc_ap_pf_operativo;
/* ******************************** Procedimiento Modificacion PF para Etapa revision de Desarrollo Pruebas ** Proceso No. 80 ***********************************/
  procedure prc_md_pf_desarrollo (p_xml 			    clob,
						          o_cdgo_rspsta			out number,
						          o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_md_pf_desarrollo');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_md_pf_desarrollo ',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
								   'Error al insertar la traza del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'MD'/*,fcha = systimestamp  ,  ESTADO MODIFICACION PAQUETE FUNCIONAL POR DESARROLLADOR  PARA ETAPA DE PRUEBA*,*/
		--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Modificacion Desarrollo del Paquete Funcional para etapa de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'MD' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Modificacion Desarrollo del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
			return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
          apex_util.set_session_state('F_ID_FLJO_TREA',null);
      
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI80-Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;
        else
           rollback;
		end if;

	end;-- prc_md_pf_desarrollo;
	-- !! ----------------------------------------------------------------------------------------------------- !! -- 
	-- !!         Procedimiento para actualizar la tarea de la instancia del flujo de TI   Proceso No. 90     	!! --
	-- !! ----------------------------------------------------------------------------------------------------- !! --  		
 procedure prc_up_instancia_flujo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type
                                    , p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type
			                        ) as 
				   
v_cdgo_clnte			number;
v_nl					number;	
v_mnsje					varchar2(5000);
o_cdgo_rspsta			number;
o_mnsje_rspsta			varchar2(5000);
	begin	
			-- Determinamos el nivel del Log de la UPv
			begin
				select cdgo_clnte
				into   v_cdgo_clnte
				from ti_g_paquetes_funcional
				where id_instncia_fljo =  p_id_instncia_fljo; 
		
				v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo');

				pkg_sg_log.prc_rg_log(  v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo',  v_nl, 'Entrando ' || systimestamp, 1); 
			exception 
				when others then
					o_cdgo_rspsta := 10;
					o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
									   'Error  instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
					pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo',  v_nl, o_mnsje_rspsta, 1); 
					return;
			end;
			begin
					update ti_g_paquetes_funcional set id_fljo_trea = p_id_fljo_trea 
					where id_instncia_fljo = p_id_instncia_fljo ;
			exception 
				when others then 
					v_mnsje := 'Proceso No. 90 Error al actualizar el estado de la tarea del flujo de ajuste:' || SQLCODE || ' - - ' || SQLERRM;
					pkg_sg_log.prc_rg_log(  v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo',  v_nl, v_mnsje, 1);
				rollback;
			end;
    commit;
   end;	
   
   
/* **************************** Procedimiento Registro en traza al Generar Paquete Funcional ** Proceso No. 100 ***********************************/ 
procedure prc_rg_tr_paquete_funcional   (p_xml	 			    clob,
										o_id_pqte_fncnal_trza	out number,
										o_cdgo_rspsta			out number,
										o_mnsje_rspsta			out	varchar2) as									
			  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO');
		p_id_fljo_trea		            ti_g_paquetes_funcional.id_fljo_trea%type		        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA'); 
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO'); 
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO_ACTUAL'); 
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO_ANTRIOR');
		v_fcha							ti_g_paquetes_funcional.fcha%type						:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'FCHA');
		v_obsrvcion						ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
        def_num_rec_pr 					number; 
		v_num_rec_pr					number;
		v_json_parametros 				clob;
		v_nl							number;
		v_orden							number;
		v_mnsje							varchar2(5000);
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rg_tr_paquete_funcional');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rg_tr_paquete_funcional ',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		
		begin
			select cdgo_clnte
			into   v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
	
			v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo');

			pkg_sg_log.prc_rg_log(  v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo',  v_nl, 'Entrando ' || systimestamp, 1); 
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 80 - Codigo: '||o_cdgo_rspsta||
								   'Error  instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_up_instancia_flujo',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		
		begin 
			select nvl( max(orden), 0 ) + 1  into v_orden
			from ti_g_paquetes_fncnal_trza
			where id_pqte_fncnal = p_id_pqte_fncnal;
		exception 
			when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 100 - Codigo: '||o_cdgo_rspsta||
				    			   'Error al encontrar el orden de la traza al generar el Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rg_tr_paquete_funcional',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			insert into ti_g_paquetes_fncnal_trza (id_pqte_fncnal,id_usrio,cdgo_estdo_actual,cdgo_estdo_antrior,fcha,id_instncia_fljo,id_fljo_trea,obsrvcion,orden)
			values (p_id_pqte_fncnal,v_id_usrio,v_cdgo_estdo_actual,v_cdgo_estdo_antrior,systimestamp,p_id_instncia_fljo,p_id_fljo_trea,v_obsrvcion,v_orden)
			returning id_pqte_fncnal_trza into o_id_pqte_fncnal_trza;
		exception 
			when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 100 - Codigo: '||o_cdgo_rspsta||
								  'Error al Insertar la traza al generar el Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rg_tr_paquete_funcional',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		begin
			select to_number(vlor)
			into def_num_rec_pr 	
			from df_c_definiciones_cliente
			where cdgo_clnte = v_cdgo_clnte
			and cdgo_dfncion_clnte ='PFC';
		exception
			when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 100 - Codigo: '||o_cdgo_rspsta||
								  'Problerma al Consultar la definicion de cliente del valor ciclico de Paquete Funcional instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rg_tr_paquete_funcional',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		
		begin
            begin
                select count(cdgo_estdo_actual) into v_num_rec_pr
                from v_ti_g_paquetes_fncnal_trza
                where  id_pqte_fncnal= p_id_pqte_fncnal
                and cdgo_estdo_actual='RP'
                group by cdgo_estdo_actual;
            exception
                when no_data_found then
                    v_num_rec_pr:=0;
                when others then
                    o_cdgo_rspsta := 1;
                    o_mnsje_rspsta := '|Proceso No. 100 - Codigo: '||o_cdgo_rspsta||
                                      'Problerma al ejecutar el envio Programado Paquete Funcional instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                    pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rg_tr_paquete_funcional',  v_nl, o_mnsje_rspsta, 1); 
                    return;	    
			end;
			if (v_num_rec_pr > def_num_rec_pr  /* 3 */) then 
				begin
					begin
						select json_object(
						key 'p_id_pqte_fncnal' is p_id_pqte_fncnal,
						key 'v_num_rec_pr'     is v_num_rec_pr
					   )
					   into v_json_parametros
					   from dual;
					   
					   pkg_ma_envios.prc_co_envio_programado(
						   p_cdgo_clnte                => v_cdgo_clnte,
						   p_idntfcdor                 => 'PKG_TI.PRC_RG_TR_PAQUETE_FUNCIONAL',
						   p_json_prmtros              => v_json_parametros
					   );
				   end;			
				end;
			end if;
		exception
		when others then
				o_cdgo_rspsta := 1;
				o_mnsje_rspsta := '|Proceso No. 100 - Codigo: '||o_cdgo_rspsta||
								  'Problerma al ejecutar el envio Programado Paquete Funcional instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rg_tr_paquete_funcional',  v_nl, o_mnsje_rspsta, 1); 
				return;	
		end;
	end;-- prc_rg_tr_paquete_funcional;



/* *********************** Procedimiento Modificacion PF para Etapa de Prueba **Proceso No. 110  ***********************************/
 procedure prc_mp_pf_prueba (p_xml 			    clob,
							  o_cdgo_rspsta			out number,
							  o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_mp_pf_prueba');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_mp_pf_prueba ',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha,cdgo_clnte
			into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			v_nl := pkg_sg_log.fnc_ca_nivel_log(  v_cdgo_clnte , null, 'pkg_ti.prc_mp_pf_prueba');
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_mp_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_mp_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_mp_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'MP' /*,fcha = systimestamp  ,  ESTADO MODIFICACION PAQUETE FUNCIONAL POR DESARROLLADOR  PARA ETAPA DE PRUEBA*,*/
		--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Modificacion Desarrollo del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_mp_pf_prueba',  v_nl, o_mnsje_rspsta, 1); 
                return;
		end;
						
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'MP' ,fcha = systimestamp /*,  ESTADO APROBADO POR LIDER DESARROLLO*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_mp_pf_prueba',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Modificacion Desarrollo del Paquete Funcional para etapa de Prueba instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
			begin
				pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI110-Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_md_pf_desarrollo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;

        else
           rollback;
		end if;
	end;-- prc_mp_pf_prueba;

/* **************************** Procedimiento  Revisión PF por el Líder de Desarrollo **Proceso No. 120 ***********************************/ 
procedure prc_rl_pf_desarrollo (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2) as
								  
		
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_cdgo_clnte					number;
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
								  
		-- Determinamos el nivel del Log de la UPv
		
	begin
		--v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rl_pf_desarrollo');
		--pkg_sg_log.prc_rg_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
			begin
				select cdgo_estdo,fcha,cdgo_clnte
				into v_cdgo_estdo_actual,v_fcha,v_cdgo_clnte
				from ti_g_paquetes_funcional
				where id_instncia_fljo =  p_id_instncia_fljo; 
				v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_id_pqte_fncnal , null, 'pkg_ti.prc_rl_pf_desarrollo');
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
			exception 
				when others then
					o_cdgo_rspsta := 10;
					o_mnsje_rspsta := '|Proceso No. 120 - Codigo: '||o_cdgo_rspsta||
								   'Error al seleccionar el codigo del estado y la fecha del Paquete Funcional para etapa de Revision Lider de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                   
                    pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                    return;
			end;
						
			begin
				p_xml_tr := 	      '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
				p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
				p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
				p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
				p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
				p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
				p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
				p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr		      ||'</OBSRVCION_TR>';
					
				pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
									
			exception 
				when others then
					o_cdgo_rspsta := 20;
					o_mnsje_rspsta := '|Proceso No. 120 - Codigo: '||o_cdgo_rspsta||
						   'Error al insertar la traza del Paquete Funcional para etapa de Revision Lider de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
		   			pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
					return;
			end;
						
			begin
				 update ti_g_paquetes_funcional set  cdgo_estdo = 'RL'/*,fcha = systimestamp  ESTADO PAQUETE EN REVISIÓN POR EL LÍDER DE DESARROLLO.*/
				 where id_pqte_fncnal =  p_id_pqte_fncnal ;
			exception 
				when others then
					o_cdgo_rspsta := 30;
					o_mnsje_rspsta := '|Proceso No. 120 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobado del Paquete Funcional para etapa de Revision Lider de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
                    pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                    return;
			end;
						
			begin 
				update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'RL' ,fcha = systimestamp /* ESTADO PAQUETE EN REVISIÓN POR EL LÍDER DE DESARROLLO.*/
				where id_instncia_fljo =  p_id_instncia_fljo
				and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
				pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
			exception 
				when others then
					o_cdgo_rspsta := 40;
					o_mnsje_rspsta := '|Proceso No. 120 - Codigo: '||o_cdgo_rspsta||
								   'Error al actualizar el estado Aprobacion del Paquete Funcional para etapa de Revision Lider de Desarrollo instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
					pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',  v_nl, o_mnsje_rspsta, 1); 
                    return;
			end;
			
			if (o_cdgo_rspsta = 0) then
				commit;
			/*	begin
					select      a.id_fljo_trea_orgen
					into        v_id_fljo_trea_orgen
					from        wf_g_instancias_transicion     a
					where       a.id_instncia_fljo  =     p_id_instncia_fljo
					and         a.id_estdo_trnscion in      (1, 2);
			end;*/
				begin
					pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																	 p_id_fljo_trea		=>	p_id_fljo_trea,
																	 p_json				=>	'[]',
																	 o_type				=> 	v_o_type,
																	 o_mnsje			=>	o_mnsje,
																	 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																	 o_error			=>	v_o_error);
					if v_o_type = 'S' then
						o_cdgo_rspsta := 50;
						o_mnsje_rspsta := ' |GTI110-Proceso No. 110 - Codigo: '||o_cdgo_rspsta||
						   ' Problemas al intentar avanzar a la siguiente etapa del flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
						v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
					--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_rl_pf_desarrollo',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
						return;--continue;
					end if;
				end;
			else
				rollback;
			end if;
		
	end;-- prc_rl_pf_desarrollo;	

/* **************************** Procedimiento  Envio Programado de Alerta y  **Proceso No. 130 ***********************************/ 
procedure prc_envio_programado_calidad	 (p_cdgo_clnte			number,
                                          p_id_instncia_fljo	number) as
	v_json_parametros clob;
	
	begin
		begin
			select json_object(
            key 'p_id_instncia_fljo' is p_id_instncia_fljo
           )
           into v_json_parametros
           from dual;
           
           pkg_ma_envios.prc_co_envio_programado(
               p_cdgo_clnte                => p_cdgo_clnte,
               p_idntfcdor                 => 'PKG_TI.PRC_ENVIO_PROGRAMADO_CALIDAD',
               p_json_prmtros              => v_json_parametros
           );
       end;
						
						
end;-- prc_envio_programado_calidad;	


/* *****************************Procedimiento  Insertar Archivo Adjunto PF.  **Proceso No. 140************************************ */ 
procedure 	prc_guardar_pqte_fncnl_adjnto(	p_cdgo_clnte		number,
                                            p_id_pqte_fncnal    number,
											p_cdgo_adjnto_tpo 	varchar2,
											p_adjnto		    clob, -- item de pagina 
                                            p_fcha         		timestamp,
											p_obsrvcion         varchar2,
											p_nmro_aplccion     number,
											p_nmro_pgna         number,
                                            p_id_usrio_adjnto   number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2) as

v_nl							number;	
v_mnsje							varchar2(5000);
l_file_names 					apex_t_varchar2;     
l_file       					apex_application_temp_files%rowtype; 
begin
    l_file_names := apex_string.split (p_str => p_adjnto,p_sep => ':' ); 
	for i in 1 .. l_file_names.count
        loop           
            select *
            into l_file
            from apex_application_temp_files
            where application_id = NV('APP_ID')
            and name = l_file_names(i);
            begin
                insert into ti_g_paquetes_fncnal_adjnto (id_pqte_fncnal,cdgo_adjnto_tpo,fcha,obsrvcion,nmro_aplccion,nmro_pgna,file_blob,file_name,file_mimetype,id_usrio_adjnto)
                values 	(p_id_pqte_fncnal,p_cdgo_adjnto_tpo,p_fcha,p_obsrvcion,p_nmro_aplccion,p_nmro_pgna,l_file.blob_content,l_file_names(i),l_file.mime_type,p_id_usrio_adjnto); 
            exception 
                when others then 		  																  
                    rollback;
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := ' |Proceso No. 140 - Codigo: '||o_cdgo_rspsta || ' No fue posible cargar el archivo.'||o_mnsje_rspsta ;
                    v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;	
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_guardar_pqte_fncnl_adjnto ',v_nl,o_mnsje_rspsta || v_mnsje, 1); 
                    return;
            end;
      end loop;      
end;--fin prc_guardar_pqte_fncnl_adjnto

/* ****************************Procedimiento  Insertar Historico Archivo Adjuntos PF. Versionamiento **Proceso No. 150************************* */

procedure prc_insrtr_h_pqte_fncnl_adjnto (	p_id_pqte_fncnal_adjnto		number,
											p_cdgo_adjnto_tpo           varchar2,
											p_obsrvcion					varchar2,
											p_nmro_aplccion				number,
											p_nmro_pgna 				number,
											p_file_blob_new				blob,
                                            p_file_names                varchar2,
                                            p_mime_type                 varchar2,
											p_cdgo_clnte				number,
											o_cdgo_rspsta				out number,
											o_mnsje_rspsta				out	varchar2) as
						  
	c_id_pqte_fncnal_adjnto             number;
	c_cdgo_adjnto_tpo                   varchar2(3 byte);
	c_fcha                              timestamp;
	c_obsrvcion                         varchar2(4000 byte);
	c_nmro_aplccion                     number;
	c_nmro_pgna                         number;
	c_file_clob_old                     clob;
	c_file_blob_old                     blob;
	c_file_name                         varchar2(250 byte);
	c_file_mimetype                     varchar2(100 byte);
	c_nmro_vrsion                       number;
	c_id_usrio_adjnto                   number ;
	v_nl							    number;	
	v_mnsje							    varchar2(5000);

	begin
		-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_cdgo_clnte , null, 'prc_insrtr_h_pqte_fncnl_adjnto');
		pkg_sg_log.prc_rg_log(  p_cdgo_clnte , null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl, 'Entrando ' || systimestamp, 1); 
		o_cdgo_rspsta :=	0;
        --	insert into gti_aux (col1,col2) values ('entrando pkg_ti.prc_insrtr_h_pqte_fncnl_adjnto en procedimento', 'i' || systimestamp);	
		begin						
			select 	id_pqte_fncnal_adjnto,
					cdgo_adjnto_tpo,
					fcha,
					obsrvcion,
					nmro_aplccion,
					nmro_pgna,
					file_blob,
					file_name,
					file_mimetype,
					nmro_vrsion
			into	c_id_pqte_fncnal_adjnto ,
					c_cdgo_adjnto_tpo,
					c_fcha,
					c_obsrvcion,
					c_nmro_aplccion,
					c_nmro_pgna,
					c_file_blob_old,
					c_file_name,
					c_file_mimetype ,
					c_nmro_vrsion
			from ti_g_paquetes_fncnal_adjnto where id_pqte_fncnal_adjnto =  p_id_pqte_fncnal_adjnto;								
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 150 - Codigo: '||o_cdgo_rspsta||
					   'No se encuentran datos del Paquete Funcional '||o_mnsje_rspsta ;
                v_mnsje := o_mnsje_rspsta||'- Error: '|| SQLCODE || '--' || '--' || SQLERRM;       
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl,  v_mnsje, 1); 
				return;
		end;
						
		begin
			if dbms_lob.compare(p_file_blob_new, c_file_blob_old) <> 0  then 
            --	insert into gti_aux (col1,col2) values ('entrando pkg_ti.prc_insrtr_h_pqte_fncnl_adjnto en procedimento if', 'i' || systimestamp);	
				begin
					insert into ti_h_paquetes_fncnal_adjnto (id_pqte_fncnal_adjnto,        cdgo_adjnto_tpo,         fcha, 
															 obsrvcion,                     nmro_aplccion,          nmro_pgna, 
															 file_blob,                     file_name,              file_mimetype, 
															 nmro_vrsion)
													 values (c_id_pqte_fncnal_adjnto,    c_cdgo_adjnto_tpo,   c_fcha, 
															 c_obsrvcion,                c_nmro_aplccion,     c_nmro_pgna, 
															 p_file_blob_new,            c_file_name,         c_file_mimetype, 
															 c_nmro_vrsion);
				exception 
                    when others then
                        o_cdgo_rspsta := 20;
                        o_mnsje_rspsta := '|Proceso No. 150 - Codigo: '||o_cdgo_rspsta||
                               'No se pudo insertar en el historial del archivo adjunto del Paquete Funcional '||o_mnsje_rspsta ;
                        v_mnsje := o_mnsje_rspsta||'- Error: '|| SQLCODE || '--' || '--' || SQLERRM;       
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl,  v_mnsje, 1); 
                        return;
                end;												
				begin
					update ti_g_paquetes_fncnal_adjnto set cdgo_adjnto_tpo  = p_cdgo_adjnto_tpo,
														   obsrvcion        = p_obsrvcion,
														   nmro_aplccion    = p_nmro_aplccion,
														   nmro_pgna        = p_nmro_pgna,
														   fcha             = systimestamp,
														   FILE_BLOB        = p_file_blob_new,
														   FILE_NAME        = p_file_names,
														   FILE_MIMETYPE    = p_mime_type,
														   nmro_vrsion      = c_nmro_vrsion + 1				
					where id_pqte_fncnal_adjnto =  p_id_pqte_fncnal_adjnto; 
                 exception 
                    when others then
                        o_cdgo_rspsta := 30;
                        o_mnsje_rspsta := '|Proceso No. 150 - Codigo: '||o_cdgo_rspsta||
                                   'No se pudo actualizar el archivo adjunto del Paquete Funcional '||o_mnsje_rspsta ;
                        v_mnsje := o_mnsje_rspsta||'- Error: '|| SQLCODE || '--' || '--' || SQLERRM;       
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl,  v_mnsje, 1); 
                        return;   
				end;		
            else
				begin
					update ti_g_paquetes_fncnal_adjnto set cdgo_adjnto_tpo  = p_cdgo_adjnto_tpo,
														   obsrvcion        = p_obsrvcion,
														   nmro_aplccion    = p_nmro_aplccion,
														   nmro_pgna        = p_nmro_pgna,
														   fcha             = systimestamp,
														   FILE_BLOB        = c_file_blob_old,
														   FILE_NAME        = c_file_name,
														   FILE_MIMETYPE    = c_file_mimetype,
														   nmro_vrsion      = c_nmro_vrsion				
					where id_pqte_fncnal_adjnto =  p_id_pqte_fncnal_adjnto; 
                exception 
                    when others then
                        o_cdgo_rspsta := 40;
                        o_mnsje_rspsta := '|Proceso No. 150 - Codigo: '||o_cdgo_rspsta||
                                    'No se pudo actualizar el archivo adjunto del Paquete Funcional '||o_mnsje_rspsta ;
                        v_mnsje := o_mnsje_rspsta||'- Error: '|| SQLCODE || '--' || '--' || SQLERRM;       
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl,  v_mnsje, 1); 
                        return;
                end;
			end if;
		exception 
			when others then
				o_cdgo_rspsta := 50;
				o_mnsje_rspsta := '|Proceso No. 150 - Codigo: '||o_cdgo_rspsta||
					   'Problema al evaluar la condicion de comparacion del archivo adjunto.'||o_mnsje_rspsta;	   
				v_mnsje := o_mnsje_rspsta||'- Error: '|| SQLCODE || '--' || '--' || SQLERRM;       
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_insrtr_h_pqte_fncnl_adjnto',  v_nl,  v_mnsje, 1); 	
                return;	
		end;
end;-- fin prc_insrtr_h_pqte_fncnl_adjnto; 
/* *********************** Procedimiento Anulacion de PF. x Lider de Etapa ** Proceso No. 160 ***********************************/
  procedure prc_an_pf_lider_x_etapa	 (	p_xml 			    clob,
										p_cdgo_clnte		number,
										o_cdgo_rspsta		out number,
										o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');    
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		v_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_cdgo_estdo_antrior			ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
        v_type	                        varchar2(1); 
		-- Determinamos el nivel del Log de la UPv
		
	begin
		v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_cdgo_clnte , null, 'pkg_ti.prc_an_pf_lider_x_etapa');
		pkg_sg_log.prc_rg_log(  p_cdgo_clnte , null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, 'Entrando ' || systimestamp, 6); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha
			into v_cdgo_estdo_actual,v_fcha
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||v_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr	          ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			update ti_g_paquetes_funcional set  cdgo_estdo = 'AN'/*,fcha = systimestamp ,  ESTADO ANULADO POR LIDER DE ETAPA*/
			--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Anulado del Paquete Funcional por Lider de Etapa Instancia del Flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		begin 
			update ti_g_paquetes_fncnal_trza set  cdgo_estdo_actual = 'AN' ,fcha = systimestamp /*,  ESTADO ANULADO POR LIDER DE ETAPA*,*/
			where id_instncia_fljo =  p_id_instncia_fljo
			and id_pqte_fncnal_trza = o_id_pqte_fncnal_trza;
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 1); 	
		exception 
			when others then
				o_cdgo_rspsta := 40;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Anulado del Paquete Funcional por Lider de Etapa Instancia del Flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		
		if (o_cdgo_rspsta = 0) then
		    commit;
		/*	begin
				select      a.id_fljo_trea_orgen
				into        v_id_fljo_trea_orgen
				from        wf_g_instancias_transicion     a
				where       a.id_instncia_fljo  =     p_id_instncia_fljo
				and         a.id_estdo_trnscion in      (1, 2);
			end;*/
            apex_util.set_session_state('F_ID_FLJO_TREA',null);
			begin
				pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo,
															   p_id_fljo_trea,
                                                               v_id_usrio,
																v_type,
																v_mnsje);
			
			
			/*pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo	=>	p_id_instncia_fljo,
																 p_id_fljo_trea		=>	p_id_fljo_trea,
																 p_json				=>	'[]',
																 o_type				=> 	v_o_type,
																 o_mnsje				=>	o_mnsje,
																 o_id_fljo_trea		=>	v_o_id_fljo_trea,
																 o_error				=>	v_o_error);*/
				if v_o_type = 'S' then
					o_cdgo_rspsta := 50;
					o_mnsje_rspsta := ' |GTI30-Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   ' Problemas al intentar Finalizar Instancia del Flujo No.'||p_id_instncia_fljo||' '||o_mnsje||v_o_error;
					v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;		   
				--	pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_an_pf_lider_x_etapa',v_nl, o_mnsje||v_mnsje||' ' || systimestamp, 1);
					return;--continue;
				end if;
			end;		
        else
           rollback;
		end if;
    				
	end;-- prc_an_pf_lider_x_etapa;		 

/* *********************** Procedimiento Anulacion de PF. x Lider de Etapa ** Proceso No. 170 ***********************************/
  procedure prc_reasignacion_pf	 (	p_xml 			    clob,
									p_cdgo_clnte		number,
									o_cdgo_rspsta		out number,
									o_mnsje_rspsta		out	varchar2) as
								  
								  
		p_id_pqte_fncnal				ti_g_paquetes_funcional.id_pqte_fncnal%type				:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_PQTE_FNCNAL');
		p_id_instncia_fljo	            ti_g_paquetes_funcional.id_instncia_fljo%type	        :=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_INSTNCIA_FLJO'); 
		p_cdgo_estdo					ti_g_paquetes_funcional.cdgo_estdo%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_ESTDO');   
        p_id_fljo_trea					ti_g_paquetes_funcional.id_fljo_trea%type	        	:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
		p_id_usrio						ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
		p_id_usrio_rsgndo				ti_g_paquetes_funcional.id_usrio%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO_RSGNDO');
		v_cdgo_estdo_actual				ti_g_paquetes_funcional.cdgo_estdo%type;
		v_fcha							ti_g_paquetes_funcional.fcha%type;
		v_obsrvcion_tr					ti_g_paquetes_funcional.obsrvcion%type					:=	pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'OBSRVCION_TR');
		v_nmbre_trcro					varchar2(5000);
		v_nl							number;	
		v_mnsje							varchar2(5000);
		p_xml_tr						clob;
		o_id_pqte_fncnal_trza			number;
		o_cdgo_rspsta_tr				number;
		o_mnsje_rspsta_tr				varchar2(5000);
		v_o_type						varchar2(10);
		v_o_id_fljo_trea				number;
		v_o_error						varchar2(500);
		o_mnsje							varchar2(5000);
		v_id_fljo_trea_orgen			number;
		v_type	                        varchar2(1); 
		-- Determinamos el nivel del Log de la UPv
		
	begin
		v_nl := pkg_sg_log.fnc_ca_nivel_log(  p_cdgo_clnte , null, 'pkg_ti.prc_reasignacion_pf');
		pkg_sg_log.prc_rg_log(  p_cdgo_clnte , null, 'pkg_ti.prc_reasignacion_pf',  v_nl, 'Entrando ' || systimestamp, 6); 
		o_cdgo_rspsta :=	0;
		begin
			select cdgo_estdo,fcha
			into v_cdgo_estdo_actual,v_fcha
			from ti_g_paquetes_funcional
			where id_instncia_fljo =  p_id_instncia_fljo; 
			pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_reasignacion_pf',  v_nl, o_mnsje_rspsta ||p_id_instncia_fljo, 6); 										
		exception 
			when others then
				o_cdgo_rspsta := 10;
				o_mnsje_rspsta := '|Proceso No. 170 - Codigo: '||o_cdgo_rspsta||
					   'Error al seleccionar el ususario el codigo del estado y la fecha del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_reasignacion_pf',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
						
		begin
			select nmbre_trcro into v_nmbre_trcro from v_sg_g_usuarios where id_usrio = p_id_usrio_rsgndo;
			v_obsrvcion_tr :='Reasignacion al usuario: '|| v_nmbre_trcro ||' del Paquete Funcional';
		
			p_xml_tr := 	       '<ID_PQTE_FNCNAL>'	  ||p_id_pqte_fncnal 		  ||'</ID_PQTE_FNCNAL>';
			p_xml_tr := p_xml_tr||'<ID_INSTNCIA_FLJO>'	  ||p_id_instncia_fljo        ||'</ID_INSTNCIA_FLJO>';
			p_xml_tr := p_xml_tr||'<ID_FLJO_TREA>'		  ||p_id_fljo_trea 		      ||'</ID_FLJO_TREA>';
			p_xml_tr := p_xml_tr||'<ID_USRIO>'	 		  ||p_id_usrio                ||'</ID_USRIO>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ACTUAL>'	  ||v_cdgo_estdo_actual       ||'</CDGO_ESTDO_ACTUAL>';
			p_xml_tr := p_xml_tr||'<CDGO_ESTDO_ANTRIOR>'  ||v_cdgo_estdo_actual	      ||'</CDGO_ESTDO_ANTRIOR>';
			p_xml_tr := p_xml_tr||'<FCHA>' 				  ||v_fcha                    ||'</FCHA>';
			p_xml_tr := p_xml_tr||'<OBSRVCION_TR>'	      ||v_obsrvcion_tr	          ||'</OBSRVCION_TR>';
				
			pkg_ti.prc_rg_tr_paquete_funcional   (p_xml_tr,o_id_pqte_fncnal_trza,o_cdgo_rspsta_tr,o_mnsje_rspsta_tr);	
		exception 
			when others then
				o_cdgo_rspsta := 20;
				o_mnsje_rspsta := '|Proceso No. 170 - Codigo: '||o_cdgo_rspsta||
					   'Error al insertar la traza del Paquete Funcional para etapa de Calidad instancia del flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_reasignacion_pf',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
		

		begin
			update wf_g_instancias_transicion set  id_usrio = p_id_usrio_rsgndo  /*,  REASIGNACION PF POR LIDER DE ETAPA*,*/
			where id_instncia_fljo =  p_id_instncia_fljo and id_estdo_trnscion in (1,2,4);
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Anulado del Paquete Funcional por Lider de Etapa Instancia del Flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
	   
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_reasignacion_pf',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;	
		begin
			update ti_g_paquetes_funcional set id_usrio = p_id_usrio_rsgndo   /* REASIGNACION DE USUSARIO CREADO PF POR LIDER DE ETAPA*/
			--	id_fljo_trea = p_id_fljo_trea 
			where id_pqte_fncnal =  p_id_pqte_fncnal ;
		exception 
			when others then
				o_cdgo_rspsta := 30;
				o_mnsje_rspsta := '|Proceso No. 30 - Codigo: '||o_cdgo_rspsta||
					   'Error al actualizar el estado Anulado del Paquete Funcional por Lider de Etapa Instancia del Flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta ;
				pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_ti.prc_reasignacion_pf',  v_nl, o_mnsje_rspsta, 1); 
				return;
		end;
	end;-- prc_reasignacion_pf;		 
 
/* ****************************                    ***********************************/   
 
end  pkg_ti;

/
