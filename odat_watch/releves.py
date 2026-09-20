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
