--------------------------------------------------------
--  DDL for Package Body PKG_RECAUDOS_CAJA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_RECAUDOS_CAJA" as

    function fnc_gn_cnsctvo_usrio_cja(p_id_rcdo_cja in  number
                                    , p_id_usrio    in  number)
    return number
    is
        v_cnsctvo   number;

    begin
        begin
            select (cnsctvo_cntrol+1) into v_cnsctvo
              from re_g_recaudos_caja
             where id_rcdo_cja = p_id_rcdo_cja
               and id_usrio = p_id_usrio;
        exception
            when no_data_found then
                v_cnsctvo := 1;
        end;

        -- Actualizar el consecutivo de los recaudos
        update re_g_recaudos_caja
        set cnsctvo_cntrol = v_cnsctvo
        where id_rcdo_cja = p_id_rcdo_cja
          and id_usrio = p_id_usrio;
        commit;

        return v_cnsctvo;

    end fnc_gn_cnsctvo_usrio_cja;

  procedure prc_rg_caja(p_cdgo_clnte	        in  number
                        , p_id_bnco		        in  number
                        , p_fcha_aprtra		    in  date
                        , p_obsrvcion		    in  varchar2
                        , p_id_usrio            in  number
                        , o_id_rcdo_cja        out  number
                        , o_cdgo_rspsta        out  number
                        , o_mnsje_rspsta       out  varchar2) as

    v_exste_cja number;
  begin

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := null;

    begin
        select 1 into v_exste_cja
        from re_g_recaudos_caja
        where cdgo_clnte = p_cdgo_clnte
        and id_bnco = p_id_bnco
        and id_usrio = p_id_usrio
        and estdo_aprtra = 'A';
    exception
        when others then
            v_exste_cja := null;
    end;

    if v_exste_cja is null then
        insert into re_g_recaudos_caja(cdgo_clnte
                                    , id_bnco
                                    , fcha_aprtra
                                    , obsrvcion
                                    , cntdad_rcdos
                                    , vlor_rcdos
                                    , cdgo_rcdo_orgen
                                    , id_usrio
                                    , estdo_aprtra
                                    , fcha_rgstro
                                    , cnsctvo_cntrol)
         values(p_cdgo_clnte
               , p_id_bnco
               , sysdate
               , p_obsrvcion
               , 0
               , 0
               , 'CA'
               , p_id_usrio
               , 'A'
               , sysdate
               , 0) returning id_rcdo_cja into o_id_rcdo_cja;
    end if;

    commit;

  exception
    when others then
        o_id_rcdo_cja   := 0;
        o_cdgo_rspsta   := 1;
        o_mnsje_rspsta  := 'No se pudo registrar la caja.';
  end prc_rg_caja;

  procedure prc_ac_cerrar_caja(p_id_rcdo_cja  in  number
                             , o_cdgo_rspsta  out number
                             , o_mnsje_rspsta out varchar2)
  as
    v_estdo_aprtra varchar2(1);

  begin

    begin
        select estdo_aprtra into v_estdo_aprtra
        from re_g_recaudos_caja
        where id_rcdo_cja = p_id_rcdo_cja;
    exception
        when no_data_found then
            v_estdo_aprtra := null;
    end;

    if v_estdo_aprtra = 'A' then
        update re_g_recaudos_caja
        set estdo_aprtra = 'C',
            obsrvcion = obsrvcion||'. Caja cerrada el '||to_char(sysdate,'dd_mm_yyyy')||'.',
            fcha_crre = sysdate
        where id_rcdo_cja = p_id_rcdo_cja;
    end if;

    commit;

    o_cdgo_rspsta   := 0;
    o_mnsje_rspsta  := 'OK';

  exception
    when others then
        o_cdgo_rspsta   := 1;
        o_mnsje_rspsta  := 'No se pudo cerrar la caja.';
  end prc_ac_cerrar_caja;

  -- UP que registra los recaudos a la caja al mismo tiempo que
  -- son registrados en las tablas de recaudos.
  procedure prc_rg_recaudos_caja(p_cdgo_clnte	         in  number
                               , p_id_rcdo_cja           in  number
                               , p_id_impsto             in  number
                               , p_id_impsto_sbmpsto     in  number
                               , p_id_sjto_impsto        in  number
                               , p_cdgo_rcdo_orgn_tpo    in  varchar2
                               , p_id_orgen              in  number
                               , p_vlor_real_rcbdo       in  number
                               , p_vlor                  in  number
                               , p_vlor_cmbio            in  number
                               , p_cdgo_frma_pgo_cja     in  clob
                               , p_cdgo_rcdo_estdo       in  varchar2 default 'IN'
                               , p_id_usrio              in  number
                               , o_nmro_lqdcion          out number
                               , o_cdgo_rspsta           out number
                               , o_mnsje_rspsta          out varchar2)
  as

    v_cdgo_frma_pgo     varchar2(2);
    v_exste_cntrol_rcdo number;
    v_id_bnco_cnta      number;
    v_rcdo_cntrol       number;
    v_cdgo_rspsta       number;
    v_mnsje_rspsta      varchar2(4000);
    v_id_rcdo           number;
    v_cdgo_clnte        number;
    v_id_usrio          number;
    v_id_rcdo_cja_dtlle number;
    v_vlor_pdl          df_c_definiciones_cliente.vlor%type;
    v_dplcdos           number;
    v_id_rcdo_frma_pgo  number;
    v_cnsctvo_rcdo      number;
    ex_orgen_rcddo      exception;
    v_dcmnto_rcddo      number;
  begin

    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';

    v_id_usrio := p_id_usrio;

    -- 02-06-2021 09:11 a.m. JAGUAS
    if dbms_lob.getlength(p_cdgo_frma_pgo_cja) = 0 or p_cdgo_frma_pgo_cja is null then
       --insert into muerto2(v_001, v_002, c_001, t_001)
       --values('trazas_caja', p_id_rcdo_cja, p_cdgo_frma_pgo_cja, systimestamp);
       --commit;
        o_cdgo_rspsta := 15;
        o_mnsje_rspsta := 'No se puede registrar el recaudo porque no se han especificado formas de pago.';
      return;
    end if;

    -- Validar si el documento ya se encuentra pagado
    select count(1) into v_dcmnto_rcddo
       from re_g_recaudos
       where id_orgen = p_id_orgen;

    if v_dcmnto_rcddo > 0 then
       raise ex_orgen_rcddo;
    end if;

    -- Buscar si existe un recaudo control del impuesto y sub-impuesto en la fecha actual.
    -- Si existe obtenemos el ID del recaudo control
    -- Sino, creamos el recaudo control retornando el ID
    begin
        select c.id_rcdo_cntrol into v_rcdo_cntrol
        from re_g_recaudos_control c
        where c.id_impsto           = p_id_impsto
          and c.id_impsto_sbmpsto   = p_id_impsto_sbmpsto
          and trunc(c.fcha_cntrol)  = trunc(sysdate);
    exception
        when no_data_found then -- Si no existe un lote lo crea nuevo

            for c_rcdo_cja in (select c.id_bnco
                                , c.fcha_aprtra
                                , c.obsrvcion
                                , c.cdgo_rcdo_orgen
                                , c.id_usrio
                                , c.cdgo_clnte
                            from re_g_recaudos_caja c
                            where c.id_rcdo_cja = p_id_rcdo_cja)
            loop

                v_cdgo_clnte := c_rcdo_cja.cdgo_clnte;
                --v_id_usrio   := c_rcdo_cja.id_usrio;

                -- Buscar la cuenta del banco
                begin
                    select d.id_bnco_cnta into v_id_bnco_cnta
                      from df_s_cajas_banco d
                     where d.cdgo_clnte         = c_rcdo_cja.cdgo_clnte
                       and d.id_impsto          = p_id_impsto
                       --and d.id_impsto_sbmpsto  = p_id_impsto_sbmpsto
                       and d.id_usrio           = v_id_usrio;
                exception
                    when others then
                        v_id_bnco_cnta := null;
                end;

                -- Registrar en recaudo control
                pkg_re_recaudos.prc_rg_recaudo_control( p_cdgo_clnte        => c_rcdo_cja.cdgo_clnte
                                                      , p_id_impsto         => p_id_impsto
                                                      , p_id_impsto_sbmpsto => p_id_impsto_sbmpsto
                                                      , p_id_bnco           => c_rcdo_cja.id_bnco
                                                      , p_id_bnco_cnta      => v_id_bnco_cnta
                                                      , p_fcha_cntrol       => systimestamp
                                                      , p_obsrvcion         => c_rcdo_cja.obsrvcion
                                                      , p_cdgo_rcdo_orgen   => c_rcdo_cja.cdgo_rcdo_orgen
                                                      , p_id_usrio          => c_rcdo_cja.id_usrio
                                                      , o_id_rcdo_cntrol    => v_rcdo_cntrol
                                                      , o_cdgo_rspsta       => v_cdgo_rspsta
                                                      , o_mnsje_rspsta      => v_mnsje_rspsta);
            end loop;
    end;

    --Busca la Definici?n - Permitir Pago Duplicado en el mismo lote
    v_vlor_pdl := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte 			   => v_cdgo_clnte
                                                                 , p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria
                                                                 , p_cdgo_dfncion_clnte		   => 'PDC' );

     if v_rcdo_cntrol > 0 then

            --Verifica si el Recaudo Esta Duplicado
           select count(*)
             into v_dplcdos
             from re_g_recaudos_caja_detalle
            where id_rcdo_cja        = p_id_rcdo_cja
              and cdgo_rcdo_orgn_tpo = p_cdgo_rcdo_orgn_tpo
              and id_orgen           = p_id_orgen;

            --Verifica si se puede Incluir el Recaudo en el mismo Lote
           if( v_vlor_pdl in ( 'N' , '-1' ) and v_dplcdos > 0 ) then
               o_cdgo_rspsta    := 20;
               o_mnsje_rspsta   := 'El documento de pago, se encuentra encuentra duplicado en el lote.';
               return;
           end if;

           -- Consultamos un consecutivo para el recaudo
           v_cnsctvo_rcdo := fnc_gn_cnsctvo_usrio_cja(p_id_rcdo_cja => p_id_rcdo_cja
                                                    , p_id_usrio    => v_id_usrio);
            begin
              -- Incluimos el recaudo en la caja
              insert into re_g_recaudos_caja_detalle(id_rcdo_cja
                                                  , id_impsto
                                                  , id_impsto_sbmpsto
                                                  , id_sjto_impsto
                                                  , cdgo_rcdo_orgn_tpo
                                                  , id_orgen
                                                  , fcha_rcdo
                                                  , fcha_ingrso_bnco
                                                  , vlor_real_rcbdo
                                                  , vlor_rcdo
                                                  , vlor_cmbio
                                                  , obsrvcion
                                                  , cdgo_rcdo_estdo
                                                  , fcha_apliccion
                                                  , cnsctvo_rcdo
												  , id_rcdo)
              values(p_id_rcdo_cja
                    , p_id_impsto
                    , p_id_impsto_sbmpsto
                    , p_id_sjto_impsto
                    , p_cdgo_rcdo_orgn_tpo
                    , p_id_orgen
                    , sysdate
                    , sysdate
                    , p_vlor_real_rcbdo
                    , p_vlor
                    , p_vlor_cmbio
                    , null
                    , p_cdgo_rcdo_estdo
                    , null                    
                    , v_cnsctvo_rcdo
					, null) returning id_rcdo_cja_dtlle into v_id_rcdo_cja_dtlle;

              -- Por caja recaudo ingresado se actualiza la caja.
              update re_g_recaudos_caja
              set cntdad_rcdos = nvl(cntdad_rcdos, 0) + 1
                , vlor_rcdos = nvl(vlor_rcdos, 0) + p_vlor
              where id_rcdo_cja = p_id_rcdo_cja;

          exception
              when others then
                  rollback;
                  o_cdgo_rspsta := 25;
                  o_mnsje_rspsta := 'Ha ocurrido un error al intentar ingresar el recaudo en la caja.';
                  return;
          end;

            -- Insertar los recaudos de la caja de un impuesto y subimpuesto en las tablas de recaudo del sistema
            pkg_re_recaudos.prc_rg_recaudo( p_cdgo_clnte         => p_cdgo_clnte
                                          , p_id_rcdo_cntrol     => v_rcdo_cntrol
                                          , p_id_sjto_impsto     => p_id_sjto_impsto
                                          , p_cdgo_rcdo_orgn_tpo => p_cdgo_rcdo_orgn_tpo
                                          , p_id_orgen           => p_id_orgen
                                          , p_vlor               => p_vlor
                                          , p_obsrvcion          => 'Recaudo por caja de banco'
                                          , p_fcha_ingrso_bnco   => sysdate
                                          , p_cdgo_frma_pgo      => 'MT'
                                          , p_cdgo_rcdo_estdo    => 'RG'
                                          , o_id_rcdo            => v_id_rcdo
                                          , o_cdgo_rspsta        => v_cdgo_rspsta
                                          , o_mnsje_rspsta       => v_mnsje_rspsta );


            -- 02-06-2021 09:11 a.m. JAGUAS
            if v_cdgo_rspsta <> 0 then
              rollback;
              o_cdgo_rspsta := v_cdgo_rspsta;
              o_mnsje_rspsta := v_mnsje_rspsta;
              return;
            end if;

            -- Registrar el recaudos de acuerdo a los medios de recaudo utilizados (EF,CH,TR)
            for c_frmas_pgo in (select a.cdgo_frma_pgo,
                                       a.vlor_pgdo,
                                       a.rcdo_orgen
                                from json_table(p_cdgo_frma_pgo_cja  ,'$[*]'
                                                columns ( cdgo_frma_pgo    		number path '$.cdgo_frma_pgo',
                                                          vlor_pgdo      		number path '$.vlor_pgdo',
                                                          rcdo_orgen      		number path '$.rcdo_orgen'
                                                        )
                                                ) a
                                )
            loop


                if c_frmas_pgo.cdgo_frma_pgo = 1 then
                    v_cdgo_frma_pgo := 'EF';
                elsif c_frmas_pgo.cdgo_frma_pgo = 2 then
                    v_cdgo_frma_pgo := 'CH';
                elsif c_frmas_pgo.cdgo_frma_pgo = 3 then
                    v_cdgo_frma_pgo := 'TR';
                end if;

                insert into re_g_recaudos_forma_pago(id_rcdo
                                                   , cdgo_frma_pgo
                                                   , vlor_pgdo
                                                   , rcdo_orgn)
                                            values(v_id_rcdo
                                                 , v_cdgo_frma_pgo
                                                 , c_frmas_pgo.vlor_pgdo
                                                 , c_frmas_pgo.rcdo_orgen)
                returning id_rcdo_frma_pgo into v_id_rcdo_frma_pgo;

            end loop;

            if v_cdgo_rspsta <> 0 then
                rollback;
                o_cdgo_rspsta := v_cdgo_rspsta;
                o_mnsje_rspsta := v_mnsje_rspsta;
                return;
            end if;

            if p_cdgo_rcdo_orgn_tpo = 'DL' then

                -- En caso de ser una declaraci?n , se realiza actualizaci?n del estado
                -- Se coloca la declaraci?n como presentada
                pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte			    => p_cdgo_clnte
                                                             , p_id_dclrcion			=> p_id_orgen
                                                             , p_cdgo_dclrcion_estdo	=> 'PRS'
                                                             , p_fcha					=> sysdate
                                                             , p_id_rcdo                => v_id_rcdo
                                                             , p_id_usrio_aplccion	    => v_id_usrio
                                                             , o_cdgo_rspsta			=> v_cdgo_rspsta
                                                             , o_mnsje_rspsta			=> v_mnsje_rspsta);

                if v_cdgo_rspsta <> 0 then
                    rollback;
                    o_cdgo_rspsta := v_cdgo_rspsta;
                    o_mnsje_rspsta := v_mnsje_rspsta;
                    return;
                end if;
            end if;

            -- Aplicar el recaudo.
            pkg_re_recaudos.prc_ap_recaudo(
                            p_id_usrio          =>  v_id_usrio
                          , p_cdgo_clnte        =>  p_cdgo_clnte
                          , p_id_rcdo           =>  v_id_rcdo
                          , o_cdgo_rspsta       =>  v_cdgo_rspsta
                          , o_mnsje_rspsta      =>  v_mnsje_rspsta);


            if v_cdgo_rspsta <> 0 then
                rollback;
                o_cdgo_rspsta := v_cdgo_rspsta;
                o_mnsje_rspsta := v_mnsje_rspsta;
                return;
            end if;

            --commit;

            -- Distribuir el recaudo por forma pago y conceptos
            prc_rg_distribucion_recaudo(p_id_rcdo         => v_id_rcdo
                                      , o_cdgo_rspsta     => v_cdgo_rspsta
                                      , o_mnsje_rspsta    => v_mnsje_rspsta);

            if v_cdgo_rspsta <> 0 then
                rollback;
                o_cdgo_rspsta := v_cdgo_rspsta;
                o_mnsje_rspsta := v_mnsje_rspsta;
                return;
            end if;

            -- Poblar tablas RPT para traer la informaci?n del bono de recaudo
            prc_gn_bono_recaudo_caja( p_cdgo_clnte      => p_cdgo_clnte
                                    , p_cdgo_rcdo_orgen => p_cdgo_rcdo_orgn_tpo
                                    , p_id_orgen        => p_id_orgen
                                    , p_id_rcdo         =>  v_id_rcdo
                                    , p_vlor_ttal       => p_vlor
                                    , p_prcso_gnra      => 'CAJA'
                                    , o_cdgo_rspsta     => v_cdgo_rspsta
                                    , o_mnsje_rspsta    => v_mnsje_rspsta);

            if v_cdgo_rspsta <> 0 then
                rollback;
                o_cdgo_rspsta  := v_cdgo_rspsta;
                o_mnsje_rspsta := v_mnsje_rspsta;
                return;
            end if;

            if p_cdgo_rcdo_orgn_tpo = 'DL' then
                -- Consultamos los datos de la declaracion
                begin
                    select b.id_lqdcion
                      into o_nmro_lqdcion
                      from re_g_recaudos           a
                      join gi_g_declaraciones      b on a.id_orgen       = b.id_dclrcion
                      join si_i_personas           c on b.id_sjto_impsto = c.id_sjto_impsto
                     where a.id_orgen = p_id_orgen;

                exception
                    when others then
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := 'Error al consultar los datos de la declaraci?n. '||sqlerrm;
                        return;
                end;

            elsif p_cdgo_rcdo_orgn_tpo = 'DC' then
                -- Consultamos los datos de la renta o declaracion
                begin
                    select nvl(b.id_lqdcion, c.nmro_rnta)
                      into o_nmro_lqdcion
                      from re_g_recaudos           a
                      left join (
                                    select distinct (c.id_lqdcion) id_lqdcion
                                         , c.bse_grvble
                                         , a.id_dcmnto
                                         , c.nmro_cnsctvo
                                      from re_g_documentos           a
                                      join v_re_g_documentos_detalle b  on a.id_dcmnto         = b.id_dcmnto
                                      join gi_g_declaraciones        c  on a.id_impsto         = c.id_impsto
                                                                       and a.id_impsto_sbmpsto = c.id_impsto_sbmpsto
                                                                       and a.id_sjto_impsto    = c.id_sjto_impsto
                                                                       and b.vgncia            = c.vgncia
                                                                       and b.id_prdo           = c.id_prdo
                                                                       and cdgo_dclrcion_estdo in ('APL','PRS')
                                    where a.id_dcmnto = p_id_orgen
                                 ) b on a.id_orgen  = b.id_dcmnto
                      left join gi_g_rentas        c on a.id_orgen       = c.id_dcmnto
                      join si_i_personas           d on a.id_sjto_impsto = d.id_sjto_impsto
                     where a.id_orgen = p_id_orgen ;
                exception
                    when others then
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := 'Error al consultar los datos del Documento. '||sqlerrm;
                        return;
                end;
            end if;

    end if;

    commit;

  exception
    when ex_orgen_rcddo then
         o_cdgo_rspsta := 80;
        o_mnsje_rspsta := 'El documento ya se encuentra recaudado. ';
    when others then
        o_cdgo_rspsta := 99;
        o_mnsje_rspsta := 'No se pudo registrar el recaudo. '||sqlerrm;
  end prc_rg_recaudos_caja;

  procedure prc_vl_cdgo_brra( p_cdgo_brra          in  varchar2
                              , p_cdgo_clnte         in  df_s_clientes.cdgo_clnte%type
                              , p_id_impsto          in  df_c_impuestos.id_impsto%type
                              , p_id_impsto_sbmpsto  in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                              , p_id_rcdo_cja        in  re_g_recaudos_caja.id_rcdo_cja%type
                                                         default null
                              , o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type
                              , o_cdgo_ean           out varchar2
                              , o_nmro_dcmnto        out number
                              , o_vlor               out number
                              , o_fcha_vncmnto       out date
                              , o_indcdor_pgo_dplcdo out varchar2
                              , o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type
                              , o_id_orgen           out re_g_recaudos.id_orgen%type
                              , o_cdgo_rspsta        out number
                              , o_mnsje_rspsta       out varchar2 )
    as
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
        o_cdgo_rspsta  := 0;

        --Indicador de Pago no Duplicado
        o_indcdor_pgo_dplcdo := 'N';

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        --Se Verifica si el Codigo de Barra este Nulo
        if( p_cdgo_brra is null ) then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'El codigo de barra es requerido.';
            return;
        end if;

        --Extrae los Datos del Codigo de Barra
        declare
            null_exception exception;
        begin
            o_cdgo_ean     := substr( p_cdgo_brra , 4 , 13 );
            o_nmro_dcmnto  := to_number( substr( p_cdgo_brra , 20 , 13 ));
            o_vlor         := to_number( substr( p_cdgo_brra , 36 , 15 ));
            o_fcha_vncmnto := to_date( substr( p_cdgo_brra , 53 , 8 ) , 'YYYYMMDD' );

            --Verifica si los Campos no son Nulos
            if( o_cdgo_ean is null or o_nmro_dcmnto  is null
             or o_vlor     is null or o_fcha_vncmnto is null ) then
                raise null_exception;
            end if;
        exception
             when others then
                  o_cdgo_rspsta  := 2;
                  o_mnsje_rspsta := 'El codigo de barra no es valido.';
                  return;
        end;

        --Busca la Definicion - Permitir Pago Duplicado en lote Diferente
        v_vlor_pdo := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte 			   => p_cdgo_clnte
                                                                     , p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria
                                                                     , p_cdgo_dfncion_clnte		   => 'PDO' );

        --Busca la Definicion - Permitir Pago Duplicado en el mismo lote
        v_vlor_pdl := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte 			   => p_cdgo_clnte
                                                                     , p_cdgo_dfncion_clnte_ctgria => pkg_re_recaudos.c_cdgo_dfncion_clnte_ctgria
                                                                     , p_cdgo_dfncion_clnte		   => 'PDL' );

        --Valida el Documento de Recaudo
        pkg_re_recaudos.prc_vl_documento_01( p_cdgo_ean           => o_cdgo_ean
                                           , p_nmro_dcmnto        => o_nmro_dcmnto
                                           , p_vlor               => o_vlor
                                           , p_fcha_vncmnto       => o_fcha_vncmnto
                                           , p_indcdor_vlda_pgo   => ( v_vlor_pdo in ( 'N' , '-1'))
                                           , o_cdgo_rcdo_orgn_tpo => o_cdgo_rcdo_orgn_tpo
                                           , o_id_orgen           => o_id_orgen
                                           , o_cdgo_clnte         => v_cdgo_clnte
                                           , o_id_impsto          => v_id_impsto
                                           , o_id_impsto_sbmpsto  => v_id_impsto_sbmpsto
                                           , o_id_sjto_impsto     => o_id_sjto_impsto
                                           , o_cdgo_rspsta        => o_cdgo_rspsta
                                           , o_mnsje_rspsta       => o_mnsje_rspsta );

        --Verifica si el Documento de Pago es Valido
        if( o_cdgo_rspsta <> 0 ) then
            o_cdgo_rspsta  := 3;
            return;
        end if;

        --Valida los Parametro del Recaudo
        pkg_re_recaudos.prc_vl_documento_02( p_cdgo_clnte        => p_cdgo_clnte
                                           , p_id_impsto         => p_id_impsto
                                           , p_id_impsto_sbmpsto => p_id_impsto_sbmpsto
                                           , p_nmro_dcmnto       => o_nmro_dcmnto
                                           , c_cdgo_clnte        => v_cdgo_clnte
                                           , c_id_impsto         => v_id_impsto
                                           , c_id_impsto_sbmpsto => v_id_impsto_sbmpsto
                                           , o_cdgo_rspsta       => o_cdgo_rspsta
                                           , o_mnsje_rspsta      => o_mnsje_rspsta );

        --Verifica si los Parametro del Recaudos son Valido
        if( o_cdgo_rspsta <> 0 ) then
            o_cdgo_rspsta  := 4;
            return;
        end if;

        --Verifica si se puede Incluir el Recaudo en el mismo Lote
        if( v_vlor_pdl in ( 'N' , '-1' )) then

            --Cantidad de Recaudos
            select count(*)
              into v_rcdos
              from re_g_recaudos_caja_detalle
             where id_rcdo_cja        = p_id_rcdo_cja
               and cdgo_rcdo_orgn_tpo = o_cdgo_rcdo_orgn_tpo
               and id_orgen           = o_id_orgen;

            --Verifica si Existen Recaudos
            if( v_rcdos > 0 ) then
                --Indicador de Pago Duplicado
                o_indcdor_pgo_dplcdo := 'S';
                o_cdgo_rspsta        := 5;
                o_mnsje_rspsta       := 'El documento de pago #' || o_nmro_dcmnto ||', ya se encuentra registrado en el lote.';
                return;
            end if;
        end if;

        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        o_mnsje_rspsta := 'El codigo de barra es valido para recaudar.';

    exception
         when others then
              o_cdgo_rspsta  := 99;
              o_mnsje_rspsta := 'No fue posible validar el codigo de barra del documento.' || sqlerrm;
    end prc_vl_cdgo_brra;

    procedure prc_ap_recaudos_caja_detalle
    as

        v_cdgo_rspsta number;
        v_mnsje_rspsta varchar2(4000);

    begin

        --Recorremos recaudos
        for c_rcdos_cja in (select d.id_usrio, d.cdgo_clnte, a.id_rcdo, b.id_impsto, b.id_impsto_sbmpsto
                              from re_g_recaudos              a
                              join re_g_recaudos_control      b on b.id_rcdo_cntrol = a.id_rcdo_cntrol -- Controles que sean de cajas
                                                                and b.cdgo_rcdo_orgen = 'CA'
                              join re_g_recaudos_caja_detalle c on c.id_orgen = a.id_orgen
                              join re_g_recaudos_caja         d on d.id_rcdo_cja = c.id_rcdo_cja
                             where a.cdgo_rcdo_estdo = 'RG'
                            )
        loop


            -- Aplicaci?n de de pagos puntual
            pkg_re_recaudos.prc_ap_recaudo( p_id_usrio          => c_rcdos_cja.id_usrio
                                          , p_cdgo_clnte        => c_rcdos_cja.cdgo_clnte
                                          , p_id_rcdo           => c_rcdos_cja.id_rcdo
                                          , o_cdgo_rspsta       => v_cdgo_rspsta
                                          , o_mnsje_rspsta      => v_mnsje_rspsta);

        end loop;



    end prc_ap_recaudos_caja_detalle;

    procedure prc_el_reversion_pago_caja(p_cdgo_clnte       in number,
                                         p_id_usrio         in number,
                                         p_id_cja           in number,
                                         p_id_rcdo          in number,
                                         p_cnsctvo_rcdo     in number,
                                         p_id_rcdo_cja_dtlle in number,
                                         p_id_orgen          in number,
                                         p_obsrvcion         in varchar2,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2)
    as

        v_cdgo_rcdo_estdo       varchar2(3);
        v_nmro_dcmnto           number;
        v_vlor_rcdo             number;
        v_cdgo_rcdo_orgen_tpo   re_g_recaudos.cdgo_rcdo_orgn_tpo%type;
        v_id_impsto             v_re_g_recaudos.id_impsto%type;
        v_id_impsto_sbmpsto     v_re_g_recaudos.id_impsto_sbmpsto%type;
        v_nmro_lqdcion          number;
        v_id_acto               number;
        v_id_clse_acto          number;
        v_id_rnta               number;
        v_id_impsto_acto        number;
        v_vlor_efctvo           number;
        v_vlor_chque            number;
        v_fcha_rcdo             timestamp;
        v_id_usrio_aplco        number;
    begin

        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'OK';

        --insert into muerto(v_001, v_002) values('reversion_caja', 'entra al prc');
        --commit;
        --insert into muerto(v_001, v_002) values ('reversion_caja2', p_id_rcdo||'-'||p_id_rcdo_cja_dtlle||'-'||p_id_orgen);
        --commit;

        -- Buscamos el estado del recaudo para validar si est? aplicado
        begin
            select a.cdgo_rcdo_estdo
                 , a.nmro_dcmnto
                 , a.vlor
                 , a.cdgo_rcdo_orgn_tpo
                 , a.id_impsto
                 , a.id_impsto_sbmpsto
                 , a.fcha_rcdo
                 , id_usrio_aplco
              into v_cdgo_rcdo_estdo
                 , v_nmro_dcmnto
                 , v_vlor_rcdo
                 , v_cdgo_rcdo_orgen_tpo
                 , v_id_impsto
                 , v_id_impsto_sbmpsto
                 , v_fcha_rcdo
                 , v_id_usrio_aplco
              from v_re_g_recaudos a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_rcdo    = p_id_rcdo
               and a.id_orgen   = p_id_orgen;
        exception
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'No se encontr? reaudo.';
                return;
        end;

            begin
                select r.id_rnta
                  into v_id_rnta
                  from gi_g_rentas r
                 where r.id_dcmnto = p_id_orgen;
            exception
                when no_data_found then
                    v_id_rnta := 0;
            end;

            begin
                select distinct a.id_impsto_acto into v_id_impsto_acto
                  from df_i_impuestos_acto a
                  join df_i_impuestos_acto_concepto p on p.id_impsto_acto        = a.id_impsto_acto
                  join gf_g_movimientos_detalle d     on d.id_impsto_acto_cncpto = p.id_impsto_acto_cncpto
                  join re_g_recaudos r                on r.id_rcdo               = d.id_orgen
                 where d.cdgo_mvmnto_orgn = 'RE'
                   and r.id_orgen         = p_id_orgen;
            exception
                when no_data_found then
                    v_id_impsto_acto := 0;
            end;

            begin
                select sum(f.vlor_pgdo)
                into v_vlor_efctvo
                from re_g_recaudos_forma_pago f
                where f.id_rcdo = p_id_rcdo
                  and f.cdgo_frma_pgo = 'EF';
            exception
                when no_data_found then
                    v_vlor_efctvo := 0;
            end;

            begin
                select sum(f.vlor_pgdo)
                into v_vlor_chque
                from re_g_recaudos_forma_pago f
                where f.id_rcdo = p_id_rcdo
                  and f.cdgo_frma_pgo = 'CH';
            exception
                when no_data_found then
                    v_vlor_chque := 0;
            end;

            /* Registro en el hist?rico de reversiones */
            insert into re_g_recaudos_hstrco_rvrsn(fcha_rvrsion
                                                 , id_lqdcion
                                                 , cdgo_rcdo_orgen_tpo
                                                 , cnsctvo_rcdo
                                                 , id_rcdo
                                                 , id_orgen
                                                 , id_impsto
                                                 , id_impsto_sbmpsto
                                                 , id_impsto_acto
                                                 , vlor_efctvo
                                                 , vlor_chque
                                                 , vlor_rcdo
                                                 , obsrvcion
                                                 , id_usrio
                                                 , id_usrio_aplco)
            values(systimestamp
                 , v_id_rnta
                 , v_cdgo_rcdo_orgen_tpo
                 , p_cnsctvo_rcdo
                 , p_id_rcdo
                 , p_id_orgen
                 , v_id_impsto
                 , v_id_impsto_sbmpsto
                 , v_id_impsto_acto
                 , nvl(v_vlor_efctvo,0)
                 , nvl(v_vlor_chque,0)
                 , v_vlor_rcdo
                 , p_obsrvcion
                 , p_id_usrio
                 , v_id_usrio_aplco);

            -- 1. Elimnar las formas de pago que est?n asociadas al recaudo
            begin
                delete from re_g_recdos_frma_pgo_dtlle where id_rcdo = p_id_rcdo;
            exception
                when others then
                    o_cdgo_rspsta := 14;
                    o_mnsje_rspsta := 'Error al intentar eliminar la distribuci?n de conceptos.';
            end;

            begin
                delete from re_g_recaudos_forma_pago where id_rcdo = p_id_rcdo;
            exception
                when others then
                    o_cdgo_rspsta := 15;
                    o_mnsje_rspsta := 'Error al intentar eliminar las formas de pago del recaudo';
            end;

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;

            -- 2. Hacemos la reversi?n del pago
            pkg_re_recaudos.prc_rg_reversar_recaudo(
                                      p_cdgo_clnte	    =>  p_cdgo_clnte,
                                      p_id_usrio        =>  p_id_usrio,
                                      p_nmro_dcmnto     =>  v_nmro_dcmnto,
                                      p_id_rcdo         =>  p_id_rcdo,
                                      p_dscrpcion       =>  p_obsrvcion,
                                      o_cdgo_rspsta     =>  o_cdgo_rspsta,
                                      o_mnsje_rspsta    =>  o_mnsje_rspsta
                                      );

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;

            begin
                delete from re_g_recaudos where id_rcdo = p_id_rcdo;
            exception
                when others then
                    o_cdgo_rspsta := 20;
                    o_mnsje_rspsta := 'Error al intentar eliminar el recaudo';
            end;

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;

            -- 3. Se elimina el recaudo ingresado en la caja
            begin
                delete from re_g_recaudos_caja_detalle where id_rcdo_cja_dtlle = p_id_rcdo_cja_dtlle;
            exception
                when others then
                    o_cdgo_rspsta := 25;
                    o_mnsje_rspsta := 'Error al intentar eliminar el recaudo en la caja';
            end;

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;

            begin
                delete from re_g_bonos_caja_detalle_rpt d
                where exists(select 1
                               from re_g_bonos_caja_rpt b
                              where b.id_bno_cja_rpt = d.id_bno_cja_rpt
                                and b.id_orgn = p_id_orgen);

                delete from re_g_bonos_caja_rpt b
                 where b.id_orgn = p_id_orgen;
            exception
                when others then
                    o_cdgo_rspsta := 30;
                    o_mnsje_rspsta := 'Error al intentar eliminar datos del reporte generado';
            end;

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;

            -- 4. Actualizar cantidad de pagos y monto asociado a la caja
            begin
                update re_g_recaudos_caja
                set cntdad_rcdos  = cntdad_rcdos - 1,
                    vlor_rcdos    = vlor_rcdos   - v_vlor_rcdo
                where id_rcdo_cja = p_id_cja;
            exception
                when others then
                    o_cdgo_rspsta := 35;
                    o_mnsje_rspsta := 'Error al intentar actualizar datos de la caja';
            end;

            if o_cdgo_rspsta <> 0 then
                rollback;
                return;
            end if;


        commit;

    end prc_el_reversion_pago_caja;

    procedure prc_ac_cierre_masivo

    as

    begin

        for c_cjas in (select id_rcdo_cja from re_g_recaudos_caja where estdo_aprtra = 'A') loop

            begin
                update re_g_recaudos_caja
                   set estdo_aprtra = 'C',
                       fcha_crre = systimestamp
                 where id_rcdo_cja = c_cjas.id_rcdo_cja;
            exception
                when others then
                    dbms_output.put_line('Error al intentar cerrar caja: '||c_cjas.id_rcdo_cja);
            end;

        end loop;

        commit;

    end prc_ac_cierre_masivo;

    procedure prc_gn_bono_recaudo_caja(p_cdgo_clnte         in number
                                     , p_cdgo_rcdo_orgen    in  varchar2
                                     , p_id_orgen           in  number
                                     , p_id_rcdo            in  number
                                     , p_vlor_ttal          in  number
                                     , p_prcso_gnra         in varchar2 default null
                                     , o_cdgo_rspsta        out number
                                     , o_mnsje_rspsta       out varchar2)
    as
        v_dscrpcion_acto        re_g_bonos_caja_rpt.dscrpcion_acto%type;
        v_dscrpcion_clse_acto   re_g_bonos_caja_rpt.dscrpcion_clse_acto%type;
        v_id_bno_cja_rpt        re_g_bonos_caja_rpt.id_bno_cja_rpt%type;

        v_nmro_lqdcion          re_g_bonos_caja_rpt.nmro_lqdcion%type;
        v_bse_grvble            re_g_bonos_caja_rpt.bse_grvble%type;
        v_rfrncia_pgo           re_g_bonos_caja_rpt.rfrncia_pgo%type;
        v_nmbre_rzn_scial       re_g_bonos_caja_rpt.nmbre_rzn_scial%type;
        v_idntfccion_sjto       re_g_bonos_caja_rpt.idntfccion_sjto%type;
        v_entdad_cntrtnte       re_g_bonos_caja_rpt.entdad_cntrtnte%type;
        v_nmro_cntrto           re_g_bonos_caja_rpt.nmro_cntrto%type;
     		v_id_rcdo				re_g_recaudos.id_rcdo%type;

        v_id_dcmnto             re_g_documentos.id_dcmnto%type;
        v_existe                number;

      /*   v_rfrncia_pgo               varchar2(400);
          v_nmro_lqdcion varchar2(400);
           v_bse_grvble varchar2(400);
           v_idntfccion_sjto varchar2(400);
           v_nmbre_rzn_scial varchar2(400);
           v_entdad_cntrtnte varchar2(400);
           v_nmro_cntrto varchar2(400);
           v_id_rcdo          varchar2(400);*/


    begin

        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'OK';

        -- validamos que no este generado el bono para el origen
        begin
            select 1
              into v_existe
              from re_g_bonos_caja_rpt
             where id_orgn = p_id_orgen;      


            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Ya existe bono generado para el origen: '||p_id_orgen;
             return;
        exception
            when no_data_found then
                null;
        end;

		-- Si el origen es una declaracion, consultamos los datos de la declaracion
		if p_cdgo_rcdo_orgen = 'DL' then

			-- Consultamos los datos de la declaracion
			begin
				select a.nmro_dcmnto
					 , b.id_lqdcion
					 , b.bse_grvble
					 , (select z.idntfccion_sjto from v_si_i_sujetos_impuesto z where z.id_sjto_impsto = a.id_sjto_impsto)
					 , c.nmbre_rzon_scial
					 , 'No Aplica'
					 , 'No Aplica'
					 , a.id_rcdo
				  into v_rfrncia_pgo
					 , v_nmro_lqdcion
					 , v_bse_grvble
					 , v_idntfccion_sjto
					 , v_nmbre_rzn_scial
					 , v_entdad_cntrtnte
					 , v_nmro_cntrto
					 , v_id_rcdo
				  from re_g_recaudos           a
				  join gi_g_declaraciones      b on a.id_orgen       = b.id_dclrcion
				  join si_i_personas           c on b.id_sjto_impsto = c.id_sjto_impsto
				 where a.id_orgen = p_id_orgen;

			exception
				when others then
					o_cdgo_rspsta  := 10;
					o_mnsje_rspsta := 'Error al consultar los datos de la declaraci?n. '||sqlerrm;
					return;
			end;
			-- Fin consultamos los datos de la declaracion

		-- Si el Origen es un Documento
		elsif p_cdgo_rcdo_orgen = 'DC' then
/*
            -- Consultamos el ultimo Id del documento ya que si es una renta con 3 fechas de vencimiento
            -- necesitamos el primer documento generado que es el que se encuentra asociado a la renta
            begin
                select min(id_dcmnto)
                  into v_id_dcmnto
                  from re_g_documentos
                 where nmro_dcmnto = (
                                         select nmro_dcmnto
                                           from re_g_documentos
                                          where id_dcmnto = p_id_orgen
                                       );
            end;
*/
			-- Consultamos los datos de la renta o declaracion
			begin
                select a.nmro_dcmnto
                     , nvl(b.id_lqdcion, c.nmro_rnta)  as nmro_lqdcion
                     , nvl(b.bse_grvble, c.vlor_bse_grvble) as bse_grvble
                     , (select z.idntfccion_sjto from v_si_i_sujetos_impuesto z where z.id_sjto_impsto = a.id_sjto_impsto) as idntfccion_sjto
                     , d.nmbre_rzon_scial
                     , nvl((select nmbre_rzon_scial from df_s_entidades x where x.id_entdad = c.id_entdad), 'No Aplica') as entdad_cntrtnte
                     , nvl(c.txto_ascda, 'No Aplica') as nmro_cntrto
                     , a.id_rcdo
				  into v_rfrncia_pgo
					 , v_nmro_lqdcion
					 , v_bse_grvble
					 , v_idntfccion_sjto
					 , v_nmbre_rzn_scial
					 , v_entdad_cntrtnte
					 , v_nmro_cntrto
					 , v_id_rcdo
                  from re_g_recaudos           a
                  left join (
                                select distinct (c.id_lqdcion) id_lqdcion
                                     , c.bse_grvble
                                     , a.id_dcmnto
                                     , c.nmro_cnsctvo
                                  from re_g_documentos           a
                                  join v_re_g_documentos_detalle b  on a.id_dcmnto         = b.id_dcmnto
                                  join gi_g_declaraciones        c  on a.id_impsto         = c.id_impsto
                                                                   and a.id_impsto_sbmpsto = c.id_impsto_sbmpsto
                                                                   and a.id_sjto_impsto    = c.id_sjto_impsto
                                                                   and b.vgncia            = c.vgncia
                                                                   and b.id_prdo           = c.id_prdo
                                                                   and cdgo_dclrcion_estdo in ('APL','PRS')
                                where a.id_dcmnto = p_id_orgen
                             ) b on a.id_orgen  = b.id_dcmnto
                  left join gi_g_rentas        c on p_id_orgen       = c.id_dcmnto
                  join si_i_personas           d on a.id_sjto_impsto = d.id_sjto_impsto
                 where a.id_orgen = p_id_orgen
                    and a.cdgo_rcdo_estdo = 'AP'
                    and rownum            = 1;
			exception
				when others then
					o_cdgo_rspsta  := 20;
					o_mnsje_rspsta := 'Error al consultar los datos del Documento prc_gn_bono_recaudo_caja. '||sqlerrm;
					return;
			end;
			-- Fin Consultamos los datos de la renta o declaracion
		end if;

		-- Consultamos los datos del acto y clase acto
		begin
			 select distinct b.nmbre_impsto_acto
				  , b.nmbre_impsto_sbmpsto
			   into v_dscrpcion_clse_acto
				  , v_dscrpcion_acto
			   from gf_g_movimientos_detalle       a
			   join v_df_i_impuestos_acto_concepto b on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
			  where a.id_orgen = v_id_rcdo
                and a.cdgo_mvmnto_orgn = 'RE';
		exception
			when others then
				o_cdgo_rspsta  := 30;
				o_mnsje_rspsta := 'Error al consultar los datos del Impuesto acto. '||sqlerrm;
				return;
		end;
		-- Fin Consultamos los datos del acto y clase acto

		-- Insertamos el Encabezado del Bono
        begin
            insert into re_g_bonos_caja_rpt(id_orgn
                                          , cdgo_rcdo_orgn_tpo
                                          , cdgo_clnte
                                          , dscrpcion_acto
                                          , dscrpcion_clse_acto
                                          , nmro_lqdcion
                                          , fcha_pgo
                                          , bse_grvble
                                          , rfrncia_pgo
                                          , nmbre_rzn_scial
                                          , idntfccion_sjto
                                          , entdad_cntrtnte
                                          , nmro_cntrto
                                          , vlor_ttal
                                          , prcso_gnra)
            values(p_id_orgen
                 , p_cdgo_rcdo_orgen
                 , p_cdgo_clnte
                 , v_dscrpcion_acto
                 , v_dscrpcion_clse_acto
                 , v_nmro_lqdcion
                 , systimestamp
                 , v_bse_grvble
                 , v_rfrncia_pgo
                 , v_nmbre_rzn_scial
                 , v_idntfccion_sjto
                 , v_entdad_cntrtnte
                 , v_nmro_cntrto
                 , p_vlor_ttal
                 , p_prcso_gnra)
            returning id_bno_cja_rpt into v_id_bno_cja_rpt;

        exception
            when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'Error al intentar registrar informaci?n general del bono. '||sqlerrm;
				rollback;
				return;
        end;
        -- Fin Insertamos el Encabezado del Bono

		-- Issertamos el detalle del Bono
		begin
			for c_rcdo_dtlle in (
									-- Detalle del pago
									select b.cdgo_cncpto
										 , trim(b.dscrpcion_cncpto) as dscrpcion_cncpto
										 , sum(b.vlor_cptal )       as vlor_cncpto
									  from re_g_recaudos           a
									  join (    select a.id_orgen as id_rcdo
													 , b.cdgo_cncpto
													 , b.dscrpcion as dscrpcion_cncpto
													 , sum( case when a.cdgo_mvmnto_tpo = 'PC' then
																   a.vlor_hber
																 else
																   0
																 end ) as vlor_cptal
													 , sum( case when a.cdgo_mvmnto_tpo = 'PI' then
																   a.vlor_hber
																 else
																   0
																 end ) as vlor_intres
												  from gf_g_movimientos_detalle a
												  join df_i_conceptos b
													on a.id_cncpto        = b.id_cncpto
												  join df_i_periodos c
													on a.id_prdo          = c.id_prdo
												 where a.cdgo_mvmnto_orgn = 'RE'
												   and a.cdgo_mvmnto_tpo in ( 'PC' , 'PI' )
											  group by a.id_orgen
													 , b.cdgo_cncpto
													 , b.dscrpcion ) b on a.id_rcdo = b.id_rcdo
									where a.id_orgen = p_id_orgen
									 group by b.cdgo_cncpto
										 , trim(b.dscrpcion_cncpto)
									union
									select 'INT'      as cdgo_cncpto
										 , 'INTERESES DE MORA' as dscrpcion_cncpto
										 , sum(b.vlor_intres) as vlor_cncpto
									  from re_g_recaudos           a
									  join (    select a.id_orgen as id_rcdo
													 , b.cdgo_cncpto
													 , b.dscrpcion as dscrpcion_cncpto
													 , sum( case when a.cdgo_mvmnto_tpo = 'PC' then
																   a.vlor_hber
																 else
																   0
																 end ) as vlor_cptal
													 , sum( case when a.cdgo_mvmnto_tpo = 'PI' then
																   a.vlor_hber
																 else
																   0
																 end ) as vlor_intres
												  from gf_g_movimientos_detalle a
												  join df_i_conceptos b
													on a.id_cncpto        = b.id_cncpto
												  join df_i_periodos c
													on a.id_prdo          = c.id_prdo
												 where a.cdgo_mvmnto_orgn = 'RE'
												   and a.cdgo_mvmnto_tpo in ( 'PC' , 'PI' )
											  group by a.id_orgen
													 , b.cdgo_cncpto
													 , b.dscrpcion ) b on a.id_rcdo = b.id_rcdo
									where a.id_orgen =  p_id_orgen
									 group by 'INT'
										 , 'INTERESES DE MORA'
			)loop
				-- Insertamos el detalle del Bono
				insert into re_g_bonos_caja_detalle_rpt(
					id_bno_cja_rpt
				  , cdgo_cncpto
				  , dscrpcion_cncpto
				  , vlor
				)values(
					v_id_bno_cja_rpt
				  , c_rcdo_dtlle.cdgo_cncpto
				  , c_rcdo_dtlle.dscrpcion_cncpto
				  , c_rcdo_dtlle.vlor_cncpto
				  );

			end loop;
		exception
			when others then
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := 'Error al intentar registrar el detalle del bono. '||sqlerrm;
				rollback;
				return;
		end;
		-- Fin Insertamos el detalle del Bono
    end prc_gn_bono_recaudo_caja;

    procedure prc_rg_distribucion_recaudo(p_id_rcdo         in  number
                                        , o_cdgo_rspsta     out number
                                        , o_mnsje_rspsta    out varchar2)
    as

        v_sql               varchar2(1000);
        v_vlor_dstrbcion    number := 0;
        v_vlor_hber         number;
        v_nmbre_clccion     constant varchar2(100) := 'RECAUDOS_DISTRIBUCION';
        v_id_cncpto         number;
        v_cdgo_cncpto       varchar2(5);
        v_vlor_dbe          number;
        v_sldo_pdnte        number;
        v_id_bnco           number;
        v_id_bnco_cnta      number;
        v_sldo_pndte        number;
        v_cdgo_frma_pgo      varchar2(3) := null;
        v_ttal_rcdo         number;
        v_ttal_frma_pgo     number;

        e_no_id_rcdo        exception;

    begin
        --insert into muerto2(v_001, t_001) values('Entrando...'||p_id_rcdo, systimestamp);

        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';

        -- Si el recaudo no existe
        if p_id_rcdo is null then
            raise e_no_id_rcdo;
        end if;

        begin
           select vlor into v_ttal_rcdo
           from re_g_recaudos
           where id_rcdo = p_id_rcdo;
        exception
          when others then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := 'Error a consultar valor del recaudo';
            return;
        end;

        --insert into muerto2(v_001, t_001) values('Desopues de validar valor recaudo '||v_ttal_rcdo, systimestamp);

        begin
           select sum(vlor_pgdo) into v_ttal_frma_pgo
           from re_g_recaudos_forma_pago
           where id_rcdo = p_id_rcdo;
        exception
          when others then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error a consultar valor total por forma de pago';
            return;
        end;

        --insert into muerto2(v_001, t_001) values('Desopues de validar valor formas pago '||v_ttal_frma_pgo, systimestamp);

        if v_ttal_rcdo <> v_ttal_frma_pgo then
          o_cdgo_rspsta := 20;
          o_mnsje_rspsta := 'El valor del recaudo no coincide con el valor total por forma de pago';
          return;
        end if;

        --insert into muerto2(v_001, t_001) values('Desopues de comparar valor recaudo y toal forma pago '||v_ttal_frma_pgo, systimestamp);

        -- Se crea una session para poder usar APEX_COLLECTION
        /*APEX_SESSION.CREATE_SESSION(
            p_app_id => 100
          , p_page_id => 1
          , p_username => 'Distribucion'
        );*/

        begin
        -- Crear o truncar la coleccion
        APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION (
            p_collection_name    => v_nmbre_clccion);
        exception
            when others then
                o_cdgo_rspsta := 30;
                o_mnsje_rspsta := 'Error al crear o truncar coleccion '||v_nmbre_clccion||'-'||sqlerrm;
                return;
        end;

        --insert into muerto2(v_001, t_001) values('Desopues crear colecion '||v_nmbre_clccion, systimestamp);

        -- Agregar los conceptos del recaudo a la coleccion
        begin
            for c_cncptos in (select 'CA' as cmpnnte,
                                     d.id_cncpto,
                                     d.cdgo_cncpto,
                                     d.vlor_cptal as vlor_ttal,
                                     d.vlor_cptal as sldo_pndnte
                                from v_re_g_recaudos_detalle d
                               where d.id_rcdo = p_id_rcdo
                               union
                               select 'IM' as cmpnnte,
                                     d.id_cncpto,
                                     'CIM' AS cdgo_cncpto,
                                     sum(d.vlor_intres) as vlor_ttal,
                                     sum(d.vlor_intres) as sldo_pndnte
                                from v_re_g_recaudos_detalle d
                               where d.id_rcdo = p_id_rcdo
                               group by 'IM', d.id_cncpto, 'CIM'
                               )
            loop

                APEX_COLLECTION.ADD_MEMBER(
                    p_collection_name => v_nmbre_clccion,
                    p_n001            => c_cncptos.id_cncpto,
                    p_c001            => c_cncptos.cdgo_cncpto,
                    p_c002            => c_cncptos.cmpnnte,
                    p_n002            => c_cncptos.vlor_ttal,
                    p_n003            => c_cncptos.sldo_pndnte);

                --insert into muerto2(v_001, t_001) values('Creando miembro colleccion '||c_cncptos.vlor_ttal||'-'||c_cncptos.sldo_pndnte, systimestamp);

            end loop;
        exception
            when others then
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'Error al intentar llenar la coleccion.';
                return;
        end;

        --insert into muerto2(v_001, t_001) values('Desopues de agregar miembros a coleccion '||v_nmbre_clccion, systimestamp);

        -- Iteracion de las formas de pago
        for c_rcdo_frma_pgo in (select id_rcdo_frma_pgo, cdgo_frma_pgo, vlor_pgdo as vlor_frma_pgo
                                  from re_g_recaudos_forma_pago
                                 where id_rcdo = p_id_rcdo)
        loop

        --insert into muerto2(v_001, t_001) values('Recoriendo formas pago '||c_rcdo_frma_pgo.cdgo_frma_pgo||'-'||c_rcdo_frma_pgo.vlor_frma_pgo, systimestamp);

            v_vlor_dstrbcion := c_rcdo_frma_pgo.vlor_frma_pgo;
            v_cdgo_frma_pgo := c_rcdo_frma_pgo.cdgo_frma_pgo;

            -- Iteraci?n de la coleccion
            for c_clccion in (select seq_id,
                                     n001 as id_cncpto,
                                     c001 as cdgo_cncpto,
                                     c002 as cmpnnte,
                                     n002 as vlor_cncpto,
                                     n003 as sldo_pndnte
                                from apex_collections
                               where collection_name = v_nmbre_clccion
                                 and n003 > 0
                               order by n001)
            loop

               --insert into muerto2(v_001, t_001) values('Recoriendo coleeccion '||c_clccion.vlor_cncpto||'-'||c_clccion.sldo_pndnte, systimestamp);

                v_vlor_hber  := 0;
                v_sldo_pndte := 0;

                -- Si saldo pendiente del concepto es mayor a cero
                if c_clccion.sldo_pndnte > 0 then

                    -- Si el valor a distribuir es mayor a cero
                    if v_vlor_dstrbcion > 0 then

                        -- Validamos si el valor a distribuir es mayor o igual al saldo pendiente
                        if v_vlor_dstrbcion >= c_clccion.sldo_pndnte then
                            v_vlor_hber := c_clccion.sldo_pndnte;
                        else
                            -- En caso que el valor a distribuir sea menor al saldo pendiente
                            -- Entonces se aplica el valor restante al concepto
                            v_vlor_hber := v_vlor_dstrbcion;
                        end if;

                        -- Consultar banco y cuenta
                        begin
                            select t.id_bnco,
                                   b.id_bnco_cnta
                              into v_id_bnco,
                                   v_id_bnco_cnta
                            from df_i_cncpto_bncos_cnta b
                            join df_c_bancos_cuenta t on t.id_bnco_cnta = b.id_bnco_cnta
                            where b.id_cncpto = c_clccion.id_cncpto;
                        exception
                            when no_data_found then -- Entra cuando se trae de procesar los Intereses de Mora(IM)
                              v_id_bnco := 10;
                              v_id_bnco_cnta := 20;
                            when others then
                                o_cdgo_rspsta := 50;
                                o_mnsje_rspsta := 'Error al consultar banco y cuenta asociada al concepto.'||c_clccion.id_cncpto||'-'||sqlerrm;
                                return;
                        end;

                        --insert into muerto2(v_001, t_001) values('Validando banco cuenta '||c_clccion.id_cncpto, systimestamp);

                        begin
                            -- Insertar registro de la primera distribucion
                            insert into re_g_recdos_frma_pgo_dtlle(id_rcdo_frma_pgo
                                                                 , id_rcdo
                                                                 , id_bnco
                                                                 , id_bnco_cnta
                                                                 , id_cncpto
                                                                 , indcdor_cmpnnte
                                                                 , vlor_rcddo
                                                                 , prcntje_dstrbcion)
                            values(c_rcdo_frma_pgo.id_rcdo_frma_pgo
                                 , p_id_rcdo
                                 , v_id_bnco
                                 , v_id_bnco_cnta
                                 , c_clccion.id_cncpto
                                 , c_clccion.cmpnnte --'VT' -- VT: Valor Total, CA: Capital, IM: Interes
                                 , v_vlor_hber
                                 , 0);
                        exception
                            when others then
                                rollback;
                                o_cdgo_rspsta := 60;
                                o_mnsje_rspsta := 'Error al insertar registro.'||sqlerrm;
                                return;
                        end;

                        --insert into muerto2(v_001, t_001) values('Despues de insertar registro', systimestamp);

                        -- Se va restando el valor aplicado al valor usado para distribuir
                        -- Nuevo valor a distribuir = Valor a distribuir - Valor Distribuido
                        v_vlor_dstrbcion := v_vlor_dstrbcion - v_vlor_hber;

                        -- Calcular saldo pendiente del concepto
                        -- Nuevo saldo pendiente = saldo pendiente - Vr_Distribuido
                        v_sldo_pndte := c_clccion.sldo_pndnte - v_vlor_hber;

                        -- Actualizar la coleccion
                        -- Se actualiza la columa n003 (saldo pendiente)                        
                        APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                            p_collection_name   => v_nmbre_clccion,
                            p_seq               => c_clccion.seq_id,
                            p_attr_number       => 3,
                            p_number_value      => v_sldo_pndte);

                       -- insert into muerto2(v_001, t_001) values('Despues actualizar coleccion '||v_nmbre_clccion||'-'||v_sldo_pndte, systimestamp);

                    end if;
                end if;
            end loop;

        end loop;

        --insert into muerto2(v_001, t_001) values('Saliendo... '||p_id_rcdo, systimestamp);

        commit;

    exception
        when e_no_id_rcdo then
            o_cdgo_rspsta := 95;
            o_mnsje_rspsta := o_mnsje_rspsta||'. No se ha especificado un recaudo.';        
        when others then
            o_cdgo_rspsta := 99;
            o_mnsje_rspsta := o_mnsje_rspsta||'. Error al intentar registrar distribucion de recaudos por concepto.'||sqlerrm;
    end prc_rg_distribucion_recaudo;


end pkg_recaudos_caja;

/
