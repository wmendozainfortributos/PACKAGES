--------------------------------------------------------
--  DDL for Package XLSX_PARSER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."XLSX_PARSER" is

    c_date_format constant varchar2(255) := 'YYYY-MM-DD';

    -- we currently support 50 columns - but this can easily be increased. Just increase the columns in the
    -- record definition and add corresponing lines into the package body
    type xlsx_row_t is record( 
        line# number,
        col01 varchar2(4000), col02 varchar2(4000), col03 varchar2(4000), col04 varchar2(4000), col05 varchar2(4000),
        col06 varchar2(4000), col07 varchar2(4000), col08 varchar2(4000), col09 varchar2(4000), col10 varchar2(4000),
        col11 varchar2(4000), col12 varchar2(4000), col13 varchar2(4000), col14 varchar2(4000), col15 varchar2(4000),
        col16 varchar2(4000), col17 varchar2(4000), col18 varchar2(4000), col19 varchar2(4000), col20 varchar2(4000),
        col21 varchar2(4000), col22 varchar2(4000), col23 varchar2(4000), col24 varchar2(4000), col25 varchar2(4000),
        col26 varchar2(4000), col27 varchar2(4000), col28 varchar2(4000), col29 varchar2(4000), col30 varchar2(4000));

    type xlsx_tab_t is table of xlsx_row_t;

    --==================================================================================================================
    -- table function parses the XLSX file and returns the first 15 columns.
    -- pass either the XLSX blob directly or reference a name in the APEX_APPLICATION_TEMP_FILES table.
    --
    -- p_xlsx_name      - NAME column of the APEX_APPLICATION_TEMP_FILES table
    -- p_xlsx_content   - XLSX as a BLOB
    -- p_worksheet_name - Worksheet to extract
    -- 
    -- usage:
    --
    -- select * from table( 
    --    xlsx_parser.parse( 
    --        p_xlsx_name      => :P1_XLSX_FILE, 
    --        p_worksheet_name => :P1_WORKSHEET_NAME ) );
    --
    function parse( 
        p_xlsx_name      in varchar2 default null,
        p_xlsx_content   in blob     default null, 
        p_worksheet_name in varchar2 default 'sheet1',
        p_max_rows       in number   default 1000000 ) return xlsx_tab_t pipelined; 

    --==================================================================================================================
    -- table function to list the available worksheets in an XLSX file
    --
    -- p_xlsx_name    - NAME column of the APEX_APPLICATION_TEMP_FILES table
    -- p_xlsx_content - XLSX as a BLOB
    -- 
    -- usage:
    --
    -- select * from table( 
    --    xlsx_parser.get_worksheets( 
    --        p_xlsx_name      => :P1_XLSX_FILE ) );
    --
    function get_worksheets(
        p_xlsx_content   in blob     default null, 
        p_xlsx_name      in varchar2 default null ) return apex_t_varchar2 pipelined;

    --==================================================================================================================
    -- date and datetimes are stored as a number in XLSX; this function converts that number to an ORACLE DATE
    --
    -- p_xlsx_date_number   numeric XLSX date value
    -- 
    -- usage:
    -- select xlsx_parser.get_date( 46172 ) from dual;
    --
    function get_date( p_xlsx_date_number in number ) return date;

end xlsx_parser;

/
