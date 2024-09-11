--------------------------------------------------------
--  DDL for Package Body PKG_GF_PAZ_Y_SALVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_PAZ_Y_SALVO" AS

  function fnc_co_rspnsbles_paz_y_slvo(p_cdgo_clnte     in number,
                                       p_id_sjto_impsto in number,
                                       p_id_impsto      in number)
    return clob as
  
    v_select        clob;
    v_nmro_rspnbles number;
  begin

    v_select := '<table align="center" border="0px"  style="border-collapse: collapse; font-family: Arial">

                            <tr>
								<th style="text-align:left;">Propietario(s):</th>
								<th style="text-align:left;">Documento de Identificacion</th> 							
							</tr>';
    select count(*)
      into v_nmro_rspnbles
      from si_i_sujetos_responsable
     where id_sjto_impsto = p_id_sjto_impsto;

    for c_rspnsbles in (select (b.prmer_nmbre || ' ' || b.sgndo_nmbre || ' ' ||
                               b.prmer_aplldo || ' ' || b.sgndo_aplldo) as nmbre,
                               idntfccion_rspnsble as idntfccion
                          from v_si_i_sujetos_impuesto a
                          join v_si_i_sujetos_responsable b
                            on a.id_sjto_impsto = b.id_sjto_impsto
                         where a.cdgo_clnte = p_cdgo_clnte
                           and a.id_sjto_impsto = p_id_sjto_impsto
                           and a.id_impsto = p_id_impsto
                           and rownum <= 6) loop

      v_select := v_select || '<tr><td style="text-align:left;">' ||
                  c_rspnsbles.nmbre ||
                  '</td>
												<td style="text-align:left;">' ||
                  c_rspnsbles.idntfccion || '</td>
								</tr>';
    end loop;

    if v_nmro_rspnbles > 6 then
      v_select := v_select || '<tr><td style="text-align:left;"> Y OTROS</td>
                        <td style="text-align:left;"></td>
                </tr>';
    end if;

    v_select := v_select || '</table>';
    return v_select;
  end fnc_co_rspnsbles_paz_y_slvo;

  --consultar datos de sujeto tributo  
  function fnc_co_sjto_trbto(p_cdgo_clnte     in number,
                             p_id_sjto_impsto in number,
                             p_id_impsto      in number) return clob as

    v_cdgo_sjto_tpo df_c_impuestos.cdgo_sjto_tpo%type;
    v_select_sjto   clob;

  begin
    select cdgo_sjto_tpo
      into v_cdgo_sjto_tpo
      from df_c_impuestos a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = p_id_impsto;

    if v_cdgo_sjto_tpo = 'P' then
      for c_predio in (select a.idntfccion_antrior_frmtda,
                              a.idntfccion_sjto_frmtda,
                              nvl(c.mtrcla_inmblria, 'NO DEFINIDO') as mtrcla_inmblria,
                              trim(a.drccion) as drccion,
                              c.cdgo_estrto || '-' || c.dscrpcion_estrto as cdgo_estrto,
                              to_char(c.avluo_ctstral,
                                      'FM$999G999G999G999G999G999G990') as avluo_ctstral,
                              c.area_trrno,
                              c.area_cnstrda,
                              c.cdgo_dstno_igac || '-' ||
                              c.dscrpcion_prdo_dstno as dstno
                         from v_si_i_sujetos_impuesto a
                         join v_si_i_predios c
                           on a.id_sjto_impsto = c.id_sjto_impsto
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_sjto_impsto = p_id_sjto_impsto
                          and a.id_impsto = p_id_impsto) loop
        v_select_sjto := '<table align="center" border="0px"  style="border-collapse: collapse; font-family: Arial">
                                        <tr>
                                            <th style="text-align:left;">Datos del Sujeto Tributo:</th>
                                        </tr>
                                            <tr>
                                            <td style="text-align:left;">Referencia Catastral Anterior: </td>
                                            <td style="text-align:left;">' ||
                         c_predio.idntfccion_antrior_frmtda ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Referencia Catastral Nueva:</td> 
                                            <td style="text-align:left;">' ||
                         c_predio.idntfccion_sjto_frmtda ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Matricula Inmobiliaria:</td> 
                                            <td style="text-align:left;">' ||
                         c_predio.mtrcla_inmblria ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Direccion del Predio:</td>
                                            <td tyle="text-align:left;">' ||
                         c_predio.drccion ||
                         '</td>
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Estrato:</td>
                                            <td style="text-align:left;">' ||
                         c_predio.cdgo_estrto ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Avaluo del Predio:</td>
                                            <td style="text-align:left;">' ||
                         c_predio.avluo_ctstral ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Area de Terreno:</td>
                                            <td style="text-align:left;">' ||
                         c_predio.area_trrno ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Area Construida:</td>
                                            <td style="text-align:left;">' ||
                         c_predio.area_cnstrda ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Destino:</td>
                                            <td style="text-align:left;">' ||
                         c_predio.dstno ||
                         '</td> 
                                            </tr>
                                      </table>';
      end loop;

    elsif v_cdgo_sjto_tpo = 'V' then
      for c_vhclo in (select a.idntfccion_sjto as idntfccion,
                             c.dscrpcion_vhclo_mrca as mrca,
                             c.dscrpcion_vhclo_lnea as lnea,
                             c.clndrje,
                             c.mdlo,
                             c.dscrpcion_vhclo_clse as clse,
                             c.dscrpcion_vhclo_crrocria as carroceria,
                             c.cpcdad_crga as carga,
                             c.cpcdad_psjro as pasajero,
                             to_char(g.bse_grvble,
                                     '999G999G999G999G999G999G990') ||
                             ' Vigencia ' || g.vgncia as avaluo
                        from v_si_i_sujetos_impuesto a
                        join v_si_i_vehiculos c
                          on a.id_sjto_impsto = c.id_sjto_impsto
                        join v_gi_g_liquidaciones g
                          on g.id_sjto_impsto = a.id_sjto_impsto
                         and g.vgncia =
                             (select max(gx.vgncia)
                                from gi_g_liquidaciones gx
                               where gx.id_impsto = a.id_impsto
                                 and gx.id_sjto_impsto = a.id_sjto_impsto)
                         and g.cdgo_lqdcion_estdo = 'L'
                       where a.cdgo_clnte = p_cdgo_clnte
                         and a.id_sjto_impsto = p_id_sjto_impsto
                         and a.id_impsto = p_id_impsto) loop
        v_select_sjto := '<table align="center" border="0px"  style="border-collapse: collapse; font-family: Arial">
                                        <tr>
                                            <th style="text-align:left;">Datos del Sujeto Tributo:</th>
                                        </tr>
                                            <tr>
                                            <td style="text-align:left;">Placa: </td>
                                            <td style="text-align:left;">' ||
                         c_vhclo.idntfccion ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Marca:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.mrca ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Linea:</td>
                                            <td tyle="text-align:left;">' ||
                         c_vhclo.lnea ||
                         '</td>
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Cilindraje:</td>
                                            <td style="text-align:left;">' ||
                         c_vhclo.clndrje ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Modelo:</td>
                                            <td style="text-align:left;">' ||
                         c_vhclo.mdlo ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Clase:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.clse ||
                         '</td>  
                                            </tr> 
                                            <tr>
                                            <td style="text-align:left;">Carroceria:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.carroceria ||
                         '</td>  
                                            </tr> 
                                            <tr>
                                            <td style="text-align:left;">Capacidad de Carga:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.carga ||
                         '</td>  
                                            </tr>     
                                            <tr>
                                            <td style="text-align:left;">Capacidad de Pasajero:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.pasajero ||
                         '</td>  
                                            </tr>   
                                            <tr>
                                            <td style="text-align:left;">Ultimo Avaluo:</td> 
                                            <td style="text-align:left;">' ||
                         c_vhclo.avaluo ||
                         '</td>  
                                            </tr>             
                                      </table>';
      end loop;
    elsif v_cdgo_sjto_tpo = 'E' then

      for c_estblcmnto in (select a.idntfccion_sjto_frmtda as identificacion
                                  -- , c.nmbre_rzon_scial as propietario
                                 ,
                                  decode(a.drccion,
                                         null,
                                         'No Definido',
                                         a.drccion) as drccion,
                                  decode(a.drccion_ntfccion,
                                         null,
                                         'No Definido',
                                         a.drccion_ntfccion) as drccion_ntfccion,
                                  b.nmbre_rzon_scial as rzon_scial,
                                  decode(b.nmro_scrsles,
                                         null,
                                         'No Definido',
                                         b.nmro_scrsles) as nmero_sucrsles,
                                  b.dscrpcion_tpo_prsna as tpo_prsna,
                                  decode(b.drccion_cmra_cmrcio,
                                         null,
                                         'No Definido',
                                         b.drccion_cmra_cmrcio) as drcconn_cmra_cmrcio,
                                  a.dscrpcion_sjto_estdo
                             from v_si_i_sujetos_impuesto a
                             join v_si_i_personas b
                               on a.id_sjto_impsto = b.id_sjto_impsto
                             join v_si_i_sujetos_responsable c
                               on a.id_sjto_impsto = c.id_sjto_impsto
                              and c.prncpal_s_n = 'S'
                            where a.cdgo_clnte = p_cdgo_clnte
                              and a.id_sjto_impsto = p_id_sjto_impsto
                              and a.id_impsto = p_id_impsto
                              and a.estdo_blqdo_sjto = 'N') loop
        v_select_sjto := '<table align="center" border="0px"  style="border-collapse: collapse; font-family: Arial">
                                        <tr>
                                            <th style="text-align:left;">Datos del Sujeto Tributo:</th>
                                        </tr>
                                            <tr>
                                            <td style="text-align:left;">Identificacion: </td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.identificacion ||
                         '</td> 
                                            </tr>                                            
                                            <tr>
                                            <td style="text-align:left;">Direccion:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.drccion ||
                         '</td>
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Direccion de Notificacion:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.drccion_ntfccion ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Razon Social:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.rzon_scial ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Numero de Sucursales:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.nmero_sucrsles ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Tipo de Persona:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.tpo_prsna ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Direccion de Camara de Comercio:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.drcconn_cmra_cmrcio ||
                         '</td> 
                                            </tr>
                                            <tr>
                                            <td style="text-align:left;">Estado:</td>
                                            <td style="text-align:left;">' ||
                         c_estblcmnto.dscrpcion_sjto_estdo ||
                         '</td> 
                                            </tr>                                            
                                      </table>';
      end loop;
    end if;

    return v_select_sjto;
  end fnc_co_sjto_trbto;

  --registrat paz y salvo
   procedure prc_rg_paz_salvo(p_cdgo_clnte        in number,
                             p_id_impsto         in gf_g_paz_y_salvo.id_impsto%type,
                             p_id_impsto_sbmpsto in gf_g_paz_y_salvo.id_impsto_sbmpsto%type,
                             p_id_sjto_impsto    in gf_g_paz_y_salvo.id_sjto_impsto%type,
                             p_id_usrio          in number,
                             p_cnsctvo           in gf_g_paz_y_salvo.cnsctvo%type,
                             p_cdgo_cnsctvo      in varchar2,
                             p_id_plntlla        in gn_d_plantillas.id_plntlla%type,
                             p_txto_ascda        in varchar2 default null,
                             p_id_dcmnto         in number default null,
                             o_id_acto           out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out varchar2) as

    v_nl            number;
    v_nmbre_up    sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_paz_y_salvo.prc_rg_paz_salvo';
    v_nmro_cntrol number;
    v_cnsctvo     gf_g_paz_y_salvo.cnsctvo%type;
    v_id_pz_slvo  gf_g_paz_y_salvo.id_pz_slvo%type;
    v_nmro_acto   gn_g_actos.nmro_acto%type;
  begin
    --Determinamos el Nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,null,v_nmbre_up);

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);

    --Insertamos el paz y salvo 
    begin
      --  v_cnsctvo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'PYZ');
     /* v_nmro_cntrol := p_cnsctvo || p_id_impsto || p_id_impsto_sbmpsto ||
                       p_id_sjto_impsto || p_cdgo_clnte ||
                       to_char(sysdate, 'DDMMYYYHHMISS');
    */
      insert into gf_g_paz_y_salvo
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         fcha_pz_slvo,
         id_plntlla)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         sysdate,
         p_id_plntlla)
         returning id_pz_slvo into v_id_pz_slvo;
    exception
      when others then

        o_mnsje_rspsta := o_mnsje_rspsta ||' Excepcion al Registrar el Paz y salvo. ' ||sqlerrm;
        o_cdgo_rspsta  := 1;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
        rollback;
        return;
       -- commit;
    end;

    -- Se crea el acto
    begin
        pkg_gf_paz_y_salvo.prc_gn_acto_paz_y_salvo( p_cdgo_clnte            => p_cdgo_clnte
                                                    ,p_id_usrio             => p_id_usrio
                                                    ,p_id_pz_slvo           => v_id_pz_slvo
                                                    ,p_id_sjto_impsto       => p_id_sjto_impsto
                                                    ,p_id_plntlla           => p_id_plntlla 
                                                    ,p_cdgo_acto_tpo        => 'PYS'
                                                    ,p_id_impsto            => p_id_impsto
                                                    ,p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto
                                                    ,p_cnsctvo              => p_cnsctvo 
                                                    ,p_cdgo_cnsctvo         => p_cdgo_cnsctvo 
                                                    ,p_txto_ascda           => p_txto_ascda 
                                                    ,p_id_dcmnto            => p_id_dcmnto 
                                                    ,o_id_acto              => o_id_acto
                                                    ,o_cdgo_rspsta          => o_cdgo_rspsta
                                                    ,o_mnsje_rspsta         => o_mnsje_rspsta);

          if (o_cdgo_rspsta != 0) or o_id_acto is null then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'No se genero el acto de paz y salvo. ' ||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
            rollback;
            return;
          end if;

    exception
        when others then
            o_mnsje_rspsta := o_mnsje_rspsta ||' Excepcion al Registrar el Paz y salvo. ' ||sqlerrm;
            o_cdgo_rspsta  := 1;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
            rollback;
            return;  
    end;

    -- Se busca el numero del consecutivo del acto
    begin
        select nmro_acto
        into   v_nmro_acto
        from   gn_g_actos
        where  id_acto = o_id_acto;
    exception
        when no_data_found then
            o_mnsje_rspsta := o_mnsje_rspsta ||' No existe el id acto en la tabla actos. ' ||sqlerrm;
            o_cdgo_rspsta  := 5;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
            rollback;
            return;  
        when others then
            o_mnsje_rspsta := o_mnsje_rspsta ||' No se pudo consultar el numero del acto en la tabla actos. ' ||sqlerrm;
            o_cdgo_rspsta  := 5;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
            rollback;
            return;              
    end;    

    -- Se actualiza el id del acto en la tabla de paz y salvo           
    begin

         v_nmro_cntrol := v_nmro_acto || p_id_impsto || p_id_impsto_sbmpsto ||
                       p_id_sjto_impsto || p_cdgo_clnte ||
                       to_char(sysdate, 'DDMMYYYHHMISS');

        update gf_g_paz_y_salvo
        set    id_acto = o_id_acto
              ,cnsctvo = v_nmro_acto
              ,nmro_ctrol = v_nmro_cntrol
        where  id_pz_slvo = v_id_pz_slvo;
    exception
        when others then
            o_mnsje_rspsta := o_mnsje_rspsta ||' No se pudo actualizar el acto en la tabla de paz y salvo. ' ||sqlerrm;
            o_cdgo_rspsta  := 5;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
            rollback;
            return;  
    end;    

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);

    o_mnsje_rspsta := 'Exito';

  end prc_rg_paz_salvo;

  --Funcion Body
  function fnc_co_ultmo_acto(p_id_fsclzcion_expdnte number)
    return g_dtos_dtlle
    pipelined is

    v_dtos_dtlle t_dtos_dtlle;

  begin

    select b.nmro_acto, a.fcha_crcion, a.id_fsclzcion_expdnte, c.dscrpcion
      into v_dtos_dtlle.nmro_acto,
           v_dtos_dtlle.fcha_crcion,
           v_dtos_dtlle.id_fsclzcion_expdnte,
           v_dtos_dtlle.tpo_acto
      from fi_g_fsclzcion_expdnte_acto a
      join gn_g_actos b
        on a.id_acto = b.id_acto
      join gn_d_actos_tipo c
        on a.id_acto_tpo = c.id_acto_tpo
     where id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
     order by 2 desc
     fetch first 1 rows only;

    pipe row(v_dtos_dtlle);

  end fnc_co_ultmo_acto;

  procedure prc_rg_estdo_cnta(p_cdgo_clnte       in number,
                              p_cnsctvo          in number,
                              p_id_sjto_rspnsble in si_i_sujetos_responsable.id_sjto_rspnsble%type,
                              p_id_usrio_rgstro  in sg_g_usuarios.id_usrio%type,
                              o_cdgo_rspsta      out number,
                              o_mnsje_rspsta     out varchar2) as
    v_nvel        number;
    v_nmbre_up    sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_paz_y_salvo.prc_rg_estdo_cnta';
    v_nmro_cntrol number;
  begin
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    --Insertamos el paz y salvo 
    begin

      insert into gf_g_estados_cuenta
        (cdgo_clnte, cnsctvo, id_sjto_rspnsble, id_usrio_rgstro)
      values
        (p_cdgo_clnte, p_cnsctvo, p_id_sjto_rspnsble, p_id_usrio_rgstro);
    exception
      when others then

        o_mnsje_rspsta := o_mnsje_rspsta ||
                          ' Excepcion al Registrar el Estado de Cuenta. ' ||
                          sqlerrm;
        o_cdgo_rspsta  := 1;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 4);

        return;

        commit;
    end;
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Exito';
  end prc_rg_estdo_cnta;

  --registrat certificado
  procedure prc_rg_certificado(p_cdgo_clnte       in number,
                               p_id_impsto        in gf_g_certificados.id_impsto%type,
                               p_id_sjto_impsto   in gf_g_certificados.id_sjto_impsto%type,
                               p_id_sjto_rspnsble in gf_g_certificados.id_sjto_rspnsble%type,
                               p_cnsctvo          in gf_g_certificados.cnsctvo%type,
                               p_indcdr_prtal     in gf_g_certificados.indcdor_prtal%type,
                               p_cdgo_crtfcdo_tpo in gf_g_certificados.cdgo_crtfcdo_tpo%type,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2) as
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gf_paz_y_salvo.prc_rgcertificadoo';
  begin
    --Determinamos el Nivel del Log de la UP
    v_nvel         := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                                  p_id_impsto  => null,
                                                  p_nmbre_up   => v_nmbre_up);
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    --Insertamos el certificado
    begin
      insert into gf_g_certificados
        (cdgo_clnte,
         id_impsto,
         id_sjto_impsto,
         id_sjto_rspnsble,
         cnsctvo,
         indcdor_prtal,
         cdgo_crtfcdo_tpo)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_sjto_impsto,
         p_id_sjto_rspnsble,
         p_cnsctvo,
         p_indcdr_prtal,
         p_cdgo_crtfcdo_tpo);
    exception
      when others then

        o_mnsje_rspsta := o_mnsje_rspsta ||
                          ' Excepcion al Registrar el Certificado. ' ||
                          sqlerrm;
        o_cdgo_rspsta  := 1;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 4);
        return;
        commit;
    end;
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
    o_mnsje_rspsta := 'Exito';
  end prc_rg_certificado;

  function fnc_co_sjto_scrsal(p_id_sjto_impsto in number) return clob as

    v_select_sjto clob;
  begin
    v_select_sjto := '<table align="center" border="1px"  style="border-collapse: collapse; width:100%;font-size:9px">
    <tr>
      <th style ="width:30%">Sucursal</th>
      <th style ="width:35%">Direcci&oacute;n</th>
      <th style ="width:10%">Tel&eacute;fono</th>
      <th style ="width:25%">Email</th>
    </tr>';

    for r1 in (select c.nmbre, c.drccion, c.tlfno, c.email
                 from si_i_sujetos_sucursal c
                where c.id_sjto_impsto = p_id_sjto_impsto
                  and c.actvo = 'S'
                order by c.id_sjto_scrsal) loop
      v_select_sjto := v_select_sjto || '<tr><td>' || r1.nmbre ||
                       '</td><td>' || r1.drccion || '</td> <td>' ||
                       r1.tlfno || '</td><td>' || r1.email || '</td></tr>';
    end loop;
    v_select_sjto := v_select_sjto || '</table>';
    return v_select_sjto;
  end;
  procedure prc_gn_acto_paz_y_salvo  (p_cdgo_clnte         in number,
                                       p_id_pz_slvo         in number,
                                       p_id_impsto          in number,
                                       p_id_impsto_sbmpsto  in number,
                                       p_id_sjto_impsto     in number,
                                       p_cnsctvo            in number,
                                       p_cdgo_cnsctvo       in varchar2, 
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       p_cdgo_acto_tpo      in varchar2,  
                                       p_txto_ascda         in varchar2 default null,
                                       p_id_dcmnto          in number default null,
                                       o_id_acto            out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2 ) as
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_paz_y_salvo.prc_gn_acto_paz_y_salvo';

    v_error                 exception;
    v_id_slctud             number;
    v_id_mtvo               number;
    v_indcdor               varchar2(1);
    v_gn_d_reportes         gn_d_reportes%rowtype;
    v_app_page_id           number :=  v('APP_PAGE_ID');
    v_app_id                number :=  v('APP_ID');

    v_slct_sjto_impsto      clob;
    v_slct_rspnsble         clob;
    v_json_acto             clob;
    v_id_acto_tpo           number;
    v_id_acto               number;
    v_id_plntlla            number;
    v_id_orgen              number;
    v_dcmnto                clob;
    v_blob                  blob;

    v_type_rspsta           varchar2(1);
    v_dato                  varchar2(100);
    v_cdgo_dstno_dcmnto     gn_d_actos_tipo.cdgo_dstno_dcmnto%type;
    v_nmbre_drctrio         gn_d_actos_tipo.nmbre_drctrio%type;
    v_nmbre_archvo          varchar2(100);
    v_nmro_acto             number;
    v_id_usrio_apex         number;
  begin
    DBMS_OUTPUT.PUT_LINE('Entro');

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    -- GENERACION DEL ACTO --
    -- Select para obtener el sub-tributo y sujeto impuesto
    v_slct_sjto_impsto := 'select distinct  id_impsto  ,id_impsto_sbmpsto,  id_sjto_impsto
              from gf_g_paz_y_salvo 
               where id_sjto_impsto   = ' || p_id_sjto_impsto;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_sjto_impsto:' || v_slct_sjto_impsto,
                          6);

    -- Select para obtener los responsables de un acto
    v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo
                   , a.idntfccion
                   , a.prmer_nmbre
                   , a.sgndo_nmbre 
                   , a.prmer_aplldo
                   , a.sgndo_aplldo
                   , nvl(a.drccion_ntfccion, b.drccion_ntfccion)        drccion_ntfccion
                   , nvl(a.id_pais_ntfccion, b.id_pais_ntfccion)        id_pais_ntfccion
                   , nvl(a.id_dprtmnto_ntfccion, b.id_dprtmnto_ntfccion)id_dprtmnto_ntfccion
                   , nvl(a.id_mncpio_ntfccion, b.id_mncpio_ntfccion)    id_mncpio_ntfccion
                   , a.email
                   , a.tlfno
                from si_i_sujetos_responsable     a 
                join si_i_sujetos_impuesto          b on a.id_sjto_impsto = b.id_sjto_impsto
                where b.id_sjto_impsto        = ' || p_id_sjto_impsto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_rspnsble:' || v_slct_rspnsble,
                          6);

    v_id_orgen := p_id_pz_slvo;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_orgen:' || v_id_orgen,
                          6);

    -- Se consulta el id del tipo del acto
    begin
      select id_acto_tpo, cdgo_dstno_dcmnto
        into v_id_acto_tpo, v_cdgo_dstno_dcmnto
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = p_cdgo_acto_tpo;

      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro el tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id del tipo del acto

    -- Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'PYS',
                                                           p_id_orgen            => p_id_pz_slvo,    
                                                           p_id_undad_prdctra    => p_id_pz_slvo,    
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => p_cdgo_cnsctvo,  
                                                           /*p_cdgo_cnsctvo        => 'PYZ', --Paz y salvo por impuesto
                                                            p_cdgo_cnsctvo        => 'PPE', --PAZ Y SALVO PUBLICIDAD EXTERIOR VISUAL
                                                            p_cdgo_cnsctvo        => 'PZD', --Paz y Salvo Delineaci¿n Urbana
                                                           */
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_rspnsble       => v_slct_rspnsble);

    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el json del acto ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del json para el Acto

    -- Generacion del Acto  
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);

      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Generacion de Acto. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta || ' o_id_acto: ' || o_id_acto,
                            6);

      if o_cdgo_rspsta != 0 or o_id_acto < 1 or o_id_acto is null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del Acto  
    -- FIN GENERACION DEL ACTO

    -- GENERACION DE LA PLANTILLA Y REPORTE
    -- Se consulta el id de la plantilla
    begin
      select a.id_plntlla
        into v_id_plntlla
        from gn_d_plantillas a
       where id_plntlla = p_id_plntlla;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_plntlla: ' || v_id_plntlla,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro la plantilla ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la plantilla ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id de la plantilla


    begin
        select nmro_acto
        into v_nmro_acto
        from gn_g_actos
        where id_acto = o_id_acto;
   exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': No se encontro el numero del acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        rollback;
        return;
     when others then
       o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Problemas a consultar el numero del acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        rollback;
        return;
    end;

    -- Generar el HTML combinado de la plantilla
    begin
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<cdgo_clnte>'         ||p_cdgo_clnte          ||'</cdgo_clnte>
                          <id_impsto>'            ||p_id_impsto           ||'</id_impsto>
                                                    <id_impsto_sbimpsto>'   ||p_id_impsto_sbmpsto   ||'</id_impsto_sbimpsto> 
                                                    <id_sjto_impsto>'       ||p_id_sjto_impsto      ||'</id_sjto_impsto> 
                                                    <usrio>'                ||p_id_usrio            ||'</usrio> 
                                                    <id_dcmnto>'            ||p_id_dcmnto            ||'</id_dcmnto> 
                                                    <txto_ascda>'           ||p_txto_ascda          ||'</txto_ascda> 
                                                    <cnsctvo>'              ||v_nmro_acto             ||'</cnsctvo>',
                                                     p_id_plntlla);

      pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,'Genero el html del documento',6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,'p_id_impsto: '||p_id_impsto
      || 'p_id_impsto_sbmpsto :'||p_id_impsto_sbmpsto
      ||'p_id_sjto_impsto: '||p_id_sjto_impsto
      ||'p_id_usrio: '||p_id_usrio
      ||'p_cnsctvo: '||v_nmro_acto
      ||'p_id_dcmnto: '||p_id_dcmnto
      ||'v_nmro_acto: '||v_nmro_acto
      ||'p_txto_ascda: '||p_txto_ascda
      ,6);

     if v_dcmnto is null then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el html de la plantilla';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el html de la plantilla ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generar el HTML combinado de la plantilla

    -- Se Consultan los datos del reporte
    begin
      select b.*
        into v_gn_d_reportes
        from gn_d_plantillas a
        join gn_d_reportes b
          on a.id_rprte = b.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;

      o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
                        v_gn_d_reportes.nmbre_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);

    exception
      when no_data_found then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informacion del reporte ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informacion del reporte ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Consultamos los datos del reporte 

    -- Generacion del reporte
    begin

              /* apex_session.create_session(p_app_id   => 66000,
                                            p_page_id  => 37,
                                            p_username => '1111111112');*/

            if v('APP_SESSION') is null then
                v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                   p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                                   p_cdgo_dfncion_clnte        => 'USR');

                apex_session.create_session(p_app_id   => 66000,
                                            p_page_id  => 37,
                                            p_username => v_id_usrio_apex);
            else
                --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION')); 
                apex_session.attach(p_app_id     => 66000,
                                    p_page_id    => 37,
                                    p_session_id => v('APP_SESSION'));
            end if;

            /* -- Si existe la Sesion
            apex_session.attach(p_app_id     => 66000,
                                p_page_id    => 37,
                                p_session_id => v('APP_SESSION'));*/


      apex_util.set_session_state('P37_JSON',
                                  '{"nmbre_rprte":"' ||v_gn_d_reportes.nmbre_rprte ||
                                  '","id_orgen":"' || v_id_orgen ||
                                  '","cdgo_clnte":"' || p_cdgo_clnte ||
                                  '","id_impsto":"' || p_id_impsto ||
                                  '","id_impsto_sbimpsto":"' || p_id_impsto_sbmpsto ||
                                  '","id_sjto_impsto":"' || p_id_sjto_impsto ||
                                  '","usrio":"' || p_id_usrio ||
                                  '","cnsctvo":"' || v_nmro_acto ||
                                  '","id_dcmnto":"' || p_id_dcmnto ||
                                  '","txto_ascda":"' || p_txto_ascda ||
                                  '","id_rprte":"' || p_id_plntlla || '"}');

      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);

      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo la sesion',
                            6);

      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo el blob',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Tama?o blob:' || length(v_blob),
                            6);

      if v_blob is null then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el blob de acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el blob ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Generacion del reporte


   -- Actualizar el blob en la tabla de acto
    if v_blob is not null then

         if (v_cdgo_dstno_dcmnto = 'BFILE') then
            --Buscamos el nombre del directorio
            begin
              select nmbre_drctrio
                into v_nmbre_drctrio
                from gn_d_actos_tipo
               where cdgo_clnte = p_cdgo_clnte
                 and cdgo_acto_tpo = p_cdgo_acto_tpo;

            exception
              when no_data_found then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No se ha definido el directorio de destino.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
              when others then
                o_cdgo_rspsta  := 45;
                o_mnsje_rspsta := 'Error al intentar consultar el directorio de destino.' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
            end;
            --Generamos el numbre del archivo
            select cdgo_acto_orgen || nmro_acto_dsplay || '.pdf'
              into v_nmbre_archvo
              from gn_g_actos
             where id_acto = o_id_acto;

            pkg_gd_utilidades.prc_rg_dcmnto_dsco(p_blob         => v_blob,
                                                 p_directorio   => v_nmbre_drctrio,
                                                 p_nmbre_archvo => v_nmbre_archvo,
                                                 o_cdgo_rspsta  => o_cdgo_rspsta,
                                                 o_mnsje_rspsta => o_mnsje_rspsta);
            if (o_cdgo_rspsta = 0) then
              pkg_gn_generalidades.prc_ac_acto(p_directory       => v_nmbre_drctrio,
                                               p_file_name_dsco  => v_nmbre_archvo,
                                               p_id_acto         => o_id_acto,
                                               p_ntfccion_atmtca => 'N');
            else
              o_cdgo_rspsta  := o_cdgo_rspsta;
              o_mnsje_rspsta := v_nmbre_up || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
            end if;

          elsif (v_cdgo_dstno_dcmnto = 'BLOB') then
            begin
                pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                                 p_id_acto         => o_id_acto,
                                                 p_ntfccion_atmtca => 'N');
            exception
                when others then
                  o_cdgo_rspsta  := 13;
                  o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||' : Error al actualizar el blob para el id_acto : '|| o_id_acto|| '-'|| sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
                  rollback;
                  return;
            end;                                             
          end if;

    else  --v_blob is null
      o_cdgo_rspsta  := 14;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': No se genero el blob para el id_acto : '|| o_id_acto|| '-'|| sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,1);
      rollback;
      return;
    end if; -- FIn Actualizar el blob en la tabla de acto

    -- Bifurcacion
    apex_session.attach(p_app_id     => 71000,
                        p_page_id    => 406,
                        p_session_id => v('APP_SESSION'));
    -- FIN GENERACION DE LA PLANTILLA Y REPORTE

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Acto generado Exitosamente';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);

  end prc_gn_acto_paz_y_salvo;

  PROCEDURE PRC_GENERA_PAZ_SALVO_MASIVO(
    p_cdgo_clnte    IN NUMBER,
    p_id_usuario    IN NUMBER,
    p_id_session    IN NUMBER,
    p_id_plntlla    IN gn_d_plantillas.id_plntlla%TYPE,
    o_cdgo_rspsta   OUT NUMBER,
    o_mnsje_rspsta  OUT VARCHAR2
) 
AS
    v_nvel          NUMBER;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GF_PAZ_Y_SALVO.PRC_GENERA_PAZ_SALVO_MASIVO'; 
    v_documento     BLOB;
    v_id_acto       NUMBER; 
BEGIN
    -- Respuesta Exitosa
    o_cdgo_rspsta := 0;

    -- Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => NULL, p_nmbre_up => v_nmbre_up);

    o_mnsje_rspsta := 'Inicio del procedimiento. Sesión ' || p_id_session;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => NULL, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 1);

    FOR CUR IN (
        SELECT N001 AS ID_IMPSTO, N002 AS ID_SB_IMPSTO, C006 AS ID_SJTO_IMPSTO
        FROM GN_G_TEMPORAL
        WHERE ID_SSION = p_id_session AND C005 = 'Paz y Salvo'
    ) LOOP
        BEGIN
            pkg_gf_paz_y_salvo.prc_rg_paz_salvo(
                p_cdgo_clnte        => p_cdgo_clnte,
                p_id_impsto         => CUR.ID_IMPSTO,
                p_id_impsto_sbmpsto => CUR.ID_SB_IMPSTO,
                p_id_sjto_impsto    => CUR.ID_SJTO_IMPSTO,
                p_id_usrio          => p_id_usuario,
                p_cnsctvo           => NULL,
                p_cdgo_cnsctvo      => 'PYZ',
                p_id_plntlla        => p_id_plntlla,
                o_id_acto           => v_id_acto,
                o_cdgo_rspsta       => o_cdgo_rspsta,
                o_mnsje_rspsta      => o_mnsje_rspsta
            );

            IF o_cdgo_rspsta > 0 THEN	
                ROLLBACK;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, NULL, v_nmbre_up, v_nvel, 'No se registra Paz y Salvo para: ' || CUR.ID_SJTO_IMPSTO || ' - ' || o_mnsje_rspsta, 1);
                CONTINUE;
            END IF;

            -- Obtener el documento en formato BLOB
            v_documento := pkg_gd_utilidades.fnc_co_blob(v_id_acto);

            -- Actualiza la tabla GN_G_TEMPORAL con el valor de v_id_acto
            UPDATE GN_G_TEMPORAL 
            SET BLOB001 = v_documento, N003 = v_id_acto 
            WHERE ID_SSION = p_id_session AND C006 = CUR.ID_SJTO_IMPSTO;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN	
                ROLLBACK;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, NULL, v_nmbre_up, v_nvel, 'Error registro Paz y Salvo: ' || CUR.ID_SJTO_IMPSTO || ' - ' || SQLERRM, 1);
                CONTINUE;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        raise_application_error(-20001, 'No se pudo realizar la ejecución: ' || SQLERRM);

END PRC_GENERA_PAZ_SALVO_MASIVO;



PROCEDURE PRC_GENERA_PAZ_SALVO_MASIVO_JOB(
    p_cdgo_clnte    IN NUMBER,
    p_id_usuario    IN NUMBER,
    p_id_session    IN NUMBER,
    p_id_plntlla    IN gn_d_plantillas.id_plntlla%TYPE
) 
AS
    v_nvel          NUMBER;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GF_PAZ_Y_SALVO.PRC_GENERA_PAZ_SALVO_MASIVO_JOB'; 
    v_zip_file      BLOB;
    o_cdgo_rspsta   NUMBER;
    o_mnsje_rspsta  VARCHAR2(4000);
    v_json_parametros VARCHAR2(4000);   
BEGIN
    -- Respuesta Exitosa
    o_cdgo_rspsta := 0;

    -- Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(
                p_cdgo_clnte => p_cdgo_clnte, 
                p_id_impsto => NULL, 
                p_nmbre_up => v_nmbre_up
              );

    -- Registrar inicio del procedimiento
    o_mnsje_rspsta := 'Inicio del procedimiento. Sesión ' || p_id_session;
    pkg_sg_log.prc_rg_log(
        p_cdgo_clnte => p_cdgo_clnte, 
        p_id_impsto => NULL, 
        p_nmbre_up => v_nmbre_up, 
        p_nvel_log => v_nvel, 
        p_txto_log => o_mnsje_rspsta, 
        p_nvel_txto => 1
    );

    BEGIN
        -- Llamar al procedimiento masivo
        pkg_gf_paz_y_salvo.PRC_GENERA_PAZ_SALVO_MASIVO(
														p_cdgo_clnte => p_cdgo_clnte,
														p_id_usuario => p_id_usuario,
														p_id_session => p_id_session,
														p_id_plntlla => p_id_plntlla,
														o_cdgo_rspsta => o_cdgo_rspsta,
														o_mnsje_rspsta => o_mnsje_rspsta
        );



        -- Añadir archivos al BLOB ZIP
        FOR c_paz_salvos IN (
            SELECT c.file_blob, c.file_name 
            FROM gn_g_temporal a 
            JOIN v_gn_g_actos b ON a.n003 = b.id_acto
            LEFT JOIN gd_g_documentos c ON b.id_dcmnto = c.id_dcmnto
            WHERE b.id_dcmnto IS NOT NULL AND a.ID_SSION = p_id_session
        ) LOOP
            apex_zip.add_file(
                p_zipped_blob => v_zip_file,
                p_file_name   => c_paz_salvos.file_name,
                p_content     => c_paz_salvos.file_blob
            );
        END LOOP;

        -- Finalizar el BLOB ZIP
        apex_zip.finish(p_zipped_blob => v_zip_file);

        -- Insertar el BLOB ZIP en la tabla temporal
        BEGIN
            INSERT INTO gn_g_temporal (ID_SSION, C005, BLOB001, C007, C008, n004)
            VALUES (p_id_session, 'ZIP_Paz_y_Salvo', v_zip_file, 'Paz_y_Salvos.zip', 'application/zip', p_id_usuario);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20001, 'Error en el INSERT en gn_g_temporal: ' || SQLERRM);
        END;


        COMMIT;

        -- Consultamos los envíos programados
        BEGIN
            SELECT json_object(
               key 'p_id_usuario' VALUE p_id_usuario
            ) INTO v_json_parametros FROM dual;

            pkg_ma_envios.prc_co_envio_programado(
                p_cdgo_clnte => p_cdgo_clnte,
                p_idntfcdor => 'PAZ_Y_SALVOS',
                p_json_prmtros => v_json_parametros
            );
            o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
            pkg_sg_log.prc_rg_log(
                p_cdgo_clnte => p_cdgo_clnte,
                p_id_impsto => NULL,
                p_nmbre_up => v_nmbre_up,
                p_nvel_log => v_nvel,
                p_txto_log => o_mnsje_rspsta,
                p_nvel_txto => 1
            );
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error en los envios programados, ' || SQLERRM;
                pkg_sg_log.prc_rg_log(
                    p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto => NULL,
                    p_nmbre_up => v_nmbre_up,
                    p_nvel_log => v_nvel,
                    p_txto_log => o_mnsje_rspsta,
                    p_nvel_txto => 1
                );
                ROLLBACK;
                RETURN;
        END; -- Fin Consultamos los envios programados

        -- Verificar el código de respuesta
        IF o_cdgo_rspsta > 0 THEN   
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, o_mnsje_rspsta);                                               
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'No se pudo realizar la ejecución: ' || SQLERRM);
    END;

END PRC_GENERA_PAZ_SALVO_MASIVO_JOB;




END PKG_GF_PAZ_Y_SALVO;


/
