# DKA_SGLCTRLFLUXIFRS.sql

Source : [dka/12.0.0/sql/DKA_SGLCTRLFLUXIFRS.sql](../../dka/12.0.0/sql/DKA_SGLCTRLFLUXIFRS.sql).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 423 ; encodage : cp1252 (repli). SHA-256 : `3f5c74512094818030ba7697942be30bf69f6045aeab43b386442fcd3a0b16a8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_conso_code_v` | 73 |
| `GL_LEDGERS` | 76 |
| `gl_period_statuses` | 87 |
| `GL_access_set_assignments` | 89 |
| `gl_period_statuses` | 92 |
| `fnd_responsibility` | 106 |
| `fnd_concurrent_programs` | 117 |
| `fnd_user` | 147 |
| `dka_ieoglvec01_conso_code_v` | 168 |
| `fnd_flex_value_sets` | 189 |
| `fnd_user` | 219 |
| `DUAL` | 422 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.value` | 79 |
| `fnd_profile.value` | 89 |
| `dka_tools_pkg.get_request_set_params` | 124 |
| `fnd_global.apps_initialize` | 151 |
| `dka_tools_pkg.tab_request_params` | 156 |
| `fnd_global.apps_initialize` | 224 |
| `dka_tools_pkg.tab_request_params` | 228 |
| `fnd_request.submit_request` | 231 |
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
| `dka_tools_pkg.tab_request_params` | 322 |
| `dka_tools_pkg.tab_request_params` | 323 |
| `dka_tools_pkg.tab_request_params` | 324 |
| `dka_tools_pkg.tab_request_params` | 325 |
| `dka_tools_pkg.tab_request_params` | 326 |
| `dka_tools_pkg.tab_request_params` | 327 |
| `dka_tools_pkg.tab_request_params` | 328 |
| `dka_tools_pkg.tab_request_params` | 329 |
| `dka_tools_pkg.tab_request_params` | 330 |
| `dka_tools_pkg.tab_request_params` | 331 |
| `dka_tools_pkg.tab_request_params` | 332 |
| `dka_tools_pkg.tab_request_params` | 333 |
| `dka_tools_pkg.tab_request_params` | 334 |
| `dka_tools_pkg.tab_request_params` | 335 |
| `dka_tools_pkg.tab_request_params` | 336 |
| `fnd_concurrent.wait_for_request` | 365 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 343 |
| when_others | 172, 202, 414 |
| soumission | 231 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
