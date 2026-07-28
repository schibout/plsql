# Analyse - Batch du soir non lancé le 17/03/2026
## Incident : Absence totale du batch du soir (17/03/2026 19h → 18/03/2026 07h)

---

## 1. RÉSUMÉ EXÉCUTIF

| Indicateur | Valeur |
|---|---|
| **Date du soir contrôlé** | 17/03/2026 19h00 → 18/03/2026 07h00 |
| **Programmes exécutés ce soir** | **2** (OAM + Purge) |
| **Programmes attendus (réf. 10/03)** | **147** |
| **Cause racine identifiée** | `DKA_SLAUNCHER` n'a pas démarré à 19h00 |
| **Impact** | Toute la chaîne de traitement du soir est bloquée |

### Ce qui a tourné ce soir (UNIQUEMENT programmes système) :
| Programme | Nb exec | Heure |
|---|---|---|
| OAM Applications Dashboard Collection (`FNDOAMCOL`) | 70 | 00h01 |
| Purge Concurrent Request and/or Manager Data (`FNDCPPUR`) | 3 | 19h30-20h00 |

> ⚠️ **Aucun programme métier n'a été exécuté cette nuit.**

---

## 2. TRAITEMENTS MANQUANTS — CLASSÉS PAR TRANCHE HORAIRE

*Référence : mardi 10/03/2026 — dernier mardi comparable*

---

### 🔴 Tranche 19h00–21h00 — Comptabilisation, Imports iValua, Immobilisations

| Heure habituelle | Programme | Nom technique | Nb exec réf. | Erreurs réf. |
|---|---|---|---|---|
| 19:00 | **DKA : Lanceur (SHELL)** ← *CAUSE RACINE* | `DKA_SLAUNCHER` | 78 | 2 |
| 19:01 | DKA : Export journalier des fournisseurs | `DKA_APFRSEXP_JOUR` | 1 | 0 |
| 19:01 | DKA : Comptabilisation AR | `DKA_SXLAACCPBAR` | 3 | 0 |
| 19:01 | DKA : Generer des comptes | `DKA_FAGDA` | 1 | 0 |
| 19:01 | DKA : Mise à jour des rattachements de sites fournisseurs sur commande ouverte globale | `DKA_SPODUPSITECOG` | 1 | 0 |
| 19:01 | DKA : Export du référentiel employé vers NOTILUS | `DKA_IAPEMPLNOT` | 1 | 0 |
| 19:01 | DKA : Calculer les plus- et moins-values | `DKA_FARET` | 1 | 0 |
| 19:01 | Create Accounting | `XLAACCPB` | 495 | 0 |
| 19:01 | Accounting Program | `XLAACCUP` | 295 | 0 |
| 19:01 | Generate Accounts | `FAGDA` | 332 | 0 |
| 19:01 | Report Set | `FNDRSSUB` | 11 | 0 |
| 19:01 | Request Set Stage | `FNDRSSTG` | 33 | 0 |
| 19:02 | Journal Import | `GLLEZL` | 555 | 0 |
| 19:02 | Calculate Gains and Losses | `FARET` | 332 | 0 |
| 19:02 | Open Account Balances Data Manager | `XLATBDMG` | 285 | 0 |
| 19:02 | Open Account Balances Data Manager Worker Process | `XLATBDMW` | 285 | 0 |
| 19:02 | Update Subledger Accounting Balances | `XLABAPUB` | 286 | 0 |
| 19:03 | DKA : Interface des factures manuelles sur projets | `DKA_SARFACMAN` | 3 | 0 |
| 19:09 | DKA : Transfert des écritures d'ajustements AR vers PA | `DKA_SPAAJUSTAR_TRANSFER` | 3 | 0 |
| 19:11 | DKA : Import des Factures clients | `DKA_IARPAFAC` | 1 | 0 |
| 19:11 | DKA : Import des donnees depuis l'open Interface AP | `DKA_OPEN_INTERFACE_AP_EAI` | 65 | 0 |
| 19:11 | DKA : Import des données Fournisseurs depuis iValua | `DKA_IPOFRS_IVALUA` | 1 | ⚠️ 1 |
| 19:11 | DKA : Import des données Fournisseurs depuis iValua - Chargement des fichiers | `DKA_IPOFRS_IVALUA_LOADER` | 1 | ⚠️ 1 |
| 19:11 | Payables Open Interface Import | `APXIIMPT` | 309 | 0 |
| 19:15 | DKA : Import des commandes depuis iValua | `DKA_IPOCDE_IVALUA` | 1 | 0 |
| 19:15 | DKA : Import des commandes depuis iValua - Chargement des fichiers | `DKA_IPOCDEIVALUA_LOADER` | 1 | 0 |
| 19:16 | Autoinvoice Master Program | `RAXMTR` | 72 | 0 |
| 19:16 | Autoinvoice Import Program | `RAXTRX` | 72 | 0 |
| 19:19 | Import Standard Purchase Orders | `POXPOPDOI` | 82 | 0 |
| 19:31 | DKA : Création des encaissements clients pour le compte de | `DKA_SARAUTENC` | 1 | 0 |
| 19:31 | DKA : Flux SI / CM - Extraction en cours recouvrement | `DKA_IAR_ENCOURS_REC_SICM` | 1 | 0 |
| 19:37 | PO Output for Communication | `POXPOPDF` | 5 | 0 |
| 19:39 | DKA : Import des contrats SSTR depuis iValua | `DKA_IPO_SSTR_IVALUA` | 1 | 0 |
| 19:39 | DKA : Import des contrats SSTR depuis iValua - Chargement des fichiers | `DKA_IPOCTR_SSTR_IVALUA_LOADER` | 1 | 0 |
| 19:41 | DKA : Import des données Réceptions depuis iValua | `DKA_IPORECEPTION_IVALUA` | 1 | 0 |
| 19:41 | DKA : Import des données Réceptions depuis iValua Loader | `DKA_IPORECEPTION_IVALUA_LOADER` | 1 | 0 |
| 19:41 | DKA : Export des encaissements clients | `DKA_SAREXTENCAISSCLIENT` | 1 | 0 |
| 19:42 | DKA : Copie en haut volume périodique | `DKA_FAMCP` | 1 | 0 |
| 19:42 | Periodic Mass Copy | `FAMCP` | 303 | 0 |
| 19:43 | DKA : Créer une comptabilisation - Immobilisations (Lancement de SFAACCPB) | `DKA_SFAACCPB` | 330 | 0 |
| 19:43 | Create Accounting - Assets | `FAACCPB` | 658 | 0 |
| 19:48 | Receiving Transaction Processor | `RVCTP` | 3 | 0 |
| 19:52 | PRC: Tieback Asset Lines from Oracle Assets | `PACFATBP` | 396 | 0 |
| 19:52 | DKA - PRC : Valider l'importation des lignes d'immobilisation dans Oracle Assets | `DKA_PACFATBP` | 1 | 0 |
| 20:00 | DKA : Import des données depuis GL_INTERFACE | `DKA_IGL_INTERFACE_EAI` | 1 | 0 |
| 20:00 | DKA : Export des commandes OA vers Xerox | `DKA_IPOEXTRACTCDE` | 1 | 0 |
| 20:00 | DKA : Chargement du fichier du CDF IVALUA dans la table tmp | `DKA_LOAD_IAPCTRFLUX_IVALUA` | 1 | 0 |
| 20:00 | DKA : Chargement du fichier du CDF Xerox dans la table tmp | `DKA_LOAD_IAPCTRFLUX_XEROX` | 1 | 0 |
| 20:00 | DKA : Insertion des données CDF IVALUA dans la table d'interface | `DKA_INSERT_CDF_IVALUA` | 1 | 0 |
| 20:00 | DKA : Insertion des données CDF Xerox dans la table d'interface | `DKA_INSERT_CDF_XEROX` | 1 | 0 |
| 20:02 | DKA : Chargement du fichier des factures DSP | `DKA_LOAD_IAPFACDSP_TMP` | 1 | 0 |
| 20:02 | DKA : Alimentation des tables OA factures DSP | `DKA_POPULATE_DSP_TABLES` | 1 | 0 |
| 20:03 | DKA : Chargement du fichier des factures Xerox | `DKA_LOAD_IAPFACXGS_TMP` | 1 | 0 |
| 20:03 | DKA : Alimentation des tables factures Xerox | `DKA_POPULATE_XGS_TABLES` | 1 | 0 |
| 20:33 | DKA : Chargement du fichier des factures ZCI - Loader | `DKA_IAPFACZCI_LOADER` | 1 | 0 |
| 20:33 | DKA : Chargement du fichier des factures ZCI | `DKA_LOAD_IAPFACZCI_TMP` | 1 | 0 |
| 20:33 | DKA : Alimentation des tables OA factures ZCI | `DKA_POPULATE_ZCI_TABLES` | 1 | 0 |
| 20:35 | DKA : Intégration des factures XEROX | `DKA_IAPFACXGS` | 1 | 0 |

---

### 🔴 Tranche 21h00–23h00 — Contrôles flux, Approbations, Validation factures AP

| Heure habituelle | Programme | Nom technique | Nb exec réf. | Erreurs réf. |
|---|---|---|---|---|
| 21:16 | DKA: Import des clients OI | `DKA_ICLIENTIFS_3` | 1 | 0 |
| 21:16 | Customer Interface Master Conc Program | `RACUSTMA` | 1 | 0 |
| 21:16 | Customer Interface Sub Request | `RACUSTSB` | 15 | 0 |
| 21:31 | DKA : Contrôle des flux XEROX | `DKA_IAPCTRFLUX_XEROX` | 1 | 0 |
| 21:31 | DKA : Contrôle des flux IVALUA | `DKA_IAPCTRFLUX_IVALUA` | 1 | 0 |
| 21:32 | DKA : Import des codes de déblocage Facture depuis IVALUA | `DKA_IAPFAC_DEBLOC_INTERFACE` | 1 | 0 |
| 21:32 | DKA : Import des codes de déblocage Facture depuis IVALUA - Chargement du fichier | `DKA_IAPFAC_DEBLOC_LOADER` | 1 | 0 |
| 21:35 | DKA : Création blocages toutes sociétés avant comptabilisation factures AP | `DKA_SAPCREATE_BLOCAGES_ALL` | 1 | 0 |
| 21:35 | DKA : Création blocages comptabilisation factures AP | `DKA_SAPCREATE_BLOCAGES` | 371 | 0 |
| 21:35 | DKA : Automatisation de déblocage BAP factures rapprochées des commandes SSTR en PMTDIR | `DKA_SAPDEBAUTOSSTR` | 1 | 0 |
| 21:35 | DKA : Approbation toutes sociétés des factures fournisseurs | `DKA_SAPAPPRVL` | 1 | 0 |
| 21:40 | Invoice Validation | `APPRVL` | 192 | 0 |
| 21:40 | Invoice Validation Child Worker Process | `WORKERAPPRVL` | 255 | 0 |
| 21:56 | DQM Serial Sync Index Program | `ARHDQMSS` | 6 | 0 |
| 22:08 | DKA : Comptabilisation AP | `DKA_SXLAACCPB` | 1 | 0 |

---

### 🔴 Tranche 23h00–00h00 — Interface Projets, Posting GL, Datalake

| Heure habituelle | Programme | Nom technique | Nb exec réf. | Erreurs réf. |
|---|---|---|---|---|
| 23:08 | DKA : PAC : Transférer les notes de frais depuis Oracle Payables | `DKA_SPAAPIMP` | 1 | 0 |
| 23:08 | DKA : PAC : Importer les factures fournisseurs depuis Oracle AP | `DKA_SPAAPIMP_SI` | 1 | 0 |
| 23:08 | PRC: Interface Supplier Costs | `PAAPIMP_SI` | 136 | 0 |
| 23:09 | PRC: Interface Expense Reports from Payables | `PAAPIMP` | 17 | 0 |
| 23:09 | AUD: Supplier Costs Interface Audit | `PAAPIMPR` | 153 | 0 |
| 23:14 | DKA : Imputation GL | `DKA_SGLIMPUTATION` | 1 | 0 |
| 23:14 | DKA : Extraction du statut des factures fournisseurs | `DKA_SAPEXTSTATFAC` | 1 | 0 |
| 23:14 | Program - Automatic Posting | `GLPAUTOP` | 1 | 0 |
| 23:14 | Posting | `GLPPOS` | 1 | 0 |
| 23:15 | DKA : Rattachement des images Xerox | `DKA_IAPLOADIMG_XEROX` | 1 | 0 |
| 23:16 | DKA : Import des clients : Post Open Interface | `DKA_ICLIENTIFS_2` | 1 | 0 |
| 23:18 | DKA : Traitement de validation des factures CSP | `DKA_SAPWFCSP` | 5 | 0 |
| 23:19 | DKA : Import des images des factures INVOICE | `DKA_APLOADIMG` | 1 | 0 |
| 23:24 | DKA : Transfert d'écritures GL vers PA | `DKA_SPACUTOFF_TRANSFER` | 1 | 0 |
| 23:24 | Posting: Single Ledger | `GLPPOSS` | 8 | 0 |
| 23:27 | DKA : Export des données factures AP pour Datalake | `DKA_SAPEXTDATAFACT` | 1 | 0 |
| 23:27 | DKA : Export de Blocages Factures pour le Datalake | `DKA_SAPEXTDATABLOC` | 1 | 0 |
| 23:27 | DKA : Comparaison mensuelle - Chargement de la table DKA_SARG00C8 | `DKA_SARG00C8_LOAD` | 1 | 0 |
| 23:30 | DKA : Comparaison mensuelle - Etat de comparaison | `DKA_SARG00C8_ETAT` | 1 | 0 |
| 23:34 | DKA : Envoi par mail de l'état de comparaison des factures CID | `DKA_SARG00C8_MAIL` | 1 | 0 |
| 23:38 | DKA : Post traitement d'approbation du mouvement | `DKA_SAPPOST_APPRO_MVT` | 1 | 0 |
| 23:41 | Workflow Background Process | `FNDWFBG` | 1 | 0 |
| 23:53 | DKA : Reporting des mvts sans image | `DKA_SAPRPT_MVTS_SANS_IMAGE` | 4 | 0 |
| 23:53 | DKA - Alimenter les références de facture AP dans RB | `DKA_ALIMREFFACTURE_AP_RB` | 1 | 0 |
| 23:54 | DKA - Identification des factures AP éligibles au rapprochement RB | `DKA_SRBFACTURE_AP` | 1 | 0 |
| 23:55 | DKA : Annulation des notifications obsolètes CSP | `DKA_SAPWFCSPNTF` | 1 | 0 |
| 23:56 | DKA : Suivi des notifications ouvertes | `DKA_SAPSUIVI_NOTIF` | 1 | 0 |
| 23:59 | Purge Obsolete Workflow Runtime Data | `FNDWFPR` | 1 | 0 |

---

### 🔴 Tranche 00h00–02h00 — Règlements, Virements, Prélèvements

| Heure habituelle | Programme | Nom technique | Nb exec réf. | Erreurs réf. |
|---|---|---|---|---|
| 00:00 | DKA : Création des règlements pour la campagne de prélèvement AP - RB | `DKA_PREL_AP_RB_CREA` | 1 | 0 |
| 00:00 | Payment Process Request Program | `APXPBASL` | 390 | 0 |
| 00:00 | Scheduled Payment Selection Report | `APINVSEL` | 67 | 0 |
| 00:00 | Build Payments | `IBYBUILD` | 67 | 0 |
| 00:00 | Format Payment Instructions | `IBY_FD_PAYMENT_FORMAT` | 10 | 0 |
| 00:14 | DKA : Comptabilisation des règlements pour la campagne de prélèvement AP - RB | `DKA_SAPPRELAUTORB_COMPTA` | 1 | 0 |
| 00:15 | DKA : Extraction des engagés vers Hercule | `DKA_IPAEXT_ENG_HER` | 1 | 0 |
| 00:18 | DKA : Règlements automatiques toutes sociétés des factures fournisseurs | `DKA_SAPAUTORGT` | 2 | 0 |
| 00:24 | Format Payment Instructions with Text Output | `IBY_FD_PAYMENT_FORMAT_TEXT` | 54 | 0 |
| 00:37 | DKA Compression des fichiers en zip | `DKA_COMPRESS_FICHIER` | 1 | 0 |
| 01:48 | DKA : Campagne de règlements - Alimentation des tables AP Import | `DKA_IEOAPSAT01_APIMP` | 2 | 0 |
| 01:50 | DKA : Campagne de règlements - Création du fichier APIMPORT | `DKA_CREATE_APIMPORT_FILE` | 2 | 0 |
| 01:51 | DKA : Calcul du poids SATI et envoi de mail | `DKA_SSATIPOIDSMAIL` | 2 | 0 |
| 01:51 | DKA : Etat calcul du poids | `DKA_SSATIPOIDS_RDF` | 2 | 0 |
| 01:53 | DKA : Automatisation envoi avis de virement par mail | `DKA_SAPAUTOVIR_MAIL` | 2 | 0 |
| 01:53 | DKA : Création du fichier avis de virement | `DKA_RAPVIR_PDF` | 254 | 0 |
| 01:55 | DKA : Envoi avis de virement par mail | `DKA_SAPVIR_MAIL` | 2 | 0 |
| 01:55 | DKA : Rattachement de l'avis de virement au règlement AP | `DKA_SAPVIR_ATTACH` | 2 | 0 |
| 01:58 | DKA : Règlements automatiques des prélèvements clients | `DKA_SARAUTOPRELEV` | 1 | 0 |
| 01:58 | DKA : Lancement de confirmation des lots de règlements | `DKA_SARRGLTPRLV_CONFIRM_AUT` | 1 | 0 |
| 01:58 | DKA : Confirmation des lots de règlements pour prélèvement automatique | `DKA_ARCONFIRMLOT` | 44 | 0 |
| 01:58 | Automatic Receipts Creation Program (API) | `AR_AUTORECAPI` | 325 | 0 |
| 01:58 | Automatic Receipts/Remittances Execution Report | `ARZCARPO` | 331 | 0 |
| 01:58 | Automatic Remittances Creation Program (API) | `AUTOREMAPI` | 6 | 0 |
| 01:59 | DKA : France - Bordereau des prélèvements clients | `DKAPR02` | 6 | 0 |

---

### 🔴 Tranche 02h00–04h00 — Prélèvements clients, RB, Exports DTR

| Heure habituelle | Programme | Nom technique | Nb exec réf. | Erreurs réf. |
|---|---|---|---|---|
| 02:03 | DKA : Etat définitif des prélèvements clients | `DKA_RAR_PRELEVCLINETDEF` | 8 | 0 |
| 02:03 | DKA : Automatisation de l'état définitif des prélèvements clients | `DKA_SARRGLTPRLV_AUTO3` | 8 | ⚠️ 1 |
| 02:03 | DKA : Envoi des états pour le prélèvement automatique | `DKA_SARRGLTPRLV_MAIL` | 8 | ⚠️ 1 |
| 02:07 | Create Settlement Batches | `IBY_FC_CREATE_SETTLE_BATCHES` | 1 | 0 |
| 02:07 | DKA : Campagne de prélèvements Clients - Création du fichier DDIMPORT | `DKA_CREATE_DDIMPORT_FILE` | 1 | 0 |
| 02:08 | Reprints output from concurrent requests | `FNDREPRINT` | 6 | 0 |
| 02:10 | DKA : Automatisation avis de prélèvements clients | `DKA_SARAVIPRELEV` | 1 | 0 |
| 02:10 | DKA : Création du fichier avis de prélèvement | `DKA_RARPREL_PDF` | 6 | 0 |
| 02:11 | DKA : Rattachement de l'avis de prélèvement au règlement AR | `DKA_SARPREL_ATTACH` | 1 | 0 |
| 02:13 | DKA : Etat des prélèvements remis en banque | `DKA_RAR_PRELEVBQUE` | 8 | 0 |
| 02:13 | DKA : Automatisation des prélèvements remis en banque | `DKA_SARAUTOPRELEVBQUE` | 8 | 0 |
| 03:24 | XXRB - Import des mouvements comptables | `RBINTOAF` | 1 | 0 |
| 03:24 | DKA : Export des données Factures vers iValua | `DKA_IAPFAC_IVALUA` | 1 | 0 |
| 03:24 | DKA : Situation Oracle du matin | `DKA_SCTRLMOD_MOA_EDT` | 4 | 0 |
| 03:24 | DKA : Extraction du statut des factures TradeShift | `DKA_IAPFACTTDS` | 1 | 0 |
| 03:24 | DKA : Extraction des coordonnées bancaires | `DKA_ICE_BANKBRANCHES_DTR` | 1 | 0 |
| 03:24 | DKA : Extraction des évènements AR | `DKA_IAR_EVENEMENTS_DTR` | 1 | 0 |
| 03:24 | DKA : Extraction du contrôle de flux | `DKA_SCTLFLUX_EAI` | 1 | 0 |
| 03:25 | DKA : Envoi par mail des fichiers de situation Oracle du matin | `DKA_SCTRLMOD_MOA_MAIL` | 4 | 0 |
| 03:28 | DKA : Alimentation de la référence pour la ligne GL dans RB | `DKA_SRBALIMREF` | 1 | 0 |
| 03:43 | DKA : Export des images Factures vers iValua | `DKA_IAPIMG_IVALUA` | 1 | 0 |

---

## 3. INVENTAIRE COMPLET DES TRAITEMENTS PÉRIODIQUES (8 semaines)

*Fréquence mesurée sur les 8 dernières semaines (56 jours)*  
*Seuil de périodicité : ≥ 3 soirs sur la période*

| Nb soirs | Programme | Nom technique | Dernier soir exécuté | % Erreurs |
|---|---|---|---|---|
| 35 | AUD: Supplier Costs Interface Audit | `PAAPIMPR` | 16/03/2026 | 0% |
| 35 | Create Accounting | `XLAACCPB` | 16/03/2026 | 0% |
| 35 | DKA : Annulation des notifications obsolètes CSP | `DKA_SAPWFCSPNTF` | 16/03/2026 | 0% |
| 35 | DKA : Approbation toutes sociétés des factures fournisseurs | `DKA_SAPAPPRVL` | 16/03/2026 | 0% |
| 35 | DKA : Automatisation de déblocage BAP factures rapprochées des commandes SSTR en PMTDIR | `DKA_SAPDEBAUTOSSTR` | 16/03/2026 | 0% |
| 35 | DKA : Comptabilisation AP | `DKA_SXLAACCPB` | 16/03/2026 | 0% |
| 35 | DKA : Contrôle des flux IVALUA | `DKA_IAPCTRFLUX_IVALUA` | 16/03/2026 | 0% |
| 35 | DKA : Création blocages comptabilisation factures AP | `DKA_SAPCREATE_BLOCAGES` | 16/03/2026 | 0% |
| 35 | DKA : Création blocages toutes sociétés avant comptabilisation factures AP | `DKA_SAPCREATE_BLOCAGES_ALL` | 16/03/2026 | 0% |
| 35 | DKA : Export de Blocages Factures pour le Datalake | `DKA_SAPEXTDATABLOC` | 16/03/2026 | 0% |
| 35 | DKA : Export des données factures AP pour Datalake | `DKA_SAPEXTDATAFACT` | 16/03/2026 | 0% |
| 35 | DKA : Intégration des factures XEROX | `DKA_IAPFACXGS` | 16/03/2026 | 0% |
| 35 | DKA : Lanceur (SHELL) | `DKA_SLAUNCHER` | 16/03/2026 | 1% |
| 35 | DKA : PAC : Importer les factures fournisseurs depuis Oracle AP | `DKA_SPAAPIMP_SI` | 16/03/2026 | 0% |
| 35 | DKA : PAC : Transférer les notes de frais depuis Oracle Payables | `DKA_SPAAPIMP` | 16/03/2026 | 0% |
| 35 | DKA : Post traitement d'approbation du mouvement | `DKA_SAPPOST_APPRO_MVT` | 16/03/2026 | 0% |
| 35 | DKA : Rattachement des images Xerox | `DKA_IAPLOADIMG_XEROX` | 16/03/2026 | 0% |
| 35 | DKA : Reporting des mvts sans image | `DKA_SAPRPT_MVTS_SANS_IMAGE` | 16/03/2026 | 0% |
| 35 | DKA : Traitement de validation des factures CSP | `DKA_SAPWFCSP` | 16/03/2026 | 0% |
| 35 | Invoice Validation | `APPRVL` | 16/03/2026 | 0% |
| 35 | Invoice Validation Child Worker Process | `WORKERAPPRVL` | 16/03/2026 | 0% |
| 35 | PRC: Interface Supplier Costs | `PAAPIMP_SI` | 16/03/2026 | 0% |
| 35 | Payables Open Interface Import | `APXIIMPT` | 16/03/2026 | 0% |
| 35 | Purge Obsolete Workflow Runtime Data | `FNDWFPR` | 16/03/2026 | 0% |
| 35 | Report Set | `FNDRSSUB` | 16/03/2026 | 0% |
| 35 | Request Set Stage | `FNDRSSTG` | 16/03/2026 | 0% |
| 35 | Workflow Background Process | `FNDWFBG` | 16/03/2026 | 0% |
| 34 | Accounting Program | `XLAACCUP` | 16/03/2026 | 0% |
| 34 | DKA : Comptabilisation AR | `DKA_SXLAACCPBAR` | 16/03/2026 | 0% |
| 34 | DKA : Interface des factures manuelles sur projets | `DKA_SARFACMAN` | 16/03/2026 | 0% |
| 34 | DKA : Transfert des écritures d'ajustements AR vers PA | `DKA_SPAAJUSTAR_TRANSFER` | 16/03/2026 | 0% |
| 33 | DKA : Envoi par mail des fichiers de situation Oracle du matin | `DKA_SCTRLMOD_MOA_MAIL` | 16/03/2026 | 4% |
| 33 | DKA : Situation Oracle du matin | `DKA_SCTRLMOD_MOA_EDT` | 16/03/2026 | 4% |
| 33 | Journal Import | `GLLEZL` | 16/03/2026 | 0% |
| 33 | Open Account Balances Data Manager | `XLATBDMG` | 16/03/2026 | 0% |
| 33 | Open Account Balances Data Manager Worker Process | `XLATBDMW` | 16/03/2026 | 0% |
| 33 | Update Subledger Accounting Balances | `XLABAPUB` | 16/03/2026 | 0% |
| 31 | DKA : Alimentation des tables OA factures ZCI | `DKA_POPULATE_ZCI_TABLES` | 16/03/2026 | 0% |
| 31 | DKA : Chargement du fichier des factures ZCI | `DKA_LOAD_IAPFACZCI_TMP` | 16/03/2026 | 0% |
| 31 | DKA : Chargement du fichier des factures ZCI - Loader | `DKA_IAPFACZCI_LOADER` | 16/03/2026 | 0% |
| 30 | DKA : Imputation GL | `DKA_SGLIMPUTATION` | 16/03/2026 | 0% |
| 30 | DKA : Transfert d'écritures GL vers PA | `DKA_SPACUTOFF_TRANSFER` | 16/03/2026 | 3% |
| 30 | Posting | `GLPPOS` | 16/03/2026 | 0% |
| 30 | Program - Automatic Posting | `GLPAUTOP` | 16/03/2026 | 0% |
| 29 | PRC: Interface Expense Reports from Payables | `PAAPIMP` | 16/03/2026 | 0% |
| 29 | Posting: Single Ledger | `GLPPOSS` | 16/03/2026 | 0% |
| 28 | DKA : Extraction du statut des factures fournisseurs | `DKA_SAPEXTSTATFAC` | 16/03/2026 | 0% |
| 25 | DKA : Alimentation des tables OA factures DSP | `DKA_POPULATE_DSP_TABLES` | 16/03/2026 | 0% |
| 25 | DKA : Chargement du fichier des factures DSP | `DKA_LOAD_IAPFACDSP_TMP` | 16/03/2026 | 0% |
| 25 | DKA : Chargement du fichier du CDF IVALUA dans la table tmp | `DKA_LOAD_IAPCTRFLUX_IVALUA` | 16/03/2026 | 0% |
| 25 | DKA : Chargement du fichier du CDF Xerox dans la table tmp | `DKA_LOAD_IAPCTRFLUX_XEROX` | 16/03/2026 | 4% |
| 25 | DKA : Contrôle des flux XEROX | `DKA_IAPCTRFLUX_XEROX` | 16/03/2026 | 0% |
| 25 | DKA : Export des commandes OA vers Xerox | `DKA_IPOEXTRACTCDE` | 16/03/2026 | 0% |
| 25 | DKA : Export des données Factures vers iValua | `DKA_IAPFAC_IVALUA` | 16/03/2026 | 0% |
| 25 | DKA : Export des images Factures vers iValua | `DKA_IAPIMG_IVALUA` | 16/03/2026 | 0% |
| 25 | DKA : Extraction des engagés vers Hercule | `DKA_IPAEXT_ENG_HER` | 16/03/2026 | 0% |
| 25 | DKA : Import des codes de déblocage Facture depuis IVALUA | `DKA_IAPFAC_DEBLOC_INTERFACE` | 16/03/2026 | 0% |
| 25 | DKA : Import des codes de déblocage Facture depuis IVALUA - Chargement du fichier | `DKA_IAPFAC_DEBLOC_LOADER` | 16/03/2026 | 0% |
| 25 | DKA : Import des données Réceptions depuis iValua | `DKA_IPORECEPTION_IVALUA` | 16/03/2026 | 8% |
| 25 | DKA : Import des données depuis GL_INTERFACE | `DKA_IGL_INTERFACE_EAI` | 16/03/2026 | 0% |
| 25 | DKA : Import des images des factures INVOICE | `DKA_APLOADIMG` | 16/03/2026 | 0% |
| 25 | DKA : Insertion des données CDF IVALUA dans la table d'interface | `DKA_INSERT_CDF_IVALUA` | 16/03/2026 | 0% |
| 25 | DKA : Suivi des notifications ouvertes | `DKA_SAPSUIVI_NOTIF` | 16/03/2026 | 0% |
| 25 | DKA Compression des fichiers en zip | `DKA_COMPRESS_FICHIER` | 16/03/2026 | 0% |
| 24 | Build Payments | `IBYBUILD` | 16/03/2026 | 0% |
| 24 | Calculate Gains and Losses | `FARET` | 16/03/2026 | 0% |
| 24 | Create Accounting - Assets | `FAACCPB` | 16/03/2026 | 0% |
| 24 | Create Settlement Batches | `IBY_FC_CREATE_SETTLE_BATCHES` | 16/03/2026 | 0% |
| 24 | DKA - Alimenter les références de facture AP dans RB | `DKA_ALIMREFFACTURE_AP_RB` | 16/03/2026 | 0% |
| 24 | DKA - Identification des factures AP éligibles au rapprochement RB | `DKA_SRBFACTURE_AP` | 16/03/2026 | 0% |
| 24 | DKA - PRC : Valider l'importation des lignes d'immobilisation dans Oracle Assets | `DKA_PACFATBP` | 16/03/2026 | 0% |
| 24 | DKA : Alimentation des tables factures Xerox | `DKA_POPULATE_XGS_TABLES` | 16/03/2026 | 0% |
| 24 | DKA : Automatisation avis de prélèvements clients | `DKA_SARAVIPRELEV` | 16/03/2026 | 0% |
| 24 | DKA : Automatisation des prélèvements remis en banque | `DKA_SARAUTOPRELEVBQUE` | 16/03/2026 | 0% |
| 24 | DKA : Calculer les plus- et moins-values | `DKA_FARET` | 16/03/2026 | 0% |
| 24 | DKA : Campagne de prélèvements Clients - Création du fichier DDIMPORT | `DKA_CREATE_DDIMPORT_FILE` | 16/03/2026 | 0% |
| 24 | DKA : Chargement du fichier des factures Xerox | `DKA_LOAD_IAPFACXGS_TMP` | 16/03/2026 | 0% |
| 24 | DKA : Comptabilisation des règlements pour la campagne de prélèvement AP - RB | `DKA_SAPPRELAUTORB_COMPTA` | 16/03/2026 | 0% |
| 24 | DKA : Copie en haut volume périodique | `DKA_FAMCP` | 16/03/2026 | 0% |
| 24 | DKA : Création des règlements pour la campagne de prélèvement AP - RB | `DKA_PREL_AP_RB_CREA` | 16/03/2026 | 0% |
| 24 | DKA : Créer une comptabilisation - Immobilisations (Lancement de SFAACCPB) | `DKA_SFAACCPB` | 16/03/2026 | 0% |
| 24 | DKA : Etat des prélèvements remis en banque | `DKA_RAR_PRELEVBQUE` | 16/03/2026 | 0% |
| 24 | DKA : Export des encaissements clients | `DKA_SAREXTENCAISSCLIENT` | 16/03/2026 | 0% |
| 24 | DKA : Export du référentiel employé vers NOTILUS | `DKA_IAPEMPLNOT` | 16/03/2026 | 0% |
| 24 | DKA : Export journalier des fournisseurs | `DKA_APFRSEXP_JOUR` | 16/03/2026 | 0% |
| 24 | DKA : Flux SI / CM - Extraction en cours recouvrement | `DKA_IAR_ENCOURS_REC_SICM` | 16/03/2026 | 0% |
| 24 | DKA : Generer des comptes | `DKA_FAGDA` | 16/03/2026 | 0% |
| 24 | DKA : Import des commandes depuis iValua | `DKA_IPOCDE_IVALUA` | 16/03/2026 | 4% |
| 24 | DKA : Import des commandes depuis iValua - Chargement des fichiers | `DKA_IPOCDEIVALUA_LOADER` | 16/03/2026 | 4% |
| 24 | DKA : Import des contrats SSTR depuis iValua | `DKA_IPO_SSTR_IVALUA` | 16/03/2026 | 0% |
| 24 | DKA : Import des contrats SSTR depuis iValua - Chargement des fichiers | `DKA_IPOCTR_SSTR_IVALUA_LOADER` | 16/03/2026 | 0% |
| 24 | DKA : Import des donnees depuis l'open Interface AP | `DKA_OPEN_INTERFACE_AP_EAI` | 16/03/2026 | 0% |
| 24 | DKA : Import des données Réceptions depuis iValua Loader | `DKA_IPORECEPTION_IVALUA_LOADER` | 16/03/2026 | 8% |
| 24 | DKA : Insertion des données CDF Xerox dans la table d'interface | `DKA_INSERT_CDF_XEROX` | 16/03/2026 | 0% |
| 24 | DKA : Mise à jour des rattachements de sites fournisseurs sur commande ouverte globale | `DKA_SPODUPSITECOG` | 16/03/2026 | 0% |
| 24 | DKA : Rattachement de l'avis de prélèvement au règlement AR | `DKA_SARPREL_ATTACH` | 16/03/2026 | 0% |
| 24 | DKA : Règlements automatiques des prélèvements clients | `DKA_SARAUTOPRELEV` | 16/03/2026 | 0% |
| 24 | DKA : Règlements automatiques toutes sociétés des factures fournisseurs | `DKA_SAPAUTORGT` | 16/03/2026 | 0% |
| 24 | Format Payment Instructions | `IBY_FD_PAYMENT_FORMAT` | 16/03/2026 | 0% |
| 24 | Generate Accounts | `FAGDA` | 16/03/2026 | 0% |
| 24 | Import Standard Purchase Orders | `POXPOPDOI` | 16/03/2026 | 0% |
| 24 | PRC: Tieback Asset Lines from Oracle Assets | `PACFATBP` | 16/03/2026 | 0% |
| 24 | Payment Process Request Program | `APXPBASL` | 16/03/2026 | 0% |
| 24 | Periodic Mass Copy | `FAMCP` | 16/03/2026 | 0% |
| 24 | Scheduled Payment Selection Report | `APINVSEL` | 16/03/2026 | 0% |
| 23 | DKA : Automatisation envoi avis de virement par mail | `DKA_SAPAUTOVIR_MAIL` | 16/03/2026 | 0% |
| 23 | DKA : Calcul du poids SATI et envoi de mail | `DKA_SSATIPOIDSMAIL` | 16/03/2026 | 0% |
| 23 | DKA : Campagne de règlements - Alimentation des tables AP Import | `DKA_IEOAPSAT01_APIMP` | 16/03/2026 | 0% |
| 23 | DKA : Campagne de règlements - Création du fichier APIMPORT | `DKA_CREATE_APIMPORT_FILE` | 16/03/2026 | 0% |
| 23 | DKA : Création des encaissements clients pour le compte de | `DKA_SARAUTENC` | 16/03/2026 | 0% |
| 23 | DKA : Création du fichier avis de virement | `DKA_RAPVIR_PDF` | 16/03/2026 | 0% |
| 23 | DKA : Envoi avis de virement par mail | `DKA_SAPVIR_MAIL` | 16/03/2026 | 0% |
| 23 | DKA : Etat calcul du poids | `DKA_SSATIPOIDS_RDF` | 16/03/2026 | 0% |
| 23 | DKA : Extraction des coordonnées bancaires | `DKA_ICE_BANKBRANCHES_DTR` | 16/03/2026 | 0% |
| 23 | DKA : Extraction des évènements AR | `DKA_IAR_EVENEMENTS_DTR` | 16/03/2026 | 0% |
| 23 | DKA : Extraction du contrôle de flux | `DKA_SCTLFLUX_EAI` | 16/03/2026 | 0% |
| 23 | DKA : Extraction du statut des factures TradeShift | `DKA_IAPFACTTDS` | 16/03/2026 | 0% |
| 23 | DKA : Import des Factures clients | `DKA_IARPAFAC` | 16/03/2026 | 0% |
| 23 | DKA : Import des données Fournisseurs depuis iValua | `DKA_IPOFRS_IVALUA` | 16/03/2026 | 4% |
| 23 | DKA : Import des données Fournisseurs depuis iValua - Chargement des fichiers | `DKA_IPOFRS_IVALUA_LOADER` | 16/03/2026 | 4% |
| 23 | DKA : Rattachement de l'avis de virement au règlement AP | `DKA_SAPVIR_ATTACH` | 16/03/2026 | 0% |
| 23 | Format Payment Instructions with Text Output | `IBY_FD_PAYMENT_FORMAT_TEXT` | 16/03/2026 | 0% |
| 23 | Receiving Transaction Processor | `RVCTP` | 13/03/2026 | 0% |
| 23 | XXRB - Import des mouvements comptables | `RBINTOAF` | 16/03/2026 | 0% |
| 22 | Autoinvoice Import Program | `RAXTRX` | 13/03/2026 | 0% |
| 22 | Autoinvoice Master Program | `RAXMTR` | 13/03/2026 | 0% |
| 22 | DKA : Alimentation de la référence pour la ligne GL dans RB | `DKA_SRBALIMREF` | 16/03/2026 | 0% |
| 22 | DKA : Duplication en masse des sites fournisseurs | `DKA_SAPFRSDUPLI_MASSE` | 16/03/2026 | 0% |
| 21 | Automatic Receipts/Remittances Execution Report | `ARZCARPO` | 16/03/2026 | 0% |
| 18 | Automatic Remittances Creation Program (API) | `AUTOREMAPI` | 16/03/2026 | 0% |
| 18 | DKA : Création du fichier avis de prélèvement | `DKA_RARPREL_PDF` | 16/03/2026 | 0% |
| 18 | DKA : France - Bordereau des prélèvements clients | `DKAPR02` | 16/03/2026 | 0% |
| 18 | Reprints output from concurrent requests | `FNDREPRINT` | 16/03/2026 | 0% |
| 14 | PO Output for Communication | `POXPOPDF` | 16/03/2026 | 0% |
| 11 | DKA : Edition des fichiers de contrôle de pre-cloture | `DKA_SCTRLMODULE_EDT` | 02/03/2026 | 0% |
| 11 | DKA : Envoi par mail des fichiers de contrôle de pré-clôture | `DKA_SCTRLMODULE_MAIL` | 02/03/2026 | 0% |
| 10 | DKA : Envoi des états pour le prélèvement automatique | `DKA_SARRGLTPRLV_MAIL` | 10/03/2026 | 10% |
| 9 | DKA : campagne de lettrage à zéro | `DKA_CAMPAGNE_LETTRAGE_ZERO` | 14/03/2026 | 0% |
| 8 | DKA - Interface lignes d'écritures comptables vers HYPERION | `DKA_IHYPERION` | 03/03/2026 | 0% |
| 8 | DKA - Interface lignes d'écritures comptables vers HYPERION - Quantités | `DKA_IHYPERION_QTE` | 03/03/2026 | 0% |
| 7 | Automatic Receipts Creation Program (API) | `AR_AUTORECAPI` | 10/03/2026 | 0% |
| 7 | DKA : Automate Etat des avoirs à rembourser | `DKA_AUT_SARETAT_AVOIR` | 16/03/2026 | 0% |
| 7 | DKA : Echeancier Fournisseur Provisoire | `DKA_APXCRRCR` | 13/03/2026 | 0% |
| 7 | DKA : Echéancier provisoire tous Soc/CdG | `DKA_SAPXCRRCR` | 13/03/2026 | 0% |
| 7 | DKA : Etat des avoirs à rembourser | `DKA_SARETAT_AVOIR_REG` | 16/03/2026 | 0% |
| 6 | DKA : Envoi d'un email avec attachement | `DKA_MAIL` | 27/02/2026 | 0% |
| 4 | DKA : Automate Etat Sélection des avoirs non soldés à rembourser | `DKA_AUTO_SARSELECAVOIR` | 12/03/2026 | 0% |
| 4 | DKA : Automatisation de l'état définitif des prélèvements clients | `DKA_SARRGLTPRLV_AUTO3` | 10/03/2026 | 25% |
| 4 | DKA : Confirmation des lots de règlements pour prélèvement automatique | `DKA_ARCONFIRMLOT` | 10/03/2026 | 0% |

---

## 4. ACTIONS RECOMMANDÉES

1. **URGENT** — Vérifier le statut du Manager `DKA_SLAUNCHER` dans Oracle EBS (Concurrent Managers) — il n'a pas démarré à 19h00 le 17/03/2026.
2. **Relancer manuellement** les traitements critiques de la tranche 19h-21h : comptabilisations XLA, imports iValua, immobilisations FA.
3. **Contrôler la chaîne de paiement** (règlements virements 00h-02h) — les avis de virement du 18/03 n'ont pas été générés ni envoyés.
4. **Vérifier les fichiers iValua** en attente (fournisseurs, commandes, réceptions) — ils sont présents sur le serveur mais non traités.
5. **Notifier l'équipe de cloture** : aucune comptabilisation GL n'a eu lieu cette nuit (XLA, Journal Import, Posting).

---

## 5. TRAITEMENTS DE FIN DE MOIS

*Analyse sur 12 mois — programmes dont l'exécution est concentrée sur les derniers jours du mois*  
*Source : répartition historique des exécutions par jour du mois (FND_CONCURRENT_REQUESTS)*

---

### 5.1 Synthèse des groupes de fin de mois

| Groupe | Jours typiques | Programmes concernés | Prochain déclenchement estimé |
|---|---|---|---|
| **Refacturation** | j24 → j27 | 3 programmes | ~24/03/2026 |
| **Pré-clôture (contrôles)** | j16 → j27 + j1-j2 mois suivant | 2 programmes | ~19/03/2026 ← **imminent** |
| **HYPERION / GL récurrent** | j20 → j27 + j2-j3 mois suivant | 3 programmes | ~20/03/2026 ← **imminent** |

---

### 5.2 Groupe A — Refacturation automatique (j24–j27)

*Tournent exclusivement sur les jours 24 à 27 du mois — 100% fin de mois*

| Programme | Nom technique | Fév-26 (jours exec) | Attendu Mar-26 |
|---|---|---|---|
| DKA : Refacturation automatique | `DKA_SARREFAC` | 24, 25, 26, 27 | ~24-27/03/2026 |
| DKA : Refacturation automatique (impression) | `DKA_SARREFAC_PRT` | 24, 25, 26, 27 | ~24-27/03/2026 |
| DKA : Edition des factures de refacturation | `DKA_SARREFAC_GPE` | 24, 25, 26, 27 | ~24-27/03/2026 |

> Ces 3 programmes tournent **en chaîne** sur plusieurs soirs consécutifs en fin de mois. Ils n'ont **pas d'exécutions en dehors** de cette plage.

---

### 5.3 Groupe B — Contrôle de pré-clôture (j16–j27 + débordement début mois suivant)

*Tournent chaque soir sur ~10 jours en fin de mois + les tout premiers jours du mois suivant*

| Programme | Nom technique | Fév-26 (jours exec) | Mar-26 (jours exec) | Attendu suite Mar-26 |
|---|---|---|---|---|
| DKA : Edition des fichiers de contrôle de pre-cloture | `DKA_SCTRLMODULE_EDT` | 16, 17, 18, 19, 20, 23, 24, 25, 26, 27 | 02 | **~19 → 31/03** |
| DKA : Envoi par mail des fichiers de contrôle de pré-clôture | `DKA_SCTRLMODULE_MAIL` | 16, 17, 18, 19, 20, 23, 24, 25, 26, 27 | 02 | **~19 → 31/03** |

> ⚠️ **Ces programmes devraient démarrer dès le 19/03/2026** (demain) si le pattern de février se reproduit.  
> Le batch du soir du 17/03 étant absent, la première exécution est manquée si le démarrage était prévu ce soir.

---

### 5.4 Groupe C — Interface HYPERION et Journaux récurrents (j20–j27 + début mois suivant)

*Exportent les données vers HYPERION pour la clôture mensuelle — se déclenchent sur les deux dernières semaines du mois*

| Programme | Nom technique | Fév-26 (jours exec) | Mar-26 (jours exec) | Attendu suite Mar-26 |
|---|---|---|---|---|
| DKA - Interface lignes d'écritures comptables vers HYPERION | `DKA_IHYPERION` | 20, 23, 24, 25, 26, 27 | 02, 03 | **~20 → 31/03 + début avr.** |
| DKA - Interface lignes d'écritures comptables vers HYPERION - Quantités | `DKA_IHYPERION_QTE` | 20, 23, 24, 25, 26, 27 | 02, 03 | **~20 → 31/03 + début avr.** |
| Recurring Journal Entry | `GLPRJE` | 20, 23, 27 | 03 | **~20 → 31/03** |

---

### 5.5 Calendrier de fin de mois prévisionnel — Mars 2026

*Basé sur le pattern observé en Février 2026*

```
Semaine du 16/03 → 20/03  (cette semaine)
  - 18/03 (ce soir) : batch non lancé — 1er soir SCTRLMODULE possiblement manqué
  - 19/03 (jeudi)   : 1er soir attendu DKA_SCTRLMODULE_EDT / _MAIL (pré-clôture)
  - 20/03 (vendredi): DKA_IHYPERION, DKA_IHYPERION_QTE, GLPRJE

Semaine du 23/03 → 27/03
  - 23/03 (lundi)   : HYPERION + SCTRLMODULE
  - 24/03 (mardi)   : SARREFAC + HYPERION + SCTRLMODULE   ← début refacturation
  - 25/03 (mercredi): SARREFAC + HYPERION + SCTRLMODULE
  - 26/03 (jeudi)   : SARREFAC + HYPERION + SCTRLMODULE
  - 27/03 (vendredi): SARREFAC + HYPERION + SCTRLMODULE + GLPRJE

Début avril (01-03/04)
  - 01-03/04 : Débordement HYPERION + SCTRLMODULE (clôture finale)
```

> ⚠️ **ALERTE CLÔTURE** : Le batch non lancé du 17/03 peut déjà impacter la pré-clôture de mars si des traitements de fin de mois devaient démarrer cette semaine. Vérifier avec l'équipe comptable.

---

*Analyse générée le 18/03/2026 — Source : FND_CONCURRENT_REQUESTS / FND_CONCURRENT_PROGRAMS_VL — Référence mardi 10/03/2026*

