-- =====================================================================
-- Sauvegarde et Suppression des doublons - DKA_IARPAFAC_INTERFACE
-- =====================================================================
-- Date de création : 07/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- OBJECTIF : 
--   1. Sauvegarder la table DKA_IARPAFAC_INTERFACE
--   2. Supprimer les enregistrements en doublon
--   3. Conserver l'enregistrement le plus ancien (plus petit IARPAFAC_ID)
--
-- ⚠️  ATTENTION : Ce script modifie directement la table de PRODUCTION
--
-- CRITÈRES DE DOUBLON :
--   - INVOICE_NUMBER (numéro de facture)
--   - LINE_NUMBER (numéro de ligne)
--   - LINE_TYPE (type de ligne)
--   - LOCAL_ACCOUNT (compte comptable)
--   - COMPANY_CODE (code société)
--   - ORIGIN (origine)
--   - FIC_IDENT (fichier source)
--
-- USAGE : 
--   1. Exécuter PARTIE 1 pour créer la sauvegarde
--   2. Exécuter PARTIE 2 pour diagnostiquer les doublons
--   3. Exécuter PARTIE 3 pour supprimer les doublons en PRODUCTION
--   4. Exécuter PARTIE 4 pour vérifier le résultat
--
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

-- =============================================================================
-- PARTIE 1 : SAUVEGARDE DE LA TABLE DE PRODUCTION
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 1 : SAUVEGARDE DE LA TABLE DE PRODUCTION
PROMPT =====================================================
PROMPT

DECLARE
    v_backup_table VARCHAR2(100);
    v_table_exists NUMBER := 0;
    v_nb_enreg     NUMBER := 0;
    v_debut        TIMESTAMP;
    v_fin          TIMESTAMP;
    v_duree        NUMBER;
BEGIN
    v_debut := SYSTIMESTAMP;
    
    -- Nom de la table de sauvegarde avec timestamp
    v_backup_table := 'DKA_IARPAFAC_INTERFACE_BKP_' || 
                      TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS');
    
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('SAUVEGARDE DE LA TABLE DE PRODUCTION');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Table source : DKA_IARPAFAC_INTERFACE');
    DBMS_OUTPUT.PUT_LINE('Table backup : ' || v_backup_table);
    DBMS_OUTPUT.PUT_LINE('Début        : ' || TO_CHAR(v_debut, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Créer la sauvegarde
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_backup_table || 
                      ' AS SELECT * FROM DKA_IARPAFAC_INTERFACE';
    
    -- Compter les enregistrements sauvegardés
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || v_backup_table INTO v_nb_enreg;
    
    v_fin := SYSTIMESTAMP;
    v_duree := EXTRACT(SECOND FROM (v_fin - v_debut)) + 
               EXTRACT(MINUTE FROM (v_fin - v_debut)) * 60;
    
    DBMS_OUTPUT.PUT_LINE('✓ Sauvegarde créée avec succès');
    DBMS_OUTPUT.PUT_LINE('  Enregistrements sauvegardés : ' || TO_CHAR(v_nb_enreg, '999,999,999'));
    DBMS_OUTPUT.PUT_LINE('  Durée : ' || ROUND(v_duree, 2) || ' secondes');
    DBMS_OUTPUT.PUT_LINE('  Fin : ' || TO_CHAR(v_fin, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('⚠️  IMPORTANT : Conserver le nom de la table de backup :');
    DBMS_OUTPUT.PUT_LINE('   ' || v_backup_table);
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR lors de la sauvegarde : ' || SQLERRM);
        RAISE;
END;
/

-- =============================================================================
-- PARTIE 2 : DIAGNOSTIC DES DOUBLONS (PRODUCTION)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 2 : DIAGNOSTIC DES DOUBLONS (PRODUCTION)
PROMPT =====================================================
PROMPT

-- Vue d'ensemble
SELECT 
    'TOTAL_ENREGISTREMENTS' AS METRIQUE,
    TO_CHAR(COUNT(*), '999,999,999') AS VALEUR
FROM DKA.DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'FACTURES_UNIQUES',
    TO_CHAR(COUNT(DISTINCT INVOICE_NUMBER), '999,999,999')
FROM DKA.DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'ENREGISTREMENTS_EN_DOUBLON',
    TO_CHAR(COUNT(*), '999,999,999')
FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA.DKA_IARPAFAC_INTERFACE dii2
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
PROMPT --- Top 20 des factures en doublon ---
PROMPT

SELECT * FROM (
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
        MAX(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS DERNIERE_CREATION
    FROM DKA.DKA_IARPAFAC_INTERFACE
    GROUP BY INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE, COMPANY_CODE, ORIGIN, 
             LOCAL_ACCOUNT, FIC_IDENT
    HAVING COUNT(*) > 1
    ORDER BY COUNT(*) DESC
)
WHERE ROWNUM <= 20;

PROMPT
PROMPT --- Comptage des enregistrements à supprimer ---
PROMPT

SELECT 
    TO_CHAR(COUNT(*), '999,999,999') AS NB_ENREGISTREMENTS_A_SUPPRIMER,
    TO_CHAR(COUNT(DISTINCT INVOICE_NUMBER), '999,999,999') AS NB_FACTURES_CONCERNEES
FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE dii2
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
    FROM DKA.DKA_IARPAFAC_INTERFACE dii3
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
-- PARTIE 3 : SUPPRESSION DES DOUBLONS EN PRODUCTION
-- =============================================================================

PROMPT
PROMPT ═════════════════════════════════════════════════════════
PROMPT ⚠️  PARTIE 3 : SUPPRESSION DES DOUBLONS EN PRODUCTION ⚠️
PROMPT ═════════════════════════════════════════════════════════
PROMPT
PROMPT Cette opération va MODIFIER la table de PRODUCTION :
PROMPT   DKA.DKA_IARPAFAC_INTERFACE
PROMPT
PROMPT Les enregistrements en doublon seront SUPPRIMÉS.
PROMPT Seul l'enregistrement le plus ancien (plus petit ID) sera conservé.
PROMPT
PROMPT Assurez-vous que la sauvegarde (PARTIE 1) a été créée avec succès.
PROMPT
PROMPT ═════════════════════════════════════════════════════════
PROMPT Appuyez sur CTRL+C pour ANNULER ou Entrée pour CONTINUER
PROMPT ═════════════════════════════════════════════════════════
PAUSE

DECLARE
    v_nb_supprimes NUMBER := 0;
    v_nb_factures  NUMBER := 0;
    v_debut        TIMESTAMP;
    v_fin          TIMESTAMP;
    v_duree        NUMBER;
BEGIN
    v_debut := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('SUPPRESSION DES DOUBLONS EN PRODUCTION');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Table      : DKA.DKA_IARPAFAC_INTERFACE');
    DBMS_OUTPUT.PUT_LINE('Début      : ' || TO_CHAR(v_debut, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Stratégie  : Conserver le plus petit IARPAFAC_ID (plus ancien)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Suppression en cours...');
    
    -- Suppression des doublons
    DELETE FROM DKA.DKA_IARPAFAC_INTERFACE dii
    WHERE dii.IARPAFAC_ID NOT IN (
        -- Garder uniquement le plus petit ID (= le plus ancien)
        SELECT MIN(dii2.IARPAFAC_ID)
        FROM DKA.DKA_IARPAFAC_INTERFACE dii2
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
        FROM DKA.DKA_IARPAFAC_INTERFACE dii3
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
    
    -- Compter les factures concernées
    SELECT COUNT(DISTINCT dii.INVOICE_NUMBER)
    INTO v_nb_factures
    FROM DKA.DKA_IARPAFAC_INTERFACE dii
    WHERE dii.IARPAFAC_ID IN (
        SELECT dii2.IARPAFAC_ID
        FROM DKA.DKA_IARPAFAC_INTERFACE dii2
        GROUP BY dii2.INVOICE_NUMBER, dii2.LINE_NUMBER, dii2.COMPANY_CODE, 
                 dii2.ORIGIN, dii2.FIC_IDENT, dii2.LOCAL_ACCOUNT, dii2.LINE_TYPE
        HAVING COUNT(*) = 1
    );
    
    v_fin := SYSTIMESTAMP;
    v_duree := EXTRACT(SECOND FROM (v_fin - v_debut)) + 
               EXTRACT(MINUTE FROM (v_fin - v_debut)) * 60;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('RÉSULTAT DE LA SUPPRESSION');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Enregistrements supprimés : ' || TO_CHAR(v_nb_supprimes, '999,999,999'));
    DBMS_OUTPUT.PUT_LINE('Factures concernées       : ' || TO_CHAR(v_nb_factures, '999,999,999'));
    DBMS_OUTPUT.PUT_LINE('Durée                     : ' || ROUND(v_duree, 2) || ' secondes');
    DBMS_OUTPUT.PUT_LINE('Fin                       : ' || TO_CHAR(v_fin, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_nb_supprimes > 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ COMMIT effectué avec succès');
        DBMS_OUTPUT.PUT_LINE('✓ Doublons supprimés de la table de PRODUCTION');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠ Aucun doublon trouvé dans la table de PRODUCTION');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR lors de la suppression');
        DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
        DBMS_OUTPUT.PUT_LINE('Message : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('✓ ROLLBACK effectué - Aucune modification appliquée');
        DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════════════');
        RAISE;
END;
/

-- =============================================================================
-- PARTIE 4 : VÉRIFICATION APRÈS SUPPRESSION
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT PARTIE 4 : VÉRIFICATION APRÈS SUPPRESSION
PROMPT =====================================================
PROMPT

-- Vérification qu'il n'y a plus de doublons
SELECT 
    'DOUBLONS_RESTANTS' AS STATUT,
    TO_CHAR(COUNT(*), '999,999,999') AS NB_DOUBLONS
FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA.DKA_IARPAFAC_INTERFACE dii2
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
    TO_CHAR(COUNT(*), '999,999,999') AS VALEUR
FROM DKA.DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'FACTURES_UNIQUES',
    TO_CHAR(COUNT(DISTINCT INVOICE_NUMBER), '999,999,999')
FROM DKA.DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'DERNIER_IARPAFAC_ID',
    TO_CHAR(MAX(IARPAFAC_ID), '999,999,999')
FROM DKA.DKA_IARPAFAC_INTERFACE;

PROMPT
PROMPT ═════════════════════════════════════════════════════════
PROMPT FIN DU TRAITEMENT
PROMPT ═════════════════════════════════════════════════════════
PROMPT
PROMPT Si "NB_DOUBLONS = 0", la suppression est réussie.
PROMPT
PROMPT Pour restaurer la sauvegarde en cas de problème :
PROMPT   1. Identifier le nom de la table de backup (créée en PARTIE 1)
PROMPT   2. DROP TABLE DKA.DKA_IARPAFAC_INTERFACE;
PROMPT   3. CREATE TABLE DKA.DKA_IARPAFAC_INTERFACE AS 
PROMPT      SELECT * FROM <NOM_TABLE_BACKUP>;
PROMPT
PROMPT ═════════════════════════════════════════════════════════