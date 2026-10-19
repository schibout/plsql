# Routage documentaire DKA

Chemins de commande et chemins cités dans les tableaux : relatifs à la racine du dépôt. Les liens Markdown de ce fichier pointent vers les documents réels. Lire le contexte court, une note pertinente, puis les extraits sources nécessaires ; ne pas charger tout le dossier.

| Question | Première lecture | Pour établir les détails |
|---|---|---|
| Architecture, périmètre, vocabulaire | [Synthèse DKA](../../analyse_dka_complete/00_synthese_et_architecture.md) | [Couverture et limites](../../analyse_dka_complete/07_couverture_et_ecarts.md) |
| AP, AR, GL, PO, PA, RH, FA, CE, imports/exports, IFS, EAI, fusions | [Intégrations](../../analyse_dka_complete/02_integrations.md) | Package `.pks/.pkb`, chargeur, lanceur et programme FND correspondant |
| Approbation, CSP/BAP, contrat, commande, réception, notifications, timeout | [Workflows](../../analyse_dka_complete/03_workflows.md) | [Transitions](../../analyse_dka_complete/03a_workflows_transitions.md), export `.wft` et callback `.pkb` |
| Clôtures, paiements, prélèvements, recouvrement, hooks, reprises | [Traitements spécifiques](../../analyse_dka_complete/04_traitements_specifiques.md) | [Compléments](../../analyse_dka_complete/04a_traitements_complementaires.md), source et paramètres |
| TVA, XLA, exports fournisseurs, banques, création de compte | [Composants complémentaires](../../analyse_dka_complete/04a_traitements_complementaires.md) | Signatures, effets SQL, fichiers et API appelées |
| Nom court/libellé concurrent, exécutable, point d’entrée | [Programmes FND](../../analyse_dka_complete/05_programmes_et_orchestration.md) | `programmes_concurrents.json`, puis `.prt/.ldt` source |
| Valeur d’un paramètre ou segment SRS | [Paramètres](../../analyse_dka_complete/05a_parametres.md) | `parametres.json`, `.dpt/.prt/.ldt` source ; ne pas l’assimiler à la valeur de production |
| Trouver un fichier, une copie ou une fiche | [Inventaire CSV](../../analyse_dka_complete/inventaire_complet.csv) | [Catalogue](../../analyse_dka_complete/01_catalogue_complet.md), `inventaire_complet.json` |
| Appel ou dépendance | `analyse_dka_complete/dependances.json` | [Graphe DKA](../../analyse_dka_complete/graphify-out/GRAPH_REPORT.md), puis la référence source |
| Anomalie de facture, avoirs, doublons, images et dashboard historiques | [Premier dossier facturation](../../analyse_integration_facturation/README.md) | Comparer explicitement la variante historique avec `dka/` |
| Recette, exploitation et critères de réussite | [Plan de validation](../../analyse_dka_complete/06_exploitation_et_validation.md) | Contrats de flux, environnement et résultats réels à obtenir |
| Fichiers nouveaux ou modifiés, rapport devenu ancien | [Actualisation](ACTUALISATION.md) | Vérification de fraîcheur avant régénération |

## Recherches ciblées

```powershell
rg --files dka | rg 'IAPFAC_IVALUA|SAPWFCSP|SPOWFMASTER'
rg -n 'DKA_IAPFAC_IVALUA|DKA_SAPWFCSP' analyse_dka_complete/02_integrations.md analyse_dka_complete/03_workflows.md
rg -n 'SUBMIT_REQUEST|COMMIT|ROLLBACK|autonomous_transaction|UTL_FILE' dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb
```

Une recherche renvoie des candidats, pas une preuve d’exécution. Lire la routine et ses conditions, notamment les exceptions. Le graphe agrège des relations lexicales et de configuration : les appels dynamiques peuvent manquer, les composants isolés ne sont pas nécessairement indépendants.

## Réponse attendue

Donner d’abord le comportement ou le diagnostic utile, puis les étapes et objets concernés avec preuves `chemin:ligne`. Décrire les points de reprise ou les limites seulement s’ils affectent la question. Ne pas annoncer un état de production ni un déploiement sans preuve fournie par l’environnement.
