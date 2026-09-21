#!/usr/bin/env python3
"""Controle de bout en bout des virements source/cible pour une date donnee.

Usage: python controle_virements.py DDMMYYYY [--racine .]
"""
import argparse
import sys
from collections import defaultdict
from pathlib import Path

from cv.discovery import discover_instances
from cv.parsers import parse_dk, parse_dk_fin01, parse_ack, parse_oracle_csv, parse_quartz_xls, parse_ls_out
from cv.doublons import doublons_croises, doublons_intra_envoi, doublons_historique, doublons_sources
from cv.sanite import controle_sanite
from cv.reconcile import (
    nom_dk_depuis_fin01, controle_fichiers, controle_doublons_ack, detail_doublons_virements,
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


def collecter_instance(instance, date=None):
    """Retourne (fichiers, totaux_source, totaux_edf, ecarts, cible_virements, acks).

    cible_virements : tous les virements reellement transmis a la banque (tous les ACK
    presents, references ou non par Oracle). acks : liste de (guid, nom, LotAck).
    Sans dossier source, l'instance est controlee en mode « cible seule » (pas de DK).
    Les elements utiles aux controles transverses sont poses sur l'instance
    (cible_seul, dkfin01_cible, oracle_rows, sanite).
    """
    fichiers, totaux_source, totaux_edf, ecarts = [], [], [], []
    cible_virements, acks = [], []
    cible = instance.cible_dir
    source = instance.source_dir
    if cible is None:
        fichiers.append({"guid": instance.guid, "categorie": "INSTANCE", "fichier": instance.guid,
                         "statut": "MANQUANT", "detail": "cote cible absent"})
        return fichiers, totaux_source, totaux_edf, ecarts, cible_virements, acks
    cible_seul = source is None
    instance.cible_seul = cible_seul

    dk_map = {} if cible_seul else _noms(source / "SOURCE", "DK_*.txt")
    dkfin01_source_map = {} if cible_seul else _noms(source / "TARGET", "DK_FIN01_*.txt")
    dkfin01_cible_map = _noms(cible / "SOURCE", "DK_FIN01_*.txt")
    tous_target = _noms(cible / "TARGET", "CDPG.NC4.IMPORT_ACK.*")
    ack_map = {n: p for n, p in tous_target.items() if not n.endswith(".asc")}
    asc_map = {n: p for n, p in tous_target.items() if n.endswith(".asc")}
    csv_files = list((cible / "TARGET").glob("ORACLE_VIREMENTS_REGROUPEMENTS_REALISES*.csv"))
    oracle_rows = parse_oracle_csv(csv_files[0]) if csv_files else []
    instance.dkfin01_cible = dkfin01_cible_map
    instance.oracle_rows = oracle_rows

    # Tout ACK present dans TARGET a ete transmis a la banque, qu'Oracle le reference ou non
    acks_parses = {nom: parse_ack(path) for nom, path in sorted(ack_map.items())}
    for nom, ack in acks_parses.items():
        acks.append((instance.guid, nom, ack))
        cible_virements += ack.virements

    fichiers += controle_fichiers(
        guid=instance.guid,
        dk_names=set(dk_map),
        dkfin01_source=set(dkfin01_source_map),
        dkfin01_cible=set(dkfin01_cible_map),
        ack_names=set(ack_map),
        oracle_rows=oracle_rows,
        cible_seul=cible_seul,
    )
    if date:
        instance.sanite = controle_sanite(instance.guid, acks_parses, asc_map, oracle_rows, date,
                                          parse_ls_out(cible / "TALEND" / "LS_OUT.OK"))

    # Niveau 1 cote source : une ligne par fichier source
    for row in oracle_rows:
        nom_dk = nom_dk_depuis_fin01(row.nom_fichier_source)
        dk = parse_dk(dk_map[nom_dk]) if nom_dk in dk_map else None
        dkfin01 = _dkfin01_lot(row, dkfin01_cible_map, dkfin01_source_map)
        totaux_source.append(
            controle_totaux_source(instance.guid, row.nom_fichier_source, dk, dkfin01, row, cible_seul))

    # Regroupement par fichier EDF (relation N:1) pour les niveaux 1-EDF et 2
    groupes = defaultdict(list)
    for row in oracle_rows:
        groupes[row.nom_fichier_edf].append(row)

    for nom_edf, rows_groupe in groupes.items():
        ack = acks_parses.get(nom_edf)
        totaux_edf.append(controle_totaux_edf(instance.guid, nom_edf, ack, rows_groupe))

        if ack is not None:
            lots = [lot for lot in (_dkfin01_lot(r, dkfin01_cible_map, dkfin01_source_map)
                                    for r in rows_groupe) if lot is not None]
            ecarts += controle_lignes(instance.guid, nom_edf, lots, ack)

    return fichiers, totaux_source, totaux_edf, ecarts, cible_virements, acks


def qualifier_doublons(fichiers, doublons):
    """Requalifie en DOUBLON les lignes de controle_fichiers des ACK envoyes en double."""
    par_fichier = {(d["guid"], d["fichier"]): d for d in doublons}
    for ligne in fichiers:
        d = par_fichier.get((ligne["guid"], ligne["fichier"]))
        if d is not None and ligne["categorie"] == "ACK":
            ligne["statut"] = "DOUBLON"
            ligne["detail"] = f"envoi identique a {d['fichier_original']}"


def executer(date, racine=".", quartz=None, historique_jours=7):
    """Lance le controle complet et ecrit les rapports. Retourne un dict :
    ok, dossier (Path des rapports), nb_instances, quartz (bool : retour tresorerie trouve),
    cible_seul, extras (controles complementaires), doublons, fichiers, totaux_edf.
    Leve FileNotFoundError si aucune instance n'existe pour la date."""
    racine = Path(racine)
    instances = discover_instances(racine, date)
    if not instances:
        raise FileNotFoundError(f"Aucune instance trouvee pour la date {date} sous {racine}")

    tous_fichiers, tous_totaux_src, tous_totaux_edf, tous_ecarts = [], [], [], []
    tous_cible_virements, tous_acks = [], []
    for inst in instances:
        f, ts, te, e, cv, acks = collecter_instance(inst, date)
        tous_fichiers += f
        tous_totaux_src += ts
        tous_totaux_edf += te
        tous_ecarts += e
        tous_cible_virements += cv
        tous_acks += acks

    # Envois en double vers la banque (toutes instances confondues)
    references = {(t["guid"], t["fichier_edf"]) for t in tous_totaux_edf}
    doublons = controle_doublons_ack(tous_acks, references)
    doublons_detail = detail_doublons_virements(tous_acks, doublons)
    qualifier_doublons(tous_fichiers, doublons)

    # Doublons complementaires (D2..D6) et sanite, tous calcules sur la cible
    chevauchements, virements_multi = doublons_croises(tous_acks, doublons)
    historique, nb_jours = ([], 0)
    if historique_jours > 0:
        historique, nb_jours = doublons_historique(tous_acks, racine, date, historique_jours)
    extras = {
        "cible_seul": all(i.cible_seul for i in instances if i.cible_dir is not None),
        "chevauchements": chevauchements,
        "virements_multi": virements_multi,
        "intra": doublons_intra_envoi(tous_acks),
        "historique": historique,
        "historique_jours": nb_jours,
        "sources": doublons_sources({i.guid: i.dkfin01_cible for i in instances},
                                    {i.guid: i.oracle_rows for i in instances}),
        "sanite": [l for i in instances for l in i.sanite],
    }

    # Niveau 3 : rapprochement du retour Quartz (jour entier) contre les virements envoyes
    quartz_path = Path(quartz) if quartz else trouver_fichier_quartz(racine, date)
    quartz_totaux, quartz_ecarts = None, []
    quartz_ok = bool(quartz_path and quartz_path.is_file())
    if quartz_ok:
        quartz_virements = parse_quartz_xls(quartz_path)
        quartz_totaux, quartz_ecarts = controle_quartz(tous_cible_virements, quartz_virements)

    dossier = racine / f"rapport_{date}"
    ok = write_reports(dossier, tous_fichiers, tous_totaux_src, tous_totaux_edf, tous_ecarts,
                       quartz_totaux, quartz_ecarts, doublons, doublons_detail, extras)
    return {"ok": ok, "dossier": dossier, "nb_instances": len(instances), "quartz": quartz_ok,
            "cible_seul": extras["cible_seul"], "extras": extras, "doublons": doublons,
            "fichiers": tous_fichiers, "totaux_edf": tous_totaux_edf, "quartz_totaux": quartz_totaux}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Controle des virements source/cible.")
    parser.add_argument("date", help="Date au format DDMMYYYY (ex: 26062026)")
    parser.add_argument("--racine", default=".", help="Repertoire racine (defaut: .)")
    parser.add_argument("--quartz", default=None,
                        help="Chemin du fichier .xls Quartz (defaut: recherche automatique)")
    parser.add_argument("--historique-jours", type=int, default=7,
                        help="Nb de jours en arriere pour chercher des envois deja transmis "
                             "dans les autres dossiers JJMMAAAA de la racine (defaut: 7, 0 = desactive)")
    args = parser.parse_args(argv)

    try:
        res = executer(args.date, args.racine, args.quartz, args.historique_jours)
    except FileNotFoundError as e:
        print(e)
        return 1
    if not res["quartz"]:
        print("Fichier Quartz introuvable : niveau 3 (retour tresorerie) ignore.")
    print(f"Rapports ecrits dans {res['dossier']}. Resultat global : {'OK' if res['ok'] else 'KO'}")
    return 0 if res["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
