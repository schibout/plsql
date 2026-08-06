#!/usr/bin/env python3
"""Rapprochement des ordres de prelevement emis par ORACLE avec les etats de
reception EDF, avec restitution Excel en 3 onglets.

Etape 1 : synthese journaliere brute (volumes et montants Oracle vs EDF).
Etape 2 : etat comparatif et ecarts, avec projection de la date Oracle vers
          la date de prise en charge EDF attendue.
Etape 3 : contenu brut des fichiers de rejets internes.

Portage du script PowerShell Prelevements_Rapprochement_Oracle_EDF.ps1.
Contrairement a celui-ci, ne depend pas d'une installation locale de Microsoft
Excel : la generation du .xlsx passe par openpyxl.

Usage : python prelevements_rapprochement.py [--racine .] [--sortie .]

Code retour : 0 = aucun ecart, 1 = ecarts detectes, 2 = erreur de traitement.
"""
import argparse
import fnmatch
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from decimal import Decimal, InvalidOperation
from pathlib import Path

try:
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter
except ImportError:  # pragma: no cover - message d'aide a l'installation
    sys.exit("Le module 'openpyxl' est requis. Installez-le avec :\n"
             "    python -m pip install -r requirements.txt")

# Encodage des fichiers sources (ISO-8859-1 : les etats EDF et Oracle sont
# produits en ANSI/CP1252, dont les accents francais coincident sur cette plage).
ENCODAGE_SOURCE = "latin-1"

# Couleurs telles que rendues par le script PowerShell d'origine.
# Attention : celui-ci passe les couleurs a Excel en BGR ; les valeurs ci-dessous
# sont les RGB reellement obtenus, pour que les deux scripts produisent le meme
# classeur a l'octet pres cote mise en forme.
COULEUR_ENTETE = "FF1F497D"   # bleu fonce
COULEUR_ECART = "FFFCE4D6"    # peche : ligne en ecart
COULEUR_OK = "FFEDEFDA"       # vert pale : ligne conforme
COULEUR_BRUT = "FFBD814F"     # brun : entete de l'onglet des rejets

FORMAT_MONTANT = "#,##0.00"
FORMAT_NOMBRE = "#,##0"
FORMAT_TEXTE = "@"

BLANC = "FFFFFFFF"
TAILLE_BASE = 11   # taille ecrite explicitement, comme le fait Excel via COM


class ErreurTraitement(Exception):
    """Erreur fonctionnelle : interrompt le traitement avec un message clair."""


class Diagnostic:
    """Compteurs de traitement : un rapport partiel doit se voir."""

    def __init__(self):
        self.fichiers_oracle = 0
        self.lignes_oracle = 0
        self.lignes_oracle_ignorees = 0
        self.fichiers_edf = 0
        self.lignes_edf = 0
        self.fichiers_rejets = 0
        self.lignes_rejets = 0
        self.avertissements = []

    def avertir(self, message):
        self.avertissements.append(message)
        print(f"AVERTISSEMENT : {message}", file=sys.stderr)


def lire_lignes(chemin):
    """Lecture deterministe : jamais de surprise selon la locale du poste."""
    return chemin.read_text(encoding=ENCODAGE_SOURCE).splitlines()


def vers_decimal(valeur):
    """Conversion invariante : le separateur decimal est toujours le point."""
    return Decimal(valeur.strip().replace(",", "."))


def parse_date(valeur):
    """Renvoie None au lieu de lever, pour pouvoir signaler l'anomalie."""
    try:
        return datetime.strptime(valeur, "%Y%m%d")
    except (ValueError, TypeError):
        return None


def index_colonne_montant(lignes):
    """Resout la position de la colonne AMOUNT depuis la ligne de description
    FORMAT1ENTITYID plutot que de la coder en dur : le format Oracle peut
    evoluer sans que le script ne s'en apercoive."""
    for ligne in lignes:
        if ligne.startswith("FORMAT1ENTITYID"):
            colonnes = [c.strip() for c in ligne.split(",")]
            if "AMOUNT" in colonnes:
                return colonnes.index("AMOUNT")
    return -1


# ---------------------------------------------------------------------------
# 2. Analyse ORACLE
# ---------------------------------------------------------------------------
def analyser_oracle(oracle_path, motifs, diag):
    """Agrege nombre de lignes et montant total par date de generation
    (le nom du sous-dossier)."""
    if not oracle_path.is_dir():
        raise ErreurTraitement(f"Dossier Oracle introuvable : {oracle_path}")

    brut = defaultdict(lambda: {"nb": 0, "total": Decimal(0)})

    for fichier in sorted(oracle_path.rglob("*")):
        if not fichier.is_file():
            continue
        if not any(fnmatch.fnmatch(fichier.name, m) for m in motifs):
            continue

        date_dossier = fichier.parent.name
        if parse_date(date_dossier) is None:
            diag.avertir(f"Dossier non date ignore : {fichier.parent}")
            continue

        lignes = lire_lignes(fichier)
        idx_montant = index_colonne_montant(lignes)
        if idx_montant < 0:
            diag.avertir(f"Colonne AMOUNT introuvable, index 5 par defaut : {fichier.name}")
            idx_montant = 5

        diag.fichiers_oracle += 1
        for ligne in lignes:
            if not ligne.strip():
                continue
            if ligne.startswith("HEADER") or ligne.startswith("FORMAT1ENTITYID"):
                continue

            champs = ligne.split(",")
            if len(champs) <= idx_montant:
                diag.lignes_oracle_ignorees += 1
                continue
            try:
                montant = vers_decimal(champs[idx_montant])
            except InvalidOperation:
                diag.lignes_oracle_ignorees += 1
                continue

            brut[date_dossier]["nb"] += 1
            brut[date_dossier]["total"] += montant
            diag.lignes_oracle += 1

    if diag.lignes_oracle_ignorees:
        diag.avertir(f"{diag.lignes_oracle_ignorees} ligne(s) Oracle illisible(s) "
                     "ecartee(s) du calcul.")
    if not brut:
        raise ErreurTraitement(f"Aucune ligne Oracle exploitable trouvee sous {oracle_path}.")

    return [{"date": d, "nb": v["nb"], "total": v["total"]} for d, v in sorted(brut.items())]


# ---------------------------------------------------------------------------
# 3. Analyse EDF
# ---------------------------------------------------------------------------
def analyser_edf(edf_path, motif, nom_si, diag):
    """Agrege les lignes du SI cible par date de reception (nom du fichier)."""
    if not edf_path.is_dir():
        diag.avertir(f"Dossier EDF introuvable : {edf_path}. "
                     "Les volumes recus seront a zero.")
        return []

    brut = defaultdict(lambda: {"nb": 0, "total": Decimal(0)})

    for fichier in sorted(edf_path.glob(motif)):
        if not fichier.is_file():
            continue
        segments = fichier.name.split(".")
        if len(segments) < 2 or parse_date(segments[1]) is None:
            diag.avertir(f"Date illisible dans le nom du fichier EDF, ignore : {fichier.name}")
            continue

        date_edf = segments[1]
        diag.fichiers_edf += 1

        for ligne in lire_lignes(fichier):
            champs = ligne.split(";")
            if len(champs) < 5 or champs[0].strip() != nom_si:
                continue
            try:
                nb = int(champs[3].strip())
                total = vers_decimal(champs[4])
            except (ValueError, InvalidOperation):
                diag.avertir(f"Ligne EDF illisible ignoree dans {fichier.name} : {ligne}")
                continue

            brut[date_edf]["nb"] += nb
            brut[date_edf]["total"] += total
            diag.lignes_edf += 1

    # Un rapport ou tout l'EDF est a zero ressemble a un ecart total : il faut
    # distinguer "rien recu" de "mauvais filtre / format change".
    if diag.fichiers_edf and not diag.lignes_edf:
        diag.avertir(f"Aucune ligne '{nom_si}' trouvee dans les {diag.fichiers_edf} "
                     "fichier(s) EDF lus. Verifiez --nom-si ou le format des fichiers : "
                     "les ecarts affiches seront trompeurs.")

    return [{"date": d, "nb": v["nb"], "total": v["total"]} for d, v in sorted(brut.items())]


# ---------------------------------------------------------------------------
# 4. Lecture brute des fichiers de REJETS
# ---------------------------------------------------------------------------
def lire_rejets(rejets_path, motif, diag):
    if not rejets_path.is_dir():
        diag.avertir(f"Dossier de rejets introuvable : {rejets_path}.")
        return []

    lignes_brutes = []
    fichiers = sorted(p for p in rejets_path.iterdir()
                      if p.is_file() and fnmatch.fnmatch(p.name, motif))
    diag.fichiers_rejets = len(fichiers)

    for fichier in fichiers:
        for ligne in lire_lignes(fichier):
            if not ligne.strip():
                continue
            lignes_brutes.append({"fichier": fichier.name, "texte": ligne})
            diag.lignes_rejets += 1

    return lignes_brutes


# ---------------------------------------------------------------------------
# 5. Preparation du rapprochement comparatif
# ---------------------------------------------------------------------------
def date_cible(date_oracle):
    """Projection Oracle -> EDF : J+2 ouvre approxime en jours calendaires.

    A revoir avec le metier : ne tient pas compte des jours feries.
    weekday() : 3 = jeudi, 4 = vendredi, 5 = samedi.
    """
    if date_oracle.weekday() in (3, 4):
        return date_oracle + timedelta(days=4)
    return date_oracle + timedelta(days=2)


def construire_rapprochement(oracle_summary, edf_summary):
    edf_par_date = {e["date"]: e for e in edf_summary}

    # Plusieurs dates Oracle peuvent viser la meme date EDF : on les regroupe.
    groupes = defaultdict(list)
    for ora in oracle_summary:
        cible = date_cible(parse_date(ora["date"])).strftime("%Y%m%d")
        groupes[cible].append(ora)

    lignes = []
    for date_edf_cible in sorted(groupes):
        groupe = groupes[date_edf_cible]
        dates_origine = sorted(o["date"] for o in groupe)

        nb_attendu = sum(o["nb"] for o in groupe)
        total_attendu = sum((o["total"] for o in groupe), Decimal(0))

        correspondance = edf_par_date.get(date_edf_cible)
        nb_recu = correspondance["nb"] if correspondance else 0
        total_recu = correspondance["total"] if correspondance else Decimal(0)

        date_edf_parsee = parse_date(date_edf_cible)
        # Delai mesure depuis la premiere date d'origine du groupe.
        delai = (date_edf_parsee - parse_date(dates_origine[0])).days
        ecart_nb = nb_recu - nb_attendu

        lignes.append({
            "date_oracle": " + ".join(parse_date(d).strftime("%d/%m/%Y") for d in dates_origine),
            "date_edf": date_edf_parsee.strftime("%d/%m/%Y"),
            "nb_oracle": nb_attendu,
            "nb_edf": nb_recu,
            "ecart_nb": ecart_nb,
            "total_oracle": arrondi(total_attendu),
            "total_edf": arrondi(total_recu),
            "ecart_montant": arrondi(total_recu - total_attendu),
            "statut": f"OK (J+{delai})" if ecart_nb == 0 else f"Écart (J+{delai})",
        })

    return lignes


def arrondi(valeur):
    return float(round(valeur, 2))


# ---------------------------------------------------------------------------
# 6. Restitution Excel
# ---------------------------------------------------------------------------
def _titre(ws, cellule, texte):
    ws[cellule] = texte
    ws[cellule].font = Font(bold=True, size=14)


def _entetes(ws, ligne, col_depart, libelles, couleur):
    fill = PatternFill("solid", fgColor=couleur)
    for i, libelle in enumerate(libelles):
        cell = ws.cell(row=ligne, column=col_depart + i, value=libelle)
        cell.fill = fill
        cell.font = Font(bold=True, color=BLANC, size=TAILLE_BASE)
        cell.alignment = Alignment(horizontal="center")


def _colonnes_texte(ws, colonnes):
    """Force le format texte sur les cellules renseignees des colonnes visees.

    Reproduit le comportement de PowerShell, qui applique le format a la colonne
    entiere : dates jj/mm/aaaa, IBAN et zeros de tete ne sont jamais reinterpretes
    par Excel. Les cellules vides sont laissees telles quelles, comme dans le
    classeur produit par le script PowerShell.
    """
    for col in colonnes:
        for row in range(1, ws.max_row + 1):
            cell = ws.cell(row=row, column=col)
            if cell.value is not None:
                cell.number_format = FORMAT_TEXTE


def _ajuster_largeurs(ws, largeurs_imposees=None, maxi=60):
    """openpyxl n'a pas d'equivalent a AutoFit : on approxime a partir du contenu."""
    largeurs = defaultdict(int)
    for ligne in ws.iter_rows():
        for cell in ligne:
            if cell.value is not None:
                largeurs[cell.column] = max(largeurs[cell.column], len(str(cell.value)))
    for col, largeur in largeurs.items():
        ws.column_dimensions[get_column_letter(col)].width = min(largeur + 2, maxi)
    for col, largeur in (largeurs_imposees or {}).items():
        ws.column_dimensions[col].width = largeur


def generer_classeur(chemin, oracle_summary, edf_summary, rapprochement, rejets):
    wb = Workbook()

    # --- ONGLET 1 : Synthese journaliere brute ---
    ws1 = wb.active
    ws1.title = "Synthèse Journalière Brute"
    _titre(ws1, "A1", "ÉTAPE 1 : SYNTHÈSE JOURNALIÈRE BRUTE")
    ws1["A3"] = "Données Émises par ORACLE"
    ws1["A3"].font = Font(bold=True, size=TAILLE_BASE)
    ws1["E3"] = "Données Reçues par EDF"
    ws1["E3"].font = Font(bold=True, size=TAILLE_BASE)

    _entetes(ws1, 4, 1, ["Date Gén. Oracle", "Nb Total Lignes", "Montant Total (€)"],
             COULEUR_ENTETE)
    _entetes(ws1, 4, 5, ["Date Prise Chg EDF", "Nb Prél. Pris en Chg",
                         "Montant Pris en Chg (€)"], COULEUR_ENTETE)

    for i, row in enumerate(oracle_summary):
        r = 5 + i
        # Les dates sont stockees en texte pour figer l'affichage jj/mm/aaaa.
        c = ws1.cell(row=r, column=1, value=parse_date(row["date"]).strftime("%d/%m/%Y"))
        c.number_format = FORMAT_TEXTE
        c.alignment = Alignment(horizontal="center")
        ws1.cell(row=r, column=2, value=row["nb"]).number_format = FORMAT_NOMBRE
        ws1.cell(row=r, column=3, value=arrondi(row["total"])).number_format = FORMAT_MONTANT

    for i, row in enumerate(edf_summary):
        r = 5 + i
        c = ws1.cell(row=r, column=5, value=parse_date(row["date"]).strftime("%d/%m/%Y"))
        c.number_format = FORMAT_TEXTE
        c.alignment = Alignment(horizontal="center")
        ws1.cell(row=r, column=6, value=row["nb"]).number_format = FORMAT_NOMBRE
        ws1.cell(row=r, column=7, value=arrondi(row["total"])).number_format = FORMAT_MONTANT

    _colonnes_texte(ws1, (1, 5))
    _ajuster_largeurs(ws1, {"A": 26})

    # --- ONGLET 2 : Etat comparatif et ecarts ---
    ws2 = wb.create_sheet("État Comparatif & Écarts")
    _titre(ws2, "A1", "ÉTAPE 2 : ÉTAT COMPARATIF ET RAPPROCHEMENT DES ÉCARTS")
    _entetes(ws2, 3, 1, [
        "Date(s) Gén. Oracle", "Date Reç. EDF (Cible)", "Nb Attendu (Ora)",
        "Nb Reçu (EDF)", "Écart Nombre", "Total Attendu (Ora)", "Total Reçu (EDF)",
        "Écart Montant (€)", "Statut / Délai"], COULEUR_ENTETE)

    fill_ecart = PatternFill("solid", fgColor=COULEUR_ECART)
    fill_ok = PatternFill("solid", fgColor=COULEUR_OK)

    for i, row in enumerate(rapprochement):
        r = 4 + i
        for col, valeur in ((1, row["date_oracle"]), (2, row["date_edf"])):
            c = ws2.cell(row=r, column=col, value=valeur)
            c.number_format = FORMAT_TEXTE
            c.alignment = Alignment(horizontal="center")
        for col, valeur in ((3, row["nb_oracle"]), (4, row["nb_edf"]), (5, row["ecart_nb"])):
            ws2.cell(row=r, column=col, value=valeur).number_format = FORMAT_NOMBRE
        for col, valeur in ((6, row["total_oracle"]), (7, row["total_edf"]),
                            (8, row["ecart_montant"])):
            ws2.cell(row=r, column=col, value=valeur).number_format = FORMAT_MONTANT
        ws2.cell(row=r, column=9, value=row["statut"])

        if row["ecart_nb"] != 0:
            ws2.cell(row=r, column=5).fill = fill_ecart
            ws2.cell(row=r, column=8).fill = fill_ecart
            ws2.cell(row=r, column=9).fill = fill_ecart
            ws2.cell(row=r, column=9).font = Font(bold=True, size=TAILLE_BASE)
        else:
            ws2.cell(row=r, column=9).fill = fill_ok

    _colonnes_texte(ws2, (1, 2))
    _ajuster_largeurs(ws2, {"A": 22})

    # --- ONGLET 3 : Fichiers de rejets bruts ---
    ws3 = wb.create_sheet("Fichiers de Rejets Bruts")
    _titre(ws3, "A1", "DONNÉES BRUTES EXTRAITES DES FICHIERS DE REJETS")
    _entetes(ws3, 3, 1, ["Nom du Fichier Source",
                         "Ligne Brute (Contenu Intégral du Fichier CSV)"], COULEUR_BRUT)

    for i, rejet in enumerate(rejets):
        r = 4 + i
        ws3.cell(row=r, column=1, value=rejet["fichier"])
        ws3.cell(row=r, column=2, value=rejet["texte"])

    # Mode texte strict : preserve les IBAN et les zeros de tete.
    _colonnes_texte(ws3, (2,))

    ws3.column_dimensions["A"].width = 35
    ws3.column_dimensions["B"].width = 120

    wb.save(chemin)


# ---------------------------------------------------------------------------
# Point d'entree
# ---------------------------------------------------------------------------
def construire_parser():
    p = argparse.ArgumentParser(
        description="Rapprochement des prelevements Oracle / EDF.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("--racine", type=Path, default=Path(__file__).resolve().parent,
                   help="Racine de traitement")
    p.add_argument("--sortie", type=Path, default=None,
                   help="Dossier de sortie du classeur (defaut : la racine)")
    p.add_argument("--dossier-oracle", default="ORACLE",
                   help="Sous-dossier de l'arborescence Oracle")
    p.add_argument("--dossier-edf", default="EDF",
                   help="Sous-dossier des etats de reception EDF")
    p.add_argument("--motifs-oracle", nargs="+", default=["*PCX*", "*PCL*"],
                   help="Motifs de nom des fichiers Oracle")
    p.add_argument("--motif-edf", default="IMPORT_AVP_DK.*.*.csv",
                   help="Motif de nom des etats de reception EDF")
    p.add_argument("--motif-rejets", default="REJETS_INTERNES_DK.*",
                   help="Motif de nom des fichiers de rejets internes")
    p.add_argument("--nom-si", default="ORACLE",
                   help="Valeur de la colonne 'NOM DU SI' a rapprocher")
    return p


def trouver_dossier_rejets(edf_path):
    """Detection du dossier rejets sans distinction de casse."""
    if edf_path.is_dir():
        for d in edf_path.iterdir():
            if d.is_dir() and d.name.upper() == "REJETS":
                return d
    return edf_path / "REJETS"


def main(argv=None):
    args = construire_parser().parse_args(argv)
    diag = Diagnostic()

    try:
        racine = args.racine.resolve()
        if not racine.is_dir():
            raise ErreurTraitement(f"Racine de traitement introuvable : {racine}")
        sortie = (args.sortie or racine).resolve()
        sortie.mkdir(parents=True, exist_ok=True)

        edf_path = racine / args.dossier_edf
        horodatage = datetime.now().strftime("%Y%m%d_%H%M%S")
        chemin_sortie = sortie / f"Rapprochement_Oracle_EDF_{horodatage}.xlsx"

        print(f"Analyse du dossier en cours : {racine.name}")

        oracle_summary = analyser_oracle(racine / args.dossier_oracle,
                                         args.motifs_oracle, diag)
        print(f"Oracle : {diag.fichiers_oracle} fichier(s), {diag.lignes_oracle} ligne(s), "
              f"{len(oracle_summary)} date(s).")

        edf_summary = analyser_edf(edf_path, args.motif_edf, args.nom_si, diag)
        if diag.fichiers_edf:
            print(f"EDF : {diag.fichiers_edf} fichier(s), {diag.lignes_edf} ligne(s) "
                  f"'{args.nom_si}', {len(edf_summary)} date(s).")

        rejets = lire_rejets(trouver_dossier_rejets(edf_path), args.motif_rejets, diag)
        if diag.fichiers_rejets:
            print(f"Rejets : {diag.fichiers_rejets} fichier(s), {diag.lignes_rejets} ligne(s).")

        rapprochement = construire_rapprochement(oracle_summary, edf_summary)

        print("Génération du classeur Excel...")
        generer_classeur(chemin_sortie, oracle_summary, edf_summary, rapprochement, rejets)

    except ErreurTraitement as exc:
        print(f"Erreur critique : {exc}", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"Erreur d'acces fichier : {exc}", file=sys.stderr)
        return 2

    nb_ecarts = sum(1 for r in rapprochement if r["ecart_nb"] != 0)

    print("\n=======================================================")
    print(" Rapprochement complété avec succès !")
    print(f" Fichier : {chemin_sortie}")
    print(f" Oracle : {diag.lignes_oracle} ligne(s) / EDF : {diag.lignes_edf} ligne(s)"
          f" / Rejets : {diag.lignes_rejets} ligne(s)")
    if diag.avertissements:
        print(f" {len(diag.avertissements)} avertissement(s) - rapport potentiellement incomplet.")
    if nb_ecarts:
        print(f" {nb_ecarts} date(s) en écart sur {len(rapprochement)} rapprochée(s).")
    else:
        print(f" Aucun écart sur {len(rapprochement)} date(s) rapprochée(s).")
    print("=======================================================")

    return 1 if nb_ecarts else 0


if __name__ == "__main__":
    sys.exit(main())
