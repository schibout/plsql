# DKA_REPAPDESAC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPAPDESAC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPAPDESAC_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 240 ; encodage : cp1252 (repli). SHA-256 : `111285e1abe684106f7144d323b2b0692a77f4ec592945ed3c9b236a135c9e6e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 40 |
| `init_environnement` | 77 |
| `list_sites` | 122 |
| `MAIN` | 215 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 86 |
| `ap_suppliers` | 126 |
| `of` | 130 |
| `ap_suppliers` | 140 |
| `ap_supplier_sites_all` | 164 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 54 |
| `Dka_Tools_Pkg.put_log_message` | 58 |
| `fnd_global.apps_initialize` | 89 |
| `Dka_Tools_Pkg.put_log_message` | 95 |
| `Dka_Tools_Pkg.put_log_message` | 99 |
| `Dka_Tools_Pkg.put_log_message` | 103 |
| `Dka_Tools_Pkg.put_outdebug_message` | 146 |
| `Dka_Tools_Pkg.put_outdebug_message` | 147 |
| `Dka_Tools_Pkg.put_outdebug_message` | 149 |
| `Dka_Tools_Pkg.put_outdebug_message` | 150 |
| `Dka_Tools_Pkg.put_outdebug_message` | 154 |
| `Dka_Tools_Pkg.put_outdebug_message` | 155 |
| `Dka_Tools_Pkg.put_outdebug_message` | 156 |
| `Dka_Tools_Pkg.put_outdebug_message` | 157 |
| `Dka_Tools_Pkg.put_outdebug_message` | 176 |
| `Dka_Tools_Pkg.put_outdebug_message` | 184 |
| `Dka_Tools_Pkg.put_log_message` | 196 |
| `Dka_Tools_Pkg.put_log_message` | 219 |
| `Dka_Tools_Pkg.put_log_message` | 222 |
| `Dka_Tools_Pkg.put_log_message` | 225 |
| `Dka_Tools_Pkg.put_log_message` | 232 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 186 |
| rollback | 197, 233 |
| when_others | 55, 100, 193, 229 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPAPDESAC / DKA | `DKA_REPAPDESAC_PKG.main` | dka/12.0.0/admin/import/DKA_REPAPDESAC_F.prt:480 |
| DKA_REPAPDESAC / DKA | `DKA_REPAPDESAC_PKG.main` | dka/12.0.0/admin/import/DKA_REPAPDESAC_F.prt:480 |
| DKA_REPAPDESAC / DKA | `DKA_REPAPDESAC_PKG.main` | dka/12.0.0/admin/import/DKA_REPAPDESAC_US.prt:480 |
| DKA_REPAPDESAC / DKA | `DKA_REPAPDESAC_PKG.main` | dka/12.0.0/admin/import/DKA_REPAPDESAC_US.prt:480 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
