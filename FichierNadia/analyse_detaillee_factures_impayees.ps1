# =====================================================================
# Script d'analyse détaillée des factures impayées BO
# =====================================================================
# Ce script lit les fichiers CSV de factures impayées fournis par BO
# et extrait depuis Oracle EBS toutes les informations détaillées :
# - Informations facture (montant, dates, statuts, workflow)
# - Informations fournisseur (nom, site, adresse)
# - Informations paiement (historique complet des paiements)
# - Informations comptables (distributions, comptes GL)
# - Informations commande (PO, réception)
# =====================================================================
# Usage: .\analyse_detaillee_factures_impayees.ps1 [-Annee 2026] [-MaxFactures 100]
# =====================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxFactures = 0,  # 0 = toutes les factures
    
    [Parameter(Mandatory=$false)]
    [string]$FichierBO = ""
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  ANALYSE DÉTAILLÉE DES FACTURES IMPAYÉES BO" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Année d'analyse : $Annee"
Write-Host "Date exécution  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# 1. CHARGEMENT DU FICHIER BO
# =====================================================================
Write-Host "Étape 1 : Chargement du fichier BO..." -ForegroundColor Yellow

if ($FichierBO -eq "") {
    $FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
}

if (-not (Test-Path $FichierBO)) {
    Write-Host "❌ ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    exit 1
}

Write-Host "   Fichier BO : $FichierBO" -ForegroundColor Green

# Charger les factures impayées BO
$FacturesBO = Import-Csv -Path $FichierBO -Delimiter ',' -Encoding UTF8 | Where-Object { $_.ID_FACTURE }

if ($FacturesBO.Count -eq 0) {
    Write-Host "❌ ERREUR: Aucune facture trouvée dans le fichier BO" -ForegroundColor Red
    exit 1
}

$NbFacturesBO = $FacturesBO.Count
Write-Host "   Factures impayées BO : $NbFacturesBO" -ForegroundColor Green

# Limiter le nombre de factures si demandé
if ($MaxFactures -gt 0 -and $NbFacturesBO -gt $MaxFactures) {
    Write-Host "   ⚠️  Limitation à $MaxFactures factures pour l'analyse" -ForegroundColor Yellow
    $FacturesBO = $FacturesBO | Select-Object -First $MaxFactures
    $NbFacturesBO = $MaxFactures
}

# Extraire les IDs de factures
$IDsFactures = $FacturesBO | ForEach-Object { $_.ID_FACTURE } | Where-Object { $_ } | Sort-Object -Unique
$NbIDsUniques = $IDsFactures.Count

Write-Host "   IDs uniques : $NbIDsUniques" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 2. GÉNÉRATION DE LA REQUÊTE SQL DÉTAILLÉE
# =====================================================================
Write-Host "Étape 2 : Génération de la requête SQL..." -ForegroundColor Yellow

# Créer la liste des IDs pour la clause IN
$ListeIDs = $IDsFactures -join ", "

# Chemin du fichier de sortie avec slashes corrects pour Oracle
$FichierSortieSQL = Join-Path $ScriptDir "analyse_detaillee_impayees_${Annee}_${Timestamp}.csv"
$FichierSortieSQL = $FichierSortieSQL.Replace('\', '/')

$RequeteSQL = @"
-- =====================================================================
-- Extraction détaillée des factures impayées BO
-- =====================================================================
-- Date génération : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Année : $Annee
-- Nombre factures : $NbIDsUniques
-- =====================================================================

SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET TRIMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ';'
SET NUMFORMAT 999999999999.99

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

SPOOL $FichierSortieSQL

-- En-tête CSV
PROMPT ID_FACTURE;NUM_FACTURE;TYPE_FACTURE;SOURCE;STATUT_PAIEMENT;STATUT_VALIDATION;WORKFLOW_STATUS;MONTANT_FACTURE;MONTANT_PAYE;MONTANT_RESTANT;DEVISE;DATE_FACTURE;DATE_GL;DATE_ECHEANCE;DATE_ANNULATION;DATE_CREATION;DATE_MAJ;FOURNISSEUR_ID;FOURNISSEUR_NOM;FOURNISSEUR_NUMERO;SITE_FOURNISSEUR_ID;SITE_FOURNISSEUR;ADRESSE_PAIEMENT;CODE_PAIEMENT;ORG_ID;OU_NAME;NB_LIGNES;NB_DISTRIBUTIONS;NB_PAIEMENTS;MONTANT_TOTAL_PAIEMENTS;NB_PAIEMENTS_VALIDES;MONTANT_PAIEMENTS_VALIDES;DERNIER_PAIEMENT_DATE;DERNIER_PAIEMENT_NUM;PO_NUMBER;RECEPTION_NUM;NOTES;CREATED_BY_NAME;LAST_UPDATED_BY_NAME

-- Requête principale
SELECT
    -- Informations facture
    aia.invoice_id || ';' ||
    aia.invoice_num || ';' ||
    aia.invoice_type_lookup_code || ';' ||
    aia.source || ';' ||
    CASE aia.payment_status_flag 
        WHEN 'Y' THEN 'PAYEE'
        WHEN 'P' THEN 'PARTIELLE'
        ELSE 'IMPAYEE'
    END || ';' ||
    aia.validation_request_id || ';' ||
    aia.wfapproval_status || ';' ||
    aia.invoice_amount || ';' ||
    NVL(aia.amount_paid, 0) || ';' ||
    (aia.invoice_amount - NVL(aia.amount_paid, 0)) || ';' ||
    aia.invoice_currency_code || ';' ||
    aia.invoice_date || ';' ||
    aia.gl_date || ';' ||
    aia.terms_date || ';' ||
    aia.cancelled_date || ';' ||
    aia.creation_date || ';' ||
    aia.last_update_date || ';' ||
    
    -- Informations fournisseur
    aia.vendor_id || ';' ||
    aps.vendor_name || ';' ||
    aps.segment1 || ';' ||
    aia.vendor_site_id || ';' ||
    apss.vendor_site_code || ';' ||
    apss.address_line1 || ';' ||
    apss.payment_method_lookup_code || ';' ||
    
    -- Informations organisation
    aia.org_id || ';' ||
    hou.name || ';' ||
    
    -- Statistiques lignes et distributions
    (SELECT COUNT(*) FROM ap_invoice_lines_all ail WHERE ail.invoice_id = aia.invoice_id) || ';' ||
    (SELECT COUNT(*) FROM ap_invoice_distributions_all aid WHERE aid.invoice_id = aia.invoice_id) || ';' ||
    
    -- Statistiques paiements
    (SELECT COUNT(*) 
     FROM ap_invoice_payments_all aip 
     WHERE aip.invoice_id = aia.invoice_id) || ';' ||
    (SELECT NVL(SUM(ac.amount), 0)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id) || ';' ||
    (SELECT COUNT(*) 
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT NVL(SUM(ac.amount), 0)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT MAX(ac.check_date)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    (SELECT MAX(ac.check_number)
     FROM ap_invoice_payments_all aip
     JOIN ap_checks_all ac ON aip.check_id = ac.check_id
     WHERE aip.invoice_id = aia.invoice_id
       AND ac.status_lookup_code != 'VOIDED') || ';' ||
    
    -- Informations commande/réception
    (SELECT LISTAGG(DISTINCT poh.segment1, ', ') WITHIN GROUP (ORDER BY poh.segment1)
     FROM ap_invoice_distributions_all aid
     LEFT JOIN po_distributions_all pod ON aid.po_distribution_id = pod.po_distribution_id
     LEFT JOIN po_headers_all poh ON pod.po_header_id = poh.po_header_id
     WHERE aid.invoice_id = aia.invoice_id
       AND poh.segment1 IS NOT NULL) || ';' ||
    (SELECT LISTAGG(DISTINCT rt.receipt_num, ', ') WITHIN GROUP (ORDER BY rt.receipt_num)
     FROM ap_invoice_distributions_all aid
     LEFT JOIN rcv_transactions rt ON aid.rcv_transaction_id = rt.transaction_id
     WHERE aid.invoice_id = aia.invoice_id
       AND rt.receipt_num IS NOT NULL) || ';' ||
    
    -- Informations audit
    REPLACE(REPLACE(aia.description, CHR(10), ' '), CHR(13), ' ') || ';' ||
    (SELECT fu1.user_name FROM fnd_user fu1 WHERE fu1.user_id = aia.created_by) || ';' ||
    (SELECT fu2.user_name FROM fnd_user fu2 WHERE fu2.user_id = aia.last_updated_by) AS LIGNE
FROM ap_invoices_all aia
LEFT JOIN ap_suppliers aps ON aia.vendor_id = aps.vendor_id
LEFT JOIN ap_supplier_sites_all apss ON aia.vendor_site_id = apss.vendor_site_id
LEFT JOIN hr_operating_units hou ON aia.org_id = hou.organization_id
WHERE aia.invoice_id IN ($ListeIDs)
ORDER BY aia.last_update_date DESC, aia.invoice_id DESC;

SPOOL OFF
EXIT;
"@

$FichierSQL = Join-Path $ScriptDir "temp_analyse_detaillee_impayees.sql"
$RequeteSQL | Out-File -FilePath $FichierSQL -Encoding UTF8

Write-Host "   Script SQL généré : $FichierSQL" -ForegroundColor Green
Write-Host "   Nombre de factures à analyser : $NbIDsUniques" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 3. CONFIGURATION ORACLE
# =====================================================================
Write-Host "Étape 3 : Connexion à Oracle EBS..." -ForegroundColor Yellow

$ORACLE_USER = "aroux"
$ORACLE_PASSWORD = "GAERFTXF"
$ORACLE_HOST = "prdscanc1pdb03.dalkia.net"
$ORACLE_PORT = "1521"
$ORACLE_SERVICE = "ebs_PDBFINP1"
$ORACLE_DSN = "${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"
$CONNECT_STRING = "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"

# Détecter le client SQL
$SQL_CMD = $null
if (Get-Command sqlcl -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sqlcl"
} elseif (Get-Command sql -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sql"
} elseif (Get-Command sqlplus -ErrorAction SilentlyContinue) {
    $SQL_CMD = "sqlplus"
} else {
    Write-Host "❌ ERREUR: Aucun client Oracle trouvé (sqlcl, sql, ou sqlplus)" -ForegroundColor Red
    Remove-Item $FichierSQL -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "   Client SQL : $SQL_CMD" -ForegroundColor Green
Write-Host "   Connexion  : ${ORACLE_USER}@${ORACLE_DSN}" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 4. EXÉCUTION DE LA REQUÊTE
# =====================================================================
Write-Host "Étape 4 : Extraction des données Oracle..." -ForegroundColor Yellow
Write-Host "   ⏳ Cela peut prendre quelques minutes..." -ForegroundColor Yellow
Write-Host ""

$FichierResultat = Join-Path $ScriptDir "analyse_detaillee_impayees_${Annee}_${Timestamp}.csv"

# Exécuter la requête
& $SQL_CMD -S $CONNECT_STRING "@$FichierSQL"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: Échec de l'extraction Oracle" -ForegroundColor Red
    Remove-Item $FichierSQL -ErrorAction SilentlyContinue
    exit 1
}

# Vérifier le fichier résultat
if (-not (Test-Path $FichierResultat)) {
    Write-Host "❌ ERREUR: Fichier résultat non généré" -ForegroundColor Red
    Remove-Item $FichierSQL -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "   ✓ Extraction terminée" -ForegroundColor Green
Write-Host "   Fichier résultat : $FichierResultat" -ForegroundColor Green
Write-Host ""

# Nettoyer le fichier SQL temporaire
Remove-Item $FichierSQL -ErrorAction SilentlyContinue

# =====================================================================
# 5. ANALYSE DES RÉSULTATS
# =====================================================================
Write-Host "Étape 5 : Analyse des résultats..." -ForegroundColor Yellow

# Charger les résultats
$ResultatsOracle = Import-Csv -Path $FichierResultat -Delimiter ';' -Encoding UTF8

$NbResultats = $ResultatsOracle.Count
Write-Host "   Factures extraites : $NbResultats" -ForegroundColor Green

if ($NbResultats -eq 0) {
    Write-Host "   ⚠️  Aucune donnée Oracle trouvée pour ces factures" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Statistiques
$NbPayees = ($ResultatsOracle | Where-Object { $_.STATUT_PAIEMENT -eq 'PAYEE' }).Count
$NbPartielles = ($ResultatsOracle | Where-Object { $_.STATUT_PAIEMENT -eq 'PARTIELLE' }).Count
$NbImpayees = ($ResultatsOracle | Where-Object { $_.STATUT_PAIEMENT -eq 'IMPAYEE' }).Count
$NbAnnulees = ($ResultatsOracle | Where-Object { $_.DATE_ANNULATION -ne '' }).Count

$MontantTotal = ($ResultatsOracle | Measure-Object -Property MONTANT_FACTURE -Sum).Sum
$MontantPaye = ($ResultatsOracle | Measure-Object -Property MONTANT_PAYE -Sum).Sum
$MontantRestant = ($ResultatsOracle | Measure-Object -Property MONTANT_RESTANT -Sum).Sum

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RESULTATS DE L ANALYSE" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Statuts des factures :" -ForegroundColor Yellow
$PctPayees = [math]::Round($NbPayees/$NbResultats*100, 1)
$PctPartielles = [math]::Round($NbPartielles/$NbResultats*100, 1)
$PctImpayees = [math]::Round($NbImpayees/$NbResultats*100, 1)
$PctAnnulees = [math]::Round($NbAnnulees/$NbResultats*100, 1)
Write-Host "  Payees           : $NbPayees ($PctPayees%25)" -ForegroundColor $(if($NbPayees -gt 0){"Yellow"}else{"Green"})
Write-Host "  Partielles       : $NbPartielles ($PctPartielles%25)" -ForegroundColor $(if($NbPartielles -gt 0){"Yellow"}else{"Green"})
Write-Host "  Impayees         : $NbImpayees ($PctImpayees%25)" -ForegroundColor $(if($NbImpayees -gt 0){"Yellow"}else{"Green"})
Write-Host "  Annulees         : $NbAnnulees ($PctAnnulees%25)" -ForegroundColor $(if($NbAnnulees -gt 0){"Yellow"}else{"Green"})
Write-Host ""
Write-Host "Montants (en devise facture) :" -ForegroundColor Yellow
Write-Host "  Total factures   : $([math]::Round($MontantTotal, 2))"
Write-Host "  Total payé       : $([math]::Round($MontantPaye, 2))"
Write-Host "  Total restant    : $([math]::Round($MontantRestant, 2))" -ForegroundColor $(if($MontantRestant -gt 0){"Yellow"}else{"Green"})
Write-Host ""
Write-Host "Top 10 fournisseurs (nb factures) :" -ForegroundColor Yellow
$ResultatsOracle | Group-Object FOURNISSEUR_NOM | 
    Sort-Object Count -Descending | 
    Select-Object -First 10 | 
    ForEach-Object { Write-Host "  $($_.Name): $($_.Count) factures" }
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  FICHIER GÉNÉRÉ" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  $FichierResultat" -ForegroundColor Green
Write-Host "  Taille : $([math]::Round((Get-Item $FichierResultat).Length / 1KB, 2)) Ko"
Write-Host "  Lignes : $NbResultats factures"
Write-Host "  Colonnes : 38 champs détaillés"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Analyse terminée avec succès" -ForegroundColor Green
