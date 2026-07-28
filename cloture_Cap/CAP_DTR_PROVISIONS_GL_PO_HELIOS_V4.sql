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
   LEFT OUTER JOIN rcv_receiving_sub_ledger     rsl on   xdl.application_id = 707 -- Important: Module Receiving
    AND xdl.source_distribution_type = 'RCV_RECEIVING_SUB_LEDGER'
    AND xdl.source_distribution_id_num_1 = rsl.rcv_sub_ledger_id        
         LEFT OUTER JOIN po.po_distributions_all pda
             ON PDA.po_distribution_id = rsl.reference3
 WHERE     gjh.period_name = 'MAR-26'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NOT NULL
     AND pda.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
     AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702
UNION ALL
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
     LEFT OUTER JOIN rcv_receiving_sub_ledger     rsl on   xdl.application_id = 707 -- Important: Module Receiving
    AND xdl.source_distribution_type = 'RCV_RECEIVING_SUB_LEDGER'
    AND xdl.source_distribution_id_num_1 = rsl.rcv_sub_ledger_id        
         LEFT OUTER JOIN po.po_distributions_all pda
             ON PDA.po_distribution_id = rsl.reference3
 WHERE  gjh.period_name = 'MAR-26'
     AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
     AND gjh.je_source = 'Cost Management'
     AND gjh.je_category = 'Accrual'
     AND GJL.GL_SL_LINK_ID IS NULL
     AND pda.PO_DISTRIBUTION_ID IS NOT NULL
     AND (    SUBSTR (GJB.NAME, 1, 9) = 'PROVISION'
     AND GJB.default_period_name = gjh.period_name) --HNB 23/09/2024 KDFI-1702
     AND (gjl.entered_dr IS NOT NULL AND gjl.entered_dr <> 0)
ORDER BY 1, 2 ;