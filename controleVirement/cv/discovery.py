"""Decouverte des instances de virement pour une date donnee."""
from pathlib import Path

from cv.model import Instance


def _guids(directory: Path) -> dict:
    if not directory.is_dir():
        return {}
    return {d.name: d for d in directory.iterdir() if d.is_dir()}


def dossier_cible(racine, date: str) -> Path:
    """Dossier des instances du jour : JJMMAAAA (disposition courante) ou JJMMAAAA_cible (ancienne)."""
    racine = Path(racine)
    return racine / date if (racine / date).is_dir() else racine / f"{date}_cible"


def discover_instances(racine, date: str) -> list:
    """Une instance par sous-dossier (uuid) du dossier du jour ; le dossier JJMMAAAA_source, facultatif,
    apporte les DK en euros quand il existe (ancienne disposition)."""
    racine = Path(racine)
    src = _guids(racine / f"{date}_source")
    cib = _guids(dossier_cible(racine, date))
    instances = []
    for guid in sorted(set(src) | set(cib)):
        instances.append(Instance(
            guid=guid,
            source_dir=src.get(guid),
            cible_dir=cib.get(guid),
        ))
    return instances
