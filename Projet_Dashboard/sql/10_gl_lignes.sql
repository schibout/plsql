-- GL - Lignes creees
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT 'GL_CREES'                                AS CONTROLE,
       TO_CHAR(TRUNC(creation_date), 'DD/MM/YY') AS DATE_CR,
       SUBSTR(attribute10, 1, 45)                AS SOURCE,
       COUNT(*)                                  AS NB_LIGNES,
       ROUND(SUM(entered_dr))                    AS TOT_DEBIT
FROM   gl_je_lines
WHERE  creation_date > SYSDATE - &nb_jours_histo
GROUP BY TRUNC(creation_date), attribute10
ORDER BY TRUNC(creation_date) DESC, attribute10 DESC;
