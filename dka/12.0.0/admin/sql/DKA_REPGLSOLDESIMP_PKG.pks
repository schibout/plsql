CREATE OR REPLACE PACKAGE DKA_REPGLSOLDESIMP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPGLSOLDESIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : J.PELAT / B.DELATTRE SOCIETE : CAPGEMINI                           -
    -- DATE    : 14/04/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise GL SOLDES Import                       -
    -- FONCTION   : SFD001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.0                                 -
    -- PROGRAMME MODIFIE LE :                                            -
    -- PAR                  :                                            -
    -- NUM_ANOMALIE         :                                            -
    -- OBJET                :                                            -
    --                                                                   -
    ----------------------------------------------------------------------
    
    PROCEDURE MAIN( pv_errbuf        IN OUT VARCHAR2,
                    pn_retcode       IN OUT NUMBER,
                    pv_chargement_f  IN VARCHAR2,
                    pv_chargement_oi IN VARCHAR2,
                    pv_lancement_oi  IN VARCHAR2,
                    pv_fichier       IN VARCHAR2
                   );
    --YWA artf2194932 : REP013 - Reprise soldes GL pour les écritures en contrepassation automatique
     PROCEDURE MAIN2( pv_errbuf        IN OUT VARCHAR2,
                    pn_retcode       IN OUT NUMBER,
                    pv_chargement_f  IN VARCHAR2,
                    pv_chargement_oi IN VARCHAR2,
                    pv_lancement_oi  IN VARCHAR2,
                    pv_fichier       IN VARCHAR2
                   );
END DKA_REPGLSOLDESIMP_PKG;
/
SHOW ERRORS PACKAGE DKA_REPGLSOLDESIMP_PKG;
EXIT