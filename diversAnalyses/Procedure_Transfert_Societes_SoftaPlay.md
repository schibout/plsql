# Procédure Complète de Transfert de Sociétés entre Operating Units

**Date de création** : 28 janvier 2026  
**Document de référence** : Création et transfert de SVD_V2.1_27-NOV-2025.docx  
**Version** : 2.1  
**Contexte** : Oracle E-Business Suite 12.2.13 - SoftaPlay 2.1.027  

---

## 1. VUE D'ENSEMBLE

### 1.1 Définition
Un **transfert de société** consiste à migrer une entité juridique d'une Operating Unit (OU) source vers une Operating Unit (OU) de destination dans Oracle EBS, en conservant l'historique et les données transactionnelles.

### 1.2 Types de Transferts
- **Transfert FULL** : Société avec activité complète (tous modules EBS)
- **Transfert SVD** : Société à Volume Dérisoire (paramétrage allégé)
- **Transfert LIGHT** : Synonyme de SVD

### 1.3 Exemples Récents de Transferts

| Date | Code Ancien | Nouvelle Société | Code | OU Source | OU Destination | Type |
|------|-------------|------------------|------|-----------|----------------|------|
| 01/2025 | DK 23 | MOTTEO | 0507 | DOS | DEW | - |
| 02/2025 | SVD 102 | MIRECOURT CHALEUR URBAINE | 0402 | DOS | DCW | SVD |
| 02/2025 | DK 42 | CALORIA | 0531 | DOS | DRW | FULL |
| 02/2025 | DK 43 | RCCHOSPITALIER ANGOULEME | 0532 | DOS | DNA | - |
| 04/2025 | DK 33 | SRCM | 0520 | DOS | DEW | FULL |
| 05/2025 | SVD 115 | ESTER | 0444 | DOS | DLS | SVD |
| 06/2025 | DK 52 | - | - | - | - | - |
| 06/2025 | SVD 101 | - | - | - | DRW | SVD |

---

## 2. PRÉ-REQUIS

### 2.1 Informations Nécessaires

#### A. Société à Transférer
- ✅ Code ancien (ex: DK 23, SVD 102)
- ✅ Raison sociale actuelle
- ✅ SIRET / Code APE
- ✅ Operating Unit actuelle (source)
- ✅ Type de société (FULL / SVD)

#### B. Destination
- ✅ Operating Unit de destination (ex: DEW, DCW, DRW)
- ✅ Nouveau code société (4 chiffres, ex: 0507)
- ✅ Nouvelle raison sociale (si changement)
- ✅ Environnement cible (PROD / ETI)

#### C. Validation Métier
- ✅ Approbation de la direction
- ✅ Date de transfert souhaitée
- ✅ Impact sur les contrats clients/fournisseurs
- ✅ Validation comptable et fiscale

### 2.2 Accès et Droits
- ✅ Accès administrateur Oracle EBS
- ✅ Accès SoftaPlay avec droits de déploiement
- ✅ Accès à l'environnement de destination
- ✅ Droits SQL sur les tables de paramétrage

### 2.3 Documentation de Référence
- ✅ `Création et transfert de SVD_V2.1_27-NOV-2025.docx` (dernière version)
- ✅ `DKA_CODE_APE.xlsx` (codes activité)
- ✅ `Setup SoftaPlay Projects.xlsx` (registre des projets)

---

## 3. ÉTAPES DU PROCESSUS DE TRANSFERT

### Phase 1 : PRÉPARATION (J-15 à J-5)

#### Étape 1.1 : Analyse de l'Existant
**Durée** : 1-2 jours  
**Responsable** : Analyste Fonctionnel

**Actions** :
1. **Identifier la société source**
   ```sql
   -- Requête de vérification société
   SELECT hou.organization_id,
          hou.name,
          hou.short_code,
          hou.set_of_books_id,
          hou.legal_entity_id
   FROM hr_operating_units hou
   WHERE hou.short_code = 'DK23'  -- Ancien code
      OR hou.name LIKE '%MOTTEO%';
   ```

2. **Extraire les données de paramétrage**
   - Paramètres comptables (GL)
   - Paramètres fournisseurs (AP)
   - Paramètres achats (PO)
   - Paramètres clients (AR)
   - Paramètres taxes (ZX)

3. **Vérifier les transactions en cours**
   ```sql
   -- Factures fournisseurs non validées
   SELECT COUNT(*), SUM(invoice_amount)
   FROM ap_invoices_all
   WHERE org_id = [org_id_source]
     AND invoice_type_lookup_code != 'PREPAYMENT'
     AND validation_request_id IS NULL;
   
   -- Commandes d'achat ouvertes
   SELECT COUNT(*), SUM(line_quantity * unit_price)
   FROM po_headers_all ph,
        po_lines_all pl
   WHERE ph.po_header_id = pl.po_header_id
     AND ph.org_id = [org_id_source]
     AND ph.closed_code = 'OPEN';
   ```

4. **Documenter les spécificités**
   - Fournisseurs actifs
   - Clients actifs
   - Sites de livraison
   - Comptes bancaires
   - Séquences de numérotation

**Livrables** :
- ✅ Fiche d'analyse de l'existant
- ✅ Liste des données à migrer
- ✅ Identification des risques

---

#### Étape 1.2 : Préparation des Fichiers de Paramétrage
**Durée** : 2-3 jours  
**Responsable** : Administrateur EBS

**Actions** :

1. **Créer le fichier INITSOC de transfert**
   - Nomenclature : `INITSOC_[TYPE] - [ANCIEN] devient [NOUVEAU] - [OU_DEST] - [CODE] - V01 [MM AAAA].xlsx`
   - Exemple : `INITSOC_FULL - DK 33 devient SRCM - DEW - 0520 - V04 2025.xlsx`

2. **Remplir les onglets du fichier INITSOC**
   
   **Onglet 1 : Informations Générales**
   - Ancien code société
   - Nouveau code société (4 chiffres)
   - Raison sociale
   - SIRET / SIREN
   - Code APE (référence `DKA_CODE_APE.xlsx`)
   - Adresse du siège social
   
   **Onglet 2 : Paramètres Comptables**
   - Ledger (Set of Books)
   - Période comptable de démarrage
   - Plan comptable
   - Calendriers comptables
   - Devises
   
   **Onglet 3 : Organisation**
   - Operating Unit de destination
   - Legal Entity associée
   - Liens inter-organisations
   
   **Onglet 4 : Paramètres Opérationnels**
   - Profils utilisateurs
   - Responsabilités
   - Séquences de documents
   - Numérotation automatique

3. **Créer le fichier de suivi mensuel**
   - Nomenclature : `20 - Créations [AAAA MM]_[ENV]_Trans.xlsx`
   - Exemple : `20 - Créations 2025 01_ETI_Trans.xlsx`
   - Contenu : Liste des transferts du mois avec statuts

4. **Créer le fichier Deployment**
   - Nomenclature : `20 - Deployment_ [AAAA MM]_[ENV]_Trans.xls`
   - Exemple : `20 - Deployment_ 2025 01_ETI_Trans.xls`
   - Configuration d'exécution SoftaPlay

5. **Créer la fiche de création partenaires (optionnel)**
   - Nomenclature : `Fiche de création Partenaires Kador [ANCIEN] devient [NOUVEAU] - [CODE] - [MM AAAA].xlsx`
   - Exemple : `Fiche de création Partenaires Kador DK 23 devient MOTTEO - 0507 - 01 2025.xlsx`
   - Informations pour partenaires externes (iValua, etc.)

**Livrables** :
- ✅ Fichier INITSOC complet et validé
- ✅ Fichier de suivi mensuel
- ✅ Fichier Deployment
- ✅ Fiche partenaires (si applicable)

---

#### Étape 1.3 : Validation des Fichiers
**Durée** : 1 jour  
**Responsable** : Chef de Projet + Comptabilité

**Actions** :
1. **Contrôle de cohérence**
   - Vérifier la cohérence des codes (ancien vs nouveau)
   - Valider le code APE avec la liste de référence
   - Vérifier l'unicité du nouveau code société
   
   ```sql
   -- Vérification unicité code
   SELECT organization_id, name, short_code
   FROM hr_operating_units
   WHERE short_code = '0520';  -- Nouveau code
   ```

2. **Validation métier**
   - Approbation de la raison sociale
   - Validation des paramètres comptables
   - Accord de la direction financière

3. **Validation technique**
   - Structure du fichier INITSOC conforme
   - Fichier Deployment correctement rempli
   - Nomenclature respectée

**Livrables** :
- ✅ Fichiers validés et signés
- ✅ Ordre de transfert approuvé

---

### Phase 2 : EXÉCUTION EN ENVIRONNEMENT DE TEST (J-5 à J-3)

#### Étape 2.1 : Déploiement en ETI
**Durée** : 2-4 heures  
**Responsable** : Administrateur EBS  
**Environnement** : ETI / ETI1 / ETI2

**Actions** :
1. **Préparation de l'environnement**
   - Vérifier disponibilité environnement ETI
   - Sauvegarder l'état actuel (snapshot)
   - Vérifier les logs d'erreurs

2. **Lancer SoftaPlay**
   - Ouvrir SoftaPlay 2.1.027
   - Se connecter à l'environnement ETI
   - Charger le fichier Deployment

3. **Exécuter le transfert**
   - Sélectionner le mode "Transfert"
   - Charger le fichier INITSOC
   - Valider les paramètres de configuration
   - Lancer l'exécution
   - **Durée estimée** : 30-60 minutes

4. **Surveiller l'exécution**
   - Suivre les logs en temps réel
   - Noter les warnings/erreurs
   - Vérifier la progression des étapes :
     * Création de la nouvelle OU
     * Transfert des paramètres
     * Migration des données
     * Mise à jour des liens
     * Validation finale

**Livrables** :
- ✅ Logs d'exécution SoftaPlay
- ✅ Capture d'écran du résultat
- ✅ Rapport d'anomalies (si erreurs)

---

#### Étape 2.2 : Tests Fonctionnels en ETI
**Durée** : 1-2 jours  
**Responsable** : Équipe Fonctionnelle

**Tests à réaliser** :

1. **Vérification de la nouvelle OU**
   ```sql
   -- Vérifier création OU
   SELECT organization_id,
          name,
          short_code,
          set_of_books_id,
          legal_entity_id,
          date_from
   FROM hr_operating_units
   WHERE short_code = '0520';
   ```

2. **Vérification des paramètres comptables**
   - Ledger correctement associé
   - Périodes comptables ouvertes
   - Plan comptable actif
   - Séquences de documents initialisées

3. **Vérification des données migrées**
   ```sql
   -- Vérifier sites fournisseurs
   SELECT COUNT(*)
   FROM ap_supplier_sites_all
   WHERE org_id = [new_org_id];
   
   -- Vérifier comptes bancaires
   SELECT COUNT(*)
   FROM ce_bank_accounts
   WHERE account_owner_org_id = [new_org_id];
   ```

4. **Tests transactionnels**
   - ✅ Créer une facture fournisseur test
   - ✅ Créer une commande d'achat test
   - ✅ Générer une écriture comptable
   - ✅ Vérifier la numérotation automatique
   - ✅ Tester les workflows d'approbation

5. **Vérification des profils taxes**
   ```sql
   -- CRITIQUE : Vérifier le flag taxe (KDFI-187)
   SELECT party_id,
          party_type_code,
          use_le_as_subscriber_flag
   FROM zx_party_tax_profile
   WHERE party_type_code = 'OU'
     AND party_id = [new_org_id];
   
   -- Si NULL, appliquer la correction
   UPDATE zx_party_tax_profile
   SET use_le_as_subscriber_flag = 'Y'
   WHERE party_type_code = 'OU'
     AND party_id = [new_org_id]
     AND use_le_as_subscriber_flag IS NULL;
   COMMIT;
   ```

**Livrables** :
- ✅ Rapport de tests fonctionnels
- ✅ Liste des anomalies détectées
- ✅ Validation fonctionnelle (GO/NOGO)

---

#### Étape 2.3 : Corrections et Ajustements
**Durée** : Variable (si anomalies)  
**Responsable** : Équipe Technique

**Actions** :
1. **Analyser les anomalies**
   - Classer par criticité
   - Identifier la cause racine
   - Proposer les corrections

2. **Appliquer les correctifs**
   - Correctifs SQL directs (si mineurs)
   - Modification fichier INITSOC (si majeurs)
   - Incrémenter la version (V01 → V02)

3. **Re-tester**
   - Réitérer les tests fonctionnels
   - Valider la correction

**Livrables** :
- ✅ Fichier INITSOC corrigé (VXX)
- ✅ Scripts SQL de correction
- ✅ Validation technique finale

---

### Phase 3 : DÉPLOIEMENT EN PRODUCTION (J-1 à J)

#### Étape 3.1 : Préparation du Déploiement PROD
**Durée** : J-1 (4-6 heures avant)  
**Responsable** : Chef de Projet

**Actions** :
1. **Réunion de coordination**
   - Valider le créneau de déploiement
   - Définir la fenêtre de maintenance (si nécessaire)
   - Briefing équipe technique

2. **Checklist pré-déploiement**
   - ✅ Fichiers ETI validés et testés
   - ✅ Créer les fichiers PROD à partir des fichiers ETI
   - ✅ Mettre à jour le suffixe `_ETI` → `_PROD`
   - ✅ Sauvegarder la base de production
   - ✅ Notifier les utilisateurs (arrêt temporaire si nécessaire)
   - ✅ Plan de rollback prêt

3. **Préparation fichiers PROD**
   - Dupliquer le fichier Deployment ETI validé
   - Renommer : `20 - Deployment_ 2025 01_PROD_Trans.xls`
   - Ajuster les paramètres environnement (connexion PROD)

**Livrables** :
- ✅ Fichiers PROD prêts
- ✅ Sauvegardes effectuées
- ✅ Équipe mobilisée

---

#### Étape 3.2 : Exécution en Production
**Durée** : J (2-4 heures)  
**Responsable** : Administrateur EBS Senior  
**Environnement** : PRODUCTION

**Actions** :

1. **Connexion à l'environnement PROD**
   - Ouvrir SoftaPlay
   - Se connecter avec les credentials PROD
   - **DOUBLE VÉRIFICATION** de l'environnement

2. **Chargement et validation**
   - Charger le fichier Deployment PROD
   - Charger le fichier INITSOC validé en ETI
   - **VÉRIFIER** : environnement = PROD
   - **VÉRIFIER** : fichier = version finale testée

3. **Exécution du transfert**
   - Lancer le processus
   - Surveillance continue
   - Log en temps réel
   - **Durée estimée** : 30-90 minutes (selon volumétrie)

4. **Surveillance post-exécution**
   - Vérifier le statut final : SUCCESS
   - Pas d'erreurs critiques
   - Tous les objets créés

**Livrables** :
- ✅ Logs d'exécution PROD
- ✅ Capture d'écran SUCCESS
- ✅ Horodatage de début/fin

---

#### Étape 3.3 : Validations Post-Déploiement PROD
**Durée** : J (1-2 heures après)  
**Responsable** : Équipe Fonctionnelle + DBA

**Validations immédiates** :

1. **Vérification technique**
   ```sql
   -- 1. OU créée
   SELECT organization_id, name, short_code
   FROM hr_operating_units
   WHERE short_code = '0520';
   
   -- 2. Legal Entity liée
   SELECT hoi.organization_id,
          hoi.org_information1 as legal_entity_id,
          xle.name as legal_entity_name
   FROM hr_organization_information hoi,
        xle_entity_profiles xle
   WHERE hoi.organization_id = [new_org_id]
     AND hoi.org_information_context = 'Operating Unit Information'
     AND hoi.org_information1 = xle.legal_entity_id;
   
   -- 3. Ledger associé
   SELECT gsob.ledger_id,
          gsob.name,
          gsob.currency_code
   FROM gl_sets_of_books gsob,
        hr_operating_units hou
   WHERE hou.organization_id = [new_org_id]
     AND hou.set_of_books_id = gsob.ledger_id;
   
   -- 4. Périodes comptables
   SELECT period_name, 
          period_year, 
          period_num,
          closing_status
   FROM gl_period_statuses
   WHERE application_id = 101
     AND ledger_id = [ledger_id]
     AND closing_status = 'O'
   ORDER BY period_year DESC, period_num DESC;
   ```

2. **Vérification flag taxe (CRITIQUE)**
   ```sql
   -- KDFI-187 : Vérifier et corriger si nécessaire
   SELECT party_id,
          use_le_as_subscriber_flag
   FROM zx_party_tax_profile
   WHERE party_type_code = 'OU'
     AND party_id = [new_org_id];
   
   -- Si NULL ou 'N', corriger immédiatement
   UPDATE zx_party_tax_profile
   SET use_le_as_subscriber_flag = 'Y'
   WHERE party_type_code = 'OU'
     AND party_id = [new_org_id]
     AND (use_le_as_subscriber_flag IS NULL 
          OR use_le_as_subscriber_flag = 'N');
   COMMIT;
   ```

3. **Vérification des paramètres opérationnels**
   ```sql
   -- Sites fournisseurs actifs
   SELECT aps.vendor_site_code,
          aps.org_id,
          aps.inactive_date
   FROM ap_supplier_sites_all aps
   WHERE aps.org_id = [new_org_id]
     AND aps.inactive_date IS NULL;
   
   -- Séquences de documents
   SELECT fds.doc_sequence_name,
          fds.db_sequence_name,
          fdsv.current_sequence
   FROM fnd_document_sequences fds,
        fnd_doc_sequence_assignments fdsa,
        fnd_document_sequences_v fdsv
   WHERE fdsa.doc_sequence_id = fds.doc_sequence_id
     AND fdsv.doc_sequence_id = fds.doc_sequence_id
     AND fdsa.org_id = [new_org_id];
   ```

4. **Test transactionnel en production**
   - ✅ Créer une facture fournisseur fictive
   - ✅ Valider la facture
   - ✅ Vérifier la génération du numéro
   - ✅ Annuler la facture test
   - ✅ Créer une commande test (optionnel)

**Livrables** :
- ✅ Rapport de validation technique
- ✅ Scripts de vérification exécutés
- ✅ Statut : GO / NOGO

---

### Phase 4 : FINALISATION ET SUIVI (J+1 à J+5)

#### Étape 4.1 : Corrections Post-Production (si nécessaire)
**Durée** : J+1  
**Responsable** : Équipe Technique

**Actions** :
1. **Appliquer les correctifs obligatoires**
   - Flag taxe (si oublié)
   - Ajustements de profils utilisateurs
   - Corrections de séquences

2. **Compléter les paramétrages manuels**
   - Création de responsabilités spécifiques
   - Affectation des utilisateurs
   - Configuration des impressions

**Livrables** :
- ✅ Scripts de correctifs exécutés
- ✅ Documentation des ajustements

---

#### Étape 4.2 : Communication et Formation
**Durée** : J+1 à J+3  
**Responsable** : Chef de Projet

**Actions** :
1. **Communication interne**
   - Email aux utilisateurs concernés
   - Nouveau code société : 0520
   - Nouvelle Operating Unit : DEW
   - Date effective du changement

2. **Formation utilisateurs**
   - Briefing sur les changements
   - Nouvelle navigation dans EBS
   - Points d'attention spécifiques

3. **Documentation mise à jour**
   - Mettre à jour `Setup SoftaPlay Projects.xlsx`
   - Mettre à jour `Paramétrages POST SOFTAPLAY de sociétés_MAI 2024.xlsx`
   - Archiver les fichiers du projet

**Livrables** :
- ✅ Email de communication envoyé
- ✅ Documentation mise à jour
- ✅ Registres actualisés

---

#### Étape 4.3 : Surveillance Post-Transfert
**Durée** : J+1 à J+5  
**Responsable** : Support Applicatif

**Actions** :
1. **Monitoring quotidien**
   - Vérifier les transactions créées
   - Suivre les éventuelles erreurs
   - Répondre aux questions utilisateurs

2. **Métriques de suivi**
   ```sql
   -- Factures créées post-transfert
   SELECT COUNT(*), SUM(invoice_amount)
   FROM ap_invoices_all
   WHERE org_id = [new_org_id]
     AND creation_date >= TRUNC(SYSDATE);
   
   -- Commandes créées
   SELECT COUNT(*)
   FROM po_headers_all
   WHERE org_id = [new_org_id]
     AND creation_date >= TRUNC(SYSDATE);
   ```

3. **Support réactif**
   - Point quotidien avec les utilisateurs
   - Résolution rapide des incidents
   - Documentation des problèmes

**Livrables** :
- ✅ Rapport de suivi quotidien (J+1 à J+5)
- ✅ Base de connaissances enrichie

---

#### Étape 4.4 : Clôture du Projet
**Durée** : J+5  
**Responsable** : Chef de Projet

**Actions** :
1. **Réunion de clôture**
   - Bilan du transfert
   - Retour d'expérience (REX)
   - Points d'amélioration pour les prochains transferts

2. **Archivage**
   - Sauvegarder tous les fichiers dans le dossier mensuel
   - Structure : `Paramétrage SoftaPlay/YYYYMM/Transfert [X] sociétés/`
   - Nomenclature respectée

3. **Documentation finale**
   - Rapport de clôture projet
   - Leçons apprises
   - Mise à jour des procédures (si évolutions)

**Livrables** :
- ✅ Rapport de clôture
- ✅ Fichiers archivés
- ✅ REX documenté

---

## 4. CHECKLIST COMPLÈTE DU TRANSFERT

### ☐ PHASE 1 : PRÉPARATION
- [ ] Analyse de la société source effectuée
- [ ] Informations de destination collectées
- [ ] Fichier INITSOC créé et rempli
- [ ] Fichier de suivi mensuel créé
- [ ] Fichier Deployment créé
- [ ] Fiche partenaires créée (si applicable)
- [ ] Validation métier obtenue
- [ ] Validation technique obtenue
- [ ] Code APE vérifié dans `DKA_CODE_APE.xlsx`
- [ ] Unicité du nouveau code société vérifiée

### ☐ PHASE 2 : TEST ETI
- [ ] Environnement ETI sauvegardé
- [ ] Déploiement SoftaPlay lancé en ETI
- [ ] Logs d'exécution sans erreurs critiques
- [ ] OU créée et visible dans ETI
- [ ] Paramètres comptables validés
- [ ] Flag taxe vérifié et corrigé (`use_le_as_subscriber_flag = 'Y'`)
- [ ] Test de création facture fournisseur OK
- [ ] Test de création commande OK
- [ ] Séquences de numérotation fonctionnelles
- [ ] Validation fonctionnelle GO obtenue
- [ ] Version finale fichier INITSOC (VXX)

### ☐ PHASE 3 : PRODUCTION
- [ ] Fichiers PROD créés à partir de la version ETI validée
- [ ] Sauvegarde PROD effectuée
- [ ] Plan de rollback prêt
- [ ] Utilisateurs notifiés
- [ ] Connexion environnement PROD vérifiée (DOUBLE CHECK)
- [ ] Déploiement SoftaPlay lancé en PROD
- [ ] Exécution terminée : statut SUCCESS
- [ ] OU créée en PROD
- [ ] Legal Entity liée
- [ ] Ledger associé correctement
- [ ] Périodes comptables ouvertes
- [ ] **Flag taxe corrigé en PROD (CRITIQUE - KDFI-187)**
- [ ] Sites fournisseurs visibles
- [ ] Séquences de documents initialisées
- [ ] Test transactionnel PROD OK
- [ ] Validation GO production

### ☐ PHASE 4 : FINALISATION
- [ ] Correctifs post-production appliqués (si nécessaire)
- [ ] Communication utilisateurs envoyée
- [ ] Formation réalisée (si nécessaire)
- [ ] `Setup SoftaPlay Projects.xlsx` mis à jour
- [ ] `Paramétrages POST SOFTAPLAY de sociétés_MAI 2024.xlsx` mis à jour
- [ ] Surveillance J+1 effectuée
- [ ] Surveillance J+2 effectuée
- [ ] Surveillance J+3 effectuée
- [ ] Surveillance J+4 effectuée
- [ ] Surveillance J+5 effectuée
- [ ] Réunion de clôture tenue
- [ ] Rapport de clôture rédigé
- [ ] REX documenté
- [ ] Fichiers archivés dans `YYYYMM/Transfert [X] sociétés/`

---

## 5. POINTS D'ATTENTION CRITIQUES

### 🔴 CRITIQUE - À NE PAS OUBLIER

#### 1. Flag Profil Taxe (KDFI-187)
**Problème** : SoftaPlay ne positionne pas automatiquement le flag `use_le_as_subscriber_flag`.

**Impact** : Dysfonctionnement du moteur de taxes (module ZX) → factures impossibles à valider.

**Solution** : Exécuter SYSTÉMATIQUEMENT après chaque transfert :
```sql
UPDATE zx_party_tax_profile
SET use_le_as_subscriber_flag = 'Y'
WHERE party_type_code = 'OU'
  AND party_id = [new_org_id]
  AND use_le_as_subscriber_flag IS NULL;
COMMIT;
```

**Quand** : 
- Immédiatement après déploiement ETI
- Immédiatement après déploiement PROD

---

#### 2. Vérification Environnement
**Risque** : Exécuter un transfert PROD dans l'environnement ETI (ou inversement).

**Protection** :
- **TOUJOURS** double-vérifier l'environnement connecté dans SoftaPlay
- Vérifier le nom de la connexion : `oracleETI` vs `oracleProd`
- Demander confirmation verbale avant de lancer

---

#### 3. Sauvegarde Avant Déploiement PROD
**Risque** : Impossibilité de rollback en cas d'échec.

**Protection** :
- Sauvegarde complète de la base PROD avant tout transfert
- Plan de rollback documenté et testé
- Fenêtre de maintenance si transfert sensible

---

#### 4. Unicité du Code Société
**Risque** : Code société déjà existant → échec du transfert.

**Protection** :
```sql
-- VÉRIFIER AVANT de créer les fichiers
SELECT organization_id, name, short_code
FROM hr_operating_units
WHERE short_code = '0520';  -- Nouveau code

-- Résultat attendu : 0 ligne
```

---

#### 5. Versioning des Fichiers
**Risque** : Déployer une ancienne version du fichier INITSOC.

**Protection** :
- Incrémenter systématiquement la version (V01 → V02 → V03)
- Noter dans le nom du fichier
- Traçabilité des modifications

---

## 6. DURÉES ESTIMÉES PAR ÉTAPE

| Étape | Durée Minimale | Durée Maximale | Durée Moyenne |
|-------|----------------|----------------|---------------|
| **Phase 1 : Préparation** | 4 jours | 15 jours | 7 jours |
| - Analyse existant | 1 jour | 2 jours | 1,5 jours |
| - Création fichiers | 2 jours | 3 jours | 2,5 jours |
| - Validation | 1 jour | 10 jours | 3 jours |
| **Phase 2 : Test ETI** | 1 jour | 5 jours | 2 jours |
| - Déploiement ETI | 2 heures | 4 heures | 3 heures |
| - Tests fonctionnels | 4 heures | 2 jours | 1 jour |
| - Corrections | 0 | 3 jours | 4 heures |
| **Phase 3 : Production** | 4 heures | 1 jour | 6 heures |
| - Préparation | 2 heures | 4 heures | 3 heures |
| - Déploiement PROD | 30 min | 2 heures | 1 heure |
| - Validations | 1 heure | 2 heures | 1,5 heures |
| **Phase 4 : Finalisation** | 3 jours | 7 jours | 5 jours |
| - Corrections post-PROD | 0 | 1 jour | 2 heures |
| - Communication | 2 heures | 1 jour | 4 heures |
| - Surveillance | 3 jours | 5 jours | 5 jours |
| **TOTAL PROJET** | **9 jours** | **28 jours** | **15 jours** |

---

## 7. RÔLES ET RESPONSABILITÉS

| Rôle | Responsabilités | Phases |
|------|----------------|--------|
| **Chef de Projet** | Coordination globale, validation étapes, communication | Toutes |
| **Analyste Fonctionnel** | Analyse existant, définition besoins, tests fonctionnels | 1, 2, 4 |
| **Administrateur EBS** | Création fichiers, déploiement SoftaPlay, paramétrage technique | 1, 2, 3 |
| **DBA** | Sauvegardes, vérifications techniques, scripts SQL | 2, 3 |
| **Support Applicatif** | Surveillance post-transfert, support utilisateurs | 4 |
| **Direction Financière** | Validation comptable et fiscale | 1 |
| **Utilisateurs Métier** | Tests fonctionnels, validation finale | 2, 4 |

---

## 8. TEMPLATES DE FICHIERS

### 8.1 Nomenclature Fichier INITSOC (Transfert)

**Format** :
```
INITSOC_[TYPE] - [ANCIEN] devient [NOUVEAU] - [OU_DEST] - [CODE] - V[XX] [MM AAAA].xlsx
```

**Exemples réels** :
```
INITSOC_DK 23 devient MOTTEO DOS VERS DEW 0507 - 01 25.xlsx
INITSOC_FULL - DOS vers DRW - DK 42 devient CALORIA - 0531 - V01 2025.xlsx
INITSOC- DOS VERS DNA - DK 43 devient RCCHOSPITALIER ANGOULEME - 0532 - V02 2025.xlsx
INITSOC_SVD 102 devient MIRECOURT CHALEUR URBAINE DOS VERS DCW 0402 - 02 25.xlsx
INITSOC_FULL - DK33 de vient SRCM - DEW - 0520 - V04 2025.xlsx
INITSOC_SVD 115 devient ESTER 0444 DLS 05 2025.xlsx
```

### 8.2 Nomenclature Fichier Suivi Mensuel

**Format** :
```
20 - Créations [AAAA MM]_[ENV]_Trans.xlsx
```

**Exemples** :
```
20 - Créations 2025 01_ETI_Trans.xlsx
20 - Créations 2025 02_ETI_Trans.xlsx
20 - Créations 2025 04_ETI_Trans.xlsx
20 - Créations 2025 06_PROD_Trans.xlsx
```

### 8.3 Nomenclature Fichier Deployment

**Format** :
```
20 - Deployment_ [AAAA MM]_[DÉTAILS]_[ENV]_Trans.xls
ou
Deployment_[AAAA MM]_[SOCIÉTÉ]_[OU_DEST] - [ENV].xls
```

**Exemples** :
```
20 - Deployment_ 2025 01_ETI_Trans.xls
20 - Deployment_ 2025 02_ETI_Cré-Trans - DCW0402.xls
20 - Deployment_ 2025 04_ETI_Trans.xls
20 - Deployment_ 2025 06_DK 52_PROD_Trans.xls
Deployment_2025 06_SVD 101_DRW - ETI1.xls
```

### 8.4 Nomenclature Fiche Partenaires

**Format** :
```
Fiche de création Partenaires Kador [ANCIEN] devient [NOUVEAU] - [CODE] - [MM AAAA].xlsx
```

**Exemple** :
```
Fiche de création Partenaires Kador DK 23 devient MOTTEO - 0507 - 01 2025.xlsx
```

---

## 9. SCRIPTS SQL UTILES

### 9.1 Vérifications Pré-Transfert

```sql
-- 1. Identifier l'OU source
SELECT organization_id, name, short_code, set_of_books_id
FROM hr_operating_units
WHERE short_code = 'DK23';

-- 2. Vérifier unicité nouveau code
SELECT organization_id, name, short_code
FROM hr_operating_units
WHERE short_code = '0520';  -- Doit être vide

-- 3. Transactions en cours (source)
SELECT 'Factures AP' as type, COUNT(*) as nb, SUM(invoice_amount) as montant
FROM ap_invoices_all
WHERE org_id = [org_id_source]
  AND validation_request_id IS NULL
UNION ALL
SELECT 'Commandes PO', COUNT(*), SUM(pl.line_quantity * pl.unit_price)
FROM po_headers_all ph, po_lines_all pl
WHERE ph.po_header_id = pl.po_header_id
  AND ph.org_id = [org_id_source]
  AND ph.closed_code = 'OPEN';

-- 4. Fournisseurs actifs (source)
SELECT COUNT(*) as nb_sites_fournisseurs
FROM ap_supplier_sites_all
WHERE org_id = [org_id_source]
  AND inactive_date IS NULL;
```

### 9.2 Vérifications Post-Transfert

```sql
-- 1. OU créée
SELECT organization_id, name, short_code, date_from
FROM hr_operating_units
WHERE short_code = '0520';

-- 2. Legal Entity liée
SELECT hoi.organization_id,
       hoi.org_information1 as legal_entity_id,
       xle.name as legal_entity_name
FROM hr_organization_information hoi,
     xle_entity_profiles xle
WHERE hoi.organization_id = [new_org_id]
  AND hoi.org_information_context = 'Operating Unit Information'
  AND hoi.org_information1 = xle.legal_entity_id;

-- 3. Ledger et devise
SELECT gsob.ledger_id,
       gsob.name,
       gsob.currency_code,
       gsob.period_set_name,
       gsob.accounted_period_type
FROM gl_sets_of_books gsob,
     hr_operating_units hou
WHERE hou.organization_id = [new_org_id]
  AND hou.set_of_books_id = gsob.ledger_id;

-- 4. Périodes comptables ouvertes
SELECT period_name, 
       period_year, 
       period_num,
       closing_status,
       start_date,
       end_date
FROM gl_period_statuses
WHERE application_id = 101
  AND ledger_id = [ledger_id]
  AND closing_status IN ('O', 'F')  -- Open, Future
ORDER BY period_year DESC, period_num DESC
FETCH FIRST 12 ROWS ONLY;

-- 5. Sites fournisseurs migrés
SELECT aps.vendor_site_code,
       aps.vendor_id,
       aps.vendor_site_id,
       aps.org_id,
       aps.inactive_date
FROM ap_supplier_sites_all aps
WHERE aps.org_id = [new_org_id]
ORDER BY aps.creation_date DESC
FETCH FIRST 20 ROWS ONLY;

-- 6. Séquences de documents
SELECT fds.doc_sequence_name,
       fds.db_sequence_name,
       fdsa.category_code,
       fdsa.method_code
FROM fnd_document_sequences fds,
     fnd_doc_sequence_assignments fdsa
WHERE fdsa.doc_sequence_id = fds.doc_sequence_id
  AND fdsa.org_id = [new_org_id];
```

### 9.3 Correction Flag Taxe (KDFI-187)

```sql
-- Diagnostic
SELECT party_id,
       party_type_code,
       use_le_as_subscriber_flag,
       CASE 
         WHEN use_le_as_subscriber_flag IS NULL THEN '❌ À CORRIGER'
         WHEN use_le_as_subscriber_flag = 'N' THEN '❌ À CORRIGER'
         WHEN use_le_as_subscriber_flag = 'Y' THEN '✅ OK'
       END as statut
FROM zx_party_tax_profile
WHERE party_type_code = 'OU'
  AND party_id = [new_org_id];

-- Correction (si nécessaire)
UPDATE zx_party_tax_profile
SET use_le_as_subscriber_flag = 'Y',
    last_update_date = SYSDATE,
    last_updated_by = FND_GLOBAL.user_id
WHERE party_type_code = 'OU'
  AND party_id = [new_org_id]
  AND (use_le_as_subscriber_flag IS NULL 
       OR use_le_as_subscriber_flag = 'N');

COMMIT;

-- Vérification finale
SELECT party_id, use_le_as_subscriber_flag
FROM zx_party_tax_profile
WHERE party_type_code = 'OU'
  AND party_id = [new_org_id];
-- Résultat attendu : use_le_as_subscriber_flag = 'Y'
```

### 9.4 Surveillance Post-Transfert

```sql
-- Transactions créées depuis le transfert
SELECT TO_CHAR(creation_date, 'YYYY-MM-DD HH24:MI') as date_creation,
       'Facture AP' as type,
       invoice_num as numero,
       invoice_amount as montant,
       created_by
FROM ap_invoices_all
WHERE org_id = [new_org_id]
  AND creation_date >= TO_DATE('[date_transfert]', 'YYYY-MM-DD')
UNION ALL
SELECT TO_CHAR(creation_date, 'YYYY-MM-DD HH24:MI'),
       'Commande PO',
       segment1,
       NULL,
       created_by
FROM po_headers_all
WHERE org_id = [new_org_id]
  AND creation_date >= TO_DATE('[date_transfert]', 'YYYY-MM-DD')
ORDER BY 1 DESC;

-- Activité comptable
SELECT TO_CHAR(gl.creation_date, 'YYYY-MM-DD') as date_jour,
       COUNT(*) as nb_ecritures,
       SUM(ABS(gl.accounted_dr)) as total_debit,
       SUM(ABS(gl.accounted_cr)) as total_credit
FROM gl_je_lines gl,
     gl_je_headers gh
WHERE gl.je_header_id = gh.je_header_id
  AND gh.ledger_id = [ledger_id]
  AND gl.creation_date >= TO_DATE('[date_transfert]', 'YYYY-MM-DD')
GROUP BY TO_CHAR(gl.creation_date, 'YYYY-MM-DD')
ORDER BY 1 DESC;
```

---

## 10. TROUBLESHOOTING

### Problème 1 : Échec du Déploiement SoftaPlay

**Symptômes** :
- Message d'erreur dans SoftaPlay
- Statut : FAILED
- OU non créée

**Causes possibles** :
1. Code société déjà existant
2. Fichier INITSOC mal formaté
3. Problème de connexion base de données
4. Données manquantes (Legal Entity, Ledger)

**Solutions** :
1. Vérifier l'unicité du code (SQL ci-dessus)
2. Valider la structure du fichier INITSOC
3. Tester la connexion Oracle
4. Vérifier les logs détaillés de SoftaPlay
5. Corriger et relancer (incrémenter version)

---

### Problème 2 : Flag Taxe Non Positionné

**Symptômes** :
- Erreur lors de la validation de factures
- Message : "Tax Profile not configured"
- Module ZX non fonctionnel

**Cause** :
- `use_le_as_subscriber_flag` = NULL ou 'N'

**Solution** :
```sql
UPDATE zx_party_tax_profile
SET use_le_as_subscriber_flag = 'Y'
WHERE party_type_code = 'OU'
  AND party_id = [new_org_id];
COMMIT;
```

---

### Problème 3 : Séquences Non Initialisées

**Symptômes** :
- Erreur de numérotation de documents
- Message : "Sequence not found"

**Cause** :
- Séquences Oracle non créées ou non assignées

**Solution** :
1. Identifier les séquences manquantes
2. Créer manuellement les séquences
3. Assigner via `fnd_doc_sequence_assignments`

---

### Problème 4 : Périodes Comptables Fermées

**Symptômes** :
- Impossible de créer des transactions
- Message : "Period is closed"

**Cause** :
- Périodes non ouvertes pour la nouvelle OU

**Solution** :
```sql
-- Ouvrir la période courante
UPDATE gl_period_statuses
SET closing_status = 'O',
    last_update_date = SYSDATE
WHERE application_id = 101
  AND ledger_id = [ledger_id]
  AND period_name = '[period_name]'
  AND closing_status = 'N';
COMMIT;
```

---

## 11. ANNEXES

### Annexe A : Codes Operating Units Dalkia

| Code | Nom Complet | Description |
|------|-------------|-------------|
| **DOS** | Dalkia Operating Source | OU source pour créations et transferts |
| **DNA** | Dalkia Nord-Est | Région Nord-Est France |
| **DCW** | Dalkia Centre-Ouest | Région Centre-Ouest France |
| **DRW** | Dalkia Région Ouest | Région Ouest France |
| **DEW** | Dalkia Est | Région Est France |
| **DMS** | Dalkia Méditerranée Sud | Région Sud France |
| **DLS** | Dalkia LS | (À confirmer) |
| **DSW** | Dalkia SW | (À confirmer) |

### Annexe B : Historique des Transferts 2025

| Mois | Nb Transferts | Sociétés | Codes | OU Dest |
|------|---------------|----------|-------|---------|
| 01/2025 | 1 | MOTTEO | 0507 | DEW |
| 02/2025 | 3 | MIRECOURT CH. URB., CALORIA, RCCH ANGOULEME | 0402, 0531, 0532 | DCW, DRW, DNA |
| 04/2025 | 1 | SRCM | 0520 | DEW |
| 05/2025 | 1 | ESTER | 0444 | DLS |
| 06/2025 | 2+ | (Non détaillé) | - | DRW, autres |

**Total 2025 (jan-juin)** : 8+ transferts

### Annexe C : Versions de Documentation

| Document | Version | Date | Statut |
|----------|---------|------|--------|
| Création de société complète | V2.0 | 18-AVR-2025 | ✅ ACTUELLE |
| Création et transfert de SVD | V2.1 | 27-NOV-2025 | ✅ ACTUELLE |
| Création de société complète | V1.5 | 14-DEC-2021 | ⚠️ OBSOLÈTE |
| Création et transfert de SVD | V1.2 | 22-DEC-2021 | ⚠️ OBSOLÈTE |

**Recommandation** : Utiliser UNIQUEMENT les versions 2.x

---

## 12. CONCLUSION

Le transfert de sociétés entre Operating Units est une opération structurante qui nécessite :

✅ **Rigueur** : Respect scrupuleux des étapes  
✅ **Coordination** : Implication de multiples équipes  
✅ **Tests** : Validation systématique en ETI avant PROD  
✅ **Vigilance** : Points critiques (flag taxe, séquences, périodes)  
✅ **Documentation** : Traçabilité complète du processus  

**Durée moyenne** : 15 jours (préparation + exécution + suivi)  
**Criticité** : Haute (impact comptable et opérationnel)  
**Automatisation** : Partielle via SoftaPlay (correctifs manuels nécessaires)

---

**Document validé par** : Équipe Technique Oracle EBS  
**Prochaine révision** : Après chaque transfert majeur (mise à jour REX)

---

**FIN DE LA PROCÉDURE**
