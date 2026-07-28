#!/bin/bash

ROOT_DIR="/data/flf/share/EAIBW/EAI/filerepository/FAC02.FACTURESCLIENTS/INSTANCES"
LIST_FILE="factures.txt"
OUTPUT_FILE="resultat_multi_factures_$(date +%Y%m%d_%H%M%S).csv"
TMP_FILE="/tmp/search_multi_$$.tmp"

# Recherche multiple
grep -R -Hn --binary-files=without-match -f "$LIST_FILE" "$ROOT_DIR" 2>/dev/null > "$TMP_FILE"

# Si rien trouvé
if [ ! -s "$TMP_FILE" ]; then
    echo "Aucune occurrence trouvée"
    rm -f "$TMP_FILE"
    exit 0
fi

# Header CSV
echo "Facture;Fichier;Chemin;Ligne;Contenu" > "$OUTPUT_FILE"

while IFS=":" read -r FILE LINE CONTENT; do

    MATCH=$(grep -f "$LIST_FILE" <<< "$CONTENT")

    FILENAME=$(basename "$FILE")
    FILEPATH=$(dirname "$FILE")

    echo "\"$MATCH\";$FILENAME;$FILEPATH;$LINE;\"$CONTENT\"" >> "$OUTPUT_FILE"

done < "$TMP_FILE"

rm -f "$TMP_FILE"

echo "Résultat : $OUTPUT_FILE"