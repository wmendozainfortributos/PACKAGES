--------------------------------------------------------
--  DDL for Package Body PKG_GN_REGENERAR_ACTOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GN_REGENERAR_ACTOS" AS
    
    ---------------------------
    --Up para guardar traza de regeneración del acto
    ---------------------------
    procedure prc_rg_rgnra_acto ( p_cdgo_clnte 		    in number,
                                  p_id_acto        	    in number,
                                  p_nmro_acto        	in varchar2,
                                  p_fcha_acto           in date default null,
                                  p_id_acto_tpo         in number,
                                  p_anio                in number,
                                  p_id_dcmnto           in number,
                                  p_fcha_rgnrar         in date,
                                  p_id_usrio            in number,
                                  p_cdgo_rspsta 		in number default null,
                                  p_mnsje_rspsta 		in varchar2 default null
                                 )AS
    v_nl            number;
	v_nmbre_up      varchar2(1000) := 'pkg_gn_regenerar_actos.prc_rg_rgnra_acto';
    v_fcha_rgnrar   date;
    
    BEGIN
        v_fcha_rgnrar := to_date (p_fcha_rgnrar, 'DD/MM/YY HH24:MI:SS');
        begin
            insert into gn_g_regenerar_actos_traza  
            (cdgo_clnte    ,id_acto       ,nmro_acto        ,fcha_acto        ,id_acto_tpo ,
             anio          ,id_dcmnto     ,fcha_rgnrar      ,id_usrio_rgnrar  ,cdgo_error  ,mnsje_error)
            values  
            (p_cdgo_clnte  ,p_id_acto     ,p_nmro_acto      ,p_fcha_acto       ,p_id_acto_tpo ,
             p_anio        ,p_id_dcmnto   ,v_fcha_rgnrar    ,p_id_usrio        ,p_cdgo_rspsta  ,p_mnsje_rspsta);
         exception
            when others then
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, p_mnsje_rspsta||','||sqlerrm, 6);
                --insert into muerto(v_001) values(P_CDGO_CLNTE ||' , '||P_ID_ACTO ||' , '||P_NMRO_ACTO ||' , '||P_FCHA_ACTO ||' , '||P_ANIO ||' , '||SYSDATE ||' , '||p_id_usrio||' ,'||p_cdgo_rspsta||' , '||p_mnsje_rspsta);
         end;
         COMMIT;
    END prc_rg_rgnra_acto;

    ---------------------------
    --Up para regenerar Actos de Fiscalización
    ---------------------------
    procedure prc_rgnra_acto_fsclzcion  ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          date default null,
                                          p_fcha_fin            date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        ) as
		v_nl                    number;
		v_nmbre_up              varchar2(1000) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_fsclzcion';
		v_gnra_acto             varchar2(10);
		v_blob                  blob;
		v_id_usrio_apex         number;
		v_id_dcmnto             number;
		v_xml                   clob;
		v_json_envia            json_object_t;
		v_dcmnto                clob;
        v_nmbre_cnslta          varchar2(1000);
        v_nmbre_plntlla         varchar2(1000);
        v_cdgo_frmto_plntlla    varchar2(100);
        v_cdgo_frmto_tpo        varchar2(100);
        v_file_blob             blob;
        v_file_bfile            bfile;
	begin	
	
		begin
			o_cdgo_rspsta := 0;
			o_mnsje_rspsta := 'Acto regenerado con exito';
			
			v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_gn_regenerar_actos.prc_rgnra_acto_fsclzcion');
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
            
            for i       in (select a.id_fsclzcion_expdnte id_fsclzcion_expdnte,
                                   b.id_fsclzcion_expdnte_acto id_fsclzcion_expdnte_acto,
                                   c.id_impsto id_impsto,
                                   c.id_sjto_impsto id_sjto_impsto,
                                   b.id_acto id_acto,
                                   b.id_rprte id_rprte,
                                   b.id_plntlla id_plntlla,
                                   d.id_dcmnto id_dcmnto,
                                   a.id_instncia_fljo id_instncia_fljo,
                                   f.idntfccion_sjto idntfccion_sjto,
                                   d.nmro_acto nmro_acto,
                                   d.fcha fcha,
                                   d.id_acto_tpo id_acto_tpo,
                                   d.anio anio
                            from fi_g_fiscalizacion_expdnte     a
                            join fi_g_fsclzcion_expdnte_acto    b on b.id_fsclzcion_expdnte = a.id_fsclzcion_expdnte
                            join fi_g_candidatos                c on c.id_cnddto = a.id_cnddto
                            join v_si_i_sujetos_impuesto        f on c.id_sjto_impsto = f.id_sjto_impsto
                            join v_gn_g_actos                   d on d.id_acto = b.id_acto
                            where(d.nmro_acto   = p_nmro_acto  or p_nmro_acto is null)
                              and d.id_acto_tpo = p_id_acto_tpo
                              and d.cdgo_acto_orgen = 'FISCA'
                              and(trunc(d.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                              and ((d.file_blob is null or dbms_lob.getlength(d.file_blob) <= 5000) or (d.file_bfile is null and dbms_lob.getlength(d.file_bfile) <= 5000))
                              and rownum < 10
            )loop
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i.id_dcmnto;
                End;
                
                If(v_id_dcmnto = 0)then
                    update gn_g_actos 
                   set id_dcmnto       = null, indcdor_ntfccion = 'N'
                   where id_acto       = i.id_acto
                     and id_acto_tpo   = i.id_acto_tpo ;
                end if;
                
                --Se obtiene informacion del reporte
                begin
                    select 
                         a.nmbre_cnslta,
                         a.nmbre_plntlla,
                         a.cdgo_frmto_plntlla,
                         a.cdgo_frmto_tpo
                    into v_nmbre_cnslta,
                         v_nmbre_plntlla,
                         v_cdgo_frmto_plntlla,
                         v_cdgo_frmto_tpo
                    from gn_d_reportes a
                    join gn_d_plantillas b on b.id_rprte = a.id_rprte
                    where b.id_acto_tpo = i.id_acto_tpo;   
                exception
                    when others then
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := 'Problema al obtener informacion del reporte';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                --se genera el documento
                begin
                     v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto( p_xml => '[{"ID_SJTO_IMPSTO": '   || i.id_sjto_impsto   || ',
                                                                                 "ID_INSTNCIA_FLJO": ' || i.id_instncia_fljo || ',
                                                                                 "IDNTFCCION": '       || i.idntfccion_sjto  || ',
                                                                                 "ID_ACTO_TPO": '      || i.id_acto_tpo      || '}]',
                                                                     p_id_plntlla => i.id_plntlla
                                                                  );
                exception
                    when others then
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := ' No se pudo generar el documento';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                        
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                
                end;
                
                begin
                    v_xml :='<data>
                                <id_fsclzcion_expdnte_acto>'  || i.id_fsclzcion_expdnte_acto || '</id_fsclzcion_expdnte_acto>
                                <p_id_impsto>'                || i.id_impsto                 || '</p_id_impsto>
                                <p_id_fsclzcion_expdnte>'     || i.id_fsclzcion_expdnte      || '</p_id_fsclzcion_expdnte>
                                <cdgo_srie>FI</cdgo_srie>
                                <id_sjto_impsto>'             || i.id_sjto_impsto            || '</id_sjto_impsto>
                                <id_acto>'                    || i.id_acto                   || '</id_acto>
                                <cdgo_clnte>'                 || p_cdgo_clnte                || '</cdgo_clnte>
                             </data>';
                exception
                    when others then
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := ' No se pudo crear el XML';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    
                end;
                
                begin
                    if v('APP_SESSION') is null then
                        v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                           p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                           p_cdgo_dfncion_clnte        => 'USR');
        
                        apex_session.create_session(p_app_id   => 66000,
                                                    p_page_id  => 2,
                                                    p_username => v_id_usrio_apex);
                    else
                        --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                        apex_session.attach(p_app_id     => 66000,
                                            p_page_id    => 2,
                                            p_session_id => v('APP_SESSION'));
                    end if;
                exception
                    when others then
                        o_cdgo_rspsta := 40;
                        o_mnsje_rspsta := 'Error al setear los valores de la sesión';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                apex_util.set_session_state('P2_XML'     ,  v_xml);
                apex_util.set_session_state('P2_ID_RPRTE',  i.id_rprte);
                apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
            --	apex_util.set_session_state('F_FRMTO_MNDA', 'FM$999G999G999G999G999G999G990');
    
                v_json_envia := json_object_t();
                v_json_envia.put('ID_SJTO_IMPSTO'  , i.id_sjto_impsto);
                v_json_envia.put('ID_INSTNCIA_FLJO', i.id_instncia_fljo);
                
                
                
                for e in 1..3 loop
                    begin
                        v_blob := apex_util.get_print_document(
                                                                p_application_id     => 66000,
                                                                p_report_query_name  => v_nmbre_cnslta,  
                                                                p_report_layout_name => v_nmbre_plntlla,  
                                                                p_report_layout_type => v_cdgo_frmto_plntlla,
                                                                p_document_format    => v_cdgo_frmto_tpo
                                                                );
                                                                
                         if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                            o_cdgo_rspsta := 0;
                            o_mnsje_rspsta := 'Acto regenerado con exito';
                            exit;
                         else
                            o_cdgo_rspsta := 50;
                            o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                            --DBMS_LOCK.SLEEP(2);
                         end if;
                    end;
                end loop;
               
                if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
            
                    begin
                        pkg_gn_generalidades.prc_ac_acto(p_file_blob			=> v_blob,
                                                         p_id_acto				=> i.id_acto,
                                                         p_ntfccion_atmtca		=> 'N');
                    exception
                        when others then				
                            o_cdgo_rspsta  := 60;
                            o_mnsje_rspsta := 'Error al actualizar el blob: ' || sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);

                    end;
                else
                
                    o_cdgo_rspsta  := 70;
                    o_mnsje_rspsta := 'Blob mal generado, longitud: ' || dbms_lob.getlength(v_blob);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    
                end if;-- FIn Actualizar el blob en la tabla de acto
                
                
                if(o_cdgo_rspsta = 0)then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else
                    rollback;
                end if;
            end loop;
            begin
                apex_session.attach(p_app_id     => 66000,
                                    p_page_id    => 100,
                                    p_session_id => v('APP_SESSION'));
            exception
                when others then
                    o_cdgo_rspsta  := 60;
                    o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        end;
        
    end prc_rgnra_acto_fsclzcion ;
    

    ---------------------------
    --up que regenera actos de origen de proceso juridico
    ---------------------------  
    procedure prc_rgnra_acto_jrdco (  p_nmro_acto        	in varchar2,
                                      p_cdgo_clnte 		    in number,
                                      p_id_acto_tpo         in number,
                                      p_fcha_incio          date default null,
                                      p_fcha_fin            date default null,
                                      p_id_usrio            in number,
                                      o_cdgo_rspsta 		out number,
                                      o_mnsje_rspsta 		out varchar2
                                   ) AS
    v_nl number;
	v_nmbre_up varchar2(100) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_jrdco';
    v_documento             clob;
    v_id_usrio_apex         number;
    v_blob                  blob;
    v_json_prmtros          clob;
    v_id_acto               number;
    v_id_dcmnto             number;
    v_fcha                  date;
    --v_file_blob             blob;
    v_nmbre_cnslta          varchar2(100);
    v_nmbre_plntlla         varchar2(100);
    v_cdgo_frmto_plntlla    varchar2(5);
    v_cdgo_frmto_tpo        varchar2(5);
    v_id_rprte              number;
    v_id_plntlla            number;
    v_existe                number;
    v_id_usrio              number;
    v_id_fncnrio            number; 
    v_mnsje_tpo             number;
    v_mnsje                 varchar2(200);
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
      
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i_actos in (select  
                            a.id_acto id_acto, a.id_dcmnto id_dcmnto, a.fcha fcha, b.nmbre_cnslta nmbre_cnslta,
                            b.nmbre_plntlla nmbre_plntlla, b.cdgo_frmto_plntlla cdgo_frmto_plntlla,
                            b.cdgo_frmto_tpo cdgo_frmto_tpo, b.id_rprte id_rprte,c.id_plntlla id_plntlla,
                            a.id_acto_tpo id_acto_tpo,a.anio anio
                        from v_gn_g_actos a
                        join gn_d_plantillas    c on c.id_acto_tpo  = a.id_acto_tpo
                        join gn_d_reportes      b on b.id_rprte     = c.id_rprte
                        where(a.nmro_acto   = p_nmro_acto  or p_nmro_acto is null)
                          and a.id_acto_tpo = p_id_acto_tpo
                          and a.cdgo_acto_orgen = 'GCB'
                          and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                          and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                          and rownum < 10
            )loop 
                for i in (select *  
                      from v_cb_g_procesos_jrdco_dcmnto a                      
                      where a.id_acto       = i_actos.id_acto
                        and a.id_acto_tpo   = i_actos.id_acto_tpo
                        
                    ) 
            loop
                
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i_actos.id_dcmnto;
                End;
                
                If(v_id_dcmnto = 0)then
                    update gn_g_actos 
                   set id_dcmnto       = null, indcdor_ntfccion = 'N'
                   where id_acto       = i.id_acto
                     and id_acto_tpo   = i_actos.id_acto_tpo ;
                end if;
                 
                --generamos el HTML del documento
                begin
                    v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":"' ||
                                                                      i.id_prcsos_jrdco ||
                                                                      '","id_prcsos_jrdco_dcmnto":"' ||
                                                                      i.id_prcsos_jrdco_dcmnto || '"}',
                                                                      i_actos.id_plntlla);
                exception
                    when others then
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := ' No se pudo generar el documento';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                        
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                 
                --validamos que exista registro de la plantilla del documento, si existe se actualiza si no existe se inserta                                                             
                begin
                    select count(id_prcsos_jrdc_dcmnt_plnt)
                    into v_existe
                    from cb_g_prcsos_jrdc_dcmnt_plnt
                    where id_prcsos_jrdco_dcmnto = i.id_prcsos_jrdco_dcmnto;
                    
                    if(v_existe = 1) then
                        update cb_g_prcsos_jrdc_dcmnt_plnt x
                            set x.dcmnto = v_documento
                        where x.id_prcsos_jrdco_dcmnto = i.id_prcsos_jrdco_dcmnto;
                        
                        --insert into muerto(v_001,c_001) values('v_documento1',v_documento);
                    elsif(v_existe = 0) then
                    
                        begin
                            insert into 
                            cb_g_prcsos_jrdc_dcmnt_plnt(id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
                            values(i.id_prcsos_jrdco_dcmnto,i_actos.id_plntlla,v_documento);
                            
                            --insert into muerto(v_001,c_001) values('v_documento2',v_documento);
                            
                         exception
                         
                            when others then
                                o_cdgo_rspsta  := 20;
                                o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo insertar el documento';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);     
                                
                                pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                        end;
                    end if;
                    
                    if(o_cdgo_rspsta = 0)then
                        commit;
                    end if;
                    
                end;
                   
            
                --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                if v('APP_SESSION') is null then
                    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente  ( p_cdgo_clnte                => p_cdgo_clnte,
                                                                                          p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                          p_cdgo_dfncion_clnte        => 'USR');
                    apex_session.create_session (  p_app_id   => 66000,
                                                   p_page_id  => 2,
                                                   p_username => v_id_usrio_apex);
                else
                   --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                   apex_session.attach(p_app_id     => 66000,
                                       p_page_id    => 2,
                                       p_session_id => v('APP_SESSION'));
                end if;
                
                select json_object(
                                       'ID_PRCSOS_JRDCO_DCMNTO' value i.id_prcsos_jrdco_dcmnto
                                   )
                into v_json_prmtros
                from dual;
             
                --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                apex_util.set_session_state( 'P71_JSON' , v_json_prmtros );
                apex_util.set_session_state( 'F_CDGO_CLNTE' , p_cdgo_clnte );
                --dbms_output.put_line('llego generar blob');

                --GENERAMOS EL DOCUMENTO
                for e in 1..3 loop
                   begin
                        v_blob := apex_util.get_print_document  (p_application_id     => 66000,
                                                                 p_report_query_name  => i_actos.nmbre_cnslta,
                                                                 p_report_layout_name => i_actos.nmbre_plntlla,
                                                                 p_report_layout_type => i_actos.cdgo_frmto_plntlla,
                                                                 p_document_format    => i_actos.cdgo_frmto_tpo
                                                                );
                                                               
                        if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                            o_cdgo_rspsta := 0;
                            o_mnsje_rspsta := 'Acto regenerado con exito';
                            exit;
                        else
                            o_cdgo_rspsta := 30;
                            o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i_actos.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                            --DBMS_LOCK.SLEEP(2);
                        end if;
                   end;
                end loop;
                --
                 
                --regeneramos el acto
                begin
                        pkg_gn_generalidades.prc_ac_acto(    p_file_blob		=> v_blob,
                                                             p_id_acto			=> i.id_acto,
                                                             p_ntfccion_atmtca	=> 'N');

                exception
                    when others then
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' ocurrio un error al regenerar el acto, pkg_gn_generalidades.prc_ac_acto';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                ---se procede a notificar los actos regenerados
               /* begin
                    select  d.id_fncnrio, c.id_usrio
                      into  v_id_fncnrio,v_id_usrio
                    from  cb_g_procesos_jrdco_dcmnto  a 
                    join  cb_g_procesos_juridico      b on  b.id_prcsos_jrdco = a.id_prcsos_jrdco
                    join  gn_g_actos                  c   on  a.id_acto  = c.id_acto
                    join  v_sg_g_usuarios             d on  c.id_usrio = d.id_usrio
                    where   b.cdgo_clnte  = p_cdgo_clnte
                    and   a.id_acto       = i.id_acto;
                    
                end;
                
                begin
                    --Procedimiento para registrar en notificaciones un conjunto de actos
                    pkg_nt_notificacion.prc_rg_notificaciones_actos(
                                                                        p_cdgo_clnte            => p_cdgo_clnte,
                                                                        p_id_acto               => i.id_acto,
                                                                        p_id_usrio              => v_id_usrio,
                                                                        p_id_fncnrio            => v_id_fncnrio, 
                                                                        o_mnsje_tpo             => v_mnsje_tpo,
                                                                        o_mnsje                 => v_mnsje
                                                                      );                    
                exception
                    when others then
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' ocurrio un error al notificar el acto'||', '||v_mnsje;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                
                end;*/
               
                if(o_cdgo_rspsta = 0)then
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else
                    rollback;
                end if;
            end loop;
            
            --Se setean valores de sesion
            begin
                apex_session.attach(p_app_id     => 66000,
                                    p_page_id    => 100,
                                    p_session_id => v('APP_SESSION'));
            exception
                when others then
                    o_cdgo_rspsta  := 60;
                    o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        end loop;
        
    END prc_rgnra_acto_jrdco;


    ---------------------------
    --up que regenera actos de origen de proceso convenio
    ---------------------------
    procedure prc_rgnra_acto_cnvnio(  p_nmro_acto        	in varchar2,
                                      p_cdgo_clnte 		    in number,
                                      p_id_acto_tpo         in number,
                                      p_fcha_incio          date default null,
                                      p_fcha_fin            date default null,
                                      p_id_usrio            in number,
                                      o_cdgo_rspsta 		out number,
                                      o_mnsje_rspsta 		out varchar2
                                   ) AS
    v_nl                     number;
	v_nmbre_up               varchar2(100) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_cnvnio';
    v_dcmnto                 clob;
    v_xml                    clob;
    v_id_usrio_apex          number;
    v_blob                   blob;
    v_json_prmtros           clob;
    v_id_acto                number;
    v_id_dcmnto              number;
    v_fcha                   date;
    --v_file_blob            blob;
    v_nmbre_cnslta           varchar2(100);
    v_nmbre_plntlla          varchar2(100);
    v_cdgo_frmto_plntlla     varchar2(5);
    v_cdgo_frmto_tpo         varchar2(5);
    v_id_rprte               number;
    v_id_plntlla             number;
    v_existe                 number;
    
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
      
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i_actos in (select  
                            a.id_acto id_acto, a.id_dcmnto id_dcmnto, a.fcha fcha, b.nmbre_cnslta nmbre_cnslta,
                            b.nmbre_plntlla nmbre_plntlla, b.cdgo_frmto_plntlla cdgo_frmto_plntlla,
                            b.cdgo_frmto_tpo cdgo_frmto_tpo, b.id_rprte id_rprte,c.id_plntlla id_plntlla,
                            a.id_acto_tpo id_acto_tpo,a.anio anio, a.id_orgen id_orgen
                        from v_gn_g_actos a
                        join gn_d_plantillas    c on c.id_acto_tpo  = a.id_acto_tpo
                        join gn_d_reportes      b on b.id_rprte     = c.id_rprte
                        where(a.nmro_acto   = p_nmro_acto  or p_nmro_acto is null)
                          and a.id_acto_tpo = p_id_acto_tpo
                          and a.cdgo_acto_orgen = 'CNV'
                          and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                          and((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                          and rownum < 10
            )loop 
                for i in (select a.id_acto id_acto,a.cdgo_clnte cdgo_clnte,a.id_cnvnio id_cnvnio, a.mtvo_rchzo_slctud mtvo_rchzo_slctud,
                                 a.id_impsto id_impsto,a.nmro_acto nmro_acto, b.id_plntlla id_plntlla,b.id_acto_tpo id_acto_tpo,
                                 b.id_rprte id_rprte,b.id_cnvnio_mdfccion id_cnvnio_mdfccion
                          from v_gf_g_convenios a
                          join gf_g_convenios_documentos b on  a.id_cnvnio = b.id_cnvnio
                          where a.id_acto       = i_actos.id_acto
                            and b.id_acto_tpo   = i_actos.Id_acto_tpo
                    ) 
            loop
            
               
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i_actos.id_dcmnto;
                End;
                
                If(v_id_dcmnto = 0)then
                    update gn_g_actos 
                   set id_dcmnto       = null, indcdor_ntfccion = 'N'
                   where id_acto       = i.id_acto
                     and id_acto_tpo   = i_actos.id_acto_tpo ;
                end if;

                 
                --generamos el HTML del documento
                begin
                    v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(  '<COD_CLNTE>'   || i.cdgo_clnte                 ||'</COD_CLNTE>
                                                                      <ID_CNVNIO>'   || i.id_cnvnio                  ||'</ID_CNVNIO>
                                                                      <MTVO_RCHZO>'  ||lower(i.mtvo_rchzo_slctud)    ||'</MTVO_RCHZO>
                                                                      <ID_PLNTLLA>'  ||i.id_plntlla                  ||'</ID_PLNTLLA>
                                                                      <ID_ACTO_TPO>' ||i_actos.id_acto_tpo           ||'</ID_ACTO_TPO>
                                                                      ID_ORGEN>'     ||i_actos.id_orgen              ||'</ID_ORGEN>
                                                                      <ID_IMPSTO>'   ||i.id_impsto                   ||'</ID_IMPSTO>',
                                                                      i.id_plntlla);
                exception
                    when others then
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := ' No se pudo generar el documento';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                        
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                 
                --validamos que exista registro de la plantilla del documento, si existe se actualiza si no existe se inserta                                                             
                begin
                    select count(id_cnvnio_dcmnto)
                    into v_existe
                    from gf_g_convenios_documentos
                    where id_cnvnio_dcmnto = i.id_cnvnio;
                    
                    if(v_existe = 0) then
                        
                        begin
                            insert into gf_g_convenios_documentos
                              (id_cnvnio, id_plntlla, dcmnto, cdgo_clnte,id_rprte, id_usrio_gnro)
                            values
                              (i.id_cnvnio, i_actos.id_plntlla,v_dcmnto,i.cdgo_clnte,i_actos.id_rprte,p_id_usrio);                            
                              --insert into muerto(v_001,c_001) values('v_documento2',v_documento);
                         exception
                            when others then
                                o_cdgo_rspsta  := 20;
                                o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo insertar el documento';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                     
                                pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                        end;
                        
                    end if;
                    
                    if(o_cdgo_rspsta = 0)then
                        commit;
                    end if;
                end;
                    
                
            
                begin
                
                    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                    if v('APP_SESSION') is null then
                        v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                       p_cdgo_dfncion_clnte        => 'USR');
            
                        apex_session.create_session(p_app_id   => 66000,
                                                p_page_id  => 2,
                                                p_username => v_id_usrio_apex);
                    else
                        --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                        apex_session.attach(p_app_id     => 66000,
                                            p_page_id    => 2,
                                            p_session_id => v('APP_SESSION'));
                    end if;
                  
                    v_xml := '<data>
                                  <id_acto>'              ||i.id_acto                 ||'</id_acto>
                                  <id_cnvnio>'            ||i.id_cnvnio               ||'</id_cnvnio>
                                  <cod_clnte>'            ||i.cdgo_clnte              ||'</cod_clnte>
                                  <p_id_rprte>'           ||i.id_rprte                ||'</p_id_rprte>
                                  <id_plntlla>'           ||i.id_plntlla              ||'</id_plntlla>
                                  <id_cnvnio_mdfccion>'   ||i.id_cnvnio_mdfccion      ||'</id_cnvnio_mdfccion> 
                                  <p_id_impsto>'          ||i.id_impsto               ||'</p_id_impsto>
                              </data>'; -- 10/03/2022 agregado para modificacion AP
                      
                     --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                        apex_util.set_session_state('P2_XML'        , v_xml );
                        apex_util.set_session_state('F_CDGO_CLNTE'  , i.cdgo_clnte);
                        apex_util.set_session_state('P2_PRMTRO_1'   , i.id_cnvnio);
                        apex_util.set_session_state('P2_ID_RPRTE'   , i.id_rprte);
                        --dbms_output.put_line('llego generar blob');
    
                     --GENERAMOS EL DOCUMENTO
                     for e in 1..3 loop
                        begin
                             v_blob := apex_util.get_print_document  (p_application_id     => 66000,
                                                                      p_report_query_name  => i_actos.nmbre_cnslta,
                                                                      p_report_layout_name => i_actos.nmbre_plntlla,
                                                                      p_report_layout_type => i_actos.cdgo_frmto_plntlla,
                                                                      p_document_format    => i_actos.cdgo_frmto_tpo
                                                                      );
                                                                       
                             if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                                 o_cdgo_rspsta := 0;
                                 o_mnsje_rspsta := 'Acto regenerado con exito';
                                 exit;
                             else
                                 o_cdgo_rspsta := 30;
                                 o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                                 pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                                 --DBMS_LOCK.SLEEP(2);
                             end if;
                        end;
                     end loop;
                    
                     --
                     begin
                           pkg_gn_generalidades.prc_ac_acto(    p_file_blob			=> v_blob,
                                                                p_id_acto			=> i.id_acto,
                                                                p_ntfccion_atmtca	=> 'N');
                     exception
                            when others then
                                o_cdgo_rspsta  := 40;
                                o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el blob';
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                    
                                pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
     
                     end;
                exception
                    when others then
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo regenerar el acto';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                if(o_cdgo_rspsta = 0)then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                    
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i_actos.fcha,i.id_acto_tpo,i_actos.anio,i_actos.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else 
                    rollback;
                end if;
            end loop;
             --Se setean valores de sesion
            begin
              apex_session.attach(p_app_id     => 66000,
                                  p_page_id    => 100,
                                  p_session_id => v('APP_SESSION'));
            exception
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        end loop;
        
    END prc_rgnra_acto_cnvnio;
    
    ---------------------------
    --up que regenera actos de origen de proceso Prescripción
    ---------------------------
    procedure prc_rgnra_acto_prscrpcion(  p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          date default null,
                                          p_fcha_fin            date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                       ) AS
    v_nl                     number;
	v_nmbre_up               varchar2(100) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_prscrpcion';
    v_dcmnto                 clob;
    v_xml                    clob;
    v_id_usrio_apex          number;
    v_blob                   blob;
    v_json_prmtros           clob;
    v_id_acto                number;
    v_id_dcmnto              number;
    v_fcha                   date;
    --v_file_blob            blob;
    v_nmbre_cnslta           varchar2(100);
    v_nmbre_plntlla          varchar2(100);
    v_cdgo_frmto_plntlla     varchar2(5);
    v_cdgo_frmto_tpo         varchar2(5);
    v_id_rprte               number;
    v_id_plntlla             number;
    v_existe                 number;
    
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
      
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i in (      select   distinct                   
                            a.id_acto id_acto           , d.id_dcmnto id_dcmnto            , a.fcha fcha                  ,a.anio anio                              ,
                            a.id_orgen id_orgen         , a.nmro_acto nmro_acto            ,b.nmbre_plntlla nmbre_plntlla , b.cdgo_frmto_plntlla cdgo_frmto_plntlla ,
                            b.nmbre_cnslta nmbre_cnslta , b.cdgo_frmto_tpo cdgo_frmto_tpo  ,d.id_rprte id_rprte           ,d.id_plntlla id_plntlla                  ,
                            d.id_acto_tpo id_acto_tpo   , d.id_prscrpcion id_prscrpcion
                        from v_gn_g_actos a
                        join gn_d_plantillas        c on c.id_acto_tpo  = a.id_acto_tpo  --and c.id_plntlla = d.id_plntlla
                        join gn_d_reportes          b on b.id_rprte     = c.id_rprte
                        join gf_g_prscrpcns_dcmnto  d on d.id_acto      = a.id_acto and d.id_acto_tpo   = a.id_acto_tpo and d.id_rprte = c.id_rprte
                        where(a.nmro_acto       = p_nmro_acto  or p_nmro_acto is null)
                          and a.id_acto_tpo     = p_id_acto_tpo
                          and a.cdgo_acto_orgen = 'PRS'
                          and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                          and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                          and rownum < 10
            )loop 
            
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i.id_dcmnto;
                End;
                
                If(v_id_dcmnto = 0)then
                    update gn_g_actos 
                   set id_dcmnto       = null, indcdor_ntfccion = 'N'
                   where id_acto       = i.id_acto
                     and id_acto_tpo   = i.id_acto_tpo ;
                end if;
                
                begin
                  --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                  if v('APP_SESSION') is null then
                    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                       p_cdgo_dfncion_clnte        => 'USR');
            
                    apex_session.create_session(p_app_id   => 66000,
                                                p_page_id  => 2,
                                                p_username => v_id_usrio_apex);
                  else
                    --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                    apex_session.attach(p_app_id     => 66000,
                                        p_page_id    => 2,
                                        p_session_id => v('APP_SESSION'));
                  end if;
                  v_xml := '<data>
                                <id_dcmnto>'    || i.id_dcmnto  || '</id_dcmnto> 
                                <id_acto>'      || i.id_acto     || '</id_acto>
                                <id_prscrpcion>'|| i.id_prscrpcion ||'</id_prscrpcion>
                            </data>';
                  
                  --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                    apex_util.set_session_state('p2_xml'        , v_xml );
                    apex_util.set_session_state('F_CDGO_CLNTE'  , p_cdgo_clnte);
                    apex_util.set_session_state('P2_ID_RPRTE'   , i.id_rprte);
                  --dbms_output.put_line('llego generar blob');
                 
                 --GENERAMOS EL DOCUMENTO
                 for e in 1..3 loop
                    begin
                         v_blob := apex_util.get_print_document(    p_application_id     => 66000,
                                                                    p_report_query_name  => i.nmbre_cnslta,
                                                                    p_report_layout_name => i.nmbre_plntlla,
                                                                    p_report_layout_type => i.cdgo_frmto_plntlla,
                                                                    p_document_format    => i.cdgo_frmto_tpo
                                                                );
                                                                   
                         if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                             o_cdgo_rspsta := 0;
                             o_mnsje_rspsta := 'Acto regenerado con exito';
                             exit;
                         else
                             o_cdgo_rspsta := 30;
                             o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                             pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                             --DBMS_LOCK.SLEEP(2);
                         end if;
                    end;
                 end loop;
                 
                  --insert into muerto(v_001,b_001)values('v_blob',v_blob);
                  begin
                       pkg_gn_generalidades.prc_ac_acto(  p_file_blob			=> v_blob,
                                                          p_id_acto			=> i.id_acto,
                                                          p_ntfccion_atmtca	=> 'N'
                                                        );
                  exception
                        when others then
                            o_cdgo_rspsta  := 40;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el blob';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
 
                    end;
                exception
                    when others then
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo regenerar el acto';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                if(o_cdgo_rspsta = 0)then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else 
                    rollback;
                end if;
        end loop;
            
            --Se setean valores de sesion
            begin
              apex_session.attach(p_app_id     => 66000,
                                  p_page_id    => 100,
                                  p_session_id => v('APP_SESSION'));
            exception
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        
    END prc_rgnra_acto_prscrpcion;
    
    ---------------------------
    --up que regenera actos de origen de proceso embargo y desembargo
    ---------------------------
    procedure prc_rgnra_acto_embrgo    (  p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          date default null,
                                          p_fcha_fin            date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                       ) AS
    v_nl                     number;
	v_nmbre_up               varchar2(100) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_embrgo';
    v_dcmnto                 clob;
    v_xml                    clob;
    v_id_usrio_apex          number;
    v_blob                   blob;
    v_json_prmtros           clob;
    v_id_acto                number;
    v_id_dcmnto              number;
    v_fcha                   date;
    v_Dcmnto_Rslcion            clob;
    v_nmbre_cnslta           varchar2(100);
    v_nmbre_plntlla          varchar2(100);
    v_cdgo_frmto_plntlla     varchar2(5);
    v_cdgo_frmto_tpo         varchar2(5);
    v_id_rprte               number;
    v_id_plntlla             number;
    v_existe                 number;
    v_id_embrgos_crtra       number;
    
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';

        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i in (  select distinct                   
                        a.id_acto id_acto           , a.id_dcmnto id_dcmnto                  , a.fcha fcha                  ,a.anio anio                              ,
                        a.id_orgen id_orgen         , a.nmro_acto nmro_acto                  ,b.nmbre_plntlla nmbre_plntlla ,b.cdgo_frmto_plntlla cdgo_frmto_plntlla  ,
                        b.nmbre_cnslta nmbre_cnslta , b.cdgo_frmto_tpo cdgo_frmto_tpo        ,b.id_rprte id_rprte           ,c.id_acto_tpo id_acto_tpo                ,
                        c.id_plntlla  id_plantilla  , d.id_embrgos_rslcion id_embrgos_rslcion
                    from v_gn_g_actos                a
                    join gn_d_plantillas             c on c.id_acto_tpo         = a.id_acto_tpo
                    join gn_d_reportes               b on b.id_rprte            = c.id_rprte
                    join v_mc_g_embargos_resolucion  d on d.id_acto             = a.id_acto
                    join mc_g_embargos_cartera       b on b.id_embrgos_crtra    = d.id_embrgos_crtra
                    join mc_d_tipos_mdda_ctlr_dcmnto c on c.id_tpos_mdda_ctlar  = b.id_tpos_mdda_ctlar
                    where(a.nmro_acto   = p_nmro_acto  or p_nmro_acto is null)
                      and a.id_acto_tpo = p_id_acto_tpo
                      and a.cdgo_acto_orgen = 'MCT'
                      and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                      and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                      and rownum < 10
                      
                    union
                    
                    select distinct                   
                        a.id_acto id_acto           , a.id_dcmnto id_dcmnto                  ,a.fcha fcha                   ,a.anio anio                              ,
                        a.id_orgen id_orgen         , a.nmro_acto nmro_acto                  ,b.nmbre_plntlla nmbre_plntlla ,b.cdgo_frmto_plntlla cdgo_frmto_plntlla  ,
                        b.nmbre_cnslta nmbre_cnslta , b.cdgo_frmto_tpo cdgo_frmto_tpo        ,b.id_rprte id_rprte           ,c.id_acto_tpo id_acto_tpo                ,
                        c.id_plntlla  id_plantilla  ,d.id_dsmbrgos_rslcion id_embrgos_rslcion
                    from v_gn_g_actos                   a
                    join gn_d_plantillas                c on c.id_acto_tpo          = a.id_acto_tpo
                    join gn_d_reportes                  b on b.id_rprte             = c.id_rprte
                    join v_mc_g_desembargos_resolucion  d on d.id_acto              = a.id_acto
                    join mc_d_tipos_mdda_ctlr_dcmnto    c on c.id_tpos_mdda_ctlar   = d.id_tpos_mdda_ctlar
                    where(a.nmro_acto   = p_nmro_acto  or p_nmro_acto is null)
                      and a.id_acto_tpo = p_id_acto_tpo
                      and a.cdgo_acto_orgen = 'MCT'
                      and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                      and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                      and rownum < 10
            )loop 
                o_mnsje_rspsta := 'iniciamos loop';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i.id_dcmnto;
                   
                   o_mnsje_rspsta := 'v_id_dcmnto';
                   pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||v_id_dcmnto, 6);                
                End;
                
                If(v_id_dcmnto = 0)then
                    begin
                        update gn_g_actos 
                        set id_dcmnto       = null, indcdor_ntfccion = 'N'
                        where id_acto       = i.id_acto
                          and id_acto_tpo   = i.id_acto_tpo ;

                    exception
                         when others then
                            o_cdgo_rspsta  := 10;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el Id_documento';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
     
                    end;
                else
                    o_cdgo_rspsta  := 20;
                    o_mnsje_rspsta := o_cdgo_rspsta ||' No exite el Id_documento en gd_g_documentos';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);

                end if;
                /*
                if(o_cdgo_rspsta = 0) then 
                    commit;
                else
                    rollback;
                end if;*/
                --se consulta si el acto cuenta con documento
                begin
                    select Dcmnto_Rslcion, id_embrgos_crtra
                    into v_Dcmnto_Rslcion, v_id_embrgos_crtra
                    from mc_g_embargos_resolucion
                    where id_embrgos_rslcion = i.id_embrgos_rslcion;
                exception
                    when others then   
                        o_cdgo_rspsta  := 25;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' No exite el Dcmnto_Rslcion en mc_g_embargos_resolucion';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                end;
                
                if(v_Dcmnto_Rslcion is null)then
                    -- Se genera el html de la plantilla de resolucion de desembargo
                    begin
                      -- v_dcmnto_html := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| c_embrgos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgos_rslcion>'|| v_id_dsmbrgos_rslcion ||'</id_dsmbrgos_rslcion><id_acto>'||v_id_acto||'</id_acto>', v_id_plntlla_rslcion);
                       v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":'    || v_id_embrgos_crtra   ||
                                                                      ',"id_dsmbrgos_rslcion":' || i.id_embrgos_rslcion ||
                                                                      ',"id_embrgos_rslcion":' || i.id_embrgos_rslcion ||
                                                                      ',"id_acto":'             || i.id_acto             ||'}',
                                                                      i.id_plantilla);                                  
        
                    exception
                        when others then 
                            o_cdgo_rspsta	:= 130;
                            o_mnsje_rspsta	:= o_mnsje_rspsta || o_cdgo_rspsta ||' Error al generar el html de la plantilla de la resolución de embargo. ' || sqlerrm;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                            rollback;
                            return;
                    end; -- Fin Se genera el html de la plantilla de resolucion de desembargo
        
                    -- Se actualiza los datos de resolucion de desembargo (html de la plantilla)
                    begin
                        update mc_g_desembargos_resolucion
                           set dcmnto_dsmbrgo	   = to_clob(v_dcmnto),
                               id_plntlla          = i.id_plantilla
                         where id_dsmbrgos_rslcion = i.id_embrgos_rslcion;
        
                        o_mnsje_rspsta	:= 'Se acualizaron ' || sql%rowcount || ' registros.';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 6);
                    exception 
                        when others then 
                            o_cdgo_rspsta	:= 140;
                            o_mnsje_rspsta	:=  o_mnsje_rspsta || o_cdgo_rspsta ||' Error al actualizar los datos de la resolución desembargo (html de la plantilla). ' || sqlerrm;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
                    end;-- Fin Se actualiza los datos de resolucion de desembargo (html de la plantilla)
                end if;    
                
                begin
                    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                      if v('APP_SESSION') is null then
                        v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                           p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                           p_cdgo_dfncion_clnte        => 'USR');
                
                        apex_session.create_session(p_app_id   => 66000,
                                                    p_page_id  => 2,
                                                    p_username => v_id_usrio_apex);
                      else
                        --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                        apex_session.attach(p_app_id     => 66000,
                                            p_page_id    => 2,
                                            p_session_id => v('APP_SESSION'));
                      end if;
                  
                      v_xml := '<data>
                                    <id_embrgos_rslcion>'    || i.id_embrgos_rslcion  || '</id_embrgos_rslcion>
                                    <id_dsmbrgos_rslcion>'   || i.id_embrgos_rslcion  || '</id_dsmbrgos_rslcion>
                                </data>';
                      
                      --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                      apex_util.set_session_state('F_CDGO_CLNTE'  , p_cdgo_clnte);
                      apex_util.set_session_state('p2_xml'        , v_xml );
                      apex_util.set_session_state('P2_ID_RPRTE'   , i.id_rprte);
                      --dbms_output.put_line('llego generar blob');
                     
                     --GENERAMOS EL DOCUMENTO
                     for e in 1..3 loop
                        begin
                             v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                                                    p_report_query_name  => i.nmbre_cnslta,
                                                                    p_report_layout_name => i.nmbre_plntlla,
                                                                    p_report_layout_type => i.cdgo_frmto_plntlla,
                                                                    p_document_format    => i.cdgo_frmto_tpo);
                                                                       
                             if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                                 o_cdgo_rspsta := 0;
                                 o_mnsje_rspsta := 'Acto regenerado con exito';
                                 exit;
                             else
                                 o_cdgo_rspsta := 30;
                                 o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                         
                                 pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                                 --DBMS_LOCK.SLEEP(2);
                             end if;
                        end;
                     end loop;
                    --
                     --insert into muerto(v_001,b_001)values('v_blob',v_blob);commit;
                     begin
                          pkg_gn_generalidades.prc_ac_acto(    p_file_blob			=> v_blob,
                                                               p_id_acto			=> i.id_acto,
                                                               p_ntfccion_atmtca	=> 'N');
                     exception
                           when others then
                               o_cdgo_rspsta  := 40;
                               o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el blob pkg_gn_generalidades.prc_ac_acto';
                               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                
                               pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
     
                     end;
                exception
                    when others then
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo regenerar el acto';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                        pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);

                end;
                
                if(o_cdgo_rspsta = 0)then
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    rollback;
                end if;

        end loop;
            
            --Se setean valores de sesion
            begin
              apex_session.attach(p_app_id     => 66000,
                                  p_page_id    => 100,
                                  p_session_id => v('APP_SESSION'));
            exception
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        
    END prc_rgnra_acto_embrgo;
    
    ---------------------------
    --up que regenera actos de origen de proceso novedad persona ICA
    ---------------------------
    procedure prc_rgnra_acto_nvdad     (  p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          date default null,
                                          p_fcha_fin            date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                       ) AS
    v_nl                     number;
	v_nmbre_up               varchar2(100) := 'pkg_gn_regenerar_actos.prc_rgnra_acto_embrgo';
    v_dcmnto                 clob;
    v_xml                    clob;
    v_id_usrio_apex          number;
    v_blob                   blob;
    v_json_prmtros           clob;
    v_id_acto                number;
    v_id_dcmnto              number;
    v_fcha                   date;
    --v_file_blob            blob;
    v_nmbre_cnslta           varchar2(100);
    v_nmbre_plntlla          varchar2(100);
    v_cdgo_frmto_plntlla     varchar2(5);
    v_cdgo_frmto_tpo         varchar2(5);
    v_id_rprte               number;
    v_id_plntlla             number;
    v_existe                 number;
    
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
      
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i in (  select distinct                   
                        a.id_acto id_acto           , a.id_dcmnto id_dcmnto                  , a.fcha fcha                  ,a.anio anio                              ,
                        a.id_orgen id_orgen         , a.nmro_acto nmro_acto                  ,b.nmbre_plntlla nmbre_plntlla ,b.cdgo_frmto_plntlla cdgo_frmto_plntlla  ,
                        b.nmbre_cnslta nmbre_cnslta , b.cdgo_frmto_tpo cdgo_frmto_tpo        ,b.id_rprte id_rprte           ,c.id_plntlla id_plntlla                  ,
                        c.id_acto_tpo id_acto_tpo   , d.id_nvdad_prsna id_nvdad_prsna
                    from v_gn_g_actos                a
                    join gn_d_plantillas             c on c.id_acto_tpo  = a.id_acto_tpo
                    join gn_d_reportes               b on b.id_rprte     = c.id_rprte
                    join v_si_g_novedades_persona    d on d.id_acto      = a.id_acto 
                    where a.id_acto_tpo = p_id_acto_tpo
                      and a.cdgo_acto_orgen = 'NPR'
                      and(trunc(a.fcha) between to_date(p_fcha_incio,'dd/mm/yy') and  to_date(p_fcha_fin,'dd/mm/yy') or p_fcha_incio is null or p_fcha_fin is null)
                      and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                      and rownum < 10
            )loop 
                 
                --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select count(id_dcmnto)
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i.id_dcmnto;
                End;
                
                If(v_id_dcmnto = 0)then
                    update gn_g_actos 
                   set id_dcmnto       = null, indcdor_ntfccion = 'N'
                   where id_acto       = i.id_acto
                     and id_acto_tpo   = i.id_acto_tpo ;
                end if;
                
                --validamos que exista HTML
                begin
                    select dcmnto_html
                    into v_dcmnto
                    from si_g_novedades_persona
                    where cdgo_clnte = p_cdgo_clnte
                      and id_nvdad_prsna = i.id_nvdad_prsna;
                end;
                --se genera el documento
                if(v_dcmnto is null) then
                    begin
                          v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_nvdad_prsna":"' ||i.id_nvdad_prsna || '"}',
                                                                         i.id_plntlla
                                                                        );    
                    exception
                        when others then
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := ' No se pudo generar el documento';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                        
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    
                    end;
                end if;
                
                
            
                begin
                  --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                  if v('APP_SESSION') is null then
                    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                       p_cdgo_dfncion_clnte        => 'USR');
            
                    apex_session.create_session(p_app_id   => 66000,
                                                p_page_id  => 2,
                                                p_username => v_id_usrio_apex);
                  else
                    --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                    apex_session.attach(p_app_id     => 66000,
                                        p_page_id    => 2,
                                        p_session_id => v('APP_SESSION'));
                  end if;
                  
                  --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                    apex_util.set_session_state('P37_JSON'      ,'{"id_nvdad_prsna":"' || i.id_nvdad_prsna || '"}');
                    apex_util.set_session_state('F_CDGO_CLNTE'  , p_cdgo_clnte);
                    apex_util.set_session_state('P37_ID_RPRTE'  , i.id_rprte);
                  --dbms_output.put_line('llego generar blob');
                 
                 --GENERAMOS EL DOCUMENTO
                 for e in 1..3 loop
                    begin
                         v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                                                p_report_query_name  => i.nmbre_cnslta,
                                                                p_report_layout_name => i.nmbre_plntlla,
                                                                p_report_layout_type => i.cdgo_frmto_plntlla,
                                                                p_document_format    => i.cdgo_frmto_tpo);
                                                                   
                         if v_blob is not null and dbms_lob.getlength(v_blob) > 5000  then
                             o_cdgo_rspsta := 0;
                             o_mnsje_rspsta := 'Acto regenerado con exito';
                             exit;
                         else
                             o_cdgo_rspsta := 30;
                             o_mnsje_rspsta := 'No se pudo generar el documento'||' '||e;
                             pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                                                     
                             pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                             --DBMS_LOCK.SLEEP(2);
                         end if;
                    end;
                 end loop;

                  --
                  --insert into muerto(v_001,b_001)values('v_blob',v_blob);
                  begin
                       pkg_gn_generalidades.prc_ac_acto(    p_file_blob			=> v_blob,
                                                            p_id_acto			=> i.id_acto,
                                                            p_ntfccion_atmtca	=> 'N');
                  exception
                        when others then
                            o_cdgo_rspsta  := 40;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el blob';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);    
                            
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
 
                    end;
                exception
                    when others then
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo regenerar el acto';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);

                end;
                
                if(o_cdgo_rspsta = 0)then
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else 
                    rollback;
                end if;
            --end loop;

        end loop;
            
            --Se setean valores de sesion
            begin
              apex_session.attach(p_app_id     => 66000,
                                  p_page_id    => 100,
                                  p_session_id => v('APP_SESSION'));
            exception
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
            end;
        
    END prc_rgnra_acto_nvdad;
    
    ---------------------------------------------------
    -- Genera los blobs para los actos de la determinación 
    --------------------------------------------------
   /* procedure prc_rgnra_acto_dtrmncion( p_nmro_acto        	in varchar2,
                                                  p_cdgo_clnte 		    in number,
                                                  p_id_acto_tpo         in number,
                                                  p_fcha_incio          in date default null,
                                                  p_fcha_fin            in date default null,
                                                  p_id_usrio            in number,
                                                  o_cdgo_rspsta 		out number,
                                                  o_mnsje_rspsta 		out varchar2
                                                )
    as
    v_nl                     number;
	v_nmbre_up               varchar2(100) := 'pkg_gn_regenerar_actos.prc_rdstrbccion_tpo_acto_dtrmncion';
    v_dcmnto                 clob;
    v_xml                    clob;
    v_id_usrio_apex          number;
    v_blob                   blob;
    v_json_prmtros           clob;
    v_id_acto                number;
    v_id_dcmnto              number;
    v_fcha                   date;
    --v_file_blob            blob;
    v_nmbre_cnslta           varchar2(100);
    v_nmbre_plntlla          varchar2(100);
    v_cdgo_frmto_plntlla     varchar2(5);
    v_cdgo_frmto_tpo         varchar2(5);
    v_id_rprte               number;
    v_id_plntlla             number;
    v_existe                 number;
    begin
        
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'Acto regenerado con exito';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        --
      
        --se recoren los registros, se puede ejecutar puntual, entre rango de fecha y por tipo, el parametro tipo es obigatorio
        for i in (  select distinct                   
                        a.id_acto id_acto           , a.id_dcmnto id_dcmnto                  , a.fcha fcha                  ,a.anio anio                              ,
                        a.id_orgen id_orgen         , a.nmro_acto nmro_acto                  ,b.nmbre_plntlla nmbre_plntlla ,b.cdgo_frmto_plntlla cdgo_frmto_plntlla  ,
                        b.nmbre_cnslta nmbre_cnslta , b.cdgo_frmto_tpo cdgo_frmto_tpo        ,b.id_rprte id_rprte           ,c.id_plntlla id_plntlla                  ,
                        c.id_acto_tpo id_acto_tpo   , d.id_dtrmncion_lte id_dtrmncion_lte
                    from v_gn_g_actos                a
                    --join gn_d_plantillas             c on c.id_acto_tpo  = a.id_acto_tpo
                    --join gn_d_reportes               b on b.id_rprte     = c.id_rprte
                    join v_gi_g_determinaciones      d on d.id_acto      = a.id_acto 
                    where(a.nmro_acto   = :p_nmro_acto  or :p_nmro_acto is null)
                      and a.id_acto_tpo = :p_id_acto_tpo
                      and a.cdgo_acto_orgen = 'DTM'
                      and(trunc(a.fcha) between to_date(:p_fcha_incio,'dd/mm/yy') and  to_date(:p_fcha_fin,'dd/mm/yy') or :p_fcha_incio is null or :p_fcha_fin is null)
                      and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                      --and rownum < 10;
            )loop 
                 
                -- limpiamos la traza de error para documentos del lote
                delete  from gi_g_determinaciones_error  
                where   id_dtrmncion_lte = i.id_dtrmncion_lte 
                and     cdgo_dtrmncion_error_tip = 'DCM'; 
                
                
                  --se valida si el id_documento existe en la tabla gd_g_documentos
                begin
                   Select id_dcmnto
                   into v_id_dcmnto
                   from gd_g_documentos 
                   where id_dcmnto = i.id_dcmnto;
                 exception
                   when others then
                       update gn_g_actos 
                       set id_dcmnto = null,indcdor_ntfccion = 'N'
                       where id_acto       = i.id_acto
                         and id_acto_tpo   = i.id_acto_tpo ;
                         --commit;
                End;
                
                --validamos que exista HTML
                begin
                    select dcmnto_html
                    into v_dcmnto
                    from si_g_novedades_persona
                    where cdgo_clnte = p_cdgo_clnte
                      and id_nvdad_prsna = i.id_nvdad_prsna;
                end;
                --se genera el documento
                if(v_dcmnto is null) then
                    begin
                          v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_nvdad_prsna":"' ||i.id_nvdad_prsna || '"}',
                                                                         i.id_plntlla
                                                                        );    
                    exception
                        when others then
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := ' No se pudo generar el documento';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                        
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    
                    end;
                end if;
                
                
            
                begin
                  --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
                  if v('APP_SESSION') is null then
                    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                       p_cdgo_dfncion_clnte        => 'USR');
            
                    apex_session.create_session(p_app_id   => 66000,
                                                p_page_id  => 2,
                                                p_username => v_id_usrio_apex);
                  else
                    --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
                    apex_session.attach(p_app_id     => 66000,
                                        p_page_id    => 2,
                                        p_session_id => v('APP_SESSION'));
                  end if;
                  
                  --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
                    apex_util.set_session_state('P37_JSON'      ,'{"id_nvdad_prsna":"' || i.id_nvdad_prsna || '"}');
                    apex_util.set_session_state('F_CDGO_CLNTE'  , p_cdgo_clnte);
                    apex_util.set_session_state('P37_ID_RPRTE'  , i.id_rprte);
                  --dbms_output.put_line('llego generar blob');
                 
                 
                 --GENERAMOS EL DOCUMENTO
                  begin
                      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                                             p_report_query_name  => i.nmbre_cnslta,
                                                             p_report_layout_name => i.nmbre_plntlla,
                                                             p_report_layout_type => i.cdgo_frmto_plntlla,
                                                             p_document_format    => i.cdgo_frmto_tpo);
                                                             
                  exception
                    when others then
                            o_cdgo_rspsta  := 30;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo generar el blob';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);                         
                            
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                  end;
                  --
                  insert into muerto(v_001,b_001)values('v_blob',v_blob);
                  begin
                       pkg_gn_generalidades.prc_ac_acto(    p_file_blob			=> v_blob,
                                                            p_id_acto			=> i.id_acto,
                                                            p_ntfccion_atmtca	=> 'N');
                  exception
                        when others then
                            o_cdgo_rspsta  := 40;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo actualizar el blob';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);    
                            
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
 
                    end;
                exception
                    when others then
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := o_cdgo_rspsta ||' No se pudo regenerar el acto';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);      
                            pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);

                end;
                
                if(o_cdgo_rspsta = 0)then
                    pkg_gn_regenerar_actos.prc_rg_rgnra_acto(p_cdgo_clnte,i.id_acto,i.nmro_acto,i.fcha,i.id_acto_tpo,i.anio,i.id_dcmnto,sysdate,p_id_usrio,o_cdgo_rspsta,o_mnsje_rspsta);
                    commit;
                else 
                    rollback;
                end if;
        end loop;
            
        --Se setean valores de sesion
        begin
          apex_session.attach(p_app_id     => 66000,
                              p_page_id    => 100,
                              p_session_id => v('APP_SESSION'));
        exception
          when others then
            o_cdgo_rspsta  := 60;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||'Problemas al crear la sesion de la pagina de destino ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
        end;  
                
    end prc_rgnra_acto_dtrmncion;*/
    
    -----------------------------------------------------------------
    --proceso para ejecutar las up dependiendo el codigo del acto origen
    ------------------------------------------------------------------
    procedure prc_rdstrbccion_tpo_acto(   p_nmro_acto        	in  varchar2,
                                          p_cdgo_clnte 		    in  number,
                                          p_id_acto_tpo         in  number,
                                          p_fcha_incio          in  date default null,
                                          p_fcha_fin            in  date default null,
                                          p_id_usrio            in  number,
                                          p_cdgo_acto_origen    in  varchar2,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2
                                       ) AS
    v_nmro_acto       	varchar2(100)   := p_nmro_acto;
	v_cdgo_clnte 	 	number          := p_cdgo_clnte;
	v_id_acto_tpo      	number          := p_id_acto_tpo;
	v_fcha_incio       	date            := p_fcha_incio;
	v_fcha_fin         	date            := p_fcha_fin; 
	v_id_usrio          number          := p_id_usrio;
	v_cdgo_acto_origen  varchar2(200)   := p_cdgo_acto_origen;
	v_mnsje_rspsta 		varchar2(500);
	v_cdgo_rspsta      	number;
    v_nl                number;
	v_nmbre_up          varchar2(100)   := 'pkg_gn_regenerar_actos.prc_rdstrbccion_tpo_acto';
    v_json_parametros   clob;
    begin
        insert into muerto(v_001,t_001)values('inicia regeneración',sysdate);
         
        If(v_fcha_incio is null)then
            v_fcha_incio :='01/01/'|| extract(year from sysdate);             
        end if;
        
        if(v_fcha_fin is null)then
            v_fcha_fin := '31/12/'|| extract(year from sysdate);          
        end if;
        
        /*insert into muerto(v_001,n_001)values('v_nmro_acto',v_nmro_acto); 
        insert into muerto(v_001,n_001)values('v_id_acto_tpo',v_id_acto_tpo); 
        insert into muerto(v_001,v_002)values('v_cdgo_acto_origen',v_cdgo_acto_origen);
        insert into muerto(v_001,t_001)values('v_fcha_incio',to_date(v_fcha_incio,'dd/mm/yy')); 
        insert into muerto(v_001,t_001)values('v_fcha_fin',to_date(v_fcha_fin,'dd/mm/yy')); 
        insert into muerto(v_001,n_001)values('v_nmro_acto',v_nmro_acto); commit;*/
        
        for i in (  select distinct  a.id_dcmnto id_dcmnto , a.fcha fcha  ,a.anio anio ,a.id_orgen id_orgen  , a.nmro_acto nmro_acto                  
                    from v_gn_g_actos a 
                    where (a.nmro_acto       = v_nmro_acto  or v_nmro_acto is null)
                      and  a.id_acto_tpo     = v_id_acto_tpo
                      and  a.cdgo_acto_orgen = v_cdgo_acto_origen
                      and(trunc(a.fcha) between to_date(v_fcha_incio,'dd/mm/yy') and  to_date(v_fcha_fin,'dd/mm/yy'))-- or v_fcha_incio is null or v_fcha_fin is null)
                      and ((a.file_blob is null or dbms_lob.getlength(a.file_blob) <= 5000) or (a.file_bfile is null and dbms_lob.getlength(a.file_bfile) <= 5000))
                      and (select count(id_acto) from gn_g_regenerar_actos_traza where id_acto = a.id_acto) < 4
                )
                      
        loop
           
            If(v_cdgo_acto_origen = 'FISCA')then
            
                pkg_gn_regenerar_actos.prc_rgnra_acto_fsclzcion(    p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                );
            ELSIF(v_cdgo_acto_origen = 'GCB')THEN
              
                  pkg_gn_regenerar_actos.prc_rgnra_acto_jrdco  (	p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                );
            ELSIF(v_cdgo_acto_origen = 'CNV')THEN
              
                  pkg_gn_regenerar_actos.prc_rgnra_acto_cnvnio (	p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                );
                                                                
            ELSIF(v_cdgo_acto_origen = 'PRS')THEN
              
                  pkg_gn_regenerar_actos.prc_rgnra_acto_prscrpcion(	p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                );                                                            
            ELSIF(v_cdgo_acto_origen = 'MCT')THEN
                                  
                  pkg_gn_regenerar_actos.prc_rgnra_acto_embrgo (	p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                );
            
            ELSIF(v_cdgo_acto_origen = 'NPR')THEN
              
                  pkg_gn_regenerar_actos.prc_rgnra_acto_nvdad   (	p_nmro_acto         => v_nmro_acto,
                                                                    p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                                    p_fcha_incio        => v_fcha_incio,
                                                                    p_fcha_fin          => v_fcha_fin,
                                                                    p_id_usrio          => v_id_usrio,
                                                                    o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta      => v_mnsje_rspsta
                                                                ); 
            END IF;
            
        end loop;
        
        if(v_nmro_acto is null) then
           
           -- Consultamos los envíos programados
            BEGIN
                SELECT json_object(
                   key 'p_id_usuario' VALUE v_id_usrio
                ) INTO v_json_parametros FROM dual;
                
                pkg_ma_envios.prc_co_envio_programado(  p_cdgo_clnte => v_cdgo_clnte, 
                                                        p_idntfcdor => 'RGNRA_ACTOS', 
                                                        p_json_prmtros => v_json_parametros
                                                     );                                                 
                
            EXCEPTION
                WHEN OTHERS THEN
                    o_cdgo_rspsta := 40;
                    o_mnsje_rspsta := ' Error en los envios programados, ';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta || ',' || sqlerrm,6);
    
            END; 
            -- Fin Consultamos los envios programados
        end if;
        
        insert into muerto(v_001,t_001)values('hora final regeneración',sysdate);commit;
        o_cdgo_rspsta  := v_cdgo_rspsta;
        o_mnsje_rspsta := v_mnsje_rspsta;
        
    end prc_rdstrbccion_tpo_acto;
    
END PKG_GN_REGENERAR_ACTOS;

/
