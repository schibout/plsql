# =====================================================================
# Script simplifié d'analyse des factures impayées BO
# =====================================================================
param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxFactures = 100
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  ANALYSE FACTURES IMPAYEES BO - Version Simplifiee" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Annee : $Annee | Max factures : $MaxFactures"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# Charger le fichier BO
$FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
if (-not (Test-Path $FichierBO)) {
    Write-Host "ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    exit 1
}

$FacturesBO = Import-Csv -Path $FichierBO -Delimiter ',' -Encoding UTF8 | Where-Object { $_.ID_FACTURE }
if ($MaxFactures -gt 0) {
    $FacturesBO = $FacturesBO | Select-Object -First $MaxFactures
}

$IDsFactures = ($FacturesBO | ForEach-Object { $_.ID_FACTURE } | Sort-Object -Unique) -join ", "

Write-Host "Factures BO chargees : $($FacturesBO.Count)" -ForegroundColor Green
Write-Host ""

# Configuration Oracle
$ORACLE_USER = "aroux"
$ORACLE_PASSWORD = "GAERFTXF"
$ORACLE_DSN = "prdscanc1pdb03.dalkia.net:1521/ebs_PDBFINP1"
$CONNECT_STRING = "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"

# Générer la requête SQL simplifiée
$FichierSortie = Join-Path $ScriptDir "factures_detaillees_${Annee}_${Timestamp}.csv"
$FichierSortieOracle = $FichierSortie.Replace('\', '/')

$RequeteSQL = @"
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ';'

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

SPOOL $FichierSortieOracle

PROMPT ID_FACTURE;NUM_FACTURE;MONTANT_FACTURE;MONTANT_PAYE;STATUT_PAIEMENT;DATE_FACTURE;FOURNISSEUR;SITE;DATE_ANNULATION;DATE_MAJ

SELECT
    aia.invoice_id || ';' ||
    aia.invoice_num || ';' ||
    aia.invoice_amount || ';' ||
    NVL(aia.amount_paid, 0) || ';' ||
    aia.payment_status_flag || ';' ||
    aia.invoice_date || ';' ||
    aps.vendor_name || ';' ||
    apss.vendor_site_code || ';' ||
    NVL(TO_CHAR(aia.cancelled_date, 'DD/MM/YYYY'), '') || ';' ||
    aia.last_update_date AS LIGNE
FROM ap_invoices_all aia
LEFT JOIN ap_suppliers aps ON aia.vendor_id = aps.vendor_id
LEFT JOIN ap_supplier_sites_all apss ON aia.vendor_site_id = apss.vendor_site_id
WHERE aia.invoice_id IN ($IDsFactures)
ORDER BY aia.last_update_date DESC;

SPOOL OFF
EXIT;
"@

$FichierSQL = Join-Path $ScriptDir "temp_analyse_simple.sql"
$RequeteSQL | Out-File -FilePath $FichierSQL -Encoding ASCII

Write-Host "Execution de la requete Oracle..." -ForegroundColor Yellow

# Détecter le client SQL
$SQL_CMD = $null
if (Get-Command sqlcl -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sqlcl"
} elseif (Get-Command sql -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sql"
} elseif (Get-Command sqlplus -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sqlplus"
}

if (-not $SQL_CMD) {
    Write-Host "ERREUR: Aucun client Oracle trouve" -ForegroundColor Red
    exit 1
}

& $SQL_CMD -S $CONNECT_STRING "@$FichierSQL"

if (Test-Path $FichierSortie) {
    $Resultats = Import-Csv -Path $FichierSortie -Delimiter ';' -Encoding UTF8
    $NbResultats = $Resultats.Count
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  RESULTATS" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "Factures extraites : $NbResultats" -ForegroundColor Green
    
    $NbPayees = ($Resultats | Where-Object { $_.STATUT_PAIEMENT -eq 'Y' }).Count
    $NbImpayees = ($Resultats | Where-Object { $_.STATUT_PAIEMENT -eq 'N' }).Count
    $NbAnnulees = ($Resultats | Where-Object { $_.DATE_ANNULATION -ne '' }).Count
    
    Write-Host "  Payees   : $NbPayees" -ForegroundColor Yellow
    Write-Host "  Impayees : $NbImpayees" -ForegroundColor Yellow
    Write-Host "  Annulees : $NbAnnulees" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Fichier genere : $FichierSortie" -ForegroundColor Green
    Write-Host "=======================================================================" -ForegroundColor Cyan
} else {
    Write-Host "ERREUR: Fichier non genere" -ForegroundColor Red
}

Remove-Item $FichierSQL -ErrorAction SilentlyContinue
