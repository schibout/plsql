-- FACTURES DEMATERIALISEES - Stock par statut (DKA_DEMAT_HDR)
-- Statuts constates : INSERE (recue, pas encore integree), INTEGREE, COMPLETED.
-- Aucune colonne autre que STATUS n'est supposee : cette requete tourne quelle que soit la table.

SELECT status   AS STATUT,
       COUNT(*) AS NB
FROM   dka_demat_hdr
GROUP BY status
ORDER BY status;
