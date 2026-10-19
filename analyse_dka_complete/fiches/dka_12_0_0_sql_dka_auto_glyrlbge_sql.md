# DKA_AUTO_GLYRLBGE.sql

Source : [dka/12.0.0/sql/DKA_AUTO_GLYRLBGE.sql](../../dka/12.0.0/sql/DKA_AUTO_GLYRLBGE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 762 ; encodage : cp1252 (repli). SHA-256 : `f534828a270c93b8bdb955b5abb3d433dbc0b5c928435883284740f906ab30e7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 139 |
| `soumission_traitement` | 218 |
| `verif_period_GL` | 343 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 153 |
| `fnd_responsibility` | 172 |
| `fnd_concurrent_programs` | 191 |
| `gl_period_statuses` | 351 |
| `dka_auto_etat` | 408 |
| `fnd_profile_options_vl` | 466 |
| `dka_auto_etat` | 731 |
| `DUAL` | 752 |
| `DUAL` | 754 |
| `DUAL` | 761 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 206 |
| `Fnd_Profile.value` | 209 |
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
| `Fnd_Profile.VALUE` | 369 |
| `Dka_Tools_Pkg.get_parameter` | 436 |
| `Dka_Tools_Pkg.get_parameter` | 443 |
| `Dka_Tools_Pkg.get_request_set_params` | 553 |
| `Dka_Tools_Pkg.tab_request_params` | 572 |
| `Dka_Tools_Pkg.tab_request_params` | 573 |
| `Dka_Tools_Pkg.tab_request_params` | 574 |
| `Dka_Tools_Pkg.tab_request_params` | 575 |
| `Dka_Tools_Pkg.tab_request_params` | 576 |
| `Dka_Tools_Pkg.tab_request_params` | 577 |
| `Dka_Tools_Pkg.tab_request_params` | 578 |
| `Dka_Tools_Pkg.tab_request_params` | 580 |
| `Dka_Tools_Pkg.tab_request_params` | 581 |
| `Dka_Tools_Pkg.tab_request_params` | 582 |
| `Dka_Tools_Pkg.tab_request_params` | 583 |
| `Dka_Tools_Pkg.tab_request_params` | 584 |
| `Dka_Tools_Pkg.tab_request_params` | 585 |
| `Dka_Tools_Pkg.tab_request_params` | 586 |
| `Dka_Tools_Pkg.tab_request_params` | 601 |
| `Dka_Tools_Pkg.tab_request_params` | 609 |
| `Dka_Tools_Pkg.tab_request_params` | 619 |
| `Dka_Tools_Pkg.tab_request_params` | 628 |
| `Dka_Tools_Pkg.tab_request_params` | 634 |
| `Dka_Tools_Pkg.tab_request_params` | 648 |
| `Dka_Tools_Pkg.tab_request_params` | 649 |
| `Dka_Tools_Pkg.tab_request_params` | 650 |
| `Dka_Tools_Pkg.tab_request_params` | 651 |
| `Dka_Tools_Pkg.tab_request_params` | 652 |
| `Dka_Tools_Pkg.tab_request_params` | 653 |
| `Dka_Tools_Pkg.tab_request_params` | 654 |
| `Dka_Tools_Pkg.tab_request_params` | 657 |
| `Dka_Tools_Pkg.tab_request_params` | 658 |
| `Dka_Tools_Pkg.tab_request_params` | 659 |
| `Dka_Tools_Pkg.tab_request_params` | 660 |
| `Dka_Tools_Pkg.tab_request_params` | 661 |
| `Dka_Tools_Pkg.tab_request_params` | 662 |
| `Dka_Tools_Pkg.tab_request_params` | 663 |
| `Fnd_Concurrent.wait_for_request` | 687 |
| `Fnd_Profile.VALUE` | 736 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_GLYRLBGE_BOR.sh` | 757 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 331, 740 |
| when_others | 157, 176, 197, 358, 424, 744 |
| soumission | 220 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_GLYRLBGE / DKA | `DKA_AUTO_GLYRLBGE` | dka/12.0.0/admin/import/DKA_AUTO_GLYRLBGE.prt:523 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
