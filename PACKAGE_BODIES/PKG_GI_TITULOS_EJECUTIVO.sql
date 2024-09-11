--------------------------------------------------------
--  DDL for Package Body PKG_GI_TITULOS_EJECUTIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_TITULOS_EJECUTIVO" as

  procedure prc_rg_sujeto_impuesto(p_id_sjto_impsto          in  si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_cdgo_clnte		         in  si_c_sujetos.cdgo_clnte%type,		
                                   p_id_usrio                in  si_i_sujetos_impuesto.id_usrio%type,
                                   p_idntfccion              in  si_c_sujetos.idntfccion%type,
                                   p_id_dprtmnto             in  si_c_sujetos.id_dprtmnto%type,
                                   p_id_mncpio               in  si_c_sujetos.id_mncpio%type,
                                   p_drccion                 in  si_c_sujetos.drccion%type,
                                   p_id_impsto               in  si_i_sujetos_impuesto.id_impsto%type,
                                   p_email                   in  si_i_sujetos_impuesto.email%type,
                                   p_tlfno                   in  si_i_sujetos_impuesto.tlfno%type,
                                   p_cdgo_idntfccion_tpo	 in  si_i_personas.cdgo_idntfccion_tpo%type,
                                   p_id_rgmen_tpo            in  si_i_personas.id_sjto_tpo%type,
                                   p_tpo_prsna               in  si_i_personas.tpo_prsna%type,
                                   p_nmbre_rzon_scial        in  si_i_personas.nmbre_rzon_scial%type,
                                   p_prmer_nmbre             in  si_i_sujetos_responsable.prmer_nmbre%type,
                                   p_sgndo_nmbre             in  si_i_sujetos_responsable.sgndo_nmbre%type,
                                   p_prmer_aplldo            in  si_i_sujetos_responsable.prmer_aplldo%type,
                                   p_sgndo_aplldo            in  si_i_sujetos_responsable.sgndo_aplldo%type,
                                   p_prncpal_s_n             in  si_i_sujetos_responsable.prncpal_s_n%type default 'S',
                                   p_nmro_rgstro_cmra_cmrcio in  si_i_personas.nmro_rgstro_cmra_cmrcio%type,
                                   p_fcha_rgstro_cmra_cmrcio in  si_i_personas.fcha_rgstro_cmra_cmrcio%type,
                                   p_fcha_incio_actvddes     in  si_i_personas.fcha_incio_actvddes%type,
                                   p_nmro_scrsles            in  si_i_personas.nmro_scrsles%type,
                                   p_drccion_cmra_cmrcio     in  si_i_personas.drccion_cmra_cmrcio%type,
                                   p_json_rspnsble           in  clob,  
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2)
                                        
  as
    v_error             exception;
    v_nl                number;
    v_mnsje_log         varchar2(4000);
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_pais           df_s_departamentos.id_pais%type;
    v_idntfccion        number;
    v_idntfccion_trcro  number;
    v_id_sjto_rspnsble  number;
    v_sjto              number;

  begin
    o_cdgo_rspsta := 0;

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, 'Entrando:' || systimestamp, 1);

    --Se obtiene el identificador del País
    begin
        select d.id_pais
        into v_id_pais
        from df_s_departamentos d
        where d.id_dprtmnto = p_id_dprtmnto;
    exception 
        when no_data_found then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se puedo obtener el identificador del País';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
    end;

    if p_id_sjto_impsto is null then
        --Valida que el sujeto no se encuentre registrado
        begin
            select count(s.idntfccion)
            into v_idntfccion
            from si_c_sujetos s
            where s.idntfccion = p_idntfccion
            and S.cdgo_clnte = p_cdgo_clnte;

            if v_idntfccion > 0 then
                raise_application_error(-20007, 'La identificación ' ||' '|| p_idntfccion ||' '|| 'ya se encuentra registrada');
            end if;

        end;

        --Inserta la información del sujeto
        begin
            insert into si_c_sujetos (cdgo_clnte, idntfccion, idntfccion_antrior, id_pais, id_dprtmnto, id_mncpio, drccion, 
                                      fcha_ingrso, estdo_blqdo)
                              values (p_cdgo_clnte, p_idntfccion, p_idntfccion, v_id_pais, p_id_dprtmnto, p_id_mncpio, 
                                      p_drccion, sysdate, 'N')
            returning id_sjto into v_id_sjto;
        exception
            when others then
                o_cdgo_rspsta := 2;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar el sujeto';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Inserta la información del sujeto impuesto
        begin
            insert into si_i_sujetos_impuesto(id_sjto, id_impsto, estdo_blqdo, id_pais_ntfccion, id_dprtmnto_ntfccion, id_mncpio_ntfccion, 
                                              drccion_ntfccion, email, tlfno, fcha_rgstro, id_usrio, id_sjto_estdo)
                                      values (v_id_sjto, p_id_impsto, 'N', v_id_pais, p_id_dprtmnto, p_id_mncpio, 
                                              p_drccion, p_email, p_tlfno, sysdate, p_id_usrio, 1)
            returning id_sjto_impsto into v_id_sjto_impsto;

        exception
            when others then
                o_cdgo_rspsta := 3;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar el sujeto impuesto';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Insertar la información de la persona o establecimiento
        begin
            insert into si_i_personas(id_sjto_impsto, cdgo_idntfccion_tpo, tpo_prsna, nmbre_rzon_scial, nmro_rgstro_cmra_cmrcio,
                                      fcha_rgstro_cmra_cmrcio, fcha_incio_actvddes, nmro_scrsles, drccion_cmra_cmrcio, id_sjto_tpo)
                              values (v_id_sjto_impsto, p_cdgo_idntfccion_tpo, p_tpo_prsna, nvl2(p_prmer_nmbre, p_prmer_nmbre ||' '|| p_prmer_aplldo, p_nmbre_rzon_scial) , p_nmro_rgstro_cmra_cmrcio,
                                      p_fcha_rgstro_cmra_cmrcio, p_fcha_incio_actvddes, p_nmro_scrsles, p_drccion_cmra_cmrcio, p_id_rgmen_tpo);
        exception
            when others then
                o_cdgo_rspsta := 4;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar la persona';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        begin
            for c_rspnsble in (select   prncpal,										
                                        tpo_idntfccion,
                                        idntfccion,	
                                        prmer_nmbre,			
                                        sgndo_nmbre,	
							            prmer_aplldo,	
							            sgndo_aplldo,     		  
							            dprtmnto,	  
							            mncpio,				  
							            drccion,					  
							            tlfno,						  
							            email,
                                        cdgo_tpo_rspnsble
                               from json_table(p_json_rspnsble, '$[*]'
                               columns
                                (prncpal				varchar2	path	'$.prncpal',				
						         tpo_idntfccion         varchar2	path	'$.tpo_idntfccion',
						         idntfccion             varchar2	path	'$.idntfccion',
						         prmer_nmbre			varchar2	path	'$.prmer_nmbre',
						         sgndo_nmbre		    varchar2	path	'$.sgndo_nmbre',
						         prmer_aplldo	        varchar2	path	'$.prmer_aplldo',
						         sgndo_aplldo     	    varchar2	path	'$.sgndo_aplldo',	
						         dprtmnto       		varchar2	path	'$.dprtmnto',
						         mncpio				    varchar2	path	'$.mncpio',
						         drccion				varchar2	path	'$.drccion',	
						         tlfno					varchar2	path	'$.tlfno',
						         email					varchar2	path	'$.email',
                                 cdgo_tpo_rspnsble      varchar2    path    '$.cdgo_tpo_rspnsble'))) loop



                --Insertar la información del sujeto responsable
                begin
                    insert into si_i_sujetos_responsable(id_sjto_impsto, cdgo_idntfccion_tpo, idntfccion, prmer_nmbre, sgndo_nmbre, 
                                                         prmer_aplldo, sgndo_aplldo, prncpal_s_n, cdgo_tpo_rspnsble, orgen_dcmnto)
                                                  values(v_id_sjto_impsto, c_rspnsble.tpo_idntfccion, c_rspnsble.idntfccion, c_rspnsble.prmer_nmbre, c_rspnsble.sgndo_nmbre, 
                                                         c_rspnsble.prmer_aplldo, c_rspnsble.sgndo_aplldo, c_rspnsble.prncpal, nvl(c_rspnsble.cdgo_tpo_rspnsble, 'P'), '1');
                exception
                    when others then
                        o_cdgo_rspsta := 5;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar la responsable';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
                end;

                --Se consulta si el tercero ya existe
                begin

                    select a.idntfccion
                    into v_idntfccion_trcro
                    from si_c_terceros a
                    where a.idntfccion  =   c_rspnsble.idntfccion
                    and a.cdgo_clnte    =   p_cdgo_clnte;

                exception
                    when no_data_found then
                        --Si no existe se inserta
                        begin
                            insert into si_c_terceros (cdgo_clnte,                  cdgo_idntfccion_tpo,         idntfccion,                 prmer_nmbre,
                                                       sgndo_nmbre,                 prmer_aplldo,                sgndo_aplldo,               drccion,
                                                       id_pais,                     id_dprtmnto,                 id_mncpio,                  drccion_ntfccion,
                                                       email,                       tlfno,                       indcdor_cntrbynte,          indcdr_fncnrio)
                                                values(p_cdgo_clnte,                c_rspnsble.tpo_idntfccion,   c_rspnsble.idntfccion,      c_rspnsble.prmer_nmbre,     
                                                       c_rspnsble.sgndo_nmbre,      c_rspnsble.prmer_aplldo,     c_rspnsble.sgndo_aplldo,    c_rspnsble.drccion,         
                                                       v_id_pais,                   c_rspnsble.dprtmnto,         c_rspnsble.mncpio,          c_rspnsble.drccion,
                                                       c_rspnsble.email,            c_rspnsble.tlfno,            'N',                        'N');
                        exception 
                            when others then
                                o_cdgo_rspsta := 6;
                                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo guardar el tercero';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                return;

                        end;
            end;    
            end loop;
        end;


    else

        --Se obtiene el identificador del sujeto
        begin
            select a.id_sjto 
            into v_sjto
            from si_i_sujetos_impuesto a
            where a.id_sjto_impsto = p_id_sjto_impsto;
        end;

        --Actualiza el sujeto
        begin
            update si_c_sujetos a
            set a.id_pais = v_id_pais,
                a.id_dprtmnto = p_id_dprtmnto,
                a.id_mncpio = p_id_mncpio,
                a.drccion = p_drccion
            where a.id_sjto = v_sjto;
         exception
            when others then
                o_cdgo_rspsta := 7;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el sujeto';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Actualiza sujeto impuesto
        begin
            update si_i_sujetos_impuesto a
            set a.id_impsto = p_id_impsto,
                a.id_pais_ntfccion = v_id_pais,
                a.id_dprtmnto_ntfccion = p_id_dprtmnto,
                a.id_mncpio_ntfccion = p_id_mncpio,
                a.drccion_ntfccion = p_drccion,
                a.email = p_email,
                a.tlfno = p_tlfno
            where a.id_sjto_impsto = p_id_sjto_impsto;   
         exception
            when others then
                o_cdgo_rspsta := 8;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el sujeto impuesto';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Actualiza la persona
        begin
            if p_tpo_prsna = 'N' then
                begin
                    update si_i_personas a
                    set a.cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                        a.nmbre_rzon_scial =  p_prmer_nmbre ||' '|| p_prmer_aplldo
                    where a.id_sjto_impsto = p_id_sjto_impsto;   
                exception
                    when others then
                        o_cdgo_rspsta := 9;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar la persona';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;
                end;
            else
                begin
                    update si_i_personas a
                    set a.cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                        a.nmbre_rzon_scial =  p_nmbre_rzon_scial,
                        a.nmro_rgstro_cmra_cmrcio = p_nmro_rgstro_cmra_cmrcio,		
                        a.fcha_rgstro_cmra_cmrcio = p_fcha_rgstro_cmra_cmrcio,
                        a.fcha_incio_actvddes = p_fcha_incio_actvddes,
                        a.nmro_scrsles = p_nmro_scrsles,
                        a.drccion_cmra_cmrcio = p_drccion_cmra_cmrcio,
                        a.id_sjto_tpo = p_id_rgmen_tpo
                    where a.id_sjto_impsto = p_id_sjto_impsto;   
                exception
                    when others then
                        o_cdgo_rspsta := 10;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar la persona';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;
                end;
            end if;
        end;


        begin
            for c_rspnsble in (select   prncpal,										
                                        tpo_idntfccion,
                                        idntfccion,	
                                        prmer_nmbre,			
                                        sgndo_nmbre,	
							            prmer_aplldo,	
							            sgndo_aplldo,     		  
							            dprtmnto,	  
							            mncpio,				  
							            drccion,					  
							            tlfno,						  
							            email,
                                        cdgo_tpo_rspnsble
                               from json_table(p_json_rspnsble, '$[*]'
                               columns
                                (prncpal				varchar2	path	'$.prncpal',				
						         tpo_idntfccion         varchar2	path	'$.tpo_idntfccion',
						         idntfccion             varchar2	path	'$.idntfccion',
						         prmer_nmbre			varchar2	path	'$.prmer_nmbre',
						         sgndo_nmbre		    varchar2	path	'$.sgndo_nmbre',
						         prmer_aplldo	        varchar2	path	'$.prmer_aplldo',
						         sgndo_aplldo     	    varchar2	path	'$.sgndo_aplldo',	
						         dprtmnto       		varchar2	path	'$.dprtmnto',
						         mncpio				    varchar2	path	'$.mncpio',
						         drccion				varchar2	path	'$.drccion',	
						         tlfno					varchar2	path	'$.tlfno',
						         email					varchar2	path	'$.email',
                                 cdgo_tpo_rspnsble      varchar2    path    '$.cdgo_tpo_rspnsble'))) loop

                --Inserta un sujeto responsable si no esta asociado a el sujeto impuesto
                begin
                    select a.id_sjto_rspnsble
                    into v_id_sjto_rspnsble
                    from si_i_sujetos_responsable a 
                    where a.id_sjto_impsto = p_id_sjto_impsto
                    and a.idntfccion = c_rspnsble.idntfccion;
                exception
                    when no_data_found then

                        --Insertar la información del sujeto responsable
                        begin
                            insert into si_i_sujetos_responsable(id_sjto_impsto, cdgo_idntfccion_tpo, idntfccion, prmer_nmbre, sgndo_nmbre, 
                                                         prmer_aplldo, sgndo_aplldo, prncpal_s_n, cdgo_tpo_rspnsble, orgen_dcmnto)
                                                  values(p_id_sjto_impsto, c_rspnsble.tpo_idntfccion, c_rspnsble.idntfccion, c_rspnsble.prmer_nmbre, c_rspnsble.sgndo_nmbre, 
                                                         c_rspnsble.prmer_aplldo, c_rspnsble.sgndo_aplldo, c_rspnsble.prncpal, nvl(c_rspnsble.cdgo_tpo_rspnsble, 'P'), '1');
                        exception
                            when others then    
                                o_cdgo_rspsta := 5;
                                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar la responsable';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                return;
                        end;
                end;

                --Actualiza la información del sujeto responsable
                begin
                    update si_i_sujetos_responsable a
                        set     a.cdgo_idntfccion_tpo   = c_rspnsble.tpo_idntfccion,
                                a.idntfccion            = c_rspnsble.idntfccion,
                                a.prmer_nmbre           = c_rspnsble.prmer_nmbre,
                                a.sgndo_nmbre           = c_rspnsble.sgndo_nmbre,
                                a.prmer_aplldo          = c_rspnsble.prmer_aplldo,
                                a.sgndo_aplldo          = c_rspnsble.sgndo_aplldo,
                                a.prncpal_s_n           = c_rspnsble.prncpal,
                                a.cdgo_tpo_rspnsble     = nvl(c_rspnsble.cdgo_tpo_rspnsble, 'P')
                        where   a.idntfccion        = c_rspnsble.idntfccion;   
                    exception
                        when others then
                            o_cdgo_rspsta := 11;
                            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar la sujeto responsable';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            return;
                end;

                --Actualiza la información del tercero
                begin
                    update si_c_terceros t
                    set     t.cdgo_idntfccion_tpo   = c_rspnsble.tpo_idntfccion,
                            t.idntfccion            = c_rspnsble.idntfccion,
                            t.prmer_nmbre           = c_rspnsble.prmer_nmbre,
                            t.sgndo_nmbre           = c_rspnsble.sgndo_nmbre,
                            t.prmer_aplldo          = c_rspnsble.prmer_aplldo,
                            t.sgndo_aplldo          = c_rspnsble.sgndo_aplldo,
                            t.drccion               = c_rspnsble.drccion,
                            t.id_pais               = v_id_pais,
                            t.id_dprtmnto           =  c_rspnsble.dprtmnto,                 
                            t.id_mncpio             = c_rspnsble.mncpio,                  
                            t.drccion_ntfccion      = c_rspnsble.drccion,
                            t.email                 = c_rspnsble.email,
                            t.tlfno                 = c_rspnsble.tlfno
                    where   t.idntfccion            = c_rspnsble.idntfccion
                    and     t.cdgo_clnte            = p_cdgo_clnte;

                exception 
                when others then
                    o_cdgo_rspsta := 12;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo actualizar el tercero';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_sujeto_impuesto',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;
            end loop;
        end;
    end if;
  end prc_rg_sujeto_impuesto;

  procedure prc_rg_titulos_ejecutivo(p_cdgo_clnte			   in  si_c_sujetos.cdgo_clnte%type,		  
                                     p_id_usrio                in  si_i_sujetos_impuesto.id_usrio%type,
                                     p_nmro_ttlo_ejctvo        in  gi_g_titulos_ejecutivo.nmro_ttlo_ejctvo%type,
                                     p_id_area                 in  df_c_areas.id_area%type,    
                                     p_id_impsto_acto          in  df_i_impuestos_acto.id_impsto_acto%type,
                                     p_id_impsto               in  gi_g_titulos_ejecutivo.id_impsto%type,
                                     p_id_impsto_sbmpsto       in  gi_g_titulos_ejecutivo.id_impsto_sbmpsto%type,
                                     p_id_sjto_impsto          in  si_i_sujetos_impuesto.id_sjto_impsto%type,
                                     p_nmro_ntfccion           in  gi_g_titulos_ejecutivo.nmro_guia%type,
                                     p_mdio_ntfccion           in  gi_g_titulos_ejecutivo.mdio_ntfccion%type,
                                     p_obsrvcion               in  gi_g_titulos_ejecutivo.obsrvcion%type,
                                     p_fcha_cnsttcion          in  gi_g_titulos_ejecutivo.fcha_cnsttcion%type,
                                     p_fcha_ntfccion           in  gi_g_titulos_ejecutivo.fcha_ntfccion%type,
                                     p_fcha_vncmnto            in  gi_g_titulos_ejecutivo.fcha_vncmnto%type,
                                     p_file_blob               in  blob,
                                     p_file_name               in  varchar2,
                                     p_file_mimetype           in  varchar2,
                                     p_id_dcmnto               in  number,
                                     p_json_mtdta              in  clob,
                                     o_id_ttlo_ejctvo     	   in  out gi_g_titulos_ejecutivo.id_ttlo_ejctvo%type,
                                     o_cdgo_rspsta             out number,
                                     o_mnsje_rspsta            out varchar2) 
  as
    v_nl                        number;
    v_mnsje_log                 varchar2(4000);
    v_id_ttlo_ejctvo            number;
    v_id_fljo                   number;
    v_id_prcso                  number;
    v_instncia_fljo             number;
    v_fljo_trea                 number; 
    v_nmro_ttlo_ejctvo          gi_g_titulos_ejecutivo.nmro_ttlo_ejctvo%type;
    v_id_trd_srie_dcmnto_tpo    number;
    v_id_dcmnto                 number;
    v_ttlo                      number;
    v_nmro_guia                 number;

  begin
    o_cdgo_rspsta := 0;

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, 'Entrando:' || systimestamp, 1);

    --Se obtiene el flujo de Títulos Ejecutivo que se va instanciar para cada Título
    begin
        select a.id_fljo,
               a.id_prcso
        into   v_id_fljo,
               v_id_prcso
        from wf_d_flujos a
        where a.cdgo_fljo   = 'TEJ'
        and   a.cdgo_clnte  = p_cdgo_clnte;  
    exception
        when no_data_found then
            o_cdgo_rspsta := 2;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se encontro flujo de Títulos Ejecutivo con codigo TEJ para este cliente';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
        when others then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al consultar el flujo de Títulos Ejecutivo';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
    end;

    if o_id_ttlo_ejctvo is null then

        v_ttlo  :=  fnc_vl_titulo_ejecutivo(p_nmro_ttlo_ejctvo =>  p_nmro_ttlo_ejctvo,
                                            p_id_ttlo_ejctvo   =>  o_id_ttlo_ejctvo,
                                            p_cdgo_clnte       =>  p_cdgo_clnte);

        v_nmro_guia :=  fnc_vl_numero_guia(p_nmro_ntfccion     =>  p_nmro_ntfccion,
                                           p_id_ttlo_ejctvo    =>  o_id_ttlo_ejctvo,
                                           p_cdgo_clnte        =>  p_cdgo_clnte);

        if (v_ttlo > 0) then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := 'El Título Ejecutivo' ||' '|| p_nmro_ttlo_ejctvo ||' '|| 'ya se encuentra registrado';
            return;
            --raise_application_error(-20001, 'El Título Ejecutivo' ||' '|| p_nmro_ttlo_ejctvo ||' '|| 'ya se encuentra registrado');
        end if;

        if v_nmro_guia > 0 then
            raise_application_error(-20001, 'El Número de Guia' ||' '|| p_nmro_ntfccion ||' '|| 'ya se encuentra registrado');
        end if;

        if p_file_blob is null then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Adjunte el documento del Título Ejecutivo';
            return;
        end if;

        --Se obtiene el identificador de la trd_srie_dcmnto_tpo
        begin
            select a.id_trd_srie_dcmnto_tpo
            into v_id_trd_srie_dcmnto_tpo
            from gd_d_trd_serie_dcmnto_tpo a
            where a.id_dcmnto_tpo in (select b.id_dcmnto_tpo from gd_d_documentos_tipo b where b.cdgo_dcmnto_tpo = 'TEJ' and b.cdgo_clnte = p_cdgo_clnte);
        end;

        --Se manda a Instanciar el flujo de Títulos Judiciales                                        
        begin
            pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo, 
                                                        p_id_usrio         => p_id_usrio,
                                                        p_id_prtcpte       => null,
                                                        p_obsrvcion        => 'Instancia de flujo Títulos Ejecutivo',
                                                        o_id_instncia_fljo => v_instncia_fljo,
                                                        o_id_fljo_trea     => v_fljo_trea,
                                                        o_mnsje            => o_mnsje_rspsta);

            if v_instncia_fljo is null then
                o_cdgo_rspsta := 4;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo instanciar el flujo para el Título Ejecutivo ' || p_nmro_ttlo_ejctvo;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
            end if;
        exception
            when others then
                o_cdgo_rspsta := 5;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al llamar el procedimiento  pkg_pl_workflow_1_0.prc_rg_instancias_flujo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Se manda a guardar el documento adjunto en gestion documental
        begin
            pkg_gd_gestion_documental.prc_cd_documentos(p_id_dcmnto                => p_id_dcmnto,  
                                                        p_id_trd_srie_dcmnto_tpo   => v_id_trd_srie_dcmnto_tpo,	
                                                        p_id_dcmnto_tpo            => '',
                                                        p_file_blob                => p_file_blob,		
                                                        p_file_name                => p_file_name,	
                                                        p_file_mimetype            => p_file_mimetype,	
                                                        p_id_usrio                 => p_id_usrio,	
                                                        p_cdgo_clnte               => p_cdgo_clnte,	
                                                        p_json                     => '',		
                                                        p_accion                   => 'CREATE',	 
                                                        o_cdgo_rspsta              => o_cdgo_rspsta,
                                                        o_mnsje_rspsta             => o_mnsje_rspsta,
                                                        o_id_dcmnto                => v_id_dcmnto);
            if(o_cdgo_rspsta <> 0) then
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta, 6);
                return;
            end if;

        end;


        --Guarda el Título Ejecutivo
       begin
            insert into gi_g_titulos_ejecutivo(cdgo_clnte, nmro_ttlo_ejctvo, id_area, id_impsto_acto, id_impsto, id_impsto_sbmpsto, 
                                               id_sjto_impsto, nmro_guia, mdio_ntfccion, obsrvcion, id_dcmnto, id_usrio_rgstro, 
                                               id_instncia_fljo, cdgo_ttlo_ejctvo_estdo, fcha_cnsttcion, fcha_ntfccion, fcha_vncmnto)
                                        values(p_cdgo_clnte, p_nmro_ttlo_ejctvo, p_id_area, p_id_impsto_acto, p_id_impsto, p_id_impsto_sbmpsto,
                                               p_id_sjto_impsto, p_nmro_ntfccion, p_mdio_ntfccion, p_obsrvcion, v_id_dcmnto, p_id_usrio, 
                                               v_instncia_fljo, 'RGS', p_fcha_cnsttcion, p_fcha_ntfccion, p_fcha_vncmnto)
                                        returning id_ttlo_ejctvo into v_id_ttlo_ejctvo;

            o_id_ttlo_ejctvo := v_id_ttlo_ejctvo;
        exception
            when others then
                o_cdgo_rspsta := 6;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar el Titulo Ejecutivo '||' , '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;
    else

        v_ttlo  :=  fnc_vl_titulo_ejecutivo(p_nmro_ttlo_ejctvo =>  p_nmro_ttlo_ejctvo,
                                            p_id_ttlo_ejctvo   =>  o_id_ttlo_ejctvo,
                                            p_cdgo_clnte       =>  p_cdgo_clnte);

        v_nmro_guia :=  fnc_vl_numero_guia(p_nmro_ntfccion     =>  p_nmro_ntfccion,
                                           p_id_ttlo_ejctvo    =>  o_id_ttlo_ejctvo,
                                           p_cdgo_clnte        =>  p_cdgo_clnte);                                    

        if v_ttlo > 0 then
            raise_application_error(-20001, 'El Título Ejecutivo' ||' '|| p_nmro_ttlo_ejctvo ||' '|| 'ya se encuentra registrado');
        end if;

        if v_nmro_guia > 0 then
            raise_application_error(-20001, 'El Número de Guia' ||' '|| p_nmro_ntfccion ||' '|| 'ya se encuentra registrado');
        end if;

        begin
            update gi_g_titulos_ejecutivo a
            set a.nmro_ttlo_ejctvo = p_nmro_ttlo_ejctvo,
                a.id_area          = p_id_area,
                a.id_impsto_acto   = p_id_impsto_acto,
                a.nmro_guia        = p_nmro_ntfccion,
                a.mdio_ntfccion    = p_mdio_ntfccion,
                a.obsrvcion        = p_obsrvcion,
                a.fcha_cnsttcion   = p_fcha_cnsttcion,
                a.fcha_ntfccion    = p_fcha_ntfccion,
                a.fcha_vncmnto     = p_fcha_vncmnto,
                a.id_usrio_rgstro  = p_id_usrio
            where a.id_ttlo_ejctvo = o_id_ttlo_ejctvo;
        exception
            when others then
                o_cdgo_rspsta := 7;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el Título Ejecutivo ' ||' '|| p_nmro_ttlo_ejctvo;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;

        end;

        if p_file_blob is not null then
            begin
                pkg_gd_gestion_documental.prc_cd_documentos(p_id_dcmnto                => p_id_dcmnto,  
                                                            p_id_trd_srie_dcmnto_tpo   => v_id_trd_srie_dcmnto_tpo,	
                                                            p_id_dcmnto_tpo            => '',
                                                            p_file_blob                => p_file_blob,		
                                                            p_file_name                => p_file_name,	
                                                            p_file_mimetype            => p_file_mimetype,	
                                                            p_id_usrio                 => p_id_usrio,	
                                                            p_cdgo_clnte               => p_cdgo_clnte,	
                                                            p_json                     => '',		
                                                            p_accion                   => 'SAVE',	 
                                                            o_cdgo_rspsta              => o_cdgo_rspsta,
                                                            o_mnsje_rspsta             => o_mnsje_rspsta,
                                                            o_id_dcmnto                => v_id_dcmnto);
                if(o_cdgo_rspsta <> 0) then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta, 6);
                    return;
                end if;
            end;
        end if;
    end if;

    begin
        for c_mtdta in (select case when b.id_impstos_sbmpsto_mtdta is null 
                                then 'I'
                               else 'U'
                               end action,
                               nvl(b.id_infrmcion_mtdta, a.id) as id_infrmcion_mtdta,
                               a.id,
                               a.valor
                        from (select replace(clave, 'INP') id,
                                     valor
                              from json_table(p_json_mtdta , '$[*]' columns(clave varchar2 path '$.key', valor varchar2 path '$.value'))) a
                        full join (select i.id_impstos_sbmpsto_mtdta,
                                          i.id_infrmcion_mtdta
                                   from gi_g_informacion_metadata i
                                   where i.id_orgen = o_id_ttlo_ejctvo) b
                                   on a.id = b.id_impstos_sbmpsto_mtdta) loop

            case c_mtdta.action 
                when 'I' then
                    begin
                        insert into gi_g_informacion_metadata(id_orgen, id_prcso_orgen, id_impstos_sbmpsto_mtdta, vlor) 
                                                      values (o_id_ttlo_ejctvo, v_id_prcso, c_mtdta.id, c_mtdta.valor);
                    exception 
                        when others then
                            o_cdgo_rspsta := 7;
                            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al guardar información adicional del Titulo Ejecutivo';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            return;
                    end;
                when 'U' then
                    begin
                        update gi_g_informacion_metadata a
                        set a.vlor = 'A'--c_mtdta.valor
                        where a.id_infrmcion_mtdta = c_mtdta.id_infrmcion_mtdta;
                    exception 
                        when others then
                            o_cdgo_rspsta := 8;
                            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar la información adicional del Titulo Ejecutivo';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_titulos_ejecutivo',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            return;
                    end;
            end case;

        end loop;
    end;

  end prc_rg_titulos_ejecutivo;

  procedure prc_rg_liquidacion(p_cdgo_clnte		in 	number,
                               p_id_usrio       in 	number,
                               p_id_ttlo_ejctvo	in	gi_g_titulos_ejecutivo.id_ttlo_ejctvo%type,
                               p_aprbcion       in  varchar2,
                               o_cdgo_rspsta	out number,
                               o_mnsje_rspsta	out varchar2) as

    v_nl                    number;
    v_mnsje_log             varchar2(4000);         
    v_bse_grvble            number := 0;


    v_id_impsto             gi_g_titulos_ejecutivo.id_impsto%type;
    v_id_impsto_sbmpsto     gi_g_titulos_ejecutivo.id_impsto_sbmpsto%type;
    v_id_sjto_impsto        gi_g_titulos_ejecutivo.id_sjto_impsto%type;
    v_nmro_ttlo_ejctvo      gi_g_titulos_ejecutivo.nmro_ttlo_ejctvo%type;
    v_fcha_cnsttcion        gi_g_titulos_ejecutivo.fcha_cnsttcion%type;
    v_fcha_vncmnto          gi_g_titulos_ejecutivo.fcha_vncmnto%type;
    v_id_usrio_aprbo        gi_g_titulos_ejecutivo.id_usrio_aprbo%type;
    v_id_dcmnto_tpo_sprte   df_i_documentos_soporte_tipo.id_dcmnto_tpo_sprte%type;
    v_id_lqdcion            gi_g_liquidaciones.id_lqdcion%type;
    v_vgncia_actual         number;
    v_prdo_actual           number;
    v_id_lqdcion_tpo        number;
    v_count_lqdccion_dtlle  number  := 0;
    v_prdo                  df_i_periodos.prdo%type;
    v_ttl_id_lqdcion        gi_g_liquidaciones.id_lqdcion%type;
    v_id_cncpto_intres_csdo number;
    v_dscrpcion             varchar2(200);
    v_vlor_trfa             gi_d_tarifas_esquema.vlor_trfa%type;
    v_txto_trfa             gi_d_tarifas_esquema.txto_trfa%type;


    begin
        o_cdgo_rspsta := 0;

        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion');    
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, 'Entrando:' || systimestamp, 1);

        --Se obtiene la vigencia actual
        begin
            select pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte => p_cdgo_clnte, p_cdgo_dfncion_clnte_ctgria => 'GFN', p_cdgo_dfncion_clnte => 'VAC') 
            into v_vgncia_actual
            from dual;
        exception
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo obtener la vigencia actual';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
        end;

        --Si el Título ejecutivo requiere aprobación se actualiza el campo del usuario que lo aprueba
        if p_aprbcion = 'S' then
            begin
                update gi_g_titulos_ejecutivo t
                   set t.id_usrio_aplco = p_id_usrio
                 where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;
            exception 
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el usuario que aprobo el Título Ejecutivo';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    rollback;
                    return;
            end;
        else
        --Si el Título ejecutivo no requiere aprobación los campos id_usrio_aplco y id_usrio_aprbo se actualiza con el mismo usuario
            begin
                update gi_g_titulos_ejecutivo t
                  set t.id_usrio_aplco = p_id_usrio,
                      t.id_usrio_aprbo = p_id_usrio
                where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;
            exception 
                when others then
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el usuario que aprobo y aplico el Título Ejecutivo';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    rollback;
                    return;
            end;
        end if;
        --Actualiza el estado del Título Ejecutivo
        begin
            update gi_g_titulos_ejecutivo t
               set t.cdgo_ttlo_ejctvo_estdo = 'APB'
             where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;
        exception 
            when others then
                o_cdgo_rspsta := 4;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al actualizar el estado del Título Ejecutivo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se obtiene información del Título Ejecutivo
        begin
            select  t.id_impsto,
                    t.id_impsto_sbmpsto,
                    t.id_sjto_impsto,
                    t.nmro_ttlo_ejctvo,
                    t.fcha_cnsttcion,
                    t.fcha_vncmnto,
                    t.id_lqdcion
            into    v_id_impsto,
                    v_id_impsto_sbmpsto,
                    v_id_sjto_impsto,
                    v_nmro_ttlo_ejctvo,
                    v_fcha_cnsttcion,
                    v_fcha_vncmnto,
                    v_ttl_id_lqdcion
               from gi_g_titulos_ejecutivo t
              where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;
        exception
            when others then
                o_cdgo_rspsta := 5;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al obtener los datos del vehiculo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        if v_ttl_id_lqdcion is not null then
            o_cdgo_rspsta := 6;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'El Título Ejecutivo ' ||' '|| v_nmro_ttlo_ejctvo || 'ya se encuentra liquidado';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            rollback;
            return;
        end if;

         --Se obtiene el periodo actual
        begin
            select a.id_prdo,
                   a.prdo
            into v_prdo_actual,
                 v_prdo
            from df_i_periodos a
            where a.cdgo_clnte = p_cdgo_clnte
            and a.id_impsto = v_id_impsto
            and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
            and a.vgncia = v_vgncia_actual
            and a.prdo = pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte => p_cdgo_clnte, p_cdgo_dfncion_clnte_ctgria => 'GFN', p_cdgo_dfncion_clnte => 'PAC');

        exception
            when others then
                o_cdgo_rspsta := 7;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo obtener el periodo actual';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se obtiene el identificador del documento soporte
        begin
            select d.id_dcmnto_tpo_sprte
              into v_id_dcmnto_tpo_sprte
             from df_i_documentos_soporte_tipo d
             where d.id_impsto = v_id_impsto;
        exception
            when others then
                o_cdgo_rspsta := 8;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al obtener el tipo soporte documento';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se obtiene la base
        begin
            select sum(t.vlor_cptal)
              into v_bse_grvble
              from gi_g_titulos_ejctvo_cncpto t 
             where t.id_ttlo_ejctvo = p_id_ttlo_ejctvo;
        exception 
            when others then
                o_cdgo_rspsta := 9;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al calcular la base';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se obtiene el tipo de liquidación
        begin
            select a.id_lqdcion_tpo
            into v_id_lqdcion_tpo
            from df_i_liquidaciones_tipo a
            where a.cdgo_clnte = p_cdgo_clnte
            and a.cdgo_lqdcion_tpo = 'OTI';
        exception 
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al calcular la base';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se registra la liquidación
        begin
            insert into gi_g_liquidaciones (cdgo_clnte,         id_impsto,              id_impsto_sbmpsto,      vgncia,                 
                                            id_prdo,            id_sjto_impsto,         fcha_lqdcion,           cdgo_lqdcion_estdo, 
                                            bse_grvble,         vlor_ttal,              nmro_dcmnto_sprte,      id_dcmnto_tpo_sprte, 
                                            fcha_dcmnto_sprte,  id_lqdcion_tpo,         id_ttlo_ejctvo,         cdgo_prdcdad,  
                                            id_usrio)
                                     values(p_cdgo_clnte,       v_id_impsto,            v_id_impsto_sbmpsto,    v_vgncia_actual,                   
                                            v_prdo_actual,      v_id_sjto_impsto,       sysdate,                'L',                
                                            v_bse_grvble,       v_bse_grvble,           v_nmro_ttlo_ejctvo,     v_id_dcmnto_tpo_sprte,
                                            v_fcha_cnsttcion,   v_id_lqdcion_tpo,       p_id_ttlo_ejctvo,       'ANU',          
                                            p_id_usrio) 
                                    returning id_lqdcion into v_id_lqdcion;
        exception 
            when others then
                o_cdgo_rspsta := 11;
                o_mnsje_rspsta := o_cdgo_rspsta ||' - '||'No se pudo generar la liquidación';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, 'v_bse_grvble'||' , '||v_bse_grvble, 6);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, 'v_nmro_ttlo_ejctvo'||' , '||v_nmro_ttlo_ejctvo, 6);
                rollback;
                return;
        end;
        --Se registran los conceptos
        begin
            for c_lqcncpto in  (select  a.id_impsto_acto_cncpto,
                                        a.vlor_cptal,
                                        a.vlor_intres,
                                        b.fcha_vncmnto,
                                        b.id_impsto_acto_cncpto_rlcnal
                                from gi_g_titulos_ejctvo_cncpto     a
                                join df_i_impuestos_acto_concepto   b on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
                                where a.id_ttlo_ejctvo = p_id_ttlo_ejctvo) loop

                --Se obtiene el valor tarifa y texto tarifa del impuesto acto concepto
                begin
                    select e.vlor_trfa,
                           e.txto_trfa
                    into   v_vlor_trfa,
                           v_txto_trfa
                    from v_gi_d_tarifas_esquema e
                    where e.id_impsto_acto_cncpto = c_lqcncpto.id_impsto_acto_cncpto;
                exception
                    when no_data_found then
                        o_cdgo_rspsta := 12;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' - '|| 'El impuesto acto concepto id#[' || c_lqcncpto.id_impsto_acto_cncpto || '], no tiene parametrizado valor tarifa y texto tarifa.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;
                    when too_many_rows then
                        o_cdgo_rspsta := 13;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' - '|| 'El impuesto acto concepto id#[' || c_lqcncpto.id_impsto_acto_cncpto || '], tiene mas de un valor tarifa y texto tarifa parametrizado.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;

                end;

                insert into gi_g_liquidaciones_concepto (id_lqdcion,            id_impsto_acto_cncpto,              vlor_lqddo,             vlor_clcldo, 
                                                         trfa,                  bse_cncpto,                         txto_trfa,              vlor_intres,            
                                                         indcdor_lmta_impsto,   fcha_vncmnto)
                                                  values(v_id_lqdcion,          c_lqcncpto.id_impsto_acto_cncpto,   c_lqcncpto.vlor_cptal,  c_lqcncpto.vlor_cptal, 
                                                         v_vlor_trfa,           c_lqcncpto.vlor_cptal,              v_txto_trfa,   c_lqcncpto.vlor_intres, 
                                                         'N',                   v_fcha_vncmnto);

                if c_lqcncpto.vlor_intres > 0 then

                        begin
                            select id_cncpto 
                              into v_id_cncpto_intres_csdo
                              from df_i_impuestos_acto_concepto 
                             where id_impsto_acto_cncpto = c_lqcncpto.id_impsto_acto_cncpto_rlcnal;
                        exception
                             when no_data_found then
                                  o_cdgo_rspsta := 14;
                                  o_mnsje_rspsta := o_cdgo_rspsta ||' - '|| 'El impuesto acto concepto id#[' || c_lqcncpto.id_impsto_acto_cncpto || '], no tiene asociado un impuesto acto relacional.';
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                  return;
                        end;

                        insert into gi_g_liquidaciones_concepto (id_lqdcion,            id_impsto_acto_cncpto,                      vlor_lqddo,             vlor_clcldo, 
                                                                 trfa,                  bse_cncpto,                                 txto_trfa,              vlor_intres,            
                                                                 indcdor_lmta_impsto)
                                                          values(v_id_lqdcion,          c_lqcncpto.id_impsto_acto_cncpto_rlcnal,    c_lqcncpto.vlor_intres, c_lqcncpto.vlor_intres, 
                                                                 v_vlor_trfa,           c_lqcncpto.vlor_intres,                     v_txto_trfa,            0, 
                                                                 'N');
                end if;

                v_count_lqdccion_dtlle := v_count_lqdccion_dtlle + 1;
            end loop;
        exception 
            when others then
                o_cdgo_rspsta := 15;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo liquidar los conceptos del Título Ejecutivo ' || v_nmro_ttlo_ejctvo;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

        --Se actualiza el campo de la liquidación en la tabla de Título Ejecutivo
        begin
            update gi_g_titulos_ejecutivo a
            set a.id_lqdcion =  v_id_lqdcion
            where a.id_lqdcion = p_id_ttlo_ejctvo;
        exception 
            when others then
                o_cdgo_rspsta := 16;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo actualizar el campo de liquidación en Título Ejecutivo';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                rollback;
                return;
        end;

            if v_count_lqdccion_dtlle > 0 then 
                begin

                    pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto (p_cdgo_clnte          =>  p_cdgo_clnte ,
                                                                                  p_id_lqdcion          =>  v_id_lqdcion,
                                                                                  p_cdgo_orgen_mvmnto	=>  'TE',
                                                                                  p_id_orgen_mvmnto     =>  p_id_ttlo_ejctvo,
                                                                                  o_cdgo_rspsta         =>  o_cdgo_rspsta,
                                                                                  o_mnsje_rspsta        =>  o_mnsje_rspsta);                                                            
                    if o_cdgo_rspsta> 0 then
                        o_cdgo_rspsta := 17;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        rollback;
                        return;
                    end if;
                exception
                    when others then
                        o_cdgo_rspsta := 18;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al llamar el procedimiento que registra los movimiento financieros, '||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        rollback;
                        return;
                end;

                begin
                    pkg_gi_determinacion.prc_gn_determinacion (p_cdgo_clnte            => p_cdgo_clnte,
                                                               p_id_impsto             => v_id_impsto,
                                                               p_id_impsto_sbmpsto     => v_id_impsto_sbmpsto,
                                                               p_id_sjto_impsto        => v_id_sjto_impsto,
                                                               p_cdna_vgncia_prdo      => v_vgncia_actual || ','|| v_prdo,
                                                               p_tpo_orgen             => 'TE',
                                                               p_id_orgen              => p_id_ttlo_ejctvo,
                                                               p_id_usrio              => p_id_usrio,
                                                               o_cdgo_rspsta           => o_cdgo_rspsta,
                                                               o_mnsje_rspsta          => o_mnsje_rspsta) ;
                    if o_cdgo_rspsta> 0 then
                        o_cdgo_rspsta := 19;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        rollback;
                        return;
                    end if;
                exception
                    when others then
                        o_cdgo_rspsta := 20;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Error al llamar el procedimiento que registra la determinación, '||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        rollback;
                        return;
                end;
        else
            o_cdgo_rspsta := 21;
            o_mnsje_rspsta := o_cdgo_rspsta ||' - '||'No se insertó el detalle de la liquicación';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
        end if;

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_liquidacion',  v_nl, 'Saliendo con Éxito prc_rg_liquidacion:' || systimestamp, 1);

  end prc_rg_liquidacion;

  procedure prc_rg_anulacion(p_cdgo_clnte       in  number,
                             p_id_usrio         in  number,
                             p_id_instncia_fljo in  number,
                             p_id_fljo_trea     in  number,
                             p_ttlo_ejctvo      in  number,
                             p_obsrvcion        in  varchar2,
                             o_cdgo_rspsta      out number,
                             o_mnsje_rspsta	    out varchar2) as

    v_nl                    number;
    v_mnsje_log             varchar2(4000);         
    v_bse_grvble            number := 0;
    v_o_error		        varchar2(500);

  begin

    o_cdgo_rspsta := 0;

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion',  v_nl, 'Entrando:' || systimestamp, 1);


    begin
        update gi_g_titulos_ejecutivo t
        set t.cdgo_ttlo_ejctvo_estdo = 'RCH'
        where t.id_ttlo_ejctvo = p_ttlo_ejctvo;
    exception
        when others then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo anular el Título Ejecutivo, '||sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
    end;

    begin
        insert into gi_g_titulos_ejctvo_anldo (id_ttlo_ejctvo, obsrvcion,  id_usrio)
                                        values(p_ttlo_ejctvo,  p_obsrvcion,  p_id_usrio);
    exception
        when others then
            o_cdgo_rspsta := 2;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo registrar la anulación del Título Ejecutivo, '||sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
    end;

    begin
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                       p_id_fljo_trea     => p_id_fljo_trea,
                                                       p_id_usrio         => p_id_usrio,
                                                       o_error            => v_o_error,
                                                       o_msg              => o_mnsje_rspsta );

        if v_o_error = 'N' then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion',  v_nl, o_cdgo_rspsta||'-'||o_mnsje_rspsta, 6);
            return;
        end if;



    exception 
        when others then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo llamar al procedimiento pkg_pl_workflow_1_0.prc_rg_finalizar_instancia , '||sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_titulos_ejecutivo.prc_rg_anulacion',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            return;
    end;





  end prc_rg_anulacion;

  function fnc_gn_region_metadatos(p_cdgo_clnte          in number,
                                   p_id_impsto           in number,
                                   p_id_impsto_sbmpsto   in number,
                                   p_id_orgen            in number,
                                   p_dsbled              in varchar2 default 'N')
    return clob 
    as
        v_html  clob;


  begin

    for c_metadata in (select a.id_impsto_sbmpsto_mtdta,
                              a.nmbre,
                              a.tpo_dto,
                              a.dscrpcion_tpo_dto,
                              a.tpo_objto,
                              a.dscrpcion_tpo_objto,
                              a.tpo_orgen,
                              a.dscrpcion_tpo_orgen,
                              case when a.tpo_objto = 'S' and a.tpo_orgen = 'E' 
                                then to_clob('select vlor_dsplay, vlor_rturn from df_i_impsts_sbmpst_mtdt_vlr where id_impsto_sbmpsto_mtdta = ' || a.id_impsto_sbmpsto_mtdta )
                              else a.orgen
                              end orgen,
                              decode(a.indcdor_rqrdo, 'S', 'is-required', '') indcdor_rqrdo,
                              decode(a.indcdor_rqrdo, 'S', 'required','') rqrdo,
                              decode(p_dsbled, 'S', ' disabled="disabled"') disabled,
                              a.dscrpcion_indcdor_rqrdo,
                              a.actvo,
                              a.dscrpcion_actvo,
                              c.vlor,
                              row_number() over(order by a.orden ) rw,
                              count(1) over(partition by null) cnt
                        from v_df_i_impstos_sbmpsto_mtdta       a
                        left join gi_g_informacion_metadata     c   on  a.id_impsto_sbmpsto_mtdta = c.id_impstos_sbmpsto_mtdta
                                                                    and c.id_orgen          = p_id_orgen
                        where   a.cdgo_clnte        = p_cdgo_clnte
                        and     a.id_impsto         = p_id_impsto
                        and     a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                        and     a.actvo = 'S'
                        order by a.orden) loop

            if (mod(c_metadata.rw, 2) = 1 )then
                v_html := v_html ||  '<div class="row">';
            end if;
            v_html := v_html ||  '<div class="col col-6 apex-col-auto">';
            v_html := v_html ||  '<div class="t-Form-fieldContainer t-Form-fieldContainer--stacked '|| c_metadata.indcdor_rqrdo|| ' t-Form-fieldContainer--stretchInputs">';            
            v_html := v_html ||  '<div class="t-Form-labelContainer col col-3">';
            v_html := v_html ||  '<label for="'||'INP'||c_metadata.id_impsto_sbmpsto_mtdta||'" class="t-Form-label">'||c_metadata.nmbre||'</label>';
            v_html := v_html ||  '</div>';
            v_html := v_html ||  '<div class="t-Form-inputContainer">';
            v_html := v_html ||  '<div class="t-Form-itemWrapper">';

    case c_metadata.tpo_objto
                when 'T' then
                    case when c_metadata.tpo_dto  in ('C','N')
                         then 
                            v_html := v_html || 
                                apex_item.text(
                                    p_idx        => 1,
                                    p_value      => c_metadata.vlor,               
                                    p_attributes => c_metadata.rqrdo || c_metadata.disabled || ' class="text_field apex-item-text" size="30"',
                                    p_item_id    => 'INP'||c_metadata.id_impsto_sbmpsto_mtdta); 
                         when c_metadata.tpo_dto  in ('D')
                         then
                            begin
                                c_metadata.vlor := to_char(to_date(c_metadata.vlor), 'dd/mm/YYYY');
                            exception
                                when others then 
                                    c_metadata.vlor := null;
                            end;
                            v_html := v_html ||
                                apex_item.date_popup2(
                                    p_idx                 => 1,   
                                    p_attributes          => c_metadata.rqrdo || c_metadata.disabled || ' class="datepicker apex-item-text apex-item-datepicker"',
                                    p_value               => c_metadata.vlor,
                                    p_date_format         => 'DD/MM/YYYY',
                                    p_item_id             => 'INP'|| c_metadata.id_impsto_sbmpsto_mtdta,
                                    p_navigation_list_for => 'MONTH_AND_YEAR',
                                    p_size                => 20);
                    end case;
            when 'S' then
                 v_html := v_html ||   
                        apex_item.select_list_from_query_xl(
                                   p_idx           => 1,
								   p_value         => c_metadata.vlor,
								   p_query         => c_metadata.orgen,
								   p_attributes    => c_metadata.rqrdo || c_metadata.disabled || ' class="selectlist apex-item-select"',
								   p_show_null     => 'YES',
								   p_null_value    => null,
								   p_null_text     => 'Seleccione',
								   p_item_id       => 'INP'||c_metadata.id_impsto_sbmpsto_mtdta, 
								   p_show_extra    => null);
            when 'A' then
                 v_html := v_html ||
                        apex_item.textarea(
                            p_idx           => 1,
                            p_value         => c_metadata.vlor,
                            p_rows          => 4,
                            p_cols          => 40,
                            p_item_id       => 'INP'||c_metadata.id_impsto_sbmpsto_mtdta,
                            p_attributes    => c_metadata.rqrdo || c_metadata.disabled || ' class="textarea apex-item-textarea"');                            
            else
                v_html := v_html ||  ' ';
            end case;
            v_html := v_html ||  '</div></div></div></div>';
            if (mod(c_metadata.rw, 2) = 0 or c_metadata.cnt = c_metadata.rw)then
                v_html := v_html ||  '</div>';
            end if;
    end loop;
    return v_html;
  end fnc_gn_region_metadatos;





  function fnc_vl_titulo_ejecutivo(p_nmro_ttlo_ejctvo in  number,
                                   p_id_ttlo_ejctvo   in  number default null,
                                   p_cdgo_clnte       in  number)

    return number as

  v_nmro_ttlo_ejctvo    number;

  begin

        --Valida si el Título Ejecutivo existe
        begin
            select count(t.nmro_ttlo_ejctvo) 
            into v_nmro_ttlo_ejctvo
            from gi_g_titulos_ejecutivo t
            where t.cdgo_clnte = p_cdgo_clnte
            and ((p_id_ttlo_ejctvo is not null and (t.id_ttlo_ejctvo <>  p_id_ttlo_ejctvo)) or (p_id_ttlo_ejctvo is null))
            and   t.nmro_ttlo_ejctvo = p_nmro_ttlo_ejctvo;

            return v_nmro_ttlo_ejctvo;
        end;

  end fnc_vl_titulo_ejecutivo;





  function fnc_vl_numero_guia(p_nmro_ntfccion     in  number,
                              p_id_ttlo_ejctvo    in  number default null,
                              p_cdgo_clnte        in  number)

    return number as

    v_nmro_guia number;
  begin

    --Valida si el numero de guia existe
        begin
            select count(t.nmro_guia)
            into v_nmro_guia
            from gi_g_titulos_ejecutivo t
            where t.cdgo_clnte = p_cdgo_clnte
            and ((p_id_ttlo_ejctvo is not null and (t.id_ttlo_ejctvo <>  p_id_ttlo_ejctvo)) or (p_id_ttlo_ejctvo is null))
            and t.nmro_guia       =   p_nmro_ntfccion;

            return v_nmro_guia;
        end;

  end fnc_vl_numero_guia;

end pkg_gi_titulos_ejecutivo;

/
