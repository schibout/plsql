#!/bin/bash

# Vérification qu'un paramètre (la liste de fichiers) a bien été fourni
if [ -z "$1" ]; then
    echo "Erreur : Vous devez fournir une liste de noms de fichiers séparés par des points-virgules."
    echo "Usage : ./fast_search_file.sh \"FICHIER1;FICHIER2;...\" [recent|ancien]"
    echo "  recent : parcourt les dossiers du plus recent au plus ancien (defaut)"
    echo "  ancien : parcourt les dossiers du plus ancien au plus recent"
    echo "Exemple : ./fast_search_file.sh \"FAC02_210826;FAC03_210827;FAC04_210828\" recent"
    exit 1
fi

# Ordre de parcours des sous-dossiers
ORDER="${2:-recent}"
case "$ORDER" in
    recent) LS_OPTS="-1dt" ;;
    ancien) LS_OPTS="-1dtr" ;;
    *)
        echo "Erreur : le 2e parametre doit etre 'recent' ou 'ancien'."
        exit 1
        ;;
esac

# Configuration des dossiers
SEARCH_DIR="/data/flf/share/EAIBW/EAI/filerepository/VHC03.FACTURESFOURNISSEURS/INSTANCES"
TARGET_DIR="."

# Création du dossier cible s'il n'existe pas
mkdir -p "$TARGET_DIR"

# Fichier de log
LOG_FILE="resultat_recherche_$(date +%Y%m%d_%H%M%S).log"
CORES=$(nproc 2>/dev/null || echo 4)
START_TS=$(date +%s)

# Découpage de la liste de fichiers (séparateur = ;)
IFS=';' read -ra FILE_LIST <<< "$1"

{
    echo "Date de lancement : $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Dossier source : $SEARCH_DIR"
    echo "Dossier cible : $TARGET_DIR"
    echo "Nombre de fichiers à chercher : ${#FILE_LIST[@]}"
    echo "------------------------------------------------------"
} > "$LOG_FILE"

echo "Recherche en cours pour ${#FILE_LIST[@]} fichier(s)..."
echo "Les résultats seront enregistrés dans : ./$LOG_FILE"
echo "------------------------------------------------------"

# Boucle sur chaque fichier de la liste
for PREFIX in "${FILE_LIST[@]}"; do
    # Ignorer les éléments vides (ex: si la liste se termine par un point-virgule)
    if [ -z "$PREFIX" ]; then
        continue
    fi

    PATTERN="${PREFIX}*"
    
    # 1) Recherche à la racine
    RESULT=$(find "$SEARCH_DIR" -maxdepth 1 -type f -name "$PATTERN" -print -quit 2>/dev/null)

    # 2) Recherche dans les sous-dossiers si non trouvé à la racine
    if [ -z "$RESULT" ]; then
        RESULT=$(ls $LS_OPTS "$SEARCH_DIR"/*/ 2>/dev/null | tr '\n' '\0' | \
            xargs -0 -P "$CORES" -I {} find "{}" -type f -name "$PATTERN" -print -quit 2>/dev/null | \
            head -n 1)
    fi

    # Bilan pour ce fichier
    if [ -n "$RESULT" ]; then
        cp "$RESULT" "$TARGET_DIR/"
        if [ $? -eq 0 ]; then
            MSG="[SUCCÈS] Trouvé et copié : $RESULT"
        else
            MSG="[ERREUR] Trouvé mais échec de copie : $RESULT"
        fi
    else
        MSG="[INTROUVABLE] Aucun fichier trouvé pour : $PATTERN"
    fi

    # Affichage écran et écriture log
    echo "$MSG"
    echo "$MSG" >> "$LOG_FILE"
done

ELAPSED=$(( $(date +%s) - START_TS ))

{
    echo "------------------------------------------------------"
    echo "Recherche terminée en ${ELAPSED}s."
} >> "$LOG_FILE"

echo "------------------------------------------------------"
echo "Terminé en ${ELAPSED}s ! Consultez ./$LOG_FILE pour le détail."