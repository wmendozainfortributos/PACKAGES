--------------------------------------------------------
--  DDL for Package Body PKG_WS_RECAUDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_RECAUDOS" is

  /*
  * @descripcion  : valida el login del usuario que quiere consumir el web service de recaudos java
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */
  procedure prc_vl_usuario(p_usrio            in varchar2,
                           p_password         in varchar2,
                           p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                           p_id_usrio_wbsrvce out ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                           o_cdgo_rspsta      out number,
                           o_mnsje_rspsta     out varchar2) is
  
    v_usuario          ws_g_usuarios_webservice.user_name%type;
    v_password         ws_g_usuarios_webservice.password%type;
    v_password_almcndo ws_g_usuarios_webservice.password%type;
  begin
  
    v_usuario  := p_usrio;
    v_password := p_password;
  
    --se convierte la contrase?a a el esquema de seguridad
    v_password := pkg_sg_autenticacion.fnc_sg_hash(v_usuario, v_password);
  
    -- se consulta el usuario para validar las credenciales
    begin
      select w.password, w.id_usrio_wbsrvce
        into v_password_almcndo, p_id_usrio_wbsrvce
        from ws_g_usuarios_webservice w
       where w.user_name = v_usuario
         and w.cdgo_clnte = p_cdgo_clnte
         and w.actvo = 'S';
    
      if v_password_almcndo = v_password then
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Usuario Encontrado';
      else
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'Nombre de Usuario o Contrase?a no coincide';
      end if;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'Usuario no existe';
    end;
  end;

  /*
  * @descripcion  : valida el usuario web service por codigo del banco
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */

  procedure prc_vl_usuario_no_login(p_cdgo_bnco        in varchar2,
                                    p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                    p_id_usrio_wbsrvce out ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                                    o_cdgo_rspsta      out number,
                                    o_mnsje_rspsta     out varchar2) is
  
  begin
  
    -- se consulta el usuario para validar las credenciales
    begin
      select w.id_usrio_wbsrvce
        into p_id_usrio_wbsrvce
        from ws_g_usuarios_webservice w
        join df_c_bancos b
          on b.id_bnco = w.id_bnco
       where ltrim(b.cdgo_bnco, '0') = ltrim(p_cdgo_bnco, '0')
         and w.cdgo_clnte = p_cdgo_clnte;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Usuario Encontrado';
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'Usuario no existe';
    end;
  end;

  /*
  * @descripcion  : validar documento antes del recaudo recaudo
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */

  procedure prc_vl_documento(p_cdgo_ean           in df_i_impuestos_subimpuesto.cdgo_ean%type,
                             p_nmro_dcmnto        in re_g_documentos.nmro_dcmnto%type,
                             p_fcha_venci         in varchar2,
                             p_vlor               in number,
                             o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                             o_id_impsto          out df_c_impuestos.id_impsto%type,
                             o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                             o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                             o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                             o_id_orgen           out re_g_recaudos.id_orgen%type,
                             o_cdgo_rspsta        out number,
                             o_mnsje_rspsta       out varchar2) is
  
    v_fcha_vncmnto date;
  
  begin
  
    -- se formata la fecha de vencimiento de acuerdo a como se recibe por el web service
    begin
      v_fcha_vncmnto := to_date(p_fcha_venci, 'YYYYMMDD');
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'Formato de fecha invalido, debe estar en YYYYMMDD.';
        return;
    end;
  
    -- se valida el vencimiento del recibo
    if to_char(v_fcha_vncmnto, 'YYYYMMDD') < to_char(sysdate, 'YYYYMMDD') then
      o_cdgo_rspsta  := 23;
      o_mnsje_rspsta := 'El documento se encuentra vencido';
      return;
    end if;
  
    --valida la informacion del documento 
    pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => lpad(p_cdgo_ean,
                                                                     13,
                                                                     '0'),
                                        p_nmro_dcmnto        => p_nmro_dcmnto,
                                        p_vlor               => p_vlor,
                                        p_fcha_vncmnto       => v_fcha_vncmnto,
                                        p_fcha_rcdo          => null,
                                        p_indcdor_vlda_pgo   => true,
                                        o_cdgo_rcdo_orgn_tpo => o_cdgo_rcdo_orgn_tpo,
                                        o_id_orgen           => o_id_orgen,
                                        o_cdgo_clnte         => o_cdgo_clnte,
                                        o_id_impsto          => o_id_impsto,
                                        o_id_impsto_sbmpsto  => o_id_impsto_sbmpsto,
                                        o_id_sjto_impsto     => o_id_sjto_impsto,
                                        o_cdgo_rspsta        => o_cdgo_rspsta,
                                        o_mnsje_rspsta       => o_mnsje_rspsta);
  
    if o_cdgo_rspsta = 0 then
      -- se valida que no exista en la tabla de ws_g_recaudos_webservice ya que puede que se encuentre registrado pero no aplicado
      for recaudosws in (select 1
                           from ws_g_recaudos_webservice d
                          where d.nmro_dcmnto = p_nmro_dcmnto
                            and d.id_sjto_impsto = o_id_sjto_impsto
                            and d.cdgo_clnte = o_cdgo_clnte) loop
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'Existe un pago registrado para este recibo';
      end loop;
    end if;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := 'Ok';
    end if;
  
  end;

  /*
  * @descripcion  : validar documento solo por referencia de pago antes del recaudo
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */

  procedure prc_vl_documento_referencia(p_nmro_dcmnto        in re_g_documentos.nmro_dcmnto%type,
                                        o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                                        o_id_impsto          out df_c_impuestos.id_impsto%type,
                                        o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                        o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                        o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                                        o_id_orgen           out re_g_recaudos.id_orgen%type,
                                        o_fcha_vncmnto       out varchar2,
                                        o_vlor_dcmnto        out varchar2,
                                        o_cdgo_rspsta        out number,
                                        o_mnsje_rspsta       out varchar2) is
  
    v_fcha_vncmnto date;
  
    v_vlor_dcmnto re_g_documentos.vlor_ttal_dcmnto%type;
    v_cdgo_ean    df_i_impuestos_subimpuesto.cdgo_ean%type;
  
  begin
  
    begin
      select d.fcha_vncmnto, d.vlor_ttal_dcmnto, e.cdgo_ean
        into v_fcha_vncmnto, v_vlor_dcmnto, v_cdgo_ean
        from re_g_documentos d
        join df_i_impuestos_subimpuesto e
          on e.id_impsto_sbmpsto = d.id_impsto_sbmpsto
       where d.nmro_dcmnto = p_nmro_dcmnto;
    exception
      when no_data_found then
        begin
          select t.fcha_prsntcion_pryctda fcha_vncmnto,
                 round(t.vlor_pago) vlor_pgo,
                 c.cdgo_ean
            into v_fcha_vncmnto, v_vlor_dcmnto, v_cdgo_ean
            from gi_g_declaraciones t
            join df_i_impuestos_subimpuesto c
              on c.id_impsto_sbmpsto = t.id_impsto_sbmpsto
           where t.nmro_cnsctvo = p_nmro_dcmnto;
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'Documento no existe en el sistema.';
            return;
        end;
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := 'Documento no existe en el sistema.';
        return;
    end;
  
    -- se valida el vencimiento del recibo
    if to_char(v_fcha_vncmnto, 'YYYYMMDD') < to_char(sysdate, 'YYYYMMDD') then
      o_cdgo_rspsta  := 23;
      o_mnsje_rspsta := 'El documento se encuentra vencido';
      return;
    end if;
  
    --valida la informacion del documento 
    pkg_re_recaudos.prc_vl_documento_01(p_cdgo_ean           => v_cdgo_ean,
                                        p_nmro_dcmnto        => p_nmro_dcmnto,
                                        p_vlor               => v_vlor_dcmnto,
                                        p_fcha_vncmnto       => v_fcha_vncmnto,
                                        p_fcha_rcdo          => null,
                                        p_indcdor_vlda_pgo   => true,
                                        o_cdgo_rcdo_orgn_tpo => o_cdgo_rcdo_orgn_tpo,
                                        o_id_orgen           => o_id_orgen,
                                        o_cdgo_clnte         => o_cdgo_clnte,
                                        o_id_impsto          => o_id_impsto,
                                        o_id_impsto_sbmpsto  => o_id_impsto_sbmpsto,
                                        o_id_sjto_impsto     => o_id_sjto_impsto,
                                        o_cdgo_rspsta        => o_cdgo_rspsta,
                                        o_mnsje_rspsta       => o_mnsje_rspsta);
  
    if o_cdgo_rspsta = 0 then
      -- se valida que no exista en la tabla de ws_g_recaudos_webservice ya que puede que se encuentre registrado pero no aplicado
      for recaudosws in (select 1
                           from ws_g_recaudos_webservice d
                          where d.nmro_dcmnto = p_nmro_dcmnto
                            and d.id_sjto_impsto = o_id_sjto_impsto
                            and d.cdgo_clnte = o_cdgo_clnte) loop
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'Existe un pago registrado para este recibo';
      end loop;
    end if;
  
    if o_cdgo_rspsta = 0 then
      o_fcha_vncmnto := to_char(v_fcha_vncmnto, 'YYYYMMDD');
      o_vlor_dcmnto  := v_vlor_dcmnto;
      o_mnsje_rspsta := 'Ok';
    end if;
  
  end;

  /*
  * @descripcion  : regista el recaudo web service
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */
  procedure prc_rg_recaudo_webservice(p_cdgo_ean         in df_i_impuestos_subimpuesto.cdgo_ean%type,
                                      p_nmro_dcmnto      in number,
                                      p_vlor             in number,
                                      p_fcha_venci       in varchar2,
                                      p_fcha_pgo         in varchar2,
                                      p_ref_suc          in varchar2,
                                      p_cdgo_frma_pgo    in varchar2,
                                      p_id_usrio_wbsrvce in varchar2,
                                      p_sprta_rvrso      in varchar2 default 'N',
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2) is
  
    v_cdgo_clnte         df_s_clientes.cdgo_clnte%type;
    v_id_impsto          df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_id_sjto_impsto     df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_cdgo_rcdo_orgn_tpo re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
    v_id_orgen           re_g_recaudos.id_orgen%type;
  
    v_fcha_rcdo date;
  
    v_id_bnco      df_c_bancos.id_bnco%type;
    v_id_bnco_cnta df_c_bancos_cuenta.id_bnco_cnta%type;
  
  begin
    -- se formata la fecha de recaudo de acuerdo a como se recibe por el web service
    begin
      v_fcha_rcdo := to_date(p_fcha_pgo, 'YYYYMMDD');
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'Formato de fecha invalido, debe estar en formato YYYYMMDD.';
        return;
    end;
  
    --se valida el documento antes de registrarlo
    prc_vl_documento(p_cdgo_ean           => lpad(p_cdgo_ean, 13, '0'),
                     p_nmro_dcmnto        => p_nmro_dcmnto,
                     p_fcha_venci         => p_fcha_venci,
                     p_vlor               => p_vlor,
                     o_cdgo_clnte         => v_cdgo_clnte,
                     o_id_impsto          => v_id_impsto,
                     o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto,
                     o_id_sjto_impsto     => v_id_sjto_impsto,
                     o_cdgo_rcdo_orgn_tpo => v_cdgo_rcdo_orgn_tpo,
                     o_id_orgen           => v_id_orgen,
                     o_cdgo_rspsta        => o_cdgo_rspsta,
                     o_mnsje_rspsta       => o_mnsje_rspsta);
  
    if o_cdgo_rspsta = '0' then
    
      --se identifica el banco y la cuenta parametrizada para ese usuario
      begin
        select a.id_bnco, t.id_bnco_cnta
          into v_id_bnco, v_id_bnco_cnta
          from ws_g_usuarios_webservice a
          join ws_d_usuarios_cuenta_impuesto t
            on t.id_usrio_wbsrvce = a.id_usrio_wbsrvce
         where t.id_impsto = v_id_impsto
           and t.id_impsto_sbmpsto = v_id_impsto_sbmpsto
           and a.id_usrio_wbsrvce = p_id_usrio_wbsrvce;
      exception
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'Error en la parametrizacion Banco Cuenta Recaudadora';
          return;
      end;
    
      -- se valida la forma del pago 
      if p_cdgo_frma_pgo not in ('EF', 'CH', 'TR', 'MI', 'TC', 'DC') then
        o_cdgo_rspsta  := 22;
        o_mnsje_rspsta := 'Error en la forma de pago';
        return;
      end if;
    
      --se registra la informacion del recaudo
      begin
        insert into ws_g_recaudos_webservice
          (id_rcdo_wbsrvce,
           id_orgen,
           cdgo_rcdo_orgen,
           nmro_dcmnto,
           vlor,
           fcha_rcdo_wbsrvce,
           id_bnco,
           id_bnco_cnta,
           cdgo_scursal,
           fcha_registro,
           id_sjto_impsto,
           id_usrio_wbsrvce,
           cdgo_clnte,
           cdgo_frma_pgo,
           id_impsto,
           id_impsto_sbmpsto,
           sprta_rvrso)
        values
          (sq_ws_g_recaudos_webservice.nextval,
           v_id_orgen,
           v_cdgo_rcdo_orgn_tpo,
           p_nmro_dcmnto,
           p_vlor,
           v_fcha_rcdo,
           v_id_bnco,
           v_id_bnco_cnta,
           p_ref_suc,
           sysdate,
           v_id_sjto_impsto,
           p_id_usrio_wbsrvce,
           v_cdgo_clnte,
           p_cdgo_frma_pgo,
           v_id_impsto,
           v_id_impsto_sbmpsto,
           p_sprta_rvrso);
        commit;
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Ok';
      exception
        when others then
          o_cdgo_rspsta  := 21;
          o_mnsje_rspsta := 'Error procesando el recaudo';
      end;
    
    end if;
  
  end;

  /*
  * @descripcion  : aplica todos los recaudos web service
  * @creacion     : 23/11/2021
  * @modificacion : 23/11/2021
  */

  procedure prc_ap_recaudo_webservice(p_cdgo_clnte   in number,
                                      p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) is
    v_nmro_pgos      number;
    v_id_rcdo_cntrol re_g_recaudos_control.id_rcdo_cntrol%type;
    v_id_rcdo        re_g_recaudos.id_rcdo%type;
    v_id_usrio       sg_g_usuarios.id_usrio%type;
  
    v_mntos_rvrso number := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                            p_cdgo_dfncion_clnte_ctgria => 'RCD',
                                                                            p_cdgo_dfncion_clnte        => 'REV');
  begin
  
    -- valida el usuario que aplica
    begin
      select u.id_usrio
        into v_id_usrio
        from sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'El usuario no existe';
        raise;
    end;
  
    --valida la parametrizacion de los minutos para el reverso
  
    if v_mntos_rvrso is null then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'No se encuentra parametrizado el parametro RCD(Recaudos) REV(Minutos para reversar)';
      return;
    end if;
  
    begin
      update ws_g_recaudos_webservice a
         set a.sprta_rvrso = 'N'
       where a.sprta_rvrso = 'S'
         and ((sysdate - a.fcha_registro) * 1440) > v_mntos_rvrso;
    end;
  
    -- se valida si existen recaudos pendientes para aplicar
    select count(*)
      into v_nmro_pgos
      from ws_g_recaudos_webservice a
     where a.id_rcdo is null
       and a.obsrvcion_aplcion is null
       and a.sprta_rvrso = 'N'
       and a.cdgo_clnte = p_cdgo_clnte;
  
    if v_nmro_pgos > 0 then
      --se agrupan los recaudos por banco cuenta para realizar el proceso de aplicacion por lotes
    
      for control in (select a.id_bnco,
                             a.id_bnco_cnta,
                             a.id_usrio_wbsrvce,
                             a.cdgo_rcdo_orgen,
                             a.id_impsto,
                             a.id_impsto_sbmpsto,
                             trunc(a.fcha_rcdo_wbsrvce) fcha_rcdo_wbsrvce
                        from ws_g_recaudos_webservice a
                       where a.id_rcdo is null
                         --and a.obsrvcion_aplcion is null
                         and a.cdgo_clnte = p_cdgo_clnte
                         and a.sprta_rvrso = 'N'
                         and not exists
                       (select 1
                                from re_g_recaudos c
                               where c.cdgo_rcdo_orgn_tpo = a.cdgo_rcdo_orgen
                                 and c.id_orgen = a.id_orgen
                                 and c.id_sjto_impsto = a.id_sjto_impsto)
                       group by a.id_bnco,
                                a.id_bnco_cnta,
                                a.cdgo_rcdo_orgen,
                                a.id_impsto,
                                a.id_impsto_sbmpsto,
                                trunc(a.fcha_rcdo_wbsrvce),
                                a.id_usrio_wbsrvce
                       order by a.id_usrio_wbsrvce,
                                trunc(a.fcha_rcdo_wbsrvce)) loop
      
        --se crea el control
        pkg_re_recaudos.prc_rg_recaudo_control(p_cdgo_clnte        => p_cdgo_clnte,
                                               p_id_impsto         => control.id_impsto,
                                               p_id_impsto_sbmpsto => control.id_impsto_sbmpsto,
                                               p_id_bnco           => control.id_bnco,
                                               p_id_bnco_cnta      => control.id_bnco_cnta,
                                               p_fcha_cntrol       => control.fcha_rcdo_wbsrvce,
                                               p_obsrvcion         => 'RECAUDOS WEB SERVICE',
                                               -- p_id_rcdo_cja       => null,
                                               p_cdgo_rcdo_orgen => 'WR',
                                               p_id_prcso_crga   => null,
                                               p_id_usrio        => p_id_usrio,
                                               o_id_rcdo_cntrol  => v_id_rcdo_cntrol,
                                               o_cdgo_rspsta     => o_cdgo_rspsta,
                                               o_mnsje_rspsta    => o_mnsje_rspsta);
      
        --se valida que el control se haya creado exitosamente
        if o_cdgo_rspsta = 0 and v_id_rcdo_cntrol > 0 then
          --se recorren los recaudos del mismo banco - cuenta - origen
          for recaudos in (select a.*, i.idntfccion_sjto
                             from ws_g_recaudos_webservice a
                             join v_si_i_sujetos_impuesto i
                               on i.id_sjto_impsto = a.id_sjto_impsto
                            where a.id_rcdo is null
                             -- and a.obsrvcion_aplcion is null
                              and a.cdgo_clnte = p_cdgo_clnte
                              and a.sprta_rvrso = 'N'
                              and a.cdgo_rcdo_orgen =
                                  control.cdgo_rcdo_orgen
                              and a.id_bnco = control.id_bnco
                              and a.id_bnco_cnta = control.id_bnco_cnta
                              and a.id_usrio_wbsrvce =
                                  control.id_usrio_wbsrvce
                              and a.id_impsto = control.id_impsto
                              and a.id_impsto_sbmpsto =
                                  control.id_impsto_sbmpsto
                              and trunc(a.fcha_rcdo_wbsrvce) =
                                  trunc(control.fcha_rcdo_wbsrvce)
                              and not exists
                            (select 1
                                     from re_g_recaudos c
                                    where c.cdgo_rcdo_orgn_tpo =
                                          a.cdgo_rcdo_orgen
                                      and c.id_orgen = a.id_orgen
                                      and c.id_sjto_impsto = a.id_sjto_impsto)
                            order by a.id_rcdo_wbsrvce) loop
          
            --se registra el recaudo en el lote
            pkg_re_recaudos.prc_rg_recaudo(p_cdgo_clnte         => p_cdgo_clnte,
                                           p_id_rcdo_cntrol     => v_id_rcdo_cntrol,
                                           p_id_sjto_impsto     => recaudos.id_sjto_impsto,
                                           p_cdgo_rcdo_orgn_tpo => recaudos.cdgo_rcdo_orgen,
                                           --p_rcdo_orgn          => null, no aplica en municipios
                                           p_id_orgen  => recaudos.id_orgen,
                                           p_vlor      => recaudos.vlor,
                                           p_obsrvcion => 'RECAUDO WEBSERVICE',
                                           --p_id_rcdo_cja_dtlle  => null, no aplica en municipios
                                           p_fcha_ingrso_bnco => recaudos.fcha_rcdo_wbsrvce,
                                           p_cdgo_frma_pgo    => recaudos.cdgo_frma_pgo,
                                           p_cdgo_rcdo_estdo  => 'RG',
                                           o_id_rcdo          => v_id_rcdo,
                                           o_cdgo_rspsta      => o_cdgo_rspsta,
                                           o_mnsje_rspsta     => o_mnsje_rspsta);
          
            if o_cdgo_rspsta = 0 and v_id_rcdo > 0 then
              -- aplicacion del recaudo
            
              if recaudos.cdgo_rcdo_orgen = 'DL' then
                update gi_g_declaraciones a
                   set a.cdgo_dclrcion_estdo = 'PRS',
                       a.id_rcdo             = v_id_rcdo,
                       a.fcha_prsntcion      = recaudos.fcha_rcdo_wbsrvce
                 where a.id_dclrcion = recaudos.id_orgen;
                --registra los movimientos financieros de la declaracion
                pkg_gi_declaraciones.prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   => p_cdgo_clnte,
                                                                   p_id_dclrcion  => recaudos.id_orgen,
                                                                   p_idntfccion   => recaudos.idntfccion_sjto,
                                                                   o_cdgo_rspsta  => o_cdgo_rspsta,
                                                                   o_mnsje_rspsta => o_mnsje_rspsta);
              end if;
            
              pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => p_id_usrio,
                                             p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_rcdo      => v_id_rcdo,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
              if o_cdgo_rspsta = 0 then
                update ws_g_recaudos_webservice a
                   set a.id_rcdo = v_id_rcdo
                 where a.id_rcdo_wbsrvce = recaudos.id_rcdo_wbsrvce;
                commit;
              else
                -- Se reversa lo insertado en tablas de recaudo control, recaudos, movimiento financiero
                rollback;
                --update ws_g_recaudos_webservice a
                 --  set a.obsrvcion_aplcion = 'Error aplicando el recaudo: ' || o_mnsje_rspsta
                 --where a.id_rcdo_wbsrvce = recaudos.id_rcdo_wbsrvce;
                 begin
                    insert into ws_g_recaudos_webservice_log 
                                (id_rcdo_wbsrvce,
                                obsrvcion)
                    values      (recaudos.id_rcdo_wbsrvce,
                                'Error aplicando el recaudo: ' || o_mnsje_rspsta);
                 exception
                    when others then
                        o_cdgo_rspsta  := 3;
                        o_mnsje_rspsta := 'No se puedo registrar el error de aplicacion en la tabla de log';
                end;
              end if;
            else
             -- Se reversa lo insertado en tablas de recaudo control, recaudos, movimiento financiero
              rollback;
              --update ws_g_recaudos_webservice a
              -- set a.obsrvcion_aplcion = 'Error registrando el recaudo: ' ||  o_mnsje_rspsta
               --where a.id_rcdo_wbsrvce = recaudos.id_rcdo_wbsrvce;
                begin
                    insert into ws_g_recaudos_webservice_log 
                                (id_rcdo_wbsrvce,
                                obsrvcion)
                    values      (recaudos.id_rcdo_wbsrvce,
                                'Error registrando el recaudo: ' || o_mnsje_rspsta);
                 exception
                    when others then
                        o_cdgo_rspsta  := 4;
                        o_mnsje_rspsta := 'No se puedo registrar el error de registro la tabla de log';
                end;               
            end if;
          end loop;
        else
          -- Si no fue posible crear el recaudo control
          --marcar todos los recaudos del lote con la novedad de no aplicacion
          update ws_g_recaudos_webservice a
             set a.obsrvcion_aplcion = 'Error registrando el control: ' || o_mnsje_rspsta
           where a.id_bnco = control.id_bnco
             and a.id_bnco_cnta = control.id_bnco_cnta
             and a.id_rcdo is null
             and a.obsrvcion_aplcion is null
             and a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = control.id_impsto
             and a.id_impsto_sbmpsto = control.id_impsto_sbmpsto
             and a.id_usrio_wbsrvce = control.id_usrio_wbsrvce;
        end if;
      
      end loop;
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'No hay recaudos para procesar';
    end if;
  end;

  /*
  * @descripcion  : reversa el recaudo validando si es apto para reverso
  * @creacion     : 21/02/2022
  * @modificacion : 21/02/2022
  */

  procedure prc_rv_recaudo_web_service(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                       p_nmro_dcmnto      in re_g_documentos.nmro_dcmnto%type,
                                       p_id_usrio_wbsrvce in ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2) is
  
    v_id_rcdo_wbsrvce ws_g_recaudos_webservice.id_rcdo_wbsrvce%type;
    v_fcha_registro   date;
    v_sprta_rvrso     ws_g_recaudos_webservice.sprta_rvrso%type;
    v_id_rcdo         re_g_recaudos.id_rcdo%type;
  
    v_mntos_rvrso number := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                            p_cdgo_dfncion_clnte_ctgria => 'RCD',
                                                                            p_cdgo_dfncion_clnte        => 'REV');
  
    v_mntos_trnscrdos number;
  begin
  
    --consulta del documento a reversar
    begin
      select a.id_rcdo_wbsrvce, a.fcha_registro, a.sprta_rvrso, id_rcdo
        into v_id_rcdo_wbsrvce, v_fcha_registro, v_sprta_rvrso, v_id_rcdo
        from ws_g_recaudos_webservice a
       where a.nmro_dcmnto = p_nmro_dcmnto
         and a.id_usrio_wbsrvce = p_id_usrio_wbsrvce
         and a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 24;
        o_mnsje_rspsta := 'El Documento a reversar no existe';
        return;
    end;
  
    if v_id_rcdo is null then
    
      if v_sprta_rvrso = 'S' then
        --validamos el tiempo transcurrido
        v_mntos_trnscrdos := (sysdate - v_fcha_registro) * 1440;
      
        if v_mntos_trnscrdos <= v_mntos_rvrso then
          -- borramos el registro
          begin
            delete from ws_g_recaudos_webservice a
             where a.id_rcdo_wbsrvce = v_id_rcdo_wbsrvce;
          
            if sql%rowcount = 1 then
              o_cdgo_rspsta  := 0;
              o_mnsje_rspsta := '0+Ok';
            else
              o_cdgo_rspsta  := 28;
              o_mnsje_rspsta := 'Error reversando el recaudo';
            end if;
          
            commit;
          exception
            when others then
              o_cdgo_rspsta  := 28;
              o_mnsje_rspsta := 'Error reversando el recaudo';
          end;
        
        else
          o_cdgo_rspsta  := 26;
          o_mnsje_rspsta := 'El tiempo habilitado para reversi?n fue excedido';
        end if;
      
      else
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'El documento a reversar ya no soporta reversi?n';
      end if;
    else
      o_cdgo_rspsta  := 27;
      o_mnsje_rspsta := 'El recaudo ya fue aplicado';
    end if;
  
  end;

end pkg_ws_recaudos;

/
