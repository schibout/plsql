CREATE OR REPLACE PACKAGE BODY DKA_SRBRELBANC_CSP_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_SRBRELBANC_CSP_PKG.pkb
     -- Capgemini
     -- Nom              : DKA_SRBRELBANC_CSP_PKG.pkb
     -- Description      : Corps du package DKA_SRBRELBANC_CSP_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 25/08/2014
     -- Doc. associée    :
     -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- 2016/10/17 HDE Portage Helios 
     -- ---------- --- ------------------------------------------------------

     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     -- CONSTANTES ET VARIABLES PRIVEES
     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     cv_conc_resp_id PLS_INTEGER := fnd_global.resp_id;
     cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';

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
     --  Nom           : SRBRELBANC_ETAT_CSP
     --  Description   : Procédure de création du fichier CSV contenant les informations RB
     --          pour un Dalkia ou pour un CSP
     --  PARAMETRES    :
     --    Pv_Errbuf         Message d'erreur
     --    Pn_Retcode        Code de retour
     --    Pv_banque         Nom de la banque.
     --    Pd_start_date     Date de début.
     --    Pd_end_date       Date de fin.
     --    Pv_code_opib      Code Opération Interbancaire.
     --    Pv_nom_csp        Nom du CSP (NULL si Dalkia)
     --    Pv_file_name      Nom du fichier
     --  VALEUR RETOURNEE :
     --     Valeurs possibles : 0: deroulement correct
     --                         1: avertissement
     --                         2: deroulement avec erreur
     ------------------------------------------------------------------------------------
     PROCEDURE SRBRELBANC_ETAT_CSP(Pv_Errbuf     OUT VARCHAR2,
                                   Pn_Retcode    OUT NUMBER,
                                   Pv_banque     IN VARCHAR2,
                                   Pd_start_date IN VARCHAR2,
                                   Pd_end_date   IN VARCHAR2,
                                   Pv_code_opib  IN VARCHAR2,
								                   Pv_flag_automatisation  IN VARCHAR2,
                                   Pv_nom_csp    IN VARCHAR2,            
                                   Pn_nb_line    OUT NUMBER,
                                   Pv_file_name  OUT VARCHAR2) IS
          -- Variable d'écriture dans un fichier de sortie
          fileHandler UTL_FILE.FILE_TYPE;
          filename    varchar2(70);
     
          lv_current_program_unit VARCHAR2(30) := 'SRBRELBANC_ETAT_CSP';
     
          CURSOR CUR_SRBRELBANC_ETAT IS
           SELECT cbb.BANK_NAME,
                  cbb.BANK_BRANCH_NAME,
                  CBA.BANK_ACCOUNT_NAME,
                  CBA.IBAN_NUMBER,
                  RLA.CURRENCY_CODE,
                  RLA.LINE_TYPE,
                  RLA.BANK_TRANSACTION_CODE,
                  RLA.LINE_DATE,
                  RLA.BANK_DATE,
                  RLA.CHECK_NUMBER,
                  RLA.REFERENCE1,
                  RLA.DESCRIPTION,
                  RLA.AMOUNT,
                  RLA.REFERENCE2,
                  RLA.REFERENCE3,
                  RLA.REFERENCE4,
                  RLA.REFERENCE5,
                  RLA.REFERENCE6,
                  RLA.MATCHING_STATUS,
                  RLA.MATCHING_DATE,
                  RLA.MATCHING_REF,
                  RLA.MATCHING_TYPE,
                  RLA.MATCHING_SYSDATE,
                  RLA.FREE_COMMENT,
                  RLA.LONG_DESCRIPTION
             FROM RB_LINES_ALL         RLA
             join CE_BANK_ACCOUNTS     CBA on (RLA.BANK_ACCOUNT_ID = CBA.BANK_ACCOUNT_ID)
             join CE_BANK_BRANCHES_V   cbb on (cbb.branch_party_id = CBA.BANK_BRANCH_ID)
             join GL_CODE_COMBINATIONS GCC on (GCC.CODE_COMBINATION_ID = CBA.ASSET_CODE_COMBINATION_ID)
            WHERE CBA.BANK_ACCOUNT_ID = nvl(Pv_banque, CBA.BANK_ACCOUNT_ID)
              AND RLA.BANK_TRANSACTION_CODE = nvl(Pv_code_opib, RLA.BANK_TRANSACTION_CODE)
              AND RLA.LINE_TYPE = 'B'
              AND trunc(decode(Pv_flag_automatisation,'A', RLA.CREATION_DATE, RLA.LINE_DATE)) BETWEEN
                    trunc(nvl(fnd_date.canonical_to_date(Pd_start_date), SYSDATE)) AND trunc(nvl(fnd_date.canonical_to_date(Pd_end_date), SYSDATE))                  
              AND (Pv_nom_csp is null or 
                    EXISTS (SELECT 'X'            -- le compte bancaire appartient à la région du CSP (RG 4)
                           FROM dka_stransco_lines   dsl,
                                dka_stransco_headers dsh
                          WHERE dsh.set_id = dsl.set_id
                            AND trunc(SYSDATE) <= trunc(nvl(dsh.inactive_date, SYSDATE))
                            AND (trunc(SYSDATE) between trunc(nvl(dsl.start_date, SYSDATE)) AND trunc(nvl(dsl.end_date, SYSDATE)))
                            AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                            AND dsl.return_value = Pv_nom_csp
                            AND dsl.param2_value = gcc.segment2
                            AND dsl.enable = 'Y')
                    AND EXISTS (SELECT 'X'        -- Le compte bancaire appartient à une société gérées par les CSP
                           FROM FND_FLEX_VALUES_VL  FFV,
                                FND_FLEX_VALUE_SETS FFVS
                          WHERE FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                            AND FFVS.FLEX_VALUE_SET_NAME = 'DAOPCCF_STE'
                            AND FFV.FLEX_VALUE = gcc.segment1
                            AND FFV.ENABLED_FLAG = 'Y'
                            AND (trunc(SYSDATE) between trunc(nvl(FFV.START_DATE_ACTIVE, SYSDATE)) AND trunc(nvl(FFV.END_DATE_ACTIVE, SYSDATE)))
                            AND FFV.ATTRIBUTE16 = 'OUI')
                    AND EXISTS (SELECT 'X'        -- le transaction_code appartient à la liste autorisée pour les CSP (RG 3)
                           FROM FND_FLEX_VALUES_VL  FFV,
                                FND_FLEX_VALUE_SETS FFVS
                          WHERE FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                            AND FFVS.FLEX_VALUE_SET_NAME = 'DKA_COI_CSP'
                            AND FFV.ENABLED_FLAG = 'Y'
                            AND (trunc(SYSDATE) between trunc(nvl(FFV.START_DATE_ACTIVE, SYSDATE)) AND trunc(nvl(FFV.END_DATE_ACTIVE, SYSDATE)))
                            AND FFV.FLEX_VALUE = RLA.BANK_TRANSACTION_CODE));     
          lv_csv_line varchar2(32000);
     BEGIN
          log_msg(lv_current_program_unit ||
                  ' 000 : Initialisation du nom du fichier / nombre enregistrements.');
          filename     := 'DKA_RELEVES_BANCAIRES_' || (case when Pv_nom_csp is not null then Pv_nom_csp || '_' end) ||
                          to_char(SYSDATE, 'YYYYMMDDHHMMSS') || '.csv';
          Pv_file_name := filename;
          Pn_nb_line   := 0;
               
          log_msg(lv_current_program_unit || ' 001 : Parcours des enregistrements RB.');
          FOR REC_SRBRELBANC_ETAT in CUR_SRBRELBANC_ETAT LOOP
               Pn_nb_line := Pn_nb_line + 1;
               -- Insertion de l'entête du fichier.
               IF Pn_nb_line = 1 THEN
                    log_msg(lv_current_program_unit || ' 002 : Ouverture du fichier ' || filename || ' en mode écriture.');
                    fileHandler := utl_file.fopen(cv_directory, filename, 'w');
               
                    log_msg(lv_current_program_unit || ' 003 : Création de l''entête du fichier.');
                    out_msg('Banque;Agence;Compte;IBAN;Devise;Mvt;Opé;Date Opé.;Date Val.;Num. Règl;Ref.;Libellé;Montant;Ref. 2;Ref. 3;Ref. 4;Ref. 5;Ref. 6;Status;Date Rappro.;Ref. Rappro.;Type;Rapproché le;Commentaire;Libellé Long;');
                    utl_file.put_line(fileHandler, 'Banque;Agence;Compte;IBAN;Devise;Mvt;Opé;Date Opé.;Date Val.;Num. Règl;Ref.;Libellé;Montant;Ref. 2;Ref. 3;Ref. 4;Ref. 5;Ref. 6;Status;Date Rappro.;Ref. Rappro.;Type;Rapproché le;Commentaire;Libellé Long;');
               
                    log_msg(lv_current_program_unit || ' 004 : Insertion de ligne dans le fichier CSV.');
               END IF;
          
               lv_csv_line := REC_SRBRELBANC_ETAT.BANK_NAME || ';' || --Banque
                       REC_SRBRELBANC_ETAT.BANK_BRANCH_NAME || ';' || --Agence
                       REC_SRBRELBANC_ETAT.BANK_ACCOUNT_NAME || ';' || --Compte
                       REC_SRBRELBANC_ETAT.IBAN_NUMBER || ';' || --IBAN
                       REC_SRBRELBANC_ETAT.CURRENCY_CODE || ';' || --Devise
                       REC_SRBRELBANC_ETAT.LINE_TYPE || ';' || --Mvt
                       REC_SRBRELBANC_ETAT.BANK_TRANSACTION_CODE || ';' || --Opé
                       to_char(REC_SRBRELBANC_ETAT.LINE_DATE, 'DD/MM/YYYY') || ';' || --Date Opé.
                       to_char(REC_SRBRELBANC_ETAT.BANK_DATE, 'DD/MM/YYYY') || ';' || --Date Val.
                       REC_SRBRELBANC_ETAT.CHECK_NUMBER || ';' || --Num. Règl
                       REC_SRBRELBANC_ETAT.REFERENCE1 || ';' || --Ref.
                       REC_SRBRELBANC_ETAT.DESCRIPTION || ';' || --Libellé
                       REC_SRBRELBANC_ETAT.AMOUNT || ';' || --Montant
                       REC_SRBRELBANC_ETAT.REFERENCE2 || ';' || --Ref. 2
                       REC_SRBRELBANC_ETAT.REFERENCE3 || ';' || --Ref. 3
                       REC_SRBRELBANC_ETAT.REFERENCE4 || ';' || --Ref. 4
                       REC_SRBRELBANC_ETAT.REFERENCE5 || ';' || --Ref. 5
                       REC_SRBRELBANC_ETAT.REFERENCE6 || ';' || --Ref. 6
                       REC_SRBRELBANC_ETAT.MATCHING_STATUS || ';' || --Status
                       to_char(REC_SRBRELBANC_ETAT.MATCHING_DATE, 'DD/MM/YYYY') || ';' || --Date Rappro.
                       REC_SRBRELBANC_ETAT.MATCHING_REF || ';' || --Ref. Rappro.
                       REC_SRBRELBANC_ETAT.MATCHING_TYPE || ';' || --Type
                       to_char(REC_SRBRELBANC_ETAT.MATCHING_SYSDATE, 'DD/MM/YYYY') || ';' || --Rapproché le
                       REC_SRBRELBANC_ETAT.FREE_COMMENT || ';' || --Commentaire
                       REC_SRBRELBANC_ETAT.LONG_DESCRIPTION || ';'; --Libellé Long
          
               out_msg(lv_csv_line);
               utl_file.put_line(fileHandler, lv_csv_line);
          END LOOP;
          log_msg(lv_current_program_unit || ' 005 : nb lignes extraites : ' || Pn_nb_line);
          log_msg(lv_current_program_unit || ' 005 : Fermeture du fichier.');
          if utl_file.is_open(fileHandler) then utl_file.fclose(fileHandler); end if;
          log_msg(lv_current_program_unit || ' 999 : Fin Normale.');
     EXCEPTION
          WHEN OTHERS THEN
               if utl_file.is_open(fileHandler) then utl_file.fclose(fileHandler); end if;
               log_msg(lv_current_program_unit || ' 999 : Fin Erronée.');
               Pv_Errbuf  := 'Erreur lors de l''exécution de la procédure SRBRELBANC_ETAT_CSP ' || Substr(SQLERRM, 1, 80);
               Pn_Retcode := 2;
     END SRBRELBANC_ETAT_CSP;

     ------------------------------------------------------------------------------------
     --  Nom           : ENVOI_MAIL
     --  Description   : Procédure d'envoi par mail des fichiers RB
     --
     --  PARAMETRES    :
     --      Pv_Errbuf         Message d'erreur
     --      Pn_Retcode        Code de retour
     --  VALEUR RETOURNEE :
     --     Valeurs possibles : 0: deroulement correct
     --                         1: avertissement
     --                         2: deroulement avec erreur
     ------------------------------------------------------------------------------------
     PROCEDURE ENVOI_MAIL(Pv_Errbuf     OUT VARCHAR2,
                          Pn_Retcode    OUT NUMBER,
                          Pd_start_date IN VARCHAR2,
                          Pd_end_date   IN VARCHAR2,
                          Pv_file_name  IN VARCHAR2) IS
     
          lv_current_program_unit VARCHAR2(30) := 'ENVOI_MAIL';
          vv_jdv_destinataire     VARCHAR2(2000);
          vv_objet                VARCHAR2(200);
          vv_corps                VARCHAR2(500);
          vv_exped                VARCHAR2(200);
          rec_param               dka_parameters%ROWTYPE;
          vv_conn                 VARCHAR2(50);
          vv_retour_mail          VARCHAR2(50);
          vv_responsibility_name  FND_RESPONSIBILITY_TL.RESPONSIBILITY_NAME%TYPE;
     BEGIN
          -- Recherche de la connexion :
          log_msg(lv_current_program_unit ||
                  ' 001 : Récuperation des paramètres de connexion');
          Dka_Tools_Pkg.get_parameter('DKA_SRBRELBANC', 'SMTP_CONNECTION', rec_param, Pv_Errbuf, Pn_Retcode);
          vv_conn := rec_param.varchar2_value;
          log_msg(lv_current_program_unit ||
                  ' 001 : Récuperation des paramètres de connexion : ' ||
                  vv_conn);
     
          -- Recherche de l'expéditeur du mail :
          log_msg(lv_current_program_unit ||
                  ' 002 : Récuperation de l''expéditeur');
          Dka_Tools_Pkg.get_parameter('DKA_SRBRELBANC', 'EXPEDITEUR_MAIL', rec_param, Pv_Errbuf, Pn_Retcode);
          vv_exped := rec_param.varchar2_value;
          log_msg(lv_current_program_unit ||
                  ' 002 : Récuperation de l''expéditeur : ' || vv_exped);
     
          -- Recherche de l'adresse mail retour pour cause de non réception :
          log_msg(lv_current_program_unit ||
                  ' 003 : Récuperation du mail de non réception.');
          Dka_Tools_Pkg.get_parameter('DKA_SRBRELBANC', 'RETOUR_MAIL', rec_param, Pv_Errbuf, Pn_Retcode);
          vv_retour_mail := rec_param.varchar2_value;
          log_msg(lv_current_program_unit ||
                  ' 003 : Récuperation du mail de non réception : ' ||
                  vv_retour_mail);
     
          -- Recherche des adresses de destination :
          log_msg(lv_current_program_unit ||
                  ' 004 : Récuperation le jeu de valeur des adresses mails de destination');
          vv_jdv_destinataire := 'DKA_RELEVE_BANCAIRE_MAIL';
          log_msg(lv_current_program_unit ||
                  ' 004 : Récuperation le jeu de valeur des adresses mails de destination : ' ||
                  vv_jdv_destinataire);
     
          -- Recherche de l'objet du mail :
          log_msg(lv_current_program_unit ||
                  ' 005 : Récuperation l''objet du mail');
          vv_objet := Dka_Tools_Pkg.get_message('DKA', 'DKA_SRBRELBANC_OBJET', 'DATE_SYS', to_char(SYSDATE, 'dd/mm/yyyy'));
          log_msg(lv_current_program_unit ||
                  ' 005 : Récuperation l''objet du mail : ' || vv_objet);
     
          -- Recherche du corps du mail :
          log_msg(lv_current_program_unit ||
                  ' 006 : Récuperation le corps du mail');
          vv_corps := Dka_Tools_Pkg.get_message('DKA', 'DKA_SRBRELBANC_CORP', 'DATE_DEB', substr(Pd_start_date, 9, 2) || '/' ||
                                                 substr(Pd_start_date, 6, 2) || '/' ||
                                                 substr(Pd_start_date, 1, 4), 'DATE_FIN', substr(Pd_end_date, 9, 2) || '/' ||
                                                 substr(Pd_end_date, 6, 2) || '/' ||
                                                 substr(Pd_end_date, 1, 4));
          log_msg(lv_current_program_unit ||
                  ' 006 : Récuperation le corps du mail : ' || vv_corps);
     
          -- Recherche du nom de la responsabilité de lancement du traitement:
          log_msg(lv_current_program_unit ||
                  ' 007 : Recherche du nom de la responsabilité.');
          vv_responsibility_name := NULL;
     
          BEGIN
               SELECT FR.RESPONSIBILITY_NAME
                 INTO vv_responsibility_name
                 FROM FND_RESPONSIBILITY_TL FR
                WHERE FR.RESPONSIBILITY_ID = CV_CONC_RESP_ID
                  AND FR.LANGUAGE = 'F';
          EXCEPTION
               WHEN OTHERS THEN
                    vv_responsibility_name := NULL;
          END;
          log_msg(lv_current_program_unit ||
                  ' 007 : Recherche du nom de la responsabilité : ' ||
                  vv_responsibility_name);
     
          log_msg(lv_current_program_unit || ' 008 : Envoi d''un mail');
          -- Envoi du mail d'avertissement :
          DKA_SEND_MAIL_PKG.Send_Mail(Pv_Errbuf => Pv_Errbuf, Pn_Retcode => Pn_Retcode, Pv_connexion => vv_conn, --Connexion
                                      Pv_expediteur => vv_exped, --Expéditeur
                                      Pv_retour_mail => vv_retour_mail, --Mail de retour
                                      Pv_liste_destinataire => vv_jdv_destinataire, --JDV des destinataires
                                      Pv_message_subject => vv_objet, --Texte à mettre en objet
                                      Pv_message_corps => vv_corps, --Texte à mettre dans le corps
                                      Pv_directory => 'DKA_OUT_DIR', --Nom de a directory à utiliser pour ajouter les fichiers joints
                                      Pv_liste_fichier => Pv_file_name, --Liste des fichiers séparés par des '/'
                                      Pv_JDV_Attribute1 => vv_responsibility_name --CUF du JDV des destinataires
                                      );
          log_msg(lv_current_program_unit || ' 999 : Fin Normale.');
     EXCEPTION
          WHEN OTHERS THEN
               Pn_Retcode := 2;
               Pv_Errbuf  := SQLERRM || ' Erreur : Procédure ENVOI_MAIL.';
               log_msg(Pv_Errbuf);
     END ENVOI_MAIL;

     -----------------------------------------------------------------
     procedure check_setup
     is 
     begin
       -- directories
       dka_tools_pkg.check_directory(cv_directory);     
       
       -- Transco
       dka_tools_pkg.check_transco('CENTRE_SERVICE_PARTAGE');
       dka_tools_pkg.check_transco('DKA_CSP_RESP');
       
       -- Jeux de valeurs
       dka_tools_pkg.check_value_set('DAOPCCF_STE');
       dka_tools_pkg.check_value_set('DKA_COI_CSP');
       dka_tools_pkg.check_value_set('DKA_RELEVE_BANCAIRE_MAIL');
              
       -- Paramètres Dalkia
       dka_tools_pkg.check_parameter('DKA_SRBRELBANC', 'SMTP_CONNECTION');
       dka_tools_pkg.check_parameter('DKA_SRBRELBANC', 'EXPEDITEUR_MAIL');
       dka_tools_pkg.check_parameter('DKA_SRBRELBANC', 'RETOUR_MAIL');
       
       -- messages
       dka_tools_pkg.check_message('DKA', 'DKA_SRBRELBANC_OBJET');
       dka_tools_pkg.check_message('DKA', 'DKA_SRBRELBANC_CORP');
       
       
       -- Segments de CUF
       dka_tools_pkg.check_flex_segment('FND', 'FND_FLEX_VALUES', 'DAOPCCF_STE', null, 'ATTRIBUTE16');      
          
     end check_setup;
     

     -----------------------------------------------------------------
     --  NOM           : main
     --  DESCRIPTION   : Procédure principale du traitement
     --
     --  PARAMETRES   : pv_retcode            code retour out
     --                 pn_errbuf             description de l'erreur out
     --          pv_banque          Nom de la banque.
     --          pd_start_date      Date de début.
     --          pd_end_date      Date de fin.
     --          pv_code_opib      Code Opération Interbancaire.
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf     OUT VARCHAR2,
                    pn_retcode    OUT NUMBER,
                    pv_banque     IN VARCHAR2,
                    pd_start_date IN VARCHAR2,
                    pd_end_date   IN VARCHAR2,
                    pv_code_opib  IN VARCHAR2,
					pv_flag_automatisation	IN VARCHAR2) IS
          e_main EXCEPTION;
          lv_current_program_unit VARCHAR2(30) := 'main';
          vv_nom_csp              dka_stransco_lines.params_value%TYPE;
          vn_nb_line              NUMBER;
          vv_file_name            VARCHAR2(70);
     BEGIN
          log_msg(lv_current_program_unit || ' 000 : Vérification du paramétrage.');
          check_setup;
          log_msg(lv_current_program_unit || ' 000 : cv_conc_resp_id = ' || cv_conc_resp_id); 
          log_msg(lv_current_program_unit || ' 000 : Pd_start_date = ' || Pd_start_date);
          log_msg(lv_current_program_unit || ' 000 : Pd_end_date = ' || Pd_end_date);   
          log_msg(lv_current_program_unit || ' 000 : Pv_code_opib = ' || Pv_code_opib);
          log_msg(lv_current_program_unit || ' 000 : Pv_flag_automatisation = ' || pv_flag_automatisation);
          
          log_msg(lv_current_program_unit ||
                  ' 000 : Initialisation Variable.');
          vn_nb_line := 0;
          BEGIN
               SELECT dsl.params_value
                 INTO vv_nom_csp
                 FROM dka_stransco_lines dsl, dka_stransco_headers dsh
                WHERE dsh.set_id = dsl.set_id
                  AND trunc(SYSDATE) <=
                      trunc(nvl(dsh.inactive_date, SYSDATE))
                  AND (trunc(SYSDATE) between trunc(dsl.start_date) AND
                      trunc(nvl(dsl.end_date, SYSDATE)))
                  AND dsh.set_name = 'DKA_CSP_RESP'
                  AND dsl.return_value = cv_conc_resp_id
                  AND dsl.enable = 'Y';
          EXCEPTION
               WHEN OTHERS THEN
                    pv_errbuf  := lv_current_program_unit ||
                                  ' 000 : Impossible de déterminer le nom du csp de la responsabilité.' ||
                                  cv_conc_resp_id;
                    vv_nom_csp := NULL;
          END;
          log_msg(lv_current_program_unit || ' 000 : vv_nom_csp = ' || vv_nom_csp);                          
     
          log_msg(lv_current_program_unit || ' 001 : Création du fichier.');
          log_msg(lv_current_program_unit || ' 002 : Création du fichier pour ' || (case vv_nom_csp when null then 'DALKIA' else 'le CSP ' || vv_nom_csp end) || '.');
          SRBRELBANC_ETAT_CSP(
             Pv_Errbuf              => pv_errbuf, 
             Pn_Retcode             => pn_retcode,
             Pv_banque              => pv_banque,
             Pd_start_date          => pd_start_date,
             Pd_end_date            => pd_end_date,
             Pv_code_opib           => pv_code_opib,
             Pv_flag_automatisation => pv_flag_automatisation,
             Pv_nom_csp             => vv_nom_csp,
             Pn_nb_line             => vn_nb_line,
             Pv_file_name           => vv_file_name);
             
          IF pn_retcode != 0 THEN
               log_msg(lv_current_program_unit ||
                       ' 002 : Erreur lors de la création du fichier.');
               RAISE e_main;
          END IF;
     
          IF vn_nb_line > 0 THEN
               log_msg(lv_current_program_unit ||
                       ' 003 : Envoi du fichier par mail.');
               ENVOI_MAIL(pv_errbuf, pn_retcode, pd_start_date, pd_end_date, vv_file_name);
          ELSE
               log_msg(lv_current_program_unit ||
                       ' 003 : Pas d''envoi de mail car aucun fichier existant.');
              pn_retcode := 1;
          END IF;
     
          log_msg(lv_current_program_unit || ' 999 : Fin normale.');
     EXCEPTION
          WHEN e_main THEN
               pn_retcode := 2;
               log_msg(pv_errbuf);
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := SQLERRM || ' Erreur : Procédure main.';
               log_msg(pv_errbuf);
     END main;
END DKA_SRBRELBANC_CSP_PKG;
/

show errors 
exit;