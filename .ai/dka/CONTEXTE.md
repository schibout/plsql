# Contexte immédiat — Oracle EBS DKA

Référence de contexte préparée le **18 octobre 2026**, à partir de l’analyse locale du **17 octobre 2026**. Les chiffres décrivent cet instantané, pas un contrat permanent : vérifier l’inventaire si les sources ont changé.

## Ce projet

DKA est l’application spécifique d’un environnement Oracle E-Business Suite. Le dépôt regroupe des sources PL/SQL, scripts Unix/SQL*Plus, contrôles SQL*Loader, définitions FNDLOAD et exports Workflow. Ce n’est pas une application web ni une preuve de l’état de production.

| Emplacement depuis la racine du dépôt | Utilité |
|---|---|
| `dka/12.0.0/admin/sql/` | Packages `.pkb/.pks`, objets, triggers et scripts |
| `dka/12.0.0/sql/` | Lanceurs SQL, extractions, quelques packages |
| `dka/12.0.0/bin/` | Shells, contrôles de chargement et variantes |
| `dka/12.0.0/admin/import/` | Programmes FND, paramètres et workflows `.wft` |
| `analyse_dka_complete/` | Synthèse, notes par domaine, catalogue, fiches et JSON |
| `analyse_integration_facturation/` | Première analyse SQL/README ; utile aux incidents historiques |

L’instantané recense 2 702 fichiers, dont 255 corps et 255 spécifications de packages, 12 exports Workflow et 1 225 fiches techniques. Le catalogue est exhaustif en fichiers ; l’analyse fonctionnelle est ciblée. Les binaires et archives sont inventoriés par métadonnées seulement.

## Repères qui évitent les contresens

- **AP fournisseurs** : XGS/Xerox, ZCI et DSP utilisent le moteur `DKA_IAPFACXGS_PKG`, puis les interfaces AP et l’import standard. Un statut spécifique `OK`, une soumission FND ou la fin technique d’un concurrent ne prouvent pas seuls la création de la facture finale. Rapprocher lot/fichier, interface, rejets, demande et objet final.
- **Ivalua** : `DKA_IAPFAC_IVALUA_PKG` est un **export** Oracle vers Ivalua avec factures/images ; son nom ne permet pas d’en faire un import entrant. Voir `analyse_dka_complete/02_integrations.md`, section 2.3, et le corps du package.
- **AR clients** : staging `DKA_IARPAFAC_INTERFACE`, interfaces AR et transactions finales sont des étapes distinctes. Origine, société/UO, pièce, ligne, fichier, devise et grain de montant comptent ; le numéro de facture seul est insuffisant.
- **Workflow AP/CSP** : une fin du parent AP ne prouve pas la création de l’enfant CSP. La note Workflow décrit un `COMPLETE:FAIL` intercepté et une sortie parent `#ANY`. Vérifier l’enfant, sa clé, ses attributs et son état.
- **Workflows PO** : contrats, commandes et réceptions peuvent être orchestrés par maître/enfants, attentes et callbacks. Les activités présentes dans un export ne sont pas toutes sur le parcours effectivement lancé.
- **Comptabilisation** : certains `.wft` génèrent des combinaisons comptables ; ce ne sont pas tous des circuits humains d’approbation.
- **REP / FUS** : distinguer reprises historiques, fusions de sociétés et flux récurrents. `FUS` n’établit pas une migration Oracle Fusion Cloud.
- **Reprise** : commits intermédiaires, DDL/`TRUNCATE`, transactions autonomes et fichiers produits peuvent rendre un rollback global insuffisant. Les prélèvements et clôtures ont des points sensibles documentés.
- **Variantes** : comparer le chemin et le contenu. Les copies `_PROD`, ETI1, archives et sources `dka/` ne sont pas interchangeables ; le nom ne prouve pas la version installée.

Les détails et lignes probantes sont dans les notes puis dans les sources. Ces repères ne dispensent pas de vérifier la branche et la version concernées.

## Mode de travail

1. Lire le [routage documentaire](ROUTAGE.md) puis uniquement la note du domaine ; chercher le composant précis dans l’inventaire plutôt que charger les gros JSON ou les 1 225 fiches.
2. Vérifier le `.pks` pour le contrat public, le `.pkb` pour les effets, le `.prt/.ldt/.dpt` pour la configuration et le shell/SQL pour le lancement. Citer `chemin:ligne` dans la source locale.
3. Séparer faits statiques, documentation historique, interprétations et validations en environnement. Aucune analyse locale antérieure ne constitue un test de production.
4. Une demande documentaire ou d’analyse n’autorise pas l’exécution des SQL/shells/FNDLOAD/Workflow du corpus. Ne pas réutiliser ou afficher les identifiants, mots de passe ou données bancaires éventuellement présents.

## Actualisation

Pour **vérifier l’état existant sans régénérer l’inventaire** :

```powershell
python analyse_dka_complete/outils/verifier_livraison.py
```

Ce script lit les sources et écrit uniquement le rapport documentaire `verification_livraison.json`. Il détecte ajouts, disparitions et empreintes différentes ; s’il échoue, lire les écarts. Son champ `date` est actuellement codé en dur : il ne prouve pas la date d’une nouvelle exécution.

Pour une **régénération demandée**, suivre [ACTUALISATION.md](ACTUALISATION.md). Elle réécrit le catalogue et les fiches automatiques, pas l’analyse fonctionnelle. Ne pas régénérer avant un diagnostic de fraîcheur : cela remplacerait la référence d’empreintes à comparer.
