"""Decouverte des instances de virement pour une date donnee."""
from pathlib import Path

from cv.model import Instance


def _guids(directory: Path) -> dict:
    if not directory.is_dir():
        return {}
    return {d.name: d for d in directory.iterdir() if d.is_dir()}


def discover_instances(racine, date: str) -> list:
    racine = Path(racine)
    src = _guids(racine / f"{date}_source")
    cib = _guids(racine / f"{date}_cible")
    instances = []
    for guid in sorted(set(src) | set(cib)):
        instances.append(Instance(
            guid=guid,
            source_dir=src.get(guid),
            cible_dir=cib.get(guid),
        ))
    return instances
