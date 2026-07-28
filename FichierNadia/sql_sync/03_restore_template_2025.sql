-- =====================================================================
-- TEMPLATE DE RESTAURATION
-- =====================================================================
-- Genere le : 19/02/2026 17:15:37
-- Annee : 2025
-- =====================================================================
-- INSTRUCTIONS :
-- 1. Ouvrir le fichier CSV de sauvegarde dans Excel
-- 2. Utiliser ce template pour generer les UPDATE
-- 3. Remplacer les valeurs XXX par les valeurs du CSV
-- =====================================================================

-- Template pour chaque ligne du CSV :
/*
UPDATE ap_invoices_all
SET last_update_date = TO_DATE('YYYY-MM-DD HH24:MI:SS', 'YYYY-MM-DD HH24:MI:SS'),
    last_updated_by = XXX
WHERE invoice_id = XXX;
*/

-- OU utiliser le script PowerShell generer_restore.ps1 avec le fichier CSV

-- Exemple :
-- UPDATE ap_invoices_all SET last_update_date = TO_DATE('2025-11-15 14:30:22', 'YYYY-MM-DD HH24:MI:SS'), last_updated_by = 1234 WHERE invoice_id = 47135;

COMMIT;
