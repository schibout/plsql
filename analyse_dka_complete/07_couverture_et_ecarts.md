# Couverture, méthode et écarts à confirmer

## Couverture du dossier

- **2 702 fichiers** inventoriés dans `dka/`, soit 60 891 428 octets.
- **2 687 fichiers texte** lus intégralement par extraction statique, représentant 1 556 125 lignes ; **15 fichiers** inventoriés uniquement par métadonnées.
- **255 corps de packages et 255 spécifications** présents comme fichiers. Le scanner relève 249 noms de corps distincts : les occurrences et copies restent conservées dans le catalogue.
- **1 225 fiches techniques** : packages et spécifications, SQL, shells et variantes reconnues, workflows, contrôles de chargement, triggers, vues et autres exécutables reconnus.
- **458 occurrences de définition PROGRAM**, représentant **418 identités de programme/application** dans les exports lus. Les variantes de langue et de livraison ne prouvent pas autant de traitements actifs.
- **1 674 occurrences de paramètres spécifiques ou segments SRS** dans les exports locaux.
- **12 exports Workflow** : 1 383 activités, 244 processus, 3 077 instances et 3 651 transitions extraits. Ces totaux comprennent des versions et bibliothèques ; ce ne sont pas des effectifs de processus déployés.

## Niveaux de preuve

| Niveau | Ce qui est établi | Ce qui ne l’est pas |
|---|---|---|
| Inventaire | Présence, taille, empreinte et format de chaque fichier | Déploiement, activité et version de référence |
| Extraction statique | Occurrences d’objets, routines, références et marqueurs ; blocs exportés | Sémantique complète, atteignabilité et résultats d’exécution |
| Revue fonctionnelle ciblée | Chaînes décrites et effets cités dans les notes spécialisées | Validation instruction par instruction de tous les packages |
| Définition FND | Programme, exécutable, propriétés présentes dans l’export | Activation actuelle, paramètres effectifs, droits et planification |
| Structure Workflow | Activités, instances, résultats, cibles et callbacks exportés | Version active, rôles réels, mail remis et parcours d’instances en production |

## Limites des extracteurs

Les fiches automatiques utilisent des expressions régulières, pas un compilateur Oracle. Les CTE peuvent être prises pour des tables ; une référence dans une chaîne ou du SQL dynamique peut être détectée sans exécution ou manquer. Les commentaires SQL sont retirés en conservant les lignes ; ce traitement ne remplace pas un parseur des chaînes PL/SQL. Les commentaires shell ne sont pas systématiquement exclus. Les appels dynamiques, paramètres positionnels, résolutions par synonymes, schémas et liens de base demandent une analyse complémentaire.

La résolution des exécutables FND se fait par nom court ; les collisions d’application et versions doivent être arbitrées. Les propriétés multilignes ne sont pas toutes reconstruites dans le catalogue FND. L’extracteur Workflow traite les continuations, mais ne reconstitue pas tous les corps multilignes de messages. Les annexes conservent donc la source comme référence finale.

Le graphe agrège les références et la configuration locale. Les fichiers de données ou configuration non reliés peuvent rester isolés. Une absence de relation dans le graphe n’est pas une preuve d’indépendance.

## Périmètre géographique du dépôt

Ce nouveau dossier a `dka/` comme source principale. Il complète les analyses précédentes du reste du dépôt et ne fusionne pas automatiquement les copies déposées ailleurs, notamment celles d’autres dossiers d’incidents. Les divergences entre copies doivent être arbitrées par empreinte et version déployée. Aucun composant DKA n’a été exécuté.

## Pièces hors lecture textuelle

La liste exacte figure dans l’inventaire avec la mention « métadonnées seulement ». Les classeurs, archives et autres binaires ne sont pas ouverts ou décompressés. Leurs éventuels mappings ou contenus additionnels ne sont donc pas certifiés dans ce dossier.

## Conditions pour une validation finale

La conclusion d’exploitation nécessite les versions installées et compilées, le paramétrage réel, les exports ordonnanceur, les contrats de données, les résultats des scénarios de recette et l’accord des responsables métier. Les coûts de tokens des revues ne sont pas exposés par les outils : ils ne sont pas mesurés dans le rapport du graphe.
