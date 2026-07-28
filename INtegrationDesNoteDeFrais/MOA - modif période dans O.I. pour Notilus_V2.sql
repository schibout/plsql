--======================= Vérification factures dans ORacle Interfaces ======================

-- ============== INTERFACES_Header ===============

SELECT -- distinct (ATTRIBUTE10)
 INVOICE_NUM,
    GL_Date,
    status,
    vendor_id,
    invoice_amount,
    attribute9,
    attribute10,
    invoice_date,
    LAST_UPDATE_DATE,
    ap.*   
FROM
    ap_invoices_interface ap
Where 1 = 1
      --and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20260129233925','NOT01_SRC_FACTURESFOURNISSEURS_20260131231758','NOT01_SRC_FACTURESFOURNISSEURS_20260130234157')
      and ATTRIBUTE9 = 'NOT' 
      --and Status is Null
      --and GL_Date <> '01/04/24'
      and Status = 'REJECTED' 
      --and Status <> 'PROCESSED'
      --and INVOICE_ID in ('432068','432990') 
 
order by Invoice_ID
; --==> 261  lignes

--======== count  ========
SELECT  count(*)
FROM     ap.ap_invoices_interface ap
WHERE    1 = 1 
and ATTRIBUTE9 = 'NOT' 
--and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20251031232203')
and Status <> 'PROCESSED'
--group by INVOICE_NUM --ATTRIBUTE9
;
--======>  lignes d en-tete et 1 pour la pièce du 29/07

--==========================================-Lignes d'interfaces-===================================================
--===================================================--===================================================
SELECT ACCOUNTING_DATE 
,      EXPENDITURE_ITEM_DATE
,      LINE_TYPE_LOOKUP_CODE
,      aili.*
FROM
    ap_invoice_lines_interface aili
Where 1 = 1
and invoice_id in 
        (SELECT  INVOICE_ID 
        FROM ap_invoices_interface ap
        Where 1 = 1
        and ATTRIBUTE9 = 'NOT' 
        --and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20260129233925','NOT01_SRC_FACTURESFOURNISSEURS_20260131231758','NOT01_SRC_FACTURESFOURNISSEURS_20260130234157')
        --and INVOICE_NUM in ('465750')
        --and INVOICE_ID in ('10797266','10797267')
        and Status <> 'PROCESSED'
        --and GL_Date <> '01/03/25'
        )
--and ACCOUNTING_DATE <> '01/03/25'
--and LINE_TYPE_LOOKUP_CODE <> 'TAX'
;
--1475 lignes  
     
        
--===================================================- Update -===================================================-
Select aii.GL_DATE
,      aili.ACCOUNTING_DATE
,      aili.EXPENDITURE_ITEM_DATE
,      aii.INVOICE_ID
,      aii.INVOICE_NUM
,      aili.LINE_TYPE_LOOKUP_CODE
,      aii.*
,      aili.*
from ap_invoices_interface aii
,    AP_INVOICE_LINES_INTERFACE aili
where 1 = 1
and aii.INVOICE_ID = aili.INVOICE_ID
and aii.ATTRIBUTE9 = 'NOT' 
--and aii.Status is NULL
and Status <> 'PROCESSED'
--and aii. ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20250729235426')
--and aili.LINE_TYPE_LOOKUP_CODE = 'TAX'
--and aili.EXPENDITURE_ITEM_DATE is NULL
order by aii.INVOICE_NUM
;

/*
--====== 1 === on modifie ACCOUNTING_DATE    !! ET !!      EXPENDITURE_ITEM_DATE ==============
update  AP_INVOICE_LINES_INTERFACE
set    ACCOUNTING_DATE = '01/02/26'
,      EXPENDITURE_ITEM_DATE = '01/02/26'   -- à ne changer que lorsqu'elle est renseignée (cf. 2)
where 1 = 1 
and invoice_id in 
        (SELECT  INVOICE_ID 
        FROM ap_invoices_interface ap
        Where 1 = 1
        and ATTRIBUTE9 = 'NOT' 
--        and Status is NULL
        and Status <> 'PROCESSED'
--        and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20260129233925','NOT01_SRC_FACTURESFOURNISSEURS_20260131231758','NOT01_SRC_FACTURESFOURNISSEURS_20260130234157')
        )
and LINE_TYPE_LOOKUP_CODE <> 'TAX'            -- à ne changer que lorsqu'elle est renseignée (cf. 2)
and EXPENDITURE_ITEM_DATE is not NULL
;
-- 1170 lignes mises à jour et 6

--====== 2 === QUE lines ======== à faire absolument car sinon seules les lignes avec un EXPENDITURE_ITEM_DATE seront modifiées !!!!
update  AP_INVOICE_LINES_INTERFACE
set    ACCOUNTING_DATE = '01/02/26'
where 1 = 1 
and invoice_id in 
        (SELECT  INVOICE_ID 
        FROM ap_invoices_interface ap
        Where 1 = 1
        and ATTRIBUTE9 = 'NOT' 
--        and Status is NULL
        and Status <> 'PROCESSED'
--        and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20260129233925','NOT01_SRC_FACTURESFOURNISSEURS_20260131231758','NOT01_SRC_FACTURESFOURNISSEURS_20260130234157')
        )
and LINE_TYPE_LOOKUP_CODE = 'TAX'
;
-- 305 lignes mises à jours et 3

--====== 3 ===========
update  AP_INVOICES_INTERFACE
set GL_DATE = '01/02/26'
where 1 = 1
and ATTRIBUTE9 = 'NOT' 
--and Status is NULL
and Status <> 'PROCESSED'
--and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20260129233925','NOT01_SRC_FACTURESFOURNISSEURS_20260131231758','NOT01_SRC_FACTURESFOURNISSEURS_20260130234157')
;  
--261 lignes mises à jour et 1 

*/

commit ;

--==> quid du statut "Rejected" ??  on laisse, on ne fait rien.

-- =========== Vérification 
Select aii.GL_DATE
,      aili.ACCOUNTING_DATE
,      aili.EXPENDITURE_ITEM_DATE
,      aii.Status
,      aii.INVOICE_ID
,      aii.INVOICE_NUM
,      aili.LINE_TYPE_LOOKUP_CODE
,      aii.*
,      aili.*
from ap_invoices_interface aii
,    AP_INVOICE_LINES_INTERFACE aili
where 1 = 1
and aii.INVOICE_ID = aili.INVOICE_ID
and aii.ATTRIBUTE9 = 'NOT' 
and aii.GL_DATE = '01/02/26'
--and aii.Status is NULL
and Status <> 'PROCESSED'
--and aii.ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20241017223104')
--and aili.LINE_TYPE_LOOKUP_CODE = 'TAX'
--and aili.EXPENDITURE_ITEM_DATE is NULL
order by aii.INVOICE_NUM
; -- 11 lignes

SELECT distinct status
FROM
    ap_invoices_interface ap
Where 1 = 1
      --and ATTRIBUTE10 in ('NOT01_SRC_FACTURESFOURNISSEURS_20241017223104')
      --and ATTRIBUTE10 like 'NOT01_SRC_FACTURESFOURNISSEURS_20240%'
      and ATTRIBUTE9 = 'NOT' 
      --and Status is Null
      and GL_Date = '01/11/25'
;

--==> quid du statut "Rejected" ??  on laisse, on ne fait rien. On ne modifie que la date.


Select *
from ap_invoices_interface ap
where Status = 'REJECTED'
and ATTRIBUTE9 = 'NOT' 
;
