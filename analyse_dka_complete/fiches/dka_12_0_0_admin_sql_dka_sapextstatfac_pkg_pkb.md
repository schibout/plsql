# DKA_SAPEXTSTATFAC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPEXTSTATFAC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPEXTSTATFAC_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 633 ; encodage : cp1252 (repli). SHA-256 : `224cc21ffcbdbd9b81d09f070820fdca4f9097b8a3c9bcf7f6d8028efd8c712c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 67 |
| `output_header` | 149 |
| `Request_parameters` | 199 |
| `output_end` | 297 |
| `create_data` | 329 |
| `Report_Bilan` | 451 |
| `main` | 516 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 112 |
| `fnd_concurrent_programs` | 161 |
| `fnd_concurrent_requests` | 203 |
| `fnd_concurrent_requests` | 234 |
| `fnd_concurrent_requests` | 256 |
| `AP_INVOICES_ALL` | 333 |
| `FND_LOOKUP_VALUES_VL` | 355 |
| `FND_LOOKUP_VALUES_VL` | 362 |
| `DKA_SAP_STATUT_FACTURE` | 373 |
| `DKA_SAP_STATUT_FACTURE` | 377 |
| `DKA_SAP_STATUT_FACTURE` | 392 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 76 |
| `fnd_profile.value` | 94 |
| `Fnd_File.put_line` | 105 |
| `Fnd_File.put_line` | 116 |
| `fnd_file.put_line` | 126 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 176 |
| `Fnd_File.put_line` | 178 |
| `Fnd_File.put_line` | 181 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 220 |
| `Fnd_File.put_line` | 221 |
| `Fnd_File.put_line` | 222 |
| `Fnd_File.put_line` | 240 |
| `Fnd_File.put_line` | 243 |
| `Fnd_File.put_line` | 262 |
| `Fnd_File.put_line` | 265 |
| `Fnd_File.put_line` | 270 |
| `Fnd_File.put_line` | 273 |
| `Fnd_File.put_line` | 274 |
| `Fnd_File.put_line` | 303 |
| `Fnd_File.put_line` | 304 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 343 |
| `ap_invoices_utility_pkg.get_approval_status` | 350 |
| `Fnd_File.put_line` | 423 |
| `Fnd_File.put_line` | 430 |
| `Fnd_File.put_line` | 431 |
| `Fnd_File.put_line` | 455 |
| `fnd_file.put_line` | 467 |
| `fnd_file.put_line` | 468 |
| `fnd_file.put_line` | 469 |
| `fnd_file.put_line` | 470 |
| `fnd_file.put_line` | 473 |
| `fnd_file.put_line` | 480 |
| `Fnd_File.put_line` | 481 |
| `Fnd_File.put_line` | 489 |
| `Fnd_File.put_line` | 490 |
| `Fnd_File.put_line` | 532 |
| `Fnd_File.put_line` | 539 |
| `Fnd_File.put_line` | 559 |
| `Fnd_File.put_line` | 595 |
| `Fnd_File.put_line` | 596 |
| `Fnd_File.put_line` | 598 |
| `Fnd_File.put_line` | 606 |
| `Fnd_File.put_line` | 607 |
| `Fnd_File.put_line` | 608 |
| `Fnd_File.put_line` | 612 |
| `Fnd_File.put_line` | 619 |
| `Fnd_File.put_line` | 623 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 421 |
| rollback | 2 |
| when_others | 128, 168, 427, 486, 616 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPEXTSTATFAC / DKA | `DKA_SAPEXTSTATFAC_PKG.main` | dka/12.0.0/admin/import/DKA_SAPEXTSTATFAC.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
