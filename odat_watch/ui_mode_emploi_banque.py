"""Sous-onglet Banque › Mode d'emploi : relevés bancaires, virements, prélèvements.

Le texte vient de docs/MODE_EMPLOI_BANQUE.md (une seule source à tenir à jour, une section « ## » par onglet) ;
les dossiers sont lus dans config.ini au moment de l'affichage, et les statuts des prélèvements viennent de
prelevements.py : le mode d'emploi ne peut diverger ni de la configuration ni de l'écran.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd
import streamlit as st

import prelevements as pv
import releves as rb
import virements as vr
from db import BASE_DIR

GUIDE = BASE_DIR / "docs" / "MODE_EMPLOI_BANQUE.md"
ONGLETS = [("📄 Relevés bancaires", "Relevés bancaires", "releves"), ("💸 Virements", "Virements", "virements"),
           ("💳 Prélèvements", "Prélèvements", "prelevements")]


def sections(texte: str) -> tuple[str, dict[str, str]]:
    """(introduction, {titre de section « ## » : corps})."""
    intro, *blocs = texte.split("\n## ")
    out = {}
    for b in blocs:
        titre, _, corps = b.partition("\n")
        out[titre.strip()] = corps.strip()
    return intro.split("\n", 1)[-1].strip(), out


def _etat(p: Path) -> str:
    if p.is_dir():
        return f"✅ {sum(1 for _ in p.iterdir())} élément(s)"
    if p.is_file():
        return "✅ fichier présent"
    return "❌ absent"


def dossiers(onglet: str) -> pd.DataFrame:
    """Dossiers de l'onglet tels que configurés : clé config.ini, chemin résolu, état sur disque."""
    if onglet == "releves":
        cfg = rb.config_releves()
        lignes = [("racine", cfg["racine"]), ("dossier_pfe", cfg["dossier_pfe"]), ("dossier_ebs", cfg["dossier_ebs"])]
        lignes += [("dossiers_logs", d) for d in cfg["dossiers_logs"]]
        lignes += [("dossier_rapports", cfg["dossier_rapports"]), ("fichier_liste", cfg["fichier_liste"])]
    elif onglet == "virements":
        cfg = vr.config_virements()
        lignes = [("racine", cfg["racine"]), ("depot", cfg["depot"]), ("dossier_oracle", cfg["oracle"]),
                  ("dossier_edf", cfg["edf"]), ("dossier_rejets", cfg["rejets"]), ("dossier_rapports", cfg["rapports"]),
                  ("outil", cfg["outil"])]
    else:
        cfg = pv.config_prelevements()
        lignes = [("racine", cfg["racine"]), ("dossier_oracle", cfg["oracle"]), ("dossier_edf", cfg["edf"]),
                  ("dossier_rejets", cfg["rejets"]), ("dossier_rapports", cfg["rapports"]), ("outil", cfg["outil"])]
    return pd.DataFrame([{"clé config.ini": k, "chemin": str(p), "état": _etat(Path(p))} for k, p in lignes])


def _statuts_prelevements() -> pd.DataFrame:
    return pd.DataFrame([{"statut": pv.LIBELLES_STATUT[s], "signification": pv.EXPLICATIONS[s],
                          "à traiter": "🔴 anomalie" if s in pv.STATUTS_ANOMALIE
                          else "🟠 signalé" if s in pv.STATUTS_SIGNALES else ""}
                         for s in pv.ORDRE_STATUTS])


def render() -> None:
    if not GUIDE.is_file():
        st.error(f"Guide introuvable : `{GUIDE}`")
        return
    intro, corps = sections(GUIDE.read_text(encoding="utf-8"))
    st.markdown("#### 📖 Mode d'emploi · Relevés bancaires, Virements, Prélèvements")
    st.markdown(intro)
    for tab, (_, titre, onglet) in zip(st.tabs([o[0] for o in ONGLETS]), ONGLETS):
        with tab:
            st.markdown(f"##### Où sont les fichiers — section `[{onglet}]` de config.ini")
            st.dataframe(dossiers(onglet), hide_index=True, use_container_width=True)
            st.caption("Chemins relatifs à `racine` (ou absolus), eux-mêmes relatifs au dossier de l'application. "
                       "Modifier config.ini puis recharger la page.")
            st.markdown(corps.get(titre, "_Section absente du guide._"))
            if onglet == "prelevements":
                st.markdown("##### Statuts des clés")
                st.dataframe(_statuts_prelevements(), hide_index=True, use_container_width=True)
