CREATE OR REPLACE PACKAGE DKA_APFRSEXP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_APFRSEXP_PKG.sql                                    -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 26/05/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : DKA : Export des fournisseurs                        -
    -- FONCTION   : INT001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :     1.1                                    -
    -- PROGRAMME MODIFIE LE :     16/01/2017                             -
    -- PAR                  :     Maxime EGOT                            -
    -- NUM_ANOMALIE         :                                            -
    -- OBJET                :     Evolution EDB38                        -
    --                                                                   -
    ----------------------------------------------------------------------
    
    PROCEDURE Export_journalier(p_errbuff               IN OUT VARCHAR2,
                                p_retcode               IN OUT NUMBER
              );

    PROCEDURE Export_mensuel(p_errbuff               IN OUT VARCHAR2,
                             p_retcode               IN OUT NUMBER,
                             p_site_paiement         IN     VARCHAR2
              );


END DKA_APFRSEXP_PKG;
/
SHOW ERRORS PACKAGE DKA_APFRSEXP_PKG;
EXIT
