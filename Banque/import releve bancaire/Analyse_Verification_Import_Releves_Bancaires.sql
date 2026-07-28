-- =====================================================================
-- Analyse et Vérification de l'Import des Relevés Bancaires
-- =====================================================================
-- Date de création : 15/05/2026
-- Auteur           : GitHub Copilot / Équipe Finance Dalkia
-- Base de données  : Oracle EBS 12.2.13 (19.25.0.0.0)
-- Schéma custom    : XXRB (module rapprochement bancaire)
--
-- OBJECTIF :
--   Vérifier que les relevés bancaires importés via le programme RBAFBIMP
--   (Import fichier des banques - format AFB120) sont correctement présents
--   dans les tables XXRB.
--
-- FLUX D'IMPORT :
--   Fichier AFB120.txt
--     → RBAFBIMP (programme concurrent)
--       → XXRB.RB_BATCH_IMPORT   (en-têtes de batch / suivi import)
--       → XXRB.RB_LINES_ALL      (lignes de relevé actives)
--
-- NOTE : Les tables standard Oracle CE (CE_STATEMENT_HEADERS,
--        CE_STATEMENT_LINES) ne sont PAS utilisées dans cet environnement.
--        Le module XXRB est le référentiel des relevés bancaires.
--
-- TABLES PRINCIPALES :
--   XXRB.RB_BATCH_IMPORT    : Suivi des imports (642 K enregistrements)
--   XXRB.RB_LINES_ALL       : Lignes de relevé actives (10,7 M lignes)
--   XXRB.RB_ARCHIVES_ALL    : Lignes archivées / rapprochées (6,7 M)
--   XXRB.RB_BANK_ACCOUNTS_ALL : Comptes bancaires paramétrés (707)
--
-- CLÉ DE JOINTURE : RB_BATCH_IMPORT.BATCH_ID + BANK_ACCOUNT_ID
--                   → RB_LINES_ALL.BATCH_ID + BANK_ACCOUNT_ID
-- =====================================================================


-- =====================================================================
-- REQUÊTE 1 : SYNTHÈSE GLOBALE DU JOUR J-1
-- Donne un résumé en une ligne : total batches, OK, anomalies, erreurs
-- =====================================================================
SELECT
    COUNT(*)                                                     AS total_batches,
    SUM(CASE WHEN NVL(rbi.lines, 0) = NVL(cnt.nb_reel, 0)
             THEN 1 ELSE 0 END)                                  AS batches_ok,
    SUM(CASE WHEN NVL(rbi.lines, 0) != NVL(cnt.nb_reel, 0)
             THEN 1 ELSE 0 END)                                  AS batches_anomalie,
    SUM(CASE WHEN NVL(rbi.nb_errors, 0) > 0
             THEN 1 ELSE 0 END)                                  AS batches_avec_erreurs,
    SUM(NVL(rbi.lines, 0))                                       AS total_lignes_attendu,
    SUM(NVL(cnt.nb_reel, 0))                                     AS total_lignes_reel,
    SUM(NVL(rbi.lines, 0)) - SUM(NVL(cnt.nb_reel, 0))           AS ecart
FROM
    xxrb.rb_batch_import rbi
LEFT JOIN (
    SELECT   batch_id,
             bank_account_id,
             COUNT(*) AS nb_reel
    FROM     xxrb.rb_lines_all
    GROUP BY batch_id,
             bank_account_id
) cnt
    ON  cnt.batch_id        = rbi.batch_id
    AND cnt.bank_account_id = rbi.bank_account_id
WHERE
    TRUNC(rbi.import_date) = TRUNC(SYSDATE - 1)
;


-- =====================================================================
-- REQUÊTE 2 : DÉTAIL PAR COMPTE BANCAIRE (toutes les lignes J-1)
-- Permet de voir compte par compte le statut de l'import
-- Colonnes clés :
--   NB_LIGNES_ATTENDU  : valeur dans RB_BATCH_IMPORT.LINES
--   NB_LIGNES_REEL     : lignes effectivement dans RB_LINES_ALL
--   ECART              : différence (0 = OK, <>0 = anomalie)
--   STATUT             : OK / ANOMALIE / SANS_LIGNES / ERREUR_IMPORT
-- =====================================================================
SELECT
    TO_CHAR(rbi.import_date, 'DD/MM/YYYY HH24:MI')              AS date_import,
    rbi.bank_account_num,
    rbi.currency_code,
    rbi.batch_id,
    rbi.import_id,
    NVL(rbi.lines, 0)                                           AS nb_lignes_attendu,
    NVL(cnt.nb_reel, 0)                                         AS nb_lignes_reel,
    NVL(rbi.lines, 0) - NVL(cnt.nb_reel, 0)                    AS ecart,
    NVL(rbi.nb_errors, 0)                                       AS nb_erreurs,
    CASE
        WHEN NVL(rbi.nb_errors, 0) > 0
            THEN 'ERREUR_IMPORT'
        WHEN NVL(rbi.lines, 0) = 0 AND NVL(cnt.nb_reel, 0) = 0
            THEN 'SANS_LIGNES'
        WHEN NVL(rbi.lines, 0) = NVL(cnt.nb_reel, 0)
            THEN 'OK'
        ELSE 'ANOMALIE'
    END                                                          AS statut,
    rbi.batch_start_date,
    rbi.batch_end_date
FROM
    xxrb.rb_batch_import rbi
LEFT JOIN (
    SELECT   batch_id,
             bank_account_id,
             COUNT(*) AS nb_reel
    FROM     xxrb.rb_lines_all
    GROUP BY batch_id,
             bank_account_id
) cnt
    ON  cnt.batch_id        = rbi.batch_id
    AND cnt.bank_account_id = rbi.bank_account_id
WHERE
    TRUNC(rbi.import_date) = TRUNC(SYSDATE - 1)
ORDER BY
    CASE
        WHEN NVL(rbi.nb_errors, 0) > 0                          THEN 1
        WHEN NVL(rbi.lines, 0) != NVL(cnt.nb_reel, 0)          THEN 2
        ELSE 3
    END,
    rbi.bank_account_num
;


-- =====================================================================
-- REQUÊTE 3 : ANOMALIES UNIQUEMENT (écart entre attendu et réel)
-- Résultat vide = tout est OK
-- =====================================================================
SELECT
    rbi.bank_account_num,
    rbi.currency_code,
    rbi.batch_id,
    NVL(rbi.lines, 0)                                           AS nb_lignes_attendu,
    NVL(cnt.nb_reel, 0)                                         AS nb_lignes_reel,
    NVL(rbi.lines, 0) - NVL(cnt.nb_reel, 0)                    AS ecart,
    NVL(rbi.nb_errors, 0)                                       AS nb_erreurs,
    TO_CHAR(rbi.import_date, 'DD/MM/YYYY HH24:MI')              AS date_import
FROM
    xxrb.rb_batch_import rbi
LEFT JOIN (
    SELECT   batch_id,
             bank_account_id,
             COUNT(*) AS nb_reel
    FROM     xxrb.rb_lines_all
    GROUP BY batch_id,
             bank_account_id
) cnt
    ON  cnt.batch_id        = rbi.batch_id
    AND cnt.bank_account_id = rbi.bank_account_id
WHERE
    TRUNC(rbi.import_date) = TRUNC(SYSDATE - 1)
    AND (
        NVL(rbi.lines, 0) != NVL(cnt.nb_reel, 0)   -- écart de lignes
        OR NVL(rbi.nb_errors, 0) > 0                 -- erreurs d'import
    )
ORDER BY
    rbi.bank_account_num
;


-- =====================================================================
-- REQUÊTE 4 : COMPTES NON IMPORTÉS (présents dans RB_BANK_ACCOUNTS_ALL
--             mais absents de RB_BATCH_IMPORT hier)
-- Permet de détecter les comptes pour lesquels aucun fichier n'est arrivé
-- Note : exclure les comptes inactifs (STATUS != 'A' ou END_DATE dépassée)
-- =====================================================================
SELECT
    rba.bank_account_id,
    rba.status,
    rba.import_status,
    rba.last_match_date
FROM
    xxrb.rb_bank_accounts_all rba
WHERE
    NVL(rba.status, 'A') = 'A'                         -- comptes actifs
    AND NVL(rba.end_date, SYSDATE + 1) > SYSDATE        -- non clôturés
    AND NOT EXISTS (
        SELECT 1
        FROM   xxrb.rb_batch_import rbi
        WHERE  rbi.bank_account_id = rba.bank_account_id
        AND    TRUNC(rbi.import_date) = TRUNC(SYSDATE - 1)
    )
ORDER BY
    rba.bank_account_id
;


-- =====================================================================
-- REQUÊTE 5 : DÉTAIL DES LIGNES IMPORTÉES HIER (échantillon)
-- Explore le contenu de RB_LINES_ALL pour un compte donné
-- → Remplacer :bank_account_num par le numéro de compte voulu
-- =====================================================================
SELECT
    rl.line_id,
    rl.bank_account_id,
    rl.batch_id,
    rl.import_id,
    rl.line_date,
    rl.bank_date,
    rl.amount,
    rl.currency_code,
    rl.bank_transaction_code,
    rl.description,
    rl.matching_status,                -- N=Non rapproché, M=Rapproché, P=En attente
    rl.type,                           -- R=Relevé bancaire, G=GL, etc.
    rl.line_type
FROM
    xxrb.rb_lines_all rl
JOIN
    xxrb.rb_batch_import rbi
    ON  rbi.batch_id        = rl.batch_id
    AND rbi.bank_account_id = rl.bank_account_id
WHERE
    TRUNC(rbi.import_date) = TRUNC(SYSDATE - 1)
    AND rbi.bank_account_num = :bank_account_num       -- ex : '00012063026'
ORDER BY
    rl.line_date,
    rl.line_id
;


-- =====================================================================
-- REQUÊTE 6 : TRAITEMENTS CONCURRENT XXRB (reproduit la vue de la capture)
-- Affiche les programmes XXRB : import, rapprochement auto, balance, etc.
-- Colonnes : DATE_DÉBUT, DATE_FIN, MEANING (phase), MEANING_1 (statut),
--            NUM_TRAITEMENT, CLÉ_RÉGION (user), RESPONSIBILITY_NAME, NOM_TRAITEMENT
-- Remplacer TRUNC(SYSDATE) - 1 par la date souhaitée si besoin
-- =====================================================================
SELECT
    fcr.actual_start_date                                                        AS date_debut,
    fcr.actual_completion_date                                                   AS date_fin,
    CASE fcr.phase_code
        WHEN 'C' THEN 'Terminé'
        WHEN 'P' THEN 'En attente'
        WHEN 'R' THEN 'En cours'
        WHEN 'I' THEN 'Inactif'
        ELSE            fcr.phase_code
    END                                                                          AS meaning,
    CASE fcr.status_code
        WHEN 'C' THEN 'Normal'
        WHEN 'G' THEN 'Avertissement'
        WHEN 'E' THEN 'Erreur'
        WHEN 'X' THEN 'Annulé'
        WHEN 'D' THEN 'Annulé'
        WHEN 'R' THEN 'Normal'
        WHEN 'W' THEN 'En attente'
        ELSE            fcr.status_code
    END                                                                          AS meaning_1,
    fcr.request_id                                                               AS num_traitement,
    fu.user_name                                                                 AS cle_region,
    frvl.responsibility_name,
    fcp.user_concurrent_program_name                                             AS nom_traitement,
    SUBSTR(fcr.argument_text, 1, 60)                                             AS parametres,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)    AS duree_min,
    SUBSTR(fcr.completion_text, 1, 80)                                           AS message
FROM
    fnd_concurrent_requests       fcr
JOIN fnd_concurrent_programs_vl   fcp
    ON  fcp.concurrent_program_id        = fcr.concurrent_program_id
    AND fcp.application_id               = fcr.program_application_id
JOIN fnd_user                     fu
    ON  fu.user_id                       = fcr.requested_by
LEFT JOIN fnd_responsibility_vl   frvl
    ON  frvl.responsibility_id           = fcr.responsibility_id
    AND frvl.application_id              = fcr.responsibility_application_id
WHERE
    fcp.user_concurrent_program_name LIKE 'XXRB%'
    AND fcr.actual_start_date >= TRUNC(SYSDATE) - 1
ORDER BY
    fcr.actual_start_date
;


-- =====================================================================
-- REQUÊTE 7 : HISTORIQUE SUR N JOURS (pour suivi de tendance)
-- Remplacer :v_nb_jours par le nombre de jours souhaité (ex : 7)
-- =====================================================================
SELECT
    TRUNC(rbi.import_date)                                       AS date_import,
    TO_CHAR(rbi.import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
    COUNT(DISTINCT rbi.batch_id)                                 AS nb_batches,
    COUNT(DISTINCT rbi.bank_account_id)                          AS nb_comptes,
    SUM(NVL(rbi.lines, 0))                                       AS total_lignes_attendu,
    SUM(NVL(cnt.nb_reel, 0))                                     AS total_lignes_reel,
    SUM(NVL(rbi.nb_errors, 0))                                   AS total_erreurs
FROM
    xxrb.rb_batch_import rbi
LEFT JOIN (
    SELECT   batch_id,
             bank_account_id,
             COUNT(*) AS nb_reel
    FROM     xxrb.rb_lines_all
    GROUP BY batch_id,
             bank_account_id
) cnt
    ON  cnt.batch_id        = rbi.batch_id
    AND cnt.bank_account_id = rbi.bank_account_id
WHERE
    rbi.import_date >= TRUNC(SYSDATE) - NVL(:v_nb_jours, 7)
GROUP BY
    TRUNC(rbi.import_date),
    TO_CHAR(rbi.import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY
    TRUNC(rbi.import_date) DESC
;
