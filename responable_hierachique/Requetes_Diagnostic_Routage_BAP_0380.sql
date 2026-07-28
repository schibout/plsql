-- =====================================================================
-- Requêtes de diagnostic — Problème de routage BAP site DNA0380
-- =====================================================================
-- Contexte : Notifications hiérarchiques JORIS → DEVILLIERS au lieu de BENESSE
-- Analyse   : Analyse_Probleme_Routage_Notif_JORIS_REDON.md
-- Date      : 15/04/2026
-- =====================================================================


-- =====================================================================
-- [1] IDENTIFIER L'OPERATING UNIT D'UN SITE (DNA0380 / DNA0820)
-- =====================================================================
SELECT HOU.ORGANIZATION_ID,
       HOU.NAME,
       HOU.ATTRIBUTE10  AS DIVISION,
       HOI.ORG_INFORMATION1  AS TYPE_CLASSE
  FROM HR_ALL_ORGANIZATION_UNITS    HOU
  JOIN HR_ORGANIZATION_INFORMATION  HOI
    ON HOI.ORGANIZATION_ID = HOU.ORGANIZATION_ID
 WHERE HOU.NAME IN ('DNA0380', 'DNA0820')
 ORDER BY HOU.NAME, HOI.ORG_INFORMATION_CONTEXT;


-- =====================================================================
-- [2] RÔLES WF ACTIFS SUR UN SITE (tous utilisateurs, sans filtre expiration)
--     → Permet de détecter les rôles oubliés sans DATE_EXPIRATION
-- =====================================================================
SELECT WLUR.USER_NAME,
       PAPF.FULL_NAME,
       WLUR.ROLE_NAME,
       TO_CHAR(WLUR.START_DATE,      'DD/MM/YYYY') AS START_DATE,
       TO_CHAR(WLUR.EXPIRATION_DATE, 'DD/MM/YYYY') AS EXPIRATION_DATE
  FROM WF_LOCAL_USER_ROLES    WLUR
  JOIN FND_USER               FU   ON FU.USER_NAME    = WLUR.USER_NAME
  JOIN HR.PER_ALL_PEOPLE_F    PAPF ON PAPF.PERSON_ID  = FU.EMPLOYEE_ID
   AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE
                          AND NVL(PAPF.EFFECTIVE_END_DATE, SYSDATE)
 WHERE WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA0380%'   -- ← Changer 0380 si besoin
 ORDER BY WLUR.START_DATE DESC;


-- =====================================================================
-- [3] AFFECTATIONS RH D'UN UTILISATEUR (historique des sites)
--     → Permet de confirmer la date réelle de départ d'un site
-- =====================================================================
SELECT PAPF.FULL_NAME,
       PAA.ASSIGNMENT_NUMBER,
       TO_CHAR(PAA.EFFECTIVE_START_DATE, 'DD/MM/YYYY') AS DEBUT,
       TO_CHAR(PAA.EFFECTIVE_END_DATE,   'DD/MM/YYYY') AS FIN,
       HOU.NAME         AS ORGANISATION,
       HOU.ATTRIBUTE10  AS DIVISION,
       PAA.ASSIGNMENT_STATUS_TYPE_ID                   AS STATUT
  FROM HR.PER_ALL_PEOPLE_F      PAPF
  JOIN HR.PER_ALL_ASSIGNMENTS_F PAA ON PAA.PERSON_ID       = PAPF.PERSON_ID
  JOIN HR_ALL_ORGANIZATION_UNITS HOU ON HOU.ORGANIZATION_ID = PAA.ORGANIZATION_ID
  JOIN FND_USER                  FU  ON FU.EMPLOYEE_ID      = PAPF.PERSON_ID
 WHERE FU.USER_NAME = '69942D'   -- ← Matricule à adapter
 ORDER BY PAA.EFFECTIVE_START_DATE DESC;


-- =====================================================================
-- [4] RESPONSABILITÉS ORACLE D'UN UTILISATEUR SUR UN SITE
--     → Vérifie si END_DATE est renseignée (révocation formelle)
-- =====================================================================
SELECT FR.RESPONSIBILITY_KEY,
       TO_CHAR(FURG.START_DATE, 'DD/MM/YYYY') AS DEBUT,
       TO_CHAR(FURG.END_DATE,   'DD/MM/YYYY') AS FIN
  FROM FND_USER                   FU
  JOIN FND_USER_RESP_GROUPS_ALL   FURG ON FURG.USER_ID               = FU.USER_ID
  JOIN FND_RESPONSIBILITY         FR   ON FR.RESPONSIBILITY_ID        = FURG.RESPONSIBILITY_ID
                                      AND FR.APPLICATION_ID           = FURG.RESPONSIBILITY_APPLICATION_ID
 WHERE FU.USER_NAME = '69942D'         -- ← Matricule à adapter
   AND FR.RESPONSIBILITY_KEY LIKE 'DNA0380%'   -- ← Site à adapter
 ORDER BY FURG.START_DATE DESC;


-- =====================================================================
-- [5] SUPÉRIEUR HIÉRARCHIQUE DKA D'UN UTILISATEUR
--     → Requête extraite du package DKA_SAPWFCSP_PKG (get_superieur_hierachique)
--     → Champ ASS_ATTRIBUTE3 = ID du supérieur DKA (≠ SUPERVISOR_ID Oracle standard)
-- =====================================================================
SELECT fu_superieur.user_name          AS SUPERIEUR_USERNAME,
       sup_person.full_name            AS SUPERIEUR_NOM
  FROM per_all_people_f       pap
  JOIN per_all_assignments_f  paf         ON paf.person_id        = pap.person_id
  JOIN per_all_people_f       sup_person  ON sup_person.person_id = paf.ass_attribute3
  JOIN fnd_user               fu          ON fu.employee_id       = pap.person_id
  JOIN fnd_user               fu_superieur ON fu_superieur.employee_id = sup_person.person_id
 WHERE fu.user_name = '69747Y'              -- ← Matricule à adapter (ex: JORIS)
   AND SYSDATE BETWEEN pap.effective_start_date AND NVL(pap.effective_end_date, SYSDATE)
   AND SYSDATE BETWEEN paf.effective_start_date AND NVL(paf.effective_end_date, SYSDATE)
   AND SYSDATE BETWEEN sup_person.effective_start_date AND NVL(sup_person.effective_end_date, SYSDATE)
   AND ROWNUM = 1;


-- =====================================================================
-- [6] SEUIL DE DÉLÉGATION BAP D'UN UTILISATEUR
--     → Champ PER_JOBS.ATTRIBUTE1 utilisé par employe_droit_habilitation
-- =====================================================================
SELECT fu.user_name,
       papf.full_name,
       pj.name             AS JOB_NAME,
       pj.attribute1       AS SEUIL_DELEGATION_BAP
  FROM per_all_people_f      papf
  JOIN per_all_assignments_f paf  ON paf.person_id  = papf.person_id
  JOIN per_jobs              pj   ON pj.job_id       = paf.job_id
  JOIN fnd_user              fu   ON fu.employee_id  = papf.person_id
 WHERE fu.user_name = '69747Y'   -- ← Matricule à adapter
   AND SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date, SYSDATE)
   AND SYSDATE BETWEEN paf.effective_start_date  AND NVL(paf.effective_end_date,  SYSDATE);


-- =====================================================================
-- [7] HISTORIQUE WF D'UN ITEM (chronologie des activités)
--     → Reconstituer le flux exact d'une facture en litige
-- =====================================================================
SELECT TO_CHAR(WIAS.BEGIN_DATE, 'DD/MM/YYYY HH24:MI') AS DATE_ACTIVITE,
       WPA.DISPLAY_NAME                                AS ACTIVITE,
       WIAS.ASSIGNED_USER                              AS UTILISATEUR,
       WIAS.ACTIVITY_RESULT_CODE                       AS RESULTAT,
       WIAS.NOTIFICATION_ID                            AS NID
  FROM WF_ITEM_ACTIVITY_STATUSES  WIAS
  JOIN WF_PROCESS_ACTIVITIES      WPA  ON WPA.INSTANCE_ID   = WIAS.PROCESS_ACTIVITY
 WHERE WIAS.ITEM_TYPE = 'DKA_CSP'
   AND WIAS.ITEM_KEY  = '11307004_8639749'   -- ← Item key à adapter
 ORDER BY WIAS.BEGIN_DATE;


-- =====================================================================
-- [8] ATTRIBUTS WF D'UN ITEM (état courant : VALIDEUR_BAP, FORWARD_TO, etc.)
-- =====================================================================
SELECT WIAV.NAME   AS ATTRIBUT,
       WIAV.TEXT_VALUE,
       WIAV.NUMBER_VALUE,
       TO_CHAR(WIAV.DATE_VALUE, 'DD/MM/YYYY') AS DATE_VALUE
  FROM WF_ITEM_ATTRIBUTE_VALUES WIAV
 WHERE WIAV.ITEM_TYPE = 'DKA_CSP'
   AND WIAV.ITEM_KEY  = '11307004_8639749'   -- ← Item key à adapter
   AND WIAV.NAME IN (
       'VALIDEUR_BAP',
       'FORWARD_TO_USERNAME_RESPONSE',
       'DKA_COMMENTS',
       'RESPONDER_USER_ID',
       'INVOICE_ID',
       'DKA_INVOICE_AMOUNT'
   )
 ORDER BY WIAV.NAME;


-- =====================================================================
-- [9] DIAGNOSTIC GLOBAL : tous les sites avec anciens exploitants
--     sans rôle expiré (doublons actifs sur même rôle DNA%)
-- =====================================================================
SELECT WLUR.USER_NAME,
       PAPF.FULL_NAME,
       WLUR.ROLE_NAME,
       TO_CHAR(WLUR.START_DATE,      'DD/MM/YYYY') AS START_DATE,
       TO_CHAR(WLUR.EXPIRATION_DATE, 'DD/MM/YYYY') AS EXPIRATION_DATE,
       (SELECT COUNT(1)
          FROM WF_LOCAL_USER_ROLES W2
         WHERE W2.USER_NAME  != WLUR.USER_NAME
           AND W2.ROLE_NAME   = WLUR.ROLE_NAME
           AND (W2.EXPIRATION_DATE IS NULL OR W2.EXPIRATION_DATE > SYSDATE)
       ) AS NB_AUTRES_ACTIFS_MEME_ROLE
  FROM WF_LOCAL_USER_ROLES  WLUR
  JOIN FND_USER              FU   ON FU.USER_NAME   = WLUR.USER_NAME
  JOIN HR.PER_ALL_PEOPLE_F   PAPF ON PAPF.PERSON_ID = FU.EMPLOYEE_ID
   AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
 WHERE (   WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA%_IP_GEST_DA_RECEPTION|STANDARD'
        OR WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA%_GESTION_RECEPTIONS|STANDARD'
       )
 ORDER BY WLUR.ROLE_NAME, WLUR.EXPIRATION_DATE NULLS LAST;


-- =====================================================================
-- [10] CORRECTIF P1 : Expirer les 5 rôles WF sans expiration sur DNA0380
--      ⚠️ EXÉCUTER UNIQUEMENT APRÈS VALIDATION DBA
-- =====================================================================

-- Vérification avant exécution
SELECT USER_NAME,
       TO_CHAR(START_DATE,      'DD/MM/YYYY') AS START_DATE,
       TO_CHAR(EXPIRATION_DATE, 'DD/MM/YYYY') AS EXPIRATION_DATE
  FROM WF_LOCAL_USER_ROLES
 WHERE ROLE_NAME        = 'FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD'
   AND EXPIRATION_DATE IS NULL;
-- Résultat attendu : 5 lignes (69942D, 69762S, 69924E, 69260F, 70073B)

-- Correction WF_LOCAL_USER_ROLES
-- UPDATE WF_LOCAL_USER_ROLES
--    SET EXPIRATION_DATE = TRUNC(SYSDATE)
--  WHERE ROLE_NAME        = 'FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD'
--    AND EXPIRATION_DATE IS NULL;
-- COMMIT;

-- Correction FND_USER_RESP_GROUPS_ALL (responsabilités Oracle)
-- UPDATE FND_USER_RESP_GROUPS_ALL FURG
--    SET FURG.END_DATE = TRUNC(SYSDATE)
--  WHERE FURG.RESPONSIBILITY_ID = (
--         SELECT RESPONSIBILITY_ID FROM FND_RESPONSIBILITY
--          WHERE RESPONSIBILITY_KEY = 'DNA0380_IP_GEST_DA_RECEPTION')
--    AND FURG.USER_ID IN (
--         SELECT USER_ID FROM FND_USER
--          WHERE USER_NAME IN ('69942D','69762S','69924E','69260F','70073B'))
--    AND (FURG.END_DATE IS NULL OR FURG.END_DATE > SYSDATE);
-- COMMIT;
