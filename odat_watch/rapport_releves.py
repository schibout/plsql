"""Rapport HTML autonome de l'onglet Relevés bancaires (même charte que rapport_matin)."""
from __future__ import annotations

import html
import numbers
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

from rapport_matin import STYLE
from releves import COLONNES_CHRONO, COLONNES_CONTINUITE, COLONNES_PFE, COLONNES_PLAN, Journee, TON_VERDICT

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"
CLASSE = {"ok": "ok", "warn": "warn", "ko": "ko", "neutral": "na"}
STYLE_FRISE = """
  .frise { display: flex; gap: 8px; align-items: stretch; margin: 6px 0 14px; flex-wrap: wrap; }
  .pas { flex: 1 1 150px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px; padding: 9px 10px; border-top: 4px solid #8b949e; }
  .pas.ok { border-top-color: #1F9D55; } .pas.warn { border-top-color: #D9A400; } .pas.ko { border-top-color: #D23F31; }
  .pas b { display: block; font-size: .78em; text-transform: uppercase; color: #57606a; }
  .pas span { font-size: .82em; }
  .flux { margin-bottom: 10px; }
  .causes { background: #fff8e1; border-left: 4px solid #D9A400; padding: 8px 12px; font-size: .85em; margin: 6px 0 12px; }
  .causes.ko { background: #fbdcdc; border-left-color: #D23F31; }
"""


@dataclass
class Bilan:
    journee: Journee
    chronologie: pd.DataFrame = field(default_factory=pd.DataFrame)
    continuite: pd.DataFrame = field(default_factory=pd.DataFrame)
    plan: list = field(default_factory=list)
    pfe: pd.DataFrame = field(default_factory=pd.DataFrame)
    controles: pd.DataFrame = field(default_factory=pd.DataFrame)


def _bool(v) -> bool:
    return isinstance(v, (bool, np.bool_))


def _num(v) -> bool:
    return isinstance(v, numbers.Number) and not _bool(v)


def _manquant(v) -> bool:
    """None, NaN, pd.NA, NaT (pd.isna sur un scalaire ; une liste/série n'est pas « manquante »)."""
    if v is None:
        return True
    try:
        return bool(pd.isna(v))
    except (TypeError, ValueError):
        return False


def _t(v) -> str:
    """Texte échappé d'une cellule : vide pour None/NaN/NA/NaT, « oui »/« non » pour les booléens, entiers sans « .0 »."""
    if _manquant(v):
        return ""
    if _bool(v):
        return "oui" if v else "non"
    if isinstance(v, numbers.Real) and not isinstance(v, numbers.Integral) and float(v).is_integer():
        return str(int(v))
    return html.escape(str(v))


def _table(df: pd.DataFrame, colonnes: dict[str, str]) -> str:
    if df is None or df.empty:
        return "<div class='vide'>aucune donnée</div>"
    head = "".join(f"<th>{html.escape(l)}</th>" for l in colonnes.values())
    rows = []
    for _, r in df.iterrows():
        rows.append("<tr>" + "".join(
            f"<td class='num'>{_t(r[c])}</td>" if _num(r[c]) else f"<td>{_t(r[c])}</td>"
            for c in colonnes) + "</tr>")
    return f"<div class='tablewrap'><table><thead><tr>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>"


def _frise(flux) -> str:
    pas = "".join(f"<div class='pas {CLASSE[e['ton']]}'><b>{_t(e['libelle'])}</b><span>{_t(e['texte'])}</span></div>"
                  for e in flux.etapes)
    cls = TON_VERDICT[flux.verdict]
    causes = ("" if not flux.causes else
              f"<div class='causes {cls}'>" + "<br>".join(_t(c) for c in flux.causes) + "</div>")
    return (f"<div class='flux'><h3>Flux {flux.code} <span class='pill {CLASSE[cls]}'>{_t(flux.verdict)}</span></h3>"
            f"<div class='frise'>{pas}</div>{causes}</div>")


def construire(b: Bilan) -> str:
    j = b.journee
    cls = CLASSE[TON_VERDICT[j.verdict]]
    msg = {"OK": "Les deux flux ont été intégrés.", "WARN": "À surveiller.", "KO": "Rupture de la chaîne des relevés.",
           "—": "Pas d'intégration attendue (" + (j.motif or "aucune donnée") + ")."}[j.verdict]
    plan = ("<div class='vide'>aucun fichier à rejouer</div>" if not b.plan else _table(pd.DataFrame(b.plan), COLONNES_PLAN))
    cont = b.continuite
    if cont is not None and not cont.empty:   # retard ou trou, hors comptes connus
        cont = cont[((cont["trou"] == True) | (cont["retard_j"].fillna(0) > 1)) & ~cont["connu"].astype(bool)]  # noqa: E712
        cont = cont.sort_values("retard_j", ascending=False)
    sections = [
        ("Matinée du %s" % j.jour.strftime("%d/%m/%Y"), "".join(_frise(f) for f in j.flux.values())),
        ("Chronologie des imports", _table(b.chronologie, COLONNES_CHRONO)),
        ("Continuité des comptes (retard ou trou, hors comptes connus)", _table(cont, COLONNES_CONTINUITE)),
        ("Plan de reprise", plan),
        ("Rapprochement PFE ↔ EBS", _table(b.pfe, COLONNES_PFE)),
        ("Contrôles DKA_SRBCTRLRB", _table(b.controles, {"executed_at": "Exécuté le", "request_id": "Request", "date_reference": "Date de référence",
                                                        "nb_anomalies": "Anomalies", "nb_sg": "dont SG", "nb_hors_connus": "hors comptes connus"})),
    ]
    corps = "".join(f"<h2>{html.escape(t)}</h2>{c}" for t, c in sections)
    return f"""<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8"><title>Relevés bancaires — {j.jour:%d/%m/%Y}</title>
<style>{STYLE}{STYLE_FRISE}</style></head><body><div class="wrap">
<h1>🏦 Relevés bancaires — matinée du {j.jour:%d/%m/%Y}</h1>
<div class="meta"><span>Généré le {datetime.now():%d/%m/%Y %H:%M}</span><span>Flux A = multi-banques 07:50 · Flux B = Société Générale 08:20</span></div>
<div class="bandeau {cls}"><strong>{_t(j.verdict)}</strong>{_t(msg)}</div>
{corps}
<div class="footer">ODAT Watch · rapport Relevés bancaires</div></div></body></html>"""


def ecrire(b: Bilan, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Releves_{b.journee.jour:%Y%m%d}_{datetime.now():%H%M}.html"
    chemin.write_text(construire(b), encoding="utf-8")
    return chemin
