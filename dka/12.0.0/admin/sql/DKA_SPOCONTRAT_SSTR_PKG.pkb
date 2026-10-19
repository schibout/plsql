CREATE OR REPLACE PACKAGE BODY DKA_SPOCONTRAT_SSTR_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SPOCONTRAT_SSTR_PKG.pkb 485 2007-12-03 15:58:05Z NORDEST\tbonduae $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCONTRAT_SSTR_PKG.pkb
-- DESCRIPTION       : DKA_SPOCONTRAT_SSTR_PKG package body
--
-- AUTEUR            : T. Bonduaeux
-- DATE DE CREATION  : 03/12/2007
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : À exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 03-Dec-07  tbonduae  Création
-- 11-Jan-10  cde       Correction controle frs : ajout procedure Check_vendor
-- 15-Jan-10  cde       Evol EID20090323 - ajout de la procédure get_ccid
-- 08-Sep-10  cde       EARS00009239876 - Correctif génération ccid dernier jour du mois
-- 14-Fev-11  cde       Evol DGE20100001 - Modif LOV gestionnaire + Ajout Procédures de calcul
--                      des dates de début et de fin du contrat + Modif check_montant_imput_facture
-- 04-Mai-11  cde       EARS00009474845 - Correctif calcul nouveau montant imputé suite modif
-- 20-Jan-12  bco       Correction du package pour inclure les projets de CODE Z lors de l'ajout d'une imputation
-- 12-AOU-16  RBE       Migration R12
-- 10-JAN-17  RBE       Correction artf2080405
-- 24-JUL-17  RBE       artf2187880: SPE119 - Problème de CCF lors de la résiliation d'un contrat
-- 24-AOU-17  NBO       artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD
-- 15-FEV-18  RBE       artf2376255 : SPE119 - Correction de la sélection Employés
-- 04-SEP-18  RBE       artf3025989 : INC0243936 - SPE119 - Problème recherche gestionnaire contrat SSTR
-- 10-SEP-18  RBE       artf3029018 : INC0245981 - Correctif SSTR - Liste des fournisseurs
-- 25/08/2023 ARA       EDB364 - Contrats SSTR - Rajout d'une liste déroulante pour la région
--------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  cst_type_ligne CONSTANT VARCHAR2(50) := 'PRESTATION';
  --g_org_id             NUMBER := fnd_profile.VALUE('ORG_ID');

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--------------------------------------------------------------------------------
--  Nom           : get_varchar2_parameter
--  Description   : Procédure récupérant un paramètre de type VARCHAR2
--  PARAMETRES    :
--                     pv_program_code      : Le code programme
--                     pv_parameter_name    : Le nom du paramètre
--                     pv_data              : La valeur du paramètre
--                     pn_retcode           : Le code d'erreur
--                     pv_errbuf            : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_varchar2_parameter(pv_program_code   IN     VARCHAR2,
                                     pv_parameter_name IN     VARCHAR2,
                                     pv_data              OUT VARCHAR2,
                                     pn_retcode           OUT NUMBER,
                                     pv_err_msg           OUT VARCHAR2)
    IS
        lr_result DKA_PARAMETERS%ROWTYPE;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        DKA_TOOLS_PKG.GET_PARAMETER(pv_program_code,
                                    pv_parameter_name,
                                    lr_result,
                                    pn_retcode,
                                    pv_err_msg);
        pv_data := lr_result.varchar2_value;

        IF pv_data IS NULL
        THEN
            pn_retcode := 2;
            pv_err_msg := 'Pas de valeur';
        END IF;
    END;

--------------------------------------------------------------------------------
--  Nom           : get_number_parameter
--  Description   : Procédure récupérant un paramètre de type NUMBER
--  PARAMETRES    :
--                     pv_program_code      : Le code programme
--                     pv_parameter_name    : Le nom du paramètre
--                     pv_data              : La valeur du paramètre
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_number_parameter(pv_program_code   IN     VARCHAR2,
                                   pv_parameter_name IN     VARCHAR2,
                                   pv_data              OUT NUMBER,
                                   pn_retcode           OUT NUMBER,
                                   pv_err_msg           OUT VARCHAR2)
    IS
        lr_result DKA_PARAMETERS%ROWTYPE;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        DKA_TOOLS_PKG.GET_PARAMETER(pv_program_code,
                                    pv_parameter_name,
                                    lr_result,
                                    pn_retcode,
                                    pv_err_msg);
        pv_data := lr_result.number_value;

        IF pv_data IS NULL
        THEN
            pn_retcode := 2;
            pv_err_msg := 'Pas de valeur';
        END IF;
    END;

--------------------------------------------------------------------------------
--  Nom           : Check_vendor
--  Description   : Procédure de contrôle du fournisseur
--  PARAMETRES    :
--                     pv_vendor_id         : ID fournisseur
--                     pv_check             : variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_vendor(pv_vendor_id      IN     NUMBER,
                           pv_check             OUT VARCHAR2,
                           pn_retcode           OUT NUMBER,
                           pv_err_msg           OUT VARCHAR2)
    IS
    l_vendor_id NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT vendor_id
           INTO l_vendor_id
           FROM po_vendors po
           WHERE 1 = 1 --po.pay_group_lookup_code IN ('TIERS', 'GROUPEDKA', 'PARTENAIRE') -- RBE Migration R12 --RBE artf3029018 
             AND PO.VENDOR_TYPE_LOOKUP_CODE NOT IN ('EMPLOYEE', 'FACTOR') --RBE artf3029018 
             AND po.end_date_active IS NULL
             AND po.vendor_id = pv_vendor_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Fournisseur non actif';
           pn_retcode := 2;
        END;
        
    END check_vendor;    

--------------------------------------------------------------------------------
--  Nom           : Check_vendor_site
--  Description   : Procédure de contrôle du site fournisseur
--  PARAMETRES    :
--                     pn_vendor_site_id    : ID site fournisseur
--                     pv_check             : variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_vendor_site(pn_vendor_site_id    IN     NUMBER,
                                pv_check             OUT VARCHAR2,
                                pn_retcode           OUT NUMBER,
                                pv_err_msg           OUT VARCHAR2)
    IS
    l_vendor_site_id NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT vendor_site_id
           INTO l_vendor_site_id
           FROM po_vendor_sites_all pvs  --RBE Migration R12
           WHERE pvs.purchasing_site_flag = 'Y'
             AND (pvs.inactive_date IS NULL 
               OR pvs.inactive_date > sysdate)
             AND pvs.vendor_site_id = pn_vendor_site_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Site fournisseur non actif';
           pn_retcode := 2;
        END;
      
    END check_vendor_site;    

--------------------------------------------------------------------------------
--  Nom           : Check_lieu_livraison
--  Description   : Procédure de contrôle du lieu de livraison
--  PARAMETRES    :
--                     pn_ship_to_location_id  : ID lieu livraison
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_lieu_livraison(pn_ship_to_location_id   IN     NUMBER,
                                   pv_check                 OUT VARCHAR2,
                                   pn_retcode               OUT NUMBER,
                                   pv_err_msg               OUT VARCHAR2)
    IS
    l_ship_to_location_id NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT location_id
           INTO l_ship_to_location_id
           FROM hr_locations
           WHERE ship_to_site_flag = 'Y'
             AND nvl(inactive_date, sysdate) >= sysdate
             AND location_id = pn_ship_to_location_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Lieu de livraison non actif';
           pn_retcode := 2;
        END;
        
    END check_lieu_livraison; 

--------------------------------------------------------------------------------
--  Nom           : Check_lieu_facturation
--  Description   : Procédure de contrôle du lieu de facturation
--  PARAMETRES    :
--                     pn_bill_to_location_id  : ID lieu facturation
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_lieu_facturation(pn_bill_to_location_id   IN     NUMBER,
                                     pv_check                 OUT VARCHAR2,
                                     pn_retcode               OUT NUMBER,
                                     pv_err_msg               OUT VARCHAR2)
    IS
    l_bill_to_location_id NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT location_id
           INTO l_bill_to_location_id
           FROM hr_locations
           WHERE bill_to_site_flag = 'Y'
             AND nvl(inactive_date, sysdate) >= sysdate
             AND location_id = pn_bill_to_location_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Lieu de facturation non actif';
           pn_retcode := 2;
        END;
        
    END check_lieu_facturation; 

--------------------------------------------------------------------------------
--  Nom           : Check_projet
--  Description   : Procédure de contrôle du projet
--  PARAMETRES    :
--                     pn_project_id           : ID projet
--                     pv_project_readonly     : Balise code projet en lecture seule
--                     pn_org_id               : ID Org
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_projet(pn_project_id       IN  NUMBER,
                           pv_project_readonly IN  VARCHAR2,
                           pn_org_id           IN  NUMBER,
                           pv_check            OUT VARCHAR2,
                           pn_retcode          OUT NUMBER,
                           pv_err_msg          OUT VARCHAR2)
    IS
    l_project_id NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;


        IF pv_project_readonly = 'NumProjetRO'
        THEN
        -- Contrôle différent pour le mode "Modification"
           BEGIN
                SELECT project_id
                INTO l_project_id
                FROM pa_projects_all pj   
                    --,hr_all_organization_units_vl haou 
                    --,ak_web_user_sec_attr_values attribut
                    --,fnd_application appli
                WHERE pj.project_status_code NOT IN ('CLOSED')
                  AND pj.project_type IN ('Facturable') --RBE Migration R12
                  AND pj.template_flag = 'N'
                  --AND pj.carrying_out_organization_id = haou.organization_id
                  /*AND dka_ibdsoc_tools_pkg.find_parent_acct_area_by_level ( haou.name , '2', TRUNC (SYSDATE))  = attribut.VARCHAR2_VALUE  -- rbe
                  AND attribut.web_user_id = fnd_global.user_id
                  AND attribut.attribute_code = 'DKA_CONTRAT_SSTR_REGION'
                  AND attribut.attribute_application_id = appli.application_id
                  AND appli.application_short_name = 'ICX' */
                  AND pj.org_id     = pn_org_id
                  AND pj.project_id = pn_project_id;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
                    pv_check := 'KO';
                    pv_err_msg := 'Projet non actif';
                    pn_retcode := 2;
           END;
        ELSE
           BEGIN
                SELECT project_id
                INTO l_project_id
                FROM pa_projects_all pj   
                    --,hr_all_organization_units_vl haou 
                    --,ak_web_user_sec_attr_values attribut
                    --,fnd_application appli
                WHERE pj.project_status_code NOT IN ('CLOSED', '1001')
                  AND pj.project_type IN ('Facturable') --RBE Migration R12
                  AND pj.template_flag = 'N'
                  /*AND pj.carrying_out_organization_id = haou.organization_id
                  AND dka_ibdsoc_tools_pkg.find_parent_acct_area_by_level ( haou.name , '2', TRUNC (SYSDATE))  = attribut.VARCHAR2_VALUE
                  AND attribut.web_user_id = fnd_global.user_id
                  AND attribut.attribute_code = 'DKA_CONTRAT_SSTR_REGION'
                  AND attribut.attribute_application_id = appli.application_id
                  AND appli.application_short_name = 'ICX' */
                  AND pj.org_id     = pn_org_id 
                  AND pj.project_id = pn_project_id;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
                    pv_check := 'KO';
                    pv_err_msg := 'Projet non actif';
                    pn_retcode := 2;
           END;
         END IF;  
        
    END check_projet; 

--------------------------------------------------------------------------------
--  Nom           : Check_expenditure_type
--  Description   : Procédure de contrôle du type de dépense
--  PARAMETRES    :
--                     pv_expenditure_type     : Type de dépense
--                     pn_project_id           : ID projet
--                     pn_task_id              : ID tache
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_expenditure_type(pv_expenditure_type   IN     VARCHAR2,
                                     pn_project_id         IN     NUMBER,
                                     pn_task_id            IN     NUMBER, --RBE artf2080405
                                     pv_check              OUT VARCHAR2,
                                     pn_retcode            OUT NUMBER,
                                     pv_err_msg            OUT VARCHAR2)
    IS
    l_expenditure_type VARCHAR2(30);
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT et.expenditure_type
           INTO l_expenditure_type
           FROM pa_expenditure_types et
               ,pa_transaction_controls ptc 
               ,pa_projects_all ppa
           WHERE ptc.project_id = ppa.project_id
             AND ptc.expenditure_type = et.expenditure_type
             AND et.attribute3 = 'Y'
             AND et.attribute5 = 'Y'
             AND (et.end_date_active IS NULL or trunc(et.end_date_active) > trunc(SYSDATE))
             AND (ptc.end_date_active IS NULL or trunc(ptc.end_date_active) > trunc(SYSDATE))
             AND ppa.project_id = pn_project_id
             AND ptc.task_id    = pn_task_id --RBE artf2080405
             AND et.expenditure_type = pv_expenditure_type;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Type de dépense non actif pour le projet';
           pn_retcode := 2;
        END;
        
    END check_expenditure_type; 

--------------------------------------------------------------------------------
--  Nom           : Check_gestionnaire
--  Description   : Procédure de contrôle du gestionnaire
--  PARAMETRES    :
--                     pn_gestionnaire_id      : ID gestionnaire
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_gestionnaire(pn_gestionnaire_id    IN     NUMBER,
                                 pv_check              OUT VARCHAR2,
                                 pn_retcode            OUT NUMBER,
                                 pv_err_msg            OUT VARCHAR2)
    IS
    l_gestionnaire NUMBER;
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           SELECT ppf.person_id
           INTO l_gestionnaire
           FROM --per_people_f ppf -- RBE artf2376255
                per_people_f ppf  -- RBE artf2376255 --artf3025989
               ,per_assignments_f pav 
               ,per_jobs pj
               ,po_agents pa
           WHERE ppf.person_id = pav.person_id
             AND pav.job_id = pj.job_id
             AND pa.agent_id = ppf.person_id
             AND ppf.current_employee_flag = 'Y'
             AND TRUNC(SYSDATE) BETWEEN TRUNC(ppf.effective_start_date) AND NVL(ppf.effective_end_date,SYSDATE) --RBE  artf3025989
             AND TRUNC(sysdate) BETWEEN TRUNC(pav.effective_start_date) AND pav.effective_end_date --RBE
             AND TRUNC(sysdate) BETWEEN nvl(pa.start_date_active, trunc(sysdate)) AND nvl(pa.end_date_active, sysdate) 
             AND pj.attribute3 = 'OUI'
             AND EXISTS ( SELECT  1 
                          FROM ak_web_user_sec_attr_values attribut, fnd_application appli,  fnd_user fu
                          WHERE attribut.varchar2_value  = ppf.attribute2
                            AND attribut.web_user_id = fu.user_id
                            AND attribut.web_user_id = fnd_global.user_id
                            AND attribut.attribute_code = 'DKA_CONTRAT_SSTR_REGION'
                            AND attribut.attribute_application_id = appli.application_id
                            AND appli.application_short_name = 'ICX' 
                          )
             AND ppf.person_id = pn_gestionnaire_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pv_check := 'KO';
           pv_err_msg := 'Gestionnaire non actif';
           pn_retcode := 2;
        END;
        
    END check_gestionnaire; 

--------------------------------------------------------------------------------
--  Nom           : Check_nature_prestation
--  Description   : Procédure de contrôle de la nature de prestation
--  PARAMETRES    :
--                     pv_nature_prest         : Nature de prestation
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE Check_nature_prestation(pv_nature_prest    IN     VARCHAR2,
                                 pv_check              OUT VARCHAR2,
                                 pn_retcode            OUT NUMBER,
                                 pv_err_msg            OUT VARCHAR2)
    IS
    vv_nature_prestation VARCHAR2(100);
    vv_value_set_name VARCHAR2(50);
    vv_sql VARCHAR2(4000);
    vv_mapping_code VARCHAR2(150);
    vn_success NUMBER;
    vv_sql_req VARCHAR2(4000);
    
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
        vv_value_set_name := 'DKA_NATURE_PRESTATION';

        fnd_flex_val_api.get_table_vset_select 
                   (p_value_set_name => vv_value_set_name
                    , x_select =>  vv_sql 
                    , x_mapping_code => vv_mapping_code
                    , x_success => vn_success );


        IF vv_sql IS NOT NULL
        THEN
        vv_sql_req := 'SELECT category_concat_segs'||
                   ' FROM ('||vv_sql ||')'||
                   'WHERE category_concat_segs = :pv_nature_prest';
                   
           BEGIN           
               EXECUTE IMMEDIATE vv_sql_req INTO vv_nature_prestation USING pv_nature_prest;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              pv_check := 'KO';
              pv_err_msg := 'Nature de prestation non active';
              pn_retcode := 2;
           END;
        ELSE
              pv_check := 'KO';
              pv_err_msg := 'Erreur dans la récupération du jeu de valeurs';
              pn_retcode := 2;         
        END IF;
        
    END Check_nature_prestation; 


--------------------------------------------------------------------------------
--  Nom           : get_affich_imput
--  Description   : Fonction permettant de déterminer si les informations au niveau
--                  imputation doivent être modifiable ou pas
--  PARAMETRES    :
--                     pn_contrat_imput_id    : ID de la ligne d'imputation
--                     pv_champ               : nom du champ
--------------------------------------------------------------------------------
    FUNCTION get_affich_imput (
        pn_contrat_imput_id   IN   NUMBER,
        pv_champ              IN   VARCHAR2
        
    )
        RETURN VARCHAR2
    IS
        vv_affichage          VARCHAR2(10);
        vn_commande_id        NUMBER;
        vn_unite_oeuvre_archi NUMBER;
        vn_reconduction_num   NUMBER;
    BEGIN
        -- Initialisation
        vv_affichage := NULL;

        BEGIN
        SELECT dcs.commande_id,
               dcsia.unite_oeuvre,
               dcs.reconduction_num
        INTO   vn_commande_id,
               vn_unite_oeuvre_archi,
               vn_reconduction_num
        FROM   dka_contrat_sstr dcs, 
               dka_contrat_sstr_imput_archi dcsia
        WHERE  dcsia.po_header_id = dcs.po_header_id
          AND  dcsia.contrat_imputation_id = pn_contrat_imput_id
          AND  dcsia.revision_num = (SELECT MAX(revision_num) 
                                     FROM po_headers_archive_all 
                                     WHERE po_header_id = dcsia.po_header_id);
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_commande_id := NULL;
            vn_unite_oeuvre_archi := NULL;
            vn_reconduction_num := 0;
        END;

        IF ((pv_champ = 'LIEU_PREST' OR pv_champ = 'PROJET' OR pv_champ = 'SUPPR' OR pv_champ = 'TACHE') --RBE Migration R12
             AND vn_commande_id IS NOT NULL AND vn_unite_oeuvre_archi IS NOT NULL)
            OR
            (pv_champ = 'EXP_TYPE' AND vn_reconduction_num > 0
            AND vn_commande_id IS NOT NULL AND vn_unite_oeuvre_archi IS NOT NULL)
        THEN
            vv_affichage := 'RO';
        ELSE
            vv_affichage := 'AF';
        END IF;
        
        ----- return value -----
        RETURN (vv_affichage);
    END get_affich_imput;
    

--------------------------------------------------------------------------------
--  Nom           : get_invoices_count
--  Description   : Procédure de comptage du nombre de factures
--  PARAMETRES    :
--                     pn_commande_id       : ID commande
--                     pn_nbr_facture       : Nombre de factures
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_invoices_count(pn_commande_id      IN     NUMBER,
                                 pn_nbr_facture      OUT NUMBER,
                                 pn_retcode          OUT NUMBER,
                                 pv_err_msg          OUT VARCHAR2)
    IS
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN
           -- On détermine s'il y a ou pas des factures à partir de la quantité facturée
           -- pour prendre en compte le cas des commandes reprises 
           --SELECT count(distinct invoice_id)
           --INTO pn_nbr_facture
           --FROM ap_invoice_distributions_all apd
           --     , po_distributions_all pd
           --WHERE pd.po_distribution_id = apd.po_distribution_id
           --  AND pd.po_header_id = pn_commande_id;
           SELECT decode(sum(quantity_billed),0,0,1)
           INTO pn_nbr_facture
           FROM po_distributions_all pd
           WHERE pd.po_header_id = pn_commande_id;          
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pn_nbr_facture := 0;
           pv_err_msg := 'Erreur dans la détermination du nombre de facture';
           pn_retcode := 2;
        END;
        
    END get_invoices_count; 

--------------------------------------------------------------------------------
--  Nom           : check_montant_facture
--  Description   : Procédure de vérification du nouveau montant du contrat
--  PARAMETRES    :
--                     pn_contrat_id        : ID contrat
--                     pd_start_date        : Date de début
--                     pd_end_date          : Date de fin
--                     pn_amount            : Montant
--                     pd_date_effet        : Date d'effet
--                     pn_commande_id       : ID commande
--                     pv_check             : Variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_montant_facture(pn_contrat_id      IN     NUMBER,
                                    pd_start_date      IN     DATE,
                                    pd_end_date        IN     DATE,
                                    pn_amount          IN     NUMBER,
                                    pd_date_effet      IN     DATE,
                                    pn_commande_id     IN     NUMBER,                        
                                    pv_check           OUT    VARCHAR2,
                                    pn_retcode         OUT    NUMBER,
                                    pv_err_msg         OUT    VARCHAR2)
    IS
    vn_amount_facture NUMBER;
    vn_amount_commande NUMBER;
    vn_nbr_mois_contrat NUMBER;
    vd_date_effet_deb DATE;
    vd_date_effet_fin DATE;

        CURSOR cur_historique(pn_contrat_id NUMBER, pd_start_date DATE)
            IS
            SELECT phaa.revision_num,
                   phaa.blanket_total_amount amount,
                   phaa.start_date,
                   dcsa.date_effet,
                   dcsa_RevSup.date_effet date_effet_revsup,
                   dcsa_RevSup.revision_num revision_num_revsup
            FROM   po_headers_archive_all phaa
                   ,dka_contrat_sstr_archi dcsa
                   ,dka_contrat_sstr_archi dcsa_RevSup
            WHERE  dcsa.po_header_id = phaa.po_header_id
            AND    dcsa.revision_num = phaa.revision_num
            AND    dcsa_RevSup.po_header_id(+) = phaa.po_header_id
            AND    dcsa_RevSup.revision_num(+) = phaa.revision_num + 1
            AND    phaa.po_header_id = pn_contrat_id
            AND    phaa.start_date = pd_start_date
            ORDER BY phaa.revision_num
            ; 
         rec_historique cur_historique%ROWTYPE;

    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
        vn_amount_commande := 0;
        vn_nbr_mois_contrat := round(months_between(trunc(pd_end_date), trunc(pd_start_date)));
        
        IF pd_date_effet IS NULL
        THEN
        -- Cas de correction de date de début la première année avec changement de montant
            vn_amount_commande := pn_amount;
        ELSE    
        
            -- Calcul du nouveau montant de la commande        
            FOR rec_historique IN cur_historique (pn_contrat_id, pd_start_date)
            LOOP
                BEGIN
                vd_date_effet_deb := nvl(rec_historique.date_effet, rec_historique.start_date);
                
                IF rec_historique.revision_num_revsup IS NULL
                THEN
                     vd_date_effet_fin := nvl(rec_historique.date_effet_revsup, pd_date_effet);
                ELSE
                     vd_date_effet_fin := nvl(rec_historique.date_effet_revsup, rec_historique.start_date);
                END IF;

                IF round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))) > 0
                THEN  
                     vn_amount_commande := vn_amount_commande + ROUND((rec_historique.amount 
                                             * round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))))
                                                / vn_nbr_mois_contrat , 2);
                END IF;

                END;
            END LOOP;    

            vn_amount_commande := vn_amount_commande + ROUND((pn_amount 
                                    * round(months_between(trunc(pd_end_date), trunc(pd_date_effet))))
                                           / vn_nbr_mois_contrat , 2);
        END IF;
         
        -- Calcul du montant facturé
        BEGIN
           -- Dermination du montant facturé directement à partir de po_distributions
           -- pour prendre en compte le cas des commandes reprises.
           --SELECT nvl(sum(apd.amount),0)
           --INTO vn_amount_facture
           --FROM ap_invoice_distributions_all apd,
           --     po_distributions_all pd
           --WHERE pd.po_distribution_id = apd.po_distribution_id
           --  AND pd.po_header_id = pn_commande_id;
           SELECT nvl(sum(pd.quantity_billed),0)
           INTO vn_amount_facture
           FROM po_distributions_all pd
           WHERE pd.po_header_id = pn_commande_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           vn_amount_facture := 0;
        END;
        
        
        IF (vn_amount_commande < vn_amount_facture)
        THEN
           pv_check := 'KO';
        END IF;

    EXCEPTION
     WHEN OTHERS THEN
       pn_retcode := 2;
       pv_err_msg  := 'CHECK_MONTANT_FACTURE =>' || SQLERRM;        
    END check_montant_facture; 


--------------------------------------------------------------------------------
--  Nom           : check_montant_imput_facture
--  Description   : Procédure de vérification du nouveau montant du contrat
--  PARAMETRES    :
--                     pn_imputation_id        : ID imputation contrat
--                     pd_start_date           : Date de début
--                     pd_end_date             : Date de fin
--                     pn_amount               : Montant du contrat
--                     pd_date_effet           : Date d'effet
--                     pn_commande_id          : ID commande
--                     pn_unit_oeuvre          : Unite d'oeuvre
--                     pn_sum_unit_oeuvre      : Somme des unités d'oeuvre
--                     pv_check                : Variable de contrôle
--                     pn_amount_imputation    : Montant commandé
--                     pn_amount_imput_facture : Montant facturé
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_montant_imput_facture(pn_imputation_id         IN     NUMBER,
                                           pd_start_date           IN     DATE,
                                           pd_end_date             IN     DATE,
                                           pn_amount               IN     NUMBER,
                                           pd_date_effet           IN     DATE,
                                           pn_commande_id          IN     NUMBER, 
                                           pn_unit_oeuvre          IN     NUMBER,
                                           pn_sum_unit_oeuvre      IN     NUMBER,                      
                                           pv_check                OUT    VARCHAR2,
                                           pn_amount_imputation    OUT    NUMBER, 
                                           pn_amount_imput_facture OUT    NUMBER,
                                           pn_retcode              OUT    NUMBER,
                                           pv_err_msg              OUT    VARCHAR2)
    IS
    vn_nbr_mois_contrat NUMBER;
    vd_date_effet_deb DATE;
    vd_date_effet_fin DATE;

        CURSOR cur_historique_imput(pn_imputation_id NUMBER, pd_start_date DATE)
            IS
            SELECT phaa.revision_num,
                   phaa.po_header_id,
                   phaa.blanket_total_amount amount,
                   phaa.start_date,
                   dcsa.date_effet,
                   dcsa_RevSup.date_effet date_effet_revsup,
                   dcsia.location_id,
                   dcsia.project_id,
                   dcsia.unite_oeuvre,
                   dcsia_sum.sum_unite_oeuvre,
                   dcsa_RevSup.revision_num revision_num_revsup
            FROM   po_headers_archive_all phaa
                   ,dka_contrat_sstr_archi dcsa
                   ,dka_contrat_sstr_archi dcsa_RevSup
                   ,dka_contrat_sstr_imput_archi dcsia
                   ,(SELECT po_header_id, revision_num, sum(unite_oeuvre) sum_unite_oeuvre
                     FROM dka_contrat_sstr_imput_archi
                     GROUP BY po_header_id, revision_num) dcsia_sum
            WHERE  dcsa.po_header_id = phaa.po_header_id
            AND    dcsa.revision_num = phaa.revision_num
            AND    dcsa_RevSup.po_header_id(+) = phaa.po_header_id
            AND    dcsa_RevSup.revision_num(+) = phaa.revision_num + 1
            AND    phaa.po_header_id = dcsia.po_header_id
            AND    phaa.revision_num = dcsia.revision_num
            AND    dcsia_sum.po_header_id = dcsia.po_header_id
            AND    dcsia_sum.revision_num = dcsia.revision_num
            AND    dcsia.contrat_imputation_id = pn_imputation_id
            AND    phaa.start_date = pd_start_date
            ORDER BY phaa.revision_num
            ; 
         rec_historique_imput cur_historique_imput%ROWTYPE;

    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
        pn_amount_imputation := 0;
        vn_nbr_mois_contrat := round(months_between(trunc(pd_end_date), trunc(pd_start_date)));
        
        IF pd_date_effet IS NULL
        THEN
        -- Cas de correction de date de début la première année avec changement de montant
            pn_amount_imputation := pn_amount * pn_unit_oeuvre / pn_sum_unit_oeuvre;
        ELSE 
        
            -- Calcul du nouveau montant de la commande        
            FOR rec_historique_imput IN cur_historique_imput (pn_imputation_id, pd_start_date)
            LOOP
               BEGIN
               vd_date_effet_deb := nvl(rec_historique_imput.date_effet, rec_historique_imput.start_date);
               
               IF rec_historique_imput.revision_num_revsup IS NULL
               THEN 
                   vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup, pd_date_effet); 
               ELSE
                   vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup, rec_historique_imput.start_date);                
               END IF;

               IF rec_historique_imput.sum_unite_oeuvre != 0 AND round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))) > 0
               THEN                 
                   pn_amount_imputation := pn_amount_imputation + ROUND((rec_historique_imput.amount 
                                            * (round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))))
                                               / vn_nbr_mois_contrat)
                                            * (rec_historique_imput.unite_oeuvre / rec_historique_imput.sum_unite_oeuvre)
                                                , 2);
               END IF;

               END;
            END LOOP;    

            IF pn_sum_unit_oeuvre != 0 
            THEN
                pn_amount_imputation := pn_amount_imputation + ROUND((pn_amount 
                                           * (round(months_between(trunc(pd_end_date), trunc(pd_date_effet))))
                                               / vn_nbr_mois_contrat)
                                           *  (pn_unit_oeuvre / pn_sum_unit_oeuvre)
                                               , 2);
            END IF;
        END IF;
 
        -- Calcul du montant facturé pour la ligne d'imputation
        BEGIN
           -- Dermination du montant facturé directement à partir de po_distributions
           -- pour prendre en compte le cas des commandes reprises.
           --SELECT nvl(sum(apd.amount),0)
           --INTO vn_amount_imput_facture
           --FROM ap_invoice_distributions_all apd
           --     , po_distributions_all pd
           --     , dka_contrat_sstr_imputation dcsi
           --WHERE pd.po_distribution_id = apd.po_distribution_id
           --  AND pd.attribute3 = dcsi.contrat_imputation_id
           --  AND pd.po_header_id = pn_commande_id
           --  AND dcsi.contrat_imputation_id = pn_imputation_id;
           SELECT nvl(pd.quantity_billed,0)
           INTO pn_amount_imput_facture
           FROM po_distributions_all pd
           WHERE pd.attribute3 = pn_imputation_id
             AND pd.po_header_id = pn_commande_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           pn_amount_imput_facture := 0;
        END;
        
        
        IF (pn_amount_imputation < pn_amount_imput_facture)
        THEN
           pv_check := 'KO';
        END IF;

    EXCEPTION
     WHEN OTHERS THEN
       pn_retcode := 2;
       pv_err_msg  := 'CHECK_MONTANT_IMPUT_FACTURE =>' || SQLERRM;        
    END check_montant_imput_facture; 


--------------------------------------------------------------------------------
--  Nom           : get_first_revnum_ctr_annuel
--  Description   : Fonction fournissant le numéro de la dernière révision approuvée
--                  d'un contrat annuel
--  PARAMETRES    :
--                     pn_contrat_id    : ID du contrat
--                     pd_start_date    : Date de début
--------------------------------------------------------------------------------
    FUNCTION get_first_revnum_ctr_annuel (
        pn_contrat_id   IN   NUMBER,
        pd_start_date   IN   DATE
    )
        RETURN NUMBER
    IS
        vn_revision_num       NUMBER;
    BEGIN
        -- Initialisation
        vn_revision_num := NULL;

        BEGIN
        SELECT min(revision_num)
        INTO   vn_revision_num
        FROM   po_headers_archive_all
        WHERE  po_header_id = pn_contrat_id
          AND  start_date = pd_start_date;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_revision_num := NULL;
        END;

        ----- return value -----
        RETURN (vn_revision_num);
    END get_first_revnum_ctr_annuel;

--------------------------------------------------------------------------------
--  Nom           : get_last_revnum_ctr_annuel
--  Description   : Fonction fournissant le numéro de la dernière révision approuvée
--                  d'un contrat annuel
--  PARAMETRES    :
--                     pn_contrat_id    : ID du contrat
--                     pd_start_date    : Date de début
--------------------------------------------------------------------------------
    FUNCTION get_last_revnum_ctr_annuel (
        pn_contrat_id   IN   NUMBER,
        pn_commande_id  IN   NUMBER
       -- pd_start_date   IN   DATE
    )
        RETURN NUMBER
    IS
        vn_revision_num       NUMBER;
    BEGIN
        -- Initialisation
        vn_revision_num := NULL;

        BEGIN
        SELECT max(pha.revision_num)
        INTO   vn_revision_num
        FROM   po_headers_archive_all pha,
               dka_contrat_sstr_archi dcsa
        WHERE  pha.po_header_id = pn_contrat_id
          AND  dcsa.po_header_id = pha.po_header_id
          AND  dcsa.revision_num = pha.revision_num
          AND  dcsa.commande_id = pn_commande_id; 
          -- on se base sur l'id de la commande au lieu de la start_date pour gérer les cas de maj la première année      
          -- AND  start_date = pd_start_date;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_revision_num := NULL;
        END;

        ----- return value -----
        RETURN (vn_revision_num);
    END get_last_revnum_ctr_annuel;


--------------------------------------------------------------------------------
--  Nom           : get_ccid
--  Description   : Procédure de calcul de la ccid
--  PARAMETRES    :
--                     pv_nature_prestation : Segments catégorie
--                     pv_expenditure_type  : Type de dépense
--                     pn_signataire_id     : Id du signataire
--                     pn_project_id        : Id du Projet
--                     pn_task_id           : Id de la tache
--                     pn_vendor_id         : Id du fournisseur
--                     pn_ccid              : Id de la clé comptable
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------

  PROCEDURE get_ccid(pv_nature_prestation          IN VARCHAR2,
                     pv_expenditure_type           IN VARCHAR2,
                     pn_signataire_id              IN NUMBER,
                     pn_project_id                 IN NUMBER,
                     Pn_Task_Id                    IN NUMBER, -- RBE MigR12
                     pn_vendor_id                  IN NUMBER,
                     pn_org_id                     IN NUMBER,
                     pn_ccid                       OUT NUMBER,
                     pn_retcode                    OUT NUMBER,
                     pv_err_msg                    OUT VARCHAR2) IS
    result BOOLEAN;

    l_charge_success              BOOLEAN;
    l_budget_success              BOOLEAN;
    l_accrual_success             BOOLEAN;
    l_variance_success            BOOLEAN;
    l_code_combination_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_budget_account_id           gl_code_combinations_kfv.code_combination_id%TYPE;
    l_accrual_account_id          gl_code_combinations_kfv.code_combination_id%TYPE;
    l_variance_account_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_charge_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_budget_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_accrual_account_flex        gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_variance_account_flex       gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_charge_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_budget_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_accrual_account_desc        gl_code_combinations_kfv.description%TYPE;
    l_variance_account_desc       gl_code_combinations_kfv.description%TYPE;
    l_coa_id                      NUMBER;
    l_bom_resource_id             NUMBER;
    l_bom_cost_element_id         NUMBER;
    l_category_id                 NUMBER;
    l_destination_type_code       VARCHAR2(100);
    l_deliver_to_location_id      NUMBER;
    l_destination_organization_id NUMBER;
    l_destination_subinventory    VARCHAR2(100);
    l_expenditure_type            VARCHAR2(100);
    l_expenditure_organization_id NUMBER;
    l_expenditure_item_date       DATE;
    l_item_id                     NUMBER;
    l_line_type_id                NUMBER;
    l_result_billable_flag        VARCHAR2(100);
    l_agent_id                    NUMBER;
    l_project_id                  NUMBER;
    l_from_type_lookup_code       VARCHAR2(100);
    l_from_header_id              NUMBER;
    l_from_line_id                NUMBER;
    l_task_id                     NUMBER;
    l_deliver_to_person_id        NUMBER;
    l_type_lookup_code            VARCHAR2(100);
    l_vendor_id                   NUMBER;
    l_wip_entity_id               NUMBER;
    l_wip_entity_type             VARCHAR2(100);
    l_wip_line_id                 NUMBER;
    l_wip_repetitive_schedule_id  NUMBER;
    l_wip_operation_seq_num       NUMBER;
    l_wip_resource_seq_num        NUMBER;
    l_po_encumberance_flag        VARCHAR2(100);
    l_gl_encumbered_date          DATE;
    l_wf_itemkey                  VARCHAR2(100);
    l_new_combination             BOOLEAN;
    l_header_att1                 VARCHAR2(240);
    l_header_att2                 VARCHAR2(240);
    l_header_att3                 VARCHAR2(240);
    l_header_att4                 VARCHAR2(240);
    l_header_att5                 VARCHAR2(240);
    l_header_att6                 VARCHAR2(240);
    l_header_att7                 VARCHAR2(240);
    l_header_att8                 VARCHAR2(240);
    l_header_att9                 VARCHAR2(240);
    l_header_att10                VARCHAR2(240);
    l_header_att11                VARCHAR2(240);
    l_header_att12                VARCHAR2(240);
    l_header_att13                VARCHAR2(240);
    l_header_att14                VARCHAR2(240);
    l_header_att15                VARCHAR2(240);
    l_line_att1                   VARCHAR2(240);
    l_line_att2                   VARCHAR2(240);
    l_line_att3                   VARCHAR2(240);
    l_line_att4                   VARCHAR2(240);
    l_line_att5                   VARCHAR2(240);
    l_line_att6                   VARCHAR2(240);
    l_line_att7                   VARCHAR2(240);
    l_line_att8                   VARCHAR2(240);
    l_line_att9                   VARCHAR2(240);
    l_line_att10                  VARCHAR2(240);
    l_line_att11                  VARCHAR2(240);
    l_line_att12                  VARCHAR2(240);
    l_line_att13                  VARCHAR2(240);
    l_line_att14                  VARCHAR2(240);
    l_line_att15                  VARCHAR2(240);
    l_shipment_att1               VARCHAR2(240);
    l_shipment_att2               VARCHAR2(240);
    l_shipment_att3               VARCHAR2(240);
    l_shipment_att4               VARCHAR2(240);
    l_shipment_att5               VARCHAR2(240);
    l_shipment_att6               VARCHAR2(240);
    l_shipment_att7               VARCHAR2(240);
    l_shipment_att8               VARCHAR2(240);
    l_shipment_att9               VARCHAR2(240);
    l_shipment_att10              VARCHAR2(240);
    l_shipment_att11              VARCHAR2(240);
    l_shipment_att12              VARCHAR2(240);
    l_shipment_att13              VARCHAR2(240);
    l_shipment_att14              VARCHAR2(240);
    l_shipment_att15              VARCHAR2(240);
    l_distribution_att1           VARCHAR2(240);
    l_distribution_att2           VARCHAR2(240);
    l_distribution_att3           VARCHAR2(240);
    l_distribution_att4           VARCHAR2(240);
    l_distribution_att5           VARCHAR2(240);
    l_distribution_att6           VARCHAR2(240);
    l_distribution_att7           VARCHAR2(240);
    l_distribution_att8           VARCHAR2(240);
    l_distribution_att9           VARCHAR2(240);
    l_distribution_att10          VARCHAR2(240);
    l_distribution_att11          VARCHAR2(240);
    l_distribution_att12          VARCHAR2(240);
    l_distribution_att13          VARCHAR2(240);
    l_distribution_att14          VARCHAR2(240);
    l_distribution_att15          VARCHAR2(240);
    l_fb_error_msg                VARCHAR2(1000);
    l_etape                       VARCHAR2(100);
    
    l_transaction_flow_header_id  NUMBER;
    l_dest_charge_success         BOOLEAN;
    l_dest_variance_success       BOOLEAN;
    l_dest_charge_account_id      NUMBER;
    l_dest_variance_account_id    NUMBER;
    l_dest_charge_account_desc    VARCHAR2(240);
    l_dest_variance_account_desc  VARCHAR2(240);
    l_dest_charge_account_flex    VARCHAR2(240);
    l_dest_variance_account_flex  VARCHAR2(240);
  BEGIN
    l_etape := 'Début :';
    
    l_bom_cost_element_id   := NULL;
    l_from_type_lookup_code := NULL;
    l_from_header_id        := NULL;
    l_from_line_id          := NULL;
    l_wip_entity_type       := NULL;

    l_etape := 'Récuperation coa_id :';
    
/*    SELECT chart_of_accounts_id
      INTO l_coa_id
      FROM gl_sets_of_books
     WHERE set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID');*/
     
    SELECT GSB.CHART_OF_ACCOUNTS_ID
    INTO   l_coa_id
    FROM gl_sets_of_books gsb,
         hr_organization_information hoi,
         MTL_PARAMETERS MP
    WHERE mp.organization_id = pn_org_id
      AND mp.organization_id = hoi.organization_id
      AND HOI.ORG_INFORMATION_CONTEXT = 'Accounting Information'
      AND TO_NUMBER(hoi.org_information1) = gsb.set_of_books_id;

    l_etape := 'Récuperation category_id :';
    SELECT category_id
      INTO l_category_id
      FROM mtl_categories_kfv
     WHERE concatenated_segments = pv_nature_prestation AND structure_id = 201;
    
    l_etape := 'Récuperation line_type_id :';
    SELECT line_type_id
      INTO l_line_type_id
      FROM po_line_types_all_v
     WHERE line_type = cst_type_ligne;
    
    l_etape := 'Récuperation project_id et task_id :';
    SELECT pp.project_id, pt.task_id
      INTO l_project_id, l_task_id
      FROM pa_projects_all pp, pa_tasks pt
     WHERE pt.project_id = pp.project_id 
     AND pt.task_id = pn_task_id -- RBE MigR12
     AND pp.project_id = pn_project_id;

    l_etape := 'Récuperation agent_id et expenditure_organization_id :';
    SELECT papf.person_id, paaf.organization_id 
      INTO l_agent_id, l_expenditure_organization_id
      FROM --per_all_people_f papf  -- RBE artf2376255
           per_people_f papf -- RBE artf2376255 --artf3025989
         , per_all_assignments_f paaf
     WHERE paaf.person_id = papf.person_id
       AND papf.person_id = pn_signataire_id          
       AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND NVL(papf.effective_end_date,SYSDATE)  -- RBE artf3025989
       AND TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date) AND NVL(paaf.effective_end_date,SYSDATE); -- RBE
    
    l_etape := 'Appel po_wf_build_account_init.start_workflow :';
    -- Call the function
    result := po_wf_build_account_init.start_workflow(x_purchasing_ou_id            => pn_org_id,  --RBE artf2187880 
                                                      x_transaction_flow_header_id  => l_transaction_flow_header_id,
                                                      x_dest_charge_success         => l_dest_charge_success,
                                                      x_dest_variance_success       => l_dest_variance_success,
                                                      x_dest_charge_account_id      => l_dest_charge_account_id,
                                                      x_dest_variance_account_id    => l_dest_variance_account_id,
                                                      x_dest_charge_account_desc    => l_dest_charge_account_desc,
                                                      x_dest_variance_account_desc  => l_dest_variance_account_desc,
                                                      x_dest_charge_account_flex    => l_dest_charge_account_flex,
                                                      x_dest_variance_account_flex  => l_dest_variance_account_flex,
                                                      x_charge_success              => l_charge_success,
                                                      x_budget_success              => l_budget_success,
                                                      x_accrual_success             => l_accrual_success,
                                                      x_variance_success            => l_variance_success,
                                                      x_code_combination_id         => l_code_combination_id,
                                                      x_budget_account_id           => l_budget_account_id,
                                                      x_accrual_account_id          => l_accrual_account_id,
                                                      x_variance_account_id         => l_variance_account_id,
                                                      x_charge_account_flex         => l_charge_account_flex,
                                                      x_budget_account_flex         => l_budget_account_flex,
                                                      x_accrual_account_flex        => l_accrual_account_flex,
                                                      x_variance_account_flex       => l_variance_account_flex,
                                                      x_charge_account_desc         => l_charge_account_desc,
                                                      x_budget_account_desc         => l_budget_account_desc,
                                                      x_accrual_account_desc        => l_accrual_account_desc,
                                                      x_variance_account_desc       => l_variance_account_desc,
                                                      x_coa_id                      => l_coa_id,
                                                      x_bom_resource_id             => l_bom_resource_id,
                                                      x_bom_cost_element_id         => l_bom_cost_element_id,
                                                      x_category_id                 => l_category_id,
                                                      x_destination_type_code       => 'EXPENSE',
                                                      x_deliver_to_location_id      => l_deliver_to_location_id,
                                                      x_destination_organization_id => pn_org_id,
                                                      x_destination_subinventory    => l_destination_subinventory,
                                                      x_expenditure_type            => pv_expenditure_type,
                                                      x_expenditure_organization_id => l_expenditure_organization_id,
                                                      x_expenditure_item_date       => trunc(SYSDATE), -- CDE 080910 SYSDATE,
                                                      x_item_id                     => l_item_id,
                                                      x_line_type_id                => l_line_type_id,
                                                      x_result_billable_flag        => 'N',
                                                      x_agent_id                    => l_agent_id,
                                                      x_project_id                  => l_project_id,
                                                      x_from_type_lookup_code       => l_from_type_lookup_code,
                                                      x_from_header_id              => l_from_header_id,
                                                      x_from_line_id                => l_from_line_id,
                                                      x_task_id                     => l_task_id,
                                                      x_deliver_to_person_id        => l_deliver_to_person_id,
                                                      x_type_lookup_code            => 'STANDARD',
                                                      x_vendor_id                   => pn_vendor_id,
                                                      x_wip_entity_id               => l_wip_entity_id,
                                                      x_wip_entity_type             => l_wip_entity_type,
                                                      x_wip_line_id                 => l_wip_line_id,
                                                      x_wip_repetitive_schedule_id  => l_wip_repetitive_schedule_id,
                                                      x_wip_operation_seq_num       => l_wip_operation_seq_num,
                                                      x_wip_resource_seq_num        => l_wip_resource_seq_num,
                                                      x_po_encumberance_flag        => 'N',
                                                      x_gl_encumbered_date          => l_gl_encumbered_date,
                                                      wf_itemkey                    => l_wf_itemkey,
                                                      x_new_combination             => l_new_combination,
                                                      header_att1                   => l_header_att1,
                                                      header_att2                   => l_header_att2,
                                                      header_att3                   => l_header_att3,
                                                      header_att4                   => l_header_att4,
                                                      header_att5                   => l_header_att5,
                                                      header_att6                   => l_header_att6,
                                                      header_att7                   => l_header_att7,
                                                      header_att8                   => l_header_att8,
                                                      header_att9                   => l_header_att9,
                                                      header_att10                  => l_header_att10,
                                                      header_att11                  => l_header_att11,
                                                      header_att12                  => l_header_att12,
                                                      header_att13                  => l_header_att13,
                                                      header_att14                  => l_header_att14,
                                                      header_att15                  => l_header_att15,
                                                      line_att1                     => l_line_att1,
                                                      line_att2                     => l_line_att2,
                                                      line_att3                     => l_line_att3,
                                                      line_att4                     => l_line_att4,
                                                      line_att5                     => l_line_att5,
                                                      line_att6                     => l_line_att6,
                                                      line_att7                     => l_line_att7,
                                                      line_att8                     => l_line_att8,
                                                      line_att9                     => l_line_att9,
                                                      line_att10                    => l_line_att10,
                                                      line_att11                    => l_line_att11,
                                                      line_att12                    => l_line_att12,
                                                      line_att13                    => l_line_att13,
                                                      line_att14                    => l_line_att14,
                                                      line_att15                    => l_line_att15,
                                                      shipment_att1                 => l_shipment_att1,
                                                      shipment_att2                 => l_shipment_att2,
                                                      shipment_att3                 => l_shipment_att3,
                                                      shipment_att4                 => l_shipment_att4,
                                                      shipment_att5                 => l_shipment_att5,
                                                      shipment_att6                 => l_shipment_att6,
                                                      shipment_att7                 => l_shipment_att7,
                                                      shipment_att8                 => l_shipment_att8,
                                                      shipment_att9                 => l_shipment_att9,
                                                      shipment_att10                => l_shipment_att10,
                                                      shipment_att11                => l_shipment_att11,
                                                      shipment_att12                => l_shipment_att12,
                                                      shipment_att13                => l_shipment_att13,
                                                      shipment_att14                => l_shipment_att14,
                                                      shipment_att15                => l_shipment_att15,
                                                      distribution_att1             => l_distribution_att1,
                                                      distribution_att2             => l_distribution_att2,
                                                      distribution_att3             => l_distribution_att3,
                                                      distribution_att4             => l_distribution_att4,
                                                      distribution_att5             => l_distribution_att5,
                                                      distribution_att6             => l_distribution_att6,
                                                      distribution_att7             => l_distribution_att7,
                                                      distribution_att8             => l_distribution_att8,
                                                      distribution_att9             => l_distribution_att9,
                                                      distribution_att10            => l_distribution_att10,
                                                      distribution_att11            => l_distribution_att11,
                                                      distribution_att12            => l_distribution_att12,
                                                      distribution_att13            => l_distribution_att13,
                                                      distribution_att14            => l_distribution_att14,
                                                      distribution_att15            => l_distribution_att15,
                                                      fb_error_msg                  => l_fb_error_msg);

    l_etape := 'Fin po_wf_build_account_init.start_workflow :';
    IF NOT l_charge_success
    THEN
      pv_err_msg  := l_fb_error_msg;
      pn_retcode := 2;
    ELSE
      pn_ccid          := l_code_combination_id;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_err_msg  := 'GET_CCID =>' || l_etape || SQLERRM;
  END get_ccid;

--------------------------------------------------------------------------------
--  Nom           : get_contrat_end_date
--  Description   : Procédure de calcul de la date de fin du contrat
--  PARAMETRES    :
--                     pn_header_id         : Id du contrat
--                     pd_end_date          : Date fin de période
--                     pn_nb_reconduction   : Nombre de reconduction
--                     pn_reconduction_num  : Numéro de reconduction
--                     pd_contrat_end_date  : Date de fin du contrat
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_contrat_end_date(pn_header_id          IN  NUMBER,
                                   pd_end_date           IN  DATE,
                                   pn_nb_reconduction    IN  NUMBER,
                                   pn_reconduction_num   IN  NUMBER,
                                   pd_contrat_end_date   OUT DATE,
                                   pn_retcode            OUT NUMBER,
                                   pv_err_msg            OUT VARCHAR2)
    IS
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN

           -- Détermination de la date de fin du contrat
           IF sign(nvl(pn_nb_reconduction,0) - nvl(pn_reconduction_num,0)) = -1
           THEN
               pd_contrat_end_date := pd_end_date;
           ELSE
               pd_contrat_end_date := add_months(pd_end_date, (nvl(pn_nb_reconduction,0) - nvl(pn_reconduction_num,0))*12);
           END IF;
                  
        EXCEPTION
        WHEN OTHERS THEN
           pd_contrat_end_date := NULL;
           pv_err_msg := 'Erreur dans la détermination de la date de fin du contrat';
           pn_retcode := 2;
        END;
        
    END get_contrat_end_date; 

--------------------------------------------------------------------------------
--  Nom           : get_contrat_start_date
--  Description   : Procédure de calcul de la date de début du contrat
--  PARAMETRES    :
--                     pn_header_id         : Id du contrat
--                     pd_start_date        : Date début de période
--                     pn_reconduction_num  : Numéro de reconduction
--                     pd_contrat_start_date: Date de début du contrat
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_contrat_start_date(pn_header_id          IN  NUMBER,
                                     pd_start_date         IN  DATE,
                                     pn_reconduction_num   IN  NUMBER,
                                     pd_contrat_start_date OUT DATE,
                                     pn_retcode            OUT NUMBER,
                                     pv_err_msg            OUT VARCHAR2)
    IS
    BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;

        BEGIN

           -- Détermination de la date de début du contrat
           IF pn_reconduction_num = 0
           THEN
               pd_contrat_start_date := pd_start_date;
           ELSE
               BEGIN
                    SELECT phaa.start_date 
                    INTO pd_contrat_start_date
                    FROM po_headers_archive_all phaa
                    WHERE phaa.revision_num = (SELECT MAX(dcsa.revision_num) 
                                               FROM dka_contrat_sstr_archi dcsa
                                               WHERE dcsa.reconduction_num = 0
                                               AND dcsa.po_header_id = phaa.po_header_id)
                    AND phaa.po_header_id = pn_header_id;
               EXCEPTION
               WHEN NO_DATA_FOUND THEN   
                    pd_contrat_start_date := pd_start_date;        
               END;
           END IF;


                  
        EXCEPTION
        WHEN OTHERS THEN
           pd_contrat_start_date := NULL;
           pv_err_msg := 'Erreur dans la détermination de la date de début du contrat';
           pn_retcode := 2;
        END;
        
    END get_contrat_start_date;  

-- 24-AOU-17  NBO       artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD    
--------------------------------------------------------------------------------
--  Nom           : get_numcommande
--  Description   : Procédure de récupértion du numéro de commande
--  PARAMETRES    :
--                     pv_numcommande           : Numéro de commande
--------------------------------------------------------------------------------
    PROCEDURE get_numcommande(pv_numcommande OUT VARCHAR2)
    IS
    BEGIN 
  
      select DKA.DKA_CONTRAT_SSTR_NUM.nextval into pv_numcommande from dual;
      
    EXCEPTION
    WHEN OTHERS THEN
       pv_numcommande := NULL;
    END get_numcommande;  
	
	
---ARA EDB364 
--------------------------------------------------------------------------------
--  Nom           : get_info_region
--  Description   : Procédure de récupértion de la région du contrat

--------------------------------------------------------------------------------
PROCEDURE get_info_region (pn_orgid      IN     NUMBER,
                             pn_verify      OUT NUMBER,
							 pn_entity  OUT VARCHAR2,
							 pv_err_msg            OUT VARCHAR2)
    IS
	
	vv_region_value VARCHAR2(10);
	
	
	CURSOR c1 IS
	
	Select VARCHAR2_value
	FROM   AK_WEB_USER_SEC_ATTR_VALUES ATTRIBUT,
	FND_APPLICATION APPLI 
	WHERE attribut.WEB_USER_ID = fnd_global.user_id
	AND attribut.ATTRIBUTE_CODE = 'DKA_CONTRAT_SSTR_REGION' 
	AND ATTRIBUT.ATTRIBUTE_APPLICATION_ID = APPLI.APPLICATION_ID
	AND appli.APPLICATION_SHORT_NAME= 'ICX';
			
    BEGIN

		BEGIN
			select substr(name,0,3)
			into vv_region_value
			FROM hr_operating_units
			WHERE organization_id = pn_orgid;
		
		EXCEPTION
		WHEN OTHERS THEN 
		pv_err_msg := 'Erreur dans la détermination de la region selectionee : ' || pn_orgid;  
		END;
		
		
		pn_entity := vv_region_value;
		
		pn_verify := 0;
		
		FOR rec in c1 LOOP
		
			IF vv_region_value = rec.VARCHAR2_value THEN
				pn_verify := 1;
			END IF;
		
		END LOOP;
        
    END get_info_region; 
	
---ARA EDB364 
--------------------------------------------------------------------------------
--  Nom           : get_info_org
--  Description   : Procédure de récupértion de l'orgid du contrat

--------------------------------------------------------------------------------
PROCEDURE get_info_org (pn_idcontrat      IN     NUMBER,
                             pn_orgidcontrat      OUT NUMBER)
	IS
	BEGIN
		BEGIN
		select org_id 
		into pn_orgidcontrat
		from po_headers_all 
		where po_header_id = pn_idcontrat;
		END;

	END get_info_org; 


END DKA_SPOCONTRAT_SSTR_PKG;
/
SHOW ERRORS;

EXIT
