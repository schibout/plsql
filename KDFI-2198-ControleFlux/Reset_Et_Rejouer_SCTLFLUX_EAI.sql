-- =====================================================================
-- Reset_Et_Rejouer_SCTLFLUX_EAI.sql
-- =====================================================================
-- Date de création : 03/04/2026
-- Auteur           : GitHub Copilot / KDFI-2198
-- Objet            : Annuler un run de DKA_SCTLFLUX_EAI pour pouvoir
--                    le rejouer (tests, corrections de bug, reprise).
--
-- UTILISATION :
--   1. Renseigner les variables ci-dessous
--   2. Exécuter en SQLPLUS ou SQLcl (connexion APPS)
--   3. Vérifier les comptages dans la section DIAGNOSTIC
--   4. Relancer DKA_SCTLFLUX_EAI en mode reprise si nécessaire :
--        Argument3 (DATE_REPRISE_DE) = date debut du run d'origine
--        Argument4 (DATE_REPRISE_A)  = date fin   du run d'origine
--
-- TABLES IMPACTÉES :
--   - APPS.DKA_SCTLFLUX_EAI           (résultats contrôle de flux)
--   - APPS.DKA_SCTLFLUX_ARFLAG_EAI    (flags traitement AR)
--   - AR.RA_CUSTOMER_TRX_LINES_ALL    (ATTRIBUTE8 = flag traitement)
--   - AR.RA_INTERFACE_LINES_ALL       (ATTRIBUTE8 = flag traitement)
--   - AP.AP_INVOICES_ALL              (ATTRIBUTE7 = flag traitement)
--   - AP.AP_INVOICES_INTERFACE        (ATTRIBUTE7 = flag traitement)
--   - GL.GL_JE_LINES                  (ATTRIBUTE5 = flag traitement)
--   - GL.GL_INTERFACE                 (ATTRIBUTE5 = flag traitement)
-- =====================================================================

-- =====================================================================
-- PARAMETRES A RENSEIGNER
-- =====================================================================

-- N° du concurrent request à annuler (colonne N_TRAITEMENT dans DKA_SCTLFLUX_EAI)
DEFINE v_n_traitement = 47570152

-- Folio à traiter (laisser vide '' pour tous les folios du run)
-- Exemples : 'GCA', 'SVD', '' (= tous)
DEFINE v_folio = ''

-- Optionnel : renommer le fichier sur les données sources IARPAFAC
-- (utile pour tester sans altérer les données de production)
-- Laisser v_ancien_fichier = '' pour ne pas renommer
DEFINE v_ancien_fichier = ''
DEFINE v_nouveau_fichier = ''

-- =====================================================================
-- SECTION 1 : DIAGNOSTIC AVANT RESET (vérification)
-- =====================================================================

PROMPT ============================================================
PROMPT DIAGNOSTIC - Donnees du run &&v_n_traitement
PROMPT ============================================================

PROMPT --- DKA_SCTLFLUX_EAI ---
SELECT CODE_FOLIO, DATE_EXEC, NB_PIECE,
       ROUND(DEBIT,2) DEBIT, ROUND(CREDIT,2) CREDIT,
       SUBSTR(FICHIER,1,60) FICHIER, TRAITE
FROM APPS.DKA_SCTLFLUX_EAI
WHERE N_TRAITEMENT = &&v_n_traitement
  AND (CODE_FOLIO = DECODE('&&v_folio','',CODE_FOLIO,'&&v_folio'))
ORDER BY CODE_FOLIO;

PROMPT --- Flags positionnes par ce run ---
SELECT 'RA_CUSTOMER_TRX_LINES_ALL (ATTRIBUTE8)' SRC, COUNT(*) NB_LIGNES
FROM AR.RA_CUSTOMER_TRX_LINES_ALL WHERE ATTRIBUTE8 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'RA_INTERFACE_LINES_ALL (ATTRIBUTE8)', COUNT(*) FROM AR.RA_INTERFACE_LINES_ALL WHERE ATTRIBUTE8 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'AP_INVOICES_ALL (ATTRIBUTE7)', COUNT(*) FROM AP.AP_INVOICES_ALL WHERE ATTRIBUTE7 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'AP_INVOICES_INTERFACE (ATTRIBUTE7)', COUNT(*) FROM AP.AP_INVOICES_INTERFACE WHERE ATTRIBUTE7 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'GL_JE_LINES (ATTRIBUTE5)', COUNT(*) FROM GL.GL_JE_LINES WHERE ATTRIBUTE5 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'GL_INTERFACE (ATTRIBUTE5)', COUNT(*) FROM GL.GL_INTERFACE WHERE ATTRIBUTE5 = TO_CHAR(&&v_n_traitement)
UNION ALL
SELECT 'DKA_SCTLFLUX_ARFLAG_EAI', COUNT(*) FROM APPS.DKA_SCTLFLUX_ARFLAG_EAI WHERE REQUEST_ID = &&v_n_traitement;

-- =====================================================================
-- SECTION 2 : RESET DES RESULTATS (DKA_SCTLFLUX_EAI)
-- =====================================================================

PROMPT ============================================================
PROMPT RESET 1/6 : Suppression dans DKA_SCTLFLUX_EAI
PROMPT ============================================================

DELETE FROM APPS.DKA_SCTLFLUX_EAI
WHERE N_TRAITEMENT = &&v_n_traitement
  AND (CODE_FOLIO = DECODE('&&v_folio','',CODE_FOLIO,'&&v_folio'));

PROMPT Lignes supprimees dans DKA_SCTLFLUX_EAI : &SQL.ROWCOUNT

-- =====================================================================
-- SECTION 3 : RESET DES FLAGS AR (DKA_SCTLFLUX_ARFLAG_EAI)
-- =====================================================================

PROMPT ============================================================
PROMPT RESET 2/6 : Suppression dans DKA_SCTLFLUX_ARFLAG_EAI
PROMPT ============================================================

DELETE FROM APPS.DKA_SCTLFLUX_ARFLAG_EAI
WHERE REQUEST_ID = &&v_n_traitement
  AND (ORIGIN = DECODE('&&v_folio','',ORIGIN,'&&v_folio'));

PROMPT Lignes supprimees dans DKA_SCTLFLUX_ARFLAG_EAI : &SQL.ROWCOUNT

-- =====================================================================
-- SECTION 4 : RESET DES FLAGS AR SOURCES
-- =====================================================================

PROMPT ============================================================
PROMPT RESET 3/6 : Reset ATTRIBUTE8 dans RA_CUSTOMER_TRX_LINES_ALL
PROMPT ============================================================

UPDATE AR.RA_CUSTOMER_TRX_LINES_ALL
SET ATTRIBUTE8 = NULL
WHERE ATTRIBUTE8 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans RA_CUSTOMER_TRX_LINES_ALL : &SQL.ROWCOUNT

PROMPT ============================================================
PROMPT RESET 4/6 : Reset ATTRIBUTE8 dans RA_INTERFACE_LINES_ALL
PROMPT ============================================================

UPDATE AR.RA_INTERFACE_LINES_ALL
SET ATTRIBUTE8 = NULL
WHERE ATTRIBUTE8 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans RA_INTERFACE_LINES_ALL : &SQL.ROWCOUNT

-- =====================================================================
-- SECTION 5 : RESET DES FLAGS AP SOURCES
-- =====================================================================

PROMPT ============================================================
PROMPT RESET 5/6 : Reset ATTRIBUTE7 dans AP_INVOICES_ALL et AP_INVOICES_INTERFACE
PROMPT ============================================================

UPDATE AP.AP_INVOICES_ALL
SET ATTRIBUTE7 = NULL
WHERE ATTRIBUTE7 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans AP_INVOICES_ALL : &SQL.ROWCOUNT

UPDATE AP.AP_INVOICES_INTERFACE
SET ATTRIBUTE7 = NULL
WHERE ATTRIBUTE7 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans AP_INVOICES_INTERFACE : &SQL.ROWCOUNT

-- =====================================================================
-- SECTION 6 : RESET DES FLAGS GL SOURCES
-- =====================================================================

PROMPT ============================================================
PROMPT RESET 6/6 : Reset ATTRIBUTE5 dans GL_JE_LINES et GL_INTERFACE
PROMPT ============================================================

UPDATE GL.GL_JE_LINES
SET ATTRIBUTE5 = NULL
WHERE ATTRIBUTE5 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans GL_JE_LINES : &SQL.ROWCOUNT

UPDATE GL.GL_INTERFACE
SET ATTRIBUTE5 = NULL
WHERE ATTRIBUTE5 = TO_CHAR(&&v_n_traitement)
  AND (ATTRIBUTE9 = DECODE('&&v_folio','',ATTRIBUTE9,'&&v_folio'));

PROMPT Lignes resetees dans GL_INTERFACE : &SQL.ROWCOUNT

-- =====================================================================
-- SECTION 7 (OPTIONNEL) : RENOMMAGE DU FICHIER DANS IARPAFAC
--   Permet de rejouer en simulant un nouveau nom de fichier
--   pour éviter les contrôles de doublon dans DKA_SCTLFLUX_ARFLAG_EAI
-- =====================================================================

PROMPT ============================================================
PROMPT RENOMMAGE optionnel du FIC_IDENT dans DKA_IARPAFAC_INTERFACE
PROMPT ============================================================

BEGIN
  IF '&&v_ancien_fichier' IS NOT NULL AND '&&v_nouveau_fichier' IS NOT NULL THEN

    UPDATE APPS.DKA_IARPAFAC_INTERFACE
    SET FIC_IDENT = '&&v_nouveau_fichier'
    WHERE FIC_IDENT = '&&v_ancien_fichier'
      AND (ORIGIN = DECODE('&&v_folio','',ORIGIN,'&&v_folio'));
    DBMS_OUTPUT.PUT_LINE('Renommage IARPAFAC : '|| SQL%ROWCOUNT ||' lignes.');

    -- Reset du statut OA_STATUS pour pouvoir rejouer
    UPDATE APPS.DKA_IARPAFAC_INTERFACE
    SET OA_STATUS = NULL
    WHERE FIC_IDENT = '&&v_nouveau_fichier'
      AND (ORIGIN = DECODE('&&v_folio','',ORIGIN,'&&v_folio'));
    DBMS_OUTPUT.PUT_LINE('Reset OA_STATUS : '|| SQL%ROWCOUNT ||' lignes.');

  ELSE
    DBMS_OUTPUT.PUT_LINE('Renommage non demande (v_ancien_fichier vide) - ignore.');
  END IF;
END;
/

-- =====================================================================
-- COMMIT FINAL
-- =====================================================================

COMMIT;

PROMPT ============================================================
PROMPT RESET TERMINE AVEC SUCCES - Run &&v_n_traitement reinitialise
PROMPT
PROMPT Pour rejouer le programme concurrent, utiliser :
PROMPT   DKA_SCTLFLUX_EAI en mode reprise
PROMPT   Argument3 (DATE_REPRISE_DE) = date debut extraction d origine
PROMPT   Argument4 (DATE_REPRISE_A)  = date fin   extraction d origine
PROMPT ============================================================
