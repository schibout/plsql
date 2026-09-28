"""Pour chaque fichier SRC de FichierPirenne.csv, indique s'il est présent dans le rapport de vérification.

Une ligne par fichier SRC (CTL, XML… ignorés : jamais dans le rapport). Trouvés d'abord, non trouvés à la fin.
Comparaison : extension retirée, espaces retirés, insensible à la casse.
Usage : python rapprochement_pirenne.py [pirenne.csv] [rapport.csv] [sortie.csv]
"""
import csv
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
PIRENNE = Path(sys.argv[1]) if len(sys.argv) > 1 else ICI / "FichierPirenne.csv"
RAPPORT = Path(sys.argv[2]) if len(sys.argv) > 2 else max(ICI.glob("Rapport_Verification_*.csv"))
SORTIE = Path(sys.argv[3]) if len(sys.argv) > 3 else ICI / "rapprochement_pirenne.csv"

def cle(nom):
    nom = "".join(nom.split()).lower()
    return nom.rsplit(".", 1)[0] if "." in nom else nom


with RAPPORT.open(newline="", encoding="utf-8-sig") as f:
    rapport = {cle(ligne["Nom fichier transmis"]) for ligne in csv.DictReader(f, delimiter=";")}

trouves, non_trouves = [], []
with PIRENNE.open(newline="", encoding="utf-8-sig") as f:
    for ligne in csv.DictReader(f, delimiter=";"):
        if "_SRC_" not in ligne["Name"].upper():
            continue
        base = [ligne["Name"], ligne["Creation-Time"], ligne["Last-Modified"], ligne["Content-Length"]]
        if cle(ligne["Name"]) in rapport:
            trouves.append([*base, "TROUVE"])
        else:
            non_trouves.append([*base, "NON TROUVE"])

with SORTIE.open("w", newline="", encoding="utf-8-sig") as out:
    writer = csv.writer(out, delimiter=";")
    writer.writerow(["Name", "Creation-Time", "Last-Modified", "Content-Length", "Rapport"])
    writer.writerows(trouves + non_trouves)

print(f"Rapport : {RAPPORT.name}")
print(f"Trouvés : {len(trouves)} | Non trouvés : {len(non_trouves)} | Total : {len(trouves) + len(non_trouves)}")
print(f"-> {SORTIE}")
