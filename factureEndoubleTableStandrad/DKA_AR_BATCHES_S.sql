CREATE OR REPLACE PACKAGE BODY dka_sapxcrrcr_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPXCRRCR_PKG.pks
-- DESCRIPTION       : DKA_SAPXCRRCR_PKG package spec :
---
--- AUTEUR           : X. Descamps
--- DATE DE CREATION : 20/05/2003
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 27/07/2004 STI Portage specifiques PHENIX 2004
---              changement de la requete du curseur/dissociation segment1 et 2
--- 19/08/2005 EBL Modification du curseur
--- 03/04/2007 TB  Spécialisation de l'édition par classe de règlements (TIERS, GROUPE, EMPLOYE)
--- 31/03/2008 QV  Changement du type des variables pd_pay_through_date pd_payment_date
--- 23/04/2009 MSL Changement de la regles pour la sélection des responsabilités de lancement
--- 25/09/2009 MSL Artf531736 - Problème sur le traitement "DKA : Echéancier provisoire tous Soc/CdG" rencontré sur la production 
--- 13/03/2017 NBO artf2112476 - ETA005 : Echéancier provisoire : L'automate lance les états pour toutes les UO avec le paraméte Modèle DRWTIERSVIR0028
--- 14/04/2017 YWA artf2121311 
--- 26/04/2017 NBO artf2123683 - ETA005 : Etat de synthèse
--- 30/05/2017 NBO artf2123683 - ETA005 : Etat de synthèse
--- 25/01/2018 MEG artf2328655 : ETA005 - Boucle sur les organisations incorrecte
--- 13/02/2018 MEG artf2365634 : ETA005 - Correction recherche utilisateur
--- 08/10/2018 MEN artf2416369 : EDB207 - Rajout de l'Unité d'Organisation et le Nom de la Société dans le Nom du programme
--- 25/01/2018 SFA artf3035091 : INC0250110 - ETA005 - Echéancier Provisoire fournisseur 
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
--                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf                   IN OUT   VARCHAR2,
        pn_retcode                  OUT      NUMBER,
        pv_pay_only_when_due_flag   IN       VARCHAR2,
        pd_pay_through_date         IN       VARCHAR2,--DATE, CSP Portabilite 2008
        pd_payment_date             IN       VARCHAR2,--DATE, CSP Portabilite 2008
        pv_include_unapp_inv_flag   IN       VARCHAR2,
        pv_type_tiers               IN       VARCHAR2 DEFAULT NULL,-- Ajout TB 03/04/07
        pv_include_unval_inv_flag   IN       VARCHAR2,  --Facture non validées
        pv_include_select_inv_flag  IN       VARCHAR2  --Facture sélectionnées        
    )
    IS
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vv_ap_responsibility   VARCHAR2(40);
        rec_param              dka_parameters%ROWTYPE;
        vn_request_id          fnd_concurrent_requests.request_id%TYPE;
        vv_phase               VARCHAR2 (100);
        vv_status              VARCHAR2 (100);
        vv_dev_phase           VARCHAR2 (100);
        vv_dev_status          VARCHAR2 (100);
        vv_classe_reg          VARCHAR2 (100);
        va_request_ids         pa_utils.idtabtyp; ---Tableau
        vn_requests_cnt        NUMBER (15);
        vv_errbuf              VARCHAR2 (150);        
        
        --vn_conc_request_id     fnd_concurrent_requests.request_id%TYPE;
        vn_user_id             fnd_user.user_id%TYPE;

        vv_printer             fnd_printer.printer_name%TYPE;
        
        vn_template_id         AP_PAYMENT_TEMPLATES.template_id%TYPE;


        --vd_pay_through_date    DATE := to_date(pd_pay_through_date, 'YYYY/MM/DD HH24:MI:SS'); -- CSP Portabilite 2008
        --vd_payment_date        DATE := to_date(pd_payment_date, 'YYYY/MM/DD HH24:MI:SS'); -- CSP Portabilite 2008  
          
        --vn_orgid               NUMBER (4);                            -- CSP Portabilite 2008
        --vn_sob                 gl_sets_of_books.set_of_books_id%TYPE; -- CSP Portabilite 2008
        
        -- Division de la ligne en cours de traitement
        --vv_division            VARCHAR2(150);
        -- Valeur pour la responsabilité
        vv_csp_ville           VARCHAR2(40);
        
        -- Début Ajout MSL - 25/09/2009 -  (++)  
        -- Varibale temporaire pour les valeurs des profils
        VC_PER_BUSINESS_GROUP_ID      VARCHAR2(240);
        VC_ORG_ID                     VARCHAR2(240);
        VC_GL_SET_OF_BKS_NAME         VARCHAR2(240);
        VC_GL_SET_OF_BKS_ID           VARCHAR2(240);
        -- Modifcation du profil ok
        vb_save_ok                    BOOLEAN;
        -- Fin Ajout MSL - 25/09/2009 -  (++)     

        --- 26/04/2017 NBO artf2123683 - ETA005 : Etat de synthèse        
        vn_trt_a_lancer                  NUMBER:=0;
        vn_trt_lances                    NUMBER:=0;
        vn_trt_normal                    NUMBER:=0;
        vn_trt_erreur                    NUMBER:=0;
        vn_trt_warning                   NUMBER:=0;     
         
        -- Curseur sur les couples Soc / CdG
        CURSOR cur IS
/*        select distinct hou.name, hou.organization_id ORG_ID, gl.short_name, gl.ledger_id 
				from hr_operating_units hou, gl_ledgers gl
				where gl.ledger_id = hou.set_of_books_id
        --and gl.short_name IN ('0028','0441') -- TEST JPE A ENLEVER AVANT LIVRAISON
				order by gl.short_name, hou.organization_id; */
		--- 08/10/2018  rajout du nom société		
        SELECT DISTINCT PSO.organization_name name, PSO.organization_id ORG_ID, gl.short_name, gl.ledger_id , gl.name society_name
          FROM PER_SECURITY_PROFILES_V PSP, PER_SECURITY_ORGANIZATIONS_V PSO, gl_ledgers gl, hr_operating_units hou
         WHERE 1 = 1
           AND hou.organization_id = PSO.organization_id
           AND gl.ledger_id = hou.set_of_books_id
           AND PSO.SECURITY_PROFILE_ID = PSP.SECURITY_PROFILE_ID
           AND PSP.SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
		   AND hou.set_of_books_id in (select set_of_books_id from FINANCIALS_SYSTEM_PARAMS_ALL)  ---SFA  --artf3035091 ajouté le 25/01/2019
         ORDER BY gl.short_name, PSO.organization_id;

    BEGIN

         
    /*CSP Portabilite 2008*/
    
        --vn_orgid                := fnd_profile.value('ORG_ID');
        --vn_sob                  := fnd_profile.value('GL_SET_OF_BKS_ID');
        
        -- IF vn_orgid IS NULL 
        -- THEN
            -- pn_retcode    := 2;
            -- pv_errbuf     := 'L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée';
            -- RETURN;
        -- END IF;
        
        -- IF vn_sob IS NULL
        -- THEN
            -- pn_retcode   := 2;
            -- pv_errbuf    := 'L''option de profil 1_Nom de l''entité comptable GL n''est pas paramétrée';
            -- RETURN;
        -- END IF;
    
    /*CSP Portabilite 2008*/
        
        pn_retcode              := 0;
        dka_tools_pkg.put_log_message ('pv_pay_only_when_due_flag : ' || pv_pay_only_when_due_flag);
        dka_tools_pkg.put_log_message ('pd_pay_through_date       : ' || pd_pay_through_date); -- CSP Portabilite 2008
        dka_tools_pkg.put_log_message ('pd_payment_date           : ' || pd_payment_date); -- CSP Portabilite 2008
        --dka_tools_pkg.put_log_message ('vd_pay_through_date       : ' || vd_pay_through_date); -- CSP Portabilite 2008
        --dka_tools_pkg.put_log_message ('vd_payment_date           : ' || vd_payment_date); -- CSP Portabilite 2008
        dka_tools_pkg.put_log_message ('pv_include_unapp_inv_flag : ' || pv_include_unapp_inv_flag);

        --récupération des parametres utilisés par le traitement
        -- Debut Modif MSLA 088 --  (--)
        /*--dka_tools_pkg.get_parameter ('SAPXCRRCR', 'AP_RESPONSIBILITY_KEY_' || vn_orgid , rec_param, pn_retcode, pv_errbuf);

        IF pn_retcode != 0
        THEN
            pn_retcode    := 1;
            RETURN;
        END IF;

        vv_ap_responsibility    := rec_param.varchar2_value;*/
        -- Fin Modif MSLA 088 --  (--)

        
        
        vn_requests_cnt         := 0;
        -- Debut Modif MSLA 088 --  (--)
        --vn_conc_request_id      := fnd_global.conc_request_id;
        --vn_conc_user_id         := fnd_global.user_id;
        -- Fin Modif MSLA 088 --  (--)
        
        --- 13/03/2017 NBO artf2112476 - ETA005 : Echéancier provisoire : L'automate lance les états pour toutes les UO avec le paraméte Modèle DRWTIERSVIR0028
        /*vv_ap_responsibility := 'CSP REGLEMENT'; --'CSP REGLEMENT';
        -- Début Ajout MSL - 25/09/2009 -  (++)  
        Dka_Tools_Pkg.put_log_message('responsibility_key  : ' || vv_ap_responsibility );
        ----- Récupération du contexte nécessaire au lancement de la boucle des traitements -----
        BEGIN
           SELECT fr.responsibility_id, fr.application_id
           INTO vn_responsibility_id, vn_application_id
           FROM fnd_responsibility fr
           WHERE fr.responsibility_key = vv_ap_responsibility;
         EXCEPTION
           WHEN OTHERS THEN
             pn_retcode := 2;
             pv_errbuf := 'Echec recherche responsabilité AP : ' || vv_ap_responsibility || ' ' || SQLERRM;
             Dka_Tools_Pkg.put_log_message(pv_errbuf);
             RETURN;
         END;*/
        
        FOR rec IN cur
        LOOP
            vn_trt_a_lancer := vn_trt_a_lancer + 1; -- NBO
            
            Dka_Tools_Pkg.put_log_message('rec.short_name ' || rec.short_name);
            
            BEGIN
              /*
              SELECT DISTINCT user_id
                into vn_user_id
                FROM fnd_flex_value_sets sets, fnd_flex_values_vl val, fnd_user fu
               WHERE sets.flex_value_set_id = val.flex_value_set_id
                 AND val.enabled_flag = 'Y'
                 AND val.compiled_value_attributes = 'Y' || chr(10) || 'Y'
                 AND val.summary_flag = 'N'
                 AND val.VALUE_CATEGORY = 'DAOPCCF_STE'
                 and val.FLEX_VALUE = rec.short_name
                 AND val.ATTRIBUTE2 = fu.USER_NAME;
              */  

               SELECT DISTINCT fu.user_id
                 INTO vn_user_id
                 FROM fnd_user fu, hr_operating_units hou
                WHERE sysdate BETWEEN nvl(fu.start_date, sysdate) AND nvl(fu.end_date, sysdate)
                  AND hou.organization_id = rec.org_id
                  AND substr(hou.name, 0, 3) = fu.user_name;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                Dka_Tools_Pkg.put_log_message('pas de user configuré.');
            END;
            
            --- 13/03/2017 NBO artf2112476 - ETA005 : Echéancier provisoire : L'automate lance les états pour toutes les UO avec le paraméte Modèle DRWTIERSVIR0028
            -- Vérification de l'existence du couple Division/Region
            BEGIN
              SELECT DISTINCT dsl.return_value
                INTO vv_csp_ville 
                FROM dka_stransco_lines dsl,
                     dka_stransco_headers dsh
               WHERE dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                 AND SYSDATE BETWEEN nvl(dsl.start_date, SYSDATE) 
                                     AND nvl(dsl.end_date, SYSDATE)
                 AND dsl.inactive_date IS NULL                   
                 AND dsl.param2_value = substr(rec.name,1,3);                            -- Région
              
            EXCEPTION 
            WHEN NO_DATA_FOUND 
            THEN
            -- Si le couple Division/Region n'existe pas dans la table de transcodification        
              vv_csp_ville := NULL;            
            END;     

          ----- Récupération du contexte nécessaire au lancement de la boucle des traitements -----
          BEGIN
             SELECT fr.responsibility_id, fr.application_id
             INTO vn_responsibility_id, vn_application_id
             FROM fnd_responsibility fr
             WHERE fr.responsibility_key = vv_csp_ville ||'_REGLEMENTS';
           EXCEPTION
             WHEN OTHERS THEN
               Dka_Tools_Pkg.put_log_message('Echec recherche responsabilité AP : ' || vv_csp_ville ||'_REGLEMENTS' || ' ' || SQLERRM);
               
               
                --récupération des parametres utilisés par le traitement
                --YWA artf2121311 
                dka_tools_pkg.get_parameter ('DKA_SAPXCRRCR', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, pv_errbuf);
                
                IF pn_retcode != 0
                THEN
                    pn_retcode    := 1;
                    RETURN;
                END IF;

                vv_ap_responsibility    := rec_param.varchar2_value;
                Dka_Tools_Pkg.put_log_message('recherche responsabilité AP_RESPONSIBILITY_KEY : ' || vv_ap_responsibility);
               BEGIN
                 SELECT fr.responsibility_id, fr.application_id
                   INTO vn_responsibility_id, vn_application_id
                   FROM fnd_responsibility fr
                  WHERE fr.responsibility_key = vv_ap_responsibility;-- YWA artf2121311 
               
               EXCEPTION
                 WHEN OTHERS THEN
                   pn_retcode := 2;
                   pv_errbuf := 'Echec recherche responsabilité '||vv_ap_responsibility;--YWA artf2121311  
                   Dka_Tools_Pkg.put_log_message(pv_errbuf);
               --RETURN;
			   CONTINUE;
           END;
             
           END;
             
            Dka_Tools_Pkg.put_log_message('User id: ' || vn_user_id);
            Dka_Tools_Pkg.put_log_message('Resp Id: ' || vn_responsibility_id);
            Dka_Tools_Pkg.put_log_message('App Id: '  || vn_application_id);
            fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
            mo_global.init('SQLAP');
        
            -- Debut Modif MSLA 088 --  (++)
            --vv_csp_ville := NULL;
          
            -- Récupération de la division pour la ligne en cours
            /*BEGIN
              SELECT DISTINCT hou.attribute10
                INTO vv_division
                FROM hr_all_organization_units hou
               WHERE hou.attribute10 IS NOT NULL
                 AND hou.business_group_id = rec.business_group_id;
              
            EXCEPTION 
            WHEN NO_DATA_FOUND 
            THEN
              vv_division :=NULL;                   
            END; 
            
            -- Vérification de l'existence du couple Division/Region
            BEGIN
              SELECT dsl.return_value
                INTO vv_csp_ville 
                FROM dka_stransco_lines dsl,
                     dka_stransco_headers dsh
               WHERE dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                 AND SYSDATE BETWEEN nvl(dsl.start_date, SYSDATE) 
                                     AND nvl(dsl.end_date, SYSDATE)
                 AND dsl.inactive_date IS NULL                   
                 AND dsl.param1_value = vv_division                               -- Division
                 AND dsl.param2_value = rec.acct_area;                            -- Région
              
            EXCEPTION 
            WHEN NO_DATA_FOUND 
            THEN
            -- Si le couple Division/Region n'existe pas dans la table de transcodification        
              vv_ap_responsibility := 'TOUT_AP_ADMINISTRATEUR';            
            END;  */          
            
            -- Si le couple Division/Region existe dans la table de transcodification                      
            /*IF vv_csp_ville IS NOT NULL
            THEN 
             
              -- On sauvegarde les valeurs du profil de lancement
              fnd_profile.GET(NAME => 'PER_BUSINESS_GROUP_ID',
                              VAL => VC_PER_BUSINESS_GROUP_ID);
              fnd_profile.GET(NAME => 'ORG_ID',
                              VAL => VC_ORG_ID);
              fnd_profile.GET(NAME => 'GL_SET_OF_BKS_NAME',
                              VAL => VC_GL_SET_OF_BKS_NAME);
              fnd_profile.GET(NAME => 'GL_SET_OF_BKS_ID',
                              VAL => VC_GL_SET_OF_BKS_ID);                   
              
             -- On met les valeurs du profil de lancement du traitement, dans celle du profil de lancement des sous traitements
             vb_save_ok := fnd_profile.SAVE(X_NAME => 'PER_BUSINESS_GROUP_ID',
                                            X_VALUE => VC_PER_BUSINESS_GROUP_ID,
                                            X_LEVEL_NAME => 'RESP',
                                            X_LEVEL_VALUE => vn_responsibility_id,
                                            X_LEVEL_VALUE_APP_ID => vn_application_id);
    
             vb_save_ok := fnd_profile.SAVE(X_NAME => 'ORG_ID',
                                            X_VALUE => VC_ORG_ID,
                                            X_LEVEL_NAME => 'RESP',
                                            X_LEVEL_VALUE => vn_responsibility_id,
                                            X_LEVEL_VALUE_APP_ID => vn_application_id);
                              
             vb_save_ok := fnd_profile.SAVE(X_NAME => 'GL_SET_OF_BKS_NAME',
                                            X_VALUE => VC_GL_SET_OF_BKS_NAME,
                                            X_LEVEL_NAME => 'RESP',
                                            X_LEVEL_VALUE => vn_responsibility_id,
                                            X_LEVEL_VALUE_APP_ID => vn_application_id);
                              
             vb_save_ok := fnd_profile.SAVE(X_NAME => 'GL_SET_OF_BKS_ID',
                                            X_VALUE => VC_GL_SET_OF_BKS_ID,
                                            X_LEVEL_NAME => 'RESP',
                                            X_LEVEL_VALUE => vn_responsibility_id,
                                            X_LEVEL_VALUE_APP_ID => vn_application_id);                                                    

             COMMIT;                            
             -- Fin Ajout MSL - 25/09/2009 -  (++)               
              
            --END IF;
            -- Fin Modif MSLA 088 --  (++)        
            
            -- Récupération des variables nécessaires au lancement du traitement
            /*BEGIN
              SELECT fr.responsibility_id,
                     fr.application_id
                INTO vn_responsibility_id,
                     vn_application_id
                FROM fnd_responsibility fr
              -- WHERE  fr.responsibility_key = REPLACE (vv_ap_responsibility, 'XXXX', rec.societe);
               WHERE  fr.responsibility_key = vv_ap_responsibility;-- PHENIX 2004
            
            -- Debut Modif MSLA 088 --  (++)
            EXCEPTION 
              WHEN NO_DATA_FOUND 
              THEN
                -- Si la responsabilité n'existe pas dans fnd_responsibility, on utilise celle par défaut
                vv_ap_responsibility := 'TOUT_AP_ADMINISTRATEUR';
                -- Ce select retournera un résultat car il s'agit de la responsabilité par défaut
                SELECT fr.responsibility_id,
                       fr.application_id
                  INTO vn_responsibility_id,
                       vn_application_id
                  FROM fnd_responsibility fr
                 WHERE fr.responsibility_key = vv_ap_responsibility;                
            END;            
            -- Fin Modif MSLA 088 --  (++)           
            
              -- Définition de la classe de règlement à traiter
              IF pv_type_tiers IS NOT NULL THEN
                vv_classe_reg := rec.societe || rec.acct_area || pv_type_tiers;
              END IF;
            
              -- Initialisation de l'environement OA pour correspondre a la societe en cours de traitement
              fnd_global.apps_initialize (rec.user_id, vn_responsibility_id, vn_application_id);  */

              -- Choix de l'imprimante
              vv_printer   := fnd_profile.value ('PRINTER');
			  
    			    -- Choix de la langue
    			    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
			  
			        IF NOT fnd_request.set_print_options (printer => vv_printer, copies  => 0) THEN
                  pn_retcode    := 1;
                  pv_errbuf     := 'L''imprimante n''a pas été trouvée pour le Centre de Gestion ' || rec.name;
              ELSE
                  Fnd_Request.set_org_id(org_id => rec.org_id);                        
                  Dka_Tools_Pkg.put_log_message('rec.org_id: ' || rec.org_id);
                  
                  --Modèle 'DRWGPEVIR0028'
                  SELECT TEMPLATE_ID
                  INTO vn_template_id
                    FROM AP_PAYMENT_TEMPLATES
                  --WHERE template_name = 'DRWTIERSVIR0028';
                  --- 13/03/2017 NBO artf2112476 - ETA005 : Echéancier provisoire : L'automate lance les états pour toutes les UO avec le paraméte Modèle DRWTIERSVIR0028
                  WHERE template_name = 'ECHEANCIER' || pv_type_tiers ;
                  
                  -- Lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
                  vn_request_id         := fnd_request.submit_request (
                                               'DKA', --APPLICATION
                                               'DKA_APXCRRCR', --PROGRAM
                                               --NULL, --PROGRAM_NAME  --- 08/10/2018  rajout du UO et le Nom Société
                                               rec.name ||' - '||rec.society_name, --PROGRAM_NAME
											   NULL, --START_TIME
                                               FALSE, --SUB_REQUEST
                                               pv_pay_only_when_due_flag,                 --Payable à échéance uniquement 
                                               pd_pay_through_date,                       --Date de sélection règlements -- CSP Portabilite 2008
                                               pd_payment_date,                           --Date de règlement   -- CSP Portabilite 2008
                                               pv_include_unval_inv_flag,                 --Facture non validées
                                               pv_include_unapp_inv_flag,                 --Facture non approuvées
                                               pv_type_tiers,                             --Classe de règlement
                                               'N',                                       --Option de synthèse
                                               NULL,                                      --Mode de règlement
                                               vn_template_id,                            --Modèle 'DRWGPEVIR0028'
                                               NULL,                                      --Devise
                                               NULL,                                      --Priorité haute
                                               NULL,                                      --Priorité basse
                                               pv_include_select_inv_flag                 --Facture sélectionnées                                                 
                                           );

                  Dka_Tools_Pkg.put_log_message('vn_request_id: ' || vn_request_id);
                  IF vn_request_id IS NULL
                  THEN
                      pn_retcode    := 1;
                      pv_errbuf     := 'Le traitement d''approbation n''a pas pu être lancé pour la société  ' || rec.name;
                  ELSE
                      pn_retcode                          := 0;
                      pv_errbuf                           := 'Traitement d''approbation : ' || TO_CHAR (vn_request_id) || ' lancé sur la société ' || rec.name;
                      dka_tools_pkg.put_outdebug_message (pv_errbuf);
                      vn_requests_cnt                     := vn_requests_cnt + 1;
                      va_request_ids (vn_requests_cnt)    := vn_request_id;
                      --- 26/04/2017 NBO artf2123683 - ETA005 : Etat de synthèse
                      vn_trt_lances := vn_trt_lances + 1;
                  END IF;
              END IF;
              COMMIT;
        END LOOP;

        WHILE vn_requests_cnt > 0
        LOOP
            IF NOT (fnd_concurrent.wait_for_request (
                        va_request_ids (vn_requests_cnt),
                        15,
                        0,
                        vv_phase,
                        vv_status,
                        vv_dev_phase,
                        vv_dev_status,
                        vv_errbuf
                    )
                   )
            THEN
                dka_tools_pkg.put_outdebug_message (
                    'Traitement numéro '|| TO_CHAR (va_request_ids (vn_requests_cnt)) || ' trop long ou tombé en erreur'
                );
                --- 30/05/2017 NBO artf2123683 - ETA005 : Etat de synthèse
                vn_trt_erreur := vn_trt_erreur + 1;
            ELSIF (    vv_dev_phase = 'COMPLETE'
                   AND vv_dev_status = 'NORMAL'
                  )
            THEN
                dka_tools_pkg.put_outdebug_message (
                    'Traitement numéro '|| TO_CHAR (va_request_ids (vn_requests_cnt)) || ' correctement exécuté'
                );
                --- 26/04/2017 NBO artf2123683 - ETA005 : Etat de synthèse
                vn_trt_normal := vn_trt_normal + 1;
            ELSIF vv_dev_status = 'WARNING' THEN
              dka_tools_pkg.put_outdebug_message (CHR (10) || '>>> Traitement '||TO_CHAR (va_request_ids (vn_requests_cnt))||' termine en Warning ');
              vn_trt_warning := vn_trt_warning + 1;
            ELSIF vv_dev_status != 'NORMAL' THEN
              dka_tools_pkg.put_outdebug_message (CHR (10) || '>>> Traitement '||TO_CHAR (va_request_ids (vn_requests_cnt))||' termine en Erreur ');
              vn_trt_erreur := vn_trt_erreur + 1;
            END IF;

            vn_requests_cnt    := vn_requests_cnt - 1;
        END LOOP;

        --- 26/04/2017 NBO artf2123683 - ETA005 : Etat de synthèse
        dka_tools_pkg.put_outdebug_message (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_outdebug_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_outdebug_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_outdebug_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_outdebug_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        
        --- 30/05/2017 NBO artf2123683 - ETA005 : Etat de synthèse
        IF vn_trt_erreur > 0 THEN
          pn_retcode := 2;
        ELSIF vn_trt_warning > 0 THEN
          pn_retcode := 1;
        END IF;

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM (SQLCODE);
            pn_retcode    := 2;
    END main;
--------------------------------------------------------------------------------------------------------------
END dka_sapxcrrcr_pkg;
/
SHOW ERROR
EXIT;
