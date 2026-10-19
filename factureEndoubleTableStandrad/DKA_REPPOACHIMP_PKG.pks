CREATE OR REPLACE PACKAGE DKA_REPAPFRSIMP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPAPFRSIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 15/03/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise AP fournisseurs Import                       -
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

    /*=====================================================================================*/
    /* PROCEDURE NAME : main
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création des fournisseurs
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE MAIN(p_errbuf                 IN OUT VARCHAR2,
                   p_retcode                IN OUT NUMBER,
                    p_chargement_f          VARCHAR2,
                    p_chargement_oi         VARCHAR2,
                    p_lancement_prog_stand  VARCHAR2,
                    p_creation_banque       VARCHAR2,
                    p_creation_lien_factor  VARCHAR2
                   );

                       /*
    *************************************************************************
    * PROCEDURE NAME : update_parent_vendor
    *
    * DESCRIPTION
    *  Procédure de Mise à jour de la société mère sur fournisseurs
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE update_parent_vendor (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        );
        
END DKA_REPAPFRSIMP_PKG;
/
SHOW ERRORS PACKAGE DKA_REPAPFRSIMP_PKG;
EXIT