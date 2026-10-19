# Comptabilité, référentiels et périmètre connexe de la facturation

## Portée et niveau de preuve

Analyse statique des 103 SQL et README énumérés dans `graphify-out/perimetre_2.json`. Tous les contenus ont été lus par un traitement intégral (inventaire, lignes, empreinte, références lexicales) ; revue sémantique approfondie des flux pertinents, revue de classement des scripts connexes. Les très grands packages RH et workflow ne font pas l'objet d'une certification exhaustive de leur comportement. Le détail par fichier figure ci-dessous et dans `graphify-out/couverture_02.json`. Aucun SQL exécuté, aucune base consultée, aucun correctif appliqué.

**Preuve** désigne ici une instruction ou une déclaration présente dans le dépôt, pas un résultat constaté en production. Les résultats, performances et causes annoncés dans les README restent des déclarations documentaires. **Hypothèse / à confirmer** signale une interprétation ou une vérification restant nécessaire. Les variantes et archives ne constituent pas autant de flux distincts ni une preuve de déploiement.

## Chaîne comptable et analytique observée

La facture fournisseur s'articule autour de `AP_INVOICES_ALL` (en-tête), `AP_INVOICE_LINES_ALL` (ligne), `AP_INVOICE_DISTRIBUTIONS_ALL` (imputation), puis `AP_PAYMENT_SCHEDULES_ALL` (échéance). Fournisseur et site relèvent de `AP_SUPPLIERS` et `AP_SUPPLIER_SITES_ALL` ; l'unité opérationnelle est portée par `ORG_ID`. La documentation racine décrit distributions, codes comptables, règlements et annulations de paiement (`README.md:34`, `README.md:57`, `README.md:64`). Elle renvoie à un script précis ; cette description ne suffit pas à valider toutes les requêtes du dépôt.

Les requêtes de provisions matérialisent le chemin GL → XLA → réception → distribution PO : journal/en-tête/lot (`GL_JE_LINES`, `GL_JE_HEADERS`, `GL_JE_BATCHES`), `XLA_AE_LINES` reliées par `GL_SL_LINK_ID`, puis `XLA_DISTRIBUTION_LINKS`. Quand le lien GL est absent, `GL_IMPORT_REFERENCES` fournit l'étape intermédiaire. Les deux branches sont séparées par `GL_SL_LINK_ID IS [NOT] NULL` : `cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql:8`, `:30`, `:46`, `:67`.

Dans CAP V4, la référence source XLA rejoint `RCV_RECEIVING_SUB_LEDGER.RCV_SUB_LEDGER_ID` sous `APPLICATION_ID=707` et type `RCV_RECEIVING_SUB_LEDGER`, puis `REFERENCE3` rejoint `PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID` (`cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql:21`). Le rattachement projet/tâche s'effectue ensuite depuis la distribution PO vers `PA_PROJECTS_ALL` et `PA_TASKS` (`SSTR/SQL_Provision_OCT-25.sql:168`, `:178`). La liste des commandes rejetées relie explicitement `DKA_SPOCHARGE_ERRORS` à la distribution, la tâche, la commande et le fournisseur (`cloture_Cap/CAP_COMMANDES_REJ.sql:24`). C'est un point de rapprochement charge/provision/facture, pas une preuve d'intégration réussie.

### Divergence critique sur les clés de réception

Le README DTR-BO déclare la disparition de `APPLIED_TO_DIST_ID_NUM_1` en NOV-25 et propose une jonction directe de `SOURCE_DISTRIBUTION_ID_NUM_1` à `RCV_TRANSACTIONS.TRANSACTION_ID` (`DTR-BO/README_Changement_APPLIED_TO_NOV25.md:13`, `:39`). La requête « compatible » reproduit ce chemin et impose une transaction de réception non nulle (`DTR-BO/Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql:58`, `:78`). Le chemin CAP V4 décrit plus haut utilise une clé de sous-livre de réception distincte. Le dépôt comporte donc des interprétations concurrentes de la même référence source.

**À confirmer avant réutilisation :** type réel de distribution, clé source, correspondance sous-livre/transaction, taux de rattachement PO et sommes débit/crédit par période. Le filtre `RT.TRANSACTION_ID IS NOT NULL` peut exclure un ancien enregistrement dont seul `APPLIED_TO_DIST_ID_NUM_1` est renseigné malgré le `COALESCE`. Le libellé « compatible » n'est donc pas une garantie. L'attribution documentaire à un patch Oracle (`...compatible_OCT_NOV.sql:184`) ne démontre pas la cause générale ; aucun accès production n'a été réalisé.

## Cut-off SSTR, factures et granularité

La variante V4 construit `INVOICE_DETAILS` à la granularité distribution PO + numéro/date de facture, avec sommes séparées sur `POSTED_FLAG`, et exclusion de `PREPAY`, `REC_TAX`, `NONREC_TAX` (`JiraKDFI3809/SSTR_Od_Cut_Off_détail_factures_V4.sql:2`). Le lien final porte sur `PO_DISTRIBUTION_ID` (`:120`). C'est plus traçable qu'un seul numéro de commande, mais une distribution portant plusieurs factures produit plusieurs lignes : sommer ensuite le montant GL répété sur ces lignes gonflerait le cut-off. Un contrôle distinct du montant provisionné et des montants facturés est nécessaire.

Cette extraction sélectionne le ledger primaire, une période codée en dur `JUN-26`, la source `Purchasing` et des noms d'OD à contrepassation définis par expression régulière (`...V4.sql:121`). Les V3 et V4 sont des variantes locales de reporting ; ne pas cumuler leurs résultats. Les contrats proviennent notamment de `DKA_CONTRAT_SSTR_ARCHI`, `DKA_SPO_CONTRAT_SSTR_IVALUA` et `DKA_CONTRAT_SSTR` (`cloture_Cap/CAP_OD_Cut_Off_SSTR_factures_V3.sql:27`, `:64`, `:280`). Leurs versions et dates de validité doivent entrer dans le dossier de mapping.

## Référentiel fournisseur et paiement

Le référentiel joint fournisseur/site à `HZ_PARTIES`, `HZ_PARTY_SITES`, aux structures d'organisation et aux objets IBY. La variante optimisée reste une extraction, pas le mécanisme maître de synchronisation (`FactureLitige/Referentiel_Fournisseur_OPTIMISEE.sql:154`). Le fichier `MiseaJourFournisseurs/Detail_algorithme_maj_sites_fournisseurs.sql` est principalement une **description d'algorithme**, avec exemples et propositions : il déclare un traitement incrémental par `LAST_UPDATE_DATE`, un watermark `DKA_PARAMETERS`, et un appel `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR` (`:39`, `:69`, `:150`). Il cite les API de mise à jour du site et du compte bancaire (`:180`), ainsi que la table d'erreurs `DKA_SAPFRSDUPLI_ERROR_TMP` (`:185`). Ces déclarations nécessitent confirmation dans le package exécuté.

Le watermark est décrit comme la date de lancement, issue de `FND_CONCURRENT_REQUESTS.REQUESTED_START_DATE` (`...Detail_algorithme...sql:243`). **Risque à instruire :** avance du watermark alors que certains sites sont en erreur, changements simultanés pendant le traitement, multiplicité des instruments bancaires, et cohérence entre transactions et table d'erreurs. Ajouter des commits intermédiaires sur la seule foi d'une recommandation documentaire changerait l'atomicité du flux ; le dossier doit d'abord préciser l'unité de reprise.

L'identité de rapprochement doit conserver `VENDOR_ID`, `VENDOR_SITE_ID`, `ORG_ID`, bénéficiaire IBY, instrument et périodes de validité. Un numéro de fournisseur ou un code de site seul ne prouve pas l'unicité multi-organisation. Les fiches bancaires et données personnelles vues dans le dépôt ne sont pas recopiées dans l'analyse.

## Litiges, BAP et images

Le point d'entrée des exports de litiges est `AP_HOLDS_ALL`, filtré sur blocage non levé et code contenant `itige` ; les refus Ivalua proviennent de `AP_INV_APRVL_HIST_ALL`, réponse `DKA_REFUSE_IVALUA`, avec classement par date (`FactureLitige/SQL_Export_Gestion_Litiges_OPTIMISEE.sql:28`). Les échéances, fournisseurs, unité et compte GL enrichissent le résultat (`:253`). Le README précise qu'une facture avec plusieurs holds actifs conserve plusieurs lignes (`FactureLitige/README_Optimisation_SQL_Export_Gestion_Litiges.md:221`). **À confirmer :** granularité attendue facture/hold/échéance, sensibilité à la casse des codes, départage des événements à date égale et traitement des bénéficiaires globaux `ORG_ID IS NULL` (`:217`).

Le calcul documentaire du « solde fournisseur » agrège par `VENDOR_ID` (`...README_Optimisation...md:175`) : ce montant peut regrouper plusieurs organisations et devises. Il ne constitue pas un solde comptable exploitable sans préciser les axes et la conversion. Le flag « comptabilisé » fondé sur l'absence de distribution `POSTED_FLAG='N'` peut également masquer les cas sans distribution ou avec valeur nulle ; à rapprocher des statuts XLA/GL.

Les pièces jointes passent par `FND_ATTACHED_DOCUMENTS`, `FND_DOCUMENTS` et `FND_LOB_ACCESS`. Les générateurs d'URL produisent des données d'extraction ; ce ne sont pas de simples SELECT. Le générateur facture commence par supprimer le contenu d'`EXTRACTION_FACTURE` puis valider (`FactureLitige/DKA_GENERATE_URL_IMAGE_FACTURE_SOURCE.sql:25`). Il faut conserver le lien de pièce, sa durée de validité et les contrôles d'accès dans le contrat d'intégration. Le package `responable_hierachique/DKA_SAPWFCSP_PKG.sql` définit notamment initialisation OI/AP, poses de blocage et transfert OI → AP (`:295`, `:311`, `:379`, `:430`). Son lien avec la facturation est explicite ; son périmètre de 14 200 lignes exige une revue dédiée avant changement de routage.

## Reprises, corrections et clôture

`repousseGL/repouusse.sql` met à jour les dates comptables des lignes d'interface, la `GL_DATE` et le statut de l'en-tête, puis fait un `COMMIT` (`:88`, `:114`, `:137`). Une telle reprise modifie le rattachement de période : exiger périmètre source/lot, état avant/après, accord comptable et preuve de non-duplication avant toute exécution.

Les archives de fermeture PO réalisent des UPDATE directs d'en-têtes, lignes et échéanciers, parfois des distributions, avec commits (`fermetureCommandesPO/archive/fermeture_commandes_04122025.sql:77`, `:106`, `:114`). Les versions ne touchent pas toutes les mêmes niveaux ; elles ne constituent pas un mode opératoire générique de fermeture. Le script d'annulation ciblée, les contrôles de réceptions et factures doivent être réévalués pour chaque commande.

La correction GL `miseAjourGL/Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql` annonce une simulation avec rollback, contrôle les absents et le nombre modifié avant validation conditionnelle (`:28`, `:158`). Conserver le mode effectivement activé dans toute fiche de reprise. Le groupe AR « doublons OpenInterface » comporte rapport et scripts de suppression enfants → erreurs → lignes avec possibilité de commit (`factureEndoubleTableStandrad/Suppression_Doublons_Execution.sql:113`, `:130`, `:156`) ; une erreur d'interface ne suffit pas à prouver un doublon métier. Ce volet relève de la facturation client, à séparer du circuit AP.

Les contrôles de clôture interrogent les requêtes concurrentes (`cloture2026/Controle_Cloture_Quotidien.sql:92`) ; ils donnent une visibilité de traitement, pas un contrôle de totalisation des factures. Les programmes, request IDs, paramètres, période, UO et sommes intégrées/rejetées doivent être reliés au même lot de factures.

## Banque, supervision et frontières du dossier

Les README de virements/prélèvements décrivent principalement collecte de mails et pièces vers Drive, idempotence et contrôle de rapports (`Projet_Virements/README.md:179`, `AppsScript/controlePrelevement/README.md:17`). Ils ne démontrent ni génération de paiement EBS ni exécution bancaire. L'incident relevés bancaires décrit une concurrence des chaînes Control-M 05/06 sur le même zip et un plan de reprise séquencé (`ControleReleveBancaire/README.md:12`, `:122`, `:159`). La causalité est celle du rapport fourni ; elle n'a pas été reproduite. Un défaut de relevé ne doit pas être interprété directement comme une facture non payée.

RH (`dateFinEmploye`, exports d'affectation/banque/personnes), désactivation utilisateurs, ajout de responsabilités et vérification de comptes relèvent de domaines connexes. Ils peuvent conditionner l'approbation ou le fournisseur salarié, mais leur inclusion complète dans l'intégration de facturation est une **hypothèse** à faire valider. Paie, catégories d'immobilisations, cache pytest, prompts, inventaire scheduler et rafraîchissement de vues restent du support ou d'autres domaines ; ne pas les convertir artificiellement en étapes de facturation. `lionelDtr/XXEAI.sql` expose des recherches de projets/tâches (`:536`, `:558`), utiles au mapping analytique, sans preuve qu'un flux de facture précis appelle ces routines.

## Éléments à reprendre dans le dossier d'intégration

1. Définir les contrats séparés AP, AR, PO/réception, GL/XLA, PA, référentiel et paiement : clés, cardinalités, organisation, devise, dates et sources maîtres.
2. Tracer un lot depuis le fichier et le contrôle EAI jusqu'à l'interface, la facture, les distributions, les rejets, la request concurrente et le journal comptable.
3. Arbitrer les chemins XLA/réception sur échantillons de périodes antérieures et récentes ; mesurer les non-rattachés et réconcilier les montants avant de choisir une variante SQL.
4. Définir la reprise par lot/transaction, ses statuts, son idempotence et son watermark ; distinguer simulation, correction validée, purge et réimport.
5. Tester les cardinalités avec plusieurs échéances, plusieurs holds, historique RH, plusieurs bénéficiaires IBY et plusieurs factures par distribution PO. Conserver des contrôles à la granularité des montants pour éviter les doubles sommes.
6. Documenter les interfaces réellement déployées et les preuves d'exploitation : README, SQL locaux et archives ne remplacent pas inventaire applicatif, package en production, logs et recette métier.

## Couverture fichier par fichier

Inventaire documentaire : références lexicales détectées, incluant potentiellement CTE ou exemples. Les classes ci-dessous servent au tri et ne certifient pas l'appartenance à un flux exécuté. Les empreintes et toutes les références/numéros de lignes sont dans `graphify-out/couverture_02.json`. Le fragment de graphe encode seulement « le fichier référence l'objet », sans déduire automatiquement appel, propriété ou flux réel.

| Fichier | Lignes | Classement | Premiers objets repérés |
|---|---:|---|---|
| `.github/prompts/README.md` | 236 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `.pytest_cache/README.md` | 8 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `Ajout_de_responsabilite/pbAjoutRespon/Fix_WF_Synchro_H00036238E.sql` | 63 | RH / habilitations / workflow (connexe pour BAP) | APPLSYS.WF_LOCAL_ROLES:31 |
| `Ajout_de_responsabilite/Utilisateurs ayant une certaine responsabilité.sql` | 26 | RH / habilitations / workflow (connexe pour BAP) | FND_USER_RESP_GROUPS_DIRECT:8 ; FND_RESPONSIBILITY_TL:24 |
| `AppsScript/cloture/README.md` | 42 | Facturation / GL-PA / diagnostic à contextualiser | Documentation / aucune référence SQL isolée |
| `AppsScript/controlePrelevement/README.md` | 145 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `AppsScript/odat/README.md` | 124 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `ChaineControleM/Inventaire_Jobs_FINFIN.sql` | 255 | Support technique / orchestration / autre domaine | APPS.FND_CONCURRENT_REQUESTS:68 |
| `cloture2026/Controle_Cloture_Quotidien.sql` | 475 | Clôture / provisions / cut-off | FND_CONCURRENT_REQUESTS:92 ; FND_CONCURRENT_PROGRAMS:141 ; FND_CONCURRENT_PROGRAMS_TL:144 ; FND_USER:148 |
| `cloture2026/Dalkia_Traitements.sql` | 465 | Clôture / provisions / cut-off | FND_CONCURRENT_REQUESTS:1 ; ALL_TAB_COLS:5 ; AS_STATUSES_B:13 ; FND_CONC_REQ_SUMMARY_V:49 |
| `cloture2026/Fev2026/Controle_Cloture_Quotidien.sql` | 475 | Clôture / provisions / cut-off | FND_CONCURRENT_REQUESTS:92 ; FND_CONCURRENT_PROGRAMS:141 ; FND_CONCURRENT_PROGRAMS_TL:144 ; FND_USER:148 |
| `cloture2026/Fev2026/Recherche_La_Crau_Energies_Vertes.sql` | 410 | Clôture / provisions / cut-off | AP.AP_SUPPLIER_SITES_ALL:141 ; HR.HR_OPERATING_UNITS:143 ; AP.AP_TERMS:145 ; GL.GL_CODE_COMBINATIONS_KFV:147 |
| `cloture2026/Fev2026/Responsabilites_ORG_ID_86.sql` | 299 | Clôture / provisions / cut-off | GL.GL_LEDGERS:25 ; APPS.FND_RESPONSIBILITY_VL:49 ; APPS.FND_APPLICATION_VL:50 ; APPS.FND_USER_RESP_GROUPS_DIRECT:185 |
| `cloture_Cap/CAP_COMMANDES_REJ.sql` | 30 | Clôture / provisions / cut-off | DKA_SPOCHARGE_ERRORS:24 ; PO_DISTRIBUTIONS_ALL:25 ; PO_LINES_ALL:26 ; PA.PA_TASKS:27 |
| `cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql` | 72 | Clôture / provisions / cut-off | GL.GL_JE_LINES:8 ; GL.GL_LEDGERS:9 ; GL.GL_JE_HEADERS:10 ; GL.GL_JE_BATCHES:11 |
| `cloture_Cap/CAP_OD_Cut_Off_SSTR_factures_V3.sql` | 339 | Clôture / provisions / cut-off | PO.PO_HEADERS_ALL:22 ; DKA.DKA_CONTRAT_SSTR_ARCHI:27 ; DKA_SPO_CONTRAT_SSTR_IVALUA:64 ; AP.AP_INVOICES_ALL:86 |
| `cloture_Cap/SQL_Provision_OCT-25.sql` | 478 | Clôture / provisions / cut-off | AP.AP_INVOICE_DISTRIBUTIONS_ALL:13 ; PO.PO_DISTRIBUTIONS_ALL:14 ; PO.PO_HEADERS_ALL:16 ; HR.PER_ALL_PEOPLE_F:25 |
| `cloturePeriode/sql_J-7.sql` | 23 | Facturation / GL-PA / diagnostic à contextualiser | FND_CONCURRENT_REQUESTS:10 ; FND_CONCURRENT_PROGRAMS_VL:11 ; FND_LOOKUPS:14 ; FND_USER:21 |
| `ControleReleveBancaire/Analyse_Verification_Import_Releves_Bancaires.sql` | 301 | Paiements / banque / collecte de rapports | XXRB.RB_LINES_ALL:56 ; XXRB.RB_BATCH_IMPORT:175 ; FND_CONCURRENT_PROGRAMS_VL:254 ; FND_USER:257 |
| `ControleReleveBancaire/DKA_SRBCTRLRB_PKG.sql` | 645 | Paiements / banque / collecte de rapports | RB_BANK_ACCOUNTS_ALL:300 |
| `ControleReleveBancaire/README.md` | 190 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `controleVirement/.pytest_cache/README.md` | 8 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/.pytest_cache/README.md` | 8 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/docs/README_ecart_589_20260914.md` | 114 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `dateFinEmploye/body.sql` | 8915 | RH / habilitations / workflow (connexe pour BAP) | AP_TERMS:202 ; PER_JOB_GROUPS:209 ; XXEAI_HR_PEOPLE_INT:217 ; PER_ALL_PEOPLE_F:220 |
| `dateFinEmploye/export/xxeai_hr_assignment_int.sql` | 297 | RH / habilitations / workflow (connexe pour BAP) | XXEAI_HR_ASSIGNMENT_INT:3 |
| `dateFinEmploye/export/xxeai_hr_bank_int_all.sql` | 297 | RH / habilitations / workflow (connexe pour BAP) | XXEAI_HR_BANK_INT_ALL:3 |
| `dateFinEmploye/export/XXEAI_HR_PEOPLE_INT.sql` | 264 | RH / habilitations / workflow (connexe pour BAP) | XXEAI_HR_PEOPLE_INT:3 |
| `dateFinEmploye/reverse_termination.sql` | 62 | RH / habilitations / workflow (connexe pour BAP) | PER_PERIODS_OF_SERVICE:28 |
| `dateFinUser/desactivation_users.sql` | 382 | RH / habilitations / workflow (connexe pour BAP) | APPLSYS.FND_USER:162 ; APPLSYS.FND_RESPONSIBILITY:176 ; TESTES:364 |
| `diversAnalyses/get_ebs_info.sql` | 3 | Support technique / orchestration / autre domaine | FND_PRODUCT_GROUPS:1 ; V$VERSION:2 ; ALL_TABLES:3 |
| `diversAnalyses/get_main_programs.sql` | 28 | Support technique / orchestration / autre domaine | FND_CONCURRENT_REQUESTS:8 ; FND_CONCURRENT_PROGRAMS_VL:9 |
| `diversAnalyses/get_ou_info.sql` | 13 | Support technique / orchestration / autre domaine | AP_INVOICES_ALL:6 ; PO_HEADERS_ALL:8 |
| `diversAnalyses/Open AP Invoices.sql` | 49 | Facturation / GL-PA / diagnostic à contextualiser | APPS.AP_INVOICES_ALL:20 |
| `diversAnalyses/oracleProd.sql` | 33 | Facturation / GL-PA / diagnostic à contextualiser | FND_CONCURRENT_REQUESTS:8 ; FND_CONCURRENT_PROGRAMS_VL:9 ; FND_USER:11 ; GL_INTERFACE:17 |
| `diversAnalyses/Recherche_Fournisseur_Groupe_Services_France.sql` | 325 | Référentiel fournisseur / commandes | AP.AP_SUPPLIER_SITES_ALL:140 ; HR.HR_OPERATING_UNITS:142 ; AP.AP_TERMS:144 ; AP.AP_SUPPLIER_CONTACTS:177 |
| `diversAnalyses/Requête statut des factures AP.sql` | 154 | Facturation / GL-PA / diagnostic à contextualiser | AP_INVOICE_DISTRIBUTIONS_ALL:92 ; PO_VENDORS:93 |
| `diversAnalyses/run_direct.sql` | 9 | Facturation / GL-PA / diagnostic à contextualiser | Documentation / aucune référence SQL isolée |
| `diversAnalyses/temp_oracleProd_20260605_141040.sql` | 50 | Facturation / GL-PA / diagnostic à contextualiser | FND_CONCURRENT_REQUESTS:22 ; FND_CONCURRENT_PROGRAMS_VL:23 ; FND_USER:25 ; GL_INTERFACE:31 |
| `diversAnalyses/temp_test.sql` | 614 | Facturation / GL-PA / diagnostic à contextualiser | APPS.AP_PAYMENT_SCHEDULES_ALL:16 ; APPS.PA_TASKS:21 ; FND_FLEX_VALUE_SETS:25 ; FND_FLEX_VALUES_VL:26 |
| `diversAnalyses/Traitement_longue_duree_27nov.sql` | 67 | Facturation / GL-PA / diagnostic à contextualiser | FND_CONCURRENT_REQUESTS:30 ; FND_CONCURRENT_PROGRAMS_VL:31 |
| `diversAnalyses/Utilisateurs ayant une certaine responsabilité.sql` | 26 | Facturation / GL-PA / diagnostic à contextualiser | FND_USER_RESP_GROUPS_DIRECT:8 ; FND_RESPONSIBILITY_TL:24 |
| `DTR-BO/Analyse_requete_provisions_NOV25.sql` | 313 | Clôture / provisions / cut-off | GL.GL_JE_BATCHES:27 ; GL.GL_JE_HEADERS:28 ; GL.GL_LEDGERS:29 ; GL.GL_JE_LINES:47 |
| `DTR-BO/ancienneReq.sql` | 80 | Clôture / provisions / cut-off | GL.GL_JE_LINES:13 ; GL.GL_LEDGERS:14 ; GL.GL_JE_HEADERS:15 ; GL.GL_JE_BATCHES:16 |
| `DTR-BO/README_Changement_APPLIED_TO_NOV25.md` | 90 | Clôture / provisions / cut-off | PO.PO_DISTRIBUTIONS_ALL:31 ; PO.RCV_TRANSACTIONS:39 |
| `DTR-BO/requete.sql` | 82 | Clôture / provisions / cut-off | GL.GL_JE_LINES:10 ; GL.GL_LEDGERS:11 ; GL.GL_JE_HEADERS:12 ; GL.GL_JE_BATCHES:13 |
| `DTR-BO/Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql` | 197 | Clôture / provisions / cut-off | GL.GL_JE_LINES:44 ; GL.GL_LEDGERS:45 ; GL.GL_JE_HEADERS:46 ; GL.GL_JE_BATCHES:47 |
| `DTR-BO/Requete_provisions_NOV25_CORRIGEE.sql` | 214 | Clôture / provisions / cut-off | GL.GL_JE_LINES:41 ; GL.GL_LEDGERS:42 ; GL.GL_JE_HEADERS:44 ; GL.GL_JE_BATCHES:46 |
| `DTR-BO/requeteDiag.sql` | 38 | Clôture / provisions / cut-off | DBA_OBJECTS:3 ; AD_APPLIED_PATCHES:11 ; XLA_AE_HEADERS:21 ; XLA_DISTRIBUTION_LINKS:22 |
| `DTR-BO/requeteNVetAn.sql` | 187 | Clôture / provisions / cut-off | GL.GL_JE_LINES:12 ; GL.GL_LEDGERS:13 ; GL.GL_JE_HEADERS:14 ; GL.GL_JE_BATCHES:15 |
| `factureEndoubleTableStandrad/Extraction_Depenses_GS0211082R_Soc348.sql` | 180 | Facturation / GL-PA / diagnostic à contextualiser | AP.AP_INVOICE_LINES_ALL:51 ; AP.AP_INVOICE_DISTRIBUTIONS_ALL:52 ; GL.GL_CODE_COMBINATIONS_KFV:54 ; AP.AP_SUPPLIERS:55 |
| `factureEndoubleTableStandrad/Rapport_Doublons_OpenInterface_AR.sql` | 240 | Facturation / GL-PA / diagnostic à contextualiser | AR.RA_INTERFACE_LINES_ALL:63 ; AR.RA_INTERFACE_ERRORS_ALL:64 ; AR.RA_INTERFACE_SALESCREDITS_ALL:83 ; CIBLES:84 |
| `factureEndoubleTableStandrad/Suppression_Doublons_Execution.sql` | 192 | Facturation / GL-PA / diagnostic à contextualiser | AR.RA_INTERFACE_LINES_ALL:73 ; AR.RA_INTERFACE_ERRORS_ALL:74 ; AR.RA_INTERFACE_SALESCREDITS_ALL:113 ; AR.RA_INTERFACE_DISTRIBUTIONS_ALL:118 |
| `factureEndoubleTableStandrad/Suppression_Doublons_OpenInterface_AR.sql` | 319 | Facturation / GL-PA / diagnostic à contextualiser | AR.RA_INTERFACE_LINES_ALL:87 ; AR.RA_INTERFACE_ERRORS_ALL:88 ; AR.RA_INTERFACE_SALESCREDITS_ALL:142 ; CIBLES:143 |
| `FactureLitige/DKA_GENERATE_URL_IMAGE_BDC_OPTIMISEE.sql` | 261 | Litiges / référentiel / pièces | APPS.FND_ATTACHED_DOCUMENTS:56 ; APPS.PO_HEADERS_ALL:57 ; APPS.FND_DOCUMENTS:59 ; FND_LOB_ACCESS:89 |
| `FactureLitige/DKA_GENERATE_URL_IMAGE_FACTURE_SOURCE.sql` | 178 | Litiges / référentiel / pièces | DKA_JMETER_ST.EXTRACTION_FACTURE:25 ; DKA_PARAMETERS:34 ; APPS.FND_ATTACHED_DOCUMENTS:60 ; APPS.AP_INVOICES_ALL:61 |
| `FactureLitige/optimized_query.sql` | 147 | Litiges / référentiel / pièces | APPS.AP_HOLDS_ALL:23 ; DKA_IAPFAC_DEBLOC_REPOR_INTERF:36 ; FACTURES_EN_LITIGE:85 ; AP_INV_APRVL_HIST_ALL:88 |
| `FactureLitige/original_query.sql` | 73 | Litiges / référentiel / pièces | APPS.FND_USER:9 ; APPS.PER_PEOPLE_F:20 ; PER_PEOPLE_F:31 ; APPS.AP_HOLDS_ALL:66 |
| `FactureLitige/README_Optimisation_SQL_Export_Gestion_Litiges.md` | 227 | Litiges / référentiel / pièces | AP_HOLDS_ALL:32 ; DIRECT:44 ; HOLDS_COUNT:55 ; APPS.PER_ALL_PEOPLE_F:68 |
| `FactureLitige/Referentiel_Fournisseur.sql` | 169 | Litiges / référentiel / pièces | APPLSYS.FND_FLEX_VALUE_SETS:7 ; APPLSYS.FND_FLEX_VALUES:8 ; APPLSYS.FND_FLEX_VALUES_TL:10 ; APPS.AP_SUPPLIER_SITES_ALL:109 |
| `FactureLitige/Referentiel_Fournisseur_OPTIMISEE.sql` | 199 | Litiges / référentiel / pièces | APPLSYS.FND_FLEX_VALUES:35 ; APPLSYS.FND_FLEX_VALUES_TL:36 ; AR.HZ_PARTY_SITES:154 ; AP.AP_SUPPLIERS:155 |
| `FactureLitige/Script_Generation_BDC_2026_Mensuel.sql` | 258 | Litiges / référentiel / pièces | DKA_JMETER_ST.EXTRACTION_BDC:83 ; DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL:89 |
| `FactureLitige/SQL_Export_Gestion_Litiges.sql` | 158 | Litiges / référentiel / pièces | AP_SUPPLIERS:139 ; AP_SUPPLIER_SITES_ALL:140 ; HR_ORGANIZATION_UNITS:141 ; GL_LEDGERS:142 |
| `FactureLitige/SQL_Export_Gestion_Litiges_OPTIMISEE.sql` | 272 | Litiges / référentiel / pièces | AP_PAYMENT_SCHEDULES_ALL:160 ; AP_SUPPLIERS:253 ; AP_SUPPLIER_SITES_ALL:254 ; HR_ORGANIZATION_UNITS:255 |
| `fermetureCommandesPO/archive/fermeture_commandes_04122025.sql` | 223 | Référentiel fournisseur / commandes | PO.PO_HEADERS_ALL:69 ; PO.PO_LINES_ALL:88 ; PO.PO_LINE_LOCATIONS_ALL:97 ; PO.PO_DISTRIBUTIONS_ALL:106 |
| `fermetureCommandesPO/archive/fermeture_commandes_23122025.sql` | 201 | Référentiel fournisseur / commandes | PO.PO_HEADERS_ALL:66 ; PO.PO_LINES_ALL:88 ; PO.PO_LINE_LOCATIONS_ALL:97 |
| `fermetureCommandesPO/archive/fermeture_commandes_24122025.sql` | 204 | Référentiel fournisseur / commandes | PO.PO_HEADERS_ALL:66 ; PO.PO_LINES_ALL:88 ; PO.PO_LINE_LOCATIONS_ALL:97 |
| `fermetureCommandesPO/archive/fermeture_commandes_26012026.sql` | 186 | Référentiel fournisseur / commandes | PO.PO_HEADERS_ALL:61 ; PO.PO_LINES_ALL:83 ; PO.PO_LINE_LOCATIONS_ALL:92 |
| `fermetureCommandesPO/archive/fermeture_commandes_30012026.sql` | 207 | Référentiel fournisseur / commandes | PO.PO_HEADERS_ALL:80 ; PO.PO_LINES_ALL:102 ; PO.PO_LINE_LOCATIONS_ALL:111 ; APPLSYS.FND_USER:182 |
| `fermetureCommandesPO/archive/hindFermeture.sql` | 162 | Référentiel fournisseur / commandes | APPS.PO_HEADERS_ALL:18 ; APPS.PO_VENDOR_SITES_ALL:19 ; APPS.HR_ALL_ORGANIZATION_UNITS:22 ; APPS.PO_LINE_LOCATIONS_ALL:92 |
| `fermetureCommandesPO/archive/hindFermetureEhanced.sql` | 296 | Référentiel fournisseur / commandes | PO.PO_LINES_ALL:36 ; PO.PO_LINE_LOCATIONS_ALL:39 ; PO.PO_DISTRIBUTIONS_ALL:42 ; PO.PO_HEADERS_ALL:50 |
| `FichierPaie22012026/extract_package.sql` | 51 | Facturation / GL-PA / diagnostic à contextualiser | ALL_SOURCE:24 |
| `FichierPaie22012026/README_Package_Extraction.md` | 35 | Facturation / GL-PA / diagnostic à contextualiser | ALL_SOURCE:26 |
| `JiraKDFI3809/CAP_OD_Cut_Off_SSTR_factures_V3.sql` | 339 | Clôture / provisions / cut-off | PO.PO_HEADERS_ALL:22 ; DKA.DKA_CONTRAT_SSTR_ARCHI:27 ; DKA_SPO_CONTRAT_SSTR_IVALUA:64 ; AP.AP_INVOICES_ALL:86 |
| `JiraKDFI3809/SSTR_Od_Cut_Off_détail_factures_V4.sql` | 127 | Clôture / provisions / cut-off | AP.AP_INVOICE_DISTRIBUTIONS_ALL:11 ; AP.AP_INVOICES_ALL:12 ; PO.PO_HEADERS_ALL:37 ; DKA.DKA_CONTRAT_SSTR_ARCHI:42 |
| `KDFI-3422/maj_last_update_date_categories.sql` | 157 | Support technique / orchestration / autre domaine | FND_USER:74 ; FA.FA_CATEGORIES_B:88 |
| `KDFI-3426AnnulerBonDecommande/annulation_PO_4736744ST2501.sql` | 336 | Référentiel fournisseur / commandes | FND_USER:45 ; FND_RESPONSIBILITY_VL:51 ; AP.AP_SUPPLIERS:91 ; PO.PO_LINES_ALL:110 |
| `KDFI-3825-CUT OFF SSTR/SSTR_Od_Cut_Off_détail_factures_V4.sql` | 127 | Clôture / provisions / cut-off | AP.AP_INVOICE_DISTRIBUTIONS_ALL:11 ; AP.AP_INVOICES_ALL:12 ; PO.PO_HEADERS_ALL:37 ; DKA.DKA_CONTRAT_SSTR_ARCHI:42 |
| `lanceurCentrale/Analyse_Erreur_Control_Fournisseur/Control_Fournisseur_CORRIGEE.sql` | 586 | Référentiel fournisseur / commandes | APPS.PO_VENDORS:23 ; AP.AP_INVOICES_ALL:32 ; AP.AP_PAYMENT_SCHEDULES_ALL:33 ; AR.HZ_PARTIES:61 |
| `lionelDtr/XXEAI.sql` | 3102 | Facturation / GL-PA / diagnostic à contextualiser | APPS.FND_FLEX_VALUE_SETS:484 ; APPS.FND_FLEX_VALUES_VL:485 ; APPS.FND_FLEX_VALUES_DFV:486 ; APPS.PA_PROJECTS_ALL:536 |
| `MiseaJourFournisseurs/Definition_programme_maj_sites_fournisseurs.sql` | 133 | Référentiel fournisseur / commandes | FND_CONCURRENT_PROGRAMS_VL:16 ; FND_EXECUTABLES:40 ; FND_DESCR_FLEX_COL_USAGE_VL:56 ; FND_FLEX_VALUE_SETS:59 |
| `MiseaJourFournisseurs/Detail_algorithme_maj_sites_fournisseurs.sql` | 653 | Référentiel fournisseur / commandes | AP_SUPPLIER_SITES_ALL:74 ; DKA_SAPFRSDUPLI_ERROR_TMP:198 ; DKA_PARAMETERS:243 ; FND_CONCURRENT_REQUESTS:246 |
| `miseAjourGL/Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql` | 190 | Facturation / GL-PA / diagnostic à contextualiser | GL.GL_JE_LINES:113 |
| `odat_watch/.pytest_cache/README.md` | 8 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `odat_watch/README.md` | 305 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `OptimisationRequete/FACTURES_EN_COURS_V3_Q1.sql` | 258 | Facturation / GL-PA / diagnostic à contextualiser | APPS.AP_INVOICES_ALL:7 ; PARAMS:8 ; APPS.AP_INVOICE_LINES_ALL:14 ; APPS.AP_INVOICE_DISTRIBUTIONS_ALL:21 |
| `Projet_CTM/README.md` | 91 | Support technique / orchestration / autre domaine | Documentation / aucune référence SQL isolée |
| `Projet_Virements/README.md` | 219 | Paiements / banque / collecte de rapports | Documentation / aucune référence SQL isolée |
| `README.md` | 100 | Facturation / GL-PA / diagnostic à contextualiser | Documentation / aucune référence SQL isolée |
| `repousseGL/repouusse.sql` | 184 | Facturation / GL-PA / diagnostic à contextualiser | AP_INVOICES_INTERFACE:52 ; AP_INVOICE_LINES_INTERFACE:58 |
| `responable_hierachique/DKA_SAPWFCSP_PKG.sql` | 14200 | RH / habilitations / workflow (connexe pour BAP) | FND_PROFILE_OPTIONS:1380 ; DKA_WF_DEBUG:1391 ; PER_ALL_PEOPLE_F:1581 ; AP_INV_APRVL_HIST_ALL:1627 |
| `responable_hierachique/Requetes_Diagnostic_Routage_BAP_0380.sql` | 206 | RH / habilitations / workflow (connexe pour BAP) | HR_ALL_ORGANIZATION_UNITS:17 ; HR_ORGANIZATION_INFORMATION:18 ; WF_LOCAL_USER_ROLES:33 ; FND_USER:34 |
| `robot/CA_global_concat_CORRIGE.sql` | 196 | Facturation / GL-PA / diagnostic à contextualiser | RA_CUST_TRX_LINE_GL_DIST_ALL:37 ; HZ_CUST_ACCOUNTS:155 ; FINAL:195 |
| `sql/appinit.sql` | 3 | Support technique / orchestration / autre domaine | ALL_TAB_COLUMNS:1 ; FND_USER:3 |
| `sql/CSP_Onglet_Litige.sql` | 192 | Litiges / référentiel / pièces | AP_HOLDS_ALL:7 ; AP_INVOICE_DISTRIBUTIONS_ALL:16 ; FND_ATTACHED_DOCUMENTS:36 ; AP_PAYMENT_SCHEDULES_ALL:45 |
| `sql/oracleProd4.sql` | 3 | Facturation / GL-PA / diagnostic à contextualiser | DKA_SCTLFLUX_EAI:1 |
| `sql/oracleProd~2.sql` | 73 | Facturation / GL-PA / diagnostic à contextualiser | GL.GL_JE_LINES:10 ; GL.GL_LEDGERS:11 ; GL.GL_JE_HEADERS:12 ; GL.GL_JE_BATCHES:13 |
| `sql/oracleProd~3.sql` | 27 | Facturation / GL-PA / diagnostic à contextualiser | APPS.FND_USER_RESP_GROUPS:14 ; FND_RESPONSIBILITY_VL:25 |
| `SSTR/README_Optimisation_SQL_Provision.md` | 104 | Clôture / provisions / cut-off | HR.PER_ALL_PEOPLE_F:17 |
| `SSTR/SQL_Provision_OCT-25.sql` | 466 | Clôture / provisions / cut-off | AP.AP_INVOICE_DISTRIBUTIONS_ALL:14 ; PO.PO_DISTRIBUTIONS_ALL:15 ; PO.PO_HEADERS_ALL:17 ; HR.PER_ALL_PEOPLE_F:31 |
| `TACHE_FRONTAL_FINANCE/REFRESH_MV_20h00.sql` | 79 | Support technique / orchestration / autre domaine | USER_SCHEDULER_JOBS:45 ; USER_SCHEDULER_JOB_RUN_DETAILS:77 |
| `TP12011976/requete_index_contrainte.sql` | 54 | Support technique / orchestration / autre domaine | ALL_IND_COLUMNS:13 ; DKA.DKA_IARPAFAC_INTERFACE:42 |
| `verification_user/verification_user.sql` | 65 | RH / habilitations / workflow (connexe pour BAP) | APPLSYS.FND_USER:35 ; APPLSYS.FND_USER_RESP_GROUPS_DIRECT:56 ; APPLSYS.FND_RESPONSIBILITY_VL:58 ; APPLSYS.FND_APPLICATION:61 |
