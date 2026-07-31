#Requires -Version 5.1
# =====================================================================
#  Doublons Open Interface AR : rapport complet, puis suppression
# =====================================================================
#  Deux etapes, toujours dans cet ordre :
#    1. RAPPORT  - lecture seule. Chaque enregistrement qui partirait est
#                  liste, dans les quatre tables concernees, en HTML et
#                  en CSV.
#    2. PURGE    - simulation par defaut (DELETE joue puis annule). Ne
#                  s'execute qu'avec -Executer, apres confirmation.
#
#  Le rapport a compte les lignes visees et somme leurs identifiants. Le
#  bloc de purge recalcule les deux valeurs et refuse d'agir si elles ont
#  bouge : on ne supprime jamais un perimetre autre que celui qui vient
#  d'etre edite et relu.
#
#  Usage :
#    .\Suppression_Doublons.ps1                       # rapport + simulation
#    .\Suppression_Doublons.ps1 -RapportSeul          # rapport uniquement
#    .\Suppression_Doublons.ps1 -Executer             # purge reelle
#    .\Suppression_Doublons.ps1 -OrgId 348 -Executer  # limitee a une org
#    .\Suppression_Doublons.ps1 -Motif '%duplicate invoice%'
#
#  MOTIF : le message d'erreur EBS est traduit selon NLS_LANGUAGE. En
#  session francaise le motif par defaut convient ; en session anglaise,
#  passer '%duplicate invoice%'.
#
#  ENCODAGE : ce fichier est en ASCII pur, il se lit correctement quel
#  que soit l'encodage suppose. Si un accent y est introduit un jour,
#  l'enregistrer alors en UTF-8 AVEC BOM.
# =====================================================================

param(
    [string] $Motif     = '%facture en double%',
    [int]    $OrgId     = 0,          # 0 = toutes les organisations
    [switch] $Executer,
    [switch] $RapportSeul,
    [switch] $SansConfirmation,
    [switch] $SansOuverture,          # ne pas ouvrir le HTML a la fin
    [string] $LogDir    = '',
    [switch] $GarderTempSQL
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Mode      = if ($Executer -and -not $RapportSeul) { 'EXECUTION' } else { 'SIMULATION' }

# 0 = conforme, 1 = erreur technique, 2 = ecart de perimetre, 3 = annule
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ECART = 2; $EXIT_ANNULE = 3

function Titre { param([string]$T, [string]$C = 'Cyan')
    Write-Host ''; Write-Host ('=' * 71) -ForegroundColor $C
    Write-Host "  $T" -ForegroundColor $C; Write-Host ('=' * 71) -ForegroundColor $C }
function Ok  { param([string]$T) Write-Host "   $T" -ForegroundColor Green }
function Ko  { param([string]$T) Write-Host "   $T" -ForegroundColor Red }
function Avt { param([string]$T) Write-Host "   $T" -ForegroundColor Yellow }

# Decoupe une ligne balisee "##TAG##a|b|c" en tableau de champs, en
# garantissant le nombre de colonnes attendu : une colonne finale vide
# est perdue par le split, et la lecture par index echouerait sans ca.
function Split-Balise {
    param([string]$Ligne, [string]$Tag, [int]$NbChamps)
    $corps = $Ligne.Substring($Tag.Length)
    $c = $corps -split '\|'
    if ($c.Count -lt $NbChamps) {
        $c = $c + (@('') * ($NbChamps - $c.Count))
    }
    return $c
}

# Les compteurs servent a des comparaisons, jamais a de l'affichage seul :
# un champ vide doit valoir 0 et non faire echouer la conversion.
function ConvertTo-Entier {
    param([string]$V)
    if ([string]::IsNullOrWhiteSpace($V)) { return 0 }
    $n = 0
    if ([int]::TryParse($V.Trim(), [ref]$n)) { return $n }
    return 0
}

function ConvertTo-Nombre {
    param([string]$V)
    if ([string]::IsNullOrWhiteSpace($V)) { return [double]0 }
    $d = [double]0
    if ([double]::TryParse($V.Trim(), [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }
    return [double]0
}

Titre "DOUBLONS OPEN INTERFACE AR  -  MODE $Mode" $(if ($Mode -eq 'EXECUTION') { 'Red' } else { 'Cyan' })
Write-Host "  Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Mode           : $Mode" -ForegroundColor $(if ($Mode -eq 'EXECUTION') { 'Red' } else { 'Green' })
Write-Host "  Motif          : $Motif"
Write-Host "  Organisation   : $(if ($OrgId -eq 0) { 'TOUTES' } else { $OrgId })"
Write-Host ''

# =====================================================================
#  ETAPE 1 : PREREQUIS
# =====================================================================
Write-Host 'Etape 1 : Verification des prerequis...' -ForegroundColor Yellow

if ($Motif -notmatch '%') {
    Avt "[ATTENTION] Le motif '$Motif' ne contient aucun caractere %."
    Avt '            Le LIKE portera sur une egalite stricte : c''est rarement voulu.'
}

$SqlRapport = Join-Path $ScriptDir 'Rapport_Doublons_OpenInterface_AR.sql'
$SqlPurge   = Join-Path $ScriptDir 'Suppression_Doublons_Execution.sql'
$PsRapport  = Join-Path $ScriptDir 'Rapport_Html_Doublons.ps1'
foreach ($f in @($SqlRapport, $SqlPurge, $PsRapport)) {
    if (-not (Test-Path $f)) { Ko "[ERREUR] Fichier introuvable : $f"; exit $EXIT_TECH }
}
. $PsRapport

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
$FichierRapport = Join-Path $LogDir "rapport_doublons_${Timestamp}.txt"
$FichierHtml    = Join-Path $LogDir "Rapport_Doublons_${Timestamp}.html"
$FichierCsv     = Join-Path $LogDir "Rapport_Doublons_${Timestamp}.csv"
$FichierPurge   = Join-Path $LogDir "purge_doublons_${Timestamp}.log"
Ok "Dossier logs  : $LogDir"
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
Write-Host ''

$env:NLS_LANG = 'FRENCH_FRANCE.AL32UTF8'

# =====================================================================
#  ETAPE 3 : EXTRACTION DU RAPPORT
# =====================================================================
Write-Host 'Etape 3 : Extraction des enregistrements concernes...' -ForegroundColor Yellow

$enteteRapport = @(
    "-- Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') par Suppression_Doublons.ps1",
    '',
    'WHENEVER SQLERROR EXIT FAILURE',
    '',
    "DEFINE P_MOTIF   = `"$Motif`"",
    "DEFINE P_ORG_ID  = $OrgId",
    '',
    "SPOOL $($FichierRapport.Replace('\','/'))",
    ''
) -join "`r`n"
$piedRapport = @('', 'SPOOL OFF', 'EXIT;') -join "`r`n"

$corpsRapport   = [System.IO.File]::ReadAllText($SqlRapport, [System.Text.Encoding]::UTF8)
$TmpSqlRapport  = Join-Path $LogDir "temp_rapport_${Timestamp}.sql"
# UTF-8 sans BOM : sqlplus echoue sur la premiere instruction s'il en trouve un.
[System.IO.File]::WriteAllText($TmpSqlRapport, ($enteteRapport + $corpsRapport + $piedRapport),
    (New-Object System.Text.UTF8Encoding $false))

$t0 = Get-Date
& $SqlCmd -S $ConnectStr "@$TmpSqlRapport" | Out-Null
$rcRapport = $LASTEXITCODE
$dureeRapport = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
if (-not $GarderTempSQL) { Remove-Item $TmpSqlRapport -ErrorAction SilentlyContinue }

if (-not (Test-Path $FichierRapport)) {
    Ko "[ERREUR] Aucun rapport produit : $FichierRapport"
    Ko '         Verifier la connexion Oracle et les droits de lecture sur AR.'
    exit $EXIT_TECH
}
Ok "Extraction terminee en ${dureeRapport}s (code retour $rcRapport)"

# =====================================================================
#  ETAPE 4 : LECTURE DU RAPPORT
# =====================================================================
Write-Host 'Etape 4 : Lecture des enregistrements...' -ForegroundColor Yellow

$brut = Get-Content $FichierRapport -Encoding UTF8

$erreursOracle = @($brut | Where-Object { $_ -match '^ORA-\d+' -or $_ -match '^SP2-\d+' })
if ($erreursOracle.Count -gt 0) {
    Ko 'Erreurs remontees par Oracle pendant l''extraction :'
    $erreursOracle | Select-Object -Unique -First 10 | ForEach-Object { Ko "   $_" }
    exit $EXIT_TECH
}

$lignes = New-Object System.Collections.Generic.List[object]
$erreurs = New-Object System.Collections.Generic.List[object]
$distributions = New-Object System.Collections.Generic.List[object]
$creditsVente = New-Object System.Collections.Generic.List[object]
$compteurs = @{}
$nbAttendu = -1
$sommeIds  = -1
$finVue    = $false

foreach ($l in $brut) {
    if ($l -like '##FIN##*') { $finVue = $true; continue }

    if ($l -like '##CTRL##*') {
        $c = Split-Balise $l '##CTRL##' 2
        $nbAttendu = [int]$c[0]
        $sommeIds  = [decimal]$c[1]
        continue
    }
    if ($l -like '##CNT##*') {
        $c = Split-Balise $l '##CNT##' 2
        $compteurs[$c[0].Trim()] = [int]$c[1]
        continue
    }
    if ($l -like '##LINE##*') {
        $c = Split-Balise $l '##LINE##' 27
        $lignes.Add([PSCustomObject]@{
            InterfaceLineId   = $c[0].Trim()
            Source            = $c[1]
            Contexte          = $c[2]
            Attribut1         = $c[3]
            Attribut2         = $c[4]
            Attribut3         = $c[5]
            TrxNumber         = $c[6]
            TrxDate           = $c[7]
            GlDate            = $c[8]
            Montant           = ConvertTo-Nombre $c[9]
            Devise            = $c[10]
            ClientRef         = $c[11]
            TypeTrx           = $c[12]
            TypeLigne         = $c[13]
            Quantite          = $c[14]
            Description       = $c[15]
            OrgId             = $c[16].Trim()
            CreePar           = $c[17]
            CreationDate      = $c[18]
            RequestId         = $c[19]
            NbErreurs         = ConvertTo-Entier $c[20]
            NbDistributions   = ConvertTo-Entier $c[21]
            NbSalescredits    = ConvertTo-Entier $c[22]
            Message           = $c[23]
            NbTrxExistantes   = ConvertTo-Entier $c[24]
            DateTrxExistante  = $c[25]
            NbDansInterface   = ConvertTo-Entier $c[26]
        })
        continue
    }
    if ($l -like '##ERR##*') {
        $c = Split-Balise $l '##ERR##' 4
        $erreurs.Add([PSCustomObject]@{
            InterfaceLineId = $c[0].Trim(); Message = $c[1]
            ValeurInvalide  = $c[2];        OrgId   = $c[3].Trim()
        })
        continue
    }
    if ($l -like '##DIST##*') {
        $c = Split-Balise $l '##DIST##' 6
        $distributions.Add([PSCustomObject]@{
            DistributionId = $c[0].Trim(); InterfaceLineId = $c[1].Trim()
            Classe         = $c[2];        Montant         = $c[3].Trim()
            Pourcentage    = $c[4].Trim(); OrgId           = $c[5].Trim()
        })
        continue
    }
    if ($l -like '##SC##*') {
        $c = Split-Balise $l '##SC##' 6
        $creditsVente.Add([PSCustomObject]@{
            SalescreditId = $c[0].Trim(); InterfaceLineId = $c[1].Trim()
            Commercial    = $c[2];        Montant         = $c[3].Trim()
            Pourcentage   = $c[4].Trim(); OrgId           = $c[5].Trim()
        })
        continue
    }
}

# Le marqueur de fin distingue un rapport vide d'un rapport tronque. Sans
# lui, une extraction coupee en cours de route passerait pour un perimetre
# vide, et la purge suivrait sans rien avoir montre.
if (-not $finVue) {
    Ko '[ERREUR] Rapport incomplet : le marqueur de fin est absent.'
    Ko "         L'extraction a ete interrompue. Fichier : $FichierRapport"
    exit $EXIT_TECH
}
if ($nbAttendu -lt 0) {
    Ko '[ERREUR] Controle de perimetre absent du rapport : extraction non exploitable.'
    exit $EXIT_TECH
}

$montantTotal = ($lignes | Measure-Object -Property Montant -Sum).Sum
if ($null -eq $montantTotal) { $montantTotal = 0 }

Ok "Lignes d'interface  : $($lignes.Count)"
Ok "Erreurs             : $($erreurs.Count)"
Ok "Distributions       : $($distributions.Count)"
Ok "Credits de vente    : $($creditsVente.Count)"

# La ligne d'interface est comptee dans le rapport ligne par ligne ; le
# ##CNT## vient d'un COUNT independant. Un ecart signale une lecture
# partielle du spool, donc un rapport auquel on ne peut pas se fier.
if ($compteurs.ContainsKey('RA_INTERFACE_LINES_ALL') -and
    $compteurs['RA_INTERFACE_LINES_ALL'] -ne $lignes.Count) {
    Ko "[ERREUR] Incoherence du rapport : $($lignes.Count) ligne(s) lue(s) pour "
    Ko "         $($compteurs['RA_INTERFACE_LINES_ALL']) annoncee(s) par la base."
    exit $EXIT_TECH
}
if ($lignes.Count -ne $nbAttendu) {
    Ko "[ERREUR] Incoherence du rapport : $($lignes.Count) ligne(s) lue(s) pour "
    Ko "         $nbAttendu attendue(s) par le controle de perimetre."
    exit $EXIT_TECH
}
Write-Host ''

# =====================================================================
#  ETAPE 5 : CSV ET HTML
# =====================================================================
Write-Host 'Etape 5 : Generation du rapport...' -ForegroundColor Yellow

# Un seul CSV, une ligne par enregistrement supprime, toutes tables
# confondues : c'est la piece exhaustive, celle qui se relit et se
# conserve. Le HTML au-dessus sert a comprendre et a decider.
$exportCsv = New-Object System.Collections.Generic.List[object]
foreach ($l in $lignes) {
    $categorie = if ([int]$l.NbTrxExistantes -gt 0) { 'DEJA_INTEGREE' }
                 elseif ([int]$l.NbDansInterface -gt 1) { 'DOUBLON_INTERNE' }
                 else { 'SANS_CONCURRENT' }
    $exportCsv.Add([PSCustomObject]@{
        Table            = 'RA_INTERFACE_LINES_ALL'
        InterfaceLineId  = $l.InterfaceLineId
        IdEnfant         = ''
        OrgId            = $l.OrgId
        Source           = $l.Source
        NumeroFacture    = $l.TrxNumber
        DateFacture      = $l.TrxDate
        DateGL           = $l.GlDate
        Montant          = $l.Montant
        Devise           = $l.Devise
        RefClient        = $l.ClientRef
        TypeTransaction  = $l.TypeTrx
        Description      = $l.Description
        Contexte         = $l.Contexte
        Attribut1        = $l.Attribut1
        Attribut2        = $l.Attribut2
        Attribut3        = $l.Attribut3
        CreeLe           = $l.CreationDate
        CreePar          = $l.CreePar
        RequestId        = $l.RequestId
        Categorie        = $categorie
        DejaEnBase       = $l.NbTrxExistantes
        DateDejaEnBase   = $l.DateTrxExistante
        ExemplairesInterface = $l.NbDansInterface
        Detail           = $l.Message
    })
}
foreach ($e in $erreurs) {
    $exportCsv.Add([PSCustomObject]@{
        Table = 'RA_INTERFACE_ERRORS_ALL'; InterfaceLineId = $e.InterfaceLineId
        IdEnfant = ''; OrgId = $e.OrgId; Detail = $e.Message
        Description = $e.ValeurInvalide
    })
}
foreach ($d in $distributions) {
    $exportCsv.Add([PSCustomObject]@{
        Table = 'RA_INTERFACE_DISTRIBUTIONS_ALL'; InterfaceLineId = $d.InterfaceLineId
        IdEnfant = $d.DistributionId; OrgId = $d.OrgId; Montant = $d.Montant
        Detail = "classe=$($d.Classe);pourcentage=$($d.Pourcentage)"
    })
}
foreach ($s in $creditsVente) {
    $exportCsv.Add([PSCustomObject]@{
        Table = 'RA_INTERFACE_SALESCREDITS_ALL'; InterfaceLineId = $s.InterfaceLineId
        IdEnfant = $s.SalescreditId; OrgId = $s.OrgId; Montant = $s.Montant
        Detail = "commercial=$($s.Commercial);pourcentage=$($s.Pourcentage)"
    })
}

# Excel francais attend le point-virgule ; l'UTF-8 avec BOM lui evite de
# massacrer les accents a l'ouverture.
$exportCsv | Export-Csv -Path $FichierCsv -NoTypeInformation -Delimiter ';' -Encoding UTF8
Ok "CSV  : $FichierCsv ($($exportCsv.Count) enregistrement(s))"

if ($Mode -ne 'EXECUTION') {
    New-RapportDoublonsHtml -Lignes ($lignes.ToArray()) -Erreurs ($erreurs.ToArray()) `
        -Distributions ($distributions.ToArray()) -CreditsVente ($creditsVente.ToArray()) `
        -CheminHtml $FichierHtml -Compteurs $compteurs `
        -Mode $(if ($RapportSeul) { 'RAPPORT' } else { $Mode }) -Motif $Motif `
        -Org $(if ($OrgId -eq 0) { 'TOUTES' } else { "$OrgId" }) `
        -Base "${ORA_USER}@${OraDsn}" -Duree $dureeRapport -CheminCsv $FichierCsv
    Ok "HTML : $FichierHtml"
}
Write-Host ''

$dejaIntegrees = @($lignes | Where-Object { [int]$_.NbTrxExistantes -gt 0 })
$internes      = @($lignes | Where-Object { [int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -gt 1 })
$isoles        = @($lignes | Where-Object { [int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -le 1 })

Titre 'CE QUI SERA SUPPRIME' $(if ($lignes.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_LINES_ALL', $lignes.Count)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_ERRORS_ALL', $erreurs.Count)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_DISTRIBUTIONS_ALL', $distributions.Count)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_SALESCREDITS_ALL', $creditsVente.Count)
Write-Host ''
Write-Host ("  {0,-34} : {1,8}" -f 'Deja integrees en base', $dejaIntegrees.Count) -ForegroundColor Green
Write-Host ("  {0,-34} : {1,8}" -f 'Doublons internes a l''interface', $internes.Count) -ForegroundColor $(if ($internes.Count -gt 0) { 'Red' } else { 'Gray' })
Write-Host ("  {0,-34} : {1,8}" -f 'Sans concurrent identifie', $isoles.Count) -ForegroundColor $(if ($isoles.Count -gt 0) { 'Yellow' } else { 'Gray' })
Write-Host ('=' * 71) -ForegroundColor Yellow

if ($internes.Count -gt 0) {
    Write-Host ''
    Avt "[ATTENTION] $($internes.Count) ligne(s) sont en doublon INTERNE a l'interface :"
    Avt '            leur numero n''existe dans aucune table definitive, mais'
    Avt '            apparait plusieurs fois en interface. Tout supprimer ferait'
    Avt '            perdre la facture. Les arbitrer avant de purger.'
    $internes | Select-Object -First 10 | ForEach-Object {
        Avt "            $($_.TrxNumber) (line_id $($_.InterfaceLineId), org $($_.OrgId), $('{0:N2}' -f $_.Montant))"
    }
    if ($internes.Count -gt 10) { Avt "            ... et $($internes.Count - 10) autre(s)" }
}

if ($Mode -ne 'EXECUTION') {
    if (-not $SansOuverture -and (Test-Path $FichierHtml)) {
        Start-Process $FichierHtml
    }
}

if ($lignes.Count -eq 0) {
    Write-Host ''
    Ok 'Aucune ligne a supprimer : rien a faire.'
    Avt 'Si des doublons sont pourtant attendus, verifier le motif : le message'
    Avt 'd''erreur EBS est traduit selon NLS_LANGUAGE. En session anglaise :'
    Write-Host "     .\Suppression_Doublons.ps1 -Motif '%duplicate invoice%'" -ForegroundColor White
    Write-Host ''
    exit $EXIT_OK
}

if ($RapportSeul) {
    Write-Host ''
    Ok 'Rapport seul : aucune suppression tentee.'
    Write-Host ''
    exit $EXIT_OK
}

# =====================================================================
#  ETAPE 6 : CONFIRMATION AVANT SUPPRESSION REELLE
# =====================================================================
if ($Mode -eq 'EXECUTION' -and -not $SansConfirmation) {
    $total = $lignes.Count + $erreurs.Count + $distributions.Count + $creditsVente.Count
    Titre 'CONFIRMATION REQUISE' 'Red'
    Write-Host "  Vous allez supprimer definitivement $total enregistrement(s) :" -ForegroundColor Red
    Write-Host "    $($lignes.Count) ligne(s) d'interface, $($erreurs.Count) erreur(s)," -ForegroundColor Red
    Write-Host "    $($distributions.Count) distribution(s), $($creditsVente.Count) credit(s) de vente." -ForegroundColor Red
    Write-Host "  Base             : ${ORA_USER}@${OraDsn}" -ForegroundColor Red
    if ($internes.Count -gt 0) {
        Write-Host "  Dont $($internes.Count) doublon(s) INTERNE(S) : la facture n'existe nulle part ailleurs." -ForegroundColor Red
    }
    Write-Host ''
    Write-Host "  Le detail complet est dans le fichier CSV : $FichierCsv" -ForegroundColor Yellow
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
        Avt 'Operation annulee. Aucune suppression effectuee.'
        Avt "Le rapport reste disponible : $FichierHtml"
        exit $EXIT_ANNULE
    }
    Write-Host ''
}

# =====================================================================
#  ETAPE 7 : SUPPRESSION
# =====================================================================
Write-Host "Etape 7 : Suppression ($Mode)..." -ForegroundColor Yellow

$entetePurge = @(
    "-- Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') par Suppression_Doublons.ps1",
    "-- Perimetre valide par le rapport : $FichierHtml",
    '',
    'WHENEVER SQLERROR EXIT FAILURE',
    '',
    "DEFINE P_MODE       = `"$Mode`"",
    "DEFINE P_MOTIF      = `"$Motif`"",
    "DEFINE P_ORG_ID     = $OrgId",
    "DEFINE P_MAX_LIGNES = 9999999 -- Plafond desactive",
    "DEFINE P_NB_ATTENDU = $nbAttendu",
    "DEFINE P_SOMME_IDS  = $sommeIds",
    '',
    "SPOOL $($FichierPurge.Replace('\','/'))",
    ''
) -join "`r`n"
$piedPurge = @('', 'SPOOL OFF', 'EXIT;') -join "`r`n"

$corpsPurge  = [System.IO.File]::ReadAllText($SqlPurge, [System.Text.Encoding]::UTF8)
$TmpSqlPurge = Join-Path $LogDir "temp_purge_${Timestamp}.sql"
[System.IO.File]::WriteAllText($TmpSqlPurge, ($entetePurge + $corpsPurge + $piedPurge),
    (New-Object System.Text.UTF8Encoding $false))

$t1 = Get-Date
& $SqlCmd -S $ConnectStr "@$TmpSqlPurge" | Out-Null
$rcPurge = $LASTEXITCODE
$dureePurge = [math]::Round(((Get-Date) - $t1).TotalSeconds, 1)

if (-not $GarderTempSQL) { Remove-Item $TmpSqlPurge -ErrorAction SilentlyContinue }
else { Avt "[INFO] Script SQL conserve : $TmpSqlPurge" }
Ok "Termine en ${dureePurge}s (code retour $rcPurge)"
Write-Host ''

# =====================================================================
#  ETAPE 8 : ANALYSE
# =====================================================================
Write-Host 'Etape 8 : Analyse du resultat...' -ForegroundColor Yellow

if (-not (Test-Path $FichierPurge)) {
    Ko "[ERREUR] Aucun log de suppression produit : $FichierPurge"
    exit $EXIT_TECH
}

$logPurge   = Get-Content $FichierPurge -Encoding UTF8
$errPurge   = @($logPurge | Where-Object { $_ -match '^ORA-\d+' -or $_ -match '^SP2-\d+' -or $_ -like '##ERR##*' })
$resume     = @{}
$orphelins  = New-Object System.Collections.Generic.List[object]

foreach ($l in $logPurge) {
    if ($l -like '*##SUM##*') {
        $p = $l.Substring($l.IndexOf('##SUM##') + 7)
        foreach ($kv in $p.Split(';')) {
            $x = $kv.Split('='); if ($x.Count -eq 2) { $resume[$x[0].Trim()] = [int]$x[1] }
        }
        continue
    }
    if ($l -like '##ORPH##*') {
        $c = Split-Balise $l '##ORPH##' 2
        $orphelins.Add([PSCustomObject]@{ Controle = $c[0]; Nb = [int]$c[1] })
    }
}

# Le log garde les balises pour l'archive, mais la copie lisible s'en passe.
$logPropre = $logPurge | Where-Object { $_ -notlike '*##SUM##*' -and $_ -notlike '##ORPH##*' -and $_ -notlike '##ERR##*' }
[System.IO.File]::WriteAllLines($FichierPurge, $logPropre, (New-Object System.Text.UTF8Encoding $true))

$nbLig  = if ($resume.ContainsKey('lig'))  { $resume['lig'] }  else { 0 }
$nbErr  = if ($resume.ContainsKey('err'))  { $resume['err'] }  else { 0 }
$nbDist = if ($resume.ContainsKey('dist')) { $resume['dist'] } else { 0 }
$nbSc   = if ($resume.ContainsKey('sc'))   { $resume['sc'] }   else { 0 }
$orphRestants = @($orphelins | Where-Object { $_.Nb -gt 0 })

# =====================================================================
#  ETAPE 9 : SYNTHESE
# =====================================================================
$couleur = if ($errPurge.Count -gt 0 -or $rcPurge -ne 0) { 'Red' }
           elseif ($orphRestants.Count -gt 0) { 'Yellow' }
           elseif ($Mode -eq 'EXECUTION') { 'Green' } else { 'Cyan' }

Titre 'SYNTHESE' $couleur
Write-Host ("  {0,-34} : {1}" -f 'Mode', $Mode) -ForegroundColor $(if ($Mode -eq 'EXECUTION') { 'Red' } else { 'Green' })
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_LINES_ALL', $nbLig)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_ERRORS_ALL', $nbErr)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_DISTRIBUTIONS_ALL', $nbDist)
Write-Host ("  {0,-34} : {1,8}" -f 'RA_INTERFACE_SALESCREDITS_ALL', $nbSc)
if ($Mode -ne 'EXECUTION') {
    Write-Host ("  {0,-34} : {1}" -f 'Rapport HTML', $FichierHtml) -ForegroundColor Green
}
Write-Host ("  {0,-34} : {1}" -f 'Rapport CSV', $FichierCsv) -ForegroundColor Green
Write-Host ("  {0,-34} : {1}" -f 'Log suppression', $FichierPurge) -ForegroundColor Green

if ($orphRestants.Count -gt 0) {
    Write-Host ''
    Avt 'Enregistrements orphelins detectes apres suppression :'
    $orphRestants | ForEach-Object { Avt "   $($_.Controle) : $($_.Nb)" }
}

if ($errPurge.Count -gt 0) {
    Write-Host ''
    Ko 'Erreurs remontees par Oracle :'
    $errPurge | Select-Object -Unique -First 10 | ForEach-Object { Ko "   $($_ -replace '^##ERR##','')" }
}

Write-Host ('=' * 71) -ForegroundColor $couleur
Write-Host ''

if ($Mode -ne 'EXECUTION' -and $errPurge.Count -eq 0 -and $rcPurge -eq 0) {
    Avt 'Simulation uniquement : aucune modification en base.'
    Avt 'Pour supprimer reellement :'
    Write-Host "     .\Suppression_Doublons.ps1 -Executer" -ForegroundColor White
    Write-Host ''
}

if ($errPurge.Count -gt 0 -or $rcPurge -ne 0) { exit $EXIT_TECH }
if ($orphRestants.Count -gt 0) { exit $EXIT_ECART }
exit $EXIT_OK
