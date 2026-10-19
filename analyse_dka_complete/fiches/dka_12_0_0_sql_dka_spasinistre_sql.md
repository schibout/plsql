# DKA_SPASINISTRE.sql

Source : [dka/12.0.0/sql/DKA_SPASINISTRE.sql](../../dka/12.0.0/sql/DKA_SPASINISTRE.sql).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 337 ; encodage : cp1252 (repli). SHA-256 : `fa8b182ad0af8c7fae7e5a1a6d09c41a14c012d0179c4455b0d0191f8e220809`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PER_SECURITY_PROFILES` | 65 |
| `fnd_responsibility` | 78 |
| `fnd_user` | 83 |
| `fnd_concurrent_programs` | 93 |
| `DUAL` | 336 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 70 |
| `fnd_global.apps_initialize` | 99 |
| `fnd_profile.value` | 104 |
| `FND_REQUEST.SET_ORG_ID` | 110 |
| `dka_tools_pkg.get_request_set_params` | 119 |
| `FND_REQUEST.SET_OPTIONS` | 147 |
| `fnd_request.submit_request` | 150 |
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
| `fnd_concurrent.wait_for_request` | 293 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 261 |
| when_others | 138, 328 |
| soumission | 150 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
