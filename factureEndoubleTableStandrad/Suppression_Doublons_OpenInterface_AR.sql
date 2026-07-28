-- =====================================================================
-- Suppression des factures en doublon dans les tables Open Interface AR
-- =====================================================================
-- Date de création : 10/03/2026
-- Auteur           : GitHub Copilot
-- Base de données  : Oracle EBS 12.2.13
--
-- PROBLÈME RÉSOLU :
--   Suppression des enregistrements bloqués en Open Interface AR
--   avec l'erreur "Numéro de facture en double" dans RA_INTERFACE_ERRORS_ALL.
--
-- TABLES IMPACTÉES (ordre de suppression à respecter) :
--   1. RA_INTERFACE_SALESCREDITS_ALL  (enfant des lignes)
--   2. RA_INTERFACE_DISTRIBUTIONS_ALL (enfant des lignes)
--   3. RA_INTERFACE_LINES_ALL         (table principale)
--   4. RA_INTERFACE_ERRORS_ALL        (erreurs associées)
--
-- LIEN CLÉ :
--   RA_INTERFACE_ERRORS_ALL.INTERFACE_LINE_ID
--     -> RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ID
--
-- UTILISATION :
--   1. Exécuter d'abord le bloc de DIAGNOSTIC (SELECT COUNT(*))
--   2. Vérifier les résultats avant toute suppression
--   3. Exécuter le bloc DELETE dans une transaction (ROLLBACK possible)
--   4. COMMIT uniquement après validation des counts
-- =====================================================================


-- =====================================================================
-- ÉTAPE 1 : DIAGNOSTIC - Vérification avant suppression
-- =====================================================================

-- Nombre total d'erreurs "Numéro de facture en double"
SELECT COUNT(*) AS nb_erreurs_doublon
FROM AR.RA_INTERFACE_ERRORS_ALL
WHERE MESSAGE_TEXT = 'Numéro de facture en double';

-- Détail des lignes en doublon (pour vérification)
SELECT
    RIL.INTERFACE_LINE_ID,
    RIL.BATCH_SOURCE_NAME,
    RIL.ORIG_SYSTEM_BILL_CUSTOMER_REF,
    RIL.TRX_NUMBER,
    RIL.TRX_DATE,
    RIL.AMOUNT,
    RIL.ORG_ID,
    RIE.MESSAGE_TEXT,
    RIE.INVALID_VALUE
FROM AR.RA_INTERFACE_LINES_ALL    RIL
JOIN AR.RA_INTERFACE_ERRORS_ALL   RIE
    ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
ORDER BY RIL.BATCH_SOURCE_NAME, RIL.TRX_NUMBER;

-- Nombre de lignes à supprimer dans chaque table
SELECT
    'RA_INTERFACE_LINES_ALL'         AS table_name,
    COUNT(DISTINCT RIL.INTERFACE_LINE_ID) AS nb_lignes_a_supprimer
FROM AR.RA_INTERFACE_LINES_ALL  RIL
JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
    ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
UNION ALL
SELECT
    'RA_INTERFACE_DISTRIBUTIONS_ALL' AS table_name,
    COUNT(*) AS nb_lignes_a_supprimer
FROM AR.RA_INTERFACE_DISTRIBUTIONS_ALL RID
WHERE RID.INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
)
UNION ALL
SELECT
    'RA_INTERFACE_SALESCREDITS_ALL'  AS table_name,
    COUNT(*) AS nb_lignes_a_supprimer
FROM AR.RA_INTERFACE_SALESCREDITS_ALL RIS
WHERE RIS.INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
)
UNION ALL
SELECT
    'RA_INTERFACE_ERRORS_ALL'        AS table_name,
    COUNT(*) AS nb_lignes_a_supprimer
FROM AR.RA_INTERFACE_ERRORS_ALL RIE
WHERE RIE.INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE2
        ON RIE2.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE2.MESSAGE_TEXT = 'Numéro de facture en double'
);


-- =====================================================================
-- ÉTAPE 2 : SUPPRESSION (exécuter après validation du diagnostic)
-- =====================================================================
-- /!\ ATTENTION : Exécuter dans une transaction - COMMIT à la fin
--                 après vérification des counts retournés
-- =====================================================================

-- Sous-requête partagée : liste des INTERFACE_LINE_ID en doublon
-- (utilisée comme référence pour toutes les suppressions)

-- 2.1 - Suppression des crédits de vente associés
DELETE FROM AR.RA_INTERFACE_SALESCREDITS_ALL
WHERE INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
);

-- Affichage du nombre de lignes supprimées
-- (vérifier dans le client SQL : ex. "X ligne(s) supprimée(s)")

-- 2.2 - Suppression des distributions associées
DELETE FROM AR.RA_INTERFACE_DISTRIBUTIONS_ALL
WHERE INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
);

-- 2.3 - Suppression des erreurs associées
DELETE FROM AR.RA_INTERFACE_ERRORS_ALL
WHERE INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double'
);

-- 2.4 - Suppression des lignes principales
DELETE FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_LINE_ID IN (
    SELECT RIL.INTERFACE_LINE_ID
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE_TEMP
        ON RIE_TEMP.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE_TEMP.MESSAGE_TEXT = 'Numéro de facture en double'
);

-- ATTENTION : Étant donné que les erreurs ont été supprimées en 2.3,
-- la sous-requête ci-dessus ne trouvera plus de correspondances.
-- Utiliser une table temporaire ou une collection si nécessaire.
-- Voir version avec collecte préalable des IDs ci-dessous (recommandée).

-- =====================================================================
-- ÉTAPE 2 (VERSION RECOMMANDÉE) : Avec collecte préalable des IDs
-- Utiliser ce bloc PL/SQL plutôt que les DELETEs standalone ci-dessus
-- =====================================================================

DECLARE
    -- Collection des INTERFACE_LINE_ID à supprimer
    TYPE t_id_list IS TABLE OF AR.RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ID%TYPE;
    l_ids t_id_list;

    l_count_salescredits    NUMBER := 0;
    l_count_distributions   NUMBER := 0;
    l_count_errors          NUMBER := 0;
    l_count_lines           NUMBER := 0;

BEGIN
    -- Collecte des IDs des lignes en doublon
    SELECT DISTINCT RIL.INTERFACE_LINE_ID
    BULK COLLECT INTO l_ids
    FROM AR.RA_INTERFACE_LINES_ALL  RIL
    JOIN AR.RA_INTERFACE_ERRORS_ALL RIE
        ON RIE.INTERFACE_LINE_ID = RIL.INTERFACE_LINE_ID
    WHERE RIE.MESSAGE_TEXT = 'Numéro de facture en double';

    DBMS_OUTPUT.PUT_LINE('Nombre de lignes identifiées : ' || l_ids.COUNT);

    IF l_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucun enregistrement à supprimer.');
        RETURN;
    END IF;

    -- 1. Suppression dans RA_INTERFACE_SALESCREDITS_ALL
    FORALL i IN 1..l_ids.COUNT
        DELETE FROM AR.RA_INTERFACE_SALESCREDITS_ALL
        WHERE INTERFACE_LINE_ID = l_ids(i);
    l_count_salescredits := SQL%ROWCOUNT;

    -- 2. Suppression dans RA_INTERFACE_DISTRIBUTIONS_ALL
    FORALL i IN 1..l_ids.COUNT
        DELETE FROM AR.RA_INTERFACE_DISTRIBUTIONS_ALL
        WHERE INTERFACE_LINE_ID = l_ids(i);
    l_count_distributions := SQL%ROWCOUNT;

    -- 3. Suppression dans RA_INTERFACE_ERRORS_ALL (toutes erreurs de ces lignes)
    FORALL i IN 1..l_ids.COUNT
        DELETE FROM AR.RA_INTERFACE_ERRORS_ALL
        WHERE INTERFACE_LINE_ID = l_ids(i);
    l_count_errors := SQL%ROWCOUNT;

    -- 4. Suppression dans RA_INTERFACE_LINES_ALL
    FORALL i IN 1..l_ids.COUNT
        DELETE FROM AR.RA_INTERFACE_LINES_ALL
        WHERE INTERFACE_LINE_ID = l_ids(i);
    l_count_lines := SQL%ROWCOUNT;

    -- Bilan des suppressions
    DBMS_OUTPUT.PUT_LINE('===== BILAN DES SUPPRESSIONS =====');
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_SALESCREDITS_ALL  : ' || l_count_salescredits  || ' ligne(s) supprimée(s)');
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_DISTRIBUTIONS_ALL : ' || l_count_distributions || ' ligne(s) supprimée(s)');
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_ERRORS_ALL        : ' || l_count_errors        || ' ligne(s) supprimée(s)');
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_LINES_ALL         : ' || l_count_lines         || ' ligne(s) supprimée(s)');
    DBMS_OUTPUT.PUT_LINE('==================================');

    -- COMMIT : décommenter après validation
    -- COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('COMMIT effectué avec succès.');

    -- Pour annuler : décommenter la ligne suivante
    -- ROLLBACK;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR - Rollback effectué : ' || SQLERRM);
        RAISE;
END;
/


-- =====================================================================
-- ÉTAPE 3 : VÉRIFICATION POST-SUPPRESSION
-- =====================================================================

-- Contrôle : ne doit plus retourner de lignes après suppression
SELECT COUNT(*) AS nb_erreurs_restantes
FROM AR.RA_INTERFACE_ERRORS_ALL
WHERE MESSAGE_TEXT = 'Numéro de facture en double';
