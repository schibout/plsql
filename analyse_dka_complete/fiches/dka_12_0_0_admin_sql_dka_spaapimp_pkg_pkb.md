# DKA_SPAAPIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAAPIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAAPIMP_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 168 ; encodage : cp1252 (repli). SHA-256 : `1b16d8ca743aadc7a0fa6905d996bad153f6cf656d7232589cb49e6a6793c28c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 46 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoices_all` | 66 |
| `fnd_responsibility` | 123 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 90 |
| `fnd_global.apps_initialize` | 127 |
| `fnd_request.set_org_id` | 130 |
| `fnd_request.submit_request` | 134 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `PAAPIMP` | 134 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 159 |
| soumission | 134 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPAAPIMP / DKA | `DKA_SPAAPIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPAAPIMP.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
