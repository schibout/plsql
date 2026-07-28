-- =====================================================================
-- Contrôle Quotidien des Traitements - Clôture Comptable Dalkia
-- =====================================================================
-- Date de création : 03/02/2026
-- Auteur : Copilot
-- Base de données : Oracle EBS 12.2.13
-- Outil : SQL Developer
--
-- OBJECTIF : Générer un rapport quotidien des traitements concurrents
--            lors de la clôture comptable mensuelle.
--
-- USAGE : Exécuter chaque matin pour vérifier les traitements de la nuit.
-- =====================================================================

-- =============================================================================
-- SECTION 1 : PARAMÈTRES
-- =============================================================================

VAR v_date_debut      VARCHAR2(20);
VAR v_date_fin        VARCHAR2(20);
VAR v_type_controle   VARCHAR2(30);

BEGIN
    -- =========================================================================
    -- PARAMÈTRES À MODIFIER CHAQUE JOUR
    -- =========================================================================
    :v_date_debut    := '0/02/2026 00:00:00';   -- Date/heure début (nuit précédente)
    :v_date_fin      := '03/02/2026 08:00:00';   -- Date/heure fin (matin)
    
    -- Type de contrôle :
    -- 'TOUS'              : Tous les traitements
    -- 'ERREURS'           : Uniquement les erreurs et avertissements
    -- 'FA'                : Traitements Fixed Assets (avant clôture provisoire)
    -- 'CLOTURE_PROV'      : Clôture provisoire
    -- 'CLOTURE_DEF'       : Clôture définitive
    -- 'IVALUA'            : Flux iValua
    -- 'VCOM'              : Campagne de règlements
    -- 'COMPTABILISATION'  : Traitements de comptabilisation AP/AR/GL
    -- 'DTR'               : Jobs DTR
    -- 'HYPERION'          : Extractions Hyperion/Selene
    -- 'TVA'               : Traitements TVA
    -- 'REPETITIVES'       : Pièces répétitives
    :v_type_controle := 'TOUS';
    -- =========================================================================
END;
/

-- Affichage des paramètres
SELECT :v_date_debut   AS "Date Début",
       :v_date_fin     AS "Date Fin",
       :v_type_controle AS "Type Contrôle"
FROM   DUAL;

-- =============================================================================
-- SECTION 2 : RAPPORT SYNTHÉTIQUE - STATUTS
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_date_debut    DATE := TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS');
    v_date_fin      DATE := TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS');
    v_type_controle VARCHAR2(30) := :v_type_controle;
    
    v_total         NUMBER := 0;
    v_ok            NUMBER := 0;
    v_erreur        NUMBER := 0;
    v_warning       NUMBER := 0;
    v_running       NUMBER := 0;
    v_pending       NUMBER := 0;
    v_cancelled     NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('RAPPORT QUOTIDIEN - CLÔTURE COMPTABLE DALKIA');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('Période : ' || TO_CHAR(v_date_debut, 'DD/MM/YYYY HH24:MI') || 
                         ' à ' || TO_CHAR(v_date_fin, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('Type    : ' || v_type_controle);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Comptage par statut
    SELECT COUNT(*),
           SUM(CASE WHEN fcr.STATUS_CODE = 'C' THEN 1 ELSE 0 END),
           SUM(CASE WHEN fcr.STATUS_CODE = 'E' THEN 1 ELSE 0 END),
           SUM(CASE WHEN fcr.STATUS_CODE = 'G' THEN 1 ELSE 0 END),
           SUM(CASE WHEN fcr.STATUS_CODE = 'R' THEN 1 ELSE 0 END),
           SUM(CASE WHEN fcr.STATUS_CODE IN ('I', 'Q') THEN 1 ELSE 0 END),
           SUM(CASE WHEN fcr.STATUS_CODE = 'D' THEN 1 ELSE 0 END)
    INTO   v_total, v_ok, v_erreur, v_warning, v_running, v_pending, v_cancelled
    FROM   FND_CONCURRENT_REQUESTS fcr
    WHERE  fcr.ACTUAL_START_DATE >= v_date_debut
    AND    fcr.ACTUAL_START_DATE <= v_date_fin;
    
    DBMS_OUTPUT.PUT_LINE('SYNTHÈSE DES STATUTS');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total traitements     : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('OK (C)                : ' || v_ok);
    DBMS_OUTPUT.PUT_LINE('Erreur (E)            : ' || v_erreur);
    DBMS_OUTPUT.PUT_LINE('Avertissement (G)     : ' || v_warning);
    DBMS_OUTPUT.PUT_LINE('En cours (R)          : ' || v_running);
    DBMS_OUTPUT.PUT_LINE('Programmé (I/Q)       : ' || v_pending);
    DBMS_OUTPUT.PUT_LINE('Annulé (D)            : ' || v_cancelled);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    
    IF v_erreur > 0 THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ATTENTION : ' || v_erreur || ' TRAITEMENT(S) EN ERREUR ***');
    END IF;
    
    IF v_warning > 0 THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ' || v_warning || ' TRAITEMENT(S) AVEC AVERTISSEMENT ***');
    END IF;
    
END;
/

-- =============================================================================
-- SECTION 3 : DÉTAIL DES ERREURS ET AVERTISSEMENTS
-- =============================================================================

SELECT fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE,
              'C', 'OK',
              'D', 'Annulé',
              'E', '*** ERREUR ***',
              'G', 'Avertissement',
              'I', 'Programmé',
              'Q', 'Programmé',
              'R', 'Running',
              fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI:SS') AS DEBUT,
       TO_CHAR(fcr.ACTUAL_COMPLETION_DATE, 'DD/MM HH24:MI:SS') AS FIN,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN,
       fu.USER_NAME AS DEMANDEUR,
       SUBSTR(fcr.COMPLETION_TEXT, 1, 80) AS MESSAGE
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
JOIN   FND_USER fu ON fcr.REQUESTED_BY = fu.USER_ID
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.STATUS_CODE IN ('E', 'G')  -- Erreurs et Avertissements uniquement
ORDER BY fcr.STATUS_CODE, fcr.REQUEST_ID DESC;

-- =============================================================================
-- SECTION 4 : CONTRÔLES SPÉCIFIQUES PAR TYPE
-- =============================================================================

-- *** 4.1 - PIÈCES RÉPÉTITIVES (Abonnements) ***
SELECT 'REPETITIVES' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'REPETITIVES', 'FA'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération des pièces répétitives%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération des pièces répétitives - Compte Rendu par CdG%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.2 - FIXED ASSETS (FA) ***
SELECT 'FA' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'FA'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Générer des comptes%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Incorporation des écritures d%amortissement%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'XXS FA - Créer des pièces%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Centraliser les pièces dans%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.3 - CLÔTURE PROVISOIRE ***
SELECT 'CLOTURE_PROV' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'CLOTURE_PROV'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA%facturation%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération des OD CAP multi-société%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : traitement de génération du CUT OFF%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Calcul des TEC et PCA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Gestion des CCA sur sinistres%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Equilibre comptable par centre de gestion%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Extourne des TEC et PCA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%DKA : Extourne CCA sur sinistre%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'FINFIN_C15TRT_04_WRK01_M : DKA_SPOCUTOFF_JOB.sh%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'FINFIN_C19TRT_04_WRK01_M : DKA_SPATRAVCOURS_JOB.sh%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.4 - CLÔTURE DÉFINITIVE ***
-- Traitements à vérifier après clôture définitive :
-- 1. DKA : Equilibre comptable par centre de gestion
-- 2. Alimentation Garantie Totale (DKA : Interface vers Garantie Totale)
-- 3. DKA : Etat déclaratif de la TVA dans GL (ou Automate)
-- 4. DKA : Etat de contrôle des retraitements IFRS
-- 5. DKA : Génération du fichier VECTOR
-- 6. DKA : Balance VECTOR
-- 7. DKA : Consolidation VECTOR
-- 8. Mettre à jour les soldes de comptabilité auxiliaire

SELECT 'CLOTURE_DEF' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', '*** ERREUR ***', 'G', 'WARNING', 'R', 'RUNNING', fcr.STATUS_CODE) AS STATUT,
       CASE 
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Equilibre comptable%' THEN '1-EQUILIBRE_CDG'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Interface vers Garantie Totale%' THEN '2-GARANTIE_TOTALE'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%Etat déclaratif de la TVA dans GL%' THEN '3-TVA_GL'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Etat de contrôle des retraitements IFRS%' THEN '4-IFRS'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération du fichier VECTOR%' THEN '5-VECTOR_FICHIER'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Balance VECTOR%' THEN '6-VECTOR_BALANCE'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Consolidation VECTOR%' THEN '7-VECTOR_CONSO'
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Mettre à jour les soldes de comptabilité auxiliaire%' THEN '8-MAJ_SOLDES'
           ELSE '9-AUTRE'
       END AS ORDRE,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       TO_CHAR(fcr.ACTUAL_COMPLETION_DATE, 'DD/MM HH24:MI') AS FIN,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'CLOTURE_DEF'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Equilibre comptable par centre de gestion%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Interface vers Garantie Totale%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%Etat déclaratif de la TVA dans GL%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Automate Etat déclaratif de la TVA dans GL%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Etat de contrôle des retraitements IFRS%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération du fichier VECTOR%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Balance VECTOR%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Consolidation VECTOR%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Mettre à jour les soldes de comptabilité auxiliaire%')
ORDER BY CASE 
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Equilibre comptable%' THEN 1
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Interface vers Garantie Totale%' THEN 2
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%Etat déclaratif de la TVA dans GL%' THEN 3
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Etat de contrôle des retraitements IFRS%' THEN 4
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Génération du fichier VECTOR%' THEN 5
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Balance VECTOR%' THEN 6
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Consolidation VECTOR%' THEN 7
           WHEN fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Mettre à jour les soldes de comptabilité auxiliaire%' THEN 8
           ELSE 9
       END, fcr.REQUEST_ID DESC;

-- *** 4.4b - CONTRÔLE GARANTIE TOTALE (à exécuter manuellement en PROD) ***
-- Vérification du montant total extrait pour Garantie Totale
-- SELECT SUM(amount) FROM DKA_IEOPAGTO01_TMP;

-- *** 4.5 - IVALUA ***
SELECT 'IVALUA' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'IVALUA'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Import des commandes depuis iValua%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Import des données Réceptions depuis iValua%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Import des codes de déblocage Facture depuis IVALUA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Import des données Fournisseurs depuis iValua%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Export des données Factures vers iValua%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Export des images Factures vers iValua%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA%alua%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.6 - CAMPAGNE DE RÈGLEMENTS (VCOM) ***
SELECT 'VCOM' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'VCOM'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA%glements automatiques toutes soc%des factures fournisseurs%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Campagne de règlements%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Créer des règlements%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Formater les instructions de règlement%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Etat relatif à la sélection de%échéancier de paiement%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'XXS AP - Registre des propositions de règlements%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Registre des instructions de règlement%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Auto Select (XXS AP%Programme de demande de traitement des règlements)%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.7 - COMPTABILISATION ***
SELECT 'COMPTABILISATION' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'COMPTABILISATION'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Créer une comptabilisation%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Programme de comptabilisation%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Imputation : Livre unique%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Mettre à jour les soldes de comptabilité auxiliaire%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'Centraliser des pièces dans GL%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.8 - DTR ***
SELECT 'DTR' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'DTR'))
AND    fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%DTR%'
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.9 - HYPERION / SELENE ***
SELECT 'HYPERION' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'HYPERION'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%HYP%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE '%HYPERION%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Export du détail de sous-traitance pour HYPERION%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA%Extraction%données%HYPERION%')
ORDER BY fcr.REQUEST_ID DESC;

-- *** 4.10 - TVA ***
SELECT 'TVA' AS TYPE_CTRL,
       fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (:v_type_controle IN ('TOUS', 'TVA'))
AND    (fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA%TVA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Automate%TVA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : France - Déclaration%TVA%'
        OR fcpt.USER_CONCURRENT_PROGRAM_NAME LIKE 'DKA : Compression et envoi des états de TVA aux régions%')
ORDER BY fcr.REQUEST_ID DESC;

-- =============================================================================
-- SECTION 5 : TRAITEMENTS LONGS (> 30 minutes)
-- =============================================================================

SELECT fcr.REQUEST_ID,
       DECODE(fcr.STATUS_CODE, 'C', 'OK', 'E', 'ERREUR', 'G', 'WARNING', 'R', 'RUNNING', fcr.STATUS_CODE) AS STATUT,
       fcpt.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM HH24:MI') AS DEBUT,
       TO_CHAR(fcr.ACTUAL_COMPLETION_DATE, 'DD/MM HH24:MI') AS FIN,
       ROUND((fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60, 1) AS DUREE_MIN,
       fu.USER_NAME AS DEMANDEUR
FROM   FND_CONCURRENT_REQUESTS fcr
JOIN   FND_CONCURRENT_PROGRAMS fcp 
       ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID 
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
JOIN   FND_CONCURRENT_PROGRAMS_TL fcpt 
       ON fcp.CONCURRENT_PROGRAM_ID = fcpt.CONCURRENT_PROGRAM_ID 
       AND fcp.APPLICATION_ID = fcpt.APPLICATION_ID 
       AND fcpt.LANGUAGE = 'F'
JOIN   FND_USER fu ON fcr.REQUESTED_BY = fu.USER_ID
WHERE  fcr.ACTUAL_START_DATE >= TO_DATE(:v_date_debut, 'DD/MM/YYYY HH24:MI:SS')
AND    fcr.ACTUAL_START_DATE <= TO_DATE(:v_date_fin, 'DD/MM/YYYY HH24:MI:SS')
AND    (fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) * 24 * 60 > 30  -- Plus de 30 minutes
ORDER BY (fcr.ACTUAL_COMPLETION_DATE - fcr.ACTUAL_START_DATE) DESC;

-- =============================================================================
-- FIN DU RAPPORT
-- =============================================================================
