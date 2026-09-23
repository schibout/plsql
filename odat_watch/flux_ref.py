"""Référentiel des flux autour d'Oracle : un flux = une application, un objet échangé et un sens, comme le
schéma « Flux pour FIN01 - ORACLE » les dessine. Chaque fiche porte en plus ce que le schéma ne dit pas :
le motif du nom de fichier, qui appeler (interlocuteurs) et tout le reste (attributs libres clé / valeur)."""
from __future__ import annotations
import csv
import fnmatch
import io
import json
import re
import sqlite3
import unicodedata
from datetime import datetime
from pathlib import Path

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
CATALOGUE_FIN01 = BASE_DIR / "flux_fin01.json"       # extrait du schéma Flux-FIN01 - ORACLE.pdf (23/09/2026)

SENS = ("entrant", "sortant")
STATUTS = ("Actif", "En projet", "Inactif")
NATURES = ("Flux Asynchrone (Batch)", "Flux Asynchrone (Fil de l'eau)", "Flux Synchrone", "Nature de flux inconnue")
DOMAINES = ("FINANCES", "REFERENTIEL", "OPERATION", "RESSOURCES HUMAINES", "PARTENAIRES EXTERNES",
            "JURIDIQUE, RISQUE, COMMUNICATION & PILOTAGE", "MARKETING, COMMERCE & RELATION CLIENTS",
            "APPLICATION SYSTEME D'INFORMATION", "DECOMMISSIONNEE", "INCONNU")
TYPES = ("FOURNISSEURS", "CLIENTS", "GL", "AUTRE")
SOURCES_ETAT = ("ctrl_flux", "virements", "prelevements", "releves", "")
ROLES = ("amont", "EAI", "metier", "Oracle", "autre")
COLS_FLUX = ["code", "application", "nom_application", "domaine", "sens", "objet", "nature", "statut",
             "type_flux", "motif", "source_etat", "dossier_unix", "commentaire"]
COLS_INTER = ["nom", "role", "mail", "telephone", "remarque"]
FAMILLES = {"FOURNISSEURS": "FACTURESFOURNISSEURS", "CLIENTS": "FACTURESCLIENTS", "GL": "ECRITURESGL"}


# ------------------------------------------------------------------ outils

def slug(texte: str) -> str:
    """« Factures Fournisseurs (AP) » -> « FACTURES_FOURNISSEURS_AP »."""
    sans_accent = unicodedata.normalize("NFKD", str(texte or "")).encode("ascii", "ignore").decode()
    return re.sub(r"_+", "_", re.sub(r"[^A-Za-z0-9]+", "_", sans_accent)).strip("_").upper()


def code_flux(application: str, sens: str, objet: str) -> str:
    return f"{slug(application)}_{'IN' if sens == 'entrant' else 'OUT'}_{slug(objet)}"


def libelle(fiche) -> str:
    app, objet = str(fiche.get("application") or ""), str(fiche.get("objet") or "")
    fleche = "→ Oracle" if fiche.get("sens") == "entrant" else "Oracle →"
    return f"{app} {fleche} {objet}".strip()


def type_depuis_objet(objet: str) -> str:
    o = slug(objet).lower()
    if "facture" in o and "fournisseur" in o:
        return "FOURNISSEURS"
    if "facture" in o and "client" in o:
        return "CLIENTS"
    if "ecriture" in o:
        return "GL"
    return "AUTRE"


# ------------------------------------------------------------------ motif

def reconnait(motif: str | None, nom: str | None) -> bool:
    """Le motif reconnaît-il ce nom de fichier ? Joker `*` / `?` par défaut, expression régulière si le
    motif commence par `^`. La casse est ignorée ; un motif invalide ne reconnaît rien."""
    if not motif or not nom:
        return False
    motif, nom = str(motif).strip(), str(nom).strip()
    if not motif:
        return False
    if motif.startswith("^"):
        try:
            return re.search(motif, nom, re.I) is not None
        except re.error:
            return False
    return fnmatch.fnmatch(nom.lower(), motif.lower())


def flux_du_fichier(con: sqlite3.Connection, nom: str) -> dict | None:
    """Fiche du flux qui reconnaît ce fichier transmis ; le motif le plus précis (le plus long) l'emporte."""
    candidats = [r for r in flux(con).to_dict("records") if reconnait(r.get("motif"), nom)]
    return max(candidats, key=lambda r: len(str(r.get("motif") or "")), default=None)


def proposer_fiche(nom: str) -> dict:
    """Fiche pré-remplie à partir d'un nom de fichier transmis (donc un flux entrant) : application =
    premier segment, motif = début du nom jusqu'au premier segment horodaté, objet déduit du nom."""
    base = Path(str(nom or "")).stem
    morceaux = re.split(r"([._])", base)
    garde, coupe = [], False
    for m in morceaux:
        if m in ("_", "."):
            if not coupe:
                garde.append(m)
            continue
        if len(re.sub(r"\D", "", m)) >= 6 or (m.isdigit() and len(m) >= 4):
            coupe = True
            break
        garde.append(m)
    prefixe = "".join(garde).rstrip("._")
    motif = (prefixe + ("_*" if "_" in prefixe and "." not in prefixe else ".*")) if coupe else base
    mots = [m for m in re.split(r"[._]", prefixe) if m]
    application = mots[0].upper() if mots else base.upper()[:10]
    typ = type_depuis_objet(base.replace("FACTURESFOURNISSEURS", "factures fournisseurs")
                            .replace("FACTURESCLIENTS", "factures clients").replace("ECRITURESGL", "ecritures gl"))
    objet = {"FOURNISSEURS": "Factures fournisseurs (AP)", "CLIENTS": "Factures clients (AR)",
             "GL": "Ecritures GL"}.get(typ, " ".join(mots[1:]) or base)
    return {"code": code_flux(application, "entrant", objet), "application": application, "nom_application": "",
            "domaine": "INCONNU", "sens": "entrant", "objet": objet, "nature": "Nature de flux inconnue",
            "statut": "Actif", "type_flux": typ, "motif": motif, "source_etat": "ctrl_flux",
            "dossier_unix": "", "commentaire": f"proposé depuis {base}"}


# ------------------------------------------------------------------ fiches

def flux(con: sqlite3.Connection) -> pd.DataFrame:
    return pd.read_sql_query(f"SELECT {', '.join(COLS_FLUX)}, cree_le, maj_le FROM flux_referentiel "
                             "ORDER BY sens, application, objet", con)


def enregistrer(con: sqlite3.Connection, fiche: dict) -> str:
    """Crée ou met à jour une fiche (clé : code). Les champs absents ne sont pas écrasés."""
    code = str(fiche.get("code") or "").strip()
    if not code:
        raise ValueError("Le code du flux est obligatoire.")
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with con:
        if con.execute("SELECT 1 FROM flux_referentiel WHERE code = ?", (code,)).fetchone():
            champs = [c for c in COLS_FLUX if c != "code" and c in fiche]
            if champs:
                con.execute(f"UPDATE flux_referentiel SET {', '.join(f'{c}=?' for c in champs)}, maj_le=? "
                            "WHERE code=?", [*(str(fiche[c] if fiche[c] is not None else "").strip() for c in champs),
                                             now, code])
        else:
            con.execute(f"INSERT INTO flux_referentiel({', '.join(COLS_FLUX)}, cree_le, maj_le) "
                        f"VALUES ({', '.join('?' * len(COLS_FLUX))}, ?, ?)",
                        [code, *(str(fiche.get(c) if fiche.get(c) is not None else "").strip() for c in COLS_FLUX[1:]),
                         now, now])
    return code


def supprimer(con: sqlite3.Connection, code: str) -> None:
    with con:
        con.execute("DELETE FROM flux_attributs WHERE code = ?", (code,))
        con.execute("DELETE FROM flux_interlocuteurs WHERE code = ?", (code,))
        con.execute("DELETE FROM flux_referentiel WHERE code = ?", (code,))


# ------------------------------------------------------------------ interlocuteurs et attributs

def interlocuteurs(con: sqlite3.Connection, code: str | None = None, role: str | None = None) -> pd.DataFrame:
    sql, clauses, params = "SELECT id, code, nom, role, mail, telephone, remarque FROM flux_interlocuteurs", [], []
    if code:
        clauses.append("code = ?")
        params.append(code)
    if role:
        clauses.append("LOWER(role) = LOWER(?)")
        params.append(role)
    if clauses:
        sql += " WHERE " + " AND ".join(clauses)
    return pd.read_sql_query(sql + " ORDER BY id", con, params=params)


def remplacer_interlocuteurs(con: sqlite3.Connection, code: str, lignes) -> int:
    """La liste fournie fait foi : les interlocuteurs de ce flux sont remplacés."""
    lignes = [l for l in (lignes or []) if any(str(l.get(c) or "").strip() for c in COLS_INTER)]
    with con:
        con.execute("DELETE FROM flux_interlocuteurs WHERE code = ?", (code,))
        con.executemany("INSERT INTO flux_interlocuteurs(code, nom, role, mail, telephone, remarque) "
                        "VALUES (?,?,?,?,?,?)",
                        [(code, *(str(l.get(c) or "").strip() for c in COLS_INTER)) for l in lignes])
    return len(lignes)


def attributs(con: sqlite3.Connection, code: str) -> dict[str, str]:
    return {r[0]: r[1] for r in con.execute("SELECT cle, valeur FROM flux_attributs WHERE code = ? ORDER BY cle",
                                            (code,))}


def remplacer_attributs(con: sqlite3.Connection, code: str, valeurs: dict) -> int:
    paires = [(str(k).strip(), str(v if v is not None else "").strip()) for k, v in (valeurs or {}).items()
              if str(k or "").strip()]
    with con:
        con.execute("DELETE FROM flux_attributs WHERE code = ?", (code,))
        con.executemany("INSERT INTO flux_attributs(code, cle, valeur) VALUES (?,?,?)",
                        [(code, k, v) for k, v in paires])
    return len(paires)


# ------------------------------------------------------------------ fichiers transmis connus

def fichiers_connus(con: sqlite3.Connection) -> list[str]:
    """Noms de fichiers transmis déjà vus, côté Ctrl Flux comme côté GDR."""
    noms = {r[0] for r in con.execute(
        "SELECT DISTINCT fichier FROM fr_lignes WHERE fichier IS NOT NULL AND TRIM(fichier) <> ''")}
    noms |= {r[0] for r in con.execute(
        "SELECT DISTINCT fichier_source FROM gdr_lignes WHERE fichier_source IS NOT NULL AND TRIM(fichier_source) <> ''")}
    return sorted(noms)


def apercu_motif(con: sqlite3.Connection, motif: str, limite: int = 5) -> tuple[int, list[str]]:
    """Combien de fichiers connus ce motif reconnaît, et quelques exemples : pour juger un motif à la saisie."""
    vus = [n for n in fichiers_connus(con) if reconnait(motif, n)]
    return len(vus), vus[:limite]


def fichiers_sans_flux(con: sqlite3.Connection) -> list[str]:
    """Fichiers transmis qu'aucun motif ne reconnaît : les flux qui restent à déclarer."""
    motifs = [m for m in flux(con)["motif"].tolist() if m]
    return [n for n in fichiers_connus(con) if not any(reconnait(m, n) for m in motifs)]


def decouvrir(con: sqlite3.Connection) -> list[dict]:
    """Fiches proposées pour les fichiers connus qu'aucun flux ne reconnaît, regroupées par motif."""
    groupes: dict[str, dict] = {}
    for nom in fichiers_sans_flux(con):
        p = proposer_fiche(nom)
        g = groupes.setdefault(p["motif"], {**p, "nb_fichiers": 0, "exemple": nom})
        g["nb_fichiers"] += 1
    return sorted(groupes.values(), key=lambda g: -g["nb_fichiers"])


# ------------------------------------------------------------------ catalogue du schéma FIN01

def catalogue_fin01() -> list[dict]:
    """Les flux du schéma « Flux pour FIN01 - ORACLE », tels qu'extraits du PDF (application, objet, sens,
    domaine, nature). Motif et source d'état sont complétés par `charger_catalogue` avec les données du poste."""
    if not CATALOGUE_FIN01.exists():
        return []
    brut = json.loads(CATALOGUE_FIN01.read_text(encoding="utf-8"))
    out = []
    for f in brut:
        out.append({"code": code_flux(f["application"], f["sens"], f["objet"]), "application": f["application"],
                    "nom_application": f.get("nom", ""), "domaine": f.get("domaine", "INCONNU"),
                    "sens": f["sens"], "objet": f["objet"], "nature": f.get("nature", "Nature de flux inconnue"),
                    "statut": "Actif", "type_flux": type_depuis_objet(f["objet"]), "motif": "",
                    "source_etat": "", "dossier_unix": "", "commentaire": "schéma Flux-FIN01 - ORACLE"})
    return out


# flux dont ODAT Watch suit déjà l'état ailleurs que par les fichiers transmis
SOURCES_CONNUES = {("PEV01", "sortant", "Virement"): "virements",
                   ("PEV01", "sortant", "Prélèvement"): "prelevements",
                   ("EDF01", "entrant", "Releves de compte"): "releves"}


def charger_catalogue(con: sqlite3.Connection) -> int:
    """Ajoute les flux du schéma qui manquent au référentiel (les fiches existantes ne sont pas touchées).
    Pour un flux entrant de factures ou d'écritures, le motif est déduit des fichiers transmis connus."""
    connus = fichiers_connus(con)
    existants = set(flux(con)["code"])
    n = 0
    for f in catalogue_fin01():
        if f["code"] in existants:
            continue
        famille = FAMILLES.get(f["type_flux"])
        if f["sens"] == "entrant" and famille:
            motif = f"{f['application']}_SRC_{famille}_*"
            if any(reconnait(motif, nom) for nom in connus):
                f["motif"], f["source_etat"] = motif, "ctrl_flux"
        f["source_etat"] = SOURCES_CONNUES.get((f["application"], f["sens"], f["objet"]), f["source_etat"])
        enregistrer(con, f)
        n += 1
    return n


# ------------------------------------------------------------------ import / export CSV

COLS_CSV = COLS_FLUX + ["interlocuteurs", "attributs"]


def exporter_csv(con: sqlite3.Connection) -> str:
    """Une ligne par flux ; interlocuteurs et attributs sérialisés en JSON dans leur colonne."""
    sortie = io.StringIO()
    w = csv.DictWriter(sortie, fieldnames=COLS_CSV, delimiter=";", lineterminator="\n")
    w.writeheader()
    for f in flux(con).to_dict("records"):
        w.writerow({**{c: f.get(c, "") for c in COLS_FLUX},
                    "interlocuteurs": json.dumps(interlocuteurs(con, f["code"])[COLS_INTER].to_dict("records"),
                                                 ensure_ascii=False),
                    "attributs": json.dumps(attributs(con, f["code"]), ensure_ascii=False)})
    return sortie.getvalue()


def importer_csv(con: sqlite3.Connection, texte) -> int:
    """Charge un export (même format). Un flux déjà présent est mis à jour. Renvoie le nombre de flux lus."""
    if isinstance(texte, (bytes, bytearray)):
        texte = bytes(texte).decode("utf-8-sig", errors="replace")
    n = 0
    for ligne in csv.DictReader(io.StringIO(str(texte).lstrip("﻿")), delimiter=";"):
        code = str(ligne.get("code") or "").strip()
        if not code:
            continue
        enregistrer(con, {c: ligne.get(c, "") for c in COLS_FLUX})
        try:
            inter, attrs = json.loads(ligne.get("interlocuteurs") or "[]"), json.loads(ligne.get("attributs") or "{}")
        except json.JSONDecodeError:
            inter, attrs = [], {}
        if inter:
            remplacer_interlocuteurs(con, code, inter)
        if attrs:
            remplacer_attributs(con, code, attrs)
        n += 1
    return n
