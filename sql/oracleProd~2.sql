exec fnd_global.apps_initialize(1323, 50937, 222, 0);
SELECT * FROM (
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       PDA.PO_DISTRIBUTION_ID,
       GJL.LEDGER_ID,
       PDA.ORG_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME
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
     LEFT OUTER JOIN po.po_distributions_all pda
         ON PDA.po_distribution_id = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE     gjh.period_name = 'OCT-25'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NOT NULL
     AND pda.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
--   AND SUBSTR (GJB.NAME,(INSTR (GJB.NAME,'_',1,2)+ 1),6) --HNB 23/09/2024 KDFI-1702
     AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702
UNION ALL
  -- GJL.GL_SL_LINK_ID is null
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       PDA.PO_DISTRIBUTION_ID,
       GJL.LEDGER_ID,
       PDA.ORG_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME
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
     LEFT OUTER JOIN po.po_distributions_all pda
         ON PDA.po_distribution_id = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE  gjh.period_name = 'OCT-25'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NULL
     AND pda.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
--   AND SUBSTR (GJB.NAME,(INSTR (GJB.NAME,'_',1,2)+ 1),6)--HNB 23/09/2024 KDFI-1702
     AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702
     AND (gjl.entered_dr IS NOT NULL AND gjl.entered_dr <> 0)
ORDER BY 1, 2
)WHERE 1 = 1
AND JE_HEADER_ID =20730055