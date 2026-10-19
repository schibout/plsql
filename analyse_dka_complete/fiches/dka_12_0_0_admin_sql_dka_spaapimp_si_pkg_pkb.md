# DKA_SPAAPIMP_SI_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAAPIMP_SI_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAAPIMP_SI_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 220 ; encodage : cp1252 (repli). SHA-256 : `9fa6f4bb0566cfb6be57b8f8326fd9c0007321b6eee8d46adad36c727803e0ac`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 50 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_all_organization_units` | 77 |
| `ap_invoices` | 79 |
| `fnd_responsibility` | 132 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 90 |
| `dka_tools_pkg.put_log_message` | 91 |
| `dka_tools_pkg.get_parameter` | 93 |
| `dka_tools_pkg.put_debug_message` | 105 |
| `dka_tools_pkg.put_debug_message` | 111 |
| `dka_tools_pkg.put_debug_message` | 118 |
| `dka_tools_pkg.put_debug_message` | 119 |
| `dka_tools_pkg.put_log_message` | 126 |
| `fnd_global.apps_initialize` | 137 |
| `fnd_request.set_org_id` | 140 |
| `fnd_request.submit_request` | 146 |
| `dka_tools_pkg.put_debug_message` | 164 |
| `fnd_concurrent.wait_for_request` | 180 |
| `dka_tools_pkg.put_outdebug_message` | 189 |
| `dka_tools_pkg.put_debug_message` | 193 |
| `dka_tools_pkg.put_outdebug_message` | 195 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `PAAPIMP_SI` | 146 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 176 |
| when_others | 210 |
| soumission | 146 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPAAPIMP_SI / DKA | `DKA_SPAAPIMP_SI_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPAAPIMP_SI.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
