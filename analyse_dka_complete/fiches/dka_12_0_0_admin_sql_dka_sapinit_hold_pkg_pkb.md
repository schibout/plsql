# DKA_SAPINIT_HOLD_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPINIT_HOLD_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPINIT_HOLD_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 260 ; encodage : cp1252 (repli). SHA-256 : `9f54aa837959cd1cb9b82f88ef1532fcdd9801cf36f823c72736f30334ab53c9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 24 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SAPREINITBLOCAGE_TMP` | 44 |
| `ap_holds_all` | 68 |
| `wf_notifications` | 76 |
| `wf_notifications` | 111 |
| `wf_notifications` | 126 |
| `ap_holds_all` | 138 |
| `DKA_SAPREINITBLOCAGE_TMP` | 148 |
| `ap_holds_all` | 172 |
| `wf_notifications` | 190 |
| `ap_holds_all` | 195 |
| `ap_holds_all` | 206 |
| `DKA_SAPREINITBLOCAGE_TMP` | 211 |
| `ap_invoices_all` | 221 |
| `DKA_SAPREINITBLOCAGE_TMP` | 226 |
| `ap_holds_all` | 237 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_outdebug_message` | 33 |
| `Dka_Tools_Pkg.put_log_message` | 39 |
| `Dka_Tools_Pkg.put_outdebug_message` | 205 |
| `fnd_profile.value` | 208 |
| `fnd_profile.value` | 209 |
| `Dka_Tools_Pkg.put_outdebug_message` | 215 |
| `Dka_Tools_Pkg.put_outdebug_message` | 217 |
| `Dka_Tools_Pkg.put_outdebug_message` | 220 |
| `fnd_profile.value` | 223 |
| `fnd_profile.value` | 224 |
| `Dka_Tools_Pkg.put_outdebug_message` | 231 |
| `Dka_Tools_Pkg.put_outdebug_message` | 233 |
| `Dka_Tools_Pkg.put_outdebug_message` | 236 |
| `fnd_profile.value` | 239 |
| `fnd_profile.value` | 240 |
| `Dka_Tools_Pkg.put_outdebug_message` | 243 |
| `Dka_Tools_Pkg.put_outdebug_message` | 245 |
| `Dka_Tools_Pkg.put_outdebug_message` | 251 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 247 |
| when_others | 249 |
| truncate | 41 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPINIT_HOLD / DKA | `DKA_SAPINIT_HOLD_PKG.main` | dka/12.0.0/admin/import/DKA_SAPINIT_HOLD.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
