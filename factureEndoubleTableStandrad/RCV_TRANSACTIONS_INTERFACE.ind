CREATE OR REPLACE PACKAGE BODY Dka_Sfacloture_Pkg AS

  ---------------------------------------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SFACLOTURE_PKG
  -- DESCRIPTION       : Traitement de la cloture des périodes FA
  ---
  --- AUTEUR           : Guillaume Chabrier
  --- DATE DE CREATION : 30/05/2002
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --  09/07/2002 MSF Fusion des packages DKA_SFACLOTURE_PKG et DKA_SFACLOFISC_PKG
  --                 Ajout d'un nouveau paramètre en entrée "vv_book_type_code".
  --                 gestion de l'erreur e_erreur_livre, count_error
  --  24/10/2002 XD  Mise en forme
  --                 Alimentation du va_request_ids
  --  17/01/2003 XD  Modif sur la sélection des livres
  --  24/03/2003 XD  Suppression des lignes à recalculer
  --                 Copie vers le livre fiscal : correction du calcul du livre fiscal
  --  07/04/2003 XD  Changement de responsabilité pour lancer la cloture
  --                 Ne plus lancer d'état
  --  25/06/2003 XD  Plus de controle de la table fa_mass_additions
  --  10/09/2003 XD  Correction pour les sécurité FA
  --  13/02/2004 SL  Modification de la requête de suppression des combinaisons à recalculer
  --- 30/07/2004 SLE Portage spécifique pour projet PHENIX 2004
  ---                Modification de l'appel à la procédure " Fnd_Global.apps_initialize "
  ---                Suppression d'un paramètre dans l'appel à FARET
  ---                Suppression des livres fiscaux
  --- 10/02/2005 SL  PHENIX2004 Debut Report Maintenance
  ---                Report de maintenance (Phoenix)
  ---                Adaptation du package pour crystal qui n'utilise pas le module PA:
  ---                suppression de la requête de suppression des combinaisons à recalculer
  ---                Mise en commun du package pour Crystal et Dalkia
  ---
  ---                Modification de la requête de recherche du livre fiscal à partir du livre comptable
  ---                (rajout d'une condition sur la date_ineffective) -- PHENIX2004
  ---                PHENIX2004 Fin Report Maintenance
  --- 03/05/2013 BCO DPE20120028 - Sécurisation de la clôture FA - Ajout du paramètre "Période à fermer"
  ---                    pour ne sélectionner que les livres dont la période en cour correspond
  ---                 à la période FA en paramètre du traitement.
  --- 03/10/2016 RGH Migration R12
  --- 29/11/16   NBO Force le SOB
  ---------------------------------------------------------------------------------------------------------------

  --gv_type_instance VARCHAR2(10); --PHENIX2004 Report Maintenance

  PROCEDURE main(pv_errbuf         IN OUT VARCHAR2,
                 pn_retcode        OUT NUMBER,
                 pv_book_class     IN VARCHAR2,
                 pv_period_name    IN VARCHAR2,
                 pn_sob            IN NUMBER) IS
    ----- variables venues du spécIFique SFACLOATURE -----
    va_request_ids  Pa_Utils.idtabtyp; ---Tableau
    vn_requests_cnt NUMBER := 0; ---Compteur de request
    --vn_request_id   NUMBER;
    vv_phase        VARCHAR2(10);
    vv_status       VARCHAR2(10);
    vv_dev_phase    VARCHAR2(10);
    vv_dev_status   VARCHAR2(10);
    vv_errbuf       VARCHAR2(150);

    --*************************************************
    --vc_livre VARCHAR2(15);
    vn_dummy NUMBER(22);
    --*************************************************

    --vn_invoice_cnt           NUMBER; --compteur de facture en attente de traitement FA
    vv_book_type_code_fiscal VARCHAR2(15); --représente le livre fiscal d'un société
    --type_code                VARCHAR2(15);
    vv_period_name           VARCHAR2(15);
    vv_close_period          VARCHAR2(3);
    vn_confirm_flag          NUMBER;
    vv_book_class            VARCHAR2(15);
    cop_id                   NUMBER;
    e_erreur_livre EXCEPTION;
    count_error NUMBER(5) := 0;
    ----- variables venues du standard OA ------
    old_profile     VARCHAR2(1);
    ret_id          NUMBER;
    deprn_id        NUMBER;
    rep_id          NUMBER;
    number_required NUMBER;
    dummy_default   BOOLEAN DEFAULT FALSE;
    gen_id          NUMBER;
    ppt_id          NUMBER;
    -- the following is for 309712 workaround
    --h_req_id            NUMBER;
    h_null1             VARCHAR2(200);
    h_null2             VARCHAR2(200);
    h_request_flag      BOOLEAN;
    h_message           VARCHAR2(2000);
    h_status            VARCHAR2(200);
    h_dev_status        VARCHAR2(200);
    h_phase             VARCHAR2(200);
    h_dev_phase         VARCHAR2(200);
    h_req               NUMBER;
    h_last_period_ctr   NUMBER;
    h_deprn_status      VARCHAR2(1);
    h_count             NUMBER;
    --h_book_stat         BOOLEAN;
    h_mrc_sob_type_code VARCHAR2(1);
    close_period        VARCHAR2(1);
    h_printer_profile   VARCHAR2(50);
    set_printer_profile EXCEPTION;
    --vn_responsibility_id NUMBER(15);
    --vn_application_id    NUMBER(15);

    --gn_user_id    NUMBER(15) := Fnd_Global.user_id;
    --gn_request_id NUMBER(15) := Fnd_Global.conc_request_id;
    --gn_SET_OF_BKS_ID NUMBER(15) := FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

    l_log_level FA_API_TYPES.log_level_rec_type; --RGH
    ----- Curseur sur org_id -----
    /*CURSOR cur_org IS
    SELECT   fbc.org_id,
             fbc.book_type_code
    FROM     hr_all_organization_units haou,
             fa_book_controls fbc
    WHERE        haou.organization_id = fbc.org_id
             AND book_class = vv_book_type_code
             --AND fbc.deprn_calendar = 'MOIS 07-06' --MSF: exculsion 26 "Les société cloturant au 30/06"
             AND fbc.date_ineffective IS NULL ----MSF: exculsion 26 "Les sociétés actifs"
             AND fbc.book_type_code != 'REFERENCE' -- Cas test
             AND haou.attribute4 = 'Y'
    ORDER BY fbc.org_id;*/ --RGH

    ----- Curseur sur livre ----- --RGH
    /*
    CURSOR cur_acess is
      SELECT gl.name livre, gl.ledger_id
        FROM gl_access_set_assignments gasa, gl_ledgers gl
       WHERE access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
         AND gl.ledger_id = gasa.ledger_id
         AND gl.ledger_category_code = 'PRIMARY';
    */
    ----- Curseur sur Type livre FA ----- --RGH
    CURSOR cur_book_type IS
      SELECT fbc.SET_OF_BOOKS_ID, fbc.book_type_code
        FROM fa_book_controls fbc, fa_deprn_periods fdp 
       WHERE 1 = 1
         AND book_class = pv_book_class
         AND fbc.book_type_code = fdp.BOOK_TYPE_CODE 
         --AND fbc.SET_OF_BOOKS_ID = p_ledger_id
         AND fdp.period_name = pv_period_name
         AND fdp.period_close_date is null
         AND nvl(fbc.DATE_INEFFECTIVE, trunc(sysdate)) >= trunc(sysdate) -- Les sociétés actifs
         AND fbc.book_type_code != 'REFERENCE' 
         AND fbc.SET_OF_BOOKS_ID = pn_sob;

    --vv_responsibility_key fnd_responsibility.responsibility_key%TYPE; -- PHENIX 2004: Ajout.
    --vr_data               DKA_PARAMETERS%ROWTYPE; -- PHENIX 2004: Ajout.
    --vn_retcode            NUMBER; -- PHENIX 2004: Ajout.
    --vv_err_msg            VARCHAR2(512); -- PHENIX 2004: Ajout.

    ----------------------------------------------------------------------------------------------------------
  BEGIN
    -- main
      dka_tools_pkg.put_log_message('pv_book_class = ' || pv_book_class);
      dka_tools_pkg.put_log_message('pv_period_name = ' || pv_period_name);
      dka_tools_pkg.put_log_message('pn_sob = ' || pn_sob);

    --dka_tools_pkg.put_debug_message('SFACLOTURE');
    ----------------------------------------------------------------------------------------------------------
    -- On verifie le type du livre
      IF pv_book_class = 'CORPORATE' THEN
        ----- comme pré-requis, on vérifie que les factures AP sont toutes interfacées sinon je sort en erreur

        Dka_Tools_Pkg.put_log_message('Livre comptable');
        --SELECT COUNT (*)
        --INTO   vn_invoice_cnt
        --FROM   fa_mass_additions
        --WHERE     posting_status = 'NEW'
        --       OR posting_status = 'POST'
        --       OR posting_status = 'ON HOLD';
        --
        --IF vn_invoice_cnt > 0
        --THEN
        --    dka_tools_pkg.put_debug_message ('***************************');
        --    dka_tools_pkg.put_debug_message ('Il existe des factures AP non interfacées');
        --    dka_tools_pkg.put_debug_message ('***************************');
        --    pn_retcode    := 2;
        --    RETURN;
        --END IF;
      ELSIF pv_book_class = 'TAX' THEN
        Dka_Tools_Pkg.put_log_message('Livre fiscal');
      ELSE
        Dka_Tools_Pkg.put_log_message('Le livre sélectionné n''est pas identifié');
        pn_retcode := 2;
        RETURN;
      END IF;

      --PHENIX2004 Debut Report Maintenance
      -- Récupération de l'option de profil déterminant s'il s'agit d'une base CRYSTAL ou DALKIA
      /* --RGH
      gv_type_instance := fnd_profile.value('DKA_TYPE_INSTANCE');
      dka_tools_pkg.put_log_message ('Instance >>>>>>>>>>>>>>> '|| gv_type_instance);
      IF gv_type_instance IS NULL
      THEN
        dka_tools_pkg.put_log_message ('Option de profil du type d''Instance non positionnée');
        pn_retcode    := 2;
        RETURN;
      END IF;
      */ --RGH
      ----- Dans le cas d'une base CRYSTAL, Le DELETE des clés générées ne doit pas être fait ici
      ----- 1) L'appartenance est dans un CUF sur le jeu de valeurs des codes affaires :il n'y a donc pas d'historique
      -----    de l'appartenance d'un code affaire. C'est donc un trigger sur le jeu de valeurs qui fait éventuellement
      -----    le DELETE
      ----- 2) Contrairement à Dalkia, le workflow n'utilise pas le centre de gestion issu du projet via l'appartenance,
      -----    via la société mais celui provenant de FA_MASS_ADDITION dans le cas d'une immo isuue de AP et du compte de
      -----    dotation aux amortissements saisi par l'utilisateur. Les triggers Dalkia suffisent donc.
      /* --RGH
      IF (gv_type_instance != 'CRYSTAL')
      THEN
      --PHENIX2004 Fin Report Maintenance
              -- Suppression des combinaison à recalculer
              DELETE      fa_distribution_accounts fda
              WHERE       (fda.book_type_code, fda.distribution_id) IN
                                  (SELECT          -- ordered use_nl(fdp_open,fdp,fdh,fab)
                                   DISTINCT        fdh.book_type_code,
                                                   fdh.distribution_id
                                   FROM            fa_book_controls fbc,
                                                   fa_deprn_periods fdp_open,
                                                   fa_deprn_periods fdp,
                                                   fa_books fb,
                                                   fa_distribution_history fdh,
                                                   fa_additions_b fab
                                   WHERE               fdp_open.period_counter = fbc.last_period_counter + 1
                                                   AND fdp.period_counter = fbc.last_period_counter
                                                   AND fbc.book_type_code = fdp_open.book_type_code
                                                   AND fbc.book_type_code = fdp.book_type_code
                                                   AND fbc.book_class = vv_book_type_code
                                                   AND fbc.date_ineffective IS NULL
                                                   AND fbc.book_type_code = fb.book_type_code
                                                   AND fb.asset_id = fdh.asset_id
                                                   AND fab.asset_id = fb.asset_id
                                                   AND fbc.book_type_code = fdh.book_type_code
                                                   AND (   (Dka_Tools_Pkg.get_appart (fab.attribute1, fdp_open.calendar_period_close_date) !=
                                                                          Dka_Tools_Pkg.get_appart (fab.attribute1, fdp.calendar_period_close_date)
                                                           )
                                                        OR (Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f (
                                                                fab.attribute1,
                                                                '1',
                                                                fdp_open.calendar_period_close_date
                                                            ) != Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f (
                                                                     fab.attribute1,
                                                                     '1',
                                                                     fdp.calendar_period_close_date
                                                                 )
                                                           )
                                                       ));*/ --RGH

      vn_dummy := SQL%ROWCOUNT;

      IF vn_dummy > 0 THEN
        INSERT INTO dka_sfacloture_trace
          (creation_date, created_by, number_of_rows, message)
        VALUES
          (SYSDATE,
           Fnd_Global.user_id,
           vn_dummy,
           'Changement d''appartenance ou de centre de gestion du projet');
      END IF;
      --END IF; ----- Si Ce n'est pas une base Crystal --PHENIX2004

      -- PHENIX 2004: DEBUT déplacement et modification de ce code
      -- Connexion dans la responsabilité --
      /* --RGH
      Dka_Tools_Pkg.get_parameter('DKA_SFACLOTURE', 'FA_RESPONSIBILITY_KEY', vr_data, vn_retcode, vv_err_msg);
      vv_responsibility_key := vr_data.varchar2_value;

      -- Connexion dans la responsabilité --
      SELECT fr.responsibility_id,
             fr.application_id
      INTO   vn_responsibility_id,
             vn_application_id
      FROM   fnd_responsibility fr
      WHERE    fr.responsibility_key = vv_responsibility_key;
      -- PHENIX 2004: Suppression  SUBSTR (fr.responsibility_key, 1, 6) = 'FA' || SUBSTR (rec_org.book_type_code, 1, 4)
      -- PHENIX 2004: Suppression      AND fr.responsibility_key LIKE '%FISCAL';

      Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);
      -- fin PHENIX 2004
      */ --RGH
      --------------------------------------------------------------------------------------------------------
      --FOR rec_org IN cur_org --RGH
      FOR rec_book IN cur_book_type LOOP
        pn_retcode := 0;

        --*************************************************************************************************************
        ----- selection du period_name se rapportant au book_code ------
        SELECT period_name
          INTO vv_period_name
          FROM fa_deprn_periods
         WHERE book_type_code = rec_book.book_type_code
           AND period_close_date IS NULL;

        -- -------------------------------------------- --
        -- DPE20120028 - Sécurisation de la clôture FA. --
        -- -------------------------------------------- --
        IF pv_period_name = vv_period_name THEN

          --*************************************************************************************************************
          -- Fa_Security.reset_fa_context; --RGH

          Dka_Tools_Pkg.put_log_message('***************************************************');
          --Dka_Tools_Pkg.put_debug_message ('org_id :'|| rec_org.org_id);
          Dka_Tools_Pkg.put_log_message('book_type_code :' ||  rec_book.book_type_code);
          Dka_Tools_Pkg.put_log_message('periode :       ' ||  vv_period_name);

          --dka_tools_pkg.put_debug_message('');

          ----------------------------*****************************************-------------------------
          BEGIN
            ----- procedure standard OA -----
            -- mwoodwar 12/09/99.  CRL Stub call.
            ----- Option de profil d'installation non accessible -----
            /*
            IF (fnd_profile.value('CRL-FA ENABLED') = 'Y') THEN
              IF not (fa_cua_trx_approval_ext_pkg.facuas2(rec_org.book_type_code, 'R')) THEN
              --fa_standard.raise_error('FA_CUA_PENDING_BOOK');
              END IF;
            END IF;
            */

            -- Check implemented for bug 915890
            h_printer_profile := Fnd_Profile.VALUE('PRINTER');

            IF (h_printer_profile IS NULL) THEN
              RAISE set_printer_profile;
            END IF;

            --  The following is a workaround for bug 309712,
            --  lIFting some code from user exit to here

            SELECT deprn_status, deprn_request_id, last_period_counter
              INTO h_deprn_status, h_req, h_last_period_ctr
              FROM fa_book_controls
             WHERE book_type_code = rec_book.book_type_code;

            Dka_Tools_Pkg.put_debug_message('h_deprn_status :' ||  h_deprn_status);

            IF (h_deprn_status IN ('S', 'R')) THEN
              --'S' : Submitted , 'R' : Running
              h_request_flag := Fnd_Concurrent.get_request_status(h_req,
                                                                  h_null1,
                                                                  h_null2,
                                                                  h_phase,
                                                                  h_status,
                                                                  h_dev_phase,
                                                                  h_dev_status,
                                                                  h_message);

              IF (h_dev_phase IN ('PENDING', 'INACTIVE', 'RUNNING')) THEN
                vn_confirm_flag := 0;
                --fa_standard.raise_error('FA_TRXAPP_DEPRN_IS_RUNNING',
                --          'BOOK',rec_org.book_type_code);

              END IF;
            ELSIF (h_dev_phase IS NOT NULL AND
                  h_dev_phase NOT IN ('PENDING', 'INACTIVE', 'RUNNING')) THEN
              SELECT COUNT(*)
                INTO h_count
                FROM fa_deprn_summary
               WHERE book_type_code = rec_book.book_type_code
                 AND period_counter = h_last_period_ctr + 1;

              IF (h_count != 0) THEN
                vn_confirm_flag := 0;
                --fa_standard.raise_error('FA_TRXAPP_DEPRN_FAILED','BOOK',
                --      rec_org.book_type_code);
              END IF;
            ELSIF (h_dev_phase IS NOT NULL AND h_dev_phase != 'C') THEN
              vn_confirm_flag := 0;
              --fa_standard.raise_error('FA_TRXAPP_UNKNOWN_STATUS','STATUS',
              --      h_dev_phase);

            END IF;

            -- Bug 309712 workaround ENDs here

            --    USER_EXIT('OFA CHECK_BOOK_STATUS ' ||
            --              'BOOK_TYPE_CODE="rec_org.book_type_code" ');
            /*
                h_book_stat := FA_CHK_BOOKSTS_PKG.FAXCBSX (
                      X_book  => rec_org.book_type_code,
                  X_init_message_flag => 'YES'
                  );

            IF  (NOT h_book_stat) THEN
                faform_messages.Get_Server_Messages;

                IF (FAFORM_MESSAGES.Print_Debug) THEN
                  FAFORM_MESSAGES.Raise_Debug_Messages;
                END IF;
                vn_confirm_flag := 0;
                raise Form_Trigger_Failure;
              END IF;

            */
            -- get mrc_sob_type_code for the current book to see
            -- IF FARET or FAGDA needs to be submitted
            SELECT glsob.mrc_sob_type_code
              INTO h_mrc_sob_type_code
              FROM gl_sets_of_books glsob, fa_book_controls bc
             WHERE glsob.set_of_books_id = bc.set_of_books_id
               AND bc.book_type_code = rec_book.book_type_code;

            --old_profile := Fnd_Profile.VALUE('CONC_SINGLE_THREAD');
            Fnd_Profile.put('CONC_SINGLE_THREAD', 'Y');
            old_profile                 := 'Y';
            l_log_level.statement_level := TRUE; --RGH
            Fa_Set_Profile_Pkg1.fa_sprf(old_profile, l_log_level); --RGH : Migration R12 ajout l_log_level
            Dka_Tools_Pkg.put_log_message('h_mrc_sob_type_code : ' ||h_mrc_sob_type_code);
            Dka_Tools_Pkg.put_log_message('lancement FAGDA');

            IF (h_mrc_sob_type_code != 'R') THEN
              -- submit Generate Accounts Program
              gen_id := Fnd_Request.submit_request('OFA', -- application
                                                   'FAGDA', -- program : Générer des comptes
                                                   '', -- description
                                                   '', -- start_time
                                                   dummy_default, --sub_request : FALSE
                                                   rec_book.book_type_code --argument1
                                                   );

              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := gen_id;
            END IF;

            Dka_Tools_Pkg.put_log_message('lancement FARET');

            -- IF book is a reporting book do not submit FARET
            IF (h_mrc_sob_type_code != 'R') THEN
              ret_id := Fnd_Request.submit_request('OFA',
                                                   'FARET', -- FA Retirement Program : Calculer les plus- et moins-values
                                                   '',
                                                   '',
                                                   dummy_default,
                                                   rec_book.book_type_code
                                                   -- , vv_period_name PHENIX 2004
                                                   );
              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := ret_id;
            END IF;

            number_required := TO_NUMBER(Fnd_Profile.VALUE('FA_NUM_PARALLEL_REQUESTS'));
            ----- code original OA laissé -----
            ----- pour le spécIFique : close period est tjs à YES car on veut fermer les periodes -----
            vv_close_period := 'YES';

            IF vv_close_period = 'YES' THEN
              close_period := '1';
            ELSE
              close_period := '0';
            END IF;

            IF number_required > 0 THEN
              Dka_Tools_Pkg.put_log_message('number_required : ' || number_required);
              Dka_Tools_Pkg.put_log_message('lancement FADEPR');
              deprn_id := Fnd_Request.submit_request('OFA',
                                                     'FADEPR', -- FA Depreciation Program : Exécution d'amortissement
                                                     '',
                                                     '',
                                                     dummy_default,
                                                     rec_book.book_type_code,
                                                     vv_period_name,
                                                     close_period,
                                                     TO_CHAR(number_required));
              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := deprn_id;
            ELSE
              Dka_Tools_Pkg.put_log_message('lancement FADEPR');
              deprn_id := Fnd_Request.submit_request('OFA',
                                                     'FADEPR', -- FA Depreciation Program : Exécution d'amortissement
                                                     '',
                                                     '',
                                                     dummy_default,
                                                     rec_book.book_type_code,
                                                     vv_period_name,
                                                     close_period);
              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := deprn_id;
            END IF;

            ----- ajout spécIFique -----
            SELECT book_class
              INTO vv_book_class
              FROM fa_book_controls
             WHERE book_type_code = rec_book.book_type_code;

            ----- standard OA -----
            -- IF vv_book_class = 'CORPORATE'
            -- THEN
            --     IF fnd_profile.VALUE ('CRL-FA ENABLED') = 'Y'
            --     THEN
            --         dka_tools_pkg.put_debug_message ('lancement FACS400');
            --         rep_id                              := fnd_request.submit_request (
            --                                                    'CUA',
            --                                                    'FACS400', -- CRL Journal Entry Reserve Ledger
            --                                                    '',
            --                                                    '',
            --                                                    dummy_default,
            --                                                    rec_org.book_type_code,
            --                                                    vv_period_name
            --                                                );
            --         vn_requests_cnt                     := vn_requests_cnt + 1;
            --         va_request_ids (vn_requests_cnt)    := rep_id;
            --     ELSE
            --         dka_tools_pkg.put_debug_message ('lancement FAS400');
            --         rep_id                              := fnd_request.submit_request (
            --                                                    'OFA',
            --                                                    'FAS400', -- Journal Entry Reserve Ledger
            --                                                    '',
            --                                                    '',
            --                                                    dummy_default,
            --                                                    rec_org.book_type_code,
            --                                                    vv_period_name
            --                                                );
            --         vn_requests_cnt                     := vn_requests_cnt + 1;
            --         va_request_ids (vn_requests_cnt)    := rep_id;
            --     END IF;
            -- ELSE
            --     dka_tools_pkg.put_debug_message ('lancement FAS480');
            --     rep_id                              := fnd_request.submit_request (
            --                                                'OFA',
            --                                                'FAS480', -- Tax Reserve Ledger Report
            --                                                '',
            --                                                '',
            --                                                dummy_default,
            --                                                rec_org.book_type_code,
            --                                                vv_period_name
            --                                            );
            --     vn_requests_cnt                     := vn_requests_cnt + 1;
            --     va_request_ids (vn_requests_cnt)    := rep_id;
            -- END IF;

            -- Fix for Bug 1399652.  IF period is closed, THEN
            -- run the Process PENDing Transactions program,
            -- i.e., Mass Additions Post in FUTURE mode.

            IF (close_period = 1) AND (h_mrc_sob_type_code != 'R') THEN
              Dka_Tools_Pkg.put_log_message('lancement FAPPT');
              ppt_id := Fnd_Request.submit_request('OFA',
                                                   'FAPPT', -- Process PENDing Transactions : Traiter les mouvements en attente
                                                   '',
                                                   '',
                                                   dummy_default,
                                                   rec_book.book_type_code,
                                                   'FUTURE');
              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := ppt_id;
            END IF;

            Fnd_Message.set_name('OFA', 'FA_DEPRN_REQUESTS');
            Fnd_Message.set_token('GEN_ID', TO_CHAR(gen_id), dummy_default);
            Fnd_Message.set_token('RET_ID', TO_CHAR(ret_id), dummy_default);
            Fnd_Message.set_token('DEPRN_ID',
                                  TO_CHAR(deprn_id),
                                  dummy_default);
            Fnd_Message.set_token('REP_ID', TO_CHAR(rep_id), dummy_default);

            IF (close_period = 1) AND (h_mrc_sob_type_code != 'R') THEN
              Fnd_Message.set_token('PPT_ID', TO_CHAR(ppt_id), dummy_default);
            END IF;

            ----- standard OA -----
            --FND_MESSAGE.RETRIEVE;
            --FND_MESSAGE.SHOW;
            Dka_Tools_Pkg.put_log_message(Fnd_Message.get);
            UPDATE fa_book_controls
               SET deprn_status = 'S', deprn_request_id = deprn_id
             WHERE book_type_code = rec_book.book_type_code;
             commit;
             Dka_Tools_Pkg.put_log_message('deprn_status updated to S for ' || TO_CHAR(deprn_id));
            --    FND_PROFILE.PUT('CONC_SINGLE_THREAD', old_profile);
            Fa_Set_Profile_Pkg1.fa_sprf(old_profile, l_log_level); --RGH : Migration R12 ajout l_log_level
          EXCEPTION
            --WHEN SET_PRINTER_PROFILE THEN
            --FND_MESSAGE.SET_NAME('FND','CONC-ILLEGAL PRINTER SPEC');
            --FND_MESSAGE.ERROR;
            --WHEN FORM_TRIGGER_FAILURE THEN
            --vn_confirm_flag := 0;
            --raise;
            WHEN OTHERS THEN
              vn_confirm_flag := 0;
              --fa_standard.raise_error;
          END; --standard OA

          ----------------------------****************Lancement Copie vers livre fiscal****************------------------
          -- PHENIX 2004 : Suppression des livres fiscaux => Copie inutile
          /**/
          --IF vv_book_type_code = 'CORPORATE'
            IF pv_book_class  = 'CORPORATE'
          THEN
            BEGIN --Lancement Copie vers livre fiscal
              Dka_Tools_Pkg.put_log_message ('lancement FAMCP copie de livre fiscal');

              ----- Cloture du livre comptable livre FISCAL
              SELECT fbc.book_type_code
              INTO   vv_book_type_code_fiscal
              FROM   fa_book_controls fbc
              WHERE  fbc.distribution_source_book = rec_book.book_type_code
              AND    fbc.book_class = 'TAX'
              AND    fbc.book_type_code like '%IFRS%'
              AND    nvl(fbc.date_ineffective, sysdate) >= sysdate; --PHENIX2004 Report Maintenance;

              cop_id                              :=
                  Fnd_Request.submit_request (
                    'OFA',
                    'FAMCP', -- Copie assets and transactions from corporate to tax book
                    '',
                    '',
                    dummy_default,
                    vv_book_type_code_fiscal,
                    vv_period_name,
                    2
                  ); --Code désignant la copie haut volume périodique constante = 2
              vn_requests_cnt                     := vn_requests_cnt + 1;
              va_request_ids (vn_requests_cnt)    := cop_id;
            EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                pn_retcode     := 1;
                count_error    := count_error + 1;
                Dka_Tools_Pkg.put_log_message (
                  'Le livre fiscal correspondant à "'|| rec_book.book_type_code || '" n''est pas déclaré'
                );
              WHEN OTHERS
              THEN
                pn_retcode    := 2;
            END; --Lancement Copie vers livre fiscal
          END IF;

          --***********************************************************************************************************
        END IF;
      END LOOP;

      -- Validation pour que les traitements démarrent
      COMMIT;

      IF count_error != 0 THEN
        pn_retcode := 2;
      END IF;

      /*********************** VERIFICATION ET ATTENTE >fin DES TRAITEMENTS  ***************************/
      ----- On part du dernier traitement lancé en pariant sur le fait que si le dernier traitement est terminé -----
      ----- il y a des chances que les précédents le soient aussi -----

      WHILE vn_requests_cnt > 0 LOOP
        IF NOT (Fnd_Concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                                15,
                                                0,
                                                vv_phase,
                                                vv_status,
                                                vv_dev_phase,
                                                vv_dev_status,
                                                vv_errbuf)) THEN
          Dka_Tools_Pkg.put_log_message('Traitement numéro ' ||
                                             TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                             ' trop long ou tombé en erreur : Erreur : ' || vv_errbuf);
          pn_retcode := 1;
        ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
          Dka_Tools_Pkg.put_log_message('Traitement numéro ' ||
                                          TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                          ' correctement exécuté');
        ELSE
          Dka_Tools_Pkg.put_log_message('Traitement numéro ' ||
                                          TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                          ' terminé anormalement : Erreur : ' || vv_errbuf);
          pn_retcode := 1;
        END IF; ----- >fin IF NOT -----

        vn_requests_cnt := vn_requests_cnt - 1;
      END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      Dka_Tools_Pkg.put_log_message('OTHERS');
  END main;
  --------------------------------------------------------------------------------------------------------
END Dka_Sfacloture_Pkg; -- Package body
/
SHOW ERRORS;
EXIT
