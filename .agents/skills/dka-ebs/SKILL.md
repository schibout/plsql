---
name: dka-ebs
description: "Use when working in this DKA Oracle E-Business Suite repository on integrations, AP/AR/GL/PO/PA/FA/RH/CE packages, CSP/BAP workflows, specific treatments, diagnostics, dependencies or the generated analysis dossier. Not for unrelated projects or generic Oracle questions."
---

# DKA EBS — comprendre le contexte et retrouver les preuves

Ce skill est **local au dépôt PL/SQL DKA**. Retrouver sa racine à partir de ce fichier : trois niveaux au-dessus se trouvent `dka/`, `analyse_dka_complete/` et `.ai/dka/`. Ne pas dépendre du chemin Windows d’une machine particulière ni du répertoire courant d’une session démarrée dans un sous-dossier.

## Entrée rapide

Lire [le contexte commun](../../../.ai/dka/CONTEXTE.md), sauf s’il a déjà été chargé depuis le point d’entrée de l’outil, puis [le routage](../../../.ai/dka/ROUTAGE.md). Charger une note de domaine, retrouver le composant, puis vérifier les extraits sources. Ne pas charger toutes les fiches, tous les JSON ou toutes les analyses par défaut.

Les noms peuvent tromper : `DKA_IAPFAC_IVALUA_PKG` exporte vers Ivalua ; REP/FUS peut désigner reprise ou fusion de sociétés ; une fin de workflow AP ne prouve pas la création de l’enfant CSP. Les notes indiquent les branches et sources à confirmer pour la version visée.

## Selon la demande

- **Expliquer ou diagnostiquer** : partir de la note du domaine ; relier entrée, routine, tables/interfaces, concurrent/API et sortie. Pour un incident concret, conserver fichier/lot, UO, pièce, demande et état de l’étape ; demander les valeurs manquantes seulement lorsqu’elles conditionnent le diagnostic.
- **Tracer un workflow** : retrouver le type d’item, le processus et le point de départ dans l’export `.wft`, suivre les résultats/transitions puis les callbacks `.pkb`. Vérifier les enfants et attentes ; présence d’une activité et fin du parent ne démontrent pas son exécution.
- **Analyser un traitement spécifique** : lire contrat public `.pks`, corps, lanceur, définition FND et paramètres pertinents. Identifier les effets directs/indirects et les points de reprise utiles à la question : DML/DDL, hooks, commits, fichiers, demandes et notifications.
- **Modifier un composant à la demande** : confirmer variante et source de référence, examiner appelants/paramètres/callbacks affectés et définir une validation adaptée. Ne pas confondre correction d’une fiche générée avec correction de la source ; tenir la note correspondante à jour.
- **Vérifier la fraîcheur ou actualiser** : lire [ACTUALISATION.md](../../../.ai/dka/ACTUALISATION.md). Comparer au relevé existant avant de régénérer. La génération documentaire ne met pas à jour les conclusions métier et ne valide pas la production.

## Preuves et limites

Citer le fichier source et ses lignes pour les comportements spécifiques. Distinguer fait statique, affirmation documentaire, hypothèse et résultat d’exécution. Un nom de fichier `_PROD`, un statut spécifique OK, une soumission FND ou une transition finale ne suffisent pas à établir l’intégration métier ou le déploiement.

Une demande d’analyse n’autorise pas à exécuter les SQL, shells, FNDLOAD ou workflows du corpus. Les scripts Python documentaires sont décrits séparément ; leur rôle n’est pas de lancer les traitements Oracle. Ne pas recopier de secrets ou données bancaires dans les réponses ou la mémoire.

Répondre en français par défaut, avec le résultat utile, les preuves et les limites qui changent la décision. Ce skill ne remplace pas les règles plus spécifiques du dépôt ni les instructions explicites de l’utilisateur.
