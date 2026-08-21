#!/bin/bash

# =====================================================================
# Copie locale des fichiers SRC + CTL d'un flux (FAC02 fournisseurs par
# defaut, ou tout autre flux de la table de correspondance ci-dessous).
#
# Usage:
#   ./copier_instances_local.sh [FLUX] [DD-MM-YYYY]
#   (sans argument : flux FAC02_FOURNISSEUR, date du jour)
#
# Exemples:
#   ./copier_instances_local.sh                          # fournisseurs, aujourd'hui
#   ./copier_instances_local.sh 21-08-2026               # fournisseurs, date donnee
#   ./copier_instances_local.sh NOT                      # flux NOT, aujourd'hui
#   ./copier_instances_local.sh VHC 21-08-2026           # flux VHC, date donnee
#
# Description:
# 1. Resout le dossier du flux dans filerepository a partir du code passe
#    en parametre (table de correspondance FLUX_CODE -> dossier).
# 2. Cherche les instances du flux creees a la date demandee.
# 3. Cree un dossier local DDMMYYYY_<FLUX> (ex: 21082026_FAC02_FOURNISSEUR).
# 4. Y copie A PLAT le contenu du sous-dossier SOURCE/ de chaque instance
#    (le fichier de donnees ..._SRC_... et le fichier de controle
#    ..._CTL_...).
# 5. Enregistre toute la copie dans un fichier de log.
#
# Le dossier obtenu se glisse tel quel sur le .bat de controle Windows
# (ex: ctl_fac02_fournisseur.bat) : le rapport Excel est alors genere
# dans rapport\.
# =====================================================================

set -uo pipefail

FILEREPOSITORY="/data/flf/share/EAIBW/EAI/filerepository"

# ---------------------------------------------------------------------
# Table de correspondance : code de flux -> dossier dans filerepository.
# Le code sert aussi de suffixe au dossier de destination DDMMYYYY_<code>.
# Pour ajouter un flux : une ligne dans le case ci-dessous suffit.
# ---------------------------------------------------------------------
resoudre_flux() {
    case "$1" in
        FAC02_FOURNISSEUR|FOURNISSEUR) FLUX_NAME="FAC02.FACTURESFOURNISSEURS" ;;
        FAC02_CLIENT|CLIENT)           FLUX_NAME="FAC02.FACTURESCLIENTS" ;;
        NOT)                           FLUX_NAME="NOT01.FACTURES" ;;
        # ING, VHC et les autres codes folio fournisseurs passent tous par
        # le meme flux : seul le nom du dossier de destination change.
        ING|VHC|GAZ|BIO|HAC)           FLUX_NAME="FAC02.FACTURESFOURNISSEURS" ;;
        *)
            echo "Erreur : flux inconnu '$1'."
            echo "Flux disponibles : FAC02_FOURNISSEUR (defaut), FAC02_CLIENT, NOT, ING, VHC, GAZ, BIO, HAC"
            exit 1
            ;;
    esac
}

# --- Fonctions ---

# Trouve les instances creees a la date demandee et copie le contenu de
# leur sous-dossier SOURCE/ (fichiers SRC + CTL) a plat dans le dossier
# de destination.
# Arguments:
#   $1: Nom du flux (pour les logs)
#   $2: Repertoire INSTANCES du flux
#   $3: Repertoire de destination
#
# Variables globales utilisees:
# - START_DATE, END_DATE : bornes de la recherche par date
# - total_copied_count   : compteur global de fichiers copies
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
    # (mindepth 1 : find renvoie aussi le répertoire de départ lui-même, qui
    # n'est pas une instance)
    while IFS= read -r -d $'\0' dir; do found_dirs+=("$dir"); done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -newerBt "$START_DATE" ! -newerBt "$END_DATE" -print0 2>/dev/null)

    # Essai 2: Méthode de secours si la première n'a rien donné.
    if [ ${#found_dirs[@]} -eq 0 ]; then
        search_method="lente (stat)"
        echo " -> La recherche rapide n'a rien retourné. Passage à la méthode de secours (plus lente)..."

        # a) On récupère les candidats : tous les dossiers modifiés le jour J.
        #    Ceci est un sur-ensemble des dossiers créés le jour J.
        local candidates=()
        while IFS= read -r -d $'\0' dir; do candidates+=("$dir"); done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -newermt "$START_DATE" ! -newermt "$END_DATE" -print0)

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

    if [ ${#found_dirs[@]} -eq 0 ]; then
        echo " -> Aucune instance trouvée pour ${flux_name} pour la date spécifiée."
        echo "---------------------------------------------------------------------"
        return
    fi

    echo " -> ${#found_dirs[@]} instance(s) trouvée(s) pour ${flux_name} (méthode: ${search_method})."
    for dir in "${found_dirs[@]}"; do
        # La copie se limite au sous-dossier SOURCE de l'instance : c'est lui
        # qui porte le fichier de données (SRC) et le fichier de contrôle (CTL).
        # Copie A PLAT dans la destination, pour que le glisser-déposer du
        # dossier sur ctl_fac02_fournisseur.bat trouve directement les CSV.
        local src_subdir="${dir}/SOURCE"
        if [ ! -d "$src_subdir" ]; then
            echo "  !! Instance sans sous-dossier SOURCE, ignorée : $(basename "$dir")"
            continue
        fi
        echo "  -> Instance $(basename "$dir") :"
        local copied_any=0
        for f in "$src_subdir"/*; do
            [ -f "$f" ] || continue
            echo "     copie de $(basename "$f")"
            # -p : préserve les timestamps (le .bat prend le SRC le plus récent)
            if cp -p "$f" "$dest_dir/"; then
                total_copied_count=$((total_copied_count + 1))
                copied_any=1
            else
                echo "     !! ECHEC de la copie de $(basename "$f")"
            fi
        done
        if [ "$copied_any" -eq 0 ]; then
            echo "     !! Aucun fichier dans ${src_subdir}"
        fi
    done
    echo "---------------------------------------------------------------------"
}

# --- Configuration et Validation ---
# Arguments libres : [FLUX] [DD-MM-YYYY]. Un argument qui ressemble a une
# date est la date ; sinon c'est le code de flux. Defauts : flux
# FAC02_FOURNISSEUR, date du jour (cas courant, lance le jour du flux).
FLUX_CODE="FAC02_FOURNISSEUR"
INPUT_DATE="$(date "+%d-%m-%Y")"
for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        INPUT_DATE="$arg"
    else
        FLUX_CODE="$arg"
    fi
done

resoudre_flux "$FLUX_CODE"
INSTANCES_DIR="${FILEREPOSITORY}/${FLUX_NAME}/INSTANCES"
DEST_SUFFIX="$FLUX_CODE"

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

DEST_DIR_NAME="$(date -d "$START_DATE" "+%d%m%Y")_${DEST_SUFFIX}"

# --- Fichier de log ---
LOG_FILE="copie_${DEST_DIR_NAME}.log"
echo "Les logs de copie seront enregistrés dans le fichier : ./${LOG_FILE}"

# Redirige toute la sortie (stdout et stderr) du bloc de code ci-dessous vers le fichier de log.
{
    echo "Flux              : $FLUX_CODE ($FLUX_NAME)"
    echo "Date de recherche : $INPUT_DATE"
    echo "Recherche des instances dont la date de création est le $INPUT_DATE"
    echo "---------------------------------------------------------------------"

    echo "Création du répertoire de destination : ./${DEST_DIR_NAME}"
    mkdir -p "$DEST_DIR_NAME"

    # Compteur global pour la fonction copy_and_log_instances
    total_copied_count=0

    # --- Copie des fichiers SRC + CTL ---
    copy_and_log_instances "$FLUX_NAME" "$INSTANCES_DIR" "$DEST_DIR_NAME"

    # Vérification si des fichiers ont été copiés au total
    if [ "$total_copied_count" -eq 0 ]; then
        echo "Aucun fichier copié pour la date du $INPUT_DATE."
        rmdir "$DEST_DIR_NAME" 2>/dev/null
    else
        echo "Opération de copie terminée avec succès."
        echo "$total_copied_count fichier(s) copié(s) dans ./${DEST_DIR_NAME}"
        echo ""
        echo "Étape suivante (Windows) : glisser le dossier ${DEST_DIR_NAME} sur"
        echo "ctl_fac02_fournisseur.bat — le rapport Excel est généré dans rapport\\."
    fi

} > "$LOG_FILE" 2>&1

echo "Copie terminée. Consultez ./${LOG_FILE} pour le détail."
