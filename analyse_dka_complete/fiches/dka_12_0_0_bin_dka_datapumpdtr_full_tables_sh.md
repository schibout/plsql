# DKA_DATAPUMPDTR_FULL_TABLES.sh

Source : [dka/12.0.0/bin/DKA_DATAPUMPDTR_FULL_TABLES.sh](../../dka/12.0.0/bin/DKA_DATAPUMPDTR_FULL_TABLES.sh).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 111 ; encodage : utf-8. SHA-256 : `3fca3adedcfe81d7212eff33a6e6ece0f5c72369c191f0afae2138d53fd799db`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PA.PA_PROJECTS_ALL` | 62 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `@$DKA_TOP/sql/DKA_TABLES_DTR_FULL_TABLES.sql` | 57 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 57 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
