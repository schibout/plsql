# =====================================================================
#  Moteur commun - Renvoi de factures Oracle EBS vers DacShop
# =====================================================================
#  Marque les factures d'AP.AP_INVOICES_ALL comme modifiees (colonnes WHO)
#  afin de declencher leur reprise par l'interface DacShop. En mode image,
#  remet aussi FND_ATTACHED_DOCUMENTS.ATTRIBUTE1 a NULL pour que les
#  documents attaches soient renvoyes.
#
#  Ce fichier n'est pas lance directement : envoiFacture\Update_AP_Invoices.ps1
#  et EnvoiImageEtFacture\Update_AP_Invoices_Image.ps1 l'appellent avec
#  leurs parametres. Les deux scripts etaient auparavant dupliques a
#  l'identique, ce qui imposait de corriger chaque anomalie deux fois.
#
#  SIMULATION PAR DEFAUT : sans -Executer, les UPDATE sont joues puis
#  annules par ROLLBACK. Rien n'est conserve, mais les droits d'ecriture
#  et le nombre de lignes reellement touchees sont valides.
# =====================================================================

param(
    [Parameter(Mandatory = $true)] [string] $CsvNom,     # ex. invoice.csv
    [Parameter(Mandatory = $true)] [string] $DossierBase,
    [string] $Libelle            = 'Renvoi factures',
    [switch] $AvecImages,                # traite aussi FND_ATTACHED_DOCUMENTS
    [switch] $Executer,                  # sans ce commutateur : simulation
    [switch] $SansConfirmation,          # pour une execution planifiee
    [switch] $AutoriserManquants,        # accepter que des IDs soient absents
    [int]    $MaxLignes          = 50000,
    [switch] $GarderTempSQL
)

$ErrorActionPreference = 'Stop'
$Timestamp = Get-Date -Format 'ddMMyyyy_HHmmss'
$Mode      = if ($Executer) { 'EXECUTION' } else { 'SIMULATION' }

# 0 = conforme, 1 = erreur technique, 2 = ecart fonctionnel, 3 = annule
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ECART = 2; $EXIT_ANNULE = 3

function Titre { param([string]$T, [string]$C = 'Cyan')
    Write-Host ''; Write-Host ('=' * 71) -ForegroundColor $C
    Write-Host "  $T" -ForegroundColor $C; Write-Host ('=' * 71) -ForegroundColor $C }
function Ok  { param([string]$T) Write-Host "   $T" -ForegroundColor Green }
function Ko  { param([string]$T) Write-Host "   $T" -ForegroundColor Red }
function Avt { param([string]$T) Write-Host "   $T" -ForegroundColor Yellow }

Titre "$Libelle  -  MODE $Mode" $(if ($Executer) { 'Red' } else { 'Cyan' })
Write-Host "  Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Mode           : $Mode" -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host "  Images         : $(if ($AvecImages) { 'oui (FND_ATTACHED_DOCUMENTS)' } else { 'non' })"
Write-Host ''

# =====================================================================
#  ETAPE 1 : CONFIGURATION
# =====================================================================
Write-Host 'Etape 1 : Chargement de la configuration...' -ForegroundColor Yellow

$ConfigFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'OracleVersDacShop\config.ps1'
if (-not (Test-Path $ConfigFile)) { $ConfigFile = Join-Path $PSScriptRoot 'config.ps1' }
if (-not (Test-Path $ConfigFile)) {
    Ko "[ERREUR] config.ps1 introuvable a cote de $PSScriptRoot"
    exit $EXIT_TECH
}
. (Resolve-Path $ConfigFile)

$OraDsn     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$ConnectStr = "${ORA_USER}/${ORA_PWD}@${OraDsn}"
Ok "Connexion : ${ORA_USER}@${OraDsn}"
Ok "FND User  : $FND_USER_NAME (USER_ID=$FND_USER_ID / RESP_ID=$FND_RESP_ID / APPL_ID=$FND_RESP_APPL_ID)"

$SqlCmd = $null
foreach ($c in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $SqlCmd = $c; break }
}
if ($null -eq $SqlCmd) {
    Ko '[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)'
    exit $EXIT_TECH
}
Ok "Client    : $SqlCmd"
Write-Host ''

# =====================================================================
#  ETAPE 2 : LECTURE DU CSV
# =====================================================================
Write-Host "Etape 2 : Lecture de $CsvNom..." -ForegroundColor Yellow

$CsvPath = Join-Path $DossierBase $CsvNom
if (-not (Test-Path $CsvPath)) {
    Ko "[ERREUR] $CsvNom introuvable : $CsvPath"
    exit $EXIT_TECH
}

# Trim AVANT le controle de format : la version precedente testait
# '^\d+$' sur la ligne brute, si bien qu'un identifiant suivi d'une
# espace ou d'un point-virgule etait ecarte sans le moindre message.
$lignes   = @(Get-Content $CsvPath)
$ids      = New-Object System.Collections.Generic.List[string]
$rejetees = New-Object System.Collections.Generic.List[string]
$doublons = New-Object System.Collections.Generic.List[string]
$vus      = @{}

foreach ($l in $lignes) {
    $v = ([string]$l).Trim().Trim(';', ',', '"')
    if ($v -eq '') { continue }
    if ($v -notmatch '^\d+$') {
        # L'entete eventuelle n'est pas une anomalie.
        if ($v -notmatch '(?i)invoice') { $rejetees.Add($v) }
        continue
    }
    if ($vus.ContainsKey($v)) { $doublons.Add($v); continue }
    $vus[$v] = $true
    $ids.Add($v)
}

$nbTotal = $ids.Count
Ok "Factures retenues : $nbTotal"
if ($doublons.Count -gt 0) {
    Avt "[ATTENTION] $($doublons.Count) doublon(s) ecarte(s) : sans cela, l'ecart"
    Avt "            entre identifiants fournis et lignes mises a jour serait faux."
}
if ($rejetees.Count -gt 0) {
    Avt "[ATTENTION] $($rejetees.Count) ligne(s) non numerique(s) ignoree(s) :"
    $rejetees | Select-Object -First 10 | ForEach-Object { Avt "              $_" }
    if ($rejetees.Count -gt 10) { Avt "              ... et $($rejetees.Count - 10) autre(s)" }
}
if ($nbTotal -eq 0) {
    Ko '[ERREUR] Aucun identifiant de facture exploitable.'
    exit $EXIT_TECH
}
if ($nbTotal -gt $MaxLignes) {
    Ko "[ERREUR] $nbTotal identifiants, au-dela du plafond de $MaxLignes."
    Ko '         Verifier le fichier, ou relever -MaxLignes en connaissance de cause.'
    exit $EXIT_TECH
}
Write-Host ''

# =====================================================================
#  ETAPE 3 : CONFIRMATION AVANT MODIFICATION REELLE
# =====================================================================
if ($Executer -and -not $SansConfirmation) {
    Titre 'CONFIRMATION REQUISE' 'Red'
    Write-Host "  Vous allez modifier $nbTotal facture(s) dans AP.AP_INVOICES_ALL." -ForegroundColor Red
    if ($AvecImages) {
        Write-Host '  Et remettre a NULL FND_ATTACHED_DOCUMENTS.ATTRIBUTE1 pour ces factures.' -ForegroundColor Red
    }
    Write-Host "  Base : ${ORA_USER}@${OraDsn}" -ForegroundColor Red
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
#  ETAPE 4 : GENERATION DU SCRIPT SQL
# =====================================================================
Write-Host 'Etape 4 : Generation du script SQL...' -ForegroundColor Yellow

$LogDir = Join-Path $DossierBase 'Logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$FichierSqlTmp = Join-Path $LogDir "update_ap_${Timestamp}.sql"
$FichierLog    = Join-Path $LogDir "update_ap_${Timestamp}.log"

# Lots de 999 : limite Oracle du nombre d'expressions d'une clause IN.
$batchSize = 999
$batches   = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $nbTotal; $i += $batchSize) {
    $fin = [Math]::Min($i + $batchSize - 1, $nbTotal - 1)
    $batches.Add(@($ids[$i..$fin]))
}
Write-Host "   Lots de $batchSize : $($batches.Count) lot(s)" -ForegroundColor Gray

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('SET SERVEROUTPUT ON SIZE UNLIMITED')
[void]$sb.AppendLine('SET FEEDBACK OFF')
[void]$sb.AppendLine('WHENEVER SQLERROR EXIT ROLLBACK')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('DECLARE')
[void]$sb.AppendLine("    v_user_id     NUMBER := $FND_USER_ID;")
[void]$sb.AppendLine("    v_resp_id     NUMBER := $FND_RESP_ID;")
[void]$sb.AppendLine("    v_resp_app_id NUMBER := $FND_RESP_APPL_ID;")
[void]$sb.AppendLine("    v_attendu     NUMBER := $nbTotal;")
[void]$sb.AppendLine('    v_total       NUMBER := 0;')
[void]$sb.AppendLine('    v_total_fad   NUMBER := 0;')
[void]$sb.AppendLine('BEGIN')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    FND_GLOBAL.APPS_INITIALIZE(v_user_id, v_resp_id, v_resp_app_id);')
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('APPS_INITIALIZE OK - USER=$FND_USER_NAME USER_ID=$FND_USER_ID RESP_ID=$FND_RESP_ID APPL_ID=$FND_RESP_APPL_ID');")
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('Mode : $Mode');")
[void]$sb.AppendLine('')

$lot = 1
foreach ($batch in $batches) {
    # Sous-lignes de 50 : au-dela, SQL*Plus tronque les lignes trop longues.
    $lineSize = 50
    $sousNum = @(); $sousStr = @()
    for ($j = 0; $j -lt $batch.Count; $j += $lineSize) {
        $f2 = [Math]::Min($j + $lineSize - 1, $batch.Count - 1)
        $sousNum += ($batch[$j..$f2] -join ', ')
        $sousStr += (($batch[$j..$f2] | ForEach-Object { "'$_'" }) -join ', ')
    }
    $inNum = $sousNum -join ",`r`n               "
    $inStr = $sousStr -join ",`r`n               "

    [void]$sb.AppendLine("    -- Lot $lot / $($batches.Count) ($($batch.Count) factures)")
    [void]$sb.AppendLine('    UPDATE AP.AP_INVOICES_ALL')
    [void]$sb.AppendLine('    SET    LAST_UPDATE_DATE  = SYSDATE,')
    [void]$sb.AppendLine('           LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,')
    [void]$sb.AppendLine('           LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID')
    [void]$sb.AppendLine("    WHERE  INVOICE_ID IN ($inNum);")
    [void]$sb.AppendLine('    v_total := v_total + SQL%ROWCOUNT;')
    [void]$sb.AppendLine('')

    if ($AvecImages) {
        # ATTRIBUTE1 IS NOT NULL : sans ce filtre, les lignes deja vides
        # etaient reecrites pour rien et gonflaient le compteur.
        [void]$sb.AppendLine('    UPDATE FND_ATTACHED_DOCUMENTS')
        [void]$sb.AppendLine('    SET    ATTRIBUTE1       = NULL,')
        [void]$sb.AppendLine('           LAST_UPDATE_DATE = SYSDATE,')
        [void]$sb.AppendLine('           LAST_UPDATED_BY  = FND_GLOBAL.USER_ID')
        [void]$sb.AppendLine("    WHERE  ENTITY_NAME = 'AP_INVOICES'")
        [void]$sb.AppendLine('      AND  ATTRIBUTE1 IS NOT NULL')
        [void]$sb.AppendLine("      AND  PK1_VALUE IN ($inStr);")
        [void]$sb.AppendLine('    v_total_fad := v_total_fad + SQL%ROWCOUNT;')
        [void]$sb.AppendLine('')
    }
    $lot++
}

[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('');")
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('=================================================');")
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('RESULTAT');")
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('=================================================');")
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('  AP_INVOICES_ALL        : ' || v_total || ' / ' || v_attendu);")
if ($AvecImages) {
    [void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('  FND_ATTACHED_DOCUMENTS : ' || v_total_fad || ' ligne(s)');")
}
[void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('=================================================');")
[void]$sb.AppendLine('')

# Le controle que l'en-tete d'origine annoncait sans jamais l'implementer :
# le COMMIT n'a lieu que si le nombre de lignes touchees est bien celui attendu.
[void]$sb.AppendLine('    IF v_total <> v_attendu THEN')
[void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('##ECART##' || (v_attendu - v_total));")
[void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('ECART : ' || (v_attendu - v_total) || ' identifiant(s) sans ligne correspondante dans AP_INVOICES_ALL.');")
if ($AutoriserManquants) {
    [void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('Ecart accepte (-AutoriserManquants).');")
} else {
    [void]$sb.AppendLine('        ROLLBACK;')
    [void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('ROLLBACK complet : aucune modification conservee.');")
    [void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('Corriger le fichier, ou relancer avec -AutoriserManquants.');")
    [void]$sb.AppendLine('        RETURN;')
}
[void]$sb.AppendLine('    END IF;')
[void]$sb.AppendLine('')

if ($Executer) {
    [void]$sb.AppendLine('    COMMIT;')
    [void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('COMMIT effectue.');")
} else {
    [void]$sb.AppendLine('    ROLLBACK;')
    [void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('SIMULATION : ROLLBACK effectue, aucune modification en base.');")
    [void]$sb.AppendLine("    DBMS_OUTPUT.PUT_LINE('Pour appliquer reellement, relancer avec -Executer.');")
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine('EXCEPTION')
[void]$sb.AppendLine('    WHEN OTHERS THEN')
[void]$sb.AppendLine('        ROLLBACK;')
[void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('ERREUR FATALE : ' || SQLERRM);")
[void]$sb.AppendLine("        DBMS_OUTPUT.PUT_LINE('ROLLBACK effectue - aucune modification enregistree.');")
[void]$sb.AppendLine('        RAISE;')
[void]$sb.AppendLine('END;')
[void]$sb.AppendLine('/')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('EXIT;')

# UTF-8 sans BOM : sqlplus echoue sur la premiere instruction s'il en trouve un.
[System.IO.File]::WriteAllText($FichierSqlTmp, $sb.ToString(),
    (New-Object System.Text.UTF8Encoding $false))
Ok "Script SQL : $FichierSqlTmp"
Write-Host ''

# =====================================================================
#  ETAPE 5 : EXECUTION
# =====================================================================
Write-Host "Etape 5 : Execution sur Oracle EBS ($Mode)..." -ForegroundColor Yellow
$t0 = Get-Date
$sortie   = & $SqlCmd -S "$ConnectStr" "@$FichierSqlTmp" 2>&1
$rc       = $LASTEXITCODE
$duree    = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

# Le log conserve le contexte d'execution, pas seulement la sortie Oracle :
# sans lui, impossible de savoir a posteriori quel fichier a ete traite.
$entete = @(
    '=====================================================================',
    " $Libelle",
    '=====================================================================',
    " Date       : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
    " Mode       : $Mode",
    " Fichier    : $CsvPath",
    " Identifiants retenus : $nbTotal   (doublons ecartes : $($doublons.Count), lignes ignorees : $($rejetees.Count))",
    " Images     : $(if ($AvecImages) { 'oui' } else { 'non' })",
    " Base       : ${ORA_USER}@${OraDsn}",
    " Contexte   : $FND_USER_NAME (user_id=$FND_USER_ID resp=$FND_RESP_ID/$FND_RESP_APPL_ID)",
    " Duree      : ${duree}s (code retour $rc)",
    '=====================================================================',
    ''
)
[System.IO.File]::WriteAllLines($FichierLog, ($entete + ($sortie | ForEach-Object { "$_" })),
    (New-Object System.Text.UTF8Encoding $true))

$sortie | ForEach-Object { Write-Host $_ }
Write-Host ''

if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
else { Avt "[INFO] Script SQL conserve : $FichierSqlTmp" }

# =====================================================================
#  ETAPE 6 : SYNTHESE ET CODE RETOUR
# =====================================================================
$txt      = ($sortie | ForEach-Object { "$_" }) -join "`n"
$aErreur  = ($rc -ne 0) -or ($txt -match 'ORA-\d+' -or $txt -match 'SP2-\d+' -or $txt -match 'ERREUR FATALE')
$aEcart   = $txt -match '##ECART##'

Titre 'SYNTHESE' $(if ($aErreur) { 'Red' } elseif ($aEcart) { 'Yellow' } else { 'Green' })
Write-Host ("  {0,-22} : {1}" -f 'Mode', $Mode) -ForegroundColor $(if ($Executer) { 'Red' } else { 'Green' })
Write-Host ("  {0,-22} : {1}" -f 'Fichier source', (Split-Path $CsvPath -Leaf))
Write-Host ("  {0,-22} : {1}" -f 'Identifiants retenus', $nbTotal)
Write-Host ("  {0,-22} : {1}" -f 'Duree', "${duree}s")
Write-Host ("  {0,-22} : {1}" -f 'Log', $FichierLog) -ForegroundColor Green
Write-Host ('=' * 71) -ForegroundColor $(if ($aErreur) { 'Red' } elseif ($aEcart) { 'Yellow' } else { 'Green' })
Write-Host ''

if ($aErreur) {
    Ko '[ERREUR] Erreur Oracle detectee : aucune modification conservee.'
    exit $EXIT_TECH
}
if ($aEcart) {
    Avt '[ECART] Des identifiants sont sans correspondance dans AP_INVOICES_ALL.'
    exit $EXIT_ECART
}
if (-not $Executer) {
    Avt 'Simulation uniquement : aucune modification en base.'
    Avt 'Pour appliquer reellement, relancer le .bat avec le parametre EXEC.'
}
Write-Host '[OK] Traitement termine.' -ForegroundColor Green
exit $EXIT_OK
