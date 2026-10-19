# DKA_AMOR_FISC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_AMOR_FISC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_AMOR_FISC_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 527 ; encodage : cp1252 (repli). SHA-256 : `be2f64bd86fe8f043314f9b2ec73cedf5b07ae55a46d149be7d364dda0ae8514`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `version` | 57 |
| `Insert_Data` | 80 |
| `Delete_Data` | 501 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Fnd_Flex_Value_Sets` | 111 |
| `Fnd_Flex_Value_Sets` | 130 |
| `Fa_Book_Controls` | 206 |
| `Fa_Deprn_Periods` | 226 |
| `Fa_Deprn_Periods` | 245 |
| `Dka_Stransco_Headers` | 256 |
| `Fa_Asset_Invoices` | 292 |
| `Fa_Additions_B` | 303 |
| `Fa_Book_Controls` | 317 |
| `Fa_Deprn_Summary` | 350 |
| `Fa_Deprn_Summary` | 356 |
| `Fa_Deprn_Summary` | 383 |
| `Fa_retirements_v` | 429 |
| `Dka_Amor_Fisc` | 441 |
| `DKA_AMOR_FISC` | 509 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `@Package_name..sql` | 5 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 480, 515 |
| when_others | 325, 361, 483 |
| suppression | 509 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
