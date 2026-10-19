# DKA_GLYRLBGE_JOB.sh

Source : [dka/12.0.0/bin/DKA_GLYRLBGE_JOB.sh](../../dka/12.0.0/bin/DKA_GLYRLBGE_JOB.sh).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 78 ; encodage : cp1252 (repli). SHA-256 : `2d1072363a991cae5928a0b80093f909b1c52ef9d3ad70f2f2c73e011396235f`.

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
| `@$DKA_TOP/sql/DKA_GLYRLBGE.sql` | 55 |
| `$DKA_TOP/bin/DKA_GLYRLBGE_BOR.sh` | 60 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 54 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
