--------------------------------------------------------
--  DDL for Package PKG_GN_DOCUMENTOS_DINAMICOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GN_DOCUMENTOS_DINAMICOS" as 

  nmro_prcsos_jrdco cb_g_procesos_juridico.nmro_prcso_jrdco%type;
  fcha_prcso_jrdco  cb_g_procesos_juridico.fcha%type;
  sujetos           varchar2(500);
  responsables      varchar2(5000);
  cartera           varchar2(5000);
        
end pkg_gn_documentos_dinamicos;

/
