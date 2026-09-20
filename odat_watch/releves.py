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
        # Plusieurs TARGET / zips possibles dans un même dossier : on prend le plus récent (ordre des noms = horodatage)
        targets = sorted(f for f in (d / "TARGET").glob("*.txt") if TARGET_RE.search(f.name)) if (d / "TARGET").is_dir() else []
        if not targets:
            continue
        target = targets[-1]
        m = TARGET_RE.search(target.name)
        horodatage = datetime.strptime(m.group(1) + m.group(2), "%y%m%d%H%M%S")
        sources = sorted((d / "SOURCE").glob("*")) if (d / "SOURCE").is_dir() else []
        zips = sorted((d / "TARGET").glob("compteur_*.zip"))
        zip_ok = False
        if zips:
            try:
                with zipfile.ZipFile(zips[-1]) as z:
                    zip_ok = target.name in z.namelist()
            except (zipfile.BadZipFile, OSError):
                zip_ok = False
        ls_ok = (d / "TALEND" / "LS_IN.OK").exists()
        a = lire_afb120(target, banque_b)
        con.execute(
            "INSERT INTO rb_pfe(uuid,horodatage,fichier_source,fichier_target,zip,ls_in_ok,complete,flux,nb_releves,"
            "nb_lignes,banques,date_min,date_max,md5,vu_le) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (d.name, horodatage.strftime("%Y-%m-%d %H:%M:%S"), str(sources[0]) if sources else None, str(target),
             str(zips[-1]) if zips else None, int(ls_ok), int(bool(sources) and zip_ok and ls_ok), a.flux,
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


# ---------------------------------------------------------------- logs RBAFBIMP
MOIS = {"JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6, "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10,
        "NOV": 11, "DEC": 12,
        # formes françaises rencontrées dans les sorties DKA_SRBCTRLRB (ex. 28-AOU-26)
        "FEV": 2, "AVR": 4, "MAI": 5, "AOU": 8}
BATCH_RE = re.compile(r"chargement N\S+\s*(\d+)")
LIGNE_ERR_RE = re.compile(r"^\s*(\d+) >  (.+)$")            # « 01565 >  0130003 … » : n° d'enregistrement + contenu
CODE_ERR_RE = re.compile(r"^\s*Erreur\s+(\d{3})\s*:")
# Codes banque parfois alphanumériques (comptes suisses CH530.87050.…)
SYNTHESE_RE = re.compile(
    r"^(?P<err>[01])\s+(?P<num>\d+)\s+(?P<compte>[A-Z0-9]{5}\.[A-Z0-9]{5}\.[A-Z0-9]{11})\s+(?P<dev>[A-Z]{3})\s+"
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
    erreurs: list[tuple[int, str]] = []          # (n° d'enregistrement en erreur, code)
    compteur: Counter = Counter()
    releves: list[dict] = []
    batch = None
    pied = {"releves_charges": 0, "releves_erreurs": 0, "releves_total": 0,
            "lignes_chargees": 0, "lignes_erreurs": 0, "lignes_total": 0}
    dernier_enreg: int | None = None
    for ligne in text.splitlines():
        m = BATCH_RE.search(ligne)
        if m and batch is None:
            batch = int(m.group(1))
        m = LIGNE_ERR_RE.match(ligne)
        if m:
            dernier_enreg = int(m.group(1))
            continue
        m = CODE_ERR_RE.match(ligne)
        if m:
            code = f"Erreur {m.group(1)}"
            compteur[code] += 1
            if dernier_enreg is not None:
                erreurs.append((dernier_enreg, code))
            continue
        m = SYNTHESE_RE.match(ligne)
        if m:
            banque, guichet, numero = m.group("compte").split(".")
            releves.append(dict(num=int(m.group("num")), compte=m.group("compte"), banque=banque, guichet=guichet,
                                numero=numero, devise=m.group("dev"), date_debut=_date_ora(m.group("d1")),
                                date_fin=_date_ora(m.group("d2")), mouvements=int(m.group("mvt")),
                                l1=int(m.group("l1")), l2=int(m.group("l2")),
                                en_erreur=int(m.group("err") == "1"), code_erreur=None))
            continue
        m = PIED_RE.search(ligne)
        if m:
            g1, v1, g2, v2 = m.groups()
            cle1 = "releves_charges" if g1.lower().startswith("relev") else "releves_" + ("erreurs" if g1.lower() == "erreurs" else "total")
            cle2 = "lignes_chargees" if g2.lower().startswith("lignes") else "lignes_" + ("erreurs" if g2.lower() == "erreurs" else "total")
            pied[cle1], pied[cle2] = int(v1), int(v2)
    for r in releves:   # le relevé couvre les enregistrements l1..l2 du fichier : premier code d'erreur dans cette plage
        if r["en_erreur"]:
            r["code_erreur"] = next((c for n, c in erreurs if r["l1"] <= n <= r["l2"]), None)
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
    # UPSERT : un rescan (le .out arrivé après le .req) met à jour la ligne sans toucher md5_ebs
    con.execute(
        "INSERT INTO rb_imports(request_id,debut,fin,fichier,lus,ecrits,batch,releves_charges,releves_erreurs,"
        "lignes_chargees,lignes_erreurs,err001,err025,autres_erreurs,flux,source_req,source_out) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
        "ON CONFLICT(request_id) DO UPDATE SET debut=excluded.debut, fin=excluded.fin, fichier=excluded.fichier, "
        "lus=excluded.lus, ecrits=excluded.ecrits, batch=excluded.batch, releves_charges=excluded.releves_charges, "
        "releves_erreurs=excluded.releves_erreurs, lignes_chargees=excluded.lignes_chargees, "
        "lignes_erreurs=excluded.lignes_erreurs, err001=excluded.err001, err025=excluded.err025, "
        "autres_erreurs=excluded.autres_erreurs, flux=excluded.flux, source_req=excluded.source_req, "
        "source_out=excluded.source_out",
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
    return "RBAFBIMP" in text or "Fichier des relev" in text or ("Synth" in text and "relev" in text)


def _est_controle(text: str) -> bool:
    return "DKA_SRBCTRLRB" in text or "DATE DE REFERENCE" in text


def scanner_logs(dossiers: list[Path], con: sqlite3.Connection, banque_b: str = "30003") -> int:
    """Charge les couples l<id>.req / o<id>.out nouveaux (imports et contrôles). Retourne le nombre de requests
    ajoutées ou complétées (une request déjà en base est relue si un fichier absent lors du premier scan est apparu)."""
    fichiers: dict[int, dict] = {}
    for d in dossiers:
        if not d.is_dir():
            continue
        for f in d.rglob("*"):
            m = logs.FILE_RE.match(f.name)
            if f.is_file() and m:
                fichiers.setdefault(int(m.group(2)), {})["req" if m.group(1).lower() == "l" else "out"] = f
    # request_id -> (req déjà lu, out déjà lu). rb_controles ne trace que le .out.
    deja: dict[int, tuple[bool, bool]] = {
        r[0]: (r[1] is not None, r[2] is not None)
        for r in con.execute("SELECT request_id, source_req, source_out FROM rb_imports")}
    deja.update({r[0]: (True, r[1] is not None)
                 for r in con.execute("SELECT request_id, source_out FROM rb_controles")})
    n = 0
    for rid, fs in sorted(fichiers.items()):
        if rid in deja:
            a_req, a_out = deja[rid]
            if not (("req" in fs and not a_req) or ("out" in fs and not a_out)):
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


# ---------------------------------------------------------------- logs DKA_SRBCTRLRB
DATE_REF_RE = re.compile(r"DATE DE REFERENCE\s*:\s*(\d{2})/(\d{2})/(\d{4})")
ENTETE_CTRL = "ID;NOM_BANQUE;BANQUE;GUICHET;COMPTE;NOM_COMPTE;RAPPRO;COMPTE_LOCAL;DATE_DERNIER_IMPORT"


DATE_COURTE_RE = re.compile(r"^\d{2}-[A-Z]{3}-\d{2}$", re.I)          # 14-SEP-26
DATE_LONGUE_RE = re.compile(r"^\d{2}-[A-Z]{3}-\d{4}", re.I)            # 17-SEP-2026[ 08:19:53]


def _date_ctrl(txt: str) -> str | None:
    """Date d'une sortie DKA_SRBCTRLRB -> ISO ; texte inchangé si le format n'est pas reconnu."""
    txt = txt.strip()
    if not txt:
        return None
    try:
        if DATE_COURTE_RE.match(txt):
            return _date_ora_courte(txt)
        if DATE_LONGUE_RE.match(txt):
            return _date_ora(txt)
    except (KeyError, ValueError):
        pass
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
    """Remplace la liste des comptes connus par le contenu de l'éditeur (lignes vides / NaN ignorées)."""
    lignes = []
    for _, r in df.iterrows():
        cle = r.get("cle")
        if cle is None or pd.isna(cle) or not str(cle).strip():
            continue
        motif = r.get("motif")
        motif = "" if motif is None or pd.isna(motif) else str(motif).strip()
        lignes.append((str(cle).strip(), motif, maintenant()))
    con.execute("DELETE FROM rb_comptes_connus")
    con.executemany("INSERT OR REPLACE INTO rb_comptes_connus(cle, motif, ajoute_le) VALUES (?,?,?)", lignes)
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
