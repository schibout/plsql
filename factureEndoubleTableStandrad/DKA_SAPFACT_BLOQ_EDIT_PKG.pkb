/* Formatted on 02/11/2002 11:42 (Formatter Plus v4.5.2) */
SET VERIFY OFF;
DEFINE package_name = "DKA_SPAAUTOACCOUNTING_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS

--------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPAAUTOACCOUNTING_PKG.pkb
-- DESCRIPTION       : DKA_SPAAUTOACCOUNTING_PKG package body :
---
--- AUTEUR           : Maxime EGOT (CAPGEMINI)
--- DATE DE CREATION : 06/07/2016
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  05/07/2016 MEG Creation
--------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : initialisation des parametres
--
--  PARAMETRES    :
--    pv_errbuf             Sortie
--    pn_retcode            Sortie
--  VALEUR RETOURNEE :
--     Description       : Initialisation
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );

    PRAGMA RESTRICT_REFERENCES (init, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_ORG_ID_F
--  Description   : Fonction utilisee pour retourner l'organisation (org_id) en fonction de l'identifiant du projet (project_id)
--
--  PARAMETRES :
--      pn_project_id                   Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne l'identifiant de la societe (org_id)en fonction de l'identifiant du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_org_id_f (
        pn_project_id   IN   NUMBER
    )
        RETURN NUMBER;

    PRAGMA RESTRICT_REFERENCES (get_org_id_f, WNDS);


---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_ORGANISATION_F
--  Description   : Fonction utilisee pour retourner l'organisation en fonction de l'identifiant du projet (project_id)
--
--  PARAMETRES :
--      pn_project_id                   Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne l'organisation du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_organisation_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_organisation_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_TYPE_F
--  Description   : Fonction utilisee pour retourner le type du projet en fonction de l'identifiant du projet
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       : le type de projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_type_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_project_type_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_CODE_F
--  Description   : Fonction utilisee pour retourner le numero du projet en fonction de l'identifiant du projet
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       : le type de projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_code_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_project_code_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PA_CODE_EXPRESS_F
--  Description   : Fonction utilisee pour retourner une valeur dans le jeu de codes express d'affectation 
--                  automatique passee en parametre
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       : le type de projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_pa_code_express_f (
        pv_nom_jeu        IN   VARCHAR2,
        pv_valeur_interm  IN   VARCHAR2
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_pa_code_express_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_ASSET_CATEGORY_F
--  Description   : Fonction qui retourne la categorie d'immobilisation d'une tâche
--
--  PARAMETRES :
--      pn_task_id                  Entree
--  VALEUR RETOURNEE :
--     Description       : Retourne la categorie de l'immobilisation
--             de depense.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_asset_category_f (
        pn_task_id            IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_task_asset_category_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_BACK_BILLING_PROJECT_F
--  Description   : Fonction utilisee pour retourner l'identifiant du projet à refacturer à partir de l'idendifianr
--          de l'element de depense.
--
--  PARAMETRES :
--      pn_expenditure_item_id           Entree
--  VALEUR RETOURNEE :
--     Description       :  Le project_id   (attribute1 de la table pa_expenditure_items_all)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_back_billing_project_f (
        pn_expenditure_item_id   IN   NUMBER
    )
        RETURN NUMBER;

    PRAGMA RESTRICT_REFERENCES (get_back_billing_project_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_DEST_PROJET_F
--  Description   : Fonction utilisee pour retourner la destination du projet a refacturer
--
--  PARAMETRES :
--      pn_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       : Valeur (code de classe) de la classification (categorie) "DESTINATION" du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_dest_projet_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_dest_projet_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_AFFAIRE_PROJET_F
--  Description   : Fonction utilisee pour retourner la destination du projet a refacturer
--
--  PARAMETRES :
--      pn_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       : Valeur (code de classe) de la classification (categorie) "DESTINATION" du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_affaire_projet_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_affaire_projet_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_TEMPLATE_F
--  Description   : Fonction utilisee pour retourner le modele de la tache
--
--  PARAMETRES :
--      pn_task_id           Entree
--  VALEUR RETOURNEE :
--     Description       : Deux premiers caracteres du numero de la tache
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_template_f (
        pn_task_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_task_template_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_ATTRIBUTE_F
--  Description   : Fonction utilisee pour retourner l'attribut de la tache
--
--  PARAMETRES :
--      pn_task_id           Entree
--  VALEUR RETOURNEE :
--     Description       : Attribute1 de la tache
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_attribute_f (
        pn_task_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_task_attribute_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_INTERCO_FOURN_F
--  Description   : Fonction utilisee pour retourner le segment5 du compte fournisseur du site fournisseur
--
--  PARAMETRES :
--      pn_vendor_id           Entree
--  VALEUR RETOURNEE :
--     Description       : Segment5
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_interco_fourn_f (
        pn_vendor_site_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_interco_fourn_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_VENDOR_SITE_ID_F
--  Description   : Fonction utilisee pour retourner l'identifiant du site fournisseur de la facture à partir de l'identifiant
--          de l'element de depense
--
--  PARAMETRES :
--  pn_expenditure_item_id           Entree
-- VALEUR RETOURNEE :
--     Description       : Identifiant du fournisseur
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_vendor_site_id_f (
        pn_expenditure_item_id   IN   NUMBER
    )
        RETURN NUMBER;

    PRAGMA RESTRICT_REFERENCES (get_vendor_site_id_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_ID_F
--  Description   : Fonction utilisee pour retourner l'identifiant du projet de la facture a partir de l'identifiant
--          de l'element de depense.
--
--  PARAMETRES :
--  pn_expenditure_item_id           Entree
-- VALEUR RETOURNEE :
--     Description       : Identifiant du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_id_f (
        pn_expenditure_item_id    IN   NUMBER
    )
        RETURN NUMBER;

    PRAGMA RESTRICT_REFERENCES (get_project_id_f, WNDS); 

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CENTREFI
--  Description   : Fonction utilisée pour retourner le segment6 centre finance
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       :  le centre finance (segment6)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION centrefi (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (centrefi, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : AFFAIRE
--  Description   : Fonction utilisée pour retourner le segment7 affaire
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       :  affaire (segment7)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION affaire (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (affaire, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : FLUX
--  Description   : Fonction utilisée pour retourner le segment9 flux
--
--  PARAMETRES :
--      pv_project_id           Entree
--  VALEUR RETOURNEE :
--     Description       :  flux (segment9)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION flux (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (flux, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : SOCIETE_PROJET
--  Description   : Fonction utilisee pour le segment1
--
--  PARAMETRES :
--      pn_project_id                   Entree
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment1 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION societe_projet (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (societe_projet, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : PROJETFI
--  Description   : Fonction utilisee pour le segment8
--
--  PARAMETRES :
--      pn_project_id                   Entree
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment8 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION projetfi (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (projetfi, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : UO_PROJET
--  Description   : Fonction utilisee pour le segment2
--
--  PARAMETRES :
--      pn_project_id                   Entree
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment2 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION uo_projet (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (uo_projet, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CODE_INTERCO
--  Description   : Fonction utilisee pour le segment5
--
--  PARAMETRES :
--      pn_expenditure_item_id          Entree
--      pn_project_id                   Entree
--      pn_id_site_fourn                Entree       
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment5 de la cle comptable en fonction de l'identifiant de l'element de depense
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION code_interco (
        pn_expenditure_item_id IN NUMBER DEFAULT NULL,
        pn_project_id          IN NUMBER DEFAULT NULL,
        pn_id_site_fourn       IN NUMBER DEFAULT NULL
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (code_interco, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_LOCAL_COUTS
--  Description   : Fonction utilisee pour retourner le compte local en fonction de l'identifiant du projet, du type de
--                  depense et de l'identifiant de la tâche
--  PARAMETRES :
--      pn_project_id        Entree
--      pv_expenditure_type  Entree
--      task_id              Entree
--  VALEUR RETOURNEE :
--     Description       : le compte local
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION cpt_local_couts (
        pn_project_id          IN   NUMBER,
        pv_expenditure_type    IN   VARCHAR2,
        pn_task_id             IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (cpt_local_couts, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_GROUPE_COUTS
--  Description   : Fonction utilisee pour la règle CPT_GROUPE_COUTS
--
--  PARAMETRES :
--      pn_project_id                   Entree
--      pv_expenditure_type             Entree
--      pn_expenditure_item_id          Entree
--      pn_task_id                      Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la valeur du segment4 de la cle comptable en fonction de l'identifiant du projet,
--             du type de l'element de depense, de l'identifiant de l'element de depense et de l'identifiant de la tache
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION cpt_groupe_couts (
        pn_project_id            IN   NUMBER,
        pv_expenditure_type      IN   VARCHAR2,
        pn_expenditure_item_id   IN   NUMBER,
        pn_task_id               IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (cpt_groupe_couts, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_GROUPE_PRODUIT
--  Description   : Fonction utilisee pour la règle CPT_GROUPE_PRODUIT
--
--  PARAMETRES :
--      pn_project_id               Entree
--      pv_event_type               Entree
--      pn_task_id                  Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la valeur du segment2 de la cle comptable en fonction de l'identifiant du projet,
--             du type de l'evenement et du numero de l'evenement.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION cpt_groupe_produit (
        pn_project_id   IN   NUMBER,
        pv_event_type   IN   VARCHAR2,
        pn_task_id      IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (cpt_groupe_produit, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_CPT_GROUPE_COUTS_F
--  Description   : Fonction qui retourne le compte groupe a partir de l'identifiant du projet, le type de
--                  de depense, de l'identifiant des depenses et de l'identifiant de la tache
--          du project à refacturer.
--
--  PARAMETRES :
--      pn_project_id               Entree  
--      pv_expenditure_type         Entree  
--      pn_expenditure_item_id      Entree  
--      pn_task_id                  Entree  
--      pn_refac_project_id         Entree 
--
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment4 de la cle comptable.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION run_cpt_groupe_couts_f (
        pn_project_id            IN   NUMBER,
        pv_expenditure_type      IN   VARCHAR2,
        pn_expenditure_item_id   IN   NUMBER DEFAULT NULL,
        pn_task_id               IN   NUMBER,
        pn_refac_project_id      IN   NUMBER DEFAULT NULL
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (run_cpt_groupe_couts_f, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_CPT_GROUPE_PRODUIT_F
--  Description   : Fonction qui retourne le compte groupe à partir de l'identifiant du projet, le type du projet, le type
--          d'evenement et une date.
--
--  PARAMETRES :
--      pn_project_id           Entree
--      pv_project_type         Entree
--      pn_task_id              Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la valeur du segment2 de la cle comptable
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION run_cpt_groupe_produit_f (
        pn_project_id   IN   NUMBER,
        pv_event_type   IN   VARCHAR2,
        pn_task_id      IN   NUMBER
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (run_cpt_groupe_produit_f, WNDS);

END &&package_name; -- Specification du package
/
SHOW ERRORS;

EXIT
