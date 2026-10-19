# DKA_SAPCREATE_BLOCAGES_ALL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_ALL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_ALL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 180 ; encodage : cp1252 (repli). SHA-256 : `8e8c6d712cd81fcfd7decd2b82ca89109e7352e4691980c157aa89bc5bff69d8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 39 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoices_all` | 62 |
| `fnd_responsibility` | 96 |
| `hr_all_organization_units` | 162 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 72 |
| `fnd_global.apps_initialize` | 100 |
| `fnd_request.set_org_id` | 105 |
| `fnd_request.submit_request` | 108 |
| `dka_tools_pkg.put_debug_message` | 124 |
| `fnd_concurrent.wait_for_request` | 136 |
| `dka_tools_pkg.put_outdebug_message` | 144 |
| `dka_tools_pkg.put_debug_message` | 152 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_SAPCREATE_BLOCAGES` | 108 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 131 |
| when_others | 168 |
| soumission | 108 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPCREATE_BLOCAGES_ALL / DKA | `DKA_SAPCREATE_BLOCAGES_ALL_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPCREATE_BLOCAGES_ALL.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
