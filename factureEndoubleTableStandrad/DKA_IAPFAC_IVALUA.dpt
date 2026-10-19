CREATE OR REPLACE PACKAGE BODY APPS.Dka_Spocharge_Pkg AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOCHARGE_PKG.pkb
  -- DESCRIPTION       : DKA_SPOCHARGE_PKG package body : package pour completer les attributs (11,13,14) de GL_INTERFACE
  --
  -- AUTEUR            : AZIZ NOUJOUD(CGEY)
  -- DATE DE CREATION  : 18/03/2004
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 25/07/2002 SYB mise à jour du group_id sur les lignes impactées
  ---                ajout de messages d'erreurs
  ---                ajout des criteres status = NEW et group_id is null sur le curseur
  --- 17/10/2002 BER Lancement du standard sur toutes les societes
  ---                Suppression dans GL_INTERFACE des lignes qui ne sont pas sur les 26 societes
  --- 08/12/2003 XD  Mise en forme du script
  ---                Modification du type de la plupart des variable pour faire référence à une colonne
  ---                update_gl_interface : mise à jour sur les comptes de classe 6
  ---                                      gestion de l'unité de mesure EUR
  --- 18/03/2004 GL  Comptabilisation des charges d'achat sur projet
  ---                Ajout d'intervention et de controle sur les écritures comptables
  --- 25/05/2004 CD  Suppression utilisation table obsolète dka_active_companies
  ---                + suppression return dans recherche responsabilité malgré resp. incorrecte
  --- 05/08/2004 SLE Portage spécifique pour projet PHENIX 2004
  ---                Modification des procédures run_import, run_prog_standard, update_gl_interface
  --- 25/10/2006 EMA Le calcul des statistiques devient obsolète
  --- 12/02/2007 SRO Rééquilibrer la ligne de bilan par rapport à la ligne de charge sur le segment1 Société
  --- 14/09/2007 JJA Ajout de la desactivation du calcul des CAP  Fournisseurs pour les commandes
  ---                issues des contrats SSTR
  --- 06/11/2007 ADR ETANCHEITE DALKIA 2007
  --- 21/04/2009 CDE EID20090101 - Evolution Fermeture définitive commande pour limiter provisions : Passage
  ---                du paramètre "Extended value" à 10 sur le traitement "RECEIPT_ACCRUALS".
  --- 04/06/2009 TB  EIS20090039 - Modification de la règle de calcul des quantités si unité de mesure différente de EUR
  --- 17/10/2011 EMA EARS00009696836 : On termine le traitement en erreur si l'Easylink se termine en avertissement ou
  ---                en erreur.
  --- 04/06/2013 BCO INC000000415087 : Correction des décimales bloquantes dans PA.
  --- 05/09/2016 MEG Migration R12
  --- 12/01/2017 MEG Modification artf2082208
  --- 07/03/2017 MEG Modification artf2114632
  --- 12/04/2017 MEG Modification artf2101885 : SPE064 : Automatisation : Calcul de la période KO
  --- 20/04/2017 RBE artf2140484 : SPE064 - Problème de performance
  --- 15/06/2017 MEG artf2173355 : SPE064 - Comptabilisation des charges à payer - Fonctionnement
  --- 31/01/2018 MEG artf2345832 : SPE064 - Generation et comptabilisation des charges à payer four - Cle provision
  --- 21/02/2018 MEG artf2391531:  INC0193098 - ETI1 - SPE064 - Comptabilisation_des_charges_d_achat_sur_projet
  --- 26/02/2018 MEG artf2399847 : SPE064 - Alimentation erronée du CUF ATTRIBUTE14
  --- 06/03/2018 MEG artf2415550 : SPE064 - Charges à payer fournisseur - Date de la tache
  --- 08/03/2018 MEG artf2421169:  SPE064 - Soumettre la comptabilisation avec le paramètre "Etat" a "Synthese" au lieu de "Detail"
  --- 07/05/2018 MEG artf2607220 : SPE064 - Calcul des provisions PO - EasyLink avertissement (INC021595)
  --- 20/09/2018 RBE artf2992569 : DPE20180027_EDB208_OracleR12_CAP PO sur commande d'investissement
  --- 16/10/2018 JWY artf3040126 : INC0255126 - Correctif livres à parcourir + modif date exclusion extourne
  --- 08/01/2020 SELO INC0385497 : Controle sur la date fin de la resp PO_ADMINISTRATEUR et Modification de la taille du champ project_code
  --  02/04/2020 JWYC INC0417126 : Problème de contrôle de date de fin des responsabilités
  --  18/06/2025 BBM  KAFI-1116  : EDB407- Calcul des CAP PO - Archivage de la table des rejets dka_spocharge_errors





  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --gv_responsibility_key_mask dka_parameters.varchar2_value%TYPE;
  --gv_user_je_category_name   gl_interface.user_je_category_name%TYPE;
  --gv_user_je_source_name     gl_interface.user_je_source_name%TYPE;
  --gv_context3                gl_interface.context3%TYPE;
  /* ETANCHEITE DALKIA 2007 */
  --gn_set_of_books_id           gl_sets_of_books.set_of_books_id%TYPE;
  gn_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_login_id        fnd_logins.login_id%TYPE;
  gn_montant_min     NUMBER(15);
  G_LOG_LEVEL        CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  G_PKG_NAME         CONSTANT VARCHAR2(30) := 'Dka_Spocharge_Pkg';
  gb_err_easylink    BOOLEAN               := FALSE;
  gn_RESP_ACTIVE  varchar2(5);

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ---------------------------------------------------------------------------------------------------
  --  Nom           : Create_PerEndAccruals
  --  Description   : Procédure basée sur le procédure standard CST_PerEndAccruals_PVT.Create_PerEndAccruals
  --                  Permet de recupérer les lignes selectionnees par le standard et de les controler

  --  PARAMETRES    :
  --     p_api_version      NUMBER       Required
  --     p_init_msg_list    VARCHAR2     Required
  --     p_commit           VARCHAR2     Required
  --     p_validation_level NUMBER       Required
  --     p_min_accrual_amount NUMBER     Required
  --                                     Minimum Accrual Amount
  --     p_vendor_id        NUMBER       Optional         default NULL
  --     p_vendor_from      VARCHAR2     Optional         default NULL
  --                                     Vendor From
  --     p_vendor_to        VARCHAR2     Optional         default NULL
  --                                     Vendor to
  --     p_category_id      NUMBER       Optional         default NULL
  --                                     Category Id
  --     p_category_from    VARCHAR2     Optional         default NULL
  --                                     Category From
  --     p_category_to      VARCHAR2     Optional         default NULL
  --                                     Category to
  --     p_end_date         DATE         Required
  --                                     Period End date
  --     p_accrued_receipt  VARCHAR2     Optional         default NULL
  --                                     Accrued receipts, 'Y' or 'N'
  --     p_online_accruals  VARCHAR2     Optional         default NULL
  --                                     Include online accruals 'Y' or 'N'
  --     p_online_accruals  VARCHAR2     Optional         default NULL
  --                                     Include Closed POs 'Y' or 'N'
  --
  --                                     p_online_accruals, p_accrued_receipts and
  --                                     p_online_accruals are used for Uninvoiced
  --                                     Receipts Report, in other case this value
  --                                     will be 'N'
  --     p_calling_api      NUMBER       Optional
  --
  --   OUT             :
  --     x_return_status    VARCHAR2
  --     x_msg_count        NUMBER
  --     x_msg_data         VARCHAR2
  --
  --   Version : Current version       1.0
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE Create_PerEndAccruals(p_api_version      IN NUMBER,
                                  p_init_msg_list    IN VARCHAR2,
                                  p_commit           IN VARCHAR2,
                                  p_validation_level IN NUMBER,
                                  x_return_status    OUT NOCOPY VARCHAR2,
                                  x_msg_count        OUT NOCOPY NUMBER,
                                  x_msg_data         OUT NOCOPY VARCHAR2,

                                  p_min_accrual_amount  IN NUMBER,
                                  p_vendor_id           IN NUMBER,
                                  p_vendor_from         IN VARCHAR2,
                                  p_vendor_to           IN VARCHAR2,
                                  p_category_id         IN NUMBER,
                                  p_category_from       IN VARCHAR2,
                                  p_category_to         IN VARCHAR2,
                                  p_end_date            IN DATE,
                                  p_accrued_receipt     IN VARCHAR2,
                                  p_online_accruals     IN VARCHAR2,
                                  p_closed_pos          IN VARCHAR2,
                                  p_calling_api         IN NUMBER,
                                  p_accrual_effect_date IN DATE,
                                  p_org_name            IN VARCHAR2,
                                  p_period_name         IN VARCHAR2)

   IS
    l_api_name    CONSTANT VARCHAR2(30) := 'Create_PerEndAccruals';
    l_api_version CONSTANT NUMBER := 1.0;
    l_return_status VARCHAR2(1);

    l_full_name CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || l_api_name;
    l_module    CONSTANT VARCHAR2(60) := 'cst.plsql.' || l_full_name;

    /* Log Severities*/
    /* 6- UNEXPECTED */
    /* 5- ERROR      */
    /* 4- EXCEPTION  */
    /* 3- EVENT      */
    /* 2- PROCEDURE  */
    /* 1- STATEMENT  */

    /* In general, we should use the following:
    G_LOG_LEVEL    CONSTANT NUMBER := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
    l_uLog         CONSTANT BOOLEAN := FND_LOG.TEST(FND_LOG.LEVEL_UNEXPECTED, l_module) AND (FND_LOG.LEVEL_UNEXPECTED >= G_LOG_LEVEL);
    l_errorLog     CONSTANT BOOLEAN := l_uLog AND (FND_LOG.LEVEL_ERROR >= G_LOG_LEVEL);
    l_exceptionLog CONSTANT BOOLEAN := l_errorLog AND (FND_LOG.LEVEL_EXCEPTION >= G_LOG_LEVEL);
    l_eventLog     CONSTANT BOOLEAN := l_exceptionLog AND (FND_LOG.LEVEL_EVENT >= G_LOG_LEVEL);
    l_pLog         CONSTANT BOOLEAN := l_eventLog AND (FND_LOG.LEVEL_PROCEDURE >= G_LOG_LEVEL);
    l_sLog         CONSTANT BOOLEAN := l_pLog AND (FND_LOG.LEVEL_STATEMENT >= G_LOG_LEVEL);
    */

    l_uLog         CONSTANT BOOLEAN := FND_LOG.TEST(FND_LOG.LEVEL_UNEXPECTED, l_module) AND (FND_LOG.LEVEL_UNEXPECTED >= G_LOG_LEVEL);
    l_exceptionLog CONSTANT BOOLEAN := l_uLog AND (FND_LOG.LEVEL_EXCEPTION >= G_LOG_LEVEL);
    l_pLog         CONSTANT BOOLEAN := l_exceptionLog AND (FND_LOG.LEVEL_PROCEDURE >= G_LOG_LEVEL);
    l_sLog         CONSTANT BOOLEAN := l_pLog AND (FND_LOG.LEVEL_STATEMENT >= G_LOG_LEVEL);

    l_accrual_rec CST_PER_END_ACCRUALS_TEMP%ROWTYPE;
    l_end_date    DATE;
    l_stmt_num    NUMBER;
    l_msg_data    VARCHAR2(240);
    l_neg_accrual VARCHAR2(1) := NVL(fnd_profile.value('CST_NEG_ACCRUAL'),'N');

    ------------------------------------------------------------------------
    -- Distribution Level Cursor
    --  The following conditions must be satisfied:
    --  1. Shipment must be on a STANDARD, BLANKET, or PLANNED PO header.
    --  2. If a vendor is specified, then the purchase order must be for
    --     that vendor.
    --  3. If an item category has been specified, then the PO line must be
    --     for that item category.
    --  4. The shipment type must not be of PREPAYMENT type
    --  5. Accrued flag should be Y or N depending upon the value of Accrued
    --     Receipt parameter.
    --  6. For Period End Accruals, the destination type for the distribution
    --     should be EXPENSE and should be either not closed or closed after
    --     the cut-off date.
    --  8. For online accruals, filter out the shipments where quantity_billed
    --     is equal to quantity_received. This will help in improving the
    --     performance of the process.
    --  9. If 'Include Closed POs' is yes, include all the closed POs. Else
    --     exclude the POs which are closed before the cut-oof date.
    --     This parameter is used by Uninvoiced Receipts Report.
    --  10.Must have a receipt against it with a transaction date less than
    --     the cutoff date.
    -------------------------------------------------------------------------

    --
    -- No vendor provided and no category provided
    --
    CURSOR c_no_vendor_no_category IS
      SELECT /*+ LEADING (pod,POLL) PUSH_SUBQ */
       pod.po_distribution_id po_distribution_id,
       poll.line_location_id line_location_id,
       DECODE(poll.matching_basis, 'AMOUNT', 1, 0) service_flag,
       DECODE(poll.matching_basis,
              'AMOUNT',
              pod.amount_ordered - NVL(pod.amount_cancelled, 0),
              pod.quantity_ordered - NVL(pod.quantity_cancelled, 0)) distribution_quantity,
       DECODE(poll.matching_basis,
              'AMOUNT',
              pod.amount_ordered,
              pod.quantity_ordered) quantity_ordered,
       DECODE(poll.matching_basis,
              'AMOUNT',
              poll.amount - NVL(poll.amount_cancelled, 0),
              poll.quantity - NVL(poll.quantity_cancelled, 0)) shipment_quantity,
       DECODE(poll.matching_basis,
              'AMOUNT',
              1,
              NVL(poll.price_override, pol.unit_price)) po_price,
       NVL(poll.match_option, 'P') match_option,
       pol.category_id category_id,
       poh.currency_code currency_code,
       NVL(NVL(pod.rate, poh.rate), 1) currency_rate,
       poh.rate_type curr_conv_type,
       pod.rate_date currency_conv_date,
       pod.project_id, --
       pt.task_id, --
       pod.expenditure_type, --
       --Fnd_Date.canonical_to_date(pt.attribute2) date_fermeture_tache, --
       pt.completion_date date_fermeture_tache,
       gcc.code_combination_id ccid_imputation, --
       gcc2.code_combination_id ccid_provision, --
       gcc.segment1, --
       gcc.segment2, --
       gcc.segment6, --
       gcc.segment7, --
       gcc.concatenated_segments, --
       pp.segment1 pp_segment1, --
       poh.segment1 ph_segment1, --
       poh.creation_date ph_creation_date, --
       pol.line_num, --
       pt.task_number task_num, --
       pp.segment1 project_num, --
/*     DKA_SPAAUTOACCOUNTING_PKG.societe_projet(pod.project_id) new_segment1,
       DKA_SPAAUTOACCOUNTING_PKG.uo_projet(pod.project_id) new_segment2,
       DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(pod.project_id,
                                                 pod.expenditure_type,
                                                 pt.task_id) new_segment3,
       DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f(pod.project_id,
                                                        pod.expenditure_type,
                                                        NULL,
                                                        pt.task_id,
                                                        NULL) new_segment4,*/
       --DKA_SPAAUTOACCOUNTING_PKG.code_interco(pod.project_id,poh.vendor_site_id) new_segment5,
       DKA_SPAAUTOACCOUNTING_PKG.centrefi(pod.project_id) new_segment6,
       DKA_SPAAUTOACCOUNTING_PKG.affaire(pod.project_id) new_segment7,
       --dka_spaautoaccounting_pkg.projetfi(pod.project_id) new_segment8,
       (SELECT gl.ledger_id FROM gl_ledgers gl WHERE gl.name = mo_utils.Get_Ledger_Name(pod.org_id)) ledger_id --
        FROM po_distributions         pod, -- Using single org view PO_DISTRIBUTIONS to support MOAC
             po_line_locations_all    poll,
             po_lines_all             pol,
             po_headers_all           poh,
             gl_code_combinations_kfv gcc,
             gl_code_combinations_kfv gcc2,
             pa_expenditure_types     pet,
             pa_projects_all          pp,
             pa_tasks                 pt,
             pa_rules                 pr,
             ap_suppliers             pv
       WHERE 1 = 1
         AND pv.vendor_id = poh.vendor_id
         AND pr.rule_name = 'CPT_LOCAL_COUTS'
         AND pol.po_line_id = pod.po_line_id
         AND poh.po_header_id = pod.po_header_id
         AND pp.project_id(+) = pod.project_id
         AND pt.task_id(+) = pod.task_id
         AND pet.expenditure_type(+) = pod.expenditure_type
         AND gcc.code_combination_id = pod.code_combination_id
         AND gcc2.code_combination_id = pod.accrual_account_id
         --AND gcc.gl_account_type = 'E'
         --AND gcc2.gl_account_type = 'E'
         AND pol.po_header_id = poh.po_header_id
         AND poh.pcard_id IS NULL
         AND poll.po_line_id = pol.po_line_id
         AND pod.line_location_id = poll.line_location_id
         AND poh.type_lookup_code IN ('STANDARD', 'BLANKET', 'PLANNED')
         AND poll.shipment_type <> 'PREPAYMENT'
         AND (p_closed_pos = 'Y' OR (poll.shipment_closed_date IS NULL OR
             poll.shipment_closed_date > l_end_date))
         AND ((NVL(poll.accrue_on_receipt_flag, 'N') = 'N' AND
             pod.destination_type_code = 'EXPENSE' AND
             NVL(pod.accrued_flag, 'N') = NVL(p_accrued_receipt, 'N')) OR
             (p_online_accruals = 'Y' AND
             poll.accrue_on_receipt_flag = 'Y' AND
             (poll.shipment_closed_date is NULL or
             (poll.shipment_closed_date > l_end_date) OR
             DECODE(poll.matching_basis,
                       'AMOUNT',
                       poll.amount_billed - poll.amount_received,
                       poll.quantity_billed - poll.quantity_received) <> 0)))
         AND DECODE(poll.matching_basis,
                    'AMOUNT',
                    pod.amount_ordered - NVL(pod.amount_cancelled, 0),
                    pod.quantity_ordered - NVL(pod.quantity_cancelled, 0)) > 0
         AND DECODE(poll.matching_basis,
                    'AMOUNT',
                    poll.amount - NVL(poll.amount_cancelled, 0),
                    poll.quantity - NVL(poll.quantity_cancelled, 0)) > 0
         AND EXISTS
       (SELECT /*+ PUSH_SUBQ NO_UNNEST */
               'Get a receipt/match for this shipment'
                FROM rcv_transactions rvt
               WHERE rvt.po_line_location_id = poll.line_location_id
                 AND rvt.transaction_type IN ('RECEIVE', 'MATCH')
                 AND rvt.transaction_date <= l_end_date)
       ORDER by poll.line_location_id; /*Order by Clause added for bug 8675502*/

    -------------------------------------------------------------------------
    -- PL/SQL tables of accrual info to be inserted in
    -- CST_PER_END_ACCRUALS_TEMP table
    -------------------------------------------------------------------------
    l_acr_dist_id_tbl           ACR_DIST_ID_TBL_TYPE;
    l_acr_shipment_id_tbl       ACR_SHIPMENT_ID_TBL_TYPE;
    l_acr_category_id_tbl       ACR_CATEGORY_ID_TBL_TYPE;
    l_acr_match_option_tbl      ACR_MATCH_OPTION_TBL_TYPE;
    l_acr_qty_received_tbl      ACR_QTY_RECEIVED_TBL_TYPE;
    l_acr_qty_billed_tbl        ACR_QTY_BILLED_TBL_TYPE;
    l_acr_accrual_qty_tbl       ACR_ACCRUAL_QTY_TBL_TYPE;
    l_acr_encum_qty_tbl         ACR_ENCUM_QTY_TBL_TYPE;
    l_acr_unit_price_tbl        ACR_UNIT_PRICE_TBL_TYPE;
    l_acr_accrual_amount_tbl    ACR_ACCRUAL_AMOUNT_TBL_TYPE;
    l_acr_encum_amount_tbl      ACR_ENCUM_AMOUNT_TBL_TYPE;
    l_acr_cur_code_tbl          ACR_CUR_CODE_TBL_TYPE;
    l_acr_cur_conv_type_tbl     ACR_CUR_CONV_TYPE_TBL_TYPE;
    l_acr_cur_conv_rate_tbl     ACR_CUR_CONV_RATE_TBL_TYPE;
    l_acr_cur_conv_date_tbl     ACR_CUR_CONV_DATE_TBL_TYPE;
    l_acr_project_id            ACR_PROJECT_ID;
    l_acr_task_id               ACR_TASK_ID;
    l_acr_expenditure_type      ACR_EXPENDITURE_TYPE;
    l_acr_date_fermeture_tache  ACR_DATE_FERMETURE_TACHE;
    l_acr_ccid_imputation       ACR_CCID_IMPUTATION;
    l_acr_ccid_provision        ACR_CCID_PROVISION;
    l_acr_segment1              ACR_SEGMENT1;
    l_acr_segment2              ACR_SEGMENT2;
    l_acr_segment6              ACR_SEGMENT6;
    l_acr_segment7              ACR_SEGMENT7;
    l_acr_new_segment6          ACR_NEW_SEGMENT6;
    l_acr_new_segment7          ACR_NEW_SEGMENT7;
    l_acr_concatenated_segments ACR_CONCATENATED_SEGMENTS;
    l_acr_pp_segment1           ACR_PP_SEGMENT1;
    l_acr_ph_segment1           ACR_PH_SEGMENT1;
    l_acr_ph_creation_date      ACR_PH_CREATION_DATE;
    l_acr_line_num              ACR_LINE_NUM;
    l_acr_project_num           ACR_PROJECT_NUM;
    l_acr_task_num              ACR_TASK_NUM;
    l_acr_ledger_id             ACR_LEDGER_ID;

    l_ctr NUMBER;
    l_use VARCHAR2(30);
  BEGIN

    -- Standard Start of API savepoint
    SAVEPOINT Create_PerEndAccruals_PVT;

    l_stmt_num := 0;

    -- Standard call to check for call compatibility
    IF NOT FND_API.Compatible_API_Call(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Initialize the period end date
    l_end_date := p_end_date + 0.99999;

    -- Loop for each distribution
    l_stmt_num := 50;

    --
    --{Specialization BUG#7296737
    --
    FOR l_distribution_rec IN c_no_vendor_no_category LOOP
      l_accrual_rec.shipment_id              := l_distribution_rec.line_location_id;
      l_accrual_rec.distribution_id          := l_distribution_rec.po_distribution_id;
      l_accrual_rec.category_id              := l_distribution_rec.category_id;
      l_accrual_rec.match_option             := l_distribution_rec.match_option;
      l_accrual_rec.currency_code            := l_distribution_rec.currency_code;
      l_accrual_rec.currency_conversion_type := l_distribution_rec.curr_conv_type;
      l_accrual_rec.currency_conversion_rate := l_distribution_rec.currency_rate;
      l_accrual_rec.currency_conversion_date := l_distribution_rec.currency_conv_date;

      l_stmt_num               := 110;
      l_accrual_rec.unit_price := l_distribution_rec.po_price +
                                  po_tax_sv.get_tax('PO',
                                                    l_distribution_rec.po_distribution_id) /
                                  l_distribution_rec.quantity_ordered;
      l_stmt_num               := 120;

      CST_PerEndAccruals_PVT.Calculate_AccrualAmount(p_api_version      => 1.0,
                                                     p_init_msg_list    => FND_API.G_FALSE,
                                                     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                                     x_return_status    => l_return_status,
                                                     x_msg_count        => x_msg_count,
                                                     x_msg_data         => x_msg_data,
                                                     p_service_flag     => l_distribution_rec.service_flag,
                                                     p_dist_qty         => l_distribution_rec.distribution_quantity,
                                                     p_shipment_qty     => l_distribution_rec.shipment_quantity,
                                                     p_end_date         => l_end_date,
                                                     x_accrual_rec      => l_accrual_rec);

      IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        l_msg_data := 'Error Occured while calculating acrual amount against the Shipment id :' ||
                      TO_CHAR(l_distribution_rec.line_location_id) ||
                      ' ,Distribution Id :' ||
                      TO_CHAR(l_distribution_rec.po_distribution_id);
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      l_stmt_num := 130;

      -- BUG#17236204
      /*
            IF ((l_accrual_rec.quantity_received > l_accrual_rec.quantity_billed)
               OR
               (l_accrual_rec.quantity_received < l_accrual_rec.quantity_billed AND
               p_calling_api = G_UNINVOICED_RECEIPT_REPORT))
      */
      IF ((l_accrual_rec.quantity_received > l_accrual_rec.quantity_billed) OR
         (l_accrual_rec.quantity_received < l_accrual_rec.quantity_billed AND
         p_calling_api = G_UNINVOICED_RECEIPT_REPORT) OR
         -- Condition to do negative Accrual
         (l_accrual_rec.quantity_received < l_accrual_rec.quantity_billed AND
         l_neg_accrual = 'Y')) THEN
        -- Get the position of the new row to be added
        l_ctr := l_acr_dist_id_tbl.COUNT + 1;

        l_acr_dist_id_tbl(l_ctr) := l_accrual_rec.distribution_id;
        l_acr_shipment_id_tbl(l_ctr) := l_accrual_rec.shipment_id;
        l_acr_category_id_tbl(l_ctr) := l_accrual_rec.category_id;
        l_acr_match_option_tbl(l_ctr) := l_accrual_rec.match_option;
        l_acr_qty_received_tbl(l_ctr) := l_accrual_rec.quantity_received;
        l_acr_qty_billed_tbl(l_ctr) := l_accrual_rec.quantity_billed;
        l_acr_accrual_qty_tbl(l_ctr) := l_accrual_rec.accrual_quantity;
        l_acr_encum_qty_tbl(l_ctr) := l_accrual_rec.encum_quantity;
        l_acr_unit_price_tbl(l_ctr) := l_accrual_rec.unit_price;
        l_acr_accrual_amount_tbl(l_ctr) := l_accrual_rec.accrual_amount;
        l_acr_encum_amount_tbl(l_ctr) := l_accrual_rec.encum_amount;
        l_acr_cur_code_tbl(l_ctr) := l_accrual_rec.currency_code;
        l_acr_cur_conv_type_tbl(l_ctr) := l_accrual_rec.currency_conversion_type;
        l_acr_cur_conv_rate_tbl(l_ctr) := l_accrual_rec.currency_conversion_rate;
        l_acr_cur_conv_date_tbl(l_ctr) := l_accrual_rec.currency_conversion_date;

        l_acr_project_id(l_ctr) := l_distribution_rec.project_id;
        l_acr_task_id(l_ctr) := l_distribution_rec.task_id;
        l_acr_expenditure_type(l_ctr) := l_distribution_rec.expenditure_type;
        l_acr_date_fermeture_tache(l_ctr) := l_distribution_rec.date_fermeture_tache;
        l_acr_ccid_imputation(l_ctr) := l_distribution_rec.ccid_imputation;
        l_acr_ccid_provision(l_ctr) := l_distribution_rec.ccid_provision;
        l_acr_segment1(l_ctr) := l_distribution_rec.segment1;
        l_acr_segment2(l_ctr) := l_distribution_rec.segment2;
        l_acr_segment6(l_ctr) := l_distribution_rec.segment6;
        l_acr_segment7(l_ctr) := l_distribution_rec.segment7;
        l_acr_new_segment6(l_ctr) := l_distribution_rec.new_segment6;
        l_acr_new_segment7(l_ctr) := l_distribution_rec.new_segment7;
        l_acr_concatenated_segments(l_ctr) := l_distribution_rec.concatenated_segments;
        l_acr_pp_segment1(l_ctr) := l_distribution_rec.pp_segment1;
        l_acr_ph_segment1(l_ctr) := l_distribution_rec.ph_segment1;
        l_acr_ph_creation_date(l_ctr) := l_distribution_rec.ph_creation_date;
        l_acr_line_num(l_ctr) := l_distribution_rec.line_num;
        l_acr_project_num(l_ctr) := l_distribution_rec.project_num;
        l_acr_task_num(l_ctr) := l_distribution_rec.task_num;
        l_acr_ledger_id(l_ctr) := l_distribution_rec.ledger_id;

      END IF;

      IF (p_calling_api = G_RECEIPT_ACCRUAL_PER_END) THEN
        CST_ReceiptAccrualPerEnd_PVT.g_accrued_dist_id_tbl(CST_ReceiptAccrualPerEnd_PVT.g_accrued_dist_id_tbl.COUNT + 1) := l_distribution_rec.po_distribution_id;
      END IF;

    END LOOP; --end of c_no_vendor_no_category loop

    -------------------------------------------------------------------------
    -- Bulk insert the data from PL/SQL tables to temp table
    -------------------------------------------------------------------------
    l_stmt_num := 140;
    FORALL l_ctr IN l_acr_dist_id_tbl.FIRST .. l_acr_dist_id_tbl.LAST
      INSERT INTO DKA_CST_PER_END_ACCRUALS_TEMP
        (shipment_id,
         distribution_id,
         category_id,
         match_option,
         quantity_received,
         quantity_billed,
         accrual_quantity,
         encum_quantity,
         unit_price,
         accrual_amount,
         encum_amount,
         currency_code,
         currency_conversion_type,
         currency_conversion_rate,
         currency_conversion_date,
         project_id,
         task_id,
         expenditure_type,
         date_fermeture_tache,
         ccid_imputation,
         ccid_provision,
         segment1_imput,
         segment2_imput,
         segment6_imput,
         segment7_imput,
         concatenated_segments,
         pp_segment1,
         ph_segment1,
         ph_creation_date,
         line_num,
         project_num,
         task_num,
         ledger_id,
         new_segment6,
         new_segment7)
      VALUES
        (l_acr_shipment_id_tbl(l_ctr),
         l_acr_dist_id_tbl(l_ctr),
         l_acr_category_id_tbl(l_ctr),
         l_acr_match_option_tbl(l_ctr),
         l_acr_qty_received_tbl(l_ctr),
         l_acr_qty_billed_tbl(l_ctr),
         l_acr_accrual_qty_tbl(l_ctr),
         l_acr_encum_qty_tbl(l_ctr),
         l_acr_unit_price_tbl(l_ctr),
         l_acr_accrual_amount_tbl(l_ctr),
         l_acr_encum_amount_tbl(l_ctr),
         l_acr_cur_code_tbl(l_ctr),
         l_acr_cur_conv_type_tbl(l_ctr),
         l_acr_cur_conv_rate_tbl(l_ctr),
         l_acr_cur_conv_date_tbl(l_ctr),
         l_acr_project_id(l_ctr),
         l_acr_task_id(l_ctr),
         l_acr_expenditure_type(l_ctr),
         l_acr_date_fermeture_tache(l_ctr),
         l_acr_ccid_imputation(l_ctr),
         l_acr_ccid_provision(l_ctr),
         l_acr_segment1(l_ctr),
         l_acr_segment2(l_ctr),
         l_acr_segment6(l_ctr),
         l_acr_segment7(l_ctr),
         l_acr_concatenated_segments(l_ctr),
         l_acr_pp_segment1(l_ctr),
         l_acr_ph_segment1(l_ctr),
         l_acr_ph_creation_date(l_ctr),
         l_acr_line_num(l_ctr),
         l_acr_project_num(l_ctr),
         l_acr_task_num(l_ctr),
         l_acr_ledger_id(l_ctr),
         l_acr_new_segment6(l_ctr),
         l_acr_new_segment7(l_ctr));

    -------------------------------------------------------------------------
    -- Check for min_accrual_amount at shipment level.
    -- If accrual_amount for a shipment is less then min_accrual_amount, then
    -- delete the rows related to that shipment from the temporary table.
    -------------------------------------------------------------------------
    l_stmt_num := 150;
    DELETE FROM DKA_CST_PER_END_ACCRUALS_TEMP
     WHERE shipment_id IN
           (SELECT shipment_id
              FROM dka_cst_per_end_accruals_temp
             GROUP BY shipment_id
            HAVING SUM(accrual_amount) < NVL(p_min_accrual_amount, 0));

    -------------------------------------------------------------------------
    -- Controle des champs
    -------------------------------------------------------------------------
    FOR rec_dka_accruals_temp IN (SELECT *
                                    FROM DKA_CST_PER_END_ACCRUALS_TEMP
                                    WHERE segment1_imput = substr(p_org_name, -4)
                                      AND segment2_imput = substr(p_org_name, 0, 3)) LOOP

      DECLARE
        vv_message VARCHAR2(200);
        e_rejet_cle EXCEPTION;
        e_rejet_metier EXCEPTION;
        vd_canonical_date_next DATE;

      BEGIN

        IF rec_dka_accruals_temp.project_id IS NULL THEN
          vv_message := 'Projet manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.task_id IS NULL THEN
          vv_message := 'Tâche manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.expenditure_type IS NULL THEN
          vv_message := 'Type de dépense manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.ccid_imputation IS NULL THEN
          vv_message := 'Compte d''imputation manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.ccid_provision IS NULL THEN
          vv_message := 'Compte de provision manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.segment6_imput IS NULL THEN
          vv_message := 'Centre finance manquant';
          RAISE e_rejet_cle;
        END IF;

        IF rec_dka_accruals_temp.segment7_imput IS NULL THEN
          vv_message := 'Code affaire manquant';
          RAISE e_rejet_cle;
        END IF;

        IF TRUNC(p_accrual_effect_date) >
           TRUNC(rec_dka_accruals_temp.date_fermeture_tache) THEN
          vv_message := 'Le projet / tâche ' || rec_dka_accruals_temp.project_num || '/' || rec_dka_accruals_temp.task_num ||
                        ' n''est pas valide à la date du ' ||
                        p_accrual_effect_date;
          RAISE e_rejet_metier;
        END IF;

      --vd_canonical_date_next := TRUNC(ADD_MONTHS(p_accrual_effect_date, 1),'MONTH');

        SELECT end_date -- JWYC artf3040126 : L'extourne est créée au dernier jour de la période, donc il faut se fier à la END_DATE
        --SELECT start_date
          INTO vd_canonical_date_next
          FROM gl_period_statuses
         WHERE start_date IN (SELECT END_date + 1
                                FROM gl_period_statuses
                               WHERE period_name = p_period_name
                                 AND application_id = 101)
           AND application_id = 101
           AND ROWNUM = 1;

        IF TRUNC(vd_canonical_date_next) >
           TRUNC(rec_dka_accruals_temp.date_fermeture_tache) THEN
          vv_message := 'Imputation interdite pour le projet / tâche ' || rec_dka_accruals_temp.project_num || '/' || rec_dka_accruals_temp.task_num ||
                        ' sur un journal à extourne automatique car ce projet ne sera plus valide à la date de l''extourne ' ||
                        vd_canonical_date_next;
          RAISE e_rejet_metier;
        END IF;

      -- Calcul de la nouvelle clé d'imputation à partir des nouveaux segments
      DECLARE
        pn_code_combination_id       NUMBER;
        pn_imputation_combination_id NUMBER;
        pn_provision_combination_id  NUMBER;
        pv_errbuf                    VARCHAR2(200);
        pn_retcode                   NUMBER;
        vv_concat_seg_imput          gl_code_combinations_kfv.concatenated_segments%TYPE;
        vv_concat_seg_provi          gl_code_combinations_kfv.concatenated_segments%TYPE;

      BEGIN

        SELECT e.concatenated_segments
          INTO vv_concat_seg_imput
          FROM gl_code_combinations_kfv e
         WHERE e.code_combination_id = rec_dka_accruals_temp.ccid_imputation;

        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(vv_concat_seg_imput,
                                                                               0,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1) - 1),
                                              pv_segment2            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     1) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     2) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                1) - 1),
                                              pv_segment3            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     2) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     3) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                2) - 1),
                                              pv_segment4            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     3) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     4) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                3) - 1),
                                              pv_segment5            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     4) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     5) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                4) - 1),
                                              pv_segment6            => rec_dka_accruals_temp.new_segment6,
                                              pv_segment7            => rec_dka_accruals_temp.new_segment7,
                                              pv_segment8            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     7) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     8) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                7) - 1),
                                              pv_segment9            => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     8) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     9) - instr(vv_concat_seg_imput,
                                                                                                '.',
                                                                                                1,
                                                                                                8) - 1),
                                              pv_segment10           => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     9) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     10) - instr(vv_concat_seg_imput,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 9) - 1),
                                              pv_segment11           => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(vv_concat_seg_imput,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(vv_concat_seg_imput,
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(vv_concat_seg_imput) -
                                                                               instr(vv_concat_seg_imput,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');

        pn_imputation_combination_id := pn_code_combination_id;
        pn_code_combination_id       := NULL;

        IF pn_retcode <> 0 THEN
          RAISE e_rejet_cle;
        END IF;

        -- Calcul de la nouvelle clé de provision à partir des nouveaux segments
         SELECT e.concatenated_segments
           INTO vv_concat_seg_provi
           FROM gl_code_combinations_kfv e
          WHERE e.code_combination_id = rec_dka_accruals_temp.ccid_provision;

        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(vv_concat_seg_provi,
                                                                               0,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1) - 1),
                                              pv_segment2            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     1) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     2) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                1) - 1),
                                              pv_segment3            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     2) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     3) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                2) - 1),
                                              pv_segment4            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     3) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     4) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                3) - 1),
                                              pv_segment5            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     4) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     5) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                4) - 1),
                                              pv_segment6            => --rec_dka_accruals_temp.new_segment6,
                                                                        substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     5) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     6) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                5) - 1),
                                              pv_segment7            => rec_dka_accruals_temp.new_segment7,
                                              pv_segment8            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     7) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     8) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                7) - 1),
                                              pv_segment9            => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     8) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     9) - instr(vv_concat_seg_provi,
                                                                                                '.',
                                                                                                1,
                                                                                                8) - 1),
                                              pv_segment10           => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     9) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     10) - instr(vv_concat_seg_provi,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 9) - 1),
                                              pv_segment11           => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(vv_concat_seg_provi,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(vv_concat_seg_provi,
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(vv_concat_seg_provi) -
                                                                               instr(vv_concat_seg_provi,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');

        pn_provision_combination_id := pn_code_combination_id;
        pn_code_combination_id      := NULL;

        IF pn_retcode <> 0 THEN
          RAISE e_rejet_cle;
        END IF;

      -- Si nouvelle clé d'imputation différent de l'ancienne ou nouvelle clé de provision différent de l'ancienne alors maj
      IF pn_imputation_combination_id <> rec_dka_accruals_temp.ccid_imputation OR
         pn_provision_combination_id <> rec_dka_accruals_temp.ccid_provision  THEN

         UPDATE po_distributions t
            SET t.code_combination_id = pn_imputation_combination_id,
                t.ACCRUAL_ACCOUNT_ID = pn_provision_combination_id,
                t.VARIANCE_ACCOUNT_ID = pn_imputation_combination_id
          WHERE t.PO_DISTRIBUTION_ID = rec_dka_accruals_temp.distribution_id;

      END IF;

      EXCEPTION
        WHEN OTHERS THEN
        RAISE e_rejet_cle;

      END;

        -- maj dans po_distributions des 3 clés (note:écart = imputation)

      EXCEPTION
        WHEN e_rejet_cle THEN
          Dka_Tools_Pkg.put_log_message('REJET CLE : ' || vv_message || ' (N°commande: ' || rec_dka_accruals_temp.ph_segment1 || ')');

          UPDATE po_distributions t
             SET t.accrued_flag = 'Y'
           WHERE t.PO_DISTRIBUTION_ID =
                 rec_dka_accruals_temp.distribution_id;

        WHEN e_rejet_metier THEN
          Dka_Tools_Pkg.put_debug_message('REJET METIER : ' || vv_message|| ' (N°commande: ' || rec_dka_accruals_temp.ph_segment1 || ')');

          UPDATE po_distributions t
             SET t.accrued_flag = 'Y'
           WHERE t.PO_DISTRIBUTION_ID =
                 rec_dka_accruals_temp.distribution_id;

          INSERT INTO dka_spocharge_errors
          VALUES
            (rec_dka_accruals_temp.segment1_imput,
             rec_dka_accruals_temp.segment2_imput,
             substr(p_org_name,-4),
             rec_dka_accruals_temp.ph_segment1,
             rec_dka_accruals_temp.ph_creation_date,
             rec_dka_accruals_temp.line_num,
             rec_dka_accruals_temp.pp_segment1,
             rec_dka_accruals_temp.expenditure_type,
             rec_dka_accruals_temp.concatenated_segments,
             NULL,
             NULL,
             rec_dka_accruals_temp.distribution_id,
             vv_message,
             SYSDATE,
             Fnd_Global.user_id,
             SYSDATE,
             Fnd_Global.user_id,
             gn_login_id,
             gn_conc_request_id);

      END;

    END LOOP;

    -- date_fermeture_tache date_fermeture_tache

    -- Procedure level log message for exit point
    IF (l_pLog) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     l_module,
                     'Create_PerEndAccruals >>');
    END IF;

    -- Get message count and if 1, return message data.
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data => x_msg_data);

    -- Standard check of p_commit.
    IF FND_API.To_Boolean(p_commit) THEN
      COMMIT WORK;
    END IF;

  EXCEPTION

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO Create_PerEndAccruals_PVT;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      IF (l_exceptionLog) THEN
        FND_LOG.STRING(FND_LOG.LEVEL_EXCEPTION,
                       l_module || '.' || l_stmt_num,
                       l_msg_data);
      END IF;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                                p_data  => x_msg_data);

    WHEN OTHERS THEN
      ROLLBACK TO Create_PerEndAccruals_PVT;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      -- Unexpected level log message
      IF (l_uLog) THEN
        FND_LOG.STRING(FND_LOG.LEVEL_UNEXPECTED,
                       l_module || '.' || l_stmt_num,
                       SQLERRM);
      END IF;

      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
        FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                l_api_name,
                                '(' || TO_CHAR(l_stmt_num) || ') : ' ||
                                SUBSTRB(SQLERRM, 1, 230));
      END IF;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                                p_data  => x_msg_data);

  END Create_PerEndAccruals;

  ---------------------------------------------------------------------------------------------------
  --  Nom           : update_gl
  --  Description   : Procédure permettant de mettre a jour les CUF au niveau des pieces GL

  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE update_gl(pv_period       IN VARCHAR2, --RBE artf2140484
                      pv_errbuf       IN OUT VARCHAR2,
                      pn_retcode      OUT NUMBER,
                      va_batches_name IN OUT Pa_Utils.Char240TabTyp) IS

  vv_next_period gl_period_statuses.period_name%TYPE;

  CURSOR cur_gl_je_lines(pv_rec_batch NUMBER) IS
    SELECT jel2.je_header_id,
           jel2.je_line_num,
           pod.project_id,
           pod.task_id,
           pod.expenditure_type,
           ROUND(DECODE(pet.unit_of_measure, 'EUR', NVL(rrs.entered_dr, rrs.entered_cr), NVL(rrs.entered_dr, rrs.entered_cr) / pla.unit_price), 5) quantity_ordered, --pod.quantity_ordered,
           'Y.E.X'
      FROM po_headers_all           poh,
           po_lines_all             pla,
           po_distributions_all     pod,
           xla_distribution_links   xdl,
           xla_ae_lines             xal,
           rcv_receiving_sub_ledger rrs,
           gl_import_references     gif,
           gl_je_lines              jel2,
           gl_je_headers            jeh,
           gl_je_batches            jeb,
           gl_code_combinations     glcc,
           pa_expenditure_types     pet
     WHERE 1 = 1
       AND xdl.ae_line_num = xal.ae_line_num
       AND xdl.ae_header_id = xal.ae_header_id
       AND xal.gl_sl_link_table = gif.gl_sl_link_table
       AND xal.gl_sl_link_id = gif.gl_sl_link_id
       AND gif.je_header_id = jel2.je_header_id
       AND gif.je_line_num = jel2.je_line_num
       AND jel2.code_combination_id = glcc.code_combination_id
       AND jel2.je_header_id = jeh.je_header_id
       AND jeh.je_batch_id = jeb.je_batch_id
       AND xdl.source_distribution_type = 'RCV_RECEIVING_SUB_LEDGER'
       AND xdl.application_id = 707
       AND rrs.reference3 = pod.po_distribution_id
       AND rrs.rcv_sub_ledger_id = xdl.source_distribution_id_num_1
       AND pod.po_header_id = poh.po_header_id
       AND pod.po_line_id = pla.po_line_id
       AND pod.expenditure_type = pet.expenditure_type
       AND jeb.name LIKE va_batches_name(pv_rec_batch)||'%'
       AND jeh.je_source = 'Cost Management' --RBE artf2140484
       AND jeh.je_category = 'Accrual' --RBE artf2140484
       AND jeh.period_name IN (pv_period,vv_next_period) --RBE artf2140484
       AND jeh.period_name = jel2.period_name
       AND (glcc.account_type = 'E' --RBE artf2140484 compte de charge
       --RBE artf2992569 et si le compte local est compte de charge d'immo
       OR (SELECT DECODE(COUNT(1), 0, 'N', 'Y')
            FROM fa_categories_vl fcv, fa_category_books fcb
           WHERE EXISTS (SELECT 1
                          FROM fa_book_controls_sec bc
                         WHERE nvl(date_ineffective, sysdate + 1) > sysdate
                           AND bc.book_type_code = fcb.book_type_code)
             AND fcv.category_id = fcb.category_id
             AND NVL(fcv.enabled_flag, 'N') = 'Y'
             AND fcb.asset_clearing_acct = glcc.segment3) = 'Y')
    ;

  BEGIN

    --RBE artf2140484
    Dka_Tools_Pkg.put_debug_message('Get next period name +');

  SELECT period_name
  INTO vv_next_period
  FROM gl_period_statuses
  WHERE start_date IN (   SELECT   END_date + 1
                            FROM gl_period_statuses
                            WHERE period_name = pv_period
                            AND application_id = 101)
  AND application_id = 101
  AND ROWNUM = 1;

    Dka_Tools_Pkg.put_log_message('update_gl +');

    FOR rec_batch IN NVL(va_batches_name.first, 0) .. NVL(va_batches_name.last,-1) LOOP

      Dka_Tools_Pkg.put_debug_message('-> Batch name: ' || va_batches_name(rec_batch) || '%');

      FOR rec_gl_je_lines IN cur_gl_je_lines(rec_batch) LOOP

        UPDATE gl_je_lines jel
           SET jel.attribute11 = rec_gl_je_lines.project_id,
               jel.attribute17 = rec_gl_je_lines.task_id,
               jel.attribute13 = rec_gl_je_lines.expenditure_type,
               jel.attribute14 = rec_gl_je_lines.quantity_ordered,
               jel.context3    = 'Y.E.X'
        WHERE jel.je_header_id = rec_gl_je_lines.je_header_id
        AND jel.je_line_num = rec_gl_je_lines.je_line_num;

        --Dka_Tools_Pkg.put_debug_message('Lignes MAJ : '||SQL%ROWCOUNT ||' pour la ligne : '||rec_gl_je_lines.je_line_num);

      END LOOP;

      COMMIT;

    END LOOP;

    Dka_Tools_Pkg.put_log_message('update_gl -');

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      Dka_Tools_Pkg.put_debug_message('Fin de la procédure update_gl : EXCEPTION OTHERS ');
  END update_gl;

  ---------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation du package
  --                  Génère l'entête du fichier de sortie

  --  PARAMETRES    :
  -- gv_je_source_name         Sortie
  -- gv_user_je_source_name    Sortie
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    v_data   dka_parameters%ROWTYPE;
    vn_dummy NUMBER(15);
    /* ETANCHEITE DALKIA 2007 */
    vv_parameter dka_parameters.parameter_name%TYPE := NULL;
    vv_sqlstmt                     VARCHAR2(250);--BBM
    vv_date_heure                  VARCHAR2(25); --BBM

  BEGIN

    -- Suppression des donnees dans les tables specifiques
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_CST_PER_END_ACCRUALS_TEMP';
    --EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_CSTPEACR_ORGID';

    Dka_Tools_Pkg.put_out_header;

    ----- Initialisation des variables -----
    vn_dummy   := 0;
    pn_retcode := 0;
    pv_errbuf  := NULL;

    /* ETANCHEITE DALKIA 2007 */
    --gn_set_of_books_id    := Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');
    gn_conc_request_id := Fnd_Global.conc_request_id;
    gn_login_id        := Fnd_Global.login_id;
    vv_date_heure := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');--BBM
    
    --<BBM
      Dka_Tools_Pkg.put_log_message('Création de la table de sauvgarde DKA.DKA_SPOCHARGE_ERRORS_' || vv_date_heure);
  vv_sqlstmt := 'CREATE TABLE DKA.DKA_SPOCHARGE_ERRORS_' || vv_date_heure || ' AS SELECT * FROM DKA.dka_spocharge_errors';
  EXECUTE IMMEDIATE vv_sqlstmt;


  COMMIT;
  
  -->BBM
    --suppression des enregistrements dans DKA_SPOCHARGE_ERRORS
    DELETE FROM dka_spocharge_errors;

    -- Récupération dans DKA_PARAMETERS de la catégorie de document désignant les provisions --
    /*
    Dka_Tools_Pkg.get_parameter('SPOCHARGE',
                                'USER_JE_CATEGORY',
                                v_data,
                                pn_retcode,
                                pv_errbuf);

    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Le type de pièce OA n''a pu être déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_user_je_category_name := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('Type de pièce ==>' ||
                                      gv_user_je_category_name);
    END IF;
    */
    -- Récupération dans DKA_PARAMETERS de l'origine désignant les achats --
    /*
    Dka_Tools_Pkg.get_parameter('SPOCHARGE',
                                'JE_SOURCE_NAME',
                                v_data,
                                pn_retcode,
                                pv_errbuf);

    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'L''origine OA n''a pu être déterminée';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_user_je_source_name := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('Origine ==>' ||
                                      gv_user_je_source_name);
    END IF;
    */
    -- Récupération dans DKA_PARAMETERS du context3 désignant Y.E.X --
    /*
    Dka_Tools_Pkg.get_parameter('SPOCHARGE',
                                'le_context3',
                                v_data,
                                pn_retcode,
                                pv_errbuf);

    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Le context3 n''a pu être déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_context3 := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('Context3 ==>' || gv_context3);
    END IF;
    */

    ----  Détermination d'un Group_id -----
    ----- Attribution un numéro de regroupement via GL_INTERFACE_CONTROL_S -----
    --   dka_tools_pkg.put_debug_message('Attribution un numéro de regroupement via GL_INTERFACE_CONTROL_S ') ;
    --   SELECT  GL_INTERFACE_CONTROL_S.NEXTVAL
    --   INTO    gn_group_id
    --   FROM    dual;

    -- Récupération dans DKA_PARAMETERS de la responsabilite de lancement des sous-traitements de SPOCHARGE --
    /* ETANCHEITE DALKIA 2007 */

    /*
    vv_parameter := 'PO_RESPONSIBILITY_KEY_' || gn_set_of_books_id;
    Dka_Tools_Pkg.get_parameter('SPOCHARGE',
                                vv_parameter,
                                v_data,
                                pn_retcode,
                                pv_errbuf);

    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'PO_RESPONSIBILITY_KEY n''a pu être déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_responsibility_key_mask := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('gv_responsibility_key_mask ==>' ||
                                      gv_responsibility_key_mask);
    END IF;
    */

    -- Vérification que les différentes responsabilités sont définies pour les 26 sociétés --
    /*  -- La table dka_active_companies n'est plus d'actualité
    SELECT COUNT (1)
      INTO   vn_dummy
      FROM   dka_active_companies dac
      WHERE  NOT EXISTS ( SELECT 1
                          FROM   fnd_responsibility fr
                          WHERE      fr.application_id = 201
                                 AND fr.responsibility_key = REPLACE (gv_responsibility_key_mask, 'XXXX', dac.NAME));

      IF vn_dummy != 0
      THEN
          pn_retcode    := 1;
          pv_errbuf     :=
                          'Toutes les responsabilités ' || gv_responsibility_key_mask || ' ne sont pas définies sur les 26 sociétés';
          dka_tools_pkg.put_debug_message (pv_errbuf);
          RETURN;
      END IF;*/

    -- Récupération dans DKA_PARAMETERS du montant minimum à prendre en compte pour le calcul des provisions --
    Dka_Tools_Pkg.get_parameter('SPOCHARGE',
                                'MONTANT_MIN',
                                v_data,
                                pn_retcode,
                                pv_errbuf);

    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Le seuil minimum pour le calcul des provisions n''a pas été déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gn_montant_min := v_data.number_value;
      Dka_Tools_Pkg.put_debug_message('Montant minimum ==>' ||
                                      gn_montant_min);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      Dka_Tools_Pkg.put_log_message('Fin de la procédure init : EXCEPTION OTHERS ');
  END init;

  -------------------------------------------------------------------------------------------------------------------------------------
  --  Nom           : run_prog_standard
  --  Description   : Procedure de lancement du traitement standard "Provisions pour réception - Fin de période"
  --  PARAMETRES    :
  -- pn_group_id              Entrée
  -- pn_interface_run_id       Entrée
  -- pn_request_id            Sortie
  -- pv_errbuf                 Entrée/Sortie    message d'erreur
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------------------------------------------------------------
  -- PHENIX 2004
  -- Modification de l'appel à la procédure " fnd_global.apps_initialize ".

  PROCEDURE run_prog_standard(pv_period_name IN VARCHAR2,
                              pv_errbuf      OUT VARCHAR2,
                              pn_retcode     OUT NUMBER) IS

    vn_request_id        fnd_concurrent_requests.request_id%TYPE;
    va_request_ids       Pa_Utils.idtabtyp;
    vn_compteur          NUMBER(15);
    vn_erreur            NUMBER(15);
    vn_responsibility_id fnd_responsibility.responsibility_id%TYPE;
    vn_application_id    fnd_application.application_id%TYPE;
    vv_phase             VARCHAR2(10);
    vv_status            VARCHAR2(10);
    vv_dev_phase         VARCHAR2(10);
    vv_dev_status        VARCHAR2(10);
    vv_errbuf            VARCHAR2(150);
    e_resp_err           EXCEPTION;
    e_period_err         EXCEPTION;
    --e_next_rec         EXCEPTION;
    l_api_name           CONSTANT VARCHAR2(30) := 'Start_process';
    l_api_version        CONSTANT NUMBER := 1.0;
    l_return_status      VARCHAR2(1);
    l_msg_count          NUMBER;
    l_msg_data           VARCHAR2(240);
    l_legal_entity       NUMBER;
  vn_end_date          DATE; --SELO
    accrual_cutoff_date  DATE;
    accrual_effect_date  DATE;
    vn_period_end_date   DATE;
    vv_check_period      BOOLEAN := TRUE;
    --vb_reduction_26        VARCHAR2 (1);

    -- Récupération des org_id de lancement du traitement standard : Provisions pour réceptions-fin de période --
    CURSOR cur_select_org_id IS
      SELECT haou.NAME, haou.organization_id, haou.set_of_books_id
        FROM hr_operating_units haou,
             financials_system_parameters FSP
       WHERE haou.organization_id = fsp.org_id;
        -- RBE artf2140484
        /*
        SELECT   hou.name,hou.ORGANIZATION_ID
    FROM     PER_SECURITY_PROFILES psp,
         PER_SECURITY_ORGANIZATIONS pso,
         HR_OPERATING_UNITS hou
    WHERE    pso.SECURITY_PROFILE_ID = psp.SECURITY_PROFILE_ID
       AND   pso.ORGANIZATION_ID = hou.ORGANIZATION_ID
       AND   psp.SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL'); */

    --MEG 20/04/2017
    /*CURSOR cur_primary_ledger IS
      SELECT gl.ledger_id
        FROM gl_ledgers gl
       WHERE gl.ledger_category_code = 'PRIMARY';*/
    --MEG 20/04/2017
    CURSOR cur_primary_ledger IS
      SELECT gl.ledger_id
        FROM gl_ledgers gl,
             gl_access_set_ledgers gasl
       WHERE gl.ledger_category_code = 'PRIMARY'
         AND GASL.ledger_id = gl.ledger_id
         AND GASL.ACCESS_SET_ID = fnd_profile.VALUE('GL_ACCESS_SET_ID')
         AND EXISTS (SELECT 1 FROM financials_system_parameters -- JWYC artf3040126;
         WHERE set_of_books_id = gl.ledger_id)
         ;


  BEGIN

    Dka_Tools_Pkg.put_log_message('run_prog_standard +');

    ---Initialisation des variables--
    pv_errbuf   := NULL;
    pn_retcode  := 0;
    vn_compteur := 0;
    vn_erreur   := 0;

    -- On ne se limite plus aux 26 societes
    ----- Récupération option de profil pour savoir si on réduit RB aux 26 sociétés cloturant fin juin -----
    --vb_reduction_26 := fnd_profile.value('DKA_REDUCTION_26');
    --vb_reduction_26 := 'N';

    -- RG6.7 : Controle de la periode
    DECLARE
      vv_exist_period NUMBER;

    BEGIN

    Dka_Tools_Pkg.put_log_message('Verification parametrage des livres');

      FOR rec_primary_ledger IN cur_primary_ledger LOOP

        SELECT COUNT(1)
          INTO vv_exist_period
          FROM gl_period_statuses           GL_PER,
               gl_period_statuses           PO_PER,
               gl_period_statuses           AP_PER,
               financials_system_parameters FSP
         WHERE PO_PER.application_id = 201
           AND PO_PER.set_of_books_id = FSP.set_of_books_id
           AND PO_PER.closing_status = 'O'
           AND PO_PER.period_name = GL_PER.period_name
           AND AP_PER.application_id = 200
           AND AP_PER.set_of_books_id = FSP.set_of_books_id
           AND AP_PER.closing_status = 'C'
           AND AP_PER.period_name = GL_PER.period_name
           AND GL_PER.set_of_books_id = FSP.set_of_books_id
           AND GL_PER.application_id = 101
           AND GL_PER.closing_status in ('O', 'F')
           AND GL_PER.period_name = pv_period_name
           AND GL_PER.ledger_id = rec_primary_ledger.ledger_id;

        IF vv_exist_period = 0 THEN
          vv_check_period := FALSE;
        END IF;

      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        vv_check_period := FALSE;
    END;

    IF NOT vv_check_period THEN
      RAISE e_period_err;
    END IF;

    Dka_Tools_Pkg.put_log_message('Lancement du programme standard pour chaque UO');

    -- Lancement du traitement standard Provisions pour réceptions-fin de période dans chaque org_id --
    FOR rec_select_org_id IN cur_select_org_id LOOP

      BEGIN
        /*
        IF (vb_reduction_26 = 'Y')
        THEN
          BEGIN
            SELECT dac.name
            INTO vv_dummy
            FROM dka_active_companies dac
            WHERE dac.name = rec_select_org_id.name;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
             RAISE e_next_rec;
            WHEN OTHERS THEN
             RAISE e_next_rec;
          END;
        END IF;
        */

        Dka_Tools_Pkg.put_log_message('org_id: ' || rec_select_org_id.organization_id);

        vn_responsibility_id := 0;
        vn_application_id    := 0;

        -- On se place dans la bonne responsabilité --
        BEGIN

          SELECT fr.responsibility_id, fr.application_id, nvl(fr.end_date, to_date('31/12/4712', 'DD/MM/YYYY')) --JWYC INC0417126
            INTO vn_responsibility_id, vn_application_id, vn_end_date -- SELO : INC0385497 - add vn_end_date
            FROM fnd_responsibility fr
           WHERE fr.application_id = 201 -- PO
                --AND fr.responsibility_key = gv_responsibility_key_mask -- PHENIX 2004: REPLACE (gv_responsibility_key_mask, 'XXXX', rec_select_org_id.NAME) -> gv_responsibility_key_mask.
             AND fr.responsibility_key =
                 upper(rec_select_org_id.NAME) || '_PO_ADMINISTRATEUR';

        EXCEPTION
          WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Echec recherche responsabilité ' ||
              rec_select_org_id.NAME || ' : ' || SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      RAISE e_resp_err;

        END;
    -- SELO : INC0385497
        IF vn_end_date < trunc(sysdate) --JWYC INC0417126
      THEN
        pn_retcode := 1;
        gn_RESP_ACTIVE :='KO';
        pv_errbuf  := 'La responsabilité ' || upper(rec_select_org_id.NAME) || '_PO_ADMINISTRATEUR' || ' n''est pas active.' ;
        Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);   
        RAISE e_resp_err;
      END IF;
     -- SELO : INC0385497 - Fin 
        ----- Initialisation de l'environement OA -----
        Fnd_Global.apps_initialize(Fnd_Global.user_id,
                                   vn_responsibility_id,
                                   vn_application_id);

        Fnd_Request.set_org_id(org_id => rec_select_org_id.organization_id);
        MO_GLOBAL.INIT('PO');

        -- RG6.3 - RG6.4 : Controle sur les lignes qui vont etre selectionnees par le standard
        SELECT DECODE(SIGN(acr.start_date - SYSDATE),
                      1,
                      acr.start_date,
                      DECODE(SIGN(SYSDATE - acr.end_date),
                             1,
                             acr.end_date,
                             SYSDATE)) accrual_effect_date,
               acr.end_date
          INTO accrual_cutoff_date, accrual_effect_date
          FROM gl_period_statuses           acr,
               financials_system_parameters fsp,
               gl_sets_of_books             sob
         WHERE acr.application_id = 201
           AND acr.set_of_books_id = fsp.set_of_books_id
           AND acr.period_name = pv_period_name
           AND fsp.set_of_books_id = sob.set_of_books_id
           AND fsp.org_id = rec_select_org_id.organization_id
           AND fsp.set_of_books_id = rec_select_org_id.set_of_books_id
               /*(SELECT MAX(ledger_id)
                  from gl_ledgers
                 where name =
                       mo_utils.Get_Ledger_Name(rec_select_org_id.organization_id))*/
           AND acr.adjustment_period_flag = 'N';

        SELECT TO_NUMBER(org_information2)
          INTO l_legal_entity
          FROM hr_organization_information
         WHERE organization_id = rec_select_org_id.organization_id
           AND org_information_context = 'Operating Unit Information';

        vn_period_end_date := INV_LE_TIMEZONE_PUB.GET_SERVER_DAY_TIME_FOR_LE(accrual_cutoff_date,
                                                                             l_legal_entity);

        Create_PerEndAccruals(p_api_version         => 1.0,
                              p_init_msg_list       => FND_API.G_FALSE,
                              p_commit              => FND_API.G_FALSE,
                              p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
                              x_return_status       => l_return_status,
                              x_msg_count           => l_msg_count,
                              x_msg_data            => l_msg_data,
                              p_min_accrual_amount  => gn_montant_min,
                              p_vendor_id           => NULL,
                              p_category_id         => NULL,
                              p_end_date            => vn_period_end_date,
                              p_accrued_receipt     => 'N',
                              p_online_accruals     => 'N',
                              p_closed_pos          => 'N',
                              p_calling_api         => CST_PerEndAccruals_PVT.G_RECEIPT_ACCRUAL_PER_END,
                              p_accrual_effect_date => accrual_effect_date,
                              p_org_name            => rec_select_org_id.name,
                              p_period_name         => pv_period_name);

        --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST   --
        /*        vn_request_id := Fnd_Request.submit_request('PO', --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                              'RECEIPT_ACCRUALS', --SHORT_NAME du TRAITEMENT
                                                              NULL, --PROGRAM_NAME
                                                              NULL, --START
                                                              NULL, --SUB_REQUEST
                                                              gn_montant_min, --CDE 210409 0, -- Extended Value
                                                              NULL, -- Vendor
                                                              201, -- p_struct_num
                                                              NULL, -- Category
                                                              pv_period_name); -- Période
        */

        vn_request_id := Fnd_Request.submit_request('BOM', --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    'CSTPEACR', --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    NULL, --SUB_REQUEST
                                                    gn_montant_min, --CDE 210409 0, -- Extended Value
                                                    NULL, -- Vendor
                                                    201, -- p_struct_num
                                                    NULL, -- Category
                                                    pv_period_name); -- Période

        IF vn_request_id IS NULL THEN

          pn_retcode := 1;
          pv_errbuf  := 'Le traitement Provisions pour réceptions - fin de période n''a pas pu être lancé pour la société  ' ||
                        rec_select_org_id.NAME;
          Dka_Tools_Pkg.put_outdebug_message(pv_errbuf); 

        ELSE
          --SELO : INC0385497 Debut
          /*pv_errbuf := 'Provisions pour réceptions - fin de période  : ' ||
                       TO_CHAR(vn_request_id) || ' lancé sur la société ' ||
                       rec_select_org_id.NAME;
          Dka_Tools_Pkg.put_log_message(pv_errbuf);*/

      Dka_Tools_Pkg.put_log_message('Provisions pour réceptions - fin de période  : ' ||
                       TO_CHAR(vn_request_id) || ' lancé sur la société ' ||
                       rec_select_org_id.NAME);   
      --SELO : INC0385497 Fin

          vn_compteur := vn_compteur + 1;
          va_request_ids(vn_compteur) := vn_request_id;

          --INSERT INTO DKA_CSTPEACR_ORGID VALUES (rec_select_org_id.organization_id);

        END IF;

        COMMIT;

      EXCEPTION
        /*WHEN e_next_rec THEN
        NULL;*/
        WHEN e_resp_err THEN
          Dka_Tools_Pkg.put_log_message('e_resp_err : '||SQLERRM);
        WHEN OTHERS THEN
         Dka_Tools_Pkg.put_log_message('others : '||SQLERRM); 
      END;
    END LOOP;


    Dka_Tools_Pkg.put_log_message('Attente fin traitements');
    /*********************** VERIFICATION ET ATTENTE >fin DES TRAITEMENTS  ***************************/
    ----- On part du dernier traitement lancé en pariant sur le fait que si le dernier traitement est terminé -----
    ----- il y a des chances que les précédents le soient aussi -----
    WHILE vn_compteur > 0 LOOP

      IF NOT (Fnd_Concurrent.wait_for_request(va_request_ids(vn_compteur),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_errbuf)) THEN

        Dka_Tools_Pkg.put_outdebug_message(vn_erreur ||
                                           'Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_compteur)) ||
                                           ' trop long ou tombé en erreur');
        vn_erreur := vn_erreur + 1;
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        Dka_Tools_Pkg.put_debug_message('Traitement numéro ' ||
                                        TO_CHAR(va_request_ids(vn_compteur)) ||
                                        ' correctement exécuté');
      ELSE
        Dka_Tools_Pkg.put_outdebug_message(vn_erreur ||
                                           'Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_compteur)) ||
                                           ' trop long ou tombé en erreur');
        vn_erreur := vn_erreur + 1;

      END IF; ----- >fin IF NOT -----

      vn_compteur := vn_compteur - 1;

    END LOOP;

    IF vn_erreur != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := pv_errbuf ||
                    '- Des traitements Provisions pour réceptions ¿ fin de période sont tombés en erreur';
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
    END IF;

    Dka_Tools_Pkg.put_log_message('run_prog_standard -');
  EXCEPTION
    WHEN e_period_err THEN
      pn_retcode := 2;
      pv_errbuf  := 'Le mois comptable à provisionner ne correspond pas à la periode comptable en cours ('||pv_period_name||')';
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Fin de la procédure RUN_PROG_STANDARD : EXCEPTION OTHERS ' ||
                    SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
  END run_prog_standard;

  -------------------------------------------------------------------------------------------------------------------------------------
  --  Nom           : run_prog_comptabilisation
  --  Description   : Procedure de lancement du traitement standard "Créer une comptabilisation - Receiving"
  --  PARAMETRES    :
  -- pv_period_name            Entrée
  -- pv_errbuf                 Entrée/Sortie    message d'erreur
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------------------------------------------------------------
  PROCEDURE run_prog_comptabilisation(pv_period_name  IN VARCHAR2,
                                      pv_errbuf       OUT VARCHAR2,
                                      pn_retcode      OUT NUMBER,
                                      va_batches_name IN OUT Pa_Utils.Char240TabTyp) IS

    vn_request_id              fnd_concurrent_requests.request_id%TYPE;
    va_request_ids             Pa_Utils.idtabtyp;
    vn_request_layout          BOOLEAN;
    vb_set_options             BOOLEAN;
    vn_compteur                NUMBER(15);
    vn_erreur                  NUMBER(15) := 0;
    vv_phase                   VARCHAR2(10);
    vv_status                  VARCHAR2(10);
    vv_dev_phase               VARCHAR2(10);
    vv_dev_status              VARCHAR2(10);
    vv_errbuf                  VARCHAR2(150);
    vn_application_id          NUMBER;
    vv_source_application_name VARCHAR2(240);
    vv_process_category_name   VARCHAR2(80);
    vv_y_meaning               VARCHAR2(80);
    vv_n_meaning               VARCHAR2(80);
    vv_accounting_mode         VARCHAR2(80);
    vv_accounting_mode_name    VARCHAR2(80);
    vv_batch_name              VARCHAR2(200);
    vv_compteur                NUMBER := 1;
    vv_date_de_fin             VARCHAR2(30);
    vn_app_id                  NUMBER;
    vn_resp_id                 NUMBER;
    vn_count_easylink          NUMBER := 0;
    vn_total_easylink_err      NUMBER := 0;
    e_set_options_err          EXCEPTION;

    -- Recuperation des livres correspondant aux org_id selectionnees ci-dessus
    CURSOR cur_select_ledger_id IS
      SELECT DISTINCT gl.ledger_id, gl.name
        FROM DKA_CST_PER_END_ACCRUALS_TEMP dco, gl_ledgers gl
       WHERE dco.ledger_id = gl.ledger_id;

  BEGIN

    Dka_Tools_Pkg.put_log_message('run_prog_comptabilisation +');

    ---Initialisation des variables--
    pv_errbuf   := NULL;
    pn_retcode  := 0;
    vn_compteur := 0;
    vn_erreur   := 0;

    --Positionnement du contexte
    vn_resp_id  := 0;
    vn_app_id   := 0;

    BEGIN

      SELECT fr.responsibility_id, fr.application_id
        INTO vn_resp_id, vn_app_id
        FROM fnd_responsibility fr
       WHERE fr.application_id = 201 -- PO
         AND fr.responsibility_key = 'TOUT_PO_ADMINISTRATEUR';

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := 2;
        pv_errbuf  := 'run_prog_comptabilisation Echec recherche responsabilité ' || SQLERRM;
        Dka_Tools_Pkg.put_log_message(pv_errbuf);
        RAISE;
    END;

    ----- Initialisation de l'environement OA -----
    Fnd_Global.apps_initialize(Fnd_Global.user_id,
                               vn_resp_id,
                               vn_app_id);

    Fnd_Request.set_org_id(org_id => NULL);
    MO_GLOBAL.INIT('PO');

    --> Application et Source Application
    SELECT application_id
      INTO vn_application_id
      FROM fnd_application_vl
     WHERE application_id = 707;

    --> Source Application Name
    SELECT application_name
      INTO vv_source_application_name
      FROM fnd_application_vl
     WHERE application_id = vn_application_id;

    --> Process Category Name
    SELECT xec.name
      INTO vv_process_category_name
      FROM xla_event_class_grps_vl xec
     WHERE xec.application_id = vn_application_id
       AND xec.event_class_group_code = 'RCV_TXNS';

    --> Create Accounting
    SELECT meaning
      INTO vv_y_meaning
      FROM xla_lookups
     WHERE lookup_type = 'XLA_YES_NO'
       AND lookup_code = 'Y';

    --> Error Only
    SELECT meaning
      INTO vv_n_meaning
      FROM xla_lookups
     WHERE lookup_type = 'XLA_YES_NO'
       AND lookup_code = 'N';

    -- Boucle pour le lancement du traitement "Creer une comptabilisation - Receiving"
    FOR rec_select_ledger_id IN cur_select_ledger_id LOOP

      --> Accounting Mode
      SELECT meaning, lookup_code
        INTO vv_accounting_mode_name, vv_accounting_mode
        FROM xla_lookups xlk, xla_subledger_options_v xso
       WHERE xlk.lookup_type = 'XLA_ACCOUNTING_ENTRY_STATUS'
         AND xlk.lookup_code = xso.accounting_mode_code
         AND xso.application_id = vn_application_id
         AND xso.ledger_id = rec_select_ledger_id.ledger_id;

      --> Batch Name
      DECLARE
        vn_compteur NUMBER := 1;

      BEGIN

        SELECT NVL(to_number(MAX(substr(substr(b.name,
                                           instr(b.name, '_', 1, 3) + 1),
                                    1,
                                    instr(substr(b.name,
                                                 instr(b.name, '_', 1, 3) + 1),
                                          '_',
                                          1,
                                          1) - 1))) + 1, 1)
          INTO vn_compteur
          FROM gl_je_batches b
         WHERE b.name LIKE 'PROVISION' || '_' ||
               REPLACE(rec_select_ledger_id.name, ' ', '-') || '_' ||
               pv_period_name || '_%';

        vv_batch_name := 'PROVISION' || '_' ||
                         REPLACE(rec_select_ledger_id.name, ' ', '-') || '_' ||
                         pv_period_name || '_' || vn_compteur || '_';

      EXCEPTION
        WHEN OTHERS THEN
          vv_batch_name := 'PROVISION' || '_' ||
                           REPLACE(rec_select_ledger_id.name, ' ', '-') || '_' ||
                           pv_period_name || '_' || vn_compteur || '_';
      END;

      --> Date de fin
      SELECT to_char(to_date(start_date, 'DD/MM/RRRR'), 'YYYY/MM/DD') ||
             ' 23:59:59'
        INTO vv_date_de_fin
        FROM gl_period_statuses
       WHERE effective_period_num >
             (SELECT effective_period_num
                FROM gl_period_statuses
               WHERE ledger_id = rec_select_ledger_id.ledger_id
                 AND application_id = 201
                 AND period_name = pv_period_name)
         AND ledger_id = rec_select_ledger_id.ledger_id
         AND application_id = 201
         AND rownum = 1
       ORDER BY effective_period_num;

      --==> lancement du traitement
      vb_set_options := FND_REQUEST.set_options(LANGUAGE  => 'FRENCH',
                                                TERRITORY => 'FRANCE');

      IF NOT vb_set_options THEN
        RAISE e_set_options_err;
      END IF;

      vn_request_layout := FND_REQUEST.add_layout('BOM',
                                                  'CSTCRACCRCV',
                                                  'fr',
                                                  '00',
                                                  'PDF');

      IF vn_request_layout THEN

        vn_request_id := Fnd_Request.submit_request('BOM', --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    'CSTCRACCRCV', --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    NULL, --SUB_REQUEST
                                                    vn_application_id, -- Application
                                                    vn_application_id, -- Source Application
                                                    'Y', -- Dummy Parameter 0
                                                    rec_select_ledger_id.ledger_id, -- Ledger
                                                    'RCV_TXNS', -- Process Category
                                                    vv_date_de_fin, -- End Date
                                                    'Y', -- Create Accounting Flag
                                                    'Y', -- Dummy Parameter 1
                                                    vv_accounting_mode, -- Accounting Mode
                                                    'Y', -- Dummy Parameter 2
                                                    'N', -- Errors Only Flag
                                                    'S', -- Report
                                                    'Y', -- Transfer to GL Flag
                                                    'Y', -- Dummy Parameter 3
                                                    'N', -- Post to GL Flag
                                                    vv_batch_name, -- GL Batch Name
                                                    NULL, -- Mixed Currency Precision
                                                    'N', -- Include Zero Amt Lines Flag
                                                    NULL, -- Request ID
                                                    NULL, -- Entity ID
                                                    vv_source_application_name, -- Source Application Name
                                                    vv_source_application_name, -- Application Name
                                                    rec_select_ledger_id.name, -- Ledger Name
                                                    vv_process_category_name, -- Process Category Name
                                                    vv_y_meaning, -- Create Accounting
                                                    vv_accounting_mode_name, -- Accounting Mode Name
                                                    vv_n_meaning, -- Errors Only
                                                    'Synthèse', -- Report Level
                                                    vv_y_meaning, -- Transfer to GL
                                                    vv_n_meaning, -- Post in GL
                                                    vv_n_meaning, -- Include Zero Amount Lines
                                                    NULL, -- Valuation Method
                                                    NULL, -- Security ID Integer 1
                                                    NULL, -- Security ID Integer 2
                                                    NULL, -- Security ID Integer 3
                                                    NULL, -- Security ID Char 1
                                                    NULL, -- Security ID Char 2
                                                    NULL, -- Security ID Char 3
                                                    NULL, -- Concurrent Request ID
                                                    NULL, -- P_INCLUDE_USER_TRX_ID_FLAG
                                                    vv_y_meaning, -- P_INCLUDE_USER_TRX_IDENTIFIERS
                                                    NULL -- P_DEBUG_FLAG
                                                    );

        COMMIT;

      END IF;

      IF vn_request_id IS NULL THEN

        pn_retcode := 1;
        pv_errbuf  := 'Le traitement Créer une comptabilisation - Receiving n''a pas pu être lancé pour la société  ' ||
                      rec_select_ledger_id.NAME;
        Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);

      ELSE

        Dka_Tools_Pkg.put_log_message('Créer une comptabilisation - Receiving  : ' ||
                     TO_CHAR(vn_request_id) || ' lancé sur le livre ' ||
                     rec_select_ledger_id.name);

        vn_compteur := vn_compteur + 1;
        va_request_ids(vn_compteur) := vn_request_id;
        va_batches_name(vn_compteur) := vv_batch_name;

      END IF;

      vv_compteur := vv_compteur + 1;

    END LOOP;

    /*********************** VERIFICATION ET ATTENTE >fin DES TRAITEMENTS  ***************************/
    ----- On part du dernier traitement lancé en pariant sur le fait que si le dernier traitement est terminé -----
    ----- il y a des chances que les précédents le soient aussi -----
    WHILE vn_compteur > 0 LOOP

      IF NOT (Fnd_Concurrent.wait_for_request(va_request_ids(vn_compteur),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_errbuf)) THEN

        Dka_Tools_Pkg.put_outdebug_message(vn_erreur ||
                                           'Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_compteur)) ||
                                           ' trop long ou tombé en erreur');
        vn_erreur := vn_erreur + 1;
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        Dka_Tools_Pkg.put_debug_message('Traitement numéro ' ||
                                        TO_CHAR(va_request_ids(vn_compteur)) ||
                                        ' correctement exécuté');
      ELSE
        Dka_Tools_Pkg.put_outdebug_message(vn_erreur ||
                                           'Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_compteur)) ||
                                           ' trop long ou tombé en erreur');
        vn_erreur := vn_erreur + 1;

      END IF; ----- >fin IF NOT -----

      -- Recherche des Easylink en avertissement ou en erreur
      SELECT COUNT(1)
        INTO vn_count_easylink
        FROM fnd_concurrent_requests fcr, fnd_concurrent_programs_vl fcp
       WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
         AND fcp.concurrent_program_name = 'GLLEZL'
         AND fcr.status_code IN ('E', 'G')
       START WITH fcr.request_id = va_request_ids(vn_compteur)
      CONNECT BY PRIOR fcr.request_id = fcr.parent_request_id;

      vn_compteur := vn_compteur - 1;
      vn_total_easylink_err := vn_total_easylink_err + vn_count_easylink;

    END LOOP;

    IF vn_erreur != 0 THEN
      pn_retcode := 2; --1; JWYC artf3040126
      pv_errbuf  := pv_errbuf ||
                    '- Des traitements Créer une comptabilisation - Receiving sont tombés en erreur';
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
    END IF;

    IF vn_total_easylink_err > 0 THEN
      gb_err_easylink := TRUE;
    END IF;

    Dka_Tools_Pkg.put_log_message('run_prog_comptabilisation -');

  EXCEPTION
    WHEN e_set_options_err THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur set_print_options :' || SQLERRM;
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Fin de la procédure RUN_PROG_COMPTABILISATION : EXCEPTION OTHERS' ||
                    SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
  END run_prog_comptabilisation;

  ---------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du specifique SPOCHARGE
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
                 pv_period  IN VARCHAR) IS

    vv_error_message  VARCHAR2(200);
    vn_error_code     NUMBER(15);
    va_org_ids        Pa_Utils.idtabtyp;
    va_batches_name   Pa_Utils.Char240TabTyp;
    e_check_period    EXCEPTION;
    e_check_easylink  EXCEPTION;

  BEGIN

    Dka_Tools_Pkg.put_log_message('main +');
    vn_error_code := 0;

    /* ETANCHEITE DALKIA 2007 */
    /*
    IF gn_org_id IS NULL THEN
      dka_tools_pkg.put_log_message('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
      pv_errbuf  := 'L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée';
      pn_retcode := 2;
      RETURN;
    END IF;
    */

    /* ETANCHEITE DALKIA 2007 */
    --IF gn_set_of_books_id IS NULL THEN
    /*
    IF gn_ledger_id IS NULL THEN
      dka_tools_pkg.put_log_message('L''option de profil 1_Nom de l''entité comptable GL n''est pas paramétrée');
      pv_errbuf  := 'L''option de profil 1_Nom de l''entité comptable GL n''est pas paramétrée';
      pn_retcode := 2;
      RETURN;
    END IF;
    */
    /************************** INITIALISATION **************************/
    init(pv_errbuf, pn_retcode);

    IF pn_retcode != 0 THEN
      pn_retcode := 2;
      Dka_Tools_Pkg.put_log_message('init : '||pv_errbuf);
      --insertion du message d'erreur dans la table des messages d'erreurs dka_program_messages----
      Dka_Tools_Pkg.ins_prog_message(gn_conc_request_id,
                                     'SPOCHARGE',
                                     'OA',
                                     'GL_INTERFACE',
                                     NULL,
                                     NULL,
                                     NULL,
                                     'E',
                                     pv_errbuf);
      RETURN;
    END IF;

    --14/09/2007 Desactivation du calcul des CAP  Fournisseurs pour les commandes issues des contrats SSTR
    DKA_TOOLS_PKG.put_log_message('Desactivation du calcul des CAP');
    DKA_SPODISABLE_CALC_CAP_PKG.desactive_calcul_cap_sstr(pv_errbuf,
                                                          pn_retcode);
    IF pn_retcode != 0 THEN
      pn_retcode := 2;
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
      --insertion du message d'erreur dans la table des messages d'erreurs dka_program_messages----
      Dka_Tools_Pkg.ins_prog_message(gn_conc_request_id,
                                     'SPOCHARGE',
                                     'OA',
                                     'PO_DISTRIBUTIONS_ALL',
                                     NULL,
                                     NULL,
                                     NULL,
                                     'E',
                                     pv_errbuf);
      RETURN;
    END IF;

    -- APPEL DE LA PROCEDURE DU LANCEMENT DU TRAITEMENT STANDARD Provisions pour réceptions-fin de période --
    Dka_Spocharge_Pkg.run_prog_standard(pv_period,
                                        vv_error_message,
                                        vn_error_code);

    Dka_Tools_Pkg.put_log_message('run_prog_standard, code_retour======>' || vn_error_code);

    IF vn_error_code = 2 THEN
      pv_errbuf := vv_error_message;
      RAISE e_check_period;
    END IF;

    IF vn_error_code != 0 THEN
    IF (NVL(gn_RESP_ACTIVE,'OK') <> 'KO') THEN -- SELO INC0385497
      pn_retcode := 2; --1; JWY artf3040126
      pv_errbuf  := vv_error_message ||
            '- Des traitements "Provisions pour réception - Fin de période" sont tombés en erreur';
    ELSE     -- SELO INC0385497
      pn_retcode := vn_error_code; -- SELO INC0385497
      pv_errbuf := vv_error_message ;-- SELO INC0385497
    END IF; -- SELO INC0385497
    END IF;

    -- APPEL DE LA PROCEDURE DU LANCEMENT DU TRAITEMENT STANDARD "Créer une comptabilisation - Receiving"
    Dka_Spocharge_Pkg.run_prog_comptabilisation(pv_period,
                                                vv_error_message,
                                                vn_error_code,
                                                va_batches_name);

    Dka_Tools_Pkg.put_log_message('run_prog_comptrabilisation, code_retour======>' ||
                                    vn_error_code);

    IF vn_error_code != 0 THEN
      pn_retcode := 2; --1; JWY artf3040126
      pv_errbuf  := vv_error_message ||
                    '- Des traitements "Créer une comptabilisation - Receiving" sont tombés en erreur';
       Dka_Tools_Pkg.put_log_message(pv_errbuf);             
    END IF;

    -- APPEL DE LA PROCEDURE DE MISE A JOUR DES LIGNES DANS GL_INTERFACES (création d'une pièce par société) --
    /*
    Dka_Spocharge_Pkg.update_gl_interface(vv_error_message, vn_error_code);
    Dka_Tools_Pkg.put_debug_message('vn_error_code GL_INTERFACES  ======>' ||
                                    vn_error_code);

    IF vn_error_code != 0 THEN
      pv_errbuf  := vv_error_message;
      pn_retcode := vn_error_code;
      RETURN;
    END IF;
    */

    -- APPEL DE LA PROCEDURE UPDATE_GL"
    IF va_batches_name.COUNT > 0 THEN

      Dka_Spocharge_Pkg.update_gl(pv_period, --RBE artf2140484
                                  vv_error_message,
                                  vn_error_code,
                                  va_batches_name);

      Dka_Tools_Pkg.put_log_message('update_gl, code_retour======>' ||
                                      vn_error_code);

      IF ( vn_error_code != 0 )   THEN
      pn_retcode := 2; -- 1;   JWY artf3040126
        pv_errbuf  := vv_error_message ||
                      '- Une erreur est survenue dans la procedure update_gl';
      END IF;

    END IF;

    IF gb_err_easylink THEN
      RAISE e_check_easylink;
    END IF;

    Dka_Tools_Pkg.put_log_message('main -');

  EXCEPTION
    WHEN e_check_easylink THEN
      pv_errbuf := 'Au moins un traitement Easylink est tombé en erreur.';
      pn_retcode := 2;
    WHEN e_check_period THEN
      Dka_Tools_Pkg.put_log_message('e_check_period : '||pv_errbuf);
      pn_retcode := 2;
    WHEN OTHERS THEN
      pv_errbuf := 'sortir de main avec erreur avec EXCEPTION OTHERS:' ||
                   SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      pn_retcode := 2;
  END main;

END Dka_Spocharge_Pkg;


/
SHOW ERRORS;
EXIT