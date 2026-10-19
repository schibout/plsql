# DKA_AUTO_SARRECOUVREMENT.sql

Source : [dka/12.0.0/sql/DKA_AUTO_SARRECOUVREMENT.sql](../../dka/12.0.0/sql/DKA_AUTO_SARRECOUVREMENT.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 288 ; encodage : cp1252 (repli). SHA-256 : `0e1b0db280b268fd58e3665c5c87f0e63996dd1837ca8a65db647ca3e61ca396`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Positionnement_Contexte` | 58 |
| `soumission_traitement` | 109 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Fnd_User` | 66 |
| `Fnd_Responsibility` | 77 |
| `fnd_application` | 88 |
| `fnd_concurrent_programs` | 131 |
| `fnd_application` | 132 |
| `v$instance` | 168 |
| `fnd_concurrent_programs` | 181 |
| `fnd_application` | 182 |
| `DUAL` | 286 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.Apps_Initialize` | 98 |
| `Fnd_Profile.VALUE` | 99 |
| `Dka_Tools_Pkg.Get_Request_Set_Params` | 119 |
| `Fnd_Request.Submit_Request` | 137 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 143 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 145 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 146 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 147 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 148 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 149 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 150 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 151 |
| `Dka_Tools_Pkg.Tab_Request_Params` | 152 |
| `fnd_message.set_name` | 158 |
| `fnd_message.set_token` | 159 |
| `Fnd_Concurrent.Wait_For_Request` | 236 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 154 |
| when_others | 157, 278 |
| soumission | 137 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
