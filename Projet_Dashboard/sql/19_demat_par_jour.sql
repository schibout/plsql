-- FACTURES DEMATERIALISEES - Arrivees par jour et statut (DKA_DEMAT_HDR)
-- Suppose la colonne WHO standard CREATION_DATE : en cas d'ORA-00904, corriger ici le nom de la colonne date.

SELECT TO_CHAR(TRUNC(creation_date), 'DD/MM/YY')                          AS DATE_CR,
       RTRIM(TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))   AS JOUR,
       SUM(CASE WHEN status = 'INSERE'    THEN 1 ELSE 0 END)               AS NB_INSERE,
       SUM(CASE WHEN status = 'INTEGREE'  THEN 1 ELSE 0 END)               AS NB_INTEGREE,
       SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END)               AS NB_COMPLETED,
       SUM(CASE WHEN status NOT IN ('INSERE', 'INTEGREE', 'COMPLETED') THEN 2 ELSE 0 END) AS NB_AUTRE,
       COUNT(*)                                                             AS TOTAL
FROM   dka_demat_hdr
WHERE  creation_date > SYSDATE - &nb_jours_histo
GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(creation_date) DESC;
