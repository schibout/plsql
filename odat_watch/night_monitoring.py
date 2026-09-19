"""Rapproche le plan prévisionnel avec la dernière photo Control-M disponible."""
from __future__ import annotations

from datetime import datetime, timedelta

import pandas as pd


def suivi(prevision: pd.DataFrame, photo: pd.DataFrame | None, now: datetime | None = None) -> pd.DataFrame:
    """Retourne une ligne par occurrence attendue, avec un diagnostic prudent.

    Une absence dans une photo est toujours "Non observé", jamais "Non exécuté".
    """
    now = now or datetime.now()
    out = prevision.copy()
    if out.empty:
        out["suivi"] = pd.Series(dtype=str)
        return out
    out["suivi"] = "À venir"
    out.loc[out["statut"] == "Ended OK", "suivi"] = "Terminé OK"
    out.loc[out["statut"] == "Ended Not OK", "suivi"] = "Erreur constatée"
    out.loc[out["statut"] == "Executing", "suivi"] = "En cours"
    out.loc[out["statut"] == "Wait for Event", "suivi"] = "En attente"
    deadline = out["heure_prevue"] + pd.to_timedelta(out["duree_min"].clip(lower=15) + 30, unit="m")
    missing = (out["statut"] == "à venir") & (deadline < now)
    out.loc[missing, "suivi"] = "Non observé — à vérifier"
    if photo is not None and not photo.empty:
        out["photo_le"] = photo.attrs.get("snap_time")
    else:
        out["photo_le"] = None
    return out


def compteurs(suivi_df: pd.DataFrame) -> dict[str, int]:
    labels = ("Terminé OK", "Erreur constatée", "En cours", "En attente", "Non observé — à vérifier")
    if suivi_df.empty:
        return {label: 0 for label in labels}
    counts = suivi_df["suivi"].value_counts()
    return {label: int(counts.get(label, 0)) for label in labels}
