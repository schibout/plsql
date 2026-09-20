"""Onglet Virements : pont vers l'outil controleVirement (dossiers *_cible chargés à la main).

Le contrôle lui-même vit dans ../controleVirement (controle_virements.executer) ; ici on choisit la journée,
on le lance en local et on relit le dossier rapport_<date> pour l'affichage.
"""
from __future__ import annotations
import configparser
import re
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd

from oracle_refresh import BASE_DIR, CONFIG

DEFAUTS = {"racine": r"..\controleVirement", "historique_jours": "7"}

# Fichiers du rapport : (clé, nom du CSV, libellé, gravité portée par la colonne « gravite » ou fixe)
CSV_RAPPORT = [
    ("fichiers", "controle_fichiers.csv", "Présence des fichiers"),
    ("totaux_source", "controle_totaux_source.csv", "Totaux par fichier d'origine"),
    ("totaux_edf", "controle_totaux_edf.csv", "Totaux par envoi vers la banque"),
    ("lignes", "controle_lignes_ecarts.csv", "Écarts virement par virement"),
    ("quartz", "controle_quartz_ecarts.csv", "Écarts avec le retour trésorerie (Quartz)"),
    ("doublons_ack", "controle_doublons_ack.csv", "Envois transmis en double (D1)"),
    ("doublons_virements", "controle_doublons_virements.csv", "Virements des envois en double (liste banque)"),
    ("croises", "controle_doublons_croises.csv", "Envois se recouvrant partiellement (D2)"),
    ("virements_jour", "controle_doublons_virements_jour.csv", "Virement présent dans plusieurs envois (D3)"),
    ("intra", "controle_doublons_intra_envoi.csv", "Virement répété dans un même envoi (D4)"),
    ("historique", "controle_doublons_historique.csv", "Déjà transmis un jour précédent (D5)"),
    ("sources", "controle_doublons_sources.csv", "Fichiers d'origine rejoués (D6)"),
    ("sanite", "controle_sanite.csv", "Contrôles de forme"),
]
CLES_DOUBLONS = ("doublons_ack", "croises", "virements_jour", "intra", "historique", "sources")


def _chemin(v: str) -> Path:
    p = Path(v.strip())
    return p if p.is_absolute() else (BASE_DIR / p).resolve()


def config_virements() -> dict:
    """Section [virements] de config.ini, complétée par les valeurs par défaut."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    val = {k: cfg.get("virements", k, fallback=v) for k, v in DEFAUTS.items()}
    return {"racine": _chemin(val["racine"]), "historique_jours": int(val["historique_jours"] or 0)}


def dates_disponibles(racine: Path) -> list[str]:
    """Dates JJMMAAAA ayant un dossier *_cible sous la racine, la plus récente en premier."""
    dates = set()
    for d in Path(racine).glob("*_cible"):
        m = re.fullmatch(r"(\d{8})_cible", d.name)
        if m and d.is_dir():
            dates.add(m.group(1))
    return sorted(dates, key=lambda d: datetime.strptime(d, "%d%m%Y"), reverse=True)


def date_lisible(d: str) -> str:
    return f"{d[0:2]}/{d[2:4]}/{d[4:8]}"


def source_presente(racine: Path, date: str) -> bool:
    return (Path(racine) / f"{date}_source").is_dir()


def fichier_quartz(racine: Path, date: str) -> Path | None:
    _outil(racine)
    import controle_virements
    return controle_virements.trouver_fichier_quartz(Path(racine), date)


def _outil(racine: Path) -> None:
    """Rend importable controle_virements / cv depuis la racine de l'outil."""
    r = str(Path(racine))
    if r not in sys.path:
        sys.path.insert(0, r)


def lancer(date: str, cfg: dict) -> dict:
    """Exécute le contrôle et écrit rapport_<date>. Renvoie le dict de controle_virements.executer."""
    _outil(cfg["racine"])
    import controle_virements
    return controle_virements.executer(date, cfg["racine"], historique_jours=cfg["historique_jours"])


def lire_rapport(dossier: Path) -> dict | None:
    """Relit un dossier rapport_<date> : synthèses markdown + un DataFrame par CSV (vide si absent)."""
    dossier = Path(dossier)
    if not (dossier / "synthese.md").is_file():
        return None
    out = {"dossier": dossier,
           "synthese": (dossier / "synthese.md").read_text(encoding="utf-8"),
           "synthese_simple": ((dossier / "synthese_simple.md").read_text(encoding="utf-8")
                               if (dossier / "synthese_simple.md").is_file() else ""),
           "genere_le": datetime.fromtimestamp((dossier / "synthese.md").stat().st_mtime)}
    for cle, nom, _ in CSV_RAPPORT:
        f = dossier / nom
        if f.is_file() and f.stat().st_size:
            out[cle] = pd.read_csv(f, sep=";", dtype=str, keep_default_na=False, encoding="utf-8")
        else:
            out[cle] = pd.DataFrame()
    return out


def resume(rapport: dict) -> dict:
    """Chiffres clés pour les tuiles : ok, nb/montant envoyés, KO bloquants, à vérifier, écarts classiques."""
    edf = rapport["totaux_edf"]
    nb = int(pd.to_numeric(edf.get("nb_ack_footer", pd.Series(dtype=float)), errors="coerce").fillna(0).sum()) if not edf.empty else 0
    montant = float(pd.to_numeric(edf.get("montant_ack_footer", pd.Series(dtype=float)), errors="coerce").fillna(0).sum()) / 100 if not edf.empty else 0.0
    ko, a_verifier = 0, 0
    for cle in (*CLES_DOUBLONS, "sanite"):
        df = rapport[cle]
        if df.empty:
            continue
        if "gravite" in df.columns:
            ko += int((df["gravite"] == "KO").sum())
            a_verifier += int((df["gravite"] == "A_VERIFIER").sum())
        else:                       # D1 : pas de colonne gravité, toujours bloquant
            ko += len(df)
    ecarts = sum(len(rapport[c]) for c in ("lignes", "quartz"))
    ecarts += sum(int(((rapport[c].get("statut_lignes", "") != "OK") | (rapport[c].get("statut_montant", "") != "OK")).sum())
                  for c in ("totaux_source", "totaux_edf") if not rapport[c].empty)
    fichiers = rapport["fichiers"]
    if not fichiers.empty:
        ecarts += int((~fichiers["statut"].isin(["OK", "DOUBLON"])).sum())
    ok = "✅ Conforme" in rapport["synthese"]
    return {"ok": ok, "nb_envoyes": nb, "montant_envoye": montant, "ko": ko, "a_verifier": a_verifier,
            "ecarts": ecarts, "cible_seul": "cible seul" in rapport["synthese"],
            "quartz": "Non réalisé : l'export de la trésorerie" not in rapport["synthese"]}
