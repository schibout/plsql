-- =====================================================================
-- Suppression des doublons Open Interface AR - bloc d'execution
-- =====================================================================
-- Base de donnees : Oracle EBS 12.2.13
-- Appele par      : Suppression_Doublons.ps1 (ne pas lancer seul, les
--                   parametres et le SPOOL sont poses par le PowerShell)
--
-- TABLES IMPACTEES, dans l'ordre de suppression :
--   1. RA_INTERFACE_SALESCREDITS_ALL   (enfant des lignes)
--   2. RA_INTERFACE_DISTRIBUTIONS_ALL  (enfant des lignes)
--   3. RA_INTERFACE_ERRORS_ALL         (erreurs des lignes visees)
--   4. RA_INTERFACE_LINES_ALL          (table principale)
--
-- CE QUI RELIE CE SCRIPT AU RAPPORT :
--   Le rapport a compte les lignes visees et somme leurs identifiants.
--   Ce bloc recalcule les deux valeurs avant de toucher a quoi que ce
--   soit et s'arrete si elles different : on ne supprime jamais un
--   perimetre autre que celui qui a ete relu et valide. Sans ce
--   controle, une ligne arrivee en interface entre le rapport et la
--   purge serait supprimee sans avoir jamais ete montree.
--
-- PARAMETRES attendus (DEFINE poses par le PowerShell) :
--   P_MODE          SIMULATION (rollback) ou EXECUTION (commit)
--   P_MOTIF         motif LIKE du message d'erreur
--   P_ORG_ID        0 = toutes les organisations
--   P_MAX_LIGNES    plafond de securite
--   P_NB_ATTENDU    nombre de lignes vues par le rapport
--   P_SOMME_IDS     somme des interface_line_id vus par le rapport
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 0
SET HEADING OFF

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ';

DECLARE
    c_mode        CONSTANT VARCHAR2(20)  := UPPER('&&P_MODE');
    c_motif       CONSTANT VARCHAR2(200) := UPPER('&&P_MOTIF');
    c_org         CONSTANT NUMBER := &&P_ORG_ID;
    c_max         CONSTANT NUMBER := &&P_MAX_LIGNES;
    c_nb_attendu  CONSTANT NUMBER := &&P_NB_ATTENDU;
    c_somme_att   CONSTANT NUMBER := &&P_SOMME_IDS;

    TYPE t_id_list IS TABLE OF ar.ra_interface_lines_all.interface_line_id%TYPE;
    l_ids t_id_list;

    l_somme            NUMBER := 0;
    l_nb_salescredits  NUMBER := 0;
    l_nb_distributions NUMBER := 0;
    l_nb_errors        NUMBER := 0;
    l_nb_lines         NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('SUPPRESSION DOUBLONS OPEN INTERFACE AR - MODE ' || c_mode);
    DBMS_OUTPUT.PUT_LINE('Motif   : ' || c_motif);
    DBMS_OUTPUT.PUT_LINE('Org     : ' || CASE WHEN c_org = 0 THEN 'TOUTES' ELSE TO_CHAR(c_org) END);
    DBMS_OUTPUT.PUT_LINE('=====================================================');

    IF c_mode NOT IN ('SIMULATION', 'EXECUTION') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'P_MODE doit valoir SIMULATION ou EXECUTION, recu : ' || c_mode);
    END IF;

    -- Collecte prealable des identifiants vises. Les identifiants sont
    -- releves AVANT toute suppression : c'est ce qui permet de supprimer
    -- les erreurs puis les lignes sans perdre la cible en route.
    SELECT DISTINCT ril.interface_line_id
    BULK COLLECT INTO l_ids
    FROM   ar.ra_interface_lines_all  ril
    JOIN   ar.ra_interface_errors_all rie
           ON rie.interface_line_id = ril.interface_line_id
    WHERE  UPPER(rie.message_text) LIKE c_motif
    AND    (c_org = 0 OR ril.org_id = c_org);

    DBMS_OUTPUT.PUT_LINE('Lignes d''interface identifiees : ' || l_ids.COUNT);

    IF l_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('##SUM##sc=0;dist=0;err=0;lig=0');
        DBMS_OUTPUT.PUT_LINE('Aucun enregistrement a supprimer : rien a faire.');
        RETURN;
    END IF;

    -- Garde-fou : un motif trop large ne doit pas pouvoir vider l'interface.
    IF l_ids.COUNT > c_max THEN
        RAISE_APPLICATION_ERROR(-20002,
            l_ids.COUNT || ' lignes visees, au-dela du plafond de ' || c_max || '. '
            || 'Verifier le motif et l''organisation, ou relever le plafond '
            || 'en connaissance de cause.');
    END IF;

    -- Concordance avec le rapport : meme nombre de lignes ET memes lignes.
    -- La somme des identifiants suffit a detecter une substitution, un
    -- ajout ou un retrait dans le perimetre depuis l'edition du rapport.
    FOR i IN 1 .. l_ids.COUNT LOOP
        l_somme := l_somme + l_ids(i);
    END LOOP;

    IF l_ids.COUNT <> c_nb_attendu OR l_somme <> c_somme_att THEN
        RAISE_APPLICATION_ERROR(-20004,
            'Le perimetre a change depuis l''edition du rapport : '
            || l_ids.COUNT || ' ligne(s) pour ' || c_nb_attendu || ' annoncee(s) '
            || '(controle ' || l_somme || ' contre ' || c_somme_att || '). '
            || 'Aucune suppression effectuee : relancer le rapport.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Perimetre conforme au rapport (' || c_nb_attendu || ' lignes).');

    -- Ordre impose par les dependances : enfants, puis erreurs, puis lignes.
    FORALL i IN 1 .. l_ids.COUNT
        DELETE FROM ar.ra_interface_salescredits_all
        WHERE interface_line_id = l_ids(i);
    l_nb_salescredits := SQL%ROWCOUNT;

    FORALL i IN 1 .. l_ids.COUNT
        DELETE FROM ar.ra_interface_distributions_all
        WHERE interface_line_id = l_ids(i);
    l_nb_distributions := SQL%ROWCOUNT;

    -- Toutes les erreurs de ces lignes, pas seulement celles du motif :
    -- la ligne disparait, ses erreurs n'ont plus lieu d'exister.
    FORALL i IN 1 .. l_ids.COUNT
        DELETE FROM ar.ra_interface_errors_all
        WHERE interface_line_id = l_ids(i);
    l_nb_errors := SQL%ROWCOUNT;

    FORALL i IN 1 .. l_ids.COUNT
        DELETE FROM ar.ra_interface_lines_all
        WHERE interface_line_id = l_ids(i);
    l_nb_lines := SQL%ROWCOUNT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('----------- BILAN -----------------------------------');
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_SALESCREDITS_ALL  : ' || LPAD(l_nb_salescredits, 8));
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_DISTRIBUTIONS_ALL : ' || LPAD(l_nb_distributions, 8));
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_ERRORS_ALL        : ' || LPAD(l_nb_errors, 8));
    DBMS_OUTPUT.PUT_LINE('RA_INTERFACE_LINES_ALL         : ' || LPAD(l_nb_lines, 8));
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('##SUM##sc=' || l_nb_salescredits
                         || ';dist=' || l_nb_distributions
                         || ';err='  || l_nb_errors
                         || ';lig='  || l_nb_lines);

    -- Controle de coherence : autant de lignes supprimees que d'identifiants
    -- collectes, sinon quelque chose a bouge entre-temps.
    IF l_nb_lines <> l_ids.COUNT THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003,
            l_nb_lines || ' ligne(s) supprimee(s) pour ' || l_ids.COUNT
            || ' attendue(s) : ROLLBACK complet, aucune modification conservee.');
    END IF;

    IF c_mode = 'EXECUTION' THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT effectue.');
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('SIMULATION : ROLLBACK effectue, aucune modification en base.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('##ERR##' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('ERREUR - ROLLBACK effectue : ' || SQLERRM);
        RAISE;
END;
/


-- ---------------------------------------------------------------------
-- Controle des orphelins. Recompter les erreurs du motif ne prouverait
-- rien : elles viennent d'etre supprimees. Ce qui compte, c'est
-- qu'aucun enfant ne soit reste sans ligne parente.
-- ---------------------------------------------------------------------
SELECT '##ORPH##Distributions sans ligne parente|' || COUNT(*)
FROM   ar.ra_interface_distributions_all d
WHERE  NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = d.interface_line_id)
UNION ALL
SELECT '##ORPH##Credits de vente sans ligne parente|' || COUNT(*)
FROM   ar.ra_interface_salescredits_all s
WHERE  NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = s.interface_line_id)
UNION ALL
SELECT '##ORPH##Erreurs sans ligne parente|' || COUNT(*)
FROM   ar.ra_interface_errors_all e
WHERE  e.interface_line_id IS NOT NULL
AND    NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = e.interface_line_id);
