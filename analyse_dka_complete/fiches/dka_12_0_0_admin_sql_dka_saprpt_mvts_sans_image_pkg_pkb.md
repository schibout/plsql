# DKA_SAPRPT_MVTS_SANS_IMAGE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPRPT_MVTS_SANS_IMAGE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPRPT_MVTS_SANS_IMAGE_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 308 ; encodage : cp1252 (repli). SHA-256 : `f4bdc51ff77d4564149b962c7193162a40001f5ce29f11ccac827aed672227aa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `clear_tmp_table` | 42 |
| `Load_data` | 65 |
| `Launch_report` | 232 |
| `Main` | 268 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SAPMVTSANSIMAGE_TMP` | 46 |
| `DKA_SAPMVTSANSIMAGE_TMP` | 71 |
| `ap_invoices_all` | 88 |
| `dka_stransco_headers` | 95 |
| `DKA_STRANSCO_LINES` | 114 |
| `DKA_STRANSCO_HEADERS` | 116 |
| `fnd_attached_documents` | 126 |
| `ap_invoices_interface` | 159 |
| `dka_stransco_headers` | 169 |
| `DKA_STRANSCO_HEADERS` | 184 |
| `fnd_attached_documents` | 198 |
| `DKA_SAPMVTSANSIMAGE_TMP` | 237 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.PUT_LINE` | 243 |
| `fnd_file.PUT_LINE` | 245 |
| `fnd_file.PUT` | 249 |
| `fnd_file.PUT` | 250 |
| `fnd_file.put_line` | 251 |
| `fnd_file.put_line` | 256 |
| `fnd_file.put_line` | 278 |
| `fnd_file.put_line` | 286 |
| `fnd_file.put_line` | 294 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 49, 215 |
| when_others | 52, 218, 255, 300 |
| suppression | 46 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
