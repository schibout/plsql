-- =====================================================================
-- Correction des Dates - Notes de Frais Notilus
-- =====================================================================
-- Date de création : 03/02/2026
-- Auteur : Copilot
-- Base de données : Oracle EBS 12.2.13
-- Outil : SQL Developer
--
-- OBJECTIF : Mettre à jour les dates comptables des factures Notilus
--            bloquées dans les tables d'interface pour permettre leur
--            retraitement par le batch nocturne.
--
-- VOIR : ReadMe.md pour la documentation complète
-- =====================================================================

-- =============================================================================
-- SECTION 1 : DÉFINITION DES VARIABLES
-- =============================================================================
-- *** MODIFIER CES VALEURS UNE SEULE FOIS AVANT EXÉCUTION ***

-- Pour SQL Developer : Exécuter ce bloc en premier (F5 ou Ctrl+Enter)
-- Les valeurs seront demandées via popup ou modifiez-les directement ci-dessous

VAR v_nouvelle_date   VARCHAR2(10);
VAR v_source_notilus  VARCHAR2(10);
VAR nom_fichier       VARCHAR2(100);
VAR v_statut_filtre   VARCHAR2(20);
VAR mode_execution    VARCHAR2(20);

BEGIN
    -- =========================================================================
    -- PARAMÈTRES À MODIFIER ICI
    -- =========================================================================
    :v_nouvelle_date   := '01/06/2026';           -- Date GL cible (1er du mois ouvert)
    :v_source_notilus  := 'NOT';                -- Identifiant source Notilus (ATTRIBUTE9)
    :nom_fichier       := NULL;                 -- Optionnel: filtre ATTRIBUTE10 (NULL = tous)
    :v_statut_filtre   := 'REJECTED';           -- Statut à traiter
    :mode_execution    := 'SIMULATION';         -- Mode: 'SIMULATION' ou 'MISE_A_JOUR'
    -- =========================================================================
END;
/

-- Affichage des paramètres configurés
SELECT :v_nouvelle_date  AS "Date Cible",
       :v_source_notilus AS "Source",
       NVL(:nom_fichier, '(Tous les fichiers)') AS "Nom Fichier",
       :v_statut_filtre  AS "Statut Filtre",
       :mode_execution   AS "Mode Exécution"
FROM   DUAL;

-- =============================================================================
-- SECTION 2 : VÉRIFICATIONS AVANT CORRECTION
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    -- Variables de comptage
    v_nb_entetes        NUMBER := 0;
    v_nb_lignes_total   NUMBER := 0;
    v_nb_lignes_std     NUMBER := 0;
    v_nb_lignes_tax     NUMBER := 0;
    
    -- Variables pour les fichiers batch
    v_liste_fichiers    VARCHAR2(4000) := '';
    v_nb_fichiers       NUMBER := 0;
    
    -- Paramètres (bind variables)
    p_source            VARCHAR2(10)  := :v_source_notilus;
    p_statut_filtre     VARCHAR2(20)  := :v_statut_filtre;
    p_nom_fichier       VARCHAR2(100) := :nom_fichier;
    
    -- Curseur pour récupérer les fichiers batch distincts
    CURSOR c_fichiers IS
        SELECT DISTINCT ATTRIBUTE10 AS batch_file,
               COUNT(*) OVER (PARTITION BY ATTRIBUTE10) AS nb_factures
        FROM   ap_invoices_interface
        WHERE  ATTRIBUTE9 = p_source
        AND    Status = p_statut_filtre
        AND    (p_nom_fichier IS NULL OR ATTRIBUTE10 = p_nom_fichier)
        ORDER BY ATTRIBUTE10;
        
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('ÉTAPE 0 : Analyse des données à corriger');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =========================================================================
    -- Comptage des en-têtes
    -- =========================================================================
    SELECT COUNT(*)
    INTO   v_nb_entetes
    FROM   ap_invoices_interface
    WHERE  ATTRIBUTE9 = p_source
    AND    Status = p_statut_filtre
    AND    (p_nom_fichier IS NULL OR ATTRIBUTE10 = p_nom_fichier);
    
    -- =========================================================================
    -- Comptage des lignes (total)
    -- =========================================================================
    SELECT COUNT(*)
    INTO   v_nb_lignes_total
    FROM   ap_invoice_lines_interface
    WHERE  invoice_id IN (
        SELECT INVOICE_ID 
        FROM   ap_invoices_interface
        WHERE  ATTRIBUTE9 = p_source
        AND    Status = p_statut_filtre
        AND    (p_nom_fichier IS NULL OR ATTRIBUTE10 = p_nom_fichier)
    );
    
    -- =========================================================================
    -- Comptage des lignes STANDARD (hors TAX, avec EXPENDITURE_ITEM_DATE)
    -- =========================================================================
    SELECT COUNT(*)
    INTO   v_nb_lignes_std
    FROM   ap_invoice_lines_interface
    WHERE  invoice_id IN (
        SELECT INVOICE_ID 
        FROM   ap_invoices_interface
        WHERE  ATTRIBUTE9 = p_source
        AND    Status = p_statut_filtre
        AND    (p_nom_fichier IS NULL OR ATTRIBUTE10 = p_nom_fichier)
    )
    AND    LINE_TYPE_LOOKUP_CODE <> 'TAX'
    AND    EXPENDITURE_ITEM_DATE IS NOT NULL;
    
    -- =========================================================================
    -- Comptage des lignes TAX
    -- =========================================================================
    SELECT COUNT(*)
    INTO   v_nb_lignes_tax
    FROM   ap_invoice_lines_interface
    WHERE  invoice_id IN (
        SELECT INVOICE_ID 
        FROM   ap_invoices_interface
        WHERE  ATTRIBUTE9 = p_source
        AND    Status = p_statut_filtre
        AND    (p_nom_fichier IS NULL OR ATTRIBUTE10 = p_nom_fichier)
    )
    AND    LINE_TYPE_LOOKUP_CODE = 'TAX';
    
    -- =========================================================================
    -- Affichage du résumé des comptages
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ DES VOLUMES À TRAITER');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('Nombre d''en-têtes (factures)    : ' || v_nb_entetes);
    DBMS_OUTPUT.PUT_LINE('Nombre total de lignes          : ' || v_nb_lignes_total);
    DBMS_OUTPUT.PUT_LINE('  - Lignes standard (Étape 1)   : ' || v_nb_lignes_std);
    DBMS_OUTPUT.PUT_LINE('  - Lignes TAX (Étape 2)        : ' || v_nb_lignes_tax);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =========================================================================
    -- Liste des fichiers batch (ATTRIBUTE10)
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('FICHIERS BATCH CONCERNÉS (ATTRIBUTE10)');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    
    FOR rec IN c_fichiers LOOP
        v_nb_fichiers := v_nb_fichiers + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(NVL(rec.batch_file, '(NULL)'), 55) || ' | ' || rec.nb_factures || ' facture(s)');
        
        -- Construction de la liste pour réutilisation
        IF rec.batch_file IS NOT NULL THEN
            IF v_liste_fichiers IS NOT NULL AND LENGTH(v_liste_fichiers) > 0 THEN
                v_liste_fichiers := v_liste_fichiers || ', ';
            END IF;
            v_liste_fichiers := v_liste_fichiers || '''' || rec.batch_file || '''';
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total fichiers batch : ' || v_nb_fichiers);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =========================================================================
    -- Affichage de la liste pour clause IN (copier-coller)
    -- =========================================================================
    IF v_liste_fichiers IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('=====================================================');
        DBMS_OUTPUT.PUT_LINE('LISTE POUR CLAUSE IN (ATTRIBUTE10) :');
        DBMS_OUTPUT.PUT_LINE('=====================================================');
        DBMS_OUTPUT.PUT_LINE(v_liste_fichiers);
        DBMS_OUTPUT.PUT_LINE('=====================================================');
    END IF;
    
END;
/

-- =============================================================================
-- SECTION 3 : EXÉCUTION DES CORRECTIONS
-- =============================================================================
-- Le mode d'exécution est contrôlé par la variable :mode_execution
-- - 'SIMULATION'   : Affiche ce qui serait modifié sans exécuter
-- - 'MISE_A_JOUR'  : Exécute réellement les UPDATE

DECLARE
    -- Variables
    v_mode              VARCHAR2(20)  := :mode_execution;
    v_nouvelle_date_dt  DATE          := TO_DATE(:v_nouvelle_date, 'DD/MM/YY');
    v_source            VARCHAR2(10)  := :v_source_notilus;
    v_statut            VARCHAR2(20)  := :v_statut_filtre;
    v_fichier           VARCHAR2(100) := :nom_fichier;
    
    -- Compteurs
    v_nb_lignes_std     NUMBER := 0;
    v_nb_lignes_tax     NUMBER := 0;
    v_nb_entetes        NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('SECTION 3 : CORRECTIONS - MODE ' || v_mode);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_mode NOT IN ('SIMULATION', 'MISE_A_JOUR') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Mode invalide. Valeurs autorisées : SIMULATION ou MISE_A_JOUR');
    END IF;
    
    -- =========================================================================
    -- ÉTAPE 1 : Mise à jour lignes (hors TAX)
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('--- ÉTAPE 1 : Lignes standard (hors TAX) ---');
    
    IF v_mode = 'SIMULATION' THEN
        SELECT COUNT(*)
        INTO   v_nb_lignes_std
        FROM   ap_invoice_lines_interface
        WHERE  invoice_id IN (
            SELECT INVOICE_ID 
            FROM   ap_invoices_interface
            WHERE  ATTRIBUTE9 = v_source
            AND    Status = v_statut
            AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier)
        )
        AND    LINE_TYPE_LOOKUP_CODE <> 'TAX'
        AND    EXPENDITURE_ITEM_DATE IS NOT NULL;
        
        DBMS_OUTPUT.PUT_LINE('[SIMULATION] ' || v_nb_lignes_std || ' ligne(s) seraient mises à jour');
    ELSE
        UPDATE ap_invoice_lines_interface
        SET    ACCOUNTING_DATE        = v_nouvelle_date_dt,
               EXPENDITURE_ITEM_DATE  = v_nouvelle_date_dt
        WHERE  invoice_id IN (
            SELECT INVOICE_ID 
            FROM   ap_invoices_interface
            WHERE  ATTRIBUTE9 = v_source
            AND    Status = v_statut
            AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier)
        )
        AND    LINE_TYPE_LOOKUP_CODE <> 'TAX'
        AND    EXPENDITURE_ITEM_DATE IS NOT NULL;
        
        v_nb_lignes_std := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('[MISE_A_JOUR] ' || v_nb_lignes_std || ' ligne(s) mise(s) à jour');
    END IF;
    
    -- =========================================================================
    -- ÉTAPE 2 : Mise à jour lignes TAX
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- ÉTAPE 2 : Lignes TAX ---');
    
    IF v_mode = 'SIMULATION' THEN
        SELECT COUNT(*)
        INTO   v_nb_lignes_tax
        FROM   ap_invoice_lines_interface
        WHERE  invoice_id IN (
            SELECT INVOICE_ID 
            FROM   ap_invoices_interface
            WHERE  ATTRIBUTE9 = v_source
            AND    Status = v_statut
            AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier)
        )
        AND    LINE_TYPE_LOOKUP_CODE = 'TAX';
        
        DBMS_OUTPUT.PUT_LINE('[SIMULATION] ' || v_nb_lignes_tax || ' ligne(s) seraient mises à jour');
    ELSE
        UPDATE ap_invoice_lines_interface
        SET    ACCOUNTING_DATE = v_nouvelle_date_dt
        WHERE  invoice_id IN (
            SELECT INVOICE_ID 
            FROM   ap_invoices_interface
            WHERE  ATTRIBUTE9 = v_source
            AND    Status = v_statut
            AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier)
        )
        AND    LINE_TYPE_LOOKUP_CODE = 'TAX';
        
        v_nb_lignes_tax := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('[MISE_A_JOUR] ' || v_nb_lignes_tax || ' ligne(s) mise(s) à jour');
    END IF;
    
    -- =========================================================================
    -- ÉTAPE 3 : Mise à jour en-têtes (GL_DATE)
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- ÉTAPE 3 : En-têtes (GL_DATE) ---');
    
    IF v_mode = 'SIMULATION' THEN
        SELECT COUNT(*)
        INTO   v_nb_entetes
        FROM   ap_invoices_interface
        WHERE  ATTRIBUTE9 = v_source
        AND    Status = v_statut
        AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier);
        
        DBMS_OUTPUT.PUT_LINE('[SIMULATION] ' || v_nb_entetes || ' en-tête(s) seraient mis à jour');
    ELSE
        UPDATE ap_invoices_interface
        SET    GL_DATE = v_nouvelle_date_dt
        WHERE  ATTRIBUTE9 = v_source
        AND    Status = v_statut
        AND    (v_fichier IS NULL OR ATTRIBUTE10 = v_fichier);
        
        v_nb_entetes := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('[MISE_A_JOUR] ' || v_nb_entetes || ' en-tête(s) mis à jour');
    END IF;
    
    -- =========================================================================
    -- Résumé
    -- =========================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ DES MODIFICATIONS');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('Lignes standard : ' || v_nb_lignes_std);
    DBMS_OUTPUT.PUT_LINE('Lignes TAX      : ' || v_nb_lignes_tax);
    DBMS_OUTPUT.PUT_LINE('En-têtes        : ' || v_nb_entetes);
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    
    IF v_mode = 'SIMULATION' THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** MODE SIMULATION : Aucune modification en base ***');
        DBMS_OUTPUT.PUT_LINE('Pour exécuter réellement, modifier :mode_execution = ''MISE_A_JOUR''');
    ELSE
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** MODIFICATIONS EFFECTUÉES ***');
        DBMS_OUTPUT.PUT_LINE('ATTENTION : Pensez à exécuter COMMIT pour valider !');
    END IF;
    
END;
/

-- =============================================================================
-- SECTION 4 : VALIDATION
-- =============================================================================
-- Exécuter COMMIT pour valider les modifications
-- Exécuter ROLLBACK pour annuler

-- COMMIT;
-- ROLLBACK;

-- =============================================================================
-- SECTION 5 : VÉRIFICATION POST-CORRECTION
-- =============================================================================

-- Comptage des en-têtes modifiés
SELECT COUNT(*) AS "Nombre d'en-têtes modifiés"
FROM   ap_invoices_interface
WHERE  ATTRIBUTE9 = :v_source_notilus
AND    GL_DATE = TO_DATE(:v_nouvelle_date, 'DD/MM/YY')
AND    Status = :v_statut_filtre
AND    (:nom_fichier IS NULL OR ATTRIBUTE10 = :nom_fichier);

-- Comptage des lignes modifiées par type
SELECT LINE_TYPE_LOOKUP_CODE AS "Type de ligne",
       COUNT(*) AS "Nombre de lignes"
FROM   ap_invoice_lines_interface
WHERE  invoice_id IN (
    SELECT INVOICE_ID
    FROM   ap_invoices_interface
    WHERE  ATTRIBUTE9 = :v_source_notilus
    AND    GL_DATE = TO_DATE(:v_nouvelle_date, 'DD/MM/YY')
    AND    Status = :v_statut_filtre
    AND    (:nom_fichier IS NULL OR ATTRIBUTE10 = :nom_fichier)
)
GROUP BY LINE_TYPE_LOOKUP_CODE
ORDER BY LINE_TYPE_LOOKUP_CODE;

-- Nombre total de lignes modifiées
SELECT COUNT(*) AS "Nombre total de lignes modifiées"
FROM   ap_invoice_lines_interface
WHERE  invoice_id IN (
    SELECT INVOICE_ID
    FROM   ap_invoices_interface
    WHERE  ATTRIBUTE9 = :v_source_notilus
    AND    GL_DATE = TO_DATE(:v_nouvelle_date, 'DD/MM/YY')
    AND    Status = :v_statut_filtre
    AND    (:nom_fichier IS NULL OR ATTRIBUTE10 = :nom_fichier)
);

-- =============================================================================
-- FIN DU SCRIPT
-- =============================================================================
