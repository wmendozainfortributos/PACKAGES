--------------------------------------------------------
--  DDL for Package Body PKG_GJ_JSON_ACCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GJ_JSON_ACCIONES" as

  function fnc_gn_json_vigencias_ajuste(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob as
    v_json clob := null;
    v_nmbre_prmtro varchar2(500);
  begin
  
    begin
        select nmbre_prmtro
        into v_nmbre_prmtro
        from gj_d_parametros
        where id_prmtro = p_id_prmtro;
    exception
        when others then
            return null;
    end;
    
    begin
        select json_object(v_nmbre_prmtro value(
            select json_arrayagg( 
                json_object(
                    'VGNCIA' value vgncia,
                    'ID_PRDO' value id_prdo,
                    'ID_CNCPTO' value id_cncpto,
                    'VLOR_SLDO_CPTAL' value vlor_sldo_cptal,
                    'VLOR_AJSTE' value vlor_ajste
                )
            )from gj_g_rcrsos_accn_vgnc_cncpt
            where id_rcrso_accion = p_id_rcrso_accion
        ))
        into v_json
        from dual;
    exception
        when others then
            v_json := null;
    end;
    
    return v_json;
    
  end fnc_gn_json_vigencias_ajuste;
  
  function fnc_gn_json_id_ajuste_motivo(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob as
    v_json          varchar2(32000);
    v_id_ajste_mtvo number;
    v_orgen         gf_d_ajuste_motivo.orgen%type;
    v_tpo_ajste     gf_d_ajuste_motivo.tpo_ajste%type;
    v_json_object   JSON_OBJECT_T;
  begin
    
    v_json_object := JSON_OBJECT_T('{}');
    --Consultamos el Id Ajuste Motivo
    begin
        select id_ajste_mtvo
        into v_id_ajste_mtvo
        from gj_g_recursos_accion
        where id_rcrso_accion = p_id_rcrso_accion;
    end;
    
    --Consultamos el Ajuste Motivo
    begin
        select orgen, tpo_ajste
        into v_orgen, v_tpo_ajste
        from gf_d_ajuste_motivo
        where id_ajste_mtvo = v_id_ajste_mtvo;
    exception
        when no_data_found then
            v_orgen := null; v_tpo_ajste := null;
    end;
    v_json_object.put('id_ajste_mtvo', v_id_ajste_mtvo);
    v_json_object.put('orgen', v_orgen);
    v_json_object.put('tpo_ajste', v_tpo_ajste);
    
    v_json := v_json_object.stringify;
    return v_json;
  end fnc_gn_json_id_ajuste_motivo;
  
  function fnc_gn_json_acto_resolucion(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob as
    v_json          clob;
    v_json_object   JSON_OBJECT_T;
    --
    v_id_acto       gn_g_actos.id_acto%type;
    v_id_acto_tpo   gn_g_actos.id_acto_tpo%type;
    v_fcha          timestamp;
    --Manejo de Errores
    v_cdgo_rspsta   number;
    v_mnsje_rspsta  varchar2(3000);
  begin

    v_json_object := JSON_OBJECT_T('{}');
    
    --Consultamos el Acto que Resuelve el Recurso
    pkg_gj_recurso.prc_co_acto_resolucion(
        p_cdgo_clnte			=> p_cdgo_clnte,
        p_id_instncia_fljo		=> p_id_instncia_fljo,
        o_id_acto               => v_id_acto,
        o_id_acto_tpo           => v_id_acto_tpo,
        o_fcha                  => v_fcha,
        o_cdgo_rspsta			=> v_cdgo_rspsta,
        o_mnsje_rspsta          => v_mnsje_rspsta
    );
    
    if(v_cdgo_rspsta != 0)then
        return v_json;
    end if;
    
    v_json_object.put('tpo_dcmnto_sprte', v_id_acto);
    v_json_object.put('nmro_dcmto_sprte', v_id_acto);
    v_json_object.put('fcha_dcmnto_sprte', to_char(v_fcha,'dd/MM/yyyy HH:MI:SS'));
    
     v_json := v_json_object.stringify;
     
    return v_json;
  end fnc_gn_json_acto_resolucion;
  
end pkg_gj_json_acciones;

/
