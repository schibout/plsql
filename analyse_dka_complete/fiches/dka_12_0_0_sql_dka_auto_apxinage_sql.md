# DKA_AUTO_APXINAGE.sql

Source : [dka/12.0.0/sql/DKA_AUTO_APXINAGE.sql](../../dka/12.0.0/sql/DKA_AUTO_APXINAGE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 757 ; encodage : cp1252 (repli). SHA-256 : `27ce280135f24adc789d7ea802dc1af543353887f9245c61c14a66ae6fe52a13`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 108 |
| `soumission_traitement` | 223 |
| `verif_date` | 348 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 121 |
| `fnd_responsibility` | 141 |
| `fnd_concurrent_programs` | 165 |
| `fnd_concurrent_programs` | 181 |
| `dual` | 353 |
| `dka_auto_etat` | 384 |
| `HR_OPERATING_UNITs` | 450 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 455 |
| `fnd_concurrent_programs` | 658 |
| `fnd_concurrent_request_class` | 661 |
| `dka_auto_etat` | 702 |
| `fnd_concurrent_requests` | 719 |
| `fnd_concurrent_programs` | 741 |
| `fnd_concurrent_request_class` | 744 |
| `DUAL` | 756 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 199 |
| `Fnd_Request.submit_request` | 225 |
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
| `Dka_Tools_Pkg.tab_request_params` | 325 |
| `Dka_Tools_Pkg.tab_request_params` | 326 |
| `Dka_Tools_Pkg.tab_request_params` | 327 |
| `Dka_Tools_Pkg.tab_request_params` | 328 |
| `Dka_Tools_Pkg.tab_request_params` | 329 |
| `Fnd_Profile.VALUE` | 367 |
| `Dka_Tools_Pkg.get_parameter` | 412 |
| `Dka_Tools_Pkg.get_request_set_params` | 526 |
| `Dka_Tools_Pkg.tab_request_params` | 578 |
| `Dka_Tools_Pkg.tab_request_params` | 579 |
| `Dka_Tools_Pkg.tab_request_params` | 580 |
| `Dka_Tools_Pkg.tab_request_params` | 581 |
| `Dka_Tools_Pkg.tab_request_params` | 582 |
| `Dka_Tools_Pkg.tab_request_params` | 583 |
| `Dka_Tools_Pkg.tab_request_params` | 584 |
| `Dka_Tools_Pkg.tab_request_params` | 585 |
| `Dka_Tools_Pkg.tab_request_params` | 586 |
| `Dka_Tools_Pkg.tab_request_params` | 587 |
| `Dka_Tools_Pkg.tab_request_params` | 588 |
| `Dka_Tools_Pkg.tab_request_params` | 589 |
| `Dka_Tools_Pkg.tab_request_params` | 590 |
| `Dka_Tools_Pkg.tab_request_params` | 603 |
| `Dka_Tools_Pkg.tab_request_params` | 604 |
| `Dka_Tools_Pkg.tab_request_params` | 605 |
| `Dka_Tools_Pkg.tab_request_params` | 606 |
| `Dka_Tools_Pkg.tab_request_params` | 607 |
| `Dka_Tools_Pkg.tab_request_params` | 608 |
| `Dka_Tools_Pkg.tab_request_params` | 609 |
| `Dka_Tools_Pkg.tab_request_params` | 610 |
| `Dka_Tools_Pkg.tab_request_params` | 611 |
| `Dka_Tools_Pkg.tab_request_params` | 612 |
| `Dka_Tools_Pkg.tab_request_params` | 613 |
| `Dka_Tools_Pkg.tab_request_params` | 614 |
| `Dka_Tools_Pkg.tab_request_params` | 615 |
| `Dka_Tools_Pkg.tab_request_params` | 621 |
| `Dka_Tools_Pkg.tab_request_params` | 632 |
| `Dka_Tools_Pkg.tab_request_params` | 633 |
| `Dka_Tools_Pkg.tab_request_params` | 634 |
| `Dka_Tools_Pkg.tab_request_params` | 635 |
| `Dka_Tools_Pkg.tab_request_params` | 636 |
| `Dka_Tools_Pkg.tab_request_params` | 637 |
| `Dka_Tools_Pkg.tab_request_params` | 638 |
| `Dka_Tools_Pkg.tab_request_params` | 639 |
| `Dka_Tools_Pkg.tab_request_params` | 640 |
| `Dka_Tools_Pkg.tab_request_params` | 641 |
| `Dka_Tools_Pkg.tab_request_params` | 642 |
| `Dka_Tools_Pkg.tab_request_params` | 643 |
| `Dka_Tools_Pkg.tab_request_params` | 644 |
| `Fnd_Concurrent.wait_for_request` | 674 |
| `Fnd_Profile.VALUE` | 707 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 186, 336, 665, 711, 727, 748 |
| when_others | 125, 145, 171, 189, 356, 401, 733 |
| soumission | 225 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_APXINAGE / DKA | `DKA_AUTO_APXINAGE` | dka/12.0.0/admin/import/DKA_AUTO_APXINAGE.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
