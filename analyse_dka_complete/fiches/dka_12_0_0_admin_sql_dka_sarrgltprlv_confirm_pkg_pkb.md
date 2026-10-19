# DKA_SARRGLTPRLV_CONFIRM_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CONFIRM_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CONFIRM_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 394 ; encodage : cp1252 (repli). SHA-256 : `63cac5d6ef126540252b2637e5f46d387bd918a4a45fe890acb179eff256d953`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 58 |
| `launch_prog_confirm` | 82 |
| `main` | 219 |
| `main` | 385 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ar_batches_all` | 234 |
| `ar_cash_receipts_all` | 246 |
| `AR_BATCHES_ALL` | 270 |
| `HZ_CUST_SITE_USES_ALL` | 334 |
| `ar_cash_receipts_all` | 349 |
| `AR_PAYMENT_SCHEDULES_ALL` | 359 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 63 |
| `FND_FILE.PUT_LINE` | 64 |
| `Fnd_File.put_line` | 70 |
| `Fnd_File.put_line` | 72 |
| `Fnd_File.put_line` | 73 |
| `Fnd_File.put_line` | 74 |
| `Fnd_File.put_line` | 75 |
| `Fnd_File.put_line` | 76 |
| `Fnd_File.put_line` | 94 |
| `Fnd_File.put_line` | 97 |
| `FND_REQUEST.submit_request` | 98 |
| `Fnd_File.put_line` | 160 |
| `Fnd_File.put_line` | 162 |
| `Fnd_File.put_line` | 163 |
| `Fnd_File.put_line` | 164 |
| `Fnd_File.put_line` | 165 |
| `Fnd_File.put_line` | 166 |
| `Fnd_File.put_line` | 167 |
| `Fnd_File.put_line` | 172 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 175 |
| `Fnd_File.put_line` | 176 |
| `Fnd_File.put_line` | 177 |
| `Fnd_File.put_line` | 178 |
| `Fnd_File.put_line` | 179 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 186 |
| `Fnd_File.put_line` | 187 |
| `Fnd_File.put_line` | 188 |
| `Fnd_File.put_line` | 189 |
| `Fnd_File.put_line` | 190 |
| `Fnd_File.put_line` | 191 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 198 |
| `Fnd_File.put_line` | 199 |
| `Fnd_File.put_line` | 200 |
| `Fnd_File.put_line` | 201 |
| `Fnd_File.put_line` | 202 |
| `Fnd_File.put_line` | 203 |
| `Fnd_File.put_line` | 260 |
| `Fnd_File.put_line` | 263 |
| `Fnd_File.put_line` | 280 |
| `Fnd_Concurrent.wait_for_request` | 296 |
| `Fnd_File.put_line` | 348 |
| `Fnd_File.put_line` | 378 |
| `Fnd_File.put_line` | 385 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 150 |
| when_others | 67, 193, 338, 384 |
| soumission | 98 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_ARCONFIRMLOT / DKA | `DKA_SARRGLTPRLV_CONFIRM_PKG.main` | dka/12.0.0/admin/import/DKA_ARCONFIRMLOT_PRG.ldt:529 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
