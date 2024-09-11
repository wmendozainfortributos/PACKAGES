--------------------------------------------------------
--  DDL for Package GTI_MAIL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."GTI_MAIL" is

	-- Write a MIME header
	procedure write_mime_header (
		p_conn in out nocopy utl_smtp.connection,
		p_name in varchar2,
		p_value in varchar2 );
  
	-- set Parameters
	procedure set_parameters( v_cod_cia number);
	
	-- Set Recipents
	procedure add_rcpt(p_Destinatarios in varchar2 );
  
	-- send mail using UTL_SMTP
	procedure send_mail (
		p_cod_cia number,
		p_sender in varchar2,
		p_recipient in varchar2,
		p_subject in varchar2,
		p_message in varchar2,
		p_attach_name IN VARCHAR2 DEFAULT NULL,
		p_attach_mime IN VARCHAR2 DEFAULT NULL,
		p_attach_blob IN BLOB DEFAULT NULL,
		p_cod_mail	IN NUMBER DEFAULT NULL);
  
end;

/
