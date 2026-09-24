-- XEROX - Factures AVEC images (compteur)
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

-- COUNT(DISTINCT num_fact) : la double jointure (multi-organisation cote
-- ap_invoices_all, plusieurs documents cote fnd_documents) multipliait les
-- lignes et surevaluait fortement ce compteur.
SELECT COUNT(DISTINCT dir.num_fact) AS NB_AVEC_IMG
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
JOIN   fnd_documents fd ON fd.creation_date > SYSDATE - 30
       AND (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
            OR fd.file_name = aia.attribute3)
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD');
