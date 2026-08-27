#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""rapport_reconciliation.py - Rapport HTML de la cascade source -> Oracle

Les classeurs Excel produits par les controles sont ranges par export : ils
repondent a la question "ce fichier est-il passe ?". L'exploitation a besoin
de l'autre vue, celle de la journee entiere : quels folios sont integres,
lesquels ont des pieces rejetees, et lesquelles.

Ce module met en page cette vue consolidee, dans la charte des rapports
Rapport_Verification_*.html de ControleFolioRose : bandeau de synthese,
tuiles de comptage, tableau des cascades puis tableau des pieces rejetees.

Il est appele par reconciliation.py --html ; il ne lit rien lui-meme.
"""

import html
from datetime import datetime
from pathlib import Path
from typing import List, Optional

import reconciliation
from reconciliation import (
    DEMI_FLUX2_ABSENT,
    ECART_INEXPLIQUE,
    INTEGRE_COMPLET,
    INTEGRE_PARTIEL_REJETS,
    NON_PUBLIE,
    Resultat,
)


# Couleur de la pastille de diagnostic. Le vocabulaire est celui de
# reconciliation.py : une seule valeur est un succes, les autres appellent
# une action differente, d'ou trois niveaux et non deux.
CLASSES = {
    INTEGRE_COMPLET: "ok",
    INTEGRE_PARTIEL_REJETS: "warn",
    DEMI_FLUX2_ABSENT: "warn",
    NON_PUBLIE: "ko",
    ECART_INEXPLIQUE: "ko",
}

STYLE = """
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 22px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1700px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 15px 22px; border-radius: 6px;
       font-size: 1.22em; margin: 0 0 12px 0; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 30px; font-size: 1.04em; }
  .meta { background: #e8f0fe; border-left: 4px solid #003366; padding: 9px 15px;
          margin-bottom: 15px; border-radius: 0 4px 4px 0; font-size: .85em; }
  .meta span { margin-right: 20px; display: inline-block; }
  .bandeau { padding: 13px 19px; border-radius: 6px; margin-bottom: 16px; font-size: .92em; }
  .bandeau strong { display: block; font-size: 1.14em; margin-bottom: 3px; }
  .bandeau.ok   { background: #d7f2e3; color: #0b6b3a; border: 1px solid #7fc9a3; }
  .bandeau.warn { background: #fff4d6; color: #7a5600; border: 1px solid #e8c46a; }
  .bandeau.ko   { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; }
  .tiles { display: flex; flex-wrap: wrap; gap: 11px; margin-bottom: 8px; }
  .tile { flex: 1 1 145px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 13px 9px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.45em; font-weight: 700; line-height: 1.15; }
  .tn { font-size: .73em; color: #57606a; text-transform: uppercase;
        letter-spacing: .03em; margin-top: 4px; }
  table { border-collapse: collapse; width: 100%; background: #fff; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px;
               box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  th { background: #003366; color: #fff; padding: 9px 10px; text-align: left;
       font-size: .77em; white-space: nowrap; position: sticky; top: 0; z-index: 2; }
  td { padding: 6px 10px; border-bottom: 1px solid #eceff2; font-size: .81em;
       white-space: nowrap; }
  tr:nth-child(even) td { background: #fafbfc; }
  tr:hover td { background: #eef4fd; }
  .mono { font-family: Consolas, Menlo, monospace; font-size: .95em; }
  .num  { text-align: right; font-variant-numeric: tabular-nums; }
  .ctr  { text-align: center; }
  .fic { max-width: 380px; overflow: hidden; text-overflow: ellipsis; }
  .exp { white-space: normal; color: #57606a; font-style: italic; max-width: 420px; }
  td:empty::after { content: '-'; color: #c9ced4; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px;
          font-size: .8em; font-weight: 600; }
  .pill.ok   { background: #d7f2e3; color: #0b6b3a; }
  .pill.warn { background: #fff4d6; color: #7a5600; }
  .pill.ko   { background: #fbdcdc; color: #9b1c1c; }
  .cascade span { color: #8b949e; margin: 0 5px; }
  .footer { font-size: .76em; color: #8b949e; margin-top: 30px; text-align: center; }
  @media print { body { background: #fff; padding: 0; } th { position: static; } }
"""


def _t(valeur) -> str:
    """Echappe une valeur pour l'inserer dans le HTML."""
    return html.escape("" if valeur is None else str(valeur))


def _nb(valeur: Optional[int]) -> str:
    return "" if valeur is None else format(valeur, ",").replace(",", " ")


def _euros(centimes: Optional[int]) -> str:
    if centimes is None:
        return ""
    signe = "-" if centimes < 0 else ""
    entiers, cents = divmod(abs(centimes), 100)
    return "%s%s,%02d" % (signe, format(entiers, ",").replace(",", " "), cents)


def _tuile(valeur, libelle) -> str:
    return ('<div class="tile"><div class="tv">%s</div>'
            '<div class="tn">%s</div></div>' % (_t(valeur), _t(libelle)))


def _bandeau(cascades) -> str:
    """Message de tete : ce que l'exploitant doit faire de cette journee."""
    rejets = [c for c in cascades if c.diagnostic == INTEGRE_PARTIEL_REJETS]
    bloquants = [c for c in cascades
                 if c.diagnostic in (NON_PUBLIE, ECART_INEXPLIQUE)]
    nb_pieces = sum(c.nb_pieces_rejetees for c in cascades)

    if bloquants:
        return ('<div class="bandeau ko"><strong>%d fichier(s) a examiner'
                '</strong>Un flux n\'a pas abouti ou sa cascade ne boucle pas : '
                'voir la colonne Explication.</div>' % len(bloquants))
    if rejets:
        return ('<div class="bandeau warn"><strong>%d piece(s) rejetee(s) sur '
                '%d fichier(s)</strong>Le reste des fichiers est integre. Les '
                'pieces ci-dessous sont a corriger dans le referentiel puis a '
                'rejouer.</div>' % (nb_pieces, len(rejets)))
    if any(c.diagnostic == DEMI_FLUX2_ABSENT for c in cascades):
        return ('<div class="bandeau warn"><strong>Integration a confirmer'
                '</strong>Le second demi-flux n\'a pas ete rapatrie pour '
                'certains flux : le controle s\'arrete au fichier pivot.</div>')
    return ('<div class="bandeau ok"><strong>Toutes les integrations sont '
            'completes</strong>Chaque fichier transmis a ete publie en '
            'totalite, sans rejet.</div>')


def _table_cascades(cascades) -> str:
    entetes = ["Export", "Type", "Fichier", "Cascade", "Nb SRC", "Nb publies",
               "Montant SRC", "Montant cible", "Rejets", "Diagnostic",
               "Explication"]
    lignes = []
    for c in cascades:
        cascade = '%s <span>&rarr;</span> %s <span>&rarr;</span> %s' % (
            _nb(c.nb_src) or "-", _nb(c.nb_cible) or "-", _nb(c.nb_publies) or "-"
        )
        lignes.append(
            "<tr>"
            '<td class="mono">%s</td>'
            '<td>%s</td>'
            '<td class="mono fic" title="%s">%s</td>'
            '<td class="ctr mono cascade">%s</td>'
            '<td class="num">%s</td>'
            '<td class="num">%s</td>'
            '<td class="num">%s</td>'
            '<td class="num">%s</td>'
            '<td class="num">%s</td>'
            '<td class="ctr"><span class="pill %s">%s</span></td>'
            '<td class="exp">%s</td>'
            "</tr>"
            % (
                _t(c.dossier), _t(c.type_flux), _t(c.fichier), _t(c.fichier),
                cascade, _nb(c.nb_src), _nb(c.nb_publies),
                _euros(c.montant_src), _euros(c.montant_cible),
                _nb(c.nb_pieces_rejetees) if c.nb_pieces_rejetees else "",
                CLASSES.get(c.diagnostic, "ko"), _t(c.diagnostic),
                _t(c.explication),
            )
        )
    return '<div class="tablewrap"><table><thead><tr>%s</tr></thead><tbody>%s' \
           "</tbody></table></div>" % (
               "".join("<th>%s</th>" % _t(e) for e in entetes), "".join(lignes)
           )


def _table_rejets(cascades) -> str:
    lignes = []
    for c in cascades:
        for rejet in c.rejets:
            lignes.append(
                "<tr>"
                '<td class="mono">%s</td><td class="mono fic" title="%s">%s</td>'
                '<td class="mono ctr">%s</td><td>%s</td><td class="num">%s</td>'
                '<td class="mono">%s</td><td class="mono">%s</td>'
                "</tr>"
                % (
                    _t(c.dossier), _t(c.fichier), _t(c.fichier),
                    _t(rejet.code or "(sans code)"), _t(rejet.libelle),
                    _t(rejet.nb_lignes), _t(rejet.piece), _t(rejet.appel),
                )
            )
    if not lignes:
        return '<div class="bandeau ok">Aucune piece rejetee.</div>'
    entetes = ["Export", "Fichier", "Code", "Libelle", "Nb lignes", "Piece",
               "Appel PL/SQL"]
    return '<div class="tablewrap"><table><thead><tr>%s</tr></thead><tbody>%s' \
           "</tbody></table></div>" % (
               "".join("<th>%s</th>" % _t(e) for e in entetes), "".join(lignes)
           )


def construire(resultats: List[Resultat], horodatage: Optional[str] = None) -> str:
    """Page HTML complete de la cascade, pour un ou plusieurs exports."""
    cascades = [c for resultat in resultats for c in resultat.cascades]
    genere = horodatage or datetime.now().strftime("%d/%m/%Y %H:%M:%S")

    complets = sum(1 for c in cascades if c.diagnostic == INTEGRE_COMPLET)
    nb_pieces = sum(c.nb_pieces_rejetees for c in cascades)
    montant_rejete = sum(c.montant_rejete for c in cascades)
    publies = sum(c.nb_publies or 0 for c in cascades)

    tuiles = "".join([
        _tuile(len(resultats), "Exports"),
        _tuile(len(cascades), "Fichiers transmis"),
        _tuile(complets, "Integres en totalite"),
        _tuile(_nb(publies), "Enregistrements publies"),
        _tuile(nb_pieces, "Pieces rejetees"),
        _tuile(_euros(montant_rejete), "Montant rejete"),
    ])

    return """<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Reconciliation source vers Oracle - %s</title>
<style>%s</style>
</head>
<body>
<div class="wrap">
<h1>Reconciliation source &rarr; Oracle &mdash; second demi-flux</h1>
<div class="meta"><span><strong>Genere le :</strong> %s</span>
<span><strong>Cascade :</strong> SRC &rarr; cible du demi-flux 2 &rarr; publies
&rarr; rejets</span></div>
%s
<div class="tiles">%s</div>
<h2>Cascade par fichier transmis</h2>
%s
<h2>Pieces rejetees par les controles fonctionnels</h2>
%s
<div class="footer">reconciliation.py &mdash; les comptages proviennent des
fichiers cibles du second demi-flux et du compteur Talend TS_OUT.</div>
</div>
</body>
</html>
""" % (_t(genere), STYLE, _t(genere), _bandeau(cascades), tuiles,
       _table_cascades(cascades), _table_rejets(cascades))


def ecrire(resultats: List[Resultat], destination=None) -> Path:
    """Ecrit le rapport HTML et renvoie son chemin.

    Sans destination, le rapport est range dans Logs\\ a cote des rapports de
    verification, avec le meme nommage horodate.
    """
    if destination is None:
        dossier = Path(reconciliation.__file__).resolve().parent / "Logs"
        dossier.mkdir(parents=True, exist_ok=True)
        destination = dossier / (
            "Rapport_Reconciliation_%s.html"
            % datetime.now().strftime("%d%m%Y_%H%M%S")
        )
    chemin = Path(destination)
    chemin.write_text(construire(resultats), encoding="utf-8")
    return chemin
