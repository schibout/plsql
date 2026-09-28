"""Pour chaque traitement de l'extraction fusionnée, indique si son FILE_OUT est présent dans le rapport de vérification.

Une ligne par traitement de l'extraction (tous conservés). Trouvés d'abord, non trouvés à la fin.
Comparaison : extension retirée, espaces retirés, insensible à la casse.
Usage : python rapprochement_file_out.py [fusion.csv] [rapport.csv] [sortie.csv]
"""
import csv
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
FUSION = Path(sys.argv[1]) if len(sys.argv) > 1 else ICI / "csv_extracts_fusion.csv"
RAPPORT = Path(sys.argv[2]) if len(sys.argv) > 2 else max(ICI.glob("Rapport_Verification_*.csv"))
SORTIE = Path(sys.argv[3]) if len(sys.argv) > 3 else ICI / "rapprochement_file_out.csv"

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

integres, non_integres = [], []
with FUSION.open(newline="", encoding="utf-8-sig") as f:
    for ligne in csv.DictReader(f, delimiter=";"):
        fichiers_out = [n.strip() for n in ligne["FILE_OUT"].split(",") if n.strip()]
        lignes_rapport = [r for nom in fichiers_out for r in rapport.get(cle(nom), [])]
        base = [ligne["Flow_name"], ligne["traitment_id"], ligne["date"], ligne["FILE_IN"], ligne["FILE_OUT"]]
        if lignes_rapport:
            sommes = [montant(sum(nombre(r[c]) for r in lignes_rapport)) for c in MONTANTS]
            integres.append([*base, *sommes, "TROUVE"])
        else:
            non_integres.append([*base, *[""] * len(MONTANTS), "NON TROUVE"])

with SORTIE.open("w", newline="", encoding="utf-8-sig") as out:
    writer = csv.writer(out, delimiter=";")
    writer.writerow(["Flow_name", "traitment_id", "date", "FILE_IN", "FILE_OUT", "Montant fichier", "Montant Oracle", "Rapport"])
    writer.writerows(integres + non_integres)

print(f"Rapport : {RAPPORT.name}\n")
print(f"{'Flow_name':<34} {'Date':<19} {'Montant fichier':>15} {'Montant Oracle':>15}  Rapport     FILE_OUT")
for l in integres + non_integres:
    print(f"{l[0]:<34} {l[2]:<19} {l[5]:>15} {l[6]:>15}  {l[7]:<11} {l[4]}")
print(f"\nTrouvés : {len(integres)} | Non trouvés : {len(non_integres)} | Total : {len(integres) + len(non_integres)}")
print(f"-> {SORTIE}")
