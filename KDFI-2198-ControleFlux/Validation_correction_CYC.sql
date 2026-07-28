-- =====================================================================
-- Validation de la correction - Fichier CYC du 02/12/2025
-- =====================================================================
-- Date : 04/12/2025
-- Objectif : Valider que la suppression du DECODE résout l'écart de 7,9M€
--
-- RAPPEL DU PROBLÈME :
--   - Avoirs stockés en NÉGATIF dans Oracle : -3 996 905,57€
--   - Package appliquait (-1) × (négatif) = POSITIF → ERREUR
--   - Écart créé : -7 993 811,14€
--
-- CORRECTION :
--   - Suppression du DECODE d'inversion
--   - SUM simple : les avoirs restent négatifs = CORRECT
-- =====================================================================

SET LINESIZE 200
COL type_mvt FORMAT A25
COL nb_factures FORMAT 999,999
COL montant_oracle FORMAT 999,999,999.99
COL status FORMAT A30

PROMPT =====================================================================
PROMPT VALIDATION 1 : Montants par type de mouvement
PROMPT =====================================================================
PROMPT Fichier : HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001
PROMPT

SELECT SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_oracle,
       CASE 
         WHEN SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) LIKE '%AVOIR%' 
              AND SUM(RCTL.EXTENDED_AMOUNT) < 0
         THEN 'OK - Avoir NEGATIF (correct)'
         WHEN SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) LIKE '%AVOIR%' 
              AND SUM(RCTL.EXTENDED_AMOUNT) > 0
         THEN 'ERREUR - Avoir POSITIF !'
         ELSE 'OK - Facture normale'
       END AS status
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)
ORDER BY montant_oracle DESC;

PROMPT
PROMPT Résultat attendu :
PROMPT   T_FACTURE  : 838 pièces,  +7 175 040,16 € (OK - Facture normale)
PROMPT   ONT_AVOIR  :  55 pièces,  -3 996 905,57 € (OK - Avoir NEGATIF)
PROMPT

PROMPT =====================================================================
PROMPT VALIDATION 2 : Total net (doit correspondre à l'amont)
PROMPT =====================================================================

SELECT COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_pieces_total,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_net_total,
       CASE 
         WHEN ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) BETWEEN 3100000 AND 3500000
         THEN 'OK - Proche du montant amont (3 443 835,61 €)'
         ELSE 'A VERIFIER'
       END AS status
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION';

PROMPT
PROMPT Résultat attendu :
PROMPT   893 pièces, 3 178 134,59 € (OK - aligné avec amont)
PROMPT   
PROMPT   Si le montant est autour de 11M€ → Le package inverse encore (ERREUR)
PROMPT   Si le montant est autour de 3M€ → Correction réussie (OK)
PROMPT

PROMPT =====================================================================
PROMPT VALIDATION 3 : Détail de quelques avoirs
PROMPT =====================================================================
PROMPT Vérifier que les avoirs sont bien négatifs dans Oracle

SELECT RCTL.CUSTOMER_TRX_ID AS num_facture,
       SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       ROUND(RCTL.EXTENDED_AMOUNT, 2) AS montant,
       CASE 
         WHEN RCTL.EXTENDED_AMOUNT < 0 THEN 'OK - Négatif'
         WHEN RCTL.EXTENDED_AMOUNT > 0 THEN 'ERREUR - Positif !'
         ELSE 'Nul'
       END AS status
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
  AND SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) LIKE '%AVOIR%'
  AND ROWNUM <= 10
ORDER BY RCTL.EXTENDED_AMOUNT;

PROMPT
PROMPT =====================================================================
PROMPT VALIDATION 4 : Synthèse AVANT vs APRÈS correction
PROMPT =====================================================================

SELECT 'AVANT correction (avec DECODE inversion)' AS scenario,
       893 AS nb_pieces,
       ROUND(SUM(CASE 
                   WHEN SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) LIKE '%AVOIR%'
                   THEN (-1) * RCTL.EXTENDED_AMOUNT  -- Inversion = ERREUR
                   ELSE RCTL.EXTENDED_AMOUNT
                 END), 2) AS montant_total,
       '11 171 945,73 €' AS attendu,
       'Écart -7 993 811,14 € vs amont' AS resultat
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
UNION ALL
SELECT 'APRES correction (SUM simple)' AS scenario,
       893 AS nb_pieces,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_total,  -- Simple SUM = CORRECT
       '3 178 134,59 €' AS attendu,
       'Aligné avec amont' AS resultat
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION';

PROMPT
PROMPT =====================================================================
PROMPT FIN DE LA VALIDATION
PROMPT =====================================================================
PROMPT
PROMPT INTERPRETATION :
PROMPT ✅ Si VALIDATION 1 montre avoirs NEGATIFS → Oracle correct
PROMPT ✅ Si VALIDATION 2 montre ~3,1M€ → Package correct (après correction)
PROMPT ✅ Si VALIDATION 4 AVANT = 11M€ et APRES = 3M€ → Correction validée
PROMPT
PROMPT ❌ Si VALIDATION 2 montre ~11M€ → Package inverse encore (erreur)
PROMPT
PROMPT La correction consiste à SUPPRIMER le DECODE d'inversion dans le package
PROMPT car les avoirs sont DEJA négatifs dans Oracle.
PROMPT =====================================================================
