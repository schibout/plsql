# Dossier complet des intégrations, workflows et traitements spécifiques DKA

Analyse du dépôt local `dka/`, constituée le **17 octobre 2026**. Ce dossier élargit l’[analyse de la facturation](../analyse_integration_facturation/README.md) aux composants de l’application DKA.

## Parcours de lecture

Pour démarrer une session Claude, Codex ou Gemini avec ce contexte : voir le [guide des skills IA](../.ai/dka/README.md) et le [contexte commun](../.ai/dka/CONTEXTE.md).

| Document | Contenu |
|---|---|
| [Synthèse et architecture](00_synthese_et_architecture.md) | Vue d’ensemble, responsabilités, conclusions et limites |
| [Catalogue exhaustif](01_catalogue_complet.md) | Chaque fichier du dossier DKA, classement et accès aux fiches |
| [Intégrations](02_integrations.md) | Flux par domaine, interfaces, appels, contrôles et reprises |
| [Workflows](03_workflows.md) | Processus, déclencheurs, notifications, callbacks et gestion des erreurs |
| [Transitions des workflows](03a_workflows_transitions.md) | Annexe détaillée des processus et transitions des 12 exports |
| [Traitements spécifiques](04_traitements_specifiques.md) | Clôtures, paiements, prélèvements, recouvrement, hooks, outils et reprises |
| [Composants complémentaires](04a_traitements_complementaires.md) | 22 fiches fonctionnelles : exports, TVA, XLA, comptes, images et affectations bancaires |
| [Programmes et orchestration](05_programmes_et_orchestration.md) | Définitions FND des programmes, exécutables et points d’entrée |
| [Paramètres](05a_parametres.md) | Paramètres spécifiques et segments SRS présents dans les exports |
| [Exploitation et validation](06_exploitation_et_validation.md) | Matrice de recette, preuves d’intégration, reprise et questions ouvertes |
| [Couverture et écarts](07_couverture_et_ecarts.md) | Profondeur d’analyse, binaires, dépendances et versions à confirmer |

## Données exploitables

- [Inventaire CSV](inventaire_complet.csv) : filtrage par fichier, format, famille et taille.
- [Inventaire JSON](inventaire_complet.json) : empreintes, lignes, objets SQL, références d’appels et marqueurs transactionnels.
- [Programmes concurrents](programmes_concurrents.json) et [définitions FND](definitions_fnd.json) : valeurs présentes dans les exports locaux, dont paramètres et jeux de traitement détectés.
- [Paramètres détaillés](parametres.json) : clés, contexte, valeurs et lignes sources des paramètres et segments détectés.
- [Dépendances](dependances.json) : références de forme appel, fichier et ligne, disponibilité du corps cible.
- [Structure Workflow détaillée](workflow_structure.json) et [blocs exportés](workflows.json).
- [Graphe de navigation](graphify-out/graph.html), [rapport du graphe](graphify-out/GRAPH_REPORT.md) et [statistiques](statistiques.json).

Les fiches techniques sont accessibles depuis le catalogue. Elles sont générées par lecture statique ; les analyses par domaine fournissent l’interprétation fonctionnelle et ses réserves. Une occurrence détectée ne démontre pas que la branche est exécutée.

## Conditions de lecture

« Complet » désigne l’inventaire de tous les fichiers et le catalogue des composants disponibles. La revue sémantique est ciblée et son niveau est indiqué. Les binaires et archives sont inventoriés par métadonnées ; leur contenu n’est pas certifié. Aucun composant du corpus n’a été exécuté, aucune base Oracle consultée et aucune source modifiée. La présence d’un fichier ne prouve ni son déploiement ni son utilisation actuelle.

Le générateur local [construire_catalogue.py](outils/construire_catalogue.py) permet de renouveler l’extraction. Il lit les sources et écrit exclusivement dans ce dossier ; il ne lance aucun SQL ni shell du corpus. Les notes d’analyse métier sont des livrables distincts, à réviser après un changement fonctionnel.
