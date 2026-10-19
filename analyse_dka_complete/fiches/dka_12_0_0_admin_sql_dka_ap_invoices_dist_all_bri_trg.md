# dka_ap_invoices_dist_all_bri.trg

Source : [dka/12.0.0/admin/sql/dka_ap_invoices_dist_all_bri.trg](../../dka/12.0.0/admin/sql/dka_ap_invoices_dist_all_bri.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 165 ; encodage : cp1252 (repli). SHA-256 : `cb6d43b99d4894674e350f2278e94c51cf566b8bb145c7b8be7ce28730ba1a24`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `APPS.dka_ap_invoices_dist_all_bri` | 1 |
| `dka_ap_invoices_dist_all_bri` | 164 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_holds_all` | 110 |
| `ap_hold_codes` | 119 |
| `ap_invoices_all` | 123 |
| `po_headers_all` | 129 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 59 |
| `dka_tools_pkg.get_parameter` | 67 |
| `dka_tools_pkg.get_parameter` | 74 |
| `dka_tools_pkg.get_parameter` | 81 |
| `dka_tools_pkg.get_parameter` | 89 |
| `dka_tools_pkg.get_parameter` | 99 |
| `AP_HOLDS_PKG.insert_single_hold` | 141 |
| `AP_HOLDS_PKG.insert_single_hold` | 151 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
