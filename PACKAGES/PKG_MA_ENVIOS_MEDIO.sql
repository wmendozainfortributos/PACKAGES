--------------------------------------------------------
--  DDL for Package PKG_MA_ENVIOS_MEDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MA_ENVIOS_MEDIO" as
  /*Procedimiento para enviar SMS*/
  procedure prc_rg_sms(p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
                       o_cdgo_rspsta   out number,
                       o_mnsje_rspsta  out varchar2);

  /*Procedimiento para enviar Correo*/
  procedure prc_rg_mail(p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
                        o_cdgo_rspsta   out number,
                        o_mnsje_rspsta  out varchar2);

  /*Procedimiento para registrar Alerta*/
  procedure prc_rg_alerta(p_id_envio_mdio in ma_g_envios_medio.id_envio_mdio%type,
                          o_cdgo_rspsta   out number,
                          o_mnsje_rspsta  out varchar2);
end pkg_ma_envios_medio;

/
