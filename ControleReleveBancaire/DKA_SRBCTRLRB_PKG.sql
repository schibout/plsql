create or replace PACKAGE BODY DKA_SRBCTRLRB_PKG AS
-------------------------------------------------------------------------------------
-- $Id: DKA_SRBCTRLRB_PKG.pkb $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_SRBCTRLRB_PKG.pkb
-- DESCRIPTION       : DKA_SRBCTRLRB_PKG package body
---
--- AUTEUR           : Florent Peenaert
--- DATE DE CREATION : 27/03/2015
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 08/11/2016 RBE Migration R12
--- 12/04/2018 RBE artf2523214 : INC0208697 : contrôle relevé bancaire
------------------------------------------------------------------------------------


  --CONSTANTE
  cv_package_name      CONSTANT VARCHAR2(30)  := 'DKA_SRBCTRLRB_PKG';
  cv_fsep              CONSTANT VARCHAR2(1)   := ';';

  --CONSTANTE JEU DE VALEUR, TRANSCO ....

  cv_directory         CONSTANT VARCHAR2(30)  := 'DKA_OUT_DIR';
  cv_extension         CONSTANT VARCHAR2(10)  := '.csv';
  cv_line              CONSTANT VARCHAR2(75)  := '+-------------------------------------------------------------------------+';

  --VARIABLE GLOBALES

  gv_step             VARCHAR2(500);
  gv_file_name        VARCHAR2(100);

  --PARAMETRES
  gd_date_reference   DATE;



  -----------------------------------------------------------------------
  -- GET_TIME
  ----------------------------------------------------------------------
  --  fonction qui retourne la date et l'heure actuelle
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(sysdate,'dd/mm/rrrr HH24:MI:SS');
  END get_time;

  -----------------------------------------------------------------
  --  Nom           : get_parameters
  --  Description   : procedure de récupération des paramètres
  --
  --  PARAMETRES :
  --   pv_errbuf       IN OUT NOCOPY VARCHAR2,
  --   pn_retcode      IN OUT NOCOPY NUMBER
  --   pv_date_test    IN            VARCHAR2
  -----------------------------------------------------------------
  PROCEDURE get_parameters(pv_errbuf       IN OUT NOCOPY VARCHAR2,
                           pn_retcode      IN OUT NOCOPY NUMBER,
                           pv_date_test    IN         VARCHAR2) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_parameters';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    dka_tools_pkg.put_debug_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : Affectations aux variables globales';
    dka_tools_pkg.put_debug_message(gv_step);
    -- on prend le jour précédent dès le départ
    gd_date_reference   := fnd_date.canonical_to_date(pv_date_test)-1;

    gv_step  := lv_current_program_unit||' 002 : FIN';
    dka_tools_pkg.put_debug_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE2 : ERREUR lors de :'||gv_step;
    dka_tools_pkg.put_log_message(gv_step);
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    dka_tools_pkg.put_log_message(pv_errbuf);
    pn_retcode := 2;
  END get_parameters;

    -----------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : procédure d'envoi de mail avec pièce jointe
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  --   vb_boucle        IN         BOOLEAN
  -----------------------------------------------------------------

  PROCEDURE SEND_MSG(Pv_Errbuf  IN OUT NOCOPY VARCHAR2,
                     Pn_Retcode IN OUT NOCOPY VARCHAR2,
                     pb_boucle  IN            BOOLEAN ) IS

        lv_current_program_unit  VARCHAR2(30) := 'SEND_MSG';

        Vv_Message_Erreur               VARCHAR2(250);
        vv_fichier                      VARCHAR2(100);
        vv_conn                         VARCHAR2(500);
        vv_exped                        VARCHAR2(200);
        vv_objet                        VARCHAR2(200);
        vv_corps                        VARCHAR2(500);
        rec_param                       dka_parameters%ROWTYPE;


       BEGIN
         gv_step  := lv_current_program_unit||' 000 : DEBUT';

         Pv_Errbuf     := NULL;
         Pn_Retcode    := 0;
         vv_fichier := gv_file_name;

          --Connexion
          gv_step  := lv_current_program_unit||' 001 : Récupération des paramètres de connexion';
          Dka_Tools_Pkg.Put_Debug_Message(gv_step);
          Dka_Tools_Pkg.get_parameter ('DKA_SRBCTRLRB', 'SMTP_CONNECTION', rec_param, Pv_Errbuf, Pn_Retcode);
          vv_conn := rec_param.varchar2_value;


          --Expéditeur
          gv_step  := lv_current_program_unit||' 002 : Récupération de l''expéditeur';
          Dka_Tools_Pkg.Put_Debug_Message(gv_step);
          Dka_Tools_Pkg.get_parameter ('DKA_SRBCTRLRB', 'EXPEDITEUR_MAIL', rec_param, Pv_Errbuf, Pn_Retcode);
          vv_exped := rec_param.varchar2_value;



        -- Si il y a des relevés manquants on envoie un mail KO sinon on envoie un mail RAS
        IF  pb_boucle
           THEN

            gv_step  := 'récupération de l''objet et du corps correspondant';
            Dka_Tools_Pkg.Put_Debug_Message(gv_step);
            --Objet
            Fnd_Message.Set_Name('DKA', 'DKA_SRBCTRLRB_OBJ_KO');
            Fnd_Message.SET_TOKEN('DATE',to_char(gd_date_reference,'dd/mm/rrrr'));
            vv_objet := Fnd_Message.Get;
            --Corps
            Fnd_Message.Set_Name('DKA', 'DKA_SRBCTRLRB_COR_KO');
            vv_corps := Fnd_Message.Get;
            gv_step  := 'récupération terminée';
            Dka_Tools_Pkg.Put_Debug_Message(gv_step);

           ELSE
            gv_step  := 'récupération de l''objet et du corps correspondant';
            Dka_Tools_Pkg.Put_Debug_Message(gv_step);
             --Objet
            Fnd_Message.Set_Name('DKA', 'DKA_SRBCTRLRB_OBJ_RAS');
            Fnd_Message.SET_TOKEN('DATE',to_char(gd_date_reference,'dd/mm/rrrr'));
            vv_objet := Fnd_Message.Get;
             --Corps
            Fnd_Message.Set_Name('DKA', 'DKA_SRBCTRLRB_COR_RAS');
            Fnd_Message.SET_TOKEN('DATE',to_char(gd_date_reference,'dd/mm/rrrr'));
            vv_corps := Fnd_Message.Get;
            vv_fichier := NULL;
            gv_step  := 'récupération terminée :'||vv_exped;Dka_Tools_Pkg.Put_Debug_Message(gv_step);
        END IF;

        gv_step  := 'appel de la procédure d''envoi de mail';
        Dka_Tools_Pkg.Put_Debug_Message(gv_step);
        DKA_SEND_MAIL_PKG.Send_Mail(Pv_Errbuf             => Pv_Errbuf,
                                    Pn_Retcode            => Pn_Retcode,
                                    Pv_connexion          => vv_conn,                --Connexion
                                    Pv_expediteur         => vv_exped,               --Expéditeur
                                    Pv_retour_mail        => NULL,                   --Mail de retour
                                    Pv_liste_destinataire => 'DKA_SRBCTRLRB_LD',     --JDV des destinataires
                                    Pv_message_subject    => vv_objet,               --Texte à mettre en objet
                                    Pv_message_corps      => vv_corps,               --Texte à mettre dans le corps
                                    Pv_directory          => cv_directory,           --Nom de a directory à utiliser pour ajouter les fichiers joints
                                    Pv_liste_fichier      => vv_fichier              --Liste des fichiers séparés par des '/'
                                    );

    gv_step  := lv_current_program_unit||' 999 : FIN';

  EXCEPTION
    WHEN OTHERS THEN
      gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END SEND_MSG;

  -----------------------------------------------------------------
  --  Nom           : CONTROL_BANK_STATEMENT
  --  Description   : procédure de contrôle des relevés bancaires et d'écriture dans un fichier
  --
  --  PARAMETRES :
  --   pv_errbuf      IN  OUT NOCOPY VARCHAR2,
  --   pn_retcode     IN  OUT NOCOPY NUMBER
  --   pb_boucle      IN  OUT        BOOLEAN
  -----------------------------------------------------------------
  PROCEDURE CONTROL_BANK_STATEMENT(
                    Pv_Errbuf  IN OUT NOCOPY VARCHAR2,
                    Pn_Retcode IN OUT NOCOPY NUMBER,
                    pb_boucle     OUT        BOOLEAN) IS
        --variables

        vv_fichier               VARCHAR2(100);
        vf_fichier               utl_file.file_type;
        Erreur_Traitement        EXCEPTION;
        Vv_Ligne                 VARCHAR2(32000);
        vb_boucle                BOOLEAN;
        lv_current_program_unit  VARCHAR2(30) := 'CONTROL_BANK_STATEMENT';

        ------------------------------------------------
        -- Curseur de lecture des releves  --
        ------------------------------------------------
        CURSOR Cur_Releve IS
            /* --RBE MigR12
            SELECT Id,
                   Nom_Banque,
                   Banque,
                   Guichet,
                   Compte,
                   Nom_Compte,
                   Rappro,
                   Cpt_51,
                   Last_Import,
                   Anc_Date,
                   Nouv_Date,
                   Anc_Solde,
                   Nouv_Solde
            FROM(
              SELECT rbaa.bank_account_id Id,
                     abb.bank_name Nom_Banque,
                     abb.bank_number Banque,
                     abb.bank_num Guichet,
                     abaa.bank_account_num Compte,
                     abaa.bank_account_name Nom_Compte,
                     rbaa.status Rappro,
                     gcc.segment3 Cpt_51,
                     rbi.import_date Last_Import,
                     rbi.old_amount Anc_Solde,
                     rbi.new_amount Nouv_Solde,
                     rbi.batch_start_date Anc_Date,
                     rbi.batch_end_date Nouv_Date,
                     row_number() over (partition by rbi.bank_account_id order by rbi.batch_end_date desc) rn
                FROM rb_bank_accounts_all rbaa,
                     rb_batch_import rbi,
                     ap_bank_accounts_all abaa,
                     ap_bank_branches abb,
                     rb_bank_account_gl_ccids rbagc,
                     gl_code_combinations gcc
                 WHERE rbaa.bank_account_id = rbi.bank_account_id
                  AND rbaa.bank_account_id = abaa.bank_account_id
                  AND abaa.bank_branch_id = abb.bank_branch_id
                  AND rbagc.bank_account_id = rbaa.bank_account_id
                  AND rbagc.code_combination_id = gcc.code_combination_id
                  AND rbaa.status = 'Y' --> Comptes en rapprochement
                  )
                WHERE rn = 1 --> on prend l'enregistrement le plus récent
                  -- Il faut vérifier que la date du nouveau solde correspond au jour ouvré précédent
                  AND nouv_date <> gd_date_reference
                  -- On définit une limite : 2 mois
                  AND nouv_date > add_months(sysdate, -2)
                ORDER BY nouv_date desc, 2, substr(Nom_Compte, 1, 4);
                */
            --RBE MigR12
            SELECT Id,
                   Nom_Banque,
                   Banque,
                   Guichet,
                   Compte,
                   Nom_Compte,
                   Rappro,
                   Cpt_51,
                   Last_Import,
                   Anc_Date,
                   Nouv_Date,
                   Anc_Solde,
                   Nouv_Solde
            FROM(
              SELECT rbaa.bank_account_id Id,
                     abb.bank_name Nom_Banque,
                     ABB.BANK_NUMBER BANQUE,
                     --ABB.BANK_NUM GUICHET,
                     ABB.BRANCH_NUMBER GUICHET,
                     abaa.bank_account_num Compte,
                     abaa.bank_account_name Nom_Compte,
                     rbaa.status Rappro,
                     gcc.segment3 Cpt_51,
                     rbi.import_date Last_Import,
                     rbi.old_amount Anc_Solde,
                     rbi.new_amount Nouv_Solde,
                     rbi.batch_start_date Anc_Date,
                     rbi.batch_end_date Nouv_Date,
                     ROW_NUMBER() OVER (PARTITION BY RBI.BANK_ACCOUNT_ID ORDER BY RBI.BATCH_END_DATE DESC) RN
                 FROM RB_BANK_ACCOUNTS_ALL RBAA,
                     RB_BATCH_IMPORT RBI,
                     CE_BANK_ACCOUNTS ABAA,
                     CE_BANK_BRANCHES_V ABB,
                     rb_bank_account_gl_ccids rbagc,
                     gl_code_combinations gcc
                 WHERE RBAA.BANK_ACCOUNT_ID = RBI.BANK_ACCOUNT_ID
                  AND RBAA.BANK_ACCOUNT_ID = ABAA.BANK_ACCOUNT_ID
                  AND ABAA.BANK_BRANCH_ID = ABB.BRANCH_PARTY_ID
                  AND rbagc.bank_account_id = rbaa.bank_account_id
                  AND RBAGC.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                  AND RBAA.STATUS = 'Y' --> Comptes en rapprochement
                  )
                WHERE rn = 1 --> on prend l'enregistrement le plus récent
                  -- Il faut vérifier que la date du nouveau solde correspond au jour ouvré précédent
                  AND nouv_date <> gd_date_reference
                  -- On définit une limite : 2 mois
                  AND nouv_date > add_months(sysdate, -2)
                ORDER BY nouv_date desc, 2, substr(Nom_Compte, 1, 4)
                 ;

           Rec_Releve Cur_Releve%ROWTYPE;

  BEGIN

    gv_step       := lv_current_program_unit||' 000 : initialisation';
    dka_tools_pkg.put_debug_message(gv_step);
    vb_boucle     := FALSE;
    Pv_Errbuf     := NULL;
    Pn_Retcode    := 0;

    gv_step     := lv_current_program_unit||' 001 : création du fichier';
   --Initialisation du fichier de sortie --
    vv_fichier := 'Controle_RB_'||to_char(gd_date_reference,'rrrrmmdd')||cv_extension; -- RBE artf2523214 : remplacement du ô
      Dka_Tools_Pkg.Put_Debug_Message('Ouverture du fichier');
      vf_fichier := utl_file.fopen(cv_directory, vv_fichier, 'W', 32764);

    -------------------------------------
    -- Impression de la ligne d'entête --
    -------------------------------------
    gv_step  := lv_current_program_unit||' 002 : écriture de la ligne d''entête';
    Vv_Ligne := 'ID'|| cv_fsep ||
                'NOM_BANQUE'||cv_fsep ||
                'BANQUE'||cv_fsep ||
                'GUICHET' ||cv_fsep ||
                'COMPTE'||cv_fsep ||
                'NOM_COMPTE'||cv_fsep ||
                'RAPPRO'||cv_fsep ||
                'COMPTE_LOCAL'||cv_fsep ||
                'DATE_DERNIER_IMPORT'||cv_fsep ||
                'DATE_DEBUT_RELEVE'||cv_fsep ||
                'DATE_FIN_RELEVE'||cv_fsep ||
                'SOLDE_INITIAL_RELVE'||cv_fsep ||
                'SOLDE_FINAL_RELEVE';

    --Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Ligne);
    Fnd_File.put_line (Fnd_File.Output, Vv_Ligne);
    utl_file.put_line(vf_fichier,Vv_Ligne);

    ------------------------------------
    -- Boucle de lecture des origines --
    ------------------------------------
    gv_step     := lv_current_program_unit||' 003 : écriture des données dans le fichier';
    OPEN Cur_Releve;
    LOOP
        FETCH Cur_Releve INTO Rec_Releve;

        EXIT WHEN Cur_Releve%NOTFOUND;

         Vv_Ligne := rec_releve.Id ||cv_fsep||
                     rec_releve.Nom_Banque ||cv_fsep||
                     rec_releve.Banque ||cv_fsep||
                     rec_releve.Guichet ||cv_fsep||
                     rec_releve.Compte ||cv_fsep||
                     rec_releve.Nom_Compte ||cv_fsep||
                     rec_releve.Rappro ||cv_fsep||
                     rec_releve.Cpt_51 ||cv_fsep||
                     rec_releve.Last_Import ||cv_fsep||
                     rec_releve.Anc_Date ||cv_fsep||
                     rec_releve.Nouv_Date||cv_fsep||
                     rec_releve.Anc_Solde ||cv_fsep||
                     rec_releve.Nouv_Solde;

        vb_boucle:=TRUE;

        Fnd_File.put_line (Fnd_File.Output, Vv_Ligne);
        utl_file.put_line(vf_fichier,Vv_Ligne);

    END LOOP;
    CLOSE Cur_Releve;

    Dka_Tools_Pkg.Put_Debug_Message('Fermeture du fichier');
    utl_file.fclose(vf_fichier);
    gv_file_name := vv_fichier;
    pb_boucle := vb_boucle;

    gv_step   := lv_current_program_unit||' 999 : FIN';


  EXCEPTION
    WHEN OTHERS THEN
      --Fermeture du fichier si erreur
      IF utl_file.is_open(file => vf_fichier) THEN
        utl_file.fclose(vf_fichier);
      END IF;

      gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END CONTROL_BANK_STATEMENT;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_PREV_WORKING_DAY
  --  Description   :  fonction qui retourne le jour ouvré précédent le plus proche de la date passée en paramètre
  --
  --  PARAMETRES    :   --   pv_errbuf      IN OUT NOCOPY VARCHAR2,
                        --   pn_retcode     IN OUT NOCOPY NUMBER,
                        --   pd_date        IN OUT        DATE
   --------------------------------------------------------------------------------------------------
PROCEDURE GET_PREV_WORKING_DAY (Pv_Errbuf  IN OUT NOCOPY VARCHAR2,
                                Pn_Retcode IN OUT NOCOPY NUMBER,
                                pd_date    IN OUT        DATE)
      IS
        lv_current_program_unit  VARCHAR2(30) := 'GET_PREV_WORKING_DAY';
      BEGIN
           -- On recherche si la date est un jour férié ou un jour de week-end
           IF dka_tools_pkg.IS_BANK_HOLIDAY(pd_date)= 1 OR TRIM(TO_CHAR(pd_date, 'DAY')) IN ('SAMEDI', 'DIMANCHE') -- RBE MigR12 - Modif nom package
           THEN
               -- Si oui, on appelle la fonction de manière récursive en diminuant d'un jour,
               -- ce qui permet automatiquement de trouver le précédent jour ouvert
               dka_tools_pkg.put_log_message(pd_date||' est un jour non ouvré');

               pd_date:=pd_date-1;
               dka_tools_pkg.put_log_message('appel récursif de get_prev_working_day avec comme paramètre '||pd_date);
               GET_PREV_WORKING_DAY(pv_errbuf,pn_retcode,pd_date);
           END IF;

      EXCEPTION

       WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
        dka_tools_pkg.put_log_message(gv_step);
        Pv_Errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
        dka_tools_pkg.put_log_message(Pv_Errbuf);
        Pn_Retcode := 2;
      END GET_PREV_WORKING_DAY;

  -----------------------------------------------------------------
  --  Nom           : AFFICHAGE_FICHIER_SORTIE
  --  Description   : procédure d'écriture dans le fichier de sortie
  --                  du traitement
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE affichage_fichier_sortie(pv_errbuf        OUT NOCOPY VARCHAR2,
                                     pn_retcode       OUT NOCOPY NUMBER) IS

   lv_current_program_unit  VARCHAR2(30) := 'affichage_fichier_sortie';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    dka_tools_pkg.put_debug_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : INSERTION ENTETE';
    dka_tools_pkg.put_debug_message(gv_step);
    dka_tools_pkg.put_out_header;

    gv_step  := lv_current_program_unit||' 002 : AFFICHAGE DES PARAMETRES';
    dka_tools_pkg.put_debug_message(gv_step);

    dka_tools_pkg.put_outdebug_message('DATE DE REFERENCE:'||to_char(gd_date_reference,'dd/mm/rrrr'));
    dka_tools_pkg.put_outdebug_message(cv_line);

    gv_step  := lv_current_program_unit||' 003 : FIN';
    dka_tools_pkg.put_debug_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    dka_tools_pkg.put_log_message(gv_step);
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    dka_tools_pkg.put_log_message(pv_errbuf);
    pn_retcode := 2;

  END affichage_fichier_sortie;


  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf          OUT NOCOPY VARCHAR2 message d'erreur si pn_retcode != 0
  --  pn_retcode         OUT NOCOPY NUMBER  code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_date_test       IN         VARCHAR2  Date de référence
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_date_test    IN         VARCHAR2) IS

    lv_current_program_unit  VARCHAR2(30) := 'main';
    vb_boucle          BOOLEAN;

    --EXCEPTION
    e_param            EXCEPTION;
    e_jour_ouvre       EXCEPTION;
    e_control_ecriture EXCEPTION;
    e_output           EXCEPTION;
    e_affichage_sortie EXCEPTION;
    e_envoi_mail       EXCEPTION;

  BEGIN

    ----------------------------------------------------------------
    --RECUPERATION DES PARAMETRES
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Recuperation des parametres');
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Debut : '||get_time);

    --procedure de recuperation des parametres
    get_parameters(pv_errbuf,
                   pn_retcode,
                   pv_date_test);

    IF pn_retcode != 0 THEN
      RAISE e_param;
    END IF;

    dka_tools_pkg.put_log_message('Recuperation des parametres OK...');
    dka_tools_pkg.put_log_message('Fin   : '||get_time);

    ----------------------------------------------------------------
    --AFFICHAGE DANS LE FICHIER DE SORTIE
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie');
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Debut : '||get_time);

    --procedure d'affichage dans le fichier de sortie
    affichage_fichier_sortie(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_affichage_sortie;
    END IF;
    dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie OK...');
    dka_tools_pkg.put_log_message('Fin   : '||get_time);

    ----------------------------------------------------------------
    --DETERMINATION DU PRECEDENT JOUR OUVRE
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Détermination du jour ouvré précédent');
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Debut : '||get_time);

    --procedure d'affichage dans le fichier de sortie
    GET_PREV_WORKING_DAY(pv_errbuf,pn_retcode,gd_date_reference);
    IF pn_retcode != 0 THEN
      RAISE e_jour_ouvre;
    END IF;
    dka_tools_pkg.put_log_message('Détermination du jour ouvré précédent OK...');
    dka_tools_pkg.put_log_message('Fin   : '||get_time);


    ----------------------------------------------------------------
    --ECRITURE DANS LE FICHIER
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Ecriture du fichier de sortie');
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Debut : '||get_time);

    --appel de la procédure de controle et d'écriture de fichier
    CONTROL_BANK_STATEMENT(pv_errbuf,pn_retcode,vb_boucle);
    IF pn_retcode != 0 THEN
      RAISE e_control_ecriture;
    END IF;
    dka_tools_pkg.put_log_message('Ecriture du fichier de sortie OK...');
    dka_tools_pkg.put_log_message('Fin   : '||get_time);

    ----------------------------------------------------------------
    --envoi DU MAIL
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('envoi du mail');
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Debut : '||get_time);

    --appel de la procédure qui envoie le mail avec/sans PJ
    SEND_MSG(pv_errbuf,pn_retcode,vb_boucle);
    IF pn_retcode != 0 THEN
      RAISE e_envoi_mail;
    END IF;
    dka_tools_pkg.put_log_message('envoi du mail OK...');
    dka_tools_pkg.put_log_message('Fin   : '||get_time);



  EXCEPTION
    WHEN e_param THEN
      gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_affichage_sortie THEN
      gv_step  := lv_current_program_unit||' EE2 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_jour_ouvre THEN
      gv_step  := lv_current_program_unit||' EE3 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_control_ecriture THEN
      gv_step  := lv_current_program_unit||' EE4 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_envoi_mail THEN
      gv_step  := lv_current_program_unit||' EE5 : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;

    WHEN OTHERS THEN
      gv_step  := lv_current_program_unit||' EEE : ERREUR lors de :'||gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END main;

END DKA_SRBCTRLRB_PKG;