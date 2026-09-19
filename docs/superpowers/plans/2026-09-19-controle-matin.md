# Onglet « Matin » (contrôle quotidien) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter à ODAT Watch un onglet « ☀️ Matin » qui exécute les 15 contrôles de `ControleMatinGenerique/Controle_Quotidien_Complet.sql` via `oracledb` sur une plage date+heure libre (défaut hier 19:00 → aujourd'hui 07:00), en affiche la synthèse et le détail, historise les indicateurs dans SQLite, génère un rapport HTML téléchargeable et peut se programmer chaque matin via le Planificateur Windows.

**Architecture:** Quatre modules dans `odat_watch/` : `controle_matin.py` (moteur : requêtes Oracle portées, statuts, historique SQLite, CLI), `rapport_matin.py` (HTML pur, charte de `FichierControleFluxCoteUnix/rapport_reconciliation.py`), `planif_matin.py` (tâche `schtasks`), `ui_matin.py` (onglet Streamlit). `db.py` reçoit la table `controle_matin_histo` ; `app.py` gagne un onglet. Le `.sql` et le `.ps1` d'origine ne sont pas modifiés.

**Tech Stack:** Python 3 (venv `C:\tmp\odatenv`), Streamlit, pandas, plotly, oracledb, sqlite3, pytest, `schtasks` (Windows).

**Spec :** `docs/superpowers/specs/2026-09-19-controle-matin-design.md`.

**Conventions du dépôt :**
- Commentaires et libellés en français, ton des modules existants (`oracle_refresh.py`, `ui_oracle.py`).
- Toutes les commandes se lancent depuis `odat_watch/` avec `/c/tmp/odatenv/Scripts/python.exe` (Git Bash).
- Commits en français, terminés par `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les requêtes conservent les `TO_CHAR` d'affichage du `.sql` ; seules les bornes temporelles changent (`:debut`, `:fin`, `:histo` à la place de `SYSDATE`). Dans le SQL, `:debut`/`:fin` sont utilisés via `CAST(:x AS DATE)` : oracledb lie un `datetime` en TIMESTAMP, et l'arithmétique `TIMESTAMP - nombre` n'est pas garantie.

---

## Carte des fichiers

| Fichier | Action | Responsabilité |
|---|---|---|
| `odat_watch/tests/conftest.py` | créer | rend `odat_watch/` importable par pytest |
| `odat_watch/db.py` | modifier | table `controle_matin_histo` |
| `odat_watch/controle_matin.py` | créer | dataclasses, catalogue SQL, `executer`, statuts, historique, delta veille, CLI |
| `odat_watch/rapport_matin.py` | créer | `construire(resultat) -> str`, `ecrire(resultat, dossier) -> Path` |
| `odat_watch/planif_matin.py` | créer | tâche planifiée Windows (`commande`, `creer`, `supprimer`, `etat`) |
| `odat_watch/ui_matin.py` | créer | `render(now, kpi)` : onglet Streamlit |
| `odat_watch/app.py` | modifier | onglet « ☀️ Matin » |
| `odat_watch/README.md` | modifier | documenter le module |
| `.gitignore` | modifier | ignorer `odat_watch/rapports/` |
| `odat_watch/tests/test_controle_matin.py` | créer | statuts, statut global, binds, plage par défaut, enrichissement job |
| `odat_watch/tests/test_histo_matin.py` | créer | table, `enregistrer_histo`, `delta_veille`, `historique` |
| `odat_watch/tests/test_rapport_matin.py` | créer | rendu HTML |
| `odat_watch/tests/test_planif_matin.py` | créer | commande schtasks, parsing de l'état |

---

### Task 1 : outillage de test

**Files:**
- Create: `odat_watch/tests/conftest.py`
- Modify: `.gitignore`

- [ ] **Step 1 : installer pytest dans le venv**

Run: `/c/tmp/odatenv/Scripts/python.exe -m pip install pytest`
Expected: `Successfully installed pytest-...` (ou « Requirement already satisfied »).

- [ ] **Step 2 : créer le conftest**

Fichier `odat_watch/tests/conftest.py` :

```python
"""Rend les modules d'odat_watch importables depuis tests/ quel que soit le cwd."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
```

- [ ] **Step 3 : ignorer le dossier des rapports générés**

Ajouter à la fin de `.gitignore` (le fichier se termine par une ligne mal encodée `extractionCap/*.xlsx` ; ajouter après elle, sur une nouvelle ligne) :

```
# Rapports HTML du contrôle du matin (ODAT Watch)
odat_watch/rapports/
```

- [ ] **Step 4 : vérifier que pytest tourne à vide**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: `no tests ran` (code retour 5, normal).

- [ ] **Step 5 : commit**

```bash
git add odat_watch/tests/conftest.py .gitignore
git commit -m "ODAT Watch : socle pytest et dossier rapports ignoré

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2 : table `controle_matin_histo` dans SQLite

**Files:**
- Modify: `odat_watch/db.py` (constante `SCHEMA`, avant la triple-quote fermante)
- Test: `odat_watch/tests/test_histo_matin.py`

- [ ] **Step 1 : test de création de la table**

Fichier `odat_watch/tests/test_histo_matin.py` :

```python
"""Historique du contrôle du matin dans SQLite."""
from datetime import datetime

import db


def _cols(con, table):
    return [r[1] for r in con.execute(f"PRAGMA table_info({table})")]


def test_table_controle_matin_histo_creee(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cols = _cols(con, "controle_matin_histo")
    for c in ("date_ctrl", "plage_debut", "plage_fin", "statut_global", "nb_images_manq", "fichier_rapport"):
        assert c in cols
    con.close()
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_histo_matin.py -q`
Expected: FAIL — `assert 'date_ctrl' in []`.

- [ ] **Step 3 : ajouter la table au schéma**

Dans `odat_watch/db.py`, juste avant la ligne `"""` qui ferme `SCHEMA` (après le bloc `CREATE TABLE IF NOT EXISTS job_mapping (...);`), ajouter :

```sql

CREATE TABLE IF NOT EXISTS controle_matin_histo (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date_ctrl         TEXT NOT NULL,      -- AAAA-MM-JJ, jour de la borne de fin
    executed_at       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM:SS
    plage_debut       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM
    plage_fin         TEXT NOT NULL,
    statut_global     TEXT NOT NULL,      -- OK | WARNING | ALERTE | ERREUR
    nb_flux_dsp       INTEGER, nb_ndf INTEGER, nb_fac_xerox INTEGER, nb_fac_tradeshift INTEGER,
    nb_fac_dsp        INTEGER, nb_gl_interface INTEGER, nb_gl_lignes INTEGER,
    nb_traitements    INTEGER, nb_erreurs INTEGER, nb_warnings INTEGER,
    nb_rb_imports     INTEGER, nb_images_manq INTEGER,
    duree_s           REAL,
    fichier_rapport   TEXT
);
CREATE INDEX IF NOT EXISTS ix_cm_histo_date ON controle_matin_histo(date_ctrl, executed_at);
```

- [ ] **Step 4 : lancer, vérifier le succès**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_histo_matin.py -q`
Expected: `1 passed`.

- [ ] **Step 5 : commit**

```bash
git add odat_watch/db.py odat_watch/tests/test_histo_matin.py
git commit -m "ODAT Watch : table controle_matin_histo

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3 : `controle_matin.py` — dataclasses, plage par défaut, règles de statut, catalogue SQL

**Files:**
- Create: `odat_watch/controle_matin.py`
- Test: `odat_watch/tests/test_controle_matin.py`

- [ ] **Step 1 : tests**

Fichier `odat_watch/tests/test_controle_matin.py` :

```python
"""Règles de statut et catalogue du contrôle du matin (mêmes seuils que Controle_Quotidien_Complet.sql)."""
from datetime import datetime

import pandas as pd

import controle_matin as cm


def compteurs_ok(**maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0)
    c.update(maj)
    return c


def test_plage_par_defaut_hier_19h_aujourdhui_7h():
    debut, fin = cm.plage_par_defaut(datetime(2026, 9, 21, 8, 42))
    assert debut == datetime(2026, 9, 20, 19, 0)
    assert fin == datetime(2026, 9, 21, 7, 0)


def test_statuts_tout_ok():
    s = cm.statuts(compteurs_ok())
    assert set(s.values()) == {"OK"}
    assert set(s) == {"nb_flux_dsp", "nb_ndf", "nb_fac_xerox", "nb_fac_tradeshift", "nb_fac_dsp",
                      "nb_gl_interface", "nb_gl_lignes", "nb_rb_imports"}


def test_statuts_seuil_dsp_et_factures_dsp():
    s = cm.statuts(compteurs_ok(nb_flux_dsp=4))
    assert s["nb_flux_dsp"] == "W"
    assert s["nb_fac_dsp"] == "W"          # dépend du seuil DSP
    s = cm.statuts(compteurs_ok(nb_fac_dsp=2))
    assert s["nb_fac_dsp"] == "W"          # une facture DSP = anomalie


def test_statuts_compteur_absent_est_w():
    assert cm.statuts(compteurs_ok(nb_ndf=None))["nb_ndf"] == "W"


def _sections(**erreur_ou_lignes):
    out = []
    for cle, titre, _sql, alerte_si_lignes in cm.CATALOGUE:
        sec = cm.Section(cle=cle, titre=titre, df=pd.DataFrame())
        if cle in erreur_ou_lignes:
            v = erreur_ou_lignes[cle]
            if isinstance(v, str):
                sec.erreur = v
            else:
                sec.df = pd.DataFrame({"REQ_ID": list(range(v))})
                sec.alerte = alerte_si_lignes and v > 0
        out.append(sec)
    return out


def test_statut_global_ok():
    assert cm.statut_global(compteurs_ok(), _sections()) == "OK"


def test_statut_global_warning_sur_seuil():
    assert cm.statut_global(compteurs_ok(nb_flux_dsp=2), _sections()) == "WARNING"


def test_statut_global_warning_sur_warnings_nuit():
    assert cm.statut_global(compteurs_ok(nb_warnings=1), _sections()) == "WARNING"


def test_statut_global_warning_sur_traitement_en_cours():
    assert cm.statut_global(compteurs_ok(), _sections(nuit_en_cours=1)) == "WARNING"


def test_statut_global_alerte_erreurs():
    assert cm.statut_global(compteurs_ok(nb_erreurs=1), _sections()) == "ALERTE"


def test_statut_global_alerte_images_manquantes():
    assert cm.statut_global(compteurs_ok(nb_images_manq=3), _sections()) == "ALERTE"


def test_statut_global_erreur_si_section_en_echec():
    assert cm.statut_global(compteurs_ok(), _sections(rb="ORA-00942: table ou vue inexistante")) == "ERREUR"


def test_statut_global_erreur_si_compteur_indisponible():
    assert cm.statut_global(compteurs_ok(nb_rb_imports=None), _sections()) == "ERREUR"


def test_binds_ne_garde_que_les_variables_presentes():
    sql = "SELECT 1 FROM dual WHERE :histo > 0 AND CAST(:fin AS DATE) > SYSDATE"
    d, f = datetime(2026, 9, 18, 19), datetime(2026, 9, 19, 7)
    assert cm._binds(sql, {"histo": 3, "debut": d, "fin": f}) == {"histo": 3, "fin": f}


def test_catalogue_15_sections_sans_sysdate_de_fenetre():
    cles = [c[0] for c in cm.CATALOGUE]
    assert len(cles) == 15 and len(set(cles)) == 15
    assert cles[0] == "dsp_detail" and cles[-1] == "rb"
    for cle, _t, sql, _a in cm.CATALOGUE:
        if cle != "nuit_en_cours":      # seule la durée des traitements en cours lit l'horloge
            assert "SYSDATE" not in sql, cle
    for _cles, sql in cm.SYNTHESE:
        assert "SYSDATE" not in sql
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_controle_matin.py -q`
Expected: FAIL — `ModuleNotFoundError: No module named 'controle_matin'`.

- [ ] **Step 3 : écrire le module (partie pure + catalogue SQL)**

Fichier `odat_watch/controle_matin.py` :

```python
"""Contrôle du matin : portage Python de ControleMatinGenerique/Controle_Quotidien_Complet.sql.

Le .sql reste la référence métier ; les requêtes ci-dessous en sont la copie, avec trois
paramètres nommés à la place de SYSDATE et des variables SQL*Plus :
    :debut  = début de la nuit contrôlée (datetime, défaut hier 19:00)  — la « veille » du .sql
    :fin    = fin de la nuit contrôlée   (datetime, défaut aujourd'hui 07:00) — le « jour » du .sql
    :histo  = nb de jours d'historique affichés (v_nb_jours_histo, défaut 3)
On peut ainsi rejouer un matin passé. Seule la durée des traitements « en cours » lit SYSDATE.

Chaque section est exécutée indépendamment : une requête qui échoue (ORA-xxxxx) est
signalée dans Section.erreur et n'empêche pas les autres de tourner, comme dans le .ps1.

Usage en ligne de commande (c'est ce que lance la tâche planifiée) :
    python controle_matin.py                      # plage par défaut, synthèse à l'écran
    python controle_matin.py --rapport            # + rapport HTML dans rapports/
    python controle_matin.py --debut "2026-09-18 19:00" --fin "2026-09-19 07:00" --histo 5
"""
from __future__ import annotations
import argparse
import sqlite3
import time
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta

import pandas as pd

from db import connect
from oracle_refresh import _connect_oracle, _schema, load_config

# ------------------------------------------------------------------ modèles

COMPTEURS = ["nb_flux_dsp", "nb_ndf", "nb_fac_xerox", "nb_fac_tradeshift", "nb_fac_dsp",
             "nb_gl_interface", "nb_gl_lignes", "nb_traitements", "nb_erreurs", "nb_warnings",
             "nb_rb_imports", "nb_images_manq"]

LIBELLES = {
    "nb_flux_dsp": "Flux DSP (fichiers)", "nb_ndf": "Notes de frais Notilus",
    "nb_fac_xerox": "Factures Xerox", "nb_fac_tradeshift": "Factures Tradeshift",
    "nb_fac_dsp": "Factures DSP", "nb_gl_interface": "Écritures GL (interface)",
    "nb_gl_lignes": "Lignes GL créées", "nb_traitements": "Traitements nuit",
    "nb_erreurs": "Erreurs", "nb_warnings": "Avertissements",
    "nb_rb_imports": "Imports RB", "nb_images_manq": "Images manquantes",
}


@dataclass
class Section:
    cle: str
    titre: str
    df: pd.DataFrame | None = None
    erreur: str | None = None
    alerte: bool = False

    @property
    def nb(self) -> int:
        return 0 if self.df is None else len(self.df)


@dataclass
class Resultat:
    executed_at: datetime
    debut: datetime
    fin: datetime
    nb_jours_histo: int
    compteurs: dict
    statuts: dict
    statut_global: str
    sections: list[Section] = field(default_factory=list)
    duree_s: float = 0.0
    date_rb_max: date | None = None
    erreurs_synthese: dict = field(default_factory=dict)   # compteur -> message Oracle
    fichier_rapport: str | None = None
    histo_id: int | None = None

    @property
    def date_ctrl(self) -> date:
        return self.fin.date()

    def section(self, cle: str) -> Section | None:
        return next((s for s in self.sections if s.cle == cle), None)


def plage_par_defaut(now: datetime) -> tuple[datetime, datetime]:
    """Hier 19:00 → aujourd'hui 07:00 (les valeurs par défaut du .sql)."""
    fin = now.replace(hour=7, minute=0, second=0, microsecond=0)
    return fin - timedelta(hours=12), fin


# ------------------------------------------------------------------ règles de statut

def statuts(compteurs: dict) -> dict:
    """OK / W par indicateur, mêmes seuils que la SECTION 2 du .sql. Un compteur absent vaut W."""
    c = {k: compteurs.get(k) for k in COMPTEURS}
    def pos(k): return c[k] is not None and c[k] > 0
    dsp_ok = c["nb_flux_dsp"] is not None and c["nb_flux_dsp"] >= 5
    return {
        "nb_flux_dsp": "OK" if dsp_ok else "W",
        "nb_ndf": "OK" if pos("nb_ndf") else "W",
        "nb_fac_xerox": "OK" if pos("nb_fac_xerox") else "W",
        "nb_fac_tradeshift": "OK" if pos("nb_fac_tradeshift") else "W",
        # Une facture DSP dans le reporting Xerox est une anomalie : OK = 0 facture ET flux DSP présents.
        "nb_fac_dsp": "OK" if (c["nb_fac_dsp"] == 0 and dsp_ok) else "W",
        "nb_gl_interface": "OK" if pos("nb_gl_interface") else "W",
        "nb_gl_lignes": "OK" if pos("nb_gl_lignes") else "W",
        "nb_rb_imports": "OK" if pos("nb_rb_imports") else "W",
    }


def statut_global(compteurs: dict, sections: list[Section]) -> str:
    """ERREUR (contrôle indisponible) > ALERTE (erreurs nuit, images manquantes) > WARNING > OK."""
    if any(s.erreur for s in sections) or any(compteurs.get(k) is None for k in COMPTEURS):
        return "ERREUR"
    if (compteurs["nb_erreurs"] or 0) > 0 or (compteurs["nb_images_manq"] or 0) > 0:
        return "ALERTE"
    en_cours = next((s for s in sections if s.cle == "nuit_en_cours"), None)
    if ((compteurs["nb_warnings"] or 0) > 0 or "W" in statuts(compteurs).values()
            or (en_cours is not None and en_cours.nb > 0)):
        return "WARNING"
    return "OK"


# ------------------------------------------------------------------ catalogue SQL
# Toutes les requêtes sont des f-strings : {{s}} devient {s} (préfixe de schéma, résolu à
# l'exécution), {DEB}/{FIN} sont les bornes castées en DATE, {NUIT} la fenêtre nuit commune.

DEB = "CAST(:debut AS DATE)"
FIN = "CAST(:fin AS DATE)"
JOUR_FR = "'DAY', 'NLS_DATE_LANGUAGE=FRENCH'"

NUIT = f"""
WHERE  fcr.actual_start_date >= {DEB}
AND    fcr.actual_start_date <  {FIN}
AND    fcr.requested_by IN (SELECT user_id FROM {{s}}fnd_user WHERE user_name LIKE 'EXP%')"""

TYPE_FLUX = """CASE
    WHEN dih.file_name LIKE '%SUP%'                                  THEN 'FOURNISSEURS'
    WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '['
      OR dih.file_name LIKE '%CDE%'
      OR dih.file_name LIKE 'ORDER%'                                 THEN 'COMMANDES'
    WHEN dih.file_name LIKE '%REC%'                                  THEN 'RECEPTIONS'
    WHEN dih.file_name LIKE '%DEB%' OR dih.file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
    ELSE 'AUTRE' END"""

_DSP_TABLES = ["dka_ipofrs_hist_entetes", "dka_ipocde_hist_headers",
               "dka_iporec_hist_interface", "dka_iapfac_debloc_hist_interf"]


def _dsp_union_detail() -> str:
    return "\n    UNION ALL\n".join(
        f"    SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation, "
        f"TO_CHAR(dih.creation_date, {JOUR_FR}) AS jour_creation, dih.file_name\n"
        f"    FROM {{s}}{t} dih WHERE dih.creation_date > {FIN} - :histo" for t in _DSP_TABLES)


# (clé, titre, sql, alerte_si_lignes) — ordre du .sql.
CATALOGUE: list[tuple[str, str, str, bool]] = [
    ("dsp_detail", "DSP — Détail des flux (fichiers)", f"""
SELECT 'DSP' AS SRC, TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR, RTRIM(jour_creation) AS JOUR,
       {TYPE_FLUX.replace('dih.file_name', 'file_name')} AS TYPE_FLUX, file_name AS FICHIER
FROM (
{_dsp_union_detail()}
)
ORDER BY date_creation DESC, TYPE_FLUX, file_name""", False),

    ("dsp_jour", "DSP — Synthèse par jour et type", f"""
SELECT TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR, RTRIM(jour_creation) AS JOUR,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'FOURNISSEURS' THEN file_name END) AS NB_SUP,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'COMMANDES'    THEN file_name END) AS NB_CDE,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'RECEPTIONS'   THEN file_name END) AS NB_REC,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'DEBLOCAGE'    THEN file_name END) AS NB_DEB,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'AUTRE'        THEN file_name END) AS NB_AUT,
       COUNT(DISTINCT file_name) AS TOTAL
FROM (
    SELECT TRUNC(dih.creation_date) AS date_creation, TO_CHAR(dih.creation_date, {JOUR_FR}) AS jour_creation,
           dih.file_name, {TYPE_FLUX} AS TYPE_FLUX
    FROM {{s}}dka_ipofrs_hist_entetes dih WHERE dih.creation_date > {FIN} - :histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, {JOUR_FR}), dih.file_name,
           CASE WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '[' OR dih.file_name LIKE '%CDE%' THEN 'COMMANDES' ELSE 'AUTRE' END
    FROM {{s}}dka_ipocde_hist_headers dih WHERE dih.creation_date > {FIN} - :histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, {JOUR_FR}), dih.file_name, 'RECEPTIONS'
    FROM {{s}}dka_iporec_hist_interface dih WHERE dih.creation_date > {FIN} - :histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, {JOUR_FR}), dih.file_name, 'DEBLOCAGE'
    FROM {{s}}dka_iapfac_debloc_hist_interf dih WHERE dih.creation_date > {FIN} - :histo
)
GROUP BY date_creation, jour_creation
ORDER BY date_creation DESC""", False),

    ("notilus", "NOTILUS — Notes de frais", f"""
SELECT TO_CHAR(TRUNC(creation_date), 'DD/MM/YY') AS DATE_CR,
       RTRIM(TO_CHAR(creation_date, {JOUR_FR})) AS JOUR,
       COUNT(*) AS NB_NDF, ROUND(SUM(invoice_amount)) AS MONTANT_TOT
FROM   {{s}}ap_invoices_all
WHERE  attribute9 = 'NOT' AND creation_date > {FIN} - :histo
GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, {JOUR_FR})
ORDER BY TRUNC(creation_date) DESC""", False),

    ("fact_source", "FACTURES — Synthèse par source", f"""
SELECT TO_CHAR(TO_DATE(date_creation, 'YYYYMMDD'), 'DD/MM/YY') AS DATE_CR,
       DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES') AS SOURCE,
       COUNT(*) AS NB_FACS
FROM   {{s}}dka_iapfacxgs_reporting_all
WHERE  TO_DATE(date_creation, 'YYYYMMDD') > {FIN} - :histo
GROUP BY date_creation, DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES')
ORDER BY date_creation DESC, SOURCE""", False),

    ("xerox_sans_img", "XEROX — Factures SANS images", f"""
SELECT dir.date_creation AS DATE_CR, NVL(dir.num_fact, '?') AS NUM_FACT,
       NVL(MIN(dir.reference_lad), '?') AS FICHIER,
       LISTAGG(aia.invoice_id, ',') WITHIN GROUP (ORDER BY aia.invoice_id) AS INVOICE_IDS
FROM   {{s}}dka_iapfacxgs_reporting_all dir
JOIN   {{s}}ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > {FIN} - 30
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR({DEB}, 'YYYYMMDD')
AND    NOT EXISTS (SELECT 1 FROM {{s}}fnd_documents fd
                   WHERE  fd.creation_date > {FIN} - 30
                   AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                           OR fd.file_name = aia.attribute3))
GROUP BY dir.date_creation, dir.num_fact
ORDER BY dir.num_fact""", True),

    ("xerox_avec_img", "XEROX — Factures AVEC images (compteur)", f"""
SELECT COUNT(DISTINCT dir.num_fact) AS NB_AVEC_IMG
FROM   {{s}}dka_iapfacxgs_reporting_all dir
JOIN   {{s}}ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > {FIN} - 30
JOIN   {{s}}fnd_documents fd ON fd.creation_date > {FIN} - 30
       AND (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3 OR fd.file_name = aia.attribute3)
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR({DEB}, 'YYYYMMDD')""", False),

    ("gl_interface", "GL — Interface (en attente)", f"""
SELECT SUBSTR(attribute10, 1, 40) AS SOURCE, SUBSTR(attribute9, 1, 15) AS TYPE_GL, status AS STATUS_GL,
       COUNT(*) AS NB_LIGNES, ROUND(SUM(entered_dr)) AS TOT_DEBIT, ROUND(SUM(entered_cr)) AS TOT_CREDIT,
       TO_CHAR(MIN(date_created), 'DD/MM/YY') AS PLUS_ANCIEN,
       TRUNC({FIN}) - TRUNC(MIN(date_created)) AS AGE_J
FROM   {{s}}gl_interface
GROUP BY attribute10, attribute9, status
ORDER BY MIN(date_created)""", False),

    ("gl_lignes", "GL — Lignes créées", f"""
SELECT TO_CHAR(TRUNC(creation_date), 'DD/MM/YY') AS DATE_CR, SUBSTR(attribute10, 1, 45) AS SOURCE,
       COUNT(*) AS NB_LIGNES, ROUND(SUM(entered_dr)) AS TOT_DEBIT
FROM   {{s}}gl_je_lines
WHERE  creation_date > {FIN} - :histo
GROUP BY TRUNC(creation_date), attribute10
ORDER BY TRUNC(creation_date) DESC, attribute10 DESC""", False),

    ("nuit_synthese", "NUIT — Synthèse par statut", f"""
SELECT CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN '*** ERREUR ***' WHEN 'G' THEN 'WARNING'
            WHEN 'R' THEN 'EN COURS' WHEN 'W' THEN 'EN ATTENTE' ELSE 'AUTRE (' || fcr.status_code || ')' END AS STATUT,
       COUNT(*) AS NB
FROM   {{s}}fnd_concurrent_requests fcr
{NUIT}
GROUP BY CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN '*** ERREUR ***' WHEN 'G' THEN 'WARNING'
              WHEN 'R' THEN 'EN COURS' WHEN 'W' THEN 'EN ATTENTE' ELSE 'AUTRE (' || fcr.status_code || ')' END
ORDER BY 1""", False),

    ("nuit_err_prog", "NUIT — Erreurs regroupées par programme", f"""
SELECT fcp.user_concurrent_program_name AS PROGRAMME, COUNT(*) AS NB_ERR,
       TO_CHAR(MIN(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS PREMIERE,
       TO_CHAR(MAX(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS DERNIERE,
       SUBSTR(MIN(fcr.completion_text), 1, 70) AS MSG
FROM   {{s}}fnd_concurrent_requests fcr
JOIN   {{s}}fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
{NUIT}
AND    fcr.status_code = 'E'
GROUP BY fcp.user_concurrent_program_name
ORDER BY COUNT(*) DESC""", True),

    ("nuit_err_detail", "NUIT — Détail des erreurs (30 plus récentes)", f"""
SELECT * FROM (
    SELECT fcr.request_id AS REQ_ID, fcp.user_concurrent_program_name AS PROGRAMME,
           TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS DEBUT,
           TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI:SS') AS FIN,
           ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS DUREE_MIN,
           SUBSTR(fcr.completion_text, 1, 70) AS MSG
    FROM   {{s}}fnd_concurrent_requests fcr
    JOIN   {{s}}fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
    {NUIT}
    AND    fcr.status_code = 'E'
    ORDER BY fcr.actual_start_date DESC
)
WHERE ROWNUM <= 30""", False),

    ("nuit_warnings", "NUIT — Détail des warnings", f"""
SELECT fcr.request_id AS REQ_ID, fcp.user_concurrent_program_name AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS DEBUT,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS DUREE_MIN,
       SUBSTR(fcr.completion_text, 1, 55) AS MSG
FROM   {{s}}fnd_concurrent_requests fcr
JOIN   {{s}}fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
{NUIT}
AND    fcr.status_code = 'G'
ORDER BY fcr.actual_start_date DESC""", True),

    ("nuit_longs", "NUIT — Traitements longs (> 30 min)", f"""
SELECT fcr.request_id AS REQ_ID, fcp.user_concurrent_program_name AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI') AS DEBUT,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI') AS FIN,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS DUREE_MIN,
       CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN 'ERREUR' WHEN 'G' THEN 'WARNING' ELSE fcr.status_code END AS STATUT
FROM   {{s}}fnd_concurrent_requests fcr
JOIN   {{s}}fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
{NUIT}
AND    (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 30
ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC""", False),

    ("nuit_en_cours", "NUIT — Traitements en cours (potentiellement bloqués)", f"""
SELECT fcr.request_id AS REQ_ID, fcp.user_concurrent_program_name AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS DEBUT,
       ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1) AS DUREE_MIN,
       SUBSTR(fcr.argument_text, 1, 50) AS PARAMETRES
FROM   {{s}}fnd_concurrent_requests fcr
JOIN   {{s}}fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= {DEB}
AND    fcr.requested_by IN (SELECT user_id FROM {{s}}fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'R'
ORDER BY fcr.actual_start_date""", True),

    ("rb", "Rapprochement bancaire (RB)", f"""
SELECT TO_CHAR(TRUNC(import_date), 'DD/MM/YY') AS DATE_CR,
       RTRIM(TO_CHAR(import_date, {JOUR_FR})) AS JOUR, COUNT(*) AS NB_CTES
FROM   {{s}}rb_batch_import
WHERE  import_date > {FIN} - :histo
GROUP BY TRUNC(import_date), TO_CHAR(import_date, {JOUR_FR})
ORDER BY TRUNC(import_date) DESC""", False),
]

# Compteurs de la SECTION 2 : (clé(s), sql). Une requête peut alimenter plusieurs compteurs.
SYNTHESE: list[tuple[tuple[str, ...], str]] = [
    (("nb_flux_dsp",), "SELECT COUNT(DISTINCT file_name) FROM (\n" + "\n    UNION ALL ".join(
        f"SELECT file_name FROM {{s}}{t} WHERE TRUNC(creation_date) = TRUNC({DEB})" for t in _DSP_TABLES) + ")"),
    (("nb_ndf",), f"""
SELECT COUNT(*) FROM {{s}}ap_invoices_all
WHERE attribute9 = 'NOT' AND TRUNC(creation_date) = TRUNC({DEB})"""),
    (("nb_fac_xerox", "nb_fac_tradeshift", "nb_fac_dsp"), f"""
SELECT NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'VE1' THEN 1 ELSE 0 END), 0),
       NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'L56' THEN 1 ELSE 0 END), 0),
       NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'DSP' THEN 1 ELSE 0 END), 0)
FROM   {{s}}dka_iapfacxgs_reporting_all
WHERE  date_creation = TO_CHAR({DEB}, 'YYYYMMDD')"""),
    (("nb_gl_interface",), f"SELECT COUNT(*) FROM {{s}}gl_interface WHERE date_created > TRUNC({DEB})"),
    (("nb_gl_lignes",), f"SELECT COUNT(*) FROM {{s}}gl_je_lines WHERE TRUNC(creation_date) = TRUNC({DEB})"),
    (("nb_traitements", "nb_erreurs", "nb_warnings"), f"""
SELECT COUNT(*),
       NVL(SUM(CASE WHEN fcr.status_code = 'E' THEN 1 ELSE 0 END), 0),
       NVL(SUM(CASE WHEN fcr.status_code = 'G' THEN 1 ELSE 0 END), 0)
FROM   {{s}}fnd_concurrent_requests fcr
{NUIT}"""),
    (("nb_rb_imports", "date_rb_max"), f"""
SELECT COUNT(*), MAX(TRUNC(import_date)) FROM {{s}}rb_batch_import
WHERE  TRUNC(import_date) IN (TRUNC({DEB}), TRUNC({FIN}))"""),
    (("nb_images_manq",), f"""
SELECT COUNT(DISTINCT dir.num_fact)
FROM   {{s}}dka_iapfacxgs_reporting_all dir
JOIN   {{s}}ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > {FIN} - 30
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR({DEB}, 'YYYYMMDD')
AND    NOT EXISTS (SELECT 1 FROM {{s}}fnd_documents fd
                   WHERE  fd.creation_date > {FIN} - 30
                   AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                           OR fd.file_name = aia.attribute3))"""),
]


def _binds(sql: str, params: dict) -> dict:
    """oracledb refuse les binds absents de la requête : on ne passe que ceux qu'elle utilise."""
    return {k: v for k, v in params.items() if f":{k}" in sql}
```

- [ ] **Step 4 : lancer, vérifier le succès**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_controle_matin.py -q`
Expected: `14 passed`.

- [ ] **Step 5 : vérifier que toutes les requêtes se formatent sans erreur**

Run:
```bash
cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -c "
import controle_matin as cm
for cle, _, sql, _ in cm.CATALOGUE: s = sql.format(s=''); assert ':debut' in s or ':fin' in s, cle
for cles, sql in cm.SYNTHESE: sql.format(s='')
print('format OK')"
```
Expected: `format OK` (une `KeyError`/`IndexError` signalerait une accolade non doublée).

- [ ] **Step 6 : commit**

```bash
git add odat_watch/controle_matin.py odat_watch/tests/test_controle_matin.py
git commit -m "ODAT Watch : moteur du contrôle du matin (catalogue SQL paramétré, règles de statut)

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4 : `controle_matin.py` — exécution, enrichissement job Control-M, historique, CLI

**Files:**
- Modify: `odat_watch/controle_matin.py` (ajout en fin de fichier)
- Test: `odat_watch/tests/test_controle_matin.py`, `odat_watch/tests/test_histo_matin.py`

- [ ] **Step 1 : tests de l'enrichissement et de l'historique**

Ajouter à la fin de `odat_watch/tests/test_controle_matin.py` :

```python
def test_enrichir_job_ajoute_le_job_controlm(tmp_path):
    import db
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO ora_requests(request_id, job_name) VALUES (101, 'FINFIN_J18TRT_04_IMP01_Q')")
    con.commit()
    df = pd.DataFrame({"REQ_ID": [101, 102], "PROGRAMME": ["A", "B"]})
    out = cm.enrichir_job(df, con)
    assert list(out.columns)[:2] == ["REQ_ID", "JOB_CTM"]
    assert out.loc[0, "JOB_CTM"] == "FINFIN_J18TRT_04_IMP01_Q"
    assert out.loc[1, "JOB_CTM"] == ""
    con.close()


def test_enrichir_job_sans_colonne_req_id_ne_change_rien(tmp_path):
    import db
    con = db.connect(tmp_path / "t.db")
    df = pd.DataFrame({"SOURCE": ["X"]})
    assert cm.enrichir_job(df, con).equals(df)
    con.close()
```

Ajouter à la fin de `odat_watch/tests/test_histo_matin.py` :

```python
import controle_matin as cm


def _resultat(executed_at, **maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0)
    c.update(maj)
    debut, fin = cm.plage_par_defaut(executed_at)
    return cm.Resultat(executed_at=executed_at, debut=debut, fin=fin, nb_jours_histo=3,
                       compteurs=c, statuts=cm.statuts(c), statut_global=cm.statut_global(c, []),
                       sections=[], duree_s=4.2)


def test_enregistrer_histo_et_relire(tmp_path):
    con = db.connect(tmp_path / "t.db")
    r = _resultat(datetime(2026, 9, 19, 7, 30))
    hid = cm.enregistrer_histo(r, con)
    assert r.histo_id == hid
    row = con.execute("SELECT date_ctrl, plage_debut, plage_fin, statut_global, nb_flux_dsp, duree_s "
                      "FROM controle_matin_histo").fetchone()
    assert tuple(row) == ("2026-09-19", "2026-09-18 19:00", "2026-09-19 07:00", "OK", 6, 4.2)
    cm.maj_fichier_rapport(hid, "rapports/Controle_Matin_20260919_0730.html", con)
    assert con.execute("SELECT fichier_rapport FROM controle_matin_histo").fetchone()[0].endswith("0730.html")
    con.close()


def test_delta_veille_compare_a_la_derniere_execution_d_un_jour_anterieur(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 17, 7, 0), nb_erreurs=5), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 7, 0), nb_erreurs=2), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 9, 0), nb_erreurs=1), con)   # relance le même jour
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 19, 7, 0), nb_erreurs=4), con)   # aujourd'hui, ignoré
    auj = _resultat(datetime(2026, 9, 19, 7, 30), nb_erreurs=4)
    d = cm.delta_veille(auj.compteurs, auj.date_ctrl, con)
    assert d["date"] == "2026-09-18"
    assert d["nb_erreurs"] == 3            # 4 - 1 (dernière exécution du 18)
    assert d["nb_flux_dsp"] == 0
    con.close()


def test_delta_veille_sans_historique(tmp_path):
    con = db.connect(tmp_path / "t.db")
    assert cm.delta_veille({"nb_erreurs": 1}, datetime(2026, 9, 19).date(), con) == {}
    con.close()


def test_historique_une_ligne_par_jour(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 7, 0), nb_erreurs=2), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 9, 0), nb_erreurs=1), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 19, 7, 0), nb_erreurs=0), con)
    h = cm.historique(3650, con)
    assert list(h["date_ctrl"]) == ["2026-09-18", "2026-09-19"]
    assert list(h["nb_erreurs"]) == [1, 0]
    assert list(h["statut_global"]) == ["ALERTE", "OK"]
    con.close()
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: FAIL — `AttributeError: module 'controle_matin' has no attribute 'enrichir_job'` (et `enregistrer_histo`, etc.).

- [ ] **Step 3 : ajouter exécution, historique et CLI**

Ajouter à la fin de `odat_watch/controle_matin.py` :

```python


# ------------------------------------------------------------------ exécution

def _lire_df(cur, sql: str, params: dict) -> pd.DataFrame:
    cur.execute(sql, _binds(sql, params))
    cols = [d[0] for d in cur.description]
    return pd.DataFrame.from_records(cur.fetchall(), columns=cols)


def enrichir_job(df: pd.DataFrame, con: sqlite3.Connection) -> pd.DataFrame:
    """Ajoute JOB_CTM (job Control-M connu d'ora_requests) juste après REQ_ID. Vide si inconnu."""
    if df is None or "REQ_ID" not in df.columns or df.empty:
        return df
    ids = [int(x) for x in df["REQ_ID"].dropna().unique()]
    q = ",".join("?" * len(ids))
    connus = {r[0]: r[1] or "" for r in con.execute(
        f"SELECT request_id, job_name FROM ora_requests WHERE request_id IN ({q})", ids)}
    out = df.copy()
    out.insert(1, "JOB_CTM", out["REQ_ID"].map(lambda x: connus.get(int(x), "") if pd.notna(x) else ""))
    return out


def executer(debut: datetime, fin: datetime, nb_jours_histo: int = 3) -> Resultat:
    """Lance la synthèse puis les 15 sections sur la plage [debut, fin[. Une section en échec n'arrête pas les autres."""
    if fin <= debut:
        raise ValueError("La fin de la plage doit être postérieure à son début.")
    cfg = load_config()
    s = _schema(cfg)
    params = {"debut": debut, "fin": fin, "histo": int(nb_jours_histo)}
    t0 = time.perf_counter()
    executed_at = datetime.now()
    compteurs: dict = {k: None for k in COMPTEURS}
    erreurs_synthese: dict = {}
    date_rb_max = None
    sections: list[Section] = []

    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        for cles, sql in SYNTHESE:
            sql = sql.format(s=s)
            try:
                cur.execute(sql, _binds(sql, params))
                row = cur.fetchone() or ()
                for cle, val in zip(cles, row):
                    if cle == "date_rb_max":
                        date_rb_max = val.date() if hasattr(val, "date") else val
                    else:
                        compteurs[cle] = int(val or 0)
            except Exception as e:  # noqa: BLE001 — on veut le message Oracle, quel qu'il soit
                for cle in cles:
                    if cle != "date_rb_max":
                        erreurs_synthese[cle] = str(e).strip()
        for cle, titre, sql, alerte_si_lignes in CATALOGUE:
            sec = Section(cle=cle, titre=titre)
            try:
                sec.df = _lire_df(cur, sql.format(s=s), params)
                sec.alerte = bool(alerte_si_lignes and not sec.df.empty)
            except Exception as e:  # noqa: BLE001
                sec.erreur = str(e).strip()
            sections.append(sec)

    con = connect()
    try:
        for sec in sections:
            if sec.cle in ("nuit_err_detail", "nuit_warnings", "nuit_longs", "nuit_en_cours"):
                sec.df = enrichir_job(sec.df, con)
        res = Resultat(executed_at=executed_at, debut=debut, fin=fin, nb_jours_histo=int(nb_jours_histo),
                       compteurs=compteurs, statuts=statuts(compteurs),
                       statut_global=statut_global(compteurs, sections), sections=sections,
                       duree_s=round(time.perf_counter() - t0, 1), date_rb_max=date_rb_max,
                       erreurs_synthese=erreurs_synthese)
        enregistrer_histo(res, con)
    finally:
        con.close()
    return res


# ------------------------------------------------------------------ historique SQLite

def enregistrer_histo(res: Resultat, con: sqlite3.Connection) -> int:
    cols = ["date_ctrl", "executed_at", "plage_debut", "plage_fin", "statut_global",
            *COMPTEURS, "duree_s", "fichier_rapport"]
    vals = [res.date_ctrl.strftime("%Y-%m-%d"), res.executed_at.strftime("%Y-%m-%d %H:%M:%S"),
            res.debut.strftime("%Y-%m-%d %H:%M"), res.fin.strftime("%Y-%m-%d %H:%M"), res.statut_global,
            *[res.compteurs.get(k) for k in COMPTEURS], res.duree_s, res.fichier_rapport]
    cur = con.execute(f"INSERT INTO controle_matin_histo({','.join(cols)}) VALUES ({','.join('?' * len(cols))})", vals)
    con.commit()
    res.histo_id = cur.lastrowid
    return res.histo_id


def maj_fichier_rapport(histo_id: int, fichier: str, con: sqlite3.Connection) -> None:
    con.execute("UPDATE controle_matin_histo SET fichier_rapport = ? WHERE id = ?", (fichier, histo_id))
    con.commit()


def delta_veille(compteurs: dict, date_ctrl: date, con: sqlite3.Connection) -> dict:
    """Écart de chaque compteur avec la dernière exécution d'un jour antérieur. {} si aucune."""
    row = con.execute(
        f"SELECT date_ctrl, {','.join(COMPTEURS)} FROM controle_matin_histo "
        "WHERE date_ctrl < ? ORDER BY executed_at DESC LIMIT 1", (date_ctrl.strftime("%Y-%m-%d"),)).fetchone()
    if row is None:
        return {}
    out = {"date": row[0]}
    for k in COMPTEURS:
        a, b = compteurs.get(k), row[k]
        if a is not None and b is not None:
            out[k] = a - b
    return out


def historique(jours: int, con: sqlite3.Connection) -> pd.DataFrame:
    """Une ligne par jour (dernière exécution du jour), sur les N derniers jours."""
    sql = f"""
    SELECT date_ctrl, executed_at, statut_global, {','.join(COMPTEURS)}
    FROM controle_matin_histo h
    WHERE executed_at = (SELECT MAX(executed_at) FROM controle_matin_histo WHERE date_ctrl = h.date_ctrl)
      AND date_ctrl >= date('now', ?)
    ORDER BY date_ctrl"""
    return pd.read_sql_query(sql, con, params=(f"-{int(jours)} days",))


# ------------------------------------------------------------------ ligne de commande

def _parse_dt(txt: str | None) -> datetime | None:
    return datetime.strptime(txt, "%Y-%m-%d %H:%M") if txt else None


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--debut", help='début de nuit "AAAA-MM-JJ HH:MM" (défaut hier 19:00)')
    ap.add_argument("--fin", help='fin de nuit "AAAA-MM-JJ HH:MM" (défaut aujourd\'hui 07:00)')
    ap.add_argument("--histo", type=int, default=3, help="jours d'historique (défaut 3)")
    ap.add_argument("--rapport", action="store_true", help="écrit aussi le rapport HTML dans rapports/")
    a = ap.parse_args()
    d0, f0 = plage_par_defaut(datetime.now())
    res = executer(_parse_dt(a.debut) or d0, _parse_dt(a.fin) or f0, a.histo)
    print(f"[{res.statut_global}] plage {res.debut:%d/%m %H:%M} → {res.fin:%d/%m %H:%M}, {res.duree_s} s")
    for k in COMPTEURS:
        v = res.compteurs.get(k)
        print(f"  {LIBELLES[k]:<26}: {'?' if v is None else v:>7}  [{res.statuts.get(k, '')}]")
    for sec in res.sections:
        if sec.erreur:
            print(f"  !! {sec.titre} : {sec.erreur}")
    if a.rapport:
        import rapport_matin
        chemin = rapport_matin.ecrire(res)
        con = connect()
        maj_fichier_rapport(res.histo_id, str(chemin), con)
        con.close()
        print(f"Rapport : {chemin}")
```

- [ ] **Step 4 : lancer, vérifier le succès**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: `21 passed`.

- [ ] **Step 5 : test de fumée sur Oracle (poste Dalkia, `config.ini` renseigné)**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe controle_matin.py`
Expected: ligne `[OK|WARNING|ALERTE|ERREUR] plage 18/09 19:00 → 19/09 07:00, N s`, 12 compteurs numériques, aucune ligne `!!`. Si une section affiche `ORA-00942`, vérifier le préfixe `schema` dans `config.ini [database]`. Si `ORA-00932` ou `ORA-01722` sur une borne, c'est le `CAST(:x AS DATE)` qui est en cause : le signaler. Si le poste n'a pas Oracle, noter l'étape comme non exécutée et continuer.

- [ ] **Step 6 : commit**

```bash
git add odat_watch/controle_matin.py odat_watch/tests/test_controle_matin.py odat_watch/tests/test_histo_matin.py
git commit -m "ODAT Watch : exécution du contrôle du matin, historique SQLite et CLI

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5 : `rapport_matin.py` — rapport HTML

**Files:**
- Create: `odat_watch/rapport_matin.py`
- Test: `odat_watch/tests/test_rapport_matin.py`

- [ ] **Step 1 : tests du rendu**

Fichier `odat_watch/tests/test_rapport_matin.py` :

```python
"""Rapport HTML du contrôle du matin : pur, sans Oracle ni SQLite."""
from datetime import date, datetime

import pandas as pd

import controle_matin as cm
import rapport_matin as rm


def _sections(**maj):
    out = [cm.Section(cle=cle, titre=titre, df=pd.DataFrame()) for cle, titre, _sql, _a in cm.CATALOGUE]
    for sec in out:
        if sec.cle in maj:
            v = maj[sec.cle]
            if isinstance(v, str):
                sec.erreur = v
            else:
                sec.df, sec.alerte = v, True
    return out


def _resultat(statut="OK", executed_at=datetime(2026, 9, 19, 7, 30), **maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0)
    debut, fin = cm.plage_par_defaut(executed_at)
    return cm.Resultat(executed_at=executed_at, debut=debut, fin=fin, nb_jours_histo=3,
                       compteurs=c, statuts=cm.statuts(c), statut_global=statut,
                       sections=_sections(**maj), duree_s=4.2, date_rb_max=date(2026, 9, 18))


def test_structure_generale():
    h = rm.construire(_resultat())
    assert h.count("<h2>") == 15
    assert "Contrôle quotidien FIN-FINANCE — 19/09/2026" in h
    assert "18/09/2026 19:00" in h and "19/09/2026 07:00" in h      # plage contrôlée
    assert 'class="bandeau ok"' in h
    assert "Aucune ligne" in h
    assert "Flux DSP (fichiers)" in h and "pill ok" in h


def test_bandeau_selon_statut():
    assert 'bandeau warn' in rm.construire(_resultat("WARNING"))
    assert 'bandeau ko' in rm.construire(_resultat("ALERTE"))
    assert 'bandeau ko' in rm.construire(_resultat("ERREUR"))


def test_tableau_et_echappement():
    df = pd.DataFrame({"REQ_ID": [1], "JOB_CTM": ["FINFIN_J18TRT_04_IMP01_Q"], "MSG": ["a < b & c"]})
    h = rm.construire(_resultat("ALERTE", nuit_err_detail=df))
    assert "<th>JOB_CTM</th>" in h
    assert "a &lt; b &amp; c" in h
    assert "a < b" not in h


def test_section_en_erreur_affiche_le_message_oracle():
    h = rm.construire(_resultat("ERREUR", rb="ORA-00942: table ou vue inexistante"))
    assert "ORA-00942" in h
    assert 'class="erreur"' in h


def test_rappel_lundi():
    lundi = datetime(2026, 9, 21, 7, 30)
    assert "fichier SG" in rm.construire(_resultat(executed_at=lundi))
    assert "fichier SG" not in rm.construire(_resultat())


def test_ecrire_nomme_le_fichier(tmp_path):
    p = rm.ecrire(_resultat(), tmp_path)
    assert p.name == "Controle_Matin_20260919_0730.html"
    assert p.read_text(encoding="utf-8").startswith("<!DOCTYPE html>")
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_rapport_matin.py -q`
Expected: FAIL — `ModuleNotFoundError: No module named 'rapport_matin'`.

- [ ] **Step 3 : écrire le module**

Fichier `odat_watch/rapport_matin.py` :

```python
"""Rapport HTML du contrôle du matin, dans la charte des Rapport_Verification_*.html
(cf. FichierControleFluxCoteUnix/rapport_reconciliation.py) : bandeau, tuiles, un tableau par section.

Module pur : il met en page un Resultat, ne lit ni Oracle ni SQLite.
"""
from __future__ import annotations
import html
from pathlib import Path

import pandas as pd

from controle_matin import COMPTEURS, LIBELLES, Resultat

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_RAPPORTS = BASE_DIR / "rapports"

JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

CLASSE_STATUT = {"OK": "ok", "WARNING": "warn", "ALERTE": "ko", "ERREUR": "ko"}
MESSAGE_STATUT = {
    "OK": "Tous les indicateurs sont au vert.",
    "WARNING": "Des indicateurs sont sous leur seuil ou des traitements sont en avertissement : à vérifier.",
    "ALERTE": "Traitements en erreur ou factures Xerox sans image : action requise.",
    "ERREUR": "Une partie du contrôle n'a pas pu être exécutée (erreur Oracle) : les compteurs concernés ne sont pas fiables.",
}

STYLE = """
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 22px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1700px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 15px 22px; border-radius: 6px;
       font-size: 1.22em; margin: 0 0 12px 0; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 30px; font-size: 1.04em; }
  .meta { background: #e8f0fe; border-left: 4px solid #003366; padding: 9px 15px;
          margin-bottom: 15px; border-radius: 0 4px 4px 0; font-size: .85em; }
  .meta span { margin-right: 20px; display: inline-block; }
  .bandeau { padding: 13px 19px; border-radius: 6px; margin-bottom: 16px; font-size: .92em; }
  .bandeau strong { display: block; font-size: 1.14em; margin-bottom: 3px; }
  .bandeau.ok   { background: #d7f2e3; color: #0b6b3a; border: 1px solid #7fc9a3; }
  .bandeau.warn { background: #fff4d6; color: #7a5600; border: 1px solid #e8c46a; }
  .bandeau.ko   { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; }
  .tiles { display: flex; flex-wrap: wrap; gap: 11px; margin-bottom: 8px; }
  .tile { flex: 1 1 145px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 13px 9px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.45em; font-weight: 700; line-height: 1.15; }
  .tn { font-size: .73em; color: #57606a; text-transform: uppercase; letter-spacing: .03em; margin-top: 4px; }
  table { border-collapse: collapse; width: 100%; background: #fff; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  th { background: #003366; color: #fff; padding: 9px 10px; text-align: left; font-size: .77em; white-space: nowrap; }
  td { padding: 6px 10px; border-bottom: 1px solid #eceff2; font-size: .81em; white-space: nowrap; }
  tr:nth-child(even) td { background: #fafbfc; }
  tr:hover td { background: #eef4fd; }
  td.num { text-align: right; font-variant-numeric: tabular-nums; }
  td:empty::after { content: '-'; color: #c9ced4; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px; font-size: .8em; font-weight: 600; margin-top: 4px; }
  .pill.ok   { background: #d7f2e3; color: #0b6b3a; }
  .pill.warn { background: #fff4d6; color: #7a5600; }
  .pill.ko   { background: #fbdcdc; color: #9b1c1c; }
  .vide { color: #8b949e; font-style: italic; font-size: .88em; padding: 8px 2px; }
  .erreur { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; border-radius: 6px;
            padding: 9px 14px; font-family: Consolas, Menlo, monospace; font-size: .82em; white-space: pre-wrap; }
  .footer { font-size: .76em; color: #8b949e; margin-top: 30px; text-align: center; }
  @media print { body { background: #fff; padding: 0; } }
"""


def _t(valeur) -> str:
    return html.escape("" if valeur is None or (isinstance(valeur, float) and pd.isna(valeur)) else str(valeur))


def _nb(valeur) -> str:
    if valeur is None:
        return "?"
    return format(int(valeur), ",").replace(",", " ")


def _tuile(cle: str, res: Resultat) -> str:
    val = res.compteurs.get(cle)
    if cle in res.erreurs_synthese:
        pill = '<span class="pill ko">non contrôlé</span>'
    elif cle in res.statuts:
        pill = f'<span class="pill {"ok" if res.statuts[cle] == "OK" else "warn"}">{res.statuts[cle]}</span>'
    elif cle in ("nb_erreurs", "nb_images_manq"):
        pill = f'<span class="pill {"ko" if (val or 0) > 0 else "ok"}">{"ALERTE" if (val or 0) > 0 else "OK"}</span>'
    elif cle == "nb_warnings":
        pill = f'<span class="pill {"warn" if (val or 0) > 0 else "ok"}">{"W" if (val or 0) > 0 else "OK"}</span>'
    else:
        pill = ""
    return (f'<div class="tile"><div class="tv">{_nb(val)}</div>'
            f'<div class="tn">{_t(LIBELLES[cle])}</div>{pill}</div>')


def _bandeau(res: Resultat) -> str:
    cls = CLASSE_STATUT.get(res.statut_global, "ko")
    rappel = ""
    if res.executed_at.weekday() == 0:
        rappel = ("<br><b>Rappel lundi :</b> charger manuellement le fichier SG (Société Générale), "
                  "les imports automatiques ne tournent pas le dimanche.")
    return (f'<div class="bandeau {cls}"><strong>Statut global : {_t(res.statut_global)}</strong>'
            f'{_t(MESSAGE_STATUT.get(res.statut_global, ""))}{rappel}</div>')


def _table(df: pd.DataFrame) -> str:
    if df is None or df.empty:
        return '<div class="vide">Aucune ligne.</div>'
    num = {c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])}
    head = "".join(f"<th>{_t(c)}</th>" for c in df.columns)
    rows = []
    for _, r in df.iterrows():
        cells = "".join(f'<td class="num">{_t(r[c])}</td>' if c in num else f"<td>{_t(r[c])}</td>" for c in df.columns)
        rows.append(f"<tr>{cells}</tr>")
    return f'<div class="tablewrap"><table><thead><tr>{head}</tr></thead><tbody>{"".join(rows)}</tbody></table></div>'


def construire(res: Resultat) -> str:
    d = res.executed_at
    meta = (f'<span>📅 {JOURS[d.weekday()].capitalize()} {d:%d/%m/%Y} à {d:%H:%M}</span>'
            f'<span>Plage contrôlée : {res.debut:%d/%m/%Y %H:%M} → {res.fin:%d/%m/%Y %H:%M}</span>'
            f'<span>Historique : {res.nb_jours_histo} j</span>'
            f'<span>Durée : {res.duree_s} s</span>')
    if res.date_rb_max:
        meta += f'<span>Dernier import RB : {res.date_rb_max:%d/%m/%Y}</span>'
    tuiles = "".join(_tuile(c, res) for c in COMPTEURS)
    corps = []
    for sec in res.sections:
        titre = _t(sec.titre) + (f' <span class="pill ko">{sec.nb}</span>' if sec.alerte else "")
        corps.append(f"<h2>{titre}</h2>")
        corps.append(f'<div class="erreur">{_t(sec.erreur)}</div>' if sec.erreur else _table(sec.df))
    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Contrôle quotidien FIN-FINANCE — {res.date_ctrl:%d/%m/%Y}</title>
<style>{STYLE}</style>
</head>
<body><div class="wrap">
<h1>Contrôle quotidien FIN-FINANCE — {res.date_ctrl:%d/%m/%Y}</h1>
<div class="meta">{meta}</div>
{_bandeau(res)}
<div class="tiles">{tuiles}</div>
{"".join(corps)}
<div class="footer">ODAT Watch · contrôle du matin · portage de Controle_Quotidien_Complet.sql</div>
</div></body>
</html>
"""


def ecrire(res: Resultat, dossier: Path | str = DOSSIER_RAPPORTS) -> Path:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    chemin = dossier / f"Controle_Matin_{res.executed_at:%Y%m%d_%H%M}.html"
    chemin.write_text(construire(res), encoding="utf-8")
    res.fichier_rapport = str(chemin)
    return chemin
```

- [ ] **Step 4 : lancer, vérifier le succès**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: `27 passed`.

- [ ] **Step 5 : commit**

```bash
git add odat_watch/rapport_matin.py odat_watch/tests/test_rapport_matin.py
git commit -m "ODAT Watch : rapport HTML du contrôle du matin

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6 : `planif_matin.py` — tâche planifiée Windows

**Files:**
- Create: `odat_watch/planif_matin.py`
- Test: `odat_watch/tests/test_planif_matin.py`

- [ ] **Step 1 : tests**

Fichier `odat_watch/tests/test_planif_matin.py` :

```python
"""Tâche planifiée Windows : construction de la commande et lecture de l'état, sans appeler schtasks."""
import subprocess

import pytest

import planif_matin as pm


def test_commande_create():
    cmd = pm.commande("07:15", python=r"C:\tmp\odatenv\Scripts\python.exe", script=r"C:\p\controle_matin.py")
    assert cmd[:2] == ["schtasks", "/Create"]
    assert cmd[cmd.index("/TN") + 1] == pm.NOM_TACHE
    assert cmd[cmd.index("/SC") + 1] == "DAILY"
    assert cmd[cmd.index("/ST") + 1] == "07:15"
    assert cmd[cmd.index("/TR") + 1] == r'"C:\tmp\odatenv\Scripts\python.exe" "C:\p\controle_matin.py" --rapport'
    assert "/F" in cmd


def test_commande_heure_invalide():
    with pytest.raises(ValueError):
        pm.commande("7h15")


CSV_FR = ('"Nom de l\'hôte","Nom de la tâche","Prochaine exécution","Statut","Mode d\'ouverture de session",'
          '"Dernière exécution","Dernier résultat","Auteur","Tâche à exécuter"\r\n'
          '"PC01","\\ODATWatch_ControleMatin","20/09/2026 07:15:00","Prêt","Interactif seulement",'
          '"19/09/2026 07:15:00","0","DALKIA\\samir","python controle_matin.py --rapport"\r\n')


def test_parse_etat_csv_par_position():
    e = pm._parse_etat(CSV_FR)
    assert e == {"prochaine": "20/09/2026 07:15:00", "statut": "Prêt",
                 "derniere": "19/09/2026 07:15:00", "dernier_resultat": "0"}


def test_etat_none_si_tache_absente(monkeypatch):
    def faux_run(*a, **k):
        return subprocess.CompletedProcess(a, 1, stdout="", stderr="ERREUR : le système ne trouve pas le fichier spécifié.")
    monkeypatch.setattr(subprocess, "run", faux_run)
    assert pm.etat() is None


def test_creer_leve_si_schtasks_echoue(monkeypatch):
    def faux_run(*a, **k):
        return subprocess.CompletedProcess(a, 1, stdout="", stderr="ERREUR : accès refusé.")
    monkeypatch.setattr(subprocess, "run", faux_run)
    with pytest.raises(RuntimeError, match="accès refusé"):
        pm.creer("07:15")
```

- [ ] **Step 2 : lancer, vérifier l'échec**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests/test_planif_matin.py -q`
Expected: FAIL — `ModuleNotFoundError: No module named 'planif_matin'`.

- [ ] **Step 3 : écrire le module**

Fichier `odat_watch/planif_matin.py` :

```python
"""Programmation du contrôle du matin via le Planificateur de tâches Windows (schtasks).

La tâche lance chaque jour `python controle_matin.py --rapport` : contrôle + HTML + historique,
que l'application soit ouverte ou non. Le poste doit être allumé et la session ouverte à l'heure dite.
"""
from __future__ import annotations
import csv
import io
import re
import subprocess
import sys
from pathlib import Path

NOM_TACHE = "ODATWatch_ControleMatin"
SCRIPT = Path(__file__).resolve().parent / "controle_matin.py"
_HEURE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def commande(heure: str, python: str | None = None, script: str | Path | None = None) -> list[str]:
    """Arguments de `schtasks /Create` pour une exécution quotidienne à HH:MM."""
    if not _HEURE.match(heure):
        raise ValueError(f"Heure attendue au format HH:MM, reçu {heure!r}")
    py = python or sys.executable
    sc = str(script or SCRIPT)
    return ["schtasks", "/Create", "/TN", NOM_TACHE, "/SC", "DAILY", "/ST", heure,
            "/TR", f'"{py}" "{sc}" --rapport', "/F"]


def _run(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(args, capture_output=True, text=True, encoding="cp850", errors="replace")


def creer(heure: str) -> str:
    r = _run(commande(heure))
    if r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or f"schtasks a renvoyé {r.returncode}")
    return r.stdout.strip()


def supprimer() -> str:
    r = _run(["schtasks", "/Delete", "/TN", NOM_TACHE, "/F"])
    if r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or f"schtasks a renvoyé {r.returncode}")
    return r.stdout.strip()


def _parse_etat(texte_csv: str) -> dict | None:
    """Sortie de `schtasks /Query /FO CSV /V`, lue par position : les en-têtes dépendent de la langue."""
    lignes = list(csv.reader(io.StringIO(texte_csv)))
    if len(lignes) < 2 or len(lignes[1]) < 7:
        return None
    l = lignes[1]
    return {"prochaine": l[2], "statut": l[3], "derniere": l[5], "dernier_resultat": l[6]}


def etat() -> dict | None:
    """None si la tâche n'existe pas."""
    r = _run(["schtasks", "/Query", "/TN", NOM_TACHE, "/FO", "CSV", "/V"])
    if r.returncode != 0:
        return None
    return _parse_etat(r.stdout)
```

- [ ] **Step 4 : lancer, vérifier le succès**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: `32 passed`.

- [ ] **Step 5 : essai réel (poste Windows)**

Run:
```bash
cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -c "
import planif_matin as pm
print(pm.creer('07:15')); print(pm.etat()); print(pm.supprimer()); print(pm.etat())"
```
Expected: `Opération réussie…`, un dict avec `prochaine` = demain 07:15:00, `Opération réussie…`, puis `None`. Si `creer` lève « accès refusé », la stratégie du poste interdit schtasks : le noter, l'UI affichera la commande à exécuter manuellement.

- [ ] **Step 6 : commit**

```bash
git add odat_watch/planif_matin.py odat_watch/tests/test_planif_matin.py
git commit -m "ODAT Watch : programmation du contrôle du matin via schtasks

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7 : onglet Streamlit « ☀️ Matin »

**Files:**
- Create: `odat_watch/ui_matin.py`
- Modify: `odat_watch/app.py:243-252` (déclaration des onglets et branchement)

- [ ] **Step 1 : écrire le module d'interface**

Fichier `odat_watch/ui_matin.py` :

```python
"""Onglet Matin : contrôle quotidien à la demande sur une plage date+heure, rapport HTML,
programmation quotidienne, tendance."""
from __future__ import annotations
import subprocess
from datetime import datetime, time as dtime
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
import streamlit as st

import controle_matin as cm
import planif_matin as pm
import rapport_matin as rm
from db import connect
from oracle_refresh import CONFIG

AFFICHE = {"OK": st.success, "WARNING": st.warning, "ALERTE": st.error, "ERREUR": st.error}
# Palette des KPI de app.py (ok / warn / err / run) + violet pour les images manquantes.
COULEURS = {"nb_erreurs": "#D23F31", "nb_warnings": "#D9A400", "nb_images_manq": "#7B3FBF", "nb_flux_dsp": "#2F6FED"}
COULEUR_STATUT = {"OK": "#1F9D55", "WARNING": "#D9A400", "ALERTE": "#D23F31", "ERREUR": "#8A94A6"}


def _delta_txt(delta: dict, cle: str) -> str:
    if cle not in delta:
        return ""
    d = delta[cle]
    j = datetime.strptime(delta["date"], "%Y-%m-%d").strftime("%d/%m")
    return f" · {d:+d} vs {j}" if d else f" · = {j}"


def _ton_tuile(res: cm.Resultat, cle: str) -> str:
    v = res.compteurs.get(cle)
    if cle in res.erreurs_synthese or v is None:
        return "err"
    if cle in res.statuts:
        return "ok" if res.statuts[cle] == "OK" else "warn"
    if cle in ("nb_erreurs", "nb_images_manq"):
        return "err" if v > 0 else "ok"
    if cle == "nb_warnings":
        return "warn" if v > 0 else "ok"
    return "neutral"


def _bouton_telecharger(chemin: Path, cle: str, libelle: str = "⬇ Télécharger"):
    st.download_button(libelle, data=chemin.read_bytes(), file_name=chemin.name, mime="text/html", key=cle)


def render(now: datetime, kpi):
    if not CONFIG.exists():
        st.info("Renseignez `config.ini` (copie de `config.ini.exemple`, section `[database]`) pour lancer le contrôle du matin.")
        return

    d0, f0 = cm.plage_par_defaut(now)
    gauche, droite = st.columns([3, 2])
    with gauche:
        st.markdown("#### Plage contrôlée")
        c1, c2, c3, c4, c5 = st.columns([1.2, 0.8, 1.2, 0.8, 0.8])
        j_deb = c1.date_input("Début de nuit", d0.date(), key="m_jd")
        h_deb = c2.time_input("Heure", dtime(19, 0), key="m_hd", step=900)
        j_fin = c3.date_input("Fin de nuit", f0.date(), key="m_jf")
        h_fin = c4.time_input("Heure ", dtime(7, 0), key="m_hf", step=900)
        histo = c5.number_input("Histo (j)", 1, 30, 3)
        debut, fin = datetime.combine(j_deb, h_deb), datetime.combine(j_fin, h_fin)
        st.caption(f"Traitements de nuit du {debut:%d/%m %H:%M} au {fin:%d/%m %H:%M} · veille = {debut:%d/%m} · jour = {fin:%d/%m}")
        if st.button("▶ Lancer le contrôle", type="primary", use_container_width=True):
            if fin <= debut:
                st.error("La fin de la plage doit être après son début.")
            else:
                with st.spinner("Contrôles en cours sur Oracle…"):
                    try:
                        st.session_state["matin"] = cm.executer(debut, fin, int(histo))
                        st.session_state.pop("matin_rapport", None)
                    except Exception as e:  # noqa: BLE001 — connexion Oracle, config : on affiche tel quel
                        st.error(f"Contrôle impossible : {e}")
    with droite:
        _bloc_programmer()

    res: cm.Resultat | None = st.session_state.get("matin")
    if res is None:
        st.caption("Aucune exécution dans cette session. Les rapports déjà générés sont listés en bas de page.")
        _anciens_rapports()
        con = connect()
        _tendance(con)
        con.close()
        return

    AFFICHE[res.statut_global](f"**Statut global : {res.statut_global}** — {rm.MESSAGE_STATUT[res.statut_global]}  \n"
                               f"Plage {res.debut:%d/%m %H:%M} → {res.fin:%d/%m %H:%M}, exécuté le "
                               f"{res.executed_at:%d/%m/%Y à %H:%M} en {res.duree_s} s.")
    if res.executed_at.weekday() == 0:
        st.warning("**Rappel lundi :** charger manuellement le fichier SG (Société Générale).", icon="🏦")
    if res.erreurs_synthese:
        st.error("Compteurs non contrôlés : " + ", ".join(cm.LIBELLES[k] for k in res.erreurs_synthese))

    con = connect()
    delta = cm.delta_veille(res.compteurs, res.date_ctrl, con)
    cols = st.columns(6)
    for i, cle in enumerate(cm.COMPTEURS):
        v = res.compteurs.get(cle)
        kpi(cols[i % 6], "?" if v is None else v, cm.LIBELLES[cle] + _delta_txt(delta, cle), _ton_tuile(res, cle))
    if res.date_rb_max:
        st.caption(f"Dernier import RB : {res.date_rb_max:%d/%m/%Y}")

    st.markdown("#### Détail des contrôles")
    for sec in res.sections:
        titre = f"{'🔴 ' if sec.erreur else '⚠️ ' if sec.alerte else ''}{sec.titre} — {sec.nb} ligne(s)"
        with st.expander(titre, expanded=bool(sec.alerte or sec.erreur)):
            if sec.erreur:
                st.error(sec.erreur)
            elif sec.df is None or sec.df.empty:
                st.caption("Aucune ligne.")
            else:
                st.dataframe(sec.df, use_container_width=True, hide_index=True)

    st.markdown("#### Rapport")
    r1, r2 = st.columns([1, 3])
    if r1.button("📄 Générer le rapport HTML", use_container_width=True):
        try:
            chemin = rm.ecrire(res)
            if res.histo_id:
                cm.maj_fichier_rapport(res.histo_id, str(chemin), con)
            st.session_state["matin_rapport"] = str(chemin)
        except OSError as e:
            st.error(f"Écriture du rapport impossible : {e}")
    if st.session_state.get("matin_rapport"):
        chemin = Path(st.session_state["matin_rapport"])
        with r2:
            st.caption(f"Rapport écrit : `{chemin}`")
            _bouton_telecharger(chemin, "dl_courant")

    _anciens_rapports()
    _tendance(con)
    con.close()


def _bloc_programmer():
    st.markdown("#### ⏰ Programmer chaque matin")
    etat = pm.etat()
    if etat:
        st.success(f"Tâche **{pm.NOM_TACHE}** active — prochaine : {etat['prochaine']} · "
                   f"dernière : {etat['derniere'] or '—'} (résultat {etat['dernier_resultat']})", icon="✅")
    else:
        st.caption("Aucune tâche planifiée. La tâche lance `controle_matin.py --rapport` (plage par défaut 19h → 7h), "
                   "poste allumé et session ouverte.")
    c1, c2, c3 = st.columns([1, 1.2, 1])
    heure = c1.time_input("Heure", dtime(7, 15), key="m_hp", step=900)
    if c2.button("Programmer", use_container_width=True, type="secondary"):
        try:
            pm.creer(heure.strftime("%H:%M"))
            st.rerun()
        except (RuntimeError, OSError, subprocess.SubprocessError) as e:
            st.error(f"schtasks a échoué : {e}")
            st.code(subprocess.list2cmdline(pm.commande(heure.strftime("%H:%M"))), language="bat")
    if c3.button("Supprimer", use_container_width=True, disabled=etat is None):
        try:
            pm.supprimer()
            st.rerun()
        except (RuntimeError, OSError, subprocess.SubprocessError) as e:
            st.error(f"schtasks a échoué : {e}")


def _anciens_rapports():
    fichiers = sorted(rm.DOSSIER_RAPPORTS.glob("Controle_Matin_*.html"), reverse=True)[:10] if rm.DOSSIER_RAPPORTS.exists() else []
    if not fichiers:
        return
    with st.expander(f"Rapports précédents ({len(fichiers)})"):
        for f in fichiers:
            a, b = st.columns([3, 1])
            a.write(f.name)
            with b:
                _bouton_telecharger(f, f"dl_{f.stem}")


def _tendance(con):
    h = cm.historique(30, con)
    if len(h) < 2:
        return
    st.markdown("#### Tendance 30 jours")
    h["date_ctrl"] = pd.to_datetime(h["date_ctrl"])
    fig = go.Figure()
    for cle, couleur in COULEURS.items():
        fig.add_trace(go.Scatter(x=h["date_ctrl"], y=h[cle], name=cm.LIBELLES[cle], mode="lines+markers",
                                 line=dict(color=couleur, width=2.5, shape="spline", smoothing=0.6),
                                 marker=dict(size=7, color=couleur, line=dict(width=1, color="white")),
                                 hovertemplate="%{x|%d/%m}<br>%{y}<extra>" + cm.LIBELLES[cle] + "</extra>"))
    fig.add_trace(go.Scatter(x=h["date_ctrl"], y=[0] * len(h), mode="markers", name="statut du jour",
                             marker=dict(size=13, symbol="square", color=[COULEUR_STATUT.get(s, "#8A94A6") for s in h["statut_global"]],
                                         line=dict(width=1, color="white")),
                             hovertemplate="%{x|%d/%m} : %{text}<extra></extra>", text=h["statut_global"]))
    fig.update_layout(height=340, margin=dict(l=10, r=10, t=10, b=10), template="plotly_white",
                      legend=dict(orientation="h", y=1.08), hovermode="x unified",
                      xaxis=dict(tickformat="%d/%m", showgrid=False), yaxis=dict(rangemode="tozero", gridcolor="#EEF1F5"))
    st.plotly_chart(fig, use_container_width=True)
```

- [ ] **Step 2 : brancher l'onglet dans `app.py`**

Dans `odat_watch/app.py`, remplacer :

```python
tab_soir, tab_demain, tab_now, tab_ora, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "🅾 Oracle", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])

with tab_ora:
    import ui_oracle
    ui_oracle.render(application, recherche, now, kpi, badge)
```

par :

```python
tab_soir, tab_demain, tab_now, tab_matin, tab_ora, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "☀️ Matin", "🅾 Oracle", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])

with tab_matin:
    import ui_matin
    ui_matin.render(now, kpi)

with tab_ora:
    import ui_oracle
    ui_oracle.render(application, recherche, now, kpi, badge)
```

- [ ] **Step 3 : vérifier que l'app démarre et que l'onglet s'affiche**

Run (en arrière-plan) : `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m streamlit run app.py --server.headless true --browser.gatherUsageStats false`
Puis : `curl -s -o /dev/null -w "%{http_code}" http://localhost:8501` → `200`.
Ouvrir http://localhost:8501, cliquer « ☀️ Matin » : les sélecteurs date/heure (hier 19:00 → aujourd'hui 07:00), le bouton « ▶ Lancer le contrôle » et le bloc « ⏰ Programmer chaque matin » s'affichent. Aucune exception dans le terminal Streamlit. Faire une capture d'écran et la regarder.

- [ ] **Step 4 : sur le poste Dalkia, lancer un contrôle depuis l'onglet**

Cliquer « ▶ Lancer le contrôle » : bandeau de statut, 12 tuiles, 15 expanders (ceux en alerte ouverts), puis « 📄 Générer le rapport HTML » : un fichier `odat_watch/rapports/Controle_Matin_AAAAMMJJ_HHMM.html` apparaît et le bouton de téléchargement fonctionne. Ouvrir le HTML dans un navigateur et vérifier visuellement bandeau, tuiles, tableaux. Changer la date de début à avant-hier, relancer : la plage affichée dans le bandeau suit.

- [ ] **Step 5 : relancer la suite de tests**

Run: `cd odat_watch && /c/tmp/odatenv/Scripts/python.exe -m pytest tests -q`
Expected: `32 passed`.

- [ ] **Step 6 : commit**

```bash
git add odat_watch/ui_matin.py odat_watch/app.py
git commit -m "ODAT Watch : onglet Matin (plage libre, rapport HTML, programmation, tendance)

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8 : documentation et validation croisée

**Files:**
- Modify: `odat_watch/README.md` (tableau des fichiers, ligne `app.py`, nouvelle section)

- [ ] **Step 1 : documenter les modules dans le README**

Dans le tableau des fichiers de `odat_watch/README.md`, après la ligne `| ui_oracle.py | Onglet Oracle de l'interface. |`, ajouter :

```markdown
| `controle_matin.py` | **Contrôle du matin** : portage `oracledb` des 15 contrôles de `ControleMatinGenerique/Controle_Quotidien_Complet.sql` (DSP, Notilus, factures Xerox/Tradeshift, GL, traitements de la nuit, RB) sur une plage date+heure libre. Calcule les statuts OK/W et le statut global, historise la synthèse dans `controle_matin_histo`. Aussi en ligne de commande (`--rapport`). Le `.sql` reste la référence : toute évolution métier se fait d'abord là, puis se reporte ici. |
| `rapport_matin.py` | Rapport HTML du contrôle du matin (charte des `Rapport_Verification_*.html`), écrit dans `rapports/` (ignoré par git). |
| `planif_matin.py` | Tâche du Planificateur Windows `ODATWatch_ControleMatin` (`schtasks`) qui lance `controle_matin.py --rapport` chaque matin. |
| `ui_matin.py` | Onglet Matin : plage date+heure, bandeau, tuiles avec écart vs. veille, détail par section, génération/téléchargement du rapport, programmation, tendance 30 jours. |
```

Remplacer la ligne `| app.py | Interface Streamlit : Ce soir, Demain, Maintenant, Oracle, Historique, Profils, Données, SQL. |` par :

```markdown
| `app.py` | Interface Streamlit : Ce soir, Demain, Maintenant, Matin, Oracle, Historique, Profils, Données, SQL. |
```

Ajouter en fin de README :

```markdown
## Contrôle du matin

Onglet **☀️ Matin** : choisir la plage de nuit (défaut hier 19:00 → aujourd'hui 07:00 ; modifiable pour rejouer un
matin passé), « ▶ Lancer le contrôle » exécute les mêmes requêtes que `ControleMatinGenerique\Lancer_Controle_Quotidien.ps1`,
puis « 📄 Générer le rapport HTML » produit `rapports\Controle_Matin_AAAAMMJJ_HHMM.html` à joindre au mail.
« ⏰ Programmer » crée une tâche Windows quotidienne (`schtasks`) qui fait la même chose sans ouvrir l'application.
Les compteurs de la synthèse sont historisés dans `controle_matin_histo` (tuiles : écart vs. veille, tendance 30 j).

En ligne de commande : `python controle_matin.py [--debut "AAAA-MM-JJ HH:MM"] [--fin "..."] [--histo 3] [--rapport]`.

Tests : `python -m pytest tests -q` (sans Oracle). Validation métier : lancer l'onglet et le `.ps1` le même matin,
les compteurs de la « SYNTHESE DU JOUR » doivent coïncider.
```

- [ ] **Step 2 : validation croisée avec le `.ps1` (poste Dalkia)**

Run: `powershell -File ..\ControleMatinGenerique\Lancer_Controle_Quotidien.ps1` puis relire le log `ControleMatinGenerique\Logs\Controle_*.log` le plus récent, bloc « SYNTHESE DU JOUR ». Comparer aux 12 tuiles de l'onglet lancé dans les mêmes minutes avec la plage par défaut.
Expected: mêmes valeurs (à une exécution près si un traitement se termine entre les deux). Un écart systématique sur un compteur signale une différence de requête : corriger `SYNTHESE` dans `controle_matin.py` à partir du `.sql`.

- [ ] **Step 3 : commit**

```bash
git add odat_watch/README.md
git commit -m "ODAT Watch : documentation du contrôle du matin

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Auto-revue du plan

- **Couverture de la spec** : plage date+heure libre et binds `:debut/:fin/:histo` (T3, T4, T7), moteur et statuts (T3), exécution par section avec `try/except` (T4), enrichissement job Control-M (T4), table SQLite avec `plage_debut/plage_fin` (T2, T4), delta veille et historique (T4), CLI (T4), rapport HTML avec plage affichée (T5), tâche Windows `commande/creer/supprimer/etat` et repli sur la commande à copier (T6, T7), onglet complet avec Plotly coloré (T7), gestion des erreurs connexion/section/rapport/schtasks (T4, T7), tests sans Oracle (T2–T6), validation manuelle contre le `.ps1` (T8), `.gitignore` (T1), README (T8). Hors périmètre respecté (pas de mail).
- **Cohérence des noms** : `Section(cle, titre, df, erreur, alerte)`, `Resultat(executed_at, debut, fin, nb_jours_histo, compteurs, statuts, statut_global, sections, duree_s, date_rb_max, erreurs_synthese, fichier_rapport, histo_id)` + propriété `date_ctrl`, `plage_par_defaut`, `CATALOGUE`, `SYNTHESE`, `COMPTEURS`, `LIBELLES`, `DEB/FIN/NUIT`, `_binds`, `statuts`, `statut_global`, `executer(debut, fin, nb_jours_histo)`, `enrichir_job`, `enregistrer_histo`, `maj_fichier_rapport`, `delta_veille(compteurs, date_ctrl, con)`, `historique(jours, con)`, `rm.construire/ecrire/DOSSIER_RAPPORTS/MESSAGE_STATUT`, `pm.NOM_TACHE/commande/creer/supprimer/etat/_parse_etat` — identiques dans les tests, `rapport_matin.py`, `planif_matin.py` et `ui_matin.py`.
- **Compteurs de tests attendus** : T2 → 1 ; T3 → 14 (fichier seul) ; T4 → 21 ; T5 → 27 ; T6 → 32 ; T7 → 32.
