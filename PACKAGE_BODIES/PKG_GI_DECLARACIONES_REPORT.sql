--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES_REPORT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES_REPORT" as
    
    function fnc_gn_atributos_orgen_sql		   (p_orgen	in	varchar2)
	return varchar2 as 
		v_atributos	varchar2(32000);
	begin
		select	listagg(atributo, ',') within group (order by atributo) "atributo"
		into	v_atributos
		from(
			select regexp_substr(p_orgen, '\RGN[0-9]+ATR[0-9]+FLAX+', 1, level) as atributo
			from dual connect by regexp_substr(p_orgen, '\RGN[0-9]+ATR[0-9]+FLAX+', 1, level) is not null 
		);
		return v_atributos;
	end fnc_gn_atributos_orgen_sql;
    
    procedure prc_gn_region(p_id_rgion    in     gi_d_formularios_region.id_frmlrio_rgion%type) 
    as
        v_rt_gi_d_regiones          v_gi_d_formularios_region%rowtype;
		v_rt_gi_d_regiones_tipo     gi_d_regiones_tipo%rowtype;
		v_rt_gi_d_atributo_valor    gi_d_frmlrios_rgn_atrbt_vlr%rowtype;
		v_columna                   number;
		v_data                      clob;
		v_html                      clob;
		v_xml                       clob;
    begin
		/*Consultamos la region*/
		begin
			select *
			into v_rt_gi_d_regiones
			from v_gi_d_formularios_region
			where id_frmlrio_rgion = p_id_rgion;
		exception
			when others then
				raise_application_error(-20001,'Problemas al consultar region, '||sqlerrm);
		end;

		--Validamos el tipo de Region
		if(v_rt_gi_d_regiones.cdgo_rgion_tpo = 'CES')then
			v_html :=
			'<div class="container" id="RGN'||p_id_rgion||'">'||
				/*Cabecera Cuadricula*/
				'<div class="row">'||
					/*Titulo de la Cuadricula*/
					'<div class="col col-12">
						<div class="table-title">
							<h3>'||v_rt_gi_d_regiones.dscrpcion||'</h3>
						</div>
					</div>
				</div>'||
				/*Atributos*/
				'<div class="row">';
				for c_atributos in(select *
								   from v_gi_d_frmlrios_rgion_atrbto 
								   where id_frmlrio_rgion = p_id_rgion and actvo = 'S'
								   order by orden asc)loop
					v_data := 'data-tipoValor= "'||c_atributos.tpo_orgn||'" data-valor="'||c_atributos.orgen||'" data-fila="1" data-attrMask="'||c_atributos.mscra||'" '||
							   case when c_atributos.indcdor_oblgtrio is not null then 'data-attrRequerido="' ||c_atributos.indcdor_oblgtrio             ||'" ' end;

					v_xml :=    '<cdgo_atrbto_tpo value='''||c_atributos.cdgo_atrbto_tpo||'''/>'||
								'<idx value = '''||1||''' />'||
								'<value value = '''||c_atributos.vlor_dfcto||''' />'||
								'<attributes value = '''||v_data||case when c_atributos.indcdor_edtble = 'N' then ' disabled' end ||''' />'||
								'<item_id value = '''||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||1||''' />'||
								'<item_label value = '''||c_atributos.nmbre_dsplay||''' />';

					v_html :=   v_html ||
								'<div class="col col-'||nvl(c_atributos.amplcion_clmna, 12)||'">'||
								'<label for="'||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||1||'">'||c_atributos.nmbre_dsplay|| case when c_atributos.indcdor_oblgtrio = 'S' then '<label style="color:red">(*)</label>'end||'</label>'||
								fnc_gn_item(p_xml => v_xml)||
								'</div>';
				end loop;
				v_html := v_html ||
				'</div>
			</div>';
		elsif(v_rt_gi_d_regiones.cdgo_rgion_tpo = 'CIN')then
		   --Cuadricula Interactiva
		   v_html :=
		   '<div class="container" id="RGN'||p_id_rgion||'">'||
				/*Cabecera Cuadricula*/
				'<div class="row">'||
					/*Titulo de la Cuadricula*/
					'<div class="col col-6">
						<div class="table-title">
							<h3>'||v_rt_gi_d_regiones.dscrpcion||'</h3>
						</div>
					</div>'||
					/*Opciones de Cuadricula*/
					case when v_rt_gi_d_regiones.indcdor_edtble = 'S' then
					'<div class="col col-6">
						<button type="button" class="t-Button t-Button--icon t-Button--hot t-Button--iconLeft pull-right" onclick="addRow('||p_id_rgion||');">
							<span aria-hidden="true" class="t-Icon t-Icon--left fa fa-plus add-row"></span>Adicionar
						</button>
					</div>'
					end||
				'</div>
				<div class="row">
					<div class="col col-12">
						<table class="table-fill">
							<thead>
								<tr>';
		   /*Adicionamos las columnas de la tabla*/
		   for c_atributos in(select a.* 
							  from gi_d_frmlrios_rgion_atrbto a
							  where a.id_frmlrio_rgion = p_id_rgion and a.actvo = 'S'
							  order by a.orden asc)loop
				v_html := v_html||'<th scope="col" class="text-'||c_atributos.alncion_cbcra||'">'||c_atributos.nmbre_dsplay||'</th>';
		   end loop;
		   v_html := v_html ||case when v_rt_gi_d_regiones.indcdor_edtble = 'S' then '<th scope="col" class="text-C">Opciones</th>' end||
								'</tr>
							<thead>
							<tbody class="table-hover">';
		   /*Por Cada Fila Registramos Valores*/
		   for c_fila in(select a.fla
						 from gi_d_frmlrios_rgn_atrbt_vlr a
						 inner join gi_d_frmlrios_rgion_atrbto b on a.id_frmlrio_rgion_atrbto = b.id_frmlrio_rgion_atrbto
						 where b.id_frmlrio_rgion = p_id_rgion and b.actvo = 'S'
						 group by a.fla
						 order by a.fla)loop
			v_html := v_html ||'<tr>';
			for c_atributos in(select *
							   from v_gi_d_frmlrios_rgion_atrbto 
							   where id_frmlrio_rgion = p_id_rgion and actvo = 'S'
							   order by orden asc)loop
				/*Consultamos el Valor Asociado al Atributo*/
				begin
					select *
					into v_rt_gi_d_atributo_valor
					from gi_d_frmlrios_rgn_atrbt_vlr
					where id_frmlrio_rgion_atrbto = c_atributos.id_frmlrio_rgion_atrbto and
						  fla             = c_fila.fla;
				exception
					when no_data_found then
						v_rt_gi_d_atributo_valor := null;
				end;
				/*Generamos los Data*/
				v_data := case when c_atributos.mscra            is not null then 'data-attrMask="'      ||c_atributos.mscra                         ||'" 'end||
						  case when c_atributos.indcdor_oblgtrio is not null then 'data-attrRequerido="' ||c_atributos.indcdor_oblgtrio             ||'" ' end||
						  case 
							when v_rt_gi_d_atributo_valor.tpo_orgn is not null then 
								'data-tipoValor="'||v_rt_gi_d_atributo_valor.tpo_orgn||'" '
							when c_atributos.tpo_orgn is not null then
								'data-tipoValor="'||c_atributos.tpo_orgn||'" '
						  end||
						  case 
							when v_rt_gi_d_atributo_valor.orgen is not null then 
								'data-valor="'||
								case when v_rt_gi_d_atributo_valor.tpo_orgn in ('S','F') then 
									fnc_gn_atributos_orgen_sql(p_orgen => v_rt_gi_d_atributo_valor.orgen)
								else
									v_rt_gi_d_atributo_valor.orgen ||'" '
								end
							when c_atributos.orgen is not null then
								'data-valor="'||case when c_atributos.tpo_orgn in ('S','F') then 
									fnc_gn_atributos_orgen_sql(p_orgen => c_atributos.orgen)
								else
									c_atributos.orgen ||'" '
								end
						  end||
						  case when v_rt_gi_d_atributo_valor.indcdor_edtble = 'N' or c_atributos.indcdor_edtble = 'N' then 'disabled ' end||
						  case when c_fila.fla                                is not null then 'data-fila="'          ||c_fila.fla                                ||'" 'end;

				--Generamos el XML para generar el Item
				v_xml :=    '<cdgo_atrbto_tpo value='''||c_atributos.cdgo_atrbto_tpo||'''/>'||
							'<idx value = '''||1||''' />'||
							'<value value = '''||v_rt_gi_d_atributo_valor.vlor||''' />'||
							'<attributes value = '''||v_data||''' />'||
							'<item_id value = '''||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||c_fila.fla||''' />'||
							'<item_label value = '''||c_atributos.nmbre_dsplay||''' />';

				v_html := v_html ||'<td class="text-'||c_atributos.alncion_vlor||'">'||fnc_gn_item(p_xml => v_xml)||'</td>';

			end loop;    
		   end loop;
		   v_html := v_html ||                     
							'</tbody>
						</table>
					</div>
				</div>
			</div>';
		end if;
		dbms_output.put_line(v_html);
		/*Adicionamos las subregiones*/
		for c_subregiones in (select id_frmlrio_rgion 
							  from v_gi_d_formularios_region
							  where id_frmlrio_rgion_pdre = p_id_rgion
							  order by orden asc)loop
			prc_gn_region(p_id_rgion => c_subregiones.id_frmlrio_rgion);
		end loop;
	  end prc_gn_region;

    function fnc_gn_item(p_xml in clob)
    return clob 
    as
		v_cdgo_atrbto_tpo   varchar2(3)     := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'cdgo_atrbto_tpo');
		v_idx               number          := nvl(pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'idx'),1);
		v_value             varchar2(1000)  := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'value');
		v_attributes        varchar2(3000)  := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'attributes');
		v_item_id           varchar2(200)   := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'item_id');
		v_item_label        varchar2(500)   := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'item_label');
		v_orgen             varchar2(32000) := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'orgen');
    begin
		return case v_cdgo_atrbto_tpo
			when 'NUM' then
				apex_item.text(p_idx         => v_idx,
							   p_value       => v_value,
							   p_size        => null,
							   p_maxlength   => null,
							   p_attributes  => v_attributes||' class="input-formulario"',
							   p_item_id     => v_item_id,
							   p_item_label  => v_item_label)
			when 'TXT' then
				apex_item.text(p_idx         => v_idx,
							   p_value       => v_value,
							   p_size        => null,
							   p_maxlength   => null,
							   p_attributes  => v_attributes||' class="input-formulario"',
							   p_item_id     => v_item_id,
							   p_item_label  => v_item_label)
			when 'DSP' then
				v_value
			when 'SLQ' then
				apex_item.select_list_from_query_xl(p_idx           => v_idx,
												 p_value         => null,
												 p_query         => v_orgen,
												 p_attributes    => v_attributes||' class="input-formulario"',
												 p_show_null     => 'YES',
												 p_null_value    => null,
												 p_null_text     => 'Seleccione',
												 p_item_id       => v_item_id,
												 p_item_label    => v_item_label,
												 p_show_extra    => null)
		end;
	  end fnc_gn_item;
end pkg_gi_declaraciones_report;

/
