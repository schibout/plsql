# Utiliser le contexte DKA avec Claude, Codex et Gemini

Créé le 18 octobre 2026. Ces fichiers sont locaux au dépôt : ils accompagnent les analyses sans recopier les milliers de sources. Rien n’est installé dans le profil global de l’utilisateur.

## Emplacements et démarrage

| Outil | Contexte initial | Skill du dépôt | Utilisation |
|---|---|---|---|
| Codex | [AGENTS.md](../../AGENTS.md), qui demande la lecture du contexte commun | [.agents/skills/dka-ebs/SKILL.md](../../.agents/skills/dka-ebs/SKILL.md) | Ouvrir une nouvelle session dans ce dépôt ; demander `Utilise $dka-ebs pour analyser…` |
| Claude Code | [CLAUDE.md](../../CLAUDE.md), qui importe le contexte commun | [.claude/skills/dka-ebs/SKILL.md](../../.claude/skills/dka-ebs/SKILL.md) | Ouvrir le dépôt, puis `/dka-ebs` ou une demande DKA pertinente |
| Gemini CLI | [GEMINI.md](../../GEMINI.md), qui importe le contexte commun | [.gemini/skills/dka-ebs/SKILL.md](../../.gemini/skills/dka-ebs/SKILL.md) et alias partagé `.agents/skills` | Ouvrir le dépôt ; `/skills list`, puis demander d’utiliser `dka-ebs` ; `/skills reload` pour rafraîchir la liste |

La découverte reste soumise à la version du client, à la confiance du projet et aux politiques de l’environnement. Gemini peut demander un consentement à l’activation ; il privilégie l’alias `.agents/skills` si le même nom existe aux deux endroits. Les deux copies sont identiques, donc ce choix ne change pas le contenu. Aucune politique de permissions ni configuration locale existante n’a été modifiée.

Ces emplacements visent Codex, Claude Code et Gemini CLI avec accès au dossier. Une conversation dans un site web sans accès au dépôt ne charge pas ces fichiers automatiquement. Dans ce cas, fournir le [contexte commun](CONTEXTE.md) et les seules notes pertinentes ; les références aux sources ne deviennent pas disponibles par le seul téléversement du skill.

## Exemples de demandes

- « Utilise dka-ebs pour expliquer la chaîne d’intégration des factures Xerox et les preuves de réussite. »
- « Trace le workflow CSP, ses branches de rejet et les callbacks associés. »
- « Quels traitements sont touchés si je modifie cette procédure ? Cite les sources. »
- « Vérifie si le dossier d’analyse est à jour sans régénérer l’inventaire. »
- « J’ai ajouté des sources DKA : actualise le catalogue puis révise les notes affectées. »

## Ce qui est partagé

Le [contexte court](CONTEXTE.md) donne le vocabulaire et les pièges connus ; le [routage](ROUTAGE.md) dirige vers une seule note pertinente ; le [guide d’actualisation](ACTUALISATION.md) distingue contrôle de fraîcheur et régénération. Les analyses détaillées et le code restent les sources de preuve.

Le skill de référence est dans `.agents/skills/dka-ebs/`. Après une évolution de ses instructions, synchroniser les copies Claude et Gemini. Les chemins sont relatifs : déplacer ou cloner l’ensemble du dépôt conserve les renvois ; copier uniquement le dossier du skill ailleurs ne le rend pas autonome.

## Validation effectuée et limites

Un test avant création a montré qu’une IA nouvelle, limitée à quelques lectures, ne retrouvait pas le sens précis de l’export Ivalua ni le vérificateur de fraîcheur. Avec le skill et le contexte, une autre IA a retrouvé ces réponses ainsi que la limite de la fin du workflow AP, en ne lisant que deux notes spécialisées.

Cette évaluation porte sur les instructions et la navigation documentaire, pas sur des exécutions dans les trois produits. La validation de format et de liens est rapportée dans [validation_skills.json](validation_skills.json). Aucun SQL, shell ou traitement Oracle n’est exécuté pour vérifier les skills.

## Références officielles vérifiées

- [Codex : skills du dépôt et découverte `.agents/skills`](https://learn.chatgpt.com/docs/build-skills).
- [Codex : instructions AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- [Claude Code : skills](https://code.claude.com/docs/en/skills) et [contexte CLAUDE.md / imports](https://code.claude.com/docs/en/memory).
- [Gemini CLI : skills et alias](https://geminicli.com/docs/cli/skills/) et [contexte GEMINI.md / imports](https://geminicli.com/docs/cli/gemini-md/).
