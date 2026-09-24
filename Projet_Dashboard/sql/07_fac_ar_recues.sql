-- FACTURES AR - Recues (24 h) par origine et statut
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT dii.origin AS ORIGINE, dii.oa_status AS STATUT_OA,
       COUNT(DISTINCT dii.invoice_number) AS NB_FACTURES, COUNT(*) AS NB_LIGNES,
       ROUND(SUM(dii.fmt_amount)) AS MONTANT,
       TO_CHAR(MIN(dii.creation_date), 'DD/MM HH24:MI') AS PREMIERE,
       TO_CHAR(MAX(dii.creation_date), 'DD/MM HH24:MI') AS DERNIERE,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM ra_interface_lines_all ril WHERE ril.trx_number = dii.invoice_number)
                THEN 1 ELSE 0 END) AS LIGNES_ENCORE_EN_INTERFACE
FROM   dka_iarpafac_interface dii
WHERE  dii.creation_date >= SYSDATE - 1
GROUP BY dii.origin, dii.oa_status
ORDER BY dii.origin, dii.oa_status;
