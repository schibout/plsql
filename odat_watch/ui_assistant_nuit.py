"""Panneau de questions guidées connecté au plan déjà calculé."""
from __future__ import annotations

import pandas as pd
import streamlit as st

import assistant_nuit


def render(plan: pd.DataFrame, contexte: str, debut, fin) -> None:
    st.markdown("#### Assistant de nuit")
    st.caption("Questions guidées : les réponses s'appuient sur le plan affiché, sans IA externe.")
    keys = ["Prévu", "Les plus longs", "À surveiller", "Pourquoi ?"]
    questions = [
        "Qu'est-ce qui est prévu ?", "Quels sont les plus longs ?",
        "Que dois-je surveiller ?", "Pourquoi ces jobs sont attendus ?",
    ]
    cols = st.columns(4)
    for col, label, question in zip(cols, keys, questions):
        if col.button(label, key=f"assistant_{label}", use_container_width=True):
            st.session_state["assistant_question"] = question
    question = st.text_input("Votre question", value=st.session_state.get("assistant_question", ""),
                             placeholder="Ex. Quels traitements sont les plus longs ?", key="assistant_input")
    if question:
        response, result = assistant_nuit.repondre(question, plan, contexte, debut, fin)
        st.info(response)
        if not result.empty:
            st.dataframe(result[["heure_prevue", "job", "description", "duree_min", "fiabilite", "nb_obs", "confiance"]],
                         use_container_width=True, hide_index=True, height=min(350, 40 * len(result) + 40),
                         column_config={"duree_min": st.column_config.NumberColumn("durée médiane (min)", format="%.1f"),
                                        "fiabilite": st.column_config.NumberColumn("taux OK (%)", format="%.0f")})
