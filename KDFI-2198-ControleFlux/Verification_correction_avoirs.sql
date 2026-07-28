-- =====================================================================
-- Script de vérification - Correction avoirs contrôle de flux
-- =====================================================================
-- Date de création : 04/12/2025
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13 (DB 19.25)
--
-- OBJECTIF : Valider que la correction du package DKA_SCTLFLUX_EAI_PKG
-- inverse correctement le signe des avoirs clients.
--
-- VOIR : CORRECTION_Avoirs_04122025.md
-- =====================================================================

PROMPT =====================================================================
PROMPT Vérification 1 : État de compilation du package
PROMPT =====================================================================

SELECT object_name, 
       object_type, 
       status,
       last_ddl_time
FROM dba_objects
WHERE owner = 'APPS'
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
ORDER BY object_type;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 2 : Distribution des types de mouvements AR (7 derniers jours)
PROMPT =====================================================================

SELECT SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE1 || RII.INTERFACE_LINE_ATTRIBUTE2 || RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_factures,
       COUNT(*) AS nb_lignes_distribution,
       SUM(RID.AMOUNT) AS montant_brut,
       SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                  'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                  'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                  RID.AMOUNT)) AS montant_net,
       CASE 
         WHEN SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV') THEN 'AVOIR (inversé)'
         ELSE 'FACTURE (normal)'
       END AS comportement
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
GROUP BY SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)
ORDER BY type_mvt;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 3 : Comparaison par folio (IGP et SVD) - RA_INTERFACE
PROMPT =====================================================================

SELECT RII.ATTRIBUTE9 AS folio,
       RII.ATTRIBUTE10 AS fichier,
       SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE1 || RII.INTERFACE_LINE_ATTRIBUTE2 || RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_factures,
       -- Compte 411 (clients) pour DEBIT
       SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) = '411' 
                THEN DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                           'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                           'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                           RID.AMOUNT)
                ELSE 0 
           END) AS debit_net,
       -- Autres comptes pour CREDIT
       SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) != '411' 
                THEN DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                           'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                           'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                           RID.AMOUNT)
                ELSE 0 
           END) AS credit_net
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RII.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
GROUP BY RII.ATTRIBUTE9, RII.ATTRIBUTE10, SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)
ORDER BY folio, fichier, type_mvt;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 4 : Comparaison par folio - RA_CUSTOMER_TRX
PROMPT =====================================================================

SELECT RCTL.ATTRIBUTE9 AS folio,
       RCTL.ATTRIBUTE10 AS fichier,
       SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       -- Compte 411 (clients) pour DEBIT
       SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) = '411' 
                THEN DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                           'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                           'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                           RCTL.EXTENDED_AMOUNT)
                ELSE 0 
           END) AS debit_net,
       -- Autres comptes pour CREDIT
       SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) != '411' 
                THEN DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                           'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                           'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                           RCTL.EXTENDED_AMOUNT)
                ELSE 0 
           END) AS credit_net
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
JOIN RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD ON RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                          AND RCTLGD.CUSTOMER_TRX_LINE_ID = RCTL.CUSTOMER_TRX_LINE_ID
JOIN GL_CODE_COMBINATIONS GCC ON GCC.CODE_COMBINATION_ID = RCTLGD.CODE_COMBINATION_ID
WHERE RCTL.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RCTL.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY RCTL.ATTRIBUTE9, RCTL.ATTRIBUTE10, SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)
ORDER BY folio, fichier, type_mvt;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 5 : Détection des avoirs sans inversion (problème)
PROMPT =====================================================================
PROMPT Cette requête devrait retourner ZERO ligne si la correction fonctionne

SELECT 'RA_INTERFACE' AS source,
       RII.ATTRIBUTE9 AS folio,
       RII.ATTRIBUTE10 AS fichier,
       SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       SUM(RID.AMOUNT) AS montant_brut,
       CASE 
         WHEN SUM(RID.AMOUNT) > 0 AND SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
         THEN 'PROBLEME : Avoir non inversé !'
         ELSE 'OK'
       END AS statut
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RII.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
GROUP BY RII.ATTRIBUTE9, RII.ATTRIBUTE10, SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)
HAVING SUM(RID.AMOUNT) > 0
UNION ALL
SELECT 'RA_CUSTOMER_TRX' AS source,
       RCTL.ATTRIBUTE9 AS folio,
       RCTL.ATTRIBUTE10 AS fichier,
       SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       SUM(RCTL.EXTENDED_AMOUNT) AS montant_brut,
       CASE 
         WHEN SUM(RCTL.EXTENDED_AMOUNT) > 0 AND SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
         THEN 'PROBLEME : Avoir non inversé !'
         ELSE 'OK'
       END AS statut
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RCTL.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
  AND SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
GROUP BY RCTL.ATTRIBUTE9, RCTL.ATTRIBUTE10, SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)
HAVING SUM(RCTL.EXTENDED_AMOUNT) > 0;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 6 : Dernière exécution du programme de contrôle
PROMPT =====================================================================

SELECT FCR.REQUEST_ID,
       FCR.ACTUAL_START_DATE,
       FCR.ACTUAL_COMPLETION_DATE,
       ROUND((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60, 2) AS duree_minutes,
       FCR.STATUS_CODE,
       FCR.PHASE_CODE,
       FCR.ARGUMENT_TEXT AS parametres
FROM FND_CONCURRENT_REQUESTS FCR
JOIN FND_CONCURRENT_PROGRAMS_VL FCP ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
WHERE FCP.USER_CONCURRENT_PROGRAM_NAME = 'DKA : Extraction du contrôle de flux'
  AND FCR.ACTUAL_START_DATE >= TRUNC(SYSDATE) - 7
ORDER BY FCR.REQUEST_ID DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT =====================================================================
PROMPT Vérification 7 : Résultats du dernier contrôle de flux (IGP/SVD)
PROMPT =====================================================================

SELECT DSE.CODE_FOLIO,
       DSE.FICHIER,
       DSE.DATE_EXEC,
       DSE.NB_PIECE,
       ROUND(DSE.DEBIT, 2) AS debit,
       ROUND(DSE.CREDIT, 2) AS credit,
       ROUND(DSE.DEBIT - DSE.CREDIT, 2) AS net,
       DSE.N_TRAITEMENT AS request_id
FROM DKA_SCTLFLUX_EAI DSE
WHERE DSE.N_TRAITEMENT = (SELECT MAX(FCR.REQUEST_ID)
                          FROM FND_CONCURRENT_REQUESTS FCR
                          JOIN FND_CONCURRENT_PROGRAMS_VL FCP ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
                          WHERE FCP.USER_CONCURRENT_PROGRAM_NAME = 'DKA : Extraction du contrôle de flux'
                            AND FCR.ACTUAL_START_DATE >= TRUNC(SYSDATE) - 7)
  AND DSE.CODE_FOLIO IN ('IGP', 'SVD')
ORDER BY DSE.CODE_FOLIO, DSE.FICHIER;

PROMPT
PROMPT =====================================================================
PROMPT FIN DE LA VERIFICATION
PROMPT =====================================================================
PROMPT
PROMPT INTERPRETATION DES RESULTATS :
PROMPT - Vérification 1 : Le package doit être VALID
PROMPT - Vérification 2 : Les avoirs (SI_AMONT_AVOIR, SI_AMT_ANNUL_AV) 
PROMPT                    doivent avoir un montant_net négatif
PROMPT - Vérification 3-4 : Les montants nets par folio doivent correspondre
PROMPT                      aux attentes amont
PROMPT - Vérification 5 : AUCUNE ligne ne doit apparaître (0 rows)
PROMPT - Vérification 6-7 : Consulter les résultats du dernier contrôle
PROMPT =====================================================================
