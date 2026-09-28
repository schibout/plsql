"""Pour chaque fichier de FichierPirenne.csv, indique s'il est présent dans le rapport de vérification.

Une ligne par fichier (tous conservés). Trouvés d'abord, non trouvés à la fin.
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

# Montant fichier = "Somme Amont Fichier", Montant Oracle = "Montant OA" (sommés sur les folios)
MONTANTS = ["Somme Amont Fichier", "Montant OA"]


def cle(nom):
    nom = "".join(nom.split()).lower()
    return nom.rsplit(".", 1)[0] if "." in nom else nom


def nombre(texte):
    try:
        return float(texte.replace(" ", "").replace(",", "."))
    except ValueError:
        return 0.0


def montant(valeur):
    return f"{valeur:.2f}".replace(".", ",")


with RAPPORT.open(newline="", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f, delimiter=";")
    reader.fieldnames = [c.strip() for c in reader.fieldnames]  # "Montant OA " -> "Montant OA"
    rapport = {}
    for ligne in reader:
        rapport.setdefault(cle(ligne["Nom fichier transmis"]), []).append(ligne)

trouves, non_trouves = [], []
with PIRENNE.open(newline="", encoding="utf-8-sig") as f:
    for ligne in csv.DictReader(f, delimiter=";"):
        base = [ligne["Name"], ligne["Creation-Time"], ligne["Last-Modified"], ligne["Content-Length"]]
        lignes_rapport = rapport.get(cle(ligne["Name"]), [])
        if lignes_rapport:
            sommes = [montant(sum(nombre(r[c]) for r in lignes_rapport)) for c in MONTANTS]
            trouves.append([*base, *sommes, "TROUVE"])
        else:
            non_trouves.append([*base, *[""] * len(MONTANTS), "NON TROUVE"])

with SORTIE.open("w", newline="", encoding="utf-8-sig") as out:
    writer = csv.writer(out, delimiter=";")
    writer.writerow(["Name", "Creation-Time", "Last-Modified", "Content-Length", "Montant fichier", "Montant Oracle", "Rapport"])
    writer.writerows(trouves + non_trouves)

print(f"Rapport : {RAPPORT.name}\n")
print(f"{'Name':<55} {'Creation-Time':<18} {'Montant fichier':>15} {'Montant Oracle':>15}  Rapport")
for l in trouves + non_trouves:
    print(f"{l[0]:<55} {l[1]:<18} {l[4]:>15} {l[5]:>15}  {l[6]}")
print(f"\nTrouvés : {len(trouves)} | Non trouvés : {len(non_trouves)} | Total : {len(trouves) + len(non_trouves)}")
print(f"-> {SORTIE}")
