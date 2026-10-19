# DKA_SGLABONNEMENT.sql

Source : [dka/12.0.0/sql/DKA_SGLABONNEMENT.sql](../../dka/12.0.0/sql/DKA_SGLABONNEMENT.sql).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 246 ; encodage : cp1252 (repli). SHA-256 : `de245194893390048938dc7851f4d8b6bfd00efee5417be24f15458285209998`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Fnd_Responsibility` | 51 |
| `Fnd_User` | 56 |
| `Fnd_Concurrent_Programs` | 66 |
| `DUAL` | 245 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.Apps_Initialize` | 72 |
| `Fnd_Profile.VALUE` | 76 |
| `Dka_Tools_Pkg.Get_Request_Set_Params` | 79 |
| `Fnd_Request.Submit_Request` | 95 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 100 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 101 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 102 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 103 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 104 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 105 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 106 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 107 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 108 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 109 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 110 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 111 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 112 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 113 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 114 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 115 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 116 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 117 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 118 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 119 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 120 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 121 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 122 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 123 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 124 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 125 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 126 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 127 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 128 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 129 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 130 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 131 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 132 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 133 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 134 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 135 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 136 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 137 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 138 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 139 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 140 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 141 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 142 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 143 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 144 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 145 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 146 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 147 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 148 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 149 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 150 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 151 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 152 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 153 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 154 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 155 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 156 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 157 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 158 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 159 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 160 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 161 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 162 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 163 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 164 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 165 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 166 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 167 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 168 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 169 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 170 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 171 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 172 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 173 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 174 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 175 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 176 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 177 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 178 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 179 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 180 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 181 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 182 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 183 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 184 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 185 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 186 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 187 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 188 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 189 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 190 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 191 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 192 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 193 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 194 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 195 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 196 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 197 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 198 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 199 |
| `Fnd_Concurrent.Wait_For_Request` | 212 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 202 |
| when_others | 238 |
| soumission | 95 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
