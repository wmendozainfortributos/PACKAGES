--------------------------------------------------------
--  DDL for Package EBA_GI_FLEX_FW
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."EBA_GI_FLEX_FW" as

	procedure flex_report_update (
		p_flex_table_name      in     varchar2,
		p_irr_region_static_id in     varchar2,
		p_flex_column_prefix   in     varchar2,
		p_app_id               in     number,
		p_page_id              in     number,
		p_region_type          in     varchar2,
		P_id_tpo_frmlrio 		in	number,
		P_vgncia				in	number,
		P_id_prdo				in	number
	);

	function validate_lov_query ( p_query in varchar2,
		p_display_column out varchar2,
		p_return_column out varchar2,
		p_error out varchar2
	) return boolean;

	procedure populate_page_map_table;

	procedure reset_flex_registry;

	function fetch_v( p_column in varchar2,
					p_input in varchar2,
					P_id_tpo_frmlrio 	number,
					P_vgncia			number,
					P_id_prdo			number) return varchar2;

	function fetch_n( p_column in varchar2,
					p_input in number,
					P_id_tpo_frmlrio 	number,
					P_vgncia			number,
					P_id_prdo			number) return varchar2;
					

    -- Genera los registros de FLEX Por FLEXIBLE_TABLA, FLEXIBLE_COLUMN y FIXED_COLUMN_VALUE
	procedure add_flex_registry(
		p_flexible_table varchar2, 
		p_prefijo_column varchar2, 
		P_id_tpo_frmlrio 	number,
        P_vgncia			number,
        P_id_prdo			number);
end;

/
