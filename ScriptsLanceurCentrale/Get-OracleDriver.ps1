<#
.SYNOPSIS
    Telecharge le pilote Oracle managé (ODP.NET) utilise par CapAppro_Local.ps1.

.DESCRIPTION
    Oracle.ManagedDataAccess.dll est une implementation 100 % .NET du protocole
    Oracle : elle ne necessite AUCUN client Oracle installe, contrairement aux
    modes OLE DB et ODBC.

    Le script recupere le paquet NuGet adapte a l'edition de PowerShell en
    cours et extrait la DLL dans .\lib\ , ou CapAppro_Local.ps1 la cherche
    automatiquement.

        Windows PowerShell 5.1  -> Oracle.ManagedDataAccess      (net472)
        PowerShell 7+           -> Oracle.ManagedDataAccess.Core (net8.0)

.PARAMETER Destination
    Dossier de depot. Par defaut .\lib\ a cote du script.

.PARAMETER Version
    Version precise du paquet NuGet. Par defaut, la derniere publiee.

.EXAMPLE
    .\Get-OracleDriver.ps1
.EXAMPLE
    .\Get-OracleDriver.ps1 -Version 21.19.0
#>

[CmdletBinding()]
param(
    [string]$Destination,
    [string]$Version
)

# Version par defaut : derniere version verifiee comme chargeable sous
# Windows PowerShell 5.1. Les versions 21.x et 23.x declarent des dependances
# NuGet (System.Text.Json, System.Formats.Asn1...) absentes de .NET Framework
# et echouent au chargement avec une ReflectionTypeLoadException.
$VERSION_PAR_DEFAUT_DESKTOP = '19.28.0'

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$dossierScript = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($Destination)) {
    $Destination = Join-Path $dossierScript 'lib'
}

# --- Choix du paquet selon l'edition de PowerShell ---------------------------
$editionCore = $false
if ((Get-Variable -Name PSVersionTable -ErrorAction SilentlyContinue) -and
    $PSVersionTable.ContainsKey('PSEdition')) {
    $editionCore = ($PSVersionTable.PSEdition -eq 'Core')
}

if ($editionCore) {
    $paquet = 'Oracle.ManagedDataAccess.Core'
    $ciblesPreferees = @('lib/net8.0/', 'lib/net6.0/', 'lib/netstandard2.1/')
} else {
    $paquet = 'Oracle.ManagedDataAccess'
    $ciblesPreferees = @('lib/net472/', 'lib/net462/', 'lib/net46/')
}

if ([string]::IsNullOrEmpty($Version) -and -not $editionCore) {
    $Version = $VERSION_PAR_DEFAUT_DESKTOP
}
$url = "https://www.nuget.org/api/v2/package/$paquet"
if (-not [string]::IsNullOrEmpty($Version)) { $url = "$url/$Version" }

Write-Host "Edition PowerShell : $($PSVersionTable.PSVersion) ($(if ($editionCore) {'Core'} else {'Desktop'}))"
Write-Host "Paquet NuGet       : $paquet $(if ($Version) { $Version } else { '(dernière)' })"
Write-Host "Destination        : $Destination"
Write-Host ''

# --- Telechargement ----------------------------------------------------------
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch { }

$archiveTemporaire = Join-Path $env:TEMP ("{0}.nupkg.zip" -f $paquet)
Write-Host "Téléchargement depuis $url ..."
try {
    Invoke-WebRequest -Uri $url -OutFile $archiveTemporaire -UseBasicParsing -TimeoutSec 120
} catch {
    Write-Host ''
    Write-Host "ECHEC du téléchargement : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ''
    Write-Host "Si l'accès à nuget.org est bloqué, récupérer manuellement le paquet" -ForegroundColor Yellow
    Write-Host "$paquet, l'ouvrir comme une archive ZIP, et copier" -ForegroundColor Yellow
    Write-Host "Oracle.ManagedDataAccess.dll dans : $Destination" -ForegroundColor Yellow
    exit 1
}
Write-Host ("Téléchargé : {0} Mo" -f [math]::Round((Get-Item $archiveTemporaire).Length / 1MB, 2))

# --- Extraction --------------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}

$archive = [IO.Compression.ZipFile]::OpenRead($archiveTemporaire)
try {
    $entree = $null
    foreach ($cible in $ciblesPreferees) {
        $entree = $archive.Entries | Where-Object {
            $_.FullName -like "$cible*" -and $_.Name -eq 'Oracle.ManagedDataAccess.dll'
        } | Select-Object -First 1
        if ($null -ne $entree) { break }
    }
    if ($null -eq $entree) {
        $disponibles = ($archive.Entries | Where-Object { $_.Name -like '*.dll' } |
                        ForEach-Object { $_.FullName }) -join ', '
        throw "Oracle.ManagedDataAccess.dll introuvable pour les cibles $($ciblesPreferees -join ', '). Contenu : $disponibles"
    }

    $fichierCible = Join-Path $Destination 'Oracle.ManagedDataAccess.dll'
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entree, $fichierCible, $true)
    Write-Host "Extrait : $($entree.FullName)"
    Write-Host "Écrit   : $fichierCible"
} finally {
    $archive.Dispose()
    Remove-Item -LiteralPath $archiveTemporaire -Force -ErrorAction SilentlyContinue
}

# --- Verification ------------------------------------------------------------
Write-Host ''
try {
    Add-Type -Path $fichierCible
    $type = [Oracle.ManagedDataAccess.Client.OracleConnection]
    Write-Host "Pilote chargé avec succès : $($type.Assembly.GetName().Version)" -ForegroundColor Green
    Write-Host ''
    Write-Host "CapAppro_Local.ps1 le trouvera automatiquement." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "La DLL a été déposée mais n'a pas pu être chargée :" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Vérifier que le fichier n'est pas bloqué par Windows :" -ForegroundColor Yellow
    Write-Host "  Unblock-File '$fichierCible'" -ForegroundColor Yellow
    exit 1
}
