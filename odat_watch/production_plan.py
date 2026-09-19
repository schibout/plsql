"""Construction d'un plan de nuit partageable par l'interface et l'assistant."""
from __future__ import annotations

from datetime import datetime
import sqlite3

import pandas as pd

import business_calendar
import forecast


def construire(con: sqlite3.Connection, profs, debut: datetime, fin: datetime,
               derniere_photo: pd.DataFrame | None = None) -> tuple[pd.DataFrame, pd.DataFrame, str]:
    """Construit le plan et retourne aussi les opérations métier de la période."""
    plan = forecast.prevision(profs, debut, fin, derniere_photo)
    contexte, events = business_calendar.context_for_range(con, debut, fin)
    if not plan.empty:
        plan = plan.copy()
        plan["contexte"] = contexte
        plan["fin_prevue"] = plan["heure_prevue"] + pd.to_timedelta(plan["duree_min"].clip(lower=6), unit="m")
        plan["confiance"] = plan["nb_obs"].map(lambda n: "Élevée" if n >= 20 else "Moyenne" if n >= 6 else "Faible")
    return plan, events, contexte


def filtrer_contexte(plan: pd.DataFrame, events: pd.DataFrame, mode: str) -> pd.DataFrame:
    """Le filtre de contexte est appliqué sans effacer les cas sans calendrier."""
    if mode == "Toutes" or plan.empty:
        return plan
    if mode == "Clôture":
        return plan if not events.empty else plan.iloc[0:0]
    if mode == "Hors clôture":
        return plan if events.empty else plan.iloc[0:0]
    # "Inconnu" : pas de calendrier actif visible sur la période.
    return plan if events.empty else plan.iloc[0:0]
