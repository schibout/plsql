# Workflows DKA — circuits, comptabilisation et exploitation

Analyse statique des 12 exports `.wft` de `dka/12.0.0/admin/import` et des packages associés. Les exports contiennent **1 383 définitions d’activité et 244 processus**, y compris des bibliothèques Oracle et des versions anciennes ; ces nombres ne représentent pas 244 workflows déployés ou utilisés. L’[annexe des transitions](03a_workflows_transitions.md) restitue tous les processus exportés, instances, résultats, cibles, rôles, délais et callbacks, avec leurs lignes sources. La [structure JSON](workflow_structure.json) conserve également attributs, messages et objets exportés.

## 1. Inventaire exhaustif des exports

| Export | Activités | Processus | Instances dans les processus | Fonction démontrée par le contenu |
|---|---:|---:|---:|---|
| DKA_APINVAPR.wft | 90 | 5 | 76 | Approbation AP, bifurcation spécifique CSP / approbation automatique |
| DKA_FAFLEXWF.wft | 69 | 14 | 129 | Génération de combinaisons comptables immobilisations |
| DKA_PAAPINVW.wft | 67 | 7 | 83 | Génération des comptes AP projet |
| DKA_PAAPWEBX.wft | 65 | 6 | 75 | Génération des comptes de dépenses salariés AP |
| DKA_POWFPOAG.wft | 150 | 43 | 426 | Génération des comptes commandes PO |
| DKA_POWFRQAG.wft | 135 | 34 | 339 | Génération des comptes demandes d’achat |
| DKA_SAPWFCSP.wft | 177 | 27 | 540 | Anomalies factures OI/AP, BAP, imputation, Ivalua, notifications et erreurs |
| DKA_SEND_NOTIF.wft | 33 | 1 | 3 | Notification générique à destinataire porté par attribut |
| DKA_SPOBON_POAPPRV.wft | 445 | 104 | 1 324 | Approbation et communication PO, adaptations DKA, synchronisation contrat/commande |
| DKA_SPOWFAPPRO.wft | 48 | 1 | 30 | Modification et réapprobation contrat/commande, correction de réception |
| DKA_SPOWFMASTER.wft | 46 | 1 | 24 | Orchestration contrat → commande → réception |
| DKA_SPOWFRESIL.wft | 58 | 1 | 28 | Résiliation/annulation, ajustements réception/commande |

Les instances de bibliothèque peuvent être exportées dans plusieurs fichiers. Les activités déclarées mais non atteignables depuis le départ d’un processus ne sont pas des étapes de son parcours effectif. Exemple déterminant : `APPROVAL_MAIN` contient encore les activités standard AME mais son `START` part vers `DKA_FACT_PERIM_CSP` (`DKA_APINVAPR.wft:5236`). Les fichiers sources de cette section sont tous sous `dka/12.0.0/admin/import/` ; les packages sont sous `dka/12.0.0/admin/sql/` et les lanceurs sous `dka/12.0.0/sql/`.

## 2. Entrée facturation AP : substitution du parcours principal

Le parcours effectif de `APINVAPR.APPROVAL_MAIN` est :

```text
START → DKA_FACT_PERIM_CSP
  N → DKA_APPROVE_AP → END-3
  Y → DKA_IMAGE_EXIST
       N → END-3
       Y → DKA_LANCE_WK_CSP → END-3 (#ANY)
```

Sources : `DKA_APINVAPR.wft:5236`, `:5248`, `:5259`, `:5270`, `:5285`. Les autres boucles standard de collecte des approbateurs sont présentes dans le même export (`:5050`) mais ne sont pas reliées à ce départ. Il faut donc analyser le graphe, sans conclure à un passage AME systématique parce que les activités sont dans le fichier.

Les callbacks sont `DKA_SAPIAWIE_PKG.is_facture_perimetre_CSP`, `.Invoice_image_exists`, `.approuve_facture_auto`, `.lance_workflow_CSP` (`DKA_APINVAPR.wft:7792`, `:7806`, `:7820`, `:7835`). Le périmètre CSP combine réellement : source `SCAN_XGS`, `SCAN` ou `Manual Invoice Entry` ; couple division/région actif dans la transcodification `CENTRE_SERVICE_PARTAGE` ; facture `STANDARD` ou `CREDIT` ; catégorie documentaire ne correspondant pas à `%REPRISE%`. Division et région proviennent respectivement d’`HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE10` et des trois premiers caractères du nom d’organisation (`DKA_SAPIAWIE_PKG.pkb:85`). Une catégorie nulle ne rend pas vraie la condition SQL `NOT LIKE` : cas à tester.

L’approbation automatique effectue des mises à jour directes : `AP_INVOICES_ALL.WFAPPROVAL_STATUS='WFAPPROVED'`, lignes `INITIATED`, `NEEDS WFREAPPROVAL` ou `WFAPPROVED` vers `NOT REQUIRED`, puis insertion dans `AP_INV_APRVL_HIST` (`DKA_SAPIAWIE_PKG.pkb:232`, historique `:157`). C’est un traitement spécifique de statut et d’historisation, pas une preuve de validation comptable ou de paiement.

Le lancement CSP crée `DKA_CSP.DKA_PROCESS_AP`, construit une clé `invoice_id || '_' || séquence DKA_SAPWFCSP_S`, associe le parent AP, renseigne `INVOICE_ID`, démarre et commit (`DKA_SAPIAWIE_PKG.pkb:317`). Son exception transforme toute erreur en `COMPLETE:FAIL` sans relancer l’exception (`:377`) ; la transition `#ANY` termine ensuite le processus AP (`DKA_APINVAPR.wft:5265`). **Risque concret : une fin de workflow AP ne suffit pas à prouver que le workflow CSP a été créé.** Il faut vérifier l’existence de l’enfant, ses attributs et son état.

Le contrôle d’image a sa propre logique d’exclusions et de données : ne pas remplacer cette décision par le seul test d’une URL dans une analyse fonctionnelle (`DKA_SAPIAWIE_PKG.pkb:390`). La branche `N` termine sans lancement CSP dans cet export ; le mécanisme de reprise de l’arrivée d’image doit être vérifié avec les traitements d’images et les paramètres d’exploitation.

## 3. Circuit CSP OI/AP et Ivalua

### 3.1 Deux points d’entrée et une clé de suivi

`lance_workflow_CSP_PL` sélectionne `DKA_PROCESS_OI` si `pn_fact_AP_OI=0`, sinon `DKA_PROCESS_AP`, attribue respectivement `INVOICE_OI_ID` ou `INVOICE_ID`, crée une clé facture/séquence, démarre et commit (`DKA_SAPWFCSP_PKG.pkb:8575`). L’association parent est commentée dans cette variante ; elle est active dans le lanceur depuis AP décrit plus haut. Il ne faut donc pas imposer la présence d’un parent à toutes les instances CSP.

| Entrée | Parcours effectif | Échec |
|---|---|---|
| `DKA_PROCESS_AP` | START → initialisation AP → duplication des codes blocages OI/AP → sous-processus `DKA_ANOMALIE_AP` → END | `FAIL` de l’initialisation → `WFERROR.ABORTPROCESS` |
| `DKA_PROCESS_OI` | START → initialisation OI → `DKA_FACT_TRAITEE_OI` ; `Y` → END ; `N` → `DKA_FACT_BLOQ_OI` → END-1 | `FAIL` de l’initialisation → `WFERROR.ABORTPROCESS` |

Sources : `DKA_SAPWFCSP.wft:21426`, `:21504`. Les fonctions liées sont `initialise_workflow_AP`, `initialise_workflow_OI`, `transfert_codes_blocages_OI_AP`, `facture_OI` (`:20978`, `:20992`, `:19070`, `:19487`).

### 3.2 Tous les sous-processus métier CSP exportés

| Processus | Ligne dans DKA_SAPWFCSP.wft | Objet du circuit décrit par les activités exportées |
|---|---:|---|
| `DKA_ANO_IMPUT_ATTENTE` | 15454 | Imputation en attente, notification CSP / valideur et reprise de réponse |
| `DKA_ANOMALIE_AFFACT` | 16655 | Affacturage et refus/transmission CSP |
| `DKA_ANOMALIE_AP` | 16926 | Orchestration anomalie AP |
| `DKA_ANOMALIE_BLOC_DIVERS` | 16970 | Blocages divers |
| `DKA_ANOMALIE_CMD_MULTI` | 17123 | Commandes multiples |
| `DKA_ANOMALIE_FRN_ABS` | 17455 | Fournisseur absent |
| `DKA_ANOMALIE_PRLV` | 17528 | Prélèvement |
| `DKA_ANOMALIE_QTY_ORD` | 17723 | Écart quantité commandée, CSP / acheteur / hiérarchie |
| `DKA_ANOMALIE_QTY_REC` | 18261 | Écart quantité reçue, demandeur/exploitant |
| `DKA_ANOMALIE_RIB` | 18823 | RIB |
| `DKA_FACT_BLOQ_OI` | 19168 | Routage des factures bloquées OI |
| `DKA_FACT_OI_AP` | 19431 | Passage du contexte OI au traitement AP |
| `DKA_FACTURE_MANUELLE` | 19501 | Circuit de facture manuelle |
| `DKA_IMPOSE_BAP` | 20447 | Habilitation et validation BAP |
| `DKA_ANOMALIE_ECART_PRIX` | 23848 | Écart prix, acheteur régional, habilitations et réponses |
| `DKA_ANO_IMPUT_ATTENTE_OLD` | 25032 | Version ancienne conservée dans l’export ; usage non démontré |
| `DKA_BLOCAGE_IVALUA_ATTENTE` | 25934 | Traitement du retour Ivalua et blocage en attente |
| `DKA_ANOMALIE_ECART_PRIX_IVALUA` | 26296 | Écart prix Ivalua |
| `DKA_ANOMALIE_QTY_REC_IVALUA` | 26881 | Quantité reçue Ivalua |
| `DKA_ANOMALIE_QTY_ORD_IV` | 27219 | Quantité commandée Ivalua |

Ce tableau sert de catalogue ; la séquence exacte de chaque circuit, ses résultats et cibles figurent dans l’annexe. Il ne permet pas de conclure que toute anomalie reçoit tous ces traitements. Les processus `WFERROR.DEFAULT_ERROR`, `DEFAULT_EVENT_ERROR`, `HR_STANDARD_ERROR_PRC`, `RETRY_ONLY` sont également exportés (`:22877`, `:23085`, `:23446`, `:23599`).

### 3.3 Notifications, rôles et relances

Les instances de notification CSP portent réellement des rôles par attribut : `DKA_RESP_CSP_ANO` (ex. `:15910`), `VALIDEUR_BAP` (`:15931`), `DKA_RESP_CSP_REF` (`:16871`), `DKA_HIERAR_ACHETEUR_COMMANDE` (`:18140`), `DKA_CHEF_EXPLOT_QTY_REC` (`:18691`), `DKA_ACHETEUR_COMMANDE` (`:18733`), `DKA_ACHETEUR_REGION_COMMANDE` (`:24112`). Les délais sont lus dans `DUREE_AVANT_TIMEOUT_EXP` et `DUREE_AVANT_TIMEOUT_CSP` (`:15938`, `:15917`). Les valeurs effectives et les personnes destinataires ne sont pas connues sans paramètres et annuaire Workflow déployés.

Les callbacks de notification ne sont pas tous de simples envois : l’export relie les réponses à des procédures telles que `notif_CSP_ANO_QTY_ORD`, `notif_CSP_ANO_QTY_REC`, `notif_CSP_ANO_PRICE`, `notif_EXPLOIT_BAP`, aux contrôles `employe_price_habilitation`, `employe_qty_ord_habilitation`, `employe_Droit_habilitation`, et à `reponse_notif_precedente` (`DKA_SAPWFCSP.wft:21050`, `:21065`, `:21142`, `:21307`, `:20400`, `:20416`, `:20432`, `:15091`). Leur corps et le mode `funcmode` doivent être conservés lors d’une migration de workflow.

Le fichier contient aussi des instances `SYSADMIN` et un rôle constant `KH PO 1` (`:22453`). Cela justifie un contrôle des références exportées et de leur atteignabilité ; cela ne prouve pas qu’une notification métier actuelle est envoyée à ce rôle de test.

### 3.4 Parcours Ivalua effectivement déclaré

`DKA_BLOCAGE_IVALUA_ATTENTE` initialise AP, historise, lit la réponse Ivalua ; `DKA_GET_BLOCAGE_IVALUA` mène directement à la levée de blocage si `Y`, sinon à la préparation de notification. Si le blocage existe, la notification CSP attend `SOUMETTRE`, ou boucle par `RELANCE` en cas de `#TIMEOUT`. La réponse mène à `DKA_RELEASE_HOLD_NULL`, puis `TRAITEMENT_BLOCAGE_IVALUA`. Un échec mène à `ABORTPROCESS`. Ensuite, absence d’autre blocage → `DKA_APPROVE_AP` → `DKA_ABORT_PREV_WKF` → END ; présence → END. Sources : `DKA_SAPWFCSP.wft:25934`, `:26017`, `:26057`, `:26080`, `:26114`, `:26142`, `:26199`.

Ces activités utilisent `DKA_SAPWFCSP_IVALUA_PKG.pre_notification_ivalua`, `.notif_reponse_ivalua`, `.traitement_blocage_ivalua`, `.debloque_null`, `.insert_history_wf_ivalua`, `.get_reponse_blocage_ivalua` (`:25919`, `:26215`, `:26230`, `:26244`, `:26843`, `:27534`). Les corps existent dans `DKA_SAPWFCSP_IVALUA_PKG.pkb:1163`, `:2056`, `:2198`, `:2597`, `:3040`, `:3427`.

Le circuit démontre un retour de décision et un traitement local des blocages. Il ne démontre pas, à lui seul, le transport réseau, la cadence de réception ni la complétude des réponses externes : rapprocher les traitements d’intégration Ivalua et les historiques.

## 4. Contrats, commandes et réceptions : orchestration maître

### 4.1 Déclenchement et contexte

`DKA_SPOWFMASTER_PKG.lance_workflow_maitre` crée `DKASPOMA.DKAPROCESSMAITRE` avec une clé concaténant contrat et séquence, lit l’organisation dans `PO_HEADERS_ALL`, renseigne `P_CONTRACT_ID`, `USER_ID`, `RESPONSIBILITY_ID`, `APPLICATION_ID`, `ORG_ID`, démarre et commit (`DKA_SPOWFMASTER_PKG.pkb:1186`). Les variantes `lance_wf_modif_approbation` et `lance_wf_resil_annule` créent les processus de modification/résiliation (`:1268`, `:1361`).

Le callback `lance_approbation` crée et démarre le processus enfant d’approbation PO (`DKA_SPOWFMASTER_PKG.pkb:153`, création `:308`, démarrage `:474`). Le processus `DKA_POAP.DKA_SPOMASTDTL` effectue un contrôle TP avant `DKA_POAPPRV_TOP`, puis deux `CONTINUEFLOW`, contrat et commande, réunis par `AND` (`DKA_SPOBON_POAPPRV.wft:46001`). Les attentes du maître utilisent explicitement `CONTINUATION_FLOW='DETAIL'` et `CONTINUATION_ACTIVITY='CONTINUEFLOW-CONTRAT'` (`DKA_SPOWFMASTER.wft:1989`). C’est une dépendance d’exécution entre workflows, pas une simple juxtaposition de traitements.

### 4.2 Création initiale

Dans `DKAPROCESSMAITRE`, START → affectation de l’identifiant contrat → lancement approbation → attente contrat → contrôle statut. `APPROVED` conduit à l’archivage, activation/désactivation site fournisseur, création commande, récupération commande, impression/fax, création réception, soumission programme concurrent et attente. Seul le résultat `NORMAL` de ce programme conduit au second traitement du site fournisseur et à la fin normale ; `ERROR`, `WARNING`, `CANCELLED`, `TERMINATED` terminent dans `END-7`. `REJECTED` déclenche modification du statut puis mail (`DKA_SPOWFMASTER.wft:1877`, `:1989`, `:2584`, `:2562`, `:2629`, `:1918`, `:2010`, `:2573`, `:2066`, `:2081`, `:2514`).

Les callbacks sont reliés à des corps exécutables : `cree_commande` (`DKA_SPOWFMASTER_PKG.pkb:520`), `recup_commande` (`:621`), `cree_reception` (`:741`), `archivage_contrat` (`:839`), fonctions déclarées dans l’export `DKA_SPOWFMASTER.wft:2652`, `:5195`, `:5209`, `:5223`. Les fonctions de commande/réception ont leurs dépendances propres dans les packages d’intégration ; une terminaison du workflow maître ne garantit donc pas à elle seule le résultat métier de chaque interface.

### 4.3 Modification et réapprobation

`DKASPAPR.DKAPROCESSAPPRO` réapprouve d’abord le contrat, attend son retour, contrôle `APPROVED/REJECTED`, archive puis teste la diminution de quantité. Si `Y`, correction de réception et deux programmes concurrents successifs ; leurs résultats non `NORMAL` vont à `END-FIN ANORMALE`. Ensuite modification de commande, seconde approbation, attente commande, test des quantités à recevoir, compléments de réception et autres programmes concurrents (`DKA_SPOWFAPPRO.wft:2878`, `:2932`, `:2947`, `:2958`, `:3438`, `:3470`, `:3489`, `:3504`, `:3966`, `:4006`).

Les callbacks de correction/complément utilisent `DKA_IPORECVTOTAL_PKG` et la modification `DKA_IPOGENCOM_PKG.modification_commande` (`DKA_SPOWFAPPRO.wft:5507`, `:7036`, `:7078`, `:7092`). Particularité à surveiller : tous les résultats du `WAITFORCONCPROG-5`, y compris `ERROR`, reprennent vers `DKA_SPO_COMPLEMENT_RECEPTION` (`:5415`). Une reprise métier est déclarée même après erreur technique ; il faut corréler le statut de demande concurrente et les quantités effectivement traitées.

### 4.4 Résiliation et annulation

`DKASPORE.DKAPROCESSRESIL` route selon le statut contrat : `INCOMPLETE` → modification statut → fin ; `RENOUVELLEMENT` → mise à jour statut, fermeture et mail ; `APPROVED` → traitement statut approuvé, contrôle date de résiliation. Si absence du critère de date, contrôle existence de facture : résultat `N` → annulation commande → édition/fax → mail ; `Y` → mail. Sinon archivage résiliation/contrat, diminution des quantités facturées, éventuelle correction de réception et programmes concurrents, modification et approbation de version commande, édition/fax puis action de résiliation et mail (`DKA_SPOWFRESIL.wft:4362`, `:4415`, `:4475`, `:4499`, `:4532`, `:5413`, `:5485`, `:5518`, `:5573`).

Les callbacks effectifs sont `verif_date_resiliation`, `verif_exist_facture`, `diminution_quantite_facture`, `approve_version_commande`, `annuler_commande_sans_facture` (`DKA_SPOWFRESIL.wft:6637`, `:5690`, `:5750`, `:6577`, `:6607`). Attention à une activité déclarée nommée `DKA_SPO_DATE_RESILIATION` mais liée à `verif_exist_facture` (`:5675`) : son nom seul ne décrit pas son effet et ne doit pas remplacer le mapping exact.

## 5. Approbation et communication des commandes

L’export `DKA_SPOBON_POAPPRV.wft` contient une bibliothèque volumineuse et plusieurs points d’entrée Oracle. Le parcours spécifique à considérer est `DKA_POAP.DKA_POAPPRV_TOP` (`:45602`), avec `DKA_MAIN_POAPPRV_PROCESS` (`:46128`), `DKA_APPROVE_PO_SUB_PROCESS` (`:47049`), `DKA_NOTIFY_APPROVER_PROCESS` (`:47418`), `DKA_NOTIFY_APPROVER_SUBPROCESS` (`:47857`) et `DKA_APPROVE_AND_FORWARD_PO` (`:48086`). Les processus standard restent présents ; leur utilisation réelle dépend du processus référencé au lancement et du paramétrage PO.

Le top spécifique démarre par retrait de rappel et initialisation. Après acquisition des données, il distingue nouveau document, archivage et règles de réapprobation. Les branches contrôlent la réservation avant approbation et les actions valides. Après notification d’approbation au `PREPARER_USER_NAME`, le test `DKA_IS_IVALUA_ORDER` termine sur `Y`, tandis que `N` mène au contrôle commande SPP puis au parcours impression/fax (`:45883`, `:45978`, `:45682`, `:45697`, `:45708`). **L’édition/fax ne doit pas être supposée commune aux commandes Ivalua et aux autres commandes.**

Les adaptations déclarées appellent `DKA_SPOWFAPPRV_PKG.alim_description_contrat_sstr` et `.REGISTER_DOC_SUBMITTED`, `DKA_SPOBON_WF_PKG.IS_ORDER_SSP_APPROVED`, `.PRINT_AND_FAX_ORDER_PDF`, `.PRINT_ORDER_PDF`, `.last_approb_da`, `.is_ivalua_order`, ainsi que `DKA_SFNDCLOSETP_WF_PKG.is_close_TP` (`:45407`, `:45499`, `:45453`, `:45469`, `:45484`, `:47035`, `:48366`, `:45438`). Ces callbacks relient le workflow à des éditions et règles spécifiques ; les programmes d’impression et les canaux externes restent des dépendances à vérifier dans l’environnement.

## 6. Génération comptable : cinq exports distincts

Il s’agit de moteurs de génération de combinaisons, comportant des sous-processus `RUNNABLE=N`, des points d’entrée `RUNNABLE=Y`, des validations de flexfield et des sorties `SUCCESS/FAILURE`. Ce ne sont pas des circuits d’approbation humaine.

| Domaine | Point d’entrée DKA et source | Traitement visible |
|---|---|---|
| AP projet | `PAAPINVW.DKA_AP_ACCOUNT_GENERATION_TOP`, DKA_PAAPINVW.wft:6485 | START_GENERATION → sous-processus DKA ; SUCCESS → validation combinaison → END_GENERATION ; FAILURE → ABORT_GENERATION |
| Dépenses salariés | `PAAPWEBX.DKA_AP_EMP_ACCOUNT_GENERATION`, DKA_PAAPWEBX.wft:5949 | Même structure, sous-processus de calcul des segments |
| Demandes d’achat | `POWFRQAG.DKA_PO_ACCOUNT_GENERATION_TOP`, DKA_POWFRQAG.wft:10421 | Sous-processus DKA charge, variance et accrual ; branches de budget et projet dans l’export |
| Commandes | `POWFPOAG.DKA_DEFAULT_ACCOUNT_GENERATION`, DKA_POWFPOAG.wft:12399 | Charge si absente, budget si engagement actif, accrual, variance, contrôle des plans de comptes et comptes destination |
| Immobilisations | `FAFLEXWF.DKA_DEFAULT_ACCOUNT_GENERATION`, DKA_FAFLEXWF.wft:5967 | Initialisation DKA, routage groupe ASSET/BOOK/CATE, validation de combinaison |

Les workflows AP appellent explicitement les douze `DKA_SAPWFAG_PKG.GET_AP_SEGMENTn_VALUE` (`DKA_PAAPINVW.wft:5874`, `:6584` à `:6734` ; `DKA_PAAPWEBX.wft:5769` à `:5934`). Exemple de règle vérifiée : segment 1 obtenu via `DKA_SPAAUTOACCOUNTING_PKG.societe_projet(PROJECT_ID)` ; résultat nul → `ERROR_MESSAGE` et `COMPLETE:FAILURE`, sinon `LOOKUP_SET_VALUE` et `COMPLETE:SUCCESS` (`DKA_SAPWFAG_PKG.pkb:94`, `:128`). Les segments 10, 11, 12 sont explicitement fixés à `'0'` (`:959`, `:1020`, `:1081`). Les exceptions contextualisent via `WF_CORE.CONTEXT` puis sont relancées (`:152`).

Les workflows PO/DA appellent `DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT1_VALUE` à `...12_VALUE`, `IS_PO_PROJECT_RELATED`, `is_project_type_invest`, `get_po_cp_segment3_value`, `get_po_cp_segment5_value` (`DKA_POWFPOAG.wft:11466` à `:11631`, `:12384`, `:14328`, `:14358`, `:14373` ; `DKA_POWFRQAG.wft:11059` à `:11224`, `:11837`, `:12348`, `:12950`, `:12965`). Il faut préserver la distinction projet investissement / autres projets et les types charge, variance, accrual ; l’existence d’un callback commun ne prouve pas une règle identique pour tous les comptes.

FA appelle `DKA_SPE037_ACC_GEN_FA_PKG.init` (`DKA_FAFLEXWF.wft:7569`) avant les branches niveau actif/livre/catégorie (`:5981`). Les autres règles FA utilisent les activités décrites dans l’annexe ; leur installation et affectation à la génération de comptes doivent être comparées au paramétrage FA actif.

## 7. Notification générique, reprise et traitements d’exploitation

### 7.1 Notification générique

`DKASDNOT.DKA_SEND_NOTIF_PROCESS` est déclaré `RUNNABLE=N` ; son parcours est START → `DKA_NOTIFICATION` → END, avec rôle issu de `DKA_DESTINATAIRE` (`DKA_SEND_NOTIF.wft:2715`, `:2747`). La définition montre le service de notification, pas ses appelants ni la population effectivement destinataire. Ne pas confondre la déclaration non exécutable depuis l’interface de lancement et l’absence d’utilisation comme sous-processus/API.

### 7.2 Moteur différé et purge

Les lanceurs suivants soumettent explicitement `FNDWFBG`, initialisent le contexte utilisateur/responsabilité, chargent des paramètres, attendent la demande concurrente et traduisent `NORMAL/WARNING/autres` en code de sortie :

| Lanceur | Filtre item type forcé | Source |
|---|---|---|
| DKA_FNDWFBG.sql | `DKA_CSP`, paramètres 4 et 5 à `Y` | :24, :97, :221 |
| DKA_SFND_WFBG_REQAPPRV.sql | `REQAPPRV`, paramètres 4 et 5 à `Y` | :22, :95, :219 |
| DKA_SFND_WFBG_POAPPRV.sql | `POAPPRV`, paramètres 4 et 5 à `Y` | :22, :95, :219 |
| DKA_SFNDWFPR.sql | soumission `FNDWFPR`, paramètres récupérés | :24, :213 |

Les scripts shell `bin/*_JOB.sh` sont des points d’intégration avec l’ordonnanceur, pas la preuve d’une fréquence active. Les trois filtres FNDWFBG ci-dessus ne démontrent pas à eux seuls la prise en charge des items `DKA_POAP`, `DKASPOMA`, `DKASPAPR`, `DKASPORE`. Vérifier les autres demandes moteur et paramètres actifs. La rétention et les paramètres de purge ne peuvent être déduits du nom du programme.

### 7.3 Reprise automatique des erreurs PO

`DKA_SPOWFRETRY_PKG.main` sélectionne les commandes `IN PROCESS` ou `PRE-APPROVED` ayant une activité en erreur, puis leurs items enfants avec activité `NOTIFIED` (`DKA_SPOWFRETRY_PKG.pkb:45`). Il ferme le circuit d’erreur par `WF_ENGINE.HANDLEERROR(...,'SKIP','RETRY')`, commit, recherche l’activité parent `ERROR`, appelle `WF_ENGINE.HANDLEERROR(...,command=>wf_engine.eng_retry)`, commit (`:106`, `:113`, `:117`, `:135`, `:142`). Les exceptions par élément passent le code retour à 1 et journalisent ; exception globale rollback et code 2 (`:144`, `:158`, `:173`).

Deux limites concrètes : la fermeture du circuit d’erreur est déjà commitée si la reprise parent échoue ; la recherche `SELECT INTO` de l’activité parent utilise `ITEM_KEY` et statut `ERROR`, sans filtre `ITEM_TYPE` ni garantie d’unicité (`:117`). Des erreurs multiples ou des clés partagées peuvent provoquer une exception. Reprendre après diagnostic, avec contrôle de l’état final et des effets métier déjà validés.

### 7.4 Nettoyage des notifications obsolètes CSP

`DKA_SAPWFCSPNTF_PKG.main` sélectionne les notifications DKA_CSP encore ouvertes, selon la transcodification `DKA_NOTIF_METIER` : notifications OI dont la facture n’est plus trouvée dans l’interface par `GLOBAL_ATTRIBUTE2/3`, ou notifications AP sans blocage non libéré (`DKA_SAPWFCSPNTF_PKG.pkb:41`). Il tente `WF_ENGINE.ABORTPROCESS` sur l’item encore actif, sinon `WF_NOTIFICATION.CANCEL`, puis ajoute pour AP une ligne d’historique d’annulation (`:120`, `:134`, `:156`). L’identification repose sur le découpage des chaînes `CONTEXT/ITEM_KEY` ; préserver leur format est une dépendance d’intégration.

### 7.5 Effet déclenché lors des mises à jour Workflow

Le trigger `DKA_WF_ITEM_ACTIVITY_STAT_AUR` se déclenche après UPDATE de `WF_ITEM_ACTIVITY_STATUSES` pour item `POAPPRV`, état `COMPLETE`, résultat `ACTIVITY_PERFORMED` et date de fin renseignée (`DKA_WF_ITEM_ACTIVITY_STAT_AUR.trg:23`). Le commentaire introductif mentionne une autre table ; seule la clause `ON WF_ITEM_ACTIVITY_STATUSES` est probante.

Il recherche la commande par `WF_ITEM_KEY`, compte les éléments catalogue et les affectations/lignes, puis, si le nombre catalogue correspond au nombre attendu, supprime les affectations actives de `PO_GA_ORG_ASSIGNMENTS`, les restaure depuis `DKA_PO_GA_ORG_ASSIGNMENTS`, vide cette dernière pour la commande et relaie les erreurs via `APP_EXCEPTION` (`:45`, `:59`, `:104`, `:107`, `:113`, `:133`, `:139`). Il s’agit d’un traitement spécifique catalogue couplé à une transition Workflow. Une erreur de restauration peut donc affecter l’UPDATE Workflow ; ce point doit être inclus dans les tests de reprise catalogue.

## 8. Dépendances et contrôles de recette

| Contrôle | Justification et preuve attendue |
|---|---|
| Version réellement déployée de chaque processus | Les exports incluent standard, DKA et OLD. Exporter les versions actives Oracle Workflow et les comparer aux `.wft` ; ne pas compter les seuls noms de fichier. |
| Facture dans/hors CSP, source et catégorie nulle/reprise | Vérifier résultat de `is_facture_perimetre_CSP`, statut AP et historique ; comparer les valeurs de transcodification (DKA_SAPIAWIE_PKG.pkb:85). |
| Image absente puis disponible | Contrôler la première fin AP et le mécanisme effectif de relance CSP, sans supposer une attente dans APPROVAL_MAIN (DKA_APINVAPR.wft:5270). |
| Échec de création CSP | Provoquer en recette une dépendance manquante ; vérifier la distinction entre fin du parent et existence/statut de l’enfant (DKA_SAPIAWIE_PKG.pkb:377). |
| Blocage Ivalua accepté/refusé/en attente, retour rejoué | Vérifier résultat, blocages locaux, historique et absence de double approbation ; mesurer délai externe et timeout notification (DKA_SAPWFCSP.wft:25934). |
| Notifications humaines et escalades | Résoudre les rôles par attribut, habilitations et délais de l’environnement, tester `#TIMEOUT` et la réponse ultérieure à une ancienne notification. |
| Contrat approuvé/rejeté ; programmes NORMAL/WARNING/ERROR | Contrôler archivage, commande, réception, sites fournisseurs et fin maître ; une fin `END-n` n’est pas synonyme de succès métier (DKA_SPOWFMASTER.wft:2514). |
| Modification/résiliation après réception/facturation | Rapprocher quantités reçues/facturées et versions de commandes ; vérifier les points de commit et les demandes concurrentes déjà exécutées. |
| Reprise PO avec plusieurs erreurs | Vérifier l’unicité de la recherche de l’activité et l’état du circuit d’erreur après le premier commit (DKA_SPOWFRETRY_PKG.pkb:106). |
| Comptes AP/DA/PO/FA | Tester projet absent, société absente, investissement, type compte et combinaison invalide ; vérifier `FAILURE/ABORT` et segments produits. |
| Ordonnancement et purge | Collecter demandes moteur, fréquence, logs, statuts et rétention réellement paramétrés ; vérifier la couverture de tous les item types spécifiques. |
| Catalogue et transition PO | Tester restauration d’affectations et erreur du trigger, avec comptages catalogue et tables d’affectation avant/après. |

## 9. Limites de l’analyse

Les transitions et callbacks de l’annexe sont extraits du texte fourni, avec réunification des lignes de continuation `\\`. Le contrôle structurel compte 3 077 instances et 3 651 transitions ; toutes les cibles extraites correspondent à une instance du même processus. Les tables de l’annexe sont exhaustives pour les blocs processus/activités des 12 exports, mais elles ne constituent pas une validation de l’installation : aucune base Oracle, instance Workflow, notification, demande concurrente ou ordonnanceur n’a été interrogé. Aucun SQL ni script shell du corpus n’a été exécuté.

Les sources peuvent contenir plusieurs définitions du même objet ; l’analyse conserve chaque occurrence et sa ligne. Les rôles, transcodifications, profils, responsabilités, habilitations, adresses et durées effectives restent à collecter. Les branches sont prouvées par les transitions ; les procédures non développées ici sont des dépendances explicitement nommées, pas une prétention à avoir vérifié chaque règle de leurs corps. La disponibilité des APIs Oracle standard et l’atteignabilité depuis les écrans ou traitements d’amont doivent être confirmées en environnement.
