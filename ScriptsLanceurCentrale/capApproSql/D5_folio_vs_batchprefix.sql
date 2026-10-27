-- D2 - AP_INVOICES_INTERFACE : statuts conserves, folios, rejets, 30 jours
-- Objectif : savoir si les factures PROCESSED restent en interface (sinon purge) et comment reconnaitre un rejet
-- (status REJECTED seul, ou presence dans AP_INTERFACE_REJECTIONS entete / lignes).

SELECT NVL(aii.status, '(null)')                               AS STATUT_OI,
       NVL(aii.attribute9, '(vide)')                           AS FOLIO,
       COUNT(*)                                                AS NB,
       SUM(CASE WHEN aii.attribute10 IS NULL THEN 1 ELSE 0 END) AS NB_SANS_FICHIER,
       COUNT(DISTINCT aii.attribute10)                         AS NB_FICHIERS,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM ap_interface_rejections air
                             WHERE  air.parent_table = 'AP_INVOICES_INTERFACE' AND air.parent_id = aii.invoice_id)
                THEN 1 ELSE 0 END)                             AS NB_REJET_ENTETE,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM ap_interface_rejections air
                             JOIN   ap_invoice_lines_interface aili ON aili.invoice_line_id = air.parent_id
                             WHERE  air.parent_table = 'AP_INVOICE_LINES_INTERFACE' AND aili.invoice_id = aii.invoice_id)
                THEN 1 ELSE 0 END)                             AS NB_REJET_LIGNE,
       TRUNC(SYSDATE) - TRUNC(MIN(aii.creation_date))          AS AGE_MAX_J,
       TO_CHAR(MAX(aii.creation_date), 'DD/MM/YY')             AS DERNIERE
FROM   ap_invoices_interface aii
WHERE  aii.creation_date > TRUNC(SYSDATE) - 30
GROUP BY NVL(aii.status, '(null)'), NVL(aii.attribute9, '(vide)')
ORDER BY STATUT_OI, NB DESC;

