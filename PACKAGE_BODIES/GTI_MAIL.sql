--------------------------------------------------------
--  DDL for Package Body GTI_MAIL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."GTI_MAIL" is
	l_conn			utl_smtp.connection;
	g_smtp_host		varchar2 (256)     := 'localhost';
	g_smtp_port		pls_integer        := 11025;
	g_smtp_domain	varchar2 (256)     := 'gmail.com';
	g_email			varchar2(100);
	g_password		varchar2(100);
	g_mailer_id		constant varchar2 (256) := 'Mailer by Oracle UTL_SMTP';
	g_error			varchar2(1900);

	-- Write a MIME header
	procedure write_mime_header (
		p_conn in out nocopy utl_smtp.connection,
		p_name in varchar2,
		p_value in varchar2 ) is
	begin
		utl_smtp.write_data ( p_conn, p_name || ': ' || p_value || utl_tcp.crlf );
	end;

	-- Set Parameters
	procedure set_parameters( v_cod_cia number) is
		cursor c1 is
		select *
		from gti_mail_conf
		where cod_cia = v_cod_cia;
	begin
		for i in c1 loop
			g_smtp_host   := i.smtp_server;
			g_smtp_port   := i.smtp_port;
			g_smtp_domain := i.smtp_domain;
			g_email       := i.email;
			g_password    := i.password;
		end loop;
	end;
	
	procedure add_rcpt(p_Destinatarios in varchar2 ) as
		l_Cadena varchar2(500) := p_Destinatarios;
		l_LargoCadena number;
		l_Comas number;
		l_PosicionComa number := 0;
		l_Destinatario varchar2(100);
		l_Destinatarios varchar2(2000);
	begin
		l_Cadena := replace(l_Cadena,' ', '');
		l_Cadena := trim(l_Cadena);
		l_LargoCadena := length(l_Cadena);
		l_Comas := l_LargoCadena-length(replace(l_Cadena,','));
		
		--Bloque 1 Asginación del RCPT
		if ( l_Comas > 0 ) then
			for l_segmento in 1 .. l_Comas loop
				l_Destinatario := substr(l_Cadena, l_PosicionComa + 1, instr(l_Cadena,',',1,l_segmento) - (l_PosicionComa + 1));
				l_PosicionComa := instr(l_Cadena,',',1,l_Segmento);
				utl_smtp.rcpt(l_conn, l_Destinatario);
				l_Destinatarios := l_Destinatarios || l_Destinatario || '|';
			end loop;
		end if;
		-- Fin de Bloque 1
	
		-- Bloque 2: Para inserción del ultimo recipient solicitado (o el primero, si es unico)
		l_Destinatario := substr(l_Cadena, l_PosicionComa + 1, l_LargoCadena);
		utl_smtp.rcpt(l_conn, l_Destinatario);
		l_Destinatarios := l_Destinatarios || l_Destinatario || '|';
		-- Fin Bloque 2  
		
		--return l_Destinatarios;
	end;

	procedure send_mail (
		p_cod_cia number,
		p_sender in varchar2,
		p_recipient in varchar2,
		p_subject in varchar2,
		p_message in varchar2,
		p_attach_name IN VARCHAR2 DEFAULT NULL,
		p_attach_mime IN VARCHAR2 DEFAULT NULL,
		p_attach_blob IN BLOB DEFAULT NULL,
		p_cod_mail	IN NUMBER DEFAULT NULL) is

		l_boundary	varchar2(50) := '----=*#abc1234321cba#*=';
		l_step		pls_integer  := 12000; -- make sure you set a multiple of 3 not higher than 24573
		nls_charset	varchar2(255);
		v_cadena	varchar2(400);

	begin

delete gti_aux;
commit;

		-- get characterset
		select value into nls_charset
		from   nls_database_parameters
		where  parameter = 'NLS_CHARACTERSET';

		-- set parameteres
		set_parameters(p_cod_cia);
insert into gti_aux(col1, col2) values (0, 'set parameters paso');
commit;

		-- establish connection and autheticate
		l_conn   := utl_smtp.open_connection (g_smtp_host, g_smtp_port);
insert into gti_aux(col1, col2) values (1, 'Despues de conexion');
commit;
		utl_smtp.ehlo(l_conn, g_smtp_domain);
insert into gti_aux(col1, col2) values (2, 'Despues de ehlo');
commit;
		utl_smtp.command(l_conn, 'auth login');
insert into gti_aux(col1, col2) values (3, 'Despues de Auth Login');
commit;
		utl_smtp.command(l_conn,utl_encode.text_encode(g_email, nls_charset, 1));
insert into gti_aux(col1, col2) values (4, 'Despues de g_email');
commit;
		utl_smtp.command(l_conn, utl_encode.text_encode(g_password, nls_charset, 1));
insert into gti_aux(col1, col2) values (5, 'conexion establecida paso');
commit;

		-- set from/recipient
		utl_smtp.command(l_conn, 'MAIL FROM: <'||p_sender||'>');
		-- set recipent(s)
		add_rcpt(p_recipient);
		--utl_smtp.command(l_conn, 'RCPT TO: <'||p_recipient||'>');
insert into gti_aux(col1, col2) values (5.5, 'Despues de MAIL FROM  y  RCPT TO: ' || p_recipient);
commit;
		-- write mime headers
		utl_smtp.open_data (l_conn);
		write_mime_header (l_conn, 'Date', TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
		write_mime_header (l_conn, 'From', p_sender);
		write_mime_header (l_conn, 'To', p_recipient);
		write_mime_header (l_conn, 'Subject', p_subject);
		write_mime_header (l_conn, 'Content-Type', 'multipart/mixed; boundary="' || l_boundary || '"' );
		write_mime_header (l_conn, 'X-Mailer', g_mailer_id);
		utl_smtp.write_data (l_conn, utl_tcp.crlf);
insert into gti_aux(col1, col2) values (5.5, 'Despues de Encabezado: To: ' || p_recipient || ' Subject: ' || p_subject);
commit;
		-- write message body
		if p_message is not null then
			utl_smtp.write_data(l_conn, '--' || l_boundary || UTL_TCP.crlf);
			utl_smtp.write_data(l_conn, 'Content-Type: text/html; charset="iso-8859-1"' || utl_tcp.crlf || utl_tcp.crlf);

			utl_smtp.write_data (l_conn, p_message);
			utl_smtp.write_data(l_conn, utl_tcp.crlf || utl_tcp.crlf);
		end if;
--insert into gti_aux(col1, col2) values (6, 'Despues de message body: ' || p_message);
commit;
		-- Attachment UNO
		if p_attach_name is not null then
			utl_smtp.write_data(l_conn, '--' || l_boundary || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'Content-Type: ' || p_attach_mime || '; name="' || p_attach_name || '"' || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'Content-Transfer-Encoding: base64' || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'Content-Disposition: attachment; filename="' || p_attach_name || '"' || utl_tcp.crlf || utl_tcp.crlf);

			for i in 0 .. trunc((dbms_lob.getlength(p_attach_blob) - 1 )/l_step) loop
				utl_smtp.write_data(l_conn, UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_attach_blob, l_step, i * l_step + 1))));
			end loop;

			utl_smtp.write_data(l_conn, utl_tcp.crlf || utl_tcp.crlf);
		end if;

		-- Adjuntamos archivos de la Tabla gti_email_attachment
		if p_cod_mail is not null then
insert into gti_aux(col1, col2) values (71, 'Antes de For archivos adjuntos');
commit;
			for j in (select * from gti_email_attachment where cod_mail = p_cod_mail) loop
				utl_smtp.write_data(l_conn, '--' || l_boundary || utl_tcp.crlf);
				utl_smtp.write_data(l_conn, 'Content-Type: ' || j.FILE_MIMETYPE || '; name="' || j.FILENAME || '"' || utl_tcp.crlf);
				utl_smtp.write_data(l_conn, 'Content-Transfer-Encoding: base64' || utl_tcp.crlf);
				utl_smtp.write_data(l_conn, 'Content-Disposition: attachment; filename="' || j.FILENAME || '"' || utl_tcp.crlf || utl_tcp.crlf);

				for i in 0 .. trunc((dbms_lob.getlength(j.FILE_BLOB) - 1 )/l_step) loop
					utl_smtp.write_data(l_conn, UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(j.FILE_BLOB, l_step, i * l_step + 1))));
				end loop;
				utl_smtp.write_data(l_conn, utl_tcp.crlf || utl_tcp.crlf);
insert into gti_aux(col1, col2) values (72, 'Archivo adjunto: ' || j.FILENAME);
commit;
			end loop;
		end if;

insert into gti_aux(col1, col2) values (7, 'Antes de fin de conexion paso');
commit;
		-- end connection
		utl_smtp.write_data(l_conn, '--' || l_boundary || utl_tcp.crlf);
		utl_smtp.close_data(l_conn);
		utl_smtp.quit (l_conn);
insert into gti_aux(col1, col2) values (7.99, 'Fin');
commit;
	exception
		when others then
			begin
				v_cadena := sqlerrm;
insert into gti_aux(col1, col2) values (8, 'Exception 1 paso. ' || v_cadena);
commit;

				utl_smtp.quit(l_conn);
			exception
				when others then
					v_cadena := sqlerrm;
insert into gti_aux(col1, col2) values (9, 'Exception 2 paso. ' || v_cadena);
commit;
					null;
			end;
			raise_application_error(-20000,'Fallo para enviar correo electronico. Error: ' || sqlerrm);
	end;
end;

/
