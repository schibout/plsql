-- XEROX - Factures SANS images
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

-- invoice_num n'etant pas unique en multi-organisation, la meme facture
-- ressortait plusieurs fois (F-2026-07-1 dans le log du 28/07) : une ligne par
-- facture, invoice_id regroupes. Fournisseur, date, montant et image attendue
-- (attribute3) permettent de retrouver la facture sans rouvrir Oracle.
SELECT TO_CHAR(TO_DATE(dir.date_creation, 'YYYYMMDD'), 'DD/MM/YY') AS RECUE_LE,
       NVL(dir.num_fact, '?') AS NUM_FACT,
       MIN(aps.vendor_name) AS FOURNISSEUR,
       TO_CHAR(MIN(aia.invoice_date), 'DD/MM/YY') AS DATE_FACT,
       MAX(aia.invoice_amount) AS MONTANT,
       MIN(aia.invoice_currency_code) AS DEV,
       MIN(aia.attribute3) AS IMAGE_ATTENDUE,
       NVL(MIN(dir.reference_lad), '?') AS FICHIER_XEROX,
       TRUNC(SYSDATE) - TRUNC(MIN(aia.creation_date)) AS AGE_J,
       LISTAGG(aia.invoice_id, ',') WITHIN GROUP (ORDER BY aia.invoice_id) AS INVOICE_IDS
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
LEFT JOIN ap_suppliers aps ON aps.vendor_id = aia.vendor_id
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
AND    NOT EXISTS (SELECT 1 FROM fnd_documents fd
                   WHERE  fd.creation_date > SYSDATE - 30
                   AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                           OR fd.file_name = aia.attribute3))
GROUP BY dir.date_creation, dir.num_fact
ORDER BY MIN(aps.vendor_name), dir.num_fact;
