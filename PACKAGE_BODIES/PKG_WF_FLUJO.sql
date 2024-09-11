--------------------------------------------------------
--  DDL for Package Body PKG_WF_FLUJO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WF_FLUJO" as

    procedure prc_rg_instancias_flujo(p_id_fljo in wf_d_flujos.id_fljo%type, 
                                      p_id_usrio in sg_g_usuarios.id_usrio%type,
                                      p_id_prtcpte in sg_g_usuarios.id_usrio%type) 
        as
        --!------------------------------------------------!--
        --! PROCEDIMIENTO PARA GENERAR INSTANCIAS DE FLUJO !--
        --!------------------------------------------------!--
            v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
            v_id_fljo_trea v_wf_d_flujos_transicion.id_fljo_trea%type;
            v_mnsje	            varchar2(4000);
            v_id_prtcpte sg_g_usuarios.id_usrio%type := p_id_prtcpte ;
                                      
        begin
            --F_ID_USRIO
            begin
                
                if v_id_prtcpte is null then
                    
                    v_id_prtcpte := pkg_wf_flujo.fnc_co_instancias_prtcpnte(p_id_fljo => p_id_fljo);
                    
                    if v_id_prtcpte = 0 then
                        rollback;
                        v_mnsje := 'No se encontro participante para este flujo';
                        apex_error.add_error  ( p_message          => v_mnsje,
                                                p_display_location => apex_error.c_inline_in_notification );
                        return;
                    end if;
                end if;
                
                insert into wf_g_instancias_flujo (id_fljo       , fcha_incio, fcha_fin_plnda, 
                                                   fcha_fin_optma, id_usrio  , estdo_instncia) 
                                           values (p_id_fljo     , sysdate   , sysdate       , 
                                                   sysdate       , p_id_usrio, 'INICIADA'    )
                        returning id_instncia_fljo into v_id_instncia_fljo;
                
                select distinct id_fljo_trea
                  into v_id_fljo_trea
                  from v_wf_d_flujos_transicion
                 where id_fljo = p_id_fljo 
                   and indcdor_incio = 'S';
                
                insert into wf_g_instancias_transicion (id_instncia_fljo  , id_fljo_trea_orgen, fcha_incio   ,
                                                        fcha_fin_plnda    , fcha_fin_optma    , fcha_fin_real, 
                                                        id_usrio          , id_estdo_trnscion) 
                                                values (v_id_instncia_fljo, v_id_fljo_trea    , sysdate      , 
                                                        sysdate           , sysdate           , sysdate      , 
                                                        v_id_prtcpte      , 1);
                        
            exception when others then
                      rollback;
                      v_mnsje := 'Error al crear la instancia del flujo';
                      apex_error.add_error  ( p_message          => v_mnsje,
					                          p_display_location => apex_error.c_inline_in_notification );
                      raise_application_error( -20001 , sqlerrm || p_id_usrio ); 
            end;

    end prc_rg_instancias_flujo;
    
    function fnc_co_instancias_prtcpnte(p_id_fljo in wf_d_flujos.id_fljo%type )
    return number is
    --!----------------------------------------------------------------!--
    --! FUNCION PARA VALIDAR SI EL USUARIO ES PARTICIPANTE DE LA TAREA !--
    --!----------------------------------------------------------------!--
        v_id_prtcpnte number;
        
    begin
    
        begin
            select distinct first_value( c.id_usrio ) over (order by a.id_fljo desc )
              into v_id_prtcpnte
              from v_wf_d_flujos_tarea_prtcpnte a
              join v_wf_d_flujos_transicion b
                on b.id_fljo = a.id_fljo
              join (select c.id_prfil, 
                           a.id_usrio
                      from v_sg_g_usuarios a
                      join sg_g_perfiles_usuario b
                        on b.id_usrio = a.id_usrio
                      join sg_g_perfiles c
                        on c.id_prfil  = b.id_prfil ) c
                on decode(a.tpo_prtcpnte , 'USUARIO', c.id_usrio,'PERFIL',c.id_prfil) = a.id_prtcpte
             where b.indcdor_incio = 'S'
               and a.id_fljo = p_id_fljo;
 
        exception when no_data_found then
            v_id_prtcpnte := 0;
        end;
        
        return v_id_prtcpnte;
        
    end fnc_co_instancias_prtcpnte;
    
end pkg_wf_flujo;

/
