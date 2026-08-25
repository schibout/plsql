#!/bin/bash

# Fichier CSV en entrée (à adapter)
F_CSV="ma_liste_fichiers.csv"

echo "Voici les lignes à copier/coller dans resoudre_flux() :"
echo "------------------------------------------------------"

# On lit le fichier ligne par ligne (en ignorant la première ligne d'en-tête)
# On suppose que le séparateur est le point-virgule (;)
tail -n +2 "$F_CSV" | while IFS=';' read -r folio type date nom_fichier reste; do
    
    # On ignore les lignes vides
    if [ -z "$folio" ]; then continue; fi

    # Extraction du nom du flux à partir du nom du fichier
    # Exemple: CEL01_SRC_FACTURESFOURNISSEURS_... -> CEL01.FACTURESFOURNISSEURS
    PREFIXE=$(echo "$nom_fichier" | awk -F'_SRC_' '{print $1}')
    SUFFIXE=$(echo "$nom_fichier" | awk -F'_SRC_' '{print $2}' | awk -F'_' '{print $1}')
    
    FLUX_NAME="${PREFIXE}.${SUFFIXE}"

    # Affichage au format attendu pour le script
    echo "        ${folio}) FLUX_NAME=\"${FLUX_NAME}\" ;;"

done | sort -u # sort -u permet de dédoublonner les lignes identiques