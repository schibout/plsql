-- =====================================================================
-- CORRECTION - ERREUR GL DACAR : GET_UO_DALKIA_FROM_TACHE
-- =====================================================================
-- Date de création : 29/12/2025
-- Base de données : Oracle EBS 12.2.13
-- 
-- PROBLÈME :
-- Deux pièces GL Dacar rejetées par la PFE avec l'erreur :
-- VHC02_SRC_ECRITURESGL_241225-050002|GET_UO_DALKIA_FROM_TACHE|ASSURANCE202512-0001
--
-- CAUSE :
-- La tâche GK1596490T (projet FB0092005B) n'est pas référencée dans
-- HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12 de l'UO DNA0001
--
-- SOLUTION :
-- Mise à jour du champ ATTRIBUTE12 avec la bonne tâche
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET LINESIZE 200
SET PAGESIZE 1000

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 1 : DIAGNOSTIC - VÉRIFICATION DE L'ÉTAT ACTUEL
PROMPT =====================================================================
PROMPT

-- Vérifier la tâche
PROMPT ** 1.1 - Informations sur la tâche GK1596490T **
SELECT 
    PT.TASK_ID AS "Task ID",
    PT.TASK_NUMBER AS "Task Number",
    PT.TASK_NAME AS "Task Name",
    PT.PROJECT_ID AS "Project ID",
    PP.SEGMENT1 AS "Project Number",
    PP.NAME AS "Project Name",
    PP.ORG_ID AS "Org ID"
FROM 
    APPS.PA_TASKS PT
    LEFT JOIN APPS.PA_PROJECTS_ALL PP ON PT.PROJECT_ID = PP.PROJECT_ID
WHERE 
    PT.TASK_NUMBER = 'GK1596490T';

PROMPT
PROMPT ** 1.2 - Operating Unit DNA0001 actuelle **
SELECT 
    HAOU.ORGANIZATION_ID AS "Org ID",
    HAOU.NAME AS "UO Name",
    HAOU.ATTRIBUTE12 AS "Task Number Actuel",
    HAOU.DATE_FROM AS "Date Début",
    HAOU.DATE_TO AS "Date Fin"
FROM 
    APPS.HR_ALL_ORGANIZATION_UNITS HAOU
WHERE 
    HAOU.ORGANIZATION_ID = 89
    AND HAOU.NAME = 'DNA0001';

PROMPT
PROMPT ** 1.3 - Recherche de l'UO par la fonction get_task_number **
PROMPT (Devrait retourner 0 lignes avant correction)
SELECT 
    PT.TASK_NUMBER AS "Tâche Recherchée",
    HAOU.NAME AS "UO Trouvée (si existe)",
    HAOU.ATTRIBUTE12 AS "Task dans ATTRIBUTE12"
FROM 
    APPS.PA_TASKS PT
    LEFT JOIN APPS.HR_ALL_ORGANIZATION_UNITS HAOU 
        ON HAOU.ATTRIBUTE12 = PT.TASK_NUMBER
WHERE 
    PT.TASK_NUMBER = 'GK1596490T';

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 2 : VÉRIFICATION DES DÉPENDANCES
PROMPT =====================================================================
PROMPT

-- Vérifier si l'ancienne tâche GK0001338W est utilisée ailleurs
PROMPT ** 2.1 - Utilisation de l'ancienne tâche GK0001338W **
SELECT 
    PT.TASK_NUMBER AS "Task Number",
    PT.TASK_NAME AS "Task Name",
    PT.PROJECT_ID AS "Project ID",
    PP.SEGMENT1 AS "Project Number",
    PP.NAME AS "Project Name"
FROM 
    APPS.PA_TASKS PT
    JOIN APPS.PA_PROJECTS_ALL PP ON PT.PROJECT_ID = PP.PROJECT_ID
WHERE 
    PT.TASK_NUMBER = 'GK0001338W';

PROMPT
PROMPT ** 2.2 - Pièces GL en erreur pour ASSURANCE202512-0001 **
SELECT 
    STATUS AS "Statut",
    USER_JE_SOURCE_NAME AS "Source",
    COUNT(*) AS "Nb Lignes",
    SUM(ENTERED_DR) AS "Total Débit",
    SUM(ENTERED_CR) AS "Total Crédit"
FROM 
    APPS.GL_INTERFACE
WHERE 
    STATUS = 'E'
    AND (UPPER(REFERENCE1) LIKE '%ASSURANCE202512-0001%'
         OR UPPER(REFERENCE10) LIKE '%ASSURANCE202512-0001%'
         OR UPPER(REFERENCE2) LIKE '%VHC02_SRC_ECRITURESGL%')
GROUP BY 
    STATUS, USER_JE_SOURCE_NAME;

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 3 : CORRECTION (À EXÉCUTER MANUELLEMENT APRÈS VALIDATION)
PROMPT =====================================================================
PROMPT
PROMPT ⚠️  ATTENTION : Les commandes UPDATE ci-dessous sont en commentaire
PROMPT    Décommenter et exécuter UNIQUEMENT après validation fonctionnelle
PROMPT
PROMPT /*

-- Sauvegarde de l'ancienne valeur (optionnel mais recommandé)
/*
INSERT INTO APPS.DKA_STRANSCO_TAB (
    TRANSCO_NAME,
    CODE_SOURCE,
    CODE_CIBLE,
    DATE_DEBUT,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    CREATION_DATE,
    CREATED_BY
) VALUES (
    'DNA0001_TASK_HISTORY',
    'GK0001338W',
    TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
    SYSDATE,
    SYSDATE,
    FND_GLOBAL.USER_ID,
    SYSDATE,
    FND_GLOBAL.USER_ID
);
*/

-- Mise à jour du champ ATTRIBUTE12
/*
UPDATE APPS.HR_ALL_ORGANIZATION_UNITS
SET ATTRIBUTE12 = 'GK1596490T',
    LAST_UPDATE_DATE = SYSDATE,
    LAST_UPDATED_BY = FND_GLOBAL.USER_ID
WHERE ORGANIZATION_ID = 89
  AND NAME = 'DNA0001';

COMMIT;
*/

PROMPT */
PROMPT
PROMPT Pour exécuter la correction, décommenter le bloc ci-dessus et relancer
PROMPT

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 4 : VÉRIFICATION POST-CORRECTION
PROMPT =====================================================================
PROMPT
PROMPT Exécuter ces requêtes APRÈS la correction :
PROMPT

-- Vérification 1 : ATTRIBUTE12 mis à jour
PROMPT
PROMPT -- Vérification 1 : ATTRIBUTE12 mis à jour
PROMPT SELECT ORGANIZATION_ID, NAME, ATTRIBUTE12
PROMPT FROM APPS.HR_ALL_ORGANIZATION_UNITS
PROMPT WHERE ORGANIZATION_ID = 89 AND NAME = 'DNA0001';
PROMPT -- Résultat attendu : ATTRIBUTE12 = 'GK1596490T'
PROMPT

-- Vérification 2 : Fonction get_task_number retourne un résultat
PROMPT -- Vérification 2 : Fonction get_task_number retourne un résultat
PROMPT SELECT PT.TASK_NUMBER, HAOU.NAME AS UO_TROUVEE
PROMPT FROM APPS.PA_TASKS PT
PROMPT LEFT JOIN APPS.HR_ALL_ORGANIZATION_UNITS HAOU 
PROMPT     ON HAOU.ATTRIBUTE12 = PT.TASK_NUMBER
PROMPT WHERE PT.TASK_NUMBER = 'GK1596490T';
PROMPT -- Résultat attendu : UO_TROUVEE = 'DNA0001'
PROMPT

-- Vérification 3 : Cohérence Projet-UO-Tâche
PROMPT -- Vérification 3 : Cohérence Projet-UO-Tâche
PROMPT SELECT 
PROMPT     PT.TASK_NUMBER,
PROMPT     PP.SEGMENT1 AS PROJET,
PROMPT     HAOU.NAME AS UO,
PROMPT     HAOU.ATTRIBUTE12 AS TACHE_ATTR12,
PROMPT     CASE WHEN PT.TASK_NUMBER = HAOU.ATTRIBUTE12 THEN 'COHERENT' ELSE 'INCOHERENT' END AS STATUT
PROMPT FROM APPS.PA_TASKS PT
PROMPT JOIN APPS.PA_PROJECTS_ALL PP ON PT.PROJECT_ID = PP.PROJECT_ID
PROMPT JOIN APPS.HR_ALL_ORGANIZATION_UNITS HAOU ON PP.ORG_ID = HAOU.ORGANIZATION_ID
PROMPT WHERE PT.TASK_NUMBER = 'GK1596490T';
PROMPT -- Résultat attendu : STATUT = 'COHERENT'
PROMPT

PROMPT
PROMPT =====================================================================
PROMPT ÉTAPE 5 : RETRAITEMENT DES PIÈCES GL EN ERREUR
PROMPT =====================================================================
PROMPT
PROMPT Après correction, relancer le flux GL depuis l'interface EBS ou le batch
PROMPT Navigation suggérée : Comptabilité Générale > Journaux > Importer
PROMPT
PROMPT Ou relancer le programme concurrent : VHC02_SRC_ECRITURESGL
PROMPT

PROMPT
PROMPT =====================================================================
PROMPT RÉSUMÉ DE L'ANALYSE
PROMPT =====================================================================
PROMPT
PROMPT Tâche problématique    : GK1596490T (TF TRAVAUX DTGP MIDI)
PROMPT Projet                 : FB0092005B-DNA_0001PF ORG TRAV
PROMPT Operating Unit         : DNA0001 (Org ID 89)
PROMPT
PROMPT Ancienne valeur ATTR12 : GK0001338W
PROMPT Nouvelle valeur ATTR12 : GK1596490T
PROMPT
PROMPT Erreur originale      : VHC02_SRC_ECRITURESGL_241225-050002
PROMPT                          GET_UO_DALKIA_FROM_TACHE
PROMPT                          ASSURANCE202512-0001
PROMPT
PROMPT Package concerné       : XXEAI.XXEAI_INTERFACE_TOOLS_PKG
PROMPT Fonction incriminée    : get_task_number (lignes 234-251)
PROMPT
PROMPT =====================================================================
PROMPT FIN DU SCRIPT
PROMPT =====================================================================
