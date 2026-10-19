# DKA_SAPWFAG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPWFAG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPWFAG_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1113 ; encodage : cp1252 (repli). SHA-256 : `4693fa6a484a94aa9d028ff9503dfc5e3218e132a4777d2ce637ffd4e19431ca`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_ap_segment1_value` | 58 |
| `get_ap_segment2_value` | 177 |
| `get_ap_segment3_value` | 287 |
| `get_ap_segment4_value` | 384 |
| `get_ap_segment5_value` | 530 |
| `get_ap_segment6_value` | 625 |
| `get_ap_segment7_value` | 725 |
| `get_ap_segment8_value` | 798 |
| `get_ap_segment9_value` | 870 |
| `get_ap_segment10_value` | 939 |
| `get_ap_segment11_value` | 1000 |
| `get_ap_segment12_value` | 1061 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `wf_engine.GetItemAttrNumber` | 94 |
| `DKA_SPAAUTOACCOUNTING_PKG.societe_projet` | 128 |
| `fnd_message.set_name` | 131 |
| `wf_engine.SetItemAttrText` | 132 |
| `wf_engine.SetItemAttrText` | 140 |
| `wf_core.context` | 153 |
| `wf_engine.GetItemAttrNumber` | 208 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 243 |
| `fnd_message.set_name` | 246 |
| `wf_engine.SetItemAttrText` | 247 |
| `wf_engine.SetItemAttrText` | 254 |
| `wf_core.context` | 266 |
| `wf_engine.GetItemAttrNumber` | 318 |
| `wf_engine.GetItemAttrText` | 323 |
| `wf_engine.GetItemAttrNumber` | 328 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 334 |
| `fnd_message.set_name` | 340 |
| `wf_engine.SetItemAttrText` | 341 |
| `wf_engine.SetItemAttrText` | 349 |
| `wf_core.context` | 361 |
| `wf_engine.GetItemAttrNumber` | 415 |
| `wf_engine.GetItemAttrText` | 442 |
| `wf_engine.GetItemAttrNumber` | 448 |
| `wf_engine.GetItemAttrText` | 459 |
| `wf_engine.GetItemAttrText` | 464 |
| `fnd_message.set_name` | 468 |
| `fnd_message.set_token` | 469 |
| `wf_engine.SetItemAttrText` | 470 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f` | 481 |
| `fnd_message.set_name` | 489 |
| `wf_engine.SetItemAttrText` | 490 |
| `wf_engine.SetItemAttrText` | 497 |
| `wf_core.context` | 507 |
| `wf_engine.GetItemAttrText` | 567 |
| `wf_engine.GetItemAttrNumber` | 572 |
| `dka_spaautoaccounting_pkg.code_interco` | 581 |
| `fnd_message.set_name` | 585 |
| `wf_engine.SetItemAttrText` | 586 |
| `wf_engine.SetItemAttrText` | 593 |
| `wf_core.context` | 603 |
| `wf_engine.GetItemAttrNumber` | 648 |
| `dka_spaautoaccounting_pkg.centrefi` | 681 |
| `fnd_message.set_name` | 684 |
| `wf_engine.SetItemAttrText` | 685 |
| `wf_engine.SetItemAttrText` | 692 |
| `wf_core.context` | 702 |
| `wf_engine.GetItemAttrNumber` | 747 |
| `dka_spaautoaccounting_pkg.affaire` | 756 |
| `fnd_message.set_name` | 759 |
| `wf_engine.SetItemAttrText` | 760 |
| `wf_engine.SetItemAttrText` | 767 |
| `wf_core.context` | 777 |
| `wf_engine.GetItemAttrNumber` | 820 |
| `dka_spaautoaccounting_pkg.projetfi` | 829 |
| `fnd_message.set_name` | 832 |
| `wf_engine.SetItemAttrText` | 833 |
| `wf_engine.SetItemAttrText` | 840 |
| `wf_core.context` | 850 |
| `wf_engine.GetItemAttrNumber` | 892 |
| `dka_spaautoaccounting_pkg.flux` | 898 |
| `fnd_message.set_name` | 901 |
| `wf_engine.SetItemAttrText` | 902 |
| `wf_engine.SetItemAttrText` | 909 |
| `wf_core.context` | 919 |
| `fnd_message.set_name` | 962 |
| `wf_engine.SetItemAttrText` | 963 |
| `wf_engine.SetItemAttrText` | 970 |
| `wf_core.context` | 980 |
| `fnd_message.set_name` | 1023 |
| `wf_engine.SetItemAttrText` | 1024 |
| `wf_engine.SetItemAttrText` | 1031 |
| `wf_core.context` | 1041 |
| `fnd_message.set_name` | 1084 |
| `wf_engine.SetItemAttrText` | 1085 |
| `wf_engine.SetItemAttrText` | 1092 |
| `wf_core.context` | 1102 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 152, 265, 360, 506, 602, 701, 776, 849, 918, 979, 1040, 1101 |
| workflow | 87, 88, 94, 132, 140, 201, 202, 208, 247, 254, 311, 312, 318, 323, 328, 341, 349, 407, 409, 415, 442, 448, 459, 464, 470, 490, 497, 548, 549, 567, 572, 586, 593, 641, 642, 648, 685, 692, 740, 741, 747, 760, 767, 813, 814, 820, 833, 840, 885, 886, 892, 902, 909, 954, 955, 963, 970, 1015, 1016, 1024, 1031, 1076, 1077, 1085, 1092 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
