-- =====================================================================
-- Script de déploiement - Correction avoirs contrôle de flux
-- =====================================================================
-- Date de création : 04/12/2025
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13 (DB 19.25)
--
-- OBJECTIF : Compiler le package APPS.DKA_SCTLFLUX_EAI_PKG corrigé
--
-- PREREQUIS : 
--   - Connexion en tant qu'utilisateur APPS
--   - Package body (.pkb) disponible dans le répertoire courant
--
-- UTILISATION :
--   sqlplus apps/password@oracleProd @deploiement_correction_avoirs.sql
--
-- VOIR : CORRECTION_Avoirs_04122025.md
--       RESUME_EXECUTIF_JIRA.md
-- =====================================================================

SET SERVEROUTPUT ON SIZE 1000000
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET TIMING ON

PROMPT =====================================================================
PROMPT DEPLOIEMENT - Correction avoirs contrôle de flux
PROMPT Date: 04/12/2025
PROMPT =====================================================================

PROMPT
PROMPT Étape 1 : Vérification de l'utilisateur connecté
PROMPT ---------------------------------------------------------------------
SELECT USER AS utilisateur_connecte,
       TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') AS date_execution
FROM DUAL;

PROMPT
PROMPT Étape 2 : État actuel du package
PROMPT ---------------------------------------------------------------------
SELECT object_name, 
       object_type, 
       status,
       TO_CHAR(last_ddl_time, 'DD/MM/YYYY HH24:MI:SS') AS derniere_modif
FROM dba_objects
WHERE owner = 'APPS'
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
ORDER BY object_type;

PROMPT
PROMPT Étape 3 : Sauvegarde de l'ancienne version (optionnel)
PROMPT ---------------------------------------------------------------------
PROMPT Si besoin, extraction du code actuel :
PROMPT SELECT text FROM dba_source 
PROMPT WHERE owner = 'APPS' AND name = 'DKA_SCTLFLUX_EAI_PKG' 
PROMPT AND type = 'PACKAGE BODY' ORDER BY line;

PROMPT
PROMPT Étape 4 : Compilation du package body corrigé
PROMPT ---------------------------------------------------------------------
PROMPT Compilation en cours...

-- Charger le package body corrigé
@@APPS.DKA_SCTLFLUX_EAI_PKG.pkb

PROMPT
PROMPT Étape 5 : Vérification de la compilation
PROMPT ---------------------------------------------------------------------
DECLARE
    v_status VARCHAR2(10);
    v_count_errors NUMBER;
BEGIN
    SELECT status INTO v_status
    FROM dba_objects
    WHERE owner = 'APPS'
      AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
      AND object_type = 'PACKAGE BODY';
    
    IF v_status = 'VALID' THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS : Package compilé avec succès - Status = VALID');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ ERREUR : Package en erreur - Status = ' || v_status);
        
        -- Afficher les erreurs de compilation
        SELECT COUNT(*) INTO v_count_errors
        FROM dba_errors
        WHERE owner = 'APPS'
          AND name = 'DKA_SCTLFLUX_EAI_PKG'
          AND type = 'PACKAGE BODY';
          
        IF v_count_errors > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Nombre d''erreurs : ' || v_count_errors);
            DBMS_OUTPUT.PUT_LINE('Détails :');
            
            FOR err_rec IN (SELECT line, position, text
                           FROM dba_errors
                           WHERE owner = 'APPS'
                             AND name = 'DKA_SCTLFLUX_EAI_PKG'
                             AND type = 'PACKAGE BODY'
                           ORDER BY line, position)
            LOOP
                DBMS_OUTPUT.PUT_LINE('  Ligne ' || err_rec.line || ', Position ' || err_rec.position || ' : ' || err_rec.text);
            END LOOP;
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERREUR : Package non trouvé après compilation');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERREUR : ' || SQLERRM);
END;
/

PROMPT
PROMPT Étape 6 : État final du package
PROMPT ---------------------------------------------------------------------
SELECT object_name, 
       object_type, 
       status,
       TO_CHAR(last_ddl_time, 'DD/MM/YYYY HH24:MI:SS') AS derniere_modif
FROM dba_objects
WHERE owner = 'APPS'
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
ORDER BY object_type;

PROMPT
PROMPT Étape 7 : Vérification des objets dépendants
PROMPT ---------------------------------------------------------------------
SELECT object_name,
       object_type,
       status
FROM dba_objects
WHERE owner = 'APPS'
  AND object_name IN (
    SELECT referenced_name
    FROM dba_dependencies
    WHERE owner = 'APPS'
      AND name = 'DKA_SCTLFLUX_EAI_PKG'
      AND type = 'PACKAGE BODY'
  )
  AND status != 'VALID';

PROMPT
PROMPT =====================================================================
PROMPT DEPLOIEMENT TERMINE
PROMPT =====================================================================
PROMPT
PROMPT ACTIONS SUIVANTES :
PROMPT 1. Vérifier que le package est VALID (ci-dessus)
PROMPT 2. Exécuter le script de vérification :
PROMPT    @Verification_correction_avoirs.sql
PROMPT 3. Tester sur un folio pilote (IGP ou SVD) :
PROMPT    - Exécuter le programme "DKA : Extraction du contrôle de flux"
PROMPT    - Comparer avec le contrôle amont
PROMPT 4. Surveillance 24-48h sur tous les folios
PROMPT
PROMPT DOCUMENTATION :
PROMPT - Détails techniques : CORRECTION_Avoirs_04122025.md
PROMPT - Résumé JIRA : RESUME_EXECUTIF_JIRA.md
PROMPT - Script validation : Verification_correction_avoirs.sql
PROMPT
PROMPT =====================================================================

SET TIMING OFF
EXIT
