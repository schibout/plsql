-- =====================================================================
-- Script de repousse GL pour factures rejetées
-- Outil : SQL Developer
-- Date d'exécution : &DATE_EXEC
-- =====================================================================

-- Configuration SQL Developer
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET FEEDBACK ON
SET ECHO ON
SET VERIFY OFF

PROMPT
PROMPT ╔═════════════════════════════════════════════════════════════════╗
PROMPT ║     SCRIPT DE REPOUSSE GL - FACTURES REJETÉES                  ║
PROMPT ╚═════════════════════════════════════════════════════════════════╝
PROMPT

-- Affichage des critères de sélection
PROMPT Critères de sélection :
PROMPT   - attribute10 LIKE 'NOT%'
PROMPT   - status = 'REJECTED'
PROMPT

DECLARE
    v_count_lines NUMBER := 0;
    v_count_lines_updated NUMBER := 0;
    v_count_invoices NUMBER := 0;
    v_count_invoices_updated NUMBER := 0;
    v_start_time TIMESTAMP := SYSTIMESTAMP;
    v_new_gl_date DATE := SYSDATE;
BEGIN
    -- Mise à jour du contexte d'application pour monitoring
    DBMS_APPLICATION_INFO.SET_MODULE(
        module_name => 'Repousse GL',
        action_name => 'Initialisation'
    );
    
    DBMS_OUTPUT.PUT_LINE('╔═════════════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║ DÉBUT DU TRAITEMENT                                            ║');
    DBMS_OUTPUT.PUT_LINE('╚═════════════════════════════════════════════════════════════════╝');
    DBMS_OUTPUT.PUT_LINE('Date/Heure : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Nouvelle GL_DATE : ' || TO_CHAR(v_new_gl_date, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Comptage des enregistrements AVANT traitement
    DBMS_APPLICATION_INFO.SET_ACTION('Comptage initial');
    
    SELECT COUNT(DISTINCT invoice_id)
    INTO v_count_invoices
    FROM ap_invoices_interface
    WHERE attribute10 LIKE 'NOT%'
      AND status = 'REJECTED';
    
    SELECT COUNT(*)
    INTO v_count_lines
    FROM ap_invoice_lines_interface
    WHERE invoice_id IN (
        SELECT invoice_id
        FROM ap_invoices_interface
        WHERE attribute10 LIKE 'NOT%'
          AND status = 'REJECTED'
    );
    
    DBMS_OUTPUT.PUT_LINE('┌─────────────────────────────────────────────────────────────────┐');
    DBMS_OUTPUT.PUT_LINE('│ ANALYSE INITIALE                                                │');
    DBMS_OUTPUT.PUT_LINE('├─────────────────────────────────────────────────────────────────┤');
    DBMS_OUTPUT.PUT_LINE('│ Factures à traiter       : ' || LPAD(TO_CHAR(v_count_invoices), 8) || '                       │');
    DBMS_OUTPUT.PUT_LINE('│ Lignes à traiter         : ' || LPAD(TO_CHAR(v_count_lines), 8) || '                       │');
    DBMS_OUTPUT.PUT_LINE('└─────────────────────────────────────────────────────────────────┘');
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_count_invoices = 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠ ATTENTION : Aucune facture à traiter');
        DBMS_OUTPUT.PUT_LINE('');
        RETURN;
    END IF;
    
    -- ÉTAPE 1 : Mise à jour des lignes
    DBMS_APPLICATION_INFO.SET_ACTION('MAJ ap_invoice_lines_interface');
    
    DBMS_OUTPUT.PUT_LINE('┌─────────────────────────────────────────────────────────────────┐');
    DBMS_OUTPUT.PUT_LINE('│ ÉTAPE 1/3 : Mise à jour des lignes                             │');
    DBMS_OUTPUT.PUT_LINE('│ Table : ap_invoice_lines_interface                              │');
    DBMS_OUTPUT.PUT_LINE('├─────────────────────────────────────────────────────────────────┤');
    
    UPDATE ap_invoice_lines_interface
    SET accounting_date = v_new_gl_date
    WHERE invoice_id IN (
        SELECT invoice_id
        FROM ap_invoices_interface
        WHERE attribute10 LIKE 'NOT%'
          AND status = 'REJECTED'
    );
    
    v_count_lines_updated := SQL%ROWCOUNT;
    
    DBMS_OUTPUT.PUT_LINE('│ Champ modifié            : accounting_date                      │');
    DBMS_OUTPUT.PUT_LINE('│ Nouvelle valeur          : ' || TO_CHAR(v_new_gl_date, 'DD/MM/YYYY') || '                           │');
    DBMS_OUTPUT.PUT_LINE('│ Lignes mises à jour      : ' || LPAD(TO_CHAR(v_count_lines_updated), 8) || '                       │');
    DBMS_OUTPUT.PUT_LINE('│ Statut                   : ✓ OK                                 │');
    DBMS_OUTPUT.PUT_LINE('└─────────────────────────────────────────────────────────────────┘');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- ÉTAPE 2 : Mise à jour des en-têtes
    DBMS_APPLICATION_INFO.SET_ACTION('MAJ ap_invoices_interface');
    
    DBMS_OUTPUT.PUT_LINE('┌─────────────────────────────────────────────────────────────────┐');
    DBMS_OUTPUT.PUT_LINE('│ ÉTAPE 2/3 : Mise à jour des en-têtes                           │');
    DBMS_OUTPUT.PUT_LINE('│ Table : ap_invoices_interface                                   │');
    DBMS_OUTPUT.PUT_LINE('├─────────────────────────────────────────────────────────────────┤');
    
    UPDATE ap_invoices_interface
    SET gl_date = v_new_gl_date, 
        status = NULL
    WHERE attribute10 LIKE 'NOT%'
      AND status = 'REJECTED';
    
    v_count_invoices_updated := SQL%ROWCOUNT;
    
    DBMS_OUTPUT.PUT_LINE('│ Champs modifiés          : gl_date, status                      │');
    DBMS_OUTPUT.PUT_LINE('│ Nouvelle gl_date         : ' || TO_CHAR(v_new_gl_date, 'DD/MM/YYYY') || '                           │');
    DBMS_OUTPUT.PUT_LINE('│ Nouveau status           : NULL                                 │');
    DBMS_OUTPUT.PUT_LINE('│ Factures mises à jour    : ' || LPAD(TO_CHAR(v_count_invoices_updated), 8) || '                       │');
    DBMS_OUTPUT.PUT_LINE('│ Statut                   : ✓ OK                                 │');
    DBMS_OUTPUT.PUT_LINE('└─────────────────────────────────────────────────────────────────┘');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- ÉTAPE 3 : Validation de la transaction
    DBMS_APPLICATION_INFO.SET_ACTION('COMMIT');
    
    DBMS_OUTPUT.PUT_LINE('┌─────────────────────────────────────────────────────────────────┐');
    DBMS_OUTPUT.PUT_LINE('│ ÉTAPE 3/3 : Validation de la transaction                       │');
    DBMS_OUTPUT.PUT_LINE('├─────────────────────────────────────────────────────────────────┤');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('│ Transaction              : COMMIT                               │');
    DBMS_OUTPUT.PUT_LINE('│ Statut                   : ✓ Validé avec succès                │');
    DBMS_OUTPUT.PUT_LINE('└─────────────────────────────────────────────────────────────────┘');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Résumé final
    DBMS_OUTPUT.PUT_LINE('╔═════════════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║ RÉSUMÉ DE L''EXÉCUTION                                          ║');
    DBMS_OUTPUT.PUT_LINE('╠═════════════════════════════════════════════════════════════════╣');
    DBMS_OUTPUT.PUT_LINE('║ Date/Heure fin      : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '                    ║');
    DBMS_OUTPUT.PUT_LINE('║ Durée totale        : ' || 
        LPAD(TO_CHAR(ROUND((SYSTIMESTAMP - v_start_time) * 24 * 60 * 60, 2)), 8) || ' secondes                   ║');
    DBMS_OUTPUT.PUT_LINE('║ Factures traitées   : ' || LPAD(TO_CHAR(v_count_invoices_updated), 8) || '                           ║');
    DBMS_OUTPUT.PUT_LINE('║ Lignes traitées     : ' || LPAD(TO_CHAR(v_count_lines_updated), 8) || '                           ║');
    DBMS_OUTPUT.PUT_LINE('║ Résultat            : ✓ SUCCÈS                                 ║');
    DBMS_OUTPUT.PUT_LINE('╚═════════════════════════════════════════════════════════════════╝');
    
    DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('╔═════════════════════════════════════════════════════════════════╗');
        DBMS_OUTPUT.PUT_LINE('║ ✗ ERREUR DÉTECTÉE                                              ║');
        DBMS_OUTPUT.PUT_LINE('╠═════════════════════════════════════════════════════════════════╣');
        DBMS_OUTPUT.PUT_LINE('║ Code erreur         : ' || LPAD(TO_CHAR(SQLCODE), 10) || '                           ║');
        DBMS_OUTPUT.PUT_LINE('║ Message             : ' || SUBSTR(SQLERRM, 1, 43) || ' ║');
        IF LENGTH(SQLERRM) > 43 THEN
            DBMS_OUTPUT.PUT_LINE('║                       ' || SUBSTR(SQLERRM, 44, 43) || ' ║');
        END IF;
        DBMS_OUTPUT.PUT_LINE('║ Action              : ROLLBACK effectué                        ║');
        DBMS_OUTPUT.PUT_LINE('║ Date/Heure          : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '                    ║');
        DBMS_OUTPUT.PUT_LINE('╚═════════════════════════════════════════════════════════════════╝');
        
        DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL);
        RAISE;
END;
/

PROMPT
PROMPT ═══════════════════════════════════════════════════════════════════
PROMPT   FIN DU SCRIPT
PROMPT ═══════════════════════════════════════════════════════════════════
PROMPT