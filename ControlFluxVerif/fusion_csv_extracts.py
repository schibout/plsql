"""Fusionne tous les CSV de csv_extracts/ en un seul fichier (en-tête écrit une seule fois).

Usage : python fusion_csv_extracts.py [dossier_source] [fichier_sortie]
"""
import csv
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ICI / "csv_extracts"
SORTIE = Path(sys.argv[2]) if len(sys.argv) > 2 else ICI / "csv_extracts_fusion.csv"

entete = None
nb = 0
with SORTIE.open("w", newline="", encoding="utf-8") as out:
    writer = csv.writer(out, delimiter=";")
    for fichier in sorted(SOURCE.glob("*.csv")):
        with fichier.open(newline="", encoding="utf-8-sig") as f:
            reader = csv.reader(f, delimiter=";")
            tete = next(reader, None)
            if tete is None:
                continue
            if entete is None:
                entete = tete
                writer.writerow(entete)
            elif tete != entete:
                sys.exit(f"En-tête différent dans {fichier.name} : {tete}")
            lignes = [l for l in reader if l]
            writer.writerows(lignes)
            nb += len(lignes)
            print(f"{fichier.name} : {len(lignes)} lignes")

print(f"-> {SORTIE} : {nb} lignes fusionnées")
