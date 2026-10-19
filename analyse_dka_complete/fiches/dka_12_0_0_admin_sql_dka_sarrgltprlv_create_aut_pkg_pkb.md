# DKA_SARRGLTPRLV_CREATE_AUT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CREATE_AUT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_CREATE_AUT_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 382 ; encodage : cp1252 (repli). SHA-256 : `6265ecb931a4f489fe033ca876b0a2e4267ddc42a914e82ba429c82ff58c3b36`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 61 |
| `launch_prog_creation` | 85 |
| `main` | 229 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hz_cust_accounts` | 238 |
| `DKA_ARLOTREG_TMP` | 289 |
| `fnd_responsibility_tl` | 302 |

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
| `Fnd_File.put_line` | 169 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 172 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 175 |
| `Fnd_File.put_line` | 176 |
| `Fnd_File.put_line` | 181 |
| `Fnd_File.put_line` | 183 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 185 |
| `Fnd_File.put_line` | 186 |
| `Fnd_File.put_line` | 187 |
| `Fnd_File.put_line` | 188 |
| `Fnd_File.put_line` | 193 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 197 |
| `Fnd_File.put_line` | 198 |
| `Fnd_File.put_line` | 199 |
| `Fnd_File.put_line` | 201 |
| `Fnd_File.put_line` | 206 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 209 |
| `Fnd_File.put_line` | 210 |
| `Fnd_File.put_line` | 211 |
| `Fnd_File.put_line` | 212 |
| `Fnd_File.put_line` | 213 |
| `Fnd_File.put_line` | 286 |
| `Fnd_File.put_line` | 296 |
| `Fnd_File.put_line` | 297 |
| `fnd_profile.value` | 309 |
| `Fnd_File.put_line` | 310 |
| `Fnd_File.put_line` | 311 |
| `fnd_global.apps_initialize` | 314 |
| `Fnd_File.put_line` | 319 |
| `Fnd_Concurrent.wait_for_request` | 336 |
| `Fnd_File.put_line` | 368 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 122, 290 |
| when_others | 70, 203, 282, 373 |
| suppression | 289 |
| soumission | 111 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARRGLTPRLV_CREATE_AUT / DKA | `DKA_SARRGLTPRLV_CREATE_AUT_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_CREATE_AUT_PRG.ldt:455 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
