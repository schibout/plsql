"""Sous-onglet Ctrl Flux › Mode d'emploi : Ctrl Flux, Historique, GDR, Carte des flux.

Le texte vient de docs/MODE_EMPLOI_CTRL_FLUX.md (une section « ## » par sous-onglet) ; les dossiers, les
couleurs des lignes et les états des flux sont lus dans le code au moment de l'affichage : le mode d'emploi ne
peut diverger ni de la configuration ni de l'écran.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd
import streamlit as st

import carte_flux as cf
import ctrl_flux as cx
import flux_ref as fx
import gdr as gd
from db import BASE_DIR
from rapport_matin import DOSSIER_RAPPORTS
from ui_ctrl_flux import COULEUR_GDR, DOSSIER_SAUVEGARDE

GUIDE = BASE_DIR / "docs" / "MODE_EMPLOI_CTRL_FLUX.md"
ONGLETS = [("🔀 Ctrl Flux", "Ctrl Flux"), ("📚 Historique", "Historique"), ("🧾 GDR", "GDR"),
           ("🗺 Carte des flux", "Carte des flux")]
# ordre de priorité des couleurs de ligne, tel qu'appliqué par ui_ctrl_flux._styles_lignes puis cx.couleur_ligne
REGLES_COULEUR = [
    ("gris, texte grisé", "#EAF7EE", "ligne rapprochée"),
    ("gris italique", "#FFFFFF", "ligne disparue du dernier export (visible si la case est cochée)"),
    ("violet", COULEUR_GDR, "écart expliqué par des pièces rejetées dans la GDR"),
    ("orange", cx.COULEURS_LIGNE["orange"], "données en interface Oracle absentes des tables définitives, ou montant différent"),
    ("bleu", cx.COULEURS_LIGNE["bleu"], "vérification Oracle OK"),
    ("jaune", cx.COULEURS_LIGNE["jaune"], "commentaire renseigné"),
    ("vert", cx.COULEURS_LIGNE["vert"], "écart de montant nul (débit et crédit)"),
    ("rose", cx.COULEURS_LIGNE["rose"], "nombre de pièces égal mais montant différent"),
]


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
    return "✅ fichier présent" if p.is_file() else "❌ absent"


def dossiers(onglet: str) -> pd.DataFrame:
    """Dossiers et fichiers utilisés par le sous-onglet, avec leur état sur disque."""
    if onglet in ("Ctrl Flux", "Historique"):
        lignes = [("Exports Ctrl Flux", DOSSIER_SAUVEGARDE), ("Exports archivés", DOSSIER_SAUVEGARDE / "sauvegarde")]
        if onglet == "Ctrl Flux":
            lignes += [("Exports GDR ([gdr] racine)", gd.config_gdr()["racine"]), ("Rapports HTML", DOSSIER_RAPPORTS),
                       ("Accès Oracle (config.ini)", BASE_DIR / "config.ini")]
    elif onglet == "GDR":
        lignes = [("Exports GDR ([gdr] racine)", gd.config_gdr()["racine"])]
    else:
        lignes = [("Catalogue du schéma FIN01", fx.CATALOGUE_FIN01)]
    return pd.DataFrame([{"rôle": r, "chemin": str(p), "état": _etat(Path(p))} for r, p in lignes])


def _pastille(couleur: str) -> str:
    return (f'<span style="display:inline-block;width:14px;height:14px;border-radius:3px;background:{couleur};'
            f'border:1px solid #CBD5E1;vertical-align:middle"></span>')


def _tableau_html(lignes: list[tuple[str, str, str]], entetes: tuple[str, str]) -> str:
    corps = "".join(f"<tr><td>{_pastille(c)} {n}</td><td>{s}</td></tr>" for n, c, s in lignes)
    return (f'<table style="border-collapse:collapse;font-size:.9rem"><thead><tr><th style="text-align:left;'
            f'padding-right:1.5rem">{entetes[0]}</th><th style="text-align:left">{entetes[1]}</th></tr></thead>'
            f"<tbody>{corps}</tbody></table>")


def render() -> None:
    if not GUIDE.is_file():
        st.error(f"Guide introuvable : `{GUIDE}`")
        return
    intro, corps = sections(GUIDE.read_text(encoding="utf-8"))
    st.markdown("#### 📖 Mode d'emploi · Ctrl Flux, Historique, GDR, Carte des flux")
    st.markdown(intro)
    for tab, (_, titre) in zip(st.tabs([o[0] for o in ONGLETS]), ONGLETS):
        with tab:
            st.markdown("##### Où sont les fichiers")
            st.dataframe(dossiers(titre), hide_index=True, use_container_width=True)
            st.markdown(corps.get(titre, "_Section absente du guide._"))
            if titre == "Ctrl Flux":
                st.markdown("##### Couleur des lignes, de la règle la plus forte à la plus faible")
                st.markdown(_tableau_html(REGLES_COULEUR, ("Couleur", "Signification")), unsafe_allow_html=True)
            elif titre == "Carte des flux":
                st.markdown("##### État d'un flux (couleur des flèches)")
                st.markdown(_tableau_html([(cf.LIBELLES_ETAT[e], cf.COULEURS_ETAT[e], e) for e in cf.ETATS],
                                          ("État", "Code")), unsafe_allow_html=True)
                st.markdown("##### Domaines (couleur des nœuds)")
                st.markdown(_tableau_html([(d, c, "") for d, c in cf.COULEURS_DOMAINE.items()],
                                          ("Domaine", "")), unsafe_allow_html=True)
