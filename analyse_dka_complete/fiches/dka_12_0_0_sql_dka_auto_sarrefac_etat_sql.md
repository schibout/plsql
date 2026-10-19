# DKA_AUTO_SARREFAC_ETAT.sql

Source : [dka/12.0.0/sql/DKA_AUTO_SARREFAC_ETAT.sql](../../dka/12.0.0/sql/DKA_AUTO_SARREFAC_ETAT.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 401 ; encodage : cp1252 (repli). SHA-256 : `e1174a711a5c29d9efa00db0b0184eed8e3fa7feb38dc7b9cd119db2e71bab67`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Recherche_Request_Id` | 88 |
| `Recherche_Extension` | 136 |
| `Ecriture_Fichier` | 179 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Fnd_Flex_Value_Sets` | 68 |
| `fnd_conc_req_outputs` | 80 |
| `Fnd_Concurrent_Requests` | 96 |
| `GL_PERIODS` | 166 |
| `all_directories` | 270 |
| `DUAL` | 392 |
| `DUAL` | 394 |
| `DUAL` | 400 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 243 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_SARREFAC_ETAT_BOR.sh` | 356 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 252, 279, 383 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_SARREFAC_ETAT / DKA | `DKA_AUTO_SARREFAC_ETAT` | dka/12.0.0/admin/import/DKA_AUTO_SARREFAC_ETAT.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
