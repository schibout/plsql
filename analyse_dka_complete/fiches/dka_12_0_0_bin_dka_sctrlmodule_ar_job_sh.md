# DKA_SCTRLMODULE_AR_JOB.sh

Source : [dka/12.0.0/bin/DKA_SCTRLMODULE_AR_JOB.sh](../../dka/12.0.0/bin/DKA_SCTRLMODULE_AR_JOB.sh).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 67 ; encodage : cp1252 (repli). SHA-256 : `68258a7cca9088a7546d1ee1cd882150346afe6b05261d5a5ff2223c2bff2f04`.

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
| `@$DKA_TOP/sql/DKA_SCTRLMODULE.sql` | 45 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 44 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
