-- RAPPROCHEMENT BANCAIRE - Imports
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT 'RB_IMPORTS'                                                               AS CONTROLE,
       TO_CHAR(TRUNC(import_date), 'DD/MM/YY')                                     AS DATE_CR,
       RTRIM(TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))               AS JOUR,
       COUNT(*)                                                                     AS NB_CTES
FROM   rb_batch_import
WHERE  import_date > SYSDATE - &nb_jours_histo
GROUP BY TRUNC(import_date), TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(import_date) DESC;
