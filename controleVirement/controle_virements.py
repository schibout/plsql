#!/usr/bin/env python3
"""Controle de bout en bout des virements source/cible pour une date donnee.

Usage: python controle_virements.py DDMMYYYY [--racine .]
"""
import argparse
import sys
from collections import defaultdict
from pathlib import Path

from cv.discovery import discover_instances
from cv.parsers import parse_dk, parse_dk_fin01, parse_ack, parse_oracle_csv, parse_quartz_xls
from cv.reconcile import (
    nom_dk_depuis_fin01, controle_fichiers,
    controle_totaux_source, controle_totaux_edf, controle_lignes, controle_quartz,
)
from cv.report import write_reports

# Normalisation accents pour retrouver le fichier Quartz quelle que soit la casse/accentuation
_ACCENTS = str.maketrans("éèêëàâäîïôöûüç", "eeeeaaaiioouuc")


def trouver_fichier_quartz(racine: Path, date: str):
    """Cherche 'Liste des virements importes du jour<date>.xls' (accents/casse ignores)."""
    cible = f"listedesvirementsimportesdujour{date}.xls"
    for p in racine.glob("*.xls"):
        clef = p.name.lower().translate(_ACCENTS).replace(" ", "")
        if clef == cible:
            return p
    return None


def _noms(dossier: Path, motif: str):
    if not dossier or not dossier.is_dir():
        return {}
    return {p.name: p for p in dossier.glob(motif)}


def _dkfin01_lot(row, dkfin01_cible_map, dkfin01_source_map):
    path = dkfin01_cible_map.get(row.nom_fichier_source) or dkfin01_source_map.get(row.nom_fichier_source)
    return parse_dk_fin01(path) if path else None


def collecter_instance(instance):
    fichiers, totaux_source, totaux_edf, ecarts = [], [], [], []
    cible_virements = []
    cible = instance.cible_dir
    source = instance.source_dir
    if cible is None or source is None:
        cote = "cible" if cible is None else "source"
        fichiers.append({"guid": instance.guid, "categorie": "INSTANCE", "fichier": instance.guid,
                         "statut": "MANQUANT", "detail": f"cote {cote} absent"})
        return fichiers, totaux_source, totaux_edf, ecarts, cible_virements

    dk_map = _noms(source / "SOURCE", "DK_*.txt")
    dkfin01_source_map = _noms(source / "TARGET", "DK_FIN01_*.txt")
    dkfin01_cible_map = _noms(cible / "SOURCE", "DK_FIN01_*.txt")
    ack_map = {n: p for n, p in _noms(cible / "TARGET", "CDPG.NC4.IMPORT_ACK.*").items()
               if not n.endswith(".asc")}
    csv_files = list((cible / "TARGET").glob("ORACLE_VIREMENTS_REGROUPEMENTS_REALISES*.csv"))
    oracle_rows = parse_oracle_csv(csv_files[0]) if csv_files else []

    fichiers += controle_fichiers(
        guid=instance.guid,
        dk_names=set(dk_map),
        dkfin01_source=set(dkfin01_source_map),
        dkfin01_cible=set(dkfin01_cible_map),
        ack_names=set(ack_map),
        oracle_rows=oracle_rows,
    )

    # Niveau 1 cote source : une ligne par fichier source
    for row in oracle_rows:
        nom_dk = nom_dk_depuis_fin01(row.nom_fichier_source)
        dk = parse_dk(dk_map[nom_dk]) if nom_dk in dk_map else None
        dkfin01 = _dkfin01_lot(row, dkfin01_cible_map, dkfin01_source_map)
        totaux_source.append(
            controle_totaux_source(instance.guid, row.nom_fichier_source, dk, dkfin01, row))

    # Regroupement par fichier EDF (relation N:1) pour les niveaux 1-EDF et 2
    groupes = defaultdict(list)
    for row in oracle_rows:
        groupes[row.nom_fichier_edf].append(row)

    for nom_edf, rows_groupe in groupes.items():
        ack = parse_ack(ack_map[nom_edf]) if nom_edf in ack_map else None
        totaux_edf.append(controle_totaux_edf(instance.guid, nom_edf, ack, rows_groupe))

        if ack is not None:
            cible_virements += ack.virements
            lots = [lot for lot in (_dkfin01_lot(r, dkfin01_cible_map, dkfin01_source_map)
                                    for r in rows_groupe) if lot is not None]
            ecarts += controle_lignes(instance.guid, nom_edf, lots, ack)

    return fichiers, totaux_source, totaux_edf, ecarts, cible_virements


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Controle des virements source/cible.")
    parser.add_argument("date", help="Date au format DDMMYYYY (ex: 26062026)")
    parser.add_argument("--racine", default=".", help="Repertoire racine (defaut: .)")
    parser.add_argument("--quartz", default=None,
                        help="Chemin du fichier .xls Quartz (defaut: recherche automatique)")
    args = parser.parse_args(argv)

    racine = Path(args.racine)
    instances = discover_instances(racine, args.date)
    if not instances:
        print(f"Aucune instance trouvee pour la date {args.date} sous {racine}")
        return 1

    tous_fichiers, tous_totaux_src, tous_totaux_edf, tous_ecarts = [], [], [], []
    tous_cible_virements = []
    for inst in instances:
        f, ts, te, e, cv = collecter_instance(inst)
        tous_fichiers += f
        tous_totaux_src += ts
        tous_totaux_edf += te
        tous_ecarts += e
        tous_cible_virements += cv

    # Niveau 3 : rapprochement du retour Quartz (jour entier) contre les virements envoyes
    quartz_path = Path(args.quartz) if args.quartz else trouver_fichier_quartz(racine, args.date)
    quartz_totaux, quartz_ecarts = None, []
    if quartz_path and quartz_path.is_file():
        quartz_virements = parse_quartz_xls(quartz_path)
        quartz_totaux, quartz_ecarts = controle_quartz(tous_cible_virements, quartz_virements)
    else:
        print("Fichier Quartz introuvable : niveau 3 (retour tresorerie) ignore.")

    dossier = racine / f"rapport_{args.date}"
    ok = write_reports(dossier, tous_fichiers, tous_totaux_src, tous_totaux_edf, tous_ecarts,
                       quartz_totaux, quartz_ecarts)
    print(f"Rapports ecrits dans {dossier}. Resultat global : {'OK' if ok else 'KO'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
