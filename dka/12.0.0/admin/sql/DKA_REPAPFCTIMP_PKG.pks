CREATE OR REPLACE PACKAGE DKA_REPAPFCTIMP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPAPFCTIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 18/04/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise AP factures fournisseurs Import               -
    -- FONCTION   : SFD003                                               -
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
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- ---------- --- ---------------------------------------------------
    --  10/07/2017 OBE artf2191277 : Reprise en cours Fournisseur : EDB077 - Reprise des factures bloquées au paiement    
    --- ---------- --- ---------------------------------------------------    
    
    PROCEDURE MAIN(p_errbuf                 IN OUT VARCHAR2,
                   p_retcode                IN OUT NUMBER,
                    p_chargement_f          VARCHAR2,
                    p_chargement_oi         VARCHAR2,
                    p_lancement_prog_stand  VARCHAR2,
                    p_chargement_blocage    VARCHAR2,
                    p_chargement_echeances  VARCHAR2, -- OBE artf2191277
                    p_date                  VARCHAR2
                   );


END DKA_REPAPFCTIMP_PKG;
/
SHOW ERRORS PACKAGE DKA_REPAPFCTIMP_PKG;
EXIT