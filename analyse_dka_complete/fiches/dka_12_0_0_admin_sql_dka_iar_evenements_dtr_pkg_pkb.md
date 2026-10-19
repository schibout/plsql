# DKA_IAR_EVENEMENTS_DTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1014 ; encodage : cp1252 (repli). SHA-256 : `f0d613a833c5ad8a40bb7e2f95ea74e12ea652008edeb8e944a2412bfc87519e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 43 |
| `p_validate` | 60 |
| `p_check_directory` | 83 |
| `p_extract_data` | 117 |
| `p_extract_data` | 826 |
| `p_extract_data` | 876 |
| `output_header` | 890 |
| `p_bilan` | 933 |
| `main` | 968 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 86 |
| `dual` | 200 |
| `ar.ra_customer_trx_all` | 306 |
| `ar.ra_customer_trx_all` | 431 |
| `ar.ar_payment_schedules_all` | 532 |
| `ar.ra_customer_trx_all` | 551 |
| `ar.ar_adjustments_all` | 624 |
| `ar.ar_payment_schedules_all` | 711 |
| `ar.ar_payment_schedules_all` | 797 |
| `fnd_concurrent_programs` | 902 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 47 |
| `Fnd_File.put_line` | 823 |
| `Fnd_File.put_line` | 824 |
| `Fnd_File.put_line` | 825 |
| `Fnd_File.put_line` | 839 |
| `Fnd_File.put_line` | 858 |
| `Fnd_File.put_line` | 861 |
| `Fnd_File.put_line` | 914 |
| `Fnd_File.put_line` | 915 |
| `Fnd_File.put_line` | 917 |
| `Fnd_File.put_line` | 919 |
| `Fnd_File.put_line` | 922 |
| `Fnd_File.put_line` | 937 |
| `Fnd_File.put_line` | 938 |
| `Fnd_File.put_line` | 939 |
| `Fnd_File.put_line` | 940 |
| `Fnd_File.put_line` | 941 |
| `Fnd_File.put_line` | 942 |
| `Fnd_File.put_line` | 943 |
| `Fnd_File.put_line` | 946 |
| `Fnd_File.put_line` | 947 |
| `Fnd_File.put_line` | 948 |
| `Fnd_File.put_line` | 951 |
| `Fnd_File.put_line` | 953 |
| `Fnd_File.put_line` | 979 |
| `fnd_date.canonical_to_date` | 984 |
| `fnd_date.canonical_to_date` | 985 |
| `Fnd_File.put_line` | 991 |
| `Fnd_File.put_line` | 999 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 864 |
| when_others | 875, 909, 1006 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAR_EVENEMENTS_DTR / DKA | `DKA_IAR_EVENEMENTS_DTR_PKG.main` | dka/12.0.0/admin/import/DKA_IAR_EVENEMENTS_DTR.prt:475 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
