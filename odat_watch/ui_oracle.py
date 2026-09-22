"""Onglet Oracle Apps de l'interface : demandes concurrentes, lien Control-M, logs et diagnostics."""
from __future__ import annotations
import json
from datetime import datetime, timedelta

import pandas as pd
import streamlit as st

from db import connect, DB_PATH

PHASE_ICON = {"P": "⏳", "R": "▶", "C": "✔", "I": "⏸"}
STATUS_ICON = {"E": "✖", "G": "⚠", "X": "✖", "D": "✖", "T": "⏹"}
GRAVITE_ICON = {"bloquant": "🟥", "à reprendre": "🟧", "normal": "🟩", "à qualifier": "⬜"}


@st.cache_data(show_spinner=False)
def _charger(cache_key: tuple):
    """Charge les données Oracle ; ``cache_key`` invalide le cache après chaque import."""
    con = connect()
    try:
        return _charger_depuis(con)
    finally:
        con.close()


def _charger_depuis(con):
    """Charge uniquement les traitements et programmes provenant réellement d'Oracle EBS."""
    req = pd.read_sql_query("SELECT * FROM ora_requests WHERE source='oracle'", con)
    logs = pd.read_sql_query("SELECT * FROM ora_request_logs", con)
    progs = pd.read_sql_query("SELECT * FROM ora_programs WHERE source='oracle'", con)
    return req, logs, progs


def _stamp() -> tuple:
    """Clé de cache : compteurs + dernier rafraîchissement (robuste même si le mtime ne bouge pas)."""
    con = connect()
    try:
        demandes = con.execute(
            "SELECT COUNT(*), MAX(refreshed_at) FROM ora_requests WHERE source='oracle'"
        ).fetchone()
        logs = con.execute(
            "SELECT COUNT(*), MAX(loaded_at) FROM ora_request_logs"
        ).fetchone()
        programmes = con.execute(
            "SELECT COUNT(*), MAX(refreshed_at) FROM ora_programs WHERE source='oracle'"
        ).fetchone()
        return tuple(str(valeur or "") for groupe in (demandes, logs, programmes) for valeur in groupe)
    finally:
        con.close()


def _etat(r) -> str:
    if r["phase_code"] == "C":
        return f"{STATUS_ICON.get(r['status_code'], '✔')} {r['status'] or r['status_code']}"
    return f"{PHASE_ICON.get(r['phase_code'], '•')} {r['phase'] or r['phase_code']}"


def _filtre(df: pd.DataFrame, recherche: str, application: str | None) -> pd.DataFrame:
    if df.empty:
        return df
    if application and application.startswith("FIN"):
        pass  # les demandes chargées sont déjà filtrées par config (filtre_description)
    if recherche:
        m = pd.Series(False, index=df.index)
        for c in ("job_name", "program_short", "program_name", "description", "argument_text", "requestor"):
            if c in df.columns:
                m |= df[c].fillna("").astype(str).str.lower().str.contains(recherche, regex=False)
        df = df[m]
    return df


def _filtre_multi(df: pd.DataFrame, jobs=(), programmes=(), statuts=()) -> pd.DataFrame:
    """Filtres cumulables ; plusieurs valeurs d'un même critère sont combinées par OU."""
    if df.empty:
        return df.copy()
    resultat = df.copy()
    if jobs and "job_name" in resultat.columns:
        resultat = resultat[resultat["job_name"].isin(jobs)]
    if programmes and "program_short" in resultat.columns:
        resultat = resultat[resultat["program_short"].isin(programmes)]
    if statuts and "état" in resultat.columns:
        resultat = resultat[resultat["état"].isin(statuts)]
    return resultat


def render(application, recherche, now: datetime, kpi, badge):
    req, logs, progs = _charger(_stamp())
    st.caption("Source : traitements Oracle EBS réellement chargés, logs locaux analysés et référentiel réel. "
               "Les données de mock sont exclues.")

    if req.empty and logs.empty:
        st.info("Aucune donnée Oracle. Renseignez `config.ini` (copie de `config.ini.exemple`) puis cliquez "
                "« Demandes » dans la barre latérale, ou lancez `python oracle_refresh.py --test`.")
        return

    req = _filtre(req, recherche, application)
    # Les programmes génériques (lanceur DKA_SLAUNCHER…) ne portent aucune information métier : masqués.
    if not req.empty and "program_short" in req.columns:
        import forecast
        req = req[~req["program_short"].isin(forecast.GENERIQUES)]
    for c in ("request_date", "requested_start", "actual_start", "actual_completion", "refreshed_at"):
        if c in req.columns:
            req[c] = pd.to_datetime(req[c], errors="coerce")
    if not req.empty:
        req["état"] = req.apply(_etat, axis=1)
        req["durée_min"] = ((req["actual_completion"] - req["actual_start"]).dt.total_seconds() / 60).round(1)
        req["en_erreur"] = (req["phase_code"] == "C") & req["status_code"].isin(["E", "G", "X", "D"])

    # ------------------------------------------------------------ recherche multi
    req_avant_multi = req
    jobs_disponibles = (sorted(req["job_name"].dropna().astype(str).loc[lambda s: s.str.strip().ne("")].unique())
                        if not req.empty and "job_name" in req.columns else [])
    programmes_disponibles = (sorted(req["program_short"].dropna().astype(str).loc[lambda s: s.str.strip().ne("")].unique())
                              if not req.empty and "program_short" in req.columns else [])
    statuts_disponibles = (sorted(req["état"].dropna().astype(str).unique())
                           if not req.empty and "état" in req.columns else [])
    noms_programmes = {}
    if not req.empty and {"program_short", "program_name"}.issubset(req.columns):
        noms_programmes = (req.dropna(subset=["program_short"])
                           .drop_duplicates("program_short")
                           .set_index("program_short")["program_name"].fillna("").to_dict())

    col_jobs, col_programmes, col_statuts = st.columns([1.6, 1.5, 1])
    jobs_choisis = col_jobs.multiselect(
        "Jobs Control-M",
        jobs_disponibles,
        placeholder="Rechercher plusieurs jobs…",
        key="oracle_jobs_multi",
    )
    programmes_choisis = col_programmes.multiselect(
        "Programmes Oracle",
        programmes_disponibles,
        placeholder="Rechercher plusieurs programmes…",
        format_func=lambda code: f"{code} — {noms_programmes.get(code, '')}".rstrip(" —"),
        key="oracle_programmes_multi",
    )
    statuts_choisis = col_statuts.multiselect(
        "Statuts",
        statuts_disponibles,
        placeholder="Tous les statuts",
        key="oracle_statuts_multi",
    )
    req = _filtre_multi(req, jobs_choisis, programmes_choisis, statuts_choisis)
    st.caption(f"{len(req)} demande(s) affichée(s) sur {len(req_avant_multi)}.")

    # ------------------------------------------------------------ KPI
    c = st.columns(6)
    kpi(c[0], int((req["phase_code"] == "R").sum()) if not req.empty else 0, "▶ en cours")
    kpi(c[1], int((req["phase_code"] == "P").sum()) if not req.empty else 0, "⏳ en attente / planifiées")
    kpi(c[2], int(req["en_erreur"].sum()) if not req.empty else 0, "✖ en erreur / avertissement")
    kpi(c[3], int(req["job_name"].notna().sum()) if not req.empty else 0, "liées à un job Control-M")
    kpi(c[4], len(logs), "logs analysés")
    maj = req["refreshed_at"].max() if not req.empty else None
    kpi(c[5], f"{maj:%d/%m %H:%M}" if pd.notna(maj) else "—", "dernier rafraîchissement")

    s_err, s_next, s_all, s_logs, s_progs = st.tabs(
        ["✖ Erreurs et logs", "⏳ Ce soir / demain côté Oracle", "📋 Tous les traitements", "🧾 Logs chargés", "📚 Programmes"])

    cols_req = ["état", "request_id", "job_name", "program_short", "program_name", "requested_start", "actual_start",
                "actual_completion", "durée_min", "requestor", "argument_text", "completion_text"]

    # ------------------------------------------------------------ erreurs + logs
    with s_err:
        err = req[req["en_erreur"]].sort_values("actual_completion", ascending=False) if not req.empty else pd.DataFrame()
        # demandes dont on a un log avec erreurs, même sans ligne ora_requests (cas des logs copiés à la main)
        logs_err = logs[logs["erreurs"].fillna("[]") != "[]"] if not logs.empty else pd.DataFrame()
        if err.empty and logs_err.empty:
            st.success("Aucune demande en erreur sur la période chargée.")
        else:
            if not err.empty:
                st.markdown("#### Demandes terminées en erreur ou avertissement")
                st.dataframe(err[cols_req], use_container_width=True, hide_index=True, height=min(400, 38 * len(err) + 40))
            ids = sorted(set(err["request_id"].tolist() if not err.empty else []) | set(logs_err["request_id"].tolist()),
                         reverse=True)
            st.markdown("#### Diagnostic d'une demande")
            rid = st.selectbox("Request id", ids, format_func=lambda i: _libelle(i, req, logs))
            if rid:
                _detail_request(rid, req, logs)
            st.markdown("---")
            st.caption("Logs absents en local ? Générez la liste des chemins pour `copy_ebs_logs.sh` :")
            if st.button("📝 Générer list.txt des logs manquants"):
                import logs as logmod
                st.info(logmod.ecrire_liste())

    # ------------------------------------------------------------ ce soir / demain
    with s_next:
        if req.empty:
            st.info("Pas de demandes chargées.")
        else:
            fin = (now + timedelta(days=2)).replace(hour=6, minute=0, second=0, microsecond=0)
            nxt = req[(req["phase_code"].isin(["P", "R"])) & (req["requested_start"].fillna(now) <= fin)] \
                .sort_values("requested_start")
            st.caption("Demandes Oracle en cours ou planifiées (PHASE Pending/Running) jusqu'à après-demain 06:00. "
                       "Les demandes Control-M n'apparaissent ici qu'une fois soumises par le lanceur : l'onglet "
                       "« Ce soir » reste la prévision, celui-ci la confirmation.")
            if nxt.empty:
                st.info("Rien de planifié côté Oracle sur la plage.")
            else:
                n = nxt.copy()
                n["quand"] = n["requested_start"].dt.strftime("%a %d/%m %H:%M")
                n["récurrence"] = n["resubmit_interval"].fillna("").astype(str) + " " + n["resubmit_unit"].fillna("")
                st.dataframe(n[["état", "quand", "request_id", "job_name", "program_short", "program_name",
                                "récurrence", "requestor", "argument_text"]],
                             use_container_width=True, hide_index=True, height=min(600, 38 * len(n) + 40))

    # ------------------------------------------------------------ toutes
    with s_all:
        if req.empty:
            st.info("Pas de demandes chargées.")
        else:
            st.dataframe(req.sort_values("request_date", ascending=False)[cols_req],
                         use_container_width=True, hide_index=True, height=600)

    # ------------------------------------------------------------ logs
    with s_logs:
        if logs.empty:
            st.info("Aucun log analysé. Déposez des fichiers l<id>.req / o<id>.out dans les dossiers de "
                    "`config.ini [logs]` puis cliquez « Analyser les logs ».")
        else:
            l = logs.copy()
            l["nb_erreurs"] = l["erreurs"].apply(lambda s: sum(e.get("nb", 0) for e in json.loads(s or "[]")))
            l["codes"] = l["erreurs"].apply(lambda s: ", ".join(e["code"] for e in json.loads(s or "[]")))
            l = _filtre(l.rename(columns={"program": "program_name"}), recherche, application)
            st.dataframe(l[["request_id", "kind", "program_name", "started", "ended", "nb_erreurs", "codes", "path"]]
                         .sort_values(["request_id", "kind"], ascending=[False, True]),
                         use_container_width=True, hide_index=True, height=500)
            rid = st.selectbox("Voir le détail", sorted(l["request_id"].unique(), reverse=True), key="log_detail")
            if rid:
                _detail_request(rid, req, logs)

    # ------------------------------------------------------------ programmes
    with s_progs:
        if progs.empty:
            st.info("Référentiel vide : cliquez « Programmes » dans la barre latérale.")
        else:
            p = progs
            if recherche:
                m = pd.Series(False, index=p.index)
                for c in ("program_short", "program_name", "executable_name", "execution_file", "description"):
                    m |= p[c].fillna("").astype(str).str.lower().str.contains(recherche, regex=False)
                p = p[m]
            st.dataframe(p[["program_short", "program_name", "application_short", "execution_method",
                            "executable_name", "execution_file", "description"]],
                         use_container_width=True, hide_index=True, height=600)


def _libelle(rid, req, logs) -> str:
    r = req[req["request_id"] == rid]
    if not r.empty:
        r = r.iloc[0]
        return f"{rid} — {r['job_name'] or ''} {r['program_short'] or ''} — {r['état']}"
    l = logs[(logs["request_id"] == rid) & (logs["kind"] == "req")]
    return f"{rid} — {l.iloc[0]['program'] if not l.empty else 'log seul'}"


def _detail_request(rid, req, logs):
    r = req[req["request_id"] == rid]
    if not r.empty:
        r = r.iloc[0]
        c = st.columns(4)
        c[0].markdown(f"**Job Control-M** : `{r['job_name'] or '—'}`")
        c[1].markdown(f"**Programme** : `{r['program_short']}`  \n{r['program_name']}")
        c[2].markdown(f"**Début / fin** : {r['actual_start']} → {r['actual_completion']}")
        c[3].markdown(f"**Statut** : {r['état']}  \n{r['completion_text'] or ''}")
        if r["argument_text"]:
            st.caption(f"Arguments : {r['argument_text']}")
        st.caption(f"Log : `{r['logfile_name'] or '?'}`  ·  Sortie : `{r['outfile_name'] or '?'}`")
    lr = logs[logs["request_id"] == rid]
    if lr.empty:
        st.warning("Aucun log local pour cette demande. Rapatriez l<id>.req et o<id>.out puis « Analyser les logs ».")
        return
    for _, l in lr.sort_values("kind", ascending=False).iterrows():  # req d'abord
        titre = "Journal (.req)" if l["kind"] == "req" else "Sortie (.out)"
        diag = json.loads(l["diagnostic"] or "[]")
        compt = json.loads(l["compteurs"] or "{}")
        lus = _entier(next((v for k, v in compt.items() if "lus" in k.lower()), None))
        ecrits = _entier(next((v for k, v in compt.items() if "crit" in k.lower()), None))
        zero_ecrit = lus and ecrits == 0
        with st.expander(f"{titre} — {l['path']}" + (f"  ·  {sum(d['nb'] for d in diag)} erreur(s)" if diag else ""),
                         expanded=bool(diag) or l["kind"] == "req"):
            if diag:
                for d in diag:
                    st.markdown(f"{GRAVITE_ICON.get(d['gravite'], '⬜')} **{d['code']}** × {d['nb']} — {d['explication']}  \n"
                                f"👉 {d['action']}")
            elif zero_ecrit:
                st.warning(f"{lus} enregistrements lus mais 0 ligne écrite : le fichier a été rejeté en totalité. "
                           "Le détail est dans la sortie (.out).")
            else:
                st.success("Aucune erreur détectée dans ce fichier.")
            if compt:
                st.table(pd.DataFrame({"valeur": compt}).astype(str))
            if l["fnd_messages"]:
                st.code(l["fnd_messages"], language="text")


def _entier(v):
    try:
        return int(str(v).strip().replace(" ", "").replace(".", "").replace(",", ""))
    except (TypeError, ValueError):
        return None
