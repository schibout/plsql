WITH
    INVOICE
    AS
        (  SELECT /*+ MATERIALIZE */
                  PDA.PO_DISTRIBUTION_ID,
                  SUM (
                        DECODE (AIDA.POSTED_FLAG, 'Y', 1, 0)
                      * nvl(AIDA.QUANTITY_INVOICED,0))
                      POSTED_QTY,
                  SUM (
                        DECODE (AIDA.POSTED_FLAG, 'Y', 0, 1)
                      * nvl(AIDA.QUANTITY_INVOICED,0))
                      UNPOSTED_QTY
             FROM AP.AP_INVOICE_DISTRIBUTIONS_ALL AIDA
                  INNER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
                      ON PDA.PO_DISTRIBUTION_ID = AIDA.PO_DISTRIBUTION_ID
                  INNER JOIN PO.PO_HEADERS_ALL PHA
                      ON PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
            WHERE PHA.CLOSED_CODE <> 'FINALLY CLOSED'
           HAVING SUM (nvl(AIDA.QUANTITY_INVOICED,0)) <> 0
         GROUP BY PDA.PO_DISTRIBUTION_ID),
    PEOPLE
    AS
        (SELECT /*+ MATERIALIZE */
                PERSON_ID, EMPLOYEE_NUMBER, FULL_NAME
           FROM (SELECT PAPF.PERSON_ID,
                        PAPF.EMPLOYEE_NUMBER,
                        PAPF.FULL_NAME,
                        ROW_NUMBER () OVER (PARTITION BY PAPF.PERSON_ID
                                            ORDER BY PAPF.EFFECTIVE_END_DATE DESC) AS RN
                   FROM HR.PER_ALL_PEOPLE_F PAPF
                  WHERE PAPF.PERSON_TYPE_ID IN (6, 125))
          WHERE RN = 1)
  -- GJL.GL_SL_LINK_ID is not null
  SELECT 
  haou.NAME
             "UO",
         gcc.segment1
             "ste",
         gcc.segment2
             "région",
         gcc.segment3
             "Cpt local",
         gcc.segment4
             "Cpt groupe",
         GCC.SEGMENT5
             "Interco",
         gcc.segment6
             "Centre finance",
         gcc.segment7
             "Affaire",
         gcc.segment8
             "projet",
         GJH.CURRENCY_CODE
             "Devise",
         SUM (gjl.entered_dr)
             "Montant",
         pha.segment1
             "num cde",
         PHA.REVISION_NUM
             "V.",
         PHA.ATTRIBUTE6
             "Envoi",
         PHA.ATTRIBUTE13
             "Pmt Dir",
         PLA.ATTRIBUTE2
             "CUF",
         PHA.ATTRIBUTE9
             "Rouvert",
         NULL
             "M/L",
         SUM (pla.UNIT_PRICE * nvl(pda.QUANTITY_ORDERED,0))
             "Valeur cde",
         SUM (nvl(PDA.QUANTITY_ORDERED,0))
             "Qté Cde.",
         SUM (nvl(PDA.QUANTITY_CANCELLED,0))
             "Qté Annul.",
         SUM (nvl(PDA.QUANTITY_DELIVERED,0))
             "Qté reçue",
         SUM (nvl(INVOICE.POSTED_QTY,0))
             "Qté Fact.",
         SUM (nvl(INVOICE.UNPOSTED_QTY,0))
             "Qté Non Cpta",
         pha.creation_date
             "date cde",
            TO_CHAR (pha.creation_date, 'YYYY')
         || '.'
         || DECODE (TO_CHAR (pha.creation_date, 'MM'),
                    '01', '1',
                    '02', '1',
                    '03', '1',
                    '04', '1',
                    '05', '1',
                    '06', '1',
                    '07', '2',
                    '08', '2',
                    '09', '2',
                    '10', '2',
                    '11', '2',
                    '12', '2')
             "Periode",
         pv.segment1
             "code fourn",
         pv.vendor_name
             "fournisseur",
         PVSA.VENDOR_SITE_CODE
             "Site",
         haou1.name
             "UO Projet",
         ppa.segment1
             "projet po",
         PT.TASK_NUMBER
             "Num tâche",
         CASE
             WHEN ppa.attribute8 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (ppa.attribute8, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END
             "Date clôture projet",
         CASE
             WHEN PT.attribute2 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (PT.attribute2, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END
             "Date clôture tâche",
         PEOPLE.EMPLOYEE_NUMBER
             "Demandeur",
         PEOPLE.FULL_NAME
             "Nom demandeur",
         CASE
             WHEN substr(HAOU.NAME,4,4)=substr(HAOU1.NAME,4,4)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END
             "Inter société",
         CASE
             WHEN substr(HAOU.NAME,1,3)=substr(HAOU1.NAME,1,3)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END
             "Inter région"
    FROM gl.gl_je_lines gjl
         INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
         INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
         INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
         INNER JOIN GL.GL_CODE_COMBINATIONS GCC
             ON GCC.CODE_COMBINATION_ID = GJL.CODE_COMBINATION_ID
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
         LEFT OUTER JOIN po.PO_LINES_ALL PLA ON pla.PO_LINE_ID = pda.PO_LINE_ID
         LEFT OUTER JOIN po.po_headers_all pha
             ON pha.po_header_id = PDA.po_header_id
         LEFT OUTER JOIN INVOICE
             ON INVOICE.PO_DISTRIBUTION_ID = PDA.PO_DISTRIBUTION_ID
         LEFT OUTER JOIN AP.AP_SUPPLIERS pv ON pv.vendor_id = pha.vendor_id
         LEFT OUTER JOIN AP.AP_SUPPLIER_SITES_ALL pvsa
             ON PVSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID
         LEFT OUTER JOIN PA.pa_projects_all ppa
             ON ppa.project_id = pda.project_id
         LEFT OUTER JOIN PA.PA_TASKS PT ON PT.TASK_ID = PDA.TASK_ID
         LEFT OUTER JOIN PEOPLE ON PEOPLE.PERSON_ID = PHA.AGENT_ID
         LEFT OUTER JOIN hr.hr_all_organization_units haou
             ON haou.organization_id = PDA.ORG_ID
         LEFT OUTER JOIN hr.hr_all_organization_units haou1
             ON haou1.organization_id = PPA.ORG_ID
   WHERE     gjh.period_name = UPPER ('AVR-26')
         AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
         AND gjh.je_source = 'Cost Management'
      --   and gjh.je_header_id =20969361
         AND gjh.je_category = 'Accrual'
         AND GJL.GL_SL_LINK_ID IS NOT NULL
         AND GJB.NAME LIKE 'PROVISION\_%%\_AVR-26\_%%' ESCAPE '\'
GROUP BY 
haou.NAME,
         gcc.segment1,
         gcc.segment2,
         gcc.segment3,
         gcc.segment4,
         GCC.SEGMENT5,
         gcc.segment6,
         gcc.segment7,
         gcc.segment8,
         GJH.CURRENCY_CODE,
         pha.segment1,
         PHA.REVISION_NUM,
         PHA.ATTRIBUTE6,
         PHA.ATTRIBUTE13,
         PLA.ATTRIBUTE2,
         PHA.ATTRIBUTE9,
         NULL,
         pha.creation_date,
            TO_CHAR (pha.creation_date, 'YYYY')
         || '.'
         || DECODE (TO_CHAR (pha.creation_date, 'MM'),
                    '01', '1',
                    '02', '1',
                    '03', '1',
                    '04', '1',
                    '05', '1',
                    '06', '1',
                    '07', '2',
                    '08', '2',
                    '09', '2',
                    '10', '2',
                    '11', '2',
                    '12', '2'),
         pv.segment1,
         pv.vendor_name,
         PVSA.VENDOR_SITE_CODE,
         haou1.name,
         ppa.segment1,
         PT.TASK_NUMBER,
         CASE
             WHEN ppa.attribute8 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (ppa.attribute8, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         CASE
             WHEN PT.attribute2 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (PT.attribute2, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         PEOPLE.EMPLOYEE_NUMBER,
         PEOPLE.FULL_NAME,
         CASE
             WHEN substr(HAOU.NAME,4,4)=substr(HAOU1.NAME,4,4)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END,
         CASE
             WHEN substr(HAOU.NAME,1,3)=substr(HAOU1.NAME,1,3)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END
UNION ALL
  -- GJL.GL_SL_LINK_ID is null
  SELECT 
  haou.NAME,
         gcc.segment1,
         gcc.segment2,
         gcc.segment3,
         gcc.segment4,
         GCC.SEGMENT5,
         gcc.segment6,
         gcc.segment7,
         gcc.segment8,
         GJH.CURRENCY_CODE,
         SUM (
             ROUND (
                   ((  nvl(PLLA.QUANTITY_RECEIVED,0)
                    - nvl(PLLA.QUANTITY_BILLED,0)
                    + nvl(INVOICE.UNPOSTED_QTY,0))
                 * PLA.UNIT_PRICE),
                 2)),
         pha.segment1,
         PHA.REVISION_NUM,
         PHA.ATTRIBUTE6,
         PHA.ATTRIBUTE13,
         PLA.ATTRIBUTE2,
         PHA.ATTRIBUTE9,
         'OUI',
         SUM (pla.UNIT_PRICE * nvl(pda.QUANTITY_ORDERED,0)),
         SUM (nvl(PDA.QUANTITY_ORDERED,0)),
         SUM (nvl(PDA.QUANTITY_CANCELLED,0)),
         SUM (nvl(PDA.QUANTITY_DELIVERED,0)),
         SUM (nvl(INVOICE.POSTED_QTY,0)),
         SUM (nvl(INVOICE.UNPOSTED_QTY,0)),
         pha.creation_date,
            TO_CHAR (pha.creation_date, 'YYYY')
         || '.'
         || DECODE (TO_CHAR (pha.creation_date, 'MM'),
                    '01', '1',
                    '02', '1',
                    '03', '1',
                    '04', '1',
                    '05', '1',
                    '06', '1',
                    '07', '2',
                    '08', '2',
                    '09', '2',
                    '10', '2',
                    '11', '2',
                    '12', '2'),
         pv.segment1,
         pv.vendor_name,
         PVSA.VENDOR_SITE_CODE,
         haou1.name,
         ppa.segment1,
         PT.TASK_NUMBER,
         CASE
             WHEN ppa.attribute8 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (ppa.attribute8, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         CASE
             WHEN PT.attribute2 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (PT.attribute2, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         PEOPLE.EMPLOYEE_NUMBER,
         PEOPLE.FULL_NAME,
         CASE
             WHEN substr(HAOU.NAME,4,4)=substr(HAOU1.NAME,4,4)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END,
         CASE
             WHEN substr(HAOU.NAME,1,3)=substr(HAOU1.NAME,1,3)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END
    FROM gl.gl_je_lines gjl
         INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
         INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
         INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
         INNER JOIN GL.GL_CODE_COMBINATIONS GCC
             ON GCC.CODE_COMBINATION_ID = GJL.CODE_COMBINATION_ID
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
         LEFT OUTER JOIN PO.PO_LINE_LOCATIONS_ALL PLLA
             ON PLLA.LINE_LOCATION_ID = pda.LINE_LOCATION_ID
         LEFT OUTER JOIN po.PO_LINES_ALL PLA ON pla.PO_LINE_ID = pda.PO_LINE_ID
         LEFT OUTER JOIN po.po_headers_all pha
             ON pha.po_header_id = PDA.po_header_id
         LEFT OUTER JOIN INVOICE
             ON INVOICE.PO_DISTRIBUTION_ID = PDA.PO_DISTRIBUTION_ID
         LEFT OUTER JOIN AP.AP_SUPPLIERS pv ON pv.vendor_id = pha.vendor_id
         LEFT OUTER JOIN AP.AP_SUPPLIER_SITES_ALL pvsa
             ON PVSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID
         LEFT OUTER JOIN PA.pa_projects_all ppa
             ON ppa.project_id = pda.project_id
         LEFT OUTER JOIN PA.PA_TASKS PT ON PT.TASK_ID = PDA.TASK_ID
         LEFT OUTER JOIN PEOPLE ON PEOPLE.PERSON_ID = PHA.AGENT_ID
         LEFT OUTER JOIN hr.hr_all_organization_units haou
             ON haou.organization_id = PDA.ORG_ID
         LEFT OUTER JOIN hr.hr_all_organization_units haou1
             ON haou1.organization_id = PPA.ORG_ID
   WHERE     gjh.period_name = UPPER ('AVR-26')
 -- and gjh.je_header_id =20969361
         AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
         AND gjh.je_source = 'Cost Management'
         AND gjh.je_category = 'Accrual'
         AND GJL.GL_SL_LINK_ID IS NULL
         AND GJB.NAME LIKE 'PROVISION\_%%\_AVR-26\_%%' ESCAPE '\'
         AND (gjl.entered_dr IS NOT NULL AND gjl.entered_dr <> 0)
GROUP BY haou.NAME,
         gcc.segment1,
         gcc.segment2,
         gcc.segment3,
         gcc.segment4,
         GCC.SEGMENT5,
         gcc.segment6,
         gcc.segment7,
         gcc.segment8,
         GJH.CURRENCY_CODE,
         pha.segment1,
         PHA.REVISION_NUM,
         PHA.ATTRIBUTE6,
         PHA.ATTRIBUTE13,
         PLA.ATTRIBUTE2,
         PHA.ATTRIBUTE9,
         'OUI',
         pha.creation_date,
            TO_CHAR (pha.creation_date, 'YYYY')
         || '.'
         || DECODE (TO_CHAR (pha.creation_date, 'MM'),
                    '01', '1',
                    '02', '1',
                    '03', '1',
                    '04', '1',
                    '05', '1',
                    '06', '1',
                    '07', '2',
                    '08', '2',
                    '09', '2',
                    '10', '2',
                    '11', '2',
                    '12', '2'),
         pv.segment1,
         pv.vendor_name,
         PVSA.VENDOR_SITE_CODE,
         haou1.name,
         ppa.segment1,
         PT.TASK_NUMBER,
         CASE
             WHEN ppa.attribute8 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (ppa.attribute8, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         CASE
             WHEN PT.attribute2 IS NOT NULL
             THEN
                 TO_DATE (SUBSTR (PT.attribute2, 1, 10), 'YYYY/MM/DD')
             ELSE
                 NULL
         END,
         PEOPLE.EMPLOYEE_NUMBER,
         PEOPLE.FULL_NAME,
         CASE
             WHEN substr(HAOU.NAME,4,4)=substr(HAOU1.NAME,4,4)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END,
         CASE
             WHEN substr(HAOU.NAME,1,3)=substr(HAOU1.NAME,1,3)
             THEN
                 'Non'
             ELSE
                 'Oui'
         END
ORDER BY 1, 12