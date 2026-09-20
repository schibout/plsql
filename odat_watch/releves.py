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
