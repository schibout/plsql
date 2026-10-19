# DKA_SAPFACT_BLOQ_EDIT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPFACT_BLOQ_EDIT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPFACT_BLOQ_EDIT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 69 ; encodage : utf-8. SHA-256 : `7d9f04316ac81f6ead0904358be42247a00c589f383b774a34e1e4f8bfefab88`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 27 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SAPREINITBLOCAGE_TMP` | 49 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 35 |
| `fnd_message.get_string` | 39 |
| `fnd_message.get_string` | 40 |
| `fnd_message.get_string` | 41 |
| `fnd_message.get_string` | 42 |
| `fnd_message.get_string` | 43 |
| `fnd_message.get_string` | 44 |
| `Dka_Tools_Pkg.put_outdebug_message` | 45 |
| `Dka_Tools_Pkg.put_outdebug_message` | 54 |
| `Dka_Tools_Pkg.put_log_message` | 62 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 60 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPFACT_BLOQ_EDIT / DKA | `DKA_SAPFACT_BLOQ_EDIT_PKG.main` | dka/12.0.0/admin/import/DKA_SAPFACT_BLOQ_EDIT.prt:484 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
