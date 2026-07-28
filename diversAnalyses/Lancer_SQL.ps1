# Lanceur generique - Execution de scripts SQL Oracle EBS
# Date : 20/03/2026
# Usage : .\Lancer_SQL.ps1 -SqlFile "chemin\script.sql" [-LogDir "chemin\logs"] [-GarderTempSQL] [-OuvrirLog]

param(
    [Parameter(Mandatory=$true)]
    [string] $SqlFile,                   # Chemin du fichier SQL a executer (obligatoire)
    [string] $LogDir      = "",          # Dossier de sortie des logs (defaut : sous-dossier Logs\ a cote du SQL)
    [switch] $GarderTempSQL,             # Conserver le fichier SQL temporaire pour debug
    [switch] $OuvrirLog,                 # Ouvrir le log dans Notepad a la fin
    [switch] $EnvoyerMail               # Envoyer le rapport par email a la fin
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DateJour  = Get-Date -Format "ddMMyyyy"

# --- Nom de base du script (sans extension) pour nommer le log ---
$SqlBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SqlFile)

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  LANCEUR SQL Oracle EBS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  Date execution  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Script SQL      : $SqlFile"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# ETAPE 1 : PREREQUIS
# =============================================================================
Write-Host "Etape 1 : Verification des prerequis..." -ForegroundColor Yellow

# Resoudre le chemin complet du fichier SQL
if (-not [System.IO.Path]::IsPathRooted($SqlFile)) {
    $SqlFile = Join-Path (Get-Location) $SqlFile
}
if (-not (Test-Path $SqlFile)) {
    Write-Host "[ERREUR] Fichier SQL introuvable : $SqlFile" -ForegroundColor Red
    exit 1
}
Write-Host "   Script SQL      : $SqlFile" -ForegroundColor Green

# Dossier du fichier SQL source
$SqlDir = Split-Path -Parent $SqlFile

# Dossier de logs
if ($LogDir -eq "") {
    $LogDir = Join-Path $SqlDir "Logs"
}
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$FichierLog    = Join-Path $LogDir "${SqlBaseName}_${DateJour}_${Timestamp}.log"
$FichierLogSQL = $FichierLog.Replace('\', '/')

Write-Host "   Dossier logs    : $LogDir" -ForegroundColor Green
Write-Host "   Fichier log     : $FichierLog" -ForegroundColor Green

# Detection du client Oracle
$SQL_CMD = $null
foreach ($cmd in @('sqlcl','sql','sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $SQL_CMD = $cmd; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host "[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)" -ForegroundColor Red
    exit 1
}
Write-Host "   Client Oracle   : $SQL_CMD" -ForegroundColor Green
Write-Host ""

# =============================================================================
# ETAPE 2 : CONNEXION ORACLE
# =============================================================================
Write-Host "Etape 2 : Chargement de la configuration Oracle..." -ForegroundColor Yellow

# Chercher config.ps1 : d'abord dans le dossier du SQL, puis dans le dossier du lanceur
$ConfigFile = $null
foreach ($candidat in @((Join-Path $SqlDir "config.ps1"), (Join-Path $ScriptDir "config.ps1"))) {
    if (Test-Path $candidat) { $ConfigFile = $candidat; break }
}
if ($null -eq $ConfigFile) {
    Write-Host "[ERREUR] Fichier config.ps1 introuvable" -ForegroundColor Red
    Write-Host "         Cherche dans : $SqlDir" -ForegroundColor Red
    Write-Host "         Cherche dans : $ScriptDir" -ForegroundColor Red
    exit 1
}
Write-Host "   Config          : $ConfigFile" -ForegroundColor Green
. $ConfigFile

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"

Write-Host "   Connexion       : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host ""

# =============================================================================
# ETAPE 3 : GENERATION DU SCRIPT SQL TEMPORAIRE (avec SPOOL)
# =============================================================================
Write-Host "Etape 3 : Generation du script temporaire..." -ForegroundColor Yellow

$sqlContenu = Get-Content $SqlFile -Encoding UTF8

$header = @(
    "-- Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') par Lancer_SQL.ps1",
    "-- Source : $SqlFile",
    "",
    "SPOOL $FichierLogSQL",
    "",
    "SET PAGESIZE 9999",
    "SET LINESIZE 200",
    "SET TRIMOUT ON",
    "SET TRIMSPOOL ON",
    "SET FEEDBACK OFF",
    "SET VERIFY OFF",
    "SET SQLBLANKLINES ON",
    "SET SERVEROUTPUT ON SIZE UNLIMITED",
    ""
)
$footer = @("", "SPOOL OFF", "EXIT;")

$FichierSQLTemp = Join-Path $SqlDir "temp_${SqlBaseName}_${Timestamp}.sql"
$utf8bom = New-Object System.Text.UTF8Encoding($true)
$sqlFinal = ($header + $sqlContenu + $footer) -join "`r`n"
[System.IO.File]::WriteAllText($FichierSQLTemp, $sqlFinal, $utf8bom)

Write-Host "   Fichier temp    : $FichierSQLTemp" -ForegroundColor Green
Write-Host ""

# =============================================================================
# ETAPE 4 : EXECUTION
# =============================================================================
Write-Host "Etape 4 : Execution Oracle EBS..." -ForegroundColor Yellow
Write-Host "   Cela peut prendre quelques minutes..." -ForegroundColor Yellow
Write-Host ""

$env:NLS_LANG = "FRENCH_FRANCE.AL32UTF8"

$t0 = Get-Date
& $SQL_CMD -S $CONNECT_STR "@$FichierSQLTemp"
$rc = $LASTEXITCODE
$duree = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

if (-not $GarderTempSQL) {
    Remove-Item $FichierSQLTemp -ErrorAction SilentlyContinue
} else {
    Write-Host "   [INFO] Fichier temporaire conserve : $FichierSQLTemp" -ForegroundColor Yellow
}

if ($rc -ne 0) {
    Write-Host "[ERREUR] Echec execution Oracle (code retour : $rc)" -ForegroundColor Red
    exit 1
}

# =============================================================================
# ETAPE 5 : ANALYSE DU LOG
# =============================================================================
Write-Host "Etape 5 : Analyse du log..." -ForegroundColor Yellow

if (-not (Test-Path $FichierLog)) {
    Write-Host "[ATTENTION] Fichier log non genere." -ForegroundColor Yellow
    Write-Host "            Verifier les droits d'ecriture sur : $LogDir" -ForegroundColor Yellow
    exit 1
}

$logLines  = Get-Content $FichierLog -Encoding UTF8
$nbLignes  = $logLines.Count
$tailleLog = [math]::Round((Get-Item $FichierLog).Length / 1KB, 2)

$errOra  = $logLines | Where-Object { $_ -match "^ORA-\d+" }
$errSP2  = $logLines | Where-Object { $_ -match "^SP2-\d+" }
$ligWarn = $logLines | Where-Object { $_ -match "\bWARNING\b" -and $_ -notmatch "^ORA-|^SP2-" }

$nbErrTech = $errOra.Count + $errSP2.Count
$nbWarn    = $ligWarn.Count

Write-Host "   [OK] Log analyse : $nbLignes lignes, $tailleLog Ko" -ForegroundColor Green
Write-Host ""

# =============================================================================
# ETAPE 6 : AFFICHAGE DES ERREURS
# =============================================================================
if ($nbErrTech -gt 0) {
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "       ERREURS TECHNIQUES ($nbErrTech)" -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    if ($errOra.Count -gt 0) {
        Write-Host "  Erreurs Oracle ($($errOra.Count)) :" -ForegroundColor Red
        $errOra | Select-Object -Unique | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
        Write-Host ""
    }
    if ($errSP2.Count -gt 0) {
        Write-Host "  Erreurs SQL*Plus ($($errSP2.Count)) :" -ForegroundColor Red
        $errSP2 | Select-Object -Unique | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
        Write-Host ""
    }
}

if ($nbWarn -gt 0) {
    Write-Host "======================================================================" -ForegroundColor Yellow
    Write-Host "       AVERTISSEMENTS ($nbWarn)" -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Yellow
    $ligWarn | Select-Object -First 20 | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($nbErrTech -eq 0 -and $nbWarn -eq 0) {
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "                OK - AUCUNE ERREUR DETECTEE" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
}

# =============================================================================
# ETAPE 7 : RESUME
# =============================================================================
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RESUME" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  Script          : $SqlFile"
Write-Host "  Duree           : ${duree}s"
Write-Host "  Log             : $FichierLog" -ForegroundColor Green
Write-Host "  Taille log      : $tailleLog Ko ($nbLignes lignes)"
if ($nbErrTech -gt 0) {
    Write-Host "  Erreurs tech.   : $nbErrTech  (ORA- / SP2-)" -ForegroundColor Red
} else {
    Write-Host "  Erreurs tech.   : 0" -ForegroundColor Green
}
if ($nbWarn -gt 0) {
    Write-Host "  Avertissements  : $nbWarn" -ForegroundColor Yellow
} else {
    Write-Host "  Avertissements  : 0" -ForegroundColor Green
}
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($nbErrTech -gt 0 -or $OuvrirLog) {
    if (Get-Command notepad -ErrorAction SilentlyContinue) {
        Write-Host "  Ouverture du log dans Notepad..." -ForegroundColor Yellow
        Start-Process notepad $FichierLog
    }
}

# =============================================================================
# ETAPE 8 : ENVOI MAIL
# =============================================================================
if ($EnvoyerMail) {
    Write-Host "Etape 8 : Envoi du rapport par email..." -ForegroundColor Yellow
    try {
        if ($nbErrTech -gt 0) {
            $sujet = "[ERREUR] $SqlBaseName - $(Get-Date -Format 'dd/MM/yyyy')"
        } elseif ($nbWarn -gt 0) {
            $sujet = "[WARNING] $SqlBaseName - $(Get-Date -Format 'dd/MM/yyyy')"
        } else {
            $sujet = "[OK] $SqlBaseName - $(Get-Date -Format 'dd/MM/yyyy')"
        }

        $corps = @"
RAPPORT D'EXECUTION SQL Oracle EBS
Date      : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Script    : $SqlFile
Duree     : ${duree}s

--- SYNTHESE ---
Erreurs techniques  : $nbErrTech
Avertissements      : $nbWarn

$(if ($errOra.Count -gt 0) { "Erreurs Oracle :`n" + ($errOra | Select-Object -Unique | Out-String) })
$(if ($errSP2.Count -gt 0) { "Erreurs SQL*Plus :`n" + ($errSP2 | Select-Object -Unique | Out-String) })
$(if ($nbErrTech -eq 0 -and $nbWarn -eq 0) { "Aucune erreur detectee." })

--- FICHIER LOG ---
$FichierLog

---
Ce message est envoye automatiquement par Lancer_SQL.ps1
"@

        $mailParams = @{
            SmtpServer  = $MAIL_SMTP_HOST
            Port        = $MAIL_SMTP_PORT
            From        = $MAIL_FROM
            To          = $MAIL_TO
            Subject     = $sujet
            Body        = $corps
            Attachments = $FichierLog
            UseSsl      = $MAIL_SSL
            Encoding    = [System.Text.Encoding]::UTF8
        }

        if ((Get-Variable 'MAIL_USER' -ErrorAction SilentlyContinue) -and $MAIL_USER -ne "") {
            $securePwd = ConvertTo-SecureString $MAIL_PWD -AsPlainText -Force
            $mailParams['Credential'] = New-Object System.Management.Automation.PSCredential($MAIL_USER, $securePwd)
        }

        Send-MailMessage @mailParams
        Write-Host "   [OK] Mail envoye a : $($MAIL_TO -join ', ')" -ForegroundColor Green
    } catch {
        Write-Host "   [ATTENTION] Echec envoi mail : $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "[OK] Execution terminee." -ForegroundColor Green