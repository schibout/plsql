-- 1. Vérifier les versions des objets XLA/CST modifiés récemment
SELECT object_name, object_type, last_ddl_time
FROM dba_objects
WHERE owner IN ('XLA', 'CST', 'RCV')
  AND object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND last_ddl_time > TO_DATE('01-OCT-2025', 'DD-MON-YYYY')
ORDER BY last_ddl_time DESC;

-- 2. Vérifier les patches appliqués récemment
SELECT patch_name, patch_type, creation_date
FROM ad_applied_patches
WHERE creation_date > TO_DATE('01-OCT-2025', 'DD-MON-YYYY')
ORDER BY creation_date DESC;

-- 3. Comparer les colonnes peuplées entre OCT et NOV
SELECT 
    TRUNC(xah.accounting_date, 'MM') as period,
    COUNT(*) as total_lines,
    COUNT(xdl.applied_to_dist_id_num_1) as with_po_dist_id,
    COUNT(*) - COUNT(xdl.applied_to_dist_id_num_1) as without_po_dist_id
FROM xla_ae_headers xah
JOIN xla_distribution_links xdl ON xdl.ae_header_id = xah.ae_header_id
WHERE xah.application_id = 707
  AND xah.event_type_code = 'PERIOD_END_ACCRUAL_ALL'
  AND xdl.source_distribution_type = 'RCV_RECEIVING_SUB_LEDGER'
  AND xah.accounting_date >= TO_DATE('01-OCT-2025', 'DD-MON-YYYY')
GROUP BY TRUNC(xah.accounting_date, 'MM')
ORDER BY 1;

-- 4. Vérifier si REFERENCE3 dans RCV_RECEIVING_SUB_LEDGER contient toujours le PO_DISTRIBUTION_ID
SELECT 
    period_name,
    COUNT(*) as total,
    COUNT(reference3) as with_po_dist
FROM rcv_receiving_sub_ledger rrsl
WHERE period_name IN ('OCT-25', 'NOV-25')
  AND accrual_method_flag = 'P'
GROUP BY period_name;