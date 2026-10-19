# DKA_SAPWFCSP_IVALUA_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SAPWFCSP_IVALUA_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SAPWFCSP_IVALUA_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 296 ; encodage : cp1252 (repli). SHA-256 : `7b47623b46b7e6577fb5b2e72436263cfbc257c064f1fd2c66f57e7c5d315fdd`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `update_data` | 18 |
| `notif_csp_ano_imput_att_ivalua` | 33 |
| `pose_blocage` | 48 |
| `maj_blocage` | 63 |
| `notif_dest_ivalua` | 78 |
| `insert_history_ivalua` | 94 |
| `pre_notification_ivalua` | 110 |
| `get_action_history_ivalua` | 125 |
| `get_infos_ap_ivalua` | 139 |
| `notif_reponse_ivalua` | 152 |
| `traitement_blocage_ivalua` | 166 |
| `debloque_null` | 181 |
| `is_ivalua_order` | 195 |
| `notif_ecartprix_ivalua` | 209 |
| `get_ecart_prix_ivalua` | 225 |
| `insert_history_wf_ivalua` | 230 |
| `notif_CSP_ANO_QTY_REC_IV` | 245 |
| `notif_CSP_ANO_QTY_ORD_IV` | 260 |
| `get_reponse_blocage_ivalua` | 274 |
| `verif_blocage_ivalua` | 288 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
