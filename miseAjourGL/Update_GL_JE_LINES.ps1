#Requires -Version 5.1
# =====================================================================
#  Correction d'un attribut de GL_JE_LINES a partir d'un fichier CSV
# =====================================================================
#  Le perimetre n'est plus fige dans le SQL : il vient d'un CSV listant
#  les couples JE_HEADER_ID / JE_LINE_NUM a corriger.
#
#  SIMULATION PAR DEFAUT : sans -Executer, l'UPDATE est joue puis annule.
#  On voit l'ancienne et la nouvelle valeur de chaque ligne, sans rien
#  conserver.
#
#  Usage :
#    .\Update_GL_JE_LINES.ps1
#    .\Update_GL_JE_LINES.ps1 -Executer
#    .\Update_GL_JE_LINES.ps1 -Csv autre_lot.csv -Attribut ATTRIBUTE13 `
#                             -Valeur "MAIN D'OEUVRE HORS THO" -Executer
#
#  Format du CSV (separateur ; ou , ou tabulation, en-tete facultatif) :
#    JE_HEADER_ID;JE_LINE_NUM
#    22975525;24
#    22975525;25
#
#  IMPORTANT - ENCODAGE : ce fichier doit rester en UTF-8 AVEC BOM, la
#  valeur par defaut contenant le caractere oe ligature. La valeur est
#  de toute facon convertie en notation UNISTR avant d'atteindre Oracle,
#  ce qui la rend independante de l'encodage cote base.
# =====================================================================

param(
    [string] $Csv       = 'lignes_a_corriger.csv',
    [string] $Attribut  = 'ATTRIBUTE13',
    [string] $Valeur    = "MAIN D'ŒUVRE HORS THO",
    [switch] $Executer,
    [switch] $SansConfirmation,
    [int]    $OrgId     = 0,        # 0 = pas de contexte MO
    [int]    $MaxLignes = 5000,
    [string] $LogDir    = '',
    [switch] $GarderTempSQL
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Mode      = if ($Executer) { 'EXECUTION' } else { 'SIMULATION' }

# 0 = conforme, 1 = erreur technique, 2 = ecart de perimetre, 3 = annule
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ECART = 2; $EXIT_ANNULE = 3

function Titre { param([string]$T, [string]$C = 'Cyan')
    Write-Host ''; Write-Host ('=' * 71) -ForegroundColor $C
    Write-Host "  $T" -ForegroundColor $C; Write-Host ('=' * 71) -ForegroundColor $C }
function Ok  { param([string]$T) Write-Host "   $T" -ForegroundColor Green }
function Ko  { param([string]$T) Write-Host "   $T" -ForegroundColor Red }
function Avt { param([string]$T) Write-Host "   $T" -ForegroundColor Yellow }

# Convertit un texte en litteral UNISTR : tout caractere non-ASCII est
# remplace par son point de code \XXXX. C'est ce qui rend la valeur
# insensible a l'encodage du fichier SQL et au NLS_LANG du poste --
# precisement le defaut que ce traitement corrige en base.
function ConvertTo-Unistr {
    param([string]$Texte)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $Texte.ToCharArray()) {
        $code = [int][char]$c
        if ($c -eq "'")        { [void]$sb.Append("''") }
        elseif ($c -eq '\')    { [void]$sb.Append('\\') }
        elseif ($code -lt 128) { [void]$sb.Append($c) }
        else                   { [void]$sb.AppendFormat('\{0:X4}', $code) }
    }
    return $sb.ToString()
}

# Les exports de ce projet arrivent tantot en CP850, tantot en
# Windows-1252, parfois en UTF-8 avec BOM.
function Get-EncodageFichier {
    param([string]$Chemin)
    $o = [System.IO.File]::ReadAllBytes($Chemin)
    if ($o.Length -ge 3 -and $o[0] -eq 0xEF -and $o[1] -eq 0xBB -and $o[2] -eq 0xBF) {
        return @{ Enc = [System.Text.Encoding]::UTF8; Nom = 'UTF-8 (BOM)' }
    }
    $nOem = 0; $nAnsi = 0
    foreach ($b in $o) {
        if     ($b -ge 0x80 -and $b -le 0x9F) { $nOem++ }
        elseif ($b -ge 0xC0)                  { $nAnsi++ }
    }
    if ($nOem -gt $nAnsi) { return @{ Enc = [System.Text.Encoding]::GetEncoding(850);  Nom = 'CP850 (OEM)' } }
    return @{ Enc = [System.Text.Encoding]::GetEncoding(1252); Nom = 'Windows-1252' }
}

Titre "CORRECTION $Attribut DE GL_JE_LINES  -  MODE $Mode" $(if ($Executer) { 'Red' } else { 'Cyan' })
Write-Host "  Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Mode           : $Mode" -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host ''

# =====================================================================
#  ETAPE 1 : PREREQUIS
# =====================================================================
Write-Host 'Etape 1 : Verification des prerequis...' -ForegroundColor Yellow

if ($Attribut -notmatch '^(?i)ATTRIBUTE([1-9]|1[0-9]|20)$') {
    Ko "[ERREUR] Attribut invalide : '$Attribut'. Attendu ATTRIBUTE1 a ATTRIBUTE20."
    Ko '         Ce nom est injecte tel quel dans le SQL, il est donc strictement controle.'
    exit $EXIT_TECH
}
$Attribut = $Attribut.ToUpper()
Ok "Colonne cible : GL_JE_LINES.$Attribut"

if (-not [System.IO.Path]::IsPathRooted($Csv)) { $Csv = Join-Path $ScriptDir $Csv }
if (-not (Test-Path $Csv)) {
    Ko "[ERREUR] Fichier CSV introuvable : $Csv"
    Ko '         Format attendu : JE_HEADER_ID;JE_LINE_NUM (une ligne par correction).'
    exit $EXIT_TECH
}
Ok "Fichier CSV   : $Csv"

$SqlSource = Join-Path $ScriptDir 'Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql'
if (-not (Test-Path $SqlSource)) {
    Ko "[ERREUR] Script SQL introuvable : $SqlSource"
    exit $EXIT_TECH
}

$SqlCmd = $null
foreach ($c in @('sqlplus', 'sqlcl', 'sql')) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $SqlCmd = $c; break }
}
if ($null -eq $SqlCmd) {
    Ko '[ERREUR] Aucun client Oracle trouve (sqlplus, sqlcl ou sql).'
    exit $EXIT_TECH
}
Ok "Client Oracle : $SqlCmd"

if ($LogDir -eq '') { $LogDir = Join-Path $ScriptDir 'Logs' }
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$FichierLog  = Join-Path $LogDir "update_gl_${Timestamp}.log"
$FichierUndo = Join-Path $LogDir "undo_${Timestamp}.sql"
Ok "Dossier logs  : $LogDir"

$valeurUnistr = ConvertTo-Unistr -Texte $Valeur
Ok "Valeur cible  : $Valeur"
Ok "  -> UNISTR   : $valeurUnistr"
Write-Host ''

# =====================================================================
#  ETAPE 2 : CONFIGURATION ORACLE
# =====================================================================
Write-Host 'Etape 2 : Chargement de la configuration...' -ForegroundColor Yellow

$ConfigFile = $null
foreach ($cand in @((Join-Path $ScriptDir 'config.ps1'),
                    (Join-Path (Split-Path -Parent $ScriptDir) 'fichierConfig\config.ps1'))) {
    if (Test-Path $cand) { $ConfigFile = $cand; break }
}
if ($null -eq $ConfigFile) {
    Ko '[ERREUR] config.ps1 introuvable (ni local, ni dans ..\fichierConfig\).'
    exit $EXIT_TECH
}
. $ConfigFile

$OraDsn     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$ConnectStr = "${ORA_USER}/${ORA_PWD}@${OraDsn}"
Ok "Config     : $ConfigFile"
Ok "Connexion  : ${ORA_USER}@${OraDsn}"

$FndUserId     = if ($null -ne $FND_USER_ID)      { $FND_USER_ID }      else { -1 }
$FndRespId     = if ($null -ne $FND_RESP_ID)      { $FND_RESP_ID }      else { -1 }
$FndRespApplId = if ($null -ne $FND_RESP_APPL_ID) { $FND_RESP_APPL_ID } else { -1 }
if ([int]$FndUserId -le 0) {
    Ko '[ERREUR] FND_USER_ID absent du config.ps1 : APPS_INITIALIZE ne peut pas etre pose.'
    exit $EXIT_TECH
}
Ok "Contexte FND : $FND_USER_NAME (user_id=$FndUserId, resp=$FndRespId/$FndRespApplId)"
Write-Host ''

# =====================================================================
#  ETAPE 3 : LECTURE DU CSV
# =====================================================================
Write-Host 'Etape 3 : Lecture des lignes a corriger...' -ForegroundColor Yellow

$infoEnc = Get-EncodageFichier -Chemin $Csv
$texte   = [System.IO.File]::ReadAllText($Csv, $infoEnc.Enc)
Ok "Encodage detecte : $($infoEnc.Nom)"

$couples  = New-Object System.Collections.Generic.List[object]
$rejetees = New-Object System.Collections.Generic.List[string]
$vus      = @{}
$noLigne  = 0

foreach ($l in ($texte -split "`r?`n")) {
    $noLigne++
    $v = $l.Trim()
    if ($v -eq '') { continue }

    # Separateur tolerant : point-virgule, virgule ou tabulation.
    $ch = $v -split '[;,\t]'
    if ($ch.Count -lt 2) { $rejetees.Add("ligne $noLigne : '$v'"); continue }

    $h = $ch[0].Trim().Trim('"')
    $n = $ch[1].Trim().Trim('"')

    # En-tete eventuel : ignore sans le compter comme anomalie.
    if ($h -match '(?i)je_header|header') { continue }

    if ($h -notmatch '^\d+$' -or $n -notmatch '^\d+$') {
        $rejetees.Add("ligne $noLigne : '$v'")
        continue
    }

    $cle = "$h|$n"
    if ($vus.ContainsKey($cle)) { continue }
    $vus[$cle] = $true
    $couples.Add([PSCustomObject]@{ Header = $h; Ligne = $n })
}

Ok "Couples retenus : $($couples.Count)"
if ($rejetees.Count -gt 0) {
    Avt "[ATTENTION] $($rejetees.Count) ligne(s) ignoree(s) car non exploitable(s) :"
    $rejetees | Select-Object -First 10 | ForEach-Object { Avt "              $_" }
    if ($rejetees.Count -gt 10) { Avt "              ... et $($rejetees.Count - 10) autre(s)" }
}
if ($couples.Count -eq 0) {
    Ko '[ERREUR] Aucun couple (JE_HEADER_ID, JE_LINE_NUM) exploitable.'
    exit $EXIT_TECH
}
if ($couples.Count -gt $MaxLignes) {
    Ko "[ERREUR] $($couples.Count) lignes, au-dela du plafond de $MaxLignes."
    exit $EXIT_TECH
}
Write-Host ''

# =====================================================================
#  ETAPE 4 : CONFIRMATION AVANT MODIFICATION REELLE
# =====================================================================
if ($Executer -and -not $SansConfirmation) {
    Titre 'CONFIRMATION REQUISE' 'Red'
    Write-Host "  Vous allez modifier GL_JE_LINES.$Attribut sur $($couples.Count) ligne(s)." -ForegroundColor Red
    Write-Host "  Nouvelle valeur : $Valeur" -ForegroundColor Red
    Write-Host "  Base            : ${ORA_USER}@${OraDsn}" -ForegroundColor Red
    Write-Host ''
    Write-Host '  Saisir OUI (en majuscules) pour confirmer, toute autre saisie annule.' -ForegroundColor Yellow
    $rep = $null
    try { $rep = Read-Host '  Confirmation' }
    catch {
        Write-Host ''
        Ko '[ERREUR] Aucune saisie possible : la session n''est pas interactive.'
        Ko '         Relancer depuis une console, ou ajouter -SansConfirmation.'
        exit $EXIT_TECH
    }
    if ($rep -cne 'OUI') {
        Write-Host ''
        Avt 'Operation annulee. Aucune modification effectuee.'
        exit $EXIT_ANNULE
    }
    Write-Host ''
}

# =====================================================================
#  ETAPE 5 : GENERATION DU SCRIPT TEMPORAIRE
# =====================================================================
Write-Host 'Etape 5 : Generation du script SQL temporaire...' -ForegroundColor Yellow

$affect = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $couples.Count; $i++) {
    $affect.Add(("    l_hdr({0}) := {1}; l_lin({0}) := {2};" -f ($i + 1), $couples[$i].Header, $couples[$i].Ligne))
}

$corps = [System.IO.File]::ReadAllText($SqlSource, [System.Text.Encoding]::UTF8)
$corps = $corps.Replace('    -- @@LISTE_LIGNES@@', ($affect -join "`r`n"))
$corps = $corps.Replace('    -- @@VALEUR@@',
                        "    c_valeur CONSTANT VARCHAR2(240) := UNISTR('$valeurUnistr');")

$entete = @(
    "-- Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') par Update_GL_JE_LINES.ps1",
    "-- Source CSV : $Csv",
    '',
    'WHENEVER SQLERROR EXIT FAILURE',
    '',
    "DEFINE P_MODE          = `"$Mode`"",
    "DEFINE P_ATTRIBUT      = `"$Attribut`"",
    "DEFINE P_USER_ID       = $FndUserId",
    "DEFINE P_RESP_ID       = $FndRespId",
    "DEFINE P_RESP_APPL_ID  = $FndRespApplId",
    "DEFINE P_ORG_ID        = $OrgId",
    '',
    "SPOOL $($FichierLog.Replace('\','/'))",
    ''
) -join "`r`n"

$pied = @('', 'SPOOL OFF', 'EXIT;') -join "`r`n"

$FichierSqlTmp = Join-Path $LogDir "temp_update_gl_${Timestamp}.sql"
# UTF-8 sans BOM : sqlplus echoue sur la premiere instruction s'il en trouve
# un. Le fichier est de toute facon pur ASCII grace a la notation UNISTR.
[System.IO.File]::WriteAllText($FichierSqlTmp, ($entete + $corps + $pied),
    (New-Object System.Text.UTF8Encoding $false))
Ok "Fichier temp : $FichierSqlTmp"
Ok "Lignes injectees : $($affect.Count)"
Write-Host ''

# =====================================================================
#  ETAPE 6 : EXECUTION
# =====================================================================
Write-Host "Etape 6 : Execution Oracle ($Mode)..." -ForegroundColor Yellow
$env:NLS_LANG = 'FRENCH_FRANCE.AL32UTF8'
$t0    = Get-Date
& $SqlCmd -S $ConnectStr "@$FichierSqlTmp" | Out-Null
$rc    = $LASTEXITCODE
$duree = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
else { Avt "[INFO] Script SQL conserve : $FichierSqlTmp" }
Ok "Termine en ${duree}s (code retour $rc)"
Write-Host ''

# =====================================================================
#  ETAPE 7 : ANALYSE
# =====================================================================
Write-Host 'Etape 7 : Analyse du resultat...' -ForegroundColor Yellow

if (-not (Test-Path $FichierLog)) {
    Ko "[ERREUR] Aucun log produit : $FichierLog"
    exit $EXIT_TECH
}

$logLignes = Get-Content $FichierLog -Encoding UTF8
$anciennes = New-Object System.Collections.Generic.List[object]
$absents   = New-Object System.Collections.Generic.List[string]
$resume    = @{}
$erreurs   = @($logLignes | Where-Object { $_ -match '^##ERR##' -or $_ -match '^ORA-\d+' -or $_ -match '^SP2-\d+' })

foreach ($l in $logLignes) {
    if ($l -match '^##OLD##([^|]+)\|([^|]+)\|(.*)$') {
        $anciennes.Add([PSCustomObject]@{ Header = $Matches[1]; Ligne = $Matches[2]; Ancienne = $Matches[3] })
        continue
    }
    if ($l -match '^##ABSENT##([^|]+)\|(.*)$') { $absents.Add("$($Matches[1]) / $($Matches[2])"); continue }
    if ($l -match '^##SUM##(.*)$') {
        foreach ($p in $Matches[1].Split(';')) {
            $kv = $p.Split('='); if ($kv.Count -eq 2) { $resume[$kv[0]] = [int]$kv[1] }
        }
    }
}

# Le log destine a la lecture humaine est debarrasse des lignes balisees.
$logPropre = $logLignes | Where-Object { $_ -notmatch '^##(OLD|ABSENT|SUM|ERR)##' }
[System.IO.File]::WriteAllLines($FichierLog, $logPropre, (New-Object System.Text.UTF8Encoding $true))

Ok "$($anciennes.Count) valeur(s) d'origine relevee(s), $($absents.Count) couple(s) introuvable(s)"
Write-Host ''

# =====================================================================
#  ETAPE 8 : FICHIER D'ANNULATION
# =====================================================================
if ($Executer -and $erreurs.Count -eq 0 -and $absents.Count -eq 0 -and $anciennes.Count -gt 0) {
    Write-Host 'Etape 8 : Generation du fichier d''annulation...' -ForegroundColor Yellow
    $undo = New-Object System.Collections.Generic.List[string]
    $undo.Add('-- =====================================================================')
    $undo.Add("-- Annulation de la correction du $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
    $undo.Add("-- Restaure GL_JE_LINES.$Attribut dans son etat anterieur.")
    $undo.Add('--')
    $undo.Add('-- Les valeurs sont en notation UNISTR : elles ne dependent donc ni de')
    $undo.Add('-- l''encodage de ce fichier, ni du NLS_LANG du poste qui le rejoue.')
    $undo.Add('-- A RELIRE AVANT EXECUTION.')
    $undo.Add('-- =====================================================================')
    $undo.Add('SET SERVEROUTPUT ON')
    $undo.Add('BEGIN')
    foreach ($a in $anciennes) {
        if ([string]::IsNullOrEmpty($a.Ancienne)) {
            $undo.Add("    UPDATE gl.gl_je_lines SET $Attribut = NULL, last_update_date = SYSDATE")
        } else {
            $val = $a.Ancienne.Replace("'", "''")
            $undo.Add("    UPDATE gl.gl_je_lines SET $Attribut = UNISTR('$val'), last_update_date = SYSDATE")
        }
        $undo.Add("     WHERE je_header_id = $($a.Header) AND je_line_num = $($a.Ligne);")
    }
    $undo.Add('    COMMIT;')
    $undo.Add("    DBMS_OUTPUT.PUT_LINE('Annulation effectuee : $($anciennes.Count) ligne(s) restauree(s).');")
    $undo.Add('END;')
    $undo.Add('/')
    [System.IO.File]::WriteAllText($FichierUndo, ($undo -join "`r`n"),
        (New-Object System.Text.UTF8Encoding $false))
    Ok "Fichier annulation : $FichierUndo"
    Write-Host ''
}

# =====================================================================
#  ETAPE 9 : SYNTHESE
# =====================================================================
$nbMaj    = if ($resume.ContainsKey('maj'))    { $resume['maj'] }    else { 0 }
$nbAbsent = if ($resume.ContainsKey('absent')) { $resume['absent'] } else { $absents.Count }
$nbDeja   = if ($resume.ContainsKey('deja'))   { $resume['deja'] }   else { 0 }

$couleur = if ($erreurs.Count -gt 0) { 'Red' } elseif ($nbAbsent -gt 0) { 'Yellow' } else { 'Green' }
Titre 'SYNTHESE' $couleur
Write-Host ("  {0,-26} : {1}" -f 'Mode', $Mode) -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host ("  {0,-26} : {1}" -f 'Colonne', "GL_JE_LINES.$Attribut")
Write-Host ("  {0,-26} : {1}" -f 'Nouvelle valeur', $Valeur)
Write-Host ("  {0,-26} : {1}" -f 'Lignes demandees', $couples.Count)
Write-Host ("  {0,-26} : {1}" -f 'Lignes mises a jour', $nbMaj) -ForegroundColor $(if ($nbMaj -eq $couples.Count) { 'Green' } else { 'Yellow' })
Write-Host ("  {0,-26} : {1}" -f 'Deja a la bonne valeur', $nbDeja)
if ($nbAbsent -gt 0) {
    Write-Host ("  {0,-26} : {1}" -f 'Couples introuvables', $nbAbsent) -ForegroundColor Yellow
    $absents | Select-Object -First 15 | ForEach-Object { Write-Host "       $_" -ForegroundColor Yellow }
    if ($absents.Count -gt 15) { Write-Host "       ... et $($absents.Count - 15) autre(s)" -ForegroundColor Yellow }
}
Write-Host ("  {0,-26} : {1}" -f 'Log', $FichierLog) -ForegroundColor Green
if ($Executer -and (Test-Path $FichierUndo)) {
    Write-Host ("  {0,-26} : {1}" -f 'Annulation', $FichierUndo) -ForegroundColor Magenta
}

if ($erreurs.Count -gt 0) {
    Write-Host ''
    Ko 'Erreurs remontees par Oracle :'
    $erreurs | Select-Object -Unique -First 10 | ForEach-Object { Ko "   $_" }
}

Write-Host ('=' * 71) -ForegroundColor $couleur
Write-Host ''

if (-not $Executer -and $erreurs.Count -eq 0) {
    Avt 'Simulation uniquement : aucune modification en base.'
    Avt 'Pour appliquer reellement :'
    Write-Host "     .\Update_GL_JE_LINES.ps1 -Executer" -ForegroundColor White
    Write-Host ''
}

if ($erreurs.Count -gt 0 -or $rc -ne 0) { exit $EXIT_TECH }
if ($nbAbsent -gt 0) { exit $EXIT_ECART }
exit $EXIT_OK
