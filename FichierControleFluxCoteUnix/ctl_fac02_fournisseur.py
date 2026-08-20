#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ctl_fac02_fournisseur.py - Controle du flux FAC02 factures FOURNISSEURS

Usage : python ctl_fac02_fournisseur.py <fichier_SRC> [fichier_CTL]
        Si le fichier CTL est omis, il est deduit du nom du fichier SRC
        (remplacement de _SRC_ par _CTL_).

Structure du fichier SRC fournisseurs (differente du flux clients) :
  - 1re ligne = en-tete (ignoree)
  - separateur ';', montants DECIMAUX A VIRGULE, deja signes
  - champs utiles (index a partir de 1) : 3=Compte Comptable Achat,
    6=Code folio, 10=Montant, 12=Date de la piece, 13=Numero de piece

Regle de rapprochement (verifiee sur le fichier du 19/08/2026) :
  - NB_FACTURES (CTL col 3) = nb de lignes SRC sur comptes fournisseurs 401*
  - MONTANT (CTL col 4)     = somme des montants de ces lignes 401*

Traitements identiques au flux clients : synthese par folio, rapprochement
SRC <-> CTL, factures a montant 0, rapport Excel
rapport\\FAC02_SYNTHESE_FOURNISSEURS_<horodatage>.xlsx.

Code retour : 0 = rapprochement OK, 1 = ecart detecte, 2 = erreur usage
"""

import os
import sys
from collections import defaultdict

from ctl_fac02 import fr, lire_ctl, generer_excel


def lire_src(chemin):
    """Agrege les lignes comptes fournisseurs 401* par code folio."""
    cnt = defaultdict(int)
    amt = defaultdict(int)          # en centimes pour rester exact
    zeros = []
    with open(chemin, "r", encoding="latin-1") as f:
        for num, ligne in enumerate(f):
            if num == 0:            # ligne d'en-tete
                continue
            ch = ligne.rstrip("\r\n").split(";")
            if len(ch) < 13 or not ch[2].startswith("401"):
                continue
            folio, compte = ch[5], ch[2]
            date_piece, piece = ch[11], ch[12]
            try:
                m = int(round(float((ch[9] or "0").replace(",", ".")) * 100))
            except ValueError:
                print("ATTENTION : montant illisible ligne %d : '%s' "
                      "(compte comme 0)" % (num + 1, ch[9]), file=sys.stderr)
                m = 0
            cnt[folio] += 1
            amt[folio] += m
            if m == 0:
                zeros.append((folio, piece, compte, date_piece))
    return cnt, amt, zeros


def main():
    if len(sys.argv) < 2:
        print("Usage : %s <fichier_SRC> [fichier_CTL]" % sys.argv[0], file=sys.stderr)
        return 2
    src = sys.argv[1]
    ctl = sys.argv[2] if len(sys.argv) > 2 else src.replace("_SRC_", "_CTL_")
    for chemin in (src, ctl):
        if not os.path.isfile(chemin):
            print("ERREUR : fichier introuvable : %s" % chemin, file=sys.stderr)
            return 2

    print("=" * 77)
    print(" CONTROLE FLUX FAC02 - FACTURES FOURNISSEURS")
    print(" Fichier SRC : %s" % src)
    print(" Fichier CTL : %s" % ctl)
    print("=" * 77)

    cnt, amt, zeros = lire_src(src)
    attendu = lire_ctl(ctl)

    print("\n--- 1. SYNTHESE PAR FOLIO (fichier SRC) ---")
    for p in sorted(cnt):
        print("Folio %-4s : %5d factures, montant %15s"
              % (p, cnt[p], fr(amt[p] / 100.0)))

    print("\n--- 2. RAPPROCHEMENT SRC <-> CTL ---")
    ecart = False
    rappro = []
    for p in sorted(set(cnt) | set(attendu)):
        ligne = {"ptf": p, "src_cnt": cnt.get(p), "src_amt": None,
                 "ctl_cnt": None, "ctl_amt": None, "statut": "ECART"}
        if p in cnt:
            ligne["src_amt"] = round(amt[p] / 100.0, 2)
        if p in attendu:
            ligne["ctl_cnt"], ligne["ctl_amt"] = attendu[p]
        if p not in attendu:
            print("ECART  %-4s : present dans SRC mais absent du CTL (%d factures)"
                  % (p, cnt[p]))
            ecart = True
        elif p not in cnt:
            print("ECART  %-4s : present dans CTL mais absent du SRC" % p)
            ligne["src_cnt"] = 0
            ecart = True
        else:
            sa = amt[p] / 100.0
            nb_ctl, amt_ctl = attendu[p]
            if cnt[p] == nb_ctl and abs(sa - amt_ctl) < 0.005:
                print("OK     %-4s : %5d factures, montant %s" % (p, cnt[p], fr(sa)))
                ligne["statut"] = "OK"
            else:
                print("ECART  %-4s : SRC=%d factures / %s  --  CTL=%d factures / %s"
                      % (p, cnt[p], fr(sa), nb_ctl, fr(amt_ctl)))
                ecart = True
        rappro.append(ligne)

    print("\n--- 3. FACTURES A MONTANT 0 ---")
    if not zeros:
        print("Aucune facture a montant 0.")
    else:
        for p, piece, compte, date_piece in zeros:
            print("Folio %-4s piece %-15s compte %s date %s"
                  % (p, piece, compte, date_piece))
        print("TOTAL : %d facture(s) a montant 0" % len(zeros))

    print("\n--- 4. RAPPORT EXCEL ---")
    xlsx = generer_excel(src, ctl, rappro, zeros, ecart,
                         titre="CONTROLE FLUX FAC02 - FACTURES FOURNISSEURS",
                         libelle="Folio",
                         prefixe="FAC02_SYNTHESE_FOURNISSEURS")
    if xlsx:
        print("Rapport genere : %s" % xlsx)

    print("\n" + "=" * 77)
    if ecart:
        print(" RESULTAT : ECART(S) DETECTE(S) - voir section 2")
        print("=" * 77)
        return 1
    print(" RESULTAT : RAPPROCHEMENT OK")
    print("=" * 77)
    return 0


if __name__ == "__main__":
    sys.exit(main())
