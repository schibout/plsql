"""Programmation du contrôle du matin via le Planificateur de tâches Windows (schtasks).

La tâche lance chaque jour `python controle_matin.py --rapport` : contrôle + HTML + historique,
que l'application soit ouverte ou non. Le poste doit être allumé et la session ouverte à l'heure dite.
"""
from __future__ import annotations
import csv
import io
import re
import subprocess
import sys
from pathlib import Path

NOM_TACHE = "ODATWatch_ControleMatin"
SCRIPT = Path(__file__).resolve().parent / "controle_matin.py"
_HEURE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def commande(heure: str, python: str | None = None, script: str | Path | None = None) -> list[str]:
    """Arguments de `schtasks /Create` pour une exécution quotidienne à HH:MM."""
    if not _HEURE.match(heure):
        raise ValueError(f"Heure attendue au format HH:MM, reçu {heure!r}")
    py = python or sys.executable
    sc = str(script or SCRIPT)
    return ["schtasks", "/Create", "/TN", NOM_TACHE, "/SC", "DAILY", "/ST", heure,
            "/TR", f'"{py}" "{sc}" --rapport', "/F"]


def _run(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(args, capture_output=True, text=True, encoding="cp850", errors="replace")


def creer(heure: str) -> str:
    r = _run(commande(heure))
    if r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or f"schtasks a renvoyé {r.returncode}")
    return r.stdout.strip()


def supprimer() -> str:
    r = _run(["schtasks", "/Delete", "/TN", NOM_TACHE, "/F"])
    if r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or f"schtasks a renvoyé {r.returncode}")
    return r.stdout.strip()


def _parse_etat(texte_csv: str) -> dict | None:
    """Sortie de `schtasks /Query /FO CSV /V`, lue par position : les en-têtes dépendent de la langue."""
    lignes = list(csv.reader(io.StringIO(texte_csv)))
    if len(lignes) < 2 or len(lignes[1]) < 7:
        return None
    l = lignes[1]
    # Tâche jamais exécutée : Windows renvoie la date sentinelle 30/11/1999 et le code 267011.
    derniere = "" if l[5].startswith("30/11/1999") else l[5]
    resultat = "" if l[6] == "267011" else l[6]
    return {"prochaine": l[2], "statut": l[3], "derniere": derniere, "dernier_resultat": resultat}


def etat() -> dict | None:
    """None si la tâche n'existe pas."""
    r = _run(["schtasks", "/Query", "/TN", NOM_TACHE, "/FO", "CSV", "/V"])
    if r.returncode != 0:
        return None
    return _parse_etat(r.stdout)
