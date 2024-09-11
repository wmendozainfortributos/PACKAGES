--------------------------------------------------------
--  DDL for Package Body PKG_GI_PREDIO_VALORIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_PREDIO_VALORIZACION" AS

    PROCEDURE PRC_CREA_PRDIO_VAL_PUNTUAL (
                                            p_cdgo_clnte        IN    NUMBER,
                                            p_id_usuario        IN    NUMBER,
                                            p_rfrncia_ctstral   IN    VARCHAR2,
                                            o_cdgo_rspsta       OUT   NUMBER,
                                            o_mnsje_rspsta      OUT   VARCHAR2
                                             
                                        ) 
    AS
        v_nvel                  NUMBER;
        v_nmbre_up              sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GI_PREDIO_VALORIZACION.PRC_CREA_PRDIO_VAL_PUNTUAL';
        V_ID_IMPSTO_IPU         df_c_impuestos.ID_IMPSTO%TYPE;
        V_ID_IMPSTO_VAL         df_c_impuestos.ID_IMPSTO%TYPE;    
        V_ID_SJTO_IMPSTO_IPU    NUMBER;
        V_ID_SJTO_IMPSTO_VAL    NUMBER; 
    BEGIN

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        BEGIN
            SELECT ID_IMPSTO INTO V_ID_IMPSTO_IPU   
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'IPU';

            SELECT ID_IMPSTO INTO V_ID_IMPSTO_VAL 
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'VAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'No se encontró información.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                RETURN;
        END;

        BEGIN
            SELECT i.id_sjto_impsto INTO V_ID_SJTO_IMPSTO_VAL
            FROM v_si_i_sujetos_impuesto i
            WHERE i.id_impsto = V_ID_IMPSTO_VAL
            AND i.idntfccion_sjto = P_RFRNCIA_CTSTRAL 
            /*AND I.ID_SJTO_ESTDO = 1*/;

            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := 'La referencia ['||P_RFRNCIA_CTSTRAL||'] ya tiene sujeto de Valorización';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- Deja V_ID_SJTO_IMPSTO_VAL como NULL
        END;

        BEGIN
            SELECT i.id_sjto_impsto INTO V_ID_SJTO_IMPSTO_IPU
            FROM V_SI_I_SUJETOS_IMPUESTO i
            WHERE i.id_impsto = V_ID_IMPSTO_IPU
            AND I.IDNTFCCION_SJTO = P_RFRNCIA_CTSTRAL
            AND I.ID_SJTO_ESTDO = 1;

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Sujeto predial: '||V_ID_SJTO_IMPSTO_IPU , 3 );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_cdgo_rspsta := 30;
                o_mnsje_rspsta := 'La referencia ['||P_RFRNCIA_CTSTRAL||'] no existe en el sistema para el impuesto predial.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                --NULL; -- Deja V_ID_SJTO_IMPSTO_PRDAL como NULL
               return;
            WHEN OTHERS THEN
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'Error al consultar impuesto predial para la referencia ['||P_RFRNCIA_CTSTRAL||']. '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                --NULL; -- Deja V_ID_SJTO_IMPSTO_PRDAL como NULL
               return;
        END;

        IF V_ID_SJTO_IMPSTO_IPU IS NULL THEN
            o_cdgo_rspsta := 50;
            o_mnsje_rspsta := 'No se encontró información del impuesto predial para la referencia: ' || P_RFRNCIA_CTSTRAL;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            RETURN;
        END IF;

        BEGIN
            for c_sjto in ( SELECT c.id_sjto,
                                --V_ID_IMPSTO_VAL,
                                c.estdo_blqdo,
                                c.id_pais_ntfccion,
                                c.id_dprtmnto_ntfccion,
                                c.id_mncpio_ntfccion,
                                c.drccion_ntfccion,
                                c.email,
                                c.tlfno,
                                c.fcha_rgstro,
                                c.id_usrio,
                                c.id_sjto_estdo,
                                c.fcha_ultma_nvdad,
                                c.fcha_cnclcion,
                                c.indcdor_sjto_mgrdo,
                                c.indcdor_mgrdo
                            FROM si_i_sujetos_impuesto c
                            WHERE  c.id_sjto_impsto = V_ID_SJTO_IMPSTO_IPU )
            loop
                    INSERT INTO si_i_sujetos_impuesto
                                (id_sjto,
                                id_impsto,
                                estdo_blqdo,
                                id_pais_ntfccion,
                                id_dprtmnto_ntfccion,
                                id_mncpio_ntfccion,
                                drccion_ntfccion,
                                email,
                                tlfno,
                                fcha_rgstro,
                                id_usrio,
                                id_sjto_estdo,
                                fcha_ultma_nvdad,
                                fcha_cnclcion,
                                indcdor_sjto_mgrdo,
                                indcdor_mgrdo
                               )
                values  (
                        c_sjto.id_sjto ,
                        V_ID_IMPSTO_VAL ,
                        c_sjto.estdo_blqdo ,
                        c_sjto.id_pais_ntfccion ,
                        c_sjto.id_dprtmnto_ntfccion ,
                        c_sjto.id_mncpio_ntfccion ,
                        c_sjto.drccion_ntfccion ,
                        c_sjto.email ,
                        c_sjto.tlfno ,
                        c_sjto.fcha_rgstro ,
                        c_sjto.id_usrio ,
                        c_sjto.id_sjto_estdo ,
                        c_sjto.fcha_ultma_nvdad ,
                        c_sjto.fcha_cnclcion ,
                        c_sjto.indcdor_sjto_mgrdo ,
                        c_sjto.indcdor_mgrdo
                        )
                returning id_sjto_impsto into V_ID_SJTO_IMPSTO_VAL;

                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Sujeto Valorización: '||V_ID_SJTO_IMPSTO_VAL , 3 );
            end loop;

            /*SELECT c.id_sjto,
                V_ID_IMPSTO_VAL,
                c.estdo_blqdo,
                c.id_pais_ntfccion,
                c.id_dprtmnto_ntfccion,
                c.id_mncpio_ntfccion,
                c.drccion_ntfccion,
                c.email,
                c.tlfno,
                c.fcha_rgstro,
                c.id_usrio,
                c.id_sjto_estdo,
                c.fcha_ultma_nvdad,
                c.fcha_cnclcion,
                c.indcdor_sjto_mgrdo,
                c.indcdor_mgrdo
            FROM si_i_sujetos_impuesto c
            WHERE  c.id_sjto_impsto = V_ID_SJTO_IMPSTO_IPU ;*/

        --      SELECT id_sjto_impsto INTO V_ID_SJTO_IMPSTO_VAL
   --     FROM si_i_sujetos_impuesto where id_sjto =  2983272 and ID_IMPSTO = 2300115;


        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 50;
                o_mnsje_rspsta := 'Error al insertar sujeto impuesto: ' || SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                return;
        END;

        BEGIN
            INSERT INTO si_i_sujetos_responsable
                (id_sjto_impsto,
                cdgo_idntfccion_tpo,
                idntfccion,
                prmer_nmbre,
                sgndo_nmbre,
                prmer_aplldo,
                sgndo_aplldo,
                prncpal_s_n,
                cdgo_tpo_rspnsble,
                prcntje_prtcpcion,
                orgen_dcmnto,
                id_pais_ntfccion,
                id_dprtmnto_ntfccion,
                id_mncpio_ntfccion,
                drccion_ntfccion,
                email,
                tlfno,
                cllar,
                actvo,
                id_trcro,
                indcdor_mgrdo)
            SELECT V_ID_SJTO_IMPSTO_VAL,
                t.cdgo_idntfccion_tpo,
                t.idntfccion,
                t.prmer_nmbre,
                t.sgndo_nmbre,
                t.prmer_aplldo,
                t.sgndo_aplldo,
                t.prncpal_s_n,
                t.cdgo_tpo_rspnsble,
                t.prcntje_prtcpcion,
                t.orgen_dcmnto,
                t.id_pais_ntfccion,
                t.id_dprtmnto_ntfccion,
                t.id_mncpio_ntfccion,
                t.drccion_ntfccion,
                t.email,
                t.tlfno,
                t.cllar,
                t.actvo,
                t.id_trcro,
                t.indcdor_mgrdo
            FROM si_i_sujetos_responsable t
            WHERE id_sjto_impsto = V_ID_SJTO_IMPSTO_IPU;

           pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Responsables registrados para sujeto: '||V_ID_SJTO_IMPSTO_VAL , 3 );
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 60;
                o_mnsje_rspsta := 'Error al insertar sujeto responsable: ' || SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                return;
        END;

        --CREO EL PREDIO
        BEGIN
            INSERT INTO si_i_predios
                    (id_sjto_impsto,
                    id_prdio_dstno,
                    cdgo_estrto,
                    cdgo_dstno_igac,
                    cdgo_prdio_clsfccion,
                    id_prdio_uso_slo,
                    avluo_ctstral,
                    avluo_cmrcial,
                    area_trrno,
                    area_cnstrda,
                    area_grvble,
                    mtrcla_inmblria,
                    indcdor_prdio_mncpio,
                    id_entdad,
                    id_brrio,
                    fcha_ultma_actlzcion,
                    bse_grvble,
                    dstncia,
                    lttud,
                    lngtud,
                    indcdor_mgrdo)
            SELECT V_ID_SJTO_IMPSTO_VAL,
                t.id_prdio_dstno,
                t.cdgo_estrto,
                t.cdgo_dstno_igac,
                t.cdgo_prdio_clsfccion,
                t.id_prdio_uso_slo,
                t.avluo_ctstral,
                t.avluo_cmrcial,
                t.area_trrno,
                t.area_cnstrda,
                t.area_grvble,
                t.mtrcla_inmblria,
                t.indcdor_prdio_mncpio,
                t.id_entdad,
                t.id_brrio,
                t.fcha_ultma_actlzcion,
                t.bse_grvble,
                t.dstncia,
                t.lttud,
                t.lngtud,
                t.indcdor_mgrdo
            FROM si_i_predios t
            WHERE id_sjto_impsto = V_ID_SJTO_IMPSTO_IPU;                                            

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'predio registrados para sujeto: '||V_ID_SJTO_IMPSTO_VAL , 3 );

          --COMMIT;  
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 70;
                o_mnsje_rspsta := 'Error al insertar predio: ' || SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                return;
        END;

        -- Traza del proceso
        begin
            INSERT INTO SI_I_PREDIO_VALORIZACION_TRAZA (
                                ID_USRIO,
                                CDGO_CLNTE,
                                OBSRVCION,
                                FCHA_GSTION,
                                CDGO_PRCSO,
                                RFRNCIA_CTSTRAL,
                                RSLCION_IGAC
                            ) VALUES (
                                p_id_usuario,
                                p_cdgo_clnte,
                               'Sujeto de Valorización creado exitosamente',
                                SYSDATE,
                                'CP', 
                                p_rfrncia_ctstral,
                                NULL
                            );
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 70;
                o_mnsje_rspsta := 'Error al insertar traza para referencia: ' || p_rfrncia_ctstral ||' - '||SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
        END;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Sujeto de Valorización Creado Exitosamente' , 3 );

        COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 100;
                o_mnsje_rspsta := 'Error controlado referencia : ' || p_rfrncia_ctstral ||' - '||SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );

    END PRC_CREA_PRDIO_VAL_PUNTUAL;


    PROCEDURE PRC_ACTLZA_PRDIOS_VAL (
                                        p_cdgo_clnte       IN NUMBER,
                                        p_id_usuario       IN NUMBER,
                                        p_rfrncia_ctstral  IN VARCHAR2,
                                        o_cdgo_rspsta      OUT NUMBER,
                                        o_mnsje_rspsta     OUT VARCHAR2
                                    )
    AS
        v_nvel                NUMBER;
        v_nmbre_up            sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GI_PREDIO_VALORIZACION.PRC_ACTLZA_PRDIOS_VAL';
        v_id_impsto_ipu       df_c_impuestos.ID_IMPSTO%TYPE;
        v_id_impsto_val       df_c_impuestos.ID_IMPSTO%TYPE;
       -- v_mensaje            varchar2 (100);



        CURSOR C1 IS
            SELECT I.ID_SJTO, I.ID_SJTO_IMPSTO
            FROM SI_I_SUJETOS_IMPUESTO I
            WHERE I.ID_IMPSTO = v_id_impsto_val
              AND EXISTS (
                  SELECT 1
                  FROM SI_I_SUJETOS_IMPUESTO T
                  WHERE T.ID_SJTO = I.ID_SJTO
                    AND T.ID_SJTO_IMPSTO <> I.ID_SJTO_IMPSTO
              )
              AND EXISTS (
                  SELECT 1
                  FROM SI_C_SUJETOS S
                  WHERE S.ID_SJTO = I.ID_SJTO
                    AND (S.IDNTFCCION = p_rfrncia_ctstral OR p_rfrncia_ctstral IS NULL)
              );

        -- SUJETO PREDIAL
        CURSOR C2 (R_ID_SJTO NUMBER) IS
            SELECT I.ID_SJTO_IMPSTO, I.ID_SJTO_ESTDO
            FROM SI_I_SUJETOS_IMPUESTO I
            WHERE I.ID_IMPSTO = v_id_impsto_ipu
              AND I.ID_SJTO = R_ID_SJTO;

        -- BUSCO LOS DATOS PREDIAL
        CURSOR C3 (R_ID_SJTO_IMPSTO NUMBER) IS
            SELECT P.AVLUO_CTSTRAL,
                   P.MTRCLA_INMBLRIA,
                   P.AREA_TRRNO,
                   P.AREA_CNSTRDA,
                   P.CDGO_ESTRTO
            FROM SI_I_PREDIOS P
            WHERE P.ID_SJTO_IMPSTO = R_ID_SJTO_IMPSTO;

    BEGIN

        -- Respuesta Exitosa
        o_cdgo_rspsta := 0;

        -- Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento. Referencia: ' || p_rfrncia_ctstral;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 1);

        BEGIN
            SELECT ID_IMPSTO INTO v_id_impsto_ipu
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'IPU';

            SELECT ID_IMPSTO INTO v_id_impsto_val
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'VAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'No se encontró información.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);
                RETURN;
        END;

        FOR R1 IN C1 LOOP
            DECLARE
                V_ID_SJTO_IMPSTO_PRDAL NUMBER;
                V_AVLUO                NUMBER;
                V_AREA_TRRNO           NUMBER;
                V_AREA_CNSTRDA         NUMBER;
                V_ESTDO_SJTO_PRDIAL    NUMBER;
                V_MTRCLA               VARCHAR2(50);
                V_ESTRTO               NUMBER;

            BEGIN
                FOR R2 IN C2(R1.ID_SJTO) LOOP
                    V_ID_SJTO_IMPSTO_PRDAL := R2.ID_SJTO_IMPSTO;
                    V_ESTDO_SJTO_PRDIAL    := R2.ID_SJTO_ESTDO;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ID_SJTO_IMPSTO_PRDAL: '||V_ID_SJTO_IMPSTO_PRDAL , 3 );
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ESTDO_SJTO_PRDIAL: '||V_ESTDO_SJTO_PRDIAL , 3 );
                END LOOP;

                FOR R3 IN C3(V_ID_SJTO_IMPSTO_PRDAL) LOOP
                    V_AVLUO        := R3.AVLUO_CTSTRAL;
                    V_MTRCLA       := R3.MTRCLA_INMBLRIA;
                    V_AREA_TRRNO   := R3.AREA_TRRNO;
                    V_AREA_CNSTRDA := R3.AREA_CNSTRDA;
                    V_ESTRTO       := R3.CDGO_ESTRTO;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ESTRTO: '||V_ESTRTO , 3 );
                END LOOP;

                -- ACTUALIZO AVALUO Y MATRICULA VALORIZACION
                UPDATE SI_I_PREDIOS P
                   SET P.AVLUO_CTSTRAL   = V_AVLUO,
                       P.MTRCLA_INMBLRIA = V_MTRCLA,
                       P.AVLUO_CMRCIAL   = V_AVLUO,
                       P.AREA_TRRNO      = V_AREA_TRRNO,
                       P.AREA_CNSTRDA    = V_AREA_CNSTRDA,
                       P.CDGO_ESTRTO     = V_ESTRTO
                 WHERE P.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                UPDATE SI_I_SUJETOS_IMPUESTO I
                   SET I.ID_SJTO_ESTDO = V_ESTDO_SJTO_PRDIAL
                 WHERE I.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                DELETE FROM SI_I_SUJETOS_RESPONSABLE R
                 WHERE R.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                INSERT INTO SI_I_SUJETOS_RESPONSABLE
                    (ID_SJTO_IMPSTO,
                     CDGO_IDNTFCCION_TPO,
                     IDNTFCCION,
                     PRMER_NMBRE,
                     SGNDO_NMBRE,
                     PRMER_APLLDO,
                     SGNDO_APLLDO,
                     PRNCPAL_S_N,
                     CDGO_TPO_RSPNSBLE,
                     PRCNTJE_PRTCPCION,
                     ORGEN_DCMNTO,
                     ID_PAIS_NTFCCION,
                     ID_DPRTMNTO_NTFCCION,
                     ID_MNCPIO_NTFCCION,
                     DRCCION_NTFCCION,
                     EMAIL,
                     TLFNO,
                     CLLAR,
                     ACTVO,
                     ID_TRCRO,
                     INDCDOR_MGRDO)
                SELECT R1.ID_SJTO_IMPSTO,
                       R.CDGO_IDNTFCCION_TPO,
                       R.IDNTFCCION,
                       R.PRMER_NMBRE,
                       R.SGNDO_NMBRE,
                       R.PRMER_APLLDO,
                       R.SGNDO_APLLDO,
                       R.PRNCPAL_S_N,
                       R.CDGO_TPO_RSPNSBLE,
                       R.PRCNTJE_PRTCPCION,
                       R.ORGEN_DCMNTO,
                       R.ID_PAIS_NTFCCION,
                       R.ID_DPRTMNTO_NTFCCION,
                       R.ID_MNCPIO_NTFCCION,
                       R.DRCCION_NTFCCION,
                       R.EMAIL,
                       R.TLFNO,
                       R.CLLAR,
                       R.ACTVO,
                       R.ID_TRCRO,
                       R.INDCDOR_MGRDO
                  FROM SI_I_SUJETOS_RESPONSABLE R
                 WHERE R.ID_SJTO_IMPSTO = V_ID_SJTO_IMPSTO_PRDAL;

                    COMMIT;
           EXCEPTION
               WHEN OTHERS THEN
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Error en la actualización e inserción: ' || SQLERRM, 3);
                ROLLBACK;
             END;
       --  END;



        END LOOP;

       begin
            INSERT INTO SI_I_PREDIO_VALORIZACION_TRAZA (
                                                        ID_USRIO,
                                                        CDGO_CLNTE,
                                                        OBSRVCION,
                                                        FCHA_GSTION,
                                                        CDGO_PRCSO,
                                                        RFRNCIA_CTSTRAL,
                                                        RSLCION_IGAC) 
                                                    VALUES 
                                                        (p_id_usuario,
                                                        p_cdgo_clnte,
                                                        'Actualizacion Masiva Exitosa',
                                                        SYSDATE,
                                                        'AM', 
                                                        p_rfrncia_ctstral,
                                                        NULL);   
        --COMMIT; 
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 70;
                o_mnsje_rspsta := 'Error al insertar traza para referencia: ' || p_rfrncia_ctstral ||' - '||SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
        END;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Sujeto de Valorización modificado exitosamente' , 3 );        



    EXCEPTION
        WHEN OTHERS THEN
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error en la ejecución del procedimiento: ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);

    END PRC_ACTLZA_PRDIOS_VAL;



    PROCEDURE PRC_CREA_PRDIO_VAL (
                                    P_RSLCION_IGAC    IN VARCHAR2,
                                    p_cdgo_clnte      IN NUMBER,
                                    p_id_usuario      IN NUMBER,
                                    o_cdgo_rspsta     OUT NUMBER,
                                    o_mnsje_rspsta    OUT VARCHAR2
                                   -- P_MNSJE           OUT VARCHAR2
                                )
    IS
        v_nvel                   NUMBER;
        v_nmbre_up               sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GI_PREDIO_VALORIZACION.PRC_CREA_PRDIO_VAL';
        V_ID_SJTO_IMPSTO_PRDAL   NUMBER;
        V_ID_IMPSTO_IPU          df_c_impuestos.ID_IMPSTO%TYPE;
        V_ID_IMPSTO_VAL          df_c_impuestos.ID_IMPSTO%TYPE;    

    begin

        -- Respuesta Exitosa
        o_cdgo_rspsta := 0;

        -- Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento. resolución ' || P_RSLCION_IGAC;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 1);

        begin
            SELECT ID_IMPSTO INTO v_id_impsto_ipu
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'IPU';

            SELECT ID_IMPSTO INTO v_id_impsto_val
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'VAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'No se encontró información.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);
                RETURN;
        END;

        for c_datos in (select rfrncia_igac, id_sjto_impsto
                        from si_g_resolucion_igac_t1
                       where rslcion = P_RSLCION_IGAC
                         and cncla_inscrbe = 'I') 
        loop

        --insert into muerto (v_001, v_002) values ('P_IGAC', c_datos.rfrncia_igac); commit;
        declare
          --RECORRER LOS PREDIOS DE VALORIZACI?N
          CURSOR c1 IS
            SELECT c.id_sjto
              FROM si_c_sujetos c
             WHERE c.idntfccion = c_datos.rfrncia_igac; --SUJETO PREDIAL
          CURSOR c2(r_id_sjto NUMBER) IS
            SELECT i.id_sjto_impsto
              FROM si_i_sujetos_impuesto i
             WHERE i.id_impsto = V_ID_IMPSTO_IPU
               AND i.id_sjto = r_id_sjto; --SUJETO VALORIZACION
          CURSOR c3(r_id_sjto NUMBER) IS
            SELECT i.id_sjto_impsto
              FROM si_i_sujetos_impuesto i
             WHERE i.id_impsto = V_ID_IMPSTO_VAL
               AND i.id_sjto = r_id_sjto;

          CURSOR c4 IS
            SELECT i.id_sjto_impsto
              FROM v_si_i_sujetos_impuesto i
             WHERE i.id_impsto = V_ID_IMPSTO_VAL
               AND i.idntfccion_sjto = c_datos.rfrncia_igac;
        begin
          BEGIN
            BEGIN
              o_mnsje_rspsta := NULL;
              FOR r4 IN c4 LOOP
                o_mnsje_rspsta := 'SUJETO IMPUESTO YA EXISTE EN VALORIZACION';
              END LOOP;
              IF o_mnsje_rspsta IS NULL THEN
                FOR r1 IN c1 LOOP
                  FOR r2 IN c2(r1.id_sjto) LOOP
                    v_id_sjto_impsto_prdal := r2.id_sjto_impsto;


                    INSERT INTO si_i_sujetos_impuesto
                      (id_sjto,
                       id_impsto,
                       estdo_blqdo,
                       id_pais_ntfccion,
                       id_dprtmnto_ntfccion,
                       id_mncpio_ntfccion,
                       drccion_ntfccion,
                       email,
                       tlfno,
                       fcha_rgstro,
                       id_usrio,
                       id_sjto_estdo,
                       fcha_ultma_nvdad,
                       fcha_cnclcion,
                       indcdor_sjto_mgrdo,
                       indcdor_mgrdo)
                      SELECT c.id_sjto,
                             V_ID_IMPSTO_VAL,
                             c.estdo_blqdo,
                             c.id_pais_ntfccion,
                             c.id_dprtmnto_ntfccion,
                             c.id_mncpio_ntfccion,
                             c.drccion_ntfccion,
                             c.email,
                             c.tlfno,
                             c.fcha_rgstro,
                             c.id_usrio,
                             c.id_sjto_estdo,
                             c.fcha_ultma_nvdad,
                             c.fcha_cnclcion,
                             c.indcdor_sjto_mgrdo,
                             c.indcdor_mgrdo
                        FROM si_i_sujetos_impuesto c
                       WHERE c.id_sjto = r1.id_sjto
                         AND c.id_impsto = V_ID_IMPSTO_IPU;


                    COMMIT;

                  END LOOP;

                  FOR r3 IN c3(r1.id_sjto) LOOP
                    --CREO RESPONSABLES
                    INSERT INTO si_i_sujetos_responsable
                      (id_sjto_impsto,
                       cdgo_idntfccion_tpo,
                       idntfccion,
                       prmer_nmbre,
                       sgndo_nmbre,
                       prmer_aplldo,
                       sgndo_aplldo,
                       prncpal_s_n,
                       cdgo_tpo_rspnsble,
                       prcntje_prtcpcion,
                       orgen_dcmnto,
                       id_pais_ntfccion,
                       id_dprtmnto_ntfccion,
                       id_mncpio_ntfccion,
                       drccion_ntfccion,
                       email,
                       tlfno,
                       cllar,
                       actvo,
                       id_trcro,
                       indcdor_mgrdo)
                      SELECT r3.id_sjto_impsto,
                             t.cdgo_idntfccion_tpo,
                             t.idntfccion,
                             t.prmer_nmbre,
                             t.sgndo_nmbre,
                             t.prmer_aplldo,
                             t.sgndo_aplldo,
                             t.prncpal_s_n,
                             t.cdgo_tpo_rspnsble,
                             t.prcntje_prtcpcion,
                             t.orgen_dcmnto,
                             t.id_pais_ntfccion,
                             t.id_dprtmnto_ntfccion,
                             t.id_mncpio_ntfccion,
                             t.drccion_ntfccion,
                             t.email,
                             t.tlfno,
                             t.cllar,
                             t.actvo,
                             t.id_trcro,
                             t.indcdor_mgrdo
                        FROM si_i_sujetos_responsable t
                       WHERE id_sjto_impsto = v_id_sjto_impsto_prdal;


                    --CREO EL PREDIO
                    INSERT INTO si_i_predios
                      (id_sjto_impsto,
                       id_prdio_dstno,
                       cdgo_estrto,
                       cdgo_dstno_igac,
                       cdgo_prdio_clsfccion,
                       id_prdio_uso_slo,
                       avluo_ctstral,
                       avluo_cmrcial,
                       area_trrno,
                       area_cnstrda,
                       area_grvble,
                       mtrcla_inmblria,
                       indcdor_prdio_mncpio,
                       id_entdad,
                       id_brrio,
                       fcha_ultma_actlzcion,
                       bse_grvble,
                       dstncia,
                       lttud,
                       lngtud,
                       indcdor_mgrdo)
                      SELECT r3.id_sjto_impsto,
                             t.id_prdio_dstno,
                             t.cdgo_estrto,
                             t.cdgo_dstno_igac,
                             t.cdgo_prdio_clsfccion,
                             t.id_prdio_uso_slo,
                             t.avluo_ctstral,
                             t.avluo_cmrcial,
                             t.area_trrno,
                             t.area_cnstrda,
                             t.area_grvble,
                             t.mtrcla_inmblria,
                             t.indcdor_prdio_mncpio,
                             t.id_entdad,
                             t.id_brrio,
                             t.fcha_ultma_actlzcion,
                             t.bse_grvble,
                             t.dstncia,
                             t.lttud,
                             t.lngtud,
                             t.indcdor_mgrdo
                        FROM si_i_predios t
                       WHERE id_sjto_impsto = v_id_sjto_impsto_prdal;

                  END LOOP;
                 o_cdgo_rspsta := 40;  
                  o_mnsje_rspsta := 'SUJETO CREADO CON EXITO';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);


                END LOOP;


                COMMIT;
              END IF;
        /*    EXCEPTION
        WHEN OTHERS THEN
            o_cdgo_rspsta := SQLCODE;
            o_mnsje_rspsta := 'Error en la ejecución del procedimiento: ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);
    */
            END loop;


                             COMMIT; 
            EXCEPTION
        WHEN OTHERS THEN
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error en la ejecución del procedimiento: ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);

          end;
           INSERT INTO SI_I_PREDIO_VALORIZACION_TRAZA (
                                                        ID_USRIO,
                                                        CDGO_CLNTE,
                                                        OBSRVCION,
                                                        FCHA_GSTION,
                                                        CDGO_PRCSO,
                                                        RFRNCIA_CTSTRAL,
                                                        RSLCION_IGAC) VALUES 
                                                                            (p_id_usuario,
                                                                            p_cdgo_clnte,
                                                                            'Creacion Masiva Exitosa',
                                                                            SYSDATE,
                                                                            'CM', 
                                                                            NULL,
                                                                            P_RSLCION_IGAC);
        end;
      end loop;

    END PRC_CREA_PRDIO_VAL;


    PROCEDURE PRC_CREA_PRDIO_VAL_ARCHIVO ( p_cdgo_clnte      IN NUMBER,
                                           p_id_usuario      IN NUMBER,
                                           p_id_session      IN NUMBER,
                                           o_cdgo_rspsta     OUT NUMBER,
                                           o_mnsje_rspsta    OUT VARCHAR2                                    
                                          )                                           
    as
        v_nvel                   NUMBER;
        v_nmbre_up               sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GI_PREDIO_VALORIZACION.PRC_CREA_PRDIO_VAL_ARCHIVO';      
    begin

        -- Respuesta Exitosa
        o_cdgo_rspsta := 0;

        -- Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento. Sesión ' || p_id_session;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 1);


        for c_sujetos in (	select 	c001 idntfccion_sjto
                            from 	gn_g_temporal 
                            where	id_ssion = p_id_session
                            and     c005     = 'VLD'
                         )
        loop
            begin
                PKG_GI_PREDIO_VALORIZACION.PRC_CREA_PRDIO_VAL_PUNTUAL (
                                                                        p_cdgo_clnte        => p_cdgo_clnte ,
                                                                        p_id_usuario        => p_id_usuario ,
                                                                        p_rfrncia_ctstral   => c_sujetos.idntfccion_sjto ,
                                                                        o_cdgo_rspsta       => o_cdgo_rspsta ,
                                                                        o_mnsje_rspsta      => o_mnsje_rspsta 
                                                                    ) ;

                if o_cdgo_rspsta > 0 then	
                    rollback;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nvel , 'No se registra para: '||c_sujetos.idntfccion_sjto ||' - '||o_mnsje_rspsta , 1 );
                    continue;
                end if;
                commit; -- se asegura cada sujeto creado
            exception
                when others then	
                    rollback;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nvel , 'Error valorización: '||c_sujetos.idntfccion_sjto ||' - '||sqlerrm , 1 );
                    continue;
            end;

        end loop;


    exception
        when others then	
            rollback;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte , null , v_nmbre_up, v_nvel , 'Error controlado: '||sqlerrm , 1 );


    end PRC_CREA_PRDIO_VAL_ARCHIVO;



PROCEDURE PRC_ACTLZA_PRDIOS_VAL_MASIVO (
                                        p_cdgo_clnte       IN NUMBER,
                                        p_id_usuario       IN NUMBER,
                                         p_rfrncia_ctstral  IN VARCHAR2

                                    )
    AS
        v_nvel                NUMBER;
        v_nmbre_up            sg_d_configuraciones_log.nmbre_up%TYPE := 'PKG_GI_PREDIO_VALORIZACION.PRC_ACTLZA_PRDIOS_VAL_MASIVO';
        v_id_impsto_ipu       df_c_impuestos.ID_IMPSTO%TYPE;
        v_id_impsto_val       df_c_impuestos.ID_IMPSTO%TYPE;
        v_mensaje            varchar2 (100);
        v_correo            v_sg_g_usuarios.email%type; 
        v_from              ma_d_envios_mdio_cnfgrcn_pr.vlor%type;
        val                  varchar2(1000);
        o_cdgo_rspsta       NUMBER;
        o_mnsje_rspsta      VARCHAR2(4000);

        CURSOR C1 IS
            SELECT I.ID_SJTO, I.ID_SJTO_IMPSTO
            FROM SI_I_SUJETOS_IMPUESTO I
            WHERE I.ID_IMPSTO = v_id_impsto_val
              AND EXISTS (
                  SELECT 1
                  FROM SI_I_SUJETOS_IMPUESTO T
                  WHERE T.ID_SJTO = I.ID_SJTO
                    AND T.ID_SJTO_IMPSTO <> I.ID_SJTO_IMPSTO
              )
              AND EXISTS (
                  SELECT 1
                  FROM SI_C_SUJETOS S
                  WHERE S.ID_SJTO = I.ID_SJTO
                    AND (S.IDNTFCCION = p_rfrncia_ctstral OR p_rfrncia_ctstral IS NULL)
              );

        -- SUJETO PREDIAL
        CURSOR C2 (R_ID_SJTO NUMBER) IS
            SELECT I.ID_SJTO_IMPSTO, I.ID_SJTO_ESTDO
            FROM SI_I_SUJETOS_IMPUESTO I
            WHERE I.ID_IMPSTO = v_id_impsto_ipu
              AND I.ID_SJTO = R_ID_SJTO;

        -- BUSCO LOS DATOS PREDIAL
        CURSOR C3 (R_ID_SJTO_IMPSTO NUMBER) IS
            SELECT P.AVLUO_CTSTRAL,
                   P.MTRCLA_INMBLRIA,
                   P.AREA_TRRNO,
                   P.AREA_CNSTRDA,
                   P.CDGO_ESTRTO
            FROM SI_I_PREDIOS P
            WHERE P.ID_SJTO_IMPSTO = R_ID_SJTO_IMPSTO;

    BEGIN

        -- Respuesta Exitosa
        o_cdgo_rspsta := 0;

        -- Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up);

        o_mnsje_rspsta := 'Inicio del procedimiento. Referencia: ' || p_rfrncia_ctstral;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 1);

        BEGIN
            SELECT ID_IMPSTO INTO v_id_impsto_ipu
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'IPU';

            SELECT ID_IMPSTO INTO v_id_impsto_val
            FROM df_c_impuestos 
            WHERE cdgo_impsto = 'VAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'No se encontró información.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);
                RETURN;
        END;

        FOR R1 IN C1 LOOP
            DECLARE
                V_ID_SJTO_IMPSTO_PRDAL NUMBER;
                V_AVLUO                NUMBER;
                V_AREA_TRRNO           NUMBER;
                V_AREA_CNSTRDA         NUMBER;
                V_ESTDO_SJTO_PRDIAL    NUMBER;
                V_MTRCLA               VARCHAR2(50);
                V_ESTRTO               NUMBER;

            BEGIN
                FOR R2 IN C2(R1.ID_SJTO) LOOP
                    V_ID_SJTO_IMPSTO_PRDAL := R2.ID_SJTO_IMPSTO;
                    V_ESTDO_SJTO_PRDIAL    := R2.ID_SJTO_ESTDO;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ID_SJTO_IMPSTO_PRDAL: '||V_ID_SJTO_IMPSTO_PRDAL , 3 );
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ESTDO_SJTO_PRDIAL: '||V_ESTDO_SJTO_PRDIAL , 3 );
                END LOOP;

                FOR R3 IN C3(V_ID_SJTO_IMPSTO_PRDAL) LOOP
                    V_AVLUO        := R3.AVLUO_CTSTRAL;
                    V_MTRCLA       := R3.MTRCLA_INMBLRIA;
                    V_AREA_TRRNO   := R3.AREA_TRRNO;
                    V_AREA_CNSTRDA := R3.AREA_CNSTRDA;
                    V_ESTRTO       := R3.CDGO_ESTRTO;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'V_ESTRTO: '||V_ESTRTO , 3 );
                END LOOP;

                -- ACTUALIZO AVALUO Y MATRICULA VALORIZACION
                UPDATE SI_I_PREDIOS P
                   SET P.AVLUO_CTSTRAL   = V_AVLUO,
                       P.MTRCLA_INMBLRIA = V_MTRCLA,
                       P.AVLUO_CMRCIAL   = V_AVLUO,
                       P.AREA_TRRNO      = V_AREA_TRRNO,
                       P.AREA_CNSTRDA    = V_AREA_CNSTRDA,
                       P.CDGO_ESTRTO     = V_ESTRTO
                 WHERE P.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                UPDATE SI_I_SUJETOS_IMPUESTO I
                   SET I.ID_SJTO_ESTDO = V_ESTDO_SJTO_PRDIAL
                 WHERE I.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                DELETE FROM SI_I_SUJETOS_RESPONSABLE R
                 WHERE R.ID_SJTO_IMPSTO = R1.ID_SJTO_IMPSTO;

                INSERT INTO SI_I_SUJETOS_RESPONSABLE
                    (ID_SJTO_IMPSTO,
                     CDGO_IDNTFCCION_TPO,
                     IDNTFCCION,
                     PRMER_NMBRE,
                     SGNDO_NMBRE,
                     PRMER_APLLDO,
                     SGNDO_APLLDO,
                     PRNCPAL_S_N,
                     CDGO_TPO_RSPNSBLE,
                     PRCNTJE_PRTCPCION,
                     ORGEN_DCMNTO,
                     ID_PAIS_NTFCCION,
                     ID_DPRTMNTO_NTFCCION,
                     ID_MNCPIO_NTFCCION,
                     DRCCION_NTFCCION,
                     EMAIL,
                     TLFNO,
                     CLLAR,
                     ACTVO,
                     ID_TRCRO,
                     INDCDOR_MGRDO)
                SELECT R1.ID_SJTO_IMPSTO,
                       R.CDGO_IDNTFCCION_TPO,
                       R.IDNTFCCION,
                       R.PRMER_NMBRE,
                       R.SGNDO_NMBRE,
                       R.PRMER_APLLDO,
                       R.SGNDO_APLLDO,
                       R.PRNCPAL_S_N,
                       R.CDGO_TPO_RSPNSBLE,
                       R.PRCNTJE_PRTCPCION,
                       R.ORGEN_DCMNTO,
                       R.ID_PAIS_NTFCCION,
                       R.ID_DPRTMNTO_NTFCCION,
                       R.ID_MNCPIO_NTFCCION,
                       R.DRCCION_NTFCCION,
                       R.EMAIL,
                       R.TLFNO,
                       R.CLLAR,
                       R.ACTVO,
                       R.ID_TRCRO,
                       R.INDCDOR_MGRDO
                  FROM SI_I_SUJETOS_RESPONSABLE R
                 WHERE R.ID_SJTO_IMPSTO = V_ID_SJTO_IMPSTO_PRDAL;

                    COMMIT;
           EXCEPTION
               WHEN OTHERS THEN
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Error en la actualización e inserción: ' || SQLERRM, 3);
                ROLLBACK;
             END;
       --  END;



        END LOOP;

       begin
            INSERT INTO SI_I_PREDIO_VALORIZACION_TRAZA (
                                                        ID_USRIO,
                                                        CDGO_CLNTE,
                                                        OBSRVCION,
                                                        FCHA_GSTION,
                                                        CDGO_PRCSO,
                                                        RFRNCIA_CTSTRAL,
                                                        RSLCION_IGAC) 
                                                    VALUES 
                                                        (p_id_usuario,
                                                        p_cdgo_clnte,
                                                        'Actualizacion Masiva Exitosa',
                                                        SYSDATE,
                                                        'AM', 
                                                        p_rfrncia_ctstral,
                                                        NULL);   
        --COMMIT; 
        EXCEPTION
            WHEN OTHERS THEN
                o_cdgo_rspsta := 70;
                o_mnsje_rspsta := 'Error al insertar traza para referencia: ' || p_rfrncia_ctstral ||' - '||SQLERRM;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
        END;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null , v_nmbre_up, v_nvel , 'Sujeto de Valorización modificado exitosamente' , 3 );        

        IF p_rfrncia_ctstral is null then 

            select email 
            into v_correo    
            from    v_sg_g_usuarios
            where   id_usrio = p_id_usuario;


            begin
                select  a.vlor into v_from
                    from    ma_d_envios_mdio_cnfgrcn_pr a
                    join    ma_d_envios_medio_cnfgrcion b on a.id_envio_mdio_cnfgrcion = b.id_envio_mdio_cnfgrcion
                    where   b.cdgo_clnte = p_cdgo_clnte
                    and     b.cdgo_envio_mdio = 'EML'
                    and     a.prmtro = 'SMTP_USRNME' ;
            exception
                when no_data_found then
                o_cdgo_rspsta := 5;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'No hay correo configurado para el envío ', 1);  

            end;

            --insert into muerto2(n_001,v_001,t_001) values(111,'1.select email into v_correo=>'||v_correo,systimestamp);commit;
            if v_correo is not null then
                val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
                apex_util.set_security_group_id(p_security_group_id => val);



                apex_mail.send( p_to        => v_correo,
                                p_from      => v_from,
                                p_subj      => 'Asunto: Actualizacion Masiva Valorizacion',
                                p_body => ' Estimado usuario,<br>La Actualizacion Masiva ha terminado correctamente .<br><br>',
                                p_body_html => 'Estimado usuario,<br>La Actualizacion Masiva ha terminado correctamente .<br><br><br>'
                              );

            --APEX_MAIL.PUSH_QUEUE;                 
            else
                o_cdgo_rspsta := 10;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'No hay correo parametrizado para enviar Notificación del proceso ', 1);             
            end if;

        end if;

    EXCEPTION
        WHEN OTHERS THEN
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error en la ejecución del procedimiento: ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up, p_nvel_log => v_nvel, p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3);

    END PRC_ACTLZA_PRDIOS_VAL_MASIVO;




END PKG_GI_PREDIO_VALORIZACION;

/
