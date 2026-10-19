# DKA_IEOMTL_PURGRECH_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOMTL_PURGRECH_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOMTL_PURGRECH_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 114 ; encodage : cp1252 (repli). SHA-256 : `6eb8f31d273ba970426d37d1baa073d8107d54d752eda177953467d1e56cbd4b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `PURGE_RECH_CATALOG` | 42 |
| `MAIN` | 95 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA.DKA_SICXRECHCAT_HIST` | 55 |
| `DKA.DKA_SICXRECHCAT_HIST` | 72 |
| `DKA.DKA_SICXRECHCAT_HIST` | 77 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 63 |
| `FND_FILE.PUT_LINE` | 64 |
| `FND_FILE.PUT_LINE` | 65 |
| `FND_FILE.PUT_LINE` | 89 |
| `FND_FILE.PUT_LINE` | 90 |
| `FND_FILE.PUT_LINE` | 91 |
| `FND_FILE.PUT_LINE` | 92 |
| `DKA_IEOMTL_PURGRECH_PKG.PURGE_RECH_CATALOG` | 105 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 83 |
| suppression | 77 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_PURGE_RECH_CATAL / DKA | `DKA_IEOMTL_PURGRECH_PKG.MAIN` | dka/12.0.0/admin/import/DKA_PURGE_RECH_CATAL_PRG.ldt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
