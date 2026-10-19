# DKA_IFA_FLUXCM_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IFA_FLUXCM_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IFA_FLUXCM_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 720 ; encodage : cp1252 (repli). SHA-256 : `6e06c5b7dca4ea8adc2403483a27735fe2e82704183d5795bbfd28d75484faf2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `check_setup` | 158 |
| `Get_Info` | 181 |
| `Get_Old_Asset` | 316 |
| `Val_Debut_Periode` | 402 |
| `Val_Fin_Periode` | 507 |
| `Main` | 565 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `per_security_profiles` | 60 |
| `per_organization_list` | 61 |
| `hr_operating_units` | 62 |
| `FND_ID_FLEX_SEGMENTS_VL` | 71 |
| `FND_FLEX_VALUES_VL` | 72 |
| `fnd_flex_values_vl` | 81 |
| `fnd_flex_value_sets` | 82 |
| `fa_asset_invoices` | 87 |
| `Fa_Books` | 116 |
| `Fa_Book_Controls` | 117 |
| `Fa_Additions` | 118 |
| `FA_CATEGORIES_B_KFV` | 119 |
| `rub_principale` | 120 |
| `Fa_Transaction_Headers` | 121 |
| `Fa_Asset_History` | 125 |
| `Fa_Category_Books` | 128 |
| `Gl_Code_Combinations` | 130 |
| `Fa_Distribution_History` | 131 |
| `Gl_Code_Combinations` | 134 |
| `assets` | 135 |
| `pa_tasks` | 136 |
| `Pa_Projects_All` | 137 |
| `compte_local` | 138 |
| `regions` | 141 |
| `Fa_Transaction_Headers` | 143 |
| `Fa_Book_Controls` | 200 |
| `Fa_Deprn_Periods` | 221 |
| `Fa_Calendar_Periods` | 225 |
| `Fa_Deprn_Periods` | 251 |
| `Fa_Calendar_Periods` | 255 |
| `Dka_Stransco_Headers` | 279 |
| `Fa_Asset_Invoices` | 334 |
| `Fa_Additions_B` | 349 |
| `Fa_Book_Controls` | 368 |
| `Fa_Deprn_Detail` | 413 |
| `Fa_Deprn_Detail` | 427 |
| `Fa_Deprn_Detail` | 447 |
| `Fa_Transaction_Headers` | 467 |
| `Fa_Deprn_Detail` | 516 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.check_directory` | 162 |
| `dka_tools_pkg.check_value_set` | 165 |
| `Dka_Tools_Pkg.Put_Log_Message` | 188 |
| `Dka_Tools_Pkg.Put_Log_Message` | 189 |
| `Dka_Tools_Pkg.Put_Log_Message` | 190 |
| `Dka_Tools_Pkg.Put_Log_Message` | 191 |
| `Dka_Tools_Pkg.Put_Log_Message` | 204 |
| `Dka_Tools_Pkg.Put_Log_Message` | 208 |
| `Dka_Tools_Pkg.Put_Log_Message` | 229 |
| `Dka_Tools_Pkg.Put_Log_Message` | 230 |
| `Dka_Tools_Pkg.Put_Log_Message` | 231 |
| `Dka_Tools_Pkg.Put_Log_Message` | 236 |
| `Dka_Tools_Pkg.Put_Log_Message` | 259 |
| `Dka_Tools_Pkg.Put_Log_Message` | 260 |
| `Dka_Tools_Pkg.Put_Log_Message` | 261 |
| `Dka_Tools_Pkg.Put_Log_Message` | 266 |
| `Dka_Tools_Pkg.Put_Log_Message` | 288 |
| `Dka_Tools_Pkg.Put_Log_Message` | 289 |
| `Dka_Tools_Pkg.Put_Log_Message` | 292 |
| `Dka_Tools_Pkg.Put_Log_Message` | 293 |
| `Dka_Tools_Pkg.Put_Log_Message` | 322 |
| `Dka_Tools_Pkg.Put_Log_Message` | 323 |
| `Dka_Tools_Pkg.Put_Log_Message` | 324 |
| `Dka_Tools_Pkg.Put_Log_Message` | 325 |
| `Dka_Tools_Pkg.Put_Log_Message` | 326 |
| `Dka_Tools_Pkg.Put_Log_Message` | 340 |
| `Dka_Tools_Pkg.Put_Log_Message` | 360 |
| `Dka_Tools_Pkg.Put_Log_Message` | 361 |
| `Dka_Tools_Pkg.Put_Log_Message` | 375 |
| `Dka_Tools_Pkg.Put_Log_Message` | 383 |
| `Dka_Tools_Pkg.Put_Log_Message` | 384 |
| `Dka_Tools_Pkg.Put_Log_Message` | 386 |
| `Dka_Tools_Pkg.Put_Log_Message` | 436 |
| `Dka_Tools_Pkg.Put_Log_Message` | 437 |
| `Dka_Tools_Pkg.Put_Log_Message` | 438 |
| `Dka_Tools_Pkg.Put_Log_Message` | 439 |
| `Dka_Tools_Pkg.Put_Log_Message` | 456 |
| `Dka_Tools_Pkg.Put_Log_Message` | 474 |
| `Dka_Tools_Pkg.Put_Log_Message` | 479 |
| `Dka_Tools_Pkg.Put_Log_Message` | 487 |
| `Dka_Tools_Pkg.Put_Log_Message` | 488 |
| `Dka_Tools_Pkg.Put_Log_Message` | 526 |
| `Dka_Tools_Pkg.Put_Log_Message` | 527 |
| `Dka_Tools_Pkg.Put_Log_Message` | 528 |
| `Dka_Tools_Pkg.Put_Log_Message` | 529 |
| `Dka_Tools_Pkg.Put_Log_Message` | 536 |
| `Dka_Tools_Pkg.Put_Log_Message` | 537 |
| `Dka_Tools_Pkg.Put_Log_Message` | 584 |
| `Dka_Tools_Pkg.Put_Log_Message` | 585 |
| `Dka_Tools_Pkg.Put_Log_Message` | 586 |
| `Fnd_Profile.Value` | 593 |
| `fnd_profile.value` | 597 |
| `Dka_Tools_Pkg.Put_Log_Message` | 630 |
| `Dka_Tools_Pkg.Put_Log_Message` | 702 |
| `Dka_Tools_Pkg.Put_Log_Message` | 703 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 207, 235, 265, 377, 453, 709 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IFA_FLUXCM / DKA | `DKA_IFA_FLUXCM_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IFA_FLUXCM.prt:497 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
