CREATE OR REPLACE PACKAGE DKA_SPATRAVCOURS_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPATRAVCOURS_PKG
-- DESCRIPTION       : DKA_SPATRAVCOURS_PKG package spec:Calcul des TEC/PCA et leur Annulation
---
--- AUTEUR           :Hassan CHRAOUI (CGEY)
--- DATE DE CREATION : 08/10/2001
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 07/12/2001 HCH Mise aux normes
--- 03/09/2003 XD  process_projects : Création
--- 06/04/2004 FL  Refonte des TEC et PCA, ajout des procédures main_reverse et reverse pour le calcul des extournes
--- 02/08/2005 TB  Refonte des TEC et PCA, suppression des process non utilisés
--- 23/11/2005 EB  MAJ_CALCULE : création de la procédure
---                MAJ_FACTURE : ancienne procedure  MAJ ATTRIBUTE10 modifiée
--- 11/05/2016 RGH Migration R12

--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-------------------------------------------------------------------------------------
--  Nom           : init
--  Description   : initialisation des variables globales du package.

    --  PARAMETRES    :
    --                    pv_period_name  Entrée


    --  VALEUR RETOURNEE :pd_to_date,pn_group_id, pv_errbuf, pn_retcode

------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_period_name   IN       VARCHAR2,
        pd_to_date       OUT      DATE,
        pd_from_date     OUT      DATE,
        pn_group_id      OUT      NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pn_retcode       OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : clear_spatravcours_tmp
--  Description   : purger la table de travail dka_spatravcours_tmp
--
--  PARAMETRES    :
--    pv_errbuf, pn_result

    --  VALEUR RETOURNEE :

------------------------------------------------------------------------------------
    PROCEDURE clear_spatravcours_tmp (
        pv_errbuf   OUT   VARCHAR2,
        pn_result   OUT   NUMBER
    );
-------------------------------------------------------------------------------------
--  Nom           : maj_calcule
--  Description   : mettre à jour le flag du projet calcule
--
--  PARAMETRES    :
--    pd_project_id  Entrée
--       pv_errbuf, pn_result  Sortie

    --  VALEUR RETOURNEE :

------------------------------------------------------------------------------------
   PROCEDURE maj_calcule (
        pv_project_id IN       VARCHAR2,
        pv_task_id    IN       VARCHAR2,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );
-------------------------------------------------------------------------------------
--  Nom           : maj_facture
--  Description   : mettre à jour le flag des projets facturés
--
--  PARAMETRES    :
--    pd_to_date, pn_group_id  Entrée
--       pv_errbuf, pn_result  Sortie

    --  VALEUR RETOURNEE :

------------------------------------------------------------------------------------
   PROCEDURE maj_facture (
        pd_to_date    IN       DATE,
        pd_from_date  IN       DATE,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : process_projects
--  Description   : Traitement principal des projets
--
--  PARAMETRES    :
--              pd_to_date   Entrée
--              pn_group_id  Entrée
--
--  VALEUR RETOURNEE :pv_errbuf , pn_result

------------------------------------------------------------------------------------
    PROCEDURE process_projects (
        pd_to_date    IN       DATE,
        pd_from_date  IN       DATE,
        pn_group_id   IN       NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : create_output
--  Description   : Lister la table de travail dka_spatravcours_tmp.
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :pv_errbuf , pn_result

------------------------------------------------------------------------------------
    PROCEDURE create_output (
        pv_errbuf   OUT   VARCHAR2,
        pn_result   OUT   NUMBER
    );


----------------------------------------------------------------------------------------
--  Nom           : gl_open_interface
-- Description   : Alimente GL_INTERFACE_CONTROL et lance l'Easylink.
--
--  PARAMETRES :
--              pn_group_id     Entrée
--  VALEUR RETOURNEE :

----------------------------------------------------------------------------------------
    PROCEDURE gl_open_interface (
        pn_group_id   IN       NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--                  du traitement DKA : Calcul des TEC et PCA
--  PARAMETRES :
--             pv_errbuf                       Entrée/Sortie
--
--             pn_retcode                      Sortie
-- valeurs possibles 0=normal, 1=warning, 2= erreur
------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pv_period_name   IN       VARCHAR2
    );
-------------------------------------------------------------------------------------
--  Nom           : reverse
--  Description   : Traitement principal des extournes
--
--  PARAMETRES    :
--
--              pn_group_id  Entrée
--              pn_retcode   Entrée
--              pn_errbuf    Entrée/Sortie
--  VALEUR RETOURNEE :pv_errbuf , pn_result
--  Valeurs possibles de pn_result : 0=normal, 1=warning, 2=erreur
------------------------------------------------------------------------------------
    PROCEDURE reverse (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pn_group_id      IN       NUMBER
    );
-------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--                  du traitement DKA : Extourne des TEC et PCA
--  PARAMETRES :
--             pv_errbuf                       Entrée/Sortie
--
--             pn_retcode                      Sortie
-- valeurs possibles 0=normal, 1=warning, 2= erreur
------------------------------------------------------------------------------------
    PROCEDURE main_reverse (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER
    );

END DKA_SPATRAVCOURS_PKG;

/
SHOW ERROR
EXIT;