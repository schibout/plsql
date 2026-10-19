CREATE OR REPLACE PACKAGE DKA_FUSION_PA_PKG AS
------------------------------------------------------------------------------------
-- $Id: DKA_FUSION_PA_PKG.pks
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_FUSION_PA_PKG.pks
-- DESCRIPTION       : DKA_FUSION_PA_PKG package créé pour la fusion PA
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 15/07/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------

------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT  ==>:  DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_SAUVEGARDE
  --  Description   :  procédure pour la sauvegarde et la purge des tables de sauvegarde
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_SAUVEGARDE_ET01 ;

------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_INTERF_ET01
  --  Description   :  procédure pour la sauvegarde et la purge des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_INTERF_ET01 ;

  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET01
  --  Description   : bilan du traitement DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET01 ;

  ------------------------------------------------------------------------------------
  --  Nom           : MAIN_SAUV_PURGE
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_SAUV_PURGE (
        PV_ERRBUF    OUT NOCOPY VARCHAR2,
        PN_RETCODE   OUT NOCOPY NUMBER
    );
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> traitement  :  « DKA : Fusion PA ¿ Etape 02: Suffixage des Projets et Taches
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*------------------------------------------------------------------------------------
  --  Nom           : fusion_pa_suffix_z
  --  Description   :  procédure de mise à jour des noms et numéros des projets et tâcches
  ------------------------------------------------------------------------------------

    PROCEDURE FUSION_PA_SUFFIX_Z (
        P_CODE_UO_ABSORBE      IN VARCHAR2,
        P_CODE_UO_ABSORBANTE   IN VARCHAR2,
        P_MODE_SIMULATION      IN VARCHAR2
    ) ;   */
  ------------------------------------------------------------------------------------
  --  Nom           : fusion_pa_suffix_z
  --  Description   :  procédure de mise à jour des noms et numéros des projets et tâches
  --
  ------------------------------------------------------------------------------------

    PROCEDURE FUSION_PA_SUFFIX_Z_TRANS (
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
  ------------------------------------------------------------------------------------
  --  Nom           : main_suffix_projet
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Etape 02: Suffixage des Projets et Taches
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE main_suffix_projet (
        PV_ERRBUF              OUT NOCOPY VARCHAR2,
        PN_RETCODE             OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Etape 03: Récupération de l¿historique
--                                    de rattachement des projets aux centres finances
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROCEDURE RATTACHEMENT_PROJET_FINANCE (
   P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
);
  ------------------------------------------------------------------------------------
  --  Nom           : MAIN_REC_HIST
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 03: Récupération de l'historique de rattachement des projets aux centres finances
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

PROCEDURE MAIN_REC_HIST (
       PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    );
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Etape 07 : Restauration des tables d¿interface
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_SAUVEGARDE_ET07
  --  Description   :  procédure pour la sauvegarde des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_SAUVEGARDE_ET07 (P_TRANSCODIFICATION varchar2,p_uo_absorbee number);
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_INTERF_ET07
  --  Description   :  procédure pour la sauvegarde et la purge des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_INTERF_ET07 (P_TRANSCODIFICATION varchar2,p_uo_absorbee number);
  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET07
  --  Description   : bilan du traitement DKA : Fusion PA ¿ Etape 07 : Restauration des tables d¿interface
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET07 ;
  ------------------------------------------------------------------------------------
  --  Nom           : main_rest_TAB_INT
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Etape 07 : Restauration des tables d¿interface
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE main_rest_TAB_INT (
        PV_ERRBUF    OUT NOCOPY VARCHAR2,
        PN_RETCODE   OUT NOCOPY NUMBER,
		P_TRANSCODIFICATION varchar2,
		p_uo_absorbee number);

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> DKA ¿ Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : FERMETURE_PROJET_TACHE
   --  Description   :  procédure pour mise à jour des projets et des tâches
  --
  ------------------------------------------------------------------------------------

    PROCEDURE FERMETURE_PROJET_TACHE (
        P_TRANSCODIFICATION   VARCHAR2,
        P_DATE_FIN_PROJET     VARCHAR2,
        P_DATE_FIN_TACHE      VARCHAR2,
		P_UO_ABSORBEE         NUMBER
    );


  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET08
  --  Description   : bilan du traitement DKA ¿ Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET08 ;
  ------------------------------------------------------------------------------------
  --  Nom           : main_ferm_projet
  --  Description   : point d'entrée du traitement  DKA - Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE main_ferm_projet (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   VARCHAR2,
        P_DATE_FIN_PROJET     VARCHAR2,
        P_DATE_FIN_TACHE      VARCHAR2,
        P_UO_ABSORBEE         NUMBER
    );

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Correction des organisations des projets
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  --  Nom           : CORREECTION_ORG_PROJET
  --  Description   :  procédure de mise à jour des des projets
  ------------------------------------------------------------------------------------

   PROCEDURE CORRECTION_ORG_PROJET (
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    ) ;

	 ------------------------------------------------------------------------------------
  --  Nom           : CORREECTION_ORG_PROJET
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Correction des organisations des projets
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_CORREC_PROJET (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA  - Etape 04 : Reprise des indicateurs TEC et PCA
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : REPRISE_INDICATEUR
  --  Description   :  procédure de mise à jour des des projets
  ------------------------------------------------------------------------------------

   PROCEDURE REPRISE_INDICATEUR (
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    ) ;

	 ------------------------------------------------------------------------------------
  --  Nom           : MAIN_REPRISE_INDIC
  --  Description   : point d'entrée du traitement DKA : Fusion PA  - Etape 04 : Reprise des indicateurs TEC et PCA
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_REPRISE_INDIC (
        PV_ERRBUF              OUT NOCOPY VARCHAR2,
        PN_RETCODE             OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
    		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA - Etape 05 : Mise à jour des projets et tâches pour les TEC et PCA
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : MAJ_PR_TEC_PCA
  --  Description   :  procédure de mise à jour des des projets  et tâches pour TEC et PCA
  ------------------------------------------------------------------------------------

   PROCEDURE MAJ_PR_TEC_PCA (
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
     ------------------------------------------------------------------------------------
  --  Nom           : MAIN_MAJ_PR_TEC_PCA
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 05 : Mise à jour des projets et tâches pour les TEC et PCA
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_MAJ_PR_TEC_PCA (
        PV_ERRBUF              OUT NOCOPY VARCHAR2,
        PN_RETCODE             OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
    	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA - Etape 06 : Mise à jour des projets et tâches pour les CCA sur sinistres
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : MAJ_PR_CCA
  --  Description   :  procédure de mise à jour des des projets  et tâches pour CCA
  ------------------------------------------------------------------------------------

   PROCEDURE MAJ_PR_CCA (
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
     ------------------------------------------------------------------------------------
  --  Nom           : MAIN_MAJ_PR_CCA
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 06 : Mise à jour des projets et tâches pour les CCA sur sinistres
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_MAJ_PR_CCA (
        PV_ERRBUF              OUT NOCOPY VARCHAR2,
        PN_RETCODE             OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION    IN VARCHAR2,
        P_CODE_UO_ABSORBE      IN NUMBER,
        P_MODE_SIMULATION      IN VARCHAR2
    );
END DKA_FUSION_PA_PKG;
/
SHOW ERRORS;
EXIT;
