-- FACTURES - Synthese par source
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT 'FACTURES'                                                                   AS CONTROLE,
       TO_CHAR(TO_DATE(date_creation, 'YYYYMMDD'), 'DD/MM/YY')                      AS DATE_CR,
       DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES') AS SOURCE,
       COUNT(*)                                                                      AS NB_FACS
FROM   dka_iapfacxgs_reporting_all
WHERE  TO_DATE(date_creation, 'YYYYMMDD') > SYSDATE - &nb_jours_histo
GROUP BY date_creation, DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES')
ORDER BY date_creation DESC, SOURCE;
