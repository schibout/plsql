CREATE OR REPLACE PACKAGE DKA_ICODEPROJET_PKG AS
     ----------------------------------------------------------------------
    -- PROGRAM : DKA_ICODEPROJET_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 16/08/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Import des projets dans PA                       -
    -- FONCTION   : INT018                                               -
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
    /* PROCEDURE NAME : centre_finance
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création et modification des centres de finances
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE centre_finance( p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER,
                    p_date_controle VARCHAR2
                    );
    
    
    /*=====================================================================================*/
    /* PROCEDURE NAME : projets
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création 
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/

    PROCEDURE projets( p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER
                    );
   
    
    /*Debut RBE*/
    ----------------------------------------------------------------------------------------
    --  Nom           : UPDATE_PROJECT_CLOSED
    --  Description   : Procédure mettant à jour le status "fermé" du projet
    --
    --  PARAMETRES :
    --    pn_rec                  Entrée
    --    pv_errbuf               Sortie
    --    pn_retcode               Sortie
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal
    --                         2: erreur
    --                         ou le code erreur ORA
    ----------------------------------------------------------------------------------------
    PROCEDURE update_project_closed(pn_project_id IN NUMBER,
                                    pv_errbuf     OUT VARCHAR2,
                                    pn_retcode    OUT NUMBER); 

    ----------------------------------------------------------------------------------------
    --  Nom           : UPDATE_PROJECT_ENCLOSED
    --  Description   : Procédure mettant à jour le status "clôturé" du projet
    --
    --  PARAMETRES :
    --    pn_rec                  Entrée
    --    pv_errbuf               Sortie
    --    pn_retcode               Sortie
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal
    --                         2: erreur
    --                         ou le code erreur ORA
    ----------------------------------------------------------------------------------------
    PROCEDURE update_project_enclosed(pn_project_id IN NUMBER,
                                    pv_errbuf     OUT VARCHAR2,
                                    pn_retcode    OUT NUMBER); 
                                    
    ----------------------------------------------------------------------------------------
    --  Nom           : UPDATE_MONTH_ORG_PROJECT
    --  Description   : Procédure mettant à jour l'organisation mensuelle du projet
    --
    --  PARAMETRES :
    --    pn_rec                  Entrée
    --    pv_errbuf               Sortie
    --    pn_retcode               Sortie
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal
    --                         2: erreur
    --                         ou le code erreur ORA
    ----------------------------------------------------------------------------------------
    PROCEDURE update_month_org_project(pn_project_id      IN NUMBER,
                                       pn_organization_id IN NUMBER,
                                       pd_date_ref        IN DATE,
                                       pv_errbuf          OUT VARCHAR2,
                                       pn_retcode         OUT NUMBER);
  
    ----------------------------------------------------------------------------------------
    --  Nom           : UPDATE_MONTH_ORG_TASK
    --  Description   : Procédure mettant à jour l'organisation mensuelle du projet
    --
    --  PARAMETRES :
    --    pn_rec                  Entrée
    --    pv_errbuf               Sortie
    --    pn_retcode               Sortie
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal
    --                         2: erreur
    --                         ou le code erreur ORA
    ----------------------------------------------------------------------------------------
    PROCEDURE update_month_org_task(pn_project_id      IN NUMBER,
                                    pn_organization_id IN NUMBER,
                                    pd_date_ref        IN DATE,
                                    pv_errbuf          OUT VARCHAR2,
                                    pn_retcode         OUT NUMBER);
  
    --------------------------------------------------------------------------------------
    --  Nom           : UPDATE_PROJECT_STATUS_CLOSED
    --  Description   : Procédure de mise à jour mensuelle des projets
    --
    --  PARAMETRES :
    --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --    pn_retcode                      Sortie                  status du traitement en sortie
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    --
    ----------------------------------------------------------------------------------------
    PROCEDURE update_project_month_status(pv_errbuf  OUT VARCHAR2,
                                          pn_retcode OUT NUMBER);
  
    --------------------------------------------------------------------------------------
    --  Nom           : UPDATE_MONTH_PROJECT
    --  Description   : Procédure de mise à jour mensuelle des projets
    --
    --  PARAMETRES :
    --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --    pn_retcode                      Sortie                  status du traitement en sortie
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    --
    ----------------------------------------------------------------------------------------
    PROCEDURE update_month_project(pv_errbuf  OUT VARCHAR2,
                                   pn_retcode OUT NUMBER);
  
    --------------------------------------------------------------------------------------
    --  Nom           : MAIN2
    --  Description   : Procédure de mise à jour mensuelle des projets
    --
    --  PARAMETRES :
    --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --    pn_retcode                      Sortie                  status du traitement en sortie
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    --
    ----------------------------------------------------------------------------------------
    PROCEDURE main2(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER);

END DKA_ICODEPROJET_PKG;
/
SHOW ERRORS;
EXIT