"""Pour chaque traitement de l'extraction fusionnée, indique si son FILE_OUT est présent dans le rapport de vérification.
FILE_OUT vide : on cherche à la place le fichier SRC du FILE_IN.

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

def cle(nom):
    nom = "".join(nom.split()).lower()
    return nom.rsplit(".", 1)[0] if "." in nom else nom


with RAPPORT.open(newline="", encoding="utf-8-sig") as f:
    rapport = {cle(ligne["Nom fichier transmis"]) for ligne in csv.DictReader(f, delimiter=";")}

integres, non_integres = [], []
with FUSION.open(newline="", encoding="utf-8-sig") as f:
    for ligne in csv.DictReader(f, delimiter=";"):
        fichiers_out = [n.strip() for n in ligne["FILE_OUT"].split(",") if n.strip()]
        if not fichiers_out:  # pas de FILE_OUT : on prend le fichier SRC du FILE_IN (pas le CTL)
            fichiers_out = [n.strip() for n in ligne["FILE_IN"].split(",") if "_SRC_" in n.upper()]
        base = [ligne["Flow_name"], ligne["traitment_id"], ligne["date"], ligne["FILE_IN"], ligne["FILE_OUT"]]
        if any(cle(nom) in rapport for nom in fichiers_out):
            integres.append([*base, "TROUVE"])
        else:
            non_integres.append([*base, "NON TROUVE"])

with SORTIE.open("w", newline="", encoding="utf-8-sig") as out:
    writer = csv.writer(out, delimiter=";")
    writer.writerow(["Flow_name", "traitment_id", "date", "FILE_IN", "FILE_OUT", "Rapport"])
    writer.writerows(integres + non_integres)

print(f"Rapport : {RAPPORT.name}")
print(f"Trouvés : {len(integres)} | Non trouvés : {len(non_integres)} | Total : {len(integres) + len(non_integres)}")
print(f"-> {SORTIE}")
