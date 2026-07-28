-- =====================================================================
-- Vérification de l'état d'un utilisateur Oracle EBS
-- =====================================================================
-- Date de création : 20/03/2026
-- Paramètre        : :NOM_PERSONNE  (ex: 'Dupont%' ou '%Marie%')
--
-- Contrôles effectués :
--   1. Existence et état du compte FND_USER (actif, GUID, dates)
--   2. Responsabilités actives affectées à l'utilisateur
-- =====================================================================

-- -------------------------------------------------------
-- 1. Informations du compte utilisateur
-- -------------------------------------------------------
SELECT
    fu.USER_ID,
    fu.USER_NAME,
    fu.DESCRIPTION,
    fu.EMAIL_ADDRESS,
    fu.START_DATE,
    fu.END_DATE,
    CASE
        WHEN fu.END_DATE IS NULL OR fu.END_DATE > SYSDATE THEN 'ACTIF'
        ELSE 'INACTIF'
    END AS STATUT_COMPTE,
    CASE
        WHEN fu.USER_GUID IS NOT NULL THEN 'OK - GUID alimenté'
        ELSE '*** MANQUANT - GUID non alimenté ***'
    END AS STATUT_GUID,
    fu.USER_GUID,
    fu.LAST_LOGON_DATE,
    fu.PASSWORD_DATE,
    fu.CREATION_DATE,
    fu.LAST_UPDATE_DATE
FROM APPLSYS.FND_USER fu
WHERE UPPER(fu.DESCRIPTION) LIKE UPPER(:NOM_PERSONNE)
ORDER BY fu.USER_NAME;


-- -------------------------------------------------------
-- 2. Responsabilités actives affectées à l'utilisateur
-- -------------------------------------------------------
SELECT
    fu.USER_NAME,
    fu.DESCRIPTION AS NOM_PERSONNE,
    fr.RESPONSIBILITY_NAME,
    fa.APPLICATION_SHORT_NAME,
    fur.START_DATE,
    fur.END_DATE,
    CASE
        WHEN fur.END_DATE IS NULL OR fur.END_DATE > SYSDATE THEN 'ACTIVE'
        ELSE 'EXPIREE'
    END AS STATUT_RESPONSABILITE,
    fr.RESPONSIBILITY_KEY
FROM APPLSYS.FND_USER fu
JOIN APPLSYS.FND_USER_RESP_GROUPS_DIRECT fur
    ON fur.USER_ID = fu.USER_ID
JOIN APPLSYS.FND_RESPONSIBILITY_VL fr
    ON fr.RESPONSIBILITY_ID    = fur.RESPONSIBILITY_ID
    AND fr.APPLICATION_ID      = fur.RESPONSIBILITY_APPLICATION_ID
JOIN APPLSYS.FND_APPLICATION fa
    ON fa.APPLICATION_ID = fr.APPLICATION_ID
WHERE UPPER(fu.DESCRIPTION) LIKE UPPER(:NOM_PERSONNE)
  AND (fur.END_DATE IS NULL OR fur.END_DATE > SYSDATE)
ORDER BY fu.USER_NAME, fr.RESPONSIBILITY_NAME;
