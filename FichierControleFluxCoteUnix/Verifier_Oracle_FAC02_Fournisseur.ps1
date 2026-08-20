# =====================================================================
#  Controle FAC02 - Verification des factures FOURNISSEURS dans Oracle EBS
# =====================================================================
#  1) Lit le fichier SRC fournisseurs (1re ligne = en-tete, montants
#     decimaux a virgule deja signes) et calcule par code folio le nb de
#     factures (lignes comptes 401*) et le montant total.
#  2) Interroge Oracle en UNE SEULE session sqlplus, par folio :
#       - tables definitives AP : APPS.AP_INVOICES_ALL (attribute10 =
#         fichier, attribute9 = folio), comme le controle Folio Rose
#         type FOURNISSEURS
#       - open interface : APPS.AP_INVOICES_INTERFACE /
#         AP_INVOICE_LINES_INTERFACE, hors lignes rejetees
#         (AP_INTERFACE_REJECTIONS)
#  3) Restitue par folio : fichier vs Oracle definitif vs interface,
#     avec un statut :
#       INTEGREE     : tout est dans les tables definitives
#       EN INTERFACE : rien en definitif, tout en open interface
#       PARTIELLE    : reparti entre definitif et interface
#       ABSENTE      : nulle part dans Oracle
#       ECART        : montants incoherents
#
#  Base sur Verifier_Oracle_FAC02_Client.ps1 (meme enveloppe sqlplus,
#  meme convention ##RES##cle|...) et sur les requetes FOURNISSEURS de
#  ControleFolioRose\Verifier_Factures.ps1.
#
#  Usage :
#    .\Verifier_Oracle_FAC02_Fournisseur.ps1 -CheminFichierSrc FAC02_SRC_FACTURESFOURNISSEURS_...csv
#
#  Codes retour : 0 = tout integre, 1 = erreur technique, 2 = anomalies
# =====================================================================
param(
    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le fichier SRC FAC02 fournisseurs")]
    [string] $CheminFichierSrc,
    # Affiche les requetes envoyees et la sortie brute d'Oracle
    [switch] $Diagnostic,
    # Conserve le script SQL genere, pour analyse
    [switch] $GarderTempSQL
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ANOMALIE = 2

function Format-Montant { param($V) return ('{0:N2}' -f [double]$V) }

Write-Host ''
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host '  CONTROLE FAC02 - Verification des factures FOURNISSEURS dans Oracle' -ForegroundColor Cyan
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host "  Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host ''

# =====================================================================
#  1. CONFIGURATION ORACLE
# =====================================================================
$ConfigFile = Join-Path $ScriptDir 'config.ps1'
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERREUR] Fichier de configuration introuvable : $ConfigFile" -ForegroundColor Red
    exit $EXIT_TECH
}
. $ConfigFile

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"

$SQL_CMD = $null
foreach ($c in @('sqlplus', 'sqlcl', 'sql')) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $SQL_CMD = $c; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host '[ERREUR] Aucun client Oracle trouve (sqlplus, sqlcl ou sql) dans le PATH.' -ForegroundColor Red
    exit $EXIT_TECH
}
Write-Host "   Connexion : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host "   Client    : $SQL_CMD" -ForegroundColor Green

# =====================================================================
#  2. LECTURE DU FICHIER SRC : SYNTHESE PAR FOLIO
# =====================================================================
$CheminAbsolu = Resolve-Path $CheminFichierSrc -ErrorAction SilentlyContinue
if ($null -eq $CheminAbsolu) {
    Write-Host "[ERREUR] Fichier SRC introuvable : $CheminFichierSrc" -ForegroundColor Red
    exit $EXIT_TECH
}
Write-Host "   Fichier   : $($CheminAbsolu.Path)" -ForegroundColor Green

# Nom de fichier transmis dans Oracle : base sans le suffixe _ST_..._001
$NomFichier  = [System.IO.Path]::GetFileNameWithoutExtension($CheminAbsolu.Path)
$FichierBase = $NomFichier
$posST = $NomFichier.IndexOf('_ST_')
if ($posST -gt 0) { $FichierBase = $NomFichier.Substring(0, $posST) }
Write-Host "   Cle Oracle (attribute10) : $FichierBase%" -ForegroundColor Green
Write-Host ''

# Agregation par folio sur les lignes comptes fournisseurs 401*
# Champs SRC (index 0) : 2=compte achat, 5=code folio, 9=montant
# (decimal a virgule, deja signe), 11=date piece, 12=numero de piece.
# La 1re ligne est l'en-tete.
$SrcCnt = @{}; $SrcAmt = @{}
$numLigne = 0
$culture = [System.Globalization.CultureInfo]::InvariantCulture
foreach ($ligne in [System.IO.File]::ReadLines($CheminAbsolu.Path, [System.Text.Encoding]::GetEncoding(1252))) {
    $numLigne++
    if ($numLigne -eq 1) { continue }   # en-tete
    $ch = $ligne.Split(';')
    if ($ch.Count -lt 13 -or -not $ch[2].StartsWith('401')) { continue }
    $folio = $ch[5].Trim()
    if ($folio -eq '') { continue }
    $txt = $ch[9].Trim().Replace(' ', '').Replace(',', '.')
    $m = [decimal]0
    if ($txt -ne '' -and -not [decimal]::TryParse($txt, [System.Globalization.NumberStyles]::Number, $culture, [ref]$m)) {
        Write-Host "   [ATTENTION] montant illisible ligne $numLigne : '$($ch[9])' (compte comme 0)" -ForegroundColor Yellow
        $m = [decimal]0
    }
    if (-not $SrcCnt.ContainsKey($folio)) { $SrcCnt[$folio] = 0; $SrcAmt[$folio] = [decimal]0 }
    $SrcCnt[$folio]++
    $SrcAmt[$folio] += $m
}
if ($SrcCnt.Count -eq 0) {
    Write-Host '[ERREUR] Aucune ligne compte 401* dans le fichier SRC.' -ForegroundColor Red
    exit $EXIT_TECH
}

$Folios = @($SrcCnt.Keys | Sort-Object)
Write-Host 'Etape 1 : Synthese du fichier SRC' -ForegroundColor Yellow
foreach ($p in $Folios) {
    Write-Host ("   Folio {0,-4} : {1,5} factures, montant {2,15}" -f `
        $p, $SrcCnt[$p], (Format-Montant $SrcAmt[$p]))
}
Write-Host ''

# =====================================================================
#  3. UNE SEULE SESSION ORACLE POUR TOUS LES FOLIOS
# =====================================================================
#  Par folio : nb + montant en definitif (AP), nb + montant en open
#  interface hors rejets. Meme enveloppe ##RES## que le flux clients.
# =====================================================================
Write-Host 'Etape 2 : Interrogation Oracle...' -ForegroundColor Yellow

$LogDir = Join-Path $ScriptDir 'Logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$Timestamp         = Get-Date -Format 'ddMMyyyy_HHmmss'
$FichierRapportCsv = Join-Path $LogDir "Rapport_Oracle_FAC02_FOURNISSEURS_${Timestamp}.csv"
$FichierSqlTmp     = Join-Path $LogDir "requetes_fac02_frs_${Timestamp}.sql"

$b = $FichierBase.Replace("'", "''")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('SET PAGESIZE 0')
[void]$sb.AppendLine('SET FEEDBACK OFF')
[void]$sb.AppendLine('SET HEADING OFF')
[void]$sb.AppendLine('SET LINESIZE 1000')
[void]$sb.AppendLine('SET TRIMSPOOL ON')
[void]$sb.AppendLine('SET DEFINE OFF')
[void]$sb.AppendLine('WHENEVER SQLERROR CONTINUE')
[void]$sb.AppendLine('')

$cle = 0
$clesParFolio = @{}
foreach ($p in $Folios) {
    $f = $p.Replace("'", "''")
    $clesParFolio[$p] = $cle
    [void]$sb.AppendLine(@"
SELECT '##RES##$cle|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.nb_int, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx,
          SUM(aia.invoice_amount)        AS sum_amt
   FROM   APPS.AP_INVOICES_ALL aia
   WHERE  aia.attribute10 LIKE TRIM('$b') || '%'
     AND  aia.attribute9 = TRIM('$f')) q_def
CROSS JOIN
 (SELECT COUNT(DISTINCT aii.invoice_id) AS nb_int,
         SUM(aili.amount)               AS sum_int
  FROM   APPS.AP_INVOICES_INTERFACE aii
  JOIN   APPS.AP_INVOICE_LINES_INTERFACE aili ON aii.invoice_id = aili.invoice_id
  WHERE  aii.attribute10 LIKE TRIM('$b') || '%'
    AND  aii.attribute9 = TRIM('$f')
    AND  NOT EXISTS (
             SELECT 1
             FROM APPS.AP_INTERFACE_REJECTIONS air
             WHERE air.parent_id = aii.invoice_id
               AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
         )
 ) q_int;
"@)
    [void]$sb.AppendLine('')
    $cle++
}
[void]$sb.AppendLine('EXIT;')

# UTF-8 sans BOM : sqlplus echoue sur la premiere instruction s'il en trouve un.
[System.IO.File]::WriteAllText($FichierSqlTmp, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

if ($Diagnostic) {
    Write-Host '---- SCRIPT SQL ----' -ForegroundColor DarkGray
    Get-Content $FichierSqlTmp | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

$t0     = Get-Date
$sortie = & $SQL_CMD -S $CONNECT_STR "@$FichierSqlTmp" 2>&1
$rc     = $LASTEXITCODE
$duree  = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

if ($Diagnostic) {
    Write-Host '---- SORTIE ORACLE ----' -ForegroundColor DarkGray
    $sortie | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

# Une erreur Oracle ne doit pas se traduire par des montants a zero
# presentes comme un resultat de reconciliation.
$erreursOra = @($sortie | Where-Object { $_ -match '^(ORA|SP2|TNS)-\d+' } | Select-Object -Unique)
if ($erreursOra.Count -gt 0) {
    Write-Host ''
    Write-Host '[ERREUR] Oracle a retourne des erreurs : le controle est interrompu.' -ForegroundColor Red
    $erreursOra | Select-Object -First 10 | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
    if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
    exit $EXIT_TECH
}

$resultats = @{}
foreach ($l in $sortie) {
    if ("$l" -match '##RES##(\d+)\|([^|]*)\|([^|]*)\|([^|]*)\|(.*)$') {
        $resultats[[int]$Matches[1]] = @{
            NbDef = $Matches[2].Trim(); MtDef = $Matches[3].Trim()
            NbInt = $Matches[4].Trim(); MtInt = $Matches[5].Trim()
        }
    }
}

if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
else { Write-Host "   [INFO] Script SQL conserve : $FichierSqlTmp" -ForegroundColor Yellow }

Write-Host "   $($resultats.Count) / $($Folios.Count) interrogation(s) aboutie(s) en ${duree}s (code retour $rc)" -ForegroundColor Green
Write-Host ''

# =====================================================================
#  4. RESTITUTION : FICHIER vs DEFINITIF vs OPEN INTERFACE
# =====================================================================
$TOLERANCE = 0.01
$Tableau = [System.Collections.Generic.List[PSCustomObject]]::new()
$nbInteg = 0; $nbInterface = 0; $nbAutre = 0

Write-Host ("{0,-6} | {1,8} | {2,15} | {3,8} | {4,15} | {5,8} | {6,15} | {7}" -f `
    'FOLIO', 'NB SRC', 'MT SRC', 'NB ORA', 'MT ORACLE', 'NB INT', 'MT INTERFACE', 'STATUT')
Write-Host ('-' * 110)

foreach ($p in $Folios) {
    $mtSrc = [double]$SrcAmt[$p]
    $nbSrc = $SrcCnt[$p]

    $ora = $resultats[$clesParFolio[$p]]
    if ($null -eq $ora) {
        $statut = 'INDETERMINE'; $couleur = 'Yellow'; $nbAutre++
        $nbDef = $null; $mtDef = $null; $nbInt = $null; $mtInt = $null
    } else {
        $nbDef = [int]$ora.NbDef
        $mtDef = [double]($ora.MtDef -replace ',', '.')
        $nbInt = [int]$ora.NbInt
        $mtInt = [double]($ora.MtInt -replace ',', '.')

        if ($nbDef -eq $nbSrc -and [math]::Abs($mtDef - $mtSrc) -le $TOLERANCE) {
            $statut = 'INTEGREE'; $couleur = 'Green'; $nbInteg++
        } elseif ($nbDef -eq 0 -and [math]::Abs($mtInt - $mtSrc) -le $TOLERANCE) {
            $statut = 'EN INTERFACE'; $couleur = 'Yellow'; $nbInterface++
        } elseif ($nbDef -eq 0 -and $nbInt -eq 0) {
            $statut = 'ABSENTE'; $couleur = 'Red'; $nbAutre++
        } elseif ([math]::Abs(($mtDef + $mtInt) - $mtSrc) -le $TOLERANCE) {
            $statut = 'PARTIELLE'; $couleur = 'Yellow'; $nbAutre++
        } else {
            $statut = 'ECART'; $couleur = 'Red'; $nbAutre++
        }
    }

    Write-Host ("{0,-6} | {1,8:N0} | {2,15:N2} | {3,8} | {4,15} | {5,8} | {6,15} | " -f `
        $p, $nbSrc, $mtSrc, $nbDef, $(if ($null -ne $mtDef) { Format-Montant $mtDef }), `
        $nbInt, $(if ($null -ne $mtInt) { Format-Montant $mtInt })) -NoNewline
    Write-Host $statut -ForegroundColor $couleur

    $Tableau.Add([PSCustomObject]@{
        'Folio'                = $p
        'Fichier'              = $NomFichier
        'Nb Factures Fichier'  = $nbSrc
        'Montant Fichier'      = [math]::Round($mtSrc, 2)
        'Nb Factures Oracle'   = $nbDef
        'Montant Oracle'       = $mtDef
        'Nb Factures Interface' = $nbInt
        'Montant Interface'    = $mtInt
        'Statut'               = $statut
    })
}

# =====================================================================
#  5. EXPORT ET SYNTHESE
# =====================================================================
$Tableau | Export-Csv -Path $FichierRapportCsv -Delimiter ';' -NoTypeInformation -Encoding UTF8

Write-Host ''
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host '  SYNTHESE' -ForegroundColor Cyan
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host ("  {0,-26} : {1}" -f 'Folios controles', $Folios.Count)
Write-Host ("  {0,-26} : {1}" -f 'Integres dans Oracle', $nbInteg) -ForegroundColor Green
Write-Host ("  {0,-26} : {1}" -f 'En open interface', $nbInterface) -ForegroundColor $(if ($nbInterface -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ("  {0,-26} : {1}" -f 'Autres (absent/ecart...)', $nbAutre) -ForegroundColor $(if ($nbAutre -gt 0) { 'Red' } else { 'Green' })
Write-Host ("  {0,-26} : {1}" -f 'Duree Oracle', "${duree}s")
Write-Host ("  {0,-26} : {1}" -f 'Rapport (CSV)', $FichierRapportCsv) -ForegroundColor Green
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host ''

if ($nbAutre -gt 0 -or $nbInterface -gt 0) { exit $EXIT_ANOMALIE }
exit $EXIT_OK
