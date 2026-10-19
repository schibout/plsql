CREATE OR REPLACE PACKAGE BODY DKA_SPOCUT_OFF_PKG AS
  --------------------------------------------------------------------------------
  -- $Id: DKA_SPOCUT_OFF_PKG.pkb 552 2008-02-08 15:56:47Z NORDEST\viknab $
  -- Capgemini
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOCUT_OFF_PKG.pkb
  -- DESCRIPTION       : Corps du package DKA_SPOCUT_OFF_PKG
  --
  -- AUTEUR            : T. BONDUAEUX
  -- DATE DE CRÉATION  : 25/09/2007
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Personne  Description
  -- ---------- --------- --------------------------------------------------------
  -- 07/11/2007 tbonduae  Correction des appels à dka_tools_pkg.get_parameter,
  --                      mise en commentaire des variables inutilisées, messages
  --                      d'erreurs plus précis.
  -- 12/11/2007 tbonduae  Si pas de CAP ou de CCA à traiter, alors n'exécute pas
  --                      EasyLink et sort en statut WARNING.
  -- 13/12/2007 vknab     Modification suite FT59
  -- 31/01/2008 tbonduae  ft#67 : dans le cas d¿une CAP, la TVA doit être au débit
  --                      et pas au crédit.
  -- 08/02/2008 vknab     Modification suite FT69.
  -- 20/03/2008 CDE       Modification suite FT71 : Modif calcul prorata temporis (division
  --                      par mois et non par jour)
  --                      + Correction suite FT70 : Modif calcul des montants ttc, ht et tvs
  -- 23/04/2008 CDE       Prise en compte du cas des contrats à date future et de ceux dont la date
  --                      d'échéance est dépassée
  -- 09/09/2009 SROL      Correction de la sélection des imputations des commandes liées à des contrats
  --                      de sous-traitance (dépendants ou indépendants) pour le calcul du cut-off associé.
  -- 12/02/2010 SROL      Changement du filtre de sélection des lignes de commandes à l'élection du CUTOFF pour y
  --                      inclure les commandes dont le statut de fermeture est à 'CLOSED'
  -- 18/02/2010 CDE       EID20090220 : Modification du calcul de la charge théorique pour prendre en compte
  --                      les modifications de montants à date d'effet
  -- 11/06/2010 CDE       EID20100127 : Ajout d'une description sur les écritures de CUT OFF
  -- 22/07/2010 CDE       Correction calcul du CUT OFF quand renouvellement
  -- 08/04/2011 EMA-CDE   EARS00009462976 - Recalcul du CCID pour prendre en compte les modifications d'appartenance
  --                      qui auraient éventuellement eu lieu sur le code D.
  -- 13/01/2012 EMA       DGE20110033 : Prise de compte de la date de résiliation dans le cas
  --                      où elle est renseignée.
  -- 27/02/2014 BCO       DPE20130084 : Modification du calcul des Chargers à payer pour les contrats de Sous-Traitance
  --                      en prestation unitaire
  -- 09/06/2017 RBE       Correction artf2170606 SPE119 - SPOCUTOFF - Automatisation en erreur - Defect Bout_En_Bout_Helios_Ref #751
  -- 24/07/2017 RBE       Correction artf2195248 : SPE119 - Traitement du CUTOFF - problèmes multiples
  -- 09/04/2018 JWYC      Correction artf2512537 : Correction de la récupération du code interco
  -- 10/04/2019 AAM       artf07231300 - SPE119 Modification du champ GLI_CURRENCY_CODE
  -- 09/10/2019 OCL       EDB240 - Calcul des provisions SSTR multi sociétés
  -- 10/08/2020 JWY      INC0451603 - Retrait de l'avertissement s'il n'y a pas de données traitées
  -- 08/02/2021 JWY       artf07439823 INC0509419 - SPE119 - Ajout exception dans le calcul de la charge SSTR (division par 0)
  --------------------------------------------------------------------------------

  /* Constantes */
  APP_ID                    CONSTANT gl_period_statuses.application_id%TYPE := 101;
  APP_NAME                  CONSTANT VARCHAR2(50) := 'SPOCUT_OFF';
  TRANSCO_CTX               CONSTANT VARCHAR2(150) := 'MIGR_GROUP_ACCOUNT_CLASS_BILAN';
  GLI_USER_JE_SOURCE_NAME   CONSTANT gl_interface.user_je_source_name%TYPE := 'Achats';
  GLI_USER_JE_CATEGORY_NAME CONSTANT gl_interface.user_je_category_name%TYPE := 'OD A CONTREPASSATION';
  GLI_STATUS                CONSTANT gl_interface.status%TYPE := 'NEW';
  --GLI_CURRENCY_CODE         CONSTANT gl_interface.currency_code%TYPE := 'EUR'; --AAM artf07231300 - SPE119
  GLI_CURRENCY_CODE gl_ledgers.currency_code%TYPE; --AAM artf07231300 - SPE119
  GLI_ACTUAL_FLAG CONSTANT gl_interface.actual_flag%TYPE := 'A';
  GLI_CONTEXT3    CONSTANT gl_interface.context3%TYPE := 'Y.E.X';
  LOT_HDR         CONSTANT gl_interface.reference1%TYPE := 'Cut-off sous-traitance ';
  CAP             CONSTANT gl_interface.reference4%TYPE := 'CAP';
  CCA             CONSTANT gl_interface.reference4%TYPE := 'CCA';
  --TVA                       CONSTANT  gl_interface.reference4%TYPE := 'TVA';

  /* Variables globales */
  local_cap       VARCHAR2(10);
  local_cca       VARCHAR2(10);
  local_tva       VARCHAR2(10);
  grpe_cap        VARCHAR2(10);
  grpe_cca        VARCHAR2(10);
  grpe_tva        VARCHAR2(10);
  taux_tva        NUMBER;
  period_end_date DATE;
  created_per     NUMBER;

  --------------------------------------------------------------------------------
  -- Nom          : log_msg
  -- Description  : Affiche un message de la sortie de log.
  --
  -- Paramètres   :
  --   message      Entrée                  texte a afficher en sortie
  --------------------------------------------------------------------------------
  PROCEDURE log_msg(message IN VARCHAR2) IS
    messagebuf VARCHAR2(1000);
  BEGIN
    messagebuf := SUBSTR(message, 1, 1000);
    IF (messagebuf IS NULL) THEN
      messagebuf := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;
    fnd_file.put_line(fnd_file.log, messagebuf);
    --dbms_output.put_line('LOG : ' || SUBSTR(messagebuf, 1, 255));
  END log_msg;

  --------------------------------------------------------------------------------
  -- Nom           : out_msg
  -- Description   : Affiche un message dans la sortie standard.
  --
  -- Paramètres    :
  --   message       Entrée                 texte a afficher en sortie
  --
  --------------------------------------------------------------------------------
  PROCEDURE out_msg(message in VARCHAR2) IS
  BEGIN
    fnd_file.put_line(fnd_file.output, message);
    --dbms_output.put_line('OUT : ' || SUBSTR(message, 1, 255));
  END out_msg;

  --------------------------------------------------------------------------------
  -- Nom           : init
  -- Description   : Récupère les paramètres, initialise les variables globales
  --                 En particulier, récupère et calcule les comptes locaux et
  --                 groupes pour les CAP, CCA, TVA ; récupère et initialise
  --                 également le taux de TVA ainsi que la date de fin de période.
  --
  -- Paramètres    :
  --   pv_errbuf     Entrée/Sortie         message d'erreur
  --   pn_retcode    Sortie                0=normal, 1=warning, 2=erreur
  --   period        Entrée                chaîne contenant la période sur
  --                                       laquelle calculer (ex. 'JAN-08')
  --------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf         IN OUT VARCHAR2,
                 pn_retcode        OUT NUMBER,
                 period            IN VARCHAR2,
                 p_set_of_books_id IN VARCHAR2) IS
    --RBE artf2170606
    l_param   VARCHAR2(100);
    rec_param dka_parameters%ROWTYPE;
    param_err EXCEPTION;
    ret_err   EXCEPTION;
    v_set_of_books_id NUMBER := p_set_of_books_id; --RBE artf2170606
  BEGIN
    log_msg('-------------------[init]-------------------');
    log_msg('Paramètre (period) : ' || period);
  
    -- récupération du compte local de CAP
    l_param := 'CPTE_CAP';
    dka_tools_pkg.get_parameter(APP_NAME,
                                'CPTE_CAP',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    local_cap := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      RAISE param_err;
    END IF;
    log_msg('Compte local CAP  : ' || local_cap);
  
    -- récupération du compte local de CCA
    l_param := 'CPTE_CCA';
    dka_tools_pkg.get_parameter(APP_NAME,
                                'CPTE_CCA',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    local_cca := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      RAISE param_err;
    END IF;
    log_msg('Compte local CCA  : ' || local_cca);
  
    -- récupération du compte local de TVA
    l_param := 'CPTE_TVA';
    dka_tools_pkg.get_parameter(APP_NAME,
                                'CPTE_TVA',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    local_tva := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      RAISE param_err;
    END IF;
    log_msg('Compte local TVA  : ' || local_tva);
  
    -- récupération du taux de TVA
    l_param := 'TAUX_TVA';
    dka_tools_pkg.get_parameter(APP_NAME,
                                'TAUX_TVA',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    taux_tva := rec_param.number_value;
    IF pn_retcode != 0 THEN
      RAISE param_err;
    END IF;
    log_msg('Taux TVA          : ' || taux_tva);
  
    -- calcul du compte groupe de CAP
    l_param  := 'GRPE_CAP';
    grpe_cap := dka_stransco_pkg.get_value_f(TRANSCO_CTX,
                                             SYSDATE,
                                             pv_errbuf,
                                             local_cap);
    IF grpe_cap IS NULL THEN
      RAISE ret_err;
    END IF;
    log_msg('Compte groupe CAP : ' || grpe_cap);
  
    -- calcul du compte groupe de CCA
    l_param  := 'GRPE_CCA';
    grpe_cca := dka_stransco_pkg.get_value_f(TRANSCO_CTX,
                                             SYSDATE,
                                             pv_errbuf,
                                             local_cca);
    IF grpe_cca IS NULL THEN
      RAISE ret_err;
    END IF;
    log_msg('Compte groupe CCA : ' || grpe_cca);
  
    -- calcul du compte groupe de TVA
    l_param  := 'GRPE_TVA';
    grpe_tva := dka_stransco_pkg.get_value_f(TRANSCO_CTX,
                                             SYSDATE,
                                             pv_errbuf,
                                             local_tva);
    IF grpe_tva IS NULL THEN
      RAISE ret_err;
    END IF;
    log_msg('Compte groupe TVA : ' || grpe_tva);
  
    -- récupération de la date de fin de période
    SELECT gps.end_date
      INTO period_end_date
      FROM gl_period_statuses gps
     WHERE gps.period_name = period
       AND gps.set_of_books_id = v_set_of_books_id --gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R') -- fnd_profile.value('GL_SET_OF_BKS_ID') --RBE MigR12
       AND gps.application_id = APP_ID;
    log_msg('Fin de période    : ' || period_end_date);
  
    -- récupération de l'Id de l'utilisateur.
    created_per := fnd_profile.value('USER_ID');
  
    pn_retcode := 0;
    pv_errbuf  := '';
  
    log_msg('-------------[fin normale init]-------------');
  
  EXCEPTION
    WHEN param_err THEN
      pv_errbuf  := '[init] Erreur lors de la récupératon du paramètre ' ||
                    l_param || ', vérifier qu''il existe dans ' ||
                    'DKA_PARAMETERS. ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN ret_err THEN
      pv_errbuf  := '[init] Erreur récupération table de transco ' ||
                    l_param || ' : ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := '[init] Erreur générique' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END init;

  --return DKA_SPOCUT_OFF_PKG.get_montant_ht(:PRESTA_UNITAIRE, :ATTRIBUTE3, :DATE_DEBUT, :DATE_FIN, :DATE_PERIOD, :MNTT_AN, :ID_CONTRAT);

  --------------------------------------------------------------------------------
  -- Nom           : get_charge_theorique_imput
  -- Description   : Fonction de calcul de la charge théorique
  --
  -- Paramètres    :
  --                     pn_contrat_imputation_id  : ID imputation contrat
  --                     pd_start_date             : Date de début du contrat
  --                     pd_period_date            : Date de fin de la période
  --------------------------------------------------------------------------------
  FUNCTION get_charge_theorique_imput(pn_contrat_imputation_id IN NUMBER,
                                      pd_start_date            IN DATE,
                                      pd_period_date           IN DATE)
    RETURN NUMBER IS
    vn_amount_imputation NUMBER;
    vn_nbr_mois_contrat  NUMBER;
    vd_date_effet_deb    DATE;
    vd_date_effet_fin    DATE;
    vn_amount            NUMBER;
  
    CURSOR cur_historique_imput(pn_contrat_imputation_id NUMBER,
                                pd_start_date            DATE) IS
      SELECT phaa.revision_num,
             phaa.po_header_id,
             phaa.blanket_total_amount amount,
             phaa.start_date,
             phaa.end_date,
             dcsa.date_effet,
             -- Début modif EMA du 13/01/2012
             dcsa.date_resiliation date_resiliation,
             -- Fin modif EMA du 13/01/2012
             RevSup.date_effet          date_effet_revsup,
             dcsia.unite_oeuvre,
             dcsia_sum.sum_unite_oeuvre,
             RevSup.revision_num        revision_num_revsup,
             -- Ajout bco
             phaa.attribute14 presta_unit,
             -- DGE20130037 - Flag correspondant à la modification du montant d'un contrat.
             dcsa.annulation,
             RevSup.blanket_total_amount RevSupAmount
        FROM po_headers_archive_all phaa,
             dka_contrat_sstr_archi dcsa,
             (SELECT dcsa_RevSup.po_header_id,
                     dcsa_RevSup.revision_num,
                     phaa_RevSup.start_date,
                     dcsa_RevSup.date_effet,
                     phaa_RevSup.blanket_total_amount
                FROM po_headers_archive_all phaa_RevSup,
                     dka_contrat_sstr_archi dcsa_RevSup
               WHERE dcsa_RevSup.po_header_id = phaa_RevSup.Po_Header_Id
                 AND dcsa_RevSup.revision_num = phaa_RevSup.revision_num) RevSup,
             dka_contrat_sstr_imput_archi dcsia,
             (SELECT po_header_id,
                     revision_num,
                     sum(unite_oeuvre) sum_unite_oeuvre
                FROM dka_contrat_sstr_imput_archi
               GROUP BY po_header_id, revision_num) dcsia_sum
       WHERE dcsa.po_header_id = phaa.po_header_id
         AND dcsa.revision_num = phaa.revision_num
         AND RevSup.po_header_id(+) = phaa.po_header_id
         AND RevSup.revision_num(+) = phaa.revision_num + 1
         AND RevSup.start_date(+) = phaa.start_date
         AND phaa.po_header_id = dcsia.po_header_id
         AND phaa.revision_num = dcsia.revision_num
         AND dcsia_sum.po_header_id = dcsia.po_header_id
         AND dcsia_sum.revision_num = dcsia.revision_num
         AND phaa.start_date = pd_start_date
         AND dcsia.contrat_imputation_id = pn_contrat_imputation_id
       ORDER BY phaa.revision_num;
    rec_historique_imput cur_historique_imput%ROWTYPE;
  
  BEGIN
    vn_amount_imputation := 0;
    vn_amount            := 0;
    -- Calcul du nouveau montant de la ligne d'imputation
    FOR rec_historique_imput IN cur_historique_imput(pn_contrat_imputation_id,
                                                     pd_start_date) LOOP
      BEGIN
        vn_nbr_mois_contrat := round(months_between(trunc(rec_historique_imput.end_date),
                                                    trunc(rec_historique_imput.start_date)));
        vd_date_effet_deb   := nvl(rec_historique_imput.date_effet,
                                   rec_historique_imput.start_date);
      
        IF rec_historique_imput.revision_num_revsup IS NULL THEN
          -- Debut Modif EMA du 13/01/2011
          --vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup, rec_historique_imput.end_date);
          vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup,
                                   NVL(rec_historique_imput.date_resiliation,
                                       rec_historique_imput.end_date));
          -- Fin Modif EMA du 13/01/2011
        ELSE
          vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup,
                                   rec_historique_imput.start_date);
        END IF;
      
        -- ajustement de la date de fin à la période de calcul
        IF (vd_date_effet_fin > pd_period_date) THEN
          vd_date_effet_fin := pd_period_date;
        END IF;
      
        IF (vd_date_effet_deb < pd_period_date) THEN
          IF rec_historique_imput.sum_unite_oeuvre != 0 THEN
            IF rec_historique_imput.annulation = 'OUI' THEN
              vn_amount := rec_historique_imput.RevSupAmount;
            ELSE
              vn_amount := rec_historique_imput.amount;
            END IF;
            IF rec_historique_imput.presta_unit = 'OUI' THEN
              vn_amount_imputation := vn_amount_imputation +
                                      ROUND((vn_amount -
                                            vn_amount_imputation) *
                                            ((round(months_between(trunc(vd_date_effet_fin),
                                                                   trunc(vd_date_effet_deb)))) -- nombre mois entre date effet en cour et futur date effet
                                            / (round(months_between(trunc(rec_historique_imput.end_date),
                                                                     trunc(vd_date_effet_deb))))) *
                                            (rec_historique_imput.unite_oeuvre /
                                            rec_historique_imput.sum_unite_oeuvre),
                                            2);
            ELSE
              vn_amount_imputation := vn_amount_imputation +
                                      ROUND((vn_amount *
                                            (round(months_between(trunc(vd_date_effet_fin),
                                                                   trunc(vd_date_effet_deb)))) /
                                            vn_nbr_mois_contrat) *
                                            (rec_historique_imput.unite_oeuvre /
                                            rec_historique_imput.sum_unite_oeuvre),
                                            2);
            END IF;
          END IF;
        
        END IF;
      
        -- <JWY 08/02/2021 artf07439823 INC0509419
      EXCEPTION
        WHEN OTHERS THEN
          log_msg('Erreur de calcul rencontree sur la commande po_header_id/contrat_imputation_id : ' ||
                  rec_historique_imput.po_header_id || '/' ||
                  pn_contrat_imputation_id);
          log_msg(SQLERRM);
          -- JWY 08/02/2021  artf07439823 INC0509419 />   
      END;
    END LOOP;
  
    ----- return value -----
    RETURN(vn_amount_imputation);
  END get_charge_theorique_imput;

  -------------------------------------------------------------------------------
  -- Nom           : main
  -- Description   : Insère, pour chaque imputation d'une commande en cours d'un
  --                  contrat de sous-traitance, une Charge À Payer (CAP) ou une
  --                  Charge Constatée d'Avance (CCA).
  --
  --                  Pour une CAP, génère une écriture de charge (débit), une
  --                  écriture sur le compte CAP (crédit), et une écriture de TVA
  --                  (crédit).
  --                  Pour une CCA, génère une écriture de charge (crédit) et une
  --                  écriture sur le compte CCA (débit).
  --                  Les écritures sur les comptes CAP, TVA, CCA sont regroupées
  --                  suivant le segment1 (société), segment2 (région), et compte
  --                  local (CAP, TVA ou CCA).
  --
  -- Paramètres    :
  --   pv_errbuf     Entrée/Sortie         Retour de message eventuel
  --   pn_retcode           Sortie         Statut du traitement en sortie
  --   period        Entrée                Chaîne contenant la période sur
  --                                       laquelle calculer (ex. 'JAN-08')
  --------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf         IN OUT VARCHAR2,
                 pn_retcode        OUT NUMBER,
                 period            IN gl_period_statuses.period_name%TYPE,
                 p_set_of_books_id IN NUMBER) IS
    --RBE artf2170606
  
    /*
    * Requête récupérant les imputations des commandes liées à des contrats
    * de sous-traitance (dépendants ou indépendants) et calculant directement
    * le cut-off associé.
    */
    CURSOR c_imputations(c_set_of_books_id NUMBER) IS
      SELECT ph.po_header_id,
             pd.po_distribution_id  AS imp_id,
             ph.segment1            AS cmde_id,
             ph.revision_num,
             pv.segment1            AS num_frs,
             pv.vendor_name         AS fournisseur,
             phc.segment1           AS ctrt_num,
             phc.po_header_id       AS ctrt_id,
             phc.start_date         AS ctrt_start_date,
             phc.end_date           AS ctrt_end_date,
             gps.end_date           AS periode_end_date,
             pd.code_combination_id,
             gcc_old.segment1       AS old_segment1,
             gcc_old.segment2       AS old_segment2,
             gcc_old.segment3       AS old_segment3,
             gcc_old.segment4       AS old_segment4,
             gcc_old.segment5       AS old_segment5,
             gcc_old.segment6       AS old_segment6,
             gcc_old.segment7       AS old_segment7,
             gcc_old.segment8       AS old_segment8,
             gcc_old.segment9       AS old_segment9,
             gcc_old.segment10      AS old_segment10,
             gcc_old.segment11      AS old_segment11, --RBE MigR12
             gcc_old.segment12      AS old_segment12, --RBE MigR12
             --RBE MigR12
             /*SUBSTR(Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f(pd.project_id,
                                                               '0',
                                                               gps.end_date,
                                                               NULL),
             1 + Dka_Tools_Pkg.segment_size(2),
             Dka_Tools_Pkg.segment_size(1)) new_segment1,*/
             DKA_SPAAUTOACCOUNTING_PKG.societe_projet(pd.project_id) new_segment1,
             /*SUBSTR(Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f(pd.project_id,
                                                               '0',
                                                               gps.end_date,
                                                               NULL),
             1,
             Dka_Tools_Pkg.segment_size(2)) new_segment2,*/
             DKA_SPAAUTOACCOUNTING_PKG.uo_projet(pd.project_id) new_segment2,
             
             /*Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f(pd.project_id,
             pd.expenditure_type,
             NULL,
             gps.end_date,
             NULL) new_segment4,*/
             DKA_SPAAUTOACCOUNTING_PKG.cpt_groupe_couts(pd.project_id,
                                                        pd.expenditure_type,
                                                        NULL,
                                                        pd.task_id) new_segment4,
             /*Dka_Spaautoaccounting_Pkg.get_code_partenaire_f(pv.vendor_type_lookup_code,
             pv.vendor_id) new_segment5,*/
             -- dka_spaautoaccounting_pkg.get_interco_fourn_f(pv.vendor_id) new_segment5,
             dka_spaautoaccounting_pkg.get_interco_fourn_f(pvsa.vendor_site_id) new_segment5, -- JWYC artf2512537
             /*Dka_Spaautoaccounting_Pkg.get_cost_center_f(pd.project_id,
             gps.end_date) new_segment6,*/
             dka_spaautoaccounting_pkg.centrefi(pd.project_id) new_segment6,
             /*Dka_Spaautoaccounting_Pkg.code_d(pd.project_id) new_segment7,*/
             Dka_Spaautoaccounting_Pkg.affaire(pd.project_id) new_segment7,
             /*Dka_Spaautoaccounting_Pkg.get_class_code_f(pd.project_id,
             'NATURE_ACTIVITE') new_segment8,*/
             Dka_Spaautoaccounting_Pkg.projetfi(pd.project_id) new_segment8,
             pd.project_id,
             pd.task_id,
             pd.expenditure_type,
             gcc_acc.segment1,
             gcc_acc.segment2,
             gcc_acc.segment4, -- EMA 08/04/2011
             gcc_acc.segment5,
             gcc_acc.segment6,
             gcc_acc.segment7,
             gcc_acc.segment8,
             gcc_acc.segment9,
             gcc_acc.segment10,
             gcc_acc.segment11, --RBE MigR12
             gcc_acc.segment12, --RBE MigR12
             pd.quantity_ordered AS imp_ordered_q, -- charge théorique annuelle
             pd.quantity_billed AS imp_billed_q, -- charge réellement facturée
             pd.attribute3 -- Contrat_imputation_id
             -- CD 230408  ROUND((pd.quantity_ordered
             -- CD 230408              * round(months_between(trunc(gps.end_date), trunc(phc.start_date))) -- durée écoulée
             -- CD 230408              / round(months_between(trunc(phc.End_Date), trunc(phc.start_date)))) -- durée du contrat
             -- CD 230408            -  pd.quantity_billed,
             -- CD 230408        2)                     AS diff_q                        -- différence entre charge théorique attendue au prorata temporis cumulé et charge facturée
            ,
             ph.org_id --RBE MigR12
            ,
             gps.set_of_books_id ledger_id
        FROM --hr_operating_units hou,  --RBE MigR12
             po_headers_all ph, -- commandes
             (select pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     dcsa_max.commande_id -- Récuperation du dernier contrat archivé pour chaque commande
                from po_headers_archive_all pha,
                     (select po_header_id,
                             commande_id,
                             max(revision_num) revision_num
                        from dka_contrat_sstr_archi
                       group by po_header_id, commande_id) dcsa_max
               where dcsa_max.po_header_id = pha.po_header_id
                 and dcsa_max.revision_num = pha.revision_num
                 and pha.authorization_status = 'APPROVED'
                 and pha.attribute4 in
                     ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
              --RBE artf2170606
              --OCL EDB240
              /*and EXISTS (SELECT 1
              FROM hr_operating_units
              WHERE set_of_books_id = c_set_of_books_id
              AND organization_id = pha.org_id
              )*/
              ) phc, -- contrats de sous-traitance approuvés
             Po_Distributions_All pd, -- lignes d'imputation
             gl_period_statuses gps, -- périodes
             gl_code_combinations gcc_acc, -- codes comptables
             po_vendors pv,
             po_vendor_sites_all pvsa, --JWYC artf2512537
             gl_code_combinations gcc_old, --,
             --gl_ledgers gl, --RBE artf2170606
             --gl_access_set_assignments gasa --RBE artf2170606
             pa_projects_all    ppa, --OCL EDB240
             hr_operating_units hou --OCL EDB240
       WHERE 1 = 1
         AND ph.segment1 LIKE '%ST%'
         AND ph.authorization_status = 'APPROVED'
         AND ph.po_header_id = pd.po_header_id
         AND phc.segment1 =
             substr(ph.segment1, 1, instr(ph.segment1, 'ST') + 1)
         AND gps.period_name = period
         AND gps.set_of_books_id = c_set_of_books_id --gl.ledger_id --gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R')    -- RBE MigR12
            --fnd_profile.value('GL_SET_OF_BKS_ID')  -- RBE MigR12
         AND (gps.end_date BETWEEN phc.start_date AND phc.end_date OR
             (phc.start_date > gps.end_date AND pd.quantity_billed != 0) -- CD 230408
             OR (phc.end_date < gps.end_date AND
             pd.quantity_ordered - pd.quantity_billed > 0) -- CD 230408
             )
            
            -- 09/09/2009 SROL Ajout du filtre par rapport à l annee de chaque commande sstr
            -- CDE 180210 AND substr(ph.segment1,-4) = to_char(phc.start_date,'YYYY')
         AND ph.po_header_id = phc.commande_id
            -- 09/09/2009 SROL Mise en commentaire du filtre suivant
            /*AND (ph.approved_date BETWEEN phc.start_date AND phc.end_date
                 OR (ph.approved_date < phc.start_date AND months_between(trunc(ph.approved_date), trunc(phc.start_date)) < 12)) -- CD 230408
            */
            -- 12/02/2010 SROL Changement du filtre du statut de fermeture réduit à 'FINALLY CLOSED' sans le statut 'CLOSED'
         AND nvl(ph.closed_code, '#') NOT IN ('FINALLY CLOSED')
         AND gcc_acc.code_combination_id = pd.accrual_account_id
         AND pv.vendor_id = ph.vendor_id
         AND pv.vendor_id = pvsa.vendor_id --JWYC artf2512537
         AND pvsa.vendor_site_id = ph.vendor_site_id --JWYC artf2512537
         AND gcc_old.code_combination_id = pd.code_combination_id
         AND gps.application_id = APP_ID
            --RBE artf2170606
            --AND gasa.access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
            --And gl.Ledger_Id = Gasa.Ledger_Id
            --AND gl.ledger_category_code = 'PRIMARY'
            --OCL EDB240
            /* AND EXISTS (SELECT 1
            FROM hr_operating_units
            WHERE set_of_books_id = c_set_of_books_id
            AND organization_id = ph.org_id)*/
         AND ppa.project_id = pd.project_id
         AND ppa.org_id = hou.organization_id
         AND hou.set_of_books_id = c_set_of_books_id
      
      ;
  
    --imputation c_imputations%ROWTYPE;
  
    /*
    * Table de hachage servant à regrouper les écritures dans les comptes
    * de CAP, CCA et TVA.
    * Chaque compte est indexé par sa clé comptable (segment[1-10]), et a
    * comme valeur la somme totale à créditer ou débiter.
    */
    TYPE comptes_type IS TABLE OF NUMBER INDEX BY VARCHAR2(260);
    comptes_cumul comptes_type;
  
    /* Variables utilisées pour extraire des données de la table de hachage */
    compte    VARCHAR2(260);
    somme     NUMBER;
    vn_diff_q NUMBER;
  
    /*
    * Variables temporaires utilisées pour stocker le montant total de chaque
    * imputation et générer la partie hors taxes et la partie TVA.
    */
    montant_ttc gl_interface.entered_dr%TYPE;
    montant_ht  gl_interface.entered_dr%TYPE;
    montant_tva gl_interface.entered_dr%TYPE;
  
    /*
    * Variables nécessaires pour l'insertion dans la table
    * gl_interface_control de *la* ligne de traitement pour EasyLink.
    */
    interface_run_id gl_interface_control.interface_run_id%TYPE;
    group_id         NUMBER;
    source_name      gl_je_sources.je_source_name%TYPE;
    set_of_books_id  gl_sets_of_books.set_of_books_id%TYPE := p_set_of_books_id; --RBE artf2170606
  
    /*
    * Variables temporaires utilisées pour stocker la clé comptable pour les
    * comptes CAP, CCA et TVA avant insertion dans la table gl_interface.
    */
    segment1  gl_interface.segment1%TYPE;
    segment2  gl_interface.segment2%TYPE;
    segment3  gl_interface.segment3%TYPE;
    segment4  gl_interface.segment4%TYPE;
    segment5  gl_interface.segment5%TYPE;
    segment6  gl_interface.segment6%TYPE;
    segment7  gl_interface.segment7%TYPE;
    segment8  gl_interface.segment8%TYPE;
    segment9  gl_interface.segment9%TYPE;
    segment10 gl_interface.segment10%TYPE;
    segment11 gl_interface.segment11%TYPE; -- RBE MigR12
    segment12 gl_interface.segment12%TYPE; -- RBE MigR12
    --code_combin_id    gl_interface.code_combination_id%TYPE;
  
    /* Variables temporaires utilisées pour gérer le lettrage et le lot. */
    lot          gl_interface.reference1%TYPE;
    lettrage_ref gl_interface.jgzz_recon_ref%TYPE;
    lettrage     gl_interface.jgzz_recon_ref%TYPE;
  
    /*
    * Variables temporaires utilisées pour localiser les séparateurs dans
    * la chaîne d'index de la table de hachage. Nécessaire pour parser
    * cette chaîne et distinguer les segments.
    */
    sep1  NUMBER;
    sep2  NUMBER;
    sep3  NUMBER;
    sep4  NUMBER;
    sep5  NUMBER;
    sep6  NUMBER;
    sep7  NUMBER;
    sep8  NUMBER;
    sep9  NUMBER;
    sep10 NUMBER; --RBE artf2195248
    sep11 NUMBER; --RBE artf2195248
  
    /* Variables utilisées pour l'affichage en sortie. */
    imp_lues         NUMBER := 0;
    cap_lues         NUMBER := 0;
    cca_lues         NUMBER := 0;
    ntd_lues         NUMBER := 0;
    chg_cap_inserees NUMBER := 0;
    chg_cca_inserees NUMBER := 0;
    cap_inserees     NUMBER := 0;
    cca_inserees     NUMBER := 0;
    tva_inserees     NUMBER := 0;
  
    /* Variables pour EasyLink */
    request_id NUMBER := 0;
    flag       BOOLEAN;
    phase      VARCHAR2(30);
    status     VARCHAR2(30);
    dev_phase  VARCHAR2(30);
    dev_status VARCHAR2(30);
    message    VARCHAR2(30);
  
    vn_retcode      NUMBER; -- Modif EMA du 08/04/2011
    vv_message      VARCHAR2(200); -- Modif EMA du 08/04/2011
    vv_new_segment3 gl_interface.segment3%TYPE; -- Modif EMA du 08/04/2011
    vn_new_ccid     gl_interface.code_combination_id%TYPE; -- Modif EMA du 08/04/2011
  
    /* Exceptions */
    init_err     EXCEPTION;
    segment3_err EXCEPTION;
    easylink_err EXCEPTION;
  
    v_count NUMBER; --RBE artf2170606
  
  BEGIN
    log_msg('-------------------[main]-------------------');
    log_msg('Paramètre (period) : ' || period);
    init(pv_errbuf, pn_retcode, period, set_of_books_id); -- RBE artf2170606
    IF pn_retcode != 0 THEN
      RAISE init_err;
    END IF;
  
    v_count := 0;
    FOR imputation IN c_imputations(set_of_books_id) LOOP
      v_count := v_count + 1;
      IF v_count = 1 THEN
        --RBE artf2170606
        -- Insère _une_ ligne dans gl_interface_control, après génération des id.
        SELECT gl_journal_import_s.NEXTVAL INTO interface_run_id FROM dual;
        log_msg('interface_run_id généré : ' || interface_run_id);
      
        SELECT gl_interface_control_s.NEXTVAL INTO group_id FROM dual;
        log_msg('group_id généré         : ' || group_id);
      
        --RBE R12
        --set_of_books_id := fnd_profile.VALUE('GL_SET_OF_BKS_ID');
        --set_of_books_id := gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R');
      
        SELECT je_source_name
          INTO source_name
          FROM gl_je_sources
         WHERE user_je_source_name = GLI_USER_JE_SOURCE_NAME;
      
        -- insertion de la ligne dans gl_interface_control
        INSERT INTO gl_interface_control
          (je_source_name,
           status,
           interface_run_id,
           group_id,
           set_of_books_id,
           packet_id)
        --interface_table_name,
        --processed_table_code,
        --request_id)
        VALUES
          (source_name,
           'S',
           interface_run_id,
           group_id,
           set_of_books_id,
           NULL);
        log_msg('Insertion d''une ligne dans la table gl_interface_control');
        log_msg('--------------------------------------------');
      
        lot := LOT_HDR || TO_CHAR(period_end_date, 'YYYY.MM');
        log_msg('lot : ' || lot);
        lettrage_ref := TO_CHAR(period_end_date, 'YYYYMM');
        log_msg('lettrage_ref : ' || lettrage_ref);
      END IF; --RBE artf2170606
    
      -- traitement de toutes les lignes d'imputation récupérées
      log_msg('-------- traitement des imputations --------');
      --LOOP
      --FETCH c_imputations
      --    INTO imputation;
      --EXIT WHEN c_imputations%NOTFOUND;
    
      log_msg('************ ligne d''imputation ************');
      -- CDE 200308    montant_ttc := abs(imputation.diff_q);
      -- CDE 200308    log_msg('montant_ttc : ' || montant_ttc);
    
      -- CD 230408 Calcul de diff_q (différence entre charge théorique attendue au prorata temporis cumulé et charge facturée)
      log_msg('Traitement commande id : ' || imputation.po_header_id ||
              ' - Imputation id : ' || imputation.imp_id);
    
      IF imputation.periode_end_date >= imputation.ctrt_start_date AND
         imputation.periode_end_date <= imputation.ctrt_end_date THEN
      
        IF imputation.attribute3 IS NULL THEN
          -- CD 18022010 On conserve l'ancien calcul pour les commandes pour lesquelles le lien contrat/commande n'a pas pu être établi
          -- du fait de la suppression des lignes sur le contrat avant la mise en place de l'évol
          vn_diff_q := ROUND((imputation.imp_ordered_q *
                             round(months_between(trunc(imputation.periode_end_date),
                                                   trunc(imputation.ctrt_start_date))) -- durée écoulée
                             / round(months_between(trunc(imputation.ctrt_end_date),
                                                     trunc(imputation.ctrt_start_date)))) -- durée du contrat
                             - imputation.imp_billed_q,
                             2);
        
        ELSE
          -- CD 18022010 Nouveau calcul de la charge théorique
          vn_diff_q := ROUND(get_charge_theorique_imput(imputation.attribute3,
                                                        imputation.ctrt_start_date,
                                                        imputation.periode_end_date) -
                             imputation.imp_billed_q,
                             2);
        END IF;
      
      ELSIF imputation.periode_end_date < imputation.ctrt_start_date THEN
        vn_diff_q := ROUND(0 - imputation.imp_billed_q, 2); -- On considère que la quantité commandée est à 0
      
      ELSIF imputation.periode_end_date > imputation.ctrt_end_date THEN
        vn_diff_q := ROUND(imputation.imp_ordered_q -
                           imputation.imp_billed_q,
                           2); -- Toute la quantité commandée doit être prise en compte.
      
      END IF;
    
      lettrage := nvl(imputation.new_segment1, --OCL EDB240 --RBE artf2195248
                      imputation.old_segment1) || '_' ||
                  nvl(imputation.new_segment2, --OCL EDB240 --RBE artf2195248
                      imputation.old_segment2) || '_' || lettrage_ref;
      log_msg('lettrage : ' || lettrage);
      log_msg('ImputationId   : ' || imputation.imp_id);
    
      --Debut AAM artf07231300 - SPE119
      BEGIN
        SELECT currency_code
          INTO GLI_CURRENCY_CODE
          FROM gl_ledgers gl
         WHERE gl.ledger_id = imputation.ledger_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          GLI_CURRENCY_CODE := NULL;
      END;
      --Fin AAM artf07231300 - SPE119
    
      IF vn_diff_q > 0 THEN
        -- théorique - facturé > 0 => CAP
        log_msg('->CAP<-');
        cap_lues := cap_lues + 1;
      
        montant_ht := abs(vn_diff_q); --CDE 200308
        log_msg('montant_ht : ' || montant_ht); --CDE 200308
        /* calcul partie tva/ht */
        -- CDE 200308      montant_tva := ROUND(montant_ttc * taux_tva / (100 + taux_tva), 2);
        montant_tva := ROUND(montant_ht * taux_tva / 100, 2);
        -- montant_ht := ROUND(montant_ttc / (1 + taux_tva / 100), 2);
        -- Pour le calcul du montant ht, on utilise plutôt une différence pour
        -- éviter les problèmes d'arrondis.
        -- CDE 200308      montant_ht := montant_ttc - montant_tva;
        montant_ttc := montant_ht + montant_tva;
        -- CDE 200308      log_msg('montant_ht     : ' || montant_ht);
        log_msg('montant_ttc    : ' || montant_ttc);
        log_msg('montant_tva    : ' || montant_tva);
      
        /* crédit compte CAP */
        compte := nvl(imputation.new_segment1, imputation.segment1) || '.' || --OCL EDB240 --RBE artf2195248
                  nvl(imputation.new_segment2, imputation.segment2) || '.' || --OCL EDB240 --RBE artf2195248
                  local_cap || '.' || grpe_cap || '.' ||
                  imputation.segment5 || '.' || imputation.segment6 || '.' ||
                  imputation.segment7 || '.' || imputation.segment8 || '.' ||
                  imputation.segment9 || '.' || imputation.segment10 || '.' ||
                  imputation.segment11 || '.' || --RBE artf2195248
                  imputation.segment12; --RBE artf2195248
        log_msg('Hash CAP : ' || compte);
        IF comptes_cumul.EXISTS(compte) THEN
          log_msg('Compte CAP existant');
          log_msg('Somme CAP précédente : ' || comptes_cumul(compte));
          comptes_cumul(compte) := comptes_cumul(compte) + montant_ttc;
          log_msg('Insertion dans la hashtable');
        ELSE
          log_msg('Création compte CAP');
          comptes_cumul(compte) := montant_ttc;
        END IF;
        log_msg('Nouvelle somme CAP : ' || comptes_cumul(compte));
      
        /* débit compte TVA */
        compte := nvl(imputation.new_segment1, imputation.segment1) || '.' || --OCL EDB240
                  nvl(imputation.new_segment2, imputation.segment2) || '.' || --OCL EDB240
                  local_tva || '.' || grpe_tva || '.' ||
                  imputation.segment5 || '.' || imputation.segment6 || '.' ||
                  imputation.segment7 || '.' || imputation.segment8 || '.' ||
                  imputation.segment9 || '.' || imputation.segment10 || '.' ||
                  imputation.segment11 || '.' || --RBE artf2195248
                  imputation.segment12; --RBE artf2195248
        log_msg('Hash TVA : ' || compte);
        IF comptes_cumul.EXISTS(compte) THEN
          log_msg('Compte TVA existant');
          log_msg('Somme TVA précédente : ' || comptes_cumul(compte));
          comptes_cumul(compte) := comptes_cumul(compte) + montant_tva;
          log_msg('Insertion dans la hashtable');
        ELSE
          log_msg('Création compte TVA');
          comptes_cumul(compte) := montant_tva;
        END IF;
        log_msg('Nouvelle somme TVA : ' || comptes_cumul(compte));
      
        -- Modif EMA du 08/04/2011
        -- On recalcule la clé comptable
        /*Dka_Tools_Pkg.pa_run_accounting_rule(NULL,
        'CPT_LOCAL_COUTS',
        imputation.expenditure_type,
        NULL,
        NULL,
        NULL,
        imputation.project_id,
        NULL,
        vv_new_segment3,
        vv_message,
        vn_retcode);*/
        vv_new_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(imputation.project_id,
                                                                     imputation.expenditure_type,
                                                                     imputation.task_id);
      
        IF vv_new_segment3 IS NULL THEN
          log_msg('Erreur lors de la recherche du segment3');
          vv_new_segment3 := imputation.old_segment3;
        END IF;
      
        Dka_Tools_Pkg.get_code_combination_id(nvl(imputation.new_segment1, --OCL EDB240
                                                  imputation.old_segment1),
                                              nvl(imputation.new_segment2, --OCL EDB240
                                                  imputation.old_segment2),
                                              vv_new_segment3,
                                              nvl(imputation.new_segment4,
                                                  imputation.old_segment4),
                                              nvl(imputation.new_segment5,
                                                  imputation.old_segment5),
                                              nvl(imputation.new_segment6,
                                                  imputation.old_segment6),
                                              nvl(imputation.new_segment7,
                                                  imputation.old_segment7),
                                              nvl(imputation.new_segment8,
                                                  imputation.old_segment8),
                                              imputation.old_segment9,
                                              imputation.old_segment10,
                                              --RBE MigR12
                                              imputation.old_segment11,
                                              imputation.old_segment12,
                                              vn_new_ccid,
                                              vv_message,
                                              vn_retcode,
                                              'Y');
      
        IF vn_new_ccid IS NULL THEN
          log_msg('Erreur lors de la recherche de la nouvelle ccid');
          log_msg(vv_message);
        ELSE
          imputation.code_combination_id := vn_new_ccid;
        END IF;
      
        -- Fin Modif EMA du 08/04/2011
      
        /* débit compte charge */
        INSERT INTO gl_interface
          (
           -- champs obligatoires
           status,
           --set_of_books_id, --RBE MigR12
           ledger_id, --RBE MigR12
           accounting_date,
           currency_code,
           date_created,
           created_by,
           actual_flag,
           user_je_category_name,
           user_je_source_name,
           -- reste
           entered_dr,
           accounted_dr,
           reference1,
           reference4,
           reference10,
           code_combination_id,
           group_id,
           attribute11,
           attribute17, --RBE artf2195248
           attribute13,
           attribute14,
           context2,
           invoice_date,
           tax_code,
           invoice_identifier,
           context3,
           jgzz_recon_ref,
           --/* --RBE artf2195248
           Reference21, -- VKN 13/12/2007 : ajout des 4 valeurs pour les comptes de charge (FT49)
           Reference22, -- VKN 08/02/2008 : suppression de ce qui avait ete demande auparavant
           Reference23,
           --*/ --RBE artf2195248
           Reference24)
        VALUES
          (
           -- champs obligatoires
           GLI_STATUS, -- status
           imputation.ledger_id, -- set_of_books_id
           period_end_date, -- accounting_date
           GLI_CURRENCY_CODE, -- currency_code
           SYSDATE, -- date_created
           created_per, -- created_by
           GLI_ACTUAL_FLAG, -- actual_flag
           GLI_USER_JE_CATEGORY_NAME, -- user_je_category_name
           GLI_USER_JE_SOURCE_NAME, -- uesr_je_source_name,
           -- reste
           montant_ht, -- entered_dr
           NULL, -- accounted_dr
           lot, -- reference1
           CAP || '_' ||
           nvl(imputation.new_segment1, imputation.old_segment1) || '_' || --RBE artf2195248
           nvl(imputation.new_segment2, imputation.old_segment2), -- reference4 --RBE artf2195248
           imputation.num_frs || '/' || imputation.fournisseur || '/' ||
           imputation.cmde_id || '/' || imputation.revision_num, -- reference10
           imputation.code_combination_id, -- cc_id
           group_id, -- group_id
           imputation.project_id, -- attr11
           imputation.task_id, -- attr17 --RBE artf2195248
           imputation.expenditure_type, -- attr13
           montant_ht, -- attr14
           NULL, -- context2
           NULL, -- invoice_date
           NULL, -- tax_code
           NULL, -- invoice_identifier
           GLI_CONTEXT3, -- context3
           lettrage, -- jgzz_recon_ref
           --/* --RBE artf2195248
           'PO', -- VKN 13/12/2007 : ajout des 4 valeurs pour les comptes de charge (FT49)
           imputation.po_header_id, -- VKN 08/02/2008 : suppression de ce qui avait ete demande auparavant
           imputation.imp_id,
           imputation.cmde_id
           --*/ --RBE artf2195248
           --imputation.imp_id --RBE artf2195248
           );
        log_msg('----------');
        log_msg('Insertion de la charge dans la table gl_interface (CAP, débit)');
        chg_cap_inserees := chg_cap_inserees + 1;
      ELSIF vn_diff_q < 0 THEN
        -- théorique - facturé < 0 => CCA
        log_msg('->CCA<-');
        cca_lues := cca_lues + 1;
      
        montant_ttc := abs(vn_diff_q); -- CDE 200308
        log_msg('montant_ttc : ' || montant_ttc); -- CDE 200308
      
        -- débit compte CCA
        compte := nvl(imputation.new_segment1, --RBE artf2195248
                      imputation.old_segment1) || '.' ||
                  nvl(imputation.new_segment2, --RBE artf2195248
                      imputation.old_segment2) || '.' || local_cca || '.' ||
                  grpe_cca || '.' || imputation.segment5 || '.' ||
                  imputation.segment6 || '.' || imputation.segment7 || '.' ||
                  imputation.segment8 || '.' || imputation.segment9 || '.' ||
                  imputation.segment10 || '.' || imputation.segment11 || '.' || --RBE artf2195248
                  imputation.segment12; --RBE artf2195248
        log_msg('Hash CCA : ' || compte);
      
        IF comptes_cumul.EXISTS(compte) THEN
          log_msg('Compte CCA existant');
          log_msg('Somme CCA précédente : ' || comptes_cumul(compte));
          comptes_cumul(compte) := comptes_cumul(compte) + montant_ttc;
        ELSE
          log_msg('Création compte CCA');
          comptes_cumul(compte) := montant_ttc;
        END IF;
        log_msg('Nouvelle somme CCA : ' || comptes_cumul(compte));
      
        -- Modif EMA du 08/04/2011
        -- On recalcule la clé comptable
        /*
        Dka_Tools_Pkg.pa_run_accounting_rule(NULL,
                                             'CPT_LOCAL_COUTS',
                                             imputation.expenditure_type,
                                             NULL,
                                             NULL,
                                             NULL,
                                             imputation.project_id,
                                             NULL,
                                             vv_new_segment3,
                                             vv_message,
                                             vn_retcode); */
      
        vv_new_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(imputation.project_id,
                                                                     imputation.expenditure_type,
                                                                     imputation.task_id);
      
        IF vv_new_segment3 IS NULL THEN
          log_msg('Erreur lors de la recherche du segment3');
          vv_new_segment3 := imputation.old_segment3;
        END IF;
      
        Dka_Tools_Pkg.get_code_combination_id(nvl(imputation.new_segment1, --RBE artf2195248
                                                  imputation.old_segment1),
                                              nvl(imputation.new_segment2, --RBE artf2195248
                                                  imputation.old_segment2),
                                              vv_new_segment3,
                                              nvl(imputation.new_segment4,
                                                  imputation.old_segment4),
                                              nvl(imputation.new_segment5,
                                                  imputation.old_segment5),
                                              nvl(imputation.new_segment6,
                                                  imputation.old_segment6),
                                              nvl(imputation.new_segment7,
                                                  imputation.old_segment7),
                                              nvl(imputation.new_segment8,
                                                  imputation.old_segment8),
                                              imputation.old_segment9,
                                              imputation.old_segment10,
                                              --RBE MigR12
                                              imputation.old_segment11,
                                              imputation.old_segment12,
                                              vn_new_ccid,
                                              vv_message,
                                              vn_retcode,
                                              'Y');
      
        IF vn_new_ccid IS NOT NULL THEN
          imputation.code_combination_id := vn_new_ccid;
        ELSE
          log_msg('Erreur lors de la recherche de la nouvelle ccid');
          log_msg(vv_message);
        END IF;
      
        -- Fin Modif EMA du 08/04/2011
      
        -- crédit compte charge
        INSERT INTO gl_interface
          (
           -- champs obligatoires
           status,
           --set_of_books_id, --RBE R12
           ledger_id, --RBE R12
           accounting_date,
           currency_code,
           date_created,
           created_by,
           actual_flag,
           user_je_category_name,
           user_je_source_name,
           -- reste
           entered_cr,
           accounted_cr,
           reference1,
           reference4,
           reference10,
           code_combination_id,
           group_id,
           attribute11,
           attribute17, --RBE
           attribute13,
           attribute14,
           context2,
           invoice_date,
           tax_code,
           invoice_identifier,
           context3,
           jgzz_recon_ref,
           --/*    --RBE artf2195248
           Reference21, -- VKN 13/12/2007 : ajout des 4 valeurs pour les comptes de charge (FT49)
           Reference22, -- VKN 08/02/2008 : suppression de ce qui avait ete demande auparavant
           Reference23,
           --*/ --RBE artf2195248
           Reference24)
        VALUES
          (
           -- champs obligatoires
           GLI_STATUS, -- status
           imputation.ledger_id, -- set_of_books_id
           period_end_date, -- accounting_date
           GLI_CURRENCY_CODE, -- currency_code
           SYSDATE, -- date_created
           created_per, -- created_by
           GLI_ACTUAL_FLAG, -- actual_flag
           GLI_USER_JE_CATEGORY_NAME, -- user_je_category_name
           GLI_USER_JE_SOURCE_NAME, -- user_je_source_name
           -- reste
           montant_ttc, -- entered_cr
           NULL, -- accounted_cr
           lot, -- reference1
           CCA || '_' ||
           nvl(imputation.new_segment1, imputation.old_segment1) || '_' || --RBE artf2195248
           nvl(imputation.new_segment2, imputation.old_segment2), -- reference4 --RBE artf2195248
           imputation.num_frs || '/' || imputation.fournisseur || '/' ||
           imputation.cmde_id || '/' || imputation.revision_num, -- reference10
           imputation.code_combination_id, -- code_combination_id
           group_id, -- group_id
           imputation.project_id, -- attribute11
           imputation.task_id, -- attribute17 --RBE artf2195248
           imputation.expenditure_type, -- attribute13
           montant_ttc, -- attribute14
           NULL, -- context2
           NULL, -- invoice_date
           NULL, -- tax_code
           NULL, -- invoice_identifier
           GLI_CONTEXT3, -- context3
           lettrage, -- jgzz_recon_ref
           --/* --RBE artf2195248
           'PO', -- VKN 13/12/2007 : ajout des 4 valeurs pour les comptes de charge (FT49)
           imputation.po_header_id, -- VKN 08/02/2008 : suppression de ce qui avait ete demande auparavant
           imputation.imp_id,
           imputation.cmde_id
           --*/ --RBE artf2195248
           --imputation.imp_id --RBE artf2195248
           );
        log_msg('----------');
        log_msg('Insertion de la charge dans la table gl_interface (CCA, crédit)');
        chg_cca_inserees := chg_cca_inserees + 1;
      ELSE
        ntd_lues := ntd_lues + 1;
      END IF;
      imp_lues := imp_lues + 1;
    END LOOP;
  
    --CLOSE c_imputations;
  
    out_msg(imp_lues || ' ligne(s) d''imputation lues dont : ');
    out_msg('  ' || cap_lues || ' ligne(s) générant une CAP,');
    out_msg('  ' || cca_lues || ' ligne(s) générant une CCA,');
    out_msg('  ' || ntd_lues ||
            ' ligne(s) ne générant rien (théorique - facturé = 0).');
    out_msg('******************************');
  
    IF cap_lues + cca_lues > 0 THEN
      compte := comptes_cumul.FIRST;
      log_msg('--------------------------------------------');
      log_msg('LOOP comptes_list');
      WHILE compte IS NOT NULL LOOP
        somme := comptes_cumul(compte);
        log_msg('Compte ' || compte || ' : ' || somme);
        sep1     := instr(compte, '.', 1, 1);
        sep2     := instr(compte, '.', 1, 2);
        sep3     := instr(compte, '.', 1, 3);
        sep4     := instr(compte, '.', 1, 4);
        sep5     := instr(compte, '.', 1, 5);
        sep6     := instr(compte, '.', 1, 6);
        sep7     := instr(compte, '.', 1, 7);
        sep8     := instr(compte, '.', 1, 8);
        sep9     := instr(compte, '.', 1, 9);
        sep10    := instr(compte, '.', 1, 10); --RBE artf2195248
        sep11    := instr(compte, '.', 1, 11); --RBE artf2195248
        segment1 := substr(compte, 1, sep1 - 1);
        segment2 := substr(compte, sep1 + 1, sep2 - sep1 - 1);
        segment3 := substr(compte, sep2 + 1, sep3 - sep2 - 1);
        segment4 := substr(compte, sep3 + 1, sep4 - sep3 - 1);
        segment5 := substr(compte, sep4 + 1, sep5 - sep4 - 1);
        segment6 := substr(compte, sep5 + 1, sep6 - sep5 - 1);
        segment7 := substr(compte, sep6 + 1, sep7 - sep6 - 1);
        segment8 := substr(compte, sep7 + 1, sep8 - sep7 - 1);
        segment9 := substr(compte, sep8 + 1, sep9 - sep8 - 1);
        --segment10 := substr(compte, sep9 + 1); --RBE artf2195248
        --RBE artf2195248
        segment10 := substr(compte, sep9 + 1, sep10 - sep9 - 1);
        segment11 := substr(compte, sep10 + 1, sep11 - sep10 - 1);
        segment12 := substr(compte, sep11 + 1);
        -- récupération du code_combination_id (et création si inexistant)
        --dka_tools_pkg.get_code_combination_id(
        --                        segment1, segment2, segment3, segment4, segment5,
        --                        segment6, segment7, segment8, segment9, segment10,segment11,segment12
        --                        code_combin_id, pv_errbuf, pn_retcode, 'Y');
        --log_msg('code_combination_id récupéré ou généré : '|| code_combin_id);
      
        -- insertion des lignes de CAP, CCA, TVA
        lettrage := segment1 || '_' || segment2 || '_' || lettrage_ref;
        log_msg('lettrage : ' || lettrage);
        IF segment3 = local_cap THEN
          -- écriture de CAP
          INSERT INTO gl_interface
            (
             -- champs obligatoires
             status,
             --set_of_books_id, --RBE R12
             ledger_id, --RBE R12
             accounting_date,
             currency_code,
             date_created,
             created_by,
             actual_flag,
             user_je_category_name,
             user_je_source_name,
             -- reste
             segment1,
             segment2,
             segment3,
             segment4,
             segment5,
             segment6,
             segment7,
             segment8,
             segment9,
             segment10,
             segment11, --RBE artf2195248
             segment12, --RBE artf2195248
             entered_cr,
             accounted_cr,
             reference1,
             reference4,
             --code_combination_id,
             group_id,
             context2,
             invoice_date,
             tax_code,
             invoice_identifier,
             jgzz_recon_ref)
          VALUES
            (
             -- champs obligatoires
             GLI_STATUS, -- status
             set_of_books_id, -- set_of_books_id
             period_end_date, -- accounting_date
             GLI_CURRENCY_CODE, -- currency_code
             SYSDATE, -- date_created
             created_per, -- created_by
             GLI_ACTUAL_FLAG, -- actual_flag
             GLI_USER_JE_CATEGORY_NAME, -- user_je_category_name
             GLI_USER_JE_SOURCE_NAME, -- user_je_source_name
             -- reste
             segment1, -- segment1
             segment2, -- segment2
             segment3, -- segment3
             segment4, -- segment4
             segment5, -- segment5
             segment6, -- segment6
             segment7, -- segment7
             segment8, -- segment8
             segment9, -- segment9
             segment10, -- segment10
             segment11, -- segment11 --RBE artf2195248
             segment12, -- segment12 --RBE artf2195248
             somme, -- entered_cr
             NULL, -- accounted_cr
             lot, -- reference1
             CAP || '_' || segment1 || '_' || segment2, -- reference4
             --code_combin_id,                     -- code_combination_id
             group_id, -- group_id
             NULL, -- context2
             NULL, -- invoice_date
             NULL, -- tax_code
             NULL, -- invoice_identifier
             lettrage -- jgzz_recon_ref
             );
          log_msg('CAP insérée');
          cap_inserees := cap_inserees + 1;
        ELSIF segment3 = local_cca THEN
          -- écriture de CCA
          INSERT INTO gl_interface
            (
             -- champs obligatoires
             status,
             --set_of_books_id, --RBE R12
             ledger_id, --RBE R12
             accounting_date,
             currency_code,
             date_created,
             created_by,
             actual_flag,
             user_je_category_name,
             user_je_source_name,
             -- reste
             segment1,
             segment2,
             segment3,
             segment4,
             segment5,
             segment6,
             segment7,
             segment8,
             segment9,
             segment10,
             segment11, --RBE artf2195248
             segment12, --RBE artf2195248
             entered_dr,
             accounted_dr,
             reference1,
             reference4,
             --code_combination_id,
             group_id,
             context2,
             invoice_date,
             tax_code,
             invoice_identifier,
             jgzz_recon_ref)
          VALUES
            (
             -- champs obligatoires
             GLI_STATUS, -- status
             set_of_books_id, -- set_of_books_id
             period_end_date, -- accounting_date
             GLI_CURRENCY_CODE, -- currency_code
             SYSDATE, -- date_created
             created_per, -- created_by
             GLI_ACTUAL_FLAG, -- actual_flag
             GLI_USER_JE_CATEGORY_NAME, -- user_je_category_name
             GLI_USER_JE_SOURCE_NAME, -- user_je_source_name
             -- reste
             segment1, -- segment1
             segment2, -- segment2
             segment3, -- segment3
             segment4, -- segment4
             segment5, -- segment5
             segment6, -- segment6
             segment7, -- segment7
             segment8, -- segment8
             segment9, -- segment9
             segment10, -- segment10
             segment11, -- segment11 --RBE artf2195248
             segment12, -- segment12 --RBE artf2195248
             somme, -- entered_dr
             NULL, -- accounted_dr
             lot, -- reference1
             CCA || '_' || segment1 || '_' || segment2, -- reference4
             --code_combin_id,                     -- code_combination_id
             group_id, -- group_id
             NULL, -- context2
             NULL, -- invoice_date
             NULL, -- tax_code
             NULL, --invoice_identifier
             lettrage -- jgzz_recon_ref
             );
          log_msg('CCA insérée');
          cca_inserees := cca_inserees + 1;
        ELSIF segment3 = local_tva THEN
          -- écriture de TVA
          INSERT INTO gl_interface
            (
             -- champs obligatoires
             status,
             --set_of_books_id, --RBE R12
             ledger_id, --RBE R12
             accounting_date,
             currency_code,
             date_created,
             created_by,
             actual_flag,
             user_je_category_name,
             user_je_source_name,
             -- reste
             segment1,
             segment2,
             segment3,
             segment4,
             segment5,
             segment6,
             segment7,
             segment8,
             segment9,
             segment10,
             segment11, --RBE artf2195248
             segment12, --RBE artf2195248
             entered_dr,
             accounted_dr,
             reference1,
             reference4,
             --code_combination_id,
             group_id,
             context2,
             invoice_date,
             tax_code,
             invoice_identifier,
             jgzz_recon_ref)
          VALUES
            (
             -- champs obligatoires
             GLI_STATUS, -- status
             set_of_books_id, -- set_of_books_id
             period_end_date, -- accounting_date
             GLI_CURRENCY_CODE, -- currency_code
             SYSDATE, -- date_created
             created_per, -- created_by
             GLI_ACTUAL_FLAG, -- actual_flag
             GLI_USER_JE_CATEGORY_NAME, -- user_je_category_name
             GLI_USER_JE_SOURCE_NAME, -- user_je_source_name
             -- reste
             segment1, -- segment1
             segment2, -- segment2
             segment3, -- segment3
             segment4, -- segment4
             segment5, -- segment5
             segment6, -- segment6
             segment7, -- segment7
             segment8, -- segment8
             segment9, -- segment9
             segment10, -- segment10
             segment11, -- segment11 --RBE artf2195248
             segment12, -- segment12 --RBE artf2195248
             somme, -- entered_dr
             NULL, -- accounted_dr
             lot, -- reference1
             CAP || '_' || segment1 || '_' || segment2, -- reference4
             --code_combin_id,                     -- code_combination_id
             group_id, -- group_id
             NULL, -- context2
             NULL, -- invoice_date
             NULL, -- tax_code
             NULL, -- invoice_identifier
             lettrage -- jgzz_recon_ref
             );
          log_msg('TVA insérée');
          tva_inserees := tva_inserees + 1;
        ELSE
          -- Le segment3 n'est reconnu ni comme un compte de CAP, ni CCA, ni TVA.
          -- *On ne doit pas passer ici.*
          log_msg('Oh. _Merde_');
          RAISE segment3_err;
        END IF;
        compte := comptes_cumul.NEXT(compte);
      END LOOP;
      log_msg('END LOOP comptes_list');
    
      COMMIT;
      log_msg('Commited');
    
      out_msg('Écritures commitées');
    
      out_msg('Résumé : ');
      out_msg('  ' || chg_cap_inserees || ' écriture(s) de charges (CAP)');
      out_msg('  ' || chg_cca_inserees || ' écriture(s) de charges (CCA)');
      out_msg('  ' || cap_inserees || ' écriture(s) de CAP');
      out_msg('  ' || cca_inserees || ' écriture(s) de CCA');
      out_msg('  ' || tva_inserees || ' écriture(s) de TVA');
      out_msg('******************************');
    
      log_msg('--------------------------------------------');
      log_msg('Lancement EasyLink');
      log_msg('  interface_run_id : ' || interface_run_id);
      request_id := fnd_request.submit_request('SQLGL', -- appl
                                               'GLLEZL', -- prog
                                               NULL, -- program_name
                                               NULL, -- start
                                               FALSE, -- sub_request
                                               interface_run_id, -- argument1
                                               set_of_books_id, -- argument2
                                               'N', -- argument3
                                               NULL, -- argument4
                                               NULL, -- argument5
                                               'N', -- argument6
                                               'O' -- argument7
                                               );
    
      IF (request_id = 0) THEN
        RAISE easylink_err;
      END IF;
    
      log_msg('--------------------------------------------');
      log_msg('EasyLink lancé');
      log_msg('  request_id : ' || request_id);
    
      COMMIT;
    
      flag := fnd_concurrent.wait_for_request(request_id, -- traitement
                                              10, -- intervalle
                                              0, -- timeout
                                              phase,
                                              status,
                                              dev_phase,
                                              dev_status,
                                              message);
      IF NOT flag THEN
        RAISE easylink_err;
      END IF;
    
      log_msg('--------------------------------------------');
      log_msg('EasyLink terminé');
      log_msg('  phase  : ' || phase);
      log_msg('  status : ' || status);
    
      out_msg('Écritures validées et insérées par EasyLink');
    
      pn_retcode := 0;
      pv_errbuf  := '';
    ELSE
      --(cap_lues + cca_lues =< 0)
      out_msg('Rien à traiter.');
      out_msg('******************************');
      --pn_retcode := 1; -- 10/08/2020 JWY INC0451603
      pv_errbuf := 'Aucune CAP/CCA détectée.';
    END IF;
  
  EXCEPTION
    WHEN segment3_err THEN
      pv_errbuf  := '[main] segment3 non reconnu';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN easylink_err THEN
      pv_errbuf  := '[main] Erreur traitement EasyLink';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := '[main] Erreur générique ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END main;

END DKA_SPOCUT_OFF_PKG;
/
SHOW ERROR
EXIT;