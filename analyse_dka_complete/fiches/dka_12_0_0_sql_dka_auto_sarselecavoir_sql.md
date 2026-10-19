# DKA_AUTO_SARSELECAVOIR.sql

Source : [dka/12.0.0/sql/DKA_AUTO_SARSELECAVOIR.sql](../../dka/12.0.0/sql/DKA_AUTO_SARSELECAVOIR.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 461 ; encodage : cp1252 (repli). SHA-256 : `5df0188e6674f18ca5ad9955ca8bfeacd5e26beabc0c77c76784035483f7e411`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 82 |
| `soumission_traitement` | 177 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 74 |
| `fnd_user` | 94 |
| `fnd_responsibility` | 113 |
| `fnd_concurrent_programs` | 132 |
| `fnd_concurrent_requests` | 296 |
| `DUAL` | 455 |
| `DUAL` | 460 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.INITIALIZE` | 147 |
| `Fnd_Request.submit_request` | 180 |
| `Dka_Tools_Pkg.tab_request_params` | 186 |
| `Dka_Tools_Pkg.tab_request_params` | 187 |
| `Dka_Tools_Pkg.tab_request_params` | 188 |
| `Dka_Tools_Pkg.tab_request_params` | 189 |
| `Dka_Tools_Pkg.tab_request_params` | 190 |
| `Dka_Tools_Pkg.tab_request_params` | 191 |
| `Dka_Tools_Pkg.tab_request_params` | 192 |
| `Dka_Tools_Pkg.tab_request_params` | 193 |
| `Dka_Tools_Pkg.tab_request_params` | 194 |
| `Dka_Tools_Pkg.tab_request_params` | 195 |
| `Dka_Tools_Pkg.tab_request_params` | 196 |
| `Dka_Tools_Pkg.tab_request_params` | 197 |
| `Dka_Tools_Pkg.tab_request_params` | 198 |
| `Dka_Tools_Pkg.tab_request_params` | 199 |
| `Dka_Tools_Pkg.tab_request_params` | 200 |
| `Dka_Tools_Pkg.tab_request_params` | 201 |
| `Dka_Tools_Pkg.tab_request_params` | 202 |
| `Dka_Tools_Pkg.tab_request_params` | 203 |
| `Dka_Tools_Pkg.tab_request_params` | 204 |
| `Dka_Tools_Pkg.tab_request_params` | 205 |
| `Dka_Tools_Pkg.tab_request_params` | 206 |
| `Dka_Tools_Pkg.tab_request_params` | 207 |
| `Dka_Tools_Pkg.tab_request_params` | 208 |
| `Dka_Tools_Pkg.tab_request_params` | 209 |
| `Dka_Tools_Pkg.tab_request_params` | 210 |
| `Dka_Tools_Pkg.tab_request_params` | 211 |
| `Dka_Tools_Pkg.tab_request_params` | 212 |
| `Dka_Tools_Pkg.tab_request_params` | 213 |
| `Dka_Tools_Pkg.tab_request_params` | 214 |
| `Dka_Tools_Pkg.tab_request_params` | 215 |
| `Dka_Tools_Pkg.tab_request_params` | 216 |
| `Dka_Tools_Pkg.tab_request_params` | 217 |
| `Dka_Tools_Pkg.tab_request_params` | 218 |
| `Dka_Tools_Pkg.tab_request_params` | 219 |
| `Dka_Tools_Pkg.tab_request_params` | 220 |
| `Dka_Tools_Pkg.tab_request_params` | 221 |
| `Dka_Tools_Pkg.tab_request_params` | 222 |
| `Dka_Tools_Pkg.tab_request_params` | 223 |
| `Dka_Tools_Pkg.tab_request_params` | 224 |
| `Dka_Tools_Pkg.tab_request_params` | 225 |
| `Dka_Tools_Pkg.tab_request_params` | 226 |
| `Dka_Tools_Pkg.tab_request_params` | 227 |
| `Dka_Tools_Pkg.tab_request_params` | 228 |
| `Dka_Tools_Pkg.tab_request_params` | 229 |
| `Dka_Tools_Pkg.tab_request_params` | 230 |
| `Dka_Tools_Pkg.tab_request_params` | 231 |
| `Dka_Tools_Pkg.tab_request_params` | 232 |
| `Dka_Tools_Pkg.tab_request_params` | 233 |
| `Dka_Tools_Pkg.tab_request_params` | 234 |
| `Dka_Tools_Pkg.tab_request_params` | 235 |
| `Dka_Tools_Pkg.tab_request_params` | 236 |
| `Dka_Tools_Pkg.tab_request_params` | 237 |
| `Dka_Tools_Pkg.tab_request_params` | 238 |
| `Dka_Tools_Pkg.tab_request_params` | 239 |
| `Dka_Tools_Pkg.tab_request_params` | 240 |
| `Dka_Tools_Pkg.tab_request_params` | 241 |
| `Dka_Tools_Pkg.tab_request_params` | 242 |
| `Dka_Tools_Pkg.tab_request_params` | 243 |
| `Dka_Tools_Pkg.tab_request_params` | 244 |
| `Dka_Tools_Pkg.tab_request_params` | 245 |
| `Dka_Tools_Pkg.tab_request_params` | 246 |
| `Dka_Tools_Pkg.tab_request_params` | 247 |
| `Dka_Tools_Pkg.tab_request_params` | 248 |
| `Dka_Tools_Pkg.tab_request_params` | 249 |
| `Dka_Tools_Pkg.tab_request_params` | 250 |
| `Dka_Tools_Pkg.tab_request_params` | 251 |
| `Dka_Tools_Pkg.tab_request_params` | 252 |
| `Dka_Tools_Pkg.tab_request_params` | 253 |
| `Dka_Tools_Pkg.tab_request_params` | 254 |
| `Dka_Tools_Pkg.tab_request_params` | 255 |
| `Dka_Tools_Pkg.tab_request_params` | 256 |
| `Dka_Tools_Pkg.tab_request_params` | 257 |
| `Dka_Tools_Pkg.tab_request_params` | 258 |
| `Dka_Tools_Pkg.tab_request_params` | 259 |
| `Dka_Tools_Pkg.tab_request_params` | 260 |
| `Dka_Tools_Pkg.tab_request_params` | 261 |
| `Dka_Tools_Pkg.tab_request_params` | 262 |
| `Dka_Tools_Pkg.tab_request_params` | 263 |
| `Dka_Tools_Pkg.tab_request_params` | 264 |
| `Dka_Tools_Pkg.tab_request_params` | 265 |
| `Dka_Tools_Pkg.tab_request_params` | 266 |
| `Dka_Tools_Pkg.tab_request_params` | 267 |
| `Dka_Tools_Pkg.tab_request_params` | 268 |
| `Dka_Tools_Pkg.tab_request_params` | 269 |
| `Dka_Tools_Pkg.tab_request_params` | 270 |
| `Dka_Tools_Pkg.tab_request_params` | 271 |
| `Dka_Tools_Pkg.tab_request_params` | 272 |
| `Dka_Tools_Pkg.tab_request_params` | 273 |
| `Dka_Tools_Pkg.tab_request_params` | 274 |
| `Dka_Tools_Pkg.tab_request_params` | 275 |
| `Dka_Tools_Pkg.tab_request_params` | 276 |
| `Dka_Tools_Pkg.tab_request_params` | 277 |
| `Dka_Tools_Pkg.tab_request_params` | 278 |
| `Dka_Tools_Pkg.tab_request_params` | 279 |
| `Dka_Tools_Pkg.tab_request_params` | 280 |
| `Dka_Tools_Pkg.tab_request_params` | 281 |
| `Dka_Tools_Pkg.tab_request_params` | 282 |
| `Dka_Tools_Pkg.tab_request_params` | 283 |
| `Dka_Tools_Pkg.tab_request_params` | 284 |
| `Dka_Tools_Pkg.tab_request_params` | 285 |
| `Fnd_Profile.VALUE` | 309 |
| `Dka_Tools_Pkg.get_request_set_params` | 363 |
| `Dka_Tools_Pkg.tab_request_params` | 381 |
| `Dka_Tools_Pkg.tab_request_params` | 390 |
| `Fnd_Concurrent.wait_for_request` | 405 |
| `Fnd_File.put_line` | 438 |
| `Fnd_File.put_line` | 439 |
| `Fnd_File.put_line` | 440 |
| `Fnd_File.put_line` | 441 |
| `Fnd_File.put_line` | 442 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 289, 299 |
| when_others | 98, 117, 138, 447 |
| soumission | 180 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_SARSELECAVOIR / DKA | `DKA_AUTO_SARSELECAVOIR` | dka/12.0.0/admin/import/DKA_AUTO_SARSELECAVOIR.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
