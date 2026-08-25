#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_talend.py - Controle du statut Talend d'un export

Usage : python controle_talend.py <fichier_SRC>

A partir du fichier SRC (place dans <export>\\SOURCE), le script remonte au
dossier d'export et exploite :
  - <export>\\TALEND\\LS_IN.OK ou LS_IN.KO : marqueur de fin de traitement
    Talend (le fichier contient le code de statut, ex. LOG_F_0006_APPSOURCE
    ou ERR_F_0002_DATAVALIDATION) ;
  - <export>\\TARGET\\*_ERR_FORMAT_*.csv : detail des erreurs de formatage
    produites par Talend quand le marqueur est KO (1re ligne = nom du fichier
    source, 2e ligne = en-tete, puis une ligne par erreur).

Code retour : 0 = Talend OK, 1 = KO / erreurs de formatage, 2 = erreur technique
"""

import glob
import os
import sys


def _lire_marqueur(chemin):
    """Retourne (code, fichier vise) d'un marqueur LS_IN.*.

    Le marqueur contient le code de statut (ex. ERR_F_0002_DATAVALIDATION),
    parfois suivi, sur une deuxieme ligne, du nom du fichier source concerne.
    """
    try:
        with open(chemin, "r", encoding="latin-1") as f:
            lignes = [l.strip() for l in f if l.strip()]
    except OSError as exc:
        return "(illisible : %s)" % exc, None
    if not lignes:
        return "(fichier vide)", None
    return lignes[0], lignes[1] if len(lignes) > 1 else None


def _indices_utiles(entete):
    """Repere dynamiquement les colonnes interessantes de l'en-tete."""
    idx = {}
    for i, cellule in enumerate(entete):
        c = cellule.strip().lower()
        if "ligne" in c and "idx_ligne" not in idx:
            idx["idx_ligne"] = i
        elif c == "erreur":
            idx["idx_erreur"] = i
        elif "folio" in c:
            idx["idx_folio"] = i
        elif c.startswith("num") and ("pi\xe8ce" in c or "piece" in c):
            idx["idx_piece"] = i
    return idx


def afficher_err_format(chemin):
    """Affiche le detail d'un fichier *_ERR_FORMAT_*.csv, retourne le nb d'erreurs."""
    with open(chemin, "r", encoding="latin-1") as f:
        lignes = [l.rstrip("\r\n") for l in f]
    if len(lignes) < 2:
        print("  (fichier d'erreurs vide ou incomplet)")
        return 0

    print("  Fichier source vise : %s" % lignes[0].strip())
    entete = lignes[1].split(";")
    idx = _indices_utiles(entete)
    par_type = {}
    nb = 0
    for brute in lignes[2:]:
        if not brute.strip():
            continue
        ch = brute.split(";")
        nb += 1

        def val(cle):
            i = idx.get(cle)
            return ch[i].strip() if i is not None and i < len(ch) else ""

        erreur = val("idx_erreur") or "(erreur non renseignee)"
        # Une ligne peut cumuler plusieurs erreurs separees par des virgules
        # (ex. "CodeSociete:empty or null,CodeTache:empty or null") : chacune
        # compte pour son propre type dans les totaux.
        for elementaire in erreur.split(","):
            elementaire = elementaire.strip()
            if elementaire:
                par_type[elementaire] = par_type.get(elementaire, 0) + 1
        detail = []
        if val("idx_ligne"):
            detail.append("ligne %s" % val("idx_ligne").lstrip("0").rjust(1))
        if val("idx_folio"):
            detail.append("folio %s" % val("idx_folio"))
        if val("idx_piece"):
            detail.append("piece %s" % val("idx_piece"))
        print("  %-45s %s" % (erreur, ", ".join(detail)))

    print("  " + "-" * 69)
    for erreur in sorted(par_type):
        print("  TOTAL %-39s : %d ligne(s)" % (erreur, par_type[erreur]))
    return nb


def main():
    if len(sys.argv) != 2:
        print("Usage : %s <fichier_SRC>" % sys.argv[0], file=sys.stderr)
        return 2
    src = os.path.abspath(sys.argv[1])
    if not os.path.isfile(src):
        print("ERREUR : fichier introuvable : %s" % src, file=sys.stderr)
        return 2

    export = os.path.dirname(os.path.dirname(src))   # SOURCE -> dossier export
    talend = os.path.join(export, "TALEND")
    target = os.path.join(export, "TARGET")
    marqueur_ok = os.path.join(talend, "LS_IN.OK")
    marqueur_ko = os.path.join(talend, "LS_IN.KO")

    if not os.path.isdir(talend):
        print("ERREUR : dossier TALEND introuvable : %s" % talend, file=sys.stderr)
        return 2

    if os.path.isfile(marqueur_ko):
        code, fichier_vise = _lire_marqueur(marqueur_ko)
        print("Marqueur Talend : LS_IN.KO (statut %s)" % code)
        if fichier_vise:
            print("Fichier vise    : %s" % fichier_vise)
        erreurs_format = sorted(glob.glob(os.path.join(target, "*_ERR_FORMAT_*.csv")))
        if not erreurs_format:
            print("ATTENTION : aucun fichier *_ERR_FORMAT_*.csv trouve dans %s" % target)
        total = 0
        for chemin in erreurs_format:
            print("\nDetail des erreurs de formatage : %s" % os.path.basename(chemin))
            total += afficher_err_format(chemin)
        print("\n[KO] Traitement Talend en erreur : %d ligne(s) rejetee(s) "
              "pour erreur de formatage." % total)
        return 1

    if os.path.isfile(marqueur_ok):
        code, _ = _lire_marqueur(marqueur_ok)
        print("Marqueur Talend : LS_IN.OK (statut %s)" % code)
        print("[OK] Traitement Talend termine sans erreur de formatage.")
        return 0

    print("ERREUR : aucun marqueur LS_IN.OK / LS_IN.KO dans %s" % talend,
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
