# DKA_SAPDUPLICATIONFRS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPDUPLICATIONFRS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPDUPLICATIONFRS_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 341 ; encodage : cp1252 (repli). SHA-256 : `c5d286fe4a4dac9f3f0d1e8db565d88671b6bc504f7aaea9b7a9d9502f36c273`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `CHARGER_AP_DUPLICA` | 70 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_lobs` | 144 |
| `dual` | 236 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 238 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 297 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 23 |
| `fnd_profile.value` | 24 |
| `fnd_profile.value` | 25 |
| `fnd_profile.value` | 26 |
| `fnd_gfm.get_file_id` | 131 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 303, 310 |
| when_others | 150, 193, 202, 211, 220, 326 |
| suppression | 297 |
| truncate | 126 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
