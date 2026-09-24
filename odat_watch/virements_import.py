"""Import des virements déposés en vrac dans ODAT/Virements/import_virement.

On y dépose, sans les trier : des instances Talend (un dossier <uuid> contenant SOURCE, TALEND, TARGET), des
exports Quartz (« Liste des virements importés du jour.xls », sous-dossier EDF du dépôt Drive) et les rejets
bancaires de virements (« Liste des rejets bancaires du jour - Virement.xls », sous-dossier REJET). L'import date
chaque élément par son nom (préfixe JJMMAAAA_ posé par l'Apps Script, ou suffixe) sinon par son contenu, le range
dans ODAT/Virements/ORACLE/JJMMAAAA/<uuid>, ODAT/Virements/EDF/Liste des virements importés du jour<JJMMAAAA>.xls
ou ODAT/Virements/REJETS/JJMMAAAA_<nom>.xls, et enregistre les instances dans vir_imports. Un dossier JJMMAAAA déposé
tel quel est accepté aussi (ses instances sont rangées).
"""
from __future__ import annotations
import re
import shutil
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

DEPOT = "import_virement"
RE_DATE_FICHIER = re.compile(r"[-_](\d{8})[-_]")             # DK_FIN01_*-20260918-49069237_20260918-014541.txt
RE_DATE_ORACLE = re.compile(r"REGROUPEMENTS_REALISES_(\d{8})")
RE_JOUR = re.compile(r"\d{8}")
RE_PREFIXE_JOUR = re.compile(r"^(\d{8})_")                  # 18092026_Liste des … .xls (nommage Apps Script)
QUARTZ_PREFIXE = "Liste des virements importés du jour"
SOUS_DOSSIERS = {"EDF": "quartz", "REJET": "rejet", "REJETS": "rejet"}   # sous-dossiers du dépôt Drive → genre


@dataclass
class Element:
    chemin: Path
    genre: str                      # instance | quartz | rejet | inconnu
    date: str | None = None         # JJMMAAAA
    guid: str = ""
    destination: Path | None = None
    etat: str = ""                  # à importer | déjà présent | date introuvable | non reconnu
    nb_fichiers: int = 0
    nb_envois: int = 0


@dataclass
class Bilan:
    importes: list[Element] = field(default_factory=list)
    ignores: list[Element] = field(default_factory=list)

    @property
    def message(self) -> str:
        n_inst = sum(1 for e in self.importes if e.genre == "instance")
        n_q = sum(1 for e in self.importes if e.genre == "quartz")
        n_r = sum(1 for e in self.importes if e.genre == "rejet")
        jours = sorted({e.date for e in self.importes if e.date}, key=lambda d: d[4:] + d[2:4] + d[:2])
        txt = f"{n_inst} instance(s), {n_q} fichier(s) Quartz et {n_r} fichier(s) de rejets importé(s)"
        if jours:
            txt += " — journée(s) " + ", ".join(f"{d[:2]}/{d[2:4]}" for d in jours)
        if self.ignores:
            txt += f" · {len(self.ignores)} élément(s) laissé(s) dans le dépôt"
        return txt


def _aaaammjj_vers_jjmmaaaa(s: str) -> str | None:
    try:
        return datetime.strptime(s, "%Y%m%d").strftime("%d%m%Y")
    except ValueError:
        return None


def date_instance(dossier: Path) -> str | None:
    """Journée d'une instance, lue dans les noms de ses fichiers : DK_FIN01 (SOURCE) puis CSV Oracle (TARGET)."""
    for motif, regex in (("DK_FIN01_*.txt", RE_DATE_FICHIER), ("ORACLE_VIREMENTS_REGROUPEMENTS_REALISES_*.csv", RE_DATE_ORACLE)):
        for f in sorted(dossier.rglob(motif)):
            m = regex.search(f.name)
            if m:
                d = _aaaammjj_vers_jjmmaaaa(m.group(1))
                if d:
                    return d
    return None


def date_quartz(fichier: Path) -> str | None:
    """Journée d'un classeur Quartz (virements importés ou rejets) : préfixe 18092026_ ou suffixe …du jour18092026.xls
    dans le nom, sinon l'en-tête « Date de mise à jour: De JJ/MM/AAAA à JJ/MM/AAAA » du classeur."""
    m = RE_PREFIXE_JOUR.match(fichier.name) or re.search(r"(\d{8})\.xls$", fichier.name, re.I)
    if m:
        try:
            datetime.strptime(m.group(1), "%d%m%Y")
            return m.group(1)
        except ValueError:
            pass
    try:
        import xlrd
        sh = xlrd.open_workbook(str(fichier)).sheet_by_index(0)
        for r in range(min(sh.nrows, 10)):
            for c in range(sh.ncols):
                v = sh.cell_value(r, c)
                if isinstance(v, str) and "mise à jour" in v.lower():
                    dates = re.findall(r"(\d{2})/(\d{2})/(\d{4})", v)
                    if dates:
                        j, mo, a = dates[-1]
                        return f"{j}{mo}{a}"
    except Exception:  # noqa: BLE001 — classeur illisible : l'élément restera « date introuvable »
        return None
    return None


def _compter(dossier: Path) -> tuple[int, int]:
    fichiers = [f for f in dossier.rglob("*") if f.is_file()]
    return len(fichiers), sum(1 for f in fichiers if f.name.startswith("CDPG.NC4.IMPORT_ACK.") and not f.name.endswith(".asc"))


def scanner(depot: Path, cfg: dict) -> list[Element]:
    """Ce que contient le dépôt et où chaque élément irait, sans rien déplacer. `cfg` : dossiers « oracle », « edf »,
    « rejets » de virements.config_virements."""
    depot = Path(depot)
    oracle, edf, rejets = Path(cfg["oracle"]), Path(cfg["edf"]), Path(cfg["rejets"])
    out: list[Element] = []
    if not depot.is_dir():
        return out
    candidats: list[tuple[Path, str | None]] = []       # (chemin, genre imposé par le sous-dossier EDF / REJET)
    for p in sorted(depot.iterdir()):
        if p.is_dir() and RE_JOUR.fullmatch(p.name):        # journée déposée entière
            candidats += [(d, None) for d in sorted(p.iterdir()) if d.is_dir()]
        elif p.is_dir() and p.name.upper() in SOUS_DOSSIERS:  # sous-dossiers du dépôt Drive
            candidats += [(f, SOUS_DOSSIERS[p.name.upper()]) for f in sorted(p.iterdir()) if f.is_file()]
        else:
            candidats.append((p, None))
    for p, genre in candidats:
        if p.is_dir():
            e = Element(chemin=p, genre="instance", guid=p.name)
            e.nb_fichiers, e.nb_envois = _compter(p)
            e.date = date_instance(p) or (p.parent.name if RE_JOUR.fullmatch(p.parent.name) else None)
            if not e.date:
                e.etat = "date introuvable"
            else:
                e.destination = oracle / e.date / p.name
                e.etat = "déjà présent" if e.destination.exists() else "à importer"
        elif p.suffix.lower() == ".xls":
            e = Element(chemin=p, genre=genre or ("rejet" if "rejets" in p.name.lower() else "quartz"))
            e.date = date_quartz(p)
            if not e.date:
                e.etat = "date introuvable"
            else:
                if e.genre == "rejet":
                    e.destination = rejets / f"{e.date}_{RE_PREFIXE_JOUR.sub('', p.name)}"
                else:
                    e.destination = edf / f"{QUARTZ_PREFIXE}{e.date}.xls"
                e.etat = "déjà présent" if e.destination.exists() else "à importer"
        else:
            e = Element(chemin=p, genre="inconnu", etat="non reconnu")
        out.append(e)
    return out


def importer(depot: Path, cfg: dict, con=None, quand: datetime | None = None) -> Bilan:
    """Déplace ce qui est datable vers son dossier de journée ; enregistre les instances dans vir_imports."""
    bilan = Bilan()
    quand = (quand or datetime.now()).strftime("%Y-%m-%d %H:%M:%S")
    for e in scanner(depot, cfg):
        if e.etat != "à importer":
            bilan.ignores.append(e)
            continue
        e.destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(e.chemin), str(e.destination))
        if e.genre == "instance" and con is not None:
            with con:
                con.execute(
                    "INSERT INTO vir_imports(guid, date_ctrl, dossier, nb_fichiers, nb_envois, cible_seul, importe_le) "
                    "VALUES (?,?,?,?,?,?,?) ON CONFLICT(guid) DO NOTHING",
                    (e.guid, datetime.strptime(e.date, "%d%m%Y").strftime("%Y-%m-%d"), None,
                     e.nb_fichiers, e.nb_envois, 1, quand))
        bilan.importes.append(e)
    # une journée déposée entière et vidée par l'import ne laisse pas de dossier vide derrière elle
    for p in Path(depot).iterdir() if Path(depot).is_dir() else []:
        if p.is_dir() and RE_JOUR.fullmatch(p.name) and not any(p.iterdir()):
            p.rmdir()
    return bilan
