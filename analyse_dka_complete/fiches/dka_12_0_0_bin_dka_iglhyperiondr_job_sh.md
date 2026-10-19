# DKA_IGLHYPERIONDR_JOB.sh

Source : [dka/12.0.0/bin/DKA_IGLHYPERIONDR_JOB.sh](../../dka/12.0.0/bin/DKA_IGLHYPERIONDR_JOB.sh).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 128 ; encodage : cp1252 (repli). SHA-256 : `77b46dd88fb43012a936b959a4a331018cbb50aeb798a4a13c5e90a1f61d9794`.

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
| `@$DKA_TOP/sql/DKA_IGLHYPERIONDR.sql` | 52 |
| `@$DKA_TOP/sql/DKA_IGLHYPERIONDR.sql` | 59 |
| `@$DKA_TOP/admin/sql/DKA_IGLHYPERIONDR_REP.sql` | 94 |
| `@$DKA_TOP/sql/DKA_CONCATENAT_FILE.sql` | 106 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 51, 58, 94, 106 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
