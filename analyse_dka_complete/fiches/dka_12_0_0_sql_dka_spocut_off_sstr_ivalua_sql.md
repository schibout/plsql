# DKA_SPOCUT_OFF_SSTR_IVALUA.sql

Source : [dka/12.0.0/sql/DKA_SPOCUT_OFF_SSTR_IVALUA.sql](../../dka/12.0.0/sql/DKA_SPOCUT_OFF_SSTR_IVALUA.sql).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 384 ; encodage : cp1252 (repli). SHA-256 : `30b7c4cb6e7388ce34fa5bb6f37d2bb65d61b44d93e83933ea74c275eba710dd`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 64 |
| `fnd_responsibility` | 89 |
| `fnd_user` | 94 |
| `fnd_concurrent_programs` | 104 |
| `gl_period_statuses` | 161 |
| `gl_period_statuses` | 164 |
| `DUAL` | 383 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 110 |
| `fnd_profile.value` | 113 |
| `dka_tools_pkg.get_request_set_params` | 116 |
| `dka_tools_pkg.tab_request_params` | 173 |
| `dka_tools_pkg.tab_request_params` | 174 |
| `fnd_request.submit_request` | 177 |
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
| `dka_tools_pkg.tab_request_params` | 218 |
| `dka_tools_pkg.tab_request_params` | 219 |
| `dka_tools_pkg.tab_request_params` | 220 |
| `dka_tools_pkg.tab_request_params` | 221 |
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
| `Fnd_Concurrent.wait_for_request` | 330 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 285, 355 |
| when_others | 375 |
| soumission | 177 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
