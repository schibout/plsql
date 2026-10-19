# DKA_SARRECOUVREMENT_PKG.pks

Source : [dka/12.0.0/sql/DKA_SARRECOUVREMENT_PKG.pks](../../dka/12.0.0/sql/DKA_SARRECOUVREMENT_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 197 ; encodage : cp1252 (repli). SHA-256 : `352bf70e834d03f14cdedebe8860ab0d3cb205899733e9f17a4cec9a219e1392`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Get_Last_Date` | 57 |
| `Get_Lib_Centre_Gestion` | 72 |
| `Get_Classe_Client` | 87 |
| `Get_Categorie_Client` | 102 |
| `Extraction_Encours` | 123 |
| `Extraction_Avoirs` | 148 |
| `Extraction_Ratios` | 180 |

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
| DKA_AVOIRS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_FRANCE.prt:617 |
| DKA_AVOIRS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_FRANCE.prt:617 |
| DKA_AVOIRS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_RECOUVREMENT.prt:617 |
| DKA_AVOIRS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_RECOUVREMENT.prt:617 |
| DKA_ENCOURS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_FRANCE.prt:617 |
| DKA_ENCOURS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_FRANCE.prt:617 |
| DKA_ENCOURS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_RECOUVREMENT.prt:617 |
| DKA_ENCOURS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_RECOUVREMENT.prt:617 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
