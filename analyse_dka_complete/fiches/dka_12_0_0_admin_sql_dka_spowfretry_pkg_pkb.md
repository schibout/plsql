# DKA_SPOWFRETRY_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOWFRETRY_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOWFRETRY_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 193 ; encodage : cp1252 (repli). SHA-256 : `3c42971c08960871b50fd6c2c93086f171521875f02f8b4553671612234b0954`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 33 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 58 |
| `wf_item_activity_statuses` | 70 |
| `wf_item_activity_statuses` | 122 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_outdebug_message` | 94 |
| `Dka_Tools_Pkg.put_outdebug_message` | 103 |
| `wf_engine.handleerror` | 106 |
| `Dka_Tools_Pkg.put_outdebug_message` | 133 |
| `WF_ENGINE.HandleError` | 135 |
| `Dka_Tools_Pkg.put_outdebug_message` | 150 |
| `Dka_Tools_Pkg.add_error_stack` | 152 |
| `Dka_Tools_Pkg.put_outdebug_message` | 164 |
| `Dka_Tools_Pkg.add_error_stack` | 166 |
| `Dka_Tools_Pkg.put_outdebug_message` | 171 |
| `Dka_Tools_Pkg.put_log_message` | 181 |
| `Dka_Tools_Pkg.put_log_message` | 182 |
| `Dka_Tools_Pkg.put_log_message` | 183 |
| `Dka_Tools_Pkg.print_error_stack` | 185 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 113, 142 |
| rollback | 175 |
| when_others | 145, 159, 174 |
| workflow | 106, 135, 138 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOWFRETRY / DKA | `DKA_SPOWFRETRY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOWFRETRY_F.prt:419 |
| DKA_SPOWFRETRY / DKA | `DKA_SPOWFRETRY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOWFRETRY_F.prt:419 |
| DKA_SPOWFRETRY / DKA | `DKA_SPOWFRETRY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOWFRETRY_US.prt:419 |
| DKA_SPOWFRETRY / DKA | `DKA_SPOWFRETRY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOWFRETRY_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
