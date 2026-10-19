# Contexte du projet PL/SQL DKA

Ce dépôt documente une application spécifique **Oracle E-Business Suite DKA** : intégrations AP/AR/GL/PO/PA/FA/RH/CE, workflows, clôtures, règlements et reprises. Pour une tâche DKA, lire [.ai/dka/CONTEXTE.md](.ai/dka/CONTEXTE.md) au premier accès ; ce fichier est le contexte commun de Codex, Claude et Gemini.

Skill projet : [.agents/skills/dka-ebs/SKILL.md](.agents/skills/dka-ebs/SKILL.md). L’utiliser pour une question d’intégration, de workflow, de traitement spécifique, de diagnostic ou de mise à jour du dossier DKA. Charger ensuite seulement la note correspondant à la question.

Les sources sont dans `dka/`, l’analyse principale dans `analyse_dka_complete/` et la première analyse de facturation dans `analyse_integration_facturation/`. Le README racine historique ne décrit qu’un diagnostic de facture, pas l’ensemble du projet.

Ne pas confondre documentation générée et code déployé. Une demande d’analyse ne demande pas d’exécuter les SQL, shells ou imports Oracle du corpus. Citer la variante de source et ses lignes ; distinguer constat statique, hypothèse et résultat en base.

# graphify

- **graphify** (`~/.Codex/skills/graphify/SKILL.md`) — entrée vers le graphe de connaissances. Déclencheur : `/graphify`.
- Quand l’utilisateur tape `/graphify`, invoquer d’abord la compétence `graphify` avec le mécanisme de skills disponible, avant toute autre action. Si cette compétence n’est pas disponible, le signaler sans simuler son invocation.
- Les graphes existants sont des aides de navigation, pas une preuve d’exécution ou de déploiement.
