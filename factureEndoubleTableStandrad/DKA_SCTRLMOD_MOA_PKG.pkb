CREATE OR REPLACE PACKAGE DKA_IPOFRS_IVALUA_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_IPOFRS_IVALUA_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : S.HAHIOUI / SOCIETE : CAPGEMINI                           -
    -- DATE    : 10/05/20                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Import fournisseurs pour iValua                       -
    -- FONCTION   : SFD261                                               -
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
                   p_recyclage              IN VARCHAR2
                   );

   
        
END DKA_IPOFRS_IVALUA_PKG;
/
SHOW ERRORS PACKAGE DKA_IPOFRS_IVALUA_PKG;
EXIT