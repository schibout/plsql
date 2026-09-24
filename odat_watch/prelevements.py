"""Onglet Prélèvements : pont vers l'outil CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement par clé métier).

Le code du contrôle vit dans ../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement_cle_metier.executer,
config [prelevements] outil) ; les données (ORACLE/<AAAAMMJJ>, EDF, REJETS) et les rapports
(RAPPORTS/Rapprochement_Cle_Metier_<AAAAMMJJ>_<HHMMSS>.*) dans ../ODAT/Prelevements (config [prelevements] racine).
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
DOSSIER_RAPPORT = "RAPPORTS"
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
        if module is not None and getattr(module, "__spec__", None) is not None:
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


def _doublons(f: Path) -> pd.DataFrame:
    """Doublons d'émission seuls : les rapports produits avant leur suppression contiennent aussi des
    lignes SIMILITUDE, qui ne sont pas des doublons."""
    dbl = _csv(f)
    return dbl[dbl["type"] == "DOUBLON"].reset_index(drop=True) if "type" in dbl.columns else dbl


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
            "doublons": _doublons(dossier / f"{base}_doublons.csv"),
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
    return {"doublons": len(dbl), "statut_global": r.get("statut_global", "INCONNU"), "nb_cles": int(len(df)),
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


# ------------------------------------------------------------------ base : trésorerie EDF persistante, historique

def _iso(d) -> str:
    return d.isoformat() if hasattr(d, "isoformat") else str(d)


def _fichier(genre: str, nom: str, date_fichier, dossier: Path, nb_lignes: int, quand: str):
    import hashlib
    chemin = Path(dossier) / nom
    taille, md5 = None, None
    if chemin.is_file():
        octets = chemin.read_bytes()
        taille, md5 = len(octets), hashlib.md5(octets).hexdigest()
    return (nom, genre, _iso(date_fichier), nb_lignes, taille, md5, quand)


def enregistrer(res: dict, con, quand: datetime | None = None) -> int:
    """Après un lancement : historise le rapprochement (pv_histo) et persiste les fichiers EDF / rejets lus
    (pv_fichiers, pv_edf, pv_rejets). Idempotent : relancer n'ajoute que la ligne d'historique.
    `res` est le dict de rapprochement_cle_metier.executer. Renvoie l'id de l'historique."""
    maintenant = (quand or datetime.now()).strftime("%Y-%m-%d %H:%M:%S")
    ps = res.get("par_statut", {})
    nb_cles = sum(int(e["cles"]) for e in ps.values())
    nb_emis = sum(int(e["nb"]) for e in ps.values())
    montant = float(sum(float(e["montant"]) for e in ps.values()))
    with con:
        cur = con.execute(
            "INSERT INTO pv_histo(reference, executed_at, statut_global, nb_cles, nb_emis, montant_emis, en_attente, anomalies, "
            "signales, a_investiguer, doublons, lignes_ko, avertissements, base) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (_iso(res["reference"]), maintenant, res["statut_global"], nb_cles, nb_emis, montant,
             int(ps.get("EN_ATTENTE", {}).get("cles", 0)), int(res.get("nb_anomalies") or 0), int(res.get("nb_signales") or 0),
             int(res.get("nb_a_investiguer") or 0), int(res.get("nb_doublons") or 0),
             int(res.get("nb_lignes_ko") or 0), len(res.get("avertissements") or []), res.get("base")))
        histo_id = cur.lastrowid
        edf, rejets = res.get("edf") or [], res.get("rejets") or []
        par_fichier: dict[str, tuple] = {}
        for f in res.get("fichiers_edf") or []:          # tous les fichiers reçus, même sans ligne du SI
            par_fichier[f["fichier"]] = ("EDF", f["date_fichier"], Path(res["dossier_edf"]), 0)
        for f in res.get("fichiers_rejets") or []:
            par_fichier[f["fichier"]] = ("REJET", f["date_fichier"], Path(res["dossier_rejets"]), 0)
        for e in edf:
            par_fichier.setdefault(e["fichier"], ("EDF", e["date_fichier"], Path(res["dossier_edf"]), 0))
            g = par_fichier[e["fichier"]]
            par_fichier[e["fichier"]] = (*g[:3], g[3] + 1)
        for r in rejets:
            par_fichier.setdefault(r["fichier"], ("REJET", r["date_fichier"], Path(res["dossier_rejets"]), 0))
            g = par_fichier[r["fichier"]]
            par_fichier[r["fichier"]] = (*g[:3], g[3] + 1)
        con.executemany(
            "INSERT INTO pv_fichiers(nom, genre, date_fichier, nb_lignes, taille, md5, importe_le) VALUES (?,?,?,?,?,?,?) "
            "ON CONFLICT(nom) DO UPDATE SET nb_lignes=excluded.nb_lignes, taille=COALESCE(excluded.taille, pv_fichiers.taille), "
            "md5=COALESCE(excluded.md5, pv_fichiers.md5)",
            [_fichier(genre, nom, d, dossier, n, maintenant) for nom, (genre, d, dossier, n) in par_fichier.items()])
        con.executemany(
            "INSERT OR REPLACE INTO pv_edf(fichier, date_fichier, nom_si, iban_creancier, echeance, nb, montant) VALUES (?,?,?,?,?,?,?)",
            [(e["fichier"], _iso(e["date_fichier"]), e.get("nom_si"), e["iban_creancier"], _iso(e["echeance"]),
              int(e["nb"]), float(e["montant"])) for e in edf])
        con.executemany(
            "INSERT OR REPLACE INTO pv_rejets(fichier, date_fichier, iban_creancier, rum, iban_debiteur, echeance, montant, code, "
            "motif, appariee, beneficiaire) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            [(r["fichier"], _iso(r["date_fichier"]), r.get("iban_creancier"), r["rum"], r.get("iban_debiteur"),
              _iso(r["echeance"]), float(r["montant"]), r.get("code"), r.get("motif"), int(bool(r.get("appariee"))),
              r.get("beneficiaire")) for r in rejets])
    return histo_id


def maj_fichier_rapport(histo_id: int, fichier: str, con) -> None:
    with con:
        con.execute("UPDATE pv_histo SET fichier_rapport = ? WHERE id = ?", (fichier, histo_id))


def historique(jours: int, con) -> pd.DataFrame:
    """Une ligne par date de référence (dernière exécution), sur les N derniers jours."""
    sql = """
    SELECT reference, executed_at, statut_global, nb_cles, nb_emis, montant_emis, en_attente, anomalies, signales,
           a_investiguer, doublons, lignes_ko, avertissements, fichier_rapport
    FROM pv_histo h
    WHERE executed_at = (SELECT MAX(executed_at) FROM pv_histo WHERE reference = h.reference)
      AND reference >= date('now', ?)
    ORDER BY reference DESC"""
    return pd.read_sql_query(sql, con, params=(f"-{int(jours)} days",))


def _jours_ouvres(debut: date, fin: date) -> list[date]:
    from datetime import timedelta
    from controle_matin import jours_feries
    feries = jours_feries(debut.year) | jours_feries(fin.year)
    j, out = debut, []
    while j <= fin:
        if j.weekday() < 5 and j not in feries:
            out.append(j)
        j += timedelta(days=1)
    return out


def tresorerie(con, jours: int = 90, reference: date | None = None) -> dict:
    """Vue trésorerie EDF depuis la base : chronologie des états reçus (nb, montant, rejets du jour), jours ouvrés
    sans état, rejets de la période, mandats rejetés plusieurs fois."""
    from datetime import timedelta
    reference = reference or date.today()
    debut = (reference - timedelta(days=jours)).isoformat()
    chrono = pd.read_sql_query("""
        SELECT f.date_fichier, f.nom AS fichier,
               COALESCE(SUM(e.nb), 0) AS nb, COALESCE(SUM(e.montant), 0) AS montant,
               COUNT(DISTINCT e.iban_creancier || e.echeance) AS cles,
               (SELECT COUNT(*) FROM pv_rejets r WHERE r.date_fichier = f.date_fichier) AS rejets
        FROM pv_fichiers f LEFT JOIN pv_edf e ON e.fichier = f.nom
        WHERE f.genre = 'EDF' AND f.date_fichier >= ?
        GROUP BY f.date_fichier, f.nom ORDER BY f.date_fichier DESC""", con, params=(debut,))
    recus = {datetime.strptime(d, "%Y-%m-%d").date() for d in chrono["date_fichier"]} if not chrono.empty else set()
    premier = min(recus) if recus else None
    jours_sans = [j for j in _jours_ouvres(premier, reference) if j not in recus] if premier else []
    rejets = pd.read_sql_query("""
        SELECT date_fichier, echeance, beneficiaire, rum, iban_debiteur, montant, code, motif, appariee, fichier
        FROM pv_rejets WHERE date_fichier >= ? ORDER BY date_fichier DESC, echeance""", con, params=(debut,))
    recidives = pd.read_sql_query("""
        SELECT rum, MAX(beneficiaire) AS beneficiaire, COUNT(*) AS nb_rejets, ROUND(SUM(montant), 2) AS montant,
               GROUP_CONCAT(DISTINCT code) AS codes, MIN(date_fichier) AS premier, MAX(date_fichier) AS dernier
        FROM pv_rejets WHERE date_fichier >= ? GROUP BY rum HAVING COUNT(*) > 1 ORDER BY nb_rejets DESC, montant DESC""",
        con, params=(debut,))
    return {"chronologie": chrono, "jours_sans_etat": jours_sans, "rejets": rejets, "recidives": recidives}


def fichiers_absents(con, dossier_edf: Path, dossier_rejets: Path) -> list[str]:
    """Fichiers connus en base mais plus présents sur disque : la base en garde la mémoire, on le signale."""
    out = []
    for nom, genre in con.execute("SELECT nom, genre FROM pv_fichiers ORDER BY date_fichier"):
        dossier = Path(dossier_edf) if genre == "EDF" else Path(dossier_rejets)
        if not (dossier / nom).is_file():
            out.append(nom)
    return out
