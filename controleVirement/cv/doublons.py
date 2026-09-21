"""Controles de doublons complementaires, calcules uniquement a partir du dossier cible.

D1 (envois strictement identiques) reste dans reconcile.controle_doublons_ack. Ici :
  D2  envois chevauchants : meme payeur, des virements en commun sans etre identiques
  D3  virement present dans plusieurs envois differents de la journee
  D4  virement present deux fois dans le meme envoi
  D5  envoi / virement deja transmis un jour precedent (autres dossiers *_cible de la racine)
  D6  fichier source (DK_FIN01) rejoue : meme nom ou meme contenu dans plusieurs instances,
      ou reference plusieurs fois par le CSV Oracle

Chaque ligne produite porte une gravite : KO (ecart bloquant) ou A_VERIFIER (a qualifier).
"""
import re
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from itertools import combinations
from pathlib import Path

from cv.parsers import parse_ack, parse_dk_fin01
from cv.reconcile import _empreinte_ack, _norm_nom

KO = "KO"
A_VERIFIER = "A_VERIFIER"

_REF_PAIEMENT = re.compile(r"\d{2}/\d{2}/\d{4}-(\d+)-")


def _cle(payeur, v):
    return (payeur.strip(), v.iban, v.montant_cts, _norm_nom(v.nom))


def ref_paiement(v):
    """Reference de paiement Oracle portee par le libelle ACK (ex. '21/09/2026-44756-Site ...' -> '44756')."""
    m = _REF_PAIEMENT.search(v.libelle or "")
    return m.group(1) if m else ""


# ------------------------------------------------------------------ D2 + D3
def doublons_croises(acks, doublons_identiques=()):
    """Compare tous les envois de la journee entre eux, hors copies deja signalees en D1.

    acks : liste de (guid, nom, LotAck). Retourne (chevauchements, virements_multi).
    chevauchements : une ligne par paire d'envois ayant au moins un virement commun (D2).
    virements_multi : une ligne par virement (payeur, IBAN, montant, nom) present dans
    plusieurs envois distincts (D3), avec la liste des envois concernes.
    """
    exclus = {(d["guid"], d["fichier"]) for d in doublons_identiques}
    lots = [(g, n, a) for g, n, a in acks if (g, n) not in exclus and a.virements]
    index = defaultdict(list)                       # cle virement -> [indice de lot, ...]
    for i, (_, _, a) in enumerate(lots):
        for v in a.virements:
            index[_cle(a.iban_payeur, v)].append(i)

    virements_multi = []
    communs = Counter()
    for cle, idxs in index.items():
        distincts = sorted(set(idxs))
        if len(distincts) < 2:
            continue
        payeur, iban, montant, nom = cle
        virements_multi.append({
            "payeur": payeur, "iban": iban, "montant_cts": montant, "nom": nom,
            "nb_envois": len(distincts),
            "envois": " | ".join(lots[i][1] for i in distincts),
            "guids": " | ".join(sorted({lots[i][0] for i in distincts})),
            "gravite": KO,
        })
        for i, j in combinations(distincts, 2):
            communs[(i, j)] += 1

    chevauchements = []
    for (i, j), nb in sorted(communs.items()):
        ga, na, a = lots[i]
        gb, nb_, b = lots[j]
        plus_petit = min(len(a.virements), len(b.virements))
        chevauchements.append({
            "guid": ga, "fichier": na, "guid_autre": gb, "fichier_autre": nb_,
            "nb_virements": len(a.virements), "nb_virements_autre": len(b.virements),
            "nb_communs": nb, "pct_commun": round(100 * nb / plus_petit) if plus_petit else 0,
            "montant_commun_cts": sum(v.montant_cts for v in a.virements
                                      if index.get(_cle(a.iban_payeur, v)) and j in index[_cle(a.iban_payeur, v)]),
            "gravite": KO,
        })
    virements_multi.sort(key=lambda r: (-r["montant_cts"], r["iban"]))
    return chevauchements, virements_multi


# ------------------------------------------------------------------ D4
def doublons_intra_envoi(acks):
    """Meme beneficiaire (IBAN) et meme montant plusieurs fois dans un meme envoi.

    Deux factures de meme montant sont possibles : la ligne est A_VERIFIER, et devient KO si
    les occurrences portent la meme reference de paiement Oracle.
    """
    lignes = []
    for guid, nom, ack in acks:
        groupes = defaultdict(list)
        for v in ack.virements:
            groupes[(v.iban, v.montant_cts)].append(v)
        for (iban, montant), vs in groupes.items():
            if len(vs) < 2:
                continue
            refs = [ref_paiement(v) for v in vs]
            memes_refs = len(set(refs)) < len(refs) and any(refs)
            lignes.append({
                "guid": guid, "fichier": nom, "iban": iban, "montant_cts": montant,
                "nom": vs[0].nom, "occurrences": len(vs),
                "references": " | ".join(r or "?" for r in refs),
                "gravite": KO if memes_refs else A_VERIFIER,
                "detail": ("meme reference de paiement repetee" if memes_refs
                           else "references de paiement distinctes : deux factures possibles"),
            })
    return lignes


# ------------------------------------------------------------------ D5
def dossiers_cible_precedents(racine, date, jours):
    """Dossiers JJMMAAAA (ou JJMMAAAA_cible) de la racine dont la date est dans les `jours` jours avant `date`."""
    racine = Path(racine)
    ref = datetime.strptime(date, "%d%m%Y")
    out = []
    for d in racine.iterdir():
        m = re.fullmatch(r"(\d{8})(?:_cible)?", d.name)
        if not m or m.group(1) == date or not d.is_dir():
            continue
        try:
            dt = datetime.strptime(m.group(1), "%d%m%Y")
        except ValueError:
            continue
        if timedelta(0) < ref - dt <= timedelta(days=jours):
            out.append((m.group(1), d))
    return sorted(out)


def charger_envois(dossier_cible):
    """Tous les ACK d'un dossier cible : liste de (guid, nom, LotAck)."""
    acks = []
    for inst in sorted(p for p in Path(dossier_cible).iterdir() if p.is_dir()):
        for f in sorted((inst / "TARGET").glob("CDPG.NC4.IMPORT_ACK.*")):
            if not f.name.endswith(".asc"):
                acks.append((inst.name, f.name, parse_ack(f)))
    return acks


def doublons_historique(acks, racine, date, jours=7):
    """Envois ou virements du jour deja transmis un jour precedent.

    ACK_IDENTIQUE / FICHIER_REJOUE : KO. VIREMENT_DEJA_ENVOYE : A_VERIFIER (un paiement
    recurrent de meme montant au meme beneficiaire est legitime).
    Retourne (lignes, nb_jours_compares).
    """
    precedents = dossiers_cible_precedents(racine, date, jours)
    empreintes, noms, virements = {}, {}, {}
    for d, dossier in precedents:
        for guid, nom, ack in charger_envois(dossier):
            noms.setdefault(nom, (d, guid))
            if ack.virements:
                empreintes.setdefault(_empreinte_ack(ack), (d, guid, nom))
                for v in ack.virements:
                    virements.setdefault(_cle(ack.iban_payeur, v), (d, nom))

    lignes = []
    for guid, nom, ack in acks:
        if nom in noms:
            d, g = noms[nom]
            lignes.append({"guid": guid, "fichier": nom, "type": "FICHIER_REJOUE", "gravite": KO,
                           "date_precedente": d, "fichier_precedent": nom,
                           "nb_virements": len(ack.virements),
                           "montant_cts": sum(v.montant_cts for v in ack.virements),
                           "detail": f"meme nom de fichier deja present le {d} (instance {g})"})
            continue
        if not ack.virements:
            continue
        origine = empreintes.get(_empreinte_ack(ack))
        if origine:
            d, g, n = origine
            lignes.append({"guid": guid, "fichier": nom, "type": "ACK_IDENTIQUE", "gravite": KO,
                           "date_precedente": d, "fichier_precedent": n,
                           "nb_virements": len(ack.virements),
                           "montant_cts": sum(v.montant_cts for v in ack.virements),
                           "detail": f"contenu identique a un envoi du {d} (instance {g})"})
            continue
        for v in ack.virements:
            deja = virements.get(_cle(ack.iban_payeur, v))
            if deja:
                d, n = deja
                lignes.append({"guid": guid, "fichier": nom, "type": "VIREMENT_DEJA_ENVOYE",
                               "gravite": A_VERIFIER, "date_precedente": d, "fichier_precedent": n,
                               "nb_virements": 1, "montant_cts": v.montant_cts,
                               "detail": f"{v.nom} / {v.iban} deja paye le {d}"})
    return lignes, len(precedents)


# ------------------------------------------------------------------ D6
def _empreinte_lot(lot):
    return tuple(sorted((v.iban, v.montant_cts, _norm_nom(v.nom)) for v in lot.virements))


def doublons_sources(instances_sources, oracle_rows_par_guid):
    """Fichiers DK_FIN01 rejoues.

    instances_sources : {guid: {nom_fichier: chemin}} des DK_FIN01 du dossier cible.
    oracle_rows_par_guid : {guid: [OracleRow]}.
    """
    lignes = []
    par_nom = defaultdict(list)
    par_contenu = defaultdict(list)
    for guid, fichiers in instances_sources.items():
        for nom, chemin in fichiers.items():
            par_nom[nom].append(guid)
            lot = parse_dk_fin01(chemin)
            if lot.virements:
                par_contenu[_empreinte_lot(lot)].append((guid, nom, lot))
    for nom, guids in sorted(par_nom.items()):
        if len(guids) > 1:
            lignes.append({"type": "FICHIER_DANS_PLUSIEURS_INSTANCES", "gravite": KO, "fichier": nom,
                           "guids": " | ".join(sorted(guids)), "nb_virements": "", "montant_cts": "",
                           "detail": f"present dans {len(guids)} instances"})
    for lots in par_contenu.values():
        noms = sorted({n for _, n, _ in lots})
        if len(noms) > 1:
            lot = lots[0][2]
            lignes.append({"type": "CONTENU_IDENTIQUE", "gravite": A_VERIFIER, "fichier": " | ".join(noms),
                           "guids": " | ".join(sorted({g for g, _, _ in lots})),
                           "nb_virements": len(lot.virements),
                           "montant_cts": sum(v.montant_cts for v in lot.virements),
                           "detail": "memes virements sous des noms de fichier differents"})
    refs = Counter()
    for guid, rows in oracle_rows_par_guid.items():
        for r in rows:
            refs[(r.nom_fichier_source, guid)] += 1
    par_source = defaultdict(list)
    for (nom, guid), n in refs.items():
        par_source[nom] += [guid] * n
    for nom, guids in sorted(par_source.items()):
        if len(guids) > 1:
            lignes.append({"type": "REFERENCE_ORACLE_MULTIPLE", "gravite": KO, "fichier": nom,
                           "guids": " | ".join(sorted(set(guids))), "nb_virements": "", "montant_cts": "",
                           "detail": f"reference {len(guids)} fois par le CSV Oracle"})
    return lignes
