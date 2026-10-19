# XXEAI_INTERFACE_TOOLS_PKG.pks

Source : [dka/12.0.0/admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pks](../../dka/12.0.0/admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pks).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 397 ; encodage : cp1252 (repli). SHA-256 : `3df3035e60336c2aeb1b929525860c04344cb875dcffa4381214045fe4945f94`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Get_Infos_Banque` | 45 |
| `Get_Infos_Banque_Interne` | 60 |
| `Get_Infos_Rejets_Sepa` | 75 |
| `Get_Params_FOLIO_GL` | 93 |
| `Get_Societe_Projet` | 109 |
| `Get_Type_Depense_Evenement` | 126 |
| `Get_Cle_Comptable_CUF` | 148 |
| `Get_Societe_Projet_Liste` | 165 |
| `Get_Type_Depense_Evt_Liste` | 182 |
| `Get_Cle_Comptable_CUF_Liste` | 204 |
| `Get_Invoice_Id` | 220 |
| `Get_Info_Invoice_Header` | 247 |
| `Get_Params_FOLIO_AP` | 270 |
| `Get_Info_Invoice_Line` | 302 |
| `Get_Info_Invoice_Header_Liste` | 320 |
| `Get_Info_Invoice_Line_Liste` | 337 |
| `Get_Invoice_Id_Liste` | 354 |
| `Get_type_num_ligne_mvt_AR` | 372 |
| `Get_region_DKCODE` | 390 |

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
