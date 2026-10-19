# DKA_AUTO_JEFRDVER01.sql

Source : [dka/12.0.0/sql/DKA_AUTO_JEFRDVER01.sql](../../dka/12.0.0/sql/DKA_AUTO_JEFRDVER01.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 765 ; encodage : cp1252 (repli). SHA-256 : `abdca820e64412e1806e51060c9f9007be457ece366d4b1b49474dff0d41d23f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `display_msg` | 127 |
| `positionnement_contexte` | 136 |
| `soumission_traitement` | 257 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `XLE_ENTITY_PROFILES` | 114 |
| `hr_operating_units` | 115 |
| `fnd_user` | 149 |
| `fnd_responsibility` | 169 |
| `fnd_concurrent_programs` | 193 |
| `fnd_concurrent_programs` | 209 |
| `dka_auto_etat` | 423 |
| `dual` | 510 |
| `fnd_responsibility` | 547 |
| `fnd_concurrent_programs` | 665 |
| `fnd_concurrent_request_class` | 668 |
| `dka_auto_etat` | 710 |
| `fnd_concurrent_programs` | 750 |
| `fnd_concurrent_request_class` | 753 |
| `DUAL` | 764 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 130 |
| `fnd_global.INITIALIZE` | 229 |
| `Fnd_Profile.value` | 248 |
| `Fnd_Request.submit_request` | 259 |
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
| `Dka_Tools_Pkg.tab_request_params` | 325 |
| `Dka_Tools_Pkg.tab_request_params` | 326 |
| `Dka_Tools_Pkg.tab_request_params` | 327 |
| `Dka_Tools_Pkg.tab_request_params` | 328 |
| `Dka_Tools_Pkg.tab_request_params` | 329 |
| `Dka_Tools_Pkg.tab_request_params` | 330 |
| `Dka_Tools_Pkg.tab_request_params` | 331 |
| `Dka_Tools_Pkg.tab_request_params` | 332 |
| `Dka_Tools_Pkg.tab_request_params` | 333 |
| `Dka_Tools_Pkg.tab_request_params` | 334 |
| `Dka_Tools_Pkg.tab_request_params` | 335 |
| `Dka_Tools_Pkg.tab_request_params` | 336 |
| `Dka_Tools_Pkg.tab_request_params` | 337 |
| `Dka_Tools_Pkg.tab_request_params` | 338 |
| `Dka_Tools_Pkg.tab_request_params` | 339 |
| `Dka_Tools_Pkg.tab_request_params` | 340 |
| `Dka_Tools_Pkg.tab_request_params` | 341 |
| `Dka_Tools_Pkg.tab_request_params` | 342 |
| `Dka_Tools_Pkg.tab_request_params` | 343 |
| `Dka_Tools_Pkg.tab_request_params` | 344 |
| `Dka_Tools_Pkg.tab_request_params` | 345 |
| `Dka_Tools_Pkg.tab_request_params` | 346 |
| `Dka_Tools_Pkg.tab_request_params` | 347 |
| `Dka_Tools_Pkg.tab_request_params` | 348 |
| `Dka_Tools_Pkg.tab_request_params` | 349 |
| `Dka_Tools_Pkg.tab_request_params` | 350 |
| `Dka_Tools_Pkg.tab_request_params` | 351 |
| `Dka_Tools_Pkg.tab_request_params` | 352 |
| `Dka_Tools_Pkg.tab_request_params` | 353 |
| `Dka_Tools_Pkg.tab_request_params` | 354 |
| `Dka_Tools_Pkg.tab_request_params` | 355 |
| `Dka_Tools_Pkg.tab_request_params` | 356 |
| `Dka_Tools_Pkg.tab_request_params` | 357 |
| `Dka_Tools_Pkg.tab_request_params` | 358 |
| `Dka_Tools_Pkg.tab_request_params` | 359 |
| `Dka_Tools_Pkg.tab_request_params` | 360 |
| `Dka_Tools_Pkg.tab_request_params` | 361 |
| `Dka_Tools_Pkg.tab_request_params` | 362 |
| `Dka_Tools_Pkg.tab_request_params` | 363 |
| `Fnd_Profile.VALUE` | 402 |
| `Dka_Tools_Pkg.get_parameter` | 454 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 459 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 518 |
| `Fnd_Request.set_org_id` | 570 |
| `FND_REQUEST.SET_OPTIONS` | 572 |
| `Dka_Tools_Pkg.get_request_set_params` | 579 |
| `Dka_Tools_Pkg.tab_request_params` | 629 |
| `Dka_Tools_Pkg.tab_request_params` | 630 |
| `Dka_Tools_Pkg.tab_request_params` | 631 |
| `Dka_Tools_Pkg.tab_request_params` | 632 |
| `Dka_Tools_Pkg.tab_request_params` | 634 |
| `Dka_Tools_Pkg.tab_request_params` | 635 |
| `Dka_Tools_Pkg.tab_request_params` | 645 |
| `Dka_Tools_Pkg.tab_request_params` | 646 |
| `Dka_Tools_Pkg.tab_request_params` | 648 |
| `Dka_Tools_Pkg.tab_request_params` | 649 |
| `Dka_Tools_Pkg.tab_request_params` | 650 |
| `Fnd_Concurrent.wait_for_request` | 681 |
| `Fnd_Profile.VALUE` | 715 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 726 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 730 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 733 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 744 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 214, 371, 672, 719, 757 |
| when_others | 153, 173, 199, 217, 441, 513, 737 |
| soumission | 259 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_JEFRDVER01 / DKA | `DKA_AUTO_JEFRDVER01` | dka/12.0.0/admin/import/DKA_AUTO_JEFRDVER01.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
