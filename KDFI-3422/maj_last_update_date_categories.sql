-- =====================================================================
-- SCRIPT DE MISE À JOUR DES CATÉGORIES FA - LAST_UPDATE_DATE
-- =====================================================================
-- Date de création : 29/12/2025
-- Ticket : KDFI-3422
-- Base de données : Oracle EBS 12.2.13
-- 
-- PROBLÈME :
-- Les mises à jour des catégories FA effectuées dans Oracle R12 ne 
-- descendent pas dans BO car le champ LAST_UPDATE_DATE n'a pas été mis à jour
--
-- SOLUTION :
-- Mettre à jour LAST_UPDATE_DATE pour forcer la synchronisation vers BO
--
-- CATÉGORIES CONCERNÉES :
-- - CEE.CEEI12.L05.0
-- - CEE.CEE.L05.0
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON

PROMPT
PROMPT =====================================================================
PROMPT VÉRIFICATION DE L'ÉTAT ACTUEL DES CATÉGORIES
PROMPT =====================================================================
PROMPT

-- Vérification avant mise à jour
SELECT 
    CATEGORY_ID,
    SEGMENT1 || '.' || SEGMENT2 || '.' || SEGMENT3 || '.' || SEGMENT4 AS "Catégorie",
    SEGMENT1,
    SEGMENT2,
    SEGMENT3,
    SEGMENT4,
    LAST_UPDATE_DATE AS "Dernière MAJ",
    LAST_UPDATED_BY AS "MAJ Par",
    CREATION_DATE AS "Date Création"
FROM 
    FA.FA_CATEGORIES_B
WHERE 
    (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEEI12' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0')
    OR (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEE' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0')
ORDER BY 
    SEGMENT1, SEGMENT2, SEGMENT3, SEGMENT4;

PROMPT
PROMPT =====================================================================
PROMPT MISE À JOUR DU CHAMP LAST_UPDATE_DATE
PROMPT =====================================================================
PROMPT

DECLARE
    l_count NUMBER := 0;
    l_category_id NUMBER;
    l_category_name VARCHAR2(200);
    l_user_id NUMBER;
    
    CURSOR c_categories IS
        SELECT 
            CATEGORY_ID,
            SEGMENT1 || '.' || SEGMENT2 || '.' || SEGMENT3 || '.' || SEGMENT4 AS CATEGORY_NAME
        FROM 
            FA.FA_CATEGORIES_B
        WHERE 
            (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEEI12' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0')
            OR (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEE' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0');
            
BEGIN
    -- Récupération du USER_ID
    SELECT user_id 
    INTO l_user_id
    FROM fnd_user 
    WHERE user_name = 'H00035381F';
    
    DBMS_OUTPUT.PUT_LINE('Début du traitement : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('User ID : ' || l_user_id || ' (H00035381F)');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN c_categories LOOP
        l_category_id := rec.CATEGORY_ID;
        l_category_name := rec.CATEGORY_NAME;
        
        DBMS_OUTPUT.PUT_LINE('Traitement de la catégorie : ' || l_category_name || ' (ID: ' || l_category_id || ')');
        
        -- Mise à jour de LAST_UPDATE_DATE pour forcer la synchronisation vers BO
        UPDATE FA.FA_CATEGORIES_B
        SET 
            LAST_UPDATE_DATE = SYSDATE,
            LAST_UPDATED_BY = l_user_id,
            LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
        WHERE 
            CATEGORY_ID = l_category_id;
            
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('  ✓ Mise à jour effectuée - LAST_UPDATE_DATE = ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
            l_count := l_count + 1;
        ELSE
            DBMS_OUTPUT.PUT_LINE('  ⚠ Aucune ligne mise à jour');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ DE L''EXÉCUTION');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('Nombre de catégories mises à jour : ' || l_count);
    DBMS_OUTPUT.PUT_LINE('Fin du traitement : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        RAISE;
END;
/

PROMPT
PROMPT =====================================================================
PROMPT VÉRIFICATION POST-MISE À JOUR
PROMPT =====================================================================
PROMPT

-- Vérification après mise à jour
SELECT 
    CATEGORY_ID,
    SEGMENT1 || '.' || SEGMENT2 || '.' || SEGMENT3 || '.' || SEGMENT4 AS "Catégorie",
    SEGMENT1,
    SEGMENT2,
    SEGMENT3,
    SEGMENT4,
    LAST_UPDATE_DATE AS "Dernière MAJ",
    LAST_UPDATED_BY AS "MAJ Par",
    CREATION_DATE AS "Date Création",
    CASE 
        WHEN LAST_UPDATE_DATE >= TRUNC(SYSDATE) THEN '✓ Mise à jour ce jour'
        ELSE '○ Ancienne date'
    END AS "Statut"
FROM 
    FA.FA_CATEGORIES_B
WHERE 
    (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEEI12' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0')
    OR (SEGMENT1 = 'CEE' AND SEGMENT2 = 'CEE' AND SEGMENT3 = 'L05' AND SEGMENT4 = '0')
ORDER BY 
    SEGMENT1, SEGMENT2, SEGMENT3, SEGMENT4;

PROMPT
PROMPT =====================================================================
PROMPT FIN DU SCRIPT
PROMPT =====================================================================
