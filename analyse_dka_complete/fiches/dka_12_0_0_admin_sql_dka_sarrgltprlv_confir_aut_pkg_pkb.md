# DKA_SARRGLTPRLV_CONFIR_AUT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CONFIR_AUT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CONFIR_AUT_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 387 ; encodage : cp1252 (repli). SHA-256 : `77e7b3573628d28fdf652ae5da8c279da690344a587c5ce6f1a2f2be5bddb466`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 61 |
| `launch_prog_confirmation` | 85 |
| `main` | 226 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ar_batches_all` | 266 |
| `fnd_responsibility_tl` | 307 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 67 |
| `Fnd_File.put_line` | 73 |
| `Fnd_File.put_line` | 75 |
| `Fnd_File.put_line` | 76 |
| `Fnd_File.put_line` | 77 |
| `Fnd_File.put_line` | 78 |
| `Fnd_File.put_line` | 79 |
| `Fnd_File.put_line` | 107 |
| `Fnd_File.put_line` | 110 |
| `FND_REQUEST.submit_request` | 111 |
| `Fnd_File.put_line` | 166 |
| `Fnd_File.put_line` | 168 |
| `Fnd_File.put_line` | 169 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 172 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 178 |
| `Fnd_File.put_line` | 180 |
| `Fnd_File.put_line` | 181 |
| `Fnd_File.put_line` | 182 |
| `Fnd_File.put_line` | 183 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 185 |
| `Fnd_File.put_line` | 190 |
| `Fnd_File.put_line` | 192 |
| `Fnd_File.put_line` | 193 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 198 |
| `Fnd_File.put_line` | 203 |
| `Fnd_File.put_line` | 205 |
| `Fnd_File.put_line` | 206 |
| `Fnd_File.put_line` | 207 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 209 |
| `Fnd_File.put_line` | 210 |
| `Fnd_File.put_line` | 301 |
| `Fnd_File.put_line` | 302 |
| `fnd_profile.value` | 314 |
| `Fnd_File.put_line` | 315 |
| `Fnd_File.put_line` | 316 |
| `fnd_global.apps_initialize` | 319 |
| `Fnd_File.put_line` | 324 |
| `Fnd_Concurrent.wait_for_request` | 341 |
| `Fnd_File.put_line` | 373 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 121 |
| when_others | 70, 200, 293, 378 |
| soumission | 111 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARRGLTPRLV_CONFIRM_AUT / DKA | `DKA_SARRGLTPRLV_CONFIR_AUT_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_CONFIRM_AUT_PRG.ldt:455 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
