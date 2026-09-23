"""Sous-onglet Carte des flux : tous les flux qui entrent dans Oracle et en sortent, dessinés comme le schéma
« Flux pour FIN01 - ORACLE », avec l'état de chacun, et le référentiel qui les décrit (motif du nom de
fichier, interlocuteurs, attributs libres)."""
from __future__ import annotations
import contextlib

import pandas as pd
import streamlit as st
import streamlit.components.v1 as components
from pyvis.network import Network

import carte_flux as cf
import flux_ref as fx
from db import connect

METEO = {"ok": "☀️", "ecart": "🌧️", "inconnu": "⛅", "inactif": "🌫️"}
COLS_TABLE = {"meteo": "", "sens": "Sens", "application": "Appli", "nom_application": "Application",
              "objet": "Objet", "nature": "Nature", "domaine": "Domaine", "etat_libelle": "État",
              "vu_le": "Vu le", "detail": "Détail", "nb_interlocuteurs": "Contacts", "motif": "Motif"}
HAUTEUR_GRAPHE = 680


def _graphe_html(df: pd.DataFrame, objets: bool) -> str:
    """Graphe interactif façon Neo4j (vis-network embarqué, aucun accès réseau) : les nœuds se tirent à la
    souris, Oracle Finance reste au centre, les liens portent l'état du flux et la nature en pointillés."""
    g = cf.graphe(df)
    net = Network(height=f"{HAUTEUR_GRAPHE - 20}px", width="100%", directed=True, bgcolor="#F7F8FA",
                  font_color="#1F2937", cdn_resources="in_line")
    for n in g["noeuds"]:
        centre = n["id"] == cf.ORACLE_ID
        net.add_node(n["id"], label=n["label"], title=n["titre"], shape="dot", size=n["taille"],
                     color={"background": n["couleur"], "border": n["bordure"],
                            "highlight": {"background": n["couleur"], "border": "#1F2937"}},
                     borderWidth=3 if centre else 2, x=n["x"], y=n["y"], physics=not centre, fixed=centre,
                     font={"size": 16 if centre else 12, "color": n["police"] if centre else "#1F2937",
                           "face": "Segoe UI, Arial", "multi": False, "bold": centre,
                           "vadjust": 0 if centre else -2})
    for l in g["liens"]:
        net.add_edge(l["de"], l["vers"], title=l["titre"], color={"color": l["couleur"], "highlight": "#1F2937",
                                                                 "hover": "#1F2937"},
                     width=l["largeur"], dashes=l["tirets"], label=l["objet"] if objets else "",
                     smooth={"type": "curvedCW", "roundness": l["roundness"]}, arrows="to",
                     font={"size": 9, "color": "#4B5563", "strokeWidth": 3, "strokeColor": "#F7F8FA", "align": "middle"})
    net.barnes_hut(gravity=-5200, central_gravity=0.12, spring_length=210, spring_strength=0.02, damping=0.55,
                   overlap=0.25)
    html = net.generate_html()
    # Dans un cadre Streamlit, le canevas n'a pas encore sa taille quand vis-network cadre la vue : on recadre
    # une fois la physique stabilisée, puis à chaque redimensionnement du cadre.
    recadrage = """
<script type="text/javascript">
  (function () {
    function cadrer() { try { network.fit({animation: false}); } catch (e) {} }
    if (typeof network !== "undefined") {
      network.once("stabilizationIterationsDone", function () { setTimeout(cadrer, 50); });
      network.once("stabilized", function () { setTimeout(cadrer, 50); });
      setTimeout(cadrer, 700); setTimeout(cadrer, 2500);
      window.addEventListener("resize", cadrer);
    }
  })();
</script>
</body>"""
    return html.replace("</body>", recadrage, 1)


# ------------------------------------------------------------------ fiche d'un flux

def _fiche(con, code: str) -> None:
    f = fx.flux(con)
    fiche = f[f["code"] == code].iloc[0].to_dict()
    st.markdown(f"##### {METEO.get(cf.etat_flux(con, fiche)['etat'], '')} {fx.libelle(fiche)}")
    colonnes = {"application": st.column_config.TextColumn("Appli"),
                "nom_application": st.column_config.TextColumn("Application"),
                "domaine": st.column_config.SelectboxColumn("Domaine", options=list(fx.DOMAINES)),
                "sens": st.column_config.SelectboxColumn("Sens", options=list(fx.SENS)),
                "objet": st.column_config.TextColumn("Objet", width="medium"),
                "nature": st.column_config.SelectboxColumn("Nature", options=list(fx.NATURES)),
                "statut": st.column_config.SelectboxColumn("Statut", options=list(fx.STATUTS)),
                "type_flux": st.column_config.SelectboxColumn("Type", options=list(fx.TYPES)),
                "motif": st.column_config.TextColumn("Motif du nom de fichier", width="large"),
                "source_etat": st.column_config.SelectboxColumn("Source de l'état", options=list(fx.SOURCES_ETAT)),
                "dossier_unix": st.column_config.TextColumn("Dossier Unix", width="medium"),
                "commentaire": st.column_config.TextColumn("Commentaire", width="medium")}
    edit = st.data_editor(pd.DataFrame([{c: fiche.get(c, "") for c in fx.COLS_FLUX if c != "code"}]),
                          hide_index=True, use_container_width=True, key=f"cf_fiche_{code}", column_config=colonnes)
    nb, exemples = fx.apercu_motif(con, edit.iloc[0]["motif"])
    if str(edit.iloc[0]["motif"] or "").strip():
        (st.success if nb else st.warning)(f"Le motif reconnaît {nb} fichier(s) transmis connu(s)."
                                            + ("" if not exemples else "\n\n" + "\n".join(f"- `{e}`" for e in exemples)))
    else:
        st.caption("Sans motif, l'état de ce flux ne peut venir que d'une source d'état (virements, prélèvements, "
                   "relevés). Saisissez le motif des fichiers transmis pour le suivre par Ctrl Flux.")
    b1, b2 = st.columns([1, 1])
    if b1.button("💾 Enregistrer la fiche", key=f"cf_save_{code}", use_container_width=True):
        fx.enregistrer(con, {"code": code, **edit.iloc[0].to_dict()})
        st.session_state["cf_msg"] = "Fiche enregistrée."
        st.rerun()
    if b2.button("🗑 Supprimer ce flux", key=f"cf_del_{code}", use_container_width=True):
        fx.supprimer(con, code)
        st.session_state["cf_msg"] = f"Flux {code} supprimé."
        st.rerun()

    g1, g2 = st.columns(2)
    with g1:
        st.markdown("**Interlocuteurs** — qui appeler, selon le rôle")
        inter = fx.interlocuteurs(con, code)
        ed_i = st.data_editor(inter[fx.COLS_INTER] if not inter.empty else pd.DataFrame(columns=fx.COLS_INTER),
                              num_rows="dynamic", use_container_width=True, key=f"cf_inter_{code}",
                              column_config={"nom": st.column_config.TextColumn("Nom"),
                                             "role": st.column_config.SelectboxColumn("Rôle", options=list(fx.ROLES)),
                                             "mail": st.column_config.TextColumn("Mail"),
                                             "telephone": st.column_config.TextColumn("Téléphone"),
                                             "remarque": st.column_config.TextColumn("Remarque")})
        if st.button("💾 Enregistrer les interlocuteurs", key=f"cf_inter_save_{code}"):
            fx.remplacer_interlocuteurs(con, code, ed_i.to_dict("records"))
            st.session_state["cf_msg"] = "Interlocuteurs enregistrés."
            st.rerun()
    with g2:
        st.markdown("**Attributs libres** — clé / valeur, autant qu'il en faut")
        attrs = fx.attributs(con, code)
        df_a = pd.DataFrame(sorted(attrs.items()), columns=["cle", "valeur"]) if attrs else pd.DataFrame(columns=["cle", "valeur"])
        ed_a = st.data_editor(df_a, num_rows="dynamic", use_container_width=True, key=f"cf_attr_{code}",
                              column_config={"cle": st.column_config.TextColumn("Clé"),
                                             "valeur": st.column_config.TextColumn("Valeur", width="medium")})
        st.caption("Exemples : `criticite`, `heure_attendue`, `jours`, `ticket`, `procedure`, `job_ctm`.")
        if st.button("💾 Enregistrer les attributs", key=f"cf_attr_save_{code}"):
            fx.remplacer_attributs(con, code, dict(zip(ed_a["cle"], ed_a["valeur"])))
            st.session_state["cf_msg"] = "Attributs enregistrés."
            st.rerun()

    motif = str(fiche.get("motif") or "")
    if motif:
        vus = pd.read_sql_query("SELECT date, folio, fichier, amont_nb, amont_debit, ecart_debit FROM fr_lignes "
                                "WHERE present = 1 ORDER BY substr(date,7,4)||substr(date,4,2)||substr(date,1,2) DESC", con)
        vus = vus[[fx.reconnait(motif, x) for x in vus["fichier"]]].head(15)
        if not vus.empty:
            st.markdown("**Derniers fichiers transmis reconnus**")
            st.dataframe(vus.rename(columns={"date": "Date", "folio": "Folio", "fichier": "Fichier", "amont_nb": "Pièces",
                                             "amont_debit": "Montant", "ecart_debit": "Écart"}),
                         use_container_width=True, hide_index=True, height=min(360, 38 * len(vus) + 40),
                         column_config={"Montant": st.column_config.NumberColumn("Montant", format="euro"),
                                        "Écart": st.column_config.NumberColumn("Écart", format="euro")})


# ------------------------------------------------------------------ écran

def render(kpi):
    with contextlib.closing(connect()) as con:
        msg = st.session_state.pop("cf_msg", None)
        if msg:
            st.toast(msg, icon="✅")

        df = cf.carte(con)
        # ---------------------------------------------------------- alimentation
        a1, a2, a3, a4 = st.columns([1.4, 1.4, 1, 1.4])
        nb_cat = len(fx.catalogue_fin01())
        manquants = nb_cat - int(df["commentaire"].eq("schéma Flux-FIN01 - ORACLE").sum()) if not df.empty else nb_cat
        if a1.button(f"🗺 Charger les flux du schéma FIN01 ({manquants} à ajouter)", disabled=manquants <= 0,
                     use_container_width=True, key="cf_charger",
                     help="Les 66 flux du schéma « Flux pour FIN01 - ORACLE », avec leur domaine et leur nature. "
                          "Les fiches déjà présentes ne sont pas touchées."):
            n = fx.charger_catalogue(con)
            st.session_state["cf_msg"] = f"{n} flux ajouté(s) depuis le schéma."
            st.rerun()
        propositions = fx.decouvrir(con)
        if a2.button(f"🔍 Déclarer les fichiers inconnus ({len(propositions)})", disabled=not propositions,
                     use_container_width=True, key="cf_decouvrir",
                     help="Une fiche par famille de fichiers transmis qu'aucun motif ne reconnaît. Chargez d'abord "
                          "les flux du schéma : leurs motifs reconnaissent déjà les fichiers SRC de factures et "
                          "d'écritures, il ne reste alors que les fichiers intermédiaires ou inattendus."):
            for p in propositions:
                p.pop("nb_fichiers", None)
                p.pop("exemple", None)
                fx.enregistrer(con, p)
            st.session_state["cf_msg"] = f"{len(propositions)} flux déclaré(s) depuis les fichiers connus."
            st.rerun()
        a3.download_button("⬇ Exporter (CSV)", fx.exporter_csv(con), file_name="flux_referentiel.csv",
                           mime="text/csv", use_container_width=True, key="cf_dl", disabled=df.empty)
        depot = a4.file_uploader("Importer un export CSV", type=["csv"], key="cf_up", label_visibility="collapsed")
        if depot is not None and a4.button("📥 Importer", key="cf_imp", use_container_width=True):
            st.session_state["cf_msg"] = f"{fx.importer_csv(con, depot.getvalue())} flux importé(s)."
            st.rerun()

        if df.empty:
            st.info("Aucun flux déclaré. Chargez les flux du schéma FIN01, ou déclarez-les depuis les fichiers "
                    "transmis connus, puis complétez chaque fiche (motif, interlocuteurs, attributs).")
            return

        # ---------------------------------------------------------- tuiles
        r = cf.resume(df)
        t = st.columns(6)
        kpi(t[0], r["flux"], f"flux · {r['applications']} applications", "neutral")
        kpi(t[1], r["entrants"], "vers Oracle", "neutral")
        kpi(t[2], r["sortants"], "depuis Oracle", "neutral")
        kpi(t[3], r["ok"], "conformes", "ok" if r["ok"] else "neutral")
        kpi(t[4], r["ecart"], "en écart", "err" if r["ecart"] else "ok")
        kpi(t[5], r["inconnu"], "sans donnée", "warn" if r["inconnu"] else "neutral")
        if r["suivis"]:
            sante = round(100 * r["ok"] / r["suivis"])
            st.progress(sante / 100, text=f"Santé des flux suivis : {sante} % conformes ({r['ok']} sur {r['suivis']})")

        # ---------------------------------------------------------- filtres et diagramme
        f1, f2, f3, f4 = st.columns(4)
        sens = f1.multiselect("Sens", list(fx.SENS), key="cf_f_sens", format_func=lambda s: "→ Oracle" if s == "entrant" else "Oracle →")
        domaines = f2.multiselect("Domaine", sorted(df["domaine"].dropna().unique()), key="cf_f_dom")
        natures = f3.multiselect("Nature", sorted(df["nature"].dropna().unique()), key="cf_f_nat")
        etats = f4.multiselect("État", list(cf.ETATS), key="cf_f_etat", format_func=lambda e: f"{METEO[e]} {cf.LIBELLES_ETAT[e]}")
        vue = df
        if sens:
            vue = vue[vue["sens"].isin(sens)]
        if domaines:
            vue = vue[vue["domaine"].isin(domaines)]
        if natures:
            vue = vue[vue["nature"].isin(natures)]
        if etats:
            vue = vue[vue["etat"].isin(etats)]
        c1, c2 = st.columns([3, 1])
        c1.caption("Un nœud par application, Oracle Finance au centre, une flèche par flux : verte conforme, "
                   "orange en écart, grise sans donnée ; tirets longs pour le batch, points pour le fil de l'eau. "
                   "Les nœuds se déplacent à la souris, la molette zoome, le survol donne le détail. "
                   "Couleur des applications = domaine du schéma.")
        objets = c2.checkbox("Objets sur les flèches", False, key="cf_objets",
                             help="Affiche le libellé de chaque flux le long de sa flèche.")
        if vue.empty:
            st.info("Aucun flux pour ces filtres.")
        else:
            components.html(_graphe_html(vue, objets), height=HAUTEUR_GRAPHE, scrolling=False)
            legende = " · ".join(f'<span style="display:inline-block;width:11px;height:11px;border-radius:50%;'
                                 f'background:{cf.COULEURS_DOMAINE[d]};margin-right:4px;vertical-align:middle"></span>{d}'
                                 for d in sorted(vue["domaine"].dropna().unique()) if d in cf.COULEURS_DOMAINE)
            st.markdown(f'<div style="font-size:.8rem;color:#4B5563">{legende}</div>', unsafe_allow_html=True)

        # ---------------------------------------------------------- météo des flux
        st.markdown(f"#### Météo des flux ({len(vue)})")
        table = vue.assign(meteo=vue["etat"].map(METEO))[list(COLS_TABLE)].rename(columns=COLS_TABLE)
        table["Sens"] = table["Sens"].map({"entrant": "→ Oracle", "sortant": "Oracle →"})
        st.dataframe(table, use_container_width=True, hide_index=True, height=min(520, 38 * len(table) + 40),
                     column_config={"": st.column_config.TextColumn("", width="small"),
                                    "Contacts": st.column_config.NumberColumn("Contacts", format="%d")})

        # ---------------------------------------------------------- fiche
        st.markdown("#### Fiche d'un flux")
        choix = {f"{METEO[r_['etat']]} {r_['libelle']}": r_["code"] for _, r_ in vue.iterrows()}
        cle = st.selectbox("Flux", list(choix), key="cf_choix")
        if cle:
            _fiche(con, choix[cle])
