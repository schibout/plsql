"""Folio Rose : lecture des exports, import SQLite, statuts, rapprochements et contrôle Oracle.

Portage de ControleFolioRose/Verifier_Factures.ps1 : mêmes règles de lecture (encodage CP850/1252/BOM,
deux lignes de filtres, en-têtes tolérants aux accents, montants à virgule), mêmes trois requêtes Oracle
(CLIENTS / FOURNISSEURS / GL par folio + fichier de base), même statut OK/KO par ligne.
S'y ajoute ce que le .ps1 ne fait pas : les lignes d'un même folio + fichier de base dont la somme des
« Écarts Débit » fait 0 peuvent être rapprochées, et ces rapprochements sont mémorisés (empreinte de ligne
stable d'un export à l'autre ; deux lignes strictement identiques dans un même export reçoivent un rang
d'occurrence, stable d'un export à l'autre).
"""
from __future__ import annotations
import csv
import hashlib
import io
import re
import sqlite3
import unicodedata
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path

import pandas as pd

TOL = 0.005          # tolérance sur les montants (centime)

# colonne interne -> libellés acceptés (comparés après normaliser())
COLONNES = {
    "folio": ["folio"], "date": ["date"],
    "amont_nb": ["app amont nb piece"], "amont_debit": ["app amont debit"], "amont_credit": ["app amont credit"],
    "si_nb": ["si finance nb piece"], "si_debit": ["si finance debit"], "si_credit": ["si finance credit"],
    "ecart_nb": ["ecarts nb piece", "ecart nb piece"], "ecart_debit": ["ecarts debit", "ecart debit"],
    "ecart_credit": ["ecarts credit", "ecart credit"],
    "commentaire": ["commentaire", "commentaires"], "fichier": ["nom fichier transmis"],
    "piece_jointe": ["presence d'une piece jointe"], "lettrage": ["lettrage"],
}
MONTANTS = ["amont_nb", "amont_debit", "amont_credit", "si_nb", "si_debit", "si_credit",
            "ecart_nb", "ecart_debit", "ecart_credit"]
OBLIGATOIRES = {"folio": "Folio", "fichier": "Nom fichier transmis", "ecart_debit": "Ecarts Débit"}
TYPES = ("CLIENTS", "FOURNISSEURS", "GL", "AUTRE")


# ------------------------------------------------------------------ règles élémentaires

def normaliser(s: str | None) -> str:
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", s).strip().lower()


def detecter_encodage(octets: bytes) -> str:
    """BOM → utf-8-sig ; accents CP850 (0x80-0x9F) majoritaires → cp850 ; sinon cp1252 (règle du .ps1)."""
    if octets[:3] == b"\xef\xbb\xbf":
        return "utf-8-sig"
    n_oem = sum(1 for b in octets if 0x80 <= b <= 0x9F)
    n_ansi = sum(1 for b in octets if b >= 0xC0)
    return "cp850" if n_oem > n_ansi else "cp1252"


_MONTANT_RE = re.compile(r"-?\d+(\.\d+)?")


def montant(txt: str | None) -> tuple[float, bool]:
    """(valeur, illisible). Vide ou '-' → 0 ; illisible → 0 et True, comme Parse-Montant."""
    v = (txt or "").strip().replace(" ", "").replace(" ", "").replace(" ", "").replace(",", ".")
    if v in ("", "-"):
        return 0.0, False
    if not _MONTANT_RE.fullmatch(v):
        return 0.0, True
    return float(v), False


def type_flux(fichier: str | None) -> str:
    f = (fichier or "").upper()
    if not f:
        return "AUTRE"
    if "CLIENTS" in f:
        return "CLIENTS"
    if "FOURNISSEURS" in f:
        return "FOURNISSEURS"
    if "GL" in f or "GRAND LIVRE" in f or "CDPG" in f:
        return "GL"
    return "AUTRE"


def fichier_base(fichier: str | None) -> str:
    f = (fichier or "").strip()
    i = f.find("_ST_")
    return f[:i] if i > 0 else f


def date_export_du_nom(nom: str) -> date | None:
    m = re.search(r"ExportCSV-(\d{2})-(\d{2})-(\d{4})", nom)
    if not m:
        return None
    try:
        return date(int(m.group(3)), int(m.group(2)), int(m.group(1)))
    except ValueError:
        return None


def _date_fr(txt: str | None) -> date | None:
    try:
        return datetime.strptime((txt or "").strip()[:10], "%d/%m/%Y").date()
    except ValueError:
        return None


def empreinte(folio, date_txt, fichier, rang: int = 0) -> str:
    """Clé métier d'une ligne : folio + date + nom de fichier transmis (+ rang d'occurrence si doublon strict).
    Indépendante des montants : un nouvel export met la ligne à jour, il n'en crée pas une autre."""
    cle = f"{(folio or '').strip()}|{(date_txt or '').strip()}|{(fichier or '').strip()}"
    return hashlib.sha1(f"{cle}|{rang}".encode("utf-8")).hexdigest()


# ------------------------------------------------------------------ lecture

@dataclass
class Export:
    nom: str
    date_export: date
    periode_debut: str | None
    periode_fin: str | None
    encodage: str
    file_hash: str
    lignes: pd.DataFrame
    nb_montants_illisibles: int = 0
    id: int | None = None


def _index_colonnes(entete: list[str]) -> dict[str, int]:
    exact = {h.strip(): i for i, h in enumerate(entete)}
    norm = {normaliser(h): i for i, h in enumerate(entete)}
    sans = {normaliser(h).replace(" ", ""): i for i, h in enumerate(entete)}
    out = {}
    for interne, libelles in COLONNES.items():
        for lib in libelles:
            for table, cle in ((exact, lib), (norm, normaliser(lib)), (sans, normaliser(lib).replace(" ", ""))):
                if cle in table:
                    out[interne] = table[cle]
                    break
            if interne in out:
                break
    return out


def lire_export(source: Path | str | bytes, nom: str | None = None, date_import: date | None = None) -> Export:
    """Lit un export Folio Rose (chemin ou octets). Lève ValueError si une colonne indispensable manque."""
    if isinstance(source, (str, Path)):
        chemin = Path(source)
        octets, nom = chemin.read_bytes(), nom or chemin.name
    else:
        octets, nom = source, nom or "export.csv"
    enc = detecter_encodage(octets)
    lignes = octets.decode(enc, errors="replace").splitlines()
    periode_debut = periode_fin = None
    if lignes and re.match(r"^﻿?Folio[;,\t]Ecart", lignes[0]):
        champs = re.split(r"[;,\t]", lignes[1]) if len(lignes) > 1 else []
        periode_debut = champs[2].strip() if len(champs) > 2 else None
        periode_fin = champs[3].strip() if len(champs) > 3 else None
        lignes = lignes[2:]
    if not lignes:
        raise ValueError("Fichier vide.")
    entete_txt = lignes[0].lstrip("﻿")
    sep = "\t" if "\t" in entete_txt else ("," if ("," in entete_txt and ";" not in entete_txt) else ";")
    rows = list(csv.reader(io.StringIO("\n".join([entete_txt] + lignes[1:])), delimiter=sep))
    entete, data = rows[0], rows[1:]
    idx = _index_colonnes(entete)
    manquantes = [lib for cle, lib in OBLIGATOIRES.items() if cle not in idx]
    if manquantes:
        raise ValueError(f"Colonnes indispensables absentes : {', '.join(manquantes)}")

    date_export = date_export_du_nom(nom) or date_import or date.today()
    enregs, illisibles = [], 0
    for num, r in enumerate(data, start=1):
        if not any(c.strip() for c in r):
            continue
        r = r + [""] * (len(entete) - len(r))
        val = {cle: (r[i].strip() if i < len(r) else "") for cle, i in idx.items()}
        e = {c: val.get(c, "") for c in COLONNES}
        for c in MONTANTS:
            e[c], ill = montant(val.get(c))
            illisibles += ill
        if not e["folio"] or not e["fichier"]:
            e["type"] = "AUTRE"
        else:
            e["type"] = type_flux(e["fichier"])
        e["fichier_base"] = fichier_base(e["fichier"])
        d = _date_fr(e["date"])
        e["age_j"] = (date_export - d).days if d else None
        e["_cle"] = f"{(e['folio'] or '').strip()}|{(e['date'] or '').strip()}|{(e['fichier'] or '').strip()}"
        e["num"] = num
        enregs.append(e)
    colonnes = ["num", "empreinte", "rang", "folio", "date", "type", "fichier", "fichier_base", *MONTANTS,
                "commentaire", "piece_jointe", "lettrage", "age_j"]
    df = pd.DataFrame(enregs, columns=[*colonnes, "_cle"])
    if not df.empty:
        df["rang"] = df.groupby("_cle").cumcount()
        df["empreinte"] = [empreinte(f, d, fi, r) for f, d, fi, r in zip(df["folio"], df["date"], df["fichier"], df["rang"])]
    df = df.drop(columns="_cle")[colonnes]
    return Export(nom=nom, date_export=date_export, periode_debut=periode_debut, periode_fin=periode_fin,
                  encodage=enc, file_hash=hashlib.sha1(octets).hexdigest(), lignes=df,
                  nb_montants_illisibles=illisibles)


# ------------------------------------------------------------------ import et lecture SQLite

def _valeur(c, v):
    if pd.isna(v):
        return None
    return int(v) if c in ("age_j", "num", "rang") else v


def importer(export: Export, con: sqlite3.Connection) -> int | None:
    """Enregistre l'export et met à jour l'état courant : une ligne existante (folio + date + fichier) est
    mise à jour, une ligne inédite est créée, une ligne de la période absente de l'export est marquée disparue.
    None si ce fichier (même hash) est déjà en base."""
    if con.execute("SELECT 1 FROM fr_exports WHERE file_hash = ?", (export.file_hash,)).fetchone():
        return None
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cols = [c for c in export.lignes.columns if c != "empreinte"]
    maj = ", ".join(f"{c}=excluded.{c}" for c in cols)
    with con:
        cur = con.execute(
            "INSERT INTO fr_exports(nom_fichier, file_hash, date_export, periode_debut, periode_fin, importe_le, "
            "nb_lignes, encodage, nb_montants_illisibles) VALUES (?,?,?,?,?,?,?,?,?)",
            (export.nom, export.file_hash, export.date_export.isoformat(), export.periode_debut, export.periode_fin,
             now, len(export.lignes), export.encodage, export.nb_montants_illisibles))
        eid = cur.lastrowid
        con.executemany(
            f"INSERT INTO fr_lignes(empreinte, {','.join(cols)}, premier_export_id, dernier_export_id, present, maj_le) "
            f"VALUES (?{',?' * len(cols)},?,?,1,?) "
            f"ON CONFLICT(empreinte) DO UPDATE SET {maj}, dernier_export_id=excluded.dernier_export_id, present=1, "
            "maj_le=excluded.maj_le",
            [(row.empreinte, *[_valeur(c, getattr(row, c)) for c in cols], eid, eid, now)
             for row in export.lignes.itertuples(index=False)])
        # lignes de la période couverte par l'export qui n'y figurent plus : disparues (pas supprimées)
        d0, d1 = _date_fr(export.periode_debut), _date_fr(export.periode_fin)
        if d0 and d1:
            con.execute(
                "UPDATE fr_lignes SET present = 0 WHERE dernier_export_id <> ? AND present = 1 "
                "AND substr(date,7,4)||'-'||substr(date,4,2)||'-'||substr(date,1,2) BETWEEN ? AND ?",
                (eid, d0.isoformat(), d1.isoformat()))
    export.id = eid
    return eid


def dernier_export(con: sqlite3.Connection) -> Export | None:
    """Métadonnées du dernier export importé (le plus récent par date d'export)."""
    ex = exports(con)
    if ex.empty:
        return None
    r = ex.iloc[0]
    return Export(nom=r["nom_fichier"], date_export=date.fromisoformat(r["date_export"]), periode_debut=r["periode_debut"],
                  periode_fin=r["periode_fin"], encodage="", file_hash="", lignes=pd.DataFrame(), id=int(r["id"]))


def exports(con: sqlite3.Connection) -> pd.DataFrame:
    return pd.read_sql_query(
        "SELECT id, nom_fichier, date_export, periode_debut, periode_fin, importe_le, nb_lignes, "
        "nb_montants_illisibles FROM fr_exports ORDER BY date_export DESC, id DESC", con)


def _statut(r, controle_lance: bool) -> str:
    if r["type"] == "AUTRE":
        return "NON CONTROLE"
    if not controle_lance:
        return "—"
    if r["erreur"] or pd.isna(r["nb_oracle"]):
        return "INDETERMINE"
    if abs(r["amont_nb"] - r["nb_oracle"]) < TOL and abs(r["amont_debit"] - r["montant_oracle"]) < TOL:
        return "OK"
    return "KO"


def lignes(con: sqlite3.Connection, disparues: bool = False) -> pd.DataFrame:
    """État courant des lignes + résultat Oracle + rapproche + statut (règle du .ps1).
    disparues=True inclut les lignes absentes du dernier export couvrant leur date."""
    df = pd.read_sql_query(f"""
        SELECT l.*, e.nom_fichier AS dernier_export, e.date_export AS date_dernier_export,
               o.nb_oracle, o.montant_oracle, o.nb_interface, o.montant_interface, o.erreur, o.controle_le,
               EXISTS (SELECT 1 FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r ON r.id = rl.rapprochement_id
                       WHERE rl.empreinte = l.empreinte AND r.annule_le IS NULL) AS rapproche
        FROM fr_lignes l
        LEFT JOIN fr_exports e ON e.id = l.dernier_export_id
        LEFT JOIN fr_oracle o ON o.folio = l.folio AND o.fichier_base = l.fichier_base AND o.type = l.type
        {"" if disparues else "WHERE l.present = 1"}
        ORDER BY substr(l.date,7,4)||substr(l.date,4,2)||substr(l.date,1,2) DESC, l.folio, l.num""", con)
    df["rapproche"] = df["rapproche"].astype(bool)
    df["present"] = df["present"].astype(bool)
    controle_lance = bool(con.execute("SELECT 1 FROM fr_oracle LIMIT 1").fetchone())
    df["ecart_nb_calcule"] = df["amont_nb"] - df["nb_oracle"]
    df["ecart_mt_calcule"] = df["amont_debit"] - df["montant_oracle"]
    df["statut"] = df.apply(_statut, axis=1, controle_lance=controle_lance) if not df.empty else pd.Series(dtype=str)
    return df


# ------------------------------------------------------------------ rapprochements

ECARTS = ("ecart_debit", "ecart_credit", "ecart_nb")   # les trois écarts qui doivent se compenser
TOL_NB = 0.5                                              # nombre de pièces : entier, tolérance d'arrondi


def compensee(sommes: dict) -> bool:
    """Vrai si les trois écarts (débit, crédit, nombre de pièces) sont nuls."""
    return (abs(sommes.get("ecart_debit", 0)) < TOL and abs(sommes.get("ecart_credit", 0)) < TOL
            and abs(sommes.get("ecart_nb", 0)) < TOL_NB)


def groupes_compenses(lignes: pd.DataFrame) -> pd.DataFrame:
    """Par folio + fichier de base, lignes non rapprochées : nb ≥ 2 et les trois écarts ≈ 0."""
    libres = lignes[~lignes["rapproche"].astype(bool)]
    colonnes = ["folio", "fichier_base", "nb", "somme", "somme_credit", "somme_nb", "empreintes"]
    if libres.empty:
        return pd.DataFrame(columns=colonnes)
    libres = libres.assign(**{c: libres[c].fillna(0) for c in ECARTS})
    g = (libres.groupby(["folio", "fichier_base"])
         .agg(nb=("empreinte", "size"), somme=("ecart_debit", "sum"), somme_credit=("ecart_credit", "sum"),
              somme_nb=("ecart_nb", "sum"), empreintes=("empreinte", list))
         .reset_index())
    ok = (g["nb"] >= 2) & (g["somme"].abs() < TOL) & (g["somme_credit"].abs() < TOL) & (g["somme_nb"].abs() < TOL_NB)
    return g[ok].reset_index(drop=True)[colonnes]


def sommes_selection(lignes: pd.DataFrame, empreintes: list[str]) -> dict:
    """Écarts débit / crédit / nombre de pièces cumulés sur les lignes sélectionnées."""
    sel = lignes.loc[lignes["empreinte"].isin(empreintes), list(ECARTS)].fillna(0)
    return {c: float(sel[c].sum()) for c in ECARTS}


def somme_selection(lignes: pd.DataFrame, empreintes: list[str]) -> float:
    return sommes_selection(lignes, empreintes)["ecart_debit"]


def _ecarts_par_empreinte(empreintes: list[str], con: sqlite3.Connection) -> dict[str, dict]:
    q = ",".join("?" * len(empreintes))
    # une empreinte détermine ses montants par construction (folio|date|fichier|amont|si) : n'importe quelle ligne convient
    rows = con.execute(f"SELECT empreinte, MAX(ecart_debit), MAX(ecart_credit), MAX(ecart_nb) FROM fr_lignes "
                       f"WHERE empreinte IN ({q}) GROUP BY empreinte", empreintes).fetchall()
    return {r[0]: {"ecart_debit": float(r[1] or 0), "ecart_credit": float(r[2] or 0), "ecart_nb": float(r[3] or 0)}
            for r in rows}


def rapprocher(empreintes: list[str], commentaire: str, con: sqlite3.Connection) -> int:
    empreintes = list(dict.fromkeys(empreintes))
    if len(empreintes) < 2:
        raise ValueError("Un rapprochement porte sur au moins deux lignes.")
    ecarts = _ecarts_par_empreinte(empreintes, con)
    if len(ecarts) != len(empreintes):
        raise ValueError("Ligne inconnue dans la sélection.")
    sommes = {c: sum(e[c] for e in ecarts.values()) for c in ECARTS}
    somme = sommes["ecart_debit"]
    if not compensee(sommes):
        raise ValueError("La somme des écarts n'est pas nulle (débit {:,.2f}, crédit {:,.2f}, pièces {:g}).".format(
            sommes["ecart_debit"], sommes["ecart_credit"], sommes["ecart_nb"]))
    q = ",".join("?" * len(empreintes))
    deja = con.execute(f"SELECT COUNT(*) FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r "
                       f"ON r.id = rl.rapprochement_id WHERE r.annule_le IS NULL AND rl.empreinte IN ({q})",
                       empreintes).fetchone()[0]
    if deja:
        raise ValueError(f"{deja} ligne(s) déjà rapprochée(s).")
    with con:
        cur = con.execute(
            "INSERT INTO fr_rapprochements(cree_le, commentaire, somme_ecart, nb_lignes) VALUES (?,?,?,?)",
            (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), (commentaire or "").strip() or None,
             round(somme, 2), len(empreintes)))
        rid = cur.lastrowid
        con.executemany("INSERT INTO fr_rapprochement_lignes(rapprochement_id, empreinte) VALUES (?,?)",
                        [(rid, e) for e in empreintes])
    return rid


def annuler_rapprochement(rid: int, con: sqlite3.Connection) -> None:
    con.execute("UPDATE fr_rapprochements SET annule_le = ? WHERE id = ? AND annule_le IS NULL",
                (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), rid))
    con.commit()


def rapprochements(con: sqlite3.Connection) -> pd.DataFrame:
    """Un rapprochement par ligne, avec les folios concernés (les plus récents d'abord)."""
    return pd.read_sql_query("""
        SELECT r.id, r.cree_le, r.nb_lignes, r.somme_ecart, r.commentaire, r.annule_le,
               (SELECT GROUP_CONCAT(DISTINCT l.folio) FROM fr_rapprochement_lignes rl
                JOIN fr_lignes l ON l.empreinte = rl.empreinte WHERE rl.rapprochement_id = r.id) AS folios
        FROM fr_rapprochements r ORDER BY r.id DESC""", con)


# ------------------------------------------------------------------ contrôle Oracle (requêtes du .ps1)

SQL_ORACLE = {
    "CLIENTS": """
SELECT NVL(q1.nb_trx, 0), NVL(q1.sum_amt, 0), NVL(q2.nb_int, 0), NVL(q2.sum_int, 0)
FROM (SELECT COUNT(DISTINCT racta.customer_trx_id) AS nb_trx, SUM(rctl.extended_amount) AS sum_amt
      FROM   {s}ra_customer_trx_all racta, {s}ra_customer_trx_lines_all rctl
      WHERE  racta.customer_trx_id = rctl.customer_trx_id
        AND  rctl.attribute10 LIKE :base || '%'
        AND  rctl.attribute9 = :folio) q1
CROSS JOIN
     (SELECT COUNT(*) AS nb_int,
             SUM(CASE WHEN typmvt = 'SI_AMT_FACTURE' THEN fmt_amount ELSE -1 * fmt_amount END) AS sum_int
      FROM   {s}dka_iarpafac_interface
      WHERE  fic_ident LIKE :base || '%'
        AND  local_account LIKE '411%'
        AND  oa_status != 'A'
        AND  fmt_origin = :folio) q2""",
    "FOURNISSEURS": """
SELECT NVL(q_def.nb_trx, 0), NVL(q_def.sum_amt, 0), NVL(q_int.nb_int, 0), NVL(q_int.sum_int, 0)
FROM (SELECT COUNT(DISTINCT aia.invoice_id) AS nb_trx, SUM(aia.invoice_amount) AS sum_amt
      FROM   {s}ap_invoices_all aia
      WHERE  aia.attribute10 LIKE :base || '%'
        AND  aia.attribute9 = :folio) q_def
CROSS JOIN
     (SELECT COUNT(DISTINCT aii.invoice_id) AS nb_int, SUM(aili.amount) AS sum_int
      FROM   {s}ap_invoices_interface aii
      JOIN   {s}ap_invoice_lines_interface aili ON aii.invoice_id = aili.invoice_id
      WHERE  aii.attribute10 LIKE :base || '%'
        AND  aii.attribute9 = :folio
        AND  NOT EXISTS (SELECT 1 FROM {s}ap_interface_rejections air
                         WHERE air.parent_id = aii.invoice_id
                           AND air.parent_table IN ('AP_INVOICES_INTERFACE', 'AP_INVOICE_LINES_INTERFACE'))) q_int""",
    "GL": """
SELECT NVL(q_def.nb_trx, 0), NVL(q_def.sum_amt, 0), NVL(q_int.nb_int, 0), NVL(q_int.sum_int, 0)
FROM (SELECT COUNT(DISTINCT gjh.je_header_id) AS nb_trx, SUM(gjl.entered_dr) AS sum_amt
      FROM   {s}gl_je_headers gjh
      JOIN   {s}gl_je_lines gjl ON gjh.je_header_id = gjl.je_header_id
      WHERE  gjl.attribute10 LIKE :base || '%'
        AND  gjl.attribute9 = :folio) q_def
CROSS JOIN
     (SELECT COUNT(*) AS nb_int, SUM(entered_dr) AS sum_int
      FROM   {s}gl_interface
      WHERE  attribute10 LIKE :base || '%'
        AND  attribute9 = :folio) q_int""",
}


def _connexion_oracle():
    """(connexion, préfixe de schéma). Isolé pour être remplacé dans les tests."""
    from oracle_refresh import _connect_oracle, _schema, load_config
    cfg = load_config()
    return _connect_oracle(cfg), _schema(cfg)


def controler_oracle(con: sqlite3.Connection) -> str:
    """Interroge Oracle pour chaque couple (folio, fichier de base, type) de l'état courant et mémorise le résultat."""
    couples = con.execute(
        "SELECT DISTINCT folio, fichier_base, type FROM fr_lignes WHERE present = 1 AND type <> 'AUTRE' "
        "AND folio <> '' AND fichier_base <> '' ORDER BY 1, 2").fetchall()
    if not couples:
        return "Aucune ligne contrôlable (types CLIENTS / FOURNISSEURS / GL)."
    ocon, s = _connexion_oracle()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    resultats, erreurs = [], 0
    with ocon:
        cur = ocon.cursor()
        for folio, base, typ in couples:
            try:
                cur.execute(SQL_ORACLE[typ].format(s=s), {"folio": folio.strip(), "base": base.strip()})
                nb_trx, sum_amt, nb_int, sum_int = cur.fetchone() or (None, None, None, None)
                resultats.append((folio, base, typ, float(nb_trx or 0), float(sum_amt or 0),
                                  float(nb_int or 0), float(sum_int or 0), None, now))
            except Exception as e:  # noqa: BLE001 — le message Oracle est l'information utile
                erreurs += 1
                resultats.append((folio, base, typ, None, None, None, None, str(e).strip(), now))
    with con:
        con.executemany(
            "INSERT INTO fr_oracle(folio, fichier_base, type, nb_oracle, montant_oracle, nb_interface, "
            "montant_interface, erreur, controle_le) VALUES (?,?,?,?,?,?,?,?,?) "
            "ON CONFLICT(folio, fichier_base, type) DO UPDATE SET nb_oracle=excluded.nb_oracle, "
            "montant_oracle=excluded.montant_oracle, nb_interface=excluded.nb_interface, "
            "montant_interface=excluded.montant_interface, erreur=excluded.erreur, controle_le=excluded.controle_le",
            resultats)
    return f"{len(couples)} couple(s) folio/fichier interrogé(s), {erreurs} en erreur."
