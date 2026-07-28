-- =====================================================================
-- SCRIPT : Génération URLs BDC 2026 - Traitement Mensuel Automatisé
-- =====================================================================
-- Date : 09/03/2026
-- Objectif : Traiter toute l'année 2026 mois par mois pour éviter timeout
-- Durée estimée : 60-120 minutes (5-10 min par mois)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET ECHO ON

-- =====================================================================
-- ÉTAPE 1 : Créer table de backup pour accumuler les résultats
-- =====================================================================
PROMPT
PROMPT ===== Création table de backup EXTRACTION_BDC_2026_FULL =====
PROMPT

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL';
    DBMS_OUTPUT.PUT_LINE('Table existante supprimée');
EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Table n''existe pas encore (normal)');
END;
/

CREATE TABLE DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL (
    PO_HEADER_ID NUMBER,
    URL VARCHAR2(2000),
    ACCESS_ID VARCHAR2(50),
    MOIS_TRAITEMENT VARCHAR2(10),
    DATE_TRAITEMENT DATE DEFAULT SYSDATE
);

PROMPT Table créée avec succès
PROMPT

-- =====================================================================
-- ÉTAPE 2 : Traiter les 12 mois de 2026
-- =====================================================================
PROMPT
PROMPT ===== Début du traitement des 12 mois de 2026 =====
PROMPT

DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_count NUMBER;
    v_mois VARCHAR2(10);
    v_total_urls NUMBER := 0;
    v_debut_traitement TIMESTAMP;
    v_fin_traitement TIMESTAMP;
    v_duree_secondes NUMBER;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Début du traitement : ' || TO_CHAR(SYSTIMESTAMP, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Boucle sur les 12 mois
    FOR i IN 1..12 LOOP
        v_debut_traitement := SYSTIMESTAMP;
        
        -- Calculer dates début/fin du mois
        v_start_date := TO_DATE('01/' || LPAD(i, 2, '0') || '/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS');
        v_end_date := TRUNC(LAST_DAY(v_start_date)) + (86399/86400);  -- 23:59:59 du dernier jour
        v_mois := TO_CHAR(v_start_date, 'YYYY-MM');
        
        DBMS_OUTPUT.PUT_LINE('=============================================================');
        DBMS_OUTPUT.PUT_LINE('MOIS ' || i || '/12 : ' || v_mois);
        DBMS_OUTPUT.PUT_LINE('=============================================================');
        DBMS_OUTPUT.PUT_LINE('Période : ' || TO_CHAR(v_start_date, 'DD/MM/YYYY HH24:MI:SS') || 
                             ' → ' || TO_CHAR(v_end_date, 'DD/MM/YYYY HH24:MI:SS'));
        
        -- Appeler la procédure
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Lancement DKA_GENERATE_URL_IMAGE_BDC...');
            
            DKA_GENERATE_URL_IMAGE_BDC(v_start_date, v_end_date);
            
            -- Compter les résultats
            SELECT COUNT(*) INTO v_count FROM DKA_JMETER_ST.EXTRACTION_BDC;
            
            IF v_count = 0 THEN
                DBMS_OUTPUT.PUT_LINE('⚠ ATTENTION : Aucune URL générée pour ' || v_mois);
            ELSE
                -- Sauvegarder les résultats du mois
                INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL (
                    PO_HEADER_ID, URL, ACCESS_ID, MOIS_TRAITEMENT
                )
                SELECT PO_HEADER_ID, URL, ACCESS_ID, v_mois
                FROM DKA_JMETER_ST.EXTRACTION_BDC;
                
                v_total_urls := v_total_urls + v_count;
                
                v_fin_traitement := SYSTIMESTAMP;
                v_duree_secondes := EXTRACT(SECOND FROM (v_fin_traitement - v_debut_traitement)) +
                                    EXTRACT(MINUTE FROM (v_fin_traitement - v_debut_traitement)) * 60 +
                                    EXTRACT(HOUR FROM (v_fin_traitement - v_debut_traitement)) * 3600;
                
                DBMS_OUTPUT.PUT_LINE('✓ SUCCÈS : ' || v_count || ' URLs générées');
                DBMS_OUTPUT.PUT_LINE('  Durée : ' || ROUND(v_duree_secondes, 1) || ' secondes');
                DBMS_OUTPUT.PUT_LINE('  Total cumulé : ' || v_total_urls || ' URLs');
            END IF;
            
            COMMIT;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_fin_traitement := SYSTIMESTAMP;
                v_duree_secondes := EXTRACT(SECOND FROM (v_fin_traitement - v_debut_traitement)) +
                                    EXTRACT(MINUTE FROM (v_fin_traitement - v_debut_traitement)) * 60;
                
                DBMS_OUTPUT.PUT_LINE('✗ ERREUR sur ' || v_mois || ' après ' || ROUND(v_duree_secondes, 1) || ' secondes');
                DBMS_OUTPUT.PUT_LINE('  Code : ' || SQLCODE);
                DBMS_OUTPUT.PUT_LINE('  Message : ' || SQLERRM);
                
                ROLLBACK;
                
                -- Continuer avec le mois suivant malgré l'erreur
        END;
        
        DBMS_OUTPUT.PUT_LINE('');
        
    END LOOP;
    
    -- =========================================================================
    -- STATISTIQUES FINALES
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=============================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ FINAL - Année 2026');
    DBMS_OUTPUT.PUT_LINE('=============================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- URLs par mois
    DBMS_OUTPUT.PUT_LINE('URLs générées par mois :');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    FOR rec IN (
        SELECT MOIS_TRAITEMENT, COUNT(*) AS nb_urls
        FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
        GROUP BY MOIS_TRAITEMENT
        ORDER BY MOIS_TRAITEMENT
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || rec.MOIS_TRAITEMENT || ' : ' || 
                             LPAD(TO_CHAR(rec.nb_urls, '999G999G999'), 12) || ' URLs');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Statistiques globales :');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    
    -- Total URLs
    SELECT COUNT(*) INTO v_count FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;
    DBMS_OUTPUT.PUT_LINE('  Total URLs         : ' || TO_CHAR(v_count, '999G999G999'));
    
    -- BDC uniques
    SELECT COUNT(DISTINCT PO_HEADER_ID) INTO v_count 
    FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;
    DBMS_OUTPUT.PUT_LINE('  BDC uniques        : ' || TO_CHAR(v_count, '999G999G999'));
    
    -- URLs invalides
    SELECT COUNT(*) INTO v_count 
    FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
    WHERE URL IS NULL OR LENGTH(URL) < 20;
    DBMS_OUTPUT.PUT_LINE('  URLs invalides     : ' || TO_CHAR(v_count, '999G999G999'));
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Fin du traitement : ' || TO_CHAR(SYSTIMESTAMP, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=============================================================');
    
END;
/

-- =====================================================================
-- ÉTAPE 3 : Vérifications détaillées
-- =====================================================================
PROMPT
PROMPT ===== Vérifications détaillées =====
PROMPT

-- Vue d'ensemble par mois
SELECT 
    MOIS_TRAITEMENT AS "Mois",
    COUNT(*) AS "Nb URLs",
    COUNT(DISTINCT PO_HEADER_ID) AS "BDC Uniques",
    MIN(TO_NUMBER(ACCESS_ID)) AS "Min ACCESS_ID",
    MAX(TO_NUMBER(ACCESS_ID)) AS "Max ACCESS_ID"
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
GROUP BY MOIS_TRAITEMENT
ORDER BY MOIS_TRAITEMENT;

-- URLs potentiellement problématiques
PROMPT
PROMPT ===== URLs invalides ou suspectes =====
SELECT 
    MOIS_TRAITEMENT,
    PO_HEADER_ID,
    URL,
    ACCESS_ID,
    CASE
        WHEN URL IS NULL THEN 'URL NULL'
        WHEN LENGTH(URL) < 20 THEN 'URL TROP COURTE'
        WHEN URL NOT LIKE 'http%' THEN 'URL SANS HTTP'
        ELSE 'AUTRE PROBLÈME'
    END AS TYPE_PROBLEME
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
WHERE URL IS NULL 
   OR LENGTH(URL) < 20
   OR URL NOT LIKE 'http%'
ORDER BY MOIS_TRAITEMENT, PO_HEADER_ID
FETCH FIRST 20 ROWS ONLY;

-- Vérifier échantillon d'URLs
PROMPT
PROMPT ===== Échantillon d'URLs générées (5 premières) =====
SELECT PO_HEADER_ID, SUBSTR(URL, 1, 100) AS URL_EXTRAIT, ACCESS_ID, MOIS_TRAITEMENT
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
WHERE ROWNUM <= 5
ORDER BY MOIS_TRAITEMENT;

-- =====================================================================
-- ÉTAPE 4 : Optionnel - Copier dans la table finale
-- =====================================================================
PROMPT
PROMPT ===== IMPORTANT : Table finale EXTRACTION_BDC =====
PROMPT
PROMPT La table DKA_JMETER_ST.EXTRACTION_BDC contient actuellement les données
PROMPT du dernier mois traité (Décembre 2026).
PROMPT
PROMPT Pour avoir TOUTES les données de l'année, vous devez copier depuis
PROMPT la table de backup EXTRACTION_BDC_2026_FULL :
PROMPT
PROMPT   TRUNCATE TABLE DKA_JMETER_ST.EXTRACTION_BDC;
PROMPT   INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC (PO_HEADER_ID, URL, ACCESS_ID)
PROMPT   SELECT PO_HEADER_ID, URL, ACCESS_ID
PROMPT   FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;
PROMPT   COMMIT;
PROMPT
PROMPT Voulez-vous exécuter cette copie maintenant ? (commentez si NON)
PROMPT

-- Décommenter les 4 lignes ci-dessous pour copier automatiquement
/*
TRUNCATE TABLE DKA_JMETER_ST.EXTRACTION_BDC;
INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC (PO_HEADER_ID, URL, ACCESS_ID)
SELECT PO_HEADER_ID, URL, ACCESS_ID FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;
COMMIT;
*/

PROMPT
PROMPT ===== Script terminé =====
PROMPT

-- =====================================================================
-- FIN DU SCRIPT
-- =====================================================================
