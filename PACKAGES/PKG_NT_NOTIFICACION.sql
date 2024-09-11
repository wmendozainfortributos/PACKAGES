--------------------------------------------------------
--  DDL for Package PKG_NT_NOTIFICACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_NT_NOTIFICACION" as
  
  -->1<--
  /*Procedimiento para consultar el medio de notificacion que debe seguir, 
    segun la secuencia del tipo de acto*/
  procedure prc_co_min_orden(
    p_id_ntfccion   in number,
    o_min_orden     out number,
    o_cant_mdios    out number,
    o_mnsje_tpo     out varchar2,
    o_mnsje         out varchar2
  );

  -->2<--
  /*Procedimiento para el registro en notificaciones de actos, asociados a 
    un acto requerido*/
  procedure prc_rg_notificacion_automatica(
    p_id_acto in  number
  );

  -->3<--
  /*Procedimiento que valida y registra intentos de notificacion*/
  procedure prc_gn_detalle_notificacion;

  -->4<--
  /*Procedimiento para actualizar el intento de notificacion edicto*/
  procedure prc_ac_edicto(
    p_id_lte        in  nt_g_lote.id_lte%type,
    p_fcha_fin      in  timestamp,
    p_file_evdncia  in  varchar2,
    p_id_fncnrio    in  number,
    o_mnsje_tpo     out varchar2,
    o_mnsje         out varchar2
  );

  -->5<--
  /*Procedimiento para registrar un edicto*/
  procedure prc_rg_edicto(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_fcha_incio            in  timestamp,
    p_ubccion               in  varchar2,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  );

  -->6<--
  /*Procedimiento para registrar el intento de notificacion gaceta*/
  procedure prc_rg_gaceta(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_nmro_gceta            in  nt_g_gaceta.nmro_gceta%type,
    p_fcha_pblccion         in  timestamp,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  );

  -->7<--
  /*Procedimiento para registrar el intento de notificacion prensa*/
  procedure prc_rg_prensa(
    p_id_lte                in  nt_g_lote.id_lte%type,
    p_ubccion               in  varchar2,
    p_fcha_rgstro           in  timestamp,
    p_file_evdncia          in  varchar2,
    p_id_fncnrio            in  number,
    o_mnsje_tpo             out varchar2,
    o_mnsje                 out varchar2
  );

  -->8<--
  /*Procedimiento para el registro de notificacion puntual
  ('Notificacion Pesonal', 'Conducta Concluyente')*/
  procedure prc_rg_notificacion__puntual(
    p_cdgo_clnte			in  number,
    p_id_acto               in  number,
    p_id_ntfccion           in  nt_g_notificaciones.id_ntfccion%type,
    p_json_rspnsbles        in  clob,
    p_cdgo_rspnsble_tpo     in df_s_responsables_tipo.cdgo_rspnsble_tpo%type        default null, 
    p_cdgo_idntfccion_tpo   in df_s_identificaciones_tipo.cdgo_idntfccion_tpo%type  default null,
    p_nmro_idntfccion       in nt_g_presentacion_personal.nmro_idntfccion%type      default null,
    p_cdgo_mncpio           in  varchar2                                            default null,
    p_nmro_trjeta_prfsnal   in  varchar2                                            default null,
    p_prmer_nmbre           in  varchar2                                            default null,
    p_sgndo_nmbre           in  varchar2                                            default null,
    p_prmer_aplldo          in  varchar2                                            default null,
    p_sgndo_aplldo          in  varchar2                                            default null,
    p_file_evdncia          in  varchar2,
    p_fcha_prsntccion       in  timestamp                                           default null,
    p_id_fncnrio            in  number,
    p_cdgo_mdio             in  varchar2,
    o_cdgo_rspsta			out number,
    o_mnsje_rspsta          out varchar2
  );

  -->9<--
  /*Procedimiento para eliminar un lote*/
  procedure prc_el_lote(
    p_id_lote    in     number,
    o_mnsje_tpo  out    varchar2,
    o_mnsje      out    varchar2
  );

  -->10<--
  /*Procedimiento para actualizar un lote*/
  procedure prc_ac_lote(
    p_id_lote    in     number,
    p_id_fncnrio in     nt_g_lote.id_fncnrio_prcsmnto%type,
    o_mnsje_tpo  out    varchar2,
    o_mnsje      out    varchar2
  );

  -->11<--
  /*Procedimiento para adicionar el detalle a un lote*/
  procedure prc_rg_detalle_lotes(
    p_id_lote                   in     number,
    p_id_ntfccion_dtlle_json    in     clob,
    o_mnsje_tpo                 out    varchar2,
    o_mnsje                     out    varchar2
  );

  -->12<--
  /*Procedimiento para registrar en notificaciones un conjunto de actos*/
  procedure prc_rg_notificaciones_actos(
    p_cdgo_clnte            in      varchar2,
    p_id_acto               in      number default null,
    p_json_actos            in      clob default null,
    p_id_usrio              in      number default null,
    p_id_fncnrio            in      nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type default null, 
    o_mnsje_tpo             out     varchar2,
    o_mnsje                 out     varchar2
  );

  -->13<--
  /*Procedimiento para registrar una notificacion asociada a un acto*/
  procedure prc_rg_notificaciones(
    p_id_ntfccion           out     nt_g_notificaciones.id_ntfccion%type,
    p_id_acto               in      number,
    p_cdgo_estdo            in      varchar2,
    p_indcdor_ntfcdo        in      varchar2,
    p_id_fncnrio            in      nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
    p_cdgo_clnte            in      df_s_clientes.cdgo_clnte%type,
    o_mnsje_tpo             out     varchar2,
    o_mnsje                 out     varchar2
  );

  -->14<--  
  /*Procedimiento para registrar un intento de notificacion asociado a un acto*/
  procedure prc_rg_notificacion_detalle(
    p_id_ntfccion_dtlle     out     nt_g_notificaciones_detalle.id_ntfccion_dtlle%type,
    p_id_ntfccion           in      nt_g_notificaciones_detalle.id_ntfccion%type,
    p_id_mdio               in      nt_g_notificaciones_detalle.id_mdio%type,
    p_id_entdad_clnte_mdio  in      nt_g_notificaciones_detalle.id_entdad_clnte_mdio%type,
    p_fcha_gnrcion          in      nt_g_notificaciones_detalle.fcha_gnrcion%type,
    p_fcha_fin_trmno        in      nt_g_notificaciones_detalle.fcha_fin_trmno%type,
    p_id_fncnrio_gnrcion    in      nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
    o_mnsje_tpo             out     varchar2,
    o_mnsje                 out     varchar2
  );

  -->15<--
  /*Procedimiento para registrar los responsables asociados a un intento de notificacion*/
  procedure prc_rg_notificacion_respnsbles(
    p_id_ntfccion_dtlle         in      nt_g_notificaciones_detalle.id_ntfccion_dtlle%type,
    p_id_acto                   in      gn_g_actos.id_acto%type,
    p_id_acto_rspnsble          in      gn_g_actos_responsable.id_acto_rspnsble%type default null,
    p_json_rspnsbles            in      clob default null,
    p_indca_notfcdo             in      varchar2 default 'N',
    p_id_ntfcion_mdio_evdncia   in      nt_g_ntfccnes_rspnsble.id_ntfcion_mdio_evdncia%type default null,
    p_cdgo_csal                 in      nt_g_ntfccnes_rspnsble.cdgo_csal%type default null,
    o_mnsje_tpo                 out     varchar2,
    o_mnsje                     out     varchar2
  ); 

  -->16<--
  /*Procedimiento para consultar el archivo asociado como evidencia*/
  procedure pr_co_archivo_evidencia(
    p_file_name     in     varchar2,
    p_file_mimetype	in out varchar2,
    p_file_blob     in out nocopy blob,
    o_mnsje_tpo        out varchar2,
    o_mnsje            out varchar2
  );

  -->17<--
  /*Procedimiento para el registro de evidencia puntual*/
  procedure prc_rg_evidencia_puntual(
    p_cdgo_clnte           in   number,
    p_id_entdad_clnte_mdio in   number,
    p_id_ntfccion_rspnsble in   number,
    p_file_evdncia         in   varchar2,
    p_id_fncnrio           in   number,
    p_xml                  in   clob,
    p_id_mdio              in   number,
    o_mnsje                out  varchar2
  );

  -->18<--
 /*Procedimiento para el registro de evidencia*/
 procedure prc_rg_evidencia(p_cdgo_clnte              in number,
                             p_id_mdio                 in nt_g_medio_entidad_evdncia.id_mdio%type,
                             p_fcha_ntfccion           in nt_g_medio_entidad_evdncia.fcha_ntfccion%type default systimestamp ,
                             p_file_blob               in nt_g_medio_entidad_evdncia.file_blob%type,
                             p_file_name               in nt_g_medio_entidad_evdncia.file_name%type,
                             p_file_mimetype           in nt_g_medio_entidad_evdncia.file_mimetype%type,							 
                             o_id_ntfcion_mdio_evdncia out number,
                             o_cdgo_rspsta             out number,
                             o_mnsje_rspsta            out varchar2); 

  -->19<--
  /*Procedimiento para procesar guia de notificacion*/
  procedure prc_rg_guia_notificacion(p_cdgo_clnte     in number,
                                     p_id_fncnrio     in nt_g_notificaciones_detalle.id_fncnrio_gnrcion%type,
                                     p_id_usrio       in number,
                                     p_id_prcso_crga  in et_g_procesos_carga.id_prcso_crga%type default null,
                                     p_guias_ntffcion in varchar2 default null,
                                     o_cdgo_rspsta    out number,
                                     o_mnsje_rspsta   out varchar2);

  -->20<--
    /*Procedimiento para confirmar actualizar las guias de notificacion*/
  procedure prc_ac_guias_notificacion(p_cdgo_clnte      in number,
                                      p_collection_name in varchar2,
                                      o_cdgo_rspsta     out number,
                                      o_mnsje_rspsta    out varchar2);

/********************* Procedimiento Notificacion de Actos Automaticamente prc_rg_notfccion_gnrda_atmtca    (No es exclusivo de Actos q esten asociados al usuario del sistema )  ****************************************/

/************************************* SE AGREGA prc_rg_notfccion_gnrda_atmtca  PARA PODER GENERAR EL JOB  **************************/
procedure prc_rg_notfccion_gnrda_atmtca; 

   -- Procedimiento para registar las notificaciones de los envios por correo electronico                                       
   procedure prc_rg_notificaciones_email( p_cdgo_clnte   in number,
                                    p_id_lte       in number, 
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);
    
  procedure prc_rg_notificacion_puntual(p_cdgo_clnte          in number,
                                        p_id_acto             in number,
                                        p_id_ntfccion         in nt_g_notificaciones.id_ntfccion%type,
                                        p_json_rspnsbles      in clob,
                                        p_cdgo_rspnsble_tpo   in df_s_responsables_tipo.cdgo_rspnsble_tpo%type default null,
                                        p_cdgo_idntfccion_tpo in df_s_identificaciones_tipo.cdgo_idntfccion_tpo%type default null,
                                        p_nmro_idntfccion     in nt_g_presentacion_personal.nmro_idntfccion%type default null,
                                        p_cdgo_mncpio         in varchar2 default null,
                                        p_nmro_trjeta_prfsnal in varchar2 default null,
                                        p_prmer_nmbre         in varchar2 default null,
                                        p_sgndo_nmbre         in varchar2 default null,
                                        p_prmer_aplldo        in varchar2 default null,
                                        p_sgndo_aplldo        in varchar2 default null,
                                        p_file_evdncia        in varchar2,
                                        p_fcha_prsntccion     in timestamp default null,
                                        p_id_fncnrio          in number,
                                        p_cdgo_mdio           in varchar2,
                                        p_indcdor_envia_email in varchar2 default 'N',
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2);
                                        
                                        
procedure prc_rg_notificaciones_email_puntual(  p_cdgo_clnte   in number,
                                                p_id_acto       in number,
                                                p_id_ntfccion   in number,
                                                p_id_fncnrio    in number,
                                                --p_json_rspnsbles in clob,
                                                p_cdgo_mdio     in varchar2,
                                                o_cdgo_rspsta   out number,
                                                o_mnsje_rspsta   out  varchar2);

function fnc_vl_enviar_email (p_id_lte in number) return varchar2;

procedure prc_rg_ntfccnes_guia_error(p_id_lte       in number,
                                      p_id_lte_dtlle in number,
                                      p_mnsje_error  in varchar2,
                                      p_id_usrio     in number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);  

/*Prc para registrar los responsables del acto 
  cuando no fueron poblados al momento de generar el acto */
  
 procedure prc_ac_actos_responsables(p_cdgo_clnte in number,
                                      p_id_acto    in number,
                                      o_mnsje_tpo  out varchar2,
                                      o_mnsje      out varchar2);
									  
									  
  -->Fin prc_ac_actos_responsables<--
--Publicación de actos en la web
procedure prc_rg_pag_web(p_cdgo_clnte   in number,
                           p_pblccion     in date,
                           p_id_crtfcdo_json in number,
                           p_json_actos   in clob default null,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2);

  procedure prc_rg_certificados_json(p_cdgo_clnte         in number,
                                     p_json_actos         in clob,
                                     o_id_nt_crtfcdo_json out number,
                                     o_cdgo_rspsta        out number,
                                     o_mnsje_rspsta       out varchar2);
                                     
  procedure prc_rg_pag_web_job(p_cdgo_clnte      in number,
                               p_pblccion        in date,
                               p_id_crtfcdo_json in number,
                               p_id_usuario      in number); 
	                                      


end pkg_nt_notificacion;

/
