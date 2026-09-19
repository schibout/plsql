"""Dossiers d'import ODAT choisis par l'utilisateur : mémorisés dans odat.db (table parametres),
sélectionnés via la boîte de dialogue Windows. Les sources par défaut restent celles d'ingest.py."""
from __future__ import annotations
import sqlite3
import subprocess
import sys
from pathlib import Path

from ingest import DOWNLOADS, ODAT_DIR

SOURCES_DEFAUT = [ODAT_DIR, DOWNLOADS]
CLE = "import.dossiers"
SEP = ";"

# La boîte de dialogue tkinter tourne dans un sous-processus : Streamlit exécute le script dans un
# thread secondaire, où Tk n'est pas fiable, et un dialogue bloquant ne doit pas figer le serveur.
_SCRIPT_DIALOGUE = (
    "import tkinter as tk; from tkinter import filedialog; r = tk.Tk(); r.withdraw(); "
    "r.attributes('-topmost', True); print(filedialog.askdirectory(title='Dossier des fichiers ODAT') or '')"
)


def dossiers_memorises(con: sqlite3.Connection) -> list[Path]:
    row = con.execute("SELECT valeur FROM parametres WHERE cle = ?", (CLE,)).fetchone()
    if not row or not row[0]:
        return []
    return [Path(x) for x in row[0].split(SEP) if x]


def _enregistrer(con: sqlite3.Connection, dossiers: list[Path]) -> None:
    con.execute("INSERT INTO parametres(cle, valeur) VALUES (?, ?) "
                "ON CONFLICT(cle) DO UPDATE SET valeur = excluded.valeur",
                (CLE, SEP.join(str(d) for d in dossiers)))
    con.commit()


def ajouter_dossier(con: sqlite3.Connection, chemin: str | Path) -> None:
    txt = str(chemin).strip().strip('"')
    if not txt:
        return
    d = Path(txt)
    actuels = dossiers_memorises(con)
    if d not in actuels:
        _enregistrer(con, actuels + [d])


def retirer_dossier(con: sqlite3.Connection, chemin: str | Path) -> None:
    d = Path(str(chemin))
    _enregistrer(con, [x for x in dossiers_memorises(con) if x != d])


def commande_dialogue() -> list[str]:
    return [sys.executable, "-c", _SCRIPT_DIALOGUE]


def choisir_dossier() -> Path | None:
    """Ouvre le sélecteur de dossier Windows. None si annulé ou si tkinter est indisponible."""
    try:
        r = subprocess.run(commande_dialogue(), capture_output=True, text=True, encoding="utf-8", timeout=600)
    except (OSError, subprocess.SubprocessError):
        return None
    chemin = (r.stdout or "").strip()
    return Path(chemin) if r.returncode == 0 and chemin else None
