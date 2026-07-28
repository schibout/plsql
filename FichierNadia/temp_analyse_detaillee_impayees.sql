-- =====================================================================
-- Extraction dÃ©taillÃ©e des factures impayÃ©es BO
-- =====================================================================
-- Date gÃ©nÃ©ration : 18/02/2026 17:35:19
-- AnnÃ©e : 2026
-- Nombre factures : 10
-- =====================================================================

SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET TRIMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ';'
SET NUMFORMAT 999999999999.99

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

SPOOL C:/Users/schibout/Documents/plsql/FichierNadia/analyse_detaillee_impayees_2026_20260218_173515.csv

-- En-tÃªte CSV
PROMPT ID_FACTURE;NUM_FACTURE;TYPE_FACTURE;SOURCE;STATUT_PAIEMENT;STATUT_VALIDATION;WORKFLOW_STATUS;MONTANT_FACTURE;MONTANT_PAYE;MONTANT_RESTANT;DEVISE;DATE_FACTURE;DATE_GL;DATE_ECHEANCE;DATE_ANNULATION;DATE_CREATION;DATE_MAJ;FOURNISSEUR_ID;FOURNISSEUR_NOM;FOURNISSEUR_NUMERO;SITE_FOURNISSEUR_ID;SITE_FOURNISSEUR;ADRESSE_PAIEMENT;CODE_PAIEMENT;ORG_ID;OU_NAME;NB_LIGNES;NB_DISTRIBUTIONS;NB_PAIEMENTS;MONTANT_TOTAL_PAIEMENTS;NB_PAIEMENTS_VALIDES;MONTANT_PAIEMENTS_VALIDES;DERNIER_PAIEMENT_DATE;DERNIER_PAIEMENT_NUM;PO_NUMBER;RECEPTION_NUM;NOTES;CREATED_BY_NAME;LAST_UPDATED_BY_NAME

-- RequÃªte principale
SELECT
    -- Informations facture
    aia.invoice_id || ';' ||
    aia.invoice_num || ';' ||
    aia.invoice_type_lookup_code || ';' ||
    aia.source || ';' ||
    CASE aia.payment_status_flag 
        WHEN 'Y' THEN 'PAYEE'
        WHEN 'P' THEN 'PARTIELLE'
        ELSE 'IMPAYEE'
    END || ';' ||
    aia.validation_request_id || ';' ||
    aia.wfapproval_status || ';' ||
    aia.invoice_amount || ';' ||
    NVL(aia.amount_paid, 0) || ';' ||
    (aia.invoice_amount - NVL(aia.amount_paid, 0)) || ';' ||
    aia.invoice_currency_code || ';' ||
    aia.invoice_date || ';' ||
    aia.gl_date || ';' ||
    aia.terms_date || ';' ||
    aia.cancelled_date || ';' ||
    aia.creation_date || ';' ||
    aia.last_update_date || ';' ||
    
    -- Informations fournisseur
    aia.vendor_id || ';' ||
    aps.vendor_name || ';' ||
    aps.segment1 || ';' ||
    aia.vendor_site_id || ';' ||
    apss.vendor_site_code || ';' ||
    apss.address_line1 || ';' ||
    apss.payment_method_lookup_code || ';' ||
    
    -- Informations organisation
    aia.org_id || ';' ||
    hou.name || ';' ||
    
    -- Statistiques lignes et distributions
    (SELECT COUNT(*) FROM ap_invoice_lines_all ail WHERE ail.invoice_id = aia.invoice_id) || ';' ||
    (SELECT COUNT(*) FROM ap_invoice_distributions_all aid WHERE aid.invoice_id = aia.invoice_id) || ';' ||
    
    -- Statistiques paiements
    (SELECT COUNT(*) 
     FROM ap_invoice_payments_all aip 
     WHERE aip.invoice_id = aia.invoice_id) || ';' ||
    (SELECT NVL(SUM(ac.amount), 0)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id) || ';' ||
    (SELECT COUNT(*) 
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT NVL(SUM(ac.amount), 0)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT MAX(ac.check_date)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT MAX(ac.check_number)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    
    -- Informations commande/rÃ©ception
    (SELECT LISTAGG(DISTINCT poh.segment1, ', ') WITHIN GROUP (ORDER BY poh.segment1)
     FROM ap_invoice_distributions_all aid
     LEFT JOIN po_distributions_all pod ON aid.po_distribution_id = pod.po_distribution_id
     LEFT JOIN po_headers_all poh ON pod.po_header_id = poh.po_header_id
     WHERE aid.invoice_id = aia.invoice_id
       AND poh.segment1 IS NOT NULL) || ';' ||
    (SELECT LISTAGG(DISTINCT rt.receipt_num, ', ') WITHIN GROUP (ORDER BY rt.receipt_num)
     FROM ap_invoice_distributions_all aid
     LEFT JOIN rcv_transactions rt ON aid.rcv_transaction_id = rt.transaction_id
     WHERE aid.invoice_id = aia.invoice_id
       AND rt.receipt_num IS NOT NULL) || ';' ||
    
    -- Informations audit
    REPLACE(REPLACE(aia.description, CHR(10), ' '), CHR(13), ' ') || ';' ||
    (SELECT fu1.user_name FROM fnd_user fu1 WHERE fu1.user_id = aia.created_by) || ';' ||
    (SELECT fu2.user_name FROM fnd_user fu2 WHERE fu2.user_id = aia.last_updated_by) AS LIGNE
FROM ap_invoices_all aia
LEFT JOIN ap_suppliers aps ON aia.vendor_id = aps.vendor_id
LEFT JOIN ap_supplier_sites_all apss ON aia.vendor_site_id = apss.vendor_site_id
LEFT JOIN hr_operating_units hou ON aia.org_id = hou.organization_id
WHERE aia.invoice_id IN (1471379, 1471380, 2452495, 43334, 43336, 55827, 56823, 56825, 59884, 59887)
ORDER BY aia.last_update_date DESC, aia.invoice_id DESC;

SPOOL OFF
EXIT;
