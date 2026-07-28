-- =====================================================================
-- Requête Provisions Cost Management - Version Corrigée et Compatible
-- =====================================================================
-- Date de création : 01/12/2025
-- Auteur : Analyse automatique
-- Base de données : Oracle EBS 19.25.0.0.0
--
-- PROBLÈME RÉSOLU :
-- Le champ APPLIED_TO_DIST_ID_NUM_1 n'est plus alimenté depuis NOV-25
-- Cette requête fonctionne pour OCT-25 ET NOV-25
--
-- CHANGEMENTS PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Ajout de la jointure vers RCV_TRANSACTIONS
-- 2. Utilisation de COALESCE pour gérer les deux cas (OCT et NOV)
-- 3. Filtre sur RT.TRANSACTION_ID au lieu de PDA.PO_DISTRIBUTION_ID
-- 4. Ajout d'une colonne PO_LINK_SOURCE pour diagnostic
--
-- VOIR : Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md
-- =====================================================================

-- Partie 1 : GJL.GL_SL_LINK_ID is not null
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       RT.TRANSACTION_ID AS RCV_TRANSACTION_ID,
       RT.TRANSACTION_TYPE AS RCV_TRANSACTION_TYPE,
       PDA.PO_DISTRIBUTION_ID,
       POH.SEGMENT1 AS PO_NUMBER,
       GJL.LEDGER_ID,
       RT.ORGANIZATION_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME,
       GJL.ENTERED_DR,
       GJL.ENTERED_CR,
       GJL.ACCOUNTED_DR,
       GJL.ACCOUNTED_CR,
       -- Indicateur de source du lien PO (pour diagnostic)
       CASE 
           WHEN XDL.APPLIED_TO_DIST_ID_NUM_1 IS NOT NULL THEN 'VIA_XLA_APPLIED_TO'
           WHEN RT.PO_DISTRIBUTION_ID IS NOT NULL THEN 'VIA_RCV_TRANSACTIONS'
           ELSE 'NO_PO_LINK'
       END AS PO_LINK_SOURCE,
       XDL.SOURCE_DISTRIBUTION_TYPE,
       XDL.SOURCE_DISTRIBUTION_ID_NUM_1
  FROM GL.GL_JE_LINES GJL
     INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
     INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
     INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
     INNER JOIN XLA.XLA_AE_LINES XAL
         ON (    XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
             AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
             AND XAL.gl_sl_link_table = 'XLAJEL')
     LEFT OUTER JOIN XLA.xla_ae_headers XAH
         ON XAH.ae_header_id = XAL.ae_header_id
     LEFT OUTER JOIN XLA.xla_distribution_links XDL
         ON (    XDL.ae_header_id = XAH.ae_header_id
             AND XDL.ae_line_num = XAL.ae_line_num)
     -- ✅ NOUVELLE JOINTURE : RCV_TRANSACTIONS (source fiable pour tous les mois)
     LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
         ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
         AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'
     -- ✅ JOINTURE CORRIGÉE : Utilise RCV_TRANSACTIONS au lieu de APPLIED_TO
     LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
         ON PDA.PO_DISTRIBUTION_ID = COALESCE(
                XDL.APPLIED_TO_DIST_ID_NUM_1,  -- OCT-25 (si disponible)
                RT.PO_DISTRIBUTION_ID          -- NOV-25 (nouveau chemin obligatoire)
            )
     LEFT OUTER JOIN PO.PO_HEADERS_ALL POH
         ON POH.PO_HEADER_ID = COALESCE(
                PDA.PO_HEADER_ID,              -- Via PO_DISTRIBUTIONS_ALL
                RT.PO_HEADER_ID                -- Direct depuis RCV_TRANSACTIONS
            )
 WHERE     gjh.period_name = 'NOV-25'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NOT NULL
     -- ✅ FILTRE CORRIGÉ : Sur RCV_TRANSACTIONS au lieu de PO_DISTRIBUTIONS
     AND RT.TRANSACTION_ID IS NOT NULL  -- Au lieu de : PDA.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
          AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702

UNION ALL

-- Partie 2 : GJL.GL_SL_LINK_ID is null
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       RT.TRANSACTION_ID AS RCV_TRANSACTION_ID,
       RT.TRANSACTION_TYPE AS RCV_TRANSACTION_TYPE,
       PDA.PO_DISTRIBUTION_ID,
       POH.SEGMENT1 AS PO_NUMBER,
       GJL.LEDGER_ID,
       RT.ORGANIZATION_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME,
       GJL.ENTERED_DR,
       GJL.ENTERED_CR,
       GJL.ACCOUNTED_DR,
       GJL.ACCOUNTED_CR,
       -- Indicateur de source du lien PO (pour diagnostic)
       CASE 
           WHEN XDL.APPLIED_TO_DIST_ID_NUM_1 IS NOT NULL THEN 'VIA_XLA_APPLIED_TO'
           WHEN RT.PO_DISTRIBUTION_ID IS NOT NULL THEN 'VIA_RCV_TRANSACTIONS'
           ELSE 'NO_PO_LINK'
       END AS PO_LINK_SOURCE,
       XDL.SOURCE_DISTRIBUTION_TYPE,
       XDL.SOURCE_DISTRIBUTION_ID_NUM_1
  FROM gl.gl_je_lines gjl
     INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
     INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
     INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
     LEFT OUTER JOIN gl.gl_import_references gir
         ON (    GIR.JE_HEADER_ID = GJL.JE_HEADER_ID
             AND gir.JE_LINE_NUM = GJL.JE_LINE_NUM)
     LEFT OUTER JOIN XLA.XLA_AE_LINES XAL
         ON (    XAL.GL_SL_LINK_ID = GIR.GL_SL_LINK_ID
             AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
             AND XAL.gl_sl_link_table = 'XLAJEL')
     LEFT OUTER JOIN XLA.xla_ae_headers XAH
         ON XAH.ae_header_id = XAL.ae_header_id
     LEFT OUTER JOIN XLA.xla_distribution_links XDL
         ON (    XDL.ae_header_id = XAH.ae_header_id
             AND XDL.ae_line_num = XAL.ae_line_num)
     -- ✅ NOUVELLE JOINTURE : RCV_TRANSACTIONS (source fiable pour tous les mois)
     LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
         ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
         AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'
     -- ✅ JOINTURE CORRIGÉE : Utilise RCV_TRANSACTIONS au lieu de APPLIED_TO
     LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
         ON PDA.PO_DISTRIBUTION_ID = COALESCE(
                XDL.APPLIED_TO_DIST_ID_NUM_1,  -- OCT-25 (si disponible)
                RT.PO_DISTRIBUTION_ID          -- NOV-25 (nouveau chemin obligatoire)
            )
     LEFT OUTER JOIN PO.PO_HEADERS_ALL POH
         ON POH.PO_HEADER_ID = COALESCE(
                PDA.PO_HEADER_ID,              -- Via PO_DISTRIBUTIONS_ALL
                RT.PO_HEADER_ID                -- Direct depuis RCV_TRANSACTIONS (NOV-25)
            )
 WHERE  gjh.period_name = 'NOV-25'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NULL
     -- ✅ FILTRE CORRIGÉ : Sur RCV_TRANSACTIONS au lieu de PO_DISTRIBUTIONS
     AND RT.TRANSACTION_ID IS NOT NULL  -- Au lieu de : PDA.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
          AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702
     AND (gjl.entered_dr IS NOT NULL AND gjl.entered_dr <> 0)

ORDER BY 1, 2 ;

-- =====================================================================
-- RÉSULTATS ATTENDUS :
-- =====================================================================
-- OCT-25 : ~119,931 lignes (au lieu de 62,852 avec l'ancienne requête)
-- NOV-25 : ~116,975 lignes (au lieu de 0 avec l'ancienne requête)
--
-- La colonne PO_LINK_SOURCE vous indiquera :
-- - 'VIA_XLA_APPLIED_TO' : Lien direct via APPLIED_TO (OCT-25 uniquement)
-- - 'VIA_RCV_TRANSACTIONS' : Lien via RCV_TRANSACTIONS (OCT-25 et NOV-25)
-- - 'NO_PO_LINK' : Aucun lien PO trouvé
-- =====================================================================

-- =====================================================================
-- COMPARAISON AVEC L'ANCIENNE REQUÊTE :
-- =====================================================================
-- ANCIENNE (ne fonctionne plus en NOV-25) :
--     LEFT OUTER JOIN po.po_distributions_all pda
--         ON PDA.po_distribution_id = XDL.APPLIED_TO_DIST_ID_NUM_1
--     WHERE ... AND pda.PO_DISTRIBUTION_ID IS NOT NULL
--
-- NOUVELLE (fonctionne OCT-25 et NOV-25) :
--     LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
--         ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
--     LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
--         ON PDA.PO_DISTRIBUTION_ID = COALESCE(
--                XDL.APPLIED_TO_DIST_ID_NUM_1,
--                RT.PO_DISTRIBUTION_ID)
--     WHERE ... AND RT.TRANSACTION_ID IS NOT NULL
-- =====================================================================

-- =====================================================================
-- NOTES TECHNIQUES :
-- =====================================================================
-- 1. APPLIED_TO_DIST_ID_NUM_1 n'est plus alimenté depuis NOV-25
--    Raison : Changement de comportement Oracle XLA (patch/upgrade)
--
-- 2. Les données PO sont toujours disponibles via :
--    XDL.SOURCE_DISTRIBUTION_ID_NUM_1 → RCV_TRANSACTIONS.TRANSACTION_ID
--    RCV_TRANSACTIONS.PO_DISTRIBUTION_ID → PO_DISTRIBUTIONS_ALL
--
-- 3. Le COALESCE permet la compatibilité rétroactive :
--    - OCT-25 : Utilisera APPLIED_TO_DIST_ID_NUM_1 si disponible
--    - NOV-25 : Utilisera RT.PO_DISTRIBUTION_ID obligatoirement
--
-- 4. Pour plus de détails, voir :
--    Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md
-- =====================================================================
