--------------------------------------------------------
--  DDL for Package Body PKG_RE_RECAUDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_RE_RECAUDOS" as

  --01/06/2022 Insolvencia Acuerdos de Pago 

  /*
  *g_cdgo_mvmnto_orgn : Origen de Movimiento Financiero
  */
  g_cdgo_mvmnto_orgn constant varchar2(2) := 'RE';

  /*
  * @Descripcion  : Registra Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudo_control(p_cdgo_clnte        in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_impsto         in re_g_recaudos_control.id_impsto%type,
                                   p_id_impsto_sbmpsto in re_g_recaudos_control.id_impsto_sbmpsto%type,
                                   p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                   p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                   p_fcha_cntrol       in re_g_recaudos_control.fcha_cntrol%type,
                                   p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                   p_id_rcdo_cja       in number default null,
                                   p_cdgo_rcdo_orgen   in re_g_recaudos_control.cdgo_rcdo_orgen%type,
                                   p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type default null,
                                   p_id_usrio          in re_g_recaudos_control.id_usrio%type,
                                   o_id_rcdo_cntrol    out re_g_recaudos_control.id_rcdo_cntrol%type,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_recaudo_control';
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Inserta el Registro de Recaudo Control
    insert into re_g_recaudos_control
      (cdgo_clnte,
       id_impsto,
       id_impsto_sbmpsto,
       id_bnco,
       id_bnco_cnta,
       fcha_cntrol,
       obsrvcion,
       cdgo_rcdo_orgen,
       id_prcso_crga,
       id_usrio)
    values
      (p_cdgo_clnte,
       p_id_impsto,
       p_id_impsto_sbmpsto,
       p_id_bnco,
       p_id_bnco_cnta,
       p_fcha_cntrol,
       p_obsrvcion,
       p_cdgo_rcdo_orgen,
       p_id_prcso_crga,
       p_id_usrio)
    returning id_rcdo_cntrol into o_id_rcdo_cntrol;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Recaudo control creado con exito #' ||
                      o_id_rcdo_cntrol || '.';
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible crear el recaudo control, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 1);
  end prc_rg_recaudo_control;

  /*
  * @Descripcion  : Actualiza Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ac_recaudo_control(p_cdgo_clnte        in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_usrio          in re_g_recaudos_control.id_usrio%type,
                                   p_id_rcdo_cntrol    in re_g_recaudos_control.id_rcdo_cntrol%type,
                                   p_id_impsto         in re_g_recaudos_control.id_impsto%type,
                                   p_id_impsto_sbmpsto in re_g_recaudos_control.id_impsto_sbmpsto%type,
                                   p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                   p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                   p_fcha_cntrol       in re_g_recaudos_control.fcha_cntrol%type,
                                   p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ac_recaudo_control';
    v_rcdos    number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Cantidad de Recaudos
    select count(*)
      into v_rcdos
      from re_g_recaudos
     where id_rcdo_cntrol = p_id_rcdo_cntrol;
  
    --Verifica si Existen Recaudos Registrados
    if (v_rcdos > 0) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo control #' ||
                        p_id_rcdo_cntrol ||
                        ', no fue posible actualizar ya que existen recaudos asociados.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Actualiza los Datos de Recaudos Control
    update re_g_recaudos_control
       set id_impsto         = p_id_impsto,
           id_impsto_sbmpsto = p_id_impsto_sbmpsto,
           id_bnco           = p_id_bnco,
           id_bnco_cnta      = p_id_bnco_cnta,
           fcha_cntrol       = p_fcha_cntrol,
           obsrvcion         = p_obsrvcion,
           id_usrio          = p_id_usrio,
           cntdad_rcdos      = 0,
           vlor_rcdos        = 0
     where id_rcdo_cntrol = p_id_rcdo_cntrol;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Recaudo control actualizado con exito #' ||
                      p_id_rcdo_cntrol || '.';
  
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible actualizar el recaudo control #[' ||
                        p_id_rcdo_cntrol || '], intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ac_recaudo_control;

  /*
  * @Descripcion  : Elimina Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_el_recaudo_control(p_cdgo_clnte     in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_usrio       in re_g_recaudos_control.id_usrio%type,
                                   p_id_rcdo_cntrol in re_g_recaudos_control.id_rcdo_cntrol%type,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_el_recaudo_control';
    v_rcdos    number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    delete from re_g_recaudos_control
     where id_rcdo_cntrol = p_id_rcdo_cntrol;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Recaudo control eliminado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible eliminar el recaudo control #[' ||
                        p_id_rcdo_cntrol || '], intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_el_recaudo_control;

  /*
  * @Descripcion  : Validar Documento de Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_documento_01(p_cdgo_ean           in varchar2,
                                p_nmro_dcmnto        in number,
                                p_vlor               in number,
                                p_fcha_vncmnto       in date default null,
                                p_fcha_rcdo          in date default null,
                                p_indcdor_vlda_pgo   in boolean default true,
                                o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                                o_id_orgen           out re_g_recaudos.id_orgen%type,
                                o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                                o_id_impsto          out df_c_impuestos.id_impsto%type,
                                o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2) as
    v_vlor  number;
    v_rcdos number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Se Verifica si el codigo EAN es Numerico
    if (not regexp_like(p_cdgo_ean, '^[[:digit:]]+$')) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Codigo EAN no valido, verifique que sea numerico.';
      return;
    end if;
  
    --Se Verifica si los Parametros de Entrada no esten Nulos
    if (p_cdgo_ean is null) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'El codigo EAN se encuentra vacio.';
      return;
    elsif (p_nmro_dcmnto is null) then
      o_mnsje_rspsta := 'El numero de documento se encuentra vacio.';
      o_cdgo_rspsta  := 3;
      return;
    elsif (p_vlor is null) then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'El valor a pagar se encuentra vacio.';
      return;
    elsif (p_fcha_vncmnto is null and p_fcha_rcdo is null) then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'La fecha de documento se encuentra vacio.';
      return;
    end if;
  
    --Se Verifica si Codigo EAN Existe
    begin
      select cdgo_clnte
        into o_cdgo_clnte
        from df_i_impuestos_subimpuesto
       where cdgo_ean = p_cdgo_ean
       fetch first 1 row only;
    exception
      when no_data_found then
        --Se Verifica si Codigo EAN Existe por Historico
        begin
          select cdgo_clnte
            into o_cdgo_clnte
            from df_h_ean
           where cdgo_ean = p_cdgo_ean;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'El codigo EAN[' || p_cdgo_ean ||
                              '], no existe en el sistema.';
            return;
        end;
    end;
  
    --Indica que el Documento es una Declaracion
    if (p_nmro_dcmnto like '120%') then
      --Declaracion
      o_cdgo_rcdo_orgn_tpo := 'DL';
    
      --Verifica si la Declaracion Existe
      begin
        select id_dclrcion,
               vlor_pago,
               id_sjto_impsto,
               id_impsto,
               id_impsto_sbmpsto
          into o_id_orgen,
               v_vlor,
               o_id_sjto_impsto,
               o_id_impsto,
               o_id_impsto_sbmpsto
          from gi_g_declaraciones
         where cdgo_clnte = o_cdgo_clnte
           and nmro_cnsctvo = p_nmro_dcmnto
           and trunc(fcha_prsntcion_pryctda) =
               nvl(p_fcha_vncmnto, trunc(fcha_prsntcion_pryctda))
           and vlor_pago = p_vlor;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'El documento ' || p_nmro_dcmnto || ' por ' ||
                            to_char(p_vlor, 'FM$999G999G999G999G999G999G990') ||
                            (case
                              when p_fcha_vncmnto is not null then
                               ' y fecha: ' || to_char(p_fcha_vncmnto, 'DD/MM/YYYY')
                            end) || ', no existe.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'No fue posible encontrar la declaracion #' ||
                            p_nmro_dcmnto ||
                            ', ya que existe mas de uno en el sistema.';
          return;
      end;
    else
      --Documento
      o_cdgo_rcdo_orgn_tpo := 'DC';
    
      --Verifica si el Documento Existe
      begin
        select id_dcmnto,
               vlor_ttal_dcmnto,
               id_sjto_impsto,
               id_impsto,
               id_impsto_sbmpsto
          into o_id_orgen,
               v_vlor,
               o_id_sjto_impsto,
               o_id_impsto,
               o_id_impsto_sbmpsto
          from re_g_documentos
         where cdgo_clnte = o_cdgo_clnte
           and nmro_dcmnto = p_nmro_dcmnto
           and trunc(fcha_vncmnto) =
               nvl(p_fcha_vncmnto, trunc(fcha_vncmnto))
           and vlor_ttal_dcmnto =
               nvl2(p_fcha_rcdo, p_vlor, vlor_ttal_dcmnto);
      exception
        when no_data_found then
          /*Se agrego este bloque de codigo que consulta la declaracion
           *porque no parametrizaron el consecutivo de la declaracion
           *que empezara con 1
          */
          --Declaracion
          o_cdgo_rcdo_orgn_tpo := 'DL';
        
          --Verifica si la Declaracion Existe
          begin
            select id_dclrcion,
                   vlor_pago,
                   id_sjto_impsto,
                   id_impsto,
                   id_impsto_sbmpsto
              into o_id_orgen,
                   v_vlor,
                   o_id_sjto_impsto,
                   o_id_impsto,
                   o_id_impsto_sbmpsto
              from gi_g_declaraciones
             where cdgo_clnte = o_cdgo_clnte
               and nmro_cnsctvo = p_nmro_dcmnto
               and trunc(fcha_prsntcion_pryctda) =
                   nvl(p_fcha_vncmnto, trunc(fcha_prsntcion_pryctda))
               and vlor_pago = p_vlor;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'El documento ' || p_nmro_dcmnto || ' por ' ||
                                to_char(p_vlor, 'FM$999G999G999G999G999G999G990') ||
                                (case
                                  when p_fcha_vncmnto is not null then
                                   ' y fecha: ' || to_char(p_fcha_vncmnto, 'DD/MM/YYYY')
                                end) || ', no existe.';
              return;
            when too_many_rows then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'No fue posible encontrar la declaracion #' ||
                                p_nmro_dcmnto ||
                                ', ya que existe mas de uno en el sistema.';
              return;
          end;
          /*o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'El documento de pago #' || p_nmro_dcmnto || ' con valor ' || to_char( p_vlor , 'FM$999G999G999G999G999G999G990')
                            || ( case when p_fcha_vncmnto is not null then
                                     ' y fecha de vencimiento: ' || to_char(  p_fcha_vncmnto , 'DD/MM/YYYY' )
                                 end )
                            || ', no existe en el sistema.';
          return;*/
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No fue posible encontrar el documento de pago #' ||
                            p_nmro_dcmnto ||
                            ', ya que existe mas de uno en el sistema.';
          return;
      end;
    end if;
  
    --Verifica si el Valor del Documento Corresponde al Recaudado
    if (v_vlor <> p_vlor) then
      o_cdgo_rspsta  := 11;
      o_mnsje_rspsta := 'El valor a pagar ' ||
                        to_char(p_vlor, 'FM$999G999G999G999G999G999G990') ||
                        ' del documento #' || p_nmro_dcmnto ||
                        ', no corresponde al del sistema. ' || v_vlor;
      return;
    end if;
  
    --Valida Pago del Documento
    if (p_indcdor_vlda_pgo) then
    
      --Cantidad de Recaudos Registrado y Aplicado
      select count(*)
        into v_rcdos
        from re_g_recaudos
       where cdgo_rcdo_orgn_tpo = o_cdgo_rcdo_orgn_tpo
         and id_orgen = o_id_orgen
         and cdgo_rcdo_estdo in ('RG', 'AP');
    
      --Verifica si Existen Recaudos
      if (v_rcdos > 0) then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'El documento de pago #' || p_nmro_dcmnto ||
                          ', ya se encuentra pagado.';
        return;
      end if;
    end if;
  
    o_mnsje_rspsta := 'El documento de pago es valido para recaudar.';
  
  exception
    when others then
      o_cdgo_rspsta  := 13;
      o_mnsje_rspsta := 'No fue posible validar el documento de pago.';
  end prc_vl_documento_01;

  /*
  * @Descripcion  : Validar Parametros de Recaudos
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_documento_02(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto         in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_nmro_dcmnto       in number,
                                c_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                c_id_impsto         in df_c_impuestos.id_impsto%type,
                                c_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                o_cdgo_rspsta       out number,
                                o_mnsje_rspsta      out varchar2) as
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Verifica si el Documento Corresponde al Cliente
    if ((p_cdgo_clnte <> c_cdgo_clnte) or (p_cdgo_clnte is null)) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'El documento de pago #' || p_nmro_dcmnto ||
                        ', no corresponde al cliente.';
      --Verifica si el Documento Corresponde al Tributo
    elsif ((p_id_impsto <> c_id_impsto) or (p_id_impsto is null)) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'El documento de pago #' || p_nmro_dcmnto ||
                        ', no corresponde al tributo.';
      --Verifica si el Documento Corresponde al SubTributo
    elsif ((p_id_impsto_sbmpsto <> c_id_impsto_sbmpsto) or
          (p_id_impsto_sbmpsto is null)) then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'El documento de pago #' || p_nmro_dcmnto ||
                        ', no corresponde al sub-tributo.';
    end if;
  
  end prc_vl_documento_02;

  /*
  * @Descripcion  : Validar Codigo de Barra - Recaudo Manual
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_cdgo_brra(p_cdgo_brra          in varchar2,
                             p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                             p_id_impsto          in df_c_impuestos.id_impsto%type,
                             p_id_impsto_sbmpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                             p_id_rcdo_cntrol     in re_g_recaudos.id_rcdo_cntrol%type default null,
                             o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                             o_cdgo_ean           out varchar2,
                             o_nmro_dcmnto        out number,
                             o_vlor               out number,
                             o_fcha_vncmnto       out date,
                             o_indcdor_pgo_dplcdo out varchar2,
                             o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                             o_id_orgen           out re_g_recaudos.id_orgen%type,
                             o_cdgo_rspsta        out number,
                             o_mnsje_rspsta       out varchar2) as
    v_nvel              number;
    v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_vl_cdgo_brra';
    v_cdgo_clnte        df_s_clientes.cdgo_clnte%type;
    v_id_impsto         df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_vlor_pdl          df_c_definiciones_cliente.vlor%type;
    v_vlor_pdo          df_c_definiciones_cliente.vlor%type;
    v_rcdos             number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Indicador de Pago no Duplicado
    o_indcdor_pgo_dplcdo := 'N';
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Se Verifica si el Codigo de Barra este Nulo
    if (p_cdgo_brra is null) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'El codigo de barra es requerido.';
      return;
    end if;
  
    --Valida si largo del codigo de barra es del sistema anterior o de taxation smart
    if length(p_cdgo_brra) = 60 then
      -- taxation smart
    
      --Extrae los Datos del Codigo de Barra
      declare
        null_exception exception;
      begin
        o_cdgo_ean     := substr(p_cdgo_brra, 4, 13);
        o_nmro_dcmnto  := to_number(substr(p_cdgo_brra, 20, 13));
        o_vlor         := to_number(substr(p_cdgo_brra, 36, 15));
        o_fcha_vncmnto := to_date(substr(p_cdgo_brra, 53, 8), 'YYYYMMDD');
      
        --Verifica si los Campos no son Nulos
        if (o_cdgo_ean is null or o_nmro_dcmnto is null or o_vlor is null or
           o_fcha_vncmnto is null) then
          raise null_exception;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'El codigo de barra no es valido.';
          return;
      end;
    
    else
    
      --Extrae los Datos del Codigo de Barra
      declare
        null_exception exception;
      begin
        o_cdgo_ean     := substr(p_cdgo_brra, 4, 13);
        o_nmro_dcmnto  := to_number(substr(p_cdgo_brra, 20, 16));
        o_vlor         := to_number(substr(p_cdgo_brra, 40, 14));
        o_fcha_vncmnto := to_date(substr(p_cdgo_brra, 56, 8), 'YYYYMMDD');
      
        --Verifica si los Campos no son Nulos
        if (o_cdgo_ean is null or o_nmro_dcmnto is null or o_vlor is null or
           o_fcha_vncmnto is null) then
          raise null_exception;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'El codigo de barra no es valido.';
          return;
      end;
    
    end if;
  
    --Busca la Definicion - Permitir Pago Duplicado en lote Diferente
    v_vlor_pdo := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                  p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria,
                                                                  p_cdgo_dfncion_clnte        => 'PDO');
  
    --Busca la Definicion - Permitir Pago Duplicado en el mismo lote
    v_vlor_pdl := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                  p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria,
                                                                  p_cdgo_dfncion_clnte        => 'PDL');
  
    --Valida el Documento de Recaudo
    pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => o_cdgo_ean,
                                        p_nmro_dcmnto        => o_nmro_dcmnto,
                                        p_vlor               => o_vlor,
                                        p_fcha_vncmnto       => o_fcha_vncmnto,
                                        p_indcdor_vlda_pgo   => (v_vlor_pdo in
                                                                ('N', '-1')),
                                        o_cdgo_rcdo_orgn_tpo => o_cdgo_rcdo_orgn_tpo,
                                        o_id_orgen           => o_id_orgen,
                                        o_cdgo_clnte         => v_cdgo_clnte,
                                        o_id_impsto          => v_id_impsto,
                                        o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto,
                                        o_id_sjto_impsto     => o_id_sjto_impsto,
                                        o_cdgo_rspsta        => o_cdgo_rspsta,
                                        o_mnsje_rspsta       => o_mnsje_rspsta);
  
    --Verifica si el Documento de Pago es Valido
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta := 3;
      return;
    end if;
  
    --Valida los Parametro del Recaudo
    pkg_re_recaudos.prc_vl_documento_02(p_cdgo_clnte        => p_cdgo_clnte,
                                        p_id_impsto         => p_id_impsto,
                                        p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                        p_nmro_dcmnto       => o_nmro_dcmnto,
                                        c_cdgo_clnte        => v_cdgo_clnte,
                                        c_id_impsto         => v_id_impsto,
                                        c_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                        o_cdgo_rspsta       => o_cdgo_rspsta,
                                        o_mnsje_rspsta      => o_mnsje_rspsta);
  
    --Verifica si los Parametro del Recaudos son Valido
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta := 4;
      return;
    end if;
  
    --Verifica si se puede Incluir el Recaudo en el mismo Lote
    if (v_vlor_pdl in ('N', '-1')) then
    
      --Cantidad de Recaudos
      select count(*)
        into v_rcdos
        from re_g_recaudos
       where id_rcdo_cntrol = p_id_rcdo_cntrol
         and cdgo_rcdo_orgn_tpo = o_cdgo_rcdo_orgn_tpo
         and id_orgen = o_id_orgen;
    
      --Verifica si Existen Recaudos
      if (v_rcdos > 0) then
        --Indicador de Pago Duplicado
        o_indcdor_pgo_dplcdo := 'S';
        o_cdgo_rspsta        := 5;
        o_mnsje_rspsta       := 'El documento de pago #' || o_nmro_dcmnto ||
                                ', ya se encuentra registrado en el lote.';
        return;
      end if;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'El codigo de barra es valido para recaudar.';
  
  exception
    when others then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := 'No fue posible validar el codigo de barra del documento.' ||
                        sqlerrm;
  end prc_vl_cdgo_brra;

  /*
  * @Descripcion  : Registra Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudo(p_cdgo_clnte         in re_g_recaudos_control.cdgo_clnte%type,
                           p_id_rcdo_cntrol     in re_g_recaudos.id_rcdo_cntrol%type,
                           p_id_sjto_impsto     in re_g_recaudos.id_sjto_impsto%type,
                           p_cdgo_rcdo_orgn_tpo in re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                           p_rcdo_orgn          in re_g_recaudos.rcdo_orgn%type default null,
                           p_id_orgen           in re_g_recaudos.id_orgen%type,
                           p_vlor               in re_g_recaudos.vlor%type,
                           p_obsrvcion          in re_g_recaudos.obsrvcion%type default null,
                           p_id_rcdo_cja_dtlle  in number default null,
                           p_fcha_ingrso_bnco   in re_g_recaudos.fcha_ingrso_bnco%type default null,
                           p_cdgo_frma_pgo      in re_g_recaudos.cdgo_frma_pgo%type,
                           p_cdgo_rcdo_estdo    in re_g_recaudos.cdgo_rcdo_estdo%type default 'IN',
                           o_id_rcdo            out re_g_recaudos.id_rcdo%type,
                           o_cdgo_rspsta        out number,
                           o_mnsje_rspsta       out varchar2) as
    v_nvel           number;
    v_nmro_dcmnto    number;
    v_nmbre_up       sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_recaudo';
    v_id_rcdo_cntrol re_g_recaudos_control.id_rcdo_cntrol%type;
    v_cntdad_rcdos   re_g_recaudos_control.cntdad_rcdos%type;
    v_vlor_rcdos     re_g_recaudos_control.vlor_rcdos%type;
    v_fcha_rcdo      re_g_recaudos.fcha_rcdo%type;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica que Existe el Control de Recaudo
    begin
      select id_rcdo_cntrol, fcha_cntrol
        into v_id_rcdo_cntrol, v_fcha_rcdo
        from re_g_recaudos_control
       where id_rcdo_cntrol = p_id_rcdo_cntrol;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Excepcion el recaudo control#[' ||
                          p_id_rcdo_cntrol || '], no existe en el sistema.';
        return;
    end;
  
    --Se obtiene el numero de documento o declaracion
    if p_cdgo_rcdo_orgn_tpo = 'DC' then
    
      begin
        select a.nmro_dcmnto
          into v_nmro_dcmnto
          from re_g_documentos a
         where id_dcmnto = p_id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo obtener el numero de documento';
          return;
      end;
    
    else
    
      begin
        select a.nmro_cnsctvo
          into v_nmro_dcmnto
          from gi_g_declaraciones a
         where id_dclrcion = p_id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo obtener el numero de la declaracion';
          return;
      end;
    
    end if;
  
    --Inserta el Registro de Recaudo
    insert into re_g_recaudos
      (id_rcdo_cntrol,
       id_sjto_impsto,
       cdgo_rcdo_orgn_tpo,
       id_orgen,
       fcha_rcdo,
       fcha_ingrso_bnco,
       vlor,
       obsrvcion,
       cdgo_frma_pgo,
       cdgo_rcdo_estdo,
       rcdo_orgn,
       nmro_dcmnto)
    values
      (v_id_rcdo_cntrol,
       p_id_sjto_impsto,
       p_cdgo_rcdo_orgn_tpo,
       p_id_orgen,
       v_fcha_rcdo,
       nvl(p_fcha_ingrso_bnco, v_fcha_rcdo),
       p_vlor,
       p_obsrvcion,
       p_cdgo_frma_pgo,
       p_cdgo_rcdo_estdo,
       p_rcdo_orgn,
       v_nmro_dcmnto)
    returning id_rcdo into o_id_rcdo;
  
    select count(*), nvl(sum(vlor), 0)
      into v_cntdad_rcdos, v_vlor_rcdos
      from re_g_recaudos
     where id_rcdo_cntrol = p_id_rcdo_cntrol;
  
    --Actualiza Recaudo Control
    update re_g_recaudos_control
       set cntdad_rcdos = v_cntdad_rcdos, vlor_rcdos = v_vlor_rcdos
     where id_rcdo_cntrol = p_id_rcdo_cntrol;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Se creo el recaudo, con consecutivo #' || o_id_rcdo;
  
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Excepcion no fue posible crear el registro recaudo.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 1);
  end prc_rg_recaudo;

  /*
  * @Descripcion  : Confirmar Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ac_confirmar_recaudo(p_cdgo_clnte   in re_g_recaudos_control.cdgo_clnte%type,
                                     p_id_usrio     in re_g_recaudos_control.id_usrio%type,
                                     p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ac_confirmar_recaudo';
    v_re_g_recaudos re_g_recaudos%rowtype;
    v_id_cnvnio     re_g_documentos.id_cnvnio%type;
  begin
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo
         and a.cdgo_rcdo_estdo = 'IN';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo #' || p_id_rcdo ||
                          ', no existe en el sistema o no se encuentra en estado incluido.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Indicador de Documentos
    if (v_re_g_recaudos.cdgo_rcdo_orgn_tpo = 'DC') then
    
      --Verifica si Existe el Documento de Pago
      begin
        select a.id_cnvnio
          into v_id_cnvnio
          from re_g_documentos a
         where id_dcmnto = v_re_g_recaudos.id_orgen;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                            v_re_g_recaudos.id_orgen ||
                            ', no existe en el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
      end;
    
      --Indicador de Declaracion
    elsif (v_re_g_recaudos.cdgo_rcdo_orgn_tpo = 'DL') then
    
      --Up Para Actualizar el Estado de la Declaracion - Presentada
      pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte          => p_cdgo_clnte,
                                                     p_id_dclrcion         => v_re_g_recaudos.id_orgen,
                                                     p_cdgo_dclrcion_estdo => 'PRS',
                                                     p_id_rcdo             => p_id_rcdo,
                                                     p_fcha                => v_re_g_recaudos.fcha_rcdo,
                                                     o_cdgo_rspsta         => o_cdgo_rspsta,
                                                     o_mnsje_rspsta        => o_mnsje_rspsta);
    
      --Verifica si Hubo Error
      if (not o_cdgo_rspsta in (0, 1000)) then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar el estado de la declaracion para el recaudo #[' ||
                          p_id_rcdo || '], ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    end if;
  
    --Actualiza los Datos del Recaudo
    update re_g_recaudos
       set id_cnvnio = v_id_cnvnio, cdgo_rcdo_estdo = 'RG'
     where id_rcdo = p_id_rcdo;
  
    --Actualiza el Usuario en Recaudo Control
    update re_g_recaudos_control
       set id_usrio = p_id_usrio
     where id_rcdo_cntrol = v_re_g_recaudos.id_rcdo_cntrol;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    o_mnsje_rspsta := 'Recaudo confirmado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible confirmar el recaudo #[' ||
                        p_id_rcdo || '], intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ac_confirmar_recaudo;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Proporcional
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function prc_ap_recaudo_prprcnal(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto         in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_fcha_vncmnto      in date,
                                   p_vlor_rcdo         in number,
                                   p_json_crtra        in clob,
                                   p_id_dcmnto         in number default null)
    return g_ap_rcdo
    pipelined is
    type t_crtra is record(
      vgncia                  df_s_vigencias.vgncia%type,
      prdo                    df_i_periodos.prdo%type,
      id_prdo                 df_i_periodos.id_prdo%type,
      cdgo_prdcdad            df_i_periodos.cdgo_prdcdad%type,
      id_cncpto               df_i_conceptos.id_cncpto%type,
      cdgo_cncpto             df_i_conceptos.cdgo_cncpto%type,
      id_mvmnto_fncro         gf_g_movimientos_financiero.id_mvmnto_fncro%type,
      id_impsto_acto_cncpto   df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type,
      fcha_vncmnto            gf_g_movimientos_detalle.fcha_mvmnto%type,
      id_cncpto_csdo          gf_g_movimientos_detalle.id_cncpto_csdo%type,
      gnra_intres_mra         gf_g_movimientos_detalle.gnra_intres_mra%type,
      crtra_vlor_cptal        number,
      crtra_vlor_intres       number,
      vlor_sldo_cptal         number,
      vlor_intres             number,
      vlor_dscnto_cptal       number,
      id_cncpto_dscnto_cptal  df_i_conceptos.id_cncpto%type,
      vlor_dscnto_intres      number,
      id_cncpto_dscnto_intres df_i_conceptos.id_cncpto%type,
      cdgo_mvmnto_orgn        gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type,
      id_orgen                gf_g_movimientos_financiero.id_orgen%type,
      vlor_ttal               number);
  
    type r_crtra is table of t_crtra;
    v_crtra          r_crtra;
    r_ap_rcdo        g_ap_rcdo := g_ap_rcdo();
    v_vlor_rcdo      number := p_vlor_rcdo; --Valor de Recaudo
    v_indcdor_cnvnio varchar2(3);
  
    v_indcdor_inslvncia    varchar2(1); --Insolvencia Acuerdos de Pago
    v_indcdor_clcla_intres varchar2(1); --Insolvencia Acuerdos de Pago
    v_fcha_cngla_intres    date; --Insolvencia Acuerdos de Pago
  
  begin
  
    --Insolvencia Acuerdos de Pago
    select nvl(json_value(p_json_crtra, '$.indcdor_cnvnio'), 'N'),
           nvl(json_value(p_json_crtra, '$.indcdor_inslvncia'), 'N'),
           nvl(json_value(p_json_crtra, '$.indcdor_clcla_intres'), 'S'),
           to_char(TO_TIMESTAMP_TZ(json_value(p_json_crtra,
                                              '$.fcha_cngla_intres'),
                                   'yyyy-mm-dd"T"hh24:mi:ss'),
                   'dd/mm/yyyy') --ojo
      into v_indcdor_cnvnio,
           v_indcdor_inslvncia,
           v_indcdor_clcla_intres,
           v_fcha_cngla_intres
      from dual;

--DBMS_OUTPUT.PUT_LINE('p_json_crtra convenio = ' || p_json_crtra);

    --Almacena Coleccion de Cartera
    with w_a as
     (select *
        from json_table(nvl(p_json_crtra, '[]'),
                        '$.descuentos[*]'
                        columns(id_mvmnto_fncro number path
                                '$.id_mvmnto_fncro',
                                id_impsto_acto_cncpto number path
                                '$.id_impsto_acto_cncpto',
                                id_cncpto number path '$.id_cncpto',
                                id_cncpto_rlcnal number path
                                '$.id_cncpto_rlcnal',
                                vlor_dscnto number path '$.vlor_dscnto',
                                indcdor_intres_bncrio varchar2(3) path
                                '$.indcdor_intres_bncrio',
                                vlor_intres_bncrio number path
                                '$.vlor_intres_bncrio')))
    select a.*, a.vlor_sldo_cptal + a.vlor_intres as vlor_ttal
      bulk collect
      into v_crtra
      from (select a.vgncia,
                   a.prdo,
                   a.id_prdo,
                   a.cdgo_prdcdad,
                   a.id_cncpto,
                   a.cdgo_cncpto,
                   a.id_mvmnto_fncro,
                   a.id_impsto_acto_cncpto,
                   a.fcha_vncmnto,
                   a.id_cncpto_intres_mra,
                   a.gnra_intres_mra,
                   a.vlor_sldo_cptal       as crtra_vlor_cptal,
                   a.vlor_intres           as crtra_vlor_intres
                   --Reconocimiento de los Descuento Capital
                  ,
                   (case
                     when a.vlor_sldo_cptal - nvl(b.vlor_dscnto, 0) <= 0 then
                      0
                     when a.vlor_sldo_cptal - nvl(b.vlor_dscnto, 0) > 0 and
                          v_indcdor_cnvnio = 'N' then
                     --else
                      (a.vlor_sldo_cptal - nvl(b.vlor_dscnto, 0))
                     when a.vlor_sldo_cptal - nvl(b.vlor_dscnto, 0) > 0 and
                          v_indcdor_cnvnio = 'S' then
                      a.vlor_sldo_cptal
                   end) as vlor_sldo_cptal
                   --Reconocimiento de los Descuento Interes
                  ,
                   (case
                     when a.vlor_intres - nvl(c.vlor_dscnto, 0) <= 0 then
                      0
                     when (a.vlor_intres - nvl(c.vlor_dscnto, 0) > 0 and
                          nvl(c.indcdor_intres_bncrio, 'M') = 'M' and
                          v_indcdor_cnvnio = 'N') then
                      (a.vlor_intres - nvl(c.vlor_dscnto, 0))
                     when (a.vlor_intres - nvl(c.vlor_dscnto, 0) > 0 and
                          nvl(c.indcdor_intres_bncrio, 'M') = 'M' and
                          v_indcdor_cnvnio = 'S') then
                      a.vlor_intres
                     when (a.vlor_intres - nvl(c.vlor_dscnto, 0) > 0 and
                          nvl(c.indcdor_intres_bncrio, 'M') = 'B' and
                          v_indcdor_cnvnio = 'S') then
                      c.vlor_intres_bncrio
                   end) as vlor_intres
                   --Valor de Descuento Capital
                  ,
                   (case
                     when a.vlor_sldo_cptal - nvl(b.vlor_dscnto, 0) < 0 then
                      a.vlor_sldo_cptal
                     else
                      nvl(b.vlor_dscnto, 0)
                   end) as vlor_dscnto_cptal,
                   b.id_cncpto as id_cncpto_dscnto_cptal
                   --Valor de Descuento Interes
                  ,
                   (case
                     when a.vlor_intres - nvl(c.vlor_dscnto, 0) < 0 then
                      a.vlor_intres
                     else
                      nvl(c.vlor_dscnto, 0)
                   end) as vlor_dscnto_intres,
                   c.id_cncpto as id_cncpto_dscnto_intres,
                   a.cdgo_mvmnto_orgn,
                   a.id_orgen
              from (select a.vgncia,
                           a.prdo,
                           a.id_prdo,
                           a.cdgo_prdcdad,
                           a.id_cncpto,
                           a.cdgo_cncpto,
                           a.id_mvmnto_fncro,
                           a.id_impsto_acto_cncpto,
                           a.fcha_vncmnto,
                           b.id_cncpto_intres_mra,
                           b.gnra_intres_mra,
                           a.vlor_sldo_cptal,
                           case
                             when v_indcdor_cnvnio = 'S' and
                                  v_indcdor_inslvncia = 'S' and
                                  v_indcdor_clcla_intres = 'N' then --Insolvencia Acuerdos de Pago
                              0
                             when v_indcdor_cnvnio = 'S' and
                                  v_indcdor_inslvncia = 'S' and
                                  v_indcdor_clcla_intres = 'S' and
                                  v_fcha_cngla_intres is not null then --Insolvencia Acuerdos de Pago
                              pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                p_id_impsto         => p_id_impsto,
                                                                                p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                p_vgncia            => a.vgncia,
                                                                                p_id_prdo           => a.id_prdo,
                                                                                p_id_cncpto         => a.id_cncpto,
                                                                                p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                p_indcdor_clclo     => 'CLD',
                                                                                p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                p_id_orgen          => a.id_orgen,
                                                                                p_fcha_pryccion     => v_fcha_cngla_intres,
                                                                                p_id_dcmnto         => p_id_dcmnto)
                           
                             when (b.gnra_intres_mra = 'S' and
                                  b.id_cncpto_intres_mra is not null) then
                              pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                p_id_impsto         => p_id_impsto,
                                                                                p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                p_vgncia            => a.vgncia,
                                                                                p_id_prdo           => a.id_prdo,
                                                                                p_id_cncpto         => a.id_cncpto,
                                                                                p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                p_indcdor_clclo     => 'CLD',
                                                                                p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                p_id_orgen          => a.id_orgen,
                                                                                p_fcha_pryccion     => p_fcha_vncmnto,
                                                                                p_id_dcmnto         => p_id_dcmnto)
                             else
                              0
                           end as vlor_intres,
                           a.cdgo_mvmnto_orgn,
                           a.id_orgen
                      from json_table(nvl(p_json_crtra, '[]'),
                                      '$.carteras[*]'
                                      columns(vgncia number path '$.vgncia',
                                              prdo number path '$.prdo',
                                              id_prdo number path '$.id_prdo',
                                              cdgo_prdcdad varchar2 path
                                              '$.cdgo_prdcdad',
                                              id_cncpto number path
                                              '$.id_cncpto',
                                              cdgo_cncpto varchar2 path
                                              '$.cdgo_cncpto',
                                              id_mvmnto_fncro number path
                                              '$.id_mvmnto_fncro',
                                              vlor_sldo_cptal number path
                                              '$.vlor_sldo_cptal',
                                              id_impsto_acto_cncpto number path
                                              '$.id_impsto_acto_cncpto',
                                              fcha_vncmnto date path
                                              '$.fcha_vncmnto',
                                              cdgo_mvmnto_orgn varchar2 path
                                              '$.cdgo_mvmnto_orgn',
                                              id_orgen varchar2 path
                                              '$.id_orgen')) a
                      join df_i_impuestos_acto_concepto b
                        on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
                     where a.vlor_sldo_cptal > 0) a
              left join w_a b
                on a.id_mvmnto_fncro = b.id_mvmnto_fncro
               and a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
               and a.id_cncpto = b.id_cncpto_rlcnal
              left join w_a c
                on a.id_mvmnto_fncro = c.id_mvmnto_fncro
               and a.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
               and a.id_cncpto_intres_mra = c.id_cncpto_rlcnal
             order by a.vgncia, a.prdo, a.cdgo_cncpto) a;
    declare
      v_ttal_cptal        number := 0;
      v_ttal_intres       number := 0;
      v_vlor_ttal         number := 0;
      a_ttal_cptal        number := 0;
      a_ttal_intres       number := 0;
      v_ttal              number := 0;
      v_ap_cptal          number := 0;
      v_ap_intres         number := 0;
      v_ap_rcdo           t_ap_rcdo := t_ap_rcdo();
      v_sldo_na           number := 0;
      v_index             number := 0;
      v_vlor_ttal_dcto    number := 0;
      v_vlor_ttal_dcto_in number := 0;
    begin
    
      --Sumatorias de Carteras C y I
      for i in 1 .. v_crtra.count loop
        v_ttal_cptal        := v_ttal_cptal + v_crtra(i).vlor_sldo_cptal;
        v_ttal_intres       := v_ttal_intres + v_crtra(i).vlor_intres;
        v_vlor_ttal         := v_vlor_ttal + v_crtra(i).vlor_ttal;
        v_vlor_ttal_dcto    := v_vlor_ttal_dcto + v_crtra(i).vlor_dscnto_cptal;
        v_vlor_ttal_dcto_in := v_vlor_ttal_dcto_in + v_crtra(i).vlor_dscnto_intres;
      end loop;
    
      -- insert into muerto(v_001, v_002)
      --  values('val_dcto_rcdo', v_vlor_rcdo||','||v_vlor_ttal_dcto||','||v_ttal_intres||','||v_vlor_ttal);
    
      --Determina si Existe Saldo a Favor
      if (v_vlor_rcdo > v_vlor_ttal) then
        v_ap_rcdo.cdgo_mvmnto_tpo := 'SF';
        v_ap_rcdo.vlor_sldo_fvor  := (v_vlor_rcdo - v_vlor_ttal);
        v_vlor_rcdo               := v_vlor_ttal;
        --Guarda Fila 1 en Coleccion
        r_ap_rcdo.extend;
        r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
      end if;
    
     --DBMS_OUTPUT.PUT_LINE('v_ttal_intres convenio = ' || v_ttal_intres);
     --DBMS_OUTPUT.PUT_LINE('v_vlor_ttal convenio = ' || v_vlor_ttal);
      --Aplicacion de Recaudo Sobre Totales de Cartera C y I
      a_ttal_intres := (case
                         when v_vlor_ttal <> 0 and v_indcdor_cnvnio = 'S' then
                          trunc(((v_vlor_rcdo + v_vlor_ttal_dcto +
                                v_vlor_ttal_dcto_in) * v_ttal_intres) /  v_vlor_ttal)
                         when v_vlor_ttal <> 0 and v_indcdor_cnvnio = 'N' then
                         --when v_vlor_ttal <> 0 then
                          trunc((v_vlor_rcdo * v_ttal_intres) / v_vlor_ttal)
                         else
                          0
                       end);
      a_ttal_cptal  := (v_vlor_rcdo - a_ttal_intres);
    
      if v_indcdor_cnvnio = 'S' then
        a_ttal_cptal := ((v_vlor_rcdo + v_vlor_ttal_dcto + v_vlor_ttal_dcto_in) - a_ttal_intres);
        --DBMS_OUTPUT.PUT_LINE('v_vlor_rcdo convenio = ' || v_vlor_rcdo);
        --DBMS_OUTPUT.PUT_LINE('v_vlor_ttal_dcto convenio = ' || v_vlor_ttal_dcto);
        --DBMS_OUTPUT.PUT_LINE('v_vlor_ttal_dcto_in convenio = ' || v_vlor_ttal_dcto_in);
        --DBMS_OUTPUT.PUT_LINE('a_ttal_intres convenio = ' || a_ttal_intres);
        --DBMS_OUTPUT.PUT_LINE('********** a_ttal_cptal convenio = ' || a_ttal_cptal);
      end if;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Valor Recaudo = ' || v_vlor_rcdo,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Dcto Capital = ' || v_vlor_ttal_dcto,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Dcto Interes = ' || v_vlor_ttal_dcto_in,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Total Interes = ' || v_ttal_intres,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Total Cartera = ' || v_vlor_ttal,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Proporcion a_ttal_intres = ' || a_ttal_intres,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                            6,
                            'Proporcion a_ttal_cptal = ' || a_ttal_cptal,
                            2);
    
      --Aplicacion Recaudo
      for i in 1 .. v_crtra.count loop
      
        --Inicializa el Objeto Recaudo
        v_ap_rcdo := t_ap_rcdo();
      
        --Datos a Mostrar
        v_ap_rcdo.vgncia                := v_crtra(i).vgncia;
        v_ap_rcdo.id_prdo               := v_crtra(i).id_prdo;
        v_ap_rcdo.id_mvmnto_fncro       := v_crtra(i).id_mvmnto_fncro;
        v_ap_rcdo.id_cncpto             := v_crtra(i).id_cncpto;
        v_ap_rcdo.vlor_sldo_cptal       := v_crtra(i).crtra_vlor_cptal;
        v_ap_rcdo.vlor_intres           := v_crtra(i).crtra_vlor_intres;
        v_ap_rcdo.cdgo_prdcdad          := v_crtra(i).cdgo_prdcdad;
        v_ap_rcdo.fcha_vncmnto          := v_crtra(i).fcha_vncmnto;
        v_ap_rcdo.id_impsto_acto_cncpto := v_crtra(i).id_impsto_acto_cncpto;
        v_ap_rcdo.cdgo_mvmnto_orgn      := v_crtra(i).cdgo_mvmnto_orgn;
        v_ap_rcdo.id_orgen              := v_crtra(i).id_orgen;
      
        --Aplicacion de Recaudo Sobre Cartera C y I
        v_ap_cptal := (case
                        when v_ttal_cptal <> 0 then
                         trunc((a_ttal_cptal * v_crtra(i).vlor_sldo_cptal) /
                               v_ttal_cptal)
                        else
                         0
                      end);
      
        v_ap_intres := (case
                         when v_ttal_intres <> 0 then
                          trunc((a_ttal_intres * v_crtra(i).vlor_intres) /
                                v_ttal_intres)
                         else
                          0
                       end);
      
        if v_indcdor_cnvnio = 'S' then
          v_ap_cptal  := v_ap_cptal - v_crtra(i).vlor_dscnto_cptal;
          v_ap_intres := v_ap_intres - v_crtra(i).vlor_dscnto_intres;
        end if;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                              6,
                              'v_ap_cptal(' || i || ') = ' || v_ap_cptal,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.prc_ap_rcdo_prprcnal',
                              6,
                              'v_ap_intres(' || i || ') = ' || v_ap_intres,
                              2);
      
        --Valor Total Aplicado
        v_ttal := (v_ttal + v_ap_cptal + v_ap_intres);
      
        --Determina si es el Ultimo Movimiento
        if (i = v_crtra.count) then
          --Almacena el Saldo que no se Aplico
          v_sldo_na := (v_vlor_rcdo - v_ttal);
        end if;
      
        --Reconocimiento Descuento Capital
        if (v_crtra(i).vlor_dscnto_cptal > 0) then
          v_ap_rcdo.cdgo_mvmnto_tpo  := 'DC';
          v_ap_rcdo.id_cncpto_csdo   := v_crtra(i).id_cncpto_dscnto_cptal;
          v_ap_rcdo.id_cncpto_rlcnal := v_crtra(i).id_cncpto;
          v_ap_rcdo.vlor_hber        := v_crtra(i).vlor_dscnto_cptal;
          --Guarda Fila 2 en Coleccion
          r_ap_rcdo.extend;
          r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
          --Se Inicializa en Null
          v_ap_rcdo.id_cncpto_rlcnal := null;
        end if;
      
        --Verifica si Calculo C
        if (v_ap_cptal > 0) then
          --Valor Aplicado en C
          v_ap_rcdo.cdgo_mvmnto_tpo := 'PC';
          v_ap_rcdo.id_cncpto_csdo  := v_crtra(i).id_cncpto;
          v_ap_rcdo.vlor_hber       := v_ap_cptal;
          --Guarda Fila 3 en Coleccion
          r_ap_rcdo.extend;
          r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
        end if;
      
        --Valor Causado en I
        begin
          --Datos Iniciales de la Fila de Ingreso de Interes
          --Id del Concepto de Interes
          v_ap_rcdo.id_cncpto_csdo := v_crtra(i).id_cncpto_csdo;
          --Tipo Ingreso Interes
          v_ap_rcdo.cdgo_mvmnto_tpo := 'IT';
          --Valor Inicializado
          v_ap_rcdo.vlor_hber := 0;
        
          if (v_crtra(i).vlor_dscnto_intres = 0 and v_ap_intres > 0) then
            --Ingreso Interes
            v_ap_rcdo.vlor_dbe := v_ap_intres;
            --Guarda Fila 4 en Coleccion
            r_ap_rcdo.extend;
            r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
          
            --Reconocimiento Descuento Interes
          elsif (v_crtra(i).vlor_dscnto_intres > 0) then
            --Ingreso Interes
            v_ap_rcdo.vlor_dbe := (v_ap_intres + v_crtra(i).vlor_dscnto_intres);
          
            --Guarda Fila 5 en Coleccion
            r_ap_rcdo.extend;
            r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
          
            --Descuento Interes
            v_ap_rcdo.cdgo_mvmnto_tpo  := 'DI';
            v_ap_rcdo.id_cncpto_csdo   := v_crtra(i).id_cncpto_dscnto_intres;
            v_ap_rcdo.vlor_dbe         := 0;
            v_ap_rcdo.vlor_hber        := v_crtra(i).vlor_dscnto_intres;
            v_ap_rcdo.id_cncpto_rlcnal := v_crtra(i).id_cncpto_csdo;
            --Guarda Fila 6 en Coleccion
            r_ap_rcdo.extend;
            r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
          end if;
        end;
      
        --Verifica si Calculo I
        if (v_ap_intres > 0) then
          --Valor Aplicado en I
          v_ap_rcdo.id_cncpto_rlcnal := null;
          v_ap_rcdo.id_cncpto_csdo   := v_crtra(i).id_cncpto_csdo;
          v_ap_rcdo.cdgo_mvmnto_tpo  := 'PI';
          v_ap_rcdo.vlor_dbe         := 0;
          v_ap_rcdo.vlor_hber        := v_ap_intres;
          --Guarda Fila 7 en Coleccion
          r_ap_rcdo.extend;
          r_ap_rcdo(r_ap_rcdo.count) := v_ap_rcdo;
        end if;
      end loop;
    
      --Verifica si hay Saldo por Aplicar
      while (v_sldo_na > 0 and v_index <> r_ap_rcdo.count) loop
        --Incrementa el Indice
        v_index := v_index + 1;
      
        declare
          v_dfrncia number := 0;
        begin
        
          --Pago Capital
          if (r_ap_rcdo(v_index).cdgo_mvmnto_tpo = 'PC') then
          
            --Verifica si hay Movimiento de Descuento Capital
            if (v_index > 1 and r_ap_rcdo(v_index - 1).cdgo_mvmnto_tpo = 'DC') then
              --Diferencia Entre Valor Capital y Valor Aplicado en Capital + Valor Descuento Capital
              v_dfrncia := (r_ap_rcdo(v_index).vlor_sldo_cptal -
                            (r_ap_rcdo(v_index).vlor_hber + r_ap_rcdo(v_index - 1).vlor_hber));
            else
              --Diferencia Entre Valor Capital y Valor Aplicado en Capital
              v_dfrncia := (r_ap_rcdo(v_index).vlor_sldo_cptal - r_ap_rcdo(v_index).vlor_hber);
            end if;
          
            if (v_sldo_na >= v_dfrncia) then
              --El Valor Aplicado en Capital se le Suma la Diferencia
              r_ap_rcdo(v_index).vlor_hber := (r_ap_rcdo(v_index)
                                              .vlor_hber + v_dfrncia);
              --Se Resta en el Saldo la Diferencia
              v_sldo_na := (v_sldo_na - v_dfrncia);
            elsif (v_sldo_na > 0) then
              --El Valor Aplicado en Capital se le Suma el Disponible
              r_ap_rcdo(v_index).vlor_hber := (r_ap_rcdo(v_index)
                                              .vlor_hber + v_sldo_na);
              --Reinicia el Saldo en 0
              v_sldo_na := 0;
            end if;
          end if;
        
          --Pago Interes
          if (r_ap_rcdo(v_index).cdgo_mvmnto_tpo = 'PI') then
          
            declare
              --Posicion de Movimiento de Ingreso de Interes
              v_ingrso_i number;
            begin
              --Verifica si hay Movimiento de Descuento Interes
              if (v_index > 1 and r_ap_rcdo(v_index - 1).cdgo_mvmnto_tpo = 'DI') then
                --Diferencia Entre Valor Interes y Valor Aplicado en Interes + Valor Descuento Interes
                v_dfrncia  := (r_ap_rcdo(v_index).vlor_intres -
                               (r_ap_rcdo(v_index).vlor_hber + r_ap_rcdo(v_index - 1).vlor_hber));
                v_ingrso_i := (v_index - 2);
              else
                --Diferencia Entre Valor Interes y Valor Aplicado en Interes
                v_dfrncia  := (r_ap_rcdo(v_index).vlor_intres - r_ap_rcdo(v_index).vlor_hber);
                v_ingrso_i := (v_index - 1);
              end if;
            
              if (0 >= v_dfrncia) then
                --El Valor Aplicado en Interes se le Suma la Diferencia
                r_ap_rcdo(v_index).vlor_hber := (r_ap_rcdo(v_index)
                                                .vlor_hber + v_dfrncia);
                r_ap_rcdo(v_ingrso_i).vlor_dbe := (r_ap_rcdo(v_ingrso_i)
                                                  .vlor_dbe + v_dfrncia);
                --Se Resta en el Saldo la Diferencia
                v_sldo_na := (v_sldo_na - v_dfrncia);
              elsif (v_sldo_na > 0) then
                --El Valor Aplicado en Interes se le Suma el Disponible
                r_ap_rcdo(v_index).vlor_hber := (r_ap_rcdo(v_index)
                                                .vlor_hber + v_sldo_na);
                r_ap_rcdo(v_ingrso_i).vlor_dbe := (r_ap_rcdo(v_ingrso_i)
                                                  .vlor_dbe + v_sldo_na);
                --Reinicia el Saldo en 0
                v_sldo_na := 0;
              end if;
            end;
          end if;
        end;
      end loop;
    
      --Escribe las Filas del Pipelined
      for i in 1 .. r_ap_rcdo.count loop
        pipe row(r_ap_rcdo(i));
      end loop;
    end;
  end prc_ap_recaudo_prprcnal;

  /*
  * @Descripcion  : Registra el Saldo a Favor
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_saldo_favor(p_id_usrio           in sg_g_usuarios.id_usrio%type,
                               p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                               p_id_impsto          in df_c_impuestos.id_impsto%type,
                               p_id_impsto_sbmpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                               p_id_sjto_impsto     in si_i_sujetos_impuesto.id_sjto_impsto%type,
                               p_id_rcdo            in re_g_recaudos.id_rcdo%type,
                               p_id_orgen           in gf_g_saldos_favor.id_orgen%type,
                               p_cdgo_rcdo_orgn_tpo in re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                               p_cdgo_sldo_fvor_tpo in gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type,
                               p_vlor_sldo_fvor     in gf_g_saldos_favor.vlor_sldo_fvor%type,
                               p_obsrvcion          in gf_g_saldos_favor.obsrvcion %type,
                               o_id_sldo_fvor       out gf_g_saldos_favor.id_sldo_fvor%type,
                               o_cdgo_rspsta        out number,
                               o_mnsje_rspsta       out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_saldo_favor_documento';
    v_json     clob;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Documento
    if (p_cdgo_rcdo_orgn_tpo = 'DC') then
    
      --Json de Documentos
      select nvl(json_arrayagg(json_object('vgncia' value a.vgncia,
                                           'id_prdo' value a.id_prdo)
                               returning clob),
                 '[]')
        into v_json
        from (select b.vgncia, b.id_prdo
                from re_g_documentos_detalle a
                join gf_g_movimientos_detalle b
                  on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
               where a.id_dcmnto = p_id_orgen
               group by b.id_prdo, b.vgncia) a;
    
      --Declaracion
    elsif (p_cdgo_rcdo_orgn_tpo = 'DL') then
    
      --Json de Declaracion
      select nvl(json_arrayagg(json_object('vgncia' value a.vgncia,
                                           'id_prdo' value a.id_prdo)
                               returning clob),
                 '[]')
        into v_json
        from gi_g_declaraciones a
       where a.id_dclrcion = p_id_orgen;
    
    end if;
  
    --Up Registro Saldo a Favor
    pkg_gf_saldos_favor.prc_rg_saldos_favor(p_cdgo_clnte         => p_cdgo_clnte,
                                            p_id_impsto          => p_id_impsto,
                                            p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                            p_id_sjto_impsto     => p_id_sjto_impsto,
                                            p_cdgo_sldo_fvor_tpo => p_cdgo_sldo_fvor_tpo,
                                            p_vlor_sldo_fvor     => p_vlor_sldo_fvor,
                                            p_id_orgen           => p_id_rcdo,
                                            p_id_usrio           => p_id_usrio,
                                            p_obsrvcion          => p_obsrvcion,
                                            p_json_pv            => v_json,
                                            o_id_sldo_fvor       => o_id_sldo_fvor,
                                            o_cdgo_rspsta        => o_cdgo_rspsta,
                                            o_mnsje_rspsta       => o_mnsje_rspsta);
  
    --Verifica si no hay Errores
    if (o_cdgo_rspsta <> 0) then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible registrar el saldo a favor.';
      return;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Saldo a favor registrado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible registrar el saldo a favor, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_rg_saldo_favor;

  /*
  * @Descripcion    : Aplicacion de Recaudo
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */

  procedure prc_ap_recaudo(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                           p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                           p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2) as
    v_nvel             number;
    v_nmbre_up         sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_recaudo';
    v_re_g_recaudos    re_g_recaudos%rowtype;
    v_re_g_documentos  re_g_documentos%rowtype;
    v_id_sldo_fvor     gf_g_saldos_favor.id_sldo_fvor%type;
    recaudo_encontrado exception;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo;
    
      if (v_re_g_recaudos.cdgo_rcdo_estdo = 'AP') then
        raise recaudo_encontrado;
      end if;
    
    exception
      when recaudo_encontrado then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '.1 El recaudo #' || p_id_rcdo ||
                          ', se encuentra aplicado en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo #' || p_id_rcdo ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Indicador de Documentos
    if (v_re_g_recaudos.cdgo_rcdo_orgn_tpo = 'DC') then
    
      --Verifica si Existe el Documento de Pago
      begin
        select /*+ RESULT_CACHE */
         a.*
          into v_re_g_documentos
          from re_g_documentos a
         where id_dcmnto = v_re_g_recaudos.id_orgen;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                            v_re_g_recaudos.id_orgen ||
                            ', no existe en el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
      end;
    
      o_mnsje_rspsta := ' v_re_g_documentos.cdgo_dcmnto_tpo ' ||
                        v_re_g_documentos.cdgo_dcmnto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
    
      --Indicador de Documento Normal o Masivo
      if (v_re_g_documentos.cdgo_dcmnto_tpo in ('DNO', 'DMA')) then
      
        --Up para Aplicacion de Pago de Documento Normal
        pkg_re_recaudos.prc_ap_documento_dno(p_id_usrio     => p_id_usrio,
                                             p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_rcdo      => p_id_rcdo,
                                             o_id_sldo_fvor => v_id_sldo_fvor,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3); 
          return;
        end if;
      
        --Indicador de Documento de Abono
      elsif (v_re_g_documentos.cdgo_dcmnto_tpo = 'DAB') then
      
        --Up para Aplicacion de Pago de Documento Abono
        pkg_re_recaudos.prc_ap_documento_dab(p_id_usrio     => p_id_usrio,
                                             p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_rcdo      => p_id_rcdo,
                                             o_id_sldo_fvor => v_id_sldo_fvor,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          --o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3); 
          return;
        end if;
      
        --Indicador de Documento de Convenio de Pago
      elsif (v_re_g_documentos.cdgo_dcmnto_tpo = 'DCO') then
      
        o_mnsje_rspsta := ' Entro a re_g_documentos.cdgo_dcmnto_tpo = DCO';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
      
        --Up para Aplicacion de Pago de Documento Convenio
        pkg_re_recaudos.prc_ap_documento_dco(p_id_usrio     => p_id_usrio,
                                             p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_rcdo      => p_id_rcdo,
                                             o_id_sldo_fvor => v_id_sldo_fvor,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3); 
          return;
        end if;
      else
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'El tipo de documento [' ||
                          v_re_g_documentos.cdgo_dcmnto_tpo ||
                          '], no posee operaciones.';
        return;
      end if;
    
      --Actualiza Documento como Aplicado
      update re_g_documentos
         set indcdor_pgo_aplcdo = 'S'
       where id_dcmnto = v_re_g_documentos.id_dcmnto;
    
    else
    
      --Aplicacion de Declaracion
      pkg_gi_declaraciones_utlddes.prc_ap_declaracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_id_usrio     => p_id_usrio,
                                                      p_id_dclrcion  => v_re_g_recaudos.id_orgen,
                                                      o_cdgo_rspsta  => o_cdgo_rspsta,
                                                      o_mnsje_rspsta => o_mnsje_rspsta);
    
      --Verifica si Hubo Error
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3); 
        return;
      end if;
    
      --Indica si se Aplica el Recaudo de Declaracion
      if (v_re_g_recaudos.vlor > 0) then
      
        --Up para Aplicacion de Pago Declaracion
        pkg_re_recaudos.prc_ap_declaracion(p_id_usrio     => p_id_usrio,
                                           p_cdgo_clnte   => p_cdgo_clnte,
                                           p_id_rcdo      => p_id_rcdo,
                                           o_id_sldo_fvor => v_id_sldo_fvor,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3); 
          return;
        end if;
      end if;
    end if;
  
    --Actualiza el Consolidado de Cartera Despues de Aplicar Recaudo
    begin
      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                p_id_sjto_impsto => v_re_g_recaudos.id_sjto_impsto);
    exception
      when others then
        o_cdgo_rspsta := 9;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || '.' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        o_mnsje_rspsta := 'No fue posible actualizar el consolidado del sujeto impuesto.';
        return;
    end;
  
    --Actualiza los Datos del Recaudo Aplicado
    update re_g_recaudos a
       set cdgo_rcdo_estdo = 'AP',
           fcha_apliccion  = systimestamp,
           mnsje_rspsta    = nvl(o_mnsje_rspsta, 'Aplicado'),
           id_usrio_aplco  = p_id_usrio,
           id_sldo_fvor    = v_id_sldo_fvor
     where id_rcdo = p_id_rcdo
       and cdgo_rcdo_estdo = 'RG';
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Recaudo #' || p_id_rcdo || ' aplicado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo #[' ||
                        p_id_rcdo || '], intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_recaudo;

  /*
  * @Descripcion    : Aplicar Recaudos Masivo
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */

  procedure prc_ap_recaudos_masivo(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                   p_json         in clob,
                                   o_cdgo_rspsta  out number,
                                   o_mnsje_rspsta out varchar2) as
    v_nvel         number;
    v_nmbre_up     sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_recaudos_masivo';
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Cursor de Recaudos para Aplicar Recaudos
    for c_rcdos in (select a.id_rcdo, c.cdgo_clnte
                      from json_table(p_json,
                                      '$[*]'
                                      columns(id_rcdo number path '$.ID_RCDO')) a
                      join re_g_recaudos b
                        on a.id_rcdo = b.id_rcdo
                      join re_g_recaudos_control c
                        on b.id_rcdo_cntrol = c.id_rcdo_cntrol
                     where b.cdgo_rcdo_estdo = 'RG') loop
    
      --Up para Aplicar Recaudo
      pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => p_id_usrio,
                                     p_cdgo_clnte   => c_rcdos.cdgo_clnte,
                                     p_id_rcdo      => c_rcdos.id_rcdo,
                                     o_cdgo_rspsta  => v_cdgo_rspsta,
                                     o_mnsje_rspsta => v_mnsje_rspsta);
    
      --Verifica si no hay Errores
      if (v_cdgo_rspsta <> 0) then
        rollback;
        --Actualiza la Respuesta del Aplicador
        update re_g_recaudos a
           set mnsje_rspsta = v_mnsje_rspsta
         where id_rcdo = c_rcdos.id_rcdo
           and cdgo_rcdo_estdo = 'RG';
      end if;
      --Salva los Cambios de Recaudo Aplicados
      commit;
    end loop;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Proceso terminado con exito.';
  
  exception
    when no_data_found then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar los recaudos, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_recaudos_masivo;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Normal
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dno(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
    v_nvel                  number;
    v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_documento_dno';
    v_re_g_recaudos         re_g_recaudos%rowtype;
    v_re_g_documentos       re_g_documentos%rowtype;
    v_indcdor_nrmlzar_crtra df_c_impuestos.indcdor_nrmlzar_crtra%type;
    v_cdgo_sldo_fvor_tpo    gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type;
    v_json_crtra            clob;
    v_json_dscnto           clob;
    v_json_object           json_object_t;
    v_json                  clob;
    v_vlor_aplcdo           number := 0;
    v_vlor_sldo_cptal       number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo
         and a.cdgo_rcdo_estdo = 'RG'
         and a.cdgo_rcdo_orgn_tpo = 'DC';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo #' || p_id_rcdo ||
                          ' con origen [DC], no se encuentra en estado registrado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Verifica si Existe el Documento de Pago
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_documentos
        from re_g_documentos a
       where id_dcmnto = v_re_g_recaudos.id_orgen
         and cdgo_dcmnto_tpo in ('DNO', 'DMA');
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          v_re_g_recaudos.id_orgen ||
                          ', no existe en el sistema o no se encuentra con tipo [DNO] o [DMA].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Indicador de Normaliza Cartera
    begin
      select a.indcdor_nrmlzar_crtra
        into v_indcdor_nrmlzar_crtra
        from df_c_impuestos a
       where a.id_impsto = v_re_g_documentos.id_impsto;
    end;
  
    --Trunca las Fechas de Vencimientos
    v_re_g_recaudos.fcha_rcdo      := trunc(v_re_g_recaudos.fcha_rcdo);
    v_re_g_documentos.fcha_vncmnto := trunc(v_re_g_documentos.fcha_vncmnto);
  
    --Determina si el Recaudo Aplica como Abono
    if (v_re_g_recaudos.fcha_rcdo > v_re_g_documentos.fcha_vncmnto) then
      --Up Aplicacion de Recaudo de Abono
      pkg_re_recaudos.prc_ap_documento_dab(p_id_usrio     => p_id_usrio,
                                           p_cdgo_clnte   => p_cdgo_clnte,
                                           p_id_rcdo      => p_id_rcdo,
                                           p_mnsje_rspsta => 'Se aplica recaudo como abono de documento normal, ya que la fecha del recaudo ' ||
                                                             to_char(v_re_g_recaudos.fcha_rcdo,
                                                                     'DD/MM/YYYY') ||
                                                             ' es mayor que la fecha de vencimiento ' ||
                                                             to_char(v_re_g_documentos.fcha_vncmnto,
                                                                     'DD/MM/YYYY') ||
                                                             ' del documento.',
                                           o_id_sldo_fvor => o_id_sldo_fvor,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
      return;
    end if;
  
    --Json de Cartera del Documento
    select json_object('carteras' value
                       json_arrayagg(json_object('vgncia' value a.vgncia,
                                                 'prdo' value a.prdo,
                                                 'id_prdo' value a.id_prdo,
                                                 'cdgo_prdcdad' value
                                                 a.cdgo_prdcdad,
                                                 'id_cncpto' value
                                                 a.id_cncpto,
                                                 'cdgo_cncpto' value
                                                 a.cdgo_cncpto,
                                                 'id_mvmnto_fncro' value
                                                 a.id_mvmnto_fncro,
                                                 'vlor_sldo_cptal' value
                                                 a.vlor_sldo_cptal,
                                                 'id_impsto_acto_cncpto'
                                                 value
                                                 a.id_impsto_acto_cncpto,
                                                 'fcha_vncmnto' value
                                                 a.fcha_vncmnto,
                                                 'cdgo_mvmnto_orgn' value
                                                 a.cdgo_mvmnto_orgn,
                                                 'id_orgen' value a.id_orgen)
                                     returning clob) absent on null
                       returning clob) as json,
           nvl(sum(a.vlor_sldo_cptal), 0)
      into v_json_crtra, v_vlor_sldo_cptal
      from v_gf_g_cartera_x_concepto a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = v_re_g_documentos.id_impsto
       and a.id_impsto_sbmpsto = v_re_g_documentos.id_impsto_sbmpsto
       and a.id_sjto_impsto = v_re_g_documentos.id_sjto_impsto
       and a.id_mvmnto_fncro in
           (select c.id_mvmnto_fncro
              from re_g_documentos_detalle b
              join gf_g_movimientos_detalle c
                on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle
             where b.id_dcmnto = v_re_g_documentos.id_dcmnto
             group by c.id_mvmnto_fncro)
       and a.vlor_sldo_cptal > 0;
  
    if (v_vlor_sldo_cptal > 0 and v_json_crtra = '{}') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'No se pudo obtener la cartera a la que se le va aplicar el recaudo. Intentelo mas tarde';
      return;
    end if;
  
    o_mnsje_rspsta := 'v_re_g_documentos.indcdor_cnvnio  : ' ||
                      v_re_g_documentos.indcdor_cnvnio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 3);
  
    --Json de Descuentos del Documento
    select json_object('descuentos' value
                       json_arrayagg(json_object('id_mvmnto_fncro' value
                                                 a.id_mvmnto_fncro,
                                                 'id_impsto_acto_cncpto'
                                                 value
                                                 a.id_impsto_acto_cncpto,
                                                 'id_cncpto' value
                                                 a.id_cncpto,
                                                 'id_cncpto_rlcnal' value
                                                 a.id_cncpto_rlcnal,
                                                 'vlor_dscnto' value
                                                 a.vlor_dscnto,
                                                 'indcdor_intres_bncrio'
                                                 value
                                                 a.indcdor_intres_bncrio,
                                                 'vlor_intres_bncrio' value
                                                 a.vlor_intres_bncrio)
                                     returning clob) absent on null
                       returning clob) as json
      into v_json_dscnto
      from (select b.id_mvmnto_fncro,
                   b.id_impsto_acto_cncpto,
                   max(a.id_cncpto) as id_cncpto,
                   a.id_cncpto_rlcnal,
                   sum(a.vlor_hber) as vlor_dscnto,
                   case
                     when sum(a.intres_bncrio) > 0 then
                      'B'
                     else
                      'M'
                   end as indcdor_intres_bncrio,
                   sum(a.intres_bncrio) as vlor_intres_bncrio
              from re_g_documentos_detalle a
              join gf_g_movimientos_detalle b
                on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
             where a.vlor_hber > 0
               and a.id_dcmnto = v_re_g_documentos.id_dcmnto
             group by b.id_mvmnto_fncro,
                      b.id_impsto_acto_cncpto,
                      a.id_cncpto_rlcnal) a;
  
    --Asigna el Json al Objeto
    v_json_object := json_object_t(v_json_crtra);
    --Merge de Json de Cartera Documento y Descuentos
    v_json_object.mergepatch(json_object_t(v_json_dscnto));
    --Json de Aplicador
    v_json := v_json_object.to_clob();
  
    --Se guarda una foto de como se encontraba la cartera antes de aplicar el recaudo
    begin
      insert into re_g_recaudos_cartera
        (id_rcdo, json_crtra)
      values
        (p_id_rcdo, v_json);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'No se pudo guardar la foto de la cartera';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
    /* insert into muerto3
      (N_001, N_002, V_001, T_001)
    values
      (11, p_id_rcdo, 're_g_recaudos_cartera', SYSTIMESTAMP);*/
  
    --Cursor de Cartera Aplicada
    for c_crtra in (select a.*
                      from table(pkg_re_recaudos.prc_ap_recaudo_prprcnal(p_cdgo_clnte        => p_cdgo_clnte,
                                                                         p_id_impsto         => v_re_g_documentos.id_impsto,
                                                                         p_id_impsto_sbmpsto => v_re_g_documentos.id_impsto_sbmpsto,
                                                                         p_fcha_vncmnto      => v_re_g_documentos.fcha_vncmnto,
                                                                         p_vlor_rcdo         => v_re_g_recaudos.vlor,
                                                                         p_json_crtra        => v_json,
                                                                         p_id_dcmnto         => v_re_g_recaudos.id_orgen)) a) loop
    
      --Indica si la Cartera se Normaliza
      if (v_indcdor_nrmlzar_crtra = 'S') then
        --Actualiza el Movimiento Financiero
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where id_mvmnto_fncro = c_crtra.id_mvmnto_fncro
           and cdgo_mvnt_fncro_estdo = 'AN';
      end if;
    
      declare
        v_indcdor_mvmnto_blqdo gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type;
        v_cdgo_trza_orgn       gf_g_movimientos_traza.cdgo_trza_orgn%type;
        v_id_orgen             gf_g_movimientos_traza.id_orgen%type;
        v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
      begin
      
        --Saldo a Favor, Pago Capital y Pago Interes
        if (c_crtra.cdgo_mvmnto_tpo in ('SF', 'PC', 'PI')) then
          v_vlor_aplcdo := v_vlor_aplcdo + c_crtra.vlor_sldo_fvor +
                           c_crtra.vlor_hber;
        end if;
      
        --Indicador de Saldo a Favor
        if (c_crtra.cdgo_mvmnto_tpo = 'SF') then
        
          --Pago en Exceso
          v_cdgo_sldo_fvor_tpo := 'PEE';
          if (v_re_g_documentos.indcdor_pgo_aplcdo = 'S') then
            --Pago Doble
            v_cdgo_sldo_fvor_tpo := 'SPD';
          end if;
        
          --Up Registro Saldo a Favor
          pkg_re_recaudos.prc_rg_saldo_favor(p_id_usrio           => p_id_usrio,
                                             p_cdgo_clnte         => p_cdgo_clnte,
                                             p_id_impsto          => v_re_g_documentos.id_impsto,
                                             p_id_impsto_sbmpsto  => v_re_g_documentos.id_impsto_sbmpsto,
                                             p_id_sjto_impsto     => v_re_g_documentos.id_sjto_impsto,
                                             p_id_rcdo            => v_re_g_recaudos.id_rcdo,
                                             p_id_orgen           => v_re_g_recaudos.id_orgen,
                                             p_cdgo_rcdo_orgn_tpo => v_re_g_recaudos.cdgo_rcdo_orgn_tpo,
                                             p_cdgo_sldo_fvor_tpo => v_cdgo_sldo_fvor_tpo,
                                             p_vlor_sldo_fvor     => c_crtra.vlor_sldo_fvor,
                                             p_obsrvcion          => 'Saldo a favor, documento #' ||
                                                                     v_re_g_documentos.nmro_dcmnto ||
                                                                     ' por valor de ' ||
                                                                     to_char(c_crtra.vlor_sldo_fvor,
                                                                             'FM$999G999G999G999G999G999G990'),
                                             o_id_sldo_fvor       => o_id_sldo_fvor,
                                             o_cdgo_rspsta        => o_cdgo_rspsta,
                                             o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
          continue;
        end if;
      
        --Up que Consulta si la Cartera esta Bloqueada
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_sjto_impsto       => v_re_g_documentos.id_sjto_impsto,
                                                                  p_vgncia               => c_crtra.vgncia,
                                                                  p_id_prdo              => c_crtra.id_prdo,
                                                                  p_id_orgen             => c_crtra.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta := 6;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          o_mnsje_rspsta := 'No fue posible consultar si la cartera del sujeto impuesto, se encuentra bloqueda. p_id_prdo:' ||
                            c_crtra.id_prdo || ' p_id_orgen:' ||
                            c_crtra.id_orgen;
          return;
        end if;
      
        --Verifica si la Cartera se Encuentra Bloqueada
        if (v_indcdor_mvmnto_blqdo = 'S') then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el sujeto impuesto posee la vigencia ' ||
                            c_crtra.vgncia || ' bloqueada,' ||
                            lower(v_obsrvcion_blquo) || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      
        --Inserta los Movimientos Financiero
        begin
          insert into gf_g_movimientos_detalle
            (id_mvmnto_dtlle,
             id_mvmnto_fncro,
             cdgo_mvmnto_orgn,
             id_orgen,
             cdgo_mvmnto_tpo,
             vgncia,
             id_prdo,
             cdgo_prdcdad,
             fcha_mvmnto,
             id_cncpto,
             id_cncpto_csdo,
             vlor_dbe,
             vlor_hber,
             actvo,
             gnra_intres_mra,
             fcha_vncmnto,
             id_impsto_acto_cncpto)
          values
            (sq_gf_g_movimientos_detalle.nextval,
             c_crtra.id_mvmnto_fncro,
             g_cdgo_mvmnto_orgn,
             p_id_rcdo,
             c_crtra.cdgo_mvmnto_tpo,
             c_crtra.vgncia,
             c_crtra.id_prdo,
             c_crtra.cdgo_prdcdad,
             systimestamp,
             c_crtra.id_cncpto,
             c_crtra.id_cncpto_csdo,
             c_crtra.vlor_dbe,
             c_crtra.vlor_hber,
             'S',
             c_crtra.gnra_intres_mra,
             c_crtra.fcha_vncmnto,
             c_crtra.id_impsto_acto_cncpto);
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el movimiento financiero para el documento normal.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      end;
    end loop;
    --insert into muerto3(N_001,V_001,T_001) values(22,'Inserta mov. detalle recaudo: '||p_id_rcdo,SYSTIMESTAMP);
    /* insert into muerto3
      (N_001, N_002, V_001, T_001)
    values
      (22, p_id_rcdo, 'mov. detalle recaudo', SYSTIMESTAMP);*/
  
    --Verifica el Valor del Recaudo contra El Valor Aplicado
    if (v_re_g_recaudos.vlor <> v_vlor_aplcdo) then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo, ya que el valor aplicado ' ||
                        to_char(v_vlor_aplcdo,
                                'FM$999G999G999G999G999G999G990') ||
                        ' no corresponde al del recaudo ' ||
                        to_char(v_re_g_recaudos.vlor,
                                'FM$999G999G999G999G999G999G990') || '.';
      return;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Documento normal aplicado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo #[' ||
                        p_id_rcdo ||
                        '] de documento normal, intentelo mas tarde.' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_documento_dno;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Abono
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dab(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 p_mnsje_rspsta in varchar2 default null,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
    v_nvel                  number;
    v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_documento_dab';
    v_re_g_recaudos         re_g_recaudos%rowtype;
    v_re_g_documentos       re_g_documentos%rowtype;
    v_indcdor_nrmlzar_crtra df_c_impuestos.indcdor_nrmlzar_crtra%type;
    v_cdgo_sldo_fvor_tpo    gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type;
    v_json_crtra            clob;
    v_json                  clob;
    v_json_dscnto           clob;
    v_json_object           json_object_t;
    v_fcha_vncmnto          timestamp;
    v_vlor_aplcdo           number := 0;
    v_vlor_sldo_cptal       number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo
         and a.cdgo_rcdo_estdo = 'RG'
         and a.cdgo_rcdo_orgn_tpo = 'DC';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo #' || p_id_rcdo ||
                          ' con origen [DC], no se encuentra en estado registrado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Verifica si Existe el Documento de Pago
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_documentos
        from re_g_documentos a
       where id_dcmnto = v_re_g_recaudos.id_orgen;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          v_re_g_recaudos.id_orgen ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Indicador de Normaliza Cartera
    begin
      select a.indcdor_nrmlzar_crtra
        into v_indcdor_nrmlzar_crtra
        from df_c_impuestos a
       where a.id_impsto = v_re_g_documentos.id_impsto;
    end;
  
    --Trunca las Fechas de Vencimientos
    v_re_g_recaudos.fcha_rcdo      := trunc(v_re_g_recaudos.fcha_rcdo);
    v_re_g_documentos.fcha_vncmnto := trunc(v_re_g_documentos.fcha_vncmnto);
  
    --Determina la Fecha de Vencimiento
    if (v_re_g_recaudos.fcha_rcdo > v_re_g_documentos.fcha_vncmnto) then
      v_fcha_vncmnto := v_re_g_recaudos.fcha_rcdo;
    else
      v_fcha_vncmnto := v_re_g_documentos.fcha_vncmnto;
    end if;
  
    --Json de Cartera del Documento
    select json_object('carteras' value
                       json_arrayagg(json_object('vgncia' value a.vgncia,
                                                 'prdo' value a.prdo,
                                                 'id_prdo' value a.id_prdo,
                                                 'cdgo_prdcdad' value
                                                 a.cdgo_prdcdad,
                                                 'id_cncpto' value
                                                 a.id_cncpto,
                                                 'cdgo_cncpto' value
                                                 a.cdgo_cncpto,
                                                 'id_mvmnto_fncro' value
                                                 a.id_mvmnto_fncro,
                                                 'vlor_sldo_cptal' value
                                                 a.vlor_sldo_cptal,
                                                 'id_impsto_acto_cncpto'
                                                 value
                                                 a.id_impsto_acto_cncpto,
                                                 'fcha_vncmnto' value
                                                 a.fcha_vncmnto,
                                                 'cdgo_mvmnto_orgn' value
                                                 a.cdgo_mvmnto_orgn,
                                                 'id_orgen' value a.id_orgen)
                                     returning clob),
                       'indcdor_cnvnio' value
                       v_re_g_documentos.indcdor_cnvnio, --insolvencia Acuerdos de Pago
                       'indcdor_inslvncia' value
                       v_re_g_documentos.indcdor_inslvncia, --insolvencia Acuerdos de Pago
                       'indcdor_clcla_intres' value
                       v_re_g_documentos.indcdor_clcla_intres, --insolvencia Acuerdos de Pago
                       'fcha_cngla_intres' value
                       v_re_g_documentos.fcha_cngla_intres --insolvencia Acuerdos de Pago
                       absent on null returning clob) as json,
           nvl(sum(a.vlor_sldo_cptal), 0)
      into v_json_crtra, v_vlor_sldo_cptal
      from v_gf_g_cartera_x_concepto a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = v_re_g_documentos.id_impsto
       and a.id_impsto_sbmpsto = v_re_g_documentos.id_impsto_sbmpsto
       and a.id_sjto_impsto = v_re_g_documentos.id_sjto_impsto
       and a.id_mvmnto_fncro in
           (select c.id_mvmnto_fncro
              from re_g_documentos_detalle b
              join gf_g_movimientos_detalle c
                on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle
             where b.id_dcmnto = v_re_g_documentos.id_dcmnto
             group by c.id_mvmnto_fncro)
       and a.vlor_sldo_cptal > 0;
  
    if v_re_g_documentos.indcdor_cnvnio = 'S' then
      select json_object('descuentos' value
                         json_arrayagg(json_object('id_mvmnto_fncro' value
                                                   a.id_mvmnto_fncro,
                                                   'id_impsto_acto_cncpto'
                                                   value
                                                   a.id_impsto_acto_cncpto,
                                                   'id_cncpto' value
                                                   a.id_cncpto,
                                                   'id_cncpto_rlcnal' value
                                                   a.id_cncpto_rlcnal,
                                                   'vlor_dscnto' value
                                                   a.vlor_dscnto,
                                                   'indcdor_intres_bncrio'
                                                   value
                                                   a.indcdor_intres_bncrio,
                                                   'vlor_intres_bncrio'
                                                   value
                                                   a.vlor_intres_bncrio)
                                       returning clob) absent on null
                         returning clob) as json
        into v_json_dscnto
        from (select b.id_mvmnto_fncro,
                     b.id_impsto_acto_cncpto,
                     max(a.id_cncpto) as id_cncpto,
                     a.id_cncpto_rlcnal,
                     sum(a.vlor_hber) as vlor_dscnto,
                     -- sum(nvl((a.prcntje_dscnto * c.vlor_dbe),0))  vlor_dscnto,    -- Acuerdos de Pago 09/02/2022
                     case
                       when sum(a.intres_bncrio) > 0 then
                        'B'
                       else
                        'M'
                     end as indcdor_intres_bncrio,
                     sum(a.intres_bncrio) as vlor_intres_bncrio
                from re_g_documentos_detalle a
                join gf_g_movimientos_detalle b
                  on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                left join re_g_documentos_detalle c
                  on a.id_dcmnto = c.id_dcmnto
                 and a.id_cncpto_rlcnal = c.id_cncpto
                 and c.id_mvmnto_dtlle = a.id_mvmnto_dtlle  --- 8/05/2023
               where a.vlor_hber > 0
                 and a.id_dcmnto = v_re_g_documentos.id_dcmnto
               group by b.id_mvmnto_fncro,
                        b.id_impsto_acto_cncpto,
                        a.id_cncpto_rlcnal) a;
    else
      v_json_dscnto := null;
    end if;
  
    if (v_vlor_sldo_cptal > 0 and v_json_crtra = '{}') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'No se pudo obtener la cartera a la que se le va aplicar el recaudo. Intentelo mas tarde';
      return;
    end if;
  
    --Asigna el Json al Objeto
    --v_json_object := json_object_t(v_json_crtra);
    --Json de Aplicador
    --v_json := v_json_object.to_clob();
  
    --Asigna el Json al Objeto
    v_json_object := json_object_t(v_json_crtra);
  
    if v_json_dscnto is not null then
      --Merge de Json de Cartera Documento y Descuentos
      v_json_object.mergepatch(json_object_t(v_json_dscnto));
    end if;
  
    --Json de Aplicador
    v_json := v_json_object.to_clob();
    
    --DBMS_OUTPUT.PUT_LINE('v_json = ' || v_json);
  
    --Se guarda una foto de como se encontraba la cartera antes de aplicar el recaudo
    begin
      insert into re_g_recaudos_cartera
        (id_rcdo, json_crtra)
      values
        (p_id_rcdo, v_json);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'No se pudo guardar la foto de la cartera';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Nota: En la Aplicacion de Abono no se Reconocen los Descuentos
    --Cursor de Cartera Aplicada
    for c_crtra in (select a.*
                      from table(pkg_re_recaudos.prc_ap_recaudo_prprcnal(p_cdgo_clnte        => p_cdgo_clnte,
                                                                         p_id_impsto         => v_re_g_documentos.id_impsto,
                                                                         p_id_impsto_sbmpsto => v_re_g_documentos.id_impsto_sbmpsto,
                                                                         p_fcha_vncmnto      => v_fcha_vncmnto,
                                                                         p_vlor_rcdo         => v_re_g_recaudos.vlor,
                                                                         p_json_crtra        => v_json, --v_json_crtra,
                                                                         p_id_dcmnto         => v_re_g_recaudos.id_orgen)) a) loop
    
      --Indica si la Cartera se Normaliza
      if (v_indcdor_nrmlzar_crtra = 'S') then
        --Actualiza el Movimiento Financiero
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where id_mvmnto_fncro = c_crtra.id_mvmnto_fncro
           and cdgo_mvnt_fncro_estdo = 'AN';
      end if;
    
      declare
        v_indcdor_mvmnto_blqdo gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type;
        v_cdgo_trza_orgn       gf_g_movimientos_traza.cdgo_trza_orgn%type;
        v_id_orgen             gf_g_movimientos_traza.id_orgen%type;
        v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
      begin
      
        --Saldo a Favor, Pago Capital y Pago Interes
        if (c_crtra.cdgo_mvmnto_tpo in ('SF', 'PC', 'PI')) then
          v_vlor_aplcdo := v_vlor_aplcdo + c_crtra.vlor_sldo_fvor + c_crtra.vlor_hber;
      
        --DBMS_OUTPUT.PUT_LINE('c_crtra.id_cncpto = ' || c_crtra.id_cncpto || ' v_vlor_aplcdo = ' || v_vlor_aplcdo); 
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => ' v_vlor_aplcdo : '|| v_vlor_aplcdo ,
                                p_nvel_txto  => 3);          
        end if;
      
        --Indicador de Saldo a Favor
        if (c_crtra.cdgo_mvmnto_tpo = 'SF') then
        
          --Pago en Exceso
          v_cdgo_sldo_fvor_tpo := 'PEE';
          if (v_re_g_documentos.indcdor_pgo_aplcdo = 'S') then
            --Pago Doble
            v_cdgo_sldo_fvor_tpo := 'SPD';
          end if;
        
          --Up Registro Saldo a Favor
          pkg_re_recaudos.prc_rg_saldo_favor(p_id_usrio           => p_id_usrio,
                                             p_cdgo_clnte         => p_cdgo_clnte,
                                             p_id_impsto          => v_re_g_documentos.id_impsto,
                                             p_id_impsto_sbmpsto  => v_re_g_documentos.id_impsto_sbmpsto,
                                             p_id_sjto_impsto     => v_re_g_documentos.id_sjto_impsto,
                                             p_id_rcdo            => v_re_g_recaudos.id_rcdo,
                                             p_id_orgen           => v_re_g_recaudos.id_orgen,
                                             p_cdgo_rcdo_orgn_tpo => v_re_g_recaudos.cdgo_rcdo_orgn_tpo,
                                             p_cdgo_sldo_fvor_tpo => v_cdgo_sldo_fvor_tpo,
                                             p_vlor_sldo_fvor     => c_crtra.vlor_sldo_fvor,
                                             p_obsrvcion          => 'Saldo a favor, documento #' ||
                                                                     v_re_g_documentos.nmro_dcmnto ||
                                                                     ' por valor de ' ||
                                                                     to_char(c_crtra.vlor_sldo_fvor,
                                                                             'FM$999G999G999G999G999G999G990'),
                                             o_id_sldo_fvor       => o_id_sldo_fvor,
                                             o_cdgo_rspsta        => o_cdgo_rspsta,
                                             o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
          continue;
        end if;
      
        --Up que Consulta si la Cartera esta Bloqueada
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_sjto_impsto       => v_re_g_documentos.id_sjto_impsto,
                                                                  p_vgncia               => c_crtra.vgncia,
                                                                  p_id_prdo              => c_crtra.id_prdo,
                                                                  p_id_orgen             => c_crtra.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta := 6;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          o_mnsje_rspsta := 'No fue posible consultar si la cartera del sujeto impuesto se encuentra bloqueda.';
          return;
        end if;
      
        --Verifica si la Cartera se Encuentra Bloqueada
        if (v_indcdor_mvmnto_blqdo = 'S') then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el sujeto impuesto posee la vigencia ' ||
                            c_crtra.vgncia || ' bloqueada,' ||
                            lower(v_obsrvcion_blquo) || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      
        --Inserta los Movimientos Financiero
        begin
          insert into gf_g_movimientos_detalle
            (id_mvmnto_dtlle,
             id_mvmnto_fncro,
             cdgo_mvmnto_orgn,
             id_orgen,
             cdgo_mvmnto_tpo,
             vgncia,
             id_prdo,
             cdgo_prdcdad,
             fcha_mvmnto,
             id_cncpto,
             id_cncpto_csdo,
             vlor_dbe,
             vlor_hber,
             actvo,
             gnra_intres_mra,
             fcha_vncmnto,
             id_impsto_acto_cncpto)
          values
            (sq_gf_g_movimientos_detalle.nextval,
             c_crtra.id_mvmnto_fncro,
             g_cdgo_mvmnto_orgn,
             p_id_rcdo,
             c_crtra.cdgo_mvmnto_tpo,
             c_crtra.vgncia,
             c_crtra.id_prdo,
             c_crtra.cdgo_prdcdad,
             systimestamp,
             c_crtra.id_cncpto,
             c_crtra.id_cncpto_csdo,
             c_crtra.vlor_dbe,
             c_crtra.vlor_hber,
             'S',
             c_crtra.gnra_intres_mra,
             c_crtra.fcha_vncmnto,
             c_crtra.id_impsto_acto_cncpto);
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el movimiento financiero para el documento de abono.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      end;
    end loop;
  
    --Verifica el Valor del Recaudo contra El Valor Aplicado
    if (v_re_g_recaudos.vlor <> v_vlor_aplcdo) then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el valor aplicado ' ||
                        to_char(v_vlor_aplcdo,
                                'FM$999G999G999G999G999G999G990') ||
                        ' no corresponde al del recaudo de abono ' ||
                        to_char(v_re_g_recaudos.vlor,
                                'FM$999G999G999G999G999G999G990') || '.';
      return;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := nvl(p_mnsje_rspsta,
                          'Documento abono aplicado con exito.');
  
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo #[' ||
                        p_id_rcdo ||
                        '] para el documento de abono, intentelo mas tarde.' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_documento_dab;

  /*
  * @Descripcion  : Distribucion Aplicacion de Recaudo - Documento de Convenio
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_ap_documento_dco(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto         in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_id_sjto_impsto    in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                p_id_dcmnto         in re_g_documentos.id_dcmnto%type,
                                p_vlor_rcdo         in number)
    return g_ap_rcdo
    pipelined is
    r_ap_rcdo          t_ap_rcdo := t_ap_rcdo();
    v_ap_rcdo_c        g_ap_rcdo := g_ap_rcdo();
    v_ap_rcdo_i        g_ap_rcdo := g_ap_rcdo();
    v_sldo_crtra       number := 0;
    v_vlor_aplcdo      number := 0;
    v_sldo_x_aplcr     number := 0;
    v_vlor_dscnto      number := 0;
    vlor_ttal_dscnto_c number := 0;
  begin
  
    --Cursor de Cartera del Documento
    for c_crtera in (with w_dscntos_cptal as
                        (select x.id_cncpto_rlcnal, x.id_prdo, x.vlor_dscnto
                          from (select b.id_mvmnto_fncro,
                                       b.id_impsto_acto_cncpto,
                                       b.id_prdo,
                                       max(a.id_cncpto) as id_cncpto,
                                       a.id_cncpto_rlcnal,
                                       sum(a.vlor_hber) as vlor_dscnto,
                                       case
                                         when sum(a.intres_bncrio) > 0 then
                                          'B'
                                         else
                                          'M'
                                       end as indcdor_intres_bncrio,
                                       sum(a.intres_bncrio) as vlor_intres_bncrio
                                  from re_g_documentos_detalle a
                                  join gf_g_movimientos_detalle b
                                    on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                                   left join V_re_g_documentos_detalle c
                                    on a.id_dcmnto = c.id_dcmnto
                                   and a.id_cncpto_rlcnal = c.id_cncpto
                                   and c.CTGRIA_CNCPTO_DSCNTO = 'C' ----ojooooo preguntar
                                   
                                     and c.id_mvmnto_dtlle = b.id_mvmnto_dtlle  
                                     and a.ID_DCMNTO_DTLLE = c.ID_DCMNTO_DTLLE 
                                   
                                   and c.id_prdo = b.id_prdo 
                                 where a.vlor_hber > 0
                                   and a.id_dcmnto = p_id_dcmnto
                                -- and a.id_cncpto_rlcnal = c_crtera.id_cncpto
                                 group by b.id_mvmnto_fncro,
                                          b.id_impsto_acto_cncpto,
                                          b.id_prdo,
                                          a.id_cncpto_rlcnal) x)
                       select a.vgncia,
                              a.prdo,
                              a.id_prdo,
                              a.cdgo_prdcdad,
                              a.id_cncpto,
                              a.cdgo_cncpto,
                              a.id_mvmnto_fncro,
                              a.vlor_sldo_cptal,
                              nvl(b.vlor_dscnto, 0) as vlor_dscnto_cptal,
                              a.id_impsto_acto_cncpto,
                              a.fcha_vncmnto,
                              a.cdgo_mvmnto_orgn,
                              a.id_orgen
                         from v_gf_g_cartera_x_concepto a
                         left join w_dscntos_cptal b
                           on b.id_cncpto_rlcnal = a.id_cncpto
                          and b.id_prdo = a.id_prdo
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_impsto = p_id_impsto
                          and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                          and a.id_sjto_impsto = p_id_sjto_impsto
                          and a.id_mvmnto_fncro in
                              (select c.id_mvmnto_fncro
                                 from re_g_documentos_detalle b
                                 join gf_g_movimientos_detalle c
                                   on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                                where b.id_dcmnto = p_id_dcmnto
                                group by c.id_mvmnto_fncro)
                          and a.vlor_sldo_cptal > 0
                        order by a.vgncia, a.prdo, a.cdgo_cncpto) loop
    
      begin
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                              6,
                              'Entrando concepto = ' || c_crtera.id_cncpto,
                              2);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                              6,
                              'c_crtera.vlor_sldo_cptal = ' ||
                              c_crtera.vlor_sldo_cptal,
                              2);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                              6,
                              'Paso 2',
                              2);
      
        -- Agrega una fila a la coleccion de Capital
        r_ap_rcdo := t_ap_rcdo(vgncia                => c_crtera.vgncia,
                               id_prdo               => c_crtera.id_prdo,
                               cdgo_prdcdad          => c_crtera.cdgo_prdcdad,
                               id_cncpto             => c_crtera.id_cncpto,
                               id_cncpto_csdo        => c_crtera.id_cncpto,
                               id_mvmnto_fncro       => c_crtera.id_mvmnto_fncro,
                               vlor_sldo_cptal       => c_crtera.vlor_sldo_cptal,
                               cdgo_mvmnto_tpo       => 'PC',
                               fcha_vncmnto          => c_crtera.fcha_vncmnto,
                               id_impsto_acto_cncpto => c_crtera.id_impsto_acto_cncpto,
                               cdgo_mvmnto_orgn      => c_crtera.cdgo_mvmnto_orgn,
                               id_orgen              => c_crtera.id_orgen);
      
        --Busca el Concepto en el Documento
        declare
          v_vlor_dbe_dcmnto_dtlle number;
          v_dfrncia               number;
        begin
        
          -- Saldo en Cartera
          v_sldo_crtra := v_sldo_crtra + c_crtera.vlor_sldo_cptal;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'v_sldo_crtra = ' || v_sldo_crtra,
                                2);
        
          -- Buscar el valor_debe correspondiente a la cuota en el documento.
          select nvl(sum(a.vlor_dbe), 0)
            into v_vlor_dbe_dcmnto_dtlle
            from re_g_documentos_detalle a
            join gf_g_movimientos_detalle b
              on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
           where a.id_dcmnto = p_id_dcmnto
             and b.id_mvmnto_fncro = c_crtera.id_mvmnto_fncro
             and b.id_cncpto = c_crtera.id_cncpto
             and a.id_cncpto = b.id_cncpto;
             
             
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null, 'pkg_re_recaudos.fnc_ap_dcmnto_dco',6,
                                'p_id_dcmnto = ' || p_id_dcmnto || ' - c_crtera.id_mvmnto_fncro ' || c_crtera.id_mvmnto_fncro  || ' - c_crtera.id_cncpto ' || c_crtera.id_cncpto,
                                2);        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'v_vlor_dbe_dcmnto = ' ||
                                v_vlor_dbe_dcmnto_dtlle,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'c_crtera.vlor_dscnto_cptal = ' ||
                                c_crtera.vlor_dscnto_cptal,
                                2);
        
          -- Calcular la diferencia entre el valor adeudado y el valor debe del documento (Lo que se va a pagar de la cuota)
          v_dfrncia := (c_crtera.vlor_sldo_cptal - v_vlor_dbe_dcmnto_dtlle); --v_vlor_dbe_dcmnto_dtlle lo que trae en el documento
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'v_dfrncia = ' || v_dfrncia,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'c_crtera.vlor_sldo_cptal = ' ||
                                c_crtera.vlor_sldo_cptal,
                                2);
        
          --Asigna el Valor Aplicado para el Concepto C
          r_ap_rcdo.vlor_hber := (case
                                   when (v_dfrncia < 0) then
                                    c_crtera.vlor_sldo_cptal
                                   when (v_dfrncia >= 0 and c_crtera.vlor_dscnto_cptal > 0) then
                                    (v_vlor_dbe_dcmnto_dtlle - c_crtera.vlor_dscnto_cptal)
                                   else
                                    v_vlor_dbe_dcmnto_dtlle
                                 end);
        
          --if c_crtera.vlor_dscnto_cptal > 0 then
          --  r_ap_rcdo.vlor_hber := c_crtera.vlor_dscnto_cptal;
          --end if;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_re_recaudos.fnc_ap_dcmnto_dco',  6, 'Descontando PC = '||c_crtera.vlor_sldo_cptal, 2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'r_ap_rcdo.vlor_hber = ' ||
                                r_ap_rcdo.vlor_hber,
                                2);
        
          --Llena la Coleccion de Capital
          v_ap_rcdo_c.extend;
          v_ap_rcdo_c(v_ap_rcdo_c.count) := r_ap_rcdo;
        
          if (c_crtera.vlor_dscnto_cptal > 0) then
            r_ap_rcdo := t_ap_rcdo(vgncia                => c_crtera.vgncia,
                                   id_prdo               => c_crtera.id_prdo,
                                   cdgo_prdcdad          => c_crtera.cdgo_prdcdad,
                                   id_cncpto             => c_crtera.id_cncpto,
                                   id_cncpto_csdo        => c_crtera.id_cncpto,
                                   id_mvmnto_fncro       => c_crtera.id_mvmnto_fncro,
                                   vlor_sldo_cptal       => 0,
                                   cdgo_mvmnto_tpo       => 'DC',
                                   fcha_vncmnto          => c_crtera.fcha_vncmnto,
                                   id_impsto_acto_cncpto => c_crtera.id_impsto_acto_cncpto,
                                   cdgo_mvmnto_orgn      => c_crtera.cdgo_mvmnto_orgn,
                                   id_orgen              => c_crtera.id_orgen,
                                   vlor_hber             => c_crtera.vlor_dscnto_cptal);
            v_ap_rcdo_c.extend;
            v_ap_rcdo_c(v_ap_rcdo_c.count) := r_ap_rcdo;
          end if;
        
          --Acumulado de Valor Aplicado
          --v_vlor_aplcdo := v_vlor_aplcdo + r_ap_rcdo.vlor_hber - c_crtera.vlor_dscnto_cptal;
          v_vlor_aplcdo := v_vlor_aplcdo + r_ap_rcdo.vlor_hber; --19/02/2022
        
          --if  (c_crtera.vlor_dscnto_cptal > 0) then
          --   v_vlor_aplcdo := v_vlor_aplcdo - c_crtera.vlor_dscnto_cptal;
          --end if;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'v_vlor_aplcdo_cptal = ' || v_vlor_aplcdo,
                                2);
        
        end;
      end;
    
      vlor_ttal_dscnto_c := vlor_ttal_dscnto_c + c_crtera.vlor_dscnto_cptal;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                            6,
                            'vlor_ttal_dscnto_c = ' || vlor_ttal_dscnto_c,
                            2);
    
    end loop;
  
    --Verifica si la Cartera esta en 0 - Para Generar el Saldo a Favor
    if (v_sldo_crtra = 0) then
      r_ap_rcdo.cdgo_mvmnto_tpo := 'SF';
      r_ap_rcdo.vlor_sldo_fvor  := p_vlor_rcdo;
      pipe row(r_ap_rcdo);
      return;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          'vlor_ttal_dscnto_c = ' || vlor_ttal_dscnto_c,
                          2);
  
    --if (vlor_ttal_dscnto_c > 0) then
    --  r_ap_rcdo.cdgo_mvmnto_tpo := 'DC';
    --  r_ap_rcdo.vlor_hber  := vlor_ttal_dscnto_c;
    ---  pipe row(r_ap_rcdo);
    --  return;
    -- end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          '*************** INTERESES *****************',
                          2);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          'Antes de Interes v_vlor_aplcdo : ' ||
                          v_vlor_aplcdo,
                          2);
  
    --Cursor de Conceptos I del Documento
    for c_cncptos_i in (
                        
                          with w_dscntos_intres as
                           (select x.id_cncpto_rlcnal,
                                   x.id_prdo,
                                   x.vlor_dscnto
                              from (select b.id_mvmnto_fncro,
                                           b.id_impsto_acto_cncpto,
                                           b.id_prdo,
                                           max(a.id_cncpto) as id_cncpto,
                                           a.id_cncpto_rlcnal,
                                           sum(a.vlor_hber) as vlor_dscnto,
                                           case
                                             when sum(a.intres_bncrio) > 0 then
                                              'B'
                                             else
                                              'M'
                                           end as indcdor_intres_bncrio,
                                           sum(a.intres_bncrio) as vlor_intres_bncrio
                                      from re_g_documentos_detalle a
                                      join gf_g_movimientos_detalle b
                                        on a.id_mvmnto_dtlle =
                                           b.id_mvmnto_dtlle
                                      left join v_re_g_documentos_detalle c
                                        on a.id_dcmnto = c.id_dcmnto
                                       and a.id_cncpto_rlcnal = c.id_cncpto
                                       and c.CTGRIA_CNCPTO_DSCNTO = 'I'
                                       and c.id_prdo = b.id_prdo
                                       and c.id_mvmnto_dtlle =
                                           b.id_mvmnto_dtlle --- lujan
                                       and a.ID_DCMNTO_DTLLE =
                                           c.ID_DCMNTO_DTLLE --- johanna
                                     where a.vlor_hber > 0
                                       and a.id_dcmnto = p_id_dcmnto
                                    -- and a.id_cncpto_rlcnal = c_crtera.id_cncpto
                                     group by b.id_mvmnto_fncro,
                                              b.id_impsto_acto_cncpto,
                                              b.id_prdo,
                                              a.id_cncpto_rlcnal) x)
                          select b.vgncia,
                                 e.prdo,
                                 b.id_prdo,
                                 b.cdgo_prdcdad,
                                 b.id_cncpto,
                                 a.id_cncpto as id_cncpto_csdo,
                                 d.cdgo_cncpto,
                                 b.id_mvmnto_fncro,
                                 b.id_impsto_acto_cncpto,
                                 b.fcha_vncmnto,
                                 c.cdgo_mvmnto_orgn,
                                 c.id_orgen,
                                 sum(a.vlor_dbe) as vlor,
                                 decode(a.cdgo_cncpto_tpo, 'I', 'PI', 'PC') as cdgo_mvmnto_tpo,
                                 nvl(r.vlor_dscnto, 0) as vlor_dscnto_intres ---ojooooo
                            from re_g_documentos_detalle a
                            join gf_g_movimientos_detalle b
                              on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                            join gf_g_movimientos_financiero c
                              on b.id_mvmnto_fncro = c.id_mvmnto_fncro
                            join df_i_conceptos d
                              on b.id_cncpto = d.id_cncpto
                            join df_i_periodos e
                              on b.id_prdo = e.id_prdo
                            left join w_dscntos_intres r
                              on r.id_cncpto_rlcnal = a.id_cncpto ---ojooooo
                             and r.id_prdo = b.id_prdo
                           where a.id_dcmnto = p_id_dcmnto
                             and a.id_cncpto <> b.id_cncpto
                             and a.vlor_dbe > 0
                           group by b.vgncia,
                                    e.prdo,
                                    b.id_prdo,
                                    b.cdgo_prdcdad,
                                    b.id_cncpto,
                                    a.id_cncpto,
                                    d.cdgo_cncpto,
                                    b.id_mvmnto_fncro,
                                    b.id_impsto_acto_cncpto,
                                    b.fcha_vncmnto,
                                    c.cdgo_mvmnto_orgn,
                                    c.id_orgen,
                                    decode(a.cdgo_cncpto_tpo, 'I', 'PI', 'PC'),
                                    r.vlor_dscnto ---ojooooo
                        ) loop
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                            6,
                            'Entrando conceptos Interes = ' ||
                            c_cncptos_i.id_cncpto,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                            6,
                            'c_crtera.vlor = ' || c_cncptos_i.vlor,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                            6,
                            'c_crtera.vlor_dscnto_intres = ' ||
                            c_cncptos_i.vlor_dscnto_intres,
                            2);
    
      declare
        r_ap_rcdo_in t_ap_rcdo;
      begin
      
        r_ap_rcdo := t_ap_rcdo(vgncia                => c_cncptos_i.vgncia,
                               id_prdo               => c_cncptos_i.id_prdo,
                               cdgo_prdcdad          => c_cncptos_i.cdgo_prdcdad,
                               id_cncpto             => c_cncptos_i.id_cncpto,
                               id_cncpto_csdo        => c_cncptos_i.id_cncpto_csdo,
                               id_mvmnto_fncro       => c_cncptos_i.id_mvmnto_fncro,
                               cdgo_mvmnto_tpo       => c_cncptos_i.cdgo_mvmnto_tpo,
                               fcha_vncmnto          => c_cncptos_i.fcha_vncmnto,
                               id_impsto_acto_cncpto => c_cncptos_i.id_impsto_acto_cncpto,
                               cdgo_mvmnto_orgn      => c_cncptos_i.cdgo_mvmnto_orgn,
                               id_orgen              => c_cncptos_i.id_orgen);
      
        --Ingreso
        r_ap_rcdo_in                 := r_ap_rcdo;
        r_ap_rcdo_in.cdgo_mvmnto_tpo := 'IN';
        r_ap_rcdo_in.vlor_dbe        := c_cncptos_i.vlor -
                                        c_cncptos_i.vlor_dscnto_intres;
        v_ap_rcdo_i.extend;
        v_ap_rcdo_i(v_ap_rcdo_i.count) := r_ap_rcdo_in;
      
        --Pago
        r_ap_rcdo.vlor_hber := c_cncptos_i.vlor -
                               c_cncptos_i.vlor_dscnto_intres;
        v_ap_rcdo_i.extend;
        v_ap_rcdo_i(v_ap_rcdo_i.count) := r_ap_rcdo;
      
        --Acumulado de Valor Aplicado
        v_vlor_aplcdo := v_vlor_aplcdo + c_cncptos_i.vlor;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                              6,
                              'v_vlor_aplcdo acumulado = ' || v_vlor_aplcdo,
                              2);
      
      end;
    end loop;
  
    --Saldo por Aplicar
    v_sldo_x_aplcr := (p_vlor_rcdo - v_vlor_aplcdo);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          'p_vlor_rcdo = ' || p_vlor_rcdo,
                          2);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          'v_vlor_aplcdo_ttal = ' || v_vlor_aplcdo,
                          2);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                          6,
                          'v_sldo_x_aplcr = ' || v_sldo_x_aplcr,
                          2);
  
    --Verifica si Hay Saldo por Aplicar
    declare
      v_index number := 0;
    begin
      while (v_sldo_x_aplcr > 0 and v_index <> v_ap_rcdo_c.count) loop
        --Incrementa el Indice
        v_index := v_index + 1;
      
        declare
          v_dfrncia number := 0;
        begin
        
          --Diferencia por Aplicar
          v_dfrncia := (v_ap_rcdo_c(v_index).vlor_sldo_cptal - v_ap_rcdo_c(v_index).vlor_hber);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_recaudos.fnc_ap_dcmnto_dco',
                                6,
                                'Diferencia por Aplicar = ' || v_dfrncia,
                                2);
        
          if (v_sldo_x_aplcr >= v_dfrncia) then
            --El Valor Aplicado en Capital se le Suma la Diferencia
            v_ap_rcdo_c(v_index).vlor_hber := v_ap_rcdo_c(v_index)
                                              .vlor_hber + v_dfrncia;
            v_sldo_x_aplcr := (v_sldo_x_aplcr - v_dfrncia);
          elsif (v_sldo_x_aplcr > 0) then
            --El Valor Aplicado en Capital se le Suma el Disponible
            v_ap_rcdo_c(v_index).vlor_hber := v_ap_rcdo_c(v_index)
                                              .vlor_hber + v_sldo_x_aplcr;
            --Reinicia el Saldo en 0
            v_sldo_x_aplcr := 0;
          end if;
        end;
      end loop;
    end;
  
    --Verifica si Hay Saldo a Favor
    if (v_sldo_x_aplcr > 0) then
      r_ap_rcdo                 := t_ap_rcdo();
      r_ap_rcdo.cdgo_mvmnto_tpo := 'SF';
      r_ap_rcdo.vlor_sldo_fvor  := v_sldo_x_aplcr;
      pipe row(r_ap_rcdo);
    end if;
  
    --Escribe los Capitales de Coleccion
    for i in 1 .. v_ap_rcdo_c.count loop
      if (v_ap_rcdo_c(i).vlor_hber > 0) then
        pipe row(v_ap_rcdo_c(i));
      end if;
    end loop;
  
    --Escribe los Interes de la Coleccion
    for i in 1 .. v_ap_rcdo_i.count loop
      pipe row(v_ap_rcdo_i(i));
    end loop;
  
  end fnc_ap_documento_dco;

  /*
    function fnc_ap_documento_dco(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_id_sjto_impsto    in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                  p_id_dcmnto         in re_g_documentos.id_dcmnto%type,
                                  p_vlor_rcdo         in number)
      return g_ap_rcdo
      pipelined is
      r_ap_rcdo      t_ap_rcdo := t_ap_rcdo();
      v_ap_rcdo_c    g_ap_rcdo := g_ap_rcdo();
      v_ap_rcdo_i    g_ap_rcdo := g_ap_rcdo();
      v_sldo_crtra   number := 0;
      v_vlor_aplcdo  number := 0;
      v_sldo_x_aplcr number := 0;
    begin
  
      --Cursor de Cartera del Documento
      for c_crtera in (select a.vgncia,
                              a.prdo,
                              a.id_prdo,
                              a.cdgo_prdcdad,
                              a.id_cncpto,
                              a.cdgo_cncpto,
                              a.id_mvmnto_fncro,
                              a.vlor_sldo_cptal,
                              a.id_impsto_acto_cncpto,
                              a.fcha_vncmnto,
                              a.cdgo_mvmnto_orgn,
                              a.id_orgen
                         from v_gf_g_cartera_x_concepto a
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_impsto = p_id_impsto
                          and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                          and a.id_sjto_impsto = p_id_sjto_impsto
                          and a.id_mvmnto_fncro in
                              (select c.id_mvmnto_fncro
                                 from re_g_documentos_detalle b
                                 join gf_g_movimientos_detalle c
                                   on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                                where b.id_dcmnto = p_id_dcmnto
                                group by c.id_mvmnto_fncro)
                          and a.vlor_sldo_cptal > 0
                        order by a.vgncia, a.prdo, a.cdgo_cncpto) loop
  
        begin
  
          r_ap_rcdo := t_ap_rcdo(vgncia                => c_crtera.vgncia,
                                 id_prdo               => c_crtera.id_prdo,
                                 cdgo_prdcdad          => c_crtera.cdgo_prdcdad,
                                 id_cncpto             => c_crtera.id_cncpto,
                                 id_cncpto_csdo        => c_crtera.id_cncpto,
                                 id_mvmnto_fncro       => c_crtera.id_mvmnto_fncro,
                                 vlor_sldo_cptal       => c_crtera.vlor_sldo_cptal,
                                 cdgo_mvmnto_tpo       => 'PC',
                                 fcha_vncmnto          => c_crtera.fcha_vncmnto,
                                 id_impsto_acto_cncpto => c_crtera.id_impsto_acto_cncpto,
                                 cdgo_mvmnto_orgn      => c_crtera.cdgo_mvmnto_orgn,
                                 id_orgen              => c_crtera.id_orgen);
  
          --Busca el Concepto en el Documento
          declare
            v_vlor    number;
            v_dfrncia number;
          begin
  
            --Saldo en Cartera
            v_sldo_crtra := v_sldo_crtra + c_crtera.vlor_sldo_cptal;
  
            select nvl(sum(a.vlor_dbe), 0)
              into v_vlor
              from re_g_documentos_detalle a
              join gf_g_movimientos_detalle b
                on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
             where a.id_dcmnto = p_id_dcmnto
               and b.id_mvmnto_fncro = c_crtera.id_mvmnto_fncro
               and b.id_cncpto = c_crtera.id_cncpto
               and a.id_cncpto = b.id_cncpto;
  
            --Diferencia C
            v_dfrncia := (c_crtera.vlor_sldo_cptal - v_vlor);
  
            --Asigna el Valor Aplicado para el Concepto C
            r_ap_rcdo.vlor_hber := (case
                                     when (v_dfrncia < 0) then
                                      c_crtera.vlor_sldo_cptal
                                     else
                                      v_vlor
                                   end);
  
            --Llena la Coleccion de Capital
            v_ap_rcdo_c.extend;
            v_ap_rcdo_c(v_ap_rcdo_c.count) := r_ap_rcdo;
  
            --Acumulado de Valor Aplicado
            v_vlor_aplcdo := v_vlor_aplcdo + r_ap_rcdo.vlor_hber;
  
          end;
        end;
      end loop;
  
      --Verifica si la Cartera esta en 0 - Para Generar el Saldo a Favor
      if (v_sldo_crtra = 0) then
        r_ap_rcdo.cdgo_mvmnto_tpo := 'SF';
        r_ap_rcdo.vlor_sldo_fvor  := p_vlor_rcdo;
        pipe row(r_ap_rcdo);
        return;
      end if;
  
      --Cursor de Conceptos I del Documento
      for c_cncptos_i in (select b.vgncia,
                                 e.prdo,
                                 b.id_prdo,
                                 b.cdgo_prdcdad,
                                 b.id_cncpto,
                                 a.id_cncpto as id_cncpto_csdo,
                                 d.cdgo_cncpto,
                                 b.id_mvmnto_fncro,
                                 b.id_impsto_acto_cncpto,
                                 b.fcha_vncmnto,
                                 c.cdgo_mvmnto_orgn,
                                 c.id_orgen,
                                 sum(a.vlor_dbe) as vlor,
                                 decode(a.cdgo_cncpto_tpo, 'I', 'PI', 'PC') as cdgo_mvmnto_tpo
                            from re_g_documentos_detalle a
                            join gf_g_movimientos_detalle b
                              on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                            join gf_g_movimientos_financiero c
                              on b.id_mvmnto_fncro = c.id_mvmnto_fncro
                            join df_i_conceptos d
                              on b.id_cncpto = d.id_cncpto
                            join df_i_periodos e
                              on b.id_prdo = e.id_prdo
                           where a.id_dcmnto = p_id_dcmnto
                             and a.id_cncpto <> b.id_cncpto
                             and a.vlor_dbe > 0
                           group by b.vgncia,
                                    e.prdo,
                                    b.id_prdo,
                                    b.cdgo_prdcdad,
                                    b.id_cncpto,
                                    a.id_cncpto,
                                    d.cdgo_cncpto,
                                    b.id_mvmnto_fncro,
                                    b.id_impsto_acto_cncpto,
                                    b.fcha_vncmnto,
                                    c.cdgo_mvmnto_orgn,
                                    c.id_orgen,
                                    decode(a.cdgo_cncpto_tpo, 'I', 'PI', 'PC')) loop
  
        declare
          r_ap_rcdo_in t_ap_rcdo;
        begin
  
          r_ap_rcdo := t_ap_rcdo(vgncia                => c_cncptos_i.vgncia,
                                 id_prdo               => c_cncptos_i.id_prdo,
                                 cdgo_prdcdad          => c_cncptos_i.cdgo_prdcdad,
                                 id_cncpto             => c_cncptos_i.id_cncpto,
                                 id_cncpto_csdo        => c_cncptos_i.id_cncpto_csdo,
                                 id_mvmnto_fncro       => c_cncptos_i.id_mvmnto_fncro,
                                 cdgo_mvmnto_tpo       => c_cncptos_i.cdgo_mvmnto_tpo,
                                 fcha_vncmnto          => c_cncptos_i.fcha_vncmnto,
                                 id_impsto_acto_cncpto => c_cncptos_i.id_impsto_acto_cncpto,
                                 cdgo_mvmnto_orgn      => c_cncptos_i.cdgo_mvmnto_orgn,
                                 id_orgen              => c_cncptos_i.id_orgen);
  
          --Ingreso
          r_ap_rcdo_in                 := r_ap_rcdo;
          r_ap_rcdo_in.cdgo_mvmnto_tpo := 'IN';
          r_ap_rcdo_in.vlor_dbe        := c_cncptos_i.vlor;
          v_ap_rcdo_i.extend;
          v_ap_rcdo_i(v_ap_rcdo_i.count) := r_ap_rcdo_in;
  
          --Pago
          r_ap_rcdo.vlor_hber := c_cncptos_i.vlor;
          v_ap_rcdo_i.extend;
          v_ap_rcdo_i(v_ap_rcdo_i.count) := r_ap_rcdo;
  
          --Acumulado de Valor Aplicado
          v_vlor_aplcdo := v_vlor_aplcdo + c_cncptos_i.vlor;
  
        end;
      end loop;
  
      --Saldo por Aplicar
      v_sldo_x_aplcr := (p_vlor_rcdo - v_vlor_aplcdo);
  
      --Verifica si Hay Saldo por Aplicar
      declare
        v_index number := 0;
      begin
        while (v_sldo_x_aplcr > 0 and v_index <> v_ap_rcdo_c.count) loop
          --Incrementa el Indice
          v_index := v_index + 1;
  
          declare
            v_dfrncia number := 0;
          begin
  
            --Diferencia por Aplicar
            v_dfrncia := (v_ap_rcdo_c(v_index).vlor_sldo_cptal - v_ap_rcdo_c(v_index).vlor_hber);
  
            if (v_sldo_x_aplcr >= v_dfrncia) then
              --El Valor Aplicado en Capital se le Suma la Diferencia
              v_ap_rcdo_c(v_index).vlor_hber := v_ap_rcdo_c(v_index)
                                                .vlor_hber + v_dfrncia;
              v_sldo_x_aplcr := (v_sldo_x_aplcr - v_dfrncia);
            elsif (v_sldo_x_aplcr > 0) then
              --El Valor Aplicado en Capital se le Suma el Disponible
              v_ap_rcdo_c(v_index).vlor_hber := v_ap_rcdo_c(v_index)
                                                .vlor_hber + v_sldo_x_aplcr;
              --Reinicia el Saldo en 0
              v_sldo_x_aplcr := 0;
            end if;
          end;
        end loop;
      end;
  
      --Verifica si Hay Saldo a Favor
      if (v_sldo_x_aplcr > 0) then
        r_ap_rcdo                 := t_ap_rcdo();
        r_ap_rcdo.cdgo_mvmnto_tpo := 'SF';
        r_ap_rcdo.vlor_sldo_fvor  := v_sldo_x_aplcr;
        pipe row(r_ap_rcdo);
      end if;
  
      --Escribe los Capitales de Coleccion
      for i in 1 .. v_ap_rcdo_c.count loop
        if (v_ap_rcdo_c(i).vlor_hber > 0) then
          pipe row(v_ap_rcdo_c(i));
        end if;
      end loop;
  
      --Escribe los Interes de la Coleccion
      for i in 1 .. v_ap_rcdo_i.count loop
        pipe row(v_ap_rcdo_i(i));
      end loop;
  
    end fnc_ap_documento_dco;
  */

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Convenio
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dco(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
    v_nvel               number;
    v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_documento_dco';
    v_re_g_recaudos      re_g_recaudos%rowtype;
    v_re_g_documentos    re_g_documentos%rowtype;
    v_cdgo_sldo_fvor_tpo gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type;
    v_vlor_aplcdo        number := 0;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo
         and a.cdgo_rcdo_estdo = 'RG'
         and a.cdgo_rcdo_orgn_tpo = 'DC';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo id#' || p_id_rcdo ||
                          ' con origen [DC], no existe en el sistema o no se encuentra en estado registrado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Verifica si Existe el Documento de Pago
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_documentos
        from re_g_documentos a
       where id_dcmnto = v_re_g_recaudos.id_orgen
         and cdgo_dcmnto_tpo = 'DCO';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago id#' ||
                          v_re_g_recaudos.id_orgen ||
                          ', no existe en el sistema o no se encuentra con tipo [DCO].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => 'Antes de entrar al cursor c_crtra',
                          p_nvel_txto  => 3);
  
    --Cursor de Cartera Aplicada
    for c_crtra in (select *
                      from table(pkg_re_recaudos.fnc_ap_documento_dco(p_cdgo_clnte        => p_cdgo_clnte,
                                                                      p_id_impsto         => v_re_g_documentos.id_impsto,
                                                                      p_id_impsto_sbmpsto => v_re_g_documentos.id_impsto_sbmpsto,
                                                                      p_id_sjto_impsto    => v_re_g_documentos.id_sjto_impsto,
                                                                      p_id_dcmnto         => v_re_g_documentos.id_dcmnto,
                                                                      p_vlor_rcdo         => v_re_g_recaudos.vlor)) a) loop
    
      declare
        v_indcdor_mvmnto_blqdo gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type;
        v_cdgo_trza_orgn       gf_g_movimientos_traza.cdgo_trza_orgn%type;
        v_id_orgen             gf_g_movimientos_traza.id_orgen%type;
        v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
      begin
      
        --Saldo a Favor, Pago Capital y Pago Interes
        if (c_crtra.cdgo_mvmnto_tpo in ('SF', 'PC', 'PI')) then
          v_vlor_aplcdo := v_vlor_aplcdo + c_crtra.vlor_sldo_fvor +
                           c_crtra.vlor_hber;
        end if;
      
        --Indicador de Saldo a Favor
        if (c_crtra.cdgo_mvmnto_tpo = 'SF') then
        
          --Pago en Exceso
          v_cdgo_sldo_fvor_tpo := 'PEE';
          if (v_re_g_documentos.indcdor_pgo_aplcdo = 'S') then
            --Pago Doble
            v_cdgo_sldo_fvor_tpo := 'SPD';
          end if;
        
          --Up Registro Saldo a Favor
          pkg_re_recaudos.prc_rg_saldo_favor(p_id_usrio           => p_id_usrio,
                                             p_cdgo_clnte         => p_cdgo_clnte,
                                             p_id_impsto          => v_re_g_documentos.id_impsto,
                                             p_id_impsto_sbmpsto  => v_re_g_documentos.id_impsto_sbmpsto,
                                             p_id_sjto_impsto     => v_re_g_documentos.id_sjto_impsto,
                                             p_id_rcdo            => v_re_g_recaudos.id_rcdo,
                                             p_id_orgen           => v_re_g_recaudos.id_orgen,
                                             p_cdgo_rcdo_orgn_tpo => v_re_g_recaudos.cdgo_rcdo_orgn_tpo,
                                             p_cdgo_sldo_fvor_tpo => v_cdgo_sldo_fvor_tpo,
                                             p_vlor_sldo_fvor     => c_crtra.vlor_sldo_fvor,
                                             p_obsrvcion          => 'Saldo a favor, documento #' ||
                                                                     v_re_g_documentos.nmro_dcmnto ||
                                                                     ' por valor de ' ||
                                                                     to_char(c_crtra.vlor_sldo_fvor,
                                                                             'FM$999G999G999G999G999G999G990'),
                                             o_id_sldo_fvor       => o_id_sldo_fvor,
                                             o_cdgo_rspsta        => o_cdgo_rspsta,
                                             o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
          continue;
        end if;
      
        --Up que Consulta si la Cartera esta Bloqueada
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_sjto_impsto       => v_re_g_documentos.id_sjto_impsto,
                                                                  p_vgncia               => c_crtra.vgncia,
                                                                  p_id_prdo              => c_crtra.id_prdo,
                                                                  p_id_orgen             => c_crtra.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta := 4;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          o_mnsje_rspsta := 'No fue posible consultar si la cartera del sujeto impuesto se encuentra bloqueda.';
          return;
        end if;
      
        --Verifica si la Cartera se Encuentra Bloqueada
        if (v_indcdor_mvmnto_blqdo = 'S') then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el sujeto impuesto posee la vigencia ' ||
                            c_crtra.vgncia || ' bloqueada,' ||
                            lower(v_obsrvcion_blquo) || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      
        --Inserta los Movimientos Financiero
        begin
          insert into gf_g_movimientos_detalle
            (id_mvmnto_dtlle,
             id_mvmnto_fncro,
             cdgo_mvmnto_orgn,
             id_orgen,
             cdgo_mvmnto_tpo,
             vgncia,
             id_prdo,
             cdgo_prdcdad,
             fcha_mvmnto,
             id_cncpto,
             id_cncpto_csdo,
             vlor_dbe,
             vlor_hber,
             actvo,
             gnra_intres_mra,
             fcha_vncmnto,
             id_impsto_acto_cncpto)
          values
            (sq_gf_g_movimientos_detalle.nextval,
             c_crtra.id_mvmnto_fncro,
             g_cdgo_mvmnto_orgn,
             p_id_rcdo,
             c_crtra.cdgo_mvmnto_tpo,
             c_crtra.vgncia,
             c_crtra.id_prdo,
             c_crtra.cdgo_prdcdad,
             systimestamp,
             c_crtra.id_cncpto,
             c_crtra.id_cncpto_csdo,
             c_crtra.vlor_dbe,
             c_crtra.vlor_hber,
             'S',
             c_crtra.gnra_intres_mra,
             c_crtra.fcha_vncmnto,
             c_crtra.id_impsto_acto_cncpto);
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el movimiento financiero para el documento de convenio.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      end;
    end loop;
  
    o_mnsje_rspsta := ' v_re_g_recaudos.vlor ' || v_re_g_recaudos.vlor ||
                      ' - v_vlor_aplcdo ' || v_vlor_aplcdo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 3);
  
    --Verifica el Valor del Recaudo contra El Valor Aplicado
    if (v_re_g_recaudos.vlor <> v_vlor_aplcdo) then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo, ya que el valor aplicado ' ||
                        to_char(v_vlor_aplcdo,
                                'FM$999G999G999G999G999G999G990') ||
                        ' no corresponde al del recaudo ' ||
                        to_char(v_re_g_recaudos.vlor,
                                'FM$999G999G999G999G999G999G990') || '.';
      return;
    end if;
  
    for c_cuotas in (select id_cnvnio, nmro_cta
                       from re_g_documentos_cnvnio_cta
                      where id_dcmnto = v_re_g_recaudos.id_orgen
                      group by id_cnvnio, nmro_cta) loop
    
      if (pkg_gf_convenios.fnc_cl_cuota_pagada(p_id_cnvnio => c_cuotas.id_cnvnio,
                                               p_nmro_cta  => c_cuotas.nmro_cta) = 'N') then
        pkg_gf_convenios.prc_ac_convenio_cuota(p_cdgo_clnte   => p_cdgo_clnte,
                                               p_id_cnvnio    => c_cuotas.id_cnvnio,
                                               p_nmro_cta     => c_cuotas.nmro_cta,
                                               p_id_dcmnto    => v_re_g_recaudos.id_orgen,
                                               o_cdgo_rspsta  => o_cdgo_rspsta,
                                               o_mnsje_rspsta => o_mnsje_rspsta);
      end if;
    
      --Verifica si no hay Errores
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No fue posible actualizar la cuota del convenio';
        return;
      end if;
    end loop;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Documento de convenio aplicado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo id#[' ||
                        p_id_rcdo ||
                        '] para el documento de convenio, intentelo mas tarde.' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_documento_dco;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Declaracion
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_declaracion(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                               p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                               p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                               o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2) as
    v_nvel               number;
    v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_ap_declaracion';
    v_re_g_recaudos      re_g_recaudos%rowtype;
    v_gi_g_declaraciones gi_g_declaraciones%rowtype;
    v_cdgo_sldo_fvor_tpo gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type;
    v_json_crtra         clob;
    v_json_dscnto        clob;
    v_json_object        json_object_t;
    v_json               clob;
    v_vlor_aplcdo        number := 0;
    v_vlor_sldo_cptal    number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si el Recaudo Existe
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_re_g_recaudos
        from re_g_recaudos a
       where a.id_rcdo = p_id_rcdo
         and a.cdgo_rcdo_estdo = 'RG'
         and a.cdgo_rcdo_orgn_tpo = 'DL';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El recaudo #' || p_id_rcdo ||
                          ' con origen [DL], no se encuentra en estado registrado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Verifica si Existe el Documento de Pago
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_gi_g_declaraciones
        from gi_g_declaraciones a
       where id_dclrcion = v_re_g_recaudos.id_orgen;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El documento de declaracion #' ||
                          v_re_g_recaudos.id_orgen ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Json de Cartera de la Declaracion
    select json_object('carteras' value
                       json_arrayagg(json_object('vgncia' value a.vgncia,
                                                 'prdo' value a.prdo,
                                                 'id_prdo' value a.id_prdo,
                                                 'cdgo_prdcdad' value
                                                 a.cdgo_prdcdad,
                                                 'id_cncpto' value
                                                 a.id_cncpto,
                                                 'cdgo_cncpto' value
                                                 a.cdgo_cncpto,
                                                 'id_mvmnto_fncro' value
                                                 a.id_mvmnto_fncro,
                                                 'vlor_sldo_cptal' value
                                                 a.vlor_sldo_cptal,
                                                 'id_impsto_acto_cncpto'
                                                 value
                                                 a.id_impsto_acto_cncpto,
                                                 'fcha_vncmnto' value
                                                 a.fcha_vncmnto,
                                                 'cdgo_mvmnto_orgn' value
                                                 a.cdgo_mvmnto_orgn,
                                                 'id_orgen' value a.id_orgen)
                                     returning clob) absent on null
                       returning clob) as json,
           nvl(sum(a.vlor_sldo_cptal), 0)
      into v_json_crtra, v_vlor_sldo_cptal
      from v_gf_g_cartera_x_concepto a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = v_gi_g_declaraciones.id_impsto
       and a.id_impsto_sbmpsto = v_gi_g_declaraciones.id_impsto_sbmpsto
       and a.id_sjto_impsto = v_gi_g_declaraciones.id_sjto_impsto
       and a.id_mvmnto_fncro in
           (select c.id_mvmnto_fncro
              from gi_g_dclrcnes_mvmnto_fnncro b
              join gf_g_movimientos_detalle c
                on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle
             where b.id_dclrcion = v_re_g_recaudos.id_orgen
               and b.id_mvmnto_dtlle is not null
             group by c.id_mvmnto_fncro)
       and a.vlor_sldo_cptal > 0;
  
    if (v_vlor_sldo_cptal > 0 and v_json_crtra = '{}') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'No se pudo obtener la cartera a la que se le va aplicar el recaudo. Intentelo mas tarde';
      return;
    end if;
  
    --Json de Descuentos de la Declaracion
    select json_object('descuentos' value
                       json_arrayagg(json_object('id_mvmnto_fncro' value
                                                 a.id_mvmnto_fncro,
                                                 'id_impsto_acto_cncpto'
                                                 value
                                                 a.id_impsto_acto_cncpto,
                                                 'id_cncpto' value
                                                 a.id_cncpto,
                                                 'id_cncpto_rlcnal' value
                                                 a.id_cncpto_rlcnal,
                                                 'vlor_dscnto' value
                                                 a.vlor_dscnto) returning clob)
                       absent on null returning clob) as json
      into v_json_dscnto
      from (select b.id_mvmnto_fncro,
                   b.id_impsto_acto_cncpto,
                   max(a.id_cncpto) as id_cncpto,
                   a.id_cncpto_rlcnal,
                   sum(a.vlor_hber) as vlor_dscnto
              from gi_g_dclrcnes_mvmnto_fnncro a
              join gf_g_movimientos_detalle b
                on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
             where a.vlor_hber > 0
               and a.id_dclrcion = v_gi_g_declaraciones.id_dclrcion
             group by b.id_mvmnto_fncro,
                      b.id_impsto_acto_cncpto,
                      a.id_cncpto_rlcnal) a;
  
    --Asigna el Json al Objeto
    v_json_object := json_object_t(v_json_crtra);
    --Merge de Json de Cartera Documento y Descuentos
    v_json_object.mergepatch(json_object_t(v_json_dscnto));
    --Json de Aplicador
    v_json := v_json_object.to_clob();
  
    --Se guarda una foto de como se encontraba la cartera antes de aplicar el recaudo
    begin
      insert into re_g_recaudos_cartera
        (id_rcdo, json_crtra)
      values
        (p_id_rcdo, v_json);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'No se pudo guardar la foto de la cartera';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Cursor de Cartera Aplicada
    for c_crtra in (select a.*
                      from table(pkg_re_recaudos.prc_ap_recaudo_prprcnal(p_cdgo_clnte        => p_cdgo_clnte,
                                                                         p_id_impsto         => v_gi_g_declaraciones.id_impsto,
                                                                         p_id_impsto_sbmpsto => v_gi_g_declaraciones.id_impsto_sbmpsto,
                                                                         p_fcha_vncmnto      => v_gi_g_declaraciones.fcha_prsntcion_pryctda,
                                                                         p_vlor_rcdo         => v_re_g_recaudos.vlor,
                                                                         p_json_crtra        => v_json)) a) loop
    
      declare
        v_indcdor_mvmnto_blqdo gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type;
        v_cdgo_trza_orgn       gf_g_movimientos_traza.cdgo_trza_orgn%type;
        v_id_orgen             gf_g_movimientos_traza.id_orgen%type;
        v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
      begin
      
        --Saldo a Favor, Pago Capital y Pago Interes
        if (c_crtra.cdgo_mvmnto_tpo in ('SF', 'PC', 'PI')) then
          v_vlor_aplcdo := v_vlor_aplcdo + c_crtra.vlor_sldo_fvor +
                           c_crtra.vlor_hber;
        end if;
      
        --Indicador de Saldo a Favor
        if (c_crtra.cdgo_mvmnto_tpo = 'SF') then
        
          --Pago en Exceso
          v_cdgo_sldo_fvor_tpo := 'PEE';
          --Esta Pendiente por Confirmar el Estado Anulado
          if (not v_gi_g_declaraciones.cdgo_dclrcion_estdo in
              ('REG', 'AUT', 'ANU')) then
            --Pago Doble
            v_cdgo_sldo_fvor_tpo := 'SPD';
          end if;
        
          --Up Registro Saldo a Favor
          pkg_re_recaudos.prc_rg_saldo_favor(p_id_usrio           => p_id_usrio,
                                             p_cdgo_clnte         => p_cdgo_clnte,
                                             p_id_impsto          => v_gi_g_declaraciones.id_impsto,
                                             p_id_impsto_sbmpsto  => v_gi_g_declaraciones.id_impsto_sbmpsto,
                                             p_id_sjto_impsto     => v_gi_g_declaraciones.id_sjto_impsto,
                                             p_id_rcdo            => v_re_g_recaudos.id_rcdo,
                                             p_id_orgen           => v_re_g_recaudos.id_orgen,
                                             p_cdgo_rcdo_orgn_tpo => v_re_g_recaudos.cdgo_rcdo_orgn_tpo,
                                             p_cdgo_sldo_fvor_tpo => v_cdgo_sldo_fvor_tpo,
                                             p_vlor_sldo_fvor     => c_crtra.vlor_sldo_fvor,
                                             p_obsrvcion          => 'Saldo a favor, declaracion #' ||
                                                                     v_gi_g_declaraciones.nmro_cnsctvo ||
                                                                     ' por valor de ' ||
                                                                     to_char(c_crtra.vlor_sldo_fvor,
                                                                             'FM$999G999G999G999G999G999G990'),
                                             o_id_sldo_fvor       => o_id_sldo_fvor,
                                             o_cdgo_rspsta        => o_cdgo_rspsta,
                                             o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
          continue;
        end if;
      
        --Up que Consulta si la Cartera esta Bloqueada
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_sjto_impsto       => v_gi_g_declaraciones.id_sjto_impsto,
                                                                  p_vgncia               => c_crtra.vgncia,
                                                                  p_id_prdo              => c_crtra.id_prdo,
                                                                  p_id_orgen             => c_crtra.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);
      
        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta := 6;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          o_mnsje_rspsta := 'No fue posible consultar si la cartera del sujeto impuesto, se encuentra bloqueda.';
          return;
        end if;
      
        --Verifica si la Cartera se Encuentra Bloqueada
        if (v_indcdor_mvmnto_blqdo = 'S') then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el sujeto impuesto posee la vigencia ' ||
                            c_crtra.vgncia || ' bloqueada,' ||
                            lower(v_obsrvcion_blquo) || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      
        --Inserta los Movimientos Financiero
        begin
          insert into gf_g_movimientos_detalle
            (id_mvmnto_dtlle,
             id_mvmnto_fncro,
             cdgo_mvmnto_orgn,
             id_orgen,
             cdgo_mvmnto_tpo,
             vgncia,
             id_prdo,
             cdgo_prdcdad,
             fcha_mvmnto,
             id_cncpto,
             id_cncpto_csdo,
             vlor_dbe,
             vlor_hber,
             actvo,
             gnra_intres_mra,
             fcha_vncmnto,
             id_impsto_acto_cncpto)
          values
            (sq_gf_g_movimientos_detalle.nextval,
             c_crtra.id_mvmnto_fncro,
             g_cdgo_mvmnto_orgn,
             p_id_rcdo,
             c_crtra.cdgo_mvmnto_tpo,
             c_crtra.vgncia,
             c_crtra.id_prdo,
             c_crtra.cdgo_prdcdad,
             systimestamp,
             c_crtra.id_cncpto,
             c_crtra.id_cncpto_csdo,
             c_crtra.vlor_dbe,
             c_crtra.vlor_hber,
             'S',
             c_crtra.gnra_intres_mra,
             c_crtra.fcha_vncmnto,
             c_crtra.id_impsto_acto_cncpto);
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el movimiento financiero para la declaracion.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      end;
    end loop;
  
    --Verifica el Valor del Recaudo contra El Valor Aplicado
    if (v_re_g_recaudos.vlor <> v_vlor_aplcdo) then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible aplicar el recaudo, ya que el valor aplicado ' ||
                        to_char(v_vlor_aplcdo,
                                'FM$999G999G999G999G999G999G990') ||
                        ' no corresponde al del recaudo ' ||
                        to_char(v_re_g_recaudos.vlor,
                                'FM$999G999G999G999G999G999G990') || '.';
      return;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Declaracion aplicada con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible aplicar el recaudo #[' ||
                        p_id_rcdo || '] declaracion, intentelo mas tarde.' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ap_declaracion;

  /*
  * @Descripcion    : Metodo Validar Factura WebService
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */

  procedure prc_vl_factura_ws(p_request_json  in clob,
                              o_response_json out clob) as
    v_nvel               number;
    v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_vl_factura_ws';
    v_cdgo_ean           varchar2(30);
    v_nmro_dcmnto        number;
    v_vlor_pago          number;
    v_fcha_vncmnto       timestamp;
    v_cdgo_rcdo_orgn_tpo re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
    v_id_orgen           re_g_recaudos.id_orgen%type;
    v_cdgo_clnte         df_s_clientes.cdgo_clnte%type;
    v_id_impsto          df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_cdgo_rspsta        number;
    v_mnsje_rspsta       varchar2(4000);
    v_c_rcdos            number;
    v_vlor_hra_incio     df_c_definiciones_cliente.vlor%type;
    v_vlor_hra_fin       df_c_definiciones_cliente.vlor%type;
    v_fcha_hra_incio     timestamp;
    v_fcha_hra_fin       timestamp;
  begin
  
    o_response_json := '{}';
  
    --Verifica si el JSON es Valido
    begin
      apex_json.parse(p_request_json);
    exception
      when others then
        raise_application_error(-20001,
                                'JSON no valido, por favor verifique.');
    end;
  
    --Inicializa el Objeto JSON
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.open_object('Respuesta');
    apex_json.write('RqUID', sys_guid());
  
    --1. CodigoEan
    v_cdgo_ean := apex_json.get_varchar2(p_path => 'CodigoEan');
  
    begin
      --2. NumeroDocumento
      v_nmro_dcmnto := apex_json.get_number(p_path => 'NumeroDocumento');
    exception
      when value_error then
        apex_json.write('NumeroEstadoRespuesta', 20);
        apex_json.write('DescripcionEstadoRespuesta',
                        'Numero de documento no valido, verifique que sea numerico.');
        apex_json.close_all;
        o_response_json := apex_json.get_clob_output;
        return;
    end;
  
    begin
      --3. ValorPago
      v_vlor_pago := apex_json.get_number(p_path => 'ValorPago');
    exception
      when value_error then
        apex_json.write('NumeroEstadoRespuesta', 21);
        apex_json.write('DescripcionEstadoRespuesta',
                        'Valor a pagar no valido, verifique que sea numerico.');
        apex_json.close_all;
        o_response_json := apex_json.get_clob_output;
        return;
    end;
  
    begin
      --4. FechaVencimiento
      v_fcha_vncmnto := apex_json.get_timestamp(p_path   => 'FechaVencimiento',
                                                p_format => 'YYYYMMDD');
    exception
      when others then
        apex_json.write('NumeroEstadoRespuesta', 22);
        apex_json.write('DescripcionEstadoRespuesta',
                        'Fecha de vencimiento no valido, verifique que sea numerico y su formato en YYYYMMDD.');
        apex_json.close_all;
        o_response_json := apex_json.get_clob_output;
        return;
    end;
  
    --Valida el Documento de Pago
    /*pkg_re_recaudos.prc_vl_documento( p_cdgo_ean           => v_cdgo_ean
    , p_nmro_dcmnto        => v_nmro_dcmnto
    , p_vlor               => v_vlor_pago
    , p_fcha_vncmnto       => v_fcha_vncmnto
    , o_cdgo_rcdo_orgn_tpo => v_cdgo_rcdo_orgn_tpo
    , o_id_orgen           => v_id_orgen
    , o_cdgo_clnte         => v_cdgo_clnte
    , o_id_impsto          => v_id_impsto
    , o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto
    , o_id_sjto_impsto     => v_id_sjto_impsto
    , o_cdgo_rspsta        => v_cdgo_rspsta
    , o_mnsje_rspsta       => v_mnsje_rspsta );*/
  
    --Verifica si la Validacion del Documento de Pago fue Exitosa
    if (v_cdgo_rspsta <> 0) then
      apex_json.write('NumeroEstadoRespuesta', v_cdgo_rspsta);
      apex_json.write('DescripcionEstadoRespuesta', v_mnsje_rspsta);
      apex_json.close_all;
      o_response_json := apex_json.get_clob_output;
      return;
    end if;
  
    /*select count(*)
     into v_c_rcdos
     from re_g_recaudo_linea
    where cdgo_rcdo_orgn_tpo = v_cdgo_rcdo_orgn_tpo
      and id_orgen           = v_id_orgen
      and cdgo_rcdo_estdo    <> 'AN';*/
  
    --Verifica si no Existe un Pago Registrado en Recaudo Linea
    if (v_c_rcdos > 0) then
      apex_json.write('NumeroEstadoRespuesta', 9);
      apex_json.write('DescripcionEstadoRespuesta',
                      'El Documento #' || v_nmro_dcmnto ||
                      ', ya se encuentra pagado.');
      apex_json.close_all;
      o_response_json := apex_json.get_clob_output;
      return;
    end if;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => v_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => v_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Se Verifica que la Fecha del Documento no se Encuentra Vencida.
    if (trunc(systimestamp) > v_fcha_vncmnto) then
      apex_json.write('NumeroEstadoRespuesta', 20);
      apex_json.write('DescripcionEstadoRespuesta',
                      'El Documento se encuentra vencido.');
      apex_json.close_all;
      o_response_json := apex_json.get_clob_output;
      return;
    end if;
  
    --Busca la Hora de Inicio para Recaudar del Cliente
    v_vlor_hra_incio := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                        p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria,
                                                                        p_cdgo_dfncion_clnte        => 'WHI');
  
    --Busca la Hora Fin para Recaudar del Cliente
    v_vlor_hra_fin := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                      p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria,
                                                                      p_cdgo_dfncion_clnte        => 'WHF');
  
    --Verifica si se Encontro el Valor de la Definicion
    if (v_vlor_hra_incio <> '-1' and v_vlor_hra_fin <> '-1') then
      begin
        v_fcha_hra_incio := to_timestamp(v_vlor_hra_incio, 'HH24:MI');
        v_fcha_hra_fin   := to_timestamp(v_vlor_hra_fin, 'HH24:MI');
        --Se Verifica si el Documento se Encuentra en Horario para Recaudar
        if (not (to_timestamp(to_char(systimestamp, 'HH24:MI'), 'HH24:MI') between
            v_fcha_hra_incio and v_fcha_hra_fin)) then
          apex_json.write('NumeroEstadoRespuesta', 22);
          apex_json.write('DescripcionEstadoRespuesta',
                          'Transaccion fallida, el horario estipulado es de ' ||
                          to_char(v_fcha_hra_incio, 'HH12:MI AM') || ' a ' ||
                          to_char(v_fcha_hra_fin, 'HH12:MI AM') || '.');
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
        end if;
      
      exception
        when others then
          apex_json.write('NumeroEstadoRespuesta', 21);
          apex_json.write('DescripcionEstadoRespuesta',
                          'Verifique que la definicion de horario de web service se encuente en el formato [HH24:MI].'); --corregir
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end;
    end if;
  
    apex_json.write('NumeroEstadoRespuesta', 0);
    apex_json.write('DescripcionEstadoRespuesta',
                    'El Documento es valido para registrar recaudo en el sistema.');
    apex_json.write('IdDocumento', v_id_orgen);
    apex_json.write('CodigoDocumentoDestino', v_cdgo_rcdo_orgn_tpo);
    apex_json.write('IdCliente', v_cdgo_clnte);
    apex_json.write('IdImpuesto', v_id_impsto);
    apex_json.write('IdSubImpuesto', v_id_impsto_sbmpsto);
    apex_json.write('IdSujetoImpuesto', v_id_sjto_impsto);
    apex_json.close_all;
  
    o_response_json := apex_json.get_clob_output;
  
    v_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => v_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
  exception
    when others then
      apex_json.write('NumeroEstadoRespuesta', 100);
      apex_json.write('DescripcionEstadoRespuesta',
                      'Transaccion fallida, intentelo mas tarde.');
      apex_json.write('Error', sqlerrm);
      apex_json.close_all;
      o_response_json := apex_json.get_clob_output;
      apex_json.free_output;
  end prc_vl_factura_ws;

  /*
  * @Descripcion    : Metodo Registrar Recaudo Pago WebService
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */
  /*
  procedure prc_rg_recaudo_pago_ws( p_request_json  in  clob
                                  , o_response_json out clob )
  as
      v_nivel             number;
      v_cdgo_clnte        df_s_clientes.cdgo_clnte%type;
      v_id_impsto         df_c_impuestos.id_impsto%type;
      v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
      v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;
      v_fcha_vncmnto      timestamp;
      v_vlor_pago         number;
      v_cdgo_orgn         re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
      v_id_orgen          re_g_recaudos.id_orgen%type;
      v_fcha_pgo          timestamp;
      v_frma_pgo          varchar2(5);
      v_cdgo_bnco         df_c_bancos.cdgo_bnco%type;
      v_cdgo_scrsal       varchar2(10);
      v_json_in           apex_json.t_values;
      v_json_out          apex_json.t_values;
      v_id_rcdo_lnea      re_g_recaudo_linea.id_rcdo_lnea%type;
      v_id_rcdo_cntrol    re_g_recaudos_control.id_rcdo_cntrol%type;
      v_id_rcdo           re_g_recaudos.id_rcdo%type;
      v_mnsje             varchar2(4000);
      v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_recaudo_pago_ws';
      v_id_bnco           df_c_bancos.id_bnco%type;
      v_nmro_dcmnto       number;
      v_cdgo_rspsta       number;
      v_mnsje_rspsta      varchar2(4000);
  begin
  
      o_response_json := '{}';
  
      --Se Valida el Documento de Pago por Seguridad WS
      pkg_re_recaudos.prc_vl_factura_ws( p_request_json  => p_request_json
                                       , o_response_json => o_response_json );
  
      --Se Parsea la Salida a JSON Value
      apex_json.parse( v_json_out , o_response_json);
  
      --Se Verifica si la Validacion del Documento de Pago fue Exitosa
      if( apex_json.get_number( p_values => v_json_out , p_path => 'Respuesta.NumeroEstadoRespuesta') <> 0 ) then
          return;
      end if;
  
      --Se Obtiene los Datos de la Salida JSON
      v_cdgo_clnte        := apex_json.get_number   ( p_values => v_json_out , p_path => 'Respuesta.IdCliente');
      v_id_impsto         := apex_json.get_number   ( p_values => v_json_out , p_path => 'Respuesta.IdImpuesto');
      v_id_impsto_sbmpsto := apex_json.get_number   ( p_values => v_json_out , p_path => 'Respuesta.IdSubImpuesto');
      v_id_sjto_impsto    := apex_json.get_number   ( p_values => v_json_out , p_path => 'Respuesta.IdSujetoImpuesto');
      v_cdgo_orgn         := apex_json.get_varchar2 ( p_values => v_json_out , p_path => 'Respuesta.CodigoDocumentoDestino');
      v_id_orgen          := apex_json.get_number   ( p_values => v_json_out , p_path => 'Respuesta.IdDocumento');
  
      --Determinamos el Nivel del Log de la UP
      v_nivel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => v_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );
  
      v_mnsje := 'Inicio del procedimiento ' || v_nmbre_up;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte => v_cdgo_clnte  , p_id_impsto => null    , p_nmbre_up  => v_nmbre_up
                           , p_nvel_log   => v_nivel       , p_txto_log  => v_mnsje , p_nvel_txto => 1 );
  
      --Se Parsea la Entrada a JSON Value
      apex_json.parse( v_json_in , p_request_json );
  
      --Inicializa el Objeto JSON
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.open_object('Respuesta');
      apex_json.write('RqUID' , sys_guid());
  
      begin
          --5. FechaPago
          v_fcha_pgo := apex_json.get_timestamp( p_values => v_json_in , p_path => 'FechaPago' , p_format => 'YYYYMMDD');
      exception
           when others then
                apex_json.write('NumeroEstadoRespuesta' , 30 );
                apex_json.write('DescripcionEstadoRespuesta' , 'Fecha de pago no valido, verifique que sea numerico y su formato en YYYYMMDD.' );
                apex_json.close_all;
                o_response_json := apex_json.get_clob_output;
                return;
      end;
  
      --Verifica si la Fecha de Pago no es Nulo
      if( v_fcha_pgo is null ) then
          apex_json.write('NumeroEstadoRespuesta' , 31 );
          apex_json.write('DescripcionEstadoRespuesta' , 'La Fecha de pago se encuentra vacio.' );
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end if;
  
      if( v_fcha_pgo < trunc(systimestamp) or v_fcha_pgo > trunc(systimestamp + 1)) then
          apex_json.write('NumeroEstadoRespuesta' , 32 );
          apex_json.write('DescripcionEstadoRespuesta' , 'Fecha de pago no valido, verifique que se encuentre dentro del rango.' );
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end if;
  
      --6 FormaPago
      v_frma_pgo := apex_json.get_varchar2( p_values => v_json_in , p_path => 'FormaPago');
  
      --Verifica si la Forma de Pago no es Nulo
      if( v_frma_pgo is null ) then
          apex_json.write('NumeroEstadoRespuesta' , 33 );
          apex_json.write('DescripcionEstadoRespuesta' , 'La Forma de pago se encuentra vacio.' );
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end if;
  
      --7. CodigoBanco
      v_cdgo_bnco := apex_json.get_varchar2( p_values => v_json_in , p_path => 'CodigoBanco');
  
      --Verifica si el Codigo Banco no es Nulo
      if( v_cdgo_bnco is null ) then
          apex_json.write('NumeroEstadoRespuesta' , 35 );
          apex_json.write('DescripcionEstadoRespuesta' , 'El Codigo banco se encuentra vacio.' );
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end if;
  
      --8. CodigoSucursal
      v_cdgo_scrsal := apex_json.get_varchar2( p_values => v_json_in , p_path => 'CodigoSucursal');
  
      --Verifica si el Codigo Sucursal no es Nulo
      if( v_cdgo_scrsal is null ) then
          apex_json.write('NumeroEstadoRespuesta' , 36 );
          apex_json.write('DescripcionEstadoRespuesta' , 'El Codigo sucursal se encuentra vacio.' );
          apex_json.close_all;
          o_response_json := apex_json.get_clob_output;
          return;
      end if;
  
      --4. FechaVencimiento
      v_fcha_vncmnto := apex_json.get_timestamp( p_values => v_json_in , p_path => 'FechaVencimiento' , p_format => 'YYYYMMDD');
  
      --3. ValorPago
      v_vlor_pago    := apex_json.get_number( p_path => 'ValorPago');
  
      v_nmro_dcmnto  := apex_json.get_number( p_path => 'NumeroDocumento');
  
      --Banco
      begin
          select id_bnco
            into v_id_bnco
            from df_c_bancos
           where cdgo_clnte = v_cdgo_clnte
             and cdgo_bnco  = v_cdgo_bnco;
      exception
           when no_data_found then
                apex_json.write('NumeroEstadoRespuesta' , 37 );
                apex_json.write('DescripcionEstadoRespuesta' , 'El Banco no existe en el sistema.' );
                apex_json.close_all;
                o_response_json := apex_json.get_clob_output;
                return;
      end;
  
      --Registra Recaudo Linea (RG Registrado)
      insert into re_g_recaudo_linea ( cdgo_clnte , id_impsto , id_impsto_sbmpsto , id_sjto_impsto , cdgo_rcdo_orgn_tpo
                                     , id_orgen , nmro_dcmnto , vlor_pgo , fcha_vncmnto , fcha_pgo
                                     , cdgo_scursal , id_bnco , cdgo_rcdo_estdo )
                              values ( v_cdgo_clnte , v_id_impsto , v_id_impsto_sbmpsto , v_id_sjto_impsto , v_cdgo_orgn
                                     , v_id_orgen , v_nmro_dcmnto , v_vlor_pago ,  v_fcha_vncmnto , v_fcha_pgo
                                     , v_cdgo_scrsal , v_id_bnco , 'RG' )
      returning id_rcdo_lnea
           into v_id_rcdo_lnea;
  
  
      pkg_re_recaudos.prc_rg_recaudo_control( p_cdgo_clnte        => v_cdgo_clnte
                                            , p_id_impsto         => v_id_impsto
                                            , p_id_impsto_sbmpsto => v_id_impsto_sbmpsto
                                            , p_id_bnco           => v_id_bnco
                                            , p_id_bnco_cnta      => 1
                                            , p_fcha_cntrol       => v_fcha_pgo
                                            , p_obsrvcion         => 'Pago web service #' || v_id_rcdo_lnea || ' valor ' || to_char( v_vlor_pago , 'FM$999G999G999G999G999G999G990')
                                            , p_cdgo_rcdo_orgen   => 'WS'
                                            , p_id_usrio          => 1
                                            , o_id_rcdo_cntrol    => v_id_rcdo_cntrol
                                            , o_cdgo_rspsta       => v_cdgo_rspsta
                                            , o_mnsje_rspsta      => v_mnsje_rspsta );
  
      pkg_re_recaudos.prc_rg_recaudo( p_cdgo_clnte         => v_cdgo_clnte
                                    , p_id_rcdo_cntrol     => v_id_rcdo_cntrol
                                    , p_id_sjto_impsto     => v_id_sjto_impsto
                                    , p_cdgo_rcdo_orgn_tpo => v_cdgo_orgn
                                    , p_id_orgen           => v_id_orgen
                                    , p_vlor               => v_vlor_pago
                                    , p_cdgo_rcdo_estdo    => 'RG'
                                    , p_cdgo_frma_pgo      => 'EF'
                                    , o_id_rcdo            => v_id_rcdo
                                    , o_cdgo_rspsta        => v_cdgo_rspsta
                                    , o_mnsje_rspsta       => v_mnsje_rspsta );
  
      update re_g_recaudo_linea
         set id_rcdo      = v_id_rcdo
       where id_rcdo_lnea = v_id_rcdo_lnea;
  
      apex_json.write('NumeroEstadoRespuesta' , 0 );
      apex_json.write('DescripcionEstadoRespuesta' , 'Pago registrado con exito.' );
      apex_json.write('IdPago' , v_id_rcdo_lnea );
      apex_json.close_all;
      o_response_json := apex_json.get_clob_output;
  
      v_mnsje := 'Fin del procedimiento ' || v_nmbre_up;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte => v_cdgo_clnte , p_id_impsto => null    , p_nmbre_up  => v_nmbre_up
                           , p_nvel_log   => v_nivel      , p_txto_log  => v_mnsje , p_nvel_txto => 1 );
  
  exception
      when others then
           apex_json.write('NumeroEstadoRespuesta' , 100 );
           apex_json.write('DescripcionEstadoRespuesta' , 'Transaccion fallida, intentelo mas tarde.' );
           apex_json.write('Error' , sqlerrm );
           apex_json.close_all;
           o_response_json := apex_json.get_clob_output;
           apex_json.free_output;
  end prc_rg_recaudo_pago_ws;*/

  /*
  * @Descripcion    : Metodo Consulta Recaudo Pago WebService
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */
  /*
  procedure prc_co_recaudo_pago_ws( p_request_json  in  clob
                                  , o_response_json out clob )
  as
      v_re_g_recaudo_linea sys_refcursor;
      v_fcha_pgo_incio     timestamp;
      v_fcha_pgo_fin       timestamp;
      v_cdgo_bnco          df_c_bancos.cdgo_bnco%type;
      v_cdgo_scrsal        varchar2(10);
  begin
  
      o_response_json := '{}';
  
      --Verifica si el JSON es Valido
      begin
          apex_json.parse(p_request_json);
      exception
           when others then
                raise_application_error( -20001 , 'JSON no valido, por favor verifique.' );
      end;
  
      --Inicializa el Objeto JSON
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.open_object('Respuesta');
      apex_json.write('RqUID' , sys_guid());
  
      begin
          --1. FechaPagoInicio
          v_fcha_pgo_incio := apex_json.get_timestamp( p_path => 'FechaPagoInicio' , p_format => 'YYYYMMDD');
      exception
           when others then
                apex_json.write('NumeroEstadoRespuesta' , 40 );
                apex_json.write('DescripcionEstadoRespuesta' , 'Fecha de pago inicio no valido, verifique que sea numerico y su formato en YYYYMMDD.' );
                apex_json.close_all;
                o_response_json := apex_json.get_clob_output;
                return;
      end;
  
      begin
          --1. FechaPagoFin
          v_fcha_pgo_fin := apex_json.get_timestamp( p_path => 'FechaPagoFin' , p_format => 'YYYYMMDD');
      exception
           when others then
                apex_json.write('NumeroEstadoRespuesta' , 41 );
                apex_json.write('DescripcionEstadoRespuesta' , 'Fecha de pago fin no valido, verifique que sea numerico y su formato en YYYYMMDD.' );
                apex_json.close_all;
                o_response_json := apex_json.get_clob_output;
                return;
      end;
  
      --3. CodigoSucursal
      v_cdgo_scrsal := apex_json.get_varchar2( p_path => 'CodigoSucursal');
  
      --4. CodigoBanco
      v_cdgo_bnco   := apex_json.get_varchar2( p_path => 'CodigoBanco');
  
      open v_re_g_recaudo_linea for select id_rcdo_lnea as "IdPago"
                                         , cdgo_clnte as "IdCliente"
                                         , nmbre_clnte as "Cliente"
                                         , id_impsto as "IdImpuesto"
                                         , nmbre_impsto as "Impuesto"
                                         , id_impsto_sbmpsto as "IdSubImpuesto"
                                         , nmbre_impsto_sbmpsto as "SubImpuesto"
                                         , cdgo_ean as "CodigoEan"
                                         , cdgo_bnco as "CodigoBanco"
                                         , nmbre_bnco as "Banco"
                                         , dscrpcion_rcdo_orgn_tpo as "CodigoDocumentoDestino"
                                         , nmro_dcmnto as "IdDocumento"
                                         , fcha_vncmnto as "FechaVencimiento"
                                         , fcha_pgo as "FechaPago"
                                         , cdgo_scursal as "CodigoSucursal"
                                         , fcha_rgstro as "FechaRegistroSistema"
                                      from v_re_g_recaudo_linea
                                     where cdgo_bnco    = v_cdgo_bnco
                                       and cdgo_scursal = v_cdgo_scrsal
                                       and trunc(fcha_pgo) between v_fcha_pgo_incio and v_fcha_pgo_fin;
  
    apex_json.write('Pagos' , v_re_g_recaudo_linea );
    apex_json.close_all;
    o_response_json := apex_json.get_clob_output;
  
  exception
      when others then
           apex_json.write('NumeroEstadoRespuesta' , 100 );
           apex_json.write('DescripcionEstadoRespuesta' , 'Transaccion fallida, intentelo mas tarde.' );
           apex_json.write('Error' , sqlerrm );
           apex_json.close_all;
           o_response_json := apex_json.get_clob_output;
           apex_json.free_output;
  end prc_co_recaudo_pago_ws;*/

  /*
  * @Descripcion  : Extrae el Valor de Atributo de Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_co_valor_asobancaria(p_tpo_rgstro           in varchar2,
                                    p_cdgo_tpo_asbncria    in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type,
                                    p_cdgo_atrbto_asbncria in re_d_atributos_asobancaria.cdgo_atrbto_asbncria%type,
                                    p_lnea                 in varchar2)
    return varchar2 is
    v_vlor         varchar2(4000);
    v_cdgo_dto_tpo et_d_datos_tipo.cdgo_dto_tpo%type;
  begin
  
    select substr(p_lnea,
                  crcter_incial,
                  ((crcter_fnal - crcter_incial) + 1)),
           cdgo_dto_tpo
      into v_vlor, v_cdgo_dto_tpo
      from re_d_cnfgrcnes_asbncria
     where tpo_rgstro = p_tpo_rgstro
       and cdgo_tpo_asbncria = p_cdgo_tpo_asbncria
       and cdgo_atrbto_asbncria = p_cdgo_atrbto_asbncria;
  
    return(case when v_cdgo_dto_tpo = 'F' then
           to_char(to_date(v_vlor, 'YYYYMMDD'), 'DD/MM/YYYY') when
           v_cdgo_dto_tpo = 'N' then to_char(to_number(v_vlor)) else
           v_vlor end);
  
  exception
    when others then
      return null;
  end fnc_co_valor_asobancaria;

  /*
  * @Descripcion  : Registra el Recaudo por Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudos_asobancaria(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                        p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                        p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                        p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                        p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type,
                                        p_cdgo_tpo_asbncria in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type,
                                        o_id_rcdo_cntrol    out re_g_recaudos_control.id_rcdo_cntrol%type,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2) as
    v_nvel      number;
    v_nmbre_up  sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_recaudos_asobancaria';
    e_null      exception;
    v_cdgo_ean  varchar2(30);
    v_fcha_rcdo re_g_recaudos.fcha_rcdo%type;
    v_rcdos     number := 0;
    v_vlor_ttal number := 0;
    v_vlor_pdl  df_c_definiciones_cliente.vlor%type;
  
    type c_dtos is table of re_g_recaudos_asobancaria%rowtype;
    v_dtos c_dtos := c_dtos();
  begin
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Marca el Archivo Como Procesado
    update et_g_procesos_carga
       set indcdor_prcsdo = 'S'
     where id_prcso_crga = p_id_prcso_crga;
  
    --Actualiza el Tipo de Asobancaria
    update re_g_recaudos_asobancaria
       set cdgo_tpo_asbncria = p_cdgo_tpo_asbncria,
           id_bnco           = p_id_bnco,
           id_bnco_cnta      = p_id_bnco_cnta
     where id_prcso_crga = p_id_prcso_crga;
  
    --Busca la Definicion - Permitir Pago Duplicado en el mismo lote
    v_vlor_pdl := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                  p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria,
                                                                  p_cdgo_dfncion_clnte        => 'PDL');
  
    for c_asbncria in (select id_rcdo_asbncria, nmero_lnea, tpo_rgstro, lnea
                         from re_g_recaudos_asobancaria
                        where id_prcso_crga = p_id_prcso_crga
                          and tpo_rgstro in ('01', '05', '06', '09')
                        order by nmero_lnea) loop
    
      if (c_asbncria.tpo_rgstro = '01') then
        --Extrae la Fecha de Recaudo
        begin
          v_fcha_rcdo := to_timestamp(pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                               p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                               p_cdgo_atrbto_asbncria => 'FCHA_RCDO',
                                                                               p_lnea                 => c_asbncria.lnea),
                                      'DD/MM/YYYY');
          --Verifica si Encontro la Fecha de Recaudo
          if (v_fcha_rcdo is null) then
            raise e_null;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible encontrar la fecha de recaudo del archivo, linea ' ||
                              c_asbncria.lnea || '.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      
      elsif (c_asbncria.tpo_rgstro = '05') then
        --Extrae el Codigo EAN
        begin
          v_cdgo_ean := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                 p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                 p_cdgo_atrbto_asbncria => 'CDGO_EAN',
                                                                 p_lnea                 => c_asbncria.lnea);
          --Verifica si Encontro el Codigo EAN
          if (v_cdgo_ean is null) then
            raise e_null;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible encontrar el codigo EAN del archivo, linea ' ||
                              c_asbncria.lnea || '.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      
        --Documentos
      elsif (c_asbncria.tpo_rgstro = '06') then
        declare
          v_id_impsto          df_c_impuestos.id_impsto%type;
          v_id_impsto_sbmpsto  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
          v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
          v_cdgo_clnte         df_s_clientes.cdgo_clnte%type;
          v_id_orgen           re_g_recaudos.id_orgen%type;
          v_cdgo_rcdo_orgn_tpo re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
          v_nmro_dcmnto        number;
          v_vlor_rcdo          number;
          v_id_rcdo            re_g_recaudos.id_rcdo%type;
          v_dplcdos            number;
          v_obsrvcion          varchar2(200);
        begin
        
          --Extrae el Numero del Documento
          v_nmro_dcmnto := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                    p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                    p_cdgo_atrbto_asbncria => 'NMRO_DCMNTO',
                                                                    p_lnea                 => c_asbncria.lnea);
        
          --Extrae el Valor del Recaudo
          v_vlor_rcdo := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                  p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                  p_cdgo_atrbto_asbncria => 'VLOR_RCDO',
                                                                  p_lnea                 => c_asbncria.lnea);
        
          --Cantidad de Recaudos
          v_rcdos := v_rcdos + 1;
        
          --Valor Total Recaudos
          v_vlor_ttal := v_vlor_ttal + v_vlor_rcdo;
        
          --Verifica el Documento de Pago
          pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => v_cdgo_ean,
                                              p_nmro_dcmnto        => v_nmro_dcmnto,
                                              p_vlor               => v_vlor_rcdo,
                                              p_fcha_rcdo          => v_fcha_rcdo,
                                              p_indcdor_vlda_pgo   => true,
                                              o_cdgo_rcdo_orgn_tpo => v_cdgo_rcdo_orgn_tpo,
                                              o_id_orgen           => v_id_orgen,
                                              o_cdgo_clnte         => v_cdgo_clnte,
                                              o_id_impsto          => v_id_impsto,
                                              o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto,
                                              o_id_sjto_impsto     => v_id_sjto_impsto,
                                              o_cdgo_rspsta        => o_cdgo_rspsta,
                                              o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            v_dtos.extend;
            v_dtos(v_dtos.count).id_rcdo_asbncria := c_asbncria.id_rcdo_asbncria;
            v_dtos(v_dtos.count).mnsje_rspsta := o_mnsje_rspsta;
            continue;
          end if;
        
          --Verifica si el Cliente Corresponde al del Recaudo
          if (v_cdgo_clnte <> p_cdgo_clnte) then
            v_dtos.extend;
            v_dtos(v_dtos.count).id_rcdo_asbncria := c_asbncria.id_rcdo_asbncria;
            v_dtos(v_dtos.count).mnsje_rspsta := 'El documento de pago #' ||
                                                 v_nmro_dcmnto ||
                                                 ', no corresponde al cliente.';
            continue;
          end if;
        
          --Verifica si Existe el Recaudo Control
          if (o_id_rcdo_cntrol is null) then
            --Registra el Recaudo Control
            pkg_re_recaudos.prc_rg_recaudo_control(p_cdgo_clnte        => p_cdgo_clnte,
                                                   p_id_impsto         => v_id_impsto,
                                                   p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                                   p_id_bnco           => p_id_bnco,
                                                   p_id_bnco_cnta      => p_id_bnco_cnta,
                                                   p_fcha_cntrol       => v_fcha_rcdo,
                                                   p_obsrvcion         => p_obsrvcion,
                                                   p_cdgo_rcdo_orgen   => 'AC',
                                                   p_id_usrio          => p_id_usrio,
                                                   p_id_prcso_crga     => p_id_prcso_crga,
                                                   o_id_rcdo_cntrol    => o_id_rcdo_cntrol,
                                                   o_cdgo_rspsta       => o_cdgo_rspsta,
                                                   o_mnsje_rspsta      => o_mnsje_rspsta);
          
            --Verifica si Hubo Error
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            end if;
          end if;
        
          v_dtos.extend;
          v_dtos(v_dtos.count).id_rcdo_asbncria := c_asbncria.id_rcdo_asbncria;
        
          --Verifica si el Recaudo Esta Duplicado
          select count(*)
            into v_dplcdos
            from re_g_recaudos
           where id_rcdo_cntrol = o_id_rcdo_cntrol
             and cdgo_rcdo_orgn_tpo = v_cdgo_rcdo_orgn_tpo
             and id_orgen = v_id_orgen;
        
          --Verifica si se puede Incluir el Recaudo en el mismo Lote
          if (v_vlor_pdl in ('N', '-1') and v_dplcdos > 0) then
            v_dtos.extend;
            v_dtos(v_dtos.count).id_rcdo_asbncria := c_asbncria.id_rcdo_asbncria;
            v_dtos(v_dtos.count).mnsje_rspsta := 'El documento de pago #' ||
                                                 v_nmro_dcmnto ||
                                                 ', se encuentra encuentra duplicado en el lote.';
            continue;
          end if;
        
          v_obsrvcion := (case
                           when v_dplcdos > 0 then
                            'Recaudo Duplicado, Documento #' || v_nmro_dcmnto
                         end);
        
          --Registra Recaudo Incluido
          pkg_re_recaudos.prc_rg_recaudo(p_cdgo_clnte         => p_cdgo_clnte,
                                         p_id_rcdo_cntrol     => o_id_rcdo_cntrol,
                                         p_id_sjto_impsto     => v_id_sjto_impsto,
                                         p_cdgo_rcdo_orgn_tpo => v_cdgo_rcdo_orgn_tpo,
                                         p_id_orgen           => v_id_orgen,
                                         p_vlor               => v_vlor_rcdo,
                                         p_obsrvcion          => v_obsrvcion,
                                         p_cdgo_frma_pgo      => 'EF',
                                         o_id_rcdo            => v_id_rcdo,
                                         o_cdgo_rspsta        => o_cdgo_rspsta,
                                         o_mnsje_rspsta       => o_mnsje_rspsta);
        
          --Verifica si Hubo Error
          if (o_cdgo_rspsta <> 0) then
            v_dtos(v_dtos.count).mnsje_rspsta := o_mnsje_rspsta;
            continue;
          end if;
        
          --Registro Procesados
          v_dtos(v_dtos.count).indcdor_rlzdo := 'S';
          v_dtos(v_dtos.count).mnsje_rspsta := nvl(v_obsrvcion, 'Procesado');
          v_dtos(v_dtos.count).id_rcdo := v_id_rcdo;
        end;
      
        --Totalizados
      elsif (c_asbncria.tpo_rgstro = '09') then
        declare
          v_ttal_rgstros_rcdo_archvo number;
          v_vlot_ttal_rcdo_archvo    number;
        begin
        
          --Extrae el Total de Registro del Archivo
          v_ttal_rgstros_rcdo_archvo := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                                 p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                                 p_cdgo_atrbto_asbncria => 'TTAL_RGSTROS_RCDO_ARCHVO',
                                                                                 p_lnea                 => c_asbncria.lnea);
        
          --Extrae el Valor Total de Recaudos del Archivo
          v_vlot_ttal_rcdo_archvo := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                              p_cdgo_tpo_asbncria    => p_cdgo_tpo_asbncria,
                                                                              p_cdgo_atrbto_asbncria => 'VLOT_TTAL_RCDO_ARCHVO',
                                                                              p_lnea                 => c_asbncria.lnea);
        
          --Verifica si el Archivo Tiene Diferente Numeros de Recaudos
          if (v_ttal_rgstros_rcdo_archvo <> v_rcdos) then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. La cantidad de los registros no corresponde al archivo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
        
          --Verifica si el Archivo Tiene Diferente Valor Total
          if (v_vlot_ttal_rcdo_archvo <> v_vlor_ttal) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El valor total de los registros no corresponde al archivo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          end if;
        end;
      end if;
    end loop;
  
    --Verifica si no Hay Recaudos
    if (v_rcdos = 0) then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible procesar el archivo asobancaria, ya que no contienen recaudos por procesar.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Actualiza los Datos de la Asobancaria
    forall i in 1 .. v_dtos.count
      update re_g_recaudos_asobancaria
         set id_rcdo       = v_dtos(i).id_rcdo,
             indcdor_rlzdo = nvl(v_dtos(i).indcdor_rlzdo, 'N'),
             mnsje_rspsta  = v_dtos(i).mnsje_rspsta
       where id_rcdo_asbncria = v_dtos(i).id_rcdo_asbncria;
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Archivo procesado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 7;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible procesar el archivo asobancaria, intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_rg_recaudos_asobancaria;

  /*
  * @Descripcion  : Muestra los Datos de la Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_co_datos_asobancaria(p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type,
                                    p_cdgo_tpo_asbncria in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type default null)
    return g_asbncria
    pipelined is
    v_cdgo_ean  varchar2(30);
    v_fcha_rcdo re_g_recaudos.fcha_rcdo%type;
  begin
  
    for c_asbncria in (select /*+ RESULT_CACHE */
                        a.id_rcdo_asbncria,
                        a.id_prcso_crga,
                        a.tpo_rgstro,
                        a.lnea,
                        a.id_rcdo,
                        a.indcdor_rlzdo,
                        nvl(p_cdgo_tpo_asbncria, a.cdgo_tpo_asbncria) as cdgo_tpo_asbncria,
                        a.mnsje_rspsta,
                        a.nmero_lnea,
                        a.id_bnco,
                        a.id_bnco_cnta
                         from re_g_recaudos_asobancaria a
                        where id_prcso_crga = p_id_prcso_crga
                          and tpo_rgstro in ('01', '05', '06')
                        order by a.nmero_lnea) loop
    
      --Fecha de Recaudo
      if (c_asbncria.tpo_rgstro = '01') then
        --Extrae la Fecha de Recaudo
        v_fcha_rcdo := to_timestamp(pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                             p_cdgo_tpo_asbncria    => c_asbncria.cdgo_tpo_asbncria,
                                                                             p_cdgo_atrbto_asbncria => 'FCHA_RCDO',
                                                                             p_lnea                 => c_asbncria.lnea),
                                    'DD/MM/YYYY');
        --Codigo EAN
      elsif (c_asbncria.tpo_rgstro = '05') then
        --Extrae el Codigo EAN
        v_cdgo_ean := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                               p_cdgo_tpo_asbncria    => c_asbncria.cdgo_tpo_asbncria,
                                                               p_cdgo_atrbto_asbncria => 'CDGO_EAN',
                                                               p_lnea                 => c_asbncria.lnea);
        --Documentos
      elsif (c_asbncria.tpo_rgstro = '06') then
      
        declare
          v_cdgo_rspsta  number;
          v_mnsje_rspsta varchar2(4000);
          r_asbncria     t_asbncria;
        begin
        
          --Linea del Archivo
          --Indicador Realizado
          --Tipo de Asobancaria
          --Mensaje de Respuesta
          --Id Recaudo
          --Codigo EAN
          --Fecha de Recaudo
          r_asbncria := t_asbncria(id_rcdo_asbncria  => c_asbncria.id_rcdo_asbncria,
                                   id_prcso_crga     => c_asbncria.id_prcso_crga,
                                   nmero_lnea        => c_asbncria.nmero_lnea,
                                   indcdor_rlzdo     => c_asbncria.indcdor_rlzdo,
                                   cdgo_tpo_asbncria => c_asbncria.cdgo_tpo_asbncria,
                                   mnsje_rspsta      => c_asbncria.mnsje_rspsta,
                                   id_rcdo           => c_asbncria.id_rcdo,
                                   cdgo_ean          => v_cdgo_ean,
                                   fcha_rcdo         => v_fcha_rcdo,
                                   id_bnco           => c_asbncria.id_bnco,
                                   id_bnco_cnta      => c_asbncria.id_bnco_cnta);
        
          --Extrae el Numero del Documento
          r_asbncria.nmro_dcmnto := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                             p_cdgo_tpo_asbncria    => c_asbncria.cdgo_tpo_asbncria,
                                                                             p_cdgo_atrbto_asbncria => 'NMRO_DCMNTO',
                                                                             p_lnea                 => c_asbncria.lnea);
        
          --Extrae el Valor del Recaudo
          r_asbncria.vlor_rcdo := pkg_re_recaudos.fnc_co_valor_asobancaria(p_tpo_rgstro           => c_asbncria.tpo_rgstro,
                                                                           p_cdgo_tpo_asbncria    => c_asbncria.cdgo_tpo_asbncria,
                                                                           p_cdgo_atrbto_asbncria => 'VLOR_RCDO',
                                                                           p_lnea                 => c_asbncria.lnea);
        
          --Extrae los Datos del Documento
          pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => v_cdgo_ean,
                                              p_nmro_dcmnto        => r_asbncria.nmro_dcmnto,
                                              p_vlor               => r_asbncria.vlor_rcdo,
                                              p_fcha_rcdo          => v_fcha_rcdo,
                                              o_cdgo_rcdo_orgn_tpo => r_asbncria.cdgo_rcdo_orgn_tpo,
                                              o_id_orgen           => r_asbncria.id_orgen,
                                              o_cdgo_clnte         => r_asbncria.cdgo_clnte,
                                              o_id_impsto          => r_asbncria.id_impsto,
                                              o_id_impsto_sbmpsto  => r_asbncria.id_impsto_sbmpsto,
                                              o_id_sjto_impsto     => r_asbncria.id_sjto_impsto,
                                              o_cdgo_rspsta        => v_cdgo_rspsta,
                                              o_mnsje_rspsta       => v_mnsje_rspsta);
        
          pipe row(r_asbncria);
        end;
      end if;
    end loop;
  end fnc_co_datos_asobancaria;

  /*
  * @Descripcion  : Metodo Validar Factura Soap
  * @Creacion     : 01/08/2018
  * @Modificacion : 01/08/2018
  */

  procedure prc_vl_factura_soap(p_request_json in clob,
                                o_response     out varchar2) as
    v_cdgo_ean     varchar2(30);
    v_nmro_dcmnto  number;
    v_vlor_rcdo    number;
    v_fcha_vncmnto date;
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);
  begin
  
    --raise_application_error(-20326,'might not change '||'emp table during nonworking hours');
  
    --1. Codigo EAN
    v_cdgo_ean := json_value(p_request_json, '$.codEan');
  
    --2. Numero de Documento
    begin
      v_nmro_dcmnto := to_number(json_value(p_request_json, '$.nmroDcmnto'));
    exception
      when others then
        o_response := '101+Numero de documento no valido, verifique que sea un dato numerico.';
        return;
    end;
  
    --3. Valor del Recaudo
    begin
      v_vlor_rcdo := to_number(json_value(p_request_json, '$.vlorPago'));
    exception
      when others then
        o_response := '102+Monto a pagar no valido, verifique que sea un dato numerico.';
        return;
    end;
  
    --4. Fecha de Recaudo
    begin
      v_fcha_vncmnto := to_date(json_value(p_request_json, '$.fchaVncmnto'),
                                'YYYYMMDD');
    exception
      when others then
        o_response := '103+Fecha de vencimiento no valida, verifique que sea un dato numerico o se encuentre en formato YYYYMMDD.';
        return;
    end;
  
    --Verifica que los Campos no esten Nulos
    if (v_cdgo_ean is null or v_nmro_dcmnto is null or v_vlor_rcdo is null or
       v_fcha_vncmnto is null) then
      o_response := '104+Debe diligenciar todos los campos.';
      return;
    end if;
  
    declare
      v_cdgo_rcdo_orgn_tpo re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
      v_id_orgen           re_g_recaudos.id_orgen%type;
      v_cdgo_clnte         df_s_clientes.cdgo_clnte%type;
      v_id_impsto          df_c_impuestos.id_impsto%type;
      v_id_impsto_sbmpsto  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
      v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
    begin
    
      --Valida el Documento de Recaudo
      pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => v_cdgo_ean,
                                          p_nmro_dcmnto        => v_nmro_dcmnto,
                                          p_vlor               => v_vlor_rcdo,
                                          p_fcha_vncmnto       => v_fcha_vncmnto,
                                          p_indcdor_vlda_pgo   => true,
                                          o_cdgo_rcdo_orgn_tpo => v_cdgo_rcdo_orgn_tpo,
                                          o_id_orgen           => v_id_orgen,
                                          o_cdgo_clnte         => v_cdgo_clnte,
                                          o_id_impsto          => v_id_impsto,
                                          o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto,
                                          o_id_sjto_impsto     => v_id_sjto_impsto,
                                          o_cdgo_rspsta        => v_cdgo_rspsta,
                                          o_mnsje_rspsta       => v_mnsje_rspsta);
    end;
  
    if (v_cdgo_rspsta <> 0) then
      o_response := '105+Recibo no valido para procesar.';
      return;
    end if;
  
    o_response := '100+Ok.';
  
    /*exception
    when others then
         raise_application_error( -20001 , sqlerrm );*/
  end prc_vl_factura_soap;

  procedure prc_rg_recaudo_soap(p_request_json in clob,
                                o_response     out varchar2) as
  begin
    o_response := '0+Ok.';
  end prc_rg_recaudo_soap;

  procedure prc_rg_pago_linea(p_cdgo_clnte   in number,
                              p_id_impsto    in number,
                              p_id_dcmnto    in number,
                              p_id_trcro     in number,
                              p_vgncia_prdo  in clob,
                              o_json         out json_object_t,
                              o_cdgo_rspsta  out number,
                              o_mnsje_rspsta out varchar2) as
  
    v_valorneto number := 0;
  
    json_data              json_object_t := new json_object_t();
    cliente                json_object_t := new json_object_t();
    identification         json_object_t := new json_object_t();
    fullname               json_object_t := new json_object_t();
    refcuponpago           json_object_t := new json_object_t();
    paymentresume          json_object_t := new json_object_t();
    externalsystemuserinfo json_object_t := new json_object_t();
    paymentconcept         json_object_t := new json_object_t();
    paymentconcepts        json_array_t := new json_array_t();
  
    v_email               varchar2(1000);
    v_cdgo_idntfccion_tpo varchar2(3);
    v_idntfccion          varchar2(100);
    v_prmer_nmbre         varchar2(100);
    v_sgndo_nmbre         varchar2(100);
    v_prmer_aplldo        varchar2(100);
    v_sgndo_aplldo        varchar2(100);
    v_tlfno               number;
    v_cllar               number;
    v_drccion_ntfccion    varchar2(100);
  
    jsonprueba clob;
  
    --JOSE
    v_result           clob;
    v_subscription_key varchar2(100);
    v_contrato         varchar2(100);
    v_password         varchar2(100);
    v_tokenAuth        varchar2(500);
    v_body             clob;
  
  begin
  
    begin
      select a.email,
             a.cdgo_idntfccion_tpo,
             a.idntfccion,
             a.prmer_nmbre,
             a.sgndo_nmbre,
             a.prmer_aplldo,
             a.sgndo_aplldo,
             a.tlfno,
             a.cllar,
             a.drccion_ntfccion
        into v_email,
             v_cdgo_idntfccion_tpo,
             v_idntfccion,
             v_prmer_nmbre,
             v_sgndo_nmbre,
             v_prmer_aplldo,
             v_sgndo_aplldo,
             v_tlfno,
             v_cllar,
             v_drccion_ntfccion
        from si_c_terceros a
       where cdgo_clnte = p_cdgo_clnte
         and id_trcro = p_id_trcro;
    
    exception
      when others then
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'No se pudo obtener los datos del responsable';
    end;
  
    json_data.put('ApplicationToken',
                  'D7E64F46-D444-4429-BF76-E3FB21F3B5FB');
  
    --Objeto Identification
    identification.put('TypeCode', v_cdgo_idntfccion_tpo);
    identification.put('Number', v_idntfccion);
  
    --Objeto FullName
    fullname.put('FirstName', v_prmer_nmbre);
    fullname.put('MiddleName', v_sgndo_nmbre);
    fullname.put('LastName', v_prmer_aplldo);
    fullname.put('SecondLastName', v_sgndo_aplldo);
  
    --Objeto Client
    cliente.put('Email', v_email);
    cliente.put('Identification', identification);
    cliente.put('FullName', fullname);
    cliente.put('Phone1', v_tlfno);
    cliente.put('Phone2', v_cllar);
    cliente.put('Phone3', '');
    cliente.put('Address1', v_drccion_ntfccion);
    cliente.put('Address2', '');
    cliente.put('Address3', '');
  
    json_data.put('Client', cliente);
    json_data.put('RefCuponPago', '111');
  
    begin
    
      for vgncia_prdo in (select vgncia, prdo, id_orgen
                            from json_table(p_vgncia_prdo,
                                            '$[*].VGNCIA_PRDO'
                                            columns(vgncia varchar2 path
                                                    '$.vgncia',
                                                    prdo varchar2 path
                                                    '$.prdo',
                                                    id_orgen varchar2 path
                                                    '$.id_orgen'))) loop
      
        declare
        
          paymentconcept json_object_t := new json_object_t();
        
        begin
        
          for cncpto in (select *
                           from v_gf_g_movimientos_detalle a
                          where a.id_orgen = vgncia_prdo.id_orgen) loop
          
            --Objeto PaymentConcepts
            paymentconcept.put('ReferenceNumber', cncpto.id_mvmnto_dtlle);
            paymentconcept.put('Description', cncpto.dscrpcion_cncpto_csdo);
            paymentconcept.put('Value', cncpto.vlor_dbe);
            paymentconcept.put('VAT', 0);
          
            paymentconcepts.append(paymentconcept);
          
            v_valorneto := v_valorneto + cncpto.vlor_dbe;
          
          end loop;
        
        end;
      
      end loop;
    
    end;
  
    json_data.put('PaymentConcepts', paymentconcepts);
  
    --Objeto PaymentResume
    paymentresume.put('ConceptoGeneral', 'Concepto General');
    paymentresume.put('ValorNeto', v_valorneto);
    paymentresume.put('IVATotal', 0);
    paymentresume.put('TotalPagar', v_valorneto);
  
    json_data.put('PaymentResume', paymentresume);
  
    --Objeto ExternalSystemUserInfo
    externalsystemuserinfo.put('UserId', 'jvargas');
    externalsystemuserinfo.put('UserName', 'jvargas');
    externalsystemuserinfo.put('ClientIP', '192.168.1.1');
  
    json_data.put('ExternalSystemUserInfo', externalsystemuserinfo);
    json_data.put('indRedireccionManual', true);
  
    --o_json := json_data;
  
    --Jose
    v_subscription_key := 'b75ce036fb20464a9235672dd36d1fe8';
    v_contrato         := 'D7E64F46-D444-4429-BF76-E3FB21F3B5FB';
    v_password         := 'V4L13dUP4RmUn1c1P10';
    v_tokenAuth        := 'Basic' ||
                          utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(v_contrato || ':' ||
                                                                                                v_password)));
  
    v_body := json_data.to_clob;
  
    -- HEADER
    apex_web_service.g_request_headers(1).name := 'Subscription-Key';
    apex_web_service.g_request_headers(1).value := v_subscription_key;
    apex_web_service.g_request_headers(2).name := 'Content-Type';
    apex_web_service.g_request_headers(2).value := 'application/json';
    apex_web_service.g_request_headers(3).name := 'Contrato';
    apex_web_service.g_request_headers(3).value := v_contrato;
    apex_web_service.g_request_headers(4).name := 'Authorization';
    apex_web_service.g_request_headers(4).value := v_tokenAuth;
    apex_web_service.g_request_headers(5).name := 'Referrer';
    apex_web_service.g_request_headers(5).value := '192.168.11.34';
  
    begin
      v_result := apex_web_service.make_rest_request(p_url         => 'https://pol-qa.azure-api.net/Transactions/StartTransaction',
                                                     p_http_method => 'GET',
                                                     p_body        => v_body,
                                                     p_wallet_path => 'file:/u01/app/oracle/product/18.0.0/dbhome_1/wallet',
                                                     p_wallet_pwd  => 'Informatica2020_');
    
      o_json := new json_object_t(v_result);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al llamar al servicio ' || sqlerrm;
    end;
  
  end prc_rg_pago_linea;

  procedure prc_rg_reversion_recaudo_log(p_id_scncia_rvrsa in gf_g_recaudo_reversa.id_rcdo_rvrsa%type,
                                         p_nmbre_tbla      in gf_g_recaudo_reversa_fla.nmbre_tbla%type,
                                         p_id_orgen        in gf_g_recaudo_reversa_fla.id_orgen%type,
                                         p_fla             in gf_g_recaudo_reversa_fla.fla%type,
                                         o_mnsje_rspsta    out varchar2) as
  begin
  
    insert into gf_g_recaudo_reversa_fla
      (id_id_rcdo_rvrsa_fla, id_rcdo_rvrsa, nmbre_tbla, id_orgen, fla)
    values
      (sq_gf_g_rcdo_rvrsa_fla.nextval,
       p_id_scncia_rvrsa,
       p_nmbre_tbla,
       p_id_orgen,
       p_fla);
  
  exception
    when others then
      o_mnsje_rspsta := 'prc_rg_reversion_recaudo_log-->' || sqlerrm;
  end;

  procedure prc_rg_reversar_recaudo(p_cdgo_clnte   in number,
                                    p_id_usrio     in gf_g_recaudo_reversa.id_usrio%type,
                                    p_nmro_dcmnto  in number,
                                    p_id_rcdo      in number,
                                    p_dscrpcion    in gf_g_recaudo_reversa.dscrpcion%type,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
  
    v_cntdad_rcdos          number;
    v_vlor_rcdos            number;
    v_id_sldo_fvor          number;
    v_id_sldo_fvor_slctud   number;
    v_cntdad_mvmntos        number;
    v_id_rcdo               number;
    v_nvel                  number;
    v_indcdor_nrmlzar_crtra varchar2(1);
  
    v_re_g_documentos re_g_documentos%rowtype;
    v_re_g_recaudo    v_re_g_recaudos%rowtype;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_reversar_recaudo';
  
    v_id_rcdo_rvrsa number;
    v_mnsje_rspsta  varchar2(1000);
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si Existe el Documento de Pago
    begin
      select a.*
        into v_re_g_documentos
        from re_g_documentos a
       where nmro_dcmnto = p_nmro_dcmnto
         and INDCDOR_PGO_APLCDO = 'S'
         and cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          p_nmro_dcmnto || ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Verifica si el documento tiene un Recaudo
    begin
      select a.*
        into v_re_g_recaudo
        from v_re_g_recaudos a
       where a.id_rcdo = p_id_rcdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          p_nmro_dcmnto || ', no tiene un recaudo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se valida que el recaudo no venga de un archivo asobancaria o de web service
    if v_re_g_recaudo.cdgo_rcdo_orgen_cntrol in ('WS') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. La reversion aplica solo para pagos manuales';
      rollback;
      return;
    end if;
  
    --Se valida que no existan movimientos posteriores a la aplicacion del recaudo
    begin
    
      select count(*)
        into v_cntdad_mvmntos
        from v_gf_g_movimientos_detalle a
       where a.id_sjto_impsto = v_re_g_recaudo.id_sjto_impsto
         and a.id_orgen <> v_re_g_recaudo.id_rcdo
         and a.fcha_mvmnto >
             (select max(b.fcha_mvmnto) as fcha_mvmnto_mxma
                from gf_g_movimientos_detalle b
               where b.cdgo_mvmnto_orgn = 'RE'
                 and b.id_orgen = a.id_orgen);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo obtener la cantidad de movimientos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    if v_cntdad_mvmntos > 0 then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No se pudo reversar el pago, se encontraron movimientos posteriores a la fecha del recaudo';
      rollback;
      return;
    end if;
  
    -- Se registra en el maestro del log de lo reversado - NLCZ
    v_id_rcdo_rvrsa := sq_gf_g_recaudo_reversa.nextval;
    begin
      insert into gf_g_recaudo_reversa
        (id_rcdo_rvrsa,
         nmro_dcmnto,
         id_usrio,
         fcha_rvrsa,
         id_rcdo,
         dscrpcion)
      values
        (v_id_rcdo_rvrsa,
         p_nmro_dcmnto,
         p_id_usrio,
         sysdate,
         v_re_g_recaudo.id_rcdo,
         p_dscrpcion);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '.0. No se pudo registrar el maestro del log para documento: ' ||
                          p_nmro_dcmnto || ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
    --Se elimina los movimientos de origen recaudo (RE)
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_MVMNTO_DTLLE llave,
                          json_object('ID_MVMNTO_DTLLE' VALUE
                                      ID_MVMNTO_DTLLE,
                                      'ID_MVMNTO_FNCRO' VALUE ID_MVMNTO_FNCRO,
                                      'CDGO_MVMNTO_ORGN' VALUE
                                      CDGO_MVMNTO_ORGN,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'CDGO_MVMNTO_TPO' VALUE CDGO_MVMNTO_TPO,
                                      'VGNCIA' VALUE VGNCIA,
                                      'ID_PRDO' VALUE ID_PRDO,
                                      'CDGO_PRDCDAD' VALUE CDGO_PRDCDAD,
                                      'FCHA_MVMNTO' VALUE FCHA_MVMNTO,
                                      'ID_CNCPTO' VALUE ID_CNCPTO,
                                      'ID_CNCPTO_CSDO' VALUE ID_CNCPTO_CSDO,
                                      'VLOR_DBE' VALUE VLOR_DBE,
                                      'VLOR_HBER' VALUE VLOR_HBER,
                                      'ID_MVMNTO_DTLLE_BSE' VALUE
                                      ID_MVMNTO_DTLLE_BSE,
                                      'ACTVO' VALUE ACTVO,
                                      'GNRA_INTRES_MRA' VALUE GNRA_INTRES_MRA,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'ID_IMPSTO_ACTO_CNCPTO' VALUE
                                      ID_IMPSTO_ACTO_CNCPTO) texto
                     from gf_g_movimientos_detalle
                    where cdgo_mvmnto_orgn = 'RE'
                      and id_orgen = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_movimientos_detalle',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_movimientos_detalle ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_movimientos_detalle
       where cdgo_mvmnto_orgn = 'RE'
         and id_orgen = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo reversar los movimientos' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    if v_re_g_recaudo.id_sldo_fvor is not null then
    
      --Se valida si el saldo a favor fue reconocido
      begin
        select a.id_sldo_fvor
          into v_id_sldo_fvor
          from gf_g_saldos_favor a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_sldo_fvor = v_re_g_recaudo.id_sldo_fvor
           and a.indcdor_rcncdo = 'S';
        --or a.indcdor_rcncdo = 'N';
      exception
        when no_data_found then
          null;
        
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Problemas al consultar el estado del saldo a favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          rollback;
          return;
      end;
    
      if v_id_sldo_fvor is not null then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se puede reversar el recaudo porque se reconocio el saldo a favor que genero el mismo';
        rollback;
        return;
      end if;
    
      --Se valida si el saldo a favor se encuentra en una solicitud abierta
      begin
        select a.id_sldo_fvor_slctud
          into v_id_sldo_fvor_slctud
          from gf_g_saldos_favor_solicitud a
          join wf_g_instancias_flujo b
            on a.id_instncia_fljo = b.id_instncia_fljo
          join gf_g_sldos_fvor_slctud_dtll c
            on a.id_sldo_fvor_slctud = c.id_sldo_fvor_slctud
           and c.id_sldo_fvor = v_re_g_recaudo.id_sldo_fvor
           and b.estdo_instncia = 'INICIADA';
      exception
        when no_data_found then
          null;
        
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Problemas al consultar si el saldo a favor se encuentra en una solicitud';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          rollback;
          return;
      end;
    
      if v_id_sldo_fvor_slctud is not null then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se puede reversar el recaudo debido a que se esta proyectando el saldo a favor que se genero por el recuado';
        rollback;
        return;
      end if;
    
    end if;
  
    --Se obtiene la cantidad de recaudos agregados al recaudo control y el valor total de recuados
    begin
    
      select a.cntdad_rcdos, a.vlor_rcdos
        into v_cntdad_rcdos, v_vlor_rcdos
        from re_g_recaudos_control a
       where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol;
    
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Obtener la cantidad de recaudos y valor total de los recuados' ||
                          ' Erro: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se actualiza el recaudo control
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_RCDO_CNTROL llave,
                          json_object('ID_RCDO_CNTROL' VALUE ID_RCDO_CNTROL,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_BNCO' VALUE ID_BNCO,
                                      'ID_BNCO_CNTA' VALUE ID_BNCO_CNTA,
                                      'FCHA_CNTROL' VALUE FCHA_CNTROL,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'CNTDAD_RCDOS' VALUE CNTDAD_RCDOS,
                                      'VLOR_RCDOS' VALUE VLOR_RCDOS,
                                      'CDGO_RCDO_ORGEN' VALUE CDGO_RCDO_ORGEN,
                                      'ID_PRCSO_CRGA' VALUE ID_PRCSO_CRGA,
                                      'ID_USRIO' VALUE ID_USRIO,
                                      'FCHA_RGSTRO' VALUE FCHA_RGSTRO) texto
                     from re_g_recaudos_control
                    where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_recaudos_control',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_recaudos_control ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      v_cntdad_rcdos := v_cntdad_rcdos - 1;
      v_vlor_rcdos   := v_vlor_rcdos - v_re_g_recaudo.vlor;
    
      update re_g_recaudos_control a
         set a.vlor_rcdos = v_vlor_rcdos, a.cntdad_rcdos = v_cntdad_rcdos
       where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol;
    
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Actualizar la cantidad de recaudos y valor total de los recuados' ||
                          ' Erro: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Actualizamos Documento
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_DCMNTO llave,
                          json_object('ID_DCMNTO' VALUE ID_DCMNTO,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'NMRO_DCMNTO' VALUE NMRO_DCMNTO,
                                      'CDGO_DCMNTO_TPO' VALUE CDGO_DCMNTO_TPO,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'NMRO_CTA' VALUE NMRO_CTA,
                                      'FCHA_DCMNTO' VALUE FCHA_DCMNTO,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'VLOR_TTAL_DBE' VALUE VLOR_TTAL_DBE,
                                      'VLOR_TTAL_HBER' VALUE VLOR_TTAL_HBER,
                                      'VLOR_TTAL' VALUE VLOR_TTAL,
                                      'INDCDOR_PGO_APLCDO' VALUE
                                      INDCDOR_PGO_APLCDO,
                                      'VLOR_TTAL_DCMNTO' VALUE
                                      VLOR_TTAL_DCMNTO,
                                      'ID_DCMNTO_LTE' VALUE ID_DCMNTO_LTE,
                                      'INDCDOR_ENTRNO' VALUE INDCDOR_ENTRNO,
                                      'DRCCION' VALUE DRCCION,
                                      'CDGO_PSTAL' VALUE CDGO_PSTAL,
                                      'ID_RCDO_ULTMO' VALUE ID_RCDO_ULTMO) texto
                     from re_g_documentos
                    where id_dcmnto = v_re_g_documentos.id_dcmnto) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_documentos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_documentos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      update re_g_documentos
         set indcdor_pgo_aplcdo = 'N'
       where id_dcmnto = v_re_g_documentos.id_dcmnto;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo actualizar el estado del documento' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se obtiene el ultimo recaudo
    begin
      select a.id_rcdo
        into v_id_rcdo
        from re_g_recaudos a
        join re_g_recaudos_control b
          on a.id_rcdo_cntrol = b.id_rcdo_cntrol
       where b.cdgo_clnte = p_cdgo_clnte
         and b.id_impsto = v_re_g_recaudo.id_impsto
         and b.id_impsto_sbmpsto = v_re_g_recaudo.id_impsto_sbmpsto
         and a.id_sjto_impsto = v_re_g_recaudo.id_sjto_impsto
         and a.cdgo_rcdo_estdo = 'AP'
         and a.cdgo_rcdo_orgn_tpo = 'DC'
         and a.id_rcdo <> v_re_g_recaudo.id_rcdo
       order by fcha_rcdo desc
       fetch first 1 rows only;
    exception
      when no_data_found then
        null;
    end;
  
    -- Actualizamos todos los documentos cuyo ID recaudo ultimo ...
    -- referencien al Recaudo a reversar
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_DCMNTO llave,
                          json_object('ID_DCMNTO' VALUE ID_DCMNTO,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'NMRO_DCMNTO' VALUE NMRO_DCMNTO,
                                      'CDGO_DCMNTO_TPO' VALUE CDGO_DCMNTO_TPO,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'NMRO_CTA' VALUE NMRO_CTA,
                                      'FCHA_DCMNTO' VALUE FCHA_DCMNTO,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'VLOR_TTAL_DBE' VALUE VLOR_TTAL_DBE,
                                      'VLOR_TTAL_HBER' VALUE VLOR_TTAL_HBER,
                                      'VLOR_TTAL' VALUE VLOR_TTAL,
                                      'INDCDOR_PGO_APLCDO' VALUE
                                      INDCDOR_PGO_APLCDO,
                                      'VLOR_TTAL_DCMNTO' VALUE
                                      VLOR_TTAL_DCMNTO,
                                      'ID_DCMNTO_LTE' VALUE ID_DCMNTO_LTE,
                                      'INDCDOR_ENTRNO' VALUE INDCDOR_ENTRNO,
                                      'DRCCION' VALUE DRCCION,
                                      'CDGO_PSTAL' VALUE CDGO_PSTAL,
                                      'ID_RCDO_ULTMO' VALUE ID_RCDO_ULTMO) texto
                     from re_g_documentos
                    where id_rcdo_ultmo = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_documentos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_documentos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      update re_g_documentos
         set id_rcdo_ultmo = v_id_rcdo
       where id_rcdo_ultmo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Actualizar los documentos cuyo ID recaudo ultimo referencian al Recaudo a reversar' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina la foto de la cartera antes de aplicar el recaudo
    begin
      delete from re_g_recaudos_cartera
       where id_rcdo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar la foto de la cartera antes de aplicar el recaudo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina el recaudo
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_RCDO llave,
                          json_object('ID_RCDO' VALUE ID_RCDO,
                                      'ID_RCDO_CNTROL' VALUE ID_RCDO_CNTROL,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'CDGO_RCDO_ORGN_TPO' VALUE
                                      CDGO_RCDO_ORGN_TPO,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'FCHA_RCDO' VALUE FCHA_RCDO,
                                      'FCHA_INGRSO_BNCO' VALUE
                                      FCHA_INGRSO_BNCO,
                                      'VLOR' VALUE VLOR,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'CDGO_FRMA_PGO' VALUE CDGO_FRMA_PGO,
                                      'CDGO_RCDO_ESTDO' VALUE CDGO_RCDO_ESTDO,
                                      'FCHA_APLICCION' VALUE FCHA_APLICCION,
                                      'MNSJE_RSPSTA' VALUE MNSJE_RSPSTA,
                                      'ID_USRIO_APLCO' VALUE ID_USRIO_APLCO,
                                      'ID_SLDO_FVOR' VALUE ID_SLDO_FVOR,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'INDCDOR_INTRFAZ' VALUE INDCDOR_INTRFAZ) texto
                     from re_g_recaudos
                    where id_rcdo = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_recaudos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_recaudos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from re_g_recaudos where id_rcdo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo revertir el recaudo' || ' Error: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina las vigencia del saldo a favor
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_SLDO_FVOR_VGNCIA llave,
                          json_object('ID_SLDO_FVOR_VGNCIA' value
                                      ID_SLDO_FVOR_VGNCIA,
                                      'ID_SLDO_FVOR' value ID_SLDO_FVOR,
                                      'VGNCIA' value VGNCIA,
                                      'ID_PRDO' value ID_PRDO) texto
                     from gf_g_saldos_favor_vigencia
                    where id_sldo_fvor = v_id_sldo_fvor) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_saldos_favor_vigencia',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_saldos_favor_vigencia ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_saldos_favor_vigencia a
       where a.id_sldo_fvor = v_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar el saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina el saldo a favor
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_SLDO_FVOR llave,
                          json_object('ID_SLDO_FVOR' VALUE ID_SLDO_FVOR,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'VLOR_SLDO_FVOR' VALUE VLOR_SLDO_FVOR,
                                      'CDGO_SLDO_FVOR_TPO' VALUE
                                      CDGO_SLDO_FVOR_TPO,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'ID_USRIO' VALUE ID_USRIO,
                                      'INDCDOR_RCNCDO' VALUE INDCDOR_RCNCDO,
                                      'FCHA_RGSTRO' VALUE FCHA_RGSTRO,
                                      'FCHA_RCNCMNTO' VALUE FCHA_RCNCMNTO,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'INDCDOR_RGSTRO' VALUE INDCDOR_RGSTRO,
                                      'ESTDO' VALUE ESTDO) texto
                     from gf_g_saldos_favor
                    where cdgo_clnte = p_cdgo_clnte
                      and id_sldo_fvor = v_id_sldo_fvor) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_saldos_favor',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 17;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_saldos_favor ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_saldos_favor a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_sldo_fvor = v_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar el saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se actualiza el consolidado
    begin
      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                p_id_sjto_impsto => v_re_g_recaudo.id_sjto_impsto);
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo actualizar el consolidado' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
  end prc_rg_reversar_recaudo;

  procedure prc_rg_recaudo_manual(p_cdgo_clnte   in number,
                                  p_id_usrio     in number,
                                  p_json_rcdo    in clob,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    v_nvel                   number;
    v_id_rcdo_cntrol         number;
    v_id_rcdo                number;
    v_rgstros                number;
    v_id_dcmnto              number;
    v_id_mvmnto_fncro        number;
    v_vgncia                 number;
    v_prdo                   number;
    v_id_orgen               number := 0;
    v_fcha_prsntcion_pryctda timestamp;
    v_vigencia               clob;
    v_nmbre_up               sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_recaudo_manual';
    v_re_g_recaudos_manual   re_g_recaudos_manual%rowtype;
  
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    for c_recaudo in (select id_rcdos_mnual
                        from json_table(nvl(p_json_rcdo, '[]'),
                                        '$[*]' columns(id_rcdos_mnual number path
                                                '$.ID_RCDOS_MNUAL'))) loop
    
      --Se obtiene el recaudo
      begin
        select /*+ RESULT_CACHE */
         a.*
          into v_re_g_recaudos_manual
          from re_g_recaudos_manual a
         where a.id_rcdos_mnual = c_recaudo.id_rcdos_mnual;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo obtener el recuado';
          return;
      end;
    
      if v_re_g_recaudos_manual.cdgo_frma_pgo = 'CH' then
      
        --Se valida si se adjunto el cheque al recaudo
        begin
        
          select count(*)
            into v_rgstros
            from re_g_recaudos_manual_soprte a
            join re_d_documento_soporte_tipo b
              on a.id_dcmnto_sprte_tpo = b.id_dcmnto_sprte_tpo
           where b.cdgo_clnte = v_re_g_recaudos_manual.cdgo_clnte
             and a.id_rcdos_mnual = c_recaudo.id_rcdos_mnual
             and b.cdgo_dcmnto_sprte_tpo = 'CHE';
        
          if v_rgstros = 0 then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Agregue el recibo del cheque ';
            return;
          end if;
        
        end;
      
      elsif v_re_g_recaudos_manual.cdgo_frma_pgo = 'TR' then
      
        --Se valida si se adjunto la transferencia
        select count(*)
          into v_rgstros
          from re_g_recaudos_manual_soprte a
          join re_d_documento_soporte_tipo b
            on a.id_dcmnto_sprte_tpo = b.id_dcmnto_sprte_tpo
         where b.cdgo_clnte = v_re_g_recaudos_manual.cdgo_clnte
           and a.id_rcdos_mnual = c_recaudo.id_rcdos_mnual
           and b.cdgo_dcmnto_sprte_tpo = 'RTF';
      
        if v_rgstros = 0 then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Agregue el recibo de tranferencia';
          return;
        end if;
      
      end if;
    
      if v_id_orgen <> v_re_g_recaudos_manual.id_orgen then
      
        --Se obtiene informacion de la declaracion
        begin
          select a.fcha_prsntcion_pryctda, a.vgncia, b.prdo
            into v_fcha_prsntcion_pryctda, v_vgncia, v_prdo
            from gi_g_declaraciones a
            join df_i_periodos b
              on a.id_prdo = b.id_prdo
           where id_dclrcion = v_re_g_recaudos_manual.id_orgen;
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'No se pudo obtener la fecha proyectada de declaracion';
            return;
        end;
      
        --Se coloca la declaracion como presentada
        begin
          pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte          => p_cdgo_clnte,
                                                         p_id_dclrcion         => v_re_g_recaudos_manual.id_orgen,
                                                         p_cdgo_dclrcion_estdo => 'PRS',
                                                         p_fcha                => systimestamp,
                                                         o_cdgo_rspsta         => o_cdgo_rspsta,
                                                         o_mnsje_rspsta        => o_mnsje_rspsta);
          if o_cdgo_rspsta > 0 then
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Problema al llamar la up que coloca la presentacion presentada';
            return;
        end;
      
        --Se pasa la declaracion a movimiento financiero
        begin
          pkg_gi_declaraciones_utlddes.prc_ap_declaracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                          p_id_usrio     => v_re_g_recaudos_manual.id_usrio,
                                                          p_id_dclrcion  => v_re_g_recaudos_manual.id_orgen,
                                                          o_cdgo_rspsta  => o_cdgo_rspsta,
                                                          o_mnsje_rspsta => o_mnsje_rspsta);
        
          if o_cdgo_rspsta > 0 then
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'Problema al llamar la up que registra la declaracion en movimienot financiero';
            return;
        end;
      
        v_id_orgen := v_re_g_recaudos_manual.id_orgen;
      
      end if;
    
      begin
      
        v_vigencia := '{"VGNCIA_PRDO":[{"vgncia":' || v_vgncia ||
                      ',"prdo":' || v_prdo || ',"id_orgen":' || v_id_orgen ||
                      '}]}';
      
        -- Se genera el documento a pagar.
        v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                          p_id_impsto           => v_re_g_recaudos_manual.id_impsto,
                                                          p_id_impsto_sbmpsto   => v_re_g_recaudos_manual.id_impsto_sbmpsto,
                                                          p_cdna_vgncia_prdo    => v_vigencia,
                                                          p_cdna_vgncia_prdo_ps => null,
                                                          p_id_dcmnto_lte       => null,
                                                          p_id_sjto_impsto      => v_re_g_recaudos_manual.id_sjto_impsto,
                                                          p_fcha_vncmnto        => v_fcha_prsntcion_pryctda,
                                                          p_cdgo_dcmnto_tpo     => 'DAB',
                                                          p_nmro_dcmnto         => null,
                                                          p_vlor_ttal_dcmnto    => v_re_g_recaudos_manual.vlor,
                                                          p_indcdor_entrno      => 'PRVDO');
      
        if v_id_dcmnto is null then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se pudo generar el documento';
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se pudo llamar a la funcion que genera el documento';
          return;
      end;
    
      --Se registra el recaudo control
      begin
        prc_rg_recaudo_control(p_cdgo_clnte        => v_re_g_recaudos_manual.cdgo_clnte,
                               p_id_impsto         => v_re_g_recaudos_manual.id_impsto,
                               p_id_impsto_sbmpsto => v_re_g_recaudos_manual.id_impsto_sbmpsto,
                               p_id_bnco           => v_re_g_recaudos_manual.id_bnco,
                               p_id_bnco_cnta      => v_re_g_recaudos_manual.id_bnco_cnta,
                               p_fcha_cntrol       => v_re_g_recaudos_manual.fcha_cntrol,
                               p_obsrvcion         => v_re_g_recaudos_manual.obsrvcion,
                               p_cdgo_rcdo_orgen   => 'MN',
                               p_id_usrio          => v_re_g_recaudos_manual.id_usrio,
                               o_id_rcdo_cntrol    => v_id_rcdo_cntrol,
                               o_cdgo_rspsta       => o_cdgo_rspsta,
                               o_mnsje_rspsta      => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'Problema al llamar la up que registra el recaudo control';
          return;
        
      end;
    
      --Se registra el recaudo
      begin
        pkg_re_recaudos.prc_rg_recaudo(p_cdgo_clnte         => v_re_g_recaudos_manual.cdgo_clnte,
                                       p_id_rcdo_cntrol     => v_id_rcdo_cntrol,
                                       p_id_sjto_impsto     => v_re_g_recaudos_manual.id_sjto_impsto,
                                       p_cdgo_rcdo_orgn_tpo => 'DC',
                                       p_rcdo_orgn          => v_re_g_recaudos_manual.rcdo_orgn,
                                       p_id_orgen           => v_id_dcmnto,
                                       p_vlor               => v_re_g_recaudos_manual.vlor,
                                       p_obsrvcion          => v_re_g_recaudos_manual.obsrvcion,
                                       p_cdgo_frma_pgo      => v_re_g_recaudos_manual.cdgo_frma_pgo,
                                       p_cdgo_rcdo_estdo    => 'RG',
                                       o_id_rcdo            => v_id_rcdo,
                                       o_cdgo_rspsta        => o_cdgo_rspsta,
                                       o_mnsje_rspsta       => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'Problema al llamar la up que registra el recaudo';
          return;
      end;
    
      --Se aplica el recaudo
      begin
        pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => p_id_usrio,
                                       p_cdgo_clnte   => p_cdgo_clnte,
                                       p_id_rcdo      => v_id_rcdo,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se pudo llamar la up que aplica el recaudo';
          return;
      end;
    
      --Se actualiza la columna de recaudo en recaudo manual
      begin
        update re_g_recaudos_manual a
           set a.id_rcdo = v_id_rcdo, a.cdgo_rcdo_estdo = 'AP'
         where a.id_rcdos_mnual = c_recaudo.id_rcdos_mnual;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se pudo actualizar el recuado manual';
          return;
      end;
    
    end loop;
  
  end prc_rg_recaudo_manual;

  procedure prc_rg_reversar_recaudo_no_delete(p_cdgo_clnte   in number,
                                              p_id_usrio     in gf_g_recaudo_reversa.id_usrio%type,
                                              p_nmro_dcmnto  in number,
                                              p_id_rcdo      in number,
                                              p_dscrpcion    in gf_g_recaudo_reversa.dscrpcion%type,
                                              o_cdgo_rspsta  out number,
                                              o_mnsje_rspsta out varchar2) as
  
    v_cntdad_rcdos          number;
    v_vlor_rcdos            number;
    v_id_sldo_fvor          number;
    v_id_sldo_fvor_slctud   number;
    v_cntdad_mvmntos        number;
    v_id_rcdo               number;
    v_nvel                  number;
    v_indcdor_nrmlzar_crtra varchar2(1);
  
    v_re_g_documentos re_g_documentos%rowtype;
    v_re_g_recaudo    v_re_g_recaudos%rowtype;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_recaudos.prc_rg_reversar_recaudo_no_delete';
  
    v_id_rcdo_rvrsa number;
    v_mnsje_rspsta  varchar2(1000);
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Verifica si Existe el Documento de Pago
    begin
      select a.*
        into v_re_g_documentos
        from re_g_documentos a
       where nmro_dcmnto = p_nmro_dcmnto
         and INDCDOR_PGO_APLCDO = 'S'
         and cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          p_nmro_dcmnto || ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Verifica si el documento tiene un Recaudo
    begin
      select a.*
        into v_re_g_recaudo
        from v_re_g_recaudos a
       where a.id_rcdo = p_id_rcdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El documento de pago #' ||
                          p_nmro_dcmnto || ', no tiene un recaudo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se valida que el recaudo no venga de un archivo asobancaria o de web service
    /* if v_re_g_recaudo.cdgo_rcdo_orgen_cntrol in ('WS') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. La reversion aplica solo para pagos manuales';
      rollback;
      return;
    end if;*/
  
    --Se valida que no existan movimientos posteriores a la aplicacion del recaudo
    begin
    
      select count(*)
        into v_cntdad_mvmntos
        from v_gf_g_movimientos_detalle a
       where a.id_sjto_impsto = v_re_g_recaudo.id_sjto_impsto
         and a.id_orgen <> v_re_g_recaudo.id_rcdo
         and a.fcha_mvmnto >
             (select max(b.fcha_mvmnto) as fcha_mvmnto_mxma
                from gf_g_movimientos_detalle b
               where b.cdgo_mvmnto_orgn = 'RE'
                 and b.id_orgen = a.id_orgen);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo obtener la cantidad de movimientos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    if v_cntdad_mvmntos > 0 then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No se pudo reversar el pago, se encontraron movimientos posteriores a la fecha del recaudo';
      rollback;
      return;
    end if;
  
    -- Se registra en el maestro del log de lo reversado - NLCZ
    v_id_rcdo_rvrsa := sq_gf_g_recaudo_reversa.nextval;
    begin
      insert into gf_g_recaudo_reversa
        (id_rcdo_rvrsa,
         nmro_dcmnto,
         id_usrio,
         fcha_rvrsa,
         id_rcdo,
         dscrpcion)
      values
        (v_id_rcdo_rvrsa,
         p_nmro_dcmnto,
         p_id_usrio,
         sysdate,
         v_re_g_recaudo.id_rcdo,
         p_dscrpcion);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '.0. No se pudo registrar el maestro del log para documento: ' ||
                          p_nmro_dcmnto || ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
    --Se elimina los movimientos de origen recaudo (RE)
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_MVMNTO_DTLLE llave,
                          json_object('ID_MVMNTO_DTLLE' VALUE
                                      ID_MVMNTO_DTLLE,
                                      'ID_MVMNTO_FNCRO' VALUE ID_MVMNTO_FNCRO,
                                      'CDGO_MVMNTO_ORGN' VALUE
                                      CDGO_MVMNTO_ORGN,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'CDGO_MVMNTO_TPO' VALUE CDGO_MVMNTO_TPO,
                                      'VGNCIA' VALUE VGNCIA,
                                      'ID_PRDO' VALUE ID_PRDO,
                                      'CDGO_PRDCDAD' VALUE CDGO_PRDCDAD,
                                      'FCHA_MVMNTO' VALUE FCHA_MVMNTO,
                                      'ID_CNCPTO' VALUE ID_CNCPTO,
                                      'ID_CNCPTO_CSDO' VALUE ID_CNCPTO_CSDO,
                                      'VLOR_DBE' VALUE VLOR_DBE,
                                      'VLOR_HBER' VALUE VLOR_HBER,
                                      'ID_MVMNTO_DTLLE_BSE' VALUE
                                      ID_MVMNTO_DTLLE_BSE,
                                      'ACTVO' VALUE ACTVO,
                                      'GNRA_INTRES_MRA' VALUE GNRA_INTRES_MRA,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'ID_IMPSTO_ACTO_CNCPTO' VALUE
                                      ID_IMPSTO_ACTO_CNCPTO) texto
                     from gf_g_movimientos_detalle
                    where cdgo_mvmnto_orgn = 'RE'
                      and id_orgen = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_movimientos_detalle',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_movimientos_detalle ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_movimientos_detalle
       where cdgo_mvmnto_orgn = 'RE'
         and id_orgen = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo reversar los movimientos' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    if v_re_g_recaudo.id_sldo_fvor is not null then
    
      --Se valida si el saldo a favor fue reconocido
      begin
        select a.id_sldo_fvor
          into v_id_sldo_fvor
          from gf_g_saldos_favor a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_sldo_fvor = v_re_g_recaudo.id_sldo_fvor
           and a.indcdor_rcncdo = 'S';
        --or a.indcdor_rcncdo = 'N';
      exception
        when no_data_found then
          null;
        
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Problemas al consultar el estado del saldo a favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          rollback;
          return;
      end;
    
      if v_id_sldo_fvor is not null then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se puede reversar el recaudo porque se reconocio el saldo a favor que genero el mismo';
        rollback;
        return;
      end if;
    
      --Se valida si el saldo a favor se encuentra en una solicitud abierta
      begin
        select a.id_sldo_fvor_slctud
          into v_id_sldo_fvor_slctud
          from gf_g_saldos_favor_solicitud a
          join wf_g_instancias_flujo b
            on a.id_instncia_fljo = b.id_instncia_fljo
          join gf_g_sldos_fvor_slctud_dtll c
            on a.id_sldo_fvor_slctud = c.id_sldo_fvor_slctud
           and c.id_sldo_fvor = v_re_g_recaudo.id_sldo_fvor
           and b.estdo_instncia = 'INICIADA';
      exception
        when no_data_found then
          null;
        
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Problemas al consultar si el saldo a favor se encuentra en una solicitud';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          rollback;
          return;
      end;
    
      if v_id_sldo_fvor_slctud is not null then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se puede reversar el recaudo debido a que se esta proyectando el saldo a favor que se genero por el recuado';
        rollback;
        return;
      end if;
    
    end if;
  
    --Se obtiene la cantidad de recaudos agregados al recaudo control y el valor total de recuados
    begin
    
      select a.cntdad_rcdos, a.vlor_rcdos
        into v_cntdad_rcdos, v_vlor_rcdos
        from re_g_recaudos_control a
       where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol;
    
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Obtener la cantidad de recaudos y valor total de los recuados' ||
                          ' Erro: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se actualiza el recaudo control
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_RCDO_CNTROL llave,
                          json_object('ID_RCDO_CNTROL' VALUE ID_RCDO_CNTROL,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_BNCO' VALUE ID_BNCO,
                                      'ID_BNCO_CNTA' VALUE ID_BNCO_CNTA,
                                      'FCHA_CNTROL' VALUE FCHA_CNTROL,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'CNTDAD_RCDOS' VALUE CNTDAD_RCDOS,
                                      'VLOR_RCDOS' VALUE VLOR_RCDOS,
                                      'CDGO_RCDO_ORGEN' VALUE CDGO_RCDO_ORGEN,
                                      'ID_PRCSO_CRGA' VALUE ID_PRCSO_CRGA,
                                      'ID_USRIO' VALUE ID_USRIO,
                                      'FCHA_RGSTRO' VALUE FCHA_RGSTRO) texto
                     from re_g_recaudos_control
                    where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_recaudos_control',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_recaudos_control ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      v_cntdad_rcdos := v_cntdad_rcdos - 1;
      v_vlor_rcdos   := v_vlor_rcdos - v_re_g_recaudo.vlor;
    
      update re_g_recaudos_control a
         set a.vlor_rcdos = v_vlor_rcdos, a.cntdad_rcdos = v_cntdad_rcdos
       where id_rcdo_cntrol = v_re_g_recaudo.id_rcdo_cntrol;
    
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Actualizar la cantidad de recaudos y valor total de los recuados' ||
                          ' Erro: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Actualizamos Documento
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_DCMNTO llave,
                          json_object('ID_DCMNTO' VALUE ID_DCMNTO,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'NMRO_DCMNTO' VALUE NMRO_DCMNTO,
                                      'CDGO_DCMNTO_TPO' VALUE CDGO_DCMNTO_TPO,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'NMRO_CTA' VALUE NMRO_CTA,
                                      'FCHA_DCMNTO' VALUE FCHA_DCMNTO,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'VLOR_TTAL_DBE' VALUE VLOR_TTAL_DBE,
                                      'VLOR_TTAL_HBER' VALUE VLOR_TTAL_HBER,
                                      'VLOR_TTAL' VALUE VLOR_TTAL,
                                      'INDCDOR_PGO_APLCDO' VALUE
                                      INDCDOR_PGO_APLCDO,
                                      'VLOR_TTAL_DCMNTO' VALUE
                                      VLOR_TTAL_DCMNTO,
                                      'ID_DCMNTO_LTE' VALUE ID_DCMNTO_LTE,
                                      'INDCDOR_ENTRNO' VALUE INDCDOR_ENTRNO,
                                      'DRCCION' VALUE DRCCION,
                                      'CDGO_PSTAL' VALUE CDGO_PSTAL,
                                      'ID_RCDO_ULTMO' VALUE ID_RCDO_ULTMO) texto
                     from re_g_documentos
                    where id_dcmnto = v_re_g_documentos.id_dcmnto) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_documentos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_documentos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      update re_g_documentos
         set indcdor_pgo_aplcdo = 'N'
       where id_dcmnto = v_re_g_documentos.id_dcmnto;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo actualizar el estado del documento' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se obtiene el ultimo recaudo
    begin
      select a.id_rcdo
        into v_id_rcdo
        from re_g_recaudos a
        join re_g_recaudos_control b
          on a.id_rcdo_cntrol = b.id_rcdo_cntrol
       where b.cdgo_clnte = p_cdgo_clnte
         and b.id_impsto = v_re_g_recaudo.id_impsto
         and b.id_impsto_sbmpsto = v_re_g_recaudo.id_impsto_sbmpsto
         and a.id_sjto_impsto = v_re_g_recaudo.id_sjto_impsto
         and a.cdgo_rcdo_estdo = 'AP'
         and a.cdgo_rcdo_orgn_tpo = 'DC'
         and a.id_rcdo <> v_re_g_recaudo.id_rcdo
       order by fcha_rcdo desc
       fetch first 1 rows only;
    exception
      when no_data_found then
        null;
    end;
  
    -- Actualizamos todos los documentos cuyo ID recaudo ultimo ...
    -- referencien al Recaudo a reversar
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_DCMNTO llave,
                          json_object('ID_DCMNTO' VALUE ID_DCMNTO,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'NMRO_DCMNTO' VALUE NMRO_DCMNTO,
                                      'CDGO_DCMNTO_TPO' VALUE CDGO_DCMNTO_TPO,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'NMRO_CTA' VALUE NMRO_CTA,
                                      'FCHA_DCMNTO' VALUE FCHA_DCMNTO,
                                      'FCHA_VNCMNTO' VALUE FCHA_VNCMNTO,
                                      'VLOR_TTAL_DBE' VALUE VLOR_TTAL_DBE,
                                      'VLOR_TTAL_HBER' VALUE VLOR_TTAL_HBER,
                                      'VLOR_TTAL' VALUE VLOR_TTAL,
                                      'INDCDOR_PGO_APLCDO' VALUE
                                      INDCDOR_PGO_APLCDO,
                                      'VLOR_TTAL_DCMNTO' VALUE
                                      VLOR_TTAL_DCMNTO,
                                      'ID_DCMNTO_LTE' VALUE ID_DCMNTO_LTE,
                                      'INDCDOR_ENTRNO' VALUE INDCDOR_ENTRNO,
                                      'DRCCION' VALUE DRCCION,
                                      'CDGO_PSTAL' VALUE CDGO_PSTAL,
                                      'ID_RCDO_ULTMO' VALUE ID_RCDO_ULTMO) texto
                     from re_g_documentos
                    where id_rcdo_ultmo = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_documentos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_documentos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      update re_g_documentos
         set id_rcdo_ultmo = v_id_rcdo
       where id_rcdo_ultmo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo Actualizar los documentos cuyo ID recaudo ultimo referencian al Recaudo a reversar' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina la foto de la cartera antes de aplicar el recaudo
    begin
      delete from re_g_recaudos_cartera
       where id_rcdo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar la foto de la cartera antes de aplicar el recaudo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina el recaudo
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_RCDO llave,
                          json_object('ID_RCDO' VALUE ID_RCDO,
                                      'ID_RCDO_CNTROL' VALUE ID_RCDO_CNTROL,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'CDGO_RCDO_ORGN_TPO' VALUE
                                      CDGO_RCDO_ORGN_TPO,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'FCHA_RCDO' VALUE FCHA_RCDO,
                                      'FCHA_INGRSO_BNCO' VALUE
                                      FCHA_INGRSO_BNCO,
                                      'VLOR' VALUE VLOR,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'CDGO_FRMA_PGO' VALUE CDGO_FRMA_PGO,
                                      'CDGO_RCDO_ESTDO' VALUE CDGO_RCDO_ESTDO,
                                      'FCHA_APLICCION' VALUE FCHA_APLICCION,
                                      'MNSJE_RSPSTA' VALUE MNSJE_RSPSTA,
                                      'ID_USRIO_APLCO' VALUE ID_USRIO_APLCO,
                                      'ID_SLDO_FVOR' VALUE ID_SLDO_FVOR,
                                      'ID_CNVNIO' VALUE ID_CNVNIO,
                                      'INDCDOR_INTRFAZ' VALUE INDCDOR_INTRFAZ) texto
                     from re_g_recaudos
                    where id_rcdo = v_re_g_recaudo.id_rcdo) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       're_g_recaudos',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para re_g_recaudos ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      update re_g_recaudos
         set cdgo_rcdo_estdo = 'RG'
       where id_rcdo = v_re_g_recaudo.id_rcdo;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo revertir el recaudo' || ' Error: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina las vigencia del saldo a favor
    begin
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_SLDO_FVOR_VGNCIA llave,
                          json_object('ID_SLDO_FVOR_VGNCIA' value
                                      ID_SLDO_FVOR_VGNCIA,
                                      'ID_SLDO_FVOR' value ID_SLDO_FVOR,
                                      'VGNCIA' value VGNCIA,
                                      'ID_PRDO' value ID_PRDO) texto
                     from gf_g_saldos_favor_vigencia
                    where id_sldo_fvor = v_id_sldo_fvor) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_saldos_favor_vigencia',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_saldos_favor_vigencia ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_saldos_favor_vigencia a
       where a.id_sldo_fvor = v_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar el saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se elimina el saldo a favor
    begin
    
      -- Se guarda el log de lo que se elimina
      for fila in (select ID_SLDO_FVOR llave,
                          json_object('ID_SLDO_FVOR' VALUE ID_SLDO_FVOR,
                                      'CDGO_CLNTE' VALUE CDGO_CLNTE,
                                      'ID_IMPSTO' VALUE ID_IMPSTO,
                                      'ID_IMPSTO_SBMPSTO' VALUE
                                      ID_IMPSTO_SBMPSTO,
                                      'ID_SJTO_IMPSTO' VALUE ID_SJTO_IMPSTO,
                                      'VLOR_SLDO_FVOR' VALUE VLOR_SLDO_FVOR,
                                      'CDGO_SLDO_FVOR_TPO' VALUE
                                      CDGO_SLDO_FVOR_TPO,
                                      'ID_ORGEN' VALUE ID_ORGEN,
                                      'ID_USRIO' VALUE ID_USRIO,
                                      'INDCDOR_RCNCDO' VALUE INDCDOR_RCNCDO,
                                      'FCHA_RGSTRO' VALUE FCHA_RGSTRO,
                                      'FCHA_RCNCMNTO' VALUE FCHA_RCNCMNTO,
                                      'OBSRVCION' VALUE OBSRVCION,
                                      'INDCDOR_RGSTRO' VALUE INDCDOR_RGSTRO,
                                      'ESTDO' VALUE ESTDO) texto
                     from gf_g_saldos_favor
                    where cdgo_clnte = p_cdgo_clnte
                      and id_sldo_fvor = v_id_sldo_fvor) loop
        begin
          pkg_re_recaudos.prc_rg_reversion_recaudo_log(v_id_rcdo_rvrsa,
                                                       'gf_g_saldos_favor',
                                                       fila.llave,
                                                       fila.texto,
                                                       v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 17;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '.1. No se pudo registrar el log para gf_g_saldos_favor ID: ' ||
                              fila.llave || ' Error: ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            rollback;
            return;
        end;
      end loop;
    
      delete from gf_g_saldos_favor a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_sldo_fvor = v_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo eliminar el saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
    --Se actualiza el consolidado
    begin
      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                p_id_sjto_impsto => v_re_g_recaudo.id_sjto_impsto);
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo actualizar el consolidado' ||
                          ' Error: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        rollback;
        return;
    end;
  
  end prc_rg_reversar_recaudo_no_delete;

end pkg_re_recaudos;

/
