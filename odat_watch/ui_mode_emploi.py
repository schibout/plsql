"""Sous-onglet Control-M › Mode d'emploi : légende en vraies couleurs, grille d'exemple commentée, guide complet.

Le texte vient de docs/PLAN_DE_PRODUCTION.md (une seule source à tenir à jour) ; les couleurs viennent de
ui_plan_prod (celles de la grille), donc la légende ne peut pas diverger de l'écran.
"""
from __future__ import annotations

import pandas as pd
import streamlit as st

import plan_prod as pp
import ui_plan_prod
from db import BASE_DIR

GUIDE = BASE_DIR / "docs" / "PLAN_DE_PRODUCTION.md"

LEGENDE = [   # (cellule, signification, exemple)
    ("✔ 7", "Tous les jobs de la chaîne sont terminés OK. Le chiffre est le nombre de jobs vus ce jour-là.",
     "TIERS EXPRESS à J-7 : les 7 jobs OK."),
    ("✖ 7", "Au moins un job en erreur (Ended Not OK) : c'est le pire état qui s'affiche.",
     "TIERS EXPRESS à J-5 (24/08/2026) : règlements automatiques en erreur, pas de virement ce soir-là."),
    ("▶ 3", "Au moins un job en cours à la dernière photo.", "Chaîne de nuit encore en cours à 8h07."),
    ("⏸ 3", "Au moins un job en attente : odate en cours, ce n'est pas encore fini.", "Chaîne du soir vue à 13h46."),
    ("⊘ 7", "Ordonnancée mais jamais partie pour cet odate (Non lancé) : ne compte pas comme tournée.",
     "Extraction DTR à J-2 : les 7 jobs restés en attente jusqu'à 8h07 le lendemain."),
    ("✔ 7+", "« + » violet : la chaîne a tourné un jour hors de sa planification.",
     "Chaîne planifiée « J » qui tourne aussi à J+1."),
    (pp.NON_OBSERVE, "Prévu, des photos existent ce jour-là, mais la chaîne n'y est pas. À vérifier.",
     "TIERS EXPRESS à J : jamais le jour de la clôture (règle « sauf L1 »)."),
    (pp.PREVU, "Prévu, à venir (jour après la dernière photo).", "J+16 du mois en cours."),
    (pp.SANS_PHOTO, "Prévu, mais aucune photo ce jour-là : impossible de savoir.", "Jour où l'import ODAT a manqué."),
    ("", "Pas prévu et rien observé.", "Chaîne de clôture un jour hors clôture."),
]

ORIGINES = [
    ("Référentiel", "Chaîne de la bible, toujours vue dans les photos."),
    ("Ajoutée", "Ajoutée au référentiel depuis les ODAT (bouton ou synchronisation)."),
    ("Nouvelle", "Vue dans les photos, pas encore au référentiel : à qualifier."),
    ("Jamais vue", "Au référentiel, absente de toutes les photos."),
    ("Plus vue depuis JJ/MM/AAAA", f"Au référentiel, absente depuis plus de {pp.OUBLI_JOURS} jours."),
    ("Supprimée", "Statut « supprimée » : masquée par défaut."),
]

TUILES = [
    ("Chaînes au référentiel", "gris", "Chaînes du référentiel non supprimées."),
    ("Chaînes observées sur le mois", "bleu", "Chaînes réellement parties au moins une fois dans la fenêtre (⊘ exclu)."),
    ("Nouvelles, à qualifier", "jaune", "Vues dans les photos, absentes du référentiel."),
    ("Absentes des photos", "rouge", "« Jamais vue » + « Plus vue depuis… »."),
    ("Écarts de planification", "jaune", "Chaînes dont les jours réels diffèrent de la planification."),
]


def _exemple() -> tuple[pd.DataFrame, list[str]]:
    """Grille fictive inspirée d'août 2026 : une ligne par cas à connaître."""
    jours = ["J-5 24/08", "J-2 27/08", "J-1 28/08", "sam 29/08", "J 31/08", "J+1 01/09", "J+2 02/09", "J+16 22/09"]
    lignes = [
        ("FINEXT_J17GEN_06_M", "lun mar mer jeu ven", "Référentiel", "−J",
         ["✖ 7", "✖ 7", "✔ 7", "", pp.NON_OBSERVE, "✔ 7", "✔ 7", pp.PREVU]),
        ("FINDTR_J11GEN_06_Q", "lun mar mer jeu ven", "Référentiel", "−J-2 −J −J+1 −J+2",
         ["✔ 7", "⊘ 7", "✔ 7", "", "⊘ 7", pp.NON_OBSERVE, pp.NON_OBSERVE, pp.PREVU]),
        ("FINFIN_C13TRT_04_M", "J", "Référentiel", "", ["", "", "", "", "✔ 2", "", "", ""]),
        ("FINFIN_C1ITRT_04_M", "J-4", "Référentiel", "+J-5 −J-4", ["✔ 5+", "", "", "", "", "", "", ""]),
        ("FINFIN_J11TEC_04_FJA01_Q", "", "Nouvelle", "", ["✔ 1", "✔ 1", "✔ 1", "✔ 1", "✔ 1", "✔ 1", "✔ 1", ""]),
        ("FINFIN_C12TRT_04_M", "J-2, J-1, J", "Jamais vue", "−J-2 −J-1 −J",
         ["", pp.NON_OBSERVE, pp.NON_OBSERVE, "", pp.NON_OBSERVE, "", "", ""]),
    ]
    t = pd.DataFrame([dict(chaîne=c, planification=p, origine=o, écarts=e, **dict(zip(jours, cellules)))
                      for c, p, o, e, cellules in lignes])
    return t, jours


def render() -> None:
    st.markdown("### 📖 Mode d'emploi du Plan de production")
    st.caption("J = dernier jour ouvré du mois ; on compte en jours ouvrés de J-7 à J+16 (J-n = L(n+1), J+n = Dn). "
               "Chaque cellule résume une chaîne pour un odate, à partir des photos ODAT fusionnées "
               "(dernier état connu de chaque exécution).")

    st.markdown("#### Les cellules de la grille")
    leg = pd.DataFrame(LEGENDE, columns=["cellule", "signification", "exemple"])
    st.dataframe(ui_plan_prod._grille_stylee(leg, ["cellule"]), hide_index=True, use_container_width=True,
                 column_config={"signification": st.column_config.TextColumn(width="large"),
                                "exemple": st.column_config.TextColumn(width="large")})
    st.caption("Quand les jobs d'une chaîne n'ont pas tous le même état, le pire l'emporte : ✖ > ▶ > ⏸ > ✔ > ⊘.")

    st.markdown("#### Une grille d'exemple, ligne par ligne")
    t, jours = _exemple()
    st.dataframe(ui_plan_prod._grille_stylee(t, jours), hide_index=True, use_container_width=True)
    st.markdown("""
- **FINEXT_J17GEN_06_M (TIERS EXPRESS)** : ✖ à J-5 et J-2 = incidents (pas de virement à J-5) ; ○ à J = règle
  « jamais le jour de la clôture », d'où l'écart **−J** qui revient chaque mois.
- **FINDTR_J11GEN_06_Q (Datapump DTR)** : ⊘ = ordonnancée mais jamais partie (blocage à investiguer) ;
  ○ à J+1 et J+2 = suspension voulue pendant la clôture, tous les mois.
- **FINFIN_C13TRT_04_M (Clôture AP)** : planifiée « J », a tourné à J : rien à dire, pas d'écart.
- **FINFIN_C1ITRT_04_M (Clôture FA)** : planifiée J-4, a tourné à J-5 → **✔ 5+** en violet et écart **+J-5 −J-4** :
  le jour a glissé, adopter la planification observée si c'est la nouvelle règle.
- **FINFIN_J11TEC_04_FJA01_Q** : origine **Nouvelle** → à ajouter au référentiel (bouton ou synchronisation).
- **FINFIN_C12TRT_04_M** : **Jamais vue** → la synchronisation la passera « supprimée ».
- Colonne **sam 29/08** : pas de label J (week-end), seules les chaînes du week-end y apparaissent.
- Colonne **J+16 22/09** : après la dernière photo, **·** = prévu, à venir.
""")

    st.markdown("#### Les écarts")
    st.markdown("""
| Notation | Signification |
|---|---|
| **+J+3** | a tourné à J+3 alors que ce n'était pas prévu |
| **−J-1** | prévu à J-1, n'a pas tourné (compté seulement s'il y a des photos ce jour-là) |
| **+dim 23/08** | même chose pour un jour sans label J (week-end, férié) |

Un écart **qui revient chaque mois** est une règle d'ordonnancement (à noter dans le commentaire du référentiel) ;
un écart **isolé** est un incident à expliquer.
""")

    g, d = st.columns(2)
    with g:
        st.markdown("#### Origine d'une chaîne")
        st.dataframe(pd.DataFrame(ORIGINES, columns=["origine", "signification"]), hide_index=True,
                     use_container_width=True)
    with d:
        st.markdown("#### Les 5 tuiles")
        st.dataframe(pd.DataFrame(TUILES, columns=["tuile", "liseré", "ce qu'elle compte"]), hide_index=True,
                     use_container_width=True)

    st.markdown("#### Écrire une planification")
    st.markdown("""
| Forme | Exemple | Pour |
|---|---|---|
| jours de semaine | `lun mar mer jeu ven` | quotidiennes, hebdomadaires |
| labels J | `J-2, J, J+4` | clôture, périodiques, campagnes |
| labels Control-M | `L3, L1, D4` | accepté en saisie, converti en J (L3 = J-2, D4 = J+4) |

Une planification **saisie à la main** est protégée : la synchronisation n'y touche plus. La vider rend la main aux ODAT.
""")

    st.markdown("#### 🔄 Synchroniser avec ODAT")
    st.markdown(f"""
| Changement | Quand |
|---|---|
| **ajoutée** | vue dans les photos des {pp.OUBLI_JOURS} derniers jours, absente du référentiel |
| **supprimée** | absente des photos depuis plus de {pp.OUBLI_JOURS} jours, ou jamais vue |
| **réactivée** | supprimée, mais revue dans les {pp.OUBLI_JOURS} derniers jours |
| **planification** | l'observée diffère de la référence (sauf saisie manuelle, « variable » ou chaîne plus vue) |

Importer d'abord les derniers fichiers ODAT (barre latérale), puis synchroniser. Relancée tout de suite,
la synchronisation ne change plus rien.
""")

    st.divider()
    if GUIDE.exists():
        with st.expander("📘 Guide complet (docs/PLAN_DE_PRODUCTION.md)"):
            st.markdown(GUIDE.read_text(encoding="utf-8"))
