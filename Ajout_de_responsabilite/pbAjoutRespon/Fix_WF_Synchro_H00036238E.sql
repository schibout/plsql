-- =====================================================================
-- Fix : Synchronisation WF_LOCAL_ROLES pour H00036238E (SNOECK, EMILIE)
-- =====================================================================
-- Date de création : 03/04/2026
-- Auteur           : GitHub Copilot / Diagnostic EBS
-- Base de données  : Oracle EBS 12.2.13
--
-- PROBLÈME :
--   ORA-20002: [WF_NO_USER] NAME=H00036238E ORIG_SYSTEM=NULL ORIG_SYSTEM_ID=NULL
--   détecté dans FND_USER_RESP_GROUPS_API.INSERT_ASSIGNMENT
--
-- CAUSE RACINE :
--   - Compte FND_USER créé le 03/04/2026 (USER_ID=36993, EMPLOYEE_ID=78409)
--   - Fiche RH PER_ALL_PEOPLE_F effective à partir du 07/04/2026 (pas encore active)
--   - La synchronisation automatique WF a échoué → aucune ligne dans WF_LOCAL_ROLES
--   - FND_USER_RESP_GROUPS_API.INSERT_ASSIGNMENT requiert une entrée WF pour fonctionner
--
-- SOLUTION :
--   Forcer la synchronisation du répertoire WF pour cet utilisateur FND
--   via WF_LOCAL_SYNCH.propagate_user (ORIG_SYSTEM = 'FND_USR')
-- =====================================================================

-- ÉTAPE 1 : Vérification avant correction
SELECT 
    'AVANT' AS ETAPE,
    wlr.NAME,
    wlr.ORIG_SYSTEM,
    wlr.ORIG_SYSTEM_ID,
    wlr.DISPLAY_NAME,
    wlr.STATUS
FROM APPLSYS.WF_LOCAL_ROLES wlr
WHERE (wlr.ORIG_SYSTEM = 'FND_USR' AND wlr.ORIG_SYSTEM_ID = 36993)
   OR (wlr.ORIG_SYSTEM = 'PER'     AND wlr.ORIG_SYSTEM_ID = 78409);

-- ÉTAPE 2 : Synchronisation WF pour l'utilisateur FND
-- (crée ou met à jour l'entrée dans WF_LOCAL_ROLES avec ORIG_SYSTEM='FND_USR')
BEGIN
    WF_LOCAL_SYNCH.propagate_user(
        p_orig_system    => 'FND_USR',
        p_orig_system_id => 36993   -- USER_ID de H00036238E dans FND_USER
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK : Synchronisation WF effectuée pour H00036238E (USER_ID=36993)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        RAISE;
END;
/

-- ÉTAPE 3 : Vérification après correction
SELECT 
    'APRES' AS ETAPE,
    wlr.NAME,
    wlr.ORIG_SYSTEM,
    wlr.ORIG_SYSTEM_ID,
    wlr.DISPLAY_NAME,
    wlr.STATUS,
    TO_CHAR(wlr.EXPIRATION_DATE,'DD/MM/YYYY') AS EXPIRATION_DATE
FROM APPLSYS.WF_LOCAL_ROLES wlr
WHERE (wlr.ORIG_SYSTEM = 'FND_USR' AND wlr.ORIG_SYSTEM_ID = 36993)
   OR (wlr.ORIG_SYSTEM = 'PER'     AND wlr.ORIG_SYSTEM_ID = 78409);
