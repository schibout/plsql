"""Onglet SQL : explorateur des tables SQLite et requêteur libre (lecture seule)."""
from __future__ import annotations
import re
import sqlite3
import time
from datetime import datetime

import pandas as pd
import streamlit as st

from db import connect, DB_PATH

EXEMPLES = {
    "Dernière photo Control-M : jobs FIN en erreur":
        """SELECT j.job_name, j.status, j.start_time, j.end_time, j.rerun, j.description
FROM ctm_jobs j
JOIN snapshots s ON s.id = j.snapshot_id
WHERE s.id = (SELECT id FROM snapshots ORDER BY snap_time DESC LIMIT 1)
  AND j.application = 'FIN-FINANCE'
  AND j.status = 'Ended Not OK'
ORDER BY j.start_time""",
    "Heure médiane de démarrage par job (approx.)":
        """SELECT job_name,
       COUNT(*)                                  AS nb_exec,
       MIN(time(start_time))                     AS plus_tot,
       MAX(time(start_time))                     AS plus_tard,
       ROUND(AVG((julianday(end_time) - julianday(start_time)) * 1440), 1) AS duree_moy_min
FROM (SELECT DISTINCT job_name, odate, start_time, end_time FROM ctm_jobs
      WHERE application = 'FIN-FINANCE' AND start_time IS NOT NULL AND task_type <> 'Dummy')
GROUP BY job_name
ORDER BY plus_tot""",
    "Ce qui a changé entre les deux dernières photos":
        """WITH s AS (SELECT id, snap_time, ROW_NUMBER() OVER (ORDER BY snap_time DESC) rn FROM snapshots),
a AS (SELECT job_name, status, start_time FROM ctm_jobs WHERE snapshot_id = (SELECT id FROM s WHERE rn = 2)),
b AS (SELECT job_name, status, start_time, end_time, description FROM ctm_jobs WHERE snapshot_id = (SELECT id FROM s WHERE rn = 1))
SELECT b.job_name, a.status AS avant, b.status AS apres, b.start_time, b.end_time, b.description
FROM b LEFT JOIN a ON a.job_name = b.job_name AND COALESCE(a.start_time,'') = COALESCE(b.start_time,'')
WHERE a.status IS NULL OR a.status <> b.status
ORDER BY b.start_time""",
    "Demandes Oracle en erreur avec leur job Control-M":
        """SELECT r.request_id, r.job_name, r.program_short, r.program_name, r.status,
       r.actual_start, r.actual_completion, r.completion_text
FROM ora_requests r
WHERE r.phase_code = 'C' AND r.status_code IN ('E','G','X')
ORDER BY r.actual_completion DESC""",
    "Logs analysés : codes d'erreur les plus fréquents":
        """SELECT je.value ->> '$.code' AS code,
       SUM(je.value ->> '$.nb')   AS occurrences,
       COUNT(DISTINCT l.request_id) AS demandes
FROM ora_request_logs l, json_each(l.erreurs) je
GROUP BY code
ORDER BY occurrences DESC""",
    "Photos chargées par jour":
        """SELECT odate, COUNT(*) AS nb_photos, MIN(time(snap_time)) AS premiere, MAX(time(snap_time)) AS derniere
FROM snapshots GROUP BY odate ORDER BY odate DESC""",
}

INTERDIT = re.compile(r"^\s*(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|REPLACE|ATTACH|DETACH|PRAGMA|VACUUM|REINDEX)\b", re.I)


def _schema() -> dict[str, pd.DataFrame]:
    con = connect()
    tables = [r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' ORDER BY name")]
    out = {}
    for t in tables:
        cols = pd.read_sql_query(f"PRAGMA table_info('{t}')", con)[["name", "type", "notnull", "pk"]]
        cols["notnull"] = cols["notnull"].astype(bool)
        cols["pk"] = cols["pk"].astype(bool)
        n = con.execute(f"SELECT COUNT(*) FROM '{t}'").fetchone()[0]
        cols.attrs["nb"] = n
        out[t] = cols
    con.close()
    return out


def _executer(sql: str, limite: int) -> tuple[pd.DataFrame, float]:
    con = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    try:
        t0 = time.perf_counter()
        df = pd.read_sql_query(sql, con)
        dt = time.perf_counter() - t0
    finally:
        con.close()
    return df.head(limite), dt


def render(kpi):
    schema = _schema()
    total = sum(c.attrs["nb"] for c in schema.values())
    c = st.columns(4)
    kpi(c[0], len(schema), "tables")
    kpi(c[1], f"{total:,}".replace(",", " "), "lignes au total")
    kpi(c[2], f"{DB_PATH.stat().st_size / 1e6:.1f} Mo" if DB_PATH.exists() else "—", "taille du fichier")
    kpi(c[3], DB_PATH.name, "base SQLite")

    gauche, droite = st.columns([1, 2.2], gap="large")

    # ---------------------------------------------------------------- explorateur
    with gauche:
        st.markdown("#### 🗄 Tables")
        for t, cols in schema.items():
            with st.expander(f"**{t}**  ·  {cols.attrs['nb']:,} lignes".replace(",", " ")):
                st.dataframe(cols.rename(columns={"name": "colonne", "notnull": "non nul", "pk": "clé"}),
                             hide_index=True, use_container_width=True, height=min(400, 36 * len(cols) + 40))
                b1, b2 = st.columns(2)
                if b1.button("SELECT *", key=f"sel_{t}", use_container_width=True):
                    st.session_state["sql"] = f"SELECT *\nFROM {t}\nLIMIT 200"
                    st.session_state["sql_run"] = True
                if b2.button("Aperçu", key=f"ap_{t}", use_container_width=True):
                    st.session_state["sql"] = f"SELECT {', '.join(cols['name'].head(8))}\nFROM {t}\nORDER BY rowid DESC\nLIMIT 50"
                    st.session_state["sql_run"] = True

    # ---------------------------------------------------------------- requêteur
    with droite:
        st.markdown("#### ⌨ Requêteur (lecture seule)")
        ex = st.selectbox("Exemples", ["— choisir un exemple —"] + list(EXEMPLES), label_visibility="collapsed")
        if ex in EXEMPLES and st.session_state.get("ex_prec") != ex:
            st.session_state["sql"] = EXEMPLES[ex]
            st.session_state["ex_prec"] = ex
        sql = st.text_area("SQL", st.session_state.get("sql", "SELECT * FROM snapshots ORDER BY snap_time DESC"),
                           height=220, key="sql_area", label_visibility="collapsed")
        st.session_state["sql"] = sql
        c1, c2, c3 = st.columns([1, 1, 2])
        run = c1.button("▶ Exécuter", type="primary", use_container_width=True) or st.session_state.pop("sql_run", False)
        limite = c2.selectbox("Lignes max", [100, 500, 2000, 10000], index=1, label_visibility="collapsed")
        c3.caption("Ctrl+Entrée dans la zone puis Exécuter. SQLite : `date()`, `time()`, `julianday()`, `json_each()`.")

        if run and sql.strip():
            if INTERDIT.match(sql):
                st.error("Lecture seule : seules les requêtes SELECT / WITH sont autorisées.")
            else:
                try:
                    df, dt = _executer(sql, limite)
                    st.session_state["sql_result"] = (df, dt, datetime.now())
                except Exception as e:  # noqa: BLE001
                    st.session_state["sql_result"] = None
                    st.error(f"{type(e).__name__} : {e}")
        if st.session_state.get("sql_result"):
            df, dt, quand = st.session_state["sql_result"]
            st.caption(f"{len(df)} ligne(s) · {dt * 1000:.0f} ms · {quand:%H:%M:%S}")
            st.dataframe(df, use_container_width=True, hide_index=True, height=min(520, 38 * len(df) + 40))
            st.download_button("⬇ CSV", df.to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"requete_{quand:%Y%m%d_%H%M%S}.csv", "text/csv")
