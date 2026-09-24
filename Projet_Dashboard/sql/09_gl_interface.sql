-- GL - Interface (en attente)
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

-- GL_INTERFACE est volontairement lue sans borne de date : c'est le stock en
-- attente qui fait le controle. On ajoute l'anciennete de la plus vieille
-- ligne, qui est l'information reellement actionnable le matin.
SELECT 'GL_INTERFACE'                                AS CONTROLE,
       SUBSTR(attribute10, 1, 40)                    AS SOURCE,
       SUBSTR(attribute9,  1, 15)                    AS TYPE_GL,
       status                                        AS STATUS_GL,
       COUNT(*)                                      AS NB_LIGNES,
       ROUND(SUM(entered_dr))                        AS TOT_DEBIT,
       ROUND(SUM(entered_cr))                        AS TOT_CREDIT,
       TO_CHAR(MIN(date_created), 'DD/MM/YY')        AS PLUS_ANCIEN,
       TRUNC(SYSDATE) - TRUNC(MIN(date_created))     AS AGE_J
FROM   gl_interface
GROUP BY attribute10, attribute9, status
ORDER BY MIN(date_created);
