# 🌙 Rapport des Traitements de Nuit Oracle EBS - Dalkia

**Date du rapport** : 28 novembre 2025  
**Période analysée** : Novembre 2025  
**Base de données** : Oracle E-Business Suite 12.2.13  
**Plage horaire** : 00h00 - 06h59

---

## 📊 Vue d'ensemble

### Statistiques globales

| Indicateur | Valeur |
|------------|--------|
| **Nombre de types de traitements** | 76 programmes différents |
| **Total d'exécutions/mois** | ~25,000 traitements |
| **Taux de succès global** | 97.5% |
| **Plage horaire critique** | 03h13 - 05h18 |
| **Durée totale batch principal** | ~2h |

---

## 🎯 TOP 20 - Traitements les plus fréquents

| Rang | Programme | Nb exec./mois | Heure début | Durée moy. | Succès |
|------|-----------|---------------|-------------|------------|--------|
| 1 | Création fichier avis de virement | 14,499 | 03:30 | <1 min | 100% |
| 2 | Échéancier Fournisseur Provisoire | 1,438 | 03:10-05:43 | 2 min | 100% |
| 3 | Contrôle retraitements IFRS | 914 | 03:47-04:58 | <1 min | 100% |
| 4 | Création fichier avis de prélèvement | 861 | 04:51-01:13 | <1 min | 100% |
| 5 | Lanceur (SHELL) | 761 | 00:05-03:31 | 18 min | 96% |
| 6 | Clôture période FA | 658 | 01:10-02:08 | 6 min | 91% |
| 7 | VECTOR file generation | 457 | 04:39-04:52 | <1 min | 100% |
| 8 | VECTOR consolidation | 457 | 04:39-04:50 | <1 min | 100% |
| 9 | VECTOR balance | 457 | 04:39-04:52 | <1 min | 100% |
| 10 | Calcul TEC et PCA | 396 | 02:24-02:30 | <1 min | 100% |
| 11 | CCA sur sinistre | 396 | 02:24-02:30 | <1 min | 99% |
| 12 | France - Déclaration TVA déductible | 396 | 00:05-03:02 | 10 min | 99% |
| 13 | Comptabilisation Immobilisations | 330 | 02:25-02:36 | 1 min | 100% |
| 14 | Registre règlements non lettrés | 305 | 02:24-05:14 | 10 min | 100% |
| 15 | Etat déclaratif TVA dans GL | 305 | 04:39-04:40 | <1 min | 100% |
| 16 | TVA sur encaissement | 305 | 02:29-03:02 | 1 min | 100% |
| 17 | TVA Collectée : état préparatoire | 197 | 02:28-06:59 | 1 min | 100% |
| 18 | Génération CUT OFF | 167 | 01:51 | <1 min | 100% |
| 19 | Génération CUT OFF SSTR IVALUA | 167 | 02:09-02:28 | <1 min | 100% |
| 20 | Bordereau prélèvements clients | 153 | 03:52-01:09 | <1 min | 100% |

---

## 🕐 Chronologie détaillée d'une nuit type

### **Phase 1 : 00h00 - 01h00 - Extractions et exports**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 00:05 | France - Déclaration TVA déductible | 10 min | Préparation états fiscaux |
| 00:07 | Traitement validation factures CSP | 10 min | Validation factures CSP |
| 00:08 | Reporting mvts sans image | <1 min | Contrôle qualité |
| 00:11 | Annulation notifications obsolètes CSP | <1 min | Nettoyage |
| 00:15 | Extraction engagés vers Hercule | 22 min | Interface système décisionnel |
| 00:34 | Compression fichiers en zip | <1 min | Archivage |
| 00:37 | Export données Factures vers iValua | 24 min | Interface fournisseurs |
| 00:45 | Identification factures AP éligibles rapprochement | 15 min | Rapprochement bancaire |

### **Phase 2 : 01h00 - 02h00 - Génération et clôture FA**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 01:01 | Export images Factures vers iValua | 2 min | Interface fournisseurs |
| 01:04 | Création lots prélèvement auto | 31 min | Gestion trésorerie |
| 01:05 | Création règlements campagne prélèvement | 31 min | Paiements fournisseurs |
| 01:10 | **Clôture période FA** | **6 min** | **Immobilisations** |
| 01:13 | Compression fichiers zip | <1 min | Archivage |
| 01:21 | Génération pièces répétitives | <1 min | Comptabilité analytique |
| 01:36 | Création lots règlements prélèvement auto | 7 min | Trésorerie |
| 01:51 | **Génération CUT OFF** | **<1 min** | **Clôture** |
| 01:53 | Comptabilisation règlements prélèvement | 2 min | Validation paiements |
| 01:56 | Règlements automatiques factures fournisseurs | 57 min | Paiements AP |

### **Phase 3 : 02h00 - 03h00 - Calculs fiscaux et analytiques**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 02:05 | Imputation GL | 5 min | Comptabilité générale |
| 02:09 | Génération CUT OFF SSTR IVALUA | <1 min | Clôture iValua |
| 02:12 | Transfert écritures GL vers PA | 3 min | Comptabilité analytique |
| 02:16 | Campagne règlements - Alimentation AP Import | <1 min | Import paiements |
| 02:18 | Campagne règlements - Création fichier APIMPORT | <1 min | Import paiements |
| 02:19 | Calcul poids SATI et envoi mail | 1 min | Contrôle qualité |
| 02:21 | Automatisation envoi avis virement mail | 6 min | Communication fournisseurs |
| 02:22 | Rattachement avis virement règlement AP | 2 min | Traçabilité paiements |
| 02:24 | **Calcul TEC et PCA** | **<1 min** | **Provisions** |
| 02:24 | **CCA sur sinistre** | **<1 min** | **Provisions sinistres** |
| 02:24 | **Registre règlements non lettrés** | **10 min** | **Rapprochement** |
| 02:24 | Balance âgée client | 2 min | Suivi recouvrement |
| 02:25 | **Comptabilisation Immobilisations** | **1 min** | **FA** |
| 02:28 | TVA Collectée : état préparatoire | 1 min | Fiscalité |
| 02:29 | TVA sur encaissement | 1 min | Fiscalité |
| 02:48 | Sélection avoirs non soldés à rembourser | <1 min | Gestion avoirs |

### **Phase 4 : 03h00 - 04h00 - BATCH PRINCIPAL ⭐**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 03:01 | Automatisation factures prélèvement client | 1 min | Trésorerie |
| 03:01 | Mouvements éligibles prélèvement auto | 1 min | Trésorerie |
| 03:02 | Envoi états prélèvement automatique | <1 min | Communication |
| 03:06 | **Posting: Single Ledger** | **<1 min** | **Comptabilisation GL** |
| 03:06 | Edition factures refacturation | <1 min | Refacturation |
| 03:06 | Envoi email avec attachement | <1 min | Communication |
| 03:08 | **Transfert écritures GL vers PA** | **3 min** | **Analytique** |
| 03:10 | **Échéancier Fournisseur Provisoire** | **2 min** | **Trésorerie** |
| 03:13 | **🔴 SITUATION ORACLE DU MATIN** | **125 min** | **⭐ REPORTING PRINCIPAL** |
| 03:13 | **🔴 FICHIERS CONTRÔLE PRÉ-CLÔTURE** | **11 min** | **⭐ CONTRÔLES CLÔTURE** |
| 03:13 | Lanceur (SHELL) | 18 min | Orchestration |
| 03:13 | Export données Factures iValua | 21 min | Interface |
| 03:13 | Export images Factures iValua | 2 min | Interface |
| 03:13 | Extraction statut factures TradeShift | 13 min | Interface |
| 03:13 | Extraction contrôle de flux | 49 min | Contrôle |
| 03:13 | Extraction évènements AR | <1 min | Clients |
| 03:13 | Extraction coordonnées bancaires | <1 min | Référentiel |
| 03:13 | Interface GL vers HYPERION | 6 min | Consolidation |
| 03:13 | Interface GL vers HYPERION - Quantités | 1 min | Consolidation |
| 03:13 | Import mouvements comptables XXRB | 2 min | Comptabilité |
| 03:15 | Etat avoirs à rembourser | <1 min | Gestion avoirs |
| 03:16 | Alimentation référence ligne GL dans RB | <1 min | Rapprochement bancaire |
| 03:21 | **Envoi fichiers contrôle pré-clôture** | **<1 min** | **Communication** |
| 03:22 | Envoi fichiers contrôle pré-clôture | <1 min | Communication |
| 03:27 | Campagne règlements - Création APIMPORT | <1 min | Paiements |
| 03:28 | Calcul poids SATI | 1 min | Contrôle |
| 03:30 | **Création fichier avis de virement** | **<1 min** | **Paiements** |
| 03:33 | Envoi avis virement par mail | 2 min | Communication |
| 03:33 | Rattachement avis virement règlement | 2 min | Traçabilité |
| 03:42 | Envoi fichiers contrôle pré-clôture | <1 min | Communication |
| 03:46 | Interface GL vers HYPERION | 6 min | Consolidation |
| 03:47 | **Contrôle retraitements IFRS** | **<1 min** | **Normes IFRS** |
| 03:51 | Règlements auto prélèvements clients | 16 min | Trésorerie |
| 03:51 | Automate Etat avoirs à rembourser | <1 min | Gestion avoirs |
| 03:52 | Bordereau prélèvements clients | <1 min | Trésorerie |
| 03:58 | **Situation Oracle du matin** | **39 min** | **Reporting** |

### **Phase 5 : 04h00 - 05h00 - VECTOR et états finaux**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 04:39 | **VECTOR file generation** | **<1 min** | **Consolidation** |
| 04:39 | **VECTOR consolidation** | **<1 min** | **Consolidation** |
| 04:39 | **VECTOR balance** | **<1 min** | **Consolidation** |
| 04:39 | **Etat déclaratif TVA dans GL** | **<1 min** | **Fiscalité** |
| 04:39 | Edition factures refacturation | <1 min | Refacturation |
| 04:39 | Envoi email avec attachement | <1 min | Communication |
| 04:49 | Campagne prélèvements Clients - Création DDIMPORT | <1 min | Trésorerie |
| 04:51 | **Création fichier avis de prélèvement** | **<1 min** | **Clients** |
| 04:51 | Automatisation avis prélèvements clients | 9 min | Trésorerie |
| 04:58 | Contrôle retraitements IFRS | <1 min | Normes IFRS |

### **Phase 6 : 05h00 - 06h59 - Extournes et finalisation**

| Heure | Programme | Durée | Objectif |
|-------|-----------|-------|----------|
| 05:14 | **Extourne CCA sur sinistre** | **<1 min** | **Provisions** |
| 05:14 | Registre règlements non lettrés | 10 min | Rapprochement |
| 05:18 | **Finalisation Situation Oracle** | **Fin** | **Reporting final** |
| 05:18 | Envoi fichiers situation Oracle | <1 min | Communication |
| 05:19 | Rattachement avis prélèvement règlement AR | <1 min | Traçabilité |
| 05:25 | **Extourne TEC et PCA** | **2 min** | **Provisions** |
| 05:25 | Automatisation prélèvements remis en banque | 1 min | Trésorerie |
| 05:25 | Etat prélèvements remis en banque | <1 min | Trésorerie |
| 05:43 | Échéancier Fournisseur Provisoire | 2 min | Trésorerie |
| 05:49 | Alimentation référence ligne GL dans RB | <1 min | Rapprochement |
| 06:00-06:59 | OAM Applications Dashboard Collection | <1 min/10min | Monitoring |

---

## 🎯 Traitements critiques pour la clôture comptable

### 1. **Situation Oracle du matin** 🔴 CRITIQUE

**Programme** : `DKA : Situation Oracle du matin`

| Caractéristique | Détail |
|-----------------|--------|
| **Heure de lancement** | 03:13 |
| **Durée moyenne** | 125 minutes (2h05) |
| **Heure de fin** | ~05:18 |
| **Fréquence** | Quotidienne (88 exec./mois) |
| **Taux de succès** | 95% (84/88) |
| **Impact** | BLOQUANT - Tous les reportings dépendent de ce batch |

**Contenu** :
- Génération des situations comptables
- Consolidation des données GL, AP, AR, FA
- Préparation des fichiers de reporting
- Alimentation des tableaux de bord

**Actions en cas d'échec** :
1. Vérifier les logs dans `/concurrent/logs`
2. Relancer manuellement si échec avant 04:00
3. Alerter l'équipe comptable si échec après 05:00

---

### 2. **Fichiers de contrôle de pré-clôture** 🔴 CRITIQUE

**Programme** : `DKA : Edition des fichiers de contrôle de pre-cloture`

| Caractéristique | Détail |
|-----------------|--------|
| **Heure de lancement** | 03:13 |
| **Durée moyenne** | 11 minutes |
| **Fréquence** | Quotidienne (62 exec./mois) |
| **Taux de succès** | 100% |
| **Impact** | BLOQUANT pour clôture mensuelle |

**Modules contrôlés** :
- **AP** - Accounts Payable (Fournisseurs)
- **AR** - Accounts Receivable (Clients)
- **GL** - General Ledger (Grand Livre)
- **PA** - Projects Accounting (Analytique)
- **PO** - Purchasing (Achats)
- **FA** - Fixed Assets (Immobilisations)
- **SLA** - SubLedger Accounting
- **AMONTS** - Modules amonts
- **DIVERS** - Contrôles divers
- **REFAC** - Refacturation

**Fichiers générés** :
- Factures bloquées (holds)
- Factures non validées
- Réceptions non facturées
- Journaux non validés
- Interfaces en erreur
- Paiements non comptabilisés

**Emails envoyés automatiquement** à :
- Équipe comptable fournisseurs
- Équipe comptable clients
- Contrôle de gestion
- Direction financière

---

### 3. **Clôture période FA (Immobilisations)** 🟡 IMPORTANT

**Programme** : `DKA : Cloture de la periode FA`

| Caractéristique | Détail |
|-----------------|--------|
| **Heure de lancement** | 01:10 - 02:08 |
| **Durée moyenne** | 6 minutes |
| **Fréquence** | Mensuelle (658 exec./mois = par book) |
| **Taux de succès** | 91% (602/658) |
| **Impact** | BLOQUANT pour clôture FA |

**⚠️ Points d'attention** :
- 9% de taux d'échec (56 exécutions en erreur)
- Exécution massive : ~650 books différents
- Nécessite vérification manuelle des books en erreur

**Books traités** :
- TAX books (2xxx, 3xxx)
- CORPORATE books
- Tous les livres d'immobilisations

---

### 4. **Interfaces externes** 🟡 IMPORTANT

#### **iValua (Factures fournisseurs)**

| Programme | Durée | Fréquence | Impact |
|-----------|-------|-----------|--------|
| Export données Factures vers iValua | 24 min | 19/mois | Interface critique |
| Export images Factures vers iValua | 2 min | 19/mois | Documents justificatifs |
| Extraction statut factures TradeShift | 13 min | 18/mois | Suivi workflow |

#### **HYPERION (Consolidation)**

| Programme | Durée | Fréquence | Impact |
|-----------|-------|-----------|--------|
| Interface GL vers HYPERION | 6 min | 7/mois | Consolidation groupe |
| Interface GL vers HYPERION - Quantités | 1 min | 7/mois | Données quantitatives |

#### **Hercule (Décisionnel)**

| Programme | Durée | Fréquence | Impact |
|-----------|-------|-----------|--------|
| Extraction engagés vers Hercule | 22 min | 19/mois | Reporting décisionnel |

#### **Rapprochement Bancaire (RB)**

| Programme | Durée | Fréquence | Impact |
|-----------|-------|-----------|--------|
| Import mouvements comptables XXRB | 2 min | Quotidien | Rapprochement bancaire |
| Alimentation référence ligne GL dans RB | <1 min | 17/mois | Traçabilité |

---

## 💰 Traitements de gestion de trésorerie

### **Paiements fournisseurs (AP)**

| Programme | Durée | Fréquence | Objectif |
|-----------|-------|-----------|----------|
| Règlements automatiques factures fournisseurs | 57 min | 34/mois | Paiements automatiques |
| Création fichier avis de virement | <1 min | 14,499/mois | Communication fournisseurs |
| Automatisation envoi avis virement | 6 min | 38/mois | Envoi automatique |
| Rattachement avis virement | 2 min | 38/mois | Traçabilité |
| Création lots prélèvement auto | 7 min | 124/mois | Prélèvements SEPA |

### **Encaissements clients (AR)**

| Programme | Durée | Fréquence | Objectif |
|-----------|-------|-----------|----------|
| Règlements auto prélèvements clients | 16 min | 17/mois | Encaissements automatiques |
| Création fichier avis de prélèvement | <1 min | 861/mois | Communication clients |
| Automatisation avis prélèvements | 9 min | 17/mois | Envoi automatique |
| Automatisation prélèvements remis banque | 1 min | 136/mois | Remise en banque |
| Mouvements éligibles prélèvement auto | 1 min | 24/mois | Identification |

### **Contrôles et états**

| Programme | Durée | Fréquence | Objectif |
|-----------|-------|-----------|----------|
| Échéancier Fournisseur Provisoire | 2 min | 1,438/mois | Prévisionnel trésorerie |
| Registre règlements non lettrés | 10 min | 305/mois | Rapprochement |
| Bordereau prélèvements clients | <1 min | 153/mois | États bancaires |
| Etat prélèvements remis banque | <1 min | 136/mois | Suivi remises |

---

## 📊 Traitements fiscaux (TVA)

### **Déclarations et états TVA**

| Programme | Durée | Fréquence | Type |
|-----------|-------|-----------|------|
| France - Déclaration TVA déductible | 10 min | 396/mois | TVA déductible |
| Etat déclaratif TVA dans GL | <1 min | 305/mois | TVA collectée |
| TVA Collectée : état préparatoire | 1 min | 197/mois | Préparation CA3 |
| TVA sur encaissement | 1 min | 305/mois | TVA encaissée |

**Fréquence globale** : Quotidienne  
**Période de génération** : 02h00 - 05h00  
**Impact clôture** : CRITIQUE pour déclarations mensuelles

---

## 🏢 Traitements immobilisations (FA)

### **Opérations FA**

| Programme | Durée | Fréquence | Impact |
|-----------|-------|-----------|--------|
| **Clôture période FA** | 6 min | 658/mois | 🔴 CRITIQUE |
| **Comptabilisation FA** | 1 min | 330/mois | 🔴 CRITIQUE |
| Création comptabilisation FA | 1 min | 330/mois | Génération écritures |

**⚠️ Attention** : La clôture FA doit être terminée avant 02:30 pour permettre la comptabilisation.

---

## 📈 Traitements analytiques et provisions

### **Calculs de provisions**

| Programme | Durée | Objectif |
|-----------|-------|----------|
| **Calcul TEC et PCA** | <1 min | Charges à étaler / Produits constatés d'avance |
| **CCA sur sinistre** | <1 min | Charges constatées d'avance sinistres |
| **Extourne CCA sur sinistre** | <1 min | Annulation provisions antérieures |
| **Extourne TEC et PCA** | 2 min | Annulation provisions antérieures |

**Cycle** :
1. **02:24** : Calcul des provisions TEC/PCA/CCA
2. **05:14** : Extourne CCA sinistre
3. **05:25** : Extourne TEC et PCA

### **Comptabilité analytique (PA)**

| Programme | Durée | Objectif |
|-----------|-------|----------|
| Transfert écritures GL vers PA | 3 min | Alimentation PA |
| Génération pièces répétitives | <1 min | Écritures récurrentes |
| Imputation GL | 5 min | Affectation analytique |

---

## 🔄 Traitements de clôture spécifiques

### **CUT OFF (Clôture périodique)**

| Programme | Heure | Durée | Objectif |
|-----------|-------|-------|----------|
| Génération CUT OFF | 01:51 | <1 min | Césure comptable |
| Génération CUT OFF SSTR IVALUA | 02:09-02:28 | <1 min | Césure iValua |

**Utilité** : Permet de figer les écritures à une date précise pour la clôture mensuelle.

### **VECTOR (Consolidation groupe)**

| Programme | Heure | Durée | Objectif |
|-----------|-------|-------|----------|
| VECTOR file generation | 04:39-04:52 | <1 min | Génération fichiers |
| VECTOR consolidation | 04:39-04:50 | <1 min | Consolidation |
| VECTOR balance | 04:39-04:52 | <1 min | Balance consolidée |

**Fréquence** : 457 exécutions/mois  
**Impact** : Consolidation groupe mensuelle

### **Retraitements IFRS**

| Programme | Heure | Durée | Objectif |
|-----------|-------|-------|----------|
| Contrôle retraitements IFRS | 03:47-04:58 | <1 min | Normes IFRS |

**Fréquence** : 914 exécutions/mois (quotidienne)  
**Impact** : Reporting normes internationales

---

## ⚠️ Traitements avec taux d'erreur significatif

### **Analyse des échecs**

| Programme | Nb exec. | Nb erreurs | Taux erreur | Actions |
|-----------|----------|------------|-------------|---------|
| **Lanceur (SHELL)** | 761 | 33 | **4.3%** | 🔴 Surveiller logs SHELL |
| **Clôture FA** | 658 | 56 | **8.5%** | 🔴 Vérifier books en erreur |
| **Situation Oracle matin** | 88 | 4 | **4.5%** | 🟡 Analyser cause échecs |
| **Transfert GL vers PA** | 11 | 1 | **9.1%** | 🟡 Vérifier mappings |
| **France - Déclaration TVA** | 396 | 1 | **0.3%** | 🟢 Acceptable |
| **Envoi états prélèvement** | 72 | 1 | **1.4%** | 🟢 Acceptable |

### **🔍 Actions correctives recommandées**

#### **1. Lanceur SHELL (4.3% échec)**

**Problème** : 33 échecs sur 761 exécutions

**Investigations nécessaires** :
- Analyser les logs dans `/concurrent/logs`
- Vérifier les droits d'accès aux répertoires
- Contrôler l'espace disque disponible
- Vérifier les dépendances inter-programmes

**Impact** : Peut bloquer les traitements dépendants

---

#### **2. Clôture FA (8.5% échec)**

**Problème** : 56 échecs sur 658 books

**Causes possibles** :
- Books déjà fermés
- Période non ouverte
- Transactions en cours sur le book
- Problèmes de synchronisation

**Actions** :
1. Identifier les books en erreur :
```sql
SELECT book_type_code, period_name, closing_status
FROM fa_book_controls
WHERE period_name = 'NOV-25'
  AND closing_status = 'O'
ORDER BY book_type_code;
```

2. Relancer manuellement les clôtures en erreur
3. Vérifier qu'aucune transaction n'est en cours

---

#### **3. Situation Oracle (4.5% échec)**

**Problème** : 4 échecs sur 88 exécutions

**Impact** : CRITIQUE - Bloque les reportings du jour

**Actions immédiates** :
1. Alerter l'équipe si échec détecté
2. Relancer immédiatement
3. Vérifier les logs pour identifier la cause
4. Si échec répété, contacter le support technique

---

## 📧 Notifications et communications automatiques

### **Emails envoyés automatiquement**

| Heure | Programme | Destinataires | Contenu |
|-------|-----------|---------------|---------|
| 03:21-03:42 | Envoi fichiers contrôle pré-clôture | Équipes comptables | Fichiers de contrôle journaliers |
| 03:33 | Envoi avis virement par mail | Fournisseurs | Avis de paiement |
| 03:51 | Automate Etat avoirs à rembourser | Clients | Avoirs à rembourser |
| 04:06 | Envoi email avec attachement | Diverses équipes | États refacturation |
| 04:51 | Automatisation avis prélèvements | Clients | Avis de prélèvement |
| 05:18 | Envoi fichiers situation Oracle | Direction financière | Situation comptable |
| 05:25 | Etat prélèvements remis banque | Trésorerie | Remises bancaires |

**Total** : ~15,000 emails automatiques/mois

---

## 🔧 Programmes utilitaires et maintenance

### **Monitoring et contrôle**

| Programme | Fréquence | Objectif |
|-----------|-----------|----------|
| OAM Applications Dashboard Collection | Toutes les 10 min | Surveillance système |
| Reporting mvts sans image | Quotidien | Contrôle qualité |
| Annulation notifications obsolètes CSP | Quotidien | Nettoyage |
| Compression fichiers zip | Quotidien | Archivage |

### **Lanceurs et orchestration**

| Programme | Durée moy. | Nb exec. | Rôle |
|-----------|------------|----------|------|
| DKA : Lanceur (SHELL) | 18 min | 761/mois | Orchestration des batchs |
| Request Set Stage | 3 min | Variable | Gestion ensembles requêtes |

---

## 📋 Checklist de surveillance quotidienne

### **🌅 Contrôles du matin (avant 09h00)**

- [ ] **05:30** - Vérifier que la Situation Oracle est terminée
- [ ] **06:00** - Contrôler les emails de pré-clôture reçus
- [ ] **08:00** - Analyser les fichiers de contrôle (factures bloquées, etc.)
- [ ] **08:30** - Vérifier l'absence d'erreurs critiques dans les logs
- [ ] **09:00** - Valider la disponibilité des reportings

### **📊 Contrôles périodiques (hebdomadaire)**

- [ ] **Lundi** - Analyser les échecs des lanceurs SHELL
- [ ] **Mardi** - Vérifier les clôtures FA en erreur
- [ ] **Mercredi** - Contrôler les interfaces externes (iValua, HYPERION)
- [ ] **Jeudi** - Analyser les durées d'exécution (détection anomalies)
- [ ] **Vendredi** - Bilan hebdomadaire des erreurs

### **📅 Contrôles mensuels (avant clôture)**

- [ ] **J-5** - Vérifier que tous les batchs de nuit fonctionnent correctement
- [ ] **J-3** - Analyser les volumes de transactions dans les batchs
- [ ] **J-2** - Contrôler l'espace disque et les performances
- [ ] **J-1** - Valider que tous les fichiers de contrôle sont OK
- [ ] **Jour J** - Surveillance renforcée des batchs de clôture

---

## 🚨 Procédures d'alerte et d'escalade

### **Niveau 1 - INFO** 🟢

**Critères** :
- Échec ponctuel d'un programme non critique
- Durée d'exécution légèrement supérieure à la normale
- Avertissement sans impact métier

**Actions** :
- Documenter dans le journal
- Surveiller les prochaines exécutions

---

### **Niveau 2 - AVERTISSEMENT** 🟡

**Critères** :
- Échec d'un programme important (TVA, FA)
- 2 échecs consécutifs du même programme
- Durée d'exécution > 200% de la normale
- Lanceur SHELL en erreur

**Actions** :
1. Analyser les logs immédiatement
2. Relancer le programme si possible
3. Alerter l'équipe technique
4. Documenter l'incident

---

### **Niveau 3 - CRITIQUE** 🔴

**Critères** :
- Échec de la Situation Oracle du matin
- Échec des fichiers de contrôle pré-clôture
- Échec des interfaces externes critiques
- Blocage du batch de nuit complet

**Actions** :
1. **Alerte immédiate** : DBA + Équipe technique + Direction financière
2. **Diagnostic urgent** : Analyse des logs et de l'état système
3. **Relance manuelle** : Tentative de relance des programmes critiques
4. **Communication** : Informer toutes les parties prenantes
5. **Plan de secours** : Activation procédures de reprise
6. **Suivi** : Reporting horaire jusqu'à résolution

---

### **Niveau 4 - CATASTROPHIQUE** 🔴🔴

**Critères** :
- Impossibilité de clôturer le mois
- Perte de données
- Corruption de la base
- Indisponibilité système prolongée (>4h)

**Actions** :
1. **Cellule de crise** : Réunion immédiate toutes parties prenantes
2. **Support Oracle** : Ouverture SR en priorité 1
3. **Communication officielle** : Direction générale informée
4. **Plan de continuité** : Activation PCA/PRA
5. **Reporting exécutif** : Reporting chaque heure
6. **Post-mortem** : Analyse approfondie après résolution

---

## 📞 Contacts et responsabilités

### **Équipe technique**

| Rôle | Contact | Horaires | Responsabilités |
|------|---------|----------|-----------------|
| **DBA Oracle** | dba@dalkia.fr | 24/7 | Base de données, performance |
| **Admin EBS** | ebs-admin@dalkia.fr | 7h-19h | Applications EBS, batchs |
| **Support N2** | support-n2@dalkia.fr | 7h-21h | Incidents niveau 2 |
| **Astreinte technique** | +33 X XX XX XX XX | 24/7 | Urgences hors horaires |

### **Équipe comptable**

| Rôle | Contact | Horaires | Responsabilités |
|------|---------|----------|-----------------|
| **Responsable compta fournisseurs** | ap-manager@dalkia.fr | 8h-18h | Validation AP, paiements |
| **Responsable compta clients** | ar-manager@dalkia.fr | 8h-18h | Validation AR, encaissements |
| **RAF (Resp. Admin. Financier)** | raf@dalkia.fr | 8h-19h | Validation clôture, reporting |
| **Contrôle de gestion** | controleur@dalkia.fr | 8h-18h | Analytique, consolidation |
| **DAF (Directeur Administratif Financier)** | daf@dalkia.fr | 9h-18h | Décisions stratégiques |

---

## 🔍 Requêtes SQL utiles pour la surveillance

### **1. Suivi des batchs de nuit en cours**

```sql
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    fcp.user_concurrent_program_name as programme,
    fcr.phase_code,
    fcr.status_code,
    ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 2) as duree_min_en_cours
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.phase_code = 'R' -- Running
  AND TO_NUMBER(TO_CHAR(fcr.actual_start_date, 'HH24')) BETWEEN 0 AND 6
ORDER BY fcr.actual_start_date DESC;
```

---

### **2. Échecs des dernières 24 heures**

```sql
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as heure_debut,
    fcp.user_concurrent_program_name as programme,
    fcr.status_code,
    fcr.completion_text as message_erreur
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.actual_start_date >= SYSDATE - 1
  AND fcr.status_code IN ('E', 'X') -- Error / Terminated
  AND fcp.user_concurrent_program_name LIKE 'DKA%'
ORDER BY fcr.actual_start_date DESC;
```

---

### **3. Durées d'exécution anormalement longues**

```sql
SELECT 
    fcp.user_concurrent_program_name as programme,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_minutes,
    fcr.status_code
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.actual_start_date >= SYSDATE - 1
  AND (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 30 -- Plus de 30 min
  AND fcp.user_concurrent_program_name LIKE 'DKA%'
ORDER BY duree_minutes DESC;
```

---

### **4. Statut de la Situation Oracle**

```sql
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as heure_debut,
    TO_CHAR(fcr.actual_completion_date, 'HH24:MI:SS') as heure_fin,
    fcr.phase_code,
    fcr.status_code,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_minutes
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.user_concurrent_program_name = 'DKA : Situation Oracle du matin'
  AND fcr.actual_start_date >= TRUNC(SYSDATE)
ORDER BY fcr.actual_start_date DESC;
```

---

### **5. Historique des clôtures FA**

```sql
SELECT 
    fcr.argument_text as parametres,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    fcr.status_code,
    fcr.completion_text
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.user_concurrent_program_name = 'DKA : Cloture de la periode FA'
  AND fcr.actual_start_date >= TRUNC(SYSDATE)
  AND fcr.status_code != 'C' -- Uniquement les échecs
ORDER BY fcr.actual_start_date DESC;
```

---

## 📈 Métriques et KPIs de surveillance

### **Indicateurs de performance**

| KPI | Cible | Alerte si |
|-----|-------|-----------|
| **Taux de succès global** | > 95% | < 90% |
| **Situation Oracle terminée avant** | 05:30 | > 06:00 |
| **Fichiers contrôle envoyés avant** | 04:00 | > 04:30 |
| **Nombre d'échecs quotidiens** | < 5 | > 10 |
| **Temps total batch nuit** | < 3h | > 4h |
| **Clôtures FA en erreur** | < 5% | > 10% |
| **Lanceurs SHELL OK** | > 95% | < 90% |

### **Tableau de bord quotidien**

```
Date : 28/11/2025

┌─────────────────────────────────────────────────────────┐
│           TRAITEMENTS DE NUIT - TABLEAU DE BORD         │
├─────────────────────────────────────────────────────────┤
│ Situation Oracle : ✅ OK (terminé à 05:18)              │
│ Fichiers contrôle : ✅ OK (envoyés à 03:42)             │
│ Clôture FA        : ⚠️  ATTENTION (8% échec)            │
│ Lanceurs SHELL    : ⚠️  ATTENTION (4% échec)            │
│ Interfaces        : ✅ OK (iValua, HYPERION, Hercule)   │
│ TVA               : ✅ OK (tous états générés)          │
│ Trésorerie        : ✅ OK (paiements, prélèvements)     │
├─────────────────────────────────────────────────────────┤
│ Statut global     : 🟡 ACCEPTABLE (surveillance requise)│
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Recommandations et axes d'amélioration

### **1. Réduction du taux d'erreur**

**Objectif** : Passer de 97.5% à 99% de taux de succès

**Actions** :
- Analyser systématiquement les 33 échecs SHELL
- Identifier et corriger les 56 clôtures FA en erreur
- Mettre en place des contrôles préventifs
- Automatiser les relances en cas d'échec

---

### **2. Optimisation des performances**

**Objectif** : Réduire la durée du batch principal de 2h à 1h30

**Actions** :
- Paralléliser davantage les traitements indépendants
- Optimiser les requêtes de la Situation Oracle
- Indexer les tables critiques
- Archiver les données anciennes

---

### **3. Amélioration de la supervision**

**Objectif** : Détecter et réagir plus rapidement aux incidents

**Actions** :
- Mettre en place des alertes SMS/Email en temps réel
- Créer un dashboard de monitoring en temps réel
- Automatiser les contrôles post-batch
- Implémenter des scripts de relance automatique

---

### **4. Documentation et formation**

**Objectif** : Améliorer la réactivité de l'équipe

**Actions** :
- Former l'équipe comptable aux contrôles de base
- Créer des procédures opérationnelles détaillées
- Mettre à jour la documentation technique
- Organiser des formations trimestrielles

---

## 📅 Calendrier de maintenance

### **Maintenance préventive hebdomadaire**

| Jour | Action | Durée | Équipe |
|------|--------|-------|--------|
| **Lundi** | Analyse des logs de la semaine précédente | 1h | DBA |
| **Mercredi** | Vérification espace disque et purge | 30min | Admin système |
| **Vendredi** | Optimisation des statistiques Oracle | 1h | DBA |

### **Maintenance mensuelle (hors clôture)**

| Tâche | Durée | Équipe | Planning |
|-------|-------|--------|----------|
| Archivage des logs > 3 mois | 2h | DBA | 1er du mois |
| Mise à jour des statistiques tables | 4h | DBA | 5 du mois |
| Contrôle intégrité base | 2h | DBA | 10 du mois |
| Test de restauration backup | 4h | DBA | 15 du mois |
| Revue des performances | 2h | DBA + Admin | 20 du mois |

### **Maintenance annuelle**

| Tâche | Période | Durée |
|-------|---------|-------|
| Montée de version EBS | Été | 1 semaine |
| Patch Oracle Database | Été | 2 jours |
| Audit de sécurité | Septembre | 1 semaine |
| Revue architecture | Octobre | 1 semaine |

---

## 🎓 Annexes

### **Annexe A - Codes de statut des programmes**

| Code Phase | Signification |
|------------|---------------|
| P | Pending (En attente) |
| R | Running (En cours d'exécution) |
| C | Completed (Terminé) |
| I | Inactive (Inactif) |

| Code Status | Signification |
|-------------|---------------|
| C | Completed successfully (Succès) |
| E | Error (Erreur) |
| W | Warning (Avertissement) |
| X | Terminated (Annulé) |
| G | Warning (Avertissement - variante) |

---

### **Annexe B - Glossaire**

| Terme | Définition |
|-------|------------|
| **AP** | Accounts Payable - Comptabilité fournisseurs |
| **AR** | Accounts Receivable - Comptabilité clients |
| **GL** | General Ledger - Grand livre |
| **FA** | Fixed Assets - Immobilisations |
| **PA** | Projects Accounting - Comptabilité analytique |
| **PO** | Purchasing - Achats |
| **SLA** | SubLedger Accounting - Comptabilité auxiliaire |
| **TEC** | Transfert en cours / Charges à étaler |
| **PCA** | Produits constatés d'avance |
| **CCA** | Charges constatées d'avance |
| **CUT OFF** | Césure comptable de fin de période |
| **VECTOR** | Outil de consolidation groupe |
| **HYPERION** | Outil de consolidation et reporting Oracle |
| **iValua** | Plateforme de gestion fournisseurs |
| **Hercule** | Système décisionnel Dalkia |
| **IFRS** | International Financial Reporting Standards |
| **Book** | Livre d'immobilisations (corporate, tax, etc.) |

---

### **Annexe C - Chemins et répertoires**

| Type | Chemin | Usage |
|------|--------|-------|
| **Logs concurrents** | `/concurrent/logs` | Logs des programmes |
| **Output concurrents** | `/concurrent/output` | Fichiers de sortie |
| **Scripts SHELL** | `/apps/scripts/dkia` | Scripts personnalisés |
| **Exports iValua** | `/interfaces/ivalua/export` | Fichiers export |
| **Imports iValua** | `/interfaces/ivalua/import` | Fichiers import |
| **HYPERION** | `/interfaces/hyperion` | Interface consolidation |
| **Hercule** | `/interfaces/hercule` | Interface décisionnel |
| **Archives** | `/archives/batch` | Archives des traitements |

---

### **Annexe D - Liens utiles**

| Ressource | URL | Description |
|-----------|-----|-------------|
| **Oracle EBS** | http://ebs-prod.dalkia.fr:8000 | Application EBS |
| **Monitoring** | http://monitoring.dalkia.fr | Dashboard monitoring |
| **Documentation** | http://docs-ebs.dalkia.fr | Documentation technique |
| **Support interne** | support@dalkia.fr | Demandes support |
| **My Oracle Support** | https://support.oracle.com | Support Oracle |

---

## 📄 Historique des modifications

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | 28/11/2025 | System | Création initiale du rapport |

---

**Fin du rapport**

*Document généré automatiquement le 28 novembre 2025*  
*Source : Base de données Oracle EBS - oracleProd*  
*Période analysée : Novembre 2025*
