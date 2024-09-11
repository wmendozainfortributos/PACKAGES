--------------------------------------------------------
--  DDL for Package PKG_TI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_TI" as

/* ***************************** Procedimiento Aprobacion Lider de Desarrollo ** Proceso No. 10 ***********************************/  
procedure prc_ap_pf_desarrollo  (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);	
						 
/* ***************************** Procedimiento Rechazo Lider de Desarrollo ** Proceso No. 20 **********************************************/						 
procedure prc_rc_pf_desarrollo  (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
						        o_mnsje_rspsta			out	varchar2);	
								
/* ***************************** Procedimiento Aprobacion Lider de Calidad ** Proceso No. 30 ***********************************/  
procedure prc_ap_pf_calidad     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);

/* **************************** Procedimiento Rechazo Lider de Calidad ** Proceso No. 40 **********************************************/								
procedure prc_rc_pf_calidad     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);
								
/* **************************** Procedimiento Aprobacion Analista de Prueba ** Proceso No. 50 ***********************************/ 
procedure prc_ap_pf_prueba     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);
								
/* ***************************** Procedimiento Rechazo Analista de Prueba  ** Proceso No. 60 **********************************************/								
procedure prc_rc_pf_prueba     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);
								
/* **************************** Procedimiento Aprobacion Operativo ** Proceso No. 70 ***********************************/ 
procedure prc_ap_pf_operativo     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);								
								
/* **************************** Procedimiento Modificacion PF para Etapa revision de Desarrollo Pruebas **Proceso No. 80 ***********************************/ 
procedure prc_md_pf_desarrollo     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);	

/* *************************** Procedimiento para actualizar la tarea de la instancia del flujo de TI **Proceso No. 90 *************/						
procedure prc_up_instancia_flujo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type
                                   , p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type
								  );								
/* **************************** Procedimiento Registro en traza al Generar Paquete Funcional ** Proceso No. 100 ***********************************/ 
procedure prc_rg_tr_paquete_funcional   (p_xml	 			    clob,
										o_id_pqte_fncnal_trza	out number,
										o_cdgo_rspsta			out number,
										o_mnsje_rspsta			out	varchar2);									

/* **************************** Procedimiento Modificacion PF para Etapa de Prueba **Proceso No. 110 ***********************************/ 
procedure prc_mp_pf_prueba     (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);								


/* **************************** Procedimiento  Revisión PF por el Líder de Desarrollo **Proceso No. 120 ***********************************/ 
procedure prc_rl_pf_desarrollo (p_xml	 			    clob,
								o_cdgo_rspsta			out number,
								o_mnsje_rspsta			out	varchar2);


/* **************************** Procedimiento  Envio Programado de Alerta y  **Proceso No. 130 ***********************************/ 
procedure prc_envio_programado_calidad	 (p_cdgo_clnte			number,
										  p_id_instncia_fljo	number);
                                          
/* *****************************Procedimiento  Insertar Archivo Adjunto PF.  **Proceso No. 140************************************ */ 
procedure prc_guardar_pqte_fncnl_adjnto(	p_cdgo_clnte		number,
                                            p_id_pqte_fncnal    number,
											p_cdgo_adjnto_tpo 	varchar2,
                                            p_adjnto		    clob,
											p_fcha         		timestamp,
											p_obsrvcion         varchar2,
											p_nmro_aplccion     number,
											p_nmro_pgna         number,
                                            p_id_usrio_adjnto   number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2);

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
											o_mnsje_rspsta				out	varchar2);

/* *********************** Procedimiento Anulacion de PF. x Lider de Etapa ** Proceso No. 160 ***********************************/
  procedure prc_an_pf_lider_x_etapa	 (	p_xml 			    clob,
										p_cdgo_clnte		number,
										o_cdgo_rspsta		out number,
										o_mnsje_rspsta		out	varchar2);
/* *********************** Procedimiento Anulacion de PF. x Lider de Etapa ** Proceso No. 170 ***********************************/

  procedure prc_reasignacion_pf	 (	p_xml 			    clob,
									p_cdgo_clnte		number,
									o_cdgo_rspsta		out number,
									o_mnsje_rspsta		out	varchar2);
                                    

end pkg_ti;

/
