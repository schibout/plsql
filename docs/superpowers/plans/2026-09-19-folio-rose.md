# Onglet « 🌹 Folio Rose » — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un onglet ODAT Watch qui importe les exports Folio Rose, contrôle les montants dans Oracle comme `Verifier_Factures.ps1`, et permet de rapprocher des lignes (somme des écarts débit = 0) avec mémorisation des rapprochements et rapport HTML.

**Architecture:** `folio_rose.py` (lecture CSV, import SQLite, statuts, groupes compensés, rapprochements, contrôle Oracle), `rapport_folio_rose.py` (HTML pur), `ui_folio_rose.py` (onglet Streamlit), tables `fr_*` dans `db.py`, un onglet dans `app.py`. Spec : `docs/superpowers/specs/2026-09-19-folio-rose-design.md`.

**Tech Stack:** Python 3.13 (venv `/c/tmp/odatenv/Scripts/python.exe`), pandas, Streamlit 1.64 (`st.dataframe` avec `on_select`), oracledb, sqlite3, pytest + `streamlit.testing.v1.AppTest`.

**Conventions :** commandes depuis `odat_watch/` ; tests avec `PYTHONIOENCODING=utf-8 python -m pytest tests -q` (46 tests au départ) ; commits en français terminés par `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` ; libellés et commentaires en français ; `use_container_width=True` comme le reste de l'app. Les exports réels de test sont dans `../ControleFolioRose/sauvegarde/*.csv` (23 fichiers) et `../ControleFolioRose/ExportCSV-03-08-2026.csv`.

---

## Carte des fichiers

| Fichier | Action | Responsabilité |
|---|---|---|
| `odat_watch/db.py` | modifier | tables `fr_exports`, `fr_lignes`, `fr_oracle`, `fr_rapprochements`, `fr_rapprochement_lignes` |
| `odat_watch/folio_rose.py` | créer | lecture, import, `lignes_export`, groupes, rapprochements, `controler_oracle` |
| `odat_watch/rapport_folio_rose.py` | créer | `construire`, `ecrire` |
| `odat_watch/ui_folio_rose.py` | créer | `render(kpi)` |
| `odat_watch/app.py` | modifier | onglet « 🌹 Folio Rose » après « ☀️ Matin » |
| `odat_watch/README.md` | modifier | documentation |
| `odat_watch/tests/test_folio_rose_lecture.py` | créer | lecture des exports réels, empreintes |
| `odat_watch/tests/test_folio_rose_base.py` | créer | import, statuts, groupes, rapprochements, Oracle simulé |
| `odat_watch/tests/test_rapport_folio_rose.py` | créer | HTML |
| `odat_watch/tests/test_ui_folio_rose.py` | créer | AppTest |

---

### Task 1 : tables `fr_*`

**Files:** Modify `odat_watch/db.py` ; Test `odat_watch/tests/test_folio_rose_base.py`

- [ ] **Step 1 : test**

Fichier `odat_watch/tests/test_folio_rose_base.py` :

```python
"""Folio Rose : import SQLite, statuts, groupes compensés, rapprochements, contrôle Oracle simulé."""
from datetime import date, datetime
from pathlib import Path

import pandas as pd
import pytest

import db
import folio_rose as fr

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def test_tables_folio_rose(tmp_path):
    con = db.connect(tmp_path / "t.db")
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"fr_exports", "fr_lignes", "fr_oracle", "fr_rapprochements", "fr_rapprochement_lignes"} <= tables
    cols = [r[1] for r in con.execute("PRAGMA table_info(fr_lignes)")]
    for c in ("empreinte", "folio", "type", "fichier_base", "ecart_debit", "age_j"):
        assert c in cols
    con.close()
```

- [ ] **Step 2 : lancer** → FAIL (`ModuleNotFoundError: folio_rose` — normal, le test suivant le corrigera ; pour isoler cette tâche, lancer `pytest tests/test_folio_rose_base.py -q -k tables` après avoir créé un `folio_rose.py` vide contenant seulement la docstring `"""Folio Rose (en construction)."""`).

- [ ] **Step 3 : schéma** — dans `odat_watch/db.py`, après le bloc `parametres`, avant la `"""` fermante de `SCHEMA` :

```sql

-- Folio Rose : exports, lignes, contrôle Oracle, rapprochements
CREATE TABLE IF NOT EXISTS fr_exports (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    nom_fichier            TEXT NOT NULL,
    file_hash              TEXT NOT NULL UNIQUE,
    date_export            TEXT NOT NULL,          -- AAAA-MM-JJ (nom du fichier, sinon date d'import)
    periode_debut          TEXT, periode_fin TEXT, -- JJ/MM/AAAA tels que lus
    importe_le             TEXT NOT NULL,
    nb_lignes              INTEGER NOT NULL,
    encodage               TEXT,
    nb_montants_illisibles INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS fr_lignes (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    export_id     INTEGER NOT NULL REFERENCES fr_exports(id) ON DELETE CASCADE,
    num           INTEGER NOT NULL,                -- rang dans le fichier
    empreinte     TEXT NOT NULL,                   -- identité stable d'une ligne entre exports
    folio         TEXT, date TEXT, type TEXT, fichier TEXT, fichier_base TEXT,
    amont_nb      REAL, amont_debit REAL, amont_credit REAL,
    si_nb         REAL, si_debit REAL, si_credit REAL,
    ecart_nb      REAL, ecart_debit REAL, ecart_credit REAL,
    commentaire   TEXT, piece_jointe TEXT, lettrage TEXT,
    age_j         INTEGER
);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_export ON fr_lignes(export_id);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_empreinte ON fr_lignes(empreinte);
CREATE TABLE IF NOT EXISTS fr_oracle (
    export_id         INTEGER NOT NULL REFERENCES fr_exports(id) ON DELETE CASCADE,
    folio             TEXT NOT NULL, fichier_base TEXT NOT NULL, type TEXT NOT NULL,
    nb_oracle         REAL, montant_oracle REAL, nb_interface REAL, montant_interface REAL,
    erreur            TEXT, controle_le TEXT NOT NULL,
    PRIMARY KEY (export_id, folio, fichier_base, type)
);
CREATE TABLE IF NOT EXISTS fr_rapprochements (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    cree_le     TEXT NOT NULL,
    commentaire TEXT,
    somme_ecart REAL NOT NULL,
    nb_lignes   INTEGER NOT NULL,
    annule_le   TEXT
);
CREATE TABLE IF NOT EXISTS fr_rapprochement_lignes (
    rapprochement_id INTEGER NOT NULL REFERENCES fr_rapprochements(id) ON DELETE CASCADE,
    empreinte        TEXT NOT NULL,
    PRIMARY KEY (rapprochement_id, empreinte)
);
CREATE INDEX IF NOT EXISTS ix_fr_rl_empreinte ON fr_rapprochement_lignes(empreinte);
```

- [ ] **Step 4 : lancer** `pytest tests/test_folio_rose_base.py -q -k tables` → `1 passed`.
- [ ] **Step 5 : commit** `git add odat_watch/db.py odat_watch/folio_rose.py odat_watch/tests/test_folio_rose_base.py` — « ODAT Watch : tables Folio Rose ».

---

### Task 2 : `folio_rose.py` — lecture d'un export

**Files:** Modify `odat_watch/folio_rose.py` (remplace le fichier vide) ; Test `odat_watch/tests/test_folio_rose_lecture.py`

- [ ] **Step 1 : tests**

```python
"""Lecture des exports Folio Rose (règles de Verifier_Factures.ps1) sur les fichiers réels du dépôt."""
from datetime import date
from pathlib import Path

import pytest

import folio_rose as fr

RACINE = Path(__file__).resolve().parents[2] / "ControleFolioRose"
EXPORTS = sorted(RACINE.glob("sauvegarde/ExportCSV-*.csv")) + sorted(RACINE.glob("ExportCSV-*.csv"))


def _lignes_donnees(chemin: Path) -> int:
    octets = chemin.read_bytes()
    texte = octets.decode(fr.detecter_encodage(octets))
    lignes = texte.splitlines()
    if lignes and lignes[0].lstrip("﻿").startswith("Folio") and "Ecart" in lignes[0].split(";")[1:2]:
        lignes = lignes[2:]
    return sum(1 for l in lignes[1:] if l.replace(";", "").replace(",", "").strip())


@pytest.mark.parametrize("chemin", EXPORTS, ids=lambda p: p.name)
def test_lecture_export_reel(chemin):
    e = fr.lire_export(chemin)
    assert len(e.lignes) == _lignes_donnees(chemin)
    assert set(e.lignes["type"]) <= {"CLIENTS", "FOURNISSEURS", "GL", "AUTRE"}
    assert e.lignes["empreinte"].str.len().eq(40).all()
    assert e.periode_debut and e.periode_fin
    assert e.date_export == date(int(chemin.stem[15:19]), int(chemin.stem[12:14]), int(chemin.stem[9:11]))
    for c in ("folio", "fichier", "fichier_base", "ecart_debit", "amont_debit", "si_debit", "age_j"):
        assert c in e.lignes.columns


def test_regles_unitaires():
    assert fr.normaliser("App Amont Nb piéce ") == "app amont nb piece"
    assert fr.montant("1 234,56") == (1234.56, False)
    assert fr.montant("-") == (0.0, False) and fr.montant("") == (0.0, False)
    assert fr.montant("abc") == (0.0, True)
    assert fr.type_flux("HEF01_SRC_FACTURESCLIENTS_070826-011057_ST_HEF01_6392_001") == "CLIENTS"
    assert fr.type_flux("CEL01_SRC_FACTURESFOURNISSEURS_070826") == "FOURNISSEURS"
    assert fr.type_flux("CDPG_XXX") == "GL" and fr.type_flux("truc") == "AUTRE" and fr.type_flux("") == "AUTRE"
    assert fr.fichier_base("A_B_ST_HEF01_6392_001") == "A_B" and fr.fichier_base("A_B") == "A_B"
    assert fr.date_export_du_nom("ExportCSV-19-08-2026_16h00.csv") == date(2026, 8, 19)
    assert fr.date_export_du_nom("autre.csv") is None


def test_empreinte_stable_entre_deux_exports():
    a = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-18-08-2026.csv").lignes
    b = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-19-08-2026.csv").lignes
    communes = set(a["empreinte"]) & set(b["empreinte"])
    assert len(communes) >= 10          # les exports se recouvrent largement
    la = a.set_index("empreinte").loc[sorted(communes)]
    lb = b.set_index("empreinte").loc[sorted(communes)]
    assert (la["folio"] == lb["folio"]).all() and (la["fichier"] == lb["fichier"]).all()


def test_colonnes_decalees_donnent_autre():
    contenu = ("Folio;Ecart;Début de période;Fin de période\nTous;Oui;01/01/2026;31/01/2026\n"
               "Folio;Date;App Amont Nb piéce;App Amont Débit;App Amont Crédit;SI Finance Nb piece;SI Finance Débit;"
               "SI Finance Crédit;Ecarts Nb Piece;Ecarts Débit;Ecarts Crédit;Commentaire;Nom fichier transmis\n"
               "ABC;10/01/2026;1;10;10;0;0;0;1;10;10;com;ment;aire;FAC02_SRC_FACTURESCLIENTS_X_ST_Y_001\n"
               "ABC;11/01/2026;0;0;0;1;10;10;-1;-10;-10;;FAC02_SRC_FACTURESCLIENTS_X_ST_Y_001\n\n").encode("utf-8-sig")
    e = fr.lire_export(contenu, "ExportCSV-31-01-2026.csv")
    assert len(e.lignes) == 2
    assert list(e.lignes["type"]) == ["AUTRE", "CLIENTS"]      # ';' dans le commentaire → fichier décalé
    assert e.lignes["age_j"].tolist() == [21, 20]


def test_colonnes_obligatoires_absentes():
    with pytest.raises(ValueError, match="Ecarts Débit"):
        fr.lire_export(b"Folio;Date\nA;1\n", "x.csv")
```

- [ ] **Step 2 : lancer** → FAIL (`AttributeError`).

- [ ] **Step 3 : module** — remplacer `odat_watch/folio_rose.py` par :

```python
"""Folio Rose : lecture des exports, import SQLite, statuts, rapprochements et contrôle Oracle.

Portage de ControleFolioRose/Verifier_Factures.ps1 : mêmes règles de lecture (encodage CP850/1252/BOM,
deux lignes de filtres, en-têtes tolérants aux accents, montants à virgule), mêmes trois requêtes Oracle
(CLIENTS / FOURNISSEURS / GL par folio + fichier de base), même statut OK/KO par ligne.
S'y ajoute ce que le .ps1 ne fait pas : les lignes d'un même folio + fichier de base dont la somme des
« Écarts Débit » fait 0 peuvent être rapprochées, et ces rapprochements sont mémorisés (empreinte de ligne
stable d'un export à l'autre).
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
    "commentaire": ["commentaire"], "fichier": ["nom fichier transmis"],
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


def montant(txt: str | None) -> tuple[float, bool]:
    """(valeur, illisible). Vide ou '-' → 0 ; illisible → 0 et True, comme Parse-Montant."""
    v = (txt or "").strip().replace(" ", "").replace(" ", "").replace(",", ".")
    if v in ("", "-"):
        return 0.0, False
    try:
        return float(v), False
    except ValueError:
        return 0.0, True


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
    return date(int(m.group(3)), int(m.group(2)), int(m.group(1))) if m else None


def _date_fr(txt: str | None) -> date | None:
    try:
        return datetime.strptime((txt or "").strip()[:10], "%d/%m/%Y").date()
    except ValueError:
        return None


def empreinte(folio, date_txt, fichier, amont_debit, si_debit) -> str:
    cle = f"{(folio or '').strip()}|{(date_txt or '').strip()}|{(fichier or '').strip()}|{amont_debit:.2f}|{si_debit:.2f}"
    return hashlib.sha1(cle.encode("utf-8")).hexdigest()


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
        e["empreinte"] = empreinte(e["folio"], e["date"], e["fichier"], e["amont_debit"], e["si_debit"])
        e["num"] = num
        enregs.append(e)
    colonnes = ["num", "empreinte", "folio", "date", "type", "fichier", "fichier_base", *MONTANTS,
                "commentaire", "piece_jointe", "lettrage", "age_j"]
    df = pd.DataFrame(enregs, columns=colonnes)
    return Export(nom=nom, date_export=date_export, periode_debut=periode_debut, periode_fin=periode_fin,
                  encodage=enc, file_hash=hashlib.sha1(octets).hexdigest(), lignes=df,
                  nb_montants_illisibles=illisibles)
```

- [ ] **Step 4 : lancer** `pytest tests/test_folio_rose_lecture.py -q` → tous verts (24 paramétrés + 4). Si un export réel fait échouer `test_lecture_export_reel` sur le comptage, examiner le fichier (`sed -n 1,5p`) : le helper `_lignes_donnees` doit compter comme le module ; corriger le helper si c'est lui qui est naïf (ex. ligne composée uniquement de séparateurs), pas le module — sauf bug avéré du module.
- [ ] **Step 5 : commit** — « ODAT Watch : lecture des exports Folio Rose ».

---

### Task 3 : `folio_rose.py` — import, statuts, groupes compensés, rapprochements

**Files:** Modify `odat_watch/folio_rose.py` ; Test `odat_watch/tests/test_folio_rose_base.py`

- [ ] **Step 1 : tests** — ajouter à `test_folio_rose_base.py` :

```python
def _export(tmp_path, nom="ExportCSV-19-08-2026.csv"):
    return fr.lire_export(SAUVEGARDE / nom)


def test_importer_dedoublonne(tmp_path):
    con = db.connect(tmp_path / "t.db")
    e = _export(tmp_path)
    eid = fr.importer(e, con)
    assert eid and e.id == eid
    assert fr.importer(_export(tmp_path), con) is None
    assert con.execute("SELECT COUNT(*) FROM fr_lignes WHERE export_id=?", (eid,)).fetchone()[0] == len(e.lignes)
    ex = fr.exports(con)
    assert list(ex.columns)[:3] == ["id", "nom_fichier", "date_export"] and len(ex) == 1
    con.close()


def test_lignes_export_sans_controle(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes_export(eid, con)
    assert "statut" in l.columns and "rapproche" in l.columns
    assert set(l.loc[l["type"] != "AUTRE", "statut"]) == {"—"}
    assert set(l.loc[l["type"] == "AUTRE", "statut"]) <= {"NON CONTROLE"}
    assert not l["rapproche"].any()
    con.close()


def _df(*lignes):
    """(empreinte, folio, base, ecart, rapproche)"""
    return pd.DataFrame(lignes, columns=["empreinte", "folio", "fichier_base", "ecart_debit", "rapproche"])


def test_groupes_compenses():
    df = _df(("a", "CYC", "F1", 100.0, False), ("b", "CYC", "F1", -60.0, False), ("c", "CYC", "F1", -40.0, False),
             ("d", "CYC", "F2", 10.0, False), ("e", "GCA", "F1", 5.0, False), ("f", "GCA", "F1", -5.0, True))
    g = fr.groupes_compenses(df)
    assert len(g) == 1
    assert g.iloc[0]["folio"] == "CYC" and g.iloc[0]["nb"] == 3 and abs(g.iloc[0]["somme"]) < fr.TOL
    assert sorted(g.iloc[0]["empreintes"]) == ["a", "b", "c"]


def test_rapprocher_et_annuler(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes_export(eid, con)
    g = fr.groupes_compenses(l)
    if g.empty:                                         # on fabrique un groupe si l'export n'en a pas
        con.execute("UPDATE fr_lignes SET ecart_debit = -ecart_debit WHERE id = (SELECT MIN(id) FROM fr_lignes)")
        con.commit()
        l = fr.lignes_export(eid, con); g = fr.groupes_compenses(l)
    empreintes = list(g.iloc[0]["empreintes"]) if not g.empty else []
    if len(empreintes) < 2:
        pytest.skip("aucun groupe compensé exploitable dans cet export")
    rid = fr.rapprocher(empreintes, "test", con)
    l2 = fr.lignes_export(eid, con)
    assert l2.loc[l2["empreinte"].isin(empreintes), "rapproche"].all()
    assert fr.groupes_compenses(l2).apply(lambda r: set(r["empreintes"]) != set(empreintes), axis=1).all() if not fr.groupes_compenses(l2).empty else True
    with pytest.raises(ValueError):                      # déjà rapprochées
        fr.rapprocher(empreintes, "", con)
    r = fr.rapprochements(con)
    assert len(r) == 1 and r.iloc[0]["nb_lignes"] == len(empreintes) and r.iloc[0]["commentaire"] == "test"
    fr.annuler_rapprochement(rid, con)
    assert not fr.lignes_export(eid, con)["rapproche"].any()
    assert fr.rapprochements(con).iloc[0]["annule_le"]
    con.close()


def test_rapprocher_refuse_somme_non_nulle(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes_export(eid, con)
    deux = l[l["ecart_debit"] > 0]["empreinte"].head(2).tolist()
    with pytest.raises(ValueError, match="somme"):
        fr.rapprocher(deux, "", con)
    with pytest.raises(ValueError, match="deux"):
        fr.rapprocher(deux[:1], "", con)
    con.close()


def test_somme_selection():
    df = _df(("a", "X", "F", 1.5, False), ("b", "X", "F", -1.5, False), ("c", "X", "F", 2.0, False))
    assert fr.somme_selection(df, ["a", "b"]) == pytest.approx(0.0)
    assert fr.somme_selection(df, ["a", "c"]) == pytest.approx(3.5)
```

- [ ] **Step 2 : lancer** → FAIL (`AttributeError: importer`).

- [ ] **Step 3 : code** — ajouter à la fin de `folio_rose.py` :

```python


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
```

- [ ] **Step 4 : lancer** `pytest tests -q` → tous verts. Le test `test_rapprocher_et_annuler` peut se terminer en `skip` si l'export du 19/08 n'a aucun groupe compensé même après inversion d'un signe : dans ce cas remplacer l'export par un autre de `sauvegarde/` qui en a (vérifier avec un one-liner `python -c "import folio_rose as fr; ..."`) et le dire dans le rapport.
- [ ] **Step 5 : commit** — « ODAT Watch : import Folio Rose, statuts, groupes compensés et rapprochements ».

---

### Task 4 : `controler_oracle`

**Files:** Modify `odat_watch/folio_rose.py` ; Test `odat_watch/tests/test_folio_rose_base.py`

- [ ] **Step 1 : test** (ajouter) :

```python
class _FauxCurseur:
    def __init__(self):
        self.appels = []
    def execute(self, sql, binds):
        self.appels.append((sql, binds))
        if binds["folio"] == "BOOM":
            raise RuntimeError("ORA-00942: table ou vue inexistante")
        self.derniere = (2, 100.0, 2, 100.0)
    def fetchone(self):
        return self.derniere


class _FauxCon:
    def __init__(self): self.cur = _FauxCurseur()
    def cursor(self): return self.cur
    def __enter__(self): return self
    def __exit__(self, *a): return False


def test_controler_oracle_simule(tmp_path, monkeypatch):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    con.execute("UPDATE fr_lignes SET folio = 'BOOM' WHERE id = (SELECT MIN(id) FROM fr_lignes WHERE type <> 'AUTRE')")
    con.commit()
    faux = _FauxCon()
    monkeypatch.setattr(fr, "_connexion_oracle", lambda: (faux, "APPS."))
    resume = fr.controler_oracle(eid, con)
    couples = con.execute("SELECT COUNT(*), SUM(erreur IS NOT NULL) FROM fr_oracle WHERE export_id=?", (eid,)).fetchone()
    assert couples[0] == len(faux.cur.appels) and couples[1] == 1
    assert "1 en erreur" in resume
    sql, binds = faux.cur.appels[0]
    assert "APPS." in sql and set(binds) == {"folio", "base"} and ":v_" not in sql
    l = fr.lignes_export(eid, con)
    assert set(l.loc[l["type"] != "AUTRE", "statut"]) <= {"OK", "KO", "INDETERMINE"}
    assert (l.loc[l["folio"] == "BOOM", "statut"] == "INDETERMINE").all()
    con.close()
```

- [ ] **Step 2 : lancer** → FAIL.

- [ ] **Step 3 : code** (ajouter à la fin de `folio_rose.py`) :

```python


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


def controler_oracle(export_id: int, con: sqlite3.Connection) -> str:
    """Interroge Oracle pour chaque couple (folio, fichier de base, type) de l'export et mémorise le résultat."""
    couples = con.execute(
        "SELECT DISTINCT folio, fichier_base, type FROM fr_lignes WHERE export_id = ? AND type <> 'AUTRE' "
        "AND folio <> '' AND fichier_base <> '' ORDER BY 1, 2", (export_id,)).fetchall()
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
                resultats.append((export_id, folio, base, typ, float(nb_trx or 0), float(sum_amt or 0),
                                  float(nb_int or 0), float(sum_int or 0), None, now))
            except Exception as e:  # noqa: BLE001 — le message Oracle est l'information utile
                erreurs += 1
                resultats.append((export_id, folio, base, typ, None, None, None, None, str(e).strip(), now))
    con.executemany(
        "INSERT INTO fr_oracle(export_id, folio, fichier_base, type, nb_oracle, montant_oracle, nb_interface, "
        "montant_interface, erreur, controle_le) VALUES (?,?,?,?,?,?,?,?,?,?) "
        "ON CONFLICT(export_id, folio, fichier_base, type) DO UPDATE SET nb_oracle=excluded.nb_oracle, "
        "montant_oracle=excluded.montant_oracle, nb_interface=excluded.nb_interface, "
        "montant_interface=excluded.montant_interface, erreur=excluded.erreur, controle_le=excluded.controle_le",
        resultats)
    con.commit()
    return f"{len(couples)} couple(s) folio/fichier interrogé(s), {erreurs} en erreur."
```

- [ ] **Step 4 : lancer** `pytest tests -q` → verts.
- [ ] **Step 5 : commit** — « ODAT Watch : contrôle Oracle Folio Rose ».

---

### Task 5 : `rapport_folio_rose.py`

**Files:** Create `odat_watch/rapport_folio_rose.py` ; Test `odat_watch/tests/test_rapport_folio_rose.py`

- [ ] **Step 1 : test**

```python
"""Rapport HTML Folio Rose (pur)."""
from pathlib import Path

import pandas as pd

import db
import folio_rose as fr
import rapport_folio_rose as rp

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def _contexte(tmp_path):
    con = db.connect(tmp_path / "t.db")
    e = fr.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    fr.importer(e, con)
    lignes = fr.lignes_export(e.id, con)
    return con, e, lignes


def test_rapport_complet(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    lignes.loc[lignes.index[0], "commentaire"] = "a <b> & c"
    h = rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    assert "Folio Rose — export du 19/08/2026" in h
    assert "a &lt;b&gt; &amp; c" in h and "<b>" not in h.split("</style>")[1]
    for titre in ("Synthèse par type", "Synthèse par folio", "Détail des lignes", "Rapprochements"):
        assert f"<h2>{titre}" in h
    assert h.count("<tr>") >= len(lignes)
    assert 'class="bandeau' in h
    con.close()


def test_bandeau_ko_si_ko(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    lignes["statut"] = "OK"
    assert 'bandeau ok' in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    lignes.loc[lignes.index[0], "statut"] = "KO"
    assert 'bandeau ko' in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    con.close()


def test_ecrire(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    p = rp.ecrire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con), tmp_path)
    assert p.name.startswith("Folio_Rose_20260819_") and p.read_text(encoding="utf-8").startswith("<!DOCTYPE html>")
    con.close()
```

- [ ] **Step 2 : lancer** → FAIL.

- [ ] **Step 3 : module**

```python
"""Rapport HTML Folio Rose : charte des Rapport_Verification_*.html (bandeau, tuiles, synthèses, détail).
Module pur : met en page des DataFrames déjà calculés par folio_rose."""
from __future__ import annotations
import html
from datetime import datetime
from pathlib import Path

import pandas as pd

from folio_rose import TOL, Export
from rapport_matin import STYLE as _STYLE_BASE, DOSSIER_RAPPORTS

STYLE = _STYLE_BASE + """
  td.ko { background: #fbdcdc !important; } td.ok { background: #d7f2e3 !important; }
  tr.rapproche td { color: #8b949e; } .num { text-align: right; font-variant-numeric: tabular-nums; }
"""
JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]


def _t(v) -> str:
    if v is None:
        return ""
    try:
        if pd.isna(v):
            return ""
    except (TypeError, ValueError):
        pass
    return html.escape(str(v))


def _mt(v) -> str:
    try:
        if v is None or pd.isna(v):
            return ""
    except (TypeError, ValueError):
        return _t(v)
    return f"{float(v):,.2f}".replace(",", " ").replace(".", ",")


def _nb(v) -> str:
    try:
        return "" if v is None or pd.isna(v) else f"{int(round(float(v))):,}".replace(",", " ")
    except (TypeError, ValueError):
        return _t(v)


def _tuile(val, lib, cls="") -> str:
    pill = f'<span class="pill {cls}">{_t(lib)}</span>' if cls else f'<div class="tn">{_t(lib)}</div>'
    return f'<div class="tile"><div class="tv">{_t(val)}</div>{pill if cls else ""}{"" if cls else ""}{f"<div class=\\"tn\\">{_t(lib)}</div>" if cls else ""}</div>'


def _synthese(lignes: pd.DataFrame, champ: str, titre: str) -> str:
    if lignes.empty:
        return f"<h2>{titre}</h2><div class='vide'>Aucune ligne.</div>"
    g = lignes.groupby(champ).agg(lignes=("empreinte", "size"),
                                  en_ecart=("ecart_debit", lambda s: int((s.abs() >= TOL).sum())),
                                  montant=("ecart_debit", "sum"),
                                  ko=("statut", lambda s: int((s == "KO").sum())),
                                  rapprochees=("rapproche", "sum")).reset_index()
    rows = "".join(f"<tr><td>{_t(r[champ])}</td><td class='num'>{_nb(r['lignes'])}</td><td class='num'>{_nb(r['en_ecart'])}</td>"
                   f"<td class='num'>{_mt(r['montant'])}</td><td class='num'>{_nb(r['ko'])}</td><td class='num'>{_nb(r['rapprochees'])}</td></tr>"
                   for _, r in g.iterrows())
    return (f"<h2>{titre}</h2><div class='tablewrap'><table><thead><tr><th>{_t(champ.capitalize())}</th><th>Lignes</th>"
            f"<th>En écart</th><th>Montant en écart</th><th>KO Oracle</th><th>Rapprochées</th></tr></thead><tbody>{rows}</tbody></table></div>")


def _detail(lignes: pd.DataFrame) -> str:
    if lignes.empty:
        return "<div class='vide'>Aucune ligne.</div>"
    rows = []
    for _, r in lignes.iterrows():
        cls_statut = {"OK": "ok", "KO": "ko"}.get(r["statut"], "")
        rows.append(
            f"<tr class='{'rapproche' if r['rapproche'] else ''}'><td>{_t(r['folio'])}</td><td>{_t(r['type'])}</td>"
            f"<td>{_t(r['date'])}</td><td class='num'>{_nb(r['age_j'])}</td><td>{_t(r['fichier'])}</td>"
            f"<td class='num'>{_nb(r['ecart_nb'])}</td><td class='num'>{_mt(r['ecart_debit'])}</td>"
            f"<td class='num'>{_nb(r['nb_oracle'])}</td><td class='num'>{_mt(r['montant_oracle'])}</td>"
            f"<td class='num'>{_mt(r['montant_interface'])}</td><td class='num'>{_mt(r['ecart_mt_calcule'])}</td>"
            f"<td>{_t(r['commentaire'])}</td><td class='{cls_statut}'>{_t(r['statut'])}</td>"
            f"<td>{'✔' if r['rapproche'] else ''}</td></tr>")
    head = ("<th>Folio</th><th>Type</th><th>Date</th><th>Âge</th><th>Fichier transmis</th><th>Écart nb</th>"
            "<th>Écart débit</th><th>Nb Oracle</th><th>Montant Oracle</th><th>Montant interface</th>"
            "<th>Écart calculé</th><th>Commentaire</th><th>Statut</th><th>Rapproché</th>")
    return f"<div class='tablewrap'><table><thead><tr>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>"


def _rapprochements(r: pd.DataFrame) -> str:
    if r is None or r.empty:
        return "<div class='vide'>Aucun rapprochement enregistré.</div>"
    rows = "".join(f"<tr><td>{_t(x['cree_le'])}</td><td>{_t(x['folios'])}</td><td class='num'>{_nb(x['nb_lignes'])}</td>"
                   f"<td class='num'>{_mt(x['somme_ecart'])}</td><td>{_t(x['commentaire'])}</td>"
                   f"<td>{'annulé le ' + _t(x['annule_le']) if x['annule_le'] else ''}</td></tr>" for _, x in r.iterrows())
    return (f"<div class='tablewrap'><table><thead><tr><th>Date</th><th>Folios</th><th>Lignes</th><th>Somme</th>"
            f"<th>Commentaire</th><th></th></tr></thead><tbody>{rows}</tbody></table></div>")


def construire(export: Export, lignes: pd.DataFrame, groupes: pd.DataFrame, rapprochements: pd.DataFrame) -> str:
    d = export.date_export
    nb_ko = int((lignes["statut"] == "KO").sum()) if not lignes.empty else 0
    nb_ok = int((lignes["statut"] == "OK").sum()) if not lignes.empty else 0
    nb_ind = int((lignes["statut"] == "INDETERMINE").sum()) if not lignes.empty else 0
    nb_rap = int(lignes["rapproche"].sum()) if not lignes.empty else 0
    nb_grp = 0 if groupes is None else len(groupes)
    total = float(lignes["ecart_debit"].sum()) if not lignes.empty else 0.0
    if nb_ko:
        cls, msg = "ko", f"{nb_ko} ligne(s) KO : le montant Oracle ne correspond pas au montant amont."
    elif nb_ind or nb_grp:
        cls, msg = "warn", f"{nb_ind} ligne(s) indéterminée(s), {nb_grp} groupe(s) compensé(s) en attente de rapprochement."
    else:
        cls, msg = "ok", "Aucun écart Oracle ; aucun groupe compensé en attente."
    tuiles = "".join([
        f'<div class="tile"><div class="tv">{len(lignes)}</div><div class="tn">Lignes</div></div>',
        f'<div class="tile"><div class="tv">{lignes["folio"].nunique() if not lignes.empty else 0}</div><div class="tn">Folios</div></div>',
        f'<div class="tile"><div class="tv">{_mt(total)}</div><div class="tn">Écart débit total</div></div>',
        f'<div class="tile"><div class="tv">{nb_ok}</div><div class="tn">OK Oracle</div></div>',
        f'<div class="tile"><div class="tv">{nb_ko}</div><div class="tn">KO Oracle</div></div>',
        f'<div class="tile"><div class="tv">{nb_rap}</div><div class="tn">Rapprochées</div></div>',
        f'<div class="tile"><div class="tv">{nb_grp}</div><div class="tn">Groupes compensés en attente</div></div>',
    ])
    meta = (f"<span>📅 Export du {d:%d/%m/%Y} ({_t(export.nom)})</span>"
            f"<span>Période : {_t(export.periode_debut)} → {_t(export.periode_fin)}</span>"
            f"<span>Rapport généré le {datetime.now():%d/%m/%Y %H:%M}</span>")
    return f"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"><title>Folio Rose — export du {d:%d/%m/%Y}</title><style>{STYLE}</style></head>
<body><div class="wrap">
<h1>Folio Rose — export du {d:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
<div class="bandeau {cls}"><strong>{_t(msg)}</strong></div>
<div class="tiles">{tuiles}</div>
{_synthese(lignes, "type", "Synthèse par type")}
{_synthese(lignes, "folio", "Synthèse par folio")}
<h2>Détail des lignes</h2>{_detail(lignes)}
<h2>Rapprochements</h2>{_rapprochements(rapprochements)}
<div class="footer">ODAT Watch · Folio Rose · portage de Verifier_Factures.ps1</div>
</div></body></html>
"""


def ecrire(export: Export, lignes, groupes, rapprochements, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Folio_Rose_{export.date_export:%Y%m%d}_{datetime.now():%H%M}.html"
    chemin.write_text(construire(export, lignes, groupes, rapprochements), encoding="utf-8")
    return chemin
```

**Nettoyage attendu** : la fonction `_tuile` ci-dessus est inutile (les tuiles sont écrites en dur dans `construire`) — **ne pas la copier**.

- [ ] **Step 4 : lancer** → verts.
- [ ] **Step 5 : commit** — « ODAT Watch : rapport HTML Folio Rose ».

---

### Task 6 : onglet `ui_folio_rose.py` + `app.py` + AppTest

**Files:** Create `odat_watch/ui_folio_rose.py` ; Modify `odat_watch/app.py` ; Test `odat_watch/tests/test_ui_folio_rose.py`

- [ ] **Step 1 : module UI**

```python
"""Onglet Folio Rose : import des exports, tableau avec sélection et somme des écarts en direct,
rapprochements (manuels et groupes compensés), contrôle Oracle, rapport HTML, historique."""
from __future__ import annotations
import contextlib
from pathlib import Path

import pandas as pd
import streamlit as st

import folio_rose as fr
import rapport_folio_rose as rp
from db import connect
from oracle_refresh import CONFIG

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_SAUVEGARDE = BASE_DIR.parent / "ControleFolioRose"
COLS_AFFICHEES = ["folio", "type", "date", "age_j", "fichier", "amont_nb", "amont_debit", "si_nb", "si_debit",
                  "ecart_nb", "ecart_debit", "nb_oracle", "montant_oracle", "montant_interface", "statut",
                  "rapproche", "commentaire"]
LIBELLES = {"folio": "Folio", "type": "Type", "date": "Date", "age_j": "Âge (j)", "fichier": "Fichier transmis",
            "amont_nb": "Amont nb", "amont_debit": "Amont débit", "si_nb": "SI nb", "si_debit": "SI débit",
            "ecart_nb": "Écart nb", "ecart_debit": "Écart débit", "nb_oracle": "Nb Oracle",
            "montant_oracle": "Montant Oracle", "montant_interface": "Montant interface", "statut": "Statut",
            "rapproche": "Rapproché", "commentaire": "Commentaire"}


def _eur(v) -> str:
    return f"{v:,.2f} €".replace(",", " ").replace(".", ",")


def _importer_fichiers(fichiers) -> list[str]:
    msgs = []
    with contextlib.closing(connect()) as con:
        for f in fichiers:
            nom = f.name if hasattr(f, "name") else Path(f).name
            try:
                e = fr.lire_export(f.getvalue() if hasattr(f, "getvalue") else Path(f), nom)
                eid = fr.importer(e, con)
                msgs.append(f"{nom} : {'déjà importé' if eid is None else f'{len(e.lignes)} lignes importées'}")
            except (ValueError, OSError, UnicodeDecodeError) as ex:
                msgs.append(f"{nom} : ERREUR {ex}")
    return msgs


def _style(df: pd.DataFrame):
    def ligne(r):
        if r["Rapproché"]:
            return ["background-color: #EAF7EE; color: #7A8794"] * len(r)
        if r["Statut"] == "KO":
            return ["background-color: #FDECEC"] * len(r)
        return [""] * len(r)
    return df.style.apply(ligne, axis=1).format({c: "{:,.2f}" for c in ("Amont débit", "SI débit", "Écart débit",
                                                                       "Montant Oracle", "Montant interface")}, na_rep="")


def render(kpi):
    # ---------------------------------------------------------------- import
    with st.expander("📥 Importer des exports Folio Rose", expanded=False):
        fichiers = st.file_uploader("Glisser-déposer un ou plusieurs ExportCSV-*.csv", type=["csv"],
                                    accept_multiple_files=True, key="fr_upload")
        c1, c2 = st.columns(2)
        if c1.button("Importer les fichiers déposés", disabled=not fichiers, use_container_width=True):
            st.session_state["fr_import_log"] = _importer_fichiers(fichiers)
            st.rerun()
        if c2.button("Importer le dossier ControleFolioRose", use_container_width=True,
                     help=str(DOSSIER_SAUVEGARDE)):
            csvs = sorted(DOSSIER_SAUVEGARDE.glob("ExportCSV-*.csv")) + sorted((DOSSIER_SAUVEGARDE / "sauvegarde").glob("ExportCSV-*.csv"))
            st.session_state["fr_import_log"] = _importer_fichiers(csvs)
            st.rerun()
        if st.session_state.get("fr_import_log"):
            st.code("\n".join(st.session_state["fr_import_log"]))

    with contextlib.closing(connect()) as con:
        ex = fr.exports(con)
        if ex.empty:
            st.info("Aucun export importé. Déposez un fichier ExportCSV-*.csv ci-dessus.")
            return
        libelles = {int(r.id): f"{r.date_export} · {r.periode_debut} → {r.periode_fin} · {r.nb_lignes} lignes · {r.nom_fichier}"
                    for r in ex.itertuples()}
        eid = st.selectbox("Export", list(libelles), format_func=libelles.get, key="fr_export")
        export = _export_obj(eid, ex)
        lignes = fr.lignes_export(eid, con)
        groupes = fr.groupes_compenses(lignes)

        # ------------------------------------------------------------ tuiles
        c = st.columns(6)
        kpi(c[0], len(lignes), "lignes", "neutral")
        kpi(c[1], lignes["folio"].nunique(), "folios", "neutral")
        kpi(c[2], _eur(lignes["ecart_debit"].sum()), "écart débit total", "warn" if abs(lignes["ecart_debit"].sum()) >= fr.TOL else "ok")
        kpi(c[3], int(lignes["rapproche"].sum()), "lignes rapprochées", "ok")
        kpi(c[4], len(groupes), "groupes compensés en attente", "warn" if len(groupes) else "ok")
        nb_ko = int((lignes["statut"] == "KO").sum())
        kpi(c[5], nb_ko if "—" not in set(lignes["statut"]) else "—", "KO Oracle", "err" if nb_ko else "neutral")

        # ------------------------------------------------------------ filtres
        f1, f2, f3, f4 = st.columns([1, 1, 2, 1])
        types = f1.multiselect("Type", sorted(lignes["type"].unique()), key="fr_types")
        statuts = f2.multiselect("Statut", sorted(lignes["statut"].unique()), key="fr_statuts")
        folios = f3.multiselect("Folio", sorted(lignes["folio"].unique()), key="fr_folios")
        masquer = f4.checkbox("Masquer les rapprochées", True, key="fr_masquer")
        vue = lignes.copy()
        if types:
            vue = vue[vue["type"].isin(types)]
        if statuts:
            vue = vue[vue["statut"].isin(statuts)]
        if folios:
            vue = vue[vue["folio"].isin(folios)]
        if masquer:
            vue = vue[~vue["rapproche"]]
        vue = vue.reset_index(drop=True)

        # ------------------------------------------------------------ tableau + sélection
        aff = vue[COLS_AFFICHEES].rename(columns=LIBELLES)
        ev = st.dataframe(_style(aff), use_container_width=True, hide_index=True, height=420,
                          on_select="rerun", selection_mode="multi-row", key=f"fr_table_{eid}_{len(vue)}")
        sel_idx = list(ev.selection.rows) if ev and ev.selection else []
        sel = vue.iloc[sel_idx]
        somme = float(sel["ecart_debit"].sum())
        if sel.empty:
            st.caption("Cochez des lignes : la somme de leurs écarts débit s'affiche ici. À 0, elles peuvent être rapprochées.")
        elif len(sel) >= 2 and abs(somme) < fr.TOL:
            st.success(f"✔ {len(sel)} lignes sélectionnées · somme des écarts débit = {_eur(somme)} — compensé, rapprochement possible.")
            com = st.text_input("Commentaire (optionnel)", key="fr_com")
            if st.button("🔗 Rapprocher ces lignes", type="primary"):
                try:
                    fr.rapprocher(sel["empreinte"].tolist(), com, con)
                    st.session_state["fr_msg"] = f"Rapprochement enregistré ({len(sel)} lignes)."
                    st.rerun()
                except ValueError as e:
                    st.error(str(e))
        else:
            st.info(f"{len(sel)} ligne(s) sélectionnée(s) · somme des écarts débit = {_eur(somme)}"
                    + ("" if len(sel) >= 2 else " · sélectionnez au moins deux lignes"))
        if st.session_state.pop("fr_msg", None):
            st.toast(st.session_state.get("fr_msg_txt", "Enregistré."), icon="✅")

        # ------------------------------------------------------------ groupes compensés
        st.markdown(f"#### Groupes compensés en attente ({len(groupes)})")
        if groupes.empty:
            st.caption("Aucun groupe folio + fichier dont la somme des écarts débit fait 0.")
        else:
            if st.button("🔗 Tout rapprocher", key="fr_tous"):
                n = 0
                for _, g in groupes.iterrows():
                    try:
                        fr.rapprocher(list(g["empreintes"]), "groupe compensé (auto)", con); n += 1
                    except ValueError:
                        pass
                st.session_state["fr_msg"] = f"{n} groupe(s) rapproché(s)."
                st.rerun()
            for i, g in groupes.iterrows():
                a, b = st.columns([5, 1])
                a.write(f"**{g['folio']}** · `{g['fichier_base']}` · {g['nb']} lignes · somme {_eur(g['somme'])}")
                if b.button("Rapprocher", key=f"fr_grp_{i}"):
                    try:
                        fr.rapprocher(list(g["empreintes"]), "groupe compensé", con)
                        st.rerun()
                    except ValueError as e:
                        st.error(str(e))

        # ------------------------------------------------------------ Oracle + rapport
        st.markdown("#### Oracle et rapport")
        o1, o2 = st.columns(2)
        if o1.button("🅾 Contrôler dans Oracle", disabled=not CONFIG.exists(), use_container_width=True):
            with st.spinner("Interrogation Oracle…"):
                try:
                    st.session_state["fr_oracle_msg"] = fr.controler_oracle(eid, con)
                    st.rerun()
                except (Exception, SystemExit) as e:  # noqa: BLE001 — même mécanique que l'onglet Matin
                    st.error(f"Contrôle impossible : {e}")
        if st.session_state.get("fr_oracle_msg"):
            o1.caption(st.session_state["fr_oracle_msg"])
        if o2.button("📄 Générer le rapport HTML", use_container_width=True):
            try:
                chemin = rp.ecrire(export, lignes, groupes, fr.rapprochements(con))
                st.session_state["fr_rapport"] = str(chemin)
            except OSError as e:
                st.error(f"Écriture impossible : {e}")
        if st.session_state.get("fr_rapport"):
            p = Path(st.session_state["fr_rapport"])
            if p.exists():
                o2.download_button("⬇ Télécharger " + p.name, p.read_bytes(), file_name=p.name, mime="text/html",
                                   key="fr_dl")

        # ------------------------------------------------------------ historique
        r = fr.rapprochements(con)
        with st.expander(f"Historique des rapprochements ({int((r['annule_le'].isna()).sum()) if not r.empty else 0} actifs)"):
            if r.empty:
                st.caption("Aucun rapprochement.")
            for _, x in r.iterrows():
                a, b = st.columns([5, 1])
                etat = f" · annulé le {x['annule_le']}" if x["annule_le"] else ""
                a.write(f"{x['cree_le']} · {x['folios'] or ''} · {x['nb_lignes']} lignes · {x['commentaire'] or ''}{etat}")
                if not x["annule_le"] and b.button("Annuler", key=f"fr_ann_{x['id']}"):
                    fr.annuler_rapprochement(int(x["id"]), con)
                    st.rerun()


def _export_obj(eid: int, ex: pd.DataFrame) -> fr.Export:
    """Reconstitue un Export (métadonnées) depuis la table, pour le rapport."""
    r = ex[ex["id"] == eid].iloc[0]
    from datetime import date
    return fr.Export(nom=r["nom_fichier"], date_export=date.fromisoformat(r["date_export"]),
                     periode_debut=r["periode_debut"], periode_fin=r["periode_fin"], encodage="", file_hash="",
                     lignes=pd.DataFrame(), id=eid)
```

Corrections à appliquer en copiant : le bloc `if st.session_state.pop("fr_msg", None): st.toast(...)` doit afficher le message lui-même — remplacer par :
```python
        msg = st.session_state.pop("fr_msg", None)
        if msg:
            st.toast(msg, icon="✅")
```
et déplacer `from datetime import date` en tête de fichier.

- [ ] **Step 2 : `app.py`** — remplacer

```python
tab_soir, tab_demain, tab_now, tab_matin, tab_ora, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "☀️ Matin", "🅾 Oracle", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])

with tab_matin:
    import ui_matin
    ui_matin.render(now, kpi)
```
par
```python
tab_soir, tab_demain, tab_now, tab_matin, tab_folio, tab_ora, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "☀️ Matin", "🌹 Folio Rose", "🅾 Oracle", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])

with tab_matin:
    import ui_matin
    ui_matin.render(now, kpi)

with tab_folio:
    import ui_folio_rose
    ui_folio_rose.render(kpi)
```

- [ ] **Step 3 : AppTest** `odat_watch/tests/test_ui_folio_rose.py`

```python
"""Onglet Folio Rose via AppTest : import, somme de la sélection, rapprochement."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import folio_rose as fr
import ui_folio_rose

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_folio_rose

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_folio_rose.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    e = fr.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    fr.importer(e, con)
    con.close()
    monkeypatch.setattr(ui_folio_rose, "connect", lambda: db.connect(base))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, base


def test_affichage(app):
    at, _ = app
    assert any("lignes [neutral]" in m.value for m in at.markdown)
    assert at.dataframe
    assert any("Cochez des lignes" in c.value for c in at.caption)


def test_selection_et_rapprochement(app):
    at, base = app
    con = db.connect(base)
    eid = int(fr.exports(con)["id"].iloc[0])
    lignes = fr.lignes_export(eid, con)
    # deux lignes du même folio dont on force la compensation
    a, b = lignes.index[:2]
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=100 WHERE empreinte=?", (lignes.loc[a, "empreinte"],))
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=-100 WHERE empreinte=?", (lignes.loc[b, "empreinte"],))
    con.commit()
    at.session_state["fr_folios"] = ["ZZZ"]
    at.run()
    assert not at.exception
    assert any("Groupes compensés en attente (1)" in m.value for m in at.markdown)
    # la sélection de lignes dans st.dataframe n'est pas pilotable par AppTest : on rapproche le groupe
    next(b_ for b_ in at.button if b_.label == "Rapprocher").click().run()
    assert not at.exception
    assert fr.lignes_export(eid, con)["rapproche"].sum() == 2
    assert any("Groupes compensés en attente (0)" in m.value for m in at.markdown)
    con.close()


def test_somme_selection_logique():
    # la partie « somme en direct » repose sur folio_rose.somme_selection, testée unitairement ;
    # ici on vérifie seulement que le module expose bien la fonction utilisée par l'onglet
    assert callable(fr.somme_selection)
```

- [ ] **Step 4 : lancer** `PYTHONIOENCODING=utf-8 python -m pytest tests -q` → verts. Si `st.dataframe(..., on_select=...)` n'accepte pas un `Styler` (Streamlit 1.64 l'accepte), passer `aff` brut et garder le style pour plus tard, en le disant.
- [ ] **Step 5 : vérification navigateur** : `streamlit run app.py --server.port 8502 --server.headless true` (si 8502 occupé, 8504), Playwright : onglet « 🌹 Folio Rose » → « Importer le dossier ControleFolioRose » → journal d'import (24 fichiers), sélecteur d'exports, tuiles, tableau ; cocher deux lignes et lire le bandeau de somme ; capture `.playwright-mcp/folio_rose.png` à regarder. Ne pas cliquer « Contrôler dans Oracle » (poste sans Oracle : un clic afficherait juste l'erreur, acceptable). Tuer le serveur.
- [ ] **Step 6 : commit** — « ODAT Watch : onglet Folio Rose (import, sélection/somme, rapprochements, Oracle, rapport) ».

---

### Task 7 : README

- [ ] Ajouter au tableau des fichiers : `folio_rose.py`, `rapport_folio_rose.py`, `ui_folio_rose.py` ; « Folio Rose » dans la ligne `app.py` ; une section « Folio Rose » en fin de README (import, sélection → somme → rapprocher, groupes compensés, Oracle, rapport, `rapports/Folio_Rose_*.html`, tables `fr_*`, tests). Mentionner que `Verifier_Factures.ps1` reste utilisable et que la validation Oracle est à faire sur le poste Dalkia.
- [ ] Commit — « ODAT Watch : documentation Folio Rose ».

---

## Auto-revue

- Spec ↔ tâches : lecture (T2), tables (T1), import/statuts/groupes/rapprochements (T3), Oracle (T4), rapport (T5), onglet complet avec somme en direct, propositions, historique (T6), README (T7). Tests sur les 24 exports réels (T2), AppTest (T6).
- Noms cohérents : `lire_export`, `importer`, `exports`, `lignes_export`, `groupes_compenses`, `somme_selection`, `rapprocher`, `annuler_rapprochement`, `rapprochements`, `controler_oracle`, `_connexion_oracle`, `TOL`, `Export`, `rp.construire/ecrire`.
- Limite connue : AppTest ne sait pas cocher des lignes d'un `st.dataframe` ; la somme en direct est vérifiée par `somme_selection` + contrôle manuel dans le navigateur (T6 step 5).
