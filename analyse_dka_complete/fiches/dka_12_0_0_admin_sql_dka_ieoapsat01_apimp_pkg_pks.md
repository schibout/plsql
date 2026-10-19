# DKA_IEOAPSAT01_APIMP_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 73 ; encodage : cp1252 (repli). SHA-256 : `7d30cd9fbefd0e40e85f17bbccee4f7a347cbe53fba4e207bbaab541723e1565`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `CREATE_AP_IMPORT_FILE` | 42 |
| `MAIN` | 62 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 24 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CREATE_APIMPORT_FILE / DKA | `DKA_IEOAPSAT01_APIMP_PKG.CREATE_AP_IMPORT_FILE` | dka/12.0.0/admin/import/DKA_CREATE_APIMPORT_FILE.prt:504 |
| DKA_IEOAPSAT01_APIMP / DKA | `DKA_IEOAPSAT01_APIMP_PKG.main` | dka/12.0.0/admin/import/DKA_IEOAPSAT01_APIMP.prt:422 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
