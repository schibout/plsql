CREATE OR REPLACE PACKAGE BODY Dka_Sapletmvtzero_Pkg AS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SAPLETMVTZERO_PKG.pkb
    -- DESCRIPTION      : DKA_SAPLETMVTZERO_PKG Package Body
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 28/09/2006
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    -- 
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 31/10/2007 ADR ETANCHEITE DALKIA 2007
    -- 21/08/2008 EMA Dans la mise à jour de la table Po_Vendor_Sites, on utilise le
    --                champ attribute9 au lieu du champ attribute6.
    -- 22/06/2016 YWA Migration R12
    -- 01/06/2017 NBO artf2133561 - SPE110 - Optimisation du programme
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Warning_Programme                   EXCEPTION;
    Erreur_Programme                    EXCEPTION;
    g_org_id                        hr_all_organization_units.organization_id%TYPE;
    g_ap_app_id                     NUMBER ;
    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_tempo                        NUMBER;

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


     /*
    *************************************************************************
    * PROCEDURE NAME : init
    *
    * DESCRIPTION
    *  Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS

        v_procedure   VARCHAR2(30);
        program_error             EXCEPTION;

    BEGIN

        Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init');


        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_procedure := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------

        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_user_id                    :=   fnd_global.user_id;
        g_ap_app_id                     := 200;
        g_tempo                        := 20;


        Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');


    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.output, 'ERREUR : ' || p_errbuf);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := v_procedure ||': '||SQLERRM;
    END init;

    /* ***********************************************************************
    * PROCEDURE NAME : init_environement
    *
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init_environement (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS
        v_resp_id                               NUMBER;
        v_resp_appl_id                          NUMBER;
    BEGIN

        -- artf2133561 - SPE110 - Optimisation du programme
        SELECT responsibility_id
              ,application_id
        INTO   v_resp_id
               ,v_resp_appl_id
        FROM
        (
                    --SELECT  furg.responsibility_id,
                    --        furg.responsibility_application_id
                    SELECT  fr.responsibility_id,
                            fr.application_id
                    FROM    FND_PROFILE_OPTIONS       fpo,
                            FND_PROFILE_OPTION_VALUES fpov,
                            --FND_USER_RESP_GROUPS      furg
                            FND_RESPONSiBILITY FR
                    WHERE  1 = 1
                    AND    fpov.APPLICATION_ID       = fpo.APPLICATION_ID
                    AND    fpov.PROFILE_OPTION_ID    = fpo.PROFILE_OPTION_ID
                    AND    fpov.PROFILE_OPTION_VALUE = TO_CHAR(g_org_id)
                    AND    fpo.PROFILE_OPTION_NAME   = 'ORG_ID'
                    AND    fpov.LEVEL_ID             = 10003
                    --AND    furg.responsibility_application_id = fpov.LEVEL_VALUE_APPLICATION_ID
                    --AND    furg.responsibility_id       = fpov.LEVEL_VALUE
                    --AND    furg.USER_ID                 = g_user_id
                    --AND    furg.START_DATE              <= SYSDATE
                    --AND    nvl(furg.END_DATE,SYSDATE+1) >= SYSDATE
                    --AND    furg.responsibility_application_id = g_ap_app_id -- AP
                    AND    fr.application_id = fpov.LEVEL_VALUE_APPLICATION_ID
                    AND    fr.responsibility_id       = fpov.LEVEL_VALUE
                    AND    fr.START_DATE              <= SYSDATE
                    AND    nvl(fr.END_DATE,SYSDATE+1) >= SYSDATE
                    AND    fr.application_id = g_ap_app_id -- AP
                    --ORDER BY furg.responsibility_id ASC
                    ORDER BY fr.responsibility_id ASC

            )
        WHERE ROWNUM = 1; --Car on ne veut qu'une seule responsabilité


        fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);

        -- Initialiser org_id
        mo_global.set_org_context(g_org_id,NULL,'SQLAP');

    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.output, 'ERREUR : ' || p_errbuf);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'init_environement: '||SQLERRM;

    END init_environement;
    
    
    /*=========================================================================*/
    /* PROCEDURE NAME :   wait_program_end 
    /*
    /* DESCRIPTION  Attente de la fin du traitement
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /* p_request_id       Id du traitementr PPR. 
    /*
    /*=========================================================================*/
    PROCEDURE wait_program_end
                        (p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER,
                         p_request_id        IN  NUMBER )
    IS

        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);

        -- Boolean. Ctrle qu'un traitement soumis est en cours d'exécution
        v_end boolean := FALSE;
        v_trash VARCHAR2(1);

        -- Liste des programmes soumis par le PPR
        CURSOR Cur_Request IS
        select Fcr.request_id, fcp.USER_CONCURRENT_PROGRAM_NAME
        from fnd_concurrent_requests Fcr, Fnd_Concurrent_Programs_Vl Fcp
        where Fcr.CONCURRENT_PROGRAM_ID = Fcp.CONCURRENT_PROGRAM_ID
        start with Fcr.request_id = p_request_id
        connect by prior Fcr.request_id = Fcr.PARENT_REQUEST_ID
        ORDER BY Fcr.request_id desc;

        v_errbuf varchar2(32000);
        v_retcode NUMBER;

    BEGIN
            -- Tant qu'il existe un traitement en cours dans le PPR
            WHILE ( NOT v_end )
            LOOP

               BEGIN
                  -- Recherche si un traitement soumis par le PPR est en cours
                  select 'x'
                  into v_trash
                  from fnd_concurrent_requests fcr
                  where fcr.request_id in ( select fcr.request_id
                           from fnd_concurrent_requests fcr
                           start with fcr.request_id = p_request_id
                           connect by prior fcr.request_id = fcr.PARENT_REQUEST_ID )
                  and fcr.phase_code <> 'C'
                  and rownum = 1;
                  -- Au moins un traitement est en cours. On attend avant la prochaine boucle
                  dbms_lock.sleep (g_tempo);
               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  -- Tous les traitements soumis par le PPR sont termines.
                  -- On peut sortir de la boucle et controler l'etat de sortie des traitements soumis.
                  v_end := TRUE;
               END;

            END LOOP; /* ( NOT v_end ) */

            -- Ctrle de l'etat de sortie des traitements soumis par le PPR.
            FOR Rec_Request IN Cur_Request
            LOOP

               IF NOT (Fnd_Concurrent.wait_for_request (Rec_Request.request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN
                    v_errbuf  := v_message;
                    v_retcode    := 2;
                    Fnd_File.put_line (Fnd_File.output, 'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' || CHR(10) ||
                                                        'MESSAGE : ' || v_message || CHR(10) );
               END IF;

               IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                   Fnd_File.put_line (Fnd_File.output, 'Request '||Rec_Request.request_id ||': COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                   Fnd_File.put_line (Fnd_File.LOG, 'Request '||Rec_Request.request_id ||': Statut de fin : ' || v_phase || '/' || v_status);


               ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                  Fnd_File.put_line (Fnd_File.output, 'Traitement '||Rec_Request.request_id||'- Programme '||Rec_Request.USER_CONCURRENT_PROGRAM_NAME ||' en warning ');

                  IF NVL(p_retcode,0) < 1 -- Pas d'erreur plus grave que le niveau 1
                  THEN
                     v_errbuf  := 'Request '||Rec_Request.request_id||': Fin du traitement en warning ';
                     v_retcode    := 1;
                  END IF;

               ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                  IF NVL(p_retcode,0) < 2 -- Pas d'erreur plus grave de niveau 2
                  THEN
                      v_retcode := 2;
                      v_errbuf  := 'Request '||Rec_Request.request_id||': Fin du traitement en erreur ';
                   END IF;

                   Fnd_File.put_line (Fnd_File.output, 'Traitement '||Rec_Request.request_id||'- Programme '||Rec_Request.USER_CONCURRENT_PROGRAM_NAME ||' en erreur ');

                   Fnd_File.put_line (Fnd_File.output, 'ERREUR : Fin anormale du traitement '|| Rec_Request.request_id  || CHR(10) ||
                                              'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                              'MESSAGE : ' || v_message || CHR(10) );
                   Fnd_File.put_line (Fnd_File.LOG, '===> ERREUR : Fin anormale du traitement '||Rec_Request.request_id);
               END IF;

            END LOOP; /* Rec_Request IN Cur_Request */

            p_retcode := v_retcode;
            p_errbuf := v_errbuf;

EXCEPTION
WHEN OTHERS THEN
  p_errbuf  := SQLCODE || ' -' || SQLERRM || ' ';
  p_retcode := 2;
  Dka_Tools_Pkg.put_log_message('wait_program_end - Erreur... : '|| p_errbuf);

END wait_program_end;
    
    
    
    /*=========================================================================*/
    /* PROCEDURE NAME :   autoselect
    /*
    /* DESCRIPTION  Traitement standard d?import des fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE autoselect(p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER,
                         p_request_id        OUT NUMBER,
                         p_template_id      IN NUMBER)
    IS

        v_message                VARCHAR2 (100);
        v_request_id             NUMBER;
        v_errbuf varchar2(32000);
        v_retcode NUMBER;

    BEGIN
        v_request_id:= FND_REQUEST.SUBMIT_REQUEST
                               (Application => 'SQLAP'
                               ,Program     => 'APXPBASL'
                               ,Description => NULL
                               ,Start_time  => NULL
                               ,Sub_Request => FALSE
                               ,Argument1   => NULL
                               ,Argument2   => p_template_id
                               ,Argument3   => to_char(TRUNC(sysdate), 'YYYY/MM/DD HH24:MI:SS')--2016/06/22 00:00:00--fnd_date.canonical_to_date(sysdate)
                               ,Argument4   => to_char(TRUNC(sysdate), 'YYYY/MM/DD HH24:MI:SS')--fnd_date.canonical_to_date(sysdate+30)
                               ,Argument5   => NULL
                               );


        IF v_request_id = 0 THEN

            p_retcode    := 2;
            Fnd_File.put_line (Fnd_File.output, 'ERREUR : Le Programme de demande de traitement des règlements' || CHR(10) ||
                                            'PROGRAMME  : Le Programme de demande de traitement des règlements');
            Fnd_File.put_line (Fnd_File.LOG, '====> ERREUR : Le Programme de demande de traitement des règlements ');
            v_message :=' ERREUR : Le Programme de demande de traitement des règlements ';
            p_errbuf := v_message;

        ELSE
            COMMIT;
            Fnd_File.put_line (Fnd_File.output, '=> LOAD REQUEST ID= ' || v_request_id);
            Fnd_File.put_line (Fnd_File.LOG, 'Numéro du Programme de demande de traitement des règlements: ' || v_request_id);
            p_request_id := v_request_id;
            
            wait_program_end
                        (p_errbuf      => v_errbuf,
                         p_retcode     => v_retcode,
                         p_request_id  => v_request_id );
            
            p_retcode := v_retcode;
            p_errbuf := v_errbuf;
        END IF; 
        
            

    END autoselect;
    -- -----------------------------------------------------------------------------
    -- Nom              : Maj_Mouvements
    -- Description      : Procédure de mise à jour des mouvements à 0 et non annulées
    --
    -- PARAMETRES       : Pn_Nb_Factures Sortie Nombre de factures à traiter
    --                    Pv_Errbuf      Sortie Message d'erreur
    --                    Pn_Retcode     Sortie Code Retour de la procédure
    --                                          '0' : Normal
    --                                          '1' : Avertissement
    --                                          '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Maj_Mouvements(Pn_Nb_Factures  OUT  NUMBER,
                             Pv_Errbuf       OUT  VARCHAR2,
                             Pn_Retcode      OUT  NUMBER) IS

        ----------------------------------------
        -- Curseur de lecture de l'échéancier --
        ----------------------------------------
        CURSOR Cur_Payment_Schedules_1 IS
            SELECT Apsa.*
            /*ETANCHEITE DALKIA 2007*/
            FROM   Ap_Payment_Schedules_All Apsa
            WHERE  Apsa.Invoice_Id IN (SELECT Aia.Invoice_Id
                                       /*ETANCHEITE DALKIA 2007*/
                                       FROM   Ap_Invoices_All Aia
                                       WHERE  Aia.Invoice_Amount      = 0
                                       AND    Aia.Cancelled_Date     IS NULL
                                       AND    Aia.Payment_Status_Flag = 'N'
                                       AND    Ap_Invoices_Pkg.Get_Approval_Status(Aia.Invoice_Id,
                                                                                  Aia.Invoice_Amount,
                                                                                  Aia.Payment_Status_Flag,
                                                                                  Aia.Invoice_Type_Lookup_Code) IN ('APPROVED', 'UNPAID'))
            AND    Apsa.Payment_Status_Flag = 'Y'
            AND    Apsa.Checkrun_Id        IS NULL
            AND    Apsa.Due_Date           <= SYSDATE
            FOR UPDATE OF Apsa.Payment_Status_Flag,
                          Apsa.Last_Update_Date,
                          Apsa.Last_Updated_By,
                          Apsa.Last_Update_Login;

        -------------------------------------
        -- Curseur de lecture des factures --
        -------------------------------------
        CURSOR Cur_Invoices IS
            SELECT Aia.Invoice_Id,
                   Aia.Invoice_Num,
                   Aia.Invoice_Amount,
                   Aia.Cancelled_Date,
                   Aia.Pay_Group_Lookup_Code,
                   Aia.PAYMENT_METHOD_CODE,
                   Pv.Vendor_Name,
                   Aia.Vendor_Site_Id,
                   Aia.org_id
            /*ETANCHEITE DALKIA 2007*/
            FROM   Ap_Invoices_All            Aia,
                   Ap_Payment_Schedules_All   Apsa,
                   AP_SUPPLIERS                 Pv
            WHERE  Aia.Invoice_Id           = Apsa.Invoice_Id
            AND    Aia.Vendor_Id            = Pv.Vendor_Id
            AND    Aia.org_id               = Apsa.org_id --ywa
            AND    Aia.Invoice_Amount       = 0
            AND    Aia.Cancelled_Date      IS NULL
            AND    Aia.Payment_Status_Flag  = 'N'
            AND    Apsa.Payment_Status_Flag = 'N'
            AND    Apsa.Checkrun_Id        IS NULL
            --AND    Apsa.Due_Date           <= SYSDATE
            AND    Aia.wfapproval_status =  'WFAPPROVED'
            AND    Ap_Invoices_Pkg.Get_Approval_Status(Aia.Invoice_Id,
                                                       Aia.Invoice_Amount,
                                                       Aia.Payment_Status_Flag,
                                                       Aia.Invoice_Type_Lookup_Code) IN ('APPROVED', 'UNPAID');

        ----------------------------------------
        -- Curseur de lecture de l'échéancier --
        ----------------------------------------
        CURSOR Cur_Payment_Schedules_2 IS
            SELECT Apsa.*
            /*ETANCHEITE DALKIA 2007*/
            FROM   Ap_Payment_Schedules_All Apsa
            WHERE  Apsa.Invoice_Id IN (SELECT Dalt.Invoice_Id
                                       FROM   Dka_Ap_Lettrage_0_Tmp Dalt)
            AND   ( Apsa.Payment_Priority           != 3 OR
                    Apsa.PAYMENT_METHOD_CODE != (SELECT Alc.Lookup_Code
                                                        FROM   Ap_Lookup_Codes Alc
                                                        WHERE  Alc.Lookup_Type     = 'PAYMENT METHOD'
                                                        AND    Alc.Lookup_Code = 'CHECK') OR
                    Apsa.Hold_Flag                  != 'N')
            FOR UPDATE OF Apsa.Payment_Priority,
                          Apsa.PAYMENT_METHOD_CODE,
                          Apsa.Hold_Flag,
                          Apsa.Last_Update_Date,
                          Apsa.Last_Updated_By,
                          Apsa.Last_Update_Login;

        -------------------------------------
        -- Curseur de lecture des blocages --
        -------------------------------------
        CURSOR Cur_Holds IS
            SELECT Aha.*
            FROM   Ap_Holds_ALL Aha
            WHERE  Aha.Invoice_Id IN (SELECT Dalt.Invoice_Id
                                      FROM   Dka_Ap_Lettrage_0_Tmp Dalt)
            AND    Aha.Release_Lookup_Code IS NULL
            FOR UPDATE OF Aha.Release_Lookup_Code,
                          Aha.Release_Reason,
                          Aha.Last_Updated_By,
                          Aha.Last_Update_Date,
                          Aha.Last_Update_Login;

        -------------------------------------------------------------------
        -- Curseur de lecture des blocages au niveau du site fournisseur --
        -------------------------------------------------------------------
        CURSOR Cur_Vendor_Sites IS
            SELECT assa.*
            /*ETANCHEITE DALKIA 2007*/
            FROM   AP_SUPPLIER_SITES_ALL assa --YWA
            WHERE  assa.Vendor_Site_Id IN (SELECT Dalt.Vendor_Site_Id
                                           FROM   Dka_Ap_Lettrage_0_Tmp Dalt)
            AND    assa.Hold_All_Payments_Flag = 'Y'
            FOR UPDATE OF assa.Hold_All_Payments_Flag,
            --               assa.Attribute6;      -- Modif EMA du 21/08/2008
                          assa.Attribute9;         -- Modif EMA du 21/08/2008

        Rec_Payment_Schedules_1         Cur_Payment_Schedules_1%ROWTYPE;
        Rec_Invoices                    Cur_Invoices%ROWTYPE;
        Rec_Payment_Schedules_2         Cur_Payment_Schedules_2%ROWTYPE;
        Rec_Holds                       Cur_Holds%ROWTYPE;
        Rec_Vendor_Sites                Cur_Vendor_Sites%ROWTYPE;
        Vn_Nb_Maj                       NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Debug_Message('Maj_Mouvements (+)');

        Pv_Errbuf      := NULL;
        Pn_Retcode     := 0;
        Pn_Nb_Factures := 0;

        ---------------------------------------------------------------------------------
        -- RG3 : Mise à jour des lignes d'échéancier des mouvements à 0 et non annulés --
        ---------------------------------------------------------------------------------
        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 200 (+)');
            OPEN Cur_Payment_Schedules_1;
            LOOP
                FETCH Cur_Payment_Schedules_1 INTO Rec_Payment_Schedules_1;
                EXIT WHEN Cur_Payment_Schedules_1%NOTFOUND;

                /*ETANCHEITE DALKIA 2007*/
                UPDATE Ap_Payment_Schedules_All Apsa
                SET    Apsa.Payment_Status_Flag = 'N',
                       Apsa.Last_Update_Date    = SYSDATE,
                       Apsa.Last_Updated_By     = Fnd_Global.User_Id,
                       Apsa.Last_Update_Login   = Fnd_Global.Login_Id
                WHERE CURRENT OF Cur_Payment_Schedules_1;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Payment_Schedules_1;

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || Vn_Nb_Maj || ' lignes d''échéancier ont été mises à jour');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 200 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 200)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de Ap_Payment_Schedules_All');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Payment_Schedules_1.Invoice_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Payment_Num : ' || Rec_Payment_Schedules_1.Payment_Num);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==========================================================');

                CLOSE Cur_Payment_Schedules_1;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 200 (-)');

                RAISE;
        END;

        --------------------------------------------------------------------------
        -- RG4 : Suppression et insertion des factures dans la table de travail --
        --------------------------------------------------------------------------
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 210 (+)');
            ------------------------------------------------------------
            -- Suppression des enregistrements de la table de travail --
            ------------------------------------------------------------
            DELETE FROM Dka_Ap_Lettrage_0_Tmp;

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT || ' lignes supprimées dans la table Dka_Ap_Lettrage_0_Tmp');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 210 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 210)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la suppression dans Dka_Ap_Lettrage_0_Tmp');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 210 (-)');

                RAISE;
        END;

        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 220 (+)');
            ----------------------------------------------------
            -- Insertion des données dans la table de travail --
            ----------------------------------------------------
            OPEN Cur_Invoices;
            LOOP
                FETCH Cur_Invoices INTO Rec_Invoices;
                EXIT WHEN Cur_Invoices%NOTFOUND;

                INSERT INTO Dka_Ap_Lettrage_0_Tmp
                    (Date_Extraction,
                     Invoice_Id,
                     Invoice_Num,
                     Invoice_Amount,
                     Pay_Group_Lookup_Code,
                     Payment_Method_Lookup_Code,
                     Vendor_Name,
                     Vendor_Site_Id,
                     org_id)
                VALUES
                    (SYSDATE,
                     Rec_Invoices.Invoice_Id,
                     Rec_Invoices.Invoice_Num,
                     Rec_Invoices.Invoice_Amount,
                     Rec_Invoices.Pay_Group_Lookup_Code,
                     Rec_Invoices.PAYMENT_METHOD_CODE,
                     Rec_Invoices.Vendor_Name,
                     Rec_Invoices.Vendor_Site_Id,
                     Rec_Invoices.org_id);

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Invoices;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' lignes insérées dans la table Dka_Ap_Lettrage_0_Tmp');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 220 (-)');

            Pn_Nb_Factures := Vn_Nb_Maj;

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 220)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de l''insertion dans Dka_Ap_Lettrage_0_Tmp');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_id                 : ' || Rec_Invoices.Invoice_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Num                : ' || Rec_Invoices.Invoice_Num);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Amount             : ' || Rec_Invoices.Invoice_Amount);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Cancelled_Date             : ' || Rec_Invoices.Cancelled_Date);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Pay_Group_Lookup_Code      : ' || Rec_Invoices.Pay_Group_Lookup_Code);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> PAYMENT_METHOD_CODE : ' || Rec_Invoices.PAYMENT_METHOD_CODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Vendor_Name                : ' || Rec_Invoices.Vendor_Name);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> org_id                : ' || Rec_Invoices.org_id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');

                CLOSE Cur_Invoices;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 220 (-)');

                RAISE;
        END;

        ------------------------------------------------------------------------------------------------
        -- RG6 + RG7 + RG19 : Mise à jour des codes priorité, du mode de paiement et levée du blocage --
        --                    au niveau de l'échéancier                                               --
        ------------------------------------------------------------------------------------------------
        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 230 (+)');

            OPEN Cur_Payment_Schedules_2;
            LOOP
                FETCH Cur_Payment_Schedules_2 INTO Rec_Payment_Schedules_2;
                EXIT WHEN Cur_Payment_Schedules_2%NOTFOUND;

                /*ETANCHEITE DALKIA 2007*/
                UPDATE Ap_Payment_Schedules_All Apsa
                SET    Apsa.Payment_Priority           = 3,
                      Apsa.PAYMENT_METHOD_CODE = (SELECT Alc.Lookup_Code
                                                        FROM   Ap_Lookup_Codes Alc
                                                        WHERE  Alc.Lookup_Type     = 'PAYMENT METHOD'
                                                        AND    Alc.Lookup_Code = 'CHECK'),--YWA
                       Apsa.Hold_Flag                  = 'N',
                       Apsa.Last_Update_Date           = SYSDATE,
                       Apsa.Last_Updated_By            = Fnd_Global.User_Id,
                       Apsa.Last_Update_Login          = Fnd_Global.Login_Id
                WHERE CURRENT OF Cur_Payment_Schedules_2;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Payment_Schedules_2;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' lignes mises à jour dans Ap_Payment_Schedules_All');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 230 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 230)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de Ap_Payment_Schedules_All');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Payment_Schedules_2.Invoice_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Payment_Num : ' || Rec_Payment_Schedules_2.Payment_Num);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==========================================================');

                CLOSE Cur_Payment_Schedules_2;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 230 (-)');

                RAISE;
        END;

        ------------------------------
        -- RG8 : Levée des blocages --
        ------------------------------
        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 240 (+)');
            OPEN Cur_Holds;
            LOOP
                FETCH Cur_Holds INTO Rec_Holds;
                EXIT WHEN Cur_Holds%NOTFOUND;

                UPDATE Ap_Holds_all Aha -- YWA
                SET    Aha.Release_Lookup_Code = 'APPROVED',
                       Aha.Release_Reason      = (SELECT Alc.Description
                                                  FROM   Ap_Lookup_Codes Alc
                                                  WHERE  Alc.Lookup_Type = 'HOLD CODE'
                                                  AND    Alc.Lookup_Code = 'APPROVED'),
                       Aha.Last_Updated_By     = Fnd_Global.User_Id,
                       Aha.Last_Update_Date    = SYSDATE,
                       Aha.Last_Update_Login   = Fnd_Global.Login_Id
                WHERE CURRENT OF Cur_Holds;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Holds;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' lignes mises à jour dans Ap_Holds_All');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 240 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 240)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de Ap_Holds_All');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Holds.Invoice_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==========================================================');

                CLOSE Cur_Holds;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 240 (-)');

                RAISE;
        END;

        -------------------------------------------------------------
        -- RG18 : Levée des blocages au niveau du site fournisseur --
        -------------------------------------------------------------
        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 250 (+)');
            OPEN Cur_Vendor_Sites;
            LOOP
                FETCH Cur_Vendor_Sites INTO Rec_Vendor_Sites;
                EXIT WHEN Cur_Vendor_Sites%NOTFOUND;

                /*ETANCHEITE DALKIA 2007*/
                UPDATE AP_SUPPLIER_SITES_ALL assa
                SET    assa.Hold_All_Payments_Flag = 'N',
                --        assa.Attribute6             = assa.Hold_All_Payments_Flag     -- Modif EMA du 21/08/2008
                       assa.Attribute9             = assa.Hold_All_Payments_Flag        -- Modif EMA du 21/08/2008
                WHERE CURRENT OF Cur_Vendor_Sites;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Vendor_Sites;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' lignes mises à jour dans AP_SUPPLIER_SITES_ALL');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 250 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Maj_Mouvements (STEP 250)');
                Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de AP_SUPPLIER_SITES_ALL');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Vendor_Sites.Vendor_Site_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==========================================================');

                CLOSE Cur_Vendor_Sites;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 250 (-)');

                RAISE;
        END;


        Dka_Tools_Pkg.Put_Debug_Message('Maj_Mouvements (-)');

    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur dans de la procécure Maj_Mouvements : ' || SQLERRM;
            Pn_Retcode := 2;
            Dka_Tools_Pkg.Put_Debug_Message('Maj_Mouvements (-)');

    END Maj_Mouvements;


    -- -----------------------------------------------------------------------------
    -- Nom              : Campagne_Lettrage
    -- Description      : Procédure de lancement de la campagne de lettrage à 0
    --
    -- PARAMETRES       : Pv_Debug_Switch  Entrée Flag activation diagnostic
    --                                            'Y' : Oui
    --                                            'N' : Non
    --                    Pv_Trace_Switch  Entrée Flag activation analyse
    --                                            'Y' : Oui
    --                                            'N' : Non
    --                    Pv_Checkrun_Name Sortie Nom du lot de règlement
    --                    Pv_Errbuf        Sortie Message d'erreur
    --                    Pn_Retcode       Sortie Code Retour de la procédure
    --                                            '0' : Normal
    --                                            '1' : Avertissement
    --                                            '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Campagne_Lettrage(
                                Pn_Nb_Factures    IN       NUMBER,
                                Pv_Errbuf             OUT  VARCHAR2,
                                Pn_Retcode            OUT  NUMBER)
    IS
        Vv_Period_Name                  Ap_Inv_Selection_Criteria_All.Period_Name%TYPE;
        Vn_Lots_En_Cours                NUMBER;
        /* ETANCHEITE DALKIA 2007 */
        v_template_name VARCHAR2(240);
        v_request_id                    NUMBER;

        Erreur                  EXCEPTION;

        v_TEMPLATE_ID                   ap_payment_templates.TEMPLATE_ID%TYPE;
        v_payment_document_id           ap_payment_templates.payment_document_id%TYPE;
        v_bank_account_id               ap_payment_templates.bank_account_id%TYPE;
        v_payment_exchange_rate_type    ap_payment_templates.payment_exchange_rate_type%TYPE;
        v_payment_profile_id            ap_payment_templates.payment_profile_id %TYPE;
        v_document_rejection_level_c ap_payment_templates.document_rejection_level_code%TYPE;
        v_payment_rejection_level_c  ap_payment_templates.payment_rejection_level_code%TYPE;
        TYPE vt_request_id_Type IS TABLE OF Fnd_Concurrent_requests.request_Id%TYPE INDEX BY BINARY_INTEGER;
        vt_request_id vt_request_id_Type;
        vn_nbre_request BINARY_INTEGER := 0;        
        v_errbuf varchar2(32000);
        v_retcode NUMBER;

        ----------------------------------------
        -- Curseur  pour chaque unité opérationnelle où des mouvements à lettrer qui ont été identifiés--
        ----------------------------------------
        CURSOR Cur_inv_unit_op IS
            SELECT dal.org_id, hou.name
            FROM dka_ap_lettrage_0_tmp dal,
            hr_operating_units  hou
            WHERE hou.organization_id = dal.org_id
            GROUP BY dal.org_id, hou.name;--ywa

        -------------------------------------------------
        -- Curseur de recherche des campagnes en cours --
        -------------------------------------------------
        CURSOR Cur_Lots (p_template_name varchar2) IS
            SELECT ipsr.*
            FROM iby_pay_service_requests ipsr,
                iby_acct_pmt_profiles_vl iapp
            WHERE ipsr.payment_service_request_status NOT IN ('COMPLETED','TERMINATED')
            AND ipsr.payment_profile_id=iapp.payment_profile_id
            AND iapp.system_profile_code = 'RGLT_NUL_CHQ'
            AND ipsr.call_app_pay_service_req_code like p_template_name||'%';

        --Rec_Requests                    Cur_Requests%ROWTYPE;
        Rec_Lots                        Cur_Lots%ROWTYPE;

    BEGIN
        Dka_Tools_Pkg.Put_Debug_Message('Campagne_Lettrage (+)');

        Pv_Errbuf  := NULL;
        Pn_Retcode := 0;

        IF Pn_Nb_Factures = 0 THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Il n''y a aucune facture à traiter');
            Dka_Tools_Pkg.Put_Debug_Message('Campagne_Lettrage (-)');
            RETURN;
        END IF;

        -----------------------------------------------------
        -- RG10 : Composition de la campagne de règlement  --
        -----------------------------------------------------

        -------------------------------------------------------------
        -- Renseignement de la table Ap_Inv_Selection_Criteria_All --
        -------------------------------------------------------------
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (+)');

            FOR c_uo IN Cur_inv_unit_op LOOP

                v_template_name := c_uo.name||'_RGLTNUL';
                g_org_id := c_uo.org_id;
                Dka_Tools_Pkg.Put_Outdebug_Message('template pour les facture de l''uo '||v_template_name);
                ----------------------------------------------
                -- Récupération du template -- YWA -
                ----------------------------------------------
                DECLARE
                    Erreur                  EXCEPTION;
                BEGIN
                    Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du template '||v_template_name);

                    SELECT  template_id,
                        template_name,
                        payment_document_id,
                        bank_account_id,
                        payment_exchange_rate_type,
                        payment_profile_id,
                        document_rejection_level_code,
                        payment_rejection_level_code
                    INTO v_template_id,
                        v_template_name,
                        v_payment_document_id,
                        v_bank_account_id,
                        v_payment_exchange_rate_type,
                        v_payment_profile_id,
                        v_document_rejection_level_c,
                        v_payment_rejection_level_c
                    FROM   ap_payment_templates
                    WHERE template_name =v_template_name;

                EXCEPTION
                    WHEN Erreur THEN
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_Lettrage (STEP 300)');
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la récupération du template');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (-)');
                        RAISE;
                END;

                -----------------------------
                -- Recherche de la période --
                -----------------------------
                DECLARE
                    CURSOR Cur_Period IS
                        SELECT period_name
                        FROM   gl_period_statuses gps,
                               hr_operating_units hou
                        WHERE  gps.set_of_books_id = hou.set_of_books_id
                        AND    gps.closing_status = 'O'
                        AND    trunc(SYSDATE) BETWEEN gps.start_date AND gps.end_date
                        AND    nvl(gps.adjustment_period_flag, 'N') = 'N'
                        AND    gps.application_id = g_ap_app_id
                        AND    hou.organization_id = c_uo.org_id;--YWA
                BEGIN
                    Dka_Tools_Pkg.Put_Debug_Message(' ');
                    Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la période');
                    OPEN Cur_Period;
                    FETCH Cur_Period INTO Vv_Period_Name;
                    IF Cur_Period%ROWCOUNT = 0 THEN
                        CLOSE Cur_Period;
                        RAISE Erreur;
                    END IF;
                    CLOSE Cur_Period;

                    Dka_Tools_Pkg.Put_Debug_Message('==> Vv_Period_Name : ' || Vv_Period_Name);

                EXCEPTION
                    WHEN Erreur THEN
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_Lettrage (STEP 300)');
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la recherche de la période');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (-)');

                        RAISE;
                END;

                -----------------------------------------------------------
                -- Insertion dans la table Ap_Inv_Selection_Criteria_All --
                -----------------------------------------------------------
                BEGIN
                    Dka_Tools_Pkg.Put_Debug_Message(' ');
                    Dka_Tools_Pkg.Put_Debug_Message('==> Insertion dans Ap_Inv_Selection_Criteria_All');

                    --------------------------------------------------------------------------
                    -- RG16 : On vérifie qu'il n'y a pas de campagne de règlements en cours --
                    --------------------------------------------------------------------------
                    Vn_Lots_En_Cours := 0;
                    OPEN Cur_Lots(v_template_name) ;
                    LOOP
                        FETCH Cur_Lots INTO Rec_Lots;
                        EXIT WHEN Cur_Lots%NOTFOUND;

                        Vn_Lots_En_Cours := Vn_Lots_En_Cours + 1;

                        IF Vn_Lots_En_Cours = 1 THEN
                            Dka_Tools_Pkg.Put_Outdebug_Message('==> Le lot de règlement ' || v_template_name||'-'||To_Char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || ' ne peut pas être traité car : ');
                        END IF;
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> Le lot de règlement ' || Rec_Lots.call_app_pay_service_req_code || ' est en cours !');

                    END LOOP;
                    CLOSE Cur_Lots;

                    IF Vn_Lots_En_Cours = 0 THEN

                        Dka_Tools_Pkg.Put_Debug_Message(' ');
                        Dka_Tools_Pkg.Put_Debug_Message('>> Step 310 (+)');
                        Dka_Tools_Pkg.Put_Debug_Message('==> Lancement de la campagne de règlements ' ||v_template_name);

                        BEGIN
                            -- Initialiser org_id
                            Fnd_File.put_line (Fnd_File.output, 'Initialisation de l''environnement');
                            init_environement(Pv_Errbuf, Pn_Retcode);
                            IF Pn_Retcode = 2 THEN
                               Dka_Tools_Pkg.Put_Debug_Message(' ');
                                Dka_Tools_Pkg.Put_Debug_Message('>> Step 311 (+)');
                                Dka_Tools_Pkg.Put_Debug_Message('==> Erreur Initialisation de l''environnement');
                                RAISE Erreur;
                            END IF;
                            ----------------------------------------
                            -- AUTOSELECT : Sélection des données --
                            ----------------------------------------
                            autoselect(Pv_Errbuf,Pn_Retcode,v_request_id, v_TEMPLATE_ID);

                            IF Pn_Retcode = 2
                            THEN
                                Dka_Tools_Pkg.Put_Debug_Message(' ');
                                Dka_Tools_Pkg.Put_Debug_Message('>> Step 312 (+)');
                                Dka_Tools_Pkg.Put_Debug_Message('==> Erreur Lancement de la campagne de règlements');
                            ELSE
                                -- Memorisation de l'id du traitement pour controle plus tard.
                                vn_nbre_request := vn_nbre_request +1;
                                vt_request_id (vn_nbre_request) := v_request_id;    
                            END IF;
                        EXCEPTION
                            WHEN Erreur THEN
                                Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure autoselect (STEP 313)');
                                Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                                Dka_Tools_Pkg.Put_Outdebug_Message('==> autoselect');
                                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                                Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                                Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (-)');

                                RAISE;
                        END;

                    END IF;
                    

                EXCEPTION
                    WHEN OTHERS THEN
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_Lettrage (STEP 300)');
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors d''insertion dans Ap_Inv_Selection_Criteria_All');
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                        Dka_Tools_Pkg.Put_Outdebug_Message('============================================================');
                        Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (-)');

                END;

                Dka_Tools_Pkg.Put_Debug_Message('>> Step 300 (-)');

        END LOOP;

        Dka_Tools_Pkg.Put_Debug_Message('==> Controle de la fin des traitements mis.');
        -- Ctrle de la fin des traitemenys soumis.
        FOR I IN 1..vn_nbre_request
        LOOP
           wait_program_end
                        (p_errbuf     => v_errbuf,
                         p_retcode    => v_retcode,
                         p_request_id => vt_request_id(I) );
        END LOOP;


      END;
        Dka_Tools_Pkg.Put_Debug_Message('Campagne_Lettrage (-)');

    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur dans de la procécure Campagne_Lettrage : ' || SQLERRM;
            Pn_Retcode := 2;
            Dka_Tools_Pkg.Put_Debug_Message('Campagne_Lettrage (-)');

    END Campagne_Lettrage;


    -- -----------------------------------------------------------------------------
    -- Nom              : Identification_Factures
    -- Description      : Procédure de mise à jour des mouvements à 0 et annulées
    --
    -- PARAMETRES       : Pv_Checkrun_Name Sortie Nom du lot de règlement
    --                    Pv_Errbuf        Sortie Message d'erreur
    --                    Pn_Retcode       Sortie Code Retour de la procédure
    --                                            '0' : Normal
    --                                            '1' : Avertissement
    --                                            '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Identification_Factures(Pn_Nb_Factures    IN       NUMBER,
                                      Pv_Errbuf             OUT  VARCHAR2,
                                      Pn_Retcode            OUT  NUMBER) IS

        ---------------------------------------------------------------------
        -- Curseur de lecture des factures payées par le lot de règlements --
        ---------------------------------------------------------------------
        CURSOR Cur_Invoices  IS
            /*SELECT Aipa.Invoice_Id
            /*ETANCHEITE DALKIA 2007*/
            /*FROM   Ap_Checks_All           Aca,
                   Ap_Invoice_Payments_All Aipa
            WHERE  Aca.Checkrun_Name = Pv_Checkrun_Name
            AND    Aca.Check_Id      = Aipa.Check_Id;*/--YWA

            SELECT Aipa.Invoice_Id,
                    Aca.Checkrun_Name,
                    Aipa.org_id
            FROM   Ap_Checks_All           Aca,
                   Ap_Invoice_Payments_All Aipa,
                   Dka_Ap_Lettrage_0_Tmp dal
            WHERE  Aca.Checkrun_Name IN (SELECT checkrun_name FROM ap_inv_selection_criteria_all
            WHERE TO_DATE(CREATION_DATE,'dd/mm/yyyy') = TO_DATE (sysdate,'dd/mm/yyyy'))
                                       --  AND status ='SELECTED')
            AND    Aca.Check_Id      = Aipa.Check_Id
            AND Aipa.Invoice_Id = dal.invoice_id--in (select invoice_id from Dka_Ap_Lettrage_0_Tmp);
            AND  Aipa.org_id = dal.org_id
            AND Aca.org_id      = Aipa.org_id;

        -------------------------------------------------------------------
        -- Curseur de lecture des blocages au niveau du site fournisseur --
        -------------------------------------------------------------------
        CURSOR Cur_Vendor_Sites IS
            SELECT assa.*
            /*ETANCHEITE DALKIA 2007*/
            FROM   Po_Vendor_Sites_All assa
            WHERE  assa.Vendor_Site_Id IN (SELECT Dalt.Vendor_Site_Id
                                           FROM   Dka_Ap_Lettrage_0_Tmp Dalt)
            -- AND    assa.Attribute6 IS NOT NULL       -- Modif EMA du 21/08/2008
            AND    assa.Attribute9 IS NOT NULL          -- Modif EMA du 21/08/2008
            FOR UPDATE OF assa.Hold_All_Payments_Flag,
            --               assa.Attribute6;           -- Modif EMA du 21/08/2008
                          assa.Attribute9;              -- Modif EMA du 21/08/2008

        Rec_Invoices                    Cur_Invoices%ROWTYPE;
        Rec_Vendor_Sites                Cur_Vendor_Sites%ROWTYPE;
        Vn_Nb_Maj                       NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Debug_Message('Identification_Factures (+)');

        Pv_Errbuf  := NULL;
        Pn_Retcode := 0;

        IF Pn_Nb_Factures = 0 THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Il n''y a aucune facture à mettre à jour');
            Dka_Tools_Pkg.Put_Debug_Message('Identification_Factures (-)');
            RETURN;
        END IF;

        ------------------------------------------------------------
        -- RG9 : Mise à jour des factures payées par la campagne  --
        ------------------------------------------------------------
        -- artf2133561 - SPE110 - Optimisation du programme
        /*Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 400 (+)');

            OPEN Cur_Invoices;
            LOOP
                FETCH Cur_Invoices INTO Rec_Invoices;
                EXIT WHEN Cur_Invoices%NOTFOUND;

                -- ETANCHEITE DALKIA 2007
                UPDATE Ap_Invoices_All Aia
                SET    Aia.Attribute2        = Rec_Invoices.Checkrun_Name,
                       Aia.Last_Update_Date  = SYSDATE,
                       Aia.Last_Updated_By   = Fnd_Global.User_Id,
                       Aia.Last_Update_Login = Fnd_Global.Login_Id
                WHERE  Aia.Invoice_Id        = Rec_Invoices.Invoice_Id
                and Aia.org_id = Rec_Invoices.org_id;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Invoices;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' factures mises à jour');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 400 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Identification_Factures (STEP 400)');
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de Ap_Invoices_All');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Invoices.Invoice_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');

                CLOSE Cur_Invoices;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 400 (-)');

                RAISE;
        END;*/

        ----------------------------------------------------------------------
        -- RG18 : Réinitialisation du blocage au niveau du site fournisseur --
        ----------------------------------------------------------------------
        Vn_Nb_Maj := 0;
        BEGIN
            Dka_Tools_Pkg.Put_Debug_Message(' ');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 410 (+)');

            OPEN Cur_Vendor_Sites;
            LOOP
                FETCH Cur_Vendor_Sites INTO Rec_Vendor_Sites;
                EXIT WHEN Cur_Vendor_Sites%NOTFOUND;

                /*ETANCHEITE DALKIA 2007*/
                UPDATE Po_Vendor_Sites_All assa
                -- SET    assa.Hold_All_Payments_Flag = assa.Attribute6,     -- Modif EMA du 21/08/2008
                --        assa.Attribute6             = NULL                 -- Modif EMA du 21/08/2008
                SET    assa.Hold_All_Payments_Flag = assa.Attribute9,        -- Modif EMA du 21/08/2008
                       assa.Attribute9             = NULL                    -- Modif EMA du 21/08/2008
                WHERE CURRENT OF Cur_Vendor_Sites;

                Vn_Nb_Maj := Vn_Nb_Maj + SQL%ROWCOUNT;

            END LOOP;
            CLOSE Cur_Vendor_Sites;

            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vn_Nb_Maj || ' sites fournisseurs mis à jour');
            Dka_Tools_Pkg.Put_Debug_Message('>> Step 410 (-)');

        EXCEPTION
            WHEN OTHERS THEN
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Identification_Factures (STEP 410)');
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la mise à jour de AP_SUPPLIER_SITES_ALL');
                Dka_Tools_Pkg.Put_Outdebug_Message('==> Invoice_Id  : ' || Rec_Vendor_Sites.Vendor_Site_Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');

                CLOSE Cur_Vendor_Sites;
                Dka_Tools_Pkg.Put_Debug_Message('>> Step 410 (-)');

                RAISE;
        END;

        Dka_Tools_Pkg.Put_Debug_Message('Identification_Factures (-)');

    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur dans de la procécure Identification_Factures : ' || SQLERRM;
            Pn_Retcode := 2;
            Dka_Tools_Pkg.Put_Debug_Message('Identification_Factures (-)');

    END Identification_Factures;


    -- -----------------------------------------------------------------------------
    -- Nom              : Main
    -- Description      : Procédure principale du traitement qui enchaîne l'ensemble
    --                    des autres procédures.
    --
    -- PARAMETRES       : Pv_Errbuf       Sortie Message d'erreur
    --                    Pn_Retcode      Sortie Code Retour de la procédure
    --                                           '0' : Normal
    --                                           '1' : Avertissement
    --                                           '2' : Erreur
    --                    Pv_Debug_Switch Entrée Flag activation diagnostic
    --                                           'Y' : Oui
    --                                           'N' : Non
    --                    Pv_Trace_Switch Entrée Flag activation analyse
    --                                           'Y' : Oui
    --                                           'N' : Non
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf            OUT  VARCHAR2,
                   Pn_Retcode           OUT  NUMBER)
                   --Pv_Debug_Switch  IN       VARCHAR2,
                   --Pv_Trace_Switch  IN       VARCHAR2)
    IS

        Vv_Errbuf_Phase1                VARCHAR2(2500);
        Vn_Retcode_Phase1               NUMBER;
        Vv_Errbuf_Phase2                VARCHAR2(2500);
        Vn_Retcode_Phase2               NUMBER;
        Vv_Errbuf_Phase3                VARCHAR2(2500);
        Vn_Retcode_Phase3               NUMBER;
        Vv_Errbuf_Phase4                VARCHAR2(2500);
        Vn_Retcode_Phase4               NUMBER;

        Vn_Nb_Factures                  NUMBER;

    BEGIN
        Dka_Tools_Pkg.Put_Debug_Message('Main (+)');

        Dka_Tools_Pkg.Put_Debug_Message('==> Paramètres du traitement : ');
        --Dka_Tools_Pkg.Put_Debug_Message('==> Pv_Debug_Switch : ' || Pv_Debug_Switch);
        --Dka_Tools_Pkg.Put_Debug_Message('==> Pv_Trace_Switch : ' || Pv_Trace_Switch);


        Vv_Errbuf_Phase1  := NULL;
        Vn_Retcode_Phase1 := 0;
        Vv_Errbuf_Phase2  := NULL;
        Vn_Retcode_Phase2 := 0;
        Vv_Errbuf_Phase3  := NULL;
        Vn_Retcode_Phase3 := 0;
        Vv_Errbuf_Phase4  := NULL;
        Vn_Retcode_Phase4 := 0;

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Execution du traitement');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        --YWA
        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        --Fnd_File.put_line (Fnd_File.output, 'Initiation des variables');
        Dka_Tools_Pkg.Put_Outdebug_Message('Initiation des variables');
        Init(Vv_Errbuf_Phase1, Vn_Retcode_Phase1);
        IF Vn_Retcode_Phase1 = 2 THEN
            Pv_Errbuf  := Vv_Errbuf_Phase1;
            Pn_Retcode := Vn_Retcode_Phase1;
            RAISE Erreur_Programme;
        END IF;

        /* ETANCHEITE DALKIA 2007 */
        /*IF gn_org_id IS NULL THEN
            dka_tools_pkg.put_log_message('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
            pv_errbuf := 'L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée';
            pn_retcode := 2;
            RETURN;
        END IF;*/--YWA

        /* ---------------------------------------------------------------------
        -- Phase 1 : Mise à jour des factures, notes et avoirs à 0 annulés --
        ---------------------------------------------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 1 : Mise à jour des factures, notes et avoirs à 0 annulés');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        Maj_Mouvements_Annules(Vv_Errbuf_Phase1, Vn_Retcode_Phase1);

        IF Vn_Retcode_Phase1 = 2 THEN
            Pv_Errbuf := Vv_Errbuf_Phase1;
            RAISE Erreur_Programme;
        END IF; */--YWA

        -------------------------------------------------------------------------
        -- Phase 2 : Mise à jour des factures, notes et avoirs à 0 non annulés --
        -------------------------------------------------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 1 : Mise à jour des factures, notes et avoirs à 0 non annulés');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        Maj_Mouvements(Vn_Nb_Factures, Vv_Errbuf_Phase2, Vn_Retcode_Phase2);

        IF Vn_Retcode_Phase2 = 2 THEN
            Pv_Errbuf := Vv_Errbuf_Phase2;
            RAISE Erreur_Programme;
        END IF;

        ----------------------------------------
        -- Phase 3 : Campagne de lettrage à 0 --
        ----------------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 2 : Campagne de lettrage à 0');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        --Campagne_Lettrage(Pv_Debug_Switch, Pv_Trace_Switch, Vn_Nb_Factures, Vn_Checkrun_Name, Vv_Errbuf_Phase3, Vn_Retcode_Phase3);--YWA R12
        Campagne_Lettrage(Vn_Nb_Factures,  Vv_Errbuf_Phase3, Vn_Retcode_Phase3);


        IF Vn_Retcode_Phase3 = 2 THEN
            Pv_Errbuf := Vv_Errbuf_Phase3;
            RAISE Erreur_Programme;
        END IF;

        -------------------------------------------
        -- Phase 4 : Identification des factures --
        -------------------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 3 : Identification des factures');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        Identification_Factures( Vn_Nb_Factures, Vv_Errbuf_Phase4, Vn_Retcode_Phase4);

        IF Vn_Retcode_Phase4 = 2 THEN
            Pv_Errbuf := Vv_Errbuf_Phase4;
            RAISE Erreur_Programme;
        END IF;

        COMMIT;

        ------------------------------------------------------------------------
        -- Gestion des codes retour pour sortie en avertissement du programme --
        ------------------------------------------------------------------------
        IF Vn_Retcode_Phase1 = 1 OR
           Vn_Retcode_Phase2 = 1 OR
           Vn_Retcode_Phase3 = 1 OR
           Vn_Retcode_Phase4 = 1 THEN
            Pn_Retcode := 1;
        END IF;

        IF Pn_Retcode = 1 THEN
            Dka_Tools_Pkg.Put_Outdebug_Message(' ');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN AVERTISSEMENT');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

            IF Vn_Retcode_Phase1 = 1 THEN
                Pv_Errbuf := Vv_Errbuf_Phase1;
                Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            END IF;

            IF Vn_Retcode_Phase2 = 1 THEN
                Pv_Errbuf := Vv_Errbuf_Phase2;
                Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            END IF;
            IF Vn_Retcode_Phase3 = 1 THEN
                Pv_Errbuf := Vv_Errbuf_Phase3;
                Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            END IF;
            IF Vn_Retcode_Phase4 = 1 THEN
                Pv_Errbuf := Vv_Errbuf_Phase4;
                Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            END IF;
        END IF;

        Dka_Tools_Pkg.Put_Debug_Message('Main (-)');

    EXCEPTION
        WHEN Warning_Programme THEN
            ROLLBACK;
            Pn_Retcode := 1;
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            Dka_Tools_Pkg.Put_Debug_Message('Main (-)');
        WHEN Erreur_Programme THEN
            ROLLBACK;
            Dka_Tools_Pkg.Put_Outdebug_Message(' ');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            Pn_Retcode := 2;
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            Dka_Tools_Pkg.Put_Debug_Message('Main (-)');
        WHEN OTHERS THEN
            ROLLBACK;
            Dka_Tools_Pkg.Put_Outdebug_Message(' ');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
            Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            Pv_Errbuf  := 'Erreur dans la procécure Main : ' || SQLERRM;
            Pn_Retcode := 2;
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
            Dka_Tools_Pkg.Put_Debug_Message('Main (-)');
    END Main;

END Dka_Sapletmvtzero_Pkg;
/
SHOW ERRORS
EXIT
