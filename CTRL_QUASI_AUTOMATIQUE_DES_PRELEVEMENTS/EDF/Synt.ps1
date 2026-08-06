# Configuration du chemin de traitement
$baseDir = "C:\Users\ljove\Documents\DATA\RUN"
$targetPath = "$baseDir\20260706\Prélèvements\EDF"

# Vérification si le dossier existe
if (-not (Test-Path $targetPath)) {
    Write-Error "Le dossier spécifié n'existe pas : $targetPath"
    exit
}

# Récupération de tous les fichiers CSV correspondant à la nomenclature
$files = Get-ChildItem -Path $targetPath -Filter "IMPORT_AVP_DK.*.*.csv"

$synthese_globale = @()

foreach ($file in $files) {
    # Extraction de la date à partir du nom du fichier
    $dateFichier = $file.Name.Split('.')[1]

    # Import du fichier CSV (sans entête)
    $csvData = Import-Csv -Path $file.FullName -Header "ColA", "ColB", "ColC", "ColD", "ColE" -Delimiter ";"

    # Initialisation des compteurs ORACLE
    $oracleNb = 0
    $oracleMontant = 0.0

    foreach ($row in $csvData) {
        # Filtration stricte sur ORACLE
        if ($row.ColA -eq "ORACLE") {
            # Conversion des données numériques
            $nb = [int]$row.ColD
            $montant = [double]($row.ColE -replace ',', '.')

            $oracleNb += $nb
            $oracleMontant += $montant
        }
    }

    # Ajout au tableau global
    $synthese_globale += [PSCustomObject]@{
        Date           = $dateFichier
        Oracle_Nombre  = $oracleNb
        Oracle_Montant = [math]::Round($oracleMontant, 2)
    }
}

# --- Affichage du résultat ---
# Regroupement final par jour (fusion si plusieurs fichiers le même jour)
$syntheseJournaliere = $synthese_globale | Group-Object Date | ForEach-Object {
    [PSCustomObject]@{
        "Date Prélèvement"  = $_.Name
        "Nombre Total (ORACLE)" = ($_.Group | Measure-Object Oracle_Nombre -Sum).Sum
        "Montant Total (€)"     = [math]::Round(($_.Group | Measure-Object Oracle_Montant -Sum).Sum, 2)
    }
}

# Affichage propre dans la console
Write-Host "`n--- SYNTHESE DES PRELEVEMENTS ORACLE ---" -ForegroundColor Cyan
$syntheseJournaliere | Format-Table -AutoSize