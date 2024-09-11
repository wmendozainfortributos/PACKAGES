--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES_ELEMENTO" as
    
    /**/
    function fnc_co_vigencia(p_id_dclrcion in number)
    return varchar2
    is
        v_vgncia    varchar2(100);
    begin
        begin 
            select 'AÑO GRAVABLE ' || vgncia 
              into v_vgncia
              from gi_g_declaraciones 
             where id_dclrcion = p_id_dclrcion;             
        exception
            when others then 
                v_vgncia := '';
        end;        
        return v_vgncia;    
    end fnc_co_vigencia;

    /**/
    function fnc_co_destinatario(p_id_dclrcion in number)
    return clob
    is 
        v_json          clob;
        v_cdgo_clnte    number;
        v_dstntrio      clob;         
    begin
        begin
            select cdgo_clnte    
              into v_cdgo_clnte 
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion;
        exception
            when others then
                return '[]';
        end;

        v_dstntrio  := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte 				=> v_cdgo_clnte
                                                                      , p_cdgo_dfncion_clnte_ctgria	=> 'RPT'
                                                                      , p_cdgo_dfncion_clnte		    => 'DST');
        begin
            select json_arrayagg( json_object(key 'valor' value a.cdna) returning clob)
              into v_json
              from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => v_dstntrio, p_crcter_dlmtdor => ',')) a ;
        exception
            when others then 
                v_json := '[]';
        end;
        return v_json;    
    end fnc_co_destinatario;

    /**/
    function fnc_co_tipo_sujeto(p_id_dclrcion in number)
    return clob
    is
        v_cdgo_clnte    number;
        v_vlor          varchar2(4000);
        v_cdgo_rspsta   number;
        v_mnsje_rspsta  varchar2(4000);
        v_rgmen         clob;
        v_id_impsto     number;

    begin  
        begin
            select cdgo_clnte    
                 , id_impsto
              into v_cdgo_clnte
                 , v_id_impsto
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion; 

            pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte      => v_cdgo_clnte
                                                    , p_cdgo_hmlgcion   => 'ELM'
                                                    , p_cdgo_prpdad     => 'RGM'
                                                    , p_id_dclrcion     => p_id_dclrcion
                                                    , o_vlor            => v_vlor
                                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                                    , o_mnsje_rspsta    => v_mnsje_rspsta);

            select listagg('<span> ' || initcap(b.nmbre_sjto_tpo) || ' ' || decode(v_vlor, b.id_sjto_tpo, '<span style="font-size: 18px;">&#x2612;</span>', '<span style="font-size: 18px;">&#x2610;</span>')||' </span>', '') within group (order by null )
              into v_rgmen
              from df_i_sujetos_tipo b
             where b.cdgo_clnte = v_cdgo_clnte             
               and b.id_impsto = v_id_impsto   ;
        exception
            when others then 
                v_rgmen := '';
        end;

        return v_rgmen;
    end fnc_co_tipo_sujeto;

    /**/        
    function fnc_co_uso(p_id_dclrcion in number)
    return clob
    is
        v_cdgo_clnte    number;
        v_vlor          varchar2(4000);
        v_cdgo_rspsta   number;
        v_mnsje_rspsta  varchar2(4000);
        v_uso           clob; 

    begin  
        begin
            select cdgo_clnte     
              into v_cdgo_clnte 
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion; 

            pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte      => v_cdgo_clnte
                                                    , p_cdgo_hmlgcion   => 'ELM'
                                                    , p_cdgo_prpdad     => 'USO'
                                                    , p_id_dclrcion     => p_id_dclrcion
                                                    , o_vlor            => v_vlor
                                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                                    , o_mnsje_rspsta    => v_mnsje_rspsta); 
            select listagg('<span> ' || b.nmbre_dclrcion_uso || ' ' || decode(v_vlor, b.cdgo_dclrcion_uso, '<span style="font-size: 18px;">&#x2612;</span>', '<span style="font-size: 18px;">&#x2610;</span>')||' </span>', '') within group (order by null )
              into v_uso
              from gi_d_declaraciones_uso b
              where b.cdgo_clnte = v_cdgo_clnte;
        exception
            when others then 
                v_uso := '';
        end;    
        return v_uso;
    end fnc_co_uso;    

    /**/
    function fnc_co_tipo_documento(p_id_dclrcion in number, p_cdgo_prpdad in varchar2)
    return clob
    is 
        v_cdgo_clnte    number;
        v_cdgo_rspsta   number;
        v_mnsje_rspsta  varchar2(4000);
        v_vlor          varchar2(4000);
        v_tipo_documento    clob;
    begin
        begin
            select cdgo_clnte     
              into v_cdgo_clnte 
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion;

            pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte      => v_cdgo_clnte
                                                    , p_cdgo_hmlgcion   => 'ELM'
                                                    , p_cdgo_prpdad     => p_cdgo_prpdad 
                                                    , p_id_dclrcion     => p_id_dclrcion
                                                    , o_vlor            => v_vlor
                                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                                    , o_mnsje_rspsta    => v_mnsje_rspsta);

            select listagg('<span> ' || b.nmtcnco_idntfccion_tpo|| ' ' || decode(v_vlor, b.cdgo_idntfccion_tpo, '<span style="font-size: 18px;">&#x2612;</span>', '<span style="font-size: 18px;">&#x2610;</span>')|| ' </span>', '') within group (order by null )
              into v_tipo_documento
              from v_gi_d_identificaciones_tipo b;

        exception
            when others then
                v_tipo_documento := '';
        end;
        return v_tipo_documento;    
    end fnc_co_tipo_documento;

    /**/
    function fnc_co_numero_declaracion(p_id_dclrcion in number)
    return varchar2
    is
        v_nmro_cnsctvo varchar2(4000);
    begin
        begin
            select nmro_cnsctvo 
              into v_nmro_cnsctvo 
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion ;
        exception
            when others then
                v_nmro_cnsctvo := '';
        end;
        return v_nmro_cnsctvo;
    end;


    function fnc_co_tipo_sujeto_periodo(p_id_dclrcion in number)
    return clob
    is    
        v_cdgo_clnte        number;
        v_cdgo_rspsta       number;
        v_mnsje_rspsta      varchar2(4000);
        v_vlor              varchar2(4000);
        v_nmbre_sjto_tpo    varchar2(4000);
        v_prdo              clob;
        v_id_prdo           number;
    begin
        begin
            select cdgo_clnte     
                 , id_prdo
              into v_cdgo_clnte 
                 , v_id_prdo
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion;

            pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte      => v_cdgo_clnte
                                                    , p_cdgo_hmlgcion   => 'ELM'
                                                    , p_cdgo_prpdad     => 'SJT' 
                                                    , p_id_dclrcion     => p_id_dclrcion
                                                    , o_vlor            => v_vlor
                                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                                    , o_mnsje_rspsta    => v_mnsje_rspsta);
        exception
            when others then
                return  null;
        end;

        begin
            select a.nmbre_sjto_tpo
              into v_nmbre_sjto_tpo
              from df_i_sujetos_tipo   a
             where a.id_sjto_tpo = v_vlor;
        exception
            when others then
                return null;
        end;

        begin
            select '<fieldset><table style="border: none !important;"><tr style="margin-left:10px !important; border: none !important;">' || 
                   listagg('<td style="padding:5px !important; border: 1px dotted !important;"><span> ' || a.dscrpcion|| '</span></td>', '' ) within group (order by  a.id_prdo ) || '</tr><tr style="margin-left:10px !important; border: none !important;">' || 
                   listagg('<td style="padding:5px !important; border: 1px dotted !important;" ><center>' || decode(v_id_prdo, a.id_prdo, '<span style="font-size: 14px;">&#x2612;</span>', '<span style="font-size: 14px;">&#x2610;</span>') || '</center></td>', '') within group (order by  a.id_prdo ) ||                                                      
                   '</tr><legend style="font-size: 14px;">'|| v_nmbre_sjto_tpo || '</legend></fieldset>'
              into v_prdo
              from (select case when d.cdgo_prdcdad = 'BIM' 
                                then substr(d.dscrpcion,0,3) ||substr(d.dscrpcion,(instr(d.dscrpcion,' - ')),6) 
                                when d.cdgo_prdcdad = 'MNS'
                                then substr(d.dscrpcion,0,3)
                                else
                                d.dscrpcion
                           end  as dscrpcion
                         , d.id_prdo
                      from df_i_periodos   d 
                     where exists( select c.cdgo_prdcdad
                                     from gi_d_dclrcnes_vgncias_frmlr a
                                     join gi_d_dclrcnes_tpos_vgncias  b   on  b.id_dclrcion_tpo_vgncia    =   a.id_dclrcion_tpo_vgncia
                                     join gi_d_declaraciones_tipo     c   on  c.id_dclrcn_tpo             =   b.id_dclrcn_tpo
                                     join gi_g_declaraciones          e   on  e.id_dclrcion_vgncia_frmlrio=   a.id_dclrcion_vgncia_frmlrio
                                    where e.id_dclrcion       = p_id_dclrcion
                                      and d.cdgo_prdcdad      = c.cdgo_prdcdad
                                      and d.id_impsto         = c.id_impsto
                                      and d.id_impsto_sbmpsto = c.id_impsto_sbmpsto
                                      and d.vgncia            = b.vgncia
                                   ) ) a;
            return v_prdo;  
        exception
            when others then
                 return null;
        end;         
    end fnc_co_tipo_sujeto_periodo;

    /*function fnc_co_periodo(p_id_dclrcion in number)
    return clob
    is    
        v_cdgo_clnte        number;
        v_cdgo_rspsta       number;
        v_mnsje_rspsta      varchar2(4000);
        v_vlor              varchar2(4000);
        v_nmbre_sjto_tpo    varchar2(4000);
        v_prdo              clob;
        v_id_prdo           number;
    begin
        begin
             select cdgo_clnte     
                 , id_prdo
              into v_cdgo_clnte 
                 , v_id_prdo
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion;
            
            select  '<table style="border: none !important;"><tr style="margin-left:10px !important; border: none !important;">' || 
                    listagg('<td style="padding:5px !important; border: 1px dotted !important;"><span> ' || f.dscrpcion|| '</span></td>', '' ) within group (order by  f.id_prdo ) || '</tr><tr style="margin-left:10px !important; border: none !important;">' || 
                    listagg('<td style="padding:5px !important; border: 1px dotted !important;" ><center>' || decode(v_id_prdo, f.id_prdo, '<span style="font-size: 14px;">&#x2612;</span>', '<span style="font-size: 14px;">&#x2610;</span>') || '</center></td>', '') within group (order by  f.id_prdo ) ||
                    '</tr></table>'
            into    v_prdo
            from    (
                        select  case    when a.cdgo_prdcdad = 'BIM'
                                            then substr(a.dscrpcion,0,3) ||substr(a.dscrpcion,(instr(a.dscrpcion,' - ')),6) 
                                        when a.cdgo_prdcdad = 'MNS'
                                            then substr(a.dscrpcion,0,3)
                                        else    a.dscrpcion
                                end  as dscrpcion,
                                a.id_prdo
                        from    df_i_periodos               a
                        join    gi_d_dclrcnes_tpos_vgncias  b   on  b.id_prdo   =   a.id_prdo
                        where   b.actvo =   'S'
                        and     exists  (
                                            select  1
                                            from    gi_g_declaraciones          c
                                            join    gi_d_dclrcnes_vgncias_frmlr d   on  d.id_dclrcion_vgncia_frmlrio    =   c.id_dclrcion_vgncia_frmlrio
                                            join    gi_d_dclrcnes_tpos_vgncias  e   on  e.id_dclrcion_tpo_vgncia        =   d.id_dclrcion_tpo_vgncia
                                            where   c.id_dclrcion               =   p_id_dclrcion
                                            and     e.id_dclrcn_tpo             =   b.id_dclrcn_tpo
                                            and     e.vgncia                    =   b.vgncia
                                        )
                        order by    a.prdo
                    )   f;
            return v_prdo;  
        exception
            when others then
                 return null;
        end;         
    end fnc_co_periodo;*/
    function fnc_co_periodo(p_id_dclrcion in number) return clob is
        v_cdgo_clnte     number;
        v_cdgo_rspsta    number;
        v_mnsje_rspsta   varchar2(4000);
        v_vlor           varchar2(4000);
        v_nmbre_sjto_tpo varchar2(4000);
        v_prdo           clob;
        v_id_prdo        number;
      begin
        begin
          select cdgo_clnte, id_prdo
            into v_cdgo_clnte, v_id_prdo
            from gi_g_declaraciones
           where id_dclrcion = p_id_dclrcion;
        
          select '<table style="border: none !important;"><tr style="margin-left:10px !important; border: none !important;">' ||
                 listagg('<td style="padding:5px !important; border: 1px dotted !important;"><span> ' ||
                         f.dscrpcion || '</span></td>',
                         '') within group(order by f.prdo) || '</tr><tr style="margin-left:10px !important; border: none !important;">' || listagg('<td style="padding:5px !important; border: 1px dotted !important;" ><center>' || decode(v_id_prdo, f.id_prdo, '<span style="font-size: 14px;">&#x2612;</span>', '<span style="font-size: 14px;">&#x2610;</span>') || '</center></td>', '') within group(order by f.prdo) || '</tr></table>'
            into v_prdo
            from (select case
                           when a.cdgo_prdcdad = 'BIM' then
                            substr(a.dscrpcion, 0, 3) ||
                            substr(a.dscrpcion, (instr(a.dscrpcion, ' - ')), 6)
                           when a.cdgo_prdcdad = 'MNS' then
                            substr(a.dscrpcion, 0, 3)
                           else
                            a.dscrpcion
                         end as dscrpcion,
                         a.id_prdo,
                         a.prdo
                    from df_i_periodos a
                    join gi_d_dclrcnes_tpos_vgncias b
                      on b.id_prdo = a.id_prdo
                   where b.actvo = 'S'
                     and exists (select 1
                            from gi_g_declaraciones c
                            join gi_d_dclrcnes_vgncias_frmlr d
                              on d.id_dclrcion_vgncia_frmlrio =
                                 c.id_dclrcion_vgncia_frmlrio
                            join gi_d_dclrcnes_tpos_vgncias e
                              on e.id_dclrcion_tpo_vgncia =
                                 d.id_dclrcion_tpo_vgncia
                           where c.id_dclrcion = p_id_dclrcion
                             and e.id_dclrcn_tpo = b.id_dclrcn_tpo
                             and e.vgncia = b.vgncia)
                   order by a.prdo) f;
          return v_prdo;
        exception
          when others then
            return null;
        end;
      end fnc_co_periodo;

    function fnc_co_tpo_rspnsble_atrzcion(p_id_dclrcion in number)
    return clob
    is
        v_tpo_rspnsble_atrzcion clob;
        v_cdgo_clnte            number;
        v_cdgo_rspsta           number;
        v_mnsje_rspsta          varchar2(4000);
        v_vlor                  varchar2(4000);
    begin
        begin
            select cdgo_clnte     
              into v_cdgo_clnte 
              from gi_g_declaraciones
             where id_dclrcion = p_id_dclrcion;

            pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte      => v_cdgo_clnte
                                                    , p_cdgo_hmlgcion   => 'ELM'
                                                    , p_cdgo_prpdad     => 'TRA' 
                                                    , p_id_dclrcion     => p_id_dclrcion
                                                    , o_vlor            => v_vlor
                                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                                    , o_mnsje_rspsta    => v_mnsje_rspsta);



            select listagg('<span> ' || a.dscrpcion_rspnsble_tpo|| ' ' || decode(v_vlor, a.cdgo_rspnsble_tpo, '<span style="font-size: 18px;">&#x2612;</span>', '<span style="font-size: 18px;">&#x2610;</span>')|| ' </span>', '<br/>') within group (order by null )                        
              into v_tpo_rspnsble_atrzcion
              from df_s_responsables_tipo a
             where a.cdgo_rspnsble_tpo in ('RF', 'CO');            

        exception
            when others then
                v_tpo_rspnsble_atrzcion := '';
        end;

        return v_tpo_rspnsble_atrzcion;
    end;    

    function fnc_co_bancos_recaudadores(p_id_dclrcion in number) return clob is
    v_result clob;
  begin
    for r1 in (select a.cdgo_clnte, a.id_impsto, a.id_impsto_sbmpsto
                 from gi_g_declaraciones a
                where a.id_dclrcion = p_id_dclrcion) loop
      v_result := pkg_gn_generalidades.fnc_co_bancos_recaudadores(p_cdgo_clnte        => r1.cdgo_clnte,
                                                                  p_id_impsto         => r1.id_impsto,
                                                                  p_id_impsto_sbmpsto => r1.id_impsto_sbmpsto);
    end loop;
    return v_result;
  end fnc_co_bancos_recaudadores;

end pkg_gi_declaraciones_elemento;

/
