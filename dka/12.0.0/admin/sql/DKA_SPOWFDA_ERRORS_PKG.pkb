CREATE OR REPLACE PACKAGE BODY DKA_SPOWFDA_ERRORS_PKG
AS

----------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOWFDA_ERRORS_PKG.pkb
-- DESCRIPTION       : DKA_SPOWFDA_ERRORS_PKG package body
---
--- AUTEUR           : C. Delcasso
--- DATE DE CREATION : 26/09/2006
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
--- 23/04/2010 CDE EARS00009081466 - Correction pour traiter aussi les DA
---                Pré-approuvées
--- 25/10/2016 RGH Migration R12
--- 15/03/2017 YWA artf2120387
--- 14/02/2018 RBE artf2376252 : SPE111 - Correction de la sélection Employés
----------------------------------------------------------------------------


    gn_user_id                      fnd_user.user_id%TYPE;
    gn_login_id                     fnd_logins.login_id%TYPE;
    gn_request_id                   fnd_concurrent_requests.request_id%TYPE;
    gv_authorization_status_err     po_requisition_headers_all.authorization_status%TYPE;
    gv_authorization_status_new     po_requisition_headers_all.authorization_status%TYPE;
    gv_activity_status              wf_item_activity_statuses.activity_status%TYPE;
    gv_item_type_da                 wf_item_activity_statuses.item_type%TYPE;
    gv_item_type_err                wf_item_activity_statuses.item_type%TYPE;
    gv_activity_status_not          wf_item_activity_statuses.activity_status%TYPE;
    gv_activity_status_complete     wf_item_activity_statuses.activity_status%TYPE;
    gv_result_code_abort            wf_item_activity_statuses.activity_result_code%TYPE;
    gv_result_code_force            wf_item_activity_statuses.activity_result_code%TYPE;
    gv_status_closed                wf_notifications.status%TYPE;
    gv_conn                         VARCHAR2(30);
    gv_expediteur                   VARCHAR2(50);
    gv_responder                    VARCHAR2(10);
    gn_nbre_jour                    NUMBER(15);
    gv_mail_test                  VARCHAR2(240) := NULL;--YWA artf2120387 

----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--PARAMETRES :
--  pv_errbuf   Entrée/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        dka_tools_pkg.put_debug_message ('(+) Init');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- En-tête du fichier de sortie
        dka_tools_pkg.put_out_header;

        -- Variables globale "WHO"
        gn_user_id                      := fnd_global.user_id;
        gn_login_id                     := fnd_global.login_id;
        gn_request_id                   := fnd_global.conc_request_id;

        -- Variables MAJ des DA
        gv_authorization_status_err     := 'IN PROCESS';
        gv_authorization_status_new     := 'INCOMPLETE';
        gv_activity_status              := 'ERROR';
        gv_item_type_da                 := 'REQAPPRV';
        gv_item_type_err                := 'WFERROR';
        gv_activity_status_not          := 'NOTIFIED';
        gv_activity_status_complete     := 'COMPLETE';
        gv_result_code_abort            := 'ABORT';
        gv_result_code_force            := '#FORCE';
        gv_status_closed                := 'CLOSED';
        gv_responder                    := 'SYSADMIN';


        -- Variables liées à l'envoi du mail
        Dka_Tools_Pkg.get_parameter ('SPOWFDA_ERRORS', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
        gv_conn                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre SMTP_CONNECTION : ' || pv_errbuf;
            RETURN;
        ELSIF gv_conn IS NULL
        THEN
            pv_errbuf    := 'Paramètre SMTP_CONNECTION : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_conn : ' || gv_conn);

        Dka_Tools_Pkg.get_parameter ('SPOWFDA_ERRORS', 'EXPEDITEUR_MAIL', rec_param, pv_errbuf, pn_retcode);
        gv_expediteur                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre EXPEDITEUR_MAIL : ' || pv_errbuf;
            RETURN;
        ELSIF gv_expediteur IS NULL
        THEN
            pv_errbuf    := 'Paramètre EXPEDITEUR_MAIL : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_expediteur : ' || gv_expediteur);

        Dka_Tools_Pkg.get_parameter ('SPOWFDA_ERRORS', 'NBRE_JOURS', rec_param, pv_errbuf, pn_retcode);
        gn_nbre_jour                   := rec_param.number_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre NBRE_JOURS : ' || pv_errbuf;
            RETURN;
        ELSIF gn_nbre_jour IS NULL
        THEN
            gn_nbre_jour := 0;
        END IF;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_nbre_jour : ' || gn_nbre_jour);



        dka_tools_pkg.put_debug_message ('(-) Init');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;
    END init;


----------------------------------------------------------------------------
--  Nom           : insert_dka_spowfda_errors
--  Description   :
--
--PARAMETRES :
--  pv_errbuf   Entrée/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE insert_dka_spowfda_errors (
        pv_errbuf           IN OUT  VARCHAR2,
        pn_retcode          OUT     NUMBER
    )
    IS
        vv_errbuf               VARCHAR2 (500);

    BEGIN
        dka_tools_pkg.put_debug_message ('(+) insert_dka_spowfda_errors');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        Dka_Tools_Pkg.put_outdebug_message('***** SELECTION DES DA A RECYCLER *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));


        INSERT INTO dka_spowfda_errors
                    (requisition_header_id,
                     segment1,
                     description,
                     creation_date,
                     to_person_id,
                     nom_demandeur,
                     prenom_demandeur,
                     centrefinance_demandeur,
                     matricule_createur,
                     nom_createur,
                     prenom_createur,
                     mail_createur,
                     mail_user_createur,
                     item_key_da,
                     item_key_err,
                     notif_err,
                     begin_date_err,
                     flag_reaiguillage_da,
                     flag_envoi_email_createur_da
                    )
           SELECT    prha.requisition_header_id,
                     prha.segment1,
                     prha.description,
                     prha.creation_date,
                     prla.to_person_id,
                     papf2.last_name,
                     papf2.first_name,
                     papf2.attribute1,
                     papf1.employee_number,
                     papf1.last_name,
                     papf1.first_name,
                     papf1.email_address,
                     fu.email_address,
                     prha.wf_item_key,
                     wi.item_key,
                     wias_err.notification_id,
                     wias_err.begin_date,
                     'N',
                     'N'
             FROM    po_requisition_headers_all prha,
                     po_requisition_lines_all prla,
                     fnd_user fu,
                     --per_all_people_f papf1, --RBE artf2376252
                     --per_all_people_f papf2, --RBE artf2376252
                     per_people_v7 papf1, --RBE artf2376252
                     per_people_v7 papf2, --RBE artf2376252
                     wf_items wi,
                     wf_item_activity_statuses wias_err
               WHERE 1=1
                 AND prla.requisition_header_id = prha.requisition_header_id
                 AND fu.user_id = prha.created_by
                 AND papf1.person_id = fu.employee_id
                 AND papf2.person_id = prla.to_person_id
                 AND prha.authorization_status in ('IN PROCESS', 'PRE-APPROVED')
                 AND prla.line_num = 1
                 AND EXISTS (SELECT 'x'
                               FROM wf_item_activity_statuses
                              WHERE activity_status = gv_activity_status
                                AND item_key = prha.wf_item_key
                                AND item_type = prha.wf_item_type)
                 AND wi.parent_item_type = prha.wf_item_type
                 AND wi.parent_item_key = prha.wf_item_key
                 AND wias_err.item_type = wi.item_type
                 AND wias_err.item_key = wi.item_key
                 AND wias_err.activity_status = gv_activity_status_not
                 AND wi.begin_date >= trunc(SYSDATE - gn_nbre_jour)
                 ;


             IF SQL%ROWCOUNT = 0
             THEN
                 Dka_Tools_Pkg.put_outdebug_message('Aucune DA à recycler');
                 Dka_Tools_Pkg.put_outdebug_message( CHR(10));
             ELSE
                 Dka_Tools_Pkg.put_outdebug_message('Nombre de DA sélectionnées pour le déblocage : '||SQL%ROWCOUNT);
                 Dka_Tools_Pkg.put_outdebug_message( CHR(10));
             END IF;


         dka_tools_pkg.put_debug_message ('(-) Insert_dka_spowfda_errors');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode          := 2;
            pv_errbuf           := SUBSTR (('Insert_dka_spowfda_errors:' || SQLERRM), 1, 500);
    END insert_dka_spowfda_errors;

-------------------------------------------------------------------------------------
--  Nom           : maj_da
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE maj_da (
        pn_requisition_header_id     IN    NUMBER,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    )
    IS
    BEGIN

        dka_tools_pkg.put_debug_message ('(+) maj_da');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Passage de la DA a Incomplet');

        UPDATE po_requisition_headers_all
           SET authorization_status = gv_authorization_status_new
              ,last_update_date     = SYSDATE
              ,last_updated_by      = gn_user_id
         WHERE requisition_header_id = pn_requisition_header_id
           AND authorization_status  in ('IN PROCESS', 'PRE-APPROVED');

       dka_tools_pkg.put_debug_message('Mise à jour statut de la DA id : '||pn_requisition_header_id);


       dka_tools_pkg.put_debug_message ('(-) maj_da');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := 'Maj_DA : ' || SQLERRM;
    END maj_da;

-------------------------------------------------------------------------------------
--  Nom           : fermeture_notif_erreur
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE fermeture_notif_erreur (
        pn_notif_err                IN    NUMBER,
        pv_item_key_err             IN    VARCHAR2,
        pv_item_key_da              IN    VARCHAR2,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    )
    IS
    BEGIN
        dka_tools_pkg.put_debug_message ('(+) fermeture_notif_erreur');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Fermeture notification');

        -- Fermeture de la notification d'erreur
        UPDATE wf_notifications
           SET status      = gv_status_closed
              ,mail_status = NULL
              ,end_date    = SYSDATE
              ,responder   = gv_responder
        WHERE notification_id = pn_notif_err;

        dka_tools_pkg.put_debug_message('Wf_notifications - fermeture notification_id : '||pn_notif_err);


        -- Fermeture WF des erreurs
        -- Activité NOTIFIED
        UPDATE wf_item_activity_statuses
           SET activity_status      = gv_activity_status_complete
              ,activity_result_code = gv_result_code_abort
              ,end_date             = SYSDATE
         WHERE item_type       = gv_item_type_err
           AND item_key        = pv_item_key_err
           AND notification_id = pn_notif_err
           AND end_date IS NULL;

        -- Autres ativités ouvertes
        UPDATE wf_item_activity_statuses
           SET activity_status      = gv_activity_status_complete
              ,end_date             = SYSDATE
         WHERE item_type       = gv_item_type_err
           AND item_key        = pv_item_key_err
           AND end_date IS NULL;

        dka_tools_pkg.put_debug_message('WF erreur - fermeture activité : '||pv_item_key_err);


        -- Fermeture liens WF erreur - WF DA
        UPDATE wf_items
           SET end_date        = SYSDATE
         WHERE item_type       = gv_item_type_err
           AND item_key        = pv_item_key_err;

        dka_tools_pkg.put_debug_message('WF erreur - fermeture lien WF DA : '||pv_item_key_err);


        -- Fermeture du WF de la DA
        UPDATE wf_item_activity_statuses
           SET activity_status      = gv_activity_status_complete
              ,activity_result_code = gv_result_code_force
              ,end_date             = SYSDATE
         WHERE item_type       = gv_item_type_da
           AND item_key        = pv_item_key_da
           AND end_date IS NULL;


        dka_tools_pkg.put_debug_message('WF DA - fermeture activité : '||pv_item_key_da);


        dka_tools_pkg.put_debug_message ('(-) fermeture_notif_erreur');


    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := 'Fermeture_notif_erreur : ' || SQLERRM;
    END fermeture_notif_erreur;

-------------------------------------------------------------------------------------
--  Nom           : mail
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE mail (
        pv_segment1                 IN    VARCHAR2,
        pv_description              IN    VARCHAR2,
        pv_centrefinance_demandeur         IN    VARCHAR2,
        pv_adresse_mail             IN    VARCHAR2,
        pv_destinataire             IN    VARCHAR2,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    )
    IS
    crlf VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
    mesg VARCHAR2( 4000 );
    conn UTL_SMTP.CONNECTION;
    vv_sujet_mail  VARCHAR2(200);
    vv_corps_mail  VARCHAR2(2000);

    BEGIN

        dka_tools_pkg.put_debug_message ('(+) mail');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Génération du mail à adresser à '||pv_adresse_mail||' pour la DA '||pv_segment1);


        -- Récupération du sujet du mail et adaptation au contexte
        vv_sujet_mail     := Dka_Tools_Pkg.get_message ('DKA',
                                                        'DKA_SPOWFDA_ERRORS_MAIL_SUJET',
                                                        'NUM_DA',
                                                         pv_segment1,
                                                        'Centre Finance',
                                                         pv_centrefinance_demandeur,
                                                        'DESCRIPTION',
                                                         pv_description);


        -- Récupération du coprs du mail et adaptation au contexte
        vv_corps_mail     := Dka_Tools_Pkg.get_message ('DKA',
                                                        'DKA_SPOWFDA_ERRORS_MAIL_CORPS',
                                                        'NUM_DA',
                                                         pv_segment1,
                                                        'DESCRIPTION',
                                                         pv_description);

        -- Création et envoi du mail au créateur
        conn:= utl_smtp.open_connection( gv_conn, 25 );

        utl_smtp.helo( conn , gv_conn );
        utl_smtp.mail( conn , gv_expediteur );
        utl_smtp.rcpt( conn , nvl(gv_mail_test,pv_adresse_mail) );--  YWA artf2120387
        mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf ||
               'From: ' || gv_expediteur || crlf ||
               'To: ' || pv_adresse_mail || pv_destinataire|| crlf ||
               vv_sujet_mail || crlf ||
               vv_corps_mail || crlf;
        utl_smtp.data( conn , mesg );
        utl_smtp.quit( conn );

        dka_tools_pkg.put_debug_message ('(-) mail');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 1;
            pv_errbuf     := 'MAIL - ' || SQLERRM;
    END mail;

-------------------------------------------------------------------------------------
--  Nom           : deblocage_da
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------

    PROCEDURE deblocage_da (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    )
    IS
        CURSOR cur_da
        IS
            SELECT segment1,
                   requisition_header_id,
                   item_key_da,
                   item_key_err,
                   notif_err
             FROM  dka_spowfda_errors
            WHERE  flag_reaiguillage_da = 'N';

        rec_da   cur_da%ROWTYPE;
        e_error  EXCEPTION;

    BEGIN
        dka_tools_pkg.put_debug_message ('(+) deblocage_da');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Déblocage des DA');

        Dka_Tools_Pkg.put_outdebug_message('***** DEBLOCAGE DES DA *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));


        OPEN cur_da;
        FETCH cur_da INTO rec_da;
            IF (cur_da%NOTFOUND)
            THEN
                Dka_Tools_Pkg.put_outdebug_message('Aucune DA à débloquer');
                Dka_Tools_Pkg.put_outdebug_message( CHR(10));
                RETURN;
            END IF;
        CLOSE cur_da;

        OPEN cur_da;
        LOOP
        FETCH cur_da INTO rec_da;
        EXIT WHEN cur_da%NOTFOUND;

                BEGIN
                Dka_Tools_Pkg.put_debug_message ('Début déblocage DA : '||rec_da.segment1);

                -- Déblocage de la DA
                maj_da(rec_da.requisition_header_id, pv_errbuf, pn_retcode);

                IF pn_retcode != 0
                THEN

                    UPDATE dka_spowfda_errors
                       SET flag_reaiguillage_da = 'R'
                          ,message_erreur = 'MAJ DA - ' || pv_errbuf
                     WHERE requisition_header_id = rec_da.requisition_header_id
                       AND flag_reaiguillage_da = 'N';

                    pv_errbuf    := 'MAJ DA - ' || pv_errbuf;
                    RAISE e_error;
                END IF;

                -- Fermeture de la notification d'erreur lorsque la DA est débloquée
                fermeture_notif_erreur(rec_da.notif_err, rec_da.item_key_err, rec_da.item_key_da, pv_errbuf, pn_retcode);

                IF pn_retcode != 0
                THEN

                    UPDATE dka_spowfda_errors
                       SET flag_reaiguillage_da = 'R'
                          ,message_erreur = 'FERMETURE NOTIF - '||pv_errbuf
                     WHERE requisition_header_id = rec_da.requisition_header_id
                       AND flag_reaiguillage_da = 'N';

                    pv_errbuf    := 'FERMETURE NOTIF - ' || pv_errbuf;
                    RAISE e_error;
                 END IF;

                 UPDATE dka_spowfda_errors
                    SET flag_reaiguillage_da = 'Y'
                  WHERE requisition_header_id = rec_da.requisition_header_id
                    AND flag_reaiguillage_da = 'N';

                Dka_Tools_Pkg.put_outdebug_message('La DA '||rec_da.segment1 ||' a été débloquée.');

                EXCEPTION
                    WHEN e_error
                    THEN
                       pn_retcode    := 1;
                END;
        END LOOP;
        CLOSE cur_da;

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        dka_tools_pkg.put_debug_message ('(-) deblocage_da');

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'DEBLOCAGE DA - ' || SQLERRM;
            pn_retcode    := 2;
    END deblocage_da;

-------------------------------------------------------------------------------------
--  Nom           : envoi_mail
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------

    PROCEDURE envoi_mail (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    )
    IS

        CURSOR cur
        IS
            SELECT requisition_header_id,
                   segment1,
                   description,
                   centrefinance_demandeur,
                   matricule_createur,
                   nom_createur,
                   prenom_createur,
                   nvl(mail_createur, mail_user_createur) adresse_mail
             FROM  dka_spowfda_errors
            WHERE  flag_reaiguillage_da = 'Y'
              AND  flag_envoi_email_createur_da = 'N';

        rec   cur%ROWTYPE;
        e_error  EXCEPTION;
        vv_adresse_mail VARCHAR2(50);

    BEGIN

        dka_tools_pkg.put_debug_message ('(+) envoi_mail');


        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Envoi du mail au créateur');

        Dka_Tools_Pkg.put_outdebug_message('***** ENVOI MAILS D''INFORMATION AUX CREATEURS *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));


        OPEN cur;
        FETCH cur INTO rec;
            IF (cur%NOTFOUND)
            THEN
                Dka_Tools_Pkg.put_outdebug_message('Aucun mail à envoyer');
                Dka_Tools_Pkg.put_outdebug_message( CHR(10));
                RETURN;
            END IF;
        CLOSE cur;


        OPEN cur;
        LOOP
        FETCH cur INTO rec;
        EXIT WHEN cur%NOTFOUND;

                BEGIN
                Dka_Tools_Pkg.put_debug_message ('Envoi mail - Début traitement DA : '||rec.segment1);

                -- Contrôle de l'existence d'une adresse mail

                IF rec.adresse_mail IS NULL
                THEN

                    Dka_Tools_Pkg.put_outdebug_message ('DA '||rec.segment1||' EN REJET : Pas d''adresse mail pour l''employé '||rec.matricule_createur||' - '||rec.nom_createur||', '||rec.prenom_createur);

                    UPDATE dka_spowfda_errors
                       SET flag_envoi_email_createur_da = 'R'
                          ,message_erreur = 'ENVOI MAIL - Pas d''adresse mail pour l''employé '||rec.matricule_createur||' - '||rec.nom_createur||', '||rec.prenom_createur
                     WHERE requisition_header_id = rec.requisition_header_id
                       AND flag_envoi_email_createur_da = 'N';

                    RAISE e_error;


                ELSE

                    vv_adresse_mail := '<'||rec.adresse_mail ||'>';

                    -- Envoi du mail
                    mail (rec.segment1
                         ,rec.description
                         ,rec.centrefinance_demandeur
                         ,vv_adresse_mail
                         ,rec.nom_createur||' '||rec.prenom_createur
                         ,pv_errbuf
                         ,pn_retcode);

                         IF pn_retcode != 0
                         THEN

                             pv_errbuf    := 'ENVOI MAIL - ' || pv_errbuf;

                             UPDATE dka_spowfda_errors
                                SET flag_envoi_email_createur_da = 'R'
                                   ,message_erreur = pv_errbuf
                              WHERE requisition_header_id = rec.requisition_header_id
                                AND flag_envoi_email_createur_da = 'N';

                             Dka_Tools_Pkg.put_debug_message(pv_errbuf);
                             Dka_Tools_Pkg.put_outdebug_message ('DA '||rec.segment1||' EN REJET : '||pv_errbuf);

                            RAISE e_error;
                         END IF;

                     UPDATE dka_spowfda_errors
                        SET flag_envoi_email_createur_da = 'Y'
                      WHERE requisition_header_id = rec.requisition_header_id
                        AND flag_envoi_email_createur_da = 'N';

                     Dka_Tools_Pkg.put_outdebug_message ('DA '||rec.segment1||' : Mail envoyé à '||rec.adresse_mail || ' ('||rec.matricule_createur||' - '||rec.nom_createur||', '||rec.prenom_createur||')');


                 END IF;
                 EXCEPTION
                     WHEN e_error
                     THEN
                       pn_retcode    := 1;
                 END;

        END LOOP;
        CLOSE cur;

        dka_tools_pkg.put_debug_message ('(-) envoi_mail');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'ENVOI MAIL - ' || SQLERRM;
            pn_retcode    := 2;
    END envoi_mail;

--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validité
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --    pv_mail_test                Entree          Adresse mail destinataire pour test
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_mail_test IN VARCHAR2
    )
    IS
    BEGIN
        dka_tools_pkg.put_debug_message ('(+) main');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'début de la procédure principale' || CHR (10));
        
        --YWA artf2120387
        ------------------------------------
        --INITIALISATION ADRESSE MAIL TEST--
        ------------------------------------
        DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
        dka_tools_pkg.put_debug_message ('Mail de test :'||gv_mail_test);
        
        ----- Appel de la procédure INIT -----
        init (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'INIT - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_outdebug_message('**************** RECYCLAGE DES DA EN ERREUR DU '||TO_CHAR(SYSDATE-gn_nbre_jour,'DD/MM/RRRR')||' ****************');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));


        ----- Appel de la procédure d'alimentation de la table de travail dka_spowfda_errors-----
        insert_dka_spowfda_errors (pv_errbuf, pn_retcode);

        -- Déblocage des DA
        deblocage_da (pv_errbuf, pn_retcode);

        -- Envoi des mails
        envoi_mail (pv_errbuf, pn_retcode);


        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('***** FIN DU TRAITEMENT *****');

        dka_tools_pkg.put_debug_message ('(-) main');

    END main;

END DKA_SPOWFDA_ERRORS_PKG;

/

SHOW ERROR

EXIT
