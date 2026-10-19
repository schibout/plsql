# execution_histo_lettrage.sh

Source : [dka/12.0.0/bin/execution_histo_lettrage.sh](../../dka/12.0.0/bin/execution_histo_lettrage.sh).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 70 ; encodage : cp1252 (repli). SHA-256 : `86d402c057c2e94c57944aea72c3ac590c7690e6db8ff73a9e0c1860fa60d7ba`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 44 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 46 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 48 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 50 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 52 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 54 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 56 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 58 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 60 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 62 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 64 |
| `@$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql` | 66 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 31, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
