# DKA_SAPFRSDUP_MASSE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPFRSDUP_MASSE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPFRSDUP_MASSE_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 849 ; encodage : cp1252 (repli). SHA-256 : `3651bf73075a246bb0c80617077709a8ea2e5ab7d9f900102d306537ad06ffe6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 52 |
| `writelog` | 71 |
| `output_end` | 120 |
| `writeout` | 139 |
| `Report_Bilan` | 173 |
| `DKA_SAPFRSDUPLI_MASSE` | 270 |
| `purge_data` | 688 |
| `main` | 734 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 303 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 342 |
| `ap_supplier_sites_all` | 355 |
| `ap_supplier_sites_all` | 375 |
| `DUAL` | 395 |
| `dka_sapfrsdupli_error_tmp` | 397 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 417 |
| `ap_supplier_sites_all` | 437 |
| `DUAL` | 453 |
| `dka_sapfrsdupli_error_tmp` | 455 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 474 |
| `ap_supplier_sites_all` | 497 |
| `DUAL` | 513 |
| `dka_sapfrsdupli_error_tmp` | 515 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 535 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 567 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 586 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 604 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 626 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 697 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 699 |
| `fnd_responsibility_vl` | 757 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 29 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 55 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 56 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 57 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 58 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 59 |
| `fnd_file.put_line` | 83 |
| `fnd_file.put_line` | 86 |
| `fnd_file.put_line` | 90 |
| `Fnd_File.put_line` | 125 |
| `Fnd_File.put_line` | 126 |
| `Fnd_File.put_line` | 127 |
| `FND_FILE.PUT_LINE` | 144 |
| `Fnd_File.put_line` | 150 |
| `Fnd_File.put_line` | 152 |
| `Fnd_File.put_line` | 153 |
| `Fnd_File.put_line` | 154 |
| `Fnd_File.put_line` | 155 |
| `Fnd_File.put_line` | 156 |
| `Fnd_File.put_line` | 180 |
| `fnd_file.put_line` | 189 |
| `fnd_file.put_line` | 190 |
| `fnd_file.put_line` | 191 |
| `fnd_file.put_line` | 193 |
| `fnd_file.put_line` | 194 |
| `fnd_file.put_line` | 195 |
| `fnd_file.put_line` | 196 |
| `fnd_file.put_line` | 197 |
| `fnd_file.put_line` | 204 |
| `fnd_file.put_line` | 205 |
| `fnd_file.put_line` | 206 |
| `fnd_file.put_line` | 218 |
| `fnd_file.put_line` | 223 |
| `fnd_file.put_line` | 224 |
| `fnd_file.put_line` | 225 |
| `fnd_file.put_line` | 226 |
| `fnd_file.put_line` | 239 |
| `Fnd_File.put_line` | 240 |
| `Fnd_File.put_line` | 248 |
| `Fnd_File.put_line` | 249 |
| `Fnd_File.put_line` | 322 |
| `DKA_SAPFRSDUPLI_PKG.DUPLICATION_SITE_FOURNISSEUR` | 547 |
| `fnd_file.put_line` | 638 |
| `Fnd_File.put_line` | 666 |
| `Dka_Tools_Pkg.put_log_message` | 695 |
| `Dka_Tools_Pkg.put_log_message` | 709 |
| `fnd_global.apps_initialize` | 766 |
| `Fnd_File.put_line` | 816 |
| `Fnd_File.put_line` | 817 |
| `Fnd_File.put_line` | 818 |
| `Fnd_File.put_line` | 820 |
| `Fnd_File.put_line` | 828 |
| `Fnd_File.put_line` | 829 |
| `Fnd_File.put_line` | 836 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 426, 489, 544, 622, 635, 710, 813 |
| when_others | 93, 147, 244, 347, 365, 385, 444, 483, 504, 613, 637, 712, 760, 831 |
| suppression | 697 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
