CREATE OR REPLACE PACKAGE BODY DKA_SFADATAJ_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SFADATAJ_PKG.pkb 271 2018-01-03 10:13:20 $
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications (Helios R12)
-- NOM               : DKA_SFADATAJ_PKG.pkb
-- DESCRIPTION       : DKA_SFADATAJ_PKG package body :
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 03/01/2018
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
--- 28/01/2019 SNK artf3051477 - EDB226 DPE20180037 Ajout du traitement « Calcul des +/- values » 
--- 21/04/2020 ARA tracker50786 - INC0419432 Changement dans la fonction copie_hvp concernant la UO de référence
--- 20/10/2020 SHA artf07415926 - INC0473703 Changement dans la fonction calcul_values afin d'y ajouter une boucle pour attendre que tous les traitements lancés soit terminés.
--- 20/07/2023 BNZ EDB366 Ajout du traitement « Generer des comptes » 
--------------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
     
-------------------------------------------------------------------------------------------------------------------
--  Nom           : Generer_comptes
--  Description   : Procédure pour lancer "DKA : Generer des comptes"
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
---< BNZ : EDB366 --------- 
PROCEDURE generer_comptes (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
	----- Curseur sur Type code livre FA -----
  CURSOR cur_book_type 
  IS
  SELECT DISTINCT book_type_code 
  FROM fa_books;
  
    vn_user_id                       NUMBER:=fnd_global.user_id;
    vn_responsibility_id             NUMBER;
    vn_application_id                NUMBER;
    gen_id                           NUMBER;
    vv_mesg                          VARCHAR2(500);
    vn_traitement                    NUMBER:= 0;---Compteur de request
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;---Tableau
  BEGIN
  
      dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_FA_ADMINISTRATEUR';
       
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
    
     FOR R1 IN cur_book_type
     LOOP
     
        vn_trt_a_lancer := vn_trt_a_lancer + 1;
     
    
     
     -- submit Generate Accounts Program
                gen_id := Fnd_Request.submit_request('OFA', -- application
                                                   'FAGDA', -- program : Générer des comptes
                                                   '', -- description
                                                   '', -- start_time
                                                   false, --sub_request : FALSE
                                                   R1.book_type_code --argument1
                                                   );
     IF NVL(gen_id,0) = 0
            THEN
      dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement pour le livre FA : ' || R1.book_type_code);
      pn_retcode    := 2;
      
     ELSE   
            vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := gen_id;
                vn_trt_lances := vn_trt_lances + 1;
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (gen_id));
            END IF;
    
      
      
     END LOOP;
    FOR vn_indice IN 1..vn_traitement 
        LOOP
          IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (gen_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  vn_trt_warning := vn_trt_warning + 1;
               END IF;
            END IF;

        END LOOP;
    --Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');
    dka_Tools_Pkg.put_log_message('');
  END;

---> 20/07/2023 BNZ :  Fin EDB366 -------------

    
  
-------------------------------------------------------------------------------------------------------------------
--  Nom           : transfer_immo
--  Description   : Procédure pour lancer "PRC : Transférer des immobilisations vers Oracle Assets"
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------

-- artf3051477 SNIK 28/01/2019
PROCEDURE calcul_values (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
	CURSOR FA_BOOK 
	IS
	SELECT DISTINCT book_type_code 
	FROM fa_books;
	
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
	--l_period_name          VARCHAR2(15);
	vn_trt_a_lancer        NUMBER:=0;
    vn_trt_lances          NUMBER:=0;
	vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
	 TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;
	BEGIN
	
	    dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_FA_ADMINISTRATEUR';
       
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
		
		 FOR R0 IN FA_BOOK
		 LOOP
		 
		 vn_trt_a_lancer := vn_trt_a_lancer + 1;
		 
		 /*BEGIN
		 SELECT period_name
         INTO l_period_name
         FROM fa_deprn_periods  
         WHERE period_close_date IS NULL
		 AND   book_type_code = R0.book_type_code;
		 EXCEPTION WHEN OTHERS THEN
              l_period_name := NULL;
		 END;*/
		 
		 dka_Tools_Pkg.put_log_message('Soumission du traitement pour le livre FA : ' || R0.book_type_code);
		 vn_request_id    := fnd_request.submit_request (
                                    'OFA',       --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                    'FARET', --SHORT_NAME du TRAITEMENT : Calculer les plus- et moins-values
                                    NULL,       --PROGRAM_NAME
                                    NULL,       --START
                                    FALSE,      --SUB_REQUEST
                                    R0.book_type_code
                                    )
                                    ;
		 IF NVL(vn_request_id,0) = 0
            THEN
			dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement pour le livre FA : ' || R0.book_type_code);
			pn_retcode    := 2;
			
		 ELSE   
        		vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := vn_request_id;
                vn_trt_lances := vn_trt_lances + 1;
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;
		
			
			
		 END LOOP;
		FOR vn_indice IN 1..vn_traitement 
        LOOP
            IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  --- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
                  vn_trt_warning := vn_trt_warning + 1;
               END IF;
            END IF;

        END LOOP;
		--Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
		dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');
		dka_Tools_Pkg.put_log_message('');
	END;
	
    PROCEDURE transfer_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
--- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
    CURSOR cur_org2(p_profile NUMBER)
    IS /*SELECT organization_id,organization_name
    FROM PER_SECURITY_ORGANIZATIONS_V ov
    WHERE ov.security_profile_id = p_profile*/
    SELECT ov.organization_id, hou.name organization_name
    FROM PER_SECURITY_ORGANIZATIONS ov, hr_all_organization_units_tl hou
    WHERE ov.security_profile_id = p_profile
    AND ov.organization_id = hou.organization_id
    AND hou.language = 'F';
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vn_traitement          NUMBER         := 0;
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vd_date                          DATE;
    l_profile_option                 NUMBER := fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL');
    
    BEGIN
    
        dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_FA_ADMINISTRATEUR';
       
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
                 
        --- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
        FOR rec_cur_org IN cur_org2(l_profile_option)
        LOOP
             vn_trt_a_lancer := vn_trt_a_lancer + 1;
            
            --  Traitement multi-org    
            FND_REQUEST.SET_ORG_ID(rec_cur_org.organization_id);

            BEGIN
                SELECT end_date
                INTO vd_date
                FROM PA_PERIODS_ALL
                WHERE ORG_ID = rec_cur_org.organization_id
                AND STATUS = 'O'
                AND CURRENT_PA_PERIOD_FLAG = 'Y';
            EXCEPTION
            WHEN OTHERS THEN
                vd_date := NULL;
                dka_Tools_Pkg.put_log_message('La période PA ouverte n''est pas trouvée ');
                pn_retcode    := 2;
                continue;
            END;
            dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || rec_cur_org.organization_name);
            --- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
            vn_request_id    := fnd_request.submit_request (
                                    'PA',       --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                    'PAXCPCAL', --SHORT_NAME du TRAITEMENT
                                    NULL,       --PROGRAM_NAME
                                    NULL,       --START
                                    FALSE,      --SUB_REQUEST
                                    'FC000000A',
                                    'FC999999Z',
--                                    vd_date,
                                    NULL,
                                    'N'
                                    )
                                    ;
            
            dka_Tools_Pkg.put_log_message('Validation pour que les GTS puissent prendre la demande');
            --vn_traitement := vn_traitement + 1;
            --vt_traitement(vn_traitement).request_id   := vn_request_id;
            --vn_trt_a_lancer := vn_trt_a_lancer + 1;
            --COMMIT;

            IF NVL(vn_request_id,0) = 0
            THEN
                dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement pour '||rec_cur_org.organization_name);
                pn_retcode    := 2;
            ELSE
                vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := vn_request_id;
                vn_trt_lances := vn_trt_lances + 1;
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;

        END LOOP;

        FOR vn_indice IN 1..vn_traitement 
        LOOP
            IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  --- 06/07/2018 NBO artf2785514 - INC0227603 Incident lié à  l'EDB 101 . 
                  vn_trt_warning := vn_trt_warning + 1;
               END IF;
            END IF;

        END LOOP;

        --Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');

        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'Bilan des traitements :');
        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        Fnd_File.put_line (Fnd_File.output,'');
        
        IF vn_trt_erreur > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_a_lancer > vn_trt_lances THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 1;
        ELSIF vn_trt_warning > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 1;
        END IF;
        
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
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE imput_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    
    CURSOR cur_ledger IS
    SELECT BC.BOOK_TYPE_CODE,BC.BOOK_TYPE_NAME 
    FROM FA_BOOK_CONTROLS_SEC BC
    Where NVL(BC.DATE_INEFFECTIVE, SYSDATE+1) > SYSDATE
    AND EXISTS (SELECT 1 
    FROM FA_MASS_ADDITIONS MA
    WHERE BC.BOOK_TYPE_CODE = MA.BOOK_TYPE_CODE
    AND MA.POSTING_STATUS = 'POST')
    ORDER BY BC.BOOK_TYPE_CODE
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
               
    vn_traitement          NUMBER         := 0;
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    
    BEGIN
        
        -- Positionnement de l'environnement
        SELECT fr.responsibility_id,
               fr.application_id  ,
               fa.application_short_name
        INTO   vn_responsibility_id,
               vn_appl_resp_id,
               vv_appl_resp_name
        FROM   fnd_responsibility fr ,
               fnd_application fa
        WHERE  fr.responsibility_key = 'TOUT_FA_ADMINISTRATEUR'
        AND    fr.application_id = fa.application_id;

        SELECT frs.request_set_id
        INTO   vn_req_set_id
        FROM   fnd_request_sets frs
        WHERE  frs.request_set_name = vv_program_code;

        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_appl_resp_id);

        FOR rec_cur_ledger IN cur_ledger 
        LOOP
            vn_trt_a_lancer := vn_trt_a_lancer + 1;
            -- Initialisation
            IF NOT Fnd_Submit.set_request_set (vv_application, vv_program_code)
            THEN
                Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_submit.set_request_set" le jeu de traitements '|| vv_program_code);
                pn_retcode    := 2;
                Continue;
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
            
                Dka_Tools_Pkg.tab_request_params (1) := rec_cur_ledger.BOOK_TYPE_CODE;
                
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
                continue;
            ELSE
                vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := vn_request_id;
                vn_trt_lances := vn_trt_lances + 1;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;
        
        END LOOP;
        
        FOR vn_indice IN 1..vn_traitement 
        LOOP
            IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  vn_trt_erreur := vn_trt_erreur + 1;
               END IF;
            END IF;

        END LOOP;

        --Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des jeux de traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de jeux de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de jeux de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de jeux de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de jeux de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de jeux de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');
        
        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'Bilan des jeux de traitements :');
        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de jeux de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de jeux de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de jeux de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de jeux de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de jeux de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

        IF vn_trt_erreur > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_a_lancer > vn_trt_lances THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_warning > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 1;
        END IF;
        
        EXCEPTION
            WHEN OTHERS
            THEN
                pv_errbuf     := 'launch_request_set :' || SQLERRM;
                pn_retcode    := 2;

    END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : copie_hvp
--  Description   : Procédure pour lancer "Copie en haut volume périodique "
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE copie_hvp (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    
    CURSOR cur_ledger IS
    --ARA
	SELECT BOOK_TYPE_CODE,BOOK_TYPE_NAME
    from FA_BOOK_CONTROLS_SEC
    where ALLOW_MASS_COPY = 'YES'
    and BOOK_CLASS = 'TAX'
    AND DATE_INEFFECTIVE IS NULL
    AND org_id IN (
					SELECT organization_id 
					FROM PER_SECURITY_ORGANIZATIONS
					WHERE SECURITY_PROFILE_ID = (
						SELECT SECURITY_PROFILE_ID
						FROM PER_SECURITY_PROFILES
						WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT'
					)
				)
    order by 1
    ;
	
     
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

    vn_traitement          NUMBER         := 0;
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;

    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    
    BEGIN
    
        dka_Tools_Pkg.put_log_message('Recuperation des identifiants user');
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = 'TOUT_FA_ADMINISTRATEUR';

        SELECT user_name
        INTO   vv_user
        FROM   fnd_user
        WHERE  user_id = vn_user_id;
        
        dka_Tools_Pkg.put_log_message('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

        /*SELECT PERIOD_NAME 
        INTO vv_periode_name
        FROM FA_CALENDAR_PERIODS 
        WHERE SYSDATE BETWEEN START_DATE AND END_DATE
        and rownum = 1; */



        FOR rec_cur_ledger IN cur_ledger
        LOOP
            vn_trt_a_lancer := vn_trt_a_lancer + 1;

            BEgin
                SELECT corp_dp.period_name
                INTO vv_periode_name
                from FA_DEPRN_PERIODS CORP_DP, FA_DEPRN_PERIODS TAX_DP, FA_BOOK_CONTROLS_SEC BC
                WHERE CORP_DP.BOOK_TYPE_CODE     = BC.DISTRIBUTION_SOURCE_BOOK
                and bc.book_type_code          = rec_cur_ledger.BOOK_TYPE_CODE
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
                    and bc.book_type_code          = rec_cur_ledger.BOOK_TYPE_CODE
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
                    dka_Tools_Pkg.put_log_message('Problème de recupération de la période pour le livre '||rec_cur_ledger.BOOK_TYPE_CODE);
                    pn_retcode    := 2;
                    continue;
                END;
            WHEN OTHERS THEN
                dka_Tools_Pkg.put_log_message('Problème de recupération de la période pour le livre '||rec_cur_ledger.BOOK_TYPE_CODE);
                pn_retcode    := 2;
                continue;
            END;
            dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || rec_cur_ledger.BOOK_TYPE_CODE);
            vn_request_id    := fnd_request.submit_request (
                                    vv_application,     --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                    vv_program_code,    --SHORT_NAME du TRAITEMENT
                                    NULL,               --PROGRAM_NAME
                                    NULL,               --START
                                    FALSE,              --SUB_REQUEST
                                    rec_cur_ledger.BOOK_TYPE_CODE,
                                    vv_periode_name,
                                    2
                                    );

            dka_Tools_Pkg.put_log_message('Validation pour que les GTS puissent prendre la demande');
            
            IF NVL(vn_request_id,0) = 0
            THEN
                dka_Tools_Pkg.put_log_message('Impossible de lancer le Traitement ');
                pn_retcode    := 2;
                continue;
            ELSE
                vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := vn_request_id;
                vn_trt_lances := vn_trt_lances + 1;
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;
        
        END LOOP;
        
        FOR vn_indice IN 1..vn_traitement 
        LOOP
            IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  vn_trt_erreur := vn_trt_erreur + 1;
               END IF;
            END IF;

        END LOOP;

        --Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');

        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'Bilan des traitements :');
        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        Fnd_File.put_line (Fnd_File.output,'');
        
        IF vn_trt_erreur > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_a_lancer > vn_trt_lances THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_warning > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 1;
        END IF;
        
    EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
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
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE valider_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    
    CURSOR cur_org
    IS SELECT organization_id,organization_name
    FROM PER_SECURITY_ORGANIZATIONS_V ov
    WHERE ov.security_profile_id = fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL')
    ;
     
    vn_user_id             NUMBER:=fnd_global.user_id;
    vn_responsibility_id   NUMBER;
    vn_application_id      NUMBER;
    vn_request_id          NUMBER;
    vv_mesg                VARCHAR2(500);
    vn_traitement          NUMBER         := 0;
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    
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
        
        FOR rec_cur_org IN cur_org
        LOOP
            vn_trt_a_lancer := vn_trt_a_lancer + 1;
            --  Traitement multi-org    
            FND_REQUEST.SET_ORG_ID(rec_cur_org.organization_id);

            dka_Tools_Pkg.put_log_message('Soumission du traitement pour ' || rec_cur_org.organization_name);
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
                continue;
            ELSE
                vn_traitement := vn_traitement + 1;
                vt_traitement(vn_traitement).request_id   := vn_request_id;
                vn_trt_lances := vn_trt_lances + 1;
                COMMIT;
                dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
            END IF;

        END LOOP;

        FOR vn_indice IN 1..vn_traitement 
        LOOP
            IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               dka_Tools_Pkg.put_log_message('Traitement numero : ' || TO_CHAR (vn_request_id));
               dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
            ELSE
               IF vv_dstatus = 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
                  vn_trt_normal := vn_trt_normal + 1;
               ELSIF vv_dstatus = 'WARNING' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
                  vn_trt_warning := vn_trt_warning + 1;
               ELSIF vv_dstatus != 'NORMAL' THEN
                  dka_Tools_Pkg.put_log_message('Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
                  vn_trt_erreur := vn_trt_erreur + 1;
               END IF;
            END IF;

        END LOOP;

        --Etat de synthèse
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('Bilan des traitements :');
        dka_Tools_Pkg.put_log_message('');
        dka_tools_pkg.put_log_message ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        dka_tools_pkg.put_log_message ('==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        dka_Tools_Pkg.put_log_message('');

        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'Bilan des traitements :');
        Fnd_File.put_line (Fnd_File.output,'');
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        Fnd_File.put_line (Fnd_File.output,'==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
        Fnd_File.put_line (Fnd_File.output,'');
        
        IF vn_trt_erreur > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_a_lancer > vn_trt_lances THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        ELSIF vn_trt_warning > 0 THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 1;
        END IF;
        
        EXCEPTION
        WHEN OTHERS
        THEN
            vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
    END;


END DKA_SFADATAJ_PKG; -- Package body
/
SHOW ERRORS;
EXIT;
