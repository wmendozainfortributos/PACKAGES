--------------------------------------------------------
--  DDL for Package Body PKG_MA_EMAIL_TEMPLATE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MA_EMAIL_TEMPLATE" IS

    /**********************************************
    ***********************************************
    ***********************************************
    GLOBAL STUFF
    ***********************************************
    ***********************************************
    **********************************************/

    /* Global Header */
    FUNCTION fnc_print_global_header
		return clob
	IS
    BEGIN
        return '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' ||
                '<html xmlns="http://www.w3.org/1999/xhtml">' ||
                '<head>' ||
                    '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />' ||
                    '<meta name="viewport" content="width=device-width"/>' ||
                '</head>';
    END fnc_print_global_header;

    /* Global CSS */
    FUNCTION fnc_print_global_css
		return clob
	IS
		v_clob clob;
    BEGIN
		v_clob := empty_clob();
        v_clob := '<style type="text/css">a:hover,a:active{color:#2795b6!important}a:visited,h1 a:active,h1 a:visited,h2 a:active,h2 a:visited,h3 a:active,h3 a:visited,h4 a:active,h4 a:visited,h5 a:active,h5 a:visited,h6 a:active,h6 a:visited{color:#2ba6cb!important}table.button:active td,table.button:visited td{background:#2795b6!important}table.button:visited td a{color:#fff!important}table.button:hover td,table.large-button:hover td,table.medium-button:hover td,table.small-button:hover td,table.tiny-button:hover td{background:#2795b6!important}table.button td a:visited,table.button:active td a,table.button:hover td a,table.large-button td a:visited,table.large-button:active td a,table.large-button:hover td a,table.medium-button td a:visited,table.medium-button:active td a,table.medium-button:hover td a,table.small-button td a:visited,table.small-button:active td a,table.small-button:hover td a,table.tiny-button td a:visited,table.tiny-button:active td a,table.tiny-button:hover td a{color:#fff!important}table.secondary:hover td{background:#d0d0d0!important;color:#555}table.secondary td a:visited,table.secondary:active td a,table.secondary:hover td a{color:#555!important}table.success:hover td{background:#457a1a!important}table.alert:hover td{background:#970b0e!important}table.facebook:hover td{background:#2d4473!important}table.twitter:hover td{background:#0087bb!important}table.google-plus:hover td{background:#C00!important}@media only screen and (max-width:600px){table[class=body] img{width:auto!important;height:auto!important}table[class=body] center{min-width:0!important}table[class=body] .container{width:95%!important}table[class=body] .row{width:100%!important;display:block!important}table[class=body] .wrapper{display:block!important;padding-right:0!important}table[class=body] .column,table[class=body] .columns{table-layout:fixed!important;float:none!important;width:100%!important;padding-right:0!important;padding-left:0!important;display:block!important}table[class=body] .wrapper.first .column,table[class=body] .wrapper.first .columns{display:table!important}table[class=body] table.column td,table[class=body] table.columns td{width:100%!important}table[class=body] .column td.one,table[class=body] .columns td.one{width:8.333333%!important}table[class=body] .column td.two,table[class=body] .columns td.two{width:16.666666%!important}table[class=body] .column td.three,table[class=body] .columns td.three{width:25%!important}table[class=body] ';
		v_clob := v_clob || '.column td.four,table[class=body] .columns td.four{width:33.333333%!important}table[class=body] .column td.five,table[class=body] .columns td.five{width:41.666666%!important}table[class=body] .column td.six,table[class=body] .columns td.six{width:50%!important}table[class=body] .column td.seven,table[class=body] .columns td.seven{width:58.333333%!important}table[class=body] .column td.eight,table[class=body] .columns td.eight{width:66.666666%!important}table[class=body] .column td.nine,table[class=body] .columns td.nine{width:75%!important}table[class=body] .column td.ten,table[class=body] .columns td.ten{width:83.333333%!important}table[class=body] .column td.eleven,table[class=body] .columns td.eleven{width:91.666666%!important}table[class=body] .column td.twelve,table[class=body] .columns td.twelve{width:100%!important}table[class=body] td.off--set-by-eight,table[class=body] td.off--set-by-eleven,table[class=body] td.off--set-by-five,table[class=body] td.off--set-by-four,table[class=body] td.off--set-by-nine,table[class=body] td.off--set-by-one,table[class=body] td.off--set-by-seven,table[class=body] td.off--set-by-six,table[class=body] td.off--set-by-ten,table[class=body] td.off--set-by-three,table[class=body] td.off--set-by-two{padding-left:0!important}table[class=body] table.columns td.expander{width:1px!important}table[class=body] .text-pad-right{padding-left:10px!important}table[class=body] .text-pad-left{padding-right:10px!important}table[class=body] .hide-for-small,table[class=body] .show-for-desktop{display:none!important}table[class=body] .hide-for-desktop,table[class=body] .show-for-small{display:inherit!important}table[class=body] .right-text-pad{padding-left:10px!important}table[class=body] .left-text-pad{padding-right:10px!important}}</style>';
		return v_clob;
    END fnc_print_global_css;

    /* Global Body HTML tag */
    FUNCTION fnc_outer_body(p_content in clob)
		return clob
	IS
    BEGIN
        return '<body style="background:' || g_body_background || '; width: 100% !important; min-width: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; text-align: left; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: 0;">'
            || p_content
            || '</body>';
    END fnc_outer_body;

    /* Global Mandatory Table to wrap the body content */
    FUNCTION fnc_inner_body(p_content in clob)
		return clob
	IS
    BEGIN
        return '<table class="body" style="background:' || g_body_background || '; border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; height: 100%; width: 100%; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: 0;">'
            || '<tr style="vertical-align: top; text-align: left; padding: 0;" align="left">'
            || p_content
            || '</tr>'
            || '</table>';
    END fnc_inner_body;

    /* Email Footer */
    FUNCTION fnc_print_global_end
		return clob
	IS
    BEGIN
        return '</html>';
    END fnc_print_global_end;

    /**********************************************
    ***********************************************
    ***********************************************
    GRID
    ***********************************************
    ***********************************************
    **********************************************/

    /* Constrains the content to a 580px wrapper on large screens (95% on small screens) and centers it within the body. */
    FUNCTION fnc_print_container (p_content in clob)
		return clob
	IS
    BEGIN
        return '<table class="container" style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: inherit; width: 580px; margin: 0 auto; padding: 0;">'
            || '<tr style="vertical-align: top; text-align: left; padding: 0;" align="left">'
            || fnc_print_standard_td(p_content)
            || '</tr>'
            || '</table>';
    END fnc_print_container;

    /* Separates each row of content. */
    FUNCTION fnc_print_row (
							p_content in clob
							, p_classes in varchar2 default null
							, p_display in varchar2 default 'block'
							, p_header_background_color in varchar2 default 'transparent')
		return clob
	IS
    BEGIN
        return '<table class="row ' || p_classes || '" style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; width: 100%; position: relative; background: ' || p_header_background_color || '; display: ' || p_display || '; padding: 0px;" bgcolor="' || p_header_background_color || '">'
            || '<tr style="vertical-align: top; text-align: left; padding: 0;" align="left">'
            || p_content
            || '</tr>'
            || '</table>';
    END fnc_print_row;

    /* Grid Standard TD */
    FUNCTION fnc_print_standard_td (
									p_content in clob
									, p_align in varchar2 default 'left'
									, p_padding in varchar2 default '0 0 10px'
									, p_background_color in varchar2 default 'transparent'
									, p_border in varchar2 default 'none'
									, p_extra_attributes in varchar2 default null)
		return clob
	IS
    BEGIN
        return '<td style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: top; text-align: ' || p_align || '; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: ' || p_padding || ';" align="' || p_align || '" valign="top">'
            || p_content
            || '</td>';
    END fnc_print_standard_td;

    /* Grid Standard TD Centered */
    FUNCTION fnc_print_standard_td_center (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_standard_td(
                p_content => '<center style="width: 100%; min-width: 580px;">'
                            || p_content
                            || '</center>'
                ,p_align => 'center'
            );
    END fnc_print_standard_td_center;

    /*
    Wraps each .columns table, in order to create a gutter between columns
    and force them to expand to full width on small screens.
    */
    FUNCTION fnc_print_column_wrapper (p_content in clob)
		return clob
	IS
    BEGIN
        return '<td class="wrapper" style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: top; text-align: left; position: relative; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: 10px 20px 0px 0px;" align="left" valign="top">'
        || p_content
        || '</td>';
    END fnc_print_column_wrapper;

    /*
    Can be any number between one and twelve (spelled out).
    Used to determine how wide your .columns tables are.
    The number of columns in each row should add up to 12, including offset columns .
    */
    FUNCTION fnc_print_col (
							p_content in clob
							, p_number in varchar2
							, p_width in varchar2)
		return clob
	IS
    BEGIN
        return '<table class="' || p_number || ' columns" style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; width: ' || p_width || '; margin: 0 auto; padding: 0;">'
            || '<tr style="vertical-align: top; text-align: left; padding: 0;" align="left">'
            || p_content
            || fnc_print_expander
            || '</tr>'
            || '</table>';
    END fnc_print_col;

    /* 1 Columns */
    FUNCTION fnc_print_col_1 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'one', '30px');
    END fnc_print_col_1;

    /* 2 Columns */
    FUNCTION fnc_print_col_2 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'two', '80px');
    END fnc_print_col_2;

    /* 3 Columns */
    FUNCTION fnc_print_col_3 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'three', '130px');
    END fnc_print_col_3;

    /* 4 Columns */
    FUNCTION fnc_print_col_4 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'four', '180px');
    END fnc_print_col_4;

    /* 5 Columns */
    FUNCTION fnc_print_col_5 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'five', '230px');
    END fnc_print_col_5;

    /* 6 Columns */
    FUNCTION fnc_print_col_6 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'six', '280px');
    END fnc_print_col_6;

    /* 7 Columns */
    FUNCTION fnc_print_col_7 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'seven', '330px');
    END fnc_print_col_7;

    /* 8 Columns */
    FUNCTION fnc_print_col_8 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'eight', '380px');
    END fnc_print_col_8;

    /* 9 Columns */
    FUNCTION fnc_print_col_9 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'nine', '430px');
    END fnc_print_col_9;

    /* 10 Columns */
    FUNCTION fnc_print_col_10 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'ten', '480px');
    END fnc_print_col_10;

    /* 11 Columns */
    FUNCTION fnc_print_col_11 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'eleven', '530px');
    END fnc_print_col_11;

    /* 12 Columns */
    FUNCTION fnc_print_col_12 (p_content in clob)
		return clob
	IS
    BEGIN
        return fnc_print_col(p_content, 'twelve', '580px');
    END fnc_print_col_12;

    /*
    An empty (and invisible) element added after the content element in a .columns table.
    It forces the content td to expand to the full width of the screen on small devices,
    instead of just the width of the content within the td.
    */
    FUNCTION fnc_print_expander
		return clob
	IS
    BEGIN
        return '<td class="expander" style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: top; text-align: left; visibility: hidden; width: 0px; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: 0;" align="left" valign="top"></td>';
    END fnc_print_expander;

    /**********************************************
    ***********************************************
    ***********************************************
    SUB GRID
    ***********************************************
    ***********************************************
    **********************************************/

    /*
    Can be any number between one and twelve (spelled out).
    Used to determine how wide your .columns tables are.
    The number of sub columns in each row should add up to 12, including offset sub columns .
    */
    FUNCTION fnc_print_sub_col (p_content in clob
								, p_classes in varchar2
								, p_width in varchar2
								, p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return '<td class="sub-columns ' || p_classes || '" style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: middle; text-align: ' || p_align || '; min-width: 0px; width: ' || p_width || '; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; margin: 0; padding: 0px 10px 10px 0px;" align="' || p_align || '" valign="middle">'
            || p_content
            || '</td>';
    END fnc_print_sub_col;

    /* 1 Sub Columns */
    FUNCTION fnc_print_sub_col_1 (
								   p_content in clob,
								   p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'one', round(100*1/12, 4) || '%', p_align);
    END fnc_print_sub_col_1;

    /* 2 Sub Columns */
    FUNCTION fnc_print_sub_col_2 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'two', round(100*2/12, 4) || '%', p_align);
    END fnc_print_sub_col_2;

    /* 3 Sub Columns */
    FUNCTION fnc_print_sub_col_3 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'three', round(100*3/12, 4) || '%', p_align);
    END fnc_print_sub_col_3;

    /* 4 Sub Columns */
    FUNCTION fnc_print_sub_col_4 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'four', round(100*4/12, 4) || '%', p_align);
    END fnc_print_sub_col_4;

    /* 5 Sub Columns */
    FUNCTION fnc_print_sub_col_5 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'five', round(100*5/12, 4) || '%', p_align);
    END fnc_print_sub_col_5;

    /* 6 Sub Columns */
    FUNCTION fnc_print_sub_col_6 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'six', round(100*6/12, 4) || '%', p_align);
    END fnc_print_sub_col_6;

    /* 7 Sub Columns */
    FUNCTION fnc_print_sub_col_7 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'seven', round(100*7/12, 4) || '%', p_align);
    END fnc_print_sub_col_7;

    /* 8 Sub Columns */
    FUNCTION fnc_print_sub_col_8 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'eight', round(100*8/12, 4) || '%', p_align);
    END fnc_print_sub_col_8;

    /* 9 Sub Columns */
    FUNCTION fnc_print_sub_col_9 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'nine', round(100*9/12, 4) || '%', p_align);
    END fnc_print_sub_col_9;

    /* 10 Sub Columns */
    FUNCTION fnc_print_sub_col_10 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'ten', round(100*10/12, 4) || '%', p_align);
    END fnc_print_sub_col_10;

    /* 11 Sub Columns */
    FUNCTION fnc_print_sub_col_11 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'eleven', round(100*11/12, 4) || '%', p_align);
    END fnc_print_sub_col_11;

    /* 12 Sub Columns */
    FUNCTION fnc_print_sub_col_12 (
									p_content in clob,
									p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return fnc_print_sub_col(p_content, 'twelve', round(100*12/12, 4) || '%', p_align);
    END fnc_print_sub_col_12;

    /**********************************************
    ***********************************************
    ***********************************************
    PANELS
    ***********************************************
    ***********************************************
    **********************************************/

    FUNCTION fnc_print_panel (
								p_content in clob
								, p_background_color in varchar2 default '#f2f2f2'
								, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return '<td class="panel" style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: top; text-align: left; color: ' || p_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; background: ' || p_background_color || '; margin: 0; padding: 10px; border: 1px solid #d9d9d9;" align="left" bgcolor="' || p_background_color || '" valign="top">' || p_content || '</td>';
    END fnc_print_panel;

    /**********************************************
    ***********************************************
    ***********************************************
    TYPOGRAPHY
    ***********************************************
    ***********************************************
    **********************************************/

    /* Prints a standard paragraph */
    FUNCTION fnc_print_paragraph (
									p_text in varchar2
									, p_classes in varchar2 default null
									, p_font_size in varchar2 default '14px'
									, p_align in varchar2 default 'left'
									, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return '<p class="' || p_classes || '" style="color: ' || p_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; text-align: ' || p_align || '; line-height: ' || g_line_height || '; font-size: ' || p_font_size || '; margin: 0 0 10px; padding: 0;" align="' || p_align || '">' || p_text || '</p>';
    END fnc_print_paragraph;

    /* Prints a bigger paragraph */
    FUNCTION fnc_print_paragraph_lead (
										p_text in varchar2
										, p_align in varchar2 default 'left'
										, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_paragraph (
            p_text => p_text
            , p_classes => 'lead'
            , p_font_size => '18px'
            , p_align => p_align
            , p_text_color => p_text_color);
    END fnc_print_paragraph_lead;

    /* Prints an H tag */
    FUNCTION fnc_print_h (
							p_text in varchar2
							, p_h_size in varchar2
							, p_font_size in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return '<h' || p_h_size || ' style="color: ' || p_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; text-align: ' || p_align || '; line-height: 1.3; word-break: normal; font-size: ' || p_font_size || '; margin: 0; padding: 0;" align="' || p_align || '">'
            || p_text
            || '</h' || p_h_size || '>';
    END fnc_print_h;

    /* Prints an H1 tag */
    FUNCTION fnc_print_h1 (
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '1'
							, p_font_size => '40px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h1;

    /* Prints an H2 tag */
    FUNCTION fnc_print_h2 (
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '2'
							, p_font_size => '36px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h2;

    /* Prints an H3 tag */
    FUNCTION fnc_print_h3 (
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '3'
							, p_font_size => '32px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h3;

    /* Prints an H4 tag */
    FUNCTION fnc_print_h4 (
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '4'
							, p_font_size => '28px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h4;

    /* Prints an H5 tag */
    FUNCTION fnc_print_h5 (
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '5'
							, p_font_size => '24px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h5;

    /* Prints an H6 tag */
    FUNCTION fnc_print_h6(
							p_text in varchar2
							, p_align in varchar2 default 'left'
							, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return fnc_print_h (
							p_text => p_text
							, p_h_size => '6'
							, p_font_size => '20px'
							, p_align => p_align
							, p_text_color => p_text_color);
    END fnc_print_h6;

    /* Prints a small text */
    FUNCTION fnc_print_small_text(
									p_text in varchar2
									, p_text_color in varchar2 default g_text_color)
		return clob
	IS
    BEGIN
        return '<small style="font-size: 10px;">' || p_text || '</small>';
    END fnc_print_small_text;

    /* Prints a label for the title bar */
    FUNCTION fnc_print_title(
								p_text in varchar2
								, p_text_color in varchar2 default '#ffffff')
		return clob
	IS
    BEGIN
        return '<span class="template-label" style="color: ' || p_text_color || '; font-weight: bold; font-size: 11px;">' || p_text || '</span>';
    END fnc_print_title;

    /**********************************************
    ***********************************************
    ***********************************************
    BUTTONS
    ***********************************************
    ***********************************************
    **********************************************/

    FUNCTION fnc_print_button (
								p_content in clob
								, p_button_classes in varchar2 default 'button'
								, p_align in varchar2 default 'left'
								, p_padding in varchar2 default '0 0 10px'
								, p_background_color in varchar2 default 'transparent'
								, p_border in varchar2 default 'none'
								, p_extra_style in varchar2 default null)
		return clob
	IS
    BEGIN
        return '<table class="' || p_button_classes || '" style="border-spacing: 0; border-collapse: collapse; vertical-align: top; text-align: left; width: 100%; overflow: hidden; padding: 0;">'
            || '<tr style="vertical-align: top; text-align: left; padding: 0;" align="left">'
            || '<td style="word-break: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; border-collapse: collapse !important; vertical-align: top; text-align: ' || p_align || '; color: ' || g_text_color || '; font-family: ' || g_font_family || '; font-weight: normal; line-height: ' || g_line_height || '; font-size: ' || g_font_size || '; background: ' || p_background_color || '; margin: 0; padding: ' || p_padding || '; border: ' || p_border || '; ' || p_extra_style || '" align="' || p_align || '" valign="top" bgcolor="' || p_background_color || '">'
            || p_content
            || '</td>'
            || '</tr>'
            || '</table>';
    END fnc_print_button;

    FUNCTION fnc_print_plain_link (
									p_url in clob
									, p_label in clob)
		return clob
	IS
    BEGIN
        return fnc_print_button(
								p_content => '<a href="' || p_url || '" style="color: ' || g_text_color || '; text-decoration: none;">' || p_label || '</a>'
							);
    END fnc_print_plain_link;

    FUNCTION fnc_print_primary_button (
										p_url in clob
										, p_label in clob)
		return clob
	IS
    BEGIN
        return fnc_print_button(
								p_content => '<a href="' || p_url || '" style="color: ' || g_primary_button_text_color || '; text-decoration: none; font-weight: bold; font-family: ' || g_font_family || '; font-size: 16px;">' || p_label || '</a>'
								,p_align => 'center'
								,p_padding => '8px 0'
								,p_background_color => g_primary_button_bgcolor
								,p_border => '1px solid #2284a1'
								,p_extra_style => 'display: block; width: auto !important;'
								);
    END fnc_print_primary_button;

    FUNCTION fnc_print_button_facebook (
										p_url in clob
										, p_label in clob)
		return clob
	IS
    BEGIN
        return fnc_print_button(
							p_content => '<a href="' || p_url || '" style="color: #ffffff; text-decoration: none; font-weight: bold; font-family: ' || g_font_family || '; font-size: 12px;">' || p_label || '</a>'
							,p_button_classes => 'tiny-button facebook'
							,p_align => 'center'
							,p_padding => '5px 0 4px'
							,p_background_color => '#3b5998'
							,p_border => '1px solid #2d4473'
							,p_extra_style => 'display: block; width: auto !important;'
							);
    END fnc_print_button_facebook;

    FUNCTION fnc_print_button_twitter (
										p_url in clob
										, p_label in clob)
		return clob
	IS
    BEGIN
        return fnc_print_button(
							p_content => '<a href="' || p_url || '" style="color: #ffffff; text-decoration: none; font-weight: bold; font-family: ' || g_font_family || '; font-size: 12px;">' || p_label || '</a>'
							,p_button_classes => 'tiny-button twitter'
							,p_align => 'center'
							,p_padding => '5px 0 4px'
							,p_background_color => '#00acee'
							,p_border => '1px solid #0087bb'
							,p_extra_style => 'display: block; width: auto !important;'
							);
    END fnc_print_button_twitter;

    FUNCTION fnc_print_button_google_plus (
											p_url in clob
											, p_label in clob)
		return clob
	IS
    BEGIN
        return fnc_print_button(
							p_content => '<a href="' || p_url || '" style="color: #ffffff; text-decoration: none; font-weight: bold; font-family: ' || g_font_family || '; font-size: 12px;">' || p_label || '</a>'
							,p_button_classes => 'tiny-button google-plus'
							,p_align => 'center'
							,p_padding => '5px 0 4px'
							,p_background_color => '#DB4A39'
							,p_border => '1px solid #cc0000'
							,p_extra_style => 'display: block; width: auto !important;'
							);
    END fnc_print_button_google_plus;

    /**********************************************
    ***********************************************
    ***********************************************
    OTHER FEATURES
    ***********************************************
    ***********************************************
    **********************************************/

    /*
    Print an image through a URL
    Can be aligned left, center or right
    */
    FUNCTION fnc_print_image(
								p_img_url in varchar2
								, p_align in varchar2 default 'left')
		return clob
	IS
    BEGIN
        return '<img src="' || p_img_url || '" style="outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; width: auto; max-width: 100%; float: left; clear: both; display: block;" align="' || p_align || '" />';
    END fnc_print_image;

    /* Simple line to separate content */
    FUNCTION fnc_print_hr
		return clob
	IS
    BEGIN
        return '<hr style="color: #d9d9d9; height: 1px; background: #d9d9d9; border: none;" />';
    END fnc_print_hr;

    /**********************************************
    ***********************************************
    ***********************************************
    COMMON PATTERNS
    ***********************************************
    ***********************************************
    **********************************************/

    FUNCTION fnc_print_default_body_header(
											p_logo_url in varchar2
											, p_title in varchar2)
		return clob
	IS
    BEGIN
        return  fnc_print_row(
							p_content => fnc_print_standard_td_center(
											fnc_print_container(
												fnc_print_column_wrapper (
													fnc_print_col_12(
														fnc_print_sub_col_6(fnc_print_image(p_logo_url), 'left')
														|| fnc_print_sub_col_6(fnc_print_title(p_title), 'right')
													)
												)
											)
										)
							, p_classes => 'header'
							, p_display => 'table'
							, p_header_background_color => g_header_background_color
                )
                || '<br />';
    END fnc_print_default_body_header;

    FUNCTION fnc_print_default_body_footer(
											p_footer_links in varchar2)
		return clob
	IS
    BEGIN
        return  '<br /><br />'
                || fnc_print_row(
                    fnc_print_column_wrapper (
                        fnc_print_col_12(
                            fnc_print_standard_td_center(
                                fnc_print_paragraph (
                                    p_text => p_footer_links
                                    , p_align => 'center')
                            )
                        )
                    )
                );
    END fnc_print_default_body_footer;

    FUNCTION fnc_print_global_body(
									p_content in clob)
		return clob
	IS
    BEGIN
        return  fnc_print_global_header
                || fnc_outer_body(
                    fnc_print_global_css
                    || fnc_inner_body(
                        fnc_print_standard_td_center(p_content)
                    )
                )
                || fnc_print_global_end;
    END fnc_print_global_body;

    /**********************************************
    ***********************************************
    ***********************************************
    PREset TEMPLATES
    ***********************************************
    ***********************************************
    **********************************************/

    /* Basic Template */
    FUNCTION fnc_basic (p_content in t_content)
		return clob
	IS
        l_body clob;
    BEGIN
        /* Build the email body */
        l_body :=   fnc_print_global_body(
                        fnc_print_default_body_header(p_content.logo_url, p_content.title)
                        || fnc_print_container(
                            fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_12(
                                        fnc_print_standard_td(
                                            fnc_print_h1(p_content.welcome_title)
                                            || fnc_print_paragraph_lead(p_content.sub_welcome_title)
                                            || fnc_print_paragraph(p_content.top_paragraph)
                                        )
                                    )
                                )
                            )
                            || fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_12(
                                        fnc_print_panel(
                                            p_content => fnc_print_paragraph(
                                                            p_text => p_content.bottom_paragraph)
                                            , p_background_color => '#ECF8FF')
                                    )
                                )
                            )
                            || '<br />'
                            || fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.social_title)
                                            || fnc_print_button_facebook(
                                                p_url => '#'
                                                ,p_label => 'Facebook')
                                            || fnc_print_hr
                                            || fnc_print_button_twitter(
                                                p_url => '#'
                                                ,p_label => 'Twitter')
                                            || fnc_print_hr
                                            || fnc_print_button_google_plus(
                                                p_url => '#'
                                                ,p_label => 'Google+')
                                        )
                                    )
                                )
                                || fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.contact_info)
                                            || fnc_print_paragraph(p_content.contact_phone)
                                            || fnc_print_paragraph(p_content.contact_email)
                                        )
                                    )
                                )
                            )
                            || fnc_print_default_body_footer(p_content.footer_links)
                        )
                    );

        /* Returns email body */
        return l_body;
    END fnc_basic;

    /* Hero Template */
    FUNCTION fnc_hero (p_content in t_content)
		RETURN clob
	IS
        l_body clob;
    BEGIN
        /* Build the email body */
        l_body :=   fnc_print_global_body(
                        fnc_print_default_body_header(p_content.logo_url, p_content.title)
                        || fnc_print_container(
                            fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_12(
                                        fnc_print_standard_td(
                                            fnc_print_h1(p_content.welcome_title)
                                            || fnc_print_paragraph_lead(p_content.sub_welcome_title)
                                            || fnc_print_image(p_content.big_picture_url)
                                        )
                                    )
                                )
                            )
                            || fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_12(
                                        fnc_print_panel(
                                            p_content           =>  fnc_print_paragraph(
                                                                        p_text => p_content.top_paragraph)
                                            ,p_background_color => '#ECF8FF')
                                    )
                                    || '<br />'
                                    || fnc_print_col_12(
                                        fnc_print_h3(p_content.bottom_paragraph_title
                                                || fnc_print_small_text(p_content.bottom_paragraph_subtitle))
                                        || fnc_print_paragraph(
                                                p_text => p_content.bottom_paragraph)
                                    )
                                )
                            )
                            || '<br />'
                            || fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.social_title)
                                            || fnc_print_button_facebook(
                                                p_url => '#'
                                                ,p_label => 'Facebook')
                                            || fnc_print_hr
                                            || fnc_print_button_twitter(
                                                p_url => '#'
                                                ,p_label => 'Twitter')
                                            || fnc_print_hr
                                            || fnc_print_button_google_plus(
                                                p_url => '#'
                                                ,p_label => 'Google+')
                                        )
                                    )
                                )
                                || fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.contact_info)
                                            || fnc_print_paragraph(p_content.contact_phone)
                                            || fnc_print_paragraph(p_content.contact_email)
                                        )
                                    )
                                )
                            )
                            || fnc_print_default_body_footer(p_content.footer_links)
                        )
                    );

        /* Returns email body */
        return l_body;
    END fnc_hero;

    /* Sidebar Template */
    FUNCTION fnc_sidebar (p_content in t_content)
		return clob
	IS
        l_body clob;
    BEGIN
        /* Build the email body */
        l_body :=   fnc_print_global_body(
                        fnc_print_default_body_header(p_content.logo_url, p_content.title)
                        || fnc_print_container(
                            fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_standard_td(
                                            fnc_print_h1(p_content.welcome_title)
                                            || fnc_print_paragraph(p_content.sub_welcome_title)
                                            || fnc_print_paragraph(p_content.left_paragraph)
                                        )
                                    )
                                    || '<br />'
                                    || fnc_print_col_6(
                                        fnc_print_panel(fnc_print_paragraph(p_content.top_paragraph))
                                    )
                                    || '<br />'
                                    || fnc_print_col_6(
                                        fnc_print_standard_td(
                                            fnc_print_paragraph(p_content.left_paragraph)
                                            || fnc_print_primary_button (
                                                p_url => '#'
                                                , p_label => 'Click Me!')
                                        )
                                    )
                                )
                                || fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.right_header)
                                            || fnc_print_paragraph(p_content.right_sub_header)
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                        )
                                    )
                                    || '<br />'
                                    || fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.social_title)
                                            || fnc_print_button_facebook(
                                                p_url => '#'
                                                ,p_label => 'Facebook')
                                            || fnc_print_hr
                                            || fnc_print_button_twitter(
                                                p_url => '#'
                                                ,p_label => 'Twitter')
                                            || fnc_print_hr
                                            || fnc_print_button_google_plus(
                                                p_url => '#'
                                                ,p_label => 'Google+')
                                            || '<br />'
                                            || fnc_print_h6(p_content.contact_info)
                                            || fnc_print_paragraph(p_content.contact_phone)
                                            || fnc_print_paragraph(p_content.contact_email)
                                        )
                                    )
                                )
                            )
                            || fnc_print_default_body_footer(p_content.footer_links)
                        )
                    );

        /* Returns email body */
        return l_body;
    END fnc_sidebar;

    /* Sidebar Hero Template */
    FUNCTION fnc_sidebar_hero (p_content in t_content)
		return clob
	IS
        l_body clob;
    BEGIN
        /* Build the email body */
        l_body :=   fnc_print_global_body(
                        fnc_print_default_body_header(p_content.logo_url, p_content.title)
                        || fnc_print_container(
                            fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_12(
                                        fnc_print_standard_td(
                                            fnc_print_h1(p_content.welcome_title)
                                            || fnc_print_paragraph(p_content.sub_welcome_title)
                                            || fnc_print_image(p_content.big_picture_url)
                                        )
                                    )
                                    || fnc_print_col_12(
                                        fnc_print_panel(fnc_print_paragraph(p_content.top_paragraph))
                                    )
                                )
                            )
                            || '<br />'
                            || fnc_print_row(
                                fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_standard_td(
                                            fnc_print_paragraph(p_content.left_paragraph)
                                            || fnc_print_primary_button (
                                                    p_url => '#'
                                                    , p_label => 'Click Me!')
                                        )
                                    )
                                )
                                || fnc_print_column_wrapper(
                                    fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.right_header)
                                            || fnc_print_paragraph(p_content.right_sub_header)
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                            || fnc_print_hr
                                            || fnc_print_plain_link('#', 'Just a Plain Link ¿')
                                        )
                                    )
                                    || '<br />'
                                    || fnc_print_col_6(
                                        fnc_print_panel(
                                            fnc_print_h6(p_content.social_title)
                                            || fnc_print_button_facebook(
                                                p_url => '#'
                                                ,p_label => 'Facebook')
                                            || fnc_print_hr
                                            || fnc_print_button_twitter(
                                                p_url => '#'
                                                ,p_label => 'Twitter')
                                            || fnc_print_hr
                                            || fnc_print_button_google_plus(
                                                p_url => '#'
                                                ,p_label => 'Google+')
                                            || '<br />'
                                            || fnc_print_h6(p_content.contact_info)
                                            || fnc_print_paragraph(p_content.contact_phone)
                                            || fnc_print_paragraph(p_content.contact_email)
                                        )
                                    )
                                )
                            )
                            || fnc_print_default_body_footer(p_content.footer_links)
                        )
                    );

        /* Returns email body */
        return l_body;
    END fnc_sidebar_hero;

END pkg_ma_email_template;


/
