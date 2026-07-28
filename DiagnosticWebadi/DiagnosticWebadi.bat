@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  Diagnostic Oracle / WebADI - DBFINP1  v9
REM  Script autonome - Batch + PowerShell fusionnes
REM ============================================================

REM --- Parametres (modifiables) ---
set "HOTE=prdscanc1pdb03.dalkia.net"
set "PORT=1521"
set "TNS_ALIAS=DBFINP1"
set "SERVICE=ebs_PDBFINP1"
set "URL_EBS=https://finance.dalkia.net"
set "HOST_EBS=finance.dalkia.net"

REM --- Construction du nom de log ---
for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value 2>nul"') do set "DT=%%I"
set "STAMP=%DT:~0,8%_%DT:~8,6%"
set "LOG=%~dp0Diagnostic_%TNS_ALIAS%_%STAMP%.log"
set "TMP_PS1=%TEMP%\DiagWEBADI_%STAMP%.ps1"

echo.
echo ============================================================
echo  DIAGNOSTIC ORACLE / WebADI - %TNS_ALIAS%
echo ============================================================
echo  Date / Heure : %DATE% %TIME%
echo  Utilisateur  : %USERDOMAIN%\%USERNAME%
echo  Machine      : %COMPUTERNAME%
echo  Fichier log  : %LOG%
echo ============================================================
echo.

REM --- Extraction de la partie PowerShell vers un fichier temporaire ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines=Get-Content '%~f0'; $idx=($lines | Select-String '^::#PS_BEGIN').LineNumber; $lines | Select-Object -Skip $idx | Set-Content -Encoding UTF8 '%TMP_PS1%'"

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS1%" ^
    -Hote "%HOTE%" ^
    -Port %PORT% ^
    -TnsAlias "%TNS_ALIAS%" ^
    -Service "%SERVICE%" ^
    -UrlEbs "%URL_EBS%" ^
    -HostEbs "%HOST_EBS%" ^
    -LogFile "%LOG%"

del "%TMP_PS1%" >nul 2>&1

echo.
echo ============================================================
echo  Diagnostic termine. Log : %LOG%
echo ============================================================
echo.
endlocal
exit /b 0

::#PS_BEGIN
# =============================================================================
#  Diagnostic Oracle / WebADI - DBFINP1  (PowerShell)  v1
#  Embarque dans DiagnosticWebadi.bat - ne pas executer directement
#
#  Usage :  double-cliquer sur DiagnosticWebadi.bat
# =============================================================================

[CmdletBinding()]
param(
    [string]$Hote      = 'prdscanc1pdb03.dalkia.net',
    [int]   $Port      = 1521,
    [string]$TnsAlias  = 'DBFINP1',
    [string]$Service   = 'ebs_PDBFINP1',
    [string]$UrlEbs    = 'https://finance.dalkia.net:4443/',
    [string]$HostEbs   = 'finance.dalkia.net',
    [string]$LogFile
)

$ErrorActionPreference = 'Continue'
$WarningPreference     = 'SilentlyContinue'

# ---------------------------------------------------------------------------
# Logging : tout est affiche ET ecrit dans le log via Start-Transcript
# ---------------------------------------------------------------------------
if (-not $LogFile) {
    $stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
    $LogFile = Join-Path $PSScriptRoot ("Diagnostic_{0}_{1}.log" -f $TnsAlias, $stamp)
}
try { Stop-Transcript | Out-Null } catch {}
Start-Transcript -Path $LogFile -Force | Out-Null

# Stockage des resultats pour le recapitulatif
$R = @{
    OracleClient    = 'KO'
    OracleBitness   = '?'
    Excel           = 'KO'
    DNS             = 'KO'
    ScanIps         = '?'
    Ping            = 'KO'
    Latence         = '?'
    Port            = 'KO'
    TnsAlias        = 'KO'
    TnsEzconnect    = 'KO'
    Proxy           = '?'
    ExcelMacros     = '?'
    EdgeIeMode      = '?'
    HttpsEbs        = '?'
    ZonesIE         = '?'
    NtpStatus       = '?'
    MtuOk           = '?'
}

function Write-Banniere {
    param([string]$Titre)
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "  $Titre"
    Write-Host "============================================================"
}
function Write-Etape {
    param([string]$Titre)
    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "  $Titre"
    Write-Host "------------------------------------------------------------"
}
function Write-KV {
    param([string]$Cle, $Valeur)
    Write-Host ("  {0,-22} : {1}" -f $Cle, $Valeur)
}

# =============================================================================
Write-Banniere "DIAGNOSTIC ORACLE / WebADI - $TnsAlias"
Write-Host ("  Demarre le      : " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ("  Lance par       : $env:USERDOMAIN\$env:USERNAME sur $env:COMPUTERNAME")
Write-Host ("  Hote SCAN       : $Hote")
Write-Host ("  Alias TNS       : $TnsAlias")
Write-Host ("  Service         : $Service")
Write-Host ("  URL EBS         : $UrlEbs")
Write-Host ("  Fichier log     : $LogFile")

# =============================================================================
Write-Etape "0/9 - Contexte du poste (identite, OS, reseau)"
# =============================================================================

Write-Host "--- Identite ---"
Write-KV "Date / Heure locale" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')
Write-KV "Date / Heure UTC"   ((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss UTC'))
Write-KV "Fuseau horaire"     ((Get-TimeZone).Id + ' (' + (Get-TimeZone).DisplayName + ')')
Write-KV "Utilisateur Windows" "$env:USERDOMAIN\$env:USERNAME"
Write-KV "Profil utilisateur" $env:USERPROFILE
try {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    Write-KV "SID utilisateur" $id.User.Value
    $adm = ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
    Write-KV "Droits admin local" $adm
} catch {}
Write-KV "Nom de machine"     $env:COMPUTERNAME
Write-KV "Domaine DNS"        $env:USERDNSDOMAIN
Write-KV "LOGONSERVER"        $env:LOGONSERVER

Write-Host ""
Write-Host "--- Systeme d'exploitation ---"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        Write-KV "OS"            ($os.Caption + ' (' + $os.OSArchitecture + ')')
        Write-KV "Version"       ($os.Version + ' build ' + $os.BuildNumber)
        Write-KV "Demarre le"    $os.LastBootUpTime
    }
    Write-KV "Langue / Locale"  ((Get-Culture).Name + ' / ' + (Get-WinSystemLocale).Name)
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($cs) {
        Write-KV "Constructeur"  ($cs.Manufacturer + ' / ' + $cs.Model)
        Write-KV "RAM totale GB" ([math]::Round($cs.TotalPhysicalMemory / 1GB, 1))
    }
    $av = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction SilentlyContinue |
          Select-Object -ExpandProperty displayName
    if ($av) { Write-KV "Antivirus" ($av -join ', ') }
} catch { Write-Host "  [!] $($_.Exception.Message)" }

Write-Host ""
Write-Host "--- Reseau : interfaces et IP locales ---"
try {
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        $ipc = $_
        Write-Host ("  Interface  : " + $ipc.InterfaceAlias + " (" + $ipc.InterfaceDescription + ")")
        Write-Host ("    IPv4     : " + (($ipc.IPv4Address | ForEach-Object { $_.IPAddress }) -join ', '))
        Write-Host ("    Masque   : /" + (($ipc.IPv4Address | ForEach-Object { $_.PrefixLength }) -join ', '))
        if ($ipc.IPv4DefaultGateway) {
            Write-Host ("    Gateway  : " + (($ipc.IPv4DefaultGateway | ForEach-Object { $_.NextHop }) -join ', '))
        }
        $dns = ($ipc.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | ForEach-Object { $_.ServerAddresses }) -join ', '
        Write-Host ("    DNS      : $dns")
        $ad = Get-NetAdapter -InterfaceIndex $ipc.InterfaceIndex -ErrorAction SilentlyContinue
        if ($ad) {
            Write-Host ("    MAC      : " + $ad.MacAddress)
            Write-Host ("    Statut   : " + $ad.Status + "   Vitesse : " + $ad.LinkSpeed)
        }
    }
} catch { Write-Host "  [!] $($_.Exception.Message)" }

Write-Host ""
Write-Host "--- IP publique (sortie Internet) ---"
try {
    $ipPub = (Invoke-WebRequest -UseBasicParsing -Uri 'https://api.ipify.org' -TimeoutSec 5).Content
    Write-KV "IP publique" $ipPub
} catch {
    Write-Host "  [!] IP publique non recuperable (proxy/firewall ?) : $($_.Exception.Message)"
}

Write-Host ""
Write-Host "--- VPN configures ---"
try {
    $vpn = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue
    if ($vpn) {
        foreach ($v in $vpn) {
            Write-Host ("  VPN : " + $v.Name + " - " + $v.ConnectionStatus + " (" + $v.ServerAddress + ")")
        }
    } else {
        Write-Host "  Aucune connexion VPN configuree au niveau machine."
    }
} catch {}

Write-Host ""
Write-Host "--- Sessions ouvertes (quser) ---"
try {
    $qu = quser 2>$null
    if ($qu) { $qu | ForEach-Object { Write-Host ("  " + $_) } } else { Write-Host "  (Aucune info quser disponible)" }
} catch {}

# =============================================================================
Write-Etape "1/9 - Verification du client Oracle"
# =============================================================================

Write-KV "ORACLE_HOME" $env:ORACLE_HOME
Write-KV "TNS_ADMIN"   $env:TNS_ADMIN

$tnsping = Get-Command tnsping.exe -ErrorAction SilentlyContinue
$sqlplus = Get-Command sqlplus.exe -ErrorAction SilentlyContinue
if ($tnsping) { Write-Host "  [OK] tnsping trouve : $($tnsping.Source)" } else { Write-Host "  [KO] tnsping introuvable dans le PATH." }
if ($sqlplus) { Write-Host "  [OK] sqlplus trouve : $($sqlplus.Source)" } else { Write-Host "  [KO] sqlplus introuvable dans le PATH." }

if ($tnsping) {
    $R['OracleClient'] = 'OK'
    try {
        $fs = [IO.File]::OpenRead($tnsping.Source)
        $br = New-Object IO.BinaryReader($fs)
        $fs.Position = 0x3C
        $peOffset = $br.ReadInt32()
        $fs.Position = $peOffset + 4
        $machine = $br.ReadUInt16()
        $br.Close(); $fs.Close()
        switch ($machine) {
            0x014c { $R['OracleBitness'] = '32 bits' }
            0x8664 { $R['OracleBitness'] = '64 bits' }
            default { $R['OracleBitness'] = "indetermine (machine=0x{0:X4})" -f $machine }
        }
    } catch {
        if ($tnsping.Source -match 'Program Files \(x86\)') { $R['OracleBitness'] = '32 bits' }
        elseif ($tnsping.Source -match 'Program Files')     { $R['OracleBitness'] = '64 bits' }
    }
    Write-KV "Client Oracle" $R['OracleBitness']
}

Write-Host ""
Write-Host "--- ORACLE_HOMES dans le registre ---"
foreach ($base in 'HKLM:\SOFTWARE\ORACLE','HKLM:\SOFTWARE\WOW6432Node\ORACLE') {
    if (Test-Path $base) {
        Write-Host ("  Branche : " + $base)
        Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($p.ORACLE_HOME) {
                Write-Host ("    " + $_.PSChildName + " -> " + $p.ORACLE_HOME)
            }
        }
    }
}

# =============================================================================
Write-Etape "2/9 - Verification d'Excel (32 bits requis pour WebADI)"
# =============================================================================

$bitness = $null; $source = $null; $exePath = $null
$ctr = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
if (Test-Path $ctr) {
    $p = Get-ItemProperty $ctr -ErrorAction SilentlyContinue
    if ($p.Platform) { $bitness = $p.Platform; $source = 'Click-to-Run' }
}
if (-not $bitness) {
    foreach ($v in '16.0','15.0','14.0') {
        $k = "HKLM:\SOFTWARE\Microsoft\Office\$v\Outlook"
        if (Test-Path $k) {
            $b = (Get-ItemProperty $k -ErrorAction SilentlyContinue).Bitness
            if ($b) { $bitness = $b; $source = "Office $v (MSI)"; break }
        }
    }
}
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe',
               'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\excel.exe') {
    if (Test-Path $k) {
        $exePath = (Get-ItemProperty $k -ErrorAction SilentlyContinue).'(default)'
        if ($exePath) { break }
    }
}
if ($exePath) {
    Write-KV "Chemin Excel" $exePath
    if (-not $bitness) {
        if ($exePath -match 'Program Files \(x86\)') { $bitness = 'x86'; $source = 'chemin' }
        elseif ($exePath -match 'Program Files')     { $bitness = 'x64'; $source = 'chemin' }
    }
}
if ($source)  { Write-KV "Source detection" $source }
if ($bitness) { Write-KV "Bitness Excel"    $bitness }

if ($bitness -match 'x86|32') {
    Write-Host "  [OK] Excel 32 bits - compatible WebADI."
    $R['Excel'] = 'OK (32 bits)'
} elseif ($bitness -match 'x64|64') {
    Write-Host "  [KO] Excel 64 bits - WebADI ne fonctionnera PAS."
    $R['Excel'] = 'KO (64 bits)'
} elseif (-not $exePath) {
    Write-Host "  [KO] Excel introuvable sur le poste."
    $R['Excel'] = 'KO (absent)'
} else {
    $R['Excel'] = '? (indetermine)'
}

# =============================================================================
Write-Etape "3/9 - Resolution DNS de $Hote (SCAN RAC)"
# =============================================================================

try {
    $ips = [System.Net.Dns]::GetHostAddresses($Hote) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
    Write-Host "  --- IP resolues par le SCAN ---"
    foreach ($ip in $ips) { Write-Host ("    - " + $ip.IPAddressToString) }
    Write-KV "Total IP" $ips.Count
    if ($ips.Count -gt 0) {
        $R['DNS'] = 'OK'
        $R['ScanIps'] = "$($ips.Count) IP"
    }
    $scanIpList = $ips | ForEach-Object { $_.IPAddressToString }
} catch {
    Write-Host "  [KO] Resolution DNS impossible : $($_.Exception.Message)"
    $scanIpList = @()
}

Write-Host ""
Write-Host "--- nslookup ---"
try { nslookup $Hote 2>&1 | ForEach-Object { Write-Host ("  " + $_) } } catch {}

# =============================================================================
Write-Etape "4/9 - Test PING vers $Hote"
# =============================================================================

try {
    $rep = Test-Connection -ComputerName $Hote -Count 5 -ErrorAction SilentlyContinue
    if ($rep) {
        foreach ($p in $rep) {
            Write-Host ("  Reponse de " + $p.IPV4Address + " en " + $p.ResponseTime + " ms")
        }
        $avg = [math]::Round(($rep | Measure-Object -Property ResponseTime -Average).Average, 1)
        $max = ($rep | Measure-Object -Property ResponseTime -Maximum).Maximum
        Write-Host ("  Latence moyenne : $avg ms (max : $max ms)")
        $R['Ping'] = 'OK'
        $R['Latence'] = "$avg ms"
    } else {
        Write-Host "  [!] Pas de reponse ICMP (un SCAN VIP peut ne pas repondre meme si le port 1521 est OK)."
        $R['Ping'] = 'KO'
        $R['Latence'] = 'N/A'
    }
} catch {
    Write-Host "  [!] $($_.Exception.Message)"
}

# =============================================================================
Write-Etape "5/9 - Test du port $Port sur $Hote"
# =============================================================================

try {
    $tnc = Test-NetConnection -ComputerName $Hote -Port $Port -WarningAction SilentlyContinue
    Write-KV "Adresse distante" $tnc.RemoteAddress
    Write-KV "Port distant"     $tnc.RemotePort
    if ($tnc.SourceAddress) { Write-KV "Interface source" $tnc.SourceAddress.IPAddress }
    Write-KV "TCP test reussi"  $tnc.TcpTestSucceeded
    if ($tnc.TcpTestSucceeded) {
        Write-Host "  [OK] Port $Port ouvert sur $Hote."
        $R['Port'] = 'OK'
    } else {
        Write-Host "  [KO] Port $Port INACCESSIBLE sur $Hote."
        $R['Port'] = 'KO'
    }
} catch { Write-Host "  [!] $($_.Exception.Message)" }

if ($scanIpList) {
    Write-Host ""
    Write-Host "  --- Test port 1521 sur chaque IP du SCAN ---"
    foreach ($ip in $scanIpList) {
        try {
            $t = Test-NetConnection -ComputerName $ip -Port $Port -WarningAction SilentlyContinue
            $etat = if ($t.TcpTestSucceeded) { '[OK]' } else { '[KO]' }
            Write-Host ("    $etat $ip : TCP=$($t.TcpTestSucceeded)")
        } catch {}
    }
}

# =============================================================================
Write-Etape "6/9 - TNSPING $TnsAlias + inspection tnsnames.ora"
# =============================================================================

$tnsCandidats = @()
Write-Host "  --- Recherche des fichiers tnsnames.ora possibles ---"
# 1. Variable d'environnement TNS_ADMIN
if ($env:TNS_ADMIN) {
    $tnsPath = Join-Path $env:TNS_ADMIN 'tnsnames.ora'
    $tnsCandidats += $tnsPath
    Write-Host "  [+] Ajout via TNS_ADMIN: $tnsPath"
}
# 2. Variable d'environnement ORACLE_HOME
if ($env:ORACLE_HOME) {
    $tnsPath = Join-Path $env:ORACLE_HOME 'network\admin\tnsnames.ora'
    $tnsCandidats += $tnsPath
    Write-Host "  [+] Ajout via ORACLE_HOME: $tnsPath"
}

# 3. Recherche dynamique dans le registre (32 et 64 bits)
Write-Host "  [+] Recherche dans le registre..."
foreach ($base in 'HKLM:\SOFTWARE\ORACLE','HKLM:\SOFTWARE\WOW6432Node\ORACLE') {
    if (Test-Path $base) {
        Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($p.ORACLE_HOME) {
                $tnsPath = Join-Path $p.ORACLE_HOME 'network\admin\tnsnames.ora'
                $tnsCandidats += $tnsPath
                Write-Host "      - Depuis $($_.PSChildName): $tnsPath"
            }
        }
    }
}

Write-Host ""
Write-Host "  --- Analyse des fichiers trouves ---"
foreach ($f in $tnsCandidats | Select-Object -Unique) {
    if (Test-Path $f) {
        Write-Host "  [OK] $f existe."
        if (Select-String -Path $f -Pattern "(?i)^\s*$([regex]::Escape($TnsAlias))\s*=" -Quiet) {
            Write-Host "  [OK] Alias $TnsAlias present dans $f."
        } else {
            Write-Host "  [KO] Alias $TnsAlias ABSENT de $f."
        }
    }
}

Write-Host ""
Write-Host "--- Test 1 : TNSPING sur l'alias $TnsAlias ---"
if ($tnsping) {
    $out = & $tnsping.Source $TnsAlias 2>&1
    $out | ForEach-Object { Write-Host ("  " + $_) }
    if ($LASTEXITCODE -eq 0) { $R['TnsAlias'] = 'OK' } else { $R['TnsAlias'] = 'KO' }
} else {
    Write-Host "  [!] tnsping introuvable - test ignore."
    $R['TnsAlias'] = 'KO (tnsping absent)'
}

Write-Host ""
Write-Host "--- Test 2 : TNSPING EZCONNECT ($Hote`:$Port/$Service) ---"
if ($tnsping) {
    $out = & $tnsping.Source "$Hote`:$Port/$Service" 2>&1
    $out | ForEach-Object { Write-Host ("  " + $_) }
    if ($LASTEXITCODE -eq 0) { $R['TnsEzconnect'] = 'OK' } else { $R['TnsEzconnect'] = 'KO' }
} else {
    $R['TnsEzconnect'] = 'KO (tnsping absent)'
}

# =============================================================================
Write-Etape "7/9 - Traceroute + latence"
# =============================================================================

Write-Host "--- Traceroute (15 sauts max) ---"
tracert -h 15 -w 1000 $Hote 2>&1 | ForEach-Object { Write-Host ("  " + $_) }

# =============================================================================
Write-Etape "8/9 - Verifications complementaires WebADI"
# =============================================================================

Write-Host "--- 8.1 : Proxy Windows / WinHTTP / IE ---"
$ie = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
Write-KV "IE ProxyEnable"    $ie.ProxyEnable
Write-KV "IE ProxyServer"    $ie.ProxyServer
Write-KV "IE ProxyOverride"  $ie.ProxyOverride
Write-KV "IE AutoConfigURL"  $ie.AutoConfigURL
Write-Host ""
Write-Host "  --- WinHTTP (netsh) ---"
netsh winhttp show proxy 2>&1 | ForEach-Object { Write-Host ("  " + $_) }
if ($ie.ProxyEnable -eq 1) { $R['Proxy'] = 'Actif' } else { $R['Proxy'] = 'Aucun (direct)' }

Write-Host ""
Write-Host "--- 8.2 : Excel Trust Center (macros + emplacements de confiance) ---"
foreach ($v in '16.0','15.0','14.0') {
    $sec = "HKCU:\Software\Microsoft\Office\$v\Excel\Security"
    if (Test-Path $sec) {
        $s = Get-ItemProperty $sec -ErrorAction SilentlyContinue
        Write-Host "  Excel $v :"
        Write-Host ("    VBAWarnings                       : " + $s.VBAWarnings + "  (1=toutes 2=avertir 3=signees 4=desactiver)")
        Write-Host ("    AccessVBOM                        : " + $s.AccessVBOM + "   (1=requis WebADI)")
        Write-Host ("    BlockContentExecutionFromInternet : " + $s.BlockContentExecutionFromInternet)
        if ($s.AccessVBOM -ne 1) {
            Write-Host "    [KO] AccessVBOM != 1 : WebADI ne pourra pas executer ses macros."
            $R['ExcelMacros'] = 'KO (AccessVBOM!=1)'
        } elseif ($s.VBAWarnings -eq 4) {
            Write-Host "    [KO] Macros completement desactivees."
            $R['ExcelMacros'] = 'KO (macros off)'
        } else {
            $R['ExcelMacros'] = 'OK'
        }
        $tr = "$sec\Trusted Locations"
        if (Test-Path $tr) {
            Write-Host "    Emplacements de confiance :"
            Get-ChildItem $tr -ErrorAction SilentlyContinue | ForEach-Object {
                $tp = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).Path
                if ($tp) { Write-Host ("      - " + $tp) }
            }
        }
        break
    }
}

Write-Host ""
Write-Host "--- 8.3 : Edge / IE Mode ---"
$edgeVer = $null
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Edge\BLBeacon','HKCU:\SOFTWARE\Microsoft\Edge\BLBeacon') {
    if (Test-Path $k) { $edgeVer = (Get-ItemProperty $k -ErrorAction SilentlyContinue).version; if ($edgeVer) { break } }
}
Write-KV "Version Edge" $edgeVer
$pol = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -ErrorAction SilentlyContinue
Write-KV "IE Mode (politique)" ($pol.InternetExplorerIntegrationLevel)
Write-KV "Site List IEMode"    $pol.InternetExplorerIntegrationSiteList
if ($pol.InternetExplorerIntegrationLevel -eq 1) { $R['EdgeIeMode'] = 'Actif' } else { $R['EdgeIeMode'] = 'Inactif' }
$ieReg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer' -ErrorAction SilentlyContinue
Write-KV "Internet Explorer" ($ieReg.svcVersion, $ieReg.Version | Where-Object { $_ } | Select-Object -First 1)

Write-Host ""
Write-Host "--- 8.4 : Java JRE ---"
$j = Get-Command java.exe -ErrorAction SilentlyContinue
if ($j) {
    Write-KV "java.exe" $j.Source
    & $j.Source -version 2>&1 | ForEach-Object { Write-Host ("  " + $_) }
} else {
    Write-Host "  [INFO] Aucun java.exe dans le PATH (souvent non requis avec WebADI recent)."
}

Write-Host ""
Write-Host "--- 8.5 : Instances Excel deja ouvertes ---"
$p = Get-Process EXCEL -ErrorAction SilentlyContinue
if ($p) {
    $p | Select-Object Id, StartTime, Path | Format-Table -AutoSize | Out-String -Width 200 |
        ForEach-Object { $_ -split "`r?`n" } | ForEach-Object { if ($_.Trim()) { Write-Host ("  " + $_) } }
} else {
    Write-Host "  Aucune instance Excel en cours."
}

# =============================================================================
Write-Etape "9/9 - Verifications avancees"
# =============================================================================

Write-Host "--- 9.1 : Test HTTPS portail EBS ($UrlEbs) + certificat ---"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12'
    $script:certCapt = $null
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {
        param($s, $cert, $chain, $err)
        $script:certCapt = $cert
        return $true
    }
    $req = [Net.HttpWebRequest]::Create($UrlEbs)
    $req.Timeout = 10000
    $req.AllowAutoRedirect = $true
    $resp = $req.GetResponse()
    Write-KV "HTTP Status" ([int]$resp.StatusCode.value__,$resp.StatusCode -join ' ')
    Write-KV "Server"      $resp.Headers['Server']
    $resp.Close()
    if ($script:certCapt) {
        Write-KV "Cert Sujet"     $script:certCapt.Subject
        Write-KV "Cert Emetteur"  $script:certCapt.Issuer
        Write-KV "Cert Expire le" $script:certCapt.GetExpirationDateString()
    }
    $R['HttpsEbs'] = 'OK'
} catch {
    Write-Host ("  [KO] Echec HTTPS : " + $_.Exception.Message)
    $R['HttpsEbs'] = 'KO'
} finally {
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $null
}

Write-Host ""
Write-Host "--- 9.2 : Sites de confiance IE/Edge (ZoneMap) pour $HostEbs ---"
$base = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$found = $false
if (Test-Path $base) {
    Get-ChildItem $base -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        foreach ($proto in 'http','https','*') {
            $zone = $p.$proto
            if ($zone) {
                $path = $_.PSChildName
                $parent = Split-Path $_.PSParentPath -Leaf
                $full = if ($parent -eq 'Domains') { $path } else { "$path.$parent" }
                if ($HostEbs -like "*$full*" -or $full -like "*$HostEbs*") {
                    $zNom = switch ([int]$zone) {
                        1 { 'Intranet' }
                        2 { 'Sites de confiance' }
                        3 { 'Internet' }
                        4 { 'Sites sensibles' }
                        default { $zone }
                    }
                    Write-Host "  [OK] $full ($proto) -> Zone $zone ($zNom)"
                    $found = $true
                }
            }
        }
    }
}
if (-not $found) {
    Write-Host "  [!] $HostEbs non present dans les zones IE (HKCU). A ajouter en Intranet ou Sites de confiance pour WebADI."
    $R['ZonesIE'] = 'Absent'
} else {
    $R['ZonesIE'] = 'Present'
}

Write-Host ""
Write-Host "--- 9.3 : Excel Protected View + Add-ins desactives ---"
foreach ($v in '16.0','15.0','14.0') {
    $pv = "HKCU:\Software\Microsoft\Office\$v\Excel\Security\ProtectedView"
    if (Test-Path $pv) {
        $p = Get-ItemProperty $pv -ErrorAction SilentlyContinue
        Write-Host "  Excel $v ProtectedView :"
        Write-Host ("    DisableInternetFilesInPV   : " + $p.DisableInternetFilesInPV)
        Write-Host ("    DisableAttachementsInPV    : " + $p.DisableAttachementsInPV)
        Write-Host ("    DisableUnsafeLocationsInPV : " + $p.DisableUnsafeLocationsInPV)
    }
    $res = "HKCU:\Software\Microsoft\Office\$v\Excel\Resiliency\DisabledItems"
    if (Test-Path $res) {
        $items = (Get-Item $res -ErrorAction SilentlyContinue).Property
        if ($items) {
            Write-Host ("  [!] Excel $v a " + $items.Count + " add-in(s) desactive(s) : " + ($items -join ', '))
        } else {
            Write-Host "  [OK] Excel $v : aucun add-in desactive."
        }
    }
}

Write-Host ""
Write-Host "--- 9.4 : Enregistrement COM Excel.Application ---"
$clsid = $null
foreach ($k in 'HKLM:\SOFTWARE\Classes\Excel.Application\CLSID',
               'HKLM:\SOFTWARE\Classes\WOW6432Node\Excel.Application\CLSID') {
    if (Test-Path $k) {
        $clsid = (Get-ItemProperty $k -ErrorAction SilentlyContinue).'(default)'
        if ($clsid) { break }
    }
}
Write-KV "CLSID Excel.Application" $clsid
try {
    $x = New-Object -ComObject Excel.Application
    Write-Host "  [OK] Instanciation COM Excel reussie (version : $($x.Version))"
    $x.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($x) | Out-Null
} catch {
    Write-Host ("  [KO] Impossible d'instancier Excel via COM : " + $_.Exception.Message)
}

Write-Host ""
Write-Host "--- 9.5 : Test MTU / fragmentation (ping 1472 octets DF) ---"
$mtuOut = ping -f -l 1472 -n 2 $Hote 2>&1
$mtuOut | ForEach-Object { Write-Host ("  " + $_) }
if ($mtuOut -match 'fragment') {
    $R['MtuOk'] = 'KO (fragmentation requise)'
} elseif ($mtuOut -match 'TTL=') {
    $R['MtuOk'] = 'OK (1472 sans frag)'
} else {
    $R['MtuOk'] = '?'
}

Write-Host ""
Write-Host "--- 9.6 : Etat NTP / heure systeme ---"
try {
    $w32 = w32tm /query /status 2>&1
    $w32 | ForEach-Object { Write-Host ("  " + $_) }
    $deriv = ($w32 | Select-String 'Phase Offset|Decalage de phase') -replace '^\s+',''
    if ($deriv) { $R['NtpStatus'] = ($deriv | Select-Object -First 1).ToString() } else { $R['NtpStatus'] = 'OK' }
} catch { Write-Host "  [!] w32tm indisponible." }

Write-Host ""
Write-Host "--- 9.7 : Espace disque + dossier TEMP ---"
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -or $_.Free -ne $null } | ForEach-Object {
    $libre = [math]::Round(($_.Free / 1GB), 2)
    $total = [math]::Round((($_.Used + $_.Free) / 1GB), 2)
    Write-Host ("  Lecteur " + $_.Name + ": libre $libre GB / total $total GB")
}
Write-KV "TEMP utilisateur" $env:TEMP
try {
    $tmpSize = (Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
    if ($tmpSize) { Write-KV "Taille TEMP" ("{0:N1} MB" -f ($tmpSize / 1MB)) }
} catch {}

Write-Host ""
Write-Host "--- 9.8 : PowerShell : version + ExecutionPolicy ---"
Write-KV "Version PowerShell" $PSVersionTable.PSVersion
Get-ExecutionPolicy -List | ForEach-Object {
    Write-Host ("  " + $_.Scope.ToString().PadRight(18) + " : " + $_.ExecutionPolicy)
}

Write-Host ""
Write-Host "--- 9.9 : Derniers evenements Excel / Office (7 jours, max 15) ---"
try {
    $since = (Get-Date).AddDays(-7)
    $evts = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $since; Level = 1,2,3 } -ErrorAction SilentlyContinue |
            Where-Object { $_.ProviderName -match 'Excel|Office' } |
            Select-Object -First 15
    if ($evts) {
        foreach ($e in $evts) {
            $msg = ($e.Message -split "`r?`n")[0]
            Write-Host ("  [{0}] {1} - {2} (id {3}) : {4}" -f $e.TimeCreated, $e.LevelDisplayName, $e.ProviderName, $e.Id, $msg)
        }
    } else {
        Write-Host "  Aucun evenement Excel/Office au niveau erreur/warning sur les 7 derniers jours."
    }
} catch { Write-Host "  [!] Lecture des evenements impossible : $($_.Exception.Message)" }

Write-Host ""
Write-Host "--- 9.10 : Route reseau vers $Hote ---"
try {
    $ipFirst = ([System.Net.Dns]::GetHostAddresses($Hote) |
                Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1).IPAddressToString
    if ($ipFirst) {
        $route = Find-NetRoute -RemoteIPAddress $ipFirst -ErrorAction SilentlyContinue
        if ($route) {
            $route | Select-Object -First 2 IPAddress, InterfaceAlias, NextHop, RouteMetric, DestinationPrefix |
                Format-List | Out-String | ForEach-Object { $_ -split "`r?`n" } |
                ForEach-Object { if ($_.Trim()) { Write-Host ("  " + $_) } }
        }
    }
} catch { Write-Host "  [!] $($_.Exception.Message)" }

# =============================================================================
Write-Banniere "RECAPITULATIF"
# =============================================================================

Write-Host ("  Poste / utilisateur ... $env:COMPUTERNAME / $env:USERDOMAIN\$env:USERNAME")
Write-Host ("  Date diagnostic ....... " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ("  Oracle Client ......... " + $R['OracleClient'] + "  (bitness : " + $R['OracleBitness'] + ")")
Write-Host ("  Excel ................. " + $R['Excel'])
Write-Host ("  Resolution DNS ........ " + $R['DNS'] + "  (" + $R['ScanIps'] + ")")
Write-Host ("  Ping $Hote ........... " + $R['Ping'])
Write-Host ("  Latence moyenne ....... " + $R['Latence'])
Write-Host ("  Port $Port ............... " + $R['Port'])
Write-Host ("  TNSPING alias $TnsAlias .. " + $R['TnsAlias'])
Write-Host ("  TNSPING EZCONNECT ..... " + $R['TnsEzconnect'])
Write-Host ("  Proxy Windows/IE ...... " + $R['Proxy'])
Write-Host ("  Excel macros (VBOM) ... " + $R['ExcelMacros'])
Write-Host ("  Edge IE Mode .......... " + $R['EdgeIeMode'])
Write-Host ("  HTTPS $UrlEbs ......... " + $R['HttpsEbs'])
Write-Host ("  Zones IE ($HostEbs) ... " + $R['ZonesIE'])
Write-Host ("  MTU 1472 sans frag .... " + $R['MtuOk'])
Write-Host ("  NTP ................... " + $R['NtpStatus'])
Write-Host ""
Write-Host ("  Log complet : " + $LogFile)

Stop-Transcript | Out-Null
