# DKA_SAPDAS2_PKG.pkb

Source : [dka/12.0.0/sql/DKA_SAPDAS2_PKG.pkb](../../dka/12.0.0/sql/DKA_SAPDAS2_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2255 ; encodage : cp1252 (repli). SHA-256 : `376ec2e8b84e1a5f7317cd56bc3aa0a88680d8609ffe734748340f001d3ce91f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Put_Out_Message` | 50 |
| `Put_Log_Message` | 68 |
| `Est_Numerique` | 90 |
| `Conversion_Chaine` | 121 |
| `Extract_Data` | 176 |
| `Control_Data` | 520 |
| `Debut_Message` | 1083 |
| `Controle_Siren` | 1104 |
| `Controle_Raison_Sociale` | 1142 |
| `Controle_Adresse_Comp` | 1168 |
| `Controle_Adresse_Voie` | 1187 |
| `Controle_Code_Insee` | 1207 |
| `Controle_Commune` | 1227 |
| `Controle_Code_Postal` | 1252 |
| `Controle_Bureau_Distributeur` | 1293 |
| `Controle_Siret` | 1322 |
| `Controle_Nic` | 1369 |
| `Controle_Nom` | 1412 |
| `Controle_Prenom` | 1433 |
| `Controle_Profession` | 1454 |
| `Controle_Nom_Prenom` | 1476 |
| `Controle_Nom_Raison_Sociale` | 1500 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Dual` | 97 |
| `Dual` | 141 |
| `Dka_Sapdas2_010` | 213 |
| `Dka_Sapdas2_020` | 246 |
| `Dka_Sapdas2_210` | 296 |
| `Dka_Sapdas2_300` | 370 |
| `Dka_Sapdas2_310` | 409 |
| `Ap_Reporting_Entities_All` | 594 |
| `Ap_Reporting_Entities_All` | 634 |
| `Ap_Reporting_Entities_All` | 896 |
| `Po_Vendor_Contacts` | 928 |
| `Dual` | 934 |
| `Dka_Sapdas2_020` | 998 |
| `Dka_Sapdas2_210` | 1010 |
| `Dka_Sapdas2_010` | 1051 |
| `Dka_Sapdas2_020` | 1053 |
| `Dka_Sapdas2_210` | 1066 |
| `Dual` | 1092 |
| `Dka_Sapdas2_010` | 1549 |
| `Fnd_Concurrent_Requests` | 1551 |
| `Dka_Sapdas2_020` | 1555 |
| `Fnd_Concurrent_Requests` | 1557 |
| `Dka_Sapdas2_210` | 1561 |
| `Fnd_Concurrent_Requests` | 1563 |
| `Dka_Sapdas2_300` | 1567 |
| `Fnd_Concurrent_Requests` | 1569 |
| `Dka_Sapdas2_310` | 1573 |
| `Fnd_Concurrent_Requests` | 1575 |
| `Dka_Sapdas2_010` | 1651 |
| `Dka_Sapdas2_020` | 1774 |
| `Dka_Sapdas2_210` | 1931 |
| `Dka_Sapdas2_210` | 2019 |
| `Dka_Sapdas2_300` | 2060 |
| `Dka_Sapdas2_310` | 2131 |
| `Dka_Sapdas2_010` | 2220 |
| `Dka_Sapdas2_020` | 2223 |
| `Dka_Sapdas2_210` | 2226 |
| `Dka_Sapdas2_300` | 2229 |
| `Dka_Sapdas2_310` | 2232 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.Put_Line` | 53 |
| `Fnd_File.Put_Line` | 73 |
| `Fnd_File.Put_Line` | 75 |
| `dka_tools_pkg.get_parameter` | 1533 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1536 |
| `Dka_Tools_Pkg.put_log_message` | 1542 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 2172, 2236 |
| when_others | 106, 2247 |
| suppression | 1549, 1555, 1561, 1567, 1573, 2220, 2223, 2226, 2229, 2232 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL.prt:664 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL.prt:664 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL.prt:664 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL.prt:664 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL.prt:664 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_F.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_F.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_F.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_F.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_F.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_US.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_US.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_US.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_US.prt:643 |
| DKA_SAPDAS2_CTL / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_CTL_US.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_F.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_F.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_F.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_F.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_F.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_US.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_US.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_US.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_US.prt:643 |
| DKA_SAPDAS2_GEN / DKA | `DKA_SAPDAS2_PKG.Control_Data` | dka/12.0.0/admin/import/DKA_SAPDAS2_GEN_US.prt:643 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
