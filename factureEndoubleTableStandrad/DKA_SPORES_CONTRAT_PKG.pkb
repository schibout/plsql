CREATE OR REPLACE PACKAGE BODY dka_spasinistre_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPASINISTRE_PKG.pks
-- DESCRIPTION       : DKA_SPASINISTRE_PKG package body : CCA sur sinistre hors automobile
---
--- AUTEUR           :Hassan CHRAOUI(CGEY)
--- DATE DE CREATION : 08/10/2001
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 07/12/2001 HCH Mise aux normes
--- 27/02/2002 XD  Suppression du traitement des couts indirects (évolution future)
--- 22/11/2002 EB  Modification de la gestion des statuts cloturé et actif.
--- 14/10/2003 AD  GL_OPEN_INTERFACE : Ajout de la procédure standard fnd_concurent.wait_for_request.
---                On attend la fin de l'easylink avant celle du specifque.
--  04/04/2004 GL  Calcul des CCA sur sinistres "hors automobile" et des extournes associées
--                 Gestion de la table spécifique DKA_SPASINISTRE_TMP
--  25/05/2005 NB  Modification pour prise en compte EID20050030 ( Refonte suite reprise PHENIX 2004 )
--  02/08/2005 TB  Suppression des process inutiles
--                 + process_active_projects : Correction des conditions de calcul des CCA
--- 03/12/2007 ADR ETANCHEITE DALKIA 2007
--- 16/11/2016 NBO Migration R12
--  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
--                 artf2059187 - Mauvais calcul de la date du mouvement et date GL
--  03/01/2017 NBO artf2073155 - SPE051 - Fourchette de dates pour la sélection des mouvements
--  11/04/2018 JJA artf2516146 - Modification du contrôle de la date de clôture
---------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gv_event_type_etat_frais         dka_parameters.varchar2_value%TYPE;
    gv_event_type_cca                dka_parameters.varchar2_value%TYPE;
    gv_event_type_extourne_cca       dka_parameters.varchar2_value%TYPE;
    gv_event_type_ccai               dka_parameters.varchar2_value%TYPE;
    gv_event_type_extourne_ccai      dka_parameters.varchar2_value%TYPE;
    gv_project_type_sinistre_class   dka_parameters.varchar2_value%TYPE;
    gv_status_code_actif             dka_parameters.varchar2_value%TYPE;
    gv_status_code_inactif           dka_parameters.varchar2_value%TYPE;
    gv_gl_resp_key                   dka_parameters.varchar2_value%TYPE;
    gv_gl_batch_name                 dka_parameters.varchar2_value%TYPE;
    gv_attribute_category            VARCHAR2 (3);
    -- GL
    gv_request_id                    fnd_concurrent_requests.request_id%TYPE   := 0;
    gv_created_by                    fnd_user.user_id%TYPE                     := 0;
    gv_last_updated_by               fnd_user.user_id%TYPE                     := 0;
    gv_last_update_login             fnd_logins.login_id%TYPE                  := 0;
    gv_period_name                   gl_period_statuses.period_name%TYPE;
    gv_period_extourne               gl_period_statuses.period_name%TYPE;
    /* ETANCHEITE DALKIA 2007 */
    --  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
    --gn_org_id                        NUMBER := fnd_global.org_id; --TO_NUMBER(fnd_profile.VALUE('ORG_ID'));
    gn_org_id                        NUMBER := MO_GLOBAL.get_current_org_id;

    gv_org_name                      VARCHAR2(100);
    --- 16/11/2016 NBO Migration R12 - Récupère l'ttribut de sécurité
    --gn_sob                           NUMBER := TO_NUMBER(fnd_profile.VALUE('GL_SET_OF_BKS_ID'));
    gn_sob                           NUMBER; --:= TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R'));


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
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
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
        --pn_result   NUMBER;
        --l_org_id NUMBER;
    BEGIN
        --Initialisation des Variables de sortie de la Procédure:
        pv_errbuf                         := NULL;
        pn_retcode                         := 0;
        -- Initialisation des fichiers de journal (log) et de sortie (out)
        -- pour éviter un Commit en cours de traitement
        -- Appel à la procédure commune d'initialisation de l'état de sortie
        dka_tools_pkg.put_out_header;
        --Initialisation des variables
        gv_request_id                     := fnd_profile.VALUE ('CONC_REQUEST_ID');

        IF NVL (gv_request_id, 0) = 0
        THEN
            pn_retcode    := 1;
            pv_errbuf     := 'request_id non trouvé';
            RETURN;
        END IF;
        
        
        dka_tools_pkg.put_log_message('gn_org_id : ' || gn_org_id);

        IF gn_org_id IS NULL OR gn_org_id = -1 THEN
          dka_tools_pkg.put_log_message('L''option de profil 1_MO:Unité opérationnelle n''est pas paramétrée');
          pv_errbuf := 'L''option de profil 1_MO:Unité opérationnelle n''est pas paramétrée';
          pn_retcode := 2;
          RETURN;
        END IF;

        --  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
        select set_of_books_id, name INTO gn_sob, gv_org_name from hr_operating_units where organization_id = gn_org_id;

        IF gn_sob IS NULL THEN
          dka_tools_pkg.put_log_message('L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétrée');
          pv_errbuf := 'L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétrée';
          pn_retcode := 2;
          RETURN;
        END IF;

        gv_created_by                     := fnd_profile.VALUE ('USER_ID');
        gv_last_updated_by                := fnd_profile.VALUE ('USER_ID');
        gv_last_update_login              := fnd_profile.VALUE ('LOGIN_ID');

        --Calcul de la Date de Fin:
        IF pv_period_name IS NOT NULL --GL
        THEN
            gv_period_name    := pv_period_name;
            
            --  03/01/2017 NBO artf2073155 - SPE051 - Fourchette de dates pour la sélection des mouvements
            SELECT pap.start_date
	          INTO pd_from_date
	          FROM pa_periods pap
   	        WHERE pap.period_name = pv_period_name;

            --artf2516146
            pd_to_date        := pa_utils.get_pa_end_date (pv_period_name);

            dka_tools_pkg.put_log_message('pa_end_date : ' || pd_to_date);

            --calcul de la date comptable d'extourne  --GL
            BEGIN
                SELECT period_name
                INTO   gv_period_extourne
                FROM   gl_period_statuses gps
                --- 16/11/2016 NBO Migration R12
                WHERE  gps.set_of_books_id = gn_sob
                       AND gps.application_id = 101
                       AND effective_period_num = (SELECT MIN (gps2.effective_period_num)
                                                   FROM   gl_period_statuses gps2,
                                                          gl_period_statuses gps3
                                                   WHERE      gps2.effective_period_num > gps3.effective_period_num
                                                          AND gps2.set_of_books_id = gps3.set_of_books_id
                                                          AND gps2.application_id = gps3.application_id
                                                          AND gps3.set_of_books_id = gps.set_of_books_id
                                                          AND gps3.application_id = gps.application_id
                                                          AND gps3.period_name = gv_period_name);
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    pn_retcode    := 2;
                    pv_errbuf     := 'PERIODE_SUIVANTE - NON TROUVEE ' || pv_errbuf;
                    RETURN;
                WHEN OTHERS
                THEN
                    pn_retcode    := 2;
                    pv_errbuf     := 'PERIODE_SUIVANTE - ERREUR INCONNUE ' || pv_errbuf;
                    RETURN;
            END;
        END IF;

        --calcul du group_id:
        SELECT gl_interface_control_s.NEXTVAL
        INTO   pn_group_id
        FROM   DUAL;

        --Recupération de l'ensemble des Paramètres stockés dans la Table dka_parameters:
        dka_tools_pkg.put_log_message ('PROC_INIT:Initialisation des variables de sortie');
        dka_tools_pkg.get_parameter ('SPASINISTRE', 'PROJECT_TYPE_SINISTRE_CLASS', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_sinistre_class    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PROJECT_TYPE_SINISTRE_CLASS - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'EVENT_TYPE_ETAT_FRAIS', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_etat_frais          := rec_param.varchar2_value;

        dka_tools_pkg.put_log_message ('gv_event_type_etat_frais='||gv_event_type_etat_frais);



        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_ETAT_FRAIS - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'EVENT_TYPE_CCA', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_cca                 := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_CCA - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'EVENT_TYPE_EXTOURNE_CCA', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_extourne_cca        := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_EXTOURNE_CCA - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'EVENT_TYPE_CCAI', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_ccai                := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_CCAI - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'EVENT_TYPE_EXTOURNE_CCAI', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_extourne_ccai       := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_EXTOURNE_CCAI - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'STATUS_CODE_ACTIF', rec_param, pn_retcode, pv_errbuf);
        gv_status_code_actif              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STATUS_CODE_ACTIF - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'STATUS_CODE_INACTIF', rec_param, pn_retcode, pv_errbuf);
        gv_status_code_inactif            := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STATUS_CODE_INACTIF - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'GL_RESP_KEY', rec_param, pn_retcode, pv_errbuf);
        gv_gl_resp_key                    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GL_RESP_KEY - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'GL_BATCH_NAME', rec_param, pn_retcode, pv_errbuf);
        gv_gl_batch_name                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GL_BATCH_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPASINISTRE', 'ATTRIBUTE_CATEGORY', rec_param, pn_retcode, pv_errbuf);
        gv_attribute_category             := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'ATTRIBUTE_CATEGORY - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_INIT: Fin de Recuperation de  L''ensemble des Parametres utiliser par le Traitement');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END init;


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
    )
    IS
    BEGIN
        dka_tools_pkg.put_debug_message ('PROC_CLEAR_SPASINISTRE_TMP:Initialisation des variables de sortie');
        pv_errbuf    := NULL;
        pn_result    := 0;
        dka_tools_pkg.put_debug_message ('Purger la Table de Travail DKA_SPASINISTRE_TMP');

        DELETE      dka_spasinistre_tmp
        WHERE       reversal_flag = 'Y'; --GL
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;
    END clear_spasinistre_tmp;


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
        pn_task_id   IN   NUMBER, --RGH
        pv_line_type    IN   VARCHAR2,
        pd_from_date    IN   DATE,
        pd_to_date      IN   DATE
    )
    -- remplacer pn_project_id par pn_task_id  --RGH
        RETURN NUMBER
    IS
        vn_cost_amount   NUMBER;
    BEGIN
        --dka_tools_pkg.put_debug_message('FC_GET_SUM_CHARGES: Début - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        SELECT SUM (NVL (pcdl.amount, 0))
        INTO   vn_cost_amount
        FROM   pa_cost_distribution_lines/*_all*/ pcdl,
               pa_expenditure_items/*_all*/ pei,
               pa_expenditure_types pet
        WHERE      -- pcdl.project_id = pn_project_id  --RGH
               pcdl.task_id = pn_task_id            --RGH
               AND pcdl.transfer_status_code IN ('A', 'V')
               AND pcdl.line_type = pv_line_type
               AND pet.attribute2 = 'Y'
               --  03/01/2017 NBO artf2073155 - SPE051 - Fourchette de dates pour la sélection des mouvements
               --AND pcdl.gl_date BETWEEN TRUNC (pd_to_date, 'MONTH') AND LAST_DAY (pd_to_date)
			   AND pcdl.gl_date BETWEEN pd_from_date AND pd_to_date
               AND pet.expenditure_type = pei.expenditure_type
               AND pei.expenditure_item_id = pcdl.expenditure_item_id;

        --dka_tools_pkg.put_debug_message('FC_GET_SUM_CHARGES: Fin - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

        IF vn_cost_amount IS NULL
        THEN
            vn_cost_amount    := 0;
        END IF;

        dka_tools_pkg.put_debug_message (
               'FC_GET_SUM_CHARGES: Calcul de la somme des charges sur le TASK_ID '
            || TO_CHAR (pn_task_id)
            || ' -> '
            || TO_CHAR (vn_cost_amount)
        );
        RETURN vn_cost_amount;
    END get_sum_charges;


----------------------------------------------------------------------------------------
--  Auteur        : GL
--  Nom           : PA_GET_SUM_EVENT_REVENUE ( pn_project_id    IN      VARCHAR2,
--  Description   : Procédure permettant de déterminer le montant du revenu sur un projet
--                  sur le type d'évènement passé en paramètre
--  PARAMETRES :
--    pn_project_id     Entrée
--    pd_to_gl_date     Entrée
--    pv_event_type     Entrée
--    pn_revenue_amount Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE pa_get_sum_event_revenue (
        pn_task_id       IN       VARCHAR2, --RGH
        pd_from_gl_date     IN       DATE,
        pd_to_gl_date       IN       DATE,
        pv_event_type       IN       VARCHAR2,
        pn_revenue_amount   OUT      NUMBER,
        pv_errbuf           OUT      VARCHAR2,
        pn_retcode          OUT      NUMBER
    )
    -- remplacer pn_project_id par pn_task_id  --RGH
    IS
    BEGIN
        -- Initialisation des variables de sortie
        pn_retcode           := 0;
        pv_errbuf            := NULL;
        pn_revenue_amount    := NULL;

        -- Calcul de la somme des revenus
        SELECT NVL (SUM (NVL (pe.revenue_amount, 0)), 0)
        INTO   pn_revenue_amount
        FROM   pa_events pe,
               pa_cust_event_rdl_all pcer,
               pa_draft_revenues/*_all*/ pdr /* ETANCHEITE DALKIA 2007 */
        WHERE      -- pe.project_id = pn_project_id --RGH
               pe.task_id = pn_task_id  --RGH
               AND pe.event_type = pv_event_type
               AND pcer.project_id = pe.project_id
               AND NVL (pcer.task_id, -1) = NVL (pe.task_id, -1)
               AND pcer.event_num = pe.event_num
               AND pdr.project_id = pcer.project_id
               AND pdr.ORG_ID = pcer.org_id /* ENTANCHEITE DALKIA 2007*/
               AND pdr.draft_revenue_num = pcer.draft_revenue_num
               AND pdr.transfer_status_code = 'A'
               --  03/01/2017 NBO artf2073155 - SPE051 - Fourchette de dates pour la sélection des mouvements
               --AND pdr.gl_date BETWEEN TRUNC (pd_to_gl_date, 'MONTH') AND LAST_DAY (pd_to_gl_date);
               AND pdr.gl_date BETWEEN pd_from_gl_date AND pd_to_gl_date;

        dka_tools_pkg.put_debug_message ('PA_GET_SUM_EVENT_REVENUE - '|| pv_event_type || ' -> ' || TO_CHAR (pn_revenue_amount));
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'PA_GET_SUM_EVENT_REVENUE - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END pa_get_sum_event_revenue;


------------------------------------------------------------------------------------
--  Nom           : process_active_tasks
--  Description   : traiter les tâches de type 'SINISTRE ASSURE' en statu 'Actif'.
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
    )
    IS
        --Déclaration du curseur ramenant les Projets à traiter:

        --- 16/11/2016 NBO Migration R12
        CURSOR active_tasks_cur
        IS
            SELECT pp.segment1,
                   pp.project_id,
                   pt.task_id,             -- RGH
                   pt.task_number          -- RGH
            FROM   pa_projects/*_all */       pp,
                   pa_implementations/*_all*/ pi,
                   pa_tasks               pt
            WHERE  pp.project_id              = pt.project_id               -- RGH
                   -- pp.project_type = gv_project_type_sinistre_class      -- RGH
                   AND substr(pt.task_number,2,1) = 'S'
                   --AND pp.project_status_code = gv_status_code_actif             -- EB
                   /*
                   AND (   fnd_date.canonical_to_date (pp.attribute8) > pd_to_date -- EB
                        OR pp.attribute8 IS NULL
                       ) -- EB
                   */ --RGH
                   AND ( pt.attribute2 IS NULL OR fnd_date.canonical_to_date (pt.attribute2) > LAST_DAY(pd_to_date) -- RGH --artf2516146

                   )
                   AND pp.org_id = pi.org_id
                   -- AND pi.set_of_books_id = TO_NUMBER (fnd_profile.VALUE ('GL_SET_OF_BKS_ID')) -- RGH
                   ;




        active_tasks_rec   active_tasks_cur%ROWTYPE;
        vd_completion_date    DATE;
        vn_charges            NUMBER;
        vn_etats_frais        NUMBER;
        vn_cca                NUMBER;
        vn_cca_extourne       NUMBER;
        --vn_ccai               NUMBER;
        --vn_extournes_ccai     NUMBER;
        vn_event_amount       NUMBER;
        vn_result             NUMBER;
        vv_error_message      VARCHAR2 (2000);
    BEGIN
        pv_errbuf    := NULL;
        pn_result    := 0;
        dka_tools_pkg.put_debug_message ('PROC_ACTIVE_TASKS:Initialisation des variables de sortie');

        --  09/12/2016 NBO artf2059187 - Mauvais calcul de la date du mouvement et date GL
        --Calcul de la date des évenements:
        --SELECT LAST_DAY (pd_to_date)
        --INTO   vd_completion_date
        --FROM   DUAL;
        -- artf2059187 - SPE051 - Mauvais calcul de la date du mouvement et date GL
        vd_completion_date := pd_to_date;

        dka_tools_pkg.put_debug_message (
            --'PROC_ACTIVE_PROJECTS: Début Traitement des projets de type SINISTRE ASSURE en statut actif' --RGH
            'PROC_ACTIVE_TASKS: Début Traitement des tâches de type SINISTRE en statut actif'
        );
        --Ouvrir le curseur et boucler:
        --- 16/11/2016 NBO Migration R12
        OPEN active_tasks_cur;

        LOOP
            dka_tools_pkg.put_debug_message ('Avant le BEGIN');
            vn_result           := 0;
            vv_error_message    := NULL;
            FETCH active_tasks_cur INTO active_tasks_rec;
            EXIT WHEN active_tasks_cur%NOTFOUND;
            SAVEPOINT point_arret;

            dka_tools_pkg.put_debug_message ('Apres le SAVEPOINT');

            DECLARE
                e_error   EXCEPTION;
            BEGIN
                dka_tools_pkg.put_debug_message ('*****************************************************************************');
                dka_tools_pkg.put_debug_message ('project_id:' || active_tasks_rec.project_id); --RGH TST
                dka_tools_pkg.put_debug_message ('task_id : ' || active_tasks_rec.task_id);    --RGH TST
                BEGIN
                    --Calcul du Cumul des Charges:
                    vn_charges    := dka_spasinistre_pkg.get_sum_charges (active_tasks_rec.task_id, 'R', pd_from_date, pd_to_date);
                    --RGH : remplacer project_id par task_id
                    dka_tools_pkg.put_debug_message ('charge : ' || vn_charges); --RGH TST
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        pn_result    := SQLCODE;
                        pv_errbuf    := 'GET_SUM_CHARGES - ' || SQLERRM;
                        RETURN;
                END;

                --Calcul des Cumul des états de frais:
                dka_spasinistre_pkg.pa_get_sum_event_revenue (
                    active_tasks_rec.task_id, --RGH
                    pd_from_date,
                    pd_to_date,
                    gv_event_type_etat_frais,
                    vn_etats_frais,
                    pv_errbuf,
                    vn_result
                );
                --RGH : remplacer project_id par task_id

                IF vn_result != 0
                THEN
                    --- 16/11/2016 NBO Migration R12
                    vv_error_message    :=    'Rejet pour le calcul des Cumul des etats de frais sur le projet : '
                                           || active_tasks_rec.segment1
                                           || ' et la tâche : '  -- RGH
                                           || active_tasks_rec.task_number                                   -- RGH
                                           || ' sur le type d''evenement '
                                           || gv_event_type_cca
                                           || ' pour le montant '
                                           || vn_event_amount
                                           || ' avec l''erreur '
                                           || pv_errbuf;
                    RAISE e_error;
                END IF;

                --Calcul des Cumul des CCA sur sinitres sur la période en paramètre:
                dka_tools_pkg.put_debug_message ('calcul : '|| gv_event_type_extourne_cca);
                dka_spasinistre_pkg.pa_get_sum_event_revenue (
                    active_tasks_rec.task_id, --RGH
                    pd_from_date,
                    pd_to_date,
                    gv_event_type_extourne_cca,
                    vn_cca_extourne,
                    pv_errbuf,
                    vn_result
                );
                --RGH : remplacer project_id par task_id
                IF vn_result != 0
                THEN
                    dka_tools_pkg.put_debug_message ('vn_result:' || vn_result);
                    --- 16/11/2016 NBO Migration R12
                    vv_error_message    := 'Rejet pour le calcul des Cumul des CCA sur le projet : '
                                           || active_tasks_rec.segment1
                                           || ' et la tâche : '  -- RGH
                                           || active_tasks_rec.task_number                     -- RGH
                                           || ' sur le type d''evenement '
                                           || gv_event_type_extourne_cca
                                           || ' pour le montant '
                                           || vn_event_amount
                                           || ' avec l''erreur '
                                           || pv_errbuf;
                    RAISE e_error;
                END IF;

                --Calcul des Cumul des CCA_FIN du mois:
                --GL : sur le mois en cours
                dka_tools_pkg.put_debug_message ('calcul : '|| gv_event_type_cca);
                dka_spasinistre_pkg.pa_get_sum_event_revenue (
                    active_tasks_rec.task_id, --RGH
                    pd_from_date,
                    pd_to_date,
                    gv_event_type_cca,
                    vn_cca,
                    pv_errbuf,
                    vn_result
                );
                --RGH : remplacer project_id par task_id
                IF vn_result != 0
                THEN
                    dka_tools_pkg.put_debug_message ('vn_result:' || vn_result);
                    --- 16/11/2016 NBO Migration R12
                    vv_error_message    :=    'Rejet pour le calcul des Cumul des CCA FIN sur le projet : '
                                           || active_tasks_rec.segment1
                                           || ' et la tâche : '  -- RGH
                                           || active_tasks_rec.task_number                            -- RGH
                                           || ' sur le type d''evenement '
                                           || gv_event_type_cca
                                           || ' pour le montant '
                                           || vn_event_amount
                                           || ' avec l''erreur '
                                           || pv_errbuf;
                    RAISE e_error;
                END IF;

                dka_tools_pkg.put_debug_message (vn_cca_extourne ||':'|| vn_charges ||':'|| vn_etats_frais || ':' || vn_cca);

   /* Ajout TB*/IF (vn_cca_extourne + vn_charges) > vn_etats_frais
                -- Modif TB : IF vn_charges > vn_etats_frais
                THEN


                    --Formule de Calcul du montant des CCA:
                    vn_event_amount    := vn_cca_extourne + (vn_charges - vn_etats_frais - vn_cca);

                    IF vn_event_amount != 0
                    THEN
                        dka_tools_pkg.put_debug_message (
                            'PROC_PROCESS_ACTIVE_PROJECTS : vn_charges > vn_etats_frais - Lancement INSERT_EVENT'
                        );
                        --Insertion des évènements CCA:

                        -- dka_tools_pkg.pa_insert_event ( -- RGH
                         dka_pa_tools_pkg.pa_insert_event (
                            pn_task_id                     => active_tasks_rec.task_id, --RGH
                            pv_event_type                  => gv_event_type_cca,
                            pn_amount                      => vn_event_amount,
                            pn_project_id                  => active_tasks_rec.project_id,
                            pd_completion_date             => vd_completion_date,
                            pn_group_id                    => pn_group_id,
                            pv_insert_revenue_flag         => 'Y',
                            pv_event_attr_context          => gv_attribute_category, --GL
                            pv_description                 => gv_event_type_cca,     --GL
                            pv_batch_name                  => gv_gl_batch_name,
                            pv_errbuf                      => pv_errbuf,
                            pn_result                      => vn_result
                        );

                        --quand la procédure tombe en erreur sur une ligne on continue
                        IF vn_result != 0
                        THEN
                          --- 16/11/2016 NBO Migration R12
                          vv_error_message    :=    'Rejet pour l''insertion d''evenement sur le projet : '
                                                   || active_tasks_rec.segment1
                                                   || ' et sur la tâche : '  -- RGH
                                                   || active_tasks_rec.task_number                            -- RGH
                                                   || ' sur le type d''evenement '
                                                   || gv_event_type_cca
                                                   || ' pour le montant '
                                                   || vn_event_amount
                                                   || ' avec l''erreur '
                                                   || pv_errbuf;
                            RAISE e_error;
                        END IF; --GL

                        --insertion d'une trace dans la table de travail:
                        --GL
                        INSERT INTO dka_spasinistre_tmp
                                    (segment1,
                                     period_name,
                                     period_extourne,
                                     event_type,
                                     amount,
                                     reversal_flag,
                                     creation_date,
                                     created_by,
                                     last_update_date,
                                     last_updated_by,
                                     last_update_login,
                                     request_id,
                                     project_id,
                                     task_id,               -- RGH
                                     task_number            -- RGH
                                    )
                        VALUES      (active_tasks_rec.segment1,
                                     gv_period_name,
                                     gv_period_extourne,
                                     gv_event_type_cca,
                                     vn_event_amount,
                                     'N',
                                     SYSDATE,
                                     gv_created_by,
                                     NULL,
                                     gv_last_updated_by,
                                     gv_last_update_login,
                                     gv_request_id,
                                     active_tasks_rec.project_id,
                                     active_tasks_rec.task_id,    -- RGH
                                     active_tasks_rec.task_number -- RGH
                                    );
                    END IF;

  /* Ajout TB*/ ELSIF vn_cca > 0 -- Cas où il n'y a plus de calcul des CCA mais un CCA FIN a déjà été calculé auparavant
                THEN
                -- Il faut alors annuler le montant calculé des CCA FIN du mois :
                    vn_event_amount    := - vn_cca;

                    IF vn_event_amount != 0
                    THEN
                        dka_tools_pkg.put_debug_message (
                            'PROC_PROCESS_ACTIVE_PROJECTS : vn_charges > vn_etats_frais - Lancement INSERT_EVENT'
                        );
                        --Insertion des évènements CCA:

                        -- dka_tools_pkg.pa_insert_event ( --RGH
                         dka_pa_tools_pkg.pa_insert_event (
                            pn_task_id                     => active_tasks_rec.task_id, --RGH
                            pv_event_type                  => gv_event_type_cca,
                            pn_amount                      => vn_event_amount,
                            pn_project_id                  => active_tasks_rec.project_id,
                            pd_completion_date             => vd_completion_date,
                            pn_group_id                    => pn_group_id,
                            pv_insert_revenue_flag         => 'Y',
                            pv_event_attr_context          => gv_attribute_category, --GL
                            pv_description                 => gv_event_type_cca, --GL
                            pv_batch_name                  => gv_gl_batch_name,
                            pv_errbuf                      => pv_errbuf,
                            pn_result                      => vn_result
                        );

                        --quand la procédure tombe en erreur sur une ligne on continue
                        IF vn_result != 0
                        THEN
                            --- 16/11/2016 NBO Migration R12
                            vv_error_message    :=    'Rejet pour l''insertion d''evenement sur le projet : '
                                                   || active_tasks_rec.segment1
                                                   || ' et sur la tâche : ' --RGH
                                                   || active_tasks_rec.task_number                     --RGH
                                                   || ' sur le type d''evenement '
                                                   || gv_event_type_cca
                                                   || ' pour le montant '
                                                   || vn_event_amount
                                                   || ' avec l''erreur '
                                                   || pv_errbuf;
                            RAISE e_error;
                        END IF; --GL

                        --insertion d'une trace dans la table de travail:
                        --GL
                        INSERT INTO dka_spasinistre_tmp
                                    (segment1,
                                     period_name,
                                     period_extourne,
                                     event_type,
                                     amount,
                                     reversal_flag,
                                     creation_date,
                                     created_by,
                                     last_update_date,
                                     last_updated_by,
                                     last_update_login,
                                     request_id,
                                     project_id,
                                     task_id,    -- RGH
                                     task_number -- RGH
                                    )
                        VALUES      (active_tasks_rec.segment1,
                                     gv_period_name,
                                     gv_period_extourne,
                                     gv_event_type_cca,
                                     vn_event_amount,
                                     'N',
                                     SYSDATE,
                                     gv_created_by,
                                     NULL,
                                     gv_last_updated_by,
                                     gv_last_update_login,
                                     gv_request_id,
                                     active_tasks_rec.project_id,
                                     active_tasks_rec.task_id,    -- RGH
                                     active_tasks_rec.task_number -- RGH
                                    );
                    END IF;  /* Fin Ajout TB*/

                END IF;
                dka_tools_pkg.put_debug_message ('Fin des calculs');

            EXCEPTION
                WHEN e_error
                THEN
                    ROLLBACK TO point_arret;
                    dka_tools_pkg.put_outdebug_message (vv_error_message);
                    pn_result    := 1;
                WHEN OTHERS
                THEN
                    vv_error_message    := SQLERRM;
                    ROLLBACK TO point_arret;
                    dka_tools_pkg.put_outdebug_message (vv_error_message);
                    pn_result           := 1;
            END;
            dka_tools_pkg.put_debug_message ('sortie du begin end');
        END LOOP;

        dka_tools_pkg.put_debug_message ('Fin de la boucle');

        CLOSE active_tasks_cur;
        dka_tools_pkg.put_debug_message ('PROC_ACTIVE_PROJECTS: Fin Traitement des taches de type SINISTRE en statut actif');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := 2;
            pv_errbuf    := SQLERRM;
    END process_active_tasks;


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
    )
    IS
        vn_count                 NUMBER;
        vv_message               VARCHAR2 (200);

        --Déclaration du curseur qui balaye l'ensemble des lignes:

        CURSOR spasinistre_output_cur
        IS
            SELECT   *
            FROM     dka_spasinistre_tmp dst
            WHERE    dst.request_id = gv_request_id /* ETANCHEITE DALKIA 2007 */
            ORDER BY dst.task_number; --dst.segment1; --RGH

        spasinistre_output_rec   spasinistre_output_cur%ROWTYPE;
    BEGIN
        pv_errbuf     := NULL;
        pn_result     := 0;
        dka_tools_pkg.put_debug_message ('PROC_CREATE_OUTPUT:Initialisation des variable de sortie');
        vn_count      := 0;
        vv_message    := 'Liste des évenements insérés pour '||gv_org_name ;
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '----------------------------';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := ' ';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := RPAD ('PROJET', 10) || ' ' || RPAD ('TACHE', 10) || ' ' || RPAD ('TYPE EVENEMENT', 30) || ' ' || RPAD ('MONTANT', 20);
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := RPAD ('-', 10, '-') || ' ' || RPAD ('-', 10, '-') || ' ' || RPAD ('-', 30, '-') || ' ' || RPAD ('-', 20, '-');
        fnd_file.put_line (fnd_file.output, vv_message);
        dka_tools_pkg.put_debug_message ('PROC_CREATE_OUTPUT:Affichage de l''entête');
        OPEN spasinistre_output_cur;

        LOOP
            FETCH spasinistre_output_cur INTO spasinistre_output_rec;
            EXIT WHEN spasinistre_output_cur%NOTFOUND;
            vv_message    :=    RPAD (spasinistre_output_rec.segment1, 10)
                             || ' '
                             || RPAD (spasinistre_output_rec.TASK_NUMBER, 10)
                             || ' '
                             || RPAD (spasinistre_output_rec.event_type, 30)
                             || ' '
                             || RPAD (spasinistre_output_rec.amount, 20);
            fnd_file.put_line (fnd_file.output, vv_message);
            vn_count      := vn_count + 1;
        END LOOP;

        CLOSE spasinistre_output_cur;
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := 'Nombre de tâches traités : ' || TO_CHAR (vn_count);
        fnd_file.put_line (fnd_file.output, vv_message);
        dka_tools_pkg.put_debug_message ('Lister la TABLE de travail');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;
    END create_output;


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
    )
    IS
        vn_request_id          fnd_concurrent_requests.request_id%TYPE;
        vv_je_source_name      gl_je_sources.je_source_name%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_responsibility.application_id%TYPE;
        --vn_set_of_books_id     gl_interface.set_of_books_id%TYPE;
        vn_interface_run_id    gl_interface_control.interface_run_id%TYPE;
        vn_dummy               NUMBER;
        /*** ADR le 14/10/2003 ***/
        vv_phase               VARCHAR2 (10);
        vv_status              VARCHAR2 (10);
        vv_dev_phase           VARCHAR2 (10);
        vv_dev_status          VARCHAR2 (10);
        vv_errbuf              VARCHAR2 (150);
    BEGIN
        -- Récupération du Set_Of_Books_Id
        --vn_set_of_books_id    := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');

        SELECT gl_journal_import_s.NEXTVAL
        INTO   vn_interface_run_id
        FROM   DUAL;

        -- On vérifie qu'il y a des lignes a traiter
        SELECT COUNT (1)
        INTO   vn_dummy
        FROM   gl_interface gi
        WHERE  gi.GROUP_ID = pn_group_id;

        IF vn_dummy = 0
        THEN
            RETURN;
        END IF;

        SELECT DISTINCT gjs.je_source_name
        INTO            vv_je_source_name
        FROM            gl_interface gi,
                        gl_je_sources gjs
        WHERE               gjs.user_je_source_name = gi.user_je_source_name
                        AND gi.GROUP_ID = pn_group_id;

        -- Insertion dans la table gl_interface_control
        INSERT INTO gl_interface_control
                    (je_source_name,
                     status,
                     interface_run_id,
                     GROUP_ID,
                     set_of_books_id,
                     packet_id
                    )
        VALUES      (vv_je_source_name,
                     'S',
                     vn_interface_run_id,
                     pn_group_id,
                     --- 16/11/2016 NBO Migration R12
                     gn_sob,
                     NULL
                    );

        -- Récupération de la responsabilite
        dka_tools_pkg.put_debug_message ('Récupération de la responsabilité '|| gv_gl_resp_key);

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = gv_gl_resp_key;

        dka_tools_pkg.put_debug_message ('Lancement de la fonction d''initialisation');
        fnd_profile.initialize (fnd_global.user_id, vn_responsibility_id, vn_application_id, NULL);
        dka_tools_pkg.put_debug_message ('Lancement du traitement');
        vn_request_id         := fnd_request.submit_request (
                                     'SQLGL', --APPL
                                     'GLLEZL', --PROG
                                     NULL, --PROGRAM_NAME
                                     NULL, --START
                                     FALSE, --SUB_REQUEST
                                     vn_interface_run_id, --ARGUMENT1
                                     --- 16/11/2016 NBO Migration R12
                                     --vn_set_of_books_id, --ARGUMENT2
                                     FND_PROFILE.VALUE('GL_ACCESS_SET_ID'), --ARGUMENT2
                                     'N', --ARGUMENT3
                                     NULL, --ARGUMENT4
                                     NULL, --ARGUMENT5
                                     'N', --ARGUMENT6
                                     --- 16/11/2016 NBO Migration R12
                                     'W', --ARGUMENT7
                                     'Y' --ARGUMENT8
                                 );
        /*ADR le 14/10/2003 DEBUT*/
        COMMIT;

        IF NOT (fnd_concurrent.wait_for_request (vn_request_id, 15, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_errbuf))
        THEN
            pn_result    := 2;
            pv_errbuf    := 'Le lancement de l''Easylink a échoué !';
        ELSIF (    vv_dev_phase = 'COMPLETE'
               AND vv_dev_status = 'WARNING'
              )
        THEN
            pn_result    := 1;
            dka_tools_pkg.put_debug_message ('Easylink lancé avec le traitement numéro:'|| TO_CHAR (vn_request_id));
            fnd_file.put_line (
                fnd_file.output,
                CHR (10) || CHR (10) || 'Easylink lancé avec le traitement numéro:' || TO_CHAR (vn_request_id)
            );
        ELSIF (    vv_dev_phase = 'COMPLETE'
               AND vv_dev_status = 'NORMAL'
              )
        THEN
            dka_tools_pkg.put_debug_message ('Easylink lancé avec le traitement numéro:'|| TO_CHAR (vn_request_id));
            fnd_file.put_line (
                fnd_file.output,
                CHR (10) || CHR (10) || 'Easylink lancé avec le traitement numéro:' || TO_CHAR (vn_request_id)
            );
        END IF;
    /*ADR le 14/10/2003 FIN*/

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;
    END gl_open_interface;


-------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --        pv_period_name          Entrée
 --        pv_errbuf                   Entrée/Sortie
 --        pn_retcode                  Sortie
 --
 --  VALEUR RETOURNEE :pv_errbuf , pn_result

------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pv_period_name   IN       VARCHAR2
    )
    IS
        vv_errbuf     VARCHAR2 (500);
        vn_result     NUMBER;
        vd_from_date    DATE;
        vd_to_date    DATE;
        vn_group_id   NUMBER (15);
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        dka_tools_pkg.put_debug_message ('PROC_MAIN: Lancement DE  INIT');
        Fnd_File.put_line(Fnd_File.output, 'PROC_MAIN: Lancement DE  INIT'); --RGH TST
        dka_spasinistre_pkg.init (pv_period_name, vd_from_date, vd_to_date, vn_group_id, pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_MAIN : Lancement CLEAR_SPASINISTRE_TMP');
        Fnd_File.put_line(Fnd_File.output, 'PROC_MAIN : Lancement CLEAR_SPASINISTRE_TMP'); --RGH TST
        dka_spasinistre_pkg.clear_spasinistre_tmp (pv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := 1;

            IF pv_errbuf IS NULL
            THEN
                pv_errbuf    := vv_errbuf;
            ELSE
                pv_errbuf    := pv_errbuf || CHR (10) || vv_errbuf;
            END IF;
        ELSIF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := vv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_MAIN : Lancement PROCESS_ACTIVE_PROJECTS');
        Fnd_File.put_line(Fnd_File.output, 'PROC_MAIN : Lancement PROCESS_ACTIVE_PROJECTS'); --RGH TST
        dka_spasinistre_pkg.process_active_tasks (vd_from_date, vd_to_date, vn_group_id, pv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := 1;

            IF pv_errbuf IS NULL
            THEN
                pv_errbuf    := vv_errbuf;
            ELSE
                pv_errbuf    := pv_errbuf || CHR (10) || vv_errbuf;
            END IF;
        ELSIF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := vv_errbuf;
            RETURN;
        END IF;



        dka_tools_pkg.put_debug_message ('PROC_MAIN : Lancement CREATE_OUTPUT');
        dka_spasinistre_pkg.create_output (pv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := 1;

            IF pv_errbuf IS NULL
            THEN
                pv_errbuf    := vv_errbuf;
            ELSE
                pv_errbuf    := pv_errbuf || CHR (10) || vv_errbuf;
            END IF;
        ELSIF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := vv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_MAIN : Lancement GL_OPEN_INTERFACE');
        dka_spasinistre_pkg.gl_open_interface (vn_group_id, pv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := 1;

            IF pv_errbuf IS NULL
            THEN
                pv_errbuf    := vv_errbuf;
            ELSE
                pv_errbuf    := pv_errbuf || CHR (10) || vv_errbuf;
            END IF;
        ELSIF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := vv_errbuf;
            RETURN;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END main;


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

    PROCEDURE REVERSE (
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pn_group_id   IN       NUMBER
    )
    IS
        vn_result     NUMBER                := 0;
        vv_errbuf     VARCHAR2 (500)        := '';
        --vd_to_date    DATE;
        --vn_group_id   NUMBER;
        e_erreur      EXCEPTION;

        CURSOR reverse_cur
        IS
            SELECT dst.segment1,
                   dst.period_name,
                   dst.period_extourne,
                   dst.event_type,
                   dst.project_id,
                   dst.task_id,     -- RGH
                   dst.task_number, -- RGH
                   gv_event_type_extourne_cca event_type_extourne,
                   gv_attribute_category attribute_category,
                   gv_event_type_extourne_cca description,
                   dst.amount,
                   dst.ROWID row_id, -- for update
                   gps.start_date
            FROM   pa_projects_all pp, -- ETANCHEITE DALKIA 2007 -- RGH
                   pa_tasks    pt,                              -- RGH
                   dka_spasinistre_tmp dst,
                   gl_period_statuses gps,
                   hr_operating_units hou
            WHERE      NVL (dst.reversal_flag, 'N') = 'N'
                   AND pp.project_id = dst.project_id -- ETANCHEITE DALKIA 2007 --RGH
                   AND pt.project_id = dst.project_id -- RGH
                   AND pt.task_id    = dst.task_id    -- RGH
                   AND dst.period_extourne = gps.period_name
                   AND gps.closing_status = 'O'
                   --AND gps.set_of_books_id = TO_NUMBER (fnd_profile.VALUE ('GL_SET_OF_BKS_ID'))
                   AND pp.org_id = gn_org_id
                   AND hou.organization_id = pp.org_id
                   AND hou.set_of_books_id = gps.set_of_books_id
                   AND gps.application_id = 101;

        reverse_rec   reverse_cur%ROWTYPE;
    BEGIN
        pn_retcode    := 0;
        pv_errbuf     := '';
        dka_tools_pkg.put_debug_message ('(+) reverse');
        dka_tools_pkg.put_debug_message ('Début Traitement extourne des projets');
        --Ouvrir le curseur et boucler:
        OPEN reverse_cur;

        LOOP
            dka_tools_pkg.put_debug_message ('Debut boucle');
            vn_result    := 0;
            vv_errbuf    := '';
            FETCH reverse_cur INTO reverse_rec;
            EXIT WHEN reverse_cur%NOTFOUND;
            SAVEPOINT point_arret;

            DECLARE
                e_error   EXCEPTION;
            BEGIN
                IF reverse_rec.event_type_extourne IS NULL
                THEN
                    vv_errbuf    := '**** warning : event_type_extourne is  null ';
                    RAISE e_error;
                END IF;

                dka_tools_pkg.put_debug_message ('*****************************************************************************');
                dka_tools_pkg.put_debug_message (reverse_rec.segment1  || '  ' || reverse_rec.task_number  || '  ' || reverse_rec.event_type_extourne); --RGH
                dka_tools_pkg.put_debug_message ('pa_insert_event... :'  || gv_period_extourne);
                --dka_tools_pkg.pa_insert_event (  --RGH
                dka_pa_tools_pkg.pa_insert_event (
                    pn_task_id                     => reverse_rec.task_id,
                    pv_event_type                  => reverse_rec.event_type_extourne,
                    pn_amount                      => reverse_rec.amount,
                    pn_project_id                  => reverse_rec.project_id,
                    pd_completion_date             => reverse_rec.start_date,
                    pn_group_id                    => pn_group_id,
                    pv_batch_name                  => gv_gl_batch_name,
                    pv_insert_revenue_flag         => 'Y',
                    pv_event_attr_context          => gv_attribute_category,
                    pv_description                 => gv_event_type_extourne_cca,
                    pv_errbuf                      => vv_errbuf,
                    pn_result                      => vn_result
                );
                IF vn_result != 0
                THEN
                    vv_errbuf    :=    'Rejet pour l''insertion d''evenement sur le segment1 '
                                    || reverse_rec.segment1
                                    || ' sur la tache '          -- RGH
                                    || reverse_rec.task_number   -- RGH
                                    || ' sur le type d''evenement '
                                    || gv_event_type_cca
                                    || ' pour le montant '
                                    || reverse_rec.amount
                                    || ' avec l''erreur '
                                    || vv_errbuf;
                    RAISE e_error;
                END IF;

                -- aucun warning : on met a jour la ligne
                UPDATE dka_spasinistre_tmp
                SET    reversal_flag = 'Y',
                       request_id = gv_request_id,
                       last_update_date  = SYSDATE,
                       last_updated_by   = gv_last_updated_by,
                       last_update_login = gv_last_update_login,
                       error_message = ''
                WHERE  ROWID = reverse_rec.row_id;

                dka_tools_pkg.put_debug_message ('table tmp mise à jour correctement');
            EXCEPTION
                WHEN e_error
                THEN
                    ROLLBACK TO point_arret;
                    dka_tools_pkg.put_outdebug_message (vv_errbuf);
                    pn_retcode    := 1;

                    UPDATE dka_spasinistre_tmp
                    SET    request_id = gv_request_id,
                           last_update_date = SYSDATE,
                           last_updated_by = gv_last_updated_by,
                           last_update_login = gv_last_update_login,
                           error_message = vv_errbuf
                    WHERE  ROWID = reverse_rec.row_id;
                WHEN OTHERS
                THEN
                    vv_errbuf     := SQLERRM;
                    ROLLBACK TO point_arret;
                    dka_tools_pkg.put_outdebug_message (vv_errbuf);
                    pn_retcode    := 1;

                    UPDATE dka_spasinistre_tmp
                    SET    request_id = gv_request_id,
                           last_update_date = SYSDATE,
                           last_updated_by = gv_last_updated_by,
                           last_update_login = gv_last_update_login,
                           error_message = vv_errbuf
                    WHERE  ROWID = reverse_rec.row_id;
            END;
        END LOOP;

        CLOSE reverse_cur;
        dka_tools_pkg.put_debug_message ('Fin Traitement reverse');
        dka_tools_pkg.put_debug_message ('(-) reverse ');
    EXCEPTION
        WHEN e_erreur
        THEN
            IF reverse_cur%ISOPEN
            THEN
                CLOSE reverse_cur;
            END IF;

            pv_errbuf     := vv_errbuf;
            pn_retcode    := 2;
            dka_tools_pkg.put_debug_message ('**** Erreur e_erreur '|| pv_errbuf);

            UPDATE dka_spasinistre_tmp
            SET    request_id = gv_request_id,
                   last_update_date = SYSDATE,
                   last_updated_by = gv_last_updated_by,
                   last_update_login = gv_last_update_login,
                   error_message = 'Erreur e_erreur ' || pv_errbuf
            WHERE  ROWID = reverse_rec.row_id;
        WHEN OTHERS
        THEN
            IF reverse_cur%ISOPEN
            THEN
                CLOSE reverse_cur;
            END IF;

            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            dka_tools_pkg.put_debug_message ('**** Erreur inconnue '|| SQLCODE || ' ' || SQLERRM);

            UPDATE dka_spasinistre_tmp
            SET    request_id = gv_request_id,
                   last_update_date = SYSDATE,
                   last_updated_by = gv_last_updated_by,
                   last_update_login = gv_last_update_login,
                   error_message = 'Erreur inconnue ' || pv_errbuf
            WHERE  ROWID = reverse_rec.row_id;
    END REVERSE;


-------------------------------------------------------------------------------------
 --  Auteur        : GL
 --  Nom           : MAIN_extourne
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
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_result     NUMBER;
        vv_errbuf     VARCHAR2 (500);
        vd_from_date    DATE;
        vd_to_date    DATE; -- non utilisé
        vn_group_id   NUMBER;
        erreur        EXCEPTION;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        dka_tools_pkg.put_debug_message ('PROC_MAIN_REVERSE: Lancement de  INIT');
        dka_spasinistre_pkg.init (NULL, vd_from_date, vd_to_date, vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := vv_errbuf;
            RAISE erreur;
        ELSIF vn_result = 1
        THEN
            pn_retcode    := 1;
            pv_errbuf     := vv_errbuf;
            dka_tools_pkg.put_debug_message (vv_errbuf);
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_MAIN_REVERSE: Lancement de reverse '|| vn_group_id);
        dka_spasinistre_pkg.REVERSE (vv_errbuf, vn_result, vn_group_id);

        IF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := pv_errbuf || CHR (10) || vv_errbuf;
            RAISE erreur;
        ELSIF vn_result = 1
        THEN
            pn_retcode    := 1;
            pv_errbuf     := 'Il y a des évènements rejetés';
            dka_tools_pkg.put_debug_message (pv_errbuf);
        END IF;

        dka_tools_pkg.put_debug_message ('PROC_MAIN_REVERSE : Lancement GL_OPEN_INTERFACE '|| vn_group_id);
        dka_spasinistre_pkg.gl_open_interface (vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := pv_errbuf || CHR (10) || vv_errbuf;
            RAISE erreur;
        ELSIF vn_result = 1
        THEN
            pn_retcode    := 1;
            pv_errbuf     := pv_errbuf || CHR (10) || vv_errbuf;
            dka_tools_pkg.put_debug_message (vv_errbuf);
        END IF;

        dka_tools_pkg.put_debug_message ('');
        dka_tools_pkg.put_debug_message ('*****************************************************************************');
        dka_tools_pkg.put_debug_message ('');
        dka_tools_pkg.put_debug_message ('PROC_MAIN_REVERSE : Lancement CREATE_OUTPUT');
        dka_spasinistre_pkg.create_output (vv_errbuf, vn_result);

        IF vn_result = 2
        THEN
            pn_retcode    := 2;
            pv_errbuf     := pv_errbuf || CHR (10) || vv_errbuf;
            RAISE erreur;
        ELSIF vn_result = 1
        THEN
            pn_retcode    := 1;
            pv_errbuf     := pv_errbuf || CHR (10) || vv_errbuf;
            dka_tools_pkg.put_debug_message (vv_errbuf);
        END IF;
    EXCEPTION
        WHEN erreur
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
            ROLLBACK;
            dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE : Erreur '|| vv_errbuf);
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            ROLLBACK;
            dka_tools_pkg.put_debug_message ('PROC_MAIN_REVERSE : Erreur '|| TO_CHAR (SQLCODE) || ' : ' || SQLERRM);
    END main_extourne;
END dka_spasinistre_pkg;
/
SHOW ERRORS
EXIT;
