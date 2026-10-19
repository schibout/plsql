/*<TOAD_FILE_CHUNK>*/
SET VERIFY OFF;
DEFINE package_name = "DKA_SPAAUTOACCOUNTING_PKG";

CREATE OR REPLACE PACKAGE BODY &&package_name
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
--- 05/07/2016 MEG Creation
--- 06/07/2017 MEG artf2191189 : EDB078 LOT1 - Alimentation code Flux pour investissement
--- 10/10/2017 RBE artf2239573 : EDB086 – Modification SP050 pour détermination du Projet et du Centre Finance sur investissement
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- Constantes
    cv_program_code                 dka_parameters.program_code%TYPE          := '&&package_name - ';
    
    -- Variables Globales
    gv_project_type_refac           pa_project_types_all.project_type%TYPE;
    gv_project_type_fact            pa_project_types_all.project_type%TYPE;
    gv_project_type_invest          pa_project_types_all.project_type%TYPE;
    gv_class_type_aff               pa_class_categories.class_category%TYPE; 
    gv_class_type_dest              pa_class_categories.class_category%TYPE; 
    gv_cpt_gp_cout                  dka_parameters.varchar2_value%TYPE;
    gv_cpt_gp_prod                  dka_parameters.varchar2_value%TYPE;
    
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-----------------------------------------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : Initialisation des variables globales du package
--
--  PARAMETRES    :
--    pv_errbuf
--    pv_retcode
--
--  VALEUR RETOURNEE :
--     Description       : Initialisation des variables globales
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE init(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
      rec_param dka_parameters%ROWTYPE;
    
    BEGIN
      pv_errbuf  := NULL;
      pn_retcode := 0;
      --dka_tools_pkg.put_debug_message ('Lancement des initialisations');
    
      -- Recuperation des variables de la table des parametres DKA_PARAMETERS
    
      -- Recuperation de la variable concernant le type de projet REFAC dans la table DKA_PARAMETERS
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'PROJECT_TYPE_REFAC',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_project_type_refac := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'PROJECT_TYPE_REFAC - ' || pv_errbuf;
        RETURN;
      END IF;

      -- Recuperation de la variable concernant le type de projet Facturable dans la table DKA_PARAMETERS
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'PROJECT_TYPE_FACT',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_project_type_fact := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'PROJECT_TYPE_FACT - ' || pv_errbuf;
        RETURN;
      END IF;

      -- Recuperation de la variable concernant le type de projet Investissement dans la table DKA_PARAMETERS
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'PROJECT_TYPE_INVEST',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_project_type_invest := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'PROJECT_TYPE_INVEST - ' || pv_errbuf;
        RETURN;
      END IF;

      -- Recuperation de la constante CPT_GP_COUT dans la table DKA_PARAMETERS
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'CPT_GP_COUT',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_cpt_gp_cout := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'CPT_GP_COUT - ' || pv_errbuf;
        RETURN;
      END IF;
    
      -- Recuperation de la constante  CPT_GP_PROD dans la table DKA_PARAMETERS
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'CPT_GP_PROD',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_cpt_gp_prod := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'CPT_GP_PROD - ' || pv_errbuf;
        RETURN;
      END IF;
    
      -- Recuperation des variables de la table des parametres
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'CLASSIFICATION_TYPE_AFF',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_class_type_aff := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'CLASSIFICATION_TYPE_AFF - ' || pv_errbuf;
        RETURN;
      END IF;

      -- Recuperation des variables de la table des parametres
      dka_tools_pkg.get_parameter('SPAAUTOACCOUNTING',
                                  'CLASSIFICATION_TYPE_DEST',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      gv_class_type_dest := rec_param.varchar2_value;
    
      IF pn_retcode != 0 THEN
        pv_errbuf := 'CLASSIFICATION_TYPE_DEST - ' || pv_errbuf;
        RETURN;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := cv_program_code || SQLCODE;
        pv_errbuf  := SQLERRM;
    END init;

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
        RETURN NUMBER
    IS
        vn_org_id   NUMBER (15);
    BEGIN
        SELECT ppa.org_id
        INTO   vn_org_id
        FROM   pa_projects_all ppa
        WHERE  ppa.project_id = pn_project_id;

        RETURN vn_org_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_org_id_f;

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
    FUNCTION get_organisation_f(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vn_organisation VARCHAR2(240);

    BEGIN

      SELECT hou.name
        INTO vn_organisation
        FROM pa_projects_all ppa, hr_all_organization_units hou
       where ppa.carrying_out_organization_id = hou.organization_id
         AND ppa.project_id = pn_project_id;

      RETURN vn_organisation;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_organisation_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PA_CODE_EXPRESS_F
--  Description   : Fonction utilisee pour retourner une valeur dans le jeu de codes express d'affectation 
--                  automatique passee en parametre
--
--  PARAMETRES :
--      pv_nom_jeu           Entree
--      pv_valeur_interm     Entree
--
--  VALEUR RETOURNEE :
--     Description       : la valeur dans le jeu de codes express 
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_pa_code_express_f(pv_nom_jeu       IN VARCHAR2,
                                   pv_valeur_interm IN VARCHAR2)
      RETURN VARCHAR2 IS
      vv_valeur_segment VARCHAR2(70);
    BEGIN
    
      SELECT psvl.segment_value
        INTO vv_valeur_segment
        FROM pa_segment_value_lookup_sets psvs,
             pa_segment_value_lookups     psvl
       WHERE psvs.segment_value_lookup_set_id =
             psvl.segment_value_lookup_set_id
         AND psvs.segment_value_lookup_set_name = pv_nom_jeu
         AND psvl.segment_value_lookup = pv_valeur_interm;

      RETURN vv_valeur_segment;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
      
    END get_pa_code_express_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_TYPE_F
--  Description   : Fonction utilisee pour retourner le type du projet en fonction de l'identifiant du projet
--
--  PARAMETRES :
--      pv_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : le type de projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_type_f(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_project_type VARCHAR2(70);
      
    BEGIN
      SELECT ppa.project_type
        INTO vv_project_type
        FROM pa_projects_all ppa
       WHERE ppa.project_id = pn_project_id;
    
      RETURN vv_project_type;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_project_type_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_CODE_F
--  Description   : Fonction utilisee pour retourner le numero du projet en fonction de l'identifiant du projet
--
--  PARAMETRES :
--      pv_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : le type de projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_code_f(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_project_code VARCHAR2(70);
    
    BEGIN
    
      SELECT ppa.segment1
        INTO vv_project_code
        FROM pa_projects_all ppa
       WHERE ppa.project_id = pn_project_id;
    
      RETURN vv_project_code;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_project_code_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_ASSET_CATEGORY_F
--  Description   : Fonction qui retourne la categorie d'immobilisation d'une tâche
--
--  PARAMETRES :
--      pn_task_id                  Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la categorie de l'immobilisation
--             de depense.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_asset_category_f(pn_task_id IN NUMBER) RETURN VARCHAR2 IS
      vv_asset_category_id NUMBER;
      vv_asset_category    VARCHAR2(150);

    BEGIN
      SELECT pt.attribute6
        INTO vv_asset_category_id
        FROM pa_tasks pt
       WHERE pt.task_id = pn_task_id;

      SELECT fc.concatenated_segments
        INTO vv_asset_category
        FROM fa_categories_b_kfv fc
       WHERE fc.category_id = vv_asset_category_id;

      RETURN vv_asset_category;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_task_asset_category_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_BACK_BILLING_PROJECT_F
--  Description   : Fonction utilisee pour retourner l'identifiant du projet a refacturer a partir de l'idendifianr de
--          de l'element de depense.
--
--  PARAMETRES :
--      pn_expenditure_item_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       :  Le project_id   (attribute1 de la table pa_expenditure_items_all)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_back_billing_project_f(pn_expenditure_item_id IN NUMBER)
      RETURN NUMBER IS
      vv_attribute1 VARCHAR2(70);
      
    BEGIN
      SELECT peia.attribute1
        INTO vv_attribute1
        FROM pa_expenditure_items_all peia
       WHERE peia.expenditure_item_id = pn_expenditure_item_id;
    
      RETURN(TO_NUMBER(vv_attribute1));
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_back_billing_project_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_DEST_PROJET_F
--  Description   : Fonction utilisee pour retourner la destination du projet
--
--  PARAMETRES :
--     pn_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : Valeur (code de classe) de la classification (categorie) "DESTINATION" du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_dest_projet_f(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_code_classe VARCHAR2(30);
      vv_errbuf        VARCHAR2(300);
      vn_retcode       NUMBER;
      
    BEGIN
      
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      SELECT ppc.class_code
        INTO vv_code_classe
        FROM PA_PROJECT_CLASSES ppc
       WHERE ppc.project_id = pn_project_id
         AND ppc.class_category = gv_class_type_dest;

      RETURN vv_code_classe;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_dest_projet_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_AFFAIRE_PROJET_F
--  Description   : Fonction utilisee pour retourner l'affaire du projet
--
--  PARAMETRES :
--     pn_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : Valeur (code de classe) de la classification (categorie) "DESTINATION" du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_affaire_projet_f(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_code_classe VARCHAR2(30);
      vv_errbuf        VARCHAR2(300);
      vn_retcode       NUMBER;
      
    BEGIN
    
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      SELECT ppc.class_code
        INTO vv_code_classe
        FROM PA_PROJECT_CLASSES ppc
       WHERE ppc.project_id = pn_project_id
         AND ppc.class_category = gv_class_type_aff;
    
      RETURN vv_code_classe;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_affaire_projet_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_TEMPLATE_F
--  Description   : Fonction utilisee pour retourner le modele de la tache
--
--  PARAMETRES :
--      pn_task_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : Deux premiers caracteres du numero de la tache
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_template_f(pn_task_id IN NUMBER) RETURN VARCHAR2 IS
      vv_task_template VARCHAR2(2);
    
    BEGIN
    
      SELECT substr(pt.task_number, 1, 2)
        INTO vv_task_template
        FROM pa_tasks pt
       WHERE pt.task_id = pn_task_id;
    
      RETURN vv_task_template;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_task_template_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TASK_ATTRIBUTE_F
--  Description   : Fonction utilisee pour retourner l'attribut de la tache
--
--  PARAMETRES :
--      pn_task_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       : Attribute1 de la tache
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_task_attribute_f(pn_task_id IN NUMBER) RETURN VARCHAR2 IS
      vv_attribute1 VARCHAR2(150);
    BEGIN
    
      SELECT pt.attribute1
        INTO vv_attribute1
        FROM pa_tasks pt
       WHERE pt.task_id = pn_task_id;
    
      RETURN vv_attribute1;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_task_attribute_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_VENDOR_STEI_ID_F
--  Description   : Fonction utilisee pour retourner l'identifiant du site fournisseur de la depense à partir de l'identifiant
--          de l'element de depense.
--
--  PARAMETRES :
--  pn_expenditure_item_id       Entree
--
-- VALEUR RETOURNEE :
--     Description       : Identifiant du site fournisseur
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_vendor_site_id_f(pn_expenditure_item_id IN NUMBER)
      RETURN NUMBER IS
      vn_vendor_site_id     NUMBER;
      vn_document_header_id NUMBER;
    
    BEGIN
    
      SELECT peia.document_header_id
        INTO vn_document_header_id
        FROM pa_expenditures_all pea, pa_expenditure_items_all peia
       WHERE peia.expenditure_item_id = pn_expenditure_item_id
         AND pea.expenditure_id = peia.expenditure_id;
    
      SELECT aia.vendor_site_id
        INTO vn_vendor_site_id
        FROM ap_invoices_all aia
       WHERE aia.invoice_id = vn_document_header_id;
    
      RETURN vn_vendor_site_id;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_vendor_site_id_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_ID_F
--  Description   : Fonction utilisee pour retourner l'identifiant du projet de la facture a partir de l'identifiant
--          de l'element de depense.
--
--  PARAMETRES :
--  pn_expenditure_item_id           Entree
--
-- VALEUR RETOURNEE :
--     Description       : Identifiant du projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_project_id_f(pn_expenditure_item_id IN NUMBER)
      RETURN NUMBER IS
      vn_project_id NUMBER(15);
    
    BEGIN
    
      SELECT peia.project_id
        INTO vn_project_id
        FROM pa_expenditure_items_all peia
       WHERE peia.expenditure_item_id = pn_expenditure_item_id;
    
      RETURN vn_project_id;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_project_id_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_INTERCO_FOURN_F
--  Description   : Fonction utilisee pour retourner le segment5 du compte fournisseur du site fournisseur
--
--  PARAMETRES :
--  pn_vendor_id           Entree
--
-- VALEUR RETOURNEE :
--     Description       : segment5
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
  FUNCTION get_interco_fourn_f(pn_vendor_site_id IN NUMBER) RETURN VARCHAR2 IS
    vv_segment5 VARCHAR2(240);
  
  BEGIN
  
    SELECT gcc.segment5
      INTO vv_segment5
      FROM AP_SUPPLIER_SITES_ALL assa, gl_code_combinations gcc
     WHERE assa.accts_pay_code_combination_id = gcc.code_combination_id
       AND assa.vendor_site_id = pn_vendor_site_id;
  
    RETURN vv_segment5;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_interco_fourn_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CENTREFI
--  Description   : Fonction utilisée pour retourner le segment6 centre finance
--
--  PARAMETRES :
--      pv_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       :  le centre finance (segment6)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION centrefi(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_segment6    VARCHAR2(240);
      vv_type_projet VARCHAR2(20);
      vv_errbuf        VARCHAR2(300);
      vn_retcode       NUMBER;
    
    BEGIN

      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
    
      IF vv_type_projet = gv_project_type_invest THEN 
      
        --RETURN '0'; -- RBE EDB086
        vv_segment6 := dka_spaautoaccounting_pkg.get_organisation_f(pn_project_id); -- RBE EDB086
      
      ELSE
      
        -- Recuperation de l'organisation du projet --
        vv_segment6 := dka_spaautoaccounting_pkg.get_organisation_f(pn_project_id);
      
      END IF;
    
      RETURN vv_segment6;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END centrefi;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : AFFAIRE
--  Description   : Fonction utilisée pour retourner le segment7 affaire
--
--  PARAMETRES :
--      pv_project_id           Entree
--
--  VALEUR RETOURNEE :
--     Description       :  affaire (segment7)
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION affaire(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_segment7      VARCHAR2(240);
      --vv_type_projet VARCHAR2(20);
      vv_errbuf        VARCHAR2(300);
      vn_retcode       NUMBER;
    
    BEGIN

      -- Initialisation des variables du package --
      --dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
      
      -- Recherche de l'affaire du projet --
      vv_segment7 := dka_spaautoaccounting_pkg.get_affaire_projet_f(pn_project_id);
    
      RETURN vv_segment7;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END affaire;

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
    FUNCTION flux(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_segment9      VARCHAR2(240);
      vv_type_projet   VARCHAR2(20);
      vv_errbuf        VARCHAR2(300);
      vn_retcode       NUMBER;
    
    BEGIN

      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
      
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
      
      IF vv_type_projet = gv_project_type_invest THEN
      
         RETURN 'F20';
      
      ELSE
      
         RETURN '0';
      
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END flux;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : SOCIETE_PROJET
--  Description   : Fonction utilisee pour le segment1
--
--  PARAMETRES :
--      pn_project_id                   Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment1 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION societe_projet(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_errbuf   VARCHAR2(300);
      vn_retcode  NUMBER;
      vn_org_id   NUMBER;
      vv_segment1 VARCHAR2(240);
    
    BEGIN
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      -- Recuperation de l'identifiant de la societe --
      vn_org_id := dka_spaautoaccounting_pkg.get_org_id_f(pn_project_id);
    
      IF vn_org_id IS NOT NULL THEN
      
        SELECT substr(haou.name, -4)
          INTO vv_segment1
          FROM hr_all_organization_units haou
         WHERE haou.organization_id = vn_org_id;
      
        RETURN vv_segment1;
      
      ELSE
      
        RETURN NULL;
      
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END societe_projet;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : PROJETFI
--  Description   : Fonction utilisee pour le segment1
--
--  PARAMETRES :
--      pn_project_id                   Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment1 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION projetfi(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_errbuf   VARCHAR2(300);
      vn_retcode  NUMBER;
      vv_segment8 VARCHAR2(240);
      vv_type_projet   VARCHAR2(20);
    
    BEGIN
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
      
      IF vv_type_projet = gv_project_type_invest THEN
      
        --RETURN '0'; --RBE EDB086
        vv_segment8 := dka_spaautoaccounting_pkg.get_project_code_f(pn_project_id); --RBE EDB086
      
      ELSE 
      
        vv_segment8 := dka_spaautoaccounting_pkg.get_project_code_f(pn_project_id);
      
      END IF;
      
      RETURN vv_segment8;
      
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END projetfi;


---------------------------------------------------------------------------------------------------------------------
--  Nom           : UO_PROJET
--  Description   : Fonction utilisee pour le segment2
--
--  PARAMETRES :
--      pn_project_id                   Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment2 de la cle comptable en fonction du l'identifiant du projet.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION uo_projet(pn_project_id IN NUMBER) RETURN VARCHAR2 IS
      vv_errbuf   VARCHAR2(300);
      vn_retcode  NUMBER;
      vn_org_id   NUMBER;
      vv_segment2 VARCHAR2(240);
    
    BEGIN
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      -- Recuperation de l'identifiant de la societe --
      vn_org_id := dka_spaautoaccounting_pkg.get_org_id_f(pn_project_id);
    
      IF vn_org_id IS NOT NULL THEN
      
        SELECT substr(haou.name, 1, 3)
          INTO vv_segment2
          FROM hr_all_organization_units haou
         WHERE haou.organization_id = vn_org_id;
      
        RETURN vv_segment2;
      
      ELSE
      
        RETURN NULL;
      
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END uo_projet;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CODE_INTERCO
--  Description   : Fonction utilisee pour le segment5
--
--  PARAMETRES :
--      pn_expenditure_item_id          Entree
--      pn_project_id                   Entree
--      pn_id_site_fourn                Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne le segment5 de la cle comptable en fonction de l'identifiant de l'element de depense
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION code_interco(pn_expenditure_item_id IN NUMBER DEFAULT NULL,
                          pn_project_id IN NUMBER DEFAULT NULL,
                          pn_id_site_fourn IN NUMBER DEFAULT NULL)
      RETURN VARCHAR2 IS
      vv_errbuf         VARCHAR2(300);
      vn_retcode        NUMBER;
      vv_segment5       VARCHAR2(240);
      vn_vendor_site_id NUMBER;
      vn_id_project     NUMBER;
      vv_type_projet    VARCHAR2(20);
    
    BEGIN
    
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
     
      IF pn_id_site_fourn IS NULL AND pn_expenditure_item_id IS NOT NULL THEN
      
        -- Recherche de l'identifiant du fournisseur --
        vn_vendor_site_id := dka_spaautoaccounting_pkg.get_vendor_site_id_f(pn_expenditure_item_id);

      ELSE
      
        vn_vendor_site_id := pn_id_site_fourn;
      
      END IF;
            
      IF pn_project_id IS NULL THEN
      
        -- Recherche de l'identifiant du projet -- 
        vn_id_project := dka_spaautoaccounting_pkg.get_project_id_f(pn_expenditure_item_id);
      
      ELSE
      
        vn_id_project := pn_project_id;
      
      END IF;
      
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(vn_id_project);
    
      IF vv_type_projet = gv_project_type_invest THEN
      
        RETURN '0';
      
      ELSE
      
        vv_segment5 := dka_spaautoaccounting_pkg.get_interco_fourn_f(vn_vendor_site_id);
      
      END IF;
    
      RETURN vv_segment5;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END code_interco;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_CPT_GROUPE_COUTS_F
--  Description   : Fonction qui retourne le compte groupe a partir de l'identifiant du projet, le type de
--                  de depense, de l'identifiant des depenses et de l'identifiant de la tache
--          du project a refacturer.
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
    FUNCTION run_cpt_groupe_couts_f(pn_project_id          IN NUMBER,
                                    pv_expenditure_type    IN VARCHAR2,
                                    pn_expenditure_item_id IN NUMBER DEFAULT NULL,
                                    pn_task_id             IN NUMBER,
                                    pn_refac_project_id    IN NUMBER DEFAULT NULL)
      RETURN VARCHAR2 IS
      vv_errbuf                   VARCHAR2(300);
      vn_retcode                  NUMBER;
      vv_type_projet              VARCHAR2(20);
      vv_segment4                 VARCHAR2(240);
      vv_cat_immo_tache           VARCHAR2(150);
      vn_refac_proj_id            NUMBER(15);
      vv_dest_refac_proj          VARCHAR2(30);
      vv_dest_proj                VARCHAR2(30);
      vv_segment_value_lookup_set VARCHAR2(60);
      vv_task_template            VARCHAR2(2);
      vv_attribut_tache           VARCHAR2(150);
    
    BEGIN
    
      -- Appel de la fonction init --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
 
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);

      IF vv_type_projet = gv_project_type_invest THEN
      
        -- Recuperation de la categorie de l'immo associee a la tache --
        vv_cat_immo_tache := dka_spaautoaccounting_pkg.get_task_asset_category_f(pn_task_id);
      
        -- Recherche du compte analytique associe a cette categorie d'immo --
        vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f('CATEGORIES FA.COMPTE GROUPE',
                                                                       vv_cat_immo_tache);
      
      ELSIF vv_type_projet = gv_project_type_refac THEN
        
         IF pn_refac_project_id IS NULL THEN
         
           -- Recuperation du projet a refacturer --
           vn_refac_proj_id := dka_spaautoaccounting_pkg.get_back_billing_project_f(pn_expenditure_item_id);
         
         ELSE
         
           vn_refac_proj_id := pn_refac_project_id;
         
         END IF;
      
        -- Recherche de la destination du projet a refacturer --
        vv_dest_refac_proj := dka_spaautoaccounting_pkg.get_dest_projet_f(vn_refac_proj_id);
      
        IF vn_refac_proj_id IS NOT NULL THEN
        
          -- Fabrication du jeu du code express --
          vv_segment_value_lookup_set := vv_type_projet || '.' ||
                                         vv_dest_refac_proj || '.' ||
                                         RTRIM(LTRIM(gv_cpt_gp_cout));
        
          -- Recherche du compte analytique associe au type de depense --
          vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                         pv_expenditure_type);
        ELSE
        
          -- Fabrication du jeu du code express --
          vv_segment_value_lookup_set := vv_type_projet || '..' ||
                                         RTRIM(LTRIM(gv_cpt_gp_cout));
        
          -- Recherche du compte analytique associe au type de depense --
          vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                         pv_expenditure_type);
        END IF;
      
      ELSIF vv_type_projet = gv_project_type_fact THEN
      
        -- Recherche du modele de la tache --
        vv_task_template := dka_spaautoaccounting_pkg.get_task_template_f(pn_task_id);

        IF vv_task_template IN ('GD', 'GL', 'GN', 'GS', 'GX', 'GB') THEN
        
          -- Fabrication du jeu du code express --
          vv_segment_value_lookup_set := vv_task_template || '.' ||
                                         RTRIM(LTRIM(gv_cpt_gp_cout));
        
          -- Recherche du compte analytique associe au type de depense --
          vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                         pv_expenditure_type);
        
        ELSIF vv_task_template = 'GT' THEN
        
          -- Recherche de l'attribut de la tache --
          vv_attribut_tache := dka_spaautoaccounting_pkg.get_task_attribute_f(pn_task_id);
        
          -- Fabrication du jeu du code express --
          vv_segment_value_lookup_set := vv_task_template || '.' ||
                                         vv_attribut_tache || '.' ||
                                         RTRIM(LTRIM(gv_cpt_gp_cout));
        
          -- Recherche du compte analytique associe au type de depense --
          vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                         pv_expenditure_type);
        
        ELSIF vv_task_template = 'GK' THEN
        
          -- Recherche de la destination du projet a refacturer --
          vv_dest_proj := dka_spaautoaccounting_pkg.get_dest_projet_f(pn_project_id);
        
          -- Fabrication du jeu du code express --
          vv_segment_value_lookup_set := vv_task_template || '.' ||
                                         vv_dest_proj || '.' ||
                                         RTRIM(LTRIM(gv_cpt_gp_cout));
        
          -- Recherche du compte analytique associe au type de depense --
          vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                         pv_expenditure_type);
        
        END IF;
      
      ELSE
      
        RETURN NULL;
      
      END IF;
    
      RETURN vv_segment4;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END run_cpt_groupe_couts_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_CPT_GROUPE_PRODUIT_F
--  Description   : Fonction qui retourne le compte groupe à partir de l'identifiant du projet, le type du projet, le type
--          d'evenement et une date.
--
--  PARAMETRES :
--      pn_project_id           Entree
--      pv_event_type           Entree
--      pn_task_id              Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la valeur du segment2 de la cle comptable
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION run_cpt_groupe_produit_f(pn_project_id IN NUMBER,
                                      pv_event_type IN VARCHAR2,
                                      pn_task_id    IN NUMBER)
      RETURN VARCHAR2 IS
      vv_errbuf                   VARCHAR2(300);
      vn_retcode                  NUMBER;
      vv_type_projet              VARCHAR2(20);
      vv_segment_value_lookup_set VARCHAR2(60);
      vv_segment4                 VARCHAR2(240);
      vv_task_template            VARCHAR2(2);
    
    BEGIN
    
      -- Appel de la fonction init --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
    
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
    
      IF vv_type_projet = gv_project_type_refac THEN
      
        -- Fabrication du jeu du code express --
        vv_segment_value_lookup_set := vv_type_projet || '.' ||
                                       RTRIM(LTRIM(gv_cpt_gp_prod));
      
        -- Recherche du compte analytique associe au type de depense --
        vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                       pv_event_type);
      
      ELSIF vv_type_projet = gv_project_type_fact THEN
      
        -- Recherche du modele de la tache --
        vv_task_template := dka_spaautoaccounting_pkg.get_task_template_f(pn_task_id);
      
        -- Fabrication du jeu du code express --
        vv_segment_value_lookup_set := vv_task_template || '.' ||
                                       RTRIM(LTRIM(gv_cpt_gp_prod));
      
        -- Recherche du compte analytique associe au type de depense --
        vv_segment4 := dka_spaautoaccounting_pkg.get_pa_code_express_f(vv_segment_value_lookup_set,
                                                                       pv_event_type);
      
      ELSE
      
        RETURN NULL;
      
      END IF;
    
      RETURN vv_segment4;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END run_cpt_groupe_produit_f;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_LOCAL_COUTS
--  Description   : Fonction utilisee pour retourner le compte local en fonction de l'identifiant du projet, du type de
--                  depense et de l'identifiant de la tâche
--
--  PARAMETRES :
--      pn_project_id        Entree
--      pv_expenditure_type  Entree
--      task_id              Entree
--
--  VALEUR RETOURNEE :
--     Description       : le compte local
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION cpt_local_couts(pn_project_id       IN NUMBER,
                             pv_expenditure_type IN VARCHAR2,
                             pn_task_id          IN NUMBER) RETURN VARCHAR2 IS
      vv_errbuf         VARCHAR2(300);
      vn_retcode        NUMBER;
      vv_type_projet    VARCHAR2(20);
      vv_cat_immo_tache VARCHAR2(150);
      vv_segment3       VARCHAR2(240);
    
    BEGIN
      -- Initialisation des variables du package --
      dka_spaautoaccounting_pkg.init(vv_errbuf, vn_retcode);
 
      -- Recuperation du type de projet --
      vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
  
      IF vv_type_projet = gv_project_type_invest THEN

        -- Recuperation de la categorie de l'immo associee a la tache --
        vv_cat_immo_tache := dka_spaautoaccounting_pkg.get_task_asset_category_f(pn_task_id);
      
        IF vv_cat_immo_tache IS NOT NULL THEN
        
          -- Recherche du compte analytique associe a cette categorie d'immo --
          vv_segment3 := dka_spaautoaccounting_pkg.get_pa_code_express_f('CATEGORIES FA.COMPTE LOCAL',
                                                                         vv_cat_immo_tache);
        
        ELSE

          RETURN NULL;
        
        END IF;
      
      ELSE

        -- Recherche le compte local associe au type de depense --
        vv_segment3 := dka_spaautoaccounting_pkg.get_pa_code_express_f('CPT_LOCAL_COUTS',
                                                                       pv_expenditure_type);
      
      END IF;
    
      RETURN vv_segment3;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END cpt_local_couts;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_GROUPE_COUTS
--  Description   : Fonction utilisee pour la regle d'autoaccounting CDG_GROUPE_COUTS
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
    FUNCTION cpt_groupe_couts(pn_project_id          IN NUMBER,
                              pv_expenditure_type    IN VARCHAR2,
                              pn_expenditure_item_id IN NUMBER,
                              pn_task_id             IN NUMBER)
      RETURN VARCHAR2 IS
      vv_segment4 VARCHAR2(240);
      
    BEGIN
    
      -- Appel de la fonction RUN_CPT_GROUPE_COUTS_F pour recuperer la valeur du segment --
      vv_segment4 := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f(pn_project_id          => pn_project_id,
                                                                      pv_expenditure_type    => pv_expenditure_type,
                                                                      pn_expenditure_item_id => pn_expenditure_item_id,
                                                                      pn_task_id             => pn_task_id);
    
      RETURN vv_segment4;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END cpt_groupe_couts;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : CPT_GROUPE_PRODUIT
--
--  Description   : Fonction utilisee pour la regle d'autoaccounting CDG_GROUPE_PRODUIT
--
--  PARAMETRES :
--      pn_project_id           Entree
--      pv_event_type           Entree
--      pn_task_id              Entree
--
--  VALEUR RETOURNEE :
--     Description       : Retourne la valeur du segment4 de la cle comptable en fonction de l'identifiant du projet,
--             du type de l'evenement et de l'identifiant de la tache.
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION cpt_groupe_produit(pn_project_id IN NUMBER,
                                pv_event_type IN VARCHAR2,
                                pn_task_id    IN NUMBER) RETURN VARCHAR2 IS
      vv_segment4 VARCHAR2(240);
      
    BEGIN
    
      -- Appel de la fonction run_cpt_groupe_produit pour rechercher la valeur du segment4 --
      vv_segment4 := dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f(pn_project_id => pn_project_id,
                                                                        pv_event_type => pv_event_type,
                                                                        pn_task_id    => pn_task_id);
    
      RETURN vv_segment4;
    
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END cpt_groupe_produit;

END &&package_name; -- Package body
/
/*<TOAD_FILE_CHUNK>*/


SHOW ERRORS;

EXIT
