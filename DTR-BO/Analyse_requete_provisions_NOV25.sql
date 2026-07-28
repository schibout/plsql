-- ===============================================================================
-- ANALYSE : Pourquoi des données OCT-25 apparaissent au lieu de NOV-25 ?
-- Date : 01/12/2025
-- Contexte : Requête sur les provisions de la période NOV-25
-- ===============================================================================

-- PROBLÈMES IDENTIFIÉS DANS LA REQUÊTE ORIGINALE :
-- 1. Le filtre gjh.period_name = 'NOV-25' s'applique uniquement aux en-têtes de journal (GL_JE_HEADERS)
-- 2. MAIS la condition GJB.default_period_name = gjh.period_name permet des décalages
-- 3. Les batches peuvent avoir un default_period_name différent de la période réelle du journal
-- 4. Les écritures XLA peuvent avoir des dates comptables différentes

-- ===============================================================================
-- DIAGNOSTIC ÉTAPE 1 : Vérifier la cohérence des périodes dans les données
-- ===============================================================================

-- A. Vérifier s'il existe des batches "PROVISION" avec des incohérences de période
SELECT GJB.JE_BATCH_ID,
       GJB.NAME AS BATCH_NAME,
       GJB.DEFAULT_PERIOD_NAME AS BATCH_PERIOD,
       GJH.JE_HEADER_ID,
       GJH.PERIOD_NAME AS HEADER_PERIOD,
       GJH.JE_SOURCE,
       GJH.JE_CATEGORY,
       TO_CHAR(GJH.DEFAULT_EFFECTIVE_DATE, 'DD/MM/YYYY') AS EFFECTIVE_DATE,
       TO_CHAR(GJB.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS BATCH_CREATED
  FROM GL.GL_JE_BATCHES GJB
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_BATCH_ID = GJB.JE_BATCH_ID
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJH.LEDGER_ID
 WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND (GJH.PERIOD_NAME = 'NOV-25' OR GJB.DEFAULT_PERIOD_NAME = 'NOV-25')
 ORDER BY GJB.DEFAULT_PERIOD_NAME, GJH.PERIOD_NAME, GJB.JE_BATCH_ID;

-- ===============================================================================
-- DIAGNOSTIC ÉTAPE 2 : Comparer les périodes entre GL et XLA
-- ===============================================================================

-- B. Vérifier les périodes dans XLA pour les écritures liées
SELECT GJH.PERIOD_NAME AS GL_PERIOD,
       XAH.PERIOD_NAME AS XLA_PERIOD,
       TO_CHAR(XAH.ACCOUNTING_DATE, 'DD/MM/YYYY') AS XLA_ACCOUNTING_DATE,
       COUNT(*) AS NB_LINES,
       SUM(CASE WHEN GJH.PERIOD_NAME <> XAH.PERIOD_NAME THEN 1 ELSE 0 END) AS NB_MISMATCHES
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 INNER JOIN XLA.XLA_AE_HEADERS XAH ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
   AND GJH.PERIOD_NAME IN ('OCT-25', 'NOV-25')
 GROUP BY GJH.PERIOD_NAME, XAH.PERIOD_NAME, XAH.ACCOUNTING_DATE
 ORDER BY 1, 2;

-- ===============================================================================
-- DIAGNOSTIC ÉTAPE 3 : Identifier les distributions PO liées
-- ===============================================================================

-- C. Vérifier les périodes des distributions PO (source des provisions)
SELECT GJH.PERIOD_NAME AS GL_PERIOD,
       PDA.PO_DISTRIBUTION_ID,
       PH.SEGMENT1 AS PO_NUMBER,
       TO_CHAR(PDA.CREATION_DATE, 'DD/MM/YYYY') AS PO_DIST_CREATED,
       TO_CHAR(XAH.ACCOUNTING_DATE, 'DD/MM/YYYY') AS XLA_ACCOUNTING_DATE,
       XAH.PERIOD_NAME AS XLA_PERIOD,
       COUNT(*) AS NB_LINES
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 INNER JOIN XLA.XLA_AE_HEADERS XAH ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 INNER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 INNER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1
 INNER JOIN PO.PO_HEADERS_ALL PH ON PH.PO_HEADER_ID = PDA.PO_HEADER_ID
 WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
   AND GJH.PERIOD_NAME IN ('OCT-25', 'NOV-25')
 GROUP BY GJH.PERIOD_NAME, PDA.PO_DISTRIBUTION_ID, PH.SEGMENT1, 
          PDA.CREATION_DATE, XAH.ACCOUNTING_DATE, XAH.PERIOD_NAME
 ORDER BY 1, 3;

-- ===============================================================================
-- DIAGNOSTIC ÉTAPE 4 : Vérifier le naming des batches
-- ===============================================================================

-- D. Analyser la structure des noms de batch PROVISION
SELECT SUBSTR(GJB.NAME, 1, 9) AS PREFIX,
       GJB.NAME,
       GJB.DEFAULT_PERIOD_NAME,
       GJH.PERIOD_NAME,
       COUNT(*) AS NB_JOURNALS
  FROM GL.GL_JE_BATCHES GJB
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_BATCH_ID = GJB.JE_BATCH_ID
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJH.LEDGER_ID
 WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJH.PERIOD_NAME IN ('OCT-25', 'NOV-25')
 GROUP BY SUBSTR(GJB.NAME, 1, 9), GJB.NAME, GJB.DEFAULT_PERIOD_NAME, GJH.PERIOD_NAME
 ORDER BY GJB.DEFAULT_PERIOD_NAME, GJH.PERIOD_NAME;

-- ===============================================================================
-- SOLUTION PROPOSÉE : Requête corrigée avec filtres additionnels
-- ===============================================================================

-- VERSION CORRIGÉE #1 : Filtrer strictement sur la période GL NOV-25
-- (Élimine les écritures d'autres périodes même si le batch indique NOV-25)

SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       PDA.PO_DISTRIBUTION_ID,
       GJL.LEDGER_ID,
       PDA.ORG_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME AS GL_PERIOD,
       XAH.PERIOD_NAME AS XLA_PERIOD,
       TO_CHAR(XAH.ACCOUNTING_DATE, 'DD/MM/YYYY') AS XLA_ACCT_DATE
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 LEFT OUTER JOIN XLA.XLA_AE_HEADERS XAH
     ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 LEFT OUTER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE GJH.PERIOD_NAME = 'NOV-25'  -- Filtre principal
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND GJL.GL_SL_LINK_ID IS NOT NULL
   AND PDA.PO_DISTRIBUTION_ID IS NOT NULL
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
   AND XAH.PERIOD_NAME = 'NOV-25'  -- *** FILTRE ADDITIONNEL : Période XLA ***

UNION ALL

SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       PDA.PO_DISTRIBUTION_ID,
       GJL.LEDGER_ID,
       PDA.ORG_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME AS GL_PERIOD,
       XAH.PERIOD_NAME AS XLA_PERIOD,
       TO_CHAR(XAH.ACCOUNTING_DATE, 'DD/MM/YYYY') AS XLA_ACCT_DATE
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 LEFT OUTER JOIN GL.GL_IMPORT_REFERENCES GIR
     ON (GIR.JE_HEADER_ID = GJL.JE_HEADER_ID
         AND GIR.JE_LINE_NUM = GJL.JE_LINE_NUM)
 LEFT OUTER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GIR.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 LEFT OUTER JOIN XLA.XLA_AE_HEADERS XAH
     ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 LEFT OUTER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE GJH.PERIOD_NAME = 'NOV-25'  -- Filtre principal
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND GJL.GL_SL_LINK_ID IS NULL
   AND PDA.PO_DISTRIBUTION_ID IS NOT NULL
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
   AND (GJL.ENTERED_DR IS NOT NULL AND GJL.ENTERED_DR <> 0)
   AND XAH.PERIOD_NAME = 'NOV-25'  -- *** FILTRE ADDITIONNEL : Période XLA ***
ORDER BY 1, 2;

-- ===============================================================================
-- EXPLICATION DES CAUSES POSSIBLES
-- ===============================================================================

/*
RAISONS POUR LESQUELLES VOUS OBTENEZ DES DONNÉES OCT-25 :

1. **DÉCALAGE ENTRE PÉRIODES GL ET XLA**
   - Un journal peut être posté dans GL en période NOV-25
   - Mais les écritures XLA sources peuvent avoir une date comptable en OCT-25
   - Cela arrive lors de comptabilisations rétroactives ou d'ajustements

2. **CONDITION "GJB.default_period_name = gjh.period_name" PERMISSIVE**
   - Cette condition valide que le batch et le header sont cohérents
   - MAIS ne garantit pas que les écritures XLA sous-jacentes soient dans la même période
   - Un batch "PROVISION_NOV-25" peut contenir des écritures XLA d'octobre

3. **PROCESSUS "RECEIPT ACCRUALS - PERIOD-END"**
   - Visible dans le rapport de clôture (46361435-46362197)
   - Ce processus peut créer des provisions pour des réceptions passées
   - Les écritures GL sont en NOV-25 mais référencent des PO d'OCT-25

4. **AJUSTEMENTS POST-CLÔTURE OCT-25**
   - Des ajustements sur OCT-25 peuvent avoir été comptabilisés en NOV-25
   - La période GL est NOV-25 mais la période source (XLA) reste OCT-25

5. **REPRISES DE PROVISIONS**
   - Une provision OCT-25 peut être reprise en NOV-25
   - Le lien XLA pointe vers la distribution PO originale (OCT-25)
   - Mais la période GL de l'extourne est NOV-25

SOLUTION :
Ajouter le filtre XAH.PERIOD_NAME = 'NOV-25' pour garantir que TOUTES les couches
(GL, XLA, et PO) sont cohérentes avec la période recherchée.
*/

-- ===============================================================================
-- VERSION ALTERNATIVE : Comprendre TOUTES les périodes impliquées
-- ===============================================================================

-- VERSION CORRIGÉE #2 : Afficher toutes les périodes pour comprendre les écarts

SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       GJB.NAME AS BATCH_NAME,
       GJB.DEFAULT_PERIOD_NAME AS BATCH_PERIOD,
       GJH.PERIOD_NAME AS JOURNAL_PERIOD,
       XAH.PERIOD_NAME AS XLA_PERIOD,
       TO_CHAR(XAH.ACCOUNTING_DATE, 'DD/MM/YYYY') AS XLA_DATE,
       TO_CHAR(GJH.DEFAULT_EFFECTIVE_DATE, 'DD/MM/YYYY') AS GL_EFFECTIVE_DATE,
       PDA.PO_DISTRIBUTION_ID,
       GJL.LEDGER_ID,
       PDA.ORG_ID,
       CASE 
           WHEN GJH.PERIOD_NAME = XAH.PERIOD_NAME THEN 'OK'
           ELSE '⚠️ DÉCALAGE'
       END AS PERIOD_STATUS
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 INNER JOIN XLA.XLA_AE_HEADERS XAH ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 INNER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 INNER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE GJH.PERIOD_NAME = 'NOV-25'  -- Journal en NOV-25
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
   -- SANS FILTRE SUR XAH.PERIOD_NAME pour voir les décalages
ORDER BY GJH.PERIOD_NAME, XAH.PERIOD_NAME, GJL.JE_HEADER_ID, GJL.JE_LINE_NUM;

-- ===============================================================================
-- RECOMMANDATIONS
-- ===============================================================================

/*
À FAIRE IMMÉDIATEMENT :

1. Exécuter le DIAGNOSTIC ÉTAPE 1 pour identifier les batches concernés
2. Exécuter le DIAGNOSTIC ÉTAPE 2 pour quantifier les décalages GL vs XLA
3. Exécuter la VERSION ALTERNATIVE pour voir TOUTES les périodes impliquées

ENSUITE :

4. Si vous voulez UNIQUEMENT les écritures NOV-25 pures :
   → Utiliser VERSION CORRIGÉE #1 avec filtre XAH.PERIOD_NAME = 'NOV-25'

5. Si vous voulez comprendre les ajustements rétroactifs :
   → Utiliser VERSION CORRIGÉE #2 et filtrer sur PERIOD_STATUS = '⚠️ DÉCALAGE'

6. Vérifier dans le contexte de la clôture (Rapport_Cloture_AR_Novembre_2025.md) :
   → Les processus "Receipt Accruals" (23:39 - 01:12) ont-ils créé des provisions rétroactives ?
   → Y a-t-il eu des ajustements manuels sur OCT-25 après sa clôture ?

QUESTIONS À POSER À L'ÉQUIPE FINANCE :

- Est-il normal d'avoir des provisions NOV-25 qui référencent des PO d'OCT-25 ?
- Y a-t-il eu des ajustements post-clôture sur OCT-25 en date du 28/11/2025 ?
- Le processus "Receipt Accruals - Period-End" doit-il provisionner les réceptions passées ?
*/
