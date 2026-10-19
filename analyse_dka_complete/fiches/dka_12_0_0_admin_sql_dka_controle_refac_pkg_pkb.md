# DKA_CONTROLE_REFAC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_CONTROLE_REFAC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_CONTROLE_REFAC_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2790 ; encodage : cp1252 (repli). SHA-256 : `1f949a503f71e6c0e62d18c7b303c2d4856af36eca9053676854c1e456ac6292`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Step_1` | 43 |
| `Step_2` | 154 |
| `Edition_Detail` | 581 |
| `Step_3` | 759 |
| `Step_4` | 1517 |
| `Step_5` | 1662 |
| `Step_6` | 1756 |
| `Step_7` | 2497 |
| `Step_8` | 2569 |
| `Main` | 2667 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `AR_CUSTOMERS` | 74 |
| `AR_CUSTOMERS` | 78 |
| `Fnd_Flex_Value_Sets` | 193 |
| `Pa_Expenditure_Items_All` | 216 |
| `Fnd_Flex_Value_Sets` | 287 |
| `Pa_Expenditure_Items_All` | 311 |
| `Fnd_Flex_Value_Sets` | 386 |
| `Pa_Events` | 409 |
| `Pa_Events` | 427 |
| `Dka_Sarrefac_Param` | 448 |
| `Fnd_Flex_Value_Sets` | 499 |
| `Pa_Events` | 520 |
| `Pa_Events` | 537 |
| `Dka_Sarrefac_Param` | 558 |
| `Pa_Expenditure_Types_Expend_v` | 643 |
| `Gl_Period_Statuses` | 667 |
| `Dka_Controle_Refac` | 782 |
| `Dka_Controle_Refac` | 793 |
| `ap_supplier_sites_all` | 809 |
| `Dka_Controle_Refac` | 841 |
| `Dka_Controle_Refac` | 854 |
| `Gl_Code_Combinations` | 865 |
| `Gl_Period_Statuses` | 894 |
| `Dka_Controle_Refac` | 1200 |
| `PA_EXPENDITURE_ITEMS_ALL` | 1228 |
| `PA_EXPENDITURE_ITEMS_ALL` | 1290 |
| `Pa_Events` | 1354 |
| `pa_tasks` | 1390 |
| `Ap_Invoice_Distributions_All` | 1537 |
| `Ap_Invoice_Distributions_All` | 1556 |
| `fnd_flex_value_sets` | 1678 |
| `HR_OPERATING_UNITS` | 1691 |
| `Ap_Lookup_Codes` | 1847 |
| `Ra_Customer_Trx_All` | 1850 |
| `Ap_Lookup_Codes` | 1968 |
| `Ra_Customer_Trx_All` | 1971 |
| `Ap_Lookup_Codes` | 2095 |
| `Ra_Customer_Trx_All` | 2098 |
| `Ap_Lookup_Codes` | 2220 |
| `Ra_Customer_Trx_All` | 2223 |
| `Ap_Lookup_Codes` | 2344 |
| `Ra_Customer_Trx_All` | 2347 |
| `AP_INVOICE_DISTRIBUTIONS_ALL` | 2504 |
| `Pa_Projects_All` | 2507 |
| `Dka_Sarrefac_Param` | 2580 |
| `Pa_Expenditure_Types_Expend_v` | 2586 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 102 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 103 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 113 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 114 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 115 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 118 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 123 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 134 |
| `Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f` | 182 |
| `Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f` | 276 |
| `Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Produit_f` | 376 |
| `Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Produit_f` | 489 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 584 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 585 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 586 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 587 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 588 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 589 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 590 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 591 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 592 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 593 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 594 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 595 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 596 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 597 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 598 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 599 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 600 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 601 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 602 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 603 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 604 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 605 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 606 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 607 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 614 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 615 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 616 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 617 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 632 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 654 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 678 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 687 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 696 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 705 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 714 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 723 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 739 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1401 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1402 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1403 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1404 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1417 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1418 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1419 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1426 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1436 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1463 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1464 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1465 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1471 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1480 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1496 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1571 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1572 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1573 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1574 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1583 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1584 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1585 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1600 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1618 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1643 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1703 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1704 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1705 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1706 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1715 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1716 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1717 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1720 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1724 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1736 |
| `Fnd_Date.Canonical_To_Date` | 1844 |
| `Fnd_Date.Canonical_To_Date` | 1845 |
| `Fnd_Date.Canonical_To_Date` | 1965 |
| `Fnd_Date.Canonical_To_Date` | 1966 |
| `Fnd_Date.Canonical_To_Date` | 2092 |
| `Fnd_Date.Canonical_To_Date` | 2093 |
| `Fnd_Date.Canonical_To_Date` | 2217 |
| `Fnd_Date.Canonical_To_Date` | 2218 |
| `Fnd_Date.Canonical_To_Date` | 2341 |
| `Fnd_Date.Canonical_To_Date` | 2342 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2419 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2420 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2421 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2422 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2431 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2432 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2433 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2444 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2457 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2477 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2516 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2517 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2518 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2519 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2529 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2530 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2531 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2534 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2539 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2551 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2600 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2601 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2602 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2603 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2612 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2613 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2615 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2622 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2631 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2647 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2784 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1449 |
| when_others | 131, 652, 676, 736, 1493, 1640, 1733, 2474, 2548, 2644, 2781 |
| truncate | 888 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CONTROLE_REFAC / DKA | `dka_controle_refac_pkg.main` | dka/12.0.0/admin/import/DKA_CONTROLE_REFAC.prt:545 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
