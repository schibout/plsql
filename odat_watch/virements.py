"""Onglet Virements : pont vers l'outil controleVirement (dossiers *_cible chargés à la main).

Le code du contrôle vit dans ../controleVirement (controle_virements.executer, config [virements] outil) ;
les données (dossiers JJMMAAAA/<uuid> avec SOURCE, TALEND, TARGET ; fichier Quartz ; rapports rapport_<date>)
dans ../ODAT/virements
(config [virements] racine). Ici on choisit la journée, on lance le contrôle et on relit son rapport.
"""
from __future__ import annotations
import configparser
import re
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd

from oracle_refresh import BASE_DIR, CONFIG

DEFAUTS = {"outil": r"..\controleVirement", "racine": r"..\ODAT\virements", "depot": "import_virement",
           "historique_jours": "7"}

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
    racine = _chemin(val["racine"])
    depot = Path(val["depot"].strip() or "import_virement")
    return {"outil": _chemin(val["outil"]), "racine": racine,
            "depot": depot if depot.is_absolute() else racine / depot,
            "historique_jours": int(val["historique_jours"] or 0)}


def dates_disponibles(racine: Path) -> list[str]:
    """Dates JJMMAAAA ayant un dossier JJMMAAAA (ou JJMMAAAA_cible, ancienne disposition) sous la racine,
    la plus récente en premier."""
    dates = set()
    for d in Path(racine).iterdir():
        m = re.fullmatch(r"(\d{8})(?:_cible)?", d.name)
        if m and d.is_dir():
            try:
                datetime.strptime(m.group(1), "%d%m%Y")
            except ValueError:
                continue
            dates.add(m.group(1))
    return sorted(dates, key=lambda d: datetime.strptime(d, "%d%m%Y"), reverse=True)


def nb_instances(racine: Path, date: str) -> int:
    """Nombre de sous-dossiers (instances) du dossier du jour."""
    for nom in (date, f"{date}_cible"):
        d = Path(racine) / nom
        if d.is_dir():
            return sum(1 for x in d.iterdir() if x.is_dir())
    return 0


def date_lisible(d: str) -> str:
    return f"{d[0:2]}/{d[2:4]}/{d[4:8]}"


def source_presente(racine: Path, date: str) -> bool:
    return (Path(racine) / f"{date}_source").is_dir()


def fichier_quartz(cfg: dict, date: str) -> Path | None:
    _outil(cfg["outil"])
    import controle_virements
    return controle_virements.trouver_fichier_quartz(Path(cfg["racine"]), date)


def _outil(outil: Path) -> None:
    """Rend importable controle_virements / cv depuis le dossier de l'outil, et recharge ces modules s'ils
    étaient déjà importés : Streamlit ne surveille que les fichiers de l'application, une mise à jour de
    l'outil resterait sinon invisible jusqu'au redémarrage."""
    r = str(Path(outil))
    if r not in sys.path:
        sys.path.insert(0, r)
    _recharger(("cv.model", "cv.parsers", "cv.montant", "cv.discovery", "cv.reconcile", "cv.doublons",
                "cv.sanite", "cv.report", "controle_virements"))


def _recharger(noms) -> None:
    import importlib
    for nom in noms:
        module = sys.modules.get(nom)
        if module is not None:
            try:
                importlib.reload(module)
            except Exception:  # noqa: BLE001 — un module absent de cette version de l'outil n'empêche rien
                pass


def lancer(date: str, cfg: dict) -> dict:
    """Exécute le contrôle et écrit rapport_<date> sous la racine des données. Renvoie le dict de
    controle_virements.executer."""
    _outil(cfg["outil"])
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


# ------------------------------------------------------------------ base : instances, envois, historique

def _date_iso(date: str) -> str:
    return datetime.strptime(date, "%d%m%Y").strftime("%Y-%m-%d")


def enregistrer(date: str, res: dict, con, quand: datetime | None = None) -> int:
    """Après un lancement : historise le contrôle (vir_histo), les instances lues (vir_imports, une ligne par uuid,
    conservée d'un lancement à l'autre) et les envois vers la banque (vir_envois, remplacés pour la journée).
    `res` est le dict de controle_virements.executer. Renvoie l'id de l'historique."""
    quand = quand or datetime.now()
    date_iso, maintenant = _date_iso(date), quand.strftime("%Y-%m-%d %H:%M:%S")
    rapport = lire_rapport(Path(res["dossier"]))
    r = resume(rapport) if rapport else {"ok": res["ok"], "nb_envoyes": 0, "montant_envoye": 0.0, "ko": 0,
                                         "a_verifier": 0, "ecarts": 0, "quartz": res.get("quartz", False)}
    with con:
        cur = con.execute(
            "INSERT INTO vir_histo(date_ctrl, executed_at, ok, nb_instances, nb_envoyes, montant_envoye, ko, a_verifier, "
            "ecarts, quartz, cible_seul, dossier_rapport) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (date_iso, maintenant, int(bool(r["ok"])), res.get("nb_instances"), r["nb_envoyes"], r["montant_envoye"],
             r["ko"], r["a_verifier"], r["ecarts"], int(bool(res.get("quartz"))), int(bool(res.get("cible_seul"))),
             str(res["dossier"])))
        histo_id = cur.lastrowid
        par_guid: dict[str, dict] = {}
        for f in res.get("fichiers", []):
            g = par_guid.setdefault(f["guid"], {"nb_fichiers": 0, "nb_envois": 0})
            if f.get("categorie") != "INSTANCE":
                g["nb_fichiers"] += 1
            if f.get("categorie") == "ACK":
                g["nb_envois"] += 1
        for guid, g in par_guid.items():
            con.execute(
                "INSERT INTO vir_imports(guid, date_ctrl, dossier, nb_fichiers, nb_envois, cible_seul, importe_le, controle_le) "
                "VALUES (?,?,?,?,?,?,?,?) ON CONFLICT(guid) DO UPDATE SET date_ctrl=excluded.date_ctrl, dossier=excluded.dossier, "
                "nb_fichiers=excluded.nb_fichiers, nb_envois=excluded.nb_envois, cible_seul=excluded.cible_seul, "
                "controle_le=excluded.controle_le",
                (guid, date_iso, str(res["dossier"]), g["nb_fichiers"], g["nb_envois"], int(bool(res.get("cible_seul"))),
                 maintenant, maintenant))
        con.execute("DELETE FROM vir_envois WHERE date_ctrl = ?", (date_iso,))
        con.executemany(
            "INSERT INTO vir_envois(histo_id, date_ctrl, guid, fichier_ack, nb, montant, statut) VALUES (?,?,?,?,?,?,?)",
            [(histo_id, date_iso, t["guid"], t["fichier_edf"], int(t.get("nb_ack_footer") or 0),
              round(float(t.get("montant_ack_footer") or 0) / 100, 2),
              "OK" if t.get("statut_lignes") == "OK" and t.get("statut_montant") == "OK"
              else f"{t.get('statut_lignes')}/{t.get('statut_montant')}")
             for t in res.get("totaux_edf", [])])
    return histo_id


def maj_fichier_rapport(histo_id: int, fichier: str, con) -> None:
    with con:
        con.execute("UPDATE vir_histo SET fichier_rapport = ? WHERE id = ?", (fichier, histo_id))


def historique(jours: int, con) -> pd.DataFrame:
    """Une ligne par journée contrôlée (dernière exécution), sur les N derniers jours."""
    sql = """
    SELECT date_ctrl, executed_at, ok, nb_instances, nb_envoyes, montant_envoye, ko, a_verifier, ecarts, quartz, fichier_rapport
    FROM vir_histo h
    WHERE executed_at = (SELECT MAX(executed_at) FROM vir_histo WHERE date_ctrl = h.date_ctrl)
      AND date_ctrl >= date('now', ?)
    ORDER BY date_ctrl DESC"""
    return pd.read_sql_query(sql, con, params=(f"-{int(jours)} days",))


def imports_connus(con) -> dict[str, str]:
    """uuid -> journée (AAAA-MM-JJ) des instances déjà enregistrées."""
    return {r[0]: r[1] for r in con.execute("SELECT guid, date_ctrl FROM vir_imports")}
