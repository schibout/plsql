# DKA_SARRGLTPRLV_AUTO_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_AUTO_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_AUTO_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 88 ; encodage : utf-8. SHA-256 : `53e661353e81e5ec1f532053ed4c56174a1c8e4428e4f79f39fbf1e86cc569a6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `MAIN1` | 30 |
| `MAIN2` | 45 |
| `MAIN3` | 60 |
| `ENVOI_MAIL` | 78 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARRGLTPRLV_AUTO2 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN2` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO2_PRG.ldt:515 |
| DKA_SARRGLTPRLV_AUTO3 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN3` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO3_PRG.ldt:515 |
| DKA_SARRGLTPRLV_MAIL / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.ENVOI_MAIL` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO_MAIL_PKG.prt:553 |
| DKA_SARRGLTPRLV_AUTO1 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN1` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO_PKG.prt:515 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
