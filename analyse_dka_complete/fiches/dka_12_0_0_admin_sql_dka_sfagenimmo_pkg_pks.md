# DKA_SFAGENIMMO_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SFAGENIMMO_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SFAGENIMMO_PKG.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 53 ; encodage : utf-8. SHA-256 : `965d698e33fec24e71adc0bcdadfba65d8b4156eec26fd98f2341ab1b405c073`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `transfer_immo` | 21 |
| `auto_acquis` | 27 |
| `imput_acquis` | 33 |
| `copie_hvp` | 39 |
| `valider_immo` | 45 |

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
| DKA_FA_AUTOACQ / DKA | `DKA_SFAGENIMMO_PKG.auto_acquis` | dka/12.0.0/admin/import/DKA_FA_AUTOACQ.prt:482 |
| DKA_FA_FAMCP / DKA | `DKA_SFAGENIMMO_PKG.copie_hvp` | dka/12.0.0/admin/import/DKA_FA_FAMCP.prt:481 |
| DKA_FA_FNDRSSUB46 / DKA | `DKA_SFAGENIMMO_PKG.imput_acquis` | dka/12.0.0/admin/import/DKA_FA_FNDRSSUB46.prt:482 |
| DKA_FA_PACFATBP / DKA | `DKA_SFAGENIMMO_PKG.valider_immo` | dka/12.0.0/admin/import/DKA_FA_PACFATBP.prt:484 |
| DKA_FA_PAXCPCAL / DKA | `DKA_SFAGENIMMO_PKG.transfer_immo` | dka/12.0.0/admin/import/DKA_FA_PAXCPCAL.prt:484 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
