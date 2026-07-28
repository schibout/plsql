# Lanceur - Controle Quotidien Complet Oracle EBS
# Date : 18/03/2026
# Usage : .\Lancer_Controle_Quotidien.ps1 [-NbJoursHisto 3] [-HeureFermeture 19] [-HeureOuverture 7] [-GarderTempSQL]

param(
    [int]   $NbJoursHisto    = 3,
    [int]   $HeureFermeture  = 19,
    [int]   $HeureOuverture  = 7,
    [switch]$GarderTempSQL,          # Conserver le .sql temporaire pour debug
    [switch]$EnvoyerMail             # Envoyer le rapport par email a la fin
)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "ddMMyyyy_HHmmss"
$DateJour   = (Get-Date).AddDays(-1) | Get-Date -Format "ddMMyyyy"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  CONTROLE QUOTIDIEN COMPLET - Oracle EBS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Date execution    : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "Jours historique  : $NbJoursHisto"
Write-Host "Plage nuit        : ${HeureFermeture}h - ${HeureOuverture}h"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. PREREQUIS ---
Write-Host "Etape 1 : Verification des prerequis..." -ForegroundColor Yellow

$FichierSQLSource = Join-Path $ScriptDir "Controle_Quotidien_Complet.sql"
if (-not (Test-Path $FichierSQLSource)) {
    Write-Host "[ERREUR] Fichier SQL introuvable : $FichierSQLSource" -ForegroundColor Red
    exit 1
}
Write-Host "   Script SQL      : $FichierSQLSource" -ForegroundColor Green

$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$FichierLog    = Join-Path $LogDir "Controle_${DateJour}_${Timestamp}.log"
$FichierLogSQL = $FichierLog.Replace('\', '/')

$SQL_CMD = $null
foreach ($cmd in @('sqlcl','sql','sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $SQL_CMD = $cmd; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host "[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)" -ForegroundColor Red
    exit 1
}
Write-Host "   Client Oracle   : $SQL_CMD" -ForegroundColor Green
Write-Host "   Fichier log     : $FichierLog" -ForegroundColor Green
Write-Host ""

# --- 2. CONNEXION ORACLE ---
Write-Host "Etape 2 : Configuration connexion Oracle..." -ForegroundColor Yellow

$ConfigFile = Join-Path $ScriptDir "config.ps1"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERREUR] Fichier de configuration introuvable : $ConfigFile" -ForegroundColor Red
    exit 1
}
. $ConfigFile

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"

Write-Host "   Connexion       : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host ""

# --- 3. GENERATION DU SCRIPT SQL ---
Write-Host "Etape 3 : Generation du script SQL..." -ForegroundColor Yellow

$sqlLines = Get-Content $FichierSQLSource -Encoding UTF8
$sqlModifie = $sqlLines | ForEach-Object {
    if ($_ -match '^\s*:v_nb_jours_histo\s*:=') {
        "    :v_nb_jours_histo   := $NbJoursHisto;"
    } elseif ($_ -match '^\s*:v_heure_fermeture\s*:=') {
        "    :v_heure_fermeture  := $HeureFermeture;"
    } elseif ($_ -match '^\s*:v_heure_ouverture\s*:=') {
        "    :v_heure_ouverture  := $HeureOuverture;"
    } else {
        $_
    }
}

$FichierSQLTemp = Join-Path $ScriptDir "temp_controle_${Timestamp}.sql"

# SQLBLANKLINES ON : empeche SQL*Plus de couper les requetes sur les lignes vides
# (corrige les erreurs SP2-0042 sur les UNION ALL)
$header = @(
    "-- Script genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
    "-- Params : NbJoursHisto=$NbJoursHisto, HeureFermeture=${HeureFermeture}h, HeureOuverture=${HeureOuverture}h",
    "",
    "SPOOL $FichierLogSQL",
    "",
    "SET PAGESIZE 100",
    "SET LINESIZE 200",
    "SET TRIMOUT ON",
    "SET TRIMSPOOL ON",
    "SET FEEDBACK OFF",
    "SET SQLBLANKLINES ON",
    "SET SERVEROUTPUT ON SIZE UNLIMITED",
    ""
)
$footer = @("", "SPOOL OFF", "EXIT;")

$utf8bom = New-Object System.Text.UTF8Encoding($true)
$sqlFinal = ($header + $sqlModifie + $footer) -join "`r`n"
[System.IO.File]::WriteAllText($FichierSQLTemp, $sqlFinal, $utf8bom)

Write-Host "   Script temporaire : $FichierSQLTemp" -ForegroundColor Green
Write-Host ""

# --- 4. EXECUTION ---
Write-Host "Etape 4 : Execution du controle Oracle EBS..." -ForegroundColor Yellow
Write-Host "   Cela peut prendre quelques minutes..." -ForegroundColor Yellow
Write-Host ""

# NLS_LANG en UTF-8 pour que les accents et caracteres speciaux s'affichent correctement dans le log
$env:NLS_LANG = "FRENCH_FRANCE.AL32UTF8"

$t0 = Get-Date
& $SQL_CMD -S $CONNECT_STR "@$FichierSQLTemp"
$rc = $LASTEXITCODE
$duree = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

if (-not $GarderTempSQL) {
    Remove-Item $FichierSQLTemp -ErrorAction SilentlyContinue
} else {
    Write-Host "   [INFO] Fichier SQL temporaire conserve : $FichierSQLTemp" -ForegroundColor Yellow
}

if ($rc -ne 0) {
    Write-Host "[ERREUR] Echec execution Oracle (code retour : $rc)" -ForegroundColor Red
    exit 1
}

# --- 5. ANALYSE DU LOG ---
Write-Host "Etape 5 : Analyse du fichier log..." -ForegroundColor Yellow

if (-not (Test-Path $FichierLog)) {
    Write-Host "[ATTENTION] Fichier log non genere - verifier SPOOL et droits sur : $LogDir" -ForegroundColor Yellow
    exit 1
}

$logLines  = Get-Content $FichierLog -Encoding UTF8
$nbLignes  = $logLines.Count
$tailleLog = [math]::Round((Get-Item $FichierLog).Length / 1KB, 2)

# Alertes fonctionnelles (remontees par le SQL)
$alertesImg  = $logLines | Where-Object { $_ -match "IMAGES MANQUANTES" }
$alertesDSP  = $logLines | Where-Object { $_ -match "flux DSP" -and $_ -match "ALERTE" }
$alertesWarn = $logLines | Where-Object { $_ -match "\bWARNING\b" -and $_ -notmatch "ORA-|SP2-" }

# Erreurs techniques Oracle/SQL dans le log
$errOra  = $logLines | Where-Object { $_ -match "^ORA-\d+" }
$errSP2  = $logLines | Where-Object { $_ -match "^SP2-\d+" }
$errSQL  = $logLines | Where-Object { $_ -match "^\*\s*$" -or ($_ -match "ERREUR" -and $_ -match "ligne \d+") }

$nbErrTech   = $errOra.Count + $errSP2.Count
$nbErrFonct  = $alertesImg.Count + $alertesDSP.Count
$nbWarn      = $alertesWarn.Count

Write-Host "   [OK] Log analyse : $nbLignes lignes, $tailleLog Ko" -ForegroundColor Green
Write-Host ""

# --- 6. ALERTES TECHNIQUES (ORA- / SP2-) ---
if ($nbErrTech -gt 0) {
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "          ERREURS TECHNIQUES DANS LE LOG ($nbErrTech)" -ForegroundColor Red
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

# --- 7. ALERTES FONCTIONNELLES ---
if ($nbErrFonct -gt 0 -or $nbWarn -gt 0) {
    Write-Host "======================================================================" -ForegroundColor Yellow
    Write-Host "          ALERTES FONCTIONNELLES" -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Yellow

    if ($alertesImg.Count -gt 0) {
        Write-Host "  *** IMAGES XEROX MANQUANTES ***" -ForegroundColor Red
        $alertesImg | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
        Write-Host ""
    }
    if ($alertesDSP.Count -gt 0) {
        Write-Host "  *** FLUX DSP INCOMPLETS ***" -ForegroundColor Yellow
        $alertesDSP | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }
        Write-Host ""
    }
    if ($nbWarn -gt 0) {
        Write-Host "  Avertissements ($nbWarn)" -ForegroundColor Yellow
        $alertesWarn | Select-Object -First 10 | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }
        Write-Host ""
    }
}

if ($nbErrTech -eq 0 -and $nbErrFonct -eq 0 -and $nbWarn -eq 0) {
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "                 OK - AUCUNE ALERTE DETECTEE" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
}

# --- 8. RESUME ---
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RESUME DU CONTROLE QUOTIDIEN" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  Date              : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Duree execution   : ${duree}s"
Write-Host "  Fichier log       : $FichierLog" -ForegroundColor Green
Write-Host "  Taille log        : $tailleLog Ko ($nbLignes lignes)"
if ($nbErrTech -gt 0) {
    Write-Host "  Erreurs techniques: $nbErrTech  <-- ORA- / SP2-" -ForegroundColor Red
} else {
    Write-Host "  Erreurs techniques: $nbErrTech" -ForegroundColor Green
}
if ($nbErrFonct -gt 0) {
    Write-Host "  Alertes fonct.    : $nbErrFonct" -ForegroundColor Red
} else {
    Write-Host "  Alertes fonct.    : $nbErrFonct" -ForegroundColor Green
}
if ($nbWarn -gt 0) {
    Write-Host "  Avertissements    : $nbWarn" -ForegroundColor Yellow
} else {
    Write-Host "  Avertissements    : $nbWarn" -ForegroundColor Green
}
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($nbErrTech -gt 0 -or $alertesImg.Count -gt 0) {
    Write-Host "  Ouverture automatique du log..." -ForegroundColor Yellow
    if (Get-Command notepad -ErrorAction SilentlyContinue) {
        Start-Process notepad $FichierLog
    }
}

# --- 9. ENVOI MAIL ---
if ($EnvoyerMail) {
    Write-Host "Etape 9 : Envoi du rapport par email..." -ForegroundColor Yellow
    try {
        # Sujet avec statut global
        if ($nbErrTech -gt 0) {
            $sujet = "[ERREUR] Controle Quotidien EBS - $(Get-Date -Format 'dd/MM/yyyy')"
        } elseif ($nbErrFonct -gt 0) {
            $sujet = "[ALERTE] Controle Quotidien EBS - $(Get-Date -Format 'dd/MM/yyyy')"
        } elseif ($nbWarn -gt 0) {
            $sujet = "[WARNING] Controle Quotidien EBS - $(Get-Date -Format 'dd/MM/yyyy')"
        } else {
            $sujet = "[OK] Controle Quotidien EBS - $(Get-Date -Format 'dd/MM/yyyy')"
        }

        # Corps du mail : resume + premieres lignes du log
        $corps = @"
RAPPORT DE CONTROLE QUOTIDIEN Oracle EBS
Date        : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Jours histo : $NbJoursHisto
Plage nuit  : ${HeureFermeture}h - ${HeureOuverture}h
Duree       : ${duree}s

--- SYNTHESE ---
Erreurs techniques  : $nbErrTech
Alertes fonct.      : $nbErrFonct
Avertissements      : $nbWarn

--- ALERTES ---
$(if ($errOra.Count -gt 0)     { "Erreurs Oracle :`n" + ($errOra | Select-Object -Unique | Out-String) })
$(if ($errSP2.Count -gt 0)     { "Erreurs SQL*Plus :`n" + ($errSP2 | Select-Object -Unique | Out-String) })
$(if ($alertesImg.Count -gt 0) { "Images manquantes :`n" + ($alertesImg | Out-String) })
$(if ($alertesDSP.Count -gt 0) { "Flux DSP incomplets :`n" + ($alertesDSP | Out-String) })
$(if ($nbErrTech -eq 0 -and $nbErrFonct -eq 0 -and $nbWarn -eq 0) { "Aucune alerte detectee." })

--- FICHIER LOG ---
$FichierLog

---
Ce message est envoye automatiquement par Lancer_Controle_Quotidien.ps1
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

        # Ajout credentials si definis dans config.ps1
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

Write-Host "[OK] Controle quotidien termine" -ForegroundColor Green