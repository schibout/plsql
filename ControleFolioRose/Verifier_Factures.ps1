# =====================================================================
#  Controle Folio Rose - Reconciliation des factures
# =====================================================================
#  1) Lit les colonnes du fichier d'entree (Folio, Date, App Amont...,
#     Nom fichier transmis).
#  2) Interroge Oracle pour chaque couple (folio, fichier) et complete
#     Nb Pieces Oracle, Montant Oracle, Montant Interface, puis le statut.
#
#  Une seule connexion Oracle est ouverte pour l'ensemble du fichier :
#  la version precedente lancait un processus sqlplus par ligne, soit
#  autant d'ouvertures de session que de lignes a controler.
# =====================================================================
param(
    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le fichier CSV d'entree")]
    [string] $CheminFichierCsv,
    # Affiche les requetes envoyees et la sortie brute d'Oracle
    [switch] $Diagnostic,
    # Conserve le script SQL genere, pour analyse
    [switch] $GarderTempSQL,
    # Ne pas generer le rapport HTML (le CSV reste produit)
    [switch] $PasDeRapport,
    # Generer le rapport HTML sans l'ouvrir dans le navigateur
    [switch] $PasDOuverture
)

function Html-Echap {
    param([string]$T)
    if ([string]::IsNullOrEmpty($T)) { return '' }
    return $T.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function Format-Montant {
    param($V)
    return ('{0:N2}' -f [double]$V)
}

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 0 = tout concorde, 1 = erreur technique, 2 = des ecarts subsistent
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ECART = 2

# Le rendu HTML vit dans son propre fichier : Apercu_Rapport.ps1 le charge
# aussi, ce qui garantit que l'apercu et la production affichent la meme chose.
$ModuleRapport = Join-Path $ScriptDir 'Rapport_Html.ps1'
if (-not (Test-Path $ModuleRapport)) {
    Write-Host "[ERREUR] Rapport_Html.ps1 introuvable : $ModuleRapport" -ForegroundColor Red
    exit 1
}
. $ModuleRapport

# ---------------------------------------------------------------------
#  Fonctions utilitaires
# ---------------------------------------------------------------------

# Nettoie et convertit un montant (espaces, virgule ou point decimal).
# $script:NbMontantsIllisibles compte les valeurs non convertibles : la
# version precedente renvoyait 0 sans le signaler, ce qui transformait
# une donnee illisible en ecart silencieux.
$script:NbMontantsIllisibles = 0
function Parse-Montant ([string]$valeur) {
    if ([string]::IsNullOrWhiteSpace($valeur)) { return 0 }
    $v = $valeur.Trim().Replace(' ', '').Replace([string][char]160, '').Replace(',', '.')
    if ($v -eq '-' -or $v -eq '') { return 0 }
    try { return [decimal]::Parse($v, [System.Globalization.CultureInfo]::InvariantCulture) }
    catch {
        $script:NbMontantsIllisibles++
        if ($Diagnostic) { Write-Host "   [montant illisible] '$valeur'" -ForegroundColor DarkYellow }
        return 0
    }
}

# Normalise un libelle de colonne (sans accents, sans casse, sans espaces de bord)
function Normalize-Texte ([string]$s) {
    if ($null -eq $s) { return '' }
    $s = ($s -replace '[éèêëÉÈÊË]','e' -replace '[àâäÀÂÄ]','a' -replace '[ùûüÙÛÜ]','u' `
               -replace '[îïÎÏ]','i' -replace '[ôöÔÖ]','o' -replace '[çÇ]','c').Trim().ToLower()
    return $s -replace '\s+', ' '
}

# Lit une colonne depuis la ligne du fichier d'entree (tolere accents et espacements)
function Get-ColValue ($ligneCsv, [string[]]$nomsPossibles) {
    if ($null -eq $ligneCsv) { return '' }
    $props = $ligneCsv.PSObject.Properties

    foreach ($nom in $nomsPossibles) {
        $p = $props | Where-Object { $_.Name.Trim() -eq $nom } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }
    foreach ($nom in $nomsPossibles) {
        $cible = Normalize-Texte $nom
        $p = $props | Where-Object { (Normalize-Texte $_.Name) -eq $cible } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }
    foreach ($nom in $nomsPossibles) {
        $cibleAgressive = (Normalize-Texte $nom) -replace ' ',''
        $p = $props | Where-Object { ((Normalize-Texte $_.Name) -replace ' ','') -eq $cibleAgressive } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }
    return ''
}

# Les exports de ce projet arrivent tantot en CP850 (OEM), tantot en
# Windows-1252. Lire en 1252 un fichier CP850 corrompt les accents des
# EN-TETES, donc la reconnaissance des colonnes echoue et toutes les
# valeurs remontent vides. On determine donc l'encodage sur les octets :
# en CP850 les accents francais sont entre 0x80 et 0x9F, en Windows-1252
# cette plage ne contient que de la ponctuation.
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

# Corps des trois requetes metier, inchange par rapport a la version
# precedente. Seule l'enveloppe change : le resultat est prefixe d'une
# balise et d'un identifiant de couple, pour pouvoir tout demander en
# une seule session Oracle puis rattacher chaque reponse a sa ligne.
function Get-RequeteOracle {
    param([int]$Cle, [string]$Folio, [string]$FichierBase, [string]$Type)

    $f = $Folio.Replace("'", "''")
    $b = $FichierBase.Replace("'", "''")

    switch ($Type) {
        'CLIENTS' {
            return @"
SELECT '##RES##$Cle|' || NVL(q1.nb_trx, 0) || '|' || NVL(q1.sum_amt, 0) || '|' || NVL(q2.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT racta.CUSTOMER_TRX_ID) AS nb_trx,
          SUM(rctl.EXTENDED_AMOUNT)             AS sum_amt
   FROM   APPS.RA_CUSTOMER_TRX_ALL racta,
          APPS.RA_CUSTOMER_TRX_LINES_ALL rctl
   WHERE  racta.CUSTOMER_TRX_ID = rctl.CUSTOMER_TRX_ID
     AND  rctl.attribute10 LIKE TRIM('$b') || '%'
     AND  rctl.attribute9 = TRIM('$f')) q1
CROSS JOIN
 (SELECT SUM(CASE
                WHEN TYPMVT = 'SI_AMT_FACTURE' THEN FMT_AMOUNT
                ELSE -1 * FMT_AMOUNT
            END) AS sum_int
 FROM   DKA_IARPAFAC_INTERFACE
 WHERE  FIC_IDENT LIKE TRIM('$b') || '%'
   AND  LOCAL_ACCOUNT LIKE '411%'
   AND  OA_status != 'A'
   AND  FMT_ORIGIN = TRIM('$f')) q2;
"@
        }
        'FOURNISSEURS' {
            return @"
SELECT '##RES##$Cle|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx,
          SUM(aia.invoice_amount)         AS sum_amt
   FROM   APPS.AP_INVOICES_ALL aia
   WHERE  aia.attribute10 LIKE TRIM('$b') || '%'
     AND  aia.attribute9 = TRIM('$f')) q_def
CROSS JOIN
 (SELECT SUM(aili.amount) AS sum_int
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
"@
        }
        'GL' {
            return @"
SELECT '##RES##$Cle|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.sum_int, 0)
FROM
  (SELECT COUNT(DISTINCT gjh.je_header_id) AS nb_trx,
          SUM(gjl.entered_dr)              AS sum_amt
   FROM   APPS.GL_JE_HEADERS gjh
   JOIN   APPS.GL_JE_LINES gjl ON gjh.je_header_id = gjl.je_header_id
   WHERE  gjl.attribute10 LIKE TRIM('$b') || '%'
     AND  gjl.attribute9 = TRIM('$f')) q_def
CROSS JOIN
 (SELECT SUM(entered_dr) AS sum_int
  FROM   APPS.GL_INTERFACE
  WHERE  attribute10 LIKE TRIM('$b') || '%'
    AND  attribute9 = TRIM('$f')) q_int;
"@
        }
    }
    return ''
}

# =====================================================================
#  1. CONFIGURATION ORACLE
# =====================================================================
Write-Host ''
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host '  CONTROLE FOLIO ROSE - Reconciliation des factures' -ForegroundColor Cyan
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host "  Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host ''

$ConfigFile = Join-Path $ScriptDir 'config.ps1'
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERREUR] Fichier de configuration introuvable : $ConfigFile" -ForegroundColor Red
    exit $EXIT_TECH
}
. $ConfigFile

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"

# Le client etait code en dur sur "sqlplus" et jamais verifie : s'il etait
# absent du PATH, chaque interrogation echouait en silence et le rapport
# affichait 0 partout, donc KO sur toutes les lignes sans explication.
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
#  2. FICHIER D'ENTREE
# =====================================================================
$CheminAbsolu = Resolve-Path $CheminFichierCsv -ErrorAction SilentlyContinue
if ($null -eq $CheminAbsolu) {
    Write-Host "[ERREUR] Impossible de trouver le fichier CSV : $CheminFichierCsv" -ForegroundColor Red
    exit $EXIT_TECH
}

$LogDir = Join-Path $ScriptDir 'Logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$Timestamp         = Get-Date -Format 'ddMMyyyy_HHmmss'
$FichierRapportCsv = Join-Path $LogDir "Rapport_Verification_${Timestamp}.csv"
$FichierSqlTmp     = Join-Path $LogDir "requetes_${Timestamp}.sql"

$infoEnc    = Get-EncodageFichier -Chemin $CheminAbsolu.Path
$rawContent = [System.IO.File]::ReadAllText($CheminAbsolu.Path, $infoEnc.Enc) -split "`r?`n"
Write-Host "   Fichier   : $($CheminAbsolu.Path)" -ForegroundColor Green
Write-Host "   Encodage  : $($infoEnc.Nom)" -ForegroundColor Green

# Ignorer les 2 lignes de filtres en tete (ex: Folio;Ecart;Debut de periode...)
if ($rawContent.Count -gt 1 -and $rawContent[0] -match '^Folio[;,\t]Ecart') {
    $rawContent = $rawContent | Select-Object -Skip 2
}

$delimiter = ';'
if ($rawContent.Count -gt 0) {
    if ($rawContent[0] -match "`t") { $delimiter = "`t" }
    elseif ($rawContent[0] -match ',' -and -not ($rawContent[0] -match ';')) { $delimiter = ',' }
}

$Lignes = @($rawContent | ConvertFrom-Csv -Delimiter $delimiter)
Write-Host "   Lignes lues : $($Lignes.Count)" -ForegroundColor Green
Write-Host ''

# =====================================================================
#  3. PRE-CALCUL DES SOMMES PAR FOLIO ET FICHIER
# =====================================================================
$SommeAmontParCle      = @{}
$SommeEcartDebitParCle = @{}
foreach ($ligne in $Lignes) {
    $f   = (Get-ColValue $ligne 'Folio').Trim()
    $fic = (Get-ColValue $ligne 'Nom fichier transmis').Trim()
    if ([string]::IsNullOrWhiteSpace($fic) -or [string]::IsNullOrWhiteSpace($f)) { continue }

    $cle = "$f|$fic"
    if (-not $SommeAmontParCle.ContainsKey($cle)) {
        $SommeAmontParCle[$cle]      = 0
        $SommeEcartDebitParCle[$cle] = 0
    }
    $SommeAmontParCle[$cle]      += Parse-Montant (Get-ColValue $ligne @('App Amont Débit', 'App Amont Debit'))
    $SommeEcartDebitParCle[$cle] += Parse-Montant (Get-ColValue $ligne @('Ecarts Débit', 'Ecarts Debit', 'Ecart Débit', 'Ecart Debit'))
}

# =====================================================================
#  4. CONSTITUTION DES COUPLES A INTERROGER
# =====================================================================
# Les couples sont dedoublonnes : plusieurs lignes du fichier partagent
# souvent le meme (folio, fichier), qui etait interroge autant de fois.
Write-Host 'Etape 1 : Preparation des interrogations Oracle...' -ForegroundColor Yellow

$couples    = New-Object System.Collections.Generic.List[object]
$idxParCle  = @{}
$lignesUtiles = New-Object System.Collections.Generic.List[object]

foreach ($ligne in $Lignes) {
    $folio   = (Get-ColValue $ligne 'Folio').Trim()
    $fichier = (Get-ColValue $ligne 'Nom fichier transmis').Trim()
    if ([string]::IsNullOrWhiteSpace($fichier) -or [string]::IsNullOrWhiteSpace($folio)) { continue }

    $type = ''
    if     ($fichier -match 'CLIENTS')      { $type = 'CLIENTS' }
    elseif ($fichier -match 'FOURNISSEURS') { $type = 'FOURNISSEURS' }
    elseif ($fichier -match 'GL' -or $fichier -match 'GRAND LIVRE') { $type = 'GL' }
    else { continue }

    # Base du nom de fichier, sans le suffixe de transport _ST_..._<GUID>_001
    $fichierBase = $fichier
    $posST = $fichier.IndexOf('_ST_')
    if ($posST -gt 0) { $fichierBase = $fichier.Substring(0, $posST) }

    $cleOracle = "$folio|$fichierBase|$type"
    if (-not $idxParCle.ContainsKey($cleOracle)) {
        $idxParCle[$cleOracle] = $couples.Count
        $couples.Add([PSCustomObject]@{
            Cle = $couples.Count; Folio = $folio; FichierBase = $fichierBase; Type = $type
        })
    }

    $lignesUtiles.Add([PSCustomObject]@{
        Ligne = $ligne; Folio = $folio; Fichier = $fichier
        Type = $type; IdxOracle = $idxParCle[$cleOracle]
    })
}

if ($lignesUtiles.Count -eq 0) {
    Write-Host "[ERREUR] Aucune donnee valide. Verifier les colonnes 'Folio' et 'Nom fichier transmis'." -ForegroundColor Red
    Write-Host "         Colonnes detectees : $(($Lignes[0].PSObject.Properties.Name) -join ' | ')" -ForegroundColor Yellow
    exit $EXIT_TECH
}

Write-Host "   Lignes a controler : $($lignesUtiles.Count)" -ForegroundColor Green
Write-Host "   Interrogations Oracle distinctes : $($couples.Count)" -ForegroundColor Green
Write-Host ''

# =====================================================================
#  5. UNE SEULE SESSION ORACLE POUR TOUTES LES INTERROGATIONS
# =====================================================================
Write-Host 'Etape 2 : Interrogation Oracle...' -ForegroundColor Yellow

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('SET PAGESIZE 0')
[void]$sb.AppendLine('SET FEEDBACK OFF')
[void]$sb.AppendLine('SET HEADING OFF')
[void]$sb.AppendLine('SET LINESIZE 1000')
[void]$sb.AppendLine('SET TRIMSPOOL ON')
# SET DEFINE OFF : les noms de fichiers peuvent contenir un '&', que
# SQL*Plus interpreterait sinon comme une variable de substitution.
[void]$sb.AppendLine('SET DEFINE OFF')
[void]$sb.AppendLine('WHENEVER SQLERROR CONTINUE')
[void]$sb.AppendLine('')
foreach ($c in $couples) {
    [void]$sb.AppendLine((Get-RequeteOracle -Cle $c.Cle -Folio $c.Folio -FichierBase $c.FichierBase -Type $c.Type))
    [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('EXIT;')

# UTF-8 sans BOM : sqlplus echoue sur la premiere instruction s'il en trouve un.
[System.IO.File]::WriteAllText($FichierSqlTmp, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

$t0     = Get-Date
$sortie = & $SQL_CMD -S $CONNECT_STR "@$FichierSqlTmp" 2>&1
$rc     = $LASTEXITCODE
$duree  = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

$txtSortie = ($sortie | ForEach-Object { "$_" }) -join "`n"

if ($Diagnostic) {
    Write-Host '---- SORTIE ORACLE ----' -ForegroundColor DarkGray
    $sortie | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

# Une erreur Oracle ne doit plus se traduire par des montants a zero :
# la version precedente renvoyait 0|0|0 des que la sortie ne contenait
# pas de resultat, ce qui produisait un rapport entierement KO sans
# aucune indication de la cause reelle.
$erreursOra = @($sortie | Where-Object { $_ -match '^(ORA|SP2|TNS)-\d+' } | Select-Object -Unique)
if ($erreursOra.Count -gt 0) {
    Write-Host ''
    Write-Host '[ERREUR] Oracle a retourne des erreurs : le controle est interrompu.' -ForegroundColor Red
    Write-Host '         Aucun rapport ne sera produit, pour ne pas presenter des' -ForegroundColor Red
    Write-Host '         montants a zero comme un resultat de reconciliation.' -ForegroundColor Red
    $erreursOra | Select-Object -First 10 | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
    if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
    exit $EXIT_TECH
}

$resultats = @{}
foreach ($l in $sortie) {
    if ("$l" -match '##RES##(\d+)\|([^|]*)\|([^|]*)\|(.*)$') {
        $resultats[[int]$Matches[1]] = @{
            Nb        = $Matches[2].Trim()
            Mt        = $Matches[3].Trim()
            Interface = $Matches[4].Trim()
        }
    }
}

if (-not $GarderTempSQL) { Remove-Item $FichierSqlTmp -ErrorAction SilentlyContinue }
else { Write-Host "   [INFO] Script SQL conserve : $FichierSqlTmp" -ForegroundColor Yellow }

$nbSansReponse = $couples.Count - $resultats.Count
Write-Host "   $($resultats.Count) / $($couples.Count) interrogation(s) aboutie(s) en ${duree}s (code retour $rc)" -ForegroundColor Green
if ($nbSansReponse -gt 0) {
    Write-Host "   [ATTENTION] $nbSansReponse interrogation(s) sans reponse : lignes marquees INDETERMINE." -ForegroundColor Yellow
}
Write-Host ''

# =====================================================================
#  6. RESTITUTION
# =====================================================================
$TableauResultats = [System.Collections.Generic.List[PSCustomObject]]::new()
$nbOk = 0; $nbKo = 0; $nbIndet = 0

Write-Host ("{0,-6} | {1,-12} | {2,-40} | {3,8} | {4,15} | {5,15} | {6,12} | {7,12} | {8,12} | {9,9} | {10,15} | {11,15} | {12,8} | {13,15} | {14,-12} | {15}" -f `
    'FOLIO', 'TYPE', 'FICHIER', 'NB AMONT', 'MT AMONT', 'SOMME AMONT', 'ECART DEBIT', 'ECART CREDIT', 'SOMME ECART', 'NB ORA', 'MT ORACLE', 'MT INTERFACE', 'ECART NB', 'ECART MT', 'STATUT', 'COMMENTAIRE')
Write-Host ('-' * 280)

foreach ($u in $lignesUtiles) {
    $ligne   = $u.Ligne
    $folio   = $u.Folio
    $fichier = $u.Fichier
    $type    = $u.Type

    $valDate           = Get-ColValue $ligne 'Date'
    $txtAppAmontNb     = Get-ColValue $ligne @('App Amont Nb piéce', 'App Amont Nb piece')
    $txtAppAmontDebit  = Get-ColValue $ligne @('App Amont Débit', 'App Amont Debit')
    $txtAppAmontCredit = Get-ColValue $ligne @('App Amont Crédit', 'App Amont Credit')
    $txtSiFinNb        = Get-ColValue $ligne @('SI Finance Nb piece', 'SI Finance Nb piéce', 'SI Finance Nb pièce')
    $txtSiFinDebit     = Get-ColValue $ligne @('SI Finance Débit', 'SI Finance Debit')
    $txtSiFinCredit    = Get-ColValue $ligne @('SI Finance Crédit', 'SI Finance Credit')
    $txtEcartNb        = Get-ColValue $ligne @('Ecarts Nb Piece', 'Ecart Nb Piece', 'Ecarts Nb piéce', 'Ecarts Nb pièce')
    $txtEcartDebit     = Get-ColValue $ligne @('Ecarts Débit', 'Ecarts Debit', 'Ecart Débit', 'Ecart Debit')
    $txtEcartCredit    = Get-ColValue $ligne @('Ecarts Crédit', 'Ecarts Credit', 'Ecart Crédit', 'Ecart Credit')
    $txtCommentaire    = (Get-ColValue $ligne @('Commentaire', 'Commentaires')).Trim()

    $ora = $resultats[$u.IdxOracle]
    $repondu = ($null -ne $ora)
    if ($repondu) {
        $txtNbOra = $ora.Nb; $txtMtOra = $ora.Mt; $txtMtInterface = $ora.Interface
    } else {
        $txtNbOra = ''; $txtMtOra = ''; $txtMtInterface = ''
    }

    $mt_app_amont = Parse-Montant $txtAppAmontDebit
    $mt_ora       = Parse-Montant $txtMtOra
    $ecart_debit  = Parse-Montant $txtEcartDebit
    $ecart_credit = Parse-Montant $txtEcartCredit
    $nb_amont     = Parse-Montant $txtAppAmontNb
    $nb_ora       = Parse-Montant $txtNbOra
    $ecart_nb_calcule = $nb_amont - $nb_ora
    $ecart_mt_calcule = $mt_app_amont - $mt_ora

    $cle = "$folio|$fichier"
    $somme_amont_fichier       = $SommeAmontParCle[$cle]
    $somme_ecart_debit_fichier = $SommeEcartDebitParCle[$cle]

    if (-not $repondu) {
        $statut = 'INDETERMINE'; $couleur = 'Yellow'; $nbIndet++
    } elseif ($ecart_nb_calcule -eq 0 -and $ecart_mt_calcule -eq 0) {
        $statut = 'OK'; $couleur = 'Green'; $nbOk++
    } else {
        $statut = 'KO'; $couleur = 'Red'; $nbKo++
    }

    Write-Host ("{0,-6} | {1,-12} | {2,-40} | {3,8:N0} | {4,15:N2} | {5,15:N2} | {6,12:N2} | {7,12:N2} | {8,12:N2} | {9,9:N0} | {10,15:N2} | {11,15:N2} | {12,8:N0} | {13,15:N2} | " -f `
        $folio, $type, $fichier, $nb_amont, $mt_app_amont, $somme_amont_fichier, $ecart_debit, $ecart_credit, `
        $somme_ecart_debit_fichier, $nb_ora, $mt_ora, (Parse-Montant $txtMtInterface), $ecart_nb_calcule, $ecart_mt_calcule) -NoNewline
    Write-Host ("{0,-12}" -f $statut) -ForegroundColor $couleur -NoNewline

    # Commentaire tronque a l'ecran pour ne pas casser l'alignement ; la
    # valeur complete part dans le CSV.
    if ($txtCommentaire -ne '') {
        $c = $txtCommentaire -replace '\s+', ' '
        if ($c.Length -gt 30) { $c = $c.Substring(0, 29) + [char]0x2026 }
        Write-Host (" | $c") -ForegroundColor DarkCyan
    } else {
        Write-Host ''
    }

    $TableauResultats.Add([PSCustomObject]@{
        'Folio'                  = $folio
        'Type'                   = $type
        'Date'                   = $valDate
        'Nom fichier transmis'   = $fichier
        'App Amont Nb piéce'     = $txtAppAmontNb
        'App Amont Débit'        = $txtAppAmontDebit
        'App Amont Crédit'       = $txtAppAmontCredit
        'SI Finance Nb piece'    = $txtSiFinNb
        'SI Finance Débit'       = $txtSiFinDebit
        'SI Finance Crédit'      = $txtSiFinCredit
        'Ecarts Nb Piece'        = $txtEcartNb
        'Ecarts Débit'           = $txtEcartDebit
        'Ecarts Crédit'          = $txtEcartCredit
        # Repris tel quel du fichier d'entree, a la meme position que dans
        # celui-ci : c'est la justification saisie par le gestionnaire, sans
        # laquelle un ecart deja explique ressort comme une anomalie neuve.
        'Commentaire'            = $txtCommentaire
        'Somme Amont Fichier'    = $somme_amont_fichier
        'Somme Ecart Fichier'    = $somme_ecart_debit_fichier
        'Montant Interface OA'   = $txtMtInterface
        'Nb Pieces OA'           = $txtNbOra
        'Montant OA '            = $txtMtOra
        'Ecart Nb Piece Calcule' = $ecart_nb_calcule
        'Ecart Mt Calcule'       = $ecart_mt_calcule
        'Statut Verification'    = $statut
    })
}

# =====================================================================
#  7. EXPORT ET SYNTHESE
# =====================================================================
$TableauResultats | Export-Csv -Path $FichierRapportCsv -Delimiter ';' -NoTypeInformation -Encoding UTF8

# =====================================================================
#  RAPPORT HTML
# =====================================================================
$FichierRapportHtml = $FichierRapportCsv -replace '\.csv$', '.html'

if (-not $PasDeRapport) {
    Write-Host ''
    Write-Host 'Generation du rapport HTML...' -ForegroundColor Yellow
    New-RapportHtml -Resultats $TableauResultats `
                    -CheminHtml $FichierRapportHtml `
                    -FichierSource (Split-Path $CheminAbsolu.Path -Leaf) `
                    -Encodage $infoEnc.Nom `
                    -Base "${ORA_USER}@${ORA_DSN}" `
                    -NbInterrogations $couples.Count `
                    -Duree $duree `
                    -CheminCsv $FichierRapportCsv
    Write-Host "   Rapport HTML : $FichierRapportHtml" -ForegroundColor Green
}

Write-Host ''
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host '  SYNTHESE' -ForegroundColor Cyan
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host ("  {0,-26} : {1}" -f 'Lignes controlees', $TableauResultats.Count)
Write-Host ("  {0,-26} : {1}" -f 'Concordantes (OK)', $nbOk)      -ForegroundColor Green
Write-Host ("  {0,-26} : {1}" -f 'En ecart (KO)', $nbKo)          -ForegroundColor $(if ($nbKo -gt 0) { 'Red' } else { 'Green' })
if ($nbIndet -gt 0) {
    Write-Host ("  {0,-26} : {1}" -f 'Indeterminees', $nbIndet)   -ForegroundColor Yellow
}
if ($script:NbMontantsIllisibles -gt 0) {
    Write-Host ("  {0,-26} : {1}" -f 'Montants illisibles', $script:NbMontantsIllisibles) -ForegroundColor Yellow
    Write-Host '     Ces valeurs ont ete comptees comme 0 : relancer avec -Diagnostic pour les voir.' -ForegroundColor Yellow
}
Write-Host ("  {0,-26} : {1}" -f 'Duree Oracle', "${duree}s")
Write-Host ("  {0,-26} : {1}" -f 'Donnees (CSV)', $FichierRapportCsv)   -ForegroundColor Green
if (-not $PasDeRapport) {
    Write-Host ("  {0,-26} : {1}" -f 'Rapport (HTML)', $FichierRapportHtml) -ForegroundColor Green
}
Write-Host '=======================================================================' -ForegroundColor Cyan
Write-Host ''

if ((-not $PasDeRapport) -and (-not $PasDOuverture) -and (Test-Path $FichierRapportHtml)) {
    Start-Process $FichierRapportHtml
}

if ($nbKo -gt 0 -or $nbIndet -gt 0) { exit $EXIT_ECART }
exit $EXIT_OK
