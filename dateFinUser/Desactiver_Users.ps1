# =====================================================================
#  Desactivation d'utilisateurs Oracle EBS a une date donnee
# =====================================================================
#  Lit un CSV de matricules, resout chaque compte FND_USER puis pose
#  FND_USER.END_DATE par UPDATE direct sur APPLSYS.FND_USER.
#
#  SIMULATION PAR DEFAUT : sans -Executer, les UPDATE sont joues puis
#  annules par ROLLBACK. Rien n'est conserve, mais les droits d'ecriture
#  et le ciblage des lignes sont reellement valides.
#
#  Usage :
#    .\Desactiver_Users.ps1 -DateFin "31/12/2026"
#    .\Desactiver_Users.ps1 -DateFin "31/12/2026" -Executer
#    .\Desactiver_Users.ps1 -DateFin "31/12/2026" -Csv autre_liste.csv -Executer
#
#  Connexion : ..\fichierConfig\config.ps1
# =====================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]   $DateFin,                  # Date de fin a poser : JJ/MM/AAAA ou AAAA-MM-JJ
    [string]   $Csv               = "listeusedesactive.csv",
    [switch]   $Executer,                 # Sans ce commutateur : simulation seule
    [switch]   $SansConfirmation,         # Pour une execution planifiee, sans invite clavier
    [string]   $UserEbs           = $env:USERNAME,   # Compte EBS trace dans les colonnes WHO
    [string]   $LogDir            = "",
    [switch]   $GarderTempSQL,
    [switch]   $PasDOuverture             # Ne pas ouvrir le rapport a la fin
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Mode      = if ($Executer) { 'EXECUTION' } else { 'SIMULATION' }

# ---------------------------------------------------------------------
#  Petites aides d'affichage
# ---------------------------------------------------------------------
function Ecrire-Titre {
    param([string]$Texte, [string]$Couleur = 'Cyan')
    Write-Host ''
    Write-Host ('=' * 71) -ForegroundColor $Couleur
    Write-Host "  $Texte" -ForegroundColor $Couleur
    Write-Host ('=' * 71) -ForegroundColor $Couleur
}
function Ecrire-Etape { param([string]$Texte) Write-Host "$Texte" -ForegroundColor Yellow }
function Ecrire-Ok    { param([string]$Texte) Write-Host "   $Texte" -ForegroundColor Green }
function Ecrire-Ko    { param([string]$Texte) Write-Host "   $Texte" -ForegroundColor Red }
# Les exports de ce projet arrivent tantot en CP850 (OEM, issu d'outils DOS
# ou d'Excel en export "MS-DOS"), tantot en Windows-1252. Les deux se
# distinguent de facon fiable : en CP850 les accents francais tombent dans
# 0x80-0x9F (e accent aigu = 0x82), alors qu'en Windows-1252 cette plage ne
# contient que de la ponctuation, et les accents sont au-dessus de 0xC0.
function Get-EncodageCsv {
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
    if ($nOem -gt $nAnsi) {
        return @{ Enc = [System.Text.Encoding]::GetEncoding(850);  Nom = 'CP850 (OEM)' }
    }
    return @{ Enc = [System.Text.Encoding]::GetEncoding(1252); Nom = 'Windows-1252' }
}

function Html-Echap {
    param([string]$T)
    if ([string]::IsNullOrEmpty($T)) { return '' }
    return $T.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

Ecrire-Titre "DESACTIVATION UTILISATEURS ORACLE EBS  -  MODE $Mode" `
    $(if ($Executer) { 'Red' } else { 'Cyan' })
Write-Host "  Date execution  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Mode            : $Mode" -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host ''

# =====================================================================
#  ETAPE 1 : PREREQUIS
# =====================================================================
Ecrire-Etape 'Etape 1 : Verification des prerequis...'

# --- Date de fin ---
$dateFinObj = $null
foreach ($fmt in @('dd/MM/yyyy', 'yyyy-MM-dd', 'd/M/yyyy')) {
    $tmp = [datetime]::MinValue
    if ([datetime]::TryParseExact($DateFin, $fmt, [cultureinfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None, [ref]$tmp)) { $dateFinObj = $tmp; break }
}
if ($null -eq $dateFinObj) {
    Ecrire-Ko "[ERREUR] Date de fin illisible : '$DateFin'. Formats acceptes : JJ/MM/AAAA ou AAAA-MM-JJ."
    exit 1
}
$DateFinSql = $dateFinObj.ToString('yyyy-MM-dd')
$DateFinFr  = $dateFinObj.ToString('dd/MM/yyyy')
Ecrire-Ok "Date de fin     : $DateFinFr"
if ($dateFinObj.Date -lt (Get-Date).Date) {
    Write-Host "   [ATTENTION] Cette date est dans le passe : les comptes seront clos immediatement." -ForegroundColor Yellow
}

# --- Fichier CSV ---
if (-not [System.IO.Path]::IsPathRooted($Csv)) { $Csv = Join-Path $ScriptDir $Csv }
if (-not (Test-Path $Csv)) {
    Ecrire-Ko "[ERREUR] Fichier CSV introuvable : $Csv"
    exit 1
}
Ecrire-Ok "Fichier CSV     : $Csv"

# --- Client Oracle ---
$SqlCmd = $null
foreach ($c in @('sqlplus', 'sql', 'sqlcl')) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $SqlCmd = $c; break }
}
if ($null -eq $SqlCmd) {
    Ecrire-Ko '[ERREUR] Aucun client Oracle trouve (sqlplus, sql ou sqlcl).'
    exit 1
}
Ecrire-Ok "Client Oracle   : $SqlCmd"

# --- Script SQL ---
$SqlSource = Join-Path $ScriptDir 'desactivation_users.sql'
if (-not (Test-Path $SqlSource)) {
    Ecrire-Ko "[ERREUR] Script SQL introuvable : $SqlSource"
    exit 1
}

# --- Dossier de logs ---
if ($LogDir -eq '') { $LogDir = Join-Path $ScriptDir 'Logs' }
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$FichierLogBrut = Join-Path $LogDir "desactivation_${Timestamp}.log"
$FichierRapport = Join-Path $LogDir "desactivation_${Timestamp}.html"
$FichierUndo    = Join-Path $LogDir "undo_${Timestamp}.sql"
Ecrire-Ok "Dossier logs    : $LogDir"
Write-Host ''

# =====================================================================
#  ETAPE 2 : CONNEXION ORACLE
# =====================================================================
Ecrire-Etape 'Etape 2 : Chargement de la configuration Oracle...'

$ConfigFile = $null
foreach ($cand in @(
        (Join-Path $ScriptDir 'config.ps1'),
        (Join-Path (Split-Path -Parent $ScriptDir) 'fichierConfig\config.ps1'))) {
    if (Test-Path $cand) { $ConfigFile = $cand; break }
}
if ($null -eq $ConfigFile) {
    Ecrire-Ko '[ERREUR] config.ps1 introuvable (ni local, ni dans ..\fichierConfig\).'
    exit 1
}
. $ConfigFile
$OraDsn     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$ConnectStr = "${ORA_USER}/${ORA_PWD}@${OraDsn}"
Ecrire-Ok "Config          : $ConfigFile"
Ecrire-Ok "Connexion       : ${ORA_USER}@${OraDsn}"
Write-Host ''

# =====================================================================
#  ETAPE 3 : LECTURE DU CSV
# =====================================================================
Ecrire-Etape 'Etape 3 : Lecture de la liste des matricules...'

$infoEnc   = Get-EncodageCsv -Chemin $Csv
$texteCsv  = [System.IO.File]::ReadAllText($Csv, $infoEnc.Enc)
$lignesCsv = @($texteCsv | ConvertFrom-Csv -Delimiter ';')
Ecrire-Ok "Encodage detecte  : $($infoEnc.Nom)"

if ($lignesCsv.Count -eq 0) {
    Ecrire-Ko '[ERREUR] Le fichier CSV ne contient aucune ligne de donnees.'
    exit 1
}

# Colonne matricule : par nom si present, sinon la premiere colonne.
$colonnes  = $lignesCsv[0].PSObject.Properties.Name
$colMat    = $colonnes | Where-Object { $_ -match '(?i)matricule' } | Select-Object -First 1
if (-not $colMat) { $colMat = $colonnes[0] }
$colNom    = $colonnes | Where-Object { $_ -match '(?i)nom'   } | Select-Object -First 1
$colMail   = $colonnes | Where-Object { $_ -match '(?i)mail'  } | Select-Object -First 1
Ecrire-Ok "Colonne matricule : '$colMat'"

$valides  = New-Object System.Collections.Generic.List[object]
$rejetes  = New-Object System.Collections.Generic.List[object]
$vus      = @{}

foreach ($l in $lignesCsv) {
    $mat = ''
    if ($null -ne $l.$colMat) { $mat = ([string]$l.$colMat).Trim() }
    $nom = ''
    if ($colNom -and $null -ne $l.$colNom) { $nom = (([string]$l.$colNom) -replace '\s+', ' ').Trim() }
    $mail = ''
    if ($colMail -and $null -ne $l.$colMail) { $mail = ([string]$l.$colMail).Trim() }

    if ($mat -eq '') { continue }

    # Le matricule part dans du texte SQL genere : on n'accepte qu'un jeu
    # de caracteres strict, tout le reste est ecarte et signale.
    if ($mat -notmatch '^[A-Za-z0-9._\-]{1,60}$') {
        $rejetes.Add([PSCustomObject]@{
            Matricule = $mat; Nom = $nom; Mail = $mail
            Statut = 'REJETE_FORMAT'
            Message = 'Caracteres non autorises dans le matricule : ligne ignoree.'
        })
        continue
    }

    $cle = $mat.ToUpper()
    if ($vus.ContainsKey($cle)) {
        $rejetes.Add([PSCustomObject]@{
            Matricule = $mat; Nom = $nom; Mail = $mail
            Statut = 'DOUBLON'
            Message = 'Matricule deja present plus haut dans le fichier : ligne ignoree.'
        })
        continue
    }
    $vus[$cle] = $true
    $valides.Add([PSCustomObject]@{ Matricule = $mat; Nom = $nom; Mail = $mail })
}

Ecrire-Ok "Matricules retenus : $($valides.Count)"
if ($rejetes.Count -gt 0) {
    Write-Host "   [ATTENTION] $($rejetes.Count) ligne(s) ecartee(s) (format ou doublon)." -ForegroundColor Yellow
}
if ($valides.Count -eq 0) {
    Ecrire-Ko '[ERREUR] Aucun matricule exploitable.'
    exit 1
}
Write-Host ''

# =====================================================================
#  ETAPE 4 : CONFIRMATION AVANT MODIFICATION REELLE
# =====================================================================
if ($Executer -and -not $SansConfirmation) {
    Ecrire-Titre 'CONFIRMATION REQUISE' 'Red'
    Write-Host "  Vous allez desactiver $($valides.Count) compte(s) Oracle EBS." -ForegroundColor Red
    Write-Host "  Base       : ${ORA_USER}@${OraDsn}" -ForegroundColor Red
    Write-Host "  Date de fin: $DateFinFr" -ForegroundColor Red
    Write-Host ''
    Write-Host '  Saisir OUI (en majuscules) pour confirmer, toute autre saisie annule.' -ForegroundColor Yellow

    # En contexte non interactif (tache planifiee, execution redirigee), aucune
    # saisie n'est possible : on refuse plutot que d'agir sans confirmation.
    $rep = $null
    try {
        $rep = Read-Host '  Confirmation'
    } catch {
        Write-Host ''
        Ecrire-Ko '[ERREUR] Aucune saisie possible : la session n''est pas interactive.'
        Ecrire-Ko '         Relancer depuis une console, ou ajouter -SansConfirmation'
        Ecrire-Ko '         si la confirmation a deja ete obtenue par ailleurs.'
        exit 1
    }

    if ($rep -cne 'OUI') {
        Write-Host ''
        Write-Host '  Operation annulee par l''utilisateur. Aucune modification effectuee.' -ForegroundColor Yellow
        exit 0
    }
    Write-Host ''
}

# =====================================================================
#  ETAPE 5 : GENERATION DU SCRIPT TEMPORAIRE
# =====================================================================
Ecrire-Etape 'Etape 5 : Generation du script SQL temporaire...'

$affectations = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $valides.Count; $i++) {
    $m = $valides[$i].Matricule.Replace("'", "''")
    $affectations.Add(("    l_mat({0}) := '{1}';" -f ($i + 1), $m))
}

$corpsSql = [System.IO.File]::ReadAllText($SqlSource, [System.Text.Encoding]::UTF8)
$corpsSql = $corpsSql.Replace('    -- @@LISTE_MATRICULES@@', ($affectations -join "`r`n"))

$entete = @(
    "-- Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') par Desactiver_Users.ps1",
    "-- Source : $SqlSource",
    '',
    'SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED',
    'SET LINESIZE 32767',
    'SET PAGESIZE 0',
    'SET FEEDBACK OFF',
    'SET VERIFY OFF',
    'SET TRIMSPOOL ON',
    'SET SQLBLANKLINES ON',
    'SET DEFINE ON',
    'WHENEVER SQLERROR EXIT FAILURE',
    '',
    "DEFINE P_DATE_FIN = `"$DateFinSql`"",
    "DEFINE P_MODE     = `"$Mode`"",
    "DEFINE P_USER_EBS = `"$($UserEbs.ToUpper())`"",
    '',
    "SPOOL $($FichierLogBrut.Replace('\','/'))",
    ''
) -join "`r`n"

$pied = @('', 'SPOOL OFF', 'EXIT;') -join "`r`n"

$FichierSqlTemp = Join-Path $ScriptDir "temp_desactivation_${Timestamp}.sql"
[System.IO.File]::WriteAllText($FichierSqlTemp, ($entete + $corpsSql + $pied),
    (New-Object System.Text.UTF8Encoding $true))
Ecrire-Ok "Fichier temp    : $FichierSqlTemp"
Ecrire-Ok "Matricules injectes : $($affectations.Count)"
Write-Host ''

# =====================================================================
#  ETAPE 6 : EXECUTION
# =====================================================================
Ecrire-Etape "Etape 6 : Execution Oracle ($Mode)..."
$env:NLS_LANG = 'FRENCH_FRANCE.AL32UTF8'
$t0 = Get-Date
& $SqlCmd -S $ConnectStr "@$FichierSqlTemp" | Out-Null
$rc    = $LASTEXITCODE
$duree = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

if (-not $GarderTempSQL) {
    Remove-Item $FichierSqlTemp -ErrorAction SilentlyContinue
} else {
    Write-Host "   [INFO] Fichier temporaire conserve : $FichierSqlTemp" -ForegroundColor Yellow
}
Ecrire-Ok "Termine en ${duree}s (code retour $rc)"
Write-Host ''

# =====================================================================
#  ETAPE 7 : ANALYSE DU RESULTAT
# =====================================================================
Ecrire-Etape 'Etape 7 : Analyse du resultat...'

if (-not (Test-Path $FichierLogBrut)) {
    Ecrire-Ko "[ERREUR] Aucun log produit : $FichierLogBrut"
    Ecrire-Ko '          Verifier la connexion Oracle et les droits d''ecriture.'
    exit 1
}

$logLignes = Get-Content $FichierLogBrut -Encoding UTF8
$infos     = New-Object System.Collections.Generic.List[string]
$erreurs   = New-Object System.Collections.Generic.List[string]
$resultats = New-Object System.Collections.Generic.List[object]
$resume    = @{}

# Index nom/mail du CSV pour enrichir le rapport.
$idxCsv = @{}
foreach ($v in $valides) { $idxCsv[$v.Matricule.ToUpper()] = $v }

foreach ($ligne in $logLignes) {
    if ($ligne -match '^##INFO##(.*)$') { $infos.Add($Matches[1]); continue }
    if ($ligne -match '^##ERR##(.*)$')  { $erreurs.Add($Matches[1]); continue }
    if ($ligne -match '^##SUM##(.*)$')  {
        foreach ($p in $Matches[1].Split(';')) {
            $kv = $p.Split('=')
            if ($kv.Count -eq 2) { $resume[$kv[0]] = [int]$kv[1] }
        }
        continue
    }
    if ($ligne -match '^##RES##(.*)$') {
        $ch = $Matches[1].Split('|')
        while ($ch.Count -lt 7) { $ch += '' }
        $mat = $ch[0]
        $src = $null
        if ($idxCsv.ContainsKey($mat.ToUpper())) { $src = $idxCsv[$mat.ToUpper()] }
        $resultats.Add([PSCustomObject]@{
            Matricule   = $mat
            Nom         = if ($src) { $src.Nom }  else { '' }
            Mail        = if ($src) { $src.Mail } else { '' }
            UserName    = $ch[1]
            Resolution  = $ch[2]
            AncienneFin = $ch[3]
            NouvelleFin = $ch[4]
            Statut      = $ch[5]
            Message     = $ch[6].Trim()
        })
        continue
    }
}

# Les lignes ecartees au parsing du CSV rejoignent le rapport.
foreach ($r in $rejetes) {
    $resultats.Add([PSCustomObject]@{
        Matricule = $r.Matricule; Nom = $r.Nom; Mail = $r.Mail
        UserName = ''; Resolution = ''; AncienneFin = ''; NouvelleFin = ''
        Statut = $r.Statut; Message = $r.Message
    })
}

$errOra = $logLignes | Where-Object { $_ -match '^ORA-\d+' -or $_ -match '^SP2-\d+' -or $_ -match '^PLS-\d+' }
Ecrire-Ok "$($resultats.Count) ligne(s) de resultat analysee(s)"
Write-Host ''

# =====================================================================
#  ETAPE 8 : FICHIER D'ANNULATION
# =====================================================================
$desactives = @($resultats | Where-Object { $_.Statut -eq 'DESACTIVE' })
if ($Executer -and $desactives.Count -gt 0) {
    Ecrire-Etape 'Etape 8 : Generation du fichier d''annulation...'
    $undo = New-Object System.Collections.Generic.List[string]
    $undo.Add('-- =====================================================================')
    $undo.Add("-- Annulation du lot de desactivation du $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
    $undo.Add("-- Restaure les valeurs de FND_USER.END_DATE anterieures a l'operation.")
    $undo.Add('--')
    $undo.Add('-- A RELIRE AVANT EXECUTION. Reactiver un compte reouvre des droits :')
    $undo.Add('-- ne jouer ce fichier qu''apres validation du responsable habilitations.')
    $undo.Add('-- =====================================================================')
    $undo.Add('SET SERVEROUTPUT ON')
    $undo.Add('BEGIN')
    foreach ($d in $desactives) {
        $u = $d.UserName.Replace("'", "''")
        if ([string]::IsNullOrWhiteSpace($d.AncienneFin)) {
            $undo.Add("    -- $($d.Matricule) : aucune date de fin avant l'operation")
            $undo.Add("    UPDATE applsys.fnd_user SET end_date = NULL, last_update_date = SYSDATE")
            $undo.Add("     WHERE UPPER(user_name) = UPPER('$u');")
        } else {
            $dt = [datetime]::ParseExact($d.AncienneFin, 'dd/MM/yyyy', [cultureinfo]::InvariantCulture)
            $undo.Add("    -- $($d.Matricule) : date de fin d'origine $($d.AncienneFin)")
            $undo.Add("    UPDATE applsys.fnd_user SET end_date = TO_DATE('$($dt.ToString('yyyy-MM-dd'))','YYYY-MM-DD'), last_update_date = SYSDATE")
            $undo.Add("     WHERE UPPER(user_name) = UPPER('$u');")
        }
    }
    $undo.Add('    COMMIT;')
    $undo.Add("    DBMS_OUTPUT.PUT_LINE('Annulation effectuee : $($desactives.Count) compte(s) restaure(s).');")
    $undo.Add('END;')
    $undo.Add('/')
    [System.IO.File]::WriteAllText($FichierUndo, ($undo -join "`r`n"),
        (New-Object System.Text.UTF8Encoding $true))
    Ecrire-Ok "Fichier annulation : $FichierUndo"
    Write-Host ''
}

# =====================================================================
#  ETAPE 9 : RAPPORT HTML
# =====================================================================
Ecrire-Etape 'Etape 9 : Generation du rapport...'

$styleStatut = @{
    'DESACTIVE'      = @{ c = '#0b6b3a'; f = '#d7f2e3'; l = 'Desactive' }
    'A_DESACTIVER'   = @{ c = '#0a4d8c'; f = '#d9e9fb'; l = 'A desactiver' }
    'DEJA_A_JOUR'    = @{ c = '#5a5a5a'; f = '#ececec'; l = 'Deja a jour' }
    'DEJA_DESACTIVE' = @{ c = '#5a5a5a'; f = '#ececec'; l = 'Deja desactive' }
    'INTROUVABLE'    = @{ c = '#8a5a00'; f = '#fdeccd'; l = 'Introuvable' }
    'AMBIGU'         = @{ c = '#8a5a00'; f = '#fdeccd'; l = 'Ambigu' }
    'PROTEGE'        = @{ c = '#5b2d8e'; f = '#ebdcfa'; l = 'Compte protege' }
    'ERREUR'         = @{ c = '#9b1c1c'; f = '#fbdcdc'; l = 'Erreur' }
    'REJETE_FORMAT'  = @{ c = '#9b1c1c'; f = '#fbdcdc'; l = 'Format rejete' }
    'DOUBLON'        = @{ c = '#8a5a00'; f = '#fdeccd'; l = 'Doublon' }
}
function Pastille {
    param([string]$Statut)
    $s = $styleStatut[$Statut]
    if (-not $s) { $s = @{ c = '#333'; f = '#eee'; l = $Statut } }
    return "<span class=""pill"" style=""color:$($s.c);background:$($s.f)"">$(Html-Echap $s.l)</span>"
}

$nbAnomalies = @($resultats | Where-Object {
    $_.Statut -in @('INTROUVABLE','AMBIGU','ERREUR','REJETE_FORMAT') }).Count

$tuiles = @(
    @{ n = 'Matricules';     v = $resultats.Count;                                                        c = '#003366' }
    @{ n = $(if ($Executer) { 'Desactives' } else { 'A desactiver' });
       v = @($resultats | Where-Object { $_.Statut -in @('DESACTIVE','A_DESACTIVER') }).Count;            c = '#0b6b3a' }
    @{ n = 'Deja clos';      v = @($resultats | Where-Object { $_.Statut -like 'DEJA_*' }).Count;         c = '#5a5a5a' }
    @{ n = 'Introuvables';   v = @($resultats | Where-Object { $_.Statut -eq 'INTROUVABLE' }).Count;      c = '#8a5a00' }
    @{ n = 'Ambigus';        v = @($resultats | Where-Object { $_.Statut -eq 'AMBIGU' }).Count;           c = '#8a5a00' }
    @{ n = 'Proteges';       v = @($resultats | Where-Object { $_.Statut -eq 'PROTEGE' }).Count;          c = '#5b2d8e' }
    @{ n = 'Erreurs';        v = @($resultats | Where-Object { $_.Statut -in @('ERREUR','REJETE_FORMAT') }).Count; c = '#9b1c1c' }
)

$htmlTuiles = ($tuiles | ForEach-Object {
    "<div class=""tile""><div class=""tv"" style=""color:$($_.c)"">$($_.v)</div><div class=""tn"">$($_.n)</div></div>"
}) -join ''

$ordreStatut = @{ 'ERREUR'=1; 'REJETE_FORMAT'=2; 'AMBIGU'=3; 'INTROUVABLE'=4; 'PROTEGE'=5
                  'DESACTIVE'=6; 'A_DESACTIVER'=7; 'DOUBLON'=8; 'DEJA_A_JOUR'=9; 'DEJA_DESACTIVE'=10 }
$lignesTriees = $resultats | Sort-Object `
    @{ Expression = { if ($ordreStatut.ContainsKey($_.Statut)) { $ordreStatut[$_.Statut] } else { 99 } } },
    @{ Expression = { $_.Matricule } }

$htmlLignes = ($lignesTriees | ForEach-Object {
    $cls = if ($_.Statut -in @('ERREUR','REJETE_FORMAT','AMBIGU','INTROUVABLE')) { ' class="warn"' } else { '' }
    "<tr$cls><td class=""mono"">$(Html-Echap $_.Matricule)</td>" +
    "<td>$(Html-Echap $_.Nom)</td>" +
    "<td class=""mono"">$(Html-Echap $_.UserName)</td>" +
    "<td>$(Html-Echap $_.Resolution)</td>" +
    "<td class=""ctr"">$(Html-Echap $_.AncienneFin)</td>" +
    "<td class=""ctr strong"">$(Html-Echap $_.NouvelleFin)</td>" +
    "<td>$(Pastille $_.Statut)</td>" +
    "<td class=""msg"">$(Html-Echap $_.Message)</td></tr>"
}) -join "`r`n"

$bandeauMode = if ($Executer) {
    if ($erreurs.Count -gt 0) {
        "<div class=""bandeau ko"">MODE EXECUTION &mdash; des erreurs sont survenues : un ROLLBACK complet a ete effectue, aucune modification n'a ete conservee.</div>"
    } else {
        "<div class=""bandeau ok"">MODE EXECUTION &mdash; les modifications ont ete validees en base (COMMIT).</div>"
    }
} else {
    "<div class=""bandeau sim"">MODE SIMULATION &mdash; aucune modification n'a ete effectuee en base. Relancer avec <code>-Executer</code> pour appliquer.</div>"
}

$htmlErreurs = ''
if ($erreurs.Count -gt 0 -or $errOra.Count -gt 0) {
    $lst = (@($erreurs) + @($errOra | Select-Object -Unique) | ForEach-Object { "<li>$(Html-Echap $_)</li>" }) -join ''
    $htmlErreurs = "<h2>Erreurs remontees par Oracle</h2><ul class=""err"">$lst</ul>"
}

$htmlInfos = ''
if ($infos.Count -gt 0) {
    $htmlInfos = "<h2>Journal d'execution</h2><ul class=""info"">" +
                 (($infos | ForEach-Object { "<li>$(Html-Echap $_)</li>" }) -join '') + '</ul>'
}

$htmlUndo = ''
if ($Executer -and $desactives.Count -gt 0) {
    $htmlUndo = "<div class=""undo""><strong>Fichier d'annulation genere :</strong> " +
                "<code>$(Html-Echap (Split-Path $FichierUndo -Leaf))</code><br>" +
                "Il restaure les dates de fin d'origine des $($desactives.Count) compte(s) traite(s). A relire avant tout usage.</div>"
}

$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Desactivation utilisateurs EBS - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 24px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1500px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 16px 22px; border-radius: 6px;
       font-size: 1.25em; margin: 0 0 4px 0; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 34px; font-size: 1.05em; }
  .meta { background: #e8f0fe; border-left: 4px solid #003366; padding: 10px 16px;
          margin: 14px 0 18px 0; border-radius: 0 4px 4px 0; font-size: .88em; }
  .meta span { margin-right: 22px; display: inline-block; }
  .bandeau { padding: 12px 18px; border-radius: 6px; margin-bottom: 18px;
             font-weight: 600; font-size: .92em; }
  .bandeau.sim { background: #fff4d6; color: #7a5600; border: 1px solid #e8c46a; }
  .bandeau.ok  { background: #d7f2e3; color: #0b6b3a; border: 1px solid #7fc9a3; }
  .bandeau.ko  { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; }
  .tiles { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 8px; }
  .tile { flex: 1 1 130px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 14px 10px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.9em; font-weight: 700; line-height: 1.1; }
  .tn { font-size: .78em; color: #57606a; text-transform: uppercase;
        letter-spacing: .04em; margin-top: 4px; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px;
               box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  table { border-collapse: collapse; width: 100%; }
  th { background: #003366; color: #fff; padding: 10px 12px; text-align: left;
       font-size: .82em; white-space: nowrap; position: sticky; top: 0; }
  td { padding: 8px 12px; border-bottom: 1px solid #eceff2; font-size: .85em;
       vertical-align: top; }
  tr:nth-child(even) td { background: #fafbfc; }
  tr:hover td { background: #eef4fd; }
  tr.warn td { background: #fffaf0; }
  tr.warn:hover td { background: #fdf3e0; }
  .mono { font-family: Consolas, Menlo, monospace; font-size: .93em; white-space: nowrap; }
  .ctr { text-align: center; white-space: nowrap; }
  .strong { font-weight: 700; }
  .msg { color: #57606a; font-size: .93em; }
  td:empty::after { content: '-'; color: #c0c6cd; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px;
          font-size: .82em; font-weight: 600; white-space: nowrap; }
  ul.err, ul.info { background: #fff; border-radius: 6px; padding: 12px 12px 12px 32px;
                    box-shadow: 0 1px 3px rgba(0,0,0,.1); font-size: .86em; }
  ul.err li { color: #9b1c1c; margin: 4px 0; font-family: Consolas, monospace; }
  ul.info li { color: #3d4650; margin: 4px 0; }
  .undo { background: #fff; border-left: 4px solid #5b2d8e; padding: 12px 16px;
          border-radius: 0 4px 4px 0; margin-top: 18px; font-size: .87em; }
  code { background: #f0f2f5; padding: 1px 6px; border-radius: 3px;
         font-family: Consolas, monospace; }
  .footer { font-size: .78em; color: #8b949e; margin-top: 34px; text-align: center; }
</style>
</head>
<body>
<div class="wrap">
<h1>Desactivation d'utilisateurs Oracle EBS</h1>
<div class="meta">
  <span><strong>Date :</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</span>
  <span><strong>Date de fin appliquee :</strong> $DateFinFr</span>
  <span><strong>Base :</strong> $(Html-Echap "${ORA_USER}@${OraDsn}")</span>
  <span><strong>Source :</strong> $(Html-Echap (Split-Path $Csv -Leaf)) ($($infoEnc.Nom))</span>
  <span><strong>Duree :</strong> ${duree}s</span>
</div>
$bandeauMode
<div class="tiles">$htmlTuiles</div>
<h2>Detail par matricule</h2>
<div class="tablewrap">
<table>
<thead><tr>
  <th>Matricule</th><th>Nom (CSV)</th><th>Compte EBS</th><th>Resolu par</th>
  <th>Ancienne fin</th><th>Nouvelle fin</th><th>Statut</th><th>Commentaire</th>
</tr></thead>
<tbody>
$htmlLignes
</tbody>
</table>
</div>
$htmlUndo
$htmlErreurs
$htmlInfos
<div class="footer">Genere par Desactiver_Users.ps1 &mdash; Oracle EBS &mdash; $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</div>
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText($FichierRapport, $html, (New-Object System.Text.UTF8Encoding $true))
Ecrire-Ok "Rapport HTML    : $FichierRapport"
Write-Host ''

# =====================================================================
#  ETAPE 10 : SYNTHESE CONSOLE
# =====================================================================
Ecrire-Titre 'SYNTHESE' $(if ($nbAnomalies -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ("  {0,-24} : {1}" -f 'Mode', $Mode) -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host ("  {0,-24} : {1}" -f 'Date de fin appliquee', $DateFinFr)
Write-Host ("  {0,-24} : {1}" -f 'Matricules traites', $resultats.Count)
Write-Host ''
foreach ($g in ($resultats | Group-Object Statut | Sort-Object Name)) {
    $col = switch -Wildcard ($g.Name) {
        'DESACTIVE'     { 'Green' }
        'A_DESACTIVER'  { 'Cyan' }
        'DEJA_*'        { 'DarkGray' }
        'PROTEGE'       { 'Magenta' }
        'ERREUR'        { 'Red' }
        'REJETE_FORMAT' { 'Red' }
        default         { 'Yellow' }
    }
    Write-Host ("  {0,-24} : {1,4}" -f $g.Name, $g.Count) -ForegroundColor $col
}
Write-Host ''
Write-Host ("  {0,-24} : {1}" -f 'Rapport', $FichierRapport) -ForegroundColor Green
Write-Host ("  {0,-24} : {1}" -f 'Log brut', $FichierLogBrut)
if ($Executer -and $desactives.Count -gt 0) {
    Write-Host ("  {0,-24} : {1}" -f 'Annulation', $FichierUndo) -ForegroundColor Magenta
}

if ($nbAnomalies -gt 0) {
    Write-Host ''
    Write-Host "  $nbAnomalies matricule(s) demandent une reprise manuelle :" -ForegroundColor Yellow
    foreach ($a in ($resultats | Where-Object { $_.Statut -in @('INTROUVABLE','AMBIGU','ERREUR','REJETE_FORMAT') } |
                    Sort-Object Statut, Matricule)) {
        Write-Host ("     {0,-12} {1,-16} {2}" -f $a.Matricule, $a.Statut, $a.Message) -ForegroundColor Yellow
    }
}

if (-not $Executer) {
    Write-Host ''
    Write-Host '  Simulation uniquement : aucune modification en base.' -ForegroundColor Yellow
    Write-Host '  Pour appliquer reellement :' -ForegroundColor Yellow
    Write-Host "     .\Desactiver_Users.ps1 -DateFin `"$DateFinFr`" -Executer" -ForegroundColor White
}
Write-Host ('=' * 71) -ForegroundColor $(if ($nbAnomalies -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ''

if (-not $PasDOuverture) { Start-Process $FichierRapport }

if ($rc -ne 0 -or $erreurs.Count -gt 0) { exit 1 }
exit 0
