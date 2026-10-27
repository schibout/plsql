-- D4 - D'ou tirer la region des factures de fichiers ? 30 jours
-- Partie A : taux de rapprochement des factures AP (avec attribute10) vers DKA_IAPFACXGS_REPORTING_ALL par
--            invoice_num = num_fact, par folio. Si le taux est faible, la region doit venir d'ailleurs.
-- Partie B : operating units AP (org_id) rencontrees : leur nom porte-t-il la region ?

SELECT 'A_RAPPROCHEMENT_DKA'                                   AS PARTIE,
       NVL(aia.attribute9, '(vide)')                           AS CLE,
       COUNT(*)                                                AS NB_FACTURES,
       SUM(CASE WHEN dir.num_fact IS NOT NULL THEN 1 ELSE 0 END) AS NB_TROUVEES_DKA,
       COUNT(DISTINCT dir.code_region)                         AS NB_REGIONS,
       MIN(dir.code_region) || ' .. ' || MAX(dir.code_region)  AS EXEMPLE_REGIONS,
       SUM(CASE WHEN dir.nb > 1 THEN 1 ELSE 0 END)             AS NB_NUM_FACT_AMBIGUS
FROM   ap_invoices_all aia
LEFT JOIN (SELECT num_fact, MIN(code_region) AS code_region, COUNT(DISTINCT code_region) AS nb
           FROM   dka_iapfacxgs_reporting_all
           WHERE  date_creation >= TO_CHAR(TRUNC(SYSDATE) - 60, 'YYYYMMDD')
           GROUP BY num_fact) dir ON dir.num_fact = TRIM(aia.invoice_num)
WHERE  aia.attribute10 IS NOT NULL
AND    aia.creation_date > TRUNC(SYSDATE) - 30
GROUP BY NVL(aia.attribute9, '(vide)')
UNION ALL
SELECT 'B_OPERATING_UNIT',
       hou.name,
       COUNT(*),
       NULL, NULL, NULL, NULL
FROM   ap_invoices_all aia
LEFT JOIN hr_operating_units hou ON hou.organization_id = aia.org_id
WHERE  aia.attribute10 IS NOT NULL
AND    aia.creation_date > TRUNC(SYSDATE) - 30
GROUP BY hou.name
ORDER BY 1, 3 DESC;
