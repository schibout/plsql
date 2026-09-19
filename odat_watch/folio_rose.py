"""Folio Rose : lecture des exports, import SQLite, statuts, rapprochements et contrôle Oracle.

Portage de ControleFolioRose/Verifier_Factures.ps1 : mêmes règles de lecture (encodage CP850/1252/BOM,
deux lignes de filtres, en-têtes tolérants aux accents, montants à virgule), mêmes trois requêtes Oracle
(CLIENTS / FOURNISSEURS / GL par folio + fichier de base), même statut OK/KO par ligne.
S'y ajoute ce que le .ps1 ne fait pas : les lignes d'un même folio + fichier de base dont la somme des
« Écarts Débit » fait 0 peuvent être rapprochées, et ces rapprochements sont mémorisés (empreinte de ligne
stable d'un export à l'autre).
"""
from __future__ import annotations
import csv
import hashlib
import io
import re
import sqlite3
import unicodedata
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path

import pandas as pd

TOL = 0.005          # tolérance sur les montants (centime)

# colonne interne -> libellés acceptés (comparés après normaliser())
COLONNES = {
    "folio": ["folio"], "date": ["date"],
    "amont_nb": ["app amont nb piece"], "amont_debit": ["app amont debit"], "amont_credit": ["app amont credit"],
    "si_nb": ["si finance nb piece"], "si_debit": ["si finance debit"], "si_credit": ["si finance credit"],
    "ecart_nb": ["ecarts nb piece", "ecart nb piece"], "ecart_debit": ["ecarts debit", "ecart debit"],
    "ecart_credit": ["ecarts credit", "ecart credit"],
    "commentaire": ["commentaire"], "fichier": ["nom fichier transmis"],
    "piece_jointe": ["presence d'une piece jointe"], "lettrage": ["lettrage"],
}
MONTANTS = ["amont_nb", "amont_debit", "amont_credit", "si_nb", "si_debit", "si_credit",
            "ecart_nb", "ecart_debit", "ecart_credit"]
OBLIGATOIRES = {"folio": "Folio", "fichier": "Nom fichier transmis", "ecart_debit": "Ecarts Débit"}
TYPES = ("CLIENTS", "FOURNISSEURS", "GL", "AUTRE")


# ------------------------------------------------------------------ règles élémentaires

def normaliser(s: str | None) -> str:
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", s).strip().lower()


def detecter_encodage(octets: bytes) -> str:
    """BOM → utf-8-sig ; accents CP850 (0x80-0x9F) majoritaires → cp850 ; sinon cp1252 (règle du .ps1)."""
    if octets[:3] == b"\xef\xbb\xbf":
        return "utf-8-sig"
    n_oem = sum(1 for b in octets if 0x80 <= b <= 0x9F)
    n_ansi = sum(1 for b in octets if b >= 0xC0)
    return "cp850" if n_oem > n_ansi else "cp1252"


def montant(txt: str | None) -> tuple[float, bool]:
    """(valeur, illisible). Vide ou '-' → 0 ; illisible → 0 et True, comme Parse-Montant."""
    v = (txt or "").strip().replace(" ", "").replace(" ", "").replace(",", ".")
    if v in ("", "-"):
        return 0.0, False
    try:
        return float(v), False
    except ValueError:
        return 0.0, True


def type_flux(fichier: str | None) -> str:
    f = (fichier or "").upper()
    if not f:
        return "AUTRE"
    if "CLIENTS" in f:
        return "CLIENTS"
    if "FOURNISSEURS" in f:
        return "FOURNISSEURS"
    if "GL" in f or "GRAND LIVRE" in f or "CDPG" in f:
        return "GL"
    return "AUTRE"


def fichier_base(fichier: str | None) -> str:
    f = (fichier or "").strip()
    i = f.find("_ST_")
    return f[:i] if i > 0 else f


def date_export_du_nom(nom: str) -> date | None:
    m = re.search(r"ExportCSV-(\d{2})-(\d{2})-(\d{4})", nom)
    return date(int(m.group(3)), int(m.group(2)), int(m.group(1))) if m else None


def _date_fr(txt: str | None) -> date | None:
    try:
        return datetime.strptime((txt or "").strip()[:10], "%d/%m/%Y").date()
    except ValueError:
        return None


def empreinte(folio, date_txt, fichier, amont_debit, si_debit) -> str:
    cle = f"{(folio or '').strip()}|{(date_txt or '').strip()}|{(fichier or '').strip()}|{amont_debit:.2f}|{si_debit:.2f}"
    return hashlib.sha1(cle.encode("utf-8")).hexdigest()


# ------------------------------------------------------------------ lecture

@dataclass
class Export:
    nom: str
    date_export: date
    periode_debut: str | None
    periode_fin: str | None
    encodage: str
    file_hash: str
    lignes: pd.DataFrame
    nb_montants_illisibles: int = 0
    id: int | None = None


def _index_colonnes(entete: list[str]) -> dict[str, int]:
    exact = {h.strip(): i for i, h in enumerate(entete)}
    norm = {normaliser(h): i for i, h in enumerate(entete)}
    sans = {normaliser(h).replace(" ", ""): i for i, h in enumerate(entete)}
    out = {}
    for interne, libelles in COLONNES.items():
        for lib in libelles:
            for table, cle in ((exact, lib), (norm, normaliser(lib)), (sans, normaliser(lib).replace(" ", ""))):
                if cle in table:
                    out[interne] = table[cle]
                    break
            if interne in out:
                break
    return out


def lire_export(source: Path | str | bytes, nom: str | None = None, date_import: date | None = None) -> Export:
    """Lit un export Folio Rose (chemin ou octets). Lève ValueError si une colonne indispensable manque."""
    if isinstance(source, (str, Path)):
        chemin = Path(source)
        octets, nom = chemin.read_bytes(), nom or chemin.name
    else:
        octets, nom = source, nom or "export.csv"
    enc = detecter_encodage(octets)
    lignes = octets.decode(enc, errors="replace").splitlines()
    periode_debut = periode_fin = None
    if lignes and re.match(r"^﻿?Folio[;,\t]Ecart", lignes[0]):
        champs = re.split(r"[;,\t]", lignes[1]) if len(lignes) > 1 else []
        periode_debut = champs[2].strip() if len(champs) > 2 else None
        periode_fin = champs[3].strip() if len(champs) > 3 else None
        lignes = lignes[2:]
    if not lignes:
        raise ValueError("Fichier vide.")
    entete_txt = lignes[0].lstrip("﻿")
    sep = "\t" if "\t" in entete_txt else ("," if ("," in entete_txt and ";" not in entete_txt) else ";")
    rows = list(csv.reader(io.StringIO("\n".join([entete_txt] + lignes[1:])), delimiter=sep))
    entete, data = rows[0], rows[1:]
    idx = _index_colonnes(entete)
    manquantes = [lib for cle, lib in OBLIGATOIRES.items() if cle not in idx]
    if manquantes:
        raise ValueError(f"Colonnes indispensables absentes : {', '.join(manquantes)}")

    date_export = date_export_du_nom(nom) or date_import or date.today()
    enregs, illisibles = [], 0
    for num, r in enumerate(data, start=1):
        if not any(c.strip() for c in r):
            continue
        r = r + [""] * (len(entete) - len(r))
        val = {cle: (r[i].strip() if i < len(r) else "") for cle, i in idx.items()}
        e = {c: val.get(c, "") for c in COLONNES}
        for c in MONTANTS:
            e[c], ill = montant(val.get(c))
            illisibles += ill
        if not e["folio"] or not e["fichier"]:
            e["type"] = "AUTRE"
        else:
            e["type"] = type_flux(e["fichier"])
        e["fichier_base"] = fichier_base(e["fichier"])
        d = _date_fr(e["date"])
        e["age_j"] = (date_export - d).days if d else None
        e["empreinte"] = empreinte(e["folio"], e["date"], e["fichier"], e["amont_debit"], e["si_debit"])
        e["num"] = num
        enregs.append(e)
    colonnes = ["num", "empreinte", "folio", "date", "type", "fichier", "fichier_base", *MONTANTS,
                "commentaire", "piece_jointe", "lettrage", "age_j"]
    df = pd.DataFrame(enregs, columns=colonnes)
    return Export(nom=nom, date_export=date_export, periode_debut=periode_debut, periode_fin=periode_fin,
                  encodage=enc, file_hash=hashlib.sha1(octets).hexdigest(), lignes=df,
                  nb_montants_illisibles=illisibles)
