# DKA_RELANCE_JT_BDC.prc

Source : [dka/12.0.0/admin/sql/DKA_RELANCE_JT_BDC.prc](../../dka/12.0.0/admin/sql/DKA_RELANCE_JT_BDC.prc).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 252 ; encodage : cp1252 (repli). SHA-256 : `191ddb5e982d1ea85ca92203bd07afaf7b5dc2b440e455408e939569b57c62fa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `DKA_RELANCE_JT_BDC` | 20 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 30 |
| `PO_HEADERS` | 84 |
| `po_headers` | 181 |
| `PO_HEADERS` | 221 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_conc_date.string_to_date` | 41 |
| `fnd_conc_date.string_to_date` | 42 |
| `fnd_profile.value` | 50 |
| `dka_tools_pkg.put_debug_message` | 69 |
| `dka_tools_pkg.put_debug_message` | 70 |
| `dka_tools_pkg.put_debug_message` | 71 |
| `dka_tools_pkg.put_debug_message` | 72 |
| `dka_tools_pkg.put_debug_message` | 73 |
| `dka_tools_pkg.put_debug_message` | 79 |
| `dka_tools_pkg.put_debug_message` | 82 |
| `fnd_submit.set_request_set` | 88 |
| `dka_tools_pkg.put_debug_message` | 94 |
| `fnd_submit.submit_program` | 97 |
| `dka_tools_pkg.put_debug_message` | 125 |
| `fnd_submit.submit_program` | 128 |
| `dka_tools_pkg.put_debug_message` | 138 |
| `fnd_submit.submit_program` | 141 |
| `dka_tools_pkg.put_debug_message` | 151 |
| `fnd_submit.submit_program` | 154 |
| `dka_tools_pkg.put_debug_message` | 163 |
| `fnd_submit.submit_set` | 165 |
| `dka_tools_pkg.put_debug_message` | 168 |
| `dka_tools_pkg.put_debug_message` | 171 |
| `dka_tools_pkg.put_debug_message` | 186 |
| `fnd_concurrent.wait_for_request` | 191 |
| `dka_tools_pkg.put_outdebug_message` | 203 |
| `dka_tools_pkg.put_outdebug_message` | 210 |
| `dka_tools_pkg.put_debug_message` | 230 |
| `dka_tools_pkg.put_debug_message` | 231 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 187, 226 |
| rollback | 232 |
| when_others | 229 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_RELANCE_JT_BDC / DKA | `DKA_RELANCE_JT_BDC` | dka/12.0.0/admin/import/DKA_RELANCE_JT_BDC_F.prt:471 |
| DKA_RELANCE_JT_BDC / DKA | `DKA_RELANCE_JT_BDC` | dka/12.0.0/admin/import/DKA_RELANCE_JT_BDC_F.prt:471 |
| DKA_RELANCE_JT_BDC / DKA | `DKA_RELANCE_JT_BDC` | dka/12.0.0/admin/import/DKA_RELANCE_JT_BDC_US.prt:471 |
| DKA_RELANCE_JT_BDC / DKA | `DKA_RELANCE_JT_BDC` | dka/12.0.0/admin/import/DKA_RELANCE_JT_BDC_US.prt:471 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
