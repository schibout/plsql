-- FACTURES DEMATERIALISEES - En attente d'integration (STATUS = 'INSERE'), 200 lignes max
-- SELECT * : toutes les colonnes de l'entete, sans en supposer aucune.

SELECT *
FROM   (SELECT * FROM dka_demat_hdr WHERE status = 'INSERE')
WHERE  ROWNUM <= 200;
