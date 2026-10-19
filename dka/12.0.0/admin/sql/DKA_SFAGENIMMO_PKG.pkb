CREATE OR REPLACE PACKAGE BODY APPS.DKA_SFAGENIMMO_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SFAGENIMMO_PKG.pkb 271 2018-07-13 10:13:20 $
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFAGENIMMO_PKG.pkb
-- DESCRIPTION       : DKA_SFAGENIMMO_PKG package body :
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 13/07/2018
--- DOC. ASSOCIEE    : SPE214
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 11/04/2025 ARA EDB425 - Evolution WF Générateur de compte FA - Ajout d une nouvelle destination SOP
--------------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_MASS_EXPENSE_CCID
--  Description   : Fonction de calcul de la cle de dotation
--
--  PARAMETRES    :
--  pv_errbuf                           Entrée/Sortie    retour de message eventuel
--  pn_retcode                          Sortie           status du traitement en sortie
--  pv_book_type_code                   Entrée           Livre FA
--  pn_category_id                      Entrée           Id categorie
--  pn_project_id                       Entrée           Id projet
--  pn_task_id                          Entrée           Id Tache projet
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------

FUNCTION GET_MASS_EXPENSE_CCID (
        pv_errbuf           IN OUT   VARCHAR2,
        pn_retcode          OUT      NUMBER,
        pv_book_type_code   IN       VARCHAR2,
        pn_category_id      IN       NUMBER,
        pn_project_id       IN       NUMBER,
        pn_task_id          IN       NUMBER) 
RETURN NUMBER
IS
    v_segment1              VARCHAR2(150):= NULL;
    v_segment2              VARCHAR2(150):= NULL;
    v_segment3              VARCHAR2(150):= NULL;
    v_segment4              VARCHAR2(150):= NULL;
    v_segment5              VARCHAR2(150):= NULL;
    v_segment6              VARCHAR2(150):= NULL;
    v_segment7              VARCHAR2(150):= NULL;
    v_segment8              VARCHAR2(150):= NULL;

    vv_destination          VARCHAR2(150);
    vn_project_id_parent    NUMBER;
    vv_code_projet_parent   pa_projects_all.segment1%TYPE;
    
    vv_mesg                 VARCHAR2(500);
    vv_errbuf               VARCHAR2(500);
    vn_retcode              NUMBER;
    
    vn_ccid                 NUMBER;
BEGIN
        -- Segment1 - societe , segment3 - compte local et segment5 - interco
        BEGIN
            SELECT gcc.segment1 ,gcc.segment3,gcc.segment5
            INTO v_segment1,v_segment3,v_segment5
            FROM fa_category_books fcb, 
                 gl_code_combinations_kfv gcc
            WHERE fcb.category_id  = pn_category_id
            AND fcb.book_type_code = pv_book_type_code
            AND fcb.deprn_expense_account_ccid = gcc.code_combination_id;
        EXCEPTION
        WHEN OTHERS THEN
            v_segment1  := NULL;
            v_segment3  := NULL;
            v_segment5  := NULL;
        END;
           
        -- Segment2 - Region
        v_segment2 := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(pn_project_id);

        -- Segment4,5,6,7
        BEGIN
            
            SELECT pp.project_id, pp.segment1
            INTO vn_project_id_parent, vv_code_projet_parent
            from pa_tasks pt, pa_projects_all pp
            where TO_CHAR(pt.task_id) IN
             (select attribute7 from pa.pa_tasks where task_id = pn_task_id)
            and pt.PROJECT_ID = pp.project_id;

            vv_destination := dka_pa_tools_pkg.get_class_project(fn_project_id     => vn_project_id_parent,
                                                                 fv_class_category => 'DESTINATION');
            -- Segment4 - Compte analytique
            BEGIN
                SELECT CASE vv_destination
                           WHEN 'CDV' THEN
                            fc.attribute1
                           WHEN 'COM' THEN
                            fc.attribute2
                           WHEN 'SGA' THEN
                            fc.attribute3
                           WHEN 'SOP' THEN --ARA EDB425
                            fc.attribute8
                         END
                INTO v_segment4
                FROM fa_categories fc
                WHERE fc.category_id = pn_category_id;
            EXCEPTION
            WHEN OTHERS THEN
                v_segment4 := NULL;
            END;
            
            -- Segment6 - Centre finance
            v_segment6 := dka_pa_tools_pkg.get_centre_finance(vn_project_id_parent, SYSDATE);
            
            -- Segment7 - Code affaire
            v_segment7 := dka_pa_tools_pkg.get_class_project(fn_project_id     => vn_project_id_parent,
                                                                  fv_class_category => 'AFFAIRE');
            
            -- Segment8 - Code projet finance
            v_segment8 := vv_code_projet_parent;
            
        EXCEPTION
        WHEN OTHERS THEN
            v_segment4 := NULL;
            v_segment6 := NULL;
            v_segment7 := NULL;
            v_segment8 := NULL;
            dka_Tools_Pkg.put_log_message('error  ' || SUBSTR (SQLERRM, 1, 400));
        END;
        

        Dka_Tools_Pkg.get_code_combination_id(  pv_segment1              => v_segment1,
                                                pv_segment2              => v_segment2,
                                                pv_segment3              => v_segment3,
                                                pv_segment4              => v_segment4,
                                                pv_segment5              => v_segment5,
                                                pv_segment6              => v_segment6,
                                                pv_segment7              => v_segment7,
                                                pv_segment8              => v_segment8,
                                                pv_segment9              => '0',
                                                pv_segment10             => '0',
                                                pv_segment11             => '0',
                                                pv_segment12             => '0',
                                                pn_code_combination_id   => vn_ccid,
                                                pv_errbuf                => vv_errbuf,              
                                                pn_retcode               => vn_retcode);
        IF vn_retcode != 0 THEN
            pv_errbuf     := vv_errbuf;
            pn_retcode    := vn_retcode;
        END IF;
        
        RETURN vn_ccid;
        
        EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SUBSTR (SQLERRM, 1, 400);
            pn_retcode    := 2;
    END;
    
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
             
-------------------------------------------------------------------------------------------------------------------
--  Nom           : transfer_immo
--  Description   : Procédure pour lancer "PRC : Transférer des immobilisations vers Oracle Assets"
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_org_id                       Entrée                  Id de l unite operationnelle
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE transfer_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    )
    IS
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vn_traitement          NUMBER         := 0;

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_org_name                      hr_operating_units.name%type;
    BEGIN

        /*
        dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_PA_ADMINISTRATEUR'; -- A verifier
       
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
        */
        
        dka_Tools_Pkg.put_log_message('Recuperation Org_name');
        SELECT name
        INTO   vv_org_name
        FROM   hr_operating_units
        WHERE  organization_id = pn_org_id;
        
        --  Traitement multi-org    
        FND_REQUEST.SET_ORG_ID(pn_org_id);

        dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || vv_org_name);
        ---
        vn_request_id    := fnd_request.submit_request (
                                'PA',       --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                'PAXCPCAL', --SHORT_NAME du TRAITEMENT
                                NULL,       --PROGRAM_NAME
                                NULL,       --START
                                FALSE,      --SUB_REQUEST
                                'FC000000A',
                                'FC999999Z',
                                NULL,
                                'N'
                                )
                                ;
            
        dka_Tools_Pkg.put_log_message('Validation pour que les GTS puissent prendre la demande');

        IF NVL(vn_request_id,0) = 0
        THEN
            dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement pour '||vv_org_name);
            pn_retcode    := 2;
        ELSE
            COMMIT;
            dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
        END IF;

        IF NOT Fnd_Concurrent.wait_for_request (vn_request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
           dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine normalement');
              pv_errbuf     := vv_message;
              pn_retcode    := 0;
           ELSIF vv_dstatus = 'WARNING' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning ');
              pv_errbuf     := vv_message;
              pn_retcode    := 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Erreur ');
              pv_errbuf     := vv_message;
              pn_retcode    := 2;
           END IF;
        END IF;
        
        EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_message || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
    END;

    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : auto_acquis
--  Description   : Procédure "Automatisation des acquisitions en HV"
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_org_id                       Entrée                  Id de l unite operationnelle
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE auto_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    )
    IS
    
    CURSOR cur_immo (pv_org_name VARCHAR2)IS
    SELECT *
    FROM FA_MASS_ADDITIONS MA
    WHERE 1=1
    AND MA.POSTING_STATUS = 'NEW'
    AND SUBSTR(MA.BOOK_TYPE_CODE,1,4) = SUBSTR(pv_org_name,4,7) 
    AND DKA_SPAAUTOACCOUNTING_PKG.uo_projet(MA.project_id) = SUBSTR(pv_org_name,1,3) 
    --AND MA.QUEUE_NAME = 'NEW'
    ORDER BY MA.MASS_ADDITION_ID
    ;
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vv_user                VARCHAR2(50);
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vv_errbuf              VARCHAR2(500);
    vn_retcode             NUMBER;
    vv_program_code        VARCHAR2(100):= 'FNDRSSUB46';
    vv_application         VARCHAR2(100):= 'OFA';

    e_error                EXCEPTION;
    vn_appl_resp_id        fnd_application.application_id%TYPE;
    vv_appl_resp_name      fnd_application.application_short_name%TYPE;
    vn_req_set_id          fnd_request_sets.request_set_id%TYPE;
    vb_save_output         BOOLEAN;   
    
    vv_org_name            hr_operating_units.name%type;
    v_valid                BOOLEAN:=FALSE;
    V_EXPENSE_CCID         NUMBER;
    V_ASSET_KEY_CCID       fa_asset_keywords_kfv.code_combination_id%TYPE;
    v_location_id          FA_MASS_ADDITIONS.LOCATION_ID%TYPE;
    v_ccid_gement2         VARCHAR2(10);
    v_count                NUMBER := 0;
    v_maj_count            NUMBER := 0;
    v_ko_count             NUMBER := 0;
    
    BEGIN

        dka_Tools_Pkg.put_log_message('Recuperation du nom de l''unité operationnelle');
        SELECT name
        INTO   vv_org_name
        FROM   hr_operating_units
        WHERE  organization_id = pn_org_id;
        dka_Tools_Pkg.put_log_message('Unité operationnelle : ' ||vv_org_name );

        fnd_file.put_line(fnd_file.output, '+-------------------------------------------------------------------------+' || chr(10));
        fnd_file.put_line(fnd_file.output,
                      'Nom du traitement  : ' || 'DKA - FA : Automatisation des acquisitions en HV');
        fnd_file.put_line(fnd_file.output,
                      'Programme lancé le : ' ||
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(10));
        fnd_file.put_line(fnd_file.output, '+-------------------------------------------------------------------------+' || chr(10) || chr(10));
    
        fnd_file.put_line(fnd_file.output, 'PARAMETRES ');
        fnd_file.put_line(fnd_file.output, '--------------');
        fnd_file.put_line(fnd_file.output, 'Unité Opérationnelle : '||vv_org_name);
        fnd_file.put_line(fnd_file.output, '');
        
        fnd_file.put_line(fnd_file.output, 'Bilan :');
        fnd_file.put_line(fnd_file.output, '-------');
        FOR cur_immo_rec IN cur_immo (vv_org_name) LOOP
            v_valid := TRUE;
            v_count := v_count + 1;
            --Même si la clé de dotation aux amortissements a été saisie dans PA, il faut impérativement la recalculer
            --afin de générer la bonne clé de dotation avec tous les segments correctement alimentés.
            V_EXPENSE_CCID := GET_MASS_EXPENSE_CCID (
                                                    pv_errbuf,
                                                    pn_retcode,
                                                    cur_immo_rec.BOOK_TYPE_CODE,
                                                    cur_immo_rec.ASSET_CATEGORY_ID,
                                                    cur_immo_rec.project_id,
                                                    cur_immo_rec.task_id) ;
            
            IF V_EXPENSE_CCID IS NULL THEN
                v_valid := FALSE;
                vv_mesg := vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description || ' : Import impossible dans FA car la clé de dotation n''a pas été calculée';
                dka_Tools_Pkg.put_log_message(vv_mesg);
            ELSE            
                --Si le lieu n’est pas alimenté dans PA alors générer un avertissement en indiquant l’UO, numéro d’immo + le message suivant « Import impossible dans FA car le LIEU est manquant » 
                V_ASSET_KEY_CCID := NULL;
                IF cur_immo_rec.ASSET_KEY_CCID IS NULL THEN
                    BEGIN 
                        SELECT code_combination_id 
                        INTO V_ASSET_KEY_CCID
                        FROM fa_asset_keywords
                        WHERE segment1='NON'
                        AND segment2 = 'NON';
                    EXCEPTION
                    WHEN OTHERS THEN
                        V_ASSET_KEY_CCID := NULL;
                    END;
                ELSE
                    V_ASSET_KEY_CCID := cur_immo_rec.ASSET_KEY_CCID;
                END IF;
                
                IF V_ASSET_KEY_CCID IS NULL THEN
                    v_valid := FALSE;
                    vv_mesg := vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description || ' : Import impossible dans FA car la clé immobilisation est manquante';
                    dka_Tools_Pkg.put_log_message(vv_mesg);
                END IF;

                v_location_id := NULL;
                IF cur_immo_rec.LOCATION_ID IS NULL THEN
                    BEGIN 
                        /*
                        SELECT LOCATION_ID 
                        INTO v_location_id
                        FROM PA_PROJECT_ASSETS_ALL ppa
                        WHERE ppa.project_id = cur_immo_rec.project_id 
                        AND   ppa.asset_name = cur_immo_rec.ASSET_NUMBER
                        ;*/
                        SELECT LOCATION_ID 
                        INTO v_location_id
                        from FA_MASSADD_DISTRIBUTIONS
                        WHERE MASS_ADDITION_ID = cur_immo_rec.MASS_ADDITION_ID
                        AND ROWNUM = 1
                        ;
                    EXCEPTION
                    WHEN OTHERS THEN
                        v_location_id := NULL;
                    END;
                ELSE
                    v_location_id := cur_immo_rec.LOCATION_ID;
                END IF;
                
                IF v_location_id IS NULL THEN 
                    v_valid := FALSE;
                    vv_mesg := vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description || ' : Import impossible dans FA car le LIEU est manquant';
                    dka_Tools_Pkg.put_log_message(vv_mesg);
                END IF;

                IF v_valid THEN --AND v_ccid_gement2 = SUBSTR(vv_org_name,1,3) AND SUBSTR(vv_org_name,4,7)  = SUBSTR(cur_immo_rec.BOOK_TYPE_CODE,1,4) THEN
                    
                    dka_Tools_Pkg.put_log_message('Mise à jour de l''immobilisation ' || vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description );
                    UPDATE FA_MASS_ADDITIONS
                    SET LOCATION_ID    = v_location_id,
                        ASSET_KEY_CCID = V_ASSET_KEY_CCID,
                        EXPENSE_CODE_COMBINATION_ID = V_EXPENSE_CCID,
                        QUEUE_NAME     = 'POST',
                        POSTING_STATUS = 'POST',
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATED_BY  = vn_user_id
                    WHERE MASS_ADDITION_ID = cur_immo_rec.MASS_ADDITION_ID
                    ;
                    fnd_file.put_line(fnd_file.output, 'Immobilisation ['|| vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description ||'] --> ' || 'Mise à jour OK');
                    v_maj_count := v_maj_count + 1;
                ELSE
                    fnd_file.put_line(fnd_file.output, 'Immobilisation ['|| vv_org_name ||' - '|| cur_immo_rec.ASSET_NUMBER ||' - '|| cur_immo_rec.description ||'] --> ' || 'Erreur KO');
                    v_ko_count := v_ko_count + 1;
                END IF;
            
            END IF;

        END LOOP;
        
        COMMIT;
        
        IF v_ko_count > 0 THEN
            pn_retcode    := 1;
            fnd_file.put_line(fnd_file.output, 'Avertissement : il y a des cas en erreur !');
        END IF;
        
        fnd_file.put_line(fnd_file.output, '');
        fnd_file.put_line(fnd_file.output, 'Nombre d''enregistrements trouvés       :  ' || TO_CHAR(v_count));
        fnd_file.put_line(fnd_file.output, 'Nombre d''enregistrements mis à jour OK :  ' || TO_CHAR(v_maj_count));
        fnd_file.put_line(fnd_file.output, 'Nombre d''enregistrements KO            :  ' || TO_CHAR(v_ko_count));
        
        dka_Tools_Pkg.put_log_message('');
        dka_Tools_Pkg.put_log_message('Nombre d''enregistrements trouvés       :  ' || TO_CHAR(v_count));
        dka_Tools_Pkg.put_log_message('Nombre d''enregistrements mis à jour OK :  ' || TO_CHAR(v_maj_count));
        dka_Tools_Pkg.put_log_message('Nombre d''enregistrements KO            :  ' || TO_CHAR(v_ko_count));
        
        EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
    END;
    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : imput_acquis
--  Description   : Procédure pour lancer JT "Imputer des acquisitions en haut volume "
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_org_id                       Entrée                  Id de l unite operationnelle
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE imput_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    )
    IS
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vv_user                VARCHAR2(50);
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vv_errbuf              VARCHAR2(500);
    vn_retcode             NUMBER;
    vv_program_code        VARCHAR2(100):= 'FNDRSSUB46';
    vv_application         VARCHAR2(100):= 'OFA';

    e_error                EXCEPTION;
    vn_appl_resp_id        fnd_application.application_id%TYPE;
    vv_appl_resp_name      fnd_application.application_short_name%TYPE;
    vn_req_set_id          fnd_request_sets.request_set_id%TYPE;
    vb_save_output         BOOLEAN;

    CURSOR cur_programs (
        pn_req_set_id   NUMBER
    )
    IS
        SELECT v.*,
               frss.stage_name
        FROM   fnd_req_set_run_form_v v,
               fnd_request_set_stages frss
        WHERE      frss.request_set_id = v.request_set_id
               AND frss.display_sequence = v.display_sequence
               AND v.request_set_id = pn_req_set_id;

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    
    vv_livre_social                  VARCHAR2(80);
    vv_org_name                      hr_operating_units.name%TYPE;
    BEGIN

        dka_Tools_Pkg.put_log_message('Recuperation Org_name');
        SELECT name
        INTO   vv_org_name
        FROM   hr_operating_units
        WHERE  organization_id = pn_org_id;
        
        vv_livre_social := SUBSTR(vv_org_name,4,7)||' SOCIAL';
        
        -- Positionnement de l'environnement
        SELECT fr.responsibility_id,
               fr.application_id  ,
               fa.application_short_name
        INTO   vn_responsibility_id,
               vn_appl_resp_id,
               vv_appl_resp_name
        FROM   fnd_responsibility fr ,
               fnd_application fa
        WHERE  fr.responsibility_key = SUBSTR(vv_org_name,4,7)||'_FA_SAISIE'
        AND    fr.application_id = fa.application_id;

        SELECT frs.request_set_id
        INTO   vn_req_set_id
        FROM   fnd_request_sets frs
        WHERE  frs.request_set_name = vv_program_code;

        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_appl_resp_id);
            
        -- Initialisation
        IF NOT Fnd_Submit.set_request_set (vv_application, vv_program_code)
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_submit.set_request_set" le jeu de traitements '|| vv_program_code);
            pn_retcode    := 2;
        END IF;

        FOR rec_prog IN cur_programs (vn_req_set_id)
        LOOP
            --Recuperation des parametres
            DKA_TOOLS_PKG.get_request_set_params (
                pv_errbuf,
                pn_retcode,
                rec_prog.set_application_id,
                vn_req_set_id,
                rec_prog.request_set_program_id,
                rec_prog.program_application_id,
                rec_prog.concurrent_program_id
            );

            -- Parametres d'impression
            IF rec_prog.printer IS NOT NULL
            THEN
                IF rec_prog.save_output_flag = 'Y'
                THEN
                    vb_save_output    := TRUE;
                ELSE
                    vb_save_output    := FALSE;
                END IF;

                IF NOT Fnd_Submit.set_print_options (
                           printer                        => rec_prog.printer,
                           style                          => rec_prog.print_style,
                           copies                         => rec_prog.number_of_copies,
                           save_output                    => vb_save_output
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                        'Impossible de "fnd_submit.set_print_options" le traitement '|| rec_prog.concurrent_program_name
                    );
                END IF;
                pn_retcode    := 2;
                continue;
            END IF;
        
            Dka_Tools_Pkg.tab_request_params (1) := vv_livre_social;
            
            -- Lancement programmes
            IF NOT Fnd_Submit.submit_program (
                   rec_prog.application_short_name, -- Application
                   rec_prog.concurrent_program_name, -- Program
                   rec_prog.stage_name, -- Stage
                   Dka_Tools_Pkg.tab_request_params (1), --ARGUMENT1
                   Dka_Tools_Pkg.tab_request_params (2), --ARGUMENT2
                   Dka_Tools_Pkg.tab_request_params (3), --ARGUMENT3
                   Dka_Tools_Pkg.tab_request_params (4), --ARGUMENT4
                   Dka_Tools_Pkg.tab_request_params (5), --ARGUMENT5
                   Dka_Tools_Pkg.tab_request_params (6), --ARGUMENT6
                   Dka_Tools_Pkg.tab_request_params (7), --ARGUMENT7
                   Dka_Tools_Pkg.tab_request_params (8), --ARGUMENT8
                   Dka_Tools_Pkg.tab_request_params (9), --ARGUMENT9
                   Dka_Tools_Pkg.tab_request_params (10), --ARGUMENT10
                   Dka_Tools_Pkg.tab_request_params (11), --ARGUMENT11
                   Dka_Tools_Pkg.tab_request_params (12), --ARGUMENT12
                   Dka_Tools_Pkg.tab_request_params (13), --ARGUMENT13
                   Dka_Tools_Pkg.tab_request_params (14), --ARGUMENT14
                   Dka_Tools_Pkg.tab_request_params (15), --ARGUMENT15
                   Dka_Tools_Pkg.tab_request_params (16), --ARGUMENT16
                   Dka_Tools_Pkg.tab_request_params (17), --ARGUMENT17
                   Dka_Tools_Pkg.tab_request_params (18), --ARGUMENT18
                   Dka_Tools_Pkg.tab_request_params (19), --ARGUMENT19
                   Dka_Tools_Pkg.tab_request_params (20), --ARGUMENT20
                   Dka_Tools_Pkg.tab_request_params (21), --ARGUMENT21
                   Dka_Tools_Pkg.tab_request_params (22), --ARGUMENT22
                   Dka_Tools_Pkg.tab_request_params (23), --ARGUMENT23
                   Dka_Tools_Pkg.tab_request_params (24), --ARGUMENT24
                   Dka_Tools_Pkg.tab_request_params (25), --ARGUMENT25
                   Dka_Tools_Pkg.tab_request_params (26), --ARGUMENT26
                   Dka_Tools_Pkg.tab_request_params (27), --ARGUMENT27
                   Dka_Tools_Pkg.tab_request_params (28), --ARGUMENT28
                   Dka_Tools_Pkg.tab_request_params (29), --ARGUMENT29
                   Dka_Tools_Pkg.tab_request_params (30), --ARGUMENT30
                   Dka_Tools_Pkg.tab_request_params (31), --ARGUMENT31
                   Dka_Tools_Pkg.tab_request_params (32), --ARGUMENT32
                   Dka_Tools_Pkg.tab_request_params (33), --ARGUMENT33
                   Dka_Tools_Pkg.tab_request_params (34), --ARGUMENT34
                   Dka_Tools_Pkg.tab_request_params (35), --ARGUMENT35
                   Dka_Tools_Pkg.tab_request_params (36), --ARGUMENT36
                   Dka_Tools_Pkg.tab_request_params (37), --ARGUMENT37
                   Dka_Tools_Pkg.tab_request_params (38), --ARGUMENT38
                   Dka_Tools_Pkg.tab_request_params (39), --ARGUMENT39
                   Dka_Tools_Pkg.tab_request_params (40), --ARGUMENT40
                   Dka_Tools_Pkg.tab_request_params (41), --ARGUMENT41
                   Dka_Tools_Pkg.tab_request_params (42), --ARGUMENT42
                   Dka_Tools_Pkg.tab_request_params (43), --ARGUMENT43
                   Dka_Tools_Pkg.tab_request_params (44), --ARGUMENT44
                   Dka_Tools_Pkg.tab_request_params (45), --ARGUMENT45
                   Dka_Tools_Pkg.tab_request_params (46), --ARGUMENT46
                   Dka_Tools_Pkg.tab_request_params (47), --ARGUMENT47
                   Dka_Tools_Pkg.tab_request_params (48), --ARGUMENT48
                   Dka_Tools_Pkg.tab_request_params (49), --ARGUMENT49
                   Dka_Tools_Pkg.tab_request_params (50), --ARGUMENT50
                   Dka_Tools_Pkg.tab_request_params (51), --ARGUMENT51
                   Dka_Tools_Pkg.tab_request_params (52), --ARGUMENT52
                   Dka_Tools_Pkg.tab_request_params (53), --ARGUMENT53
                   Dka_Tools_Pkg.tab_request_params (54), --ARGUMENT54
                   Dka_Tools_Pkg.tab_request_params (55), --ARGUMENT55
                   Dka_Tools_Pkg.tab_request_params (56), --ARGUMENT56
                   Dka_Tools_Pkg.tab_request_params (57), --ARGUMENT57
                   Dka_Tools_Pkg.tab_request_params (58), --ARGUMENT58
                   Dka_Tools_Pkg.tab_request_params (59), --ARGUMENT59
                   Dka_Tools_Pkg.tab_request_params (60), --ARGUMENT60
                   Dka_Tools_Pkg.tab_request_params (61), --ARGUMENT61
                   Dka_Tools_Pkg.tab_request_params (62), --ARGUMENT62
                   Dka_Tools_Pkg.tab_request_params (63), --ARGUMENT63
                   Dka_Tools_Pkg.tab_request_params (64), --ARGUMENT64
                   Dka_Tools_Pkg.tab_request_params (65), --ARGUMENT65
                   Dka_Tools_Pkg.tab_request_params (66), --ARGUMENT66
                   Dka_Tools_Pkg.tab_request_params (67), --ARGUMENT67
                   Dka_Tools_Pkg.tab_request_params (68), --ARGUMENT68
                   Dka_Tools_Pkg.tab_request_params (69), --ARGUMENT69
                   Dka_Tools_Pkg.tab_request_params (70), --ARGUMENT70
                   Dka_Tools_Pkg.tab_request_params (71), --ARGUMENT71
                   Dka_Tools_Pkg.tab_request_params (72), --ARGUMENT72
                   Dka_Tools_Pkg.tab_request_params (73), --ARGUMENT73
                   Dka_Tools_Pkg.tab_request_params (74), --ARGUMENT74
                   Dka_Tools_Pkg.tab_request_params (75), --ARGUMENT75
                   Dka_Tools_Pkg.tab_request_params (76), --ARGUMENT76
                   Dka_Tools_Pkg.tab_request_params (77), --ARGUMENT77
                   Dka_Tools_Pkg.tab_request_params (78), --ARGUMENT78
                   Dka_Tools_Pkg.tab_request_params (79), --ARGUMENT79
                   Dka_Tools_Pkg.tab_request_params (80), --ARGUMENT80
                   Dka_Tools_Pkg.tab_request_params (81), --ARGUMENT81
                   Dka_Tools_Pkg.tab_request_params (82), --ARGUMENT82
                   Dka_Tools_Pkg.tab_request_params (83), --ARGUMENT83
                   Dka_Tools_Pkg.tab_request_params (84), --ARGUMENT84
                   Dka_Tools_Pkg.tab_request_params (85), --ARGUMENT85
                   Dka_Tools_Pkg.tab_request_params (86), --ARGUMENT86
                   Dka_Tools_Pkg.tab_request_params (87), --ARGUMENT87
                   Dka_Tools_Pkg.tab_request_params (88), --ARGUMENT88
                   Dka_Tools_Pkg.tab_request_params (89), --ARGUMENT89
                   Dka_Tools_Pkg.tab_request_params (90), --ARGUMENT90
                   Dka_Tools_Pkg.tab_request_params (91), --ARGUMENT91
                   Dka_Tools_Pkg.tab_request_params (92), --ARGUMENT92
                   Dka_Tools_Pkg.tab_request_params (93), --ARGUMENT93
                   Dka_Tools_Pkg.tab_request_params (94), --ARGUMENT94
                   Dka_Tools_Pkg.tab_request_params (95), --ARGUMENT95
                   Dka_Tools_Pkg.tab_request_params (96), --ARGUMENT96
                   Dka_Tools_Pkg.tab_request_params (97), --ARGUMENT97
                   Dka_Tools_Pkg.tab_request_params (98), --ARGUMENT98
                   Dka_Tools_Pkg.tab_request_params (99), --ARGUMENT99
                   Dka_Tools_Pkg.tab_request_params (100) --ARGUMENT100
                )
            THEN
                Dka_Tools_Pkg.put_debug_message (
                    'Impossible de "fnd_submit.submit_program" le traitement '|| rec_prog.concurrent_program_name
                );
            END IF;
        END LOOP;

        -- Lancement du jeu
        vn_request_id    := Fnd_Submit.submit_set ();
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF NVL(vn_request_id,0) = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer "submit_set" pour le jeu de traitement '|| vv_program_code);
            pn_retcode    := 2;
        ELSE
            dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
        END IF;

        IF NOT Fnd_Concurrent.wait_for_request (vn_request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
           dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine normalement');
           ELSIF vv_dstatus = 'WARNING' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning ');
              pv_errbuf     := vv_message;
              pn_retcode    := 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Erreur ');
              pv_errbuf     := vv_message;
              pn_retcode    := 2;
           END IF;
        END IF;
        
        EXCEPTION
            WHEN OTHERS
            THEN
                pv_errbuf     := vv_message || ' launch_request_set :' || SQLERRM;
                pn_retcode    := 2;

    END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : copie_hvp
--  Description   : Procédure pour lancer "Copie en haut volume périodique "
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_org_id                       Entrée/Sortie           Id de l unite operationnelle
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE copie_hvp (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    )
    IS

    vn_user_id             NUMBER:=fnd_global.user_id;
    vv_user                VARCHAR2(50);
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vv_errbuf              VARCHAR2(500);
    vn_retcode             NUMBER;
    vv_program_code        VARCHAR2(100):= 'FAMCP';
    vv_application         VARCHAR2(100):= 'OFA';
    vv_param1              VARCHAR2(100);
    e_error                EXCEPTION;
    vn_appl_resp_id        fnd_application.application_id%TYPE;
    vv_appl_resp_name      fnd_application.application_short_name%TYPE;
    vn_req_set_id          fnd_request_sets.request_set_id%TYPE;
    vb_save_output         BOOLEAN;
    vv_periode_name        VARCHAR2(100);

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    
    vv_livre_social                  VARCHAR2(80);
    vv_org_name                      hr_operating_units.name%TYPE;
    
    BEGIN

        dka_Tools_Pkg.put_log_message('Recuperation Org_name');
        SELECT name
        INTO   vv_org_name
        FROM   hr_operating_units
        WHERE  organization_id = pn_org_id;
        
        vv_livre_social := SUBSTR(vv_org_name,4,7)||' IFRS';
        
        dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = SUBSTR(vv_org_name,4,7)||'_FA_SAISIE';

        SELECT user_name
        INTO   vv_user
        FROM   fnd_user
        WHERE  user_id = vn_user_id;
        
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
/*
        SELECT PERIOD_NAME 
        INTO vv_periode_name
        FROM FA_CALENDAR_PERIODS 
        WHERE SYSDATE BETWEEN START_DATE AND END_DATE
        and rownum = 1; 
*/

            BEgin
                SELECT corp_dp.period_name
                INTO vv_periode_name
                from FA_DEPRN_PERIODS CORP_DP, FA_DEPRN_PERIODS TAX_DP, FA_BOOK_CONTROLS_SEC BC
                WHERE CORP_DP.BOOK_TYPE_CODE     = BC.DISTRIBUTION_SOURCE_BOOK
                and bc.book_type_code          = vv_livre_social
                and tax_dp.book_type_code      = bc.book_type_code
                AND TAX_DP.PERIOD_CLOSE_DATE  IS NULL
                and corp_dp.period_close_date  is null
                AND ((corp_dp.calendar_period_open_date <=
                tax_dp.calendar_period_close_date AND
                bc.last_mass_copy_period_counter is null) OR
                (bc.last_mass_copy_period_counter is not null and
                (corp_dp.period_counter = bc.last_mass_copy_period_counter + 1
                or  corp_dp.period_counter = 
                BC.LAST_MASS_COPY_PERIOD_COUNTER)))
                ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN 
                    SELECT period_name
                    INTO vv_periode_name
                    FROM (SELECT corp_dp.period_name
                    from FA_DEPRN_PERIODS CORP_DP, FA_DEPRN_PERIODS TAX_DP, FA_BOOK_CONTROLS_SEC BC
                    WHERE CORP_DP.BOOK_TYPE_CODE     = BC.DISTRIBUTION_SOURCE_BOOK
                    and bc.book_type_code          = vv_livre_social
                    and tax_dp.book_type_code      = bc.book_type_code
                    AND TAX_DP.PERIOD_CLOSE_DATE  IS NULL
                    --and corp_dp.period_close_date  is null
                    AND ((corp_dp.calendar_period_open_date <=
                    tax_dp.calendar_period_close_date AND
                    bc.last_mass_copy_period_counter is null) OR
                    (bc.last_mass_copy_period_counter is not null and
                    (corp_dp.period_counter = bc.last_mass_copy_period_counter + 1
                    or  corp_dp.period_counter = 
                    BC.LAST_MASS_COPY_PERIOD_COUNTER)))
                    ORDER BY CORP_DP.PERIOD_COUNTER DESC)
                    WHERE ROWNUM = 1;
                EXCEPTION
                WHEN OTHERS THEN
                    dka_Tools_Pkg.put_log_message('Problème de recupération de la période pour le livre '||vv_livre_social);
                    pn_retcode    := 2;
                END;
            WHEN OTHERS THEN
                dka_Tools_Pkg.put_log_message('Problème de recupération de la période pour le livre '||vv_livre_social);
                pn_retcode    := 2;
            END;
            
            dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || vv_livre_social);
            vn_request_id    := fnd_request.submit_request (
                                    vv_application,     --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                    vv_program_code,    --SHORT_NAME du TRAITEMENT
                                    NULL,               --PROGRAM_NAME
                                    NULL,               --START
                                    FALSE,              --SUB_REQUEST
                                    vv_livre_social,
                                    vv_periode_name,
                                    2
                                    );

            dka_Tools_Pkg.put_log_message('Validation pour que les GTS puissent prendre la demande');
            
            IF NVL(vn_request_id,0) = 0
            THEN
                dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement ');
                pn_retcode    := 2;
            ELSE
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;
        
            IF NOT Fnd_Concurrent.wait_for_request (vn_request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine normalement');
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning ');
                  pv_errbuf     := vv_message;
                  pn_retcode    := 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Erreur ');
                  pv_errbuf     := vv_message;
                  pn_retcode    := 2;
               END IF;
            END IF;
        
    EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_message || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
            
    END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : valider_immo
--  Description   : Procédure pour lancer "PRC : Valider l'importation des lignes d'immobilisation dans Oracle Assets "
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_org_id                       Entrée/Sortie           Id de l unite operationnelle
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE valider_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    )
    IS
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    
    
    vv_rphase              VARCHAR2 (80);
    vv_rstatus             VARCHAR2 (80);
    vv_dphase              VARCHAR2 (30);
    vv_dstatus             VARCHAR2 (30);
    vv_message             VARCHAR2 (240);
    vv_mesg                VARCHAR2(500);
    
    BEGIN
    
        dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_PA_ADMINISTRATEUR';

        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
        
        --  Traitement multi-org    
        FND_REQUEST.SET_ORG_ID(pn_org_id);

        dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || pn_org_id);
        vn_request_id    := fnd_request.submit_request (
                                'PA',       --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                'PACFATBP', --SHORT_NAME du TRAITEMENT
                                NULL,       --PROGRAM_NAME
                                NULL,       --START
                                FALSE       --SUB_REQUEST
                                )
                                ;
        dka_Tools_Pkg.put_log_message('Validation pour que les GTS puissent prendre la demande');

        IF NVL(vn_request_id,0) = 0
        THEN
            dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement ');
            pn_retcode    := 2;
        ELSE
            COMMIT;
            dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
        END IF;


        IF NOT Fnd_Concurrent.wait_for_request (vn_request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
           dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine normalement');
           ELSIF vv_dstatus = 'WARNING' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Warning ');
              pv_errbuf     := vv_message;
              pn_retcode    := 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              dka_Tools_Pkg.put_log_message('Traitement '||vn_request_id||' termine en Erreur ');
              pv_errbuf     := vv_message;
              pn_retcode    := 2;
           END IF;
        END IF;
        
        EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_message || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
    END;


END DKA_SFAGENIMMO_PKG; -- Package body

/
SHOW ERRORS;
EXIT;
