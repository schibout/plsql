# DKA_AUTO_RARBALCHARG.sql

Source : [dka/12.0.0/sql/DKA_AUTO_RARBALCHARG.sql](../../dka/12.0.0/sql/DKA_AUTO_RARBALCHARG.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 545 ; encodage : cp1252 (repli). SHA-256 : `bd31ef1b9ada447c2d0b738b0f01c4a1cdfcf3b10e97e6f184f205accec10a6a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 99 |
| `soumission_traitement` | 218 |
| `verif_date` | 341 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 112 |
| `fnd_responsibility` | 132 |
| `fnd_concurrent_programs` | 156 |
| `fnd_concurrent_programs` | 172 |
| `dual` | 346 |
| `HR_OPERATING_UNITs` | 370 |
| `PER_SECURITY_ORGANIZATIONS` | 377 |
| `PER_SECURITY_PROFILES` | 380 |
| `gl_period_statuses` | 437 |
| `DUAL` | 544 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 190 |
| `Fnd_Request.submit_request` | 220 |
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
| `Dka_Tools_Pkg.tab_request_params` | 286 |
| `Dka_Tools_Pkg.tab_request_params` | 287 |
| `Dka_Tools_Pkg.tab_request_params` | 288 |
| `Dka_Tools_Pkg.tab_request_params` | 289 |
| `Dka_Tools_Pkg.tab_request_params` | 290 |
| `Dka_Tools_Pkg.tab_request_params` | 291 |
| `Dka_Tools_Pkg.tab_request_params` | 292 |
| `Dka_Tools_Pkg.tab_request_params` | 293 |
| `Dka_Tools_Pkg.tab_request_params` | 294 |
| `Dka_Tools_Pkg.tab_request_params` | 295 |
| `Dka_Tools_Pkg.tab_request_params` | 296 |
| `Dka_Tools_Pkg.tab_request_params` | 297 |
| `Dka_Tools_Pkg.tab_request_params` | 298 |
| `Dka_Tools_Pkg.tab_request_params` | 299 |
| `Dka_Tools_Pkg.tab_request_params` | 300 |
| `Dka_Tools_Pkg.tab_request_params` | 301 |
| `Dka_Tools_Pkg.tab_request_params` | 302 |
| `Dka_Tools_Pkg.tab_request_params` | 303 |
| `Dka_Tools_Pkg.tab_request_params` | 304 |
| `Dka_Tools_Pkg.tab_request_params` | 305 |
| `Dka_Tools_Pkg.tab_request_params` | 306 |
| `Dka_Tools_Pkg.tab_request_params` | 307 |
| `Dka_Tools_Pkg.tab_request_params` | 308 |
| `Dka_Tools_Pkg.tab_request_params` | 309 |
| `Dka_Tools_Pkg.tab_request_params` | 310 |
| `Dka_Tools_Pkg.tab_request_params` | 311 |
| `Dka_Tools_Pkg.tab_request_params` | 312 |
| `Dka_Tools_Pkg.tab_request_params` | 313 |
| `Dka_Tools_Pkg.tab_request_params` | 314 |
| `Dka_Tools_Pkg.tab_request_params` | 315 |
| `Dka_Tools_Pkg.tab_request_params` | 316 |
| `Dka_Tools_Pkg.tab_request_params` | 317 |
| `Dka_Tools_Pkg.tab_request_params` | 318 |
| `Dka_Tools_Pkg.tab_request_params` | 319 |
| `Dka_Tools_Pkg.tab_request_params` | 320 |
| `Dka_Tools_Pkg.tab_request_params` | 321 |
| `Dka_Tools_Pkg.tab_request_params` | 322 |
| `Dka_Tools_Pkg.tab_request_params` | 323 |
| `Dka_Tools_Pkg.tab_request_params` | 324 |
| `Fnd_Profile.VALUE` | 360 |
| `Dka_Tools_Pkg.get_request_set_params` | 421 |
| `Dka_Tools_Pkg.tab_request_params` | 442 |
| `Dka_Tools_Pkg.tab_request_params` | 443 |
| `Dka_Tools_Pkg.tab_request_params` | 444 |
| `Dka_Tools_Pkg.tab_request_params` | 445 |
| `Dka_Tools_Pkg.tab_request_params` | 446 |
| `Dka_Tools_Pkg.tab_request_params` | 447 |
| `Dka_Tools_Pkg.tab_request_params` | 448 |
| `Dka_Tools_Pkg.tab_request_params` | 449 |
| `Dka_Tools_Pkg.tab_request_params` | 450 |
| `Dka_Tools_Pkg.tab_request_params` | 451 |
| `Dka_Tools_Pkg.tab_request_params` | 452 |
| `Dka_Tools_Pkg.tab_request_params` | 453 |
| `Dka_Tools_Pkg.tab_request_params` | 454 |
| `Dka_Tools_Pkg.tab_request_params` | 455 |
| `Dka_Tools_Pkg.tab_request_params` | 456 |
| `Dka_Tools_Pkg.tab_request_params` | 457 |
| `Dka_Tools_Pkg.tab_request_params` | 458 |
| `Dka_Tools_Pkg.tab_request_params` | 459 |
| `Dka_Tools_Pkg.tab_request_params` | 460 |
| `Dka_Tools_Pkg.tab_request_params` | 461 |
| `Dka_Tools_Pkg.tab_request_params` | 462 |
| `fnd_request.add_layout` | 474 |
| `Dka_Tools_Pkg.tab_request_params` | 485 |
| `Dka_Tools_Pkg.tab_request_params` | 486 |
| `Dka_Tools_Pkg.tab_request_params` | 487 |
| `Fnd_Concurrent.wait_for_request` | 502 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 177, 329 |
| when_others | 116, 136, 162, 180, 349, 536 |
| soumission | 220 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
