# -*- coding: utf-8 -*-
"""
=====================================================================
Rapport de Contrôle Quotidien - Génération PDF
=====================================================================
Date de création : 06/02/2026
Auteur          : Copilot
Base de données : Oracle EBS 12.2.13

OBJECTIF : Exécuter les requêtes de contrôle quotidien sur la base
           Oracle EBS et générer un rapport PDF structuré.

SECTIONS DU RAPPORT :
  1. Synthèse globale (tableau de bord avec statuts OK/Warning)
  2. Flux DSP (iValua) - Détail et synthèse par jour
  3. Notes de frais (Notilus)
  4. Factures (Xerox, Tradeshift, DSP) + images manquantes
  5. Écritures GL (Interface + lignes créées)
  6. Traitements de la nuit (erreurs, warnings, longs, en cours)
  7. Rapprochement bancaire (RB)

USAGE :
  python rapport_quotidien.py
  python rapport_quotidien.py --date 2026-02-05
  python rapport_quotidien.py --config config.ini
=====================================================================
"""

import os
import sys
import argparse
import configparser
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Tuple

# --- Dépendances externes ---
try:
    import oracledb
except ImportError:
    print("ERREUR: Package 'oracledb' non installé. Exécuter : pip install oracledb")
    sys.exit(1)

try:
    from fpdf import FPDF
except ImportError:
    print("ERREUR: Package 'fpdf2' non installé. Exécuter : pip install fpdf2")
    sys.exit(1)


# =========================================================================
# SECTION 1 : CONFIGURATION ET PARAMÈTRES
# =========================================================================

@dataclass
class Config:
    """Paramètres de configuration du rapport."""

    # --- Connexion Oracle ---
    db_user: str = ""
    db_password: str = ""
    db_dsn: str = ""  # host:port/service_name

    # --- Paramètres métier (miroir du SQL) ---
    nb_jours_histo: int = 3
    heure_fermeture: int = 19  # Début plage nuit (19h)
    heure_ouverture: int = 7   # Fin plage nuit (7h)
    seuil_traitement_long_min: int = 30  # Minutes

    # --- Seuils d'alerte ---
    nb_flux_dsp_attendus: int = 5  # Jours ouvrés
    nb_fichiers_factures_attendus: int = 3  # Xerox + Tradeshift + DSP

    # --- Sortie ---
    output_dir: str = "."
    output_filename: str = ""  # Auto-généré si vide

    def __post_init__(self):
        if not self.output_filename:
            self.output_filename = f"Controle_Quotidien_{datetime.now().strftime('%Y%m%d_%H%M')}.pdf"


def load_config(config_path: Optional[str] = None) -> Config:
    """Charge la configuration depuis un fichier INI ou les variables d'environnement."""
    cfg = Config()

    if config_path and os.path.exists(config_path):
        parser = configparser.ConfigParser()
        parser.read(config_path, encoding="utf-8")

        if parser.has_section("database"):
            cfg.db_user = parser.get("database", "user", fallback=cfg.db_user)
            cfg.db_password = parser.get("database", "password", fallback=cfg.db_password)
            cfg.db_dsn = parser.get("database", "dsn", fallback=cfg.db_dsn)

        if parser.has_section("parametres"):
            cfg.nb_jours_histo = parser.getint("parametres", "nb_jours_histo", fallback=cfg.nb_jours_histo)
            cfg.heure_fermeture = parser.getint("parametres", "heure_fermeture", fallback=cfg.heure_fermeture)
            cfg.heure_ouverture = parser.getint("parametres", "heure_ouverture", fallback=cfg.heure_ouverture)
            cfg.seuil_traitement_long_min = parser.getint("parametres", "seuil_long_min", fallback=cfg.seuil_traitement_long_min)

        if parser.has_section("sortie"):
            cfg.output_dir = parser.get("sortie", "output_dir", fallback=cfg.output_dir)
            cfg.output_filename = parser.get("sortie", "output_filename", fallback=cfg.output_filename)
    else:
        # Fallback : variables d'environnement
        cfg.db_user = os.environ.get("ORACLE_USER", cfg.db_user)
        cfg.db_password = os.environ.get("ORACLE_PASSWORD", cfg.db_password)
        cfg.db_dsn = os.environ.get("ORACLE_DSN", cfg.db_dsn)

    return cfg


# =========================================================================
# SECTION 2 : MODÈLES DE DONNÉES (résultats des requêtes)
# =========================================================================

@dataclass
class SyntheseGlobale:
    """Résultats de la synthèse du jour."""
    date_controle: str = ""
    jour_semaine: str = ""
    nb_flux_dsp: int = 0
    nb_ndf: int = 0
    nb_fac_xerox: int = 0
    nb_fac_tradeshift: int = 0
    nb_fac_dsp: int = 0
    nb_gl_interface: int = 0
    nb_gl_lignes: int = 0
    nb_traitements_nuit: int = 0
    nb_erreurs: int = 0
    nb_warnings: int = 0
    nb_rb_imports: int = 0
    nb_images_manquantes: int = 0

    def statut_flux_dsp(self) -> str:
        return "OK" if self.nb_flux_dsp >= 5 else "⚠"

    def statut_ndf(self) -> str:
        return "OK" if self.nb_ndf > 0 else "⚠"

    def statut_xerox(self) -> str:
        return "OK" if self.nb_fac_xerox > 0 else "⚠"

    def statut_tradeshift(self) -> str:
        return "OK" if self.nb_fac_tradeshift > 0 else "⚠"

    def statut_gl(self) -> str:
        return "OK" if self.nb_gl_lignes > 0 else "⚠"

    def statut_rb(self) -> str:
        return "OK" if self.nb_rb_imports > 0 else "⚠"


@dataclass
class FluxDSP:
    """Un fichier de flux DSP."""
    date_creation: str = ""
    jour: str = ""
    type_flux: str = ""
    file_name: str = ""


@dataclass
class NoteDeFrais:
    """Comptage notes de frais par jour."""
    date_creation: str = ""
    jour: str = ""
    nb_ndf: int = 0
    montant_total: float = 0.0


@dataclass
class Facture:
    """Comptage factures par source et jour."""
    date_creation: str = ""
    source: str = ""
    nb_factures: int = 0


@dataclass
class ImageManquante:
    """Facture Xerox sans image associée."""
    date_creation: str = ""
    num_fact: str = ""
    reference_lad: str = ""
    invoice_id: int = 0
    vendor_id: int = 0


@dataclass
class EcritureGL:
    """Ligne GL interface ou créée."""
    date_creation: str = ""
    source: str = ""
    type_gl: str = ""
    status: str = ""
    nb_lignes: int = 0
    total_debit: float = 0.0
    total_credit: float = 0.0


@dataclass
class TraitementNuit:
    """Un traitement concurrent de la nuit."""
    request_id: int = 0
    programme: str = ""
    debut: str = ""
    fin: str = ""
    duree_min: float = 0.0
    statut: str = ""
    message: str = ""
    parametres: str = ""


# =========================================================================
# SECTION 3 : REQUÊTES SQL
# =========================================================================

class RequetesSQL:
    """Centralise toutes les requêtes SQL du contrôle quotidien.
    
    Chaque méthode retourne le texte SQL avec des bind variables (:param).
    """

    @staticmethod
    def flux_dsp_detail(nb_jours: int) -> str:
        """Détail des fichiers DSP reçus sur les N derniers jours."""
        return """
            SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
                   TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
                   'FOURNISSEURS' AS type_flux,
                   dih.file_name
            FROM   dka_ipofrs_hist_entetes dih
            WHERE  dih.creation_date > SYSDATE - :nb_jours
            UNION ALL
            SELECT DISTINCT TRUNC(dih.creation_date),
                   TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
                   'COMMANDES',
                   dih.file_name
            FROM   dka_ipocde_hist_headers dih
            WHERE  dih.creation_date > SYSDATE - :nb_jours
            UNION ALL
            SELECT DISTINCT TRUNC(dih.creation_date),
                   TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
                   'RECEPTIONS',
                   dih.file_name
            FROM   dka_iporec_hist_interface dih
            WHERE  dih.creation_date > SYSDATE - :nb_jours
            UNION ALL
            SELECT DISTINCT TRUNC(dih.creation_date),
                   TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
                   'DEBLOCAGE',
                   dih.file_name
            FROM   dka_iapfac_debloc_hist_interf dih
            WHERE  dih.creation_date > SYSDATE - :nb_jours
            ORDER BY 1 DESC, 3, 4
        """

    @staticmethod
    def flux_dsp_synthese(nb_jours: int) -> str:
        """Synthèse DSP par jour et type de flux."""
        return """
            SELECT date_creation, jour_creation,
                   SUM(CASE WHEN type_flux = 'FOURNISSEURS' THEN 1 ELSE 0 END) AS nb_sup,
                   SUM(CASE WHEN type_flux = 'COMMANDES' THEN 1 ELSE 0 END) AS nb_cde,
                   SUM(CASE WHEN type_flux = 'RECEPTIONS' THEN 1 ELSE 0 END) AS nb_rec,
                   SUM(CASE WHEN type_flux = 'DEBLOCAGE' THEN 1 ELSE 0 END) AS nb_deb,
                   COUNT(*) AS total
            FROM (
                SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
                       TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
                       'FOURNISSEURS' AS type_flux
                FROM   dka_ipofrs_hist_entetes dih
                WHERE  dih.creation_date > SYSDATE - :nb_jours
                UNION ALL
                SELECT DISTINCT TRUNC(dih.creation_date),
                       TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'COMMANDES'
                FROM   dka_ipocde_hist_headers dih WHERE dih.creation_date > SYSDATE - :nb_jours
                UNION ALL
                SELECT DISTINCT TRUNC(dih.creation_date),
                       TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'RECEPTIONS'
                FROM   dka_iporec_hist_interface dih WHERE dih.creation_date > SYSDATE - :nb_jours
                UNION ALL
                SELECT DISTINCT TRUNC(dih.creation_date),
                       TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'DEBLOCAGE'
                FROM   dka_iapfac_debloc_hist_interf dih WHERE dih.creation_date > SYSDATE - :nb_jours
            )
            GROUP BY date_creation, jour_creation
            ORDER BY date_creation DESC
        """

    @staticmethod
    def notes_de_frais(nb_jours: int) -> str:
        """Comptage des notes de frais Notilus par jour."""
        return """
            SELECT TRUNC(creation_date) AS date_creation,
                   TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
                   COUNT(*) AS nb_ndf,
                   SUM(invoice_amount) AS montant_total
            FROM   ap_invoices_all
            WHERE  attribute9 = 'NOT'
            AND    creation_date > SYSDATE - :nb_jours
            GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
            ORDER BY TRUNC(creation_date) DESC
        """

    @staticmethod
    def factures_synthese(nb_jours: int) -> str:
        """Synthèse des factures par source (Xerox/Tradeshift/DSP)."""
        return """
            SELECT date_creation,
                   DECODE(SUBSTR(imagefile, 1, 3),
                          'VE1', 'XEROX',
                          'L56', 'TRADESHIFT',
                          'DSP', 'DSP',
                          'AUTRES') AS source,
                   COUNT(*) AS nb_factures
            FROM   dka_iapfacxgs_reporting_all
            WHERE  TO_DATE(date_creation, 'YYYYMMDD') > SYSDATE - :nb_jours
            GROUP BY date_creation,
                     DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES')
            ORDER BY date_creation DESC, source
        """

    @staticmethod
    def xerox_sans_image() -> str:
        """Factures Xerox sans image associée (ALERTE)."""
        return """
            SELECT dir.date_creation,
                   dir.num_fact,
                   dir.reference_lad,
                   aia.invoice_id,
                   aia.vendor_id
            FROM   dka_iapfacxgs_reporting_all dir
            JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact
                   AND aia.creation_date > SYSDATE - 30
            WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
            AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
            AND    NOT EXISTS (
                SELECT 1
                FROM   fnd_documents fd
                WHERE  fd.creation_date > SYSDATE - 30
                AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                        OR fd.file_name = aia.attribute3)
            )
        """

    @staticmethod
    def gl_interface() -> str:
        """Lignes GL en interface (en attente de traitement)."""
        return """
            SELECT attribute10 AS source,
                   attribute9 AS type_gl,
                   status,
                   COUNT(*) AS nb_lignes,
                   SUM(entered_dr) AS total_debit,
                   SUM(entered_cr) AS total_credit
            FROM   gl_interface
            GROUP BY attribute10, attribute9, status
            ORDER BY attribute10, attribute9
        """

    @staticmethod
    def gl_lignes_creees(nb_jours: int) -> str:
        """Lignes GL créées ces derniers jours."""
        return """
            SELECT TRUNC(creation_date) AS date_creation,
                   attribute10 AS source,
                   COUNT(*) AS nb_lignes,
                   SUM(entered_dr) AS total_debit
            FROM   gl_je_lines
            WHERE  creation_date > SYSDATE - :nb_jours
            GROUP BY TRUNC(creation_date), attribute10
            ORDER BY TRUNC(creation_date) DESC, attribute10 DESC
        """

    @staticmethod
    def nuit_synthese_statuts(heure_fermeture: int, heure_ouverture: int) -> str:
        """Synthèse des traitements de la nuit par statut."""
        return """
            SELECT CASE status_code
                       WHEN 'C' THEN 'OK'
                       WHEN 'E' THEN 'ERREUR'
                       WHEN 'G' THEN 'WARNING'
                       WHEN 'R' THEN 'EN COURS'
                       WHEN 'W' THEN 'EN ATTENTE'
                       ELSE 'AUTRE (' || status_code || ')'
                   END AS statut,
                   COUNT(*) AS nb
            FROM   fnd_concurrent_requests
            WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + :heure_fermeture / 24
            AND    actual_start_date <  TRUNC(SYSDATE)     + :heure_ouverture / 24
            GROUP BY CASE status_code
                       WHEN 'C' THEN 'OK'
                       WHEN 'E' THEN 'ERREUR'
                       WHEN 'G' THEN 'WARNING'
                       WHEN 'R' THEN 'EN COURS'
                       WHEN 'W' THEN 'EN ATTENTE'
                       ELSE 'AUTRE (' || status_code || ')'
                   END
            ORDER BY 1
        """

    @staticmethod
    def nuit_erreurs(heure_fermeture: int, heure_ouverture: int) -> str:
        """Détail des traitements en ERREUR."""
        return """
            SELECT fcr.request_id,
                   fcp.user_concurrent_program_name AS programme,
                   TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
                   TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI:SS') AS fin,
                   ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
                   SUBSTR(fcr.completion_text, 1, 150) AS message
            FROM   fnd_concurrent_requests fcr
            JOIN   fnd_concurrent_programs_vl fcp
                   ON fcr.concurrent_program_id = fcp.concurrent_program_id
            WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :heure_fermeture / 24
            AND    fcr.actual_start_date <  TRUNC(SYSDATE)     + :heure_ouverture / 24
            AND    fcr.status_code = 'E'
            ORDER BY fcr.actual_start_date DESC
        """

    @staticmethod
    def nuit_warnings(heure_fermeture: int, heure_ouverture: int) -> str:
        """Détail des traitements en WARNING."""
        return """
            SELECT fcr.request_id,
                   fcp.user_concurrent_program_name AS programme,
                   TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
                   ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
                   SUBSTR(fcr.completion_text, 1, 150) AS message
            FROM   fnd_concurrent_requests fcr
            JOIN   fnd_concurrent_programs_vl fcp
                   ON fcr.concurrent_program_id = fcp.concurrent_program_id
            WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :heure_fermeture / 24
            AND    fcr.actual_start_date <  TRUNC(SYSDATE)     + :heure_ouverture / 24
            AND    fcr.status_code = 'G'
            ORDER BY fcr.actual_start_date DESC
        """

    @staticmethod
    def nuit_traitements_longs(heure_fermeture: int, heure_ouverture: int, seuil_min: int) -> str:
        """Traitements longs (> seuil minutes)."""
        return """
            SELECT fcr.request_id,
                   fcp.user_concurrent_program_name AS programme,
                   TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI') AS debut,
                   TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI') AS fin,
                   ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
                   CASE fcr.status_code
                       WHEN 'C' THEN 'OK'
                       WHEN 'E' THEN 'ERREUR'
                       WHEN 'G' THEN 'WARNING'
                       ELSE fcr.status_code
                   END AS statut
            FROM   fnd_concurrent_requests fcr
            JOIN   fnd_concurrent_programs_vl fcp
                   ON fcr.concurrent_program_id = fcp.concurrent_program_id
            WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :heure_fermeture / 24
            AND    fcr.actual_start_date <  TRUNC(SYSDATE)     + :heure_ouverture / 24
            AND    (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > :seuil_min
            ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC
        """

    @staticmethod
    def nuit_en_cours(heure_fermeture: int) -> str:
        """Traitements toujours en cours (potentiellement bloqués)."""
        return """
            SELECT fcr.request_id,
                   fcp.user_concurrent_program_name AS programme,
                   TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
                   ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1) AS duree_actuelle_min,
                   fcr.argument_text AS parametres
            FROM   fnd_concurrent_requests fcr
            JOIN   fnd_concurrent_programs_vl fcp
                   ON fcr.concurrent_program_id = fcp.concurrent_program_id
            WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :heure_fermeture / 24
            AND    fcr.status_code = 'R'
            ORDER BY fcr.actual_start_date
        """

    @staticmethod
    def rb_imports(nb_jours: int) -> str:
        """Imports de rapprochement bancaire."""
        return """
            SELECT TRUNC(import_date) AS date_import,
                   TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
                   COUNT(*) AS nb_comptes
            FROM   rb_batch_import
            WHERE  import_date > SYSDATE - :nb_jours
            GROUP BY TRUNC(import_date), TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
            ORDER BY TRUNC(import_date) DESC
        """


# =========================================================================
# SECTION 4 : COUCHE D'ACCÈS AUX DONNÉES
# =========================================================================

class OracleDAO:
    """Data Access Object – exécute les requêtes et retourne des données typées."""

    def __init__(self, config: Config):
        self.config = config
        self.connection = None

    def connect(self):
        """Ouvre la connexion Oracle."""
        oracledb.init_oracle_client()  # Mode thick si Oracle Client installé
        self.connection = oracledb.connect(
            user=self.config.db_user,
            password=self.config.db_password,
            dsn=self.config.db_dsn,
        )
        print(f"✅ Connecté à Oracle : {self.config.db_dsn}")

    def disconnect(self):
        """Ferme la connexion Oracle."""
        if self.connection:
            self.connection.close()
            self.connection = None
            print("🔌 Déconnecté d'Oracle.")

    def _execute(self, sql: str, params: dict = None) -> List[Tuple]:
        """Exécute une requête et retourne les lignes."""
        with self.connection.cursor() as cursor:
            cursor.execute(sql, params or {})
            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchall()
            return columns, rows

    # --- Méthodes par section du rapport ---

    def get_synthese(self) -> SyntheseGlobale:
        """Collecte toutes les données de la synthèse globale."""
        syn = SyntheseGlobale()
        syn.date_controle = datetime.now().strftime("%d/%m/%Y")
        syn.jour_semaine = datetime.now().strftime("%A")
        cfg = self.config

        # Flux DSP
        _, rows = self._execute("""
            SELECT COUNT(DISTINCT file_name) FROM (
                SELECT file_name FROM dka_ipofrs_hist_entetes WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
                UNION ALL
                SELECT file_name FROM dka_ipocde_hist_headers WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
                UNION ALL
                SELECT file_name FROM dka_iporec_hist_interface WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
                UNION ALL
                SELECT file_name FROM dka_iapfac_debloc_hist_interf WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            )
        """)
        syn.nb_flux_dsp = rows[0][0] if rows else 0

        # Notes de frais
        _, rows = self._execute("""
            SELECT COUNT(*) FROM ap_invoices_all
            WHERE attribute9 = 'NOT' AND TRUNC(creation_date) = TRUNC(SYSDATE - 1)
        """)
        syn.nb_ndf = rows[0][0] if rows else 0

        # Factures par source
        try:
            _, rows = self._execute("""
                SELECT NVL(SUM(CASE WHEN SUBSTR(imagefile,1,3)='VE1' THEN 1 ELSE 0 END), 0),
                       NVL(SUM(CASE WHEN SUBSTR(imagefile,1,3)='L56' THEN 1 ELSE 0 END), 0),
                       NVL(SUM(CASE WHEN SUBSTR(imagefile,1,3)='DSP' THEN 1 ELSE 0 END), 0)
                FROM dka_iapfacxgs_reporting_all
                WHERE date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
            """)
            if rows:
                syn.nb_fac_xerox, syn.nb_fac_tradeshift, syn.nb_fac_dsp = rows[0]
        except Exception:
            pass

        # GL interface
        _, rows = self._execute("""
            SELECT COUNT(*) FROM gl_interface WHERE date_created > TRUNC(SYSDATE - 1)
        """)
        syn.nb_gl_interface = rows[0][0] if rows else 0

        # GL lignes créées
        _, rows = self._execute("""
            SELECT COUNT(*) FROM gl_je_lines WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
        """)
        syn.nb_gl_lignes = rows[0][0] if rows else 0

        # Traitements nuit
        _, rows = self._execute("""
            SELECT COUNT(*),
                   SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END),
                   SUM(CASE WHEN status_code = 'G' THEN 1 ELSE 0 END)
            FROM fnd_concurrent_requests
            WHERE actual_start_date >= TRUNC(SYSDATE - 1) + :hf / 24
            AND   actual_start_date <  TRUNC(SYSDATE) + :ho / 24
        """, {"hf": cfg.heure_fermeture, "ho": cfg.heure_ouverture})
        if rows and rows[0][0]:
            syn.nb_traitements_nuit = rows[0][0] or 0
            syn.nb_erreurs = rows[0][1] or 0
            syn.nb_warnings = rows[0][2] or 0

        # RB imports
        try:
            _, rows = self._execute("""
                SELECT COUNT(*) FROM rb_batch_import
                WHERE TRUNC(import_date) = TRUNC(SYSDATE - 1)
            """)
            syn.nb_rb_imports = rows[0][0] if rows else 0
        except Exception:
            pass

        return syn

    def get_flux_dsp_detail(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne le détail des flux DSP."""
        return self._execute(
            RequetesSQL.flux_dsp_detail(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )

    def get_flux_dsp_synthese(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne la synthèse DSP par jour."""
        return self._execute(
            RequetesSQL.flux_dsp_synthese(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )

    def get_notes_de_frais(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne les notes de frais."""
        return self._execute(
            RequetesSQL.notes_de_frais(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )

    def get_factures_synthese(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne la synthèse factures."""
        return self._execute(
            RequetesSQL.factures_synthese(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )

    def get_xerox_sans_image(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne les factures Xerox sans image."""
        return self._execute(RequetesSQL.xerox_sans_image())

    def get_gl_interface(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne les lignes GL en interface."""
        return self._execute(RequetesSQL.gl_interface())

    def get_gl_lignes_creees(self) -> Tuple[List[str], List[Tuple]]:
        """Retourne les lignes GL créées."""
        return self._execute(
            RequetesSQL.gl_lignes_creees(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )

    def get_nuit_synthese(self) -> Tuple[List[str], List[Tuple]]:
        """Synthèse nuit par statut."""
        cfg = self.config
        return self._execute(
            RequetesSQL.nuit_synthese_statuts(cfg.heure_fermeture, cfg.heure_ouverture),
            {"heure_fermeture": cfg.heure_fermeture, "heure_ouverture": cfg.heure_ouverture},
        )

    def get_nuit_erreurs(self) -> Tuple[List[str], List[Tuple]]:
        """Détail des erreurs de la nuit."""
        cfg = self.config
        return self._execute(
            RequetesSQL.nuit_erreurs(cfg.heure_fermeture, cfg.heure_ouverture),
            {"heure_fermeture": cfg.heure_fermeture, "heure_ouverture": cfg.heure_ouverture},
        )

    def get_nuit_warnings(self) -> Tuple[List[str], List[Tuple]]:
        """Détail des warnings de la nuit."""
        cfg = self.config
        return self._execute(
            RequetesSQL.nuit_warnings(cfg.heure_fermeture, cfg.heure_ouverture),
            {"heure_fermeture": cfg.heure_fermeture, "heure_ouverture": cfg.heure_ouverture},
        )

    def get_nuit_traitements_longs(self) -> Tuple[List[str], List[Tuple]]:
        """Traitements longs de la nuit."""
        cfg = self.config
        return self._execute(
            RequetesSQL.nuit_traitements_longs(cfg.heure_fermeture, cfg.heure_ouverture, cfg.seuil_traitement_long_min),
            {
                "heure_fermeture": cfg.heure_fermeture,
                "heure_ouverture": cfg.heure_ouverture,
                "seuil_min": cfg.seuil_traitement_long_min,
            },
        )

    def get_nuit_en_cours(self) -> Tuple[List[str], List[Tuple]]:
        """Traitements toujours en cours."""
        cfg = self.config
        return self._execute(
            RequetesSQL.nuit_en_cours(cfg.heure_fermeture),
            {"heure_fermeture": cfg.heure_fermeture},
        )

    def get_rb_imports(self) -> Tuple[List[str], List[Tuple]]:
        """Imports RB."""
        return self._execute(
            RequetesSQL.rb_imports(self.config.nb_jours_histo),
            {"nb_jours": self.config.nb_jours_histo},
        )


# =========================================================================
# SECTION 5 : GÉNÉRATEUR PDF
# =========================================================================

class RapportPDF(FPDF):
    """Générateur de rapport PDF personnalisé pour le contrôle quotidien."""

    # --- Couleurs du thème ---
    COULEUR_TITRE = (0, 51, 102)        # Bleu foncé
    COULEUR_SECTION = (0, 102, 153)     # Bleu moyen
    COULEUR_OK = (34, 139, 34)          # Vert
    COULEUR_WARNING = (255, 140, 0)     # Orange
    COULEUR_ERREUR = (220, 20, 60)      # Rouge
    COULEUR_HEADER_TAB = (70, 130, 180) # Bleu acier
    COULEUR_LIGNE_PAIRE = (240, 248, 255)  # Bleu très clair

    def __init__(self, date_controle: str):
        super().__init__(orientation="L", unit="mm", format="A4")
        self.date_controle = date_controle
        self.set_auto_page_break(auto=True, margin=15)
        # Polices Unicode pour les accents français
        # Utilise les polices par défaut (Helvetica) - pas besoin de TTF
        self.add_page()

    # --- En-tête et pied de page ---

    def header(self):
        """En-tête de chaque page."""
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(*self.COULEUR_TITRE)
        self.cell(0, 8, f"Controle Quotidien Oracle EBS - {self.date_controle}", border=0, ln=False, align="L")
        self.cell(0, 8, f"Page {self.page_no()}/{{nb}}", border=0, ln=True, align="R")
        self.set_draw_color(*self.COULEUR_TITRE)
        self.line(10, 18, self.w - 10, 18)
        self.ln(5)

    def footer(self):
        """Pied de page."""
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f"Genere le {datetime.now().strftime('%d/%m/%Y a %H:%M')} - Dalkia Finance", align="C")

    # --- Méthodes utilitaires ---

    def titre_section(self, numero: int, titre: str):
        """Ajoute un titre de section numéroté."""
        self.ln(5)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(*self.COULEUR_SECTION)
        self.cell(0, 10, f"{numero}. {titre}", ln=True)
        self.set_draw_color(*self.COULEUR_SECTION)
        self.line(10, self.get_y(), self.w - 10, self.get_y())
        self.ln(3)

    def sous_titre(self, titre: str):
        """Ajoute un sous-titre."""
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(60, 60, 60)
        self.cell(0, 8, titre, ln=True)
        self.ln(1)

    def badge_statut(self, statut: str) -> Tuple[int, int, int]:
        """Retourne la couleur associée à un statut."""
        if statut in ("OK", "C"):
            return self.COULEUR_OK
        elif statut in ("WARNING", "W", "G"):
            return self.COULEUR_WARNING
        else:
            return self.COULEUR_ERREUR

    def tableau(self, colonnes: List[str], lignes: List[Tuple],
                largeurs: Optional[List[int]] = None, aligns: Optional[List[str]] = None):
        """Dessine un tableau avec en-tête coloré et lignes alternées."""
        if not largeurs:
            # Largeurs auto-calculées
            nb_cols = len(colonnes)
            largeur_dispo = self.w - 20
            largeurs = [largeur_dispo // nb_cols] * nb_cols

        if not aligns:
            aligns = ["L"] * len(colonnes)

        # En-tête
        self.set_font("Helvetica", "B", 8)
        self.set_fill_color(*self.COULEUR_HEADER_TAB)
        self.set_text_color(255, 255, 255)
        for i, col in enumerate(colonnes):
            self.cell(largeurs[i], 7, str(col), border=1, fill=True, align="C")
        self.ln()

        # Lignes
        self.set_font("Helvetica", "", 7)
        self.set_text_color(0, 0, 0)
        for idx, ligne in enumerate(lignes):
            # Vérifier saut de page
            if self.get_y() > self.h - 25:
                self.add_page()

            # Alternance de couleurs
            if idx % 2 == 0:
                self.set_fill_color(*self.COULEUR_LIGNE_PAIRE)
            else:
                self.set_fill_color(255, 255, 255)

            for i, val in enumerate(ligne):
                texte = str(val) if val is not None else ""
                # Tronquer si trop long
                max_chars = largeurs[i] // 2
                if len(texte) > max_chars:
                    texte = texte[:max_chars - 2] + ".."
                self.cell(largeurs[i], 6, texte, border=1, fill=True, align=aligns[i])
            self.ln()

    def tableau_synthese(self, synthese: SyntheseGlobale):
        """Dessine le tableau de synthèse avec badges de statut."""
        items = [
            ("Flux DSP (fichiers)", synthese.nb_flux_dsp, synthese.statut_flux_dsp()),
            ("Notes de frais Notilus", synthese.nb_ndf, synthese.statut_ndf()),
            ("Factures Xerox", synthese.nb_fac_xerox, synthese.statut_xerox()),
            ("Factures Tradeshift", synthese.nb_fac_tradeshift, synthese.statut_tradeshift()),
            ("Factures DSP", synthese.nb_fac_dsp, "OK" if synthese.nb_fac_dsp == 0 and synthese.nb_flux_dsp >= 5 else "INFO"),
            ("Ecritures GL (interface)", synthese.nb_gl_interface, "OK" if synthese.nb_gl_interface > 0 else "INFO"),
            ("Lignes GL creees", synthese.nb_gl_lignes, synthese.statut_gl()),
            ("Imports RB", synthese.nb_rb_imports, synthese.statut_rb()),
        ]

        self.set_font("Helvetica", "B", 8)
        self.set_fill_color(*self.COULEUR_HEADER_TAB)
        self.set_text_color(255, 255, 255)
        self.cell(100, 7, "Domaine", border=1, fill=True, align="C")
        self.cell(40, 7, "Nombre", border=1, fill=True, align="C")
        self.cell(40, 7, "Statut", border=1, fill=True, align="C")
        self.ln()

        self.set_font("Helvetica", "", 9)
        for i, (label, valeur, statut) in enumerate(items):
            if i % 2 == 0:
                self.set_fill_color(*self.COULEUR_LIGNE_PAIRE)
            else:
                self.set_fill_color(255, 255, 255)

            self.set_text_color(0, 0, 0)
            self.cell(100, 7, label, border=1, fill=True, align="L")
            self.cell(40, 7, str(valeur), border=1, fill=True, align="C")

            couleur = self.badge_statut(statut)
            self.set_text_color(*couleur)
            self.set_font("Helvetica", "B", 9)
            self.cell(40, 7, statut, border=1, fill=True, align="C")
            self.set_font("Helvetica", "", 9)
        self.ln()

        # Bloc traitements nuit
        self.ln(3)
        self.set_text_color(0, 0, 0)
        self.set_font("Helvetica", "B", 9)
        self.cell(0, 7, f"Traitements nuit : {synthese.nb_traitements_nuit}  |  "
                        f"Erreurs : {synthese.nb_erreurs}  |  "
                        f"Warnings : {synthese.nb_warnings}  |  "
                        f"Images manquantes : {synthese.nb_images_manquantes}", ln=True)

    def bloc_alertes(self, synthese: SyntheseGlobale):
        """Affiche les alertes en rouge/orange."""
        alertes = []
        if synthese.nb_erreurs > 0:
            alertes.append(("ERREUR", f"{synthese.nb_erreurs} traitement(s) en ERREUR - Voir Section 6"))
        if synthese.nb_flux_dsp < 5:
            jour = datetime.now().strftime("%a").upper()
            if jour not in ("SAT", "SUN", "MON"):
                alertes.append(("WARNING", f"Moins de {5} flux DSP (recu: {synthese.nb_flux_dsp})"))
        if synthese.nb_images_manquantes > 0:
            alertes.append(("WARNING", f"{synthese.nb_images_manquantes} factures Xerox sans image"))
        if datetime.now().strftime("%a").upper() == "MON" and synthese.nb_rb_imports == 0:
            alertes.append(("RAPPEL", "LUNDI : Charger manuellement le fichier SG"))

        if alertes:
            self.ln(3)
            self.sous_titre("Alertes")
            for niveau, msg in alertes:
                couleur = self.COULEUR_ERREUR if niveau == "ERREUR" else self.COULEUR_WARNING
                self.set_text_color(*couleur)
                self.set_font("Helvetica", "B", 9)
                self.cell(0, 6, f"[{niveau}] {msg}", ln=True)
            self.set_text_color(0, 0, 0)

    # --- Sections complètes ---

    def section_synthese(self, synthese: SyntheseGlobale):
        """Section 1 : Synthèse globale."""
        self.titre_section(1, "Synthese Globale")
        self.set_font("Helvetica", "", 10)
        self.cell(0, 7, f"Date : {synthese.date_controle}  -  Jour : {synthese.jour_semaine}", ln=True)
        self.ln(2)
        self.tableau_synthese(synthese)
        self.bloc_alertes(synthese)

    def section_flux_dsp(self, detail: Tuple, synthese: Tuple):
        """Section 2 : Flux DSP (iValua)."""
        self.add_page()
        self.titre_section(2, "Flux DSP (iValua)")
        self.sous_titre("Detail des fichiers recus")
        cols_d, rows_d = detail
        if rows_d:
            self.tableau(cols_d, rows_d, largeurs=[30, 30, 30, 180])
        else:
            self.set_font("Helvetica", "I", 9)
            self.cell(0, 7, "Aucun fichier DSP recu sur la periode.", ln=True)

        self.ln(5)
        self.sous_titre("Synthese par jour et type")
        cols_s, rows_s = synthese
        if rows_s:
            self.tableau(cols_s, rows_s, largeurs=[30, 30, 25, 25, 25, 25, 25])

    def section_notes_de_frais(self, data: Tuple):
        """Section 3 : Notes de frais (Notilus)."""
        self.add_page()
        self.titre_section(3, "Notes de frais (Notilus)")
        cols, rows = data
        if rows:
            self.tableau(cols, rows, largeurs=[30, 30, 25, 50])
        else:
            self.set_font("Helvetica", "I", 9)
            self.cell(0, 7, "Aucune note de frais sur la periode.", ln=True)

    def section_factures(self, synthese_fac: Tuple, sans_image: Tuple):
        """Section 4 : Factures."""
        self.add_page()
        self.titre_section(4, "Factures (Xerox, Tradeshift, DSP)")
        self.sous_titre("Synthese par source")
        cols_s, rows_s = synthese_fac
        if rows_s:
            self.tableau(cols_s, rows_s, largeurs=[30, 40, 30])

        self.ln(5)
        cols_i, rows_i = sans_image
        if rows_i:
            self.sous_titre(f"ALERTE : {len(rows_i)} factures Xerox SANS image")
            self.set_text_color(*self.COULEUR_ERREUR)
            self.set_font("Helvetica", "B", 9)
            self.cell(0, 6, "Les factures suivantes n'ont pas d'image associee dans FND_DOCUMENTS :", ln=True)
            self.set_text_color(0, 0, 0)
            self.tableau(cols_i, rows_i, largeurs=[25, 40, 40, 30, 30])
        else:
            self.sous_titre("Images Xerox : OK")
            self.set_text_color(*self.COULEUR_OK)
            self.set_font("Helvetica", "", 9)
            self.cell(0, 7, "Toutes les factures Xerox ont une image associee.", ln=True)
            self.set_text_color(0, 0, 0)

    def section_gl(self, interface: Tuple, creees: Tuple):
        """Section 5 : Écritures GL."""
        self.add_page()
        self.titre_section(5, "Ecritures GL")
        self.sous_titre("Lignes en interface (en attente)")
        cols_i, rows_i = interface
        if rows_i:
            self.tableau(cols_i, rows_i, largeurs=[40, 30, 20, 25, 40, 40])
        else:
            self.set_font("Helvetica", "I", 9)
            self.cell(0, 7, "Aucune ligne en interface GL.", ln=True)

        self.ln(5)
        self.sous_titre("Lignes GL creees")
        cols_c, rows_c = creees
        if rows_c:
            self.tableau(cols_c, rows_c, largeurs=[30, 40, 25, 40])

    def section_nuit(self, synthese_nuit: Tuple, erreurs: Tuple, warnings: Tuple,
                     longs: Tuple, en_cours: Tuple):
        """Section 6 : Traitements de la nuit."""
        self.add_page()
        self.titre_section(6, "Traitements de la nuit (19h-7h)")

        self.sous_titre("Synthese par statut")
        cols_s, rows_s = synthese_nuit
        if rows_s:
            self.tableau(cols_s, rows_s, largeurs=[50, 30])

        # Erreurs
        self.ln(5)
        cols_e, rows_e = erreurs
        if rows_e:
            self.sous_titre(f"ERREURS ({len(rows_e)})")
            self.tableau(cols_e, rows_e, largeurs=[25, 80, 30, 30, 20, 80])
        else:
            self.sous_titre("Erreurs : Aucune")

        # Warnings
        self.ln(3)
        cols_w, rows_w = warnings
        if rows_w:
            self.sous_titre(f"Warnings ({len(rows_w)})")
            self.tableau(cols_w, rows_w, largeurs=[25, 80, 30, 20, 80])

        # Traitements longs
        self.ln(3)
        cols_l, rows_l = longs
        if rows_l:
            self.sous_titre(f"Traitements longs > 30 min ({len(rows_l)})")
            self.tableau(cols_l, rows_l, largeurs=[25, 80, 30, 30, 25, 25])

        # En cours
        self.ln(3)
        cols_ec, rows_ec = en_cours
        if rows_ec:
            self.sous_titre(f"Traitements EN COURS ({len(rows_ec)}) - potentiellement bloques")
            self.set_text_color(*self.COULEUR_ERREUR)
            self.set_font("Helvetica", "B", 9)
            self.cell(0, 6, "Attention : ces traitements sont toujours actifs !", ln=True)
            self.set_text_color(0, 0, 0)
            self.tableau(cols_ec, rows_ec, largeurs=[25, 80, 30, 30, 80])
        else:
            self.sous_titre("En cours : Aucun traitement bloque")

    def section_rb(self, data: Tuple):
        """Section 7 : Rapprochement bancaire."""
        self.add_page()
        self.titre_section(7, "Rapprochement Bancaire")
        cols, rows = data
        if rows:
            self.tableau(cols, rows, largeurs=[30, 30, 25])
        else:
            self.set_font("Helvetica", "I", 9)
            self.cell(0, 7, "Aucun import RB sur la periode.", ln=True)

        # Rappel lundi
        if datetime.now().strftime("%a").upper() == "MON":
            self.ln(5)
            self.set_text_color(*self.COULEUR_WARNING)
            self.set_font("Helvetica", "B", 10)
            self.cell(0, 8, "RAPPEL : Le lundi, charger manuellement le fichier SG (rattrapage week-end)", ln=True)
            self.set_text_color(0, 0, 0)


# =========================================================================
# SECTION 6 : ORCHESTRATEUR PRINCIPAL
# =========================================================================

class ControleurQuotidien:
    """Orchestre la collecte de données et la génération du rapport PDF."""

    def __init__(self, config: Config):
        self.config = config
        self.dao = OracleDAO(config)

    def generer_rapport(self) -> str:
        """
        Pipeline principal :
          1. Connexion à la base Oracle
          2. Collecte des données (toutes les sections)
          3. Génération du PDF
          4. Sauvegarde du fichier
          5. Déconnexion

        Retourne le chemin du fichier PDF généré.
        """
        print("=" * 60)
        print("CONTRÔLE QUOTIDIEN - Génération du rapport PDF")
        print("=" * 60)

        # --- Étape 1 : Connexion ---
        print("\n📡 Étape 1/5 : Connexion à Oracle...")
        self.dao.connect()

        try:
            # --- Étape 2 : Collecte des données ---
            print("📊 Étape 2/5 : Collecte des données...")

            print("  → Synthèse globale...")
            synthese = self.dao.get_synthese()

            print("  → Flux DSP...")
            dsp_detail = self.dao.get_flux_dsp_detail()
            dsp_synthese = self.dao.get_flux_dsp_synthese()

            print("  → Notes de frais...")
            ndf = self.dao.get_notes_de_frais()

            print("  → Factures...")
            fac_synthese = self.dao.get_factures_synthese()
            xerox_sans_img = self.dao.get_xerox_sans_image()

            print("  → Écritures GL...")
            gl_interface = self.dao.get_gl_interface()
            gl_creees = self.dao.get_gl_lignes_creees()

            print("  → Traitements de la nuit...")
            nuit_synth = self.dao.get_nuit_synthese()
            nuit_err = self.dao.get_nuit_erreurs()
            nuit_warn = self.dao.get_nuit_warnings()
            nuit_longs = self.dao.get_nuit_traitements_longs()
            nuit_encours = self.dao.get_nuit_en_cours()

            print("  → Rapprochement bancaire...")
            rb = self.dao.get_rb_imports()

            # --- Étape 3 : Génération du PDF ---
            print("\n📄 Étape 3/5 : Génération du PDF...")
            pdf = RapportPDF(date_controle=synthese.date_controle)
            pdf.alias_nb_pages()

            print("  → Section 1 : Synthèse...")
            pdf.section_synthese(synthese)

            print("  → Section 2 : Flux DSP...")
            pdf.section_flux_dsp(dsp_detail, dsp_synthese)

            print("  → Section 3 : Notes de frais...")
            pdf.section_notes_de_frais(ndf)

            print("  → Section 4 : Factures...")
            pdf.section_factures(fac_synthese, xerox_sans_img)

            print("  → Section 5 : Écritures GL...")
            pdf.section_gl(gl_interface, gl_creees)

            print("  → Section 6 : Traitements nuit...")
            pdf.section_nuit(nuit_synth, nuit_err, nuit_warn, nuit_longs, nuit_encours)

            print("  → Section 7 : Rapprochement bancaire...")
            pdf.section_rb(rb)

            # --- Étape 4 : Sauvegarde ---
            print("\n💾 Étape 4/5 : Sauvegarde...")
            output_path = os.path.join(self.config.output_dir, self.config.output_filename)
            os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path) else ".", exist_ok=True)
            pdf.output(output_path)
            print(f"  ✅ Rapport généré : {output_path}")

            return output_path

        finally:
            # --- Étape 5 : Déconnexion ---
            print("\n🔌 Étape 5/5 : Déconnexion...")
            self.dao.disconnect()
            print("\n✅ Terminé.")


# =========================================================================
# SECTION 7 : POINT D'ENTRÉE (CLI)
# =========================================================================

def parse_args() -> argparse.Namespace:
    """Parse les arguments de la ligne de commande."""
    parser = argparse.ArgumentParser(
        description="Génère le rapport de contrôle quotidien Oracle EBS en PDF.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples :
  python rapport_quotidien.py --config config.ini
  python rapport_quotidien.py --user APPS --dsn host:1521/PROD
  python rapport_quotidien.py --jours 5 --output rapport.pdf
        """,
    )
    parser.add_argument("--config", "-c", help="Chemin du fichier de configuration INI")
    parser.add_argument("--user", "-u", help="Utilisateur Oracle")
    parser.add_argument("--password", "-p", help="Mot de passe Oracle")
    parser.add_argument("--dsn", "-d", help="DSN Oracle (host:port/service)")
    parser.add_argument("--jours", "-j", type=int, help="Nombre de jours d'historique")
    parser.add_argument("--output", "-o", help="Chemin du fichier PDF de sortie")
    return parser.parse_args()


def main():
    """Point d'entrée principal."""
    args = parse_args()

    # Chargement de la configuration
    config = load_config(args.config)

    # Surcharges CLI
    if args.user:
        config.db_user = args.user
    if args.password:
        config.db_password = args.password
    if args.dsn:
        config.db_dsn = args.dsn
    if args.jours:
        config.nb_jours_histo = args.jours
    if args.output:
        config.output_filename = args.output

    # Validation minimale
    if not config.db_user or not config.db_dsn:
        print("ERREUR : Paramètres de connexion manquants.")
        print("Utilisez --config config.ini ou --user / --dsn / --password")
        print("Ou définissez ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN en variables d'environnement")
        sys.exit(1)

    # Génération
    controleur = ControleurQuotidien(config)
    chemin_pdf = controleur.generer_rapport()

    print(f"\n📋 Rapport disponible : {chemin_pdf}")


if __name__ == "__main__":
    main()
