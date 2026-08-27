#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""reconciliation.py - Cascade d'integration d'un export, de la source a Oracle

Usage : python reconciliation.py <dossier_export> [--csv [fichier]]

Les controles ctl_fac02*.py et ctl_ecritures_gl.py rapprochent le fichier SRC
de son fichier CTL : ils disent si l'application amont s'est trompee, pas si
le flux est arrive dans Oracle. Ce script prend la suite en chainant les cinq
etages que l'export permet de reconstituer :

    SRC (demi-flux 1)
      -> cible du demi-flux 2   Header.csv + Line.csv, FIN01, pivot GL
      -> publies                TS\\TALEND\\TS_OUT (compteur Talend)
      -> rejets                 REJETS_FONCTIONNELS (piece, code, libelle)
      -> Oracle                 controle par Verifier_Oracle_*.ps1

Le resultat n'est plus un OK/KO mais un diagnostic qui nomme l'etage en cause :

    INTEGRE_COMPLET         tout le fichier est parti vers Oracle
    INTEGRE_PARTIEL_REJETS  le reste est parti, N pieces sont rejetees et
                            listees avec leur code et leur libelle d'erreur
    NON_PUBLIE              le demi-flux 2 n'a pas abouti (TS_OUT KO/absent)
    ECART_INEXPLIQUE        la cascade ne boucle pas, l'etage est designe
    DEMI_FLUX2_ABSENT       le demi-flux 2 n'a pas ete rapatrie

Identites de cascade, verifiees sur les exports du depot :

    FOURNISSEURS  publies = lignes(Header) + lignes(Line)
                          = lignes de donnees du SRC - lignes rejetees
    CLIENTS       publies = lignes(FACTURESCLIENTS_FIN01) = lignes du SRC
    GL            lignes(pivot GL) = lignes du SRC, debit = credit

Codes retour : 0 = integration complete, 1 = erreur technique,
               2 = rejets ou ecart a traiter.
"""

import csv
import sys
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Dict, List, Optional, Sequence

import demiflux2
from demiflux2 import ErreurDemiFlux2


EXIT_OK = 0
EXIT_TECHNIQUE = 1
EXIT_ANOMALIE = 2

INTEGRE_COMPLET = "INTEGRE_COMPLET"
INTEGRE_PARTIEL_REJETS = "INTEGRE_PARTIEL_REJETS"
NON_PUBLIE = "NON_PUBLIE"
ECART_INEXPLIQUE = "ECART_INEXPLIQUE"
DEMI_FLUX2_ABSENT = "DEMI_FLUX2_ABSENT"

DIAGNOSTICS_OK = (INTEGRE_COMPLET,)

# Index (a partir de 0) des colonnes du SRC fournisseurs, communes aux
# variantes FAC02 et PRN01 : compte, folio, montant, numero de piece.
SRC_FRS_COMPTE = 2
SRC_FRS_FOLIO = 5
SRC_FRS_MONTANT = 9
SRC_FRS_PIECE = 12


class ErreurReconciliation(Exception):
    """L'export ne permet pas de reconstituer la cascade."""


@dataclass
class Cascade:
    """Les etages de la cascade pour un fichier transmis."""

    dossier: str
    type_flux: str
    instance: str
    fichier: str
    nb_src: Optional[int] = None
    nb_cible: Optional[int] = None
    nb_publies: Optional[int] = None
    nb_pieces_rejetees: int = 0
    nb_lignes_rejetees: int = 0
    montant_src: Optional[int] = None                  # centimes
    montant_cible: Optional[int] = None                # centimes
    montant_rejete: int = 0                            # centimes
    statut_ls: Optional[str] = None
    statut_ts: Optional[str] = None
    diagnostic: str = ECART_INEXPLIQUE
    explication: str = ""
    rejets: List[demiflux2.PieceRejetee] = field(default_factory=list)

    @property
    def conforme(self) -> bool:
        return self.diagnostic in DIAGNOSTICS_OK

    @property
    def codes_rejets(self) -> str:
        """Codes d'erreur distincts, dans l'ordre de rencontre."""
        codes = []
        for rejet in self.rejets:
            code = rejet.code or "(sans code)"
            if code not in codes:
                codes.append(code)
        return ", ".join(codes)


@dataclass
class Resultat:
    dossier: Path
    cascades: List[Cascade] = field(default_factory=list)
    code_retour: int = EXIT_OK


def _lignes_donnees(chemin: Path):
    """Lignes de donnees d'un fichier SRC, en-tete de colonnes exclu.

    Les SRC fournisseurs commencent par une ligne d'intitules, les SRC clients
    et GL non : l'en-tete est reconnu a son premier champ non numerique plutot
    qu'au type de flux, pour rester valable sur les variantes de format.
    """
    premiere = True
    try:
        fichier = chemin.open("r", encoding=demiflux2.ENCODAGE, newline="")
    except OSError as exc:
        raise ErreurReconciliation("impossible de lire %s : %s" % (chemin, exc)) from exc
    with fichier:
        for champs in csv.reader(fichier, delimiter=";"):
            if not champs or not any(champ.strip() for champ in champs):
                continue
            if premiere:
                premiere = False
                if not champs[0].strip()[:1].isdigit():
                    continue
            yield champs


def _mesurer_src_fournisseur(chemin: Path):
    """Lignes totales et montant des lignes de comptes fournisseurs 401*."""
    nb_lignes = 0
    montant = 0
    for champs in _lignes_donnees(chemin):
        nb_lignes += 1
        compte = champs[SRC_FRS_COMPTE].strip() if len(champs) > SRC_FRS_COMPTE else ""
        if compte.startswith("401") and len(champs) > SRC_FRS_MONTANT:
            montant += demiflux2.centimes(champs[SRC_FRS_MONTANT])
    return nb_lignes, montant


def _mesurer_rejets_fournisseur(rejets: List[demiflux2.Rejet]):
    """Montant des lignes rejetees portant un compte fournisseur 401*.

    La ligne source rejetee est conservee telle quelle dans le fichier de
    rejets : elle se relit avec les memes index que le SRC.
    """
    montant = 0
    for rejet in rejets:
        champs = rejet.ligne_source.split(";")
        compte = champs[SRC_FRS_COMPTE].strip() if len(champs) > SRC_FRS_COMPTE else ""
        if compte.startswith("401") and len(champs) > SRC_FRS_MONTANT:
            montant += demiflux2.centimes(champs[SRC_FRS_MONTANT])
    return montant


def _montant_client(texte: str) -> int:
    """Montant client en centimes, quelle que soit son ecriture.

    Le flux clients exprime ses montants en centimes aux deux etages, mais
    pas de la meme facon : l'application amont ecrit 6371, le fichier que le
    demi-flux 1 produit et que le demi-flux 2 consomme ecrit 6371.00. La
    valeur numerique est la meme, seule sa forme change : il n'y a donc pas
    de conversion, seulement une lecture tolerante aux decimales.
    """
    valeur = (texte or "").strip().replace(",", ".")
    if not valeur:
        return 0
    try:
        return int(Decimal(valeur).to_integral_value())
    except (InvalidOperation, ArithmeticError, ValueError):
        return 0


def _mesurer_src_client(chemin: Path):
    """Lignes totales et montant signe des lignes de comptes clients 411*."""
    nb_lignes = 0
    montant = 0
    for champs in _lignes_donnees(chemin):
        nb_lignes += 1
        if len(champs) < 17 or not champs[6].strip().startswith("411"):
            continue
        valeur = _montant_client(champs[12])
        if champs[13].strip() == "-":
            valeur = -valeur
        if champs[11].strip().upper() == "C":
            valeur = -valeur
        montant += valeur
    return nb_lignes, montant


def _diagnostiquer(cascade: Cascade, statut: demiflux2.StatutTalend) -> None:
    """Compare les etages de la cascade et nomme celui qui casse."""
    if not statut.abouti:
        cascade.diagnostic = NON_PUBLIE
        cascade.explication = (
            "le demi-flux 2 n'a pas abouti (TS_OUT %s)" % (statut.ts or "absent")
        )
        return

    attendu = None
    if cascade.nb_src is not None:
        attendu = cascade.nb_src - cascade.nb_lignes_rejetees

    if cascade.nb_publies is not None and cascade.nb_cible is not None:
        if cascade.nb_publies != cascade.nb_cible:
            cascade.diagnostic = ECART_INEXPLIQUE
            cascade.explication = (
                "etage cible -> publies : %d enregistrement(s) dans le fichier "
                "cible pour %d publie(s)" % (cascade.nb_cible, cascade.nb_publies)
            )
            return

    if attendu is not None and cascade.nb_publies is not None:
        if attendu != cascade.nb_publies:
            cascade.diagnostic = ECART_INEXPLIQUE
            manque = attendu - cascade.nb_publies
            cascade.explication = (
                "etage source -> publies : %d ligne(s) attendue(s) (%d du SRC "
                "moins %d rejetee(s)) pour %d publiee(s), soit %+d"
                % (attendu, cascade.nb_src, cascade.nb_lignes_rejetees,
                   cascade.nb_publies, -manque)
            )
            return

    if cascade.nb_pieces_rejetees:
        cascade.diagnostic = INTEGRE_PARTIEL_REJETS
        cascade.explication = (
            "%d piece(s) rejetee(s) (%s), le reste du fichier est integre"
            % (cascade.nb_pieces_rejetees, cascade.codes_rejets)
        )
        return

    cascade.diagnostic = INTEGRE_COMPLET
    cascade.explication = "tout le fichier est parti vers Oracle"


def _cascade_instance(dossier: Path, instance: demiflux2.Instance) -> Cascade:
    """Cascade d'une instance du demi-flux 2."""
    statut = demiflux2.lire_statut(instance)
    rejets = demiflux2.lire_rejets(instance)
    pieces_rejetees = demiflux2.grouper_rejets(rejets)
    cible = demiflux2.lire_cible(instance)
    repris = demiflux2.fichier_repris(instance)

    cascade = Cascade(
        dossier=dossier.name,
        type_flux=instance.type_flux,
        instance=instance.guid,
        fichier=instance.fichier_source or (repris.stem if repris else ""),
        nb_publies=statut.nb_publies,
        nb_pieces_rejetees=len(pieces_rejetees),
        nb_lignes_rejetees=len(rejets),
        statut_ls=statut.ls,
        statut_ts=statut.ts,
        rejets=pieces_rejetees,
    )

    if cible is not None:
        cascade.nb_cible = cible.nb_enregistrements
    if repris is not None:
        if instance.type_flux == "FOURNISSEUR":
            cascade.nb_src, cascade.montant_src = _mesurer_src_fournisseur(repris)
            cascade.montant_rejete = _mesurer_rejets_fournisseur(rejets)
            if isinstance(cible, demiflux2.CibleAp):
                cascade.montant_cible = cible.montant
        elif instance.type_flux == "CLIENT":
            cascade.nb_src, cascade.montant_src = _mesurer_src_client(repris)
            if isinstance(cible, demiflux2.CibleAr):
                cascade.montant_cible = sum(cible.montant_par_portefeuille.values())
        else:
            cascade.nb_src = sum(1 for _ in _lignes_donnees(repris))

    _diagnostiquer(cascade, statut)
    return cascade


def _cascade_gl(dossier: Path) -> List[Cascade]:
    """Cascade des exports GL, dont le demi-flux 2 n'est pas rapatrie.

    Le fichier pivot produit en sortie du demi-flux 1 porte deja le code
    application et le nom du fichier source qui deviennent ATTRIBUTE9 et
    ATTRIBUTE10 dans GL_INTERFACE : il fait foi de ce qui part vers Oracle.
    """
    cascades = []
    for pivot in demiflux2.fichiers_pivot_gl(dossier):
        cible = demiflux2.lire_cible_gl(pivot)
        src = None
        for candidat in sorted((pivot.parent.parent / "SOURCE").glob("*_SRC_*")):
            if demiflux2.deduire_type(candidat.name) == "GL":
                src = candidat
                break
        cascade = Cascade(
            dossier=dossier.name,
            type_flux="GL",
            instance=pivot.parent.parent.name,
            fichier=src.stem if src else pivot.stem,
            nb_cible=cible.nb_lignes,
            montant_cible=cible.debit,
            diagnostic=DEMI_FLUX2_ABSENT,
        )
        if src is not None:
            cascade.nb_src = sum(1 for _ in _lignes_donnees(src))
            cascade.montant_src = sum(
                demiflux2.centimes(champs[demiflux2.GL_DEBIT])
                for champs in _lignes_donnees(src)
                if len(champs) > demiflux2.GL_DEBIT
            )

        details = []
        if cascade.nb_src is not None and cascade.nb_src != cible.nb_lignes:
            details.append(
                "le pivot contient %d ligne(s) pour %d dans le SRC"
                % (cible.nb_lignes, cascade.nb_src)
            )
        if not cible.equilibre:
            details.append(
                "%d piece(s) desequilibree(s)" % len(cible.pieces_desequilibrees)
            )
        if details:
            cascade.diagnostic = ECART_INEXPLIQUE
            cascade.explication = " ; ".join(details)
        else:
            cascade.explication = (
                "demi-flux 2 non rapatrie : pivot GL conforme au SRC et "
                "equilibre, integration Oracle a confirmer par "
                "Verifier_Oracle_Ecritures_GL.ps1"
            )
        cascades.append(cascade)
    return cascades


def dossier_export(entree) -> Path:
    """Dossier d'export d'un chemin, qu'on lui donne le dossier ou un fichier.

    Les lanceurs controle*.bat travaillent sur le chemin d'un fichier SRC,
    range en <export>\\SOURCE\\<instance>\\SOURCE\\<fichier> : la remontee
    s'arrete au premier dossier parent qui porte les deux demi-flux, ou a
    defaut l'un des deux.
    """
    chemin = Path(entree).expanduser().resolve()
    if chemin.is_file():
        chemin = chemin.parent
    if not chemin.is_dir():
        raise ErreurReconciliation("dossier d'export introuvable : %s" % chemin)

    # Les dossiers d'instance portent eux aussi SOURCE et TARGET : le dossier
    # d'export est le premier qui les porte sans etre lui-meme range dans un
    # demi-flux.
    reserves = {"SOURCE", "TARGET", "TALEND", "TMP", "LS", "TS"}
    candidat = chemin
    while True:
        porte_demi_flux = (candidat / "SOURCE").is_dir() or (candidat / "TARGET").is_dir()
        if (
            porte_demi_flux
            and candidat.name.upper() not in reserves
            and candidat.parent.name.upper() not in reserves
        ):
            return candidat
        if candidat.parent == candidat:
            return chemin
        candidat = candidat.parent


def trouver_exports(racine) -> List[Path]:
    """Dossiers d'export ranges sous une racine, du plus ancien au plus recent.

    Permet de traiter une journee entiere en une fois : la racine passee aux
    lanceurs contient un dossier par folio rapatrie.
    """
    chemin = Path(racine).expanduser().resolve()
    if not chemin.is_dir():
        return []
    exports = [
        candidat
        for candidat in sorted(chemin.iterdir())
        if candidat.is_dir()
        and ((candidat / "SOURCE").is_dir() or (candidat / "TARGET").is_dir())
        and candidat.name.upper() not in ("SOURCE", "TARGET")
    ]
    return exports


def reconcilier_tous(racine) -> List[Resultat]:
    """Cascade de tous les exports d'une racine, le plus souvent une journee.

    Un export illisible n'interrompt pas les autres : il est signale et la
    consolidation continue, pour que le rapport du matin reste exploitable.
    """
    resultats = []
    for export in trouver_exports(racine) or [Path(racine)]:
        try:
            resultats.append(reconcilier(export))
        except ErreurReconciliation as exc:
            print("ATTENTION : %s ignore : %s" % (export.name, exc),
                  file=sys.stderr)
    if not resultats:
        raise ErreurReconciliation("aucun export exploitable sous %s" % racine)
    return resultats


def reconcilier(entree) -> Resultat:
    """Cascade de tous les fichiers transmis d'un dossier d'export."""
    dossier = dossier_export(entree)

    try:
        instances = demiflux2.trouver_instances(dossier)
        cascades = [_cascade_instance(dossier, instance) for instance in instances]
        if not cascades:
            cascades = _cascade_gl(dossier)
    except ErreurDemiFlux2 as exc:
        raise ErreurReconciliation(str(exc)) from exc

    if not cascades:
        raise ErreurReconciliation(
            "ni demi-flux 2 ni pivot GL sous %s : rien a reconcilier" % dossier
        )

    resultat = Resultat(dossier=dossier, cascades=cascades)
    if any(cascade.diagnostic not in DIAGNOSTICS_OK for cascade in cascades):
        resultat.code_retour = EXIT_ANOMALIE
    return resultat


def _euros(centimes: Optional[int]) -> str:
    if centimes is None:
        return "-"
    return ("%.2f" % (centimes / 100.0)).replace(".", ",")


def _entier(valeur: Optional[int]) -> str:
    return "-" if valeur is None else str(valeur)


def afficher(resultat: Resultat) -> None:
    print("=" * 79)
    print(" RECONCILIATION SOURCE -> ORACLE")
    print(" Export : %s" % resultat.dossier)
    print("=" * 79)
    for cascade in resultat.cascades:
        print("\nFlux %s - instance %s" % (cascade.type_flux, cascade.instance))
        print("  Fichier : %s" % (cascade.fichier or "-"))
        print("  Temoins Talend : LS %s / TS %s"
              % (cascade.statut_ls or "-", cascade.statut_ts or "-"))
        print("  %-24s %10s %18s" % ("ETAGE", "NB", "MONTANT"))
        print("  " + "-" * 54)
        print("  %-24s %10s %18s"
              % ("1. SRC (demi-flux 1)", _entier(cascade.nb_src),
                 _euros(cascade.montant_src)))
        print("  %-24s %10s %18s"
              % ("2. Cible (demi-flux 2)", _entier(cascade.nb_cible),
                 _euros(cascade.montant_cible)))
        print("  %-24s %10s %18s"
              % ("3. Publies (Talend)", _entier(cascade.nb_publies), "-"))
        print("  %-24s %10s %18s"
              % ("4. Rejets", "%d piece(s)" % cascade.nb_pieces_rejetees,
                 _euros(cascade.montant_rejete) if cascade.montant_rejete else "-"))
        print("  " + "-" * 54)
        print("  DIAGNOSTIC : %s" % cascade.diagnostic)
        if cascade.explication:
            print("               %s" % cascade.explication)
        if cascade.rejets:
            print("\n  PIECES REJETEES :")
            print("  %-22s %-9s %-40s" % ("PIECE", "CODE", "LIBELLE"))
            for rejet in cascade.rejets:
                print("  %-22s %-9s %-40s"
                      % (rejet.piece[:22], rejet.code or "-", rejet.libelle[:40]))
                if rejet.appel:
                    print("  %-22s %s" % ("", rejet.appel))

    print("\n" + "=" * 79)
    if resultat.code_retour == EXIT_OK:
        print(" RESULTAT : INTEGRATION COMPLETE")
    else:
        print(" RESULTAT : %d fichier(s) a traiter - voir les diagnostics"
              % sum(1 for c in resultat.cascades if not c.conforme))
    print("=" * 79)


COLONNES_CASCADE = [
    "Type", "Fichier", "Nb SRC", "Montant SRC", "Nb Cible", "Montant Cible",
    "Nb Publies", "Nb Pieces Rejetees", "Montant Rejete", "Diagnostic",
]
COLONNES_REJETS = [
    "Fichier", "Piece", "Code", "Libelle", "Nb Lignes", "Appel PL/SQL",
    "Horodatage",
]
COLONNES_STATUTS = [
    "Instance", "Fichier", "Statut LS", "Statut TS", "Nb Publies",
]


def _euros_excel(valeur: Optional[int]) -> Optional[float]:
    """Montant en euros pour Excel, qui doit recevoir un nombre et non un texte."""
    return None if valeur is None else round(valeur / 100.0, 2)


def onglets(resultat: Resultat) -> List[dict]:
    """Les trois onglets que la reconciliation ajoute au classeur de l'export.

    Cascade donne l'etat de chaque fichier transmis, Rejets la liste des
    pieces a traiter avec leur motif, Statuts Talend les temoins bruts qui
    permettent de remonter a l'instance.
    """
    sous_titre = "Export %s" % resultat.dossier.name

    cascade = [
        {
            "Type": c.type_flux,
            "Fichier": c.fichier,
            "Nb SRC": c.nb_src,
            "Montant SRC": _euros_excel(c.montant_src),
            "Nb Cible": c.nb_cible,
            "Montant Cible": _euros_excel(c.montant_cible),
            "Nb Publies": c.nb_publies,
            "Nb Pieces Rejetees": c.nb_pieces_rejetees,
            "Montant Rejete": _euros_excel(c.montant_rejete) or None,
            "Diagnostic": c.diagnostic,
        }
        for c in resultat.cascades
    ]

    rejets = [
        {
            "Fichier": c.fichier,
            "Piece": rejet.piece,
            "Code": rejet.code or "(sans code)",
            "Libelle": rejet.libelle,
            "Nb Lignes": rejet.nb_lignes,
            "Appel PL/SQL": rejet.appel,
            "Horodatage": rejet.horodatage,
        }
        for c in resultat.cascades
        for rejet in c.rejets
    ]

    statuts = [
        {
            "Instance": c.instance,
            "Fichier": c.fichier,
            "Statut LS": c.statut_ls or "-",
            "Statut TS": c.statut_ts or "-",
            "Nb Publies": c.nb_publies,
        }
        for c in resultat.cascades
    ]

    return [
        {
            "nom": "Cascade",
            "titre": "CASCADE D'INTEGRATION SOURCE -> ORACLE",
            "sous_titre": sous_titre,
            "colonnes": COLONNES_CASCADE,
            "colonne_statut": "Diagnostic",
            "valeurs_ok": list(DIAGNOSTICS_OK),
            "lignes": cascade,
        },
        {
            "nom": "Rejets",
            "titre": "PIECES REJETEES PAR LES CONTROLES FONCTIONNELS",
            "sous_titre": sous_titre,
            "colonnes": COLONNES_REJETS,
            "lignes": rejets,
        },
        {
            "nom": "Statuts Talend",
            "titre": "TEMOINS TALEND DU DEMI-FLUX 2",
            "sous_titre": sous_titre,
            "colonnes": COLONNES_STATUTS,
            "colonne_statut": "Statut TS",
            "valeurs_ok": ["OK"],
            "lignes": statuts,
        },
    ]


def generer_excel(resultat: Resultat) -> Optional[Path]:
    """Ajoute les onglets de reconciliation au classeur de synthese de l'export.

    Le classeur est celui que produisent les controles locaux, nomme d'apres
    le dossier d'export : la reconciliation vient l'enrichir plutot que
    d'ouvrir un second fichier.
    """
    try:
        import openpyxl  # noqa: F401
    except ImportError:
        print("INFO : openpyxl non installe, onglets de reconciliation non "
              "ajoutes (pip install openpyxl)", file=sys.stderr)
        return None

    from rapport_excel import ajouter_onglets, dossier_rapport

    classeur = Path(dossier_rapport()) / ("%s.xlsx" % resultat.dossier.name)
    try:
        ajouter_onglets(str(classeur), onglets(resultat), creer=True)
    except (OSError, PermissionError) as exc:
        print("ATTENTION : onglets de reconciliation non ajoutes : %s" % exc,
              file=sys.stderr)
        return None
    return classeur


COLONNES_CSV = [
    "Dossier", "Type", "Instance", "Fichier", "Nb SRC", "Nb Cible",
    "Nb Publies", "Nb Pieces Rejetees", "Nb Lignes Rejetees", "Montant SRC",
    "Montant Cible", "Montant Rejete", "Statut LS", "Statut TS", "Diagnostic",
    "Detail Rejets", "Explication",
]


def lignes_csv(resultats) -> List[List[str]]:
    """Cascades sous forme tabulaire, pour les rapports Excel et PowerShell.

    Accepte un resultat ou une liste : la consolidation d'une journee et le
    controle d'un seul export produisent le meme tableau.
    """
    if isinstance(resultats, Resultat):
        resultats = [resultats]
    lignes = []
    for cascade in (c for resultat in resultats for c in resultat.cascades):
        lignes.append([
            cascade.dossier,
            cascade.type_flux,
            cascade.instance,
            cascade.fichier,
            _entier(cascade.nb_src),
            _entier(cascade.nb_cible),
            _entier(cascade.nb_publies),
            str(cascade.nb_pieces_rejetees),
            str(cascade.nb_lignes_rejetees),
            _euros(cascade.montant_src),
            _euros(cascade.montant_cible),
            _euros(cascade.montant_rejete),
            cascade.statut_ls or "",
            cascade.statut_ts or "",
            cascade.diagnostic,
            cascade.codes_rejets,
            cascade.explication,
        ])
    return lignes


def ecrire_csv(resultats, destination=None) -> None:
    """Ecrit les cascades en CSV point-virgule, comme les rapports du depot."""
    if destination:
        # UTF-8 avec BOM, comme Rapport_Verification : sans lui, Excel lit les
        # accents de travers a l'ouverture.
        fichier = open(destination, "w", encoding="utf-8-sig", newline="")
    else:
        fichier = sys.stdout
    try:
        redacteur = csv.writer(fichier, delimiter=";", lineterminator="\n")
        redacteur.writerow(COLONNES_CSV)
        redacteur.writerows(lignes_csv(resultats))
    finally:
        if destination:
            fichier.close()


def _option(args: List[str], nom: str):
    """Retire une option et sa valeur facultative de la ligne de commande.

    Renvoie (presente, valeur). La valeur est celle qui suit l'option, sauf
    si c'est une autre option ou le dossier d'entree.
    """
    if nom not in args:
        return False, None
    index = args.index(nom)
    args.pop(index)
    if index < len(args) and not args[index].startswith("-") and len(args) > 1:
        return True, args.pop(index)
    return True, None


USAGE = ("ERREUR : usage : reconciliation.py <dossier> [--tous] "
         "[--csv [fichier]] [--html [fichier]] [--sans-rapport]")


def executer(arguments: Optional[Sequence[str]] = None) -> int:
    args = list(sys.argv[1:] if arguments is None else arguments)
    # --sans-rapport : n'ecrit pas dans le classeur Excel de l'export, pour
    # les appels qui ne veulent que le diagnostic.
    sans_rapport, _ = _option(args, "--sans-rapport")
    tous, _ = _option(args, "--tous")
    sortie_csv, destination_csv = _option(args, "--csv")
    sortie_html, destination_html = _option(args, "--html")
    if len(args) != 1:
        print(USAGE, file=sys.stderr)
        return EXIT_TECHNIQUE

    try:
        resultats = reconcilier_tous(args[0]) if tous else [reconcilier(args[0])]
    except ErreurReconciliation as exc:
        print("ERREUR : %s" % exc, file=sys.stderr)
        return EXIT_TECHNIQUE

    # Le CSV part sur la sortie standard quand aucun fichier n'est donne :
    # l'affichage lisible laisserait alors la place a des lignes parasites.
    csv_sur_sortie = sortie_csv and destination_csv is None
    if sortie_csv:
        ecrire_csv(resultats, destination_csv)
    if not csv_sur_sortie:
        for resultat in resultats:
            afficher(resultat)

    if not sans_rapport and not csv_sur_sortie:
        for resultat in resultats:
            classeur = generer_excel(resultat)
            if classeur:
                print(" Rapport Excel : %s" % classeur)

    if sortie_html:
        import rapport_reconciliation

        chemin = rapport_reconciliation.ecrire(resultats, destination_html)
        if not csv_sur_sortie:
            print(" Rapport HTML  : %s" % chemin)

    return (EXIT_ANOMALIE
            if any(r.code_retour == EXIT_ANOMALIE for r in resultats)
            else EXIT_OK)


if __name__ == "__main__":
    sys.exit(executer())
