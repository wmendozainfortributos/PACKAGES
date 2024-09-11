--------------------------------------------------------
--  DDL for Package Body PKG_PLUGINS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PLUGINS" as

  procedure render_hour ( p_item   in            apex_plugin.t_item,
                          p_plugin in            apex_plugin.t_plugin,
                          p_param  in            apex_plugin.t_item_render_param,
                          p_result in out nocopy apex_plugin.t_item_render_result )
  is
      v_html varchar2(4000);
      v_page_item_name varchar2(100);
      -- v_escaped_value long := sys.htf.escape_sc(p_param.value);
      v_escaped_value varchar2(1000) := apex_escape.html(p_param.value);
  begin
      
      if wwv_flow.g_debug then
        apex_plugin_util.debug_page_item( p_plugin =>  p_plugin,
                                          p_page_item => p_item
                                        );
      end if;
      
      -- capturar nombre del item
      v_page_item_name := apex_plugin.get_input_name_for_page_item( p_is_multi_value => false );
      
      -- Cambiar Mascara del item
      apex_app_builder_api.edit_page_item (  p_page_id             => apex_application.g_flow_step_id,
                                             p_item_name           => p_item.name,
                                             p_format_mask         => 'HH12:MI PM'
                                          );
      
      -- cargar archivo JS
      apex_javascript.add_library( p_name => 'mdtimepicker',
                                   p_directory => p_plugin.file_prefix
                                 );
                                 
      -- Ejecutar JS al cargar la pagina
      v_html := '$("#@ID@").mdtimepicker();';
      v_html := replace(v_html, '@ID@', p_item.name);
      
      apex_javascript.add_onload_code( p_code =>  v_html );
      
      -- Cargar archivo Css
      apex_css.add_file( p_name => 'mdtimepicker',
                         p_directory => p_plugin.file_prefix
                       );
      
      -- imprimir un elemento input
      v_html := '<input type="text" id="%ID%" name="%NAME%" class="text_field apex-item-text" size="%SIZE%" value="%VALUE%" >';
      v_html := replace(v_html, '%ID%', p_item.name);
      v_html := replace(v_html, '%NAME%', v_page_item_name);
      -- v_html := replace(v_html, '%VALUE%', to_char(to_timestamp(p_param.value), 'HH12:MI PM'));
      v_html := replace(v_html, '%VALUE%', v_escaped_value);
      v_html := replace(v_html, '%SIZE%', p_item.element_width);
      
      sys.htp.p(v_html);
  end;


function fnc_constructor_sql_render( p_region              in apex_plugin.t_region,
                                     p_plugin              in apex_plugin.t_plugin,
                                     p_is_printer_friendly in boolean )
return apex_plugin.t_region_render_result
is
    v_html varchar2(4000);
    v_id_proceso varchar2(5) := p_region.attribute_01;
    v_id_consulta varchar2(5) := p_region.attribute_02;
    v_checks varchar2(4000) := ' ';
    v_condicion varchar2(4000); 
    v_valor_condicion1 varchar2(150); 
    v_valor_condicion2 varchar2(150); 
    v_descripcion varchar2(150);
    v_proceso varchar2(150);
    v_entidades varchar2(150);
    v_nmbre_cnslta varchar2(50);
    
begin
    if v_id_consulta is not null then 
        select listagg(id_entdad,',')within group ( order by cdgo_prcso_sql, nmbre_cnslta) ,
               cdgo_prcso_sql,
               nmbre_cnslta
          into v_entidades,
               v_id_proceso,
               v_nmbre_cnslta
          from (
        select distinct e.id_entdad, ps.cdgo_prcso_sql, p.nmbre_cnslta
          from ge_p_consulta_maestro p  
          join ge_p_consulta_detalle d
            on p.id_cnslta_mstro = d.id_cnslta_mstro
          join ge_p_entidad_columnas c
            on d.id_entdad_clmna = c.id_entdad_clmna
          join ge_p_entidad e
            on e.id_entdad = c.id_entdad
          join ge_p_procesos_sql ps
            on ps.id_prcso_sql = e.id_prcso_sql
         where d.id_cnslta_mstro = v_id_consulta ) f group by cdgo_prcso_sql, nmbre_cnslta;
     end if;
     
    select apex_item.select_list( p_idx         => 1,
                                  p_list_values => (listagg( alias_entdad  ||';'|| id_entdad , ',' )  within group ( order by id_entdad) ),
                                  p_attributes  => 'style="width:100%;" multiple="multiple" ' ,
                                  p_item_id     => 'pEntidad')
                                  
      into v_checks
      from ge_p_procesos_sql p
      join ge_p_entidad e
        on p.id_prcso_sql = e.id_prcso_sql
     where p.cdgo_prcso_sql = v_id_proceso;
     
     select apex_item.select_list( p_idx         => 2,
                                  p_value       => '1',
                                  p_list_values => (listagg(dscrpcion || '  (' || oprdor ||');'|| id_oprdor_tpo, ',') within group ( order by id_oprdor_tpo)),
                                  p_attributes  => 'style="width:70%;" class="text_field apex-item-text"' ,
                                  p_item_id     => 'pCondicion') 
       into v_condicion                            
       from df_s_operadores_tipo 
      where oprdor not in ('IS NULL','IS NOT NULL');
     
    select apex_item.text(p_idx=> 3, p_item_id => 'pValCondicion1', p_maxlength => 100, p_attributes => 'class="valCondi"'),                          
           apex_item.text(p_idx=> 4, p_item_id => 'pValCondicion2', p_maxlength => 100, p_attributes => 'class="valCondi"'),
           apex_item.text(p_idx=> 5, p_item_id => 'descripcion', p_maxlength => 50, p_value => v_nmbre_cnslta ),
           apex_item.hidden(p_idx=> 6, p_item_id => 'id_proceso', p_value => v_id_proceso)
      into v_valor_condicion1,
           v_valor_condicion2,
           v_descripcion,
           v_proceso
      from dual;
          
    v_html := '<!--Dialog Conditions -->
              <div id="pDialogCondicion" title="Condiciones">
                <div class="container">
                    <div class="row">
                        <div class="t-Form-labelContainer col col-2">
                            <label class="t-Form-label">
                                <b>Columna:</b>
                            </label>
                        </div>
                        <div class="t-Form-inputContainer col col-10">
                            <label id="pColumnVal"></label>
                        </div>
                    </div>
                    <div class="row">
                        <div class="t-Form-labelContainer col col-2">
                            <label class="t-Form-label">
                                <b>Operador :</b>
                            </label>
                        </div>
                        <div class="t-Form-inputContainer col col-4"> ' ||
                        v_condicion ||  
                        '</div>
                    </div>
                    <div class="row">
                        <div class="t-Form-labelContainer col col-2">
                            <label class="t-Form-label">
                                <b>Valor 1</b>
                            </label>
                        </div>
                        <div class="t-Form-inputContainer col col-4"> ' ||
                        v_valor_condicion1 ||  
                        '</div>
                    </div>
                    <div class="row">
                        <div class="pValor2 t-Form-labelContainer col col-2">
                            <label class="t-Form-label">
                                <b>Valor 2</b>
                            </label>
                        </div>
                        <div class="pValor2 t-Form-inputContainer col col-4"> ' ||
                        v_valor_condicion2 ||
                        '</div>                
                    </div>
                </div>
            </div>
              <div class="container">                
                 <div class="row">
                    <div class="col col-8">
                        <div class="t-Form-labelContainer col col-2">
                            <label class="t-Form-label">
                                <b>Nombre Consulta: </b>
                            </label>
                        </div>
                        <div class="t-Form-inputContainer col col-10">' 
                        || v_descripcion || '
                        </div>
                    </div>
                 </div>    
                 <div class="row">
                    <div class="col col-8">
                        <div class="t-Form-labelContainer col col-2">
                            <label for="PCSQL_ENTIDAD" class="t-Form-label">
                                <b>Entidades:</b>
                            </label>
                        </div>
                        <div class="t-Form-inputContainer col col-10">';                    
         
    sys.htp.p(v_html);
    sys.htp.p(v_proceso);
    sys.htp.p(v_checks);
    sys.htp.p('</div></div>
                  <div class="col col-4">
                    <button id="btn_consultar" class="t-Button t-Button--icon t-Button--iconLeft lto162332410710475136_0 t-Button--hot" type="button">
                        <span class="t-Button-label">Consultar</span>
                    </button>
                    <button id="btn_save" class="t-Button t-Button--icon t-Button--iconLeft lto162332410710475136_0 t-Button--hot" type="button">
                        <span class="t-Button-label">Guardar</span>
                    </button>
                  </div>
              </div>');
    sys.htp.p('<div class="row">
                <div class="col col-1">&nbsp;</div>
                <div class="col col-8" id="jqGrid_container">
                    <table id="gridColumns"></table>            
                </div>
              </div></div>');
    sys.htp.p('<div class="row">
                <div class="col col-1">&nbsp;</div>
                <div class="col col-8">
                    <table id="gridColumns"></table>            
                </div>
              </div></div>');
              
    sys.htp.p(' <script>
            var v_entidades = "'|| v_entidades || '";
            var v_consulta = "'|| v_id_consulta || '";
			function loadGrid(pRegionId, pOptions){
				function _draw() {
					$("#gridColumns").jqGrid({
						datatype: "local",
						width: "1200",
                        height: "auto", 
                        rowNum: "9999",
						colModel: [
							{ name: "alias_clmna", label:"Columna", },
							{ name: "alias_entdad", label: "Entidad", width: 100},
                            { name: "checked", label: "Select", edittype:"checkbox", formatter:"checkbox", width: 20},
							{ name: "condicionar", label: "Condicionar", formatter: btnFormatter, width: 30 },
                            { name: "condicion", label: "Condiciones", formatter: cndFormatter, width: 100 },
                            { name: "id_entdad_clmnas", hidden: true, key:true},
                            { name: "id_entdad", hidden: true},
                            { name: "tpo_clmna", hidden:true},                            
                            { name: "operador", hidden:true},
                            { name: "valor1", hidden:true},
                            { name: "valor2", hidden:true}
						],	
						grouping: true,
						groupingView: {
							groupField: ["alias_entdad"],
							groupColumnShow: [false],
							groupText: ["<b>{0}</b>"],
							groupOrder: ["asc"],
							groupSummary: [false],
							groupCollapse: true
							
						}						
					});
				}				
                function cndFormatter(c,o,r){
                    var html = "";
                    if (r.operador) {
                        var valor = $(`#pCondicion option[value=${r.operador}]`).text();
                        valor = valor.split("(")[1];
                        valor = valor.replace(")","");
                        switch(valor) {
                            case "BETWEEN":
                                html = `<p> ${r.alias_clmna} ${valor} ${r.valor1} AND ${r.valor2} </p>`;
                                break;
                            case "IN" || "NOT IN" :
                                html = `<p> ${r.alias_clmna} ${valor}( ${r.valor1} ) </p>`;
                                break;
                            default:
                                html = `<p> ${r.alias_clmna} ${valor} ${r.valor1} </p>`;
                        }
                        
                    }
                    return html;
                }
				function btnFormatter(c,o,r){                    
                    var styl = r.operador ? `style="background-color:#0572ce; cursor:pointer;text-align:center; width:100%;"` : `style="cursor:pointer;text-align:center; width:100%;"` ; 
					var html = `<div class="col col-4" onclick="openDialog(${o.rowId})"  ${styl} ><span  style="width:50%; margin: 0 auto;" class="fa fa-plus"></span></div>`;						
					return html;
				}	
                
				function _reloadGrid(pData){
                    var dataGrid = jQuery("#gridColumns").jqGrid ("getRowData");
                    var data = pData.data;
                    
                    if(dataGrid.length !== 0){
                        data = pData.data.map(function(m){
                          var rowGrid = jQuery("#gridColumns").jqGrid ("getRowData", m.id_entdad_clmnas);
                          return (rowGrid.id_entdad_clmnas ? $.extend(m,rowGrid) : m );
                        });
                    }
                    $("#gridColumns").clearGridData();
                    $("#gridColumns").setGridParam({data:data}).trigger("reloadGrid");
				}
				
				function _debug(i) {
					console.log(i);
				}
				function _save(){
                    var data = $("#gridColumns").jqGrid ("getRowData");
                    var send = data.filter(function(f){
                        return (f.checked === "Yes" || f.operador !== "")
                    })
                    send = send.map(function(m){
                        return JSON.stringify({id_entdad:m.id_entdad,id_entdad_clmnas: m.id_entdad_clmnas,operador: m.operador,valor1: m.valor1, valor2: m.valor2, checked: m.checked });
                    });
                    
                    setTimeout(function(){
                        apex.message.clearErrors();
                    }, 2000)
                    $(".u-visible").remove();
                    var errors = [];                    
                    
                    if (send.length === 0 ){
                       errors.push({ type: apex.message.TYPE.ERROR,
                                      location: ["page"],
                                      pageItem: "pValCondicion2",
                                      message: "No se a seleccionado ninguna columna",
                                      unsafe: false}); 
                    }
                    if($("#descripcion").val() === ""){
                        errors.push({ type: apex.message.TYPE.ERROR,
                                      location: ["page","inline"],
                                      pageItem: "descripcion",
                                      message: "Debe digitar un nombre de consulta",
                                      unsafe: false}); 
                    }
                    if (errors.length > 0){
                        apex.message.showErrors(errors);
                        return;
                    }
                   console.log(2);
                    apex.server.plugin(
						pOptions.ajaxIdentifier,
						{
							f01: send,
                            f02: v_consulta === "" ? "SAVE" : "EDIT" ,
                            f03: $("#id_proceso").val(),
                            f04: $("#descripcion").val(),
                            f05: v_consulta,
                            
						},
						{
							dataType: "json",
							accept: "application/json",
							success: function(resp) {
                                if( resp.SUCCESS){
                                   apex.message.showPageSuccess(resp.MSG);
                                }else{
                                apex.message.showErrors({ type: apex.message.TYPE.ERROR,
                                      location: ["page"],
                                      pageItem: "descripcion",
                                      message: resp.MSG,
                                      unsafe: false});
                                }
                            },
							error:  _debug
						}
					); 
                }
				function _refresh() {
					apex.server.plugin(
						pOptions.ajaxIdentifier,
						{
							f01: $("#pEntidad").val(),
                            f02: "LIST",
                            f03: v_consulta
						},
						{
							dataType: "json",
							accept: "application/json",
							success: _reloadGrid,
							error:  _debug
						}
					);
				}
				$(document).ready(function(){                                        
                    $("#pDialogCondicion").dialog({
						autoOpen: false,
						height: 300,
						width: 800,
						modal: true,
						buttons: {
							"Agregar": function () {
                                setTimeout(function(){
                                    apex.message.clearErrors();
                                }, 2000)
                                $(".u-visible").remove();
                                var errors = [];
                                 if(!$("#pCondicion").val()){
                                    errors.push({ type: apex.message.TYPE.ERROR,
                                            location: ["page","inline"],
                                            pageItem: "pCondicion",
                                            message: "Condicion es requerida",
                                            unsafe: false});
                                 }
                                 if ($("#pValCondicion1").val()=== "" ){
                                    errors.push({ type: apex.message.TYPE.ERROR,
                                            location: ["page","inline"],
                                            pageItem: "pValCondicion1",
                                            message: "Valor 1 es requerido",
                                            unsafe: false});
                                 }
                                 if ($("#pValCondicion2").val()=== "" && $("#pCondicion").val() === 11 ){
                                    errors.push({ type: apex.message.TYPE.ERROR,
                                                  location: ["page","inline"],
                                                  pageItem: "pValCondicion2",
                                                  message: "Valor 2 es requerido",
                                                  unsafe: false});
                                 }
                                if (errors.length > 0){
                                    apex.message.showErrors(errors);
                                    return;
                                }
                                var data = $("#gridColumns").jqGrid ("getRowData", idselect);
                                var row = $.extend(data,{operador: $("#pCondicion").val(), valor1: $("#pValCondicion1").val(), valor2: $("#pValCondicion2").val()});
                                $("#gridColumns").setRowData(idselect, row);
                                apex.message.showPageSuccess("Datos agregados exitosamente!!");
                                setTimeout(function(){
                                    apex.message.hidePageSuccess();
                                },2000)
							},
							Cancel: function() {
								$("#pDialogCondicion").dialog( "close" );
							}
						},
						close: function() {
							console.log("Salio");
						}
                    });                    
                    
                    $("#pEntidad option[value='''']").remove();
					_draw();
                    
                    if(v_entidades !== ""){
                        $("#pEntidad").val(v_entidades.split(","))
                        _refresh();
                    }
                    $("#pEntidad").select2();
				})							
				$("#btn_consultar").click(_refresh);
                $("#btn_save").click(_save);
                $("#pCondicion").change(function(){
                    if( $(this).val() === 11){
                        $(".pValor2").show();
                    }
                })
                $(window).on("resize", function () {
                    _resizeGrid();
                });
              
			}
            
            var idselect = 0;
            function openDialog(rowId) {
                idselect = rowId;
                var data = jQuery("#gridColumns").jqGrid ("getRowData", rowId);
                             
                switch(data.tpo_clmna) {
                    case "VARCHAR2":
                        $(".valCondi").attr({type:"text"});
                        break;
                    case "NUMBER":
                        $(".valCondi").attr({type:"number"});
                        break;
                    case "TIMESTAMP(6)":
                        $(".valCondi").attr({type:"date"});
                        break;
                    default:
                        console.log("No se encontro tipo");
                }
                
                $("#pCondicion").val(data.operador);
                $("#pValCondicion1").val(data.valor1);
                $("#pValCondicion2").val(data.valor2);
                data.operador === "11" ? $(".pValor2").show() :  $(".pValor2").hide();  
                $("#pColumnVal").html(data["alias_clmna"]);
                $("#pDialogCondicion").dialog("open");                
            }
           
            function _resizeGrid(){
               var width = jQuery("#jqGrid_container").width();                
                width -= 10;
                jQuery("#gridColumns").setGridWidth(width);
            }
		</script>');
               
   apex_javascript.add_onload_code (
                                      p_code => 'loadGrid(' ||
                                      apex_javascript.add_value(p_region.static_id) ||
                                        '{'||
                                            apex_javascript.add_attribute(
                                                'ajaxIdentifier', 
                                                apex_plugin.get_ajax_identifier, 
                                                false, 
                                                false
                                            )||
                                        '}'||
                                      ');'
                                  );

    
return null;

end fnc_constructor_sql_render;

function fnc_constructor_sql_ajax( p_region in apex_plugin.t_region,
                                   p_plugin in apex_plugin.t_plugin
                                 )
  return apex_plugin.t_region_ajax_result
is 

v_accion varchar2(10);
v_id_prcso_sql number;
v_id_cnslta_mstro number;
v_id_cnslta_dtlle number;

begin
    apex_json.initialize_output ( p_http_cache => false );
    
    -- begin output as json
    owa_util.mime_header('application/json', false);
    htp.p('cache-control: no-cache');
    htp.p('pragma: no-cache');
    owa_util.http_header_close;
    apex_json.open_object();
    v_accion := apex_application.g_f02(1);
    apex_json.write('ACCION', v_accion); 
    
    if v_accion = 'LIST' then
    
        apex_json.open_array('data');    
        delete from gti_aux;
        for i in 1..apex_application.g_f01.count loop 
            for ge_p_entidades_columnas in (
                                           select e.alias_entdad,
                                                  ec.alias_clmna,
                                                  e.id_entdad,
                                                  ec.id_entdad_clmna,
                                                  ec.tpo_clmna,
                                                  case when d.indcdor_select = 'S' then 'Yes' else 'No' end as checked,
                                                  d.id_oprdor_tpo,
                                                  d.vlor1,
                                                  d.vlor2
                                             from ge_p_entidad_columnas ec
                                             join ge_p_entidad e
                                               on ec.id_entdad = e.id_entdad
                                        left join ge_p_consulta_detalle d
                                               on ec.id_entdad_clmna = d.id_entdad_clmna
                                               and d.id_cnslta_mstro = apex_application.g_f03(1) 
                                        left join ge_p_consulta_maestro m
                                               on m.id_cnslta_mstro = d.id_cnslta_mstro 
                                              and m.id_cnslta_mstro = apex_application.g_f03(1)
                                          where e.id_entdad = apex_application.g_f01(i)
                                     )  loop
                                     
            apex_json.open_object(); 
            apex_json.write('alias_entdad', ge_p_entidades_columnas.alias_entdad); 
            apex_json.write('alias_clmna', ge_p_entidades_columnas.alias_clmna); 
            apex_json.write('id_entdad', ge_p_entidades_columnas.id_entdad); 
            apex_json.write('id_entdad_clmnas', ge_p_entidades_columnas.id_entdad_clmna); 
            apex_json.write('tpo_clmna', ge_p_entidades_columnas.tpo_clmna);
            apex_json.write('operador', ge_p_entidades_columnas.id_oprdor_tpo);
            apex_json.write('valor1', ge_p_entidades_columnas.vlor1);
            apex_json.write('valor2', ge_p_entidades_columnas.vlor2);
            apex_json.write('checked', ge_p_entidades_columnas.checked);
            apex_json.close_object();        
            end loop;
        end loop;
    elsif v_accion = 'SAVE' then
        
        begin
        
            select id_prcso_sql
              into v_id_prcso_sql
              from ge_p_procesos_sql
             where cdgo_prcso_sql = apex_application.g_f03(1);
            
            insert into ge_p_consulta_maestro (id_prcso_sql, nmbre_cnslta) 
                                        values(v_id_prcso_sql,apex_application.g_f04(1)) 
            returning id_cnslta_mstro 
                 into v_id_cnslta_mstro;
                 
            
            for i in 1..apex_application.g_f01.count loop 
                -- id_entdad:f.id_entdad,id_entdad_clmnas: f.id_entdad_clmnas,operador: f.operador,valor1: f.valor1, valor2: f.valor2, checked
                for r_entidad_columna in (select id_entdad,
                                                 id_entdad_clmnas,
                                                 operador,
                                                 valor1,
                                                 valor2,
                                                 case when checked = 'Yes' then 'S' else 'N' end checked
                                            from json_table(apex_application.g_f01(i),'$' columns(id_entdad number path '$.id_entdad',
                                                                                                  id_entdad_clmnas number path '$.id_entdad_clmnas',
                                                                                                  operador number path '$.operador' ,
                                                                                                  valor1 varchar2(50) path '$.valor1',
                                                                                                  valor2 varchar2(50) path '$.valor2',
                                                                                                  checked varchar2(3) path '$.checked' ) 
                                                                   ) t 
                                         )  loop
                
                 insert into ge_p_consulta_detalle(id_cnslta_mstro           , id_entdad_clmna                   , indcdor_select           , 
                                                   id_oprdor_tpo             , vlor1                             , vlor2                    ,
                                                   ordn_clmna ) 
                                            values(v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked,
                                                   r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor1 ,
                                                   i );
                end loop;                                                          
            end loop;
            
            apex_json.write('SUCCESS',true);
            apex_json.write('MSG','Se Guardaron los Cambios');
            
        exception when others then
                
                apex_json.write('ERROR',true);
                apex_json.write('MSG',sqlerrm);                
        end;
    elsif v_accion = 'EDIT' then
        
        begin
        
            select id_cnslta_mstro
              into v_id_cnslta_mstro
              from ge_p_consulta_maestro
             where id_cnslta_mstro = apex_application.g_f05(1);
                 
            
            for i in 1..apex_application.g_f01.count loop 
                -- id_entdad:f.id_entdad,id_entdad_clmnas: f.id_entdad_clmnas,operador: f.operador,valor1: f.valor1, valor2: f.valor2, checked
                for r_entidad_columna in (select id_entdad,
                                                 id_entdad_clmnas,
                                                 operador,
                                                 valor1,
                                                 valor2,
                                                 case when checked = 'Yes' then 'S' else 'N' end checked
                                            from json_table(apex_application.g_f01(i),'$' columns(id_entdad number path '$.id_entdad',
                                                                                                  id_entdad_clmnas number path '$.id_entdad_clmnas',
                                                                                                  operador number path '$.operador' ,
                                                                                                  valor1 varchar2(50) path '$.valor1',
                                                                                                  valor2 varchar2(50) path '$.valor2',
                                                                                                  checked varchar2(3) path '$.checked' ) 
                                                                   ) t 
                                         )  loop
                
                    begin
                    
                       select id_cnslta_dtlle
                         into v_id_cnslta_dtlle
                         from ge_p_consulta_detalle d
                        where d.id_cnslta_mstro = v_id_cnslta_mstro
                          and d.id_entdad_clmna = r_entidad_columna.id_entdad_clmnas;
                       
                       update ge_p_consulta_detalle 
                          set indcdor_select = r_entidad_columna.checked,
                              id_oprdor_tpo  = r_entidad_columna.operador,
                              vlor1          = r_entidad_columna.valor1,
                              vlor2          = r_entidad_columna.valor2,
                              ordn_clmna     = i
                      where id_cnslta_dtlle  = v_id_cnslta_dtlle ;
                        
                    exception when no_data_found then
                         insert into ge_p_consulta_detalle(id_cnslta_mstro           , id_entdad_clmna                   , indcdor_select           , 
                                                           id_oprdor_tpo             , vlor1                             , vlor2                    ,
                                                           ordn_clmna ) 
                                                    values(v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked,
                                                           r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor1 ,
                                                           i );                        
                    end;
                end loop;                                                          
            end loop;
            
            apex_json.write('SUCCESS',true);
            apex_json.write('MSG','Se Guardaron los Cambios');
            
        exception when others then

                apex_json.write('ERROR',true);
                apex_json.write('MSG',sqlerrm);
        end;    
    end if;
    
    apex_json.close_all();
    return null;
    
exception when others then
    apex_json.open_object();
    apex_json.write('ERROR',true);
    apex_json.write('MSG',apex_escape.html(sqlerrm));
    apex_json.close_object(); 
    return null;
end fnc_constructor_sql_ajax;

end pkg_plugins;

/
