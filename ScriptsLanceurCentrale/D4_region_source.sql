-- D6 - Apercu du resultat attendu : fichiers recus par jour et par folio, 10 jours
-- C'est la requete 18 vue par folio : permet de juger si les chiffres "fichiers recus / rejets / integrees"
-- correspondent a ce que l'exploitation attend, avant de figer les tuiles.

WITH fac AS (
    SELECT TRUNC(aia.creation_date) AS jour, aia.attribute9 AS folio, aia.attribute10 AS fichier, 'INTEGREE' AS etat
    FROM   ap_invoices_all aia
    WHERE  aia.attribute10 IS NOT NULL
    AND    aia.creation_date > TRUNC(SYSDATE) - 10
    UNION ALL
    SELECT TRUNC(aii.creation_date), aii.attribute9, aii.attribute10,
           CASE WHEN aii.status = 'REJECTED'
                  OR EXISTS (SELECT 1 FROM ap_interface_rejections air
                             WHERE  air.parent_table = 'AP_INVOICES_INTERFACE' AND air.parent_id = aii.invoice_id)
                  OR EXISTS (SELECT 1 FROM ap_interface_rejections air
                             JOIN   ap_invoice_lines_interface aili ON aili.invoice_line_id = air.parent_id
                             WHERE  air.parent_table = 'AP_INVOICE_LINES_INTERFACE' AND aili.invoice_id = aii.invoice_id)
                THEN 'REJETEE' ELSE 'EN_ATTENTE' END
    FROM   ap_invoices_interface aii
    WHERE  aii.attribute10 IS NOT NULL
    AND    NVL(aii.status, 'NEW') <> 'PROCESSED'
    AND    aii.creation_date > TRUNC(SYSDATE) - 10
)
SELECT TO_CHAR(jour, 'DD/MM/YY')                                      AS DATE_CR,
       NVL(folio, '?')                                                AS FOLIO,
       COUNT(DISTINCT fichier)                                        AS NB_FICHIERS,
       COUNT(*)                                                       AS NB_FACTURES,
       SUM(CASE WHEN etat = 'INTEGREE'   THEN 1 ELSE 0 END)           AS NB_INTEGREES,
       SUM(CASE WHEN etat = 'REJETEE'    THEN 1 ELSE 0 END)           AS NB_REJETEES,
       SUM(CASE WHEN etat = 'EN_ATTENTE' THEN 1 ELSE 0 END)           AS NB_EN_ATTENTE
FROM   fac
GROUP BY jour, NVL(folio, '?')
ORDER BY jour DESC, NB_FACTURES DESC;
