# Relevés bancaires — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter à ODAT Watch l'onglet « 🏦 Relevés bancaires » qui suit chaque matinée la chaîne PFE → Control-M → EBS
(import `RBAFBIMP` → contrôle `DKA_SRBCTRLRB`), détecte les ruptures (fichier PFE non reçu, rejet `Erreur 025`,
conflit de chaînes 05/06) et génère le plan de reprise.

**Architecture :** un module métier pur `releves.py` (lecture AFB120, scan des dossiers locaux PFE / EBS / logs,
parseurs `.out`, diagnostic Control-M à partir des photos ODAT déjà en base, verdict par flux, continuité, plan de
reprise) stocké dans des tables SQLite `rb_*` ; un onglet Streamlit `ui_releves.py` ; un rapport HTML
`rapport_releves.py` sur la charte de `rapport_matin.py`. Tout est testé sur les fichiers réels de
`ControleReleveBancaire/` (spec : `docs/superpowers/specs/2026-09-20-releves-bancaires-design.md`).

**Tech Stack :** Python 3.12, Streamlit 1.64 (AppTest), pandas, SQLite, pytest. Venv `C:\tmp\odatenv`.
Tests : depuis `odat_watch/`, `PYTHONIOENCODING=utf-8 python -m pytest tests -q`.

**Conventions :** code, commentaires, messages de commit et libellés en français ; commits terminés par
`Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` ; ne jamais commiter `odat_watch/config.ini` ni `odat.db` ;
ne jamais appeler `ingest.ingest_file` sur `ControleReleveBancaire/FichierODAT` (il **déplace** les fichiers dans
`ODAT/archive`) — les tests insèrent les lignes eux-mêmes via `ingest.read_rows`.

Dossier de référence utilisé par tous les tests : `REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"`.

---

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `odat_watch/db.py` | + tables `rb_pfe`, `rb_ebs`, `rb_imports`, `rb_import_releves`, `rb_controles`, `rb_controle_lignes`, `rb_comptes_connus` |
| `odat_watch/config.ini.exemple` | + section `[releves]` |
| `odat_watch/releves.py` (créé) | moteur : `lire_afb120`, `config_releves`, `scanner_pfe/ebs/logs`, `rapprocher_pfe_ebs`, `parse_import_out`, `parse_controle_out`, `chaine_controlm`, `diagnostic_controlm`, `journee`, `chronologie`, `continuite`, `plan_reprise`, `liste_logs_manquants`, `scanner_tout` |
| `odat_watch/rapport_releves.py` (créé) | `construire(bilan)`, `ecrire(bilan)` |
| `odat_watch/ui_releves.py` (créé) | `render(kpi)` |
| `odat_watch/app.py` | onglet « 🏦 Relevés bancaires » après « ☀️ Matin » |
| `odat_watch/tests/test_releves_afb120.py`, `test_releves_scan.py`, `test_releves_logs.py`, `test_releves_controlm.py`, `test_releves_journee.py`, `test_rapport_releves.py`, `test_ui_releves.py` | tests |
| `odat_watch/README.md` | documentation de l'onglet |

---

### Task 1 : schéma SQLite, configuration, squelette du module

**Files:**
- Modify: `odat_watch/db.py` (SCHEMA, après le bloc `calendar_job_mapping`)
- Modify: `odat_watch/config.ini.exemple`
- Create: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_scan.py`

- [ ] **Step 1 : test du schéma et de la config**

```python
# odat_watch/tests/test_releves_scan.py
"""Scan des dossiers PFE / EBS et rapprochement par md5 (fichiers réels de ControleReleveBancaire)."""
from pathlib import Path

import db
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"


def test_tables_rb_creees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"rb_pfe", "rb_ebs", "rb_imports", "rb_import_releves", "rb_controles", "rb_controle_lignes",
            "rb_comptes_connus"} <= tables


def test_config_releves_par_defaut(tmp_path, monkeypatch):
    monkeypatch.setattr(rb, "CONFIG", tmp_path / "absent.ini")
    cfg = rb.config_releves()
    assert cfg["banque_flux_b"] == "30003"
    assert cfg["dossier_pfe"].name == "fluxPFE" and cfg["dossier_ebs"].name == "fichierBanque"
    assert [d.name for d in cfg["dossiers_logs"]] == ["import", "controle"]
    assert "30003/03620/00020137269" in cfg["comptes_connus"]
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run : `cd odat_watch && PYTHONIOENCODING=utf-8 python -m pytest tests/test_releves_scan.py -q`
Attendu : `ModuleNotFoundError: No module named 'releves'`.

- [ ] **Step 3 : tables dans `db.py`**

Ajouter dans `SCHEMA`, juste avant la fermeture `"""` :

```sql
CREATE TABLE IF NOT EXISTS rb_pfe (                -- une exécution Talend (dossier <uuid>) : le fichier livré à EBS
    uuid            TEXT PRIMARY KEY,
    horodatage      TEXT,                          -- YYYY-MM-DD HH:MM:SS (nom du TARGET)
    fichier_source  TEXT, fichier_target TEXT, zip TEXT,
    ls_in_ok        INTEGER, complete INTEGER,
    flux            TEXT,                          -- A | B
    nb_releves      INTEGER, nb_lignes INTEGER, banques TEXT,   -- banques : "30003:213;30004:12"
    date_min        TEXT, date_max TEXT,           -- YYYY-MM-DD
    md5             TEXT,
    ebs_md5_recu    INTEGER DEFAULT 0,             -- 1 si un fichier rb_ebs a le même md5
    vu_le           TEXT
);
CREATE TABLE IF NOT EXISTS rb_ebs (                -- fichier AFB120.txt_<horodatage> reçu par EBS (data/traite)
    nom             TEXT PRIMARY KEY,
    horodatage      TEXT, flux TEXT,
    nb_releves      INTEGER, nb_lignes INTEGER, banques TEXT,
    date_min        TEXT, date_max TEXT, md5 TEXT, vu_le TEXT
);
CREATE TABLE IF NOT EXISTS rb_imports (            -- request RBAFBIMP (logs l<id>.req / o<id>.out)
    request_id      INTEGER PRIMARY KEY,
    debut           TEXT, fin TEXT, fichier TEXT,
    lus             INTEGER, ecrits INTEGER, batch INTEGER,
    releves_charges INTEGER, releves_erreurs INTEGER, lignes_chargees INTEGER, lignes_erreurs INTEGER,
    err001          INTEGER DEFAULT 0, err025 INTEGER DEFAULT 0, autres_erreurs INTEGER DEFAULT 0,
    flux            TEXT, md5_ebs TEXT,
    source_req      TEXT, source_out TEXT
);
CREATE TABLE IF NOT EXISTS rb_import_releves (     -- « Synthèse des relevés » : une ligne par relevé
    request_id  INTEGER NOT NULL, num INTEGER NOT NULL,
    compte      TEXT, banque TEXT, guichet TEXT, numero TEXT, devise TEXT,
    date_debut  TEXT, date_fin TEXT, mouvements INTEGER,
    en_erreur   INTEGER DEFAULT 0, code_erreur TEXT,
    PRIMARY KEY (request_id, num)
);
CREATE TABLE IF NOT EXISTS rb_controles (          -- request DKA_SRBCTRLRB
    request_id      INTEGER PRIMARY KEY,
    executed_at     TEXT, date_reference TEXT,
    nb_anomalies    INTEGER, nb_sg INTEGER, nb_hors_connus INTEGER,
    source_out      TEXT
);
CREATE TABLE IF NOT EXISTS rb_controle_lignes (
    request_id  INTEGER NOT NULL, compte_id TEXT NOT NULL,
    banque TEXT, guichet TEXT, numero TEXT, nom_compte TEXT,
    date_dernier_import TEXT, date_debut_releve TEXT, date_fin_releve TEXT,
    PRIMARY KEY (request_id, compte_id)
);
CREATE TABLE IF NOT EXISTS rb_comptes_connus (     -- anomalies préexistantes à ignorer : 'banque/guichet/compte'
    cle       TEXT PRIMARY KEY,
    motif     TEXT, ajoute_le TEXT
);
```

- [ ] **Step 4 : section `[releves]` dans `config.ini.exemple`** (à la fin du fichier)

```ini
[releves]
; Onglet Releves bancaires. Dossiers locaux alimentes a la main (copie des executions PFE, copy_ebs_logs.sh).
; Un sous-dossier <uuid> par execution Talend (SOURCE / TARGET / TALEND)
dossier_pfe = ..\ControleReleveBancaire\fluxPFE
; Fichiers AFB120.txt_<AAAAMMJJHHMMSS> recus par EBS (data/traite)
dossier_ebs = ..\ControleReleveBancaire\fichierBanque
; Logs l<request_id>.req / o<request_id>.out des imports RBAFBIMP et des controles DKA_SRBCTRLRB (separes par ;)
dossiers_logs = ..\ControleReleveBancaire\import;..\ControleReleveBancaire\controle
; Flux B = fichier ne contenant que cette banque (Societe Generale)
banque_flux_b = 30003
; Comptes en anomalie preexistante, ignores par le verdict (banque/guichet/compte, separes par ;)
comptes_connus = 30003/03620/00020137269;16807/00166/31990892212
```

- [ ] **Step 5 : squelette de `releves.py`**

```python
# odat_watch/releves.py
"""Relevés bancaires : suivi de la chaîne PFE → Control-M → EBS (import RBAFBIMP, contrôle DKA_SRBCTRLRB).

Sources locales uniquement (dossiers copiés à la main) : exécutions PFE (<uuid>/SOURCE,TARGET,TALEND), fichiers
AFB120.txt_* reçus par EBS, logs .req/.out ; photos Control-M déjà en base (ctm_jobs).
"""
from __future__ import annotations

import configparser
import hashlib
import re
import sqlite3
import zipfile
from collections import Counter
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path

import pandas as pd

import logs

BASE_DIR = Path(__file__).resolve().parent
CONFIG = BASE_DIR / "config.ini"
DEFAUTS = {
    "dossier_pfe": r"..\ControleReleveBancaire\fluxPFE",
    "dossier_ebs": r"..\ControleReleveBancaire\fichierBanque",
    "dossiers_logs": r"..\ControleReleveBancaire\import;..\ControleReleveBancaire\controle",
    "banque_flux_b": "30003",
    "comptes_connus": "30003/03620/00020137269;16807/00166/31990892212",
}


def _chemin(txt: str) -> Path:
    p = Path(txt.strip())
    return p if p.is_absolute() else (BASE_DIR / p).resolve()


def config_releves() -> dict:
    """Section [releves] de config.ini, complétée par les valeurs par défaut."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    val = {k: cfg.get("releves", k, fallback=v) for k, v in DEFAUTS.items()}
    return {
        "dossier_pfe": _chemin(val["dossier_pfe"]),
        "dossier_ebs": _chemin(val["dossier_ebs"]),
        "dossiers_logs": [_chemin(d) for d in val["dossiers_logs"].split(";") if d.strip()],
        "banque_flux_b": val["banque_flux_b"].strip(),
        "comptes_connus": [c.strip() for c in val["comptes_connus"].split(";") if c.strip()],
    }


def maintenant() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")
```

- [ ] **Step 6 : lancer, vérifier le succès**

Run : `PYTHONIOENCODING=utf-8 python -m pytest tests/test_releves_scan.py -q` → `2 passed`.

- [ ] **Step 7 : commit**

```bash
git add odat_watch/db.py odat_watch/config.ini.exemple odat_watch/releves.py odat_watch/tests/test_releves_scan.py
git commit -m "ODAT Watch : Relevés bancaires — tables rb_*, section [releves], squelette du module

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2 : lecture d'un fichier AFB120 (`lire_afb120`)

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_afb120.py`

- [ ] **Step 1 : tests**

```python
# odat_watch/tests/test_releves_afb120.py
"""Lecture des fichiers AFB120 (CFONB 120) réels."""
from datetime import date
from pathlib import Path

import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
TARGET_B = REF / "fluxPFE/2b6da61b5e384790970e4ab0b536102e/TARGET/compt_AFB120_RELEVESDECOMPTE_260915-081614.txt"
EBS_A = REF / "fichierBanque/AFB120.txt_20260915074956"


def test_flux_b_213_releves():
    a = rb.lire_afb120(TARGET_B)
    assert (a.nb_releves, a.nb_mouvements, a.nb_lignes) == (213, 2014, 8773)
    assert a.banques == {"30003": 213}
    assert a.flux == "B"
    assert (a.date_min, a.date_max) == (date(2026, 9, 11), date(2026, 9, 14))
    assert len(a.md5) == 32
    premier = a.comptes[0]
    assert premier["compte"] == "30003.01100.00020070505"
    assert (premier["date_debut"], premier["date_fin"]) == (date(2026, 9, 11), date(2026, 9, 14))


def test_flux_a_multi_banques():
    a = rb.lire_afb120(EBS_A)
    assert a.flux == "A" and len(a.banques) > 1 and "30003" not in a.banques
    assert a.nb_releves == sum(a.banques.values())


def test_md5_identique_pfe_et_ebs():
    pfe = rb.lire_afb120(REF / "fluxPFE/9098a5f957a749dd8e1545f9e9b68199/TARGET/compt_AFB120_RELEVESDECOMPTE_260915-074613.txt")
    assert pfe.md5 == rb.lire_afb120(EBS_A).md5


def test_depuis_bytes_et_fichier_vide():
    a = rb.lire_afb120(TARGET_B.read_bytes())
    assert a.nb_releves == 213
    v = rb.lire_afb120(b"")
    assert (v.nb_releves, v.flux, v.date_min) == (0, None, None)
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: module 'releves' has no attribute 'lire_afb120'`.

- [ ] **Step 3 : implémentation** (à la suite de `maintenant()`)

```python
# ---------------------------------------------------------------- AFB120 (CFONB 120)
# Positions (1-based) : code enregistrement 1-2, banque 3-7, guichet 12-16, devise 17-19, compte 22-32, date 35-40 (JJMMAA)
@dataclass
class Afb120:
    nb_releves: int = 0          # enregistrements 01 (ancien solde = ouverture de relevé)
    nb_mouvements: int = 0       # enregistrements 04
    nb_lignes: int = 0
    banques: dict = field(default_factory=dict)      # code banque -> nb de relevés
    comptes: list = field(default_factory=list)      # [{compte, banque, guichet, numero, date_debut, date_fin}]
    date_min: date | None = None
    date_max: date | None = None
    md5: str = ""
    flux: str | None = None      # "B" si une seule banque = banque_flux_b, sinon "A"


def _date_afb(txt: str) -> date | None:
    try:
        return datetime.strptime(txt, "%d%m%y").date()
    except ValueError:
        return None


def lire_afb120(source: Path | bytes, banque_flux_b: str = "30003") -> Afb120:
    raw = source if isinstance(source, bytes) else Path(source).read_bytes()
    a = Afb120(md5=hashlib.md5(raw).hexdigest())
    dates: list[date] = []
    courant: dict | None = None
    for ligne in raw.decode("latin-1").splitlines():
        if len(ligne) < 40:
            continue
        a.nb_lignes += 1
        code = ligne[0:2]
        if code == "01":
            a.nb_releves += 1
            banque, guichet, numero = ligne[2:7], ligne[11:16], ligne[21:32]
            a.banques[banque] = a.banques.get(banque, 0) + 1
            courant = dict(compte=f"{banque}.{guichet}.{numero}", banque=banque, guichet=guichet, numero=numero,
                           date_debut=_date_afb(ligne[34:40]), date_fin=None)
            a.comptes.append(courant)
        elif code == "04":
            a.nb_mouvements += 1
        elif code == "07" and courant is not None:
            courant["date_fin"] = _date_afb(ligne[34:40])
            courant = None
        d = _date_afb(ligne[34:40]) if code in ("01", "07") else None
        if d:
            dates.append(d)
    if dates:
        a.date_min, a.date_max = min(dates), max(dates)
    if a.banques:
        a.flux = "B" if set(a.banques) == {banque_flux_b} else "A"
    return a
```

- [ ] **Step 4 : lancer** → `4 passed`. Si `nb_lignes` diffère de 8773, vérifier avec
`python -c "print(sum(1 for l in open(r'..\ControleReleveBancaire\fluxPFE\2b6da61b5e384790970e4ab0b536102e\TARGET\compt_AFB120_RELEVESDECOMPTE_260915-081614.txt','rb').read().splitlines() if len(l)>=40))"`
et aligner le test sur le fichier (le README annonce 8773).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_afb120.py
git commit -m "ODAT Watch : Relevés bancaires — lecture AFB120 (relevés, mouvements, banques, dates, md5, flux)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3 : scan des exécutions PFE et des fichiers EBS, rapprochement md5

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_scan.py`

- [ ] **Step 1 : tests** (ajouter au fichier existant)

```python
def test_scanner_pfe_13_executions(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_pfe(REF / "fluxPFE", con, "30003")
    assert n == 13
    assert rb.scanner_pfe(REF / "fluxPFE", con, "30003") == 0          # déjà en base : rien de nouveau
    r = con.execute("SELECT * FROM rb_pfe WHERE uuid='2b6da61b5e384790970e4ab0b536102e'").fetchone()
    assert r["horodatage"] == "2026-09-15 08:16:14" and r["flux"] == "B" and r["nb_releves"] == 213
    assert r["complete"] == 1 and r["ls_in_ok"] == 1 and r["zip"].endswith("compteur_20260915_0816.zip")
    assert (r["date_min"], r["date_max"]) == ("2026-09-11", "2026-09-14")


def test_scanner_ebs(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_ebs(REF / "fichierBanque", con, "30003")
    assert n == 22
    r = con.execute("SELECT * FROM rb_ebs WHERE nom='AFB120.txt_20260917081953'").fetchone()
    assert r["horodatage"] == "2026-09-17 08:19:53" and r["flux"] == "B"
    r = con.execute("SELECT horodatage FROM rb_ebs WHERE nom LIKE 'AFB120.txt_20260907110939%'").fetchone()
    assert r["horodatage"] == "2026-09-07 11:09:39"                    # suffixe libre toléré


def test_rapprochement_pfe_ebs(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_pfe(REF / "fluxPFE", con, "30003")
    rb.scanner_ebs(REF / "fichierBanque", con, "30003")
    rb.rapprocher_pfe_ebs(con)
    absents = {r[0] for r in con.execute("SELECT uuid FROM rb_pfe WHERE ebs_md5_recu=0")}
    assert absents == {"2b6da61b5e384790970e4ab0b536102e", "f067afff37d54178852c7c46a7048ab0"}
    assert con.execute("SELECT COUNT(*) FROM rb_pfe WHERE ebs_md5_recu=1").fetchone()[0] == 11
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'scanner_pfe'`.

- [ ] **Step 3 : implémentation**

```python
# ---------------------------------------------------------------- scan des dossiers
TARGET_RE = re.compile(r"compt_AFB120_RELEVESDECOMPTE_(\d{6})-(\d{6})\.txt$", re.I)
EBS_RE = re.compile(r"^AFB120\.txt_(\d{14})", re.I)


def _banques_txt(b: dict) -> str:
    return ";".join(f"{k}:{v}" for k, v in sorted(b.items(), key=lambda kv: -kv[1]))


def _d(x: date | None) -> str | None:
    return x.isoformat() if x else None


def scanner_pfe(dossier: Path, con: sqlite3.Connection, banque_b: str) -> int:
    """Charge les exécutions <uuid> absentes de rb_pfe. Retourne le nombre ajouté."""
    n = 0
    if not dossier.is_dir():
        return 0
    connus = {r[0] for r in con.execute("SELECT uuid FROM rb_pfe")}
    for d in sorted(p for p in dossier.iterdir() if p.is_dir()):
        if d.name in connus:
            continue
        targets = [f for f in (d / "TARGET").glob("*.txt")] if (d / "TARGET").is_dir() else []
        target = next((f for f in targets if TARGET_RE.search(f.name)), None)
        if target is None:
            continue
        m = TARGET_RE.search(target.name)
        horodatage = datetime.strptime(m.group(1) + m.group(2), "%y%m%d%H%M%S")
        sources = list((d / "SOURCE").glob("*")) if (d / "SOURCE").is_dir() else []
        zips = list((d / "TARGET").glob("compteur_*.zip"))
        zip_ok = False
        if zips:
            try:
                zip_ok = target.name in zipfile.ZipFile(zips[0]).namelist()
            except zipfile.BadZipFile:
                zip_ok = False
        ls_ok = (d / "TALEND" / "LS_IN.OK").exists()
        a = lire_afb120(target, banque_b)
        con.execute(
            "INSERT INTO rb_pfe(uuid,horodatage,fichier_source,fichier_target,zip,ls_in_ok,complete,flux,nb_releves,"
            "nb_lignes,banques,date_min,date_max,md5,vu_le) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (d.name, horodatage.strftime("%Y-%m-%d %H:%M:%S"), str(sources[0]) if sources else None, str(target),
             str(zips[0]) if zips else None, int(ls_ok), int(bool(sources) and zip_ok and ls_ok), a.flux,
             a.nb_releves, a.nb_lignes, _banques_txt(a.banques), _d(a.date_min), _d(a.date_max), a.md5, maintenant()))
        n += 1
    con.commit()
    return n


def scanner_ebs(dossier: Path, con: sqlite3.Connection, banque_b: str) -> int:
    """Charge les fichiers AFB120.txt_<horodatage>* absents de rb_ebs."""
    n = 0
    if not dossier.is_dir():
        return 0
    connus = {r[0] for r in con.execute("SELECT nom FROM rb_ebs")}
    for f in sorted(dossier.iterdir()):
        m = EBS_RE.match(f.name)
        if not f.is_file() or not m or f.name in connus:
            continue
        a = lire_afb120(f, banque_b)
        con.execute(
            "INSERT INTO rb_ebs(nom,horodatage,flux,nb_releves,nb_lignes,banques,date_min,date_max,md5,vu_le) "
            "VALUES (?,?,?,?,?,?,?,?,?,?)",
            (f.name, datetime.strptime(m.group(1), "%Y%m%d%H%M%S").strftime("%Y-%m-%d %H:%M:%S"), a.flux,
             a.nb_releves, a.nb_lignes, _banques_txt(a.banques), _d(a.date_min), _d(a.date_max), a.md5, maintenant()))
        n += 1
    con.commit()
    return n


def rapprocher_pfe_ebs(con: sqlite3.Connection) -> None:
    """Un TARGET PFE est « reçu » si un fichier EBS a le même md5."""
    con.execute("UPDATE rb_pfe SET ebs_md5_recu = EXISTS (SELECT 1 FROM rb_ebs e WHERE e.md5 = rb_pfe.md5)")
    con.commit()
```

- [ ] **Step 4 : lancer** → `5 passed`.

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_scan.py
git commit -m "ODAT Watch : Relevés bancaires — scan des exécutions PFE et des fichiers EBS, rapprochement par md5

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4 : logs d'import `RBAFBIMP` (`.req` + `.out`)

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_logs.py`

- [ ] **Step 1 : tests**

```python
# odat_watch/tests/test_releves_logs.py
"""Parseurs des logs RBAFBIMP (import) et DKA_SRBCTRLRB (contrôle) sur les fichiers réels."""
from pathlib import Path

import db
import logs
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"


def test_parse_import_out_rejet_total():
    p = rb.parse_import_out(logs.lire(REF / "import/o49061539.out"))
    assert p["batch"] == 1010051
    assert (p["releves_charges"], p["releves_erreurs"], p["releves_total"]) == (0, 213, 213)
    assert p["erreurs"] == {"Erreur 025": 213}
    assert len(p["releves"]) == 213 and all(r["en_erreur"] for r in p["releves"])
    r = p["releves"][0]
    assert r["compte"] == "30003.01100.00020398294" and r["code_erreur"] == "Erreur 025"
    assert (r["date_debut"], r["date_fin"]) == ("2026-09-15", "2026-09-16")


def test_parse_import_out_ok():
    p = rb.parse_import_out(logs.lire(REF / "import/o49029106.out"))
    assert (p["releves_charges"], p["releves_erreurs"], p["releves_total"]) == (207, 6, 213)
    assert (p["lignes_chargees"], p["lignes_erreurs"]) == (1663, 295)
    assert p["erreurs"] == {"Erreur 001": 5, "Erreur 025": 1}
    ko = [r for r in p["releves"] if r["en_erreur"]]
    assert len(ko) == 6 and {r["code_erreur"] for r in ko} == {"Erreur 001", "Erreur 025"}
    assert next(r for r in ko if r["compte"] == "30003.03620.00020137269")["code_erreur"] == "Erreur 025"
    ok = next(r for r in p["releves"] if not r["en_erreur"])
    assert ok["mouvements"] >= 0 and ok["date_fin"] == "2026-09-11"


def test_scanner_logs_imports(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_logs([REF / "import"], con)
    assert n == con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] >= 17
    assert rb.scanner_logs([REF / "import"], con) == 0
    r = con.execute("SELECT * FROM rb_imports WHERE request_id=49061539").fetchone()
    assert (r["lus"], r["ecrits"], r["releves_charges"], r["err025"]) == (8285, 0, 0, 213)
    assert r["debut"] == "2026-09-17 08:19:53" and r["fichier"].endswith("data/in/AFB120.txt")
    assert r["flux"] == "B"
    r = con.execute("SELECT flux, releves_charges FROM rb_imports WHERE request_id=49041437").fetchone()
    assert (r["flux"], r["releves_charges"]) == ("A", 141)
    assert con.execute("SELECT COUNT(*) FROM rb_import_releves WHERE request_id=49029106").fetchone()[0] == 213
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'parse_import_out'`.

- [ ] **Step 3 : implémentation**

```python
# ---------------------------------------------------------------- logs RBAFBIMP
MOIS = {"JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6, "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10,
        "NOV": 11, "DEC": 12}
BATCH_RE = re.compile(r"chargement N\S+\s*(\d+)")
LIGNE_ERR_RE = re.compile(r"^\s*(\d{5}) >  (.+)$")
CODE_ERR_RE = re.compile(r"^\s*Erreur\s+(\d{3})\s*:")
SYNTHESE_RE = re.compile(
    r"^(?P<err>1)?\s+(?P<num>\d+)\s+(?P<compte>\d{5}\.\d{5}\.\d{11})\s+(?P<dev>[A-Z]{3})\s+"
    r"(?P<d1>\d{2}-[A-Z]{3}-\d{4})\s+(?P<s1>-?[\d.,]+)\s+(?P<d2>\d{2}-[A-Z]{3}-\d{4})\s+(?P<s2>-?[\d.,]+)\s+"
    r"(?P<mvt>\d+)\s+(?P<l1>\d+)-(?P<l2>\d+)")
PIED_RE = re.compile(r"(Relev\S+ charg\S+|erreurs|total)\s+(\d+)\s+(Lignes charg\S+|erreurs|total)\s+(\d+)", re.I)


def _date_ora(txt: str) -> str:
    """'17-SEP-2026' ou '17-SEP-2026 08:19:53' -> ISO."""
    j, m, reste = txt.split("-", 2)
    annee, _, heure = reste.partition(" ")
    iso = f"{annee}-{MOIS[m.upper()]:02d}-{int(j):02d}"
    return f"{iso} {heure}" if heure else iso


def _date_ora_courte(txt: str) -> str:
    """'14-SEP-26' -> '2026-09-14'."""
    j, m, a = txt.split("-")
    return f"20{a}-{MOIS[m.upper()]:02d}-{int(j):02d}"


def parse_import_out(text: str) -> dict:
    """Sortie de RBAFBIMP : erreurs par enregistrement, synthèse des relevés et pied (chargés / erreurs / total)."""
    erreurs_par_compte: dict[str, str] = {}
    compteur: Counter = Counter()
    releves: list[dict] = []
    batch = None
    pied = {"releves_charges": 0, "releves_erreurs": 0, "releves_total": 0,
            "lignes_chargees": 0, "lignes_erreurs": 0, "lignes_total": 0}
    dernier_enreg = None
    for ligne in text.splitlines():
        m = BATCH_RE.search(ligne)
        if m and batch is None:
            batch = int(m.group(1))
        m = LIGNE_ERR_RE.match(ligne)
        if m:
            enreg = m.group(2)
            dernier_enreg = f"{enreg[2:7]}.{enreg[11:16]}.{enreg[21:32]}" if enreg.startswith("01") else None
            continue
        m = CODE_ERR_RE.match(ligne)
        if m:
            code = f"Erreur {m.group(1)}"
            compteur[code] += 1
            if dernier_enreg:
                erreurs_par_compte.setdefault(dernier_enreg, code)
            continue
        m = SYNTHESE_RE.match(ligne)
        if m:
            banque, guichet, numero = m.group("compte").split(".")
            releves.append(dict(num=int(m.group("num")), compte=m.group("compte"), banque=banque, guichet=guichet,
                                numero=numero, devise=m.group("dev"), date_debut=_date_ora(m.group("d1")),
                                date_fin=_date_ora(m.group("d2")), mouvements=int(m.group("mvt")),
                                en_erreur=int(m.group("err") == "1"), code_erreur=None))
            continue
        m = PIED_RE.search(ligne)
        if m:
            g1, v1, g2, v2 = m.groups()
            cle1 = "releves_charges" if g1.lower().startswith("relev") else "releves_" + ("erreurs" if g1.lower() == "erreurs" else "total")
            cle2 = "lignes_chargees" if g2.lower().startswith("lignes") else "lignes_" + ("erreurs" if g2.lower() == "erreurs" else "total")
            pied[cle1], pied[cle2] = int(v1), int(v2)
    for r in releves:
        if r["en_erreur"]:
            r["code_erreur"] = erreurs_par_compte.get(r["compte"])
    return dict(batch=batch, erreurs=dict(compteur), releves=releves, **pied)


def _flux_import(heure: str, releves: list[dict], banque_b: str) -> str:
    banques = {r["banque"] for r in releves}
    if banques:
        return "B" if banques == {banque_b} else "A"
    return "B" if heure >= "08:05:00" else "A"


def _charger_import(rid: int, req: Path | None, out: Path | None, con: sqlite3.Connection, banque_b: str) -> None:
    p_req = logs.parse_req(logs.lire(req)) if req else {}
    p_out = parse_import_out(logs.lire(out)) if out else parse_import_out("")
    cpt = {**p_req.get("compteurs", {}), **p_req.get("infos", {})}
    lus = next((int(v) for k, v in cpt.items() if "enregistrements lus" in k.lower()), None)
    ecrits = next((int(v) for k, v in cpt.items() if "crites" in k.lower()), None)
    fichier = next((v for k, v in cpt.items() if k.lower().startswith("fichier des relev")), None)
    debut = _date_ora(p_req["started"]) if p_req.get("started") else None
    fin = _date_ora(p_req["ended"]) if p_req.get("ended") else None
    err = p_out["erreurs"]
    autres = sum(v for k, v in err.items() if k not in ("Erreur 001", "Erreur 025"))
    flux = _flux_import(debut[11:] if debut else "00:00:00", p_out["releves"], banque_b)
    con.execute(
        "INSERT OR REPLACE INTO rb_imports(request_id,debut,fin,fichier,lus,ecrits,batch,releves_charges,releves_erreurs,"
        "lignes_chargees,lignes_erreurs,err001,err025,autres_erreurs,flux,source_req,source_out) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        (rid, debut, fin, fichier, lus, ecrits, p_out["batch"], p_out["releves_charges"], p_out["releves_erreurs"],
         p_out["lignes_chargees"], p_out["lignes_erreurs"], err.get("Erreur 001", 0), err.get("Erreur 025", 0), autres,
         flux, str(req) if req else None, str(out) if out else None))
    con.execute("DELETE FROM rb_import_releves WHERE request_id=?", (rid,))
    con.executemany(
        "INSERT OR REPLACE INTO rb_import_releves(request_id,num,compte,banque,guichet,numero,devise,date_debut,date_fin,"
        "mouvements,en_erreur,code_erreur) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        [(rid, r["num"], r["compte"], r["banque"], r["guichet"], r["numero"], r["devise"], r["date_debut"],
          r["date_fin"], r["mouvements"], r["en_erreur"], r["code_erreur"]) for r in p_out["releves"]])


def _est_import(text: str) -> bool:
    return "RBAFBIMP" in text or "Fichier des relev" in text or "Synth" in text and "relev" in text


def _est_controle(text: str) -> bool:
    return "DKA_SRBCTRLRB" in text or "DATE DE REFERENCE" in text


def scanner_logs(dossiers: list[Path], con: sqlite3.Connection, banque_b: str = "30003") -> int:
    """Charge les couples l<id>.req / o<id>.out nouveaux (imports et contrôles). Retourne le nombre de requests ajoutées."""
    fichiers: dict[int, dict] = {}
    for d in dossiers:
        if not d.is_dir():
            continue
        for f in d.rglob("*"):
            m = logs.FILE_RE.match(f.name)
            if f.is_file() and m:
                fichiers.setdefault(int(m.group(2)), {})["req" if m.group(1).lower() == "l" else "out"] = f
    deja = ({r[0] for r in con.execute("SELECT request_id FROM rb_imports WHERE source_out IS NOT NULL OR source_req IS NOT NULL")}
            | {r[0] for r in con.execute("SELECT request_id FROM rb_controles")})
    n = 0
    for rid, fs in sorted(fichiers.items()):
        if rid in deja:
            continue
        texte = "".join(logs.lire(f) for f in fs.values())
        if _est_controle(texte):
            _charger_controle(rid, fs.get("req"), fs.get("out"), con, banque_b)
        elif _est_import(texte):
            _charger_import(rid, fs.get("req"), fs.get("out"), con, banque_b)
        else:
            continue
        n += 1
    con.commit()
    return n
```

Ajouter provisoirement, pour que la Task 4 passe seule (remplacé en Task 5) :

```python
def _charger_controle(rid, req, out, con, banque_b):   # implémenté en Task 5
    raise NotImplementedError
```

- [ ] **Step 4 : lancer** `pytest tests/test_releves_logs.py -q` → `3 passed`. Si `PIED_RE` ne matche pas
(`releves_charges` reste 0 pour 49029106), afficher les lignes 329-331 de `o49029106.out` avec
`python -c "import logs;from pathlib import Path;print(logs.lire(Path(r'..\ControleReleveBancaire\import\o49029106.out')).splitlines()[328:331])"`
et ajuster le motif (les accents sont décodés en cp1252 : « Relevés chargés 207      Lignes chargées 1663 »).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_logs.py
git commit -m "ODAT Watch : Relevés bancaires — parseur des logs d'import RBAFBIMP (synthèse des relevés, erreurs 001/025)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5 : logs de contrôle `DKA_SRBCTRLRB` et comptes connus

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_logs.py`

- [ ] **Step 1 : tests** (ajouter)

```python
def test_parse_controle_out():
    p = rb.parse_controle_out(logs.lire(REF / "controle/o49069921.out"))
    assert p["date_reference"] == "2026-09-17"
    assert len(p["lignes"]) == 208
    sg = [l for l in p["lignes"] if l["banque"] == "30003"]
    assert len(sg) == 207
    l = p["lignes"][0]
    assert l["compte_id"] == "11412" and l["guichet"] == "00370" and l["numero"] == "00025100813"
    assert (l["date_dernier_import"], l["date_debut_releve"], l["date_fin_releve"]) == ("2026-09-14", "2026-09-10", "2026-09-11")


def test_scanner_logs_controles_et_comptes_connus(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.comptes_connus_init(con, ["30003/03620/00020137269", "16807/00166/31990892212"])
    n = rb.scanner_logs([REF / "controle"], con)
    assert n >= 17 and con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] == 0
    r = con.execute("SELECT * FROM rb_controles WHERE request_id=49069921").fetchone()
    assert r["executed_at"] == "2026-09-18 08:27:49" and r["date_reference"] == "2026-09-17"
    assert (r["nb_anomalies"], r["nb_sg"], r["nb_hors_connus"]) == (208, 207, 207)   # 16807 connu, SG 03620/…269 connu
    assert con.execute("SELECT COUNT(*) FROM rb_controle_lignes WHERE request_id=49069921").fetchone()[0] == 208
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'parse_controle_out'`.

- [ ] **Step 3 : implémentation** (remplacer le `_charger_controle` provisoire)

```python
# ---------------------------------------------------------------- logs DKA_SRBCTRLRB
DATE_REF_RE = re.compile(r"DATE DE REFERENCE\s*:\s*(\d{2})/(\d{2})/(\d{4})")
ENTETE_CTRL = "ID;NOM_BANQUE;BANQUE;GUICHET;COMPTE;NOM_COMPTE;RAPPRO;COMPTE_LOCAL;DATE_DERNIER_IMPORT"


def _date_ctrl(txt: str) -> str | None:
    txt = txt.strip()
    if not txt:
        return None
    try:
        return _date_ora_courte(txt) if len(txt) == 9 else _date_ora(txt)
    except (KeyError, ValueError):
        return txt


def parse_controle_out(text: str) -> dict:
    date_ref, lignes, en_csv = None, [], False
    for ligne in text.splitlines():
        m = DATE_REF_RE.search(ligne)
        if m:
            date_ref = f"{m.group(3)}-{m.group(2)}-{m.group(1)}"
            continue
        if ligne.startswith(ENTETE_CTRL):
            en_csv = True
            continue
        if en_csv:
            champs = ligne.strip().split(";")
            if len(champs) < 11 or not champs[0].isdigit():
                en_csv = False
                continue
            lignes.append(dict(compte_id=champs[0], nom_banque=champs[1], banque=champs[2], guichet=champs[3],
                               numero=champs[4], nom_compte=champs[5], date_dernier_import=_date_ctrl(champs[8]),
                               date_debut_releve=_date_ctrl(champs[9]), date_fin_releve=_date_ctrl(champs[10])))
    return dict(date_reference=date_ref, lignes=lignes)


def comptes_connus(con: sqlite3.Connection) -> set[str]:
    return {r[0] for r in con.execute("SELECT cle FROM rb_comptes_connus")}


def comptes_connus_init(con: sqlite3.Connection, cles: list[str]) -> None:
    """Insère les comptes connus de la config s'ils n'existent pas encore (l'onglet permet ensuite de les éditer)."""
    con.executemany("INSERT OR IGNORE INTO rb_comptes_connus(cle, motif, ajoute_le) VALUES (?, 'config.ini', ?)",
                    [(c, maintenant()) for c in cles])
    con.commit()


def enregistrer_comptes_connus(df: pd.DataFrame, con: sqlite3.Connection) -> None:
    con.execute("DELETE FROM rb_comptes_connus")
    con.executemany("INSERT OR REPLACE INTO rb_comptes_connus(cle, motif, ajoute_le) VALUES (?,?,?)",
                    [(str(r["cle"]).strip(), r.get("motif") or "", maintenant())
                     for _, r in df.iterrows() if str(r["cle"]).strip()])
    con.commit()


def _charger_controle(rid: int, req: Path | None, out: Path | None, con: sqlite3.Connection, banque_b: str) -> None:
    p_req = logs.parse_req(logs.lire(req)) if req else {}
    p = parse_controle_out(logs.lire(out)) if out else dict(date_reference=None, lignes=[])
    connus = comptes_connus(con)
    executed = _date_ora(p_req["started"]) if p_req.get("started") else None
    nb_sg = sum(1 for l in p["lignes"] if l["banque"] == banque_b)
    hors = sum(1 for l in p["lignes"] if f"{l['banque']}/{l['guichet']}/{l['numero']}" not in connus)
    con.execute("INSERT OR REPLACE INTO rb_controles(request_id,executed_at,date_reference,nb_anomalies,nb_sg,"
                "nb_hors_connus,source_out) VALUES (?,?,?,?,?,?,?)",
                (rid, executed, p["date_reference"], len(p["lignes"]), nb_sg, hors, str(out) if out else None))
    con.execute("DELETE FROM rb_controle_lignes WHERE request_id=?", (rid,))
    con.executemany(
        "INSERT OR REPLACE INTO rb_controle_lignes(request_id,compte_id,banque,guichet,numero,nom_compte,"
        "date_dernier_import,date_debut_releve,date_fin_releve) VALUES (?,?,?,?,?,?,?,?,?)",
        [(rid, l["compte_id"], l["banque"], l["guichet"], l["numero"], l["nom_compte"], l["date_dernier_import"],
          l["date_debut_releve"], l["date_fin_releve"]) for l in p["lignes"]])
```

- [ ] **Step 4 : lancer** `pytest tests/test_releves_logs.py -q` → `5 passed`.

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_logs.py
git commit -m "ODAT Watch : Relevés bancaires — parseur du contrôle DKA_SRBCTRLRB et comptes connus

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6 : chaîne Control-M de la matinée (photos ODAT)

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_controlm.py`

- [ ] **Step 1 : tests**

```python
# odat_watch/tests/test_releves_controlm.py
"""Diagnostic de la chaîne FINEXT_J14INT_05/06 à partir des photos ODAT de l'incident (sans déplacer les fichiers)."""
from datetime import date
from pathlib import Path

import pytest

import db
import ingest
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire" / "FichierODAT"


def _charger_photo(con, path: Path, snap_time: str):
    rows = ingest.read_rows(path)
    odate = min(r["odate"] for r in rows if r["odate"])
    cur = con.execute("INSERT INTO snapshots(odate, snap_time, source_file, file_hash, nb_lignes) VALUES (?,?,?,?,?)",
                      (odate, snap_time, path.name, f"{path.name}-{snap_time}", len(rows)))
    con.executemany(f"INSERT OR IGNORE INTO ctm_jobs(snapshot_id,{','.join(ingest.COLS)}) VALUES (?{',?' * len(ingest.COLS)})",
                    [(cur.lastrowid, *[r[c] for c in ingest.COLS]) for r in rows])
    con.commit()


@pytest.fixture
def con(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _charger_photo(con, REF / "Report_ctm_260914_14_8h06.csv", "2026-09-15 08:06:00")
    _charger_photo(con, REF / "Report_ctm_260915_15_September_2026 (1)" / "Report_ctm_260915_15_new.csv", "2026-09-16 08:06:00")
    _charger_photo(con, REF / "Report_ctm_260916_16_September_2026 (1)" / "Report_ctm_260916_16_new.csv", "2026-09-17 07:36:00")
    return con


def test_chaine_du_15_conflit_et_zip_not_ok(con):
    df = rb.chaine_controlm(con, date(2026, 9, 15))
    assert set(df["job_name"]) >= {"FINEXT_J14INT_05_MOV01_Q", "FINEXT_J14INT_06_MOV01_Q", "FINEXT_J14INT_06_ZIP01_Q"}
    zip06 = df[df["job_name"] == "FINEXT_J14INT_06_ZIP01_Q"].iloc[0]
    assert zip06["status"] == "Ended Not OK" and zip06["rerun"] >= 10
    d = rb.diagnostic_controlm(df)
    assert d["conflit_mov"] and d["zip06_not_ok"] and not d["import06_execute"]
    assert "06_ZIP01" in d["causes"][0] or "conflit" in d["causes"][0].lower()


def test_chaine_du_17_saine(con):
    d = rb.diagnostic_controlm(rb.chaine_controlm(con, date(2026, 9, 17)))
    assert not d["conflit_mov"] and not d["zip06_not_ok"]


def test_sans_photo(con):
    df = rb.chaine_controlm(con, date(2026, 9, 1))
    assert df.empty
    d = rb.diagnostic_controlm(df)
    assert d["photo"] is None and d["causes"] == []
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'chaine_controlm'`.

- [ ] **Step 3 : implémentation**

```python
# ---------------------------------------------------------------- Control-M (photos ODAT)
GROUPES_CTM = ("FINEXT_J14INT_05_Q", "FINEXT_J14INT_06_Q")
JOBS_CTM_LIKE = "FINEXT_J14INT_0[56]_%"


def chaine_controlm(con: sqlite3.Connection, jour: date) -> pd.DataFrame:
    """Jobs des chaînes 05/06 pour la matinée `jour` (odate = veille), dernière photo prise ce jour-là.
    Colonnes : job_name, group_name, status, start_time, end_time, rerun, order_id, snap_time."""
    veille = (jour - timedelta(days=1)).isoformat()
    snap = con.execute(
        "SELECT id, snap_time FROM snapshots WHERE odate=? AND substr(snap_time,1,10)=? ORDER BY snap_time DESC LIMIT 1",
        (veille, jour.isoformat())).fetchone()
    if not snap:   # photo prise plus tard dans la journée ou le lendemain matin : on prend la dernière de l'odate
        snap = con.execute("SELECT id, snap_time FROM snapshots WHERE odate=? ORDER BY snap_time DESC LIMIT 1",
                           (veille,)).fetchone()
    if not snap:
        return pd.DataFrame(columns=["job_name", "group_name", "status", "start_time", "end_time", "rerun", "order_id", "snap_time"])
    df = pd.read_sql_query(
        "SELECT job_name, group_name, status, start_time, end_time, rerun, order_id FROM ctm_jobs "
        "WHERE snapshot_id=? AND job_name GLOB 'FINEXT_J14INT_0[56]_*' ORDER BY job_name, rerun", con, params=(snap["id"],))
    df["snap_time"] = snap["snap_time"]
    # une ligne par job : le dernier rerun
    df = df.sort_values(["job_name", "rerun"]).groupby("job_name", as_index=False).last()
    return df


def _heure(df: pd.DataFrame, job: str) -> str | None:
    r = df[df["job_name"] == job]
    return None if r.empty or pd.isna(r.iloc[0]["start_time"]) else str(r.iloc[0]["start_time"])


def diagnostic_controlm(df: pd.DataFrame) -> dict:
    """conflit_mov : 06_MOV01 démarre à < 60 s de 05_MOV01 ; zip06_not_ok : 06_ZIP01 Ended Not OK ;
    import06_execute : 06_IMP01 a tourné."""
    d = dict(photo=None, conflit_mov=False, zip06_not_ok=False, import06_execute=False, causes=[])
    if df.empty:
        return d
    d["photo"] = str(df.iloc[0]["snap_time"])
    h05, h06 = _heure(df, "FINEXT_J14INT_05_MOV01_Q"), _heure(df, "FINEXT_J14INT_06_MOV01_Q")
    if h05 and h06:
        ecart = abs((datetime.fromisoformat(h06) - datetime.fromisoformat(h05)).total_seconds())
        d["conflit_mov"] = ecart < 60
    z = df[df["job_name"] == "FINEXT_J14INT_06_ZIP01_Q"]
    d["zip06_not_ok"] = bool(len(z)) and str(z.iloc[0]["status"]).strip() == "Ended Not OK"
    i = df[df["job_name"] == "FINEXT_J14INT_06_IMP01_Q"]
    d["import06_execute"] = bool(len(i)) and str(i.iloc[0]["status"]).startswith("Ended")
    if d["conflit_mov"]:
        d["causes"].append(f"Conflit de chaînes : FINEXT_J14INT_06_MOV01_Q a démarré à {h06[11:19]}, en même temps que la "
                           f"chaîne 05 ({h05[11:19]}) — la chaîne 06 a consommé le Compteur.zip du flux A.")
    if d["zip06_not_ok"]:
        d["causes"].append(f"FINEXT_J14INT_06_ZIP01_Q terminé Ended Not OK (rerun {int(z.iloc[0]['rerun'] or 0)}) : "
                           "la chaîne cyclique 06 est bloquée, le zip de 08:16 ne sera ni mové ni importé.")
    return d
```

- [ ] **Step 4 : lancer** → `3 passed`. Si le statut lu n'est pas exactement `Ended Not OK`, afficher
`df[["job_name","status","rerun"]]` dans le test et aligner la comparaison (`.strip()`, casse).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_controlm.py
git commit -m "ODAT Watch : Relevés bancaires — chaîne Control-M 05/06 de la matinée et diagnostic (conflit MOV, ZIP01 Not OK)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7 : verdict de la matinée (`journee`) et chronologie des imports

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_journee.py`

- [ ] **Step 1 : tests**

```python
# odat_watch/tests/test_releves_journee.py
"""Verdict par flux, chronologie, continuité et plan de reprise sur le jeu de données complet de l'incident."""
from datetime import date
from pathlib import Path

import pytest

import db
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


@pytest.fixture(scope="module")
def con(tmp_path_factory):
    con = db.connect(tmp_path_factory.mktemp("rb") / "t.db")
    rb.scanner_tout(CFG, con)
    return con


def test_scanner_tout_journal(con):
    assert con.execute("SELECT COUNT(*) FROM rb_pfe").fetchone()[0] == 13
    assert con.execute("SELECT COUNT(*) FROM rb_ebs").fetchone()[0] == 22
    assert con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] >= 17
    assert con.execute("SELECT COUNT(*) FROM rb_controles").fetchone()[0] >= 17
    assert "30003/03620/00020137269" in rb.comptes_connus(con)


def test_journee_15_09_flux_b_non_recu(con):
    j = rb.journee(con, date(2026, 9, 15), CFG)
    a, b = j.flux["A"], j.flux["B"]
    assert a.verdict == "OK" and a.pfe["uuid"] == "9098a5f957a749dd8e1545f9e9b68199" and a.import_["request_id"] == 49041437
    assert b.verdict == "KO" and b.pfe["uuid"] == "2b6da61b5e384790970e4ab0b536102e"
    assert b.ebs is None and b.import_ is None
    assert any("non reçu" in c for c in b.causes)
    assert j.verdict == "KO"


def test_journee_17_09_rejet_025(con):
    b = rb.journee(con, date(2026, 9, 17), CFG).flux["B"]
    assert b.verdict == "KO" and b.import_["request_id"] == 49061539
    assert any("Erreur 025" in c for c in b.causes)


def test_journee_14_09_ok_avec_erreurs_connues(con):
    j = rb.journee(con, date(2026, 9, 14), CFG)
    assert j.flux["B"].verdict == "OK" and j.flux["B"].import_["request_id"] == 49029106


def test_journee_12_09_flux_b_absent(con):
    b = rb.journee(con, date(2026, 9, 12), CFG).flux["B"]
    assert b.verdict == "WARN" and b.pfe is None and any("PFE" in c for c in b.causes)


def test_journee_week_end(con):
    j = rb.journee(con, date(2026, 9, 13), CFG)       # samedi
    assert j.verdict == "—" and j.motif == "samedi"


def test_etapes_de_la_frise(con):
    b = rb.journee(con, date(2026, 9, 15), CFG).flux["B"]
    assert [e["cle"] for e in b.etapes] == ["pfe", "controlm", "ebs", "import", "controle"]
    assert b.etapes[0]["ton"] == "ok" and b.etapes[2]["ton"] == "ko"


def test_chronologie(con):
    ch = rb.chronologie(con, jours=15, jour=date(2026, 9, 18))
    r = ch[ch["request_id"] == 49061539].iloc[0]
    assert r["fichier"] == "AFB120.txt_20260917081953" and r["flux"] == "B" and r["resultat"].startswith("213 × Erreur 025")
    r = ch[ch["request_id"] == 49029106].iloc[0]
    assert r["resultat"] == "OK" and r["charges"] == 207
    assert list(ch["debut"]) == sorted(ch["debut"])
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'scanner_tout'`.

- [ ] **Step 3 : implémentation**

```python
# ---------------------------------------------------------------- scan global
def scanner_tout(cfg: dict, con: sqlite3.Connection) -> str:
    comptes_connus_init(con, cfg["comptes_connus"])
    n_pfe = scanner_pfe(cfg["dossier_pfe"], con, cfg["banque_flux_b"])
    n_ebs = scanner_ebs(cfg["dossier_ebs"], con, cfg["banque_flux_b"])
    n_logs = scanner_logs(cfg["dossiers_logs"], con, cfg["banque_flux_b"])
    rapprocher_pfe_ebs(con)
    con.execute("UPDATE rb_imports SET md5_ebs = (SELECT e.md5 FROM rb_ebs e WHERE substr(e.horodatage,1,16) = "
                "substr(rb_imports.debut,1,16) OR (e.horodatage <= rb_imports.debut AND e.horodatage >= "
                "datetime(rb_imports.debut, '-3 minutes')) ORDER BY e.horodatage DESC LIMIT 1) WHERE md5_ebs IS NULL")
    con.commit()
    return f"{n_pfe} exécution(s) PFE, {n_ebs} fichier(s) EBS, {n_logs} log(s) nouveaux."


# ---------------------------------------------------------------- journée
HEURE_ATTENDUE = {"A": "07:50", "B": "08:20"}
FENETRE = {"A": ("06:30:00", "08:05:00"), "B": ("08:05:00", "10:00:00")}
TON_VERDICT = {"OK": "ok", "WARN": "warn", "KO": "ko", "—": "neutral"}


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


def rejet_massif(imp: dict | None) -> bool:
    """Import rejeté en bloc : aucun relevé chargé et plusieurs Erreur 025."""
    return bool(imp) and (imp["releves_charges"] or 0) == 0 and (imp["err025"] or 0) > 1


def journee(con: sqlite3.Connection, jour: date, cfg: dict) -> Journee:
    import controle_matin as cm
    j = Journee(jour=jour, motif=cm.jour_sans_integration(jour))
    js = jour.isoformat()
    j.controlm_df = chaine_controlm(con, jour)
    diag = diagnostic_controlm(j.controlm_df)
    j.controles = _tous(con, "SELECT * FROM rb_controles WHERE substr(executed_at,1,10)=? ORDER BY executed_at", (js,))
    for code in ("A", "B"):
        f = Flux(code=code, controlm=diag)
        h0, h1 = FENETRE[code]
        f.pfe = _un(con, "SELECT * FROM rb_pfe WHERE flux=? AND substr(horodatage,1,10)=? ORDER BY horodatage DESC LIMIT 1", (code, js))
        f.ebs = _un(con, "SELECT * FROM rb_ebs WHERE flux=? AND substr(horodatage,1,10)=? ORDER BY horodatage DESC LIMIT 1", (code, js))
        f.import_ = _un(con, "SELECT * FROM rb_imports WHERE flux=? AND substr(debut,1,10)=? AND substr(debut,12) BETWEEN ? AND ? "
                             "ORDER BY debut DESC LIMIT 1", (code, js, h0, h1))
        f.controles = [c for c in j.controles if code == "A" or c["executed_at"] > (f.import_["fin"] if f.import_ else js + " 08:05:00")]
        _verdict_flux(f, j.motif)
        j.flux[code] = f
    if j.motif and not any(f.pfe or f.import_ for f in j.flux.values()):
        j.verdict = "—"
    else:
        ordre = {"KO": 3, "WARN": 2, "OK": 1, "—": 0}
        j.verdict = max((f.verdict for f in j.flux.values()), key=ordre.get)
    return j


def _verdict_flux(f: Flux, motif: str | None) -> None:
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
        if rejet_massif(imp):
            e_imp = ("ko", f"req {imp['request_id']} · 0 chargé · {imp['err025']} × Erreur 025")
            f.causes.append(f"Import {imp['request_id']} rejeté en bloc : {imp['err025']} × Erreur 025 « Journée manquante » — "
                            "un relevé antérieur n'a jamais été chargé ; rejouer les fichiers manquants dans l'ordre.")
        elif (imp["releves_charges"] or 0) == 0:
            e_imp = ("ko", f"req {imp['request_id']} · 0 chargé")
            f.causes.append(f"Import {imp['request_id']} : aucun relevé chargé.")
        else:
            e_imp = ("ok", f"req {imp['request_id']} · {imp['releves_charges']} chargés / {imp['releves_erreurs']} err.")
    elif pfe or ebs:
        e_imp = ("ko", "pas d'import")
        if ebs:
            f.causes.append("Fichier reçu par EBS mais aucun import RBAFBIMP trouvé (log absent ? lancer copy_ebs_logs.sh).")
    else:
        e_imp = ("neutral", "—")
    # --- contrôle
    if f.controles:
        c = f.controles[-1]
        if (c["nb_hors_connus"] or 0) == 0:
            e_ctl = ("ok", f"req {c['request_id']} · aucune anomalie")
        elif f.code == "B" and imp and not rejet_massif(imp):
            e_ctl = ("warn", f"req {c['request_id']} · {c['nb_hors_connus']} anomalie(s)")
        else:
            e_ctl = ("ko" if f.code == "B" else "warn", f"req {c['request_id']} · {c['nb_hors_connus']} anomalie(s)")
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
    debut = fin - timedelta(days=jours + 1)
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
```

- [ ] **Step 4 : lancer** `pytest tests/test_releves_journee.py -q` → `8 passed`. Points de vigilance :
  - `test_journee_12_09_flux_b_absent` : le 12/09 est un vendredi, `motif` est None, flux B sans PFE/EBS/import → WARN.
  - `test_journee_14_09` : l'import 49029106 est à 07:49 mais c'est un flux B (100 % 30003) → la fenêtre A/B ne doit pas
    l'exclure : si le test échoue, remplacer la borne de la requête import par `flux=? AND substr(debut,1,10)=?` sans
    fenêtre horaire (le flux est déjà déterminé par les banques) et garder la fenêtre uniquement pour rattacher les contrôles.
  - `md5_ebs` : l'import 49061539 (08:19:53) doit être relié à `AFB120.txt_20260917081953` (même minute).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_journee.py
git commit -m "ODAT Watch : Relevés bancaires — verdict de la matinée par flux (frise 5 étapes, causes) et chronologie des imports

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8 : continuité des comptes SG, plan de reprise, list.txt

**Files:**
- Modify: `odat_watch/releves.py`
- Test: `odat_watch/tests/test_releves_journee.py`

- [ ] **Step 1 : tests** (ajouter)

```python
def test_continuite_sg(con):
    c = rb.continuite(con, CFG, jour=date(2026, 9, 18))
    assert len(c) >= 200
    r = c[c["compte"] == "30003.01100.00020398294"].iloc[0]
    assert r["dernier_charge"] == "2026-09-11" and r["attendu"] == "2026-09-17" and r["retard_j"] == 6 and r["trou"]
    connu = c[c["compte"] == "30003.03620.00020137269"]
    assert connu.empty or connu.iloc[0]["connu"]


def test_plan_reprise(con):
    plan = rb.plan_reprise(con, CFG)
    assert [Path(e["chemin"]).name for e in plan] == [
        "compt_AFB120_RELEVESDECOMPTE_260915-081614.txt", "compt_AFB120_RELEVESDECOMPTE_260916-081613.txt",
        "AFB120.txt_20260917081953", "AFB120.txt_20260918082009"]
    assert plan[0]["periode"] == "2026-09-11 → 2026-09-14" and plan[0]["attendu"] == "207 chargés / 6 erreurs"
    assert plan[2]["origine"] == "EBS (rejeté Erreur 025)" and plan[0]["origine"] == "PFE (non reçu)"


def test_plan_reprise_vide_sans_trou(tmp_path):
    con = db.connect(tmp_path / "v.db")
    assert rb.plan_reprise(con, CFG) == []


def test_liste_logs_manquants(con, tmp_path):
    con.execute("INSERT INTO ora_requests(request_id, program_short, phase_code, logfile_name, outfile_name, actual_start) "
                "VALUES (49999999, 'RBAFBIMP', 'C', '/l/l49999999.req', '/o/o49999999.out', '2026-09-19 08:20:00')")
    con.execute("INSERT INTO ora_requests(request_id, program_short, phase_code, logfile_name, outfile_name, actual_start) "
                "VALUES (49061539, 'RBAFBIMP', 'C', '/l/l49061539.req', '/o/o49061539.out', '2026-09-17 08:19:53')")
    con.commit()
    dest = tmp_path / "list.txt"
    msg = rb.liste_logs_manquants(con, dest)
    assert dest.read_text() == "/l/l49999999.req /o/o49999999.out\n" and "1 ligne" in msg
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `AttributeError: ... 'continuite'`.

- [ ] **Step 3 : implémentation**

```python
# ---------------------------------------------------------------- continuité et reprise
def continuite(con: sqlite3.Connection, cfg: dict, jour: date | None = None) -> pd.DataFrame:
    """Par compte de la banque du flux B : dernier relevé chargé, date attendue (dernier fichier PFE/EBS flux B),
    retard en jours, trou (un import ultérieur a rejeté le compte en Erreur 025)."""
    b = cfg["banque_flux_b"]
    connus = comptes_connus(con)
    attendu = con.execute("SELECT MAX(m) FROM (SELECT MAX(date_max) m FROM rb_pfe WHERE flux=? "
                          "UNION ALL SELECT MAX(date_max) FROM rb_ebs WHERE flux=?)", (b, b)).fetchone()[0]
    df = pd.read_sql_query("""
        SELECT r.compte, r.banque, r.guichet, r.numero,
               MAX(CASE WHEN r.en_erreur=0 THEN r.date_fin END) AS dernier_charge,
               MAX(CASE WHEN r.code_erreur='Erreur 025' THEN i.debut END) AS dernier_rejet_025
        FROM rb_import_releves r JOIN rb_imports i ON i.request_id = r.request_id
        WHERE r.banque = ? GROUP BY r.compte ORDER BY r.compte""", con, params=(b,))
    if df.empty:
        return df.assign(attendu=None, retard_j=None, trou=None, connu=None)
    df["attendu"] = attendu
    df["retard_j"] = df.apply(lambda r: (date.fromisoformat(r["attendu"]) - date.fromisoformat(r["dernier_charge"])).days
                              if r["attendu"] and r["dernier_charge"] else None, axis=1)
    df["trou"] = df.apply(lambda r: bool(r["dernier_rejet_025"]) and (not r["dernier_charge"] or r["dernier_rejet_025"][:10] > r["dernier_charge"]), axis=1)
    df["connu"] = df.apply(lambda r: f"{r['banque']}/{r['guichet']}/{r['numero']}" in connus, axis=1)
    return df


def plan_reprise(con: sqlite3.Connection, cfg: dict) -> list[dict]:
    """Fichiers du flux B à rejouer dans l'ordre : TARGET PFE non reçus, fichiers EBS rejetés en bloc ou jamais importés,
    à partir du dernier relevé chargé. [{ordre, chemin, origine, periode, nb_releves, attendu}]"""
    b = cfg["banque_flux_b"]
    ok = con.execute("SELECT MAX(i.fin), MAX(r.date_fin), MAX(i.releves_erreurs) FROM rb_imports i "
                     "JOIN rb_import_releves r ON r.request_id=i.request_id AND r.en_erreur=0 "
                     "WHERE i.flux=? AND i.releves_charges > 0", (b,)).fetchone()
    dernier_ok_fin, dernier_charge, erreurs_habituelles = ok
    dernier_charge = dernier_charge or "0000-00-00"
    cand: dict[str, dict] = {}
    for r in con.execute("SELECT * FROM rb_pfe WHERE flux=? AND ebs_md5_recu=0 AND complete=1 AND date_max > ?", (b, dernier_charge)):
        cand[r["md5"]] = dict(chemin=r["fichier_target"], origine="PFE (non reçu)", date_min=r["date_min"],
                              date_max=r["date_max"], nb_releves=r["nb_releves"])
    for r in con.execute("SELECT e.*, i.request_id, i.releves_charges, i.err025 FROM rb_ebs e "
                         "LEFT JOIN rb_imports i ON i.md5_ebs = e.md5 WHERE e.flux=? AND e.date_max > ?", (b, dernier_charge)):
        if r["request_id"] is None:
            origine = "EBS (jamais importé)"
        elif rejet_massif(dict(r)):
            origine = "EBS (rejeté Erreur 025)"
        else:
            continue
        cand[r["md5"]] = dict(chemin=str(cfg["dossier_ebs"] / r["nom"]), origine=origine, date_min=r["date_min"],
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
          AND r.request_id NOT IN (SELECT request_id FROM rb_imports)
          AND r.request_id NOT IN (SELECT request_id FROM rb_controles)
        ORDER BY r.actual_start""").fetchall()
    dest = dest or (BASE_DIR / "list_releves.txt")
    lignes = [f"{r['logfile_name'] or ''} {r['outfile_name'] or ''}".strip() for r in rows if r["logfile_name"]]
    dest.write_text("\n".join(lignes) + ("\n" if lignes else ""), encoding="utf-8", newline="\n")
    return f"{len(lignes)} ligne(s) écrite(s) dans {dest} (à passer à copy_ebs_logs.sh sur le serveur EBS)."
```

- [ ] **Step 4 : lancer** → `12 passed`. Si le plan contient un 5ᵉ fichier (ex. `AFB120.txt_20260914074951` = 10→11/09,
`date_max` 2026-09-11 = `dernier_charge`), c'est que la comparaison `date_max > dernier_charge` n'exclut pas : vérifier
que `dernier_charge` vaut bien `2026-09-11` (`SELECT MAX(date_fin) ...`).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/releves.py odat_watch/tests/test_releves_journee.py
git commit -m "ODAT Watch : Relevés bancaires — continuité des comptes SG, plan de reprise ordonné, list.txt des logs manquants

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9 : rapport HTML

**Files:**
- Create: `odat_watch/rapport_releves.py`
- Test: `odat_watch/tests/test_rapport_releves.py`

- [ ] **Step 1 : tests**

```python
# odat_watch/tests/test_rapport_releves.py
from datetime import date
from pathlib import Path

import db
import rapport_releves as rr
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


def test_rapport_complet(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_tout(CFG, con)
    bilan = rr.Bilan(journee=rb.journee(con, date(2026, 9, 15), CFG), chronologie=rb.chronologie(con, 15, date(2026, 9, 18)),
                     continuite=rb.continuite(con, CFG), plan=rb.plan_reprise(con, CFG),
                     pfe=rb.rapprochement_pfe(con), controles=rb.controles(con))
    html = rr.construire(bilan)
    for titre in ("Matinée du 15/09/2026", "Flux A", "Flux B", "Chronologie des imports", "Continuité",
                  "Plan de reprise", "Rapprochement PFE", "Contrôles"):
        assert titre in html
    assert "compt_AFB120_RELEVESDECOMPTE_260915-081614.txt" in html and "bandeau ko" in html
    chemin = rr.ecrire(bilan, tmp_path)
    assert chemin.name.startswith("Releves_20260915_") and chemin.suffix == ".html"


def test_echappement(tmp_path):
    con = db.connect(tmp_path / "t.db")
    j = rb.journee(con, date(2026, 9, 15), CFG)
    j.flux["A"].causes.append("<script>alert(1)</script>")
    html = rr.construire(rr.Bilan(journee=j))
    assert "<script>alert" not in html and "&lt;script&gt;" in html
```

- [ ] **Step 2 : ajouter à `releves.py` les deux accesseurs utilisés par le rapport et l'onglet**

```python
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
```

- [ ] **Step 3 : lancer, vérifier l'échec** — `ModuleNotFoundError: No module named 'rapport_releves'`.

- [ ] **Step 4 : implémentation**

```python
# odat_watch/rapport_releves.py
"""Rapport HTML autonome de l'onglet Relevés bancaires (même charte que rapport_matin)."""
from __future__ import annotations

import html
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

import pandas as pd

from rapport_matin import STYLE
from releves import Journee, TON_VERDICT

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"
CLASSE = {"ok": "ok", "warn": "warn", "ko": "ko", "neutral": "na"}
STYLE_FRISE = """
  .frise { display: flex; gap: 8px; align-items: stretch; margin: 6px 0 14px; flex-wrap: wrap; }
  .pas { flex: 1 1 150px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px; padding: 9px 10px; border-top: 4px solid #8b949e; }
  .pas.ok { border-top-color: #1F9D55; } .pas.warn { border-top-color: #D9A400; } .pas.ko { border-top-color: #D23F31; }
  .pas b { display: block; font-size: .78em; text-transform: uppercase; color: #57606a; }
  .pas span { font-size: .82em; }
  .flux { margin-bottom: 10px; }
  .causes { background: #fff8e1; border-left: 4px solid #D9A400; padding: 8px 12px; font-size: .85em; margin: 6px 0 12px; }
  .causes.ko { background: #fbdcdc; border-left-color: #D23F31; }
"""


@dataclass
class Bilan:
    journee: Journee
    chronologie: pd.DataFrame = field(default_factory=pd.DataFrame)
    continuite: pd.DataFrame = field(default_factory=pd.DataFrame)
    plan: list = field(default_factory=list)
    pfe: pd.DataFrame = field(default_factory=pd.DataFrame)
    controles: pd.DataFrame = field(default_factory=pd.DataFrame)


def _t(v) -> str:
    return "" if v is None or (isinstance(v, float) and pd.isna(v)) else html.escape(str(v))


def _table(df: pd.DataFrame, colonnes: dict[str, str]) -> str:
    if df is None or df.empty:
        return "<div class='vide'>aucune donnée</div>"
    head = "".join(f"<th>{html.escape(l)}</th>" for l in colonnes.values())
    rows = []
    for _, r in df.iterrows():
        rows.append("<tr>" + "".join(
            f"<td class='num'>{_t(r[c])}</td>" if isinstance(r[c], (int, float)) and not isinstance(r[c], bool) else f"<td>{_t(r[c])}</td>"
            for c in colonnes) + "</tr>")
    return f"<div class='tablewrap'><table><thead><tr>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>"


def _frise(flux) -> str:
    pas = "".join(f"<div class='pas {CLASSE[e['ton']]}'><b>{_t(e['libelle'])}</b><span>{_t(e['texte'])}</span></div>"
                  for e in flux.etapes)
    cls = TON_VERDICT[flux.verdict]
    causes = ("" if not flux.causes else
              f"<div class='causes {cls}'>" + "<br>".join(_t(c) for c in flux.causes) + "</div>")
    return (f"<div class='flux'><h3>Flux {flux.code} <span class='pill {CLASSE[cls]}'>{_t(flux.verdict)}</span></h3>"
            f"<div class='frise'>{pas}</div>{causes}</div>")


def construire(b: Bilan) -> str:
    j = b.journee
    cls = CLASSE[TON_VERDICT[j.verdict]]
    msg = {"OK": "Les deux flux ont été intégrés.", "WARN": "À surveiller.", "KO": "Rupture de la chaîne des relevés.",
           "—": "Pas d'intégration attendue (" + (j.motif or "aucune donnée") + ")."}[j.verdict]
    plan = ("<div class='vide'>aucun fichier à rejouer</div>" if not b.plan else _table(pd.DataFrame(b.plan), {
        "ordre": "Étape", "chemin": "Fichier source", "origine": "Origine", "periode": "Relevé", "nb_releves": "Relevés",
        "attendu": "Résultat attendu"}))
    cont = b.continuite
    if cont is not None and not cont.empty:
        cont = cont[(cont["trou"] == True) | (cont["retard_j"].fillna(0) > 1)].sort_values("retard_j", ascending=False)  # noqa: E712
    sections = [
        ("Matinée du %s" % j.jour.strftime("%d/%m/%Y"), "".join(_frise(f) for f in j.flux.values())),
        ("Chronologie des imports", _table(b.chronologie, {"debut": "Date / heure", "request_id": "Request", "fichier": "Fichier EBS",
                                                           "flux": "Flux", "lus": "Lus", "ecrits": "Écrits", "charges": "Chargés",
                                                           "erreurs": "Erreurs", "resultat": "Résultat"})),
        ("Continuité des comptes (retard ou trou)", _table(cont, {"compte": "Compte", "dernier_charge": "Dernier relevé chargé",
                                                                  "attendu": "Attendu", "retard_j": "Retard (j)", "trou": "Trou", "connu": "Connu"})),
        ("Plan de reprise", plan),
        ("Rapprochement PFE ↔ EBS", _table(b.pfe, {"horodatage": "Exécution PFE", "uuid": "UUID", "flux": "Flux", "nb_releves": "Relevés",
                                                  "date_min": "Du", "date_max": "Au", "fichier_ebs": "Fichier EBS", "request_id": "Import",
                                                  "statut": "Statut"})),
        ("Contrôles DKA_SRBCTRLRB", _table(b.controles, {"executed_at": "Exécuté le", "request_id": "Request", "date_reference": "Date de référence",
                                                        "nb_anomalies": "Anomalies", "nb_sg": "dont SG", "nb_hors_connus": "hors comptes connus"})),
    ]
    corps = "".join(f"<h2>{html.escape(t)}</h2>{c}" for t, c in sections)
    return f"""<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8"><title>Relevés bancaires — {j.jour:%d/%m/%Y}</title>
<style>{STYLE}{STYLE_FRISE}</style></head><body><div class="wrap">
<h1>🏦 Relevés bancaires — matinée du {j.jour:%d/%m/%Y}</h1>
<div class="meta"><span>Généré le {datetime.now():%d/%m/%Y %H:%M}</span><span>Flux A = multi-banques 07:50 · Flux B = Société Générale 08:20</span></div>
<div class="bandeau {cls}"><strong>{_t(j.verdict)}</strong>{_t(msg)}</div>
{corps}
<div class="footer">ODAT Watch · rapport Relevés bancaires</div></div></body></html>"""


def ecrire(b: Bilan, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Releves_{b.journee.jour:%Y%m%d}_{datetime.now():%H%M}.html"
    chemin.write_text(construire(b), encoding="utf-8")
    return chemin
```

- [ ] **Step 5 : lancer** `pytest tests/test_rapport_releves.py tests/test_releves_journee.py -q` → tout vert.

- [ ] **Step 6 : commit**

```bash
git add odat_watch/rapport_releves.py odat_watch/releves.py odat_watch/tests/test_rapport_releves.py
git commit -m "ODAT Watch : Relevés bancaires — rapport HTML (frise A/B, chronologie, continuité, plan de reprise, PFE↔EBS, contrôles)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10 : onglet Streamlit « 🏦 Relevés bancaires »

**Files:**
- Create: `odat_watch/ui_releves.py`
- Modify: `odat_watch/app.py:309-333`
- Test: `odat_watch/tests/test_ui_releves.py`

- [ ] **Step 1 : test AppTest**

```python
# odat_watch/tests/test_ui_releves.py
"""Onglet Relevés bancaires via AppTest : scan, frise, plan de reprise."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import releves as rb
import ui_releves

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


def _script():
    import sys
    from datetime import date
    from pathlib import Path
    import streamlit as st
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_releves

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    st.session_state.setdefault("rb_jour", date(2026, 9, 15))
    ui_releves.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    monkeypatch.setattr(ui_releves, "connect", lambda: db.connect(base))
    monkeypatch.setattr(ui_releves.rb, "config_releves", lambda: CFG)
    at = AppTest.from_function(_script, default_timeout=120)
    at.run()
    assert not at.exception
    return at, base


def _texte(at) -> str:
    return "\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)


def test_avant_scan_invite(app):
    at, _ = app
    assert "Scanner" in "\n".join(b.label for b in at.button)


def test_scan_puis_frise_et_plan(app):
    at, base = app
    at.button(key="rb_scanner").click().run()
    assert not at.exception
    con = db.connect(base)
    assert con.execute("SELECT COUNT(*) FROM rb_pfe").fetchone()[0] == 13
    texte = _texte(at)
    assert "Flux B" in texte and "non reçu" in texte
    assert "Plan de reprise" in texte and "260915-081614" in texte
    assert "KO" in texte


def test_rapport_html(app, tmp_path, monkeypatch):
    at, base = app
    import rapport_releves
    monkeypatch.setattr(rapport_releves, "DOSSIER_RAPPORTS", tmp_path / "rapports")
    at.button(key="rb_scanner").click().run()
    at.button(key="rb_btn_rapport").click().run()
    assert not at.exception
    assert list((tmp_path / "rapports").glob("Releves_20260915_*.html"))
```

- [ ] **Step 2 : lancer, vérifier l'échec** — `ModuleNotFoundError: No module named 'ui_releves'`.

- [ ] **Step 3 : implémentation de l'onglet**

```python
# odat_watch/ui_releves.py
"""Onglet « 🏦 Relevés bancaires » : frise de la matinée (PFE → Control-M → EBS → import → contrôle), chronologie,
continuité des comptes SG, plan de reprise, rapprochement PFE ↔ EBS, chaîne Control-M, contrôles, comptes connus."""
from __future__ import annotations

from datetime import date

import pandas as pd
import streamlit as st

import rapport_releves as rr
import releves as rb
from db import connect

COULEUR = {"ok": "#1F9D55", "warn": "#D9A400", "ko": "#D23F31", "neutral": "#8A94A6"}
FOND = {"ok": "#EAF7EE", "warn": "#FFF8E1", "ko": "#FDECEC", "neutral": "#F3F4F6"}
ICONE = {"OK": "✅", "WARN": "⚠️", "KO": "🔴", "—": "⚪"}


def _frise(f: rb.Flux) -> None:
    ton = rb.TON_VERDICT[f.verdict]
    st.markdown(f"**Flux {f.code}** — {'multi-banques, import ~07:50' if f.code == 'A' else 'Société Générale, import ~08:20'} "
                f"&nbsp; <span style='background:{FOND[ton]};color:{COULEUR[ton]};border:1px solid {COULEUR[ton]};"
                f"border-radius:10px;padding:1px 9px;font-weight:700'>{ICONE[f.verdict]} {f.verdict}</span>",
                unsafe_allow_html=True)
    cols = st.columns(5)
    for col, e in zip(cols, f.etapes):
        col.markdown(f"<div style='border-top:4px solid {COULEUR[e['ton']]};background:#fff;border:1px solid #dde3ea;"
                     f"border-top:4px solid {COULEUR[e['ton']]};border-radius:6px;padding:8px 10px;min-height:74px'>"
                     f"<div style='font-size:.75rem;text-transform:uppercase;color:#57606a'>{e['libelle']}</div>"
                     f"<div style='font-size:.85rem'>{e['texte']}</div></div>", unsafe_allow_html=True)
    for c in f.causes:
        (st.error if ton == "ko" else st.warning)(c)


def _tuiles(kpi, j: rb.Journee, plan: list, cont: pd.DataFrame) -> None:
    c1, c2, c3, c4, c5 = st.columns(5)
    kpi(c1, ICONE[j.verdict] + " " + j.verdict, "verdict du jour", rb.TON_VERDICT[j.verdict])
    for col, code in ((c2, "A"), (c3, "B")):
        f = j.flux[code]
        kpi(col, f.verdict, f"flux {code}", rb.TON_VERDICT[f.verdict])
    n_trou = int(cont["trou"].sum()) if not cont.empty else 0
    kpi(c4, n_trou, "comptes en rupture", "err" if n_trou else "ok")
    kpi(c5, len(plan), "fichiers à rejouer", "err" if plan else "ok")


def render(kpi):
    cfg = rb.config_releves()
    con = connect()
    try:
        st.markdown("#### Chaîne des relevés bancaires · PFE → Control-M (FINEXT_J14INT_05/06) → EBS (RBAFBIMP → DKA_SRBCTRLRB)")
        b1, b2, b3, b4 = st.columns([1.2, 1.4, 1.4, 1.6])
        jour = b1.date_input("Matinée", st.session_state.get("rb_jour", date.today()), key="rb_jour", format="DD/MM/YYYY")
        if b2.button("🔄 Scanner les dossiers", type="primary", use_container_width=True, key="rb_scanner",
                     help=f"PFE : {cfg['dossier_pfe']}\nEBS : {cfg['dossier_ebs']}\nLogs : {'; '.join(str(d) for d in cfg['dossiers_logs'])}"):
            with st.spinner("Lecture des fichiers PFE, EBS et des logs…"):
                st.session_state["rb_msg"] = rb.scanner_tout(cfg, con)
        if b3.button("📋 list.txt des logs manquants", use_container_width=True, key="rb_liste"):
            st.session_state["rb_msg"] = rb.liste_logs_manquants(con)
        if st.session_state.get("rb_msg"):
            st.info(st.session_state["rb_msg"])

        vide = con.execute("SELECT (SELECT COUNT(*) FROM rb_pfe) + (SELECT COUNT(*) FROM rb_ebs) + (SELECT COUNT(*) FROM rb_imports)").fetchone()[0] == 0
        if vide:
            st.caption("Aucune donnée : copiez les exécutions PFE (dossiers <uuid>), les fichiers AFB120.txt_* et les logs "
                       ".req/.out dans les dossiers de `config.ini [releves]`, puis cliquez sur **Scanner**.")
            return

        j = rb.journee(con, jour, cfg)
        plan = rb.plan_reprise(con, cfg)
        cont = rb.continuite(con, cfg, jour)
        if b4.button("📄 Rapport HTML", use_container_width=True, key="rb_btn_rapport"):
            bilan = rr.Bilan(journee=j, chronologie=rb.chronologie(con, 15, jour), continuite=cont, plan=plan,
                             pfe=rb.rapprochement_pfe(con), controles=rb.controles(con))
            chemin = rr.ecrire(bilan, rr.DOSSIER_RAPPORTS)
            st.session_state["rb_rapport"] = str(chemin)
        if st.session_state.get("rb_rapport"):
            st.success(f"Rapport écrit : `{st.session_state['rb_rapport']}`")

        _tuiles(kpi, j, plan, cont)
        if j.motif:
            st.caption(f"{jour:%d/%m/%Y} = {j.motif} : pas d'intégration attendue.")

        st.markdown("##### Frise de la matinée")
        for code in ("A", "B"):
            _frise(j.flux[code])

        if plan:
            st.markdown("##### 🛠 Plan de reprise")
            st.error("Rupture de continuité : rejouer ces fichiers **un par un, dans l'ordre**, en attendant la fin de "
                     "chaque request RBAFBIMP (copier sous `AFB120.txt` dans `data/in`, lancer l'import, vérifier "
                     "`Relevés chargés`). Puis lancer DKA_SRBCTRLRB.")
            st.dataframe(pd.DataFrame(plan)[["ordre", "chemin", "origine", "periode", "nb_releves", "attendu"]],
                         hide_index=True, use_container_width=True,
                         column_config={"ordre": "Étape", "chemin": "Fichier source", "origine": "Origine",
                                        "periode": "Relevé", "nb_releves": "Relevés", "attendu": "Résultat attendu"})

        st.markdown("##### Chronologie des imports (15 jours)")
        ch = rb.chronologie(con, 15, jour)
        st.dataframe(ch[["debut", "request_id", "fichier", "flux", "lus", "ecrits", "charges", "erreurs", "resultat"]],
                     hide_index=True, use_container_width=True,
                     column_config={"debut": "Date / heure", "request_id": st.column_config.NumberColumn("Request", format="%d"),
                                    "fichier": "Fichier EBS", "flux": "Flux", "lus": "Lus", "ecrits": "Écrits",
                                    "charges": "Chargés", "erreurs": "Erreurs", "resultat": "Résultat"})

        with st.expander(f"Continuité des comptes {cfg['banque_flux_b']} — {int(cont['trou'].sum()) if not cont.empty else 0} en rupture", expanded=bool(plan)):
            if cont.empty:
                st.caption("Aucun import chargé pour cette banque.")
            else:
                vue = cont.sort_values(["trou", "retard_j"], ascending=[False, False])
                st.dataframe(vue[["compte", "dernier_charge", "attendu", "retard_j", "trou", "connu"]], hide_index=True,
                             use_container_width=True, height=320,
                             column_config={"compte": "Compte", "dernier_charge": "Dernier relevé chargé", "attendu": "Attendu",
                                            "retard_j": "Retard (j)", "trou": "Trou", "connu": "Connu"})

        with st.expander("Rapprochement PFE ↔ EBS"):
            pfe = rb.rapprochement_pfe(con)
            st.dataframe(pfe[["horodatage", "uuid", "flux", "nb_releves", "date_min", "date_max", "fichier_ebs", "request_id", "statut"]],
                         hide_index=True, use_container_width=True,
                         column_config={"horodatage": "Exécution PFE", "uuid": "UUID", "flux": "Flux", "nb_releves": "Relevés",
                                        "date_min": "Du", "date_max": "Au", "fichier_ebs": "Fichier EBS",
                                        "request_id": st.column_config.NumberColumn("Import", format="%d"), "statut": "Statut"})

        with st.expander("Chaîne Control-M de la matinée"):
            if j.controlm_df.empty:
                st.caption("Aucune photo ODAT pour cette matinée (importer les fichiers Report_ctm dans l'onglet Données).")
            else:
                d = j.flux["B"].controlm
                st.caption(f"Photo du {d['photo']} · conflit MOV 05/06 : {'oui' if d['conflit_mov'] else 'non'} · "
                           f"06_ZIP01 Not OK : {'oui' if d['zip06_not_ok'] else 'non'} · 06_IMP01 exécuté : {'oui' if d['import06_execute'] else 'non'}")
                st.dataframe(j.controlm_df[["job_name", "group_name", "status", "start_time", "end_time", "rerun"]],
                             hide_index=True, use_container_width=True)

        with st.expander("Contrôles DKA_SRBCTRLRB"):
            ctl = rb.controles(con)
            st.dataframe(ctl, hide_index=True, use_container_width=True)
            if not ctl.empty:
                rid = st.selectbox("Détail du contrôle", ctl["request_id"].tolist(), key="rb_ctl")
                st.dataframe(rb.lignes_controle(con, int(rid)), hide_index=True, use_container_width=True, height=300)

        with st.expander("Comptes connus (anomalies préexistantes ignorées par le verdict)"):
            df = pd.read_sql_query("SELECT cle, motif FROM rb_comptes_connus ORDER BY cle", con)
            edite = st.data_editor(df, num_rows="dynamic", hide_index=True, use_container_width=True, key="rb_connus",
                                   column_config={"cle": "banque/guichet/compte", "motif": "Motif"})
            if st.button("💾 Enregistrer les comptes connus", key="rb_connus_save"):
                rb.enregistrer_comptes_connus(edite, con)
                st.success("Comptes connus enregistrés — relancez « Scanner » pour recalculer les contrôles.")
    finally:
        con.close()
```

- [ ] **Step 4 : brancher l'onglet dans `app.py`**

Ligne 309-310 : ajouter `tab_releves` après `tab_matin` dans le tuple et `"🏦 Relevés bancaires"` après `"☀️ Matin"`
dans la liste :

```python
tab_plan, tab_calendriers, tab_soir, tab_demain, tab_now, tab_matin, tab_releves, tab_folio, tab_ora, tab_ref, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🧭 Préparer ma nuit", "📥 Clôtures", "🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "☀️ Matin", "🏦 Relevés bancaires", "🌹 Folio Rose", "🅾 Oracle", "📒 Référentiel", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])
```

Après le bloc `with tab_matin:` :

```python
with tab_releves:
    import ui_releves
    ui_releves.render(kpi)
```

- [ ] **Step 5 : lancer** `pytest tests/test_ui_releves.py -q` → `3 passed`, puis la suite complète
`PYTHONIOENCODING=utf-8 python -m pytest tests -q` → tout vert (≥ 147 + nouveaux).
Note AppTest : `st.date_input` avec `key="rb_jour"` et une valeur déjà dans `session_state` — si Streamlit lève
`StreamlitAPIException` (valeur par défaut + clé déjà en état), passer `date.today()` seulement quand la clé est absente :
`b1.date_input("Matinée", key="rb_jour", format="DD/MM/YYYY")` après un `st.session_state.setdefault("rb_jour", date.today())`.

- [ ] **Step 6 : vérification visuelle** — lancer `streamlit run app.py --server.port 8506`, ouvrir l'onglet, cliquer
« Scanner », choisir le 15/09/2026 : frise B rouge (Reçu EBS « non reçu »), plan de reprise à 4 lignes ; le 17/09 :
import rouge « 213 × Erreur 025 » ; le 13/09 : « samedi ». Ne pas cliquer sur des boutons Oracle.

- [ ] **Step 7 : commit**

```bash
git add odat_watch/ui_releves.py odat_watch/app.py odat_watch/tests/test_ui_releves.py
git commit -m "ODAT Watch : onglet Relevés bancaires — frise PFE/Control-M/EBS/import/contrôle, plan de reprise, continuité, PFE↔EBS

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 11 : documentation et finitions

**Files:**
- Modify: `odat_watch/README.md`
- Modify: `.gitignore` (si `list_releves.txt` doit être ignoré)

- [ ] **Step 1 : README** — ajouter une section « 🏦 Relevés bancaires » après celle du contrôle du matin :

```markdown
## 🏦 Relevés bancaires

Suit chaque matinée la chaîne PFE → Control-M (`FINEXT_J14INT_05_Q` flux A ~07:50, `FINEXT_J14INT_06_Q` flux B
Société Générale ~08:20) → EBS (`RBAFBIMP` puis `DKA_SRBCTRLRB`).

Sources locales (section `[releves]` de `config.ini`) :
- `dossier_pfe` : un sous-dossier `<uuid>` par exécution Talend (`SOURCE/`, `TARGET/compt_AFB120_*.txt` + `compteur_*.zip`, `TALEND/LS_IN.OK`) ;
- `dossier_ebs` : les `AFB120.txt_<AAAAMMJJHHMMSS>` reçus par EBS (`data/traite`) ;
- `dossiers_logs` : les `l<id>.req` / `o<id>.out` des imports et contrôles (rapatriés avec `copy_ebs_logs.sh`,
  liste générée par le bouton « list.txt des logs manquants » à partir des demandes Oracle chargées).

« Scanner » relit les dossiers (ce qui est déjà en base est ignoré), rapproche PFE ↔ EBS par md5, puis affiche :
la frise de la matinée par flux (PFE · Control-M · Reçu EBS · Import · Contrôle, verdict OK / WARN / KO et causes),
le plan de reprise quand un fichier est manquant ou rejeté en `Erreur 025` (fichiers à rejouer dans l'ordre, résultat
attendu), la chronologie des imports, la continuité par compte SG, le rapprochement PFE ↔ EBS, la chaîne Control-M
(conflit `06_MOV01` / `05_MOV01`, `06_ZIP01` Ended Not OK) et les contrôles `DKA_SRBCTRLRB`. Les « comptes connus »
(anomalies préexistantes) sont ignorés par le verdict et éditables dans l'onglet. Rapport HTML dans `rapports/Releves_*.html`.
Samedi, dimanche et jours fériés : aucune intégration attendue, pas d'alerte.
```

- [ ] **Step 2 : `.gitignore`** — ajouter `odat_watch/list_releves.txt`.

- [ ] **Step 3 : suite complète** `PYTHONIOENCODING=utf-8 python -m pytest tests -q` → tout vert.

- [ ] **Step 4 : commit**

```bash
git add odat_watch/README.md .gitignore
git commit -m "ODAT Watch : Relevés bancaires — documentation

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Auto-revue (spec ↔ plan)

- Sources locales configurables, scan idempotent → Tasks 1, 3, 4, 5, 7 (`scanner_tout`).
- AFB120 (01/04/05/07, banques, dates, md5, flux) → Task 2 ; PFE `complete` (SOURCE + zip contenant le TARGET + LS_IN.OK) → Task 3.
- Import `.req/.out` (lus, écrits, synthèse, Err 001/025, flux par banques puis heure) → Task 4 ; contrôle → Task 5.
- Control-M (dernière photo de la matinée, conflit < 60 s, ZIP01 Not OK, IMP01) → Task 6.
- `journee` (5 pastilles, verdict OK/WARN/KO/—, causes, week-end/férié via `controle_matin.jour_sans_integration`),
  `chronologie` → Task 7 ; `continuite`, `plan_reprise` (4 étapes du README §8), `liste_logs_manquants` → Task 8.
- Rapport HTML → Task 9 ; onglet (barre, tuiles, frise, plan, chronologie, continuité, PFE↔EBS, Control-M, contrôles,
  comptes connus) → Task 10 ; README → Task 11.
- Hors périmètre V1 conservé : la vue Oracle XXRB complémentaire n'est pas dans ce plan (à ajouter ensuite si utile).
- Noms cohérents entre tâches : `rejet_massif`, `TON_VERDICT`, `Flux.etapes[{cle,libelle,ton,texte}]`, `Journee.motif`,
  `rapprochement_pfe`, `controles`, `lignes_controle`, `comptes_connus_init`, `enregistrer_comptes_connus`, clés Streamlit
  `rb_jour / rb_scanner / rb_liste / rb_btn_rapport / rb_ctl / rb_connus / rb_connus_save`.
