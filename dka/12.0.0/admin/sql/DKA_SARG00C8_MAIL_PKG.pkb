--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SARG00C8_MAIL_PKG
-- Description      : Body du package DKA_SARG00C8_MAIL_PKG
-- Auteur           : B.Coudrier
-- Date de création : 25/04/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS 
--------------------------------------------------------------------------------
-- Modifications
--------------------------------------------------------------------------------
-- Auteur           : Oussama BENHAYOUN
-- Date de modif    : 19/12/2017
-- Commentaires     : artf2294060 - SPE076 - Anomalie - Defect Beb #1139
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY DKA_SARG00C8_MAIL_PKG AS
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -----------------------------------------------------------------
    --  Nom           : OUT_MSG
    --  Description   : procedure d'affichage des messages
    --
    --  PARAMETRES :
    --   p_message          texte a imprimer dans la sortie
    --
    -----------------------------------------------------------------
    PROCEDURE out_msg(p_message in varchar2) IS
    BEGIN
        -- Ecriture dans le fichier de sortie
        fnd_file.put_line(fnd_file.output, p_message);
    END out_msg;

    -----------------------------------------------------------------
    --  Nom           : LOG_MSG
    --  Description   : procedure d'affichage des messages
    --
    --  PARAMETRES :
    --   p_message      texte a imprimer dans le log
    --
    -----------------------------------------------------------------
    PROCEDURE log_msg(p_message in varchar2) IS
        l_message VARCHAR2(1000);
    BEGIN

        l_message := SUBSTR(p_message, 1, 1000);

        IF (l_message IS NULL) THEN
            l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG, l_message);
    END log_msg;
	
    ------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf         OUT VARCHAR2,
                   Pn_Retcode        OUT NUMBER)/*,
				   P_Set_Of_Books_Id IN	 VARCHAR2)*/ IS
    
        vv_jdv_destinataire VARCHAR2(2000);
        vv_objet           VARCHAR2(200);
        vv_corps            VARCHAR2(500);
        vv_exped            VARCHAR2(200);
        rec_param           dka_parameters%ROWTYPE;
        vv_conn             VARCHAR2(50);
        vv_directory        VARCHAR2(50);
		vn_size_ec			NUMBER;
		vn_size_er			NUMBER;
		vv_fichier_ec		VARCHAR2(50);
		vv_fichier_new_ec	VARCHAR2(50);
		vv_fichier_er		VARCHAR2(50);
		vv_fichier_new_er	VARCHAR2(50);
		vv_fichier          VARCHAR2(500);
		vv_step				VARCHAR2(2000);
		vv_argument2		VARCHAR2(240);
		vv_argument3		VARCHAR2(240);
    BEGIN
        -- Recherche de la connexion :
        vv_step := 'ERROR 001 : Récuperation des paramètres de connexion';
        log_msg(vv_step);
        Dka_Tools_Pkg.get_parameter('DKA_SARG00C8',
                                    'SMTP_CONNECTION',--
                                    rec_param,
                                    Pv_Errbuf,
                                    Pn_Retcode);
        vv_conn := rec_param.varchar2_value;
        vv_step := 'ERROR 001 : Récuperation des paramètres de connexion : ' ||
                   vv_conn;
        log_msg(vv_step);
    
        -- Recherche de l'expéditeur du mail :
        vv_step := 'ERROR 002 : Récuperation de l''expéditeur';
        log_msg(vv_step);
        Dka_Tools_Pkg.get_parameter('DKA_SARG00C8',
                                    'EXPEDITEUR_MAIL',--
                                    rec_param,
                                    Pv_Errbuf,
                                    Pn_Retcode);
        vv_exped := rec_param.varchar2_value;
        vv_step  := 'ERROR 002 : Récuperation de l''expéditeur : ' ||
                    vv_exped;
        log_msg(vv_step);
    
        -- Recherche des adresses de destination :
        vv_step := 'ERROR 003 : Récuperation le jeu de valeur des adresses mails de destination';
        log_msg(vv_step);
        vv_jdv_destinataire := 'DKA_SARG00C8_MAIL';--
        vv_step             := 'ERROR 003 : Récuperation le jeu de valeur des adresses mails de destination : ' ||
                               vv_jdv_destinataire;
        log_msg(vv_step);
    
        -- Recherche de l'objet du mail :
        vv_step := 'ERROR 004 : Récuperation l''objet du mail';
        log_msg(vv_step);
        vv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SARG00C8_OBJET',
                                              'DATE_SYS',
                                              to_char(SYSDATE,'dd/mm/yyyy'));
        vv_step  := 'ERROR 004 : Récuperation l''objet du mail : ' ||
                    vv_objet;
        log_msg(vv_step);
    
        -- Recherche du corps du mail :
        vv_step := 'ERROR 005 : Récuperation le corps du mail';
        log_msg(vv_step);
        vv_corps := Dka_Tools_Pkg.get_message('DKA', 'DKA_SARG00C8_CORP');
        vv_step  := 'ERROR 005 : Récuperation le corps du mail : ' ||
                    vv_corps;
        log_msg(vv_step);
    
        -- Recherche le nom du fichier - Etat de comparaison :
        vv_step := 'ERROR 006 : Récuperation le nom du fichier - Etat de comparaison';
        log_msg(vv_step);
        BEGIN
            select SUBSTR(fcr.outfile_name,
                          INSTR(fcr.outfile_name, '/', -1, 1) + 1), fcr.ofile_size, fcr.argument1 /*fcr.argument2*/ -- OBE artf2294060
              into vv_fichier_ec, vn_size_ec, vv_argument2
              from fnd_concurrent_programs fcp,
                   fnd_concurrent_requests fcr
             where fcp.concurrent_program_name = 'DKA_SARG00C8_ETAT'
               and fcr.concurrent_program_id = fcp.concurrent_program_id
			   --and fcr.argument1 = P_Set_Of_Books_Id
               and fcr.request_id =
                   (SELECT MAX(fcr2.request_id)
                      from fnd_concurrent_requests fcr2
                     where fcr2.concurrent_program_id =
                           fcr.concurrent_program_id)
               and trunc(fcr.request_date) = trunc(SYSDATE);
        EXCEPTION
            WHEN OTHERS THEN
                vv_fichier_ec 	:= NULL;
				vn_size_ec		:= 0;
				pn_retcode 		:= 1;
        END;
        vv_step := 'ERROR 006 : Récuperation le nom du fichier - Etat de comparaison : ' ||
                   vv_fichier_ec;
        log_msg(vv_step);
    
        -- Recherche le nom du fichier - Etat de rattrapage :
        /*vv_step := 'ERROR 006 : Récuperation le nom du fichier - Etat de rattrapage';
        log_msg(vv_step);
        BEGIN
            select SUBSTR(fcr.outfile_name,
                          INSTR(fcr.outfile_name, '/', -1, 1) + 1), fcr.ofile_size, fcr.argument2, fcr.argument3
              into vv_fichier_er, vn_size_er, vv_argument2, vv_argument3
              from fnd_concurrent_programs fcp,
                   fnd_concurrent_requests fcr
             where fcp.concurrent_program_name = 'DKA_SARG00C8_RATT'
               and fcr.concurrent_program_id = fcp.concurrent_program_id
			   and fcr.argument1 = P_Set_Of_Books_Id
               and fcr.request_id =
                   (SELECT MAX(fcr2.request_id)
                      from fnd_concurrent_requests fcr2
                     where fcr2.concurrent_program_id =
                           fcr.concurrent_program_id)
               and trunc(fcr.request_date) = trunc(SYSDATE);
        EXCEPTION
            WHEN OTHERS THEN
                vv_fichier_er 	:= NULL;
				vn_size_er		:= 0;
				pn_retcode 		:= 1;
        END;
        vv_step := 'ERROR 006 : Récuperation le nom du fichier - Etat de rattrapage : ' ||
                   vv_fichier_er;
        log_msg(vv_step);*/
    
        -- Recherche de la directory :
        vv_step := 'ERROR 007 : Récuperation de la directory';
        log_msg(vv_step);
		vv_directory	:=	'DKA_SARG00C8_OUTMAIL';
        vv_step := 'ERROR 007 : Récuperation de la directory : ' ||
                   vv_corps;
        log_msg(vv_step);
		
		-- Modification des noms de fichiers et copie des fichiers dans la directory :
		vv_step := 'ERROR 008 : Concaténation des noms de fichiers s''ils ne sont pas vide';
        log_msg(vv_step);
		vv_fichier := NULL;
		IF vn_size_ec > 0 THEN
			vv_step := 'ERROR 009.a : Copie et Renommage du fichier - Etat de comparaison.';
			log_msg(vv_step);
			vv_fichier_new_ec	:=	'Etat_Comparaison_CID_' || vv_argument2 || '.csv';
            BEGIN
                UTL_FILE.FCOPY('DKA_SARG00C8_MAIL',
                               vv_fichier_ec,
                               'DKA_SARG00C8_OUTMAIL',
                               vv_fichier_new_ec,
                               1,
                               NULL);
            EXCEPTION
                WHEN OTHERS THEN
                    vv_step := 'MAIN 009.a - ERREUR LORS DE LA COPIE DU FICHIER CSV - ETAT DE COMPARAISON.';
                    log_msg(vv_step);
            END;
			vv_fichier := vv_fichier_new_ec;
			vv_step := 'ERROR 009.a : Copie et Renommage du fichier - Etat de comparaison : ' || vv_fichier_new_ec;
			log_msg(vv_step);
		END IF;
		
		/*IF vn_size_er > 600 AND vn_size_ec > 600 THEN
			vv_step := 'ERROR 009.b : Copie et Renommage du fichier - Etat de rattrapage.';
			log_msg(vv_step);
			vv_fichier_new_er	:=	'Etat_Rattrapage_CID_' || vv_argument2 || '_au_' || vv_argument3 || '.csv';
            BEGIN
                UTL_FILE.FCOPY('DKA_SARG00C8_MAIL',
                               vv_fichier_er,
                               'DKA_SARG00C8_OUTMAIL',
                               vv_fichier_new_er,
                               1,
                               NULL);
            EXCEPTION
                WHEN OTHERS THEN
                    vv_step := 'MAIN 009.b - ERREUR LORS DE LA COPIE DU FICHIER CSV - ETAT DE RATTRAPAGE.';
                    log_msg(vv_step);
            END;
			vv_fichier := vv_fichier || '/' || vv_fichier_new_er;
			vv_step := 'ERROR 009.b : Copie et Renommage du fichier - Etat de rattrapage : ' || vv_fichier_new_er;
			log_msg(vv_step);
		ELSIF vn_size_er > 600 THEN
			vv_step := 'ERROR 009.b : Copie et Renommage du fichier - Etat de rattrapage.';
			log_msg(vv_step);
			vv_fichier_new_er	:=	'Etat_Rattrapage_CID_' || vv_argument2 || '_au_' || vv_argument3 || '.csv';
            BEGIN
                UTL_FILE.FCOPY('DKA_SARG00C8_MAIL',
                               vv_fichier_er,
                               'DKA_SARG00C8_OUTMAIL',
                               vv_fichier_new_er,
                               1,
                               NULL);
            EXCEPTION
                WHEN OTHERS THEN
                    vv_step := 'MAIN 009.b - ERREUR LORS DE LA COPIE DU FICHIER CSV - ETAT DE RATTRAPAGE.';
                    log_msg(vv_step);
            END;
			vv_fichier := vv_fichier_new_er;
			vv_step := 'ERROR 009.b : Copie et Renommage du fichier - Etat de rattrapage : ' || vv_fichier_new_er;
			log_msg(vv_step);
		END IF;*/

		
		IF vv_fichier IS NOT NULL THEN
		vv_step := 'ERROR 009 : Envoi d''un mail';
		log_msg(vv_step);
        -- Envoi du mail d'avertissement :
        DKA_SEND_MAIL_PKG.Send_Mail(Pv_Errbuf             => Pv_Errbuf,
                                    Pn_Retcode            => Pn_Retcode,
                                    Pv_connexion          => vv_conn, --Connexion
                                    Pv_expediteur         => vv_exped, --Expéditeur
                                    Pv_retour_mail        => NULL, --Mail de retour
                                    Pv_liste_destinataire => vv_jdv_destinataire, --JDV des destinataires
                                    Pv_message_subject    => vv_objet, --Texte à mettre en objet
                                    Pv_message_corps      => vv_corps, --Texte à mettre dans le corps
                                    Pv_directory          => vv_directory, --Nom de a directory à utiliser pour ajouter les fichiers joints
                                    Pv_liste_fichier      => vv_fichier --Liste des fichiers séparés par des '/'
                                    );
		ELSE
		vv_step := 'ERROR 009 : Pas d''envoi de mail';
		log_msg(vv_step);
		END IF;
    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur lors de l''exécution de la procédure principale ' ||
                          Substr(SQLERRM, 1, 80);
            Pn_Retcode := 2;
    END;

END DKA_SARG00C8_MAIL_PKG;
/

SHOW ERRORS PACKAGE BODY DKA_SARG00C8_MAIL_PKG;
EXIT
