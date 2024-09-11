--------------------------------------------------------
--  DDL for Package Body PKG_CB_PROCESO_PERSUASIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_CB_PROCESO_PERSUASIVO" AS

    PROCEDURE prc_rg_proceso_persuasivo (
        p_cdgo_clnte     IN    NUMBER,
        p_id_usuario     IN    NUMBER,
        p_json_sjtos     IN    CLOB,
        p_msvo           IN    VARCHAR2,
        o_cdgo_rspsta    OUT   NUMBER,
        o_mnsje_rspsta   OUT   VARCHAR2
    ) AS

        v_indcdor_prcsdo            VARCHAR2(1);
        v_prcsar_cbro_prssvo        VARCHAR2(1);
        v_obsrvcion_prcsmnto        CLOB;
        v_nmro_prcso_prssvo         NUMBER;
        v_nmro_lte_prcso_prssvo     NUMBER;
        v_id_prcso_prssvo_lte       NUMBER;
        v_id_prcsos_prssvo          NUMBER;
        v_id_fncnrio                NUMBER;
        v_cdgo_orgen_sjto           VARCHAR2(3);
        v_id_acto_tpo               NUMBER;
        v_id_prcsos_prssvo_dcmnto   NUMBER;
        v_id_plntlla                NUMBER;
        v_json_dcmnto               CLOB;
        v_dcmnto                    CLOB;
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';

    -- Inicializacion de variables
        v_id_prcso_prssvo_lte := 0;
        v_nmro_lte_prcso_prssvo := 0;

    -- Buscar el ID del funcionario asociado al usuario
        BEGIN
            SELECT
                u.id_fncnrio
            INTO v_id_fncnrio
            FROM
                v_sg_g_usuarios u
            WHERE
                u.id_usrio = p_id_usuario;

        EXCEPTION
            WHEN no_data_found THEN
                o_cdgo_rspsta := 5;
                o_mnsje_rspsta := 'Error al intentar obtener el ID del usuario.';
                apex_error.add_error(p_message => o_cdgo_rspsta
                                                  || ' - '
                                                  || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification);

                raise_application_error(-20001, o_mnsje_rspsta);
        END;

    -- Recorrer los sujetos de la población seleccionada

        FOR c_sjtos IN (
            SELECT
                id_prcsos_smu_sjto,
                id_prcsos_smu_lte,
                id_sjto,
                to_number(vlor_ttal_dda, 'FM$999G999G999G999G999G999G990') AS vlor_ttal_dda
            FROM
                JSON_TABLE ( p_json_sjtos, '$[*]'
                    COLUMNS (
                        id_prcsos_smu_sjto NUMBER PATH '$.ID_PRCSOS_SMU_SJTO',
                        id_prcsos_smu_lte NUMBER PATH '$.ID_PRCSOS_SMU_LOTE',
                        id_sjto NUMBER PATH '$.ID_SJTO',
                        vlor_ttal_dda VARCHAR2 PATH '$.VLOR_TTAL_DDA'
                    )
                )
        ) LOOP

      -- Validar si el sujeto ha sido procesado y obtener el origen del sujeto
            BEGIN
                SELECT
                    indcdor_prcsdo,
                    cdgo_orgn_sjto
                INTO
                    v_indcdor_prcsdo,
                    v_cdgo_orgen_sjto
                FROM
                    v_cb_g_procesos_simu_sujeto
                WHERE
                    id_prcsos_smu_sjto = c_sjtos.id_prcsos_smu_sjto
                    AND id_prcsos_smu_lte = c_sjtos.id_prcsos_smu_lte
                    AND id_sjto = c_sjtos.id_sjto;

            EXCEPTION
                WHEN OTHERS THEN
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := 'Error al validar estado de procesamiento del sujeto.';
                    apex_error.add_error(p_message => o_cdgo_rspsta
                                                      || ' - '
                                                      || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                      );

                    raise_application_error(-20001, o_mnsje_rspsta);
            END;

      -- ¿El sujeto no ha sido procesado?

            IF v_indcdor_prcsdo = 'N' THEN

        -- De entrada habilitamos al sujeto para que pueda ser procesado
                v_prcsar_cbro_prssvo := 'S';
                v_obsrvcion_prcsmnto := NULL;

        -- ¿El sujeto esta apto para realizar cobro persuasivo?
                IF v_prcsar_cbro_prssvo = 'S' THEN

          -- Obtener consecutivo para el numero del proceso persuasivo
                    v_nmro_prcso_prssvo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'NCP');

          -- ¿No se ha generado un lote de proceso persuasivo?
                    IF v_id_prcso_prssvo_lte = 0 THEN

            -- Obtener un consecutivo para el numero del lote persuasivo.
                        v_nmro_lte_prcso_prssvo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LPP');
                        BEGIN
                            -- Generar el lote perssuasivo
                            INSERT INTO cb_g_procesos_persuasvo_lte (
                                cdgo_clnte,
                                cnsctvo_lte,
                                fcha_lte,
                                obsrvcion_lte,
                                id_fncnrio
                            ) VALUES (
                                p_cdgo_clnte,
                                v_nmro_lte_prcso_prssvo,
                                trunc(sysdate),
                                'Lote de proceso persuasivo de fecha '
                                || to_char(trunc(sysdate), 'dd/mm/yyyy'),
                                v_id_fncnrio
                            ) RETURNING id_prcso_prssvo_lte INTO v_id_prcso_prssvo_lte;

                        EXCEPTION
                            WHEN OTHERS THEN
                                ROLLBACK;
                                o_cdgo_rspsta := 15;
                                o_mnsje_rspsta := 'Error al intentar registrar lote persuasivo.';
                                apex_error.add_error(p_message => o_cdgo_rspsta
                                                                  || ' - '
                                                                  || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                                  );

                                raise_application_error(-20001, o_mnsje_rspsta);
                        END;

                    END IF;

                    BEGIN
                        -- Generar el proceso persuasivo
                        INSERT INTO cb_g_procesos_persuasivo (
                            cdgo_clnte,
                            nmro_prcso,
                            fcha_prcso,
                            vlor_ttal_dda,
                            cdgo_prcso_estdo,
                            id_fncnrio,
                            msvo,
                            id_prcso_prssvo_lte
                        ) VALUES (
                            p_cdgo_clnte,
                            v_nmro_prcso_prssvo,
                            sysdate,
                            c_sjtos.vlor_ttal_dda,
                            'A',
                            v_id_fncnrio,
                            p_msvo,
                            v_id_prcso_prssvo_lte
                        ) RETURNING id_prcsos_prssvo INTO v_id_prcsos_prssvo;

                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK;
                            o_cdgo_rspsta := 20;
                            o_mnsje_rspsta := 'Error al intentar registrar proceso para sujeto #'
                                              || c_sjtos.id_sjto
                                              || '.';
                            apex_error.add_error(p_message => o_cdgo_rspsta
                                                              || ' - '
                                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                              );

                            raise_application_error(-20001, o_mnsje_rspsta);
                    END;

                    BEGIN
                        -- Asociar el sujeto al proceso de cobro generado
                        INSERT INTO cb_procesos_persuasivo_sjto (
                            id_prcsos_prssvo,
                            cdgo_sjto_orgen,
                            id_sjto_orgen
                        ) VALUES (
                            v_id_prcsos_prssvo,
                            v_cdgo_orgen_sjto,
                            c_sjtos.id_sjto
                        );

                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK;
                            o_cdgo_rspsta := 25;
                            o_mnsje_rspsta := 'Error al intentar registrar sujeto #'
                                              || c_sjtos.id_sjto
                                              || '.';
                            apex_error.add_error(p_message => o_cdgo_rspsta
                                                              || ' - '
                                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                              );

                            raise_application_error(-20001, o_mnsje_rspsta);
                    END;

          -- Recorrido de los responsables

                    FOR c_rspsnsbles IN (
                        SELECT
                            a.id_prcsos_smu_sjto,
                            a.cdgo_idntfccion_tpo,
                            a.idntfccion,
                            a.prmer_nmbre,
                            a.sgndo_nmbre,
                            a.prmer_aplldo,
                            a.sgndo_aplldo,
                            a.prncpal_s_n,
                            a.cdgo_tpo_rspnsble,
                            a.prcntje_prtcpcion,
                            a.id_pais_ntfccion,
                            a.id_mncpio_ntfccion,
                            a.id_dprtmnto_ntfccion,
                            a.drccion_ntfccion,
                            a.email,
                            a.tlfno,
                            a.cllar,
                            a.cdgo_orgen_rspnsble
                        FROM
                            v_cb_g_procesos_simu_rspnsble a
                        WHERE
                            a.id_prcsos_smu_sjto = c_sjtos.id_prcsos_smu_sjto
                        GROUP BY
                            a.id_prcsos_smu_sjto,
                            a.cdgo_idntfccion_tpo,
                            a.idntfccion,
                            a.prmer_nmbre,
                            a.sgndo_nmbre,
                            a.prmer_aplldo,
                            a.sgndo_aplldo,
                            a.prncpal_s_n,
                            a.cdgo_tpo_rspnsble,
                            a.prcntje_prtcpcion,
                            a.id_pais_ntfccion,
                            a.id_mncpio_ntfccion,
                            a.id_dprtmnto_ntfccion,
                            a.drccion_ntfccion,
                            a.email,
                            a.tlfno,
                            a.cllar,
                            a.cdgo_orgen_rspnsble
                    ) LOOP BEGIN
                            -- Registrar responsable(s)
                        INSERT INTO cb_g_prcsos_prssvo_rspsble (
                            id_prcsos_prssvo,
                            cdgo_idntfccion_tpo,
                            idntfccion,
                            prmer_nmbre,
                            sgndo_nmbre,
                            prmer_aplldo,
                            sgndo_aplldo,
                            prncpal_s_n,
                            cdgo_tpo_rspnsble,
                            prcntje_prtcpcion,
                            id_pais_ntfccion,
                            id_dprtmnto_ntfccion,
                            id_mncpio_ntfccion,
                            drccion_ntfccion,
                            email,
                            tlfno,
                            cllar,
                            actvo
                        ) VALUES (
                            v_id_prcsos_prssvo,
                            c_rspsnsbles.cdgo_idntfccion_tpo,
                            c_rspsnsbles.idntfccion,
                            c_rspsnsbles.prmer_nmbre,
                            c_rspsnsbles.sgndo_nmbre,
                            c_rspsnsbles.prmer_aplldo,
                            c_rspsnsbles.sgndo_aplldo,
                            c_rspsnsbles.prncpal_s_n,
                            c_rspsnsbles.cdgo_tpo_rspnsble,
                            c_rspsnsbles.prcntje_prtcpcion,
                            NULL --c_rspsnsbles.id_pais_ntfccion
                            ,
                            NULL --c_rspsnsbles.id_dprtmnto_ntfccion
                            ,
                            NULL --c_rspsnsbles.id_mncpio_ntfccion
                            ,
                            c_rspsnsbles.drccion_ntfccion,
                            c_rspsnsbles.email,
                            c_rspsnsbles.tlfno,
                            c_rspsnsbles.cllar,
                            'S'
                        );

                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK;
                            o_cdgo_rspsta := 30;
                            o_mnsje_rspsta := 'Error al intentar registrar responsables.';
                            apex_error.add_error(p_message => o_cdgo_rspsta
                                                              || ' - '
                                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                              );

                            raise_application_error(-20001, o_mnsje_rspsta);
                    END;
                    END LOOP; -- FIN Cursor c_rspsnsbles

          -- Buscar el id del tipo de acto a generar y plantilla

                    BEGIN
                        SELECT
                            a.id_acto_tpo,
                            b.id_plntlla
                        INTO
                            v_id_acto_tpo,
                            v_id_plntlla
                        FROM
                            gn_d_actos_tipo   a
                            JOIN gn_d_plantillas   b ON b.id_acto_tpo = a.id_acto_tpo
                        WHERE
                            a.cdgo_clnte = p_cdgo_clnte
                            AND a.cdgo_acto_tpo = 'OCP';

                    EXCEPTION
                        WHEN OTHERS THEN
                            o_cdgo_rspsta := 35;
                            o_mnsje_rspsta := 'Error al intentar obtener el ID del tipo de acto.';
                            apex_error.add_error(p_message => o_cdgo_rspsta
                                                              || ' - '
                                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                              );

                            raise_application_error(-20001, o_mnsje_rspsta);
                    END;

                    BEGIN
                        SELECT
                            JSON_OBJECT ( 'id_prcsos_prssvo' VALUE v_id_prcsos_prssvo )
                        INTO v_json_dcmnto
                        FROM
                            dual;

                        -- Generar la plantilla

                        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml => v_json_dcmnto, p_id_plntlla => v_id_plntlla);

                        -- Generar el documento persuasivo
                        INSERT INTO cb_g_procesos_prssvo_dcmnto (
                            id_prcsos_prssvo,
                            id_acto_tpo,
                            fcha_rgstro,
                            funcionario_firma,
                            id_acto,
                            id_acto_rqrdo,
                            actvo,
                            id_plntlla,
                            dcmnto
                        ) VALUES (
                            v_id_prcsos_prssvo,
                            v_id_acto_tpo,
                            sysdate,
                            v_id_fncnrio,
                            NULL,
                            NULL,
                            'S',
                            v_id_plntlla,
                            v_dcmnto
                        ) RETURNING id_prcsos_prssvo_dcmnto INTO v_id_prcsos_prssvo_dcmnto;

                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK;
                            o_cdgo_rspsta := 35;
                            o_mnsje_rspsta := 'Error al intentar generar documento de cobro persuasivo.';
                            apex_error.add_error(p_message => o_cdgo_rspsta
                                                              || ' - '
                                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                              );

                            raise_application_error(-20001, o_mnsje_rspsta);
                    END;

          -- El codigo de origen del sujeto es EXISTENTE EN EL SISTEMA?

                    IF v_cdgo_orgen_sjto = 'EX' THEN

            -- Recorrer movimientos
                        FOR c_mvmntos IN (
                            SELECT
                                m.id_prcsos_smu_sjto,
                                m.cdgo_clnte,
                                m.id_impsto,
                                m.id_impsto_sbmpsto,
                                m.cdgo_mvmnto_orgn,
                                m.id_orgen,
                                m.id_mvmnto_fncro,
                                m.id_sjto_impsto,
                                m.vgncia,
                                m.id_prdo,
                                m.id_cncpto,
                                c.vlor_sldo_cptal vlor_cptal,
                                nvl(c.vlor_intres, 0) vlor_intres
                            FROM
                                cb_g_procesos_smu_mvmnto    m
                                JOIN v_gf_g_cartera_x_concepto   c ON c.cdgo_clnte = m.cdgo_clnte
                                                                    AND c.id_impsto = m.id_impsto
                                                                    AND c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
                                                                    AND m.id_sjto_impsto = c.id_sjto_impsto
                                                                    AND m.vgncia = c.vgncia
                                                                    AND m.id_prdo = c.id_prdo
                                                                    AND m.id_cncpto = c.id_cncpto
                                                                    AND c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                                                                    AND c.id_orgen = m.id_orgen
                                                                    AND c.id_mvmnto_fncro = m.id_mvmnto_fncro
                            WHERE
                                m.id_prcsos_smu_sjto = c_sjtos.id_prcsos_smu_sjto
                                AND c.cdgo_clnte = p_cdgo_clnte
                        ) LOOP

              -- Registrar movimientos
                         INSERT INTO cb_g_procesos_prssvo_mvmnto (
                            id_prcsos_prssvo,
                            id_sjto_impsto,
                            vgncia,
                            id_prdo,
                            id_cncpto,
                            cdgo_clnte,
                            id_impsto,
                            id_impsto_sbmpsto,
                            cdgo_mvmnto_orgn,
                            id_orgen,
                            id_mvmnto_fncro,
                            estdo
                        ) VALUES (
                            v_id_prcsos_prssvo,
                            c_mvmntos.id_sjto_impsto,
                            c_mvmntos.vgncia,
                            c_mvmntos.id_prdo,
                            c_mvmntos.id_cncpto,
                            c_mvmntos.cdgo_clnte,
                            c_mvmntos.id_impsto,
                            c_mvmntos.id_impsto_sbmpsto,
                            c_mvmntos.cdgo_mvmnto_orgn,
                            c_mvmntos.id_orgen,
                            c_mvmntos.id_mvmnto_fncro,
                            'A'
                        );

                        END LOOP;

            -- Indicar que ya fue procesado el sujeto EXISTENTE

                        UPDATE cb_g_procesos_simu_sujeto
                        SET
                            indcdor_prcsdo = 'S'
                        WHERE
                            id_prcsos_smu_sjto = c_sjtos.id_prcsos_smu_sjto
                            AND id_prcsos_smu_lte = c_sjtos.id_prcsos_smu_lte;

                    ELSE -- ¿v_cdgo_orgen_sjto = 'NE'?

            -- Indicar que ya fue procesado el sujeto INEXISTENTE
                        UPDATE cb_g_prcss_sm_sjto_inxstnte
                        SET
                            indcdor_prcsdo = 'S'
                        WHERE
                            id_prcsos_smu_sjto_inxstnte = c_sjtos.id_prcsos_smu_sjto
                            AND id_prcsos_smu_lte = c_sjtos.id_prcsos_smu_lte;

                    END IF; -- FIN v_cdgo_orgen_sjto = 'EX'?

                END IF; -- FIN ¿v_prcsar_cbro_prssvo = 'S'?

            ELSE -- ¿v_indcdor_prcsdo = 'S'?
                NULL;
            END IF;  -- FIN v_indcdor_prcsdo = 'N'?

        END LOOP; -- FIN Recorrido de sujetos

    -- Confirmar transacciones

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_cdgo_rspsta := 99;
            o_mnsje_rspsta := 'Error al iniciar procesos de cobro persuasivo.' || sqlerrm;
            apex_error.add_error(p_message => o_cdgo_rspsta
                                              || ' - '
                                              || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification);

            raise_application_error(-20001, o_mnsje_rspsta);
    END prc_rg_proceso_persuasivo;

    PROCEDURE prc_gn_documento_persuasivo (
        p_cdgo_clnte            IN    NUMBER,
        p_json_dcmntos_prrsvo   IN    CLOB,
        p_id_usrio              IN    NUMBER,
        o_cdgo_rspsta           OUT   NUMBER,
        o_mnsje_rspsta          OUT   VARCHAR2
    ) AS

        v_json_actos         CLOB;
        v_slct_sjto_impsto   VARCHAR2(2000);
        v_slct_rspnsble      VARCHAR2(2000);
        v_slct_vgncias       VARCHAR2(2000);
        v_id_acto            NUMBER;
        v_json_dcmnto        CLOB;
        v_gn_d_reportes      gn_d_reportes%rowtype;
        v_blob               BLOB;
        v_actos_gnrdos       NUMBER := 0;
    BEGIN
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';
        FOR c_dcmntos_slccndos IN (
            SELECT
                id_prcsos_prssvo_dcmnto,
                id_prcsos_prssvo,
                id_acto_tpo,
                cdgo_sjto_orgen,
                id_acto
            FROM
                JSON_TABLE ( p_json_dcmntos_prrsvo, '$[*]'
                    COLUMNS (
                        id_prcsos_prssvo_dcmnto NUMBER PATH '$.ID_PRCSOS_PRSSVO_DCMNTO',
                        id_prcsos_prssvo NUMBER PATH '$.ID_PRCSOS_PRSSVO',
                        id_acto_tpo NUMBER PATH '$.ID_ACTO_TPO',
                        cdgo_sjto_orgen VARCHAR2 ( 3 ) PATH '$.CDGO_SJTO_ORGEN',
                        id_acto NUMBER PATH '$.ID_ACTO'
                    )
                )
        ) LOOP IF c_dcmntos_slccndos.id_acto IS NULL THEN
            v_actos_gnrdos := v_actos_gnrdos + 1;

                -- Buscar el ID Plantillas
            BEGIN
                NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    o_cdgo_rspsta := 5;
                    o_mnsje_rspsta := 'Error al intentar obtener el ID del usuario.';
                    apex_error.add_error(p_message => o_cdgo_rspsta
                                                      || ' - '
                                                      || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                      );

                    raise_application_error(-20001, o_mnsje_rspsta);
            END;

            v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto '
                                  || ' from cb_g_procesos_prssvo_mvmnto m '
                                  || ' where m.estdo = '
                                  || chr(39)
                                  || 'A'
                                  || chr(39)
                                  || ' and m.id_prcsos_prssvo = '
                                  || c_dcmntos_slccndos.id_prcsos_prssvo
                                  || ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';

            v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       '
                               || ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   '
                               || ' id_dprtmnto_ntfccion, email, tlfno '
                               || ' from cb_g_prcsos_prssvo_rspsble '
                               || ' where id_prcsos_prssvo = '
                               || c_dcmntos_slccndos.id_prcsos_prssvo;

            v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres'
                              || ' from cb_g_procesos_prssvo_mvmnto b  '
                              || ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte '
                              || ' and c.id_impsto = b.id_impsto '
                              || ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto '
                              || ' and c.id_sjto_impsto = b.id_sjto_impsto '
                              || ' and c.vgncia = b.vgncia '
                              || ' and c.id_prdo = b.id_prdo '
                              || ' and c.id_cncpto = b.id_cncpto '
                              || ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn '
                              || ' and c.id_orgen = b.id_orgen '
                              || ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro '
                              || ' where b.id_prcsos_prssvo = '
                              || c_dcmntos_slccndos.id_prcsos_prssvo
                              || ' and b.estdo = '
                              || chr(39)
                              || 'A'
                              || chr(39)
                              || ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo';
                -- Preparar JSON de acto a generar

            IF c_dcmntos_slccndos.cdgo_sjto_orgen = 'EX' THEN
                v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte => p_cdgo_clnte, p_cdgo_acto_orgen => 'GCP', p_id_orgen
                => c_dcmntos_slccndos.id_prcsos_prssvo_dcmnto, p_id_undad_prdctra => c_dcmntos_slccndos.id_prcsos_prssvo, p_id_acto_tpo
                => c_dcmntos_slccndos.id_acto_tpo,
                                      p_acto_vlor_ttal => 0, --v_vlor_ttal_dda,
                                       p_cdgo_cnsctvo => 'GCP', p_id_usrio => p_id_usrio, p_slct_sjto_impsto => v_slct_sjto_impsto, p_slct_vgncias => v_slct_vgncias,
                                      p_slct_rspnsble => v_slct_rspnsble);
            ELSE
                v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte => p_cdgo_clnte, p_cdgo_acto_orgen => 'GCP', p_id_orgen
                => c_dcmntos_slccndos.id_prcsos_prssvo_dcmnto, p_id_undad_prdctra => c_dcmntos_slccndos.id_prcsos_prssvo, p_id_acto_tpo
                => c_dcmntos_slccndos.id_acto_tpo,
                                      p_acto_vlor_ttal => 0, --v_vlor_ttal_dda,
                                       p_cdgo_cnsctvo => 'GCP', p_id_usrio => p_id_usrio, p_slct_rspnsble => v_slct_rspnsble);
            END IF;

            IF v_json_actos IS NOT NULL THEN
                    -- Generacion del acto
                pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte => p_cdgo_clnte, p_json_acto => v_json_actos, o_cdgo_rspsta => o_cdgo_rspsta
                , o_mnsje_rspsta => o_mnsje_rspsta, o_id_acto => v_id_acto);

                IF o_cdgo_rspsta <> 0 THEN
                    o_cdgo_rspsta := 10;
                    apex_error.add_error(p_message => o_cdgo_rspsta
                                                      || ' - '
                                                      || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification
                                                      );

                    raise_application_error(-20001, o_mnsje_rspsta);
                END IF;

            ELSE
                o_cdgo_rspsta := 15;
                o_mnsje_rspsta := 'Error al obtener los datos del acto a generar.';
                apex_error.add_error(p_message => o_cdgo_rspsta
                                                  || ' - '
                                                  || o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification);

                raise_application_error(-20001, o_mnsje_rspsta);
            END IF;

                -- Actualizar el id acto a la tabla de documentos

            UPDATE cb_g_procesos_prssvo_dcmnto
            SET
                id_acto = v_id_acto
            WHERE
                id_prcsos_prssvo_dcmnto = c_dcmntos_slccndos.id_prcsos_prssvo_dcmnto;

                -- ************ GENERACION DEL REPORTE ******************

            apex_session.attach(p_app_id => 66000, p_page_id => 37, p_session_id => v('APP_SESSION'));

            SELECT
                JSON_OBJECT ( 'id_prcsos_prssvo_dcmnto' VALUE c_dcmntos_slccndos.id_prcsos_prssvo_dcmnto )
            INTO v_json_dcmnto
            FROM
                dual;

                --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO

            apex_util.set_session_state('P37_JSON', v_json_dcmnto);
            apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);

                -- Datos del reporte
            BEGIN
                SELECT
                    a.*
                INTO v_gn_d_reportes
                FROM
                    gn_d_reportes     a
                    JOIN gn_d_plantillas   b ON b.id_rprte = a.id_rprte
                WHERE
                    b.id_acto_tpo = c_dcmntos_slccndos.id_acto_tpo;

            END;

                --GENERAMOS EL DOCUMENTO

            v_blob := apex_util.get_print_document(p_application_id => 66000, p_report_query_name => v_gn_d_reportes.nmbre_cnslta
            , p_report_layout_name => v_gn_d_reportes.nmbre_plntlla, p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla, p_document_format
            => v_gn_d_reportes.cdgo_frmto_tpo);
                -- Actualiar el acto con el BLOB

            pkg_gn_generalidades.prc_ac_acto(p_file_blob => v_blob, p_id_acto => v_id_acto, p_ntfccion_atmtca => 'N');

                -- Regresar a la pagina de origen

            apex_session.attach(p_app_id => 80000, p_page_id => 127, p_session_id => v('APP_SESSION'));

        END IF;
        END LOOP;

        IF v_actos_gnrdos > 0 THEN
            COMMIT;
        ELSE
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := 'Los documentos seleccionados ya han sido procesados.';
            /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );*/
            --raise_application_error( -20001 , o_mnsje_rspsta );
        END IF;

    END prc_gn_documento_persuasivo;

    FUNCTION fnc_cl_parametro_configuracion (
        p_cdgo_clnte       IN   NUMBER,
        p_cdgo_cnfgrcion   IN   VARCHAR2
    ) RETURN CLOB IS
        v_vlor CLOB;
    BEGIN
        BEGIN
            SELECT
                vlor
            INTO v_vlor
            FROM
                cb_d_process_prssvo_cnfgrcn
            WHERE
                cdgo_clnte = p_cdgo_clnte
                AND cdgo_cnfgrcion = p_cdgo_cnfgrcion;

        EXCEPTION
            WHEN OTHERS THEN
                v_vlor := NULL;
        END;

        RETURN v_vlor;
    END fnc_cl_parametro_configuracion;

END pkg_cb_proceso_persuasivo;

/
