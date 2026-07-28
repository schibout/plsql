# =====================================================================
# Script d'extraction des factures payées Oracle R12 (PowerShell)
# =====================================================================
# Usage: .\extraction_factures_payees.ps1 -Annee 2026
#        .\extraction_factures_payees.ps1 -Annee 2025
#        .\extraction_factures_payees.ps1 (année courante par défaut)
# =====================================================================

param(
    [int]$Annee = (Get-Date).Year
)

# =====================================================================
# Configuration Oracle EBS Production
# =====================================================================
$ORACLE_USER = "aroux"
$ORACLE_PASSWORD = "GAERFTXF"
$ORACLE_HOST = "prdscanc1pdb03.dalkia.net"
$ORACLE_PORT = "1521"
$ORACLE_SERVICE = "ebs_PDBFINP1"
$ORACLE_DSN = "${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"

# Environnement
$ENVIRONMENT = "PRODUCTION"
$DB_VERSION = "19.25.0.0.0"
$EBS_VERSION = "12.2.13"
$NLS_LANG = "AMERICAN_AMERICA.AL32UTF8"
$NLS_DATE_FORMAT = "DD/MM/YYYY HH24:MI:SS"

# =====================================================================
# Paramètres d'extraction
# =====================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DateDebut = "$Annee-01-01"
$DateFin = "$($Annee + 1)-01-01"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $ScriptDir "factures_payees_${Annee}_${Timestamp}.csv"
$ConnectString = "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  EXTRACTION FACTURES PAYÉES ORACLE R12" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Année              : $Annee"
Write-Host "Période            : du $DateDebut au $DateFin"
Write-Host "Base de données    : ${ORACLE_USER}@${ORACLE_DSN}"
Write-Host "Fichier de sortie  : $OutputFile"
Write-Host "=======================================================================" -ForegroundColor Cyan

# Vérification des variables
if ([string]::IsNullOrEmpty($ORACLE_USER) -or [string]::IsNullOrEmpty($ORACLE_PASSWORD) -or [string]::IsNullOrEmpty($ORACLE_HOST)) {
    Write-Host "ERREUR: Variables de connexion manquantes" -ForegroundColor Red
    exit 1
}

# Fichier SQL temporaire
$SqlFile = Join-Path $ScriptDir "temp_extraction_${Annee}.sql"

# Génération du fichier SQL
$SqlContent = @"
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET TRIMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING ON
SET COLSEP ';'
SET NUMFORMAT 999999999999.99

-- Configuration format CSV
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

SPOOL $($OutputFile -replace '\\', '/')

-- =====================================================================
-- Requête Oracle R12 - Extraction des Factures Payées (VERSION OPTIMISÉE)
-- =====================================================================
-- Date de création : 18/02/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13
--
-- AMÉLIORATION PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Utilisation de JOIN au lieu de EXISTS pour meilleures performances
-- 2. Filtre sur check_date au lieu de last_update_date
-- 3. Colonnes supplémentaires (PAIEMENT_ID, MONTANT_PAIEMENT, DEVISE)
-- 4. Paramétrage par année au lieu de J-1
-- =====================================================================

SELECT    
    aia.invoice_id AS ID_FACTURE,
    aia.invoice_num AS NUM_FACTURE,
    aia.payment_status_flag AS STATUT_PAIEMENT,
    aia.invoice_amount AS MONTANT_FACTURE,
    aia.amount_paid AS MONTANT_PAYE,
    ac.check_id AS PAIEMENT_ID,
    ac.check_number AS NUMERO_PAIEMENT,
    ac.check_date AS DATE_PAIEMENT,
    ac.amount AS MONTANT_PAIEMENT,
    ac.currency_code AS DEVISE,
    aia.last_update_date AS FACTURE_LAST_UPDATE,
    aia.vendor_id AS FOURNISSEUR_ID,
    aia.vendor_site_id AS SITE_FOURNISSEUR_ID
FROM ap_invoices_all aia
JOIN AP_INVOICE_PAYMENTS_all AIP 
    ON aia.INVOICE_ID = AIP.INVOICE_ID
JOIN AP_CHECKS_ALL AC 
    ON AIP.CHECK_ID = AC.CHECK_ID
WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
  AND NVL(aia.AMOUNT_PAID, 0) != 0
  AND aia.invoice_amount != 0
  AND ac.status_lookup_code != 'VOIDED'
  AND ac.check_date >= TO_DATE('$DateDebut', 'YYYY-MM-DD')
  AND ac.check_date < TO_DATE('$DateFin', 'YYYY-MM-DD')
ORDER BY ac.check_date DESC, aia.invoice_id;

SPOOL OFF
EXIT;
"@

$SqlContent | Out-File -FilePath $SqlFile -Encoding UTF8

Write-Host ""
Write-Host "Exécution de la requête SQL..." -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------"

# Détecter quelle commande SQL est disponible
$SqlCmd = $null
foreach ($cmd in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $SqlCmd = $cmd
        Write-Host "Utilisation de: $SqlCmd" -ForegroundColor Green
        break
    }
}

if (-not $SqlCmd) {
    Write-Host "❌ ERREUR: Aucun client Oracle trouvé (sqlcl, sql, ou sqlplus)" -ForegroundColor Red
    Write-Host "Installez SQLcl ou SQL*Plus"
    if (Test-Path $SqlFile) { Remove-Item $SqlFile -Force }
    exit 1
}

# Exécution via SQL client
try {
    $process = Start-Process -FilePath $SqlCmd -ArgumentList "-S", $ConnectString, "@$SqlFile" -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "----------------------------------------------------------------------" -ForegroundColor Green
        Write-Host "✅ EXTRACTION TERMINÉE AVEC SUCCÈS" -ForegroundColor Green
        Write-Host ""
        
        # Statistiques
        if (Test-Path $OutputFile) {
            $NbLignes = (Get-Content $OutputFile | Measure-Object -Line).Lines
            $NbFactures = $NbLignes - 1  # -1 pour l'en-tête
            $TailleFichier = [math]::Round((Get-Item $OutputFile).Length / 1KB, 2)
            
            Write-Host "Nombre de factures : $NbFactures" -ForegroundColor Green
            Write-Host "Taille du fichier  : ${TailleFichier} KB" -ForegroundColor Green
            Write-Host "Fichier généré     : $OutputFile" -ForegroundColor Green
            
            # Afficher les 5 premières lignes
            Write-Host ""
            Write-Host "Aperçu (5 premières factures) :" -ForegroundColor Cyan
            Write-Host "----------------------------------------------------------------------"
            Get-Content $OutputFile -Head 6 | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Host "⚠️  ATTENTION: Fichier de sortie non généré" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "----------------------------------------------------------------------" -ForegroundColor Red
        Write-Host "❌ ERREUR LORS DE L'EXTRACTION" -ForegroundColor Red
        Write-Host "Code retour: $($process.ExitCode)"
    }
}
catch {
    Write-Host "❌ ERREUR: $_" -ForegroundColor Red
}
finally {
    # Nettoyage fichier temporaire
    if (Test-Path $SqlFile) {
        Remove-Item $SqlFile -Force
    }
}

Write-Host "=======================================================================" -ForegroundColor Cyan
