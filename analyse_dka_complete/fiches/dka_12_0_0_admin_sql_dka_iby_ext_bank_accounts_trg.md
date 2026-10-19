# DKA_IBY_EXT_BANK_ACCOUNTS.trg

Source : [dka/12.0.0/admin/sql/DKA_IBY_EXT_BANK_ACCOUNTS.trg](../../dka/12.0.0/admin/sql/DKA_IBY_EXT_BANK_ACCOUNTS.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 359 ; encodage : cp1252 (repli). SHA-256 : `43f82b6ad461ed62bc749f65df0285054a9ede32d66589d0444f5e3c2692d745`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `APPS.DKA_IBY_EXT_BANK_ACCOUNTS` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 2 |
| `IBY_PMT_INSTR_USES_ALL` | 19 |
| `DUAL` | 62 |
| `DKA_SAPFRS_MAJ_SITES` | 64 |
| `DKA_SAPFRS_MAJ_SITES` | 89 |
| `DKA_SAPFRS_MAJ_SITES` | 114 |
| `DUAL` | 151 |
| `DKA_SAPFRS_MAJ_SITES` | 168 |
| `DKA_SAPFRS_MAJ_SITES` | 198 |
| `DKA_SAPFRS_MAJ_SITES` | 230 |
| `DKA_SAPFRS_MAJ_SITES` | 271 |
| `DKA_SAPFRS_MAJ_SITES` | 296 |
| `DKA_SAPFRS_MAJ_SITES` | 321 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_user_name` | 53 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 139, 257, 346, 350 |
| transaction_autonome | 32 |
| when_others | 353 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
