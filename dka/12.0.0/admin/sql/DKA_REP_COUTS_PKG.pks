CREATE OR REPLACE PACKAGE DKA_REP_COUTS_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REP_COUTS_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  :  B.DELATTRE SOCIETE : CAPGEMINI                           -
    -- DATE    : 07/07/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise COUTS Import                       -
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
  /*
  *************************************************************************
  * PROCEDURE NAME : init
  *
  * DESCRIPTION
  * Procédure d'initialisation des variables globales
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
  * pv_errbuf         Retour de message éventuel
  * pn_retcode        Statut du traitement en sortie
  ************************************************************************
  */
  PROCEDURE init(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode IN OUT NUMBER,
                 pv_period  IN VARCHAR2);
	  
 /* *************************************************************************
  * PROCEDURE NAME : Launch_Loader
  *
  * DESCRIPTION
  *  Procédure de lancement du programme de chargement dans la table spécifique
  *
  * PARAMETERS
  * ==========
  * NAME               DESCRIPTION
  * -----------------  ------------------------------------------------------
  * p_directory         Répertoire du fichier
  * p_file_name        Nom du fichier à charger
  * pv_errbuf          Retour de message éventuel
  * pn_retcode         Statut du traitement en sortie
  *
  ************************************************************************
  */
  PROCEDURE Launch_Loader(pv_errbuf  IN OUT VARCHAR2,
                          pn_retcode IN OUT NUMBER,
                          pv_NomFich IN VARCHAR2) ;
  
    -------------------------------------------------------------------------------------
  --  Nom           : INSERT_PA_TRANSAC_INTERFAC_ALL
  --  Description   : Procédure d'insertion dans la table PA_TRANSACTION_INTERFACE_ALL
  --  PARAMETRES    :
  --
  --        pv_errbuf                 Sortie,
  --        pn_retcode                Sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE insert_pa_transac_interfac_all(pv_errbuf  IN OUT VARCHAR2,
                                           pn_retcode IN OUT NUMBER) ;
										   
										   
  /*=========================================================================*/
  /* PROCEDURE NAME :   program_import_couts
  /*
  /* DESCRIPTION  Traitement standard d¿import des fournisseurs
  /*
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /*
  /*
  /*=========================================================================*/
  PROCEDURE program_import_couts(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode IN OUT NUMBER);
/*
  *************************************************************************
  * PROCEDURE NAME : Report_Bilan
  *
  * DESCRIPTION
  *  Procédure de génération du bilan du traitement
  *
  * PARAMETERS
  * ==========
  * NAME                 DESCRIPTION
  .* -------------------- -------------------------------------------------
  * pv_errbuf            Retour de message éventuel
  * pn_retcode           Statut du traitement en sortie
  ************************************************************************
  */
  PROCEDURE Report_Bilan(pv_errbuf IN OUT VARCHAR2, pn_retcode IN OUT NUMBER);
  
  
  
      
 PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
			 pn_retcode IN OUT NUMBER,
			 pv_NomFich IN VARCHAR2,
       pv_chargement_f  IN VARCHAR2,
		   pv_chargement_oi IN VARCHAR2,
       pv_period IN VARCHAR2);
  
  
  
  
  
  
  
  
  
  
  
  
END DKA_REP_COUTS_PKG;
/
SHOW ERRORS PACKAGE DKA_REP_COUTS_PKG;
EXIT
