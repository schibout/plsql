CREATE OR REPLACE PACKAGE BODY APPS.Dka_Sglabonnement_Pkg AS

  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : DALKIA Oracle Applications
  -- NOM              : DKA_SGLABONNEMENT_PKG
  -- DESCRIPTION      : DKA_SGLABONNEMENT_PKG Package Body
  --
  -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
  -- DATE DE CREATION : 18/07/2006
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 29/03/2007 EMA Ajout de la recherche des types de pièces dans le jeu de
  --                valeurs DKA_ABON_TYPE_PIECE.
  -- 12/04/2007 EMA Ajout du contrôle supplémentaire : un lot doit être composé
  --                de pièces du même type.
  --                Ajout de la procédure Controle_Type_Pieces.
  -- 28/05/2008 GV  is_rule_num_in_table : ajout de cette fonction pour vérifier
  --                                       la présence d'une ligne de formule
  -- 17/09/2008 EMA EIS20090062
  --                Si un compte-rendu contient des erreurs, il doit se terminer
  --                en statut "Avertissement"
  -- 26/01/2010 TB  EARS00008975248 : suppression de l'utilisation de la table
  --                Dka_Ibdsoc_I00ic_Tmp dans la procédure Traitement_Lots
  -- 14/11/2011 EMA EARS00009717370
  --                Modification des contrôles de date par rapport à la date du
  --                jour ==> ajout Trunc(SYDATE)
  -- 01/08/2016 RGH Migration R12
  -- 24/05/2017 OBE artf2159115 : SPE 108 : impossible de valider la saisie des lignes lors de la création d' une pièce répétitive
  -- 29/06/2017 YWA artf2188071 : SPE108 - Forcer désactivation Triggers en cas de plantage
  -- 26/01/2018 MEG artf2331305 : SPE108 - Gestion des abonnements
  -- 07/03/2019 MTIA artf07217339 : SPE108 - Recherche des traitements de posting
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --Gn_Set_Of_Books_Id         NUMBER(15);
  Gn_ACCESS_SET_ID           NUMBER(15); -- Modif RGH 04/08/2016
  Gn_Autopost_Set_Id         Gl_Automatic_Posting_Sets.Autopost_Set_Id%TYPE;
  Gv_Period_Name             Gl_Period_Statuses.Period_Name%TYPE;
  Gv_Program_Name_Glprje     Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE := 'GLPRJE';
  Gn_Program_Id_Glprje       Fnd_Concurrent_Programs.Concurrent_Program_Id%TYPE;
  Gv_App_Short_Name_Glprje   Fnd_Application.Application_Short_Name%TYPE;
  Gn_Application_Id_Glprje   Fnd_Concurrent_Programs.Application_Id%TYPE;
  Gn_Nb_Traitements_Glprje   NUMBER(15);
  Gv_Program_Name_Glpautop   Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE := 'GLPAUTOP';
  Gn_Program_Id_Glpautop     Fnd_Concurrent_Programs.Concurrent_Program_Id%TYPE;
  Gv_App_Short_Name_Glpautop Fnd_Application.Application_Short_Name%TYPE;
  Gn_Application_Id_Glpautop Fnd_Concurrent_Programs.Application_Id%TYPE;
  Gn_Request_Id_Glpautop     Fnd_Concurrent_Requests.Request_Id%TYPE;
  Gv_Program_Name_Cr         Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE := 'DKA_SGLABONNEMENT_CR';
  Gn_Program_Id_Cr           Fnd_Concurrent_Programs.Concurrent_Program_Id%TYPE;
  Gv_App_Short_Name_Cr       Fnd_Application.Application_Short_Name%TYPE;
  Gn_Application_Id_Cr       Fnd_Concurrent_Programs.Application_Id%TYPE;
  Gn_User_Id                 Fnd_User.User_Id%TYPE;
  Gn_Responsibility_Id       Fnd_Responsibility.Responsibility_Id%TYPE;
  Gn_Application_Id          Fnd_Responsibility.Application_Id%TYPE;
  Gn_Etats_Responsibility_Id Fnd_Responsibility.Responsibility_Id%TYPE;
  Gn_Etats_Application_Id    Fnd_Responsibility.Application_Id%TYPE;
  Gv_Program_Name_Glppos     Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE := 'GLPPOS';
  Gv_Program_Name_Glpposs     Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE := 'GLPPOSS'; -- MTIA 08/03 - Noms courts
  Gn_Request_Id_Glppos       Fnd_Concurrent_Requests.Request_Id%TYPE;
  Gv_Contexte_Charges        Gl_Je_Lines.Context%TYPE := 'Y.E.X';
  Gv_Contexte_Produits       Gl_Je_Lines.Context%TYPE := 'Y.R.X';
  Gv_Trigger_Headers_Name    User_Triggers.Trigger_Name%TYPE := 'DKA_GL_JE_HEADERS_BIR';
  Gv_Trigger_Lines_Name      User_Triggers.Trigger_Name%TYPE := 'DKA_GL_JE_LINES_BIR2';
  Gn_Copies                  NUMBER;
  Gv_Jeu_De_Valeurs          Fnd_Flex_Value_Sets.Flex_Value_Set_Name%TYPE := 'DKA_ABON_TYPE_PIECE';

  TYPE Myrecord IS RECORD(
    Request_Id           Fnd_Concurrent_Requests.Request_Id%TYPE,
    Recurring_Batch_Id   Gl_Recurring_Batches.Recurring_Batch_Id%TYPE,
    Recurring_Batch_Name Gl_Recurring_Batches.Name%TYPE,
    Traitement_Ok        VARCHAR2(2));

  TYPE Mytable IS TABLE OF Myrecord INDEX BY BINARY_INTEGER;

  Gt_Request_Id Mytable;

  Warning_Programme EXCEPTION;
  Erreur_Programme EXCEPTION;

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS SERVANT A LA PARTIE INTERACTIVE (CUSTOM.PLL)
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : get_select_record_group
  -- Description   : Renvoie le record groupe associé
  -- ---------------------------------------------------------------------------------------------------------------------
  /*FUNCTION get_select_record_group(pv_record_group IN VARCHAR2,
                                   pv_societe      IN VARCHAR2,
                                   pv_region       IN VARCHAR2)
    RETURN VARCHAR2 IS
    vv_select VARCHAR2(5000);
  BEGIN
    --Restriction code tva sur l'entête
    IF pv_record_group = 'RECBATCH_QF' THEN

      vv_select := REPLACE(cg_rec_batches,
                           'order by',
                           'and name like ''' || pv_societe || '%' ||
                           pv_region || '%'' ' || ' order by');
    ELSE
      vv_select := NULL;
    END IF;

    RETURN vv_select;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END get_select_record_group;
  */
  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : check_company_and_cost_center
  -- Description   : Contrôle la validité du couple Société/CdG
  -- ---------------------------------------------------------------------------------------------------------------------
  FUNCTION check_company_and_cost_center(pv_societe IN VARCHAR2,
                                         pv_region  IN VARCHAR2)
    RETURN BOOLEAN IS
    vn_count NUMBER := 0;

  BEGIN
    SELECT count(1)
      INTO vn_count
      FROM ( /*SELECT digi.company_code ste,
                                                         digi.mainoffice_cost_center cdg
                                                  FROM   dka_ibdsoc_general_info digi,
                                                         dka_ibdsoc_i00dgic      dii
                                                  WHERE  digi.company_code = dii.company_code
                                                  AND    dii.company_type  = 0 --societe active
                                                  UNION
                                                  SELECT dit.company_code ste,
                                                         dit.group_code cdg
                                                  FROM   dka_ibdsoc_territorialities dit,
                                                         dka_ibdsoc_i00dgic          dii
                                                  WHERE  dit.company_code = dii.company_code
                                                  AND    dii.company_type = 0 --societe active*/ -- Modif RGH 03/08/2016

            SELECT val.FLEX_VALUE ste, -- Modif RGH 03/08/2016
                    val.ATTRIBUTE2 cdg -- Modif RGH 03/08/2016
              FROM fnd_flex_value_sets sets, -- Modif RGH 03/08/2016
                    fnd_flex_values_vl  val, -- Modif RGH 03/08/2016
                    GL_LEDGERS          gl -- Modif RGH 03/08/2016
             WHERE sets.flex_value_set_id = val.flex_value_set_id -- Modif RGH 03/08/2016
               and gl.short_name = val.flex_value -- Modif RGH 03/08/2016
               and ledger_category_code = 'PRIMARY' -- Modif RGH 03/08/2016
               and val.enabled_flag = 'Y' -- Modif RGH 03/08/2016
               and SYSDATE BETWEEN nvl(val.start_date_active, SYSDATE) AND
                   nvl(val.end_date_active, SYSDATE) -- Modif RGH 03/08/2016
               and val.summary_flag = 'N' -- Modif RGH 03/08/2016
               and val.VALUE_CATEGORY = 'DAOPCCF_STE' -- Modif RGH 03/08/2016
            UNION -- Modif RGH 03/08/2016
            select substr(name, 4, 7) ste, substr(name, 1, 3) cdg -- Modif RGH 03/08/2016
              from HR_OPERATING_UNITS -- Modif RGH 03/08/2016
             where trunc(SYSDATE) BETWEEN nvl(DATE_FROM, trunc(SYSDATE)) AND
                   nvl(DATE_TO, trunc(SYSDATE))
            INTERSECT
            SELECT pv_societe, pv_region FROM DUAL);

    IF vn_count = 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;

  END check_company_and_cost_center;

  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : check_account
  -- Description   : Contrôle le compte local
  -- ---------------------------------------------------------------------------------------------------------------------
  FUNCTION check_account(pv_local_account IN VARCHAR2) RETURN BOOLEAN IS
    vn_count NUMBER := 0;

  BEGIN

    SELECT count(1)
      INTO vn_count
      FROM fnd_flex_values ffv, fnd_flex_value_sets ffvs
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       --AND ffv.compiled_value_attributes like '%Y'        -- OBE artf2159115
       AND SUBSTR(ffv.compiled_value_attributes,7,1) = 'Y'  -- OBE artf2159115
       AND ffv.flex_value = pv_local_account;

    IF vn_count = 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;

  END check_account;

  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : get_rec_header_tot_amount
  -- Description   : renvoie le montant total d'un lot d'abonnement
  -- ---------------------------------------------------------------------------------------------------------------------
  PROCEDURE get_rec_header_tot_amount(pn_rec_header_id IN NUMBER,
                                      pn_rec_line_num  IN NUMBER,
                                      pn_debit_amount  OUT NUMBER,
                                      pn_credit_amount OUT NUMBER)

   IS

  BEGIN

    SELECT SUM(decode(sign(grlcr.amount), 1, grlcr.amount, 0)),
           SUM(decode(sign(grlcr.amount), -1, grlcr.amount * -1, 0))
      INTO pn_debit_amount, pn_credit_amount
      FROM gl_recurring_line_calc_rules grlcr
     WHERE grlcr.recurring_header_id = pn_rec_header_id
       AND grlcr.recurring_line_num != pn_rec_line_num;

  EXCEPTION
    WHEN OTHERS THEN
      pn_debit_amount  := 0;
      pn_credit_amount := 0;

  END get_rec_header_tot_amount;

  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : get_rec_line_description
  -- Description   : renvoie le libellé d'une ligne de pièce d'abonnement
  -- ---------------------------------------------------------------------------------------------------------------------
  FUNCTION get_rec_line_description(pn_rec_header_id IN NUMBER)
    RETURN VARCHAR2 IS
    vv_description gl_recurring_lines.description%TYPE;
  BEGIN

    SELECT grl.description
      INTO vv_description
      FROM gl_recurring_lines grl
     WHERE grl.recurring_header_id = pn_rec_header_id
       AND rownum = 1
     ORDER BY grl.recurring_line_num;

    RETURN vv_description;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END get_rec_line_description;

  -- ---------------------------------------------------------------------------------------------------------------------
  -- Nom           : is_rule_num_in_table
  -- Description   : vérifie si la ligne de calcul est présente pour le N°de ligne indiqué
  -- ---------------------------------------------------------------------------------------------------------------------
  FUNCTION is_rule_num_in_table(pn_rec_header_id IN NUMBER,
                                pn_rec_line_num  IN NUMBER) RETURN BOOLEAN IS
    vn_count   NUMBER := 0;
    vb_present BOOLEAN;
  BEGIN

    SELECT COUNT(*)
      INTO vn_count
      FROM gl_recurring_line_calc_rules grlcr
     WHERE grlcr.recurring_header_id = pn_rec_header_id
       AND grlcr.recurring_line_num = pn_rec_line_num;

    vb_present := (vn_count >= 1);

    RETURN vb_present;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END is_rule_num_in_table;

  -- ++++++++++++++++++++++++++++++++++++++++++++++++++
  -- Fin des fonctions servant à la partie interactive
  -- ++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- -----------------------------------------------------------------------------
  -- Nom              : Initialisation
  -- Description      : Procédure d'initialisation des variables globales.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Initialisation(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER) IS

    Vv_Errbuf         VARCHAR2(2500);
    Vn_Retcode        NUMBER;
    Vr_Data           Dka_Parameters%ROWTYPE;
    Vv_Status         User_Triggers.Status%TYPE;
    Vv_Commande       VARCHAR2(250);
    Vv_Message_Erreur VARCHAR2(250);

    Erreur_Traitement EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Initialisation (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    -------------------------------------------------
    -- Activation du trigger DKA_GL_JE_HEADERS_BIR --
    -------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Activation du trigger ' ||
                                       Gv_Trigger_Headers_Name);
    Vv_Commande := 'ALTER TRIGGER ' || Gv_Trigger_Headers_Name || ' ENABLE';
    EXECUTE IMMEDIATE Vv_Commande;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de l''activation du trigger ' ||
                           Gv_Trigger_Headers_Name;
      SELECT Ut.Status
        INTO Vv_Status
        FROM User_Triggers Ut
       WHERE Ut.Trigger_Name = Gv_Trigger_Headers_Name
         AND Ut.Status = 'ENABLED';

      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le trigger ' ||
                                         Gv_Trigger_Headers_Name ||
                                         ' est actif');
    END;

    ------------------------------------------------
    -- Activation du trigger DKA_GL_JE_LINES_BIR2 --
    ------------------------------------------------
    /**/
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Activation du trigger ' ||
                                       Gv_Trigger_Lines_Name);
    Vv_Commande := 'ALTER TRIGGER ' || Gv_Trigger_Lines_Name || ' ENABLE';
    EXECUTE IMMEDIATE Vv_Commande;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de l''activation du trigger ' ||
                           Gv_Trigger_Lines_Name;
      SELECT Ut.Status
        INTO Vv_Status
        FROM User_Triggers Ut
       WHERE Ut.Trigger_Name = Gv_Trigger_Lines_Name
         AND Ut.Status = 'ENABLED';

      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le trigger ' ||
                                         Gv_Trigger_Lines_Name ||
                                         ' est actif');
    END;

    ---------------------------------------
    -- Initialisation du ACCESS_SET_ID --
    ---------------------------------------
    -- RGH
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche du GL_ACCESS_SET_ID');
    --Gn_Set_Of_Books_Id := Fnd_Profile.Value('GL_SET_OF_BKS_ID'); -- RGH
    Gn_ACCESS_SET_ID := Fnd_Profile.VALUE('GL_ACCESS_SET_ID');
    Dka_Tools_Pkg.Put_Debug_Message('==> ACCESS_SET_ID : ' ||
                                    Gn_ACCESS_SET_ID);

    --------------------------------------------------------
    -- Récupération des informations du traitement GLPRJE --
    --------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des informations du traitement GLPRJE');
    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la récupération des informations du traitement GLPRJE';
      SELECT Fa.Application_Short_Name,
             Fcp.Application_Id,
             Fcp.Concurrent_Program_Id
        INTO Gv_App_Short_Name_Glprje,
             Gn_Application_Id_Glprje,
             Gn_Program_Id_Glprje
        FROM Fnd_Concurrent_Programs Fcp, Fnd_Application Fa
       WHERE Fcp.Concurrent_Program_Name = Gv_Program_Name_Glprje
         AND Fa.Application_Id = Fcp.Application_Id;

      Dka_Tools_Pkg.Put_Debug_Message('==> Gv_App_Short_Name_Glprje : ' ||
                                      Gv_App_Short_Name_Glprje);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Application_Id_Glprje : ' ||
                                      Gn_Application_Id_Glprje);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Program_Id_Glprje     : ' ||
                                      Gn_Program_Id_Glprje);
    END;

    ----------------------------------------------------------
    -- Récupération des informations du traitement GLPAUTOP --
    ----------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des informations du traitement GLPAUTOP');
    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la récupération des informations du traitement GLPAUTOP';
      SELECT Fa.Application_Short_Name,
             Fcp.Application_Id,
             Fcp.Concurrent_Program_Id
        INTO Gv_App_Short_Name_Glpautop,
             Gn_Application_Id_Glpautop,
             Gn_Program_Id_Glpautop
        FROM Fnd_Concurrent_Programs Fcp, Fnd_Application Fa
       WHERE Fcp.Concurrent_Program_Name = Gv_Program_Name_Glpautop
         AND Fa.Application_Id = Fcp.Application_Id;

      Dka_Tools_Pkg.Put_Debug_Message('==> Gv_App_Short_Name_Glpautop : ' ||
                                      Gv_App_Short_Name_Glpautop);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Application_Id_Glpautop : ' ||
                                      Gn_Application_Id_Glpautop);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Program_Id_Glpautop     : ' ||
                                      Gn_Program_Id_Glpautop);
    END;

    ----------------------------------------------------------------------
    -- Récupération des informations du traitement DKA_SGLABONNEMENT_CR --
    ----------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des informations du traitement DKA_SGLABONNEMENT_CR');
    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la récupération des informations du traitement DKA_SGLABONNEMENT_CR';
      SELECT Fa.Application_Short_Name,
             Fcp.Application_Id,
             Fcp.Concurrent_Program_Id
        INTO Gv_App_Short_Name_Cr, Gn_Application_Id_Cr, Gn_Program_Id_Cr
        FROM Fnd_Concurrent_Programs Fcp, Fnd_Application Fa
       WHERE Fcp.Concurrent_Program_Name = Gv_Program_Name_Cr
         AND Fa.Application_Id = Fcp.Application_Id;

      Dka_Tools_Pkg.Put_Debug_Message('==> Gv_App_Short_Name_Cr : ' ||
                                      Gv_App_Short_Name_Cr);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Application_Id_Cr : ' ||
                                      Gn_Application_Id_Cr);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Program_Id_Cr     : ' ||
                                      Gn_Program_Id_Cr);
    END;

    -------------------------------------------
    -- Récupération du jeu d'auto-imputation --
    -------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des informations du jeu d''auto-imputation');
    Dka_Tools_Pkg.Get_Parameter('DKA_SGLABONNEMENT',
                                'GL_AUTOPOST_SET_NAME',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      Vv_Message_Erreur := 'Erreur lors de la recherche de GL_AUTOPOST_SET_NAME dans Dka_Parameters';
      RAISE Erreur_Traitement;
    END IF;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la récupération du jeu d''Auto-Imputation';
      SELECT Autopost_Set_Id
        INTO Gn_Autopost_Set_Id
        FROM Gl_Automatic_Posting_Sets Gaps
       WHERE Gaps.Autopost_Set_Name = Vr_Data.Varchar2_Value
            -- AND    Gaps.Set_Of_Books_Id   = Gn_Set_Of_Books_Id;  -- RGH
         AND Gaps.CHART_OF_ACCOUNTS_ID =
             (select CHART_OF_ACCOUNTS_ID
                from gl_access_sets glas
               where glas.access_set_id = Gn_ACCESS_SET_ID); -- RGH

      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Autopost_Set_Id : ' ||
                                      Gn_Autopost_Set_Id);
    END;

    ------------------------------------------------------------------------
    -- Récupération de la responsabilité pour l'édition des compte-rendus --
    ------------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche de la responsabilité pour l''édition des compte-rendus');
    Dka_Tools_Pkg.Get_Parameter('DKA_SGLABONNEMENT',
                                'ETATS_RESPONSIBILITY_KEY',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      Vv_Message_Erreur := 'Erreur lors de la recherche de ETATS_RESPONSIBILITY_KEY dans Dka_Parameters';
      RAISE Erreur_Traitement;
    END IF;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la recherche de la responsabilité pour l''édition des compte-rendus';
      SELECT Fr.Responsibility_Id, Fr.Application_Id
        INTO Gn_Etats_Responsibility_Id, Gn_Etats_Application_Id
        FROM Fnd_Responsibility Fr
       WHERE Fr.Responsibility_Key = Vr_Data.Varchar2_Value;

      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Etats_Responsibility_Id : ' ||
                                      Gn_Etats_Responsibility_Id);
      Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Etats_Application_Id    : ' ||
                                      Gn_Etats_Application_Id);
    END;

    ---------------------------------------
    -- Récupération du nombre de copies  --
    ---------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche du nombre de copies');
    Dka_Tools_Pkg.Get_Parameter('DKA_SGLABONNEMENT',
                                'NOMBRE_COPIES',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      Vv_Message_Erreur := 'Erreur lors de la recherche de NOMBRE_COPIES dans Dka_Parameters';
      RAISE Erreur_Traitement;
    END IF;

    Gn_Copies := Vr_Data.Number_Value;
    Dka_Tools_Pkg.Put_Debug_Message('==> Nombre de copies : ' || Gn_Copies);

    -----------------------------
    -- Recherche de la période --
    -----------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Recherche de la période');
    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la recherche de la période';
      /*
      SELECT Gps.Period_Name
        INTO Gv_Period_Name
        FROM Gl_Period_Statuses Gps
       WHERE Gps.Application_Id = 101
         AND Gps.Set_Of_Books_Id = Gn_Set_Of_Books_Id
         AND Trunc(SYSDATE) BETWEEN Gps.Start_Date AND Gps.End_Date;
      */
      -- Modif RGH 04/08/2016
      select gp.period_name
        INTO Gv_Period_Name
        from gl_access_sets glas, gl_periods gp
       where glas.period_set_name = gp.period_set_name
         AND glas.access_set_id = Gn_ACCESS_SET_ID
         AND Trunc(SYSDATE) BETWEEN Gp.Start_Date AND Gp.End_Date;
      -- Modif RGH 04/08/2016

      Dka_Tools_Pkg.Put_Outdebug_Message('==> Période : ' ||
                                         Gv_Period_Name);
    END;

    ------------------------------------------------------------
    -- Suppression des enregistrements de la table de travail --
    ------------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Suppression des enregistrements de la table Dka_Sglabonnement_Err');
    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la suppression des enregistrements de la table Dka_Sglabonnement_Err';
      DELETE FROM Dka_Sglabonnement_Err;

      Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT ||
                                      ' enregistrements supprimés');
    END;

    ---------------------------------------------------------
    -- Positionnement dans le contexte Oracle Applications --
    ---------------------------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des informations de connexion');
    Dka_Tools_Pkg.Get_Parameter('DKA_SGLABONNEMENT',
                                'GL_RESPONSIBILITY_KEY',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      Vv_Message_Erreur := 'Erreur lors de la recherche de GL_RESPONSIBILITY_KEY dans Dka_Parameters';
      RAISE Erreur_Traitement;
    END IF;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors du positionnement dans le contexte Oracle-Applications';
      SELECT Fnd_Global.User_Id, Fr.Responsibility_Id, Fr.Application_Id
        INTO Gn_User_Id, Gn_Responsibility_Id, Gn_Application_Id
        FROM Fnd_Responsibility Fr
       WHERE Fr.Responsibility_Key = Vr_Data.Varchar2_Value;
    END;

    Dka_Tools_Pkg.Put_Debug_Message('==> Gn_User_Id           : ' ||
                                    Gn_User_Id);
    Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Responsibility_Id : ' ||
                                    Gn_Responsibility_Id);
    Dka_Tools_Pkg.Put_Debug_Message('==> Gn_Application_Id    : ' ||
                                    Gn_Application_Id);

    Fnd_Global.Apps_Initialize(Gn_User_Id,
                               Gn_Responsibility_Id,
                               Gn_Application_Id); /**/
    Dka_Tools_Pkg.Put_Debug_Message('==> Connexion établie');

    Dka_Tools_Pkg.Put_Debug_Message('Initialisation (-)');

  EXCEPTION
    WHEN Erreur_Traitement THEN
      Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vv_Message_Erreur);
      Pv_Errbuf  := 'Erreur dans de la procécure Init : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message('Initialisation (-)');
    WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vv_Message_Erreur);
      Pv_Errbuf  := 'Erreur dans de la procécure Init : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message('Initialisation (-)');

  END Initialisation;

  -- -----------------------------------------------------------------------------
  -- Nom              : Insertion_Erreur
  -- Description      : Procédure d'insertion des messages d'erreur dans la table
  --                    DKA_SGLABONNEMENT_ERR
  --
  -- PARAMETRES       : Pv_Nom_Lot         Entree        Nom du lot à contrôler
  --                    Pv_Centre_Gestion  Entree        Centre de Gestion
  --                    Pv_Societe         Entree        Societe
  --                    Pv_Message         Entree        Message d'erreur
  --                    Pv_Errbuf                 Sortie Message d'erreur
  --                    Pn_Retcode                Sortie Code Retour de la procédure
  --                                                     '0' : Normal
  --                                                     '1' : Avertissement
  --                                                     '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Insertion_Erreur(Pv_Nom_Lot        IN VARCHAR2,
                             Pv_Centre_Gestion IN VARCHAR2,
                             Pv_Societe        IN VARCHAR2,
                             Pv_Message        IN VARCHAR2,
                             Pv_Errbuf         OUT VARCHAR2,
                             Pn_Retcode        OUT NUMBER) IS
  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Insertion_Erreur (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    -----------------------------------------------------------------------
    -- Insertion du message d'erreur dans la table Dka_Sglabonnement_Err --
    -----------------------------------------------------------------------
    INSERT INTO Dka_Sglabonnement_Err
      (Nom_Lot, Centre_Gestion, Societe, Message, Creation_Date)
    VALUES
      (Pv_Nom_Lot, Pv_Centre_Gestion, Pv_Societe, Pv_Message, SYSDATE);

    Dka_Tools_Pkg.Put_Debug_Message('Insertion_Erreur (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Insertion_Erreur : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Insertion_Erreur (-)');

  END Insertion_Erreur;

  -- -----------------------------------------------------------------------------
  -- Nom              : Controle_Type_Pieces
  -- Description      : Procédure qui contrôle que toutes les pièces du lot sont
  --                    de même type
  --
  -- PARAMETRES       : Pn_Recurring_Batch_Id  Entree        Id du lot à controler
  --                    Pv_Nom_Lot             Entree        Nom du lot à contrôler
  --                    Pv_Centre_Gestion      Entree        Centre de Gestion
  --                    Pv_Societe             Entree        Societe
  --                    Pv_Errbuf                     Sortie Message d'erreur
  --                    Pn_Retcode                    Sortie Code Retour de la procédure
  --                                                         '0' : Normal
  --                                                         '1' : Avertissement
  --                                                         '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Controle_Type_Pieces(Pn_Recurring_Batch_Id IN NUMBER,
                                 Pv_Nom_Lot            IN VARCHAR2,
                                 Pv_Centre_Gestion     IN VARCHAR2,
                                 Pv_Societe            IN VARCHAR2,
                                 Pv_Errbuf             OUT VARCHAR2,
                                 Pn_Retcode            OUT NUMBER) IS

    Vn_Nombre_Type_Pieces NUMBER;
    Vb_Type_Pieces        BOOLEAN;
    Vv_Message            VARCHAR2(2500);

    Erreur_Insert EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Type_Pieces (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des types de pièces du lot');

    Vb_Type_Pieces := TRUE;
    -----------------------------------------------
    -- Calcul du nombre de type de pièces du lot --
    -----------------------------------------------
    SELECT COUNT(DISTINCT Grh.User_Je_Category_Name) Nombre_Types
      INTO Vn_Nombre_Type_Pieces
      FROM Gl_Recurring_Headers_v Grh,
           --Gl_Period_Statuses   Gps  --RGH
           Gl_Periods     Gp, --RGH
           gl_access_sets glas -- RGH
     WHERE 1 = 1
       AND Grh.Recurring_Batch_Id = Pn_Recurring_Batch_Id
       AND EXISTS
     (SELECT 'X'
              FROM Fnd_Flex_Value_Sets Ffvs, Fnd_Flex_Values Ffv
             WHERE Ffvs.Flex_Value_Set_Name = Gv_Jeu_De_Valeurs
               AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id
               AND Ffv.Flex_Value = Grh.User_Je_Category_Name
               AND Ffv.Enabled_Flag = 'Y'
               AND Trunc(SYSDATE) BETWEEN
                   Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) AND
                   Nvl(Ffv.End_Date_Active, Trunc(SYSDATE)))
       /*
       AND Gps.Application_Id   = 101
       AND  Gps.Set_Of_Books_Id = Gn_Set_Of_Books_Id
       AND Gps.Period_Name      = Gv_Period_Name
       AND Nvl(Grh.Start_Date_Active, Gps.Start_Date) <= Gps.Start_Date
       AND Nvl(Grh.End_Date_Active, Gps.End_Date) >= Gps.End_Date
       */ --RGH
       AND glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
       AND gp.period_name = Gv_Period_Name -- RGH
       AND glas.period_set_name = gp.period_set_name -- RGH
       AND Nvl(Grh.Start_Date_Active, Gp.Start_Date) <= Gp.Start_Date -- RGH
       AND Nvl(Grh.End_Date_Active, Gp.End_Date) >= Gp.End_Date -- RGH
    ;

    ---------------------------------------------------
    -- Le type de pièce doit être unique pour le lot --
    ---------------------------------------------------
    IF Vn_Nombre_Type_Pieces != 1 THEN
      Vv_Message := 'Les pièces du lot ne sont pas toutes du même type';
      Insertion_Erreur(Pv_Nom_Lot,
                       Pv_Centre_Gestion,
                       Pv_Societe,
                       Vv_Message,
                       Pv_Errbuf,
                       Pn_Retcode);
      IF Pn_Retcode = 2 THEN
        RAISE Erreur_Insert;
      END IF;

      Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vv_Message);
      Vb_Type_Pieces := FALSE;
    END IF;

    IF Vb_Type_Pieces THEN
      Dka_Tools_Pkg.Put_Debug_Message('==> Toutes les pièces du lot sont du même type');
    ELSE
      Pv_Errbuf  := 'Il existe des pièces de type différent dans le lot';
      Pn_Retcode := 1;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Type_Pieces (-)');

  EXCEPTION
    WHEN Erreur_Insert THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Type_Pieces : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Type_Pieces (-)');
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Type_Pieces : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Type_Pieces (-)');

  END Controle_Type_Pieces;

  -- -----------------------------------------------------------------------------
  -- Nom              : Controle_Pieces_Equilibrees
  -- Description      : Procédure de contrôle de l'équilibre des pièces qui
  --                    composent le lot
  --
  -- PARAMETRES       : Pn_Recurring_Batch_Id  Entree        Id du lot à controler
  --                    Pv_Nom_Lot             Entree        Nom du lot à contrôler
  --                    Pv_Centre_Gestion      Entree        Centre de Gestion
  --                    Pv_Societe             Entree        Societe
  --                    Pv_Errbuf                     Sortie Message d'erreur
  --                    Pn_Retcode                    Sortie Code Retour de la procédure
  --                                                         '0' : Normal
  --                                                         '1' : Avertissement
  --                                                         '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Controle_Pieces_Equilibrees(Pn_Recurring_Batch_Id IN NUMBER,
                                        Pv_Nom_Lot            IN VARCHAR2,
                                        Pv_Centre_Gestion     IN VARCHAR2,
                                        Pv_Societe            IN VARCHAR2,
                                        Pv_Errbuf             OUT VARCHAR2,
                                        Pn_Retcode            OUT NUMBER) IS

    ----------------------------------------------------
    -- Curseur de recherche des pièces déséquilibrées --
    ----------------------------------------------------
    CURSOR Cur_Headers(Pn_Recurring_Batch_Id NUMBER) IS
      SELECT Grh.Name Nom_Piece, SUM(Grlcl.Amount) Montant
        FROM Gl_Recurring_Headers_v       Grh,
             Gl_Recurring_Lines           Grl,
             Gl_Recurring_Line_Calc_Rules Grlcl,
             --Gl_Period_Statuses   Gps  --RGH
             Gl_Periods     Gp, --RGH
             Gl_Access_Sets glas -- RGH
       WHERE 1 = 1
         AND Grh.Recurring_Batch_Id = Pn_Recurring_Batch_Id
            -- AND    Grh.User_Je_Category_Name   = 'ABONNEMENTS'    Modif EMA du 29/03/2007
         AND EXISTS
       (SELECT 'X' -- Modif EMA du 29/03/2007
                FROM Fnd_Flex_Value_Sets Ffvs, -- Modif EMA du 29/03/2007
                     Fnd_Flex_Values     Ffv -- Modif EMA du 29/03/2007
               WHERE Ffvs.Flex_Value_Set_Name = Gv_Jeu_De_Valeurs -- Modif EMA du 29/03/2007
                 AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id -- Modif EMA du 29/03/2007
                 AND Ffv.Flex_Value = Grh.User_Je_Category_Name -- Modif EMA du 29/03/2007
                 AND Ffv.Enabled_Flag = 'Y' -- Modif EMA du 29/03/2007
                 AND Trunc(SYSDATE) BETWEEN
                     Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) -- Modif EMA du 29/03/2007
                     AND Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))) -- Modif EMA du 29/03/2007
            /*
                                 AND Gps.Set_Of_Books_Id    = Gn_Set_Of_Books_Id
                                 AND Gps.Application_Id = 101
                                 AND Gps.Period_Name    = Gv_Period_Name
                                 AND Nvl(Grh.Start_Date_Active, Gps.Start_Date) <= Gps.Start_Date
                                 AND Nvl(Grh.End_Date_Active, Gps.End_Date)     >= Gps.End_Date
                                 */ --RGH
         AND glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND gp.period_name = Gv_Period_Name -- RGH
         AND glas.period_set_name = gp.period_set_name -- RGH
         AND Nvl(Grh.Start_Date_Active, Gp.Start_Date) <= Gp.Start_Date -- RGH
         AND Nvl(Grh.End_Date_Active, Gp.End_Date) >= Gp.End_Date -- RGH
         AND Grh.Recurring_Header_Id = Grl.Recurring_Header_Id
         AND Grl.Recurring_Header_Id = Grlcl.Recurring_Header_Id
         AND Grl.Recurring_Line_Num = Grlcl.Recurring_Line_Num
       GROUP BY Grh.Name
      HAVING SUM(Grlcl.Amount) <> 0;

    Rec_Headers Cur_Headers%ROWTYPE;

    Vb_Pieces_Equilibrees BOOLEAN;
    Vv_Message            VARCHAR2(2500);

    Erreur_Insert EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Pieces_Equilibrees (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Dka_Tools_Pkg.Put_Debug_Message('=> Recherche des pièces déséquilibrées');

    Vb_Pieces_Equilibrees := TRUE;
    -------------------------------------------------
    -- Boucle de lecture des pièces déséquilibrées --
    -------------------------------------------------
    OPEN Cur_Headers(Pn_Recurring_Batch_Id);
    LOOP
      FETCH Cur_Headers
        INTO Rec_Headers;
      EXIT WHEN Cur_Headers%NOTFOUND;

      Vv_Message := 'La pièce : ' || Rec_Headers.Nom_Piece ||
                    ' est déséquilibrée';
      Insertion_Erreur(Pv_Nom_Lot,
                       Pv_Centre_Gestion,
                       Pv_Societe,
                       Vv_Message,
                       Pv_Errbuf,
                       Pn_Retcode);
      IF Pn_Retcode = 2 THEN
        RAISE Erreur_Insert;
      END IF;

      Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vv_Message);
      Vb_Pieces_Equilibrees := FALSE;

    END LOOP;
    CLOSE Cur_Headers;

    IF Vb_Pieces_Equilibrees THEN
      Dka_Tools_Pkg.Put_Debug_Message('==> Toutes les pièces du lot sont équilibrées');
    ELSE
      Pv_Errbuf  := 'Il existe des pièces déséquilibrées';
      Pn_Retcode := 1;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Pieces_Equilibrees (-)');

  EXCEPTION
    WHEN Erreur_Insert THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Pieces_Equilibrees : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Pieces_Equilibrees (-)');
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Pieces_Equilibrees : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Pieces_Equilibrees (-)');

  END Controle_Pieces_Equilibrees;

  -- -----------------------------------------------------------------------------
  -- Nom              : Controle_Cuf
  -- Description      : Procédure de contrôle de la valeur du CUF.
  --
  -- PARAMETRES       : Pv_Nom_Lot         Entree        Nom du lot à contrôler
  --                    Pv_Centre_Gestion  Entree        Centre de Gestion
  --                    Pv_Societe         Entree        Code Societe
  --                    Pv_Context         Entree        Contexte
  --                    Pv_Attribute1      Entree        Attribute1
  --                    Pv_Attribute2      Entree        Attribute2
  --                    Pv_Attribute3      Entree        Attribute3
  --                    Pv_Nom_Piece       Entree        Nom de la pièce
  --                    Pn_Num_Ligne       Entrée        Numéro de la ligne
  --                    Pv_Errbuf                 Sortie Message d'erreur
  --                    Pn_Retcode                Sortie Code Retour de la procédure
  --                                                     '0' : Normal
  --                                                     '1' : Avertissement
  --                                                     '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Controle_Cuf(Pv_Nom_Lot        IN VARCHAR2,
                         Pv_Centre_Gestion IN VARCHAR2,
                         Pv_Societe        IN VARCHAR2,
                         Pv_Context        IN VARCHAR2,
                         Pv_Attribute1     IN VARCHAR2,
                         Pv_Attribute2     IN VARCHAR2,
                         Pv_Attribute3     IN VARCHAR2,
                         Pv_Attribute4     IN VARCHAR2,-- YWA artf2188071
                         Pv_Nom_Piece      IN VARCHAR2,
                         Pn_Num_Ligne      IN VARCHAR2,
                         Pv_Errbuf         OUT VARCHAR2,
                         Pn_Retcode        OUT NUMBER) IS

    Vv_Dummy               VARCHAR2(1);
    Vv_Segment1            Pa_Projects_All.Segment1%TYPE;
    Vv_Project_Status_Code Pa_Projects_All.Project_Status_Code%TYPE;
    Vv_Template_Flag       Pa_Projects_All.Template_Flag%TYPE;
    Vv_Project_Type        Pa_Projects_All.Project_Type%TYPE;
    --Vv_Class_Code                   Pa_Project_Classes.Class_Code%TYPE;  -- Modif RGH 01/08/2016
    Vv_Societe_Name VARCHAR2(250); -- Modif RGH 01/08/2016
    Vv_Message      VARCHAR2(2500);
    Vb_Projet_Ok    BOOLEAN;
    Vb_Erreur_Cuf   BOOLEAN;
    v_task_id       pa_tasks.task_id%TYPE;

    Erreur_Insert EXCEPTION;
  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Cuf (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Vb_Erreur_Cuf := FALSE;

    ----------------------------------------
    -- On vérifie si le CUF est renseigné --
    ----------------------------------------
    Dka_Tools_Pkg.Put_Debug_Message('=> Contrôle des données du CUF de la ligne ' ||
                                    Pn_Num_Ligne || ' de la pièce : ' || Pv_Nom_Piece);
    IF Pv_Context = Gv_Contexte_Charges THEN
      ----------------------------------------------------------
      --Les Attribute1, Attribute2 et Attribute4  doivent être renseignés
      --l'Attribute3 doit être nul
      ----------------------------------------------------------

      IF Pv_Attribute1 IS NULL OR Pv_Attribute2 IS NULL OR Pv_Attribute4 IS NULL OR
         Pv_Attribute3 IS NOT NULL -- YWA artf2188071
      -- Pv_Attribute3 IS NOT NULL --RGH
       THEN
        Vv_Message := 'Un des attributs du CUF de la ligne ' ||
                      Pn_Num_Ligne || ' de la pièce : ' || Pv_Nom_Piece || ' n''est pas correctement renseigné';
        Insertion_Erreur(Pv_Nom_Lot,
                         Pv_Centre_Gestion,
                         Pv_Societe,
                         Vv_Message,
                         Pv_Errbuf,
                         Pn_Retcode);
        IF Pn_Retcode = 2 THEN
          RAISE Erreur_Insert;
        END IF;

        Vb_Erreur_Cuf := TRUE;
        Pn_Retcode    := 1;
        Pv_Errbuf     := Vv_Message;
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
      END IF;
    ELSIF Pv_Context = Gv_Contexte_Produits THEN
      ----------------------------------------------------------
      --Les Attribute1, Attribute2 et Attribute3  doivent être renseignés
      -- L'Attribute4 doit être nul
      ----------------------------------------------------------
      IF Pv_Attribute1 IS NULL OR Pv_Attribute2 IS NULL OR Pv_Attribute3 IS NULL OR
      Pv_Attribute4 IS NOT NULL THEN-- YWA artf2188071
        Vv_Message := 'Un des attributs du CUF de la ligne ' ||
                      Pn_Num_Ligne || ' de la pièce : ' || Pv_Nom_Piece ||
                      ' n''est pas correctement renseigné';
        Insertion_Erreur(Pv_Nom_Lot,
                         Pv_Centre_Gestion,
                         Pv_Societe,
                         Vv_Message,
                         Pv_Errbuf,
                         Pn_Retcode);
        IF Pn_Retcode = 2 THEN
          RAISE Erreur_Insert;
        END IF;

        Vb_Erreur_Cuf := TRUE;
        Pn_Retcode    := 1;
        Pv_Errbuf     := Vv_Message;
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
      END IF;
    ELSE
      ----------------------------------------------------------
      --Les Attribute1, Attribute2, l'Attribute3 et Attribute4  doivent être nuls
      ----------------------------------------------------------
      IF Pv_Attribute1 IS NOT NULL OR Pv_Attribute2 IS NOT NULL OR
         Pv_Attribute3 IS NOT NULL OR Pv_Attribute4 IS NOT NULL THEN -- YWA artf2188071
        Vv_Message := 'Un des attributs du CUF de la ligne ' ||
                      Pn_Num_Ligne || ' de la pièce : ' || Pv_Nom_Piece ||
                      ' n''est pas correctement renseigné';
        Insertion_Erreur(Pv_Nom_Lot,
                         Pv_Centre_Gestion,
                         Pv_Societe,
                         Vv_Message,
                         Pv_Errbuf,
                         Pn_Retcode);
        IF Pn_Retcode = 2 THEN
          RAISE Erreur_Insert;
        END IF;

        Vb_Erreur_Cuf := TRUE;
        Pn_Retcode    := 1;
        Pv_Errbuf     := Vv_Message;
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
      END IF;
    END IF;

    -----------------------------------
    -- Controle Context = 'E' ou 'R' --
    -----------------------------------
    IF Pv_Context = Gv_Contexte_Charges OR
       Pv_Context = Gv_Contexte_Produits THEN

      Vb_Projet_Ok := TRUE;

      ------------------------
      -- Contrôle du projet --
      ------------------------
      Dka_Tools_Pkg.Put_Debug_Message('=> Contrôle du project_id : ' ||  Pv_Attribute1);
      BEGIN
        Vv_Segment1 := NULL;
        SELECT Ppa.Segment1,
               Ppa.Project_Status_Code,
               Ppa.Template_Flag,
               Ppa.Project_Type
          INTO Vv_Segment1,
               Vv_Project_Status_Code,
               Vv_Template_Flag,
               Vv_Project_Type
          FROM Pa_Projects_All Ppa
         WHERE Ppa.Project_Id = Pv_Attribute1;

        --------------------------------------
        -- Le projet ne doit pas être fermé --
        --------------------------------------
        IF Vv_Project_Status_Code = 'CLOSED' THEN
          Vv_Message := 'Le code projet ' || Vv_Segment1 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' ne doit pas être fermé';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
        END IF;

        -------------------------------------------------
        -- Le projet ne doit pas être un projet modèle --
        -------------------------------------------------
        IF Vv_Template_Flag != 'N' THEN
          Vv_Message := 'Le code projet ' || Vv_Segment1 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' ne doit pas être un projet modèle';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
        END IF;

        -----------------------------------------
        -- Le type de projet doit être correct --
        -----------------------------------------
        /* -- RGH
        IF Vv_Project_Type NOT IN
           ('EXPLOITATION', 'CODE Z', 'APPARTENANCE') THEN
          Vv_Message := 'Le type du projet ' || Vv_Segment1 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' est incorrect';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
        END IF;
        */
      EXCEPTION
        WHEN No_Data_Found THEN
          Vv_Message := 'Le code projet ' ||
                        Nvl(Vv_Segment1,
                            '(Project_Id = ' || Pv_Attribute1 || ')') ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece || ' est inconnu';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
      END;

      --------------------------------------
      -- Contrôle de la société du projet --
      --------------------------------------
      BEGIN
        -- Modif RGH : 01/08/2016
        /*SELECT Ppc.Class_Code
        INTO   Vv_Class_Code
        FROM   Pa_Project_Classes Ppc
        WHERE  Ppc.Project_Id     = Pv_Attribute1
        AND    Ppc.Class_Category = 'SOCIETE';
        */
        select substr(hou.name, 4, 4)
          INTO Vv_Societe_Name
          from PA_PROJECTS_ALL ppa, HR_OPERATING_UNITS hou
         where hou.organization_id = ppa.ORG_ID
           AND ppa.Project_Id     = Pv_Attribute1;

        IF Vv_Societe_Name != Pv_Societe THEN
          Vv_Message := 'La société (' || Vv_Societe_Name ||
                        ') du code projet ' || Vv_Segment1 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' est incorrecte';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
        END IF;

      EXCEPTION
        WHEN No_Data_Found THEN
          Vv_Message := 'La société du code projet ' ||
                        Nvl(Vv_Segment1,
                            '(Project_Id = ' || Pv_Attribute1 || ')') ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' n''est pas renseignée';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Vb_Projet_Ok  := FALSE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
      END;

      IF Vb_Projet_Ok THEN
        Dka_Tools_Pkg.Put_Debug_Message('==> Contrôle OK');
      END IF;


        --YWA artf2188071  Contrôle de la validité de la tâche : la COMPLETION_DATE de la tâche doit être inférieure ou égale au dernier jour de la période traitée (Gv_Period_Name).
        ------------------------
        -- Contrôle du tache --
        ------------------------
        BEGIN

            SELECT task_id
            INTO v_task_id
            FROM PA_TASKS
            WHERE task_id   = Pv_Attribute2
            AND NVL(completion_date, to_date('31/12/4712','DD/MM/YYYY')) >=
              (SELECT gp.end_date
              FROM gl_access_sets glas,
                gl_periods gp
              WHERE glas.period_set_name = gp.period_set_name
              AND glas.access_set_id     = Gn_ACCESS_SET_ID
              AND gp.period_name         = Gv_Period_Name
              ) ;

        EXCEPTION
            WHEN OTHERS THEN
                 Vv_Message := 'La tache task_id= '|| Pv_Attribute2 ||' du code projet ' ||
                        Nvl(Vv_Segment1, '(Project_Id = ' || Pv_Attribute1 || ')') ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' n''est pas valide';
              Insertion_Erreur(Pv_Nom_Lot,
                               Pv_Centre_Gestion,
                               Pv_Societe,
                               Vv_Message,
                               Pv_Errbuf,
                               Pn_Retcode);
              IF Pn_Retcode = 2 THEN
                RAISE Erreur_Insert;
              END IF;


            Vb_Erreur_Cuf := TRUE;
            Pn_Retcode    := 1;
            Pv_Errbuf     := Vv_Message;
            Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
            Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
        END;


    END IF;

    ----------------------------
    -- Controle Context = 'E' --
    ----------------------------
    IF Pv_Context = Gv_Contexte_Charges THEN
      ---------------------------------
      -- Contrôle du type de dépense --
      ---------------------------------
      Dka_Tools_Pkg.Put_Debug_Message('=> Contrôle du type de dépense : ' ||  Pv_Attribute4);
      BEGIN
        SELECT 'X'
          INTO Vv_Dummy
          FROM Pa_Expenditure_Types_Expend_v Petev
         WHERE Petev.System_Linkage_Function = 'PJ'
           AND Petev.Expenditure_Type = Pv_Attribute4 -- YWA  Pv_Attribute3 artf2188071 --Pv_Attribute2 -- RGH
           AND Petev.Expenditure_Type IN
               (SELECT Ptc.Expenditure_Type
                  FROM Pa_Transaction_Controls Ptc, Pa_Projects_All Ppa
                 WHERE Ppa.Project_Id = Pv_Attribute1
                   AND Ppa.Limit_To_Txn_Controls_Flag = 'Y'
                   AND Ptc.Project_Id = Ppa.Project_Id
                   AND Trunc(SYSDATE) BETWEEN
                       Nvl(Ptc.Start_Date_Active, Trunc(SYSDATE)) AND
                       Nvl(Ptc.End_Date_Active, Trunc(SYSDATE))
                UNION ALL
                SELECT Pet.Expenditure_Type
                  FROM Pa_Expenditure_Types Pet, Pa_Projects_All Ppa
                 WHERE Ppa.Project_Id = Pv_Attribute1
                   AND Ppa.Limit_To_Txn_Controls_Flag = 'N')
           AND Trunc(SYSDATE) BETWEEN
               Nvl(Petev.Expnd_Typ_Start_Date_Active, Trunc(SYSDATE)) AND
               Nvl(Petev.Expnd_Typ_End_Date_Active, Trunc(SYSDATE));

        Dka_Tools_Pkg.Put_Debug_Message('==> Contrôle OK');

      EXCEPTION
        WHEN No_Data_Found THEN
          Vv_Message := 'Le type de dépense : ' || Pv_Attribute4 || -- YWA artf2188071 Pv_Attribute2 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' est invalide';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
      END;
    END IF;

    ----------------------------
    -- Controle Context = 'R' --
    ----------------------------
    IF Pv_Context = Gv_Contexte_Produits THEN
      ---------------------------------
      -- Contrôle du type de produit --
      ---------------------------------
      Dka_Tools_Pkg.Put_Debug_Message('=> Contrôle du type de produit : ' ||
                                      Pv_Attribute3);
      BEGIN
        SELECT 'X'
          INTO Vv_Dummy
          FROM Pa_Event_Types Pet
         WHERE Pet.Event_Type = Pv_Attribute3
           AND Trunc(SYSDATE) BETWEEN
               Nvl(Pet.Start_Date_Active, Trunc(SYSDATE)) AND
               Nvl(Pet.End_Date_Active, Trunc(SYSDATE));

        Dka_Tools_Pkg.Put_Debug_Message('==> Contrôle OK');

      EXCEPTION
        WHEN No_Data_Found THEN
          Vv_Message := 'Le type de produit : ' || Pv_Attribute3 ||
                        ' du CUF de la ligne ' || Pn_Num_Ligne ||
                        ' de la pièce : ' || Pv_Nom_Piece ||
                        ' est invalide';
          Insertion_Erreur(Pv_Nom_Lot,
                           Pv_Centre_Gestion,
                           Pv_Societe,
                           Vv_Message,
                           Pv_Errbuf,
                           Pn_Retcode);
          IF Pn_Retcode = 2 THEN
            RAISE Erreur_Insert;
          END IF;

          Vb_Erreur_Cuf := TRUE;
          Pn_Retcode    := 1;
          Pv_Errbuf     := Vv_Message;
          Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
          Dka_Tools_Pkg.Put_Debug_Message(Substr(SQLERRM, 1, 80));
      END;
    END IF;

    IF Vb_Erreur_Cuf THEN
      Dka_Tools_Pkg.Put_Debug_Message('==> Erreur lors du contrôle des données du CUF');
    ELSE
      Dka_Tools_Pkg.Put_Debug_Message('==> Le CUF est correctement renseigné');
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Controle_Cuf (-)');

  EXCEPTION
    WHEN Erreur_Insert THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Cuf : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Cuf (-)');
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Controle_Cuf : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Controle_Cuf (-)');

  END Controle_Cuf;

  -- -----------------------------------------------------------------------------
  -- Nom              : Soumission_Traitement
  -- Description      : Procédure de soumission d'un traitement.
  --
  -- PARAMETRES       : Pv_Prog_Application_Short_Name  Entrée        Nom court de
  --                                                                  l'application
  --                    Pv_Prog_Name                    Entrée        Nom court du
  --                                                                  programme
  --                    Pn_Request_Id                          Sortie N° Traitement
  --                    Pv_Errbuf                              Sortie Message d'erreur
  --                    Pn_Retcode                             Sortie Code Retour de la
  --                                                                  procédure
  --                                                                  '0' : Normal
  --                                                                  '1' : Avertissement
  --                                                                  '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Soumission_Traitement(Pv_Prog_Application_Short_Name IN VARCHAR2,
                                  Pv_Prog_Name                   IN VARCHAR2,
                                  Pn_Request_Id                  OUT NUMBER,
                                  Pv_Errbuf                      OUT VARCHAR2,
                                  Pn_Retcode                     OUT NUMBER) IS

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Soumission_Traitement (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    ------------------------------
    -- Soumission du traitement --
    ------------------------------
    Dka_Tools_Pkg.Put_Debug_Message('=> Pv_Prog_Application_Short_Name : ' ||
                                    Pv_Prog_Application_Short_Name);
    Dka_Tools_Pkg.Put_Debug_Message('=> Pv_Prog_Name                   : ' ||
                                    Pv_Prog_Name);

    Pn_Request_Id := Fnd_Request.Submit_Request(Pv_Prog_Application_Short_Name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                Pv_Prog_Name, -- SHORT NAME DU TRAITEMENT
                                                NULL, -- PROGRAM NAME
                                                NULL, -- START
                                                FALSE, -- SUB REQUEST
                                                Dka_Tools_Pkg.Tab_Request_Params(1), -- ARGUMENT1
                                                Dka_Tools_Pkg.Tab_Request_Params(2), -- ARGUMENT2
                                                Dka_Tools_Pkg.Tab_Request_Params(3), -- ARGUMENT3
                                                Dka_Tools_Pkg.Tab_Request_Params(4), -- ARGUMENT4
                                                Dka_Tools_Pkg.Tab_Request_Params(5), -- ARGUMENT5
                                                Dka_Tools_Pkg.Tab_Request_Params(6), -- ARGUMENT6
                                                Dka_Tools_Pkg.Tab_Request_Params(7), -- ARGUMENT7
                                                Dka_Tools_Pkg.Tab_Request_Params(8), -- ARGUMENT8
                                                Dka_Tools_Pkg.Tab_Request_Params(9), -- ARGUMENT9
                                                Dka_Tools_Pkg.Tab_Request_Params(10), -- ARGUMENT10
                                                Dka_Tools_Pkg.Tab_Request_Params(11), -- ARGUMENT11
                                                Dka_Tools_Pkg.Tab_Request_Params(12), -- ARGUMENT12
                                                Dka_Tools_Pkg.Tab_Request_Params(13), -- ARGUMENT13
                                                Dka_Tools_Pkg.Tab_Request_Params(14), -- ARGUMENT14
                                                Dka_Tools_Pkg.Tab_Request_Params(15), -- ARGUMENT15
                                                Dka_Tools_Pkg.Tab_Request_Params(16), -- ARGUMENT16
                                                Dka_Tools_Pkg.Tab_Request_Params(17), -- ARGUMENT17
                                                Dka_Tools_Pkg.Tab_Request_Params(18), -- ARGUMENT18
                                                Dka_Tools_Pkg.Tab_Request_Params(19), -- ARGUMENT19
                                                Dka_Tools_Pkg.Tab_Request_Params(20), -- ARGUMENT20
                                                Dka_Tools_Pkg.Tab_Request_Params(21), -- ARGUMENT21
                                                Dka_Tools_Pkg.Tab_Request_Params(22), -- ARGUMENT22
                                                Dka_Tools_Pkg.Tab_Request_Params(23), -- ARGUMENT23
                                                Dka_Tools_Pkg.Tab_Request_Params(24), -- ARGUMENT24
                                                Dka_Tools_Pkg.Tab_Request_Params(25), -- ARGUMENT25
                                                Dka_Tools_Pkg.Tab_Request_Params(26), -- ARGUMENT26
                                                Dka_Tools_Pkg.Tab_Request_Params(27), -- ARGUMENT27
                                                Dka_Tools_Pkg.Tab_Request_Params(28), -- ARGUMENT28
                                                Dka_Tools_Pkg.Tab_Request_Params(29), -- ARGUMENT29
                                                Dka_Tools_Pkg.Tab_Request_Params(30), -- ARGUMENT30
                                                Dka_Tools_Pkg.Tab_Request_Params(31), -- ARGUMENT31
                                                Dka_Tools_Pkg.Tab_Request_Params(32), -- ARGUMENT32
                                                Dka_Tools_Pkg.Tab_Request_Params(33), -- ARGUMENT33
                                                Dka_Tools_Pkg.Tab_Request_Params(34), -- ARGUMENT34
                                                Dka_Tools_Pkg.Tab_Request_Params(35), -- ARGUMENT35
                                                Dka_Tools_Pkg.Tab_Request_Params(36), -- ARGUMENT36
                                                Dka_Tools_Pkg.Tab_Request_Params(37), -- ARGUMENT37
                                                Dka_Tools_Pkg.Tab_Request_Params(38), -- ARGUMENT38
                                                Dka_Tools_Pkg.Tab_Request_Params(39), -- ARGUMENT39
                                                Dka_Tools_Pkg.Tab_Request_Params(40), -- ARGUMENT40
                                                Dka_Tools_Pkg.Tab_Request_Params(41), -- ARGUMENT41
                                                Dka_Tools_Pkg.Tab_Request_Params(42), -- ARGUMENT42
                                                Dka_Tools_Pkg.Tab_Request_Params(43), -- ARGUMENT43
                                                Dka_Tools_Pkg.Tab_Request_Params(44), -- ARGUMENT44
                                                Dka_Tools_Pkg.Tab_Request_Params(45), -- ARGUMENT45
                                                Dka_Tools_Pkg.Tab_Request_Params(46), -- ARGUMENT46
                                                Dka_Tools_Pkg.Tab_Request_Params(47), -- ARGUMENT47
                                                Dka_Tools_Pkg.Tab_Request_Params(48), -- ARGUMENT48
                                                Dka_Tools_Pkg.Tab_Request_Params(49), -- ARGUMENT49
                                                Dka_Tools_Pkg.Tab_Request_Params(50), -- ARGUMENT50
                                                Dka_Tools_Pkg.Tab_Request_Params(51), -- ARGUMENT51
                                                Dka_Tools_Pkg.Tab_Request_Params(52), -- ARGUMENT52
                                                Dka_Tools_Pkg.Tab_Request_Params(53), -- ARGUMENT53
                                                Dka_Tools_Pkg.Tab_Request_Params(54), -- ARGUMENT54
                                                Dka_Tools_Pkg.Tab_Request_Params(55), -- ARGUMENT55
                                                Dka_Tools_Pkg.Tab_Request_Params(56), -- ARGUMENT56
                                                Dka_Tools_Pkg.Tab_Request_Params(57), -- ARGUMENT57
                                                Dka_Tools_Pkg.Tab_Request_Params(58), -- ARGUMENT58
                                                Dka_Tools_Pkg.Tab_Request_Params(59), -- ARGUMENT59
                                                Dka_Tools_Pkg.Tab_Request_Params(60), -- ARGUMENT60
                                                Dka_Tools_Pkg.Tab_Request_Params(61), -- ARGUMENT61
                                                Dka_Tools_Pkg.Tab_Request_Params(62), -- ARGUMENT62
                                                Dka_Tools_Pkg.Tab_Request_Params(63), -- ARGUMENT63
                                                Dka_Tools_Pkg.Tab_Request_Params(64), -- ARGUMENT64
                                                Dka_Tools_Pkg.Tab_Request_Params(65), -- ARGUMENT65
                                                Dka_Tools_Pkg.Tab_Request_Params(66), -- ARGUMENT66
                                                Dka_Tools_Pkg.Tab_Request_Params(67), -- ARGUMENT67
                                                Dka_Tools_Pkg.Tab_Request_Params(68), -- ARGUMENT68
                                                Dka_Tools_Pkg.Tab_Request_Params(69), -- ARGUMENT69
                                                Dka_Tools_Pkg.Tab_Request_Params(70), -- ARGUMENT70
                                                Dka_Tools_Pkg.Tab_Request_Params(71), -- ARGUMENT71
                                                Dka_Tools_Pkg.Tab_Request_Params(72), -- ARGUMENT72
                                                Dka_Tools_Pkg.Tab_Request_Params(73), -- ARGUMENT73
                                                Dka_Tools_Pkg.Tab_Request_Params(74), -- ARGUMENT74
                                                Dka_Tools_Pkg.Tab_Request_Params(75), -- ARGUMENT75
                                                Dka_Tools_Pkg.Tab_Request_Params(76), -- ARGUMENT76
                                                Dka_Tools_Pkg.Tab_Request_Params(77), -- ARGUMENT77
                                                Dka_Tools_Pkg.Tab_Request_Params(78), -- ARGUMENT78
                                                Dka_Tools_Pkg.Tab_Request_Params(79), -- ARGUMENT79
                                                Dka_Tools_Pkg.Tab_Request_Params(80), -- ARGUMENT80
                                                Dka_Tools_Pkg.Tab_Request_Params(81), -- ARGUMENT81
                                                Dka_Tools_Pkg.Tab_Request_Params(82), -- ARGUMENT82
                                                Dka_Tools_Pkg.Tab_Request_Params(83), -- ARGUMENT83
                                                Dka_Tools_Pkg.Tab_Request_Params(84), -- ARGUMENT84
                                                Dka_Tools_Pkg.Tab_Request_Params(85), -- ARGUMENT85
                                                Dka_Tools_Pkg.Tab_Request_Params(86), -- ARGUMENT86
                                                Dka_Tools_Pkg.Tab_Request_Params(87), -- ARGUMENT87
                                                Dka_Tools_Pkg.Tab_Request_Params(88), -- ARGUMENT88
                                                Dka_Tools_Pkg.Tab_Request_Params(89), -- ARGUMENT89
                                                Dka_Tools_Pkg.Tab_Request_Params(90), -- ARGUMENT90
                                                Dka_Tools_Pkg.Tab_Request_Params(91), -- ARGUMENT91
                                                Dka_Tools_Pkg.Tab_Request_Params(92), -- ARGUMENT92
                                                Dka_Tools_Pkg.Tab_Request_Params(93), -- ARGUMENT93
                                                Dka_Tools_Pkg.Tab_Request_Params(94), -- ARGUMENT94
                                                Dka_Tools_Pkg.Tab_Request_Params(95), -- ARGUMENT95
                                                Dka_Tools_Pkg.Tab_Request_Params(96), -- ARGUMENT96
                                                Dka_Tools_Pkg.Tab_Request_Params(97), -- ARGUMENT97
                                                Dka_Tools_Pkg.Tab_Request_Params(98), -- ARGUMENT98
                                                Dka_Tools_Pkg.Tab_Request_Params(99), -- ARGUMENT99
                                                Dka_Tools_Pkg.Tab_Request_Params(100) -- ARGUMENT100
                                                );

    ---------------------------------------------
    -- Validation pour soumettre le traitement --
    ---------------------------------------------
    COMMIT;

    IF Pn_Request_Id = 0 THEN
      Pv_Errbuf  := 'Erreur dans la procécure Soumission_Traitement';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Soumission_Traitement (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Soumission_Traitement : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Soumission_Traitement (-)');

  END Soumission_Traitement;

  -- -----------------------------------------------------------------------------
  -- Nom              : Traitement_Lots
  -- Description      : Procédure de traitement des lots.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Traitement_Lots(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER) IS

    ---------------------------------------------
    -- Curseur de recherche des lots à traiter --
    ---------------------------------------------
    CURSOR Cur_Lots IS
      SELECT DISTINCT Grb.Recurring_Batch_Id Batch_Id,
                      Grb.Name Nom_Lot,
                      Substr(Grb.Name, 1, 4) Societe,
                      Substr(Grb.Name, 6, 3) Centre_Gestion
        FROM Gl_Recurring_Batches   Grb,
             Gl_Recurring_Headers_v Grh,
             --Gl_Period_Statuses           Gps, -- RGH
             -- Dka_Ibdsoc_I00ic_Tmp        Diit,  -- Modif TB  26/01/2010
             -- Dka_Ibdsoc_I00dgic          Dii,   -- RGH
             -- Dka_Ibdsoc_General_Info     Digi   -- RGH
             gl_periods          gp, -- RGH
             fnd_flex_value_sets sets, -- RGH
             fnd_flex_values_vl  val, -- RGH
             GL_LEDGERS          gl, -- RGH
             gl_access_sets      glas -- RGH
       WHERE 1 = 1
         AND Nvl(Grb.Last_Executed_Period_Name, '#') <> Gv_Period_Name -- 1 : Le lot n'a pas encore été traité
         AND Grb.Recurring_Batch_Id = Grh.Recurring_Batch_Id
            -- AND    Grh.User_Je_Category_Name                   = 'ABONNEMENTS'            -- 2 : Pièce de type ABONNEMENTS
         AND EXISTS
       (SELECT 'X' -- Modif EMA du 29/03/2007
                FROM Fnd_Flex_Value_Sets Ffvs, -- Modif EMA du 29/03/2007
                     Fnd_Flex_Values     Ffv -- Modif EMA du 29/03/2007
               WHERE Ffvs.Flex_Value_Set_Name = Gv_Jeu_De_Valeurs -- Modif EMA du 29/03/2007
                 AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id -- Modif EMA du 29/03/2007
                 AND Ffv.Flex_Value = Grh.User_Je_Category_Name -- Modif EMA du 29/03/2007
                 AND Ffv.Enabled_Flag = 'Y' -- Modif EMA du 29/03/2007
                 AND Trunc(SYSDATE) BETWEEN
                     Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) -- Modif EMA du 29/03/2007
                     AND Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))) -- Modif EMA du 29/03/2007
            /*AND Gps.Application_Id = 101 -- 3 : Pièce active pour
                                 AND Gps.Set_Of_Books_Id = Gn_Set_Of_Books_Id -- 3   la période traitée
                                 AND Gps.Period_Name = Gv_Period_Name -- 3
                                 AND Nvl(Grh.Start_Date_Active, Gps.Start_Date) <= Gps.Start_Date -- 3
                                 AND Nvl(Grh.End_Date_Active, Gps.End_Date) >= Gps.End_Date       -- 3
                                */ -- RGH
         AND glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND glas.period_set_name = gp.period_set_name -- RGH
         AND Nvl(Grh.Start_Date_Active, Gp.Start_Date) <= Gp.Start_Date -- RGH
         AND Nvl(Grh.End_Date_Active, Gp.End_Date) >= Gp.End_Date -- RGH
         AND Gp.Period_Name = Gv_Period_Name  --YWA artf2188071
            --AND    Dii.Company_Code     = Diit.Company_Code              -- Modif TB 26/01/2010
            /*
                                 AND    Substr(Grb.Name, 1, 4)   = Dii.Company_Code     -- 4 : Le lot concerne
                                 AND    Dii.Company_Type           = '0'                 -- 4
                                 AND    Dii.Company_Code           = Digi.Company_Code;  -- 4
                                 */ -- RGH
         AND Substr(Grb.Name, 1, 4) = val.FLEX_VALUE -- RGH
         AND sets.flex_value_set_id = val.flex_value_set_id -- RGH
         AND gl.short_name = val.flex_value -- RGH
         AND gl.ledger_category_code = 'PRIMARY' -- RGH
         AND val.enabled_flag = 'Y' -- RGH
         AND SYSDATE BETWEEN nvl(val.start_date_active, SYSDATE) AND
             nvl(val.end_date_active, SYSDATE) -- RGH
         AND val.summary_flag = 'N' -- RGH
         AND val.VALUE_CATEGORY = 'DAOPCCF_STE'; -- 4       -- RGH
    Rec_Lots Cur_Lots%ROWTYPE;

    -----------------------------------
    -- Curseur de lecture des lignes --
    -----------------------------------
    CURSOR Cur_Lignes(Pn_Recurring_Batch_Id NUMBER) IS
      SELECT Grh.Name               Nom_Piece,
             Grl.Recurring_Line_Num Recurring_Line_Num,
             Grl.Context            Context,
             Grl.Attribute1         Attribute1,
             Grl.Attribute2         Attribute2,
             Grl.Attribute3         Attribute3,
             Grl.Attribute4         Attribute4 --YWA artf2188071
        FROM Gl_Recurring_Headers_v Grh,
             Gl_Recurring_Lines     Grl,
             --Gl_Period_Statuses   Gps  --RGH
             Gl_Periods     Gp, --RGH
             Gl_Access_Sets glas -- RGH
       WHERE 1 = 1
         AND Grh.Recurring_Batch_Id = Pn_Recurring_Batch_Id
            -- AND    Grh.User_Je_Category_Name  = 'ABONNEMENTS'        Modif EMA du 29/03/2007
         AND EXISTS
       (SELECT 'X' -- Modif EMA du 29/03/2007
                FROM Fnd_Flex_Value_Sets Ffvs, -- Modif EMA du 29/03/2007
                     Fnd_Flex_Values     Ffv -- Modif EMA du 29/03/2007
               WHERE Ffvs.Flex_Value_Set_Name = Gv_Jeu_De_Valeurs -- Modif EMA du 29/03/2007
                 AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id -- Modif EMA du 29/03/2007
                 AND Ffv.Flex_Value = Grh.User_Je_Category_Name -- Modif EMA du 29/03/2007
                 AND Ffv.Enabled_Flag = 'Y' -- Modif EMA du 29/03/2007
                 AND Trunc(SYSDATE) BETWEEN
                     Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) -- Modif EMA du 29/03/2007
                     AND Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))) -- Modif EMA du 29/03/2007
            /*
                                 AND Gps.Application_Id = 101
                                 AND Gps.Set_Of_Books_Id = Gn_Set_Of_Books_Id
                                 AND Gps.Period_Name = Gv_Period_Name
                                 AND Nvl(Grh.Start_Date_Active, Gps.Start_Date) <= Gps.Start_Date
                                 AND Nvl(Grh.End_Date_Active, Gps.End_Date) >= Gps.End_Date
                                 */ --RGH
         AND glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND glas.period_set_name = gp.period_set_name -- RGH
         AND Nvl(Grh.Start_Date_Active, Gp.Start_Date) <= Gp.Start_Date -- RGH
         AND Nvl(Grh.End_Date_Active, Gp.End_Date) >= Gp.End_Date -- RGH
         AND Gp.Period_Name = Gv_Period_Name  --YWA artf2188071
         AND Grh.Recurring_Header_Id = Grl.Recurring_Header_Id;

    Rec_Lignes Cur_Lignes%ROWTYPE;

    Vv_Errbuf               VARCHAR2(2500);
    Vn_Retcode              NUMBER;
    Vb_Controle_Type_Pieces BOOLEAN;
    Vb_Controle_Pieces      BOOLEAN;
    Vb_Controle_Cuf         BOOLEAN;
    Vn_Indice               NUMBER := 0;
    Vn_Indice_Parametre     NUMBER;
    Vn_Request_Id           NUMBER;

    Erreur_Controle_Cuf EXCEPTION;
    Erreur_Controle_Pieces EXCEPTION;
    Erreur_Controle_Type_Pieces EXCEPTION;
    Erreur_Traitement_Lots EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    ------------------------------
    -- Lecture de tous les lots --
    ------------------------------
    Gn_Nb_Traitements_Glprje := 0;
    OPEN Cur_Lots;
    LOOP
      FETCH Cur_Lots
        INTO Rec_Lots;
      EXIT WHEN Cur_Lots%NOTFOUND;

      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Contrôle du lot : ' || Rec_Lots.Nom_Lot);
      -- Début modif EMA du 12/04/2007
      ----------------------------------------------------------------
      -- On contrôle que toutes les pièces du lot sont de même type --
      ----------------------------------------------------------------
      Vb_Controle_Type_Pieces := TRUE;
      Controle_Type_Pieces(Rec_Lots.Batch_Id,
                           Rec_Lots.Nom_Lot,
                           Rec_Lots.Centre_Gestion,
                           Rec_Lots.Societe,
                           Vv_Errbuf,
                           Vn_Retcode);

      IF Vn_Retcode = 1 THEN
        Pv_Errbuf               := Vv_Errbuf;
        Pn_Retcode              := Vn_Retcode;
        Vb_Controle_Type_Pieces := FALSE;
      ELSIF Vn_Retcode = 2 THEN
        RAISE Erreur_Controle_Type_Pieces;
      END IF;
      -- Fin modif EMA du 12/04/2007

      ------------------------------------------------------------------------
      -- On contrôle que toutes les pièces du lot répétitif sont équilibrés --
      ------------------------------------------------------------------------
      Vb_Controle_Pieces := TRUE;
      Controle_Pieces_Equilibrees(Rec_Lots.Batch_Id,
                                  Rec_Lots.Nom_Lot,
                                  Rec_Lots.Centre_Gestion,
                                  Rec_Lots.Societe,
                                  Vv_Errbuf,
                                  Vn_Retcode);

      IF Vn_Retcode = 1 THEN
        Pv_Errbuf          := Vv_Errbuf;
        Pn_Retcode         := Vn_Retcode;
        Vb_Controle_Pieces := FALSE;
      ELSIF Vn_Retcode = 2 THEN
        RAISE Erreur_Controle_Pieces;
      END IF;

      -------------------------------------
      -- Contrôle du CUF de chaque ligne --
      -------------------------------------
      Vb_Controle_Cuf := TRUE;
      OPEN Cur_Lignes(Rec_Lots.Batch_Id);
      LOOP
        FETCH Cur_Lignes
          INTO Rec_Lignes;
        EXIT WHEN Cur_Lignes%NOTFOUND;

        Dka_Tools_Pkg.Put_Debug_Message('==> Contrôle de la pièce : ' ||
                                        Rec_Lignes.Nom_Piece ||
                                        ' - Ligne : ' ||
                                        Rec_Lignes.Recurring_Line_Num);

        ---------------------------------
        -- Contrôle des valeurs du CUF --
        ---------------------------------
        Controle_Cuf(Rec_Lots.Nom_Lot,
                     Rec_Lots.Centre_Gestion,
                     Rec_Lots.Societe,
                     Rec_Lignes.Context,
                     Rec_Lignes.Attribute1,
                     Rec_Lignes.Attribute2,
                     Rec_Lignes.Attribute3,
                     Rec_Lignes.Attribute4,--YWA artf2188071
                     Rec_Lignes.Nom_Piece,
                     Rec_Lignes.Recurring_Line_Num,
                     Vv_Errbuf,
                     Vn_Retcode);

        IF Vn_Retcode = 1 THEN
          Pv_Errbuf       := Vv_Errbuf;
          Pn_Retcode      := Vn_Retcode;
          Vb_Controle_Cuf := FALSE;
        ELSIF Vn_Retcode = 2 THEN
          RAISE Erreur_Controle_Cuf;
        END IF;

      END LOOP;
      CLOSE Cur_Lignes;

      -------------------------------------------------------------------------------
      -- Les pièces sont équilibrées et les CUF des lignes correctement renseignés --
      -------------------------------------------------------------------------------
      IF Vb_Controle_Type_Pieces AND Vb_Controle_Pieces AND Vb_Controle_Cuf THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Le lot est correctement paramètré');

        ----------------------------------
        -- Renseignement des paramètres --
        ----------------------------------
        FOR Vn_Indice_Parametre IN 1 .. 100 LOOP
          Dka_Tools_Pkg.Tab_Request_Params(Vn_Indice_Parametre) := Chr(0);
        END LOOP;
        Dka_Tools_Pkg.Tab_Request_Params(1) := Rec_Lots.Batch_Id;
        Dka_Tools_Pkg.Tab_Request_Params(2) := Gv_Period_Name;
        -- Dka_Tools_Pkg.Tab_Request_Params(3) := Gn_Set_Of_Books_Id; --RGH
        Dka_Tools_Pkg.Tab_Request_Params(3) := Gn_ACCESS_SET_Id; --RGH
        Dka_Tools_Pkg.Tab_Request_Params(4) := NULL;
        Dka_Tools_Pkg.Tab_Request_Params(5) := NULL;
        Dka_Tools_Pkg.Tab_Request_Params(6) := NULL;
        Dka_Tools_Pkg.Tab_Request_Params(7) := 'N';

        --Dka_Tools_Pkg.Put_Outdebug_Message(fnd_profile.value('USER_ID'));
        --Dka_Tools_Pkg.Put_Outdebug_Message(fnd_profile.value('RESP_ID'));
        --Dka_Tools_Pkg.Put_Outdebug_Message(fnd_profile.value('RESP_APPL_ID'));

        ------------------------------
        -- Soumission du traitement --
        ------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Soumission du traitement ''Pièce répétitive''');
        Soumission_Traitement(Gv_App_Short_Name_Glprje,
                              Gv_Program_Name_Glprje,
                              Vn_Request_Id,
                              Vv_Errbuf,
                              Vn_Retcode);

        IF Vn_Retcode = 0 THEN
          Vn_Indice := Vn_Indice + 1;
          Gt_Request_Id(Vn_Indice).Request_Id := Vn_Request_Id;
          Gt_Request_Id(Vn_Indice).Recurring_Batch_Id := Rec_Lots.Batch_Id;
          Gt_Request_Id(Vn_Indice).Recurring_Batch_Name := Rec_Lots.Nom_Lot;
          Gt_Request_Id(Vn_Indice).Traitement_Ok := 'KO';

          Dka_Tools_Pkg.Put_Outdebug_Message('==> Traitement lancé sous le numéro : ' ||
                                             Vn_Request_Id);
          Dka_Tools_Pkg.Put_Debug_Message('    Avec les paramètres :');
          Dka_Tools_Pkg.Put_Debug_Message('    => ID lot répétitif                    : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(1));
          Dka_Tools_Pkg.Put_Debug_Message('    => Nom de la période                   : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(2));
          Dka_Tools_Pkg.Put_Debug_Message('    => ID entité comptable                 : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(3));
          Dka_Tools_Pkg.Put_Debug_Message('    => ID version de budget                : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(4));
          Dka_Tools_Pkg.Put_Debug_Message('    => Date de début de validité du calcul : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(5));
          Dka_Tools_Pkg.Put_Debug_Message('    => Date validité pièce                 : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(6));
          Dka_Tools_Pkg.Put_Debug_Message('    => Indicateur pièce moyenne            : ' ||
                                          Dka_Tools_Pkg.Tab_Request_Params(7));

        ELSE
          Pv_Errbuf := 'Erreur dans la procédure Traitement_Lots (Soumission du traitement)';
          RAISE Erreur_Traitement_Lots;
        END IF;

      ELSE
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors du contrôle du lot');
      END IF;

    END LOOP;
    CLOSE Cur_Lots;

    ------------------------------------------------
    -- Sauvegarde du nombre de traitements lancés --
    ------------------------------------------------
    Gn_Nb_Traitements_Glprje := Vn_Indice;

    Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');

  EXCEPTION
    WHEN Erreur_Controle_Cuf THEN
      Pv_Errbuf  := 'Erreur dans la procédure Traitement_Lots (Contrôle du CUF)';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');
    WHEN Erreur_Controle_Pieces THEN
      Pv_Errbuf  := 'Erreur dans la procédure Traitement_Lots (Contrôle des pièces déséquilibrées)';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');
    WHEN Erreur_Controle_Type_Pieces THEN
      Pv_Errbuf  := 'Erreur dans la procédure Traitement_Lots (Contrôle du type des pièces d''un lot)';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');
    WHEN Erreur_Traitement_Lots THEN
      Pv_Errbuf  := 'Erreur dans la procédure Traitement_Lots (Soumission du traitement)';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procédure Traitement_Lots : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Traitement_Lots (-)');

  END Traitement_Lots;

  -- -----------------------------------------------------------------------------
  -- Nom              : Attente_Fin_Trait_Glprje
  -- Description      : Procédure d'attente de la fin de tous les traitements.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Attente_Fin_Trait_Glprje(Pv_Errbuf  OUT VARCHAR2,
                                     Pn_Retcode OUT NUMBER) IS

    Vn_Indice     NUMBER;
    Vn_Interval   NUMBER := 10;
    Vn_Max_Wait   NUMBER := 0;
    Vv_Phase      VARCHAR2(80);
    Vv_Status     VARCHAR2(80);
    Vv_Dev_Phase  VARCHAR2(30);
    Vv_Dev_Status VARCHAR2(30);
    Vv_Message    VARCHAR2(240);
    Vb_Trait_Ok   BOOLEAN;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glprje (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Vb_Trait_Ok := TRUE;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de traitement à attendre');
    ELSE
      ---------------------------------------------
      -- Boucle d'attente de fin des traitements --
      ---------------------------------------------
      FOR Vn_Indice IN 1 .. Gn_Nb_Traitements_Glprje LOOP
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Attente de la fin du traitement : ' ||
                                           Gt_Request_Id(Vn_Indice)
                                           .Request_Id);
        IF NOT Fnd_Concurrent.Wait_For_Request(Gt_Request_Id(Vn_Indice)
                                               .Request_Id,
                                               Vn_Interval,
                                               Vn_Max_Wait,
                                               Vv_Phase,
                                               Vv_Status,
                                               Vv_Dev_Phase,
                                               Vv_Dev_Status,
                                               Vv_Message) THEN
          Pv_Errbuf  := Vv_Message;
          Pn_Retcode := 2;
          Dka_Tools_Pkg.Put_Debug_Message(Vv_Message);
        ELSE
          IF Vv_Dev_Status = 'NORMAL' THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                               Gt_Request_Id(Vn_Indice)
                                               .Request_Id ||
                                               ' s''est terminé normalement');
            Gt_Request_Id(Vn_Indice).Traitement_Ok := 'OK';
          ELSIF Vv_Dev_Status = 'WARNING' THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                               Gt_Request_Id(Vn_Indice)
                                               .Request_Id ||
                                               ' s''est terminé en warning');
            Vb_Trait_Ok := FALSE;
          ELSIF Vv_Dev_Status != 'NORMAL' THEN
            Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                               Gt_Request_Id(Vn_Indice)
                                               .Request_Id ||
                                               ' s''est terminé en erreur');
            Vb_Trait_Ok := FALSE;
          END IF;
        END IF;
      END LOOP;

      IF NOT Vb_Trait_Ok THEN
        Pv_Errbuf  := '==> Un ou plusieurs traitements se sont terminés en Warning ou en Erreur';
        Pn_Retcode := 1;
        Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      END IF;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glprje (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Attente_Fin_Trait_Glprje : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glprje (-)');

  END Attente_Fin_Trait_Glprje;

  -- -----------------------------------------------------------------------------
  -- Nom              : Verification_Lots
  -- Description      : Procédure d'attente de la fin de tous les traitements.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Verification_Lots(Pv_Errbuf  OUT VARCHAR2,
                              Pn_Retcode OUT NUMBER) IS

    ------------------------------------------
    -- Curseur de lecture des pièces nulles --
    ------------------------------------------
    CURSOR Cur_Headers(Pn_Je_Batch_Id NUMBER) IS
      SELECT Gjhv.Name,
             Gjhv.Running_Total_Accounted_Dr,
             Gjhv.Running_Total_Accounted_Cr,
             Gjhv.Row_Id,
             Gjhv.Je_Header_Id,
             Gjhv.Batch_Rowid,
             Gjhv.Je_Batch_Id,
             -- Gjhv.Set_Of_Books_Id,  -- Modif RGH 01/08/2016
             Gjhv.Ledger_Id, -- Modif RGH 01/08/2016
             Gjhv.Actual_Flag,
             Gjhv.Period_Name,
             Gjhv.Batch_Name,
             Gjhv.Batch_Status,
             Gjhv.Status_Verified,
             Gjhv.Batch_Default_Effective_Date,
             Gjhv.Batch_Posted_Date,
             Gjhv.Batch_Date_Created,
             Gjhv.Budgetary_Control_Status,
             Gjhv.Approval_Status_Code,
             Gjhv.Batch_Control_Total,
             Gjhv.Batch_Running_Total_Dr,
             Gjhv.Batch_Running_Total_Cr,
             Gjhv.Average_Journal_Flag,
             Gjhv.Posting_Run_Id,
             Gjhv.Request_Id,
             Gjhv.Packet_Id,
             Gjhv.Unreservation_Packet_Id,
             --Gjhv.Org_Id,             -- RGH
             Gjhv.Last_Updated_By,
             Gjhv.Last_Update_Login,
             Gjhv.Chart_of_Accounts_ID, -- RGH
             Gjhv.Period_Set_Name, -- RGH
             Gjhv.Accounted_Period_Type -- RGH
        FROM Gl_Je_Headers_v       Gjhv,
             GL_Je_Lines           Gjl,
             Gl_access_sets        Glas, -- RGH
             Gl_ACCESS_SET_LEDGERS Glasl -- RGH
       WHERE Gjhv.Je_Batch_Id = Pn_Je_Batch_Id
            -- AND    Gjhv.Set_Of_Books_Id = Gn_Set_Of_Books_Id -- RGH
         AND Glasl.access_set_id = Glas.access_set_id -- RGH
         AND Gjhv.Ledger_Id = Glasl.Ledger_Id -- RGH
         AND Glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND Gjhv.Je_Header_Id = Gjl.Je_Header_Id(+)
       GROUP BY Gjhv.Name,
                Gjhv.Running_Total_Accounted_Dr,
                Gjhv.Running_Total_Accounted_Cr,
                Gjhv.Row_Id,
                Gjhv.Je_Header_Id,
                Gjhv.Batch_Rowid,
                Gjhv.Je_Batch_Id,
                -- Gjhv.Set_Of_Books_Id,               -- RGH
                Gjhv.Ledger_Id, -- RGH
                Gjhv.Actual_Flag,
                Gjhv.Period_Name,
                Gjhv.Batch_Name,
                Gjhv.Batch_Status,
                Gjhv.Status_Verified,
                Gjhv.Batch_Default_Effective_Date,
                Gjhv.Batch_Posted_Date,
                Gjhv.Batch_Date_Created,
                Gjhv.Budgetary_Control_Status,
                Gjhv.Approval_Status_Code,
                Gjhv.Batch_Control_Total,
                Gjhv.Batch_Running_Total_Dr,
                Gjhv.Batch_Running_Total_Cr,
                Gjhv.Average_Journal_Flag,
                Gjhv.Posting_Run_Id,
                Gjhv.Request_Id,
                Gjhv.Packet_Id,
                Gjhv.Unreservation_Packet_Id,
                --Gjhv.Org_Id,             -- RGH
                Gjhv.Last_Updated_By,
                Gjhv.Last_Update_Login,
                Gjhv.Chart_of_Accounts_ID, -- RGH
                Gjhv.Period_Set_Name, -- RGH
                Gjhv.Accounted_Period_Type -- RGH
      HAVING Sum(Nvl(Gjl.Accounted_Dr, 0)) = 0 AND Sum(Nvl(Gjl.Accounted_Dr, 0)) = 0;

    Rec_Headers Cur_Headers%ROWTYPE;

    ------------------------------------------
    -- Curseur de lecture des lignes nulles --
    ------------------------------------------
    CURSOR Cur_Lines(Pn_Je_Batch_Id NUMBER) IS
      SELECT Gjh.Name,
             Gjh.Je_Header_Id,
             Gjl.Je_Line_Num,
             Gjl.Accounted_Dr,
             Gjl.Accounted_Cr
        FROM Gl_Je_Headers         Gjh,
             Gl_Je_Lines           Gjl,
             Gl_access_sets        Glas, -- RGH
             Gl_ACCESS_SET_LEDGERS Glasl -- RGH
       WHERE Gjh.Je_Batch_Id = Pn_Je_Batch_Id
            -- AND    Gjh.Set_Of_Books_Id  = Gn_Set_Of_Books_Id -- RGH
         AND Glasl.access_set_id = Glas.access_set_id -- RGH
         AND Gjh.Ledger_Id = Glasl.Ledger_Id -- RGH
         AND Glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND Gjh.Je_Header_Id = Gjl.Je_Header_Id
         AND Nvl(Gjl.Accounted_Dr, 0) = 0
         AND Nvl(Gjl.Accounted_Cr, 0) = 0;

    Rec_Lines Cur_Lines%ROWTYPE;

    Vn_Indice        NUMBER;
    Vv_Row_Id        Gl_Je_Batches_v.Row_Id%TYPE;
    Vn_Je_Batch_Id   Gl_Je_Batches_v.Je_Batch_Id%TYPE;
    Vv_Je_Batch_Name Gl_Je_Batches_v.Name%TYPE;
    Vn_Debit         Gl_Je_Batches_v.Running_Total_Accounted_Dr%TYPE;
    Vn_Credit        Gl_Je_Batches_v.Running_Total_Accounted_Cr%TYPE;
    Vn_Row_Id        Gl_Je_Lines_v.Row_Id%TYPE;
    -- Vn_Wad_Row_Id                Gl_Je_Lines_v.Wad_Row_Id%TYPE; -- RGH
    Vn_Wad_Row_Id GL_JE_LINES_RECON_v.Row_Id%TYPE; -- RGH
    vn_step          NUMBER := 0;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Verification_Lots (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de lot à vérifier');
    ELSE
      -------------------------------
      -- Controle des lots générés --
      -------------------------------
      FOR Vn_Indice IN 1 .. Gn_Nb_Traitements_Glprje LOOP
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.put_outdebug_message('=> Gt_Request_Id(' || Vn_Indice ||').Recurring_Batch_Id : ' || Gt_Request_Id(Vn_Indice).Recurring_Batch_Id);
        -- Dka_Tools_Pkg.Put_Debug_Message('=> Gn_Set_Of_Books_Id  : ' || Gn_Set_Of_Books_Id); --RGH
        Dka_Tools_Pkg.put_outdebug_message('=> Gn_ACCESS_SET_ID  : ' || Gn_ACCESS_SET_ID); --RGH
        Dka_Tools_Pkg.put_outdebug_message('=> Gv_Period_Name    : ' || Gv_Period_Name);

        IF Gt_Request_Id(Vn_Indice).Traitement_Ok = 'OK' THEN
          --------------------------------------------------------------------------------------
          -- Si le traitement de génération des pièces répétitives s'est correctement terminé --
          --------------------------------------------------------------------------------------
          BEGIN
            SELECT Gjb.RowId,
                   Gjb.Je_Batch_Id,
                   Gjb.Name,
                   Sum(Nvl(Gjl.Accounted_Dr, 0)),
                   Sum(Nvl(Gjl.Accounted_Cr, 0))
              INTO Vv_Row_Id,
                   Vn_Je_Batch_Id,
                   Vv_Je_Batch_Name,
                   Vn_Debit,
                   Vn_Credit
              FROM -- Gl_Je_Batches_v   Gjbv,  -- RGH
                   Gl_Je_Batches         Gjb, -- RGH
                   Gl_Je_Headers         Gjh,
                   Gl_Je_Lines           Gjl,
                   Gl_Recurring_Batches  Grb,
                   Gl_access_sets        Glas, -- RGH
                   Gl_ACCESS_SET_LEDGERS Glasl -- RGH
             WHERE 1 = 1
               AND Grb.Recurring_Batch_Id = Gt_Request_Id(Vn_Indice).Recurring_Batch_Id
              /*
               AND    Grb.Set_Of_Books_Id                            = Gn_Set_Of_Books_Id
               AND    Substr(Gjbv.Name, 1, Instr(Gjbv.Name, ':') - 1) = Grb.Name
               AND    Gjbv.Default_Period_Name                        = Gv_Period_Name
               AND    Gjbv.Status                                     = 'U'
               AND    Gjbv.Set_Of_Books_Id                            = Gn_Set_Of_Books_Id
               AND    Gjbv.Je_Source_Name                             = 'Recurring'
               AND    Gjbv.Je_Batch_Id                                = Gjh.Je_Batch_Id */ -- RGH
               AND Gjh.Je_Header_Id                                = Gjl.Je_Header_Id(+)   --YWA artf2188071
               AND Glasl.access_set_id = Glas.access_set_id -- RGH
               AND Glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
               AND Grb.Ledger_Id = Glasl.Ledger_Id -- RGH
               AND Gjh.Ledger_Id = Gjl.Ledger_Id -- RGH
               AND Substr(Gjb.Name, 1, Instr(Gjb.Name, ':') - 1) = Grb.Name -- RGH
               AND Gjb.Default_Period_Name = Gv_Period_Name -- RGH
               AND Gjb.Status = 'U' -- RGH
               AND Gjh.Je_Source = 'Recurring' -- RGH
               AND Gjb.Je_Batch_Id = Gjh.Je_Batch_Id -- RGH
             GROUP BY Gjb.RowId, Gjb.Je_Batch_Id, Gjb.Name;

            Dka_Tools_Pkg.Put_Outdebug_Message('=> Controle du lot : ' || Vv_Je_Batch_Name ||    ' (Je_Batch_Id : ' ||    Vn_Je_Batch_Id || ')');
            Dka_Tools_Pkg.Put_Outdebug_Message('             Débit : ' ||  Vn_Debit || ' - ' || 'Crédit : ' || Vn_Credit);

            vn_step := 1;

            IF Vn_Debit = 0 AND Vn_Credit = 0 THEN
              ------------------------------
              -- Suppression des lots à 0 --
              ------------------------------
              vn_step := 2;

              Dka_Tools_Pkg.Put_Outdebug_Message('   ==> Le lot ' ||  Vv_Je_Batch_Name ||  ' est nul');
              Dka_Tools_Pkg.put_outdebug_message('       ==> Suppression du lot : ' ||    Vv_Je_Batch_Name);
              Gl_Je_Batches_Pkg.Delete_Row(Vv_Row_Id, Vn_Je_Batch_Id);
              Dka_Tools_Pkg.Put_Outdebug_Message('       ==> Lot : ' ||   Vv_Je_Batch_Name ||' supprimé');

              vn_step := 3;

            ELSE

              vn_step := 4;
              --------------------------------
              -- Suppression des pièces à 0 --
              --------------------------------
              FOR Rec_Headers IN Cur_Headers(Vn_Je_Batch_Id) LOOP
              --OPEN Cur_Headers(Vn_Je_Batch_Id);
              --LOOP
              --  FETCH Cur_Headers
              --    INTO Rec_Headers;
              --  EXIT WHEN Cur_Headers%NOTFOUND;

                Dka_Tools_Pkg.Put_Outdebug_Message('   ==> La pièce : ' ||
                                                   Rec_Headers.Name ||
                                                   ' (Je_Header_Id : ' ||
                                                   Rec_Headers.Je_Header_Id ||
                                                   ') est nulle');
                Dka_Tools_Pkg.Put_Debug_Message('       ==> Suppression de la pièce : ' ||
                                                Rec_Headers.Name);

                vn_step := 5;

                -- RGH : remplacer X_Set_Of_Books_Id par X_Ledger_Id
                -- RGH : Ajouter les params : X_Chart_of_Accounts_ID, X_Period_Set_Name, X_Accounted_Period_Type
                -- RGH : Enlever le param X_Org_Id
                Gl_Je_Headers_Pkg.Delete_Row(X_Rowid                        => Rec_Headers.Row_Id,
                                             X_Je_Header_Id                 => Rec_Headers.Je_Header_Id,
                                             X_Header_Mode                  => 'Y',
                                             X_Batch_Row_Id                 => Rec_Headers.Batch_Rowid,
                                             X_Je_Batch_Id                  => Rec_Headers.Je_Batch_Id,
                                             X_Ledger_Id                    => Rec_Headers.Ledger_Id,
                                             X_Actual_Flag                  => Rec_Headers.Actual_Flag,
                                             X_Period_Name                  => Rec_Headers.Period_Name,
                                             X_Batch_Name                   => Rec_Headers.Batch_Name,
                                             X_Chart_of_Accounts_ID         => Rec_Headers.Chart_of_Accounts_ID,
                                             X_Period_Set_Name              => Rec_Headers.Period_Set_Name,
                                             X_Accounted_Period_Type        => Rec_Headers.Accounted_Period_Type,
                                             X_Batch_Status                 => Rec_Headers.Batch_Status,
                                             X_Status_Verified              => Rec_Headers.Status_Verified,
                                             X_Batch_Default_Effective_Date => Rec_Headers.Batch_Default_Effective_Date,
                                             X_Batch_Posted_Date            => Rec_Headers.Batch_Posted_Date,
                                             X_Batch_Date_Created           => Rec_Headers.Batch_Date_Created,
                                             X_Budgetary_Control_Status     => Rec_Headers.Budgetary_Control_Status,
                                             X_Approval_Status_Code         => Rec_Headers.Approval_Status_Code,
                                             X_Batch_Control_Total          => Rec_Headers.Batch_Control_Total,
                                             X_Batch_Running_Total_Dr       => Rec_Headers.Batch_Running_Total_Dr,
                                             X_Batch_Running_Total_Cr       => Rec_Headers.Batch_Running_Total_Cr,
                                             X_Average_Journal_Flag         => Rec_Headers.Average_Journal_Flag,
                                             X_Posting_Run_Id               => Rec_Headers.Posting_Run_Id,
                                             X_Request_Id                   => Rec_Headers.Request_Id,
                                             X_Packet_Id                    => Rec_Headers.Packet_Id,
                                             X_Unreservation_Packet_Id      => Rec_Headers.Unreservation_Packet_Id,
                                             X_Last_Updated_By              => Rec_Headers.Last_Updated_By,
                                             X_Last_Update_Login            => Rec_Headers.Last_Update_Login);

                Dka_Tools_Pkg.Put_Outdebug_Message('       ==> Pièce : ' ||  Rec_Headers.Name || ' supprimée');

                vn_step := 6;

              END LOOP;
              --CLOSE Cur_Headers;

              vn_step := 7;

              -------------------------------------------
              -- Suppression des lignes des pièces à 0 --
              -------------------------------------------
              FOR Rec_Lines IN Cur_Lines(Vn_Je_Batch_Id) LOOP
              --OPEN Cur_Lines(Vn_Je_Batch_Id);
              --LOOP
              --  FETCH Cur_Lines
              --    INTO Rec_Lines;
              --  EXIT WHEN Cur_Lines%NOTFOUND;

                vn_step := 8;

                Dka_Tools_Pkg.Put_Outdebug_Message('   ==> La ligne ' ||
                                                   Rec_Lines.Je_Line_Num ||
                                                   ' de La pièce : ' ||
                                                   Rec_Lines.Name ||
                                                   ' (Je_Header_Id : ' ||
                                                   Rec_Lines.Je_Header_Id ||
                                                   ') est nulle');

                BEGIN

                  vn_step := 9;

                  SELECT Gjlv.rowid, Gjlr.rowid
                    INTO Vn_Row_Id, Vn_Wad_Row_Id
                    FROM Gl_Je_Lines           Gjlv, -- RGH
                         GL_JE_LINES_RECON     Gjlr, -- RGH
                         Gl_access_sets        Glas, -- RGH
                         Gl_ACCESS_SET_LEDGERS Glasl -- RGH
                   WHERE Gjlv.Je_Header_Id = Rec_Lines.Je_Header_Id
                     AND Gjlv.Je_Line_Num = Rec_Lines.Je_Line_Num
                        -- AND    Gjlv.Set_Of_Books_Id = Gn_Set_Of_Books_Id; -- RGH
                     AND Glasl.access_set_id = Glas.access_set_id -- RGH
                     AND Glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
                     AND Gjlv.LEDGER_Id = Glasl.Ledger_Id -- RGH
                     AND Gjlv.JE_HEADER_ID = Gjlr.JE_HEADER_ID
                     AND Gjlv.je_line_num = Gjlr.je_line_num
                     AND Gjlv.LEDGER_ID = Gjlr.LEDGER_ID;

                  vn_step := 10;

                  Dka_Tools_Pkg.put_outdebug_message('       ==> Suppression de la ligne : ' || Rec_Lines.Je_Line_Num);

                  Gl_Je_Lines_Pkg.Delete_Row(Vn_Row_Id, Vn_Wad_Row_Id);

                  vn_step := 11;

                  Dka_Tools_Pkg.Put_Outdebug_Message('       ==> Ligne : ' || Rec_Lines.Je_Line_Num ||' supprimée');

                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;

                END;

              END LOOP;

              vn_step := 12;

              --CLOSE Cur_Lines;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              Pv_Errbuf  := 'Erreur dans la procécure Verification_Lots : Plusieurs lots non imputés ont été générés pour le lot : ' ||
                            Gt_Request_Id(Vn_Indice).Recurring_Batch_Name;
              Pn_Retcode := 2;
              Dka_Tools_Pkg.Put_Outdebug_Message('Step: ' || vn_step || ' // ' || SQLERRM);
              Dka_Tools_Pkg.Put_Outdebug_Message('=> Traitement ' ||
                                                 Gt_Request_Id(Vn_Indice)
                                                 .Request_Id ||
                                                 ' terminé normalement');
              Dka_Tools_Pkg.Put_Outdebug_Message('==> Plusieurs lots non imputés ont été générés pour le lot : ' ||
                                                 Gt_Request_Id(Vn_Indice)
                                                 .Recurring_Batch_Name);
          END;
        ELSE
          ---------------------------------------------------
          -- Les pièces répétitives n'ont pas été générées --
          ---------------------------------------------------
          Dka_Tools_Pkg.Put_Outdebug_Message('=> Traitement ' ||
                                             Gt_Request_Id(Vn_Indice)
                                             .Request_Id ||
                                             ' terminé en erreur');
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de pièce générée pour le lot : ' ||
                                             Gt_Request_Id(Vn_Indice)
                                             .Recurring_Batch_Name);
        END IF;
      END LOOP;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Verification_Lots (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Verification_Lots : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Verification_Lots (-)');

  END Verification_Lots;

  -- -----------------------------------------------------------------------------
  -- Nom              : Lancement_Autoimputation
  -- Description      : Procédure de lancement du traitement d'autoimputation.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Lancement_Autoimputation(Pv_Errbuf  OUT VARCHAR2,
                                     Pn_Retcode OUT NUMBER) IS

    Vv_Errbuf           VARCHAR2(2500);
    Vn_Retcode          NUMBER;
    Vn_Request_Id       NUMBER;
    Vn_Indice_Parametre NUMBER;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Lancement_Autoimputation (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de lancement du traitement d''Auto-Imputation');
    ELSE
      ----------------------------------
      -- Renseignement des paramètres --
      ----------------------------------
      FOR Vn_Indice_Parametre IN 1 .. 100 LOOP
        Dka_Tools_Pkg.Tab_Request_Params(Vn_Indice_Parametre) := Chr(0);
      END LOOP;
      --Dka_Tools_Pkg.Tab_Request_Params(1) := Gn_Set_Of_Books_Id; --RGH
      Dka_Tools_Pkg.Tab_Request_Params(1) := Gn_ACCESS_SET_ID; --RGH
      Dka_Tools_Pkg.Tab_Request_Params(2) := Gn_Autopost_Set_Id;

      ------------------------------
      -- Soumission du traitement --
      ------------------------------
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Soumission du traitement ''Programme - Imputation automatique''');
      Soumission_Traitement(Gv_App_Short_Name_Glpautop,
                            Gv_Program_Name_Glpautop,
                            Vn_Request_Id,
                            Vv_Errbuf,
                            Vn_Retcode);

      IF Vn_Retcode = 0 THEN
        Gn_Request_Id_Glpautop := Vn_Request_Id;
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Traitement lancé sous le numéro : ' ||
                                           Gn_Request_Id_Glpautop);
        Dka_Tools_Pkg.Put_Debug_Message('    Avec les paramètres :');
        Dka_Tools_Pkg.Put_Debug_Message('    => Entité comptable      : ' ||
                                        Dka_Tools_Pkg.Tab_Request_Params(1));
        Dka_Tools_Pkg.Put_Debug_Message('    => Jeu d''auto-imputation : ' ||
                                        Dka_Tools_Pkg.Tab_Request_Params(2));
      ELSE
        Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Errbuf);
        Pv_Errbuf  := 'Erreur dans la procécure Lancement_Autoimputation';
        Pn_Retcode := 2;
      END IF;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Lancement_Autoimputation (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Lancement_Autoimputation : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Lancement_Autoimputation (-)');

  END Lancement_Autoimputation;

  -- -----------------------------------------------------------------------------
  -- Nom              : Attente_Fin_Trait_Glpautop
  -- Description      : Procédure d'attente du traitement d'auto-imputation.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Attente_Fin_Trait_Glpautop(Pv_Errbuf  OUT VARCHAR2,
                                       Pn_Retcode OUT NUMBER) IS

    Vn_Interval   NUMBER := 10;
    Vn_Max_Wait   NUMBER := 0;
    Vv_Phase      VARCHAR2(80);
    Vv_Status     VARCHAR2(80);
    Vv_Dev_Phase  VARCHAR2(30);
    Vv_Dev_Status VARCHAR2(30);
    Vv_Message    VARCHAR2(240);

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glpautop (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement d''Auto-Imputation n''a pas été lancé');
    ELSE
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Attente de la fin du traitement d''Auto-Imputation');

      IF NOT Fnd_Concurrent.Wait_For_Request(Gn_Request_Id_Glpautop,
                                             Vn_Interval,
                                             Vn_Max_Wait,
                                             Vv_Phase,
                                             Vv_Status,
                                             Vv_Dev_Phase,
                                             Vv_Dev_Status,
                                             Vv_Message) THEN
        Pv_Errbuf  := Vv_Message;
        Pn_Retcode := 2;
        Dka_Tools_Pkg.Put_Debug_Message(Vv_Message);
      ELSE
        IF Vv_Dev_Status = 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glpautop ||
                                             ' s''est terminé normalement');
        ELSIF Vv_Dev_Status = 'WARNING' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glpautop ||
                                             ' s''est terminé en warning');
        ELSIF Vv_Dev_Status != 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glpautop ||
                                             ' s''est terminé en erreur');
        END IF;
      END IF;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glpautop (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Attente_Fin_Trait_Glpautop : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glpautop (-)');

  END Attente_Fin_Trait_Glpautop;

  -- -----------------------------------------------------------------------------
  -- Nom              : Attente_Fin_Trait_Glppos
  -- Description      : Procédure d'attente du traitement d'auto-imputation.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Attente_Fin_Trait_Glppos(Pv_Errbuf  OUT VARCHAR2,
                                     Pn_Retcode OUT NUMBER) IS

    Vn_Interval   NUMBER := 10;
    Vn_Max_Wait   NUMBER := 0;
    Vv_Phase      VARCHAR2(80);
    Vv_Status     VARCHAR2(80);
    Vv_Dev_Phase  VARCHAR2(30);
    Vv_Dev_Status VARCHAR2(30);
    Vv_Message    VARCHAR2(240);

    Warning_Attente_Glppos EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glppos (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de lancement du traitement de Posting');
    ELSE
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Attente de la fin du Posting');

      ----------------------------------------------------------
      -- Recherche du numéro de traitement lancé par GLPAUTOP --
      ----------------------------------------------------------
      -- 07/03/2019 MTIA artf07217339 : SPE108 - Recherche des traitements de posting (deux noms courts)
      BEGIN
        SELECT Fcrsv.Request_Id
          INTO Gn_Request_Id_Glppos
          FROM Fnd_Conc_Req_Summary_v Fcrsv
         WHERE Fcrsv.Parent_Request_Id = Gn_Request_Id_Glpautop
           AND Fcrsv.Program_Short_Name in (Gv_Program_Name_Glppos,Gv_Program_Name_Glpposs) ;

      EXCEPTION
        WHEN No_Data_Found THEN
          RAISE Warning_Attente_Glppos;
      END;

      IF NOT Fnd_Concurrent.Wait_For_Request(Gn_Request_Id_Glppos,
                                             Vn_Interval,
                                             Vn_Max_Wait,
                                             Vv_Phase,
                                             Vv_Status,
                                             Vv_Dev_Phase,
                                             Vv_Dev_Status,
                                             Vv_Message) THEN
        Pv_Errbuf  := Vv_Message;
        Pn_Retcode := 2;
        Dka_Tools_Pkg.Put_Debug_Message(Vv_Message);
      ELSE
        IF Vv_Dev_Status = 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glppos ||
                                             ' s''est terminé normalement');
        ELSIF Vv_Dev_Status = 'WARNING' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glppos ||
                                             ' s''est terminé en warning');
        ELSIF Vv_Dev_Status != 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Gn_Request_Id_Glppos ||
                                             ' s''est terminé en erreur');
        END IF;
      END IF;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glppos (-)');

  EXCEPTION
    WHEN Warning_Attente_Glppos THEN
      Pv_Errbuf  := 'Le ''Posting'' n''a pas été lancé';
      Pn_Retcode := 1;
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le ''Posting'' n''a pas été lancé');
      Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glppos (-)');
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Attente_Fin_Trait_Glppos : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Glppos (-)');

  END Attente_Fin_Trait_Glppos;

  -- -----------------------------------------------------------------------------
  -- Nom              : Mise_A_Jour_Cuf
  -- Description      : Procédure d'attente du traitement d'auto-imputation.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Mise_a_Jour_Cuf(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER) IS

    --------------------------------------------
    -- Curseur de lecture des pièces d'un lot --
    --------------------------------------------
    CURSOR Cur_Pieces(Pn_Recurring_Batch_Id NUMBER) IS
      SELECT Grh.Name                Nom_Piece,
             Grh.Recurring_Header_Id Recurring_Header_Id
        FROM Gl_Recurring_Headers_v Grh,
             --Gl_Period_Statuses     Gps, --RGH
             gl_periods     gp, -- RGH
             gl_access_sets glas -- RGH

       WHERE 1 = 1
         AND Grh.Recurring_Batch_Id = Pn_Recurring_Batch_Id
            -- AND    Grh.User_Je_Category_Name                   = 'ABONNEMENTS'                    Modif EMA du 29/03/2007
         AND EXISTS
       (SELECT 'X' -- Modif EMA du 29/03/2007
                FROM Fnd_Flex_Value_Sets Ffvs, -- Modif EMA du 29/03/2007
                     Fnd_Flex_Values     Ffv -- Modif EMA du 29/03/2007
               WHERE Ffvs.Flex_Value_Set_Name = Gv_Jeu_De_Valeurs -- Modif EMA du 29/03/2007
                 AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id -- Modif EMA du 29/03/2007
                 AND Ffv.Flex_Value = Grh.User_Je_Category_Name -- Modif EMA du 29/03/2007
                 AND Ffv.Enabled_Flag = 'Y' -- Modif EMA du 29/03/2007
                 AND Trunc(SYSDATE) BETWEEN
                     Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) -- Modif EMA du 29/03/2007
                     AND Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))) -- Modif EMA du 29/03/2007
            /*
                                        AND Gps.Application_Id = 101
                                        AND Gps.Set_Of_Books_Id = Gn_Set_Of_Books_Id
                                        AND Gps.Period_Name = Gv_Period_Name
                                        AND Nvl(Grh.Start_Date_Active, Gps.Start_Date) <= Gps.Start_Date
                                        AND Nvl(Grh.End_Date_Active, Gps.End_Date) >= Gps.End_Date
                                        */ -- RGH
         AND glas.access_set_id = Gn_ACCESS_SET_ID -- RGH
         AND glas.period_set_name = gp.period_set_name -- RGH
         AND Gp.period_name = Gv_Period_Name -- RGH
         AND Nvl(Grh.Start_Date_Active, Gp.Start_Date) <= Gp.Start_Date -- RGH
         AND Nvl(Grh.End_Date_Active, Gp.End_Date) >= Gp.End_Date; -- RGH

    Rec_Pieces Cur_Pieces%ROWTYPE;

    Vb_Mise_a_Jour BOOLEAN;
    Vn_Indice      NUMBER;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Mise_A_Jour_Cuf (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    IF Gn_Nb_Traitements_Glprje = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Il n''y a pas de pièces répétitives générées');
      Dka_Tools_Pkg.Put_Outdebug_Message('==> Pas de CUF à mettre à jour');
    ELSE
      -----------------------------------
      -- Boucle de mise à jour des CUF --
      -----------------------------------
      Vb_Mise_a_Jour := TRUE;
      FOR Vn_Indice IN 1 .. Gn_Nb_Traitements_Glprje LOOP
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Mise à jour des CUF du lot : ' ||
                                           Gt_Request_Id(Vn_Indice)
                                           .Recurring_Batch_Name);

        OPEN Cur_Pieces(Gt_Request_Id(Vn_Indice).Recurring_Batch_Id);
        LOOP
          FETCH Cur_Pieces
            INTO Rec_Pieces;
          EXIT WHEN Cur_Pieces%NOTFOUND;

          Dka_Tools_Pkg.Put_Debug_Message('==> Mise à jour du CUF de la pièce : ' ||
                                          Rec_Pieces.Nom_Piece);
          Dka_Tools_Pkg.Put_Debug_Message('    Recurring_Header_Id                    : ' ||
                                          Rec_Pieces.Recurring_Header_Id);
          -- Dka_Tools_Pkg.Put_Debug_Message('    Gn_Set_Of_Books_Id                     : ' ||  Gn_Set_Of_Books_Id); -- RGH
          Dka_Tools_Pkg.Put_Debug_Message('    Gn_ACCESS_SET_ID                     : ' ||
                                          Gn_ACCESS_SET_ID); -- RGH
          Dka_Tools_Pkg.Put_Debug_Message('    Gt_Request_Id(Vn_Indice).Traitement_Ok : ' ||
                                          Gt_Request_Id(Vn_Indice)
                                          .Traitement_Ok);

          BEGIN
            UPDATE Gl_Recurring_Headers Grh
               SET Grh.Attribute1 = 0
             WHERE Grh.Recurring_Header_Id = Rec_Pieces.Recurring_Header_Id
                  --AND Grh.Set_Of_Books_Id                    = Gn_Set_Of_Books_Id  -- RGH
               AND Gt_Request_Id(Vn_Indice).Traitement_Ok = 'OK';

            IF SQL%ROWCOUNT = 1 THEN
              Dka_Tools_Pkg.Put_Debug_Message('==> Le CUF a été mis à jour');
            ELSE
              Pv_Errbuf  := 'Le CUF de la pièce ' || Rec_Pieces.Nom_Piece ||
                            ' n''a pas été mise à jour';
              Pn_Retcode := 1;
              Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Pv_Errbuf);
              Vb_Mise_a_Jour := FALSE;
            END IF;
          END;
        END LOOP;
        CLOSE Cur_Pieces;
      END LOOP;

      IF Vb_Mise_a_Jour THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Toutes les CUF ont été mis à jour');
      ELSE
        Pv_Errbuf  := 'Il existe des CUF non mis à jour';
        Pn_Retcode := 1;
      END IF;
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Mise_A_Jour_Cuf (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Mise_A_Jour_Cuf : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Mise_A_Jour_Cuf (-)');

  END Mise_a_Jour_Cuf;

  -- -----------------------------------------------------------------------------
  -- Nom              : Desactivation_Triggers
  -- Description      : Procédure d'attente du traitement d'auto-imputation.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Desactivation_Triggers(Pv_Errbuf  OUT VARCHAR2,
                                   Pn_Retcode OUT NUMBER) IS

    Vv_Status         User_Triggers.Status%TYPE;
    Vv_Commande       VARCHAR2(250);
    Vv_Message_Erreur VARCHAR2(250);

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Desactivation_Triggers (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    -------------------------------------------------
    -- Désactivation du trigger DKA_JE_HEADERS_BIR --
    -------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Désactivation du trigger ' ||
                                       Gv_Trigger_Headers_Name);
    Vv_Commande := 'ALTER TRIGGER ' || Gv_Trigger_Headers_Name ||
                   ' DISABLE';
    EXECUTE IMMEDIATE Vv_Commande;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la désactivation du trigger ' ||
                           Gv_Trigger_Headers_Name;
      SELECT Ut.Status
        INTO Vv_Status
        FROM User_Triggers Ut
       WHERE Ut.Trigger_Name = Gv_Trigger_Headers_Name
         AND Ut.Status = 'DISABLED';

      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le trigger ' ||
                                         Gv_Trigger_Headers_Name ||
                                         ' est désactivé');

    END;

    ------------------------------------------------
    -- Désactivation du trigger DKA_JE_LINES_BIR2 --
    ------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Désactivation du trigger ' ||
                                       Gv_Trigger_Lines_Name);
    Vv_Commande := 'ALTER TRIGGER ' || Gv_Trigger_Lines_Name || ' DISABLE';
    EXECUTE IMMEDIATE Vv_Commande;

    BEGIN
      Vv_Message_Erreur := 'Erreur lors de la désactivation du trigger ' ||
                           Gv_Trigger_Lines_Name;
      SELECT Ut.Status
        INTO Vv_Status
        FROM User_Triggers Ut
       WHERE Ut.Trigger_Name = Gv_Trigger_Lines_Name
         AND Ut.Status = 'DISABLED';

      Dka_Tools_Pkg.Put_Outdebug_Message('==> Le trigger ' ||
                                         Gv_Trigger_Lines_Name ||
                                         ' est désactivé');

    END;

    Dka_Tools_Pkg.Put_Debug_Message('Desactivation_Triggers (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Outdebug_Message('==> ' || Vv_Message_Erreur);
      Pv_Errbuf  := 'Erreur dans la procécure Desactivation_Triggers : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Desactivation_Triggers (-)');

  END Desactivation_Triggers;

  -- -----------------------------------------------------------------------------
  -- Nom              : Compte_Rendu
  -- Description      : Edition du compte-rendu des anomalies pour un centre de
  --                    gestion.
  --
  -- PARAMETRES       : Pv_Centre_Gestion  Entrée        Centre de Gestion
  --                    Pv_Errbuf                 Sortie Message d'erreur
  --                    Pn_Retcode                Sortie Code Retour de la procédure
  --                                                     '0' : Normal
  --                                                     '1' : Avertissement
  --                                                     '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Compte_Rendu(Pv_Errbuf         OUT VARCHAR2,
                         Pn_Retcode        OUT NUMBER,
                         Pv_Centre_Gestion IN VARCHAR2) IS

    ----------------------------------------------------------------------
    -- Curseur de lecture des anomalies des lots d'un centre de gestion --
    ----------------------------------------------------------------------
    CURSOR Cur_Erreur(Pv_Centre_Gestion VARCHAR2) IS
      SELECT *
        FROM Dka_Sglabonnement_Err
       WHERE Centre_Gestion = Pv_Centre_Gestion
       ORDER BY Centre_Gestion, Societe, Creation_Date;

    Rec_Erreur Cur_Erreur%ROWTYPE;

    Vv_Old_Lot    Dka_Sglabonnement_Err.Nom_Lot%TYPE := '#### ###';
    Vn_Nb_Erreurs NUMBER := 0;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Compte_Rendu (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('Le ' ||
                                       To_Char(SYSDATE,
                                               'DD/MM/YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('Liste des abonnements en anomalie pour le centre de gestion : ' ||
                                       Pv_Centre_Gestion);
    Dka_Tools_Pkg.Put_Outdebug_Message('=================================================================');

    --------------------------------------------------------
    -- Boucle de lecture des erreurs du centre de gestion --
    --------------------------------------------------------
    OPEN Cur_Erreur(Pv_Centre_Gestion);
    LOOP
      FETCH Cur_Erreur
        INTO Rec_Erreur;
      EXIT WHEN Cur_Erreur%NOTFOUND;

      ----------------------------------
      -- Si rupture sur le nom du lot --
      ----------------------------------
      IF Vv_Old_Lot != Rec_Erreur.Nom_Lot THEN
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('Lot ' || Rec_Erreur.Nom_Lot ||
                                           ' non traité en raison des anomalies suivantes : ');
      END IF;
      Dka_Tools_Pkg.Put_Outdebug_Message('=> ' || Rec_Erreur.Message);

      Vv_Old_Lot    := Rec_Erreur.Nom_Lot;
      Vn_Nb_Erreurs := Vn_Nb_Erreurs + 1;

    END LOOP;
    CLOSE Cur_Erreur;

    IF Vn_Nb_Erreurs = 0 THEN
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Pas d''anomalie pour l''ensemble des lots du centre de gestion !!');
      -- Début modif EMA du 17/09/2009
      -- En cas de présence d'anomalie dans le compte-rendu, le traitement se termine en "Avertissement"
    ELSE
      Pv_Errbuf  := 'Il existe des abonnements en anomalie pour le centre de gestion : ' ||
                    Pv_Centre_Gestion;
      Pn_Retcode := 1;
      -- Fin modif EMA du 17/09/2009
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Compte_Rendu (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Compte_Rendu : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Compte_Rendu (-)');

  END Compte_Rendu;

  -- -----------------------------------------------------------------------------
  -- Nom              : Edition_Compte_Rendu
  -- Description      : Lancement de l'édition des compte-rendus par tous les
  --                    centres de gestion.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Edition_Compte_Rendu(Pv_Errbuf  OUT VARCHAR2,
                                 Pn_Retcode OUT NUMBER) IS

    -----------------------------------------------
    -- Curseur de lecture des centres de gestion --
    -----------------------------------------------
    CURSOR Cur_Cdg IS
      SELECT Ffv.Flex_Value Centre_Gestion
        FROM Fnd_Flex_Value_Sets Ffvs, Fnd_Flex_Values Ffv
       WHERE Ffvs.Flex_Value_Set_Name = 'DKA_CENTRES_DE_GESTION'
         AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id
       ORDER BY Ffv.Flex_Value;

    Rec_Cdg Cur_Cdg%ROWTYPE;

    Vn_User_Id          Fnd_User.User_Id%TYPE;
    Vv_Printer          Fnd_Printer.Printer_Name%TYPE;
    Vn_Copies           NUMBER;
    Vv_Errbuf           VARCHAR2(2500);
    Vn_Retcode          NUMBER;
    Vn_Request_Id       NUMBER;
    Vn_Indice_Parametre NUMBER;
    Vt_Request_Id       Mytable;
    Vn_Nombre_Trt       NUMBER := 0;
    Vn_Indice           NUMBER := 0;
    Vn_Interval         NUMBER := 10;
    Vn_Max_Wait         NUMBER := 0;
    Vv_Phase            VARCHAR2(80);
    Vv_Status           VARCHAR2(80);
    Vv_Dev_Phase        VARCHAR2(30);
    Vv_Dev_Status       VARCHAR2(30);
    Vv_Message          VARCHAR2(240);
    Vb_Trait_Ok         BOOLEAN;

  BEGIN

    Dka_Tools_Pkg.Put_Debug_Message('Edition_Compte_Rendu (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    ---------------------------------------------------------
    -- Boucle de lecture pour lancement des conmpte-rendus --
    ---------------------------------------------------------
    OPEN Cur_Cdg;
    LOOP
      FETCH Cur_Cdg
        INTO Rec_Cdg;
      EXIT WHEN Cur_Cdg%NOTFOUND;

      -----------------------------------------------------------
      -- Recherche du User_Id de l'utilisateur CentreDeGestion --
      -----------------------------------------------------------
      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('=> Connexion de l''utilisateur : ' ||
                                      Rec_Cdg.Centre_Gestion);
      BEGIN
        SELECT Fu.User_Id
          INTO Vn_User_Id
          FROM Fnd_User Fu
         WHERE Fu.User_Name = Rec_Cdg.Centre_Gestion;

      EXCEPTION
        WHEN OTHERS THEN
          ------------------------------------------------------------------------------
          -- Si l'utilisateur CentreDeGestion n'est pas connu, on prend le user qui a --
          -- lancé le traitement courant                                              --
          ------------------------------------------------------------------------------
          Vn_User_Id := Gn_User_Id;
      END;

      ---------------------------------------------------------
      -- Positionnement dans le contexte Oracle Applications --
      ---------------------------------------------------------
      Fnd_Global.Apps_Initialize(Vn_User_Id,
                                 Gn_Etats_Responsibility_Id,
                                 Gn_Etats_Application_Id);

      Dka_Tools_Pkg.Put_Debug_Message('==> Connexion établie pour ' ||
                                      Rec_Cdg.Centre_Gestion);

      ---------------------------------------
      -- Recherche de l'imprimante du user --
      ---------------------------------------
      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('=> Recherche de l''imprimante');
      Vv_Printer := Fnd_Profile.Value('PRINTER');
      Vn_Copies  := Gn_Copies;
      IF Vv_Printer IS NULL THEN
        Vv_Printer := 'noprint';
        Vn_Copies  := 0;
      END IF;
      Dka_Tools_Pkg.Put_Debug_Message('==> Imprimante : ' || Vv_Printer);

      --------------------------------------------
      -- Positionnement des options d'impession --
      --------------------------------------------
      Dka_Tools_Pkg.Put_Debug_Message(' ');
      Dka_Tools_Pkg.Put_Debug_Message('=> Positionnement des options d''impression');
      IF Fnd_Request.Set_Print_Options(Printer => Vv_Printer,
                                       Style   => 'LANDSCAPE',
                                       Copies  => Vn_Copies) THEN
        Dka_Tools_Pkg.Put_Debug_Message('==> Les options d''impression sont positionnées');
      ELSE
        Dka_Tools_Pkg.Put_Debug_Message('==> Impossible de positionner les options d''impression');
      END IF;

      ----------------------------------
      -- Renseignement des paramètres --
      ----------------------------------
      FOR Vn_Indice_Parametre IN 1 .. 100 LOOP
        Dka_Tools_Pkg.Tab_Request_Params(Vn_Indice_Parametre) := Chr(0);
      END LOOP;
      Dka_Tools_Pkg.Tab_Request_Params(1) := Rec_Cdg.Centre_Gestion;

      ------------------------------
      -- Soumission du traitement --
      ------------------------------
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Soumission du traitement d''édition du compte-rendu pour le centre de gestion : ' ||
                                         Rec_Cdg.Centre_Gestion);
      Soumission_Traitement(Gv_App_Short_Name_Cr,
                            Gv_Program_Name_Cr,
                            Vn_Request_Id,
                            Vv_Errbuf,
                            Vn_Retcode);

      IF Vn_Retcode = 0 THEN
        Vn_Nombre_Trt := Vn_Nombre_Trt + 1;
        Vt_request_Id(Vn_Nombre_Trt).Request_Id := Vn_Request_Id;
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Traitement lancé sous le numéro : ' ||
                                           Vn_Request_Id);
        Dka_Tools_Pkg.Put_Debug_Message('    Avec les paramètres :');
        Dka_Tools_Pkg.Put_Debug_Message('    => Centre de Gestion : ' ||
                                        Dka_Tools_Pkg.Tab_Request_Params(1));
      ELSE
        Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Errbuf);
        Pv_Errbuf  := 'Erreur dans la procécure Edition_Compte_Rendu';
        Pn_Retcode := 2;
      END IF;

    END LOOP;
    CLOSE Cur_Cdg;

    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    Vb_Trait_Ok := TRUE;
    FOR Vn_Indice IN 1 .. Vn_Nombre_Trt LOOP
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> Attente de la fin du traitement : ' ||
                                         Vt_Request_Id(Vn_Indice)
                                         .Request_Id);
      IF NOT Fnd_Concurrent.Wait_For_Request(Vt_Request_Id(Vn_Indice)
                                             .Request_Id,
                                             Vn_Interval,
                                             Vn_Max_Wait,
                                             Vv_Phase,
                                             Vv_Status,
                                             Vv_Dev_Phase,
                                             Vv_Dev_Status,
                                             Vv_Message) THEN
        Pv_Errbuf  := Vv_Message;
        Pn_Retcode := 2;
        Dka_Tools_Pkg.Put_Debug_Message(Vv_Message);
      ELSE
        IF Vv_Dev_Status = 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Vt_Request_Id(Vn_Indice)
                                             .Request_Id ||
                                             ' s''est terminé normalement');
        ELSIF Vv_Dev_Status = 'WARNING' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Vt_Request_Id(Vn_Indice)
                                             .Request_Id ||
                                             ' s''est terminé en warning');
          Vb_Trait_Ok := FALSE;
        ELSIF Vv_Dev_Status != 'NORMAL' THEN
          Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                             Vt_Request_Id(Vn_Indice)
                                             .Request_Id ||
                                             ' s''est terminé en erreur');
          Vb_Trait_Ok := FALSE;
        END IF;
      END IF;
    END LOOP;

    IF NOT Vb_Trait_Ok THEN
      Pv_Errbuf  := '==> Un ou plusieurs traitements se sont terminés en Warning ou en Erreur';
      Pn_Retcode := 1;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
    END IF;

    Dka_Tools_Pkg.Put_Debug_Message('Edition_Compte_Rendu (-)');

  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Edition_Compte_Rendu : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Edition_Compte_Rendu (-)');

  END Edition_Compte_Rendu;

  -- -----------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement qui enchaîne l'ensemble
  --                    des autres procédures.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Main(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER) IS

    Vv_Errbuf_Phase1   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase1  NUMBER := 0;
    Vv_Errbuf_Phase2   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase2  NUMBER := 0;
    Vv_Errbuf_Phase3   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase3  NUMBER := 0;
    Vv_Errbuf_Phase4   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase4  NUMBER := 0;
    Vv_Errbuf_Phase5   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase5  NUMBER := 0;
    Vv_Errbuf_Phase6   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase6  NUMBER := 0;
    Vv_Errbuf_Phase7   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase7  NUMBER := 0;
    Vv_Errbuf_Phase8   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase8  NUMBER := 0;
    Vv_Errbuf_Phase9   VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase9  NUMBER := 0;
    Vv_Errbuf_Phase10  VARCHAR2(2500) := NULL;
    Vn_Retcode_Phase10 NUMBER := 0;
    v_trigger BOOLEAN := FALSE;

  BEGIN
    Dka_Tools_Pkg.Put_Debug_Message('Main (+)');

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Execution du traitement');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    ------------------------------
    -- Phase 1 : Initialisation --
    ------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 1 : Initialisation');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Initialisation(Vv_Errbuf_Phase1, Vn_Retcode_Phase1);

    IF Vn_Retcode_Phase1 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase1;
      RAISE Erreur_Programme;
    END IF;

    -----------------------------------
    -- Phase 2 : traitement des lots --
    -----------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 2 : Traitement des lots');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Traitement_Lots(Vv_Errbuf_Phase2, Vn_Retcode_Phase2);

    IF Vn_Retcode_Phase2 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase2;
      RAISE Erreur_Programme;
    END IF;

    ----------------------------------------------------------------------------------------
    -- Phase 3 : Attente de la fin des traitement GLPRJE (Générer des pièces répétitives) --
    ----------------------------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 3 : Attente de la fin des traitements ''Pièce répétitive''');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Attente_Fin_Trait_Glprje(Vv_Errbuf_Phase3, Vn_Retcode_Phase3);

    IF Vn_Retcode_Phase3 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase3;
      RAISE Erreur_Programme;
    END IF;

    -----------------------------------------------------------------------------------
    -- Phase 4 : Vérification des lots (Suppression des lots, pièces ou lignes à 0) --
    -----------------------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 4 : Vérification des lots');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Verification_Lots(Vv_Errbuf_Phase4, Vn_Retcode_Phase4);

    IF Vn_Retcode_Phase4 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase4;
      RAISE Erreur_Programme;
    END IF;

    ------------------------------------------------------------------
    -- Phase 5 : Lancement du traitement GLPAUTOP (Auto-Imputation) --
    ------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 5 : Lancement du traitement d''auto-imputation');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Lancement_Autoimputation(Vv_Errbuf_Phase5, Vn_Retcode_Phase5);

    IF Vn_Retcode_Phase5 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase5;
      RAISE Erreur_Programme;
    END IF;

    --------------------------------------------------------
    -- Phase 6 : Attente de la fin du traitement GLPAUTOP --
    --------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 6 : Attente de la fin du traitement d''autoimputation');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Attente_Fin_Trait_Glpautop(Vv_Errbuf_Phase6, Vn_Retcode_Phase6);

    IF Vn_Retcode_Phase6 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase6;
      RAISE Erreur_Programme;
    END IF;

    ------------------------------------------------------------------------------------------
    -- Phase 7 : Attente de la fin du traitement GLPOS (Posting) qui est lancé par GLPAUTOP --
    ------------------------------------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 7 : Attente de la fin du posting');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Attente_Fin_Trait_Glppos(Vv_Errbuf_Phase7, Vn_Retcode_Phase7);

    IF Vn_Retcode_Phase7 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase7;
      RAISE Erreur_Programme;
    END IF;

    -------------------------------------------------------------
    -- Phase 8 : Mise à jour du CUF 'Nombre de mois à annuler' --
    -------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 8 : Mise à jour du CUF ''Définir pièce répétitive : Pièce''');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Mise_a_Jour_Cuf(Vv_Errbuf_Phase8, Vn_Retcode_Phase8);

    IF Vn_Retcode_Phase8 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase8;
      RAISE Erreur_Programme;
    END IF;

    ------------------------------------------
    -- Phase 9 : Désactivation des triggers --
    ------------------------------------------

    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 9 : Désactivation des triggers ' ||
                                       Gv_Trigger_Headers_Name || ' et ' ||
                                       Gv_Trigger_Lines_Name);
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Desactivation_Triggers(Vv_Errbuf_Phase9, Vn_Retcode_Phase9);

    IF Vn_Retcode_Phase9 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase9;
      RAISE Erreur_Programme;
    END IF;
    v_trigger := TRUE;--YWA artf2188071
    ----------------------------------------------------------------
    -- Phase 10 : Edition des compte-rendus par centre de gestion --
    ----------------------------------------------------------------
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Phase 10 : Edition des compte-rendus par centre de gestion');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

    Edition_Compte_Rendu(Vv_Errbuf_Phase10, Vn_Retcode_Phase10);

    IF Vn_Retcode_Phase10 = 2 THEN
      Pv_Errbuf := Vv_Errbuf_Phase10;
      RAISE Erreur_Programme;
    END IF;

    ------------------------------------------------------------------------
    -- Gestion des codes retour pour sortie en avertissement du programme --
    ------------------------------------------------------------------------
    IF Vn_Retcode_Phase1 = 1 OR Vn_Retcode_Phase2 = 1 OR
       Vn_Retcode_Phase3 = 1 OR Vn_Retcode_Phase4 = 1 OR
       Vn_Retcode_Phase5 = 1 OR Vn_Retcode_Phase6 = 1 OR
       Vn_Retcode_Phase7 = 1 OR Vn_Retcode_Phase8 = 1 OR
       Vn_Retcode_Phase9 = 1 OR Vn_Retcode_Phase10 = 1 THEN
      Pn_Retcode := 1;

      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN AVERTISSEMENT');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

      IF Vn_Retcode_Phase1 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase1;
      ELSIF Vn_Retcode_Phase2 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase2;
      ELSIF Vn_Retcode_Phase3 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase3;
      ELSIF Vn_Retcode_Phase4 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase4;
      ELSIF Vn_Retcode_Phase5 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase5;
      ELSIF Vn_Retcode_Phase6 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase6;
      ELSIF Vn_Retcode_Phase7 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase7;
      ELSIF Vn_Retcode_Phase8 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase8;
      ELSIF Vn_Retcode_Phase9 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase9;
      ELSIF Vn_Retcode_Phase10 = 1 THEN
        Pv_Errbuf := Vv_Errbuf_Phase10;
      END IF;

      Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
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
      --YWA artf2188071
      IF NOT v_trigger THEN
        ------------------------------------------
        --Erreur_Programme Désactivation des triggers --
        ------------------------------------------
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
        Dka_Tools_Pkg.Put_Outdebug_Message('=> Erreur_Programme ==> Désactivation des triggers ' ||
                                           Gv_Trigger_Headers_Name || ' et ' ||
                                           Gv_Trigger_Lines_Name);
        Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

        Desactivation_Triggers(Vv_Errbuf_Phase9, Vn_Retcode_Phase9);

        IF Vn_Retcode_Phase9 = 2 THEN
          Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Errbuf_Phase9);
        END IF;--YWA artf2188071

      END IF;

      Dka_Tools_Pkg.Put_Debug_Message('Main (-)');
    WHEN OTHERS THEN
      ROLLBACK;
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Pv_Errbuf  := 'Erreur dans la procécure Main : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Main (-)');

  END Main;

END Dka_Sglabonnement_Pkg;
/
SHOW ERRORS
EXIT
