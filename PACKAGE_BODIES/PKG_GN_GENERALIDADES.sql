--------------------------------------------------------
--  DDL for Package Body PKG_GN_GENERALIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GN_GENERALIDADES" as

  function fnc_cl_consecutivo(p_cdgo_clnte number, p_cdgo_cnsctvo varchar2)
    return number is
    pragma autonomous_transaction;
    -- !! ----------------------------------- !! -- 
    -- !! Funcion para generar un consecutivo !! --
    -- !! --.-------------------------------- !! -- 
    v_vlor_cnsctvo number;
  
    cursor v_cnsctvo is
      select vlor
        from df_c_consecutivos
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_cnsctvo = p_cdgo_cnsctvo
         for update of vlor;
  begin
  
    for c_cnsctvo in v_cnsctvo loop
      v_vlor_cnsctvo := (c_cnsctvo.vlor + 1);
    
      update df_c_consecutivos
         set vlor = v_vlor_cnsctvo
       where current of v_cnsctvo;
    end loop;
  
    commit;
    return v_vlor_cnsctvo;
  
  exception
    when others then
      rollback;
      return null;
  end fnc_cl_consecutivo;

  function fnc_cl_defniciones_cliente(p_cdgo_clnte                number,
                                      p_cdgo_dfncion_clnte_ctgria varchar2,
                                      p_cdgo_dfncion_clnte        varchar2)
    return varchar2 is
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion que retornar el valor de un definicio de cliente !! --
    -- !! --.----------------------------------------------------- !! -- 
  
    v_mnsje varchar2(4000);
  
    v_vlor_dfncion df_c_definiciones_cliente.vlor%type;
  
  begin
  
    begin
      select vlor
        into v_vlor_dfncion
        from v_df_c_definiciones_cliente
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_dfncion_clnte_ctgria = p_cdgo_dfncion_clnte_ctgria
         and cdgo_dfncion_clnte = p_cdgo_dfncion_clnte;
    
    exception
      when no_data_found then
        v_vlor_dfncion := -1;
        v_mnsje        := 'Excepcion no existe valor para la definicion ' ||
                          p_cdgo_dfncion_clnte;
      
    end;
  
    return v_vlor_dfncion;
  end fnc_cl_defniciones_cliente;

  function fnc_vl_fcha_vncmnto_tsas_mra(p_cdgo_clnte   number,
                                        p_id_impsto    number,
                                        p_fcha_vncmnto date) return varchar2 is
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion para validar si una fecha esta dentro de la 
    -- !! parametrizacion de tasas mora               !! --
    -- !! --.----------------------------------------------------- !! -- 
  
    v_mnsje varchar2(4000);
  
    v_fcha_vlda varchar2(1);
  
  begin
  
    begin
      select 'S'
        into v_fcha_vlda
        from df_i_tasas_mora
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and p_fcha_vncmnto between fcha_dsde and fcha_hsta;
    exception
      when no_data_found then
        v_fcha_vlda := 'N';
    end;
    return v_fcha_vlda;
  end fnc_vl_fcha_vncmnto_tsas_mra;

  function fnc_cl_id_acto_tpo(p_cdgo_clnte    number,
                              p_cdgo_acto_tpo varchar2) return number is
  
    -- !! ---------------------------------------------------------- !! -- 
    -- !! Funcion que retornar un id del tipo de acto de un cliente  !! --
    -- !! --.------------------------------------------------------- !! --   
    v_id_acto_tpo gn_d_actos_tipo.id_acto_tpo%type;
  
  begin
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = p_cdgo_acto_tpo;
    exception
      when others then
        v_id_acto_tpo := null;
    end;
  
    return v_id_acto_tpo;
  end;

  function fnc_cl_json_acto(p_cdgo_clnte          number,
                            p_cdgo_acto_orgen     varchar2,
                            p_id_orgen            number,
                            p_id_undad_prdctra    number,
                            p_id_acto_tpo         number,
                            p_acto_vlor_ttal      number,
                            p_cdgo_cnsctvo        varchar2,
                            p_id_acto_rqrdo_hjo   number default null,
                            p_id_acto_rqrdo_pdre  number default null,
                            p_fcha_incio_ntfccion varchar2 default null,
                            p_id_usrio            number,
                            p_slct_sjto_impsto    in clob default null,
                            p_slct_vgncias        in clob default null,
                            p_slct_rspnsble       in clob default null)
    return clob is
  
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion que retornar un json con los datos de un acto     !! --
    -- !! --.----------------------------------------------------- !! -- 
  
    v_sql_sjto_impsto    clob;
    v_sql_vgncias        clob;
    v_sql_sjto_rspnsble  clob;
    v_json_sjto_impsto   clob;
    v_json_vgncias       clob;
    v_json_sjto_rspnsble clob;
    v_json               json_object_t := json_object_t();
    ecode                number;

  begin
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gn_generalidades.fnc_cl_json_acto', 6, ' Entro a fnc_cl_json_acto - '||systimestamp, 6);
      
    v_json.put('CDGO_ACTO_ORGEN', p_cdgo_acto_orgen);
    v_json.put('ID_ORGEN', p_id_orgen);
    v_json.put('ID_UNDAD_PRDCTRA', p_id_undad_prdctra);
    v_json.put('ID_ACTO_TPO', p_id_acto_tpo);
    v_json.put('ACTO_VLOR_TTAL', p_acto_vlor_ttal);
    v_json.put('CDGO_CNSCTVO', p_cdgo_cnsctvo);
    v_json.put('ID_USRIO', p_id_usrio);
    v_json.put('ID_ACTO_RQRDO_HJO', p_id_acto_rqrdo_hjo);
    v_json.put('ID_ACTO_RQRDO_PDRE', p_id_acto_rqrdo_pdre);
    v_json.put('FCHA_INCIO_NTFCCION', p_fcha_incio_ntfccion);
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gn_generalidades.fnc_cl_json_acto', 6, 'llenando json antes de las select - '||systimestamp, 6);
  
    if p_slct_sjto_impsto is not null then
      v_sql_sjto_impsto := 'select json_arrayagg( json_object( ''ID_IMPSTO_SBMPSTO'' value id_impsto_sbmpsto, 
                                                                        ''ID_SJTO_IMPSTO''    value id_sjto_impsto ) returning clob ) from (' ||
                           p_slct_sjto_impsto || ')';
      execute immediate v_sql_sjto_impsto
        into v_json_sjto_impsto;
      v_json.put('SJTOS_IMPSTO', json_array_t(v_json_sjto_impsto));
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gn_generalidades.fnc_cl_json_acto', 6, ' ejecuto select de sujeto impuesto - '||v_json_sjto_impsto||' ---- '||systimestamp, 6);
  
    if p_slct_vgncias is not null then
      v_sql_vgncias := 'select json_arrayagg( json_object( ''ID_SJTO_IMPSTO'' value id_sjto_impsto, 
                                                                 ''VGNCIA''         value vgncia,
                                                                 ''ID_PRDO''        value id_prdo,
                                                                 ''VLOR_CPTAL''     value vlor_cptal,
                                                                 ''VLOR_INTRES''    value vlor_intres) returning clob ) from (' ||
                       p_slct_vgncias || ')';
      execute immediate v_sql_vgncias
        into v_json_vgncias;
      v_json.put('VGNCIAS', json_array_t(v_json_vgncias));
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gn_generalidades.fnc_cl_json_acto', 6, ' ejecuto select de vigencias - '||v_json_vgncias||' ---- '||systimestamp, 6);
  
    if p_slct_rspnsble is not null then
    
      begin
        v_sql_sjto_rspnsble := 'select json_arrayagg( json_object( ''IDNTFCCION''           value idntfccion, 
                                                                                   ''PRMER_NMBRE''          value prmer_nmbre,
                                                                                   ''SGNDO_NMBRE''          value sgndo_nmbre,
                                                                                   ''PRMER_APLLDO''         value prmer_aplldo,
                                                                                   ''SGNDO_APLLDO''         value sgndo_aplldo,
                                                                                   ''CDGO_IDNTFCCION_TPO''  value cdgo_idntfccion_tpo,
                                                                                   ''DRCCION_NTFCCION''     value drccion_ntfccion,
                                                                                   ''ID_PAIS_NTFCCION''     value id_pais_ntfccion,
                                                                                   ''ID_DPRTMNTO_NTFCCION'' value id_dprtmnto_ntfccion,
                                                                                   ''ID_MNCPIO_NTFCCION''   value id_mncpio_ntfccion,
                                                                                   ''EMAIL''                value email,
                                                                                   ''TLFNO''                value tlfno ) returning clob ) from (' ||
                               p_slct_rspnsble || ')';
        execute immediate v_sql_sjto_rspnsble
          into v_json_sjto_rspnsble;
        v_json.put('RSPNSBLES', json_array_t(v_json_sjto_rspnsble));
      exception
        when others then
          ecode := sqlcode;
          if ecode = 30625 then
            v_json_sjto_rspnsble := null;
          end if;
      end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gn_generalidades.fnc_cl_json_acto', 6, ' ejecuto select de responsables - '||v_json_sjto_rspnsble||' ---- '||systimestamp, 6);
  
    end if;
    return v_json.to_Clob();
  
  end fnc_cl_json_acto;

  procedure prc_rg_acto(p_cdgo_clnte   in number,
                        p_json_acto    in clob,
                        o_id_acto      out number,
                        o_cdgo_rspsta  out number,
                        o_mnsje_rspsta out varchar2) as
  
    -- !! ----------------------------------------------------------------------- !! -- 
    -- !! ----- *-*-* PROCEDMIENTO QUE REGISTRAR UN ACTO DADO UN JSON *-*-* ----- !! --
    -- !! ----------------------------------------------------------------------- !! -- 
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gn_generalidades.prc_rg_acto';
    v_error    exception;
  
    v_id_fncnrio_frma     gn_g_actos.id_fncnrio_frma%type;
    v_nmro_acto           gn_g_actos.nmro_acto%type;
    v_anio                gn_g_actos.anio%type;
    v_nmro_acto_dsplay    gn_g_actos.nmro_acto_dsplay%type;
    v_cdgo_undad_prdctora varchar2(5);
    v_cntidad_sjtos       number;
    v_cntdad_vngncias     number;
    v_cntdad_rspnsbles    number;
  
    v_cdgo_acto_orgen     gn_g_actos.cdgo_acto_orgen%type;
    v_id_orgen            gn_g_actos.id_orgen%type;
    v_id_undad_prdctra    gn_g_actos.id_undad_prdctra%type;
    v_id_acto_tpo         gn_g_actos.id_acto_tpo%type;
    v_acto_vlor_ttal      number;
    v_cdgo_cnsctvo        df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_acto_rqrdo_hjo   gn_g_actos.id_acto_rqrdo_ntfccion%type;
    v_id_acto_rqrdo_pdre  gn_g_actos.id_acto_rqrdo_ntfccion%type;
    v_fcha_incio_ntfccion date;
    v_id_usrio            gn_g_actos.id_usrio%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Inicializacion de Variables
    o_id_acto             := null;
    o_cdgo_rspsta         := 0;
    o_mnsje_rspsta        := '';
    v_fcha_incio_ntfccion := sysdate;
    v_cntidad_sjtos       := 0;
    v_cntdad_vngncias     := 0;
    v_cntdad_rspnsbles    := 0;
  
    -- Extraer a?o 
    select extract(year from systimestamp) into v_anio from dual;
    o_mnsje_rspsta := 'v_nmro_acto: ' || v_anio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    if p_json_acto is null then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'El json es nulo';
      raise v_error;
    end if;
  
    -- Se extraen los datos basicos del Acto del json 
    begin
      select json_value(p_json_acto, '$.CDGO_ACTO_ORGEN') cdgo_acto_orgen,
             json_value(p_json_acto, '$.ID_ORGEN') id_orgen,
             json_value(p_json_acto, '$.ID_UNDAD_PRDCTRA') id_undad_prdctra,
             json_value(p_json_acto, '$.ID_ACTO_TPO') id_acto_tpo,
             json_value(p_json_acto, '$.ACTO_VLOR_TTAL') acto_vlor_ttal,
             json_value(p_json_acto, '$.CDGO_CNSCTVO') cdgo_cnsctvo,
             json_value(p_json_acto, '$.ID_ACTO_RQRDO_HJO') id_acto_rqrdo_hjo,
             json_value(p_json_acto, '$.ID_ACTO_RQRDO_PDRE') id_acto_rqrdo_pdre,
             json_value(p_json_acto, '$.FCHA_INCIO_NTFCCION') fcha_incio_ntfccion,
             json_value(p_json_acto, '$.ID_USRIO') id_usrio
        into v_cdgo_acto_orgen,
             v_id_orgen,
             v_id_undad_prdctra,
             v_id_acto_tpo,
             v_acto_vlor_ttal,
             v_cdgo_cnsctvo,
             v_id_acto_rqrdo_hjo,
             v_id_acto_rqrdo_pdre,
             v_fcha_incio_ntfccion,
             v_id_usrio
        from dual;
    
      o_mnsje_rspsta := 'v_cdgo_acto_orgen: ' || v_cdgo_acto_orgen ||
                        ' v_id_orgen: ' || v_id_orgen ||
                        ' v_id_undad_prdctra: ' || v_id_undad_prdctra ||
                        ' v_id_acto_tpo: ' || v_id_acto_tpo ||
                        ' v_acto_vlor_ttal: ' || v_acto_vlor_ttal ||
                        ' v_cdgo_cnsctvo: ' || v_cdgo_cnsctvo ||
                        ' v_id_acto_rqrdo_hjo: ' || v_id_acto_rqrdo_hjo ||
                        ' v_id_acto_rqrdo_pdre: ' || v_id_acto_rqrdo_pdre ||
                        ' v_fcha_incio_ntfccion: ' || v_fcha_incio_ntfccion ||
                        ' v_id_usrio: ' || v_id_usrio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al extraer los datos del json. ' ||
                          sqlerrm;
        raise v_error;
    end;
  
    -- Asignacion de Consecutivo del acto
    v_nmro_acto    := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                              p_cdgo_cnsctvo => v_cdgo_cnsctvo);
    o_mnsje_rspsta := 'v_nmro_acto: ' || v_nmro_acto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Construccion del Consecutivo del acto display
    v_nmro_acto_dsplay := v_cdgo_undad_prdctora || '-' || v_anio || '-' ||
                          v_nmro_acto;
    o_mnsje_rspsta     := 'v_nmro_acto_dsplay: ' || v_nmro_acto_dsplay;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Se consulta el funcionario que firmara el acto
    begin
      select id_fncnrio
        into v_id_fncnrio_frma
        from gn_d_actos_funcionario_frma
       where id_acto_tpo = v_id_acto_tpo
         and actvo = 'S'
         and trunc(sysdate) between fcha_incio and fcha_fin
         and v_acto_vlor_ttal between rngo_dda_incio and rngo_dda_fin;
      o_mnsje_rspsta := 'v_id_fncnrio_frma: ' || v_id_fncnrio_frma;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' No se encontro funcionario parametrizado para firmar el acto por valor: ' ||
                          to_char(v_acto_vlor_ttal,
                                  'FM$999G999G999G999G999G999G990');
        raise v_error;
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al consultar el funcionario para firmar el acto ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta el funcionario que firmara el acto
  
    -- Se registra el acto
    begin
      insert into gn_g_actos
        (cdgo_clnte,
         cdgo_acto_orgen,
         id_orgen,
         id_undad_prdctra,
         id_acto_tpo,
         nmro_acto,
         anio,
         nmro_acto_dsplay,
         fcha,
         id_usrio,
         id_fncnrio_frma,
         id_acto_rqrdo_ntfccion,
         fcha_incio_ntfccion,
         vlor)
      values
        (p_cdgo_clnte,
         v_cdgo_acto_orgen,
         v_id_orgen,
         v_id_undad_prdctra,
         v_id_acto_tpo,
         v_nmro_acto,
         v_anio,
         v_nmro_acto_dsplay,
         systimestamp,
         v_id_usrio,
         v_id_fncnrio_frma,
         v_id_acto_rqrdo_pdre,
         v_fcha_incio_ntfccion,
         v_acto_vlor_ttal)
      returning id_acto into o_id_acto;
      o_cdgo_rspsta := 0;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al insertar el acto: ' || sqlerrm;
        raise v_error;
    end;
  
    -- Se valida si tiene actos hijos
    if v_id_acto_rqrdo_hjo is not null then
      for c_actos_hjo in (select id_acto
                            from gn_g_actos
                           where id_acto = v_id_acto_rqrdo_hjo) loop
        begin
          update gn_g_actos
             set id_acto_rqrdo_ntfccion = o_id_acto
           where id_acto = c_actos_hjo.id_acto;
        
          o_mnsje_rspsta := 'Se actulizaron los actos hijos del .' ||
                            o_id_acto || ' , con consecutivo No.  ' ||
                            v_nmro_acto_dsplay;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                              ' Error al actualizar los actos hijos del acto N?.' ||
                              o_id_acto || ' , con consecutivo No.  ' ||
                              v_nmro_acto_dsplay;
            raise v_error;
        end;
      end loop;
    end if;
  
    -- Se extraen los subimpuestos y los sujetos impuestos del json
    for c_sjtos_impsto in (select sjtos_impstos.*
                             from dual,
                                  json_table(p_json_acto,
                                             '$.SJTOS_IMPSTO[*]'
                                             columns(id_impsto_sbmpsto
                                                     varchar2(10) path
                                                     '$.ID_IMPSTO_SBMPSTO',
                                                     id_sjto_impsto
                                                     varchar2(20) path
                                                     '$.ID_SJTO_IMPSTO')) as sjtos_impstos
                            where sjtos_impstos.id_impsto_sbmpsto is not null
                              and sjtos_impstos.id_sjto_impsto is not null) loop
    
      -- Se registra cada sujeto impuesto del acto
      begin
        insert into gn_g_actos_sujeto_impuesto
          (id_acto, id_impsto_sbmpsto, id_sjto_impsto)
        values
          (o_id_acto,
           c_sjtos_impsto.id_impsto_sbmpsto,
           c_sjtos_impsto.id_sjto_impsto);
        v_cntidad_sjtos := v_cntidad_sjtos + 1;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' Error al insertar el o los sujetos impuestos del acto: ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Se registra cada sujeto impuesto del acto
    end loop; -- Fin Se extraen los subimpuestos y los sujetos impuestos del json
  
    --Se extraen las vigencias y periodos de los sujestos impuestos del json
    for c_vgncias in (select vgncias.*
                        from dual,
                             json_table(p_json_acto,
                                        '$.VGNCIAS[*]'
                                        columns(id_sjto_impsto varchar2(50) path
                                                '$.ID_SJTO_IMPSTO',
                                                vgncia varchar2(50) path
                                                '$.VGNCIA',
                                                id_prdo varchar2(50) path
                                                '$.ID_PRDO',
                                                vlor_cptal varchar2(50) path
                                                '$.VLOR_CPTAL',
                                                vlor_intres varchar2(50) path
                                                '$.VLOR_INTRES')) as vgncias
                       where vgncias.id_sjto_impsto is not null
                         and vgncias.vgncia is not null
                         and vgncias.id_prdo is not null
                         and vgncias.vlor_cptal is not null
                         and vgncias.vlor_intres is not null) loop
      -- Se registra cada vigencia de los sujetos impuestos del acto
      begin
        insert into gn_g_actos_vigencia
          (id_acto,
           id_sjto_impsto,
           vgncia,
           id_prdo,
           vlor_cptal,
           vlor_intres)
        values
          (o_id_acto,
           c_vgncias.id_sjto_impsto,
           c_vgncias.vgncia,
           c_vgncias.id_prdo,
           c_vgncias.vlor_cptal,
           c_vgncias.vlor_cptal);
        v_cntdad_vngncias := v_cntdad_vngncias + 1;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' Error al insertar las vigencias y periodos del acto: ' ||
                            sqlerrm;
          raise v_error;
        
      end; -- Fin Se registra cada vigencia de los sujetos impuestos del acto
    end loop; -- Fin Se extraen las vigencias y periodos de los sujestos impuestos del json
  
    -- Se extraen los responsables del acto
    for c_sjtos_rspnsble in (select rspnsbles.*
                               from dual,
                                    json_table(p_json_acto,
                                               '$.RSPNSBLES[*]'
                                               columns(idntfccion
                                                       varchar2(100) path
                                                       '$.IDNTFCCION',
                                                       prmer_nmbre
                                                       varchar2(100) path
                                                       '$.PRMER_NMBRE',
                                                       sgndo_nmbre
                                                       varchar2(100) path
                                                       '$.SGNDO_NMBRE',
                                                       prmer_aplldo
                                                       varchar2(100) path
                                                       '$.PRMER_APLLDO',
                                                       sgndo_aplldo
                                                       varchar2(100) path
                                                       '$.SGNDO_APLLDO',
                                                       cdgo_idntfccion_tpo
                                                       varchar2(100) path
                                                       '$.CDGO_IDNTFCCION_TPO',
                                                       drccion_ntfccion
                                                       varchar2(100) path
                                                       '$.DRCCION_NTFCCION',
                                                       id_pais_ntfccion
                                                       varchar2(100) path
                                                       '$.ID_PAIS_NTFCCION',
                                                       id_dprtmnto_ntfccion
                                                       varchar2(100) path
                                                       '$.ID_DPRTMNTO_NTFCCION',
                                                       id_mncpio_ntfccion
                                                       varchar2(100) path
                                                       '$.ID_MNCPIO_NTFCCION',
                                                       email varchar2(100) path
                                                       '$.EMAIL',
                                                       tlfno varchar2(100) path
                                                       '$.TLFNO')) as rspnsbles
                              where rspnsbles.idntfccion is not null) loop
      -- Se registran los responsable
      begin
        insert into gn_g_actos_responsable
          (id_acto,
           cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           drccion_ntfccion,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           email,
           tlfno)
        values
          (o_id_acto,
           c_sjtos_rspnsble.cdgo_idntfccion_tpo,
           c_sjtos_rspnsble.idntfccion,
           c_sjtos_rspnsble.prmer_nmbre,
           c_sjtos_rspnsble.sgndo_nmbre,
           c_sjtos_rspnsble.prmer_aplldo,
           c_sjtos_rspnsble.sgndo_aplldo,
           c_sjtos_rspnsble.drccion_ntfccion,
           c_sjtos_rspnsble.id_pais_ntfccion,
           c_sjtos_rspnsble.id_dprtmnto_ntfccion,
           c_sjtos_rspnsble.id_mncpio_ntfccion,
           c_sjtos_rspnsble.email,
           c_sjtos_rspnsble.tlfno);
        v_cntdad_rspnsbles := v_cntdad_rspnsbles + 1;
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' Error al insertar el los responsable del sujeto impuesto del acto: ' ||
                            sqlerrm;
          raise v_error;
        
      end; -- Fin Se registran los responsable
    end loop; -- Fin Se extraen los responsables del acto
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := 'Se creo el acto N?.' || o_id_acto ||
                        ' , con consecutivo No.  ' || v_nmro_acto_dsplay;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      return;
    end if;
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      return;
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta || ' Error: ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      return;
  end;

  procedure prc_ac_acto(p_id_acto         in gn_g_actos.id_acto%type,
                        p_ntfccion_atmtca gn_d_actos_tipo_tarea.ntfccion_atmtca%type,
                        p_file_blob       in blob default null,
                        p_directory       in varchar2 default null,
                        p_file_name_dsco  in varchar2 default null) as
    --!-----------------------------------------------------------------------!--
    --!    PROCEDIMIENTO PARA ACTUALIZAR EL DOCUMENTO GENERADO PARA EL ACTO   !--
    --!-----------------------------------------------------------------------!--
  
    v_mnsje                  varchar2(4000);
    v_id_dcmnto_tpo          number;
    v_id_trd_srie_dcmnto_tpo number;
    v_file_mimetype          varchar2(4000);
    v_file_name              varchar2(4000);
    v_id_usrio               number;
    v_id_dcmnto              number;
    v_cdgo_clnte             number;
    v_cdgo_rspsta            number;
    v_mnsje_rspsta           varchar2(4000);
    v_nl                     number;
    v_nmbre_up               varchar2(70) := 'pkg_gn_generalidades.prc_ac_acto';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(23001, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    /*
    begin
    
            update gn_g_actos
         set --file_blob        = p_file_blob,
           fcha_incio_ntfccion  = case when fcha_incio_ntfccion is null and p_ntfccion_atmtca = 'S'
                          then sysdate
                        else fcha_incio_ntfccion end
           --file_mimetype    = 'application/pdf',
           --file_name        = nmro_acto_dsplay || '.pdf'
       where id_acto          = p_id_acto
         and indcdor_ntfccion   = 'N';
    
    exception
      when others then
        v_mnsje := 'Error al Actualizar el Acto. No se Pudo Realizar el Proceso'|| SQLERRM;
                raise_application_error( -20001 , v_mnsje );
    end;
        */
    --BUSCAMOS LA TRD PARA EL TIPO DE ACTO
    begin
    
      begin
        select d.id_dcmnto_tpo,
               d.id_trd_srie_dcmnto_tpo,
               a.id_usrio,
               'application/pdf' file_mimetype,
               a.nmro_acto_dsplay || '.pdf' file_name,
               a.cdgo_clnte,
               a.id_dcmnto
          into v_id_dcmnto_tpo,
               v_id_trd_srie_dcmnto_tpo,
               v_id_usrio,
               v_file_mimetype,
               v_file_name,
               v_cdgo_clnte,
               v_id_dcmnto
          from gd_d_trd_serie_dcmnto_tpo d
          join gn_d_actos_tipo t
            on t.id_trd_srie_dcmnto_tpo = d.id_trd_srie_dcmnto_tpo
          join gn_g_actos a
            on a.id_acto_tpo = t.id_acto_tpo
         where a.id_acto = p_id_acto;
      exception
        when no_data_found then
          v_mnsje := 'No existe parametrizado la TRD del tipo de acto.';
          raise_application_error(-20001, v_mnsje);
      end;
    
      if p_directory is not null and p_file_name_dsco is not null then
        -- Si el archivo se debe extrael del dico
        pkg_gd_gestion_documental.prc_cd_documentos(p_id_trd_srie_dcmnto_tpo => v_id_trd_srie_dcmnto_tpo,
                                                    p_id_dcmnto_tpo          => v_id_dcmnto_tpo,
                                                    p_directory              => p_directory,
                                                    p_file_name_dsco         => p_file_name_dsco,
                                                    p_file_name              => v_file_name,
                                                    p_file_mimetype          => v_file_mimetype,
                                                    p_id_usrio               => v_id_usrio,
                                                    p_cdgo_clnte             => v_cdgo_clnte,
                                                    p_json                   => '[]',
                                                    p_accion                 => 'SAVE',
                                                    p_id_dcmnto              => v_id_dcmnto,
                                                    o_cdgo_rspsta            => v_cdgo_rspsta,
                                                    o_mnsje_rspsta           => v_mnsje_rspsta,
                                                    o_id_dcmnto              => v_id_dcmnto);
      
        v_nl := pkg_sg_log.fnc_ca_nivel_log(23001, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(23001,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '1. Entro al if - pkg_gd_gestion_documental.prc_cd_documentos: v_cdgo_rspsta - ' ||
                              v_cdgo_rspsta || ' - ' || systimestamp,
                              1);
      else
        pkg_gd_gestion_documental.prc_cd_documentos(p_id_trd_srie_dcmnto_tpo => v_id_trd_srie_dcmnto_tpo,
                                                    p_id_dcmnto_tpo          => v_id_dcmnto_tpo,
                                                    p_file_blob              => p_file_blob,
                                                    p_file_name              => v_file_name,
                                                    p_file_mimetype          => v_file_mimetype,
                                                    p_id_usrio               => v_id_usrio,
                                                    p_cdgo_clnte             => v_cdgo_clnte,
                                                    p_json                   => '[]',
                                                    p_accion                 => 'SAVE',
                                                    p_id_dcmnto              => v_id_dcmnto,
                                                    o_cdgo_rspsta            => v_cdgo_rspsta,
                                                    o_mnsje_rspsta           => v_mnsje_rspsta,
                                                    o_id_dcmnto              => v_id_dcmnto);
        v_nl := pkg_sg_log.fnc_ca_nivel_log(23001, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(23001,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '2. Entro al if - pkg_gd_gestion_documental.prc_cd_documentos: v_cdgo_rspsta - ' ||
                              v_cdgo_rspsta,
                              1);
      end if;
    
      if (v_cdgo_rspsta != 0) then
        raise_application_error(-20001, v_mnsje_rspsta);
      end if;
    
      update gn_g_actos
         set id_dcmnto           = v_id_dcmnto,
             fcha_incio_ntfccion = case
                                     when fcha_incio_ntfccion is null and
                                          p_ntfccion_atmtca = 'S' then
                                      sysdate
                                     else
                                      fcha_incio_ntfccion
                                   end
       where id_acto = p_id_acto
         and indcdor_ntfccion = 'N';
      v_nl := pkg_sg_log.fnc_ca_nivel_log(23001, null, v_nmbre_up);
      pkg_sg_log.prc_rg_log(23001,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Finalizado con exito ' || systimestamp,
                            1);
    exception
      when others then
        v_mnsje := 'Actualizar el Acto. No se pudo registrar el documento ' ||
                   sqlerrm;
        raise_application_error(-20001, v_mnsje);
    end;
  end prc_ac_acto;

  function fnc_cl_texto_codigo_barra(p_cdgo_clnte        number,
                                     p_id_impsto         number,
                                     p_id_impsto_sbmpsto number,
                                     p_nmro_dcmnto       number,
                                     p_vlor_ttal         number,
                                     p_fcha_vncmnto      date)
    return varchar2 is
    -- !! ----------------------------------------------------- !! -- 
    -- !! Funcion que calcular el texto del codigo de barras   !! --
    -- !! ----------------------------------------------------- !! --                    
  
    v_txto_cdgo_brra varchar2(100);
    v_cdgo_ean       df_i_impuestos_subimpuesto.cdgo_ean%type;
  
  begin
  
    -- 1. Se calcula el codigo EAN Del Sub-impuesto
    begin
      select cdgo_ean
        into v_cdgo_ean
        from df_i_impuestos_subimpuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and actvo = 'S';
    exception
      when no_data_found then
        return 'No se encontro Codigo EAN';
      when others then
        return 'Error al consultar el codigo EAN. Erro: ' || SQLCODE || '-- -- ' || SQLERRM;
    end;
  
    -- 2. Se arma el texto del codigo de barra 
    v_txto_cdgo_brra := '(415)' || v_cdgo_ean || '(8020)' ||
                        lpad(to_char(p_nmro_dcmnto), 10, '0') || '(3900)' ||
                        lpad(to_char(p_vlor_ttal), 10, '0') || '(96)' ||
                        to_char(p_fcha_vncmnto, 'YYYYMMDD');
  
    return v_txto_cdgo_brra;
  
  end fnc_cl_texto_codigo_barra;

  function fnc_cl_formato_texto(p_txto           varchar2,
                                p_frmto          varchar2,
                                p_crcter_dlmtdor varchar2)
  
   return varchar2 is
    -- !! ------------------------------------------------------------------------------ !! -- 
    -- !! Funcion que le aplica a un texto dado (p_txto) un formato especifico (p_frmto) !! --
    -- !! definido por un caracter delimitador  (p_crcter_dlmtdor)                       !! --
    -- !! ------------------------------------------------------------------------------ !! --   
  
    v_txto_frmto    varchar2(300);
    v_pscion_crcter number;
    i               number;
    v_txto          varchar2(300);
  
  begin
    -- 1. Inicializacion de Variables
  
    v_pscion_crcter := 1;
    i               := 1;
    v_txto          := p_txto;
  
    while v_pscion_crcter > 0 loop
      -- 2. Se busca la posicion del caracter delimitador
      v_pscion_crcter := instr(p_frmto, p_crcter_dlmtdor, 1, i);
      -- insert into gti_aux (col1, col2) values ('i-1 = ' || i, 'v_pscion_crcter = ' || v_pscion_crcter); commit;
    
      -- 3. Si se encuntra el caracter se procede a:            
      if v_pscion_crcter > 0 then
      
        -- 3.1 Concatener en la cadena de texto el caracter delimintador en la posicion que corresponde
        /*  select regexp_replace(ID,
                            '^(.{' || (v_pscion_crcter - 1) || '})',
                            '\1' || p_crcter_dlmtdor || '')
        into v_txto_frmto
        from (select v_txto id from DUAL); */
        -- insert into gti_aux (col1, col2) values ('i-2 = ' || i, 'v_txto_frmto = ' || v_txto_frmto); commit;
      
        v_txto_frmto := regexp_replace(v_txto,
                                       '^(.{' || (v_pscion_crcter - 1) || '})',
                                       '\1' || p_crcter_dlmtdor || '');
      
        -- 3.2 Se remplaza el texto 
        v_txto := v_txto_frmto;
      
        -- 3.3 Se incrementa la variable de conteo
        i := i + 1;
      end if;
    
    end loop;
  
    return v_txto_frmto;
  
  end fnc_cl_formato_texto;

  function fnc_cl_convertir_blob_a_base64(p_blob blob) return clob is
  
    -- !! -------------------------------------------- !! -- 
    -- !! Funcion combierte un blob a cadena (base 64) !! --
    -- !! -------------------------------------------- !! --   
    v_clob           clob;
    v_result         clob;
    v_offset         integer;
    v_chunk_size     binary_integer := (48 / 4) * 3;
    v_buffer_varchar varchar2(48);
    v_buffer_raw     raw(48);
  
  begin
  
    if p_blob is null then
      return null;
    end if;
    dbms_lob.createtemporary(v_clob, true);
    v_offset := 1;
  
    for i in 1 .. ceil(dbms_lob.getlength(p_blob) / v_chunk_size) loop
      dbms_lob.read(p_blob, v_chunk_size, v_offset, v_buffer_raw);
      v_buffer_raw     := utl_encode.base64_encode(v_buffer_raw);
      v_buffer_varchar := utl_raw.cast_to_varchar2(v_buffer_raw);
      dbms_lob.writeappend(v_clob,
                           length(v_buffer_varchar),
                           v_buffer_varchar);
      v_offset := v_offset + v_chunk_size;
    end loop;
  
    v_result := v_clob;
    dbms_lob.freetemporary(v_clob);
  
    return v_result;
  end fnc_cl_convertir_blob_a_base64;
  
  function fnc_cl_convertir_blob_a_clob (blob_in in blob) return clob is
        v_clob clob;
        v_varchar varchar2(32767);
        v_start pls_integer := 1;
        v_buffer pls_integer := 32767;
        v_sqlerrm varchar2(2000);
        
        v_cdgo_clnte    number := 23001;
        v_nl            number;
        v_nmbre_up      varchar2(50) := 'pkg_gn_generalidades.fnc_cl_convertir_blob_a_clob';
    begin
        -- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, v_nmbre_up );
		-- Traza
		pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Inicia ' || v_nmbre_up, 1);

        dbms_lob.createtemporary(v_clob, true);
        
        for i in 1..ceil(dbms_lob.getlength(blob_in) / v_buffer)
        loop
            v_varchar := utl_raw.cast_to_varchar2(dbms_lob.substr(blob_in, v_buffer, v_start));    
            dbms_lob.writeappend(v_clob, length(v_varchar), v_varchar);
            v_start := v_start + v_buffer;
        end loop;
        
        pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Antes de retornar CLOB', 1);
        
        return v_clob;
    exception 
        when others then
            v_sqlerrm := 'fnc_cl_convertir_blob_a_clob. ' || sqlerrm;
            pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, v_nmbre_up,  v_nl, v_sqlerrm, 1);
            raise_application_error(-20100, v_sqlerrm);
            
    end fnc_cl_convertir_blob_a_clob ;
  
  function fnc_co_bancos_recaudadores(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number)
    return varchar2 is
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna los bancos recaudadores            !! -- 
    -- !! de un subimpuesto en una cadena separados por coma "," !! --
    -- !! ------------------------------------------------------ !! --   
    v_bncos_rcddres varchar2(1000);
  
  begin
    begin
      select listagg(nmbre_bnco, ', ') within group(order by nmbre_bnco) bncos_rcddres
        into v_bncos_rcddres
        from v_df_c_bancos_impuesto_smpsto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    exception
      when others then
        v_bncos_rcddres := 'Error' || SQLCODE || ' -- ' || SQLERRM;
    end;
  
    if v_bncos_rcddres is null then
      begin
        select listagg(nmbre_bnco, ', ') within group(order by nmbre_bnco) bncos_rcddres
          into v_bncos_rcddres
          from v_df_c_bancos_impuesto
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto;
      exception
        when others then
          v_bncos_rcddres := 'Error' || SQLCODE || ' -- ' || SQLERRM;
      end;
    end if;
  
    if v_bncos_rcddres is null then
      begin
        select listagg(nmbre_bnco, ', ') within group(order by b.ordn) bncos_rcddres
          into v_bncos_rcddres
          from v_df_c_bancos b
         where cdgo_clnte = p_cdgo_clnte
           and b.rcddor = 'S';
      exception
        when no_data_found then
          v_bncos_rcddres := 'No existen bancos recaudadores.';
      end;
    end if;
  
    return v_bncos_rcddres;
  
  end fnc_co_bancos_recaudadores;

  function fnc_co_vigencias_con_saldo(p_cdgo_clnte     number,
                                      p_id_sjto_impsto number)
    return g_dtos_vgncias_sldo
    pipelined is
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna las vigencias con saldo de un      !! -- 
    -- !! sujeto impuesto en una cadena separados por coma ","   !! --
    -- !! ------------------------------------------------------ !! --   
    v_vgncias t_dtos_vgncias_sldo;
  
  begin
    begin
      select listagg(vgncia || '-' || prdo, ', ') within group(order by vgncia, prdo) vgncias,
             sum(vlor_sldo_cptal + vlor_intres) vlor_sldo_vgncias
        into v_vgncias
        from (select a.vgncia,
                     a.prdo,
                     sum(a.vlor_sldo_cptal) vlor_sldo_cptal,
                     sum(vlor_intres) vlor_intres
                from v_gf_g_cartera_x_vigencia a
               where id_sjto_impsto = p_id_sjto_impsto
                 and (vlor_sldo_cptal) > 0
               group by a.vgncia, a.prdo);
    exception
      when no_data_found then
        v_vgncias.vgncia_sldo := 'No existen vigencias con saldo';
      when others then
        v_vgncias.vgncia_sldo := 'Error' || SQLCODE || ' -- ' || SQLERRM;
    end;
  
    pipe row(v_vgncias);
  
  end fnc_co_vigencias_con_saldo;

  function fnc_co_vigencias_con_saldo(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number,
                                      p_id_sjto_impsto    number)
    return g_dtos_vgncias_sldo
    pipelined is
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna las vigencias con saldo de un      !! -- 
    -- !! sujeto impuesto en una cadena separados por coma ","   !! --
    -- !! ------------------------------------------------------ !! --   
    v_vgncias t_dtos_vgncias_sldo;
  
  begin
    begin
      select listagg(vgncia || '-' || prdo, ', ') within group(order by vgncia, prdo) vgncias,
             sum(vlor_sldo_cptal + vlor_intres) vlor_sldo_vgncias
        into v_vgncias
        from (select a.vgncia,
                     a.prdo,
                     sum(a.vlor_sldo_cptal) vlor_sldo_cptal,
                     sum(vlor_intres) vlor_intres
                from v_gf_g_cartera_x_vigencia a
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = p_id_impsto
                 and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                 and id_sjto_impsto = p_id_sjto_impsto
                 and (vlor_sldo_cptal) > 0
               group by a.vgncia, a.prdo);
    exception
      when no_data_found then
        v_vgncias.vgncia_sldo := 'No existen vigencias con saldo';
      when others then
        v_vgncias.vgncia_sldo := 'Error' || SQLCODE || ' -- ' || SQLERRM;
    end;
  
    pipe row(v_vgncias);
  
  end fnc_co_vigencias_con_saldo;

  function fnc_ca_split_table(p_cdna clob, p_crcter_dlmtdor varchar2)
    return g_split
    pipelined is
    v_cadena clob := p_cdna;
    v_split  t_split;
    v_length number := 4000;
  begin
  
    v_split.vlor := 0;
    while (instr(v_cadena, p_crcter_dlmtdor) > 0) loop
      v_split.vlor := v_split.vlor + 1;
      v_split.cdna := substr(v_cadena,
                             1,
                             instr(v_cadena, p_crcter_dlmtdor) - 1);
      v_cadena     := substr(v_cadena,
                             instr(v_cadena, p_crcter_dlmtdor) + 1);
      pipe row(v_split);
    end loop;
  
    if (length(v_cadena) <= v_length) then
      v_split.vlor := v_split.vlor + 1;
      v_split.cdna := v_cadena;
      pipe row(v_split);
    end if;
  
    /*for c_split in ( select level,
                        regexp_substr( p_cdna , '[^'||p_crcter_dlmtdor||']+', 1, level ) 
                   from dual 
                connect by level <= regexp_count( p_cdna , p_crcter_dlmtdor ) + 1 
                    and prior sys_guid() is not null 
                    )
    loop 
        pipe row(c_split);
    end loop;*/
  end fnc_ca_split_table;
  -----------------------------------

  procedure prc_cd_reportes_cliente(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                    p_json         in clob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gn_generalidades.prc_cd_reportes_cliente';
    l_start    number;
    l_end      number;
    v_action   varchar2(2);
  begin
  
    l_start       := dbms_utility.get_time;
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Extrae el valor de la action
    v_action := json_value(p_json, '$.action');
  
    for c_rprte_clnte in (select a.id_rprte
                            from json_table(p_json,
                                            '$.datas[*]'
                                            columns(id_rprte number path
                                                    '$.id_rprte')) a
                           where v_action in ('I', 'D')
                             and a.id_rprte is not null) loop
    
      if (v_action = 'D') then
        --Elimina por los reportes del cliente
        begin
          delete gn_d_reporte_cliente
           where cdgo_clnte = p_cdgo_clnte
             and id_rprte = c_rprte_clnte.id_rprte;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No fue posible eliminar los reportes asociado al cliente.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 6);
            return;
        end;
      
        o_mnsje_rspsta := 'Reporte eliminado , con consecutivo No. ' ||
                          c_rprte_clnte.id_rprte || ' y cliente ' ||
                          p_cdgo_clnte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 6);
      
      elsif (v_action = 'I') then
        --Registra los reportes del cliente
        begin
          insert into gn_d_reporte_cliente
            (id_rprte, cdgo_clnte, actvo)
          values
            (c_rprte_clnte.id_rprte, p_cdgo_clnte, 'S');
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No fue posible asignar los reportes al cliente.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 6);
            return;
        end;
      
        o_mnsje_rspsta := 'Reporte nuevo , con consecutivo No. ' ||
                          c_rprte_clnte.id_rprte || ' y cliente ' ||
                          p_cdgo_clnte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 6);
      
      end if;
    end loop;
  
    l_end := ((dbms_utility.get_time - l_start) / 100);
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up || ' tiempo: ' ||
                      l_end || ' s';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Exito';
  
  exception
    when others then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'No fue posible realizar la operacion, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta || sqlerrm,
                            p_nvel_txto  => 3);
  end prc_cd_reportes_cliente;

  /*
  * @Descripcion    : Calcula el Valor de un Nodo de un XML
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 26/10/2018
  * @Modificacion   : 26/10/2018
  */

  function fnc_ca_extract_value(p_xml  in varchar2,
                                p_nodo in varchar2,
                                p_path in varchar2 default '[1]')
    return varchar2 is
    v_xml  xmltype;
    v_vlor varchar2(4000);
  begin
  
    --Verifica si el XML es Valido
    begin
      v_xml := xmltype(p_xml);
    exception
      when others then
        v_xml := xmltype('<data>' || p_xml || '</data>');
    end;
  
    select nvl(extractValue(v_xml, '//' || p_nodo || '/@value' || p_path),
               extractValue(v_xml, '//' || p_nodo || p_path))
      into v_vlor
      from dual;
  
    return v_vlor;
  
  end fnc_ca_extract_value;

  /*
  * @Descripcion    : Genera el XML Apartir del Estandar (parametro:valor#)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 26/10/2018
  * @Modificacion   : 26/10/2018
  * @Nota           : '#' Separador de Parametros
  */

  function fnc_ge_xml_prmtro(p_cdna in varchar2) return varchar2 is
    v_xml varchar2(4000);
  begin
  
    for c_xml in (select regexp_substr(a.cdna,
                                       '[^' ||
                                       pkg_gn_generalidades.g_sprdor_v_xml_prmtro || ']+') as etqueta,
                         regexp_substr(a.cdna,
                                       '[^' ||
                                       pkg_gn_generalidades.g_sprdor_v_xml_prmtro || ']+',
                                       1,
                                       2) as vlor
                    from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_cdna,
                                                                       p_crcter_dlmtdor => pkg_gn_generalidades.g_sprdor_p_xml_prmtro)) a
                   where a.cdna is not null
                     and regexp_like(a.cdna,
                                     '^[A-Za-z0-9]+' ||
                                     pkg_gn_generalidades.g_sprdor_v_xml_prmtro ||
                                     '[A-Za-z0-9]')) loop
      v_xml := v_xml || '<' || c_xml.etqueta || '><![CDATA[' || c_xml.vlor ||
               ']]></' || c_xml.etqueta || '>';
    end loop;
  
    return '<?xml version="1.0" encoding="UTF-8"?>' || chr(10) || '<data>' || v_xml || '</data>';
  
  end fnc_ge_xml_prmtro;

  function fnc_ge_dcmnto(p_xml        in varchar2,
                         p_id_plntlla in gn_d_plantillas_consulta.id_plntlla%type)
    return clob is
    type c_cursor_type is ref cursor;
    c_cursor           c_cursor_type;
    v_to_cursor_number number;
    v_desc_table       dbms_sql.desc_tab;
    v_column_count     number;
    v_column_value     clob; --varchar2(4000); 
    v_dcmnto           clob;
  
  begin
    begin
      --CONCATENAMOS LOS PARRAFOS DE LA PLANTILLA
      begin
        for r_plantilla in (select prrfo
                              from gn_d_plantillas_parrafo
                             where id_plntlla = p_id_plntlla
                             order by orden) loop
          v_dcmnto := v_dcmnto || r_plantilla.prrfo;
        end loop;
      exception
        when others then
          v_dcmnto := null;
      end;
    
      --SI NO EXISTEN PARRAFOS, NO GENERAMOS EL DOCUMENTO
      if v_dcmnto is null then
        return '';
      end if;
    
      --BUSCAMOS TODAS LAS CONSULTAS DISPONIBLES DE LA PLANTILLA
      for c_plntllas in (select a.cnslta, a.id_plntlla_cnslta
                           from gn_d_plantillas_consulta a
                          where a.id_plntlla = p_id_plntlla) loop
      
        --ABRIMOS UN CURSOR POR CADA CONSULTA(QUERY) DE LA PLANTILLA
        c_plntllas.cnslta := replace(c_plntllas.cnslta,
                                     ':F_APP_XML',
                                     chr(39) || p_xml || chr(39));
      
        --dbms_output.put_line(c_plntllas.cnslta);
        open c_cursor for c_plntllas.cnslta; --using p_xml ;
        v_to_cursor_number := dbms_sql.to_cursor_number(c_cursor);
        dbms_sql.describe_columns(v_to_cursor_number,
                                  v_column_count,
                                  v_desc_table);
      
        for i in 1 .. v_column_count loop
          --dbms_sql.define_column(v_to_cursor_number, i, null, 4000);
          dbms_sql.define_column(v_to_cursor_number, i, v_column_value);
        end loop;
      
        while dbms_sql.fetch_rows(v_to_cursor_number) > 0 loop
          --v_column_count := case when v_column_count > 1 then 1 else v_column_count end;
          for i in 1 .. v_column_count loop
            dbms_sql.column_value(v_to_cursor_number, i, v_column_value);
            if (length(v_column_value) > 4000) then
              v_dcmnto := pkg_gn_generalidades.fnc_clob_replace(p_source  => v_dcmnto,
                                                                p_search  => '<a href="' ||
                                                                             c_plntllas.id_plntlla_cnslta ||
                                                                             '">!' || v_desc_table(i).col_name ||
                                                                             '!</a>',
                                                                p_replace => v_column_value);
            else
              v_dcmnto := replace(v_dcmnto,
                                  '<a href="' ||
                                  c_plntllas.id_plntlla_cnslta || '">!' || v_desc_table(i).col_name ||
                                  '!</a>',
                                  v_column_value);
            end if;
          
          end loop;
        end loop;
        dbms_sql.close_cursor(v_to_cursor_number);
      end loop;
    
      --dbms_output.put_line(v_dcmnto);
      return pkg_gn_generalidades.fnc_ca_variables(p_dcmnto => v_dcmnto);
      --return v_dcmnto;
    exception
      when others then
        return '' /*|| sqlerrm*/
        ;
    end;
  end fnc_ge_dcmnto;

  function fnc_ca_variables(p_dcmnto in clob) return clob is
    v_count    number;
    v_vlor     varchar2(1000);
    v_exprsion varchar2(1000);
    v_dcmnto   clob := p_dcmnto;
  
  begin
  
    begin
    
      for c_vrbles in (select nmbre, fncion from gn_d_plantillas_variable) loop
        v_exprsion := '\<a href="' || c_vrbles.nmbre || '">!' ||
                      c_vrbles.nmbre || '!<\/a>';
        --CANTIDAD DE VALORES A REEMPLAZAR EN EL TEXTO.
        v_count := regexp_count(v_dcmnto, v_exprsion, 1, 'i');
      
        --SE VALIDA QUE TENGA AL MENOS UN VALOR A REEMPLAZAR.
        if v_count > 0 then
          for i in 1 .. v_count loop
            --ANTES DE REEMPLAZAR EL VALOR SE UTLIZA LA FUNCION QUE SE ENCUENTRA EN LA TABLA PARA OBTENER EL VALOR POR EL CUAL
            -- SE REALIZARA EL REEMPLAZO Y PORQUE FORMA DE NUMERACION.
            begin
              execute immediate 'begin :S := ' || c_vrbles.fncion ||
                                '; end;'
                using out v_vlor, i;
              -- SE REEMPLAZA EN EL TEXTO LOS VALORES ENCONTRADOS POR LOS QUE NOS DEVUELVE LA FUNCION ANTERIOR.
              v_dcmnto := regexp_replace(v_dcmnto,
                                         v_exprsion,
                                         trim(v_vlor),
                                         1,
                                         1,
                                         'i');
            exception
              when others then
                null;
            end;
          end loop;
        end if;
      end loop;
    exception
      when others then
        null;
    end;
  
    return v_dcmnto;
  end fnc_ca_variables;

  function fnc_clob_replace(p_source  in clob,
                            p_search  in varchar2,
                            p_replace in clob) return clob is
    v_pos number;
  begin
    v_pos := nvl(instr(p_source, p_search), 0);
    if v_pos > 0 then
      return pkg_gn_generalidades.fnc_clob_replace(substr(p_source,
                                                          1,
                                                          v_pos - 1) ||
                                                   p_replace ||
                                                   substr(p_source,
                                                          v_pos +
                                                          length(p_search)),
                                                   p_search,
                                                   p_replace);
    end if;
    return p_source;
  end fnc_clob_replace;

  function fnc_ca_expresion(p_vlor in number, p_expresion in varchar2)
    return number is
    v_vlor      number;
    v_expresion varchar2(4000);
  begin
  
    --Elimina la Inyeccion Sql
    execute immediate 'begin :result := :1 ; end;'
      using out v_expresion, in p_expresion;
  
    execute immediate 'begin :result := ' || v_expresion || '; end;'
      using out v_vlor, in p_vlor;
  
    return v_vlor;
  
  exception
    when others then
      return p_vlor;
  end fnc_ca_expresion;

  procedure prc_rg_apex_session(p_app_id      in apex_applications.application_id%type,
                                p_app_user    in apex_workspace_activity_log.apex_user%type,
                                p_app_page_id in apex_application_pages.page_id%type default 1) as
    v_workspace_id apex_applications.workspace_id%type;
    v_cgivar_name  owa.vc_arr;
    v_cgivar_val   owa.vc_arr;
    v_mnsje        varchar2(4000);
  
  begin
  
    htp.init;
    v_cgivar_name(1) := 'REQUEST_PROTOCOL';
    v_cgivar_val(1) := 'HTTP';
    owa.init_cgi_env(num_params => 1,
                     param_name => v_cgivar_name,
                     param_val  => v_cgivar_val);
  
    begin
      select workspace_id
        into v_workspace_id
        from apex_applications
       where application_id = p_app_id;
    exception
      when no_data_found then
        v_mnsje := 'No se Encontraron Datos de la Aplicacion';
        raise_application_error(-20001, v_mnsje);
    end;
  
    wwv_flow_api.set_security_group_id(v_workspace_id);
    apex_application.g_instance     := 1;
    apex_application.g_flow_id      := p_app_id;
    apex_application.g_flow_step_id := p_app_page_id;
  
    apex_custom_auth.post_login(p_uname      => p_app_user,
                                p_session_id => null,
                                p_app_page   => apex_application.g_flow_id || ':' ||
                                                p_app_page_id);
  exception
    when others then
      v_mnsje := 'No se Pudo Iniciar Session en APEX';
      raise_application_error(-20001, v_mnsje);
  end prc_rg_apex_session;

  function fnc_ge_to_base64(t in varchar2) return varchar2 AS
  BEGIN
    return utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(t)));
  END fnc_ge_to_base64;

  function fnc_ge_from_base64(t in varchar2) return varchar2 AS
  BEGIN
    return utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(t)));
  END fnc_ge_from_base64;

  function fnc_number_to_text(v_numero in number, v_tpo in varchar2)
    return varchar2 is
  
    -- !! ----------------------------------------------------- !! -- 
    -- !! Funcion que para pasar Numeros a Letras                !! --
    -- !! ----------------------------------------------------- !! --        
  
    l             number;
    k             varchar2(1);
    p             number;
    letras        varchar2(1000);
    v_vlor_dcmal  number(4);
    v_vlor_entro  number(14);
    v_txto_cntvos varchar2(100);
    v_cntvos      number(3, 2);
    v_letras      varchar2(1200);
  
  begin
    --sitpr001('entrando al procedimientos sitpr006', p_archvo);
  
    v_vlor_entro := trunc(v_numero);
    v_vlor_dcmal := v_numero - v_vlor_entro;
    v_cntvos     := v_vlor_dcmal * 100;
    if v_tpo = 'd' then
      -- tipo de dato enviado corresponde a dinero
      if v_cntvos > 0 then
        v_txto_cntvos := 'pesos ' || to_char(v_cntvos) || ' ctvs ';
      else
        v_txto_cntvos := 'pesos ';
      end if;
    else
      -- tipo de dato enviado corresponde a numero
      if v_cntvos > 0 then
        v_txto_cntvos := ' ' || to_char(v_cntvos) || ' decimas ';
      else
        v_txto_cntvos := ' ';
      end if;
    end if;
    if v_vlor_entro is null then
      v_letras := ' ';
    else
      l      := length(ltrim(rtrim(to_char(v_vlor_entro))));
      p      := length(ltrim(rtrim(to_char(v_vlor_entro))));
      letras := '';
      loop
        if v_vlor_entro = 0 then
          letras := 'cero ';
          exit;
        end if;
        if l = 6 and letras is not null then
          if p = 7 and k = '1' then
            letras := letras || 'millon ';
          else
            letras := letras || 'millones ';
          end if;
        end if;
        if l = 3 and letras is not null then
          l := l + 1;
          k := substr(to_char(v_numero), -l, 1);
          if k = 0 then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = 0 then
              l := l + 1;
              k := substr(to_char(v_numero), -l, 1);
              if k != 0 then
                letras := letras || 'mil ';
              end if;
              l := l - 1;
              k := substr(to_char(v_numero), -l, 1);
            else
              letras := letras || 'mil ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          else
            letras := letras || 'mil ';
          end if;
          l := l - 1;
          k := substr(to_char(v_numero), -l, 1);
        end if;
        if l = 9 or l = 6 or l = 3 then
          k := substr(to_char(v_numero), -l, 1);
          if k = '1' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = 0 then
              l := l - 1;
              k := substr(to_char(v_numero), -l, 1);
              if k = 0 then
                letras := letras || 'cien ';
              else
                letras := letras || 'ciento ';
              end if;
              l := l + 1;
              k := substr(to_char(v_numero), -l, 1);
            else
              letras := letras || 'ciento ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          end if;
          if k = '2' then
            letras := letras || 'doscientos ';
          end if;
          if k = '3' then
            letras := letras || 'trecientos ';
          end if;
          if k = '4' then
            letras := letras || 'cuatrocientos ';
          end if;
          if k = '5' then
            letras := letras || 'quinientos ';
          end if;
          if k = '6' then
            letras := letras || 'seiscientos ';
          end if;
          if k = '7' then
            letras := letras || 'setecientos ';
          end if;
          if k = '8' then
            letras := letras || 'ochocientos ';
          end if;
          if k = '9' then
            letras := letras || 'novecientos ';
          end if;
        end if;
        if l = 8 or l = 5 or l = 2 then
          k := substr(to_char(v_numero), -l, 1);
          if k = '1' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'diez ';
            elsif k = '1' then
              letras := letras || 'once ';
            elsif k = '2' then
              letras := letras || 'doce ';
            elsif k = '3' then
              letras := letras || 'trece ';
            elsif k = '4' then
              letras := letras || 'catorce ';
            elsif k = '5' then
              letras := letras || 'quince ';
            else
              letras := letras || 'dieci';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '2' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'veinte ';
            else
              letras := letras || 'veinti';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '4' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'cuarenta ';
            else
              letras := letras || 'cuarenta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '3' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'treinta ';
            else
              letras := letras || 'treinta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '5' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'cincuenta ';
            else
              letras := letras || 'cincuenta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '6' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'sesenta ';
            else
              letras := letras || 'sesenta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '7' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'setenta ';
            else
              letras := letras || 'setenta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '8' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'ochenta ';
            else
              letras := letras || 'ochenta y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '9' then
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
            if k = '0' then
              letras := letras || 'noventa ';
            else
              letras := letras || 'noventa y ';
            end if;
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
          end if;
        end if;
        if l = 7 or l = 4 or l = 1 then
          k := substr(to_char(v_numero), -l, 1);
          if k = '1' and letras is not null then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if (k != '1' and k != '2') then
              letras := letras || 'un ';
            elsif k = '2' then
              letras := letras || 'un ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '1' and letras is null then
            letras := 'un ';
          elsif k = '2' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if ((k != '1' or k is null) and (k != '2' or k is null)) then
              letras := letras || 'dos ';
            elsif k = '2' then
              letras := letras || 'dos ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '3' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if ((k != '1' or k is null) and (k != '2' or k is null)) then
              letras := letras || 'tres ';
            elsif k = '2' then
              letras := letras || 'tres ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '4' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if ((k != '1' or k is null) and (k != '2' or k is null)) then
              letras := letras || 'cuatro ';
            elsif k = '2' then
              letras := letras || 'cuatro ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '5' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if ((k != '1' or k is null) and (k != '2' or k is null)) then
              letras := letras || 'cinco ';
            elsif k = '2' then
              letras := letras || 'cinco ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '6' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if k != '2' then
              letras := letras || 'seis ';
            else
              letras := letras || 'seis ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '7' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if k != '2' then
              letras := letras || 'siete ';
            else
              letras := letras || 'siete ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '8' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if k != '2' then
              letras := letras || 'ocho ';
            else
              letras := letras || 'ocho ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          elsif k = '9' then
            l := l + 1;
            k := substr(to_char(v_numero), -l, 1);
            if k != '2' then
              letras := letras || 'nueve ';
            else
              letras := letras || 'nueve ';
            end if;
            l := l - 1;
            k := substr(to_char(v_numero), -l, 1);
          end if;
        end if;
        l := l - 1;
        if l = 0 then
          exit;
        end if;
      end loop;
      v_letras := letras || v_txto_cntvos;
    end if;
  
    return v_letras;
  
  end;

  function fnc_date_to_text(p_fcha date) return varchar2 as
    v_fcha_txto varchar2(2000);
  begin
    v_fcha_txto := trim(to_char(p_fcha,
                                'MONTH',
                                'nls_date_language=spanish')) || ' ' ||
                   to_char(to_char(p_fcha, 'dd'), '00') || ' de ' ||
                   to_char(p_fcha, 'yyyy');
  
    return v_fcha_txto;
  end fnc_date_to_text;

  procedure prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion in clob,
                                  p_xml                        in varchar2,
                                  o_indcdor_vldccion           out varchar2,
                                  o_rspstas                    out pkg_gn_generalidades.g_rspstas)
  
   as
  
    type t_funciones is record(
      id_rgla_ngcio_clnte_fncion gn_d_rglas_ngcio_clnte_fnc.id_rgla_ngcio_clnte_fncion%type,
      orden_agrpcion             gn_d_rglas_ngcio_clnte_fnc.orden_agrpcion%type,
      cmprta_lgca                gn_d_rglas_ngcio_clnte_fnc.cmprta_lgca%type,
      indcdor_cmple_vldccion     gn_d_rglas_ngcio_clnte_fnc.indcdor_cmple_vldccion%type,
      rspsta_pstva               gn_d_rglas_ngcio_clnte_fnc.rspsta_pstva%type,
      rspsta_ngtva               gn_d_rglas_ngcio_clnte_fnc.rspsta_ngtva%type,
      dscrpcion                  gn_d_funciones.dscrpcion%type,
      nmbre_up                   gn_d_funciones.nmbre_up%type);
      v_nl                       number;
      v_nmbre_up                    varchar2(100);
    type g_funciones is table of t_funciones;
  
    v_funciones g_funciones;
    v_where     varchar2(2000);
  begin
  
         pkg_sg_log.prc_rg_log( 23001, null, v_nmbre_up,  v_nl, 'ALC Entrando a reglas de negocio  - ' , 1);
        pkg_sg_log.prc_rg_log( 23001, null, v_nmbre_up,  v_nl, 'ALC v_id_rgl_ngco_clnt_fncn  - ',1);
 
  
    o_rspstas := pkg_gn_generalidades.g_rspstas();
  
    --Llena la coleccion de reglas de negocio cliente
    select a.id_rgla_ngcio_clnte_fncion,
           a.orden_agrpcion,
           a.cmprta_lgca,
           a.indcdor_cmple_vldccion,
           a.rspsta_pstva,
           a.rspsta_ngtva,
           b.dscrpcion,
           b.nmbre_up
      bulk collect
      into v_funciones
      from gn_d_rglas_ngcio_clnte_fnc a
      join gn_d_funciones b
        on a.id_fncion = b.id_fncion
     where a.id_rgla_ngcio_clnte_fncion in
           (select cdna
              from (table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_id_rgla_ngcio_clnte_fncion,
                                                                  p_crcter_dlmtdor => ','))))
       and a.actvo = 'S'
     order by a.orden, a.orden_agrpcion, a.cmprta_lgca;
  
    for i in 1 .. v_funciones.count loop
    
      o_rspstas.extend;
    
      --Ejecuta la funcion de validacion
      begin
      
        pkg_sg_log.prc_rg_log( 23001, null, v_nmbre_up,  v_nl, 'ALC Entrando a reglas de negocio  - ' , 1);
        pkg_sg_log.prc_rg_log( 23001, null, v_nmbre_up,  v_nl, 'ALC Execute inmediate  - '|| 'begin :result := ' || v_funciones(i).nmbre_up ||
                          '( p_xml  => :p_xml); end;',1);
      
        execute immediate 'begin :result := ' || v_funciones(i).nmbre_up ||
                          '( p_xml  => :p_xml); end;'
          using out o_indcdor_vldccion, in p_xml;
      exception
        when others then
          o_rspstas(i).mnsje := 'No fue posible ejecutar la funcion: ' || v_funciones(i).nmbre_up ||
                                '( p_xml  => ' || chr(39) || p_xml ||
                                chr(39) || ') de la regla #' || v_funciones(i).id_rgla_ngcio_clnte_fncion;
          raise_application_error(-20009, o_rspstas(i).mnsje);
      end;
    
      if (o_indcdor_vldccion = v_funciones(i).indcdor_cmple_vldccion) then
        o_indcdor_vldccion := 'S';
        o_rspstas(i).mnsje := v_funciones(i).rspsta_pstva;
      else
        o_rspstas(i).mnsje := v_funciones(i).rspsta_ngtva;
        o_indcdor_vldccion := 'N';
      end if;
    
      --Construcion del where 
      v_where := v_where || chr(39) || o_indcdor_vldccion || chr(39) || ' = ' ||
                 chr(39) || 'S' || chr(39) || (case
                   when i <> v_funciones.count and v_funciones(i).orden_agrpcion <> v_funciones(i + 1).orden_agrpcion then
                    ') ' || v_funciones(i).cmprta_lgca || ' ( '
                   when i <> v_funciones.count then
                    ' ' || v_funciones(i).cmprta_lgca || ' '
                 end);
    
      o_rspstas(i).id_orgen := v_funciones(i).id_rgla_ngcio_clnte_fncion;
      o_rspstas(i).indcdor_vldccion := o_indcdor_vldccion;
    
    end loop;
  
    v_where := '(' || nvl(v_where, ' 1 = 0 ') || ')';
  
    --Comprueba las condiciones construidas por cada funcion
    begin
      execute immediate ('select ''S'' from dual where ' || v_where)
        into o_indcdor_vldccion;
    exception
      when others then
        o_indcdor_vldccion := 'N';
    end;
  
  end prc_vl_reglas_negocio;

  --Up del Proceso de Aplicacion - (Imprimir_Multiples_Reportes)
  procedure prc_ge_reportes_multiples as
    v_xml     varchar2(4000);
    v_request varchar2(4000);
    v_data    sys_refcursor;
  begin
    begin
    
      v_xml     := apex_application.g_f01(1);
      v_request := apex_application.g_x01;
      apex_json.open_object();
    
      open v_data for
        select a.*,
               apex_util.prepare_url('/ords/f?p=66000:2:' ||
                                     v('APP_SESSION') || ':' || v_request ||
                                     '::2:P2_XML,P2_ID_RPRTE,P2_NMBRE_RPRTE,P2_ID_RPRTE_PRMTRO:' ||
                                     a."xml" || ',' || a."id_rprte" || ',' ||
                                     a."nmbre_rprte" || ',' ||
                                     a."id_rprte_prmtro") as "url"
          from (select rownum as "nmro",
                       b.id_rprte as "id_rprte",
                       nvl(pkg_gn_generalidades.fnc_ca_extract_value(a.xml.getStringVal(),
                                                                     'nmbre_rprte'),
                           b.nmbre_rprte || '.pdf') as "nmbre_rprte",
                       pkg_gn_generalidades.fnc_ca_extract_value(a.xml.getStringVal(),
                                                                 'id_rprte_prmtro') as "id_rprte_prmtro",
                       a.xml.extract('xml').getStringVal() as "xml"
                  from xmltable('/datas/data' passing
                                xmltype('<datas>' || v_xml || '</datas>')
                                columns xml xmltype path 'node()') a
                  join gn_d_reportes b
                    on pkg_gn_generalidades.fnc_ca_extract_value(a.xml.getStringVal(),
                                                                 'id_rprte') =
                       b.id_rprte) a;
    
      apex_json.write('err', false);
      apex_json.write('msg', 'exito');
      apex_json.write('data', v_data);
      apex_json.close_object();
    
    exception
      when others then
        apex_json.write('err', true);
        apex_json.write('msg', apex_escape.html(sqlerrm));
        apex_json.close_object();
    end;
  
    apex_json.close_all();
  
  end prc_ge_reportes_multiples;

  procedure prc_ge_excel_sql(p_sql            in clob,
                             o_file_blob      out blob,
                             o_msgerror       out varchar2,
                             p_column_headers in boolean default true,
                             p_sheet          in pls_integer default null) as
    v_bfile      bfile;
    v_directorio clob;
    v_file_name  varchar2(3000);
  
    --Exceptions
    v_no_directorio exception;
    pragma exception_init(v_no_directorio, -29280);
  begin
    o_file_blob := empty_blob();
    as_xlsx.query2sheet(p_sql);
    as_xlsx.query2sheet(p_sql            => p_sql,
                        p_column_headers => p_column_headers,
                        p_sheet          => p_sheet);
  
    v_directorio := 'FILES_TEMP';
    v_file_name  := 'Temp_' || to_char(sysdate, 'yyyyMMddHHMISS') || '_' ||
                    sys_context('USERENV', 'SESSIONID') || '.xlsx';
    as_xlsx.save(v_directorio, v_file_name);
  
    v_bfile := bfilename(v_directorio, v_file_name);
  
    dbms_lob.open(v_bfile, dbms_lob.lob_readonly);
    dbms_lob.createtemporary(lob_loc => o_file_blob,
                             cache   => true,
                             dur     => dbms_lob.session);
    -- Open temporary lob
    dbms_lob.open(o_file_blob, dbms_lob.lob_readwrite);
  
    -- Load binary file into temporary LOB
    dbms_lob.loadfromfile(dest_lob => o_file_blob,
                          src_lob  => v_bfile,
                          amount   => dbms_lob.getlength(v_bfile));
  
    -- Close lob objects
    dbms_lob.close(o_file_blob);
    dbms_lob.close(v_bfile);
  
    utl_file.fremove(v_directorio, v_file_name);
  exception
    when v_no_directorio then
      o_msgerror := 'Directorio no encontrado';
    when others then
      o_msgerror := 'Problemas al generar excel, ' || sqlerrm;
  end prc_ge_excel_sql;

  function fnc_co_formatted_type(p_tipo varchar2, p_valor varchar2)
    return varchar2 is
    v_tipo   varchar2(125) := lower(p_tipo);
    v_result varchar2(4000);
  begin
  
    if (v_tipo in ('varchar2',
                   'varchar',
                   'char',
                   'nchar',
                   'nvarchar2',
                   'xmltype',
                   'long',
                   'date',
                   'timestamp(6)')) then
      v_result := chr(39) || p_valor || chr(39);
    elsif (v_tipo in ('number', 'float', 'double', 'numeric', 'integer')) then
      v_result := replace(nvl(p_valor, q'['']'), ',', '.');
    else
      v_result := nvl(p_valor, q'['']');
    end if;
  
    return v_result;
  
  end fnc_co_formatted_type;

  function fnc_cl_fecha_texto(p_fecha date) return varchar2 is
    v_fcha_txto varchar2(100);
  begin
  
    select trim(to_char(p_fecha,
                        'DD "de" Month',
                        'nls_date_language=spanish')) ||
           to_char(p_fecha, ' "de" YYYY') AS FECHA
      into v_fcha_txto
      from dual;
  
    return v_fcha_txto;
  
  exception
    when others then
      return 'fecha no valida';
    
  end fnc_cl_fecha_texto;

  ---Procedimiento para generar el id de la tabla de parametros xml para reportes 
  function fnc_ge_id_rprte_prmtro return varchar2 is
  begin
    return v('APP_SESSION') || to_char(systimestamp, 'YYYYMMDDHH24MISSFF6');
  end fnc_ge_id_rprte_prmtro;

  procedure prc_rg_t_reportes_parametro(p_id_rprte_prmtro in varchar2,
                                        p_dta             in clob,
                                        o_cdgo_rspsta     out number,
                                        o_mnsje_rspsta    out varchar2) as
  begin
    o_cdgo_rspsta := 0;
  
    insert into gn_t_reportes_parametro
      (id_rprte_prmtro, dta)
    values
      (p_id_rprte_prmtro, p_dta);
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 01;
      o_mnsje_rspsta := '|Proceso insertar el id de los parametros del reporte';
      pkg_sg_log.prc_rg_log(1,
                            null,
                            'pkg_gn_generalidades.prc_generar_id_rprte_prmtro',
                            o_cdgo_rspsta,
                            o_mnsje_rspsta,
                            2);
  end prc_rg_t_reportes_parametro;

  /*
    * @Descripcion    : Procedimiento utilizado en la creacion de JOBS
    * @Autor          : Julio Diaz
    * @Creacion       : 29/05/2019
    * @Modificacion   : 29/05/2019
  */
  procedure prc_rg_creacion_jobs(p_cdgo_clnte      in number,
                                 p_job_name        in varchar2,
                                 p_job_action      in varchar2,
                                 p_t_prmtrs        in t_prmtrs,
                                 p_start_date      in timestamp with time zone,
                                 p_repeat_interval in varchar2 default null,
                                 p_end_date        in timestamp with time zone default null,
                                 p_auto_drop       in boolean default true,
                                 p_comments        in varchar2,
                                 o_cdgo_rspsta     out number,
                                 o_mnsje_rspsta    out varchar2) as
    pragma autonomous_transaction;
    v_nl number;
  
    v_nmro_job            number := scq_job.nextval;
    v_job_name            varchar2(100);
    v_number_of_arguments number;
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gn_generalidades.prc_rg_creacion_jobs');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gn_generalidades.prc_rg_creacion_jobs',
                          v_nl,
                          'Proceso iniciado con exito. ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    v_job_name            := p_job_name || '_' || v_nmro_job;
    v_number_of_arguments := p_t_prmtrs.count;
    begin
      dbms_scheduler.create_job(job_name            => v_job_name,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => p_job_action,
                                number_of_arguments => v_number_of_arguments,
                                start_date          => null,
                                repeat_interval     => p_repeat_interval,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => p_auto_drop,
                                comments            => p_comments);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC20-' || o_cdgo_rspsta ||
                          ' Problemas en la creacion del JOBS' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --PASAMOS EL ARGUMENTO DE LA INSTANCIA DEL FLUJO AL JOBS
    begin
      for i in 1 .. p_t_prmtrs.count loop
        dbms_scheduler.set_job_argument_value(job_name          => v_job_name,
                                              argument_position => i,
                                              argument_value    => p_t_prmtrs(i));
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC20-' || o_cdgo_rspsta ||
                          ' Problemas en el registro de parametros del JOBS' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --ACTUALIZAMOS LA FECHA DE INICIO DEL JOBS
    begin
      dbms_scheduler.set_attribute(name      => v_job_name,
                                   attribute => 'start_date',
                                   value     => p_start_date);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC20-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar fecha de inicio del JOBS' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --ACTUALIZAMOS LA FECHA DE FIN DEL JOBS
    if p_end_date is not null then
      begin
        dbms_scheduler.set_attribute(name      => v_job_name,
                                     attribute => 'end_date',
                                     value     => p_end_date);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC20-' || o_cdgo_rspsta ||
                            ' Problemas al actualizar fecha de fin del JOBS' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gn_generalidades.prc_rg_creacion_jobs',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gn_generalidades.prc_rg_creacion_jobs',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    --HABILITAMOS EL JOBS
    begin
      dbms_scheduler.enable(name => v_job_name);
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '|PRSC20-' || o_cdgo_rspsta ||
                          ' Problemas al habilitar el JOBS' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gn_generalidades.prc_rg_creacion_jobs',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gn_generalidades.prc_rg_creacion_jobs',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_rg_creacion_jobs;

  /*
    * @Descripcion    : Valida si la Cadena es Valida (1/0)
    * @Autor          : Ing. Nelson Ardila
    * @Creacion       : 01/11/2019
    * @Modificacion   : 01/11/2019
  */

  function fnc_vl_regexp(cadena in varchar2, expresion in varchar2)
    return number is
    language java name 'Util.regExp(java.lang.String,java.lang.String) return java.lang.Integer';

  /*
    * @Descripcion    : Valida si una cadena cumple con una expresion regular.
    * @Creacion       : 01/11/2019
    * @Modificacion   : 01/11/2019
  */
  function fnc_vl_expresion(p_cdgo_exp   in varchar2,
                            p_cdgo_clnte in number default v('F_CDGO_CLNTE'),
                            p_mnsje      in varchar2 default null,
                            p_vlor       in varchar2) return varchar2 is
    v_expresiones_validacion gn_d_expresiones_validacion%rowtype;
    v_count                  number := 0;
  begin
    begin
      select id_exprsion_vldcion,
             cdgo_exprsion_vldcion,
             cdgo_clnte,
             exprsion,
             dscrpcion,
             nvl(mnsje, p_mnsje) mnsje
        into v_expresiones_validacion
        from gn_d_expresiones_validacion a
       where cdgo_exprsion_vldcion = p_cdgo_exp
         and nvl(cdgo_clnte, p_cdgo_clnte) = p_cdgo_clnte
       order by a.cdgo_clnte
       fetch first row only;
    
    exception
      when no_data_found then
        v_expresiones_validacion.exprsion := p_cdgo_exp;
        v_expresiones_validacion.mnsje    := p_mnsje;
      when others then
        null;
    end;
  
    v_count := pkg_gn_generalidades.fnc_vl_regexp(cadena    => p_vlor,
                                                  expresion => v_expresiones_validacion.exprsion);
    if v_count = 0 then
      return v_expresiones_validacion.mnsje || ' ' || v_expresiones_validacion.dscrpcion;
    end if;
    return null;
  end fnc_vl_expresion;

  procedure prc_rg_migracion(p_cdgo_clnte   in number,
                             p_cdgo_mgrcion in varchar2,
                             p_obj_arr      in json_array_t,
                             v_key          in varchar2 default null,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2) as
    v_obj_a   json_array_t;
    v_json_a  clob;
    v_obj_f   json_object_t;
    v_obj_arr json_array_t := p_obj_arr;
    /*Funcion que devuelve un objeto de una array*/
    function find(v_array json_array_t, key varchar2, value varchar)
      return json_object_t as
      v_r json_object_t;
    begin
    
      for i in 0 .. (v_array.get_size() - 1) loop
        v_r := json_object_t(v_array.get(i));
        if (v_r.get_String(key) = value) then
          return v_r;
        end if;
      end loop;
      return null;
    end find;
  begin
    o_cdgo_rspsta := 0;
    begin
      select dta
        into v_json_a
        from gn_g_migracion
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_mgrcion = p_cdgo_mgrcion;
    
      v_obj_a := json_array_t(v_json_a);
      for i in 0 .. (v_obj_arr.get_size() - 1) loop
        if (v_key is not null) then
          v_obj_f := find(v_obj_a,
                          v_key,
                          json_object_t(v_obj_arr.get(i)).get_String(v_key));
          if (v_obj_f is not null) then
            continue;
          end if;
        end if;
        v_obj_a.append(v_obj_arr.get(i));
      end loop;
    
      v_json_a := v_obj_a.to_clob();
    
      update gn_g_migracion
         set dta = v_json_a
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_mgrcion = p_cdgo_mgrcion;
    
    exception
      when no_data_found then
        begin
          v_json_a := v_obj_arr.to_clob();
          insert into gn_g_migracion
            (cdgo_clnte, cdgo_mgrcion, dta)
          values
            (p_cdgo_clnte, p_cdgo_mgrcion, v_json_a);
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Ocurrio un error registrando la migracion ' ||
                              sqlerrm;
        end;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Ocurrio un error ' || sqlerrm;
    end;
  end prc_rg_migracion;

  function fnc_co_html(p_html clob) return clob as
    v_html clob := p_html;
  begin
    for crsor in (select vlor, exprsion from df_s_caracteres_especiales) loop
      v_html := replace(v_html, crsor.exprsion, crsor.vlor);
    end loop;
    return v_html;
  end fnc_co_html;
      function fnc_vl_html( p_html in clob) return boolean as
        l_comment  xmltype;
        xml_parse_err exception;
        pragma exception_init (xml_parse_err , -31011);
        v_html_aux  clob; 
        v_sqlerrm   varchar2(2000);
    begin
        --DBMS_OUTPUT.put_line('validar_html Inicio. ');
        
        -- Convierte los caracteres especiales en caracteres 
        v_html_aux := fnc_html_escape( p_html );
        
        --DBMS_OUTPUT.put_line('validar_html Antes de xmltype.createxml  v_html_aux: ' );
      l_comment := xmltype.createxml('<root><row>' || v_html_aux || '</row></root>');
      --DBMS_OUTPUT.put_line('validar_html Despues de xmltype.createxml ' || p_html );
      return true;
    
    exception 
        when xml_parse_err then
            v_sqlerrm := sqlerrm;
            --DBMS_OUTPUT.put_line('validar_html 98. Error: ' || v_sqlerrm );
            return false;
        when others then
            v_sqlerrm := sqlerrm;
            --DBMS_OUTPUT.put_line('validar_html 99. Error: ' || v_sqlerrm );
            return false;
    end;
    
    procedure prc_html_dividir( p_html      in clob
                              , p_tmno      in number   default 10000
                              , o_cdgo_mnsje  out number
                              , o_mnsje_rspsta  out varchar2) as

        v_html_aux  clob; 
    
        v_crcter_incial   number  := 1;
        v_crcter_fnal   number  := length(p_html);
        v_nmro_prcion   number  := 0;
        v_hasta       number;
    
    --v_json_object_t   json_object_t := json_object_t();
    --v_json_array_t      JSON_ARRAY_T;
    --v_json_object   clob;
    
        v_sqlerrm     varchar2(2000);
    
    begin
        o_cdgo_mnsje := 0;
        o_mnsje_rspsta := 'inicio';
        --Se setean valores de sesion
    begin
      if v('APP_SESSION') is null then
        apex_session.create_session(p_app_id   => 74000,
                                    p_page_id  => 17,
                                    p_username => '1111111112');
      else
      
        apex_session.attach(p_app_id     => 74000,
                            p_page_id    => 17,
                            p_session_id => v('APP_SESSION'));
      end if;
    exception
      when others then
        o_cdgo_mnsje  := 1;
        o_mnsje_rspsta := o_cdgo_mnsje ||' - '||'Error al setear los valores de la sesi?n';
        pkg_sg_log.prc_rg_log(70001,null,'pkg_gn_generalidades.prc_html_dividir',null, o_mnsje_rspsta||' , '||sqlerrm,6);
        rollback;
        return;
    end;
    
        --DBMS_OUTPUT.put_line('Inicio prc_dividir_html. ') ; -- || p_html );
    
        if pkg_gn_generalidades.fnc_vl_html( p_html ) = true then 
            --DBMS_OUTPUT.put_line('HTML Valido. ');
            o_cdgo_mnsje := 0;
            o_mnsje_rspsta := 'Valido';
        else
            --DBMS_OUTPUT.put_line('HTML No Valido: ' );
            o_cdgo_mnsje := 10;
            o_mnsje_rspsta := 'No valido';
            return;
        end if;
        begin
            apex_collection.delete_collection(p_collection_name => 'DATOS');
        exception 
            when others then 
            null;
        end;        
        
        apex_collection.create_or_truncate_collection( p_collection_name => 'DATOS');
        
        --delete muerto2 where n_001 = 10; commit;
        
    -- Instanciamos el objeto Json Array
    --v_json_array_t := new JSON_ARRAY_T;
    --o_json := '{ [';
    
    while v_crcter_incial < v_crcter_fnal
        loop
            --DBMS_OUTPUT.put_line('5 v_crcter_incial : ' || v_crcter_incial || ' Tamano: ' || p_tmno );
    
            -- Selecciono Porcion, de tama?o maximo p_tmno
            v_html_aux := substr( p_html, v_crcter_incial, p_tmno );
    
            --DBMS_OUTPUT.put_line('6 Antes de validar. v_html_aux: '  );
    
            -- Valido que la porci?n sea un HTML V?lido
            if pkg_gn_generalidades.fnc_vl_html( v_html_aux ) = true then    
                v_nmro_prcion := v_nmro_prcion + 1;
                
                apex_collection.add_member (
                                p_collection_name => 'DATOS',
                                p_n001      =>  v_nmro_prcion,
                                p_clob001   =>  v_html_aux);
                                
                --insert into muerto2 (n_001, n_002, c_001, t_001) values (10, v_nmro_prcion, v_html_aux, systimestamp); commit;
                
                --DBMS_OUTPUT.put_line('10 HTML V?lido. Inserto Porcion : ' || v_nmro_prcion );
        
                --v_json_object_t := JSON_OBJECT_T.parse('{"orden":"'  || v_nmro_prcion || '", 
        --                     "dcmnto":"' || v_html_aux || '" }');
        --v_json_object := '{"orden":"'  || v_nmro_prcion || '","dcmnto":"' || v_html_aux || '" }';
        
                v_crcter_incial := v_crcter_incial + p_tmno;
    
            else
                --DBMS_OUTPUT.put_line(' else NO VALIDO. v_crcter_fnal: ' || v_crcter_fnal || ' v_crcter_incial: ' || v_crcter_incial || ' p_tmno - 1 : ' || p_tmno );
    
                -- Iteramos adicionando caracter a caracter
                -- Hasta encontrar un HTML V?lido o Alcanzar el Final del HTML
                v_hasta := v_crcter_fnal - v_crcter_incial + p_tmno - 1;  
    
                --DBMS_OUTPUT.put_line(' else Despues de calcular v_hasta: ' || v_hasta || ' Procedemos a Iterar');
    
                for i in 1 .. v_hasta
                loop
                    --DBMS_OUTPUT.put_line('9 v_crcter_incial : ' || v_crcter_incial || ' p_tmno + i ' || p_tmno );
                    v_html_aux := substr( p_html, v_crcter_incial, p_tmno + i);
                    --DBMS_OUTPUT.put_line('For i : ' || i  );
    
                    if pkg_gn_generalidades.fnc_vl_html( v_html_aux ) = true  then
                        v_nmro_prcion := v_nmro_prcion + 1;
                        
                        apex_collection.add_member (
                                p_collection_name => 'DATOS',
                                p_n001      =>  v_nmro_prcion,
                                p_clob001   =>  v_html_aux);
                                
                        --insert into muerto2 (n_001, n_002, c_001, t_001) values (10, v_nmro_prcion, v_html_aux, systimestamp); commit;
                        
                        --DBMS_OUTPUT.put_line('10 HTML V?lido. Inserto Porcion : ' || v_nmro_prcion || ' v_crcter_incial: ' || v_crcter_incial || ' p_tmno: ' || p_tmno  );
            
                        -- := JSON_OBJECT_T.parse('{"orden":"'  || v_nmro_prcion || '", 
            --                     "dcmnto":"' || v_html_aux || '" }');
            --v_json_object := '{"orden":"'  || v_nmro_prcion || '","dcmnto":"' || v_html_aux || '" }';           
            
                        v_crcter_incial := v_crcter_incial + p_tmno + i;
    
                        exit;
                    end if;
                    if ( v_crcter_incial + p_tmno ) > v_crcter_fnal then
                        --DBMS_OUTPUT.put_line('Salio del For Por alcanzar el fin sin HTM V?lido');
                        Exit;
                    end if;
    
                end loop;
                --DBMS_OUTPUT.put_line('For End' );
            end if;
      
      -- Armamos el json
            --DBMS_OUTPUT.put_line('For End' );
      --o_json := o_json || v_json_object || ',' ;
    
        end loop;
    
    /*if length( o_json ) > 0 then
      -- Quitamos la ?ltima coma 
      o_json := substr( o_json, 1, length( o_json ) - 1 );
    end if;*/
    
    --o_json := o_json || '] }';
  
        /*for c in( select n_001, n_002, length(c_001) tamano
                    from muerto2
                    where n_001 = 10
                    order by n_002 ) 
        loop
            --DBMS_OUTPUT.put_line('Html: ' || c.c_001 );
            --DBMS_OUTPUT.put_line('Muerto n_001: ' || c.n_001 || ' n_002: ' || c.n_002  || ' Tamano: ' || c.tamano );
        end loop;*/
    
    exception 
        when others then
            o_cdgo_mnsje := 20;
            o_mnsje_rspsta := o_cdgo_mnsje||'- Error: ' || sqlerrm;
            v_sqlerrm := '99. Error: ' || sqlerrm;
            --DBMS_OUTPUT.put_line(v_sqlerrm);
    end;
    
    function fnc_html_escape ( p_html in clob ) return clob as
    v_html  clob := p_html;
  begin
    v_html := replace(v_html, '&aacute;', '?');
    v_html := replace(v_html, '&eacute;', '?');
    v_html := replace(v_html, '&iacute;', '?');
    v_html := replace(v_html, '&oacute;', '?');
    v_html := replace(v_html, '&uacute;', '?');
    v_html := replace(v_html, '&ntilde;', '?');
    v_html := replace(v_html, '&Aacute;', '?');
    v_html := replace(v_html, '&Eacute;', '?');
    v_html := replace(v_html, '&Iacute;', '?');
    v_html := replace(v_html, '&Oacute;', '?');
    v_html := replace(v_html, '&Uacute;', '?');
    v_html := replace(v_html, '&Ntilde;', '?');
    v_html := replace(v_html, '&nbsp;', ' ')  ;
    v_html := replace(v_html, '&ldquo;', '?');
    v_html := replace(v_html, '&rdquo;', '?');
    v_html := replace(v_html, '&bdquo;', '?');
    v_html := replace(v_html, '&deg;', '?') ;
    v_html := replace(v_html, '&auml;', '?');
    v_html := replace(v_html, '&euml;', '?');
    v_html := replace(v_html, '&iuml;', '?');
    v_html := replace(v_html, '&ouml;', '?');
    v_html := replace(v_html, '&uuml;', '?');
    v_html := replace(v_html, '&Auml;', '?');
    v_html := replace(v_html, '&Euml;', '?');
    v_html := replace(v_html, '&Iuml;', '?');
    v_html := replace(v_html, '&Ouml;', '?');
    v_html := replace(v_html, '&Uuml;', '?');
    v_html := replace(v_html, '<br>', '<br />');
    v_html := replace(v_html, '&ndash;', '?');
    v_html := replace(v_html, '&mdash;', '?');
    v_html := replace(v_html, '&ordm;', '?');
    v_html := replace(v_html, '&quot;', '"');
        
    v_html := replace(v_html, '&amp;', '&');
    v_html := replace(v_html, '&lt;', '<');
    v_html := replace(v_html, '&gt;', '>');
    v_html := replace(v_html, '&iexcl;', '?');
    v_html := replace(v_html, '&cent;', '?');
    v_html := replace(v_html, '&pound;', '?');
    v_html := replace(v_html, '&curren;', '?');
    v_html := replace(v_html, '&yen;', '?');
    v_html := replace(v_html, '&euro;', '?');
    v_html := replace(v_html, '&brvbar;', '?');
    v_html := replace(v_html, '&sect;', '?');
    v_html := replace(v_html, '&uml;', '?');
    v_html := replace(v_html, '&copy;', '?');
    v_html := replace(v_html, '&ordf;', '?');
    v_html := replace(v_html, '&laquo;', '?');
    v_html := replace(v_html, '&raquo;', '?');
    v_html := replace(v_html, '&not;', '?');
    v_html := replace(v_html, '&shy;', '?');
    v_html := replace(v_html, '&reg;', '?');
    v_html := replace(v_html, '&macr;', '?');
    v_html := replace(v_html, '&plusmn;', '?');
        v_html := replace(v_html, '&sup1;', '?');
    v_html := replace(v_html, '&sup2;', '?');
    v_html := replace(v_html, '&sup3;', '?');
    v_html := replace(v_html, '&acute;', '?');
    v_html := replace(v_html, '&micro;', '?');
    v_html := replace(v_html, '&para;', '?');
    v_html := replace(v_html, '&middot;', '?');
    v_html := replace(v_html, '&cedil;', '?');
    v_html := replace(v_html, '&iquest;', '?');
    v_html := replace(v_html, '&frac14;', '?');
    v_html := replace(v_html, '&frac12;', '?');
    v_html := replace(v_html, '&frac34;', '?');
        
        v_html := replace(v_html, '&Agrave',  '?');
        v_html := replace(v_html, '&Acirc;',  '?');
        v_html := replace(v_html, '&Atilde',  '?');
        v_html := replace(v_html, '&Aring;',  '?');
        v_html := replace(v_html, '&AElig;',  '?');
        v_html := replace(v_html, '&Ccedil',  '?');
        v_html := replace(v_html, '&Egrave',  '?');
        v_html := replace(v_html, '&Ecirc;',  '?');
        v_html := replace(v_html, '&Igrave',  '?');
        v_html := replace(v_html, '&Icirc;',  '?');
        v_html := replace(v_html, '&ETH;',    '?');
        v_html := replace(v_html, '&Ograve;', '?');
        v_html := replace(v_html, '&Ocirc;',  '?');
        v_html := replace(v_html, '&Otilde;', '?');
        v_html := replace(v_html, '&times;',  '?');
        v_html := replace(v_html, '&Oslash;', '?');
        v_html := replace(v_html, '&Ugrave;', '?');
        v_html := replace(v_html, '&Ucirc;',  '?');
        v_html := replace(v_html, '&Yacute;', '?');
        v_html := replace(v_html, '&THORN;',  '?');
        v_html := replace(v_html, '&szlig;',  '?');
        v_html := replace(v_html, '&agrave;', '?');
        v_html := replace(v_html, '&acirc;',  '?');
        v_html := replace(v_html, '&atilde;', '?');
        v_html := replace(v_html, '&aring;',  '?');
        v_html := replace(v_html, '&aelig;',  '?');
        v_html := replace(v_html, '&ccedil;', '?');
        v_html := replace(v_html, '&egrave;', '?');
        v_html := replace(v_html, '&ecirc;',  '?');
        v_html := replace(v_html, '&igrave;', '?');
        v_html := replace(v_html, '&icirc;',  '?');
        v_html := replace(v_html, '&eth;',    '?');
        v_html := replace(v_html, '&ograve;', '?');
        v_html := replace(v_html, '&ocirc;',  '?');
        v_html := replace(v_html, '&otilde;', '?');
        v_html := replace(v_html, '&divide;', '?');
        v_html := replace(v_html, '&oslash;', '?');
        v_html := replace(v_html, '&ugrave;', '?');
        v_html := replace(v_html, '&ucirc;',  '?');
        v_html := replace(v_html, '&yacute;', '?');
        v_html := replace(v_html, '&thorn;',  '?');
        v_html := replace(v_html, '&yuml;',   '?');
        
    v_html := replace(v_html, '&hellip;', '?');
    
    return v_html;
  end fnc_html_escape;

  

  -- Migrada de Pruebas por JAGUAS 23/04/2021
  function fnc_vl_pago_pse(p_cdgo_clnte          in number,
                           p_cdgo_impsto         in varchar2,
                           p_cdgo_impsto_sbmpsto in number default null)
    return varchar2 as
  
    v_resultado number;
  
  begin
  
    begin
    
      select 1
        into v_resultado
        from ws_d_provedores_cliente
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_cdgo_impsto
         and (id_impsto_sbmpsto = p_cdgo_impsto_sbmpsto or p_cdgo_impsto_sbmpsto is null)
         --and id_impsto_sbmpsto in (2300111, 2300177, 23001157, 23001155, 2300199) -- ojo quitar esta validacion
         and actvo = 'S';
    
    exception
      when no_data_found then
        return 'N';
      when others then
        return 'N';
    end;
  
    return 'S';
  
  end fnc_vl_pago_pse;

  -- Procedimiento que consulta un archivo de la tabla temporal APEX_APPLICATION_TEMP_FILES
  procedure prc_co_archivo_apex_temp_file(p_nmbre_archvo  in varchar2,
                                          o_file_blob     out blob,
                                          o_file_name     out varchar2,
                                          o_file_mimetype out varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2) as
  begin
    --Consultamos el archivo en la tabla temporal 'APEX_APPLICATION_TEMP_FILES'
    begin
      select blob_content, filename, mime_type
        into o_file_blob, o_file_name, o_file_mimetype
        from apex_application_temp_files
       where lower(filename) = lower(p_nmbre_archvo);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro el archivo: ' || p_nmbre_archvo;
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Problemas al consultar el Archivo: ' ||
                          p_nmbre_archvo;
        return;
    end;
  end prc_co_archivo_apex_temp_file;

  -- Procedimiento que consulta un archivo alojado en el servidor
  procedure prc_co_archivo_disco_servidor(p_drctrio       in varchar2,
                                          p_nmbre_archvo  in varchar2,
                                          o_file_blob     out blob,
                                          o_file_name     out varchar2,
                                          o_file_mimetype out varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2) as
    v_file_bfile bfile;
    --v_file_blob   blob;
  begin
    -- mensaje y codigo exitoso
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Ok';
  
    v_file_bfile := bfilename(p_drctrio, p_nmbre_archvo);
  
    -- validamos si se encontro el archivo
    if dbms_lob.fileexists(v_file_bfile) = 1 then
    
      dbms_lob.fileopen(v_file_bfile);
    
      dbms_lob.createtemporary(o_file_blob, true);
    
      dbms_lob.loadfromfile(o_file_blob,
                            v_file_bfile,
                            dbms_lob.getlength(v_file_bfile));
    
      dbms_lob.fileclose(v_file_bfile);
    else
      o_cdgo_rspsta   := 10;
      o_mnsje_rspsta  := o_cdgo_rspsta || ' - ' || 'Archivo ' ||
                         p_nmbre_archvo || ' no existe';
      o_file_blob     := null;
      o_file_name     := null;
      o_file_mimetype := null;
      return;
    end if;
  
  exception
    when others then
      o_cdgo_rspsta  := 20;
      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || sqlerrm;
  end prc_co_archivo_disco_servidor;

  procedure prc_rg_registros_impresion(p_json_regstros in clob,
                                       p_cdgo_imprsion in varchar2,
                                       p_id_usrio      in number,
                                       p_id_session    in number default v('APP_SESSION'),
                                       o_ttal_rgstros  out number,
                                       o_cdgo_rspsta   out number,
                                       o_mnsje_rspsta  out varchar2) as
    v_ttal_rgstros      number := 0;
    v_id_rprte_imprsion number;
    v_json_data         clob;
  begin
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
    delete gn_g_reportes_impresion where id_session = p_id_session;
    for c_datos in (select x.json_data
                      from json_table(p_json_regstros,
                                      '$[*]'
                                      columns(json_data clob FORMAT JSON path '$')) as x) loop
      v_ttal_rgstros := v_ttal_rgstros + 1;
      begin
        insert into gn_g_reportes_impresion
          (cdgo_imprsion,
           prmtros_rprte_cnslta,
           id_usrio,
           id_session,
           estdo_imprsion)
        values
          (p_cdgo_imprsion,
           c_datos.json_data,
           p_id_usrio,
           p_id_session,
           'P');
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al insertar los datos de impresion: ' ||
                            p_cdgo_imprsion;
      end;
    end loop;
    o_ttal_rgstros := v_ttal_rgstros;
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Error al procesar datos de impresion';
  end prc_rg_registros_impresion;

  procedure prc_rg_seleccion_cnddts_archvo(p_cdgo_clnte    in number,
                                           p_id_prcso_crga in number,
                                           p_id_lte        in number,
                                           o_cdgo_rspsta   out number,
                                           o_mnsje_rspsta  out varchar2) as
    e_no_encuentra_lote   exception;
    e_no_archivo_excel    exception;
    v_et_g_procesos_carga et_g_procesos_carga%rowtype;
    v_cdgo_prcso          varchar2(3);
    v_sldo_ttal_crtra     number;
    v_id_sjto_impsto      number;
    v_id_prcsos_smu_sjto  number;
    v_id_embrgos_smu_sjto number;
    v_id_prgrma           number;
    v_id_sbprgrma         number;
    v_id_prdo             number;
    v_id_cnddto           number;
    v_id_cnddto_vgncia    number;
    v_nl                  number := 6;
    v_nmbre_up            varchar2(100) := 'pkg_gn_generalidades.prc_rg_seleccion_cnddts_archvo';
    v_determinacion       varchar2(1); 
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Si no se especifica un lote
    if p_id_lte is null then
      raise e_no_encuentra_lote;
    end if;
  
    -- ****************** INICIO ETL ***************************************************
    begin
      select a.*
        into v_et_g_procesos_carga
        from et_g_procesos_carga a
       where id_prcso_crga = p_id_prcso_crga;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al consultar informacion de carga en ETL';
        return;
    end;
  
    -- Cargar archivo al directorio
    pk_etl.prc_carga_archivo_directorio(p_file_blob => v_et_g_procesos_carga.file_blob,
                                        p_file_name => v_et_g_procesos_carga.file_name);
  
    -- Ejecutar proceso de ETL para cargar a tabla intermedia
    pk_etl.prc_carga_intermedia_from_dir(p_cdgo_clnte    => p_cdgo_clnte,
                                         p_id_prcso_crga => p_id_prcso_crga);
  
    -- Cargar datos a Gestion
    pk_etl.prc_carga_gestion(p_cdgo_clnte    => p_cdgo_clnte,
                             p_id_prcso_crga => p_id_prcso_crga);
  
    -- ****************** FIN ETL ******************************************************
  
    -- Validar si el ID_CRGA pertenece al modulo cautelar o al modulo de cobros
    -- GCB o MCA?
  
    insert into muerto
      (n_001, v_001, t_001)
    values
      (250,
       'p_id_prcso_crga: ' || p_id_prcso_crga || ', p_id_lte: ' || p_id_lte,
       systimestamp);
    commit;
    begin
      select cdgo_prcso
        into v_cdgo_prcso
        from v_gn_g_candidatos_carga
       where id_prcso_crga = p_id_prcso_crga
         and id_lte_prcso = p_id_lte
         and rownum <= 1;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al validar el proceso que realiza la carga.';
        return;
    end;
  
    -- Si el proceso es del modulo de cobros (GCB)
    if v_cdgo_prcso = 'GCB' then
    
      begin
        -- 3. Se inactivan los sujetos (que no han sido procesados) en el lote que 
        -- no se encuentren en la informacion cargada del archivo.
        --delete from cb_g_procesos_simu_sujeto a
        update cb_g_procesos_simu_sujeto a
           set a.actvo = 'N'
         where a.id_prcsos_smu_lte = p_id_lte
           and a.indcdor_prcsdo = 'N'
           and a.actvo = 'S'
           and not exists (select 1
                  from v_gn_g_candidatos_carga c
                  join si_c_sujetos d
                    on d.idntfccion = c.idntfccion
                 where d.id_sjto = a.id_sjto
                   and c.id_prcso_crga = p_id_prcso_crga
                   and c.id_lte_prcso = p_id_lte
                   and c.cdgo_prcso = v_cdgo_prcso);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '-Error al intentar eliminar los sujetos que no estan en el archivo cargado.' ||
                            sqlerrm;
          return;
      end;
    
      -- Activa sujetos que vinieron en el Excel y Estan INACTIVOS en el Lote
      for c_sjtos_archvo in (select d.id_sjto
                               from v_gn_g_candidatos_carga c
                               join si_c_sujetos d
                                 on d.idntfccion = c.idntfccion
                              where c.id_prcso_crga = p_id_prcso_crga
                                and c.id_lte_prcso = p_id_lte
                                and c.cdgo_prcso = v_cdgo_prcso
                                and exists
                              (select 1
                                       from cb_g_procesos_simu_sujeto j
                                      where j.id_sjto = d.id_sjto
                                        and j.id_prcsos_smu_lte =
                                            c.id_lte_prcso
                                        and j.actvo = 'N'
                                        and j.indcdor_prcsdo = 'N')) loop
      
        -- Los que esten inactivos pero vinieron en el archivo se vuelven a activar
        update cb_g_procesos_simu_sujeto a
           set a.actvo = 'S'
         where a.id_prcsos_smu_lte = p_id_lte
           and a.id_sjto = c_sjtos_archvo.id_sjto
           and a.indcdor_prcsdo = 'N'
           and a.actvo = 'N';
      
      end loop;
    
      -- INSERTAR en el Lote ... los Nuevos Sujeto que vinieron en el Excel y No estaban en el Lote
      for c_sjtos_archvo in (select c.idntfccion,
                                    c.vgncia_dsde,
                                    c.vgncia_hsta,
                                    d.id_sjto,
                                    c.id_impsto,
                                    c.id_impsto_sbmpsto
                               from v_gn_g_candidatos_carga c
                               join si_c_sujetos d
                                 on d.idntfccion = c.idntfccion
                              where c.id_prcso_crga = p_id_prcso_crga
                                and c.id_lte_prcso = p_id_lte
                                and c.cdgo_prcso = v_cdgo_prcso
                                and not exists
                              (select 1
                                       from cb_g_procesos_simu_sujeto j
                                      where j.id_sjto = d.id_sjto) --and j.id_prcsos_smu_lte = c.id_lte_prcso)
                             ) loop
      
        -- *************************************
        -- incluimos Sujetos
        -- *************************************
        -- Incluir Responsables
        -- Incluir Movimientos Financieros 
      
        -- <Identificar Sujeto Impuesto>
        begin
          select a.id_sjto_impsto
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto a
           where a.id_impsto = c_sjtos_archvo.id_impsto
             and a.id_sjto = c_sjtos_archvo.id_sjto;
          insert into muerto
            (v_001, t_001)
          values
            ('el id sujeto:  ' || v_id_sjto_impsto, systimestamp);
        
        exception
          when others then
            o_cdgo_rspsta  := 35;
            o_mnsje_rspsta := 'No se pudo identificar el sujeto impuesto asociado al ID SUJETO 1 #' ||
                              c_sjtos_archvo.id_sjto;
            insert into muerto
              (v_001, t_001)
            values
              (o_cdgo_rspsta || ' ' || o_mnsje_rspsta, systimestamp);
            continue;
        end;
      
        -- FIN <Identificar Sujeto Impuesto>
      
        -- <Validar cartera>
        -- Validar si presenta saldo en el rango de vigencias indicado
        -- En la cartera vencida.
        begin
          /* select nvl(sum(a.vlor_sldo_cptal + a.vlor_intres), 0)
            into v_sldo_ttal_crtra
            from v_gf_g_cartera_x_concepto a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = c_sjtos_archvo.id_impsto
             and a.id_impsto_sbmpsto = c_sjtos_archvo.id_impsto_sbmpsto
             and a.id_sjto_impsto = v_id_sjto_impsto
             and a.vgncia between c_sjtos_archvo.vgncia_dsde and
                 c_sjtos_archvo.vgncia_hsta
             and trunc(a.fcha_vncmnto) < trunc(sysdate)*/
             --Incluimos la validacion de Vigencia que presenten determinacion
             /*and exists (select 1
                 from gi_g_determinacion_detalle d
                 where d.id_sjto_impsto = a.id_sjto_impsto
                 and d.vgncia = a.vgncia
                 and d.id_prdo = a.id_prdo
                and d.id_cncpto = a.id_cncpto) */   
                
 ---ALEX Validamos que las Vigencias esten Determinadas y que no tengan proceso juridico activo
 
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  p_cdgo_clnte  - '|| p_cdgo_clnte , 1);         
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  c_sjtos_archvo.id_impsto  - '|| c_sjtos_archvo.id_impsto , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  c_sjtos_archvo.id_impsto_sbmpsto  - '|| c_sjtos_archvo.id_impsto_sbmpsto , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  v_id_sjto_impsto  - '|| v_id_sjto_impsto , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  c_sjtos_archvo.vgncia_dsde  - '|| c_sjtos_archvo.vgncia_dsde , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  c_sjtos_archvo.vgncia_hsta  - '|| c_sjtos_archvo.vgncia_hsta , 1);
                select    
                      nvl(sum(a.vlor_sldo_cptal + a.vlor_intres), 0)
                into v_sldo_ttal_crtra
                from v_gf_g_cartera_x_concepto a
                join si_i_sujetos_impuesto b     on b.id_sjto_impsto = a.id_sjto_impsto
                                                       and b.id_sjto_estdo = 1
                where a.cdgo_clnte =  p_cdgo_clnte
                and a.id_impsto = c_sjtos_archvo.id_impsto
                and a.id_impsto_sbmpsto = c_sjtos_archvo.id_impsto_sbmpsto
                and a.id_sjto_impsto = v_id_sjto_impsto
                and a.vgncia between c_sjtos_archvo.vgncia_dsde and
                                    c_sjtos_archvo.vgncia_hsta
                and trunc(a.fcha_vncmnto) < trunc(sysdate)
                and a.vlor_sldo_cptal > 0
                and a.cdgo_mvnt_fncro_estdo = 'NO'
                and not exists (select 1
                                  from cb_g_procesos_jrdco_mvmnto c
                                 where c.id_sjto_impsto = a.id_sjto_impsto
                                   and c.vgncia = a.vgncia
                                   and c.id_prdo = a.id_prdo
                                   and c.id_cncpto = a.id_cncpto)
               and pkg_cb_proceso_juridico.fnc_vl_determinacion_vigencia_prdo(
                                   p_id_sjto_impsto => a.id_sjto_impsto,
                                   p_vgncia         => a.vgncia,
                                   p_id_prdo        => a.id_prdo,
                                   p_id_cncpto      => a.id_cncpto) = 'S'
                   --case when a.id_impsto = 230011 then 'S' else 'N' end
                ;                                          
 --ALEX 09/09/2024 fin
                
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'Error al validar saldo en cartera.';
            continue;
        end;
        -- FIN <Validar cartera>
 
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  v_sldo_ttal_crtra  - '|| v_sldo_ttal_crtra , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  p_id_lte  - '|| p_id_lte , 1);
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  c_sjtos_archvo.id_sjto  - '|| c_sjtos_archvo.id_sjto , 1);
         
        -- SI tiene cartera proseguimos
        if v_sldo_ttal_crtra > 0 then
        
          -- 1. Incluir sujeto
          begin
            insert into cb_g_procesos_simu_sujeto
              (id_prcsos_smu_lte,
               id_sjto,
               vlor_ttal_dda,
               rspnsbles,
               fcha_ingrso,
               indcdor_prcsdo)
            values
              (p_id_lte,
               c_sjtos_archvo.id_sjto,
               v_sldo_ttal_crtra,
               '-',
               sysdate,
               'N')
            returning id_prcsos_smu_sjto into v_id_prcsos_smu_sjto;
          exception
            when others then
              o_cdgo_rspsta  := 50;
              o_mnsje_rspsta := 'Error al intentar incluir sujeto en el lote de seleccion.';
              continue;
          end;
        
          -- 2. Incluir responsables
          for c_rspnsbles in (select a.prmer_nmbre,
                                     a.sgndo_nmbre,
                                     a.prmer_aplldo,
                                     a.sgndo_aplldo,
                                     a.cdgo_idntfccion_tpo,
                                     a.idntfccion_rspnsble,
                                     a.prncpal_s_n,
                                     a.prcntje_prtcpcion,
                                     a.cdgo_tpo_rspnsble,
                                     a.id_pais,
                                     a.id_dprtmnto,
                                     a.id_mncpio,
                                     a.drccion
                                from v_si_i_sujetos_responsable a
                                join si_c_sujetos b
                                  on a.id_sjto = b.id_sjto
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.id_sjto = c_sjtos_archvo.id_sjto
                                 and a.id_sjto_impsto = v_id_sjto_impsto
                               group by a.prmer_nmbre,
                                        a.sgndo_nmbre,
                                        a.prmer_aplldo,
                                        a.sgndo_aplldo,
                                        a.cdgo_idntfccion_tpo,
                                        a.idntfccion_rspnsble,
                                        a.prncpal_s_n,
                                        a.prcntje_prtcpcion,
                                        a.cdgo_tpo_rspnsble,
                                        a.id_pais,
                                        a.id_dprtmnto,
                                        a.id_mncpio,
                                        a.drccion) loop
            begin
              insert into cb_g_procesos_simu_rspnsble
                (id_prcsos_smu_sjto,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 prmer_nmbre,
                 sgndo_nmbre,
                 prmer_aplldo,
                 sgndo_aplldo,
                 prncpal_s_n,
                 cdgo_tpo_rspnsble,
                 prcntje_prtcpcion,
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion)
              values
                (v_id_prcsos_smu_sjto,
                 c_rspnsbles.cdgo_idntfccion_tpo,
                 c_rspnsbles.idntfccion_rspnsble,
                 c_rspnsbles.prmer_nmbre,
                 c_rspnsbles.sgndo_nmbre,
                 c_rspnsbles.prmer_aplldo,
                 c_rspnsbles.sgndo_aplldo,
                 c_rspnsbles.prncpal_s_n,
                 c_rspnsbles.cdgo_tpo_rspnsble,
                 c_rspnsbles.prcntje_prtcpcion,
                 c_rspnsbles.id_pais,
                 c_rspnsbles.id_dprtmnto,
                 c_rspnsbles.id_mncpio,
                 c_rspnsbles.drccion);
            exception
              when others then
                o_cdgo_rspsta  := 55;
                o_mnsje_rspsta := 'Error mientras se intentaba incluir al responsable con identificacion #' ||
                                  c_rspnsbles.idntfccion_rspnsble;
                continue;
            end;
          end loop;
        
          -- 3. Insertar los movimientos
          for c_mvmntos in (select id_sjto_impsto,
                                   vgncia,
                                   id_prdo,
                                   id_cncpto,
                                   vlor_sldo_cptal,
                                   vlor_intres,
                                   cdgo_clnte,
                                   id_impsto,
                                   id_impsto_sbmpsto,
                                   cdgo_mvmnto_orgn,
                                   id_orgen,
                                   id_mvmnto_fncro
                              from v_gf_g_cartera_x_concepto
                             where cdgo_clnte = p_cdgo_clnte
                               and id_impsto = c_sjtos_archvo.id_impsto
                               and id_impsto_sbmpsto =
                                   c_sjtos_archvo.id_impsto_sbmpsto
                               and id_sjto_impsto = v_id_sjto_impsto
                               and vgncia between c_sjtos_archvo.vgncia_dsde and
                                   c_sjtos_archvo.vgncia_hsta
                               and (vlor_sldo_cptal + vlor_intres) > 0
                               and trunc(fcha_vncmnto) < trunc(sysdate)
                               and cdgo_mvnt_fncro_estdo = 'NO' -- Cartera Normalizada
                            ) loop
          
            begin
              insert into cb_g_procesos_smu_mvmnto
                (id_prcsos_smu_sjto,
                 id_sjto_impsto,
                 vgncia,
                 id_prdo,
                 id_cncpto,
                 vlor_cptal,
                 vlor_intres,
                 cdgo_clnte,
                 id_impsto,
                 id_impsto_sbmpsto,
                 cdgo_mvmnto_orgn,
                 id_orgen,
                 id_mvmnto_fncro)
              values
                (v_id_prcsos_smu_sjto,
                 c_mvmntos.id_sjto_impsto,
                 c_mvmntos.vgncia,
                 c_mvmntos.id_prdo,
                 c_mvmntos.id_cncpto,
                 c_mvmntos.vlor_sldo_cptal,
                 c_mvmntos.vlor_intres,
                 c_mvmntos.cdgo_clnte,
                 c_mvmntos.id_impsto,
                 c_mvmntos.id_impsto_sbmpsto,
                 c_mvmntos.cdgo_mvmnto_orgn,
                 c_mvmntos.id_orgen,
                 c_mvmntos.id_mvmnto_fncro);
            exception
              when others then
                o_cdgo_rspsta  := 55;
                o_mnsje_rspsta := 'Error mientras se intentaba incluir movimientos de cartera al sujeto #' ||
                                  v_id_prcsos_smu_sjto;
                continue;
            end;
          end loop;
        else
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'El sujeto no tiene saldo en cartera #' ||
                            c_sjtos_archvo.id_sjto;
        end if;
      end loop;
    
    elsif v_cdgo_prcso = 'MCA' then
      -- Si el proceso es del modulo cautelar (MCA)
    
      begin
        -- 3. Se eliminan los sujetos (que no han sido procesados) en el lote que 
        -- no se encuentren en la informacion cargada del archivo.
        update mc_g_embargos_simu_sujeto a
           set a.actvo = 'N'
         where a.id_embrgos_smu_lte = p_id_lte
           and a.indcdor_prcsdo = 'N'
           and a.actvo = 'S'
           and not exists (select 1
                  from v_gn_g_candidatos_carga c
                  join si_c_sujetos d
                    on d.idntfccion = c.idntfccion
                 where d.id_sjto = a.id_sjto
                   and c.id_prcso_crga = p_id_prcso_crga
                   and c.id_lte_prcso = p_id_lte
                   and c.cdgo_prcso = v_cdgo_prcso);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '-Error al intentar eliminar los sujetos que no estan en el archivo cargado.' ||
                            sqlerrm;
          return;
      end;
    
      -- Activa sujetos que vinieron en el Excel y Estan INACTIVOS en el Lote
      for c_sjtos_archvo in (select d.id_sjto
                               from v_gn_g_candidatos_carga c
                               join si_c_sujetos d
                                 on d.idntfccion = c.idntfccion
                              where c.id_prcso_crga = p_id_prcso_crga
                                and c.id_lte_prcso = p_id_lte
                                and c.cdgo_prcso = v_cdgo_prcso
                                and exists
                              (select 1
                                       from mc_g_embargos_simu_sujeto j
                                      where j.id_sjto = d.id_sjto
                                        and j.id_embrgos_smu_lte =
                                            c.id_lte_prcso
                                        and j.actvo = 'N'
                                        and j.indcdor_prcsdo = 'N')) loop
      
        -- Los que esten inactivos pero vinieron en el archivo se vuelven a activar
        update mc_g_embargos_simu_sujeto a
           set a.actvo = 'S'
         where a.id_embrgos_smu_lte = p_id_lte
           and a.id_sjto = c_sjtos_archvo.id_sjto
           and a.indcdor_prcsdo = 'N'
           and a.actvo = 'N';
      
      end loop;
    
      -- INSERTAR en el Lote ... los Nuevos Sujeto que vinieron en el Excel y No estaban en el Lote
      for c_sjtos in (select c.idntfccion,
                             c.vgncia_dsde,
                             c.vgncia_hsta,
                             d.id_sjto,
                             c.id_impsto,
                             c.id_impsto_sbmpsto
                        from v_gn_g_candidatos_carga c
                        join si_c_sujetos d
                          on d.idntfccion = c.idntfccion
                       where c.id_prcso_crga = p_id_prcso_crga
                         and c.id_lte_prcso = p_id_lte
                         and c.cdgo_prcso = v_cdgo_prcso
                         and not exists
                       (select 1
                                from mc_g_embargos_simu_sujeto j
                               where j.id_sjto = d.id_sjto)) loop
      
        -- *************************************
        -- incluimos Sujetos
        -- *************************************
        -- Incluir Responsables
        -- Incluir Movimientos Financieros    
      
        -- <Identificar Sujeto Impuesto>
        begin
          select a.id_sjto_impsto
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto a
           where a.id_impsto = c_sjtos.id_impsto
             and a.id_sjto = c_sjtos.id_sjto;
        
          if v_id_sjto_impsto is null then
            rollback;
            insert into mc_g_embrgo_cnddtos_no_crgdos
              (cdgo_clnte,
               idntfccion_sjto,
               vgncia_dsde,
               vgncia_hsta,
               fcha,
               obsrvcion)
            values
              (p_cdgo_clnte,
               c_sjtos.idntfccion,
               c_sjtos.vgncia_dsde,
               c_sjtos.vgncia_hsta,
               systimestamp,
               'No se pudo identificar el sujeto impuesto asociado al ID SUJETO 2 #' ||
               c_sjtos.id_sjto);
            commit;
            continue;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 35;
            o_mnsje_rspsta := 'No se pudo identificar el sujeto impuesto asociado al ID SUJETO 3 #' ||
                              c_sjtos.id_sjto;
            continue;
        end;
        -- FIN <Identificar Sujeto Impuesto>
      
        -- <Validar cartera>
        -- Validar si presenta saldo en el rango de vigencias indicado
        -- En la cartera vencida.
        begin
          select nvl(sum(vlor_sldo_cptal + vlor_intres), 0)
            into v_sldo_ttal_crtra
            from v_gf_g_cartera_x_concepto
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = c_sjtos.id_impsto
             and id_impsto_sbmpsto = c_sjtos.id_impsto_sbmpsto
             and id_sjto_impsto = v_id_sjto_impsto
             and vgncia between c_sjtos.vgncia_dsde and c_sjtos.vgncia_hsta
             and trunc(fcha_vncmnto) < trunc(sysdate);
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'Error al validar saldo en cartera.';
            continue;
        end;
        -- FIN <Validar cartera>
      
        -- Si saldo en cartera es mayor a cero (Cartera > 0), entonces...
        if v_sldo_ttal_crtra > 0 then
        
          -- Si ya existe un lote, entonces, se incluyen los sujetos, los responsables y los movimientos.
          -- 1. Incluir sujeto
          begin
            insert into mc_g_embargos_simu_sujeto
              (id_embrgos_smu_lte,
               id_sjto,
               vlor_ttal_dda,
               fcha_ingrso,
               indcdor_prcsdo)
            values
              (p_id_lte, c_sjtos.id_sjto, v_sldo_ttal_crtra, sysdate, 'N')
            returning id_embrgos_smu_sjto into v_id_embrgos_smu_sjto;
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 50;
              o_mnsje_rspsta := 'Error al intentar incluir sujeto en el lote de seleccion.';
              insert into mc_g_embrgo_cnddtos_no_crgdos
                (cdgo_clnte,
                 idntfccion_sjto,
                 vgncia_dsde,
                 vgncia_hsta,
                 fcha,
                 obsrvcion)
              values
                (p_cdgo_clnte,
                 c_sjtos.idntfccion,
                 c_sjtos.vgncia_dsde,
                 c_sjtos.vgncia_hsta,
                 systimestamp,
                 o_cdgo_rspsta || ' ' || o_mnsje_rspsta);
              commit;
              continue;
          end;
        
          -- 2. Incluir responsables
          for c_rspnsbles in (select a.prmer_nmbre,
                                     a.sgndo_nmbre,
                                     a.prmer_aplldo,
                                     a.sgndo_aplldo,
                                     a.cdgo_idntfccion_tpo,
                                     a.idntfccion_rspnsble,
                                     a.prncpal_s_n,
                                     a.prcntje_prtcpcion,
                                     a.cdgo_tpo_rspnsble,
                                     a.id_pais,
                                     a.id_dprtmnto,
                                     a.id_mncpio,
                                     a.drccion
                                from v_si_i_sujetos_responsable a
                                join si_c_sujetos b
                                  on a.id_sjto = b.id_sjto
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.id_sjto = c_sjtos.id_sjto
                                 and a.id_sjto_impsto = v_id_sjto_impsto
                               group by a.prmer_nmbre,
                                        a.sgndo_nmbre,
                                        a.prmer_aplldo,
                                        a.sgndo_aplldo,
                                        a.cdgo_idntfccion_tpo,
                                        a.idntfccion_rspnsble,
                                        a.prncpal_s_n,
                                        a.prcntje_prtcpcion,
                                        a.cdgo_tpo_rspnsble,
                                        a.id_pais,
                                        a.id_dprtmnto,
                                        a.id_mncpio,
                                        a.drccion) loop
            begin
              insert into mc_g_embargos_simu_rspnsble
                (id_embrgos_smu_sjto,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 prmer_nmbre,
                 sgndo_nmbre,
                 prmer_aplldo,
                 sgndo_aplldo,
                 prncpal_s_n,
                 cdgo_tpo_rspnsble,
                 prcntje_prtcpcion,
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion)
              values
                (v_id_embrgos_smu_sjto,
                 c_rspnsbles.cdgo_idntfccion_tpo,
                 c_rspnsbles.idntfccion_rspnsble,
                 c_rspnsbles.prmer_nmbre,
                 c_rspnsbles.sgndo_nmbre,
                 c_rspnsbles.prmer_aplldo,
                 c_rspnsbles.sgndo_aplldo,
                 c_rspnsbles.prncpal_s_n,
                 c_rspnsbles.cdgo_tpo_rspnsble,
                 c_rspnsbles.prcntje_prtcpcion,
                 c_rspnsbles.id_pais,
                 c_rspnsbles.id_dprtmnto,
                 c_rspnsbles.id_mncpio,
                 c_rspnsbles.drccion);
              null;
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 55;
                o_mnsje_rspsta := 'Error mientras se intentaba incluir al responsable con identificacion #' ||
                                  c_rspnsbles.idntfccion_rspnsble;
                insert into mc_g_embrgo_cnddtos_no_crgdos
                  (cdgo_clnte,
                   idntfccion_sjto,
                   vgncia_dsde,
                   vgncia_hsta,
                   fcha,
                   obsrvcion)
                values
                  (p_cdgo_clnte,
                   c_sjtos.idntfccion,
                   c_sjtos.vgncia_dsde,
                   c_sjtos.vgncia_hsta,
                   systimestamp,
                   o_cdgo_rspsta || ' ' || o_mnsje_rspsta);
                commit;
            end;
          end loop;
        
          -- 3. Insertar los movimientos
          for c_mvmntos in (select id_sjto_impsto,
                                   vgncia,
                                   id_prdo,
                                   id_cncpto,
                                   vlor_sldo_cptal,
                                   vlor_intres,
                                   cdgo_clnte,
                                   id_impsto,
                                   id_impsto_sbmpsto,
                                   cdgo_mvmnto_orgn,
                                   id_orgen,
                                   id_mvmnto_fncro
                              from v_gf_g_cartera_x_concepto
                             where cdgo_clnte = p_cdgo_clnte
                               and id_impsto = c_sjtos.id_impsto
                               and id_impsto_sbmpsto =
                                   c_sjtos.id_impsto_sbmpsto
                               and id_sjto_impsto = v_id_sjto_impsto
                               and vgncia between c_sjtos.vgncia_dsde and
                                   c_sjtos.vgncia_hsta
                               and (vlor_sldo_cptal + vlor_intres) > 0
                               and trunc(fcha_vncmnto) < trunc(sysdate)) loop
          
            begin
              insert into mc_g_embargos_smu_mvmnto
                (id_embrgos_smu_sjto,
                 id_sjto_impsto,
                 vgncia,
                 id_prdo,
                 id_cncpto,
                 vlor_cptal,
                 vlor_intres,
                 cdgo_clnte,
                 id_impsto,
                 id_impsto_sbmpsto,
                 cdgo_mvmnto_orgn,
                 id_orgen,
                 id_mvmnto_fncro)
              values
                (v_id_embrgos_smu_sjto,
                 c_mvmntos.id_sjto_impsto,
                 c_mvmntos.vgncia,
                 c_mvmntos.id_prdo,
                 c_mvmntos.id_cncpto,
                 c_mvmntos.vlor_sldo_cptal,
                 c_mvmntos.vlor_intres,
                 c_mvmntos.cdgo_clnte,
                 c_mvmntos.id_impsto,
                 c_mvmntos.id_impsto_sbmpsto,
                 c_mvmntos.cdgo_mvmnto_orgn,
                 c_mvmntos.id_orgen,
                 c_mvmntos.id_mvmnto_fncro);
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 55;
                o_mnsje_rspsta := 'Error mientras se intentaba incluir movimientos de cartera al sujeto #' ||
                                  v_id_embrgos_smu_sjto;
                commit;
                insert into mc_g_embrgo_cnddtos_no_crgdos
                  (cdgo_clnte,
                   idntfccion_sjto,
                   vgncia_dsde,
                   vgncia_hsta,
                   fcha,
                   obsrvcion)
                values
                  (p_cdgo_clnte,
                   c_sjtos.idntfccion,
                   c_sjtos.vgncia_dsde,
                   c_sjtos.vgncia_hsta,
                   systimestamp,
                   o_cdgo_rspsta || ' ' || o_mnsje_rspsta);
            end;
          end loop;
        else
          rollback;
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'El sujeto no tiene saldo en cartera #' ||
                            c_sjtos.id_sjto;
          insert into mc_g_embrgo_cnddtos_no_crgdos
            (cdgo_clnte,
             idntfccion_sjto,
             vgncia_dsde,
             vgncia_hsta,
             fcha,
             obsrvcion)
          values
            (p_cdgo_clnte,
             c_sjtos.idntfccion,
             c_sjtos.vgncia_dsde,
             c_sjtos.vgncia_hsta,
             systimestamp,
             o_cdgo_rspsta || ' ' || o_mnsje_rspsta);
          commit;
        end if;
      end loop;
    elsif v_cdgo_prcso = 'FIS' then
      --  Si el proceso es del modulo de FISCALIZACION (FIS)
    
      begin
        -- 3. Se eliminan los sujetos (que no han sido procesados) en el lote que 
        -- no se encuentren en la información cargada del archivo.
        update fi_g_candidatos a
           set a.actvo = 'N'
         where a.id_fsclzcion_lte = p_id_lte
           and a.indcdor_asgndo = 'N'
           and a.actvo = 'S'
           and not exists (select 1
                  from v_gn_g_candidatos_carga c
                  join si_c_sujetos d
                    on d.idntfccion = c.idntfccion
                  join si_i_sujetos_impuesto e
                    on d.id_sjto = e.id_sjto
                 where e.id_sjto_impsto = a.id_sjto_impsto
                   and c.id_prcso_crga = p_id_prcso_crga
                   and c.id_lte_prcso = p_id_lte
                   and c.cdgo_prcso = v_cdgo_prcso);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '-Error al intentar eliminar los candidatos que no estan en el archivo cargado.' ||
                            sqlerrm;
          return;
      end;
    
      -- Incluir sujetos del archivo que no estan en el lote
      for c_sjtos_archvo in (select e.id_sjto_impsto
                               from v_gn_g_candidatos_carga c
                               join si_c_sujetos d
                                 on d.idntfccion = c.idntfccion
                               join si_i_sujetos_impuesto e
                                 on d.id_sjto = e.id_sjto
                              where c.id_prcso_crga = p_id_prcso_crga
                                and c.id_lte_prcso = p_id_lte
                                and c.cdgo_prcso = v_cdgo_prcso
                                and exists
                              (select 1
                                       from fi_g_candidatos j
                                      where j.id_sjto_impsto =
                                            e.id_sjto_impsto
                                        and j.id_fsclzcion_lte =
                                            c.id_lte_prcso
                                        and j.actvo = 'N'
                                        and j.indcdor_asgndo = 'N')) loop
      
        o_mnsje_rspsta := 'id_sjto_impsto: ' ||
                          c_sjtos_archvo.id_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        -- Los que esten inactivos pero vinieron en el archivo se vuelven a activar
        update fi_g_candidatos a
           set a.actvo = 'S'
         where a.id_fsclzcion_lte = p_id_lte
           and a.id_sjto_impsto = c_sjtos_archvo.id_sjto_impsto
           and a.indcdor_asgndo = 'N'
           and a.actvo = 'N';
      end loop;
    
      -- INSERTAR en el Lote ... los Nuevos Sujeto que vinieron en el Excel y No estaban en el Lote
      for c_sjtos_archvo in (select c.idntfccion,
                                    c.vgncia_dsde,
                                    c.vgncia_hsta,
                                    d.id_sjto,
                                    c.id_impsto,
                                    c.id_impsto_sbmpsto,
                                    c.periodo,
                                    c.cdgo_prdcdad,
                                    c.cdgo_prgrma,
                                    c.cdgo_subprgrma,
                                    c.cdgo_trbto_acto,
                                    c.fcha_expdcion,
                                    c.nmro_rnta
                               from v_gn_g_candidatos_carga c
                               join si_c_sujetos d
                                 on d.idntfccion = c.idntfccion
                              where c.id_prcso_crga = p_id_prcso_crga
                                and c.id_lte_prcso = p_id_lte
                                and c.cdgo_prcso = v_cdgo_prcso
                                and not exists
                              (select 1
                                       from fi_g_candidatos a
                                       join si_i_sujetos_impuesto b
                                         on a.id_sjto_impsto =
                                            b.id_sjto_impsto
                                        and b.id_sjto = d.id_sjto
                                      where a.id_fsclzcion_lte = p_id_lte)) loop
        -- *************************************
        -- incluimos Sujetos
        -- *************************************
        -- <Identificar Sujeto Impuesto>
        begin
          select a.id_prgrma, a.id_sbprgrma
          --,b.cdgo_prgrma
          --,c.cdgo_sbprgrma
            into v_id_prgrma, v_id_sbprgrma
          --,v_cdgo_prgrma
          --,v_cdgo_sbprgrma
            from fi_g_fiscalizacion_lote a
          --join fi_d_programas b   on a.id_prgrma = b.id_prgrma
          -- join fi_d_subprogramas  c   on  a.id_sbprgrma = c.id_sbprgrma
           where id_fsclzcion_lte = p_id_lte;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo obtener el programa y subprograma del lote';
            continue;
        end;
      
        o_mnsje_rspsta := 'v_id_prgrma: ' || v_id_prgrma ||
                          ', v_id_sbprgrma: ' || v_id_sbprgrma;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        o_mnsje_rspsta := 'id_impsto: ' || c_sjtos_archvo.id_impsto ||
                          ', id_sjto: ' || c_sjtos_archvo.id_sjto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        begin
          select a.id_sjto_impsto
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto a
           where a.id_impsto = c_sjtos_archvo.id_impsto
             and a.id_sjto = c_sjtos_archvo.id_sjto;
        exception
          when others then
            o_cdgo_rspsta  := 35;
            o_mnsje_rspsta := 'No se pudo identificar el sujeto impuesto asociado al ID SUJETO 4 #' ||
                              c_sjtos_archvo.id_sjto;
            continue;
        end;
        o_mnsje_rspsta := 'v_id_sjto_impsto: ' || v_id_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        -- FIN <Identificar Sujeto Impuesto>
      
        o_mnsje_rspsta := 'periodo: ' || c_sjtos_archvo.periodo ||
                          ', cdgo_prdcdad: ' || c_sjtos_archvo.cdgo_prdcdad ||
                          ', vgncia_dsde: ' || c_sjtos_archvo.vgncia_dsde ||
                          ', vgncia_hsta: ' || c_sjtos_archvo.vgncia_hsta ||
                          ', id_impsto: ' || c_sjtos_archvo.id_impsto ||
                          ', id_impsto_sbmpsto: ' ||
                          c_sjtos_archvo.id_impsto_sbmpsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        -- consultar el id periodo y vigencias a fiscalizar
        if (c_sjtos_archvo.periodo is not null and
           c_sjtos_archvo.cdgo_prdcdad is not null) then
          begin
            SELECT id_prdo
              into v_id_prdo
              FROM df_i_periodos
             where prdo = c_sjtos_archvo.periodo
               and cdgo_prdcdad = c_sjtos_archvo.cdgo_prdcdad
               and vgncia = c_sjtos_archvo.vgncia_dsde
               and id_impsto = c_sjtos_archvo.id_impsto
               and id_impsto_sbmpsto = c_sjtos_archvo.id_impsto_sbmpsto;
          exception
            when others then
              o_cdgo_rspsta  := 40;
              o_mnsje_rspsta := 'Error al consultar el id periodo';
              continue;
          end;
        
          o_mnsje_rspsta := 'v_id_prdo: ' || v_id_prdo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
        end if;
      
        o_mnsje_rspsta := 'cdgo_prgrma: ' || c_sjtos_archvo.cdgo_prgrma ||
                          ' ó cdgo_subprgrma: ' ||
                          c_sjtos_archvo.cdgo_subprgrma;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        --Se validad que el sujeto tenga declaraciones pendientes
        case
          when c_sjtos_archvo.cdgo_prgrma = 'O' then
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     id_dclrcion_vgncia_frmlrio,
                                     id_dclrcion
                                from v_fi_g_pblcion_omsos_cncdos
                               where /*cdgo_clnte = p_cdgo_clnte 
                                                                      and*/
                               id_sjto_impsto = v_id_sjto_impsto
                           and vgncia between c_sjtos_archvo.vgncia_dsde and
                               nvl(c_sjtos_archvo.vgncia_hsta,
                                   c_sjtos_archvo.vgncia_dsde)
                           and id_prdo = nvl(v_id_prdo, id_prdo)
                           and cdgo_prdcdad =
                               nvl(c_sjtos_archvo.cdgo_prdcdad, cdgo_prdcdad)) loop
            
              -- FIN <Validar cartera>
            
              -- SI tiene declaraciones 
            
              -- 1. Incluir sujeto
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo
                   and a.id_dclrcion_vgncia_frmlrio =
                       c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       id_dclrcion_vgncia_frmlrio)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       c_canddto.id_dclrcion_vgncia_frmlrio);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              commit;
            end loop;
          when c_sjtos_archvo.cdgo_prgrma = 'I' then
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     id_dclrcion_vgncia_frmlrio,
                                     id_dclrcion
                                from v_fi_g_pblcion_inxctos
                               where /*cdgo_clnte = p_cdgo_clnte 
                                                                          and*/
                               id_sjto_impsto = v_id_sjto_impsto
                           and vgncia between c_sjtos_archvo.vgncia_dsde and
                               nvl(c_sjtos_archvo.vgncia_hsta,
                                   c_sjtos_archvo.vgncia_dsde)
                           and id_prdo = nvl(v_id_prdo, id_prdo)
                           and cdgo_prdcdad =
                               nvl(c_sjtos_archvo.cdgo_prdcdad, cdgo_prdcdad)) loop
            
              -- FIN <Validar cartera>
            
              -- SI tiene declaraciones 
            
              -- 1. Incluir sujeto
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo
                   and a.id_dclrcion_vgncia_frmlrio =
                       c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       id_dclrcion_vgncia_frmlrio,
                       id_dclrcion)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       c_canddto.id_dclrcion_vgncia_frmlrio,
                       c_canddto.id_dclrcion);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              commit;
            end loop;
          when c_sjtos_archvo.cdgo_subprgrma = 'SML' THEN
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     id_dclrcion_vgncia_frmlrio,
                                     id_dclrcion
                                from v_fi_g_pbl_sncn_sncn_mal_lqdda
                               where /*cdgo_clnte = p_cdgo_clnte
                                                          and*/
                               id_sjto_impsto = v_id_sjto_impsto
                           and vgncia between c_sjtos_archvo.vgncia_dsde and
                               nvl(c_sjtos_archvo.vgncia_hsta,
                                   c_sjtos_archvo.vgncia_dsde)
                           and id_prdo = nvl(v_id_prdo, id_prdo)
                           and cdgo_prdcdad =
                               nvl(c_sjtos_archvo.cdgo_prdcdad, cdgo_prdcdad)) loop
            
              -- FIN <Validar cartera>
            
              -- SI tiene declaraciones 
            
              -- 1. Incluir sujeto
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo
                   and a.id_dclrcion_vgncia_frmlrio =
                       c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       id_dclrcion_vgncia_frmlrio,
                       id_dclrcion)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       c_canddto.id_dclrcion_vgncia_frmlrio,
                       c_canddto.id_dclrcion);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              commit;
            end loop;
          when c_sjtos_archvo.cdgo_subprgrma = 'EXT' THEN
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     id_dclrcion_vgncia_frmlrio,
                                     id_dclrcion
                                from v_fi_g_pblcion_sncntr_extmprn
                               where /*cdgo_clnte = p_cdgo_clnte
                                                          and*/
                               id_sjto_impsto = v_id_sjto_impsto
                           and vgncia between c_sjtos_archvo.vgncia_dsde and
                               nvl(c_sjtos_archvo.vgncia_hsta,
                                   c_sjtos_archvo.vgncia_dsde)
                           and id_prdo = nvl(v_id_prdo, id_prdo)
                           and cdgo_prdcdad =
                               nvl(c_sjtos_archvo.cdgo_prdcdad, cdgo_prdcdad)) loop
            
              -- FIN <Validar cartera>
            
              -- SI tiene declaraciones 
            
              -- 1. Incluir sujeto
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo
                   and a.id_dclrcion_vgncia_frmlrio =
                       c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       id_dclrcion_vgncia_frmlrio,
                       id_dclrcion)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       c_canddto.id_dclrcion_vgncia_frmlrio,
                       c_canddto.id_dclrcion);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              commit;
            end loop;
          when c_sjtos_archvo.cdgo_subprgrma = 'NEI' THEN
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     id_dclrcion_vgncia_frmlrio
                                     --,id_dclrcion
                                from v_fi_g_pbl_sncn_no_enviar_info
                               where id_sjto_impsto = v_id_sjto_impsto
                                and id_impsto = c_sjtos_archvo.id_impsto
                                and id_impsto_sbmpsto = c_sjtos_archvo.id_impsto_sbmpsto
                                and vgncia between c_sjtos_archvo.vgncia_dsde and nvl(c_sjtos_archvo.vgncia_hsta,
                                                                                       c_sjtos_archvo.vgncia_dsde)
                               and cdgo_prdcdad = nvl(cdgo_prdcdad, c_sjtos_archvo.cdgo_prdcdad)
                               and id_prdo = nvl(id_prdo , v_id_prdo)
            ) loop
            
              -- FIN <Validar cartera>
            
              -- SI tiene declaraciones 
            
              -- 1. Incluir sujeto
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo
                   and a.id_dclrcion_vgncia_frmlrio =
                       c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       id_dclrcion_vgncia_frmlrio
                       )--id_dclrcion)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       c_canddto.id_dclrcion_vgncia_frmlrio
                       );--c_canddto.id_dclrcion);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              commit;
            end loop;
          when c_sjtos_archvo.cdgo_prgrma = 'OLQ' THEN
            o_mnsje_rspsta := 'cdgo_trbto_acto: ' ||
                              c_sjtos_archvo.cdgo_trbto_acto ||
                              ', fcha_expdcion: ' ||
                              c_sjtos_archvo.fcha_expdcion ||
                              ', nmro_rnta: ' || c_sjtos_archvo.nmro_rnta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            for c_canddto in (select vgncia,
                                     id_prdo,
                                     nmro_rnta,
                                     to_char(fcha_rgstro, 'DD/MM/YY') as fcha_expdcion
                                from v_fi_g_pblcion_omsos_lqddos
                               where id_sjto_impsto = v_id_sjto_impsto
                                    --and vgncia between c_sjtos_archvo.vgncia_dsde and nvl(c_sjtos_archvo.vgncia_hsta, c_sjtos_archvo.vgncia_dsde)
                                    --and id_prdo =  nvl(v_id_prdo, id_prdo)
                                    --and cdgo_prdcdad =  nvl(c_sjtos_archvo.cdgo_prdcdad, cdgo_prdcdad)
                                 and cdgo_impsto_acto =
                                     nvl(c_sjtos_archvo.cdgo_trbto_acto,
                                         cdgo_impsto_acto)
                                    --and to_char (fcha_rgstro, 'DD/MM/YY') = nvl(to_char (c_sjtos_archvo.fcha_expdcion, 'DD/MM/YY'), to_char (fcha_rgstro, 'DD/MM/YY'))
                                 and nmro_rnta =
                                     nvl(c_sjtos_archvo.nmro_rnta, nmro_rnta)) loop
              -- FIN <Validar cartera>
              -- 1. Incluir sujeto
            
              o_mnsje_rspsta := 'vgncia: ' || c_canddto.vgncia ||
                                ', id_prdo: ' || c_canddto.id_prdo;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            
              begin
                select a.id_cnddto
                  into v_id_cnddto
                  from fi_g_candidatos a
                 where a.id_sjto_impsto = v_id_sjto_impsto
                   and a.id_impsto = c_sjtos_archvo.id_impsto
                   and a.id_prgrma = v_id_prgrma
                   and a.id_fsclzcion_lte = p_id_lte;
              exception
                when no_data_found then
                  --Se inserta los candidatos
                  begin
                    insert into fi_g_candidatos
                      (id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       id_fsclzcion_lte,
                       cdgo_cnddto_estdo,
                       indcdor_asgndo,
                       id_prgrma,
                       id_sbprgrma,
                       cdgo_clnte)
                    values
                      (c_sjtos_archvo.id_impsto,
                       c_sjtos_archvo.id_impsto_sbmpsto,
                       v_id_sjto_impsto,
                       p_id_lte,
                       'ACT',
                       'N',
                       v_id_prgrma,
                       v_id_sbprgrma,
                       p_cdgo_clnte)
                    returning id_cnddto into v_id_cnddto;
                  exception
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo guardar el candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion;
                      rollback;
                      continue;
                  end;
              end;
            
              o_mnsje_rspsta := 'v_id_cnddto: ' || v_id_cnddto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            
              -- 2. Incluir las vigencias
              begin
                select a.id_cnddto_vgncia
                  into v_id_cnddto_vgncia
                  from fi_g_candidatos_vigencia a
                 where a.id_cnddto = v_id_cnddto
                   and a.vgncia = c_canddto.vgncia
                   and a.id_prdo = c_canddto.id_prdo; --and   a.id_dclrcion_vgncia_frmlrio = c_canddto.id_dclrcion_vgncia_frmlrio;
              exception
                when no_data_found then
                  --Se inserta las vigencia periodo de los candidatos
                  begin
                    insert into fi_g_candidatos_vigencia
                      (id_cnddto,
                       vgncia,
                       id_prdo,
                       indcdor_fsclzcion_tpo,
                       fcha_expdcion,
                       nmro_rnta)
                    values
                      (v_id_cnddto,
                       c_canddto.vgncia,
                       c_canddto.id_prdo,
                       'LQ',
                       c_canddto.fcha_expdcion,
                       c_canddto.nmro_rnta);
                  exception
                    when others then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se pudo registrar las vigencia periodo del candidato con identificación ' || '-' ||
                                        c_sjtos_archvo.idntfccion || '-' ||
                                        sqlerrm;
                      rollback;
                      continue;
                  end;
              end;
              o_mnsje_rspsta := 'v_id_cnddto_vgncia: ' ||
                                v_id_cnddto_vgncia;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            
              commit;
            end loop;
          else
            null;
        end case;
      
      end loop;
    end if;
  
    commit;

  
  exception
    when e_no_encuentra_lote then
      o_cdgo_rspsta  := 97;
      o_mnsje_rspsta := 'No se ha especificado un lote valido.';
    when e_no_archivo_excel then
      o_cdgo_rspsta  := 98;
      o_mnsje_rspsta := 'El archivo cargado no es un archivo EXCEL.';
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'No se pudo procesar la seleccion de candidatos por medio del cargue de archivo.';
  end prc_rg_seleccion_cnddts_archvo;
    
    function fnc_cl_antrior_dia_habil(p_cdgo_clnte number, p_fecha in date) return date is
		
        /*
          Autor : BVILLEGAS
          Creado : 21/09/2023
          Descripción: Función que devuelve el anterior día hábil a partir de una fecha
        */
        v_fecha_habil  date;
    
    begin        
        for c_calendario_general in (select max(a.fcha) as fecha_habil
                                       from df_c_calendario_general a
                                      where a.cdgo_clnte = p_cdgo_clnte
                                        and trunc(a.fcha) <=  trunc(p_fecha)
                                        and a.indcdor_lboral = 'S') loop
            
            v_fecha_habil := c_calendario_general.fecha_habil;
        end loop;
        
        return v_fecha_habil;
    end fnc_cl_antrior_dia_habil;

end pkg_gn_generalidades; -- Fin del Paquere pkg_gn_generalidades

/
