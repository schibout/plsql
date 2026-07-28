#!/bin/bash
# =====================================================================
# Script d'extraction des factures payées Oracle R12
# =====================================================================
# Usage: ./extraction_factures_payees.sh [ANNEE]
# Exemple: ./extraction_factures_payees.sh 2026
#          ./extraction_factures_payees.sh 2025
#          ./extraction_factures_payees.sh (année courante par défaut)
# =====================================================================

# Chargement des variables d'environnement
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Chercher env_oracle.sh d'abord dans le répertoire du script, puis dans HOME
if [ -f "${SCRIPT_DIR}/env_oracle.sh" ]; then
    ENV_FILE="${SCRIPT_DIR}/env_oracle.sh"
elif [ -f "${HOME}/env_oracle.sh" ]; then
    ENV_FILE="${HOME}/env_oracle.sh"
else
    echo "ERREUR: Fichier env_oracle.sh introuvable"
    echo "Cherché dans: ${SCRIPT_DIR}/env_oracle.sh et ${HOME}/env_oracle.sh"
    exit 1
fi

echo "Utilisation du fichier: $ENV_FILE"

# Sourcer directement le fichier env_oracle.sh (c'est un script shell)
# Convertir les fins de ligne Windows si nécessaire
dos2unix "$ENV_FILE" 2>/dev/null || sed -i 's/\r$//' "$ENV_FILE" 2>/dev/null || true

# Charger les variables
source "$ENV_FILE"

# Résoudre les variables composées si nécessaire
if [ -n "$ORACLE_HOST" ] && [ -n "$ORACLE_PORT" ] && [ -n "$ORACLE_SERVICE" ]; then
    export ORACLE_DSN="${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"
    export ORACLE_PROD_CONNECTION="${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}"
fi

# Paramètres
ANNEE=${1:-$(date +%Y)}  # Année par défaut = année courante
DATE_DEBUT="${ANNEE}-01-01"
DATE_FIN="$((ANNEE + 1))-01-01"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${SCRIPT_DIR}/factures_payees_${ANNEE}_${TIMESTAMP}.csv"

echo "======================================================================="
echo "  EXTRACTION FACTURES PAYÉES ORACLE R12"
echo "======================================================================="
echo "Année              : $ANNEE"
echo "Période            : du ${DATE_DEBUT} au ${DATE_FIN}"
echo "Base de données    : ${ORACLE_USER}@${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"
echo "Fichier de sortie  : $OUTPUT_FILE"
echo "======================================================================="

# Vérification connexion
if [ -z "$ORACLE_USER" ] || [ -z "$ORACLE_PASSWORD" ] || [ -z "$ORACLE_HOST" ]; then
    echo "ERREUR: Variables de connexion manquantes dans .env"
    echo "Vérifiez ORACLE_USER, ORACLE_PASSWORD, ORACLE_HOST"
    exit 1
fi

# Construction de la chaîne de connexion
CONNECT_STRING="${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"

# Fichier SQL temporaire
SQL_FILE="${SCRIPT_DIR}/temp_extraction_${ANNEE}.sql"

# Génération du fichier SQL
cat > "$SQL_FILE" << EOF
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET TRIMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING ON
SET COLSEP ';'
SET NUMFORMAT 999999999999.99

-- Configuration format CSV
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

SPOOL ${OUTPUT_FILE}

-- =====================================================================
-- Requête Oracle R12 - Extraction des Factures Payées (VERSION OPTIMISÉE)
-- =====================================================================
-- Date de création : 18/02/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13
--
-- AMÉLIORATION PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Utilisation de JOIN au lieu de EXISTS pour meilleures performances
-- 2. Filtre sur check_date au lieu de last_update_date
-- 3. Colonnes supplémentaires (PAIEMENT_ID, MONTANT_PAIEMENT, DEVISE)
-- 4. Paramétrage par année au lieu de J-1
-- =====================================================================

SELECT    
    aia.invoice_id AS ID_FACTURE,
    aia.invoice_num AS NUM_FACTURE,
    aia.payment_status_flag AS STATUT_PAIEMENT,
    aia.invoice_amount AS MONTANT_FACTURE,
    aia.amount_paid AS MONTANT_PAYE,
    ac.check_id AS PAIEMENT_ID,
    ac.check_number AS NUMERO_PAIEMENT,
    ac.check_date AS DATE_PAIEMENT,
    ac.amount AS MONTANT_PAIEMENT,
    ac.currency_code AS DEVISE,
    aia.last_update_date AS FACTURE_LAST_UPDATE,
    aia.vendor_id AS FOURNISSEUR_ID,
    aia.vendor_site_id AS SITE_FOURNISSEUR_ID
FROM ap_invoices_all aia
JOIN AP_INVOICE_PAYMENTS_all AIP 
    ON aia.INVOICE_ID = AIP.INVOICE_ID
JOIN AP_CHECKS_ALL AC 
    ON AIP.CHECK_ID = AC.CHECK_ID
WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
  AND NVL(aia.AMOUNT_PAID, 0) != 0
  AND aia.invoice_amount != 0
  AND ac.status_lookup_code != 'VOIDED'
  AND ac.check_date >= TO_DATE('${DATE_DEBUT}', 'YYYY-MM-DD')
  AND ac.check_date < TO_DATE('${DATE_FIN}', 'YYYY-MM-DD')
ORDER BY ac.check_date DESC, aia.invoice_id;

SPOOL OFF
EXIT;
EOF

echo ""
echo "Exécution de la requête SQL..."
echo "----------------------------------------------------------------------"

# Détecter quelle commande SQL est disponible
if command -v sqlcl &> /dev/null; then
    SQL_CMD="sqlcl"
elif command -v sql &> /dev/null; then
    SQL_CMD="sql"
elif command -v sqlplus &> /dev/null; then
    SQL_CMD="sqlplus"
else
    echo "❌ ERREUR: Aucun client Oracle trouvé (sqlcl, sql, ou sqlplus)"
    echo "Installez SQLcl ou SQL*Plus"
    rm -f "$SQL_FILE"
    exit 1
fi

echo "Utilisation de: $SQL_CMD"

# Exécution via SQL client
$SQL_CMD -S "$CONNECT_STRING" @"$SQL_FILE"

# Vérification du code retour
if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------------------"
    echo "✅ EXTRACTION TERMINÉE AVEC SUCCÈS"
    echo ""
    
    # Statistiques
    if [ -f "$OUTPUT_FILE" ]; then
        NB_LIGNES=$(wc -l < "$OUTPUT_FILE")
        NB_FACTURES=$((NB_LIGNES - 1))  # -1 pour l'en-tête
        TAILLE_FICHIER=$(du -h "$OUTPUT_FILE" | cut -f1)
        
        echo "Nombre de factures : $NB_FACTURES"
        echo "Taille du fichier  : $TAILLE_FICHIER"
        echo "Fichier généré     : $OUTPUT_FILE"
        
        # Afficher les 5 premières lignes
        echo ""
        echo "Aperçu (5 premières factures) :"
        echo "----------------------------------------------------------------------"
        head -6 "$OUTPUT_FILE"
    else
        echo "⚠️  ATTENTION: Fichier de sortie non généré"
    fi
else
    echo "----------------------------------------------------------------------"
    echo "❌ ERREUR LORS DE L'EXTRACTION"
    echo "Code retour: $?"
fi

# Nettoyage fichier temporaire
rm -f "$SQL_FILE"

echo "======================================================================="
