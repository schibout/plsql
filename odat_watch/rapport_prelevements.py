"""Rapport HTML du rapprochement des prélèvements (Oracle ↔ EDF), dans la charte des Rapport_Verification_*.html
(cf. rapport_matin.py) : synthèse en haut (bandeau, tuiles, statuts, à faire), tableaux de détail en bas.

Module pur : il met en page un rapport relu par prelevements.lire_rapport, ne lance rien.
"""
from __future__ import annotations
import html
from datetime import datetime
from pathlib import Path

import pandas as pd

import prelevements as pv
from rapport_matin import JOURS, STYLE, _t, _table

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"

CLASSE_STATUT = {"OK": "ok", "DEGRADE": "warn", "ANOMALIES": "ko", "ERREUR": "ko", "INCONNU": "warn"}
MESSAGE_STATUT = {
    "OK": "Tout ce qu'Oracle a émis est confirmé par EDF ou expliqué par un rejet interne.",
    "DEGRADE": "Le rapprochement a tourné sur des données incomplètes : les statuts sont à lire avec les avertissements ci-dessous.",
    "ANOMALIES": "Des prélèvements émis ne sont pas confirmés par EDF hors délai, présentent un écart inexpliqué, ou ont été émis en double : action requise.",
    "ERREUR": "Des lignes Oracle n'ont pas pu être lues : le résultat n'est pas fiable.",
    "INCONNU": "Rapport ancien, sans résumé structuré : statut global non disponible.",
}
LIBELLES_CAUSE = {"INEXPLIQUE": "inexpliqué", "SANS_ORACLE": "EDF sans Oracle", "REJET": "expliqué par rejet",
                  "NON_CONFIRME": "non confirmé"}
COLONNES_RAPPRO = ["iban_creancier", "echeance", "nb_oracle", "montant_oracle", "nb_edf", "montant_edf",
                   "ecart_nb", "ecart_montant", "nb_rejets", "montant_rejets", "codes_rejets", "emissions", "tranches_edf"]
LIBELLES_COL = {"iban_creancier": "IBAN créancier", "echeance": "Échéance", "nb_oracle": "Nb Oracle",
                "montant_oracle": "Montant Oracle", "nb_edf": "Nb EDF", "montant_edf": "Montant EDF",
                "ecart_nb": "Écart nb", "ecart_montant": "Écart montant", "nb_rejets": "Nb rejets",
                "montant_rejets": "Montant rejets", "codes_rejets": "Codes rejets", "emissions": "Émission(s)",
                "tranches_edf": "Tranches EDF", "cause": "Cause", "nb": "Nb", "montant": "Montant",
                "beneficiaire": "Bénéficiaire", "rum": "RUM", "iban_debiteur": "IBAN débiteur", "code": "Code",
                "motif": "Motif", "emission": "Émission", "fichier_oracle": "Fichier Oracle",
                "fichier_rejet": "Fichier rejet", "fichier_edf": "Fichier EDF", "statut_cle": "Statut clé",
                "ecart_nb_cle": "Écart nb clé", "ecart_montant_cle": "Écart montant clé", "type": "Type",
                "reference": "Référence(s)", "fichiers": "Fichier(s)", "statut": "Statut"}


def _nb(v) -> str:
    return f"{int(v):,}".replace(",", " ")


def _eur(v) -> str:
    return f"{float(v):,.2f} €".replace(",", " ").replace(".", ",")


def _tuile(valeur, libelle, cls: str = "") -> str:
    pill = f'<span class="pill {cls}">{ {"ok": "OK", "warn": "À SUIVRE", "ko": "ACTION"}[cls] }</span>' if cls else ""
    return f'<div class="tile"><div class="tv">{_t(valeur)}</div><div class="tn">{_t(libelle)}</div>{pill}</div>'


def _tuiles(r: dict) -> str:
    return "".join([
        _tuile(_nb(r["nb_emis"]), "prélèvements émis"),
        _tuile(_eur(r["montant_emis"]), "montant émis"),
        _tuile(_nb(r["nb_cles"]), "clés IBAN × échéance"),
        _tuile(_nb(r["en_attente"]), "en attente EDF", "warn" if r["en_attente"] else "ok"),
        _tuile(_nb(r["anomalies"]), "anomalies", "ko" if r["anomalies"] else "ok"),
        _tuile(_nb(r["a_investiguer"]), "écarts à investiguer", "ko" if r["a_investiguer"] else "ok"),
        _tuile(_nb(r["doublons"]), "émis en double", "ko" if r["doublons"] else "ok"),
        _tuile(_nb(r["similitudes"]), "similitudes à vérifier", "warn" if r["similitudes"] else "ok"),
    ])


def _bandeau(rapport: dict, r: dict) -> str:
    g = r["statut_global"]
    cls = CLASSE_STATUT.get(g, "ko")
    extra = ""
    if r["lignes_ko"]:
        extra += f"<br><b>{r['lignes_ko']} ligne(s) Oracle non conforme(s)</b> : voir l'onglet « Lignes rejetées » du classeur."
    for a in rapport["resume"].get("avertissements", []):
        extra += f"<br>⚠ {_t(a)}"
    return (f'<div class="bandeau {cls}"><strong>Statut global : {_t(g)}</strong>'
            f'{_t(MESSAGE_STATUT.get(g, ""))}{extra}</div>')


def _synthese_statuts(df: pd.DataFrame) -> str:
    lignes = []
    for statut, g in pv.par_statut(df):
        nb = int(g["nb_oracle"].sum() or g["nb_edf"].sum())
        montant = float(g["montant_oracle"].sum() or g["montant_edf"].sum())
        cls = "ko" if statut in pv.STATUTS_ANOMALIE else "warn" if statut in pv.STATUTS_SIGNALES or statut == "EN_ATTENTE" else "ok"
        lignes.append(f'<tr><td><span class="pill {cls}">{_t(pv.LIBELLES_STATUT[statut])}</span></td>'
                      f'<td class="num">{len(g)}</td><td class="num">{_nb(nb)}</td><td class="num">{_eur(montant)}</td>'
                      f'<td>{_t(pv.EXPLICATIONS[statut])}</td></tr>')
    if not lignes:
        return '<div class="vide">Aucune clé dans le périmètre.</div>'
    return ('<div class="tablewrap"><table><thead><tr><th>Statut</th><th>Clés</th><th>Prélèvements</th>'
            '<th>Montant</th><th>Signification</th></tr></thead><tbody>' + "".join(lignes) + "</tbody></table></div>")


def actions(rapport: dict) -> list[tuple[str, str]]:
    """Liste « À faire aujourd'hui » : (gravité ko/warn/ok, phrase). Vide si rien à faire."""
    df, just, dbl = rapport["rapprochement"], rapport["justifications"], rapport["doublons"]
    out: list[tuple[str, str]] = []
    if not dbl.empty:
        for _, d in dbl[dbl["type"] == "DOUBLON"].iterrows():
            out.append(("ko", f"Doublon d'émission : {d['beneficiaire']} ({d['rum']}), {_eur(d['montant'])} à l'échéance "
                              f"du {d['echeance']}, référence {d['reference']} émise {d['nb']} fois "
                              f"({d['fichiers']}). Bloquer le second prélèvement avant l'échéance."))
    if not df.empty:
        for _, k in df[df["statut"] == "NON_RECU"].iterrows():
            out.append(("ko", f"Non reçu par EDF : {_nb(k['nb_oracle'])} prélèvement(s) pour {_eur(k['montant_oracle'])}, "
                              f"IBAN {k['iban_creancier']}, échéance {k['echeance']}, émis le {k['emissions']}. "
                              f"Vérifier la transmission des fichiers Oracle de ce jour à EDF."))
        for _, k in df[df["statut"] == "EDF_SANS_ORACLE"].iterrows():
            out.append(("ko", f"EDF a reçu {_nb(k['nb_edf'])} prélèvement(s) pour {_eur(k['montant_edf'])} "
                              f"(IBAN {k['iban_creancier']}, échéance {k['echeance']}) sans émission Oracle connue : "
                              f"identifier la source (autre SI, historique manquant ou envoi manuel)."))
        for _, k in df[df["statut"] == "ECART_PARTIEL"].iterrows():
            out.append(("ko", f"Écart partiel inexpliqué : Oracle {_nb(k['nb_oracle'])} / EDF {_nb(k['nb_edf'])} "
                              f"pour l'IBAN {k['iban_creancier']}, échéance {k['echeance']} "
                              f"(écart {_eur(k['ecart_montant'])}). Détail dans la justification des écarts."))
    if not just.empty:
        for _, j in just[just["cause"].isin(pv.CAUSES_A_INVESTIGUER)].iterrows():
            out.append(("ko", f"Écart {LIBELLES_CAUSE.get(j['cause'], j['cause'])} : {_nb(j['nb'])} prélèvement(s), {_eur(j['montant'])}, "
                              f"{j['beneficiaire'] or 'bénéficiaire inconnu'}, échéance {j['echeance']}, "
                              f"fichier {j['fichier_oracle'] or j['fichier_edf'] or '?'} : à investiguer."))
    if not df.empty:
        for _, k in df[df["statut"].isin(pv.STATUTS_SIGNALES)].iterrows():
            out.append(("warn", f"{pv.LIBELLES_STATUT[k['statut']]} : IBAN {k['iban_creancier']}, échéance {k['echeance']}, "
                                f"{_nb(k['nb_rejets'])} rejet(s) ({k['codes_rejets']}). À signaler au métier : "
                                f"{pv.EXPLICATIONS[k['statut']].lower()}"))
    if not dbl.empty:
        n_sim = int((dbl["type"] == "SIMILITUDE").sum())
        if n_sim:
            out.append(("warn", f"{n_sim} similitude(s) : même mandat, débiteur, échéance et montant avec des références "
                                f"différentes. Confirmer qu'il s'agit bien de factures distinctes (tableau Doublons)."))
    if not df.empty:
        att = df[df["statut"] == "EN_ATTENTE"]
        if not att.empty:
            out.append(("ok", f"{len(att)} clé(s) en attente EDF ({_nb(att['nb_oracle'].sum())} prélèvements, "
                              f"{_eur(att['montant_oracle'].sum())}) émise(s) le {', '.join(sorted(set(att['emissions'])))} : "
                              f"rien à faire, relancer le contrôle après le prochain état EDF."))
    return out


def _a_faire(rapport: dict) -> str:
    items = actions(rapport)
    if not items:
        return '<div class="vide">Rien à faire : toutes les clés sont rapprochées.</div>'
    icone = {"ko": "🔴", "warn": "🟠", "ok": "🟢"}
    return "<ul class=\"afaire\">" + "".join(f'<li class="{cls}">{icone[cls]} {_t(txt)}</li>' for cls, txt in items) + "</ul>"


def _renommer(df: pd.DataFrame, colonnes: list[str] | None = None) -> pd.DataFrame:
    if df.empty:
        return df
    d = df[[c for c in (colonnes or df.columns) if c in df.columns]].copy()
    for c in d.columns:
        if c.startswith("montant") or c.startswith("ecart_montant"):
            d[c] = pd.to_numeric(d[c], errors="coerce").map(lambda v: _eur(v) if pd.notna(v) else "")
    return d.rename(columns=LIBELLES_COL)


def construire(rapport: dict) -> str:
    r = pv.resume(rapport)
    res = rapport["resume"]
    ref = datetime.strptime(rapport["base"][len(pv.PREFIXE):len(pv.PREFIXE) + 8], "%Y%m%d").date()
    d = rapport["genere_le"]
    ctx = res.get("contexte", {})
    meta = (f'<span>📅 Rapprochement au {ref:%d/%m/%Y}</span>'
            f'<span>Généré le {JOURS[d.weekday()]} {d:%d/%m/%Y} à {d:%H:%M}</span>')
    for k in ("Profondeur (jours)", "Échéances retenues", "Lignes Oracle", "Lignes EDF", "Rejets retenus"):
        if k in ctx:
            meta += f"<span>{_t(k)} : {_t(ctx[k])}</span>"

    corps = ["<h2>Synthèse par statut</h2>", _synthese_statuts(rapport["rapprochement"]),
             "<h2>À faire aujourd'hui</h2>", _a_faire(rapport)]

    corps.append("<h2>Détail — Justification des écarts"
                 + (f' <span class="pill ko">{r["a_investiguer"]} à investiguer</span>' if r["a_investiguer"] else "") + "</h2>")
    corps.append(_table(_renommer(rapport["justifications"])))
    corps.append("<h2>Détail — Doublons et similitudes"
                 + (f' <span class="pill ko">{r["doublons"]}</span>' if r["doublons"] else "") + "</h2>")
    corps.append(_table(_renommer(rapport["doublons"])))
    for statut, g in pv.par_statut(rapport["rapprochement"]):
        cls = "ko" if statut in pv.STATUTS_ANOMALIE else "warn" if statut in pv.STATUTS_SIGNALES or statut == "EN_ATTENTE" else "ok"
        corps.append(f'<h2>Détail — {_t(pv.LIBELLES_STATUT[statut])} <span class="pill {cls}">{len(g)} clé(s)</span></h2>')
        corps.append(f'<p class="expl">{_t(pv.EXPLICATIONS[statut])}</p>')
        corps.append(_table(_renommer(g, COLONNES_RAPPRO)))

    style = STYLE + """
  ul.afaire { list-style: none; padding: 0; margin: 0; }
  ul.afaire li { background: #fff; border-left: 5px solid #dde3ea; border-radius: 4px; padding: 8px 12px;
                 margin-bottom: 6px; font-size: .88em; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  ul.afaire li.ko { border-left-color: #c62828; } ul.afaire li.warn { border-left-color: #e8a317; }
  ul.afaire li.ok { border-left-color: #2e8b57; }
  p.expl { color: #57606a; font-size: .85em; margin: 4px 0 8px; }
"""
    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Prélèvements Oracle ↔ EDF — {ref:%d/%m/%Y}</title>
<style>{style}</style>
</head>
<body><div class="wrap">
<h1>Prélèvements Oracle ↔ EDF — rapprochement au {ref:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
{_bandeau(rapport, r)}
<div class="tiles">{_tuiles(r)}</div>
{"".join(corps)}
<div class="footer">ODAT Watch · rapprochement par clé métier (IBAN créancier × échéance) · {_t(rapport["base"])}</div>
</div></body>
</html>
"""


def texte_court(rapport: dict) -> str:
    """Résumé en quelques lignes, à coller dans un mail ou Teams."""
    r = pv.resume(rapport)
    ref = datetime.strptime(rapport["base"][len(pv.PREFIXE):len(pv.PREFIXE) + 8], "%Y%m%d").date()
    lignes = [f"Prélèvements Oracle ↔ EDF au {ref:%d/%m/%Y} : {r['statut_global']}",
              f"- {_nb(r['nb_emis'])} prélèvements émis pour {_eur(r['montant_emis'])} ({_nb(r['nb_cles'])} clés)",
              f"- {_nb(r['en_attente'])} clé(s) en attente EDF, {_nb(r['anomalies'])} anomalie(s), "
              f"{_nb(r['a_investiguer'])} écart(s) à investiguer, {_nb(r['doublons'])} doublon(s) d'émission"]
    for a in rapport["resume"].get("avertissements", []):
        lignes.append(f"- Avertissement : {a}")
    todo = [t for cls, t in actions(rapport) if cls != "ok"]
    if todo:
        lignes.append("À faire :")
        lignes += [f"  • {t}" for t in todo]
    return "\n".join(lignes)


def ecrire(rapport: dict, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    ref = rapport["base"][len(pv.PREFIXE):len(pv.PREFIXE) + 8]
    chemin = dossier / f"Prelevements_{ref}_{datetime.now():%H%M%S}.html"
    chemin.write_text(construire(rapport), encoding="utf-8")
    return chemin
