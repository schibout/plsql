# DKA_IAPFAC_EXPORTDSP_JOB.sh

Source : [dka/12.0.0/bin/DKA_IAPFAC_EXPORTDSP_JOB.sh](../../dka/12.0.0/bin/DKA_IAPFAC_EXPORTDSP_JOB.sh).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 68 ; encodage : cp1252 (repli). SHA-256 : `5d45dfe0bdb0cba7e41f33b16eff907ec41c5d95010de09f814aa4fce293d5c1`.

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
| `@$DKA_TOP/sql/DKA_IAPFAC_EXPORTDSP.sql` | 46 |
| `$DKA_TOP/bin/DKA_IAPFAC_CREATEDIR.sh` | 51 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 45 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
