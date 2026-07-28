# =====================================================================
#  Re-affichage d'un controle deja realise
# =====================================================================
#  Regenere le rapport HTML a partir d'un Rapport_Verification_*.csv
#  existant, sans aucune connexion Oracle.
#
#  Utile pour relire un controle passe, comparer deux journees, ou
#  simplement voir le rendu du rapport sans lancer de traitement.
#
#  Usage :
#    .\Apercu_Rapport.ps1                          -> le rapport le plus recent
#    .\Apercu_Rapport.ps1 -Csv Logs\Rapport_....csv
#    .\Apercu_Rapport.ps1 -Tous                    -> tous les rapports du dossier
# =====================================================================

param(
    [string] $Csv = '',
    [switch] $Tous,
    [switch] $PasDOuverture
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$ModuleRapport = Join-Path $ScriptDir 'Rapport_Html.ps1'
if (-not (Test-Path $ModuleRapport)) {
    Write-Host "[ERREUR] Rapport_Html.ps1 introuvable : $ModuleRapport" -ForegroundColor Red
    exit 1
}
. $ModuleRapport

$LogDir = Join-Path $ScriptDir 'Logs'

$cibles = @()
if ($Csv -ne '') {
    if (-not [System.IO.Path]::IsPathRooted($Csv)) { $Csv = Join-Path $ScriptDir $Csv }
    if (-not (Test-Path $Csv)) {
        Write-Host "[ERREUR] Fichier introuvable : $Csv" -ForegroundColor Red
        exit 1
    }
    $cibles = @(Get-Item $Csv)
}
elseif ($Tous) {
    $cibles = @(Get-ChildItem (Join-Path $LogDir 'Rapport_Verification_*.csv') -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime)
}
else {
    $cibles = @(Get-ChildItem (Join-Path $LogDir 'Rapport_Verification_*.csv') -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime | Select-Object -Last 1)
}

if ($cibles.Count -eq 0) {
    Write-Host "[ERREUR] Aucun rapport trouve dans $LogDir" -ForegroundColor Red
    Write-Host '         Lancer d''abord Lancer_Verification.bat sur un fichier d''export.' -ForegroundColor Yellow
    exit 1
}

Write-Host ''
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host '  APERCU DES RAPPORTS - Controle Folio Rose' -ForegroundColor Cyan
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host ''

$dernier = $null
foreach ($c in $cibles) {
    # Les rapports sont exportes en UTF-8 avec BOM par Export-Csv.
    $lignes = @(Import-Csv -Path $c.FullName -Delimiter ';' -Encoding UTF8)
    if ($lignes.Count -eq 0) {
        Write-Host "   [ignore] $($c.Name) : aucune ligne" -ForegroundColor Yellow
        continue
    }

    $html = $c.FullName -replace '\.csv$', '.html'
    New-RapportHtml -Resultats $lignes -CheminHtml $html -CheminCsv $c.FullName

    $ko = @($lignes | Where-Object { $_.'Statut Verification' -eq 'KO' }).Count
    Write-Host ("   {0,-46} {1,4} ligne(s), {2,3} en ecart" -f $c.Name, $lignes.Count, $ko) -ForegroundColor Green
    $dernier = $html
}

Write-Host ''
Write-Host "   $($cibles.Count) rapport(s) regenere(s) dans $LogDir" -ForegroundColor Green
Write-Host ''

if (-not $PasDOuverture -and $dernier -and (Test-Path $dernier)) {
    Start-Process $dernier
}
