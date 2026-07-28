-- =====================================================================
-- Test diagnostic pour le folio CYC - Contrôle de flux
-- =====================================================================
-- Date : 04/12/2025
-- Objectif : Diagnostiquer l'écart de 7,9M€ sur le folio CYC (900 pièces)
--           en comparant montant_brut (AVANT correction) vs montant_net (APRÈS)
--
-- Données de référence (capture d'écran) :
--   Application Amont : 900 pièces, Débit=3443835,61€, Crédit=3443835,61€
--   Flux Finance     : 900 pièces, Débit=11437646,75€, Crédit=11437646,75€
--   Écart            : Nombre=0, Débit=-7993811,14€, Crédit=-7993811,14€
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 1000
COL fichier FORMAT A50
COL folio FORMAT A10
COL type_mvt FORMAT A25
COL nb_pieces FORMAT 999,999
COL montant_brut FORMAT 999,999,999.99
COL montant_net FORMAT 999,999,999.99
COL ecart FORMAT 999,999,999.99

PROMPT =====================================================================
PROMPT DIAGNOSTIC 1 : Vue d'ensemble du folio CYC
PROMPT =====================================================================
PROMPT Recherche des données CYC dans RA_INTERFACE_LINES et RA_CUSTOMER_TRX

-- Vérifier si des données CYC existent dans RA_INTERFACE_LINES
SELECT 'RA_INTERFACE_LINES' AS source,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_factures,
       COUNT(*) AS nb_lignes_distrib,
       MIN(RII.CREATION_DATE) AS date_min,
       MAX(RII.CREATION_DATE) AS date_max
FROM RA_INTERFACE_LINES_ALL RII
WHERE RII.ATTRIBUTE9 = 'CYC'
  AND RII.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RII.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY');

-- Vérifier si des données CYC existent dans RA_CUSTOMER_TRX_LINES
SELECT 'RA_CUSTOMER_TRX_LINES' AS source,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       COUNT(*) AS nb_lignes,
       MIN(RCTL.CREATION_DATE) AS date_min,
       MAX(RCTL.CREATION_DATE) AS date_max
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
WHERE RCTL.ATTRIBUTE9 = 'CYC'
  AND RCTL.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RCTL.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY');

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 2 : Analyse par type de mouvement (RA_INTERFACE_LINES)
PROMPT =====================================================================
PROMPT Objectif : Identifier les avoirs non inversés causant l'écart de 7,9M€

SELECT SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_factures,
       COUNT(*) AS nb_lignes_distrib,
       ROUND(SUM(RID.AMOUNT), 2) AS montant_brut,
       ROUND(SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                        'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                        'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                        RID.AMOUNT)), 2) AS montant_net,
       ROUND(SUM(RID.AMOUNT) - SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                                          'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                                          'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                                          RID.AMOUNT)), 2) AS ecart,
       CASE 
         WHEN SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV') 
         THEN '⚠️ AVOIR - doit être inversé'
         ELSE '✅ FACTURE - normal'
       END AS comportement
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.ATTRIBUTE9 = 'CYC'
  AND RII.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RII.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
GROUP BY SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)
ORDER BY ecart DESC;

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 3 : Répartition Débit/Crédit (compte 411 vs autres)
PROMPT =====================================================================
PROMPT Comparaison AVANT/APRÈS correction pour le folio CYC

SELECT 
       CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) = '411' THEN 'DEBIT (Compte 411)' ELSE 'CREDIT (Autres comptes)' END AS categorie,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_factures,
       -- AVANT correction (montant_brut)
       ROUND(SUM(RID.AMOUNT), 2) AS montant_brut_AVANT,
       -- APRÈS correction (montant_net avec inversion avoirs)
       ROUND(SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                        'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                        'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                        RID.AMOUNT)), 2) AS montant_net_APRES,
       -- Écart = ce qui sera corrigé
       ROUND(SUM(RID.AMOUNT) - SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                                          'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                                          'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                                          RID.AMOUNT)), 2) AS ecart_corrige
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.ATTRIBUTE9 = 'CYC'
  AND RII.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RII.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
GROUP BY CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) = '411' THEN 'DEBIT (Compte 411)' ELSE 'CREDIT (Autres comptes)' END
ORDER BY categorie;

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 4 : Analyse par type de mouvement (RA_CUSTOMER_TRX_LINES)
PROMPT =====================================================================

SELECT SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       COUNT(*) AS nb_lignes,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_brut,
       ROUND(SUM(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                        'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                        'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                        RCTL.EXTENDED_AMOUNT)), 2) AS montant_net,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT) - SUM(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                                                     'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                                                     'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                                                     RCTL.EXTENDED_AMOUNT)), 2) AS ecart,
       CASE 
         WHEN SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV') 
         THEN '⚠️ AVOIR - doit être inversé'
         ELSE '✅ FACTURE - normal'
       END AS comportement
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE9 = 'CYC'
  AND RCTL.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RCTL.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)
ORDER BY ecart DESC;

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 5 : Répartition Débit/Crédit (RA_CUSTOMER_TRX_LINES)
PROMPT =====================================================================

SELECT 
       CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) = '411' THEN 'DEBIT (Compte 411)' ELSE 'CREDIT (Autres comptes)' END AS categorie,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       -- AVANT correction
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_brut_AVANT,
       -- APRÈS correction
       ROUND(SUM(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                        'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                        'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                        RCTL.EXTENDED_AMOUNT)), 2) AS montant_net_APRES,
       -- Écart
       ROUND(SUM(RCTL.EXTENDED_AMOUNT) - SUM(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                                                     'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                                                     'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                                                     RCTL.EXTENDED_AMOUNT)), 2) AS ecart_corrige
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
JOIN RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD ON RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                          AND RCTLGD.CUSTOMER_TRX_LINE_ID = RCTL.CUSTOMER_TRX_LINE_ID
JOIN GL_CODE_COMBINATIONS GCC ON GCC.CODE_COMBINATION_ID = RCTLGD.CODE_COMBINATION_ID
WHERE RCTL.ATTRIBUTE9 = 'CYC'
  AND RCTL.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RCTL.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) = '411' THEN 'DEBIT (Compte 411)' ELSE 'CREDIT (Autres comptes)' END
ORDER BY categorie;

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 6 : SYNTHÈSE - Comparaison avec capture d'écran
PROMPT =====================================================================
PROMPT Données attendues (capture) :
PROMPT   Application Amont : 900 pièces, 3 443 835,61€
PROMPT   Flux Finance     : 900 pièces, 11 437 646,75€
PROMPT   Écart            : -7 993 811,14€

SELECT 'TOTAL RA_INTERFACE' AS source,
       COUNT(DISTINCT RII.INTERFACE_LINE_ATTRIBUTE3) AS nb_pieces,
       ROUND(SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) = '411' THEN RID.AMOUNT ELSE 0 END), 2) AS debit_brut_AVANT,
       ROUND(SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) != '411' THEN RID.AMOUNT ELSE 0 END), 2) AS credit_brut_AVANT,
       ROUND(SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) = '411' 
                      THEN DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                                  'SI_AMONT_AVOIR', (-1) * RID.AMOUNT,
                                  'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                                  RID.AMOUNT)
                      ELSE 0 END), 2) AS debit_net_APRES,
       ROUND(SUM(CASE WHEN SUBSTR(RID.SEGMENT3, 1, 3) != '411' 
                      THEN DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                                  'SI_AMONT_AVOIR', (-1) * RID.AMOUNT,
                                  'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                                  RID.AMOUNT)
                      ELSE 0 END), 2) AS credit_net_APRES
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.ATTRIBUTE9 = 'CYC'
  AND RII.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RII.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
UNION ALL
SELECT 'TOTAL RA_CUSTOMER_TRX' AS source,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_pieces,
       ROUND(SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) = '411' THEN RCTL.EXTENDED_AMOUNT ELSE 0 END), 2) AS debit_brut_AVANT,
       ROUND(SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) != '411' THEN RCTL.EXTENDED_AMOUNT ELSE 0 END), 2) AS credit_brut_AVANT,
       ROUND(SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) = '411' 
                      THEN DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                                  'SI_AMONT_AVOIR', (-1) * RCTL.EXTENDED_AMOUNT,
                                  'SI_AMT_ANNUL_AV', (-1) * RCTL.EXTENDED_AMOUNT,
                                  RCTL.EXTENDED_AMOUNT)
                      ELSE 0 END), 2) AS debit_net_APRES,
       ROUND(SUM(CASE WHEN SUBSTR(GCC.SEGMENT3, 1, 3) != '411' 
                      THEN DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                                  'SI_AMONT_AVOIR', (-1) * RCTL.EXTENDED_AMOUNT,
                                  'SI_AMT_ANNUL_AV', (-1) * RCTL.EXTENDED_AMOUNT,
                                  RCTL.EXTENDED_AMOUNT)
                      ELSE 0 END), 2) AS credit_net_APRES
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
JOIN RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD ON RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                          AND RCTLGD.CUSTOMER_TRX_LINE_ID = RCTL.CUSTOMER_TRX_LINE_ID
JOIN GL_CODE_COMBINATIONS GCC ON GCC.CODE_COMBINATION_ID = RCTLGD.CODE_COMBINATION_ID
WHERE RCTL.ATTRIBUTE9 = 'CYC'
  AND RCTL.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RCTL.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION';

PROMPT
PROMPT =====================================================================
PROMPT DIAGNOSTIC 7 : DÉTECTION DES AVOIRS - Liste détaillée
PROMPT =====================================================================
PROMPT Liste des 10 premiers avoirs pour vérifier l'inversion de signe

SELECT SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       RII.INTERFACE_LINE_ATTRIBUTE3 AS num_facture,
       RID.SEGMENT3 AS compte,
       ROUND(RID.AMOUNT, 2) AS montant_brut,
       ROUND(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                    'SI_AMONT_AVOIR', (-1) * RID.AMOUNT,
                    'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                    RID.AMOUNT), 2) AS montant_net,
       CASE 
         WHEN SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
              AND RID.AMOUNT > 0
         THEN '❌ AVOIR NON INVERSÉ'
         WHEN SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
              AND RID.AMOUNT < 0
         THEN '✅ AVOIR DÉJÀ NÉGATIF'
         ELSE '✅ FACTURE NORMALE'
       END AS statut
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.ATTRIBUTE9 = 'CYC'
  AND RII.CREATION_DATE >= TO_DATE('02/12/2025', 'DD/MM/YYYY')
  AND RII.CREATION_DATE < TO_DATE('03/12/2025', 'DD/MM/YYYY')
  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) IN ('SI_AMONT_AVOIR', 'SI_AMT_ANNUL_AV')
  AND ROWNUM <= 10
ORDER BY RID.AMOUNT DESC;

PROMPT
PROMPT =====================================================================
PROMPT FIN DU DIAGNOSTIC
PROMPT =====================================================================
PROMPT
PROMPT INTERPRÉTATION :
PROMPT - DIAGNOSTIC 2 : Si "ecart" ≈ 7,9M€ sur ligne AVOIR → c'est la cause !
PROMPT - DIAGNOSTIC 3 : Vérifier que montant_net_APRES ≈ 3,44M€ (capture amont)
PROMPT - DIAGNOSTIC 6 : Comparer les totaux avec la capture d'écran
PROMPT - DIAGNOSTIC 7 : Si statut = "AVOIR NON INVERSÉ" → correction nécessaire
PROMPT
PROMPT Si l'écart est confirmé = 7,9M€ d'avoirs comptés en positif au lieu de négatif
PROMPT → La correction du package résoudra ce problème
PROMPT =====================================================================
