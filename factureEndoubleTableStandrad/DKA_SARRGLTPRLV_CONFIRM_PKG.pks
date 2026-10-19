CREATE OR REPLACE PACKAGE BODY Dka_Sarencais_Pkg AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM           : DKA_SARENCAIS_PKG.pkb
  -- DESCRIPTION       : DKA_SARENCAIS_PKG package body :
  ---
  --- AUTEUR       : Drifa ARBOUZ (CGEY)
  --- DATE DE CREATION : 05/11/2001
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 28/02/2002 BER correction requete de selection dans get_ap_payments
  ---            (test du type fournisseur + jointure organisation-fournisseur)
  --- 15/03/2002 XD  Correction ano IAR sur la sélection des données dans get_ap_payments
  --- 15/03/2002 XD  Correction de l'appel à dka_tools_pkg.get_code_societe dans run_import
  --- 28/03/2002 XD  vn_amount_applied1 * 100
  --- 09/07/2003 XD  get_ap_payments : optimisation de la requete
  --- 23/08/2003 AD  populate_data : Modification du calcul du montant à lettrer (amount_applied1).
  ---                get_ap_payments : Correction de la requête d'insertion des données afin de 
  ---                supprimer les factures en doubles (numéro de facture) dans AR.
  ---                La procédure insert_ar_interface a été renommée en insert_ar_transmission
  ---                Appel de la proc insert_ar_interface dans insert_ar_transmission.
  ---                insert_ar_interface : Correction de l'alimentation de la table ar_payments_interface_all.
  --- 23/02/2004 AD  MAIN : Désactivation avant le lancement du post quickcash des règles d'auto-lettrages
  ---                Réactivation des régles en fin de traitement.
  ---                TIEBACK : Ajout du customer_id pour la mise à jour des lignes en rejets(jointure).
  ---                OUTPUT_STATUS : Ajout du cas pour lequel il n'y a un fournisseur inactif.
  --- 13/05/2004 CD  Procedure get_ap_payments : Modif. récup. compte bancaire. On passe par ap_checks_all
  ---                au lieu de prendre celui de ap_bank_account_uses_all (PHENIX 2004)
  --- 21/06/2004 SLE Portage spécifique pour projet PHENIX 2004 
  ---                Modification des procédures get_ap_payments, insert_ar_transmission,
  ---                insert_ar_interface, populate_data, run_import, tieback, run_report, run_all_imports 
  --- 15/07/2005 VSE Evolution pour gérer les factures reprises par SOFTAPACK, suffixées.
  --- 06/09/2005 SL  Procédure tieback : Rajout d'une condition sur la date du règlement (sur
  ---                plantage cause changement de banque et attribution d'un même numéro de règlement dans AP)
  --- 11/10/2005 SL  run_report : modification du choix de l'imprimante. Le CDG provient de la méthode d'encaissement
  ---                et non plus du site de l'encaissement
  --- 04/04/2006 SL  tieback : modification de la jointure mettant à 'R' les enregistrements
  ---                présents dans ar_payments_interface_all (remplacement de customer_id 
  ---                par customer_number)
  --- 12/09/2006 SL  Rajout de la procédure ecarter_fact et maj_data. Cette procédure détecte et écarte les factures 
  ---                portant un numéro double.Modification de insert_ar_transmission (rajout appel à ecarter_fact)
  --- 14/11/2008 SL  get_ap_payments - Ajout d'une condition pour ne prendre que les sociétés gérées sous OA, c'est à dire
  ---                les sociétés dont l'organisation est encore active
  --- 10/04/2013 BCO INC000000395045 - Insertion du parent lors du lancement du traitement d'envoi par mail paiement intra groupe AP/AR.
  --- 04/08/2016 MEG Migration R12
  --- 26/07/2017 MEG artf2202485 : SPE019 - Campagne Paiement intra Groupe AP / AR - Defect 718
  --- 26/07/2017 MEG artf2207554 : SPE019 - Aucune facture sélectionnée - defect BeB # 1036
  --- 26/09/2017 RBE artf2226321 : SPE019 - Campagne Paiement intra Groupe AP / AR
  --- 08/03/2018 RBE artf2418217 : INC0191600 : SPE019 - Campagne de paiement intra Groupe AP/AR 
  --- 16/05/2018 MEG artf2642415 : INC0191600 : SPE019 - Campagne de paiement intra Groupe AP/AR
  --- 06/07/2018 OBE artf2848298 : INCXXXXXX - SPE019 - Traitement IntraGroupe - Si facture existe pas dans AR on crée le Reglt dans Région Principale 
  --- 07/07/2020 MTIA artf07390929 : INC0439507 - traitement Encaissement IntraGroupe AP/AR - Ne pas créer les règlements non identifié 
  --------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --                              VARIABLES GLOBALES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gv_type_four             dka_parameters.varchar2_value%TYPE;
  gv_status                dka_parameters.varchar2_value%TYPE;
  gv_type_regl             dka_parameters.varchar2_value%TYPE;
  gv_format                dka_parameters.varchar2_value%TYPE;
  gv_ar_responsibility_key fnd_responsibility.responsibility_key%TYPE;
  gn_request_id            fnd_concurrent_requests.request_id%TYPE;
  gv_origine               ar_batch_sources_all.name%TYPE := 'PAIEMENT_INTRAGROUPE'; -- PHENIX 2004 
  gv_user_softa            fnd_user.user_name%TYPE := 'SOFTAPACK'; -- PHENIX 2005 User SOFTAPACK

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --                               PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation des variables globales du package
  --
  --  PARAMETRES    :
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK  ou 2: erreur
  ------------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    rec_param dka_parameters%ROWTYPE;
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    ----- Initialisation du fichier de sortie
    Dka_Tools_Pkg.put_out_header;

    Dka_Tools_Pkg.put_debug_message('début de la procédure INIT');
    ----- Initialisation des variables globales -----

    gn_request_id := Fnd_Global.conc_request_id;

    Dka_Tools_Pkg.get_parameter('SARENCAIS',
                                'TYPE_FOUR',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_type_four := rec_param.varchar2_value;
    Dka_Tools_Pkg.put_debug_message('gv_type_four : ' || gv_type_four);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'TYPE_FOUR ' || pv_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('SARENCAIS',
                                'STATUS',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_status := rec_param.varchar2_value;
    Dka_Tools_Pkg.put_debug_message('gv_status : ' || gv_status);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'STATUS ' || pv_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('SARENCAIS',
                                'TYPE_REGL',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_type_regl := rec_param.varchar2_value;
    Dka_Tools_Pkg.put_debug_message('gv_type_regl : ' || gv_type_regl);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'TYPE_REGL ' || pv_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('SARENCAIS',
                                'FORMAT',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_format := rec_param.varchar2_value;
    Dka_Tools_Pkg.put_debug_message('gv_format : ' || gv_format);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'FORMAT ' || pv_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('SARENCAIS',
                                'AR_RESPONSIBILITY_KEY',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_ar_responsibility_key := rec_param.varchar2_value;
    Dka_Tools_Pkg.put_debug_message('gv_ar_responsibility_key : ' ||
                                    gv_ar_responsibility_key);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'AR_RESPONSIBILITY_KEY ' || pv_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.put_debug_message('Fin de la procédure INIT');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END init;

  ----------------------------------------------------------------------------------------
  --  Nom           : get_ap_payments
  --  Description   : Procédure d'insertion dans la table dka_sarencais_tmp des réglments ayant
  --          les caractéristiques suivantes :
  --          - Type de fournisseurs partenaire/société sur système
  --          - Tous les règlements sont des virements
  --          - Le règlement doit être en status 'Négociable'
  --
  --  PARAMETRES    :
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------
  --- PHENIX 2004 
  --- Remplacement du SUBSTR (gcc.segment1, 1, 3) par gcc.segment2 
  --- Suppression de la jointure entre les tables " hr_all_organization_units " et " ap_bank_accounts_all "
  --- Remplacement de la valeur de la colonne " ap_org_id " par " l'organization_id " 
  --- de la société formant les 4 premiers caractères de la colonne " doc_category_code " de la table " ap_checks_all ".
  --- Migration R12

  PROCEDURE get_ap_payments(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER) IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début GET_AP_PAYMENTS');

    ---Suppression de toutes les lignes ayant un status à A, R, W et P
    DELETE dka_sarencais_tmp dst WHERE dst.status IN ('A', 'R', 'W', 'P');

    Dka_Tools_Pkg.put_debug_message('Suppression dans DKA_SARENCAIS_TMP : ' ||
                                    SQL%ROWCOUNT);

    -- Alimentation de la table temporaire : 1 ligne de réglement pour 1 factures
    INSERT INTO dka_sarencais_tmp
      (check_id,
       vendor_id,
       amount,
       check_number,
       vendor_name,
       bank_account_id,
       bank_account_num, --Numéro du compte bancaire utilisé pour le calcul de lockbox_number = vv_code _societe||vn_bank_account_num
       vendor_site_code,
       bank_acct_area, --centre de gestion du compte GL correspondant au compte bancaire
       bank_segment3,
       invoice_id,
       check_date,
       ap_gl_date,
       invoice_payment_id,
       payment_num,
       payment_status_flag,
       trx_number,
       customer_trx_id,
       invoice_num,
       invoice1,
       invoice2, -- Non renseigné
       invoice3, -- Non renseigné
       invoice4, -- Non renseigné
       invoice5, -- Non renseigné
       invoice6, -- Non renseigné
       invoice7, -- Non renseigné
       invoice8, -- Non renseigné
       amount_applied1,
       amount_applied2, -- Non renseigné
       amount_applied3, -- Non renseigné
       amount_applied4, -- Non renseigné
       amount_applied5, -- Non renseigné
       amount_applied6, -- Non renseigné
       amount_applied7, -- Non renseigné
       amount_applied8, -- Non renseigné
       status,
       rejection_reason,
       transmission_record_id,
       remittance_amount,
       receipt_date,
       ACCOUNT,
       customer_number,
       ar_check_number,
       gl_date,
       customer_id,
       receipt_method_id,
       customer_site_use_id,
       customer_bank_account_id,
       remittance_bank_name,
       request_id,
       ap_org_id,
       ar_org_id,
       attribute2,
       ledger_id,
       exchange_date,
       exchange_rate,
       exchange_rate_type,
       currency_code)
    SELECT aca.check_id,
             aia.vendor_id,
             aca.amount,
             aca.check_number,
             aca.vendor_name,
             cba_to.bank_account_id,
             cba_to.bank_account_num,
             /*aca*/pvs.vendor_site_code,
             gcc2.segment2, -- bank_acct_area
             gcc2.segment3,
             aia.invoice_id,
             aca.check_date,
             aipa.accounting_date,
             aipa.invoice_payment_id,
             aipa.payment_num,
             'Y', --aia.payment_status_flag,
             NULL, --rct.trx_number,
             NULL, --rct.customer_trx_id,
             -- PHENIX 2005 Gestion des intragroupes repris lors de la migration et suffixés
             DECODE(fu.user_name,
                    /*gv_user_softa*/
                    NULL,
                    SUBSTR(SUBSTR(aia.invoice_num,
                                  1,
                                  LENGTH(aia.invoice_num) - 5),
                           1,
                           20),
                    SUBSTR(aia.invoice_num, 1, 20)), -- 25c dans AP et 20c dans AR! 
             NULL, --invoice1
             NULL, --invoice2
             NULL, --invoice3
             NULL, --invoice4
             NULL, --invoice5
             NULL, --invoice6
             NULL, --invoice7
             NULL, --invoice8
             aipa.amount, --amount_applied1,
             NULL, --amount_applied2,
             NULL, --amount_applied3,
             NULL, --amount_applied4,
             NULL, --amount_applied5,
             NULL, --amount_applied6,
             NULL, --amount_applied7,
             NULL, --amount_applied8,
             'P', --status
             NULL, --rejection_reason
             NULL, --transmission_record_id
             NULL, --remittance_amount
             NULL, --receipt_date
             NULL, --account
             NULL, --customer_number
             NULL, --ar_check_number
             NULL, --gl_date
             NULL, --customer_id
             NULL, --receipt_method_id
             NULL, -- customer_site_use_id
             NULL, --customer_bank_account_id
             NULL, --request_id
             NULL, --remittance_bank_name
             aca.org_id, --ap_org_id  PHENIX 2004 
             -1,--hou.organization_id, --ar_org_id
             gcc.segment5, --Code interco correspondant au code partenaire du site fournisseur
              (SELECT ledger_id from gl_ledgers where short_name = substr(gcc.segment5,-4)) ledger_id, --aia.set_of_books_id,
             aca.exchange_date,
             aca.exchange_rate,
             aca.exchange_rate_type,
             aca.currency_code
        FROM ap_checks_all             aca,
             ap_invoices               aia,
             fnd_user                  fu,
             ap_suppliers              pv,
             ap_supplier_sites_all     pvs,
             ap_invoice_payments_all   aipa,
             ce_bank_accounts          cba_from,
             ce_bank_accounts          cba_to,
             gl_code_combinations      gcc,
             gl_code_combinations      gcc2,
             --hr_all_organization_units hou, -- OBE artf2848298
			 /*,ce_bank_acct_uses_all     cbaua*/
             hr_all_organization_units hou_ap --rbe artf2418217
       WHERE 1 = 1
         AND aca.vendor_site_id = aia.vendor_site_id
         AND aca.vendor_id = aia.vendor_id
         AND aca.org_id = aia.org_id
         AND aia.org_id = hou_ap.organization_id --RBE artf2418217
         AND fu.user_id = aia.created_by
         AND pv.vendor_id = aia.vendor_id
         AND pv.vendor_id = pvs.vendor_id
         AND aca.vendor_site_id = pvs.vendor_site_id
         AND cba_from.bank_account_num = aca.bank_account_num
         AND cba_from.account_classification = 'INTERNAL'
         AND cba_from.bank_branch_id = cba_to.bank_branch_id
         AND cba_from.bank_account_num = cba_to.bank_account_num
         AND cba_to.account_classification = 'INTERNAL'
         AND SYSDATE BETWEEN nvl(cba_from.start_date,SYSDATE) AND nvl(cba_from.end_date,SYSDATE)
         AND SYSDATE BETWEEN nvl(cba_to.start_date,SYSDATE) AND nvl(cba_to.end_date,SYSDATE)
         AND pvs.accts_pay_code_combination_id = gcc.code_combination_id
         AND gcc2.code_combination_id = cba_to.asset_code_combination_id
         AND aca.payment_method_code = gv_type_regl --Les reglements sont tous des virements
         AND aca.payment_type_flag = 'A' --A=Automatique, M=Manuel
         AND aca.status_lookup_code = gv_status --Le reglement doit etre de status Negociable
         AND pv.vendor_type_lookup_code = gv_type_four -- Les fournisseurs sont de type Partenaire
         AND aipa.invoice_id = aia.invoice_id
         AND aca.check_id = aipa.check_id
         --AND hou.name = substr(hou_ap.name, 1,3) || substr(gcc.segment5, -4) --RBE artf2418217       -- OBE artf2848298
         --AND nvl(hou.date_to, trunc(sysdate)) >= trunc(sysdate) --La societe doit encore être active -- OBE artf2848298
         AND EXISTS (SELECT 1
                       FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv 
                      WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE' 
                        AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                        AND sysdate BETWEEN NVL(ffv.start_date_active,sysdate) AND nvl(end_date_active,sysdate)
                        AND ffv.enabled_flag = 'Y'
                        AND substr(gcc.segment5, -4) = ffv.flex_value)
         AND aca.attribute10 IS NULL;

    Dka_Tools_Pkg.put_debug_message('Insertion dans DKA_SARENCAIS_TMP : ' ||
                                    SQL%ROWCOUNT);
    Dka_Tools_Pkg.put_debug_message('Fin de la procédure GET_AP_PAYMENTS');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : GET_AP_PAYMENTS');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END get_ap_payments;

  ------------------------------------------------------------------------------------
  --  Nom           : get_ar_period_date_f
  --  Description   : Renvoie la date de fin de la premiere periode ouverte AR
  --                  par rapport a une date de reference D
  --                  (ie la 1ère période AR ouverte, par ordre chrono, dont la date de fin est >= D)
  --
  --  PARAMETRES    :
  --      pd_ref_date                 Entree
  --      pn_set_of_books_id          Entree

  --  VALEUR RETOURNEE :
  --     Description       : Date de fin de la premiere periode ouverte
  --     Valeurs possibles : 
  -------------------------------------------------------------------------------------
  FUNCTION get_ar_period_date_f(pd_ref_date        IN DATE,
                                pn_set_of_books_id IN NUMBER) RETURN DATE IS

    ld_date           DATE;
    ln_application_id NUMBER := 222;

  BEGIN

    SELECT MIN(gps.end_date)
      INTO ld_date
      FROM gl_period_statuses gps
     WHERE gps.application_id = ln_application_id
       AND gps.adjustment_period_flag = 'N' -- on ne prend pas les periodes d'ajustement
       AND gps.closing_status = 'O' -- periodes ouvertes
       AND gps.set_of_books_id = pn_set_of_books_id -- restrictions sur le set_of_books_id
       AND gps.end_date >= NVL(pd_ref_date, gps.end_date);

    RETURN ld_date;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END get_ar_period_date_f;

  ---------------------------------------------------------------------------------------
  --  Nom           : get_customer_partner
  --  Description   : Procédure permettant d'obtenir les identifiants du client, addresse client,
  --                  et lieu de facturation 
  --
  --  PARAMETRES :
  --          pv_code_societe         Entrée
  --          pv_centre_gestion       Entrée
  --          pn_org_id               Entrée
  --          pn_customer_id          Sortie
  --          pv_customer_number      Sortie
  --          pn_customer_site_id     Sortie
  --          pn_bill_to_site_use_id  Sortie
  --          pv_errbuf               Entrée  Sortie
  --          pn_retcode              Sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : Identifiant du client + code retour de validité
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE get_customer_partner(pv_code_societe        IN VARCHAR2,
                                 pv_interco             IN VARCHAR2,
                                 pn_customer_id         OUT NUMBER,
                                 pv_customer_number     OUT VARCHAR2,
                                 pn_customer_site_id    OUT NUMBER,
                                 pn_bill_to_site_use_id OUT NUMBER,
                                 pv_bill_to_location    OUT VARCHAR2, -- RBE
                                 pv_errbuf              IN OUT VARCHAR2,
                                 pn_retcode             OUT NUMBER) IS

    CURSOR cur_customer(vv_code_societe IN VARCHAR2, vv_interco IN VARCHAR2) IS
      SELECT hca.cust_account_id,
             hca.account_number,
             hcas.cust_acct_site_id,
             hcsu.site_use_id,
             hcsu.location --RBE artf2418217
        FROM hz_cust_site_uses_all     hcsu,
             hz_cust_acct_sites_all    hcas,
             hz_cust_accounts          hca,
             hr_all_organization_units hou
       WHERE hcsu.cust_acct_site_id = hcas.cust_acct_site_id
         AND hcsu.org_id = hcas.org_id
         AND hca.cust_account_id = hcas.cust_account_id
         AND hcsu.org_id = hou.organization_id
         AND hcsu.site_use_code = 'BILL_TO'
         AND hcsu.status = 'A'
         AND hcas.status = 'A'
         --AND hca.CUSTOMER_CLASS_CODE = 'GROUPE' --RBE artf2418217
         AND hou.name = vv_interco
         AND hcas.attribute8 = vv_code_societe
       ORDER BY hcsu.primary_flag DESC, hcas.creation_date ASC;

    rec_customer cur_customer%ROWTYPE;

  BEGIN

    -- Recuperation des informations liees au client
    OPEN cur_customer(pv_code_societe, pv_interco);
    FETCH cur_customer
      INTO rec_customer;

    IF cur_customer%NOTFOUND THEN

      SELECT hca.cust_account_id,
             hca.account_number,
             hcas.cust_acct_site_id,
             hcsu.site_use_id,
             hcsu.location --RBE artf2418217
        INTO pn_customer_id,
             pv_customer_number,
             pn_customer_site_id,
             pn_bill_to_site_use_id,
             pv_bill_to_location --RBE artf2418217
        FROM hz_cust_site_uses_all     hcsu,
             hz_cust_acct_sites_all    hcas,
             hz_cust_accounts          hca,
             hr_all_organization_units hou
       WHERE hcsu.cust_acct_site_id = hcas.cust_acct_site_id
         AND hcsu.org_id = hcas.org_id
         AND hcsu.org_id = hou.organization_id
         AND hca.cust_account_id = hcas.cust_account_id
         AND hcsu.site_use_code = 'BILL_TO'
         AND hcsu.status = 'A'
         AND hcas.status = 'A'
         --AND hca.CUSTOMER_CLASS_CODE = 'GROUPE' --RBE artf2418217
         AND hou.name = pv_interco
         AND hcas.attribute8 = 'XXX' || substr(pv_code_societe, -4)
         AND ROWNUM = 1;

    ELSE
      pn_customer_id         := rec_customer.cust_account_id;
      pv_customer_number     := rec_customer.account_number;
      pn_customer_site_id    := rec_customer.cust_acct_site_id;
      pn_bill_to_site_use_id := rec_customer.site_use_id;
      pv_bill_to_location    := rec_customer.location; --RBE artf2418217
    END IF; --rec_customer%NOTFOUND

    CLOSE cur_customer;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      pv_errbuf  := 'get_customer_partner : pas de client partenaire';
      pn_retcode := 2;
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur get_customer_partner : WHEN_OTHERS  ' ||
                    SQLERRM;
      pn_retcode := 2;
  END get_customer_partner;

  ------------------------------------------------------------------------------------
  --  Nom           : check_periods
  --  Description   : Procédure permettant de savoir si la periode correspondante à la
  ---                 date de règlement AP est ouverte dans les modules AP et AR.
  --
  --  PARAMETRES    :
  --      pd_date                 Entrée
  --      pv_open_flag                    Sortie
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------
  PROCEDURE check_periods(pd_date      IN DATE,
                          pd_sob       IN NUMBER,
                          pv_open_flag OUT VARCHAR2,
                          pv_errbuf    IN OUT VARCHAR2,
                          pn_retcode   OUT NUMBER) IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure CHECK_PERIODS ');

    SELECT DECODE(closing_status, 'O', 'Y', 'N')
      INTO pv_open_flag
      FROM gl_period_statuses gps
     WHERE set_of_books_id = pd_sob --Fnd_Profile.VALUE('GL_SET_OF_BKS_ID')
       AND application_id = 200 -- AP
       AND pd_date BETWEEN start_date AND end_date;

    IF pv_open_flag = 'N' THEN
      pv_errbuf  := 'LA PERIODE COMPTABLE AP EST FERMEE';
      pn_retcode := 2;
      RETURN;
    END IF;

    SELECT DECODE(closing_status, 'O', 'Y', 'N')
      INTO pv_open_flag
      FROM gl_period_statuses gps
     WHERE set_of_books_id = pd_sob --Fnd_Profile.VALUE('GL_SET_OF_BKS_ID')
       AND application_id = 222 --AR
       AND pd_date BETWEEN start_date AND end_date;

    IF pv_open_flag = 'N' THEN
      pv_errbuf  := 'LA PERIODE COMPTABLE AR EST FERMEE';
      pn_retcode := 2;
      RETURN;
    END IF;

    Dka_Tools_Pkg.put_debug_message('Fin de la procédure CHECK_PERIODS');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : CHECK_PERIODS');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END check_periods;

  ------------------------------------------------------------------------------------
  --  Nom           : maj_data
  --  Description   : Procédure mettant à jour les enregistements de l'interface 
  --                  règlements AR, "Efface" le numéro de facture et le montant
  --
  --  PARAMETRES    :
  --      vv_invoice_num                 Entrée
  --      vv_customer_num                Entrée
  --      vv_receipt_method              Entrée
  --  vv_transmission_id         Entrée
  --  vv_item_number           Entrée
  --      vv_transmission_record_id      Entrée
  --      vv_montant                     Entrée
  --      vv_check_num                   Entrée
  --      num                            Entrée
  --      pv_errbuf                      Entrée  Sortie
  --      pv_retcode                     Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------

  PROCEDURE maj_data(vv_invoice_num            VARCHAR2,
                     --vv_customer_num           VARCHAR2, --RBE artf2418217
                     vn_customer_id            NUMBER, -- RBE artf2418217
                     vv_receipt_method         VARCHAR2,
                     vv_transmission_id        NUMBER,
                     vv_item_number            NUMBER,
                     vv_transmission_record_id NUMBER,
                     vv_montant                NUMBER,
                     vv_check_num              VARCHAR2,
                     num                       NUMBER,
                     pv_errbuf                 IN OUT VARCHAR2,
                     pn_retcode                OUT NUMBER) IS

    cpt                 NUMBER := 0;
    nb_fact             NUMBER := 0;
    Vv_Ordre_PLSQL      VARCHAR2(1000);
    vv_message          VARCHAR2(250) := '';
    vv_customer_num     ra_customers.customer_number%TYPE; --RBE artf2418217

  BEGIN

    dka_tools_pkg.put_debug_message('maj_data(+)');

    Vv_Ordre_PLSQL := '
update ar_payments_interface_all api
set    api.invoice' || to_char(num) ||
                      ' = null,
api.amount_applied' || to_char(num) ||
                      ' = null
where  api.transmission_record_id = ' ||
                      vv_transmission_record_id || '
and    api.transmission_id = ' || vv_transmission_id || '
and    api.item_number = ' || vv_item_number;


    --RBE artf2418217 : chercher le numero client
    BEGIN
        SELECT customer_number
        INTO vv_customer_num
        FROM ra_customers
        WHERE customer_id = vn_customer_id;
    EXCEPTION
        WHEN OTHERS THEN
        vv_customer_num := NULL;
    END;

    -- Recherche du nb de factures portant le même numéro pour le même client -- SI > 1 --> pb

    SELECT count(*)
      INTO cpt
      FROM ra_customer_trx_all rcta2, ra_customers rc2
     WHERE rcta2.trx_number = vv_invoice_num
       AND rc2.customer_id = rcta2.bill_to_customer_id
       --AND rc2.customer_number = vv_customer_num --RBE artf2418217
       AND rc2.customer_id = vn_customer_id --RBE artf2418217

       ;

    -- Recherche s'il existe facture portant le même nom mais sur une soc différente et s'il n'existe 
    -- pas de factures portant ce nom sur la "bonne" soc

    SELECT count(*)
      INTO nb_fact
      from ra_customer_trx_all   rcta,
           ra_customers          rc,
           ra_cust_trx_types_all rctta
     where 1 = 1
       and rcta.trx_number = vv_invoice_num
       and rcta.bill_to_customer_id = rc.customer_id
       --and rc.customer_number = vv_customer_num --RBE artf2418217
       AND rc.customer_id = vn_customer_id --RBE artf2418217
       and rctta.cust_trx_type_id = rcta.cust_trx_type_id
       and substr(rctta.name, 1, 4) != substr(vv_receipt_method, 1, 4);

    IF cpt > 1 OR ( /*cpt >= 1 AND */
        nb_fact >= 1) THEN

      apps_ddl.apps_ddl(Vv_Ordre_PLSQL);

      vv_message := RPAD(substr(vv_receipt_method, 1, 4), 7) || ' ' ||
                    RPAD(vv_check_num, 12) || ' ' ||
                    RPAD(vv_customer_num, 12) || ' ' || 
                    RPAD(vv_invoice_num, 20) || ' ' ||
                    RPAD(vv_montant / 100, 20);
      Fnd_File.put_line(Fnd_File.output, vv_message);

    END IF;
    dka_tools_pkg.put_debug_message('maj_data(-)');
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Pb dans maj_data');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END maj_data;

  ------------------------------------------------------------------------------------
  --  Nom           : ecarter_fact
  --  Description   : Procédure écartant du lettrage automatique les factures portant 
  --                 un numéro existant en double
  --
  --  PARAMETRES    :
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode              Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------
  PROCEDURE ecarter_fact(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS

    cursor cur_rglt_entete is
      select api.item_number,
             api.transmission_id,
             api.check_number,
             --api.customer_number, --RBE artf2418217
             api.customer_id, --RBE artf2418217
             api.remittance_amount,
             api.receipt_method,
             api.customer_site_use_id
        from ar_payments_interface_all api
       where 1 = 1
         and api.status = 'AR_PLB_NEW_RECORD'
         and api.record_type = '6';

    cursor cur_rglt_ligne(vv_transmission_id IN NUMBER, vv_item_number IN NUMBER) is
      select api.transmission_record_id,
             api.invoice1,
             api.amount_applied1,
             api.invoice2,
             api.amount_applied2,
             api.invoice3,
             api.amount_applied3,
             api.invoice4,
             api.amount_applied4,
             api.invoice5,
             api.amount_applied5,
             api.invoice6,
             api.amount_applied6,
             api.invoice7,
             api.amount_applied7,
             api.invoice8,
             api.amount_applied8
        from ar_payments_interface_all api
       where 1 = 1
         and api.record_type = '4'
         and api.transmission_id = vv_transmission_id
         and api.item_number = vv_item_number;

    rec_rglt_ligne  cur_rglt_ligne%ROWTYPE;
    rec_rglt_entete cur_rglt_entete%ROWTYPE;
    vv_message      VARCHAR2(250) := '';

  BEGIN
    dka_tools_pkg.put_debug_message('ecarter_fact(+)');

    vv_message := 'Liste des factures à lettrer manuellement';
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := '----------------------------------------------';
    Fnd_File.put_line(Fnd_File.output, vv_message);
    Fnd_File.NEW_LINE(Fnd_File.output, 2);

    vv_message :=  --RPAD('Société', 7) || ' ' || RPAD('N° règlement', 12) || ' ' ||
     RPAD('UO', 7) || ' ' || RPAD('N° règlement', 12) || ' ' ||
                  RPAD('N° Client', 12) || ' ' || RPAD('N° Mouvt', 20) || ' ' ||
                  RPAD('Montant à lettrer', 20);
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := RPAD('-', 7, '-') || ' ' || RPAD('-', 12, '-') || ' ' ||
                  RPAD('-', 12, '-') || ' ' || RPAD('-', 20, '-') || ' ' ||
                  RPAD('-', 20, '-');
    Fnd_File.put_line(Fnd_File.output, vv_message);

    FOR rec_rglt_entete IN cur_rglt_entete LOOP

      OPEN cur_rglt_ligne(rec_rglt_entete.transmission_id,
                          rec_rglt_entete.item_number);

      LOOP
        FETCH cur_rglt_ligne
          INTO rec_rglt_ligne;
        EXIT WHEN cur_rglt_ligne%NOTFOUND;

        maj_data(rec_rglt_ligne.invoice1,
                 --rec_rglt_entete.customer_number, --RBE artf2418217
                 rec_rglt_entete.customer_id, --RBE artf2418217
                 rec_rglt_entete.receipt_method,
                 rec_rglt_entete.transmission_id,
                 rec_rglt_entete.item_number,
                 rec_rglt_ligne.transmission_record_id,
                 rec_rglt_ligne.amount_applied1,
                 rec_rglt_entete.check_number,
                 1,
                 pv_errbuf,
                 pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice2,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied2,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 2,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice3,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied3,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 3,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice4,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied4,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 4,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice5,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied5,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 5,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice6,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied6,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 6,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice7,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied7,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 7,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

        maj_data(vv_invoice_num            => rec_rglt_ligne.invoice8,
                 --vv_customer_num           => rec_rglt_entete.customer_number, --RBE artf2418217
                 vn_customer_id           => rec_rglt_entete.customer_id, --RBE artf2418217
                 vv_receipt_method         => rec_rglt_entete.receipt_method,
                 vv_transmission_id        => rec_rglt_entete.transmission_id,
                 vv_item_number            => rec_rglt_entete.item_number,
                 vv_transmission_record_id => rec_rglt_ligne.transmission_record_id,
                 vv_montant                => rec_rglt_ligne.amount_applied8,
                 vv_check_num              => rec_rglt_entete.check_number,
                 num                       => 8,
                 pv_errbuf                 => pv_errbuf,
                 pn_retcode                => pn_retcode);

      END LOOP;

      CLOSE cur_rglt_ligne;

    END LOOP;

    Fnd_File.NEW_LINE(Fnd_File.output, 2);

    dka_tools_pkg.put_debug_message('ecarter_fact(-)');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END ecarter_fact;

  --------------------------------------------------------------------------------------
  --  Nom           : insert_ar_transmission
  --  Description   : Procédure permet d'inserer dans deux tables ar_transmissions_all,
  --          ar_payments_interface_all les informations importées par
  --                  l'open interface Autolockbox
  --
  --  PARAMETRES    :
  --      pv_errbuf        Entrée     Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --
  ------------------------------------------------------------------------------------
  -- PHENIX 2004 remplacement de ar_transmission_rec.ar_org_id  par fnd_profile.value('ORG_ID') 
  PROCEDURE insert_ar_transmission( --pn_org_id    N                       NUMBER,
                                   pv_errbuf  IN OUT VARCHAR2,
                                   pn_retcode OUT NUMBER) IS
    vn_transmission_id ar_transmissions_all.transmission_id%TYPE;
    vn_trans_format_id ar_transmission_formats.transmission_format_id%TYPE;
    vn_result          NUMBER;

    ----- Curseur sur la table dka_sarencais_tmp avec statut 'P' -----
    CURSOR cur_ar_tbl_dka_sarencais_tmp IS
      SELECT DISTINCT dst.ar_org_id,dst.bank_acct_area, dst.bank_segment3
        FROM dka_sarencais_tmp dst
       WHERE dst.status = 'P';

    ar_transmission_rec cur_ar_tbl_dka_sarencais_tmp%ROWTYPE;

  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    vn_result  := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure INSERT_AR_TRANSMISSION ');

    --Récuperation du transmission_format_id--
    SELECT transmission_format_id
      INTO vn_trans_format_id
      FROM ar_transmission_formats
     WHERE format_name = gv_format; -- Utilisation du format: convertir

    ----- Ouverture du curseur ------
    OPEN cur_ar_tbl_dka_sarencais_tmp;

    ----- Chargement du curseur -----
    LOOP
      FETCH cur_ar_tbl_dka_sarencais_tmp
        INTO ar_transmission_rec;
      EXIT WHEN cur_ar_tbl_dka_sarencais_tmp%NOTFOUND;

      SELECT ar_transmissions_s.NEXTVAL INTO vn_transmission_id FROM DUAL;

      INSERT INTO ar_transmissions_all
        (transmission_request_id,
         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         trans_date,
         time,
         validated_count,
         validated_amount,
         status,
         requested_trans_format_id,
         transmission_name,
         transmission_id,
         latest_request_id,
         org_id)
        SELECT Fnd_Global.conc_request_id,
               Fnd_Global.user_id,
               SYSDATE,
               Fnd_Global.user_id,
               SYSDATE,
               SYSDATE,
               to_char(SYSDATE, 'HH24:MI'),
               0,
               0,
               'NEW', --'NB',
               vn_trans_format_id, --101: format de transmission,
               'SARENCAIS-' || TO_CHAR(vn_transmission_id),
               vn_transmission_id, --ar_transmissions_s.NEXTVAL,
               Fnd_Global.conc_request_id,
               ar_transmission_rec.ar_org_id --Fnd_Profile.value('ORG_ID') -- PHENIX 2004 
          FROM DUAL;

      --Dka_Tools_Pkg.put_debug_message('Nb insertions dans Ar_Transmissions_All (Org_Id=' ||
      --                                TO_CHAR(Fnd_Profile.value('ORG_ID')) ||
      --                                '): ' || TO_CHAR(SQL%ROWCOUNT)); -- PHENIX 2004

      Dka_Tools_Pkg.put_debug_message('Nb insertions dans Ar_Transmissions_All (Org_Id=' ||
                                      TO_CHAR(ar_transmission_rec.ar_org_id) ||
                                      '): ' || TO_CHAR(SQL%ROWCOUNT));

      -- Appel de la procédure de chargement de la table d'open interface ar_payments_interface_all.
      -- On insere les lignes en colonnes, regroupement par check number , 1 rglt = x factures
      BEGIN

        Dka_Sarencais_Pkg.insert_ar_interface(vn_transmission_id,
                                              ar_transmission_rec.ar_org_id,
                                              ar_transmission_rec.bank_acct_area,
                                              ar_transmission_rec.bank_segment3,
                                              pv_errbuf,
                                              vn_result);

      EXCEPTION
        WHEN OTHERS THEN
          pn_retcode := SQLCODE;
          pv_errbuf  := SQLERRM;
      END;
    END LOOP;

    --SL 
    ecarter_fact(pv_errbuf, vn_result);

    CLOSE cur_ar_tbl_dka_sarencais_tmp;
    Dka_Tools_Pkg.put_debug_message('Fin de la procédure INSERT_AR_TRANSMISSION');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : INSERT_AR_TRANSMISSION');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END insert_ar_transmission;

  --------------------------------------------------------------------------------------
  --  Nom           : insert_ar_interface
  --  Description   : Procédure permet d'inserer dans ar_payments_interface_all 
  --                  les informations importées par l'open interface Autolockbox.
  --
  --  PARAMETRES    :
  --      pn_transmission   Entrée     
  --      pn_org_id         Entrée     
  --      pv_bank_acct_area Entrée    
  --      pn_bank_segment3  Entrée    
  --      pv_errbuf         Entrée    Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --
  ------------------------------------------------------------------------------------
  -- PHENIX 2004 remplacement de pn_org_id par fnd_profile.value('ORG_ID') 
  -- ajout du champ attribute2 dans le curseur cur_ins_ar_payments_interface
  -- ajout de la mise à jour de la colonne " RECEIPT_METHOD ".
  -- remplacement de " pn_org_id " par " Fnd_Profile.Value ('ORG_ID') " 

  PROCEDURE insert_ar_interface(pn_transmission   IN NUMBER,
                                pn_org_id         IN NUMBER,
                                pv_bank_acct_area IN VARCHAR2,
                                pn_bank_segment3  IN NUMBER,
                                pv_errbuf         IN OUT VARCHAR2,
                                pn_retcode        OUT NUMBER) IS
    CURSOR cur_ins_ar_payments_interface --- Curseur de regroupement des réglements / factures.
    IS
      SELECT DISTINCT dst.check_number,
                      dst.customer_number,
                      dst.account,
                      dst.check_date,
                      dst.remittance_amount,
                      dst.customer_site_use_id,
                      dst.attribute2, -- PHENIX 2004 
                      dst.exchange_date,
                      dst.exchange_rate,
                      dst.exchange_rate_type,
                      dst.currency_code,
                      dst.ar_org_id,
                      dst.customer_id, -- RBE artf2418217
                      dst.bill_to_location --RBE artf2418217
        FROM dka_sarencais_tmp dst
       WHERE dst.ar_org_id = pn_org_id
         AND dst.bank_acct_area = pv_bank_acct_area
         AND dst.bank_segment3 = pn_bank_segment3
         and dst.STATUS <> 'R'; --MTIA artf07390929

    CURSOR cur_ins_ar_invoices(pn_org_id         IN NUMBER, --- Curseur de chargement des factures.
                               pv_bank_acct_area IN VARCHAR2, 
                               pn_bank_segment3  IN NUMBER, 
                               vn_check_num      IN NUMBER, 
                               vn_customer_num   IN VARCHAR2)  -- RBE artf2418217
      IS
      SELECT dst.invoice_num, dst.amount_applied1
        FROM dka_sarencais_tmp dst
       WHERE dst.ar_org_id = pn_org_id
         AND dst.bank_acct_area = pv_bank_acct_area
         AND dst.bank_segment3 = pn_bank_segment3
         AND dst.check_number = vn_check_num
         AND dst.customer_number = vn_customer_num
         and dst.STATUS <> 'R' --MTIA artf07390929
       ORDER BY dst.amount_applied1 DESC; -- On ordonne les factures par montants décroissants

    -- Declaration du type tableau    
    TYPE invoicetyp IS TABLE OF cur_ins_ar_invoices%ROWTYPE INDEX BY BINARY_INTEGER;
    invoice_num_tab invoicetyp; --- Tableau de stockage des factures     

    vn_check_num              NUMBER;
    --vn_customer_num           NUMBER; -- RBE artf2418217
    vn_compteur               NUMBER;
    vn_indice                 NUMBER;
    vn_check_ind              NUMBER;
    vn_transmission_record_id ar_payments_interface_all.transmission_record_id%TYPE;
    vn_item_num               ar_payments_interface_all.item_number%TYPE;
    vn_overflow_sequence      ar_payments_interface_all.overflow_sequence%TYPE;
    vv_name                   ar_receipt_methods.name%TYPE; -- PHENIX 2004             
    ar_payments_rec           cur_ins_ar_payments_interface%ROWTYPE;
    ar_invoices_rec           cur_ins_ar_invoices%ROWTYPE;
    -- Indice
    i NUMBER;
    j NUMBER;
    k NUMBER;

  BEGIN
    --- Initialisation des variables de sortie de la procédure 
    pv_errbuf  := NULL;
    pn_retcode := 0;

    --- Initialisation du numéro de mouvement   
    vn_item_num := 0;

    Dka_Tools_Pkg.put_debug_message('début de la procédure INSERT_AR_INTERFACE ');

    --- Ouverture du curseur 
    OPEN cur_ins_ar_payments_interface;

    --- Chargement du curseur     
    LOOP
      FETCH cur_ins_ar_payments_interface
        INTO ar_payments_rec;
      EXIT WHEN cur_ins_ar_payments_interface%NOTFOUND;

      -- initialisation des indices
      vn_compteur          := 0;
      vn_check_ind         := 0;
      vn_overflow_sequence := 0;
      -- incrementation de l'item number pour chacun des réglements
      vn_item_num := vn_item_num + 1;

      -- Recherche du nombre de facture associé au réglement.
      SELECT COUNT(dst.invoice_num)
        INTO vn_compteur
        FROM dka_sarencais_tmp dst
       WHERE dst.ar_org_id = pn_org_id
         AND dst.bank_acct_area = pv_bank_acct_area
         AND dst.bank_segment3 = pn_bank_segment3
         AND dst.check_number = ar_payments_rec.check_number
         AND dst.customer_number = ar_payments_rec.customer_number;

      Dka_Tools_Pkg.put_debug_message(vn_compteur ||
                                      ' facture(s) trouvée(s) pour le réglement ' ||
                                      ar_payments_rec.check_number);

      -- PHENIX 2004 
      /*
      SELECT arm.name
        INTO vv_name
        FROM ar_receipt_methods arm, ar_batch_sources_all absa
       WHERE arm.RECEIPT_METHOD_ID = absa.DEFAULT_RECEIPT_METHOD_ID
         AND arm.RECEIPT_CLASS_ID = absa.DEFAULT_RECEIPT_CLASS_ID
         AND absa.name LIKE ar_payments_rec.attribute2 || '%' || gv_origine
         AND arm.name LIKE ar_payments_rec.attribute2 || '%'
         ;
      */
      -- Fin PHENIX 2004   

      SELECT arm.name
        INTO vv_name
        FROM ar_receipt_methods arm, ar_batch_sources_all absa
       WHERE arm.RECEIPT_METHOD_ID = absa.DEFAULT_RECEIPT_METHOD_ID
         AND arm.RECEIPT_CLASS_ID = absa.DEFAULT_RECEIPT_CLASS_ID
         AND absa.org_id = ar_payments_rec.ar_org_id
                         /*(SELECT MIN(hou.organization_id)
                              FROM hr_all_organization_units hou
                             WHERE hou.name = ar_payments_rec.attribute2)*/
         AND absa.name LIKE '%' || gv_origine;

      Dka_Tools_Pkg.put_debug_message('Insertion dans la table ar_payments_interface_all');                  

      -- insertion des informations dans l'enregistrement d'entête (record_type 6)           
      INSERT INTO ar_payments_interface_all
        (transmission_record_id,
         creation_date,
         created_by,
         last_updated_by,
         last_update_date,
         record_type,
         status,
         transmission_request_id,
         item_number,
         currency_code,
         remittance_amount,
         transit_routing_number,
         account,
         check_number,
         customer_number, --RBE artf2418217 -- OBE artf2848298
         customer_id, --RBE artf2418217
         customer_site_use_id, --RBE artf2418217 -- OBE artf2848298
         bill_to_location, --RBE artf2418217
         transmission_id,
         receipt_date,
         receipt_method, -- PHENIX 2004 
         org_id,
         --receipt_date,
         exchange_rate,
         exchange_rate_type)
        SELECT ar_payments_interface_s.NEXTVAL,
               SYSDATE,
               Fnd_Global.user_id,
               Fnd_Global.user_id,
               SYSDATE,
               '6', -- entête
               'AR_PLB_NEW_RECORD', --status
               Fnd_Global.conc_request_id,
               vn_item_num, -- numéro de mouvement
               ar_payments_rec.currency_code, --'EUR',
               ar_payments_rec.remittance_amount, -- montant de la remise en banque
               '12345678', --transit_routing_number
               ar_payments_rec.account,
               ar_payments_rec.check_number,
               ar_payments_rec.customer_number, --RBE artf2418217 -- OBE artf2848298
               ar_payments_rec.customer_id, --RBE artf2418217
               ar_payments_rec.customer_site_use_id, --RBE artf2418217 -- OBE artf2848298
               ar_payments_rec.bill_to_location, --RBE artf2418217
               pn_transmission, --ar_transmissions_s.currval,
               ar_payments_rec.check_date,
               vv_name, -- PHENIX 2004 
               pn_org_id, --Fnd_Profile.value('ORG_ID'), -- PHENIX 2004  
               --ar_payments_rec.exchange_date,
               ar_payments_rec.exchange_rate,
               ar_payments_rec.exchange_rate_type
          FROM DUAL;

      Dka_Tools_Pkg.put_debug_message('Fin Insertion dans la table ar_payments_interface_all');

      -- Détermination du nombre d'enregistrements de suite à insérer
      vn_check_ind := CEIL(vn_compteur / 8);

      -- Ouverture du curseur des factures
      OPEN cur_ins_ar_invoices(pn_org_id,
                               pv_bank_acct_area,
                               pn_bank_segment3,
                               ar_payments_rec.check_number,
                               ar_payments_rec.customer_number);

      FOR i IN 1 .. vn_check_ind -- Boucle sur le nombre d'enregistrement de suite à créer.
       LOOP

        Dka_Tools_Pkg.put_debug_message('Création de l''encaissement ' ||
                                        ar_payments_rec.check_number || '_' || i);
        -- initialisation   
        k := 0;
        j := 0;

        -- Initialisation des 8 occurences par la valeur NULL. 
        FOR j IN 1 .. 8 LOOP
          invoice_num_tab(j).invoice_num := NULL;
          invoice_num_tab(j).amount_applied1 := NULL;
        END LOOP;

        FOR k IN 1 .. 8 -- Boucle sur les factures 
         LOOP
          FETCH cur_ins_ar_invoices
            INTO ar_invoices_rec;
          EXIT WHEN cur_ins_ar_invoices%NOTFOUND;

          BEGIN
            -- Chargement par paquets de 8 factures

            Dka_Tools_Pkg.put_debug_message('Chargement de la facture ' ||
                                            ar_invoices_rec.invoice_num ||
                                            ' d''un montant de : ' ||
                                            ar_invoices_rec.amount_applied1);
            invoice_num_tab(k).invoice_num := ar_invoices_rec.invoice_num;
            invoice_num_tab(k).amount_applied1 := ar_invoices_rec.amount_applied1;

          EXCEPTION
            WHEN OTHERS THEN
              Dka_Tools_Pkg.put_debug_message('ERREUR : Lors du chargement du type invoice_num_tab ');
              Dka_Tools_Pkg.put_debug_message(SQLCODE || ':' || SQLERRM);
          END;
        END LOOP;

        --- Incrementation de la séquence.
        SELECT ar_payments_interface_s.NEXTVAL
          INTO vn_transmission_record_id
          FROM DUAL;
        --- Incrementation de la sequence de suite
        vn_overflow_sequence := vn_overflow_sequence + 1;

        ---  insertion des enregistrements de suite (record_type 4). 
        INSERT INTO ar_payments_interface_all
          (transmission_record_id,
           creation_date,
           created_by,
           last_updated_by,
           last_update_date,
           record_type,
           status,
           transmission_request_id,
           item_number,
           currency_code,
           transit_routing_number,
           overflow_indicator,
           overflow_sequence,
           account,
           transmission_id,
           receipt_date,
           invoice1,
           invoice2,
           invoice3,
           invoice4,
           invoice5,
           invoice6,
           invoice7,
           invoice8,
           amount_applied1,
           amount_applied2,
           amount_applied3,
           amount_applied4,
           amount_applied5,
           amount_applied6,
           amount_applied7,
           amount_applied8,
           org_id,
           --receipt_date,
           exchange_rate,
           exchange_rate_type)
          SELECT vn_transmission_record_id,
                 SYSDATE,
                 Fnd_Global.user_id,
                 Fnd_Global.user_id,
                 SYSDATE,
                 '4', --record_type
                 'AR_PLB_NEW_RECORD', --status
                 Fnd_Global.conc_request_id,
                 vn_item_num, --item_number
                 ar_payments_rec.currency_code, --'EUR',
                 '12345678', --transit_routing_number
                 '0', -- indicateur de suite
                 vn_overflow_sequence, -- indicateur de séquence
                 ar_payments_rec.account,
                 pn_transmission, --ar_transmissions_s.currval,
                 ar_payments_rec.check_date,
                 invoice_num_tab(1) .invoice_num,
                 invoice_num_tab(2) .invoice_num,
                 invoice_num_tab(3) .invoice_num,
                 invoice_num_tab(4) .invoice_num,
                 invoice_num_tab(5) .invoice_num,
                 invoice_num_tab(6) .invoice_num,
                 invoice_num_tab(7) .invoice_num,
                 invoice_num_tab(8) .invoice_num,
                 invoice_num_tab(1) .amount_applied1,
                 invoice_num_tab(2) .amount_applied1,
                 invoice_num_tab(3) .amount_applied1,
                 invoice_num_tab(4) .amount_applied1,
                 invoice_num_tab(5) .amount_applied1,
                 invoice_num_tab(6) .amount_applied1,
                 invoice_num_tab(7) .amount_applied1,
                 invoice_num_tab(8) .amount_applied1,
                 pn_org_id, --Fnd_Profile.value('ORG_ID'), -- PHENIX 2004 
                 --ar_payments_rec.exchange_date,
                 ar_payments_rec.exchange_rate,
                 ar_payments_rec.exchange_rate_type
            FROM DUAL;

        Dka_Tools_Pkg.put_debug_message('Nb insertions dans Ar_Payments_Interface_All (Org_Id=' ||
                                        TO_CHAR(Fnd_Profile.value('ORG_ID')) ||
                                        '): ' || TO_CHAR(SQL%ROWCOUNT)); -- PHENIX 2004
      END LOOP;

      CLOSE cur_ins_ar_invoices;

      -- Mise à jour de l'indicateur de suite du dernier enregistrement
      UPDATE ar_payments_interface_all apia
         SET apia.overflow_indicator = '9'
       WHERE apia.transmission_record_id = vn_transmission_record_id;

      -- Mise à jour de la table dka_sarencais_tmp --
      UPDATE dka_sarencais_tmp dst
         SET dst.status = 'T', 
             dst.transmission_id = pn_transmission
       WHERE dst.ar_org_id = pn_org_id
         AND dst.bank_acct_area = pv_bank_acct_area
         AND dst.bank_segment3 = pn_bank_segment3
         AND dst.check_number = ar_payments_rec.check_number
         AND dst.customer_number = ar_payments_rec.customer_number;

      --Mise à jour de la table ap_checks_all
      UPDATE ap_checks_all ac
         SET ac.attribute10 = TO_CHAR(Fnd_Global.conc_request_id)
       WHERE ac.check_id IN
             (SELECT dst.check_id
                FROM dka_sarencais_tmp dst
               WHERE dst.status = 'T'
                 AND dst.bank_acct_area = pv_bank_acct_area
                 AND dst.bank_segment3 = pn_bank_segment3
                 AND dst.check_number = ar_payments_rec.check_number
                 AND dst.customer_number = ar_payments_rec.customer_number);

      Dka_Tools_Pkg.put_debug_message('Nb de lignes mises à jour dans ap_checks_all ' ||
                                      (SQL%ROWCOUNT));

      COMMIT;

    END LOOP;
    CLOSE cur_ins_ar_payments_interface;

    Dka_Tools_Pkg.put_debug_message('Fin de la procédure INSERT_AR_INTERFACE');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('Erreur INSERT_AR_INTERFACE : ' ||
                                      SQLERRM);
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END insert_ar_interface;

  ---------------------------------------------------------------------------------------
  --  Nom           : populate_data
  --  Description   : Procédure qui renseigne et complète  la table dka_sarencais_tmp
  --  PARAMETRES    :
  --  PARAMETRES    :
  --      pv_errbuf       Entrée  Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --------------------------------------------------------------------------------------
  -- PHENIX 2004 Dans la requête de sélection du site client, suppression de la
  -- restriction entre la colonne " hcas.org_id " et " vn_ar_org_id "                                                                                  
  PROCEDURE populate_data(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS

    ----- Curseur sur la table dka_sarencais_tmp avec statut 'P' -----
    CURSOR cur_tbl_dka_sarencais_tmp IS
      SELECT *
        FROM dka_sarencais_tmp dst
       WHERE dst.status = 'P'
         FOR UPDATE;

    vd_gl_date             DATE;
    v_payment_rec          cur_tbl_dka_sarencais_tmp%ROWTYPE;
    vv_open_flag           dka_sarencais_tmp.payment_status_flag%TYPE;
    vn_amount              dka_sarencais_tmp.remittance_amount%TYPE;
    vd_receipt_date        dka_sarencais_tmp.receipt_date%TYPE;
    vn_ar_check_number     dka_sarencais_tmp.ar_check_number%TYPE;
    vv_invoice1            ar_payments_interface.invoice1%TYPE;
    vn_amount_applied1     ar_payments_interface.amount_applied1%TYPE;
    vv_code_societe        hr_all_organization_units.NAME%TYPE;
    vn_customer_id         ra_customers.customer_id%TYPE;
    vv_customer_number     ra_customers.customer_number%TYPE;
    vn_customer_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    vn_bill_to_site_use_id hz_cust_site_uses_all.bill_to_site_use_id%TYPE;
    vv_bill_to_location    dka_sarencais_tmp.bill_to_location%TYPE; --RBE artf2418217
    vn_ar_org_id           hr_all_organization_units.organization_id%TYPE;

    vv_errbuf  VARCHAR2(500);
    vn_retcode NUMBER;

    v_region_principale VARCHAR2(80); --RBE artf2226321
  BEGIN
    ---Initialisation des variables--

    pv_errbuf  := NULL;
    pn_retcode := 0;
    --vv_errbuf     := NULL;
    vn_retcode := 0;

    Dka_Tools_Pkg.put_debug_message('début de la procédure POPULATE_DATA');
    ----- Ouverture du curseur ------
    OPEN cur_tbl_dka_sarencais_tmp;

    ----- Chargement du curseur -----
    LOOP
      vv_errbuf := NULL;

      FETCH cur_tbl_dka_sarencais_tmp
        INTO v_payment_rec;
      EXIT WHEN cur_tbl_dka_sarencais_tmp%NOTFOUND;
      Dka_Tools_Pkg.put_debug_message('Calcul de la date GL');


      Dka_Sarencais_Pkg.check_periods(v_payment_rec.ap_gl_date,
                                      v_payment_rec.ledger_id,
                                      vv_open_flag,
                                      pv_errbuf,
                                      pn_retcode);

      IF vv_open_flag = 'N' THEN
        ---Appel de la procédure GET_AR_PERIOD --

        vd_gl_date := get_ar_period_date_f(v_payment_rec.ap_gl_date,
                                           v_payment_rec.ledger_id);

        vv_errbuf := 'Erreur sur période comptable';

      ELSE
        vd_gl_date := v_payment_rec.ap_gl_date;
      END IF;

      Dka_Tools_Pkg.put_debug_message('Calcul de données complementaires');

      --Calcul du nom de la société pour AP. Appel de la procédure get_code_société
      Dka_Tools_Pkg.get_code_societe(v_payment_rec.ap_org_id,
                                     vv_code_societe,
                                     pv_errbuf,
                                     pn_retcode);

      --Appel de la procédure get_customer_partner
      BEGIN

        --RBE artf2226321
        BEGIN
            SELECT ffvv.attribute2
            INTO   v_region_principale
            FROM    fnd_flex_value_sets ffvs,
                    fnd_flex_values_vl  ffvv
            WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
            AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
            AND ffvv.enabled_flag = 'Y'
            AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE)
            AND nvl(ffvv.end_date_active,SYSDATE)
            AND ffvv.flex_value = SUBSTR(v_payment_rec.attribute2,4,7)
            AND ffvv.attribute2 IS NOT NULL
            ;      
        EXCEPTION
            WHEN OTHERS THEN
                v_region_principale := NULL;
        END;

        get_customer_partner(vv_code_societe,
                             v_region_principale||SUBSTR(v_payment_rec.attribute2,4,7), --RBE artf2226321
                             vn_customer_id,
                             vv_customer_number,
                             vn_customer_site_id,
                             vn_bill_to_site_use_id,
                             vv_bill_to_location, --RBE artf2418217
                             vv_errbuf,
                             vn_retcode);

        IF vn_retcode != 0 THEN
          --BEGIN
          -- réinitialisation 
          vn_retcode := 0;
          --vv_errbuf  := NULL;

          Dka_Tools_Pkg.put_debug_message('ERREUR : Site Client introuvable pour le réglement ' ||
                                          v_payment_rec.check_number);

          vv_errbuf := 'Site Client introuvable';

        END IF;
      END;

      BEGIN
       --Recherche de l'organisation AR
       SELECT rcta.org_id
         INTO vn_ar_org_id
         FROM ra_customer_trx_all          rcta,
              ra_cust_trx_line_gl_dist_all rctlgda,
              gl_code_combinations_kfv     gcc,
              ra_cust_trx_types_all        rctta,
              ap_invoices_all              aia
        WHERE rcta.trx_number = v_payment_rec.invoice_num
          AND rcta.bill_to_customer_id = vn_customer_id
          AND rcta.customer_trx_id = rctlgda.customer_trx_id
          AND rcta.cust_trx_type_id = rctta.cust_trx_type_id
          AND rcta.trx_date = aia.invoice_date
          AND aia.invoice_id = v_payment_rec.invoice_id
          AND rctlgda.account_class = 'REC'
          AND gcc.code_combination_id = rctlgda.code_combination_id
          AND gcc.segment5 like '%' || substr(vv_code_societe, -4)
          AND gcc.segment1 = substr(v_payment_rec.attribute2, -4);

      EXCEPTION 
       WHEN OTHERS THEN
        -- réinitialisation 

		--< OBE artf2848298

        SELECT organization_id
		INTO vn_ar_org_id
        FROM hr_operating_units
        WHERE name = v_region_principale||SUBSTR(v_payment_rec.attribute2,4,7);		

		Dka_Tools_Pkg.put_debug_message('Facture AR introuvable. Sélection de l''UO principale.');
        --vn_ar_org_id := -1;
        --Dka_Tools_Pkg.put_debug_message('ERREUR : Organisation AR introuvable pour la facture : ' ||
                                        --v_payment_rec.invoice_num);

        --vv_errbuf := 'Organisation AR introuvable';
		--> OBE artf2848298
      END;

       BEGIN
       --Correction site client
        SELECT hcsu.site_use_id,
               hcsu.location
          INTO vn_bill_to_site_use_id,
               vv_bill_to_location
          FROM hz_cust_site_uses_all     hcsu,
               hz_cust_acct_sites_all    hcas
         WHERE hcsu.cust_acct_site_id = hcas.cust_acct_site_id
           AND hcsu.org_id = hcas.org_id
           AND hcas.cust_account_id = vn_customer_id
           AND hcsu.org_id = vn_ar_org_id
           AND hcsu.site_use_code = 'BILL_TO'
           AND hcsu.status = 'A'
           AND hcas.status = 'A'
           AND hcas.attribute8 LIKE '%'||substr(vv_code_societe,-4)
           AND ROWNUM = 1;

      EXCEPTION 
       WHEN OTHERS THEN
        -- réinitialisation 
        vn_bill_to_site_use_id := NULL;
        vv_bill_to_location    := NULL;
        Dka_Tools_Pkg.put_debug_message('ERREUR : Site client introuvable pour l''id client : ' ||
                                        vn_customer_id);

        vv_errbuf := 'Site client introuvable';
      END;

      --Lettrage automatique  des règlements, utilisation du numéro de facture comme critère de lettrage
      vv_invoice1 := v_payment_rec.invoice_num;
      --le montant,la date et le numero du règlement AP sont identiques à ceux de AR
      vn_amount_applied1 := v_payment_rec.amount_applied1 * 100; -- L'interface travaille en centimes;
      vn_amount          := v_payment_rec.amount * 100; -- L'interface travaille en centimes
      vd_receipt_date    := v_payment_rec.check_date;
      vn_ar_check_number := v_payment_rec.check_number;

      --Mise à jour de la table dka_sarencais_tmp
      UPDATE dka_sarencais_tmp dst
         SET dst.payment_status_flag  = vv_open_flag,
             dst.gl_date              = vd_gl_date,
             dst.remittance_amount    = vn_amount,
             dst.ar_org_id            = vn_ar_org_id, 
             dst.receipt_date         = vd_receipt_date,
             dst.ar_check_number      = vn_ar_check_number, -- /***Debug***/ || TO_CHAR (drifa_s.NEXTVAL),
             dst.invoice1             = vv_invoice1,
             dst.amount_applied1      = vn_amount_applied1,
             dst.customer_id          = vn_customer_id,
             dst.customer_number      = vv_customer_number,
             dst.customer_site_use_id = vn_bill_to_site_use_id,
             dst.bill_to_location     = vv_bill_to_location, --RBE artf2418217
             dst.bank_acct_area       = (select substr(name,1,3) from hr_operating_units where organization_id = vn_ar_org_id), --Correction Région
             dst.rejection_reason     = vv_errbuf,
			 dst.status               = decode(vv_errbuf,'Site client introuvable','R',dst.status)
       WHERE CURRENT OF cur_tbl_dka_sarencais_tmp;
    END LOOP;

    ----- Fermeture du curseur -----
    CLOSE cur_tbl_dka_sarencais_tmp;

    ---Ajustement des montants par Org
    UPDATE dka_sarencais_tmp dst
    SET amount = (SELECT SUM(amount_applied1)/100 from dka_sarencais_tmp d2 where d2.check_id = dst.check_id and d2.ar_org_id = dst.ar_org_id),
        remittance_amount  = (SELECT SUM(amount_applied1) from dka_sarencais_tmp d2 where d2.check_id = dst.check_id and d2.ar_org_id = dst.ar_org_id)
    WHERE dst.status = 'P';

    Dka_Tools_Pkg.put_debug_message('FIN de la procédure POPULATE_DATA');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : POPULATE_DATA');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END populate_data;

  -----------------------------------------------------------------------------------
  --  Nom           : run_import
  --  Description   : Procedure qui permet de lancer le traitement Standard  ARLPLB
  --                  de l'open interface
  --  PARAMETRES    :
  --  PARAMETRES    :
  --      pn_transmission_id              Entrée
  --      pn_org_id                       Entrée
  --      pn_request_id                           Sortie
  --      pv_errbuf               Entrée  Sortie
  --      pv_retcode                          Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------------
  -- PHENIX 2004 Dans la requête sur la table " ar_lockboxes_all ", suppression
  -- de la restriction sur " l'org_id "
  -- Suppression de la requête sur la table des responsabilités 
  -- Suppression de l'appel à la procédure de positionnement de l'environnement
  -- " apps_initialize ".
  -- Ajout paramètre
  -- Modif codif lockbox_number et category_code
  PROCEDURE run_import(pv_errbuf          IN OUT VARCHAR2,
                       pn_retcode         OUT NUMBER,
                       pn_transmission_id IN NUMBER,
                       pn_org_id          IN NUMBER,
                       pv_acct_area       IN VARCHAR2,
                       pv_region_ap       IN VARCHAR2, --RBE artf2418217
                       pv_segment3        IN VARCHAR2,
                       pn_ar_org_id       IN NUMBER, -- PHENIX 2004
                       pn_request_id      OUT NUMBER) IS

    vn_lockbox_id        ar_lockboxes_all.lockbox_id%TYPE;
    vv_category_code     fnd_doc_sequence_assignments.category_code%TYPE;
    vn_transmission_name ar_transmissions_all.transmission_name%TYPE;
    vn_trans_format_id   ar_transmission_formats.transmission_format_id%TYPE;
    vv_code_societe      hr_all_organization_units.NAME%TYPE;
    vv_code_uo           hr_all_organization_units.NAME%TYPE;
    --vn_ar_org_id         hr_all_organization_units.organization_id%TYPE;
    vn_responsibility_id fnd_responsibility.responsibility_id%TYPE;
    vn_application_id    fnd_application.application_id%TYPE;
    vv_message           VARCHAR2(255);
    e_error_lockbox EXCEPTION;
    e_error_sequences EXCEPTION;

  BEGIN
    ---Initialisation des variables--
    pv_errbuf        := NULL;
    pn_retcode       := 0;
    vn_lockbox_id    := 0;
    vv_category_code := NULL;
    Dka_Tools_Pkg.put_debug_message('début de la procédure RUN_IMPORT');
    -- Récupération du nom du lot de règlement

    Dka_Tools_Pkg.put_debug_message('Récupération du nom du lot de règlement');

    SELECT transmission_name
      INTO vn_transmission_name
      FROM ar_transmissions_all ata
     WHERE ata.transmission_id = pn_transmission_id;

    Dka_Tools_Pkg.put_debug_message('Récupération du format de transmission');

    SELECT transmission_format_id
      INTO vn_trans_format_id
      FROM ar_transmission_formats
     WHERE format_name = gv_format;

    --Calcul du nom de la société pour AP --
    --Appel de la procédure get_code_societe--
    Dka_Tools_Pkg.get_code_societe(pn_ar_org_id,
                                   vv_code_uo,
                                   pv_errbuf,
                                   pn_retcode); -- PHENIX 2004

    vv_code_societe := substr(vv_code_uo, -4);

    BEGIN

      Dka_Tools_Pkg.put_debug_message('Récupération du lockbox_id');

      -- Récupération du lockbox_id et calcul du lockbox_number
      SELECT al.lockbox_id
        INTO vn_lockbox_id
        FROM ar_lockboxes_all al
       WHERE al.status = 'A'
            --AND    pn_org_id = al.org_id  PHENIX 2004 
         --AND al.lockbox_number = vv_code_societe || '_' || pv_acct_area || '_VI_' || pv_segment3; -- PHENIX 2004 --RBE artf2418217
         AND al.lockbox_number = vv_code_societe || '_' || pv_acct_area || '_VI_' || pv_segment3; --RBE artf2418217


      IF vn_lockbox_id = 0 THEN
        RAISE e_error_lockbox;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_error_lockbox;

    END;

    BEGIN

      Dka_Tools_Pkg.put_debug_message('Vérification des affectations de séquences');

      -- Vérification des affectations des séquences 
      SELECT category_code
        INTO vv_category_code
        FROM (SELECT fdsa.category_code
                FROM fnd_doc_sequence_assignments fdsa
               WHERE fdsa.category_code = vv_code_societe || '_' || pv_acct_area || '_VI_' || pv_segment3 -- PHENIX 2004
                 AND fdsa.application_id = 222
                 AND SYSDATE BETWEEN nvl(fdsa.start_date, sysdate) AND nvl(fdsa.end_date, sysdate)
               ORDER BY fdsa.method_code ASC NULLS FIRST)
       WHERE rownum = 1;

      IF vv_category_code IS NULL THEN
        RAISE e_error_sequences;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_error_sequences;
    END;

    Dka_Tools_Pkg.put_debug_message('Responsibility_key: ' || vv_code_uo || gv_ar_responsibility_key);

    -- Positionnement de la responsabilité
    SELECT fr.responsibility_id, fr.application_id
      INTO vn_responsibility_id, vn_application_id
      FROM fnd_responsibility fr
    --WHERE responsibility_key = gv_ar_responsibility_key; -- PHENIX 2004: REPLACE (gv_ar_responsibility_key, 'XXXX', vv_code_societe) -> gv_ar_responsibility_key.
     WHERE responsibility_key = vv_code_uo || gv_ar_responsibility_key;

    Fnd_Global.apps_initialize(Fnd_Global.user_id,
                               vn_responsibility_id,
                               vn_application_id);

    mo_global.init('AR');

    mo_global.set_policy_context('S', pn_ar_org_id);
    arp_standard.init_standard(pn_ar_org_id);

    --Lancement du programme ARLPLB
    --Dka_Tools_Pkg.put_debug_message('Lancement du programme standard DKA_ARLPLB');
    Dka_Tools_Pkg.put_debug_message('Lancement du programme standard ARLPLB');

    -- PHENIX 2004
    pn_request_id := Fnd_Request.SUBMIT_REQUEST(
                                      application => 'AR', --APPL
                                      program     => 'ARLPLB', --PROG
                                      description => NULL, --PROGRAM_NAME
                                      start_time  => NULL, --START
                                      sub_request => FALSE, --SUB_REQUEST

                                      argument1   => 'N',                          --nouvel import                          
                                      argument2   => pn_transmission_id,           --transmission_id         
                                      argument3   => gn_request_id,                --numéro du traitement          
                                      argument4   => vn_transmission_name,         --nom du lot             
                                      argument5   => 'N',                          --lancer l'import                         
                                      argument6   => NULL,                         --fichier d'import                     
                                      argument7   => NULL,                         --fichier de contrôle                    
                                      argument8   => vn_trans_format_id,           --format de transmission 
                                      argument9   => 'Y',                          --Lancer validation                       
                                      argument10  => 'N',                          --autoriser reglements                    
                                      argument11  => vn_lockbox_id,                --lockbox_id                    
                                      argument12  => NULL,                         --gl_date                               
                                      argument13  => 'A',                          --format de l'etat                      
                                      argument14  => 'N',                          --lots terminés                          
                                      argument15  => 'Y',                          --lancer l'imputation                     
                                      argument16  => 'N', --NULL,                  --recherche autre nom           
                                      argument17  => 'Y',                          --imputer mtt restant                    
                                      argument18  => NULL,                         --Code mvt USSGL                         
                                      argument19  => pn_ar_org_id,--Fnd_Profile.Value('ORG_ID'),  --Org Id 
                                      argument20  => 'N',                          --Apply Unearned Discounts (Y/N)
                                      argument21  => 1,                            --Nombre d'instances       
                                      argument22  => 'L',                          --submission_type                         
                                      argument23  => NULL                          --scoring_model                          
                                      );  
    -- FIN PHENIX 2004

    Dka_Tools_Pkg.put_debug_message('Fin de la procédure RUN_IMPORT');

  EXCEPTION
    WHEN e_error_lockbox THEN
      -- Signalisation de l'anomalie dans le .out
      vv_message := 'Liste des sociétés non importées';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '---------------------------------';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'La validation et l''imputation ne sera pas effectuée pour la société: ' || vv_code_societe;
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'WARNING : le Lockbox number ' || vv_code_societe || '_' ||
                    pv_acct_area || '_VI_' || pv_segment3 ||
                    ' n''est pas définit dans l''interface'; -- PHENIX 2004
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'CAUSE : Veuillez verifier le compte bancaire fournisseur utilisé pour régler les factures';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      -- Signalisation dans le .log
      Dka_Tools_Pkg.put_debug_message('le Lockbox number ' ||
                                      vv_code_societe || '_' ||
                                      pv_acct_area || '_VI_' ||
                                      pv_segment3 ||
                                      ' n''est pas définit dans l''interface'); -- PHENIX 2004
      -- Motif du rejet
      UPDATE dka_sarencais_tmp dst
         SET dst.rejection_reason = 'Lockbox invalide'
       WHERE dst.transmission_id = pn_transmission_id;
      COMMIT;
    WHEN e_error_sequences THEN
      vv_message := 'Liste des sociétés non importées';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '---------------------------------';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'La validation et l''imputation ne sera pas effectuée pour la société: ' || vv_code_societe;
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'WARNING : ' || vv_code_societe || '_' || pv_acct_area ||
                    '_VI_' || pv_segment3; -- PHENIX 2004
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'CAUSE : L''affectation des séquences n''est pas définie';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      UPDATE dka_sarencais_tmp dst
         SET dst.rejection_reason = 'Séquence non affectée'
       WHERE dst.transmission_id = pn_transmission_id;
      COMMIT;
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : RUN_IMPORT');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END run_import;

  ------------------------------------------------------------------------------------
  --  Nom           : run_all_imports
  --  Description   : Procédure qui permet d'enchainer tous les traitements de l'open interface
  --  PARAMETRES    :
  --      pv_errbuf        Entrée Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------------
  PROCEDURE run_all_imports(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER) IS

    ----- Curseur sur la table dka_sarencais_tmp
    CURSOR cur_run_dka_sarencais_tmp IS
      SELECT DISTINCT ata.org_id,
                      ata.transmission_id,
                      dst.bank_acct_area,
                      dst.bank_segment3,
                      dst.ar_org_id, -- PHENIX 2004
                      SUBSTR(hou.name,1,3) region_ap --RBE artf2418217
        FROM ar_transmissions_all ata, dka_sarencais_tmp dst , hr_all_organization_units hou --RBE artf2418217
       WHERE dst.transmission_id = ata.transmission_id
         AND hou.organization_id = dst.ap_org_id --RBE artf2418217
         AND dst.customer_site_use_id IS NOT NULL;

    v_run_import_rec cur_run_dka_sarencais_tmp%ROWTYPE;

    vv_phase         VARCHAR2(100);
    vv_status        VARCHAR2(100);
    vv_dev_phase     VARCHAR2(100);
    vv_dev_status    VARCHAR2(100);
    vv_message       VARCHAR2(100);
    vn_request_id    NUMBER(15);
    va_request_ids   Pa_Utils.idtabtyp; ---Tableau
    vn_compteur      NUMBER;

  BEGIN

    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure RUN_ALL_IMPORTS  ');
    vn_compteur := 0;

    ----- Ouverture du curseur ------
    OPEN cur_run_dka_sarencais_tmp;

    ----- Chargement du curseur -----
    LOOP
      FETCH cur_run_dka_sarencais_tmp
        INTO v_run_import_rec;
      EXIT WHEN cur_run_dka_sarencais_tmp%NOTFOUND;

      --Appel de la procédure RUN IMPORT  --
      Dka_Sarencais_Pkg.run_import(pv_errbuf,
                                   pn_retcode,
                                   v_run_import_rec.transmission_id,
                                   v_run_import_rec.org_id,
                                   v_run_import_rec.bank_acct_area,
                                   v_run_import_rec.region_ap, --RBE artf2418217
                                   v_run_import_rec.bank_segment3,
                                   v_run_import_rec.ar_org_id, -- PHENIX 2004
                                   vn_request_id);

      IF pn_retcode != 0 THEN
        Dka_Tools_Pkg.put_debug_message('ERREUR: Lancement du traitement a généré une erreur: ' ||
                                        pv_errbuf);
        CLOSE cur_run_dka_sarencais_tmp;
        RETURN;
      END IF;

      IF vn_request_id = 0 THEN
        pn_retcode := 2;
        Dka_Tools_Pkg.put_debug_message('/!\ Le traitement a échoué pour l''org_id ' ||
                                        TO_CHAR(v_run_import_rec.org_id));
      ELSE
        Dka_Tools_Pkg.put_debug_message('Le traitement pour l''org_id ' ||
                                        TO_CHAR(v_run_import_rec.org_id) ||
                                        ' : ' || TO_CHAR(vn_request_id));
        vn_compteur := vn_compteur + 1;
        va_request_ids(vn_compteur) := vn_request_id;
      END IF;
    END LOOP;

    COMMIT;

    WHILE vn_compteur > 0 LOOP
      -- On attend la fin de tous les traitement en commençant par la fin
      IF NOT (Fnd_Concurrent.wait_for_request(va_request_ids(vn_compteur),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_message)) THEN
        Dka_Tools_Pkg.put_debug_message('Traitement trop long ');
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        Dka_Tools_Pkg.put_debug_message('L''éxécution du traitement  OK');
      END IF;

      vn_compteur := vn_compteur - 1;
    END LOOP;

    Dka_Tools_Pkg.put_debug_message('Tous les traitements sont terminés');
    ----- Fermeture du curseur -----
    CLOSE cur_run_dka_sarencais_tmp;
    Dka_Tools_Pkg.put_debug_message('Fin de la procédure RUN_ALL_IMPORTS  ');

  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : RUN_ALL_IMPORTS');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END run_all_imports;

  --------------------------------------------------------------------------------------------------------------------
  --  Nom           :tieback
  --  Description   :Cette procédure permet de:
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='A'  pour les lignes accéptées.
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='W'  pour les lignes non lettrées.
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='R'  pour les lignes rejetées.
  --                 Mettre à jour du check_id dans ap_checks_all  correspondant à l'id du règlement dans AR.
  --  PARAMETRES :
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  ---------------------------------------------------------------------------------------------------------------------
  -- PHENIX 2004 Dans les mises à jour de la table " dka_sarencais_tmp ",
  -- suppression des restrictions sur " l'org_id ".
  PROCEDURE tieback(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure TIEBACK   ');

    --Mise à jour de la table dka_sarencais_tmp avec le status='A'
    UPDATE dka_sarencais_tmp dst
       SET dst.status          = 'A',
           dst.cash_receipt_id = (SELECT acr.cash_receipt_id
                                    FROM ar_cash_receipts_all acr
                                   WHERE --acr.org_id = dst.ar_org_id  PHENIX 2004 
                                   acr.receipt_number = dst.ar_check_number
                                AND acr.pay_from_customer = dst.customer_id
                                AND acr.status = 'APP'
                                AND acr.receipt_date = dst.check_date
                                AND org_id = dst.ar_org_id)
     WHERE EXISTS (SELECT acr.cash_receipt_id
              FROM ar_cash_receipts_all acr
             WHERE --acr.org_id = dst.ar_org_id  PHENIX 2004 
             acr.receipt_number = dst.ar_check_number
          AND acr.pay_from_customer = dst.customer_id
          AND acr.status = 'APP'
          AND acr.receipt_date = dst.check_date
          AND org_id = dst.ar_org_id);

    Dka_Tools_Pkg.put_debug_message('Nb de lignes mises à jour A dans dka_sarencais_tmp' ||
                                    TO_CHAR(SQL%ROWCOUNT));

    --Mise à jour de la table dka_sarencais_tmp avec le status='W'
    UPDATE dka_sarencais_tmp dst
       SET status              = 'W',
           dst.cash_receipt_id = (SELECT acr.cash_receipt_id
                                    FROM ar_cash_receipts_all acr
                                   WHERE --acr.org_id = dst.ar_org_id PHENIX 2004 
                                   acr.receipt_number = dst.ar_check_number
                                AND acr.pay_from_customer = dst.customer_id
                                AND acr.status NOT IN ('APP', 'REV')
                                AND acr.receipt_date = dst.check_date
                                AND org_id = dst.ar_org_id)
     WHERE EXISTS (SELECT acr.cash_receipt_id
              FROM ar_cash_receipts_all acr
             WHERE --acr.org_id = dst.ar_org_id PHENIX 2004   
             acr.receipt_number = dst.ar_check_number
          AND acr.pay_from_customer = dst.customer_id
          AND acr.status NOT IN ('APP', 'REV')
          AND acr.receipt_date = dst.check_date
          AND org_id = dst.ar_org_id);

    Dka_Tools_Pkg.put_debug_message('Nb de lignes mises à jour W dans dka_sarencais_tmp ' ||
                                    TO_CHAR(SQL%ROWCOUNT));

    --Mise à jour de la table dka_sarencais_tmp avec le status='R'
    UPDATE dka_sarencais_tmp dst
       SET status = 'R'
    --rejection_reason = 'Rejeté de l''interface'
     WHERE EXISTS (SELECT 'X'
              FROM ar_payments_interface_all api
             WHERE --api.org_id = dst.ar_org_id  PHENIX 2004 
             api.check_number = dst.ar_check_number
            --AND    api.customer_id  = dst.customer_id --SL 04/04/2006
          --AND api.customer_number = dst.customer_number --SL 04/04/2006  -RBE artf2418217
          AND nvl(api.customer_id,dst.customer_id) = dst.customer_id --RBE artf2418217
          AND api.receipt_date = dst.check_date
          AND org_id = dst.ar_org_id) --AD le 23/02/04
        OR EXISTS (SELECT 'X'
              FROM ar_interim_cash_receipts_all aicr
             WHERE --aicr.org_id = dst.ar_org_id  PHENIX 2004 
             aicr.receipt_number = dst.ar_check_number
          AND aicr.pay_from_customer = dst.customer_id
          AND aicr.receipt_date = dst.check_date
          AND org_id = dst.ar_org_id); ----AD le 23/02/04

    Dka_Tools_Pkg.put_debug_message('Nb de lignes mises à jour R dans dka_sarencais_tmp ' ||
                                    TO_CHAR(SQL%ROWCOUNT));
    Dka_Tools_Pkg.put_debug_message('Fin de la procédure TIEBACK   ');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : TIEBACK');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END tieback;

  ------------------------------------------------------------------------------------------------------------
  --  Nom           : output_status
  --  Description   : Cette procédure permet d'afficher un etat de sortie suivant un status donné.
  --  PARAMETRES :
  --      pv_status               Entrée
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  -----------------------------------------------------------------------------------------------------------
  PROCEDURE output_status(pv_status  IN VARCHAR2,
                          pv_errbuf  IN OUT VARCHAR2,
                          pn_retcode OUT NUMBER) IS
    --Curseur sur la table dka_sarencais_tmp
    CURSOR sarencais_output_cur IS
      SELECT DISTINCT --dst.attribute2, --RBE artf2226321 
                      hou.name,         --RBE artf2226321 
                      dst.check_number,
                      dst.customer_number,
                      dst.remittance_amount,
                      dst.transmission_id,
                      apia.item_number,
                      dst.rejection_reason
        FROM dka_sarencais_tmp dst, ar_payments_interface_all apia, hr_operating_units hou --RBE artf2226321 
       WHERE dst.status = pv_status
         AND apia.check_number(+) = dst.check_number
         --AND apia.customer_number(+) = dst.customer_number --RBE artf2418217
         AND apia.customer_id(+) = dst.customer_id --RBE artf2418217
         AND apia.transmission_id(+) = dst.transmission_id
         AND apia.remittance_amount(+) = dst.remittance_amount
         AND dst.ar_org_id = hou.organization_id --RBE artf2226321 
       UNION
       --Règlement n'ayant pas d'organisation AR 
       SELECT DISTINCT to_char(dst.ar_org_id),
                      dst.check_number,
                      dst.customer_number,
                      dst.remittance_amount,
                      dst.transmission_id,
                      apia.item_number,
                      dst.rejection_reason
        FROM dka_sarencais_tmp dst, ar_payments_interface_all apia 
       WHERE dst.status = pv_status
         AND apia.check_number(+) = dst.check_number
         AND apia.customer_id(+) = dst.customer_id
         AND apia.transmission_id(+) = dst.transmission_id
         AND apia.remittance_amount(+) = dst.remittance_amount
         AND dst.ar_org_id = (-1)    
       ORDER BY name; 


    sarencais_output_rec sarencais_output_cur%ROWTYPE;
    vv_message           VARCHAR2(255);
    vn_count             INTEGER;
    vv_libelle           VARCHAR2(100);
    vv_status            ar_payments_interface_all.status%TYPE;
    vv_excedeed_remit    ar_payments_interface_all.remittance_amount%TYPE;
    vn_bug               INTEGER;

  BEGIN
    -- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure OUTPUT_STATUS   ');
    --initialisation du compteur a 0 --
    vn_count := 0;

    IF pv_status = 'R' THEN
      vv_libelle := 'rejetées';
    ELSIF pv_status = 'W' THEN
      vv_libelle := 'pas totalement lettrées';
    ELSIF pv_status = 'A' THEN
      vv_libelle := 'acceptées';
    END IF;

    vv_message := 'Liste des écritures ' || vv_libelle;
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := '-----------------------------------------';
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := '';
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := '';
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message :=  --RPAD('Société', 7) || ' ' || RPAD('N° règlement', 12) || ' ' ||
                  RPAD('UO', 7) || ' ' || RPAD('N° règlement', 12) || ' ' ||
                  RPAD('N° Client', 12) || ' ' || RPAD('Montant', 12) || ' ' ||
                  RPAD('N° Transmission', 15) || ' ' || RPAD('N° Mouvt', 8) || ' ' ||
                  RPAD('Motif', 65);
    Fnd_File.put_line(Fnd_File.output, vv_message);
    vv_message := RPAD('-', 7, '-') || ' ' || RPAD('-', 12, '-') || ' ' ||
                  RPAD('-', 12, '-') || ' ' || RPAD('-', 12, '-') || ' ' ||
                  RPAD('-', 15, '-') || ' ' || RPAD('-', 8, '-') || ' ' ||
                  RPAD('-', 65, '-');
    Fnd_File.put_line(Fnd_File.output, vv_message);

    --Ouverture du curseur----

    IF NOT sarencais_output_cur%ISOPEN THEN
      OPEN sarencais_output_cur;
    END IF;

    LOOP
      FETCH sarencais_output_cur
        INTO sarencais_output_rec;
      EXIT WHEN sarencais_output_cur%NOTFOUND;

      BEGIN
        SELECT apia.status
          INTO vv_status
          FROM ar_payments_interface_all apia
         WHERE apia.transmission_id = sarencais_output_rec.transmission_id
           AND apia.check_number = sarencais_output_rec.check_number
           AND apia.remittance_amount =
               sarencais_output_rec.remittance_amount
           AND apia.record_type = '6'; -- On ne selectionne que le Receipt_record

        IF vv_status = 'AR_PLB_INVALID_RECEIPT' THEN
          vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' ||  --RBE artf2226321 
                        RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||          --RBE artf2226321 
                        LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.customer_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.remittance_amount,
                             12,
                             ' ') || ' ' ||
                        LPAD(sarencais_output_rec.transmission_id, 15, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                        RPAD('Lettrages invalides', 65, ' ');
        ELSIF vv_status = 'AR_PLB_REMIT_EXCEEDED' THEN
          -- Calcul du montant lettré 
          SELECT SUM((NVL(apia.amount_applied1, 0) +
                     NVL(apia.amount_applied2, 0) +
                     NVL(apia.amount_applied3, 0) +
                     NVL(apia.amount_applied4, 0) +
                     NVL(apia.amount_applied5, 0) +
                     NVL(apia.amount_applied6, 0) +
                     NVL(apia.amount_applied7, 0) +
                     NVL(apia.amount_applied8, 0)))
            INTO vv_excedeed_remit
            FROM ar_payments_interface_all apia
           WHERE apia.transmission_id =
                 sarencais_output_rec.transmission_id
                --AND    apia.check_number = sarencais_output_rec.check_number
             AND apia.item_number = sarencais_output_rec.item_number
             AND apia.record_type = '4';

          vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' || --RBE artf2226321 
                        RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||         --RBE artf2226321 
                        LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.customer_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.remittance_amount,
                             12,
                             ' ') || ' ' ||
                        LPAD(sarencais_output_rec.transmission_id, 15, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                        RPAD('Montants lettrés :' || vv_excedeed_remit ||
                             ' >> supérieurs à la remise',
                             65,
                             ' ');
        ELSIF vv_status = 'AR_PLB_CUST_OK' THEN
          vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' ||  --RBE artf2226321 
                        RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||          --RBE artf2226321 
                        LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.customer_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.remittance_amount,
                             12,
                             ' ') || ' ' ||
                        LPAD(sarencais_output_rec.transmission_id, 15, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                        RPAD('Paramètrage incorrect', 65, ' ');
        ELSIF sarencais_output_rec.name = '-1' THEN
          vv_message := RPAD(sarencais_output_rec.name               , 7 , ' ') || ' ' || 
                        LPAD(sarencais_output_rec.check_number       , 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.customer_number    , 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.remittance_amount  , 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.transmission_id    , 15, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.item_number        , 8 , ' ') || ' ' ||
                        RPAD('Mouvement AR non retrouvé'             , 65, ' ');
        ELSE
          --Affichage des données des enregistrements
          vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' || --RBE artf2226321 
                        RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||         --RBE artf2226321 
                        LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.customer_number, 12, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.remittance_amount,
                             12,
                             ' ') || ' ' ||
                        LPAD(sarencais_output_rec.transmission_id, 15, ' ') || ' ' ||
                        LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                        RPAD(sarencais_output_rec.rejection_reason, 65, ' ');
        END IF;
        Fnd_File.put_line(Fnd_File.output, vv_message);
        vn_count := vn_count + 1;

        /*-------------------------------------------------------------------
        Bug Oracle : Le lot est transferé dans AR. Une partie des réglements
        sont bloqué dans les tables interim. Le batch est en 'Processed'
        La table ar_payments_interface_all est purgée. Impossible de relancé
        manuellement le Post QuickCash
        ------------------------------------------------------------------*/

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- Le batch a été traité mais il reste des écritures non postés
          SELECT COUNT('X')
            INTO vn_bug
            FROM ar_interim_cash_receipts_all aicr
           WHERE aicr.receipt_number = sarencais_output_rec.check_number
             AND aicr.amount = sarencais_output_rec.remittance_amount;
          -- Enumération des écritures
          IF vn_bug > 0 THEN
            vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' ||  --RBE artf2226321 
                          RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||          --RBE artf2226321 
                          LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                          LPAD(sarencais_output_rec.customer_number,
                               12,
                               ' ') || ' ' || LPAD(sarencais_output_rec.remittance_amount,
                                                   12,
                                                   ' ') || ' ' ||
                          LPAD(sarencais_output_rec.transmission_id,
                               15,
                               ' ') || ' ' ||
                          LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                          RPAD('BUG ORACLE : Ecriture non postée', 65, ' ');

          ELSE
            -- Anomalies avant transfert vers l'interface AR (ex : Site client introuvable).
            vv_message := --RPAD(sarencais_output_rec.attribute2, 7, ' ') || ' ' || --RBE artf2226321 
                          RPAD(sarencais_output_rec.name, 7, ' ') || ' ' ||         --RBE artf2226321 
                          LPAD(sarencais_output_rec.check_number, 12, ' ') || ' ' ||
                          LPAD(sarencais_output_rec.customer_number,
                               12,
                               ' ') || ' ' || LPAD(sarencais_output_rec.remittance_amount,
                                                   12,
                                                   ' ') || ' ' ||
                          LPAD(sarencais_output_rec.transmission_id,
                               15,
                               ' ') || ' ' ||
                          LPAD(sarencais_output_rec.item_number, 8, ' ') || ' ' ||
                          RPAD(sarencais_output_rec.rejection_reason,
                               65,
                               ' ');
          END IF;
          Fnd_File.put_line(Fnd_File.output, vv_message);
          vn_count := vn_count + 1;
      END;
    END LOOP;

    CLOSE sarencais_output_cur;

    IF vn_count = 0 THEN
      vv_message := 'Il n''y a pas d''écriture en rejet';
      Fnd_File.put_line(Fnd_File.output, vv_message);
    ELSE
      vv_message := '';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := 'Nombre de lignes ' || vv_libelle || ' ' ||
                    TO_CHAR(vn_count);
      Fnd_File.put_line(Fnd_File.output, vv_message);
      vv_message := '';
      Fnd_File.put_line(Fnd_File.output, vv_message);
      Dka_Tools_Pkg.put_debug_message('Fin de la procédure OUTPUT_STATUS   ');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : OUTPUT_STATUS');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END output_status;

  ------------------------------------------------------------------------------------------------------------
  --  Nom           : create_output
  --  Description   : Cette procédure permet d'afficher les enregistrements en erreur sous forme
  --                  de tableau dans le fichier de sortie du traitement.
  --  PARAMETRES :
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  -----------------------------------------------------------------------------------------------------------
  PROCEDURE create_output(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vv_errbuf  VARCHAR2(150);
    vn_retcode NUMBER;
  BEGIN
    -- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('début de la procédure CREATE_OUTPUT  ');
    --Appel de la procédure output_status pour les ligne rejetées pour un status=R
    Dka_Sarencais_Pkg.output_status('R', vv_errbuf, vn_retcode);
    --Appel de la procédure output_status pour les ligne qui ne sont pas totalement letrées pour un status=W
    --dka_sarencais_pkg.output_status ('W', vv_errbuf, vn_retcode);
    --Appel de la procédure output_status pour toutes les ligne acceptées pour un status=A
    --dka_sarencais_pkg.output_status ('A', vv_errbuf, vn_retcode);
    Dka_Tools_Pkg.put_debug_message('Fin de la procédure CREATE_OUTPUT  ');
  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : CREATE_OUTPUT');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END create_output;


  -------------------------------------------------------------------------------------
  --  Nom           : exec_sarencais_mail
  --  Description   : procedure d'exécution de la compression du fichier à envoyer
  --
  --  PARAMETRES    :
  --  cv_prog_name                IN       Short Name du traitement
  --  vb_validation               OUT      Code retour.
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
  ------------------------------------------------------------------------------------
  PROCEDURE exec_sarencais_mail(cv_prog_name  IN VARCHAR2,
                                vb_validation OUT BOOLEAN) IS
    vv_prog_application_short_name VARCHAR(30);
    vn_request_id                  NUMBER(15);
    cn_tempo CONSTANT NUMBER := 20;
    vv_rphase  VARCHAR2(80);
    vv_rstatus VARCHAR2(80);
    vv_dphase  VARCHAR2(30);
    vv_dstatus VARCHAR2(30);
    vv_message VARCHAR2(240);
  BEGIN
    -- Recherche de l'application propriétaire du traitement. --
    BEGIN
      SELECT fa.application_short_name
        INTO vv_prog_application_short_name
        FROM fnd_concurrent_programs fcp, fnd_application fa
       WHERE fcp.concurrent_program_name = cv_prog_name
         AND fa.application_id = fcp.application_id;
    EXCEPTION
      WHEN OTHERS THEN
        vb_validation := FALSE;
        Dka_Tools_Pkg.put_debug_message('Impossible de trouver l''application propriétaire pour le lancement du traitement d''envoi par mail des paiements intra groupe AP/AR.');
    END;

    vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                cv_prog_name, --SHORT_NAME du TRAITEMENT
                                                NULL, --PROGRAM_NAME
                                                NULL, --START
                                                FALSE --SUB_REQUEST
                                                );
    -- INC000000395045 - Mise à jour de la table contenant les informations de lancement de traitement :
    --           Insertion du parent du traitement.
    UPDATE fnd_concurrent_requests fcr
       SET parent_request_id = fnd_global.CONC_REQUEST_ID
     WHERE request_id = vn_request_id;

    --Dka_Tools_Pkg.put_debug_message ('Validation pour que les GTS puissent prendre la demande');
    COMMIT;


  END;
  ------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures.
  --
  --  PARAMETRES :
  --      pv_errbuf               Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vn_result NUMBER;
    --vn_org_id   NUMBER (15);
    vv_status     dka_sarencais_tmp.status%TYPE;
    vb_validation boolean;

  BEGIN
    -- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('Début de la procédure principale' ||
                                    CHR(10));
    -- Appel de la procédure INIT -----
    Dka_Sarencais_Pkg.init(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    -- Appel de la procédure GET_AP_PAYMENTS -----
    Dka_Sarencais_Pkg.get_ap_payments(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    --Appel de laprocédure POPULATE_DATA--
    Dka_Sarencais_Pkg.populate_data(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    --Appel de la procédure INSERT_AR_INTERFACE--
    Dka_Sarencais_Pkg.insert_ar_transmission(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    -- Validation des données avant lancement des traitements standards
    COMMIT;

    -- Désactivation temporaire des règles d'auto-lettrages 
    UPDATE ar_autocash_hierarchies aah
       SET aah.status           = 'I',
           aah.last_update_date = TRUNC(SYSDATE),
           aah.last_updated_by  = Fnd_Global.user_id
     WHERE aah.status = 'A';

    UPDATE ar_system_parameters_all aspa
       SET aspa.attribute10           = aspa.autocash_hierarchy_id,
           aspa.autocash_hierarchy_id = NULL
     WHERE aspa.autocash_hierarchy_id IS NOT NULL;

    COMMIT;

    --Appel de la procédure RUN_ALL_IMPORTS--
    Dka_Sarencais_Pkg.run_all_imports(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    --Appel de la procédure TIEBACK--
    Dka_Tools_Pkg.put_debug_message('Lancement de la procédure TIEBACK');
    Dka_Sarencais_Pkg.tieback(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    --Appel de la procédure OUTPUT_STATUS --
    --dka_sarencais_pkg.output_status (vv_status, pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    --Appel de la procédure CREATE_OUTPUT--
    Dka_Sarencais_Pkg.create_output(pv_errbuf, vn_result);

    IF vn_result != 0 THEN
      pn_retcode := 2;
      RETURN;
    END IF;

    -- Réactivation des régles d'auto-lettrages.
    UPDATE ar_autocash_hierarchies aah
       SET aah.status           = 'A',
           aah.last_update_date = SYSDATE,
           aah.last_updated_by  = Fnd_Global.user_id
     WHERE aah.status = 'I'
       AND aah.last_update_date = TRUNC(SYSDATE)
       AND aah.last_updated_by = Fnd_Global.user_id;

    UPDATE ar_system_parameters_all aspa
       SET aspa.autocash_hierarchy_id = aspa.attribute10,
           aspa.attribute10           = NULL
     WHERE aspa.attribute10 IS NOT NULL;

    COMMIT;

    -- Lancement du traitement d'envoi par mail des paiements intra-groupe AP/AR.
    exec_sarencais_mail('DKA_SARENCAIS_MAIL', vb_validation);
    /*IF vb_validation = FALSE THEN
      dka_tools_pkg.put_log_message('L''exécution du traitement d''envoi par mail des paiements intra groupe AP/AR a rencontré une erreur.');
      pn_retcode := 2;
    END IF;*/

  EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_debug_message('ERREUR : MAIN');
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END main;
END Dka_Sarencais_Pkg;
/
SHOW ERRORS
EXIT;
