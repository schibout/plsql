"""Modele de donnees pour le controle des virements."""
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class Virement:
    iban: str
    montant_cts: int
    nom: str
    bic: str
    libelle: str = ""          # ACK : lot Oracle + reference de paiement (zone 132-202 de l'enregistrement 06)


@dataclass
class LotDK:
    ref: str
    montant_entete_cts: int
    virements: list = field(default_factory=list)
    euro_lines: int = 0


@dataclass
class LotAck:
    iban_payeur: str
    virements: list = field(default_factory=list)
    footer_count: int = 0
    footer_total_cts: int = 0
    date_creation: str = ""    # AAMMJJ (en-tete 03, position 54)
    date_valeur: str = ""      # JJMMAA (en-tete 03, position 24)


@dataclass
class OracleRow:
    code_banque: str
    iban_payeur: str
    date: str
    nom_fichier_source: str
    nb_source: int
    montant_source_cts: int
    nom_fichier_edf: str
    nb_edf: int
    montant_edf_cts: int


@dataclass
class Instance:
    guid: str
    source_dir: Optional[Path] = None
    cible_dir: Optional[Path] = None
    # renseignes par collecter_instance, pour les controles transverses (doublons D6, sanite)
    cible_seul: bool = False
    dkfin01_cible: dict = field(default_factory=dict)
    oracle_rows: list = field(default_factory=list)
    sanite: list = field(default_factory=list)
