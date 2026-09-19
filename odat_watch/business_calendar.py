"""Lecture du calendrier de clôture actif."""
from __future__ import annotations

from datetime import date, datetime
import sqlite3

import pandas as pd


def active_events(con: sqlite3.Connection, start: date | datetime, end: date | datetime) -> pd.DataFrame:
    """Opérations du calendrier actif qui tombent dans [start, end]."""
    start_s = pd.Timestamp(start).date().isoformat()
    end_s = pd.Timestamp(end).date().isoformat()
    return pd.read_sql_query("""
        SELECT e.*, i.nom_fichier, i.importe_le
        FROM calendar_events e JOIN calendar_imports i ON i.id=e.import_id
        WHERE i.statut='active' AND e.date_operation BETWEEN ? AND ?
        ORDER BY e.date_operation, e.moment, e.id
    """, con, params=(start_s, end_s))


def context_for_range(con: sqlite3.Connection, start: date | datetime, end: date | datetime) -> tuple[str, pd.DataFrame]:
    events = active_events(con, start, end)
    if events.empty:
        return "Nuit ordinaire / calendrier non renseigné", events
    offsets = ", ".join(dict.fromkeys(events["decalage_j"].dropna().astype(str)))
    return f"Clôture : {offsets or 'jalon métier'}", events


def is_close_range(con: sqlite3.Connection, start: date | datetime, end: date | datetime) -> bool:
    return not active_events(con, start, end).empty
