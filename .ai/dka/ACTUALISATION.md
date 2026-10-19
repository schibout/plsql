# Vérifier et actualiser le dossier DKA

Exécuter les commandes depuis la racine du dépôt. Elles concernent les générateurs documentaires Python, pas les traitements Oracle du corpus.

## Avant une régénération

Lancer `python analyse_dka_complete/outils/verifier_livraison.py` pour comparer l’état courant à l’inventaire existant. Il ne régénère pas les empreintes ; il réécrit seulement le rapport de vérification et renvoie un code non nul si les contrôles échouent.

Si des fichiers ont changé, relever d’abord les écarts, puis obtenir les conclusions nécessaires dans les sources courantes. Un rapport ancien « validation_reussie=true » ne garantit pas l’état courant. Le champ de date de ce vérificateur est codé en dur au 17 octobre 2026 : utiliser la sortie de l’exécution et les empreintes, pas cette date seule.

## Régénération lorsque la tâche le demande

1. `python analyse_dka_complete/outils/construire_catalogue.py`
2. `python analyse_dka_complete/outils/extraire_parametres.py`
3. `python analyse_dka_complete/extract_workflows.py`
4. `python analyse_dka_complete/outils/construire_graphe.py`
5. `python analyse_dka_complete/outils/verifier_livraison.py`

Vérifier le code retour de chaque commande avant de continuer. Les étapes 2 et 3 sont indépendantes ; le graphe doit suivre le catalogue et la vérification doit suivre toutes les générations. Le graphe demande le paquet Python `graphifyy` ; les autres scripts utilisent la bibliothèque standard. Ne pas installer de dépendances sans rapport avec la tâche, ni supposer qu’un outil Graphify est disponible partout.

La génération réécrit les inventaires, fiches, annexes et graphes. Elle ne révise pas automatiquement les interprétations des notes métier `00`, `02`, `03`, `04`, `04a`, `06`, `07`, ni le présent contexte. Après changement : réviser les notes concernées, confirmer les chiffres dans `statistiques.json`, corriger les renvois et garder la distinction extraction automatique / revue sémantique.

## Entretenir les points d’entrée IA

Le skill de référence est `.agents/skills/dka-ebs/SKILL.md`. Les copies Claude et Gemini sont conservées à l’identique ; les trois lisent les mêmes références `.ai/dka/` et l’analyse réelle. Après édition du skill, recopier ce seul fichier vers `.claude/skills/dka-ebs/SKILL.md` et `.gemini/skills/dka-ebs/SKILL.md`, puis valider les trois frontmatters avec l’outil de validation de skills disponible.

Ne pas exporter les milliers de sources dans les skills. Ils restent des points d’entrée propres à ce dépôt ; les déplacer seuls dans un autre répertoire rendrait les références indisponibles.
