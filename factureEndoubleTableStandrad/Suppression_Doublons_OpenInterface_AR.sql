-- =====================================================================
-- Suppression des factures en doublon dans les tables Open Interface AR
-- =====================================================================
-- Base de donnees : Oracle EBS 12.2.13
-- Outil           : SQL*Plus / SQLcl
--
-- OBJET :
--   Purger les enregistrements bloques en Open Interface AR portant
--   l'erreur "numero de facture en double" dans RA_INTERFACE_ERRORS_ALL.
--
-- TABLES IMPACTEES, dans l'ordre de suppression reellement applique :
--   1. RA_INTERFACE_SALESCREDITS_ALL   (enfant des lignes)
--   2. RA_INTERFACE_DISTRIBUTIONS_ALL  (enfant des lignes)
--   3. RA_INTERFACE_ERRORS_ALL         (erreurs des lignes visees)
--   4. RA_INTERFACE_LINES_ALL          (table principale)
--
-- LIEN CLE :
--   RA_INTERFACE_ERRORS_ALL.INTERFACE_LINE_ID
--     -> RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ID
--
-- ---------------------------------------------------------------------
-- SIMULATION PAR DEFAUT
-- ---------------------------------------------------------------------
--   Tel quel, ce script execute les DELETE puis fait un ROLLBACK : il
--   affiche exactement ce qui serait supprime, valide les droits et le
--   ciblage des lignes, et ne conserve rien.
--   Pour appliquer reellement, passer P_MODE a EXECUTION ci-dessous.
--
-- PARAMETRES :
--   P_MODE        SIMULATION (rollback) ou EXECUTION (commit)
--   P_MOTIF       motif de recherche du message d'erreur, insensible a la
--                 casse. Le message est traduit par EBS : en session
--                 anglaise, utiliser '%duplicate invoice%'.
--   P_ORG_ID      0 = toutes les organisations, sinon l'ORG_ID a traiter.
--                 Les tables sont des _ALL : sans filtre, la purge porte
--                 sur toutes les entites juridiques a la fois.
--   P_MAX_LIGNES  garde-fou. Au-dela de ce nombre de lignes visees, le
--                 script refuse d'agir : un motif trop large ne doit pas
--                 pouvoir vider l'interface silencieusement.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 100

DEFINE P_MODE       = "SIMULATION"
DEFINE P_MOTIF      = "%facture en double%"
DEFINE P_ORG_ID     = "0"
DEFINE P_MAX_LIGNES = "5000"


-- =====================================================================
-- ETAPE 1 : DIAGNOSTIC - a lire avant toute suppression
-- =====================================================================

PROMPT
PROMPT === Parametres retenus ===

COLUMN MODE_EXEC FORMAT A12  HEADING "MODE"
COLUMN MOTIF     FORMAT A32  HEADING "MOTIF RECHERCHE"
COLUMN ORG       FORMAT A14  HEADING "ORG_ID"
COLUMN PLAFOND   FORMAT A10  HEADING "PLAFOND"

SELECT '&&P_MODE'                                                  AS MODE_EXEC,
       '&&P_MOTIF'                                                 AS MOTIF,
       CASE WHEN &&P_ORG_ID = 0 THEN 'TOUTES'
            ELSE TO_CHAR(&&P_ORG_ID) END                           AS ORG,
       TO_CHAR(&&P_MAX_LIGNES)                                     AS PLAFOND
FROM   DUAL;

CLEAR COLUMNS

PROMPT
PROMPT === Volumetrie par organisation et source ===

COLUMN ORG_ID     FORMAT 999999      HEADING "ORG_ID"
COLUMN SOURCE     FORMAT A30         HEADING "BATCH SOURCE"
COLUMN NB_LIGNES  FORMAT 999G999     HEADING "NB LIGNES"
COLUMN MONTANT    FORMAT 999G999G999 HEADING "MONTANT"

SELECT ril.org_id                          AS ORG_ID,
       ril.batch_source_name               AS SOURCE,
       COUNT(DISTINCT ril.interface_line_id) AS NB_LIGNES,
       ROUND(SUM(ril.amount))              AS MONTANT
FROM   ar.ra_interface_lines_all  ril
JOIN   ar.ra_interface_errors_all rie
       ON rie.interface_line_id = ril.interface_line_id
WHERE  UPPER(rie.message_text) LIKE UPPER('Numéro de facture en double')
AND    rie.interface_line_id = ril.interface_line_id
GROUP BY ril.org_id, ril.batch_source_name
ORDER BY ril.org_id, ril.batch_source_name;

CLEAR COLUMNS

PROMPT
PROMPT === Detail des lignes visees ===

COLUMN INTERFACE_LINE_ID FORMAT 9999999999 HEADING "LINE ID"
COLUMN SOURCE            FORMAT A22        HEADING "SOURCE"
COLUMN CLIENT            FORMAT A20        HEADING "REF CLIENT"
COLUMN TRX_NUMBER        FORMAT A20        HEADING "N FACTURE"
COLUMN TRX_DATE          FORMAT A10        HEADING "DATE"
COLUMN AMOUNT            FORMAT 999G999G999 HEADING "MONTANT"
COLUMN ORG_ID            FORMAT 999999     HEADING "ORG"
COLUMN MESSAGE_TEXT      FORMAT A40        HEADING "MESSAGE"

SELECT DISTINCT
       ril.interface_line_id                    AS INTERFACE_LINE_ID,
       ril.batch_source_name                    AS SOURCE,
       ril.orig_system_bill_customer_ref        AS CLIENT,
       ril.trx_number                           AS TRX_NUMBER,
       TO_CHAR(ril.trx_date, 'DD/MM/YY')        AS TRX_DATE,
       ril.amount                               AS AMOUNT,
       ril.org_id                               AS ORG_ID,
       SUBSTR(rie.message_text, 1, 40)          AS MESSAGE_TEXT
FROM   ar.ra_interface_lines_all  ril
JOIN   ar.ra_interface_errors_all rie
       ON rie.interface_line_id = ril.interface_line_id
WHERE  UPPER(rie.message_text) LIKE UPPER('&&P_MOTIF')
AND    (&&P_ORG_ID = 0 OR ril.org_id = &&P_ORG_ID)
ORDER BY ril.batch_source_name, ril.trx_number;

CLEAR COLUMNS

PROMPT
PROMPT === Lignes a supprimer, par table ===

COLUMN TABLE_NAME FORMAT A34     HEADING "TABLE"
COLUMN NB         FORMAT 999G999 HEADING "NB LIGNES"

WITH cibles AS (
    SELECT DISTINCT ril.interface_line_id
    FROM   ar.ra_interface_lines_all  ril
    JOIN   ar.ra_interface_errors_all rie
           ON rie.interface_line_id = ril.interface_line_id
    WHERE  UPPER(rie.message_text) LIKE UPPER('&&P_MOTIF')
    AND    (&&P_ORG_ID = 0 OR ril.org_id = &&P_ORG_ID)
)
SELECT 'RA_INTERFACE_SALESCREDITS_ALL' AS TABLE_NAME, COUNT(*) AS NB
FROM   ar.ra_interface_salescredits_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT 'RA_INTERFACE_DISTRIBUTIONS_ALL', COUNT(*)
FROM   ar.ra_interface_distributions_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT 'RA_INTERFACE_ERRORS_ALL', COUNT(*)
FROM   ar.ra_interface_errors_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT 'RA_INTERFACE_LINES_ALL', COUNT(*)
FROM   ar.ra_interface_lines_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles);

CLEAR COLUMNS


-- =====================================================================
-- ETAPE 2 : SUPPRESSION
-- =====================================================================
-- Un seul bloc, et un seul. La version precedente proposait aussi quatre
-- DELETE autonomes : le troisieme supprimait les erreurs dont le quatrieme
-- avait besoin pour retrouver les lignes. Lance en entier, le fichier
-- vidait donc les tables enfants ET les erreurs en laissant les lignes
-- d'interface orphelines, sans plus aucune trace du motif de blocage.
-- Ces DELETE autonomes ont ete supprimes.
--
-- Les identifiants sont collectes AVANT toute suppression : c'est ce qui
-- permet de supprimer les erreurs puis les lignes sans perdre la cible.
-- =====================================================================

DECLARE
    c_mode   CONSTANT VARCHAR2(20) := UPPER('&&P_MODE');
    c_motif  CONSTANT VARCHAR2(200) := UPPER('&&P_MOTIF');
    c_org    CONSTANT NUMBER := &&P_ORG_ID;
    c_max    CONSTANT NUMBER := &&P_MAX_LIGNES;

    TYPE t_id_list IS TABLE OF ar.ra_interface_lines_all.interface_line_id%TYPE;
    l_ids t_id_list;

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

    -- Collecte prealable des identifiants vises.
    SELECT DISTINCT ril.interface_line_id
    BULK COLLECT INTO l_ids
    FROM   ar.ra_interface_lines_all  ril
    JOIN   ar.ra_interface_errors_all rie
           ON rie.interface_line_id = ril.interface_line_id
    WHERE  UPPER(rie.message_text) LIKE c_motif
    AND    (c_org = 0 OR ril.org_id = c_org);

    DBMS_OUTPUT.PUT_LINE('Lignes d''interface identifiees : ' || l_ids.COUNT);

    IF l_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucun enregistrement a supprimer : rien a faire.');
        DBMS_OUTPUT.PUT_LINE('Si des doublons sont pourtant attendus, verifier P_MOTIF :');
        DBMS_OUTPUT.PUT_LINE('le message d''erreur EBS est traduit selon NLS_LANGUAGE.');
        RETURN;
    END IF;

    -- Garde-fou : un motif trop large ne doit pas pouvoir vider l'interface.
    IF l_ids.COUNT > c_max THEN
        RAISE_APPLICATION_ERROR(-20002,
            l_ids.COUNT || ' lignes visees, au-dela du plafond de ' || c_max || '. '
            || 'Verifier P_MOTIF et P_ORG_ID, ou relever P_MAX_LIGNES en connaissance de cause.');
    END IF;

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
        DBMS_OUTPUT.PUT_LINE('Pour appliquer : DEFINE P_MODE = "EXECUTION" en tete de script.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR - ROLLBACK effectue : ' || SQLERRM);
        RAISE;
END;
/


-- =====================================================================
-- ETAPE 3 : VERIFICATION POST-SUPPRESSION
-- =====================================================================
-- Recompter les erreurs du motif ne prouve rien : elles viennent d'etre
-- supprimees. Ce qui compte, c'est qu'aucun enfant ne soit reste orphelin.
-- =====================================================================

PROMPT
PROMPT === Controle des orphelins (doit rendre 0 partout) ===

COLUMN CONTROLE FORMAT A46     HEADING "CONTROLE"
COLUMN NB       FORMAT 999G999 HEADING "NB"

SELECT 'Erreurs restantes sur le motif' AS CONTROLE, COUNT(*) AS NB
FROM   ar.ra_interface_errors_all rie
WHERE  UPPER(rie.message_text) LIKE UPPER('&&P_MOTIF')
UNION ALL
SELECT 'Distributions sans ligne parente', COUNT(*)
FROM   ar.ra_interface_distributions_all d
WHERE  NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = d.interface_line_id)
UNION ALL
SELECT 'Credits de vente sans ligne parente', COUNT(*)
FROM   ar.ra_interface_salescredits_all s
WHERE  NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = s.interface_line_id)
UNION ALL
SELECT 'Erreurs sans ligne parente', COUNT(*)
FROM   ar.ra_interface_errors_all e
WHERE  e.interface_line_id IS NOT NULL
AND    NOT EXISTS (SELECT 1 FROM ar.ra_interface_lines_all l
                   WHERE l.interface_line_id = e.interface_line_id);

CLEAR COLUMNS

PROMPT
PROMPT === Fin ===
