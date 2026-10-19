CREATE OR REPLACE PACKAGE dka_spasinistre_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPASINISTRE_PKG
-- DESCRIPTION       : DKA_SPASINISTRE_PKG package spec :CCA sur sinistre hors automobile
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
--  04/04/2004 GL  Calcul des CCA sur sinistres "hors automobile" et des extournes associées
--                 Gestion de la table spécifique DKA_SPASINISTRE_TMP
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
    --            pv_period_name  Entrée


    --  VALEUR RETOURNEE :pd_to_date, pn_group_id, pv_errbuf, pn_retcode

------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_period_name   IN       VARCHAR2,
        pd_from_date     OUT      DATE,
        pd_to_date       OUT      DATE,
        pn_group_id      OUT      NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pn_retcode       OUT      NUMBER
    );


-------------------------------------------------------------------------------------
  --  Nom           : clear_spasinistre_tmp
  --  Description   : purger la Table de Travail dka_spasinistre_tmp
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :pv_errbuf, pn_result

------------------------------------------------------------------------------------
    PROCEDURE clear_spasinistre_tmp (
        pv_errbuf   OUT   VARCHAR2,
        pn_result   OUT   NUMBER
    );


----------------------------------------------------------------------------------------
  --  Nom           : get_sum_charges
  --  Description   : calculer la somme des charges sur le projet passé en paramètre
  --
  --  PARAMETRES :
  --            pn_project_id, pv_line_type, pd_to_date
  --
  --  VALEUR RETOURNEE :vn_cost_amount

----------------------------------------------------------------------------------------
    FUNCTION get_sum_charges (
        pn_task_id   IN   NUMBER,
        pv_line_type    IN   VARCHAR2,
        pd_from_date    IN   DATE,
        pd_to_date      IN   DATE
    )
        RETURN NUMBER;


------------------------------------------------------------------------------------
  --  Nom           : process_active_projects
  --  Description   : traiter les projects de type 'SINISTRE ASSURE' en statu 'Actif'.
  --
  --  PARAMETRES    :
  --            pd_to_date   Entrée
  --            pn_group_id  Entrée
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : pv_errbuf , pn_result
------------------------------------------------------------------------------------
    PROCEDURE process_active_tasks (
        pd_from_date  IN       DATE,
        pd_to_date    IN       DATE,
        pn_group_id   IN       NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );



-------------------------------------------------------------------------------------
  --  Nom           : create_output
  --  Description   : Lister la table de travail dka_spasinistre_tmp.
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
--  VALEUR RETOURNEE : pv_errbuf , pn_result

----------------------------------------------------------------------------------------
    PROCEDURE gl_open_interface (
        pn_group_id   IN       NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_result     OUT      NUMBER
    );


-------------------------------------------------------------------------------------
  --  Nom           : MAIN
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --        pv_errbuf                   Entrée/Sortie
  --        pn_retcode                  Sortie
  --        pv_period_name          Entrée
  --  VALEUR RETOURNEE :pv_errbuf , pn_result

--------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pv_period_name   IN       VARCHAR2
    );

-------------------------------------------------------------------------------------
 --  Auteur        : GL
 --  Nom           : REVERSE
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --        pv_period_name          Entrée
 --        pv_errbuf                   Entrée/Sortie
 --        pn_retcode                  Sortie
 --
 --  VALEUR RETOURNEE :pv_errbuf , pn_result

------------------------------------------------------------------------------------

PROCEDURE reverse (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pn_group_id      IN       NUMBER
    );

-------------------------------------------------------------------------------------
 --  Auteur        : GL
 --  Nom           : MAIN_REVERSE
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --        pv_period_name          Entrée
 --        pv_errbuf                   Entrée/Sortie
 --        pn_retcode                  Sortie
 --
 --  VALEUR RETOURNEE :pv_errbuf , pn_result

------------------------------------------------------------------------------------

PROCEDURE main_extourne (
            pv_errbuf        IN OUT   VARCHAR2,
            pn_retcode       OUT      NUMBER
        ) ;

END dka_spasinistre_pkg;
/
SHOW ERRORS
EXIT;
