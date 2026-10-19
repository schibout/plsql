CREATE OR REPLACE PACKAGE BODY dka_glparv_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- $Id: DKA_GLPARV_PKG.pkb 686 2008-05-22 08:52:21Z CORP\jdequidt $
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_GLPARV_PKG.pkb
-- DESCRIPTION       : Lancement du traitement de contrepassation GL
---
--- AUTEUR           : Xavier Descamps
--- DATE DE CREATION : 15/12/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 26/08/2005 JVI Modification suite passage 11.5.9 :
---                le paramètre n'est plus la période précédente mais la période en
---                en cours. Suppression de l'ouverture fermeture de période
--- 01/09/2006 AC  Récupération du statut de la période précédente
---                update qui rend nulles les informations projet sur les lignes de contrepassation avec compte de bilan
--- 05/11/2007 ADR ETANCHEITE DALKIA 2007
--- 30/04/2008 VKN Ajout des truncs sur les selects de gl_period_statuses (Essayer de le lancer le dernier jour du mois sans ca...)
--- 16/06/2016 JPE MIGRATION R12
--- 21/06/2017 OBE artf2179450 : SPE046 - Contre Passation - Erreur de lancement batch DKA_GLPARV_JOB.sh - Defect BeB #831
--- 27/02/2018 MEG artf2402627 : SPE046 - Gestion spécifique des extournes dans GL
--- 15/10/2018 SFA artf3031870 : EDB219_DPE20180032 - Contrepassation automatique sur compte d'immos en cours
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
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    
        --< OBE artf2179450
        CURSOR Cur_societe IS
          SELECT   gl.ledger_id
          FROM     gl_access_set_assignments gasa, gl_ledgers gl
          WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
          AND      gl.ledger_id = gasa.ledger_id
          AND      gl.ledger_category_code = 'PRIMARY'
          ;          
        --> OBE artf2179450  
        
        vn_request_id          fnd_concurrent_requests.request_id%TYPE;
        vv_rphase              VARCHAR2 (80);
        vv_rstatus             VARCHAR2 (80);
        vv_dphase              VARCHAR2 (30);
        vv_dstatus             VARCHAR2 (30);
        vv_message             VARCHAR2 (240);
        vv_closing_status      gl_period_statuses.closing_status%TYPE;
        vv_period_name         gl_period_statuses.period_name%TYPE;
        vb_period_reopen       BOOLEAN                                     := FALSE;
        --< OBE artf2179450
        vn_indice                        NUMBER;
        vn_traitement                    NUMBER := 0;
        TYPE myrecord IS RECORD (
         request_id    NUMBER); 
        TYPE mytable IS TABLE OF myrecord
             INDEX BY BINARY_INTEGER;

        vt_traitement                    mytable;          
        --> OBE artf2179450

    BEGIN

     -- Avant le lancement des traitements "Programme - Contrepassation automatique" (GLPARV) pour chaque livre, il faut degeler l'origine de piece "Achats".
     UPDATE GL_JE_SOURCES
        SET override_edits_flag = 'N'
      WHERE je_source_name = 'Purchasing';
     COMMIT;
     
     FOR cur IN Cur_societe LOOP -- OBE artf2179450

     
       --< OBE artf2179450
       /*
       IF gn_set_of_bks_id IS NULL THEN
         dka_tools_pkg.put_log_message('L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétré');
         pv_errbuf := 'L''option de profil 1_Nom de l''entité comptable Oracle GL n''est pas paramétré';
         pn_retcode := 2;
         RETURN;
       END IF;
       */
       --> OBE artf2179450
       
       
        -- Récupération du statut de la période précédente /AC le 01/09/2006
       SELECT gps.closing_status,
               gps.period_name
        INTO   vv_closing_status,
               vv_period_name
        FROM   gl_period_statuses gps
        WHERE      gps.ledger_id = cur.ledger_id -- fnd_profile.value ('GL_SET_OF_BKS_ID') -- OBE artf2179450
               AND gps.application_id = 101
               AND trunc(ADD_MONTHS (SYSDATE, -1)) BETWEEN gps.start_date AND gps.end_date;

       /* -- Si la période est fermée, il faut la ré-ouvrir
        IF vv_closing_status = 'C'
        THEN
            vb_period_reopen   := TRUE;

            dka_tools_pkg.put_debug_message ('Ouverture de ' || vv_period_name);

            UPDATE gl_period_statuses gps
            SET    gps.closing_status = 'O',
                   gps.last_updated_by = fnd_global.user_id,
                   gps.last_update_date = SYSDATE,
                   gps.last_update_login = fnd_global.login_id
            WHERE      gps.set_of_books_id = fnd_profile.value ('GL_SET_OF_BKS_ID')
                   AND gps.application_id = 101
                   AND gps.period_name = vv_period_name;
        END IF;*/--JVI 26/08/2005
        
		
		------ annulation de l'aupdate ci-dessous :  -- SFA --artf3031870 : EDB219 --15/10/2018
		
	    -- attribute relatifs au projet mis à jour pour les lignes avec un compte de bilan /AC 01/09/2006   
			
		---update gl_je_lines gll  set attribute11 = null, attribute12 = null, attribute13 = null, attribute14 = null  
		---where  period_name = vv_period_name                                                                          
		---and gll.attribute11 is not NULL                                                                              
		/* ETANCHEITE DALKIA 2007 */ 
		-- JPE 16/06/2016 MIGRATION R12
		----and gll.ledger_id = cur.ledger_id -- gn_set_of_bks_id -- OBE artf2179450                                  
		---and gll.code_combination_id in (select code_combination_id from gl_code_combinations where account_type not in ('R', 'E')); 
	   
		--Dka_Tools_Pkg.put_debug_message ('   > Nb de lignes MAJ: '||SQL%ROWCOUNT);*/   

		
		
        --Modification du fonctionnement traitement standard en 11.5.9
        --Paramètre de lancement : période en cours
        SELECT gps.closing_status,
               gps.period_name
        INTO   vv_closing_status,
               vv_period_name
        FROM   gl_period_statuses gps
        WHERE      gps.ledger_id = cur.ledger_id --fnd_profile.value ('GL_SET_OF_BKS_ID') -- OBE artf2179450
               AND gps.application_id = 101
               AND trunc(SYSDATE) BETWEEN gps.start_date AND gps.end_date;

        --Lancement du traitement
        vn_request_id    :=
        fnd_request.submit_request (
                    'SQLGL', --APPLICATION
                    'GLPARV', --PROGRAM
                    NULL, --PROGRAM_NAME
                    NULL, --START_TIME
                    FALSE, --SUB_REQUEST
                    cur.ledger_id,--fnd_profile.value ('GL_SET_OF_BKS_ID'), -- OBE artf2179450
					vv_period_name,
					fnd_profile.value ('GL_ACCESS_SET_ID') -- MIGRATION R12
                );
                
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;                

        IF NVL (vn_request_id, 0) = 0
        THEN
            pn_retcode    := 2;
            pv_errbuf     := 'Le traitement de contrepassation n''a pas pu être lancé';
            dka_tools_pkg.put_debug_message (pv_errbuf);
        ELSE
            pn_retcode    := 0;
            dka_tools_pkg.put_debug_message ('Traitement de contrepassation lancé : ' || TO_CHAR (vn_request_id));
        END IF;

        COMMIT;

        -- Attente de fin du traitement
        --< OBE artf2179450
        /*
        IF NOT fnd_concurrent.wait_for_request (
                   vn_request_id,
                   15,
                   0,
                   vv_rphase,
                   vv_rstatus,
                   vv_dphase,
                   vv_dstatus,
                   vv_message)
        THEN
            pv_errbuf    := 'ERREUR dans l''attente de fin du traitement';
            pn_retcode   := 2;
        ELSE
            IF vv_dstatus = 'WARNING'
            THEN
                pv_errbuf    := 'Traitement de contrepassation terminé en Warning ';
                pn_retcode   := 1;
            ELSIF vv_dstatus != 'NORMAL'
            THEN
                pv_errbuf    := 'Traitement de contrepassation terminé en Erreur ';
                pn_retcode   := 2;
            END IF;
        END IF;
        */
        --> OBE artf2179450

   /*     -- Si la période a été ré-ouverte, il faut la refermer
        IF vb_period_reopen
        THEN
            dka_tools_pkg.put_debug_message ('Fermeture de ' || vv_period_name);

            UPDATE gl_period_statuses gps
            SET    gps.closing_status = 'C',
                   gps.last_updated_by = fnd_global.user_id,
                   gps.last_update_date = SYSDATE,
                   gps.last_update_login = fnd_global.login_id
            WHERE      gps.set_of_books_id = fnd_profile.value ('GL_SET_OF_BKS_ID')
                   AND gps.application_id = 101
                   AND gps.period_name = vv_period_name;
        END IF;*/--JVI 26/08/2005
        
     END LOOP; -- OBE artf2179450   
     
    --< OBE artf2179450 
    FOR vn_indice IN 1..vn_traitement 
    LOOP
    IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 15, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN
        pn_retcode := 2;
        dka_tools_pkg.put_debug_message ('--> Traitement trop long: '|| TO_CHAR (vt_traitement(vn_indice).request_id) );
        dka_tools_pkg.put_debug_message ('Erreur sur le traitement '|| TO_CHAR (vt_traitement(vn_indice).request_id));        
        RETURN;
    ELSE
         IF vv_dstatus = 'NORMAL' THEN
            dka_tools_pkg.put_debug_message (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut Normal');
         ELSIF vv_dstatus = 'WARNING' THEN
            dka_tools_pkg.put_debug_message (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut en Warning');
         ELSIF vv_dstatus != 'NORMAL' THEN
            dka_tools_pkg.put_debug_message (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut en Erreur');
            dka_tools_pkg.put_debug_message ('>>>    message = "' || vv_message || '"');
         END IF;       
    END IF;
    END LOOP;
    --> OBE artf2179450
    
     -- Puis, quand les traitements "Programme - Contrepassation automatique" sont terminés, il faut regeler l'origine de piece "Achats".
     UPDATE GL_JE_SOURCES
        SET override_edits_flag = 'Y'
      WHERE je_source_name = 'Purchasing';
     COMMIT; 
        
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM (SQLCODE);
            pn_retcode    := 2;
    END main;

END dka_glparv_pkg;
/
SHOW ERROR
EXIT;
