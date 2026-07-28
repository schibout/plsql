# =====================================================================
# Script d'analyse des factures impayées BO par lots
# =====================================================================
param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$false)]
    [int]$TailleLot = 1000
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  ANALYSE FACTURES IMPAYEES BO - Traitement par lots" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Annee : $Annee | Taille lot : $TailleLot"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# Charger le fichier BO
$FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
if (-not (Test-Path $FichierBO)) {
    Write-Host "ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    exit 1
}

$FacturesBO = Import-Csv -Path $FichierBO -Delimiter ',' -Encoding UTF8 | Where-Object { $_.ID_FACTURE }
$IDsFactures = $FacturesBO | ForEach-Object { $_.ID_FACTURE } | Sort-Object -Unique

$TotalFactures = $IDsFactures.Count
$NbLots = [Math]::Ceiling($TotalFactures / $TailleLot)

Write-Host "Factures BO chargees : $TotalFactures" -ForegroundColor Green
Write-Host "Nombre de lots : $NbLots" -ForegroundColor Green
Write-Host ""

# Configuration Oracle
$ORACLE_USER = "aroux"
$ORACLE_PASSWORD = "GAERFTXF"
$ORACLE_DSN = "prdscanc1pdb03.dalkia.net:1521/ebs_PDBFINP1"
$CONNECT_STRING = "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"

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

Write-Host "Client SQL : $SQL_CMD" -ForegroundColor Green
Write-Host ""

# Fichier de sortie final
$FichierSortieFinal = Join-Path $ScriptDir "factures_detaillees_${Annee}_${Timestamp}.csv"

# Créer l'en-tête
"ID_FACTURE;NUM_FACTURE;MONTANT_FACTURE;MONTANT_PAYE;STATUT_PAIEMENT;DATE_FACTURE;FOURNISSEUR;SITE;DATE_ANNULATION;DATE_MAJ" | Out-File -FilePath $FichierSortieFinal -Encoding UTF8

# Traiter par lots
$TousResultats = @()
for ($i = 0; $i -lt $NbLots; $i++) {
    $NumLot = $i + 1
    $Debut = $i * $TailleLot
    $Fin = [Math]::Min(($i + 1) * $TailleLot - 1, $TotalFactures - 1)
    
    $IDsLot = $IDsFactures[$Debut..$Fin] -join ", "
    $NbFacturesLot = $Fin - $Debut + 1
    
    Write-Host "Lot $NumLot/$NbLots : Extraction de $NbFacturesLot factures..." -ForegroundColor Yellow
    
    # Générer la requête SQL pour ce lot
    $FichierSortieLot = Join-Path $ScriptDir "temp_lot_${i}.csv"
    $FichierSortieLotOracle = $FichierSortieLot.Replace('\', '/')
    
    $RequeteSQL = @"
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ';'

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

SPOOL $FichierSortieLotOracle

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
WHERE aia.invoice_id IN ($IDsLot)
ORDER BY aia.last_update_date DESC;

SPOOL OFF
EXIT;
"@
    
    $FichierSQL = Join-Path $ScriptDir "temp_requete_lot_${i}.sql"
    $RequeteSQL | Out-File -FilePath $FichierSQL -Encoding ASCII
    
    # Exécuter la requête
    & $SQL_CMD -S $CONNECT_STRING "@$FichierSQL" | Out-Null
    
    # Récupérer les résultats
    if (Test-Path $FichierSortieLot) {
        $ResultatsLot = Get-Content $FichierSortieLot -Encoding UTF8 | Where-Object { $_ -notmatch '^ID_FACTURE' }
        if ($ResultatsLot) {
            $ResultatsLot | Add-Content -Path $FichierSortieFinal -Encoding UTF8
            $TousResultats += $ResultatsLot
            Write-Host "  -> $($ResultatsLot.Count) factures extraites" -ForegroundColor Green
        }
        Remove-Item $FichierSortieLot -ErrorAction SilentlyContinue
    }
    
    Remove-Item $FichierSQL -ErrorAction SilentlyContinue
    
    # Pause pour éviter de surcharger Oracle
    if ($NumLot -lt $NbLots) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RESULTATS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan

# Analyser les résultats
$Resultats = Import-Csv -Path $FichierSortieFinal -Delimiter ';' -Encoding UTF8
$NbResultats = $Resultats.Count

Write-Host "Factures extraites : $NbResultats / $TotalFactures" -ForegroundColor Green

$NbPayees = ($Resultats | Where-Object { $_.STATUT_PAIEMENT -eq 'Y' }).Count
$NbImpayees = ($Resultats | Where-Object { $_.STATUT_PAIEMENT -eq 'N' }).Count
$NbPartielles = ($Resultats | Where-Object { $_.STATUT_PAIEMENT -eq 'P' }).Count
$NbAnnulees = ($Resultats | Where-Object { $_.DATE_ANNULATION -ne '' }).Count

Write-Host ""
Write-Host "Statuts :" -ForegroundColor Yellow
Write-Host "  Payees     : $NbPayees" -ForegroundColor $(if($NbPayees -gt 0){"Yellow"}else{"Green"})
Write-Host "  Impayees   : $NbImpayees" -ForegroundColor $(if($NbImpayees -gt 0){"Yellow"}else{"Green"})
Write-Host "  Partielles : $NbPartielles" -ForegroundColor $(if($NbPartielles -gt 0){"Yellow"}else{"Green"})
Write-Host "  Annulees   : $NbAnnulees" -ForegroundColor $(if($NbAnnulees -gt 0){"Yellow"}else{"Green"})

$MontantTotal = ($Resultats | Measure-Object -Property MONTANT_FACTURE -Sum).Sum
$MontantPaye = ($Resultats | Measure-Object -Property MONTANT_PAYE -Sum).Sum
$MontantRestant = $MontantTotal - $MontantPaye

Write-Host ""
Write-Host "Montants :" -ForegroundColor Yellow
Write-Host "  Total factures : $([math]::Round($MontantTotal, 2))"
Write-Host "  Total paye     : $([math]::Round($MontantPaye, 2))"
Write-Host "  Total restant  : $([math]::Round($MontantRestant, 2))" -ForegroundColor $(if($MontantRestant -gt 0){"Yellow"}else{"Green"})

Write-Host ""
Write-Host "Fichier genere : $FichierSortieFinal" -ForegroundColor Green
Write-Host "Taille : $([math]::Round((Get-Item $FichierSortieFinal).Length / 1MB, 2)) Mo"
Write-Host "=======================================================================" -ForegroundColor Cyan
