# DKA_SPADEPTRAVINT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPADEPTRAVINT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPADEPTRAVINT_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 202 ; encodage : cp1252 (repli). SHA-256 : `5ca5f5a424eaf4e72d0883f42cf50ad01b5419ad7e44bdbc149fdd656c4a1447`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 37 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_IEOPAGTO01_TMP` | 57 |
| `PA_TASKS` | 122 |
| `dka_parameters` | 144 |
| `pa_cost_distribution_lines_all` | 152 |
| `pa_expenditure_items_all` | 162 |
| `DKA_IEOPAGTO01_TMP` | 164 |
| `dka_parameters` | 173 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 46 |
| `Dka_Tools_Pkg.put_debug_message` | 52 |
| `Dka_Tools_Pkg.put_debug_message` | 55 |
| `Dka_Tools_Pkg.put_debug_message` | 158 |
| `Dka_Tools_Pkg.put_debug_message` | 167 |
| `Dka_Tools_Pkg.put_debug_message` | 185 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 169 |
| rollback | 182, 191 |
| when_others | 189 |
| truncate | 53 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPADEPTRAVINT / DKA | `DKA_SPADEPTRAVINT_PKG.main` | dka/12.0.0/admin/import/DKA_SPADEPTRAVINT.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
