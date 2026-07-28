# =====================================================================
# Exécution des scripts SQL de synchronisation
# =====================================================================
# Ce script exécute les ordres SQL via SQLcl/SQLPlus :
#   - BACKUP  : Sauvegarde les données actuelles
#   - UPDATE  : Met à jour last_update_date
#   - RESTORE : Restaure les valeurs originales
#   - STATUS  : Vérifie l'état des factures
# =====================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("BACKUP", "UPDATE", "RESTORE", "STATUS")]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Dossiers
$DossierSQL = Join-Path $ScriptDir "sql_sync"
$DossierBackup = Join-Path $ScriptDir "backup"
$DossierLogs = Join-Path $ScriptDir "logs"

# =====================================================================
# CONFIGURATION ORACLE
# =====================================================================
# SECURITE : Idéalement, utiliser des variables d'environnement ou un wallet Oracle
$ORACLE_USER = $env:ORACLE_USER
$ORACLE_PASSWORD = $env:ORACLE_PASSWORD
$ORACLE_HOST = $env:ORACLE_HOST
$ORACLE_PORT = $env:ORACLE_PORT
$ORACLE_SERVICE = $env:ORACLE_SERVICE

# Valeurs par défaut si variables non définies
if (-not $ORACLE_USER) { $ORACLE_USER = "aroux" }
if (-not $ORACLE_PASSWORD) { $ORACLE_PASSWORD = "GAERFTXF" }
if (-not $ORACLE_HOST) { $ORACLE_HOST = "prdscanc1pdb03.dalkia.net" }
if (-not $ORACLE_PORT) { $ORACLE_PORT = "1521" }
if (-not $ORACLE_SERVICE) { $ORACLE_SERVICE = "ebs_PDBFINP1" }

# Format TNS pour SQL*Plus (plus robuste que Easy Connect)
$TNS_ALIAS = "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$ORACLE_HOST)(PORT=$ORACLE_PORT))(CONNECT_DATA=(SERVICE_NAME=$ORACLE_SERVICE)))"
$CONNECT_STRING = "${ORACLE_USER}/${ORACLE_PASSWORD}@`"$TNS_ALIAS`""

# Format alternatif Easy Connect pour SQLcl
$ORACLE_DSN = "${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"
$CONNECT_STRING_SQLCL = "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  EXECUTION SQL - Action: $Action" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Annee        : $Annee"
Write-Host "Utilisateur  : $ORACLE_USER"
Write-Host "Base         : $ORACLE_DSN"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# DÉTECTION CLIENT SQL
# =====================================================================
$SQL_CMD = $null
$SQL_CONNECT = $null

foreach ($cmd in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $SQL_CMD = $cmd
        # SQLcl utilise Easy Connect, SQL*Plus préfère TNS
        if ($cmd -eq 'sqlplus') {
            $SQL_CONNECT = $CONNECT_STRING
        } else {
            $SQL_CONNECT = $CONNECT_STRING_SQLCL
        }
        Write-Host "Client SQL detecte : $SQL_CMD" -ForegroundColor Green
        break
    }
}

if (-not $SQL_CMD) {
    Write-Host "ERREUR: Aucun client Oracle trouve (sqlcl, sql, sqlplus)" -ForegroundColor Red
    exit 1
}

# =====================================================================
# FONCTION D'EXÉCUTION SQL
# =====================================================================
function Invoke-OracleSQL {
    param(
        [string]$ScriptPath,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host "Execution : $Description" -ForegroundColor Yellow
    Write-Host "Script    : $ScriptPath"
    Write-Host ""
    
    $LogFile = Join-Path $DossierLogs "exec_${Action}_${Annee}_${Timestamp}.log"
    
    # Créer un fichier de login temporaire pour éviter les problèmes de caractères spéciaux
    $LoginFile = Join-Path $env:TEMP "oracle_login_$Timestamp.sql"
    
    try {
        # Méthode 1 : Utiliser un fichier de connexion
        if ($SQL_CMD -eq 'sqlplus') {
            # Pour SQL*Plus, créer un script wrapper
            $WrapperContent = @"
CONNECT ${ORACLE_USER}/${ORACLE_PASSWORD}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${ORACLE_HOST})(PORT=${ORACLE_PORT}))(CONNECT_DATA=(SERVICE_NAME=${ORACLE_SERVICE})))
@$ScriptPath
"@
            $WrapperFile = Join-Path $env:TEMP "wrapper_$Timestamp.sql"
            $WrapperContent | Out-File -FilePath $WrapperFile -Encoding ASCII
            
            $process = Start-Process -FilePath $SQL_CMD -ArgumentList "/nolog", "@$WrapperFile" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err"
            
            # Nettoyer
            Remove-Item $WrapperFile -Force -ErrorAction SilentlyContinue
        }
        else {
            # Pour SQLcl, connexion directe
            $process = Start-Process -FilePath $SQL_CMD -ArgumentList "-S", $SQL_CONNECT, "@$ScriptPath" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err"
        }
        
        # Afficher le contenu du log
        if (Test-Path $LogFile) {
            $LogContent = Get-Content $LogFile -Raw -ErrorAction SilentlyContinue
            if ($LogContent) {
                Write-Host $LogContent
            }
        }
        if (Test-Path "$LogFile.err") {
            $ErrContent = Get-Content "$LogFile.err" -Raw -ErrorAction SilentlyContinue
            if ($ErrContent -and $ErrContent.Trim() -ne "") {
                Write-Host "STDERR: $ErrContent" -ForegroundColor Red
            }
        }
        
        if ($process.ExitCode -ne 0) {
            Write-Host "ERREUR: Code retour $($process.ExitCode)" -ForegroundColor Red
            Write-Host "Voir log : $LogFile" -ForegroundColor Yellow
            return $false
        }
        
        Write-Host ""
        Write-Host "OK - Log enregistre : $LogFile" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item $LoginFile -Force -ErrorAction SilentlyContinue
    }
}

# =====================================================================
# ACTION: BACKUP
# =====================================================================
if ($Action -eq "BACKUP") {
    $ScriptSQL = Join-Path $DossierSQL "01_sauvegarde_$Annee.sql"
    
    if (-not (Test-Path $ScriptSQL)) {
        Write-Host "ERREUR: Script de sauvegarde introuvable : $ScriptSQL" -ForegroundColor Red
        Write-Host "Executez d'abord : generer_scripts_sync.ps1 -Annee $Annee" -ForegroundColor Yellow
        exit 1
    }
    
    $Result = Invoke-OracleSQL -ScriptPath $ScriptSQL -Description "Sauvegarde des donnees actuelles"
    
    if ($Result) {
        # Vérifier que le fichier CSV a été créé
        $FichierBackup = Get-ChildItem -Path $DossierBackup -Filter "sauvegarde_factures_${Annee}_*.csv" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($FichierBackup) {
            $NbLignes = (Get-Content $FichierBackup.FullName | Measure-Object -Line).Lines - 1
            Write-Host ""
            Write-Host "Sauvegarde creee : $($FichierBackup.Name)" -ForegroundColor Green
            Write-Host "Nombre de factures sauvegardees : $NbLignes" -ForegroundColor Green
        }
        exit 0
    }
    exit 1
}

# =====================================================================
# ACTION: UPDATE
# =====================================================================
if ($Action -eq "UPDATE") {
    $ScriptSQL = Join-Path $DossierSQL "02_update_sync_$Annee.sql"
    
    if (-not (Test-Path $ScriptSQL)) {
        Write-Host "ERREUR: Script de mise a jour introuvable : $ScriptSQL" -ForegroundColor Red
        exit 1
    }
    
    # Vérifier qu'une sauvegarde existe
    $FichierBackup = Get-ChildItem -Path $DossierBackup -Filter "sauvegarde_factures_${Annee}_*.csv" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if (-not $FichierBackup) {
        Write-Host "ATTENTION: Aucune sauvegarde trouvee pour $Annee" -ForegroundColor Red
        Write-Host "Voulez-vous continuer sans sauvegarde ? (O/N)" -ForegroundColor Yellow
        $Reponse = Read-Host
        if ($Reponse -ne "O" -and $Reponse -ne "o") {
            Write-Host "Annule. Executez d'abord BACKUP." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Sauvegarde existante : $($FichierBackup.Name)" -ForegroundColor Green
    }
    
    $Result = Invoke-OracleSQL -ScriptPath $ScriptSQL -Description "Mise a jour last_update_date"
    
    if ($Result) {
        Write-Host ""
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host "  MISE A JOUR TERMINEE" -ForegroundColor Green
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Les factures ont ete mises a jour avec last_update_date = hier."
        Write-Host "Le batch BO de ce soir devrait les synchroniser."
        Write-Host ""
        Write-Host "IMPORTANT : Demain, executez :" -ForegroundColor Yellow
        Write-Host "   sync_factures_bo.bat RESTORE $Annee" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    exit 1
}

# =====================================================================
# ACTION: RESTORE
# =====================================================================
if ($Action -eq "RESTORE") {
    Write-Host "Recherche du fichier de sauvegarde..." -ForegroundColor Yellow
    
    # Trouver le fichier de sauvegarde le plus récent
    $FichierBackup = Get-ChildItem -Path $DossierBackup -Filter "sauvegarde_factures_${Annee}_*.csv" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if (-not $FichierBackup) {
        Write-Host "ERREUR: Aucune sauvegarde trouvee pour l'annee $Annee" -ForegroundColor Red
        Write-Host "Dossier recherche : $DossierBackup" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Fichier de sauvegarde : $($FichierBackup.Name)" -ForegroundColor Green
    
    # Lire le CSV et générer le script de restauration
    Write-Host "Generation du script de restauration dynamique..." -ForegroundColor Yellow
    
    $Sauvegardes = Import-Csv -Path $FichierBackup.FullName -Delimiter ';' -Encoding UTF8 | 
        Where-Object { $_.INVOICE_ID -and $_.INVOICE_ID -match '^\d+$' }
    
    $NbFactures = $Sauvegardes.Count
    Write-Host "Factures a restaurer : $NbFactures" -ForegroundColor Green
    
    # Générer le script de restauration dynamique
    $ScriptRestoreDyn = Join-Path $DossierSQL "03_restore_${Annee}_${Timestamp}.sql"
    
    $SQLContent = @"
-- =====================================================================
-- SCRIPT DE RESTAURATION DYNAMIQUE
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Fichier source : $($FichierBackup.Name)
-- Factures a restaurer : $NbFactures
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEBUT RESTAURATION ===');
    DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

"@

    # Générer les UPDATE par lots
    $Lot = 0
    foreach ($Facture in $Sauvegardes) {
        $InvoiceID = $Facture.INVOICE_ID
        $DateOriginale = $Facture.LAST_UPDATE_DATE_ORIGINAL
        $UserOriginal = $Facture.LAST_UPDATED_BY_ORIGINAL
        
        if ($DateOriginale -and $DateOriginale -ne "") {
            $SQLContent += @"
    -- Facture $InvoiceID
    UPDATE ap_invoices_all
    SET last_update_date = TO_DATE('$DateOriginale', 'YYYY-MM-DD HH24:MI:SS'),
        last_updated_by = $UserOriginal
    WHERE invoice_id = $InvoiceID;
    v_count := v_count + SQL%ROWCOUNT;

"@
        }
        
        $Lot++
        if ($Lot % 100 -eq 0) {
            $SQLContent += @"
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Lot $Lot : ' || v_count || ' factures restaurees');

"@
        }
    }
    
    $SQLContent += @"
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== RESTAURATION TERMINEE ===');
    DBMS_OUTPUT.PUT_LINE('Total factures restaurees : ' || v_count);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- Verification
SELECT 'Verification terminee' AS RESULTAT FROM DUAL;

EXIT;
"@

    $SQLContent | Out-File -FilePath $ScriptRestoreDyn -Encoding UTF8
    Write-Host "Script genere : $ScriptRestoreDyn" -ForegroundColor Green
    
    # Exécuter la restauration
    $Result = Invoke-OracleSQL -ScriptPath $ScriptRestoreDyn -Description "Restauration des donnees originales"
    
    if ($Result) {
        # Archiver le fichier de sauvegarde
        $ArchivePath = Join-Path $DossierBackup "archive"
        if (-not (Test-Path $ArchivePath)) {
            New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
        }
        Move-Item -Path $FichierBackup.FullName -Destination $ArchivePath -Force
        
        Write-Host ""
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host "  RESTAURATION TERMINEE" -ForegroundColor Green
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Les factures ont ete remises a leur etat initial."
        Write-Host "Fichier de sauvegarde archive dans : $ArchivePath"
        Write-Host ""
        exit 0
    }
    exit 1
}

# =====================================================================
# ACTION: STATUS
# =====================================================================
if ($Action -eq "STATUS") {
    Write-Host "Verification de l'etat des factures..." -ForegroundColor Yellow
    
    # Charger les IDs depuis le fichier BO
    $FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
    if (-not (Test-Path $FichierBO)) {
        Write-Host "ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
        exit 1
    }
    
    $ContenuBrut = Get-Content $FichierBO -First 2 -Encoding UTF8
    $Delimiteur = if ($ContenuBrut[0] -match ';') { ';' } else { ',' }
    
    $FacturesBO = Import-Csv -Path $FichierBO -Delimiter $Delimiteur -Encoding UTF8 | 
        Where-Object { $_.ID_FACTURE -and $_.ID_FACTURE -match '^\d+$' }
    
    $IDsFactures = ($FacturesBO | ForEach-Object { $_.ID_FACTURE } | Sort-Object -Unique | Select-Object -First 100) -join ", "
    
    # Script de vérification
    $ScriptStatus = Join-Path $DossierSQL "status_check_$Timestamp.sql"
    
    $SQLStatus = @"
SET PAGESIZE 100
SET LINESIZE 200
SET FEEDBACK ON

COLUMN INVOICE_ID FORMAT 99999999999
COLUMN INVOICE_NUM FORMAT A25
COLUMN PAYMENT_STATUS_FLAG FORMAT A3
COLUMN LAST_UPDATE_DATE FORMAT A20
COLUMN STATUT FORMAT A15

SELECT 
    invoice_id,
    invoice_num,
    payment_status_flag,
    TO_CHAR(last_update_date, 'DD/MM/YYYY HH24:MI') AS last_update_date,
    CASE 
        WHEN TRUNC(last_update_date) = TRUNC(SYSDATE) - 1 THEN 'MODIFIE_HIER'
        WHEN TRUNC(last_update_date) = TRUNC(SYSDATE) THEN 'MODIFIE_AUJOURD'
        ELSE 'ORIGINAL'
    END AS STATUT
FROM ap_invoices_all
WHERE invoice_id IN ($IDsFactures)
ORDER BY last_update_date DESC;

SELECT 
    'Resume' AS TYPE,
    COUNT(*) AS TOTAL,
    SUM(CASE WHEN TRUNC(last_update_date) = TRUNC(SYSDATE) - 1 THEN 1 ELSE 0 END) AS MODIFIE_HIER,
    SUM(CASE WHEN TRUNC(last_update_date) = TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS MODIFIE_AUJOURD
FROM ap_invoices_all
WHERE invoice_id IN ($IDsFactures);

EXIT;
"@

    $SQLStatus | Out-File -FilePath $ScriptStatus -Encoding UTF8
    
    Invoke-OracleSQL -ScriptPath $ScriptStatus -Description "Verification statut factures"
    
    # Nettoyer
    Remove-Item $ScriptStatus -Force -ErrorAction SilentlyContinue
    
    # Afficher info sauvegarde
    Write-Host ""
    Write-Host "=== FICHIERS DE SAUVEGARDE ===" -ForegroundColor Cyan
    $Backups = Get-ChildItem -Path $DossierBackup -Filter "sauvegarde_factures_${Annee}_*.csv" -ErrorAction SilentlyContinue
    if ($Backups) {
        foreach ($b in $Backups) {
            Write-Host "  - $($b.Name) ($($b.LastWriteTime))" -ForegroundColor Green
        }
    } else {
        Write-Host "  Aucune sauvegarde trouvee pour $Annee" -ForegroundColor Yellow
    }
    
    exit 0
}
