# DKA_AP_SUPPLIER_SITES_ALL.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_SUPPLIER_SITES_ALL.trg](../../dka/12.0.0/admin/sql/DKA_AP_SUPPLIER_SITES_ALL.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 287 ; encodage : cp1252 (repli). SHA-256 : `b7c22d202635a61fc0909aa2c117283df62e2ac686b353cd45da1863d4c21f46`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_AP_SUPPLIER_SITES_ALL` | 21 |
| `APPS.DKA_AP_SUPPLIER_SITES_ALL` | 24 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 25 |
| `DKA_SAPFRS_MAJ_SITES` | 139 |
| `DKA_SAPFRS_MAJ_SITES` | 161 |
| `DKA_SAPFRS_MAJ_SITES` | 166 |
| `DKA_SAPFRS_MAJ_SITES` | 175 |
| `DKA_SAPFRS_MAJ_SITES` | 188 |
| `DKA_SAPFRS_MAJ_SITES` | 211 |
| `DKA_SAPFRS_MAJ_SITES` | 226 |
| `DKA_SAPFRS_MAJ_SITES` | 249 |
| `ap_supplier_sites_all` | 251 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 34 |
| `dka_sapfrs_history_pkg.get_term_name` | 62 |
| `dka_sapfrs_history_pkg.get_term_name` | 84 |
| `dka_sapfrs_history_pkg.get_user_name` | 104 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 114 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 125 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 267 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 262 |
| transaction_autonome | 37 |
| when_others | 280 |
| suppression | 139, 188, 226 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
