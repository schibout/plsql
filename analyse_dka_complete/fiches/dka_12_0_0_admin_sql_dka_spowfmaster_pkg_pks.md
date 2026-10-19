# DKA_SPOWFMASTER_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOWFMASTER_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOWFMASTER_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 636 ; encodage : cp1252 (repli). SHA-256 : `708bcd1487f0b1fad9294f29f42cbe7f6aeec610c1630eeec88c4f820a122d6e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `lance_approbation` | 44 |
| `cree_commande` | 61 |
| `cree_reception` | 78 |
| `recup_commande` | 93 |
| `archivage_contrat` | 107 |
| `diminution_quantite` | 123 |
| `diminution_quantite_facture` | 139 |
| `reception_quantite` | 154 |
| `lance_workflow_maitre` | 171 |
| `lance_wf_modif_approbation` | 186 |
| `lance_wf_resil_annule` | 201 |
| `get_montant_imput` | 214 |
| `get_montant_presta_unit` | 226 |
| `test_modif_champ` | 238 |
| `controle_statut` | 252 |
| `modif_statut_incomplet` | 268 |
| `modif_statut_approuve` | 284 |
| `verif_date_resiliation` | 300 |
| `verif_exist_facture` | 316 |
| `archivage_date_resiliation` | 333 |
| `approve_version_commande` | 349 |
| `mise_a_jour_action_noneffec` | 364 |
| `mise_a_jour_action_resiliation` | 380 |
| `mise_a_jour_statut_appro` | 397 |
| `action_fermer` | 413 |
| `modif_statut_nouvelle_appro` | 430 |
| `annuler_commande_sans_facture` | 449 |
| `log_msg` | 464 |
| `init` | 477 |
| `get_message_mail` | 498 |
| `search_id_destinataire_mail` | 527 |
| `search_mail` | 555 |
| `mail_notification` | 580 |
| `envoi_notif_mail` | 604 |
| `active_desactive_site_four` | 627 |

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
