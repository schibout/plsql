# =====================================================================
# Script de réconciliation factures payées Oracle vs BO
# =====================================================================
# Ce script compare les factures payées extraites d'Oracle R12 avec
# les factures marquées impayées dans BO et génère :
# 1. Un rapport des écarts détectés
# 2. Un script SQL de mise à jour pour corriger BO
# =====================================================================
# Usage: .\reconciliation_factures.ps1 -Annee 2026
# =====================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RÉCONCILIATION FACTURES PAYÉES ORACLE R12 vs BO" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Année d'analyse : $Annee"
Write-Host "Date exécution  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# 1. CHARGEMENT DES FACTURES PAYÉES ORACLE (extraction récente)
# =====================================================================
Write-Host "Étape 1 : Recherche des factures payées Oracle..." -ForegroundColor Yellow

# Trouver le fichier d'extraction le plus récent pour l'année
$FichierOracle = Get-ChildItem -Path $ScriptDir -Filter "factures_payees_${Annee}_*.csv" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if (-not $FichierOracle) {
    Write-Host "❌ ERREUR: Aucun fichier d'extraction Oracle trouvé pour $Annee" -ForegroundColor Red
    Write-Host "Exécutez d'abord: .\extraction_factures_payees.ps1 -Annee $Annee" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Fichier Oracle : $($FichierOracle.Name)" -ForegroundColor Green
Write-Host "   Date extraction : $($FichierOracle.LastWriteTime)" -ForegroundColor Green

# Charger les factures payées Oracle
$FacturesPayeesOracle = Import-Csv -Path $FichierOracle.FullName -Delimiter ';' -Encoding UTF8
$NbFacturesOracle = $FacturesPayeesOracle.Count

Write-Host "   Factures payées Oracle : $NbFacturesOracle" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 2. CHARGEMENT DES FACTURES IMPAYÉES BO
# =====================================================================
Write-Host "Étape 2 : Chargement des factures impayées BO..." -ForegroundColor Yellow

$RepertoireBO = Join-Path $ScriptDir "factureImpayees"
$FichierBO = Join-Path $RepertoireBO "Factures impayees BO ${Annee}.csv"

if (-not (Test-Path $FichierBO)) {
    Write-Host "❌ ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    Write-Host "Veuillez placer le fichier d'extraction BO dans : $RepertoireBO" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Fichier BO : $(Split-Path -Leaf $FichierBO)" -ForegroundColor Green

# Charger les factures impayées BO
$FacturesImpayeesBO = Import-Csv -Path $FichierBO -Delimiter ';' -Encoding UTF8
$NbFacturesBO = $FacturesImpayeesBO.Count

Write-Host "   Factures impayées BO : $NbFacturesBO" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 3. DÉTECTION DES ÉCARTS (factures payées Oracle mais impayées BO)
# =====================================================================
Write-Host "Étape 3 : Détection des écarts..." -ForegroundColor Yellow

# Créer un hashtable pour recherche rapide
$HashOracle = @{}
foreach ($facture in $FacturesPayeesOracle) {
    if ($facture.ID_FACTURE) {
        $HashOracle[$facture.ID_FACTURE] = $facture
    }
}

# Comparer et détecter les écarts
$Ecarts = @()
foreach ($factureBO in $FacturesImpayeesBO) {
    $idFacture = $factureBO.ID_FACTURE
    
    # Ignorer les lignes avec ID_FACTURE vide ou null
    if (-not $idFacture) {
        continue
    }
    
    if ($HashOracle.ContainsKey($idFacture)) {
        # ÉCART DÉTECTÉ : facture payée dans Oracle mais impayée dans BO
        $factureOracle = $HashOracle[$idFacture]
        
        $Ecarts += [PSCustomObject]@{
            ID_FACTURE = $idFacture
            NUM_FACTURE = $factureOracle.NUM_FACTURE
            STATUT_BO = $factureBO.statut_paiement
            STATUT_ORACLE = "PAYEE"
            TYPE_FACTURE_BO = $factureBO.type_facture
            DATE_FACTURE = $factureBO.DATE_FACTURE
            DATE_PAIEMENT_ORACLE = $factureOracle.DATE_PAIEMENT
            MONTANT_FACTURE = $factureBO.MONTANT_FACTURE
            MONTANT_PAIEMENT_ORACLE = $factureOracle.MONTANT_PAIEMENT
            DEVISE = $factureOracle.DEVISE
            NUMERO_PAIEMENT = $factureOracle.NUMERO_PAIEMENT
            PAIEMENT_ID = $factureOracle.PAIEMENT_ID
            TYPE_ECART = if ($idFacture -and $factureOracle.NUM_FACTURE) { 
                "STATUT_INCORRECT" 
            } else { 
                "DONNEES_INCOMPLETES" 
            }
        }
    }
}

$NbEcarts = $Ecarts.Count

if ($NbEcarts -eq 0) {
    Write-Host "   ✅ Aucun écart détecté - Synchronisation parfaite !" -ForegroundColor Green
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    exit 0
}

Write-Host "   ⚠️  $NbEcarts écart(s) détecté(s)" -ForegroundColor Yellow
Write-Host "   Taux d'écart : $([math]::Round($NbEcarts / $NbFacturesOracle * 100, 2))%" -ForegroundColor Yellow
Write-Host ""

# =====================================================================
# 4. GÉNÉRATION DU RAPPORT D'ÉCARTS (CSV)
# =====================================================================
Write-Host "Étape 4 : Génération du rapport d'écarts..." -ForegroundColor Yellow

$RapportEcarts = Join-Path $ScriptDir "rapport_ecarts_${Annee}_${Timestamp}.csv"
$Ecarts | Export-Csv -Path $RapportEcarts -Delimiter ';' -Encoding UTF8 -NoTypeInformation

Write-Host "   Rapport généré : $(Split-Path -Leaf $RapportEcarts)" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 5. GÉNÉRATION DU SCRIPT SQL DE MISE À JOUR
# =====================================================================
Write-Host "Étape 5 : Génération du script SQL de mise à jour..." -ForegroundColor Yellow

$ScriptSQL = Join-Path $ScriptDir "maj_factures_bo_${Annee}_${Timestamp}.sql"

# En-tête SQL
$SqlContent = @"
-- =====================================================================
-- Script de mise à jour des statuts de factures dans BO
-- =====================================================================
-- Date de génération : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Année : $Annee
-- Nombre d'écarts : $NbEcarts
-- Rapport d'analyse : $(Split-Path -Leaf $RapportEcarts)
-- =====================================================================
-- IMPORTANT : EXÉCUTER APRÈS VALIDATION MÉTIER
-- =====================================================================

SET SERVEROUTPUT ON;
SET ECHO ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Sauvegarde avant mise à jour
CREATE TABLE FINANCE.BACKUP_DWH_ECHEANCIER_$(Get-Date -Format 'yyyyMMdd_HHmmss') AS
SELECT * FROM FINANCE.DWH_ECHEANCIER_AP
WHERE ID_FACTURE IN (
$($Ecarts | ForEach-Object { "    " + $_.ID_FACTURE } | Select-Object -First 50 | Join-String -Separator ",`n")
$(if ($NbEcarts -gt 50) { ",`n    -- ... et $($NbEcarts - 50) autres factures" } else { "" })
);

-- Statistiques avant mise à jour
SELECT 
    'AVANT MAJ' AS PHASE,
    statut_paiement,
    COUNT(*) AS NB_FACTURES
FROM FINANCE.DWH_ECHEANCIER_AP
WHERE ID_FACTURE IN (
$($Ecarts | ForEach-Object { "    " + $_.ID_FACTURE } | Select-Object -First 50 | Join-String -Separator ",`n")
$(if ($NbEcarts -gt 50) { ",`n    -- ... et $($NbEcarts - 50) autres factures" } else { "" })
)
GROUP BY statut_paiement;

-- Mises à jour par facture avec logging
DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Début mise à jour : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    
"@

# Générer les UPDATE pour chaque écart
foreach ($ecart in $Ecarts) {
    $SqlContent += @"

    -- Facture : $($ecart.NUM_FACTURE) (ID: $($ecart.ID_FACTURE))
    UPDATE FINANCE.DWH_ECHEANCIER_AP
    SET statut_paiement = 'PAYEE',
        date_maj_statut = SYSDATE,
        source_maj = 'RECONCILIATION_ORACLE_${Annee}',
        commentaire_maj = 'Paiement $($ecart.NUMERO_PAIEMENT) du $($ecart.DATE_PAIEMENT_ORACLE)'
    WHERE ID_FACTURE = $($ecart.ID_FACTURE)
      AND statut_paiement <> 'PAYEE';
    
    v_count := v_count + SQL%ROWCOUNT;
    
    IF MOD(v_count, 100) = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ' || v_count || ' factures mises à jour...');
        COMMIT;
    END IF;
"@
}

# Finalisation du script SQL
$SqlContent += @"

    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Fin mise à jour : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Total factures mises à jour : ' || v_count);
    
    -- Statistiques après mise à jour
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== STATISTIQUES APRÈS MAJ ===');
    
    FOR rec IN (
        SELECT 
            statut_paiement,
            COUNT(*) AS NB_FACTURES
        FROM FINANCE.DWH_ECHEANCIER_AP
        WHERE ID_FACTURE IN (
$($Ecarts | ForEach-Object { "            " + $_.ID_FACTURE } | Select-Object -First 50 | Join-String -Separator ",`n")
$(if ($NbEcarts -gt 50) { ",`n            -- ... et $($NbEcarts - 50) autres factures" } else { "" })
        )
        GROUP BY statut_paiement
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || rec.statut_paiement || ' : ' || rec.NB_FACTURES);
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        RAISE;
END;
/

-- Vérification finale
SELECT 
    'APRES MAJ' AS PHASE,
    statut_paiement,
    COUNT(*) AS NB_FACTURES
FROM FINANCE.DWH_ECHEANCIER_AP
WHERE ID_FACTURE IN (
$($Ecarts | ForEach-Object { "    " + $_.ID_FACTURE } | Select-Object -First 50 | Join-String -Separator ",`n")
$(if ($NbEcarts -gt 50) { ",`n    -- ... et $($NbEcarts - 50) autres factures" } else { "" })
)
GROUP BY statut_paiement;

-- =====================================================================
-- FIN DU SCRIPT
-- =====================================================================
PROMPT Mise à jour terminée avec succès !
EXIT;
"@

# Sauvegarder le script SQL
$SqlContent | Out-File -FilePath $ScriptSQL -Encoding UTF8

Write-Host "   Script SQL généré : $(Split-Path -Leaf $ScriptSQL)" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 6. RAPPORT FINAL
# =====================================================================
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RÉSUMÉ DE L'ANALYSE" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Factures payées Oracle (${Annee})  : $NbFacturesOracle" -ForegroundColor White
Write-Host "Factures impayées BO (${Annee})    : $NbFacturesBO" -ForegroundColor White
Write-Host "Écarts détectés                    : $NbEcarts" -ForegroundColor $(if ($NbEcarts -gt 0) { "Yellow" } else { "Green" })
Write-Host "Taux d'écart                       : $([math]::Round($NbEcarts / $NbFacturesOracle * 100, 2))%" -ForegroundColor $(if ($NbEcarts -gt 10) { "Red" } elseif ($NbEcarts -gt 0) { "Yellow" } else { "Green" })
Write-Host ""
Write-Host "Fichiers générés :" -ForegroundColor Cyan
Write-Host "  - Rapport CSV : $RapportEcarts" -ForegroundColor White
Write-Host "  - Script SQL  : $ScriptSQL" -ForegroundColor White
Write-Host ""

if ($NbEcarts -gt 0) {
    Write-Host "Top 10 des écarts détectés :" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow
    $Ecarts | Select-Object -First 10 | Format-Table ID_FACTURE, NUM_FACTURE, DATE_PAIEMENT_ORACLE, MONTANT_PAIEMENT_ORACLE, DEVISE -AutoSize
    
    Write-Host ""
    Write-Host "PROCHAINES ÉTAPES :" -ForegroundColor Cyan
    Write-Host "  1. Vérifier le rapport CSV : $RapportEcarts" -ForegroundColor White
    Write-Host "  2. Valider avec l'équipe métier (Hind, Nadia)" -ForegroundColor White
    Write-Host "  3. Exécuter le script SQL sur la base BO :" -ForegroundColor White
    Write-Host "     sqlplus user/pass@bo @$ScriptSQL" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=======================================================================" -ForegroundColor Cyan
