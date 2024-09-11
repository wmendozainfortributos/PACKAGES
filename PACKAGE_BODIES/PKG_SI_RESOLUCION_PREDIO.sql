--------------------------------------------------------
--  DDL for Package Body PKG_SI_RESOLUCION_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SI_RESOLUCION_PREDIO" as

  /*
  * @Descripcion  : Registro de Resolucion
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  function fnc_vl_vgncia_lqdcion(p_cdgo_clnte        in number,
                                 p_id_impsto         in number,
                                 p_id_impsto_sbmpsto in number,
                                 p_rslcion           in number,
                                 p_rdccion           in number,
                                 p_max_vgncia        in number,
                                 p_vlor_vgncia_mnma  in number) return number as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.fnc_vl_vgncia_lqdcion';
    -- Para validar desde cual vigencia se va a liquidar y si se tiene en cuenta la minima vigencia con deuda de los predios Cabcela
    v_min_vgncia             number;
    v_vlor_vgncia_estdo_cnta varchar2(1);
    v_exste_cncla            number;
  begin

    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);

    --Busca la Definicion de Vigencia Minima para Estado de Cuenta de  Predios Cancela
    v_vlor_vgncia_estdo_cnta := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                                p_cdgo_dfncion_clnte        => 'VEC');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => 'p_vlor_vgncia_mnma: ' ||
                                          p_vlor_vgncia_mnma,
                          p_nvel_txto  => 1);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => 'v_vlor_vgncia_estdo_cnta: ' ||
                                          v_vlor_vgncia_estdo_cnta,
                          p_nvel_txto  => 1);

    -- Valida si existe registros CANCELA, sino entonces solo son Inscripciones 
    -- y por tanto se debe liquidar las vigencias del tipo III
    select count(1)
      into v_exste_cncla
      from si_g_resolucion_igac_t1 a
      join v_si_i_sujetos_impuesto c on c.cdgo_clnte = p_cdgo_clnte 
                                    and c.idntfccion_sjto = a.rfrncia_igac
     where a.id_prcso_crga in
           (select b.id_prcso_crga
              from et_g_procesos_carga b
             where b.id_prcso_crga = a.id_prcso_crga
               and b.cdgo_clnte = p_cdgo_clnte
               and b.id_impsto = p_id_impsto
               and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
       and a.rslcion = p_rslcion
       and a.rdccion = p_rdccion
       and a.cncla_inscrbe = 'C'
       and a.nmro_orden = '001';

    -- Si valida estado de cuenta de predios Cancela
    if (v_vlor_vgncia_estdo_cnta = 'S' and v_exste_cncla > 0) then

      --buscar la minima vigencia con deuda del estado de cuenta de los predios Cancela
      select min(vgncia)
        into v_min_vgncia
        from gf_g_mvmntos_cncpto_cnslddo a
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and id_sjto_impsto in
             (select c.id_sjto_impsto
                from si_g_resolucion_igac_t1 a
                join v_si_i_sujetos_impuesto c on c.cdgo_clnte = p_cdgo_clnte 
                                              and c.idntfccion_sjto = a.rfrncia_igac
               where a.id_prcso_crga in
                     (select b.id_prcso_crga
                        from et_g_procesos_carga b
                       where b.id_prcso_crga = a.id_prcso_crga
                         and b.cdgo_clnte = p_cdgo_clnte
                         and b.id_impsto = p_id_impsto
                         and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                 and a.rslcion = p_rslcion
                 and a.rdccion = p_rdccion
                 and a.cncla_inscrbe = 'C'
                 and a.nmro_orden = '001')
         and a.cdgo_mvnt_fncro_estdo != 'AN'
         and vlor_sldo_cptal > 0;

      -- Si no tienen deuda los predios Cancela, no se liquida ninguna vigencia
      if (v_min_vgncia is null) then
        v_min_vgncia := p_max_vgncia + 1;
      else
        if (v_min_vgncia < p_max_vgncia - p_vlor_vgncia_mnma) then
          v_min_vgncia := p_max_vgncia - p_vlor_vgncia_mnma;
        end if;
      end if;
    else
      v_min_vgncia := p_max_vgncia - p_vlor_vgncia_mnma;
    end if;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => 'v_min_vgncia: ' || v_min_vgncia,
                          p_nvel_txto  => 1);

    return v_min_vgncia;

  end fnc_vl_vgncia_lqdcion;

  procedure prc_rg_resolucion_etl(p_cdgo_clnte    in df_s_clientes.cdgo_clnte%type,
                                  p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type,
                                  o_cdgo_rspsta   out number,
                                  o_mnsje_rspsta  out varchar2) as
    v_nvel                number;
    v_nmbre_up            sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_rg_resolucion_etl';
    v_et_g_procesos_carga et_g_procesos_carga%rowtype;
    v_drctrio             df_s_definiciones.vlor%type := 'DIR_ETL';

    type r_rslcion is record(
      tpo_rgstro    si_g_resolucion_igac.tpo_rgstro%type,
      rslcion_dtlle clob);

    type t_rslcion is table of r_rslcion index by pls_integer;

    v_rslcion t_rslcion;
  begin

    --Respuesta Exitosa
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

    --Verifica si el Archivo es una Resolucion General
    declare
      v_cntdad number;
    begin
      select count(*)
        into v_cntdad
        from df_s_resolucion_carga
       where id_crga_pdre in
             (select id_crga
                from et_g_procesos_carga
               where id_prcso_crga = p_id_prcso_crga);

      if (v_cntdad = 0) then
        --Nada que Hacer si el Archivo no es Una Resolucion General
        return;
      end if;
    end;

    --Busca los datos del Archivo ETL
    begin
      select *
        into v_et_g_procesos_carga
        from et_g_procesos_carga
       where id_prcso_crga = p_id_prcso_crga
         and indcdor_prcsdo = 'N';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El archivo #' ||
                          p_id_prcso_crga ||
                          ' de resolucion, ya se encuentra procesado o no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Verifica si el Impuesto y SubImpuesto son Nulos
    if (v_et_g_procesos_carga.id_impsto is null or
       v_et_g_procesos_carga.id_impsto_sbmpsto is null) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta || '. Para el archivo #' ||
                        p_id_prcso_crga ||
                        ' de resolucion, el campo impuesto y subimpuesto es requerido para este tipo de carga.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;

    --Busca el Valor del Directorio
    begin
      select vlor
        into v_drctrio
        from df_s_definiciones
       where cdgo_dfncion = v_drctrio;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El directorio de oracle [' ||
                          v_drctrio || '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Almacena la Coleccion de Resoluciones
    with w_a as
     (select a.id_rslcion_igac, a.rslcion, a.rdccion, a.tpo_rgstro, a.lnea
        from si_g_resolucion_igac a
       where a.id_prcso_crga = p_id_prcso_crga)
    select a.tpo_rgstro,
           json_arrayagg(json_object('id_rslcion_igac' value
                                     a.id_rslcion_igac,
                                     'lnea' value a.lnea) returning clob) as rslcion_dtlle
      bulk collect
      into v_rslcion
      from w_a a
     where (a.rslcion, a.rdccion) in
           (select a.rslcion, a.rdccion
              from w_a a
             where a.tpo_rgstro = 1
             group by a.rslcion, a.rdccion)
       and not (a.rslcion, a.rdccion) in
            (select a.rslcion, a.rdccion
                  from si_g_resolucion_igac_t1 a
                 where a.id_prcso_crga in
                       (select b.id_prcso_crga
                          from et_g_procesos_carga b
                         where b.id_prcso_crga = a.id_prcso_crga
                           and b.cdgo_clnte = p_cdgo_clnte
                           and b.id_impsto = v_et_g_procesos_carga.id_impsto
                           and b.id_impsto_sbmpsto =
                               v_et_g_procesos_carga.id_impsto_sbmpsto)
                 group by a.rslcion, a.rdccion)
     group by a.tpo_rgstro
     order by a.tpo_rgstro;

    --Verifica si no Hay Resoluciones por Registrar
    if (v_rslcion.count = 0) then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible procesar el archivo, ya que las resoluciones se encuentran registrada en el sistema o no hay registros tipo (1).';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;

    --Cursor de Resoluciones por Tipo
    for i in 1 .. v_rslcion.count loop
      declare
        v_id_crga       et_g_carga.id_crga%type;
        v_file_name     et_g_procesos_carga.file_name%type;
        v_archvo        utl_file.file_type;
        v_bfile         bfile;
        v_file_blob     blob;
        v_id_prcso_crga et_g_procesos_carga.id_prcso_crga%type;
      begin

        --Busca si de Carga Existe
        begin
          select id_crga
            into v_id_crga
            from df_s_resolucion_carga
           where id_crga_pdre = v_et_g_procesos_carga.id_crga
             and tpo_rgstro = v_rslcion(i).tpo_rgstro;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. La carga de ETL, resolucion tipo [' || v_rslcion(i).tpo_rgstro ||
                              '] no se encuentra parametrizada en tipos de resoluciones por carga.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
        end;

        --Nombre de la Resolucion
        v_file_name := 'R' || v_rslcion(i).tpo_rgstro || '-' ||
                       v_et_g_procesos_carga.file_name;

        --Archivo
        v_archvo := utl_file.fopen(v_drctrio, v_file_name, 'w');

        --Cursor de Lineas de Resoluciones por Tipos
        for c_lneas in (select a.*
                          from json_table(v_rslcion(i).rslcion_dtlle,
                                          '$[*]'
                                          columns(id_rslcion_igac number path
                                                  '$.id_rslcion_igac',
                                                  lnea varchar path '$.lnea')) a) loop
          --Escribe los Datos del Archivo
          utl_file.put_line(v_archvo, c_lneas.lnea);

          --Marca las Resoluciones Validas
          update si_g_resolucion_igac
             set indcdor_prcsdo = 'S'
           where id_rslcion_igac = c_lneas.id_rslcion_igac;

        end loop;

        --Cierra el Archivo
        utl_file.fclose(v_archvo);

        --Guarda el Proceso Carga
        begin
          insert into et_g_procesos_carga
            (id_crga,
             cdgo_clnte,
             id_impsto,
             vgncia,
             file_blob,
             file_name,
             file_mimetype,
             cdgo_prcso_estdo,
             lneas_encbzdo,
             id_impsto_sbmpsto,
             id_prdo,
             id_usrio,
             id_prcso_crga_pdre,
             indcdor_prcsdo)
          values
            (v_id_crga,
             p_cdgo_clnte,
             v_et_g_procesos_carga.id_impsto,
             v_et_g_procesos_carga.vgncia,
             empty_blob(),
             v_file_name,
             v_et_g_procesos_carga.file_mimetype,
             'SE',
             v_et_g_procesos_carga.lneas_encbzdo,
             v_et_g_procesos_carga.id_impsto_sbmpsto,
             v_et_g_procesos_carga.id_prdo,
             v_et_g_procesos_carga.id_usrio,
             p_id_prcso_crga,
             'S')
          returning id_prcso_crga, file_blob into v_id_prcso_crga, v_file_blob;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el proceso carga, para la resolucion tipo [' || v_rslcion(i).tpo_rgstro || '].';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;

        --Apuntador del Archivo
        v_bfile := bfilename(v_drctrio, v_file_name);

        --Abrir Apuntador del Archivo
        dbms_lob.open(v_bfile, dbms_lob.lob_readonly);

        dbms_lob.loadfromfile(dest_lob => v_file_blob,
                              src_lob  => v_bfile,
                              amount   => dbms_lob.getlength(v_bfile));

        --Cerrar Apuntador del Archivo
        dbms_lob.close(v_bfile);

        --Pasa el Archivo a Intermedia
        pk_etl.prc_carga_intermedia_from_dir(p_cdgo_clnte    => p_cdgo_clnte,
                                             p_id_prcso_crga => v_id_prcso_crga);

        --Pasa el Archivo a Gestion  
        pk_etl.prc_carga_gestion(p_cdgo_clnte    => p_cdgo_clnte,
                                 p_id_prcso_crga => v_id_prcso_crga);

        --Verifica si la Resolucion Procesada Tiene Errores de Validacion
        declare
          v_error number;
        begin
          select count(*)
            into v_error
            from et_g_procesos_carga_error
           where id_prcso_crga = v_id_prcso_crga;

          if (v_error > 0) then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta || '. La resolucion tipo [' || v_rslcion(i).tpo_rgstro ||
                              '] contiene errores de validacion, por favor verifique e intente de nuevo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
        end;

        --Actualiza las Resoluciones Hijas
        --Resolucion Predios
        if (v_rslcion(i).tpo_rgstro = 1) then

          --Actualiza el Padre R1
          update si_g_resolucion_igac_t1
             set id_prcso_crga_pdre = p_id_prcso_crga
           where id_prcso_crga = v_id_prcso_crga;

          --Resolucion Tipo 2 Matriculas
        elsif (v_rslcion(i).tpo_rgstro = 2) then

          --Actualiza el Padre R2
          update si_g_resolucion_igac_t2
             set id_prcso_crga_pdre = p_id_prcso_crga
           where id_prcso_crga = v_id_prcso_crga;

          --Resolucion Tipo 3 Decretos
        elsif (v_rslcion(i).tpo_rgstro = 3) then

          --Actualiza el Padre R3
          update si_g_resolucion_igac_t3
             set id_prcso_crga_pdre = p_id_prcso_crga,
                 vgncia             = nvl(to_char(vgncia),
                                          trim(substr(trim(decrtos),
                                                      -4,
                                                      length(trim(decrtos))))),
                 avluo_ctstral      = regexp_replace(regexp_substr(replace(decrtos,
                                                                           '$.00',
                                                                           '$0.00'),
                                                                   '\$\d{1,3}((\.|\,)\d{3})*(\.[:digit:]{2})?'),
                                                     '(\$|\.|\,)',
                                                     null)
           where id_prcso_crga = v_id_prcso_crga;
        end if;

      exception
        when others then
          --Verifica si el Archivo esta Abierto
          if (utl_file.is_open(v_archvo)) then
            utl_file.fclose(v_archvo);
          end if;
          --Verifica si el Apuntador del Archivo esta Abierto
          if (dbms_lob.fileisopen(v_bfile) = 1) then
            dbms_lob.close(v_bfile);
          end if;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No fue posible registrar la resolucion tipo [' || v_rslcion(i).tpo_rgstro || '].';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
          return;
      end;
    end loop;

    --Marca el Archivo Padre como Procesado
    update et_g_procesos_carga
       set indcdor_prcsdo = 'S'
     where id_prcso_crga = p_id_prcso_crga;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Resoluciones registradas con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible registrar las resoluciones, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_rg_resolucion_etl;

  /*
  * @Descripcion  : Valida la Resolucion Igac
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_vl_resolucion(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                              p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                              p_rslcion           in varchar2,
                              p_rdccion           in varchar2,
                              o_cdgo_trmte_tpo    out df_s_tramites_tipo.cdgo_trmte_tpo%type,
                              o_cdgo_mtcion_clse  out df_s_mutaciones_clase.cdgo_mtcion_clse%type,
                              o_vgncia            out number,
                              o_fcha_rslcion      out date,
                              o_rfrncia           out varchar2,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2) as
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_vl_resolucion';
    v_vgncia_igac   si_g_resolucion_igac_t1.vgncia_igac%type;
    v_clse_mtcion   si_g_resolucion_igac_t1.clse_mtcion%type;
    v_aplcda        si_g_resolucion_igac_t1.aplcda%type;
    v_cncla_inscrbe si_g_resolucion_igac_t1.cncla_inscrbe%type;
  begin

    --Respuesta Exitosa
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

    --Busca los Datos del la Resolucion
    begin
      select nvl(trim(a.tpo_trmte), '99'),
             a.clse_mtcion,
             a.vgncia_igac,
             a.aplcda,
             a.cncla_inscrbe,
             a.rfrncia_igac
        into o_cdgo_trmte_tpo,
             v_clse_mtcion,
             v_vgncia_igac,
             v_aplcda,
             v_cncla_inscrbe,
             o_rfrncia
        from si_g_resolucion_igac_t1 a
       where a.id_prcso_crga in
             (select b.id_prcso_crga
                from et_g_procesos_carga b
               where b.id_prcso_crga = a.id_prcso_crga
                 and b.cdgo_clnte = p_cdgo_clnte
                 and b.id_impsto = p_id_impsto
                 and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
         and a.rslcion = p_rslcion
         and a.rdccion = p_rdccion
       order by a.cncla_inscrbe desc
       fetch first 1 row only;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                          ' con radicacion #' || p_rdccion ||
                          ', no se encontraron datos.';
        return;
    end;

    --Verifica si la Resolucion se Encuentra Aplicada
    if (v_aplcda = 'S') then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                        ' con radicacion #' || p_rdccion ||
                        ', ya se encuentra aplicada.';
      return;
    end if;

    --Verifica si el Tipo de Tramite no es Mutacion
    if (not o_cdgo_trmte_tpo in ('01', '99')) then
      --Busca la Homologacion del Tipo de Tramite
      begin
        select cdgo_mtcion_clse
          into v_clse_mtcion
          from df_c_trmtes_tpo_mtcion_clse
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_trmte_tpo = o_cdgo_trmte_tpo;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encuentra homologado el tipo de tramite #' ||
                            o_cdgo_trmte_tpo || '.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Existen mas de una homologacion para el tipo de tramite #' ||
                            o_cdgo_trmte_tpo || '.';
          return;
      end;
    else
      --Verifica si el Tipo de Mutacion es 0 
      if (v_clse_mtcion = '0') then

        --Busca los Datos de la Definicion de Cliente
        v_clse_mtcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => pkg_si_resolucion_predio.c_cdgo_dfncion_clnte_ctgria,
                                                                         p_cdgo_dfncion_clnte        => 'TMD');

        --Verifica si Encontro la Definicion
        if (v_clse_mtcion = '-1') then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No fue posible encontrar la definicion, tipo mutacion por defecto - con codigo [TMD] y categoria [' ||
                            pkg_si_resolucion_predio.c_cdgo_dfncion_clnte_ctgria || '].';
          return;
        end if;
      end if;
    end if;

    /*1 - Cambio de propietario
    2 - Englobe o desenglobe
    3 - Reliquidacion cambios de base
    4 - Reliquidacion cambio de avaluo
    5 - Inscripcion de predio
    6 - Rectificar destino, matricula
    7 - Cancelacion de predio
    8 - AGREGRA POR PRIMERA EN EL SISTEMA "EL NUMERO DE CC DEL PROPIETARIO" o "EL NUM DE MATRICULA INMOBILIARIA".
    */

    --Verifica si la Clase de Mutacion Existe
    begin
      select cdgo_mtcion_clse
        into v_clse_mtcion
        from df_s_mutaciones_clase
       where cdgo_mtcion_clse = v_clse_mtcion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'La clase de mutacion #' || v_clse_mtcion ||
                          '], no existe en el sistema.';
        return;
    end;

    --Verifica si Existe el Tipo Registro Incribe 
    if (v_clse_mtcion <> '7' and v_cncla_inscrbe <> 'I') then
      o_cdgo_rspsta  := 7;
      o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                        ' con radicacion #' || p_rdccion ||
                        ', no se encontro el registro de inscribe (I).';
      return;
    end if;

    --Verifica si Existe el Tipo Registro Cancela 
    if (v_clse_mtcion = '7' and v_cncla_inscrbe <> 'C') then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                        ' con radicacion #' || p_rdccion ||
                        ', no se encontro el registro de cancela (C).';
      return;
    end if;

    --Se Asigna el Tipo de Mutacion de la Resolucion
    o_cdgo_mtcion_clse := v_clse_mtcion;

    --Extrae la Fecha de Resolucion
    o_fcha_rslcion := to_date(v_vgncia_igac, 'DDMMYYYY');

    --Extrae la Vigencia que Aplica la Resolucion 
    o_vgncia := extract(year from o_fcha_rslcion);

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Resolucion validada con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible validar la resolucion #' ||
                        p_rslcion || ' con radicacion #' || p_rdccion ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_vl_resolucion;

  /*
  * @Descripcion  : Registra Sujeto Responsables del Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_rg_sjto_rspnsbles(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_rfrncia           in si_g_resolucion_igac_t1.rfrncia_igac%type,
                                  p_rslcion           in varchar2,
                                  p_rdccion           in varchar2,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out varchar2) as
    v_nvel           number;
    v_nmbre_up       sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_rg_sjto_rspnsbles';
    v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_rspnsbles      number := 0;
    v_idntfccion     varchar2(25);
  begin

    --Respuesta Exitosa
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

    o_mnsje_rspsta := 'prc_rg_sjto_rspnsbles --> Para la referencia #' ||
                      p_rfrncia || ', datos a validar: p_cdgo_clnte:' ||
                      p_cdgo_clnte || '-p_rfrncia:' || p_rfrncia ||
                      '-p_id_impsto:' || p_id_impsto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 3);

    --Verifica si el Sujeto Impuesto Existe    
    begin
      select /*+ RESULT_CACHE */
       b.id_sjto_impsto
        into v_id_sjto_impsto
        from si_c_sujetos a
        join si_i_sujetos_impuesto b
          on a.id_sjto = b.id_sjto
       where a.cdgo_clnte = p_cdgo_clnte
         and a.idntfccion = p_rfrncia
         and b.id_impsto = p_id_impsto;

      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => 'encontro sujeto:' ||
                                            v_id_sjto_impsto,
                            p_nvel_txto  => 3);

    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. Para la referencia #' || p_rfrncia ||
                          ', no existe el sujeto de impuesto en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Se Elimina los Responsables del Sujeto Impuesto
    delete si_i_sujetos_responsable
     where id_sjto_impsto = v_id_sjto_impsto;

    for c_rspnsbles in (select /*+ RESULT_CACHE */
                         a.id_rslcion_igac_t1,
                         nvl(b.cdgo_idntfccion_tpo, 'X') as cdgo_idntfccion_tpo,
                         nvl(trim(a.nmro_dcmnto), '0') as idntfccion,
                         nvl(trim(a.nmbre_prptrio), 'No registra') as prmer_nmbre,
                         null as sgndo_nmbre,
                         '.' as prmer_aplldo,
                         null as sgndo_aplldo,
                         decode(a.nmro_orden, '001', 'S', 'N') as prncpal_s_n,
                         decode(a.nmro_orden, '001', 'P', 'R') as cdgo_tpo_rspnsble,
                         0 as prcntje_prtcpcion
                          from si_g_resolucion_igac_t1 a
                          left join df_s_identificaciones_tipo b
                            on trim(a.tpo_dcmnto) = b.cdgo_idntfccion_tpo
                         where a.id_prcso_crga in
                               (select b.id_prcso_crga
                                  from et_g_procesos_carga b
                                 where b.id_prcso_crga = a.id_prcso_crga
                                   and b.cdgo_clnte = p_cdgo_clnte
                                   and b.id_impsto = p_id_impsto
                                   and b.id_impsto_sbmpsto =
                                       p_id_impsto_sbmpsto)
                           and a.rslcion = p_rslcion
                           and a.rdccion = p_rdccion
                           and a.cncla_inscrbe = 'I'
                           and a.rfrncia_igac = p_rfrncia

                        ) loop

      --Contador de Responsables
      v_rspnsbles := v_rspnsbles + 1;

      --Actualiza el Sujeto Impuesto en la Resolucion
      update si_g_resolucion_igac_t1
         set id_sjto_impsto = v_id_sjto_impsto
       where id_rslcion_igac_t1 = c_rspnsbles.id_rslcion_igac_t1;

      --25/02/2021. Identificacion sin 0 al inicio.
      begin
        select to_number(c_rspnsbles.idntfccion)
          into v_idntfccion
          from dual;
      exception
        when others then
          v_idntfccion := c_rspnsbles.idntfccion;
      end;

      --Registra los Responsable del Sujeto Impuesto 
      insert into si_i_sujetos_responsable
        (id_sjto_impsto,
         cdgo_idntfccion_tpo,
         idntfccion,
         prmer_nmbre,
         sgndo_nmbre,
         prmer_aplldo,
         sgndo_aplldo,
         prncpal_s_n,
         cdgo_tpo_rspnsble,
         prcntje_prtcpcion,
         orgen_dcmnto)
      values
        (v_id_sjto_impsto,
         c_rspnsbles.cdgo_idntfccion_tpo,
         v_idntfccion,
         c_rspnsbles.prmer_nmbre,
         c_rspnsbles.sgndo_nmbre,
         c_rspnsbles.prmer_aplldo,
         c_rspnsbles.sgndo_aplldo,
         c_rspnsbles.prncpal_s_n,
         c_rspnsbles.cdgo_tpo_rspnsble,
         c_rspnsbles.prcntje_prtcpcion,
         p_rslcion || '-' || p_rdccion);
    end loop;

    --Verifica si Registro Responsables
    if (v_rspnsbles = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Para la referencia #' || p_rfrncia ||
                        ', no existen responsables por registrar.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Responsables registrados con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'Para la referencia #' || p_rfrncia ||
                        ', no fue posible registrar los responsables.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_rg_sjto_rspnsbles;

  /*
  * @Descripcion  : Actualiza Matricula Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ac_matricula_prdio(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto         in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_rfrncia           in si_g_resolucion_igac_t1.rfrncia_igac%type,
                                   p_rslcion           in varchar2,
                                   p_rdccion           in varchar2,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2) as
    v_nvel            number;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ac_matricula_prdio';
    v_id_sjto_impsto  si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_mtrcla_inmblria si_i_predios.mtrcla_inmblria%type;
  begin

    --Respuesta Exitosa
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

    --Verifica si el Sujeto Impuesto Existe    
    begin
      select /*+ RESULT_CACHE */
       b.id_sjto_impsto
        into v_id_sjto_impsto
        from si_c_sujetos a
        join si_i_sujetos_impuesto b
          on a.id_sjto = b.id_sjto
       where a.cdgo_clnte = p_cdgo_clnte
         and a.idntfccion = p_rfrncia
         and b.id_impsto = p_id_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Para la referencia #' || p_rfrncia ||
                          ', no existe el sujeto de impuesto en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca los Datos de la Matricula del Predio
    begin
      select trim(a.mtrcla_inmblria)
        into v_mtrcla_inmblria
        from si_g_resolucion_igac_t2 a
       where a.id_prcso_crga in
             (select b.id_prcso_crga
                from et_g_procesos_carga b
               where b.id_prcso_crga = a.id_prcso_crga
                 and b.cdgo_clnte = p_cdgo_clnte
                 and b.id_impsto = p_id_impsto
                 and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
         and a.rslcion = p_rslcion
         and a.rdccion = p_rdccion
         and a.cncla_inscrbe = 'I'
         and a.rfrncia_igac = p_rfrncia
         and a.nmro_orden = '001'
       fetch first 1 row only;
    exception
      when no_data_found then
        --Nada que Hacer si la Matricula no Existe
        null;
    end;

    --Verifica si Actualiza la Matricula del Predio
    if (v_mtrcla_inmblria is not null) then
      --Actualiza la Matricula del Predio
      update si_i_predios
         set mtrcla_inmblria = v_mtrcla_inmblria
       where id_sjto_impsto = v_id_sjto_impsto;
    end if;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Matricula actualizada con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Para la referencia #' || p_rfrncia ||
                        ', no fue posible actualizar la matricula del predio' ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ac_matricula_prdio;

  /*
  * @Descripcion  : Inactiva Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_in_prdio_rslcion(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vldar_prdio       in varchar2 default 'N',
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2) as
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_in_prdio_rslcion';
    v_id_sjto_estdo df_s_sujetos_estado.id_sjto_estdo%type;
  begin

    --Respuesta Exitosa
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

    --Busca el Id del Sujeto Estado
    begin
      select /*+ RESULT_CACHE */
       a.id_sjto_estdo
        into v_id_sjto_estdo
        from df_s_sujetos_estado a
       where a.cdgo_sjto_estdo = 'I';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No fue posible encontrar el sujeto estado con codigo (I).';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Cursor de Predios
    for c_prdios in (select a.id_rslcion_igac_t1, a.rfrncia_igac
                       from si_g_resolucion_igac_t1 a
                      where a.id_prcso_crga in
                            (select b.id_prcso_crga
                               from et_g_procesos_carga b
                              where b.id_prcso_crga = a.id_prcso_crga
                                and b.cdgo_clnte = p_cdgo_clnte
                                and b.id_impsto = p_id_impsto
                                and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                        and a.rslcion = p_rslcion
                        and a.rdccion = p_rdccion
                        and a.cncla_inscrbe = 'C'
                        and a.nmro_orden = '001') loop
      --Busca Id del Sujeto Impuesto
      declare
        v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
      begin

        --Verifica si el Sujeto Impuesto Existe    
        begin
          select /*+ RESULT_CACHE */
           b.id_sjto_impsto
            into v_id_sjto_impsto
            from si_c_sujetos a
            join si_i_sujetos_impuesto b
              on a.id_sjto = b.id_sjto
           where a.cdgo_clnte = p_cdgo_clnte
             and a.idntfccion = c_prdios.rfrncia_igac
             and b.id_impsto = p_id_impsto;

          --Actualiza el Sujeto Impuesto en la Resolucion
          update si_g_resolucion_igac_t1
             set id_sjto_impsto = v_id_sjto_impsto
           where id_rslcion_igac_t1 = c_prdios.id_rslcion_igac_t1;

          --Inactiva Predio
          update si_i_sujetos_impuesto
             set id_sjto_estdo = v_id_sjto_estdo,
                 fcha_cnclcion = systimestamp
           where id_sjto_impsto = v_id_sjto_impsto;

        exception
          when no_data_found then
            --Valida si el Predio Existe
            if (p_vldar_prdio = 'S') then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Para la referencia #' ||
                                c_prdios.rfrncia_igac ||
                                ', no existe el sujeto de impuesto en el sistema.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            end if;
        end;
      end;
    end loop;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Predios inactivado con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'No fue posible inactivar los predios' ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_in_prdio_rslcion;

  /*
  * @Descripcion  : Registra Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_rg_prdio_rslcion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vgncia            in number,
                                 p_vldar_prdio       in varchar2 default 'N',
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2) as
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_rg_prdio_rslcion';
    v_id_prdo       df_i_periodos.id_prdo%type;
    v_id_pais       df_s_clientes.id_pais%type;
    v_id_dprtmnto   df_s_clientes.id_dprtmnto%type;
    v_id_mncpio     df_s_clientes.id_mncpio%type;
    v_id_sjto_estdo df_s_sujetos_estado.id_sjto_estdo%type;
    v_prdios        number := 0;
  begin

    --Respuesta Exitosa
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

    --Busca los Datos del Cliente
    begin
      select /*+ RESULT_CACHE */
       a.id_pais, a.id_dprtmnto, a.id_mncpio
        into v_id_pais, v_id_dprtmnto, v_id_mncpio
        from df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'El cliente #' || p_cdgo_clnte ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca los Datos del Periodo
    begin
      select /*+ RESULT_CACHE */
       a.id_prdo
        into v_id_prdo
        from df_i_periodos a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.vgncia = p_vgncia;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No fue posible encontrar el periodo para la vigencia [' ||
                          p_vgncia || '].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      when too_many_rows then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Para la vigencia [' || p_vgncia ||
                          '], existe mas de un periodo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca el Id del Sujeto Estado
    begin
      select /*+ RESULT_CACHE */
       a.id_sjto_estdo
        into v_id_sjto_estdo
        from df_s_sujetos_estado a
       where a.cdgo_sjto_estdo = 'A';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No fue posible encontrar el sujeto estado con codigo (A).';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Cursor de Predios
    for c_prdios in (select a.id_rslcion_igac_t1,
                            a.rfrncia_igac,
                            a.drccion,
                            a.avluo_ctstral,
                            a.area_trrno,
                            a.area_cnstrda,
                            a.dstno_ecnmco
                       from si_g_resolucion_igac_t1 a
                      where a.id_prcso_crga in
                            (select b.id_prcso_crga
                               from et_g_procesos_carga b
                              where b.id_prcso_crga = a.id_prcso_crga
                                and b.cdgo_clnte = p_cdgo_clnte
                                and b.id_impsto = p_id_impsto
                                and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                        and a.rslcion = p_rslcion
                        and a.rdccion = p_rdccion
                        and a.cncla_inscrbe = 'I'
                        and a.nmro_orden = '001') loop

      --Registra los Predios de la Resolucion
      declare
        v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_id_sjto        si_c_sujetos.id_sjto%type;
        v_id_prdio       si_i_predios.id_prdio%type;
        v_prdio_nvo      varchar2(1);
      begin

        --Crud de Predio
        pkg_gi_predio.prc_cd_predio(p_id_usrio          => p_id_usrio,
                                    p_cdgo_clnte        => p_cdgo_clnte,
                                    p_id_impsto         => p_id_impsto,
                                    p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                    p_vgncia            => p_vgncia,
                                    p_id_prdo           => v_id_prdo,
                                    p_idntfccion        => c_prdios.rfrncia_igac,
                                    p_id_pais           => v_id_pais,
                                    p_id_dprtmnto       => v_id_dprtmnto,
                                    p_id_mncpio         => v_id_mncpio,
                                    p_drccion           => c_prdios.drccion,
                                    p_id_sjto_estdo     => v_id_sjto_estdo,
                                    p_avluo_ctstral     => c_prdios.avluo_ctstral,
                                    p_bse_grvble        => c_prdios.avluo_ctstral,
                                    p_area_trrno        => c_prdios.area_trrno,
                                    p_area_cnstrda      => c_prdios.area_cnstrda,
                                    p_cdgo_dstno_igac   => c_prdios.dstno_ecnmco,
                                    o_prdio_nvo         => v_prdio_nvo,
                                    o_id_sjto_impsto    => v_id_sjto_impsto,
                                    o_id_sjto           => v_id_sjto,
                                    o_id_prdio          => v_id_prdio,
                                    o_nmro_error        => o_cdgo_rspsta,
                                    o_mnsje             => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;

        --Valida si el Predio Existe
        if (p_vldar_prdio = 'S' and v_prdio_nvo = 'N') then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Para la referencia #' || c_prdios.rfrncia_igac ||
                            ', ya existe el sujeto de impuesto en el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        elsif (p_vldar_prdio = 'N' and v_prdio_nvo = 'N') then
          --Activa el Predio por Englobe o Desenglobe
          update si_i_sujetos_impuesto
             set id_sjto_estdo = v_id_sjto_estdo, fcha_cnclcion = null
           where id_sjto_impsto = v_id_sjto_impsto;
        end if;

        --Actualiza el Sujeto Impuesto en la Resolucion
        update si_g_resolucion_igac_t1
           set id_sjto_impsto = v_id_sjto_impsto
         where id_rslcion_igac_t1 = c_prdios.id_rslcion_igac_t1;

        --Actualiza la Matricula del Predio
        pkg_si_resolucion_predio.prc_ac_matricula_prdio(p_cdgo_clnte        => p_cdgo_clnte,
                                                        p_id_impsto         => p_id_impsto,
                                                        p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                        p_rfrncia           => c_prdios.rfrncia_igac,
                                                        p_rslcion           => p_rslcion,
                                                        p_rdccion           => p_rdccion,
                                                        o_cdgo_rspsta       => o_cdgo_rspsta,
                                                        o_mnsje_rspsta      => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;

        --Registra los Sujetos Responsables de la Resolucion
        pkg_si_resolucion_predio.prc_rg_sjto_rspnsbles(p_cdgo_clnte        => p_cdgo_clnte,
                                                       p_id_impsto         => p_id_impsto,
                                                       p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                       p_rfrncia           => c_prdios.rfrncia_igac,
                                                       p_rslcion           => p_rslcion,
                                                       p_rdccion           => p_rdccion,
                                                       o_cdgo_rspsta       => o_cdgo_rspsta,
                                                       o_mnsje_rspsta      => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;

        --Contador de Predios
        v_prdios := v_prdios + 1;
      end;
    end loop;

    --Verifica si Registro Predios
    if (v_prdios = 0) then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                        ' con radicacion #' || p_rdccion ||
                        ', no existen predios por registrar.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Predios registrados con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'No fue posible registrar los predios' ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_rg_prdio_rslcion;

  /*
  * @Descripcion  : Actualiza Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ac_prdio_rslcion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vgncia            in number,
                                 p_accion            in varchar2,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ac_prdio_rslcion';
  begin

    --Respuesta Exitosa
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

    --Cursor de Predios
    for c_prdios in (select a.id_rslcion_igac_t1,
                            a.rfrncia_igac,
                            a.drccion,
                            a.avluo_ctstral,
                            a.area_trrno,
                            a.area_cnstrda,
                            a.dstno_ecnmco
                       from si_g_resolucion_igac_t1 a
                      where a.id_prcso_crga in
                            (select b.id_prcso_crga
                               from et_g_procesos_carga b
                              where b.id_prcso_crga = a.id_prcso_crga
                                and b.cdgo_clnte = p_cdgo_clnte
                                and b.id_impsto = p_id_impsto
                                and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                        and a.rslcion = p_rslcion
                        and a.rdccion = p_rdccion
                        and a.cncla_inscrbe = 'I'
                        and a.nmro_orden = '001') loop

      --Actualiza los Datos del Predio
      declare
        v_id_sjto        si_c_sujetos.id_sjto%type;
        v_id_prdio       si_i_predios.id_prdio%type;
        v_id_prdo        df_i_periodos.id_prdo%type;
        v_id_pais        df_s_clientes.id_pais%type;
        v_id_dprtmnto    df_s_clientes.id_dprtmnto%type;
        v_id_mncpio      df_s_clientes.id_mncpio%type;
        v_id_sjto_estdo  df_s_sujetos_estado.id_sjto_estdo%type;
        v_prdio_nvo      varchar2(1);
        v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
      begin

        --Verifica si el Sujeto Impuesto Existe    
        begin
          select /*+ RESULT_CACHE */
           b.id_sjto_impsto
            into v_id_sjto_impsto
            from si_c_sujetos a
            join si_i_sujetos_impuesto b
              on a.id_sjto = b.id_sjto
           where a.cdgo_clnte = p_cdgo_clnte
             and a.idntfccion = c_prdios.rfrncia_igac
             and b.id_impsto = p_id_impsto;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Para la referencia #' ||
                              c_prdios.rfrncia_igac ||
                              ', no existe el sujeto de impuesto en el sistema.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
        end;

        --Actualiza el Sujeto Impuesto en la Resolucion
        update si_g_resolucion_igac_t1
           set id_sjto_impsto = v_id_sjto_impsto
         where id_rslcion_igac_t1 = c_prdios.id_rslcion_igac_t1;

        --Modifica Todas las Caracteristica
        if (p_accion = 'ALL') then

          --Busca los Datos del Cliente
          begin
            select /*+ RESULT_CACHE */
             a.id_pais, a.id_dprtmnto, a.id_mncpio
              into v_id_pais, v_id_dprtmnto, v_id_mncpio
              from df_s_clientes a
             where a.cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'El cliente #' || p_cdgo_clnte ||
                                ', no existe en el sistema.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;

          --Busca los Datos del Periodo
          begin
            select /*+ RESULT_CACHE */
             a.id_prdo
              into v_id_prdo
              from df_i_periodos a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_impsto = p_id_impsto
               and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and a.vgncia = p_vgncia;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'No fue posible encontrar el periodo para la vigencia [' ||
                                p_vgncia || '].';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            when too_many_rows then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Para la vigencia [' || p_vgncia ||
                                '], existe mas de un periodo.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;

          --Busca el Id del Sujeto Estado
          begin
            select /*+ RESULT_CACHE */
             a.id_sjto_estdo
              into v_id_sjto_estdo
              from df_s_sujetos_estado a
             where a.cdgo_sjto_estdo = 'A';
          exception
            when no_data_found then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'No fue posible encontrar el sujeto estado con codigo (A).';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;

          --Crud de Predio
          pkg_gi_predio.prc_cd_predio(p_id_usrio          => p_id_usrio,
                                      p_cdgo_clnte        => p_cdgo_clnte,
                                      p_id_impsto         => p_id_impsto,
                                      p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                      p_vgncia            => p_vgncia,
                                      p_id_prdo           => v_id_prdo,
                                      p_idntfccion        => c_prdios.rfrncia_igac,
                                      p_id_pais           => v_id_pais,
                                      p_id_dprtmnto       => v_id_dprtmnto,
                                      p_id_mncpio         => v_id_mncpio,
                                      p_drccion           => c_prdios.drccion,
                                      p_id_sjto_estdo     => v_id_sjto_estdo,
                                      p_avluo_ctstral     => c_prdios.avluo_ctstral,
                                      p_bse_grvble        => c_prdios.avluo_ctstral,
                                      p_area_trrno        => c_prdios.area_trrno,
                                      p_area_cnstrda      => c_prdios.area_cnstrda,
                                      p_cdgo_dstno_igac   => c_prdios.dstno_ecnmco,
                                      o_prdio_nvo         => v_prdio_nvo,
                                      o_id_sjto_impsto    => v_id_sjto_impsto,
                                      o_id_sjto           => v_id_sjto,
                                      o_id_prdio          => v_id_prdio,
                                      o_nmro_error        => o_cdgo_rspsta,
                                      o_mnsje             => o_mnsje_rspsta);

          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Actualiza la Matricula del Predio
          pkg_si_resolucion_predio.prc_ac_matricula_prdio(p_cdgo_clnte        => p_cdgo_clnte,
                                                          p_id_impsto         => p_id_impsto,
                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                          p_rfrncia           => c_prdios.rfrncia_igac,
                                                          p_rslcion           => p_rslcion,
                                                          p_rdccion           => p_rdccion,
                                                          o_cdgo_rspsta       => o_cdgo_rspsta,
                                                          o_mnsje_rspsta      => o_mnsje_rspsta);

          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          -- 25/02/2021. Se coloca para la rectificacion de la identificacion si no vinene como Cambio de Propietario
          --Registra los Sujetos Responsables de la Resolucion.
          pkg_si_resolucion_predio.prc_rg_sjto_rspnsbles(p_cdgo_clnte        => p_cdgo_clnte,
                                                         p_id_impsto         => p_id_impsto,
                                                         p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                         p_rfrncia           => c_prdios.rfrncia_igac,
                                                         p_rslcion           => p_rslcion,
                                                         p_rdccion           => p_rdccion,
                                                         o_cdgo_rspsta       => o_cdgo_rspsta,
                                                         o_mnsje_rspsta      => o_mnsje_rspsta);

          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Modifica el Avaluo del Predio
        elsif (p_accion = 'AV') then

          --Actualiza el Avaluo del Predio
          update si_i_predios
             set avluo_cmrcial = c_prdios.avluo_ctstral,
                 avluo_ctstral = c_prdios.avluo_ctstral,
                 bse_grvble    = c_prdios.avluo_ctstral
           where id_sjto_impsto = v_id_sjto_impsto;

        end if;
      end;
    end loop;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Predios actualizado con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible actualizar el predio' ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ac_prdio_rslcion;

  /*
  * @Descripcion  : Aplicacion de Resolucion (Decretos)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ap_resolucion_decretos(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                       p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_rslcion           in varchar2,
                                       p_rdccion           in varchar2,
                                       p_cdgo_mtcion_clse  in df_s_mutaciones_clase.cdgo_mtcion_clse%type,
                                       p_fcha_rslcion      in date,
                                       p_max_vgncia        in number,
                                       o_cdgo_rspsta       out number,
                                       o_mnsje_rspsta      out varchar2) as
    v_nvel            number;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ap_resolucion_decretos';
    v_id_prdo         df_i_periodos.id_prdo%type;
    v_id_lqdcion_tpo  df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_id_fljo         wf_d_flujos.id_fljo%type;
    v_id_lqdcion_cdna varchar2(4000);
    v_dscrpcion_cm    df_s_mutaciones_clase.dscrpcion%type;
    -- Para validar desde cual vigencia se va a liquidar y si se tiene en cuenta la minima vigencia con deuda de los predios Cabcela
    v_min_vgncia             number;
    v_vlor_vgncia_mnma       number;
    v_vlor_vgncia_estdo_cnta varchar2(1);
  begin

    --Respuesta Exitosa
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

    --Busca el Tipo de Liquidacion - Autoliquidacion
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = 'AU';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'El tipo de liquidacion [AU], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca la Definicion de Vigencia Minima para Liquidacion del Cliente
    v_vlor_vgncia_mnma := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                          p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                          p_cdgo_dfncion_clnte        => 'VML');

    v_min_vgncia := pkg_si_resolucion_predio.fnc_vl_vgncia_lqdcion(p_cdgo_clnte        => p_cdgo_clnte,
                                                                   p_id_impsto         => p_id_impsto,
                                                                   p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                   p_rslcion           => p_rslcion,
                                                                   p_rdccion           => p_rdccion,
                                                                   p_max_vgncia        => p_max_vgncia,
                                                                   p_vlor_vgncia_mnma  => v_vlor_vgncia_mnma);

    -------v_min_vgncia := 2022;  -- COMENTAREAR DESPUES DE LA PRUEBA

    --Busca el Flujo Generado
    begin
      select /*+ RESULT_CACHE */
       id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_fljo = 'AJG';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encuentra parametrizado el flujo de ajuste generado [AJG].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca los Datos de la Clase de Mutacion
    begin
      select dscrpcion
        into v_dscrpcion_cm
        from df_s_mutaciones_clase
       where cdgo_mtcion_clse = p_cdgo_mtcion_clse;
    exception
      when no_data_found then
        o_cdgo_rspsta := 3;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Cursor de Resoluciones Igac Tipo 1                     
    for c_rslcion_igac_t1 in (select a.id_sjto_impsto,
                                     a.rfrncia_igac,
                                     a.area_trrno,
                                     a.area_cnstrda,
                                     a.dstno_ecnmco,
                                     a.avluo_ctstral,
                                     a.tpo_trmte,
                                     a.tpo_rgstro,
                                     a.clse_mtcion,
                                     a.cdgo_dprtmnto,
                                     a.cdgo_mncpio,
                                     a.id_prcso_crga,
                                     a.id_prcso_crga_pdre,
                                     a.id_prcso_intrmdia,
                                     a.nmro_prdial_antrior
                                from si_g_resolucion_igac_t1 a
                               where a.id_prcso_crga in
                                     (select b.id_prcso_crga
                                        from et_g_procesos_carga b
                                       where b.id_prcso_crga =
                                             a.id_prcso_crga
                                         and b.cdgo_clnte = p_cdgo_clnte
                                         and b.id_impsto = p_id_impsto
                                         and b.id_impsto_sbmpsto =
                                             p_id_impsto_sbmpsto)
                                 and a.rslcion = p_rslcion
                                 and a.rdccion = p_rdccion
                                 and a.cncla_inscrbe = 'I'
                                 and a.nmro_orden = '001') loop

      --Limpia la Cadena por Sujeto Impuesto
      v_id_lqdcion_cdna := null;

      --Verifica si Existen Decretos por Reliquidar
      declare
        v_dcrtos number;
      begin
        select /*+ RESULT_CACHE */
         count(*)
          into v_dcrtos
          from si_g_resolucion_igac_t3 a
         where a.id_prcso_crga in
               (select b.id_prcso_crga
                  from et_g_procesos_carga b
                 where b.id_prcso_crga = a.id_prcso_crga
                   and b.cdgo_clnte = p_cdgo_clnte
                   and b.id_impsto = p_id_impsto
                   and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
           and a.rslcion = p_rslcion
           and a.rdccion = p_rdccion
           and a.rfrncia_igac = c_rslcion_igac_t1.rfrncia_igac
              --and a.vgncia       <= p_max_vgncia
           and a.vgncia between p_max_vgncia - v_vlor_vgncia_mnma and
               p_max_vgncia;

        --Verifica si no Existe Decretos
        if (v_dcrtos = 0) then
          --Registro de Resolucion Tipo 3 - Generado por el Sistema
          insert into si_g_resolucion_igac_t3
            (id_prcso_crga,
             id_prcso_intrmdia,
             nmero_lnea,
             cdgo_dprtmnto,
             cdgo_mncpio,
             rslcion,
             rdccion,
             tpo_trmte,
             clse_mtcion,
             rfrncia_igac,
             cncla_inscrbe,
             tpo_rgstro,
             nmro_orden,
             ttal_rgstro,
             decrtos,
             nmro_prdial_antrior,
             vgncia,
             avluo_ctstral,
             id_prcso_crga_pdre)
          values
            (c_rslcion_igac_t1.id_prcso_crga,
             c_rslcion_igac_t1.id_prcso_intrmdia,
             1,
             c_rslcion_igac_t1.cdgo_dprtmnto,
             c_rslcion_igac_t1.cdgo_mncpio,
             p_rslcion,
             p_rdccion,
             c_rslcion_igac_t1.tpo_trmte,
             c_rslcion_igac_t1.clse_mtcion,
             c_rslcion_igac_t1.rfrncia_igac,
             'I',
             3,
             '001',
             '001',
             upper('Decreto generado por el sistema ' ||
                   to_char(sysdate, 'DD/MM/YYYY') || ' ' ||
                   to_char(c_rslcion_igac_t1.avluo_ctstral,
                           'FM$999,999,999,999,999.00') ||
                   ' vigencia fiscal: 01/01/' || p_max_vgncia),
             c_rslcion_igac_t1.nmro_prdial_antrior,
             p_max_vgncia,
             c_rslcion_igac_t1.avluo_ctstral,
             c_rslcion_igac_t1.id_prcso_crga_pdre);

        end if;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No fue posible registrar las resolucion tipo 3 generado por el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
          return;
      end;

      --Verifica si Existe el Sujeto impuesto
      if (c_rslcion_igac_t1.id_sjto_impsto is null) then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Para la referencia #' ||
                          c_rslcion_igac_t1.rfrncia_igac ||
                          ', no existe el sujeto de impuesto en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;

      --Cursor de Resoluciones Igac Tipo 3                     
      for c_rslcion_igac_t3 in (select a.id_rslcion_igac_t3,
                                       a.vgncia,
                                       a.avluo_ctstral
                                  from si_g_resolucion_igac_t3 a
                                 where a.id_prcso_crga in
                                       (select b.id_prcso_crga
                                          from et_g_procesos_carga b
                                         where b.id_prcso_crga =
                                               a.id_prcso_crga
                                           and b.cdgo_clnte = p_cdgo_clnte
                                           and b.id_impsto = p_id_impsto
                                           and b.id_impsto_sbmpsto =
                                               p_id_impsto_sbmpsto)
                                   and a.rslcion = p_rslcion
                                   and a.rdccion = p_rdccion
                                   and a.rfrncia_igac =
                                       c_rslcion_igac_t1.rfrncia_igac
                                   and a.vgncia >= v_min_vgncia
                                --and a.vgncia        between p_max_vgncia - 5 and p_max_vgncia
                                 order by a.vgncia) loop

        o_mnsje_rspsta := 'p_max_vgncia: ' || p_max_vgncia ||
                          ' c_rslcion_igac_t3.vgncia' ||
                          c_rslcion_igac_t3.vgncia;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);

        --Busca los Datos del Periodo
        begin
          select /*+ RESULT_CACHE */
           a.id_prdo
            into v_id_prdo
            from df_i_periodos a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = p_id_impsto
             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and a.vgncia = c_rslcion_igac_t3.vgncia;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No fue posible encontrar el periodo para la vigencia [' ||
                              c_rslcion_igac_t3.vgncia || '].';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          when too_many_rows then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'Para la vigencia [' ||
                              c_rslcion_igac_t3.vgncia ||
                              '], existe mas de un periodo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
        end;

        --Verifica si el Avaluo del Decreto es Nulo
        if (c_rslcion_igac_t3.avluo_ctstral is null) then

          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'Para la vigencia [' ||
                            c_rslcion_igac_t3.vgncia ||
                            '], el avaluo se encuentra nulo en la resolucion tipo 3.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;

        end if;

        --Busca las Caracteristicas del Predio a Liquidar
        declare
          v_cdgo_prdio_clsfccion gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;
          v_id_prdio_dstno       gi_d_predios_calculo_destino.id_prdio_dstno%type;
          v_id_prdio_uso_slo     gi_d_predios_calculo_uso.id_prdio_uso_slo%type;
          v_cdgo_estrto          df_s_estratos.cdgo_estrto%type;
          v_atipica_referencia   gi_d_atipicas_referencia%rowtype;
        begin

          --Calculamos la Clasificacion del Predio
          v_cdgo_prdio_clsfccion := pkg_gi_predio.fnc_ca_predios_clase(p_cdgo_clnte        => p_cdgo_clnte,
                                                                       p_id_impsto         => p_id_impsto,
                                                                       p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                       p_vgncia            => c_rslcion_igac_t3.vgncia,
                                                                       p_rfrncia_igac      => c_rslcion_igac_t1.rfrncia_igac);

          --Verifica si Calculo la Clasificacion del Predio
          if (v_cdgo_prdio_clsfccion is null) then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'Para la referencia ' ||
                              c_rslcion_igac_t1.rfrncia_igac ||
                              ', no se calculo la clasificacion.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Calculamos el Destino del Predio                                                   
          o_mnsje_rspsta := 'c_rslcion_igac_t3.vgncia: ' ||
                            c_rslcion_igac_t3.vgncia ||
                            ' c_rslcion_igac_t1.area_trrno ' ||
                            c_rslcion_igac_t1.area_trrno ||
                            ' c_rslcion_igac_t1.area_cnstrda ' ||
                            c_rslcion_igac_t1.area_cnstrda ||
                            ' c_rslcion_igac_t1.dstno_ecnmco ' ||
                            c_rslcion_igac_t1.dstno_ecnmco ||
                            ' v_cdgo_prdio_clsfccion ' ||
                            v_cdgo_prdio_clsfccion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);

          v_id_prdio_dstno := nvl(v_id_prdio_dstno,
                                  pkg_gi_predio.fnc_ca_destino(p_cdgo_clnte           => p_cdgo_clnte,
                                                               p_id_impsto            => p_id_impsto,
                                                               p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                               p_vgncia               => c_rslcion_igac_t3.vgncia,
                                                               p_area_trrno_igac      => c_rslcion_igac_t1.area_trrno,
                                                               p_area_cnstrda_igac    => c_rslcion_igac_t1.area_cnstrda,
                                                               p_dstno_ecnmco_igac    => c_rslcion_igac_t1.dstno_ecnmco,
                                                               p_cdgo_prdio_clsfccion => v_cdgo_prdio_clsfccion));

          --Verifica si Calculo el Destino del Predio
          if (v_id_prdio_dstno is null) then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'Para la referencia ' ||
                              c_rslcion_igac_t1.rfrncia_igac ||
                              ', no se calculo el destino.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Calculamos el Uso del Predio    

          v_id_prdio_uso_slo := nvl(v_id_prdio_uso_slo,
                                    pkg_gi_predio.fnc_ca_uso(p_cdgo_clnte           => p_cdgo_clnte,
                                                             p_id_impsto            => p_id_impsto,
                                                             p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                             p_vgncia               => c_rslcion_igac_t3.vgncia,
                                                             p_area_trrno_igac      => c_rslcion_igac_t1.area_trrno,
                                                             p_area_cnstrda_igac    => c_rslcion_igac_t1.area_cnstrda,
                                                             p_dstno_ecnmco_igac    => c_rslcion_igac_t1.dstno_ecnmco,
                                                             p_cdgo_prdio_clsfccion => v_cdgo_prdio_clsfccion));

          --Verifica si Calculo el Uso del Predio
          if (v_id_prdio_uso_slo is null) then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Para la referencia ' ||
                              c_rslcion_igac_t1.rfrncia_igac ||
                              ', no se calculo el uso.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Calculamos el Estrato del Predio
          v_cdgo_estrto := nvl(v_cdgo_estrto,
                               pkg_gi_predio.fnc_ca_estrato(p_cdgo_clnte     => p_cdgo_clnte,
                                                            p_id_impsto      => p_id_impsto,
                                                            p_id_sbimpsto    => p_id_impsto_sbmpsto,
                                                            p_id_prdio_dstno => v_id_prdio_dstno,
                                                            p_vgncia         => c_rslcion_igac_t3.vgncia,
                                                            p_id_prdo        => v_id_prdo,
                                                            p_rfrncia_igac   => c_rslcion_igac_t1.rfrncia_igac));

          --Verifica si Calculo el Estrato del Predio
          if (v_cdgo_estrto is null) then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'Para la referencia ' ||
                              c_rslcion_igac_t1.rfrncia_igac ||
                              ', no se calculo el estrato.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          declare
            v_indcdor_ajste  varchar2(2);
            v_id_lqdcion     gi_g_liquidaciones.id_lqdcion%type;
            v_vlor_sldo_fvor number;
          begin
            --Up para Generar Reliquidacion
            pkg_si_novedades_predio.prc_ge_rlqdcion_pntual_prdial(p_id_usrio             => p_id_usrio,
                                                                  p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_impsto            => p_id_impsto,
                                                                  p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                  p_id_prdo              => v_id_prdo,
                                                                  p_vgncia               => c_rslcion_igac_t3.vgncia,
                                                                  p_id_sjto_impsto       => c_rslcion_igac_t1.id_sjto_impsto,
                                                                  p_bse                  => c_rslcion_igac_t3.avluo_ctstral,
                                                                  p_area_trrno           => c_rslcion_igac_t1.area_trrno,
                                                                  p_area_cnstrda         => c_rslcion_igac_t1.area_cnstrda,
                                                                  p_cdgo_prdio_clsfccion => v_cdgo_prdio_clsfccion,
                                                                  p_cdgo_dstno_igac      => c_rslcion_igac_t1.dstno_ecnmco,
                                                                  p_id_prdio_dstno       => v_id_prdio_dstno,
                                                                  p_id_prdio_uso_slo     => v_id_prdio_uso_slo,
                                                                  p_cdgo_estrto          => v_cdgo_estrto,
                                                                  p_id_lqdcion_tpo       => v_id_lqdcion_tpo,
                                                                  p_indicador_crtra      => true /*Indicador para Crear Cartera*/,
                                                                  o_indcdor_ajste        => v_indcdor_ajste,
                                                                  o_vlor_sldo_fvor       => v_vlor_sldo_fvor,
                                                                  o_id_lqdcion           => v_id_lqdcion,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);

            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta || ' [' ||
                                c_rslcion_igac_t3.vgncia || '].';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            else
              --Actualiza la Liquidacion en la Vigencia del Decreto
              update si_g_resolucion_igac_t3
                 set id_lqdcion = v_id_lqdcion
               where id_rslcion_igac_t3 =
                     c_rslcion_igac_t3.id_rslcion_igac_t3;

              --Verifica si la Reliquidacion Realizo Ajuste
              if (v_indcdor_ajste = 'S') then
                --Recupera las Liquidaciones por Ajustes
                v_id_lqdcion_cdna := v_id_lqdcion_cdna || v_id_lqdcion || ',';
              end if;
            end if;
          end;
        end;
      end loop;

      --Realiza los Ajustes del Sujeto Impuesto
      declare
        v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
        v_fljo_trea        v_wf_d_flujos_transicion.id_fljo_trea%type;
        v_id_ajste         gf_g_ajustes.id_ajste%type;
        v_xml              varchar2(4000);
      begin

        --Cursor de Tipos de Ajustes
        for c_tpo_ajste in (select a.cdgo_clnte,
                                   a.id_impsto,
                                   a.id_impsto_sbmpsto,
                                   b.orgen,
                                   b.tpo_ajste,
                                   b.id_ajste_mtvo,
                                   decode(b.tpo_ajste,
                                          'CR',
                                          'Credito',
                                          'Debito') as dscrpcion_tpo_ajste,
                                   a.id_lqdcion_mtv_ajst
                              from gi_d_liquidaciones_mtv_ajst a
                              join gf_d_ajuste_motivo b
                                on a.id_ajste_mtvo = b.id_ajste_mtvo
                             where a.id_lqdcion_mtv_ajst in
                                   (select /*+ RESULT_CACHE */
                                     a.id_lqdcion_mtv_ajst
                                      from gi_g_liquidaciones_ajuste a
                                     where a.id_lqdcion in
                                           (select regexp_substr(v_id_lqdcion_cdna,
                                                                 '[^,]+',
                                                                 1,
                                                                 level)
                                              from dual
                                            connect by level <=
                                                       regexp_count(v_id_lqdcion_cdna,
                                                                    ','))
                                     group by a.id_lqdcion_mtv_ajst)) loop

          --Registra la Instancia del Flujo
          pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                      p_id_usrio         => p_id_usrio,
                                                      p_id_prtcpte       => null,
                                                      p_obsrvcion        => 'Flujo de Ajuste Automatico ' ||
                                                                            c_tpo_ajste.dscrpcion_tpo_ajste ||
                                                                            ', Resolucion Igac N?' ||
                                                                            p_rslcion || '-' ||
                                                                            p_rdccion || '.',
                                                      o_id_instncia_fljo => v_id_instncia_fljo,
                                                      o_id_fljo_trea     => v_fljo_trea,
                                                      o_mnsje            => o_mnsje_rspsta);

          --Verifica si Creo la Instancia Flujo
          if (v_id_instncia_fljo is null) then
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;

          --Json de Ajuste Detalle
          apex_json.initialize_clob_output;
          apex_json.open_array;

          --Cursor de Vigencia del Ajuste
          for c_ajste_dtlle in (select b.vgncia,
                                       b.id_prdo,
                                       a.id_cncpto,
                                       a.vlor_ajste,
                                       a.vlor_sldo_cptal,
                                       a.vlor_intres
                                  from gi_g_liquidaciones_ajuste a
                                  join gi_g_liquidaciones b
                                    on a.id_lqdcion = b.id_lqdcion
                                 where a.id_lqdcion in
                                       (select /*+ RESULT_CACHE */
                                         a.id_lqdcion
                                          from gi_g_liquidaciones_ajuste a
                                         where a.id_lqdcion in
                                               (select regexp_substr(v_id_lqdcion_cdna,
                                                                     '[^,]+',
                                                                     1,
                                                                     level)
                                                  from dual
                                                connect by level <=
                                                           regexp_count(v_id_lqdcion_cdna,
                                                                        ',')))
                                   and a.id_lqdcion_mtv_ajst =
                                       c_tpo_ajste.id_lqdcion_mtv_ajst) loop
            --Json
            apex_json.open_object;
            apex_json.write('VGNCIA', c_ajste_dtlle.vgncia);
            apex_json.write('ID_PRDO', c_ajste_dtlle.id_prdo);
            apex_json.write('ID_CNCPTO', c_ajste_dtlle.id_cncpto);
            apex_json.write('VLOR_AJSTE', c_ajste_dtlle.vlor_ajste);
            apex_json.write('VLOR_SLDO_CPTAL',
                            c_ajste_dtlle.vlor_sldo_cptal);
            apex_json.write('VLOR_INTRES', c_ajste_dtlle.vlor_intres);
            apex_json.write('AJSTE_DTLLE_TPO', 'C');
            apex_json.close_object;
          end loop;

          --Cierra el Array del Json
          apex_json.close_array;

          --Registra el Ajuste Automatico
          begin
            pkg_gf_ajustes.prc_rg_ajustes(p_cdgo_clnte              => p_cdgo_clnte,
                                          p_id_impsto               => p_id_impsto,
                                          p_id_impsto_sbmpsto       => p_id_impsto_sbmpsto,
                                          p_id_sjto_impsto          => c_rslcion_igac_t1.id_sjto_impsto,
                                          p_orgen                   => c_tpo_ajste.orgen,
                                          p_tpo_ajste               => c_tpo_ajste.tpo_ajste,
                                          p_id_ajste_mtvo           => c_tpo_ajste.id_ajste_mtvo,
                                          p_obsrvcion               => 'Ajuste Automatico ' ||
                                                                       c_tpo_ajste.dscrpcion_tpo_ajste ||
                                                                       ', Resolucion Igac N?' ||
                                                                       p_rslcion || '-' ||
                                                                       p_rdccion || ' [' ||
                                                                       initcap(v_dscrpcion_cm) || '].',
                                          p_tpo_dcmnto_sprte        => 0,
                                          p_nmro_dcmto_sprte        => p_rslcion || '-' ||
                                                                       p_rdccion,
                                          p_fcha_dcmnto_sprte       => p_fcha_rslcion,
                                          p_nmro_slctud             => null,
                                          p_id_usrio                => p_id_usrio,
                                          p_id_instncia_fljo        => v_id_instncia_fljo,
                                          p_id_fljo_trea            => v_fljo_trea,
                                          p_id_instncia_fljo_pdre   => null,
                                          p_json                    => apex_json.get_clob_output,
                                          p_adjnto                  => null,
                                          p_nmro_dcmto_sprte_adjnto => null,
                                          p_ind_ajste_prcso         => null,
                                          p_fcha_pryccion_intrs     => null,
                                          p_id_ajste                => v_id_ajste,
                                          o_cdgo_rspsta             => o_cdgo_rspsta,
                                          o_mnsje_rspsta            => o_mnsje_rspsta);

            --Limpia el Json
            apex_json.free_output;

            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 15;
              o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta || '.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            end if;

            --Xml de Ajuste
            v_xml := '<ID_AJSTE>' || v_id_ajste || '</ID_AJSTE>' ||
                     '<ID_SJTO_IMPSTO>' || c_rslcion_igac_t1.id_sjto_impsto ||
                     '</ID_SJTO_IMPSTO>' || '<TPO_AJSTE>' ||
                     c_tpo_ajste.tpo_ajste || '</TPO_AJSTE>' ||
                     '<CDGO_CLNTE>' || p_cdgo_clnte || '</CDGO_CLNTE>' ||
                     '<ID_USRIO>' || p_id_usrio || '</ID_USRIO>';

            --Up Para Aplicar Ajuste
            pkg_gf_ajustes.prc_ap_ajuste(p_xml          => v_xml,
                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                         o_mnsje_rspsta => o_mnsje_rspsta);

            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 16;
              o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta || '.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            end if;

            --Actualiza la Instancia Flujo y Ajuste a Liquidacion Ajuste
            update gi_g_liquidaciones_ajuste a
               set id_ajste         = v_id_ajste,
                   id_instncia_fljo = v_id_instncia_fljo
             where a.id_lqdcion in
                   (select regexp_substr(v_id_lqdcion_cdna,
                                         '[^,]+',
                                         1,
                                         level)
                      from dual
                    connect by level <= regexp_count(v_id_lqdcion_cdna, ','));

          exception
            when others then
              o_cdgo_rspsta  := 17;
              o_mnsje_rspsta := 'No fue posible registrar el ajuste automatico de resolucion.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => (o_mnsje_rspsta ||
                                                    ' Error: ' || sqlerrm),
                                    p_nvel_txto  => 3);
              return;
          end;

          --Finaliza la Instancia Flujo del Ajuste Generado
          update wf_g_instancias_flujo
             set estdo_instncia = 'FINALIZADA'
           where id_instncia_fljo = v_id_instncia_fljo;

        end loop;
      end;
    end loop;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Decretos aplicados con exito.';

  exception
    when others then
      o_cdgo_rspsta  := 18;
      o_mnsje_rspsta := 'No fue posible aplicar los decretos de la resolucion #' ||
                        p_rslcion || ' con radicacion #' || p_rdccion ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_resolucion_decretos;

  /*
  * @Descripcion  : Aplicacion de Resolucion
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ap_resolucion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                              p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                              p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                              p_rslcion           in varchar2,
                              p_rdccion           in varchar2,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2) as
    v_nvel              number;
    v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ap_resolucion';
    v_cdgo_trmte_tpo    df_s_tramites_tipo.cdgo_trmte_tpo%type;
    v_cdgo_mtcion_clse  df_s_mutaciones_clase.cdgo_mtcion_clse%type;
    v_vgncia_actual     number;
    v_vgncia            number;
    v_fcha_rslcion      date;
    v_rfrncia           si_g_resolucion_igac_t1.rfrncia_igac%type;
    v_tpo_vgncia        varchar2(2);
    v_id_rslcion_aplcda si_g_resolucion_aplicada.id_rslcion_aplcda%type;
    v_actlza_drccn      varchar2(1);
  begin

    --Respuesta Exitosa
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

    --Vigencia Actual
    --v_vgncia_actual := extract(year from sysdate);
    v_vgncia_actual := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                       p_cdgo_dfncion_clnte        => 'VAC');
    --Valida la Resolucion
    pkg_si_resolucion_predio.prc_vl_resolucion(p_cdgo_clnte        => p_cdgo_clnte,
                                               p_id_impsto         => p_id_impsto,
                                               p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                               p_rslcion           => p_rslcion,
                                               p_rdccion           => p_rdccion,
                                               o_cdgo_trmte_tpo    => v_cdgo_trmte_tpo,
                                               o_cdgo_mtcion_clse  => v_cdgo_mtcion_clse,
                                               o_vgncia            => v_vgncia,
                                               o_fcha_rslcion      => v_fcha_rslcion,
                                               o_rfrncia           => v_rfrncia,
                                               o_cdgo_rspsta       => o_cdgo_rspsta,
                                               o_mnsje_rspsta      => o_mnsje_rspsta);

    --Verifica si Hubo Error
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;

    --Determina el Tipo de Vigencia
    v_tpo_vgncia := (case
                      when (v_vgncia = v_vgncia_actual) then
                       'AC' --Actual
                      when (v_vgncia > v_vgncia_actual) then
                       'FU' --Futura
                      else
                       'AN' --Anterior
                    end);

    --Verifica si el Tipo de Vigencia es Anterior y los Tipo de Mutacion 1 , 5 , 7
    if (v_tpo_vgncia = 'AN' and v_cdgo_mtcion_clse in ('1', '5', '7')) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Para la resolucion #' || p_rslcion ||
                        ' con radicacion #' || p_rdccion ||
                        ', no es posible aplicar ya que es vigencia anterior.';
      return;
    end if;

    --Verifica si el Tipo de Vigencia es Actual o Futura
    if (v_tpo_vgncia in ('AC', 'FU')) then

      --1. Cambio de Propietario
      if (v_cdgo_mtcion_clse = '1') then
        --Registra los Sujetos Responsables de la Resolucion
        pkg_si_resolucion_predio.prc_rg_sjto_rspnsbles(p_cdgo_clnte        => p_cdgo_clnte,
                                                       p_id_impsto         => p_id_impsto,
                                                       p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                       p_rfrncia           => v_rfrncia,
                                                       p_rslcion           => p_rslcion,
                                                       p_rdccion           => p_rdccion,
                                                       o_cdgo_rspsta       => o_cdgo_rspsta,
                                                       o_mnsje_rspsta      => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, p_nvel_txto  => 3);
            return;
        end if; 

        --Validamos si se debe actualizar la direccion del predio.                                               
        v_actlza_drccn := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                          p_cdgo_dfncion_clnte_ctgria => 'RSL',
                                                                          p_cdgo_dfncion_clnte        => 'ACD');

        if ( v_actlza_drccn = 'S' ) then
            --Actualiza la dirección
            pkg_si_resolucion_predio.prc_ac_prdio_rslcion_drccn(p_cdgo_clnte        => p_cdgo_clnte,
                                                                p_id_impsto         => p_id_impsto,
                                                                p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                p_rslcion           => p_rslcion,
                                                                p_rdccion           => p_rdccion,
                                                                o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                o_mnsje_rspsta      => o_mnsje_rspsta);

            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
                o_cdgo_rspsta  := 6;
                o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, p_nvel_txto  => 3);
                return;
            end if;    

        end if;


        --2. Englobe o Desenglobe
        --5. Inscripcion de Predio
        --7. Cancelacion de Predio
      elsif (v_cdgo_mtcion_clse in ('2', '5', '7')) then

        --Inactiva los Predios que Cancelan
        if (v_cdgo_mtcion_clse <> '5') then
          pkg_si_resolucion_predio.prc_in_prdio_rslcion(p_cdgo_clnte        => p_cdgo_clnte,
                                                        p_id_impsto         => p_id_impsto,
                                                        p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                        p_rslcion           => p_rslcion,
                                                        p_rdccion           => p_rdccion,
                                                        p_vldar_prdio       => (case
                                                                                 when v_cdgo_mtcion_clse = '7' then
                                                                                  'S'
                                                                                 else
                                                                                  'N'
                                                                               end),
                                                        o_cdgo_rspsta       => o_cdgo_rspsta,
                                                        o_mnsje_rspsta      => o_mnsje_rspsta);

          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
        end if;

        --Registra los Predios que Inscribe
        if (v_cdgo_mtcion_clse <> '7') then
          pkg_si_resolucion_predio.prc_rg_prdio_rslcion(p_id_usrio          => p_id_usrio,
                                                        p_cdgo_clnte        => p_cdgo_clnte,
                                                        p_id_impsto         => p_id_impsto,
                                                        p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                        p_rslcion           => p_rslcion,
                                                        p_rdccion           => p_rdccion,
                                                        p_vgncia            => v_vgncia_actual,
                                                        p_vldar_prdio       => (case
                                                                                 when v_cdgo_mtcion_clse = '5' then
                                                                                  'S'
                                                                                 else
                                                                                  'N'
                                                                               end),
                                                        o_cdgo_rspsta       => o_cdgo_rspsta,
                                                        o_mnsje_rspsta      => o_mnsje_rspsta);

          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
        end if;

        --3. Cambios de Base
        --4. Cambios de Avaluo
        --6. Rectificar Destino y Matricula
        --8. AGREGRA POR PRIMERA EN EL SISTEMA "EL NUMERO DE CC DEL PROPIETARIO" o "EL NUM DE MATRICULA INMOBILIARIA".
      elsif (v_cdgo_mtcion_clse in ('3', '4', '6', '8')) then
        --Actualiza los Datos del Predio
        pkg_si_resolucion_predio.prc_ac_prdio_rslcion(p_id_usrio          => p_id_usrio,
                                                      p_cdgo_clnte        => p_cdgo_clnte,
                                                      p_id_impsto         => p_id_impsto,
                                                      p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                      p_rslcion           => p_rslcion,
                                                      p_rdccion           => p_rdccion,
                                                      p_vgncia            => v_vgncia_actual,
                                                      p_accion            => (case
                                                                               when v_cdgo_mtcion_clse = '4' then
                                                                                'AV'
                                                                               else
                                                                                'ALL'
                                                                             end),
                                                      o_cdgo_rspsta       => o_cdgo_rspsta,
                                                      o_mnsje_rspsta      => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      else
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Para el tipo de mutacion [' ||
                          v_cdgo_mtcion_clse ||
                          '], no posee operaciones en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    end if;

    --Verifica si el Tipo de Vigencia es Anterior o Actual
    --2. Englobe o Desenglobe
    --3. Cambios de Base
    --4. Cambios de Avaluo
    --5. Inscripcion de predios
    --6. Rectificar Destino y Matricula
    --if( v_tpo_vgncia in ( 'AN' , 'AC' ) and v_cdgo_mtcion_clse in ( '2' , '3' , '4' , '6' )) then  

    if v_cdgo_mtcion_clse in ('2', '3', '4', '6', '5') then
      --Aplicacion de Decretos
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => 3,
                            p_txto_log   => 'hola mundo' || '~' ||
                                            p_id_usrio || '~' ||
                                            p_cdgo_clnte || '~' ||
                                            p_id_impsto || '~' ||
                                            p_id_impsto_sbmpsto || '~' ||
                                            p_rslcion || '~' || p_rdccion || '~' ||
                                            v_cdgo_mtcion_clse || '~' ||
                                            v_fcha_rslcion || '~' ||
                                            v_tpo_vgncia || '~' || v_vgncia || '~' ||
                                            v_vgncia_actual,
                            p_nvel_txto  => 3);

      pkg_si_resolucion_predio.prc_ap_resolucion_decretos(p_id_usrio          => p_id_usrio,
                                                          p_cdgo_clnte        => p_cdgo_clnte,
                                                          p_id_impsto         => p_id_impsto,
                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                          p_rslcion           => p_rslcion,
                                                          p_rdccion           => p_rdccion,
                                                          p_cdgo_mtcion_clse  => v_cdgo_mtcion_clse,
                                                          p_fcha_rslcion      => v_fcha_rslcion,
                                                          p_max_vgncia        => (case
                                                                                   when v_tpo_vgncia = 'AN' then
                                                                                    v_vgncia
                                                                                   else
                                                                                    v_vgncia_actual
                                                                                 end),
                                                          o_cdgo_rspsta       => o_cdgo_rspsta,
                                                          o_mnsje_rspsta      => o_mnsje_rspsta);

      --Verifica si Hubo Error
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    end if;

    --Registra Resolucion Aplicada
    begin
      insert into si_g_resolucion_aplicada
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         rslcion,
         rdccion,
         tpo_trmte,
         clse_mtcion,
         vgncia_igac,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_rslcion,
         p_rdccion,
         v_cdgo_trmte_tpo,
         v_cdgo_mtcion_clse,
         v_vgncia,
         p_id_usrio)
      returning id_rslcion_aplcda into v_id_rslcion_aplcda;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No fue posible crear el registro de resolucion aplicada.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        rollback;

        return;

    end;

    --Actualiza la Resolucion
    update si_g_resolucion_igac_t1 a
       set a.aplcda = 'S', id_rslcion_aplcda = v_id_rslcion_aplcda
     where a.id_prcso_crga in
           (select b.id_prcso_crga
              from et_g_procesos_carga b
             where b.id_prcso_crga = a.id_prcso_crga
               and b.cdgo_clnte = p_cdgo_clnte
               and b.id_impsto = p_id_impsto
               and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
       and a.rslcion = p_rslcion
       and a.rdccion = p_rdccion;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Resolucion aplicada con Exito';

  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'No fue posible aplicar la resolucion #' ||
                        p_rslcion || ' con radicacion #' || p_rdccion ||
                        ', intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_resolucion;

  procedure prc_ap_rslcion_msva(p_id_usrio   in sg_g_usuarios.id_usrio%type,
                                p_cdgo_clnte in df_s_clientes.cdgo_clnte%type) as
    --, p_json              in clob
    --, o_cdgo_rspsta       out number
    --, o_mnsje_rspsta      out varchar2 ) as
    v_json          clob;
    v_cdgo_rspsta   number;
    v_mnsje_rspsta  varchar2(4000);
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ap_rslcion_msva';
    val             number;
    v_correo        varchar2(1000);
    v_mensaje       varchar2(4000);
    v_id_usrio_apex number;
    v_html          clob;
    v_body_html     clob;
    v_body          clob;
    -- Para validar desde cual vigencia se va a liquidar y si se tiene en cuenta la minima vigencia con deuda de los predios Cabcela

  begin
    insert into muerto
      (n_001, v_001, t_001)
    values
      (600, 'Entrando al procedimiento', systimestamp);
    --Determinamos el Nivel del Log de la UP
    v_nvel    := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                             p_id_impsto  => null,
                                             p_nmbre_up   => v_nmbre_up);
    v_mensaje := 'Entrando - ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mensaje,
                          p_nvel_txto  => 1);

    select json_rslcion_igac into v_json from aux_gn_prc_ap_rslcion_msva;
    delete from aux_gn_prc_ap_rslcion_msva;
    commit;

    v_html := '<table align="center" border="2px" style="border-collapse: collapse"   font-family: Arial">
                                        <tr>
                                            <th style="text-align:left;">Detalle del Proceso Masivo Resoluciones IGAC:</th>
                                        </tr>
                                        <tr>
                                            <td><b>Resolucion</td>
                                            <td><b>Radicacion</td>
                                            <td><b>Aplicada</td>
                                            <td><b>Codigo Respuesta</td>
                                            <td><b>Mensaje Respuesta</td>
                                        </tr>';

    for c_datos in (select *
                      from json_table(v_json,
                                      '$[*]' columns(id_impsto number PATH
                                              '$.ID_IMPSTO',
                                              id_impsto_sbmpsto number PATH
                                              '$.ID_IMPSTO_SBMPSTO',
                                              rslcion varchar2 PATH
                                              '$.RESOLUCION',
                                              rdccion varchar2 PATH
                                              '$.RADICACION'))
                     order by to_number(rslcion)) loop
      begin
        v_mnsje_rspsta := 'p_id_usrio: ' || p_id_usrio || ' - ' ||
                          'p_cdgo_clnte: ' || p_cdgo_clnte ||
                          'c_datos.id_impsto: ' || c_datos.id_impsto ||
                          ' - ' || 'c_datos.id_impsto_sbmpsto: ' ||
                          c_datos.id_impsto_sbmpsto || 'c_datos.rslcion: ' ||
                          c_datos.rslcion || ' - ' || 'c_datos.rdccion: ' ||
                          c_datos.rdccion;
        /*insert into muerto
          (n_001, v_001, c_001, t_001)
        values
          (100, 'MasivoIgac', v_mnsje_rspsta, systimestamp);
        commit;*/
        pkg_si_resolucion_predio.prc_ap_resolucion(p_id_usrio          => p_id_usrio,
                                                   p_cdgo_clnte        => p_cdgo_clnte,
                                                   p_id_impsto         => c_datos.id_impsto,
                                                   p_id_impsto_sbmpsto => c_datos.id_impsto_sbmpsto,
                                                   p_rslcion           => c_datos.rslcion,
                                                   p_rdccion           => c_datos.rdccion,
                                                   o_cdgo_rspsta       => v_cdgo_rspsta,
                                                   o_mnsje_rspsta      => v_mnsje_rspsta);

        -- Validamos si el registro de la resolucion devuelve error para notificarlo
        if v_cdgo_rspsta <> 0 then
          begin
            v_html := v_html || ' <tr>
                                    <td>' ||
                      c_datos.rslcion ||
                      '</td>
                                    <td>' ||
                      c_datos.rdccion ||
                      '</td>
                                    <td>No</td>
                                    <td>' ||
                      v_cdgo_rspsta ||
                      '</td>
                                    <td>' ||
                      v_mnsje_rspsta ||
                      '</td>
                                 </tr>';
            /*v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                               p_cdgo_dfncion_clnte        => 'USR');
            if v('APP_SESSION') is null then
              apex_session.create_session(p_app_id   => 69000,
                                          p_page_id  => 53,
                                          p_username => v_id_usrio_apex);
            end if;

            select email
              into v_correo
              from v_sg_g_usuarios
             where id_usrio = p_id_usrio;

            val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
            apex_util.set_security_group_id(p_security_group_id => val);

            apex_mail.send(p_to        => v_correo,
                           p_from      => v_correo,
                           p_subj      => 'Error en la Aplicacion Masiva Resoluciones Igac',
                           p_body      => '',
                           p_body_html => 'Codigo de respuesta: '||v_cdgo_rspsta||' - '||'Mensaje de respuesta: '||v_mnsje_rspsta);
            APEX_MAIL.PUSH_QUEUE;*/

          end;
        elsif v_cdgo_rspsta = 0 then
          v_html := v_html || ' <tr>
                   <td>' || c_datos.rslcion ||
                    '</td>
                   <td>' || c_datos.rdccion ||
                    '</td>
                   <td>Si</td>
                   <td>0</td>
                   <td>Aplicada exitosamente!</td>
                </tr>';

        end if;

      exception
        when others then
          null;
      end;
    end loop;

    v_html := v_html || ' </table>';

    begin

      v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                         p_cdgo_dfncion_clnte        => 'USR');
      if v('APP_SESSION') is null then
        apex_session.create_session(p_app_id   => 69000,
                                    p_page_id  => 53,
                                    p_username => v_id_usrio_apex);
      end if;

      select email
        into v_correo
        from v_sg_g_usuarios
       where id_usrio = p_id_usrio;

      v_mensaje := 'Despues de la session - ' || 'v_correo: ' || v_correo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => v_mensaje,
                            p_nvel_txto  => 1);

      val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
      apex_util.set_security_group_id(p_security_group_id => val);

      v_body_html := ' <br>Ha finalizado exitosamente el proceso de la Aplicacion Masiva de Resoluciones Igac.<br>A continuacion el detalle del proceso:<br>' ||
                     v_html;
      v_body      := 'Estimado Usuario,\nA continuacion encontrara el resumen del proceso de aplicacion masiva de las resoluciones:';
      apex_mail.send(p_to        => v_correo,
                     p_from      => v_correo,
                     p_subj      => 'Finalizacion del proceso de la Aplicacion Masiva de Resoluciones Igac',
                     p_body      => v_body,
                     p_body_html => v_body_html);
      APEX_MAIL.PUSH_QUEUE;
    end;
    /*insert into muerto
      (n_001, v_001, c_001, t_001)
    values
      (100, 'MasivoIgac', v_json, systimestamp);
    commit;*/
  exception
    when others then
      null;

  end prc_ap_rslcion_msva;

  procedure prc_gn_archvo_dscrga_rslcion(p_cdgo_clnte            in number,
                                         p_id_rslcion_igac_mnual in number,
                                         p_id_dprtmnto_clnte     in number,
                                         p_id_mncpio_clnte       in number,
                                         o_id_prcso_crga         out number,
                                         o_cdgo_rspsta           out number,
                                         o_mnsje_rspsta          out varchar2) as

    v_nl                number;
    v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_gn_archvo_dscrga_rslcion';
    v_fecha             varchar2(8);
    v_total_registros1  number(3);
    v_total_registros2  number(2);
    v_total_registros3  number(3);
    v_contador          number(3) := 0;
    v_contador2         number(3) := 0;
    v_contador3         number(3) := 0;
    v_frmto_mnda        varchar2(50) := 'FML999G999G999G999G990D00';
    v_cdna_lnea1        clob;
    v_cdna_lnea2        clob;
    v_cdna_lnea3        clob;
    v_dtos              clob;
    v_archivo           utl_file.file_type;
    v_destino_blob      blob := empty_blob();
    v_source_blob       bfile;
    v_nmbre_archvo      varchar2(100);
    v_drctrio           varchar2(100) := 'ETL_CARGA';
    v_id_crga           number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_vgncia            varchar2(4);
    v_rslcion           varchar2(50);
    v_fcha              varchar2(10);
    v_id_prdo           number;
    v_id_usrio          number;
    --v_file_name                varchar2(100);
    v_bfile     bfile;
    v_file_blob blob;
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'p_id_rslcion_igac_mnual ' ||
                          p_id_rslcion_igac_mnual,
                          1);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'C ' || p_cdgo_clnte || ' ID ' ||
                          p_id_rslcion_igac_mnual || ' D ' ||
                          p_id_dprtmnto_clnte || ' M ' || p_id_mncpio_clnte,
                          1);
    v_cdna_lnea1 := '';
    v_cdna_lnea2 := '';
    v_cdna_lnea3 := '';

    select a.rslcion_igac,
           to_char(a.fcha_rslcion_igac, 'ddmmyyyy'),
           decode(to_char(b.fcha_ingrso, 'yyyy'),
                  to_char(sysdate, 'yyyy') + 1,
                  to_char(sysdate, 'yyyy'),
                  to_char(b.fcha_ingrso, 'yyyy')),
           --to_char(b.fcha_ingrso,'yyyy'), 
           a.id_usrio_dgta
      into v_rslcion, v_fcha, v_vgncia, v_id_usrio
      from si_g_rslcion_igac_mnual a
      join si_g_rslcion_igac_mnual_dtlle b
        on a.id_rslcion_igac_mnual = b.id_rslcion_igac_mnual
     where a.id_rslcion_igac_mnual = p_id_rslcion_igac_mnual
       and (b.cncla_inscrbe = 'I' or b.cncla_inscrbe = 'C')
     fetch first 1 rows only;

    v_nmbre_archvo := 'RESOLUCION_' || v_rslcion || '_' || v_fcha || '.txt';
    v_archivo      := utl_file.fopen(v_drctrio, v_nmbre_archvo, 'w', 2100);

    select id_impsto, id_impsto_sbmpsto
      into v_id_impsto, v_id_impsto_sbmpsto
      from df_i_impuestos_subimpuesto
     where cdgo_impsto_sbmpsto = 'IPU'
       and cdgo_clnte = p_cdgo_clnte;

    for c_predio in (select DISTINCT (b.idntfccion_sjto)
                       from si_g_rslcion_igac_mnual a
                       join si_g_rslcion_igac_mnual_dtlle b
                         on a.id_rslcion_igac_mnual =
                            b.id_rslcion_igac_mnual /*join v_si_i_sujetos_impuesto c 
                                                                                                                                                                                                                                                                                                                                                                                                              on b.idntfccion_sjto = c.idntfccion_sjto and c.id_impsto = v_id_impsto*/
                      where a.id_rslcion_igac_mnual =
                            p_id_rslcion_igac_mnual
                      order by b.idntfccion_sjto) loop
      v_total_registros1 := 0;
      v_contador         := 0;
      select count(*)
        into v_total_registros1
        from si_g_rslcion_igac_mnual a
        join si_g_rslcion_igac_mnual_dtlle b
          on a.id_rslcion_igac_mnual = b.id_rslcion_igac_mnual /*join v_si_i_sujetos_impuesto c 
                                                                                                                         on b.idntfccion_sjto = c.idntfccion_sjto and c.id_impsto = v_id_impsto*/
       where a.id_rslcion_igac_mnual = p_id_rslcion_igac_mnual
         and b.cncla_inscrbe = 'I'
         and b.idntfccion_sjto = c_predio.idntfccion_sjto;
      for c_rslcion1 in (select a.rslcion_igac,
                                a.rdccion_igac,
                                a.fcha_rslcion_igac,
                                a.tpo_trmte,
                                a.clse_mtcion,
                                b.idntfccion_sjto,
                                b.cdgo_idntfccion_tpo,
                                b.idntfccion_rspnsble,
                                b.prmer_nmbre,
                                b.drccion,
                                b.cdgo_dstno_igac,
                                nvl(b.area_trrno, 0) area_trrno,
                                nvl(b.area_cnstrda, 0) area_cnstrda,
                                nvl(b.avluo_ctstral, 0) avluo_ctstral,
                                b.fcha_ingrso,
                                b.cncla_inscrbe,
                                c.idntfccion_antrior
                           from si_g_rslcion_igac_mnual a
                           join si_g_rslcion_igac_mnual_dtlle b
                             on a.id_rslcion_igac_mnual =
                                b.id_rslcion_igac_mnual
                           left join v_si_i_sujetos_impuesto c
                             on b.idntfccion_sjto = c.idntfccion_sjto
                            and c.id_impsto = v_id_impsto
                          where a.id_rslcion_igac_mnual =
                                p_id_rslcion_igac_mnual
                            and b.idntfccion_sjto = c_predio.idntfccion_sjto
                          order by b.idntfccion_sjto, b.cncla_inscrbe) loop
        if (c_rslcion1.cncla_inscrbe = 'C') then
          v_fecha      := to_char(c_rslcion1.fcha_ingrso, 'ddmmyyyy');
          v_cdna_lnea1 := lpad(p_id_dprtmnto_clnte, '2', '0') ||
                          lpad(p_id_mncpio_clnte, '3', '0') ||
                          lpad(c_rslcion1.rslcion_igac, '13', '0') ||
                          lpad(c_rslcion1.rdccion_igac, '15', '0') ||
                          lpad(c_rslcion1.tpo_trmte, '2', '0') ||
                          lpad(c_rslcion1.clse_mtcion, '1', '0') ||
                          lpad(c_rslcion1.idntfccion_sjto, '25', '0') ||
                          lpad(c_rslcion1.cncla_inscrbe, '1', '0') ||
                          lpad(1, '1', '0') || lpad(1, '3', '0') ||
                          lpad(1, '3', '0') ||
                          rpad(c_rslcion1.prmer_nmbre, '100', ' ') ||
                          rpad(0, '1', '0') ||
                          rpad(c_rslcion1.cdgo_idntfccion_tpo, '1', ' ') ||
                          lpad(c_rslcion1.idntfccion_rspnsble, '12', '0') ||
                          rpad(c_rslcion1.drccion, '100', ' ') ||
                          rpad(0, '1', '0') ||
                          rpad(c_rslcion1.cdgo_dstno_igac, '1', ' ') ||
                          lpad(c_rslcion1.area_trrno, '15', '0') ||
                          lpad(c_rslcion1.area_cnstrda, '6', '0') ||
                          lpad(c_rslcion1.avluo_ctstral, '15', '0') ||
                          lpad(v_fecha, '8', '0') ||
                          lpad(c_rslcion1.idntfccion_antrior, '15', '0') ||
                          lpad(' ', '66', ' ');
        end if;

        if (c_rslcion1.cncla_inscrbe = 'I') then
          v_contador   := v_contador + 1;
          v_fecha      := to_char(c_rslcion1.fcha_ingrso, 'ddmmyyyy');
          v_cdna_lnea1 := lpad(p_id_dprtmnto_clnte, '2', '0') ||
                          lpad(p_id_mncpio_clnte, '3', '0') ||
                          lpad(c_rslcion1.rslcion_igac, '13', '0') ||
                          lpad(c_rslcion1.rdccion_igac, '15', '0') ||
                          lpad(c_rslcion1.tpo_trmte, '2', '0') ||
                          lpad(c_rslcion1.clse_mtcion, '1', '0') ||
                          lpad(c_rslcion1.idntfccion_sjto, '25', '0') ||
                          lpad(c_rslcion1.cncla_inscrbe, '1', '0') ||
                          lpad(1, '1', '0') || lpad(v_contador, '3', '0') ||
                          lpad(v_total_registros1, '3', '0') ||
                          rpad(c_rslcion1.prmer_nmbre, '100', ' ') ||
                          rpad(0, '1', '0') ||
                          rpad(c_rslcion1.cdgo_idntfccion_tpo, '1', ' ') ||
                          lpad(c_rslcion1.idntfccion_rspnsble, '12', '0') ||
                          rpad(c_rslcion1.drccion, '100', ' ') ||
                          rpad(0, '1', '0') ||
                          rpad(c_rslcion1.cdgo_dstno_igac, '1', ' ') ||
                          lpad(c_rslcion1.area_trrno, '15', '0') ||
                          lpad(c_rslcion1.area_cnstrda, '6', '0') ||
                          lpad(c_rslcion1.avluo_ctstral, '15', '0') ||
                          lpad(v_fecha, '8', '0') ||
                          lpad(c_rslcion1.idntfccion_antrior, '15', '0') ||
                          lpad(' ', '66', ' ');
        end if;

        -- Se asigna la cadena creada a la variable v_dtos para ser guardada en el archivo
        v_dtos := v_cdna_lnea1;

        -- Se guardar la cadena v_dtos en el archivo
        utl_file.put_line(v_archivo, v_dtos);

      end loop;
    end loop;

    select count(*)
      into v_total_registros2
      from si_g_rslcion_igac_mnual a
      join si_g_rslcion_igac_mnual_dtlle b
        on a.id_rslcion_igac_mnual = b.id_rslcion_igac_mnual /*join v_si_i_sujetos_impuesto c 
                                                                                        on b.idntfccion_sjto = c.idntfccion_sjto and c.id_impsto = v_id_impsto*/
     where a.id_rslcion_igac_mnual = p_id_rslcion_igac_mnual
     order by b.idntfccion_sjto, b.cncla_inscrbe;

    for c_rslcion2 in (select DISTINCT a.rslcion_igac,
                                       a.rdccion_igac,
                                       a.fcha_rslcion_igac,
                                       a.tpo_trmte,
                                       a.clse_mtcion,
                                       b.idntfccion_sjto,
                                       b.mtrcla_inmblria,
                                       nvl(b.area_trrno, 0) area_trrno,
                                       nvl(b.area_cnstrda, 0) area_cnstrda,
                                       b.cncla_inscrbe
                         from si_g_rslcion_igac_mnual a
                         join si_g_rslcion_igac_mnual_dtlle b
                           on a.id_rslcion_igac_mnual =
                              b.id_rslcion_igac_mnual /*join v_si_i_sujetos_impuesto c 
                                                                                                                                                                                                                                                                                                                                                                                                                                              on b.idntfccion_sjto = c.idntfccion_sjto and c.id_impsto = v_id_impsto*/
                        where a.id_rslcion_igac_mnual =
                              p_id_rslcion_igac_mnual
                        order by b.idntfccion_sjto, b.cncla_inscrbe) loop

      --v_contador3 := v_contador3 + 1;
      if (c_rslcion2.mtrcla_inmblria is not null) then
        v_cdna_lnea2 := lpad(p_id_dprtmnto_clnte, '2', '0') ||
                        lpad(p_id_mncpio_clnte, '3', '0') ||
                        lpad(c_rslcion2.rslcion_igac, '13', '0') ||
                        lpad(c_rslcion2.rdccion_igac, '15', '0') ||
                        lpad(c_rslcion2.tpo_trmte, '2', '0') ||
                        lpad(c_rslcion2.clse_mtcion, '1', '0') ||
                        lpad(c_rslcion2.idntfccion_sjto, '25', '0') ||
                        lpad(c_rslcion2.cncla_inscrbe, '1', '0') ||
                        lpad(2, '1', '0') || lpad(1, '3', '0') ||
                        lpad(1, '3', '0') ||
                        rpad(c_rslcion2.mtrcla_inmblria, '18', ' ') ||
                        rpad(' ', '33', ' ') || --Espacio 1
                        lpad(0, '3', '0') || --zona fisica 1
                        lpad(0, '3', '0') || --zona economica 1
                        lpad(c_rslcion2.area_trrno, '15', '0') ||
                        rpad(' ', '33', ' ') || --Espacio 2
                        lpad(0, '3', '0') || --zona fisica 2
                        lpad(0, '3', '0') || --zona economica 2
                        lpad(c_rslcion2.area_trrno, '15', '0') ||
                        rpad(' ', '33', ' ') || --Espacio 3
                        lpad(0, '2', '0') || --Habitaciones 1
                        lpad(0, '2', '0') || --Ba?os 1
                        lpad(0, '2', '0') || --Locales 1
                        lpad(0, '2', '0') || --Piso 1
                        lpad(0, '2', '0') || --Tipificacion 1
                        lpad(0, '3', '0') || --Uso 1
                        lpad(0, '2', '0') || --Puntaje 1
                        lpad(c_rslcion2.area_cnstrda, '6', '0') ||
                        lpad(0, '6', '0') || rpad(' ', '33', ' ') ||
                        rpad(0, '27', '0') || rpad(' ', '33', ' ') ||
                        rpad(0, '27', '0') || rpad(' ', '38', ' ') ||
                        rpad(0, '15', '0');

        -- Se asigna la cadena creada a la variable v_dtos para ser guardada en el archivo
        v_dtos := v_cdna_lnea2;

        -- Se guardar la cadena v_dtos en el archivo
        utl_file.put_line(v_archivo, v_dtos);
      end if;
    end loop;

    for c_predio in (select DISTINCT (b.idntfccion_sjto)
                       from si_g_rslcion_igac_mnual a
                       join si_g_rslcion_igac_mnual_dtlle b
                         on a.id_rslcion_igac_mnual =
                            b.id_rslcion_igac_mnual /*join v_si_i_sujetos_impuesto c 
                                                                                                                                                                                                                                                                                                                                                                                                              on b.idntfccion_sjto = c.idntfccion_sjto and c.id_impsto = v_id_impsto*/
                      where a.id_rslcion_igac_mnual =
                            p_id_rslcion_igac_mnual
                      order by b.idntfccion_sjto) loop
      v_total_registros3 := 0;
      v_contador2        := 0;

      select count(*)
        into v_total_registros3
        from si_g_rslcion_igac_mnual a
        join si_g_rslcion_igac_mnual_dtlle b
          on a.id_rslcion_igac_mnual = b.id_rslcion_igac_mnual
        join si_g_rslcion_igac_mnual_dcrts c
          on b.id_rslcion_igac_mnual_dtlle = c.id_rslcion_igac_mnual_dtlle
       where a.id_rslcion_igac_mnual = p_id_rslcion_igac_mnual
         and b.idntfccion_sjto = c_predio.idntfccion_sjto;

      for c_rslcion3 in (select a.rslcion_igac,
                                a.rdccion_igac,
                                a.fcha_rslcion_igac,
                                a.tpo_trmte,
                                a.clse_mtcion,
                                b.idntfccion_sjto,
                                b.cncla_inscrbe,
                                nvl(c.idntfccion_antrior, b.idntfccion_sjto) idntfccion_antrior,
                                d.dcrto,
                                nvl(d.avluo_ctstral, 0) avluo_ctstral,
                                d.fecha_vgncia_fscal
                           from si_g_rslcion_igac_mnual a
                           join si_g_rslcion_igac_mnual_dtlle b
                             on a.id_rslcion_igac_mnual =
                                b.id_rslcion_igac_mnual
                           left join v_si_i_sujetos_impuesto c
                             on b.idntfccion_sjto = c.idntfccion_sjto
                            and c.id_impsto = v_id_impsto
                           join si_g_rslcion_igac_mnual_dcrts d
                             on b.id_rslcion_igac_mnual_dtlle =
                                d.id_rslcion_igac_mnual_dtlle
                          where a.id_rslcion_igac_mnual =
                                p_id_rslcion_igac_mnual
                            and b.idntfccion_sjto = c_predio.idntfccion_sjto) loop
        v_contador2  := v_contador2 + 1;
        v_cdna_lnea3 := lpad(p_id_dprtmnto_clnte, '2', '0') ||
                        lpad(p_id_mncpio_clnte, '3', '0') ||
                        lpad(c_rslcion3.rslcion_igac, '13', '0') ||
                        lpad(c_rslcion3.rdccion_igac, '15', '0') ||
                        lpad(c_rslcion3.tpo_trmte, '2', '0') ||
                        lpad(c_rslcion3.clse_mtcion, '1', '0') ||
                        lpad(c_rslcion3.idntfccion_sjto, '25', '0') ||
                        lpad(c_rslcion3.cncla_inscrbe, '1', '0') ||
                        lpad(3, '1', '0') || lpad(v_contador2, '3', '0') ||
                        lpad(v_total_registros3, '3', '0') ||
                        lpad('DECRETO ', '8', ' ') ||
                        lpad(c_rslcion3.dcrto, '9', ' ') ||
                        lpad(to_char(c_rslcion3.avluo_ctstral, v_frmto_mnda),
                             '25',
                             ' ') || lpad('VIGENCIA FISCAL: ', '18', ' ') ||
                        lpad(to_char(c_rslcion3.fecha_vgncia_fscal,
                                     'dd/mm/yyyy'),
                             '10',
                             ' ') || lpad(' ', '256', ' ') ||
                        rpad(c_rslcion3.idntfccion_antrior, '15', ' ');

        -- Se asigna la cadena creada a la variable v_dtos para ser guardada en el archivo
        v_dtos := v_cdna_lnea3;

        -- Se guardar la cadena v_dtos en el archivo
        utl_file.put_line(v_archivo, v_dtos);

      end loop;
    end loop;

    -- 4.1 Se Cierra el Archivo
    utl_file.fclose(v_archivo);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_archivo ',
                          1);

    -- 4.2 Asignacion del ruta del archivo
    v_source_blob := bfilename(v_drctrio, v_nmbre_archvo);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'PASO v_source_blob',
                          1);

    -- 4.4 Se asigna el blob a la variable file_blob
    dbms_lob.open(v_source_blob, dbms_lob.lob_readonly);
    dbms_lob.createtemporary(v_destino_blob, true);
    dbms_lob.loadfromfile(dest_lob => v_destino_blob,
                          src_lob  => v_source_blob,
                          amount   => dbms_lob.getlength(v_source_blob));

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'PASO dbms_lob.open',
                          1);

    -- 4. Se cierra el archivo
    dbms_lob.close(v_source_blob);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'PASO dbms_lob.close',
                          1);

    -- 4. Se elimina el archivo del directorio
    --utl_file.fremove(v_drctrio, v_nmbre_archvo);
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'BORRO EL ARCHIVO' , 1);
    v_id_crga := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                 p_cdgo_dfncion_clnte_ctgria => 'RSL',
                                                                 p_cdgo_dfncion_clnte        => 'CRI');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_crga ' || v_id_crga,
                          1);

    select a.id_prdo
      into v_id_prdo
      from df_i_periodos a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = v_id_impsto
       and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
       and a.vgncia = v_vgncia;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Paso select 2 ',
                          1);

    --v_file_name := 'RESOLUCION_'||v_rslcion||'_'||v_fcha||'.txt';

    --Guarda el Proceso Carga      
    begin
      insert into et_g_procesos_carga
        (id_crga,
         cdgo_clnte,
         id_impsto,
         vgncia,
         file_blob,
         file_name,
         file_mimetype,
         cdgo_prcso_estdo,
         lneas_encbzdo,
         id_impsto_sbmpsto,
         id_prdo,
         id_usrio,
         id_prcso_crga_pdre,
         indcdor_prcsdo)
      values
        (v_id_crga,
         p_cdgo_clnte,
         v_id_impsto,
         v_vgncia,
         v_destino_blob,
         v_nmbre_archvo,
         'text/plain',
         'SE',
         0,
         v_id_impsto_sbmpsto,
         v_id_prdo,
         v_id_usrio,
         null,
         'N')
      returning id_prcso_crga into o_id_prcso_crga;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Inserto en et_g_procesos_carga ',
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible crear el proceso carga, para la resolucion tipo' ||
                          v_rslcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nl,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;

    /* v_bfile := bfilename( v_drctrio , v_file_name );

    --Abrir Apuntador del Archivo
    dbms_lob.open( v_bfile , dbms_lob.lob_readonly );

    dbms_lob.loadfromfile( dest_lob => v_file_blob
                         , src_lob  => v_bfile
                         , amount => dbms_lob.getlength(v_bfile));

    --Cerrar Apuntador del Archivo
    dbms_lob.close(v_bfile);*/

    /*o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Encontro el archivo ';
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',  v_nl, o_mnsje_rspsta, 1); 

    -- Se determina el tipo de archivo
    owa_util.mime_header('application/octet', FALSE); 

    -- Se determina el tama?o del archivo
    htp.p('Content-length: '|| dbms_lob.getlength(v_destino_blob));

    -- Se determina el nombre del archivo
    htp.p('Content-Disposition: attachment; filename="'||to_char(sysdate,'YYYY-MM-DD') || '_'|| 'ARCHIVO_IMPRESOR_PRUEBA.txt'||'"');

    owa_util.http_header_close;

    -- Se descarga el archivo
    wpg_docload.download_file(v_destino_blob);*/

  exception
    when others then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Otro tipo de error ',
                            1);
      return;

  end prc_gn_archvo_dscrga_rslcion;

    /*
    * @Descripción  : Actualiza la direccion por cambio de propietario (Resolución Igac)
    * @Creación     : 26/09/2022
    * @Modificación : 26/06/2022
    */

    procedure prc_ac_prdio_rslcion_drccn( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                            p_id_impsto         in df_c_impuestos.id_impsto%type,
                                            p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                            p_rslcion           in varchar2,
                                            p_rdccion           in varchar2,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2) 
    as
        v_nvel          number;
        v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_resolucion_predio.prc_ac_prdio_rslcion_drccn';
        v_rslcn_ttl     number;
        v_drccion       si_c_sujetos.drccion%type;
    begin

    --Respuesta Exitosa
    o_cdgo_rspsta := 0;

    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);

    o_mnsje_rspsta := 'Inicio del procedimiento. Resolución: ' || p_rslcion||' - Radicación: '||p_rdccion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, 1);

    --Cursor de Predios
    for c_prdios in (select a.rfrncia_igac
                       from si_g_resolucion_igac_t1 a
                      where a.id_prcso_crga in
                            (select b.id_prcso_crga
                               from et_g_procesos_carga b
                              where b.id_prcso_crga = a.id_prcso_crga
                                and b.cdgo_clnte = p_cdgo_clnte
                                and b.id_impsto = p_id_impsto
                                and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                        and a.rslcion = p_rslcion
                        and a.rdccion = p_rdccion
                        group by a.rfrncia_igac) 
    loop

        --Validamos que la dirección que se va a actualizar sea la del predio que se cancela e inscribe
 /***       begin
            select count(1) into v_rslcn_ttl
               from si_g_resolucion_igac_t1 a
              where a.id_prcso_crga in
                    (select b.id_prcso_crga
                       from et_g_procesos_carga b
                      where b.id_prcso_crga = a.id_prcso_crga
                        and b.cdgo_clnte = p_cdgo_clnte
                        and b.id_impsto = p_id_impsto
                        and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                and a.rslcion = p_rslcion
                and a.rdccion = p_rdccion
                and a.rfrncia_igac = c_prdios.rfrncia_igac;
        exception
          when others then
               --Válida si el Predio Existe
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := 'Para la referencia #' ||
                                c_prdios.rfrncia_igac ||
                                ', valide los registros de cancela - inscribe para la resolucion igac.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
             continue;
        end;

        if ( v_rslcn_ttl > 1 ) then***/

            --Verifica dirección a actualizar    
            begin
              select a.drccion into v_drccion
               from si_g_resolucion_igac_t1 a
              where a.id_prcso_crga in
                    (select b.id_prcso_crga
                       from et_g_procesos_carga b
                      where b.id_prcso_crga = a.id_prcso_crga
                        and b.cdgo_clnte = p_cdgo_clnte
                        and b.id_impsto = p_id_impsto
                        and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto)
                and a.rslcion = p_rslcion
                and a.rdccion = p_rdccion
                and a.rfrncia_igac = c_prdios.rfrncia_igac
                and a.cncla_inscrbe = 'I'
                and rownum < 2 ;

                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_drccion: '||v_drccion, 1);

            exception
                when no_data_found then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := 'Para la referencia #' || c_prdios.rfrncia_igac ||
                                    ', No se pudo encontrar la dirección del predio en la resolución.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                        p_id_impsto  => null,
                                        p_nmbre_up   => v_nmbre_up,
                                        p_nvel_log   => v_nvel,
                                        p_txto_log   => o_mnsje_rspsta,
                                        p_nvel_txto  => 3);
                    continue;
                when others then
                      o_cdgo_rspsta  := 20;
                      o_mnsje_rspsta := 'Para la referencia #' || c_prdios.rfrncia_igac ||
                                        ', Problemas al consultar la dirección del predio en la resolución...'||sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_impsto  => null,
                                            p_nmbre_up   => v_nmbre_up,
                                            p_nvel_log   => v_nvel,
                                            p_txto_log   => o_mnsje_rspsta,
                                            p_nvel_txto  => 3);
                     continue;
            end;

            if v_drccion is not null then
                -- Actualiza dirección del sujeto
                begin
                    update  si_c_sujetos a 
                    set     a.drccion = v_drccion
                    where   a.cdgo_clnte = p_cdgo_clnte
                    and     a.idntfccion = c_prdios.rfrncia_igac;

					--pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'update  si_c_sujeto', 1);

                exception 
                    when others then
                          o_cdgo_rspsta  := 30;
                          o_mnsje_rspsta := 'Para la referencia #' ||
                                            c_prdios.rfrncia_igac ||
                                            ', Problemas al actualizar la dirección del predio.';
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                                p_id_impsto  => null,
                                                p_nmbre_up   => v_nmbre_up,
                                                p_nvel_log   => v_nvel,
                                                p_txto_log   => o_mnsje_rspsta,
                                                p_nvel_txto  => 3);
                         continue;
                end;

                -- Actualiza dirección de notificación del sujeto-impuetso
                begin
                    update  si_i_sujetos_impuesto 
                    set     drccion_ntfccion = v_drccion
                    where   id_sjto in (
                                    select id_sjto from si_c_sujetos a
                                    where a.cdgo_clnte = p_cdgo_clnte
                                    and a.idntfccion = c_prdios.rfrncia_igac);
					--pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'update  si_i_sujetos_impuesto', 1);
                exception
                    when others then
                          o_cdgo_rspsta  := 40;
                          o_mnsje_rspsta := 'Para la referencia #' ||
                                            c_prdios.rfrncia_igac ||
                                            ', Problemas al actualizar la dirección del predio de notificación.';
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                                p_id_impsto  => null,
                                                p_nmbre_up   => v_nmbre_up,
                                                p_nvel_log   => v_nvel,
                                                p_txto_log   => o_mnsje_rspsta,
                                                p_nvel_txto  => 3);
                         continue;
                end;

            end if;

            --Actualiza la Matricula del Predio
            pkg_si_resolucion_predio.prc_ac_matricula_prdio( p_cdgo_clnte        => p_cdgo_clnte,
                                                              p_id_impsto         => p_id_impsto,
                                                              p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                              p_rfrncia           => c_prdios.rfrncia_igac,
                                                              p_rslcion           => p_rslcion,
                                                              p_rdccion           => p_rdccion,
                                                              o_cdgo_rspsta       => o_cdgo_rspsta,
                                                              o_mnsje_rspsta      => o_mnsje_rspsta);

            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, p_nvel_txto  => 3);
                return;
            end if;        

       -- end if;
    end loop;

    if o_cdgo_rspsta = 0 then
        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, 1);

        o_mnsje_rspsta := 'Predios actualizados con exito.';
    end if;

    exception
        when others then
          o_cdgo_rspsta  := 100;
          o_mnsje_rspsta := 'No fue posible actualizar la dirección' ||
                            ', inténtelo más tarde.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                                sqlerrm),
                                p_nvel_txto  => 3);

    end prc_ac_prdio_rslcion_drccn;

end pkg_si_resolucion_predio;


/
