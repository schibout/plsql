# DKA_IGLHYPERIONDR.sql

Source : [dka/12.0.0/sql/DKA_IGLHYPERIONDR.sql](../../dka/12.0.0/sql/DKA_IGLHYPERIONDR.sql).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 441 ; encodage : cp1252 (repli). SHA-256 : `820bebb2955b0f41993f20e87bdc24ebf57d0836211fdc8ac3e620f1793dc67f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 64 |
| `fnd_user` | 69 |
| `fnd_concurrent_programs` | 81 |
| `fnd_concurrent_programs` | 240 |
| `DUAL` | 440 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 87 |
| `fnd_profile.value` | 89 |
| `dka_tools_pkg.get_request_set_params` | 92 |
| `fnd_request.submit_request` | 111 |
| `dka_tools_pkg.tab_request_params` | 120 |
| `dka_tools_pkg.tab_request_params` | 121 |
| `dka_tools_pkg.tab_request_params` | 122 |
| `dka_tools_pkg.tab_request_params` | 123 |
| `dka_tools_pkg.tab_request_params` | 124 |
| `dka_tools_pkg.tab_request_params` | 125 |
| `dka_tools_pkg.tab_request_params` | 126 |
| `dka_tools_pkg.tab_request_params` | 127 |
| `dka_tools_pkg.tab_request_params` | 128 |
| `dka_tools_pkg.tab_request_params` | 129 |
| `dka_tools_pkg.tab_request_params` | 130 |
| `dka_tools_pkg.tab_request_params` | 131 |
| `dka_tools_pkg.tab_request_params` | 132 |
| `dka_tools_pkg.tab_request_params` | 133 |
| `dka_tools_pkg.tab_request_params` | 134 |
| `dka_tools_pkg.tab_request_params` | 135 |
| `dka_tools_pkg.tab_request_params` | 136 |
| `dka_tools_pkg.tab_request_params` | 137 |
| `dka_tools_pkg.tab_request_params` | 138 |
| `dka_tools_pkg.tab_request_params` | 139 |
| `dka_tools_pkg.tab_request_params` | 140 |
| `dka_tools_pkg.tab_request_params` | 141 |
| `dka_tools_pkg.tab_request_params` | 142 |
| `dka_tools_pkg.tab_request_params` | 143 |
| `dka_tools_pkg.tab_request_params` | 144 |
| `dka_tools_pkg.tab_request_params` | 145 |
| `dka_tools_pkg.tab_request_params` | 146 |
| `dka_tools_pkg.tab_request_params` | 147 |
| `dka_tools_pkg.tab_request_params` | 148 |
| `dka_tools_pkg.tab_request_params` | 149 |
| `dka_tools_pkg.tab_request_params` | 150 |
| `dka_tools_pkg.tab_request_params` | 151 |
| `dka_tools_pkg.tab_request_params` | 152 |
| `dka_tools_pkg.tab_request_params` | 153 |
| `dka_tools_pkg.tab_request_params` | 154 |
| `dka_tools_pkg.tab_request_params` | 155 |
| `dka_tools_pkg.tab_request_params` | 156 |
| `dka_tools_pkg.tab_request_params` | 157 |
| `dka_tools_pkg.tab_request_params` | 158 |
| `dka_tools_pkg.tab_request_params` | 159 |
| `dka_tools_pkg.tab_request_params` | 160 |
| `dka_tools_pkg.tab_request_params` | 161 |
| `dka_tools_pkg.tab_request_params` | 162 |
| `dka_tools_pkg.tab_request_params` | 163 |
| `dka_tools_pkg.tab_request_params` | 164 |
| `dka_tools_pkg.tab_request_params` | 165 |
| `dka_tools_pkg.tab_request_params` | 166 |
| `dka_tools_pkg.tab_request_params` | 167 |
| `dka_tools_pkg.tab_request_params` | 168 |
| `dka_tools_pkg.tab_request_params` | 169 |
| `dka_tools_pkg.tab_request_params` | 170 |
| `dka_tools_pkg.tab_request_params` | 171 |
| `dka_tools_pkg.tab_request_params` | 172 |
| `dka_tools_pkg.tab_request_params` | 173 |
| `dka_tools_pkg.tab_request_params` | 174 |
| `dka_tools_pkg.tab_request_params` | 175 |
| `dka_tools_pkg.tab_request_params` | 176 |
| `dka_tools_pkg.tab_request_params` | 177 |
| `dka_tools_pkg.tab_request_params` | 178 |
| `dka_tools_pkg.tab_request_params` | 179 |
| `dka_tools_pkg.tab_request_params` | 180 |
| `dka_tools_pkg.tab_request_params` | 181 |
| `dka_tools_pkg.tab_request_params` | 182 |
| `dka_tools_pkg.tab_request_params` | 183 |
| `dka_tools_pkg.tab_request_params` | 184 |
| `dka_tools_pkg.tab_request_params` | 185 |
| `dka_tools_pkg.tab_request_params` | 186 |
| `dka_tools_pkg.tab_request_params` | 187 |
| `dka_tools_pkg.tab_request_params` | 188 |
| `dka_tools_pkg.tab_request_params` | 189 |
| `dka_tools_pkg.tab_request_params` | 190 |
| `dka_tools_pkg.tab_request_params` | 191 |
| `dka_tools_pkg.tab_request_params` | 192 |
| `dka_tools_pkg.tab_request_params` | 193 |
| `dka_tools_pkg.tab_request_params` | 194 |
| `dka_tools_pkg.tab_request_params` | 195 |
| `dka_tools_pkg.tab_request_params` | 196 |
| `dka_tools_pkg.tab_request_params` | 197 |
| `dka_tools_pkg.tab_request_params` | 198 |
| `dka_tools_pkg.tab_request_params` | 199 |
| `dka_tools_pkg.tab_request_params` | 200 |
| `dka_tools_pkg.tab_request_params` | 201 |
| `dka_tools_pkg.tab_request_params` | 202 |
| `dka_tools_pkg.tab_request_params` | 203 |
| `dka_tools_pkg.tab_request_params` | 204 |
| `dka_tools_pkg.tab_request_params` | 205 |
| `dka_tools_pkg.tab_request_params` | 206 |
| `dka_tools_pkg.tab_request_params` | 207 |
| `dka_tools_pkg.tab_request_params` | 208 |
| `dka_tools_pkg.tab_request_params` | 209 |
| `dka_tools_pkg.tab_request_params` | 210 |
| `dka_tools_pkg.tab_request_params` | 211 |
| `dka_tools_pkg.tab_request_params` | 212 |
| `dka_tools_pkg.tab_request_params` | 213 |
| `dka_tools_pkg.tab_request_params` | 214 |
| `dka_tools_pkg.tab_request_params` | 215 |
| `dka_tools_pkg.tab_request_params` | 216 |
| `dka_tools_pkg.tab_request_params` | 217 |
| `fnd_global.apps_initialize` | 246 |
| `fnd_profile.value` | 248 |
| `dka_tools_pkg.get_request_set_params` | 251 |
| `fnd_request.submit_request` | 270 |
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
| `dka_tools_pkg.tab_request_params` | 337 |
| `dka_tools_pkg.tab_request_params` | 338 |
| `dka_tools_pkg.tab_request_params` | 339 |
| `dka_tools_pkg.tab_request_params` | 340 |
| `dka_tools_pkg.tab_request_params` | 341 |
| `dka_tools_pkg.tab_request_params` | 342 |
| `dka_tools_pkg.tab_request_params` | 343 |
| `dka_tools_pkg.tab_request_params` | 344 |
| `dka_tools_pkg.tab_request_params` | 345 |
| `dka_tools_pkg.tab_request_params` | 346 |
| `dka_tools_pkg.tab_request_params` | 347 |
| `dka_tools_pkg.tab_request_params` | 348 |
| `dka_tools_pkg.tab_request_params` | 349 |
| `dka_tools_pkg.tab_request_params` | 350 |
| `dka_tools_pkg.tab_request_params` | 351 |
| `dka_tools_pkg.tab_request_params` | 352 |
| `dka_tools_pkg.tab_request_params` | 353 |
| `dka_tools_pkg.tab_request_params` | 354 |
| `dka_tools_pkg.tab_request_params` | 355 |
| `dka_tools_pkg.tab_request_params` | 356 |
| `dka_tools_pkg.tab_request_params` | 357 |
| `dka_tools_pkg.tab_request_params` | 358 |
| `dka_tools_pkg.tab_request_params` | 359 |
| `dka_tools_pkg.tab_request_params` | 360 |
| `dka_tools_pkg.tab_request_params` | 361 |
| `dka_tools_pkg.tab_request_params` | 362 |
| `dka_tools_pkg.tab_request_params` | 363 |
| `dka_tools_pkg.tab_request_params` | 364 |
| `dka_tools_pkg.tab_request_params` | 365 |
| `dka_tools_pkg.tab_request_params` | 366 |
| `dka_tools_pkg.tab_request_params` | 367 |
| `dka_tools_pkg.tab_request_params` | 368 |
| `dka_tools_pkg.tab_request_params` | 369 |
| `dka_tools_pkg.tab_request_params` | 370 |
| `dka_tools_pkg.tab_request_params` | 371 |
| `dka_tools_pkg.tab_request_params` | 372 |
| `dka_tools_pkg.tab_request_params` | 373 |
| `dka_tools_pkg.tab_request_params` | 374 |
| `dka_tools_pkg.tab_request_params` | 375 |
| `dka_tools_pkg.tab_request_params` | 376 |
| `fnd_concurrent.wait_for_request` | 392 |
| `fnd_concurrent.wait_for_request` | 411 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 220, 379 |
| when_others | 432 |
| soumission | 111, 270 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
