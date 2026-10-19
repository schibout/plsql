# DKA_SAPWFCSP_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SAPWFCSP_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SAPWFCSP_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1260 ; encodage : cp1252 (repli). SHA-256 : `67fb73b19657f2dc88e25305d5abe76da03ded1178975b7855c0258d3ff7d204`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `string_to_table` | 81 |
| `print_wf_message` | 95 |
| `contexte_PNC` | 100 |
| `debloque` | 116 |
| `debloque_aff` | 130 |
| `pre_notification` | 146 |
| `exists_blocage_type` | 161 |
| `exists_misc_holds` | 175 |
| `exists_blocage` | 190 |
| `CommandeSSTR_ivalua` | 206 |
| `demarque_blocage_BAP` | 220 |
| `superieur_bap` | 252 |
| `acheteur_commande` | 273 |
| `pose_blocage_litige` | 288 |
| `transfert_codes_blocages_OI_AP` | 304 |
| `lance_workflow_CSP_PL` | 358 |
| `initialise_workflow_OI` | 372 |
| `termine_workflow_OI` | 387 |
| `incremente_relance` | 408 |
| `initialise_workflow_AP` | 423 |
| `reponse_notif_precedente` | 440 |
| `notif_CSP_ANO_OI` | 456 |
| `notif_CSP_ANO_OI_REP` | 471 |
| `notif_CSP_REF_OI` | 486 |
| `notif_CSP_ANO_IMPUT_ATT` | 502 |
| `notif_CSP_ANO_RET_IMPUT_ATT` | 519 |
| `notif_EXPLOIT_IMPUT_ATT` | 534 |
| `en_attente` | 549 |
| `notif_EXPLOIT_BAP` | 564 |
| `notif_CSP_ANO_PRLV` | 579 |
| `notif_CSP_ANO_AFFACT` | 595 |
| `notif_CSP_REF_AFFACT` | 610 |
| `notif_CSP_ANO_RIB` | 626 |
| `notif_HIERAR_EXPLOIT_BAP` | 642 |
| `notif_CSP_ANO_BAP` | 658 |
| `notif_CSP_ANO_DIVERS` | 673 |
| `facture_OI` | 689 |
| `exists_BR_ligne_Cmd` | 704 |
| `employe_Droit_habilitation` | 721 |
| `gestion_deblocage_variance` | 738 |
| `batch_traite_factures` | 753 |
| `determine_role_associe_facture` | 767 |
| `get_action_history` | 785 |
| `get_infos_AP` | 800 |
| `get_infos_OI` | 815 |
| `insert_history_wf` | 820 |
| `insert_history` | 836 |
| `superieur_ecart_prix` | 853 |
| `employe_price_habilitation` | 868 |
| `notif_CSP_ANO_PRICE` | 883 |
| `notif_CSP_ANO_PRICE_NC` | 898 |
| `notif_CSP_NC_PRICE_INTIATEUR` | 913 |
| `notif_ACH_ANO_PRICE` | 928 |
| `notif_DDEUR_ANO_PRICE` | 943 |
| `notif_HIERAR_DDEUR_ANO_PRICE` | 959 |
| `get_ecart_prix` | 976 |
| `notif_CSP_ANO_QTY_REC` | 990 |
| `notif_DDEUR_ANO_QTY_REC` | 1005 |
| `notif_CHEF_EXPLOT_QTY_REC` | 1021 |
| `notif_CSP_ANO_QTY_ORD` | 1035 |
| `notif_ACH_ANO_QTY_ORD` | 1050 |
| `notif_HIERAR_ACH_ANO_QTY_ORD` | 1066 |
| `employe_qty_ord_habilitation` | 1081 |
| `superieur_qty_ord` | 1096 |
| `notif_CSP_ANO_CMD_MULT` | 1111 |
| `abort_previous_workflow` | 1126 |
| `Asset_invoice` | 1142 |
| `ADD_HOLD_CODE` | 1158 |
| `is_catalogue_order` | 1174 |
| `AP_SELECTOR` | 1181 |
| `cree_blocage_AP` | 1197 |
| `get_item_info` | 1208 |
| `get_blocages_AP` | 1213 |
| `leve_blocage` | 1226 |
| `leve_blocage_aff` | 1246 |

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

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPWFCSP / DKA | `DKA_SAPWFCSP_PKG.batch_traite_factures` | dka/12.0.0/admin/import/DKA_SAPWFCSP.prt:551 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
