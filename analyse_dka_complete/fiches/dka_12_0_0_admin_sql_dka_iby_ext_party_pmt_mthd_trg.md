# dka_iby_ext_party_pmt_mthd.trg

Source : [dka/12.0.0/admin/sql/dka_iby_ext_party_pmt_mthd.trg](../../dka/12.0.0/admin/sql/dka_iby_ext_party_pmt_mthd.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 101 ; encodage : cp1252 (repli). SHA-256 : `78196528ed20000ba0398d337d0fb8db305971b2ab7d74947f64431805bab497`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `iby_ext_party_pmt_mthds` | 20 |
| `dka_iby_ext_party_pmt_mthd` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_site_id` | 39 |
| `dka_sapfrs_history_pkg.get_vendor_id` | 40 |
| `dka_sapfrs_history_pkg.get_payement_method` | 41 |
| `dka_sapfrs_history_pkg.get_user_name` | 49 |
| `dka_sapfrs_history_pkg.insert_supplier_mode_p` | 58 |
| `dka_sapfrs_history_pkg.insert_supplier_mode_p` | 69 |
| `dka_sapfrs_history_pkg.insert_supplier_mode_p` | 80 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 95 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
