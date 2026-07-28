-- =====================================================================
-- Traitements tournant au maximum 4 fois par mois
-- =====================================================================
-- Date de création : 18/03/2026
-- Base de données  : Oracle EBS 12.2.x
--
-- OBJECTIF : Identifier les programmes du batch du soir dont le nombre
--            d'exécutions ne dépasse pas 4 fois sur un mois donné.
--            Cela couvre les traitements mensuels, ponctuels ou de fin
--            de mois limités (ex : refacturation, HYPERION, GL récurrent).
--
-- FENÊTRE ANALYSÉE : 6 derniers mois complets (fenêtre glissante)
-- FENÊTRE SOIR     : 19h00 → 06h59 le lendemain
-- EXCLUSIONS       : programmes système (OAM, Purge, Workflow)
--
-- VOIR : Analyse_Batch_Non_Lance_17032026.md — Sections 3 et 5
-- =====================================================================

WITH
-- Étape 1 : Base des exécutions du soir, normalisées au mois-soir
base AS (
    SELECT
        fcp.user_concurrent_program_name  AS nom_programme,
        fcp.concurrent_program_name       AS nom_technique,
        -- Normalisation : si avant 7h, on rattache au mois du soir précédent
        TRUNC(
            CASE
                WHEN TO_NUMBER(TO_CHAR(fcr.actual_start_date, 'HH24')) < 7
                THEN fcr.actual_start_date - 1
                ELSE fcr.actual_start_date
            END,
            'MM'
        ) AS mois_soir,
        fcr.status_code
    FROM apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
    WHERE
        -- Fenêtre glissante : 6 derniers mois
        fcr.actual_start_date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)
        -- Uniquement les exécutions du soir (19h → 07h)
        AND (   TO_NUMBER(TO_CHAR(fcr.actual_start_date, 'HH24')) >= 19
             OR TO_NUMBER(TO_CHAR(fcr.actual_start_date, 'HH24')) < 7)
        -- Exclusion des programmes système sans valeur métier
        AND fcp.concurrent_program_name NOT IN (
            'FNDOAMCOL',  -- OAM Dashboard Collection
            'FNDCPPUR',   -- Purge Concurrent Requests
            'FNDWFBG',    -- Workflow Background Process
            'FNDWFPR'     -- Purge Obsolete Workflow Data
        )
),

-- Étape 2 : Comptage par programme et par mois
par_mois AS (
    SELECT
        nom_programme,
        nom_technique,
        mois_soir,
        COUNT(*)                                         AS nb_exec_mois,
        SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END) AS nb_erreurs_mois
    FROM base
    GROUP BY nom_programme, nom_technique, mois_soir
),

-- Étape 3 : Agrégation par programme sur tous les mois
agreg AS (
    SELECT
        nom_programme,
        nom_technique,
        COUNT(DISTINCT mois_soir)            AS nb_mois_actifs,
        SUM(nb_exec_mois)                    AS total_executions,
        ROUND(AVG(nb_exec_mois), 1)          AS moy_exec_par_mois,
        MAX(nb_exec_mois)                    AS max_exec_un_mois,
        MIN(nb_exec_mois)                    AS min_exec_un_mois,
        SUM(nb_erreurs_mois)                 AS total_erreurs,
        -- Détail mois par mois (liste des mois actifs avec leur comptage)
        LISTAGG(
            TO_CHAR(mois_soir, 'MON-YY') || ':' || nb_exec_mois,
            '  |  '
        ) WITHIN GROUP (ORDER BY mois_soir)  AS detail_par_mois
    FROM par_mois
    GROUP BY nom_programme, nom_technique
)

-- Résultat final : programmes avec MAX ≤ 4 exec/mois
-- ET actifs sur au moins 2 mois (pour distinguer des one-shot)
SELECT
    nom_programme,
    nom_technique,
    nb_mois_actifs,
    total_executions,
    moy_exec_par_mois,
    max_exec_un_mois,
    ROUND(total_erreurs * 100.0 / NULLIF(total_executions, 0), 0) AS pct_erreurs,
    detail_par_mois
FROM agreg
WHERE
    max_exec_un_mois <= 4          -- jamais plus de 4 fois sur un même mois
    AND nb_mois_actifs >= 2        -- présent sur au moins 2 mois différents
ORDER BY
    moy_exec_par_mois DESC,
    nb_mois_actifs DESC,
    nom_technique
;

-- =====================================================================
-- VARIANTE : inclure aussi les programmes apparus une seule fois
-- (utile pour identifier des traitements one-shot ou nouveaux)
-- =====================================================================
/*
... même requête sans le filtre "AND nb_mois_actifs >= 2" ...

WHERE max_exec_un_mois <= 4
ORDER BY moy_exec_par_mois DESC, nom_technique;
*/
