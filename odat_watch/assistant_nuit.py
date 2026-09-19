"""Questions guidées pour le plan de nuit, sans IA externe."""
from __future__ import annotations

import re
from datetime import datetime, timedelta

import pandas as pd


GUIDES = [
    "Qu'est-ce qui est prévu ?",
    "Quels sont les plus longs ?",
    "Que dois-je surveiller ?",
    "Pourquoi ces jobs sont attendus ?",
]


def repondre(question: str, plan: pd.DataFrame, contexte: str, debut: datetime, fin: datetime) -> tuple[str, pd.DataFrame]:
    """Interprète un petit ensemble d'intentions explicites, toujours sur le plan fourni."""
    question = (question or "").strip()
    q = question.lower()
    if plan.empty:
        return (f"Aucun traitement prévisionnel n'est disponible entre {debut:%d/%m %H:%M} et {fin:%d/%m %H:%M}. "
                f"Contexte : {contexte}.", plan)
    shown = plan.copy()
    if any(word in q for word in ("long", "durée", "duree")):
        threshold = re.search(r"(\d+)\s*(?:min|minute)", q)
        if threshold:
            shown = shown[shown["duree_min"] >= int(threshold.group(1))]
        else:
            shown = shown.nlargest(min(10, len(shown)), "duree_min")
        return (f"{len(shown)} traitement(s) les plus longs ou dépassant le seuil demandé. "
                "Les durées sont des médianes historiques, pas des durées garanties.", shown)
    if any(word in q for word in ("surveill", "risque", "erreur", "retard")):
        shown = shown[(shown["statut"] == "Ended Not OK") | (shown["fiabilite"].fillna(0) < 90) | (shown["confiance"] == "Faible")]
        return (f"{len(shown)} traitement(s) à surveiller : erreur récente, historique de succès inférieur à 90 % "
                "ou historique insuffisant. Une absence n'est jamais interprétée comme une erreur.", shown)
    if "pourquoi" in q:
        return (f"Ces traitements sont attendus parce que leur rythme a été observé sur des nuits comparables. "
                f"Contexte actif : {contexte}. La colonne « nb_obs » indique le nombre d'observations utilisées.", shown)
    return (f"{len(shown)} traitement(s) attendus entre {debut:%d/%m %H:%M} et {fin:%d/%m %H:%M}. "
            f"Contexte : {contexte}. Sélectionnez une question guidée pour filtrer cette liste.", shown)
