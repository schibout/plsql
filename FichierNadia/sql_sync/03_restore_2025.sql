-- =====================================================================
-- SCRIPT DE RESTAURATION - Remettre les donnees originales
-- =====================================================================
-- Genere le : 19/02/2026 15:10:00
-- Ce script est un template. Le script final sera genere dynamiquement
-- a partir du fichier de sauvegarde lors de l'execution de RESTORE.
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

-- Le script de restauration sera genere dynamiquement par executer_sql_sync.ps1
-- Il lira le fichier CSV de sauvegarde et generera les UPDATE correspondants

DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SCRIPT TEMPLATE ===');
    DBMS_OUTPUT.PUT_LINE('Ce script doit etre regenere avec les donnees de sauvegarde.');
    DBMS_OUTPUT.PUT_LINE('Utilisez : sync_factures_bo.bat RESTORE 2025');
END;
/

EXIT;
