SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET LINESIZE 1000
SET TRIMSPOOL ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SELECT '##RES##0|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.nb_int, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx,
          SUM(aia.invoice_amount)        AS sum_amt
   FROM   APPS.AP_INVOICES_ALL aia
   WHERE  aia.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
     AND  aia.attribute9 = TRIM('GAZ')) q_def
CROSS JOIN
 (SELECT COUNT(DISTINCT aii.invoice_id) AS nb_int,
         SUM(aili.amount)               AS sum_int
  FROM   APPS.AP_INVOICES_INTERFACE aii
  JOIN   APPS.AP_INVOICE_LINES_INTERFACE aili ON aii.invoice_id = aili.invoice_id
  WHERE  aii.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
    AND  aii.attribute9 = TRIM('GAZ')
    AND  NOT EXISTS (
             SELECT 1
             FROM APPS.AP_INTERFACE_REJECTIONS air
             WHERE air.parent_id = aii.invoice_id
               AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
         )
 ) q_int;

SELECT '##RES##1|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.nb_int, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx,
          SUM(aia.invoice_amount)        AS sum_amt
   FROM   APPS.AP_INVOICES_ALL aia
   WHERE  aia.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
     AND  aia.attribute9 = TRIM('HAC')) q_def
CROSS JOIN
 (SELECT COUNT(DISTINCT aii.invoice_id) AS nb_int,
         SUM(aili.amount)               AS sum_int
  FROM   APPS.AP_INVOICES_INTERFACE aii
  JOIN   APPS.AP_INVOICE_LINES_INTERFACE aili ON aii.invoice_id = aili.invoice_id
  WHERE  aii.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
    AND  aii.attribute9 = TRIM('HAC')
    AND  NOT EXISTS (
             SELECT 1
             FROM APPS.AP_INTERFACE_REJECTIONS air
             WHERE air.parent_id = aii.invoice_id
               AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
         )
 ) q_int;

SELECT '##RES##2|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.nb_int, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx,
          SUM(aia.invoice_amount)        AS sum_amt
   FROM   APPS.AP_INVOICES_ALL aia
   WHERE  aia.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
     AND  aia.attribute9 = TRIM('ING')) q_def
CROSS JOIN
 (SELECT COUNT(DISTINCT aii.invoice_id) AS nb_int,
         SUM(aili.amount)               AS sum_int
  FROM   APPS.AP_INVOICES_INTERFACE aii
  JOIN   APPS.AP_INVOICE_LINES_INTERFACE aili ON aii.invoice_id = aili.invoice_id
  WHERE  aii.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
    AND  aii.attribute9 = TRIM('ING')
    AND  NOT EXISTS (
             SELECT 1
             FROM APPS.AP_INTERFACE_REJECTIONS air
             WHERE air.parent_id = aii.invoice_id
               AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
         )
 ) q_int;

SELECT '##DEF##' || aia.invoice_num || '|' || aia.attribute9 || '|' || SUM(aia.invoice_amount)
FROM   APPS.AP_INVOICES_ALL aia
WHERE  aia.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
GROUP BY aia.invoice_num, aia.attribute9;

SELECT '##INT##' || aii.invoice_num || '|' || aii.attribute9 || '|' || SUM(aili.amount)
FROM   APPS.AP_INVOICES_INTERFACE aii
JOIN   APPS.AP_INVOICE_LINES_INTERFACE aili ON aii.invoice_id = aili.invoice_id
WHERE  aii.attribute10 LIKE TRIM('FAC02_SRC_FACTURESFOURNISSEURS_310726-010538') || '%'
  AND  NOT EXISTS (
           SELECT 1
           FROM APPS.AP_INTERFACE_REJECTIONS air
           WHERE air.parent_id = aii.invoice_id
             AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
       )
GROUP BY aii.invoice_num, aii.attribute9;

EXIT;
