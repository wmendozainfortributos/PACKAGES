--------------------------------------------------------
--  DDL for Package Body PKG_GD_UTILIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GD_UTILIDADES" is 

  /* fnc_vl_archvo_exstnte
	   Funcion que retorna S si el archivo p_nmbre_archvo existe en el directorio
	   de lo contrario retorna  N */
  function fnc_vl_archvo_exstnte (p_directorio varchar2, p_nmbre_archvo varchar2) return varchar2 is 
    v_respuesta varchar2(5) := 'N';
    v_bfile     bfile;
    v_sqlerrm   varchar2(2000);
  begin
    v_bfile     :=  bfilename(p_directorio, p_nmbre_archvo);
    if (dbms_lob.fileexists(v_bfile) = 1) then
      v_respuesta := 'S';
      return v_respuesta;
    else
      return v_respuesta;
    end if;
  exception when dbms_lob.noexist_directory then
    v_sqlerrm := sqlerrm;
    return v_sqlerrm;
  end;

  /* fnc_vl_archvo_blqdo
	   Funcion que retorna S si el archivo esta bloqueado de lo contrario retorna  N */
  function fnc_vl_archvo_blqdo (p_directorio varchar2, p_nmbre_archvo varchar2) return varchar2 is 
		v_archivo_bloqueado varchar2(2) := 'S';
		v_archivo		        utl_file.file_type;
    v_up                varchar2(100);
  begin
    v_archivo := utl_file.fopen (p_directorio, p_nmbre_archvo, 'w');
		utl_file.fclose(v_archivo); 
		v_archivo_bloqueado := 'N';
		return v_archivo_bloqueado;
  exception
		when utl_file.invalid_operation then
      utl_file.fclose(v_archivo); 
			return v_archivo_bloqueado;
  end;

  /* prc_co_archco_dsco
	   proceso que devuelve un blob si no ocurre ningun error
     de lo contrario devuelve codigo 10 y mensaje de error */
  procedure prc_co_archco_dsco (p_directorio    varchar2    default null
                              , p_nmbre_archvo  varchar2    default null
                              , p_bfile         bfile       default null
                              , o_archvo_blob   out blob
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2) as
    pragma autonomous_transaction;
    v_bfile       bfile;
    v_blob        blob;
    v_sqlerrm     varchar2(2000);
    v_blob_length integer;
  begin

    -- Inicializamos el v_blob
    update gd_g_dummy
    set file_blob = empty_blob()
    where id_dmmy = 1
    returning file_blob into v_blob;

    if sql%notfound then
        dbms_output.put_line('[pkg_gd_utilidades.prc_co_archco_dsco] No Update');
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := '[pkg_gd_utilidades.prc_co_archco_dsco] No Update Dummy.';
        return;
    end if;

    --v_bfile := case when p_bfile is null then bfilename(p_directorio, p_nmbre_archvo) else p_bfile end;

    if p_bfile is not null then 
      v_bfile := p_bfile;
      dbms_output.put_line('p_bfile not null');
    elsif p_directorio is not null and p_nmbre_archvo is not null then
        -- Si el archivo existe 
        if fnc_vl_archvo_exstnte(p_directorio, p_nmbre_archvo) = 'N' then
            v_sqlerrm := sqlerrm;
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := '[prc_co_archco_dsco] Archivo no existente';
            return;
        end if;

        v_bfile := bfilename(p_directorio, p_nmbre_archvo);
      dbms_output.put_line('p_bfile null');
    end if;

    -- Tamaño del archivo
    v_blob_length := dbms_lob.getlength(v_bfile);
    if v_blob_length < 5 then
        dbms_output.put_line('[pkg_gd_utilidades.prc_co_archco_dsco] Tamaño del archivo igual a 0.');
        o_cdgo_rspsta := 30;
        o_mnsje_rspsta := '[pkg_gd_utilidades.prc_co_archco_dsco] No Update Dummy';
        return;
    end if;

    -- Abrimos y extraemos el archivo
    dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
    dbms_lob.loadfromfile(v_blob, v_bfile, v_blob_length);

     insert into muerto (n_001,v_001) values (5050,'6 - Entrando');commit;

    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Archivo extraido correctamente.';
    o_archvo_blob := v_blob;
    commit;
    dbms_lob.fileclose(v_bfile);

  exception when others then
    commit;
    v_sqlerrm := sqlerrm;
    o_cdgo_rspsta := 200;
    o_mnsje_rspsta := '[prc_co_archco_dsco] Exception: ' || v_sqlerrm;
    dbms_lob.fileclose(v_bfile);
  end;

  procedure prc_co_archco_dsco_id (p_id_dcmnto      number
                                 , o_archvo_blob    out blob
                                 , o_cdgo_rspsta    out number
                                 , o_mnsje_rspsta   out varchar2) as
    v_bfile   bfile;
    v_blob    blob;
    v_sqlerrm varchar2(2000);
  begin
    select file_blob, file_bfile into v_blob, v_bfile
    from gd_g_documentos
    where id_dcmnto  = p_id_dcmnto;

    if sql%notfound then
        dbms_output.put_line('[pkg_gd_utilidades.prc_co_archco_dsco_id] No select');
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := '[pkg_gd_utilidades.prc_co_archco_dsco_id] ID Documento no existente -gd_g_documentos-.';
        return;
    end if;


    if v_bfile is null then

        if v_blob is not null then
            o_archvo_blob := v_blob;
            o_cdgo_rspsta := 0;
            o_mnsje_rspsta := 'Archivo en base de datos columna file_blob';
        else
            -- v_blob es Nulo
            o_archvo_blob := v_blob;
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := 'El documento no contine archivo en file_blob ni en file_bfile';
            return;
        end if;
    else 
        pkg_gd_utilidades.prc_co_archco_dsco(p_bfile         => v_bfile
                                         , o_archvo_blob   => v_blob
                                         , o_cdgo_rspsta   => o_cdgo_rspsta
                                         , o_mnsje_rspsta  => o_mnsje_rspsta);

        if o_cdgo_rspsta = 0 then 
            o_archvo_blob := v_blob;
        else
            dbms_output.put_line('[pkg_gd_utilidades.prc_co_archco_dsco_id] No se puedo extraer el documento.');
            o_cdgo_rspsta := 30;
            o_mnsje_rspsta := '[pkg_gd_utilidades.prc_co_archco_dsco_id] No se puedo extraer el documento del Disco.';
        end if;
    end if;

  exception when others then
        o_cdgo_rspsta := 200;
        o_mnsje_rspsta := '[pkg_gd_utilidades.prc_co_archco_dsco_id] Exception: ' || sqlerrm;
  end prc_co_archco_dsco_id;


  procedure prc_rg_dcmnto_dsco (p_blob          in blob
                              , p_directorio    in varchar2
                              , p_nmbre_archvo  in varchar2
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2) is
    v_file      utl_file.file_type;
    v_buffer    raw(32767);
    v_amount    binary_integer := 32767;
    v_pos       integer := 1;
    v_blob_len  integer := dbms_lob.getlength(p_blob);
    v_sqlerrm   varchar2(2000);
  begin
    -- Crear o abrir archivo destino.
    v_file := utl_file.fopen(p_directorio, p_nmbre_archvo,'wb', 32767);
    -- Lea fragmentos del BLOB y escríbalos en el archivo hasta que se complete.
    while v_pos <= v_blob_len loop
      dbms_lob.read(p_blob, v_amount, v_pos, v_buffer);
      utl_file.put_raw(v_file, v_buffer, true);
      v_pos := v_pos + v_amount;
    end loop;
    -- Close the file.
    utl_file.fclose(v_file);
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Archivo cargado con exito.';

  exception when others then
      v_sqlerrm := sqlerrm;
      -- Cierra el archivo si algo sale mal.
      if utl_file.is_open(v_file) then
        utl_file.fclose(v_file);
      end if;
      o_cdgo_rspsta := 10;
      o_mnsje_rspsta := '[prc_rg_dcmnto_dsco] Exception: ' || sqlerrm;
  end prc_rg_dcmnto_dsco;

  procedure prc_el_archvo_dsco (p_directorio    varchar2
                              , p_nmbre_archvo  varchar2
                              , o_cdgo_rspsta   out number
                              , o_mnsje_rspsta  out varchar2) as
  begin 
    if fnc_vl_archvo_exstnte(p_directorio, p_nmbre_archvo) = 'S' and fnc_vl_archvo_blqdo(p_directorio, p_nmbre_archvo) = 'N' then
      begin
        -- ELiminamos Archivo
				utl_file.fremove( p_directorio, p_nmbre_archvo );

				o_cdgo_rspsta   := 0;
				o_mnsje_rspsta  := 'Archivo eliminado correctamente.';
      exception
			  when utl_file.invalid_operation then
				o_cdgo_rspsta   := 201;
				o_mnsje_rspsta  := 'Ocurrio un error, el archivo no pudo ser eliminado.';
				return;
			end;
    else
    	o_cdgo_rspsta   := 200;
			o_mnsje_rspsta  := 'El archivo no existe o esta bloqueado.';
    end if;
  end;


 /* fnc_vl_archvo_exstnte
	   Funcion que retorna S si el archivo p_file_bfile existe en el directorio
	   de lo contrario retorna  N */
  function fnc_vl_archvo_exstnte (p_bfile bfile) return varchar2 is 
    v_respuesta varchar2(5) := 'N';
    v_sqlerrm   varchar2(2000);
  begin
    if (dbms_lob.fileexists(p_bfile) = 1) then
      v_respuesta := 'S';
      return v_respuesta;
    else
      return v_respuesta;
    end if;
  exception 
    when dbms_lob.noexist_directory then
      return 'El directorio no existe';
    when others then
        v_sqlerrm   := sqlerrm;
        return v_sqlerrm;
  end;


  function fnc_co_blob (p_id_acto number)  return blob is 

    v_bfile         bfile;
    v_blob          blob;
    v_sqlerrm       varchar2(2000);
    o_cdgo_rspsta   number;
    o_mnsje_rspsta varchar2(200);
    o_archvo_blob  blob;
  begin
    select 	file_blob, file_bfile 
	into 	v_blob, v_bfile
    from 	v_gn_g_actos 
    where 	id_acto  = p_id_acto;

    if sql%notfound then
         o_cdgo_rspsta := 10;
        o_mnsje_rspsta := 'No se encontro el acto.'; 
    end if;

    if v_bfile is null then
      o_archvo_blob := v_blob;
      return o_archvo_blob;
    else 
      pkg_gd_utilidades.prc_co_archco_dsco(p_bfile         => v_bfile
                                         , o_archvo_blob   => v_blob
                                         , o_cdgo_rspsta   => o_cdgo_rspsta
                                         , o_mnsje_rspsta  => o_mnsje_rspsta);

      if o_cdgo_rspsta = 0 then 
        o_archvo_blob := v_blob;
    	return o_archvo_blob;
      else
         o_cdgo_rspsta := 10;
        o_mnsje_rspsta := ' No se puedo extraer el documento.';
      end if;
    end if;

    exception when others then
        o_cdgo_rspsta := 200;
        o_mnsje_rspsta := ' Exception: ' || v_sqlerrm;
  end fnc_co_blob;


    -- get_nombre_directorio
    -- Obtiene el Nombre de la Carpeta del BFILE
    function fnc_co_nombre_directorio ( p_file_bfile bfile ) return varchar2 is
        v_directorio	varchar2(300);
        v_archivo		varchar2(300);
    begin
        if p_file_bfile is null then
            return null;
        else
            dbms_lob.filegetname ( p_file_bfile, v_directorio, v_archivo );
        end if;

        return v_directorio;
    exception
        when others then
            return null;
    end;


    -- get_nombre_archivo
	-- Obtiene el Nombre del Archivo del BFILE
	function fnc_co_nombre_archivo ( p_file_bfile bfile ) return varchar2 as
		v_directorio	varchar2(300);
		v_archivo		varchar2(300);
	begin
		if p_file_bfile is null then
			return null;
		else
			dbms_lob.filegetname ( p_file_bfile, v_directorio, v_archivo );
		end if;

		return v_archivo;
	exception
		when others then
			return null;
	end;

end pkg_gd_utilidades;

/
