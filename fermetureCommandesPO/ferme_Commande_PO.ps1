# =====================================================================
# Fermeture definitive des commandes PO depuis po_list.csv
# =====================================================================
# Date de creation  : 13/05/2026
# Base de donnees   : Oracle EBS 12.2.13
# Fichier CSV       : po_list.csv (colonne PO_NUMBER, une par ligne)
#
# ACTION            : FINALLY CLOSE sur PO_HEADERS_ALL, PO_LINES_ALL,
#                     PO_LINE_LOCATIONS_ALL, PO_DISTRIBUTIONS_ALL
# SECURITE          : COMMIT par commande, ROLLBACK sur erreur technique
# =====================================================================

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "ddMMyyyy_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  FERMETURE DEFINITIVE COMMANDES PO - Oracle EBS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. CONFIGURATION ---
Write-Host "Etape 1 : Chargement de la configuration..." -ForegroundColor Yellow

$ConfigFile = Join-Path $ScriptDir "config.ps1"
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

# --- 2. LECTURE CSV ---
Write-Host "Etape 2 : Lecture de po_list.csv..." -ForegroundColor Yellow

$CsvPath = Join-Path $ScriptDir "po_list.csv"
if (-not (Test-Path $CsvPath)) {
    Write-Host "[ERREUR] po_list.csv introuvable : $CsvPath" -ForegroundColor Red
    pause; exit 1
}

# Lire toutes les lignes non vides, ignorer l'entete si present (PO_NUMBER)
$poNumbers = Get-Content $CsvPath -Encoding UTF8 |
             Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^PO_NUMBER$' } |
             ForEach-Object { $_.Trim() }

$nbTotal = $poNumbers.Count
if ($nbTotal -eq 0) {
    Write-Host "[ERREUR] Aucun numero de commande trouve dans po_list.csv" -ForegroundColor Red
    pause; exit 1
}
Write-Host "   Commandes trouvees : $nbTotal" -ForegroundColor Green
Write-Host ""

# --- 3. GENERATION SQL ---
Write-Host "Etape 3 : Generation du script SQL..." -ForegroundColor Yellow

$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$FichierSQLTmp = Join-Path $LogDir "ferme_po_${Timestamp}.sql"
$FichierLog    = Join-Path $LogDir "ferme_po_${Timestamp}.log"

# Encodage sans BOM (sqlplus ne supporte pas le BOM UTF-8)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# Construire la liste PL/SQL : 'BC1234', 'BC5678', ...
$poList = ($poNumbers | ForEach-Object { "'$_'" }) -join ", "

$sql  = "SET SERVEROUTPUT ON SIZE UNLIMITED`n"
$sql += "SET FEEDBACK OFF`n"
$sql += "WHENEVER SQLERROR EXIT ROLLBACK`n`n"
$sql += "DECLARE`n"
$sql += "    v_user_id           NUMBER := $FND_USER_ID;`n"
$sql += "    v_resp_id           NUMBER := $FND_RESP_ID;`n"
$sql += "    v_resp_app_id       NUMBER := $FND_RESP_APPL_ID;`n"
$sql += "    l_po_header_id      NUMBER;`n"
$sql += "    l_po_number         VARCHAR2(30);`n"
$sql += "    l_success_count     NUMBER := 0;`n"
$sql += "    l_error_count       NUMBER := 0;`n"
$sql += "    l_not_found_count   NUMBER := 0;`n"
$sql += "    l_already_count     NUMBER := 0;`n"
$sql += "    l_total_count       NUMBER := $nbTotal;`n"
$sql += "    TYPE t_po_list IS TABLE OF VARCHAR2(30);`n"
$sql += "    l_po_numbers t_po_list;`n"
$sql += "BEGIN`n`n"
$sql += "    FND_GLOBAL.APPS_INITIALIZE(v_user_id, v_resp_id, v_resp_app_id);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('APPS_INITIALIZE OK - USER=$FND_USER_NAME');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=====================================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('FERMETURE DEFINITIVE DES COMMANDES PO');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('Commandes a traiter : $nbTotal');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=====================================================================');`n`n"

# Construire la liste PL/SQL par lignes de 10 elements max
$lineSize = 10
$lines    = @()
for ($i = 0; $i -lt $poNumbers.Count; $i += $lineSize) {
    $fin    = [Math]::Min($i + $lineSize - 1, $poNumbers.Count - 1)
    $lines += ($poNumbers[$i..$fin] | ForEach-Object { "'$_'" }) -join ", "
}

if ($lines.Count -eq 1) {
    $sql += "    l_po_numbers := t_po_list($($lines[0]));`n`n"
} else {
    $sql += "    l_po_numbers := t_po_list(`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -lt $lines.Count - 1) { $virgule = "," } else { $virgule = "" }
        $sql += "        $($lines[$i])$virgule`n"
    }
    $sql += "    );`n`n"
}

$sql += "    FOR i IN 1..l_po_numbers.COUNT LOOP`n"
$sql += "        l_po_number := l_po_numbers(i);`n"
$sql += "        BEGIN`n"
$sql += "            SELECT PO_HEADER_ID INTO l_po_header_id`n"
$sql += "            FROM PO.PO_HEADERS_ALL`n"
$sql += "            WHERE SEGMENT1 = l_po_number AND ROWNUM = 1;`n`n"
$sql += "            DBMS_OUTPUT.PUT_LINE('[' || i || '/$nbTotal] ' || l_po_number || ' (ID: ' || l_po_header_id || ')');`n`n"
$sql += "            UPDATE PO.PO_HEADERS_ALL`n"
$sql += "            SET    CLOSED_CODE       = 'FINALLY CLOSED',`n"
$sql += "                   CLOSED_DATE       = SYSDATE,`n"
$sql += "                   LAST_UPDATE_DATE  = SYSDATE,`n"
$sql += "                   LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,`n"
$sql += "                   LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID`n"
$sql += "            WHERE  PO_HEADER_ID = l_po_header_id`n"
$sql += "              AND  NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';`n`n"
$sql += "            IF SQL%ROWCOUNT > 0 THEN`n"
$sql += "                UPDATE PO.PO_LINES_ALL`n"
$sql += "                SET    CLOSED_CODE      = 'FINALLY CLOSED',`n"
$sql += "                       CLOSED_DATE      = SYSDATE,`n"
$sql += "                       LAST_UPDATE_DATE = SYSDATE,`n"
$sql += "                       LAST_UPDATED_BY  = FND_GLOBAL.USER_ID`n"
$sql += "                WHERE  PO_HEADER_ID = l_po_header_id`n"
$sql += "                  AND  NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';`n`n"
$sql += "                UPDATE PO.PO_LINE_LOCATIONS_ALL`n"
$sql += "                SET    CLOSED_CODE      = 'FINALLY CLOSED',`n"
$sql += "                       CLOSED_DATE      = SYSDATE,`n"
$sql += "                       LAST_UPDATE_DATE = SYSDATE,`n"
$sql += "                       LAST_UPDATED_BY  = FND_GLOBAL.USER_ID`n"
$sql += "                WHERE  PO_HEADER_ID = l_po_header_id`n"
$sql += "                  AND  NVL(CLOSED_CODE, 'OPEN') != 'FINALLY CLOSED';`n`n"
$sql += "                UPDATE PO.PO_DISTRIBUTIONS_ALL`n"
$sql += "                SET    LAST_UPDATE_DATE = SYSDATE,`n"
$sql += "                       LAST_UPDATED_BY  = FND_GLOBAL.USER_ID`n"
$sql += "                WHERE  PO_HEADER_ID = l_po_header_id;`n`n"
$sql += "                COMMIT;`n"
$sql += "                DBMS_OUTPUT.PUT_LINE('    OK - Fermeture definitive effectuee');`n"
$sql += "                l_success_count := l_success_count + 1;`n"
$sql += "            ELSE`n"
$sql += "                COMMIT;`n"
$sql += "                DBMS_OUTPUT.PUT_LINE('    DEJA FERMEE - Aucune modification');`n"
$sql += "                l_already_count := l_already_count + 1;`n"
$sql += "            END IF;`n`n"
$sql += "        EXCEPTION`n"
$sql += "            WHEN NO_DATA_FOUND THEN`n"
$sql += "                DBMS_OUTPUT.PUT_LINE('[' || i || '/$nbTotal] ' || l_po_number || ' -> NON TROUVEE');`n"
$sql += "                l_not_found_count := l_not_found_count + 1;`n"
$sql += "            WHEN OTHERS THEN`n"
$sql += "                DBMS_OUTPUT.PUT_LINE('[' || i || '/$nbTotal] ' || l_po_number || ' -> ERREUR : ' || SQLERRM);`n"
$sql += "                l_error_count := l_error_count + 1;`n"
$sql += "                ROLLBACK;`n"
$sql += "        END;`n"
$sql += "    END LOOP;`n`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=====================================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('RESUME');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=====================================================================');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  Total traite       : $nbTotal');`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  Fermees            : ' || l_success_count);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  Deja fermees       : ' || l_already_count);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  Non trouvees       : ' || l_not_found_count);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('  Erreurs techniques : ' || l_error_count);`n"
$sql += "    DBMS_OUTPUT.PUT_LINE('=====================================================================');`n"
$sql += "END;`n"
$sql += "/`n`n"
$sql += "EXIT;`n"

[System.IO.File]::WriteAllText($FichierSQLTmp, $sql, $utf8NoBom)
Write-Host "   Script SQL : $FichierSQLTmp" -ForegroundColor Gray
Write-Host ""

# --- 4. EXECUTION ---
Write-Host "Etape 4 : Execution sur Oracle EBS..." -ForegroundColor Yellow
Write-Host "   Fermeture de $nbTotal commande(s) en cours..." -ForegroundColor Gray
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
Write-Host "  FIN - Fermeture Commandes PO" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
pause
