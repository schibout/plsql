# DKA_SFADATAJ_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SFADATAJ_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SFADATAJ_PKG.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 54 ; encodage : utf-8. SHA-256 : `8930c55e91b4ec719d36ba29e8ae32d9017159a59814e84f59bcbe3b2f3138c6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `generer_comptes` | 22 |
| `calcul_values` | 27 |
| `transfer_immo` | 32 |
| `imput_acquis` | 37 |
| `copie_hvp` | 42 |
| `valider_immo` | 47 |

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
| DKA_FAGDA / DKA | `DKA_SFADATAJ_PKG.generer_comptes` | dka/12.0.0/admin/import/DKA_FAGDA.prt:419 |
| DKA_FAMCP / DKA | `DKA_SFADATAJ_PKG.copie_hvp` | dka/12.0.0/admin/import/DKA_FAMCP.prt:419 |
| DKA_FARET / DKA | `DKA_SFADATAJ_PKG.calcul_values` | dka/12.0.0/admin/import/DKA_FARET.prt:419 |
| DKA_FNDRSSUB46 / DKA | `DKA_SFADATAJ_PKG.imput_acquis` | dka/12.0.0/admin/import/DKA_FNDRSSUB46.prt:419 |
| DKA_PACFATBP / DKA | `DKA_SFADATAJ_PKG.valider_immo` | dka/12.0.0/admin/import/DKA_PACFATBP.prt:420 |
| DKA_PAXCPCAL / DKA | `DKA_SFADATAJ_PKG.transfer_immo` | dka/12.0.0/admin/import/DKA_PAXCPCAL.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
