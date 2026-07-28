-- =====================================================================
-- Correction ATTRIBUTE13 GL_JE_LINES - MAIN D'ŒUVRE HORS THO
-- =====================================================================
-- Date de création : 30/04/2026
-- Auteur           : S. Chibout
-- Base de données  : Oracle EBS 12.2.13 - Production
--
-- PROBLÈME RÉSOLU :
--   Le champ ATTRIBUTE13 contient "MAIN D'?UVRE HORS THO" à cause
--   d'un problème d'encodage du caractère œ (U+0152).
--   La valeur correcte est "MAIN D'ŒUVRE HORS THO".
--
-- PÉRIMÈTRE : 28 lignes GL_JE_LINES concernées
-- SOURCE    : Export DONNEES A METTRE A JOUR DANS GL_JE_LINES.xlsx (30/04/2026)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- =====================================================================
-- INITIALISATION DU CONTEXTE ORACLE EBS
-- =====================================================================
-- Adapter USER_NAME et RESPONSIBILITY_KEY avant exécution
-- Application ID : 101 = General Ledger (SQLGL)
-- =====================================================================

DECLARE
    v_user_id      NUMBER := 36313;   -- USER_ID
    v_resp_id      NUMBER := 51214;   -- RESPONSIBILITY_ID GL
    v_resp_appl_id NUMBER := 50001;   -- Application ID : General Ledger (SQLGL)
    v_org_id       NUMBER := 86;      -- DEW0001 - Adapter si nécessaire
    v_nb_updated   NUMBER := 0;
BEGIN
    -- 1. Définir le contexte de l'organisation
    MO_GLOBAL.SET_POLICY_CONTEXT('S', v_org_id);

    -- 2. Initialiser le contexte applicatif
    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => v_user_id,
        resp_id      => v_resp_id,
        resp_appl_id => v_resp_appl_id
    );

    -- 3. Mise à jour ATTRIBUTE13 : lignes ciblées par JE_HEADER_ID + JE_LINE_NUM
    --    Source : Export DONNEES A METTRE A JOUR DANS GL_JE_LINES.xlsx (30/04/2026)
    UPDATE GL.GL_JE_LINES
    SET
        ATTRIBUTE13       = 'MAIN D''ŒUVRE HORS THO',
        LAST_UPDATE_DATE  = SYSDATE,
        LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,
        LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
    WHERE (JE_HEADER_ID, JE_LINE_NUM) IN ((22975525,24),(22975525,25),(22975525,26),(22975525,27),(22975525,28),(22975525,29),
(22975525,30),(22975525,31),(22975525,32),(22975525,33),(22975525,34),(22975525,35),(22975525,36),(22975525,37),
(22975525,38),(22975525,39),(22975525,40),(22975525,41),(22975525,42),(22975525,43),(22975525,44),(22975525,45),
(22975525,46),(22975526,2),(22975527,2),(22975528,2),(22975529,2),(22975530,2),(22975531,2) );

    v_nb_updated := SQL%ROWCOUNT;

    -- 4. Afficher le résultat
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('Correction ATTRIBUTE13 GL_JE_LINES');
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('Lignes mises à jour : ' || v_nb_updated);
    DBMS_OUTPUT.PUT_LINE('Valeur corrigée     : MAIN D''ŒUVRE HORS THO');
    DBMS_OUTPUT.PUT_LINE('USER_ID appliqué    : ' || FND_GLOBAL.USER_ID);
    DBMS_OUTPUT.PUT_LINE('Date mise à jour    : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=================================================');

    IF v_nb_updated = 28 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT effectué - 28 lignes corrigées.');
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK : ' || v_nb_updated || ' ligne(s) affectée(s) au lieu de 28 attendues.');
        DBMS_OUTPUT.PUT_LINE('Vérifier le périmètre des données avant de relancer.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('=================================================');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        ROLLBACK;
END;
/
