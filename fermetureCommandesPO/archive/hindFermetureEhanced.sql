-- =====================================================================
-- SCRIPT AMÉLIORÉ - FERMETURE DÉFINITIVE DES COMMANDES D'ACHAT
-- =====================================================================
-- Date création originale : 31/10/2019
-- Date amélioration : 04/12/2025
-- Base : Oracle EBS 12.2.13
-- Action : Finally Close des Purchase Orders
--
-- AMÉLIORATIONS :
-- - Ajout fermeture des PO_DISTRIBUTIONS_ALL
-- - Gestion d'erreurs renforcée par commande
-- - Statistiques détaillées (compteurs par statut)
-- - Informations enrichies (quantités, montants)
-- - Meilleure traçabilité et logs
-- - COMMIT individuel par commande (isolation des erreurs)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200

DECLARE
    -- Curseur principal : récupération des commandes avec informations étendues
    CURSOR CUR_CLOSE_PO IS
        SELECT PH.PO_HEADER_ID,
               PH.SEGMENT1,
               NVL(PH.CANCEL_FLAG, 'N')     AS CANCEL_FLAG,
               PH.CLOSED_CODE,
               PH.ORG_ID,
               HAOU.NAME                    AS OU_NAME,
               PH.CLOSED_DATE,
               PH.AUTHORIZATION_STATUS,
               PH.CURRENCY_CODE,
               -- Statistiques par commande
               (SELECT COUNT(*) 
                FROM PO.PO_LINES_ALL PL 
                WHERE PL.PO_HEADER_ID = PH.PO_HEADER_ID) AS NB_LINES,
               (SELECT COUNT(*) 
                FROM PO.PO_LINE_LOCATIONS_ALL PLL 
                WHERE PLL.PO_HEADER_ID = PH.PO_HEADER_ID) AS NB_SHIPMENTS,
               (SELECT COUNT(*) 
                FROM PO.PO_DISTRIBUTIONS_ALL PDA 
                WHERE PDA.PO_HEADER_ID = PH.PO_HEADER_ID) AS NB_DISTRIBUTIONS,
               (SELECT NVL(SUM(PLL.QUANTITY_RECEIVED), 0)
                FROM PO.PO_LINE_LOCATIONS_ALL PLL
                WHERE PLL.PO_HEADER_ID = PH.PO_HEADER_ID) AS QTY_RECEIVED,
               (SELECT NVL(SUM(PLL.QUANTITY_BILLED), 0)
                FROM PO.PO_LINE_LOCATIONS_ALL PLL
                WHERE PLL.PO_HEADER_ID = PH.PO_HEADER_ID) AS QTY_BILLED
        FROM PO.PO_HEADERS_ALL PH
        JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU 
            ON HAOU.ORGANIZATION_ID = PH.ORG_ID
        WHERE PH.SEGMENT1 IN (
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
        ORDER BY PH.SEGMENT1;

    -- Variables
    VV_MESSAGE             VARCHAR2(240) := 'Fermeture définitive par script masse du ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY');
    VN_LAST_UPDATED_BY     NUMBER := FND_GLOBAL.USER_ID;
    VN_LAST_UPDATE_LOGIN   NUMBER := FND_GLOBAL.LOGIN_ID;
    
    -- Compteurs
    VN_TOTAL               NUMBER := 0;
    VN_SUCCESS             NUMBER := 0;
    VN_ALREADY_CLOSED      NUMBER := 0;
    VN_ERROR               NUMBER := 0;
    
    -- Variables de travail
    VN_LINES_UPD           NUMBER;
    VN_SHIPMENTS_UPD       NUMBER;
    VN_DISTRIB_UPD         NUMBER;
    VV_ERROR_MSG           VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('FERMETURE DÉFINITIVE DES COMMANDES D''ACHAT');
    DBMS_OUTPUT.PUT_LINE('Date/Heure : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Utilisateur : ' || FND_GLOBAL.USER_NAME || ' (ID: ' || VN_LAST_UPDATED_BY || ')');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- En-tête du tableau
    DBMS_OUTPUT.PUT_LINE(
           RPAD('N°', 4, ' ')
        || RPAD('Commande', 13, ' ')
        || RPAD('UO', 18, ' ')
        || RPAD('Statut', 20, ' ')
        || RPAD('Lignes', 8, ' ')
        || RPAD('Ships', 8, ' ')
        || RPAD('Distrib', 9, ' ')
        || RPAD('Résultat', 50, ' ')
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 130, '-'));

    FOR REC IN CUR_CLOSE_PO LOOP
        VN_TOTAL := VN_TOTAL + 1;
        
        BEGIN
            -- Vérification du statut actuel
            IF REC.CLOSED_CODE = 'FINALLY CLOSED' THEN
                VN_ALREADY_CLOSED := VN_ALREADY_CLOSED + 1;
                DBMS_OUTPUT.PUT_LINE(
                       RPAD(VN_TOTAL, 4, ' ')
                    || RPAD(REC.SEGMENT1, 13, ' ')
                    || RPAD(REC.OU_NAME, 18, ' ')
                    || RPAD(REC.CLOSED_CODE, 20, ' ')
                    || RPAD(REC.NB_LINES, 8, ' ')
                    || RPAD(REC.NB_SHIPMENTS, 8, ' ')
                    || RPAD(REC.NB_DISTRIBUTIONS, 9, ' ')
                    || '⚠ Déjà fermée définitivement'
                );
                
            ELSIF REC.CANCEL_FLAG = 'Y' THEN
                VN_ERROR := VN_ERROR + 1;
                DBMS_OUTPUT.PUT_LINE(
                       RPAD(VN_TOTAL, 4, ' ')
                    || RPAD(REC.SEGMENT1, 13, ' ')
                    || RPAD(REC.OU_NAME, 18, ' ')
                    || RPAD('CANCELLED', 20, ' ')
                    || RPAD(REC.NB_LINES, 8, ' ')
                    || RPAD(REC.NB_SHIPMENTS, 8, ' ')
                    || RPAD(REC.NB_DISTRIBUTIONS, 9, ' ')
                    || '✗ Commande annulée - Non éligible'
                );
                
            ELSE
                -- Fermeture des shipments (line locations)
                UPDATE PO.PO_LINE_LOCATIONS_ALL
                SET CLOSED_CODE = 'FINALLY CLOSED',
                    CLOSED_DATE = SYSDATE,
                    SHIPMENT_CLOSED_DATE = SYSDATE,
                    CLOSED_BY = VN_LAST_UPDATED_BY,
                    CLOSED_REASON = SUBSTR(VV_MESSAGE, 1, 240),
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                    LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                WHERE PO_HEADER_ID = REC.PO_HEADER_ID
                AND NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';
                
                VN_SHIPMENTS_UPD := SQL%ROWCOUNT;

                -- Fermeture des lignes
                UPDATE PO.PO_LINES_ALL
                SET CLOSED_CODE = 'FINALLY CLOSED',
                    CLOSED_DATE = SYSDATE,
                    CLOSED_BY = VN_LAST_UPDATED_BY,
                    CLOSED_REASON = SUBSTR(VV_MESSAGE, 1, 240),
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                    LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                WHERE PO_HEADER_ID = REC.PO_HEADER_ID
                AND NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';
                
                VN_LINES_UPD := SQL%ROWCOUNT;

                -- Fermeture des distributions
                UPDATE PO.PO_DISTRIBUTIONS_ALL
                SET CLOSED_CODE = 'FINALLY CLOSED',
                    CLOSED_DATE = SYSDATE,
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                    LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                WHERE PO_HEADER_ID = REC.PO_HEADER_ID
                AND NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';
                
                VN_DISTRIB_UPD := SQL%ROWCOUNT;

                -- Fermeture de l'en-tête
                UPDATE PO.PO_HEADERS_ALL
                SET CLOSED_DATE = SYSDATE,
    
    -- Résumé final
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ DE L''EXÉCUTION');
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('Total commandes traitées       : ' || VN_TOTAL);
    DBMS_OUTPUT.PUT_LINE('✓ Fermées avec succès          : ' || VN_SUCCESS);
    DBMS_OUTPUT.PUT_LINE('⚠ Déjà fermées (aucune action) : ' || VN_ALREADY_CLOSED);
    DBMS_OUTPUT.PUT_LINE('✗ Erreurs                      : ' || VN_ERROR);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Taux de succès : ' || 
        ROUND((VN_SUCCESS / NULLIF(VN_TOTAL, 0)) * 100, 2) || '%');
    DBMS_OUTPUT.PUT_LINE('Date/Heure fin : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    
    IF VN_ERROR > 0 THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('⚠ ATTENTION : Des erreurs ont été détectées.');
        DBMS_OUTPUT.PUT_LINE('  Vérifiez les commandes en erreur ci-dessus.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=====================================================================');
        DBMS_OUTPUT.PUT_LINE('✗ ERREUR CRITIQUE');
        DBMS_OUTPUT.PUT_LINE('=====================================================================');
        DBMS_OUTPUT.PUT_LINE('Code erreur : ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Message     : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Pile appels : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        DBMS_OUTPUT.PUT_LINE('=====================================================================');
        RAISE;
END;
/

-- =====================================================================
-- REQUÊTE DE VÉRIFICATION POST-FERMETURE
-- =====================================================================

PROMPT
PROMPT =====================================================================
PROMPT VÉRIFICATION DES STATUTS POST-FERMETURE
PROMPT =====================================================================
PROMPT

SELECT 
    PH.SEGMENT1 AS "Commande",
    HAOU.NAME AS "UO",
    PH.CLOSED_CODE AS "Statut",
    TO_CHAR(PH.CLOSED_DATE, 'DD/MM/YYYY') AS "Date Fermeture",
    (SELECT COUNT(*) FROM PO.PO_LINES_ALL PL 
     WHERE PL.PO_HEADER_ID = PH.PO_HEADER_ID 
     AND PL.CLOSED_CODE = 'FINALLY CLOSED') AS "Lignes Fermées",
    (SELECT COUNT(*) FROM PO.PO_LINE_LOCATIONS_ALL PLL 
     WHERE PLL.PO_HEADER_ID = PH.PO_HEADER_ID 
     AND PLL.CLOSED_CODE = 'FINALLY CLOSED') AS "Shipments Fermés",
    (SELECT COUNT(*) FROM PO.PO_DISTRIBUTIONS_ALL PDA 
     WHERE PDA.PO_HEADER_ID = PH.PO_HEADER_ID 
     AND PDA.CLOSED_CODE = 'FINALLY CLOSED') AS "Distrib Fermées"
FROM PO.PO_HEADERS_ALL PH
JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU ON HAOU.ORGANIZATION_ID = PH.ORG_ID
WHERE PH.SEGMENT1 IN (
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
ORDER BY PH.SEGMENT1;

PROMPT
PROMPT =====================================================================                   || RPAD(REC.SEGMENT1, 13, ' ')
                    || RPAD(REC.OU_NAME, 18, ' ')
                    || RPAD(REC.CLOSED_CODE || ' → CLOSED', 20, ' ')
                    || RPAD(VN_LINES_UPD || '/' || REC.NB_LINES, 8, ' ')
                    || RPAD(VN_SHIPMENTS_UPD || '/' || REC.NB_SHIPMENTS, 8, ' ')
                    || RPAD(VN_DISTRIB_UPD || '/' || REC.NB_DISTRIBUTIONS, 9, ' ')
                    || '✓ Fermée avec succès'
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                VN_ERROR := VN_ERROR + 1;
                VV_ERROR_MSG := SUBSTR(SQLERRM, 1, 100);
                DBMS_OUTPUT.PUT_LINE(
                       RPAD(VN_TOTAL, 4, ' ')
                    || RPAD(REC.SEGMENT1, 13, ' ')
                    || RPAD(REC.OU_NAME, 18, ' ')
                    || RPAD(REC.CLOSED_CODE, 20, ' ')
                    || RPAD(REC.NB_LINES, 8, ' ')
                    || RPAD(REC.NB_SHIPMENTS, 8, ' ')
                    || RPAD(REC.NB_DISTRIBUTIONS, 9, ' ')
                    || '✗ ERREUR: ' || VV_ERROR_MSG
                );
        END;
    END LOOP;

    
    DBMS_OUTPUT.PUT_LINE ('*** FIN DU TRAITEMENT');
-- COMMIT;

EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE ('ERREUR : ' || SQLCODE || ' est survenue.');
        DBMS_OUTPUT.PUT_LINE (SQLERRM);
        DBMS_OUTPUT.PUT_LINE ('FAILURE');
END;
/