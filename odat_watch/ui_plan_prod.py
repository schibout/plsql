"""Sous-onglet Control-M › Plan de production : la bible des chaînes, mois par mois de J-7 à J+16."""
from __future__ import annotations

import contextlib
from datetime import date

import pandas as pd
import streamlit as st

import business_calendar
import plan_prod as pp
from db import connect

MOIS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre",
        "novembre", "décembre"]
FIXES = ["chaine", "description", "categorie", "planification", "ctm", "planification_observee", "origine", "ecarts"]
LIBELLES = {"chaine": "chaîne", "categorie": "catégorie", "ctm": "Control-M",
            "planification_observee": "observée (ODAT)", "ecarts": "écarts"}
STYLES = {   # (fond, texte) par premier caractère de cellule
    "✔": ("#E3F4EA", "#1F7A45"), "✖": ("#FBE4E1", "#B42318"), "▶": ("#E3ECFD", "#2F6FED"),
    "⏸": ("#FBF1D0", "#8A6A00"), pp.NON_OBSERVE: ("#EEF0F3", "#5B6573"),
    "⊘": ("#F3EEF8", "#7A5C99"),
    pp.SANS_PHOTO: ("#F6F7F9", "#8A94A6"), pp.PREVU: ("#F2F5FA", "#8A94A6"),
}
LEGENDE = ("✔ OK · ✖ en erreur · ▶ en cours · ⏸ en attente · ⊘ ordonnancée mais jamais partie (chiffre = nb de jobs) · **+** tourné hors planification · "
           f"{pp.NON_OBSERVE} prévu mais absent des photos du jour · {pp.PREVU} prévu, à venir · "
           f"{pp.SANS_PHOTO} prévu, aucune photo ce jour-là")


def _style(v) -> str:
    if not isinstance(v, str) or not v:
        return ""
    fond, texte = STYLES.get(v[0], ("", ""))
    css = f"background-color:{fond};color:{texte};text-align:center" if fond else ""
    return css + (";font-weight:700;color:#6D28D9" if v.endswith("+") else "")


def _grille_stylee(df: pd.DataFrame, jours: list[str]):
    styler = df.style
    return getattr(styler, "map", getattr(styler, "applymap", None))(_style, subset=jours)


def _nom_mois(a: int, m: int) -> str:
    j = pp.jour_j(a, m)
    return f"{MOIS[m - 1].capitalize()} {a} · J = {pp.JOURS[j.weekday()]} {j:%d/%m}"


def _mois_par_defaut(mois: list[tuple[int, int]], df_runs: pd.DataFrame) -> int:
    """La dernière clôture passée : le dernier mois dont le J est couvert par les photos."""
    if df_runs.empty:
        return len(mois) - 1
    fin = max(df_runs["odate"])
    commences = [i for i, (a, m) in enumerate(mois) if pp.jour_j(a, m) <= fin]
    return commences[-1] if commences else len(mois) - 1


def _section_referentiel(con, ref: pd.DataFrame, df_runs: pd.DataFrame) -> None:
    """La bible n'a servi qu'au premier chargement : ensuite le référentiel suit les photos ODAT."""
    synchro = pp.derniere_synchro(con)
    bible = ref["importe_le"].dropna().min() if not ref.empty else None
    c1, c2 = st.columns([1, 3])
    if c1.button("🔄 Synchroniser avec ODAT", key="pdp_synchro", type="primary",
                 help="Ajoute les chaînes nouvelles, passe « supprimée » une chaîne absente des photos depuis "
                      f"{pp.OUBLI_JOURS} jours, réactive celle qui revient, aligne la planification sur celle "
                      "observée (sauf planification saisie à la main)."):
        st.session_state["pdp_journal"] = pp.synchroniser(con, df_runs)
        st.rerun()
    c2.caption(f"Référentiel : {int((ref['statut'] != 'supprimee').sum()) if not ref.empty else 0} chaîne(s) active(s). "
               + (f"Bible `docs/{pp.BIBLE.name}` chargée une seule fois le {bible} ; " if bible else "")
               + (f"dernière synchronisation ODAT le {synchro}." if synchro else "jamais synchronisé avec ODAT."))
    journal = st.session_state.get("pdp_journal")
    if journal is not None:
        if journal.empty:
            st.success("Synchronisation ODAT : le plan de production était déjà à jour.")
        else:
            resume = ", ".join(f"{n} {c}" for c, n in journal["changement"].value_counts().items())
            with st.expander(f"Synchronisation ODAT : {resume}", expanded=True):
                st.dataframe(journal, hide_index=True, use_container_width=True, height=min(400, 36 * len(journal) + 40))


def _bandeau(con, cal: pd.DataFrame, entetes: list[str]) -> None:
    jalons = business_calendar.active_events(con, cal["date"].min(), cal["date"].max())
    par_jour = jalons.groupby("date_operation").size() if not jalons.empty else pd.Series(dtype=int)
    lignes = {
        "Control-M": list(cal["label_ctm"]),
        "jour": [pp.JOURS[d.weekday()] + ("" if o or d.weekday() >= 5 else " (férié)")
                 for d, o in zip(cal["date"], cal["ouvre"])],
        "jalons clôture": [str(par_jour.get(d.isoformat(), "")) for d in cal["date"]],
    }
    st.dataframe(pd.DataFrame(lignes, index=entetes).T, use_container_width=True, height=142)
    if not jalons.empty:
        with st.expander(f"Jalons du calendrier de clôture sur la fenêtre ({len(jalons)})"):
            labels = dict(zip(cal["date"].map(date.isoformat), cal["label_j"]))
            t = jalons.assign(J=jalons["date_operation"].map(labels).fillna(""),
                              libellé=jalons[["arrete", "traitement", "restitution"]].fillna("")
                              .agg(" · ".join, axis=1).str.strip(" ·"))
            st.dataframe(t[["date_operation", "J", "decalage_j", "moment", "libellé"]], hide_index=True,
                         use_container_width=True)


def _qualifier(con, ref: pd.DataFrame, synth: pd.DataFrame) -> None:
    with st.expander("✏️ Qualifier et enrichir le référentiel"):
        nouvelles = synth[synth["origine"] == "Nouvelle"]
        if not nouvelles.empty and st.button(f"Ajouter les {len(nouvelles)} chaîne(s) nouvelle(s) au référentiel",
                                             key="pdp_ajouter",
                                             help="Statut « nouvelle », catégorie « À qualifier », planification observée."):
            st.toast(f"{pp.ajouter(con, nouvelles)} chaîne(s) ajoutée(s).", icon="✅")
            st.rerun()
        planifs = dict(zip(synth["chaine"], synth["planification_observee"]))
        candidats = [c for c, p in zip(ref["code"], ref["planification"])
                     if planifs.get(c) not in (None, "", "variable") and planifs[c] != (p or "")]
        choix = st.multiselect("Adopter la planification observée pour…", candidats, key="pdp_adopter_sel",
                               format_func=lambda c: f"{c} : {ref.set_index('code').at[c, 'planification'] or '∅'} → {planifs[c]}")
        if choix and st.button("Adopter", key="pdp_adopter"):
            st.toast(f"{pp.adopter_planification(con, {c: planifs[c] for c in choix})} planification(s) mise(s) à jour.",
                     icon="✅")
            st.rerun()
        st.caption("Planification : jours de semaine pour une quotidienne (« lun mar mer jeu ven »), J±n sinon "
                   "(« J-2, J, J+4 ») ; les labels Control-M sont acceptés (« L3, D4 »).")
        edite = st.data_editor(
            ref[["code", *pp.EDITABLES, "planification_ref", "jours_reference", "source", "maj_le"]],
            key="pdp_editeur", hide_index=True, use_container_width=True, height=420,
            disabled=["code", "planification_ref", "jours_reference", "source", "maj_le"],
            column_config={
                "statut": st.column_config.SelectboxColumn("statut", options=["bible", "nouvelle", "supprimee"]),
                "planification_ref": st.column_config.TextColumn("règle écrite (bible)"),
                "jours_reference": st.column_config.TextColumn("jours cochés (bible)"),
            })
        if st.button("Enregistrer les modifications", key="pdp_enregistrer"):
            st.toast(f"{pp.enregistrer(con, edite)} chaîne(s) modifiée(s).", icon="✅")
            st.rerun()


def _fiche(df_runs, profs, programmes, cal, entetes, synth: pd.DataFrame) -> None:
    st.markdown("#### Fiche chaîne")
    chaine = st.selectbox("Chaîne", list(synth["chaine"]), index=None, key="pdp_fiche",
                          placeholder="Choisir une chaîne…",
                          format_func=lambda c: f"{c} — {synth.set_index('chaine').at[c, 'description']}")
    if not chaine:
        return
    r = synth.set_index("chaine").loc[chaine]
    st.markdown(f"**{chaine}** · {r['description']}  \n"
                f"catégorie **{r['categorie'] or '—'}** · planification **{r['planification'] or '—'}**"
                + (f" (Control-M {r['ctm']})" if r["ctm"] else "")
                + f" · observée **{r['planification_observee'] or '—'}** · {r['origine']}")
    jobs = sorted((p for p in profs.values() if p.group_name == chaine),
                  key=lambda p: (p.decalage_jour, p.heure_mediane or pd.Timestamp.max.time(), p.job_name))
    if not jobs:
        st.info("Aucun job de cette chaîne dans les photos ODAT.")
        return
    st.dataframe(pd.DataFrame([dict(
        job=p.job_name, description=p.description, **{"programme Oracle": programmes.get(p.job_name, "")},
        script=p.member, heure=p.heure_txt + (" (J+1)" if p.decalage_jour else ""),
        **{"durée (min)": None if p.duree_mediane is None else round(p.duree_mediane, 1),
           "fiabilité": None if p.taux_ok is None else round(p.taux_ok)},
        fréquence=p.frequence, jours=" ".join(pp.JOURS[i] for i in sorted(p.jours_semaine)),
        exécutions=p.nb_exec) for p in jobs]), hide_index=True, use_container_width=True,
        column_config={"fiabilité": st.column_config.ProgressColumn("fiabilité", min_value=0, max_value=100,
                                                                      format="%d %%")})
    g = pp.grille(df_runs[df_runs["group_name"] == chaine], cal, cle="job_name")
    if g.empty:
        st.caption("Aucune exécution de cette chaîne sur la fenêtre du mois.")
        return
    heads = dict(zip(cal["date"], entetes))
    g["cellule"] = [f"{pp.ICONES.get(s, '•')}" for s in g["statut"]]
    t = (g.assign(jour=g["odate"].map(heads)).pivot(index="job_name", columns="jour", values="cellule")
         .reindex(columns=entetes).fillna("").reset_index().rename(columns={"job_name": "job"}))
    st.dataframe(_grille_stylee(t, entetes), hide_index=True, use_container_width=True)


def render(df_runs: pd.DataFrame, profs: dict, programmes: dict[str, str], kpi) -> None:
    st.caption("Le plan de production des chaînes Control-M, amorcé avec la bible de Lionel (juin 2025) puis tenu à "
               "jour par les photos ODAT, "
               "mois par mois autour de la clôture : J = dernier jour ouvré du mois, de J-7 à J+16 en jours ouvrés "
               "(Control-M en rappel : J-6 = L7, J = L1, J+1 = D1).")
    with contextlib.closing(connect()) as con:
        ref = pp.referentiel(con)
        if ref.empty and pp.BIBLE.exists():
            st.toast(pp.importer_bible(con, pp.BIBLE.name, pp.BIBLE.read_bytes()), icon="📚")
            ref = pp.referentiel(con)
        _section_referentiel(con, ref, df_runs)

        mois = pp.mois_disponibles(df_runs)
        a, m = st.selectbox("Mois comptable", mois, index=_mois_par_defaut(mois, df_runs), key="pdp_mois",
                            format_func=lambda am: _nom_mois(*am))
        cal = pp.calendrier(a, m)
        entetes = [pp.entete(d, lj) for d, lj in zip(cal["date"], cal["label_j"])]
        _bandeau(con, cal, entetes)

        synth = pp.synthese(df_runs, cal, ref)
        synth.insert(synth.columns.get_loc("planification") + 1, "ctm", synth["planification"].map(pp.en_ctm))

        c = st.columns(5)
        kpi(c[0], int((ref["statut"] != "supprimee").sum()) if not ref.empty else 0, "chaînes au référentiel", "neutral")
        kpi(c[1], int((synth[entetes].apply(lambda s: s.str[:1].isin([i for s_, i in pp.ICONES.items() if s_ != pp.NON_LANCE]))).any(axis=1).sum()),
            "chaînes observées sur le mois", "run")
        kpi(c[2], int((synth["origine"] == "Nouvelle").sum()), "nouvelles, à qualifier", "warn")
        kpi(c[3], int(synth["origine"].str.startswith(("Jamais", "Plus vue")).sum()), "absentes des photos", "err")
        kpi(c[4], int((synth["ecarts"] != "").sum()), "écarts de planification", "warn")

        f1, f2, f3, f4 = st.columns([2, 1.3, 1.3, 1])
        recherche = f1.text_input("Recherche", key="pdp_recherche",
                                  placeholder="Chaîne, description, job ou programme Oracle…").strip().lower()
        categories = f2.multiselect("Catégorie", sorted(synth["categorie"].replace("", "—").unique()),
                                    key="pdp_categories", placeholder="Toutes")
        origines = f3.multiselect("Origine", ["Référentiel", "Ajoutée", "Nouvelle", "Jamais vue", "Plus vue", "Supprimée"],
                                  key="pdp_origines", placeholder="Toutes")
        ecarts = f4.checkbox("Écarts uniquement", key="pdp_ecarts")
        masquer = f4.checkbox("Masquer supprimées", value=True, key="pdp_masquer")

        vue = synth
        if recherche:
            par_chaine: dict[str, list[str]] = {}
            for p in profs.values():
                par_chaine.setdefault(p.group_name, []).extend([p.job_name, programmes.get(p.job_name, "")])
            texte = (vue["chaine"] + " " + vue["description"].fillna("") + " "
                     + vue["chaine"].map(lambda ch: " ".join(par_chaine.get(ch, [])))).str.lower()
            vue = vue[texte.str.contains(recherche, regex=False)]
        if categories:
            vue = vue[vue["categorie"].replace("", "—").isin(categories)]
        if origines:
            vue = vue[vue["origine"].str.replace(r" depuis .*", "", regex=True).isin(origines)]
        if ecarts:
            vue = vue[vue["ecarts"] != ""]
        if masquer:
            vue = vue[vue["origine"] != "Supprimée"]

        st.caption(f"{len(vue)} chaîne(s) affichée(s) sur {len(synth)}. " + LEGENDE)
        if vue.empty:
            st.info("Aucune chaîne ne correspond aux filtres.")
        else:
            table = vue[[*FIXES, *entetes]].rename(columns=LIBELLES)
            st.dataframe(_grille_stylee(table, entetes), hide_index=True, use_container_width=True,
                         height=min(720, 36 * len(table) + 40),
                         column_config={"chaîne": st.column_config.TextColumn(width="medium"),
                                        "description": st.column_config.TextColumn(width="medium"),
                                        "écarts": st.column_config.TextColumn(width="medium")})

        _qualifier(con, ref, synth)
    _fiche(df_runs, profs, programmes, cal, entetes, vue if not vue.empty else synth)
