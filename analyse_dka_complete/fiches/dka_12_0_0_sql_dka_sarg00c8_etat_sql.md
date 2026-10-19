# DKA_SARG00C8_ETAT.sql

Source : [dka/12.0.0/sql/DKA_SARG00C8_ETAT.sql](../../dka/12.0.0/sql/DKA_SARG00C8_ETAT.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 263 ; encodage : cp1252 (repli). SHA-256 : `7dfae1bd6d5d5cd50be767dec9c3fe0d3f0ea2977a2502b66231ec7188b76ef8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 50 |
| `gl_period_statuses` | 51 |
| `fnd_responsibility` | 64 |
| `fnd_user` | 69 |
| `fnd_concurrent_programs` | 79 |
| `DUAL` | 262 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 85 |
| `fnd_profile.value` | 87 |
| `dka_tools_pkg.get_request_set_params` | 90 |
| `dka_tools_pkg.tab_request_params` | 110 |
| `fnd_request.submit_request` | 114 |
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
| `dka_tools_pkg.tab_request_params` | 218 |
| `dka_tools_pkg.tab_request_params` | 219 |
| `fnd_concurrent.wait_for_request` | 233 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 222 |
| when_others | 254 |
| soumission | 114 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
