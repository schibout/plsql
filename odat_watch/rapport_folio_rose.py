"""Rapport HTML Folio Rose : charte des Rapport_Verification_*.html (bandeau, tuiles, synthèses, détail).
Module pur : met en page des DataFrames déjà calculés par folio_rose."""
from __future__ import annotations
import html
from datetime import datetime
from pathlib import Path

import pandas as pd

from folio_rose import TOL, Export, couleur_ligne
from rapport_matin import STYLE as _STYLE_BASE, DOSSIER_RAPPORTS

STYLE = _STYLE_BASE + """
  td.ko { background: #fbdcdc !important; } td.ok { background: #d7f2e3 !important; }
  span.ko { background: #fbdcdc; color: #9b1c1c; padding: 1px 7px; border-radius: 9px; font-weight: 600; }
  span.ok { background: #d7f2e3; color: #0b6b3a; padding: 1px 7px; border-radius: 9px; font-weight: 600; }
  tr.rapproche td { color: #8b949e; } .num { text-align: right; font-variant-numeric: tabular-nums; }
  tr.bleu td { background: #DCEBFF !important; } tr.vert td { background: #E3F5E8 !important; } tr.rose td { background: #FBE3EC !important; } tr.jaune td { background: #FFF6D6 !important; }
  .legende span { display: inline-block; padding: 2px 10px; margin-right: 8px; border-radius: 4px; font-size: .82em; }
"""
JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]


def _t(v) -> str:
    if v is None:
        return ""
    try:
        if pd.isna(v):
            return ""
    except (TypeError, ValueError):
        pass
    return html.escape(str(v))


def _mt(v) -> str:
    try:
        if v is None or pd.isna(v):
            return ""
        return f"{float(v):,.2f}".replace(",", " ").replace(".", ",")
    except (TypeError, ValueError):
        return _t(v)


def _nb(v) -> str:
    try:
        return "" if v is None or pd.isna(v) else f"{int(round(float(v))):,}".replace(",", " ")
    except (TypeError, ValueError):
        return _t(v)


def _synthese(lignes: pd.DataFrame, champ: str, titre: str) -> str:
    if lignes.empty:
        return f"<h2>{titre}</h2><div class='vide'>Aucune ligne.</div>"
    g = lignes.groupby(champ).agg(lignes=("empreinte", "size"),
                                  en_ecart=("ecart_debit", lambda s: int((s.abs() >= TOL).sum())),
                                  montant=("ecart_debit", "sum"),
                                  ko=("statut", lambda s: int((s == "KO").sum())),
                                  rapprochees=("rapproche", "sum")).reset_index()
    rows = "".join(f"<tr><td>{_t(r[champ])}</td><td class='num'>{_nb(r['lignes'])}</td><td class='num'>{_nb(r['en_ecart'])}</td>"
                   f"<td class='num'>{_mt(r['montant'])}</td><td class='num'>{_nb(r['ko'])}</td><td class='num'>{_nb(r['rapprochees'])}</td></tr>"
                   for _, r in g.iterrows())
    return (f"<h2>{titre}</h2><div class='tablewrap'><table><thead><tr><th>{_t(champ.capitalize())}</th><th>Lignes</th>"
            f"<th>En écart</th><th>Montant en écart</th><th>KO Oracle</th><th>Rapprochées</th></tr></thead><tbody>{rows}</tbody></table></div>")


COLONNES_DETAIL = (
    "Folio", "Type", "Date", "Âge", "Nom fichier transmis", "App Amont Nb pièce", "App Amont Débit", "App Amont Crédit",
    "SI Finance Nb pièce", "SI Finance Débit", "SI Finance Crédit", "Écarts Nb pièce", "Écarts Débit", "Écarts Crédit",
    "Commentaire", "Somme Amont Fichier", "Somme Écart Fichier", "Montant Interface OA", "Nb Pièces OA", "Montant OA",
    "Écart Nb Pièce Calculé", "Écart Mt Calculé", "Statut Vérification", "Rapproché")
_NUMERIQUES = {3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21}


def _detail(lignes: pd.DataFrame) -> str:
    """Détail des lignes, colonnes et ordre du Rapport_Verification_*.csv du .ps1."""
    if lignes.empty:
        return "<div class='vide'>Aucune ligne.</div>"
    rows = []
    for _, r in lignes.iterrows():
        cls = {"OK": "ok", "KO": "ko"}.get(r["statut"], "")
        statut = f"<span class='{cls}'>{_t(r['statut'])}</span>" if cls else _t(r["statut"])
        cells = [_t(r["folio"]), _t(r["type"]), _t(r["date"]), _nb(r["age_j"]), _t(r["fichier"]),
                 _nb(r["amont_nb"]), _mt(r["amont_debit"]), _mt(r["amont_credit"]),
                 _nb(r["si_nb"]), _mt(r["si_debit"]), _mt(r["si_credit"]),
                 _nb(r["ecart_nb"]), _mt(r["ecart_debit"]), _mt(r["ecart_credit"]), _t(r["commentaire"]),
                 _mt(r.get("somme_amont_fichier")), _mt(r.get("somme_ecart_fichier")),
                 _mt(r["montant_interface"]), _nb(r["nb_oracle"]), _mt(r["montant_oracle"]),
                 _nb(r["ecart_nb_calcule"]), _mt(r["ecart_mt_calcule"]), statut, "✔" if r["rapproche"] else ""]
        tr = ("<tr class='rapproche'>" if r["rapproche"]
              else f"<tr class='{couleur_ligne(r['ecart_debit'], r['ecart_credit'], r['ecart_nb'], r['statut'], r['commentaire']) or ''}'>")
        rows.append(tr + "".join(f"<td class='num'>{c}</td>" if i in _NUMERIQUES else f"<td>{c}</td>"
                                 for i, c in enumerate(cells)) + "</tr>")
    head = "".join(f"<th>{h}</th>" for h in COLONNES_DETAIL)
    return f"<div class='tablewrap'><table><thead><tr>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>"


def _rapprochements(r: pd.DataFrame) -> str:
    if r is None or r.empty:
        return "<div class='vide'>Aucun rapprochement enregistré.</div>"
    rows = "".join(f"<tr><td>{_t(x['cree_le'])}</td><td>{_t(x['folios'])}</td><td class='num'>{_nb(x['nb_lignes'])}</td>"
                   f"<td class='num'>{_mt(x['somme_ecart'])}</td><td>{_t(x['commentaire'])}</td>"
                   f"<td>{'annulé le ' + _t(x['annule_le']) if x['annule_le'] else ''}</td></tr>" for _, x in r.iterrows())
    return (f"<div class='tablewrap'><table><thead><tr><th>Date</th><th>Folios</th><th>Lignes</th><th>Somme</th>"
            f"<th>Commentaire</th><th></th></tr></thead><tbody>{rows}</tbody></table></div>")


def construire(export: Export, lignes: pd.DataFrame, groupes: pd.DataFrame, rapprochements: pd.DataFrame) -> str:
    d = export.date_export
    nb_ko = int((lignes["statut"] == "KO").sum()) if not lignes.empty else 0
    nb_ok = int((lignes["statut"] == "OK").sum()) if not lignes.empty else 0
    nb_ind = int((lignes["statut"] == "INDETERMINE").sum()) if not lignes.empty else 0
    nb_rap = int(lignes["rapproche"].sum()) if not lignes.empty else 0
    nb_grp = 0 if groupes is None else len(groupes)
    total = float(lignes["ecart_debit"].sum()) if not lignes.empty else 0.0
    if nb_ko:
        cls, msg = "ko", f"{nb_ko} ligne(s) KO : le montant Oracle ne correspond pas au montant amont."
    elif nb_ind or nb_grp:
        cls, msg = "warn", f"{nb_ind} ligne(s) indéterminée(s), {nb_grp} groupe(s) compensé(s) en attente de rapprochement."
    else:
        cls, msg = "ok", "Aucun écart Oracle ; aucun groupe compensé en attente."
    tuiles = "".join([
        f'<div class="tile"><div class="tv">{len(lignes)}</div><div class="tn">Lignes</div></div>',
        f'<div class="tile"><div class="tv">{lignes["folio"].nunique() if not lignes.empty else 0}</div><div class="tn">Folios</div></div>',
        f'<div class="tile"><div class="tv">{_mt(total)}</div><div class="tn">Écart débit total</div></div>',
        f'<div class="tile"><div class="tv">{nb_ok}</div><div class="tn">OK Oracle</div></div>',
        f'<div class="tile"><div class="tv">{nb_ko}</div><div class="tn">KO Oracle</div></div>',
        f'<div class="tile"><div class="tv">{nb_rap}</div><div class="tn">Rapprochées</div></div>',
        f'<div class="tile"><div class="tv">{nb_grp}</div><div class="tn">Groupes compensés en attente</div></div>',
    ])
    meta = (f"<span>📅 Export du {d:%d/%m/%Y} ({_t(export.nom)})</span>"
            f"<span>Période : {_t(export.periode_debut)} → {_t(export.periode_fin)}</span>"
            f"<span>Rapport généré le {datetime.now():%d/%m/%Y %H:%M}</span>")
    return f"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"><title>Folio Rose — export du {d:%d/%m/%Y}</title><style>{STYLE}</style></head>
<body><div class="wrap">
<h1>Folio Rose — export du {d:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
<div class="bandeau {cls}"><strong>{_t(msg)}</strong></div>
<div class="tiles">{tuiles}</div>
{_synthese(lignes, "type", "Synthèse par type")}
{_synthese(lignes, "folio", "Synthèse par folio")}
<h2>Détail des lignes</h2>
<div class="legende"><span style="background:#DCEBFF">vérification Oracle OK</span><span style="background:#FFF6D6">commentaire renseigné</span><span style="background:#E3F5E8">écart de montant nul</span><span style="background:#FBE3EC">nombre de pièces égal, montant différent</span></div>
{_detail(lignes)}
<h2>Rapprochements</h2>{_rapprochements(rapprochements)}
<div class="footer">ODAT Watch · Folio Rose · portage de Verifier_Factures.ps1</div>
</div></body></html>
"""


def ecrire(export: Export, lignes, groupes, rapprochements, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Folio_Rose_{export.date_export:%Y%m%d}_{datetime.now():%H%M}.html"
    chemin.write_text(construire(export, lignes, groupes, rapprochements), encoding="utf-8")
    return chemin
