--------------------------------------------------------
--  DDL for Package PKG_WF_FUNCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WF_FUNCIONES" as

    /*Valida la tarea Pre-liquidar del Flujo de Liquidacion*/
    function fnc_vl_tarea_preliquidar( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    return varchar2;

    /*Valida la tarea Criticas Pre-Liquidaci?n del Flujo de Liquidacion*/
    function fnc_vl_tarea_liquidar( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    return varchar2;

    function fnc_vl_acto(p_id_acto in gn_g_actos.id_acto%type)
    return varchar2;

    function fnc_vl_acto( p_id_instncia_fljo in number,
                          p_id_fljo_trea     in number )
    return varchar2;

    function fnc_vl_acto_requerido_ntfcdo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                          p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
    return varchar2;

    function fnc_vl_mdda_ctlar_en_prc_jrdco( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

    /*Valida las instancias generadas de un flujo esten terminadas*/
    function fnc_vl_flujo_generado(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

    /*<----------------------------------Funciones prescripcion------------------------------------------->*/
    -- /*Funcion de prescripciones que valida si han sido agregadas las vigencias de todos los sujeto-impuesto*/
    function fnc_vl_prsc_incio      (p_cdgo_clnte                in number,
                                     p_id_instncia_fljo          in number)
    return varchar2;

    -- /*Funcion de prescripciones que valida si tiene una respuesta, ejemplo: Condedida Totalmente*/
    function fnc_vl_prsc_atrzcion(p_cdgo_clnte                in number,
                                  p_id_prscrpcion       in number)
    return varchar2;

    /*Funci?n de prescripciones que valida aprobaci?n de la respuesta y de los documentos que est?n generados*/
    function fnc_vl_prescripcion_aprobacion(p_cdgo_clnte        in number,
                                            p_id_prscrpcion   in number)
    return varchar2;

    /*Funci?n de prescripciones que valida que todos los actos obligatorios por
  etapa existan en la tabla de documentos*/
    function fnc_vl_prescripcns_vlda_dcmnts (p_id_instncia_fljo in  number,
                       p_id_fljo_trea   in  number)
    return varchar2;

    /*Funci?n de prescripciones que valida que todos los documentos
  est?n confirmados en la tabla de actos*/
    function fnc_vl_prescripcns_dcmnts_acts (p_id_instncia_fljo in  number,
                                             p_id_fljo_trea     in  number
                                             )
    return varchar2;

    /*Funci?n de prescripciones que valida que todos los documentos de una etapa especifica
  est?n confirmados en la tabla de actos*/
    function fnc_vl_prescripcn_dcmn_etp_act (p_cdgo_clnte   in  number,
                       p_id_prscrpcion  in  number,
                       p_id_fljo_trea   in  number)
    return varchar2;

    /*Funci?n de prescripciones que valida que todos los documentos de la prescripci?n est?n notificados*/
    function fnc_vl_prescripcns_acts_ntfcds(p_id_instncia_fljo  in number)
    return varchar2;

    /*Funci?n de prescripciones que valida que todos los documentos
  de una etapa especifica de la prescripci?n est?n notificados*/
    function fnc_vl_prscrpcns_act_etp_ntfcd(p_cdgo_clnte        in number,
                      p_id_prscrpcion   in number,
                      p_id_fljo_trea    in number)
    return varchar2;

    /*Funci?n de prescripciones que valida si la respuesta es concedida totalmente (CT) o concedida parcialmente (CP)*/
    function fnc_vl_prescrpcns_rspsta_pstva(p_id_instncia_fljo       in number)
    return varchar2;

    /*Funci?n de prescripciones que valida si la respuesta es rechazada (RT)*/
    function fnc_vl_prescrpcns_rspsta_ngtva(p_id_instncia_fljo       in number)
    return varchar2;

    -- /*Funcion de prescripciones que valida si la prescripcion finaliza desde la respuesta concedida totalmente (CT) o concedida parcialmente (CP)*/
    -- function fnc_vl_prsc_fnlzcion(p_cdgo_clnte                in number
                                 -- ,p_id_instncia_fljo          in number)
    -- return varchar2;

    -- /*Funcion de prescripciones que valida si la respuesta es rechazada totalmente (RT)*/
    -- function fnc_vl_prsc_fnlzcion_rt(p_cdgo_clnte                in number
                                    -- ,p_id_instncia_fljo          in number)
    -- return varchar2;

    -- /*Funcion de prescripciones que valida si todos los documentos fueron autorizados*/
    -- function fnc_vl_prsc_autr       (p_cdgo_clnte                in number
                                    -- ,p_id_prscrpcion             in number)
    -- return varchar2;

    /*Funci?n que valida que el manejador de los flujos hijos se ejecut? con ?xito*/
    function fnc_vl_manejador_flujo(p_id_instncia_fljo in number,
                                p_id_fljo_trea     in number)
    return varchar2;
    
    /*Funcion de prescripciones que valida la respuesta en la etapa de autorizacion*/
    function fnc_vl_prsc_rspsta_rchzda(p_cdgo_clnte          in number,
                                p_id_prscrpcion       in number)
    return varchar2;

    /*<------------------------------Fin Funciones prescripcion------------------------------------------->*/

    /*Valida si existe una solicitud asociada al flujo*/
    function fnc_vl_solicitud_pqr(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;


    function fnc_vl_instancia_ajuste( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                      p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
  return varchar2;

  function fnc_vl_instncia_ajste_aplcdo( p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                           p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type )
  return varchar2;

  /*<----------------------------------Funciones Acuerdos de Pago---------------------------------->*/

    function fnc_vl_instancia_acuerdo_slc (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

    function fnc_vl_instancia_acuerdo_apr(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

    function fnc_vl_estado_acuerdo_slctdo (p_cdgo_clnte     number,
                                           p_id_cnvnio      number)return varchar2;

    function fnc_vl_estado_acuerdo_aprobado (p_cdgo_clnte       number,
                                             p_id_cnvnio        number)return varchar2;

    function fnc_vl_estado_acuerdo_rchzdo (p_cdgo_clnte       number,
                                           p_id_cnvnio        number)return varchar2;

    function fnc_vl_estado_acuerdo_aplicado (p_cdgo_clnte       number,
                                             p_id_cnvnio        number)return varchar2;

    function fnc_vl_sl_rvrsn_acrdo_rgstrdo (p_id_instncia_fljo    number) return varchar2;

    function fnc_vl_mdfccion_acrdo_pgo_aprd(p_id_cnvnio_mdfccion    number)return varchar2;

    function fnc_vl_acuerdo_pagado(p_cdgo_clnte           number,
                                   p_id_instncia_fljo       number) return varchar2;

    function fnc_vl_acuerdo_exista( p_cdgo_clnte           number
                                   ,p_id_impsto            number
                                   ,p_id_impsto_sbmpsto    number
                                   ,p_id_sjto_impsto       number
                                   ) return varchar2;
    /*<--------------------------------Fin Funciones Acuerdos de Pago-------------------------------->*/

    /*<----------------------------------Funciones Gestion Juridica---------------------------------->*/

    /*Valida si hay documentos pendientes por generar*/
    /*
    function fnc_co_rcrsos_dcmntos_pndentes(p_id_rcrso_etpa in  gj_g_recursos_etapa.id_rcrso_etpa%type)
    return varchar2;

    --Valida si hay todos los documentos que se generaron en una etapa estan notificados
    function fnc_co_actos_notificados_rcrso(p_id_rcrso in  gj_g_recursos_etapa.id_rcrso%type)
    return varchar2;

    function fnc_co_actos_notificados_etpa(p_id_rcrso_etpa in  gj_g_recursos_etapa.id_rcrso_etpa%type)
    return varchar2;

    function fnc_co_dcmntos_actualizados(p_id_slctud in number)
    return varchar2;
    */
    --funcion que valida si es acto de citacion esta notificado para transitar a la siguiente tarea
     function fnc_vl_gj_vlda_ac_ctcion_ntfcd(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
     return varchar2;

     --Funcion que valida que los documentos inadmitidos esten actualizados para poder avanzar a la siguiente tarea
    function fnc_vl_gj_vlda_dcmntos_actlzds(p_id_slctud        in number
                                      , p_id_instncia_fljo in number)
  return varchar2;

    /*<--------------------------------Fin Funciones Gestion Juridica-------------------------------->*/

  /*<----------------------------------Funciones Tecnologia de la Informacion---------------------------------->*/

  /* Condicion para pasar a etapa de Desarrollo despues de generar el Paquete Funcional */
  function fnc_vl_gn_pf_desarrollo (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /* Condicion de Aprobacion para pasar  el Paquete Funcional de etapa de Desarrollo a etapa de Calidad */
    function fnc_vl_ap_pf_desarrollo (p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

    /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
    function fnc_vl_rc_pf_desarrollo(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /*  Condicion de Aprobacion para pasar el Paquete Funcional de etapa de Calidad a etapa de Prueba */
  function fnc_vl_ap_pf_calidad(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
  function fnc_vl_rc_pf_calidad(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /*  Condicion de Aprobacion para pasar el Paquete Funcional de etapa de Calidad a etapa de Prueba */
  function fnc_vl_ap_pf_prueba(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /* Condicion de Rechazo para el Paquete Funcional de Etapa de Desarrollo a etapa de Paquete Funcional */
  function fnc_vl_rc_pf_prueba(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;

  /* Condicion de Modificacion del Paquete Funcional para Etapa de Paquete Funcional para volver a  etapa de Paquete Prueba */
  function fnc_vl_md_pf_prueba(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type)
    return varchar2;
   /*<---------------------------------- Fin Funciones Tecnologia de la Informacion---------------------------------->*/
 
     /*<---------------------------------- Inicio Funciones de Gestion Juridica---------------------------------->*/
     /*Funcion de gestion juridica que valida si el recurso asociado a un flujo tiene vigencias seleccionadas*/
     function fnc_vl_gj_recurso_vgncia (p_id_instncia_fljo         in  number)
     return varchar2;
     /*Funcion de gestion juridica que valida si el flujo ha sido instanciado en las tablas*/
     function fnc_vl_gj_recurso (p_id_instncia_fljo         in  number)
     return varchar2;

     /*Funcion de gestion juridica que valida el estado air en caso de ser necesario*/
     function fnc_vl_gj_valida_air (p_id_instncia_fljo      in  number)
     return varchar2;

     /*Funcion de gestion juridica que valida si hay actos obligatorios pendientes por generar*/
     function fnc_vl_gj_valida_actos_tarea (p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
     return varchar2;
     /*Funcion de gestion juridica que valida si hay documentos obligatorios pendientes por generar*/
     function fnc_vl_gj_valida_dcmntos_tarea(p_id_instncia_fljo  in  number,
                                             p_id_fljo_trea      in  number)
     return varchar2;
     /*Funcion que valida si los actos generados en una tarea ya se encuentran notificados*/
     function fnc_vl_gj_valida_actos_ntfcdos(p_id_instncia_fljo  in  number,
                                             p_id_fljo_trea      in  number)
     return varchar2;
     /*Funcion que valida si todas las acciones son exitosas*/
     function fnc_vl_gj_acciones_exitosa(p_id_instncia_fljo  in  number,
                                         p_id_fljo_trea      in  number)
     return varchar2;
     

     --Funcion que valida que los documentos inadmitidos esten actualizados para poder avanzar a la siguiente tarea
                                
     function fnc_vl_acto_recurso(p_cdgo_clnte          in  number,
                                 p_id_acto        	   in  number) return varchar2;
     /*<---------------------------------- Finc Funciones de Gestion Juridica---------------------------------->*/

    /*Funcion que valida si un proceso juridico se encuentra acumulado*/
    function fnc_vl_proceso_juridico_acmldo(p_id_instncia_fljo  in  number,
                                            p_id_fljo_trea      in  number)
    return varchar2;
    
    /*Funcion que valida si un proceso juridico tiene Saldo*/
     function fnc_vl_saldo_cartera_juridico (p_id_instncia_fljo  in  number,
                                             p_id_fljo_trea      in  number)
    return varchar2;

     /*<---------------------------------- Inicio Funciones de Saldo a Favor--------------------------------->*/

     function fnc_co_dcmnto_gnrado_sldo_fvor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2;

     function fnc_vl_dcmnto_sldo_fvor_cnfrdo(p_id_instncia_fljo    in gf_g_saldos_favor_solicitud.id_instncia_fljo%type)
     return varchar2;

     function fnc_vl_saldo_favor_aplicacion(p_id_instncia_fljo    in gf_g_saldos_favor_solicitud.id_instncia_fljo%type,
                                            p_id_fljo_trea        in wf_d_flujos_tarea.id_fljo_trea%type)
     return varchar2;

     function fnc_vl_saldo_favor_devolucion(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2;

     function fnc_vl_saldo_favor_rcncmiento(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
     return varchar2;

     function fnc_co_saldo_favor_solicitud(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type)
      return varchar2;

     function fnc_vl_revision_saldo_favor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type) return varchar2;

     function fnc_vl_aprobacion_saldo_favor(p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type) return varchar2;
     
     --ALC
     function fnc_vl_notificacion_acto_cobro(p_cdgo_clnte         in number,
                                        p_id_fljo_trea       in number,
                                        p_id_instncia_fljo   in number) return varchar2;


      /*<---------------------------------- Finc Funciones de de Saldo a Favor---------------------------------->*/

      /*<---------------------------------- Inicio Funciones de cautelar--------------------------------->*/

    function fnc_vl_saldo_cartera_cautelar (  p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number,
                                            p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_saldo_cartera_cautelar_desem (  p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number,
                                            p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_tipo_embargo_prmte_scstre ( p_id_instncia_fljo in number,
                                                p_id_fljo_trea     in number,
                                                p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_acto_embargo (  p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number,
                                    p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_acto_desembargo(p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number,
                                    p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_entdds_embrgo_dsmbrgdas ( p_id_instncia_fljo in number,
                                              p_id_fljo_trea     in number,
                                              p_cdgo_clnte       in number)  return varchar2;

     function fnc_vl_permite_embargo ( p_id_instncia_fljo in number,
                                      p_id_fljo_trea     in number,
                                      p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_permite_desembargo( p_id_instncia_fljo in number,
                                        p_id_fljo_trea     in number,
                                        p_cdgo_clnte       in number)  return varchar2;

    function fnc_vl_estado_dcmnto_scstre (p_id_instncia_fljo in number,
                                          p_id_fljo_trea     in number,
                                          p_cdgo_clnte       in number) return varchar2;

    /*<---------------------------------- Finc Funciones de cautelar---------------------------------->*/

    /*<-------------------------------------Funciones T?tulo Judicial--------------------------------->*/

    /*Funcion de t?tulos judiciales que valida la devoluci?n del t?tulo*/
    function fnc_cl_anlisis_devolucion_ttlo(p_cdgo_clnte        in number,
                                            p_id_instncia_fljo  in number) return varchar2;

    /*<---------------------------------- Fin Funciones T?tulo Judicial ------------------------------>*/


    /*<-------------------------------------Funciones T?tulo Ejecutivo--------------------------------->*/

    function fnc_vl_revision_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2;

    function fnc_vl_aplicacion_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2;

    function fnc_vl_concepto_titulo_ejctvo(p_id_ttlo_ejctvo in number) return varchar2;


     /*<---------------------------------- Fin Funciones T?tulo Ejecutivo ------------------------------>*/

    /*<------------------------------------- Funciones Fiscalizacion ----------------------------------->*/
       
       function fnc_vl_termino_acto(p_cdgo_clnte        in  number,
                                    p_id_fljo_trea      in  number,
                                    p_id_instncia_fljo  in  number) return varchar2;
       
       function fnc_vl_declaracion(p_cdgo_clnte         in  number,
                                   p_id_instncia_fljo   in  number) return varchar2;
                                   
       function fnc_vl_declaracion_correcion(p_cdgo_clnte         in  number,
                                             p_id_instncia_fljo   in  number) return varchar2;
                                   
       function fnc_vl_sancion(p_cdgo_clnte         in number,
                               p_id_instncia_fljo   in  number) return varchar2;
                               
       function fnc_vl_sancion_correcion(p_cdgo_clnte         in number,
                                         p_id_instncia_fljo   in  number) return varchar2;
                               
       function fnc_vl_acto_tarea(p_id_instncia_fljo    in number)return varchar2;
       
       function fnc_vl_acto_fisca(p_cdgo_clnte        in number,
                                  p_id_fljo_trea      in number,
                                  p_id_instncia_fljo  in number)return varchar2;
       
       function fnc_vl_expediente_padre(p_id_instncia_fljo in number)return varchar2;       
       
       function fnc_vl_recurso(p_cdgo_clnte         in  number,
                               p_id_instncia_fljo   in  number,
                               p_id_fljo_trea       in  number) return varchar2;
        
        function fnc_vl_requerimiento_ordinario(p_cdgo_clnte        in  number,
                                                p_id_instncia_fljo  in  number,
                                                p_id_fljo_trea      in  number) return varchar2;
                                                
        function fnc_vl_finaliza_expediente(p_fnlzcion  in  varchar2) return varchar2;
        
        function fnc_vl_pago_pliego_cargo(p_id_instncia_fljo  in  number) return varchar2;
        
        function fnc_vl_impuesto_acto(p_id_instncia_fljo  in  number) return varchar2;
        
        function fnc_vl_aplicacion_liquidacion(p_id_instncia_fljo  in  number) return varchar2;
        
        function fnc_vl_dfncion_emplzmnto_crrcn(p_cdgo_clnte in  number) return varchar2;
        
        function fnc_vl_dfncion_lqudcn_ofcl_afr(p_cdgo_clnte in  number) return varchar2;
        
        function fnc_vl_trmno_acto_plgo_crgo(p_cdgo_clnte                in  number,
                                             p_id_fljo_trea              in  number,
                                             p_id_instncia_fljo          in  number) return varchar2;
        function fnc_vl_inscripcion(p_cdgo_clnte          in  number,
                                    p_id_instncia_fljo    in  number)return varchar2;     
                                    
          /*
    Funcion agregada para validar si existe una liquidacion pagada en rentas.
    01/08/22
    @LUIS ARIZA    
  */                                    
        function fnc_vl_liquidacion_renta(  p_cdgo_clnte          in  number,
                                            p_id_instncia_fljo    in  number) return varchar2  ;                                          
                                    
    /*<------------------------------------- Fin Funciones Fiscalizacion -------------------------------->*/
     /*<-------------------------------------- Funciones Vehiculos -------------------------------->*/
      /*Funcion indicador de novedades con reliquidacion */
       function fnc_vl_nvdd_rlqudcion(p_cdgo_nvdad_tpo in varchar2) return varchar2;
        /*Funcion indicador de novedades de trasicion */
      function fnc_vl_nvdd_trasicion(p_cdgo_valdccn varchar2) return varchar2; 
      /*<-------------------------------------- Fin Funciones Vehiculos -------------------------------->*/
    
      /*<----------------------------------------- Funciones Seguridad -------------------------------->*/
    /*Funcion de solicitud de relacion usuario sujeto-impuesto*/
    function fnc_vl_usrio_sjto_impsto(p_id_instncia_fljo       in number)
    return varchar2;
    /*<--------------------------------------Fin Funciones Seguridad -------------------------------->*/

    function fnc_vl_quejas_reclamo_rspsta(p_id_instncia_fljo  in  number) return varchar2;

    function fnc_wf_error( p_value in boolean
                         , p_mensaje in varchar2 )
    return varchar2;

   function fnc_vl_exncion_rnta( p_cdgo_clnte         in number,
                                 p_id_instncia_fljo   in number ) return varchar2;

   function fnc_vl_crtfccion_rnta_aprbda( p_cdgo_clnte          in number,
                                          p_id_rnta             in number,
                                          p_id_rnta_dcmnto      in number,
                                          p_id_instncia_fljo    in number ) return varchar2;
                                          
   function fnc_vl_convenio_exista(p_cdgo_clnte number
                                  --,p_id_impsto            number
                                  --,p_id_impsto_sbmpsto    number
                                 ,
                                  p_id_sjto_impsto number) return varchar2;
                                  
  function fnc_vl_convenio_exista_estrato(p_cdgo_clnte number
                                  --,p_id_impsto            number
                                  --,p_id_impsto_sbmpsto    number
                                 ,
                                  p_id_sjto_impsto number) return varchar2;                                       

    function fnc_vl_expediente_analisis_fisca(	p_cdgo_clnte          in  number,
											p_id_instncia_fljo    in  number default null) return varchar2 ;

    function fnc_vl_expediente_analisis(p_cdgo_clnte          in 	number,
                                        p_id_expdnte_anlsis   in 	number  default null,
                                        p_id_instncia_fljo    in	number) return varchar2 ;
    
    function fnc_vl_expediente_analisis_rspta(	p_cdgo_clnte		in 	number,
                                                p_id_instncia_fljo	in	number) return varchar2;
    
    function fnc_vl_acto_embrg_rmnnte(p_cdgo_clnte       in number,
                                    p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number)
    return varchar2;

  function fnc_vl_acto_dsmbrg_rmnnte(p_id_instncia_fljo in number,
                                     p_id_fljo_trea     in number)
    return varchar2;

function fnc_vl_rgstro_embrg_rmnnte(p_cdgo_clnte in number,
                                    p_id_instncia_fljo in number,
                                    p_idntfccion       in varchar2)
  return varchar2;

  function fnc_vl_rgstro_dsmbrg_rmnnte(p_id_instncia_fljo in number,
                                       p_idntfccion       in varchar2)
    return varchar2;

  /**Funcion que valida si remenente tiene asociado un embargo**/
  function fnc_vl_rmnte_ascdo_embrgo(p_id_instncia_fljo in number)
    return varchar2;

  /**Funcion que valida si un remanente asociado a un embargo tiene una demanda por alimento**/
  function fnc_vl_rmnt_ascd_embrg_dmnda(p_id_instncia_fljo in number)
    return varchar2;

  /**Funcion que valida si el registro a desembargar tiene asociado un remanete activo**/
  function fnc_vl_embrgo_ascdo_rmnte(p_id_instncia_fljo in number)
    return varchar2;
    
    function fnc_vl_ttlo_ascdo_instncia(p_id_instncia_fljo in number)
    return varchar2;

  /*Funcion de titulos judiciales que valida la consignación del titulo*/
  function fnc_vl_consignacion_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  /*Funcion de titulos judiciales que valida la devolucion del titulo*/
  function fnc_vl_devolucion_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  /*Funcion de titulos judiciales que valida el fraccionamiento del titulo*/
  function fnc_vl_frccnmnto_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  /*Funcion de titulos judiciales que valida la consignación y devolución del titulo*/
  function fnc_vl_cnsgncn_dvlcn_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  function fnc_vl_rgstro_frccn_ttlo(p_id_instncia_fljo in number)
    return varchar2;
    
  function fnc_vl_cnsgnar_dvlver(p_id_instncia_fljo in number)
  return varchar2;  

  function fnc_vl_rgstro_vgncia_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  function fnc_vl_acto_tarea_ttlo(p_id_instncia_fljo in number,
                                  p_id_fljo_trea     in number)
    return varchar2;
    
  function fnc_vl_fnlzcion_fljo_trsldo(p_id_instncia_fljo in number) return varchar2;  

  function fnc_vl_rcbo_cnsgncn_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  function fnc_vl_aplccion_rcdo_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  function fnc_vl_saldo_cartera_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  /**Funcion que valida si el embargo asociado tiene un remanente**/
  function fnc_vl_embrgo_rmnte_ascdo_ttlo(p_id_instncia_fljo in number)
    return varchar2;

  /*Funcion de titulos judiciales que valida la consignación de remanente del titulo*/
  function fnc_vl_cnsgncn_rmnnte_ttlo(p_id_instncia_fljo in number)
    return varchar2;
  function fnc_vl_cnsgncion_ttlo_vlor(p_id_instncia_fljo in number)
    return varchar2;  
    
end pkg_wf_funciones;

/
