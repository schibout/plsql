#!/bin/bash

# ==============================================================================
# Fonction de recherche de fichiers en arrière-plan
# ==============================================================================
search_ebs_files() {
    # Assignation des paramètres d'entrée à des variables locales explicites
    local search_dir="/data/flf/share/EAIBW/EAI/filerepository/NOT01.FACTURES"
    local file_prefix="$2"
    local log_file="$3"

    # Vérification que les 3 paramètres sont bien fournis
    if [ -z "$search_dir" ] || [ -z "$file_prefix" ] || [ -z "$log_file" ]; then
        echo "Erreur : Paramètres manquants."
        echo "Usage  : search_ebs_files <repertoire> <prefixe_fichier> <fichier_log>"
        return 1
    fi

    echo "====================================================="
    echo " Lancement de la recherche EBS"
    echo "====================================================="
    echo " Dossier cible   : ${search_dir}"
    echo " Préfixe cherché : ${file_prefix}*"
    echo " Fichier de log  : ${log_file}"
    echo "====================================================="

    # Exécution de la commande find en tâche de fond
    nohup find "$search_dir" -type f -name "${file_prefix}*" > "$log_file" 2>&1 &
    
    # Récupération du Process ID (PID) de la dernière commande lancée en arrière-plan
    local pid=$!
    
    echo " -> Recherche lancée avec succès en arrière-plan !"
    echo " -> Process ID (PID) : $pid"
    echo " -> Pour suivre en direct : tail -f $log_file"
    echo ""
}

# ==============================================================================
# Appel de la fonction avec tes paramètres
# ==============================================================================
# Paramètre 1 : "." (le dossier actuel) - Tu pourrais utiliser $XX_TOP ou $APPLCSF/inbound
# Paramètre 2 : "IMPORT_AVP_DK" (le début du nom de fichier)
# Paramètre 3 : "liste_fichiers_avp.log" (le fichier de destination)

search_ebs_files "/data/flf/share/EAIBW/EAI/filerepository" "IMPORT_AVP_DK" "liste_fichiers_avp.log"
search_ebs_files "/data/flf/share/EAIBW/EAI/filerepository" "ORACLE_PRELEVEMENT_REGROUPEMENTS_REALISES_260806.csv" "liste_fichiers_grp.log"
search_ebs_files "/data/flf/share/EAIBW/EAI/filerepository" "REJETS_INTERNES_DK" "liste_fichiers_grp.log"

# Exemple d'un second appel pour un autre module (décommenter si besoin) :
# search_ebs_files "$PO_TOP/out" "PO_REQ" "logs_achats.log"