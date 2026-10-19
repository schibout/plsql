# DKA_SPAAUTCRE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAAUTCRE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAAUTCRE_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 712 ; encodage : cp1252 (repli). SHA-256 : `cc36227b6c89a8cd768fc4c16c896dfcd413ac0c21a0ea9c31028d6d107c08ad`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 63 |
| `output_header` | 146 |
| `Request_parameters` | 196 |
| `output_end` | 294 |
| `ajout_beneficiaires` | 328 |
| `enregistrement` | 449 |
| `main` | 569 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 109 |
| `fnd_concurrent_programs` | 158 |
| `fnd_concurrent_requests` | 200 |
| `fnd_concurrent_requests` | 231 |
| `fnd_concurrent_requests` | 253 |
| `hr_operating_units` | 342 |
| `pa_cc_org_relationships` | 379 |
| `hr_operating_units` | 462 |
| `PA_CC_ORG_RELATIONSHIPS` | 497 |
| `hr_operating_units` | 613 |
| `xle_entity_profiles` | 618 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 75 |
| `fnd_profile.value` | 93 |
| `Dka_Tools_Pkg.put_debug_message` | 100 |
| `Dka_Tools_Pkg.put_debug_message` | 113 |
| `Dka_Tools_Pkg.put_debug_message` | 123 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 175 |
| `Fnd_File.put_line` | 178 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 217 |
| `Dka_Tools_Pkg.put_debug_message` | 218 |
| `Dka_Tools_Pkg.put_debug_message` | 219 |
| `Fnd_File.put_line` | 237 |
| `Dka_Tools_Pkg.put_debug_message` | 240 |
| `Fnd_File.put_line` | 259 |
| `Dka_Tools_Pkg.put_debug_message` | 262 |
| `Fnd_File.put_line` | 267 |
| `Fnd_File.put_line` | 270 |
| `Dka_Tools_Pkg.put_debug_message` | 271 |
| `Fnd_File.put_line` | 300 |
| `Fnd_File.put_line` | 301 |
| `Fnd_File.put_line` | 304 |
| `FND_PROFILE.VALUE` | 398 |
| `FND_PROFILE.VALUE` | 400 |
| `FND_PROFILE.VALUE` | 401 |
| `Fnd_File.put_line` | 405 |
| `Fnd_File.put_line` | 410 |
| `Dka_Tools_Pkg.put_debug_message` | 421 |
| `Fnd_File.put_line` | 425 |
| `FND_PROFILE.VALUE` | 516 |
| `FND_PROFILE.VALUE` | 518 |
| `FND_PROFILE.VALUE` | 519 |
| `Fnd_File.put_line` | 524 |
| `Fnd_File.put_line` | 529 |
| `Dka_Tools_Pkg.put_debug_message` | 539 |
| `Fnd_File.put_line` | 543 |
| `Dka_Tools_Pkg.put_debug_message` | 587 |
| `Dka_Tools_Pkg.put_debug_message` | 594 |
| `Dka_Tools_Pkg.put_debug_message` | 623 |
| `Dka_Tools_Pkg.put_debug_message` | 641 |
| `Fnd_File.put_line` | 655 |
| `Fnd_File.put_line` | 656 |
| `Dka_Tools_Pkg.put_debug_message` | 673 |
| `Fnd_File.put_line` | 674 |
| `Dka_Tools_Pkg.put_debug_message` | 676 |
| `Dka_Tools_Pkg.put_debug_message` | 685 |
| `Fnd_File.put_line` | 686 |
| `Dka_Tools_Pkg.put_debug_message` | 687 |
| `Fnd_File.put_line` | 691 |
| `Dka_Tools_Pkg.put_debug_message` | 698 |
| `Fnd_File.put_line` | 702 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 670 |
| rollback | 2 |
| when_others | 125, 165, 418, 536, 695 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPAAUTCRE / DKA | `DKA_SPAAUTCRE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPAAUTCRE.ldt:473 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
