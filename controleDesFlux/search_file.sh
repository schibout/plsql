#!/bin/bash

ROOT_DIR="/data/flf/share/EAIBW/EAI/filerepository/FAC02.FACTURESCLIENTS/INSTANCES"
SEARCH_VALUE="$1"

# Format du rapport (csv ou txt) passé en 2ème argument (par défaut : csv)
FORMAT=$(echo "${2:-csv}" | tr '[:upper:]' '[:lower:]')

# =====================================================================
# CONFIGURATION
# =====================================================================
# Mettre à "true" pour copier les fichiers trouvés dans le dossier courant.
# Mettre à "false" si vous voulez uniquement le rapport CSV/TXT.
COPY_FOUND_FILES=true
# =====================================================================

# Vérification du paramètre obligatoire
if [ -z "$SEARCH_VALUE" ]; then
    echo "Usage: $0 <nom_du_fichier> [csv|txt]"
    echo "Exemple: $0 123456 txt"
    exit 1
fi

# Vérification du format
if [ "$FORMAT" != "csv" ] && [ "$FORMAT" != "txt" ]; then
    echo "Erreur : Le format '$FORMAT' n'est pas supporté. Utilisez 'csv' ou 'txt'."
    exit 1
fi

# Utilisation de "./" pour forcer la création dans le dossier courant
OUTPUT_FILE="./resultat_recherche_${SEARCH_VALUE}_$(date +%Y%m%d_%H%M%S).${FORMAT}"
TMP_FILE="/tmp/search_facture_${SEARCH_VALUE}_$$.tmp"

# Recherche des fichiers (insensible à la casse)
find "$ROOT_DIR" -type f -iname "*${SEARCH_VALUE}*" 2>/dev/null > "$TMP_FILE"

# Vérification si des fichiers ont été trouvés
if [ ! -s "$TMP_FILE" ]; then
    echo "Aucun fichier trouvé contenant : $SEARCH_VALUE"
    rm -f "$TMP_FILE"
    exit 0
fi

# --- Génération du rapport et Copie des fichiers ---

if [ "$FORMAT" = "csv" ]; then
    # Création du CSV dans le dossier courant
    echo "Fichier;Chemin_Complet" > "$OUTPUT_FILE"
    while IFS= read -r FILE; do
        FILENAME=$(basename "$FILE")
        FILEPATH=$(dirname "$FILE")
        echo "\"$FILENAME\";\"$FILEPATH\"" >> "$OUTPUT_FILE"
        
        # Copie optionnelle du fichier trouvé vers le dossier courant (.)
        if [ "$COPY_FOUND_FILES" = true ]; then
            cp "$FILE" . 2>/dev/null
        fi
    done < "$TMP_FILE"

else
    # Création du TXT dans le dossier courant
    echo "==================================================" > "$OUTPUT_FILE"
    echo " RÉSULTATS DE LA RECHERCHE POUR : $SEARCH_VALUE" >> "$OUTPUT_FILE"
    echo " Date : $(date '+%d/%m/%Y à %H:%M:%S')" >> "$OUTPUT_FILE"
    echo "==================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    while IFS= read -r FILE; do
        FILENAME=$(basename "$FILE")
        FILEPATH=$(dirname "$FILE")
        echo "Fichier : $FILENAME" >> "$OUTPUT_FILE"
        echo "Chemin  : $FILEPATH" >> "$OUTPUT_FILE"
        echo "--------------------------------------------------" >> "$OUTPUT_FILE"
        
        # Copie optionnelle du fichier trouvé vers le dossier courant (.)
        if [ "$COPY_FOUND_FILES" = true ]; then
            cp "$FILE" . 2>/dev/null
        fi
    done < "$TMP_FILE"
fi

# Nettoyage
rm -f "$TMP_FILE"

echo "Recherche terminée avec succès."
echo "-> Rapport [${FORMAT^^}] enregistré ici : $OUTPUT_FILE"

if [ "$COPY_FOUND_FILES" = true ]; then
    echo "-> Les fichiers correspondants ont également été copiés dans ce dossier."
fi