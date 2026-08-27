#!/bin/bash

# =====================================================================
# Copie locale des instances (amont + FIN01) a partir d'un rapport
# de verification CSV.
#
# Usage:
#   ./copier_instances_rapport.sh RAPPORT.csv [--ko]
#
#   RAPPORT.csv : rapport de verification au format
#                 "Folio";"Type";"Date";"Nom fichier transmis";...;"Statut Verification"
#   --ko        : ne traiter que les lignes dont le statut est KO
#
# Pour chaque ligne du rapport :
#   1. Le dossier amont est deduit du nom du fichier transmis
#      (ex: FAC02_SRC_FACTURESFOURNISSEURS_... -> FAC02.FACTURESFOURNISSEURS).
#      Le fichier est recherche dans <flux>/INSTANCES en parallele,
#      sous-dossiers tries du plus recent au plus ancien, arret au
#      premier resultat (meme logique que fast_search_file.sh).
#   2. Le nom de l'instance amont est extrait du chemin trouve.
#   3. Selon le type (CLIENTS / FOURNISSEURS / GL), l'instance
#      correspondante est recherchee dans :
#        CLIENTS      -> FACTURESCLIENTS.FIN01/INSTANCES
#        FOURNISSEURS -> FACTURESFOURNISSEURS.FIN01/INSTANCES
#        GL           -> FIN01.ECRITURESCOMPTABLES/INSTANCES
#      d'abord par nom d'instance (avec et sans tirets), sinon par le
#      nom du fichier transmis present dans SOURCE.
#   4. Les deux dossiers d'instance sont copies localement dans
#      ./DDMMYYYY_TYPE_FOLIO/SOURCE (instance amont)
#      ./DDMMYYYY_TYPE_FOLIO/TARGET (instance FIN01)
# =====================================================================

set -uo pipefail

FILEREPOSITORY="/data/flf/share/EAIBW/EAI/filerepository"
CORES=$(nproc 2>/dev/null || echo 4)

# --- Arguments ---
RAPPORT="${1:-}"
ONLY_KO=0
[ "${2:-}" = "--ko" ] && ONLY_KO=1

if [ -z "$RAPPORT" ] || [ ! -f "$RAPPORT" ]; then
    echo "Erreur : vous devez fournir le rapport de verification en entree."
    echo "Usage : ./copier_instances_rapport.sh RAPPORT.csv [--ko]"
    exit 1
fi

LOG_FILE="copie_rapport_$(date +%Y%m%d_%H%M%S).log"
echo "Rapport en entree : $RAPPORT"
echo "Les logs seront enregistres dans : ./$LOG_FILE"

# ---------------------------------------------------------------------
# Recherche rapide d'un fichier : sous-dossiers tries du plus recent au
# plus ancien, exploration en parallele, arret au premier resultat.
# $1 = dossier de base (ex: .../INSTANCES)   $2 = motif (ex: "NOM*")
# ---------------------------------------------------------------------
fast_find_file() {
    local base="$1" pattern="$2" res=""

    [ -d "$base" ] || return 0

    # Fichiers directement a la racine (rapide)
    res=$(find "$base" -maxdepth 1 -type f -name "$pattern" -print -quit 2>/dev/null)

    # Sinon sous-dossiers tries par date, en parallele, arret au premier
    if [ -z "$res" ]; then
        res=$(ls -1dt "$base"/*/ 2>/dev/null | tr '\n' '\0' | \
            xargs -0 -P "$CORES" -I {} find "{}" -type f -name "$pattern" -print -quit 2>/dev/null | \
            head -n 1)
    fi
    echo "$res"
}

# ---------------------------------------------------------------------
# Deduit le dossier amont dans filerepository a partir du nom du
# fichier transmis : PREFIXE_SRC_SUFFIXE_... -> PREFIXE.SUFFIXE
# ---------------------------------------------------------------------
resoudre_dossier_amont() {
    local fic="$1"
    local prefixe="${fic%%_*}"
    local reste="${fic#*_}"
    local suffixe
    suffixe=$(echo "$reste" | sed 's/^SRC_//; s/^CTL_//' | cut -d'_' -f1)

    if [ "$prefixe" = "NOT01" ]; then
        echo "NOT01.FACTURES"
    else
        echo "${prefixe}.${suffixe}"
    fi
}

# ---------------------------------------------------------------------
# Dossier FIN01 selon le type du rapport (CLIENTS / FOURNISSEURS / GL)
# ---------------------------------------------------------------------
resoudre_dossier_fin01() {
    local type
    type=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$type" in
        CLIENT*)      echo "FACTURESCLIENTS.FIN01" ;;
        FOURNISSEUR*) echo "FACTURESFOURNISSEURS.FIN01" ;;
        GL|ECRITURE*) echo "FIN01.ECRITURESCOMPTABLES" ;;
        *)            echo "" ;;
    esac
}

# ---------------------------------------------------------------------
# Trouve le dossier d'instance FIN01 correspondant.
# $1 = base FIN01/INSTANCES   $2 = nom instance amont   $3 = nom fichier
# ---------------------------------------------------------------------
trouver_instance_fin01() {
    local base="$1" instance="$2" fichier="$3"
    local sans_tirets="${instance//-/}"

    # 1) Par nom d'instance (tel quel, puis sans les tirets)
    local cand
    for cand in "$instance" "$sans_tirets"; do
        if [ -d "$base/$cand" ]; then
            echo "$base/$cand"
            return
        fi
    done

    # 2) Sinon par nom de fichier transmis (present dans SOURCE)
    local f
    f=$(fast_find_file "$base" "${fichier}*")
    if [ -n "$f" ]; then
        echo "$f" | sed 's#\(.*/INSTANCES/[^/]*\).*#\1#'
    fi
}

# --- Traitement du rapport ---
total_ok=0
total_ko=0
lignes_traitees=0

{
    echo "Date de lancement : $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Rapport           : $RAPPORT"
    [ "$ONLY_KO" -eq 1 ] && echo "Filtre            : lignes KO uniquement"
    echo "====================================================================="

    while IFS= read -r line; do
        line="${line%$'\r'}"
        [ -z "$line" ] && continue

        # Filtre optionnel sur le statut de verification (dernier champ)
        if [ "$ONLY_KO" -eq 1 ] && ! echo "$line" | grep -q ';"KO"[[:space:]]*$'; then
            continue
        fi

        # Extraction des 4 premiers champs : Folio;Type;Date;Nom fichier
        IFS=';' read -r folio type dt fichier _ <<< "$line"
        folio="${folio//\"/}"
        type="${type//\"/}"
        dt="${dt//\"/}"
        fichier="${fichier//\"/}"

        # On ignore l'entete et les lignes non exploitables
        case "$fichier" in
            *_SRC_*) ;;
            *) continue ;;
        esac

        lignes_traitees=$((lignes_traitees + 1))
        echo ""
        echo "--- Ligne $lignes_traitees : $folio / $type / $dt / $fichier"

        # === PARTIE 1 : recherche du fichier cote amont ===
        flux_amont=$(resoudre_dossier_amont "$fichier")
        instances_amont="${FILEREPOSITORY}/${flux_amont}/INSTANCES"

        fichier_trouve=$(fast_find_file "$instances_amont" "${fichier}*")
        if [ -z "$fichier_trouve" ]; then
            echo "  !! Fichier introuvable dans ${instances_amont}"
            total_ko=$((total_ko + 1))
            continue
        fi
        echo "  Fichier trouve : $fichier_trouve"

        instance_amont=$(echo "$fichier_trouve" | sed 's#.*/INSTANCES/##' | cut -d'/' -f1)
        dossier_instance_amont="${instances_amont}/${instance_amont}"
        echo "  Instance amont : $instance_amont"

        # === PARTIE 2 : recherche de l'instance cote FIN01 ===
        flux_fin01=$(resoudre_dossier_fin01 "$type")
        dossier_instance_fin01=""
        if [ -z "$flux_fin01" ]; then
            echo "  !! Type inconnu '$type' : pas de recherche FIN01."
        else
            instances_fin01="${FILEREPOSITORY}/${flux_fin01}/INSTANCES"
            dossier_instance_fin01=$(trouver_instance_fin01 "$instances_fin01" "$instance_amont" "$fichier")
            if [ -n "$dossier_instance_fin01" ]; then
                echo "  Instance FIN01 : $(basename "$dossier_instance_fin01") (dans $flux_fin01)"
            else
                echo "  !! Instance FIN01 introuvable dans ${instances_fin01}"
            fi
        fi

        # === Copie locale ===
        dest_dir="$(echo "$dt" | tr -d '/')_${type}_${folio}"
        mkdir -p "$dest_dir/SOURCE"

        if [ -d "$dest_dir/SOURCE/$instance_amont" ]; then
            echo "  Instance amont deja copiee dans ./$dest_dir/SOURCE (ignoree)."
        elif cp -rp "$dossier_instance_amont" "$dest_dir/SOURCE/"; then
            echo "  Copie amont OK -> ./$dest_dir/SOURCE/$instance_amont"
        else
            echo "  !! ECHEC de la copie amont."
        fi

        if [ -n "$dossier_instance_fin01" ]; then
            mkdir -p "$dest_dir/TARGET"
            inst_fin01=$(basename "$dossier_instance_fin01")
            if [ -d "$dest_dir/TARGET/$inst_fin01" ]; then
                echo "  Instance FIN01 deja copiee dans ./$dest_dir/TARGET (ignoree)."
            elif cp -rp "$dossier_instance_fin01" "$dest_dir/TARGET/"; then
                echo "  Copie FIN01 OK -> ./$dest_dir/TARGET/$inst_fin01"
            else
                echo "  !! ECHEC de la copie FIN01."
            fi
        fi

        total_ok=$((total_ok + 1))
    done < "$RAPPORT"

    echo ""
    echo "====================================================================="
    echo "Lignes traitees : $lignes_traitees"
    echo "Reussites       : $total_ok"
    echo "Echecs          : $total_ko"
    echo "Traitement termine : $(date '+%d/%m/%Y %H:%M:%S')"
} > "$LOG_FILE" 2>&1

echo "Traitement termine. Consultez ./$LOG_FILE pour le detail."
