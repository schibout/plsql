CREATE OR REPLACE PACKAGE BODY APPS.dka_sapapprvl_pkg AS
---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPAPPRVL_PKG.pkb
-- DESCRIPTION       : Approbation toutes sociétés des factures fournisseurs
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---
--- 16/10/2003 GV  main : dans le curseur cur_approval, supprimer la condition sur attribute3
--- 04/08/2004 SLE Portage spécifique pour projet PHENIX 2004
---                Modification et déplacement de la requête sur la table " fnd_responsibility " et de
---                l'appel à la procédure " fnd_global.apps_initialize " afin de le faire qu'une seule fois
--- 05/04/2006 FM  Remplacer "option de rapprochement" New par All.
--- 30/10/2007 ADR ETANCHEITE DALKIA 2007
--  20/06/2016 BDE HELIOS traitement lancé pour toutes les UO
--  24/11/2016 NBO SPE001 - defect 388 Prise en compte des données AP du jour en erreur
--  03/02/2017 EFL artf2095114: Modification de la soumission de APPRVL. 1 soumission sous la responsabilite TOUT_AP_ADMINISTRATEUR
--                 Parallelisation avec l'option de profil AP_APPRVL_WORKER_COUNT.
--
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
--                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main(pv_errbuf        IN  OUT VARCHAR2,
               pn_retcode           OUT NUMBER)

IS
  vn_responsibility_id   NUMBER;
  vn_application_id      NUMBER;
  vv_ap_responsibility   VARCHAR2(100);
  rec_param              dka_parameters%ROWTYPE;
  vn_request_id          NUMBER;
  vn_approval_org_id     NUMBER;
  vv_phase               VARCHAR2(100);
  vv_status              VARCHAR2(100);
  vv_dev_phase           VARCHAR2(100);
  vv_dev_status          VARCHAR2(100);
  va_request_ids         pa_utils.IdTabTyp; ---Tableau
  vn_requests_cnt        NUMBER;
  vv_errbuf              VARCHAR2(150);
  /* ETANCHEITE DALKIA 2007 */
  vv_parameter dka_parameters.parameter_name%TYPE;

  --curseur sur le regroupement de factures avec status d'approbation NULL (jamais approuvé)
  CURSOR cur_approval IS
    SELECT DISTINCT hou.organization_id org_id ,
                    hou.NAME,
                    hou.set_of_books_id
    FROM  hr_operating_units hou
    WHERE hou.organization_id in (SELECT /*+ dynamic_sampling(2) cardinality(ai,10) */
                                   DISTINCT ai.org_id
                                    FROM ap_invoices_all ai -- 7461423
                                   WHERE ai.validation_request_id IS NULL
                                     AND ai.approval_ready_flag <> 'S'
                                     AND ai.invoice_type_lookup_code <> 'INVOICE REQUEST' /*Bug 16263597*/
                                     AND ai.cancelled_date IS NULL /* Bug 9777752 */
                                     AND NOT (nvl(ai.payment_status_flag,'N') = 'Y'
                                     AND nvl(ai.historical_flag,'N') = 'Y'
                                     AND nvl(ai.force_revalidation_flag,'N') = 'N') /*Bug11934187*/
                                     AND EXISTS (SELECT /*+ PUSH_SUBQ */ 1
                                                 FROM dual
                                                 WHERE upper(nvl(ai.SOURCE,'X')) <> 'RECURRING INVOICE'
                                                 UNION ALL
                                                 SELECT 1
                                                 FROM dual
                                                 WHERE upper(nvl(ai.SOURCE,'X')) = 'RECURRING INVOICE'
                                                   AND NOT EXISTS (SELECT NULL
                                                                   FROM gl_period_statuses glps
                                                                   WHERE glps.application_id = '200'
                                                                     AND glps.set_of_books_id = ai.set_of_books_id
                                                                     AND trunc(ai.gl_date) BETWEEN glps.start_date AND glps.end_date
                                                                     AND nvl(glps.adjustment_period_flag,'N') = 'N'
                                                                     AND glps.closing_status = 'N'))
                                     AND EXISTS (  SELECT 1
                                                   FROM dual
                                                   WHERE ai.force_revalidation_flag = 'Y'
                                                 UNION ALL
                                                   SELECT /*+ index(D AP_INVOICE_DISTRIBUTIONS_N32) cardinality(D 1) use_nl(fsp) */ 1
                                                   FROM ap_invoice_distributions_all d,
                                                        financials_system_params_all fsp
                                                   WHERE d.invoice_id = ai.invoice_id
                                                     AND fsp.org_id = d.org_id
                                                     AND nvl(d.match_status_flag,'N') <> 'A'
                                                     AND fsp.set_of_books_id = d.set_of_books_id
                                                     AND (nvl(fsp.purch_encumbrance_flag,'N') = 'Y'
                                                          OR (nvl(fsp.purch_encumbrance_flag,'N') = 'N' AND nvl(d.match_status_flag,'N') <> 'T'))
                                                 UNION ALL
                                                   SELECT /*+ index(D AP_SELF_ASSESSED_TAX_DIST_N31) use_nl(fsp) */ 1
                                                   FROM ap_self_assessed_tax_dist_all d,
                                                        financials_system_params_all  fsp
                                                   WHERE d.invoice_id = ai.invoice_id
                                                     AND nvl(d.match_status_flag,'N') <> 'A'
                                                     AND fsp.org_id = d.org_id
                                                     AND fsp.set_of_books_id = d.set_of_books_id
                                                     AND (nvl(fsp.purch_encumbrance_flag,'N') = 'Y'
                                                          OR (nvl(fsp.purch_encumbrance_flag,'N') = 'N' AND nvl(d.match_status_flag,'N') <> 'T'))
                                                     AND NOT EXISTS (SELECT /*+ index(D2 AP_SELF_ASSESSED_TAX_DIST_N30) */ 'Cancelled distributions'
                                                                      FROM ap_self_assessed_tax_dist_all d2
                                                                     WHERE d2.invoice_id = d.invoice_id
                                                                       AND d2.cancellation_flag = 'Y')
                                                 UNION ALL
                                                   SELECT 1
                                                   FROM ap_holds_all h
                                                   WHERE h.invoice_id = ai.invoice_id
                                                    AND ((h.hold_lookup_code IN
                                                           ('QTY ORD', 'QTY REC', 'AMT ORD', 'AMT REC', 'QUALITY', 'PRICE', 'TAX DIFFERENCE', 'CURRENCY DIFFERENCE', 'REC EXCEPTION',
                                                            'TAX VARIANCE', 'PO NOT APPROVED', 'PO REQUIRED', 'MAX SHIP AMOUNT', 'MAX RATE AMOUNT', 'MAX TOTAL AMOUNT', 'TAX AMOUNT RANGE',
                                                            'MAX QTY ORD', 'MAX QTY REC', 'MAX AMT ORD', 'MAX AMT REC', 'CANT CLOSE PO', 'CANT TRY PO CLOSE', 'LINE VARIANCE', 'CANT FUNDS CHECK',
                                                            'Expired Registration', 'Amount Funded', 'Quantity Funded', 'GTAS Mandatory Fields', 'GTAS Data Validation', 'AWT ERROR'))
                                                          OR /* Bug#13464635 */ /*Bug18411094: Added AWT error*/
                                                         (h.hold_lookup_code IN ( SELECT hold_lookup_code
                                                                                    FROM ap_hold_codes
                                                                                   WHERE postable_flag = 'N'
                                                                                     AND user_releaseable_flag = 'N'))) /* Bug 14579876 */
                                                    AND h.release_lookup_code IS NULL
                                                    AND EXISTS (SELECT 'Lines'
                                                                FROM ap_invoice_lines_all l2
                                                                WHERE l2.invoice_id = h.invoice_id) --8580790,9112369
                                                 UNION ALL
                                                   SELECT 1
                                                   FROM ap_invoice_lines_all ail
                                                   WHERE ail.invoice_id = ai.invoice_id
                                                        /* Bug 9777752 AND AI.CANCELLED_DATE IS NULL  */
                                                     AND nvl(ail.discarded_flag,'N') <> 'Y'
                                                     AND nvl(ail.cancelled_flag,'N') <> 'Y'
                                                     AND (ail.amount <> 0 OR (ail.amount = 0 AND ail.generate_dists = 'Y')) --8580790
                                                     AND NOT EXISTS (SELECT /*+ NO_UNNEST */ 'distributed line'
                                                                     FROM ap_invoice_distributions_all d5
                                                                     WHERE d5.invoice_id = ail.invoice_id
                                                                       AND d5.invoice_line_number = ail.line_number))
                                     AND NOT EXISTS (SELECT /*+ push_subq no_unnest */ 'Cancelled distributions'
                                                      FROM ap_invoice_distributions_all d3
                                                     WHERE d3.invoice_id = ai.invoice_id
                                                       AND d3.cancellation_flag = 'Y'));



BEGIN
      pn_retcode := 0;
      pv_errbuf  := NULL;

      vn_requests_cnt := 0;


      vv_parameter := 'AP_RESPONSIBILITY_KEY';
      --récupération des parametres utilisés par le traitement
      dka_tools_pkg.get_parameter('SAPAPPRVL',
                                   vv_parameter,
                                   rec_param,
                                   pn_retcode,
                                   pv_errbuf);
      IF pn_retcode != 0 THEN
        pn_retcode := 1;
        RETURN;
      END IF;

      vv_ap_responsibility := rec_param.varchar2_value;
      dka_tools_pkg.put_log_message('Responsabilité : '|| vv_ap_responsibility );

      --récupération des variables nécessaires au lancement du traitement
      SELECT fr.responsibility_id, fr.application_id
      INTO vn_responsibility_id, vn_application_id
      FROM fnd_responsibility fr
      WHERE fr.responsibility_key = vv_ap_responsibility;
      dka_tools_pkg.put_log_message('Responsabilité : '|| vn_responsibility_id || vn_application_id );

      -- initialisation de l'environement OA pour toutes les org.
      fnd_global.apps_initialize(fnd_global.user_id,vn_responsibility_id,vn_application_id);
      MO_GLOBAL.INIT('SQLAP');

      FOR l in cur_approval LOOP

        --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
         vn_request_id := fnd_request.submit_request( 'SQLAP',        --APPLICATION
                                                      'APPRVL',       --PROGRAM
                                                      NULL,           --PROGRAM_NAME
                                                      NULL,           --START_TIME
                                                      FALSE,          --SUB_REQUEST
                                                      l.org_id,       -- org_id
                                                      'All',          --option de rapprochement
                                                      NULL,           --invoice batch id (nom du lot)
                                                      NULL,           --date de début de facture
                                                      NULL,           --date de fin de facture
                                                      NULL,           --vendor_id (fournisseur id)
                                                      NULL,           --pay_group (classe de reglement)
                                                      NULL,           --ID facture
                                                      NULL,           --id utilisateur de saisie
                                                      l.set_of_books_id,--set_of_books_id ???
                                                      'N',            --option d'analyse (trace option)
                                                      1000,          --commit size
                                                      1000,             -- Num of Transactions : Note 1917614.1. Doit etre > 0 pour utiliser l'option de profil AP_APPRVL_WORKER_COUNT
                                                      'N'            --Debug switch
                                                      );

        IF vn_request_id IS NULL THEN
          pn_retcode := 1;
          pv_errbuf := 'Le traitement d''approbation '||l.NAME||' n''a pas pu être lancé';
        ELSE pn_retcode :=0;
          pv_errbuf := 'Traitement d''approbation '||l.NAME||' : '||TO_CHAR(vn_request_id)||' lancé ';
          dka_tools_pkg.put_log_message(pv_errbuf);

          vn_requests_cnt := vn_requests_cnt + 1;
          va_request_ids(vn_requests_cnt) := vn_request_id;
        END IF;

        COMMIT;

      END LOOP; --cur_approval

      WHILE vn_requests_cnt > 0 LOOP
        dka_tools_pkg.put_outdebug_message('Attente du traitement : '||va_request_ids(vn_requests_cnt));
        IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                                15,
                                                0,
                                                vv_phase,
                                                vv_status,
                                                vv_dev_phase,
                                                vv_dev_status,
                                                vv_errbuf)) THEN

          dka_tools_pkg.put_log_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_requests_cnt)) || ' trop long ou tombé en erreur');

        ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')THEN
          dka_tools_pkg.put_log_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_requests_cnt)) || ' correctement exécuté');
        END IF;

        vn_requests_cnt := vn_requests_cnt - 1;

      END LOOP;

EXCEPTION
  WHEN OTHERS THEN

    dka_tools_pkg.put_log_message('Une exception a été déclenchée'||sqlerrm||'    '||sqlcode);
    pv_errbuf := SQLERRM(SQLCODE);
    pn_retcode := 2;

END main;
--------------------------------------------------------------------------------------------------------------
END dka_sapapprvl_pkg;

/

SHOW ERROR
EXIT;
