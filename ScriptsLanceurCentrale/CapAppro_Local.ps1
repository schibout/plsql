<#
.SYNOPSIS
    Extracteur CapAppro natif PowerShell - execution locale sans Python.

.DESCRIPTION
    Rejoue en local l'extraction d'un projet CapAppro, a partir de son IdExec.

    PERIMETRE - ce script ne remplace PAS la chaine de production :

        Fait                             Ne fait pas
        ---------------------------      ------------------------------------
        Lecture du classeur              Telechargement depuis Google Drive
          d'ordonnancement (local)         (OAuth, librairie maison gdrive)
        Lecture du classeur lanceur      Upload des resultats sur le Drive
        Execution des requetes Oracle    Envoi des mails de restitution
        Export CSV / XLSX en local       Mise a jour de l'onglet HistoExec
        Execution des scripts PL/SQL     Copie vers le partage DataViz
          via sqlplus

    Les fichiers .sql et le classeur lanceur doivent donc etre presents
    localement, dans le dossier de travail (voir [powershell] DOSSIER_TRAVAIL).

.PARAMETER IdExec
    Identifiant de la ligne a executer, tel qu'il figure dans le classeur
    d'ordonnancement. Plusieurs valeurs possibles, separees par des virgules.

.PARAMETER List
    Affiche les lignes disponibles et sort.

.PARAMETER DryRun
    Affiche ce qui serait execute, sans se connecter a la base.

.EXAMPLE
    .\CapAppro_Local.ps1 -List
.EXAMPLE
    .\CapAppro_Local.ps1 39 -DryRun
.EXAMPLE
    .\CapAppro_Local.ps1 39
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$IdExec,
    [switch]$List,
    [switch]$DryRun,
    [string]$ConfigFile
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$DOSSIER_SCRIPT = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $DOSSIER_SCRIPT 'CapAppro_Xlsx.psm1') -Force

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Console non redirigeable (ISE, hote non interactif) : sans consequence.
}

# =============================================================================
#   JOURNALISATION
# =============================================================================

function Write-Log {
    param([string]$Message, [string]$Niveau = 'INFO')
    $horodatage = (Get-Date).ToString('HH:mm:ss')
    $ligne = "$horodatage [$Niveau] $Message"
    switch ($Niveau) {
        'ERROR' { Write-Host $ligne -ForegroundColor Red }
        'WARN'  { Write-Host $ligne -ForegroundColor Yellow }
        'OK'    { Write-Host $ligne -ForegroundColor Green }
        default { Write-Host $ligne }
    }
}

function Write-LogSection {
    param([string]$Titre)
    Write-Log ('=' * 70)
    Write-Log $Titre
    Write-Log ('=' * 70)
}

function Start-Etape {
    param([string]$Libelle)
    Write-Log ">>> DEBUT  $Libelle"
    return [datetime]::Now
}

function Stop-Etape {
    param([string]$Libelle, [datetime]$Debut, [string]$Statut = 'OK')
    $duree = ([datetime]::Now - $Debut).ToString('hh\:mm\:ss')
    $niveau = 'INFO'; if ($Statut -ne 'OK') { $niveau = 'ERROR' }
    Write-Log "<<< FIN    $Libelle | statut=$Statut | duree=$duree" $niveau
    return $duree
}

# =============================================================================
#   CONFIGURATION (.ini)
# =============================================================================

function Get-IniContent {
    param([string]$Path)

    $config = @{}
    $sectionCourante = ''
    foreach ($ligne in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        $texte = $ligne.Trim()
        if ($texte -eq '' -or $texte.StartsWith('#') -or $texte.StartsWith(';')) { continue }
        if ($texte -match '^\[(.+)\]$') {
            $sectionCourante = $Matches[1].Trim()
            if (-not $config.ContainsKey($sectionCourante)) { $config[$sectionCourante] = @{} }
            continue
        }
        $separateur = $texte.IndexOf('=')
        if ($separateur -lt 1 -or $sectionCourante -eq '') { continue }
        $cle = $texte.Substring(0, $separateur).Trim()
        $valeur = $texte.Substring($separateur + 1).Trim()
        $config[$sectionCourante][$cle] = $valeur
    }
    return $config
}

function Resolve-IniValue {
    <#  Interpolation ${CLE} (meme section) et ${section:CLE}, comme le fait
        ExtendedInterpolation cote Python.  #>
    param([hashtable]$Config, [string]$Section, [string]$Valeur, [int]$Profondeur = 0)

    if ($Profondeur -gt 8 -or [string]::IsNullOrEmpty($Valeur)) { return $Valeur }

    $resultat = [regex]::Replace($Valeur, '\$\{([^}]+)\}', {
        param($correspondance)
        $reference = $correspondance.Groups[1].Value
        if ($reference.Contains(':')) {
            $morceaux = $reference.Split(':', 2)
            $sectionCible = $morceaux[0]; $cleCible = $morceaux[1]
        } else {
            $sectionCible = $Section; $cleCible = $reference
        }
        if ($Config.ContainsKey($sectionCible) -and $Config[$sectionCible].ContainsKey($cleCible)) {
            return $Config[$sectionCible][$cleCible]
        }
        return ''
    })

    if ($resultat -ne $Valeur) {
        return Resolve-IniValue -Config $Config -Section $Section -Valeur $resultat -Profondeur ($Profondeur + 1)
    }
    return $resultat
}

function Get-ConfigValue {
    <#  Lit une cle, avec surcharge par variable d'environnement
        CAPAPPRO_<SECTION>_<CLE> (meme convention que la version Python).  #>
    param([string]$Section, [string]$Cle, [string]$Defaut = $null)

    $nomVariable = ("CAPAPPRO_{0}_{1}" -f $Section, $Cle).ToUpper()
    $surcharge = [Environment]::GetEnvironmentVariable($nomVariable)
    if (-not [string]::IsNullOrEmpty($surcharge)) { return $surcharge }

    if ($script:Config.ContainsKey($Section) -and $script:Config[$Section].ContainsKey($Cle)) {
        return Resolve-IniValue -Config $script:Config -Section $Section -Valeur $script:Config[$Section][$Cle]
    }
    if ($null -ne $Defaut) { return $Defaut }
    throw "Clé de configuration manquante : [$Section] $Cle"
}

function Get-ConfigFolder {
    param([string]$Section, [string]$Cle, [string]$Defaut = $null)
    $valeur = Get-ConfigValue -Section $Section -Cle $Cle -Defaut $Defaut
    if ([string]::IsNullOrEmpty($valeur)) { return '' }
    if (-not $valeur.EndsWith('\') -and -not $valeur.EndsWith('/')) { $valeur += '\' }
    return $valeur
}

# =============================================================================
#   CONNEXION ORACLE
# =============================================================================

function Find-OdpManagedAssembly {
    <#  Localise Oracle.ManagedDataAccess.dll : c'est le seul mode qui ne
        reclame aucun client Oracle installe.  #>
    param([string]$CheminExplicite, [string]$OracleHome)

    $candidats = New-Object System.Collections.ArrayList
    if (-not [string]::IsNullOrEmpty($CheminExplicite)) { [void]$candidats.Add($CheminExplicite) }
    [void]$candidats.Add((Join-Path $DOSSIER_SCRIPT 'Oracle.ManagedDataAccess.dll'))
    [void]$candidats.Add((Join-Path $DOSSIER_SCRIPT 'lib\Oracle.ManagedDataAccess.dll'))
    if (-not [string]::IsNullOrEmpty($OracleHome)) {
        [void]$candidats.Add((Join-Path $OracleHome 'odp.net\managed\common\Oracle.ManagedDataAccess.dll'))
    }
    foreach ($candidat in $candidats) {
        if ((-not [string]::IsNullOrEmpty($candidat)) -and (Test-Path -LiteralPath $candidat)) {
            return (Resolve-Path -LiteralPath $candidat).Path
        }
    }
    return $null
}

function Test-OleDbProvider {
    param([string]$Nom)
    try {
        $enumerateur = New-Object System.Data.OleDb.OleDbEnumerator
        foreach ($ligne in $enumerateur.GetElements()) {
            if ($ligne.SOURCES_NAME -eq $Nom) { return $true }
        }
    } catch { }
    return $false
}

function Get-OdbcOracleDriver {
    try {
        $cle = 'HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers'
        if (Test-Path $cle) {
            $pilotes = Get-ItemProperty -Path $cle
            foreach ($nom in $pilotes.PSObject.Properties.Name) {
                if ($nom -like '*Oracle*') { return $nom }
            }
        }
    } catch { }
    return $null
}

function New-OracleConnection {
    <#  Ouvre une connexion Oracle avec le premier fournisseur disponible.
        Retourne un objet portant la connexion et le nom du fournisseur.  #>
    param([hashtable]$Bdd, [string]$Fournisseur, [string]$DllManagee, [string]$OracleHome)

    # Descripteur TNS complet plutot qu'une chaine EZConnect (//host:port/service) :
    # cette derniere depend d'un fichier sqlnet.ora correctement configure et
    # echoue sinon en ORA-12154.
    $source = "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST={0})(PORT={1}))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME={2})))" -f `
        $Bdd.BASE_URL, $Bdd.BASE_PORT, $Bdd.BASE_SERVICE_NAME
    $ordre = @($Fournisseur)
    if ($Fournisseur -eq 'auto') { $ordre = @('managed', 'oledb', 'odbc') }

    $echecs = New-Object System.Collections.ArrayList

    foreach ($mode in $ordre) {
        try {
            switch ($mode) {
                'managed' {
                    $dll = Find-OdpManagedAssembly -CheminExplicite $DllManagee -OracleHome $OracleHome
                    if ($null -eq $dll) {
                        [void]$echecs.Add("managed : Oracle.ManagedDataAccess.dll introuvable")
                        continue
                    }
                    Add-Type -Path $dll
                    $chaine = "User Id={0};Password={1};Data Source={2};" -f `
                        $Bdd.DB_USER, $Bdd.DB_PASSWORD, $source
                    $connexion = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($chaine)
                    $connexion.Open()
                    return [PSCustomObject]@{ Connexion = $connexion; Fournisseur = "ODP.NET managé ($dll)" }
                }
                'oledb' {
                    if (-not (Test-OleDbProvider -Nom 'OraOLEDB.Oracle')) {
                        [void]$echecs.Add("oledb : fournisseur OraOLEDB.Oracle non enregistré")
                        continue
                    }
                    $chaine = "Provider=OraOLEDB.Oracle;Data Source={0};User Id={1};Password={2};" -f `
                        $source, $Bdd.DB_USER, $Bdd.DB_PASSWORD
                    $connexion = New-Object System.Data.OleDb.OleDbConnection($chaine)
                    $connexion.Open()
                    return [PSCustomObject]@{ Connexion = $connexion; Fournisseur = 'OLE DB (OraOLEDB.Oracle)' }
                }
                'odbc' {
                    $pilote = Get-OdbcOracleDriver
                    if ($null -eq $pilote) {
                        [void]$echecs.Add("odbc : aucun pilote ODBC Oracle installé")
                        continue
                    }
                    $chaine = "Driver={{{0}}};Dbq={1}:{2}/{3};Uid={4};Pwd={5};" -f `
                        $pilote, $Bdd.BASE_URL, $Bdd.BASE_PORT, $Bdd.BASE_SERVICE_NAME,
                        $Bdd.DB_USER, $Bdd.DB_PASSWORD
                    $connexion = New-Object System.Data.Odbc.OdbcConnection($chaine)
                    $connexion.Open()
                    return [PSCustomObject]@{ Connexion = $connexion; Fournisseur = "ODBC ($pilote)" }
                }
                default { throw "Fournisseur Oracle inconnu : '$mode'" }
            }
        } catch {
            [void]$echecs.Add("$mode : $($_.Exception.Message)")
        }
    }

    throw ("Aucune connexion Oracle possible.`n  " + ($echecs -join "`n  ") +
           "`n`nPour le mode 'managed', deposer Oracle.ManagedDataAccess.dll a cote du script" +
           "`n(paquet NuGet Oracle.ManagedDataAccess) : c'est le seul mode sans client Oracle.")
}

function Invoke-OracleQuery {
    param($Connexion, [string]$Requete, [int]$TimeoutSecondes)

    $commande = $Connexion.CreateCommand()
    try {
        $commande.CommandText = $Requete
        $commande.CommandTimeout = $TimeoutSecondes
        $lecteur = $commande.ExecuteReader()
        try {
            $table = New-Object System.Data.DataTable
            $table.Load($lecteur)
            return $table
        } finally {
            $lecteur.Dispose()
        }
    } finally {
        $commande.Dispose()
    }
}

# =============================================================================
#   EXPORTS
# =============================================================================

function Format-CsvField {
    <#  Reproduit le format produit cote Python :
        pandas.to_csv(sep=';', quoting=QUOTE_NONNUMERIC,
                      encoding='utf-8-sig',
                      date_format='%d/%m/%Y %H:%M:%S', float_format='%.5f')
        -> tout ce qui n'est pas numerique est entoure de guillemets,
           les valeurs nulles sont ecrites vides.  #>
    param($Valeur)

    if ($null -eq $Valeur -or $Valeur -is [System.DBNull]) { return '' }

    $invariant = [System.Globalization.CultureInfo]::InvariantCulture

    if ($Valeur -is [double] -or $Valeur -is [single] -or $Valeur -is [decimal]) {
        return ([double]$Valeur).ToString('0.00000', $invariant)
    }
    if ($Valeur -is [int] -or $Valeur -is [long] -or $Valeur -is [int16] -or
        $Valeur -is [byte] -or $Valeur -is [uint32] -or $Valeur -is [uint64]) {
        return $Valeur.ToString($invariant)
    }
    if ($Valeur -is [datetime]) {
        return '"' + $Valeur.ToString('dd/MM/yyyy HH:mm:ss') + '"'
    }

    $texte = [string]$Valeur
    return '"' + $texte.Replace('"', '""') + '"'
}

function Export-TableToCsv {
    param([System.Data.DataTable]$Table, [string]$Chemin)

    $encodage = New-Object System.Text.UTF8Encoding($true)   # avec BOM (utf-8-sig)
    $ecrivain = New-Object System.IO.StreamWriter($Chemin, $false, $encodage)
    try {
        $entetes = @()
        foreach ($colonne in $Table.Columns) { $entetes += '"' + $colonne.ColumnName.Replace('"', '""') + '"' }
        $ecrivain.WriteLine($entetes -join ';')

        foreach ($ligne in $Table.Rows) {
            $champs = @()
            foreach ($colonne in $Table.Columns) {
                $champs += Format-CsvField -Valeur $ligne[$colonne]
            }
            $ecrivain.WriteLine($champs -join ';')
        }
    } finally {
        $ecrivain.Dispose()
    }
}

function Export-TableToXlsx {
    param([System.Data.DataTable]$Table, [string]$Chemin)

    $objets = New-Object System.Collections.ArrayList
    foreach ($ligne in $Table.Rows) {
        $objet = [ordered]@{}
        foreach ($colonne in $Table.Columns) {
            $valeur = $ligne[$colonne]
            if ($valeur -is [System.DBNull]) { $valeur = $null }
            $objet[$colonne.ColumnName] = $valeur
        }
        [void]$objets.Add([PSCustomObject]$objet)
    }

    if ($objets.Count -eq 0) {
        # Classeur a une seule ligne d'en-tetes, pour rester coherent avec
        # le comportement de pandas sur un resultat vide.
        $vide = [ordered]@{}
        foreach ($colonne in $Table.Columns) { $vide[$colonne.ColumnName] = $null }
        [void]$objets.Add([PSCustomObject]$vide)
    }

    Write-XlsxFile -Data $objets.ToArray() -Path $Chemin -SheetName 'Sheet1'
}

function Add-Horodatage {
    <#  'DDMMYYYY' -> 'Fichier_04092026.csv'  (meme conversion que cote Python) #>
    param([string]$NomFichier, [string]$Format)

    $formatNet = $Format.Replace('DD', 'dd').Replace('YYYY', 'yyyy').Replace('YY', 'yy')
    $horodatage = (Get-Date).ToString($formatNet)
    $sansExtension = [System.IO.Path]::GetFileNameWithoutExtension($NomFichier)
    $extension = [System.IO.Path]::GetExtension($NomFichier)
    return "${sansExtension}_${horodatage}${extension}"
}

# =============================================================================
#   SCRIPTS PL/SQL (sqlplus)
# =============================================================================

function Invoke-SqlplusScript {
    param(
        [string]$FichierSql,
        [hashtable]$Bdd,
        [string]$OracleHome,
        [string]$DossierSortie,
        [string]$MessageOkFr,
        [string]$MessageOkEn
    )

    $sqlplus = Join-Path $OracleHome 'bin\sqlplus.exe'
    if (-not (Test-Path -LiteralPath $sqlplus)) {
        $sqlplus = 'sqlplus.exe'   # tenter le PATH
    }

    $nomBase = [System.IO.Path]::GetFileNameWithoutExtension($FichierSql)
    $fichierSortie = Join-Path $DossierSortie "$nomBase.txt"

    $connexion = "{0}/{1}@{2}:{3}/{4}" -f `
        $Bdd.DB_USER, $Bdd.DB_PASSWORD, $Bdd.BASE_URL, $Bdd.BASE_PORT, $Bdd.BASE_SERVICE_NAME

    $processus = Start-Process -FilePath $sqlplus `
        -ArgumentList @($connexion, "@`"$FichierSql`"") `
        -RedirectStandardOutput $fichierSortie `
        -NoNewWindow -Wait -PassThru

    $contenu = ''
    if (Test-Path -LiteralPath $fichierSortie) {
        $contenu = Get-Content -LiteralPath $fichierSortie -Raw -ErrorAction SilentlyContinue
    }
    if ($null -eq $contenu) { $contenu = '' }

    $succes = ($processus.ExitCode -eq 0) -and
              ($contenu.Contains($MessageOkFr) -or $contenu.Contains($MessageOkEn))

    return [PSCustomObject]@{
        Succes    = $succes
        CodeSortie = $processus.ExitCode
        Sortie    = $contenu
        Fichier   = $fichierSortie
    }
}

# =============================================================================
#   PROGRAMME PRINCIPAL
# =============================================================================

function Invoke-Projet {
    param($Ligne, [hashtable]$Parametres)

    $nomProjet = [string]$Ligne.ProjectName
    $configBdd = [string]$Ligne.config

    $dossierProjet = Join-Path $Parametres.DossierTravail $nomProjet
    $dossierSortie = Join-Path $dossierProjet 'extractFiles'
    $classeurLanceur = Join-Path $dossierProjet ([string]$Ligne.filenameLanceur)

    Write-Log "Dossier de travail  : $dossierProjet"
    Write-Log "Classeur lanceur    : $(Split-Path -Leaf $classeurLanceur)"
    Write-Log "Configuration BDD   : $configBdd"

    if (-not (Test-Path -LiteralPath $classeurLanceur)) {
        throw ("Classeur lanceur introuvable : $classeurLanceur`n" +
               "Le Drive n'est pas accessible en natif : y déposer manuellement " +
               "le classeur du projet et ses fichiers .sql.")
    }
    if (-not (Test-Path -LiteralPath $dossierSortie)) {
        New-Item -ItemType Directory -Force -Path $dossierSortie | Out-Null
    }

    # --- Lignes de requetes a traiter ----------------------------------------
    $onglets = Get-XlsxSheetNames -Path $classeurLanceur
    $requetes = Read-XlsxSheet -Path $classeurLanceur -SheetName $onglets[0]
    $aTraiter = @($requetes | Where-Object {
        $null -ne $_.'Exécution' -and ([string]$_.'Exécution').ToLower() -eq 'oui'
    })
    Write-Log "Lignes actives dans le classeur lanceur : $($aTraiter.Count) / $($requetes.Count)"

    if ($aTraiter.Count -eq 0) { return @() }

    # --- Connexion -----------------------------------------------------------
    $bdd = $Parametres.Bases[$configBdd]
    if ($null -eq $bdd) {
        throw ("Section de base de données absente du fichier de configuration : [$configBdd]")
    }

    $connexionInfo = $null
    if (-not $Parametres.DryRun) {
        $connexionInfo = New-OracleConnection -Bdd $bdd `
            -Fournisseur $Parametres.FournisseurOracle `
            -DllManagee $Parametres.DllManagee `
            -OracleHome $Parametres.OracleHome
        Write-Log "Connexion établie via $($connexionInfo.Fournisseur)" 'OK'
    }

    $resultats = New-Object System.Collections.ArrayList
    $numero = 0
    $total = $aTraiter.Count

    try {
        foreach ($requete in $aTraiter) {
            $numero++
            $nomRequete = [string]$requete.'Nom rêquete'
            $type = ([string]$requete.'Type rêquete').ToLower()
            $libelle = "[$numero/$total] $($type.ToUpper()) :: $nomRequete"

            $debut = Start-Etape $libelle
            $statut = 'OK'
            $fichierProduit = ''
            $nbLignes = 0

            try {
                $fichierSql = Join-Path $dossierProjet $nomRequete
                if (-not (Test-Path -LiteralPath $fichierSql)) {
                    throw "Fichier SQL introuvable : $fichierSql"
                }

                if ($type -eq 'script') {
                    if ($Parametres.DryRun) {
                        Write-Log "[DRY-RUN] sqlplus @$nomRequete"
                    } else {
                        $execution = Invoke-SqlplusScript -FichierSql $fichierSql -Bdd $bdd `
                            -OracleHome $Parametres.OracleHome -DossierSortie $dossierSortie `
                            -MessageOkFr $Parametres.MessageOkFr -MessageOkEn $Parametres.MessageOkEn
                        $fichierProduit = $execution.Fichier
                        if (-not $execution.Succes) {
                            $statut = 'KO'
                            Write-Log ("Procédure en échec (code $($execution.CodeSortie)). " +
                                       "Sortie sqlplus : $($execution.Fichier)") 'ERROR'
                        }
                    }
                }
                elseif ($type -eq 'export') {
                    $nomSortie = [string]$requete.'Nom fichier sortie'
                    $formatHorodatage = ''
                    if ($null -ne $requete.formatHorodatage) {
                        $formatHorodatage = ([string]$requete.formatHorodatage).Trim()
                    }
                    if ($formatHorodatage -ne '') {
                        $nomSortie = Add-Horodatage -NomFichier $nomSortie -Format $formatHorodatage
                    }
                    $extension = [System.IO.Path]::GetExtension($nomSortie).TrimStart('.').ToLower()
                    $fichierProduit = Join-Path $dossierSortie $nomSortie

                    if ($Parametres.DryRun) {
                        Write-Log "[DRY-RUN] $nomRequete -> $nomSortie"
                    } else {
                        # Le ';' finalest retire, comme cote Python. Contrairement
                        # a la version Python, seul le ';' terminal est supprime :
                        # ceux situes dans des litteraux sont preserves.
                        $sql = (Get-Content -LiteralPath $fichierSql -Raw)
                        $sql = [regex]::Replace($sql, ';\s*$', '')

                        $table = Invoke-OracleQuery -Connexion $connexionInfo.Connexion `
                            -Requete $sql -TimeoutSecondes $Parametres.TimeoutRequete
                        $nbLignes = $table.Rows.Count
                        Write-Log "Résultat : $nbLignes ligne(s) x $($table.Columns.Count) colonne(s)"

                        switch ($extension) {
                            'csv'  { Export-TableToCsv  -Table $table -Chemin $fichierProduit }
                            'xlsx' { Export-TableToXlsx -Table $table -Chemin $fichierProduit }
                            default {
                                $statut = 'KO'
                                throw "Extension de sortie non reconnue ('$extension'), attendu csv ou xlsx."
                            }
                        }
                        Write-Log "Écrit : $fichierProduit"
                    }
                }
                else {
                    $statut = 'KO'
                    throw "Type de requête inconnu : '$type' (attendu Script ou Export)."
                }
            }
            catch {
                $statut = 'KO'
                Write-Log "Erreur sur $libelle : $($_.Exception.Message)" 'ERROR'
            }
            finally {
                $duree = Stop-Etape $libelle $debut $statut
                [void]$resultats.Add([PSCustomObject]@{
                    Requete = $nomRequete
                    Type    = $type
                    Statut  = $statut
                    Lignes  = $nbLignes
                    Duree   = $duree
                    Fichier = $fichierProduit
                })
            }
        }
    }
    finally {
        if ($null -ne $connexionInfo) {
            $connexionInfo.Connexion.Close()
            $connexionInfo.Connexion.Dispose()
        }
    }

    return $resultats.ToArray()
}

function Main {
    # --- Configuration -------------------------------------------------------
    $cheminIni = $ConfigFile
    if ([string]::IsNullOrEmpty($cheminIni)) {
        $cheminIni = [Environment]::GetEnvironmentVariable('CAPAPPRO_CONFIG')
    }
    if ([string]::IsNullOrEmpty($cheminIni)) {
        $cheminIni = Join-Path $DOSSIER_SCRIPT 'config_lanceur_central.ini'
    }
    if (-not (Test-Path -LiteralPath $cheminIni)) {
        Write-Log "Fichier de configuration introuvable : $cheminIni" 'ERROR'
        return 2
    }
    $script:Config = Get-IniContent -Path $cheminIni
    Write-Log "Configuration chargée depuis $cheminIni"

    $dossierTravail = Get-ConfigFolder 'powershell' 'DOSSIER_TRAVAIL' 'C:\Temp\CapAppro\'
    $classeurOrdonnanceur = Get-ConfigValue 'local' 'FICHIER_ORDONNANCEUR' ''
    $ongletOrdonnanceur = Get-ConfigValue 'local' 'ONGLET_ORDONNANCEUR' 'Feuil1'

    if ([string]::IsNullOrEmpty($classeurOrdonnanceur)) {
        Write-Log "Aucun classeur d'ordonnancement configuré ([local] FICHIER_ORDONNANCEUR)." 'ERROR'
        return 2
    }
    if (-not [System.IO.Path]::IsPathRooted($classeurOrdonnanceur)) {
        $classeurOrdonnanceur = Join-Path $DOSSIER_SCRIPT $classeurOrdonnanceur
    }
    if (-not (Test-Path -LiteralPath $classeurOrdonnanceur)) {
        Write-Log "Classeur d'ordonnancement introuvable : $classeurOrdonnanceur" 'ERROR'
        return 2
    }

    # --- Plan d'execution ----------------------------------------------------
    Write-Log "Lecture du plan d'exécution : $classeurOrdonnanceur (onglet '$ongletOrdonnanceur')"
    $plan = @(Read-XlsxSheet -Path $classeurOrdonnanceur -SheetName $ongletOrdonnanceur |
              Where-Object { $null -ne $_.IdExec -and "$($_.IdExec)".Trim() -ne '' })
    Write-Log "Plan d'exécution chargé : $($plan.Count) ligne(s)"

    if ($List -or $null -eq $IdExec -or $IdExec.Count -eq 0) {
        Write-LogSection "LIGNES DISPONIBLES"
        foreach ($ligne in $plan) {
            Write-Log ("  {0,-5} {1,-8} {2,-45} {3}" -f `
                [int]$ligne.IdExec, ([string]$ligne.'Exécution').ToLower(),
                ([string]$ligne.ProjectName), ([string]$ligne.config))
        }
        if ($null -eq $IdExec -or $IdExec.Count -eq 0) {
            Write-Log "Aucun IdExec fourni. Exemple : .\CapAppro_Local.ps1 39 -DryRun" 'WARN'
        }
        return 0
    }

    # --- Selection -----------------------------------------------------------
    $identifiants = New-Object System.Collections.ArrayList
    foreach ($element in $IdExec) {
        foreach ($morceau in ($element -split ',')) {
            $texte = $morceau.Trim()
            if ($texte -eq '') { continue }
            $nombre = 0
            if (-not [int]::TryParse($texte, [ref]$nombre)) {
                Write-Log "Identifiant d'exécution invalide : '$texte'" 'ERROR'
                return 2
            }
            [void]$identifiants.Add($nombre)
        }
    }

    $selection = @($plan | Where-Object { $identifiants -contains [int]$_.IdExec })
    $introuvables = @($identifiants | Where-Object { $id = $_; -not ($plan | Where-Object { [int]$_.IdExec -eq $id }) })
    if ($introuvables.Count -gt 0) {
        Write-Log "IdExec introuvable(s) : $($introuvables -join ', ')" 'ERROR'
        return 2
    }

    # --- Parametres communs --------------------------------------------------
    $bases = @{}
    foreach ($section in $script:Config.Keys) {
        if ($section -like 'config_*') {
            $bases[$section] = @{}
            foreach ($cle in $script:Config[$section].Keys) {
                $bases[$section][$cle] = Get-ConfigValue $section $cle
            }
        }
    }

    $parametres = @{
        DossierTravail    = $dossierTravail
        Bases             = $bases
        OracleHome        = Get-ConfigValue 'paths' 'ORACLE_CLIENT_HOME' ''
        FournisseurOracle = (Get-ConfigValue 'powershell' 'FOURNISSEUR_ORACLE' 'auto').ToLower()
        DllManagee        = Get-ConfigValue 'powershell' 'ODP_MANAGED_DLL' ''
        TimeoutRequete    = [int](Get-ConfigValue 'powershell' 'TIMEOUT_REQUETE_SECONDES' '3600')
        MessageOkFr       = Get-ConfigValue 'execution' 'MSG_PROCEDURE_OK_FR' 'Procédure PL/SQL terminée avec succès'
        MessageOkEn       = Get-ConfigValue 'execution' 'MSG_PROCEDURE_OK_EN' 'PL/SQL procedure successfully completed'
        DryRun            = [bool]$DryRun
    }

    Write-LogSection ("EXTRACTEUR LOCAL POWERSHELL - {0} projet(s)" -f $selection.Count)
    if ($DryRun) { Write-Log "Mode DRY-RUN : aucune connexion à la base, aucun fichier écrit." 'WARN' }
    Write-Log "Ni Drive, ni mail, ni HistoExec : traitement strictement local." 'WARN'

    # --- Execution -----------------------------------------------------------
    $codeSortie = 0
    $numero = 0
    $synthese = New-Object System.Collections.ArrayList

    foreach ($ligne in $selection) {
        $numero++
        $libelle = "PROJET [$numero/$($selection.Count)] IdExec $([int]$ligne.IdExec) - $($ligne.ProjectName)"
        $debut = Start-Etape $libelle
        $statut = 'OK'
        try {
            $resultats = Invoke-Projet -Ligne $ligne -Parametres $parametres
            foreach ($resultat in $resultats) {
                [void]$synthese.Add($resultat)
                if ($resultat.Statut -ne 'OK') { $statut = 'KO'; $codeSortie = 1 }
            }
        } catch {
            $statut = 'KO'
            $codeSortie = 1
            Write-Log $_.Exception.Message 'ERROR'
        } finally {
            Stop-Etape $libelle $debut $statut | Out-Null
        }
    }

    # --- Synthese ------------------------------------------------------------
    if ($synthese.Count -gt 0) {
        Write-LogSection "SYNTHÈSE"
        $synthese | Format-Table -AutoSize Requete, Type, Statut, Lignes, Duree | Out-String |
            ForEach-Object { $_.TrimEnd() -split "`n" } | ForEach-Object { Write-Log $_ }
    }

    Write-LogSection "FIN - code retour $codeSortie"
    return $codeSortie
}

exit (Main)
