CREATE OR REPLACE PACKAGE DKA_REPPAREVENUIMP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPPAREVENUIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : J.PELAT SOCIETE : CAPGEMINI                           -
    -- DATE    : 28/04/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise DES REVENUS Import                       -
    -- FONCTION   : SFD001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.0                                 -
    -- PROGRAMME MODIFIE LE :        20/10/2016                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2014423						-
    -- OBJET                :        Reprise des revenus projets - Pb dans la gestion de la date                                    -                                    -
    --                                                                   -
    ----------------------------------------------------------------------
    
    PROCEDURE MAIN( pv_errbuf        IN OUT VARCHAR2,
                    pn_retcode       IN OUT NUMBER,
                    pv_chargement_f  IN VARCHAR2,
					pv_chargement_oi IN VARCHAR2,
                    pv_period IN VARCHAR2
					
					);


END DKA_REPPAREVENUIMP_PKG;
/
SHOW ERRORS;
EXIT
