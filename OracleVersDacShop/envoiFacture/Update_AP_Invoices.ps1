# =====================================================================
# Update AP.AP_INVOICES_ALL depuis invoice.csv
# =====================================================================
# Date de creation  : 12/05/2026
# Base de donnees   : Oracle EBS 12.2.13
# Fichier CSV       : invoice.csv (colonne INVOICE_ID)
#
# UPDATE effectue   :
#   LAST_UPDATE_DATE  = SYSDATE
#   LAST_UPDATED_BY   = FND_GLOBAL.USER_ID
#   LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
#
# SECURITE          : COMMIT uniquement si 0 erreur, ROLLBACK sinon
#                     Lots de 999 IDs max (limite Oracle IN clause)
# =====================================================================

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "ddMMyyyy_HHmmss"

Write-Host "Etape 1 : Chargement de la configuration..." -ForegroundColor Yellow

$ConfigFile = Join-Path $ScriptDir "..\config.ps1"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERREUR] config.ps1 introuvable : $ConfigFile" -ForegroundColor Red
    pause; exit 1
}
. (Resolve-Path $ConfigFile)

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"
Write-Host "   Connexion : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host "   FND User  : $FND_USER_NAME (USER_ID=$FND_USER_ID / RESP_ID=$FND_RESP_ID / APPL_ID=$FND_RESP_APPL_ID)" -ForegroundColor Green

# --- CLIENT ORACLE ---
$SQL_CMD = $null
foreach ($cmd in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $SQL_CMD = $cmd; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host "[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)" -ForegroundColor Red
    pause; exit 1
}
Write-Host "   Client    : $SQL_CMD" -ForegroundColor Green
Write-Host ""

# --- LECTURE CSV ---
Write-Host "Etape 2 : Lecture du fichier invoice.csv..." -ForegroundColor Yellow

$CsvPath = Join-Path $ScriptDir "invoice.csv"
if (-not (Test-Path $CsvPath)) {
    Write-Host "[ERREUR] invoice.csv introuvable : $CsvPath" -ForegroundColor Red
    pause; exit 1
}

$ids = Get-Content $CsvPath -Encoding UTF8 |
       Where-Object { $_ -match '^\d+$' } |
       ForEach-Object { $_.Trim() }

$nbTotal = $ids.Count
Write-Host "   Factures trouvees : $nbTotal" -ForegroundColor Green
Write-Host ""

# --- GENERATION SQL ---
Write-Host "Etape 3 : Generation du script SQL..." -ForegroundColor Yellow

$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$FichierSQLTmp = Join-Path $LogDir "update_ap_${Timestamp}.sql"
$FichierLog    = Join-Path $LogDir "update_ap_${Timestamp}.log"

# Decouper en lots de 999 (limite Oracle pour IN clause)
$batchSize = 999
$batches   = @()
for ($i = 0; $i -lt $ids.Count; $i += $batchSize) {
    $fin     = [Math]::Min($i + $batchSize - 1, $ids.Count - 1)
    $batches += ,($ids[$i..$fin])
}
Write-Host "   Lots de $batchSize    : $($batches.Count) lot(s)" -ForegroundColor Gray

# Encodage sans BOM (sqlplus ne supporte pas le BOM UTF-8)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$sql  = "SET SERVEROUTPUT ON SIZE UNLIMITED`n"
$sql += "SET FEEDBACK OFF`n"
$sql += "WHENEVER SQLERROR EXIT ROLLBACK`n`n"
$sql += "DECLARE`n"
$sql += "    v_user_id     NUMBER := $FND_USER_ID;`n"
$sql += "    v_resp_id     NUMBER := $FND_RESP_ID;`n"
$sql += "    v_resp_app_id NUMBER := $FND_RESP_APPL_ID;`n"
$sql += "    v_total       NUMBER := 0;`n"
$sql += "BEGIN`n`n"
$sql += "    -- Initialiser le contexte Oracle EBS`n"
$sql += "    FND_GLOBAL.APPS_INITIALIZE(v_user_id, v_resp_id, v_resp_app_id);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('APPS_INITIALIZE OK - USER=$FND_USER_NAME USER_ID=$FND_USER_ID RESP_ID=$FND_RESP_ID APPL_ID=$FND_RESP_APPL_ID');`n`n"

$lotNum = 1
foreach ($batch in $batches) {
    # Decouper les IDs en sous-lignes de 50 (eviter limite sqlplus 2499 chars/ligne)
    $lineSize = 50
    $subLines = @()
    for ($j = 0; $j -lt $batch.Count; $j += $lineSize) {
        $fin2      = [Math]::Min($j + $lineSize - 1, $batch.Count - 1)
        $subLines += $batch[$j..$fin2] -join ", "
    }
    $inList = $subLines -join ",`n               "

    $sql += "    -- Lot $lotNum / $($batches.Count) ($($batch.Count) factures)`n"
    $sql += "    UPDATE AP.AP_INVOICES_ALL`n"
    $sql += "    SET    LAST_UPDATE_DATE  = SYSDATE,`n"
    $sql += "           LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,`n"
    $sql += "           LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID`n"
    $sql += "    WHERE  INVOICE_ID IN ($inList);`n"
    $sql += "    v_total := v_total + SQL%ROWCOUNT;`n`n"

    $lotNum++
}

$sql += "    COMMIT;`n`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('RESULTAT MISE A JOUR');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  AP_INVOICES_ALL       : ' || v_total || ' / $nbTotal');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('COMMIT effectue avec succes.');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=================================================');`n"
$sql += "`n"
$sql += "EXCEPTION`n"
$sql += "    WHEN OTHERS THEN`n"
$sql += "        ROLLBACK;`n"
$sql += "        DBMS_OUTPUT.PUT_LINE('ERREUR FATALE : ' || SQLERRM);`n"
$sql += "        DBMS_OUTPUT.PUT_LINE('ROLLBACK effectue - aucune modification enregistree.');`n"
$sql += "        RAISE;`n"
$sql += "END;`n"
$sql += "/`n`n"
$sql += "EXIT;`n"

[System.IO.File]::WriteAllText($FichierSQLTmp, $sql, $utf8NoBom)
Write-Host "   Script SQL : $FichierSQLTmp" -ForegroundColor Gray
Write-Host ""

# --- EXECUTION ---
Write-Host "Etape 4 : Execution sur Oracle EBS..." -ForegroundColor Yellow
Write-Host "   Mise a jour de $nbTotal factures en cours..." -ForegroundColor Gray
Write-Host ""

$sortie   = & $SQL_CMD -S "$CONNECT_STR" "@$FichierSQLTmp" 2>&1
$exitCode = $LASTEXITCODE

$sortie | Tee-Object -FilePath $FichierLog
Write-Host ""

if ($exitCode -eq 0) {
    Write-Host "Execution Oracle terminee." -ForegroundColor Green
} else {
    Write-Host "[ATTENTION] SQLcl a retourne le code : $exitCode" -ForegroundColor Yellow
}

Write-Host "   Log sauvegarde : $FichierLog" -ForegroundColor Cyan
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  FIN - Update AP_INVOICES_ALL" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
pause
