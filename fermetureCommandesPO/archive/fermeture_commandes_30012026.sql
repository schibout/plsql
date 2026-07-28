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
    
    -- Liste des commandes à fermer (po_header_id)
    TYPE t_po_list IS TABLE OF NUMBER;
    l_po_header_ids t_po_list;
    
    -- Contexte utilisateur
    l_user_id           NUMBER := 36313;  -- H00035381F (Samir CHIBOUT)
    l_resp_id           NUMBER := 50939;  -- TOUT_PO_ADMINISTRATEUR
    l_resp_appl_id      NUMBER := 201;    -- PO Application
    l_login_id          NUMBER;           -- Session LOGIN_ID
    
BEGIN
    -- Initialisation du contexte Apps
    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => l_user_id,
        resp_id      => l_resp_id,
        resp_appl_id => l_resp_appl_id
    );
    
    -- Capture du LOGIN_ID après initialisation
    l_login_id := FND_GLOBAL.LOGIN_ID;
    
    DBMS_OUTPUT.PUT_LINE('Contexte initialisé:');
    DBMS_OUTPUT.PUT_LINE('  - Utilisateur: H00035381F (ID: ' || l_user_id || ')');
    DBMS_OUTPUT.PUT_LINE('  - Responsabilité: TOUT_PO_ADMINISTRATEUR (ID: ' || l_resp_id || ')');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('FERMETURE DÉFINITIVE DES COMMANDES D''ACHAT');
    DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Initialisation de la liste des po_header_id
    l_po_header_ids := t_po_list(2131314,2131314,2184415,2134060,2185446,2156058,2156058,2156058,2697862,2156056,2156056,1489184,1489184,2129293,2951693);
    
    l_total_count := l_po_header_ids.COUNT;
    DBMS_OUTPUT.PUT_LINE('Nombre total de commandes à fermer : ' || l_total_count);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Traitement de chaque commande
    FOR i IN 1..l_po_header_ids.COUNT LOOP
        l_po_header_id := l_po_header_ids(i);
        
        BEGIN
            -- Récupération du numéro de commande pour l'affichage
            BEGIN
                SELECT segment1
                INTO l_po_number
                FROM po.po_headers_all
                WHERE po_header_id = l_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_po_number := 'ID=' || l_po_header_id;
            END;
            
            DBMS_OUTPUT.PUT_LINE('[' || i || '/' || l_total_count || '] Commande ' || l_po_number || ' (ID: ' || l_po_header_id || ')');
            
            -- Mise à jour directe du statut de fermeture
            -- CLOSED_CODE: 'FINALLY CLOSED' = Fermeture définitive
            UPDATE po.po_headers_all
            SET closed_code = 'FINALLY CLOSED',
                closed_date = SYSDATE,
                last_update_date = SYSDATE,
                last_updated_by = l_user_id,
                last_update_login = l_login_id
            WHERE po_header_id = l_po_header_id
            AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
            
            IF SQL%ROWCOUNT > 0 THEN
                -- Fermeture des lignes de la commande
                UPDATE po.po_lines_all
                SET closed_code = 'FINALLY CLOSED',
                    closed_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = l_user_id
                WHERE po_header_id = l_po_header_id
                AND NVL(closed_code, 'OPEN') != 'FINALLY CLOSED';
                
                -- Fermeture des shipments (line locations)
                UPDATE po.po_line_locations_all
                SET closed_code = 'FINALLY CLOSED',
                    closed_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = l_user_id
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
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[' || i || '/' || l_total_count || '] PO_HEADER_ID: ' || l_po_header_id);
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
    FU.USER_NAME AS "User Modifié Par",
    FU.DESCRIPTION AS "Nom Complet",
    POH.CREATION_DATE AS "Date Création",
    POH.LAST_UPDATE_DATE AS "Dernière MAJ",
    DECODE(POH.CLOSED_CODE,
        'CLOSED', '✓ Fermée',
        'FINALLY CLOSED', '✓ Fermée Définitivement',
        'OPEN', '○ Ouverte',
        POH.CLOSED_CODE) AS "Statut Lisible"
FROM 
    PO.PO_HEADERS_ALL POH
    LEFT JOIN APPLSYS.FND_USER FU ON POH.LAST_UPDATED_BY = FU.USER_ID
WHERE 
    POH.PO_HEADER_ID IN (2131314,2131314,2184415,2134060,2185446,2156058,2156058,2156058,2697862,2156056,2156056,1489184,1489184,2129293,2951693)
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
    POH.PO_HEADER_ID IN (3523638,3523643,3916681,4224993,3483676,4374970,
                                3553822,4374982,4381063,4381063,3553822,4864447,4499672)
GROUP BY POH.CLOSED_CODE
ORDER BY COUNT(*) DESC;
