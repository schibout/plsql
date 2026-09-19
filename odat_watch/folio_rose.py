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
from dataclasses import dataclass, field
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


def empreinte(folio, date_txt, fichier, amont_debit, si_debit, rang: int = 0) -> str:
    cle = f"{(folio or '').strip()}|{(date_txt or '').strip()}|{(fichier or '').strip()}|{amont_debit:.2f}|{si_debit:.2f}"
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
        e["_cle"] = (f"{(e['folio'] or '').strip()}|{(e['date'] or '').strip()}|{(e['fichier'] or '').strip()}|"
                     f"{e['amont_debit']:.2f}|{e['si_debit']:.2f}")
        e["num"] = num
        enregs.append(e)
    colonnes = ["num", "empreinte", "folio", "date", "type", "fichier", "fichier_base", *MONTANTS,
                "commentaire", "piece_jointe", "lettrage", "age_j"]
    df = pd.DataFrame(enregs, columns=[*colonnes, "_cle"])
    if not df.empty:
        rangs = df.groupby("_cle").cumcount()
        df["empreinte"] = [
            empreinte(f, d, fi, ad, sd, r)
            for f, d, fi, ad, sd, r in zip(df["folio"], df["date"], df["fichier"],
                                           df["amont_debit"], df["si_debit"], rangs)
        ]
    df = df.drop(columns="_cle")[colonnes]
    return Export(nom=nom, date_export=date_export, periode_debut=periode_debut, periode_fin=periode_fin,
                  encodage=enc, file_hash=hashlib.sha1(octets).hexdigest(), lignes=df,
                  nb_montants_illisibles=illisibles)


# ------------------------------------------------------------------ import et lecture SQLite

def importer(export: Export, con: sqlite3.Connection) -> int | None:
    """Insère l'export et ses lignes. None si ce fichier (même hash) est déjà en base."""
    if con.execute("SELECT 1 FROM fr_exports WHERE file_hash = ?", (export.file_hash,)).fetchone():
        return None
    cur = con.execute(
        "INSERT INTO fr_exports(nom_fichier, file_hash, date_export, periode_debut, periode_fin, importe_le, "
        "nb_lignes, encodage, nb_montants_illisibles) VALUES (?,?,?,?,?,?,?,?,?)",
        (export.nom, export.file_hash, export.date_export.isoformat(), export.periode_debut, export.periode_fin,
         datetime.now().strftime("%Y-%m-%d %H:%M:%S"), len(export.lignes), export.encodage,
         export.nb_montants_illisibles))
    eid = cur.lastrowid
    cols = list(export.lignes.columns)
    con.executemany(
        f"INSERT INTO fr_lignes(export_id, {','.join(cols)}) VALUES (?{',?' * len(cols)})",
        [(eid, *[None if pd.isna(v) else (int(v) if isinstance(v, float) and c in ('age_j', 'num') else v)
                 for c, v in zip(cols, row)]) for row in export.lignes.itertuples(index=False)])
    con.commit()
    export.id = eid
    return eid


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


def lignes_export(export_id: int, con: sqlite3.Connection) -> pd.DataFrame:
    """Lignes d'un export + résultat Oracle + rapproche + statut (règle du .ps1)."""
    df = pd.read_sql_query("""
        SELECT l.*, o.nb_oracle, o.montant_oracle, o.nb_interface, o.montant_interface, o.erreur, o.controle_le,
               EXISTS (SELECT 1 FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r ON r.id = rl.rapprochement_id
                       WHERE rl.empreinte = l.empreinte AND r.annule_le IS NULL) AS rapproche
        FROM fr_lignes l
        LEFT JOIN fr_oracle o ON o.export_id = l.export_id AND o.folio = l.folio
                             AND o.fichier_base = l.fichier_base AND o.type = l.type
        WHERE l.export_id = ?
        ORDER BY l.num""", con, params=(export_id,))
    df["rapproche"] = df["rapproche"].astype(bool)
    controle_lance = bool(con.execute("SELECT 1 FROM fr_oracle WHERE export_id = ? LIMIT 1", (export_id,)).fetchone())
    df["ecart_nb_calcule"] = df["amont_nb"] - df["nb_oracle"]
    df["ecart_mt_calcule"] = df["amont_debit"] - df["montant_oracle"]
    df["statut"] = df.apply(_statut, axis=1, controle_lance=controle_lance) if not df.empty else pd.Series(dtype=str)
    return df


# ------------------------------------------------------------------ rapprochements

def groupes_compenses(lignes: pd.DataFrame) -> pd.DataFrame:
    """Par folio + fichier de base, lignes non rapprochées : nb ≥ 2 et somme des écarts débit ≈ 0."""
    libres = lignes[~lignes["rapproche"].astype(bool)]
    if libres.empty:
        return pd.DataFrame(columns=["folio", "fichier_base", "nb", "somme", "empreintes"])
    g = (libres.groupby(["folio", "fichier_base"])
         .agg(nb=("empreinte", "size"), somme=("ecart_debit", "sum"), empreintes=("empreinte", list))
         .reset_index())
    g = g[(g["nb"] >= 2) & (g["somme"].abs() < TOL)].reset_index(drop=True)
    return g


def somme_selection(lignes: pd.DataFrame, empreintes: list[str]) -> float:
    return float(lignes.loc[lignes["empreinte"].isin(empreintes), "ecart_debit"].sum())


def _ecarts_par_empreinte(empreintes: list[str], con: sqlite3.Connection) -> dict[str, float]:
    q = ",".join("?" * len(empreintes))
    rows = con.execute(f"SELECT empreinte, ecart_debit FROM fr_lignes WHERE empreinte IN ({q}) "
                       "GROUP BY empreinte", empreintes).fetchall()
    return {r[0]: float(r[1] or 0) for r in rows}


def rapprocher(empreintes: list[str], commentaire: str, con: sqlite3.Connection) -> int:
    empreintes = list(dict.fromkeys(empreintes))
    if len(empreintes) < 2:
        raise ValueError("Un rapprochement porte sur au moins deux lignes.")
    ecarts = _ecarts_par_empreinte(empreintes, con)
    if len(ecarts) != len(empreintes):
        raise ValueError("Ligne inconnue dans la sélection.")
    somme = sum(ecarts.values())
    if abs(somme) >= TOL:
        raise ValueError(f"La somme des écarts n'est pas nulle ({somme:,.2f}).")
    q = ",".join("?" * len(empreintes))
    deja = con.execute(f"SELECT COUNT(*) FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r "
                       f"ON r.id = rl.rapprochement_id WHERE r.annule_le IS NULL AND rl.empreinte IN ({q})",
                       empreintes).fetchone()[0]
    if deja:
        raise ValueError(f"{deja} ligne(s) déjà rapprochée(s).")
    cur = con.execute("INSERT INTO fr_rapprochements(cree_le, commentaire, somme_ecart, nb_lignes) VALUES (?,?,?,?)",
                      (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), (commentaire or "").strip() or None,
                       round(somme, 2), len(empreintes)))
    rid = cur.lastrowid
    con.executemany("INSERT INTO fr_rapprochement_lignes(rapprochement_id, empreinte) VALUES (?,?)",
                    [(rid, e) for e in empreintes])
    con.commit()
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
