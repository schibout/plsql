-- =====================================================================
-- Rapport complet des lignes candidates a la suppression - Open Interface AR
-- =====================================================================
-- Base de donnees : Oracle EBS 12.2.13
-- Appele par      : Suppression_Doublons.ps1 (ne pas lancer seul, les
--                   parametres et le SPOOL sont poses par le PowerShell)
--
-- OBJET :
--   Ne supprime RIEN. Ce script ne fait que lire, et emet sur le spool
--   une ligne balisee par enregistrement qui serait supprime, dans les
--   quatre tables concernees :
--     ##LINE## une par ligne de RA_INTERFACE_LINES_ALL visee
--     ##ERR##  une par erreur      (RA_INTERFACE_ERRORS_ALL)
--     ##DIST## une par distribution(RA_INTERFACE_DISTRIBUTIONS_ALL)
--     ##SC##   une par credit vente(RA_INTERFACE_SALESCREDITS_ALL)
--     ##CNT##  compteurs par table
--     ##CTRL## nombre de lignes et somme des identifiants visees
--
--   ##CTRL## est le lien avec la suppression : le bloc de purge recalcule
--   ces deux valeurs et refuse d'agir si elles ont bouge. Le rapport et
--   la suppression portent donc forcement sur le meme perimetre, meme si
--   l'interface evolue entre les deux etapes.
--
-- SEPARATEUR : | . Les colonnes de texte libre sont nettoyees de tout
--   pipe et de tout retour ligne, pour que le PowerShell puisse decouper
--   sans ambiguite.
--
-- PARAMETRES attendus (DEFINE poses par le PowerShell) :
--   P_MOTIF    motif LIKE du message d'erreur, insensible a la casse.
--              Le message est traduit par EBS selon NLS_LANGUAGE :
--              en session anglaise, utiliser '%duplicate invoice%'.
--   P_ORG_ID   0 = toutes les organisations, sinon l'ORG_ID a traiter.
-- =====================================================================

SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET TRIMOUT ON
SET TERMOUT OFF
SET ECHO OFF
SET SERVEROUTPUT OFF
SET NEWPAGE NONE

-- Format impose : le PowerShell relit ces valeurs, elles ne doivent pas
-- dependre du NLS du poste qui lance le script.
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ';

-- Les balises passent par SELECT et non par PROMPT : avec TERMOUT OFF,
-- seul le resultat des requetes est garanti dans le spool.
SELECT '##PARAM##' || '&&P_MOTIF' || '|' || '&&P_ORG_ID' FROM DUAL;


-- ---------------------------------------------------------------------
-- Controle de perimetre : nombre de lignes visees et somme des
-- identifiants. Le bloc de suppression rejouera exactement ce calcul.
-- ---------------------------------------------------------------------
SELECT '##CTRL##' || COUNT(*) || '|' || NVL(TO_CHAR(SUM(interface_line_id)), '0')
FROM (
    SELECT DISTINCT ril.interface_line_id
    FROM   ar.ra_interface_lines_all  ril
    JOIN   ar.ra_interface_errors_all rie
           ON rie.interface_line_id = ril.interface_line_id
    WHERE  UPPER(rie.message_text) LIKE UPPER('&&P_MOTIF')
    AND    (&&P_ORG_ID = 0 OR ril.org_id = &&P_ORG_ID)
);


-- ---------------------------------------------------------------------
-- Compteurs par table : ce qui partira reellement, table par table.
-- ---------------------------------------------------------------------
WITH cibles AS (
    SELECT DISTINCT ril.interface_line_id
    FROM   ar.ra_interface_lines_all  ril
    JOIN   ar.ra_interface_errors_all rie
           ON rie.interface_line_id = ril.interface_line_id
    WHERE  UPPER(rie.message_text) LIKE UPPER('&&P_MOTIF')
    AND    (&&P_ORG_ID = 0 OR ril.org_id = &&P_ORG_ID)
)
SELECT '##CNT##RA_INTERFACE_SALESCREDITS_ALL|' || COUNT(*)
FROM   ar.ra_interface_salescredits_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT '##CNT##RA_INTERFACE_DISTRIBUTIONS_ALL|' || COUNT(*)
FROM   ar.ra_interface_distributions_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT '##CNT##RA_INTERFACE_ERRORS_ALL|' || COUNT(*)
FROM   ar.ra_interface_errors_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles)
UNION ALL
SELECT '##CNT##RA_INTERFACE_LINES_ALL|' || COUNT(*)
FROM   ar.ra_interface_lines_all
WHERE  interface_line_id IN (SELECT interface_line_id FROM cibles);


-- ---------------------------------------------------------------------
-- Detail des lignes d'interface visees.
--
-- La colonne NB_TRX_EXISTANTES repond a la question qui compte avant une
-- purge : la facture est-elle deja integree en base ? Si oui, la ligne
-- d'interface est un vrai doublon et peut partir. Si non, le rejet vient
-- d'un doublon INTERNE a l'interface, et supprimer les deux exemplaires
-- ferait perdre la facture. Le rapport distingue les deux cas, le
-- PowerShell les remonte separement.
-- ---------------------------------------------------------------------
SELECT '##LINE##'
       || ril.interface_line_id                                      || '|'
       || NVL(REPLACE(ril.batch_source_name, '|', '/'), '')          || '|'
       || NVL(REPLACE(ril.interface_line_context, '|', '/'), '')     || '|'
       || NVL(REPLACE(ril.interface_line_attribute1, '|', '/'), '')  || '|'
       || NVL(REPLACE(ril.interface_line_attribute2, '|', '/'), '')  || '|'
       || NVL(REPLACE(ril.interface_line_attribute3, '|', '/'), '')  || '|'
       || NVL(REPLACE(ril.trx_number, '|', '/'), '')                 || '|'
       || NVL(TO_CHAR(ril.trx_date, 'DD/MM/YYYY'), '')               || '|'
       || NVL(TO_CHAR(ril.gl_date, 'DD/MM/YYYY'), '')                || '|'
       || NVL(TO_CHAR(ril.amount), '0')                              || '|'
       || NVL(ril.currency_code, '')                                 || '|'
       || NVL(REPLACE(ril.orig_system_bill_customer_ref, '|', '/'), '') || '|'
       || NVL(REPLACE(ril.cust_trx_type_name, '|', '/'), '')         || '|'
       || NVL(REPLACE(ril.line_type, '|', '/'), '')                  || '|'
       || NVL(TO_CHAR(ril.quantity), '')                             || '|'
       || NVL(SUBSTR(REPLACE(REPLACE(REPLACE(ril.description, CHR(13), ' '),
                                     CHR(10), ' '), '|', '/'), 1, 120), '')  || '|'
       || NVL(TO_CHAR(ril.org_id), '')                               || '|'
       || NVL(TO_CHAR(ril.created_by), '')                           || '|'
       || NVL(TO_CHAR(ril.creation_date, 'DD/MM/YYYY HH24:MI'), '')  || '|'
       || NVL(TO_CHAR(ril.request_id), '')                           || '|'
       -- Volumetrie des enfants qui partiront avec la ligne.
       || (SELECT COUNT(*) FROM ar.ra_interface_errors_all e
           WHERE e.interface_line_id = ril.interface_line_id)        || '|'
       || (SELECT COUNT(*) FROM ar.ra_interface_distributions_all d
           WHERE d.interface_line_id = ril.interface_line_id)        || '|'
       || (SELECT COUNT(*) FROM ar.ra_interface_salescredits_all s
           WHERE s.interface_line_id = ril.interface_line_id)        || '|'
       -- Message le plus explicite parmi ceux de la ligne.
       || NVL(SUBSTR(REPLACE(REPLACE(REPLACE(
              (SELECT MIN(e.message_text) FROM ar.ra_interface_errors_all e
               WHERE e.interface_line_id = ril.interface_line_id
               AND   UPPER(e.message_text) LIKE UPPER('&&P_MOTIF')),
              CHR(13), ' '), CHR(10), ' '), '|', '/'), 1, 200), '')  || '|'
       -- La facture existe-t-elle deja dans les tables definitives ?
       || (SELECT COUNT(*) FROM ar.ra_customer_trx_all t
           WHERE t.trx_number = ril.trx_number
           AND   t.org_id     = ril.org_id)                          || '|'
       || NVL((SELECT TO_CHAR(MAX(t.trx_date), 'DD/MM/YYYY')
               FROM ar.ra_customer_trx_all t
               WHERE t.trx_number = ril.trx_number
               AND   t.org_id     = ril.org_id), '')                 || '|'
       -- Nombre d'exemplaires du meme numero DANS l'interface : au-dela
       -- de 1, le doublon est interne et la purge merite un arbitrage.
       || (SELECT COUNT(DISTINCT l2.interface_line_id)
           FROM ar.ra_interface_lines_all l2
           WHERE l2.trx_number = ril.trx_number
           AND   NVL(l2.org_id, -1) = NVL(ril.org_id, -1))
FROM   ar.ra_interface_lines_all ril
WHERE  ril.interface_line_id IN (
           SELECT DISTINCT l.interface_line_id
           FROM   ar.ra_interface_lines_all  l
           JOIN   ar.ra_interface_errors_all e
                  ON e.interface_line_id = l.interface_line_id
           WHERE  UPPER(e.message_text) LIKE UPPER('&&P_MOTIF')
           AND    (&&P_ORG_ID = 0 OR l.org_id = &&P_ORG_ID)
       )
ORDER BY ril.org_id, ril.batch_source_name, ril.trx_number, ril.interface_line_id;


-- ---------------------------------------------------------------------
-- Detail des erreurs supprimees.
-- Toutes les erreurs des lignes visees partent, pas seulement celles du
-- motif : la ligne disparait, ses erreurs n'ont plus d'objet. Le rapport
-- les liste donc toutes, y compris celles qui ne parlent pas de doublon.
-- ---------------------------------------------------------------------
SELECT '##ERR##'
       || rie.interface_line_id || '|'
       || NVL(SUBSTR(REPLACE(REPLACE(REPLACE(rie.message_text, CHR(13), ' '),
                                     CHR(10), ' '), '|', '/'), 1, 250), '') || '|'
       || NVL(SUBSTR(REPLACE(REPLACE(REPLACE(rie.invalid_value, CHR(13), ' '),
                                     CHR(10), ' '), '|', '/'), 1, 120), '') || '|'
       || NVL(TO_CHAR(rie.org_id), '')
FROM   ar.ra_interface_errors_all rie
WHERE  rie.interface_line_id IN (
           SELECT DISTINCT l.interface_line_id
           FROM   ar.ra_interface_lines_all  l
           JOIN   ar.ra_interface_errors_all e
                  ON e.interface_line_id = l.interface_line_id
           WHERE  UPPER(e.message_text) LIKE UPPER('&&P_MOTIF')
           AND    (&&P_ORG_ID = 0 OR l.org_id = &&P_ORG_ID)
       )
ORDER BY rie.interface_line_id;


-- ---------------------------------------------------------------------
-- Detail des distributions supprimees.
-- ---------------------------------------------------------------------
SELECT '##DIST##'
       || NVL(TO_CHAR(rid.interface_distribution_id), '') || '|'
       || rid.interface_line_id                           || '|'
       || NVL(rid.account_class, '')                      || '|'
       || NVL(TO_CHAR(rid.amount), '')                    || '|'
       || NVL(TO_CHAR(rid.percent), '')                   || '|'
       || NVL(TO_CHAR(rid.org_id), '')
FROM   ar.ra_interface_distributions_all rid
WHERE  rid.interface_line_id IN (
           SELECT DISTINCT l.interface_line_id
           FROM   ar.ra_interface_lines_all  l
           JOIN   ar.ra_interface_errors_all e
                  ON e.interface_line_id = l.interface_line_id
           WHERE  UPPER(e.message_text) LIKE UPPER('&&P_MOTIF')
           AND    (&&P_ORG_ID = 0 OR l.org_id = &&P_ORG_ID)
       )
ORDER BY rid.interface_line_id, rid.account_class;


-- ---------------------------------------------------------------------
-- Detail des credits de vente supprimes.
-- ---------------------------------------------------------------------
SELECT '##SC##'
       || NVL(TO_CHAR(ris.interface_salescredit_id), '')  || '|'
       || ris.interface_line_id                           || '|'
       || NVL(REPLACE(ris.salesrep_number, '|', '/'), '') || '|'
       || NVL(TO_CHAR(ris.sales_credit_amount_split), '') || '|'
       || NVL(TO_CHAR(ris.sales_credit_percent_split), '')|| '|'
       || NVL(TO_CHAR(ris.org_id), '')
FROM   ar.ra_interface_salescredits_all ris
WHERE  ris.interface_line_id IN (
           SELECT DISTINCT l.interface_line_id
           FROM   ar.ra_interface_lines_all  l
           JOIN   ar.ra_interface_errors_all e
                  ON e.interface_line_id = l.interface_line_id
           WHERE  UPPER(e.message_text) LIKE UPPER('&&P_MOTIF')
           AND    (&&P_ORG_ID = 0 OR l.org_id = &&P_ORG_ID)
       )
ORDER BY ris.interface_line_id;

-- Marqueur de fin : son absence signale au PowerShell une extraction
-- interrompue, qu'il ne faut surtout pas confondre avec un perimetre vide.
SELECT '##FIN##' FROM DUAL;
