--------------------------------------------------------
--  DDL for Package PKG_GI_PREDIO_VALORIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_PREDIO_VALORIZACION" AS 

    PROCEDURE PRC_CREA_PRDIO_VAL_PUNTUAL (
                                            p_cdgo_clnte        IN    NUMBER,
                                            p_id_usuario        IN    NUMBER,
                                            p_rfrncia_ctstral   IN    VARCHAR2,
                                            o_cdgo_rspsta       OUT   NUMBER,
                                            o_mnsje_rspsta      OUT   VARCHAR2
                                        ) ;

    procedure PRC_ACTLZA_PRDIOS_VAL (
                                        p_cdgo_clnte       IN NUMBER,
                                        p_id_usuario       IN NUMBER,
                                        p_rfrncia_ctstral  IN VARCHAR2,
                                        o_cdgo_rspsta      OUT NUMBER,
                                        o_mnsje_rspsta     OUT VARCHAR2
                                    );

    procedure PRC_CREA_PRDIO_VAL(   P_RSLCION_IGAC VARCHAR2,
                                    p_cdgo_clnte        IN    NUMBER,
                                    p_id_usuario        IN    NUMBER,
                                    o_cdgo_rspsta       OUT   NUMBER,
                                    o_mnsje_rspsta      OUT   VARCHAR2
                                );


    PROCEDURE PRC_CREA_PRDIO_VAL_ARCHIVO ( p_cdgo_clnte      IN NUMBER,
                                           p_id_usuario      IN NUMBER,
                                           p_id_session      IN NUMBER,
                                           o_cdgo_rspsta     OUT NUMBER,
                                           o_mnsje_rspsta    OUT VARCHAR2                                    
                                          ) ;

    procedure PRC_ACTLZA_PRDIOS_VAL_MASIVO (
                                        p_cdgo_clnte       IN NUMBER,
                                        p_id_usuario       IN NUMBER,
                                        p_rfrncia_ctstral  IN VARCHAR2

                                    );

END PKG_GI_PREDIO_VALORIZACION;


/
