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
import re
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
    presents = set(re.findall(r"(?<!:):(\w+)", sql))
    return {k: v for k, v in params.items() if k in presents}


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
