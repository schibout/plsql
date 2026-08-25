#!/bin/bash

# =====================================================================
# Copie locale des dossiers d'instances complets d'un flux.
#
# Usage:
#   ./copier_instances_local.sh [TYPE] [CODE] [DD-MM-YYYY]
#   (sans argument : flux FOURNISSEUR FAC02, date du jour)
#
# Exemples:
#   ./copier_instances_local.sh FOURNISSEUR VHC 21-08-2026
#   ./copier_instances_local.sh CLIENT VHC 21-08-2026
#   ./copier_instances_local.sh GL VHC 21-08-2026
# =====================================================================

set -uo pipefail

FILEREPOSITORY="/data/flf/share/EAIBW/EAI/filerepository"

# ---------------------------------------------------------------------
# Table de correspondance : type et code -> dossier dans filerepository.
# ---------------------------------------------------------------------
resoudre_flux() {
    local code="$1"
    local type="$2"
    local prefixe=""
    local suffixe=""

    # 1. Détermination du suffixe selon le type
    case "$type" in
        "FOURNISSEUR") suffixe="FACTURESFOURNISSEURS" ;;
        "CLIENT")      suffixe="FACTURESCLIENTS" ;;
        "GL")          suffixe="ECRITURESGL" ;;
        *)
            echo "Erreur : type de flux inconnu '$type'."
            exit 1
            ;;
    esac

    # 2. Détermination du préfixe selon le code passé en argument
    case "$code" in
        "BIO"|"FAS"|"FGE"|"GAZ"|"GCA"|"GER"|"HAC"|"IGP"|"ING"|"PAR"|"RNE"|"SVD"|"VTC") 
            prefixe="FAC02" 
            ;;
        "CEL")       prefixe="CEL01" ;;
        "CMB"|"HAF") prefixe="PRN01" ;;
        "CYC"|"CYF") prefixe="HEF01" ;;
        "NOT")       prefixe="NOT01" ;;
        "THO")       prefixe="VCH01" ;;
        "VHC"|"VFF") prefixe="VHC03" ;;
        *)
            # Si le code n'est pas dans la liste, on l'utilise tel quel
            prefixe="$code" 
            ;;
    esac

    FLUX_NAME="${prefixe}.${suffixe}"
}

# --- Fonctions ---

# Trouve les instances creees a la date demandee et copie l'intégralité
# du dossier de l'instance dans le dossier de destination.
copy_and_log_instances() {
    local flux_name="$1"
    local source_dir="$2"
    local dest_dir="$3"

    echo "Recherche pour le flux ${flux_name} dans : ${source_dir}"
    if [ ! -d "$source_dir" ]; then
        echo "Avertissement : Le répertoire source n'existe pas : ${source_dir}"
        return
    fi

    local found_dirs=()
    local search_method="rapide (-newerBt)"

    # --- STRATÉGIE DE RECHERCHE ROBUSTE ---
    while IFS= read -r -d $'\0' dir; do found_dirs+=("$dir"); done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -newerBt "$START_DATE" ! -newerBt "$END_DATE" -print0 2>/dev/null)

    # Essai 2: Méthode de secours si la première n'a rien donné.
    if [ ${#found_dirs[@]} -eq 0 ]; then
        search_method="lente (stat)"
        echo " -> La recherche rapide n'a rien retourné. Passage à la méthode de secours (plus lente)..."

        local candidates=()
        while IFS= read -r -d $'\0' dir; do candidates+=("$dir"); done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -newermt "$START_DATE" ! -newermt "$END_DATE" -print0)

        if [ ${#candidates[@]} -gt 0 ]; then
            echo " -> ${#candidates[@]} dossier(s) candidat(s) trouvé(s). Vérification de leur date de création exacte..."
            for dir in "${candidates[@]}"; do
                birth_timestamp=$(stat -c %W "$dir" 2>/dev/null)

                if [ -n "$birth_timestamp" ] && [ "$birth_timestamp" -ne 0 ]; then
                    birth_date=$(date -d "@$birth_timestamp" "+%Y-%m-%d")
                    if [ "$birth_date" == "$START_DATE" ]; then
                        found_dirs+=("$dir")
                    fi
                fi
            done
        fi
    fi

    if [ ${#found_dirs[@]} -eq 0 ]; then
        echo " -> Aucune instance trouvée pour ${flux_name} pour la date spécifiée."
        echo "---------------------------------------------------------------------"
        return
    fi

    echo " -> ${#found_dirs[@]} instance(s) trouvée(s) pour ${flux_name} (méthode: ${search_method})."
    for dir in "${found_dirs[@]}"; do
        
        echo "  -> Copie de l'instance complète $(basename "$dir") :"
        if cp -rp "$dir" "$dest_dir/"; then
            total_copied_count=$((total_copied_count + 1))
        else
            echo "     !! ECHEC de la copie de l'instance $(basename "$dir")"
        fi

    done
    echo "---------------------------------------------------------------------"
}

# --- Configuration et Validation ---
FLUX_TYPE="FOURNISSEUR"
FLUX_CODE="FAC02"
INPUT_DATE="$(date "+%d-%m-%Y")"

for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        INPUT_DATE="$arg"
    elif [[ "$arg" == "FOURNISSEUR" || "$arg" == "CLIENT" || "$arg" == "GL" ]]; then
        FLUX_TYPE="$arg"
    else
        FLUX_CODE="$arg"
    fi
done

resoudre_flux "$FLUX_CODE" "$FLUX_TYPE"
INSTANCES_DIR="${FILEREPOSITORY}/${FLUX_NAME}/INSTANCES"
# Le suffixe du dossier local contiendra maintenant le type et le code (ex: FOURNISSEUR_VHC)
DEST_SUFFIX="${FLUX_TYPE}_${FLUX_CODE}"

# --- Préparation des variables ---
DAY=${INPUT_DATE:0:2}
MONTH=${INPUT_DATE:3:2}
YEAR=${INPUT_DATE:6:4}

START_DATE="$YEAR-$MONTH-$DAY"
if ! END_DATE=$(date -d "$START_DATE + 1 day" "+%Y-%m-%d" 2>/dev/null); then
    echo "Erreur lors du calcul de la date de fin. Assurez-vous que la date '$INPUT_DATE' est valide."
    exit 1
fi

DEST_DIR_NAME="$(date -d "$START_DATE" "+%d%m%Y")_${DEST_SUFFIX}"

# --- Fichier de log ---
LOG_FILE="copie_${DEST_DIR_NAME}.log"
echo "Les logs de copie seront enregistrés dans le fichier : ./${LOG_FILE}"

{
    echo "Flux              : $FLUX_CODE / $FLUX_TYPE ($FLUX_NAME)"
    echo "Date de recherche : $INPUT_DATE"
    echo "Recherche des instances dont la date de création est le $INPUT_DATE"
    echo "---------------------------------------------------------------------"

    echo "Création du répertoire de destination : ./${DEST_DIR_NAME}"
    mkdir -p "$DEST_DIR_NAME"

    total_copied_count=0

    # --- Copie des dossiers complets ---
    copy_and_log_instances "$FLUX_NAME" "$INSTANCES_DIR" "$DEST_DIR_NAME"

    if [ "$total_copied_count" -eq 0 ]; then
        echo "Aucune instance copiée pour la date du $INPUT_DATE."
        rmdir "$DEST_DIR_NAME" 2>/dev/null
    else
        echo "Opération de copie terminée avec succès."
        echo "$total_copied_count instance(s) copiée(s) dans ./${DEST_DIR_NAME}"
        echo ""
        echo "Étape suivante (Windows) : glisser le dossier SOURCE spécifique de l'instance"
        echo "souhaitée sur ctl_fac02_fournisseur.bat"
    fi

} > "$LOG_FILE" 2>&1

echo "Copie terminée. Consultez ./${LOG_FILE} pour le détail."