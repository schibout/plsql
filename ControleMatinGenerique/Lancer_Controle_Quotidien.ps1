# Lanceur - Controle Quotidien Complet Oracle EBS
# Date : 18/03/2026
# Usage : .\Lancer_Controle_Quotidien.ps1 [-NbJoursHisto 3] [-HeureFermeture 19] [-HeureOuverture 7] [-GarderTempSQL]

param(
    [int]   $NbJoursHisto    = 3,
    [int]   $HeureFermeture  = 19,
    [int]   $HeureOuverture  = 7,
    [switch]$GarderTempSQL,          # Conserver le .sql temporaire pour debug
    [switch]$EnvoyerMail,            # Envoyer le rapport par email a la fin
    [switch]$PasDeRapport,           # Ne pas generer / ouvrir le rapport HTML
    [switch]$PasDOuverture           # Generer le rapport sans l'ouvrir
)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "ddMMyyyy_HHmmss"
$DateJour   = (Get-Date).AddDays(-1) | Get-Date -Format "ddMMyyyy"

# Codes retour, pour qu'une tache planifiee puisse distinguer les cas :
#   0 = tout va bien   1 = erreur technique   2 = alerte fonctionnelle
#   3 = avertissements seuls
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_FONCT = 2; $EXIT_WARN = 3

function Html-Echap {
    param([string]$T)
    if ([string]::IsNullOrEmpty($T)) { return '' }
    return $T.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

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

$logBrut   = Get-Content $FichierLog -Encoding UTF8

# --- Extraction des indicateurs balises emis par le SQL ---
$kpis  = New-Object System.Collections.Generic.List[object]
$meta  = @{}
foreach ($l in $logBrut) {
    if ($l -match '^##KPI##(.*)$') {
        $c = $Matches[1].Split('|')
        if ($c.Count -ge 3) {
            $kpis.Add([PSCustomObject]@{ Libelle = $c[0]; Valeur = $c[1]; Statut = $c[2].Trim() })
        }
        continue
    }
    if ($l -match '^##META##(.*)$') {
        $c = $Matches[1].Split('|')
        if ($c.Count -ge 2) { $meta[$c[0]] = $c[1] }
    }
}

# Le log destine a la lecture humaine est debarrasse des lignes balisees.
$logLines = $logBrut | Where-Object { $_ -notmatch '^##(KPI|META)##' }
[System.IO.File]::WriteAllLines($FichierLog, $logLines, (New-Object System.Text.UTF8Encoding $true))

$nbLignes  = $logLines.Count
$tailleLog = [math]::Round((Get-Item $FichierLog).Length / 1KB, 2)

# Alertes fonctionnelles (remontees par le SQL)
$alertesImg   = @($logLines | Where-Object { $_ -match "IMAGES MANQUANTES" })
$alertesDSP   = @($logLines | Where-Object { $_ -match "flux DSP" -and $_ -match "ALERTE" })
$alertesIndis = @($logLines | Where-Object { $_ -match "CONTROLE INDISPONIBLE" })
$alertesLundi = @($logLines | Where-Object { $_ -match "RAPPEL LUNDI" })
$alertesWarn  = @($logLines | Where-Object { $_ -match "\bWARNING\b" -and $_ -notmatch "ORA-|SP2-" })

# Erreurs techniques Oracle/SQL dans le log
$errOra  = @($logLines | Where-Object { $_ -match "^ORA-\d+" })
$errSP2  = @($logLines | Where-Object { $_ -match "^SP2-\d+" })

$nbErrTech   = $errOra.Count + $errSP2.Count
$nbErrFonct  = $alertesImg.Count + $alertesDSP.Count + $alertesIndis.Count
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

# --- 7b. RAPPORT HTML ---
$FichierRapport = $FichierLog -replace '\.log$', '.html'

if (-not $PasDeRapport) {
    Write-Host "Etape 7b : Generation du rapport HTML..." -ForegroundColor Yellow

    # Statut global, qui pilote la couleur du bandeau et le code retour.
    if ($nbErrTech -gt 0) {
        $globStatut = 'ERREUR TECHNIQUE'; $globClass = 'ko'
        $globTexte  = "$nbErrTech erreur(s) Oracle ou SQL*Plus dans le log : le controle n'est pas fiable en l'etat."
    } elseif ($nbErrFonct -gt 0) {
        $globStatut = 'ALERTE'; $globClass = 'alerte'
        $globTexte  = "$nbErrFonct alerte(s) fonctionnelle(s) demandent une action ce matin."
    } elseif ($nbWarn -gt 0) {
        $globStatut = 'AVERTISSEMENT'; $globClass = 'warn'
        $globTexte  = "$nbWarn avertissement(s) : a surveiller, sans action immediate."
    } else {
        $globStatut = 'CONFORME'; $globClass = 'ok'
        $globTexte  = 'Aucune anomalie detectee sur les controles du matin.'
    }

    $styleKpi = @{
        'OK' = @{ c = '#0b6b3a'; f = '#d7f2e3'; l = 'OK' }
        'W'  = @{ c = '#8a5a00'; f = '#fdeccd'; l = 'A verifier' }
        'KO' = @{ c = '#9b1c1c'; f = '#fbdcdc'; l = 'Anomalie' }
    }

    $htmlKpis = ''
    foreach ($k in $kpis) {
        $s = $styleKpi[$k.Statut]
        if (-not $s) { $s = @{ c = '#333'; f = '#eee'; l = $k.Statut } }
        $valAff = $k.Valeur
        if ($valAff -match '^\d+$') { $valAff = '{0:N0}' -f [int]$valAff }
        $htmlKpis += "<div class=""tile""><div class=""tv"" style=""color:$($s.c)"">$(Html-Echap $valAff)</div>" +
                     "<div class=""tn"">$(Html-Echap $k.Libelle)</div>" +
                     "<div class=""pill"" style=""color:$($s.c);background:$($s.f)"">$(Html-Echap $s.l)</div></div>"
    }
    if ($htmlKpis -eq '') { $htmlKpis = '<div class="tile"><div class="tn">Aucun indicateur remonte</div></div>' }

    # Bloc des alertes, du plus urgent au moins urgent.
    $blocsAlertes = ''
    function Bloc-Alerte {
        param([string]$Titre, [string]$Classe, $Lignes)
        if ($Lignes.Count -eq 0) { return '' }
        $li = ($Lignes | Select-Object -First 40 | ForEach-Object { "<li>$(Html-Echap $_.Trim())</li>" }) -join ''
        $suite = if ($Lignes.Count -gt 40) { "<li><em>... et $($Lignes.Count - 40) autre(s)</em></li>" } else { '' }
        return "<div class=""bloc $Classe""><h3>$Titre <span class=""cnt"">$($Lignes.Count)</span></h3><ul>$li$suite</ul></div>"
    }
    $blocsAlertes += Bloc-Alerte 'Erreurs Oracle'            'ko'     @($errOra | Select-Object -Unique)
    $blocsAlertes += Bloc-Alerte 'Erreurs SQL*Plus'          'ko'     @($errSP2 | Select-Object -Unique)
    $blocsAlertes += Bloc-Alerte 'Controles indisponibles'   'ko'     $alertesIndis
    $blocsAlertes += Bloc-Alerte 'Images Xerox manquantes'   'alerte' $alertesImg
    $blocsAlertes += Bloc-Alerte 'Flux DSP incomplets'       'alerte' $alertesDSP
    $blocsAlertes += Bloc-Alerte 'Rappel du lundi'           'warn'   $alertesLundi
    $blocsAlertes += Bloc-Alerte 'Avertissements'            'warn'   $alertesWarn
    if ($blocsAlertes -eq '') {
        $blocsAlertes = '<div class="bloc ok"><h3>Aucune alerte</h3><ul><li>Tous les controles sont passes sans anomalie.</li></ul></div>'
    }

    # Le log complet est integre, decoupe par section pour rester navigable.
    $sections = New-Object System.Collections.Generic.List[object]
    $titreCour = 'En-tete'
    $bufCour   = New-Object System.Collections.Generic.List[string]
    foreach ($l in $logLines) {
        if ($l -match '^===\s*(.+?)\s*===\s*$') {
            if ($bufCour.Count -gt 0) {
                $sections.Add([PSCustomObject]@{ Titre = $titreCour; Lignes = ($bufCour -join "`n") })
            }
            $titreCour = $Matches[1]
            $bufCour = New-Object System.Collections.Generic.List[string]
        } else {
            $bufCour.Add($l)
        }
    }
    if ($bufCour.Count -gt 0) {
        $sections.Add([PSCustomObject]@{ Titre = $titreCour; Lignes = ($bufCour -join "`n") })
    }

    $htmlSections = ''
    foreach ($s in $sections) {
        $corps = $s.Lignes.Trim()
        if ($corps -eq '') { continue }
        $nbL = ($corps -split "`n").Count
        $ouvert = if ($s.Titre -match 'ERREUR|SANS images|regroupees') { ' open' } else { '' }
        $htmlSections += "<details$ouvert><summary>$(Html-Echap $s.Titre) <span class=""cnt"">$nbL lignes</span></summary>" +
                         "<pre>$(Html-Echap $corps)</pre></details>"
    }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Controle quotidien EBS - $($meta['date_controle'])</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 24px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1400px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 16px 22px; border-radius: 6px;
       font-size: 1.25em; margin: 0 0 14px 0; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 32px; font-size: 1.05em; }
  .meta { background: #e8f0fe; border-left: 4px solid #003366; padding: 10px 16px;
          margin-bottom: 16px; border-radius: 0 4px 4px 0; font-size: .88em; }
  .meta span { margin-right: 22px; display: inline-block; }
  .bandeau { padding: 14px 20px; border-radius: 6px; margin-bottom: 20px; font-size: .95em; }
  .bandeau strong { display: block; font-size: 1.15em; margin-bottom: 3px; }
  .bandeau.ok     { background: #d7f2e3; color: #0b6b3a; border: 1px solid #7fc9a3; }
  .bandeau.warn   { background: #fff4d6; color: #7a5600; border: 1px solid #e8c46a; }
  .bandeau.alerte { background: #ffe8d1; color: #8a4b00; border: 1px solid #e8a86a; }
  .bandeau.ko     { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; }
  .tiles { display: flex; flex-wrap: wrap; gap: 12px; }
  .tile { flex: 1 1 150px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 14px 10px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.7em; font-weight: 700; line-height: 1.1; }
  .tn { font-size: .76em; color: #57606a; text-transform: uppercase;
        letter-spacing: .03em; margin: 5px 0 7px 0; }
  .pill { display: inline-block; padding: 2px 10px; border-radius: 11px;
          font-size: .76em; font-weight: 600; }
  .bloc { background: #fff; border-radius: 6px; margin-bottom: 12px; overflow: hidden;
          box-shadow: 0 1px 3px rgba(0,0,0,.1); border-left: 4px solid #ccc; }
  .bloc h3 { margin: 0; padding: 10px 16px; font-size: .92em; background: #fafbfc; }
  .bloc ul { margin: 0; padding: 10px 16px 12px 34px; font-size: .84em; }
  .bloc li { margin: 3px 0; font-family: Consolas, Menlo, monospace; }
  .bloc.ko     { border-left-color: #9b1c1c; } .bloc.ko h3     { color: #9b1c1c; }
  .bloc.alerte { border-left-color: #d97706; } .bloc.alerte h3 { color: #8a4b00; }
  .bloc.warn   { border-left-color: #ca8a04; } .bloc.warn h3   { color: #7a5600; }
  .bloc.ok     { border-left-color: #0b6b3a; } .bloc.ok h3     { color: #0b6b3a; }
  .cnt { background: #003366; color: #fff; border-radius: 10px; padding: 1px 9px;
         font-size: .78em; margin-left: 8px; font-weight: 600; }
  details { background: #fff; border-radius: 6px; margin-bottom: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,.08); }
  summary { padding: 10px 16px; cursor: pointer; font-weight: 600; font-size: .9em;
            color: #003366; user-select: none; }
  summary:hover { background: #f0f4fa; }
  details pre { margin: 0; padding: 12px 16px; background: #fbfcfd; border-top: 1px solid #eceff2;
                overflow-x: auto; font-family: Consolas, Menlo, monospace; font-size: .8em;
                line-height: 1.45; white-space: pre; }
  .footer { font-size: .78em; color: #8b949e; margin-top: 32px; text-align: center; }
</style>
</head>
<body>
<div class="wrap">
<h1>Controle quotidien Oracle EBS</h1>
<div class="meta">
  <span><strong>Execute le :</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</span>
  <span><strong>Donnees du :</strong> $(Html-Echap $meta['date_controle']) ($(Html-Echap $meta['jour']))</span>
  <span><strong>Base :</strong> $(Html-Echap "${ORA_USER}@${ORA_DSN}")</span>
  <span><strong>Plage nuit :</strong> ${HeureFermeture}h - ${HeureOuverture}h</span>
  <span><strong>Historique :</strong> $NbJoursHisto j</span>
  <span><strong>Duree :</strong> ${duree}s</span>
</div>
<div class="bandeau $globClass"><strong>$globStatut</strong>$globTexte</div>
<h2>Indicateurs du jour</h2>
<div class="tiles">$htmlKpis</div>
<h2>Alertes et actions</h2>
$blocsAlertes
<h2>Detail complet du controle</h2>
$htmlSections
<div class="footer">Genere par Lancer_Controle_Quotidien.ps1 &mdash; log source : $(Html-Echap (Split-Path $FichierLog -Leaf))</div>
</div>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($FichierRapport, $html, (New-Object System.Text.UTF8Encoding $true))
    Write-Host "   [OK] Rapport HTML : $FichierRapport" -ForegroundColor Green
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

if (-not $PasDeRapport) {
    Write-Host "  Rapport HTML      : $FichierRapport" -ForegroundColor Green
    if (-not $PasDOuverture) {
        Write-Host "  Ouverture du rapport dans le navigateur..." -ForegroundColor Cyan
        Start-Process $FichierRapport
    }
} elseif ($nbErrTech -gt 0 -or $alertesImg.Count -gt 0) {
    if (Get-Command notepad -ErrorAction SilentlyContinue) { Start-Process notepad $FichierLog }
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

        # Le rapport HTML part en piece jointe avec le log brut : le premier
        # pour lire, le second pour chercher.
        $pieces = @($FichierLog)
        if ((-not $PasDeRapport) -and (Test-Path $FichierRapport)) { $pieces += $FichierRapport }

        $mailParams = @{
            SmtpServer  = $MAIL_SMTP_HOST
            Port        = $MAIL_SMTP_PORT
            From        = $MAIL_FROM
            To          = $MAIL_TO
            Subject     = $sujet
            Body        = $corps
            Attachments = $pieces
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

# --- 10. CODE RETOUR ---
# Une alerte fonctionnelle ne doit plus passer pour une execution reussie :
# c'est ce qui empechait toute detection par une tache planifiee.
if ($nbErrTech -gt 0) {
    Write-Host "[ERREUR] Controle termine avec $nbErrTech erreur(s) technique(s)" -ForegroundColor Red
    exit $EXIT_TECH
} elseif ($nbErrFonct -gt 0) {
    Write-Host "[ALERTE] Controle termine avec $nbErrFonct alerte(s) fonctionnelle(s)" -ForegroundColor Yellow
    exit $EXIT_FONCT
} elseif ($nbWarn -gt 0) {
    Write-Host "[WARNING] Controle termine avec $nbWarn avertissement(s)" -ForegroundColor Yellow
    exit $EXIT_WARN
}

Write-Host "[OK] Controle quotidien termine" -ForegroundColor Green
exit $EXIT_OK