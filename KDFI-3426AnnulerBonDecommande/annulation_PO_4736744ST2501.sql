-- =====================================================================
-- SCRIPT D'ANNULATION - BON DE COMMANDE 4736744ST2501
-- =====================================================================
-- Date de création : 29/12/2025
-- Ticket : KDFI-3426
-- Base de données : Oracle EBS 12.2.13
-- 
-- BON DE COMMANDE :
-- Numéro : 4736744ST2501
-- Fournisseur : ONET SERVICES
-- Statut : APPROVED (Approuvé)
-- Date création : 24/03/2025
-- Quantité commandée : 1940,4 unités
-- État : Entièrement réceptionné (RECEIVE + DELIVER le 24/03/2025)
--
-- PROBLÈME :
-- Le bon de commande a été entièrement réceptionné et doit être annulé.
-- L'annulation directe n'est pas possible car des réceptions existent.
--
-- PROCÉDURE :
-- 1. Annuler les réceptions (via interface EBS ou API)
-- 2. Annuler le bon de commande
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET LINESIZE 200
SET PAGESIZE 1000

-- =====================================================================
-- INITIALISATION DU CONTEXTE ORACLE EBS
-- =====================================================================
-- user_id     : ID de l'utilisateur fonctionnel (FND_USER.USER_ID)
-- resp_id     : ID de la responsabilité Achats
-- resp_appl_id: 201 = Application Purchasing (PO)
-- =====================================================================

DECLARE
    l_user_id      NUMBER := 0;   -- Remplacer par l'USER_ID réel (ex: SELECT USER_ID FROM FND_USER WHERE USER_NAME='SCHIBOUT')
    l_resp_id      NUMBER := 0;   -- Remplacer par le RESPONSIBILITY_ID Achats
    l_resp_appl_id NUMBER := 201; -- Application ID : Purchasing
BEGIN
    -- Récupération dynamique de l'user (ajuster le USER_NAME)
    SELECT USER_ID INTO l_user_id
    FROM FND_USER
    WHERE USER_NAME = 'SCHIBOUT'  -- ← Adapter le USER_NAME
    FETCH FIRST 1 ROWS ONLY;

    -- Récupération de la responsabilité Achats
    SELECT RESPONSIBILITY_ID INTO l_resp_id
    FROM FND_RESPONSIBILITY_VL
    WHERE APPLICATION_ID = 201
      AND RESPONSIBILITY_KEY LIKE '%PURCHASING%'
    FETCH FIRST 1 ROWS ONLY;

    -- Initialisation du contexte applicatif
    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => l_user_id,
        resp_id      => l_resp_id,
        resp_appl_id => l_resp_appl_id
    );

    DBMS_OUTPUT.PUT_LINE('Contexte EBS initialisé :');
    DBMS_OUTPUT.PUT_LINE('  USER_ID      = ' || l_user_id);
    DBMS_OUTPUT.PUT_LINE('  RESP_ID      = ' || l_resp_id);
    DBMS_OUTPUT.PUT_LINE('  RESP_APPL_ID = ' || l_resp_appl_id);
END;
/

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 1 : VÉRIFICATION DE L'ÉTAT ACTUEL DU BON DE COMMANDE
PROMPT =====================================================================
PROMPT

-- État général du PO
SELECT 
    PHA.SEGMENT1 AS "Numéro PO",
    PHA.PO_HEADER_ID,
    PHA.TYPE_LOOKUP_CODE AS "Type PO",
    PHA.AUTHORIZATION_STATUS AS "Statut Approbation",
    PHA.APPROVED_FLAG AS "Approuvé",
    PHA.CANCEL_FLAG AS "Annulé",
    PHA.CLOSED_CODE AS "Code Fermeture",
    TO_CHAR(PHA.CREATION_DATE, 'DD/MM/YYYY') AS "Date Création",
    TO_CHAR(PHA.APPROVED_DATE, 'DD/MM/YYYY') AS "Date Approbation",
    PV.VENDOR_NAME AS "Fournisseur",
    PHA.CURRENCY_CODE AS "Devise"
FROM 
    PO.PO_HEADERS_ALL PHA
    LEFT JOIN AP.AP_SUPPLIERS PV ON PHA.VENDOR_ID = PV.VENDOR_ID
WHERE 
    PHA.SEGMENT1 = '4736744ST2501';

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 2 : DÉTAIL DES LIGNES DU BON DE COMMANDE
PROMPT =====================================================================
PROMPT

SELECT 
    PLA.LINE_NUM AS "Ligne",
    PLA.PO_LINE_ID,
    PLA.ITEM_DESCRIPTION AS "Description",
    PLA.QUANTITY AS "Qté Commandée",
    PLA.CANCEL_FLAG AS "Ligne Annulée",
    PLA.CLOSED_CODE AS "Ligne Fermée"
FROM 
    PO.PO_HEADERS_ALL PHA
    INNER JOIN PO.PO_LINES_ALL PLA ON PHA.PO_HEADER_ID = PLA.PO_HEADER_ID
WHERE 
    PHA.SEGMENT1 = '4736744ST2501'
ORDER BY 
    PLA.LINE_NUM;

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 3 : RÉCEPTIONS À ANNULER
PROMPT =====================================================================
PROMPT
PROMPT ⚠ ATTENTION : Ces réceptions doivent être annulées AVANT le PO
PROMPT

SELECT 
    PLA.LINE_NUM AS "Numéro Ligne",
    RT.TRANSACTION_ID AS "ID Transaction",
    RT.TRANSACTION_TYPE AS "Type Transaction",
    TO_CHAR(RT.TRANSACTION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS "Date Réception",
    RT.QUANTITY AS "Qté Réceptionnée",
    RT.UNIT_OF_MEASURE AS "Unité",
    RSL.SHIPMENT_HEADER_ID AS "ID Réception Header",
    RSL.SHIPMENT_LINE_ID AS "ID Réception Line"
FROM 
    PO.PO_HEADERS_ALL PHA
    INNER JOIN PO.PO_LINES_ALL PLA ON PHA.PO_HEADER_ID = PLA.PO_HEADER_ID
    INNER JOIN PO.RCV_TRANSACTIONS RT ON RT.PO_HEADER_ID = PHA.PO_HEADER_ID 
        AND RT.PO_LINE_ID = PLA.PO_LINE_ID
    LEFT JOIN PO.RCV_SHIPMENT_LINES RSL ON RT.SHIPMENT_LINE_ID = RSL.SHIPMENT_LINE_ID
WHERE 
    PHA.SEGMENT1 = '4736744ST2501'
    AND RT.TRANSACTION_TYPE IN ('RECEIVE', 'DELIVER')
ORDER BY 
    PLA.LINE_NUM, RT.TRANSACTION_DATE;

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 4 : VÉRIFICATION DES FACTURES ASSOCIÉES
PROMPT =====================================================================
PROMPT
PROMPT ⚠ Si des factures existent, elles doivent être annulées en premier
PROMPT

SELECT 
    AI.INVOICE_NUM AS "Numéro Facture",
    AI.INVOICE_ID,
    AI.INVOICE_TYPE_LOOKUP_CODE AS "Type Facture",
    TO_CHAR(AI.INVOICE_DATE, 'DD/MM/YYYY') AS "Date Facture",
    AI.INVOICE_AMOUNT AS "Montant Facture",
    AI.CANCELLED_DATE AS "Date Annulation",
    AI.PAYMENT_STATUS_FLAG AS "Statut Paiement"
FROM 
    AP.AP_INVOICES_ALL AI
    INNER JOIN AP.AP_INVOICE_DISTRIBUTIONS_ALL AID ON AI.INVOICE_ID = AID.INVOICE_ID
    INNER JOIN PO.PO_DISTRIBUTIONS_ALL PDA ON AID.PO_DISTRIBUTION_ID = PDA.PO_DISTRIBUTION_ID
    INNER JOIN PO.PO_HEADERS_ALL PHA ON PDA.PO_HEADER_ID = PHA.PO_HEADER_ID
WHERE 
    PHA.SEGMENT1 = '4736744ST2501'
ORDER BY 
    AI.INVOICE_DATE DESC;

PROMPT
PROMPT =====================================================================
PROMPT PROCÉDURE D'ANNULATION (À EXÉCUTER DANS ORACLE EBS)
PROMPT =====================================================================
PROMPT
PROMPT ÉTAPE 1 : ANNULATION DES RÉCEPTIONS
PROMPT ------------------------------------
PROMPT Navigation : Achats > Réceptions > Correction de réceptions
PROMPT 
PROMPT 1. Rechercher le PO : 4736744ST2501
PROMPT 2. Identifier les réceptions (Transaction IDs : 14842864 et 14842865)
PROMPT 3. Pour chaque réception :
PROMPT    - Sélectionner la ligne
PROMPT    - Créer une correction de type "Return to Supplier"
PROMPT    - Quantité à retourner : 1940,4
PROMPT    - Enregistrer et valider
PROMPT
PROMPT ÉTAPE 2 : ANNULATION DU BON DE COMMANDE
PROMPT -----------------------------------------
PROMPT Navigation : Achats > Bons de commande > Modification des bons de commande
PROMPT 
PROMPT 1. Rechercher le PO : 4736744ST2501
PROMPT 2. Actions > Contrôle > Annuler le bon de commande
PROMPT    OU
PROMPT    Sélectionner la ligne et cliquer sur "Annuler"
PROMPT
PROMPT ⚠ IMPORTANT : Ne JAMAIS modifier directement CANCEL_FLAG en SQL
PROMPT               Utiliser uniquement l'interface EBS ou les APIs Oracle
PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 5 : VÉRIFICATION POST-ANNULATION
PROMPT =====================================================================
PROMPT
PROMPT Exécuter ces requêtes APRÈS l'annulation pour vérifier le résultat :
PROMPT

-- Cette requête sera réexécutée après l'annulation
PROMPT
PROMPT -- Vérification du statut du PO après annulation :
PROMPT SELECT SEGMENT1, CANCEL_FLAG, CLOSED_CODE, AUTHORIZATION_STATUS
PROMPT FROM PO.PO_HEADERS_ALL WHERE SEGMENT1 = '4736744ST2501';
PROMPT
PROMPT -- Vérification des lignes après annulation :
PROMPT SELECT LINE_NUM, CANCEL_FLAG, CLOSED_CODE, QUANTITY
PROMPT FROM PO.PO_LINES_ALL WHERE PO_HEADER_ID = 5163969;
PROMPT
PROMPT -- Vérification des réceptions après annulation :
PROMPT SELECT TRANSACTION_TYPE, QUANTITY, TRANSACTION_DATE
PROMPT FROM PO.RCV_TRANSACTIONS 
PROMPT WHERE PO_HEADER_ID = 5163969
PROMPT ORDER BY TRANSACTION_DATE DESC;
PROMPT

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 6 : ANNULATION PAR API PL/SQL (alternative à l'interface EBS)
PROMPT =====================================================================
PROMPT Décommenter le bloc ci-dessous APRÈS avoir annulé les réceptions
PROMPT =====================================================================
PROMPT

/*

DECLARE
    l_return_status  VARCHAR2(1);
    l_msg_count      NUMBER;
    l_msg_data       VARCHAR2(2000);
    l_doc_type       VARCHAR2(25) := 'PO';          -- Standard Purchase Order
    l_doc_subtype    VARCHAR2(25) := 'STANDARD';
    l_doc_id         NUMBER       := 5163969;        -- PO_HEADER_ID de 4736744ST2501
    l_action         VARCHAR2(25) := 'CANCEL';
    l_action_date    DATE         := SYSDATE;
    l_note           VARCHAR2(240):= 'Annulation KDFI-3426 - PO 4736744ST2501';

BEGIN
    -- Appel à l'API standard d'annulation Oracle EBS
    PO_Document_Control_PUB.control_document(
        p_api_version        => 1.0,
        p_init_msg_list      => FND_API.G_TRUE,
        p_commit             => FND_API.G_FALSE,   -- Pas de COMMIT automatique
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_doc_type           => l_doc_type,
        p_doc_subtype        => l_doc_subtype,
        p_doc_id             => l_doc_id,
        p_doc_num            => NULL,
        p_release_id         => NULL,
        p_release_num        => NULL,
        p_doc_line_id        => NULL,
        p_doc_line_loc_id    => NULL,
        p_action             => l_action,
        p_action_date        => l_action_date,
        p_agent_id           => FND_GLOBAL.EMPLOYEE_ID,
        p_note               => l_note,
        p_approval_background_flag => NULL,
        p_mass_update_releases     => NULL,
        p_retroactive_price_change => NULL
    );

    DBMS_OUTPUT.PUT_LINE('Return Status : ' || l_return_status);

    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN

        DBMS_OUTPUT.PUT_LINE('API success - Vérification des mises à jour :');

        -- Contrôle LAST_UPDATE_DATE sur le PO header
        FOR r IN (
            SELECT SEGMENT1,
                   CANCEL_FLAG,
                   CLOSED_CODE,
                   AUTHORIZATION_STATUS,
                   TO_CHAR(LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI:SS') AS LAST_UPDATE_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_LOGIN
            FROM PO.PO_HEADERS_ALL
            WHERE PO_HEADER_ID = l_doc_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  PO             : ' || r.SEGMENT1);
            DBMS_OUTPUT.PUT_LINE('  CANCEL_FLAG    : ' || r.CANCEL_FLAG);
            DBMS_OUTPUT.PUT_LINE('  CLOSED_CODE    : ' || r.CLOSED_CODE);
            DBMS_OUTPUT.PUT_LINE('  AUTH_STATUS    : ' || r.AUTHORIZATION_STATUS);
            DBMS_OUTPUT.PUT_LINE('  LAST_UPD_DATE  : ' || r.LAST_UPDATE_DATE);
            DBMS_OUTPUT.PUT_LINE('  LAST_UPD_BY    : ' || r.LAST_UPDATED_BY);
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT effectué.');

    ELSE
        -- Affichage des messages d'erreur
        FOR i IN 1 .. l_msg_count LOOP
            DBMS_OUTPUT.PUT_LINE('Erreur ' || i || ' : ' ||
                FND_MSG_PUB.GET(p_msg_index => i, p_encoded => FND_API.G_FALSE));
        END LOOP;
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK effectué - annulation non réalisée.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION : ' || SQLERRM);
        ROLLBACK;
END;
/

*/

PROMPT
PROMPT =====================================================================
PROMPT RÉSUMÉ
PROMPT =====================================================================
PROMPT
PROMPT PO Number        : 4736744ST2501
PROMPT PO Header ID     : 5163969
PROMPT Fournisseur      : ONET SERVICES
PROMPT Quantité         : 1940,4
PROMPT Réceptions       : 2 transactions (RECEIVE + DELIVER)
PROMPT Factures         : Aucune (vérifiée)
PROMPT
PROMPT Statut actuel    : APPROVED, réceptionné, non annulé
PROMPT Action requise   : Annulation des réceptions puis du PO via EBS
PROMPT
PROMPT =====================================================================
PROMPT FIN DU SCRIPT D'ANALYSE
PROMPT =====================================================================
