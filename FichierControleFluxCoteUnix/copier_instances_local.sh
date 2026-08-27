#!/bin/bash

# =====================================================================
# Copie locale des instances (amont + FIN01) a partir d'un rapport
# de verification CSV.
#
# Usage:
#   ./copier_instances_local.sh Rapport_Verification_XXXX.csv [--ko]
#
#   --ko : ne traiter que les lignes dont le statut est KO.
#
# Le rapport est lu ligne par ligne ; seules les 4 premieres colonnes
# sont exploitees :
#   1: Folio   2: Type   3: Date   4: Nom fichier transmis
#
# Pour chaque ligne :
#   1. Le dossier du flux amont est determine par la table folio+type
#      (secours : deduit du prefixe du nom de fichier). Le fichier est
#      recherche dans <flux>/INSTANCES : sous-dossiers tries du plus
#      recent au plus ancien, en parallele, arret au premier resultat.
#   2. L'instance FIN01 correspondante est recherchee selon le type :
#        CLIENT      -> FACTURESCLIENTS.FIN01/INSTANCES
#        FOURNISSEUR -> FACTURESFOURNISSEURS.FIN01/INSTANCES
#        GL          -> FIN01.ECRITURESCOMPTABLES/INSTANCES
#   3. Copie locale :
#        ./DDMMYYYY_TYPE_FOLIO/SOURCE/<instance amont>
#        ./DDMMYYYY_TYPE_FOLIO/TARGET/<instance FIN01>
#
# Chaque fichier transmis n'est telecharge qu'UNE SEULE FOIS : si le
# meme nom de fichier apparait sur plusieurs lignes du rapport (ex: un
# fichier CEL01 partage par les folios CEC/CEE/CEG), les lignes
# suivantes sont ignorees avec un renvoi vers la premiere copie.
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
    echo "Usage : ./copier_instances_local.sh Rapport_Verification_XXXX.csv [--ko]"
    exit 1
fi

# ---------------------------------------------------------------------
# Table de correspondance : type et code -> dossier dans filerepository.
# ---------------------------------------------------------------------
resoudre_flux() {
    local code="$1"
    local type="$2"
    local prefixe=""
    local suffixe=""

    case "$type" in
        "FOURNISSEUR") suffixe="FACTURESFOURNISSEURS" ;;
        "CLIENT")      suffixe="FACTURESCLIENTS" ;;
        "GL")          suffixe="ECRITURESGL" ;;
        *)             FLUX_NAME=""; return ;;
    esac

    case "$code" in
        "BIO"|"FAS"|"FGE"|"GAZ"|"GCA"|"GER"|"HAC"|"IGP"|"ING"|"PAR"|"RNE"|"SVD"|"VTC")
            prefixe="FAC02"
            ;;
        "CEL"|"CEC"|"CEG"|"CEE") prefixe="CEL01" ;;
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
# Normalise le type du rapport (FOURNISSEURS/CLIENTS/GL) vers
# FOURNISSEUR/CLIENT/GL.
# ---------------------------------------------------------------------
normaliser_type() {
    local type
    type=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$type" in
        FOURNISSEUR*) echo "FOURNISSEUR" ;;
        CLIENT*)      echo "CLIENT" ;;
        GL|ECRITURE*) echo "GL" ;;
        *)            echo "" ;;
    esac
}

# ---------------------------------------------------------------------
# Dossier de flux amont deduit du nom du fichier transmis (secours si
# la table folio -> prefixe ne donne pas un dossier existant).
# PREFIXE_SRC_SUFFIXE_... -> PREFIXE.SUFFIXE
# ---------------------------------------------------------------------
flux_depuis_fichier() {
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
# Dossier FIN01 selon le type normalise
# ---------------------------------------------------------------------
resoudre_dossier_fin01() {
    case "$1" in
        CLIENT)      echo "FACTURESCLIENTS.FIN01" ;;
        FOURNISSEUR) echo "FACTURESFOURNISSEURS.FIN01" ;;
        GL)          echo "FIN01.ECRITURESCOMPTABLES" ;;
        *)           echo "" ;;
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
LOG_FILE="copie_rapport_$(date +%Y%m%d_%H%M%S).log"
echo "Rapport en entree : $RAPPORT"
echo "Les logs seront enregistres dans : ./$LOG_FILE"

total_ok=0
total_ko=0
total_doublons=0
lignes_traitees=0

# Memorise les fichiers deja telecharges : cle = nom du fichier,
# valeur = dossier local ou il a ete copie.
declare -A fichiers_copies

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

        # Colonnes exploitees : 1=Folio 2=Type 3=Date 4=Nom fichier
        IFS=';' read -r folio type dt fichier _reste <<< "$line"
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

        # Chaque fichier n'est telecharge qu'une seule fois
        if [ -n "${fichiers_copies[$fichier]:-}" ]; then
            echo "  Fichier deja telecharge -> voir ./${fichiers_copies[$fichier]}"
            total_doublons=$((total_doublons + 1))
            continue
        fi

        type_norm=$(normaliser_type "$type")
        if [ -z "$type_norm" ]; then
            echo "  !! Type inconnu '$type' : ligne ignoree."
            total_ko=$((total_ko + 1))
            continue
        fi

        # === PARTIE 1 : recherche du fichier cote amont ===
        resoudre_flux "$folio" "$type_norm"
        flux_amont="$FLUX_NAME"

        # Secours : si le dossier n'existe pas, on le deduit du nom du fichier
        if [ -z "$flux_amont" ] || [ ! -d "${FILEREPOSITORY}/${flux_amont}" ]; then
            flux_amont=$(flux_depuis_fichier "$fichier")
        fi
        instances_amont="${FILEREPOSITORY}/${flux_amont}/INSTANCES"

        echo "  Recherche dans : $instances_amont"
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
        flux_fin01=$(resoudre_dossier_fin01 "$type_norm")
        dossier_instance_fin01=""
        if [ -n "$flux_fin01" ]; then
            instances_fin01="${FILEREPOSITORY}/${flux_fin01}/INSTANCES"
            dossier_instance_fin01=$(trouver_instance_fin01 "$instances_fin01" "$instance_amont" "$fichier")
            if [ -n "$dossier_instance_fin01" ]; then
                echo "  Instance FIN01 : $(basename "$dossier_instance_fin01") (dans $flux_fin01)"
            else
                echo "  !! Instance FIN01 introuvable dans ${instances_fin01}"
            fi
        fi

        # === Copie locale : SOURCE = amont, TARGET = FIN01 ===
        dest_dir="$(echo "$dt" | tr -d '/')_${type}_${folio}"
        mkdir -p "$dest_dir/SOURCE"

        copie_amont_ok=0
        if [ -d "$dest_dir/SOURCE/$instance_amont" ]; then
            echo "  Instance amont deja presente dans ./$dest_dir/SOURCE (ignoree)."
            copie_amont_ok=1
        elif cp -rp "$dossier_instance_amont" "$dest_dir/SOURCE/"; then
            echo "  Copie amont OK -> ./$dest_dir/SOURCE/$instance_amont"
            copie_amont_ok=1
        else
            echo "  !! ECHEC de la copie amont."
        fi

        if [ -n "$dossier_instance_fin01" ]; then
            mkdir -p "$dest_dir/TARGET"
            inst_fin01=$(basename "$dossier_instance_fin01")
            if [ -d "$dest_dir/TARGET/$inst_fin01" ]; then
                echo "  Instance FIN01 deja presente dans ./$dest_dir/TARGET (ignoree)."
            elif cp -rp "$dossier_instance_fin01" "$dest_dir/TARGET/"; then
                echo "  Copie FIN01 OK -> ./$dest_dir/TARGET/$inst_fin01"
            else
                echo "  !! ECHEC de la copie FIN01."
            fi
        fi

        if [ "$copie_amont_ok" -eq 1 ]; then
            fichiers_copies[$fichier]="$dest_dir"
            total_ok=$((total_ok + 1))
        else
            total_ko=$((total_ko + 1))
        fi
    done < "$RAPPORT"

    echo ""
    echo "====================================================================="
    echo "Lignes traitees      : $lignes_traitees"
    echo "Fichiers telecharges : $total_ok"
    echo "Doublons ignores     : $total_doublons"
    echo "Echecs               : $total_ko"
    echo "Traitement termine : $(date '+%d/%m/%Y %H:%M:%S')"
} > "$LOG_FILE" 2>&1

echo "Traitement termine. Consultez ./$LOG_FILE pour le detail."
