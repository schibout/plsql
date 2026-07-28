-- =====================================================================
-- Suppression des doublons - DKA_IARPAFAC_INTERFACE (PRODUCTION)
-- =====================================================================
-- Date de création : 05/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- ⚠️  ATTENTION : CE SCRIPT MODIFIE DIRECTEMENT LA TABLE DE PRODUCTION
--
-- OBJECTIF : Supprimer les enregistrements en doublon dans DKA_IARPAFAC_INTERFACE
--            en conservant l'enregistrement le plus ancien (plus petit IARPAFAC_ID)
--
-- APPROCHE : Travail direct sur table de PRODUCTION avec sauvegarde préalable
--
-- CRITÈRES DE DOUBLON :
--   - INVOICE_NUMBER (numéro de facture)
--   - LINE_NUMBER (numéro de ligne)
--   - LINE_TYPE (type de ligne : CLIENT, PRODUIT, GESTION, SURTAXE)
--   - LOCAL_ACCOUNT (compte comptable)
--   - COMPANY_CODE (code société)
--   - ORIGIN (origine)
--   - FIC_IDENT (fichier source)
--
-- USAGE : 
--   0. Exécuter PARTIE 0 pour créer une SAUVEGARDE de DKA_IARPAFAC_INTERFACE
--   1. Exécuter PARTIE 1 pour voir les doublons AVANT suppression
--   2. Exécuter PARTIE 2 pour voir les enregistrements qui seront supprimés
--   3. Exécuter PARTIE 3 pour supprimer les doublons sur la table PRODUCTION
--   4. Exécuter PARTIE 4 pour vérifier qu'il n'y a plus de doublons
--   5. Exécuter PARTIE 5 (optionnel) pour restaurer depuis la sauvegarde si problème
--
-- ⚠️  SÉCURITÉ : Une sauvegarde complète est créée avant toute modification
-- ⚠️  La table de production DKA_IARPAFAC_INTERFACE sera MODIFIÉE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

-- =============================================================================
-- PARTIE 0 : CRÉATION SAUVEGARDE - DKA_IARPAFAC_INTERFACE_BKP_05032026
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 0 : CRÉATION DE LA SAUVEGARDE DE SÉCURITÉ
PROMPT =====================================================
PROMPT
PROMPT ⚠️  ATTENTION : Vous allez travailler sur la table de PRODUCTION
PROMPT ✓  Une sauvegarde complète sera créée avant toute modification
PROMPT

DECLARE
    v_table_exists NUMBER := 0;
    v_nb_enreg     NUMBER := 0;
    v_debut        TIMESTAMP;
    v_fin          TIMESTAMP;
    v_duree        NUMBER;
    v_backup_name  VARCHAR2(100) := 'DKA_IARPAFAC_INTERFACE_BKP_05032026';
BEGIN
    v_debut := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('Vérification de la table de production...');
    DBMS_OUTPUT.PUT_LINE('Début : ' || TO_CHAR(v_debut, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Compter les enregistrements de production
    SELECT COUNT(*) INTO v_nb_enreg FROM DKA_IARPAFAC_INTERFACE;
    DBMS_OUTPUT.PUT_LINE('Nombre d''enregistrements en PRODUCTION : ' || v_nb_enreg);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Vérifier si la sauvegarde existe déjà
    SELECT COUNT(*)
    INTO   v_table_exists
    FROM   user_tables
    WHERE  table_name = v_backup_name;
    
    IF v_table_exists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠ La table de sauvegarde ' || v_backup_name || ' existe déjà');
        
        -- Compter les enregistrements
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || v_backup_name INTO v_nb_enreg;
        DBMS_OUTPUT.PUT_LINE('  Nombre d''enregistrements dans l''ancienne sauvegarde : ' || v_nb_enreg);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Suppression de l''ancienne sauvegarde...');
        
        -- Supprimer l'ancienne sauvegarde
        EXECUTE IMMEDIATE 'DROP TABLE ' || v_backup_name;
        DBMS_OUTPUT.PUT_LINE('✓ Ancienne sauvegarde supprimée');
        DBMS_OUTPUT.PUT_LINE('');
    END IF;
    
    -- Créer la sauvegarde
    DBMS_OUTPUT.PUT_LINE('Création de la sauvegarde ' || v_backup_name || '...');
    DBMS_OUTPUT.PUT_LINE('⏳ Veuillez patienter, cela peut prendre quelques minutes...');
    
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_backup_name || ' AS SELECT * FROM DKA_IARPAFAC_INTERFACE';
    
    -- Compter les enregistrements sauvegardés
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || v_backup_name INTO v_nb_enreg;
    
    v_fin := SYSTIMESTAMP;
    v_duree := EXTRACT(SECOND FROM (v_fin - v_debut)) + 
               EXTRACT(MINUTE FROM (v_fin - v_debut)) * 60;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ Sauvegarde créée avec succès');
    DBMS_OUTPUT.PUT_LINE('  Table de sauvegarde : ' || v_backup_name);
    DBMS_OUTPUT.PUT_LINE('  Nombre d''enregistrements sauvegardés : ' || v_nb_enreg);
    DBMS_OUTPUT.PUT_LINE('  Durée : ' || ROUND(v_duree, 2) || ' secondes');
    DBMS_OUTPUT.PUT_LINE('  Fin : ' || TO_CHAR(v_fin, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Créer un index sur la clé primaire pour meilleures performances
    DBMS_OUTPUT.PUT_LINE('Création d''un index sur IARPAFAC_ID...');
    EXECUTE IMMEDIATE 'CREATE INDEX ' || v_backup_name || '_IDX ON ' || v_backup_name || '(IARPAFAC_ID)';
    DBMS_OUTPUT.PUT_LINE('✓ Index créé');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('IMPORTANT :');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('⚠️  Table de production : DKA_IARPAFAC_INTERFACE (SERA MODIFIÉE)');
    DBMS_OUTPUT.PUT_LINE('✓  Table de sauvegarde  : ' || v_backup_name || ' (pour restauration)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Les suppressions de doublons seront faites sur la table PRODUCTION.');
    DBMS_OUTPUT.PUT_LINE('En cas de problème, vous pourrez restaurer depuis la sauvegarde.');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR lors de la création de la sauvegarde : ' || SQLERRM);
        RAISE;
END;
/

PROMPT
PROMPT Continuer avec le diagnostic...
PROMPT

-- =============================================================================
-- PARTIE 1 : DIAGNOSTIC - Comptage des doublons (TABLE PRODUCTION)
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 1 : DIAGNOSTIC DES DOUBLONS (PRODUCTION)
PROMPT =====================================================
PROMPT

-- Vue d'ensemble des doublons
SELECT 
    'TOTAL_ENREGISTREMENTS' AS METRIQUE,
    COUNT(*) AS VALEUR
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'FACTURES_UNIQUES',
    COUNT(DISTINCT INVOICE_NUMBER)
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'ENREGISTREMENTS_EN_DOUBLON',
    COUNT(*)
FROM DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    GROUP BY dii2.INVOICE_NUMBER, dii2.LINE_NUMBER, dii2.COMPANY_CODE, 
             dii2.ORIGIN, dii2.FIC_IDENT, dii2.LOCAL_ACCOUNT, dii2.LINE_TYPE
    HAVING COUNT(*) > 1
);

PROMPT
PROMPT --- Liste des factures en doublon ---
PROMPT

-- Détail des factures en doublon (comptes 411xxx uniquement)
SELECT 
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    COMPANY_CODE,
    ORIGIN,
    LOCAL_ACCOUNT,
    FIC_IDENT,
    COUNT(*) AS NB_DOUBLONS,
    MIN(IARPAFAC_ID) AS ID_A_GARDER,
    MAX(IARPAFAC_ID) AS ID_DERNIER,
    MIN(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS PREMIERE_CREATION,
    MAX(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS DERNIERE_CREATION,
    SUM(TO_NUMBER(NVL(AMOUNT, 0))) AS MONTANT_TOTAL
FROM DKA_IARPAFAC_INTERFACE
WHERE LOCAL_ACCOUNT LIKE '411%'
GROUP BY INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE, COMPANY_CODE, ORIGIN, 
         LOCAL_ACCOUNT, FIC_IDENT
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE;

-- =============================================================================
-- PARTIE 2 : IDENTIFICATION - Enregistrements qui seront SUPPRIMÉS (PRODUCTION)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 2 : ENREGISTREMENTS QUI SERONT SUPPRIMÉS (PRODUCTION)
PROMPT =====================================================
PROMPT

-- Liste détaillée des enregistrements à supprimer
SELECT 
    'A_SUPPRIMER' AS ACTION,
    dii.IARPAFAC_ID,
    dii.INVOICE_NUMBER,
    dii.LINE_NUMBER,
    dii.LINE_TYPE,
    dii.COMPANY_CODE,
    dii.ORIGIN,
    dii.LOCAL_ACCOUNT,
    TO_CHAR(dii.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_CREATION,
    dii.OA_STATUS,
    dii.OA_REQUEST_ID,
    dii.FIC_IDENT
FROM DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    -- Garder uniquement le plus petit ID (= le plus ancien)
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
)
AND EXISTS (
    -- Vérifier qu'il existe bien des doublons
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii3
    WHERE dii3.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii3.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    GROUP BY dii3.INVOICE_NUMBER, dii3.LINE_NUMBER, dii3.COMPANY_CODE, 
             dii3.ORIGIN, dii3.FIC_IDENT, dii3.LOCAL_ACCOUNT, dii3.LINE_TYPE
    HAVING COUNT(*) > 1
)
ORDER BY dii.INVOICE_NUMBER, dii.LINE_NUMBER, dii.IARPAFAC_ID;

-- Comptage des enregistrements à supprimer
PROMPT
PROMPT --- Résumé de la suppression ---
PROMPT

SELECT 
    COUNT(*) AS NB_ENREGISTREMENTS_A_SUPPRIMER,
    COUNT(DISTINCT INVOICE_NUMBER) AS NB_FACTURES_CONCERNEES,
    MIN(IARPAFAC_ID) AS ID_MIN,
    MAX(IARPAFAC_ID) AS ID_MAX
FROM DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
)
AND EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii3
    WHERE dii3.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii3.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    GROUP BY dii3.INVOICE_NUMBER, dii3.LINE_NUMBER, dii3.COMPANY_CODE, 
             dii3.ORIGIN, dii3.FIC_IDENT, dii3.LOCAL_ACCOUNT, dii3.LINE_TYPE
    HAVING COUNT(*) > 1
);

-- =============================================================================
-- PARTIE 3 : SUPPRESSION DES DOUBLONS (⚠️  AVEC COMMIT SUR PRODUCTION)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 3 : SUPPRESSION DES DOUBLONS (PRODUCTION)
PROMPT ⚠️  ⚠️  ⚠️  ATTENTION ⚠️  ⚠️  ⚠️
PROMPT ⚠️  Les suppressions seront faites sur DKA_IARPAFAC_INTERFACE (PRODUCTION)
PROMPT ⚠️  Une sauvegarde existe dans DKA_IARPAFAC_INTERFACE_BKP_05032026
PROMPT =====================================================
PROMPT
PROMPT ⚠️  ÊTES-VOUS SÛR DE VOULOIR CONTINUER ?
PROMPT ⚠️  Appuyez sur CTRL+C pour annuler ou Entrée pour continuer...
PAUSE

DECLARE
    v_nb_supprimes NUMBER := 0;
    v_debut        TIMESTAMP;
    v_fin          TIMESTAMP;
    v_duree        NUMBER;
BEGIN
    v_debut := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('Début de la suppression sur PRODUCTION : ' || TO_CHAR(v_debut, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Suppression des doublons
    DELETE FROM DKA_IARPAFAC_INTERFACE dii
    WHERE dii.IARPAFAC_ID NOT IN (
        -- Garder uniquement le plus petit ID (= le plus ancien)
        SELECT MIN(dii2.IARPAFAC_ID)
        FROM DKA_IARPAFAC_INTERFACE dii2
        WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
        AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
        AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
        AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
        AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
        AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
        AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    )
    AND EXISTS (
        -- Vérifier qu'il existe bien des doublons
        SELECT 1
        FROM DKA_IARPAFAC_INTERFACE dii3
        WHERE dii3.INVOICE_NUMBER = dii.INVOICE_NUMBER
        AND NVL(dii3.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
        AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
        AND NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
        AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
        AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
        AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
        GROUP BY dii3.INVOICE_NUMBER, dii3.LINE_NUMBER, dii3.COMPANY_CODE, 
                 dii3.ORIGIN, dii3.FIC_IDENT, dii3.LOCAL_ACCOUNT, dii3.LINE_TYPE
        HAVING COUNT(*) > 1
    );
    
    v_nb_supprimes := SQL%ROWCOUNT;
    
    v_fin := SYSTIMESTAMP;
    v_duree := EXTRACT(SECOND FROM (v_fin - v_debut)) + 
               EXTRACT(MINUTE FROM (v_fin - v_debut)) * 60;
    
    DBMS_OUTPUT.PUT_LINE('Nombre d''enregistrements supprimés : ' || v_nb_supprimes);
    DBMS_OUTPUT.PUT_LINE('Durée : ' || ROUND(v_duree, 2) || ' secondes');
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_nb_supprimes > 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ COMMIT effectué avec succès sur la table PRODUCTION');
        DBMS_OUTPUT.PUT_LINE('✓ ' || v_nb_supprimes || ' enregistrements supprimés définitivement');
        DBMS_OUTPUT.PUT_LINE('Fin : ' || TO_CHAR(v_fin, 'DD/MM/YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('⚠️  En cas de problème, restaurez depuis DKA_IARPAFAC_INTERFACE_BKP_05032026');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠ Aucun doublon trouvé en PRODUCTION');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR lors de la suppression : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('✓ ROLLBACK effectué - Aucune modification en PRODUCTION');
        RAISE;
END;
/

-- =============================================================================
-- PARTIE 4 : VÉRIFICATION - Contrôle après suppression (PRODUCTION)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 4 : VÉRIFICATION APRÈS SUPPRESSION (PRODUCTION)
PROMPT =====================================================
PROMPT

-- Vérification qu'il n'y a plus de doublons
SELECT 
    'VERIFICATION' AS STATUT,
    COUNT(*) AS NB_DOUBLONS_RESTANTS
FROM DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    GROUP BY dii2.INVOICE_NUMBER, dii2.LINE_NUMBER, dii2.COMPANY_CODE, 
             dii2.ORIGIN, dii2.FIC_IDENT, dii2.LOCAL_ACCOUNT, dii2.LINE_TYPE
    HAVING COUNT(*) > 1
);

-- Statistiques finales
PROMPT
PROMPT --- Statistiques finales ---
PROMPT

SELECT 
    'TOTAL_ENREGISTREMENTS' AS METRIQUE,
    COUNT(*) AS VALEUR
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'FACTURES_UNIQUES',
    COUNT(DISTINCT INVOICE_NUMBER)
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'FACTURES_AVEC_COMPTE_411',
    COUNT(DISTINCT INVOICE_NUMBER)
FROM DKA_IARPAFAC_INTERFACE
WHERE LOCAL_ACCOUNT LIKE '411%'
UNION ALL
SELECT 
    'DERNIER_IARPAFAC_ID',
    MAX(IARPAFAC_ID)
FROM DKA_IARPAFAC_INTERFACE;

-- Exemple de vérification sur la facture corrigée
PROMPT
PROMPT --- Exemple : Vérification facture 0420K2603S003 ---
PROMPT

SELECT 
    IARPAFAC_ID,
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    LOCAL_ACCOUNT,
    TO_NUMBER(AMOUNT) AS MONTANT,
    DEBIT_OR_CREDIT,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_CREATION,
    OA_STATUS
FROM DKA_IARPAFAC_INTERFACE
WHERE INVOICE_NUMBER = '0420K2603S003'
ORDER BY LINE_NUMBER, IARPAFAC_ID;

-- Comparaison avec la sauvegarde
PROMPT
PROMPT --- Comparaison PRODUCTION vs SAUVEGARDE ---
PROMPT

SELECT 
    'PRODUCTION (après nettoyage)' AS SOURCE,
    COUNT(*) AS NB_TOTAL_ENREG,
    COUNT(DISTINCT INVOICE_NUMBER) AS NB_FACTURES,
    SUM(CASE WHEN LOCAL_ACCOUNT LIKE '411%' THEN 1 ELSE 0 END) AS NB_COMPTES_411
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'SAUVEGARDE (avant nettoyage)',
    COUNT(*),
    COUNT(DISTINCT INVOICE_NUMBER),
    SUM(CASE WHEN LOCAL_ACCOUNT LIKE '411%' THEN 1 ELSE 0 END)
FROM DKA_IARPAFAC_INTERFACE_BKP_05032026;

-- =============================================================================
-- PARTIE 5 : RESTAURATION D'URGENCE (si problème détecté)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 5 : RESTAURATION D'URGENCE
PROMPT =====================================================
PROMPT
PROMPT ⚠️  N'EXÉCUTER QUE SI UN PROBLÈME EST DÉTECTÉ APRÈS LA SUPPRESSION
PROMPT ⚠️  Cette partie restaure la table PRODUCTION depuis la sauvegarde
PROMPT

PROMPT
PROMPT --- Script de restauration d'urgence ---
PROMPT
PROMPT -- 1. Supprimer la table PRODUCTION modifiée
PROMPT DROP TABLE DKA_IARPAFAC_INTERFACE;
PROMPT
PROMPT -- 2. Restaurer depuis la sauvegarde
PROMPT CREATE TABLE DKA_IARPAFAC_INTERFACE AS 
PROMPT SELECT * FROM DKA_IARPAFAC_INTERFACE_BKP_05032026;
PROMPT
PROMPT -- 3. Recréer les index (si nécessaire - voir DBA)
PROMPT -- CREATE INDEX ... (demander au DBA les index originaux)
PROMPT
PROMPT -- 4. Vérifier la restauration
PROMPT SELECT COUNT(*) FROM DKA_IARPAFAC_INTERFACE;
PROMPT

-- Nettoyage de la sauvegarde (uniquement si tout est OK)
PROMPT
PROMPT --- Pour supprimer la sauvegarde après validation complète ---
PROMPT ⚠️  NE PAS EXÉCUTER avant d'être sûr que tout fonctionne correctement
PROMPT
PROMPT DROP TABLE DKA_IARPAFAC_INTERFACE_BKP_05032026;
PROMPT

PROMPT
PROMPT =====================================================
PROMPT FIN DU TRAITEMENT
PROMPT =====================================================
PROMPT
PROMPT Si "NB_DOUBLONS_RESTANTS = 0", le nettoyage de la PRODUCTION est réussi.
PROMPT
PROMPT ✓ Table de production : DKA_IARPAFAC_INTERFACE (NETTOYÉE)
PROMPT ✓ Table de sauvegarde : DKA_IARPAFAC_INTERFACE_BKP_05032026 (pour restauration)
PROMPT
PROMPT ⚠️  Conservez la sauvegarde jusqu'à validation complète par le métier
PROMPT
