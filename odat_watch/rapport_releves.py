"""Rapport HTML autonome de l'onglet Relevés bancaires (même charte que rapport_matin)."""
from __future__ import annotations

import html
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

import pandas as pd

from rapport_matin import STYLE
from releves import Journee, TON_VERDICT

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


def _t(v) -> str:
    return "" if v is None or (isinstance(v, float) and pd.isna(v)) else html.escape(str(v))


def _table(df: pd.DataFrame, colonnes: dict[str, str]) -> str:
    if df is None or df.empty:
        return "<div class='vide'>aucune donnée</div>"
    head = "".join(f"<th>{html.escape(l)}</th>" for l in colonnes.values())
    rows = []
    for _, r in df.iterrows():
        rows.append("<tr>" + "".join(
            f"<td class='num'>{_t(r[c])}</td>" if isinstance(r[c], (int, float)) and not isinstance(r[c], bool) else f"<td>{_t(r[c])}</td>"
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
    plan = ("<div class='vide'>aucun fichier à rejouer</div>" if not b.plan else _table(pd.DataFrame(b.plan), {
        "ordre": "Étape", "chemin": "Fichier source", "origine": "Origine", "periode": "Relevé", "nb_releves": "Relevés",
        "attendu": "Résultat attendu"}))
    cont = b.continuite
    if cont is not None and not cont.empty:
        cont = cont[(cont["trou"] == True) | (cont["retard_j"].fillna(0) > 1)].sort_values("retard_j", ascending=False)  # noqa: E712
    sections = [
        ("Matinée du %s" % j.jour.strftime("%d/%m/%Y"), "".join(_frise(f) for f in j.flux.values())),
        ("Chronologie des imports", _table(b.chronologie, {"debut": "Date / heure", "request_id": "Request", "fichier": "Fichier EBS",
                                                           "flux": "Flux", "lus": "Lus", "ecrits": "Écrits", "charges": "Chargés",
                                                           "erreurs": "Erreurs", "resultat": "Résultat"})),
        ("Continuité des comptes (retard ou trou)", _table(cont, {"compte": "Compte", "dernier_charge": "Dernier relevé chargé",
                                                                  "attendu": "Attendu", "retard_j": "Retard (j)", "trou": "Trou", "connu": "Connu"})),
        ("Plan de reprise", plan),
        ("Rapprochement PFE ↔ EBS", _table(b.pfe, {"horodatage": "Exécution PFE", "uuid": "UUID", "flux": "Flux", "nb_releves": "Relevés",
                                                  "date_min": "Du", "date_max": "Au", "fichier_ebs": "Fichier EBS", "request_id": "Import",
                                                  "statut": "Statut"})),
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
