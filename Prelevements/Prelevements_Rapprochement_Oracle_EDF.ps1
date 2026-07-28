#Requires -Version 5.1
# =====================================================================
#  Prelevements - Rapprochement automatique Oracle / EDF
#  Rapprochement par date d'echeance, decline jusqu'a la ligne unitaire,
#  avec justification automatique des ecarts par les fichiers de rejets.
#
#  Classeur produit (5 onglets) :
#    1. Synthese Journaliere Brute      (ce qui est parti / ce qui est arrive)
#    2. Etat Comparatif & Ecarts        (par echeance, statut a 3 niveaux)
#    3. Detail par IBAN creancier       (quel compte porte l'ecart)
#    4. Rejets detailles                (rejet -> ligne Oracle d'origine)
#    5. Lignes Oracle unitaires         (toutes les lignes emises, filtrables)
#
#  IMPORTANT - ENCODAGE : ce fichier doit rester en UTF-8 AVEC BOM.
#  Sans BOM, Windows PowerShell 5.1 le lit en ANSI et tous les libelles
#  accentues des onglets sont corrompus.
# =====================================================================

$ErrorActionPreference = 'Stop'

$InvC       = [System.Globalization.CultureInfo]::InvariantCulture
$Enc1252    = [System.Text.Encoding]::GetEncoding(1252)
$Tolerance  = 0.005      # les deux sources sont arrondies au centime

# ---------------------------------------------------------------------
#  Fonctions utilitaires de conversion
# ---------------------------------------------------------------------

function ConvertTo-Montant {
    param([string]$Texte)
    if ([string]::IsNullOrWhiteSpace($Texte)) { return [decimal]0 }
    # Retire l'espace ordinaire et l'espace insecable (160) utilises comme
    # separateur de milliers, puis normalise la virgule decimale.
    $t = $Texte.Trim().Replace(' ', '').Replace([string][char]160, '').Replace(',', '.')
    $v = [decimal]0
    if ([decimal]::TryParse($t, [System.Globalization.NumberStyles]::Float, $InvC, [ref]$v)) { return $v }
    return [decimal]0
}

function ConvertTo-DateExacte {
    param([string]$Texte, [string]$Format)
    if ([string]::IsNullOrWhiteSpace($Texte)) { return $null }
    $d = [datetime]::MinValue
    if ([datetime]::TryParseExact($Texte.Trim(), $Format, $InvC,
            [System.Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
    return $null
}

function Format-DateFr {
    param($Date)
    if ($null -eq $Date) { return '' }
    return $Date.ToString('dd/MM/yyyy')
}

function Get-CleDate {
    param($Date)
    if ($null -eq $Date) { return '' }
    return $Date.ToString('yyyyMMdd')
}

# Regle historique de calcul de la date cible theorique (J+2 en semaine,
# J+4 pour les emissions du jeudi et du vendredi). Conservee a l'identique :
# elle ne sert plus a rapprocher, seulement a signaler un delai atypique.
function Get-DateCibleTheorique {
    param([datetime]$DateEmission)
    switch ($DateEmission.DayOfWeek) {
        'Thursday' { return $DateEmission.AddDays(4) }
        'Friday'   { return $DateEmission.AddDays(4) }
        'Saturday' { return $DateEmission.AddDays(2) }
        default    { return $DateEmission.AddDays(2) }
    }
}

# Recupere le groupe associe a une cle d'index sous forme de liste.
# Ne PAS remplacer par @($Index[$Cle]) : sur une cle absente, @($null) rend un
# tableau d'UN element nul (Count = 1) et non un tableau vide, ce qui fausse
# tous les comptages.
function Get-Groupe {
    param([hashtable]$Index, [string]$Cle)
    $liste = New-Object System.Collections.Generic.List[object]
    if ($Index.ContainsKey($Cle)) {
        foreach ($v in $Index[$Cle]) { if ($null -ne $v) { $liste.Add($v) } }
    }
    return , $liste     # la virgule empeche PowerShell de derouler la liste
}

function Get-IndexColonne {
    param($Map, [string]$Nom, [int]$Defaut)
    if ($Map -and $Map.ContainsKey($Nom)) { return [int]$Map[$Nom] }
    return $Defaut
}

# ---------------------------------------------------------------------
#  ETAPE 1 : lecture des emissions Oracle (une ligne = un prelevement)
# ---------------------------------------------------------------------

function Get-OracleLignes {
    param([string]$OraclePath)

    $lignes    = New-Object System.Collections.Generic.List[object]
    $anomalies = New-Object System.Collections.Generic.List[object]

    if (-not (Test-Path $OraclePath)) {
        return [PSCustomObject]@{ Lignes = $lignes; Anomalies = $anomalies }
    }

    $fichiers = @(Get-ChildItem -Path $OraclePath -Recurse -File |
                  Where-Object { $_.Name -like '*PCX*' -or $_.Name -like '*PCL*' })

    foreach ($f in $fichiers) {
        $dateEmissionTxt = $f.Directory.Name
        $dateEmission    = ConvertTo-DateExacte $dateEmissionTxt 'yyyyMMdd'

        $idx    = $null
        $nbCols = 0

        foreach ($ligne in [System.IO.File]::ReadAllLines($f.FullName, $Enc1252)) {

            if ([string]::IsNullOrWhiteSpace($ligne)) { continue }
            if ($ligne.StartsWith('HEADER'))          { continue }

            $champs = $ligne.Split(',')

            # La ligne FORMAT1ENTITYID porte les noms de colonnes : on s'en sert
            # pour resoudre les index par nom plutot que de les figer en dur.
            if ($ligne.StartsWith('FORMAT1ENTITYID')) {
                $map = @{}
                for ($i = 0; $i -lt $champs.Count; $i++) {
                    $nom = $champs[$i].Trim()
                    if ($nom -and -not $map.ContainsKey($nom)) { $map[$nom] = $i }
                }
                $nbCols = $champs.Count
                $idx = @{
                    DateValeur    = Get-IndexColonne $map 'VALUEDATE'                   2
                    Echeance      = Get-IndexColonne $map 'TRANSACTIONDATE'             3
                    Montant       = Get-IndexColonne $map 'AMOUNT'                      5
                    Reference     = Get-IndexColonne $map 'DESCRIPTION/REFERENCE'       8
                    IbanCreancier = Get-IndexColonne $map 'ENTITYBANKACCOUNTNUMBER'    11
                    NomClient     = Get-IndexColonne $map 'COUNTERPARTYNAME'           14
                    IbanDebiteur  = Get-IndexColonne $map 'CPTYSECONDARYACCOUNTNUMBER' 25
                    Rum           = Get-IndexColonne $map 'SEPAMANDATEID'              44
                    TypeDD        = Get-IndexColonne $map 'SEPADDTYPE'                 48
                }
                continue
            }

            if ($null -eq $idx) { continue }   # donnee avant l'en-tete : ignoree

            if ($champs.Count -ne $nbCols) {
                $anomalies.Add([PSCustomObject]@{
                    Fichier = $f.Name
                    Attendu = $nbCols
                    Trouve  = $champs.Count
                    Ligne   = $ligne
                })
                continue
            }

            $lignes.Add([PSCustomObject]@{
                DateEmission   = $dateEmission
                FichierSource  = $f.Name
                DateValeur     = ConvertTo-DateExacte $champs[$idx.DateValeur] 'MM/dd/yyyy'
                Echeance       = ConvertTo-DateExacte $champs[$idx.Echeance]   'MM/dd/yyyy'
                Montant        = ConvertTo-Montant    $champs[$idx.Montant]
                Reference      = $champs[$idx.Reference].Trim()
                IbanCreancier  = $champs[$idx.IbanCreancier].Trim()
                NomClient      = $champs[$idx.NomClient].Trim()
                IbanDebiteur   = $champs[$idx.IbanDebiteur].Trim()
                Rum            = $champs[$idx.Rum].Trim()
                TypeDD         = $champs[$idx.TypeDD].Trim()
                EstRejete      = $false
                CodeRejet      = ''
                MotifRejet     = ''
            })
        }
    }

    return [PSCustomObject]@{ Lignes = $lignes; Anomalies = $anomalies }
}

# ---------------------------------------------------------------------
#  ETAPE 2 : lecture des acquittements EDF (lignes ORACLE uniquement)
# ---------------------------------------------------------------------

function Get-EdfReceptions {
    param([string]$EdfPath)

    $receptions = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path $EdfPath)) { return $receptions }

    # La 6e colonne absorbe le point-virgule final des exports bancaires :
    # sans elle, Import-Csv emet un avertissement d'en-tete manquant.
    $entetes = 'SI', 'IbanCreancier', 'Echeance', 'Nb', 'Montant', 'Reserve'

    foreach ($f in Get-ChildItem -Path $EdfPath -File -Filter 'IMPORT_AVP_DK.*.*.csv') {

        $dateFichier = ConvertTo-DateExacte ($f.Name.Split('.')[1]) 'yyyyMMdd'

        Import-Csv -Path $f.FullName -Header $entetes -Delimiter ';' |
            Where-Object { $_.SI -eq 'ORACLE' } |
            ForEach-Object {
                $receptions.Add([PSCustomObject]@{
                    DateFichier   = $dateFichier
                    FichierSource = $f.Name
                    IbanCreancier = $_.IbanCreancier.Trim()
                    Echeance      = ConvertTo-DateExacte $_.Echeance 'dd/MM/yyyy'
                    Nb            = [int]$_.Nb
                    Montant       = ConvertTo-Montant $_.Montant
                })
            }
    }

    return $receptions
}

# ---------------------------------------------------------------------
#  ETAPE 3 : lecture des rejets internes de la banque
# ---------------------------------------------------------------------

function Get-Rejets {
    param([string]$RejetsPath)

    $rejets = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path $RejetsPath)) { return $rejets }

    foreach ($f in Get-ChildItem -Path $RejetsPath -File | Where-Object { $_.Name -like 'REJETS_INTERNES_DK.*' }) {

        $dateFichier = ConvertTo-DateExacte ($f.Name.Split('.')[1]) 'yyyyMMdd'

        foreach ($ligne in [System.IO.File]::ReadAllLines($f.FullName, $Enc1252)) {

            if ([string]::IsNullOrWhiteSpace($ligne)) { continue }
            $champs = $ligne.Split(';')

            # Seules les lignes de donnees commencent par un IBAN : cela ecarte
            # le titre et l'en-tete sans dependre d'un numero de ligne fixe.
            if ($champs.Count -lt 7)                 { continue }
            if (-not $champs[0].Trim().StartsWith('FR')) { continue }

            $rejets.Add([PSCustomObject]@{
                DateFichier   = $dateFichier
                FichierSource = $f.Name
                IbanCreancier = $champs[0].Trim()
                Rum           = $champs[1].Trim()
                IbanDebiteur  = $champs[2].Trim()
                Echeance      = ConvertTo-DateExacte $champs[3] 'dd/MM/yyyy'
                Montant       = ConvertTo-Montant    $champs[4]
                CodeRejet     = $champs[5].Trim()
                MotifRejet    = $champs[6].Trim()
                LigneBrute    = $ligne
                Perimetre     = 'Hors ORACLE'
                Rattachement  = ''
                OracleLigne   = $null
            })
        }
    }

    return $rejets
}

# ---------------------------------------------------------------------
#  ETAPE 4 : rattachement de chaque rejet a sa ligne Oracle, via le RUM
#
#  Le rattachement determine le perimetre : un rejet dont le RUM est absent
#  du referentiel Oracle releve d'un autre SI (CIF) et n'entre pas dans le
#  rapprochement. Ne JAMAIS filtrer sur le prefixe du RUM : les mandats
#  Oracle se presentent aussi bien en "NVOA..." qu'en "++OA...".
# ---------------------------------------------------------------------

function Join-RejetsOracle {
    param($LignesOracle, $Rejets)

    $parRumEcheance = @{}
    $parRum         = @{}

    foreach ($o in $LignesOracle) {
        if (-not $o.Rum) { continue }

        $cle = '{0}|{1}' -f $o.Rum, (Get-CleDate $o.Echeance)
        if (-not $parRumEcheance.ContainsKey($cle)) {
            $parRumEcheance[$cle] = New-Object System.Collections.Generic.List[object]
        }
        $parRumEcheance[$cle].Add($o)

        if (-not $parRum.ContainsKey($o.Rum)) {
            $parRum[$o.Rum] = New-Object System.Collections.Generic.List[object]
        }
        $parRum[$o.Rum].Add($o)
    }

    foreach ($r in $Rejets) {

        $cle        = '{0}|{1}' -f $r.Rum, (Get-CleDate $r.Echeance)
        $candidats  = $null
        $rattachement = 'Exact (RUM + echeance)'

        if ($parRumEcheance.ContainsKey($cle)) {
            $candidats = @($parRumEcheance[$cle] | Where-Object { -not $_.EstRejete })
        }

        # Repli : meme RUM sur une autre echeance (mandat rejoue).
        if (-not $candidats -or $candidats.Count -eq 0) {
            if ($parRum.ContainsKey($r.Rum)) {
                $candidats = @($parRum[$r.Rum] | Where-Object { -not $_.EstRejete })
                $rattachement = 'Approximatif (RUM seul)'
            }
        }

        if (-not $candidats -or $candidats.Count -eq 0) { continue }

        # A RUM egal, privilegier la ligne dont le montant correspond.
        $cible = $candidats | Where-Object {
                     [math]::Abs([double]($_.Montant - $r.Montant)) -lt $Tolerance
                 } | Select-Object -First 1
        if (-not $cible) { $cible = $candidats[0] }

        $cible.EstRejete  = $true
        $cible.CodeRejet  = $r.CodeRejet
        $cible.MotifRejet = $r.MotifRejet

        $r.Perimetre    = 'ORACLE'
        $r.Rattachement = $rattachement
        $r.OracleLigne  = $cible
    }
}

# ---------------------------------------------------------------------
#  ETAPE 5 : determination du statut d'une maille rapprochee
# ---------------------------------------------------------------------

function Get-Statut {
    param(
        [int]$NbOracle, [decimal]$TotalOracle,
        [int]$NbEdf,    [decimal]$TotalEdf,
        [int]$NbRejets, [decimal]$TotalRejets,
        [switch]$MailleIban
    )

    $ecartNb          = $NbEdf - $NbOracle
    $ecartMontant     = $TotalEdf - $TotalOracle
    $ecartNbResiduel  = $ecartNb + $NbRejets
    $ecartMntResiduel = $ecartMontant + $TotalRejets

    if ($NbOracle -eq 0) {
        $statut = 'Hors perimetre (emission Oracle non fournie)'
    }
    elseif ($NbEdf -eq 0 -and $NbRejets -eq 0) {
        $statut = 'En attente de reception'
    }
    elseif ($ecartNb -eq 0 -and [math]::Abs([double]$ecartMontant) -lt $Tolerance) {
        $statut = 'OK'
    }
    elseif ($ecartNbResiduel -eq 0 -and [math]::Abs([double]$ecartMntResiduel) -lt $Tolerance) {
        $statut = 'OK - Ecart justifie par rejet'
    }
    else {
        $statut = 'Ecart NON justifie'
    }

    return [PSCustomObject]@{
        EcartNb          = $ecartNb
        EcartMontant     = $ecartMontant
        EcartNbResiduel  = $ecartNbResiduel
        EcartMntResiduel = $ecartMntResiduel
        Statut           = $statut
    }
}

# ---------------------------------------------------------------------
#  Ecriture Excel : une grille = deux appels COM, pas un par cellule.
# ---------------------------------------------------------------------

function Write-Grille {
    param(
        $Feuille,
        [int]$LigneEntete,
        [int]$ColDepart,
        [string[]]$Entetes,
        $Donnees,
        [string[]]$Proprietes,
        [int]$CouleurEntete = 0x7D491F
    )

    $nbCol = $Entetes.Count

    $arrEntetes = New-Object 'object[,]' 1, $nbCol
    for ($c = 0; $c -lt $nbCol; $c++) { $arrEntetes[0, $c] = $Entetes[$c] }

    $plageEntete = $Feuille.Range(
        $Feuille.Cells.Item($LigneEntete, $ColDepart),
        $Feuille.Cells.Item($LigneEntete, $ColDepart + $nbCol - 1))
    $plageEntete.Value2             = $arrEntetes
    $plageEntete.Interior.Color     = $CouleurEntete
    $plageEntete.Font.Color         = 0xFFFFFF
    $plageEntete.Font.Bold          = $true
    $plageEntete.HorizontalAlignment = -4108
    $plageEntete.WrapText           = $true

    # NE PAS ecrire @($Donnees) ici. Sur le Windows PowerShell 5.1 de ce poste,
    # l'operateur @() applique directement a une List[object] leve
    # "Les types des arguments ne correspondent pas" (reproduit y compris avec
    # -NoProfile et sur une liste vide). L'enumeration explicite ci-dessous
    # fonctionne pour tous les types de collections.
    $liste = New-Object System.Collections.Generic.List[object]
    if ($null -ne $Donnees) {
        if ($Donnees -is [string] -or $Donnees -isnot [System.Collections.IEnumerable]) {
            $liste.Add($Donnees)
        }
        else {
            foreach ($d in $Donnees) { $liste.Add($d) }
        }
    }
    if ($liste.Count -eq 0) { return 0 }

    $arr = New-Object 'object[,]' $liste.Count, $nbCol
    for ($r = 0; $r -lt $liste.Count; $r++) {
        for ($c = 0; $c -lt $nbCol; $c++) {
            $arr[$r, $c] = $liste[$r].($Proprietes[$c])
        }
    }

    $plage = $Feuille.Range(
        $Feuille.Cells.Item($LigneEntete + 1, $ColDepart),
        $Feuille.Cells.Item($LigneEntete + $liste.Count, $ColDepart + $nbCol - 1))
    $plage.Value2 = $arr

    return $liste.Count
}

function Set-FormatColonnes {
    param($Feuille, [int]$Ligne1, [int]$Ligne2, [hashtable]$Formats)
    if ($Ligne2 -lt $Ligne1) { return }
    foreach ($col in $Formats.Keys) {
        $Feuille.Range(
            $Feuille.Cells.Item($Ligne1, $col),
            $Feuille.Cells.Item($Ligne2, $col)).NumberFormatLocal = $Formats[$col]
    }
}

# A appeler AVANT toute ecriture dans la colonne. Excel interprete les valeurs
# a l'ecriture : une date "01/07/2026" ecrite dans une colonne au format General
# est convertie en numero de serie (et lue en MM/JJ/AAAA), et un RUM commencant
# par "+" est pris pour une formule. Formater apres coup ne repare rien.
function Set-ColonnesTexte {
    param($Feuille, [int[]]$Colonnes)
    foreach ($c in $Colonnes) { $Feuille.Columns.Item($c).NumberFormatLocal = '@' }
}

function Set-LargeurColonnes {
    param($Feuille, [hashtable]$Largeurs)
    foreach ($col in $Largeurs.Keys) {
        $Feuille.Columns.Item($col).ColumnWidth = $Largeurs[$col]
    }
}

function Enable-Filtre {
    param($Feuille, [int]$LigneEntete, [int]$NbLignes, [int]$NbColonnes, $Application)
    if ($NbLignes -le 0) { return }
    $Feuille.Range(
        $Feuille.Cells.Item($LigneEntete, 1),
        $Feuille.Cells.Item($LigneEntete + $NbLignes, $NbColonnes)).AutoFilter() | Out-Null
    try {
        $Feuille.Activate() | Out-Null
        $Application.ActiveWindow.FreezePanes = $false
        $Feuille.Cells.Item($LigneEntete + 1, 1).Select() | Out-Null
        $Application.ActiveWindow.FreezePanes = $true
    } catch { }
}

# Couleurs de statut, alignees sur la documentation v2.
function Get-CouleurStatut {
    param([string]$Statut)
    switch -Wildcard ($Statut) {
        'OK - Ecart justifie*' { return 0xFCE4D6 }   # bleu   : ecart explique
        'OK'                   { return 0xDAEFED }   # vert   : concordance totale
        'Ecart NON justifie'   { return 0xCCCCFF }   # rouge  : a investiguer
        default                { return 0xE8E8E8 }   # gris   : hors perimetre / attente
    }
}

# =====================================================================
#  TRAITEMENT
# =====================================================================

$excel = $null; $workbook = $null
$ws1 = $null; $ws2 = $null; $ws3 = $null; $ws4 = $null; $ws5 = $null
$pidExcel = $null   # PID de l'instance Excel creee par ce script, et d'elle seule

try {
    # -----------------------------------------------------------------
    #  Configuration des chemins (repertoire du script)
    # -----------------------------------------------------------------
    $rootPath   = $PSScriptRoot
    $oraclePath = Join-Path $rootPath 'ORACLE'
    $edfPath    = Join-Path $rootPath 'EDF'

    # Detection du dossier rejets sans distinction de casse.
    $rejetsPath = Join-Path $edfPath 'REJETS'
    if (Test-Path $edfPath) {
        $dossierRejets = Get-ChildItem -Path $edfPath -Directory |
                         Where-Object { $_.Name -like 'rejets' } | Select-Object -First 1
        if ($dossierRejets) { $rejetsPath = $dossierRejets.FullName }
    }

    $timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputPath = Join-Path $rootPath "Rapprochement_Oracle_EDF_$timestamp.xlsx"

    Write-Host "Analyse du dossier en cours : $(Split-Path $rootPath -Leaf)" -ForegroundColor Yellow

    # -----------------------------------------------------------------
    #  Lecture des trois sources
    # -----------------------------------------------------------------
    $resOracle    = Get-OracleLignes  -OraclePath $oraclePath
    $lignesOracle = $resOracle.Lignes
    $anomalies    = $resOracle.Anomalies

    if ($lignesOracle.Count -eq 0) {
        Write-Warning "Aucune ligne Oracle trouvee dans '$oraclePath' (fichiers *PCX* / *PCL*)."
    }

    $receptionsEdf = Get-EdfReceptions -EdfPath    $edfPath
    $rejets        = Get-Rejets        -RejetsPath $rejetsPath

    Join-RejetsOracle -LignesOracle $lignesOracle -Rejets $rejets

    $rejetsOracle = @($rejets | Where-Object { $_.Perimetre -eq 'ORACLE' })

    Write-Host ("Lignes Oracle : {0,6}   |   Receptions EDF : {1,4}   |   Rejets : {2,3} (dont {3} ORACLE)" -f `
        $lignesOracle.Count, $receptionsEdf.Count, $rejets.Count, $rejetsOracle.Count) -ForegroundColor Cyan

    if ($anomalies.Count -gt 0) {
        Write-Warning "$($anomalies.Count) ligne(s) Oracle ignoree(s) : nombre de champs inattendu."
    }

    # -----------------------------------------------------------------
    #  ONGLET 1 : synthese journaliere brute
    # -----------------------------------------------------------------
    $synthOracle = @($lignesOracle | Group-Object { Get-CleDate $_.DateEmission } | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            Date    = Format-DateFr $_.Group[0].DateEmission
            NbLines = $_.Count
            Total   = [double][math]::Round((($_.Group | Measure-Object Montant -Sum).Sum), 2)
        }
    })

    $synthEdf = @($receptionsEdf | Group-Object { Get-CleDate $_.DateFichier } | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            Date  = Format-DateFr $_.Group[0].DateFichier
            NbEdf = [int](($_.Group | Measure-Object Nb -Sum).Sum)
            Total = [double][math]::Round((($_.Group | Measure-Object Montant -Sum).Sum), 2)
        }
    })

    # -----------------------------------------------------------------
    #  ONGLET 2 : etat comparatif par echeance
    # -----------------------------------------------------------------
    $oraParEch = @{}; foreach ($g in ($lignesOracle  | Group-Object { Get-CleDate $_.Echeance })) { $oraParEch[$g.Name] = $g.Group }
    $edfParEch = @{}; foreach ($g in ($receptionsEdf | Group-Object { Get-CleDate $_.Echeance })) { $edfParEch[$g.Name] = $g.Group }
    $rejParEch = @{}; foreach ($g in ($rejetsOracle  | Group-Object { Get-CleDate $_.Echeance })) { $rejParEch[$g.Name] = $g.Group }

    $clesEcheance = @(@($oraParEch.Keys) + @($edfParEch.Keys) + @($rejParEch.Keys) |
                      Where-Object { $_ } | Select-Object -Unique | Sort-Object)

    $comparatif = New-Object System.Collections.Generic.List[object]

    foreach ($cle in $clesEcheance) {

        $ora = Get-Groupe $oraParEch $cle
        $edf = Get-Groupe $edfParEch $cle
        $rej = Get-Groupe $rejParEch $cle

        $nbOra  = $ora.Count
        $totOra = if ($nbOra) { ($ora | Measure-Object Montant -Sum).Sum } else { [decimal]0 }
        $nbEdf  = if ($edf.Count) { [int](($edf | Measure-Object Nb -Sum).Sum) } else { 0 }
        $totEdf = if ($edf.Count) { ($edf | Measure-Object Montant -Sum).Sum } else { [decimal]0 }
        $nbRej  = $rej.Count
        $totRej = if ($nbRej) { ($rej | Measure-Object Montant -Sum).Sum } else { [decimal]0 }

        $s = Get-Statut -NbOracle $nbOra -TotalOracle $totOra `
                        -NbEdf    $nbEdf -TotalEdf    $totEdf `
                        -NbRejets $nbRej -TotalRejets $totRej

        $datesEmission  = @($ora | ForEach-Object { $_.DateEmission } | Sort-Object -Unique)
        $datesReception = @($edf | ForEach-Object { $_.DateFichier  } | Sort-Object -Unique)

        $delai = ''; $cibleTheo = ''; $alerteDelai = ''
        if ($datesEmission.Count -gt 0) {
            $theo      = Get-DateCibleTheorique $datesEmission[0]
            $cibleTheo = Format-DateFr $theo
            if ($datesReception.Count -gt 0) {
                $delai = [int]($datesReception[0] - $datesEmission[0]).Days
                if ($datesReception[0] -ne $theo) { $alerteDelai = 'Delai atypique' }
            }
        }

        $comparatif.Add([PSCustomObject]@{
            Echeance         = Format-DateFr (ConvertTo-DateExacte $cle 'yyyyMMdd')
            DatesEmission    = (($datesEmission  | ForEach-Object { Format-DateFr $_ }) -join ' + ')
            DatesReception   = (($datesReception | ForEach-Object { Format-DateFr $_ }) -join ' + ')
            NbOracle         = $nbOra
            NbEdf            = $nbEdf
            EcartNb          = $s.EcartNb
            TotalOracle      = [double][math]::Round($totOra, 2)
            TotalEdf         = [double][math]::Round($totEdf, 2)
            EcartMontant     = [double][math]::Round($s.EcartMontant, 2)
            NbRejets         = $nbRej
            TotalRejets      = [double][math]::Round($totRej, 2)
            EcartNbResiduel  = $s.EcartNbResiduel
            EcartMntResiduel = [double][math]::Round($s.EcartMntResiduel, 2)
            Delai            = $delai
            CibleTheorique   = $cibleTheo
            AlerteDelai      = $alerteDelai
            Statut           = $s.Statut
        })
    }

    # -----------------------------------------------------------------
    #  ONGLET 3 : detail par echeance x IBAN creancier
    # -----------------------------------------------------------------
    $detailIban = New-Object System.Collections.Generic.List[object]

    $oraParIban = @{}; foreach ($g in ($lignesOracle  | Group-Object { '{0}|{1}' -f (Get-CleDate $_.Echeance), $_.IbanCreancier })) { $oraParIban[$g.Name] = $g.Group }
    $edfParIban = @{}; foreach ($g in ($receptionsEdf | Group-Object { '{0}|{1}' -f (Get-CleDate $_.Echeance), $_.IbanCreancier })) { $edfParIban[$g.Name] = $g.Group }
    $rejParIban = @{}; foreach ($g in ($rejetsOracle  | Group-Object { '{0}|{1}' -f (Get-CleDate $_.Echeance), $_.IbanCreancier })) { $rejParIban[$g.Name] = $g.Group }

    $clesIban = @(@($oraParIban.Keys) + @($edfParIban.Keys) + @($rejParIban.Keys) |
                  Where-Object { $_ } | Select-Object -Unique | Sort-Object)

    foreach ($cle in $clesIban) {

        $partie = $cle.Split('|')
        $ora = Get-Groupe $oraParIban $cle
        $edf = Get-Groupe $edfParIban $cle
        $rej = Get-Groupe $rejParIban $cle

        $nbOra  = $ora.Count
        $totOra = if ($nbOra) { ($ora | Measure-Object Montant -Sum).Sum } else { [decimal]0 }
        $nbEdf  = if ($edf.Count) { [int](($edf | Measure-Object Nb -Sum).Sum) } else { 0 }
        $totEdf = if ($edf.Count) { ($edf | Measure-Object Montant -Sum).Sum } else { [decimal]0 }
        $nbRej  = $rej.Count
        $totRej = if ($nbRej) { ($rej | Measure-Object Montant -Sum).Sum } else { [decimal]0 }

        $s = Get-Statut -NbOracle $nbOra -TotalOracle $totOra `
                        -NbEdf    $nbEdf -TotalEdf    $totEdf `
                        -NbRejets $nbRej -TotalRejets $totRej

        $detailIban.Add([PSCustomObject]@{
            Echeance         = Format-DateFr (ConvertTo-DateExacte $partie[0] 'yyyyMMdd')
            IbanCreancier    = $partie[1]
            NbOracle         = $nbOra
            NbEdf            = $nbEdf
            EcartNb          = $s.EcartNb
            TotalOracle      = [double][math]::Round($totOra, 2)
            TotalEdf         = [double][math]::Round($totEdf, 2)
            EcartMontant     = [double][math]::Round($s.EcartMontant, 2)
            NbRejets         = $nbRej
            TotalRejets      = [double][math]::Round($totRej, 2)
            EcartNbResiduel  = $s.EcartNbResiduel
            EcartMntResiduel = [double][math]::Round($s.EcartMntResiduel, 2)
            Statut           = $s.Statut
        })
    }

    # -----------------------------------------------------------------
    #  ONGLET 4 : rejets detailles, enrichis de la ligne Oracle d'origine
    # -----------------------------------------------------------------
    $rejetsDetail = @($rejets |
        Sort-Object @{Expression = { $_.DateFichier }}, @{Expression = { $_.IbanCreancier }} |
        ForEach-Object {
            $o = $_.OracleLigne
            [PSCustomObject]@{
                FichierRejet    = $_.FichierSource
                DateFichier     = Format-DateFr $_.DateFichier
                Perimetre       = $_.Perimetre
                IbanCreancier   = $_.IbanCreancier
                Rum             = $_.Rum
                IbanDebiteur    = $_.IbanDebiteur
                Echeance        = Format-DateFr $_.Echeance
                Montant         = [double][math]::Round($_.Montant, 2)
                CodeRejet       = $_.CodeRejet
                MotifRejet      = $_.MotifRejet
                NomClient       = if ($o) { $o.NomClient }                 else { '' }
                DateEmission    = if ($o) { Format-DateFr $o.DateEmission } else { '' }
                Reference       = if ($o) { $o.Reference }                 else { '' }
                TypeDD          = if ($o) { $o.TypeDD }                    else { '' }
                FichierOracle   = if ($o) { $o.FichierSource }             else { '' }
                Rattachement    = $_.Rattachement
                LigneBrute      = $_.LigneBrute
            }
        })

    # -----------------------------------------------------------------
    #  ONGLET 5 : toutes les lignes de prelevement Oracle emises
    # -----------------------------------------------------------------
    $lignesDetail = @($lignesOracle |
        Sort-Object @{Expression = { $_.Echeance }}, @{Expression = { $_.IbanCreancier }}, @{Expression = { $_.Montant }} |
        ForEach-Object {
            [PSCustomObject]@{
                DateEmission  = Format-DateFr $_.DateEmission
                Echeance      = Format-DateFr $_.Echeance
                IbanCreancier = $_.IbanCreancier
                IbanDebiteur  = $_.IbanDebiteur
                Rum           = $_.Rum
                NomClient     = $_.NomClient
                Montant       = [double][math]::Round($_.Montant, 2)
                TypeDD        = $_.TypeDD
                Reference     = $_.Reference
                FichierSource = $_.FichierSource
                Statut        = if ($_.EstRejete) { 'REJETE' } else { 'OK' }
                CodeRejet     = $_.CodeRejet
                MotifRejet    = $_.MotifRejet
            }
        })

    # =================================================================
    #  RESTITUTION EXCEL
    # =================================================================
    Write-Host 'Generation du classeur Excel...' -ForegroundColor Yellow

    # Releve des instances Excel deja ouvertes par l'utilisateur AVANT de creer
    # la notre : la difference identifie sans ambiguite le processus du script,
    # seul qu'on s'autorisera a terminer en dernier recours.
    $pidsAvant = @(Get-Process EXCEL -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

    $excel = New-Object -ComObject Excel.Application

    $pidExcel = @(Get-Process EXCEL -ErrorAction SilentlyContinue |
                  Select-Object -ExpandProperty Id |
                  Where-Object { $pidsAvant -notcontains $_ }) | Select-Object -First 1

    $excel.Visible       = $false
    $excel.DisplayAlerts = $false
    $excel.ScreenUpdating = $false

    $nbFeuillesDefaut = $excel.SheetsInNewWorkbook
    $excel.SheetsInNewWorkbook = 1
    $workbook = $excel.Workbooks.Add()
    $excel.SheetsInNewWorkbook = $nbFeuillesDefaut

    $fMontant = '# ##0,00'
    $fNombre  = '# ##0'
    $fTexte   = '@'

    # --- ONGLET 1 : Synthese Journaliere Brute -----------------------
    $ws1 = $workbook.Sheets.Item(1)
    $ws1.Name = 'Synthèse Journalière Brute'
    $ws1.Cells.Item(1, 1).Value2 = 'ÉTAPE 1 : SYNTHÈSE JOURNALIÈRE BRUTE'
    $ws1.Cells.Item(1, 1).Font.Bold = $true
    $ws1.Cells.Item(1, 1).Font.Size = 14
    $ws1.Cells.Item(3, 1).Value2 = 'Données émises par ORACLE'
    $ws1.Cells.Item(3, 1).Font.Bold = $true
    $ws1.Cells.Item(3, 5).Value2 = 'Données reçues par EDF'
    $ws1.Cells.Item(3, 5).Font.Bold = $true

    Set-ColonnesTexte $ws1 @(1, 5)

    $n = Write-Grille -Feuille $ws1 -LigneEntete 4 -ColDepart 1 `
            -Entetes @("Date Gén. Oracle", "Nb Total Lignes", "Montant Total (€)") `
            -Donnees $synthOracle -Proprietes @('Date', 'NbLines', 'Total')
    Set-FormatColonnes $ws1 5 (4 + $n) @{ 2 = $fNombre; 3 = $fMontant }

    $n = Write-Grille -Feuille $ws1 -LigneEntete 4 -ColDepart 5 `
            -Entetes @("Date Prise Chg EDF", "Nb Prél. Pris en Chg", "Montant Pris en Chg (€)") `
            -Donnees $synthEdf -Proprietes @('Date', 'NbEdf', 'Total')
    Set-FormatColonnes $ws1 5 (4 + $n) @{ 6 = $fNombre; 7 = $fMontant }

    Set-LargeurColonnes $ws1 @{ 1 = 20; 2 = 16; 3 = 20; 4 = 3; 5 = 20; 6 = 20; 7 = 24 }

    # --- ONGLET 2 : Etat Comparatif & Ecarts -------------------------
    $ws2 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws1)
    $ws2.Name = 'État Comparatif & Écarts'
    $ws2.Cells.Item(1, 1).Value2 = 'ÉTAPE 2 : ÉTAT COMPARATIF ET RAPPROCHEMENT DES ÉCARTS (par date d''échéance)'
    $ws2.Cells.Item(1, 1).Font.Bold = $true
    $ws2.Cells.Item(1, 1).Font.Size = 14

    $nbRouge = @($comparatif | Where-Object { $_.Statut -eq 'Ecart NON justifie' }).Count
    $ws2.Cells.Item(2, 1).Value2 = "$($comparatif.Count) échéance(s) analysée(s) - $nbRouge écart(s) NON justifié(s) à investiguer"
    $ws2.Cells.Item(2, 1).Font.Italic = $true

    $entetes2 = @("Échéance", "Date(s) Gén. Oracle", "Date(s) Réc. EDF",
                  "Nb Oracle", "Nb EDF", "Écart Nb",
                  "Total Oracle (€)", "Total EDF (€)", "Écart Montant (€)",
                  "Nb Rejets Imputés", "Montant Rejets (€)",
                  "Écart Nb Résiduel", "Écart Montant Résiduel (€)",
                  "Délai (j)", "Cible Théorique J+2/J+4", "Alerte Délai", "Statut")
    $props2 = @('Echeance', 'DatesEmission', 'DatesReception',
                'NbOracle', 'NbEdf', 'EcartNb',
                'TotalOracle', 'TotalEdf', 'EcartMontant',
                'NbRejets', 'TotalRejets',
                'EcartNbResiduel', 'EcartMntResiduel',
                'Delai', 'CibleTheorique', 'AlerteDelai', 'Statut')

    Set-ColonnesTexte $ws2 @(1, 2, 3, 15, 16, 17)

    $n2 = Write-Grille -Feuille $ws2 -LigneEntete 4 -ColDepart 1 -Entetes $entetes2 -Donnees $comparatif -Proprietes $props2
    Set-FormatColonnes $ws2 5 (4 + $n2) @{
        4 = $fNombre; 5 = $fNombre; 6 = $fNombre
        7 = $fMontant; 8 = $fMontant; 9 = $fMontant; 10 = $fNombre; 11 = $fMontant
        12 = $fNombre; 13 = $fMontant
    }
    for ($i = 0; $i -lt $n2; $i++) {
        $ligne  = 5 + $i
        $statut = $comparatif[$i].Statut
        $ws2.Range($ws2.Cells.Item($ligne, 12), $ws2.Cells.Item($ligne, 17)).Interior.Color = (Get-CouleurStatut $statut)
        if ($statut -eq 'Ecart NON justifie') { $ws2.Cells.Item($ligne, 17).Font.Bold = $true }
    }
    Set-LargeurColonnes $ws2 @{
        1 = 12; 2 = 24; 3 = 24; 4 = 10; 5 = 10; 6 = 10; 7 = 17; 8 = 17; 9 = 17
        10 = 12; 11 = 16; 12 = 12; 13 = 18; 14 = 9; 15 = 15; 16 = 14; 17 = 34
    }
    Enable-Filtre $ws2 4 $n2 $entetes2.Count $excel

    # --- ONGLET 3 : Detail par IBAN creancier ------------------------
    $ws3 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws2)
    $ws3.Name = 'Détail par IBAN créancier'
    $ws3.Cells.Item(1, 1).Value2 = 'ÉTAPE 3 : DÉTAIL PAR ÉCHÉANCE ET PAR IBAN CRÉANCIER'
    $ws3.Cells.Item(1, 1).Font.Bold = $true
    $ws3.Cells.Item(1, 1).Font.Size = 14
    $ws3.Cells.Item(2, 1).Value2 = "Maille la plus fine commune aux deux sources : désigne quel compte créancier porte l'écart."
    $ws3.Cells.Item(2, 1).Font.Italic = $true

    $entetes3 = @("Échéance", "IBAN Créancier",
                  "Nb Oracle", "Nb EDF", "Écart Nb",
                  "Total Oracle (€)", "Total EDF (€)", "Écart Montant (€)",
                  "Nb Rejets", "Montant Rejets (€)",
                  "Écart Nb Résiduel", "Écart Montant Résiduel (€)", "Statut")
    $props3 = @('Echeance', 'IbanCreancier',
                'NbOracle', 'NbEdf', 'EcartNb',
                'TotalOracle', 'TotalEdf', 'EcartMontant',
                'NbRejets', 'TotalRejets',
                'EcartNbResiduel', 'EcartMntResiduel', 'Statut')

    Set-ColonnesTexte $ws3 @(1, 2, 13)

    $n3 = Write-Grille -Feuille $ws3 -LigneEntete 4 -ColDepart 1 -Entetes $entetes3 -Donnees $detailIban -Proprietes $props3
    Set-FormatColonnes $ws3 5 (4 + $n3) @{
        3 = $fNombre; 4 = $fNombre; 5 = $fNombre
        6 = $fMontant; 7 = $fMontant; 8 = $fMontant; 9 = $fNombre; 10 = $fMontant
        11 = $fNombre; 12 = $fMontant
    }
    for ($i = 0; $i -lt $n3; $i++) {
        $statut = $detailIban[$i].Statut
        if ($statut -ne 'OK') {
            $ligne = 5 + $i
            $ws3.Range($ws3.Cells.Item($ligne, 11), $ws3.Cells.Item($ligne, 13)).Interior.Color = (Get-CouleurStatut $statut)
        }
    }
    Set-LargeurColonnes $ws3 @{
        1 = 12; 2 = 30; 3 = 10; 4 = 10; 5 = 10; 6 = 17; 7 = 17; 8 = 17
        9 = 11; 10 = 16; 11 = 12; 12 = 18; 13 = 34
    }
    Enable-Filtre $ws3 4 $n3 $entetes3.Count $excel

    # --- ONGLET 4 : Rejets detailles ---------------------------------
    $ws4 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws3)
    $ws4.Name = 'Rejets détaillés'
    $ws4.Cells.Item(1, 1).Value2 = 'ÉTAPE 4 : REJETS INTERNES RATTACHÉS À LEUR LIGNE ORACLE D''ORIGINE'
    $ws4.Cells.Item(1, 1).Font.Bold = $true
    $ws4.Cells.Item(1, 1).Font.Size = 14
    $ws4.Cells.Item(2, 1).Value2 = "Rattachement par RUM. Périmètre ""Hors ORACLE"" = mandat d'un autre SI (CIF), exclu du rapprochement."
    $ws4.Cells.Item(2, 1).Font.Italic = $true

    $entetes4 = @("Fichier Rejet", "Date Fichier", "Périmètre",
                  "IBAN Créancier", "RUM", "IBAN Débiteur", "Échéance", "Montant (€)",
                  "Code Rejet", "Motif du Rejet",
                  "Nom Client (Oracle)", "Date Gén. Oracle", "Référence / Lot",
                  "Type", "Fichier Source Oracle", "Rattachement",
                  "Ligne Brute d'Origine (piste d'audit)")
    $props4 = @('FichierRejet', 'DateFichier', 'Perimetre',
                'IbanCreancier', 'Rum', 'IbanDebiteur', 'Echeance', 'Montant',
                'CodeRejet', 'MotifRejet',
                'NomClient', 'DateEmission', 'Reference',
                'TypeDD', 'FichierOracle', 'Rattachement', 'LigneBrute')

    # Tout est force en texte sauf le montant : dates, IBAN, RUM (un RUM en
    # "++OA..." serait pris pour une formule) et ligne brute d'audit.
    Set-ColonnesTexte $ws4 @(1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17)

    $n4 = Write-Grille -Feuille $ws4 -LigneEntete 4 -ColDepart 1 -Entetes $entetes4 -Donnees $rejetsDetail -Proprietes $props4 -CouleurEntete 0xBD814F
    Set-FormatColonnes $ws4 5 (4 + $n4) @{ 8 = $fMontant }
    for ($i = 0; $i -lt $n4; $i++) {
        if ($rejetsDetail[$i].Perimetre -ne 'ORACLE') {
            $ws4.Range($ws4.Cells.Item(5 + $i, 1), $ws4.Cells.Item(5 + $i, 17)).Font.Color = 0x808080
        }
    }
    Set-LargeurColonnes $ws4 @{
        1 = 34; 2 = 12; 3 = 13; 4 = 30; 5 = 38; 6 = 30; 7 = 12; 8 = 14
        9 = 11; 10 = 22; 11 = 34; 12 = 15; 13 = 30; 14 = 7; 15 = 46; 16 = 24; 17 = 110
    }
    Enable-Filtre $ws4 4 $n4 $entetes4.Count $excel

    # --- ONGLET 5 : Lignes Oracle unitaires --------------------------
    $ws5 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws4)
    $ws5.Name = 'Lignes Oracle unitaires'
    $ws5.Cells.Item(1, 1).Value2 = 'ÉTAPE 5 : TOUTES LES LIGNES DE PRÉLÈVEMENT ÉMISES PAR ORACLE'
    $ws5.Cells.Item(1, 1).Font.Bold = $true
    $ws5.Cells.Item(1, 1).Font.Size = 14
    $ws5.Cells.Item(2, 1).Value2 = "Filtrer la colonne Statut sur ""REJETE"" pour isoler les lignes rejetées par la banque."
    $ws5.Cells.Item(2, 1).Font.Italic = $true

    $entetes5 = @("Date Gén. Oracle", "Échéance", "IBAN Créancier", "IBAN Débiteur", "RUM",
                  "Nom du Client", "Montant (€)", "Type", "Référence / Lot",
                  "Fichier Source", "Statut", "Code Rejet", "Motif du Rejet")
    $props5 = @('DateEmission', 'Echeance', 'IbanCreancier', 'IbanDebiteur', 'Rum',
                'NomClient', 'Montant', 'TypeDD', 'Reference',
                'FichierSource', 'Statut', 'CodeRejet', 'MotifRejet')

    Set-ColonnesTexte $ws5 @(1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13)

    $n5 = Write-Grille -Feuille $ws5 -LigneEntete 4 -ColDepart 1 -Entetes $entetes5 -Donnees $lignesDetail -Proprietes $props5 -CouleurEntete 0x4F81BD
    Set-FormatColonnes $ws5 5 (4 + $n5) @{ 7 = $fMontant }
    for ($i = 0; $i -lt $n5; $i++) {
        if ($lignesDetail[$i].Statut -eq 'REJETE') {
            $r = $ws5.Range($ws5.Cells.Item(5 + $i, 1), $ws5.Cells.Item(5 + $i, 13))
            $r.Interior.Color = 0xCCCCFF
            $r.Font.Bold = $true
        }
    }
    Set-LargeurColonnes $ws5 @{
        1 = 16; 2 = 12; 3 = 30; 4 = 30; 5 = 38; 6 = 36; 7 = 14; 8 = 7
        9 = 32; 10 = 46; 11 = 10; 12 = 11; 13 = 22
    }
    Enable-Filtre $ws5 4 $n5 $entetes5.Count $excel

    # --- Sauvegarde --------------------------------------------------
    $ws2.Activate()
    if (Test-Path $outputPath) { Remove-Item $outputPath -Force }
    $workbook.SaveAs($outputPath, 51)   # 51 = xlOpenXMLWorkbook (.xlsx)
    # La fermeture du classeur et la sortie d'Excel sont laissees au bloc
    # finally, seul endroit ou l'ordre de liberation COM est garanti.

    # --- Restitution console -----------------------------------------
    Write-Host ''
    Write-Host '=======================================================' -ForegroundColor Green
    Write-Host ' Rapprochement complété avec succès !' -ForegroundColor Green
    Write-Host " Fichier : $(Split-Path $outputPath -Leaf)" -ForegroundColor Yellow
    Write-Host '=======================================================' -ForegroundColor Green
    foreach ($g in ($comparatif | Group-Object Statut | Sort-Object Name)) {
        $couleur = if ($g.Name -eq 'Ecart NON justifie') { 'Red' }
                   elseif ($g.Name -like 'OK*')          { 'Green' }
                   else                                  { 'DarkGray' }
        Write-Host ("  {0,-46} : {1,3}" -f $g.Name, $g.Count) -ForegroundColor $couleur
    }
    foreach ($e in ($comparatif | Where-Object { $_.Statut -eq 'Ecart NON justifie' })) {
        Write-Host ("  -> Échéance {0} : résiduel {1} ligne(s) / {2} EUR" -f `
            $e.Echeance, $e.EcartNbResiduel, $e.EcartMntResiduel) -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur critique : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  à la ligne $($_.InvocationInfo.ScriptLineNumber) : $($_.InvocationInfo.Line.Trim())" -ForegroundColor DarkRed
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    # Liberation COM complete : sans elle, une instance Excel fantome subsiste
    # en tache de fond. L'ordre compte : feuilles, puis classeur, puis Quit,
    # puis l'application. FinalReleaseComObject vide le compteur de references
    # d'un coup, la ou ReleaseComObject ne le decremente que de un.
    foreach ($obj in @($ws5, $ws4, $ws3, $ws2, $ws1)) {
        if ($obj) { try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($obj) } catch { } }
    }
    if ($workbook) {
        try { $workbook.Close($false) } catch { }
        try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($workbook) } catch { }
    }
    if ($excel) {
        try { $excel.Quit() } catch { }
        try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel) } catch { }
    }
    $ws1 = $null; $ws2 = $null; $ws3 = $null; $ws4 = $null; $ws5 = $null
    $workbook = $null; $excel = $null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()

    # Filet de securite : les nombreux objets Range/Font/Interior manipules au
    # fil de la mise en forme laissent parfois une reference COM vivante, et
    # l'instance survit a Quit(). On ne termine que le processus cree par ce
    # script (classeur deja enregistre et ferme) : les classeurs ouverts par
    # l'utilisateur ne sont jamais touches.
    if ($pidExcel) {
        Start-Sleep -Milliseconds 500
        $restant = Get-Process -Id $pidExcel -ErrorAction SilentlyContinue
        if ($restant) {
            try { $restant | Stop-Process -Force -ErrorAction Stop } catch { }
        }
    }
}

if (-not $env:PRELEVEMENTS_NO_PAUSE) {
    Write-Host ''
    Write-Host 'Appuyez sur une touche pour fermer.' -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { }
}
