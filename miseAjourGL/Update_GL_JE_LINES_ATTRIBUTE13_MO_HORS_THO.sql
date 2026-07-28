-- =====================================================================
-- Correction d'un attribut de GL_JE_LINES sur un lot de lignes
-- =====================================================================
-- Base de donnees : Oracle EBS 12.2.13 - Production
--
-- OBJET :
--   Corriger la valeur d'une colonne ATTRIBUTEn de GL.GL_JE_LINES pour
--   une liste de couples (JE_HEADER_ID, JE_LINE_NUM). Cas d'origine :
--   ATTRIBUTE13 contenant "MAIN D'?UVRE HORS THO" au lieu de
--   "MAIN D'OEUVRE HORS THO", suite a un probleme d'encodage du
--   caractere oe ligature (U+0152).
--
-- ---------------------------------------------------------------------
-- POURQUOI UNISTR
-- ---------------------------------------------------------------------
--   La version precedente ecrivait le caractere U+0152 en clair dans ce
--   fichier. Lu par SQL*Plus avec un NLS_LANG en WE8MSWIN1252 -- le cas
--   le plus courant -- ses deux octets UTF-8 sont interpretes comme deux
--   caracteres distincts : le script cense corriger un probleme
--   d'encodage le reproduisait a l'identique.
--   La valeur est desormais transmise en notation UNISTR (\0152), donc
--   decrite par son point de code et independante de l'encodage du
--   fichier comme de la configuration du poste.
--
-- ---------------------------------------------------------------------
-- SIMULATION PAR DEFAUT
-- ---------------------------------------------------------------------
--   Tel quel, ce script execute l'UPDATE puis fait un ROLLBACK. Il
--   affiche l'ancienne et la nouvelle valeur de chaque ligne, signale
--   les couples introuvables, et ne conserve rien.
--
-- Ce fichier n'est pas destine a etre lance seul : Update_GL_JE_LINES.ps1
-- y injecte la liste des lignes issue du CSV et positionne les DEFINE.
--
-- Sortie balisee, consommee par le lanceur :
--   ##OLD##header|ligne|ancienne_valeur_ascii
--   ##ABSENT##header|ligne
--   ##SUM##attendu=n;maj=n;absent=n
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET DEFINE ON

DECLARE
    c_mode      CONSTANT VARCHAR2(20) := UPPER('&&P_MODE');
    c_user_id   CONSTANT NUMBER := &&P_USER_ID;
    c_resp_id   CONSTANT NUMBER := &&P_RESP_ID;
    c_resp_appl CONSTANT NUMBER := &&P_RESP_APPL_ID;
    c_org_id    CONSTANT NUMBER := &&P_ORG_ID;

    -- Valeur cible, injectee par le lanceur en notation UNISTR.
    -- @@VALEUR@@

    TYPE t_num IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_hdr  t_num;
    l_lin  t_num;

    l_old        VARCHAR2(4000);
    l_nb_maj     NUMBER := 0;
    l_nb_absent  NUMBER := 0;
    l_nb_deja    NUMBER := 0;
BEGIN
    -- =================================================================
    -- 1. Liste des lignes a corriger (injectee depuis le CSV)
    -- =================================================================
    -- @@LISTE_LIGNES@@

    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('Correction &&P_ATTRIBUT de GL_JE_LINES - MODE ' || c_mode);
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('Lignes demandees : ' || l_hdr.COUNT);

    IF c_mode NOT IN ('SIMULATION', 'EXECUTION') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'P_MODE doit valoir SIMULATION ou EXECUTION, recu : ' || c_mode);
    END IF;

    IF l_hdr.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucune ligne a traiter.');
        RETURN;
    END IF;

    -- =================================================================
    -- 2. Contexte applicatif
    -- =================================================================
    -- GL_JE_LINES n'est pas une table multi-organisation : le contexte MO
    -- n'est pose que si un ORG_ID a ete fourni explicitement.
    IF c_org_id > 0 THEN
        MO_GLOBAL.SET_POLICY_CONTEXT('S', c_org_id);
        DBMS_OUTPUT.PUT_LINE('Contexte MO : org_id=' || c_org_id);
    END IF;

    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => c_user_id,
        resp_id      => c_resp_id,
        resp_appl_id => c_resp_appl);
    DBMS_OUTPUT.PUT_LINE('APPS_INITIALIZE OK - user_id=' || c_user_id
                         || ' resp_id=' || c_resp_id || ' appl_id=' || c_resp_appl);
    DBMS_OUTPUT.PUT_LINE('');

    -- =================================================================
    -- 3. Releve des valeurs actuelles, avant toute ecriture
    -- =================================================================
    -- ASCIISTR echappe les caracteres non-ASCII en \XXXX : la valeur
    -- d'origine traverse ainsi le log et le fichier d'annulation sans
    -- dependre d'un quelconque encodage.
    FOR i IN 1 .. l_hdr.COUNT LOOP
        BEGIN
            SELECT &&P_ATTRIBUT INTO l_old
              FROM gl.gl_je_lines
             WHERE je_header_id = l_hdr(i)
               AND je_line_num  = l_lin(i);

            DBMS_OUTPUT.PUT_LINE('##OLD##' || l_hdr(i) || '|' || l_lin(i)
                                 || '|' || ASCIISTR(l_old));

            IF l_old = c_valeur THEN l_nb_deja := l_nb_deja + 1; END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_nb_absent := l_nb_absent + 1;
                DBMS_OUTPUT.PUT_LINE('##ABSENT##' || l_hdr(i) || '|' || l_lin(i));
            WHEN TOO_MANY_ROWS THEN
                RAISE_APPLICATION_ERROR(-20002,
                    'Plusieurs lignes pour (' || l_hdr(i) || ',' || l_lin(i)
                    || ') : le couple (JE_HEADER_ID, JE_LINE_NUM) devrait etre unique.');
        END;
    END LOOP;

    -- =================================================================
    -- 4. Mise a jour
    -- =================================================================
    FORALL i IN 1 .. l_hdr.COUNT
        UPDATE gl.gl_je_lines
           SET &&P_ATTRIBUT     = c_valeur,
               last_update_date  = SYSDATE,
               last_updated_by   = FND_GLOBAL.USER_ID,
               last_update_login = FND_GLOBAL.LOGIN_ID
         WHERE je_header_id = l_hdr(i)
           AND je_line_num  = l_lin(i);

    l_nb_maj := SQL%ROWCOUNT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('----------- BILAN -------------------------------');
    DBMS_OUTPUT.PUT_LINE('Lignes demandees      : ' || l_hdr.COUNT);
    DBMS_OUTPUT.PUT_LINE('Lignes mises a jour   : ' || l_nb_maj);
    DBMS_OUTPUT.PUT_LINE('Couples introuvables  : ' || l_nb_absent);
    DBMS_OUTPUT.PUT_LINE('Deja a la bonne valeur: ' || l_nb_deja);
    DBMS_OUTPUT.PUT_LINE('Nouvelle valeur       : ' || c_valeur);
    DBMS_OUTPUT.PUT_LINE('Nouvelle valeur (ascii): ' || ASCIISTR(c_valeur));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');

    -- Le garde-fou compare au nombre de lignes reellement fournies. La
    -- version precedente le comparait a une constante 28 alors que la
    -- liste en comptait 29 : le ROLLBACK etait systematique.
    IF l_nb_absent > 0 THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK : ' || l_nb_absent
            || ' couple(s) introuvable(s). Corriger le fichier CSV avant de relancer.');
    ELSIF l_nb_maj <> l_hdr.COUNT THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK : ' || l_nb_maj || ' ligne(s) mise(s) a jour pour '
            || l_hdr.COUNT || ' attendue(s).');
    ELSIF c_mode = 'EXECUTION' THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT effectue : ' || l_nb_maj || ' ligne(s) corrigee(s).');
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('SIMULATION : ROLLBACK effectue, aucune modification en base.');
        DBMS_OUTPUT.PUT_LINE('Pour appliquer reellement, relancer avec -Executer.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('##SUM##attendu=' || l_hdr.COUNT
        || ';maj='    || l_nb_maj
        || ';absent=' || l_nb_absent
        || ';deja='   || l_nb_deja);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('##ERR##' || SUBSTR(SQLERRM, 1, 400));
        DBMS_OUTPUT.PUT_LINE('ERREUR - ROLLBACK effectue : ' || SQLERRM);
        -- RAISE indispensable : sans lui, l'exception etait avalee et
        -- SQL*Plus sortait en succes malgre l'echec.
        RAISE;
END;
/
