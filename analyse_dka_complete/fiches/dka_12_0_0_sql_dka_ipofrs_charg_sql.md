# DKA_IPOFRS_CHARG.sql

Source : [dka/12.0.0/sql/DKA_IPOFRS_CHARG.sql](../../dka/12.0.0/sql/DKA_IPOFRS_CHARG.sql).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 244 ; encodage : cp1252 (repli). SHA-256 : `a9ba06485d10bfabe4f412804fa6955aa55c016e94ba878c08994b6d803c2243`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 47 |
| `fnd_user` | 52 |
| `fnd_concurrent_programs` | 62 |
| `DUAL` | 243 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 68 |
| `fnd_profile.value` | 70 |
| `dka_tools_pkg.get_request_set_params` | 73 |
| `fnd_request.submit_request` | 94 |
| `dka_tools_pkg.tab_request_params` | 101 |
| `dka_tools_pkg.tab_request_params` | 102 |
| `dka_tools_pkg.tab_request_params` | 103 |
| `dka_tools_pkg.tab_request_params` | 104 |
| `dka_tools_pkg.tab_request_params` | 105 |
| `dka_tools_pkg.tab_request_params` | 106 |
| `dka_tools_pkg.tab_request_params` | 107 |
| `dka_tools_pkg.tab_request_params` | 108 |
| `dka_tools_pkg.tab_request_params` | 109 |
| `dka_tools_pkg.tab_request_params` | 110 |
| `dka_tools_pkg.tab_request_params` | 111 |
| `dka_tools_pkg.tab_request_params` | 112 |
| `dka_tools_pkg.tab_request_params` | 113 |
| `dka_tools_pkg.tab_request_params` | 114 |
| `dka_tools_pkg.tab_request_params` | 115 |
| `dka_tools_pkg.tab_request_params` | 116 |
| `dka_tools_pkg.tab_request_params` | 117 |
| `dka_tools_pkg.tab_request_params` | 118 |
| `dka_tools_pkg.tab_request_params` | 119 |
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
| `fnd_concurrent.wait_for_request` | 214 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 202 |
| when_others | 235 |
| soumission | 94 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
