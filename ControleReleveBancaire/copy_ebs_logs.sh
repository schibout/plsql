#!/bin/bash

# ==============================================================================
# Script : copy_ebs_logs_both.sh
# Objectif : Copier les fichiers .req (file1) et .out (file2) depuis une liste
# ==============================================================================

# Vérification du paramètre d'entrée
if [ "$#" -ne 1 ]; then
    echo "Utilisation : $0 <fichier_liste.txt>"
    exit 1
fi

INPUT_FILE="$1"

# Vérification de l'existence du fichier
if [ ! -f "$INPUT_FILE" ]; then
    echo "Erreur : Le fichier '$INPUT_FILE' est introuvable."
    exit 1
fi

echo "Début de la copie des fichiers vers : $(pwd)"
echo "---------------------------------------------------"

# Lecture du fichier avec nettoyage à la volée des caractères de fin de ligne Windows (\r)
while read -r file1 file2 extra; do
    
    # Ignorer les lignes vides
    if [ -z "$file1" ]; then
        continue
    fi

    # 1. Traitement du fichier 1 (file1 : .req)
    if [ -f "$file1" ]; then
        cp "$file1" .
        echo "[SUCCÈS] file1 copié : $(basename "$file1")"
    else
        echo "[ERREUR] file1 introuvable : $file1"
    fi

    # 2. Traitement du fichier 2 (file2 : .out)
    # Vérifie que file2 n'est pas vide avant de tenter la copie
    if [ -n "$file2" ]; then
        if [ -f "$file2" ]; then
            cp "$file2" .
            echo "[SUCCÈS] file2 copié : $(basename "$file2")"
        else
            echo "[ERREUR] file2 introuvable : $file2"
        fi
    fi

done < <(tr -d '\r' < "$INPUT_FILE")

echo "---------------------------------------------------"
echo "Opération terminée."