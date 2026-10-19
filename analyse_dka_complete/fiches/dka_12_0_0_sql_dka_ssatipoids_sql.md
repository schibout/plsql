# DKA_SSATIPOIDS.sql

Source : [dka/12.0.0/sql/DKA_SSATIPOIDS.sql](../../dka/12.0.0/sql/DKA_SSATIPOIDS.sql).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 373 ; encodage : cp1252 (repli). SHA-256 : `9d0e1f52afed6d1ae4685a4cc321711a9e630f221f0d33fa640d4322e072e74f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 72 |
| `fnd_user` | 77 |
| `fnd_concurrent_programs` | 92 |
| `DUAL` | 371 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 98 |
| `fnd_profile.value` | 182 |
| `dka_tools_pkg.get_request_set_params` | 186 |
| `fnd_request.submit_request` | 216 |
| `dka_tools_pkg.tab_request_params` | 222 |
| `dka_tools_pkg.tab_request_params` | 223 |
| `dka_tools_pkg.tab_request_params` | 224 |
| `dka_tools_pkg.tab_request_params` | 225 |
| `dka_tools_pkg.tab_request_params` | 226 |
| `dka_tools_pkg.tab_request_params` | 227 |
| `dka_tools_pkg.tab_request_params` | 228 |
| `dka_tools_pkg.tab_request_params` | 229 |
| `dka_tools_pkg.tab_request_params` | 230 |
| `dka_tools_pkg.tab_request_params` | 231 |
| `dka_tools_pkg.tab_request_params` | 232 |
| `dka_tools_pkg.tab_request_params` | 233 |
| `dka_tools_pkg.tab_request_params` | 234 |
| `dka_tools_pkg.tab_request_params` | 235 |
| `dka_tools_pkg.tab_request_params` | 236 |
| `dka_tools_pkg.tab_request_params` | 237 |
| `dka_tools_pkg.tab_request_params` | 238 |
| `dka_tools_pkg.tab_request_params` | 239 |
| `dka_tools_pkg.tab_request_params` | 240 |
| `dka_tools_pkg.tab_request_params` | 241 |
| `dka_tools_pkg.tab_request_params` | 242 |
| `dka_tools_pkg.tab_request_params` | 243 |
| `dka_tools_pkg.tab_request_params` | 244 |
| `dka_tools_pkg.tab_request_params` | 245 |
| `dka_tools_pkg.tab_request_params` | 246 |
| `dka_tools_pkg.tab_request_params` | 247 |
| `dka_tools_pkg.tab_request_params` | 248 |
| `dka_tools_pkg.tab_request_params` | 249 |
| `dka_tools_pkg.tab_request_params` | 250 |
| `dka_tools_pkg.tab_request_params` | 251 |
| `dka_tools_pkg.tab_request_params` | 252 |
| `dka_tools_pkg.tab_request_params` | 253 |
| `dka_tools_pkg.tab_request_params` | 254 |
| `dka_tools_pkg.tab_request_params` | 255 |
| `dka_tools_pkg.tab_request_params` | 256 |
| `dka_tools_pkg.tab_request_params` | 257 |
| `dka_tools_pkg.tab_request_params` | 258 |
| `dka_tools_pkg.tab_request_params` | 259 |
| `dka_tools_pkg.tab_request_params` | 260 |
| `dka_tools_pkg.tab_request_params` | 261 |
| `dka_tools_pkg.tab_request_params` | 262 |
| `dka_tools_pkg.tab_request_params` | 263 |
| `dka_tools_pkg.tab_request_params` | 264 |
| `dka_tools_pkg.tab_request_params` | 265 |
| `dka_tools_pkg.tab_request_params` | 266 |
| `dka_tools_pkg.tab_request_params` | 267 |
| `dka_tools_pkg.tab_request_params` | 268 |
| `dka_tools_pkg.tab_request_params` | 269 |
| `dka_tools_pkg.tab_request_params` | 270 |
| `dka_tools_pkg.tab_request_params` | 271 |
| `dka_tools_pkg.tab_request_params` | 272 |
| `dka_tools_pkg.tab_request_params` | 273 |
| `dka_tools_pkg.tab_request_params` | 274 |
| `dka_tools_pkg.tab_request_params` | 275 |
| `dka_tools_pkg.tab_request_params` | 276 |
| `dka_tools_pkg.tab_request_params` | 277 |
| `dka_tools_pkg.tab_request_params` | 278 |
| `dka_tools_pkg.tab_request_params` | 279 |
| `dka_tools_pkg.tab_request_params` | 280 |
| `dka_tools_pkg.tab_request_params` | 281 |
| `dka_tools_pkg.tab_request_params` | 282 |
| `dka_tools_pkg.tab_request_params` | 283 |
| `dka_tools_pkg.tab_request_params` | 284 |
| `dka_tools_pkg.tab_request_params` | 285 |
| `dka_tools_pkg.tab_request_params` | 286 |
| `dka_tools_pkg.tab_request_params` | 287 |
| `dka_tools_pkg.tab_request_params` | 288 |
| `dka_tools_pkg.tab_request_params` | 289 |
| `dka_tools_pkg.tab_request_params` | 290 |
| `dka_tools_pkg.tab_request_params` | 291 |
| `dka_tools_pkg.tab_request_params` | 292 |
| `dka_tools_pkg.tab_request_params` | 293 |
| `dka_tools_pkg.tab_request_params` | 294 |
| `dka_tools_pkg.tab_request_params` | 295 |
| `dka_tools_pkg.tab_request_params` | 296 |
| `dka_tools_pkg.tab_request_params` | 297 |
| `dka_tools_pkg.tab_request_params` | 298 |
| `dka_tools_pkg.tab_request_params` | 299 |
| `dka_tools_pkg.tab_request_params` | 300 |
| `dka_tools_pkg.tab_request_params` | 301 |
| `dka_tools_pkg.tab_request_params` | 302 |
| `dka_tools_pkg.tab_request_params` | 303 |
| `dka_tools_pkg.tab_request_params` | 304 |
| `dka_tools_pkg.tab_request_params` | 305 |
| `dka_tools_pkg.tab_request_params` | 306 |
| `dka_tools_pkg.tab_request_params` | 307 |
| `dka_tools_pkg.tab_request_params` | 308 |
| `dka_tools_pkg.tab_request_params` | 309 |
| `dka_tools_pkg.tab_request_params` | 310 |
| `dka_tools_pkg.tab_request_params` | 311 |
| `dka_tools_pkg.tab_request_params` | 312 |
| `dka_tools_pkg.tab_request_params` | 313 |
| `dka_tools_pkg.tab_request_params` | 314 |
| `dka_tools_pkg.tab_request_params` | 315 |
| `dka_tools_pkg.tab_request_params` | 316 |
| `dka_tools_pkg.tab_request_params` | 317 |
| `dka_tools_pkg.tab_request_params` | 318 |
| `dka_tools_pkg.tab_request_params` | 319 |
| `dka_tools_pkg.tab_request_params` | 320 |
| `dka_tools_pkg.tab_request_params` | 321 |
| `fnd_concurrent.wait_for_request` | 339 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 326 |
| when_others | 362 |
| soumission | 216 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SSATIPOIDS_RDF / DKA | `DKA_SSATIPOIDS` | dka/12.0.0/admin/import/DKA_SSATIPOIDS_RDF.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
