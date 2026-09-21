"""Rapport HTML du contrôle des virements (Oracle → FIN01.VIREMENT → banque → Quartz), dans la charte des
Rapport_Verification_*.html (cf. rapport_matin.py) : synthèse en haut (bandeau, tuiles, points d'attention),
tableaux de détail en bas (doublons, contrôles de forme, niveaux 0 à 3).

Module pur : met en page un rapport relu par virements.lire_rapport, ne lance rien.
"""
from __future__ import annotations
import re
from datetime import datetime
from pathlib import Path

import pandas as pd

import virements as vr
from rapport_matin import JOURS, STYLE, _t, _table

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"


def _nb(v) -> str:
    return f"{int(v):,}".replace(",", " ")


def _eur(v) -> str:
    return f"{float(v):,.2f} €".replace(",", " ").replace(".", ",")


def _tuile(valeur, libelle, cls: str = "") -> str:
    pill = f'<span class="pill {cls}">{ {"ok": "OK", "warn": "À VÉRIFIER", "ko": "ACTION"}[cls] }</span>' if cls else ""
    return f'<div class="tile"><div class="tv">{_t(valeur)}</div><div class="tn">{_t(libelle)}</div>{pill}</div>'


def _tuiles(r: dict) -> str:
    return "".join([
        _tuile(_nb(r["nb_envoyes"]), "virements transmis à la banque"),
        _tuile(_eur(r["montant_envoye"]), "montant transmis"),
        _tuile(_nb(r["ko"]), "doublons / forme bloquants", "ko" if r["ko"] else "ok"),
        _tuile(_nb(r["a_verifier"]), "points à vérifier", "warn" if r["a_verifier"] else "ok"),
        _tuile(_nb(r["ecarts"]), "écarts de totaux / lignes", "ko" if r["ecarts"] else "ok"),
        _tuile("repris" if r["quartz"] else "non fourni", "retour trésorerie (Quartz)", "ok" if r["quartz"] else "warn"),
        _tuile(_nb(r["nb_rejets"]), "rejets bancaires du jour", "warn" if r["nb_rejets"] else "ok"),
    ])


def _bandeau(r: dict) -> str:
    if r["ok"]:
        cls, titre, msg = "ok", "Conforme", "Tous les virements préparés ont été transmis une seule fois, sans perte ni écart."
    elif r["ko"] or r["ecarts"]:
        cls, titre, msg = "ko", "Anomalies", ("Des envois sont transmis en double, ou des totaux ne concordent pas "
                                              "entre Oracle, le fichier bancaire et la trésorerie : action requise.")
    else:
        cls, titre, msg = "warn", "À examiner", "Des points non bloquants sont à vérifier."
    extra = "" if r["quartz"] else "<br>Retour trésorerie non fourni : le niveau 3 (Quartz) n'a pas été contrôlé."
    return f'<div class="bandeau {cls}"><strong>Résultat : {titre}</strong>{_t(msg)}{extra}</div>'


def _markdown_simple(md: str) -> str:
    """Rend la synthèse simple de l'outil (titres, listes, gras) sans dépendance externe."""
    out, liste = [], False
    for ligne in md.splitlines():
        l = ligne.rstrip()
        if l.startswith("# "):            # titre du document : déjà porté par le h1
            continue
        est_item = l.startswith("- ")
        if liste and not est_item:
            out.append("</ul>")
            liste = False
        if not l:
            continue
        html = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", _t(l[2:] if est_item else l))
        html = re.sub(r"`(.+?)`", r"<code>\1</code>", html)
        if l.startswith("## "):
            out.append(f"<h3>{html[3:] if html.startswith('## ') else html.lstrip('# ')}</h3>")
        elif est_item:
            if not liste:
                out.append('<ul class="afaire">')
                liste = True
            cls = "ko" if any(m in l for m in ("double", "écart", "manquant", "KO")) else "warn"
            out.append(f'<li class="{cls}">{html}</li>')
        else:
            out.append(f'<p class="expl">{html}</p>')
    if liste:
        out.append("</ul>")
    return "".join(out)


def construire(rapport: dict, date: str) -> str:
    r = vr.resume(rapport)
    d = rapport["genere_le"]
    jour = datetime.strptime(date, "%d%m%Y")
    meta = (f'<span>📅 Journée du {jour:%d/%m/%Y}</span>'
            f'<span>Généré le {JOURS[d.weekday()]} {d:%d/%m/%Y} à {d:%H:%M}</span>'
            f'<span>Envois vers la banque : {len(rapport["totaux_edf"])}</span>'
            f'<span>Dossier : {_t(str(rapport["dossier"]))}</span>')
    corps = ["<h2>Synthèse</h2>", _markdown_simple(rapport["synthese_simple"] or rapport["synthese"])]

    doublons = [(cle, nom, lib) for cle, nom, lib in vr.CSV_RAPPORT if cle in vr.CLES_DOUBLONS and not rapport[cle].empty]
    corps.append("<h2>Détail — Doublons" + (f' <span class="pill ko">{len(doublons)} famille(s)</span>' if doublons else "") + "</h2>")
    if not doublons:
        corps.append('<div class="vide">Aucun doublon : envois identiques, chevauchements, virements multiples, intra-envoi, historique, sources.</div>')
    for cle, nom, lib in doublons:
        df = rapport[cle]
        corps.append(f'<h3>{_t(lib)} — {len(df)} ligne(s) <span class="src">{_t(nom)}</span></h3>')
        corps.append(_table(df))
    if not rapport["doublons_virements"].empty:
        corps.append(f'<h3>Liste pour la banque — {len(rapport["doublons_virements"])} virement(s) des envois en double</h3>')
        corps.append(_table(rapport["doublons_virements"]))

    sanite = rapport["sanite"]
    corps.append("<h2>Détail — Contrôles de forme" + (f' <span class="pill ko">{len(sanite)}</span>' if not sanite.empty else "") + "</h2>")
    corps.append(_table(sanite) if not sanite.empty else
                 '<div class="vide">Signature PGP, compte payeur, dates, pieds de fichier, code retour Talend, montants, IBAN, BIC : rien à signaler.</div>')

    for cle in ("fichiers", "totaux_source", "totaux_edf", "lignes", "quartz"):
        lib = next(l for c, _, l in vr.CSV_RAPPORT if c == cle)
        df = rapport[cle]
        corps.append(f"<h2>Détail — {_t(lib)} ({len(df)})</h2>")
        corps.append(_table(df) if not df.empty else
                     '<div class="vide">' + ("Aucun écart." if cle in ("lignes", "quartz") else "Vide.") + "</div>")

    rejets = rapport.get("rejets", pd.DataFrame())
    corps.append(f"<h2>Rejets bancaires du jour — {len(rejets)} virement(s)"
                 + (f" pour {_eur(r['montant_rejets'])}" if len(rejets) else "") + "</h2>")
    corps.append(_table(rejets) if len(rejets) else
                 '<div class="vide">Aucun rejet de virement reçu de la banque ce jour (ou fichier REJETS/JJMMAAAA_*.xls absent).</div>')

    style = STYLE + """
  ul.afaire { list-style: none; padding: 0; margin: 0; }
  ul.afaire li { background: #fff; border-left: 5px solid #dde3ea; border-radius: 4px; padding: 8px 12px;
                 margin-bottom: 6px; font-size: .88em; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  ul.afaire li.ko { border-left-color: #c62828; } ul.afaire li.warn { border-left-color: #e8a317; }
  p.expl { color: #57606a; font-size: .88em; margin: 6px 0; }
  h3 { color: #003366; font-size: .95em; margin: 18px 0 6px; } h3 .src { color: #8b949e; font-weight: normal; font-size: .85em; }
"""
    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Virements — contrôle du {jour:%d/%m/%Y}</title>
<style>{style}</style>
</head>
<body><div class="wrap">
<h1>Contrôle des virements — journée du {jour:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
{_bandeau(r)}
<div class="tiles">{_tuiles(r)}</div>
{"".join(corps)}
<div class="footer">ODAT Watch · contrôle des virements (Oracle → FIN01.VIREMENT → VIREMENT.EDF01 → Quartz) · rapport_{date}</div>
</div></body>
</html>
"""


def texte_court(rapport: dict, date: str) -> str:
    """Résumé à coller dans un mail ou Teams : la synthèse simple de l'outil, sans mise en forme markdown."""
    r = vr.resume(rapport)
    jour = datetime.strptime(date, "%d%m%Y")
    etat = "Conforme" if r["ok"] else "Anomalies" if (r["ko"] or r["ecarts"]) else "À examiner"
    lignes = [f"Contrôle des virements du {jour:%d/%m/%Y} : {etat}",
              f"- {_nb(r['nb_envoyes'])} virements transmis à la banque pour {_eur(r['montant_envoye'])}",
              f"- {_nb(r['ko'])} bloquant(s), {_nb(r['a_verifier'])} à vérifier, {_nb(r['ecarts'])} écart(s) de totaux ; "
              f"retour trésorerie : {'repris' if r['quartz'] else 'non fourni'}"]
    if r["nb_rejets"]:
        lignes.append(f"- {_nb(r['nb_rejets'])} virement(s) rejeté(s) par la banque pour {_eur(r['montant_rejets'])}")
    md = rapport["synthese_simple"] or ""
    items = [re.sub(r"\*\*|`", "", l[2:]).strip() for l in md.splitlines() if l.startswith("- ")]
    items = [i for i in items if not i.startswith(("Transmis à la banque", "Repris par la trésorerie", "Retour trésorerie"))]
    if items:
        lignes.append("Points d'attention :")
        lignes += [f"  • {i}" for i in items]
    return "\n".join(lignes)


def ecrire(rapport: dict, date: str, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Virements_{date}_{datetime.now():%H%M%S}.html"
    chemin.write_text(construire(rapport, date), encoding="utf-8")
    return chemin
