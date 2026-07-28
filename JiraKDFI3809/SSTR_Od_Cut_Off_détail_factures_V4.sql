  WITH 
  INVOICE_DETAILS AS (
    -- Cette CTE récupère les détails de facturation par ligne de distribution de commande.
    -- C'est plus précis et performant que de joindre par N° de commande.
    SELECT
      AIDA.PO_DISTRIBUTION_ID,
      AIA.INVOICE_NUM,
      AIA.INVOICE_DATE,
      SUM(CASE WHEN AIDA.POSTED_FLAG = 'Y' THEN AIDA.AMOUNT ELSE 0 END) AS POSTED_AMOUNT,
      SUM(CASE WHEN AIDA.POSTED_FLAG != 'Y' THEN AIDA.AMOUNT ELSE 0 END) AS UNPOSTED_AMOUNT
    FROM AP.AP_INVOICE_DISTRIBUTIONS_ALL AIDA
    JOIN AP.AP_INVOICES_ALL AIA ON AIA.INVOICE_ID = AIDA.INVOICE_ID
    WHERE AIDA.PO_DISTRIBUTION_ID IS NOT NULL
      AND NVL(AIDA.LINE_TYPE_LOOKUP_CODE, 'ITEM') NOT IN ('PREPAY', 'REC_TAX', 'NONREC_TAX')
    GROUP BY
      AIDA.PO_DISTRIBUTION_ID,
      AIA.INVOICE_NUM,
      AIA.INVOICE_DATE
  ),
  CONTRACT as (select PHA.ORG_ID,
                      PHA.SEGMENT1,
                      PHA.REVISION_NUM,
                      PHA.ATTRIBUTE14 ,
                      PIVOT.PO_HEADER_ID,
                      PHAA.PO_HEADER_ID CTRID  ,
                      PHAA.SEGMENT1 NUMCTR,
                      PHAA.REVISION_NUM REVCTR ,
                      PHAA.START_DATE, 
                      PHAA.END_DATE,
                      PHAA.BLANKET_TOTAL_AMOUNT, 
                      PHAA.AUTHORIZATION_STATUS, 
                      PHAA.CLOSED_CODE, 
                      PHAA.USER_HOLD_FLAG ,
                      ASU.SEGMENT1 VENDOR_NUM,
                      ASU.VENDOR_NAME,
                      ASSA.VENDOR_SITE_CODE
            from PO.PO_HEADERS_ALL PHA 
                ,(select DCSA.PO_HEADER_ID, 
                         max(DCSA.REVISION_NUM) REVISION_NUM ,
                         DCSA.COMMANDE_ID ,
                         DCSA.COMMANDE_VERSION
                    from DKA.DKA_CONTRAT_SSTR_ARCHI DCSA 
                    group by DCSA.PO_HEADER_ID,
                             DCSA.COMMANDE_ID ,
                             DCSA.COMMANDE_VERSION ) PIVOT
                ,AP.AP_SUPPLIERS ASU
                ,AP.AP_SUPPLIER_SITES_ALL ASSA
                ,PO.PO_HEADERS_ARCHIVE_ALL PHAA
            where PHA.SEGMENT1 like '%ST%'
              and PHA.TYPE_LOOKUP_CODE = 'STANDARD'
              and ASU.VENDOR_ID = PHA.VENDOR_ID
              and ASSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID
            --where PHA.SEGMENT1 in ('1705731ST1006','1416996ST2010','1700697ST1009','1723668ST1007')
            and PIVOT.COMMANDE_ID = PHA.PO_HEADER_ID
            and PIVOT.COMMANDE_VERSION = PHA.REVISION_NUM
            and PHAA.PO_HEADER_ID = PIVOT.PO_HEADER_ID
            and PHAA.REVISION_NUM = PIVOT.REVISION_NUM
            )
  SELECT HAOU.NAME "UO",
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
         decode(CONTRACT.ATTRIBUTE14,'OUI','Oui','Non') "Prest Unit.",
         DCS.RECONDUCTION_NUM "Période",
         CONTRACT.AUTHORIZATION_STATUS "Statut approbation Ctr",
         CONTRACT.CLOSED_CODE "Statut fermeture Ctr",
         PHA.SEGMENT1 "Commande",
         PHA.REVISION_NUM "V",
         decode(PHA.ATTRIBUTE13,'OUI','OUI','NON') "Pmt Dir Cde",
         PHA.AUTHORIZATION_STATUS "Statut approbation Cde",
         PHA.CLOSED_CODE "Statut fermeture Cde",
         trunc(PHA.CLOSED_DATE) "Date fermeture",
         gjl.entered_dr "Débit",
         GJL.ENTERED_CR "Crédit",
         GJL.ATTRIBUTE13 "Type de dépense",
         GJH.NAME "Nom de la pièce",
         GJL.DESCRIPTION "Description",
         GJL.JE_LINE_NUM "Ligne",
         NVL(CONTRACT.START_DATE, PHA.START_DATE) "Date début",
         NVL(CONTRACT.END_DATE, PHA.END_DATE) "Date fin",
         ROUND(MONTHS_BETWEEN(CONTRACT.END_DATE,CONTRACT.START_DATE ),0) "Mois période" ,
         ROUND(MONTHS_BETWEEN(GP.END_DATE,CONTRACT.START_DATE ),0) "Mois arrété",
         DCS.PERIODICITE_FACTURATION "Nbre Fac attendues",
         PLLA.QUANTITY "Qte Cde",
         PLLA.QUANTITY_RECEIVED "Qte rcv",
         PLLA.QUANTITY_BILLED "Qte Fac",
         INVOICE_DETAILS.INVOICE_NUM "Num Fact", 
         INVOICE_DETAILS.INVOICE_DATE "Date Fact",
         INVOICE_DETAILS.POSTED_AMOUNT "Montant Compta",
         INVOICE_DETAILS.UNPOSTED_AMOUNT "Montant non Compta",
         NVL(CONTRACT.VENDOR_NUM, ASU.SEGMENT1) "Code fournisseur",
         NVL(CONTRACT.VENDOR_NAME, ASU.VENDOR_NAME) "Nom fournisseur",
         NVL(CONTRACT.VENDOR_SITE_CODE, ASSA.VENDOR_SITE_CODE) "Code site"
    FROM GL.GL_JE_LINES GJL
       inner join GL.GL_LEDGERS GLE on GLE.LEDGER_ID = GJL.LEDGER_ID
       inner join GL.GL_JE_HEADERS GJH on GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
        left outer join gl.gl_import_references gir on  (GIR.JE_HEADER_ID = GJL.JE_HEADER_ID 
                                                       and gir.JE_LINE_NUM = GJL.JE_LINE_NUM) 
        inner join GL.GL_PERIODS GP on (GP.PERIOD_SET_NAME = 'GROUPE' and GP.PERIOD_NAME = gjh.period_name)
        inner join GL.gl_code_combinations gcc on GCC.CODE_COMBINATION_ID = GJL.CODE_COMBINATION_ID
        left outer join PO.PO_DISTRIBUTIONS_ALL PDA on PDA.PO_DISTRIBUTION_ID = GIR.REFERENCE_3 
        left outer join PA.PA_TASKS PTA on PTA.TASK_ID = PDA.TASK_ID
        left outer join hr.hr_all_organization_units haou on haou.organization_id = PDA.ORG_ID
        left outer join PO.PO_headers_all PHA on PHA.PO_HEADER_ID = PDA.PO_HEADER_ID 
        left outer join AP.AP_SUPPLIERS ASU on ASU.VENDOR_ID = PHA.VENDOR_ID 
        left outer join AP.AP_SUPPLIER_SITES_ALL ASSA on ASSA.VENDOR_SITE_ID = PHA.VENDOR_SITE_ID
        left outer join CONTRACT on (CONTRACT.SEGMENT1 = PHA.SEGMENT1
                                and CONTRACT.REVISION_NUM = PHA.REVISION_NUM
                                and CONTRACT.ORG_ID = PHA.ORG_ID)
        left outer join DKA.DKA_CONTRAT_SSTR DCS on DCS.PO_HEADER_ID = CONTRACT.CTRID        
        left outer join PO.PO_LINE_LOCATIONS_ALL PLLA on PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
        left outer join INVOICE_DETAILS on INVOICE_DETAILS.PO_DISTRIBUTION_ID = PDA.PO_DISTRIBUTION_ID
   WHERE GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
         AND gjh.period_name = UPPER ('JUN-26')
         AND GJH.JE_SOURCE = 'Purchasing'
         -- Remplacement de 8 'OR' par une seule expression régulière pour la lisibilité et la maintenance.
         AND REGEXP_LIKE(GJH.NAME, '^C.*(DRW|DCW|DEW|DOS|DNA|DLS|DMS|DSW) OD A CONTREPASSATION EUR$')
ORDER BY "ste", "Commande", "Num Fact"
;