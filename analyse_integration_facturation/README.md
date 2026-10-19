# Analyse de l’intégration de la facturation

Dossier constitué le **17 octobre 2026** à partir des fichiers locaux de `C:/Projects/plsql`.

**Extension DKA :** le [dossier complet des intégrations, workflows et traitements spécifiques](../analyse_dka_complete/README.md) analyse les nouvelles sources `dka/`, dont packages, workflows, lanceurs et définitions FND. Il complète cette première analyse centrée sur SQL et README.

## Lecture du dossier

1. [Synthèse et chaîne d’intégration](00_synthese.md)
2. [Inventaire et méthode](01_inventaire_et_methodologie.md) — 193 fichiers : 159 SQL et 34 README.
3. [Factures fournisseurs / AP](02_flux_fournisseurs_AP.md)
4. [Factures clients / AR et supervision](03_flux_clients_AR_et_supervision.md)
5. [Comptabilité, référentiels et périmètre connexe](04_comptabilite_referentiels_et_perimetre.md)
6. [Risques et plan de validation](05_plan_de_validation.md)

L’[inventaire JSON](inventaire_sources.json) fournit chemins, tailles, nombres de lignes, empreintes SHA-256 et candidats objets SQL. Le [graphe](../graphify-out/graph.html) et son [rapport](../graphify-out/GRAPH_REPORT.md) complètent la navigation. Leurs relations sourcées ne prouvent pas le déploiement des objets.

## Portée et limites

L’inventaire couvre récursivement les extensions `.sql` et les noms commençant par `README`, y compris les fichiers ignorés par Git et cinq README de cache. Les notes distinguent lecture mécanique intégrale et revue sémantique ciblée. Cette livraison ne constitue pas un audit instruction par instruction des grands packages.

Les `.pkb`, `.pks`, scripts Python/shell, autres Markdown, CSV et pièces Office/PDF ne sont pas des sources principales de cette revue. Les références à ces fichiers dans les README restent des déclarations documentaires à confirmer. Les scripts peuvent être historiques, ponctuels ou incomplets.

Aucune connexion Oracle, exécution SQL, compilation ou modification des scripts sources. Une mention « validé » dans un README est une affirmation historique, pas une validation réalisée pour ce dossier.

