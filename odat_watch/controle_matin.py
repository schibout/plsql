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
