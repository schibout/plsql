# DKA_SAPCREATE_BLOCAGES_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 345 ; encodage : cp1252 (repli). SHA-256 : `cfc147da0fdf22fa26bf8dd70919ab4a7f0ed55bd3b26f54ebde06ad52a5dbb7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 45 |
| `Blocage_date_facture` | 101 |
| `Blocage_fres_affact` | 182 |
| `cree_blocage` | 266 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoices_all` | 108 |
| `ap_holds_all` | 116 |
| `dka_stransco_headers` | 122 |
| `ap_invoices_all` | 156 |
| `ap_invoices_all` | 189 |
| `ap_holds_all` | 197 |
| `dka_stransco_headers` | 203 |
| `ap_invoices_all` | 240 |
| `ap_lookup_codes` | 282 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 52 |
| `Dka_Tools_Pkg.put_debug_message` | 53 |
| `Dka_Tools_Pkg.put_debug_message` | 54 |
| `dka_tools_pkg.put_log_message` | 58 |
| `DKA_TOOLS_PKG.put_debug_message` | 64 |
| `Dka_Tools_Pkg.put_debug_message` | 69 |
| `DKA_TOOLS_PKG.put_debug_message` | 74 |
| `Dka_Tools_Pkg.put_debug_message` | 79 |
| `Dka_Tools_Pkg.put_debug_message` | 83 |
| `Dka_Tools_Pkg.put_debug_message` | 141 |
| `DKA_TOOLS_PKG.put_debug_message` | 145 |
| `DKA_TOOLS_PKG.put_debug_message` | 161 |
| `DKA_TOOLS_PKG.put_debug_message` | 166 |
| `Dka_Tools_Pkg.put_debug_message` | 168 |
| `Dka_Tools_Pkg.put_debug_message` | 225 |
| `DKA_TOOLS_PKG.put_debug_message` | 229 |
| `DKA_TOOLS_PKG.put_debug_message` | 245 |
| `DKA_TOOLS_PKG.put_debug_message` | 250 |
| `Dka_Tools_Pkg.put_debug_message` | 252 |
| `AP_HOLDS_PKG.insert_single_hold` | 325 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 86, 333 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPCREATE_BLOCAGES / DKA | `DKA_SAPCREATE_BLOCAGES_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPCREATE_BLOCAGES.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
