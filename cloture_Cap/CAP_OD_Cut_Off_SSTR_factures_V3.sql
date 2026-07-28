/* Formatted on 29/07/2020 15:00:08 (QP5 v5.326) */
/* Od de Cut Off avec cumul factures AP et Cut off DEC V2 */

WITH CONTRACT AS
 (SELECT PHA.ORG_ID,
         PHA.SEGMENT1,
         PHA.REVISION_NUM,
         PHA.ATTRIBUTE14,
         PIVOT.PO_HEADER_ID,
         PHAA.PO_HEADER_ID         CTRID,
         PHAA.SEGMENT1             NUMCTR,
         PHAA.REVISION_NUM         REVCTR,
         PHAA.START_DATE,
         PHAA.END_DATE,
         PHAA.BLANKET_TOTAL_AMOUNT,
         PHAA.AUTHORIZATION_STATUS,
         PHAA.CLOSED_CODE,
         PHAA.USER_HOLD_FLAG,
         ASU.SEGMENT1              VENDOR_NUM,
         ASU.VENDOR_NAME,
         ASSA.VENDOR_SITE_CODE
    FROM PO.PO_HEADERS_ALL PHA,
         (SELECT DCSA.PO_HEADER_ID,
                 MAX(DCSA.REVISION_NUM) REVISION_NUM,
                 DCSA.COMMANDE_ID,
                 DCSA.COMMANDE_VERSION
            FROM DKA.DKA_CONTRAT_SSTR_ARCHI DCSA
           GROUP BY DCSA.PO_HEADER_ID,
                    DCSA.COMMANDE_ID,
                    DCSA.COMMANDE_VERSION)
  PIVOT, AP.AP_SUPPLIERS ASU, AP.AP_SUPPLIER_SITES_ALL ASSA, PO.PO_HEADERS_ARCHIVE_ALL PHAA
   WHERE PHA.SEGMENT1 LIKE '%ST%'
     AND PHA.TYPE_LOOKUP_CODE = 'STANDARD'
     AND ASU.VENDOR_ID = PHA.VENDOR_ID
     AND ASSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID
     AND PIVOT.COMMANDE_ID = PHA.PO_HEADER_ID
     AND PIVOT.COMMANDE_VERSION = PHA.REVISION_NUM
     AND PHAA.PO_HEADER_ID = PIVOT.PO_HEADER_ID
     AND PHAA.REVISION_NUM = PIVOT.REVISION_NUM
  UNION ALL
  SELECT PHA.ORG_ID,
         PHA.SEGMENT1,
         PHA.REVISION_NUM,
         PHA.ATTRIBUTE14,
         PHA.PO_header_id,
         DSCI.ID_CONTRAT           CTRID,
         DSCI.NUM_CONTRAT          NUMCTR,
         DSCI.VERSION_CONTRAT      REVCTR,
         DSCI.DATE_DEBUT_PERIODE   START_DATE,
         DSCI.DATE_FIN_PERIODE     END_DATE,
         DSCI.MONTANT_CONTRAT      BLANKET_TOTAL_AMOUNT,
         PHAA.AUTHORIZATION_STATUS,
         PHAA.CLOSED_CODE,
         PHAA.USER_HOLD_FLAG,
         ASU.SEGMENT1              VENDOR_NUM,
         ASU.VENDOR_NAME,
         ASSA.VENDOR_SITE_CODE
    FROM PO.PO_HEADERS_ALL PHA,
         DKA_SPO_CONTRAT_SSTR_IVALUA DSCI,
         (SELECT MAX(DCSA.VERSION_CONTRAT) VERSION_CONTRAT,
                 DCSA.ID_COMMANDE,
                 MAX(DCSA.VERSION_COMMANDE) VERSION_COMMANDE,
                 DCSA.NUM_CONTRAT
            FROM DKA_SPO_CONTRAT_SSTR_IVALUA DCSA
           GROUP BY DCSA.ID_COMMANDE, DCSA.NUM_CONTRAT) DSCI1,
         AP.AP_SUPPLIERS ASU,
         AP.AP_SUPPLIER_SITES_ALL ASSA,
         PO.PO_HEADERS_ARCHIVE_ALL PHAA
   WHERE PHA.SEGMENT1 LIKE '%ST%'
     AND PHA.TYPE_LOOKUP_CODE = 'STANDARD'
     AND ASU.VENDOR_ID = PHA.VENDOR_ID
     AND ASSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID   
     and PHA.PO_HEADER_ID = DSCI.ID_COMMANDE  
     and DSCI.VERSION_COMMANDE = PHA.REVISION_NUM   
     and PHAA.PO_HEADER_ID = DSCI.ID_COMMANDE   
     and DSCI.VERSION_COMMANDE = PHAA.REVISION_NUM    
     and DSCI.VERSION_COMMANDE = DSCI1.VERSION_COMMANDE
     and DSCI.VERSION_CONTRAT = DSCI1.VERSION_CONTRAT
     and DSCI.ID_COMMANDE = DSCI1.ID_COMMANDE
     and DSCI.NUM_CONTRAT = DSCI1.NUM_CONTRAT),
INVOICE AS
 (SELECT PDA.LINE_LOCATION_ID,
         COUNT(AIA.INVOICE_NUM) NUM,
         SUM((DECODE(AIDA.POSTED_FLAG, 'Y', 1, 0)) * AIDA.AMOUNT) POSTED_AMOUNT,
         SUM((DECODE(AIDA.POSTED_FLAG, 'Y', 0, 1)) * AIDA.AMOUNT) UNPOSTED_AMOUNT
    FROM AP.AP_INVOICES_ALL AIA
   INNER JOIN AP.AP_INVOICE_DISTRIBUTIONS_ALL AIDA
      ON AIA.INVOICE_ID = AIDA.INVOICE_ID
   INNER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
      ON PDA.PO_DISTRIBUTION_ID = AIDA.PO_DISTRIBUTION_ID
   INNER JOIN PO.PO_HEADERS_ALL PHA
      ON PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
   WHERE NVL(AIDA.LINE_TYPE_LOOKUP_CODE, 'ITEM') NOT IN
         ('PREPAY', 'REC_TAX', 'NONREC_TAX')
     AND PHA.SEGMENT1 LIKE '%ST%'
     AND TO_NUMBER(SUBSTR(AIDA.PERIOD_NAME, 5, 2) ||
                   DECODE(SUBSTR(AIDA.PERIOD_NAME, 1, 3),
                          'JAN',
                          '01',
                          'FEV',
                          '02',
                          'MAR',
                          '03',
                          'AVR',
                          '04',
                          'MAI',
                          '05',
                          'JUN',
                          '06',
                          'JUL',
                          '07',
                          'AOU',
                          '08',
                          'SEP',
                          '09',
                          'OCT',
                          '10',
                          'NOV',
                          '11',
                          'DEC',
                          '12',
                          '00')) <=
         TO_NUMBER(SUBSTR(UPPER('MAR-26'), 5, 2) ||
                   DECODE(SUBSTR(UPPER('MAR-26'), 1, 3),
                          'JAN',
                          '01',
                          'FEV',
                          '02',
                          'MAR',
                          '03',
                          'AVR',
                          '04',
                          'MAI',
                          '05',
                          'JUN',
                          '06',
                          'JUL',
                          '07',
                          'AOU',
                          '08',
                          'SEP',
                          '09',
                          'OCT',
                          '10',
                          'NOV',
                          '11',
                          'DEC',
                          '12',
                          '00'))
   GROUP BY PDA.LINE_LOCATION_ID
   ORDER BY 1, 2)
SELECT HAOU.NAME "OU",
       gcc.segment1 "ste",
       gcc.segment2 "région",
       gcc.segment3 "Cpt local",
       gcc.segment4 "Cpt groupe",
       GCC.SEGMENT5 "Interco",
       gcc.segment6 "Centre finance",
       gcc.segment7 "Affaire",
       gcc.segment8 "projet",
       PTA.TASK_NUMBER "Tâche",
       CONTRACT.NUMCTR "Contrat",
       CONTRACT.REVCTR "R",
       DECODE(CONTRACT.ATTRIBUTE14, 'OUI', 'Oui', 'Non') "Prest Unit.",
       DCS.RECONDUCTION_NUM "Période",
       CONTRACT.AUTHORIZATION_STATUS "Statut approbation Ctr",
       CONTRACT.CLOSED_CODE "Statut fermeture Ctr",
       PHA.SEGMENT1 "Commande",
       PHA.REVISION_NUM "V",
       DECODE(PHA.ATTRIBUTE13, 'OUI', 'OUI', 'NON') "Pmt Dir Cde",
       PHA.AUTHORIZATION_STATUS "Statut approbation Cde",
       PHA.CLOSED_CODE "Statut fermeture Cde",
       TRUNC(PHA.CLOSED_DATE) "Date fermeture",
       gjl.entered_dr "Débit",
       GJL.ENTERED_CR "Crédit",
       GJL.ATTRIBUTE13 "Type de dépense",
       GJH.NAME "Nom de la pièce",
       GJL.DESCRIPTION "Description",
       GJL.JE_LINE_NUM "Ligne",
       CONTRACT.START_DATE "Date début",
       CONTRACT.END_DATE "Date fin",
       ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE, CONTRACT.START_DATE), 0) "Mois période",
       ROUND(MONTHS_BETWEEN(GP.END_DATE, CONTRACT.START_DATE), 0) "Mois arrété",
       CONTRACT.BLANKET_TOTAL_AMOUNT "Valeur Contrat",
       DCS.PERIODICITE_FACTURATION "Nbre Fac attendues",
       CASE
         WHEN ROUND(MONTHS_BETWEEN(GP.END_DATE, CONTRACT.START_DATE), 0) >=
              ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE, CONTRACT.START_DATE),
                    0) THEN
          DCS.PERIODICITE_FACTURATION
         ELSE
          ROUND((ROUND(MONTHS_BETWEEN(GP.END_DATE, CONTRACT.START_DATE), 0) /
                (ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE,
                                       CONTRACT.START_DATE),
                        0) + 1)) * DCS.PERIODICITE_FACTURATION,
                0)
       END "Nbre Fact théorique",
       PLLA.QUANTITY "Qte Cde",
       PLLA.QUANTITY_RECEIVED "Qte rcv",
       PLLA.QUANTITY_BILLED "Qte Fac",
       INVOICE.NUM "Nb Fact",
       SUM(INVOICE.POSTED_AMOUNT) "Montant Compta",
       SUM(INVOICE.UNPOSTED_AMOUNT) "Montant non Compta",
       SUM(CASE
             WHEN CONTRACT.NUMCTR IS NULL OR
                  NVL(CONTRACT.CLOSED_CODE, 'OPEN') NOT LIKE 'OPEN'
             --                      OR NVL (PHA.CLOSED_CODE, 'OPEN') NOT LIKE 'OPEN'
              THEN
              NULL
             WHEN CONTRACT.NUMCTR IS NOT NULL AND
                  NVL(CONTRACT.CLOSED_CODE, 'OPEN') LIKE 'OPEN' AND
                  NVL(PHA.CLOSED_CODE, 'OPEN') LIKE 'FINALLY CLOSED'
                 --                         AND gjl.entered_dr > 0
                  OR (CONTRACT.START_DATE >
                  TO_DATE('31/12/' || GP.PERIOD_YEAR, 'DD/MM/YYYY') OR
                  CONTRACT.END_DATE < GP.YEAR_START_DATE OR
                  CONTRACT.END_DATE < GP.END_DATE) THEN
              0
             WHEN CONTRACT.NUMCTR IS NOT NULL AND
                  NVL(CONTRACT.CLOSED_CODE, 'OPEN') LIKE 'OPEN'
                 --                      AND gjl.entered_dr > 0
                  AND NVL(PHA.CLOSED_CODE, 'OPEN') NOT LIKE 'FINALLY CLOSED' AND
                  (CONTRACT.START_DATE <
                  TO_DATE('31/12/' || GP.PERIOD_YEAR, 'DD/MM/YYYY') AND
                  CONTRACT.END_DATE >= GP.YEAR_START_DATE AND
                  CONTRACT.END_DATE >= GP.END_DATE AND
                  TO_CHAR(CONTRACT.END_DATE, 'YYMM') <=
                  SUBSTR(gjh.period_name, 5, 2) || '12') THEN
              PLLA.QUANTITY - NVL(INVOICE.POSTED_AMOUNT, 0) -
              NVL(gjl.entered_dr, 0) + NVL(gjl.entered_Cr, 0)
             WHEN CONTRACT.NUMCTR IS NOT NULL AND
                  NVL(CONTRACT.CLOSED_CODE, 'OPEN') LIKE 'OPEN'
                 --                      AND gjl.entered_dr > 0
                  AND NVL(PHA.CLOSED_CODE, 'OPEN') NOT LIKE 'FINALLY CLOSED' AND
                  (CONTRACT.START_DATE <
                  TO_DATE('31/12/' || GP.PERIOD_YEAR, 'DD/MM/YYYY') AND
                  CONTRACT.END_DATE >= GP.YEAR_START_DATE AND
                  CONTRACT.END_DATE >= GP.END_DATE AND
                  TO_CHAR(CONTRACT.END_DATE, 'YYMM') >
                  SUBSTR(gjh.period_name, 5, 2) || '12') THEN
              ROUND((PLLA.QUANTITY /
                    ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE, CONTRACT.START_DATE),
                           0) *
                    ROUND(MONTHS_BETWEEN(TO_DATE('31/12/' || GP.PERIOD_YEAR,
                                                  'DD/MM/YYYY'),
                                          CONTRACT.START_DATE),
                           0)) - NVL(INVOICE.POSTED_AMOUNT, 0) -
                    NVL(gjl.entered_dr, 0) + NVL(gjl.entered_cr, 0),
                    2)
             ELSE
              0
           END) "Selene",
       CONTRACT.VENDOR_NUM "Code fournisseur",
       CONTRACT.VENDOR_NAME "Nom fournisseur",
       CONTRACT.VENDOR_SITE_CODE "Code site"
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE
    ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH
    ON GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
  LEFT OUTER JOIN gl.gl_import_references gir
    ON (GIR.JE_HEADER_ID = GJL.JE_HEADER_ID AND
       gir.JE_LINE_NUM = GJL.JE_LINE_NUM)
 INNER JOIN GL.GL_PERIODS GP
    ON (GP.PERIOD_SET_NAME = 'GROUPE' AND GP.PERIOD_NAME = gjh.period_name)
 INNER JOIN GL.gl_code_combinations gcc
    ON GCC.CODE_COMBINATION_ID = GJL.CODE_COMBINATION_ID
  LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
    ON PDA.PO_DISTRIBUTION_ID = GIR.REFERENCE_3
  LEFT OUTER JOIN PA.PA_TASKS PTA
    ON PTA.TASK_ID = PDA.TASK_ID
  LEFT OUTER JOIN hr.hr_all_organization_units haou
    ON haou.organization_id = PDA.ORG_ID
  LEFT OUTER JOIN PO.PO_headers_all PHA
    ON PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
  LEFT OUTER JOIN CONTRACT
    ON (CONTRACT.SEGMENT1 = PHA.SEGMENT1 AND
       CONTRACT.REVISION_NUM = PHA.REVISION_NUM AND
       CONTRACT.ORG_ID = PHA.ORG_ID)
  LEFT OUTER JOIN DKA.DKA_CONTRAT_SSTR DCS
    ON DCS.PO_HEADER_ID = CONTRACT.CTRID
  LEFT OUTER JOIN PO.PO_LINE_LOCATIONS_ALL PLLA
    ON PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
  LEFT OUTER JOIN INVOICE
    ON INVOICE.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
 WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND gjh.period_name = UPPER('MAR-26')
   AND GJH.JE_SOURCE = 'Purchasing'
   AND (GJH.NAME LIKE 'C%DRW OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DCW OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DEW OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DOS OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DNA OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DLS OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DMS OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%DSW OD A CONTREPASSATION EUR' OR
       GJH.NAME LIKE 'C%GFK OD A CONTREPASSATION EUR')
 GROUP BY HAOU.NAME,
          gcc.segment1,
          gcc.segment2,
          gcc.segment3,
          gcc.segment4,
          GCC.SEGMENT5,
          gcc.segment6,
          gcc.segment7,
          gcc.segment8,
          PTA.TASK_NUMBER,
          CONTRACT.NUMCTR,
          CONTRACT.REVCTR,
          DECODE(CONTRACT.ATTRIBUTE14, 'OUI', 'Oui', 'Non'),
          DCS.RECONDUCTION_NUM,
          CONTRACT.AUTHORIZATION_STATUS,
          CONTRACT.CLOSED_CODE,
          PHA.SEGMENT1,
          PHA.REVISION_NUM,
          DECODE(PHA.ATTRIBUTE13, 'OUI', 'OUI', 'NON'),
          PHA.AUTHORIZATION_STATUS,
          PHA.CLOSED_CODE,
          TRUNC(PHA.CLOSED_DATE),
          gjl.entered_dr,
          GJL.ENTERED_CR,
          GJL.ATTRIBUTE13,
          GJH.NAME,
          GJL.DESCRIPTION,
          GJL.JE_LINE_NUM,
          CONTRACT.START_DATE,
          CONTRACT.END_DATE,
          ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE, CONTRACT.START_DATE), 0),
          ROUND(MONTHS_BETWEEN(GP.END_DATE, CONTRACT.START_DATE), 0),
          CONTRACT.BLANKET_TOTAL_AMOUNT,
          DCS.PERIODICITE_FACTURATION,
          PLLA.QUANTITY,
          PLLA.QUANTITY_RECEIVED,
          PLLA.QUANTITY_BILLED,
          INVOICE.NUM,
          CONTRACT.VENDOR_NUM,
          CONTRACT.VENDOR_NAME,
          CONTRACT.VENDOR_SITE_CODE
 ORDER BY 2, 26, 28;
