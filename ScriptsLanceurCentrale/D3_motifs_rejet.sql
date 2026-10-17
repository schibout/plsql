-- D5 - Folio (attribute9) contre source DKA (batchprefix), 30 jours
-- Objectif : savoir si le folio AP correspond a la source de l'interface DKA (VE1 Xerox, L56 Tradeshift,
-- DSP DacShop, DMT Serensia). Si oui, les tuiles par source et le suivi par fichier parlent de la meme chose.
-- Valide aussi les codes VE1 / L56 / DSP (jamais vus dans les extractions, seul DMT l'a ete).

SELECT NVL(dir.batchprefix, '(hors DKA)')                     AS BATCHPREFIX,
       NVL(aia.attribute9, '(vide)')                           AS FOLIO,
       COUNT(*)                                                AS NB_FACTURES,
       COUNT(DISTINCT aia.attribute10)                         AS NB_FICHIERS_AP,
       COUNT(DISTINCT dir.nom_fichier)                         AS NB_FICHIERS_DKA,
       MIN(aia.attribute10)                                    AS EXEMPLE_FICHIER_AP,
       MIN(dir.nom_fichier)                                    AS EXEMPLE_FICHIER_DKA,
       MIN(dir.imagefile)                                      AS EXEMPLE_IMAGEFILE
FROM   ap_invoices_all aia
LEFT JOIN (SELECT num_fact, MIN(batchprefix) AS batchprefix, MIN(nom_fichier) AS nom_fichier, MIN(imagefile) AS imagefile
           FROM   dka_iapfacxgs_reporting_all
           WHERE  date_creation >= TO_CHAR(TRUNC(SYSDATE) - 60, 'YYYYMMDD')
           GROUP BY num_fact) dir ON dir.num_fact = TRIM(aia.invoice_num)
WHERE  aia.creation_date > TRUNC(SYSDATE) - 30
GROUP BY NVL(dir.batchprefix, '(hors DKA)'), NVL(aia.attribute9, '(vide)')
ORDER BY NB_FACTURES DESC;
