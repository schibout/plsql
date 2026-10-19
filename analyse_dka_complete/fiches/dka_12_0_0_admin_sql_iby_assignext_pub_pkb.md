# IBY_ASSIGNEXT_PUB.pkb

Source : [dka/12.0.0/admin/sql/IBY_ASSIGNEXT_PUB.pkb](../../dka/12.0.0/admin/sql/IBY_ASSIGNEXT_PUB.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 261 ; encodage : cp1252 (repli). SHA-256 : `61db1ae40900e19396b348cedc2f51c8e6f7b606043daf3de85755b0d0a24e52`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `print_debuginfo` | 42 |
| `hookForAssignments` | 77 |
| `print_debuginfo` | 231 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 112 |
| `fnd_concurrent_requests` | 127 |
| `IBY_PAYMENT_PROFILES` | 155 |
| `dka_prel_ap_rb` | 172 |
| `IBY_PAYMENT_PROFILES` | 184 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `iby_build_utils_pkg.print_debuginfo` | 252 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 145 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
