"""Onglet Prélèvements : pont vers l'outil CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement par clé métier).

Le code du contrôle vit dans ../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement_cle_metier.executer,
config [prelevements] outil) ; les données (ORACLE/<AAAAMMJJ>, EDF, EDF/REJETS) et les rapports
(rapport/Rapprochement_Cle_Metier_<AAAAMMJJ>_<HHMMSS>.*) dans ../ODAT/prelevements (config [prelevements] racine).
Ici on choisit la date de référence, on lance le rapprochement et on relit le dernier rapport de cette date.
"""
from __future__ import annotations
import configparser
import contextlib
import io
import json
import re
import sys
from datetime import date, datetime
from pathlib import Path

import pandas as pd

from oracle_refresh import BASE_DIR, CONFIG

DEFAUTS = {"outil": r"..\CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS", "racine": r"..\ODAT\prelevements",
           "jours": "10", "nom_si": "ORACLE"}
DOSSIER_RAPPORT = "rapport"
PREFIXE = "Rapprochement_Cle_Metier_"
RE_BASE = re.compile(rf"{PREFIXE}(\d{{8}})_(\d{{6}})")

# Statuts de l'outil, dans son ordre d'affichage (ORDRE_STATUTS de rapprochement_cle_metier.py)
ORDRE_STATUTS = ["RAPPROCHE", "RAPPROCHE_AVEC_REJET_POSTERIEUR", "EXPLIQUE_PAR_REJET", "REJETE_INTEGRALEMENT",
                 "REJET_PARTIEL_NON_CONFIRME", "EN_ATTENTE", "NON_RECU", "ECART_PARTIEL", "EDF_SANS_ORACLE",
                 "HORS_PERIMETRE_HISTORIQUE"]
STATUTS_ANOMALIE = {"NON_RECU", "ECART_PARTIEL", "EDF_SANS_ORACLE"}
STATUTS_SIGNALES = {"RAPPROCHE_AVEC_REJET_POSTERIEUR", "REJET_PARTIEL_NON_CONFIRME"}
CAUSES_A_INVESTIGUER = {"INEXPLIQUE", "SANS_ORACLE"}
LIBELLES_STATUT = {
    "RAPPROCHE": "Rapproché", "RAPPROCHE_AVEC_REJET_POSTERIEUR": "Rapproché, rejet postérieur",
    "EXPLIQUE_PAR_REJET": "Écart expliqué par rejet", "REJETE_INTEGRALEMENT": "Rejeté intégralement",
    "REJET_PARTIEL_NON_CONFIRME": "Rejet partiel non confirmé", "EN_ATTENTE": "En attente EDF",
    "NON_RECU": "Non reçu par EDF", "ECART_PARTIEL": "Écart partiel", "EDF_SANS_ORACLE": "EDF sans Oracle",
    "HORS_PERIMETRE_HISTORIQUE": "Hors historique Oracle",
}
EXPLICATIONS = {
    "RAPPROCHE": "Nombre et montant identiques de part et d'autre.",
    "RAPPROCHE_AVEC_REJET_POSTERIEUR": "Totaux conformes, mais un rejet est arrivé après la remontée EDF : le prélèvement échouera.",
    "EXPLIQUE_PAR_REJET": "L'écart correspond exactement aux rejets internes.",
    "REJETE_INTEGRALEMENT": "Tous les prélèvements ont été rejetés : EDF ne remonte donc aucune ligne.",
    "REJET_PARTIEL_NON_CONFIRME": "Des rejets existent mais EDF n'a encore rien remonté pour cette clé.",
    "EN_ATTENTE": "Émis, pas encore confirmé par EDF, dans le délai normal.",
    "NON_RECU": "Émis, non confirmé par EDF au-delà du délai normal.",
    "ECART_PARTIEL": "Écart non expliqué par les rejets.",
    "EDF_SANS_ORACLE": "EDF a remonté des prélèvements sans contrepartie Oracle.",
    "HORS_PERIMETRE_HISTORIQUE": "Échéance antérieure à l'historique Oracle disponible : non concluant.",
}
LIBELLES_GLOBAL = {"OK": "✅ OK", "ANOMALIES": "❌ Anomalies", "DEGRADE": "⚠ Dégradé", "ERREUR": "❌ Erreur",
                   "INCONNU": "❔ Inconnu"}
TON_GLOBAL = {"OK": "ok", "ANOMALIES": "err", "DEGRADE": "warn", "ERREUR": "err", "INCONNU": "neutral"}


def _chemin(v: str) -> Path:
    p = Path(v.strip())
    return p if p.is_absolute() else (BASE_DIR / p).resolve()


def config_prelevements() -> dict:
    """Section [prelevements] de config.ini, complétée par les valeurs par défaut."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    val = {k: cfg.get("prelevements", k, fallback=v) for k, v in DEFAUTS.items()}
    return {"outil": _chemin(val["outil"]), "racine": _chemin(val["racine"]), "jours": int(val["jours"] or 10),
            "nom_si": val["nom_si"].strip() or "ORACLE"}


def _bases(racine: Path) -> list[tuple[date, str, str]]:
    """(date de référence, horodatage, base) de chaque rapport présent, du plus récent au plus ancien."""
    out = []
    for f in (Path(racine) / DOSSIER_RAPPORT).glob(f"{PREFIXE}*.csv"):
        m = RE_BASE.fullmatch(f.stem)
        if m:
            out.append((datetime.strptime(m.group(1), "%Y%m%d").date(), m.group(2), f.stem))
    return sorted(out, reverse=True)


def dates_disponibles(racine: Path) -> list[date]:
    """Dates de référence déjà contrôlées, la plus récente en premier."""
    return sorted({d for d, _, _ in _bases(racine)}, reverse=True)


def _outil(outil: Path) -> None:
    """Rend importable rapprochement_cle_metier depuis le dossier de l'outil, et recharge les modules déjà
    importés (Streamlit ne surveille pas les fichiers hors de l'application)."""
    import importlib
    r = str(Path(outil))
    if r not in sys.path:
        sys.path.insert(0, r)
    for nom in ("prelevements_rapprochement", "rapprochement_cle_metier"):
        module = sys.modules.get(nom)
        if module is not None:
            importlib.reload(module)


def lancer(reference: date, cfg: dict) -> dict:
    """Exécute le rapprochement et écrit rapport/<base>.*. Renvoie le dict de rapprochement_cle_metier.executer,
    complété de « journal » : ce que l'outil a écrit sur la console (fichiers lus, avertissements)."""
    _outil(cfg["outil"])
    import rapprochement_cle_metier
    journal = io.StringIO()
    with contextlib.redirect_stdout(journal), contextlib.redirect_stderr(journal):
        res = rapprochement_cle_metier.executer(reference=reference.isoformat(), racine=cfg["racine"],
                                                jours=cfg["jours"], nom_si=cfg["nom_si"])
    res["journal"] = journal.getvalue().strip()
    return res


def _csv(f: Path) -> pd.DataFrame:
    if not f.is_file() or not f.stat().st_size:
        return pd.DataFrame()
    return pd.read_csv(f, sep=";", dtype=str, keep_default_na=False, encoding="utf-8-sig")


def lire_rapport(racine: Path, reference: date) -> dict | None:
    """Relit le rapport le plus récent de la date de référence : rapprochement, justifications, résumé, classeur."""
    candidats = [b for d, _, b in _bases(racine) if d == reference]
    if not candidats:
        return None
    base = candidats[0]
    dossier = Path(racine) / DOSSIER_RAPPORT
    resume_f = dossier / f"{base}_resume.json"
    if resume_f.is_file():
        resume = json.loads(resume_f.read_text(encoding="utf-8"))
    else:   # rapport produit avant executer() : pas de résumé structuré
        resume = {"statut_global": "INCONNU", "par_statut": {}, "avertissements": [], "contexte": {},
                  "nb_lignes_ko": 0}
    rapprochement = _csv(dossier / f"{base}.csv")
    for c in ("nb_oracle", "nb_edf", "ecart_nb", "nb_rejets"):
        if c in rapprochement.columns:
            rapprochement[c] = pd.to_numeric(rapprochement[c], errors="coerce").fillna(0).astype(int)
    for c in ("montant_oracle", "montant_edf", "ecart_montant", "montant_rejets"):
        if c in rapprochement.columns:
            rapprochement[c] = pd.to_numeric(rapprochement[c], errors="coerce").fillna(0.0)
    xlsx = dossier / f"{base}.xlsx"
    return {"base": base, "dossier": dossier, "resume": resume, "rapprochement": rapprochement,
            "justifications": _csv(dossier / f"{base}_justifications.csv"),
            "doublons": _csv(dossier / f"{base}_doublons.csv"),
            "xlsx": xlsx if xlsx.is_file() else None,
            "genere_le": datetime.fromtimestamp((dossier / f"{base}.csv").stat().st_mtime)}


def resume(rapport: dict) -> dict:
    """Chiffres clés pour les tuiles, calculés depuis les tables (le JSON ne sert qu'au statut global,
    aux avertissements et aux lignes non conformes)."""
    df = rapport["rapprochement"]
    r = rapport["resume"]
    statut = df["statut"] if not df.empty else pd.Series(dtype=str)
    just = rapport["justifications"]
    a_investiguer = int(just["cause"].isin(CAUSES_A_INVESTIGUER).sum()) if not just.empty else 0
    dbl = rapport.get("doublons", pd.DataFrame())
    types = dbl["type"] if not dbl.empty else pd.Series(dtype=str)
    return {"doublons": int((types == "DOUBLON").sum()), "similitudes": int((types == "SIMILITUDE").sum()),"statut_global": r.get("statut_global", "INCONNU"), "nb_cles": int(len(df)),
            "nb_emis": int(df["nb_oracle"].sum()) if not df.empty else 0,
            "montant_emis": float(df["montant_oracle"].sum()) if not df.empty else 0.0,
            "en_attente": int((statut == "EN_ATTENTE").sum()),
            "anomalies": int(statut.isin(STATUTS_ANOMALIE).sum()),
            "signales": int(statut.isin(STATUTS_SIGNALES).sum()),
            "a_investiguer": a_investiguer,
            "avertissements": len(r.get("avertissements", [])),
            "lignes_ko": int(r.get("nb_lignes_ko") or 0)}


def par_statut(df: pd.DataFrame) -> list[tuple[str, pd.DataFrame]]:
    """Groupes non vides du rapprochement, dans l'ordre métier."""
    if df.empty:
        return []
    return [(s, df[df["statut"] == s]) for s in ORDRE_STATUTS if (df["statut"] == s).any()]
