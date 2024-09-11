--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION" as

    function fnc_ge_homologacion( p_cdgo_clnte in number 
                                , p_id_entdad  in number )
    return r_hmlgcion
    is
        v_hmlgcion r_hmlgcion := r_hmlgcion();
    begin
        for c_hmlgcion in (  
                             select to_number( replace( a.nmbre_clmna_orgen , 'CLMNA' )) as clmna
                                  , a.nmbre_clmna_orgen
                                  , trim(b.vlor_orgen) as vlor_orgen
                                  , trim(b.vlor_dstno) as vlor_dstno
                               from migra.mg_d_columnas a
                               join migra.mg_d_homologacion b
                                 on a.id_clmna   = b.id_clmna
                              where b.cdgo_clnte = p_cdgo_clnte
                                and a.id_entdad  = p_id_entdad
                          ) 
        loop
            v_hmlgcion( c_hmlgcion.clmna || c_hmlgcion.vlor_orgen ) := c_hmlgcion;
        end loop;
        
        return v_hmlgcion;
    end fnc_ge_homologacion;
    
    function fnc_co_homologacion( p_clmna    in number 
                                , p_vlor     in varchar2 
                                , p_hmlgcion in r_hmlgcion )
    return varchar2
    is
        v_llave varchar2(4000) := ( p_clmna || p_vlor );
    begin
    
        if( not p_hmlgcion.exists( v_llave )) then 
            return p_vlor;
        end if;
        
        return p_hmlgcion(v_llave).vlor_dstno;
    end fnc_co_homologacion;
    
    --Funcion que nace desde declaraciones
    function fnc_gn_mg_g_intermedia (p_cursor in t_mg_g_intermedia_cursor) return t_mg_g_intermedia_tab pipelined
        parallel_enable(partition p_cursor by hash (clmna2)) is
        
        v_prueba  pkg_mg_migracion.t_mg_g_intermedia_tab;
        
    begin
        loop fetch p_cursor bulk collect into v_prueba limit 2000;
            exit when v_prueba.count = 0;
            for i in 1 .. v_prueba.count loop
                pipe row(v_prueba(i));
            end loop;
        end loop;
    end fnc_gn_mg_g_intermedia;
    
    procedure prc_mg_periodos ( p_id_entdad          in number
                              , p_id_prcso_instncia  in number
                              , p_id_usrio           in number
                              , p_cdgo_clnte         in number
                              , o_ttal_extsos        out number
                              , o_ttal_error         out number
                              , o_cdgo_rspsta        out number
                              , o_mnsje_rspsta       out varchar2 ) as
        
        -- Variables de Valores Fijos
        v_cdgo_clnte        number                  := p_cdgo_clnte;
        --v_cdgo_impsto       varchar2(5)             := 'IPU';
        --v_cdgo_prdcdad      varchar2(3)             := 'ANU';

        -- Variables para consulta de valores
        v_id_impsto             df_i_periodos.id_impsto%type;
        v_id_impsto_sbmpsto     df_i_periodos.id_impsto_sbmpsto%type;
        
        v_errors r_errors := r_errors();
        v_hmlgcion   r_hmlgcion;
    begin
        o_ttal_extsos   := 0;
        o_ttal_error    := 0;
        
        --Carga los Datos de la Homologacion
        v_hmlgcion := fnc_ge_homologacion( p_cdgo_clnte => p_cdgo_clnte
                                         , p_id_entdad  => p_id_entdad );
        
        insert into gti_aux (col1, col2) values ('Entro prc_mg_periodos', to_date(sysdate));
        
        for c_intrmdia in (select * from migra.MG_G_INTERMEDIA_ICA_ESTABLEC where id_entdad = p_id_entdad and cdgo_estdo_rgstro = 'L') loop
            -- Se consulta el id_impsto
            begin
                select id_impsto
                  into v_id_impsto
                  from df_c_impuestos
                 where cdgo_clnte   = v_cdgo_clnte
                   and cdgo_impsto  = c_intrmdia.clmna1;
            exception
                when others then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta  := 'Error al consultar el id del impuesto. ' || sqlcode || ' -- ' || sqlerrm;
                    insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            -- Consulta de id del subimpuesto
            begin
                select id_impsto_sbmpsto
                  into v_id_impsto_sbmpsto
                  from df_i_impuestos_subimpuesto
                 where id_impsto            = v_id_impsto
                   and cdgo_impsto_sbmpsto  = c_intrmdia.clmna2;  --v_cdgo_impsto
            exception
                when others then
                    o_ttal_error := o_ttal_error  + 1;
                    o_cdgo_rspsta   := 2;
                    o_mnsje_rspsta  := 'Error al consultar el id del subimpuesto con codigo: ' || c_intrmdia.clmna3 || ' -- ' || sqlcode || ' -- ' || sqlerrm;
                    insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
            end;
            -- Insert de perido
            if v_id_impsto_sbmpsto is not null then
                begin
                    
                    --Homologacion de Clasificacion
                    c_intrmdia.clmna6:= fnc_co_homologacion( p_clmna => 6 , p_vlor => c_intrmdia.clmna6 , p_hmlgcion => v_hmlgcion );
                        
                    insert into df_i_periodos (cdgo_clnte,                          id_impsto,          id_impsto_sbmpsto,              vgncia,
                                               prdo,                                dscrpcion,          cdgo_prdcdad,                   fcha_vncmnto)
                                       values (v_cdgo_clnte,                        v_id_impsto,        v_id_impsto_sbmpsto,            to_number(c_intrmdia.clmna3),
                                               to_number(c_intrmdia.clmna4),        c_intrmdia.clmna5,  c_intrmdia.clmna6,                 to_date(c_intrmdia.clmna7, 'DD/MM/YYYY'));
                    o_ttal_extsos   := o_ttal_extsos + 1;
                exception
                    when others then
                        o_ttal_error := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 3;
                        o_mnsje_rspsta  := 'Error al insertar el periodo. Vigencia: ' || c_intrmdia.clmna1 || ' Periodo: ' || c_intrmdia.clmna2 || '. Id Intermedia: ' || c_intrmdia.id_intrmdia || ' Error: ' || sqlcode || ' -- ' || sqlerrm;
                        insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
            end if;            
        end loop;
       
        -- Actualizar estado en intermedia
        begin
          
          update migra.MG_G_INTERMEDIA_ICA_ESTABLEC
             set cdgo_estdo_rgstro = 'S'
           where cdgo_clnte        = p_cdgo_clnte 
             and id_entdad         = p_id_entdad
             and cdgo_estdo_rgstro = 'L';
              
            --Procesos con Errores
            o_ttal_error := v_errors.count;
                   
            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
               
            forall j in 1..o_ttal_error
                update migra.MG_G_INTERMEDIA_ICA_ESTABLEC
                   set cdgo_estdo_rgstro = 'E'
                 where id_intrmdia       = v_errors(j).id_intrmdia
                   and cdgo_estdo_rgstro = 'L';
            
            o_cdgo_rspsta   := 0;
            o_mnsje_rspsta  := 'Se procesaron: ' || (o_ttal_error + o_ttal_extsos) || ' registros. Exitosos: ' || o_ttal_extsos || ' con error: ' || o_ttal_error;
            insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
            
        exception
            when no_data_found then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  := 'Error al actualizar el estado de los registros en la tabla de intermedia para la entidad: ' || p_id_entdad;
            insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
        end;
       
    end prc_mg_periodos;

     procedure prc_mg_impuestos_acto_concepto (p_id_entdad          in number,
                                               p_id_prcso_instncia  in number,
                                               o_ttal_extsos        out number,
                                               o_ttal_error         out number,
                                               o_cdgo_rspsta        out number,
                                               o_mnsje_rspsta       out varchar2) as
        -- Variables de Valores Fijos
        v_cdgo_clnte        number                  := 10;
        v_cdgo_impsto       varchar2(5)             := 'IPU';
        v_cdgo_prdcdad      varchar2(3)             := 'ANU';

        -- Variables para consulta de valores
        t_df_i_periodos         df_i_periodos%rowtype;
        v_id_impsto_acto        df_i_impuestos_acto_concepto.id_impsto_acto%type;
        v_id_cncpto             df_i_impuestos_acto_concepto.id_cncpto%type;
        v_id_cncpto_intres_mra  df_i_impuestos_acto_concepto.id_cncpto_intres_mra%type;
        
        v_errors r_errors := r_errors();

    begin
        for c_intrmdia in (select * from mg_g_intermedia where id_entdad = p_id_entdad) loop            
            -- Se consulta el id del periodo
            begin
                select *
                  into t_df_i_periodos
                  from df_i_periodos 
                 where cdgo_clnte   = v_cdgo_clnte
                   and vgncia       = c_intrmdia.clmna1
                   and prdo         = c_intrmdia.clmna2;
                -- Se consulta el id impuesto acto
                begin
                    select id_impsto_acto
                      into v_id_impsto_acto
                      from df_i_impuestos_acto
                     where id_impsto            = t_df_i_periodos.id_impsto
                       and id_impsto_sbmpsto    = t_df_i_periodos.id_impsto_sbmpsto
                       and cdgo_impsto_acto     = c_intrmdia.clmna3;
                exception
                    when others then
                        o_ttal_error    := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 2;
                        o_mnsje_rspsta  := 'Error al consultar el id del impuesto acto. ' || sqlcode || ' -- ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;    
                end;
                -- Se consulta el id del concepto
                begin
                    select id_cncpto
                      into v_id_cncpto
                      from df_i_conceptos
                     where cdgo_clnte       = v_cdgo_clnte
                       and id_impsto        = t_df_i_periodos.id_impsto
                       and cdgo_cncpto      = c_intrmdia.clmna4;
                exception
                    when others then
                        o_ttal_error    := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 3;
                        o_mnsje_rspsta  := 'Error al consultar el id del concepto. ' || sqlcode || ' -- ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;    
                end;
                -- Se consulta el id del concepto de interes de mora si la columna que contiene 
                -- el codigo del concepto de interes de mora no es nulo
                if c_intrmdia.clmna9 is not null then
                    begin
                        select id_cncpto
                          into v_id_cncpto_intres_mra
                          from df_i_conceptos
                         where cdgo_clnte       = v_cdgo_clnte
                           and id_impsto        = t_df_i_periodos.id_impsto
                           and cdgo_cncpto      = c_intrmdia.clmna9;
                    exception
                        when others then
                            o_ttal_error    := o_ttal_error  + 1;
                            o_cdgo_rspsta   := 4;
                            o_mnsje_rspsta  := 'Error al consultar el id del concepto de interes de mor. ' || sqlcode || ' -- ' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;    
                    end;
                end if;

                if t_df_i_periodos.id_prdo is not null and v_id_impsto_acto is not null and v_id_cncpto is not null then
                -- Se inserta el impuesto acto concepto
                    begin
                        insert into df_i_impuestos_acto_concepto (cdgo_clnte,                   vgncia,                 id_prdo,                    id_impsto_acto,
                                                                  id_cncpto,                    actvo,                  gnra_intres_mra,            indcdor_trfa_crctrstcas,
                                                                  fcha_vncmnto,                 id_cncpto_intres_mra)   
                                                           values (v_cdgo_clnte,                c_intrmdia.clmna1,      t_df_i_periodos.id_prdo,    v_id_impsto_acto,
                                                                   v_id_cncpto,                 c_intrmdia.clmna5,      c_intrmdia.clmna6,          c_intrmdia.clmna7,
                                                                   to_date(c_intrmdia.clmna8),  v_id_cncpto_intres_mra );

                        o_ttal_extsos   := o_ttal_extsos + 1;
                        o_cdgo_rspsta   := 0;
                        o_mnsje_rspsta  := 'Se inserto el impuesto acto concepto exitosamente';
                    exception
                        when others then 
                            o_ttal_error := o_ttal_error  + 1;
                            o_cdgo_rspsta   := 5;
                            o_mnsje_rspsta  := 'Error al insertar el impuesto acto concepto. ' || sqlcode || ' -- ' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;    
                    end;
                end if;
            exception
                when others then 
                    o_ttal_error := o_ttal_error  + 1;
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta  := 'Error al consultar el periodo. ' || sqlcode || ' -- ' || sqlerrm;
                    v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;    
            end;
        end loop;
        
        -- Actualizar estado en intermedia
        begin
            update migra.MG_G_INTERMEDIA_ICA_ESTABLEC
              set cdgo_estdo_rgstro = 'S'
            where id_entdad         = p_id_entdad
              and cdgo_estdo_rgstro = 'L';
              
            --Procesos con Errores
            o_ttal_error := v_errors.count;
                   
            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
               
            forall j in 1..o_ttal_error
                update migra.MG_G_INTERMEDIA_ICA_ESTABLEC
                   set cdgo_estdo_rgstro = 'E'
                 where id_intrmdia       = v_errors(j).id_intrmdia
                   and cdgo_estdo_rgstro = 'L';
        exception
            when no_data_found then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  := 'Error al actualizar el estado de los registros en la tabla de intermedia para la entidad: ' || p_id_entdad;
        end;
    end prc_mg_impuestos_acto_concepto;

    /* procedure prc_mg_tarifa_esquema ( p_id_entdad          in number,
                                       p_id_prcso_instncia  in number,
                                       p_id_usrio           in number,
                                       o_ttal_extsos        out number,
                                       o_ttal_error         out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2) as

        -- Variables de Valores Fijos
        v_cdgo_clnte        number                  := 6;

        -- Variables para consulta de valores
        v_id_impsto                     gi_d_tarifas_esquema.id_impsto%type;
        v_id_impsto_sbmpsto             gi_d_tarifas_esquema.id_impsto_sbmpsto%type;
        v_id_impsto_acto_cncpto         gi_d_tarifas_esquema.id_impsto_sbmpsto%type;
        v_id_impsto_acto_cncpto_bse     gi_d_tarifas_esquema.id_impsto_sbmpsto%type;
        v_id_indcdor_ecnmco             gi_d_tarifas_esquema.id_impsto_sbmpsto%type;
        
        v_errors r_errors := r_errors();


    begin
        for c_intrmdia in (select * from migra.MG_G_INTERMEDIA_ICA_ESTABLEC where id_entdad = p_id_entdad) loop
            -- Se consulta el id del impuesto, subimpuesto, impuesto acto concepto
            begin
                select id_impsto,   id_impsto_sbmpsto,      id_impsto_acto_cncpto
                  into v_id_impsto, v_id_impsto_sbmpsto,    v_id_impsto_acto_cncpto
                  from v_df_i_impuestos_acto_concepto
                 where cdgo_clnte           = v_cdgo_clnte
                   and cdgo_impsto          = c_intrmdia.clmna1
                   and cdgo_impsto_sbmpsto  = c_intrmdia.clmna2
                   and cdgo_impsto_acto     = c_intrmdia.clmna3
                   and vgncia               = c_intrmdia.clmna4
                   and prdo                 = c_intrmdia.clmna5
                   and cdgo_cncpto          = c_intrmdia.clmna6;

                -- Se consulta el id del impuesto acto concepto base si la columna que contiene el codigo del concepto base no es nulo
                if c_intrmdia.clmna7 is not null then 
                    begin
                        select id_impsto_acto_cncpto
                          into v_id_impsto_acto_cncpto_bse
                          from v_df_i_impuestos_acto_concepto
                         where cdgo_clnte           = v_cdgo_clnte
                           and cdgo_impsto          = c_intrmdia.clmna1
                           and cdgo_impsto_sbmpsto  = c_intrmdia.clmna2
                           and cdgo_impsto_acto     = c_intrmdia.clmna3
                           and vgncia               = c_intrmdia.clmna4
                           and prdo                 = c_intrmdia.clmna5
                           and cdgo_cncpto          = c_intrmdia.clmna7;
                    exception
                        when others then
                            o_ttal_error := o_ttal_error  + 1;
                            o_cdgo_rspsta   := 2;
                            o_mnsje_rspsta  := 'Error al consultar el id del impuesto acto concepto base . ' || sqlcode || ' -- ' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;

                -- Se consulta el id del indicador economico si la columa que contiene el codigo del indicador economico no es nulo
                if c_intrmdia.clmna7 is not null then 
                    begin
                        select id_indcdor_ecnmco
                          into v_id_indcdor_ecnmco
                          from df_s_indicadores_economico a
                         where cdgo_indcdor_tpo = c_intrmdia.clmna14
                           and trunc(fcha_dsde) <= trunc(to_date(c_intrmdia.clmna16))
                           and trunc(fcha_hsta) >= trunc(to_date(c_intrmdia.clmna17));
                    exception
                        when others then
                            o_ttal_error := o_ttal_error  + 1;
                            o_cdgo_rspsta   := 3;
                            o_mnsje_rspsta  := 'Error al consultar el id del indicador economico. ' || sqlcode || ' -- ' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                -- Se inserta tarifa esquema
                begin
                   insert into gi_d_tarifas_esquema (cdgo_clnte,                        id_impsto,                          id_impsto_sbmpsto,              id_impsto_acto_cncpto,
                                                     id_impsto_acto_cncp_bse,           rdndeo,                             bse_incial,                     bse_fnal,
                                                     vlor_trfa,                         lqdcion_mnma,                       lqdcion_mxma,                   id_indcdor_ecnmco,
                                                     indcdr_usa_fcha_lqdcion,           fcha_incial,                        fcha_fnal,                      indcdor_usa_bse,
                                                     txto_trfa)
                                             values (v_cdgo_clnte,                      v_id_impsto,                        v_id_impsto_sbmpsto,            v_id_impsto_acto_cncpto,
                                                     v_id_impsto_acto_cncpto_bse,       to_number(c_intrmdia.clmna8),       to_number(c_intrmdia.clmna9),   to_number(c_intrmdia.clmna10),
                                                     to_number(c_intrmdia.clmna11),     to_number(c_intrmdia.clmna12),      to_number(c_intrmdia.clmna13),  v_id_indcdor_ecnmco,
                                                     c_intrmdia.clmna15,                to_date(c_intrmdia.clmna16),        to_date(c_intrmdia.clmna17),    c_intrmdia.clmna18,
                                                     c_intrmdia.clmna19);
                    o_ttal_extsos   := o_ttal_extsos + 1;
                    o_cdgo_rspsta   := 0;
                    o_mnsje_rspsta  := 'Se inserto tarifa esquema exitosamente';
                exception
                    when others then
                        o_ttal_error := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 4;
                        o_mnsje_rspsta  := 'Error al insertar tarifa esquema. ' || sqlcode || ' -- ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;   
            exception
                when others then
                    o_ttal_error := o_ttal_error  + 1;
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta  := 'Error al consultar el id del impuesto y el subimpuesto. ' || sqlcode || ' -- ' || sqlerrm;
                    v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;
            end;
        end loop;
        
        -- Actualizar estado en intermedia
        begin
            update migra.mg_g_intermedia
              set cdgo_estdo_rgstro = 'S'
            where id_entdad         = p_id_entdad
              and cdgo_estdo_rgstro = 'L';
              
            --Procesos con Errores
            o_ttal_error := v_errors.count;
                   
            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
               
            forall j in 1..o_ttal_error
                update migra.mg_g_intermedia
                   set cdgo_estdo_rgstro = 'E'
                 where id_intrmdia       = v_errors(j).id_intrmdia
                   and cdgo_estdo_rgstro = 'L';
        exception
            when no_data_found then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  := 'Error al actualizar el estado de los registros en la tabla de intermedia para la entidad: ' || p_id_entdad;
        end;
    end prc_mg_tarifa_esquema; */

  /*   procedure prc_mg_funcionarios(p_id_entdad          in number,
                                   p_id_prcso_instncia  in number,
                                   o_ttal_extsos        out number,
                                   o_ttal_error         out number,
                                   o_cdgo_rspsta        out number,
                                   o_mnsje_rspsta       out varchar2) as

        -- Variables de Valores Fijos
        v_cdgo_clnte        number                  := 6;

        -- Variables para consulta de valores
        t_v_df_s_municipios         v_df_s_municipios%rowtype;
        v_id_trcro                  si_c_terceros.id_mncpio%type;
        
        v_errors r_errors := r_errors();

    begin
        for c_intrmdia in (select * from migra.mg_g_intermedia where id_entdad = p_id_entdad) loop
            -- Se consulta el id del pais, departamento y municipio
            if c_intrmdia.clmna8 is not null and c_intrmdia.clmna9 is not null and c_intrmdia.clmna10 is not null then
                begin
                    select *
                      into t_v_df_s_municipios
                      from v_df_s_municipios
                     where cdgo_pais        = c_intrmdia.clmna8
                       and cdgo_dprtmnto    = c_intrmdia.clmna9
                       and cdgo_mncpio      = c_intrmdia.clmna10;
                exception
                    when others then
                        o_ttal_error := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 1;
                        o_mnsje_rspsta  := 'Error al consultar el id del pais, departamento y municipio. ' || sqlcode || ' -- ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
            end if;
            -- Se inserta el Tercero
            begin
                insert into si_c_terceros (cdgo_clnte,                      cdgo_idntfccion_tpo,                    idntfccion,                         prmer_nmbre,
                                           sgndo_nmbre,                     prmer_aplldo,                           sgndo_aplldo,                       drccion,
                                           id_pais,                         id_dprtmnto,                            id_mncpio,                          drccion_ntfccion,
                                           id_pais_ntfccion,                id_dprtmnto_ntfccion,                   id_mncpio_ntfccion,                 email,
                                           tlfno,                           cllar)
                                   values (v_cdgo_clnte,                    c_intrmdia.clmna1,                      c_intrmdia.clmna2,                  c_intrmdia.clmna3,
                                           c_intrmdia.clmna4,               c_intrmdia.clmna5,                      c_intrmdia.clmna6,                  c_intrmdia.clmna7,
                                           t_v_df_s_municipios.id_pais,     t_v_df_s_municipios.id_dprtmnto,        t_v_df_s_municipios.id_mncpio,      c_intrmdia.clmna7,
                                           t_v_df_s_municipios.id_pais,     t_v_df_s_municipios.id_dprtmnto,        t_v_df_s_municipios.id_mncpio,      c_intrmdia.clmna11,
                                           c_intrmdia.clmna12,              c_intrmdia.clmna13)
                  returning id_trcro into v_id_trcro;

                begin
                    insert into df_c_funcionarios (cdgo_clnte,              id_trcro,           actvo)
                                           values (v_cdgo_clnte,            v_id_trcro,         'S');

                    o_ttal_extsos   := o_ttal_extsos + 1;
                    o_cdgo_rspsta   := 0;
                    o_mnsje_rspsta  := 'Se inserto el tercero/funcionario exitosamente';
                exception
                    when others then
                        o_ttal_error := o_ttal_error  + 1;
                        o_cdgo_rspsta   := 3;
                        o_mnsje_rspsta  := 'Error al insertar el Funcionario. ' || sqlcode || ' -- ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
            exception
                when others then
                    o_ttal_error := o_ttal_error  + 1;
                    o_cdgo_rspsta   := 2;
                    o_mnsje_rspsta  := 'Error al insertar el Tercero. ' || sqlcode || ' -- ' || sqlerrm;
                    continue;
                    v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_intrmdia.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
            end;
        end loop;
        
        -- Actualizar estado en intermedia
        begin
            update migra.mg_g_intermedia
              set cdgo_estdo_rgstro = 'S'
            where id_entdad         = p_id_entdad
              and cdgo_estdo_rgstro = 'L';
              
            --Procesos con Errores
            o_ttal_error := v_errors.count;
                   
            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                             values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
               
            forall j in 1..o_ttal_error
                update migra.mg_g_intermedia
                   set cdgo_estdo_rgstro = 'E'
                 where id_intrmdia       = v_errors(j).id_intrmdia;
        exception
            when no_data_found then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  := 'Error al actualizar el estado de los registros en la tabla de intermedia para la entidad: ' || p_id_entdad;
        end;
    end prc_mg_funcionarios;*/

     procedure prc_mg_indicadores_economicos ( p_id_entdad          in number,
                                               p_id_prcso_instncia  in number,
                                               o_ttal_extsos        out number,
                                               o_ttal_error         out number,
                                               o_cdgo_rspsta        out number,
                                               o_mnsje_rspsta       out varchar2)as

    begin
        null;
    end prc_mg_indicadores_economicos;   
    
    /*Up Para Migrar Predios*/
   /* procedure prc_mg_predios( p_id_entdad         in  number
                            , p_id_prcso_instncia in  number
                            , p_id_usrio          in  number
                            , p_cdgo_clnte        in  number
                            , o_ttal_extsos       out number
                            , o_ttal_error        out number
                            , o_cdgo_rspsta       out number
                            , o_mnsje_rspsta      out varchar2 ) 
    as
        v_hmlgcion          r_hmlgcion;
        v_errors            r_errors := r_errors();
        v_id_sjto           si_c_sujetos.id_sjto%type;
        v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_df_s_clientes     df_s_clientes%rowtype;
        v_id_sjto_estdo     df_s_sujetos_estado.id_sjto_estdo%type;
        v_id_impsto         df_c_impuestos.id_impsto%type;
        v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
        v_mg_g_intrmdia     r_mg_g_intrmdia;
        v_prdio             r_mg_g_intrmdia := r_mg_g_intrmdia();
        
        type t_intrmdia_rcrd is record
        (
           r_rspnsbles r_mg_g_intrmdia := r_mg_g_intrmdia() 
        );
     
        type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);
        v_intrmdia_rcrd g_intrmdia_rcrd;
    begin
        
        --Limpia la Cache
        dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.';
                  return;
        end;

        --Carga los Datos de la Homologacion
        v_hmlgcion := fnc_ge_homologacion( p_cdgo_clnte => p_cdgo_clnte
                                         , p_id_entdad  => p_id_entdad );
        
        --Llena la Coleccion de Intermedia
        select a.*
          bulk collect  
          into v_mg_g_intrmdia
          from migra.mg_g_intermedia a
         where a.cdgo_clnte        = p_cdgo_clnte 
           and a.id_entdad         = p_id_entdad
           and a.cdgo_estdo_rgstro = 'L'
      order by a.clmna4;
        
        --Verifica si hay Registros Cargado
        if( v_mg_g_intrmdia.count = 0 ) then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
          return;  
        end if;
        
        --Llena la Coleccion de Predio Responsables
        for i in 1..v_mg_g_intrmdia.count loop
            
            --Identificacion Predio en Caso de Nulo
            v_mg_g_intrmdia(i).clmna4 := nvl( v_mg_g_intrmdia(i).clmna4 , v_mg_g_intrmdia(i).clmna5 );

            declare
                v_index number;
            begin
              if( i = 1 or (i > 1 and v_mg_g_intrmdia(i).clmna4 <> v_mg_g_intrmdia(i-1).clmna4 )) then                  
                  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4) := t_intrmdia_rcrd();
                  v_prdio.extend;
                  v_prdio(v_prdio.count) :=  v_mg_g_intrmdia(i);
              end if;
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles.extend;
              v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles.count;
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles(v_index) := v_mg_g_intrmdia(i);
            end;
        end loop;
        
        --Verifica si el Impuesto o SubImpuesto Existe        
        declare
            v_cdgo_impsto         varchar2(10) := v_prdio(v_prdio.first).clmna2;
            v_cdgo_impsto_sbmpsto varchar2(10) := v_prdio(v_prdio.first).clmna3;
        begin
           select a.id_impsto
                , b.id_impsto_sbmpsto
             into v_id_impsto
                , v_id_impsto_sbmpsto
             from df_c_impuestos a
             join df_i_impuestos_subimpuesto b
               on a.id_impsto           = b.id_impsto
            where a.cdgo_clnte          = p_cdgo_clnte
              and a.cdgo_impsto         = v_cdgo_impsto
              and b.cdgo_impsto_sbmpsto = v_cdgo_impsto_sbmpsto;
        exception
             when no_data_found then 
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El impuesto o subImpuesto, no existe en el sistema.';
                  return;
        end;

        for c_prdios in (
                            select id_intrmdia
                                 , clmna4  --Identificacion Predio
                                 , clmna5  --Identificacion Predio Anterior
                                 , clmna6  --Pais 
                                 , clmna7  --Departamento
                                 , clmna8  --Municipio
                                 , clmna9  --Direccion
                                 , clmna10 --Fecha Ingreso Predio
                                 , clmna11 --Pais Notificacion
                                 , clmna12 --Departamento Notificacion
                                 , clmna13 --Municipio Notificacion
                                 , clmna14 --Direccion Notificacion
                                 , clmna15 --Email
                                 , clmna16 --Telefono
                                 , clmna17 --Estado Predio
                                 , clmna18 --Fecha Ultima Novedad
                                 , clmna19 --Fecha Cancelacion
                                 , clmna20 --Codigo Clasificacion 
                                 , clmna21 --Codigo Destino
                                 , clmna22 --Codigo Estrato
                                 , clmna23 --Codigo Uso Suelo
                                 , clmna24 --Codigo Destino Igac
                                 , clmna25 --Avaluo
                                 , clmna26 --Avaluo Comercial
                                 , clmna27 --Area Terreno
                                 , clmna28 --Area Construida
                                 , clmna29 --Matricula
                                 , clmna30 --Latitud
                                 , clmna31 --Longitud
                              from table( v_prdio )
                        ) 
        loop
            
            --Homologacion de Departamento
            c_prdios.clmna7  := fnc_co_homologacion( p_clmna => 7  , p_vlor => c_prdios.clmna7  , p_hmlgcion => v_hmlgcion );
            --Homologacion de Municipio
            c_prdios.clmna8  := fnc_co_homologacion( p_clmna => 8  , p_vlor => c_prdios.clmna8  , p_hmlgcion => v_hmlgcion );
            
            --Homologacion de Departamento Notificacion
            c_prdios.clmna12 := fnc_co_homologacion( p_clmna => 12 , p_vlor => c_prdios.clmna12 , p_hmlgcion => v_hmlgcion );
            --Homologacion de Municipio Notificacion
            c_prdios.clmna13 := fnc_co_homologacion( p_clmna => 13 , p_vlor => c_prdios.clmna13 , p_hmlgcion => v_hmlgcion );

            --Homologacion de Estado
            c_prdios.clmna17 := fnc_co_homologacion( p_clmna => 17 , p_vlor => c_prdios.clmna17 , p_hmlgcion => v_hmlgcion );
            
            --Homologacion de Clasificacion
            c_prdios.clmna20 := fnc_co_homologacion( p_clmna => 20 , p_vlor => c_prdios.clmna20 , p_hmlgcion => v_hmlgcion );
            --Homologacion de Destino
            c_prdios.clmna21 := fnc_co_homologacion( p_clmna => 21 , p_vlor => c_prdios.clmna21 , p_hmlgcion => v_hmlgcion );
            --Homologacion de Estrato
            c_prdios.clmna22 := fnc_co_homologacion( p_clmna => 22 , p_vlor => c_prdios.clmna22 , p_hmlgcion => v_hmlgcion );
            --Homologacion de Uso Suelo
            c_prdios.clmna23 := fnc_co_homologacion( p_clmna => 23 , p_vlor => c_prdios.clmna23 , p_hmlgcion => v_hmlgcion );
            --Homologacion de Destino Igac
            c_prdios.clmna24 := fnc_co_homologacion( p_clmna => 24 , p_vlor => c_prdios.clmna24 , p_hmlgcion => v_hmlgcion );

            --Identificacion Predio Anterior
            c_prdios.clmna5 := nvl( c_prdios.clmna5 , c_prdios.clmna4 );
                    
            declare
                --Consulta Pais
                function fnc_co_pais( p_cdgo_pais in varchar2 )
                return number
                is
                    v_id_pais df_s_paises.id_pais%type;
                begin
                    
                    if( p_cdgo_pais is null ) then 
                        return v_df_s_clientes.id_pais;
                    end if;
                    
                    select 
                           id_pais 
                      into v_id_pais
                      from df_s_paises
                     where cdgo_pais = p_cdgo_pais;
                     
                     return v_id_pais;
                exception
                     when no_data_found then    
                          o_cdgo_rspsta  := 4;
                          o_mnsje_rspsta := o_cdgo_rspsta || '. El pais con codigo #' || p_cdgo_pais || ', no existe en el sistema.';
                          v_errors.extend;  
                          v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                          return null;
                end fnc_co_pais;
            
                --Consulta Departamento
                function fnc_co_departamento( p_cdgo_dprtmnto in varchar2 
                                            , p_id_pais       in df_s_paises.id_pais%type )
                return number
                is
                    v_id_dprtmnto df_s_departamentos.id_dprtmnto%type;
                begin
                    
                    if( p_cdgo_dprtmnto is null ) then 
                        return v_df_s_clientes.id_dprtmnto;
                    end if;
                    
                    select 
                           id_dprtmnto 
                      into v_id_dprtmnto
                      from df_s_departamentos
                     where cdgo_dprtmnto = p_cdgo_dprtmnto
                       and id_pais       = p_id_pais;
                     
                     return v_id_dprtmnto;
                exception
                     when no_data_found then    
                          o_cdgo_rspsta  := 5;
                          o_mnsje_rspsta := o_cdgo_rspsta || '. El departamento con codigo #' || p_cdgo_dprtmnto || ', no existe en el sistema.';
                          v_errors.extend;  
                          v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                          return null;
                end fnc_co_departamento;
            
                --Consultar Municipio
                function fnc_co_municipio( p_cdgo_mncpio in varchar2 
                                         , p_id_dprtmnto in df_s_departamentos.id_dprtmnto%type )
                return number
                is
                    v_id_mncpio df_s_municipios.id_mncpio%type;
                begin
                    
                    if( p_cdgo_mncpio is null ) then
                        return v_df_s_clientes.id_mncpio; 
                    end if;
                    
                    select 
                           id_mncpio 
                      into v_id_mncpio
                      from df_s_municipios
                     where cdgo_mncpio = p_cdgo_mncpio
                       and id_dprtmnto = p_id_dprtmnto;
                     
                     return v_id_mncpio;
                exception
                     when no_data_found then    
                          o_cdgo_rspsta  := 6;
                          o_mnsje_rspsta := o_cdgo_rspsta || '. El municipio con codigo #' || p_cdgo_mncpio || ', no existe en el sistema.';
                          v_errors.extend;  
                          v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                          return null;
                end fnc_co_municipio;
            
            begin    
                --Pais 
                c_prdios.clmna6 := fnc_co_pais( p_cdgo_pais => c_prdios.clmna6 );
                if( c_prdios.clmna6 is null ) then 
                    continue;
                end if;
                
                --Departamento
                c_prdios.clmna7 := fnc_co_departamento( p_cdgo_dprtmnto => c_prdios.clmna7 
                                                      , p_id_pais       => c_prdios.clmna6 ); 
                if( c_prdios.clmna7 is null ) then 
                    continue;
                end if;
                
                --Municipio
                c_prdios.clmna8 := fnc_co_municipio( p_cdgo_mncpio => c_prdios.clmna8 
                                                   , p_id_dprtmnto => c_prdios.clmna7 );
                if( c_prdios.clmna8 is null ) then 
                    continue;
                end if;
                
                --Pais Notificacion        
                c_prdios.clmna11 := ( case when c_prdios.clmna11 is null then 
                                            c_prdios.clmna6
                                      else
                                            fnc_co_pais( p_cdgo_pais => c_prdios.clmna11 )
                                      end );
                
                if( c_prdios.clmna11 is null ) then 
                    continue;
                end if;
                
                --Departamento Notificacion
                c_prdios.clmna12 := ( case when c_prdios.clmna12 is null then 
                                            c_prdios.clmna7
                                      else
                                            fnc_co_departamento( p_cdgo_dprtmnto => c_prdios.clmna12
                                                               , p_id_pais       => c_prdios.clmna11 )
                                      end );
                
                if( c_prdios.clmna12 is null ) then 
                    continue;
                end if;
                
                --Municipio Notificacion
                c_prdios.clmna13 := ( case when c_prdios.clmna13 is null then 
                                            c_prdios.clmna8
                                      else
                                            fnc_co_municipio( p_cdgo_mncpio => c_prdios.clmna13 
                                                            , p_id_dprtmnto => c_prdios.clmna12 )
                                      end );
                
                if( c_prdios.clmna13 is null ) then 
                    continue;
                end if;
            end;
        
            --Direccion Notificacion
            c_prdios.clmna14 := nvl( c_prdios.clmna14 , c_prdios.clmna9 );
            
             --Verifica si Existe el Sujeto
             begin
               select id_sjto
                 into v_id_sjto
                 from si_c_sujetos 
                where cdgo_clnte = p_cdgo_clnte
                  and idntfccion = c_prdios.clmna4; 
            exception   
                 when no_data_found then
                      
                      begin
                          --Registra el Sujeto
                          insert into si_c_sujetos ( cdgo_clnte , idntfccion , idntfccion_antrior , id_pais , id_dprtmnto 
                                                   , id_mncpio , drccion , fcha_ingrso , estdo_blqdo ) 
                                            values ( p_cdgo_clnte , c_prdios.clmna4 , c_prdios.clmna5 , c_prdios.clmna6 , c_prdios.clmna7
                                                   , c_prdios.clmna8 , c_prdios.clmna9 , to_date( c_prdios.clmna10 , 'DD/MM/YYYY' ) , 'N' )
                          returning id_sjto 
                               into v_id_sjto;
                      exception
                           when others then 
                                o_cdgo_rspsta  := 7;
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible registrar el sujeto para la referencia #' || c_prdios.clmna4 || '.' || sqlerrm;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                rollback;
                                continue;              
                      end;
            end;
            
            --Verifica si Existe el Sujeto Impuesto
            begin
               select id_sjto_impsto
                 into v_id_sjto_impsto
                 from si_i_sujetos_impuesto
                where id_sjto   = v_id_sjto
                  and id_impsto = v_id_impsto;
                  
               --Determina que el Predio Existe
               o_cdgo_rspsta  := 8;
               o_mnsje_rspsta := o_cdgo_rspsta || '. el predio con referencia #' || c_prdios.clmna4 ||'. ya se encuentra registrado.' ;
               v_errors.extend;  
               v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
               continue; 
            exception   
                 when no_data_found then
                      
                       begin
                          select 
                                 id_sjto_estdo
                            into c_prdios.clmna17 
                            from df_s_sujetos_estado
                           where cdgo_sjto_estdo = c_prdios.clmna17;
                       exception 
                            when no_data_found then 
                                 o_cdgo_rspsta  := 9;
                                 o_mnsje_rspsta := o_cdgo_rspsta || '. El sujeto estado con codigo #' || c_prdios.clmna17 ||', no existe en el sistema.';
                                 v_errors.extend;  
                                 v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                 rollback;
                                 continue; 
                       end;
            
                       begin
                          --Registra el Sujeto Impuesto
                          insert into si_i_sujetos_impuesto ( id_sjto , id_impsto , id_sjto_estdo , estdo_blqdo , id_pais_ntfccion 
                                                            , id_dprtmnto_ntfccion , id_mncpio_ntfccion , drccion_ntfccion , fcha_rgstro , id_usrio
                                                            , email , tlfno , fcha_ultma_nvdad , fcha_cnclcion ) 
                                                     values ( v_id_sjto ,v_id_impsto , c_prdios.clmna17 , 'N' , c_prdios.clmna11
                                                            , c_prdios.clmna12 , c_prdios.clmna13 , c_prdios.clmna14 , systimestamp , p_id_usrio 
                                                            , c_prdios.clmna15 , c_prdios.clmna16 , to_date( c_prdios.clmna18 , 'DD/MM/YYYY' ) , to_date( c_prdios.clmna19 , 'DD/MM/YYYY' ))
                          returning id_sjto_impsto
                               into v_id_sjto_impsto;
    
                       exception
                           when others then 
                                o_cdgo_rspsta  := 10;
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible registrar el sujeto impuesto para la referencia #' || c_prdios.clmna4 || '.' || sqlerrm;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                rollback;
                                continue;     
                       end;
                       
                       --Clasificacion
                       c_prdios.clmna20 := nvl( c_prdios.clmna20  , '99' );
                       --Destino
                       c_prdios.clmna21 := nvl( c_prdios.clmna21  , '99' );
                       --Estrato
                       c_prdios.clmna22 := nvl( c_prdios.clmna22  , '99' );
                       --Uso Suelo
                       c_prdios.clmna23 := nvl( c_prdios.clmna23  , '99' );
                
                       declare
                          v_id_prdio_dstno   df_i_predios_destino.id_prdio_dstno%type;
                          v_id_prdio_uso_slo df_c_predios_uso_suelo.id_prdio_uso_slo%type;
                       begin
                        
                          --Busca el Destino del Predio
                          begin
                             select 
                                    id_prdio_dstno 
                               into v_id_prdio_dstno
                               from df_i_predios_destino
                              where cdgo_clnte = p_cdgo_clnte
                                and id_impsto  = v_id_impsto
                                and nmtcnco    = c_prdios.clmna21;
                          exception
                               when no_data_found then 
                                    o_cdgo_rspsta  := 11;
                                    o_mnsje_rspsta := o_cdgo_rspsta || '. El destino con codigo #' || c_prdios.clmna21 || ', no existe en el sistema.';
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    rollback;
                                    continue;  
                          end;
                          
                          --Busca el Uso del Predio
                          begin
                             select 
                                    id_prdio_uso_slo 
                               into v_id_prdio_uso_slo
                               from df_c_predios_uso_suelo
                              where cdgo_clnte         = p_cdgo_clnte
                                and cdgo_prdio_uso_slo = c_prdios.clmna23;
                          exception
                               when no_data_found then 
                                    o_cdgo_rspsta  := 12;
                                    o_mnsje_rspsta := o_cdgo_rspsta || '. El uso suelo con codigo #' || c_prdios.clmna23 || ', no existe en el sistema.';
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    rollback;
                                    continue;  
                          end;
                          
                          --Busca el Destino Igac
                          begin
                             select 
                                    cdgo_dstno_igac
                               into c_prdios.clmna24
                               from df_s_destinos_igac
                              where cdgo_dstno_igac = c_prdios.clmna24;
                          exception
                               when no_data_found then 
                                    c_prdios.clmna24 := 'Z';
                          end;
                          
                          --Registra el Predio
                          insert into si_i_predios ( id_sjto_impsto , id_prdio_dstno , cdgo_estrto , cdgo_dstno_igac 
                                                   , cdgo_prdio_clsfccion , id_prdio_uso_slo , avluo_ctstral , avluo_cmrcial 
                                                   , area_trrno , area_cnstrda , area_grvble , indcdor_prdio_mncpio 
                                                   , bse_grvble , lngtud , lttud , mtrcla_inmblria )
                                            values ( v_id_sjto_impsto , v_id_prdio_dstno , c_prdios.clmna22 , c_prdios.clmna24
                                                   , c_prdios.clmna20 , v_id_prdio_uso_slo , c_prdios.clmna25 , nvl( c_prdios.clmna26 , c_prdios.clmna25 ) 
                                                   , to_number(c_prdios.clmna27) , to_number(c_prdios.clmna28) , greatest( to_number(c_prdios.clmna27) , to_number(c_prdios.clmna28)) , 'S'
                                                   , c_prdios.clmna25 , c_prdios.clmna30 , c_prdios.clmna31 , c_prdios.clmna29 );
                       
                       exception
                           when others then 
                                o_cdgo_rspsta  := 13; 
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible registrar el predio para la referencia #' || c_prdios.clmna4 || '.' || sqlerrm;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := t_errors( id_intrmdia => c_prdios.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                rollback;
                                continue; 
                       end;
                       
                       --Registra Responsables del Predio
                       declare
                            a_intrmdia_rcrd r_mg_g_intrmdia := v_intrmdia_rcrd(c_prdios.clmna4).r_rspnsbles;
                       begin
                           for c_rspnsbles in (
                                                   select a.id_intrmdia
                                                        , a.clmna32 as idntfccion --Identificacion Responsable
                                                        , a.clmna33 as cdgo_idntfccion_tpo --Tipo Documento
                                                        , a.clmna34 as prmer_nmbre --Primer Nombre
                                                        , a.clmna35 as sgndo_nmbre --Segundo Nombre
                                                        , a.clmna36 as prmer_aplldo --Primer Apellido
                                                        , a.clmna37 as sgndo_aplldo --Segundo Apellido
                                                        , a.clmna38 as prncpal_s_n --Principal
                                                        , a.clmna39 as prcntje_prtcpcion --Porcentaje Participacion
                                                        , decode( a.clmna38 , 'S' , 'P' , 'R' ) as cdgo_tpo_rspnsble
                                                     from table( a_intrmdia_rcrd ) a
                                              )
                           loop
                              
                               --Homologacion de Tipo de Documento
                              c_rspnsbles.cdgo_idntfccion_tpo := fnc_co_homologacion( p_clmna => 33 , p_vlor => c_rspnsbles.cdgo_idntfccion_tpo , p_hmlgcion => v_hmlgcion );
                          
                              --Registra los Responsable del Sujeto Impuesto 
                              begin
                                  insert into si_i_sujetos_responsable( id_sjto_impsto , cdgo_idntfccion_tpo , idntfccion , prmer_nmbre , sgndo_nmbre 
                                                                      , prmer_aplldo , sgndo_aplldo , prncpal_s_n , cdgo_tpo_rspnsble , prcntje_prtcpcion , orgen_dcmnto )
                                                               values ( v_id_sjto_impsto , c_rspnsbles.cdgo_idntfccion_tpo , nvl( trim(c_rspnsbles.idntfccion) , '0' ) , nvl( trim(c_rspnsbles.prmer_nmbre) , 'No registra' ) , c_rspnsbles.sgndo_nmbre
                                                                      , nvl( trim(c_rspnsbles.prmer_aplldo) , '.' ), c_rspnsbles.sgndo_aplldo , c_rspnsbles.prncpal_s_n , c_rspnsbles.cdgo_tpo_rspnsble , nvl( c_rspnsbles.prcntje_prtcpcion , 0 ) , p_id_usrio );
                                  
                                  --Indicador de Registros Exitosos
                                  o_ttal_extsos := o_ttal_extsos + 1;
                              exception
                                   when others then  
                                        o_cdgo_rspsta  := 14; 
                                        o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible registrar el responsable con identificacion #' || c_rspnsbles.idntfccion ||' para la referencia #' || c_prdios.clmna4 || '.' || sqlerrm;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := t_errors( id_intrmdia => c_rspnsbles.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                        rollback;
                                        exit; 
                              end;
                           end loop;
                       end; 
            end;
                                          
            --Se hace Commit por Cada Predio
            commit;
                   
        end loop;
        
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'S'
         where cdgo_clnte        = p_cdgo_clnte 
           and id_entdad         = p_id_entdad
           and cdgo_estdo_rgstro = 'L';
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                         values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
        
        forall j in 1..o_ttal_error
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia       = v_errors(j).id_intrmdia;
    
    exception   
         when others then
              o_cdgo_rspsta  := 15; 
              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible realizar la migracion de predio.' || sqlerrm;
    end prc_mg_predios;
    
    */
    /*Up Para Migrar Liquidaciones de Predio*/
  /*  procedure prc_mg_lqdcnes_prdio( p_id_entdad         in  number
                                  , p_id_prcso_instncia in  number
                                  , p_id_usrio          in  number
                                  , p_cdgo_clnte        in  number
                                  , o_ttal_extsos       out number
                                  , o_ttal_error        out number
                                  , o_cdgo_rspsta       out number
                                  , o_mnsje_rspsta      out varchar2 )
    as
        v_hmlgcion          r_hmlgcion;
        v_errors            r_errors := r_errors();
        v_cdgo_clnte        df_s_clientes.cdgo_clnte%type;
        v_id_impsto         df_c_impuestos.id_impsto%type;
        v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
        v_id_lqdcion_tpo    df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
        
        type t_vgncias is record 
        (
            vgncia              number,
            prdo                number,
            cdgo_impsto         varchar2(10),
            cdgo_impsto_sbmpsto varchar2(10)
        );
        
        type g_vgncias is table of t_vgncias;
        v_vgncias g_vgncias;
    begin
        
        --Limpia la Cache
        dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.cdgo_clnte
              into v_cdgo_clnte
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.';
                  return;
        end;

        --Carga los Datos de la Homologacion
        v_hmlgcion := fnc_ge_homologacion( p_cdgo_clnte => p_cdgo_clnte
                                         , p_id_entdad  => p_id_entdad );
                                 
        --Llena la Coleccion de Vigencias
        select a.clmna4
             , a.clmna5
             , a.clmna2
             , a.clmna3
          bulk collect
          into v_vgncias 
          from migra.mg_g_intermedia a
         where a.cdgo_clnte        = p_cdgo_clnte
           and a.id_entdad         = p_id_entdad
           and a.clmna4          not in ( '2019' , '2020' )
           and a.cdgo_estdo_rgstro = 'L'
      group by a.clmna4
             , a.clmna5
             , a.clmna2
             , a.clmna3
      order by a.clmna4;                              

        --Verifica si hay Registros Cargado
        if( v_vgncias.count = 0 ) then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
            return;
        end if;
        
        --Verifica si el Impuesto o SubImpuesto Existe 
        begin
           select a.id_impsto
                , b.id_impsto_sbmpsto
             into v_id_impsto
                , v_id_impsto_sbmpsto
             from df_c_impuestos a
             join df_i_impuestos_subimpuesto b
               on a.id_impsto           = b.id_impsto
            where a.cdgo_clnte          = p_cdgo_clnte
              and a.cdgo_impsto         = v_vgncias(1).cdgo_impsto
              and b.cdgo_impsto_sbmpsto = v_vgncias(1).cdgo_impsto_sbmpsto;
        exception
             when no_data_found then 
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El impuesto o subImpuesto, no existe en el sistema.';
                  return;
        end;
        
        --Se Busca el Tipo Migracion
        begin
            select id_lqdcion_tpo
              into v_id_lqdcion_tpo
              from df_i_liquidaciones_tipo 
             where cdgo_clnte       = p_cdgo_clnte
               and id_impsto        = v_id_impsto
               and cdgo_lqdcion_tpo = 'MG';
       exception
           when no_data_found then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := o_cdgo_rspsta || '. El tipo de liquidacion de migracion con codigo [MG], no existe en el sistema.';
                return;
        end;
        
        --Recorre la Coleccion de Vigencias                                 
        for i in 1..v_vgncias.count loop
            declare
                v_df_i_periodos      df_i_periodos%rowtype;
                v_id_lqdcion_antrior gi_g_liquidaciones.id_lqdcion_antrior%type;
                v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
                v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
            begin
                
                --Verifica si el Periodo Existe
                select a.* 
                  into v_df_i_periodos
                  from df_i_periodos a
                 where a.cdgo_clnte        = p_cdgo_clnte
                   and a.id_impsto         = v_id_impsto
                   and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                   and a.vgncia            = v_vgncias(i).vgncia
                   and a.prdo              = v_vgncias(i).prdo
                   and a.cdgo_prdcdad      = 'ANU';
                   
                --Cursor de Liquidaciones
                for c_lqdcnes in (
                                        select min(id_intrmdia) as id_intrmdia
                                             , a.clmna1  as id
                                             , a.clmna6  as idntfccion
                                             , a.clmna7  as fcha_lqdcion
                                             , a.clmna8  as cdgo_lqdcion_estdo
                                             , a.clmna9  as bse_grvble
                                             , a.clmna16 as cdgo_prdio_clsfccion
                                             , a.clmna17 as cdgo_dstno
                                             , a.clmna18 as cdgo_estrto
                                             , a.clmna19 as cdgo_prdio_uso_slo
                                             , a.clmna20 as area_trrno
                                             , a.clmna21 as area_cnstrda
                                             , json_arrayagg( 
                                                                json_object(
                                                                               'id_intrmdia' value a.id_intrmdia,
                                                                               'cdgo_cncpto' value a.clmna11,
                                                                               'vlor_lqddo'  value a.clmna12,
                                                                               'trfa'        value a.clmna13,
                                                                               'bse_cncpto'  value a.clmna14,
                                                                               'lmta'        value a.clmna15
                                                                           )
                                                                returning clob
                                                            ) as lqdcion_dtlle
                                          from migra.mg_g_intermedia a
                                         where a.cdgo_clnte        = p_cdgo_clnte
                                           and a.id_entdad         = p_id_entdad
                                           and a.clmna4            = ''|| v_df_i_periodos.vgncia
                                           and a.clmna5            = ''|| v_df_i_periodos.prdo
                                           and a.cdgo_estdo_rgstro = 'L'
                                      group by a.clmna1
                                             , a.clmna6
                                             , a.clmna7
                                             , a.clmna8
                                             , a.clmna9
                                             , a.clmna16
                                             , a.clmna17
                                             , a.clmna18
                                             , a.clmna19
                                             , a.clmna20
                                             , a.clmna21
                                      order by a.clmna1
                                 ) 
                loop
                    
                    --Verifica si Existe el Sujeto Impuesto
                    begin
                        select  
                               a.id_sjto_impsto
                          into v_id_sjto_impsto    
                          from si_i_sujetos_impuesto a
                         where exists(
                                        select 1
                                          from si_c_sujetos b
                                         where b.cdgo_clnte         = p_cdgo_clnte
                                           and b.idntfccion_antrior = c_lqdcnes.idntfccion
                                         --and b.idntfccion         = c_lqdcnes.idntfccion 
                                           and a.id_sjto            = b.id_sjto
                                     )
                           and a.id_impsto = v_id_impsto;
                    exception   
                         when no_data_found then
                              o_cdgo_rspsta  := 5; 
                              o_mnsje_rspsta := o_cdgo_rspsta || '. El sujeto impuesto para la referencia #' || c_lqdcnes.idntfccion || ', no existe en el sistema.';
                              v_errors.extend;  
                              v_errors( v_errors.count ) := t_errors( id_intrmdia => c_lqdcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                              continue; 
                    end;
                    
                    --Busca si Existe Liquidacion
                    begin
                        select id_lqdcion 
                          into v_id_lqdcion_antrior
                          from gi_g_liquidaciones
                         where cdgo_clnte         = p_cdgo_clnte
                           and id_impsto          = v_id_impsto
                           and id_impsto_sbmpsto  = v_id_impsto_sbmpsto
                           and id_prdo            = v_df_i_periodos.id_prdo 
                           and id_sjto_impsto     = v_id_sjto_impsto
                           and cdgo_lqdcion_estdo = pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_l;
                        
                        --Inactiva la Ultima Liquidacion
                        update gi_g_liquidaciones
                           set cdgo_lqdcion_estdo = pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_i
                         where id_lqdcion         = v_id_lqdcion_antrior; 
                           
                    exception
                         when no_data_found then
                              v_id_lqdcion_antrior := null; 
                    end; 
        
                    --Inserta el Registro de Liquidacion
                    begin
                        insert into gi_g_liquidaciones( cdgo_clnte , id_impsto , id_impsto_sbmpsto , vgncia , id_prdo 
                                                      , id_sjto_impsto , fcha_lqdcion , cdgo_lqdcion_estdo , bse_grvble , vlor_ttal
                                                      , id_lqdcion_tpo , id_ttlo_ejctvo , cdgo_prdcdad , id_lqdcion_antrior , id_usrio )
                                               values ( p_cdgo_clnte , v_id_impsto , v_id_impsto_sbmpsto , v_df_i_periodos.vgncia , v_df_i_periodos.id_prdo 
                                                      , v_id_sjto_impsto , to_date( c_lqdcnes.fcha_lqdcion , 'DD/MM/YYYY' ) , pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_l , c_lqdcnes.bse_grvble , 0  
                                                      , v_id_lqdcion_tpo , 0 , v_df_i_periodos.cdgo_prdcdad , v_id_lqdcion_antrior , p_id_usrio )
                        returning id_lqdcion 
                             into v_id_lqdcion;
                    exception 
                         when others then
                              o_cdgo_rspsta  := 6; 
                              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible registrar la liquidacion.'|| sqlerrm;
                              v_errors.extend;  
                              v_errors( v_errors.count ) := t_errors( id_intrmdia => c_lqdcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                              continue; 
                    end;
                    
                    --Inserta las Caracteristica de la Liquidacion del Predio
                    declare
                        v_id_prdio_dstno   df_i_predios_destino.id_prdio_dstno%type;
                        v_id_prdio_uso_slo df_c_predios_uso_suelo.id_prdio_uso_slo%type;
                    begin
                        
                        --Homologacion de Clasificacion
                        c_lqdcnes.cdgo_prdio_clsfccion := fnc_co_homologacion( p_clmna => 16 , p_vlor => c_lqdcnes.cdgo_prdio_clsfccion , p_hmlgcion => v_hmlgcion );
                        --Homologacion de Destino
                        c_lqdcnes.cdgo_dstno           := fnc_co_homologacion( p_clmna => 17 , p_vlor => c_lqdcnes.cdgo_dstno           , p_hmlgcion => v_hmlgcion );
                        --Homologacion de Estrato
                        c_lqdcnes.cdgo_estrto          := fnc_co_homologacion( p_clmna => 18 , p_vlor => c_lqdcnes.cdgo_estrto          , p_hmlgcion => v_hmlgcion );
                        --Homologacion de Uso Suelo
                        c_lqdcnes.cdgo_prdio_uso_slo   := fnc_co_homologacion( p_clmna => 19 , p_vlor => c_lqdcnes.cdgo_prdio_uso_slo   , p_hmlgcion => v_hmlgcion );
                        
            
                        --Clasificacion
                        c_lqdcnes.cdgo_prdio_clsfccion := nvl( c_lqdcnes.cdgo_prdio_clsfccion , '99' );
                        --Destino
                        c_lqdcnes.cdgo_dstno           := nvl( c_lqdcnes.cdgo_dstno , '99' );
                        --Estrato
                        c_lqdcnes.cdgo_estrto          := nvl( c_lqdcnes.cdgo_estrto , '99' );
                        --Uso Suelo
                        c_lqdcnes.cdgo_prdio_uso_slo   := nvl( c_lqdcnes.cdgo_prdio_uso_slo  , '99' );
                        
                        --Busca el Destino del Predio
                          begin
                             select 
                                    id_prdio_dstno 
                               into v_id_prdio_dstno
                               from df_i_predios_destino
                              where cdgo_clnte = p_cdgo_clnte
                                and id_impsto  = v_id_impsto
                                and nmtcnco    = c_lqdcnes.cdgo_dstno;
                          exception
                               when no_data_found then 
                                    o_cdgo_rspsta  := 7;
                                    o_mnsje_rspsta := o_cdgo_rspsta || '. El destino con codigo #' || c_lqdcnes.cdgo_dstno || ', no existe en el sistema.';
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_lqdcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    rollback;
                                    continue;  
                          end;
                          
                          --Busca el Uso del Predio
                          begin
                             select
                                    id_prdio_uso_slo 
                               into v_id_prdio_uso_slo
                               from df_c_predios_uso_suelo
                              where cdgo_clnte         = p_cdgo_clnte
                                and cdgo_prdio_uso_slo = c_lqdcnes.cdgo_prdio_uso_slo;
                          exception
                               when no_data_found then 
                                    o_cdgo_rspsta  := 8;
                                    o_mnsje_rspsta := o_cdgo_rspsta || '. El uso suelo con codigo #' || c_lqdcnes.cdgo_prdio_uso_slo || ', no existe en el sistema.';
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := t_errors( id_intrmdia => c_lqdcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    rollback;
                                    continue;  
                          end;
                                               
                        insert into gi_g_liquidaciones_ad_predio ( id_lqdcion , cdgo_prdio_clsfccion , id_prdio_dstno , id_prdio_uso_slo    
                                                                 , cdgo_estrto , area_trrno , area_cnsctrda , area_grvble )
                                                          values ( v_id_lqdcion , c_lqdcnes.cdgo_prdio_clsfccion , v_id_prdio_dstno , v_id_prdio_uso_slo
                                                                 , c_lqdcnes.cdgo_estrto , to_number( c_lqdcnes.area_trrno ) , to_number( c_lqdcnes.area_cnstrda ) , greatest( to_number( c_lqdcnes.area_trrno ) , to_number( c_lqdcnes.area_cnstrda )));
                    exception 
                         when others then
                              o_cdgo_rspsta  := 9; 
                              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el registro de liquidacion ad predio.' || sqlerrm;
                              v_errors.extend;  
                              v_errors( v_errors.count ) := t_errors( id_intrmdia => c_lqdcnes.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                              rollback;
                              continue; 
                    end;
        
                    --Cursor de Conceptos
                    for c_cncptos in (
                                         select a.*
                                           from json_table( c_lqdcnes.lqdcion_dtlle , '$[*]'
                                                             columns
                                                             ( id_intrmdia number  path '$.id_intrmdia' 
                                                             , cdgo_cncpto varchar path '$.cdgo_cncpto' 
                                                             , vlor_lqddo  number  path '$.vlor_lqddo' 
                                                             , trfa        number  path '$.trfa'
                                                             , bse_cncpto  number  path '$.bse_cncpto' 
                                                             , lmta        varchar path '$.lmta' )
                                                          ) a
                                     ) loop
                    
                        declare
                            v_id_cncpto             df_i_conceptos.id_cncpto%type;
                            v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
                            v_fcha_vncmnto          df_i_impuestos_acto_concepto.fcha_vncmnto%type;
                        begin
                            
                            --Busca si Existe el Concepto
                            begin
                                select 
                                       a.id_cncpto 
                                  into v_id_cncpto
                                  from df_i_conceptos a
                                 where a.cdgo_clnte  = p_cdgo_clnte
                                   and a.id_impsto   = v_id_impsto
                                   and a.cdgo_cncpto = c_cncptos.cdgo_cncpto;
                            exception
                                 when no_data_found then
                                      o_cdgo_rspsta  := 10; 
                                      o_mnsje_rspsta := o_cdgo_rspsta || '. El concepto con codigo #' || c_cncptos.cdgo_cncpto || ', no existe en el sistema.';
                                      v_errors.extend;  
                                      v_errors( v_errors.count ) := t_errors( id_intrmdia => c_cncptos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                      rollback;
                                      exit; 
                            end;
                               
                            --Busca si Existe el Impuesto Acto Concepto
                            begin
                                select 
                                       a.id_impsto_acto_cncpto
                                     , a.fcha_vncmnto
                                  into v_id_impsto_acto_cncpto
                                     , v_fcha_vncmnto
                                  from df_i_impuestos_acto_concepto a
                                 where a.cdgo_clnte = p_cdgo_clnte
                                   and a.vgncia     = v_df_i_periodos.vgncia
                                   and a.id_prdo    = v_df_i_periodos.id_prdo
                                   and a.id_cncpto  = v_id_cncpto
                                   and exists(
                                                 select 1
                                                   from df_i_impuestos_acto b
                                                  where b.id_impsto         = v_id_impsto
                                                    and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                                                    and b.cdgo_impsto_acto  = 'IPU'
                                                    and a.id_impsto_acto    = b.id_impsto_acto
                                             );
                            exception
                                 when no_data_found then 
                                      o_cdgo_rspsta  := 11; 
                                      o_mnsje_rspsta := o_cdgo_rspsta || '. El acto concepto para el concepto con codigo #' || c_cncptos.cdgo_cncpto || ', no existe en el sistema.';
                                      v_errors.extend;  
                                      v_errors( v_errors.count ) := t_errors( id_intrmdia => c_cncptos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                      rollback;
                                      exit; 
                            end;
                            
                            --Inserta el Registro de Liquidacion Concepto
                            begin
                                insert into gi_g_liquidaciones_concepto ( id_lqdcion , id_impsto_acto_cncpto , vlor_lqddo , vlor_clcldo , trfa 
                                                                        , bse_cncpto , txto_trfa , vlor_intres , indcdor_lmta_impsto , fcha_vncmnto )
                                                                 values ( v_id_lqdcion , v_id_impsto_acto_cncpto , c_cncptos.vlor_lqddo , c_cncptos.vlor_lqddo , c_cncptos.trfa 
                                                                        , c_cncptos.bse_cncpto , c_cncptos.trfa  || '/' || pkg_gi_liquidacion_predio.g_divisor , 0 , c_cncptos.lmta , v_fcha_vncmnto );
                            exception 
                                 when others then
                                      o_cdgo_rspsta  := 12;
                                      o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el registro de liquidacion concepto.' || sqlerrm;
                                      v_errors.extend;  
                                      v_errors( v_errors.count ) := t_errors( id_intrmdia => c_cncptos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                      rollback;
                                      exit;
                            end;
                            
                            --Actualiza el Valor Total de la Liquidacion
                            update gi_g_liquidaciones 
                               set vlor_ttal  = nvl( vlor_ttal , 0 ) + to_number(c_cncptos.vlor_lqddo)
                             where id_lqdcion = v_id_lqdcion;
                             
                             --Indicador de Registros Exitosos
                             o_ttal_extsos := o_ttal_extsos + 1;
                            
                        end;
                    end loop;
                    
                    --Commit por Cada Lquidacion
                    commit;
                    
                end loop;
            exception
                 when no_data_found then
                      o_cdgo_rspsta  := 13; 
                      o_mnsje_rspsta := o_cdgo_rspsta || '. La vigencia ' || v_vgncias(i).vgncia || ' con periodo ' || v_vgncias(i).prdo || ' y periodicidad anual, no existe en el sistema.';
                      rollback;
                      return;
            end;           
        end loop;
                                                             
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'S'
         where cdgo_clnte        = p_cdgo_clnte 
           and id_entdad         = p_id_entdad
           and cdgo_estdo_rgstro = 'L';
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        delete muerto;
        
        forall i in 1..o_ttal_error
         insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                          values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
        
        forall j in 1..o_ttal_error
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia       = v_errors(j).id_intrmdia;
         
    exception   
         when others then
              o_cdgo_rspsta  := 14; 
              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible realizar la migracion de liquidacion de predio.' || sqlerrm;
    end prc_mg_lqdcnes_prdio;
    
    */
    
    /*Up para migrar establecimientos*/
   /* procedure prc_mg_sjtos_impsts_estblcmnts(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2) as
                                             
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        --c_intrmdia              pkg_mg_migracion.t_mg_g_intermedia_cursor;
        
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
        --open c_intrmdia for select  /*+ parallel(a, id_entdad) 
        --                    from    migra.mg_g_intermedia   a
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
                                    select  
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
                                    from    migra.mg_g_intermedia   a
                                    where   a.cdgo_clnte        =   p_cdgo_clnte
                                    and     a.id_entdad         =   p_id_entdad
                                    and     a.cdgo_estdo_rgstro =   'L'
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
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                --REGISTRO EN SI_I_SUJETOS_IMPUESTO
                --Se valida el impuesto
                begin
                    select  a.id_impsto
                    into    v_id_impsto
                    from    df_c_impuestos  a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.cdgo_impsto   =   c_estblcmntos.clmna10;
                exception
                    when others then
                        o_cdgo_rspsta   := 7;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el impuesto del establecimiento. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 8;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_sujetos_impuesto. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 9;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais de notificacion del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 10;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento de notificacion del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 11;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 12;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el estado del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 13;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_impuesto del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 14;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_personas. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 15;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el tipo de sujeto (regimen) establecimiento en la tabla id_sjto_tpo. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 16;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la actividad economica del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 17;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_personas del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 18;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_terceros. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 19;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
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
                                o_cdgo_rspsta   := 20;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el responsable en la tabla si_c_terceros. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                        o_cdgo_rspsta   := 21;
                                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais del responsable del establecimiento. ' || sqlerrm;
                                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                        o_cdgo_rspsta   := 22;
                                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del responsable del establecimiento. ' || sqlerrm;
                                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                        o_cdgo_rspsta   := 23;
                                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del reponsable del establecimiento. ' || sqlerrm;
                                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                           c_rspnsbles.clmna35,
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
                                    o_cdgo_rspsta   := 24;
                                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del responsable. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                                  c_rspnsbles.clmna32, --idntfccion
                                                                  c_rspnsbles.clmna33, --prmer_nmbre
                                                                  c_rspnsbles.clmna34, --sgndo_nmbre
                                                                  c_rspnsbles.clmna35, --prmer_aplldo
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
                                                                  c_rspnsbles.clmna42, --tlfno
                                                                  c_rspnsbles.clmna47, --actvo
                                                                  v_id_trcro_rspnsble);
                        exception
                            when others then
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
                                || 'v_id_trcro_rspnsble: ' ||v_id_trcro_rspnsble || ' '
                                || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_rspnsbles.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;                               
                    end loop;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                --Si el establecimiento es de tipo persona natural
                else
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
                                o_cdgo_rspsta   := 26;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                                      c_estblcmntos.clmna16,
                                                                      'S',
                                                                      v_id_trcro_estblcmnto);
                            exception
                                when others then
                                    o_cdgo_rspsta   := 27;
                                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del establecimiento. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                end if;
                
                --Se asegura el commit;
                commit;
            end loop;
            
            --Se actualiza el estado de los registros procesados en la tabla MIGRA.MG_G_INTERMEDIA
            begin
                update  migra.mg_g_intermedia   a
                set     a.cdgo_estdo_rgstro =   'S'
                where   a.cdgo_clnte        =   p_cdgo_clnte
                and     id_entdad           =   p_id_entdad
                and     cdgo_estdo_rgstro   =   'L';
            exception
                when others then
                    o_cdgo_rspsta   := 28;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Procesos con Errores
                o_ttal_error   := v_errors.count;
            begin                    
                forall i in 1 .. o_ttal_error
                    insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                                     values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );
            exception
                when others then
                    o_cdgo_rspsta   := 29;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Se actualizan en la tabla MIGRA.MG_G_INTERMEDIA como error
            begin
                forall j in 1 .. o_ttal_error
                    update  migra.mg_g_intermedia   a
                    set     a.cdgo_estdo_rgstro =   'E'
                    where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
            exception
                when others then
                    o_cdgo_rspsta   := 30;
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
    
    
    */
    /*Up para migrar establecimientos*/
    procedure prc_mg_estblcmnts_pndntes(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2) as
                                             
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        --c_intrmdia              pkg_mg_migracion.t_mg_g_intermedia_2_cursor;
        
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
        --                    from    migra.mg_g_intermedia_2   a
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
                                    from    migra.mg_g_intermedia_2   a
                                    where   a.cdgo_clnte        =   p_cdgo_clnte
                                    and     a.id_entdad         =   p_id_entdad
                                    and     a.cdgo_estdo_rgstro =   'L'
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
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                    end if;
                    
                    c_estblcmntos.clmna5 := pkg_mg_migracion.fnc_co_homologacion(p_clmna   => 5,
                                                                                 p_vlor    => c_estblcmntos.clmna5,
                                                                                 p_hmlgcion=> v_hmlgcion);
                    
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
                            when no_data_found then
                                v_id_dprtmnto_esblcmnto := v_cdgo_clnte_tab.id_dprtmnto;
                            when others then
                                o_cdgo_rspsta   := 4;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
                --REGISTRO EN SI_I_SUJETOS_IMPUESTO
                --Se valida el impuesto
                begin
                    select  a.id_impsto
                    into    v_id_impsto
                    from    df_c_impuestos  a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.cdgo_impsto   =   c_estblcmntos.clmna10;
                exception
                    when others then
                        o_cdgo_rspsta   := 7;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el impuesto del establecimiento. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 8;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_sujetos_impuesto. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 9;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais de notificacion del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 10;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento de notificacion del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                o_cdgo_rspsta   := 11;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del establecimiento. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 12;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el estado del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 13;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_impuesto del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 14;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_i_personas. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        and     a.cdgo_sjto_tpo =   nvl(c_estblcmntos.clmna29, 'N');
                    exception
                        when no_data_found then
                            null;
                        when others then
                            o_cdgo_rspsta   := 15;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el tipo de sujeto (regimen) establecimiento en la tabla id_sjto_tpo. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 16;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la actividad economica del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                            o_cdgo_rspsta   := 17;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_personas del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                        o_cdgo_rspsta   := 18;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el establecimiento en la tabla si_c_terceros. ' || sqlerrm;
                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                   'S',
                                                   'N',
                                                   c_estblcmntos.clmna16) returning id_trcro into v_id_trcro_estblcmnto;
                    exception
                        when others then
                            o_cdgo_rspsta   := 19;
                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del establecimiento. ' || sqlerrm;
                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            continue;
                    end;
                end if;
                
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
                        if (c_rspnsbles.clmna32 is not null) then
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
                                    o_cdgo_rspsta   := 20;
                                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el responsable en la tabla si_c_terceros. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                            o_cdgo_rspsta   := 21;
                                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el pais del responsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                            o_cdgo_rspsta   := 22;
                                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el departamento del responsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                            o_cdgo_rspsta   := 23;
                                            o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse el municipio del reponsable del establecimiento. ' || sqlerrm;
                                            --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                            v_errors.extend;  
                                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                               nvl(c_rspnsbles.clmna35, '.'),
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
                                        o_cdgo_rspsta   := 24;
                                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_c_terceros del responsable. ' || sqlerrm;
                                        --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                        v_errors.extend;  
                                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
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
                                                                      c_rspnsbles.clmna32, --idntfccion
                                                                      c_rspnsbles.clmna33, --prmer_nmbre
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
                                                                      c_rspnsbles.clmna42, --tlfno
                                                                      c_rspnsbles.clmna47, --actvo
                                                                      v_id_trcro_rspnsble);
                            exception
                                when others then
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
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_rspnsbles.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end loop;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                --Si el establecimiento es de tipo persona natural
                else
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
                                o_cdgo_rspsta   := 26;
                                o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del responsable. ' || sqlerrm;
                                --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                v_errors.extend;  
                                v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                continue;
                        end;
                        
                        --Se continua con el proceso de si_i_sujetos_responsable si no existe
                        if (v_id_sjto_rspnsble is null) then
                            begin
                                c_estblcmntos.clmna16 := to_number(c_estblcmntos.clmna16);
                            exception
                                when others then
                                    c_estblcmntos.clmna16 := null;
                            end;
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
                                                                      c_estblcmntos.clmna16,
                                                                      'S',
                                                                      v_id_trcro_estblcmnto);
                            exception
                                when others then
                                    o_cdgo_rspsta   := 27;
                                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el si_i_sujetos_responsable del establecimiento. ' || sqlerrm;
                                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                                    v_errors.extend;  
                                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                                    continue;
                            end;
                        end if;
                    end;
                    
                    --Indicador de Registros Exitosos
                    o_ttal_extsos := o_ttal_extsos + 1;
                end if;
                
                --Se asegura el commit;
                commit;
            end loop;
            
            --Se actualiza el estado de los registros procesados en la tabla MIGRA.mg_g_intermedia_2
            begin
                update  migra.mg_g_intermedia_2   a
                set     a.cdgo_estdo_rgstro =   'S'
                where   a.cdgo_clnte        =   p_cdgo_clnte
                and     id_entdad           =   p_id_entdad
                and     cdgo_estdo_rgstro   =   'L';
            exception
                when others then
                    o_cdgo_rspsta   := 28;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Procesos con Errores
                o_ttal_error   := v_errors.count;
            begin                    
                /*forall i in 1 .. o_ttal_error
                    insert into migra.mg_g_intermedia_error( id_prcso_instncia,     id_intrmdia,                error )
                                                     values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    v_errors(i).mnsje_rspsta );*/
                delete muerto;
                forall i in 1 .. o_ttal_error
                    insert into muerto ( n_001,                 v_002,                      c_001 )
                                 values( p_id_prcso_instncia,   v_errors(i).id_intrmdia,    to_clob(v_errors(i).mnsje_rspsta) );
            exception
                when others then
                    o_cdgo_rspsta   := 29;
                    o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo actualizarse los registros procesados como error. ' || sqlerrm;
                    --insert into gti_aux (col1, col2) values ('Error => Codigo: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
                    return;
            end;
            
            --Se actualizan en la tabla MIGRA.mg_g_intermedia_2 como error
            begin
                forall j in 1 .. o_ttal_error
                    update  migra.mg_g_intermedia_2   a
                    set     a.cdgo_estdo_rgstro =   'E'
                    where   a.id_intrmdia       =   v_errors(j).id_intrmdia;
            exception
                when others then
                    o_cdgo_rspsta   := 30;
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
    end prc_mg_estblcmnts_pndntes;
    
    /*Up para migrar flujos de PQR y AP*/
   /* procedure prc_mg_pqr_ac( p_id_entdad         in  number
                           , p_id_prcso_instncia in  number
                            , p_id_usrio          in  number
                            , p_cdgo_clnte        in  number
                            , o_ttal_extsos       out number
                            , o_ttal_error        out number
                            , o_cdgo_rspsta       out number
                            , o_mnsje_rspsta      out varchar2 ) 
    as
    
        
        v_hmlgcion              pkg_mg_migracion.r_hmlgcion;
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        v_id_sjto               si_c_sujetos.id_sjto%type;
        v_id_sjto_impsto        si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_df_s_clientes         df_s_clientes%rowtype;
        v_id_sjto_estdo         df_s_sujetos_estado.id_sjto_estdo%type;
        v_id_impsto             df_c_impuestos.id_impsto%type;
        v_id_impsto_sbmpsto     df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
        v_mg_g_intrmdia         pkg_mg_migracion.r_mg_g_intrmdia;    
        v_pqr                   migra.mg_g_intermedia%rowtype;
        v_id_instncia_fljo      number;
        v_id_instncia_fljo_hjo  number;
    
        type t_impuesto is record (
            id_impsto           number,
            id_impsto_sbmpsto   number
        );
        type g_impuesto is table of t_impuesto  index by varchar2(100);
        v_impuesto              g_impuesto;
    
    begin
        
        --Limpia la Cache
        dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
            when no_data_found then                 
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.'; 
                return;
        end;
    
        --Llena la Coleccion de Intermedia
        select a.*
            bulk collect  
            into v_mg_g_intrmdia
            from migra.mg_g_intermedia a 
            where a.cdgo_clnte        = p_cdgo_clnte 
            and a.id_entdad         = p_id_entdad
            and a.cdgo_estdo_rgstro = 'L';
        
        --Verifica si hay Registros Cargado
        if( v_mg_g_intrmdia.count = 0 ) then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.'; 
            return;  
        end if;
        
        for c_impuesto in (select a.id_impsto
                                , b.id_impsto_sbmpsto
                                , a.cdgo_impsto || '' || b.cdgo_impsto_sbmpsto as indice
                                from df_c_impuestos a
                                join df_i_impuestos_subimpuesto b
                                on a.id_impsto = b.id_impsto
                            where a.cdgo_clnte = p_cdgo_clnte )
        loop
            v_impuesto(c_impuesto.indice) := t_impuesto(c_impuesto.id_impsto,c_impuesto.id_impsto_sbmpsto); 
        end loop;
        
        --Llena la Coleccion de Predio Responsables
        for i in 1..v_mg_g_intrmdia.count 
        loop
            v_pqr :=  v_mg_g_intrmdia(i);
            declare
                v_id_rdcdor         number;
                v_clmna13           varchar2(4000) := v_pqr.clmna13 ;
                v_clmna14           varchar2(4000) := v_pqr.clmna14 ;
                v_clmna15           varchar2(4000) := v_pqr.clmna15 ;
                v_id_slctud_mtvo    number;
                v_id_slctud         number;
                --Consulta Pais
                function fnc_co_pais( p_cdgo_pais in varchar2 )
                return number
                is
                    v_id_pais df_s_paises.id_pais%type;
                begin
                
                    select 
                            id_pais 
                        into v_id_pais
                        from df_s_paises
                        where cdgo_pais = p_cdgo_pais;
                        
                    return v_id_pais;
                exception
                    when no_data_found then    
                        o_cdgo_rspsta  := 3;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. El pais con codigo #' || p_cdgo_pais || ', no existe en el sistema.';
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        return null;
                end fnc_co_pais;
            
                --Consulta Departamento
                function fnc_co_departamento( p_cdgo_dprtmnto in varchar2 
                                            , p_id_pais       in df_s_paises.id_pais%type )
                return number
                is
                    v_id_dprtmnto df_s_departamentos.id_dprtmnto%type;
                begin                    
                    
                    select 
                            id_dprtmnto 
                        into v_id_dprtmnto
                        from df_s_departamentos
                        where cdgo_dprtmnto = p_cdgo_dprtmnto
                        and id_pais       = p_id_pais;
                        
                        return v_id_dprtmnto;
                exception
                        when no_data_found then    
                            o_cdgo_rspsta  := 4;
                            o_mnsje_rspsta := o_cdgo_rspsta || '. El departamento con codigo #' || p_cdgo_dprtmnto || ', no existe en el sistema.';
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            return null;
                end fnc_co_departamento;
            
                --Consultar Municipio
                function fnc_co_municipio( p_cdgo_mncpio in varchar2 
                                            , p_id_dprtmnto in df_s_departamentos.id_dprtmnto%type )
                return number
                is
                    v_id_mncpio df_s_municipios.id_mncpio%type;
                begin                     
                    
                    select 
                            id_mncpio 
                        into v_id_mncpio
                        from df_s_municipios
                        where cdgo_mncpio = p_cdgo_mncpio
                        and id_dprtmnto = p_id_dprtmnto;
                        
                        return v_id_mncpio;
                exception
                    when no_data_found then    
                        o_cdgo_rspsta  := 5;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. El municipio con codigo #' || p_cdgo_mncpio || ', no existe en el sistema.';
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        return null;
                end fnc_co_municipio;
                            
            begin
              */
            /*INICIAMOS EL PROCESO DE MIGRACION DE PQR DE ACUERDOS DE PAGO */
                /*
                begin
                    v_id_impsto_sbmpsto := v_impuesto(v_pqr.clmna16 || '' || v_pqr.clmna17).id_impsto_sbmpsto;
                    v_id_impsto         := v_impuesto(v_pqr.clmna16 || '' || v_pqr.clmna17).id_impsto;
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 6;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. El impuesto o subimpuesto con codigo #' || v_pqr.clmna16 || '' || v_pqr.clmna17 || ', no existe en el sistema.';
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        exit; 
                end;
                
                --IDENTIFICADOR DEL PAIS
                v_pqr.clmna15 := fnc_co_pais( p_cdgo_pais  => v_clmna15);
                    
                if( v_pqr.clmna15 is null ) then
                    rollback;
                    exit;
                end if;
                
                --IDENFIFICADOR DEL DEPARTAMENTO
                v_pqr.clmna14 := fnc_co_departamento( p_cdgo_dprtmnto => v_clmna14
                                                    , p_id_pais       => v_pqr.clmna15 );
                    
                if( v_pqr.clmna14 is null ) then
                    rollback;
                    exit;
                end if;
                
                --IDENFIFICADOR DEL MUNICIPIO
                v_pqr.clmna13 := fnc_co_municipio( p_cdgo_mncpio => v_clmna14 || v_clmna13
                                                    , p_id_dprtmnto       => v_pqr.clmna14 );
                    
                if( v_pqr.clmna13 is null ) then
                    rollback;
                    exit;
                end if;
                
                --CONSULTAMOS LOS DATOS DEL GESTOR
                begin
                    select id_rdcdor
                        into v_id_rdcdor
                        from pq_g_radicador
                        where cdgo_idntfccion_tpo  = v_pqr.clmna3
                        and idntfccion           = v_pqr.clmna5 ;                    
                exception
                    when others then
                        v_id_rdcdor := null;
                end;
                
                --SI NO ENCONTRAMOS DATOS DEL GESTOR LO CREAMOS 
                if v_id_rdcdor is null then
                    begin 
                                            
                        insert into pq_g_radicador (cdgo_idntfccion_tpo , idntfccion    , prmer_nmbre   , prmer_aplldo) 
                                            values (v_pqr.clmna3        , v_pqr.clmna5  , v_pqr.clmna4  , '-'         )
                                            returning id_rdcdor into v_id_rdcdor;
    
                    exception
                        when others then
                            rollback;
                            o_cdgo_rspsta  := 7;
                            o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el gestor.' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            exit; 
                    end;
                end if;
                
                --CREACION FLUJO DE PQR
                begin                                      
                    insert into wf_g_instancias_flujo( id_fljo       , fcha_incio  , fcha_fin_plnda
                                                        , fcha_fin_optma, id_usrio    , estdo_instncia
                                                        , obsrvcion) 
                                                values( 10            , v_pqr.clmna2,  v_pqr.clmna2
                                                        , v_pqr.clmna2  , p_id_usrio  , 'FINALIZADA'  
                                                        , 'Migracion flujos de pqr para acuerdos de pago.')
                                                returning id_instncia_fljo 
                                                    into v_id_instncia_fljo;                            
                                        
                    insert into wf_g_instancias_transicion( id_instncia_fljo  , id_fljo_trea_orgen, fcha_incio
                                                            , fcha_fin_plnda    , fcha_fin_optma    , fcha_fin_real
                                                            , id_usrio          , id_estdo_trnscion)
                                                        select v_id_instncia_fljo, id_fljo_trea      , v_pqr.clmna2
                                                            , v_pqr.clmna2      , v_pqr.clmna2      , v_pqr.clmna2
                                                            , p_id_usrio        , 3  
                                                            from (select id_fljo_trea 
                                                                    from wf_d_flujos_transicion 
                                                                    where id_fljo = 10
                                                                    union 
                                                                    select id_fljo_trea_dstno 
                                                                    from wf_d_flujos_transicion 
                                                                    where id_fljo = 10 ) a;
    
                    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 8;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el flujo de pqr.' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        exit;
                end;                                            
                
                --CREACION FLUJO DE ACUERDOS DE PAGO
                begin                                      
                    insert into wf_g_instancias_flujo( id_fljo       , fcha_incio  , fcha_fin_plnda
                                                        , fcha_fin_optma, id_usrio    , estdo_instncia
                                                        , obsrvcion) 
                                                values( 11            , v_pqr.clmna2,  v_pqr.clmna2
                                                        , v_pqr.clmna2  , p_id_usrio  , 'FINALIZADA'  
                                                        , 'Migracion flujos de acuerdos de pago.')
                                                returning id_instncia_fljo 
                                                    into v_id_instncia_fljo_hjo;                            
                    
                    
                    insert into wf_g_instancias_transicion( id_instncia_fljo      , id_fljo_trea_orgen, fcha_incio
                                                            , fcha_fin_plnda        , fcha_fin_optma    , fcha_fin_real
                                                            , id_usrio              , id_estdo_trnscion )
                                                        select v_id_instncia_fljo_hjo, id_fljo_trea      , v_pqr.clmna2
                                                            , v_pqr.clmna2          , v_pqr.clmna2      , v_pqr.clmna2
                                                            , p_id_usrio            , 3  
                                                            from (select id_fljo_trea 
                                                                    from wf_d_flujos_transicion 
                                                                    where id_fljo = 11
                                                                    union 
                                                                    select id_fljo_trea_dstno 
                                                                    from wf_d_flujos_transicion 
                                                                    where id_fljo = 11 ) a;
    
                    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 9;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el flujo de acuerdo de pago.' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        exit;
                end;
                
                --ASOCIAMOS EL FLUJO PQR CON EL FLUJO ACUERDO DE PAGO
                begin
                    insert into wf_g_instancias_flujo_gnrdo( id_instncia_fljo  , id_instncia_fljo_gnrdo_hjo
                                                            , id_fljo_trea      , indcdor_mnjdo             ) 
                                                        values( v_id_instncia_fljo, v_id_instncia_fljo_hjo    
                                                            , 54               , 'S'                       );
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo asociar el flujo de pqr con el de acuerdo de pago.' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        exit;
                end;
                
                declare
                    v_anio              varchar2(4)  := extract(year from to_date(v_pqr.clmna2, 'dd/mm/yyyy'));
                    v_nmro_rdcdo_dsplay varchar2(30) := v_anio || '-' || v_pqr.clmna1 ;
                    v_id_slctud         number;
                    v_id_slctud_mtvo    number;
                begin                                    
                    
                    insert into pq_g_solicitudes( id_estdo      , id_tpo             , id_usrio      , id_instncia_fljo  
                                                , id_rdcdor     , anio               , cdgo_clnte    , nmro_flio   
                                                , nmro_rdcdo    , nmro_rdcdo_dsplay  , fcha_rdcdo    , id_prsntcion_tpo)
                                            values( 9             , 5                  , p_id_usrio    , v_id_instncia_fljo
                                                , v_id_rdcdor   , v_anio             , p_cdgo_clnte  , 0    
                                                , v_pqr.clmna1  , v_nmro_rdcdo_dsplay, v_pqr.clmna2  , 2)
                                    returning id_slctud into v_id_slctud;                            
                                                
                    insert into pq_g_solicitantes(    id_slctud           , cdgo_idntfccion_tpo, idntfccion         
                                                    , prmer_nmbre         , prmer_aplldo       , id_pais_ntfccion
                                                    , id_dprtmnto_ntfccion, id_mncpio_ntfccion , drccion_ntfccion
                                                    , email               , cllar              , cdgo_rspnsble_tpo  )                                            
                                            values(    v_id_slctud          , v_pqr.clmna3      , v_pqr.clmna5
                                                    , v_pqr.clmna4         , '-'               , v_pqr.clmna15
                                                    , v_pqr.clmna14        , v_pqr.clmna13     , v_pqr.clmna10
                                                    , v_pqr.clmna12        , v_pqr.clmna11     , v_pqr.clmna6);
                    --MOTIVO 
                    insert into pq_g_solicitudes_motivo( id_slctud  , id_mtvo)
                                                    values( v_id_slctud, 5      )
                                                returning id_slctud_mtvo 
                                                    into v_id_slctud_mtvo;
                                        
                    --SUJETO IMPUESTO                    
                    begin
                        select id_sjto_impsto
                            into v_id_sjto_impsto
                            from v_si_i_sujetos_impuesto a
                            where a.cdgo_clnte         = p_cdgo_clnte
                            and a.idntfccion_antrior = v_pqr.clmna18
                            and a.id_impsto          = v_id_impsto;                            
                            
                        insert into pq_g_slctdes_mtvo_sjt_impst ( id_slctud_mtvo     , id_sjto_impsto, id_impsto
                                                                , id_impsto_sbmpsto  , idntfccion      )
                                                            values ( v_id_slctud_mtvo   , v_id_sjto_impsto, v_id_impsto
                                                                , v_id_impsto_sbmpsto, v_pqr.clmna18   );                                        
                    exception
                        when others then
                            o_cdgo_rspsta  := 10;
                            o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el sujeto impuesto. ' || sqlerrm;
                            v_errors.extend;  
                            v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => v_pqr.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                            exit;
                    end;
                end;                                                          
            end;
            if (mod(i,1000) = 0 ) then
                commit;
            end if;                   
        end loop;
        
        begin
            update migra.mg_g_intermedia
                set cdgo_estdo_rgstro = 'S'
                where cdgo_clnte        = p_cdgo_clnte 
                and id_entdad         = p_id_entdad
                and cdgo_estdo_rgstro = 'L';
            
            --Procesos con Errores
            o_ttal_error   := v_errors.count;
            
            --Respuesta Exitosa
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Exito';
            
            forall i in 1..o_ttal_error
            insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                                values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
            
            forall j in 1..o_ttal_error
            update migra.mg_g_intermedia
                set cdgo_estdo_rgstro = 'E'
                where id_intrmdia       = v_errors(j).id_intrmdia;
        
        exception   
                when others then
                    o_cdgo_rspsta  := 15; 
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible realizar la migracion de PQR.' || sqlerrm;
        end;              
    end prc_mg_pqr_ac;
    
    
    */
    /*UP Consulta de flujos*/
	procedure prc_co_flujos_acuerdo_pago( p_cdgo_clnte				in  number
										 ,p_nmro_rdcdo				in  number
										 ,o_id_instncia_fljo		out number
										 ,o_id_instncia_fljo_gnrdo	out number
										 ,o_id_slctud				out number	
										)as
	begin
        
		select a.id_slctud
			,  b.id_instncia_fljo
			,  b.id_instncia_fljo_gnrdo_hjo
		  into o_id_slctud
			,  o_id_instncia_fljo
			,  o_id_instncia_fljo_gnrdo	
		  from pq_g_solicitudes a
		  join wf_g_instancias_flujo_gnrdo b on a.id_instncia_fljo = b.id_instncia_fljo
		 where a.cdgo_clnte = p_cdgo_clnte
		   and a.nmro_rdcdo = p_nmro_rdcdo;
           
	end prc_co_flujos_acuerdo_pago;
    
    /*UP Migracion Acuerdos de pago, cartera y plan de pago generada*/
/*	procedure prc_mg_acrdo_extrcto_crtra( p_id_entdad               in  number
                                        , p_id_prcso_instncia       in  number
                                        , p_id_usrio                in  number
                                        , p_cdgo_clnte              in  number
                                        , o_ttla_cnvnios_mgrdos     out number
                                        , o_ttal_extsos             out number
                                        , o_ttal_error              out number
                                        , o_cdgo_rspsta             out number
                                        , o_mnsje_rspsta            out varchar2
                                         ) as								  

    v_errors            		r_errors := r_errors();	
    v_df_s_clientes             df_s_clientes%rowtype;
    v_acuerdo_pago      		r_mg_g_intrmdia := r_mg_g_intrmdia();
    v_mg_g_intrmdia             r_mg_g_intrmdia;
	v_cartera                   migra.mg_g_intermedia_convenio%rowtype;
    v_id_sjto_impsto			number;
	v_id_impsto					number      := 101;
	v_id_impsto_sbmpsto			number      := 1011;
	v_id_cnvnio					number;
	v_id_instncia_fljo_pdre		number;
	v_id_instncia_fljo_hjo		number;
	v_id_slctud					number;	
	v_id_cnvnio_tpo				number;	
	v_id_prdo					number;
	v_id_orgen					number;	
	v_id_cncpto			        number;
    v_count_cnvnio_mgrdos       number      := 0;
    
	type t_intrmdia_rcrd is record
	(
	   r_cartera	r_mg_g_intrmdia := r_mg_g_intrmdia(),
	   r_extracto	r_mg_g_intrmdia := r_mg_g_intrmdia() 
	);
 
	type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);
	
	v_intrmdia_rcrd g_intrmdia_rcrd;
		
    begin
        
        --Limpia la Cache
        --dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.';
                  return;
        end;
        
        --Consultamos el concepto
        begin
            select 	id_cncpto
              into	v_id_cncpto
              from	df_i_conceptos
             where	cdgo_clnte =  p_cdgo_clnte
               and	id_impsto =  v_id_impsto
               and	cdgo_cncpto = '1';
        exception
            when no_data_found then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := o_cdgo_rspsta || '. No Existe Concepto ';
        end;
        insert into gti_aux (col1, col2) values ('Inicio Acuerdos',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
        --Llena la Coleccion de Intermedia
        select a.*
             , null
          bulk collect  
          into v_mg_g_intrmdia
          from migra.mg_g_intermedia_convenio a
         where a.cdgo_clnte         = p_cdgo_clnte 
           and a.id_entdad          = p_id_entdad
           and a.cdgo_estdo_rgstro  = 'L'
           and a.clmna5             = 'RVC' --'APL'
           and a.clmna1             = 'IPU'
           and a.clmna44            is not null -- id sujeto impuesto
           and a.clmna9             is not null -- Fecha primera cuota
		   --and (a.clmna43           <> 'NM' or a.clmna43 is null)
          -- and a.clmna4              = '2004460001987'
           --and to_number(substr(clmna4, 1, 4))   in(1900)
      order by a.clmna4
             , a.clmna25
             , a.clmna26;
        
		--Verifica si hay Registros Cargado
		if( v_mg_g_intrmdia.count = 0 ) then
		  o_cdgo_rspsta  := 2;
		  o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
		  return;  
		end if;
		
		--Llena la Coleccion de Acuerdos de Pago
        for i in 1..v_mg_g_intrmdia.count loop
            
			--Se definen los indices
            declare
                v_index number;
            begin
			
				if( i = 1 or (i > 1 and v_mg_g_intrmdia(i).clmna4 <> v_mg_g_intrmdia(i-1).clmna4 )) then                  
				  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4) := t_intrmdia_rcrd();
				  v_acuerdo_pago.extend;
				  v_acuerdo_pago(v_acuerdo_pago.count) :=  v_mg_g_intrmdia(i);
				end if;
                
                if (v_mg_g_intrmdia(i).clmna25 is not null) then
                    v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
                    if (v_index > 0) then
                        v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index);                        
                        if(v_mg_g_intrmdia(i).clmna25 || v_mg_g_intrmdia(i).clmna26 != v_cartera.clmna25 || v_cartera.clmna26) then                                               
                            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.extend;
                            v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
                            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index) := v_mg_g_intrmdia(i);
                        end if;
                    else
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.extend;
                        v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index) := v_mg_g_intrmdia(i);
                    end if;
                    
                  v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(1);
                  if(v_mg_g_intrmdia(i).clmna25 = v_cartera.clmna25 and v_mg_g_intrmdia(i).clmna26 = v_cartera.clmna26) then                    
                    if (v_mg_g_intrmdia(i).clmna32 is not null) then 
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.extend;
                        v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.count;
                        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto(v_index) := v_mg_g_intrmdia(i);
                    end if;  
                  end if;                
				end if;
                /*

				if (v_mg_g_intrmdia(i).clmna25 is not null) then
				  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.extend;
				  v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
				  v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index) := v_mg_g_intrmdia(i);
				end if;
                
                if (v_mg_g_intrmdia(i).clmna32 is not null) then 
                    v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.extend;
                    v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.count;
                    v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto(v_index) := v_mg_g_intrmdia(i);
                end if;*/
       /*     end;
			
        end loop;
        
		for i in 1..v_acuerdo_pago.count loop
													
			--definir los flujos de PQR y acuerdos de pago		
			begin
				pkg_mg_migracion.prc_co_flujos_acuerdo_pago( p_cdgo_clnte				=>	p_cdgo_clnte	
															,p_nmro_rdcdo				=>	v_acuerdo_pago(i).clmna42
															,o_id_instncia_fljo			=>	v_id_instncia_fljo_pdre
															,o_id_instncia_fljo_gnrdo	=>	v_id_instncia_fljo_hjo
															,o_id_slctud				=>	v_id_slctud	);
											
			exception
				when others then
					raise_application_error(-20001, ' Error al Consultar Flujos. '||sqlerrm);
			end;
            
			--Insertar Acuerdos de Pago
			begin
                v_id_sjto_impsto    := v_acuerdo_pago(i).clmna44;
								
				insert into gf_g_convenios ( cdgo_clnte,												 	id_sjto_impsto, 				id_cnvnio_tpo,
											 nmro_cnvnio,												 	cdgo_cnvnio_estdo, 				fcha_slctud,
											 nmro_cta,													 	cdgo_prdcdad_cta,				fcha_prmra_cta,
											 ttal_cnvnio,												 	fcha_slctud_rspsta,
											 mtvo_rchzo_slctud,											 	fcha_elbrcion_cnvnio,			fcha_rvctoria,
											 obsrvcion,													 	vlor_cta_incial,				fcha_lmte_cta_incial,
											 id_instncia_fljo_pdre,										 	id_instncia_fljo_hjo,			id_slctud,
											 fcha_aprbcion,												 	id_usrio_aprbcion,
											 fcha_rchzo,												 	id_usrio_rchzo,					fcha_aplccion,
											 id_usrio_aplccion,											 	fcha_anlcn,						id_usrio_anlcn,
											 fcha_rvrsn,												 	id_usrio_rvrsn )
                                             
									 values (p_cdgo_clnte,												 	v_id_sjto_impsto, 				1,
											 to_number(v_acuerdo_pago(i).clmna4),						 	v_acuerdo_pago(i).clmna5, 		to_date(v_acuerdo_pago(i).clmna6, 'DD/MM/YYYY'),
											 v_acuerdo_pago(i).clmna7,									 	v_acuerdo_pago(i).clmna8,		to_date(v_acuerdo_pago(i).clmna9, 'DD/MM/YYYY'), 
											 v_acuerdo_pago(i).clmna10,									 	to_date(v_acuerdo_pago(i).clmna12, 'DD/MM/YYYY'),		
											 v_acuerdo_pago(i).clmna13,									 	to_date(v_acuerdo_pago(i).clmna14, 'DD/MM/YYYY'),		to_date(v_acuerdo_pago(i).clmna15, 'DD/MM/YYYY'),
											 nvl(v_acuerdo_pago(i).clmna16, 'Acuerdo Migrado '||sysdate),	v_acuerdo_pago(i).clmna17,		to_date(v_acuerdo_pago(i).clmna18, 'DD/MM/YYYY'),
											 v_id_instncia_fljo_pdre,									 	v_id_instncia_fljo_hjo,			v_id_slctud,													
											 to_date(v_acuerdo_pago(i).clmna20, 'DD/MM/YYYY'),				p_id_usrio,
											 to_date(v_acuerdo_pago(i).clmna21, 'DD/MM/YYYY'),				p_id_usrio,						v_acuerdo_pago(i).clmna22,
											 p_id_usrio,												 	to_date(v_acuerdo_pago(i).clmna20, 'DD/MM/YYYY'),		p_id_usrio,
											 to_date(v_acuerdo_pago(i).clmna24, 'DD/MM/YYYY'),				p_id_usrio	 ) returning id_cnvnio into v_id_cnvnio;					
			exception
				when others then
					rollback;
					o_cdgo_rspsta  := 5;
					o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar acuerdo de pago acuerdo No. '||v_acuerdo_pago(i).clmna4 || sqlerrm;					                    
                    v_errors.extend;  
					v_errors( v_errors.count ) := t_errors( id_intrmdia => v_acuerdo_pago(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;

			end;
			
			for j in 1..v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera.count loop

				--Consultamos el id_prdo
				begin
					select 	id_prdo
					  into	v_id_prdo
					  from	df_i_periodos
					 where	cdgo_clnte              = p_cdgo_clnte
					   and	id_impsto               = v_id_impsto
					   and	id_impsto_sbmpsto       = v_id_impsto_sbmpsto
					   and	vgncia                  =  v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna25
					   and	prdo                    =  v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna26;				   
				exception
					when no_data_found then
						rollback;
						o_cdgo_rspsta  := 6;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar acuerdo de pago';
						v_errors.extend;  
						v_errors( v_errors.count ) := t_errors( id_intrmdia => v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
                --v_id_orgen := '1';
				-- Consultamos el origen del acuerdo
				begin
					 select id_orgen
					   into v_id_orgen
					   from gf_g_movimientos_financiero
					  where cdgo_clnte          = p_cdgo_clnte
						and id_impsto           = v_id_impsto
						and id_impsto_sbmpsto   = v_id_impsto_sbmpsto
						and id_sjto_impsto      = v_id_sjto_impsto
						and vgncia              = v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna25
						and id_prdo             = v_id_prdo;
				exception
					when no_data_found then
						rollback;
						o_cdgo_rspsta  := 7;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontro el origen del acuerdo de pago';
						v_errors.extend;  
						v_errors( v_errors.count ) := t_errors( id_intrmdia => v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
						continue;
				end;
				
				--Insertamos los datos de cartera convenida
				begin
					insert into gf_g_convenios_cartera (id_cnvnio, 		vgncia,
														id_prdo,		id_cncpto,
														vlor_cptal,		vlor_intres,
														id_orgen,     	cdgo_mvmnto_orgen
														) 
						values (v_id_cnvnio,													v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna25,
								v_id_prdo,														v_id_cncpto,
								v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna28,	v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna29,
								v_id_orgen,														v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna30	
								);
				exception
					when others then
						rollback;
						o_cdgo_rspsta  := 8;
						o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar cartera de acuerdo de pago';
						return;						
				end;
				
			end loop;
			
			for k in 1..v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto.count loop 	
                
                if ( v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna32 is not null) then
                
                    --Insertamos los datos del plan de pago
                    begin
                        insert into gf_g_convenios_extracto (id_cnvnio, 			nmro_cta,
                                                             fcha_vncmnto,			vlor_ttal,
                                                             vlor_fncncion,			vlor_cptal,
                                                             vlor_intres,			indcdor_cta_pgda,
                                                             fcha_pgo_cta,			actvo) 
                                                     values (v_id_cnvnio,			v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna32,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna33,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna34,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna35,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna36,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna37,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna38,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna40,
                                                             v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna41
                                                            );
                    
                    exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 9;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar plan de pago de acuerdo de pago' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := t_errors( id_intrmdia => v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        return;		
                    end;
                    
				end if;
                
			end loop;            
                v_count_cnvnio_mgrdos    := v_count_cnvnio_mgrdos + 1;               
            commit;
		end loop;
		
		insert into gti_aux (col1, col2) values ('Termino Acuerdos',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
        /*for i in 1..v_mg_g_intrmdia.count loop
            update migra.mg_g_intermedia_convenio
               set cdgo_estdo_rgstro = 'S'
                 , clmna46           = 'S'
             where cdgo_clnte        = p_cdgo_clnte 
               and id_entdad         = p_id_entdad
               and id_intrmdia       = v_mg_g_intrmdia(i).id_intrmdia;
        end loop;*/
        
        --Procesos con Errores
       /* o_ttla_cnvnios_mgrdos   := v_count_cnvnio_mgrdos;
        o_ttal_error            := v_errors.count;
        o_ttal_extsos           := v_mg_g_intrmdia.count - v_errors.count;
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        insert into gti_aux (col1, col2) values ('inicio error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                         values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
        
        insert into gti_aux (col1, col2) values ('termino error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am')); commit;
        
        forall j in 1..o_ttal_error
            update migra.mg_g_intermedia_convenio
               set cdgo_estdo_rgstro = 'E'
                 , clmna46           = 'N'
             where id_intrmdia       = v_errors(j).id_intrmdia;
		insert into gti_aux (col1, col2) values ('termino actualizacion de interm con error',  to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));commit;
    end prc_mg_acrdo_extrcto_crtra;
    
    /*UP Migracion Revocatoria de Acuerdos de pago*/
/*	procedure prc_mg_acuerdo_revocatoria(  p_id_entdad          	in  number
										  , p_id_prcso_instncia 	in  number
										  , p_id_usrio          	in  number
										  , p_cdgo_clnte        	in  number
										  , o_ttal_extsos       	out number
										  , o_ttal_error        	out number
										  , o_cdgo_rspsta       	out number
										  , o_mnsje_rspsta      	out varchar2 ) 
	
	as								  

    v_errors            	r_errors := r_errors();
	v_df_s_clientes     	df_s_clientes%rowtype;
	v_mg_g_intrmdia         r_mg_g_intrmdia;
	v_id_cnvnio				number;		
	
    begin

        --Limpia la Cache
        dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
				o_cdgo_rspsta  := 1;
				o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.';
				return;
        end;
       
        --Llena la Coleccion de Intermedia
        select a.*
          bulk collect  
          into v_mg_g_intrmdia
          from migra.mg_g_intermedia a
         where a.cdgo_clnte        = p_cdgo_clnte 
           and a.id_entdad         = p_id_entdad
           and a.cdgo_estdo_rgstro = 'L'
      order by a.clmna1;
        
		--Verifica si hay Registros Cargado
		if( v_mg_g_intrmdia.count = 0 ) then
		  o_cdgo_rspsta  := 2;
		  o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
		  return;  
		end if;
		
        for i in 1..v_mg_g_intrmdia.count loop
			
			-- Consultamos el id_cnvnio
			begin
				select	id_cnvnio
				  into	v_id_cnvnio
				  from	gf_g_convenios
				 where	cdgo_clnte =  p_cdgo_clnte
				   and	nmro_cnvnio = v_mg_g_intrmdia(i).clmna1;			
			exception
				when others then
					o_cdgo_rspsta := 3;
					o_mnsje_rspsta := o_cdgo_rspsta ||'. No se encontro el acuerdo de pago';
					v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => v_mg_g_intrmdia(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;
				
			-- Insertamos revocatoria de acuerdo de pago
			begin
				insert into gf_g_convenios_revocatoria(id_cnvnio, 			id_rvctria_mtdo,		cdgo_cnvnio_rvctria_estdo,
													   id_usrio,			fcha_rgstro,			
													   fcha_aplccion,		id_usrio_aplccion,		
													   fcha_anlcion,		id_usrio_anlcion,
													   anlcion_actva	
													   )
												values(v_id_cnvnio,					1,							v_mg_g_intrmdia(i).clmna8,
													   p_id_usrio,					v_mg_g_intrmdia(i).clmna9,
													   v_mg_g_intrmdia(i).clmna12,	p_id_usrio,
													   v_mg_g_intrmdia(i).clmna13,	p_id_usrio,
													   v_mg_g_intrmdia(i).clmna14
														);
			exception
            when others then
				rollback;
				o_cdgo_rspsta  := 4;
				o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar plan de pago de acuerdo de pago';
				exit;
			end;           
			
		end loop;
		
		update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'S'
         where cdgo_clnte        = p_cdgo_clnte 
           and id_entdad         = p_id_entdad
           and cdgo_estdo_rgstro = 'L';
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;        
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , 	id_intrmdia , 				error )
                                         values( p_id_prcso_instncia , 	v_errors(i).id_intrmdia , 	v_errors(i).mnsje_rspsta );
        
        forall j in 1..o_ttal_error
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia       = v_errors(j).id_intrmdia;
		
	end prc_mg_acuerdo_revocatoria;
  
  */
    
    /*UP Migracion Garantia de Acuerdos de pago*/
	/*procedure prc_mg_acuerdo_garantias(  p_id_entdad         	in  number
									   , p_id_prcso_instncia 	in  number
									   , p_id_usrio          	in  number
									   , p_cdgo_clnte        	in  number
									   , o_ttal_extsos       	out number
									   , o_ttal_error        	out number
									   , o_cdgo_rspsta       	out number
									   , o_mnsje_rspsta      	out varchar2 
                                       ) 
	
	as								  

    v_errors            	r_errors := r_errors();	
	v_df_s_clientes     	df_s_clientes%rowtype;
	v_mg_g_intrmdia         r_mg_g_intrmdia;
	v_id_cnvnio				number;
	v_id_grntia_tpo			number;
		
    begin

        --Limpia la Cache
        dbms_result_cache.flush;
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
        begin
            select a.* 
              into v_df_s_clientes
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
        exception
             when no_data_found then                 
				o_cdgo_rspsta  := 1;
				o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' || p_cdgo_clnte || ', no existe en el sistema.';
				return;
        end;
        
        --Llena la Coleccion de Intermedia
        select a.*
          bulk collect  
          into v_mg_g_intrmdia
          from migra.mg_g_intermedia_convenio a
         where a.cdgo_clnte        = p_cdgo_clnte 
           and a.id_entdad         = p_id_entdad
           and a.cdgo_estdo_rgstro = 'L'
      order by a.clmna1;
        
		--Verifica si hay Registros Cargado
		if( v_mg_g_intrmdia.count = 0 ) then
		  o_cdgo_rspsta  := 2;
		  o_mnsje_rspsta := o_cdgo_rspsta || '. No existen registros cargados en intermedia, para el cliente #' || p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
		  return;  
		end if;
		
		--Llena la Coleccion de Predio Responsables
        for i in 1..v_mg_g_intrmdia.count loop
            
            -- Consultamos el id_cnvnio
			begin
				select	id_cnvnio
				  into	v_id_cnvnio
				  from	gf_g_convenios
				 where	cdgo_clnte =  p_cdgo_clnte
				   and	nmro_cnvnio = v_mg_g_intrmdia(i).clmna1;			
			exception
				when others then
					o_cdgo_rspsta := 3;
					o_mnsje_rspsta := o_cdgo_rspsta ||'. No se encontro el acuerdo de pago '||v_mg_g_intrmdia(i).clmna1;
					v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => v_mg_g_intrmdia(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;
			
			-- Consultamos el id_grntia_tpo
			begin
				select 	id_grntia_tpo
				  into	v_id_grntia_tpo
				  from 	gf_d_garantias_tipo
				 where	cdgo_clnte =  p_cdgo_clnte
				   and	cdgo_grntia_tpo = v_mg_g_intrmdia(i).clmna2; 				   
			exception
				when others then
					o_cdgo_rspsta := 4;
					o_mnsje_rspsta := o_cdgo_rspsta ||'. No se encontro el tipo de garantia. '||v_mg_g_intrmdia(i).clmna1;
					v_errors.extend;  
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => v_mg_g_intrmdia(i).id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
			end;	
				
			-- Insertamos garantias de acuerdo de pago
			begin
				insert into gf_g_convenios_garantia(id_cnvnio, 			id_grntia_tpo,			dscrpcion)
											values(v_id_cnvnio,			v_id_grntia_tpo,		v_mg_g_intrmdia(i).clmna3);
				
				-- Actualizamos el tipo de acuerdo de pago				
				update gf_g_convenios set id_cnvnio_tpo = 4 where id_cnvnio = v_id_cnvnio;				
				
			exception
				when others then				
					rollback;
					o_cdgo_rspsta  := 4;
					o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo insertar la garantia de acuerdo de pago';
					exit;
			end;
			
        end loop;
		
		update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'S'
         where cdgo_clnte        = p_cdgo_clnte 
           and id_entdad         = p_id_entdad
           and cdgo_estdo_rgstro = 'L';
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                         values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
        
        forall j in 1..o_ttal_error
        update migra.mg_g_intermedia
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia       = v_errors(j).id_intrmdia;
		
	end prc_mg_acuerdo_garantias;
    
    /*UP Migracion Procesos Juridicos y responsables de los procesos*/
    
    /*procedure prc_mg_proceso_juridico_responsables(  p_id_entdad          	in  number
                                                      , p_id_prcso_instncia 	in  number
                                                      , p_id_usrio          	in  number
                                                      , p_cdgo_clnte        	in  number
                                                      , o_ttal_extsos       	out number
                                                      , o_ttal_error        	out number
                                                      , o_cdgo_rspsta       	out number
                                                      , o_mnsje_rspsta      	out varchar2 ) 
	
	as								  
    
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();        
        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;
    
    begin
    
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
        
        
    
        null;
        
    end prc_mg_proceso_juridico_responsables;*/
    
    procedure prc_mg_embargos_cartera(  p_id_entdad          	in  number
                                      , p_id_prcso_instncia 	in  number
                                      , p_id_usrio          	in  number
                                      , p_cdgo_clnte        	in  number
                                      , o_ttal_extsos       	out number
                                      , o_ttal_error        	out number
                                      , o_cdgo_rspsta       	out number
                                      , o_mnsje_rspsta      	out varchar2 ) 
	
	as
    
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();        
        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;
        v_id_fljo               wf_d_flujos.id_fljo%type;
        v_id_fljo_trea          v_wf_d_flujos_transicion.id_fljo_trea%type;
        
        v_id_instncia_fljo       wf_g_instancias_flujo.id_instncia_fljo%type;
        v_mnsje	                 varchar2(4000);
        
        v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
        v_id_lte_mdda_ctlar     mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
        v_id_estdos_crtra       mc_d_estados_cartera.id_estdos_crtra%type;
        v_cnsctivo_lte          mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
        v_cdgo_crtra            mc_g_embargos_cartera.cdgo_crtra%type;
        v_id_tpos_mdda_ctlar    mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
        v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
        
        v_id_sjto               si_c_sujetos.id_sjto%type;
        v_id_sjto_impsto		number;
        v_id_impsto				number;
        v_id_impsto_sbmpsto		number;
        
        v_id_mvmnto_fncro       v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
        v_vgncia                v_gf_g_cartera_x_concepto.vgncia%type;
        v_id_prdo               v_gf_g_cartera_x_concepto.id_prdo%type;
        v_id_cncpto             v_gf_g_cartera_x_concepto.id_cncpto%type;
        v_cdgo_mvmnto_orgn      v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
        v_id_orgen              v_gf_g_cartera_x_concepto.id_orgen%type;
    
        v_vlor_cptal            number(15);
        v_vlor_intrs            number(15);
        v_vlor_embrgo           number(15);
        
    begin
        
        o_ttal_extsos := 0;
        o_ttal_error  := 0;
        
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
        
        --1. buscar los datos del flujo
            begin
            
                select id_fljo
                  into v_id_fljo
                  from wf_d_flujos 
                 where cdgo_fljo = 'FMC'
                   and cdgo_clnte = p_cdgo_clnte;
            
            exception when no_data_found then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := o_cdgo_rspsta || '. error al iniciar la medida cautelar. no se encontraron datos del flujo.';
                return;
            end;
            
            begin
                --EXTRAEMOS EL VALOS DE LA PRIMERA TAREA DEL FLIJO
                select distinct first_value(a.id_fljo_trea) over (order by b.orden )
                  into v_id_fljo_trea
                  from v_wf_d_flujos_transicion a
             left join wf_d_flujos_tarea_estado b
                    on b.id_fljo_trea = a.id_fljo_trea
                   and a.indcdor_procsar_estdo = 'S'
                  join wf_d_tareas c
                    on c.id_trea = a.id_trea_orgen
                 where a.id_fljo = v_id_fljo
                   and a.indcdor_incio = 'S'; 
                   
            exception when no_data_found then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := o_cdgo_rspsta || '. error al iniciar la medida cautelar.no se encontraron datos de configuracion del flujo.';
                return; 
            end;
            
        --2. buscar datos del usuario
        
        begin
        
            select u.id_fncnrio
              into v_id_fncnrio
              from v_sg_g_usuarios u
             where u.id_usrio = p_id_usrio;                     
        
        exception when no_data_found then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
            return;       
        end;
        
        --3. insertar en lote de medida cautelar
        begin
            v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
                    
            insert into mc_g_lotes_mdda_ctlar (nmro_cnsctvo  ,fcha_lte,tpo_lte,id_fncnrio,cdgo_clnte)
                                        values(v_cnsctivo_lte,sysdate    ,'I'    ,v_id_fncnrio,p_cdgo_clnte)
                                returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
                                
        exception when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '. Error al generar el lote de investigacion de medida cautelar.';
            return;       
        end;
        
        --4. datos del primer estado de la cartera de 
        begin
            
            select distinct first_value(a.id_estdos_crtra) over (order by a.orden ) as cdgo_estdos_crtra
              into v_id_estdos_crtra
              from mc_d_estados_cartera a
              join v_wf_d_flujos_tarea b on b.id_fljo_trea = a.id_fljo_trea
                                      and b.cdgo_clnte = p_cdgo_clnte;
                                              
        exception when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '. Error al generar el lote de investigacion de medida cautelar.';
            return;       
        end;                                       
        
        --Cursor de la cartera de los embargos
            for c_crtra_embrgo in (
                                    select  /*+ parallel(a, clmna2) */
                                            min(a.id_intrmdia) id_intrmdia,
                                            a.clmna1,   --codigo de cartera
                                            a.clmna2,   --Identificacion del sujeto                                            
                                            a.clmna10,  --tipo de medida cautelar 
                                            json_arrayagg(
                                                json_object(
                                                            'id_intrmdia'	value a.id_intrmdia,
                                                            'clmna3' 		value	a.clmna3, --vigencia
                                                            'clmna4' 		value	a.clmna4, --periodo
                                                            'clmna5' 		value	a.clmna5, --concepto
                                                            'clmna6' 		value	a.clmna6, --impuesto
                                                            'clmna7' 		value	a.clmna7, --sub_impuesto
                                                            'clmna8' 		value	a.clmna8, --valor capital
                                                            'clmna9' 		value	a.clmna9  --valor interes
                                                            returning clob
                                                           )
                                                           returning clob
                                                        ) json_detalle_cartera
                                    from    migra.mg_g_intermedia_juridico   a
                                    where   a.cdgo_clnte        =   p_cdgo_clnte
                                    and     a.id_entdad         =   p_id_entdad
                                    and     a.cdgo_estdo_rgstro =   'L'
                                    group by a.clmna1,  --codigo de cartera
                                            a.clmna2,  --Identificacion del sujeto
                                            a.clmna10  --tipo de medida cautelar
                                                
                                 )
            loop
                --5. buscar datos del tipo de medida cautelar
                begin 
                    
                    select a.id_tpos_mdda_ctlar
                    into v_id_tpos_mdda_ctlar
                    from mc_d_tipos_mdda_ctlar a
                    where a.cdgo_tpos_mdda_ctlar = c_crtra_embrgo.clmna10;
                    
                exception when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. Error al generar el lote de investigacion de medida cautelar.';
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_crtra_embrgo.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
					continue;
                end;     
                
                --6. buscar el sujeto
                begin 
                    select  a.id_sjto
                    into    v_id_sjto
                    from    si_c_sujetos    a
                    where   a.cdgo_clnte    =   p_cdgo_clnte
                    and     a.idntfccion_antrior    =   c_crtra_embrgo.clmna2;
                exception
                    when others then
                        o_cdgo_rspsta   := 6;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la identificacion del sujeto en la tabla si_c_sujetos. ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_crtra_embrgo.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
            
            --7. insertar en carteras 
            
            --INSERTAMOS LA CARTERA
            --v_cdgo_crtra := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'CIC');
            insert into mc_g_embargos_cartera (cdgo_clnte  ,cdgo_crtra           ,id_estdos_crtra  ,id_tpos_mdda_ctlar  ,fcha_ingrso   ,id_lte_mdda_ctlar)
                                       values (p_cdgo_clnte,c_crtra_embrgo.clmna1,v_id_estdos_crtra,v_id_tpos_mdda_ctlar,trunc(sysdate),v_id_lte_mdda_ctlar)
                                    returning id_embrgos_crtra into v_id_embrgos_crtra;
            --insertamos el sujeto
            --8. insertar el sujeto asociado a la cartera.
            insert into mc_g_embargos_sjto (id_embrgos_crtra,id_sjto)
                                        values (v_id_embrgos_crtra,v_id_sjto);    
            
            v_vlor_cptal := 0;
            v_vlor_intrs := 0;
            
            for c_crtra_dtlle in (
                                select  a.*
                                from    json_table(c_crtra_embrgo.json_detalle_cartera, '$[*]'
                                                   columns (id_intrmdia number         path '$.id_intrmdia',
                                                            clmna3     varchar2(4000)  path '$.clmna3', --vigencia
                                                            clmna4     varchar2(4000)  path '$.clmna4', --periodo
                                                            clmna5     varchar2(4000)  path '$.clmna5', --concepto
                                                            clmna6     varchar2(4000)  path '$.clmna6', --impuesto
                                                            clmna7     varchar2(4000)  path '$.clmna7', --sub_impuesto
                                                            clmna8     varchar2(4000)  path '$.clmna8', --valor capital
                                                            clmna9     varchar2(4000)  path '$.clmna9'  --valor interes
                                                            ))  a
                                )
            loop
                
                begin 
                    --9. buscamos los datos del sujeto de impuesto, impuesto y sub impuesto.
                    select 	a.id_sjto_impsto
                        ,	a.id_impsto
                        ,	c.id_impsto_sbmpsto
                      into 	v_id_sjto_impsto
                        ,	v_id_impsto
                        ,	v_id_impsto_sbmpsto		
                      from 	si_i_sujetos_impuesto a 
                      join 	df_c_impuestos b on a.id_impsto = b.id_impsto
                      join 	df_i_impuestos_subimpuesto c on c.id_impsto = a.id_impsto
                      join 	si_c_sujetos d on d.id_sjto  = a.id_sjto
                     where 	b.cdgo_clnte = p_cdgo_clnte 
                       and 	b.cdgo_impsto = c_crtra_dtlle.clmna6
                       and 	c.cdgo_impsto_sbmpsto = c_crtra_dtlle.clmna7
                       and 	d.idntfccion_antrior = c_crtra_embrgo.clmna2
                       and  d.id_sjto = v_id_sjto;
                       
                    --10. buscamos los datos adicionales de la cartera
                    select a.id_mvmnto_fncro,a.vgncia,a.id_prdo,a.id_cncpto,a.cdgo_mvmnto_orgn,a.id_orgen
                      into v_id_mvmnto_fncro,v_vgncia,v_id_prdo,v_id_cncpto,v_cdgo_mvmnto_orgn,v_id_orgen
                      from v_gf_g_cartera_x_concepto a
                     where a.cdgo_clnte = p_cdgo_clnte
                       and a.id_impsto = v_id_impsto
                       and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                       and a.id_sjto_impsto = v_id_sjto_impsto
                       and a.vgncia = c_crtra_dtlle.clmna3
                       and a.prdo = c_crtra_dtlle.clmna4
                       and a.cdgo_cncpto = c_crtra_dtlle.clmna5
                     group by a.id_mvmnto_fncro,a.vgncia,a.id_prdo,a.id_cncpto,a.cdgo_mvmnto_orgn,a.id_orgen;  
                    
                    --11. insertamos en el detalle de cartera.
                    insert into mc_g_embargos_cartera_detalle( id_embrgos_crtra , id_sjto_impsto            , vgncia                , 
                                                             id_prdo            , id_cncpto                 , vlor_cptal            , vlor_intres            ,
                                                             cdgo_clnte           ,id_impsto                  ,id_impsto_sbmpsto            ,cdgo_mvmnto_orgn,
                                                             id_orgen             ,id_mvmnto_fncro)
                                                    values ( v_id_embrgos_crtra , v_id_sjto_impsto  , v_vgncia    , 
                                                             v_id_prdo, v_id_cncpto     , c_crtra_dtlle.clmna8, c_crtra_dtlle.clmna9,
                                                             p_cdgo_clnte,v_id_impsto      ,v_id_impsto_sbmpsto,v_cdgo_mvmnto_orgn,
                                                             v_id_orgen ,v_id_mvmnto_fncro);
                                                             
                    v_vlor_cptal := v_vlor_cptal + c_crtra_dtlle.clmna8;
                    v_vlor_intrs := v_vlor_intrs + c_crtra_dtlle.clmna9;
                exception
                    when others then
                        o_cdgo_rspsta   := 7;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo insertarse el detalle de la cartera porque no se encontraron datos. ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_crtra_embrgo.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                end;
            end loop;
                    
                    v_vlor_embrgo := (2*v_vlor_cptal)+v_vlor_intrs;
                     
                     --12. generamos la instacia de flujo
                     pkg_pl_workflow_1_0.prc_rg_instancias_flujo( p_id_fljo          => v_id_fljo,
                                                                  p_id_usrio         => p_id_usrio,
                                                                  p_id_prtcpte       => null,
                                                                  o_id_instncia_fljo => v_id_instncia_fljo ,
                                                                  o_id_fljo_trea     => v_id_fljo_trea,
                                                                  o_mnsje            => v_mnsje); 
                    
                    if v_id_instncia_fljo is null then
                        rollback;
                        o_cdgo_rspsta   := 12;
                        o_mnsje_rspsta  := 'Codigo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la identificacion del sujeto en la tabla si_c_sujetos. ' || sqlerrm;
                        v_errors.extend;  
                        v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_crtra_embrgo.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                        continue;
                     end if;
                     
                     --13. actualizamos el valor del embargo y la instancia de flujo en la cartera
                     update mc_g_embargos_cartera 
                        set id_instncia_fljo = v_id_instncia_fljo,
                            vlor_mdda_ctlar = v_vlor_embrgo
                      where id_embrgos_crtra  = v_id_embrgos_crtra; 
                
               
                
                -- se hace commit por cada registro de cartera guardado de forma correcta.
                commit;
                
            end loop;
            
        update migra.mg_g_intermedia_juridico
           set cdgo_estdo_rgstro = 'S'
         where cdgo_clnte        = p_cdgo_clnte 
           and id_entdad         = p_id_entdad
           and cdgo_estdo_rgstro = 'L';
        
        --Procesos con Errores
        o_ttal_error   := v_errors.count;
        
        --Respuesta Exitosa
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';
        
        forall i in 1..o_ttal_error
        insert into migra.mg_g_intermedia_error( id_prcso_instncia , id_intrmdia , error )
                                         values( p_id_prcso_instncia , v_errors(i).id_intrmdia , v_errors(i).mnsje_rspsta );
        
        forall j in 1..o_ttal_error
        update migra.mg_g_intermedia_juridico
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia       = v_errors(j).id_intrmdia;
            
    end prc_mg_embargos_cartera;
    
    procedure  prc_mg_embargos_oficios(  p_id_entdad          	in  number
                                      , p_id_prcso_instncia 	in  number
                                      , p_id_usrio          	in  number
                                      , p_cdgo_clnte        	in  number
                                      , o_ttal_extsos       	out number
                                      , o_ttal_error        	out number
                                      , o_cdgo_rspsta       	out number
                                      , o_mnsje_rspsta      	out varchar2 ) 
	
	as
    
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();        
        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;
        v_id_fljo               wf_d_flujos.id_fljo%type;
        v_id_fljo_trea          v_wf_d_flujos_transicion.id_fljo_trea%type;
        
        v_id_instncia_fljo       wf_g_instancias_flujo.id_instncia_fljo%type;
        v_mnsje	                 varchar2(4000);
        
        v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
        v_id_lte_mdda_ctlar     mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
        v_id_estdos_crtra       mc_d_estados_cartera.id_estdos_crtra%type;
        v_cnsctivo_lte          mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
        v_cdgo_crtra            mc_g_embargos_cartera.cdgo_crtra%type;
        v_id_tpos_mdda_ctlar    mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
        v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
        
        v_id_sjto               si_c_sujetos.id_sjto%type;
        v_id_sjto_impsto		number;
        v_id_impsto				number;
        v_id_impsto_sbmpsto		number;
        
        v_id_mvmnto_fncro       v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
        v_vgncia                v_gf_g_cartera_x_concepto.vgncia%type;
        v_id_prdo               v_gf_g_cartera_x_concepto.id_prdo%type;
        v_id_cncpto             v_gf_g_cartera_x_concepto.id_cncpto%type;
        v_cdgo_mvmnto_orgn      v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
        v_id_orgen              v_gf_g_cartera_x_concepto.id_orgen%type;
    
        v_vlor_cptal            number(15);
        v_vlor_intrs            number(15);
        v_vlor_embrgo           number(15);
        
        v_cnsctvo_embrgo        mc_g_embargos_resolucion.cnsctvo_embrgo%type;
        v_id_embrgos_rspnsble   mc_g_embargos_responsable.id_embrgos_rspnsble%type;
        v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
        
        v_id_acto_tpo_rslcion   gn_d_actos_tipo.id_acto_tpo%type;
        v_id_acto_tpo_ofcio_emb gn_d_actos_tipo.id_acto_tpo%type;
        v_id_acto_tpo_ofcio_inv gn_d_actos_tipo.id_acto_tpo%type;
        v_vlor_mdda_ctlar       mc_g_embargos_cartera.vlor_mdda_ctlar%type;
        
        v_json_actos            clob;
        v_slct_sjto_impsto      varchar2(4000);
        v_slct_rspnsble         varchar2(4000);
        v_slct_vgncias          varchar2(4000);
        v_error                 varchar2(4000);
        v_id_acto_rslcion       mc_g_solicitudes_y_oficios.id_acto_slctud%type;
        v_id_acto_ofcio_emb     mc_g_solicitudes_y_oficios.id_acto_slctud%type;
        v_id_acto_ofcio_inv     mc_g_solicitudes_y_oficios.id_acto_slctud%type;
        v_cdgo_rspsta           number;
        v_id_slctd_ofcio        mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
        /*v_id_fljo_trea          mc_d_estados_cartera.id_fljo_trea%type;
        v_id_instncia_fljo      mc_g_embargos_cartera.id_instncia_fljo%type;*/
        
    begin
    
        --1. buscar datos del usuario
        
        begin
        
            select u.id_fncnrio
              into v_id_fncnrio
              from v_sg_g_usuarios u
             where u.id_usrio = p_id_usrio;                     
        
        exception when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
            return;       
        end;
        
        --2. insertar en lote de medida cautelar
        begin
            v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
                    
            insert into mc_g_lotes_mdda_ctlar (nmro_cnsctvo  ,fcha_lte,tpo_lte,id_fncnrio,cdgo_clnte)
                                        values(v_cnsctivo_lte,sysdate    ,'E'    ,v_id_fncnrio,p_cdgo_clnte)
                                returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
                                
        exception when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. Error al generar el lote de investigacion de medida cautelar.';
            return;       
        end;
        
        
        --3. buscamos id_acto_tpo de los tipos de actos de investigacion y embargo
        begin 
            select a.id_acto_tpo
            into v_id_acto_tpo_rslcion
            from v_gn_d_actos_tipo a
            where a.cdgo_acto_tpo = 'RC2'
            and a.cdgo_clnte = p_cdgo_clnte; -- RESOLUCION DE EMBARGO
        exception when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontraron datos del acto de resolucion de embargo.';
            return;       
        end;
        
        begin
            select a.id_acto_tpo
            into v_id_acto_tpo_ofcio_emb
            from v_gn_d_actos_tipo a
            where a.cdgo_acto_tpo = 'MC2'
            and a.cdgo_clnte = p_cdgo_clnte; -- OFICIO DE EMBARGO
        exception when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontraron datos del acto de oficio de embargo.';
            return;       
        end;
        
        begin 
            select a.id_acto_tpo
            into v_id_acto_tpo_ofcio_inv
            from v_gn_d_actos_tipo a
            where a.cdgo_acto_tpo = 'MC1'
            and a.cdgo_clnte = p_cdgo_clnte; -- OFICIO DE INVESTIGACION DE BIENES
        exception when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontraron datos del acto de oficio de investigacion.';
            return;       
        end;
        
        begin 
            select b.id_estdos_crtra,b.id_fljo_trea
            into v_id_estdos_crtra, v_id_fljo_trea
            from mc_d_estados_cartera b
            where b.cdgo_estdos_crtra = 'E'
            and b.cdgo_clnte = p_cdgo_clnte;
        exception when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontraron datos de los estado de la cartera.';
            return;       
        end;
        
        --3. recorremos la tabla de intermedia
        
        for c_embrgos in (
                                    select  /*+ parallel(a, clmna2) */
                                            min(a.id_intrmdia) id_intrmdia,
                                            a.clmna1,   --codigo de cartera -- es el codigo del expediente en valledupar
                                            -- datos de resolucion de embargo
                                            a.clmna2,   --resolucion de embargo
                                            a.clmna3,   --fecha de embargo
                                            -- datos de oficio de embargo
                                            a.clmna4,   -- numero oficio de embargo
                                            a.clmna5,   --fecha de oficio de embargo
                                            -- datos de investigacion
                                            a.clmna6,   -- entidad embargada  -- no existen datos
                                            a.clmna7,   --numero de solicitud -- no existen datos
                                            a.clmna8,   --fecha de solicitud  -- no existen datos
                                            -- datos del responsable
                                            a.clmna9,   --tipo identificacion
                                            a.clmna10,  --identificacion responsable
                                            a.clmna11,  --primer nombre
                                            a.clmna12,  --segundo nombre
                                            a.clmna13,  --primer apellido
                                            a.clmna14,  --segundo apellido
                                            a.clmna15,  --direccion
                                            a.clmna16,  --email
                                            a.clmna17,  --telefono
                                            a.clmna18,  --celular
                                            a.clmna19,  --responsable principal
                                            a.clmna20,  --pais del responsable
                                            a.clmna21,  --departamento responsable
                                            a.clmna22/*,  --municipio responsable
                                            json_arrayagg(
                                                json_object(
                                                            'id_intrmdia'	value a.id_intrmdia,
                                                            'clmna3' 		value	a.clmna3, --vigencia
                                                            'clmna4' 		value	a.clmna4, --periodo
                                                            'clmna5' 		value	a.clmna5, --concepto
                                                            'clmna6' 		value	a.clmna6, --impuesto
                                                            'clmna7' 		value	a.clmna7, --sub_impuesto
                                                            'clmna8' 		value	a.clmna8, --valor capital
                                                            'clmna9' 		value	a.clmna9  --valor interes
                                                            returning clob
                                                           )
                                                           returning clob
                                                        ) json_detalle_cartera*/
                                    from    migra.mg_g_intermedia_juridico   a
                                    where   a.cdgo_clnte        =   p_cdgo_clnte
                                    and     a.id_entdad         =   p_id_entdad
                                    and     a.cdgo_estdo_rgstro =   'L'
                                    group by a.clmna1,   --codigo de cartera -- es el codigo del expediente en valledupar
                                            -- datos de resolucion de embargo
                                            a.clmna2,   --resolucion de embargo
                                            a.clmna3,   --fecha de embargo
                                            -- datos de oficio de embargo
                                            a.clmna4,   -- numero oficio de embargo
                                            a.clmna5,   --fecha de oficio de embargo
                                            -- datos de investigacion
                                            a.clmna6,   -- entidad embargada  -- no existen datos
                                            a.clmna7,   --numero de solicitud -- no existen datos
                                            a.clmna8,   --fecha de solicitud  -- no existen datos
                                            -- datos del responsable
                                            a.clmna9,   --tipo identificacion
                                            a.clmna10,  --identificacion responsable
                                            a.clmna11,  --primer nombre
                                            a.clmna12,  --segundo nombre
                                            a.clmna13,  --primer apellido
                                            a.clmna14,  --segundo apellido
                                            a.clmna15,  --direccion
                                            a.clmna16,  --email
                                            a.clmna17,  --telefono
                                            a.clmna18,  --celular
                                            a.clmna19,  --responsable principal
                                            a.clmna20,  --pais del responsable
                                            a.clmna21,  --departamento responsable
                                            a.clmna22  --municipio responsable
                                                
                                 )
            loop
                
                begin
                    select a.id_embrgos_crtra,a.id_tpos_mdda_ctlar,a.vlor_mdda_ctlar,a.id_instncia_fljo
                      into v_id_embrgos_crtra,v_id_tpos_mdda_ctlar,v_vlor_mdda_ctlar,v_id_instncia_fljo
                      from mc_g_embargos_cartera a
                     where a.cdgo_crtra = c_embrgos.clmna1;
                exception when others then
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No se encontraron datos de la cartera en mc_g_embargos_cartera.';
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_embrgos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;       
                end;
                
                -- 4. generamos el registro en embargos
                begin 
                    v_cnsctvo_embrgo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'CIE');
                    insert into mc_g_embargos_resolucion (id_embrgos_crtra   ,id_fncnrio  ,id_lte_mdda_ctlar  ,cnsctvo_embrgo  ,fcha_rgstro_embrgo,id_fljo_trea_estdo) 
                                                  values (v_id_embrgos_crtra ,v_id_fncnrio,v_id_lte_mdda_ctlar,v_cnsctvo_embrgo,sysdate,null)
                    returning id_embrgos_rslcion into v_id_embrgos_rslcion;
                
                exception when others then
                    o_cdgo_rspsta  := 8;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. Error al insertar datos en mc_g_embargos_resolucion.';
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_embrgos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;       
                end;
                
                -- 5. insertamos el responsable asociado al embargo
                begin 
                    insert into mc_g_embargos_responsable (id_embrgos_crtra               , cdgo_idntfccion_tpo             , idntfccion                   , prmer_nmbre                      , 
                                                           sgndo_nmbre                    , prmer_aplldo                    , sgndo_aplldo                 , prncpal_s_n                      , 
                                                           cdgo_tpo_rspnsble              , prcntje_prtcpcion               , id_pais_ntfccion             , id_dprtmnto_ntfccion             ,
                                                           id_mncpio_ntfccion             , drccion_ntfccion                , email                        , tlfno                            , cllar              )
                                                  values ( v_id_embrgos_crtra             , c_embrgos.clmna9                , c_embrgos.clmna10            , c_embrgos.clmna11                ,
                                                           c_embrgos.clmna12              , c_embrgos.clmna13               , c_embrgos.clmna14            , nvl(c_embrgos.clmna19,'S')       ,
                                                           'P'                            , 0                               , c_embrgos.clmna20            , c_embrgos.clmna21,
                                                           c_embrgos.clmna22              , c_embrgos.clmna15               , c_embrgos.clmna16            , c_embrgos.clmna17                , c_embrgos.clmna18)
                            returning id_embrgos_rspnsble into v_id_embrgos_rspnsble;
                
                 exception when others then
                    o_cdgo_rspsta  := 9;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. Error al insertar datos en mc_g_embargos_responsable.';
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_embrgos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;       
                end;
                --6. asociamos el responsable al emabargo
                begin
                    insert into mc_g_embrgs_rslcion_rspnsbl (id_embrgos_rslcion,id_embrgos_rspnsble)
                                                             values (v_id_embrgos_rslcion,v_id_embrgos_rspnsble);
                                                         
                exception when others then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. Error al insertar datos en mc_g_embrgs_rslcion_rspnsbl.';
                    v_errors.extend;  
                    v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_embrgos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
                    continue;       
                end;
                
                --7. generamos los actos de investigacion y oficio de emabrgo
                
                v_slct_sjto_impsto  := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto '||
                                       '   from MC_G_EMBARGOS_CARTERA_DETALLE b '||
                                       ' where b.ID_EMBRGOS_CRTRA = ' ||  v_id_embrgos_crtra;
                                       
                v_slct_rspnsble     := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                                       ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                                       ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' || v_id_embrgos_crtra;
                
                v_slct_vgncias      := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres'||
                                       ' from MC_G_EMBARGOS_CARTERA_DETALLE b  '||
                                       ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte '||
                                       ' and c.id_impsto = b.id_impsto '||
                                       ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto '||
                                       ' and c.id_sjto_impsto = b.id_sjto_impsto '||
                                       ' and c.vgncia = b.vgncia '||
                                       ' and c.id_prdo = b.id_prdo '||
                                       ' and c.id_cncpto = b.id_cncpto '||
                                       ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn '||
                                       ' and c.id_orgen = b.id_orgen '||
                                       ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro '||
                                       ' where b.ID_EMBRGOS_CRTRA = '||v_id_embrgos_crtra||
                                       ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; 
                                       
                v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto( p_cdgo_clnte             => p_cdgo_clnte,
                                                                       p_cdgo_acto_orgen        => 'MCT',
                                                                       p_id_orgen               => v_id_embrgos_rslcion,
                                                                       p_id_undad_prdctra       => v_id_embrgos_rslcion,
                                                                       p_id_acto_tpo            => v_id_acto_tpo_rslcion,
                                                                       p_acto_vlor_ttal         => v_vlor_mdda_ctlar,
                                                                       p_cdgo_cnsctvo           => null,
                                                                       p_id_usrio               => p_id_usrio,
                                                                       p_slct_sjto_impsto       => v_slct_sjto_impsto,
                                                                       p_slct_vgncias           => v_slct_vgncias,
                                                                       p_slct_rspnsble          => v_slct_rspnsble); 
                                                                                    
                pkg_mg_migracion.prc_rg_acto_migracion(  p_cdgo_clnte    => p_cdgo_clnte,
                                                                  p_json_acto     => v_json_actos,
                                                                  p_nmro_acto     => c_embrgos.clmna2,
                                                                  p_fcha_acto     => to_timestamp(c_embrgos.clmna3,'dd/mm/yyyy'),
                                                                  o_mnsje_rspsta  => v_mnsje,
                                                                  o_cdgo_rspsta   => v_cdgo_rspsta,
                                                                  o_id_acto       => v_id_acto_rslcion);
                                                                  
                update mc_g_embargos_resolucion c
                   set c.id_acto = v_id_acto_rslcion, 
                       c.nmro_acto = c_embrgos.clmna2, 
                       c.fcha_acto = to_timestamp(c_embrgos.clmna3,'dd/mm/yyyy')
                 where c.id_embrgos_rslcion = v_id_embrgos_rslcion;
                
                --8. generamos los registros de investigacion y oficios de embargo
                
                for c_entidades in (select a.id_entddes
                                      from v_mc_d_entidades a
                                     where a.id_tpos_mdda_ctlar = v_id_tpos_mdda_ctlar
                                       and a.cdgo_clnte = p_cdgo_clnte) loop
                        
                        insert into mc_g_solicitudes_y_oficios (id_embrgos_crtra  ,id_entddes            ,id_embrgos_rspnsble  ,id_acto_slctud,nmro_acto_slctud,fcha_slctud,
                                                                id_acto_ofcio     , nmro_acto_ofcio      , fcha_ofcio          ,id_embrgos_rslcion)
                                                         values(v_id_embrgos_crtra,c_entidades.id_entddes,v_id_embrgos_rspnsble,null          ,null            ,null,
                                                                 null             ,null                  , null                 ,v_id_embrgos_rslcion)
                                                         returning id_slctd_ofcio into v_id_slctd_ofcio;
                                                         
                        
                        -- acto de investigacion --                                 
                        v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto( p_cdgo_clnte             => p_cdgo_clnte,
                                                                               p_cdgo_acto_orgen        => 'MCT',
                                                                               p_id_orgen               => v_id_slctd_ofcio,
                                                                               p_id_undad_prdctra       => v_id_slctd_ofcio,
                                                                               p_id_acto_tpo            => v_id_acto_tpo_ofcio_inv,
                                                                               p_acto_vlor_ttal         => v_vlor_mdda_ctlar,
                                                                               p_cdgo_cnsctvo           => null,
                                                                               p_id_usrio               => p_id_usrio,
                                                                               p_slct_sjto_impsto       => v_slct_sjto_impsto,
                                                                               p_slct_vgncias           => v_slct_vgncias,
                                                                               p_slct_rspnsble          => v_slct_rspnsble); 
                                                                                    
                        pkg_mg_migracion.prc_rg_acto_migracion(  p_cdgo_clnte    => p_cdgo_clnte,
                                                                          p_json_acto     => v_json_actos,
                                                                          p_nmro_acto     => c_embrgos.clmna4,
                                                                          p_fcha_acto     => to_timestamp(c_embrgos.clmna5,'dd/mm/yyyy'),
                                                                          o_mnsje_rspsta  => v_mnsje,
                                                                          o_cdgo_rspsta   => v_cdgo_rspsta,
                                                                          o_id_acto       => v_id_acto_ofcio_inv);
                                                                          
                        -- acto de oficio -- 
                        
                        v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto( p_cdgo_clnte             => p_cdgo_clnte,
                                                                               p_cdgo_acto_orgen        => 'MCT',
                                                                               p_id_orgen               => v_id_slctd_ofcio,
                                                                               p_id_undad_prdctra       => v_id_slctd_ofcio,
                                                                               p_id_acto_tpo            => v_id_acto_tpo_ofcio_emb,
                                                                               p_acto_vlor_ttal         => v_vlor_mdda_ctlar,
                                                                               p_cdgo_cnsctvo           => null,
                                                                               p_id_usrio               => p_id_usrio,
                                                                               p_slct_sjto_impsto       => v_slct_sjto_impsto,
                                                                               p_slct_vgncias           => v_slct_vgncias,
                                                                               p_slct_rspnsble          => v_slct_rspnsble); 
                                                                                    
                        pkg_mg_migracion.prc_rg_acto_migracion(  p_cdgo_clnte    => p_cdgo_clnte,
                                                                          p_json_acto     => v_json_actos,
                                                                          p_nmro_acto     => c_embrgos.clmna4,
                                                                          p_fcha_acto     => to_timestamp(c_embrgos.clmna5,'dd/mm/yyyy'),
                                                                          o_mnsje_rspsta  => v_mnsje,
                                                                          o_cdgo_rspsta   => v_cdgo_rspsta,
                                                                          o_id_acto       => v_id_acto_ofcio_emb);
                                                                          
                        -- actualizamos los datos del id_acto de los oficios de investigacion y embargo
                        
                         update mc_g_solicitudes_y_oficios
                            set id_acto_slctud = v_id_acto_ofcio_inv,
                                nmro_acto_slctud = c_embrgos.clmna4,
                                fcha_slctud = to_timestamp(c_embrgos.clmna5,'dd/mm/yyyy'),
                                id_acto_ofcio = v_id_acto_ofcio_emb, 
                                nmro_acto_ofcio = c_embrgos.clmna4, 
                                fcha_ofcio = to_timestamp(c_embrgos.clmna5,'dd/mm/yyyy')
                          where id_slctd_ofcio = v_id_slctd_ofcio;
                                                                    
                
                end loop;
                
                -- actualizamos la cartera al estado de embargo.
                update mc_g_embargos_cartera a
                set a.id_estdos_crtra = v_id_estdos_crtra
                where a.cdgo_crtra = c_embrgos.clmna1;
                
                -- transitar en el flujo a la etapa de embargo.
                 --- actualziar las transiciones del flujo a la etapa 3
                 
                 update wf_g_instancias_transicion
                 set id_estdo_trnscion = 3
                 where id_instncia_fljo = v_id_instncia_fljo;
                 
                 -- insertar la nueva transicion del flujo en etapa 2
                 
                 insert into wf_g_instancias_transicion (id_instncia_fljo,id_fljo_trea_orgen,fcha_incio,id_usrio,id_estdo_trnscion)
                                                 values (v_id_instncia_fljo,v_id_fljo_trea,systimestamp,p_id_usrio,2);
                                                 
                
            end loop;
    
    end prc_mg_embargos_oficios;
    
    
    procedure prc_rg_acto_migracion (p_cdgo_clnte 	in number, 
                                     p_json_acto	in clob,
                                     p_nmro_acto    in number,
                                     p_fcha_acto    in timestamp,
                                     o_id_acto      out number,
                                     o_cdgo_rspsta 	out number,
                                     o_mnsje_rspsta out varchar2) as  				   

    -- !! --------------------------------------------------------------------------------------------------------- !! -- 
	-- !!                     Procedmiento que registrar un acto dado un json	                                    !! --
    -- !! o_cdgo_rspsta => 0 o_mnsje_rspta => Registro Exitoso                                                      !! --           
    -- !! o_cdgo_rspsta => 1 o_mnsje_rspta => Error. El json es nulo                                                !! --          
    -- !! o_cdgo_rspsta => 2 o_mnsje_rspta => Error. El json no contiene sujetos impuestos                          !! --
    -- !! o_cdgo_rspsta => 3 o_mnsje_rspta => Error. El json no contiene vigencias y/o periodos                     !! --
    -- !! o_cdgo_rspsta => 4 o_mnsje_rspta => Error. El json no contiene responsables                               !! --
    -- !! o_cdgo_rspsta => 5 o_mnsje_rspta => Error. Al Actualizar los Actos Hijos                                  !! --
    -- !! o_cdgo_rspsta => 6 o_mnsje_rspta => Error. Al insertar el o los sujestos impuestos                        !! --
    -- !! o_cdgo_rspsta => 7 o_mnsje_rspta => Error. Al insertar las vigencias y periodos del actos                 !! --
    -- !! o_cdgo_rspsta => 8 o_mnsje_rspta => Error. al insertar el los responsable del sujeto impuesto del acto    !! --
    -- !! o_cdgo_rspsta => 9 o_mnsje_rspta => Error. No se encontro la informacion del acto en el json              !! --
    -- !! o_cdgo_rspsta => 10 o_mnsje_rspta => Error. No se encontro Funcionario parametrizado para firmar          !! --
    -- !! o_cdgo_rspsta => 11 o_mnsje_rspta => Error. Error al consultar el funcionario para firmar el acto         !! --
	-- !! --------------------------------------------------------------------------------------------------------- !! -- 

	v_nl						number;
	v_id_fncnrio_frma			gn_g_actos.id_fncnrio_frma%type;
	v_nmro_acto					gn_g_actos.nmro_acto%type;
	v_anio						gn_g_actos.anio%type;	
	v_nmro_acto_dsplay			gn_g_actos.nmro_acto_dsplay%type;
	v_cdgo_undad_prdctora		varchar2(3);
    v_cntidad_sjtos             number;
    v_cntdad_vngncias           number;
    v_cntdad_rspnsbles          number;

	v_cdgo_acto_orgen 			gn_g_actos.cdgo_acto_orgen%type;
	v_id_orgen		  			gn_g_actos.id_orgen%type;
	v_id_undad_prdctra			gn_g_actos.id_undad_prdctra%type;
	v_id_acto_tpo	  			gn_g_actos.id_acto_tpo%type;
	v_acto_vlor_ttal  			number;
	v_cdgo_cnsctvo	  			df_c_consecutivos.cdgo_cnsctvo%type;
	v_id_acto_rqrdo_hjo			gn_g_actos.id_acto_rqrdo_ntfccion%type;
	v_id_acto_rqrdo_pdre		gn_g_actos.id_acto_rqrdo_ntfccion%type;
	v_fcha_incio_ntfccion		date;
	v_id_usrio					gn_g_actos.id_usrio%type;
    v_fcha_acto                 timestamp;

	begin
		-- 1. Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto');

		pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, 'Entrando ' || systimestamp, 1); 		

		-- 2. Inicializacion de Variables
		o_id_acto		        := null;
		o_mnsje_rspsta		    := '';
        v_fcha_incio_ntfccion   := sysdate;
        v_cntidad_sjtos         := 0;
        v_cntdad_vngncias       := 0;
        v_cntdad_rspnsbles      := 0;


		-- 3. Extraer a?o 
		select extract(year from systimestamp) into v_anio from dual; 

		if p_json_acto is null then 
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := 'El json es nulo';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);

        else        
            -- 4. Se extraen los datos basicos del Acto del json 
            begin 
                select json_value (p_json_acto, '$.CDGO_ACTO_ORGEN') 		cdgo_acto_orgen,
                       json_value (p_json_acto, '$.ID_ORGEN') 				id_orgen,
                       json_value (p_json_acto, '$.ID_UNDAD_PRDCTRA') 		id_undad_prdctra,
                       json_value (p_json_acto, '$.ID_ACTO_TPO') 			id_acto_tpo,
                       json_value (p_json_acto, '$.ACTO_VLOR_TTAL') 		acto_vlor_ttal,
                       json_value (p_json_acto, '$.CDGO_CNSCTVO') 			cdgo_cnsctvo,
                       json_value (p_json_acto, '$.ID_ACTO_RQRDO_HJO')		id_acto_rqrdo_hjo,
                       json_value (p_json_acto, '$.ID_ACTO_RQRDO_PDRE')		id_acto_rqrdo_pdre,
                       json_value (p_json_acto, '$.FCHA_INCIO_NTFCCION')	fcha_incio_ntfccion,
                       json_value (p_json_acto, '$.ID_USRIO') 				id_usrio
                  into v_cdgo_acto_orgen ,
                       v_id_orgen,
                       v_id_undad_prdctra,
                       v_id_acto_tpo,
                       v_acto_vlor_ttal,
                       v_cdgo_cnsctvo,
					   v_id_acto_rqrdo_hjo,
					   v_id_acto_rqrdo_pdre,
					   v_fcha_incio_ntfccion,
                       v_id_usrio		  
                  from dual ;

                -- 4.1 Asignacion de Consecutivo del acto
                --v_nmro_acto := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte => p_cdgo_clnte, p_cdgo_cnsctvo => v_cdgo_cnsctvo);
                v_nmro_acto := p_nmro_acto;
                v_fcha_acto := p_fcha_acto;
                -- 4.2 Construccion del Consecutivo del acto display
                v_nmro_acto_dsplay := v_cdgo_undad_prdctora || '-' || v_anio || '-' || v_nmro_acto;

                -- 4.3 Se buscar el funcionario que firmara el acto
                begin 

                    select id_fncnrio 
                      into v_id_fncnrio_frma 
                      from gn_d_actos_funcionario_frma
                     where id_acto_tpo = v_id_acto_tpo
                       and actvo = 'S'
                       and trunc (sysdate) between fcha_incio and fcha_fin
                       and v_acto_vlor_ttal between rngo_dda_incio and rngo_dda_fin;

                    -- 4.4 Se registra el acto en la tabla de gn_g_actos
                    begin 

                        insert into gn_g_actos ( cdgo_clnte,		    cdgo_acto_orgen,	id_orgen,	    	id_undad_prdctra,
                                                 id_acto_tpo,		    nmro_acto,			anio,		    	nmro_acto_dsplay,
                                                 fcha,				    id_usrio,           id_fncnrio_frma,	id_acto_rqrdo_ntfccion,
												 fcha_incio_ntfccion,   vlor)
                                        values ( p_cdgo_clnte,		    v_cdgo_acto_orgen,	v_id_orgen,	    	v_id_undad_prdctra,
                                                 v_id_acto_tpo,	        v_nmro_acto,		v_anio,		    	v_nmro_acto_dsplay,
                                                 v_fcha_acto,		    v_id_usrio,         v_id_fncnrio_frma,	v_id_acto_rqrdo_pdre,
												 v_fcha_incio_ntfccion, v_acto_vlor_ttal)
                            returning id_acto into o_id_acto;
                            o_cdgo_rspsta := 0;

						if v_id_acto_rqrdo_hjo is not null then 
							for c_actos_hjo in (select id_acto from gn_g_actos where id_acto = v_id_acto_rqrdo_hjo) loop
								begin 
									update gn_g_actos 
									   set id_acto_rqrdo_ntfccion = o_id_acto 
									 where id_acto = c_actos_hjo.id_acto;

									o_cdgo_rspsta := 'Se actulizaron los actos hijos del .' ||  o_id_acto || ' , con consecutivo No.  ' || v_nmro_acto_dsplay;
									pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_cdgo_rspsta , 6);
								exception 
									when others then 
										o_cdgo_rspsta := 5;
                                        o_mnsje_rspsta := 'Error al actualizar los actos hijos del acto N?.' ||  o_id_acto || ' , con consecutivo No.  ' || v_nmro_acto_dsplay;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
								end; 
							end loop;
						end if;

                        -- 4.4.1 Se extraen los subimpuestos y los sujetos impuestos del json
                        for c_sjtos_impsto in (select sjtos_impstos.*
                                                 from dual, json_table(p_json_acto, '$.SJTOS_IMPSTO[*]' 
                                                              columns (id_impsto_sbmpsto 	varchar2(10) path '$.ID_IMPSTO_SBMPSTO',
                                                                       id_sjto_impsto 		varchar2(20) path '$.ID_SJTO_IMPSTO')) as sjtos_impstos 
                                                where sjtos_impstos.id_impsto_sbmpsto is not null 
                                                  and sjtos_impstos.id_sjto_impsto is not null)
                                        loop

                             -- 4.4.1.1 Se insertan cada sujeto impuesto del acto
                            begin
                                insert into gn_g_actos_sujeto_impuesto (id_acto, 	id_impsto_sbmpsto, 					id_sjto_impsto) 
                                                                values (o_id_acto,  c_sjtos_impsto.id_impsto_sbmpsto,	c_sjtos_impsto.id_sjto_impsto); 

                                v_cntidad_sjtos := v_cntidad_sjtos + 1;
                            exception
                                when others then
                                    o_cdgo_rspsta := 6;
                                    o_mnsje_rspsta := 'Error al insertar el o los sujetos impuestos del acto. ERROR:' || SQLCODE  || ' -- ' || ' -- ' || SQLERRM;
                                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);                                    
                            end; -- 4.4.1.1 Fin insert de sujestos impuestos
                        end loop; -- 4.4.1 Fin del for de c_sjtos_impsto

                        if v_cntidad_sjtos = 0 then 
                             o_cdgo_rspsta := 2;
                             o_mnsje_rspsta := 'Error. El json no contiene sujetos impuestos';                           
                        end if;

                        -- 4.4.2 Se extraen las vigencias y periodos de los sujestos impuestos del json
                        for c_vgncias in (select vgncias.*
                                                from dual, json_table (p_json_acto, '$.VGNCIAS[*]'
                                                columns(id_sjto_impsto  varchar2(50) path '$.ID_SJTO_IMPSTO', 
                                                        vgncia          varchar2(50) path '$.VGNCIA',
                                                        id_prdo         varchar2(50) path '$.ID_PRDO',
                                                        vlor_cptal      varchar2(50) path '$.VLOR_CPTAL',
                                                        vlor_intres     varchar2(50) path '$.VLOR_INTRES'))as vgncias 
                                            where vgncias.id_sjto_impsto is not null
                                              and vgncias.vgncia is not null
                                              and vgncias.id_prdo is not null
                                              and vgncias.vlor_cptal is not null
                                              and vgncias.vlor_intres is not null) loop

                             -- 4.4.2.1 Se insertan cada vigencia de los sujetos impuestos del acto
                            begin
                                insert into gn_g_actos_vigencia (id_acto,               id_sjto_impsto, 			vgncia,             id_prdo,
                                                                vlor_cptal,             vlor_intres) 
                                                         values (o_id_acto,             c_vgncias.id_sjto_impsto,	c_vgncias.vgncia,   c_vgncias.id_prdo,
                                                                 c_vgncias.vlor_cptal,  c_vgncias.vlor_cptal); 

                                v_cntdad_vngncias := v_cntdad_vngncias + 1;
                            exception
                                when others then
                                    o_cdgo_rspsta := 7;
                                    o_mnsje_rspsta := 'Error al insertar las vigencias y periodos del acto. ERROR:' || SQLCODE  || ' -- ' || ' -- ' || SQLERRM;
                                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);

                            end; -- 4.4.2.1 Fin insert de sujestos impuestos

                        end loop; -- 4.4.2 fin del for de c_vgncias

                        if v_cntdad_vngncias = 0 then 
                            o_cdgo_rspsta := 3;
                            o_mnsje_rspsta := 'Error. El json no contiene vigencias y periodos del acto';   
                        end if;

                        -- 4.4.3 Se extraen los responsables del acto
                        for c_sjtos_rspnsble in (select rspnsbles.*
                                                   from dual, json_table(p_json_acto, '$.RSPNSBLES[*]'
                                                                     columns (idntfccion 			varchar2(100) path '$.IDNTFCCION',
                                                                              prmer_nmbre  			varchar2(100) path '$.PRMER_NMBRE',
                                                                              sgndo_nmbre  			varchar2(100) path '$.SGNDO_NMBRE',
                                                                              prmer_aplldo  		varchar2(100) path '$.PRMER_APLLDO',
                                                                              sgndo_aplldo  		varchar2(100) path '$.SGNDO_APLLDO',
                                                                              cdgo_idntfccion_tpo	varchar2(100) path '$.CDGO_IDNTFCCION_TPO',
                                                                              drccion_ntfccion	    varchar2(100) path '$.DRCCION_NTFCCION',
                                                                              id_pais_ntfccion  	varchar2(100) path '$.ID_PAIS_NTFCCION',
                                                                              id_dprtmnto_ntfccion	varchar2(100) path '$.ID_DPRTMNTO_NTFCCION',
                                                                              id_mncpio_ntfccion	varchar2(100) path '$.ID_MNCPIO_NTFCCION',
                                                                              email                	varchar2(100) path '$.EMAIL',
                                                                              tlfno	                varchar2(100) path '$.TLFNO'))as rspnsbles
                                                  where rspnsbles.idntfccion is not null) loop                  
                            -- 4.4.3.1 Se insertan los responsable
                            begin 
                                insert into gn_g_actos_responsable (id_acto, 								cdgo_idntfccion_tpo, 					idntfccion,
                                                                    prmer_nmbre, 							sgndo_nmbre, 							prmer_aplldo,
                                                                    sgndo_aplldo,							drccion_ntfccion, 						id_pais_ntfccion,
                                                                    id_dprtmnto_ntfccion,					id_mncpio_ntfccion,						email,
                                                                    tlfno)
                                                            values (o_id_acto, 								c_sjtos_rspnsble.cdgo_idntfccion_tpo,	c_sjtos_rspnsble.idntfccion,
                                                                    c_sjtos_rspnsble.prmer_nmbre, 			c_sjtos_rspnsble.sgndo_nmbre,			c_sjtos_rspnsble.prmer_aplldo,
                                                                    c_sjtos_rspnsble.sgndo_aplldo,			c_sjtos_rspnsble.drccion_ntfccion,		c_sjtos_rspnsble.id_pais_ntfccion,
                                                                    c_sjtos_rspnsble.id_dprtmnto_ntfccion,	c_sjtos_rspnsble.id_mncpio_ntfccion,	c_sjtos_rspnsble.email,
                                                                    c_sjtos_rspnsble.tlfno);
                                v_cntdad_rspnsbles := v_cntdad_rspnsbles + 1;
                            exception 
                                when others then 
                                    o_cdgo_rspsta := 8;
                                    o_mnsje_rspsta := 'Error al insertar el los responsable del sujeto impuesto del acto. ERROR:' || SQLCODE  || ' -- ' || ' -- ' || SQLERRM;
                                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
                                    return;

                            end; -- 4.4.3.1 Fin insert  de actos responsables 

                        end loop; -- 4.4.3 Fin del for de c_sjtos_rspnsble
                        if v_cntdad_rspnsbles = 0 then 
                            o_cdgo_rspsta := 4;
                            o_mnsje_rspsta := 'Error. El json no contiene responsables'; 
                            return;
                        end if;

                    exception 
                        when no_data_found then 
                            o_cdgo_rspsta := 9;
                            o_mnsje_rspsta := 'No se encontro la informacion del acto en el json';
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1); 
                            return;
                    end; -- 4.4 Fin Registro del Acto*/
                exception 
                    when no_data_found then 
                        o_cdgo_rspsta := 10;
                        o_mnsje_rspsta := 'No se encontro funcionario parametrizado para firmar el acto por valor: '||to_char(v_acto_vlor_ttal, 'FM$999G999G999G999G999G999G990');
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1); 
                        return;
                    when others then
                        o_cdgo_rspsta := 11;
                        o_mnsje_rspsta := 'Error al consultar el funcionario para firmar el acto ' || SQLCODE || ' - -' || SQLERRM;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1); 
                        return;
                end; -- 4.3 Fin de la busqueda del funcionario que firma*/

                if o_cdgo_rspsta = 0 then 
                    o_mnsje_rspsta := 'Se creo el acto N?.' ||  o_id_acto || ' , con consecutivo No.  ' || v_nmro_acto_dsplay;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 6); 
                    return;
                end if;

                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, 'Saliendo ' || systimestamp, 1);                 
            end; -- 4. Fin Extraccion de los datos basicos del acto
        end if;	-- Fin Si dvalidacion json no sea nulo
	end prc_rg_acto_migracion; -- Fin del procedimiento
    
   
    
end;-- Fin del Paquete

/
