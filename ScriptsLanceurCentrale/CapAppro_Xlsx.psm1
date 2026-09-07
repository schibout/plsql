<#
    CapAppro_Xlsx.psm1
    Lecture et ecriture de fichiers .xlsx sans dependance externe.

    Un .xlsx est une archive ZIP contenant du XML (format OpenXML). Ce module
    l'exploite directement via System.IO.Compression : ni Excel installe, ni
    module PSGallery, ni Python.

    Compatible Windows PowerShell 5.1.

    Fonctions exportees :
        Read-XlsxSheet      lit un onglet -> tableau de PSCustomObject
        Get-XlsxSheetNames  liste les onglets d'un classeur
        Write-XlsxFile      ecrit un tableau d'objets dans un .xlsx
#>

Set-StrictMode -Version 2.0
Add-Type -AssemblyName System.IO.Compression.FileSystem

# =============================================================================
#   Outils internes
# =============================================================================

function ConvertFrom-ColumnRef {
    <#  "BC12" -> 55  (index de colonne, base 1)  #>
    param([string]$Reference)
    $lettres = $Reference -replace '[^A-Za-z]', ''
    $index = 0
    foreach ($caractere in $lettres.ToUpper().ToCharArray()) {
        $index = $index * 26 + ([int][char]$caractere - 64)
    }
    return $index
}

function Get-ZipEntryXml {
    <#  Extrait une entree de l'archive et la renvoie en XmlDocument.  #>
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$EntryName
    )
    $entree = $Archive.GetEntry($EntryName)
    if ($null -eq $entree) { return $null }

    $flux = $entree.Open()
    try {
        $lecteur = New-Object System.IO.StreamReader($flux, [System.Text.Encoding]::UTF8)
        try {
            $contenu = $lecteur.ReadToEnd()
        } finally {
            $lecteur.Dispose()
        }
    } finally {
        $flux.Dispose()
    }

    $document = New-Object System.Xml.XmlDocument
    $document.PreserveWhitespace = $true
    $document.LoadXml($contenu)
    return $document
}

function Get-SharedStrings {
    <#  Table des chaines partagees : les cellules texte y renvoient par index. #>
    param([System.IO.Compression.ZipArchive]$Archive)

    $chaines = New-Object System.Collections.ArrayList
    $document = Get-ZipEntryXml -Archive $Archive -EntryName 'xl/sharedStrings.xml'
    if ($null -eq $document) { return $chaines }

    foreach ($si in $document.DocumentElement.ChildNodes) {
        # Une chaine peut etre simple (<t>) ou fragmentee en plusieurs
        # sequences mises en forme (<r><t>...</t></r><r><t>...</t></r>).
        $texte = ''
        foreach ($noeud in $si.SelectNodes('.//*[local-name()="t"]')) {
            $texte += $noeud.InnerText
        }
        [void]$chaines.Add($texte)
    }
    return $chaines
}

function Get-DateStyleIds {
    <#  Identifie les styles correspondant a un format de date.

        Une date Excel est stockee comme un nombre : seul le format applique
        permet de la reconnaitre. On collecte les index de style (cellXfs)
        dont le numFmt est un format de date, natif ou personnalise.
    #>
    param([System.IO.Compression.ZipArchive]$Archive)

    $stylesDate = @{}
    $document = Get-ZipEntryXml -Archive $Archive -EntryName 'xl/styles.xml'
    if ($null -eq $document) { return $stylesDate }

    # Formats natifs Excel correspondant a des dates ou des heures
    $formatsNatifs = @(14, 15, 16, 17, 18, 19, 20, 21, 22, 45, 46, 47)

    # Formats personnalises : on considere comme date tout code contenant
    # des jetons de date sans etre un format numerique classique.
    $formatsPersonnalises = @{}
    foreach ($numFmt in $document.SelectNodes('//*[local-name()="numFmt"]')) {
        $code = $numFmt.GetAttribute('formatCode')
        $id = [int]$numFmt.GetAttribute('numFmtId')
        if ($code -match '[dDmMyYhHs]' -and $code -notmatch '^[#0.,%\s]+$') {
            $formatsPersonnalises[$id] = $true
        }
    }

    $cellXfs = $document.SelectSingleNode('//*[local-name()="cellXfs"]')
    if ($null -eq $cellXfs) { return $stylesDate }

    $indexStyle = 0
    foreach ($xf in $cellXfs.ChildNodes) {
        if ($xf.NodeType -ne [System.Xml.XmlNodeType]::Element) { continue }
        $numFmtId = 0
        if ($xf.HasAttribute('numFmtId')) { $numFmtId = [int]$xf.GetAttribute('numFmtId') }
        if ($formatsNatifs -contains $numFmtId -or $formatsPersonnalises.ContainsKey($numFmtId)) {
            $stylesDate[$indexStyle] = $true
        }
        $indexStyle++
    }
    return $stylesDate
}

function Get-SheetPath {
    <#  Chemin interne de l'onglet demande (ou du premier onglet).  #>
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$SheetName
    )

    $workbook = Get-ZipEntryXml -Archive $Archive -EntryName 'xl/workbook.xml'
    if ($null -eq $workbook) { throw "Classeur illisible : xl/workbook.xml absent." }

    $rels = Get-ZipEntryXml -Archive $Archive -EntryName 'xl/_rels/workbook.xml.rels'
    $cibleParId = @{}
    if ($null -ne $rels) {
        foreach ($relation in $rels.DocumentElement.ChildNodes) {
            if ($relation.NodeType -ne [System.Xml.XmlNodeType]::Element) { continue }
            $cibleParId[$relation.GetAttribute('Id')] = $relation.GetAttribute('Target')
        }
    }

    $onglets = $workbook.SelectNodes('//*[local-name()="sheet"]')
    foreach ($onglet in $onglets) {
        $nom = $onglet.GetAttribute('name')
        if ([string]::IsNullOrEmpty($SheetName) -or $nom -eq $SheetName) {
            $identifiant = $onglet.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
            $cible = $cibleParId[$identifiant]
            if ([string]::IsNullOrEmpty($cible)) { $cible = 'worksheets/sheet1.xml' }
            $cible = $cible -replace '^/xl/', '' -replace '^/', ''
            if ($cible -notlike 'xl/*') { $cible = "xl/$cible" }
            return $cible
        }
    }

    $disponibles = ($onglets | ForEach-Object { $_.GetAttribute('name') }) -join ', '
    throw "Onglet '$SheetName' introuvable. Onglets disponibles : $disponibles"
}

# =============================================================================
#   Lecture
# =============================================================================

function Get-XlsxSheetNames {
    param([Parameter(Mandatory = $true)][string]$Path)

    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Path).Path)
    try {
        $workbook = Get-ZipEntryXml -Archive $archive -EntryName 'xl/workbook.xml'
        $noms = @()
        foreach ($onglet in $workbook.SelectNodes('//*[local-name()="sheet"]')) {
            $noms += $onglet.GetAttribute('name')
        }
        return $noms
    } finally {
        $archive.Dispose()
    }
}

function Read-XlsxSheet {
    <#
        .SYNOPSIS
            Lit un onglet .xlsx et renvoie un tableau de PSCustomObject.
        .DESCRIPTION
            La premiere ligne fournit les noms de colonnes. Les cellules vides
            valent $null. Les dates sont converties en [datetime].
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$SheetName
    )

    $cheminComplet = (Resolve-Path -LiteralPath $Path).Path
    $archive = [System.IO.Compression.ZipFile]::OpenRead($cheminComplet)
    try {
        $chainesPartagees = Get-SharedStrings -Archive $archive
        $stylesDate = Get-DateStyleIds -Archive $archive
        $cheminOnglet = Get-SheetPath -Archive $archive -SheetName $SheetName

        $feuille = Get-ZipEntryXml -Archive $archive -EntryName $cheminOnglet
        if ($null -eq $feuille) { throw "Onglet introuvable dans l'archive : $cheminOnglet" }

        $lignes = New-Object System.Collections.ArrayList
        $nbColonnesMax = 0

        foreach ($ligne in $feuille.SelectNodes('//*[local-name()="row"]')) {
            $valeurs = @{}
            foreach ($cellule in $ligne.SelectNodes('./*[local-name()="c"]')) {

                $reference = $cellule.GetAttribute('r')
                $indexColonne = ConvertFrom-ColumnRef -Reference $reference
                if ($indexColonne -gt $nbColonnesMax) { $nbColonnesMax = $indexColonne }

                $type = $cellule.GetAttribute('t')
                $noeudValeur = $cellule.SelectSingleNode('./*[local-name()="v"]')
                $noeudTexte = $cellule.SelectSingleNode('./*[local-name()="is"]')

                $valeur = $null
                if ($type -eq 'inlineStr' -and $null -ne $noeudTexte) {
                    $valeur = $noeudTexte.InnerText
                } elseif ($null -ne $noeudValeur) {
                    $brut = $noeudValeur.InnerText
                    switch ($type) {
                        's' {
                            $indice = [int]$brut
                            if ($indice -lt $chainesPartagees.Count) {
                                $valeur = $chainesPartagees[$indice]
                            }
                        }
                        'b'   { $valeur = ($brut -eq '1') }
                        'str' { $valeur = $brut }
                        'e'   { $valeur = $brut }   # cellule en erreur (#N/A ...)
                        default {
                            # Nombre : peut etre une date selon le style applique
                            $nombre = 0.0
                            $converti = [double]::TryParse(
                                $brut,
                                [System.Globalization.NumberStyles]::Float,
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [ref]$nombre)
                            if (-not $converti) {
                                $valeur = $brut
                            } else {
                                $indexStyle = -1
                                if ($cellule.HasAttribute('s')) {
                                    $indexStyle = [int]$cellule.GetAttribute('s')
                                }
                                if ($stylesDate.ContainsKey($indexStyle) -and $nombre -gt 0) {
                                    $valeur = [datetime]::FromOADate($nombre)
                                } else {
                                    $valeur = $nombre
                                }
                            }
                        }
                    }
                }
                $valeurs[$indexColonne] = $valeur
            }
            [void]$lignes.Add($valeurs)
        }

        if ($lignes.Count -eq 0) { return @() }

        # Premiere ligne = en-tetes
        $entetes = @{}
        $premiereLigne = $lignes[0]
        for ($colonne = 1; $colonne -le $nbColonnesMax; $colonne++) {
            $nom = $null
            if ($premiereLigne.ContainsKey($colonne)) { $nom = $premiereLigne[$colonne] }
            if ($null -eq $nom -or "$nom".Trim() -eq '') { $nom = "Colonne$colonne" }
            $entetes[$colonne] = "$nom".Trim()
        }

        $resultat = New-Object System.Collections.ArrayList
        for ($i = 1; $i -lt $lignes.Count; $i++) {
            $ligne = $lignes[$i]
            $objet = [ordered]@{}
            $ligneVide = $true
            for ($colonne = 1; $colonne -le $nbColonnesMax; $colonne++) {
                $valeur = $null
                if ($ligne.ContainsKey($colonne)) { $valeur = $ligne[$colonne] }
                if ($null -ne $valeur -and "$valeur".Trim() -ne '') { $ligneVide = $false }
                $objet[$entetes[$colonne]] = $valeur
            }
            if (-not $ligneVide) {
                [void]$resultat.Add([PSCustomObject]$objet)
            }
        }
        return $resultat.ToArray()

    } finally {
        $archive.Dispose()
    }
}

# =============================================================================
#   Ecriture
# =============================================================================

function ConvertTo-XmlText {
    param([string]$Texte)
    if ($null -eq $Texte) { return '' }
    # Les caracteres de controle sont interdits dans un document XML.
    $propre = [System.Text.RegularExpressions.Regex]::Replace(
        $Texte, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    return [System.Security.SecurityElement]::Escape($propre)
}

function ConvertTo-ColumnRef {
    param([int]$Index)
    $reference = ''
    while ($Index -gt 0) {
        $reste = ($Index - 1) % 26
        $reference = [char](65 + $reste) + $reference
        $Index = [int](($Index - $reste - 1) / 26)
    }
    return $reference
}

function Write-XlsxFile {
    <#
        .SYNOPSIS
            Ecrit un tableau d'objets dans un fichier .xlsx.
        .DESCRIPTION
            Genere un classeur OpenXML minimal a une feuille. Les nombres
            restent numeriques, les dates sont ecrites au format JJ/MM/AAAA,
            le reste en chaines en ligne.
    #>
    param(
        [Parameter(Mandatory = $true)][object[]]$Data,
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$SheetName = 'Sheet1'
    )

    if ($Data.Count -eq 0) {
        $colonnes = @()
    } else {
        $colonnes = @($Data[0].PSObject.Properties.Name)
    }

    $lignesXml = New-Object System.Text.StringBuilder

    # En-tetes
    [void]$lignesXml.Append('<row r="1">')
    for ($c = 0; $c -lt $colonnes.Count; $c++) {
        $ref = (ConvertTo-ColumnRef -Index ($c + 1)) + '1'
        $texte = ConvertTo-XmlText -Texte $colonnes[$c]
        [void]$lignesXml.Append("<c r=""$ref"" t=""inlineStr"" s=""1""><is><t xml:space=""preserve"">$texte</t></is></c>")
    }
    [void]$lignesXml.Append('</row>')

    # Donnees
    $numeroLigne = 1
    foreach ($enregistrement in $Data) {
        $numeroLigne++
        [void]$lignesXml.Append("<row r=""$numeroLigne"">")
        for ($c = 0; $c -lt $colonnes.Count; $c++) {
            $valeur = $enregistrement.($colonnes[$c])
            if ($null -eq $valeur -or $valeur -is [System.DBNull]) { continue }

            $ref = (ConvertTo-ColumnRef -Index ($c + 1)) + $numeroLigne

            if ($valeur -is [datetime]) {
                $serie = $valeur.ToOADate().ToString([System.Globalization.CultureInfo]::InvariantCulture)
                [void]$lignesXml.Append("<c r=""$ref"" s=""2""><v>$serie</v></c>")
            }
            elseif ($valeur -is [int] -or $valeur -is [long] -or $valeur -is [double] -or
                    $valeur -is [decimal] -or $valeur -is [single]) {
                $nombre = ([double]$valeur).ToString([System.Globalization.CultureInfo]::InvariantCulture)
                [void]$lignesXml.Append("<c r=""$ref""><v>$nombre</v></c>")
            }
            elseif ($valeur -is [bool]) {
                $booleen = 0; if ($valeur) { $booleen = 1 }
                [void]$lignesXml.Append("<c r=""$ref"" t=""b""><v>$booleen</v></c>")
            }
            else {
                $texte = ConvertTo-XmlText -Texte ([string]$valeur)
                [void]$lignesXml.Append("<c r=""$ref"" t=""inlineStr""><is><t xml:space=""preserve"">$texte</t></is></c>")
            }
        }
        [void]$lignesXml.Append('</row>')
    }

    $nomOnglet = ConvertTo-XmlText -Texte $SheetName

    $entrees = @{
        '[Content_Types].xml' = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
'@
        '_rels/.rels' = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
'@
        'xl/_rels/workbook.xml.rels' = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
        'xl/styles.xml' = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="1"><numFmt numFmtId="164" formatCode="DD/MM/YYYY"/></numFmts>
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
</cellXfs>
</styleSheet>
'@
        'xl/workbook.xml' = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="$nomOnglet" sheetId="1" r:id="rId1"/></sheets>
</workbook>
"@
        'xl/worksheets/sheet1.xml' = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>$($lignesXml.ToString())</sheetData>
</worksheet>
"@
    }

    $dossier = Split-Path -Parent $Path
    if ($dossier -and -not (Test-Path $dossier)) {
        New-Item -ItemType Directory -Force -Path $dossier | Out-Null
    }
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }

    $archive = [System.IO.Compression.ZipFile]::Open($Path, 'Create')
    try {
        $encodage = New-Object System.Text.UTF8Encoding($false)
        foreach ($nomEntree in $entrees.Keys) {
            $entree = $archive.CreateEntry($nomEntree)
            $flux = $entree.Open()
            try {
                $octets = $encodage.GetBytes($entrees[$nomEntree].Trim())
                $flux.Write($octets, 0, $octets.Length)
            } finally {
                $flux.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
}

Export-ModuleMember -Function Read-XlsxSheet, Get-XlsxSheetNames, Write-XlsxFile
