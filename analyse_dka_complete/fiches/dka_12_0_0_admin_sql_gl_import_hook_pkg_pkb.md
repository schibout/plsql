# GL_IMPORT_HOOK_PKG.pkb

Source : [dka/12.0.0/admin/sql/GL_IMPORT_HOOK_PKG.pkb](../../dka/12.0.0/admin/sql/GL_IMPORT_HOOK_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 120 ; encodage : utf-8. SHA-256 : `fc04898e577f8d1ef6b40e33a5cf30130bf80f5e00c6b017f023e1dae786deba`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `pre_module_hook` | 45 |
| `post_module_hook` | 95 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SGLALIREFEMP_PKG.MAIN` | 53 |
| `dka_sglmasqzero_pkg.MAIN` | 58 |
| `DKA_SGLALICUF_PKG.MAIN` | 110 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
