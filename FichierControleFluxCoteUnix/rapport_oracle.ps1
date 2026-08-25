# =====================================================================
#  rapport_oracle.ps1 - Restitution des interrogations Oracle
# =====================================================================
#  Fonction commune aux scripts Verifier_Oracle_*.ps1 : les resultats des
#  interrogations Oracle sont ajoutes comme onglets au classeur de synthese
#  produit juste avant par le controle local (ctl_*.py), au lieu de faire
#  l'objet d'un second classeur.
#
#  L'ecriture passe par rapport_excel.py (openpyxl) et non par
#  l'automatisation COM : le rapport est donc produit meme quand Excel n'est
#  pas installe sur le poste, ce qui rend inutile l'ancien repli en CSV.
# =====================================================================

function Export-OngletsOracle {
    <#
        Ajoute des onglets au classeur de synthese du flux.
        -Src      : fichier SRC controle (sert a retrouver le classeur)
        -Prefixe  : prefixe du classeur (ex. FAC02_SYNTHESE_FOURNISSEURS)
        -Onglets  : tableau de hashtables { nom; titre; sous_titre; colonnes;
                    colonne_statut; valeurs_ok; lignes }
        Renvoie le chemin du classeur, ou $null si l'ajout a echoue.
    #>
    param(
        [Parameter(Mandatory = $true)] [string] $Src,
        [Parameter(Mandatory = $true)] [string] $Prefixe,
        [Parameter(Mandatory = $true)] [object[]] $Onglets,
        [string] $DossierTravail
    )

    $racine = if ($DossierTravail) { $DossierTravail } else { Split-Path -Parent $PSCommandPath }
    $script = Join-Path $racine 'rapport_excel.py'
    if (-not (Test-Path -LiteralPath $script)) {
        Write-Host "   [ATTENTION] $script introuvable : onglets Oracle non ajoutes." -ForegroundColor Yellow
        return $null
    }

    $descriptif = [ordered]@{
        src     = $Src
        prefixe = $Prefixe
        onglets = $Onglets
    }
    # Depth eleve : les lignes sont des objets imbriques dans les onglets.
    $json = $descriptif | ConvertTo-Json -Depth 8
    $fichierJson = Join-Path ([System.IO.Path]::GetTempPath()) ("onglets_oracle_" + [System.Guid]::NewGuid().ToString('N') + '.json')
    [System.IO.File]::WriteAllText($fichierJson, $json, (New-Object System.Text.UTF8Encoding $false))

    # Start-Process plutot que "& python ... 2>&1" : sous Windows PowerShell 5.1,
    # rediriger la sortie d'erreur d'un executable natif produit un
    # NativeCommandError qui, avec $ErrorActionPreference = 'Stop', interrompt
    # le script appelant et masque le vrai message.
    $sortieTmp = "$fichierJson.out"
    $erreurTmp = "$fichierJson.err"
    try {
        $process = Start-Process -FilePath 'python' -ArgumentList @($script, $fichierJson) `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $sortieTmp -RedirectStandardError $erreurTmp
        $sortie = @(if (Test-Path -LiteralPath $sortieTmp) { Get-Content -LiteralPath $sortieTmp })
        if ($process.ExitCode -ne 0) {
            Write-Host '   [ATTENTION] Onglets Oracle non ajoutes au classeur de synthese :' -ForegroundColor Yellow
            @(if (Test-Path -LiteralPath $erreurTmp) { Get-Content -LiteralPath $erreurTmp }) +
                $sortie | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }
            return $null
        }
        return ($sortie | Select-Object -Last 1)
    } finally {
        Remove-Item -LiteralPath $fichierJson, $sortieTmp, $erreurTmp -ErrorAction SilentlyContinue
    }
}

function ConvertTo-LignesOnglet {
    <#
        Transforme des PSCustomObject en hashtables ordonnees serialisables,
        en ne retenant que les colonnes demandees et dans leur ordre.
    #>
    param([object[]] $Donnees, [string[]] $Colonnes)
    $lignes = @()
    foreach ($d in @($Donnees)) {
        $ligne = [ordered]@{}
        foreach ($c in $Colonnes) {
            # Une propriete issue d'un "$(if (...) { ... })" sans branche prise
            # vaut AutomationNull, que ConvertTo-Json serialise en {} et non en
            # null : la cellule Excel serait alors refusee. On force le $null.
            if ($null -eq $d.$c) { $ligne[$c] = $null } else { $ligne[$c] = $d.$c }
        }
        $lignes += $ligne
    }
    return , $lignes
}
