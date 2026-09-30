-- RAPPROCHEMENT BANCAIRE - Imports
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : 10, 19, 7.

SELECT 'RB_IMPORTS'                                                               AS CONTROLE,
       TO_CHAR(TRUNC(import_date), 'DD/MM/YY')                                     AS DATE_CR,
       RTRIM(TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))               AS JOUR,
       COUNT(*)                                                                     AS NB_CTES
FROM   rb_batch_import
WHERE  import_date > SYSDATE - 10
GROUP BY TRUNC(import_date), TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(import_date) DESC;
