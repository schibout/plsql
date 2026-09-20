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
