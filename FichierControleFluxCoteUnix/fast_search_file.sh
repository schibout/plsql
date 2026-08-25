#!/bin/bash

# Vérification qu'un paramètre (le début du nom du fichier) a bien été fourni
if [ -z "$1" ]; then
    echo "Erreur : Vous devez fournir le début du nom du fichier."
    echo "Usage : ./fast_search.sh \"DEBUT_DU_NOM\""
    echo "Exemple : ./fast_search.sh \"FAC02_SRC_FACTURESFOURNISSEURS_210826\""
    exit 1
fi

# On cherche tout ce qui COMMENCE par le paramètre fourni
PATTERN="${1}*"

# Configuration du dossier de recherche
SEARCH_DIR="/data/flf/share/EAIBW/EAI/filerepository"

# Fichier de log (horodaté)
LOG_FILE="resultat_recherche_$(date +%Y%m%d_%H%M%S).log"

echo "Recherche en cours pour le premier fichier commençant par : $1"
echo "Les résultats seront enregistrés dans : ./$LOG_FILE"

# Redirection vers la log
{
    CORES=$(nproc 2>/dev/null || echo 4)

    echo "Date de lancement : $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Recherche de : $PATTERN"
    echo "Dans : $SEARCH_DIR"
    echo "Mode : Arrêt immédiat dès le premier résultat."
    echo "Utilisation de $CORES processus en parallèle."
    echo "------------------------------------------------------"
    echo "Fichier trouvé :"
    echo ""

    # La recherche multi-processus avec arrêt au premier résultat
    # "head -n 1" ne garde que la première ligne et force l'arrêt des autres processus
    find "$SEARCH_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | \
        xargs -0 -P "$CORES" -I {} find "{}" -type f -name "$PATTERN" 2>/dev/null | \
        head -n 1

    echo ""
    echo "------------------------------------------------------"
    echo "Recherche terminée."
} > "$LOG_FILE" 2>&1

echo "Terminé ! Consultez le fichier ./$LOG_FILE pour voir le résultat."