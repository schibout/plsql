# DKA_SARRGLTPRLV_CREATION_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CREATION_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CREATION_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 602 ; encodage : cp1252 (repli). SHA-256 : `92946a2898edb087db081b0483202405b22ea143573f65d1b5df9d972d9632e4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 57 |
| `DKA_SORTIE_TRAITEMENT` | 83 |
| `main` | 173 |
| `de` | 576 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_ARLOTREG_TMP` | 90 |
| `DKA_ARLOTREG_TMP` | 96 |
| `DKA_ARLOTREG_TMP` | 114 |
| `DKA_ARLOTREG_TMP` | 143 |
| `hz_cust_accounts` | 195 |
| `hz_cust_accounts` | 237 |
| `hz_cust_accounts` | 278 |
| `AR_RECEIPT_METHODS` | 328 |
| `AR_RECEIPT_METHODS` | 358 |
| `AR_RECEIPT_CLASSES` | 368 |
| `HR_OPERATING_UNITS` | 380 |
| `AR_BATCHES_ALL` | 394 |
| `DKA_ARLOTREG_TMP` | 430 |
| `ar_batches_all` | 540 |
| `DKA_ARLOTREG_TMP` | 564 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 62 |
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 70 |
| `Fnd_File.put_line` | 71 |
| `Fnd_File.put_line` | 72 |
| `Fnd_File.put_line` | 73 |
| `Fnd_File.put_line` | 74 |
| `FND_FILE.PUT_LINE` | 344 |
| `Fnd_File.put_line` | 389 |
| `Fnd_File.put_line` | 392 |
| `fnd_profile.value` | 413 |
| `fnd_profile.value` | 415 |
| `Fnd_File.put_line` | 451 |
| `Fnd_File.put_line` | 462 |
| `Fnd_File.put_line` | 464 |
| `Fnd_File.put_line` | 501 |
| `Fnd_Concurrent.wait_for_request` | 509 |
| `Fnd_File.put_line` | 575 |
| `FND_FILE.PUT_LINE` | 580 |
| `FND_FILE.PUT_LINE` | 585 |
| `FND_FILE.PUT_LINE` | 590 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 428, 496 |
| when_others | 65, 361, 372, 594 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_ARLOTREG / DKA | `DKA_SARRGLTPRLV_CREATION_PKG.main` | dka/12.0.0/admin/import/DKA_ARLOTREG_PRG.ldt:529 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
