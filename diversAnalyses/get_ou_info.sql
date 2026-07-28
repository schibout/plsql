-- Liste des Operating Units et volume d'activité (Factures AP et Commandes PO)
PROMPT === LISTE DES OPERATING UNITS ET VOLUMES ===
SELECT 
    hou.organization_id as OU_ID,
    hou.name as OU_NAME,
    (SELECT count(*) FROM ap_invoices_all WHERE org_id = hou.organization_id) as NB_INVOICES_TOTAL,
    (SELECT count(*) FROM ap_invoices_all WHERE org_id = hou.organization_id AND creation_date >= TRUNC(SYSDATE - 30)) as NB_INVOICES_LAST_30D,
    (SELECT count(*) FROM po_headers_all WHERE org_id = hou.organization_id) as NB_PO_TOTAL,
    (SELECT count(*) FROM po_headers_all WHERE org_id = hou.organization_id AND creation_date >= TRUNC(SYSDATE - 30)) as NB_PO_LAST_30D
FROM 
    hr_operating_units hou
ORDER BY 
    NB_INVOICES_TOTAL DESC;
