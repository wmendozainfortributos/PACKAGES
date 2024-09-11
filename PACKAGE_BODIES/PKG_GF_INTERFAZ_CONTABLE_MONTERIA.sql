--------------------------------------------------------
--  DDL for Package Body PKG_GF_INTERFAZ_CONTABLE_MONTERIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_INTERFAZ_CONTABLE_MONTERIA" as

    procedure prc_gn_interfaz_financiera_total( p_cdgo_clnte in number,
                                                p_vgncia     in number,
                                                p_id_usrio    in number ) 
    as
        v_nl                number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_gn_interfaz_financiera_total';
        v_cdgo_rspsta       number;
        v_mnsje_rspsta      varchar2(4000);
        v_error             varchar2(4000);        
        val                 number;
        v_email_from       	ma_d_envios_mdio_cnfgrcn_pr.vlor%type;
        v_correo            varchar2(1000);
        v_mensaje           varchar2(4000);
        v_id_usrio_apex     number;
        --v_html              clob; 
        v_body              clob;     
    begin

        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia prc_gn_interfaz_financiera. CLiente:' || p_cdgo_clnte || ' - Vigencia:' || p_vgncia); commit;
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia Recaudo'); commit;
        --Respuesta Exitosa
        v_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Up de Interfaz Recaudo
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Inicio prc_rg_recaudo_intrfaz_total' ,  1 );
        pkg_gf_interfaz_contable_monteria.prc_rg_recaudo_intrfaz_total(p_cdgo_clnte, p_vgncia);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Fin prc_rg_recaudo_intrfaz_total' ,  1 );
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Fin Recaudo'); commit;
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia Ajuste'); commit;

        --Up de Interfaz Ajuste
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Inicio prc_rg_ajuste_intrfaz' ,  1 );
        pkg_gf_interfaz_contable_monteria.prc_rg_ajuste_intrfaz(p_cdgo_clnte, p_vgncia);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Fin prc_rg_ajuste_intrfaz' ,  1 );
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Fin Ajuste'); commit;
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia Liquidacion'); commit;

        --Up de Interfaz Liquidacion 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Inicio prc_rg_liquidacion_intrfaz' ,  1 );
        pkg_gf_interfaz_contable_monteria.prc_rg_liquidacion_intrfaz(p_cdgo_clnte, p_vgncia);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Fin prc_rg_liquidacion_intrfaz' ,  1 );
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Fin Liquidacion'); commit;
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Fin prc_gn_interfaz_financiera'); commit;

        -- Envio notificacion de Intermedia
        begin            
            v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                               p_cdgo_dfncion_clnte        => 'USR');
            if v('APP_SESSION') is null then
                apex_session.create_session(p_app_id   => 71000,
                                            p_page_id  => 333,
                                            p_username => v_id_usrio_apex);
            end if;

            begin
                select  a.vlor into v_email_from
                from    ma_d_envios_mdio_cnfgrcn_pr a
                join    ma_d_envios_medio_cnfgrcion b on a.id_envio_mdio_cnfgrcion = b.id_envio_mdio_cnfgrcion
                where   b.cdgo_clnte = p_cdgo_clnte
                and     b.cdgo_envio_mdio = 'EML'
                and     a.prmtro = 'SMTP_USRNME' ;

                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_email_from :'||v_email_from, 1 );  

            exception
                when no_data_found then
                    v_cdgo_rspsta := 20;
                    v_mnsje_rspsta := v_nmbre_up || ' ' || v_cdgo_rspsta||'. No hay correo configurado para el envio '; 
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 ); 
                    return;
                when others then
                    v_cdgo_rspsta := 30;
                    v_mnsje_rspsta := v_nmbre_up || ' ' || v_cdgo_rspsta||'. Error al consultar correo para el envio. '||sqlerrm; 
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 ); 
                    return;
            end;

            select email
            into   v_correo
            from   v_sg_g_usuarios
            where  id_usrio = p_id_usrio;

            if v_correo is not null then
                v_mensaje := v_nmbre_up || ' ' || 'Despues de la session - ' || 'v_correo: ' || v_correo;
                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 );        

                val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
                apex_util.set_security_group_id(p_security_group_id => val);

                v_body      := 'Estimado Usuario,<br><br>El envio a la Interfaz Contable de todos los registros ha sido exitoso.<br><br>';
                apex_mail.send(  p_to        => v_correo,
                                 p_from      => v_email_from,
                                 p_subj      => 'Envio registros a la Interfaz Contable (TODOS)',
                                 p_body      => v_body,
                                 p_body_html => v_body );
                APEX_MAIL.PUSH_QUEUE;

                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'fin correo', 1 ); 
            end if;            
        end;            


        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

    end prc_gn_interfaz_financiera_total;


    procedure prc_gn_interfaz_financiera_cncldo( p_cdgo_clnte in number,
                                                 p_vgncia     in number,
                                                 p_id_usrio    in number )
    as
        v_nl                number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_gn_interfaz_financiera_cncldo';
        v_cdgo_rspsta       number;
        v_mnsje_rspsta      varchar2(4000);
        v_error             varchar2(4000);        
        val                 number;
        v_email_from       	ma_d_envios_mdio_cnfgrcn_pr.vlor%type;
        v_correo            varchar2(1000);
        v_mensaje           varchar2(4000);
        v_id_usrio_apex     number;
        --v_html              clob; 
        v_body              clob;     
    begin

        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia prc_gn_interfaz_financiera. CLiente:' || p_cdgo_clnte || ' - Vigencia:' || p_vgncia); commit;
        --insert into muerto2 (n_001, t_001, v_001) values (99, systimestamp, 'Inicia Recaudo'); commit;
        --Respuesta Exitosa
        v_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

         --Up de Interfaz Recaudo
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Inicio Recaudo total' ,  1 );
        pkg_gf_interfaz_contable_monteria.prc_rg_recaudo_intrfaz_total(p_cdgo_clnte, p_vgncia); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Fin Recaudo total' ,  1 );

        --Up de Interfaz Recaudo
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Inicio Recaudo conciliado' ,  1 );
        pkg_gf_interfaz_contable_monteria.prc_rg_recaudo_intrfaz_cncldo(p_cdgo_clnte, p_vgncia);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Fin Recaudo conciliado' ,  1 ); 


        -- Envio notificacion de Intermedia
        begin            
            v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                               p_cdgo_dfncion_clnte        => 'USR');
            if v('APP_SESSION') is null then
                apex_session.create_session(p_app_id   => 71000,
                                            p_page_id  => 333,
                                            p_username => v_id_usrio_apex);
            end if;

            begin
                select  a.vlor into v_email_from
                from    ma_d_envios_mdio_cnfgrcn_pr a
                join    ma_d_envios_medio_cnfgrcion b on a.id_envio_mdio_cnfgrcion = b.id_envio_mdio_cnfgrcion
                where   b.cdgo_clnte = p_cdgo_clnte
                and     b.cdgo_envio_mdio = 'EML'
                and     a.prmtro = 'SMTP_USRNME' ;

                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_email_from :'||v_email_from, 1 );  

            exception
                when no_data_found then
                    v_cdgo_rspsta := 20;
                    v_mnsje_rspsta := v_nmbre_up || ' ' || v_cdgo_rspsta||'. No hay correo configurado para el envio '; 
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 ); 
                    return;
                when others then
                    v_cdgo_rspsta := 30;
                    v_mnsje_rspsta := v_nmbre_up || ' ' || v_cdgo_rspsta||'. Error al consultar correo para el envio. '||sqlerrm; 
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 ); 
                    return;
            end;

            select email
            into   v_correo
            from   v_sg_g_usuarios
            where  id_usrio = p_id_usrio;

            if v_correo is not null then
                v_mensaje := v_nmbre_up || ' ' || 'Despues de la session - ' || 'v_correo: ' || v_correo;
                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mensaje, 1 );        

                val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
                apex_util.set_security_group_id(p_security_group_id => val);

                v_body      := 'Estimado Usuario,<br><br>El envio a la Interfaz Contable de los recaudos conciliados ha sido exitoso.<br><br>';
                apex_mail.send(  p_to        => v_correo,
                                 p_from      => v_email_from,
                                 p_subj      => 'Envio registros a la Interfaz Contable (CONCILIADOS)',
                                 p_body      => v_body,
                                 p_body_html => v_body );
                APEX_MAIL.PUSH_QUEUE;

                pkg_sg_log.prc_rg_log ( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'fin correo', 1 ); 
            end if;            
        end;    

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );        

    end prc_gn_interfaz_financiera_cncldo;


	procedure prc_rg_recaudo_intrfaz_total( p_cdgo_clnte  in number,
                                            p_vgncia      in number ) 

    is
        v_nl                        number;
        v_nmbre_up                  sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_rg_recaudo_intrfaz_total';
        v_cdgo_rspsta               number;
        v_mnsje_rspsta              varchar2(4000);
        s_vlor                      number;
        v_clsfccion                 varchar2(30);
        v_id_impsto_sbmpsto         number;
        --v_cdgo_cncpto              df_i_conceptos_cnclcion.cdgo_cncpto%type;
        --v_nmbre_cncpto             df_i_conceptos_cnclcion.nmbre_cncpto%type;
        o_cdgo_rspsta               number;
        v_error                     varchar2(2000);
        v_tpo_trnsccion             varchar2(30);
        v_idntfccion_rspnsble       si_i_sujetos_responsable.idntfccion%type;
        v_prmer_nmbre               si_i_sujetos_responsable.prmer_nmbre%type;
        v_sgndo_nmbre               si_i_sujetos_responsable.sgndo_nmbre%type;
        v_prmer_aplldo              si_i_sujetos_responsable.prmer_aplldo%type;
        v_sgndo_aplldo              si_i_sujetos_responsable.sgndo_aplldo%type;
        v_nmbre_prptrio             varchar2(4000);
        v_cdgo_idntfccion_tpo       si_i_sujetos_responsable.cdgo_idntfccion_tpo%type;
        v_dscrpcion_idntfccion_tpo  df_s_identificaciones_tipo.dscrpcion_idntfccion_tpo%type;
        v_vlor_cncpto               number;
        v_vlor_prcntaje             number;
    begin
        --Respuesta Exitosa
        v_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || p_cdgo_clnte || ' - ' ||p_vgncia;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Cursor de Recaudos
        for c_rcdos in (select distinct a.id_rcdo,
                                      a.idntfccion_sjto,
                                      a.cdgo_rcdo_orgn_tpo,
                                      a.nmro_dcmnto,
                                      a.fcha_apliccion, --a.fcha_rcdo,
                                      d.cdgo_bnco,
                                      d.nmbre_bnco,
                                      d.nmro_cnta,
                                      decode(g.cdgo_impsto,
                                             'IPU',
                                             'P',
                                             'REN',
                                             'R',
                                             'ICA',
                                             'I',
                                             'VHL',
                                             'C',
                                             'VAL',
                                             'V',
                                             'PLU',
                                             'L',
                                             'O') as cdgo_impsto,
                                      --extract(year from a.fcha_rcdo) as ano,
                                      extract(year from a.fcha_apliccion) as ano,
                                      --to_char(a.fcha_rcdo, 'MM') as mes,
                                      to_char(a.fcha_apliccion, 'MM') as mes,
                                      a.id_sldo_fvor,
                                      a.vlor,
                                      g.nmbre_impsto,
                                      g.cdgo_impsto cdgo_impsto_2,
                                      h.id_impsto,
                                      a.id_sjto_impsto,
                                      h.cdgo_sjto_tpo
                        from v_re_g_recaudos a
                        join v_re_g_recaudos_control d
                          on a.id_rcdo_cntrol = d.id_rcdo_cntrol
                        join v_si_i_sujetos_impuesto h
                          on a.id_sjto_impsto = h.id_sjto_impsto
                        join df_c_impuestos g
                          on h.id_impsto = g.id_impsto
                       where d.cdgo_clnte = p_cdgo_clnte
                     --  and a.id_rcdo  IN (1725852) 
                            /* and trunc(a.fcha_rcdo) between
                              to_date('01/04/2022', 'dd/mm/yyyy') and
                            to_date('30/04/2022', 'dd/mm/yyyy')*/
                         --and extract(year from a.fcha_rcdo) = p_vgncia 
                         --and extract(year from a.fcha_apliccion) = p_vgncia 
                       --  and extract(year from a.fcha_apliccion) between (p_vgncia - 1) and p_vgncia 
                         and a.cdgo_rcdo_estdo = 'AP'
                         and a.vlor > 0
                         and a.indcdor_intrfaz = 'N' 
                          and a.id_rcdo in ( 2035521 )
                       order by --a.fcha_rcdo,
                                a.fcha_apliccion,
                                a.id_rcdo ) 
        loop

            --pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'FOR TOTAL: '||c_rcdos.id_rcdo ,  1 );

            --Inicializa el Acumulador en 0 de Suma Cuadradas           
            s_vlor        := 0;
            o_cdgo_rspsta := 0;

            -- Obtener la Clasificacion
            case
              when c_rcdos.cdgo_impsto_2 = 'IPU' then
                -- Si es un predio
                if (substr(c_rcdos.idntfccion_sjto, 1, 2) = '01') then
                  v_clsfccion := 'URBANO';
                else
                  v_clsfccion := 'RURAL';
                end if;

              when c_rcdos.cdgo_impsto_2 = 'ICA' then
                -- Si es un establecimiento
                begin
                  select upper(d.nmbre_dclrcns_esqma_trfa_tpo)
                    into v_clsfccion
                    from si_i_personas a
                    join si_i_sujetos_impuesto b
                      on b.id_sjto_impsto = a.id_sjto_impsto
                    join gi_d_dclrcns_esqma_trfa c
                      on c.id_dclrcns_esqma_trfa = a.id_actvdad_ecnmca
                    join gi_d_dclrcns_esqma_trfa_tpo d
                      on d.id_dclrcns_esqma_trfa_tpo = c.id_dclrcns_esqma_trfa_tpo
                   where a.id_sjto_impsto = c_rcdos.id_sjto_impsto
                     and b.id_impsto = c_rcdos.id_impsto;

                  if v_clsfccion not in ('COMERCIAL', 'SERVICIOS', 'INDUSTRIAL') then
                    v_clsfccion := 'SERVICIOS';
                  end if;

                exception
                  when others then
                    v_clsfccion := 'SERVICIOS';
                end;

              when c_rcdos.cdgo_impsto_2 = 'ARD' then
                v_clsfccion := 'PLAZA DE MERCADO';

              when c_rcdos.cdgo_impsto_2 = 'REN' then
                -- se busca el id_impsto_sbmpsto
                select min(id_impsto_sbmpsto)
                  into v_id_impsto_sbmpsto
                  from gi_g_rentas
                 where id_sjto_impsto = c_rcdos.id_sjto_impsto
                   and id_dcmnto in
                       (select id_dcmnto
                          from re_g_documentos
                         where nmro_dcmnto = c_rcdos.nmro_dcmnto);

                if (v_id_impsto_sbmpsto = 2367842) then
                  -- ESPECTACULOS PUBLICOS AL DEPORTE
                  v_clsfccion := 'ESPECTACULO DEPORTE';
                elsif (v_id_impsto_sbmpsto = 23001148) then
                  -- DEGUELLO DE GANADO MENOR
                  v_clsfccion := 'DEGUELLO MENOR';
                elsif (v_id_impsto_sbmpsto = 23001147) then
                  -- PUBLICIDAD EXTERIOR VISUAL
                  v_clsfccion := 'PUBLICIDAD VISUAL';
                elsif (v_id_impsto_sbmpsto = 23001150) then
                  -- ESPECTACULOS PUBLICOS
                  v_clsfccion := 'ESPECTACULO PUBLICO';
                elsif (v_id_impsto_sbmpsto = 23001157) then
                  -- DELINEACION URBANA
                  v_clsfccion := 'DELINEACION';
                elsif (v_id_impsto_sbmpsto = 23001142) then
                  -- Estampilla Adulto Mayor
                  v_clsfccion := 'ADULTO MAYOR';
                elsif (v_id_impsto_sbmpsto = 23001141) then
                  -- Estampilla Pro-Cultura 
                  v_clsfccion := 'PRO CULTURA';
                else
                  v_clsfccion := 'SIN CLASIFICACION';
                end if;
              else
                v_clsfccion := 'SIN CLASIFICACION';
            end case;

            -- Buscar la informacion del responsable dependiendo del cdgo_sjto_tpo
            if (c_rcdos.cdgo_sjto_tpo = 'E') then
                begin
                    select c_rcdos.idntfccion_sjto,
                           null,
                           null,
                           null,
                           e.nmbre_rzon_scial,
                           null,
                           null
                      into v_idntfccion_rspnsble,
                           v_prmer_nmbre,
                           v_sgndo_nmbre,
                           v_prmer_aplldo,
                           v_nmbre_prptrio,
                           v_cdgo_idntfccion_tpo,
                           v_dscrpcion_idntfccion_tpo
                      from si_i_personas e
                     where e.id_sjto_impsto = c_rcdos.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        v_error       := 'Tipo: RE' || ' Id_Rcdo: ' || c_rcdos.id_rcdo ||
                                       ' - Error en persona- : ' ||
                                       c_rcdos.id_sjto_impsto || ' . Error: ' ||
                                       sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                        values
                            (systimestamp, v_error);
                        commit;
                        continue;
                end;
            else
                begin
                    select nvl(substr(e.idntfccion, 1, instr(e.idntfccion, '-') - 1),
                               e.idntfccion),
                           e.prmer_nmbre,
                           e.sgndo_nmbre,
                           e.prmer_aplldo,
                           e.sgndo_aplldo,
                           e.prmer_nmbre || ' ' || e.sgndo_nmbre || ' ' ||
                           replace(e.prmer_aplldo, '.') || ' ' || e.sgndo_aplldo,
                           e.cdgo_idntfccion_tpo,
                           f.dscrpcion_idntfccion_tpo
                      into v_idntfccion_rspnsble,
                           v_prmer_nmbre,
                           v_sgndo_nmbre,
                           v_prmer_aplldo,
                           v_sgndo_aplldo,
                           v_nmbre_prptrio,
                           v_cdgo_idntfccion_tpo,
                           v_dscrpcion_idntfccion_tpo
                      from si_i_sujetos_responsable e
                      join df_s_identificaciones_tipo f
                        on e.cdgo_idntfccion_tpo = f.cdgo_idntfccion_tpo
                     where e.id_sjto_impsto = c_rcdos.id_sjto_impsto
                       and e.prncpal_s_n = 'S'
                       and rownum = 1;
                exception
                    when others then
                        v_error := 'Tipo: RE' || ' Id_Rcdo: ' || c_rcdos.id_rcdo ||
                                 ' - Error en reponsable principal- : ' ||
                                 c_rcdos.id_sjto_impsto || ' . Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            end if;

            --Cursor Conceptos Pagados
            for c_cncptos in (select decode(a.vgncia,
                                            c_rcdos.ano,
                                            'VIGENCIA_ACTUAL',
                                            'VIGENCIA_ANTERIOR') || '_' ||
                                     decode(a.cdgo_mvmnto_tpo,
                                            'PC',
                                            'CAPITAL',
                                            'PI',
                                            'INTERES') as tpo_trnsccion,
                                     b.cdgo_cncpto,
                                     --a.id_cncpto_csdo,
                                     a.id_cncpto id_cncpto_csdo,
                                     sum(a.vlor) as vlor,
                                     b.dscrpcion,
                                     decode(a.vgncia, c_rcdos.ano, 'S', 'N') as indcdor_vgncia_actual,
                                     a.vgncia
                                from (select a.id_orgen,
                                             a.vgncia,
                                             --a.id_cncpto_csdo,
                                             a.id_cncpto,
                                             sum(a.vlor_hber) as vlor,
                                             a.cdgo_mvmnto_tpo
                                        from gf_g_movimientos_detalle a
                                       where cdgo_mvmnto_orgn = 'RE'
                                         and a.id_orgen = c_rcdos.id_rcdo
                                         and a.vlor_hber > 0
                                         and a.cdgo_mvmnto_tpo in ('PC', 'PI')
                                       group by a.id_orgen,
                                                a.vgncia,
                                                -- a.id_cncpto_csdo,
                                                a.id_cncpto,
                                                a.cdgo_mvmnto_tpo) a
                                join df_i_conceptos b
                              -- on a.id_cncpto_csdo = b.id_cncpto
                                  on a.id_cncpto = b.id_cncpto
                               group by decode(a.vgncia,
                                               c_rcdos.ano,
                                               'VIGENCIA_ACTUAL',
                                               'VIGENCIA_ANTERIOR') || '_' ||
                                        decode(a.cdgo_mvmnto_tpo,
                                               'PC',
                                               'CAPITAL',
                                               'PI',
                                               'INTERES'),
                                        b.cdgo_cncpto,
                                        --a.id_cncpto_csdo,
                                        a.id_cncpto,
                                        b.dscrpcion,
                                        decode(a.vgncia, c_rcdos.ano, 'S', 'N'),
                                        a.vgncia) 
            loop

                -- Si es ICA, la vigencia actual es la vigencia del proceso - 1
                if (c_rcdos.id_impsto = p_cdgo_clnte || 2) then
                    if (c_cncptos.vgncia >= p_vgncia - 1) then
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ACTUAL' ||
                                                         SUBSTR(c_cncptos.tpo_trnsccion,
                                                                INSTR(c_cncptos.tpo_trnsccion,
                                                                      '_',
                                                                      1,
                                                                      2));
                        c_cncptos.indcdor_vgncia_actual := 'S';
                    else
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ANTERIOR' ||
                                                         SUBSTR(c_cncptos.tpo_trnsccion,
                                                                INSTR(c_cncptos.tpo_trnsccion,
                                                                      '_',
                                                                      1,
                                                                      2));
                        c_cncptos.indcdor_vgncia_actual := 'N';
                    end if;
                end if;

                v_vlor_cncpto := c_cncptos.vlor;
                -- Calcula porcentaje sobretasa
                if (c_rcdos.id_impsto = p_cdgo_clnte || 1) then
                    if (c_cncptos.cdgo_cncpto = '1020' and c_cncptos.vgncia >= 2013 and
                        c_cncptos.tpo_trnsccion in
                        ('VIGENCIA_ACTUAL_CAPITAL', 'VIGENCIA_ANTERIOR_CAPITAL')) then

                        v_vlor_cncpto   := round(c_cncptos.vlor * 0.85);
                        v_vlor_prcntaje := c_cncptos.vlor - v_vlor_cncpto;
                        --Inserta el Movimiento en la Interfaz - porcentaje sobretasa
                        begin
                            insert into genesys_interfaz.in_movimiento_contables
                              (tpo_mvmnto,
                               id_orgen,
                               idntfccion,
                               cdgo_idntfccion_tpo,
                               dscrpcion_idntfccion,
                               idntfccion_rspnsble,
                               prmer_nmbre,
                               sgndo_nmbre,
                               prmer_aplldo,
                               sgndo_aplldo,
                               nmbre_prptrio,
                               cdgo_cncpto,
                               dscrpcion_cncpto,
                               vlor_cncpto,
                               cdgo_rcdo_orgn_tpo,
                               nmro_dcmnto,
                               fcha_rcdo,
                               cdgo_bnco,
                               nmbre_bnco,
                               nmro_cta,
                               fcha_rgstro,
                               indcdor_prcso,
                               cdgo_impsto,
                               ano,
                               mes,
                               tpo_trnsccion,
                               cdgo_clnte,
                               clsfccion)
                            values
                              ('RE',
                               c_rcdos.id_rcdo,
                               c_rcdos.idntfccion_sjto,
                               v_cdgo_idntfccion_tpo,
                               v_dscrpcion_idntfccion_tpo,
                               v_idntfccion_rspnsble,
                               v_prmer_nmbre,
                               v_sgndo_nmbre,
                               v_prmer_aplldo,
                               v_sgndo_aplldo,
                               v_nmbre_prptrio,
                               '1013',
                               'Porcentaje Ambiental',
                               v_vlor_prcntaje, --c_cncptos.vlor,
                               c_rcdos.cdgo_rcdo_orgn_tpo,
                               c_rcdos.nmro_dcmnto,
                               --c_rcdos.fcha_rcdo,
                               c_rcdos.fcha_apliccion,
                               c_rcdos.cdgo_bnco,
                               c_rcdos.nmbre_bnco,
                               c_rcdos.nmro_cnta,
                               sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'),
                               'N',
                               c_rcdos.cdgo_impsto,
                               c_rcdos.ano,
                               c_rcdos.mes,
                               c_cncptos.tpo_trnsccion,
                               p_cdgo_clnte,
                               v_clsfccion);

                            --Acumula las Sumatoria de los Conceptos   
                            s_vlor := s_vlor + v_vlor_prcntaje;

                        exception
                            when others then
                                o_cdgo_rspsta := 1;
                                rollback;
                                v_error := 'Tipo: RE' || ' Id_rcdo: ' || c_rcdos.id_rcdo ||
                                     ' - Recaudo Concepto causado prueba- : ' ||
                                     c_cncptos.id_cncpto_csdo || ' Error: ' || sqlerrm;
                                insert into genesys_interfaz.sg_g_log
                                (col1, col2)
                                values
                                (systimestamp, v_error);
                                commit;
                                exit;
                        end;
                    end if;
                end if;

                --Inserta el Movimiento en la Interfaz
                begin
                    insert into genesys_interfaz.in_movimiento_contables
                      (tpo_mvmnto,
                       id_orgen,
                       idntfccion,
                       cdgo_idntfccion_tpo,
                       dscrpcion_idntfccion,
                       idntfccion_rspnsble,
                       prmer_nmbre,
                       sgndo_nmbre,
                       prmer_aplldo,
                       sgndo_aplldo,
                       nmbre_prptrio,
                       cdgo_cncpto,
                       dscrpcion_cncpto,
                       vlor_cncpto,
                       cdgo_rcdo_orgn_tpo,
                       nmro_dcmnto,
                       fcha_rcdo,
                       cdgo_bnco,
                       nmbre_bnco,
                       nmro_cta,
                       fcha_rgstro,
                       indcdor_prcso,
                       cdgo_impsto,
                       ano,
                       mes,
                       tpo_trnsccion,
                       cdgo_clnte,
                       clsfccion)
                    values
                      ('RE',
                       c_rcdos.id_rcdo,
                       c_rcdos.idntfccion_sjto,
                       v_cdgo_idntfccion_tpo,
                       v_dscrpcion_idntfccion_tpo,
                       v_idntfccion_rspnsble,
                       v_prmer_nmbre,
                       v_sgndo_nmbre,
                       v_prmer_aplldo,
                       v_sgndo_aplldo,
                       v_nmbre_prptrio,
                       c_cncptos.cdgo_cncpto,
                       c_cncptos.dscrpcion,
                       v_vlor_cncpto, --c_cncptos.vlor,
                       c_rcdos.cdgo_rcdo_orgn_tpo,
                       c_rcdos.nmro_dcmnto,
                       --c_rcdos.fcha_rcdo,
                       c_rcdos.fcha_apliccion,
                       c_rcdos.cdgo_bnco,
                       c_rcdos.nmbre_bnco,
                       c_rcdos.nmro_cnta,
                       sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'),
                       'N',
                       c_rcdos.cdgo_impsto,
                       c_rcdos.ano,
                       c_rcdos.mes,
                       c_cncptos.tpo_trnsccion,
                       p_cdgo_clnte,
                       v_clsfccion);

                    --Acumula las Sumatoria de los Conceptos   
                    s_vlor := s_vlor + v_vlor_cncpto;          
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        rollback;
                        v_error := 'Tipo: RE' || ' Id_rcdo: ' || c_rcdos.id_rcdo ||
                                 ' - Recaudo Concepto causado- : ' ||
                                 c_cncptos.id_cncpto_csdo || ' Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                        values
                            (systimestamp, v_error);
                        commit;
                        exit;
                end;
            end loop;

            --Verifica si hay Saldo a Favor
            if (c_rcdos.id_sldo_fvor is not null and o_cdgo_rspsta=0 ) then
              

                --Busca los Datos del Saldo a Favor
                declare
                    v_vlor_sldo_fvor gf_g_saldos_favor.vlor_sldo_fvor%type;
                begin
                    select vlor_sldo_fvor
                      into v_vlor_sldo_fvor
                      from gf_g_saldos_favor
                     where id_sldo_fvor = c_rcdos.id_sldo_fvor;

                    --Inserta el Movimiento en la Interfaz de Saldo a Favor
                    insert into genesys_interfaz.in_movimiento_contables
                      (tpo_mvmnto,
                       id_orgen,
                       idntfccion,
                       cdgo_idntfccion_tpo,
                       dscrpcion_idntfccion,
                       idntfccion_rspnsble,
                       prmer_nmbre,
                       sgndo_nmbre,
                       prmer_aplldo,
                       sgndo_aplldo,
                       nmbre_prptrio,
                       cdgo_cncpto,
                       dscrpcion_cncpto,
                       vlor_cncpto,
                       cdgo_rcdo_orgn_tpo,
                       nmro_dcmnto,
                       fcha_rcdo,
                       cdgo_bnco,
                       nmbre_bnco,
                       nmro_cta,
                       fcha_rgstro,
                       indcdor_prcso,
                       cdgo_impsto,
                       ano,
                       mes,
                       tpo_trnsccion,
                       cdgo_clnte,
                       clsfccion)
                    values
                      ('RE',
                       c_rcdos.id_rcdo,
                       c_rcdos.idntfccion_sjto,
                       v_cdgo_idntfccion_tpo,
                       v_dscrpcion_idntfccion_tpo,
                       v_idntfccion_rspnsble,
                       v_prmer_nmbre,
                       v_sgndo_nmbre,
                       v_prmer_aplldo,
                       v_sgndo_aplldo,
                       v_nmbre_prptrio,
                       '999',
                       'SALDO A FAVOR ' || upper(c_rcdos.nmbre_impsto),
                       v_vlor_sldo_fvor,
                       c_rcdos.cdgo_rcdo_orgn_tpo,
                       c_rcdos.nmro_dcmnto,
                       --c_rcdos.fcha_rcdo,
                       c_rcdos.fcha_apliccion,
                       c_rcdos.cdgo_bnco,
                       c_rcdos.nmbre_bnco,
                       c_rcdos.nmro_cnta,
                       sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'),
                       'N',
                       c_rcdos.cdgo_impsto,
                       c_rcdos.ano,
                       c_rcdos.mes,
                       decode(c_rcdos.ano,
                              extract(year from sysdate),
                              'VIGENCIA_ACTUAL_CAPITAL',
                              'VIGENCIA_ANTERIOR_CAPITAL'),
                       p_cdgo_clnte,
                       v_clsfccion);

                    --Acumula las Sumatoria del Saldo a Favor 
                    s_vlor := s_vlor + v_vlor_sldo_fvor;

                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        rollback;
                        v_error := 'Tipo: RE-SF' || ' Id_rcdo: ' || c_rcdos.id_rcdo ||
                                    ' - Recaudo SF Concepto causado- : 999 Error: ' ||
                                    sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                        values
                            (systimestamp, v_error);
                        commit;
                        exit;
                end;
            end if;
             if (o_cdgo_rspsta=0 ) then
            -- Revisa Descuento
            pkg_gf_interfaz_contable_monteria.prc_rg_descuento_intrfaz ( p_cdgo_clnte  => p_cdgo_clnte,
                                                                         p_vgncia      => p_vgncia,
                                                                         p_id_rcdo     => c_rcdos.id_rcdo,
                                                                         p_clsfccion   => v_clsfccion,
                                                                         o_cdgo_rspsta => o_cdgo_rspsta );

            if (o_cdgo_rspsta = 0) then
                --Verifica si el Recaudo esta Cuadrado
                if (s_vlor = c_rcdos.vlor) then

                    --Indicador de Interfaz
                    update re_g_recaudos
                       set indcdor_intrfaz = 'S'
                     where id_rcdo = c_rcdos.id_rcdo;

                    --Salva los Cambios
                    commit;

                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'FOR ACTUALIZO INDICADOR TOTAL: '||c_rcdos.id_rcdo ,  1 );

                    /*insert into genesys_interfaz.sg_g_log  (col1, col2)
                    values (systimestamp, c_rcdos.id_rcdo||' - Marca recaudo enviado a la interfaz por el procedimiento');
                    commit;*/
                else
                    --o_cdgo_rspsta := 1;
                    rollback;
                    v_error := 'Tipo: RE' || ' Id_rcdo: ' || c_rcdos.id_rcdo ||
                                ' - Recaudo Descuadrado';
                    insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                    values
                        (systimestamp, v_error);
                    commit;
                end if;
            end if;
           end if;
        end loop;
        

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

    exception
        when others then
            --dbms_output.put_line(sqlerrm);
            v_error := 'prc_rg_recaudo_intrfaz_total. Error: ' || sqlerrm;
            insert into genesys_interfaz.sg_g_log
              (col1, col2)
            values
              (systimestamp, v_error);
            commit;

    end prc_rg_recaudo_intrfaz_total;


	procedure prc_rg_recaudo_intrfaz_cncldo( p_cdgo_clnte  in number,
                                             p_vgncia      in number  ) 

    is
        v_nl                        number;
        v_nmbre_up                  sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_rg_recaudo_intrfaz_cncldo';
        v_mnsje_rspsta              varchar2(4000);
        s_vlor                      number;
        v_clsfccion                 varchar2(30);
        v_id_impsto_sbmpsto         number;
        --v_cdgo_cncpto              df_i_conceptos_cnclcion.cdgo_cncpto%type;
        --v_nmbre_cncpto             df_i_conceptos_cnclcion.nmbre_cncpto%type;
        o_cdgo_rspsta               number;
        v_error                     varchar2(2000);
        v_tpo_trnsccion             varchar2(30);
        v_idntfccion_rspnsble       si_i_sujetos_responsable.idntfccion%type;
        v_prmer_nmbre               si_i_sujetos_responsable.prmer_nmbre%type;
        v_sgndo_nmbre               si_i_sujetos_responsable.sgndo_nmbre%type;
        v_prmer_aplldo              si_i_sujetos_responsable.prmer_aplldo%type;
        v_sgndo_aplldo              si_i_sujetos_responsable.sgndo_aplldo%type;
        v_nmbre_prptrio             varchar2(4000);
        v_cdgo_idntfccion_tpo       si_i_sujetos_responsable.cdgo_idntfccion_tpo%type;
        v_dscrpcion_idntfccion_tpo  df_s_identificaciones_tipo.dscrpcion_idntfccion_tpo%type;
        v_vlor_cncpto               number;
        v_vlor_prcntaje             number;
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Cursor de Recaudos
        for c_rcdos in (select distinct a.id_rcdo,
                                      a.idntfccion_sjto,
                                      a.cdgo_rcdo_orgn_tpo,
                                      a.nmro_dcmnto,
                                      e.fcha_cnclcion fcha_rcdo,
                                      d.cdgo_bnco,
                                      d.nmbre_bnco,
                                      d.nmro_cnta,
                                      decode(g.cdgo_impsto,
                                             'IPU',
                                             'P',
                                             'REN',
                                             'R',
                                             'ICA',
                                             'I',
                                             'VHL',
                                             'C',
                                             'VAL',
                                             'V',
                                             'PLU',
                                             'L',
                                             'O') as cdgo_impsto,
                                      extract(year from e.fcha_cnclcion) as ano,
                                      to_char(e.fcha_cnclcion, 'MM') as mes,                                      
                                      a.id_sldo_fvor,
                                      a.vlor,
                                      g.nmbre_impsto,
                                      g.cdgo_impsto cdgo_impsto_2,
                                      h.id_impsto,
                                      a.id_sjto_impsto,
                                      h.cdgo_sjto_tpo
                        from v_re_g_recaudos a
                        join v_re_g_recaudos_control d
                          on a.id_rcdo_cntrol = d.id_rcdo_cntrol
                        join v_si_i_sujetos_impuesto h
                          on a.id_sjto_impsto = h.id_sjto_impsto
                        join df_c_impuestos g
                          on h.id_impsto = g.id_impsto
                        join re_g_recaudos_cncpto_cnclcn c
                          on a.id_Rcdo = c.id_rcdo
                        join re_g_recaudos_lte_cnclcion b
                          on b.id_rcdo_lte_cnclcion = c.id_rcdo_lte_cnclcion
                        join re_g_recaudos_archvo_cnclcn e
                          on e.id_rcdo_archvo_cnclcion = b.id_rcdo_archvo_cnclcion
                         and e.estdo_archvo = 'FN'
                       where d.cdgo_clnte = p_cdgo_clnte
                     --  and a.id_rcdo  IN (1737426) 
                       --  and trunc(e.fcha_cnclcion) between to_date('01/12/2023', 'dd/mm/yyyy') and to_date('31/12/2023', 'dd/mm/yyyy')
                         -- and extract(year from a.fcha_rcdo) = p_vgncia
                         and extract(year from e.fcha_cnclcion) = p_vgncia 
                         and a.cdgo_rcdo_estdo = 'AP'
                         and a.vlor > 0
                         and not exists ( select    id_orgen
                                          from      genesys_interfaz.in_movimiento_contables
                                          where     tpo_mvmnto      = 'RE'
                                          and       id_orgen        = a.id_rcdo
                                          and       indcdor_cncldo  = 'S'
                                        )
                         --AND     A.ID_RCDO in (2035521) --( 2035141,2035202,2035128,2034539,2034437 )
                         and a.FCHA_RCDO >= to_date('01/07/2024','dd/mm/yyyy')
                       order by e.fcha_cnclcion, a.id_rcdo ) 
        loop

            --pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'En el FOR recaudo: '||c_rcdos.id_rcdo ,  1 );
            --Inicializa el Acumulador en 0 de Suma Cuadradas           
            o_cdgo_rspsta := 0;

            update  genesys_interfaz.in_movimiento_contables 
            set     indcdor_cncldo  = 'S', 
                    fcha_rcdo       = c_rcdos.fcha_rcdo, -- Esto es e.fcha_cnclcion
                    ano             = c_rcdos.ano,
                    mes             = c_rcdos.mes
            where   tpo_mvmnto      = 'RE'
            and     id_orgen        = c_rcdos.id_rcdo ;

            if sql%rowcount > 0 then
            
                update  genesys_interfaz.in_movimiento_contables 
                set     indcdor_cncldo = 'S'
                where   tpo_mvmnto      = 'AJ'
                and     id_orgen        = c_rcdos.id_rcdo 
                and     mtvo_ajste      = 999 ;
            
                pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 
                                        'Actualizados: '||sql%rowcount||' registros, recaudo: '||c_rcdos.id_rcdo ,  1 );

                commit;
            else
                rollback;
                o_cdgo_rspsta := 20;
                v_error       := 'Tipo: RE' || ' Id_Rcdo: ' || c_rcdos.id_rcdo ||
                               ' - No se actulizo el recaudo consolidado - : ' ||
                               c_rcdos.id_sjto_impsto || ' . Error: ' || sqlerrm;
                insert into genesys_interfaz.sg_g_log
                    (col1, col2)
                values
                    (systimestamp, v_error);
                commit;
                continue;
            end if;

        end loop;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

    exception
        when others then
            --dbms_output.put_line(sqlerrm);
            v_error := 'prc_rg_recaudo_intrfaz_cncldo. Error: ' || sqlerrm;
            insert into genesys_interfaz.sg_g_log
              (col1, col2)
            values
              (systimestamp, v_error);
            commit;

    end prc_rg_recaudo_intrfaz_cncldo;


    procedure prc_rg_descuento_intrfaz( p_cdgo_clnte  in number,
                                        p_vgncia      in number,
                                        p_id_rcdo     in number,
                                        p_clsfccion   in varchar2,
                                        o_cdgo_rspsta out number ) 
    as
        v_nl                       number;
        v_nmbre_up                 sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_rg_descuento_intrfaz';
        v_mnsje_rspsta             varchar2(4000);
        s_vlor                     number;
        v_clsfccion                varchar2(30);
        v_id_impsto_sbmpsto        number;
        v_error                    varchar2(2000);
        v_idntfccion_rspnsble      si_i_sujetos_responsable.idntfccion%type;
        v_prmer_nmbre              si_i_sujetos_responsable.prmer_nmbre%type;
        v_sgndo_nmbre              si_i_sujetos_responsable.sgndo_nmbre%type;
        v_prmer_aplldo             si_i_sujetos_responsable.prmer_aplldo%type;
        v_sgndo_aplldo             si_i_sujetos_responsable.sgndo_aplldo%type;
        v_nmbre_prptrio            varchar2(4000);
        v_cdgo_idntfccion_tpo      si_i_sujetos_responsable.cdgo_idntfccion_tpo%type;
        v_dscrpcion_idntfccion_tpo df_s_identificaciones_tipo.dscrpcion_idntfccion_tpo%type;
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Cursor de Descuentos - recaudos
        for c_dscntos in (select a.id_rcdo,
                                a.idntfccion_sjto,
                                a.cdgo_rcdo_orgn_tpo,
                                a.nmro_dcmnto,
                                --a.fcha_rcdo,
                                a.fcha_apliccion,
                                d.cdgo_bnco,
                                d.nmbre_bnco,
                                d.nmro_cnta,
                                decode(g.cdgo_impsto,
                                'IPU',
                                'P',
                                'REN',
                                'R',
                                'ICA',
                                'I',
                                'VHL',
                                'C',
                                'VAL',
                                'V',
                                'PLU',
                                'L',
                                'O') as cdgo_impsto,
                                --extract(year from a.fcha_rcdo) as ano,
                                extract(year from a.fcha_apliccion) as ano,
                                --to_char(a.fcha_rcdo, 'MM') as mes,
                                to_char(a.fcha_apliccion, 'MM') as mes,
                                a.id_sldo_fvor,
                                a.vlor,
                                g.nmbre_impsto,
                                g.cdgo_impsto cdgo_impsto_2,
                                h.id_impsto,
                                a.id_sjto_impsto,
                                h.cdgo_sjto_tpo,
                                d.cdgo_clnte
                        from v_re_g_recaudos a
                        join v_re_g_recaudos_control d
                        on a.id_rcdo_cntrol = d.id_rcdo_cntrol
                        join v_si_i_sujetos_impuesto h
                        on a.id_sjto_impsto = h.id_sjto_impsto
                        join df_c_impuestos g
                        on h.id_impsto = g.id_impsto
                        where d.cdgo_clnte = p_cdgo_clnte
                        and a.id_rcdo = p_id_rcdo
                        and a.cdgo_rcdo_estdo = 'AP'
                        and a.vlor > 0
                        and a.indcdor_intrfaz = 'N') 
        loop

            --Inicializa el Acumulador en 0 de Suma Cuadradas           
            s_vlor        := 0;
            o_cdgo_rspsta := 0;

            -- Buscar la informacion del responsable dependiendo del cdgo_sjto_tpo
            if (c_dscntos.cdgo_sjto_tpo = 'E') then
                begin
                    select c_dscntos.idntfccion_sjto,
                            null,
                            null,
                            null,
                            e.nmbre_rzon_scial,
                            null,
                            null
                            into v_idntfccion_rspnsble,
                            v_prmer_nmbre,
                            v_sgndo_nmbre,
                            v_prmer_aplldo,
                            v_nmbre_prptrio,
                            v_cdgo_idntfccion_tpo,
                            v_dscrpcion_idntfccion_tpo
                    from si_i_personas e
                    where e.id_sjto_impsto = c_dscntos.id_sjto_impsto;
                exception
                    when others then
                    o_cdgo_rspsta := 1;
                    v_error       := 'Tipo: RE' || ' Id_Rcdo: ' || c_dscntos.id_rcdo ||
                    ' - Error en persona- : ' ||
                    c_dscntos.id_sjto_impsto || ' . Error: ' ||
                    sqlerrm;
                    insert into genesys_interfaz.sg_g_log
                    (col1, col2)
                    values
                    (systimestamp, v_error);
                    commit;
                    continue;
                end;

            else
                begin
                    select nvl(substr(e.idntfccion, 1, instr(e.idntfccion, '-') - 1),
                        e.idntfccion),
                        e.prmer_nmbre,
                        e.sgndo_nmbre,
                        e.prmer_aplldo,
                        e.sgndo_aplldo,
                        e.prmer_nmbre || ' ' || e.sgndo_nmbre || ' ' ||
                        replace(e.prmer_aplldo, '.') || ' ' || e.sgndo_aplldo,
                        e.cdgo_idntfccion_tpo,
                        f.dscrpcion_idntfccion_tpo
                        into v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_sgndo_aplldo,
                        v_nmbre_prptrio,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo
                    from si_i_sujetos_responsable e
                    join df_s_identificaciones_tipo f
                    on e.cdgo_idntfccion_tpo = f.cdgo_idntfccion_tpo
                    where e.id_sjto_impsto = c_dscntos.id_sjto_impsto
                    and e.prncpal_s_n = 'S'
                    and rownum = 1;

                exception
                    when others then
                        v_error := 'Tipo: RE' || ' Id_Rcdo: ' || c_dscntos.id_rcdo ||
                        ' - Error en reponsable principal- : ' ||
                        c_dscntos.id_sjto_impsto || ' . Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            end if;

            o_cdgo_rspsta := 0;
            --Cursor Conceptos Pagados
            for c_cncptos in (select decode(a.vgncia,
                                            c_dscntos.ano,
                                            'VIGENCIA_ACTUAL',
                                            'VIGENCIA_ANTERIOR') || '_' ||
                                            decode(a.cdgo_mvmnto_tpo,
                                            'DC',
                                            'CAPITAL',
                                            'DI',
                                            'INTERES') as tpo_trnsccion,
                                        b.cdgo_cncpto,
                                        a.id_cncpto, --_csdo
                                        sum(a.vlor) as vlor,
                                        b.dscrpcion,
                                        decode(a.vgncia, c_dscntos.ano, 'S', 'N') as indcdor_vgncia_actual,
                                        a.vgncia
                                        from (select a.id_orgen,
                                        a.vgncia,
                                        a.id_cncpto, --_csdo
                                        sum(a.vlor_hber) as vlor,
                                        a.cdgo_mvmnto_tpo
                                    from gf_g_movimientos_detalle a
                                    where cdgo_mvmnto_orgn = 'RE'
                                    and a.id_orgen = c_dscntos.id_rcdo
                                    and a.vlor_hber > 0
                                    and a.cdgo_mvmnto_tpo in ('DC', 'DI')
                                    group by a.id_orgen,
                                            a.vgncia,
                                            a.id_cncpto, --_csdo 
                                            a.cdgo_mvmnto_tpo) a
                            join df_i_conceptos b
                            on a.id_cncpto = b.id_cncpto
                            group by decode(a.vgncia,
                                c_dscntos.ano,
                                'VIGENCIA_ACTUAL',
                                'VIGENCIA_ANTERIOR') || '_' ||
                                decode(a.cdgo_mvmnto_tpo,
                                'DC',
                                'CAPITAL',
                                'DI',
                                'INTERES'),
                                b.cdgo_cncpto,
                                a.id_cncpto, --_csdo 
                                b.dscrpcion,
                                decode(a.vgncia, c_dscntos.ano, 'S', 'N'), a.vgncia ) 
            loop

                -- Si es ICA, la vigencia actual es la vigencia del proceso - 1
                if (c_dscntos.id_impsto = p_cdgo_clnte || 2) then
                    if (c_cncptos.vgncia >= p_vgncia - 1) then
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ACTUAL' ||
                                                    SUBSTR(c_cncptos.tpo_trnsccion,
                                                        INSTR(c_cncptos.tpo_trnsccion,
                                                              '_',
                                                              1,
                                                              2));
                        c_cncptos.indcdor_vgncia_actual := 'S';
                    else
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ANTERIOR' ||
                                                    SUBSTR(c_cncptos.tpo_trnsccion,
                                                        INSTR(c_cncptos.tpo_trnsccion,
                                                              '_',
                                                              1,
                                                              2));
                        c_cncptos.indcdor_vgncia_actual := 'N';
                    end if;
                end if;

                --Inserta el Movimiento en la Interfaz
                begin

                    insert into genesys_interfaz.in_movimiento_contables
                        (tpo_mvmnto,
                        id_orgen,
                        idntfccion,
                        cdgo_idntfccion_tpo,
                        dscrpcion_idntfccion,
                        idntfccion_rspnsble,
                        prmer_nmbre,
                        sgndo_nmbre,
                        prmer_aplldo,
                        sgndo_aplldo,
                        nmbre_prptrio,
                        cdgo_cncpto,
                        dscrpcion_cncpto,
                        vlor_cncpto,
                        tpo_trnsccion,
                        nmro_dcmnto,
                        fcha_rcdo,
                        tpo_ajste,
                        mtvo_ajste,
                        obsrvcion_ajste,
                        fcha_rgstro,
                        indcdor_prcso,
                        cdgo_impsto,
                        ano,
                        mes,
                        cdgo_clnte,
                        clsfccion)
                    values
                        ('AJ', --tpo_mvmnto,
                        c_dscntos.id_rcdo, --id_orgen,
                        c_dscntos.idntfccion_sjto, --idntfccion,
                        v_cdgo_idntfccion_tpo, --cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo, --dscrpcion_idntfccion,
                        v_idntfccion_rspnsble, --idntfccion_rspnsble,
                        v_prmer_nmbre, --prmer_nmbre,
                        v_sgndo_nmbre, --sgndo_nmbre,
                        v_prmer_aplldo, --prmer_aplldo,
                        v_sgndo_aplldo, --sgndo_aplldo,
                        v_nmbre_prptrio, --nmbre_prptrio,
                        c_cncptos.cdgo_cncpto, --cdgo_cncpto,
                        c_cncptos.dscrpcion, --dscrpcion_cncpto,
                        c_cncptos.vlor, --vlor_cncpto,
                        c_cncptos.tpo_trnsccion, --tpo_trnsccion,
                        c_dscntos.nmro_dcmnto, --nmro_dcmnto, 
                        --c_dscntos.fcha_rcdo, --fcha_rcdo,
                        c_dscntos.fcha_apliccion, --fcha_rcdo,
                        'CR', --cdgo_tpo_ajste
                        999, --id_ajste_mtvo,  
                        'Descuentos', --dscrpcion_motivo 
                        sysdate, --fcha_rgstro,
                        'N', --indcdor_prcso,
                        c_dscntos.cdgo_impsto, --cdgo_impsto,
                        c_dscntos.ano, --ano,
                        c_dscntos.mes, --mes
                        c_dscntos.cdgo_clnte,
                        p_clsfccion);
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        rollback;
                        v_error := 'Tipo: AJ' || ' Id_rcdo: ' || c_dscntos.id_rcdo ||
                                    ' - Descuento Concepto causado- : ' ||
                        c_cncptos.id_cncpto || ' Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                        values
                            (systimestamp, v_error);
                        commit;
                        exit;
                end;
            end loop;
        end loop;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

    exception
        when others then
            dbms_output.put_line(sqlerrm);

    end prc_rg_descuento_intrfaz;


    procedure prc_rg_ajuste_intrfaz(p_cdgo_clnte in number,
                                    p_vgncia     in number) 
    as
        v_nl                       number;
        v_nmbre_up                 sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_rg_ajuste_intrfaz';
        v_mnsje_rspsta             varchar2(4000);
        s_vlor                     number;
        s_vlor_ac                  number;
        s_vlor_ad                  number;
        v_clsfccion                varchar2(30);
        v_cdgo_cncpto              df_i_conceptos_cnclcion.cdgo_cncpto%type;
        v_nmbre_cncpto             df_i_conceptos_cnclcion.nmbre_cncpto%type;
        o_cdgo_rspsta              number;
        v_error                    varchar2(2000);
        v_idntfccion_rspnsble      si_i_sujetos_responsable.idntfccion%type;
        v_prmer_nmbre              si_i_sujetos_responsable.prmer_nmbre%type;
        v_sgndo_nmbre              si_i_sujetos_responsable.sgndo_nmbre%type;
        v_prmer_aplldo             si_i_sujetos_responsable.prmer_aplldo%type;
        v_sgndo_aplldo             si_i_sujetos_responsable.sgndo_aplldo%type;
        v_nmbre_prptrio            varchar2(4000);
        v_cdgo_idntfccion_tpo      si_i_sujetos_responsable.cdgo_idntfccion_tpo%type;
        v_dscrpcion_idntfccion_tpo df_s_identificaciones_tipo.dscrpcion_idntfccion_tpo%type;
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Cursor de Ajuste
        for c_ajste in (select a.id_ajste,
                            a.id_impsto,
                            decode(g.cdgo_impsto,
                            'IPU',
                            'P',
                            'REN',
                            'R',
                            'ICA',
                            'I',
                            'VHL',
                            'C',
                            'VAL',
                            'V',
                            'PLU',
                            'L',
                            'O') as cdgo_impsto,
                            a.id_sjto_impsto,
                            a.numro_ajste,
                            a.id_sjto,
                            a.idntfccion_sjto,
                            a.cdgo_tpo_ajste,
                            a.orgen,
                            a.dscrpcion_orgen,
                            a.tpo_ajste,
                            a.vlor,
                            a.fcha_aplccion,
                            extract(year from a.fcha_aplccion) as ano,
                            to_char(a.fcha_aplccion, 'MM') as mes,
                            a.id_ajste_mtvo,
                            a.dscrpcion_motivo,
                            a.obsrvcion,
                            a.cdgo_ajste_estdo,
                            a.indcdor_intrfaz,
                            g.cdgo_impsto cdgo_impsto_2,
                            a.id_impsto_sbmpsto,
                            a.cdgo_clnte,
                            h.cdgo_sjto_tpo
                        from v_gf_g_ajustes a
                        join v_si_i_sujetos_impuesto h
                        on a.id_sjto_impsto = h.id_sjto_impsto
                        join df_c_impuestos g
                        on h.id_impsto = g.id_impsto
                        where a.cdgo_clnte = p_cdgo_clnte
                        /*and trunc(a.fcha_aplccion) between
                        to_date('01/04/2022', 'dd/mm/yyyy') and
                        to_date('30/04/2022', 'dd/mm/yyyy')*/
                        and extract(year from a.fcha_aplccion) = p_vgncia
                        and a.cdgo_ajste_estdo = 'AP'
                        and (a.indcdor_intrfaz = 'N' or
                        a.indcdor_intrfaz is null)
                        and a.vlor > 0
                        --and id_ajste in ( 692989 ,693010 ,693049 )
                        order by a.fcha_aplccion, a.id_ajste) 
        loop

            --Inicializa el Acumulador en 0 de Suma por tipos de ajuste cuadradas           
            --       s_vlor := 0;
            s_vlor_ac := 0;
            s_vlor_ad := 0;

            -- Obtener la Clasificacion
            case
                when c_ajste.cdgo_impsto_2 = 'IPU' then
                    -- Si es un predio
                    if (substr(c_ajste.idntfccion_sjto, 1, 2) = '01') then
                        v_clsfccion := 'URBANO';
                    else
                        v_clsfccion := 'RURAL';
                    end if;

                when c_ajste.cdgo_impsto_2 = 'ICA' then
                    -- Si es un establecimiento
                    begin
                        select upper(d.nmbre_dclrcns_esqma_trfa_tpo)
                        into v_clsfccion
                        from si_i_personas a
                        join si_i_sujetos_impuesto b
                        on b.id_sjto_impsto = a.id_sjto_impsto
                        join gi_d_dclrcns_esqma_trfa c
                        on c.id_dclrcns_esqma_trfa = a.id_actvdad_ecnmca
                        join gi_d_dclrcns_esqma_trfa_tpo d
                        on d.id_dclrcns_esqma_trfa_tpo = c.id_dclrcns_esqma_trfa_tpo
                        where a.id_sjto_impsto = c_ajste.id_sjto_impsto
                        and b.id_impsto = c_ajste.id_impsto;

                        if v_clsfccion not in ('COMERCIAL', 'SERVICIOS', 'INDUSTRIAL') then
                            v_clsfccion := 'SERVICIOS';
                        end if;

                    exception
                        when others then
                            v_clsfccion := 'SERVICIOS';
                    end;

                when c_ajste.cdgo_impsto_2 = 'ARD' then
                    v_clsfccion := 'PLAZA DE MERCADO';

                when c_ajste.cdgo_impsto_2 = 'REN' then

                    if (c_ajste.id_impsto_sbmpsto = 2367842) then
                        ---
                        -- ESPECTACULOS PUBLICOS AL DEPORTE
                        v_clsfccion := 'ESPECTACULO DEPORTE';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001148) then
                        -- DEGUELLO DE GANADO MENOR
                        v_clsfccion := 'DEGUELLO MENOR';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001147) then
                        -- PUBLICIDAD EXTERIOR VISUAL
                        v_clsfccion := 'PUBLICIDAD VISUAL';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001150) then
                        -- ESPECTACULOS PUBLICOS
                        v_clsfccion := 'ESPECTACULO PUBLICO';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001157) then
                        -- DELINEACION URBANA
                        v_clsfccion := 'DELINEACION';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001142) then
                        -- Estampilla Adulto Mayor
                        v_clsfccion := 'ADULTO MAYOR';
                    elsif (c_ajste.id_impsto_sbmpsto = 23001141) then
                        -- Estampilla Pro-Cultura 
                        v_clsfccion := 'PRO CULTURA';
                    else
                        v_clsfccion := 'SIN CLASIFICACION';
                    end if;
                else
                    v_clsfccion := 'SIN CLASIFICACION';
            end case;

            -- Buscar la informacion del responsable dependiendo del cdgo_sjto_tpo
            if (c_ajste.cdgo_sjto_tpo = 'E') then
                begin
                    select c_ajste.idntfccion_sjto,
                            null,
                            null,
                            null,
                            e.nmbre_rzon_scial,
                            null,
                            null
                            into v_idntfccion_rspnsble,
                            v_prmer_nmbre,
                            v_sgndo_nmbre,
                            v_prmer_aplldo,
                            v_nmbre_prptrio,
                            v_cdgo_idntfccion_tpo,
                            v_dscrpcion_idntfccion_tpo
                    from si_i_personas e
                    where e.id_sjto_impsto = c_ajste.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        v_error       := 'Tipo: AJ' || ' Id_Ajuste: ' || c_ajste.id_ajste ||
                                        ' - Error en persona- : ' ||
                        c_ajste.id_sjto_impsto || ' . Error: ' ||
                        sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            else
                begin
                    select nvl(substr(e.idntfccion, 1, instr(e.idntfccion, '-') - 1),
                        e.idntfccion),
                        e.prmer_nmbre,
                        e.sgndo_nmbre,
                        e.prmer_aplldo,
                        e.sgndo_aplldo,
                        e.prmer_nmbre || ' ' || e.sgndo_nmbre || ' ' ||
                        replace(e.prmer_aplldo, '.') || ' ' || e.sgndo_aplldo,
                        e.cdgo_idntfccion_tpo,
                        f.dscrpcion_idntfccion_tpo
                    into v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_sgndo_aplldo,
                        v_nmbre_prptrio,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo
                    from si_i_sujetos_responsable e
                    join df_s_identificaciones_tipo f
                    on e.cdgo_idntfccion_tpo = f.cdgo_idntfccion_tpo
                    where e.id_sjto_impsto = c_ajste.id_sjto_impsto
                    and e.prncpal_s_n = 'S'
                    and rownum = 1;

                exception
                    when others then
                        v_error := 'Tipo: AJ' || ' Id_Ajuste: ' || c_ajste.id_ajste ||
                                ' - Error en reponsable principal- : ' ||
                        c_ajste.id_sjto_impsto || ' . Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                        values
                            (systimestamp, v_error);
                        commit;
                        continue;
                end;
            end if;

            o_cdgo_rspsta := 0;
            --Cursor Conceptos Pagados
            for c_cncptos in (select decode(a.vgncia,
                                    c_ajste.ano,
                                    'VIGENCIA_ACTUAL',
                                    'VIGENCIA_ANTERIOR') || '_' ||
                                    decode(a.cdgo_mvmnto_tpo,
                                    'AC',
                                    'CAPITAL',
                                    'AD',
                                    'CAPITAL',
                                    'IT',
                                    'INTERES') as tpo_trnsccion,
                                    b.cdgo_cncpto,
                                    a.id_cncpto_csdo,
                                    sum(a.vlor_ac) as vlor_ac,
                                    sum(a.vlor_ad) as vlor_ad,
                                    b.dscrpcion,
                                    b.id_cncpto,
                                    decode(a.vgncia, c_ajste.ano, 'S', 'N') as indcdor_vgncia_actual,
                                    a.vgncia
                                from (select a.id_orgen,
                                 a.vgncia,
                                 a.id_cncpto_csdo,
                                 sum(a.vlor_hber) as vlor_ac,
                                 sum(a.vlor_dbe) as vlor_ad,
                                 a.cdgo_mvmnto_tpo
                                from gf_g_movimientos_detalle a
                                where cdgo_mvmnto_orgn = 'AJ'
                                and a.id_orgen = c_ajste.id_ajste
                                -- and a.vlor_hber           > 0
                                and a.cdgo_mvmnto_tpo in ('AC', 'AD', 'IT') -- 'Codigo del tipo de movimiento, Ejemplo: IN:Ingreso, AD:Ajuste Debito, AC:Ajuste Credito, PC:Pago Capital, PI:Pago Interes, DC:Descuento Capital, DI:Decescuento Interes, IT:Interes'
                                group by a.id_orgen,
                                    a.vgncia,
                                    a.id_cncpto_csdo,
                                    a.cdgo_mvmnto_tpo) a
                            join df_i_conceptos b
                            on a.id_cncpto_csdo = b.id_cncpto
                            group by decode(a.vgncia,
                               c_ajste.ano,
                               'VIGENCIA_ACTUAL',
                               'VIGENCIA_ANTERIOR') || '_' ||
                            decode(a.cdgo_mvmnto_tpo,
                               'AC',
                               'CAPITAL',
                               'AD',
                               'CAPITAL',
                               'IT',
                               'INTERES'),
                            b.cdgo_cncpto,
                            a.id_cncpto_csdo,
                            b.dscrpcion,
                            b.id_cncpto,
                            decode(a.vgncia, c_ajste.ano, 'S', 'N'),
                            a.vgncia) 
            loop

                -- Si es ICA, la vigencia actual es la vigencia del proceso - 1
                if (c_ajste.id_impsto = p_cdgo_clnte || 2) then
                    if (c_cncptos.vgncia >= p_vgncia - 1) then
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ACTUAL' ||
                                                         SUBSTR(c_cncptos.tpo_trnsccion,
                                                                INSTR(c_cncptos.tpo_trnsccion,
                                                                      '_',
                                                                      1,
                                                                      2));
                        c_cncptos.indcdor_vgncia_actual := 'S';
                    else
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ANTERIOR' ||
                                                         SUBSTR(c_cncptos.tpo_trnsccion,
                                                                INSTR(c_cncptos.tpo_trnsccion,
                                                                      '_',
                                                                      1,
                                                                      2));
                        c_cncptos.indcdor_vgncia_actual := 'N';
                    end if;
                end if;

                --Inserta el Movimiento en la Interfaz
                begin
                        insert into genesys_interfaz.in_movimiento_contables
                        (tpo_mvmnto,
                        id_orgen,
                        idntfccion,
                        cdgo_idntfccion_tpo,
                        dscrpcion_idntfccion,
                        idntfccion_rspnsble,
                        prmer_nmbre,
                        sgndo_nmbre,
                        prmer_aplldo,
                        sgndo_aplldo,
                        nmbre_prptrio,
                        cdgo_cncpto,
                        dscrpcion_cncpto,
                        vlor_cncpto,
                        tpo_trnsccion,
                        nmro_dcmnto,
                        fcha_rcdo,
                        tpo_ajste,
                        mtvo_ajste,
                        obsrvcion_ajste,
                        fcha_rgstro,
                        indcdor_prcso,
                        cdgo_impsto,
                        ano,
                        mes,
                        cdgo_clnte,
                        clsfccion)
                    values
                        ('AJ', --tpo_mvmnto,
                        c_ajste.id_ajste, --id_orgen,
                        c_ajste.idntfccion_sjto, --idntfccion,
                        v_cdgo_idntfccion_tpo, --cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo, --dscrpcion_idntfccion,
                        v_idntfccion_rspnsble, --idntfccion_rspnsble,
                        v_prmer_nmbre, --prmer_nmbre,
                        v_sgndo_nmbre, --sgndo_nmbre,
                        v_prmer_aplldo, --prmer_aplldo,
                        v_sgndo_aplldo, --sgndo_aplldo,
                        v_nmbre_prptrio, --nmbre_prptrio,
                        c_cncptos.cdgo_cncpto, --cdgo_cncpto,
                        c_cncptos.dscrpcion, --dscrpcion_cncpto,
                        decode(c_cncptos.vlor_ac,
                        0,
                        c_cncptos.vlor_ad,
                        c_cncptos.vlor_ac), --vlor_cncpto,
                        c_cncptos.tpo_trnsccion, --tpo_trnsccion,
                        c_ajste.numro_ajste, --nmro_dcmnto,
                        c_ajste.fcha_aplccion, --fcha_rcdo,
                        c_ajste.cdgo_tpo_ajste, --tpo_ajste,
                        c_ajste.id_ajste_mtvo, --mtvo_ajste,
                        c_ajste.dscrpcion_motivo, --dscrpcion_motivo obsrvcion_ajste,
                        sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'), --fcha_rgstro,
                        'N', --indcdor_prcso,
                        c_ajste.cdgo_impsto, --cdgo_impsto,
                        c_ajste.ano, --ano,
                        c_ajste.mes, --mes
                        c_ajste.cdgo_clnte,
                        v_clsfccion);

                    --Acumula los valores por acada ajuste dependiendo de su naturaleza por Conceptos 
                    s_vlor_ac := s_vlor_ac + c_cncptos.vlor_ac;
                    s_vlor_ad := s_vlor_ad + c_cncptos.vlor_ad;

                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        rollback;
                        v_error := 'Tipo: AJ' || ' Id_Ajste: ' || c_ajste.id_ajste ||
                        ' - Ajuste Concepto causado- : ' ||
                        c_cncptos.id_cncpto_csdo || ' Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        exit;
                end;
            end loop;

            if (o_cdgo_rspsta = 0) then
                --Verifica si el Ajuste esta Cuadrado
                if (s_vlor_ac = c_ajste.vlor) then
                    --Indicador de Interfaz
                    update gf_g_ajustes
                    set indcdor_intrfaz = 'S'
                    where id_ajste = c_ajste.id_ajste;
                    --Salva los Cambios
                    commit;
                elsif (s_vlor_ad = c_ajste.vlor) then
                    --Indicador de Interfaz
                    update gf_g_ajustes
                    set indcdor_intrfaz = 'S'
                    where id_ajste = c_ajste.id_ajste;
                    --Salva los Cambios
                    commit;
                else
                    rollback;
                    v_error := 'Tipo: AJ' || ' Id_Ajste: ' || c_ajste.id_ajste ||
                    ' - Ajuste Descuadrado';
                    insert into genesys_interfaz.sg_g_log
                    (col1, col2)
                    values
                    (systimestamp, v_error);
                    commit;
                end if;
            end if;
        end loop;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

        exception
            when others then
                --dbms_output.put_line(sqlerrm);
                v_error := 'prc_rg_ajuste_intrfaz. Error: ' || sqlerrm;
                insert into genesys_interfaz.sg_g_log
                (col1, col2)
                values
                (systimestamp, v_error);
                commit;

    end prc_rg_ajuste_intrfaz;


    procedure prc_rg_liquidacion_intrfaz(p_cdgo_clnte in number,
                                         p_vgncia     in number) 
    as
        v_nl                       number;
        v_nmbre_up                 sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_interfaz_contable_monteria.prc_rg_liquidacion_intrfaz';
        v_mnsje_rspsta             varchar2(4000);
        s_vlor                     number;
        v_clsfccion                varchar2(30);
        v_cdgo_cncpto              df_i_conceptos_cnclcion.cdgo_cncpto%type;
        v_nmbre_cncpto             df_i_conceptos_cnclcion.nmbre_cncpto%type;
        o_cdgo_rspsta              number;
        v_error                    varchar2(2000);
        v_idntfccion_rspnsble      si_i_sujetos_responsable.idntfccion%type;
        v_prmer_nmbre              si_i_sujetos_responsable.prmer_nmbre%type;
        v_sgndo_nmbre              si_i_sujetos_responsable.sgndo_nmbre%type;
        v_prmer_aplldo             si_i_sujetos_responsable.prmer_aplldo%type;
        v_sgndo_aplldo             si_i_sujetos_responsable.sgndo_aplldo%type;
        v_nmbre_prptrio            varchar2(4000);
        v_cdgo_idntfccion_tpo      si_i_sujetos_responsable.cdgo_idntfccion_tpo%type;
        v_dscrpcion_idntfccion_tpo df_s_identificaciones_tipo.dscrpcion_idntfccion_tpo%type;
        v_vlor_cncpto              number;
        v_vlor_prcntje             number;
    begin

        --Determinamos el Nivel del Log de la UP
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte , null , v_nmbre_up );
        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , v_mnsje_rspsta ,  1 );

        --Cursor de Liquidaciones
        for c_lqdciones in (select a.id_lqdcion,
                            h.idntfccion_sjto,
                            decode(g.cdgo_impsto,
                            'IPU',
                            'P',
                            'REN',
                            'R',
                            'ICA',
                            'I',
                            'VHL',
                            'C',
                            'VAL',
                            'V',
                            'PLU',
                            'L',
                            'O') as cdgo_impsto,
                            extract(year from a.fcha_lqdcion) as ano,
                            to_char(a.fcha_lqdcion, 'MM') as mes,
                            a.vlor_ttal,
                            g.nmbre_impsto,
                            g.cdgo_impsto cdgo_impsto_2,
                            h.id_impsto,
                            a.id_impsto_sbmpsto,
                            a.id_sjto_impsto,
                            h.cdgo_sjto_tpo,
                            a.fcha_lqdcion
                            from gi_g_liquidaciones a
                            join v_si_i_sujetos_impuesto h
                            on a.id_sjto_impsto = h.id_sjto_impsto
                            join df_c_impuestos g
                            on h.id_impsto = g.id_impsto
                            where a.cdgo_clnte = p_cdgo_clnte
                            /*and trunc(a.fcha_lqdcion) between
                            to_date('01/04/2022', 'dd/mm/yyyy') and
                            to_date('30/04/2022', 'dd/mm/yyyy')*/
                            and extract(year from a.fcha_lqdcion) = p_vgncia
                            and a.cdgo_lqdcion_estdo = 'L'
                            and a.vlor_ttal > 0
                            and a.indcdor_mgrdo is null
                            and a.indcdor_intrfaz = 'N'
                            --and id_lqdcion in ( 36944801 , 36944845 , 36944889)
                            and not exists
                                (select 1
                                from gf_g_movimientos_financiero
                                where id_orgen = id_lqdcion
                                and cdgo_mvmnto_orgn = 'LQ'
                                and cdgo_mvnt_fncro_estdo = 'AN')
                         order by a.fcha_lqdcion, a.id_lqdcion) 
        loop

            --Inicializa el Acumulador en 0 de Suma Cuadradas           
            s_vlor        := 0;
            o_cdgo_rspsta := 0;

            -- Obtener la Clasificacion
            case
                when c_lqdciones.cdgo_impsto_2 = 'IPU' then
                    -- Si es un predio
                    if (substr(c_lqdciones.idntfccion_sjto, 1, 2) = '01') then
                        v_clsfccion := 'URBANO';
                    else
                        v_clsfccion := 'RURAL';
                    end if;

                when c_lqdciones.cdgo_impsto_2 = 'ICA' then
                    -- Si es un establecimiento
                    begin
                        select upper(d.nmbre_dclrcns_esqma_trfa_tpo)
                        into v_clsfccion
                        from si_i_personas a
                        join si_i_sujetos_impuesto b
                        on b.id_sjto_impsto = a.id_sjto_impsto
                        join gi_d_dclrcns_esqma_trfa c
                        on c.id_dclrcns_esqma_trfa = a.id_actvdad_ecnmca
                        join gi_d_dclrcns_esqma_trfa_tpo d
                        on d.id_dclrcns_esqma_trfa_tpo = c.id_dclrcns_esqma_trfa_tpo
                        where a.id_sjto_impsto = c_lqdciones.id_sjto_impsto
                        and b.id_impsto = c_lqdciones.id_impsto;

                        if v_clsfccion not in ('COMERCIAL', 'SERVICIOS', 'INDUSTRIAL') then
                            v_clsfccion := 'SERVICIOS';
                        end if;

                    exception
                        when others then
                        v_clsfccion := 'SERVICIOS';
                    end;

                when c_lqdciones.cdgo_impsto_2 = 'ARD' then
                    v_clsfccion := 'PLAZA DE MERCADO';

                when c_lqdciones.cdgo_impsto_2 = 'REN' then

                    if (c_lqdciones.id_impsto_sbmpsto = 2367842) then
                        ---
                        -- ESPECTACULOS PUBLICOS AL DEPORTE
                        v_clsfccion := 'ESPECTACULO DEPORTE';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001148) then
                        -- DEGUELLO DE GANADO MENOR
                        v_clsfccion := 'DEGUELLO MENOR';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001147) then
                        -- PUBLICIDAD EXTERIOR VISUAL
                        v_clsfccion := 'PUBLICIDAD VISUAL';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001150) then
                        -- ESPECTACULOS PUBLICOS
                        v_clsfccion := 'ESPECTACULO PUBLICO';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001157) then
                        -- DELINEACION URBANA
                        v_clsfccion := 'DELINEACION';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001142) then
                        -- Estampilla Adulto Mayor
                        v_clsfccion := 'ADULTO MAYOR';
                    elsif (c_lqdciones.id_impsto_sbmpsto = 23001141) then
                        -- Estampilla Pro-Cultura 
                        v_clsfccion := 'PRO CULTURA';
                    else
                        v_clsfccion := 'SIN CLASIFICACION';
                    end if;
                else
                    v_clsfccion := 'SIN CLASIFICACION';
            end case;

            -- Si es ICA, la vigencia actual es la vigencia del proceso - 1
            if (c_lqdciones.id_impsto = p_cdgo_clnte || 2) then
                begin
                    select d.fcha_prsntcion,
                    extract(year from d.fcha_prsntcion) as ano,
                    to_char(d.fcha_prsntcion, 'MM') as mes
                    into c_lqdciones.fcha_lqdcion, c_lqdciones.ano, c_lqdciones.mes
                    from gi_g_declaraciones d
                    where d.id_lqdcion = c_lqdciones.id_lqdcion;
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        v_error       := 'Tipo: LQ' || ' Id_lqdcion: ' ||
                        c_lqdciones.id_lqdcion ||
                        ' - Error en declaracion- : ' ||
                        c_lqdciones.id_sjto_impsto || ' . Error: ' ||
                        sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            end if;

            -- Buscar la informacion del responsable dependiendo del cdgo_sjto_tpo
            if (c_lqdciones.cdgo_sjto_tpo = 'E') then
                begin
                    select c_lqdciones.idntfccion_sjto,
                        null,
                        null,
                        null,
                        e.nmbre_rzon_scial,
                        null,
                        null
                        into v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_nmbre_prptrio,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo
                    from si_i_personas e
                    where e.id_sjto_impsto = c_lqdciones.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        v_error       := 'Tipo: LQ' || ' Id_lqdcion: ' ||
                        c_lqdciones.id_lqdcion ||
                        ' - Error en persona- : ' ||
                        c_lqdciones.id_sjto_impsto || ' . Error: ' ||
                        sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            else
                begin
                    select nvl(substr(e.idntfccion, 1, instr(e.idntfccion, '-') - 1),
                            e.idntfccion),
                            e.prmer_nmbre,
                            e.sgndo_nmbre,
                            e.prmer_aplldo,
                            e.sgndo_aplldo,
                            e.prmer_nmbre || ' ' || e.sgndo_nmbre || ' ' ||
                            replace(e.prmer_aplldo, '.') || ' ' || e.sgndo_aplldo,
                            e.cdgo_idntfccion_tpo,
                            f.dscrpcion_idntfccion_tpo
                    into v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_sgndo_aplldo,
                        v_nmbre_prptrio,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo
                    from si_i_sujetos_responsable e
                    join df_s_identificaciones_tipo f
                    on e.cdgo_idntfccion_tpo = f.cdgo_idntfccion_tpo
                    where e.id_sjto_impsto = c_lqdciones.id_sjto_impsto
                    and e.prncpal_s_n = 'S'
                    and rownum = 1;
                exception
                    when others then
                        v_error := 'Tipo: LQ' || ' Id_lqdcion: ' ||
                        c_lqdciones.id_lqdcion ||
                        ' - Error en reponsable principal- : ' ||
                        c_lqdciones.id_sjto_impsto || ' . Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        continue;
                end;
            end if;

            --Cursor Conceptos Pagados
            for c_cncptos in (select decode(a.vgncia,
                                c_lqdciones.ano,
                                'VIGENCIA_ACTUAL_CAPITAL',
                                'VIGENCIA_ANTERIOR_CAPITAL') as tpo_trnsccion,
                                b.cdgo_cncpto,
                                a.id_cncpto_csdo,
                                sum(a.vlor) as vlor,
                                b.dscrpcion,
                                b.id_cncpto,
                                decode(a.vgncia, c_lqdciones.ano, 'S', 'N') as indcdor_vgncia_actual,
                                a.vgncia
                                from (select a.id_orgen,
                                 a.vgncia,
                                 a.id_cncpto_csdo,
                                 sum(a.vlor_dbe) as vlor,
                                 a.cdgo_mvmnto_tpo
                                from gf_g_movimientos_detalle a
                                join gf_g_movimientos_financiero b
                                on a.id_mvmnto_fncro = b.id_mvmnto_fncro
                                where a.cdgo_mvmnto_orgn = 'LQ'
                                and a.id_orgen = c_lqdciones.id_lqdcion
                                and a.vlor_dbe > 0
                                and a.cdgo_mvmnto_tpo in ('IN')
                                and b.cdgo_mvnt_fncro_estdo != 'AN'
                                group by a.id_orgen,
                                    a.vgncia,
                                    a.id_cncpto_csdo,
                                    a.cdgo_mvmnto_tpo) a
                                join df_i_conceptos b
                                on a.id_cncpto_csdo = b.id_cncpto
                                group by decode(a.vgncia,
                                   c_lqdciones.ano,
                                   'VIGENCIA_ACTUAL_CAPITAL',
                                   'VIGENCIA_ANTERIOR_CAPITAL'),
                                b.cdgo_cncpto,
                                a.id_cncpto_csdo,
                                b.dscrpcion,
                                b.id_cncpto,
                                decode(a.vgncia, c_lqdciones.ano, 'S', 'N'),
                                a.vgncia) 
            loop
                -- Si es ICA, la vigencia actual es la vigencia del proceso - 1
                if (c_lqdciones.id_impsto = p_cdgo_clnte || 2) then
                    if (c_cncptos.vgncia >= p_vgncia - 1) then
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ACTUAL_CAPITAL';
                        c_cncptos.indcdor_vgncia_actual := 'S';
                    else
                        c_cncptos.tpo_trnsccion         := 'VIGENCIA_ANTERIOR_CAPITAL';
                        c_cncptos.indcdor_vgncia_actual := 'N';
                    end if;
                end if;

                v_vlor_cncpto := c_cncptos.vlor;
                -- Calcula porcentaje sobretasa
                if (c_cncptos.cdgo_cncpto = '1020' and c_cncptos.vgncia >= 2013) then
                    v_vlor_cncpto  := round(v_vlor_cncpto * 0.85);
                    v_vlor_prcntje := c_cncptos.vlor - v_vlor_cncpto;
                    --Inserta el Movimiento en la Interfaz - porcentaje sobretasa
                    begin
                        insert into genesys_interfaz.in_movimiento_contables
                        (tpo_mvmnto,
                        id_orgen,
                        idntfccion,
                        cdgo_idntfccion_tpo,
                        dscrpcion_idntfccion,
                        idntfccion_rspnsble,
                        prmer_nmbre,
                        sgndo_nmbre,
                        prmer_aplldo,
                        sgndo_aplldo,
                        nmbre_prptrio,
                        cdgo_cncpto,
                        dscrpcion_cncpto,
                        vlor_cncpto,
                        nmro_dcmnto,
                        fcha_rcdo,
                        fcha_rgstro,
                        indcdor_prcso,
                        cdgo_impsto,
                        ano,
                        mes,
                        tpo_trnsccion,
                        cdgo_clnte,
                        clsfccion)
                        values
                        ('LQ',
                        c_lqdciones.id_lqdcion,
                        c_lqdciones.idntfccion_sjto,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo,
                        v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_sgndo_aplldo,
                        v_nmbre_prptrio,
                        '1013',
                        'Porcentaje Ambiental',
                        v_vlor_prcntje,
                        c_lqdciones.id_lqdcion,
                        c_lqdciones.fcha_lqdcion,
                        sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'),
                        'N',
                        c_lqdciones.cdgo_impsto,
                        c_lqdciones.ano,
                        c_lqdciones.mes,
                        c_cncptos.tpo_trnsccion,
                        p_cdgo_clnte,
                        v_clsfccion);

                        --Acumula las Sumatoria de los Conceptos   
                        s_vlor := s_vlor + v_vlor_prcntje;

                    exception
                        when others then
                            o_cdgo_rspsta := 1;
                            rollback;
                            v_error := 'Tipo: LQ' || ' Id_lqdcion: ' ||
                            c_lqdciones.id_lqdcion ||
                            ' - Liquidacion Concepto causado- : ' ||
                            c_cncptos.id_cncpto_csdo || ' Error: ' || sqlerrm;
                            insert into genesys_interfaz.sg_g_log
                            (col1, col2)
                            values
                            (systimestamp, v_error);
                            commit;
                            exit;
                    end;
                end if;

                --Inserta el Movimiento en la Interfaz
                begin
                    insert into genesys_interfaz.in_movimiento_contables
                        (tpo_mvmnto,
                        id_orgen,
                        idntfccion,
                        cdgo_idntfccion_tpo,
                        dscrpcion_idntfccion,
                        idntfccion_rspnsble,
                        prmer_nmbre,
                        sgndo_nmbre,
                        prmer_aplldo,
                        sgndo_aplldo,
                        nmbre_prptrio,
                        cdgo_cncpto,
                        dscrpcion_cncpto,
                        vlor_cncpto,
                        nmro_dcmnto,
                        fcha_rcdo,
                        fcha_rgstro,
                        indcdor_prcso,
                        cdgo_impsto,
                        ano,
                        mes,
                        tpo_trnsccion,
                        cdgo_clnte,
                        clsfccion)
                    values
                        ('LQ',
                        c_lqdciones.id_lqdcion,
                        c_lqdciones.idntfccion_sjto,
                        v_cdgo_idntfccion_tpo,
                        v_dscrpcion_idntfccion_tpo,
                        v_idntfccion_rspnsble,
                        v_prmer_nmbre,
                        v_sgndo_nmbre,
                        v_prmer_aplldo,
                        v_sgndo_aplldo,
                        v_nmbre_prptrio,
                        c_cncptos.cdgo_cncpto,
                        c_cncptos.dscrpcion,
                        v_vlor_cncpto,
                        c_lqdciones.id_lqdcion,
                        c_lqdciones.fcha_lqdcion,
                        sysdate, --to_date('05/05/2022', 'dd/mm/yyyy'),
                        'N',
                        c_lqdciones.cdgo_impsto,
                        c_lqdciones.ano,
                        c_lqdciones.mes,
                        c_cncptos.tpo_trnsccion,
                        p_cdgo_clnte,
                        v_clsfccion);

                    --Acumula las Sumatoria de los Conceptos   
                    s_vlor := s_vlor + v_vlor_cncpto; --c_cncptos.vlor;

                exception
                    when others then
                        o_cdgo_rspsta := 1;
                        rollback;
                        v_error := 'Tipo: LQ' || ' Id_lqdcion: ' ||
                        c_lqdciones.id_lqdcion ||
                        ' - Liquidacion Concepto causado- : ' ||
                        c_cncptos.id_cncpto_csdo || ' Error: ' || sqlerrm;
                        insert into genesys_interfaz.sg_g_log
                        (col1, col2)
                        values
                        (systimestamp, v_error);
                        commit;
                        exit;
                    end;
            end loop;

            if (o_cdgo_rspsta = 0) then
                --Verifica si la liquidacion esta Cuadrada
                if (s_vlor = c_lqdciones.vlor_ttal) then

                --Indicador de Interfaz
                update gi_g_liquidaciones
                set indcdor_intrfaz = 'S'
                where id_lqdcion = c_lqdciones.id_lqdcion;

                --Salva los Cambios
                commit;
            else
                rollback;
                v_error := 'Descuadre id_lqdcion:' || c_lqdciones.id_lqdcion ||
                ' - sujeto:' || c_lqdciones.id_sjto_impsto ||
                ' - impuesto:' || c_lqdciones.id_impsto || ' - s_vlor: ' ||
                s_vlor || ' - c_lqdciones.vlor_ttal: ' ||
                c_lqdciones.vlor_ttal;
                /*insert into genesys_interfaz.sg_g_log (col1, col2)
                values (systimestamp, v_error);
                commit;*/
                continue;
            end if;
            end if;

        end loop;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nl , 'Saliendo!!!' ,  1 );

        exception
            when others then
            --dbms_output.put_line(sqlerrm);
            v_error := 'prc_rg_liquidacion_intrfaz. Error: ' || sqlerrm;
            insert into genesys_interfaz.sg_g_log
            (col1, col2)
            values
            (systimestamp, v_error);
            commit;

    end prc_rg_liquidacion_intrfaz;

end pkg_gf_interfaz_contable_monteria;

/
