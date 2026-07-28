#!/bin/bash

# =====================================================================
# Script pour copier les dossiers d'instances de flux pour une date donnée.
#
# Usage:
#   ./copier_instances_virement.sh DD-MM-YYYY
#
# Exemple:
#   ./copier_instances_virement.sh 23-06-2026
#
# Description:
# 1. Prend une date au format DD-MM-YYYY en argument.
# 2. Cherche dans les répertoires sources les dossiers créés à cette date.
# 3. Crée des sous-répertoires locaux nommés DDMMYYYY_source et DDMMYYYY_cible.
# 4. Copie les dossiers trouvés dans les répertoires de destination respectifs.
# 5. Enregistre toute la copie dans un fichier de log.
# =====================================================================

set -uo pipefail

# --- Fonctions ---

# Fonction pour trouver et copier les instances pour un flux donné.
# Arguments:
#   $1: Nom du flux (pour les logs, ex: "FIN01.VIREMENT")
#   $2: Répertoire source
#   $3: Répertoire de destination
#
# Cette fonction utilise les variables globales:
# - START_DATE, END_DATE: pour la recherche par date
# - total_copied_count: compteur global pour le nombre de dossiers copiés
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
    # Essai 1: Méthode rapide avec -newerBt. C'est la plus performante, mais elle
    # n'est pas toujours supportée par le système de fichiers. Si elle ne renvoie
    # rien, on passe à la méthode de secours.
    while IFS= read -r -d $'\0' dir; do found_dirs+=("$dir"); done < <(find "$source_dir" -maxdepth 1 -type d -newerBt "$START_DATE" ! -newerBt "$END_DATE" -print0 2>/dev/null)

    # Essai 2: Méthode de secours si la première n'a rien donné.
    if [ ${#found_dirs[@]} -eq 0 ]; then
        search_method="lente (stat)"
        echo " -> La recherche rapide n'a rien retourné. Passage à la méthode de secours (plus lente)..."
        
        # a) On récupère les candidats : tous les dossiers modifiés le jour J.
        #    Ceci est un sur-ensemble des dossiers créés le jour J.
        local candidates=()
        while IFS= read -r -d $'\0' dir; do candidates+=("$dir"); done < <(find "$source_dir" -maxdepth 1 -type d -newermt "$START_DATE" ! -newermt "$END_DATE" -print0)

        if [ ${#candidates[@]} -gt 0 ]; then
            echo " -> ${#candidates[@]} dossier(s) candidat(s) trouvé(s). Vérification de leur date de création exacte..."
            # b) On filtre les candidats en vérifiant leur date de création avec 'stat'.
            for dir in "${candidates[@]}"; do
                # %W = date de création en secondes depuis l'Epoch. Retourne 0 si non supporté.
                birth_timestamp=$(stat -c %W "$dir" 2>/dev/null)

                # On ne traite que si la date de création est supportée et valide.
                if [ -n "$birth_timestamp" ] && [ "$birth_timestamp" -ne 0 ]; then
                    birth_date=$(date -d "@$birth_timestamp" "+%Y-%m-%d")
                    if [ "$birth_date" == "$START_DATE" ]; then
                        found_dirs+=("$dir")
                    fi
                fi
            done
        fi
    fi

    if [ ${#found_dirs[@]} -gt 0 ]; then
        echo " -> ${#found_dirs[@]} dossier(s) trouvé(s) pour ${flux_name} (méthode: ${search_method}). Copie vers ${dest_dir}..."
        for dir in "${found_dirs[@]}"; do
            echo "  -> Copie de $(basename "$dir")"
            # Utilise -a (archive) pour préserver les permissions et timestamps, équivalent à -rlptgoD
            if cp -a "$dir" "$dest_dir/"; then
                total_copied_count=$((total_copied_count + 1))
            else
                echo "  !! ECHEC de la copie de $(basename "$dir")"
            fi
        done
    else
        echo " -> Aucun dossier trouvé pour ${flux_name} pour la date spécifiée."
    fi
    echo "---------------------------------------------------------------------"
}

# --- Configuration et Validation ---
INPUT_DATE="${1:-}"

# --- Validation du paramètre ---
if [ -z "$INPUT_DATE" ]; then
    echo "Erreur : Vous devez fournir une date en paramètre."
    echo "Usage: $0 DD-MM-YYYY"
    echo "Exemple: $0 23-06-2026"
    exit 1
fi

# Regex pour valider le format de la date DD-MM-YYYY
if ! [[ "$INPUT_DATE" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    echo "Erreur : Le format de la date '$INPUT_DATE' est invalide."
    echo "Veuillez utiliser le format DD-MM-YYYY."
    exit 1
fi

# --- Préparation des variables ---
DAY=${INPUT_DATE:0:2}
MONTH=${INPUT_DATE:3:2}
YEAR=${INPUT_DATE:6:4}

START_DATE="$YEAR-$MONTH-$DAY"
# Gérer le cas où `date` échoue (date invalide, ex: 31-02-2026)
if ! END_DATE=$(date -d "$START_DATE + 1 day" "+%Y-%m-%d" 2>/dev/null); then
    echo "Erreur lors du calcul de la date de fin. Assurez-vous que la date '$INPUT_DATE' est valide."
    exit 1
fi

DEST_DIR_NAME_BASE=$(date -d "$START_DATE" "+%d%m%Y")
DEST_DIR_SOURCE_NAME="${DEST_DIR_NAME_BASE}_source"
DEST_DIR_CIBLE_NAME="${DEST_DIR_NAME_BASE}_cible"

# --- Fichier de log ---
LOG_FILE="copie_${DEST_DIR_NAME_BASE}.log"
echo "Les logs de copie seront enregistrés dans le fichier : ./${LOG_FILE}"

# Redirige toute la sortie (stdout et stderr) du bloc de code ci-dessous vers le fichier de log.
{
    echo "Date de recherche : $INPUT_DATE"
    echo "Recherche des dossiers dont la date de création est le $INPUT_DATE"
    echo "---------------------------------------------------------------------"

    echo "Création des répertoires de destination :"
    echo " -> ./${DEST_DIR_SOURCE_NAME}"
    mkdir -p "$DEST_DIR_SOURCE_NAME"
    echo " -> ./${DEST_DIR_CIBLE_NAME}"
    mkdir -p "$DEST_DIR_CIBLE_NAME"

    # Compteur global pour la fonction copy_and_log_instances
    total_copied_count=0

    # --- Copie des instances ---
    SOURCE_DIR_FIN01="/data/flf/share/EAIBW/EAI/filerepository/FIN01.VIREMENT/INSTANCES"
    copy_and_log_instances "FIN01.VIREMENT" "$SOURCE_DIR_FIN01" "$DEST_DIR_SOURCE_NAME"

    SOURCE_DIR_EDF01="/data/flf/share/EAIBW/EAI/filerepository/VIREMENT.EDF01/INSTANCES"
    copy_and_log_instances "VIREMENT.EDF01 (cible)" "$SOURCE_DIR_EDF01" "$DEST_DIR_CIBLE_NAME"

    # Vérification si des dossiers ont été copiés au total
    if [ "$total_copied_count" -eq 0 ]; then
        echo "Aucun dossier trouvé pour la date du $INPUT_DATE sur l'ensemble des flux."
        rmdir "$DEST_DIR_SOURCE_NAME" 2>/dev/null
        rmdir "$DEST_DIR_CIBLE_NAME" 2>/dev/null
    else
        echo "Opération de copie terminée avec succès."
        echo "$total_copied_count dossier(s) ont été copiés dans les répertoires de destination."
    fi

} > "$LOG_FILE" 2>&1

echo "Copie terminée. Consultez ./${LOG_FILE} pour le détail."
