# =====================================================================
# Contrôle Folio Rose - Réconciliation des factures
#
# 1) Lit 5 colonnes directement du fichier d'entree :
#    Folio, Date, App Amont Nb piéce, App Amont Débit, Nom fichier transmis
# 2) Boucle sur chaque ligne : interroge Oracle et remplit les 3 colonnes :
#    Nb Pieces Oracle, Montant Oracle, Montant Interface (+ Statut)
# =====================================================================
param(
    [Parameter(Mandatory=$true, HelpMessage="Chemin vers le fichier CSV d'entrée")]
    [string]$CheminFichierCsv,
    # Affiche, pour chaque ligne, la requete SQL envoyee et la sortie brute d'Oracle
    [switch]$Diagnostic
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------

# Nettoie et convertit un montant (espaces, virgule ou point decimal)
function Parse-Montant ([string]$valeur) {
    if ([string]::IsNullOrWhiteSpace($valeur)) { return 0 }
    $v = $valeur.Trim().Replace(" ", "").Replace(",", ".")
    if ($v -eq "-") { return 0 }
    try { return [decimal]::Parse($v, [System.Globalization.CultureInfo]::InvariantCulture) }
    catch { return 0 }
}

# Normalise un libelle de colonne (sans accents, sans casse, sans espaces de bord)
function Normalize-Texte ([string]$s) {
    if ($null -eq $s) { return "" }
    $s = ($s -replace '[éèêëÉÈÊË]','e' -replace '[àâäÀÂÄ]','a' -replace '[ùûüÙÛÜ]','u' `
               -replace '[îïÎÏ]','i' -replace '[ôöÔÖ]','o' -replace '[çÇ]','c').Trim().ToLower()
    # Remplace les espaces multiples ou insécables par un seul espace
    return $s -replace '\s+', ' '
}

# Lit une colonne directement depuis la ligne du fichier d'entree (tolere accents/encodage)
function Get-ColValue ($ligneCsv, [string[]]$nomsPossibles) {
    if ($null -eq $ligneCsv) { return "" }
    $props = $ligneCsv.PSObject.Properties

    # 1. Correspondance exacte
    foreach ($nom in $nomsPossibles) {
        $p = $props | Where-Object { $_.Name.Trim() -eq $nom } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }

    # 2. Correspondance normalisée (sans accents ni casse)
    foreach ($nom in $nomsPossibles) {
        $cible = Normalize-Texte $nom
        $p = $props | Where-Object { (Normalize-Texte $_.Name) -eq $cible } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }

    # 3. Correspondance agressive (sans aucun espace, ignore les fautes d'espacement)
    foreach ($nom in $nomsPossibles) {
        $cibleAgressive = (Normalize-Texte $nom) -replace ' ',''
        $p = $props | Where-Object { ((Normalize-Texte $_.Name) -replace ' ','') -eq $cibleAgressive } | Select-Object -First 1
        if ($p) { return [string]$p.Value }
    }

    return ""
}

# Interroge Oracle pour un couple (folio, base du nom de fichier) et renvoie les 3 montants
function Get-MontantsOracle ([string]$folio, [string]$fichierBase, [string]$type) {
    $f = $folio.Replace("'", "''")
    $b = $fichierBase.Replace("'", "''")

    $sql = "SET PAGESIZE 0`nSET FEEDBACK OFF`nSET HEADING OFF`nSET LINESIZE 1000`nSET TRIMSPOOL ON`n"

    switch ($type) {
        "CLIENTS" {
            # ---- Logique AR (Clients) ----
            $sql += @"
SELECT NVL(q1.nb_trx, 0) || '|' || NVL(q1.sum_amt, 0) || '|' || NVL(q2.sum_int, 0)
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
        "FOURNISSEURS" {
            # ---- Logique AP (Fournisseurs) ----
            $sql += @"
SELECT NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.sum_int, 0)
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
    -- Optionnel : Exclure les factures en erreur dans l'interface
    AND  NOT EXISTS (
             SELECT 1 
             FROM APPS.AP_INTERFACE_REJECTIONS air 
             WHERE air.parent_id = aii.invoice_id 
               AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE')
         )
 ) q_int;
"@
        }
        "GL" {
            # ---- Logique GL (Grand Livre) ----
            $sql += @"
SELECT NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_amt, 0) || '|' || NVL(q_int.sum_int, 0)
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
    $sql += "`nEXIT;`n"

    $sortie = $sql | & $SQL_CMD -S $CONNECT_STR

    if ($Diagnostic) {
        Write-Host "---- SQL [$folio / $fichierBase] ----" -ForegroundColor DarkGray
        Write-Host $sql -ForegroundColor DarkGray
        Write-Host "---- SORTIE ORACLE ----" -ForegroundColor DarkGray
        $sortie | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }

    $ligneRes = $sortie | Where-Object { $_ -match '\|' } | Select-Object -First 1
    if ($ligneRes) {
        $p = $ligneRes -split '\|'
        return @{ Nb = $p[0].Trim(); Mt = $p[1].Trim(); Interface = $p[2].Trim() }
    }
    return @{ Nb = "0"; Mt = "0"; Interface = "0" }
}

# ---------------------------------------------------------------------
# 1. Configuration Oracle
# ---------------------------------------------------------------------
$ConfigFile = Join-Path $ScriptDir "config.ps1"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERREUR] Fichier de configuration introuvable : $ConfigFile" -ForegroundColor Red
    exit 1
}
. $ConfigFile

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"
$SQL_CMD     = "sqlplus"

# ---------------------------------------------------------------------
# 2. Fichier d'entrée et dossier Logs
# ---------------------------------------------------------------------
$CheminAbsolu = Resolve-Path $CheminFichierCsv -ErrorAction SilentlyContinue
if ($null -eq $CheminAbsolu) {
    Write-Host "[ERREUR] Impossible de trouver le fichier CSV : $CheminFichierCsv" -ForegroundColor Red
    exit 1
}

$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$Timestamp         = Get-Date -Format "ddMMyyyy_HHmmss"
$FichierRapportCsv = Join-Path $LogDir "Rapport_Verification_${Timestamp}.csv"

# Lecture brute (encodage systeme pour gerer les accents du CSV)
$rawContent = Get-Content -Path $CheminAbsolu.Path -Encoding Default

# Ignorer les 2 lignes de filtres en tete (ex: Folio;Ecart;Début de période...)
if ($rawContent.Count -gt 1 -and $rawContent[0] -match "^Folio[;,\t]Ecart") {
    $rawContent = $rawContent | Select-Object -Skip 2
}

# Auto-detection du delimiteur
$delimiter = ";"
if ($rawContent.Count -gt 0) {
    if ($rawContent[0] -match "`t") { $delimiter = "`t" }
    elseif ($rawContent[0] -match "," -and -not ($rawContent[0] -match ";")) { $delimiter = "," }
}

$Lignes = $rawContent | ConvertFrom-Csv -Delimiter $delimiter

# ---------------------------------------------------------------------
# 3. Pré-calcul des sommes par Folio et Nom de Fichier
# ---------------------------------------------------------------------
$SommeAmontParCle = @{}
$SommeEcartDebitParCle = @{}
foreach ($ligne in $Lignes) {
    $f = (Get-ColValue $ligne "Folio").Trim()
    $fic = (Get-ColValue $ligne "Nom fichier transmis").Trim()
    if ([string]::IsNullOrWhiteSpace($fic) -or [string]::IsNullOrWhiteSpace($f)) { continue }
    
    $cle = "$f|$fic"
    
    if (-not $SommeAmontParCle.ContainsKey($cle)) {
        $SommeAmontParCle[$cle] = 0
        $SommeEcartDebitParCle[$cle] = 0
    }

    $mt_amont = Parse-Montant (Get-ColValue $ligne @("App Amont Débit", "App Amont Debit"))
    $SommeAmontParCle[$cle] += $mt_amont

    $mt_ecart = Parse-Montant (Get-ColValue $ligne @("Ecarts Débit", "Ecarts Debit", "Ecart Débit", "Ecart Debit"))
    $SommeEcartDebitParCle[$cle] += $mt_ecart
}

# ---------------------------------------------------------------------
# 4. Boucle : 5 colonnes du fichier + interrogation Oracle (3 colonnes)
# ---------------------------------------------------------------------
$TableauResultats = [System.Collections.Generic.List[PSCustomObject]]::new()
$lignesValides = 0
$total = ($Lignes | Measure-Object).Count
$index = 0

Write-Host ""
Write-Host ("{0,-6} | {1,-12} | {2,-40} | {3,8} | {4,15} | {5,15} | {6,12} | {7,12} | {8,12} | {9,9} | {10,15} | {11,15} | {12,8} | {13,15} | {14,-8}" -f "FOLIO", "TYPE", "FICHIER", "NB AMONT", "MT AMONT", "SOMME AMONT", "ECART DEBIT", "ECART CREDIT", "SOMME ECART", "NB ORA", "MT ORACLE", "MT INTERFACE", "ECART NB", "ECART MT", "STATUT")
Write-Host ("-" * 243)

foreach ($ligne in $Lignes) {
    $index++

    # ---- Colonnes lues directement du fichier d'entree ----
    $folio             = (Get-ColValue $ligne "Folio").Trim()
    $fichier           = (Get-ColValue $ligne "Nom fichier transmis").Trim()
    $valDate           = Get-ColValue $ligne "Date"
    $txtAppAmontNb     = Get-ColValue $ligne @("App Amont Nb piéce", "App Amont Nb piece")
    $txtAppAmontDebit  = Get-ColValue $ligne @("App Amont Débit", "App Amont Debit")
    $txtAppAmontCredit = Get-ColValue $ligne @("App Amont Crédit", "App Amont Credit")
    $txtSiFinNb        = Get-ColValue $ligne @("SI Finance Nb piece", "SI Finance Nb piéce", "SI Finance Nb pièce")
    $txtSiFinDebit     = Get-ColValue $ligne @("SI Finance Débit", "SI Finance Debit")
    $txtSiFinCredit    = Get-ColValue $ligne @("SI Finance Crédit", "SI Finance Credit")
    $txtEcartNb        = Get-ColValue $ligne @("Ecarts Nb Piece", "Ecart Nb Piece", "Ecarts Nb piéce", "Ecarts Nb pièce")
    $txtEcartDebit     = Get-ColValue $ligne @("Ecarts Débit", "Ecarts Debit", "Ecart Débit", "Ecart Debit")
    $txtEcartCredit    = Get-ColValue $ligne @("Ecarts Crédit", "Ecarts Credit", "Ecart Crédit", "Ecart Credit")

    if ([string]::IsNullOrWhiteSpace($fichier) -or [string]::IsNullOrWhiteSpace($folio)) { continue }

    # ---- Filtrage et Detection du Type ----
    $type = ""
    if ($fichier -match "CLIENTS") { $type = "CLIENTS" }
    elseif ($fichier -match "FOURNISSEURS") { $type = "FOURNISSEURS" }
    elseif ($fichier -match "GL" -or $fichier -match "GRAND LIVRE") { $type = "GL" }
    else { continue } # On ignore les autres types de fichiers

    $lignesValides++

    Write-Progress -Activity "Interrogation Oracle" -Status "$index / $total : $folio ($type)" `
                   -PercentComplete ([int](($index / [Math]::Max($total,1)) * 100))

    # ---- Base du nom de fichier (sans le suffixe de transport _ST_..._<GUID>_001) ----
    $fichierBase = $fichier
    $posST = $fichier.IndexOf("_ST_")
    if ($posST -gt 0) { $fichierBase = $fichier.Substring(0, $posST) }

    # ---- Interrogation Oracle : remplit les 3 colonnes ----
    $ora = Get-MontantsOracle $folio $fichierBase $type
    $txtNbOra       = $ora.Nb
    $txtMtOra       = $ora.Mt
    $txtMtInterface = $ora.Interface

    # ---- Comparaison / statut ----
    $mt_app_amont = Parse-Montant $txtAppAmontDebit
    $mt_ora       = Parse-Montant $txtMtOra
    $ecart_debit  = Parse-Montant $txtEcartDebit
    $ecart_credit = Parse-Montant $txtEcartCredit
    $nb_amont     = Parse-Montant $txtAppAmontNb
    $nb_ora       = Parse-Montant $txtNbOra
    $ecart_nb_calcule = $nb_amont - $nb_ora
    $ecart_mt_calcule = $mt_app_amont - $mt_ora

    $cle = "$folio|$fichier"
    $somme_amont_fichier = $SommeAmontParCle[$cle]
    $somme_ecart_debit_fichier = $SommeEcartDebitParCle[$cle]

    $statut  = "KO"; $couleur = "Red"
    if ($ecart_nb_calcule -eq 0 -and $ecart_mt_calcule -eq 0) { $statut = "OK"; $couleur = "Green" }

    # ---- Affichage console ----
    Write-Host ("{0,-6} | {1,-12} | {2,-40} | {3,8:N0} | {4,15:N2} | {5,15:N2} | {6,12:N2} | {7,12:N2} | {8,12:N2} | {9,9:N0} | {10,15:N2} | {11,15:N2} | {12,8:N0} | {13,15:N2} | " -f `
        $folio, $type, $fichier, $nb_amont, $mt_app_amont, $somme_amont_fichier, $ecart_debit, $ecart_credit, $somme_ecart_debit_fichier, $nb_ora, $mt_ora, (Parse-Montant $txtMtInterface), $ecart_nb_calcule, $ecart_mt_calcule) -NoNewline
    Write-Host ("{0,-8}" -f $statut) -ForegroundColor $couleur

    # ---- Ligne du rapport : colonnes du fichier + ecart + colonnes calculees + statut ----
    $TableauResultats.Add([PSCustomObject]@{
        "Folio"                 = $folio
        "Type"                  = $type
        "Date"                  = $valDate
        "Nom fichier transmis"  = $fichier
        "App Amont Nb piéce"    = $txtAppAmontNb
        "App Amont Débit"       = $txtAppAmontDebit
        "App Amont Crédit"      = $txtAppAmontCredit
        "SI Finance Nb piece"   = $txtSiFinNb
        "SI Finance Débit"      = $txtSiFinDebit
        "SI Finance Crédit"     = $txtSiFinCredit
        "Ecarts Nb Piece"       = $txtEcartNb
        "Ecarts Débit"          = $txtEcartDebit
        "Ecarts Crédit"         = $txtEcartCredit
        "Somme Amont Fichier"   = $somme_amont_fichier
        "Somme Ecart Fichier"   = $somme_ecart_debit_fichier
		"Montant Interface OA"  = $txtMtInterface
		"Nb Pieces OA"          = $txtNbOra
        "Montant OA "           = $txtMtOra
        "Ecart Nb Piece Calcule"= $ecart_nb_calcule
        "Ecart Mt Calcule"      = $ecart_mt_calcule
        "Statut Verification"   = $statut
    })
}
Write-Progress -Activity "Interrogation Oracle" -Completed

if ($lignesValides -eq 0) {
    Write-Host "`n[ERREUR] Aucune donnee valide. Verifiez les colonnes 'Folio' et 'Nom fichier transmis' du CSV." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------
# 4. Export du rapport
# ---------------------------------------------------------------------
$TableauResultats | Export-Csv -Path $FichierRapportCsv -Delimiter ";" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=======================================================================================" -ForegroundColor Cyan
Write-Host " Fichier CSV de reconciliation genere ($($TableauResultats.Count) lignes) :" -ForegroundColor Cyan
Write-Host " $FichierRapportCsv" -ForegroundColor Green
Write-Host "=======================================================================================" -ForegroundColor Cyan
