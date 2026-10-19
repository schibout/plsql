create or replace PACKAGE BODY DKA_SAPCAMPPREL_PKG AS
-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SAPCAMPPREL_PKG.pkb
-- DESCRIPTION      : DKA_SAPCAMPPREL_PKG Package Body
--
-- AUTEUR           : A.DELTOUR (Capgemini)
-- DATE DE CREATION : 07/06/2007
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 07/11/2007 SL  Modification de la procédure main pour la gestion du compte bancaire.
--                Celui-ci sera retiré le tps de la campagne de prélèvement puisqu'il n'est pas
--                utile et peut être sujet à des erreurs.
-- 26/03/2008 JJA CSP Portabilité 2008
-- 02/03/2009 SL  Modification de la procédure main pour réinitialiser les factures qui sont sur le
--                fournisseur en cours de traitement mais sur un site différent de celui passé
--                en paramètre (ajout Phase1 Suite et Phase2 Suite)
--
-- 22/06/2010 TMS EID20100146_Campagne_prel_gestion_echeance
-- 06/01/2017 OBE Modification - artf2074331 -
-- 02/10/2017 JJA Correction : artf2228879 
-- 28/03/2018 RBE Correction : artf2470765: INC0191103 : SPE118 - Correctif sur lancement campagne Prelevement AP
-- -----------------------------------------------------------------------------

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

E_Erreur_Programme                    EXCEPTION;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Function launch_program_payment(p_errbuf       OUT VARCHAR2,
                                 p_retcode      OUT NUMBER,
                                 p_template_id  IN NUMBER,
                                 p_org_id       IN hr_all_organization_units.organization_id%TYPE,
                                 p_payment_date IN DATE) return NUMBER
 IS

  v_request_id fnd_concurrent_requests.request_id%TYPE;
  v_checkrun_id NUMBER;
  v_checkrun_name VARCHAR2(50);

  v_phase      VARCHAR2(100);
  v_status     VARCHAR2(100);
  v_dev_phase  VARCHAR2(100);
  v_dev_status VARCHAR2(100);
  v_message    VARCHAR2(100);
BEGIN
 
  v_request_id := fnd_request.submit_request(application => 'SQLAP',
                                             program     => 'APXPBASL',
                                             description => NULL,
                                             start_time  => NULL,
                                             sub_request => FALSE,
                                             argument1   => NULL,
                                             argument2   => p_template_id,
                                             argument3   => fnd_date.date_to_canonical(trunc(sysdate)),--fnd_date.date_to_canonical(gd_date_from),
                                             argument4   => NULL,--fnd_date.date_to_canonical(gd_date_from),--fnd_date.date_to_canonical(gd_date_from),
                                             argument5   => fnd_date.date_to_canonical(gd_date_from));

  IF v_request_id = 0 THEN
  
    p_retcode := 2;
    fnd_file.put_line(fnd_file.output,
                      'ERREUR : Le Programme de demande de traitement des règlements' ||
                      chr(10) ||
                      'PROGRAMME  : Le Programme de demande de traitement des règlements');
    dka_tools_pkg.put_log_message('====> ERREUR : Le Programme de demande de traitement des règlements ');
    p_errbuf := ' ERREUR : Le Programme de demande de traitement des règlements ';
  ELSE
    /* g_request_id = 0 */
  
    COMMIT;
  
    fnd_file.put_line(fnd_file.output,
                      'Numéro du Programme de demande de traitement des règlements: ' ||
                      v_request_id);
    dka_tools_pkg.put_log_message('Numéro du Programme de demande de traitement des règlements: ' ||
                                  v_request_id);
    
    --********************************************
    -- Wait for the concurrent program to complete
    --********************************************
    IF NOT (fnd_concurrent.wait_for_request(v_request_id,
                                            20,
                                            0,
                                            v_phase,
                                            v_status,
                                            v_dev_phase,
                                            v_dev_status,
                                            v_message)) THEN
    
      p_errbuf  := v_message;
      p_retcode := 2;
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                        chr(10) || 'MESSAGE : ' || v_message || chr(10));
    END IF;
  
    IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'COMPLETION= ' || v_dev_phase || '/' ||
                        v_dev_status);
      fnd_file.put_line(fnd_file.log,
                        'Statut de fin : ' || v_phase || '/' || v_status);
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'Programme de demande de traitement des règlements en warning ' ||
                        v_request_id);
      v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
      p_retcode := 1;
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
    
      p_retcode := 2;
      v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                   v_message;
    
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Fin anormale du traitement ' ||
                        v_request_id || chr(10) || 'Phase/Statut : ' ||
                        v_dev_phase || '/' || v_dev_status || chr(10) ||
                        'MESSAGE : ' || v_message || chr(10));
      fnd_file.put_line(fnd_file.log,
                        '===> ERREUR : Fin anormale du traitement ' ||
                        v_request_id);
    END IF;
    p_errbuf := v_message;
  
    BEGIN
      SELECT checkrun_id, checkrun_name
        INTO v_checkrun_id, v_checkrun_name
        FROM ap_inv_selection_criteria_all
       WHERE (request_id = v_request_id OR
             request_id IN
             (SELECT request_id
                 FROM fnd_conc_req_summary_v
                WHERE parent_request_id = v_request_id))
         AND rownum = 1;
    
    EXCEPTION
      WHEN OTHERS THEN
        v_checkrun_id   := NULL;
        v_checkrun_name := NULL;
    END;
  
  END IF; 
  
  return v_request_id;

EXCEPTION
  WHEN OTHERS THEN
    p_errbuf  := SQLCODE || ' -' || SQLERRM || ' ';
    p_retcode := 2;
    dka_tools_pkg.put_log_message('launch_program_payment - Erreur... : ' ||
                                  p_errbuf);
    return v_request_id;
END launch_program_payment;

-- -----------------------------------------------------------------------------
-- Nom              : Campagne_prelevement
-- Description      : Procédure de lancement de la campagne de prelevement
--
-- PARAMETRES       : Pv_Debug_Switch  Entrée Flag activation diagnostic
--                                            'Y' : Oui
--                                            'N' : Non
--                    Pv_Trace_Switch  Entrée Flag activation analyse
--                                            'Y' : Oui
--                                            'N' : Non
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
PROCEDURE Campagne_prelevement( Pv_Errbuf            OUT NOCOPY VARCHAR2,
                                Pn_Retcode           OUT NOCOPY NUMBER,
                                Pv_Debug_Switch   IN            VARCHAR2,
                                Pv_Trace_Switch   IN            VARCHAR2
                              ) IS

Vr_Data                         Dka_Parameters%ROWTYPE;
Vv_Batch_Name                   Ap_Pbatch_Set_Lines_All.Batch_Name%TYPE;
Vv_Checkrun_Name                Ap_Inv_Selection_Criteria_All.Checkrun_Name%TYPE;
Vv_Batch_Run_Name               Ap_Inv_Selection_Criteria_All.Batch_Run_Name%TYPE;
Vv_Region                       VARCHAR2(3) := NULL;
Vv_Responsibility_Key           Fnd_responsibility.Responsibility_Key%TYPE;
Vn_Responsibility_Id            Fnd_Responsibility.Responsibility_Id%TYPE;
Vn_Application_Id               Fnd_Responsibility.Application_Id%TYPE;
Vv_Base_Currency_Code           Ap_System_Parameters.Base_Currency_Code%TYPE;
Vv_Bank_Account_Name            Ap_Bank_Accounts.Bank_Account_Name%TYPE;
Vv_Period_Name                  Ap_Inv_Selection_Criteria_All.Period_Name%TYPE;
Vn_First_Available_Document     Ap_Inv_Selection_Criteria_All.First_Available_Document%TYPE;
Vn_Total_Available_Document     Ap_Check_Stocks_All.Last_Available_Document_Num%TYPE;
Vn_Lots_En_Cours                NUMBER := 0;
Vn_check_stock_id               Ap_Check_Stocks_All.Check_Stock_Id%TYPE;
Vd_pay_thru_date                Ap_Inv_Selection_Criteria_All.Pay_Thru_Date%TYPE;
Vd_PAY_FROM_DATE                Ap_Inv_Selection_Criteria_All.PAY_FROM_DATE%TYPE;
Vv_Format_Program_Name          Ap_Payment_Programs.Program_Name%TYPE;
Vn_Interval                     NUMBER := 10;
Vn_Max_Wait                     NUMBER := 0;
VCheckrun_ID                    NUMBER := 0;
p_payreq_id                     NUMBER;
v_l_return_status               NUMBER;
Vv_Phase                        VARCHAR2(80);
Vv_Status                       VARCHAR2(80);
Vv_Dev_Phase                    VARCHAR2(30);
Vv_Dev_Status                   VARCHAR2(30);
Vv_Message                      VARCHAR2(240);
Vv_Message_Info                 VARCHAR2(240);
vn_request_id                   NUMBER;

vv_exchange_rate_type   VARCHAR2(80);
vv_bank_account_id      NUMBER;
vn_template_id          NUMBER;

----------------------------------------
-- Curseur de lecture des traitements --
----------------------------------------
CURSOR Cur_Requests (Pn_Parent_Request_Id NUMBER) IS
     SELECT Fcr.Request_Id,
            Fcpv.User_Concurrent_Program_Name
     FROM   Fnd_Concurrent_Requests     Fcr,
            Fnd_Concurrent_Programs_Vl  Fcpv
     WHERE  Fcr.Parent_Request_Id     = Pn_Parent_Request_Id
     AND    Fcr.Concurrent_Program_Id = Fcpv.Concurrent_Program_Id
     ORDER BY Fcr.Request_Id;

-------------------------------------------------
-- Curseur de recherche des campagnes en cours --
-------------------------------------------------
CURSOR Cur_Lots (Pv_Bank_Account_Name VARCHAR2)
IS
    SELECT Aisca.*
    FROM   ap_invoice_selection_criteria Aisca 
    WHERE  Aisca.Bank_Account_Name          = Pv_Bank_Account_Name
    AND    Aisca.PAYMENT_METHOD_CODE = 'WIRE'  
    AND    Aisca.Org_Id = gn_org_id
    AND    Aisca.Status NOT IN ('TERMINATED','CONFIRMED','CANCELLED NO PAYMENTS','CANCELED');

Rec_Requests                    Cur_Requests%ROWTYPE;
Rec_Lots                        Cur_Lots%ROWTYPE;

BEGIN
  Dka_Tools_Pkg.Put_Debug_Message('Start - Campagne_prelevement (+)');

  Pv_Errbuf  := NULL;
  Pn_Retcode := 0;

  IF gn_nb_factures = 0 THEN
     Dka_Tools_Pkg.Put_Outdebug_Message('==> Il n''y a aucune facture à traiter');
     Dka_Tools_Pkg.Put_Debug_Message('End - Campagne_prelevement (-)');
     RETURN;
  ELSE
    -------------------------------------------------------------
    -- Recherche de la date de selection du lot                --
    -------------------------------------------------------------
    BEGIN
      Dka_Tools_Pkg.Put_Debug_Message('==> Date de selection du lot (+)');

      SELECT MAX(Due_date)
      INTO   Vd_pay_thru_date
      FROM   dka_ap_prelevement_tmp;

      Dka_Tools_Pkg.Put_Debug_Message('==> Date de selection du lot (-)');
      Dka_Tools_Pkg.Put_Debug_Message('==> Vd_pay_thru_date : ' || Vd_pay_thru_date);
    EXCEPTION
      WHEN OTHERS THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (PAY_THRU_DATE)');
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la récupération de la date de selection du lot');
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Debug_Message('==> Date de selection du lot (-)');

        RAISE;
    END;
  END IF;

  -------------------------------------------------------------
  -- Renseignement de la table Ap_Inv_Selection_Criteria_All --
  -------------------------------------------------------------
  BEGIN
    Dka_Tools_Pkg.Put_Debug_Message('==> Build Batch name (+)');

    ----------------------------------------------
    -- Récupération du nom du lot de règlements --
    ----------------------------------------------
    DECLARE
     E_Erreur                  EXCEPTION;
    BEGIN
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du lot de règlements (+)');

      Dka_Tools_Pkg.Get_Parameter('DKA_SAPCAMPPREL',
                                  'AP_BATCH_NAME',
                                   Vr_Data,
                                   Pn_Retcode,
                                   Pv_Errbuf);

      IF Pn_Retcode != 0 THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (AP_BATCH_NAME)');
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la récupération du nom du lot de règlements');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du lot de règlements (-)');

        RAISE E_Erreur;
      END IF;

      Vv_Batch_Run_Name := To_Char(SYSDATE, 'YYYYMMDD-HH24MISS');
      Dka_Tools_Pkg.Put_Debug_Message('==> avant vr_data');
      Vv_Batch_Name     := Vr_Data.Varchar2_Value;
       Dka_Tools_Pkg.Put_Debug_Message('==> apres vr_data');

      Dka_Tools_Pkg.Put_Debug_Message('==> avant run_id');
      Vv_Checkrun_Name  := Vv_Batch_Run_Name || '-' || Vv_Batch_Name;
      Dka_Tools_Pkg.Put_Debug_Message('==> apres run_id');

      Dka_Tools_Pkg.Put_Debug_Message('==> Checkrun Name : ' || Vv_Checkrun_Name);
      --Dka_Tools_Pkg.Put_Debug_Message('==> Checkrun ID : ' || Vv_Checkrun_Id);
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du lot de règlements (-)');

    EXCEPTION
      WHEN E_Erreur THEN
        RAISE;
      WHEN OTHERS THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (AP_BATCH_NAME2)');
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la récupération du nom du lot de règlements');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Gn_vendor_site_id :' || gn_vendor_site_id);
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Gn_org_id :' || Gn_org_id);
        Dka_Tools_Pkg.Put_Outdebug_Message('=====================================================================');
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du lot de règlements (-)');
        Dka_Tools_Pkg.Put_Debug_Message('==> erreur sql '|| sqlerrm );
    END;

    ----------------------------
    -- Recherche de la devise --
    ----------------------------
    BEGIN

      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la devise (+)');

      SELECT Asp.Base_Currency_Code
      INTO   Vv_Base_Currency_Code
      FROM   Ap_System_Parameters  Asp,
             Gl_Sets_Of_Books      Gsb
      WHERE  Asp.Set_Of_Books_Id = Gsb.Set_Of_Books_Id
      AND Asp.org_id = gn_org_id   
      ;

      Dka_Tools_Pkg.Put_Debug_Message('==> Vv_Base_Currency_Code : ' || Vv_Base_Currency_Code);
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la devise (-)');

    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('====================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (CURRENCY_CODE)');
            Dka_Tools_Pkg.Put_Outdebug_Message('====================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la recherche de la devise');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
            Dka_Tools_Pkg.Put_Outdebug_Message('===========================================================');
            Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la devise (-)');

            RAISE;
    END;

    -----------------------------------------
    -- Recherche du nom du compte bancaire --
    -----------------------------------------
    BEGIN

      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du compte bancaire (+)');

      SELECT ceb.bank_account_name, ceb.bank_account_id
      INTO   Vv_Bank_Account_Name, vv_bank_account_id
      FROM ce_bank_accounts ceb
      WHERE ceb.bank_account_id  = gn_bank_account_id
      ;
      
      Dka_Tools_Pkg.Put_Debug_Message('==> Vv_Bank_Account_Name : ' || Vv_Bank_Account_Name);
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du compte bancaire (-)');

    EXCEPTION
      WHEN OTHERS THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (BANK_ACCOUNT_NAME)');
        Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la recherche du nom du compte bancaire');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> gn_Bank_Account_Id : '|| Gn_Bank_Account_Id);
        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
        Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
        Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du nom du compte bancaire (-)');

        RAISE;
    END;
    
    -----------------------------------------
    -- Recherche PPP et Exchange_rate_type --
    -----------------------------------------    
    
   BEGIN

        Dka_Tools_Pkg.Put_Debug_Message(' ');
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du PPP et Exchange_rate_type (+)');

        
        SELECT fnd_profile.VALUE('AR_DEFAULT_EXCHANGE_RATE_TYPE') 
        INTO vv_exchange_rate_type
        FROM dual;
        
        SELECT template_id
        INTO vn_template_id
        FROM AP_PAYMENT_TEMPLATES app,
        hr_all_organization_units haou
        WHERE template_name = haou.name||'_PRELEVEMENT_AUTO'
        AND haou.organization_id = gn_Org_id;
        
        
    EXCEPTION
      WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement');
      Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la recherche du PPP et Exchange_rate_type');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
      Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
      Dka_Tools_Pkg.Put_Outdebug_Message('=======================================================================');
      Dka_Tools_Pkg.Put_Debug_Message('==> Recherche du PPP et Exchange_rate_type (-)');

      RAISE;
    END;


    -----------------------------
    -- Recherche de la période --
    -----------------------------
    DECLARE
      CURSOR Cur_Period IS
          SELECT Gps.Period_Name
          FROM   Gl_Period_Statuses    Gps,
                 Ap_System_Parameters  Asp
          WHERE  Gps.Set_Of_Books_Id  = Asp.Set_Of_Books_Id
          AND    Gps.Closing_Status   = 'O'
          AND    Trunc(SYSDATE) BETWEEN Gps.Start_Date
                                AND     Gps.End_Date
          AND    Nvl(Gps.Adjustment_Period_Flag, 'N') = 'N';

      E_Erreur                  EXCEPTION;

    BEGIN
        Dka_Tools_Pkg.Put_Debug_Message(' ');
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la période courante (+)');

        OPEN Cur_Period;
        FETCH Cur_Period INTO Vv_Period_Name;
        IF Cur_Period%ROWCOUNT = 0 THEN
            CLOSE Cur_Period;
            RAISE E_Erreur;
        END IF;
        CLOSE Cur_Period;

        Dka_Tools_Pkg.Put_Debug_Message('==> Vv_Period_Name : ' || Vv_Period_Name);
        Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la période courante (-)');

    EXCEPTION
        WHEN E_Erreur THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (PERIOD_NAME)');
            Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de la recherche de la période');
            Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
            Dka_Tools_Pkg.Put_Outdebug_Message('===========================================================');
            Dka_Tools_Pkg.Put_Debug_Message('==> Recherche de la période courante (-)');

            RAISE;
    END;

  BEGIN

     OPEN Cur_Lots (Vv_Bank_Account_Name);
      LOOP
          FETCH Cur_Lots INTO Rec_Lots;
          EXIT WHEN Cur_Lots%NOTFOUND;
          Vn_Lots_En_Cours := Vn_Lots_En_Cours + 1;

          IF Vn_Lots_En_Cours = 1 THEN
              Dka_Tools_Pkg.Put_Outdebug_Message('==> Le lot de règlement ' || Vv_Checkrun_Name || ' ne peut pas être traité car : ');
          END IF;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le lot de règlement ' || Rec_Lots.Checkrun_Name || ' est en cours !');

      END LOOP;
      CLOSE Cur_Lots;
      
    EXCEPTION
      WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Outdebug_Message('====================================================================================');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (Ap_Inv_Selection_Criteria_All)');
      Dka_Tools_Pkg.Put_Outdebug_Message('====================================================================================');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de l''insertion dans Ap_Inv_Selection_Criteria_All');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLCODE : ' || SQLCODE);
      Dka_Tools_Pkg.Put_Outdebug_Message('==> SQLERRM : ' || SQLERRM);
      Dka_Tools_Pkg.Put_Outdebug_Message('====================================================================================');
      Dka_Tools_Pkg.Put_Debug_Message('==> Insertion dans Ap_Inv_Selection_Criteria_All (-)');

      RAISE;
    END;
   
    Dka_Tools_Pkg.Put_Debug_Message('==> Build Batch name (-)');

  END;
  

  -------------------------------------------
  -- Lancement de la campagne de règlement --
  -------------------------------------------
  IF Vn_Lots_En_Cours = 0 THEN
    BEGIN
      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('==> Lancement de la campagne de règlements (+)');
      
      vn_request_id := launch_program_payment( Pv_Errbuf,
                                               Pn_Retcode,
                                               vn_template_id,
                                               gn_Org_id,
                                               gd_date_to);

      ------------------------------------------
      -- Récupération du numéro de traitement --
      ------------------------------------------
      IF Pn_Retcode IN (2, 3) THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================================');
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ERREUR dans de la procécure Campagne_prelevement (APXPBASL)');
          Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================================');
          Dka_Tools_Pkg.Put_Outdebug_Message('==> La campagne de règlements n''a pas été lancée !!!');
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Outdebug_Message('==================================================================================');
      ELSE
          Pn_Retcode := 0;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Campagne de règlements sous le numéro de traitement : ' || vn_request_id);
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Lot de règlements : ' || Vv_Checkrun_Name);
      END IF;

      Dka_Tools_Pkg.Put_Debug_Message('==> Lancement de la campagne de règlements (-)');
    END;
  END IF;

  Dka_Tools_Pkg.Put_Debug_Message('End - Campagne_prelevement (-)');

EXCEPTION
    WHEN OTHERS THEN
        Pv_Errbuf  := 'Erreur dans de la procécure Campagne_prelevement : ' || SQLERRM;
        Pn_Retcode := 2;
        Dka_Tools_Pkg.Put_Debug_Message('End - Campagne_prelevement (-)');

END Campagne_prelevement;
-- -----------------------------------------------------------------------------
-- Nom              : main
-- Description      : Procédure principale du traitement qui enchaîne l'ensemble
--                    des autres procédures.
--
-- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
--                    Pn_Retcode        Sortie Code Retour de la procédure
--                                           '0' : Normal
--                                           '1' : Avertissement
--                                           '2' : Erreur
--                    Pn_org_id         Identifiant de l unite operationnelle
--                    Pn_vendor_id      Identifiant du fournisseur
--                    Pn_vendor_site_id Identifiant du site fournisseur
--                    Pv_date_from      Date de debut de selection
--                    Pv_date_to        Date de debut de selection
--                    Pv_society        Societe
--                    Pv_region         Region
--                    Pv_bank_account_id identifiant du compte bancaire
--                    Pv_Debug_Switch   Entrée Flag activation diagnostic
--                                           'Y' : Oui
--                                           'N' : Non
--                    Pv_Trace_Switch   Entrée Flag activation analyse
--                                           'Y' : Oui
--                                           'N' : Non
--
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-- -----------------------------------------------------------------------------
PROCEDURE Main(Pv_Errbuf            OUT NOCOPY VARCHAR2,
               Pn_Retcode           OUT NOCOPY NUMBER,
               Pn_org_id          IN           NUMBER, --RBE artf2470765
               Pn_vendor_id       IN           NUMBER,
               Pn_vendor_site_id  IN           NUMBER,
               Pv_date_from       IN           VARCHAR2,
               Pv_date_to         IN           VARCHAR2,
               Pn_bank_account_id IN           NUMBER,
               Pv_Debug_Switch    IN           VARCHAR2,
               Pv_Trace_Switch    IN           VARCHAR2) IS

Vv_Errbuf                VARCHAR2(2500) := NULL;
Vn_Retcode               NUMBER         := 0;
BEGIN
  Dka_Tools_Pkg.Put_Debug_Message('Start - Main (+)');

  Dka_Tools_Pkg.Put_Debug_Message('==> Paramètres du traitement : ');
  Dka_Tools_Pkg.Put_Debug_Message('==> Pn_org_id          : ' || Pn_org_id); --RBE artf2470765
  Dka_Tools_Pkg.Put_Debug_Message('==> Pn_vendor_id       : ' || Pn_vendor_id);
  Dka_Tools_Pkg.Put_Debug_Message('==> Pn_vendor_site_id  : ' || Pn_vendor_site_id);
  Dka_Tools_Pkg.Put_Debug_Message('==> Pv_date_from       : ' || TRUNC(fnd_date.canonical_to_date(pv_date_from)));
  Dka_Tools_Pkg.Put_Debug_Message('==> Pv_date_to         : ' || TRUNC(fnd_date.canonical_to_date(pv_date_to)));
  Dka_Tools_Pkg.Put_Debug_Message('==> Pn_bank_account_id : ' || Pn_bank_account_id);
  Dka_Tools_Pkg.Put_Debug_Message('==> Pv_Debug_Switch    : ' || Pv_Debug_Switch);
  Dka_Tools_Pkg.Put_Debug_Message('==> Pv_Trace_Switch    : ' || Pv_Trace_Switch);
  
  /* --RBE artf2470765
  Dka_Tools_Pkg.Put_Debug_Message('==> gn_Org_id          : ' || gn_Org_id);

  IF gn_Org_id IS NULL THEN
   Dka_Tools_Pkg.Put_Debug_Message('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
   raise_application_error(-20001, 'L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
  END IF;
  */
  ----------------------------------
  -- initialisation des variables --
  ----------------------------------
  gt_ap_prel_tmp.DELETE;
  
  gn_Org_id           := pn_org_id;   --RBE artf2470765
  gn_bank_account_id  := pn_bank_account_id;
  gn_vendor_id        := Pn_vendor_id;
  gn_vendor_site_id   := Pn_vendor_site_id;
  
  gd_date_from        := fnd_date.canonical_to_date(pv_date_from);
  gd_date_to          := fnd_date.canonical_to_date(pv_date_to);

  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Execution du traitement');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  ----------------------------------------------------------------
  -- Phase 0 : Suppression des données de la derniere campagne  --
  ----------------------------------------------------------------
  DELETE FROM DKA_AP_PRELEVEMENT_TMP;

  ------------------------------------------------------------------------------
  -- Phase 1 : Identification des factures antérieures pour réinitialisation  --
  -- Type    : standard                                                       --
  -- Approuvés, non annulés, non payés                                        --
  -- invoice_date < Pd_date_from                                              --
  -- Mode de paiement = WIRE                                                  --
  -- Priorité = 33                                                            --
  -- Classe de réglement de la société = Pv_society                           --
  -- pour le fournisseur et le site passé en parametre                        --
  ------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 1 : Identification des factures antérieures au ' || Pv_date_from || '  pour réinitialisation');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  Dka_Tools_Pkg.Put_Debug_Message('==> Select reinitialized invoices');

  SELECT 'REINITIALIZED',
         SYSDATE,
         aia.invoice_id,
         aia.invoice_num,
         aia.invoice_date,
         aia.invoice_amount,
         aia.cancelled_date,
         aia.pay_group_lookup_code,
         aia.PAYMENT_METHOD_CODE,--ray
         aia.exclusive_payment_flag,
         apsa.payment_num,
         apsa.due_date,
         apsa.payment_priority,
         pv.vendor_name,
         pvsa.vendor_site_code
  BULK COLLECT INTO gt_ap_prel_tmp
  FROM   ap_invoices_all                aia,--CSP Portabilité 2008    R12 ( ap_invoices ==> ap_invoices_all )
         ap_payment_schedules_all   apsa,
         ap_suppliers                 pv,   -- R12 ( po_vendors ==> ap_suppliers )
         ap_supplier_sites_all            pvsa   -- R12 ( po_vendor_sites ==> ap_supplier_sites_all )
  WHERE  aia.invoice_id = apsa.invoice_id
  AND    aia.vendor_id = pv.vendor_id
  AND    aia.vendor_site_id = pvsa.vendor_site_id
  AND    pvsa.vendor_id = pv.vendor_id
  AND    pv.vendor_id = pn_vendor_id
  AND    pvsa.vendor_site_id = pn_vendor_site_id
  AND    aia.cancelled_date IS NULL
  AND    aia.invoice_type_lookup_code = 'STANDARD'
  AND    aia.payment_status_flag  = 'N'
  AND    aia.org_id = gn_org_id 
  AND    aia.invoice_date < TRUNC(TO_DATE(pv_date_from,'YYYY/MM/DD HH24:MI:SS'))
  AND    apsa.due_date < TRUNC(TO_DATE(pv_date_from,'YYYY/MM/DD HH24:MI:SS'))
  --AND    SUBSTR(aia.pay_group_lookup_code,1,4) = pv_society      --R12 - les classes de règlements ne vont plus être préfixées par le code société ni région, le cloisonnement des données se fera naturellement par les UO qui vont représenter le couple société/région
  AND    apsa.payment_status_flag = 'N'
  AND    apsa.PAYMENT_METHOD_CODE = 'WIRE'
  AND    apsa.payment_priority = 33
  AND    apsa.org_id = gn_org_id 
  AND    pvsa.org_id = gn_org_id      -- R12 -  afficher uniquement les sites fournisseurs associés à l?UO de l?utilisateur
  AND    ap_invoices_pkg.get_approval_status(aia.invoice_id,
                                             aia.invoice_amount,
                                             aia.payment_status_flag,
                                             aia.invoice_type_lookup_code) IN ('APPROVED', 'UNPAID');

  Dka_Tools_Pkg.Put_Outdebug_Message('==> Nombre de factures identifiées et à réinititaliser : ' || gt_ap_prel_tmp.COUNT);

  ---------------------------------------------------------------------------
  -- Phase 2 : Mise à jour des factures antérieures identifiées en phase 1 --
  -- Champs : payment_priority = 99                                        --
  --          exclusive_payment_flag = N                                   --
  ---------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 2 : Mise à jour des factures antérieures identifiées en phase 1');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  IF gt_ap_prel_tmp.COUNT <> 0 THEN

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall insert invoices to be reinitialized');

    FORALL i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST

      INSERT INTO dka_ap_prelevement_tmp VALUES gt_ap_prel_tmp(i);

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_invoices_all.exclusive_payment_flag');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_invoices_all aia
      SET    aia.exclusive_payment_flag = 'N',
             aia.last_update_date       = SYSDATE,
             aia.last_updated_by        = gn_userid,
             aia.last_update_login      = gn_login_id
      WHERE  aia.invoice_id = gt_ap_prel_tmp(i).invoice_id;
    END LOOP;
    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_payment_schedules_all.payment_priority');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_Payment_Schedules_All apsa
      SET    apsa.payment_priority  = 99,
             apsa.Last_Update_Date  = SYSDATE,
             apsa.Last_Updated_By   = gn_userid,
             apsa.Last_Update_Login = gn_login_id
      WHERE  apsa.invoice_id = gt_ap_prel_tmp(i).invoice_id
      AND    apsa.payment_num = gt_ap_prel_tmp(i).payment_num;
    END LOOP;

    Dka_Tools_Pkg.put_outdebug_message('*** Liste des factures réinitialisées ***');
    Dka_Tools_Pkg.put_outdebug_message('"N° Facture                            "'|| ' | ' ||'"Date Facture"' || ' | ' || '"Montant Facture"' || ' | ' || '"Classe de Réglement"');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      Dka_Tools_Pkg.put_outdebug_message(RPAD(gt_ap_prel_tmp(i).invoice_num,40) || ' | ' || RPAD(gt_ap_prel_tmp(i).invoice_date,14) || ' | ' || LPAD(gt_ap_prel_tmp(i).invoice_amount,17) || ' | ' || gt_ap_prel_tmp(i).pay_group_lookup_code);
    END LOOP;

  ELSE
    Dka_Tools_Pkg.Put_Outdebug_Message('==> Aucune mise à jour à faire');
  END IF;

  ------------------------------------------------------------------------------------
  -- Phase 3 : Identification des factures sur les autres sites du            --
  --                 fournisseurs pour réinitialisation                             --
  -- Type    : standard                                                             --
  -- Approuvés, non annulés, non payés                                              --
  -- Site fournisseur autre que celui passé en paramètre                            --
  -- Mode de paiement = WIRE
  -- Classe de règlement : passé en paramètre                                                      --
  -- Priorité = 33                                                                  --
  -- Classe de réglement de la société = Pv_society                                 --
  -- pour le fournisseur et le site passé en parametre                              --
  ------------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 3 : Identification des factures sur les autres sites du fournisseur');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  Dka_Tools_Pkg.Put_Debug_Message('==> Select reinitialized invoices');

 SELECT 'REINITIALIZED',
         SYSDATE,
         aia.invoice_id,
         aia.invoice_num,
         aia.invoice_date,
         aia.invoice_amount,
         aia.cancelled_date,
         aia.pay_group_lookup_code,
         aia.PAYMENT_METHOD_CODE,--ray
         aia.exclusive_payment_flag,
         apsa.payment_num,
         apsa.due_date,
         apsa.payment_priority,
         pv.vendor_name,
         (select pvsa.VENDOR_SITE_CODE
          from     po_vendor_sites pvsa                  --  R12 (po_vendor_sites ==> ap_supplier_sites_all)
          where    pvsa.vendor_site_id = aia.vendor_site_id
          and      pvsa.vendor_id = pv.vendor_id
          ) vendor_site_code --mis ici pour des raisons de performances ...
  BULK COLLECT INTO gt_ap_prel_tmp
  FROM   ap_invoices_all                aia,--CSP Portabilité 2008  R12 ( ap_invoices ==> ap_invoices_all)
         ap_payment_schedules_all   apsa,
         ap_suppliers                 pv                          --R12 ( po_vendors ==> ap_suppliers)
  WHERE  aia.invoice_id = apsa.invoice_id
  AND    aia.vendor_id = pv.vendor_id
  AND    aia.vendor_site_id != pn_vendor_site_id
  AND    pv.vendor_id = pn_vendor_id
  AND    aia.cancelled_date IS NULL
  AND    aia.invoice_type_lookup_code = 'STANDARD'
  AND    aia.org_id = gn_org_id 
  -- AND    SUBSTR(aia.pay_group_lookup_code,1,4) = pv_society    R12 - les classes de règlements ne vont plus être préfixées par le code société ni région, le cloisonnement des données se fera naturellement par les UO qui vont représenter le couple société/région
  AND    apsa.payment_status_flag = 'N'
  AND    apsa.PAYMENT_METHOD_CODE = 'WIRE' --ray
  AND    apsa.payment_priority = 33
  AND    apsa.org_id = gn_org_id 
  --AND    aia.pay_group_lookup_code = Pv_pay_group
  AND    ap_invoices_pkg.get_approval_status(aia.invoice_id,
                                             aia.invoice_amount,
                                             aia.payment_status_flag,
                                             aia.invoice_type_lookup_code) IN ('APPROVED', 'UNPAID');

  Dka_Tools_Pkg.Put_Outdebug_Message('==> Nombre de factures identifiées et à réinititaliser : ' || gt_ap_prel_tmp.COUNT);


  --------------------------------------------------------------------------------------
  -- Phase 4 : Mise à jour des factures antérieures identifiées en phase1 Suite --
  -- Champs : payment_priority = 99                                                   --
  --          exclusive_payment_flag = N                                              --
  --------------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 4 : Mise à jour des factures sur autres sites identifiées en phase 1 Suite');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  IF gt_ap_prel_tmp.COUNT <> 0 THEN

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall insert invoices to be reinitialized');

    FORALL i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST

      INSERT INTO dka_ap_prelevement_tmp VALUES gt_ap_prel_tmp(i);

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_invoices_all.exclusive_payment_flag');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_invoices_all aia
      SET    aia.exclusive_payment_flag = 'N',
             aia.last_update_date       = SYSDATE,
             aia.last_updated_by        = gn_userid,
             aia.last_update_login      = gn_login_id
      WHERE  aia.invoice_id = gt_ap_prel_tmp(i).invoice_id;
    END LOOP;
    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_payment_schedules_all.payment_priority');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_Payment_Schedules_All apsa
      SET    apsa.payment_priority  = 99,
             apsa.Last_Update_Date  = SYSDATE,
             apsa.Last_Updated_By   = gn_userid,
             apsa.Last_Update_Login = gn_login_id
      WHERE  apsa.invoice_id = gt_ap_prel_tmp(i).invoice_id
      AND    apsa.payment_num = gt_ap_prel_tmp(i).payment_num;
    END LOOP;

    Dka_Tools_Pkg.put_outdebug_message('*** Liste des factures réinitialisées ***');
    Dka_Tools_Pkg.put_outdebug_message('"N° Facture                            "'|| ' | ' ||'"Date Facture"' || ' | ' || '"Montant Facture"' || ' | ' || '"Classe de Réglement"');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      Dka_Tools_Pkg.put_outdebug_message(RPAD(gt_ap_prel_tmp(i).invoice_num,40) || ' | ' || RPAD(gt_ap_prel_tmp(i).invoice_date,14) || ' | ' || LPAD(gt_ap_prel_tmp(i).invoice_amount,17) || ' | ' || gt_ap_prel_tmp(i).pay_group_lookup_code);
    END LOOP;

  ELSE
    Dka_Tools_Pkg.Put_Outdebug_Message('==> Aucune mise à jour à faire');
  END IF;

  ----------------------------------------------------------------------------------
  -- Phase 5 : Identification des factures comprises dans la fourchette des dates --
  -- Type    : standard                                                           --
  -- Approuvés, non annulés, non payés                                            --
  -- invoice_date >= Pd_date_from                                                 --
  -- invoice_date <= Pd_date_to                                                   --
  -- Mode de paiement = WIRE                                                      --
  -- Priorité = 33                                                                --
  -- Classe de réglement de la société = Pv_society                               --
  -- pour le fournisseur et le site passé en parametre                            --
  ----------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 5 : Identification des factures comprises dans la fourchette des dates');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  gt_ap_prel_tmp.DELETE;

  Dka_Tools_Pkg.Put_Debug_Message('==> Select invoices for wiring');

  SELECT 'SELECTED',
         SYSDATE,
         aia.invoice_id,
         aia.invoice_num,
         aia.invoice_date,
         aia.invoice_amount,
         aia.cancelled_date,
         aia.pay_group_lookup_code,
         aia.PAYMENT_METHOD_CODE, --ray
         aia.exclusive_payment_flag,
         apsa.payment_num,
         apsa.due_date,
         apsa.payment_priority,
         pv.vendor_name,
         pvsa.vendor_site_code
  BULK COLLECT INTO gt_ap_prel_tmp
  FROM   ap_invoices_all            aia,
         ap_payment_schedules_all   apsa,
         ap_suppliers                 pv,      -- R12 (po_vendors==>ap_suppliers)
         ap_supplier_sites_all        pvsa       --R12 (po_vendor_sites_all==> ap_supplier_sites_all)
  WHERE  aia.invoice_id = apsa.invoice_id
  AND    aia.vendor_id = pv.vendor_id
  AND    aia.vendor_site_id = pvsa.vendor_site_id
  AND    pvsa.vendor_id = pv.vendor_id
  AND    pv.vendor_id = pn_vendor_id
  AND    pvsa.vendor_site_id = pn_vendor_site_id
  AND    aia.cancelled_date IS NULL
  AND    aia.invoice_type_lookup_code = 'STANDARD'
  AND    aia.Org_Id = gn_org_id 
  AND  ( apsa.due_date BETWEEN gd_date_from AND gd_date_to  )
  AND    apsa.payment_status_flag = 'N'
  AND    apsa.PAYMENT_METHOD_CODE = 'WIRE'
  AND    NVL(apsa.hold_flag,'N') = 'N'
  AND    apsa.Org_Id = gn_org_id 
  AND    ap_invoices_pkg.get_approval_status(aia.invoice_id,
                                             aia.invoice_amount,
                                             aia.payment_status_flag,
                                             aia.invoice_type_lookup_code) IN ('APPROVED', 'UNPAID');

  Dka_Tools_Pkg.Put_Outdebug_Message('==> Nombre de factures identifiées et à traiter : ' || gt_ap_prel_tmp.COUNT);

  ---------------------------------------------------------------------------
  -- Phase 6 : Mise à jour des factures identifiées en phase 3             --
  -- Champs : payment_priority = 33                                        --
  --          exclusive_payment_flag = Y                                   --
  ---------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 6 : Mise à jour des factures pour être candidates à la campagne de prélèvement');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  gn_nb_factures := gt_ap_prel_tmp.COUNT;

  IF  gn_nb_factures <> 0 THEN

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall insert invoices to process');

    FORALL i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST

      INSERT INTO dka_ap_prelevement_tmp VALUES gt_ap_prel_tmp(i);

    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_invoices_all.exclusive_payment_flag');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_invoices_all aia
      SET    aia.exclusive_payment_flag = 'Y',
             aia.last_update_date       = SYSDATE,
             aia.last_updated_by        = gn_userid,
             aia.last_update_login      = gn_login_id
      WHERE  aia.invoice_id = gt_ap_prel_tmp(i).invoice_id;
    END LOOP;
    Dka_Tools_Pkg.Put_Debug_Message('==> Forall update of ap_payment_schedules_all.payment_priority');

    FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
    LOOP
      UPDATE Ap_Payment_Schedules_All apsa
      SET    apsa.payment_priority  = 33,
             apsa.Last_Update_Date  = SYSDATE,
             apsa.Last_Updated_By   = gn_userid,
             apsa.Last_Update_Login = gn_login_id,
             apsa.attribute15 = apsa.external_bank_account_id, 
             apsa.external_bank_account_id = null 
      WHERE  apsa.invoice_id = gt_ap_prel_tmp(i).invoice_id
      AND    apsa.payment_num = gt_ap_prel_tmp(i).payment_num;
    END LOOP;
  ELSE
    Dka_Tools_Pkg.Put_Outdebug_Message('==> Aucune mise à jour à faire');
  END IF;

  ---------------------------------------------------------------------------------------------
  -- Phase 7 : Enchainement et lancement automatique de la campgane de prélèvement           --
  ---------------------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 7 : Enchainement de la campagne de prélèvement');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

  Campagne_prelevement(Vv_Errbuf,Vn_Retcode,Pv_Debug_Switch,Pv_Trace_Switch);

  ----- Remise du compte bancaire
  IF  gn_nb_factures <> 0 THEN
       FOR i IN gt_ap_prel_tmp.FIRST..gt_ap_prel_tmp.LAST
       LOOP
         UPDATE Ap_Payment_Schedules_All apsa
            SET    apsa.external_bank_account_id = apsa.attribute15,
                   apsa.attribute15= null
            WHERE  apsa.invoice_id = gt_ap_prel_tmp(i).invoice_id
            AND    apsa.payment_num = gt_ap_prel_tmp(i).payment_num;
       END LOOP;
  END IF;

  IF Vn_Retcode != 0 THEN
     Pv_Errbuf := Vv_Errbuf;
     RAISE E_Erreur_Programme;
  END IF;

  Dka_Tools_Pkg.Put_Debug_Message('End - Main (-)');

EXCEPTION
    WHEN E_Erreur_Programme THEN
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

END DKA_SAPCAMPPREL_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SAPCAMPPREL_PKG
EXIT
