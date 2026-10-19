CREATE OR REPLACE PACKAGE BODY DKA_SPATRAVCOURS_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPATRAVCOURS_PKG.pks
-- DESCRIPTION       : DKA_SPATRAVCOURS_PKG package body : Calcul des TEC/PCA et leur Annulation
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
--- 25/11/2002 EB  Modification de la gestion des statuts cloturé et actif
--- 18/06/2003 XD  process_active_projects : si attribute2 = pd_to_date, on considère que la date est dépassée
--- 20/06/2003 XD  process_active_projects : Gestion des anomalies
---                process_inactive_projects : Gestion des anomalies
---                main : Gestion des anomalies
---                Mise en forme du script
--- 11/08/2003 XD  process_active_projects : on ne traite que les projets avec au moins une ligne
---                                          de dépense ou d'évènement
---                process_inactive_projects : on ne traite que les projets avec au moins une ligne
---                                            de dépense ou d'évènement
--- 03/09/2003 XD  process_projects : Création
---                main : ne plus utiliser process_active_projects
---                       ne plus utiliser process_inactive_projects
---                       utiliser process_projects
--- 14/10/2003 AD  GL_OPEN_INTERFACE : Ajout de la procédure standard fnd_concurent.wait_for_request.
---                On attend la fin de l'easylink avant celle du specifque.
--- 06/04/2004 FL  Refonte des TEC et PCA, ajout des procédures main_reverse et reverse pour le calcul des extournes PHENIX 2004
--- 11/10/2004 FB  PROCESS_PROJECTS Modif. date de fin non atteinte (> au lieu de >=) PHENIX 2004
--- 26/05/2005 NB  PROCESS_PROJECTS Modif. EID20050030 ( Refonte suite reprise PHENIX 2004 )
--- 07/07/2005 TB  PROCESS_PROJECTS Remplacement attribute9 par attribute10 + Modif. sur calcul produit
--- 22/07/2005 AD  PROCESS_PROJECTS Modif. Suppression des hints. Ajout de l'évenement VENTES TRAVAUX
--		   sur calcul des produits.
--- 02/08/2005 TB  Epuration des process non utilisés
--- 08/08/2005 TB  PROCESS_PROJECTS Modif test ATTRIBUTE10
--- 20/10/2005 TB  PROCESS_PROJECTS Annulation Update attribute 10
--- 21/10/2005 EB  MAJ_ATTRIBUTE10 : création de la procédure et appel ds le MAIN
--- 14/11/2005 EB  PROCESS_PROJECTS : MAJ ATTRIBUTE10 dans le curseur projects_cur
--- 23/11/2005 EB  MAJ_CALCULE : création de la procédure
---                MAJ_FACTURE : ancienne procedure  MAJ ATTRIBUTE10 modifiée
---                PROCESS_PROJECTS : utilisation des procedures MAJ_CALCULE et MAJ_FACTURE
---                                   Ajout de tests pour traiter les ruptures de traitement
--- 25/11/2005 TB PROCESS_PROJECTS : Modif. dans le curseur de la colonne 'Cas_projet'
--- 10/01/2007 TB PROCESS_PROJECTS : Modification du test sur la rupture de calcul
---                                  Ajout dans la requete de sélection de la somme des TEC et PCA déjà calculée pour la période
--- 30/11/2007 AD ETANCHEITE DALKIA 2007
--- 07/02/2008 TB Main : ajout de la gestion des erreurs pour la procédure maj_facture
---               maj_facture : optimisation de la requete
---                             ajout de la date de MAJ dans l'ATTRIBUTE10
---                             suppression de la restriction sur projets actifs
---               maj_calcule : prise en compte des modifs sur le contenu de l'ATTRIBUTE10
--- 01/09/2015 GFLO PROCESS_PROJECTS : Performances
--- 11/05/2016 RGH Migration R12
--- 09/11/2016 NBO Correction au test d'intégration des événements
--  09/12/2016 NBO artf2059287 - SPE052 - Traitement multi-org
--- 02/02/2017 NBO artf2091175 - SPE052 - Suppression restriction sur la description de la tâche,
---				   artf2090329 - SPE052 - Suppression alimentation date du jour dans ATTRIBUTE3
--- 14/02/2017 NBO artf2098706 - SPE052 : Logs du traitement DKA : Extourne des TEC et PCA : KO
--- 			   artf2099600 - SPE052 - Prob lancement Easylink
---				   artf2099957 - SPE052 - Affichage de la tâche dans le journal
---				   artf2100558 - SPE052 - Automatisation Extournes des TEC/PCA
--- 03/08/2017 YWA artf2206811 : SPE052 - Alimentation du CF Tâches facturées erronnée - defect BOUT_EN_BOUT_HELIOS_REF # 1034 
--- 30/11/2017 NBO artf2284468: SPE052 - Calcul des TEC et PCA - Pb de gestion de la période dans le curseur projects_cur
--- 11/04/2018 JJA artf2515970 : Modification du contrôle de la date de clôture et de la date prévisionnelle de fin de travaux
---------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gv_event_type_vt              dka_parameters.varchar2_value%TYPE;
    gv_event_type_tecd            dka_parameters.varchar2_value%TYPE;
    gv_event_type_teci            dka_parameters.varchar2_value%TYPE;
    gv_event_type_extourne_tecd   dka_parameters.varchar2_value%TYPE;
    gv_attr_categ_type_tecd       dka_parameters.varchar2_value%TYPE;
    gv_event_type_extourne_teci   dka_parameters.varchar2_value%TYPE;
    gv_attr_categ_type_teci       dka_parameters.varchar2_value%TYPE;
    gv_event_type_pca             dka_parameters.varchar2_value%TYPE;
    gv_attr_categ_type_pca        dka_parameters.varchar2_value%TYPE;
    gv_event_type_extourne_pca    dka_parameters.varchar2_value%TYPE;
    gv_project_type_te            dka_parameters.varchar2_value%TYPE;
    gv_project_type_teds          dka_parameters.varchar2_value%TYPE;
    gv_status_code_actif          dka_parameters.varchar2_value%TYPE;
    gv_status_code_inactif        dka_parameters.varchar2_value%TYPE;
    gv_regime_forfait             dka_parameters.varchar2_value%TYPE;
    gv_regime_regie               dka_parameters.varchar2_value%TYPE;
    --gv_type_code_r_spec           dka_parameters.varchar2_value%TYPE;
    gv_gl_resp_key                dka_parameters.varchar2_value%TYPE;
    gv_gl_batch_name              dka_parameters.varchar2_value%TYPE;
    -- Modif PHENIX 2004
    gv_request_id                 NUMBER (15)                          := 0;
    gv_created_by                 NUMBER (15)                          := 0;
    gv_last_updated_by            NUMBER (15)                          := 0;
    gv_last_update_login          NUMBER (15)                          := 0;
    gv_period_name                VARCHAR2 (15)                        := '';
    gv_periode_suivante           VARCHAR2 (15)                        := '';
    gn_set_of_books               NUMBER (15);
	--- 09/11/2016 NBO Variabilisation du template task
    gv_task_template              VARCHAR2(10) := 'GX%';
    /* ETANCHEITE DALKIA 2007 */
    -- Fin Modif PHENIX 2004
	gv_org_name                      VARCHAR2(100);


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
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
    )
    IS
        rec_param    dka_parameters%ROWTYPE;
        --pn_result    NUMBER;
        vv_message   VARCHAR2 (500);
    BEGIN
        --Initialisation des Variables de sortie de la Procédure:
        pv_errbuf                      := NULL;
        --pn_result                      := 0;
        -- Initialisation des fichiers de journal (log) et de sortie (out)
        -- pour éviter un Commit en cours de traitement
        dka_tools_pkg.put_out_header;
        vv_message                     := 'Liste des anomalies de traitement';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message                     := '---------------------------------';
        fnd_file.put_line (fnd_file.output, vv_message);
        -- Modif PHENIX 2004
        gv_request_id                  := fnd_profile.VALUE ('CONC_REQUEST_ID');

        IF NVL (gv_request_id, 0) = 0
        THEN
            pn_retcode    := 1;
            pv_errbuf     := 'REQUEST_ID non trouvé';
            RETURN;
        END IF;

        gv_created_by                  := fnd_profile.VALUE ('USER_ID');
        gv_last_updated_by             := fnd_profile.VALUE ('USER_ID');
        gv_last_update_login           := fnd_profile.VALUE ('LOGIN_ID');
        --gn_set_of_books                := TO_NUMBER (fnd_profile.VALUE ('GL_SET_OF_BKS_ID')); --RGH
        --gn_set_of_books                := TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R'));  
        --  09/12/2016 NBO artf2059287 - SPE052 - Traitement multi-org
        select set_of_books_id, name INTO gn_set_of_books, gv_org_name from hr_operating_units where organization_id = fnd_global.org_id;
        
        /* ETANCHEITE DALKIA 2007 */
        
        IF gn_set_of_books IS NULL THEN
          dka_tools_pkg.put_log_message('L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétrée');
          pv_errbuf := 'L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétrée';
          pn_retcode := 2;
          RETURN;
        END IF;

       
        --Calcul de la periode suivante et de la Date de Fin:
        IF pv_period_name IS NOT NULL
        THEN
            gv_period_name    := pv_period_name;

            BEGIN
                SELECT period_name
                INTO   gv_periode_suivante
                FROM   gl_period_statuses gps
                WHERE      gps.set_of_books_id = gn_set_of_books
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

            /* Modif NB 17/05/2005 */
            BEGIN
              SELECT pap.start_date
              INTO   pd_from_date
              FROM   pa_periods pap
              WHERE  pap.period_name = pv_period_name;

              EXCEPTION
                WHEN no_data_found THEN
                    pn_retcode := 2;
                    pv_errbuf  := 'DATE DEBUT PERIODE - NON TROUVEE ' || pv_errbuf;
                    RETURN;
                WHEN OTHERS THEN
                    pn_retcode := 2;
                    pv_errbuf  := 'DATE DEBUT PERIODE - ERREUR INCONNUE ' || SQLERRM;
                    RETURN;
           END;
           /* Fin modif NB 17/05/2005 */
            
            --artf2515970
            pd_to_date        := pa_utils.get_pa_end_date (pv_period_name);
            
            
        END IF;
        -- Fin Modif PHENIX 2004

        --calcul du group_id:
        SELECT gl_interface_control_s.NEXTVAL
        INTO   pn_group_id
        FROM   DUAL;
        
	    --- 09/11/2016 NBO Affichage des variables
        dka_tools_pkg.put_debug_message ('pn_group_id : ' || pn_group_id);
        
        dka_tools_pkg.put_debug_message ('pd_from_date : ' || pd_from_date);
        dka_tools_pkg.put_debug_message ('pd_to_date : ' || pd_to_date);
        
        --Recupération de l'ensemble des Paramètres stockés dans la Table dka_parameters:
        dka_tools_pkg.put_debug_message ('PROC_INIT: Initialisation des Variables de Sortie');
        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'PROJECT_TYPE_TRAVAUX_EXTERNES', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_te             := rec_param.varchar2_value;
        gv_project_type_teds           := rec_param.DESCRIPTION;
        
        dka_tools_pkg.put_debug_message ('gv_project_type_te : ''' || gv_project_type_te || '''');
        dka_tools_pkg.put_debug_message ('gv_project_type_teds : ''' || gv_project_type_teds || '''');
        
        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PROJECT_TYPE_TRAVAUX_EXTERNES - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_TECD', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_tecd             := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_tecd : ''' || gv_event_type_tecd || '''');
        

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_TECD - ' || pv_errbuf;
            RETURN;
        END IF;

        -- Modif PHENIX 2004
        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'ATTRIB_CATEG_EVENT_TYPE_TECD', rec_param, pn_retcode, pv_errbuf);
        gv_attr_categ_type_tecd        := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_attr_categ_type_tecd : ' || gv_attr_categ_type_tecd);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'ATTRIB_CATEG_EVENT_TYPE_TECD - ' || pv_errbuf;
            RETURN;
        END IF;
        -- fin Modif PHENIX 2004

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_TECI', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_teci             := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_teci : ' || gv_event_type_teci);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_TECI - ' || pv_errbuf;
            RETURN;
        END IF;

        -- Modif PHENIX 2004
        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'ATTRIB_CATEG_EVENT_TYPE_TECI', rec_param, pn_retcode, pv_errbuf);
        gv_attr_categ_type_teci        := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_attr_categ_type_teci : ' || gv_attr_categ_type_teci);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'ATTRIB_CATEG_EVENT_TYPE_TECI - ' || pv_errbuf;
            RETURN;
        END IF;
        -- Fin Modif PHENIX 2004

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_EXTOURNE_TECD', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_extourne_tecd    := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_extourne_tecd : ' || gv_event_type_extourne_tecd);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_EXTOURNE_TECD - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_EXTOURNE_TECI', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_extourne_teci    := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_extourne_teci : ' || gv_event_type_extourne_teci);
        

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_EXTOURNE_TECI - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_PCA', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_pca              := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_pca : ' || gv_event_type_pca);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_PCA - ' || pv_errbuf;
            RETURN;
        END IF;

        -- Modif PHENIX 2004
        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'ATTRIB_CATEG_EVENT_TYPE_PCA', rec_param, pn_retcode, pv_errbuf);
        gv_attr_categ_type_pca         := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_attr_categ_type_pca : ' || gv_attr_categ_type_pca);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'ATTRIB_CATEG_EVENT_TYPE_PCA - ' || pv_errbuf;
            RETURN;
        END IF;
        -- Fin Modif PHENIX 2004

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'EVENT_TYPE_EXTOURNE_PCA', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_extourne_pca     := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_extourne_pca : ' || gv_event_type_extourne_pca);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_TYPE_EXTOURNE_PCA - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'VENTES_TRAVAUX', rec_param, pn_retcode, pv_errbuf);
        gv_event_type_vt               := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_event_type_vt : ' || gv_event_type_vt);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'VENTES_TRAVAUX - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'STATUS_CODE_ACTIF', rec_param, pn_retcode, pv_errbuf);
        gv_status_code_actif           := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('gv_status_code_actif : ' || gv_status_code_actif);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STATUS_CODE_ACTIF - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'STATUS_CODE_INACTIF', rec_param, pn_retcode, pv_errbuf);
        gv_status_code_inactif         := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STATUS_CODE_INACTIF - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'REGIME_FORFAIT', rec_param, pn_retcode, pv_errbuf);
        gv_regime_forfait              := rec_param.varchar2_value;

        dka_tools_pkg.put_debug_message ('gv_regime_forfait : ' || gv_regime_forfait);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'REGIME_FORFAIT - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'REGIME_REGIE', rec_param, pn_retcode, pv_errbuf);
        gv_regime_regie                := rec_param.varchar2_value;

        dka_tools_pkg.put_debug_message ('gv_regime_regie : ' || gv_regime_regie);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'REGIME_REGIE - ' || pv_errbuf;
            RETURN;
        END IF;

/*
        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'TYPE_CODE_R_SPECIFIQUE', rec_param, pn_retcode, pv_errbuf);
        gv_type_code_r_spec            := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TYPE_CODE_R_SPECIFIQUE - ' || pv_errbuf;
            RETURN;
        END IF;
*/

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'GL_RESP_KEY', rec_param, pn_retcode, pv_errbuf);
        gv_gl_resp_key                 := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GL_RESP_KEY - ' || pv_errbuf;
            RETURN;
        END IF;

        dka_tools_pkg.get_parameter ('SPATRAVCOURS', 'GL_BATCH_NAME', rec_param, pn_retcode, pv_errbuf);
        gv_gl_batch_name               := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GL_BATCH_NAME - ' || pv_errbuf;
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
    )
    IS
    BEGIN
        dka_tools_pkg.put_debug_message ('PROC_CLEAR_SPATRAVCOURS_TMP:Initialisation des Variables de Sortie');
        pv_errbuf    := NULL;
        pn_result    := 0;
        dka_tools_pkg.put_debug_message ('Purger la Table de Travail DKA_SPATRAVCOURS_TMP');

        -- Modif PHENIX 2004
        DELETE      dka_spatravcours_tmp
        WHERE       reversal_flag = 'Y';
        -- Modif PHENIX 2004

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;
    END clear_spatravcours_tmp;
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
    )
    IS
       BEGIN
        dka_tools_pkg.put_debug_message ('MAJ_CALCULE : Flag du tache '||pv_task_id );
        pv_errbuf    := NULL;
        pn_result    := 0;

 /*       UPDATE pa_projects pp --TANCHEITE DALKIA 2007  pa_projects_all
          SET    pp.attribute10 = substr(pp.attribute10,1,1) || 'Y' || substr(pp.attribute10,3,12) -- modif TB 07/02/08
          WHERE  pp.project_id = pv_project_id;
*/

          UPDATE PA_TASKS  pt
		   --- 02/02/2017 NBO artf2090329 - SPE052 - Suppression alimentation date du jour dans ATTRIBUTE3
           SET    pt.attribute3 = NVL(substr(pt.attribute3,1,1),'N') || 'Y' -- YWA artf2206811  --|| substr(pt.attribute3,3,12) 
          WHERE  pt.project_id = pv_project_id
            AND  pt.task_id    = pv_task_id;

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;
    END maj_calcule;
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
    )
    IS
    
    CURSOR cur_task IS
    select pe.project_id, pe.task_id
    from pa_tasks              pt,
         pa_projects           pp,
         pa.pa_events          pe,
         pa_draft_revenues     pdr, /*ETANCHEITE DALKIA 2007*/
         pa_cust_event_rdl_all pcer /*ETANCHEITE DALKIA 2007*/
     WHERE 1 = 1
       AND pp.project_type =  gv_project_type_te
       AND pp.project_id = pt.project_id
       AND nvl(substr(pt.attribute3, 1, 1), 'N') = 'N'
       AND pe.project_id = pt.project_id
       AND pe.task_id = pt.task_id
       AND pe.project_id = pcer.project_id
       AND pcer.project_id = pdr.project_id
       AND pe.task_id = pcer.task_id
       AND pcer.org_id = pdr.ORG_ID /*ETANCHEITE DALKIA 2007*/
       AND pe.event_num = pcer.event_num
       AND pcer.draft_revenue_num = pdr.draft_revenue_num
       AND pdr.gl_date between pd_from_date AND pd_to_date
     GROUP BY pe.project_id, pe.task_id --NB
    HAVING SUM(decode(pe.event_type, gv_event_type_vt, pe.revenue_amount, 0)) != 0;
    
       BEGIN
        dka_tools_pkg.put_debug_message ('MAJ_FACTURE : Flag des taches facturés sur le mois');
        pv_errbuf    := NULL;
        pn_result    := 0;
        
        FOR rec_task IN cur_task LOOP
          UPDATE pa_tasks              pt 
           SET pt.attribute3 = 'Y'  || NVL(substr(pt.attribute3,2,1),'N')
          WHERE pt.task_id = rec_task.task_id;
        END LOOP;

/*          UPDATE -- pa_projects\*_all*\ pp   \*ETANCHEITE DALKIA 2007*\ 
                 pa_tasks              pt --RGH
		   --- 02/02/2017 NBO artf2090329 - SPE052 - Suppression alimentation date du jour dans ATTRIBUTE3
           SET --pp.attribute10 = 'Y' ||substr(pp.attribute10,2,1) || trunc(SYSDATE) --RGH
                 pt.attribute3 = 'Y'  || NVL(substr(pt.attribute3,2,1),'N') -- YWA artf2206811 --|| trunc(SYSDATE) 
          WHERE 1=1
          AND (select pp.project_type from pa_projects pp where pp.project_id = pt.project_id) = gv_project_type_te
          -- AND substr(pp.attribute10,1,1) = 'N' -- RGH
		  --- 09/11/2016 NBO Calcul sur les tâches avec une valeur à nulle
          AND nvl(substr(pt.attribute3,1,1),'N') = 'N' 
          AND EXISTS ( SELECT pe.project_id,
                              pe.task_id --RGH
                       FROM pa.pa_events pe,
                            pa_draft_revenues\*_all*\ pdr, \*ETANCHEITE DALKIA 2007*\
                            pa_cust_event_rdl_all pcer     \*ETANCHEITE DALKIA 2007*\
                       WHERE pe.project_id   = pt.project_id
			   		     --- 02/02/2017 NBO artf2090329 - SPE052 - Suppression alimentation date du jour dans ATTRIBUTE3
					     AND pe.task_id = pt.task_id
                         AND pe.project_id   = pcer.project_id
                         AND pcer.project_id = pdr.project_id
                         AND pe.task_id      = pcer.task_id                         
                         AND pcer.org_id     = pdr.ORG_ID \*ETANCHEITE DALKIA 2007*\
                         AND pe.event_num    = pcer.event_num                         
                         AND pcer.draft_revenue_num = pdr.draft_revenue_num
                         AND pdr.gl_date <= pd_to_date
                         AND pdr.gl_date >= pd_from_date
		               --- 09/11/2016 NBO Bug group by
                       GROUP BY pe.project_id,
                                pe.task_id --NB
                       HAVING SUM (decode(pe.event_type,gv_event_type_vt,pe.revenue_amount,0)) != 0);*/

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := 2;
            pv_errbuf    := SQLERRM;
    END maj_facture;
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
    )
    IS
        CURSOR projects_cur
        IS
         SELECT projet.segment1,
                projet.project_id,
                projet.task_id, --RGH
                projet.task_number, --RGH
                /*
                TO_DATE(projet.attribute2, 'YYYY/MM/DD HH24:MI:SS') as attribute2,
                projet.attribute3,
                projet.attribute7,
                projet.attribute8,
                */               
                TO_DATE(projet.attribute5, 'YYYY/MM/DD HH24:MI:SS') as attribute5,
                projet.attribute1, 
                projet.attribute2,
                projet.facture, -- CUF Travaux externes (Ventes travaux)
                projet.calcule, -- CUF Travaux externes (Ventes travaux)
                -- Montants des calculs
   -- Modif NB. NVL (events_v.vente_travaux, 0) vente_travaux,
  /* Ajout NB*/ NVL (events_v.vente_travaux_mois, 0) vente_travaux_mois,
  /* Ajout NB*/ NVL (events_v.pca_debut_mois, 0) vente_travaux,
                NVL (events_v.tec_directs_mois, 0) tec_directs,
                NVL (events_v.tec_indirects_mois, 0) tec_indirects,
                NVL (events_v.pca_mois, 0) pca,
                NVL (expenditures_v.couts_directs, 0) couts_directs,
                NVL (expenditures_v.couts_indirects, 0) couts_indirects,

                -- Cas dans lequel est le projet /* Modif TB 25/11/05*/
                DECODE (projet.sign_attribute8_moins_fin,
                        -1, 'Clôturé',
                        0, 'Clôturé',
                        DECODE (NVL (events_v.pca_debut_mois + events_v.vente_travaux_mois, 0),
                                0, DECODE (projet.facture,
                                           'N','Non facturé',
                                           DECODE (projet.attribute1,
                                                   gv_regime_regie,'Facturé Régie',
                                                   DECODE (projet.sign_attribute2_moins_fin,
                                                           1, 'Facturé Forfait Date non atteinte',
                                                           'Facturé Forfait Date atteinte')
                                                  )
                                          ),
                        DECODE (projet.attribute1,
                                gv_regime_regie,'Facturé Régie',
                                DECODE (projet.sign_attribute2_moins_fin,
                                        1, 'Facturé Forfait Date non atteinte',
                                        'Facturé Forfait Date atteinte')
                                )
                        )) cas_projet,
                -- Montants à insérer si projet non facturé
                NVL(events_v.tecd_debut, 0) + (NVL (expenditures_v.couts_directs, 0) - (NVL (events_v.tec_directs_mois, 0))) non_fac_tecd,
                NVL(events_v.teci_debut, 0) + (NVL (expenditures_v.couts_indirects, 0) - (NVL (events_v.tec_indirects_mois, 0))) non_fac_teci,
                ((-1) * (NVL (events_v.pca_mois, 0))) non_fac_pca,
                -- Montants à insérer si projet facturé "Régie"
                NVL (events_v.tec_directs_mois, 0) fac_regie_tecd,
                NVL (events_v.tec_indirects_mois, 0) fac_regie_teci,
                -- Montants à insérer si projet facturé "Forfait" date de fin atteinte
                NVL (events_v.tec_directs_mois, 0) fac_forfait_fin_tecd,
                NVL (events_v.tec_indirects_mois, 0) fac_forfait_fin_teci,
                NVL (events_v.pca_mois, 0) fac_forfait_fin_pca,
                -- Montants à insérer si projet facturé "Forfait" date de fin non atteinte
                NVL(events_v.tecd_debut,0) + (NVL (expenditures_v.couts_directs, 0) - NVL (events_v.tec_directs_mois, 0)) fac_forfait_non_fin_tecd,
                NVL(events_v.teci_debut,0) + (NVL (expenditures_v.couts_indirects, 0) - NVL (events_v.tec_indirects_mois, 0)) fac_forfait_non_fin_teci,
  /* Modif NB*/ NVL (events_v.vente_travaux_mois, 0) + NVL(events_v.pca_debut_mois,0) - NVL (events_v.pca_mois, 0)   fac_forfait_non_fin_pca, -- Modif TB 07/07/2005
                NVL(events_v.tecd_debut,0) + NVL(events_v.teci_debut,0) + NVL(events_v.pca_debut_mois,0) total_debut,
                NVL (events_v.tec_directs_mois, 0) + NVL (events_v.tec_indirects_mois, 0) + NVL (events_v.pca_mois, 0) total_mois -- Ajout TB 10/01/2007
           FROM ( SELECT pp.segment1,
                         pp.project_id,
                         pt.task_id,  
                         pt.task_number,                      
                         -- pp.attribute2, --RGH
                         -- pp.attribute3, --RGH
                         -- pp.attribute7, --RGH
                         -- pp.attribute8, --RGH        
                         pt.attribute5, -- Date prévisionnelle de fin                
                         pt.attribute1, -- Attribut de la tâche
                         pt.attribute2, --Date de clôture
                         NVL(SUBSTR(pt.attribute3, 1, 1), 'N') facture, -- CUF Travaux externes (Ventes travaux)
                         NVL(SUBSTR(pt.attribute3, 2, 1), 'N') calcule, -- CUF Travaux externes (Ventes travaux)
                         SIGN(fnd_date.canonical_to_date(pt.attribute2) - last_day(pd_to_date)) AS sign_attribute8_moins_fin,
                         SIGN(TO_DATE(pt.attribute5, 'YYYY/MM/DD HH24:MI:SS') - last_day(pd_to_date)) AS sign_attribute2_moins_fin
                    FROM pa_projects /*_all*/ pp /*ETANCHEITE DALKIA 2007*/
                         ,PA_TASKS pt -- RGH
                   WHERE pp.project_id = pt.project_id
                     --- 09/11/2016 NBO Correction sur les variables
                     --AND upper(pp.project_type) = gv_project_type_te         --'Facturable'
                     --AND upper(pt.DESCRIPTION) like gv_project_type_teds+'%' --'Travaux externes'
                     AND pp.project_type = gv_project_type_te         --'Facturable'
                     -- NBO 02/02/17 artf2091175 - SPE052 - Suppression restriction sur la description de la tâche
                     --AND pt.DESCRIPTION like gv_project_type_teds ||'%' --'Travaux externes'
                     AND upper(pt.task_number) like gv_task_template
                     AND pp.template_flag = 'N'
                     AND pt.attribute1 IN (SELECT ffv.flex_value
                                           FROM fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                                          WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
                                            AND ffvs.flex_value_set_name = 'DKA_GX_TASK_ATTRIBUTE'
                                            AND ffv.description LIKE 'SPECIFIQUE%')
                     --AND pp.attribute4 = gv_type_code_r_spec --RGH
                      /*AND pp.org_id = 
                        (SELECT *
                            FROM pa_implementations_all pi order by set_of_books_id
                           WHERE pi.set_of_books_id = gn_set_of_books)*/ -- RGH
                 ) projet,
                 ( SELECT
                -- Modif NB. SUM (DECODE (pe.event_type, gv_event_type_vt, NVL (pe.revenue_amount, 0), 0)) vente_travaux,
                        /*Ajoutf NB*/
                        --- 30/11/2017 NBO artf2284468: SPE052 - Calcul des TEC et PCA - Pb de gestion de la période dans le curseur projects_cur
                        /*SUM (DECODE (TRUNC (pdr.gl_date, 'MONTH'),
                                     TRUNC (pd_to_date, 'MONTH'), -- du mois
                                     DECODE (pe.event_type,
                                             gv_event_type_vt, NVL (pe.revenue_amount, 0),
                                             0),
                                     0)) vente_travaux_mois,
                        SUM (DECODE (TRUNC (pdr.gl_date, 'MONTH'),
                                     TRUNC (pd_to_date, 'MONTH'), -- du mois
                                     DECODE (pe.event_type,
                                             gv_event_type_tecd, NVL (pe.revenue_amount, 0),
                                             0),
                                     0)) tec_directs_mois,
                        SUM (DECODE (TRUNC (pdr.gl_date, 'MONTH'),
                                     TRUNC (pd_to_date, 'MONTH'),
                                     DECODE (pe.event_type,
                                             gv_event_type_teci, NVL (pe.revenue_amount, 0),
                                             0),
                                     0)) tec_indirects_mois,
                        SUM (DECODE (TRUNC (pdr.gl_date, 'MONTH'),
                                     TRUNC (pd_to_date, 'MONTH'),
                                     DECODE (pe.event_type,
                                             gv_event_type_pca, NVL (pe.revenue_amount, 0),
                                             0),
                                     0)) pca_mois,*/
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_vt, NVL (pe.revenue_amount, 0),
                                             0)) vente_travaux_mois,
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_tecd, NVL (pe.revenue_amount, 0),0)) tec_directs_mois,
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_teci, NVL (pe.revenue_amount, 0),
                                             0)) tec_indirects_mois,
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_pca, NVL (pe.revenue_amount, 0),
                                             0)) pca_mois,                                     
                        /* Ajout NB 12/05/2005 */
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_extourne_tecd, NVL (pe.revenue_amount, 0),
                                             0)) tecd_debut,
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_extourne_teci,  NVL (pe.revenue_amount, 0),
                                             0)) teci_debut,
                        SUM (DECODE (pe.event_type,
                                             gv_event_type_extourne_pca, NVL (pe.revenue_amount, 0),
                                             0)) pca_debut_mois,
                        --- Fin 30/11/2017 NBO artf2284468: SPE052 - Calcul des TEC et PCA - Pb de gestion de la période dans le curseur projects_cur
                        /* Fin Ajout NB 12/05/2005 */
                        pe.project_id, 
                        pe.task_id --RGH
                   FROM pa_events pe,
                        pa_cust_event_rdl_all pcer,
                        pa_draft_revenues/*_all*/ pdr /*ETANCHEITE DALKIA 2007*/
                  WHERE pe.event_type IN (gv_event_type_vt, gv_event_type_tecd, gv_event_type_teci, gv_event_type_pca,
                                          /* Ajout NB 12/05/2005 */
                                          gv_event_type_extourne_tecd, gv_event_type_extourne_teci, gv_event_type_extourne_pca)
                                          /* Fin Ajout NB 12/05/2005 */
                    AND pcer.project_id = pe.project_id
                    AND NVL (pcer.task_id, -1) = NVL (pe.task_id, -1)
                    AND pcer.event_num = pe.event_num
                    AND NVL(pe.attribute_category, -1	) = NVL(DECODE (pe.event_type,
                                                                      gv_event_type_tecd, gv_attr_categ_type_tecd,
                                                                      gv_event_type_teci, gv_attr_categ_type_teci,
                                                                      gv_event_type_pca, gv_attr_categ_type_pca,
                                                                      /* Ajout NB 12/05/2005 */
                                                                      gv_event_type_extourne_tecd, gv_attr_categ_type_tecd,
                                                                      gv_event_type_extourne_teci, gv_attr_categ_type_teci,
                                                                      gv_event_type_extourne_pca, gv_attr_categ_type_pca,
                                                                      /* Fin Ajout NB 12/05/2005 */
                                                                      pe.attribute_category
                                                                      ), -1)
                    AND pdr.project_id = pcer.project_id
                    AND pdr.ORG_ID = pcer.org_id /*ETANCHEITE DALKIA 2007*/
                    AND pdr.draft_revenue_num = pcer.draft_revenue_num
                    AND pdr.transfer_status_code = 'A'
                    AND pdr.gl_date <= pd_to_date
                    AND pdr.gl_date >= pd_from_date
		          --- 09/11/2016 NBO Correction sur les group by
                  GROUP BY pe.project_id, 
                           pe.task_id) events_v,
                  --2--events_v--

                (SELECT pcdl.project_id,
                        pcdl.task_id, -- RGH
                        SUM (NVL (pcdl.amount, 0)) couts_directs,
                        SUM (NVL (pcdl.denom_burdened_cost, 0) - NVL (pcdl.amount, 0)) couts_indirects
                   FROM pa_cost_distribution_lines pcdl
                  WHERE pcdl.transfer_status_code IN ('A', 'V')
                    --- 09/11/2016 NBO Remplacement D par R
                    AND pcdl.line_type = 'R'
                    AND pcdl.gl_date <= pd_to_date
                    AND pcdl.gl_date >= pd_from_date
                    AND pcdl.expenditure_item_id IN (SELECT pei.expenditure_item_id
                                                       FROM pa_expenditure_items_all pei
                                                      WHERE pei.expenditure_type IN (SELECT pet.expenditure_type
                                                                                       FROM pa_expenditure_types pet
                                                                                      WHERE pet.attribute1= 'Y'))
                    AND EXISTS (SELECT 'x'
                                  FROM pa_projects pp2,
                                       PA_TASKS pt
                                 WHERE pp2.project_id   = pt.project_id
                                   AND pp2.project_id   = pcdl.project_id
                                   AND pp2.project_type = gv_project_type_te
								   -- NBO 02/02/17 artf2091175 - SPE052 - Suppression restriction sur la description de la tâche
                                   --- 09/11/2016 NBO Correction sur les variables
                                   --AND pt.DESCRIPTION   LIKE gv_project_type_teds||'%' --'Travaux externes'
                                   AND pt.task_number like gv_task_template
                                   AND pp2.template_flag = 'N'
                                   --AND pp2.attribute4 = gv_type_code_r_spec --RGH
                                   /*AND pp2.org_id = (SELECT pi2.org_id
                                                       FROM pa_implementations pi2
                                                      WHERE pi2.set_of_books_id = gn_set_of_books)*/ )
            --- 09/11/2016 NBO Correction sur les group by      
            GROUP BY pcdl.project_id,
                           pcdl.task_id) expenditures_v
          WHERE events_v.project_id(+) = projet.project_id
            AND expenditures_v.project_id(+) = projet.project_id
            AND events_v.task_id(+) = projet.task_id       -- RGH
            AND expenditures_v.task_id(+) = projet.task_id -- RGH
            -- Limitation aux projets pour lesquels il y a des évènements à insérer
            AND (    (   fnd_date.canonical_to_date (projet.attribute2) > last_day(pd_to_date)
                      OR projet.attribute2 IS NULL)
                 AND (   (    projet.facture = 'N'
                          AND NVL(events_v.vente_travaux_mois, 0) = 0 -- Projet non facturé -- Modif TB 08/08/05
                          AND (   (NVL(events_v.tecd_debut,0) + NVL (expenditures_v.couts_directs, 0) - NVL (events_v.tec_directs_mois, 0)) != 0 -- non_fac_tecd
                               OR (NVL(events_v.teci_debut,0) + NVL (expenditures_v.couts_indirects, 0) - NVL (events_v.tec_indirects_mois, 0)) != 0 -- non_fac_teci
                               OR ((-1) * NVL (events_v.pca_mois, 0)) != 0 -- non_fac_pca
                              )
                         )
                      OR (    (   projet.facture = 'Y'
                               OR NVL(events_v.vente_travaux_mois, 0) != 0)  -- Modif TB 07/07/05
                          AND (    projet.attribute1 = gv_regime_forfait -- Projet de type Forfait
                               AND to_date(projet.attribute5, 'YYYY/MM/DD HH24:MI:SS') > last_day(pd_to_date) -- Date de fin non atteinte
                               AND (   (NVL(events_v.tecd_debut,0) + NVL (expenditures_v.couts_directs, 0) - NVL (events_v.tec_directs_mois, 0)) != 0
                                    OR (NVL(events_v.teci_debut,0) + NVL (expenditures_v.couts_indirects, 0) - NVL (events_v.tec_indirects_mois, 0)) !=0
                                    OR (NVL(events_v.vente_travaux_mois,0) + NVL (events_v.pca_debut_mois, 0) - NVL (events_v.pca_mois, 0)) !=0
                                   )
                              )
                         )
                     )
                );


        projects_rec   projects_cur%ROWTYPE;
    BEGIN
        pv_errbuf    := NULL;
        pn_result    := 0;
        --Calcul de la date des évenements:

        dka_tools_pkg.put_debug_message ('(+) process_projects');
        dka_tools_pkg.put_debug_message ('Début Traitement des Projets');
        --Ouvrir le curseur et boucler:
        OPEN projects_cur;

        LOOP
            FETCH projects_cur INTO projects_rec;
            EXIT WHEN projects_cur%NOTFOUND;

            DECLARE
                e_error      EXCEPTION;
                vv_message   VARCHAR2 (500);
                vn_result    NUMBER (22)    := 0;
            BEGIN
                SAVEPOINT point_arret;
                dka_tools_pkg.put_outdebug_message (
                    '*****************************************************************************'
                );
				-- NBO 14/02/2017 artf2099957 - SPE052 - Affichage de la tâche dans le journal
                --dka_tools_pkg.put_outdebug_message (projects_rec.task_id || ' : ' );  --RGH              
                --dka_tools_pkg.put_outdebug_message (
                --    projects_rec.segment1 || '(' || TO_CHAR (projects_rec.project_id) || ') : ' || projects_rec.cas_projet
                --);
                dka_tools_pkg.put_outdebug_message (
                    projects_rec.segment1 || '(' || TO_CHAR (projects_rec.project_id) || ')'
                );
                dka_tools_pkg.put_outdebug_message (projects_rec.task_number || ' (' || projects_rec.task_id || ')' || ' : ' || projects_rec.cas_projet);  --RGH   
                
                IF    fnd_date.canonical_to_date (projects_rec.attribute2) > last_day(pd_to_date)  OR projects_rec.attribute2 IS NULL
                THEN -- Projet actif
                    IF  ( projects_rec.vente_travaux_mois = 0
                        AND projects_rec.pca = 0
                        AND ( projects_rec.facture = 'N' OR projects_rec.facture is null) -- modif TB 08/08/2005
                        )
                    THEN -- Non Facturé

                        -- On n'insere plus si le projet est deja calculé et que la somme des TEC/PCA DEBUT ET FIN est nulle
                        IF (( projects_rec.calcule = 'Y')
                              AND (projects_rec.total_debut = 0 )
                              AND (projects_rec.total_mois = 0 )) -- Ajout TB 10/01/2007
                           THEN
                               dka_tools_pkg.put_outdebug_message ('Rupture de calcul détectée sur Projet '|| projects_rec.segment1 || ' Tâche : ' || projects_rec.task_number ||'. Flag calcul : '||  projects_rec.calcule);
                        ELSE

                          -- Insertion des TEC sur Coûts Directs à constater
                          IF projects_rec.non_fac_tecd != 0
                          THEN
                              maj_calcule(projects_rec.project_id, projects_rec.task_id, pv_errbuf,pn_result);-- on indique que c calculé
                              dka_tools_pkg.put_outdebug_message (
                                  'TEC sur Coûts Directs à constater : '|| TO_CHAR (projects_rec.non_fac_tecd)
                              );
                              --dka_tools_pkg.pa_insert_event ( --RGH
                              dka_pa_tools_pkg.pa_insert_event(
                                  pn_task_id                     => projects_rec.task_id, --RGH
                                  pv_event_type                  => gv_event_type_tecd,
                                  pn_amount                      => projects_rec.non_fac_tecd,
                                  pn_project_id                  => projects_rec.project_id,
                                  pd_completion_date             => pd_to_date,
                                  pn_group_id                    => pn_group_id,
                                  pv_batch_name                  => gv_gl_batch_name,
                                  pv_insert_revenue_flag         => 'Y',
                                  pv_event_attr_context          => gv_attr_categ_type_tecd,
                                  pv_description                 => gv_event_type_tecd,
                                  pv_errbuf                      => vv_message,
                                  pn_result                      => vn_result
                              );

                              IF vn_result != 0
                              THEN
                                  RAISE e_error;
                              END IF;

                              --Insertion d'une trace dans la table de travail:
                              INSERT INTO dka_spatravcours_tmp
                                          (project_id,
                                           segment1,
                                           task_id,
                                           task_number, 
                                           event_type,
                                           amount,
                                           period_name,
                                           period_extourne,
                                           reversal_flag,
                                           creation_date,
                                           created_by,
                                           last_update_date,
                                           last_updated_by,
                                           last_update_login,
                                           request_id
                                          )
                              VALUES      (projects_rec.project_id,
                                           projects_rec.segment1,
                                           projects_rec.task_id,
                                           projects_rec.task_number,
                                           gv_event_type_tecd,
                                           projects_rec.non_fac_tecd,
                                           gv_period_name,
                                           gv_periode_suivante,
                                           'N',
                                           SYSDATE,
                                           gv_created_by,
                                           SYSDATE,
                                           gv_created_by,
                                           gv_last_update_login,
                                           gv_request_id
                                          );
                          END IF;

                          -- Insertion des TEC sur Coûts Indirects à constater
                          IF projects_rec.non_fac_teci != 0
                          THEN
                              maj_calcule(projects_rec.project_id, projects_rec.task_id,pv_errbuf,pn_result);-- on indique que c'est calculé
                              dka_tools_pkg.put_outdebug_message (
                                  'TEC sur Coûts Indirects à constater : '|| TO_CHAR (projects_rec.non_fac_teci)
                              );
                              --dka_tools_pkg.pa_insert_event ( --RGH
                              dka_pa_tools_pkg.pa_insert_event(
                                  pn_task_id                     => projects_rec.task_id,
                                  pv_event_type                  => gv_event_type_teci,
                                  pn_amount                      => projects_rec.non_fac_teci,
                                  pn_project_id                  => projects_rec.project_id,
                                  pd_completion_date             => pd_to_date,
                                  pn_group_id                    => pn_group_id,
                                  pv_batch_name                  => gv_gl_batch_name,
                                  pv_insert_revenue_flag         => 'Y',
                                  pv_event_attr_context          => gv_attr_categ_type_teci,
                                  pv_description                 => gv_event_type_teci,
                                  pv_errbuf                      => vv_message,
                                  pn_result                      => vn_result
                              );

                              IF vn_result != 0
                              THEN
                                  RAISE e_error;
                              END IF;

                              --Insertion d'une trace dans la table de travail:
                              INSERT INTO dka_spatravcours_tmp
                                          (task_id,
                                           task_number,
                                           project_id,
                                           segment1,
                                           event_type,
                                           amount,
                                           period_name,
                                           period_extourne,
                                           reversal_flag,
                                           creation_date,
                                           created_by,
                                           last_update_date,
                                           last_updated_by,
                                           last_update_login,
                                           request_id
                                          )
                              VALUES      (projects_rec.task_id,
                                           projects_rec.task_number,
                                           projects_rec.project_id,
                                           projects_rec.segment1,
                                           gv_event_type_teci,
                                           projects_rec.non_fac_teci,
                                           gv_period_name,
                                           gv_periode_suivante,
                                           'N',
                                           SYSDATE,
                                           gv_created_by,
                                           SYSDATE,
                                           gv_created_by,
                                           gv_last_update_login,
                                           gv_request_id
                                          );
                          END IF;
                        END IF;
                    ELSE -- Facturé

                        IF projects_rec.attribute1 = gv_regime_regie
                        THEN --Facturé + Régime Régie
                             -- Modif PHENIX 2004
                            -- pas d'Insertion des TEC sur Coûts Directs à extourner
                            NULL;
                            -- Fin Modif PHENIX 2004
                        ELSIF      projects_rec.attribute1 = gv_regime_forfait
                               AND projects_rec.attribute5 > last_day(pd_to_date)
                        THEN --Facturé + Régime Forfait avec Date de Fin des Travaux non atteinte


                        -- On n'insere plus si le projet est deja calculé et que la somme des TEC/PCA DEBUT ET FIN est nulle
                        IF (( projects_rec.calcule = 'Y')
                              AND (projects_rec.total_debut = 0 )
                              AND (projects_rec.total_mois = 0 )) -- Ajout TB 10/01/2007
                        THEN
                              dka_tools_pkg.put_outdebug_message ('Rupture de calcul détectée sur Projet '|| projects_rec.segment1 || ' , sur tâche ' || projects_rec.task_number||' . Flag calcul : '||  projects_rec.calcule);
                        ELSE
                            -- Insertion des TEC sur Coûts Directs à constater
                            IF projects_rec.fac_forfait_non_fin_tecd != 0
                            THEN

                                maj_calcule(projects_rec.project_id,projects_rec.task_id, pv_errbuf,pn_result);-- on indique que c'est calculé
                                dka_tools_pkg.put_outdebug_message (
                                    'TEC sur Coûts Directs à constater : '|| TO_CHAR (projects_rec.fac_forfait_non_fin_tecd)
                                );
                                --dka_tools_pkg.pa_insert_event ( --RGH
                                dka_pa_tools_pkg.pa_insert_event(
                                    pn_task_id                     => projects_rec.task_id,
                                    pv_event_type                  => gv_event_type_tecd,
                                    pn_amount                      => projects_rec.fac_forfait_non_fin_tecd,
                                    pn_project_id                  => projects_rec.project_id,
                                    pd_completion_date             => pd_to_date,
                                    pn_group_id                    => pn_group_id,
                                    pv_batch_name                  => gv_gl_batch_name,
                                    pv_insert_revenue_flag         => 'Y',
                                    pv_event_attr_context          => gv_attr_categ_type_tecd,
                                    pv_description                 => gv_event_type_tecd,
                                    pv_errbuf                      => vv_message,
                                    pn_result                      => vn_result
                                );

                                IF vn_result != 0
                                THEN
                                    RAISE e_error;
                                END IF;

                                -- Modif PHENIX 2004
                                --Insertion d'une trace dans la table de travail:
                                INSERT INTO dka_spatravcours_tmp
                                            (task_id,
                                             task_number,
                                             project_id,
                                             segment1,
                                             event_type,
                                             amount,
                                             period_name,
                                             period_extourne,
                                             reversal_flag,
                                             creation_date,
                                             created_by,
                                             last_update_date,
                                             last_updated_by,
                                             last_update_login,
                                             request_id
                                            )
                                VALUES      (projects_rec.task_id,
                                             projects_rec.task_number,                                             
                                             projects_rec.project_id,
                                             projects_rec.segment1,
                                             gv_event_type_tecd,
                                             projects_rec.fac_forfait_non_fin_tecd,
                                             gv_period_name,
                                             gv_periode_suivante,
                                             'N',
                                             SYSDATE,
                                             gv_created_by,
                                             SYSDATE,
                                             gv_created_by,
                                             gv_last_update_login,
                                             gv_request_id
                                            );
                                 -- Fin Modif PHENIX 2004
                            END IF;

                            -- Insertion des TEC sur Coûts Indirects à constater
                            IF projects_rec.fac_forfait_non_fin_teci != 0
                            THEN
                                maj_calcule(projects_rec.project_id, projects_rec.task_id,pv_errbuf,pn_result);-- on indique que c'est calculé
                                dka_tools_pkg.put_outdebug_message (
                                    'TEC sur Coûts Indirects à constater : '|| TO_CHAR (projects_rec.fac_forfait_non_fin_teci)
                                );
                                --dka_tools_pkg.pa_insert_event ( --RGH
                                dka_pa_tools_pkg.pa_insert_event(
                                    pn_task_id                     => projects_rec.task_id, --RGH
                                    pv_event_type                  => gv_event_type_teci,
                                    pn_amount                      => projects_rec.fac_forfait_non_fin_teci,
                                    pn_project_id                  => projects_rec.project_id,
                                    pd_completion_date             => pd_to_date,
                                    pn_group_id                    => pn_group_id,
                                    pv_batch_name                  => gv_gl_batch_name,
                                    pv_insert_revenue_flag         => 'Y',
                                    pv_description                 => gv_event_type_teci,
                                    pv_event_attr_context          => gv_attr_categ_type_teci,
                                    pv_errbuf                      => vv_message,
                                    pn_result                      => vn_result
                                );

                                IF vn_result != 0
                                THEN
                                    RAISE e_error;
                                END IF;

                                -- Modif PHENIX 2004
                                --Insertion d'une trace dans la table de travail:
                                INSERT INTO dka_spatravcours_tmp
                                            (task_id,
                                             task_number,
                                             project_id,
                                             segment1,
                                             event_type,
                                             amount,
                                             period_name,
                                             period_extourne,
                                             reversal_flag,
                                             creation_date,
                                             created_by,
                                             last_update_date,
                                             last_updated_by,
                                             last_update_login,
                                             request_id
                                            )
                                VALUES      (projects_rec.task_id,
                                             projects_rec.task_number,
                                             projects_rec.project_id,
                                             projects_rec.segment1,
                                             gv_event_type_teci,
                                             projects_rec.fac_forfait_non_fin_teci,
                                             gv_period_name,
                                             gv_periode_suivante,
                                             'N',
                                             SYSDATE,
                                             gv_created_by,
                                             SYSDATE,
                                             gv_created_by,
                                             gv_last_update_login,
                                             gv_request_id
                                            );
                                  -- Fin Modif PHENIX 2004
                            END IF;

                            -- Insertion des PCA à constater
                            IF projects_rec.fac_forfait_non_fin_pca != 0
                            THEN

                                maj_calcule(projects_rec.project_id, projects_rec.task_id,pv_errbuf,pn_result);-- on indique que c'est calculé
                                dka_tools_pkg.put_outdebug_message (
                                    'PCA à constater : '|| TO_CHAR (projects_rec.fac_forfait_non_fin_pca)
                                );
                                --dka_tools_pkg.pa_insert_event ( --RGH
                                dka_pa_tools_pkg.pa_insert_event(
                                    pn_task_id                     => projects_rec.task_id, --RGH
                                    pv_event_type                  => gv_event_type_pca,
                                    pn_amount                      => projects_rec.fac_forfait_non_fin_pca,
                                    pn_project_id                  => projects_rec.project_id,
                                    pd_completion_date             => pd_to_date,
                                    pn_group_id                    => pn_group_id,
                                    pv_batch_name                  => gv_gl_batch_name,
                                    pv_insert_revenue_flag         => 'Y',
                                    pv_description                 => gv_event_type_pca,
                                    pv_event_attr_context          => gv_attr_categ_type_pca,
                                    pv_errbuf                      => vv_message,
                                    pn_result                      => vn_result
                                );

                                IF vn_result != 0
                                THEN
                                    RAISE e_error;
                                END IF;

                                -- Modif PHENIX 2004
                                --Insertion d'une trace dans la table de travail:
                                INSERT INTO dka_spatravcours_tmp
                                            (task_id,
                                             task_number,
                                             project_id,
                                             segment1,
                                             event_type,
                                             amount,
                                             period_name,
                                             period_extourne,
                                             reversal_flag,
                                             creation_date,
                                             created_by,
                                             last_update_date,
                                             last_updated_by,
                                             last_update_login,
                                             request_id
                                            )
                                VALUES      (projects_rec.task_id,
                                             projects_rec.task_number,
                                             projects_rec.project_id,
                                             projects_rec.segment1,                                             
                                             gv_event_type_pca,
                                             projects_rec.fac_forfait_non_fin_pca,
                                             gv_period_name,
                                             gv_periode_suivante,
                                             'N',
                                             SYSDATE,
                                             gv_created_by,
                                             SYSDATE,
                                             gv_created_by,
                                             gv_last_update_login,
                                             gv_request_id
                                            );
                                -- Fin Modif PHENIX 2004
                            END IF;
                        END IF;
                      END IF;

                    END IF;
                ELSIF      fnd_date.canonical_to_date (projects_rec.attribute2) <= last_day(pd_to_date)
                       --AND fnd_date.canonical_to_date (projects_rec.attribute7) > pd_to_date
                THEN -- Projet clôturé
                    -- Pas d' Insertion des TEC sur Coûts Directs à extourner
                    -- Modif PHENIX 2004
                    NULL;
                    -- Fin Modif PHENIX 2004
                END IF;
            EXCEPTION
                WHEN e_error
                THEN
                    ROLLBACK TO point_arret;
                    vv_message    := 'Projet ' || projects_rec.segment1 || ' - Tâche ' || projects_rec.task_number ||' : ' || vv_message;
                    dka_tools_pkg.put_outdebug_message (vv_message);
                    pn_result     := 1;
                    pv_errbuf     := 'Des projets ont été rejetés.';
                WHEN OTHERS
                THEN
                    ROLLBACK TO point_arret;
                    vv_message    := 'Projet ' || projects_rec.segment1 || ' - Tâche ' || projects_rec.task_number ||' : ' || SQLERRM;
                    dka_tools_pkg.put_outdebug_message (vv_message);
                    pn_result     := 1;
                    pv_errbuf     := 'Des projets ont été rejetés.';
            END;
        END LOOP;

        CLOSE projects_cur;
        dka_tools_pkg.put_debug_message ('Fin Traitement des Projets');
        dka_tools_pkg.put_debug_message ('(-) process_projects');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := SQLERRM;

            IF projects_cur%ISOPEN
            THEN
                CLOSE projects_cur;
            END IF;
    END process_projects;


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
    )
    IS
        vn_count                  NUMBER;
        vv_message                VARCHAR2 (200);

        --Déclaration du curseur qui balaye l'ensemble des lignes:
        -- Modif PHENIX 2004

        CURSOR spatravcours_output_cur
        IS
            SELECT   *
            FROM     dka_spatravcours_tmp dst
            WHERE    request_id = gv_request_id
            ORDER BY dst.segment1;

        -- Fin Modif PHENIX 2004

        spatravcours_output_rec   spatravcours_output_cur%ROWTYPE;
    BEGIN
        pv_errbuf     := NULL;
        pn_result     := 0;
        dka_tools_pkg.put_debug_message ('PROC_CREATE_OUTPUT:Initialisation des Variables de Sortie');
        --Initialisation du Compteur à zéro:

        vn_count      := 0;
        --Affichage de l'entête:

        vv_message    := 'Liste des évenements insérés pour '||gv_org_name ;
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '----------------------------';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := ' ';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := RPAD ('TACHE', 10) || ' ' || RPAD ('PROJET', 10) || ' ' || RPAD ('TYPE EVENEMENT', 30) || ' ' || RPAD ('MONTANT', 20);
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := RPAD ('-', 10, '-') || ' ' || RPAD ('-', 10, '-') || ' ' || RPAD ('-', 30, '-') || ' ' || RPAD ('-', 20, '-');
        fnd_file.put_line (fnd_file.output, vv_message);
        dka_tools_pkg.put_debug_message ('PROC_CREATE_OUTPUT:Affichage de l''Entête');
        OPEN spatravcours_output_cur;

        LOOP
            FETCH spatravcours_output_cur INTO spatravcours_output_rec;
            EXIT WHEN spatravcours_output_cur%NOTFOUND;
            --Pour chaque Enregistrement Afficher les données:

            vv_message    :=    RPAD (spatravcours_output_rec.TASK_NUMBER, 10)
                             || ' '
                             || RPAD (spatravcours_output_rec.segment1, 10)
                             || ' '
                             || RPAD (spatravcours_output_rec.event_type, 30)
                             || ' '
                             || LPAD (TO_CHAR (spatravcours_output_rec.amount, '999G999G999G990D00'), 20);
            fnd_file.put_line (fnd_file.output, vv_message);
            --Incrémenter le Compteur:

            vn_count      := vn_count + 1;
        END LOOP;

        CLOSE spatravcours_output_cur;
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        vv_message    := '';
        fnd_file.put_line (fnd_file.output, vv_message);
        --Afficher le Compteur:

        vv_message    := 'Nombre de projets traités : ' || TO_CHAR (vn_count);
        fnd_file.put_line (fnd_file.output, vv_message);
        dka_tools_pkg.put_debug_message ('Lister la TABLE de Travail');
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
--  VALEUR RETOURNEE :

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
        vn_set_of_books_id     gl_interface.set_of_books_id%TYPE;
        vn_interface_run_id    gl_interface_control.interface_run_id%TYPE;
        vn_dummy               NUMBER;
        /*** ADR le 14/10/2003 ***/
        vv_phase               VARCHAR2 (10);
        vv_status              VARCHAR2 (10);
        vv_dev_phase           VARCHAR2 (10);
        vv_dev_status          VARCHAR2 (10);
        vv_errbuf              VARCHAR2 (150);
    BEGIN
        dka_tools_pkg.put_debug_message ('gl_open_interface début');
        
        dka_tools_pkg.put_debug_message ('GET GL_SET_OF_BKS_ID');
        
		-- NBO 14/02/2017 artf2099600 - SPE052 - Prob lancement Easylink
        -- Récupération du Set_Of_Books_Id
        --vn_set_of_books_id    := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
        vn_set_of_books_id := gn_set_of_books;

        dka_tools_pkg.put_debug_message ('gl_journal_import_s.NEXTVAL');
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
            dka_tools_pkg.put_debug_message ('Aucune donnée trouvée pour le group_id :'|| pn_group_id);

            RETURN;
        END IF;
        
        
        SELECT DISTINCT user_je_source_name INTO vv_je_source_name FROM gl_interface gi WHERE gi.GROUP_ID = pn_group_id;
        dka_tools_pkg.put_debug_message ('user_je_source_name:'||vv_je_source_name);
        
        --- 09/11/2016 NBO Bug sur la récupération du je_source_name
        SELECT DISTINCT gjs.je_source_name
          INTO vv_je_source_name
          FROM gl_interface gi, gl_je_sources_tl gjs
         WHERE gjs.user_je_source_name = gi.user_je_source_name
           AND gjs.language = 'F'
           AND gi.group_id = pn_group_id;
           
        dka_tools_pkg.put_debug_message (' vv_je_source_name:'|| vv_je_source_name);                

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
                     vn_set_of_books_id,
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
		--- 09/11/2016 NBO Lancement easylink en mode R12
        vn_request_id         := fnd_request.submit_request (
                                     'SQLGL', --APPL
                                     'GLLEZL', --PROG
                                     NULL, --PROGRAM_NAME
                                     NULL, --START
                                     FALSE, --SUB_REQUEST
                                     vn_interface_run_id, --ARGUMENT1
                                     --vn_set_of_books_id, --ARGUMENT2
                                     FND_PROFILE.VALUE('GL_ACCESS_SET_ID'), --ARGUMENT2
                                     'N', --ARGUMENT3
                                     NULL, --ARGUMENT4
                                     NULL, --ARGUMENT5
                                     'N', --ARGUMENT6
                                     -- NBO 14/02/2017 artf2099600 - SPE052 - Prob lancement Easylink
                                     'O', --ARGUMENT7
                                     'Y' --ARGUMENT8
                                 );
        /*ADR le 14/10/2003 DEBUT*/
        COMMIT;

        IF NOT (fnd_concurrent.wait_for_request (vn_request_id, 15, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_errbuf))
        THEN
            pn_result    := 2;
			-- NBO 14/02/2017 - artf2098706 - SPE052 : Logs du traitement DKA : Extourne des TEC et PCA : KO
            pv_errbuf    := 'Le lancement de l''Easylink ('||vn_request_id||') a échoué !';
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
            --- 09/11/2016 NBO Bug sur les exceptions
            pn_result    := 2;
            pv_errbuf    := 'gl_open_interface : ' || SQLERRM;
    END gl_open_interface;


-------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --             pv_period_name                  Entrée
 --             pv_errbuf                       Entrée/Sortie
 --             pn_retcode                      Sortie
 --
 --  VALEUR RETOURNEE :

------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pv_period_name   IN       VARCHAR2
    )
    IS
        vn_result     NUMBER;
        -- Modif PHENIX 2004--
        vv_errbuf     VARCHAR2 (500) := '';
        vd_to_date    DATE;
        vd_from_date  DATE;
        vn_group_id   NUMBER;
        e_erreur      EXCEPTION;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        -- PROC_MAIN: Lancement de  INIT
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN: Lancement de  INIT');
        dka_spatravcours_pkg.init (pv_period_name, vd_to_date, vd_from_date, vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        
        ELSIF vn_result = 2
        THEN
            RAISE e_erreur;
        END IF;
        -- PROC_MAIN : Lancement CLEAR_SPATRAVCOURS_TMP
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Lancement CLEAR_SPATRAVCOURS_TMP');
        dka_spatravcours_pkg.clear_spatravcours_tmp (vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        
        ELSIF vn_result = 2
        THEN
            RAISE e_erreur;
        END IF;
        -- Fin Modif PHENIX 2004--

        -- PROC_MAIN : Lancement MAJ FLAG FACTURE
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Lancement MAJ FLAG FACTURE');
        dka_spatravcours_pkg.maj_facture(vd_to_date,vd_from_date,vv_errbuf,vn_result);

        IF vn_result = 2
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
            RAISE e_erreur;
        END IF;

        --PROC_MAIN : Lancement PROCESS_PROJECTS -- Modif PHENIX 2004
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Lancement PROCESS_PROJECTS');
        dka_spatravcours_pkg.process_projects (vd_to_date, vd_from_date,vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        ELSIF vn_result = 2
        THEN
            RAISE e_erreur;
        END IF;

        dka_tools_pkg.put_outdebug_message ('');
        dka_tools_pkg.put_outdebug_message ('*****************************************************************************');
        dka_tools_pkg.put_outdebug_message ('');
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Lancement CREATE_OUTPUT');
		-- NBO 14/02/2017 - artf2098706 - SPE052 : Logs du traitement DKA : Extourne des TEC et PCA : KO
        dka_spatravcours_pkg.create_output (vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        ELSIF vn_result = 2
        THEN
            RAISE e_erreur;
        END IF;
        --PROC_MAIN : Lancement GL_OPEN_INTERFACE
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Lancement GL_OPEN_INTERFACE');
        dka_spatravcours_pkg.gl_open_interface (vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        ELSIF vn_result = 2
        THEN
            RAISE e_erreur;
        END IF;
    EXCEPTION
        WHEN e_erreur
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
            ROLLBACK;
            dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Erreur '|| vv_errbuf);
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            ROLLBACK;
            dka_tools_pkg.put_outdebug_message ('PROC_MAIN : Erreur non gérée '|| TO_CHAR (SQLCODE) || ' : ' || SQLERRM);
    END main;


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
    PROCEDURE REVERSE (
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pn_group_id   IN       NUMBER
    )
    IS
        vn_result     NUMBER                := 0;
        vv_errbuf     VARCHAR2 (500)        := '';
       -- vd_to_date    DATE;
       -- vn_group_id   NUMBER;
        e_erreur      EXCEPTION;

        CURSOR reverse_cur
        IS
            SELECT dst.ROWID rowid_tmp,
                   dst.project_id, -- ETANCHEITE DALKIA 2007
                   dst.segment1, -- ETANCHEITE DALKIA 2007
                   pt.task_id,     -- RGH
                   pt.task_number, -- RGH
                   dst.period_name,
                   dst.period_extourne,
                   gps.start_date,
                   event_type,
                   DECODE (
                       event_type,
                       gv_event_type_tecd, gv_event_type_extourne_tecd,
                       gv_event_type_teci, gv_event_type_extourne_teci,
                       gv_event_type_pca, gv_event_type_extourne_pca,
                       NULL
                   ) event_type_extourne,
                   DECODE (
                       event_type,
                       gv_event_type_tecd, gv_attr_categ_type_tecd,
                       gv_event_type_teci, gv_attr_categ_type_teci,
                       gv_event_type_pca, gv_attr_categ_type_pca,
                       NULL
                   ) attribute_category,
                   DECODE (
                       event_type,
                       gv_event_type_tecd, gv_event_type_extourne_tecd,
                       gv_event_type_teci, gv_event_type_extourne_teci,
                       gv_event_type_pca, gv_event_type_extourne_pca,
                       NULL
                   ) description,
                   amount
            FROM   pa_projects /*ETANCHEITE DALKIA 2007*/ pp,
                   PA_TASKS pt,
                   dka_spatravcours_tmp dst,
                   gl_period_statuses gps

             WHERE pp.project_id = pt.project_id
               AND pp.project_id = dst.project_id /*ETANCHEITE DALKIA 2007*/
               --- 09/11/2016 NBO Correction sur les variables
               AND pp.project_type  = gv_project_type_te
			   -- NBO 02/02/17 artf2091175 - SPE052 - Suppression restriction sur la description de la tâche
               --AND pt.DESCRIPTION   LIKE gv_project_type_teds||'%' --'Travaux externes'
               AND pt.task_number like gv_task_template
               AND pt.task_id = dst.task_id
               AND  NVL (dst.reversal_flag, 'N') = 'N'
                   -- la ligne est ramenée si la periode extourne est ouverte
               AND gps.closing_status = 'O'
               AND dst.period_extourne = gps.period_name
               AND gps.set_of_books_id = gn_set_of_books
               AND gps.application_id = 101;

        reverse_rec   reverse_cur%ROWTYPE;
    BEGIN
        pn_retcode    := 0;
        pv_errbuf     := '';
        dka_tools_pkg.put_debug_message ('(+) reverse');
        dka_tools_pkg.put_outdebug_message ('Début Traitement extourne des projets');
        --Ouvrir le curseur et boucler:
        OPEN reverse_cur;

        LOOP
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
                    vv_errbuf    := '**** warning : le type d événement d extourne est indéterminé  ';
                    RAISE e_error;
                END IF;

                dka_tools_pkg.put_outdebug_message ('*****************************************************************************');
                dka_tools_pkg.put_outdebug_message (
                    reverse_rec.segment1 || '  ' || reverse_rec.task_number || '  ' || reverse_rec.event_type || '  ' || reverse_rec.amount || '  ' || reverse_rec.description
                );
                dka_tools_pkg.put_debug_message ('pa_insert_event...');
                --dka_tools_pkg.pa_insert_event ( --RGH
                dka_pa_tools_pkg.pa_insert_event(
                    pn_task_id                     => reverse_rec.task_id, --RGH
                    pv_event_type                  => reverse_rec.event_type_extourne,
                    pn_amount                      => reverse_rec.amount,
                    pn_project_id                  => reverse_rec.project_id,
                    pd_completion_date             => reverse_rec.start_date,
                    pn_group_id                    => pn_group_id,
                    pv_batch_name                  => gv_gl_batch_name,
                    pv_insert_revenue_flag         => 'Y',
                    pv_event_attr_context          => reverse_rec.attribute_category,
                    pv_description                 => reverse_rec.description,
                    pv_errbuf                      => vv_errbuf,
                    pn_result                      => vn_result
                );

                IF vn_result != 0
                THEN
                    vv_errbuf    :=    'Rejet pour l''insertion d''evenement sur le segment1 '
                                    || reverse_rec.segment1
                                    ||'sur la tâche '
                                    || reverse_rec.task_number
                                    || ' sur le type d''evenement '
                                    || reverse_rec.event_type_extourne
                                    || ' pour le montant '
                                    || reverse_rec.amount
                                    || ' avec l''erreur '
                                    || vv_errbuf;
                    RAISE e_error;
                END IF;

                UPDATE dka_spatravcours_tmp
                SET    reversal_flag = 'Y',
                       request_id = gv_request_id,
                       last_update_date = SYSDATE,
                       last_updated_by = gv_last_updated_by,
                       last_update_login = gv_last_update_login,
                       message_erreur = ''
                WHERE  ROWID = reverse_rec.rowid_tmp;

                dka_tools_pkg.put_debug_message ('table tmp mise à jour correctement');
            EXCEPTION
                WHEN e_error
                THEN
                    ROLLBACK TO point_arret;
                    pn_retcode    := 1;
                    dka_tools_pkg.put_outdebug_message (vv_errbuf);

                    UPDATE dka_spatravcours_tmp
                    SET    request_id = gv_request_id,
                           last_update_date = SYSDATE,
                           last_updated_by = gv_last_updated_by,
                           last_update_login = gv_last_update_login,
                           message_erreur = vv_errbuf
                    WHERE  ROWID = reverse_rec.rowid_tmp;
                WHEN OTHERS
                THEN
                    vv_errbuf     := SQLERRM;
                    ROLLBACK TO point_arret;
                    pn_retcode    := 1;
                    dka_tools_pkg.put_outdebug_message (vv_errbuf);

                    UPDATE dka_spatravcours_tmp
                    SET    request_id = gv_request_id,
                           last_update_date = SYSDATE,
                           last_updated_by = gv_last_updated_by,
                           last_update_login = gv_last_update_login,
                           message_erreur = vv_errbuf
                    WHERE  ROWID = reverse_rec.rowid_tmp;
            END;
        END LOOP;

        CLOSE reverse_cur;
        dka_tools_pkg.put_debug_message ('Fin Traitement reverse');
        dka_tools_pkg.put_debug_message ('(-) reverse ');
    EXCEPTION
        WHEN e_erreur
        THEN
            ----------
            ROLLBACK;
            ----------

            UPDATE dka_spatravcours_tmp
            SET    request_id = gv_request_id,
                   last_update_date = SYSDATE,
                   last_updated_by = gv_last_updated_by,
                   last_update_login = gv_last_update_login,
                   message_erreur = pv_errbuf
            WHERE  ROWID = reverse_rec.rowid_tmp;

            IF reverse_cur%ISOPEN
            THEN
                CLOSE reverse_cur;
            END IF;

            pv_errbuf     := vv_errbuf;
            pn_retcode    := 2;
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            ---------
            COMMIT;
            ---------
        WHEN OTHERS
        THEN
            ----------
            ROLLBACK;
            ----------

            UPDATE dka_spatravcours_tmp
            SET    request_id = gv_request_id,
                   last_update_date = SYSDATE,
                   last_updated_by = gv_last_updated_by,
                   last_update_login = gv_last_update_login,
                   message_erreur = 'Erreur inconnue ' || pv_errbuf
            WHERE  ROWID = reverse_rec.rowid_tmp;

            IF reverse_cur%ISOPEN
            THEN
                CLOSE reverse_cur;
            END IF;

            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            dka_tools_pkg.put_outdebug_message ('**** Erreur inconnue '|| SQLCODE || ' ' || SQLERRM);
            ---------
            COMMIT;
            ---------
    END REVERSE;


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
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_result     NUMBER;
        vv_errbuf     VARCHAR2 (500);
        vd_to_date    DATE; -- non utilisé
        vd_from_date    DATE; -- non utilisé
        vn_group_id   NUMBER;
        erreur        EXCEPTION;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE: Lancement de  INIT');
        dka_spatravcours_pkg.init (NULL, vd_to_date, vd_from_date, vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        -- on continue
        ELSIF vn_result = 2
        THEN
            RAISE erreur;
        END IF;

        dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE: Lancement de reverse');
        dka_spatravcours_pkg.REVERSE (vv_errbuf, vn_result, vn_group_id);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := 'Il y a des évènements rejetés';
        -- on continue
        ELSIF vn_result = 2
        THEN
            RAISE erreur;
        END IF;

        dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE : Lancement GL_OPEN_INTERFACE');
		-- NBO 14/02/2017 - artf2098706 - SPE052 : Logs du traitement DKA : Extourne des TEC et PCA : KO
        dka_spatravcours_pkg.gl_open_interface (vn_group_id, vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        -- on continue
        ELSIF vn_result = 2
        THEN
          RAISE erreur;
        END IF;

        dka_tools_pkg.put_outdebug_message ('');
        dka_tools_pkg.put_outdebug_message ('*****************************************************************************');
        dka_tools_pkg.put_outdebug_message ('');
        dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE : Lancement CREATE_OUTPUT');
        dka_spatravcours_pkg.create_output (vv_errbuf, vn_result);

        IF vn_result = 1
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
        -- on continue
        ELSIF vn_result = 2
        THEN
            RAISE erreur;
        END IF;
    EXCEPTION
        WHEN erreur
        THEN
            pn_retcode    := vn_result;
            pv_errbuf     := vv_errbuf;
            ROLLBACK;
			-- NBO 14/02/2017 - artf2098706 - SPE052 : Logs du traitement DKA : Extourne des TEC et PCA : KO
            dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE : Erreur : '|| vv_errbuf);
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            ROLLBACK;
            dka_tools_pkg.put_outdebug_message ('PROC_MAIN_REVERSE : Erreur non gérée '|| TO_CHAR (SQLCODE) || ' : ' || SQLERRM);
    END main_reverse;
    -- Fin Modif PHENIX 2004
END DKA_SPATRAVCOURS_PKG;
/
SHOW ERROR
EXIT;
