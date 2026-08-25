#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Selection commune du fichier SRC d'un export CLIENT, FOURNISSEUR ou GL.

Deux usages :
  selectionner_source.py CLIENT|FOURNISSEUR|GL [dossier|fichier_SRC]
      affiche le chemin du SRC de ce flux (comportement historique) ;
  selectionner_source.py --detecter [dossier|fichier_SRC]
      affiche une ligne "TYPE;chemin" par fichier SRC present sous l'entree
      (tous les exports, pas seulement le plus recent), ce qui permet au
      lanceur unique controle.bat de tous les controler.
"""

import fnmatch
import sys
from pathlib import Path


MOTIFS = {
    "CLIENT": "*_SRC_FACTURESCLIENTS*.CSV",
    "FOURNISSEUR": "*_SRC_FACTURESFOURNISSEURS*.CSV",
    "GL": "*_SRC_ECRITURESGL*.CSV",
}


class ErreurSelection(Exception):
    """Le dossier ou le fichier ne permet pas de selectionner un SRC valide."""


def _correspond(type_flux: str, chemin: Path) -> bool:
    return fnmatch.fnmatchcase(chemin.name.upper(), MOTIFS[type_flux])


def lister_sources(type_flux: str, entree=None):
    """Tous les fichiers SRC du flux sous l'entree, du plus ancien au plus recent."""
    type_normalise = str(type_flux).strip().upper()
    if type_normalise not in MOTIFS:
        raise ErreurSelection("type de flux inconnu : %s" % type_flux)

    racine = Path(entree).expanduser() if entree is not None and str(entree).strip() else Path(__file__).resolve().parent
    if not racine.exists():
        raise ErreurSelection("fichier ou dossier introuvable : %s" % racine)

    if racine.is_file():
        if racine.parent.name.upper() != "SOURCE":
            raise ErreurSelection("le fichier SRC doit etre place dans un repertoire SOURCE : %s" % racine)
        if not _correspond(type_normalise, racine):
            raise ErreurSelection(
                "le fichier ne correspond pas au flux %s (%s) : %s"
                % (type_normalise, MOTIFS[type_normalise], racine)
            )
        return [racine.resolve()]

    candidats = [
        chemin
        for chemin in racine.rglob("*")
        if chemin.is_file()
        and chemin.parent.name.upper() == "SOURCE"
        and _correspond(type_normalise, chemin)
    ]
    if not candidats:
        raise ErreurSelection(
            "aucun fichier %s trouve dans un repertoire SOURCE sous %s"
            % (MOTIFS[type_normalise], racine)
        )

    return [
        chemin.resolve()
        for chemin in sorted(
            candidats,
            key=lambda chemin: (chemin.stat().st_mtime_ns, str(chemin).lower()),
        )
    ]


def selectionner_source(type_flux: str, entree=None) -> Path:
    return lister_sources(type_flux, entree)[-1]


def detecter_flux(entree=None):
    """Fichiers SRC presents sous l'entree, tous exports confondus.

    Renvoie une liste de couples (type, chemin), dans l'ordre CLIENT,
    FOURNISSEUR, GL puis du plus ancien au plus recent. Un dossier parent
    contenant plusieurs exports du meme flux les renvoie donc tous, pour
    qu'ils soient chacun controles.
    """
    trouves = []
    for type_flux in MOTIFS:
        try:
            trouves.extend((type_flux, chemin) for chemin in lister_sources(type_flux, entree))
        except ErreurSelection:
            continue
    if not trouves:
        raise ErreurSelection(
            "aucun flux CLIENT, FOURNISSEUR ou GL trouve sous %s"
            % (entree if entree else "le dossier du lanceur")
        )
    return trouves


def main(arguments=None) -> int:
    args = list(sys.argv[1:] if arguments is None else arguments)
    if not 1 <= len(args) <= 2:
        print(
            "ERREUR : usage : selectionner_source.py CLIENT|FOURNISSEUR|GL|--detecter "
            "[dossier|fichier_SRC]",
            file=sys.stderr,
        )
        return 1
    entree = args[1] if len(args) == 2 else None
    try:
        if args[0] == "--detecter":
            for type_flux, chemin in detecter_flux(entree):
                print("%s;%s" % (type_flux, chemin))
        else:
            print(selectionner_source(args[0], entree))
        return 0
    except ErreurSelection as exc:
        print("ERREUR : %s" % exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
