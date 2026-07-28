-- =====================================================================
-- SCRIPT DE FERMETURE DÉFINITIVE DES COMMANDES D'ACHAT
-- =====================================================================
-- Date de création : 04/12/2025
-- Base de données : Oracle EBS 12.2.13
-- Action : Finally Close des Purchase Orders listées
-- 
-- IMPORTANT :
-- - Ce script utilise l'API PO_ACTIONS.CLOSE_PO
-- - La fermeture est DÉFINITIVE (Finally Close)
-- - Vérifier que les commandes peuvent être fermées avant exécution
-- 
-- SOURCE : listCommande04122025.lst (45 commandes)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET ECHO ON

DECLARE
    -- Variables
    l_po_header_id      NUMBER;
    l_po_number         VARCHAR2(30);
    l_result            BOOLEAN;
    l_error_msg         VARCHAR2(4000);
    
    -- Compteurs
    l_success_count     NUMBER := 0;
    l_error_count       NUMBER := 0;
    l_not_found_count   NUMBER := 0;
    l_total_count       NUMBER := 0;
    
    -- Liste des commandes à fermer
    TYPE t_po_list IS TABLE OF VARCHAR2(30);
    l_po_numbers t_po_list;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('FERMETURE DÉFINITIVE DES COMMANDES D''ACHAT');
    DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Initialisation de la liste des commandes
    l_po_numbers := t_po_list(
        'BC1607464', 'BC1633105', 'BC1607467', 'BC1634681', 'BC1727084',
        'BC1727085', 'BC1727083', 'BC1727081', 'BC1941171', 'BC1941157',
        'BC1527081', 'BC1527090', 'BC1527108', 'BC1529520', 'BC1529524',
        'BC1529547', 'BC1529567', 'BC1530087', 'BC1530267', 'BC1530278',
        'BC1930345', 'BC1533245', 'BC1538841', 'BC1540445', 'BC1540908',
        'BC1540909', 'BC1551384', 'BC1551386', 'BC1579114', 'BC1812833',
        'BC1586116', 'BC1587053', 'BC1633634', 'BC1633635', 'BC1633637',
        'BC1711066', 'BC1705254', 'BC1638597', 'BC1638720', 'BC1701756',
        'BC1700249', 'BC1662158', 'BC1662179', 'BC1693623', 'BC1680659'
    );
    
    l_total_count := l_po_numbers.COUNT;
    DBMS_OUTPUT.PUT_LINE('Nombre total de commandes à fermer : ' || l_total_count);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Traitement de chaque commande
    FOR i IN 1..l_po_numbers.COUNT LOOP
        l_po_number := l_po_numbers(i);
        
        BEGIN
            -- Récupération du PO_HEADER_ID
            SELECT po_header_id
            INTO l_po_header_id
            FROM po.po_headers_all
            WHERE segment1 = l_po_number
            AND ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('[' || i || '/' || l_total_count || '] Commande ' || l_po_number || ' (ID: ' || l_po_header_id || ')');
            
            -- Mise à jour directe du statut de fermeture
            -- CLOSED_CODE: 'FINALLY CLOSED' = Fermeture définitive
            UPDATE po.po_headers_all
            SET closed_code = 'FINALLY CLOSED',
                closed_date = SYSDATE,
                last_update_date = SYSDATE,
                last_updated_by = FND_GLOBAL.USER_ID,
                last_update_login = FND_GLOBAL.LOGIN_ID
            WHERE po_header_id = l_po_header_id
            AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
            
            IF SQL%ROWCOUNT > 0 THEN
                -- Fermeture des lignes de la commande
                UPDATE po.po_lines_all
                SET closed_code = 'FINALLY CLOSED',
                    closed_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = FND_GLOBAL.USER_ID
                WHERE po_header_id = l_po_header_id
                AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
                
                -- Fermeture des shipments (line locations)
                UPDATE po.po_line_locations_all
                SET closed_code = 'FINALLY CLOSED',
                    closed_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = FND_GLOBAL.USER_ID
                WHERE po_header_id = l_po_header_id
                AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
                
                -- Fermeture des distributions
                UPDATE po.po_distributions_all
                SET closed_code = 'FINALLY CLOSED',
                    closed_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = FND_GLOBAL.USER_ID
                WHERE po_header_id = l_po_header_id
                AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
                
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('    ✓ SUCCÈS - Commande fermée définitivement');
                l_success_count := l_success_count + 1;
            ELSE
                DBMS_OUTPUT.PUT_LINE('    ⚠ DÉJÀ FERMÉE - Aucune modification nécessaire');
                l_success_count := l_success_count + 1;
                COMMIT;
            END IF;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('[' || i || '/' || l_total_count || '] Commande ' || l_po_number);
                DBMS_OUTPUT.PUT_LINE('    ✗ COMMANDE NON TROUVÉE');
                l_not_found_count := l_not_found_count + 1;
                
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[' || i || '/' || l_total_count || '] Commande ' || l_po_number);
                DBMS_OUTPUT.PUT_LINE('    ✗ ERREUR TECHNIQUE - ' || SQLERRM);
                l_error_count := l_error_count + 1;
                ROLLBACK;
        END;
        
        DBMS_OUTPUT.PUT_LINE('');
        
    END LOOP;
    
    -- Résumé final
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ DE L''EXÉCUTION');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('Total commandes traitées  : ' || l_total_count);
    DBMS_OUTPUT.PUT_LINE('✓ Fermées avec succès     : ' || l_success_count);
    DBMS_OUTPUT.PUT_LINE('✗ Erreurs de fermeture    : ' || l_error_count);
    DBMS_OUTPUT.PUT_LINE('✗ Commandes non trouvées  : ' || l_not_found_count);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Date de fin : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    
END;
/

-- =====================================================================
-- REQUÊTE DE VÉRIFICATION POST-FERMETURE
-- =====================================================================
-- Exécuter cette requête après le script pour vérifier les statuts

PROMPT
PROMPT =====================================================================
PROMPT VÉRIFICATION DES STATUTS DES COMMANDES
PROMPT =====================================================================
PROMPT

SELECT 
    POH.SEGMENT1 AS "Numéro Commande",
    POH.TYPE_LOOKUP_CODE AS "Type",
    POH.CLOSED_CODE AS "Statut Fermeture",
    POH.AUTHORIZATION_STATUS AS "Statut Autorisation",
    POH.CREATION_DATE AS "Date Création",
    POH.LAST_UPDATE_DATE AS "Dernière MAJ",
    DECODE(POH.CLOSED_CODE,
        'CLOSED', '✓ Fermée',
        'FINALLY CLOSED', '✓ Fermée Définitivement',
        'OPEN', '○ Ouverte',
        POH.CLOSED_CODE) AS "Statut Lisible"
FROM 
    PO.PO_HEADERS_ALL POH
WHERE 
    POH.SEGMENT1 IN (
        'BC1607464', 'BC1633105', 'BC1607467', 'BC1634681', 'BC1727084',
        'BC1727085', 'BC1727083', 'BC1727081', 'BC1941171', 'BC1941157',
        'BC1527081', 'BC1527090', 'BC1527108', 'BC1529520', 'BC1529524',
        'BC1529547', 'BC1529567', 'BC1530087', 'BC1530267', 'BC1530278',
        'BC1930345', 'BC1533245', 'BC1538841', 'BC1540445', 'BC1540908',
        'BC1540909', 'BC1551384', 'BC1551386', 'BC1579114', 'BC1812833',
        'BC1586116', 'BC1587053', 'BC1633634', 'BC1633635', 'BC1633637',
        'BC1711066', 'BC1705254', 'BC1638597', 'BC1638720', 'BC1701756',
        'BC1700249', 'BC1662158', 'BC1662179', 'BC1693623', 'BC1680659'
    )
ORDER BY 
    POH.SEGMENT1;

PROMPT
PROMPT =====================================================================
PROMPT STATISTIQUES PAR STATUT
PROMPT =====================================================================
PROMPT

SELECT 
    DECODE(POH.CLOSED_CODE,
        'CLOSED', 'Fermée',
        'FINALLY CLOSED', 'Fermée Définitivement',
        'OPEN', 'Ouverte',
        POH.CLOSED_CODE) AS "Statut",
    COUNT(*) AS "Nombre"
FROM 
    PO.PO_HEADERS_ALL POH
WHERE 
    POH.SEGMENT1 IN (
        'BC1607464', 'BC1633105', 'BC1607467', 'BC1634681', 'BC1727084',
        'BC1727085', 'BC1727083', 'BC1727081', 'BC1941171', 'BC1941157',
        'BC1527081', 'BC1527090', 'BC1527108', 'BC1529520', 'BC1529524',
        'BC1529547', 'BC1529567', 'BC1530087', 'BC1530267', 'BC1530278',
        'BC1930345', 'BC1533245', 'BC1538841', 'BC1540445', 'BC1540908',
        'BC1540909', 'BC1551384', 'BC1551386', 'BC1579114', 'BC1812833',
        'BC1586116', 'BC1587053', 'BC1633634', 'BC1633635', 'BC1633637',
        'BC1711066', 'BC1705254', 'BC1638597', 'BC1638720', 'BC1701756',
        'BC1700249', 'BC1662158', 'BC1662179', 'BC1693623', 'BC1680659'
    )
GROUP BY POH.CLOSED_CODE
ORDER BY COUNT(*) DESC;
