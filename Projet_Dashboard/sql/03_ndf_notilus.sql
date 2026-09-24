-- NOTILUS - Comptage des notes de frais
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT 'NOTILUS'                                                                  AS CONTROLE,
       TO_CHAR(TRUNC(creation_date), 'DD/MM/YY')                                  AS DATE_CR,
       RTRIM(TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))           AS JOUR,
       COUNT(*)                                                                    AS NB_NDF,
       ROUND(SUM(invoice_amount))                                                  AS MONTANT_TOT
FROM   ap_invoices_all
WHERE  attribute9 = 'NOT'
AND    creation_date > SYSDATE - &nb_jours_histo
GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(creation_date) DESC;
