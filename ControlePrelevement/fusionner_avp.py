import os
import glob
import csv
import re

# --- Configuration ---
# Le script s'exécute dans le dossier où il se trouve.
dossier_script = os.path.dirname(os.path.abspath(__file__))
os.chdir(dossier_script)

# Modèle des fichiers à fusionner
# Cherche les fichiers qui commencent par "IMPORT_AVP_DK."
file_pattern = "IMPORT_AVP_DK.*.csv"

# Nom du fichier de sortie
output_filename = "IMPORT_AVP_DK_Fusion.csv"

# --- Exécution ---

print(f"Recherche des fichiers correspondant à '{file_pattern}'...")

# Utilise glob pour trouver tous les fichiers correspondant au modèle
# On exclut le fichier de sortie lui-même pour ne pas le lire s'il existe déjà
all_files = [f for f in glob.glob(file_pattern) if f != output_filename]

if not all_files:
    print("Aucun fichier trouvé. Le script va s'arrêter.")
    exit()

print(f"{len(all_files)} fichier(s) trouvé(s) :")
for f in all_files:
    print(f" - {f}")

# Expression régulière pour extraire la date YYYYMMDD du nom de fichier
date_regex = re.compile(r'IMPORT_AVP_DK\.(\d{8})\.\d{6}\.csv')

header_written = False

# On ouvre le fichier de sortie en mode écriture
with open(output_filename, 'w', newline='', encoding='utf-8') as outfile:
    csv_writer = csv.writer(outfile, delimiter=';')

    # On parcourt chaque fichier trouvé
    for filename in all_files:
        match = date_regex.search(filename)
        if not match:
            print(f"AVERTISSEMENT: Le fichier '{filename}' ne correspond pas au format de nom attendu et sera ignoré.")
            continue

        # La date est le premier groupe capturé par la regex (les 8 chiffres)
        file_date = match.group(1)

        # On ouvre le fichier d'entrée en lecture
        with open(filename, 'r', newline='', encoding='utf-8') as infile:
            # --- Spécificité pour les fichiers AVP (demande de l'utilisateur) ---
            # On ignore les 4 premières lignes qui représentent l'en-tête global.
            try:
                next(infile)  # Ligne 1: "ETAT DES RECEPTIONS..."
                next(infile)  # Ligne 2: Ligne vide
                next(infile)  # Ligne 3: Ligne d'en-tête des colonnes
                next(infile)  # Ligne 4: Ligne vide ou autre information
            except StopIteration:
                print(f"AVERTISSEMENT: Le fichier '{filename}' a moins de 4 lignes et sera ignoré.")
                continue
            # -----------------------------------------

            csv_reader = csv.reader(infile, delimiter=';')

            # L'en-tête du fichier source a été ignoré, on ne le lit pas.
            # On écrit un en-tête fixe dans le fichier de sortie, une seule fois.
            if not header_written:
                hardcoded_header = ['NOM DU SI DALKIA', 'IBAN CREANCIER', "DATE D'ECHEANCE", 'NOMBRE DE PRELEVEMENTS', 'MONTANT TOTAL']
                csv_writer.writerow(['DateFichier'] + hardcoded_header)
                header_written = True

            for row in csv_reader:
                # On ne garde que les lignes où la première colonne (NOM DU SI DALKIA) est 'ORACLE'
                if row and row[0] == 'ORACLE':
                    csv_writer.writerow([file_date] + row)

print(f"\nFusion terminée avec succès.")
print(f"Le fichier de sortie a été créé ici : {os.path.join(dossier_script, output_filename)}")