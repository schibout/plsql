"""GDR : lecture des exports quotidiens de rejets (AP / AR / GL), import SQLite (photos successives,
présent / disparu), agrégation par pièce et rapprochement avec les lignes Folio Rose (fichier transmis + folio)."""
from __future__ import annotations
import configparser
import hashlib
import io
import re
import sqlite3
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
CONFIG = BASE_DIR / "config.ini"
DEFAUTS = {"racine": r"..\ODAT\GDR"}
TOL = 0.005
RE_NOM = re.compile(r"^(\d{2})(\d{2})(\d{4})_Synthese_des_rejets_(AP|AR|GL)_au_\d{2}-\d{2}-\d{4}(?:_(\d+))?\.csv$", re.I)
TYPES = ("AP", "AR", "GL")
COLONNES = ["line_gdr", "id_gdr", "type", "code_rejet", "libelle_rejet", "fichier_source", "folio", "folio_libelle",
            "societe", "region", "numero_piece", "date_piece", "compte", "montant_debit", "montant_credit",
            "description", "date_creation_gdr", "date_arrete", "fichier_src_technique"]


def config_gdr() -> dict:
    """Section [gdr] de config.ini (racine des exports), avec la valeur par défaut ..\\ODAT\\GDR."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    p = Path(cfg.get("gdr", "racine", fallback=DEFAUTS["racine"]).strip())
    return {"racine": p if p.is_absolute() else (BASE_DIR / p).resolve()}


def infos_nom(nom: str) -> tuple[date, str, int] | None:
    """(date de la photo, type, rang) d'après le nom du fichier, None si ce n'est pas un export GDR."""
    m = RE_NOM.match(Path(nom).name)
    if not m:
        return None
    jj, mm, aaaa, typ, rang = m.groups()
    return date(int(aaaa), int(mm), int(jj)), typ.upper(), int(rang or 1)


@dataclass
class Fichier:
    nom: str
    file_hash: str
    type: str
    date_photo: date
    rang: int
    lignes: pd.DataFrame
    id: int | None = None
    lignes_ignorees: int = 0


def _num(v) -> float:
    try:
        return float(str(v).replace(",", ".").replace(" ", "")) if str(v).strip() else 0.0
    except ValueError:
        return 0.0


def _cle(s: str) -> str:
    return re.sub(r"[^a-z]", "", s.lower().replace("é", "e").replace("è", "e").replace("ê", "e"))


def _col(df: pd.DataFrame, *noms: str) -> pd.Series:
    """Première colonne présente parmi les noms (comparaison sans accents : ils sont parfois abîmés)."""
    index = {_cle(c): c for c in df.columns}
    for n in noms:
        if _cle(n) in index:
            return df[index[_cle(n)]]
    return pd.Series([""] * len(df), index=df.index, dtype=str)


def lire_fichier(source: Path | str | bytes, nom: str | None = None) -> Fichier:
    """Lit un export GDR (CSV « ; », UTF-8 avec BOM) et le normalise : une ligne par « Line GDR »."""
    if isinstance(source, (bytes, bytearray)):
        octets, nom = bytes(source), nom or "export.csv"
    else:
        octets, nom = Path(source).read_bytes(), nom or Path(source).name
    infos = infos_nom(nom)
    if infos is None:
        raise ValueError(f"{nom} : nom inattendu (attendu JJMMAAAA_Synthese_des_rejets_<AP|AR|GL>_au_JJ-MM-AAAA[_02].csv)")
    date_photo, typ, rang = infos
    texte = octets.decode("utf-8-sig", errors="replace")
    raw = pd.read_csv(io.StringIO(texte), sep=";", dtype=str, keep_default_na=False).fillna("")
    raw.columns = [c.strip() for c in raw.columns]
    n = len(raw)
    df = pd.DataFrame(index=raw.index)
    df["line_gdr"] = _col(raw, "Line GDR").str.strip()
    df["id_gdr"] = _col(raw, "ID GDR").str.strip()
    df["type"] = typ
    # lignes de continuation d'une pièce : code et libellé de rejet vides -> ceux de la ligne précédente
    df["code_rejet"] = _col(raw, "Code Rejet").str.strip().replace("", pd.NA).ffill().fillna("")
    df["libelle_rejet"] = _col(raw, "Libellé rejet").str.strip().replace("", pd.NA).ffill().fillna("")
    df["fichier_source"] = _col(raw, "Fichier Source").str.strip()
    df["folio_libelle"] = _col(raw, "Folio").str.strip()
    df["folio"] = df["folio_libelle"].str[:3].str.upper()
    df["societe"] = _col(raw, "Société").str.strip()
    df["region"] = _col(raw, "Région").str.strip()
    df["numero_piece"] = _col(raw, "Numéro pièce").str.strip()
    df["date_piece"] = _col(raw, "Date pièce comptable").str.strip()
    df["compte"] = _col(raw, "Compte local").str.strip()
    if typ == "GL":
        df["montant_debit"] = _col(raw, "Montant débit").map(_num)
        df["montant_credit"] = _col(raw, "Montant crédit").map(_num)
    elif typ == "AR":
        m = _col(raw, "Montant Ligne").map(_num)
        credit = _col(raw, "Sens (Dbt/Cdt)").str.strip().str.upper().str[:1] == "C"
        df["montant_debit"] = m.where(~credit, 0.0)
        df["montant_credit"] = m.where(credit, 0.0)
    else:  # AP : toutes les lignes au débit, la ligne sur le compte 401 porte le total de la facture
        df["montant_debit"] = _col(raw, "Montant Ligne").map(_num)
        df["montant_credit"] = 0.0
    df["description"] = _col(raw, "Description ligne").str.strip()
    df["date_creation_gdr"] = _col(raw, "Date création GDR").str.strip()
    df["date_arrete"] = _col(raw, "Date Arrêté comptable").str.strip()
    df["fichier_src_technique"] = _col(raw, "Fichier SRC technique").str.strip()
    df = df[df["line_gdr"] != ""].drop_duplicates("line_gdr", keep="last").reset_index(drop=True)
    return Fichier(nom, hashlib.sha1(octets).hexdigest(), typ, date_photo, rang, df[COLONNES],
                   lignes_ignorees=n - len(df))


# ------------------------------------------------------------------ import

def importer(f: Fichier, con: sqlite3.Connection) -> int | None:
    """Enregistre la photo et met à jour l'état courant de son type. Photo la plus récente du type : ligne connue
    mise à jour, ligne inédite créée, lignes absentes marquées disparues. Photo plus ancienne (rattrapage) :
    les lignes connues ne bougent pas, les inédites entrent déjà disparues (à la date de la photo suivante).
    None si le fichier (même hash) est déjà en base."""
    if con.execute("SELECT 1 FROM gdr_fichiers WHERE file_hash = ?", (f.file_hash,)).fetchone():
        return None
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cle = (f.date_photo.isoformat(), f.rang)
    derniere = con.execute("SELECT date_photo, rang FROM gdr_fichiers WHERE type = ? "
                           "ORDER BY date_photo DESC, rang DESC LIMIT 1", (f.type,)).fetchone()
    plus_recente = derniere is None or cle >= (derniere[0], derniere[1])
    cols = COLONNES
    with con:
        fid = con.execute(
            "INSERT INTO gdr_fichiers(nom_fichier, file_hash, type, date_photo, rang, importe_le, nb_lignes) "
            "VALUES (?,?,?,?,?,?,?)",
            (f.nom, f.file_hash, f.type, f.date_photo.isoformat(), f.rang, now, len(f.lignes))).lastrowid
        valeurs = [(*[row[c] for c in cols], fid, fid) for row in f.lignes.to_dict("records")]
        if plus_recente:
            maj = ", ".join(f"{c}=excluded.{c}" for c in cols if c != "line_gdr")
            con.executemany(
                f"INSERT INTO gdr_lignes({','.join(cols)}, premier_fichier_id, dernier_fichier_id, present, disparu_le) "
                f"VALUES ({','.join('?' * len(cols))},?,?,1,NULL) "
                f"ON CONFLICT(line_gdr) DO UPDATE SET {maj}, dernier_fichier_id=excluded.dernier_fichier_id, "
                "present=1, disparu_le=NULL", valeurs)
            con.execute("UPDATE gdr_lignes SET present = 0, disparu_le = ? "
                        "WHERE type = ? AND present = 1 AND dernier_fichier_id <> ?",
                        (f.date_photo.isoformat(), f.type, fid))
        else:
            suivante = con.execute("SELECT date_photo FROM gdr_fichiers WHERE type = ? AND (date_photo > ? OR "
                                   "(date_photo = ? AND rang > ?)) ORDER BY date_photo, rang LIMIT 1",
                                   (f.type, cle[0], cle[0], cle[1])).fetchone()[0]
            con.executemany(
                f"INSERT INTO gdr_lignes({','.join(cols)}, premier_fichier_id, dernier_fichier_id, present, disparu_le) "
                f"VALUES ({','.join('?' * len(cols))},?,?,0,?) ON CONFLICT(line_gdr) DO NOTHING",
                [(*v, suivante) for v in valeurs])
    f.id = fid
    return fid


def fichiers_du_dossier(racine: Path) -> list[Path]:
    """Exports GDR du dossier, dans l'ordre d'import : date de photo, rang, type."""
    out = [(infos_nom(p.name), p) for p in Path(racine).glob("*.csv")]
    return [p for i, p in sorted(((i, p) for i, p in out if i), key=lambda x: (x[0][0], x[0][2], x[0][1]))]


def importer_dossier(racine: Path, con: sqlite3.Connection) -> list[str]:
    """Importe les fichiers du dossier dont le nom est inconnu ; un message par fichier importé ou en erreur."""
    if not Path(racine).is_dir():
        return [f"Dossier GDR introuvable : {racine}"]
    connus = {r[0] for r in con.execute("SELECT nom_fichier FROM gdr_fichiers")}
    msgs = []
    for p in fichiers_du_dossier(racine):
        if p.name in connus:
            continue
        try:
            f = lire_fichier(p)
            fid = importer(f, con)
            msgs.append(f"{p.name} : {'déjà importé (même contenu)' if fid is None else f'{len(f.lignes)} lignes'}")
        except (ValueError, OSError) as e:
            msgs.append(f"{p.name} : ERREUR {e}")
    return msgs


def fichiers(con: sqlite3.Connection) -> pd.DataFrame:
    return pd.read_sql_query("SELECT id, nom_fichier, type, date_photo, rang, importe_le, nb_lignes FROM gdr_fichiers "
                             "ORDER BY date_photo DESC, rang DESC, type", con)


def rejets(con: sqlite3.Connection, ouverts: bool = True) -> pd.DataFrame:
    """Lignes GDR de l'état courant ; ouverts=False inclut les lignes disparues (rejets traités)."""
    df = pd.read_sql_query(f"""
        SELECT l.*, p.date_photo AS vu_depuis, d.date_photo AS vu_le
        FROM gdr_lignes l
        LEFT JOIN gdr_fichiers p ON p.id = l.premier_fichier_id
        LEFT JOIN gdr_fichiers d ON d.id = l.dernier_fichier_id
        {"WHERE l.present = 1" if ouverts else ""}
        ORDER BY d.date_photo DESC, l.type, l.fichier_source, l.folio, l.id_gdr, l.line_gdr""", con)
    df["present"] = df["present"].astype(bool)
    return df


# ------------------------------------------------------------------ pièces et rapprochement Folio Rose

def montant_piece(lignes: pd.DataFrame) -> float:
    """Montant d'une pièce : AP = ligne sur le compte 401 (total de la facture) ; sinon somme des débits,
    à défaut des crédits."""
    if lignes["type"].iloc[0] == "AP":
        tot = lignes[lignes["compte"].astype(str).str.startswith("401")]
        if not tot.empty:
            return round(float(tot["montant_debit"].sum()), 2)
    d, c = float(lignes["montant_debit"].sum()), float(lignes["montant_credit"].sum())
    return round(d if abs(d) >= TOL else c, 2)


COLS_PIECES = ["id_gdr", "type", "fichier_source", "folio", "numero_piece", "code_rejet", "libelle_rejet",
               "montant", "nb_lignes", "vu_depuis"]


def pieces(df: pd.DataFrame) -> pd.DataFrame:
    """Une ligne par pièce (ID GDR) : fichier, folio, numéro, code rejet, montant, nombre de lignes."""
    if df.empty:
        return pd.DataFrame(columns=COLS_PIECES)
    rows = []
    for (idg, typ, fic, fol), g in df.groupby(["id_gdr", "type", "fichier_source", "folio"], sort=False):
        rows.append({"id_gdr": idg, "type": typ, "fichier_source": fic, "folio": fol,
                     "numero_piece": g["numero_piece"].iloc[0], "code_rejet": g["code_rejet"].iloc[0],
                     "libelle_rejet": g["libelle_rejet"].iloc[0], "montant": montant_piece(g), "nb_lignes": len(g),
                     "vu_depuis": g["vu_depuis"].min() if "vu_depuis" in g else None})
    return pd.DataFrame(rows, columns=COLS_PIECES)


def _egal(a, b) -> bool:
    if a is None or b is None:
        return False
    try:
        return not pd.isna(a) and not pd.isna(b) and abs(float(a) - float(b)) < 0.01
    except (TypeError, ValueError):
        return False


def _mt(v) -> str:
    return f"{float(v):,.2f}".replace(",", " ").replace(".", ",") + " €"


def verdict(ligne, pcs: pd.DataFrame) -> tuple[str, str]:
    """(niveau, texte) pour une ligne Folio Rose et les pièces GDR ouvertes du même fichier + folio.
    niveau : '' (rien), 'total' (le montant rejeté explique un montant de la ligne : écart débit, montant de
    la pièce, pièce − OA, pièce − interface), 'piece' (une pièce seule l'explique), 'probable' (fichier + folio
    présents dans la GDR, montants différents)."""
    if pcs.empty:
        return "", ""
    n, total = len(pcs), round(float(pcs["montant"].sum()), 2)
    amont = ligne.get("amont_debit")
    candidats = [("l'écart débit", ligne.get("ecart_debit")), ("le montant de la pièce (rejet total)", amont)]
    for lib, col in (("pièce − montant OA", "montant_oracle"), ("pièce − montant interface", "montant_interface")):
        v = ligne.get(col)
        if _egal(amont, amont) and _egal(v, v):
            candidats.append((lib, float(amont) - float(v)))
    s = "s" if n > 1 else ""
    tete = f"{n} pièce{s} dans la GDR · {_mt(total)}"
    for lib, v in candidats:
        if _egal(total, v):
            return "total", f"{tete} = {lib}"
    for _, p in pcs.iterrows():
        for lib, v in candidats:
            if _egal(p["montant"], v):
                return "piece", (f"pièce {p['numero_piece']} dans la GDR ({_mt(p['montant'])} = {lib}) · "
                                 f"{n} rejetée{s} au total")
    ecart = ligne.get("ecart_debit")
    return "probable", f"probable : {tete}" + (f" (écart débit {_mt(ecart)})" if _egal(ecart, ecart) else "")


def rapprocher_folio_rose(lignes_fr: pd.DataFrame, con: sqlite3.Connection) -> tuple[pd.DataFrame, dict[str, pd.DataFrame]]:
    """Ajoute aux lignes Folio Rose les colonnes gdr_niveau et gdr (texte du verdict) et retourne, par empreinte,
    les pièces GDR ouvertes du même fichier transmis + folio (3 lettres)."""
    out = lignes_fr.copy()
    out["gdr_niveau"], out["gdr"] = "", ""
    detail: dict[str, pd.DataFrame] = {}
    if out.empty:
        return out, detail
    pcs = pieces(rejets(con))
    if pcs.empty:
        return out, detail
    par_cle = {k: g for k, g in pcs.groupby(["fichier_source", "folio"])}
    for i, r in out.iterrows():
        g = par_cle.get((str(r.get("fichier") or "").strip(), str(r.get("folio") or "").strip().upper()))
        if g is None:
            continue
        niveau, texte = verdict(r, g)
        out.at[i, "gdr_niveau"], out.at[i, "gdr"] = niveau, texte
        detail[r["empreinte"]] = g.reset_index(drop=True)
    return out, detail
