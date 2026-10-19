CREATE OR REPLACE PACKAGE BODY DKA_SFABUDGET_PKG AS
  ----------------------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SFABUDGET_PKG.pkb
  -- DESCRIPTION     : package body pour l'interface Fa Budget
  --
  -- AUTEUR            : E. Flass
  -- DATE DE CREATION  : 18/06/2004
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 14/02/2005 SLA Maintenance projet Phenix
  ---                Remplacer substr(segment1,1,4) par Segment2
  ---                Remplacer substr(segment1,4,4) par Segment1
  --                 Inverser Segment3 et Segment4
  ---                Décaler les autres segments
  --  21/05/2007 SLA Remplacement de sysdate par gv_ref_date (nécessaire pour les tests sur nos bases
  --                 de dév et recette suite à l'évolution aux normes IFRS
  --                 Ajout de la procédure DKA_AMORT_REEL ( Récupération des amortissements réels à partir de la table
  --                 fa_deprn_summary) et de la procédure DKA_FIRST_PERIOD_NEW (calcul de la période de début des
  --                 amortissements prévisionnels ainsi que le nombre de période de prévision, ces infos sont fonction
  --                 de la date de référence)
  --                 Ajout de la procédure  DKA_GET_INFOS_AMORT qui récupère les immos totalements amorties,
  --                 rattachées à un compte d'exception
  --                 Modification main - ajout d'un paramètre : date de référence
  --                 Modification DKA_INS_TRAITEMENT Récupértion des 24 montants de pérvisions (au maximum 24 périodes : 12
  --                 sur l'année N et 12 sur l'année N + 1). Prise en compte du jeu de valeur DKA_FA_CPTE_EXCEPTION.
  --                 Insertion de 3 nouvelles valeurs Dotation Annee_N, Catégorie et Cpte d'immo
  --  07/09/2007 SLA DKA_AMORT_REEL - Correctif. Determination du montant Dotaion_N erronée.
  --  31/03/2008 SLA Modification de la procédure DKA_INS_IMM_EXCEP -
  --                 Ajout de règles de gestion : Reprendre également toutes les fiches d¿immobilisations non cédées en totalité au 1er jour de l¿année N
  --                                              y compris celles pour lesquelles  le champ « amortir » n¿est pas coché et rattachées à un compte
  --                                              d'exception
  --                 Modification DKA_MAIN_GEN_DATA - Ne plus afficher le segment 1 de la clé Catégorie
  --                 (Rubrique principale)
  -- 08/07/2008  SLA Modification DKA_GET_CENTRE - Pb étanchéïté - Ajout condition sur le business_group
  -- 17/07/2008  SLA DKA_INS_IMM_EXCEP - Correctif Détermination dotations des fiches sur comptes d'exception
  -- 09/11/2009  SLA DKA_UPDATE_DATA - Adaptation pour avoir valeur avant cession année N
  --                 DKA_INS_IMM_EXCEP - Correctif Détermination dotations des fiches sur comptes d'exception
  -- 21/02/2013  JJA DKA_GET_CENTRE : Modification de la requete pour optimisation (INC000000373891)
  -- 05/08/2019  SELOO SPE073 - Interface FA - Budget-1-SFD.doc
  -- 13/08/2019  OCL   SPE073 - Ajout d'un filtre dans les procédures p_extr_data_hyperion et p_extr_data_hyperion_REG
  -- 15/07/2020  AAM   SPE073 - INC0433698 / artf07386360
  -- 31/08/2020 : MTIA : Correction fichier Budget INC0433698 - INC0433695
  -- 09/10/2020 : MTIA - Correction fichier Budget INC0433698 - INC0433695 et exclusion société de référence
  -- 01/10/2021 : SHA  - EDB304 - DPE20210026 - Export des données FA Budget - Ajout du PF et TF Investissement dans les etats justificatifs 
  --------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- Liste de livres associes aux societes a traiter
  -- La societe doit etre de type 0
  -- La Code du livre commence par le numero de la societe
  -- Le livre doit etre actif et de type comptable
  E_FATAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;
  vg_SEPARATOR      CONSTANT VARCHAR2(2) := ';';
  vg_nbl_extr_cmd number := 0;

  CURSOR Cur_Books_01 IS
    SELECT Fbc.Book_Type_Code, Fbc.Deprn_Calendar
      FROM Fa_Book_Controls Fbc, gl_ledgers gll -- SELOO Regle 31
     WHERE Fbc.Book_Class in ('CORPORATE', 'TAX')
          --and Fbc.Book_Type_Code in ('0691 SOCIAL')   --SELOO
          --AND Fbc.Date_Ineffective IS NULL
          -- SELOO
       and Fbc.Book_Type_Code not in ('9999 IFRS', '9999 SOCIAL') --INC0432593  - MTIA  ne pas lancer sur societe de reference
       and gll.ledger_id = Fbc.set_of_books_id -- SELOO Regle 31
       and gll.currency_code = 'EUR';

  Rec_Books_01 Cur_Books_01%ROWTYPE;

  -- Variable permettant de reperer une erreur interdisant le passage a l'etape suivante
  Vb_Continuer BOOLEAN := TRUE;

  -- Exception Sortie du programme
  Erreur_Prog_E EXCEPTION;

  -- Id des traitements FAGDA
  TYPE Vt_Request_Id_Fagda_Type IS TABLE OF FND_Concurrent_Requests.Request_Id%TYPE index by binary_integer;
  Vt_Request_Id_Fagda Vt_Request_Id_Fagda_Type;
  Vn_Nbre_Fagda       BINARY_INTEGER := 0;

  -- Id des traitements FAPROJ
  TYPE Vt_Request_Id_FaProj_Type IS TABLE OF FND_Concurrent_Requests.Request_Id%TYPE index by binary_integer;
  Vt_Request_Id_FaProj Vt_Request_Id_FaProj_Type;
  Vn_Nbre_FaProj       BINARY_INTEGER := 0;

  gv_ref_date   DATE; --25/04/2007
  gv_jeu_valeur VARCHAR2(255) := 'DKA_FA_CPTE_EXCEPTION';
  --Attention ce jeu est également présent en dur dna le bout de code dynamique DKA_INS_TRAITEMENT

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- Fonctions pour la suppression des donnees du traitement precedent
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_DEL_SFABUDGET_WORK
  --  Description   : Procedure de suppression des donnees de l'ancien traitement
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_DEL_SFABUDGET_WORK(pv_errbuf  IN OUT VARCHAR2,
                                   pn_retcode IN OUT NUMBER) IS
    Vn_Nbre_Record NUMBER;
  BEGIN
  
    delete DKA_SFABUDGET_WORK;
    Vn_Nbre_Record := SQL%ROWCOUNT;
    dka_tools_pkg.put_log_message('-> ' || Vn_Nbre_Record ||
                                  ' enregistrements supprimes ');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_DEL_SFABUDGET_WORK avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_DEL_SFABUDGET_WORK;

  -- Fonctions pour le pre-controle
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_BOOK_PERIODS_CTR
  --  Description   : Procedure de pre-controle pour un livre
  --                  Y a t il 12 periodes definies dans le calendrier
  --                  pour la prochaine annee civile (01/01 au 31/12) ?
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Book_Type_Code         Entree             Code du livre
  -- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_BOOK_PERIODS_CTR(pv_errbuf         IN OUT VARCHAR2,
                                 pn_retcode        IN OUT NUMBER,
                                 Pv_Book_Type_Code IN VARCHAR2,
                                 Pv_Calendar_Type  IN VARCHAR2) IS
    -- Nbre de periodes
    Vn_Nbre_Periodes NUMBER;
  BEGIN
  
    SELECT COUNT(*)
      INTO Vn_Nbre_Periodes
      FROM Fa_Calendar_Types Fct, Fa_Calendar_Periods Fcp
     WHERE Fct.calendar_type = Pv_Calendar_Type
       AND Fcp.Calendar_Type = Fct.Calendar_Type
          -- Date de debut de la periode situee entre le 01/01 et 31/12 de l'annee systeme +1
       AND Fcp.Start_Date BETWEEN
           ADD_MONTHS(trunc(gv_ref_date, 'YEAR'), 12) AND
           ADD_MONTHS(trunc(gv_ref_date, 'YEAR'), 24) - 1;
  
    IF Vn_Nbre_Periodes <> 12 THEN
      dka_tools_pkg.put_outdebug_message('-> Controles du livre ' ||
                                         Pv_Book_Type_Code);
      dka_tools_pkg.put_outdebug_message('!!!! Erreur lors du controle des periodes');
      dka_tools_pkg.put_outdebug_message('!!!! Le calendrier ' ||
                                         Pv_Calendar_Type ||
                                         ' comporte uniquement ');
      dka_tools_pkg.put_outdebug_message('!!!! ' ||
                                         TO_CHAR(NVL(Vn_Nbre_Periodes, 0)) ||
                                         ' periodes commencant en '); --||TO_CHAR(gv_ref_date,'YYYY')+1);
      dka_tools_pkg.put_outdebug_message('!!!! Le nombre attendu de periodes est 12');
      -- Une erreur interdisant la passage a l'etape suivante
      Vb_Continuer := FALSE;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_BOOK_PERIODS_CTR (' || Pv_Book_Type_Code || ',' ||
                    Pv_Calendar_Type || ') avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_BOOK_PERIODS_CTR;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_BOOK_MAIN_CTR
  --  Description   : Procedure de pre-controle d'un livre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Book_Type_Code         Entree             Code du livre
  -- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_BOOK_MAIN_CTR(pv_errbuf         IN OUT VARCHAR2,
                              pn_retcode        IN OUT NUMBER,
                              Pv_Book_Type_Code IN VARCHAR2,
                              Pv_Calendar_Type  IN VARCHAR2) IS
  BEGIN
    -- Controle du nbre de periodes
    DKA_BOOK_PERIODS_CTR(pv_errbuf,
                         pn_retcode,
                         Pv_Book_Type_Code,
                         Pv_Calendar_Type);
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_BOOK_MAIN_CTR (' || Pv_Book_Type_Code || ',' ||
                    Pv_Calendar_Type || ') avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_BOOK_MAIN_CTR;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_CTR
  --  Description   : Procédure principale de pre-controle
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_CTR(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode IN OUT NUMBER) IS
  
  BEGIN
    FOR Rec_Books_01 IN Cur_Books_01 LOOP
      -- Controles du livre
      DKA_BOOK_PERIODS_CTR(pv_errbuf,
                           pn_retcode,
                           Rec_Books_01.Book_Type_Code,
                           Rec_Books_01.Deprn_Calendar);
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        EXIT;
      END IF;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_SUBMIT_FAPROJ avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_CTR;

  -- Fonctions pour la soumission du programme de generation des cles (FAGDA)
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_WAIT_FAGDA
  --  Description   : Attente de la fin d'execution de l'ensemble des programmes FAGDA soumis
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_WAIT_FAGDA(pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode IN OUT NUMBER) IS
  
    Vb_Trash      BOOLEAN;
    Vv_Phase      VARCHAR2(50);
    Vv_Status     VARCHAR2(50);
    Vv_Dev_Phase  VARCHAR2(50);
    Vv_Dev_Status VARCHAR2(50);
    Vv_Message    VARCHAR2(50);
  
  BEGIN
    FOR I IN 1 .. Vn_Nbre_Fagda LOOP
      -- Attente de la fin d'execution des programmes
      Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST(Vt_Request_Id_Fagda(I), -- REQUEST_ID
                                                  10, -- INTERVAL
                                                  0, -- MAX_WAIT (pas de delai)
                                                  Vv_Phase, -- PHASE
                                                  Vv_Status, -- STATUS
                                                  Vv_Dev_Phase, -- DEV_PHASE
                                                  Vv_Dev_Status, -- DEV_STATUS
                                                  Vv_Message -- MESSAGE
                                                  );
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_WAIT_FAGDA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_WAIT_FAGDA;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_SUBMIT_FAGDA
  --  Description   : Soumission du programme de generation des cles de dotation pour le livre passe
  --                  en parametre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Book_Type_Code         Entree             Livre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_SUBMIT_FAGDA(pv_errbuf         IN OUT VARCHAR2,
                             pn_retcode        IN OUT NUMBER,
                             Pv_Book_Type_Code IN VARCHAR2) IS
  
    Vn_Request_Id_FAGDA Fnd_Concurrent_Requests.Request_Id%TYPE;
  
  BEGIN
    Vn_Request_Id_FAGDA := Fnd_Request.Submit_Request('OFA' -- APPLICATION SHORT NAME
                                                     ,
                                                      'FAGDA' -- CONCURRENT PROGRAM NAME
                                                     ,
                                                      NULL -- DESCRIPTION
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      -- ARGUMENTS
                                                     ,
                                                      Pv_Book_Type_Code -- 1  Livre
                                                      );
  
    -- Validation pour soumettre le traitement
    COMMIT;
  
    IF Vn_Request_Id_FAGDA = 0 THEN
      Pv_errbuf := '!!!! Erreur lors de la soumission du programme de generation des comptes (FAGDA) pour le livre ' ||
                   Pv_Book_Type_Code;
      dka_tools_pkg.put_outdebug_message(Pv_errbuf);
      dka_tools_pkg.put_outdebug_message(Fnd_Message.Get);
      -- Sortie en erreur
      Pn_Retcode := 2;
    ELSE
      -- Proramme soumis
      dka_tools_pkg.put_log_message('Programme soumis :' ||
                                    TO_CHAR(Vn_Request_Id_FAGDA));
      -- Memorisation de l'Id du traitement
      Vn_Nbre_Fagda := Vn_Nbre_Fagda + 1;
      Vt_Request_Id_Fagda(Vn_Nbre_Fagda) := Vn_Request_Id_FAGDA;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_SUBMIT_FAGDA (' || Pv_Book_Type_Code ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_SUBMIT_FAGDA;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_ALL_CCID
  --  Description   : Controle que l 'ensemble des cle de dotations ont ete generees pour un livre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Book_Type_Code         Entree             Livre
  -- Pb_exists                 Sortie             Au moins une cle n'a pas ete generee
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_CTR_ALL_CCID(pv_errbuf         IN OUT VARCHAR2,
                             pn_retcode        IN OUT NUMBER,
                             Pv_Book_Type_Code IN VARCHAR2,
                             Pb_Exists         OUT BOOLEAN) IS
  
    Vv_Trash VARCHAR2(1);
  
  BEGIN
    SELECT /*+ ordered */
     'X'
      INTO Vv_Trash
      FROM Fa_Books Fb, Fa_Distribution_History Fdh
     WHERE
    -- Enregistrements en cours de validie
    -- Base amortissable <> 0
     Fb.Book_Type_Code = Pv_Book_Type_Code
     AND Fb.Transaction_Header_Id_Out IS NULL
     AND Fb.Date_Ineffective IS NULL
     AND NVL(Fb.Recoverable_Cost, 0) <> 0
     AND Fdh.Book_Type_Code = Fb.Book_Type_Code
     AND Fdh.Asset_Id = Fb.Asset_Id
    -- Lignes d'affectation en cours de validite
     AND Fdh.Transaction_Header_Id_Out IS NULL
     AND Fdh.Date_Ineffective IS NULL
    -- Lignes n'existants pas ou dont la cle de dotation n'a pas ete generee
     AND NOT EXISTS (SELECT 'X'
        FROM Fa_Distribution_Accounts Fda
       WHERE Fda.Book_Type_Code = Fdh.Book_Type_Code
         AND Fda.Distribution_Id = Fdh.Distribution_Id
         AND Fda.Deprn_Expense_Account_Ccid IS NOT NULL);
  
    -- Il existe une cle a generer
    Pb_Exists := TRUE;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Toutes les cles ont ete generees
      Pb_Exists := FALSE;
    WHEN TOO_MANY_ROWS THEN
      -- Il existe des cles a generer
      Pb_Exists := TRUE;
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_CTR_ALL_CCID (' || Pv_Book_Type_Code ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_CTR_ALL_CCID;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_FAGDA
  --  Description   : Soumission du programme de generation des cles
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_book_type_Code         Entree             Code du livre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_FAGDA(pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode IN OUT NUMBER) IS
    -- Existe-t-il des cles a generer pour le livre
    Vb_Exists BOOLEAN;
  BEGIN
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Generation des cles de dotation');
    dka_tools_pkg.put_log_message('----------');
    FOR Rec_Books_01 IN Cur_Books_01 LOOP
    
      -- Controles de l existence des cles pour le livre
      DKA_CTR_ALL_CCID(pv_errbuf,
                       pn_retcode,
                       Rec_Books_01.Book_Type_Code,
                       Vb_Exists);
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        RETURN;
      END IF;
    
      IF Vb_Exists THEN
        -- Il reste des cles a generer
        dka_tools_pkg.put_log_message('-> Livre ' ||
                                      Rec_Books_01.Book_Type_Code);
        dka_tools_pkg.put_log_message('Il reste des cles de dotation a generer');
        dka_tools_pkg.put_log_message('Soumission du proramme de generation des cles');
      
        -- Soumission du programme
        DKA_SUBMIT_FAGDA(pv_errbuf,
                         pn_retcode,
                         Rec_Books_01.Book_Type_Code);
      
        IF pn_retcode = 2 THEN
          -- Sortie: Erreur systeme
          RETURN;
        END IF;
      
      END IF; /* IF NOT Vv_Exists */
    
    END LOOP; /* FOR Rec_Books_01 IN Cur_Books_01 */
  
    -- Attente de la fin d'execution des programmes FAGDA soumis
    DKA_WAIT_FAGDA(pv_errbuf, pn_retcode);
  
    IF pn_retcode = 2 THEN
      -- Sortie: Erreur systeme
      RETURN;
    END IF;
  
    -- Controle que l'ensemble des cles de dotation ont ete generees
    -- On ne teste pas que dans DKA_WAIT_FAGDA les programmes FAGDA sont sortis en erreur
    -- En effet, les erreurs de generation sur les cles autres que la cle de dotation
    -- ne doivent pas empecher le reste du traitement puisqu'ici seule la cle de dotation
    -- nous interesse.
    -- Il faut donc reeffectuer le controle de debut de procedure
  
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Controle de l''existence de la totalite des cles de dotations');
    dka_tools_pkg.put_log_message('necessaires pour le traitement');
    dka_tools_pkg.put_log_message('----------');
    /*FOR Rec_Books_01 IN Cur_Books_01
    LOOP
    
      -- Controles de l existence des cles pour le livre
      DKA_CTR_ALL_CCID (
        pv_errbuf    ,
        pn_retcode   ,
        Rec_Books_01.Book_Type_Code,
        Vb_Exists
         );
    
      IF pn_retcode = 2
      THEN
         -- Sortie: Erreur systeme
         RETURN;
      END IF;
    
      IF Vb_Exists
      THEN
        -- Il reste des cles a generer
        dka_tools_pkg.put_outdebug_message ( '-> Livre '||Rec_Books_01.Book_Type_Code);
        dka_tools_pkg.put_outdebug_message ( '!!!! L''ensemble des cles de dotations n''ont pas ete generees');
        -- Sortie de programme;
        Vb_Continuer := FALSE;
      END IF;
    
    END LOOP; */ /* FOR Rec_Books_01 IN Cur_Books_01 */
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_FAGDA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_FAGDA;

  -- Fonctions pour la soumission du programme de previsions d'amortissement (FAPROJ)
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_WAIT_FAPROJ
  --  Description   : Attente de la fin d'execution de l'ensemble des programmes FAPROJ soumis
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_WAIT_FAPROJ(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER) IS
  
    Vb_Trash      BOOLEAN;
    Vv_Phase      VARCHAR2(50);
    Vv_Status     VARCHAR2(50);
    Vv_Dev_Phase  VARCHAR2(50);
    Vv_Dev_Status VARCHAR2(50);
    Vv_Message    VARCHAR2(50);
  
  BEGIN
    FOR I IN 1 .. Vn_Nbre_FaProj LOOP
      -- Attente de la fin d'execution des programmes
      Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST(Vt_Request_Id_FaProj(I), -- REQUEST_ID
                                                  10, -- INTERVAL
                                                  0, -- MAX_WAIT (pas de delai)
                                                  Vv_Phase, -- PHASE
                                                  Vv_Status, -- STATUS
                                                  Vv_Dev_Phase, -- DEV_PHASE
                                                  Vv_Dev_Status, -- DEV_STATUS
                                                  Vv_Message -- MESSAGE
                                                  );
      IF (Vv_Dev_Phase <> 'COMPLETE' OR Vv_Dev_Status <> 'NORMAL') THEN
        -- Programme non termine normalement
        dka_tools_pkg.put_outdebug_message('!!!! Le traitement de prevision des aortissements ' ||
                                           TO_CHAR(Vt_Request_Id_FaProj(I)) || ')' ||
                                           ' ne s''est pas termine correctement');
      
        -- Arret des traitements
        Vb_Continuer := FALSE;
      END IF;
    
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_WAIT_FAPROJ avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_WAIT_FAPROJ;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_SUBMIT_FAPROJ
  --  Description   : Soumission du programme de generation des cles de dotation pour le livre/Caleendrier
  --                  passe en parametre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Book_Type_Code         Entree             Livre
  -- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
  -- Pv_First_Period           Entre              Premiere periode
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_SUBMIT_FAPROJ(pv_errbuf         IN OUT VARCHAR2,
                              pn_retcode        IN OUT NUMBER,
                              Pv_Book_Type_Code IN VARCHAR2,
                              Pv_Calendar_Type  IN VARCHAR2,
                              Pv_First_Period   IN VARCHAR2,
                              Pv_Nb_Periode     IN NUMBER -- 24/04/2007 ajout d'un param
                              ) IS
  
    Vn_Request_Id_FAPROJ Fnd_Concurrent_Requests.Request_Id%TYPE;
  BEGIN
    Vn_Request_Id_FAPROJ := Fnd_Request.Submit_Request('OFA' -- APPLICATION SHORT NAME
                                                      ,
                                                       'FAPROJ' -- CONCURRENT PROGRAM NAME
                                                      ,
                                                       NULL -- DESCRIPTION
                                                      ,
                                                       NULL -- START
                                                      ,
                                                       FALSE -- SUB_REQUEST
                                                       -- ARGUMENTS
                                                      ,
                                                       Pv_Calendar_Type -- 1  Calendrier
                                                      ,
                                                       Pv_First_Period -- 2 Premiere periode
                                                      ,
                                                       Pv_Nb_Periode -- 3 Nbre de periodes 24/04/2007 Remplacement de 12 par Pv_Nb_Periode
                                                      ,
                                                       'EUR' -- 4 devise EUR
                                                      ,
                                                       Pv_Book_Type_Code -- 5 Livre
                                                       
                                                       );
  
    -- Validation pour soumettre le traitement
    COMMIT;
  
    IF Vn_Request_Id_FAPROJ = 0 THEN
      Pv_errbuf := '!!!! Erreur lors de la soumission du programme de prevision d''amortissement (FAPROJ) pour le livre ' ||
                   Pv_Book_Type_Code;
      dka_tools_pkg.put_outdebug_message(Pv_errbuf);
      dka_tools_pkg.put_outdebug_message(Fnd_Message.Get);
      -- Sortie en erreur
      Pn_Retcode := 2;
    ELSE
      -- Programme soumis
      dka_tools_pkg.put_log_message('-> Livre ' || Pv_Book_Type_Code ||
                                    ' - Programme soumis :' ||
                                    TO_CHAR(Vn_Request_Id_FAPROJ));
      -- Memorisation de l'Id du traitement
      Vn_Nbre_FaProj := Vn_Nbre_FaProj + 1;
      Vt_Request_Id_FaProj(Vn_Nbre_FaProj) := Vn_Request_Id_FaProj;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_SUBMIT_FAGDA (' || Pv_Book_Type_Code ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_SUBMIT_FAPROJ;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_FIRST_PERIODE
  --  Description   : Premiere periode de l'annee civile N+1
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_Calendar_Type          Entree             Code du calendrier
  -- pv_Period_Name            Sortie             Nom de la periode
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_FIRST_PERIODE(pv_errbuf        IN OUT VARCHAR2,
                              pn_retcode       IN OUT NUMBER,
                              Pv_Calendar_Type IN VARCHAR2,
                              Pv_Period_Name   OUT VARCHAR2) IS
  
  BEGIN
    SELECT Fcp.Period_Name
      INTO Pv_Period_Name
      FROM Fa_Calendar_Periods Fcp
     WHERE Fcp.Calendar_Type = Pv_Calendar_Type
       AND Fcp.Start_Date = ADD_MONTHS(TRUNC(gv_ref_date, 'YYYY'), 12);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_FIRST_PERIODE (' || Pv_Calendar_Type ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_FIRST_PERIODE;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_FIRST_PERIODE_NEW
  --  Description   : Premiere periode de l'annee civile N+1
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_Calendar_Type          Entree             Code du calendrier
  -- pv_Period_Name            Sortie             Nom de la periode
  -- Pv_Nb_period              Sortie             Nombre de prévision pour le prévisionnel
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_FIRST_PERIODE_NEW(pv_errbuf        IN OUT VARCHAR2,
                                  pn_retcode       IN OUT NUMBER,
                                  Pv_Calendar_Type IN VARCHAR2,
                                  Pv_Period_Name   OUT VARCHAR2,
                                  Pv_Nb_period     OUT NUMBER) IS
  
  BEGIN
    SELECT Fcp.Period_Name, 24 - TO_NUMBER(TO_CHAR(gv_ref_date, 'MM')) + 1 -- nbre de période de prévisions
      INTO Pv_Period_Name, Pv_Nb_period
      FROM Fa_Calendar_Periods Fcp
     WHERE Fcp.Calendar_Type = Pv_Calendar_Type
       AND gv_ref_date between Fcp.Start_Date and fcp.End_Date
    
    ;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_FIRST_PERIODE (' || Pv_Calendar_Type ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_FIRST_PERIODE_NEW;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_FAPROJ
  --  Description   : Soumission du programme de prevision d'amortissement
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_book_type_Code         Entree             Code du livre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_FAPROJ(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER) IS
    -- Nom de la premiere periode de l'annee civile N+1 pour le calendrier du livre
    Vv_Period_Name Fa_Calendar_Periods.Period_Name%TYPE;
    Vv_Nb_Periode  Number;
  
  BEGIN
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Soumission des programmes de prevision des amortissements');
    dka_tools_pkg.put_log_message('----------');
    FOR Rec_Books_01 IN Cur_Books_01 LOOP
    
      --24/04/2007 DEB
      -- Recherche de la premiere periode de l'annee civile N+1
      /*         DKA_FIRST_PERIODE ( pv_errbuf,
      pn_retcode,
      Rec_Books_01.Deprn_Calendar,
      Vv_Period_Name );*/
    
      -- recherche de la premiere période de prévision (Periode à laquelle appartient la date de réference)
      DKA_FIRST_PERIODE_NEW(pv_errbuf,
                            pn_retcode,
                            Rec_Books_01.Deprn_Calendar,
                            Vv_Period_Name,
                            Vv_Nb_Periode);
    
      --24/04/2007 FIN
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        RETURN;
      END IF;
    
      -- Soumission du programme de prevision des amortissements
      DKA_SUBMIT_FAPROJ(pv_errbuf,
                        pn_retcode,
                        Rec_Books_01.Book_Type_Code,
                        Rec_Books_01.Deprn_Calendar,
                        Vv_Period_Name,
                        Vv_Nb_Periode);
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        RETURN;
      END IF;
    
    END LOOP; /* FOR Rec_Books_01 IN Cur_Books_01 */
  
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Controle de l''execution des programmes de prevision des amortissements');
    dka_tools_pkg.put_log_message('----------');
  
    -- Attente et resultat des traitements soumis
    DKA_WAIT_FAPROJ(pv_errbuf, pn_retcode);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_FAPROJ avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_FAPROJ;

  -- Fonctions pour l'alimentation de la table DKA_FABUDGET_WORK a partir des tables
  -- generees par les traitements de prevision des amortissement
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_TRAITEMENT
  --  Description   : Insertion des donnees generees par un traitement
  --                  On execute l'ordre dynamiquement car nom de la table d'origine
  --                  est fonction de l'id. du traitement passe en parametre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pn_Request_Id             Entree             Id du traitement
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_INS_TRAITEMENT(pv_errbuf     IN OUT VARCHAR2,
                               pn_retcode    IN OUT NUMBER,
                               pn_request_Id IN NUMBER,
                               pn_annee_n    IN NUMBER) IS
    -- Ordre PLSQL a generer
    Vv_Ordre_PLSQL VARCHAR2(10000);
  
  BEGIN
  
    -- Vb_Montant : Variable booleenne permettant de determiner
    --              qu'au moins un montant pour un mois est different de 0.
    --              Cela permet de ne pas inserer l'enregistrement  si l'ensemble
    --              des montants sont egaux a 0
    -- Vn_Old_Asset_Id       : Asset_Id de l'enregistrement precedent
    -- Vv_Old_Book_Type_Code : Livre de l'enregistrement precedent
    -- Vt_Montant : Variable tableau stockant pour une immo des montants pour chaque mois
    --
    -- POUR chaque enregistrement du curseur
    -- FAIRE
    --    SI on a change d'immo
    --    ALORS
    --       SI au moins un montant pour l'immo est different de 0 (Vb_Montant = TRUE)
    --       ALORS
    --          Insertion de l'enregistrement dans la table DKA_SFABUDGET_WORK
    --       FIN SI
    --       Reinitialisation de Vb_Montant
    --       Reinitialisation des 12 montants de la variable tableau Vt_Montant
    --    FIN SI
    --    Memorisation du montant dans la variable tableau Vt_Montant
    --    SI le montant est <> 0 OU S'IL s'agit d'un compte d'exception
    --    ALORS
    --       Memorisation qu'au moins un montant est <> 0 pour l'immo (Vb_Montant = TRUE)
    --    FIN SI
    --    Memorisation de l'id de l'immo et du livre de l'enregistrement courant
    -- FIN POUR
    --
    -- SI on a traite au moins une immo et qu'au moins un montant est <> 0 (Vb_Montant = TRUE)
    -- ALORS
    --    Insertion de l'enregistrement dans la table DKA_SFABUDGET_WORK
    -- FIN SI
  
    Vv_Ordre_PLSQL := '
DECLARE
Vn_old_Asset_Id NUMBER := -1;
Vv_Old_Book_Type_Code VARCHAR2(30);
TYPE Vt_Montant_Type IS TABLE OF NUMBER index by binary_integer;
Vt_Montant Vt_Montant_Type;
Vb_Montant BOOLEAN := FALSE;
Vv_Nb_Cpte NUMBER := 0;
Vv_Old_Nb_Cpte NUMBER := 0;
Vn_Old_Categ          VARCHAR2(30);
Vn_Old_Cpte_Categ     VARCHAR2(25);
Vn_Old_Categ_Seg2     VARCHAR2(25);
vv_jeu_valeur         VARCHAR2(255) := ''DKA_FA_CPTE_EXCEPTION'';

CURSOR CUR_1
IS
SELECT /*+ ordered use_nl (Fab,fcp) */
  Fpi.Book_Type_Code
, Fpi.Asset_Id
, DECODE (fpi.fiscal_year,
          ' || TO_NUMBER(pn_annee_n) || ',TO_CHAR(Fcp.Start_Date,''MM''),
          ' || TO_NUMBER(pn_annee_n) ||
                      ' + 1,TO_CHAR(TO_CHAR(Fcp.Start_Date,''MM'') + 12)
         ) Period_Num
, Depreciation
, Fcb.asset_cost_acct Cpte_Immo
, fc.segment1
, fc.segment2
, ''Non amortie'' life
from
(select REQUEST_ID, BOOK_TYPE_CODE, ASSET_ID, PERIOD_NAME, PERIOD_INDEX, FISCAL_YEAR, CODE_COMBINATION_ID, DEPRECIATION
  from FA_PROJ_INTERIM_REP where REQUEST_ID = ' ||
                      pn_request_Id ||
                      ' ) fpi
, Fa_Additions_b Fab
, Fa_Book_Controls Fbc
, Fa_Calendar_Periods Fcp
, Fa_Category_Books Fcb
, Fa_Categories_b_Kfv Fc
where
    Fab.Asset_Id = fpi.Asset_Id
AND Fab.Asset_Type = ''CAPITALIZED''
and fbc.book_type_code = fpi.book_type_code
and fcp.calendar_type = Fbc.Deprn_Calendar
and fcp.period_name = fpi.period_name
and fbc.deprn_calendar = ''MOIS 01-12''
and fcb.category_id = fab.asset_category_id
and fcb.book_type_code = fpi.book_type_code
and fc.category_id = fcb.category_id
--and   Fab.asset_id in (163682)
--and rownum<2
union
SELECT /*+ ordered use_nl (Fab,fcp) */
  Fpi.Book_Type_Code
, Fpi.Asset_Id
, TO_CHAR(Fcp.Start_Date,''MM'')Period_Num
, Depreciation
, Fcb.asset_cost_acct Cpte_Immo
, fc.segment1
, fc.segment2
, ''Non amortie'' life
from
(select REQUEST_ID, BOOK_TYPE_CODE, ASSET_ID, PERIOD_NAME, PERIOD_INDEX, FISCAL_YEAR, CODE_COMBINATION_ID, DEPRECIATION
  from FA_PROJ_INTERIM_REP where REQUEST_ID = ' ||
                      pn_request_Id || ' ) fpi
, Fa_Additions_b Fab
, Fa_Book_Controls Fbc
, Fa_Calendar_Periods Fcp
, Fa_Category_Books Fcb
, Fa_Categories_b_Kfv Fc
where
    Fab.Asset_Id = fpi.Asset_Id
AND Fab.Asset_Type = ''CAPITALIZED''
and fbc.book_type_code = fpi.book_type_code
and fcp.calendar_type = Fbc.Deprn_Calendar
and fcp.period_name = fpi.period_name
and fbc.deprn_calendar = ''MOIS 07-06''
and (fpi.fiscal_year = ' || TO_NUMBER(pn_annee_n) || '
     OR
     (fpi.fiscal_year = ' || TO_NUMBER(pn_annee_n) ||
                      ' + 1 AND fpi.period_index <= 6)
     )
and fcb.category_id = fab.asset_category_id
and fcb.book_type_code = fpi.book_type_code
and fc.category_id = fcb.category_id
--and   Fab.asset_id in (163682)
--and rownum<2
UNION ALL
SELECT /*+ ordered use_nl (Fab,fcp) */
  Fpi.Book_Type_Code
, Fpi.Asset_Id
, TO_CHAR(TO_CHAR(Fcp.Start_Date,''MM'') + 12) Period_Num
, Depreciation
, Fcb.asset_cost_acct Cpte_Immo
, fc.segment1
, fc.segment2
, ''Non amortie'' life
from
(select REQUEST_ID, BOOK_TYPE_CODE, ASSET_ID, PERIOD_NAME, PERIOD_INDEX, FISCAL_YEAR, CODE_COMBINATION_ID, DEPRECIATION
  from FA_PROJ_INTERIM_REP where REQUEST_ID = ' ||
                      pn_request_Id || ' ) fpi
, Fa_Additions_b Fab
, Fa_Book_Controls Fbc
, Fa_Calendar_Periods Fcp
, Fa_Category_Books Fcb
, Fa_Categories_b_Kfv Fc
where
    Fab.Asset_Id = fpi.Asset_Id
AND Fab.Asset_Type = ''CAPITALIZED''
and fbc.book_type_code = fpi.book_type_code
and fcp.calendar_type = Fbc.Deprn_Calendar
and fcp.period_name = fpi.period_name
and fbc.deprn_calendar = ''MOIS 07-06''
and (fpi.fiscal_year = ' || TO_NUMBER(pn_annee_n) ||
                      ' + 2
     OR
     (fpi.fiscal_year = ' || TO_NUMBER(pn_annee_n) ||
                      ' + 1 AND fpi.period_index > 6)
     )
and fcb.category_id = fab.asset_category_id
and fcb.book_type_code = fpi.book_type_code
and fc.category_id = fcb.category_id
--and   Fab.asset_id in (163682)
--and rownum<2
ORDER BY 2;

BEGIN
FOR Rec_1 IN Cur_1
LOOP
IF Vn_old_Asset_Id <> Rec_1.Asset_Id
THEN
SELECT COUNT(*)
INTO   Vv_Nb_Cpte
FROM   FND_FLEX_VALUE_SETS ffvs,
       fnd_flex_values ffv
WHERE  ffvs.flex_value_set_id = ffv.flex_value_set_id
AND    ffvs.flex_value_set_name = vv_jeu_valeur
AND    ffv.flex_value = Rec_1.Cpte_Immo;
IF Vb_Montant
THEN
INSERT INTO DKA_SFABUDGET_WORK
(Asset_Id,
Book_Type_Code,
DOTATION_JAN,
DOTATION_FEB,
DOTATION_MAR,
DOTATION_AVR,
DOTATION_MAI,
DOTATION_JUN,
DOTATION_JUL,
DOTATION_AOU,
DOTATION_SEP,
DOTATION_OCT,
DOTATION_NOV,
DOTATION_DEC,
DOTATION_N,
CATEGORIE,
CPTE_CATEG,
CATEG_SEGMENT2
)
VALUES
(Vn_Old_Asset_Id,
Vv_Old_Book_Type_Code,
Vt_Montant(13),
Vt_Montant(14),
Vt_Montant(15),
Vt_Montant(16),
Vt_Montant(17),
Vt_Montant(18),
Vt_Montant(19),
Vt_Montant(20),
Vt_Montant(21),
Vt_Montant(22),
Vt_Montant(23),
Vt_Montant(24),
Vt_Montant(1) + Vt_Montant(2) + Vt_Montant(3) + Vt_Montant(4) +
       Vt_Montant(5) + Vt_Montant(6) + Vt_Montant(7) + Vt_Montant(8) +
       Vt_Montant(9) + Vt_Montant(10) + Vt_Montant(11) + Vt_Montant(12),
Vn_Old_Categ,
Vn_Old_Cpte_Categ,
Vn_Old_Categ_Seg2
);
END IF;
FOR I IN 1..24
LOOP
Vt_Montant(I) := 0;
END LOOP;
Vb_Montant := FALSE;
END IF;
Vt_Montant (Rec_1.Period_Num) := NVL(Rec_1.Depreciation,0);
IF NVL(Rec_1.Depreciation,0) <> 0 OR Vv_Nb_Cpte >= 1 or (  Rec_1.life =''Non amortie'' ) THEN
  Vb_Montant := TRUE;
END IF;
Vn_old_Asset_Id := Rec_1.Asset_Id;
Vv_Old_Book_Type_Code := Rec_1.Book_Type_Code;
Vn_Old_Categ := Rec_1.Segment1;
Vn_Old_Cpte_Categ :=Rec_1.Cpte_Immo ;
Vn_Old_Categ_Seg2 := Rec_1.Segment2;
END LOOP;
IF Vb_Montant
THEN
INSERT INTO DKA_SFABUDGET_WORK
(Asset_Id,
Book_Type_Code,
DOTATION_JAN,
DOTATION_FEB,
DOTATION_MAR,
DOTATION_AVR,
DOTATION_MAI,
DOTATION_JUN,
DOTATION_JUL,
DOTATION_AOU,
DOTATION_SEP,
DOTATION_OCT,
DOTATION_NOV,
DOTATION_DEC,
DOTATION_N,
CATEGORIE,
CPTE_CATEG,
CATEG_SEGMENT2
)
VALUES
(Vn_Old_Asset_Id,
Vv_Old_Book_Type_Code,
Vt_Montant(13),
Vt_Montant(14),
Vt_Montant(15),
Vt_Montant(16),
Vt_Montant(17),
Vt_Montant(18),
Vt_Montant(19),
Vt_Montant(20),
Vt_Montant(21),
Vt_Montant(22),
Vt_Montant(23),
Vt_Montant(24),
Vt_Montant(1) + Vt_Montant(2) + Vt_Montant(3) + Vt_Montant(4) + Vt_Montant(5) +
      Vt_Montant(6) + Vt_Montant(7) + Vt_Montant(8) + Vt_Montant(9) + Vt_Montant(10) +
      Vt_Montant(11) + Vt_Montant(12),
Vn_Old_Categ,
Vn_Old_Cpte_Categ,
Vn_Old_Categ_Seg2)
;
-- SELOO
-- commit;
end if;
end;';
    COMMIT;
    apps_ddl.apps_ddl(Vv_Ordre_PLSQL);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_INS_TRAITEMENT' ||
                    TO_CHAR(pn_request_Id) ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_INS_TRAITEMENT;

  -- Fonctions pour l'alimentation de la table DKA_FABUDGET_WORK a partir des tables
  -- generees par les traitements de prevision des amortissement
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_TRAITEMENT
  --  Description   : Insertion des donnees generees par un traitement
  --                  On execute l'ordre dynamiquement car nom de la table d'origine
  --                  est fonction de l'id. du traitement passe en parametre
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pn_Request_Id             Entree             Id du traitement
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_INS_COMPL_AMORTIES(pv_errbuf  IN OUT VARCHAR2,
                                   pn_retcode IN OUT NUMBER) IS
    -- Ordre PLSQL a generer
    Vv_Ordre_PLSQL VARCHAR2(10000);
  
  BEGIN
  
    Vv_Ordre_PLSQL := '
DECLARE
Vn_old_Asset_Id NUMBER := -1;
Vv_Old_Book_Type_Code VARCHAR2(30);
TYPE Vt_Montant_Type IS TABLE OF NUMBER index by binary_integer;
Vt_Montant Vt_Montant_Type;
Vb_Montant BOOLEAN := FALSE;
Vv_Nb_Cpte NUMBER := 0;
Vv_Old_Nb_Cpte NUMBER := 0;
Vn_Old_Categ          VARCHAR2(30);
Vn_Old_Cpte_Categ     VARCHAR2(25);
Vn_Old_Categ_Seg2     VARCHAR2(25);
vv_jeu_valeur         VARCHAR2(255) := ''DKA_FA_CPTE_EXCEPTION'';

CURSOR CUR_1
IS
select  fb.book_type_code,
        fa.asset_id,
        ''08'' Period_Num,
        0 Depreciation
        , Fcb.asset_cost_acct Cpte_Immo
        , fc.segment1
        , fc.segment2
    , ''amortie'' life
from    FA_ADDITIONS fa ,  FA_BOOKS fb, FA_CATEGORIES  fc, FA_CATEGORY_BOOKS  fcb, GL_CODE_COMBINATIONS gcc3
where   fa.asset_id = fb.asset_id
and     fb.date_ineffective is null
and     fa.asset_category_id = fc.category_id
and     fc.category_id = fcb.category_id
and     fb.book_type_code = fcb.book_type_code
and     gcc3.code_combination_id = fcb.deprn_expense_account_ccid
and   fb.date_ineffective is null
--and   fa.asset_id in (163682)
and   fa.asset_id not in (select rep.asset_id
              from FA_PROJ_INTERIM_REP rep ,
                   fnd_concurrent_requests  req
               where rep.REQUEST_ID = req.request_id
               and req.PARENT_REQUEST_ID = fnd_global.conc_request_id --SELO
               and fb.book_type_code = rep.book_type_code
               )


ORDER BY 2;

BEGIN
FOR Rec_1 IN Cur_1
LOOP
  IF (Vn_old_Asset_Id <> Rec_1.Asset_Id) or ((Vn_old_Asset_Id = Rec_1.Asset_Id) and (Vv_Old_Book_Type_Code <> Rec_1.Book_Type_Code))
  THEN

    IF Vb_Montant
    THEN
      INSERT INTO DKA_SFABUDGET_WORK
      (Asset_Id,
      Book_Type_Code,
      DOTATION_JAN,
      DOTATION_FEB,
      DOTATION_MAR,
      DOTATION_AVR,
      DOTATION_MAI,
      DOTATION_JUN,
      DOTATION_JUL,
      DOTATION_AOU,
      DOTATION_SEP,
      DOTATION_OCT,
      DOTATION_NOV,
      DOTATION_DEC,
      DOTATION_N,
      CATEGORIE,
      CPTE_CATEG,
      CATEG_SEGMENT2
      )
      VALUES
      (Vn_Old_Asset_Id,
      Vv_Old_Book_Type_Code,
      Vt_Montant(13),
      Vt_Montant(14),
      Vt_Montant(15),
      Vt_Montant(16),
      Vt_Montant(17),
      Vt_Montant(18),
      Vt_Montant(19),
      Vt_Montant(20),
      Vt_Montant(21),
      Vt_Montant(22),
      Vt_Montant(23),
      Vt_Montant(24),
      Vt_Montant(1) + Vt_Montant(2) + Vt_Montant(3) + Vt_Montant(4) +
           Vt_Montant(5) + Vt_Montant(6) + Vt_Montant(7) + Vt_Montant(8) +
           Vt_Montant(9) + Vt_Montant(10) + Vt_Montant(11) + Vt_Montant(12),
      Vn_Old_Categ,
      Vn_Old_Cpte_Categ,
      Vn_Old_Categ_Seg2
      );
    END IF;
    FOR I IN 1..24
    LOOP
      Vt_Montant(I) := 0;
    END LOOP;
    Vb_Montant := FALSE;
  END IF;

  Vt_Montant (Rec_1.Period_Num) := NVL(Rec_1.Depreciation,0);

  IF NVL(Rec_1.Depreciation,0) <> 0 or (  Rec_1.life =''amortie'' ) THEN --SELOO
    Vb_Montant := TRUE;
  END IF;
  Vn_old_Asset_Id := Rec_1.Asset_Id;
  Vv_Old_Book_Type_Code := Rec_1.Book_Type_Code;
  Vn_Old_Categ := Rec_1.Segment1;
  Vn_Old_Cpte_Categ :=Rec_1.Cpte_Immo ;
  Vn_Old_Categ_Seg2 := Rec_1.Segment2;
END LOOP;
IF Vb_Montant
  THEN
  INSERT INTO DKA_SFABUDGET_WORK
  (Asset_Id,
  Book_Type_Code,
  DOTATION_JAN,
  DOTATION_FEB,
  DOTATION_MAR,
  DOTATION_AVR,
  DOTATION_MAI,
  DOTATION_JUN,
  DOTATION_JUL,
  DOTATION_AOU,
  DOTATION_SEP,
  DOTATION_OCT,
  DOTATION_NOV,
  DOTATION_DEC,
  DOTATION_N,
  CATEGORIE,
  CPTE_CATEG,
  CATEG_SEGMENT2
  )
  VALUES
  (Vn_Old_Asset_Id,
  Vv_Old_Book_Type_Code,
  Vt_Montant(13),
  Vt_Montant(14),
  Vt_Montant(15),
  Vt_Montant(16),
  Vt_Montant(17),
  Vt_Montant(18),
  Vt_Montant(19),
  Vt_Montant(20),
  Vt_Montant(21),
  Vt_Montant(22),
  Vt_Montant(23),
  Vt_Montant(24),
  Vt_Montant(1) + Vt_Montant(2) + Vt_Montant(3) + Vt_Montant(4) + Vt_Montant(5) +
      Vt_Montant(6) + Vt_Montant(7) + Vt_Montant(8) + Vt_Montant(9) + Vt_Montant(10) +
      Vt_Montant(11) + Vt_Montant(12),
  Vn_Old_Categ,
  Vn_Old_Cpte_Categ,
  Vn_Old_Categ_Seg2)
  ;
  -- SELOO
  commit;
end if;
end;';
  
    apps_ddl.apps_ddl(Vv_Ordre_PLSQL);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_INS_TRAITEMENT.DKA_INS_COMPL_AMORTIES avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_INS_COMPL_AMORTIES;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_GET_APPARTENANCE
  --  Description   : Organisation d'appartenance du projet passe en parametre
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pn_Project_Id             Entree             Id. du projet
  -- Pv_Org_Name               Sortie             Nom de l'organisation d'appartenance
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_GET_APPARTENANCE(pv_errbuf     IN OUT VARCHAR2,
                                 pn_retcode    IN OUT NUMBER,
                                 Pn_Project_Id IN NUMBER,
                                 Pv_Org_Name   OUT VARCHAR2) IS
    Vv_Org_Name VARCHAR2(30);
  BEGIN
  
    SELECT name
      INTO Vv_Org_Name
      FROM HR_ALL_ORGANIZATION_UNITS
     WHERE organization_id =
           (SELECT org_id
              FROM pa_projects_all
             WHERE project_id = Pn_Project_Id);
    Pv_Org_Name := Vv_Org_Name;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := 'DKA_GET_APPARTENANCE (' || Pn_Project_Id ||
                   ') avec EXCEPTION OTHERS:' || SQLERRM;
      --  pn_retcode    := 2;
  END DKA_GET_APPARTENANCE;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_GET_CENTRE
  --  Description   : Centre attache a l'organisation (Hierarchie 'HIERARCHIE_MENSUELLE' - Niveau 4)
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pv_Org_Name               Entree             Nom de l'organisation d'appartenance
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_GET_CENTRE(pv_errbuf   IN OUT VARCHAR2,
                           pn_retcode  IN OUT NUMBER,
                           Pv_Org_Name IN VARCHAR2,
                           Pv_Centre   OUT VARCHAR2) IS
    Vv_Centre                   VARCHAR2(30);
    vn_org_structure_version_id per_org_structure_versions.org_structure_version_id%TYPE; /*JJA 08/02/2013*/
  
  BEGIN
    /*JJA 08/02/2013*/
    SELECT posv.org_structure_version_id
      INTO vn_org_structure_version_id
      FROM per_org_structure_versions posv
     WHERE posv.organization_structure_id =
           (select Organization_Structure_Id
              from per_organization_structures
             where name = 'HIERARCHIE_MENSUELLE'
               And business_group_id =
                   fnd_profile.VALUE('PER_BUSINESS_GROUP_ID'))
       and gv_ref_date BETWEEN NVL(posv.date_from, gv_ref_date) AND
           NVL(posv.date_to, gv_ref_date);
    /*JJA 08/02/2013*/
  
    SELECT /* use_nl(posv, pose65, hou_child6, hou_child5,
                                    pose45, hou_parent5, hou_parent4
                                    ,pose34,hou_parent3) */
     DECODE(hou_parent5.type,
            '4',
            hou_parent5.name,
            DECODE(hou_parent4.type,
                   '4',
                   hou_parent4.name,
                   DECODE(hou_child6.type, '4', hou_child6.name)))
      INTO Vv_Centre
      FROM hr_all_organization_units  hou_child6,
           hr_all_organization_units  hou_parent5,
           hr_all_organization_units  hou_parent4,
           per_org_structure_elements pose56,
           per_org_structure_elements pose45 /*,
                     per_org_structure_versions posv*/ /*JJA 08/02/2013*/
     WHERE pose56.ORGANIZATION_ID_PARENT = pose45.organization_id_child
       and hou_child6.organization_id = pose56.organization_id_child
       and hou_parent5.organization_id = pose56.ORGANIZATION_ID_PARENT
       and hou_parent4.organization_id = pose45.organization_id_parent
          /*and posv.organization_structure_id =
          ( select Organization_Structure_Id
            from per_organization_structures
            where name = 'HIERARCHIE_MENSUELLE'
            And  business_group_id = fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID'))*/ /*JJA 08/02/2013*/
       and pose45.org_structure_version_id = vn_org_structure_version_id --posv.org_structure_version_id /*JJA 08/02/2013*/
       and pose56.org_structure_version_id = vn_org_structure_version_id --posv.org_structure_version_id /*JJA 08/02/2013*/
       and hou_child6.name = Pv_Org_Name
    --and gv_ref_date BETWEEN NVL(posv.date_from,gv_ref_date) AND NVL(posv.date_to,gv_ref_date) /*JJA 08/02/2013*/
    ;
  
    Pv_Centre := Vv_Centre;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      Pv_Centre := NULL;
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_GET_CENTRE (' || Pv_Org_Name ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_GET_CENTRE;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_GET_INFOS_AMORT
  --  Description   : Récupération des informations pour les immobilisations totalement amorties
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  /* PROCEDURE DKA_GET_INFOS_AMORT
          (
          pv_category     IN        VARCHAR2,
          pn_project_id   IN        NUMBER,
          pv_book_type_code  IN    VARCHAR2,
          pv_errbuf       IN OUT    VARCHAR2,
          pn_retcode      IN OUT    NUMBER,
          pv_segment6        OUT    VARCHAR2,
          pv_cpte_gpe        OUT    VARCHAR2
          )
      IS
  
      vv_expenditure_type VARCHAR2(255);
      vv_fa_date          DATE;
  
      BEGIN
  
      --Récupération du type de dépense nécessaire à la détermination du compte cpte
      --             (à partir de la hiearchie actuelle)
      vv_expenditure_type:= dka_spaautoaccounting_pkg.get_lookup_segment_value_f(
                            pv_segment_value_lookup_set => 'CATEGORIES FA.TYPES DE DEPENSE',
                            pv_segment_value_lookup     => pv_category);
  
      IF vv_expenditure_type IS NULL THEN
        pn_retcode := 2;
        pv_errbuf := pv_errbuf || ' Erreur lors de la recupration du type de depense';
      END IF;
  
  
      pv_cpte_gpe   := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f (pn_project_id,
                                                                         vv_expenditure_type,
                                                                         NULL,
                                                                         TRUNC(gv_ref_date),
                                                                         NULL);
  
      IF pv_cpte_gpe IS NULL THEN-- pb pour récuperer le cpte gpe ..
       pn_retcode := 2;
       pv_errbuf := pv_errbuf || ' Erreur lors de la recupration du type du cpte gpe';
      END IF;
  
      -- Récupération du segment6
  /*
      SELECT MIN (fdp.calendar_period_close_date)
      INTO   vv_fa_date
      FROM   fa_deprn_periods fdp
      WHERE  fdp.book_type_code = pv_book_type_code
      AND    fdp.period_close_date IS NULL;*/

  /*-- récupération de l'appartenance du projet à partir de la date de référence
  
  SELECT hou.NAME
  INTO   pv_segment6
  FROM   pa_cost_dist_overrides co,
         hr_all_organization_units hou
  WHERE      co.project_id = pn_project_id
         --AND vv_fa_date >= co.start_date_active
         --AND vv_fa_date <= NVL (co.end_date_active, vv_fa_date)
         AND gv_ref_date >= co.start_date_active
         AND gv_ref_date <= NVL (co.end_date_active, gv_ref_date)
         AND co.override_from_organization_id = hou.organization_id;
  
  
  EXCEPTION
  
      WHEN OTHERS
      THEN
          pv_errbuf     := 'sortie de DKA_GET_INFOS_AMORT avec erreur EXCEPTION OTHERS:' || SQLERRM;
          pn_retcode    := 2;
  END DKA_GET_INFOS_AMORT; */

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_UPDATE_DATA
  --  Description   : Mise a jour des donnees dans la table DKA_SFABUDGET_WORK
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_UPDATE_DATA(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER) IS
  
    CURSOR Cur_Dka_SFABUDGET_Work IS
      SELECT Gcc_Deprn_Exp_Acc.Segment2 Region -- Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,1,3) ----> Gcc_Deprn_Exp_Acc.Segment2
            ,
             Gcc_Deprn_Exp_Acc.Segment6 Centre -- Phenix2004 :  Remplacer Segment5 par Segment6
            ,
             Gcc_Deprn_Exp_Acc.Segment1 Soc --Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,4,4) par Gcc_Deprn_Exp_Acc.Segment1
            ,
             Fb.Recoverable_Cost,
             Fb.Deprn_Start_Date,
             Fb.Life_In_Months,
             Fat.Description,
             Fa.Asset_Number,
             Fa.Asset_id,
             Ppa.Segment1 Projet,
             Gcc_Deprn_Exp_Acc.Segment4 Cpt_Gpe --Phenix2004 : Remplacer Segment2 par Segment4
            ,
             TRUNC(Fa.Creation_Date) Date_Created,
             Ppa.Project_Id,
             nvl(Dsw.Dotation_Jan, 0) + nvl(Dsw.Dotation_Feb, 0) +
             nvl(Dsw.Dotation_Mar, 0) + nvl(Dsw.Dotation_Avr, 0) +
             nvl(Dsw.Dotation_Mai, 0) + nvl(Dsw.Dotation_Jun, 0) +
             nvl(Dsw.Dotation_Jul, 0) + nvl(Dsw.Dotation_Aou, 0) +
             nvl(Dsw.Dotation_Sep, 0) + nvl(Dsw.Dotation_Oct, 0) +
             nvl(Dsw.Dotation_Nov, 0) + nvl(Dsw.Dotation_Dec, 0) Dotation_Annuelle,
             Dsw.CPTE_CATEG,
             Fa.Attribute_Category_Code categorie,
             Fb.Book_Type_Code
        FROM Dka_SFaBudget_Work       Dsw,
             Fa_Books                 Fb,
             Fa_Additions_Tl          Fat,
             Fa_Additions_B           Fa,
             Pa_Projects_All          Ppa,
             Fa_Distribution_History  Fdh,
             Fa_Distribution_Accounts Fda,
             Gl_Code_Combinations     Gcc_Deprn_Exp_Acc
       WHERE Dsw.Asset_Id = Fb.Asset_Id
         AND Dsw.Book_Type_Code = Fb.Book_Type_Code
         AND Fb.Date_Ineffective IS NULL
         AND Fb.Transaction_Header_Id_Out IS NULL
         AND Fat.Asset_Id = Dsw.Asset_Id
         AND Fat.LANGUAGE = userenv('LANG')
         AND Fa.Asset_Id = Dsw.Asset_Id
            --AND Ppa.Project_Id = Fa.Attribute1
            -- SELOO
            --AND Fdh.Book_Type_Code = Dsw.Book_Type_Code
         AND Fdh.Asset_Id = Dsw.Asset_Id
         AND Fdh.Date_Ineffective IS NULL
         AND Fdh.Transaction_Header_Id_Out IS NULL
         AND Fda.Distribution_Id = Fdh.Distribution_Id
            -- SELOO
            --AND Fda.Book_Type_Code = Fdh.Book_Type_Code
            -- SELOO
         AND Fda.Book_Type_Code = Dsw.Book_Type_Code
         AND Gcc_Deprn_Exp_Acc.Code_Combination_Id =
             Fda.Deprn_Expense_Account_Ccid
            --AND   Gcc_Deprn_Exp_Acc.Code_Combination_Id = Fdh.Code_Combination_Id
         AND Gcc_Deprn_Exp_Acc.segment8 = Ppa.segment1 --(+)
         FOR UPDATE OF Dsw.Region, Dsw.Centre, Dsw.Cpt_Gpe, Dsw.Cost_Center, Dsw.Projet, Dsw.Soc, Dsw.Num_Immo, Dsw.Desc_Immo, Dsw.Recoverable_Cost, Dsw.Date_In, Dsw.Date_From, Dsw.Date_To, Dsw.Life_In_Months, Dotation_Annuelle, Dsw.CPTE_CATEG, Dsw.TOTAL_CESSION_N, Dsw.AJUSTEMENT_N;
  
    CURSOR Cur_Dka_SFABUDGET_Work_Pas_Com IS
      SELECT Fb.Recoverable_Cost,
             Fb.Deprn_Start_Date,
             Fb.Life_In_Months,
             Fat.Description,
             Fa.Asset_Number,
             Fa.Asset_id,
             TRUNC(Fa.Creation_Date) Date_Created,
             nvl(Dsw.Dotation_Jan, 0) + nvl(Dsw.Dotation_Feb, 0) +
             nvl(Dsw.Dotation_Mar, 0) + nvl(Dsw.Dotation_Avr, 0) +
             nvl(Dsw.Dotation_Mai, 0) + nvl(Dsw.Dotation_Jun, 0) +
             nvl(Dsw.Dotation_Jul, 0) + nvl(Dsw.Dotation_Aou, 0) +
             nvl(Dsw.Dotation_Sep, 0) + nvl(Dsw.Dotation_Oct, 0) +
             nvl(Dsw.Dotation_Nov, 0) + nvl(Dsw.Dotation_Dec, 0) Dotation_Annuelle,
             Dsw.CPTE_CATEG,
             Fa.Attribute_Category_Code categorie,
             Fb.Book_Type_Code
        FROM DKA_SFABUDGET_WORK Dsw,
             Fa_Books           Fb,
             Fa_Additions_Tl    Fat,
             Fa_Additions_B     Fa
      --, Fa_Distribution_History Fdh
      --, Fa_Distribution_Accounts Fda
       WHERE Dsw.Asset_Id = Fb.Asset_Id
         AND Dsw.num_immo is null
         AND Dsw.Book_Type_Code = Fb.Book_Type_Code
         AND Fb.Date_Ineffective IS NULL
         AND Fb.Transaction_Header_Id_Out IS NULL
         AND Fat.Asset_Id = Dsw.Asset_Id
         AND Fat.LANGUAGE = userenv('LANG')
         AND Fa.Asset_Id = Dsw.Asset_Id
      /*AND Fdh.Asset_Id = Dsw.Asset_Id
      AND Fdh.Date_Ineffective IS NULL
      AND Fdh.Transaction_Header_Id_Out IS NULL
      AND Fda.Distribution_Id = Fdh.Distribution_Id
      AND Fda.Book_Type_Code = Dsw.Book_Type_Code
      and Fda.Deprn_Expense_Account_Ccid is null*/
      ;
  
    CURSOR Cur_Dka_SFABUDGET_Work_HIST IS
      SELECT /*+ ordered use_nl (fb, fa, ppa, fdh, fda, Gcc_Deprn_Exp_Acc)*/
       Gcc_Deprn_Exp_Acc.Segment2 Region -- Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,1,3) ----> Gcc_Deprn_Exp_Acc.Segment2
      ,
       Gcc_Deprn_Exp_Acc.Segment6 Centre -- Phenix2004 :  Remplacer Segment5 par Segment6
      ,
       Gcc_Deprn_Exp_Acc.Segment1 Soc --Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,4,4) par Gcc_Deprn_Exp_Acc.Segment1
      ,
       Fb.Recoverable_Cost,
       Fb.Deprn_Start_Date,
       Fb.Life_In_Months,
       Fat.Description,
       Fa.Asset_Number,
       Fa.Asset_id,
       Ppa.Segment1 Projet,
       Gcc_Deprn_Exp_Acc.Segment4 Cpt_Gpe --Phenix2004 : Remplacer Segment2 par Segment4
      ,
       TRUNC(Fa.Creation_Date) Date_Created,
       Ppa.Project_Id,
       nvl(Dsw.Dotation_Jan, 0) + nvl(Dsw.Dotation_Feb, 0) +
       nvl(Dsw.Dotation_Mar, 0) + nvl(Dsw.Dotation_Avr, 0) +
       nvl(Dsw.Dotation_Mai, 0) + nvl(Dsw.Dotation_Jun, 0) +
       nvl(Dsw.Dotation_Jul, 0) + nvl(Dsw.Dotation_Aou, 0) +
       nvl(Dsw.Dotation_Sep, 0) + nvl(Dsw.Dotation_Oct, 0) +
       nvl(Dsw.Dotation_Nov, 0) + nvl(Dsw.Dotation_Dec, 0) Dotation_Annuelle,
       Dsw.CPTE_CATEG,
       Fa.Attribute_Category_Code categorie,
       Fb.Book_Type_Code
        FROM Dka_SFaBudget_Work       Dsw,
             Fa_Books                 Fb,
             Fa_Additions_Tl          Fat,
             Fa_Additions_B           Fa,
             Pa_Projects_All          Ppa,
             Fa_Distribution_History  Fdh,
             Fa_Distribution_Accounts Fda,
             Gl_Code_Combinations     Gcc_Deprn_Exp_Acc
       WHERE Dsw.Asset_Id = Fb.Asset_Id
         AND Dsw.Book_Type_Code = Fb.Book_Type_Code
         AND Fb.Date_Ineffective IS NULL
         AND Fb.Transaction_Header_Id_Out IS NULL
         AND Fat.Asset_Id = Dsw.Asset_Id
         AND Fat.LANGUAGE = userenv('LANG')
         AND Fa.Asset_Id = Dsw.Asset_Id
            --AND Ppa.Project_Id = Fa.Attribute1
         AND Fdh.Book_Type_Code = Dsw.Book_Type_Code
         AND Fdh.Asset_Id = Dsw.Asset_Id
         AND Fdh.Date_Ineffective IS NULL
         AND Fdh.Transaction_Header_Id_Out IS NULL
         AND Fda.Distribution_Id = Fdh.Distribution_Id
         AND Fda.Book_Type_Code = Fdh.Book_Type_Code
            --AND Gcc_Deprn_Exp_Acc.Code_Combination_Id = Fda.Deprn_Expense_Account_Ccid
         AND Gcc_Deprn_Exp_Acc.Code_Combination_Id =
             Fdh.Code_Combination_Id
         AND Gcc_Deprn_Exp_Acc.segment8 = Ppa.segment1
         and DSW.Region is null
         FOR UPDATE OF Dsw.Region, Dsw.Centre, Dsw.Cpt_Gpe, Dsw.Cost_Center, Dsw.Projet, Dsw.Soc, Dsw.Num_Immo, Dsw.Desc_Immo, Dsw.Recoverable_Cost, Dsw.Date_In, Dsw.Date_From, Dsw.Date_To, Dsw.Life_In_Months, Dotation_Annuelle, Dsw.CPTE_CATEG, Dsw.TOTAL_CESSION_N, Dsw.AJUSTEMENT_N;
  
    Rec_Dka_SFABUDGET_Work   Cur_Dka_SFABUDGET_Work%ROWTYPE;
    Rec_Dka_SFABUDGET_Work_s Cur_Dka_SFABUDGET_Work_Pas_Com%ROWTYPE;
    Rec_Dka_SFABUDGET_Work_H Cur_Dka_SFABUDGET_Work_HIST%ROWTYPE;
  
    Vv_Org_Name       VARCHAR2(30);
    Vv_Centre         VARCHAR2(30);
    Vv_Msg_Oracle     VARCHAR2(80);
    vv_exception_flag CHAR(1);
    Vv_Nb_Cpte        NUMBER;
    Vv_segment6       VARCHAR2(100);
    Vv_cpte_gpe       VARCHAR2(100);
  
    Cpt                      NUMBER;
    Vv_Recoverable_cost      fa_books.recoverable_cost%TYPE;
    Vv_Total_Cession_N       NUMBER;
    v_adjustment_N           NUMBER;
    Cpt_cession_exo          NUMBER;
    Vv_transaction_header_id fa_transaction_headers.transaction_header_id%TYPE;
    Vv_Adjustments           fa_adjustments.adjustment_amount%TYPE;
    V_TACHE_PARENT           VARCHAR2(5000);
    v_gy_investissement      VARCHAR2(5000);
    v_fc_investissement      VARCHAR2(5000);
    V_project_id_parent      number;
    V_Project                VARCHAR2(5000);
    v_region                 VARCHAR2(30);
  
  BEGIN
    FOR Rec_Dka_SFABUDGET_Work IN Cur_Dka_SFABUDGET_Work LOOP
      -- Recuperation de la tache parent
      BEGIN
        SELECT distinct pt2.task_number, pt2.project_id
          INTO V_TACHE_PARENT, V_project_id_parent
          FROM FA_ADDITIONS      fa1,
               FA_ASSET_INVOICES fai,
               PA_TASKS          pt,
               PA_TASKS          pt2
         WHERE fa1.asset_id = fai.asset_id
           AND pt.task_id = fai.task_id
           AND pt2.task_id = pt.attribute7
           AND fai.asset_id = Rec_Dka_SFABUDGET_Work.Asset_id;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          V_TACHE_PARENT := NULL;
        WHEN OTHERS THEN
          V_TACHE_PARENT := NULL;
      END;
    
      -- Recherche de l'organisation du projet
      DKA_GET_APPARTENANCE(pv_errbuf,
                           pn_retcode,
                           Rec_Dka_SFABUDGET_Work.Project_Id,
                           Vv_Org_Name);
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        RETURN;
      END IF;
    
      IF Vv_Org_Name IS NULL THEN
        dka_tools_pkg.put_outdebug_message('--> Immo ' ||
                                           Rec_Dka_SFABUDGET_Work.Asset_Number);
        dka_tools_pkg.put_outdebug_message('!!!!!');
        dka_tools_pkg.put_outdebug_message('!!!!! Impossible de trouver l''organisation d''appartenance ');
        dka_tools_pkg.put_outdebug_message('!!!!! du projet (' ||
                                           Rec_Dka_SFABUDGET_Work.Project_Id || ')');
        dka_tools_pkg.put_outdebug_message('!!!!!');
        -- Sortie du programme
        Vb_Continuer := FALSE;
      ELSE
        -- Recherche du centre
        DKA_GET_CENTRE(pv_errbuf, pn_retcode, Vv_Org_Name, Vv_Centre);
      
        IF pn_retcode = 2 THEN
          -- Sortie: Erreur systeme
          RETURN;
        END IF;
      
      END IF; /* IF Vv_Org_Name IS NULL */
    
      Begin
        select hr_all_organization_units.name
          into Vv_Centre
          from pa_projects_all, hr_all_organization_units
         where project_id = V_project_id_parent
           and CARRYING_OUT_ORGANIZATION_ID = organization_id;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          Vv_Centre := NULL;
        WHEN OTHERS THEN
          Vv_Centre := NULL;
      END;
    
      /* DKA_GET_INFOS_AMORT
      (
      Rec_Dka_SFABUDGET_Work.categorie,
      Rec_Dka_SFABUDGET_Work.project_id,
      Rec_Dka_SFABUDGET_Work.book_type_code,
      pv_errbuf,
      pn_retcode,
      Vv_segment6,
      Vv_cpte_gpe
      );*/
    
      IF pn_retcode = 2 --Pb lors de la récupération des infos des immos totalement amorties
       THEN
        Vb_Continuer := FALSE;
      END IF;
    
      Select count(*)
        Into Vv_Nb_Cpte
        From FND_FLEX_VALUE_SETS ffvs, fnd_flex_values ffv
       Where ffvs.flex_value_set_id = ffv.flex_value_set_id
         And ffvs.flex_value_set_name = gv_jeu_valeur /* Verif si cpte exception*/
         And ffv.flex_value = Rec_Dka_SFABUDGET_Work.CPTE_CATEG;
    
      IF Vv_Nb_Cpte = 0 THEN
        vv_exception_flag := 'N';
      ELSE
        vv_exception_flag := 'Y';
      END IF;
    
      IF Vb_Continuer THEN
        BEGIN
          UPDATE Dka_SFABUDGET_Work
             SET Region           = Rec_Dka_SFABUDGET_Work.Region,
                 Cpt_Gpe          = Rec_Dka_SFABUDGET_Work.Cpt_Gpe, --Rec_Dka_SFABUDGET_Work.Cpt_Gpe,
                 Cost_Center      = Rec_Dka_SFABUDGET_Work.Centre, --Rec_Dka_SFABUDGET_Work.Segment6, --Phenix2004 Remplacer Segment5 ---> Segment6
                 Projet           = Rec_Dka_SFABUDGET_Work.Projet,
                 Soc              = Rec_Dka_SFABUDGET_Work.Soc,
                 Num_Immo         = Rec_Dka_SFABUDGET_Work.Asset_Number,
                 Desc_Immo        = Rec_Dka_SFABUDGET_Work.Description,
                 Recoverable_Cost = Rec_Dka_SFABUDGET_Work.Recoverable_Cost,
                 Date_In          = Rec_Dka_SFABUDGET_Work.Date_Created,
                 Date_From        = Rec_Dka_SFABUDGET_Work.Deprn_Start_Date,
                 -- Date de fin = date debut + duree de vie (mois) - 1 jour
                 -- 31/01       = 01/01      + 1   = 01/01         - 1
                 Date_To           = ADD_MONTHS(Rec_Dka_SFABUDGET_Work.Deprn_Start_Date,
                                                Rec_Dka_SFABUDGET_Work.Life_In_Months) - 1,
                 Life_In_Months    = Rec_Dka_SFABUDGET_Work.Life_In_Months,
                 Dotation_Annuelle = Rec_Dka_SFABUDGET_Work.Dotation_Annuelle,
                 -- TACHE_PARENT = TACHE_PARENT,
                 LIVRE_FA = Rec_Dka_SFABUDGET_Work.Book_Type_Code,
                 CENTRE   = Vv_Centre
          -- SELOO
           WHERE CURRENT OF Cur_Dka_SFABUDGET_Work;
        
          -- SELOO
          -- UPDATE Dka_SFABUDGET_Work
          -- SET LIVRE_FA = book_type_code;
        
          -- Ajout 09/11/2009  DEBUT
        
          Select Count(*)
            Into Cpt_cession_exo
            From Fa_retirements Fr, Fa_Deprn_Periods Fdp
           Where 1 = 1
             And Fr.Book_Type_Code = Fdp.Book_Type_Code
             and Fr.Book_Type_Code = Rec_Dka_SFABUDGET_Work.Book_Type_Code
             And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                 Fdp.Calendar_Period_Close_Date
             And Fr.Asset_Id = Rec_Dka_SFABUDGET_Work.asset_id
                --And   Fr.Transaction_Header_Id_In = Rec_Dka_SFABUDGET_Work.Transaction_Header_Id_In
             And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
             AND fr.status = 'PROCESSED';
        
          IF Cpt_cession_exo >= 1 AND vv_exception_flag = 'Y' THEN
            -- Cas Cession sur exo en cours et immo d'exception
          
            -- récupération des infos avant la première cession de l'année N
            SELECT fb.cost, fb.transaction_header_id_out
              Into Vv_Recoverable_cost, Vv_transaction_header_id
              FROM fa_retirements fr1, fa_books fb
             Where 1 = 1
               and fb.asset_id = fr1.asset_id
               and fb.book_type_code = fr1.book_type_code
               and fb.book_type_code =
                   Rec_Dka_SFABUDGET_Work.Book_Type_Code
               and fb.transaction_header_id_out =
                   fr1.transaction_header_id_in
               and fr1.status = 'PROCESSED' -- on ne prend que les cessions traitées
               and fr1.retirement_id =
                   ( -- Recupération de la première cession de l'année N
                    Select min(fr.retirement_id)
                      FROM fa_retirements fr, Fa_Deprn_Periods Fdp
                     Where fr.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
                       And Fr.Date_Retired between
                           Fdp.Calendar_Period_Open_Date and
                           Fdp.Calendar_Period_Close_Date
                       And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
                       and fr.book_type_code = fr1.book_type_code
                       and fdp.book_type_code = fr1.book_type_code
                       and fr.status = 'PROCESSED'
                       and fr.book_type_code =
                           Rec_Dka_SFABUDGET_Work.Book_Type_Code);
          
            BEGIN
              -- On recherche s'il existe des ajustement de coûts apres la premiere cession
              -- de l'annee N pour avoir la valeur "Actualisée avant cession"
              Select nvl(sum(decode(fa.debit_credit_flag,
                                    'CR',
                                    -1 * fa.adjustment_amount,
                                    'DR',
                                    fa.adjustment_amount)),
                         0)
                Into Vv_Adjustments
                From fa_adjustments fa
               where 1 = 1
                 and fa.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
                 and fa.book_type_code =
                     Rec_Dka_SFABUDGET_Work.book_type_code
                 and fa.source_type_code = 'ADJUSTMENT'
                 and fa.adjustment_type = 'COST'
                 and fa.transaction_header_id > Vv_transaction_header_id;
            
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --pas d'ajustement
                Vv_Adjustments := 0;
            END;
          
            Vv_Recoverable_cost := Vv_Recoverable_cost + Vv_Adjustments;
          
            Select sum(fr.cost_retired)
              Into Vv_Total_Cession_N
              FROM fa_retirements fr, Fa_Deprn_Periods Fdp
             Where fr.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
               And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                   Fdp.Calendar_Period_Close_Date
               And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
               and fr.book_type_code = fdp.book_type_code
               and fr.status = 'PROCESSED' -- on ne prend que les cessions traitées
               and fr.book_type_code =
                   Rec_Dka_SFABUDGET_Work.Book_Type_Code;
          
            Update Dka_SFABUDGET_Work
               Set Recoverable_Cost = Vv_Recoverable_cost,
                   TOTAL_CESSION_N  = Vv_Total_Cession_N
             WHERE CURRENT OF Cur_Dka_SFABUDGET_Work;
          ELSIF vv_exception_flag = 'Y' THEN
          
            Vv_Total_Cession_N := 0;
          
            Update Dka_SFABUDGET_Work
               Set TOTAL_CESSION_N = Vv_Total_Cession_N
             WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
          
          END IF; -- IF Cpt_cession_exo >= 1
        
          BEGIN
          
            SELECT sum(adjustment_amount)
              INTO v_adjustment_N
              FROM fa_adjustments fa
             WHERE source_type_code = 'DEPRECIATION'
               AND fa.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
               AND fa.book_type_code =
                   Rec_Dka_SFABUDGET_Work.book_type_code;
          EXCEPTION
            WHEN TOO_MANY_ROWS THEN
              --pas d'ajustement
              Vv_Adjustments := 0;
            WHEN OTHERS THEN
              Vv_Adjustments := 0;
            
          END;
        -- SHA :EDB304 
		BEGIN
		
		SELECT distinct pt.task_number, ppa.segment1
		  INTO v_gy_investissement ,v_fc_investissement
          FROM FA_ADDITIONS      fa1,
               FA_ASSET_INVOICES fai,
               PA_TASKS          pt,
               pa_projects_all ppa
         WHERE fa1.asset_id = fai.asset_id
           AND pt.task_id = fai.task_id
           and ppa.project_id = pt.project_id
           and fai.asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
		   EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          v_gy_investissement := NULL;
		  v_fc_investissement := NULL;
        WHEN OTHERS THEN
          v_gy_investissement := NULL;
		  v_fc_investissement := NULL;
		  
		  END;
		-- FIN SHA EDB304   
          Select sum(fr.cost_retired)
            Into Vv_Total_Cession_N
            FROM fa_retirements fr, Fa_Deprn_Periods Fdp
           Where fr.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
             And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                 Fdp.Calendar_Period_Close_Date
                --   And    Fdp.Fiscal_Year = to_char(gv_ref_date,'RRRR')
             and fr.book_type_code = fdp.book_type_code
             and fr.status = 'PROCESSED' -- on ne prend que les cessions traitées
             and fr.book_type_code = Rec_Dka_SFABUDGET_Work.Book_Type_Code;
        
          Update Dka_SFABUDGET_Work
             Set TOTAL_CESSION_N = Vv_Total_Cession_N
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id
             and book_type_code = Rec_Dka_SFABUDGET_Work.Book_Type_Code;
        
          UPDATE Dka_SFABUDGET_Work
             SET TACHE_PARENT = V_TACHE_PARENT
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
        
          UPDATE Dka_SFABUDGET_Work
             SET AJUSTEMENT_N = v_adjustment_N
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id
             and book_type_code = Rec_Dka_SFABUDGET_Work.book_type_code; -- SELOO;
			 
		 UPDATE Dka_SFABUDGET_Work
             SET FC_INVESTISSEMENT = v_fc_investissement
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;--SHA EDB304
		   
		 UPDATE Dka_SFABUDGET_Work
             SET GY_INVESTISSEMENT = v_gy_investissement
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;--SHA EDB304
          -- Ajout 22/07/2008 FIN
        
        EXCEPTION
          WHEN OTHERS THEN
            Vv_Msg_Oracle := SUBSTR(SQLERRM, 1, 80);
            dka_tools_pkg.put_outdebug_message('--> Immo ' ||
                                               Rec_Dka_SFABUDGET_Work.Asset_Number);
            dka_tools_pkg.put_outdebug_message('!!!!!');
            dka_tools_pkg.put_outdebug_message('!!!!! Erreur ORACLE lors de la mise a jour de la table Dka_SFABUDGET_Work');
            dka_tools_pkg.put_outdebug_message('!!!!! ' || Vv_Msg_Oracle);
          
            -- Sortie du programme
            Vb_Continuer := FALSE;
        END;
      
      END IF; /* IF Vb_Continuer */
    
    END LOOP;
  
    Commit;
  
    FOR Rec_SFABUDGET_Work_Pas_Com IN Cur_Dka_SFABUDGET_Work_Pas_Com LOOP
      begin
        SELECT ppa.segment1
          INTO V_Project
          FROM FA_ADDITIONS      fa1,
               FA_ASSET_INVOICES fai,
               PA_TASKS          pt,
               PA_TASKS          pt2,
               pa_projects_all   ppa
         WHERE fa1.asset_id = fai.asset_id
           AND pt.task_id = fai.task_id
           AND pt2.task_id = pt.attribute7
           AND fai.asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
           and ppa.project_id = pt2.project_id;
      EXCEPTION
        WHEN OTHERS THEN
          V_Project := null;
      end;
      begin
        select distinct region
          into v_region
          from Dka_SFABUDGET_Work
         where asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
           and region is not null;
      EXCEPTION
        WHEN OTHERS THEN
          v_region := null;
      end;
    
      IF Vb_Continuer THEN
        BEGIN
          UPDATE Dka_SFABUDGET_Work
             SET Region           = v_region,
                 SOC              = substr(Rec_SFABUDGET_Work_Pas_Com.Book_Type_Code,
                                           1,
                                           4),
                 Num_Immo         = Rec_SFABUDGET_Work_Pas_Com.Asset_Number,
                 Desc_Immo        = Rec_SFABUDGET_Work_Pas_Com.Description,
                 Recoverable_Cost = Rec_SFABUDGET_Work_Pas_Com.Recoverable_Cost,
                 Date_In          = Rec_SFABUDGET_Work_Pas_Com.Date_Created,
                 Date_From        = Rec_SFABUDGET_Work_Pas_Com.Deprn_Start_Date,
                 -- Date de fin = date debut + duree de vie (mois) - 1 jour
                 -- 31/01       = 01/01      + 1   = 01/01         - 1
                 Date_To           = ADD_MONTHS(Rec_SFABUDGET_Work_Pas_Com.Deprn_Start_Date,
                                                Rec_SFABUDGET_Work_Pas_Com.Life_In_Months) - 1,
                 Life_In_Months    = Rec_SFABUDGET_Work_Pas_Com.Life_In_Months,
                 Dotation_Annuelle = Rec_SFABUDGET_Work_Pas_Com.Dotation_Annuelle,
                 -- TACHE_PARENT = TACHE_PARENT,
                 LIVRE_FA = Rec_SFABUDGET_Work_Pas_Com.Book_Type_Code,
                 -- SELOO
                 Projet = V_Project
           where asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
             and Num_Immo is null;
        
          -- SELOO
          -- UPDATE Dka_SFABUDGET_Work
          -- SET LIVRE_FA = book_type_code;
        
          BEGIN
          
            SELECT sum(adjustment_amount)
              INTO v_adjustment_N
              FROM fa_adjustments fa
             WHERE source_type_code = 'DEPRECIATION'
               AND fa.asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
               AND fa.book_type_code =
                   Rec_SFABUDGET_Work_Pas_Com.book_type_code;
          EXCEPTION
            WHEN TOO_MANY_ROWS THEN
              --pas d'ajustement
              Vv_Adjustments := 0;
            WHEN OTHERS THEN
              Vv_Adjustments := 0;
            
          END;
        
          UPDATE Dka_SFABUDGET_Work
             SET AJUSTEMENT_N = v_adjustment_N
           WHERE asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
             and book_type_code = Rec_SFABUDGET_Work_Pas_Com.book_type_code; -- SELOO;
          -- Ajout 22/07/2008 FIN
          Select sum(fr.cost_retired)
            Into Vv_Total_Cession_N
            FROM fa_retirements fr, Fa_Deprn_Periods Fdp
           Where fr.asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
             And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                 Fdp.Calendar_Period_Close_Date
                -- And    Fdp.Fiscal_Year = to_char(gv_ref_date,'RRRR')
             and fr.book_type_code = fdp.book_type_code
             and fr.status = 'PROCESSED' -- on ne prend que les cessions traitées
             and fr.book_type_code =
                 Rec_SFABUDGET_Work_Pas_Com.Book_Type_Code;
        
          Update Dka_SFABUDGET_Work
             Set TOTAL_CESSION_N = Vv_Total_Cession_N
           WHERE asset_id = Rec_SFABUDGET_Work_Pas_Com.asset_id
             and book_type_code = Rec_SFABUDGET_Work_Pas_Com.Book_Type_Code;
        
        EXCEPTION
          WHEN OTHERS THEN
            Vv_Msg_Oracle := SUBSTR(SQLERRM, 1, 80);
            dka_tools_pkg.put_outdebug_message('--> Immo ' ||
                                               Rec_SFABUDGET_Work_Pas_Com.Asset_Number);
            dka_tools_pkg.put_outdebug_message('!!!!!');
            dka_tools_pkg.put_outdebug_message('!!!!! Erreur ORACLE lors de la mise a jour de la table Dka_SFABUDGET_Work');
            dka_tools_pkg.put_outdebug_message('!!!!! ' || Vv_Msg_Oracle);
          
            -- Sortie du programme
            Vb_Continuer := FALSE;
        END;
      
      END IF; /* IF Vb_Continuer */
    
    END LOOP;
  
    FOR Rec_Dka_SFABUDGET_Work_H IN Cur_Dka_SFABUDGET_Work_HIST LOOP
      UPDATE Dka_SFABUDGET_Work
         SET Region           = Rec_Dka_SFABUDGET_Work_H.Region,
             Cpt_Gpe          = Rec_Dka_SFABUDGET_Work_H.Cpt_Gpe, --Rec_Dka_SFABUDGET_Work_H.Cpt_Gpe,
             Cost_Center      = Rec_Dka_SFABUDGET_Work_H.Centre, --Rec_Dka_SFABUDGET_Work_H.Segment6, --Phenix2004 Remplacer Segment5 ---> Segment6
             Projet           = Rec_Dka_SFABUDGET_Work_H.Projet,
             Soc              = Rec_Dka_SFABUDGET_Work_H.Soc,
             Num_Immo         = Rec_Dka_SFABUDGET_Work_H.Asset_Number,
             Desc_Immo        = Rec_Dka_SFABUDGET_Work_H.Description,
             Recoverable_Cost = Rec_Dka_SFABUDGET_Work_H.Recoverable_Cost,
             Date_In          = Rec_Dka_SFABUDGET_Work_H.Date_Created,
             Date_From        = Rec_Dka_SFABUDGET_Work_H.Deprn_Start_Date,
             -- Date de fin = date debut + duree de vie (mois) - 1 jour
             -- 31/01       = 01/01      + 1   = 01/01         - 1
             Date_To           = ADD_MONTHS(Rec_Dka_SFABUDGET_Work_H.Deprn_Start_Date,
                                            Rec_Dka_SFABUDGET_Work_H.Life_In_Months) - 1,
             Life_In_Months    = Rec_Dka_SFABUDGET_Work_H.Life_In_Months,
             Dotation_Annuelle = Rec_Dka_SFABUDGET_Work_H.Dotation_Annuelle,
             -- TACHE_PARENT = TACHE_PARENT,
             LIVRE_FA = Rec_Dka_SFABUDGET_Work_H.Book_Type_Code,
             CENTRE   = Rec_Dka_SFABUDGET_Work_H.Centre
      -- SELOO
       WHERE CURRENT OF Cur_Dka_SFABUDGET_Work_HIST;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_UPDATE_DATA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_UPDATE_DATA;

  PROCEDURE DKA_UPDATE_IFRS_DATA(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode IN OUT NUMBER) IS
  
    CURSOR Cur_Dka_SFABUDGET_Work IS
      SELECT 'DLS' Region -- Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,1,3) ----> Gcc_Deprn_Exp_Acc.Segment2
            ,
             '0' Centre -- Phenix2004 :  Remplacer Segment5 par Segment6
            ,
             '0' Soc --Phenix2004 : Remplacer SUBSTR(Gcc_Deprn_Exp_Acc.Segment1,4,4) par Gcc_Deprn_Exp_Acc.Segment1
            ,
             Fb.Recoverable_Cost,
             Fb.Deprn_Start_Date,
             Fb.Life_In_Months,
             Fat.Description,
             Fa.Asset_Number,
             Fa.Asset_id,
             '0' Projet,
             '0' Cpt_Gpe --Phenix2004 : Remplacer Segment2 par Segment4
            ,
             TRUNC(Fa.Creation_Date) Date_Created,
             0 Project_Id,
             nvl(Dsw.Dotation_Jan, 0) + nvl(Dsw.Dotation_Feb, 0) +
             nvl(Dsw.Dotation_Mar, 0) + nvl(Dsw.Dotation_Avr, 0) +
             nvl(Dsw.Dotation_Mai, 0) + nvl(Dsw.Dotation_Jun, 0) +
             nvl(Dsw.Dotation_Jul, 0) + nvl(Dsw.Dotation_Aou, 0) +
             nvl(Dsw.Dotation_Sep, 0) + nvl(Dsw.Dotation_Oct, 0) +
             nvl(Dsw.Dotation_Nov, 0) + nvl(Dsw.Dotation_Dec, 0) Dotation_Annuelle,
             Dsw.CPTE_CATEG,
             Fa.Attribute_Category_Code categorie,
             Fb.Book_Type_Code
        FROM Dka_SFaBudget_Work Dsw,
             Fa_Books           Fb,
             Fa_Additions_Tl    Fat,
             Fa_Additions_B     Fa
       WHERE Dsw.Asset_Id = Fb.Asset_Id
         AND Dsw.Book_Type_Code = Fb.Book_Type_Code
         AND Fb.Date_Ineffective IS NULL
         AND Fb.Transaction_Header_Id_Out IS NULL
         AND Fat.Asset_Id = Dsw.Asset_Id
         AND Fat.LANGUAGE = 'F'
         AND Fa.Asset_Id = Dsw.Asset_Id
         and not exists
       (select distinct 1
                from Fa_Distribution_History Fdh
               where Fdh.Book_Type_Code = Dsw.Book_Type_Code)
      -- SELOO
         FOR UPDATE OF Dsw.Region, Dsw.Centre, Dsw.Cpt_Gpe, Dsw.Cost_Center, Dsw.Projet, Dsw.Soc, Dsw.Num_Immo, Dsw.Desc_Immo, Dsw.Recoverable_Cost, Dsw.Date_In, Dsw.Date_From, Dsw.Date_To, Dsw.Life_In_Months, Dotation_Annuelle, Dsw.CPTE_CATEG, Dsw.TOTAL_CESSION_N, Dsw.AJUSTEMENT_N;
  
    Rec_Dka_SFABUDGET_Work Cur_Dka_SFABUDGET_Work%ROWTYPE;
  
    Vv_Org_Name       VARCHAR2(30);
    Vv_Centre         VARCHAR2(30);
    Vv_Msg_Oracle     VARCHAR2(80);
    vv_exception_flag CHAR(1);
    Vv_Nb_Cpte        NUMBER;
    Vv_segment6       VARCHAR2(100);
    Vv_cpte_gpe       VARCHAR2(100);
  
    Cpt                      NUMBER;
    Vv_Recoverable_cost      fa_books.recoverable_cost%TYPE;
    Vv_Total_Cession_N       NUMBER;
    v_adjustment_N           NUMBER;
    Cpt_cession_exo          NUMBER;
    Vv_transaction_header_id fa_transaction_headers.transaction_header_id%TYPE;
    Vv_Adjustments           fa_adjustments.adjustment_amount%TYPE;
    V_TACHE_PARENT           VARCHAR2(5000);
  
  BEGIN
  
    FOR Rec_Dka_SFABUDGET_Work IN Cur_Dka_SFABUDGET_Work LOOP
      -- Recuperation de la tache parent
      BEGIN
        SELECT distinct pt2.task_number
          INTO V_TACHE_PARENT
          FROM FA_ADDITIONS      fa1,
               FA_ASSET_INVOICES fai,
               PA_TASKS          pt,
               PA_TASKS          pt2
         WHERE fa1.asset_id = fai.asset_id
           AND pt.task_id = fai.task_id
           AND pt2.task_id = pt.attribute7
           AND fai.asset_id = Rec_Dka_SFABUDGET_Work.Asset_id;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          V_TACHE_PARENT := NULL;
        WHEN OTHERS THEN
          V_TACHE_PARENT := NULL;
      END;
    
      -- Recherche de l'organisation du projet
      /*   DKA_GET_APPARTENANCE
        (
        pv_errbuf     ,
        pn_retcode    ,
        Rec_Dka_SFABUDGET_Work.Project_Id ,
        Vv_Org_Name ) ;
      
      IF pn_retcode = 2
      THEN
         -- Sortie: Erreur systeme
         RETURN;
      END IF;
      
      IF Vv_Org_Name IS NULL
      THEN
          dka_tools_pkg.put_outdebug_message ( '--> Immo '||Rec_Dka_SFABUDGET_Work.Asset_Number );
          dka_tools_pkg.put_outdebug_message ( '!!!!!');
          dka_tools_pkg.put_outdebug_message ( '!!!!! Impossible de trouver l''organisation d''appartenance ');
          dka_tools_pkg.put_outdebug_message ( '!!!!! du projet ('|| Rec_Dka_SFABUDGET_Work.Project_Id ||')');
          dka_tools_pkg.put_outdebug_message ( '!!!!!');
          -- Sortie du programme
          Vb_Continuer := FALSE;
      ELSE
         -- Recherche du centre
         DKA_GET_CENTRE
           (
           pv_errbuf   ,
           pn_retcode  ,
           Vv_Org_Name ,
           Vv_Centre
           );
      
           IF pn_retcode = 2
           THEN
              -- Sortie: Erreur systeme
              RETURN;
           END IF;
      
      
      END IF; */ /* IF Vv_Org_Name IS NULL */
    
      /* DKA_GET_INFOS_AMORT
      (
      Rec_Dka_SFABUDGET_Work.categorie,
      Rec_Dka_SFABUDGET_Work.project_id,
      Rec_Dka_SFABUDGET_Work.book_type_code,
      pv_errbuf,
      pn_retcode,
      Vv_segment6,
      Vv_cpte_gpe
      );*/
    
      IF pn_retcode = 2 --Pb lors de la récupération des infos des immos totalement amorties
       THEN
        Vb_Continuer := FALSE;
      END IF;
    
      Select count(*)
        Into Vv_Nb_Cpte
        From FND_FLEX_VALUE_SETS ffvs, fnd_flex_values ffv
       Where ffvs.flex_value_set_id = ffv.flex_value_set_id
         And ffvs.flex_value_set_name = gv_jeu_valeur /* Verif si cpte exception*/
         And ffv.flex_value = Rec_Dka_SFABUDGET_Work.CPTE_CATEG;
    
      IF Vv_Nb_Cpte = 0 THEN
        vv_exception_flag := 'N';
      ELSE
        vv_exception_flag := 'Y';
      END IF;
    
      IF Vb_Continuer THEN
        BEGIN
          UPDATE Dka_SFABUDGET_Work
             SET Region           = Rec_Dka_SFABUDGET_Work.Region,
                 Cpt_Gpe          = Rec_Dka_SFABUDGET_Work.Cpt_Gpe, --Rec_Dka_SFABUDGET_Work.Cpt_Gpe,
                 Cost_Center      = Rec_Dka_SFABUDGET_Work.Centre, --Rec_Dka_SFABUDGET_Work.Segment6, --Phenix2004 Remplacer Segment5 ---> Segment6
                 Projet           = Rec_Dka_SFABUDGET_Work.Projet,
                 Soc              = Rec_Dka_SFABUDGET_Work.Soc,
                 Num_Immo         = Rec_Dka_SFABUDGET_Work.Asset_Number,
                 Desc_Immo        = Rec_Dka_SFABUDGET_Work.Description,
                 Recoverable_Cost = Rec_Dka_SFABUDGET_Work.Recoverable_Cost,
                 Date_In          = Rec_Dka_SFABUDGET_Work.Date_Created,
                 Date_From        = Rec_Dka_SFABUDGET_Work.Deprn_Start_Date,
                 -- Date de fin = date debut + duree de vie (mois) - 1 jour
                 -- 31/01       = 01/01      + 1   = 01/01         - 1
                 Date_To           = ADD_MONTHS(Rec_Dka_SFABUDGET_Work.Deprn_Start_Date,
                                                Rec_Dka_SFABUDGET_Work.Life_In_Months) - 1,
                 Life_In_Months    = Rec_Dka_SFABUDGET_Work.Life_In_Months,
                 Dotation_Annuelle = Rec_Dka_SFABUDGET_Work.Dotation_Annuelle,
                 -- TACHE_PARENT = TACHE_PARENT,
                 LIVRE_FA = Rec_Dka_SFABUDGET_Work.Book_Type_Code
           WHERE CURRENT OF Cur_Dka_SFABUDGET_Work;
        
          -- SELOO
          UPDATE Dka_SFABUDGET_Work SET LIVRE_FA = book_type_code;
        
          -- Ajout 09/11/2009  DEBUT
        
          Select Count(*)
            Into Cpt_cession_exo
            From Fa_retirements Fr, Fa_Deprn_Periods Fdp
           Where 1 = 1
             And Fr.Book_Type_Code = Fdp.Book_Type_Code
             and Fr.Book_Type_Code = Rec_Dka_SFABUDGET_Work.Book_Type_Code
             And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                 Fdp.Calendar_Period_Close_Date
             And Fr.Asset_Id = Rec_Dka_SFABUDGET_Work.asset_id
                --And   Fr.Transaction_Header_Id_In = Rec_Dka_SFABUDGET_Work.Transaction_Header_Id_In
             And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
             AND fr.status = 'PROCESSED';
        
          IF Cpt_cession_exo >= 1 AND vv_exception_flag = 'Y' THEN
            -- Cas Cession sur exo en cours et immo d'exception
          
            -- récupération des infos avant la première cession de l'année N
            SELECT fb.cost, fb.transaction_header_id_out
              Into Vv_Recoverable_cost, Vv_transaction_header_id
              FROM fa_retirements fr1, fa_books fb
             Where 1 = 1
               and fb.asset_id = fr1.asset_id
               and fb.book_type_code = fr1.book_type_code
               and fb.book_type_code =
                   Rec_Dka_SFABUDGET_Work.Book_Type_Code
               and fb.transaction_header_id_out =
                   fr1.transaction_header_id_in
               and fr1.status = 'PROCESSED' -- on ne prend que les cessions traitées
               and fr1.retirement_id =
                   ( -- Recupération de la première cession de l'année N
                    Select min(fr.retirement_id)
                      FROM fa_retirements fr, Fa_Deprn_Periods Fdp
                     Where fr.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
                       And Fr.Date_Retired between
                           Fdp.Calendar_Period_Open_Date and
                           Fdp.Calendar_Period_Close_Date
                       And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
                       and fr.book_type_code = fr1.book_type_code
                       and fdp.book_type_code = fr1.book_type_code
                       and fr.status = 'PROCESSED'
                       and fr.book_type_code =
                           Rec_Dka_SFABUDGET_Work.Book_Type_Code);
          
            BEGIN
              -- On recherche s'il existe des ajustement de coûts apres la premiere cession
              -- de l'annee N pour avoir la valeur "Actualisée avant cession"
              Select nvl(sum(decode(fa.debit_credit_flag,
                                    'CR',
                                    -1 * fa.adjustment_amount,
                                    'DR',
                                    fa.adjustment_amount)),
                         0)
                Into Vv_Adjustments
                From fa_adjustments fa
               where 1 = 1
                 and fa.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
                 and fa.book_type_code =
                     Rec_Dka_SFABUDGET_Work.book_type_code
                 and fa.source_type_code = 'ADJUSTMENT'
                 and fa.adjustment_type = 'COST'
                 and fa.transaction_header_id > Vv_transaction_header_id;
            
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --pas d'ajustement
                Vv_Adjustments := 0;
            END;
          
            Vv_Recoverable_cost := Vv_Recoverable_cost + Vv_Adjustments;
          
            Select sum(fr.cost_retired)
              Into Vv_Total_Cession_N
              FROM fa_retirements fr, Fa_Deprn_Periods Fdp
             Where fr.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
               And Fr.Date_Retired between Fdp.Calendar_Period_Open_Date and
                   Fdp.Calendar_Period_Close_Date
               And Fdp.Fiscal_Year = to_char(gv_ref_date, 'RRRR')
               and fr.book_type_code = fdp.book_type_code
               and fr.status = 'PROCESSED' -- on ne prend que les cessions traitées
               and fr.book_type_code =
                   Rec_Dka_SFABUDGET_Work.Book_Type_Code;
          
            Update Dka_SFABUDGET_Work
               Set Recoverable_Cost = Vv_Recoverable_cost,
                   TOTAL_CESSION_N  = Vv_Total_Cession_N
             WHERE CURRENT OF Cur_Dka_SFABUDGET_Work;
          ELSIF vv_exception_flag = 'Y' THEN
          
            Vv_Total_Cession_N := 0;
          
            Update Dka_SFABUDGET_Work
               Set TOTAL_CESSION_N = Vv_Total_Cession_N
             WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
          
          END IF; -- IF Cpt_cession_exo >= 1
        
          BEGIN
          
            SELECT adjustment_amount
              INTO v_adjustment_N
              FROM fa_adjustments fa
             WHERE source_type_code = 'DEPRECIATION'
               AND fa.asset_id = Rec_Dka_SFABUDGET_Work.asset_id
               AND fa.book_type_code =
                   Rec_Dka_SFABUDGET_Work.book_type_code;
          EXCEPTION
            WHEN TOO_MANY_ROWS THEN
              --pas d'ajustement
              Vv_Adjustments := 0;
            WHEN OTHERS THEN
              Vv_Adjustments := 0;
            
          END;
        
          UPDATE Dka_SFABUDGET_Work
             SET TACHE_PARENT = V_TACHE_PARENT
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
        
          UPDATE Dka_SFABUDGET_Work
             SET AJUSTEMENT_N = v_adjustment_N
           WHERE asset_id = Rec_Dka_SFABUDGET_Work.asset_id;
          -- Ajout 22/07/2008 FIN
        
        EXCEPTION
          WHEN OTHERS THEN
            Vv_Msg_Oracle := SUBSTR(SQLERRM, 1, 80);
            dka_tools_pkg.put_outdebug_message('--> Immo ' ||
                                               Rec_Dka_SFABUDGET_Work.Asset_Number);
            dka_tools_pkg.put_outdebug_message('!!!!!');
            dka_tools_pkg.put_outdebug_message('!!!!! Erreur ORACLE lors de la mise a jour de la table Dka_SFABUDGET_Work');
            dka_tools_pkg.put_outdebug_message('!!!!! ' || Vv_Msg_Oracle);
          
            -- Sortie du programme
            Vb_Continuer := FALSE;
        END;
      
      END IF; /* IF Vb_Continuer */
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_UPDATE_DATA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_UPDATE_IFRS_DATA;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_AMORT_REEL
  --  Description   : suppression des tables generees par les traitements de prevision des amortissements
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_AMORT_REEL(pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode IN OUT NUMBER
                           -- Pv_End_Period     IN       VARCHAR2
                           ) IS
  
    Pv_End_Period Fa_Calendar_Periods.Period_Name%TYPE;
    --Pv_Fisrt_Period         Fa_Calendar_Periods.Period_Name%TYPE;
    Pv_Montant       Number := 0;
    Pv_End_Period_PC fa_deprn_periods.period_counter%TYPE;
    --Pv_First_Period_PC      fa_deprn_periods.period_counter%TYPE;
  
    Cursor cur_immo is
      Select Asset_id, fbc.BOOK_TYPE_CODE, fbc.Deprn_Calendar calendar
        From DKA_SFABUDGET_WORK DSW, FA_BOOK_CONTROLS FBC
       Where FBC.Book_Type_Code = DSW.Book_Type_Code -- SL
            -- SELOO
         AND Fbc.Book_Class in ('CORPORATE', 'TAX')
         AND Fbc.Date_Ineffective IS NULL
      -- SELOO*
      --and rownum <=10
      ;
  
  BEGIN
  
    dka_tools_pkg.put_log_message('DKA_AMORT_REEL(+)');
  
    FOR ligne_immo in cur_immo LOOP
    
      Begin
      
        -- Si une exception se déclenche à ce niveau pour cette immo alors Rien à faire car pas d'amortissements réels en table
        /*SELECT
          Fdp.Period_Counter
        INTO
          Pv_First_Period_PC
        FROM
          Fa_Calendar_Periods Fcp,
          fa_deprn_periods    Fdp
        WHERE
            Fcp.Calendar_Type = ligne_immo.calendar
        AND Fcp.Start_Date = TRUNC(gv_ref_date,'YYYY')
        And Fcp.Period_Name = Fdp.Period_Name
        And Fdp.Book_Type_Code = ligne_immo.book_type_code
            ;*/
      
        Begin
        
          Select distinct fdp.period_counter
            Into Pv_End_Period_PC
            From fa_deprn_periods fdp, fa_deprn_summary fds
           Where fdp.book_type_code = ligne_immo.book_type_code
             And ADD_MONTHS(TRUNC(gv_ref_date), -1) between
                 fdp.calendar_period_open_date And
                 fdp.calendar_period_close_date
             And Fds.Book_Type_Code = fdp.book_type_code
             And fdp.period_counter = fds.period_counter
             And Fds.asset_id = ligne_immo.asset_id;
        
        Exception
          --Pb lors de la récupération de la période de fin --> récupération de la + gde période
          When others then
          
            Select Max(fds.period_counter)
              Into Pv_End_Period_PC
              From fa_deprn_summary fds
             Where 1 = 1
               And fds.book_type_code = ligne_immo.book_type_code
               And fds.asset_id = ligne_immo.asset_id;
        End;
      
        -- Les 2 periodes ont été récupérés
      
        /*   Select nvl(sum(nvl(fds.deprn_amount,0)),0)
           Into   Pv_Montant
           From   fa_deprn_summary fds
           Where  fds.asset_id = ligne_immo.asset_id
           And    fds.book_type_code = ligne_immo.book_type_code
           And    fds.period_counter between Pv_First_Period_PC and Pv_End_Period_PC;
        */
      
        Select nvl(fds.deprn_reserve, 0)
          Into Pv_Montant
          From fa_deprn_summary fds
         Where fds.asset_id = ligne_immo.asset_id
           And fds.book_type_code = ligne_immo.book_type_code
           And fds.period_counter = Pv_End_Period_PC;
      
        Update DKA_SFABUDGET_WORK Dsw
        -- Set    Dsw.DOTATION_N = ROUND(Pv_Montant/1000,2) + TO_NUMBER(DOTATION_N) -- SELOO
           Set Dsw.DOTATION_N = Pv_Montant + TO_NUMBER(DOTATION_N)
         Where 1 = 1
           And Dsw.Asset_Id = ligne_immo.asset_id
           And Dsw.Book_Type_Code = ligne_immo.book_type_code;
      
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
    END LOOP;
  
    dka_tools_pkg.put_log_message('DKA_AMORT_REEL(-)');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_AMORT_REEL avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_AMORT_REEL;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_IMM_EXCEP
  --  Description   : Insertion dans la table de travail des immobilisations dont la valeur nette compteble est nulle
  --                 et qui sont rattachées à un compte d'exception. Non géré en standard.
  --
  --
  --  PARAMETRES    :
  --  pv_errbuf                 Entrée/Sortie      message d'erreur
  --  pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_INS_IMM_EXCEP(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode IN OUT NUMBER) IS
  
    TYPE Vt_Deprn_Amount_Type IS TABLE OF FA_DEPRN_SUMMARY.Deprn_Amount%TYPE index by binary_integer;
  
    Vt_Deprn_Amount       Vt_Deprn_Amount_Type;
    Vv_old_book_type_code FA_DEPRN_SUMMARY.Book_Type_Code%TYPE := '';
    vn_pc_jan_N           NUMBER;
    vn_pc_cur_N           NUMBER;
    vv_amount             FA_DEPRN_SUMMARY.Deprn_Amount%TYPE;
  
    Cursor cur_immo is
      Select distinct Fab.Asset_id,
                      Fb.Book_Type_Code,
                      Fcb.Asset_Cost_Acct cpte_categ,
                      Fc.Segment1,
                      Fc.Segment2
        From fa_additions_b      Fab,
             fa_books            Fb,
             FND_FLEX_VALUE_SETS Ffvs,
             fnd_flex_values     Ffv,
             Fa_Categories_b_Kfv Fc,
             Fa_Category_Books   Fcb,
             Fa_Book_Controls    Fbc,
             Fa_Deprn_Periods    Fdp --- Add 31/03/2008
       Where 1 = 1
         And Fdp.Book_Type_Code = Fcb.Book_Type_Code --Add 31/03/2008
         And Fdp.Calendar_Period_Open_Date = TRUNC(gv_ref_date, 'YYYY') --Add 31/03/2008 --01/01/Annee N
         And NVL(Fb.Period_Counter_Fully_Retired, Fdp.Period_Counter) >=
             Fdp.Period_Counter --Add  31/03/2008
            -- SELOO
         AND Fbc.Book_Class in ('CORPORATE', 'TAX')
         AND Fbc.Date_Ineffective IS NULL
         AND Fbc.Book_Type_Code = Fb.Book_Type_Code
         And Fab.asset_id = fb.asset_id
         And Fb.date_ineffective is null
         And (Fb.cost = 0 or Fb.period_counter_fully_reserved is not null or
             Fb.period_counter_life_complete is not null or
             fb.depreciate_flag = 'NO' -- Add 31/03/2008
             )
         And Ffvs.flex_value_set_id = Ffv.flex_value_set_id
         AND Ffvs.flex_value_set_name = gv_jeu_valeur
         AND Ffv.flex_value = Fcb.asset_cost_acct
         And Fc.category_id = Fcb.category_id
         And Fcb.category_id = Fab.asset_category_id
         And Fcb.book_type_code = Fb.book_type_code
         And Fab.Asset_Type != 'CIP' -- Add 31/03/2008
         And Not Exists (Select '1'
                From Dka_Sfabudget_Work Dsw
               Where Dsw.asset_id = Fab.asset_id);
  
  BEGIN
  
    dka_tools_pkg.put_log_message('DKA_INS_IMM_EXCEP(+)');
  
    -- Initialisation du tableau
    FOR i in 0 .. 11 LOOP
      Vt_Deprn_Amount(i) := 0;
    END LOOP;
  
    FOR ligne_immo in cur_immo LOOP
    
      IF Vv_old_book_type_code IS NULL OR
         Vv_old_book_type_code != ligne_immo.book_type_code THEN
        -- Calcul des period_counters pour les livres concernés
      
        SELECT min(Fdp.Period_Counter), -- Period_counter pour JAN de l'année N
               max(Fdp.Period_Counter) -- Period_counter pour la periode sur laquelle se situe gv_ref_date (année N)
          INTO vn_pc_jan_N, vn_pc_cur_N
          FROM FA_DEPRN_PERIODS FDP
         WHERE trunc(FDP.Calendar_Period_Open_Date, 'YEAR') =
               trunc(gv_ref_date, 'YEAR')
           AND Fdp.Book_Type_Code = ligne_immo.book_type_code;
      
        Vv_old_book_type_code := ligne_immo.book_type_code;
      END IF;
    
      FOR i in 0 .. vn_pc_cur_N - vn_pc_jan_N LOOP
      
        vv_amount := 0;
      
        begin
          SELECT NVL(FDS.Deprn_Amount, 0)
            INTO vv_amount
            FROM FA_DEPRN_SUMMARY FDS
           where fds.asset_id = ligne_immo.asset_id
             and fds.book_type_code = ligne_immo.book_type_code
             and fds.period_counter = vn_pc_jan_N + i;
        
          Vt_Deprn_Amount(i) := vv_amount; -- SL 09/11/2009
          --Vt_Deprn_Amount (i) := ROUND(vv_amount / 1000,2); -- SL 09/11/2009
        exception
          when no_data_found then
            Vt_Deprn_Amount(i) := 0;
            --dka_tools_pkg.put_log_message ('asset_id :'|| ligne_immo.asset_id || ' no data_found');
        end;
      
      END LOOP;
    
      INSERT INTO DKA_SFABUDGET_WORK
        (Asset_Id,
         Book_Type_Code,
         DOTATION_JAN,
         DOTATION_FEB,
         DOTATION_MAR,
         DOTATION_AVR,
         DOTATION_MAI,
         DOTATION_JUN,
         DOTATION_JUL,
         DOTATION_AOU,
         DOTATION_SEP,
         DOTATION_OCT,
         DOTATION_NOV,
         DOTATION_DEC,
         DOTATION_N,
         CATEGORIE,
         CPTE_CATEG,
         CATEG_SEGMENT2)
      VALUES
        (ligne_immo.asset_id,
         ligne_immo.book_type_code,
         0, -- DOTATION_JAN
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0, -- DOTATION_DEC
         /*ROUND(Vt_Deprn_Amount(0)/1000,2) + ROUND(Vt_Deprn_Amount(1)/1000,2) + ROUND(Vt_Deprn_Amount(2)/1000,2) +
         ROUND(Vt_Deprn_Amount(3)/1000,2) + ROUND(Vt_Deprn_Amount(4)/1000,2) + ROUND(Vt_Deprn_Amount(5)/1000,2) +
         ROUND(Vt_Deprn_Amount(6)/1000,2) + ROUND(Vt_Deprn_Amount(7)/1000,2) + ROUND(Vt_Deprn_Amount(8)/1000,2) +
         ROUND(Vt_Deprn_Amount(9)/1000,2) + ROUND(Vt_Deprn_Amount(10)/1000,2)+ ROUND(Vt_Deprn_Amount(11)/1000,2), --DOTATION_N
         */ --SL 09/11/2009
         0,
         ligne_immo.segment1,
         ligne_immo.cpte_categ,
         ligne_immo.segment2);
    
    -- ROUND(Pv_Montant/1000,2)
    /*  INSERT INTO DKA_SFABUDGET_WORK
                (Asset_Id,
                Book_Type_Code,
                DOTATION_JAN,
                DOTATION_FEB,
                DOTATION_MAR,
                DOTATION_AVR,
                DOTATION_MAI,
                DOTATION_JUN,
                DOTATION_JUL,
                DOTATION_AOU,
                DOTATION_SEP,
                DOTATION_OCT,
                DOTATION_NOV,
                DOTATION_DEC,
                DOTATION_N,
                CATEGORIE,
                CPTE_CATEG,
                CATEG_SEGMENT2
                )
                VALUES
                (
                ligne_immo.asset_id,
                ligne_immo.book_type_code,
                0, -- DOTATION_JAN
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0, -- DOTATION_DEC
                0,
                ligne_immo.segment1,
                ligne_immo.cpte_categ,
                ligne_immo.segment2
                );*/
    END LOOP;
  
    dka_tools_pkg.put_log_message('DKA_INS_IMM_EXCEP(-)');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_INS_IMM_EXCEP avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_INS_IMM_EXCEP;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_COPY_DATA
  --  Description   : Insertion dans la table DKA_SFABUDGET_WORK des donnees generees par
  --                  les traitements de prevision des amortissements
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_book_type_Code         Entree             Code du livre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_COPY_DATA(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode IN OUT NUMBER) IS
  
    vv_annee_n NUMBER;
  
  BEGIN
    dka_tools_pkg.put_log_message('DKA_MAIN_COPY_DATA(+)');
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Insertion des donnees dans la table DKA_SFABUDGET_WORK');
    dka_tools_pkg.put_log_message('----------');
  
    SELECT TO_NUMBER(TO_CHAR(gv_ref_date, 'YYYY'))
      into vv_annee_n
      from dual;
  
    -- Pour les traitements des amortissement
    FOR I IN 1 .. Vn_Nbre_FaProj LOOP
      -- Insertion des donnees dans la table DKA_SFABUDGET_WORK
      DKA_INS_TRAITEMENT(pv_errbuf,
                         pn_retcode,
                         Vt_Request_Id_FaProj(I),
                         vv_annee_n);
    
      IF pn_retcode = 2 THEN
        -- Sortie: Erreur systeme
        RETURN;
      END IF;
    
    END LOOP; /* FOR Rec_Books_01 IN Cur_Books_01 */
  
    -- SELOO
    DKA_INS_COMPL_AMORTIES(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      -- Sortie: Erreur systeme
      RETURN;
    END IF;
  
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Insertion dans la table DKA_SFABUDGET_WORK des immos amorties rattachées à un cpte d''exception');
    dka_tools_pkg.put_log_message('----------');
  
    /*   DKA_INS_IMM_EXCEP(pv_errbuf  , pn_retcode);
    
      IF pn_retcode = 2
      THEN
         -- Sortie: Erreur systeme
         RETURN;
      END IF;
    */
  
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Mise a jour des donnees dans la table DKA_SFABUDGET_WORK');
    dka_tools_pkg.put_log_message('----------');
  
    DKA_UPDATE_DATA(pv_errbuf, pn_retcode);
  
    IF pn_retcode = 2 THEN
      -- Sortie: Erreur systeme
      RETURN;
    END IF;
    /*
    DKA_UPDATE_IFRS_DATA
    (
      pv_errbuf  ,
      pn_retcode
      );
    
      IF pn_retcode = 2
      THEN
         -- Sortie: Erreur systeme
         RETURN;
      END IF;
    */
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('traitement des amortissements réels');
    dka_tools_pkg.put_log_message('----------');
  
    DKA_AMORT_REEL(pv_errbuf, pn_retcode);
  
    IF pn_retcode = 2 THEN
      -- Sortie: Erreur systeme
      RETURN;
    END IF;
  
    -- SELOO
    begin
      insert into DKA_SFABUDGET_WORK
        select DSW.REGION,
               DSW.CENTRE,
               (select return_value
                  from DKA_STRANSCO_LINES
                 where set_id in
                       (select set_id
                          from DKA_STRANSCO_HEADERS
                         where set_name = 'DKA_TRANSCO_LOCAL_GROUPE')
                   and params_value =
                       (select fcb.attribute3
                          from FA_ADDITIONS      fa,
                               FA_BOOKS          fb,
                               FA_CATEGORIES     fc,
                               FA_CATEGORY_BOOKS fcb
                         where fa.asset_id = fb.asset_id
                           and fb.date_ineffective is null
                           and fa.asset_category_id = fc.category_id
                           and fc.category_id = fcb.category_id
                           and fb.book_type_code = fcb.book_type_code
                           and fb.date_ineffective is null
                           and fa.asset_id = DSW.ASSET_ID
                           and fb.book_type_code like '%SOCIAL')) CPT_GPE,
               DSW.COST_CENTER,
               DSW.PROJET,
               DSW.SOC,
               DSW.NUM_IMMO,
               DSW.ASSET_ID,
               DSW.BOOK_TYPE_CODE,
               DSW.DESC_IMMO,
               DSW.RECOVERABLE_COST * (-1) RECOVERABLE_COST,
               DSW.DATE_IN,
               DSW.Date_FROM,
               DSW.DATE_TO,
               DSW.LIFE_IN_MONTHS,
               DSW.DOTATION_JAN * (-1) DOTATION_JAN,
               DSW.DOTATION_FEB * (-1) DOTATION_FEB,
               DSW.DOTATION_MAR * (-1) DOTATION_MAR,
               DSW.DOTATION_AVR * (-1) DOTATION_AVR,
               DSW.DOTATION_MAI * (-1) DOTATION_MAI,
               DSW.DOTATION_JUN * (-1) DOTATION_JUN,
               DSW.DOTATION_JUL * (-1) DOTATION_JUL,
               DSW.DOTATION_AOU * (-1) DOTATION_AOU,
               DSW.DOTATION_SEP * (-1) DOTATION_SEP,
               DSW.DOTATION_OCT * (-1) DOTATION_OCT,
               DSW.DOTATION_NOV * (-1) DOTATION_NOV,
               DSW.DOTATION_DEC * (-1) DOTATION_DEC,
               DSW.DOTATION_ANNUELLE * (-1) DOTATION_ANNUELLE,
               DSW.DOTATION_N * (-1) DOTATION_N,
               DSW.CATEGORIE,
               DSW.CPTE_CATEG,
               DSW.CPTE_EXCEP_FLAG,
               DSW.CATEG_SEGMENT2,
               DSW.TOTAL_CESSION_N * (-1) TOTAL_CESSION_N,
               DSW.Tache_parent,
               DSW.livre_fa,
               DSW.ajustement_N * (-1) ajustement_N,
               DSW.FC_INVESTISSEMENT,
               DSW.GY_INVESTISSEMENT
          from DKA_SFABUDGET_WORK DSW,
               (select asset_id, count(livre_fa)
                  from DKA_SFABUDGET_WORK
                 where 1 = 1
                -- and num_immo = '101972'
                 group by asset_id
                having count(livre_fa) > 1) double_livre
         where DSW.asset_id = double_livre.asset_id
           and dsw.Book_type_code like '%SOCIAL';
    EXCEPTION
      WHEN others THEN
        null;
    END;
  
    dka_tools_pkg.put_log_message('DKA_MAIN_COPY_DATA(-)');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_COPY_DATA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_COPY_DATA;

  -- Fonctions pour la generation du fichier
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_GEN_DATA
  --  Description   : Generation des donnees
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_GEN_DATA(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode IN OUT NUMBER) IS
    CURSOR Cur_Dka_SFABUDGET_Work IS
      SELECT Dsw.Region || ';' || Dsw.Centre || ';' || Dsw.Cpt_Gpe || ';' ||
              Dsw.Cost_Center || ';' || Dsw.Projet || ';' || Dsw.Soc || ';' ||
              Dsw.Num_Immo || ';' ||
             -- Remplace les ; par ,
             --              retour chariot par espace
              TRANSLATE(Dsw.Desc_Immo,
                        ';' || CHR(10) || CHR(13) || CHR(12) || CHR(14) ||
                        CHR(11) || CHR(15) || CHR(9),
                        ',     ') || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Recoverable_Cost))) || ';' ||
              to_char(Dsw.Date_In, 'DD/MM/YY') || ';' ||
              to_char(Dsw.Date_From, 'DD/MM/YY') || ';' ||
              to_char(Dsw.Date_To, 'DD/MM/YY') || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Life_In_Months))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Jan / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Feb / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Mar / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Avr / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Mai / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Jun / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Jul / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Aou / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Sep / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Oct / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Nov / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Dec / 1000))) || ';' ||
              LTRIM(RTRIM(TO_CHAR(Dsw.Dotation_Annuelle / 1000))) Data,
             ';' || LTRIM(RTRIM(TO_CHAR(Dsw.DOTATION_N / 1000))) Data2,
             /*';'||  TRANSLATE(Dsw.CATEGORIE,';'||CHR(10)||CHR(13)||CHR(12)
             ||CHR(14)||CHR(11)||CHR(15)||CHR(9),',     ')
                                               ||*/
             ';' || LTRIM(RTRIM(TO_CHAR(Dsw.CPTE_CATEG))) || ';' ||
             TRANSLATE(Dsw.CATEG_SEGMENT2,
                       ';' || CHR(10) || CHR(13) || CHR(12) || CHR(14) ||
                       CHR(11) || CHR(15) || CHR(9),
                       ',     ') || ';' || Dsw.Total_Cession_N Data3
        FROM Dka_SFaBudget_Work Dsw
       ORDER BY Dsw.Num_Immo;
  
    Rec_Dka_SFABUDGET_Work Cur_Dka_SFABUDGET_Work%ROWTYPE;
  
    Vn_Nbre_Rows NUMBER := 0;
  
  BEGIN
    dka_tools_pkg.put_log_message('********************DEBUT DES DONNEES********************');
    -- Entete du fichier
    dka_tools_pkg.put_outdebug_message('REGION;CENTRE;CPT_GPE;COST_CENTER;PROJET;SOC;NUM_IMMO;DESC_IMMO;' ||
                                       'RECOVERABLE_COST;DATE_IN;DATE_FROM;DATE_TO;LIFE_IN_MONTHS;' ||
                                       'DOTATION_JAN;DOTATION_FEV;DOTATION_MAR;DOTATION_AVR;DOTATION_MAI;' ||
                                       'DOTATION_JUN;DOTATION_JUL;DOTATION_AOU;DOTATION_SEP;DOTATION_OCT;' ||
                                       'DOTATION_NOV;DOTATION_DEC;DOTATION_ANNUELLE;DOTATION_N;CPTE_CATEG;CATEGORIE_SEG_2;TOTAL_CESSION_N');
  
    dka_tools_pkg.put_log_message('*********************FIN DES DONNEES*********************');
    dka_tools_pkg.put_log_message('-> Nbre de lignes : ' || Vn_Nbre_Rows);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_GEN_DATA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_GEN_DATA;

  -- Fonctions pour la suppression des tables generees par les traitements de prevision des amortissements
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_REQUEST_DROP_TABLE
  --  Description   : Suppression de la table generee par le traitement de prevision dont l'id. de traitement
  --                  est passe en parametre
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- Pn_resquest_Id            Entree             Id. du traitement
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_REQUEST_DROP_TABLE(pv_errbuf     IN OUT VARCHAR2,
                                   pn_retcode    IN OUT NUMBER,
                                   Pn_request_id IN NUMBER) IS
    -- Ordre PLSQL a generer
    Vv_Ordre_PLSQL VARCHAR2(10000);
  BEGIN
  
    dka_tools_pkg.put_log_message('-> Traitement ' || pn_request_Id);
    Vv_Ordre_PLSQL := 'DROP TABLE fa_proj_interim_' ||
                      LTRIM(RTRIM(TO_CHAR(pn_request_Id)));
    apps_ddl.apps_ddl(Vv_Ordre_PLSQL);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_REQUEST_DROP_TABLE (' || Pn_request_id ||
                    ') avec erreur EXCEPTION OTHERS:' || SQLERRM;
      pn_retcode := 2;
  END DKA_REQUEST_DROP_TABLE;

  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAIN_DROP_TABLE
  --  Description   : suppression des tables generees par les traitements de prevision des amortissements
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_MAIN_DROP_TABLE(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode IN OUT NUMBER) IS
  BEGIN
    -- Pour tous les traitements de prevision soumis
    FOR I IN 1 .. NVL(Vn_Nbre_FaProj, 0) LOOP
      -- Suppression de la table
      DKA_REQUEST_DROP_TABLE(pv_errbuf,
                             pn_retcode,
                             Vt_Request_Id_FaProj(I));
      -- Pas de gestion de pn_recode pour continuer la suppression meme si une erreur s'est produite
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de DKA_MAIN_GEN_DATA avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END DKA_MAIN_DROP_TABLE;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   :
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
  
    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        dka_tools_pkg.put_log_message(p_message);
      END IF;
    
      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM,
                              nvl(p_message, 'Erreur fatale : '));
    
    END IF;
  
  END p_validate;
  --------------------------------------------------------------------------------------------------
  --  Nom           : Extraction Hyperion
  --  Description   : Procédure Extraction Hyperion
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE p_extr_data_hyperion(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                                 
                                 p_file_name   IN VARCHAR2,
                                 vn_request_id out NUMBER) IS
  
    vv_ligne        VARCHAR2(4000);
    vn_nb_lignes    NUMBER := 0;
    V_file_name     VARCHAR2(4000);
    l_file          UTL_FILE.file_type;
    l_vide1         VARCHAR2(5000);
    l_vide2         VARCHAR2(5000);
    l_vide3         VARCHAR2(5000);
    l_Colonne_total VARCHAR2(5000);
    l_Colonne_JAN   VARCHAR2(5000);
    l_Colonne_FEB   VARCHAR2(5000);
    l_Colonne_MAR   VARCHAR2(5000);
    l_Colonne_APR   VARCHAR2(5000);
    l_Colonne_MAY   VARCHAR2(5000);
    l_Colonne_JUN   VARCHAR2(5000);
    l_Colonne_JUL   VARCHAR2(5000);
    l_Colonne_AUG   VARCHAR2(5000);
    l_Colonne_SEP   VARCHAR2(5000);
    l_Colonne_OCT   VARCHAR2(5000);
    l_Colonne_NOV   VARCHAR2(5000);
    l_Colonne_DEC   VARCHAR2(5000);
    --  l_cpt_analytique  VARCHAR2(400); -- SELOO
    l_sum_ammort VARCHAR2(400);
    l_MTN_JAN    VARCHAR2(400);
    l_MTN_FEB    VARCHAR2(400);
    l_MTN_MAR    VARCHAR2(400);
    l_MTN_APR    VARCHAR2(400);
    l_MTN_MAY    VARCHAR2(400);
    l_MTN_JUN    VARCHAR2(400);
    l_MTN_JUL    VARCHAR2(400);
    l_MTN_AOU    VARCHAR2(400);
    l_MTN_SEP    VARCHAR2(400);
    l_MTN_OCT    VARCHAR2(400);
    l_MTN_NOV    VARCHAR2(400);
    l_MTN_DEC    VARCHAR2(400);
    -- l_year            VARCHAR2(20); -- SELOO
    --   l_sysdate         VARCHAR2(30); -- SELOO
    l_ligne2      VARCHAR2(4000);
    l_ligne1      VARCHAR2(4000);
    l_ligne3      VARCHAR2(4000);
    l_SUM         VARCHAR2(4000);
    pn_request_Id NUMBER := 0;
    l_project     VARCHAR2(20);
    --vn_request_id     NUMBER (15);
    /*//-- cursor pour extraction des lignes de ventilations de commandes//*/
  
    /*CURSOR cur_data IS
                 SELECT asset_id,  projet, book_type_code, region
                 FROM  DKA_SFABUDGET_WORK
           WHERE projet IS NOT NULL;
    */ -- SELOO
    CURSOR cur_data IS
      SELECT distinct projet, region
        FROM DKA_SFABUDGET_WORK
       WHERE projet IS NOT NULL; -- SELOO
  
    CURSOR cur_Compte(Project VARCHAR2) IS
      SELECT distinct dsw.CPT_GPE l_cpt_analytique,
                      TO_CHAR(SYSDATE, 'YYYY') + 1 l_year,
                      TO_CHAR(SYSDATE, 'DDMMYY') l_sysdate,
                      round(SUM(DOTATION_JAN) / -1000, 3) dotation_jan,
                      round(SUM(DOTATION_FEB) / -1000, 3) DOTATION_FEB,
                      round(SUM(DOTATION_MAR) / -1000, 3) DOTATION_MAR,
                      round(SUM(DOTATION_AVR) / -1000, 3) DOTATION_AVR,
                      round(SUM(DOTATION_MAI) / -1000, 3) DOTATION_MAI,
                      round(SUM(DOTATION_JUN) / -1000, 3) DOTATION_JUN,
                      round(SUM(DOTATION_JUL) / -1000, 3) DOTATION_JUL,
                      round(SUM(DOTATION_AOU) / -1000, 3) DOTATION_AOU,
                      round(SUM(DOTATION_SEP) / -1000, 3) DOTATION_SEP,
                      round(SUM(DOTATION_OCT) / -1000, 3) DOTATION_OCT,
                      round(SUM(DOTATION_NOV) / -1000, 3) DOTATION_NOV,
                      round(SUM(DOTATION_DEC) / -1000, 3) DOTATION_DEC,
                      round(SUM(DOTATION_ANNUELLE) / -1000, 3) DOTATION_ANNUELLE
        FROM DKA_SFABUDGET_WORK DSW
       WHERE 1 = 1
         AND dsw.projet = Project
       group by dsw.CPT_GPE,
                TO_CHAR(SYSDATE, 'YYYY') + 1,
                TO_CHAR(SYSDATE, 'DDMMYY');
  
  BEGIN
    V_file_name := p_file_name || '.csv';
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, V_file_name, 'W', 32767);
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      dka_tools_pkg.put_log_message('Le fichier ' || p_directory_name || '/' ||
                                    V_file_name ||
                                    ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    -- BEGIN
  
    -- SELOO
    l_ligne1 := ';;;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;' || to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY');
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Total annuel;Janvier;Février;Mars;Avril;Mai;Juin;Juillet;Aout;Septembre;Octobre;Novembre;Décembre';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    -- Extraction des donnees
    FOR R0 in cur_data LOOP
    
      l_sum_ammort := null;
      l_MTN_JAN    := null;
      l_MTN_FEB    := null;
      l_MTN_MAR    := null;
      l_MTN_APR    := null;
      l_MTN_MAY    := null;
      l_MTN_JUN    := null;
      l_MTN_JUL    := null;
      l_MTN_AOU    := null;
      l_MTN_SEP    := null;
      l_MTN_OCT    := null;
      l_MTN_NOV    := null;
      l_MTN_DEC    := null;
    
      /*    BEGIN
       SELECT distinct gcc.segment4,TO_CHAR(SYSDATE,'YYYY')+1,TO_CHAR(SYSDATE,'DDMMYY')  --SELOO
       INTO   l_cpt_analytique,  l_year, l_sysdate
             FROM FA_PROJ_INTERIM_REP FP, gl_code_combinations gcc
             WHERE 1=1
             AND fp.code_combination_id = gcc.code_combination_id
             AND fp.asset_id = R0.asset_id
             AND fp.book_type_code = r0.book_type_code
       AND ROWNUM =1;
       EXCEPTION WHEN NO_DATA_FOUND
             THEN
            l_cpt_analytique := null;
          l_year := null;
          l_sysdate := null;
      END;
        */
      -- SELOO
      l_SUM := TO_CHAR(sysdate, 'YYYY') + 1 || '_' || R0.region || '_' ||
               TO_CHAR(SYSDATE, 'DDMMYY'); -- SELOO
      l_SUM := 'SDM_BUD_AMORT_' || l_SUM; -- SELOO
      dbms_output.put_line('9');
      l_ligne2 := '"' || R0.projet || '"' || ';' || '"' ||
                  'Saisie de masse Intégration' || '"' || ';' || '"' ||
                  'Ecart non defini' || '"' || ';' || '"' || l_SUM || '"';
      utl_file.put_line(l_file, l_ligne2);
      l_project := R0.projet;
      FOR rec_cpt IN cur_Compte(R0.projet) LOOP
      
        l_MTN_JAN := replace(to_char(rec_cpt.dotation_jan), '.', ',');
        l_MTN_FEB := replace(to_char(rec_cpt.dotation_feb), '.', ',');
        l_MTN_MAR := replace(to_char(rec_cpt.dotation_mar), '.', ',');
        l_MTN_APR := replace(to_char(rec_cpt.dotation_avr), '.', ',');
        l_MTN_MAY := replace(to_char(rec_cpt.dotation_mai), '.', ',');
        l_MTN_JUN := replace(to_char(rec_cpt.dotation_jun), '.', ',');
        l_MTN_JUL := replace(to_char(rec_cpt.dotation_jul), '.', ',');
        l_MTN_AOU := replace(to_char(rec_cpt.dotation_aou), '.', ',');
        l_MTN_SEP := replace(to_char(rec_cpt.dotation_sep), '.', ',');
        l_MTN_OCT := replace(to_char(rec_cpt.dotation_oct), '.', ',');
        l_MTN_NOV := replace(to_char(rec_cpt.dotation_nov), '.', ',');
        l_MTN_DEC := replace(to_char(rec_cpt.dotation_dec), '.', ',');
      
        l_ligne3 := '"' || R0.projet || '"' || ';' || '"' ||
                    rec_cpt.l_cpt_analytique || '"' || ';' || '"' ||
                    'Ecart non defini' || '"' || ';' || '"' || '' || '"' || ';' || '"' ||
                    l_MTN_JAN || '"' || ';' || '"' || l_MTN_FEB || '"' || ';' || '"' ||
                    l_MTN_MAR || '"' || ';' || '"' || l_MTN_APR || '"' || ';' || '"' ||
                    l_MTN_MAY || '"' || ';' || '"' || l_MTN_JUN || '"' || ';' || '"' ||
                    l_MTN_JUL || '"' || ';' || '"' || l_MTN_AOU || '"' || ';' || '"' ||
                    l_MTN_SEP || '"' || ';' || '"' || l_MTN_OCT || '"' || ';' || '"' ||
                    l_MTN_NOV || '"' || ';' || '"' || l_MTN_DEC || '"';
      
        BEGIN
          -- Ecrit dans le fichier
          -- utl_file.put_line(l_file, l_ligne2);
          utl_file.put_line(l_file, l_ligne3);
        
          -- Maj des compteurs
          vn_nb_lignes := vn_nb_lignes + 1;
        
        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_log_message('ERREUR ' || ' - ' || SQLERRM);
            dbms_output.put_line('13');
        END;
      
      END LOOP; --SELOO
    END LOOP;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
    vn_request_id := Fnd_Request.submit_request('DKA', -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                'DKA_SFABUDGET_REG_HYP', -- SHORT NAME DU TRAITEMENT
                                                --NULL,                           -- PROGRAM NAME
                                                'TOUTE', -- PROGRAM NAME   -- SFA artf07235613
                                                NULL, -- START
                                                FALSE, -- SUB REQUEST
                                                'TOUTE',
                                                V_file_name);
    commit;
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    vg_nbl_extr_cmd := vn_nb_lignes;
    dka_tools_pkg.put_log_message('L''écriture dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est terminée');
    dka_tools_pkg.put_log_message('Le nombre de lignes dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est :' || vg_nbl_extr_cmd);
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extr_data_hyperion (' ||
                 SQLERRM || ') ' || l_project);
    
  END p_extr_data_hyperion;

  PROCEDURE p_extr_data_hyperion_REG(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                                     
                                     p_file_name   IN VARCHAR2,
                                     p_region      IN VARCHAR2,
                                     vn_request_id out NUMBER) IS
  
    vv_ligne         VARCHAR2(4000);
    vn_nb_lignes     NUMBER := 0;
    V_file_name      VARCHAR2(4000);
    l_file           UTL_FILE.file_type;
    l_vide1          VARCHAR2(5000);
    l_vide2          VARCHAR2(5000);
    l_vide3          VARCHAR2(5000);
    l_Colonne_total  VARCHAR2(5000);
    l_Colonne_JAN    VARCHAR2(5000);
    l_Colonne_FEB    VARCHAR2(5000);
    l_Colonne_MAR    VARCHAR2(5000);
    l_Colonne_APR    VARCHAR2(5000);
    l_Colonne_MAY    VARCHAR2(5000);
    l_Colonne_JUN    VARCHAR2(5000);
    l_Colonne_JUL    VARCHAR2(5000);
    l_Colonne_AUG    VARCHAR2(5000);
    l_Colonne_SEP    VARCHAR2(5000);
    l_Colonne_OCT    VARCHAR2(5000);
    l_Colonne_NOV    VARCHAR2(5000);
    l_Colonne_DEC    VARCHAR2(5000);
    l_cpt_analytique VARCHAR2(400);
    l_sum_ammort     VARCHAR2(400);
    l_MTN_JAN        VARCHAR2(400);
    l_MTN_FEB        VARCHAR2(400);
    l_MTN_MAR        VARCHAR2(400);
    l_MTN_APR        VARCHAR2(400);
    l_MTN_MAY        VARCHAR2(400);
    l_MTN_JUN        VARCHAR2(400);
    l_MTN_JUL        VARCHAR2(400);
    l_MTN_AOU        VARCHAR2(400);
    l_MTN_SEP        VARCHAR2(400);
    l_MTN_OCT        VARCHAR2(400);
    l_MTN_NOV        VARCHAR2(400);
    l_MTN_DEC        VARCHAR2(400);
    l_year           VARCHAR2(20);
    l_sysdate        VARCHAR2(30);
    l_ligne2         VARCHAR2(4000);
    l_ligne1         VARCHAR2(4000);
    l_ligne3         VARCHAR2(4000);
    l_SUM            VARCHAR2(4000);
    pn_request_Id    NUMBER := 0;
    --vn_request_id                    NUMBER (15);
    /*//-- cursor pour extraction des lignes de ventilations de commandes//*/
  
    /*CURSOR cur_data IS
                SELECT asset_id, projet, book_type_code, region
                FROM  DKA_SFABUDGET_WORK
          WHERE projet IS NOT NULL
          AND region = p_region;
    
    */ -- SELOO
    CURSOR cur_data IS
      SELECT distinct projet, region
        FROM DKA_SFABUDGET_WORK
       WHERE projet IS NOT NULL
         AND region = p_region; -- SELOO
  
    CURSOR cur_Compte(Project VARCHAR2) IS
      SELECT distinct dsw.CPT_GPE l_cpt_analytique,
                      TO_CHAR(SYSDATE, 'YYYY') + 1 l_year,
                      TO_CHAR(SYSDATE, 'DDMMYY') l_sysdate,
                      round(SUM(DOTATION_JAN) / -1000, 3) dotation_jan,
                      round(SUM(DOTATION_FEB) / -1000, 3) DOTATION_FEB,
                      round(SUM(DOTATION_MAR) / -1000, 3) DOTATION_MAR,
                      round(SUM(DOTATION_AVR) / -1000, 3) DOTATION_AVR,
                      round(SUM(DOTATION_MAI) / -1000, 3) DOTATION_MAI,
                      round(SUM(DOTATION_JUN) / -1000, 3) DOTATION_JUN,
                      round(SUM(DOTATION_JUL) / -1000, 3) DOTATION_JUL,
                      round(SUM(DOTATION_AOU) / -1000, 3) DOTATION_AOU,
                      round(SUM(DOTATION_SEP) / -1000, 3) DOTATION_SEP,
                      round(SUM(DOTATION_OCT) / -1000, 3) DOTATION_OCT,
                      round(SUM(DOTATION_NOV) / -1000, 3) DOTATION_NOV,
                      round(SUM(DOTATION_DEC) / -1000, 3) DOTATION_DEC,
                      round(SUM(DOTATION_ANNUELLE) / -1000, 3) DOTATION_ANNUELLE
        FROM DKA_SFABUDGET_WORK DSW
       WHERE 1 = 1
         AND dsw.projet = Project
       group by dsw.CPT_GPE,
                TO_CHAR(SYSDATE, 'YYYY') + 1,
                TO_CHAR(SYSDATE, 'DDMMYY');
  
  BEGIN
    V_file_name := p_file_name || '_' || p_region || '.csv';
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, V_file_name, 'W', 32767);
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      dka_tools_pkg.put_log_message('Le fichier ' || p_directory_name || '/' ||
                                    V_file_name ||
                                    ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    -- SELOO
    l_ligne1 := ';;;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie;Societe non definie';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours;Budget année en cours';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;' || to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY') || ';' ||
                to_char(sysdate + 366, 'YYYY');
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse;Saisie de masse';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours;Version En Cours';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini;Dossier non defini';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique;Vision périodique';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    l_ligne1 := ';;;Total annuel;Janvier;Février;Mars;Avril;Mai;Juin;Juillet;Aout;Septembre;Octobre;Novembre;Décembre';
    --création de l'entête
    utl_file.put_line(l_file, l_ligne1);
  
    -- Extraction des donnees
  
    FOR R0 in cur_data LOOP
    
      l_sum_ammort := null;
      l_MTN_JAN    := null;
      l_MTN_FEB    := null;
      l_MTN_MAR    := null;
      l_MTN_APR    := null;
      l_MTN_MAY    := null;
      l_MTN_JUN    := null;
      l_MTN_JUL    := null;
      l_MTN_AOU    := null;
      l_MTN_SEP    := null;
      l_MTN_OCT    := null;
      l_MTN_NOV    := null;
      l_MTN_DEC    := null;
    
      l_SUM := TO_CHAR(sysdate, 'YYYY') + 1 || '_' || R0.region || '_' ||
               TO_CHAR(SYSDATE, 'DDMMYY'); -- SELOO
      l_SUM := 'SDM_BUD_AMORT_' || l_SUM; -- SELOO
      dbms_output.put_line('9');
      l_ligne2 := '"' || R0.projet || '"' || ';' || '"' ||
                  'Saisie de masse Intégration' || '"' || ';' || '"' ||
                  'Ecart non defini' || '"' || ';' || '"' || l_SUM || '"';
      utl_file.put_line(l_file, l_ligne2);
    
      FOR rec_cpt IN cur_Compte(R0.projet) LOOP
      
        l_MTN_JAN := replace(to_char(rec_cpt.dotation_jan), '.', ',');
        l_MTN_FEB := replace(to_char(rec_cpt.dotation_feb), '.', ',');
        l_MTN_MAR := replace(to_char(rec_cpt.dotation_mar), '.', ',');
        l_MTN_APR := replace(to_char(rec_cpt.dotation_avr), '.', ',');
        l_MTN_MAY := replace(to_char(rec_cpt.dotation_mai), '.', ',');
        l_MTN_JUN := replace(to_char(rec_cpt.dotation_jun), '.', ',');
        l_MTN_JUL := replace(to_char(rec_cpt.dotation_jul), '.', ',');
        l_MTN_AOU := replace(to_char(rec_cpt.dotation_aou), '.', ',');
        l_MTN_SEP := replace(to_char(rec_cpt.dotation_sep), '.', ',');
        l_MTN_OCT := replace(to_char(rec_cpt.dotation_oct), '.', ',');
        l_MTN_NOV := replace(to_char(rec_cpt.dotation_nov), '.', ',');
        l_MTN_DEC := replace(to_char(rec_cpt.dotation_dec), '.', ',');
      
        l_ligne3 := '"' || R0.projet || '"' || ';' || '"' ||
                    rec_cpt.l_cpt_analytique || '"' || ';' || '"' ||
                    'Ecart non defini' || '"' || ';' || '"' || '' || '"' || ';' || '"' ||
                    l_MTN_JAN || '"' || ';' || '"' || l_MTN_FEB || '"' || ';' || '"' ||
                    l_MTN_MAR || '"' || ';' || '"' || l_MTN_APR || '"' || ';' || '"' ||
                    l_MTN_MAY || '"' || ';' || '"' || l_MTN_JUN || '"' || ';' || '"' ||
                    l_MTN_JUL || '"' || ';' || '"' || l_MTN_AOU || '"' || ';' || '"' ||
                    l_MTN_SEP || '"' || ';' || '"' || l_MTN_OCT || '"' || ';' || '"' ||
                    l_MTN_NOV || '"' || ';' || '"' || l_MTN_DEC || '"';
      
        BEGIN
        
          -- Ecrit dans le fichier
          utl_file.put_line(l_file, l_ligne3);
        
          -- Maj des compteurs
          vn_nb_lignes := vn_nb_lignes + 1;
        
        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_log_message('ERREUR ' || ' - ' || SQLERRM);
          
        END;
      
      END LOOP;
    END loop;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    vn_request_id := Fnd_Request.submit_request('DKA', -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                'DKA_SFABUDGET_REG_HYP', -- SHORT NAME DU TRAITEMENT
                                                --NULL,                           -- PROGRAM NAME
                                                p_region, -- PROGRAM NAME   -- SFA artf07235613
                                                NULL, -- START
                                                FALSE, -- SUB REQUEST
                                                p_region,
                                                V_file_name);
    commit;
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    vg_nbl_extr_cmd := vn_nb_lignes;
    dka_tools_pkg.put_log_message('L''écriture dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est terminée');
    dka_tools_pkg.put_log_message('Le nombre de lignes dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est :' || vg_nbl_extr_cmd);
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extr_data_hyperion_REG (' ||
                 SQLERRM || ')');
    
  END p_extr_data_hyperion_REG;

  -----------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : procédure d'envoi de mail avec pièce jointe
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  --   vb_boucle        IN         BOOLEAN
  -----------------------------------------------------------------

  PROCEDURE SEND_MSG(p_to          IN VARCHAR2,
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
                     p_text_msg    IN VARCHAR2 DEFAULT NULL,
                     p_attach_name IN VARCHAR2 DEFAULT NULL,
                     p_attach_mime IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25) AS
    l_mail_conn UTL_SMTP.connection;
    l_boundary  VARCHAR2(50) := '----=*#abc1234321cba#*=';
    l_step      PLS_INTEGER := 12000; -- make sure you set a multiple of 3 not higher than 24573
    last        BOOLEAN DEFAULT FALSE;
    FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || l_boundary ||
                                             utl_tcp.CRLF;
    LAST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || l_boundary || '--' ||
                                             utl_tcp.CRLF;
    fil           BFILE; -- SELOO
    v_length      integer := 0; -- SELOO
    k             integer := 1;
    v_raw         raw(57);
    v_buffer_size integer := 57;
  BEGIN
    l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
    UTL_SMTP.helo(l_mail_conn, p_smtp_host);
    UTL_SMTP.mail(l_mail_conn, p_from);
    UTL_SMTP.rcpt(l_mail_conn, p_to);
  
    UTL_SMTP.open_data(l_mail_conn);
  
    UTL_SMTP.write_data(l_mail_conn,
                        'Date: ' ||
                        TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') ||
                        UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Subject: ' || p_subject || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Reply-To: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Content-Type: multipart/mixed; boundary="' ||
                        l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  
    IF p_text_msg IS NOT NULL THEN
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: text/plain; charset="iso-8859-1"' ||
                          UTL_TCP.crlf || UTL_TCP.crlf);
    
      UTL_SMTP.write_data(l_mail_conn, p_text_msg);
      UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    END IF;
  
    IF p_attach_name IS NOT NULL THEN
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: ' || p_attach_mime || '; name="' ||
                          p_attach_name || '"' || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          p_attach_name || '"' || UTL_TCP.crlf ||
                          UTL_TCP.crlf);
    
      -- SELOO
      /* IF (last) THEN
              utl_smtp.write_data(l_mail_conn, LAST_BOUNDARY);
           ELSE
              utl_smtp.write_data(l_mail_conn, FIRST_BOUNDARY);
           END IF;
      
       utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw('Content-Type: ' || 'text/plain' || utl_tcp.CRLF));
         --utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'inline; filename="'||p_attach_name||'"' || utl_tcp.CRLF));
       utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'attachment; filename="'||p_attach_name||'"' || utl_tcp.CRLF));
       utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw('Content-Transfer-Encoding: base64' || utl_tcp.CRLF));
       utl_smtp.write_data(l_mail_conn, utl_tcp.CRLF);
        UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      IF (last) THEN
            IF (last) THEN
              utl_smtp.write_data(l_mail_conn, LAST_BOUNDARY);
           ELSE
              utl_smtp.write_data(l_mail_conn, FIRST_BOUNDARY);
           END IF;
         END IF; */
    
      -- SELOO
      BEGIN
        fil := bfilename(p_attach_mime, p_attach_name);
        dbms_lob.fileopen(fil, dbms_lob.file_readonly);
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
      v_length := dbms_lob.getlength(fil);
    
      while k < v_length loop
        dbms_lob.read(fil, v_buffer_size, k, v_raw);
        UTL_SMTP.write_data(l_mail_conn,
                            UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(v_raw)));
        utl_smtp.write_data(l_mail_conn, utl_tcp.crlf);
        k := k + v_buffer_size;
      end loop;
    
      dbms_lob.fileclose(fil);
    
    END IF;
  
    -- SELOO fin
  
    UTL_SMTP.write_data(l_mail_conn,
                        '--' || l_boundary || '--' || UTL_TCP.crlf);
    UTL_SMTP.close_data(l_mail_conn);
  
    UTL_SMTP.quit(l_mail_conn);
  END SEND_MSG;

  --------------------------------------------------------------------------------------------------
  --  Nom           : Extraction justif
  --  Description   : Procédure Extraction justif
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE p_extr_data_justif(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                               p_file_name      IN VARCHAR2,
                               p_nb_lignes      IN OUT VARCHAR2) IS
  
    vv_ligne     VARCHAR2(4000);
    vn_nb_lignes NUMBER := 0;
    V_file_name  VARCHAR2(4000);
    l_file       UTL_FILE.file_type;
    v_FileExcel  UTL_FILE.FILE_TYPE;
    v_NewLine    VARCHAR2(10000);
  
    /*//-- cursor pour extraction des lignes de ventilations de commandes//*/
  
    CURSOR cur_data IS
    
      select '"' || REGION || '"' || vg_SEPARATOR || '"' || CENTRE || '"' ||
              vg_SEPARATOR || '"' || CPT_GPE || '"' || vg_SEPARATOR || '"' ||
              COST_CENTER || '"' || vg_SEPARATOR || '"' || PROJET || '"' ||
              vg_SEPARATOR || '="' || SOC || '"' || vg_SEPARATOR || '"' ||
              NUM_IMMO
             --||'"'||vg_SEPARATOR||'"'||  ASSET_ID
             --||'"'||vg_SEPARATOR||'"'||  BOOK_TYPE_CODE
              || '"' || vg_SEPARATOR || '"' || DESC_IMMO || '"' ||
              vg_SEPARATOR || '"' || replace(RECOVERABLE_COST, '.', ',') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_IN, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_FROM, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_TO, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || LIFE_IN_MONTHS || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JAN / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_FEB / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_MAR / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_AVR / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_MAI / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JUN / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JUL / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_AOU / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_SEP / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_OCT / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_NOV / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_DEC / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_ANNUELLE / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_N / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' || CPTE_CATEG || '"' || vg_SEPARATOR || '"' ||
              CATEG_SEGMENT2 || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(nvl(TOTAL_CESSION_N, 0) / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' || LIVRE_FA || '"' || vg_SEPARATOR || '"' ||
              TACHE_PARENT || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(AJUSTEMENT_N / 1000, 3), '.', ',') || '"'|| vg_SEPARATOR || '"' ||
              FC_INVESTISSEMENT || '"' || vg_SEPARATOR || '"' ||
              GY_INVESTISSEMENT ||  '"'  AS LIGNE
      
        FROM DKA_SFABUDGET_WORK;
  
    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;
  
  BEGIN
    V_file_name := p_file_name || '.csv';
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, V_file_name, 'W', 32767);
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      dka_tools_pkg.put_log_message('Le fichier ' || p_directory_name || '/' ||
                                    V_file_name ||
                                    ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    --création de l'entête
    utl_file.put_line(l_file,
                      '"REGION";"CENTRE";"CPT_GPE";"COST_CENTER";"PROJET";"SOC";"NUM_IMMO";"DESC_IMMO";"RECOVERABLE_COST";"DATE_IN";"DATE_FROM";"DATE_TO";"LIFE_IN_MONTHS";"DOTATION_JAN";"DOTATION_FEV";"DOTATION_MAR";"DOTATION_AVR";"DOTATION_MAI";"DOTATION_JUN";"DOTATION_JUL";"DOTATION_AOU";"DOTATION_SEP";"DOTATION_OCT";"DOTATION_NOV";"DOTATION_DEC";"DOTATION_ANNUELLE";"DOTATION_N";"CPTE_CATEG";"CATEGORIE_SEG_2";"TOTAL_CESSION_N";"LIVRE";"TACHE";"AJUSTEMENT_N";"FC_INVESTISSEMENT";"GY_INVESTISSEMENT"');
    -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT
        INTO lt_cur_data;
    
      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP
        
          BEGIN
            vv_ligne := lt_cur_data(i).LIGNE;
          
            -- Ecrit dans le fichier
            utl_file.put_line(l_file, vv_ligne);
          
            -- Maj des compteurs
            vn_nb_lignes := vn_nb_lignes + 1;
          
          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_log_message('ERREUR ' || lt_cur_data(i).LIGNE ||
                                            ' - ' || SQLERRM);
          END;
        
        END LOOP;
      
      END IF;
    
      EXIT WHEN cur_data%NOTFOUND;
    
    END LOOP;
    CLOSE cur_data;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    l_file := UTL_FILE.fopen(p_directory_name, V_file_name, 'r');
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(l_file, v_NewLine);
        Fnd_File.PUT_LINE(Fnd_File.output, v_NewLine);
      EXCEPTION
        WHEN OTHERS THEN
          EXIT;
      END;
    END LOOP;
    UTL_FILE.FCLOSE(l_file);
  
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    vg_nbl_extr_cmd := vn_nb_lignes;
    dka_tools_pkg.put_log_message('L''écriture dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est terminée');
    dka_tools_pkg.put_log_message('Le nombre de lignes dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est :' || vg_nbl_extr_cmd);
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data_cmd (' ||
                 SQLERRM || ')');
    
  END p_extr_data_justif;

  --------------------------------------------------------------------------------------------------
  --  Nom           : Extraction justif
  --  Description   : Procédure Extraction justif
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE p_extr_data_justif_REG(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                                   p_file_name      IN VARCHAR2,
                                   p_nb_lignes      IN OUT VARCHAR2,
                                   p_region         IN VARCHAR2,
                                   vn_request_id    out number) IS
  
    vv_ligne     VARCHAR2(4000);
    vn_nb_lignes NUMBER := 0;
    V_file_name  VARCHAR2(4000);
    l_file       UTL_FILE.file_type;
    v_FileExcel  UTL_FILE.FILE_TYPE;
    v_NewLine    VARCHAR2(10000);
    --vn_request_id                    NUMBER (15);
  
    /*//-- cursor pour extraction des lignes de ventilations de commandes//*/
  
    CURSOR cur_data IS
    
      select '"' || REGION || '"' || vg_SEPARATOR || '"' || CENTRE || '"' ||
              vg_SEPARATOR || '"' || CPT_GPE || '"' || vg_SEPARATOR || '"' ||
              COST_CENTER || '"' || vg_SEPARATOR || '"' || PROJET || '"' ||
              vg_SEPARATOR || '"' || SOC || '"' || vg_SEPARATOR || '"' ||
              NUM_IMMO
             --||'"'||vg_SEPARATOR||'"'||  ASSET_ID
             --||'"'||vg_SEPARATOR||'"'||  BOOK_TYPE_CODE
              || '"' || vg_SEPARATOR || '"' || DESC_IMMO || '"' ||
              vg_SEPARATOR || '"' || replace(RECOVERABLE_COST, '.', ',') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_IN, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_FROM, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || to_char(DATE_TO, 'DD/MM/YYYY') || '"' ||
              vg_SEPARATOR || '"' || LIFE_IN_MONTHS || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JAN / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_FEB / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_MAR / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_AVR / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_MAI / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JUN / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_JUL / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_AOU / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_SEP / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_OCT / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_NOV / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_DEC / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_ANNUELLE / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' ||
              replace(ROUND(DOTATION_N / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' || CPTE_CATEG || '"' || vg_SEPARATOR || '"' ||
              CATEG_SEGMENT2 || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(nvl(TOTAL_CESSION_N, 0) / 1000, 3), '.', ',') || '"' ||
              vg_SEPARATOR || '"' || LIVRE_FA || '"' || vg_SEPARATOR || '"' ||
              TACHE_PARENT || '"' || vg_SEPARATOR || '"' ||
              replace(ROUND(AJUSTEMENT_N / 1000, 3), '.', ',') || '"'|| vg_SEPARATOR || '"' ||
              FC_INVESTISSEMENT || '"' || vg_SEPARATOR || '"' ||
              GY_INVESTISSEMENT || '"'  AS LIGNE
        FROM DKA_SFABUDGET_WORK
       WHERE REGION = p_region;
  
    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;
  
  BEGIN
    V_file_name := p_file_name || '_' || p_region || '.csv';
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, V_file_name, 'W', 32767);
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      dka_tools_pkg.put_log_message('Le fichier ' || p_directory_name || '/' ||
                                    V_file_name ||
                                    ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    --création de l'entête
    utl_file.put_line(l_file,
                      '"REGION";"CENTRE";"CPT_GPE";"COST_CENTER";"PROJET";"SOC";"NUM_IMMO";"DESC_IMMO";"RECOVERABLE_COST";"DATE_IN";"DATE_FROM";"DATE_TO";"LIFE_IN_MONTHS";"DOTATION_JAN";"DOTATION_FEV";"DOTATION_MAR";"DOTATION_AVR";"DOTATION_MAI";"DOTATION_JUN";"DOTATION_JUL";"DOTATION_AOU";"DOTATION_SEP";"DOTATION_OCT";"DOTATION_NOV";"DOTATION_DEC";"DOTATION_ANNUELLE";"DOTATION_N";"CPTE_CATEG";"CATEGORIE_SEG_2";"TOTAL_CESSION_N";"LIVRE";"TACHE";"AJUSTEMENT_N";"FC_INVESTISSEMENT";"GY_INVESTISSEMENT"');
    -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT
        INTO lt_cur_data;
    
      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP
        
          BEGIN
            vv_ligne := lt_cur_data(i).LIGNE;
          
            -- Ecrit dans le fichier
            utl_file.put_line(l_file, vv_ligne);
          
            -- Maj des compteurs
            vn_nb_lignes := vn_nb_lignes + 1;
          
          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_log_message('ERREUR ' || lt_cur_data(i).LIGNE ||
                                            ' - ' || SQLERRM);
          END;
        
        END LOOP;
      
      END IF;
    
      EXIT WHEN cur_data%NOTFOUND;
    
    END LOOP;
    CLOSE cur_data;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    vg_nbl_extr_cmd := vn_nb_lignes;
    dka_tools_pkg.put_log_message('L''écriture dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est terminée');
    dka_tools_pkg.put_log_message('Le nombre de lignes dans le fichier ' ||
                                  p_directory_name || '/' || V_file_name ||
                                  ' est :' || vg_nbl_extr_cmd);
    vn_request_id := Fnd_Request.submit_request('DKA', -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                'DKA_SFABUDGET_REG_JUST', -- SHORT NAME DU TRAITEMENT
                                                --NULL,                           -- PROGRAM NAME
                                                p_region, -- PROGRAM NAME   -- SFA artf07235613
                                                NULL, -- START
                                                FALSE, -- SUB REQUEST
                                                p_region,
                                                V_file_name);
  
    commit;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data_cmd (' ||
                 SQLERRM || ')');
    
  END p_extr_data_justif_REG;

  -------------------------------------------------------------------------------------------------
  --  Nom           : EDIT_REG_JUSTIF
  --  Description   : Procédure principale du specifique EDIT_REG_JUSTIF
  --

  ----------------------------------------------------------------------------------------------------------

  -- SELOO
  PROCEDURE EDIT_REG_JUSTIF(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER,
                            p_regoin   IN VARCHAR2, -- 25/04/2007
                            p_file     IN VARCHAR2) IS
  
    --vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'FIN01.DONNEESDEBOURSEES';
    vg_DIRECTORY CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
    p_file_name   VARCHAR2(4000) := 'DKA_EXTR_JUSTIF';
    p_file_name2  VARCHAR2(4000) := 'DKA_EXTR_HYPERION';
    ln_nb_lignes  NUMBER := 0;
    vb_boucle     BOOLEAN;
    vn_request_id NUMBER(15);
    l_file        UTL_FILE.file_type;
    v_FileExcel   UTL_FILE.FILE_TYPE;
    v_NewLine     VARCHAR2(10000);
  
    CURSOR region IS
      SELECT DISTINCT region
        FROM DKA_SFABUDGET_WORK
       WHERE region IS NOT NULL;
  
  BEGIN
  
    l_file := UTL_FILE.fopen(vg_DIRECTORY, p_file, 'r');
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(l_file, v_NewLine);
        Fnd_File.PUT_LINE(Fnd_File.output, v_NewLine);
      EXCEPTION
        WHEN OTHERS THEN
          EXIT;
      END;
    END LOOP;
    UTL_FILE.FCLOSE(l_file);
    IF p_regoin <> 'TOUTE' THEN
      update fnd_concurrent_requests req
         set req.requested_by =
             (select user_id from fnd_user where user_name = p_regoin)
       where req.request_id = fnd_global.conc_request_id;
    END IF;
  end EDIT_REG_JUSTIF;

  -- SELOO
  PROCEDURE EDIT_REG_HYP(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode IN OUT NUMBER,
                         p_regoin   IN VARCHAR2, -- 25/04/2007
                         p_file     IN VARCHAR2) IS
  
    --vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'FIN01.DONNEESDEBOURSEES';
    vg_DIRECTORY CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
    p_file_name   VARCHAR2(4000) := 'DKA_EXTR_JUSTIF';
    p_file_name2  VARCHAR2(4000) := 'DKA_EXTR_HYPERION';
    ln_nb_lignes  NUMBER := 0;
    vb_boucle     BOOLEAN;
    vn_request_id NUMBER(15);
    l_file        UTL_FILE.file_type;
    v_FileExcel   UTL_FILE.FILE_TYPE;
    v_NewLine     VARCHAR2(10000);
  
    CURSOR region IS
      SELECT DISTINCT region
        FROM DKA_SFABUDGET_WORK
       WHERE region IS NOT NULL;
  
  BEGIN
  
    l_file := UTL_FILE.fopen(vg_DIRECTORY, p_file, 'r');
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(l_file, v_NewLine);
        Fnd_File.PUT_LINE(Fnd_File.output, v_NewLine);
      EXCEPTION
        WHEN OTHERS THEN
          EXIT;
      END;
    END LOOP;
    UTL_FILE.FCLOSE(l_file);
    if p_regoin <> 'TOUTE' then
      update fnd_concurrent_requests req
         set req.requested_by =
             (select user_id from fnd_user where user_name = p_regoin)
       where req.request_id = fnd_global.conc_request_id;
    end if;
  end EDIT_REG_HYP;
  -- DEBUT AAM
  ----------------------------------------------------------------------------------------------------
  --  Nom           : DKA_UPDATE_NULL_DATA
  --  Description   : Mise à jour des données vides dans la table DKA_SFABUDGET_WORK
  --
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  -- pv_book_type_Code         Entree             Code du livre
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE DKA_UPDATE_NULL_DATA(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode IN OUT NUMBER) IS
    CURSOR cur_data IS
      SELECT *
        FROM DKA_SFABUDGET_WORK
       where centre is null
          OR projet is null
          OR cpt_gpe is null;
    V_project_id_parent number;
    Vv_Centre           VARCHAR2(30);
    Vv_region           VARCHAR2(30);
    v_prject_name       pa_projects_all.segment1%TYPE;
    v_Cpt_Gpe           GL_CODE_COMBINATIONS.Segment4%TYPE;
  BEGIN
    dka_tools_pkg.put_log_message('DKA_UPDATE_NULL_DATA(+)');
    dka_tools_pkg.put_log_message('----------');
    dka_tools_pkg.put_log_message('Mise à jour de la table DKA_SFABUDGET_WORK');
    dka_tools_pkg.put_log_message('----------');
    FOR rec_data IN cur_data LOOP
      dka_tools_pkg.put_log_message('Ligne a mettre à jour les champs vides' ||
                                    rec_data.asset_id);
    
      BEGIN
        SELECT distinct pt2.project_id
          INTO V_project_id_parent
          FROM FA_ADDITIONS      fa1,
               FA_ASSET_INVOICES fai,
               PA_TASKS          pt,
               PA_TASKS          pt2
         WHERE fa1.asset_id = fai.asset_id
           AND pt.task_id = fai.task_id
           AND pt2.task_id = pt.attribute7
           AND fai.asset_id = rec_data.Asset_id;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          V_project_id_parent := NULL;
        WHEN OTHERS THEN
          V_project_id_parent := NULL;
      END;
      BEGIN
        SELECT segment1
          INTO v_prject_name
          FROM pa_projects_all
         WHERE project_id = V_project_id_parent;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          v_prject_name := NULL;
        WHEN OTHERS THEN
          v_prject_name := NULL;
      END;
      IF rec_data.projet IS NULL THEN
        UPDATE DKA_SFABUDGET_WORK
           SET projet = v_prject_name
         WHERE asset_id = rec_data.Asset_id;
      END IF;
    
      IF rec_data.centre IS NULL THEN
        BEGIN
          select hr_all_organization_units.name
            into Vv_Centre
            from pa_projects_all, hr_all_organization_units
           where project_id = V_project_id_parent
             and CARRYING_OUT_ORGANIZATION_ID = organization_id;
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            Vv_Centre := NULL;
          WHEN OTHERS THEN
            Vv_Centre := NULL;
        END;
        UPDATE DKA_SFABUDGET_WORK
           SET centre = Vv_Centre, cost_center = Vv_Centre
         WHERE asset_id = rec_data.Asset_id;
      END IF;
    
      IF rec_data.region IS NULL THEN
        BEGIN
          select substr(hr_all_organization_units.name, 1, 3)
            into Vv_region
            from pa_projects_all, hr_all_organization_units
           where project_id = V_project_id_parent
             and org_id = organization_id;
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            Vv_region := NULL;
          WHEN OTHERS THEN
            Vv_region := NULL;
        END;
        UPDATE DKA_SFABUDGET_WORK
           SET region = Vv_region
         WHERE asset_id = rec_data.Asset_id;
      END IF;
    
      IF rec_data.cpt_gpe IS NULL THEN
        BEGIN
          SELECT gcc.Segment4
            INTO v_Cpt_Gpe
            FROM FA_ADDITIONS         fa,
                 FA_BOOKS             fb,
                 FA_CATEGORIES        fc,
                 FA_CATEGORY_BOOKS    fcb,
                 GL_CODE_COMBINATIONS gcc
           where 1 = 1
             and fa.asset_id = fb.asset_id
             and fa.asset_category_id = fc.category_id
             and fc.category_id = fcb.category_id
             and fb.book_type_code = fcb.book_type_code
             and gcc.code_combination_id = fcb.deprn_expense_account_ccid
             and fb.transaction_header_id_out is null
             and fa.asset_id = rec_data.Asset_id
             and fcb.book_type_code = rec_data.book_type_code;
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            v_Cpt_Gpe := NULL;
          WHEN OTHERS THEN
            v_Cpt_Gpe := NULL;
        END;
        UPDATE DKA_SFABUDGET_WORK
           SET cpt_gpe = v_Cpt_Gpe
         WHERE asset_id = rec_data.Asset_id;
      END IF;
    
    END LOOP;
  END DKA_UPDATE_NULL_DATA;
  --FIN AAM

  --------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du specifique DKA_SFABUDGET
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entree/Sortie      message d'erreur
  -- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf     IN OUT VARCHAR2,
                 pn_retcode    IN OUT NUMBER,
                 pv_ref_date   IN VARCHAR2, -- 25/04/2007
                 region_budget IN VARCHAR2) IS
  
    --vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'FIN01.DONNEESDEBOURSEES';
    vg_DIRECTORY CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
    p_file_name   VARCHAR2(4000) := 'DKA_EXTR_JUSTIF';
    p_file_name2  VARCHAR2(4000) := 'DKA_EXTR_HYPERION';
    ln_nb_lignes  NUMBER := 0;
    vb_boucle     BOOLEAN;
    vn_request_id NUMBER(15);
    rec_param     dka_parameters%ROWTYPE;
    vv_conn       VARCHAR2(50);
    v_adr_to      VARCHAR2(32767);
    gv_expediteur VARCHAR2(50);
    v_cpt         INTEGER := 0;
    TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    num_trait_list   num_traitement;
    g_int_request_id fnd_concurrent_requests.request_id%TYPE;
    g_tempo          NUMBER;
    v_phase          VARCHAR2(100);
    v_status         VARCHAR2(100);
    v_dev_phase      VARCHAR2(100);
    v_dev_status     VARCHAR2(100);
    v_message        VARCHAR2(100);
  
    CURSOR region IS
      SELECT DISTINCT region
        FROM DKA_SFABUDGET_WORK
       WHERE region IS NOT NULL;
  
    CURSOR EXTR_ADR IS
      SELECT ffv.flex_value AS ADR_DESTINATION
        FROM fnd_flex_values_tl  ffvt,
             fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_SFABUDGET_MAIL_RECIPIENTS'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE);
  
  BEGIN
    Pn_Retcode := 0;
    g_tempo    := 20;
  
    IF pv_ref_date is null then
      select to_date(to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS'),
                     'YYYY/MM/DD HH24:MI:SS')
        into gv_ref_date
        from dual;
    ELSE
      gv_ref_date := to_date(pv_ref_date, 'YYYY/MM/DD HH24:MI:SS');
    END IF;
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 1 : Suppression des donnees du traitement precedent');
    dka_tools_pkg.put_log_message('=> ');
  
    DKA_DEL_SFABUDGET_WORK(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 2 : Controles');
    dka_tools_pkg.put_log_message('=> ');
  
    DKA_MAIN_CTR(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    IF NOT Vb_Continuer THEN
      -- Erreur lors d'un controle
      --> Sortie
      dka_tools_pkg.put_outdebug_message('!!!!!');
      dka_tools_pkg.put_outdebug_message('!!!!! Erreur lors d''un controle ');
      dka_tools_pkg.put_outdebug_message('!!!!! Sortie du programme ');
      dka_tools_pkg.put_outdebug_message('!!!!!');
      pv_errbuf := '!!!!! Erreur lors d''un controle ';
      RAISE Erreur_Prog_E;
    END IF;
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 3 : Generation des cles de dotation');
    dka_tools_pkg.put_log_message('=> ');
  
    -- Generation des cles de dotations si elles n'existent pas
    DKA_MAIN_FAGDA(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    IF NOT Vb_Continuer THEN
      -- Erreur lors de la soumission du programme
      --> Sortie
      dka_tools_pkg.put_outdebug_message('!!!!!');
      dka_tools_pkg.put_outdebug_message('!!!!! Erreur lors de la generation des cles de dotation');
      dka_tools_pkg.put_outdebug_message('!!!!! Sortie du programme ');
      dka_tools_pkg.put_outdebug_message('!!!!!');
      pv_errbuf := '!!!!! Erreur lors de la generation des cles de dotation';
      RAISE Erreur_Prog_E;
    END IF;
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 4 : Previsions d''amortissement');
    dka_tools_pkg.put_log_message('=> ');
  
    -- Previsions d'amortissements
    DKA_MAIN_FAPROJ(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    IF NOT Vb_Continuer THEN
      -- Erreur lors des previsions des amortissements
      --> Sortie
      dka_tools_pkg.put_outdebug_message('!!!!!');
      dka_tools_pkg.put_outdebug_message('!!!!! Erreur lors de la prevision des amortissements');
      dka_tools_pkg.put_outdebug_message('!!!!! Sortie du programme ');
      dka_tools_pkg.put_outdebug_message('!!!!!');
      pv_errbuf := '!!!!! Erreur lors de la prevision des amortissements';
      RAISE Erreur_Prog_E;
    END IF;
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 5 : Insertion et mise a jour des montants des previsions ');
    dka_tools_pkg.put_log_message('=>           dans la table DKA_SFABUDGET_WORK ');
    dka_tools_pkg.put_log_message('=> ');
  
    DKA_MAIN_COPY_DATA(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    IF NOT Vb_Continuer THEN
      -- Erreur lors des insertions et mise a jour des donnees
      --> Sortie
      dka_tools_pkg.put_outdebug_message('!!!!!');
      dka_tools_pkg.put_outdebug_message('!!!!! Erreur lors de la recopie et la mise a jour des montants des previsions ');
      dka_tools_pkg.put_outdebug_message('!!!!! Sortie du programme ');
      dka_tools_pkg.put_outdebug_message('!!!!!');
      pv_errbuf := '!!!!! Erreur lors de la recopie et la mise a jour des montants des previsions';
      RAISE Erreur_Prog_E;
    END IF;
  
    --DEBUT AAM
    -- Mise à jour des champs vides
    DKA_UPDATE_NULL_DATA(pv_errbuf, pn_retcode);
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
    --FIN AAM
  
    dka_tools_pkg.put_log_message('=> ');
    dka_tools_pkg.put_log_message('=> Phase 6 : Edition des donnees ');
    dka_tools_pkg.put_log_message('=> ');
  
    DKA_MAIN_GEN_DATA(pv_errbuf, pn_retcode);
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    -- Lancement de la PROCEDURE d'extraction justif par region
  
    FOR R0 in REGION LOOP
      v_cpt := v_cpt + 1;
      p_extr_data_justif_REG(vg_DIRECTORY,
                             p_file_name,
                             ln_nb_lignes,
                             R0.region,
                             g_int_request_id);
      num_trait_list(v_cpt) := g_int_request_id;
    END LOOP;
  
    FOR var IN 1 .. v_cpt LOOP
    
      --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || num_trait_list(var));
      Fnd_File.put_line(Fnd_File.LOG,
                        'Numéro du traitement d''extraction justif par region: ' ||
                        num_trait_list(var));
    
      IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        pv_errbuf := v_Message;
        Fnd_file.put_line(Fnd_file.log,
                          'ERREUR : Attente de la fin du programme: ' ||
                          num_trait_list(var) || ' Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        Fnd_File.put_line(Fnd_File.LOG,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement en warning ' ||
                          g_int_request_id);
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement en warning ' ||
                          g_int_request_id);
        pn_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        pn_retcode := 1; --artf2063044
        pv_errbuf  := 'ERREUR : Fin anormale du traitement : ' || v_Message;
      
        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Fin anormale du traitement ' ||
                          g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || CHR(10) ||
                          'MESSAGE : ' || v_message || CHR(10));
        Fnd_File.put_line(Fnd_File.LOG,
                          '===> ERREUR : Fin anormale du traitement ' ||
                          g_int_request_id);
      END IF;
    END LOOP;
  
    -- Lancement de la PROCEDURE d'extraction justif
  
    p_extr_data_justif(vg_DIRECTORY, p_file_name, ln_nb_lignes);
  
    v_cpt := 1;
    p_extr_data_hyperion(vg_DIRECTORY, p_file_name2, g_int_request_id);
    num_trait_list(v_cpt) := g_int_request_id;
  
    FOR R1 in REGION LOOP
      v_cpt := v_cpt + 1;
      p_extr_data_hyperion_REG(vg_DIRECTORY,
                               p_file_name2,
                               R1.region,
                               g_int_request_id);
      num_trait_list(v_cpt) := g_int_request_id;
    END LOOP;
  
    --SELOO
  
    FOR var IN 1 .. v_cpt LOOP
    
      --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || num_trait_list(var));
      Fnd_File.put_line(Fnd_File.LOG,
                        'Numéro du traitement d''extraction hyperion complet ou par region : ' ||
                        num_trait_list(var));
    
      IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        pv_errbuf := v_Message;
        Fnd_file.put_line(Fnd_file.log,
                          'ERREUR : Attente de la fin du programme: ' ||
                          num_trait_list(var) || ' Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        Fnd_File.put_line(Fnd_File.LOG,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement en warning ' ||
                          g_int_request_id);
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement en warning ' ||
                          g_int_request_id);
        pn_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        pn_retcode := 1; --artf2063044
        pv_errbuf  := 'ERREUR : Fin anormale du traitement : ' || v_Message;
      
        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Fin anormale du traitement ' ||
                          g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || CHR(10) ||
                          'MESSAGE : ' || v_message || CHR(10));
        Fnd_File.put_line(Fnd_File.LOG,
                          '===> ERREUR : Fin anormale du traitement ' ||
                          g_int_request_id);
      END IF;
    END LOOP;
  
    --appel de la procédure qui envoie le mail avec PJ
    Dka_Tools_Pkg.get_parameter('DKA_SFABUDGET',
                                'SMTP_CONNECTION',
                                rec_param,
                                Pv_Errbuf,
                                Pn_Retcode);
    vv_conn := rec_param.varchar2_value;
  
    Dka_Tools_Pkg.get_parameter('DKA_SFABUDGET',
                                'EXPEDITEUR_MAIL',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_expediteur := rec_param.varchar2_value;
  
    FOR CUR_ADR IN EXTR_ADR LOOP
      v_adr_to := CUR_ADR.ADR_DESTINATION; --v_adr_to||
    
      --Envoi par mail du fichier justificatif
      SEND_MSG(p_to          => v_adr_to,
               p_from        => gv_expediteur,
               p_subject     => 'Fichier justificatif global',
               p_text_msg    => 'En pièce jointe le fichier justificatif global. Fin du traitement DKA : Interface FA - Budget.',
               p_attach_name => 'DKA_EXTR_JUSTIF.csv', --SELOO
               --p_attach_mime  => 'FIN01.DONNEESDEBOURSEES',
               p_attach_mime => 'DKA_OUT_DIR',
               p_smtp_host   => vv_conn);
    
    END LOOP;
    /*dka_tools_pkg.put_log_message ( '=> ');
    dka_tools_pkg.put_log_message ( '=> Phase 7 : Suppression des tables temporaires generees par les traitements ');
    dka_tools_pkg.put_log_message ( '=>           de prevision des amortissements');
    dka_tools_pkg.put_log_message ( '=> ');
    
    DKA_MAIN_DROP_TABLE ( pv_errbuf ,
                          pn_retcode );*/
  
    -- Erreur systeme -> Sortie
    IF pn_retcode = 2 THEN
      RAISE Erreur_Prog_E;
    END IF;
  
    -- Validation
    COMMIT;
  
  EXCEPTION
    WHEN Erreur_Prog_E THEN
      ROLLBACK;
      pn_retcode := 2;
    
      -- Si des traitements de prevision ont ete generees
      IF NVL(Vn_Nbre_FaProj, 0) <> 0 THEN
      
        dka_tools_pkg.put_outdebug_message('=> ');
        dka_tools_pkg.put_outdebug_message('=> 1 Suppression des tables temporaires generees par les traitements ');
        dka_tools_pkg.put_outdebug_message('=>  de prevision des amortissements');
        dka_tools_pkg.put_outdebug_message('=> ');
      
        -- DKA_MAIN_DROP_TABLE  ( pv_errbuf ,
        --    pn_retcode );
      END IF;
    WHEN OTHERS THEN
      ROLLBACK;
      pv_errbuf  := 'sortie de main avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
    
      -- Si des traitements de prevision ont ete generees
      IF NVL(Vn_Nbre_FaProj, 0) <> 0 THEN
      
        dka_tools_pkg.put_outdebug_message('=> ');
        dka_tools_pkg.put_outdebug_message('=> 2 Suppression des tables temporaires generees par les traitements ');
        dka_tools_pkg.put_outdebug_message('=>  de prevision des amortissements');
        dka_tools_pkg.put_outdebug_message('=> ');
      
        --  DKA_MAIN_DROP_TABLE  ( pv_errbuf ,
        --        pn_retcode );
      END IF;
    
  END main;

END DKA_SFABUDGET_PKG; -- Package body
/
SHOW ERRORS;
exit;
