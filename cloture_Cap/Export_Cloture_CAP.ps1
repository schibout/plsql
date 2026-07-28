# =====================================================================
# Export_Cloture_CAP.ps1 - Exports Cloture CAP Oracle EBS
# =====================================================================
# Date    : 01/04/2026
# Auteur  : GitHub Copilot
#
# Exporte les 4 requetes de cloture CAP :
#   1. CAP_COMMANDES_REJ.sql          -> Lignes de commande rejetees_2604.xlsx
#   2. CAP_DTR_PROVISIONS_GL_PO_...   -> DTR Provisions PO avec Cde_2604.csv
#   3. CAP_OD_Cut_Off_SSTR_...        -> Od Cut Off SSTR avec factures_2604.xlsx
#   4. SQL_Provision_OCT-25.sql       -> Provisions PO avec Cde_2604.xlsx
#
# Les SQL contenant la periode (MAR-26 par defaut) sont substitues
# automatiquement avec la periode cible.
# =====================================================================

param(
    [string] $Periode   = "DEC-25",   # Periode Oracle EBS cible (ex: DEC-25, MAR-26)
    [string] $OutputDir = ""          # Dossier de sortie (defaut : Exports\ a cote du script)
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  EXPORT CLOTURE CAP - Oracle EBS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  Date execution  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Periode cible   : $Periode"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# CONFIGURATION DES 4 EXPORTS
# Champs : SqlFile, OutputFile, ChangerDate (nbre remplacements attendus)
# =============================================================================
$Exports = @(
    [PSCustomObject]@{
        SqlFile    = "CAP_COMMANDES_REJ.sql"
        OutputFile = "Lignes de commande rejetees_2604.csv"
        ChangerDate = $false
    },
   [PSCustomObject]@{
        SqlFile    = "CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql"
        OutputFile = "DTR Provisions PO avec Cde_2604.csv"
        ChangerDate = $true
    },
    [PSCustomObject]@{
        SqlFile    = "CAP_OD_Cut_Off_SSTR_factures_V3.sql"
        OutputFile = "Od Cut Off SSTR avec factures_2604.csv"
        ChangerDate = $true
    },
    [PSCustomObject]@{
        SqlFile    = "SQL_Provision_OCT-25.sql"
        OutputFile = "Provisions PO avec Cde_2604.csv"
        ChangerDate = $true
    }
)

# =============================================================================
# PREREQUIS
# =============================================================================
Write-Host "Etape 1 : Verification des prerequis..." -ForegroundColor Yellow

# -- Dossier de sortie --
if ($OutputDir -eq "") {
    $OutputDir = Join-Path $ScriptDir "Exports"
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "   Dossier exports cree : $OutputDir" -ForegroundColor Green
} else {
    Write-Host "   Dossier exports      : $OutputDir" -ForegroundColor Green
}

# -- Client Oracle --
$SQL_CMD = $null
foreach ($cmd in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $SQL_CMD = $cmd; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host "[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)" -ForegroundColor Red
    exit 1
}
Write-Host "   Client Oracle        : $SQL_CMD" -ForegroundColor Green

# -- Config Oracle --
$ORA_USER    = "aroux"
$ORA_PWD     = "GAERFTXF"
$ORA_HOST    = "prdscanc1pdb03.dalkia.net"
$ORA_PORT    = "1521"
$ORA_SERVICE = "ebs_PDBFINP1"

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"
Write-Host "   Connexion            : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host ""

# =============================================================================
# FONCTION : Nettoyage du spool SQL*Plus pipe-separated -> vrai CSV
# SQL*Plus genere un fichier avec separateur | et colonnes paddees (espaces).
# Cette fonction nettoie le fichier pour produire un CSV propre.
# =============================================================================
function Convert-SpoolToCsv {
    param([string]$SpoolPath)

    $lines  = Get-Content $SpoolPath -Encoding UTF8
    $result = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        $t = $line.TrimEnd()
        if ($t -eq "") { continue }
        # Ignorer lignes de tirets (separateur d'entetes SQL*Plus)
        if ($t -match "^[\-\| ]+$") { continue }
        # Ignorer messages SQL*Plus (erreurs, nb lignes, etc.)
        if ($t -match "^(ORA-|SP2-|PLS-|ERROR|[0-9]+ ligne|[0-9]+ row)") { continue }
        if ($t -match "Disconnected|Connected|pas de mise en file") { continue }

        # Splitter sur | et trimmer chaque champ
        $fields = $t.Split("|") | ForEach-Object { $_.Trim() }

        # Quoter les champs contenant une virgule ou un guillemet
        $quoted = $fields | ForEach-Object {
            if ($_ -match ',' -or $_ -match '"') {
                '"' + $_.Replace('"', '""') + '"'
            } else { $_ }
        }
        $result.Add(($quoted -join ","))
    }

    $utf8bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllLines($SpoolPath, $result, $utf8bom)
}

# =============================================================================
# FONCTION : Conversion CSV -> XLSX via Excel COM
# =============================================================================
function Convert-CsvToXlsx {
    param(
        [string] $CsvPath,
        [string] $XlsxPath
    )
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible        = $false
        $excel.DisplayAlerts  = $false

        $wb = $excel.Workbooks.Open($CsvPath)
        # Formate la premiere ligne en gras (entetes)
        $ws = $wb.Worksheets.Item(1)
        $ws.Rows.Item(1).Font.Bold = $true
        $ws.Columns.AutoFit() | Out-Null

        # Sauvegarde en XLSX (51 = xlOpenXMLWorkbook)
        $wb.SaveAs($XlsxPath, 51)
        $wb.Close($false)
        $excel.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws)    | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb)    | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
        [System.GC]::Collect()
        return $true
    } catch {
        Write-Host "   [ATTENTION] Conversion XLSX echouee : $_" -ForegroundColor Yellow
        Write-Host "               Le fichier CSV est disponible : $CsvPath" -ForegroundColor Yellow
        return $false
    }
}

# =============================================================================
# BOUCLE D'EXPORT
# =============================================================================
$Resultats = @()
$NumExport = 0

foreach ($export in $Exports) {

    $NumExport++
    $SqlPath = Join-Path $ScriptDir $export.SqlFile

    Write-Host "[$NumExport/$($Exports.Count)] $($export.SqlFile)" -ForegroundColor Cyan
    Write-Host "   -> $($export.OutputFile)"

    # -- Verifier que le SQL existe --
    if (-not (Test-Path $SqlPath)) {
        Write-Host "   [ERREUR] Fichier SQL introuvable : $SqlPath" -ForegroundColor Red
        $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "ERREUR - SQL introuvable" }
        continue
    }

    # -- Lire le contenu SQL --
    $sqlContenu = Get-Content $SqlPath -Raw -Encoding UTF8

    # -- Substitution de periode si necessaire --
    if ($export.ChangerDate) {
        $nbRemplacement = ([regex]::Matches($sqlContenu, [regex]::Escape("MAR-26"))).Count
        $sqlContenu = $sqlContenu -replace [regex]::Escape("MAR-26"), $Periode
        Write-Host "   Periode substituee  : MAR-26 -> $Periode ($nbRemplacement occurrence(s))" -ForegroundColor Yellow
    }

    # -- Chemin du fichier CSV intermediaire --
    $OutputExt      = [System.IO.Path]::GetExtension($export.OutputFile).ToLower()
    $OutputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($export.OutputFile)

    if ($OutputExt -eq ".csv") {
        $CsvPath  = Join-Path $OutputDir $export.OutputFile
        $XlsxPath = $null
    } else {
        # Pour XLSX : on genere d'abord un CSV temporaire
        $CsvPath  = Join-Path $OutputDir "${OutputBaseName}_temp_${Timestamp}.csv"
        $XlsxPath = Join-Path $OutputDir $export.OutputFile
    }

    # -- Construire le script SQL temporaire avec SPOOL pipe-separated --
    # SET COLSEP avec "|" fonctionne sur toutes les versions SQL*Plus.
    # Le chemin SPOOL est entre guillemets pour supporter les espaces.
    $CsvPathSlash = $CsvPath.Replace('\', '/')
    $sqlTemp = @"
SET COLSEP "|"
SET PAGESIZE 50000
SET LINESIZE 32767
SET TRIMOUT ON
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET ECHO OFF
SET HEADING ON
SET UNDERLINE "-"
SPOOL "$CsvPathSlash"

$sqlContenu

SPOOL OFF
EXIT;
"@

    $TempSqlFile = Join-Path $ScriptDir "temp_export_${NumExport}_${Timestamp}.sql"
    $utf8nobom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($TempSqlFile, $sqlTemp, $utf8nobom)

    # -- Execution SQLcl --
    Write-Host "   Execution SQL..." -ForegroundColor Yellow
    $env:NLS_LANG = "FRENCH_FRANCE.AL32UTF8"
    $t0 = Get-Date

    try {
        & $SQL_CMD -S $CONNECT_STR "@$TempSqlFile"
        $rc = $LASTEXITCODE
    } catch {
        $rc = 1
        Write-Host "   [ERREUR] Exception SQLcl : $_" -ForegroundColor Red
    } finally {
        Remove-Item $TempSqlFile -ErrorAction SilentlyContinue
    }

    $duree = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

    if ($rc -ne 0) {
        Write-Host "   [ERREUR] SQLcl a retourne le code : $rc (duree ${duree}s)" -ForegroundColor Red
        $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "ERREUR SQLcl (code $rc)" }
        continue
    }

    if (-not (Test-Path $CsvPath)) {
        Write-Host "   [ERREUR] Fichier CSV non genere : $CsvPath" -ForegroundColor Red
        $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "ERREUR - CSV non genere" }
        continue
    }

    $tailleKo = [math]::Round((Get-Item $CsvPath).Length / 1KB, 1)
    Write-Host "   Spool brut          : $tailleKo Ko (${duree}s)" -ForegroundColor Green

    # -- Nettoyage du spool SQL*Plus (pipe+padding -> vrai CSV) --
    Convert-SpoolToCsv -SpoolPath $CsvPath
    $tailleKo = [math]::Round((Get-Item $CsvPath).Length / 1KB, 1)
    Write-Host "   CSV nettoye         : $tailleKo Ko" -ForegroundColor Green

    # -- Conversion CSV -> XLSX si necessaire --
    if ($null -ne $XlsxPath) {
        Write-Host "   Conversion XLSX..." -ForegroundColor Yellow
        $ok = Convert-CsvToXlsx -CsvPath (Resolve-Path $CsvPath).Path -XlsxPath $XlsxPath
        Remove-Item $CsvPath -ErrorAction SilentlyContinue

        if ($ok) {
            $tailleXlsx = [math]::Round((Get-Item $XlsxPath).Length / 1KB, 1)
            Write-Host "   XLSX genere         : $tailleXlsx Ko" -ForegroundColor Green
            $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "OK ($tailleXlsx Ko)" }
        } else {
            $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "CSV genere (echec XLSX)" }
        }
    } else {
        $Resultats += [PSCustomObject]@{ Fichier = $export.OutputFile; Statut = "OK ($tailleKo Ko)" }
    }

    Write-Host ""
}

# =============================================================================
# BILAN FINAL
# =============================================================================
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  BILAN EXPORT CLOTURE CAP - Periode : $Periode" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
foreach ($r in $Resultats) {
    if ($r.Statut -like "OK*") {
        Write-Host ("  [OK]     " + $r.Fichier) -ForegroundColor Green
        Write-Host ("           " + $r.Statut)
    } else {
        Write-Host ("  [ERREUR] " + $r.Fichier) -ForegroundColor Red
        Write-Host ("           " + $r.Statut) -ForegroundColor Red
    }
}
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  Fichiers generes dans : $OutputDir" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
