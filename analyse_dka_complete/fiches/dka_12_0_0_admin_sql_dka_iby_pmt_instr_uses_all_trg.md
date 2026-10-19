# DKA_IBY_PMT_INSTR_USES_ALL.trg

Source : [dka/12.0.0/admin/sql/DKA_IBY_PMT_INSTR_USES_ALL.trg](../../dka/12.0.0/admin/sql/DKA_IBY_PMT_INSTR_USES_ALL.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 270 ; encodage : cp1252 (repli). SHA-256 : `e0ad610e232762adb4d65564d0ae45a9bf62b2a30675529866c4b2b57ba74746`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_IBY_PMT_INSTR_USES_ALL` | 20 |
| `APPS.DKA_IBY_PMT_INSTR_USES_ALL` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |
| `DUAL` | 71 |
| `DKA_SAPFRS_MAJ_SITES` | 78 |
| `DKA_SAPFRS_MAJ_SITES` | 105 |
| `DKA_SAPFRS_MAJ_SITES` | 141 |
| `DKA_SAPFRS_MAJ_SITES` | 171 |
| `DKA_SAPFRS_MAJ_SITES` | 202 |
| `DKA_SAPFRS_MAJ_SITES` | 229 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_site_id` | 40 |
| `dka_sapfrs_history_pkg.get_vendor_id` | 43 |
| `dka_sapfrs_history_pkg.get_user_name` | 62 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 132, 198, 258 |
| transaction_autonome | 37 |
| when_others | 262 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
