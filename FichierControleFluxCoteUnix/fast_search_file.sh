#!/bin/bash

# Vérification qu'un paramètre (le début du nom du fichier) a bien été fourni
if [ -z "$1" ]; then
    echo "Erreur : Vous devez fournir le début du nom du fichier."
    echo "Usage : ./fast_search_file.sh \"DEBUT_DU_NOM\" [recent|ancien]"
    echo "  recent : parcourt les dossiers du plus recent au plus ancien (defaut)"
    echo "  ancien : parcourt les dossiers du plus ancien au plus recent"
    echo "Exemple : ./fast_search_file.sh \"FAC02_SRC_FACTURESFOURNISSEURS_210826\" recent"
    exit 1
fi

# On cherche tout ce qui COMMENCE par le paramètre fourni
PATTERN="${1}*"

# Ordre de parcours des sous-dossiers : recent (defaut) ou ancien
ORDER="${2:-recent}"
case "$ORDER" in
    recent) LS_OPTS="-1dt" ;;   # tri par date de modification, plus recent d'abord
    ancien) LS_OPTS="-1dtr" ;;  # tri inverse, plus ancien d'abord
    *)
        echo "Erreur : le 2e parametre doit etre 'recent' ou 'ancien' (recu : $ORDER)."
        exit 1
        ;;
esac

# Configuration du dossier de recherche
SEARCH_DIR="/data/flf/share/EAIBW/EAI/filerepository"

# Fichier de log (horodaté)
LOG_FILE="resultat_recherche_$(date +%Y%m%d_%H%M%S).log"

CORES=$(nproc 2>/dev/null || echo 4)
START_TS=$(date +%s)

echo "Recherche en cours pour le premier fichier commençant par : $1"
echo "Ordre de parcours des dossiers : $ORDER"
echo "Les résultats seront enregistrés dans : ./$LOG_FILE"

# 1) Les fichiers directement à la racine du dépôt (les plus rapides à vérifier)
RESULT=$(find "$SEARCH_DIR" -maxdepth 1 -type f -name "$PATTERN" -print -quit 2>/dev/null)

# 2) Sinon, les sous-dossiers tries par date, explorés en parallèle.
#    Chaque find s'arrête à son premier résultat (-quit), et "head -n 1"
#    coupe le pipe dès la première ligne, ce qui stoppe les autres processus.
if [ -z "$RESULT" ]; then
    RESULT=$(ls $LS_OPTS "$SEARCH_DIR"/*/ 2>/dev/null | tr '\n' '\0' | \
        xargs -0 -P "$CORES" -I {} find "{}" -type f -name "$PATTERN" -print -quit 2>/dev/null | \
        head -n 1)
fi

ELAPSED=$(( $(date +%s) - START_TS ))

# Écriture de la log
{
    echo "Date de lancement : $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Recherche de : $PATTERN"
    echo "Dans : $SEARCH_DIR"
    echo "Ordre de parcours : $ORDER (dossiers tries par date de modification)"
    echo "Mode : arrêt immédiat dès le premier résultat, $CORES processus en parallèle."
    echo "Durée : ${ELAPSED}s"
    echo "------------------------------------------------------"
    if [ -n "$RESULT" ]; then
        echo "Fichier trouvé :"
        echo "$RESULT"
    else
        echo "Aucun fichier trouvé."
    fi
    echo "------------------------------------------------------"
    echo "Recherche terminée."
} > "$LOG_FILE" 2>&1

# Affichage du résultat à l'écran
if [ -n "$RESULT" ]; then
    echo "Fichier trouvé (${ELAPSED}s) : $RESULT"
else
    echo "Aucun fichier trouvé (${ELAPSED}s)."
fi
echo "Terminé ! Consultez le fichier ./$LOG_FILE pour le détail."
