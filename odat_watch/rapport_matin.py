"""Rapport HTML du contrôle du matin, dans la charte des Rapport_Verification_*.html
(cf. FichierControleFluxCoteUnix/rapport_reconciliation.py) : bandeau, tuiles, un tableau par section.

Module pur : il met en page un Resultat, ne lit ni Oracle ni SQLite.
"""
from __future__ import annotations
import html
from pathlib import Path

import pandas as pd

from controle_matin import COMPTEURS, LIBELLES, Resultat

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"

JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

CLASSE_STATUT = {"OK": "ok", "WARNING": "warn", "ALERTE": "ko", "ERREUR": "ko"}
MESSAGE_STATUT = {
    "OK": "Tous les indicateurs sont au vert.",
    "WARNING": "Des indicateurs sont sous leur seuil ou des traitements sont en avertissement : à vérifier.",
    "ALERTE": "Traitements en erreur ou factures Xerox sans image : action requise.",
    "ERREUR": "Une partie du contrôle n'a pas pu être exécutée (erreur Oracle) : les compteurs concernés ne sont pas fiables.",
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
  .tn { font-size: .73em; color: #57606a; text-transform: uppercase; letter-spacing: .03em; margin-top: 4px; }
  table { border-collapse: collapse; width: 100%; background: #fff; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  th { background: #003366; color: #fff; padding: 9px 10px; text-align: left; font-size: .77em; white-space: nowrap; }
  td { padding: 6px 10px; border-bottom: 1px solid #eceff2; font-size: .81em; white-space: nowrap; }
  tr:nth-child(even) td { background: #fafbfc; }
  tr:hover td { background: #eef4fd; }
  td.num { text-align: right; font-variant-numeric: tabular-nums; }
  td:empty::after { content: '-'; color: #c9ced4; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px; font-size: .8em; font-weight: 600; margin-top: 4px; }
  .pill.ok   { background: #d7f2e3; color: #0b6b3a; }
  .pill.warn { background: #fff4d6; color: #7a5600; }
  .pill.ko   { background: #fbdcdc; color: #9b1c1c; }
  .vide { color: #8b949e; font-style: italic; font-size: .88em; padding: 8px 2px; }
  .erreur { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; border-radius: 6px;
            padding: 9px 14px; font-family: Consolas, Menlo, monospace; font-size: .82em; white-space: pre-wrap; }
  .footer { font-size: .76em; color: #8b949e; margin-top: 30px; text-align: center; }
  @media print { body { background: #fff; padding: 0; } }
"""


def _t(valeur) -> str:
    return html.escape("" if valeur is None or (isinstance(valeur, float) and pd.isna(valeur)) else str(valeur))


def _nb(valeur) -> str:
    if valeur is None:
        return "?"
    return format(int(valeur), ",").replace(",", " ")


def _tuile(cle: str, res: Resultat) -> str:
    val = res.compteurs.get(cle)
    if cle in res.erreurs_synthese:
        pill = '<span class="pill ko">non contrôlé</span>'
    elif cle in res.statuts:
        pill = f'<span class="pill {"ok" if res.statuts[cle] == "OK" else "warn"}">{res.statuts[cle]}</span>'
    elif cle in ("nb_erreurs", "nb_images_manq"):
        pill = f'<span class="pill {"ko" if (val or 0) > 0 else "ok"}">{"ALERTE" if (val or 0) > 0 else "OK"}</span>'
    elif cle == "nb_warnings":
        pill = f'<span class="pill {"warn" if (val or 0) > 0 else "ok"}">{"W" if (val or 0) > 0 else "OK"}</span>'
    else:
        pill = ""
    return (f'<div class="tile"><div class="tv">{_nb(val)}</div>'
            f'<div class="tn">{_t(LIBELLES[cle])}</div>{pill}</div>')


def _bandeau(res: Resultat) -> str:
    cls = CLASSE_STATUT.get(res.statut_global, "ko")
    rappel = ""
    if res.executed_at.weekday() == 0:
        rappel = ("<br><b>Rappel lundi :</b> charger manuellement le fichier SG (Société Générale), "
                  "les imports automatiques ne tournent pas le dimanche.")
    return (f'<div class="bandeau {cls}"><strong>Statut global : {_t(res.statut_global)}</strong>'
            f'{_t(MESSAGE_STATUT.get(res.statut_global, ""))}{rappel}</div>')


def _table(df: pd.DataFrame) -> str:
    if df is None or df.empty:
        return '<div class="vide">Aucune ligne.</div>'
    num = {c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])}
    head = "".join(f"<th>{_t(c)}</th>" for c in df.columns)
    rows = []
    for _, r in df.iterrows():
        cells = "".join(f'<td class="num">{_t(r[c])}</td>' if c in num else f"<td>{_t(r[c])}</td>" for c in df.columns)
        rows.append(f"<tr>{cells}</tr>")
    return f'<div class="tablewrap"><table><thead><tr>{head}</tr></thead><tbody>{"".join(rows)}</tbody></table></div>'


def construire(res: Resultat) -> str:
    d = res.executed_at
    meta = (f'<span>📅 {JOURS[d.weekday()].capitalize()} {d:%d/%m/%Y} à {d:%H:%M}</span>'
            f'<span>Plage contrôlée : {res.debut:%d/%m/%Y %H:%M} → {res.fin:%d/%m/%Y %H:%M}</span>'
            f'<span>Historique : {res.nb_jours_histo} j</span>'
            f'<span>Durée : {res.duree_s} s</span>')
    if res.date_rb_max:
        meta += f'<span>Dernier import RB : {res.date_rb_max:%d/%m/%Y}</span>'
    tuiles = "".join(_tuile(c, res) for c in COMPTEURS)
    corps = []
    for sec in res.sections:
        titre = _t(sec.titre) + (f' <span class="pill ko">{sec.nb}</span>' if sec.alerte else "")
        corps.append(f"<h2>{titre}</h2>")
        corps.append(f'<div class="erreur">{_t(sec.erreur)}</div>' if sec.erreur else _table(sec.df))
    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Contrôle quotidien FIN-FINANCE — {res.date_ctrl:%d/%m/%Y}</title>
<style>{STYLE}</style>
</head>
<body><div class="wrap">
<h1>Contrôle quotidien FIN-FINANCE — {res.date_ctrl:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
{_bandeau(res)}
<div class="tiles">{tuiles}</div>
{"".join(corps)}
<div class="footer">ODAT Watch · contrôle du matin · portage de Controle_Quotidien_Complet.sql</div>
</div></body>
</html>
"""


def ecrire(res: Resultat, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Controle_Matin_{res.executed_at:%Y%m%d_%H%M}.html"
    chemin.write_text(construire(res), encoding="utf-8")
    res.fichier_rapport = str(chemin)
    return chemin
