"""Relevés bancaires : suivi de la chaîne PFE → Control-M → EBS (import RBAFBIMP, contrôle DKA_SRBCTRLRB).

Ce module porte le métier de l'onglet : verdict de la matinée par flux, chronologie des imports, continuité des
comptes, plan de reprise, list.txt des logs manquants et vues tabulaires. L'acquisition (lecture AFB120, scan des
dossiers, parseurs de logs, Control-M) est dans releves_scan.py, dont les noms publics sont ré-exportés ici.
"""
from __future__ import annotations

import sqlite3
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path

import pandas as pd

from releves_scan import (  # noqa: F401 — ré-exports utilisés par l'onglet, le rapport et les tests
    CONFIG, DEFAUTS, BASE_DIR, Afb120, config_releves, maintenant, lire_afb120,
    scanner_pfe, scanner_ebs, rapprocher_pfe_ebs, scanner_logs, scanner_tout,
    parse_import_out, parse_controle_out, _date_ctrl,
    comptes_connus, comptes_connus_init, enregistrer_comptes_connus,
    chaine_controlm, diagnostic_controlm, recalculer_hors_connus,
)


# ---------------------------------------------------------------- journée
FENETRE = {"B": ("08:05:00", "10:00:00")}          # fenêtre du flux B : borne des contrôles « après flux B » sans import
TON_VERDICT = {"OK": "ok", "WARN": "warn", "KO": "ko", "—": "neutral"}

# Libellés de colonnes partagés par l'onglet et le rapport HTML
COLONNES_PLAN = {"ordre": "Étape", "chemin": "Fichier source", "origine": "Origine", "periode": "Relevé",
                 "nb_releves": "Relevés", "attendu": "Résultat attendu"}
COLONNES_CHRONO = {"debut": "Date / heure", "request_id": "Request", "fichier": "Fichier EBS", "flux": "Flux", "lus": "Lus",
                   "ecrits": "Écrits", "charges": "Chargés", "erreurs": "Erreurs", "resultat": "Résultat"}
COLONNES_CONTINUITE = {"compte": "Compte", "dernier_charge": "Dernier relevé chargé", "attendu": "Attendu",
                       "retard_j": "Retard (j)", "trou": "Trou", "connu": "Connu"}
COLONNES_PFE = {"horodatage": "Exécution PFE", "uuid": "UUID", "flux": "Flux", "nb_releves": "Relevés", "date_min": "Du",
                "date_max": "Au", "fichier_ebs": "Fichier EBS", "request_id": "Import", "statut": "Statut"}


@dataclass
class Flux:
    code: str
    pfe: dict | None = None
    ebs: dict | None = None
    import_: dict | None = None
    controles: list = field(default_factory=list)
    controlm: dict = field(default_factory=dict)
    verdict: str = "—"
    causes: list = field(default_factory=list)
    etapes: list = field(default_factory=list)      # [{cle, libelle, ton, texte}]


@dataclass
class Journee:
    jour: date
    flux: dict = field(default_factory=dict)        # "A" / "B" -> Flux
    controlm_df: pd.DataFrame = field(default_factory=pd.DataFrame)
    controles: list = field(default_factory=list)
    verdict: str = "—"
    motif: str | None = None                        # samedi / dimanche / jour férié


def _un(con, sql, params) -> dict | None:
    r = con.execute(sql, params).fetchone()
    return dict(r) if r else None


def _tous(con, sql, params) -> list[dict]:
    return [dict(r) for r in con.execute(sql, params)]


def rejet_massif(imp) -> bool:
    """Import rejeté en bloc : aucun relevé chargé et plusieurs Erreur 025 (dict, sqlite3.Row ou ligne pandas)."""
    if imp is None:
        return False
    charges = imp["releves_charges"] if "releves_charges" in imp.keys() else imp["charges"]
    return (charges or 0) == 0 and (imp["err025"] or 0) > 1


def _anomalies_flux(con: sqlite3.Connection, c: dict, code: str, banque_b: str, connus: set[str]) -> int:
    """Anomalies d'un contrôle pertinentes pour un flux : toutes (hors comptes connus) pour le flux B ; pour le
    flux A, seulement celles des autres banques — un contrôle lancé avant le flux B liste normalement les ~207
    comptes de la banque B, ce qui ne dit rien du flux A."""
    if code == "B":
        return c["nb_hors_connus"] or 0
    return sum(1 for l in con.execute("SELECT banque, guichet, numero FROM rb_controle_lignes WHERE request_id=?",
                                      (c["request_id"],))
               if l["banque"] != banque_b and f"{l['banque']}/{l['guichet']}/{l['numero']}" not in connus)


def journee(con: sqlite3.Connection, jour: date, cfg: dict) -> Journee:
    import controle_matin as cm
    j = Journee(jour=jour, motif=cm.jour_sans_integration(jour))
    js = jour.isoformat()
    j.controlm_df = chaine_controlm(con, jour)
    diag = diagnostic_controlm(j.controlm_df)
    j.controles = _tous(con, "SELECT * FROM rb_controles WHERE substr(executed_at,1,10)=? ORDER BY executed_at", (js,))
    banque_b, connus = cfg["banque_flux_b"], comptes_connus(con)
    # dernier relevé de la banque B chargé par un import du flux B (les fichiers A portent aussi quelques comptes B)
    dernier_charge_b = con.execute("SELECT MAX(r.date_fin) FROM rb_import_releves r JOIN rb_imports i "
                                   "ON i.request_id = r.request_id WHERE r.en_erreur=0 AND r.banque=? AND i.flux='B'",
                                   (banque_b,)).fetchone()[0]
    for code in ("A", "B"):
        f = Flux(code=code, controlm=diag)
        f.pfe = _un(con, "SELECT * FROM rb_pfe WHERE flux=? AND substr(horodatage,1,10)=? ORDER BY horodatage DESC LIMIT 1", (code, js))
        f.ebs = _un(con, "SELECT * FROM rb_ebs WHERE flux=? AND substr(horodatage,1,10)=? ORDER BY horodatage DESC LIMIT 1", (code, js))
        # le flux d'un import est déjà déterminé par ses banques : pas de fenêtre horaire (le flux B du 14/09 tourne à 07:49)
        f.import_ = _un(con, "SELECT * FROM rb_imports WHERE flux=? AND substr(debut,1,10)=? ORDER BY debut DESC LIMIT 1", (code, js))
        # contrôles rattachés : tous pour A ; pour B, seulement ceux exécutés après l'import (ou après la fenêtre B)
        apres = (f.import_ or {}).get("fin") or (f.import_ or {}).get("debut") or f"{js} {FENETRE['B'][0]}"
        f.controles = [dict(c, nb_hors_connus_flux=_anomalies_flux(con, c, code, banque_b, connus))
                       for c in j.controles if code == "A" or c["executed_at"] > apres]
        _verdict_flux(f, j.motif, dernier_charge_b if code == "B" else None)
        j.flux[code] = f
    if j.motif and not any(f.pfe or f.import_ for f in j.flux.values()):
        j.verdict = "—"
    else:
        ordre = {"KO": 3, "WARN": 2, "OK": 1, "—": 0}
        j.verdict = max((f.verdict for f in j.flux.values()), key=ordre.get)
    return j


def _verdict_flux(f: Flux, motif: str | None, dernier_charge: str | None = None) -> None:
    d = f.controlm
    pfe, ebs, imp = f.pfe, f.ebs, f.import_
    # --- PFE
    if pfe:
        e_pfe = ("ok" if pfe["complete"] else "warn",
                 f"{pfe['horodatage'][11:16]} · {pfe['nb_releves']} relevés ({pfe['date_min']} → {pfe['date_max']})")
        if not pfe["complete"]:
            f.causes.append("Exécution PFE incomplète (SOURCE / zip / LS_IN.OK manquant).")
    else:
        e_pfe = ("neutral", "aucune exécution")
    # --- Control-M
    if not d.get("photo"):
        e_ctm = ("neutral", "pas de photo")
    elif f.code == "B" and (d["conflit_mov"] or d["zip06_not_ok"]):
        e_ctm = ("ko", "chaîne 06 bloquée")
        f.causes.extend(d["causes"])
    else:
        e_ctm = ("ok", f"photo {d['photo'][11:16]}")
    # --- réception EBS
    if ebs:
        e_ebs = ("ok", f"{ebs['horodatage'][11:16]} · {ebs['nom']}")
    elif pfe and not pfe["ebs_md5_recu"]:
        e_ebs = ("ko", "non reçu")
        f.causes.append(f"Fichier PFE de {pfe['horodatage'][11:16]} non reçu par EBS (aucun AFB120.txt_* de même md5) : "
                        "les jobs move / dézip de Control-M n'ont pas livré le zip.")
    else:
        e_ebs = ("neutral", "—")
    # --- import
    if imp:
        h_imp = f"{imp['debut'][11:16]} · " if imp.get("debut") else ""
        if rejet_massif(imp):
            e_imp = ("ko", f"{h_imp}req {imp['request_id']} · 0 chargé · {imp['err025']} × Erreur 025")
            f.causes.append(f"Import {imp['request_id']} rejeté en bloc : {imp['err025']} × Erreur 025 « Journée manquante » — "
                            "un relevé antérieur n'a jamais été chargé ; rejouer les fichiers manquants dans l'ordre"
                            + (f" — dernier relevé chargé le {dernier_charge}." if dernier_charge else "."))
        elif not imp.get("source_out"):
            e_imp = ("warn", f"{h_imp}req {imp['request_id']} · .out absent")
            f.causes.append(f"Import {imp['request_id']} : log .out absent (résultat inconnu) : lancer copy_ebs_logs.sh.")
        elif (imp["releves_charges"] or 0) == 0:
            e_imp = ("ko", f"{h_imp}req {imp['request_id']} · 0 chargé")
            f.causes.append(f"Import {imp['request_id']} : aucun relevé chargé.")
        else:
            e_imp = ("ok", f"{h_imp}req {imp['request_id']} · {imp['releves_charges']} chargés / {imp['releves_erreurs']} err.")
    elif pfe or ebs:
        e_imp = ("ko", "pas d'import")
        if ebs:
            f.causes.append("Fichier reçu par EBS mais aucun import RBAFBIMP trouvé (log absent ? lancer copy_ebs_logs.sh).")
    else:
        e_imp = ("neutral", "—")
    # --- contrôle
    if motif and not (pfe or ebs or imp):
        e_ctl = ("neutral", "pas d'intégration attendue")
    elif f.controles:
        c = f.controles[-1]
        nb = c.get("nb_hors_connus_flux", c["nb_hors_connus"]) or 0
        h_ctl = f"{c['executed_at'][11:16]} · " if c.get("executed_at") else ""
        if nb == 0:
            e_ctl = ("ok", f"{h_ctl}req {c['request_id']} · aucune anomalie")
        elif f.code == "B" and imp and not rejet_massif(imp):
            e_ctl = ("warn", f"{h_ctl}req {c['request_id']} · {nb} anomalie(s)")
        else:
            e_ctl = ("ko" if f.code == "B" else "warn", f"{h_ctl}req {c['request_id']} · {nb} anomalie(s)")
    else:
        e_ctl = ("neutral", "pas de contrôle")
    f.etapes = [dict(cle=k, libelle=l, ton=t, texte=x) for k, l, (t, x) in
                (("pfe", "PFE", e_pfe), ("controlm", "Control-M", e_ctm), ("ebs", "Reçu EBS", e_ebs),
                 ("import", "Import", e_imp), ("controle", "Contrôle", e_ctl))]
    # --- verdict
    tons = [e["ton"] for e in f.etapes]
    if not pfe and not ebs and not imp:
        f.verdict = "—" if motif else "WARN"
        if not motif:
            f.causes.append(f"Aucun fichier PFE pour le flux {f.code} ce jour (banque en retard ?) — à surveiller le lendemain.")
    elif "ko" in tons:
        f.verdict = "KO"
    elif "warn" in tons:
        f.verdict = "WARN"
    else:
        f.verdict = "OK"


# ---------------------------------------------------------------- chronologie
def chronologie(con: sqlite3.Connection, jours: int = 15, jour: date | None = None) -> pd.DataFrame:
    fin = (jour or date.today()) + timedelta(days=1)
    debut = fin - timedelta(days=jours)
    df = pd.read_sql_query(
        "SELECT i.request_id, i.debut, e.nom AS fichier, i.flux, i.lus, i.ecrits, i.releves_charges AS charges, "
        "i.releves_erreurs AS erreurs, i.err001, i.err025 FROM rb_imports i LEFT JOIN rb_ebs e ON e.md5 = i.md5_ebs "
        "WHERE i.debut >= ? AND i.debut < ? ORDER BY i.debut", con, params=(debut.isoformat(), fin.isoformat()))

    def resultat(r):
        if rejet_massif(r):
            return f"{int(r['err025'])} × Erreur 025 — rejet total"
        if (r["charges"] or 0) == 0:
            return "aucun relevé chargé"
        return "OK" if (r["err025"] or 0) <= 1 else f"OK mais {int(r['err025'])} × Erreur 025"
    df["resultat"] = df.apply(resultat, axis=1) if not df.empty else []
    return df


# ---------------------------------------------------------------- continuité et reprise
def continuite(con: sqlite3.Connection, cfg: dict, jour: date | None = None) -> pd.DataFrame:
    """Par compte de la banque du flux B : dernier relevé chargé, date attendue (dernier fichier PFE/EBS flux B),
    retard en jours, trou (un import ultérieur a rejeté le compte en Erreur 025)."""
    b = cfg["banque_flux_b"]                       # code banque (rb_import_releves.banque) ; les colonnes flux valent "B"
    connus = comptes_connus(con)
    borne = (jour or date.max).isoformat()          # date attendue = dernier fichier flux B connu, au plus tard `jour`
    attendu = con.execute("SELECT MAX(m) FROM (SELECT MAX(date_max) m FROM rb_pfe WHERE flux='B' AND date_max <= ? "
                          "UNION ALL SELECT MAX(date_max) FROM rb_ebs WHERE flux='B' AND date_max <= ?)",
                          (borne, borne)).fetchone()[0]
    df = pd.read_sql_query("""
        SELECT r.compte, r.banque, r.guichet, r.numero,
               MAX(CASE WHEN r.en_erreur=0 THEN r.date_fin END) AS dernier_charge,
               MAX(CASE WHEN r.en_erreur=0 THEN i.debut END) AS dernier_import_ok,
               MAX(CASE WHEN r.code_erreur='Erreur 025' THEN i.debut END) AS dernier_rejet_025
        FROM rb_import_releves r JOIN rb_imports i ON i.request_id = r.request_id
        WHERE r.banque = ? GROUP BY r.compte ORDER BY r.compte""", con, params=(b,))
    if df.empty:
        return df.assign(attendu=None, retard_j=None, trou=None, connu=None)
    df["attendu"] = attendu
    # NULL SQL -> valeur manquante pandas (NaN, « vrai » en booléen) : on teste explicitement la présence
    present = lambda v: v is not None and pd.notna(v) and str(v) != ""   # noqa: E731
    df["retard_j"] = df.apply(lambda r: max(0, (date.fromisoformat(r["attendu"]) - date.fromisoformat(r["dernier_charge"])).days)
                              if present(r["attendu"]) and present(r["dernier_charge"]) else None, axis=1)
    # trou : le dernier rejet 025 est postérieur au dernier import ayant chargé le compte (import comparé à import)
    df["trou"] = df.apply(lambda r: present(r["dernier_rejet_025"]) and
                          (not present(r["dernier_import_ok"]) or str(r["dernier_rejet_025"]) > str(r["dernier_import_ok"])), axis=1)
    df["connu"] = df.apply(lambda r: f"{r['banque']}/{r['guichet']}/{r['numero']}" in connus, axis=1)
    return df


def plan_reprise(con: sqlite3.Connection, cfg: dict) -> list[dict]:
    """Fichiers du flux B à rejouer dans l'ordre : TARGET PFE non reçus, fichiers EBS rejetés en bloc ou jamais importés,
    à partir du dernier relevé chargé. [{ordre, chemin, origine, periode, nb_releves, attendu}]"""
    dernier_charge = con.execute("SELECT MAX(r.date_fin) FROM rb_imports i JOIN rb_import_releves r "
                                 "ON r.request_id=i.request_id AND r.en_erreur=0 WHERE i.flux='B' AND i.releves_charges > 0"
                                 ).fetchone()[0] or "0000-00-00"
    # erreurs « habituelles » : celles du dernier import flux B réussi (comptes connus en erreur chaque jour)
    dernier_ok = con.execute("SELECT releves_erreurs FROM rb_imports WHERE flux='B' AND releves_charges > 0 "
                             "ORDER BY fin DESC LIMIT 1").fetchone()
    erreurs_habituelles = dernier_ok["releves_erreurs"] if dernier_ok else 0
    cand: dict[str, dict] = {}
    for r in con.execute("SELECT * FROM rb_pfe WHERE flux='B' AND ebs_md5_recu=0 AND complete=1 AND date_max > ?", (dernier_charge,)):
        cand[r["md5"]] = dict(chemin=r["fichier_target"], origine="PFE (non reçu)", date_min=r["date_min"],
                              date_max=r["date_max"], nb_releves=r["nb_releves"])
    # un fichier EBS importé plusieurs fois (rejet puis rejeu) : c'est le dernier import qui compte
    derniers: dict[str, sqlite3.Row] = {}
    for r in con.execute("SELECT e.*, i.request_id, i.releves_charges, i.err025 FROM rb_ebs e "
                         "LEFT JOIN rb_imports i ON i.md5_ebs = e.md5 WHERE e.flux='B' AND e.date_max > ? "
                         "ORDER BY e.horodatage, i.debut", (dernier_charge,)):
        derniers[r["md5"]] = r
    for md5, r in derniers.items():
        if r["request_id"] is None:
            origine = "EBS (jamais importé)"
        elif rejet_massif(dict(r)):
            origine = "EBS (rejeté Erreur 025)"
        else:
            cand.pop(md5, None)          # reçu et chargé : rien à rejouer, même si le TARGET PFE n'est pas apparié
            continue
        cand[md5] = dict(chemin=str(cfg["dossier_ebs"] / r["nom"]), origine=origine, date_min=r["date_min"],
                         date_max=r["date_max"], nb_releves=r["nb_releves"])
    etapes = sorted(cand.values(), key=lambda c: (c["date_min"], c["date_max"]))
    err = erreurs_habituelles or 0
    for i, e in enumerate(etapes, 1):
        e["ordre"] = i
        e["periode"] = f"{e['date_min']} → {e['date_max']}"
        e["attendu"] = f"{e['nb_releves'] - err} chargés / {err} erreurs"
    return etapes


def liste_logs_manquants(con: sqlite3.Connection, dest: Path | None = None) -> str:
    """list.txt pour copy_ebs_logs.sh : requests RBAFBIMP / DKA_SRBCTRLRB connues d'ora_requests sans log local."""
    rows = con.execute("""
        SELECT r.request_id, r.logfile_name, r.outfile_name FROM ora_requests r
        WHERE r.program_short IN ('RBAFBIMP', 'DKA_SRBCTRLRB') AND r.phase_code = 'C'
          AND r.request_id NOT IN (SELECT request_id FROM rb_imports WHERE source_out IS NOT NULL)
          AND r.request_id NOT IN (SELECT request_id FROM rb_controles WHERE source_out IS NOT NULL)
        ORDER BY r.actual_start""").fetchall()
    dest = dest or (BASE_DIR / "list_releves.txt")
    lignes = [f"{r['logfile_name'] or ''} {r['outfile_name'] or ''}".strip() for r in rows if r["logfile_name"]]
    dest.write_text("\n".join(lignes) + ("\n" if lignes else ""), encoding="utf-8", newline="\n")
    return f"{len(lignes)} ligne(s) écrite(s) dans {dest} (à passer à copy_ebs_logs.sh sur le serveur EBS)."


# ---------------------------------------------------------------- vues tabulaires
def rapprochement_pfe(con: sqlite3.Connection) -> pd.DataFrame:
    """Exécutions PFE avec leur statut de réception : reçu / non reçu / reçu mais rejeté (Erreur 025)."""
    df = pd.read_sql_query(
        "SELECT p.uuid, p.horodatage, p.flux, p.nb_releves, p.nb_lignes, p.date_min, p.date_max, p.complete, p.ebs_md5_recu, "
        "e.nom AS fichier_ebs, i.request_id, i.releves_charges, i.err025 FROM rb_pfe p "
        "LEFT JOIN rb_ebs e ON e.md5 = p.md5 LEFT JOIN rb_imports i ON i.md5_ebs = p.md5 ORDER BY p.horodatage", con)
    if df.empty:
        return df.assign(statut=None)
    df["statut"] = df.apply(lambda r: "non reçu" if not r["ebs_md5_recu"] else
                            ("reçu · rejeté Erreur 025" if rejet_massif(r) else "reçu"), axis=1)
    return df


def controles(con: sqlite3.Connection, jours: int = 30) -> pd.DataFrame:
    return pd.read_sql_query("SELECT request_id, executed_at, date_reference, nb_anomalies, nb_sg, nb_hors_connus "
                             "FROM rb_controles ORDER BY executed_at DESC LIMIT ?", con, params=(jours * 3,))


def lignes_controle(con: sqlite3.Connection, request_id: int) -> pd.DataFrame:
    return pd.read_sql_query("SELECT * FROM rb_controle_lignes WHERE request_id=? ORDER BY banque, guichet, numero",
                             con, params=(request_id,))
