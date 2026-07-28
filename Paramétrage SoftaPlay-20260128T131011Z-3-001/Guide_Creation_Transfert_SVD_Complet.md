# Guide Complet - Création et Transfert de SVD

**Date de création** : 28 janvier 2026  
**Version** : 2.1 (basé sur doc officiel)  
**Contexte** : Oracle E-Business Suite 12.2.13 - SoftaPlay 2.1.027  
**Application** : Sociétés à Volume Dérisoire (SVD)

---

## TABLE DES MATIÈRES

### PARTIE 1 : CRÉATION D'UNE SVD
1. [Préambule](#1-préambule-création)
2. [Pré-requis](#2-pré-requis-création)
3. [Traitement SoftaPlay Phase 1](#3-traitement-softaplay-phase-1-création)
4. [Paramétrages Manuels](#4-paramétrages-manuels-création)
5. [Traitement SoftaPlay Phase 2](#5-traitement-softaplay-phase-2-création)
6. [Post Création](#6-post-création)

### PARTIE 2 : TRANSFERT D'UNE SVD
1. [Préambule](#1-préambule-transfert)
2. [Pré-requis](#2-pré-requis-transfert)
3. [Traitement SoftaPlay](#3-traitement-softaplay-transfert)
4. [Post Transfert](#4-post-transfert)

---

# PARTIE 1 : CRÉATION D'UNE SVD

## 1. PRÉAMBULE (Création)

Le présent document décrit la procédure permettant de **créer une ou plusieurs SVD** dans Oracle FIN01. Ces paramétrages sont réalisés à l'aide de l'application **SoftaPlay**, avec un chargement préalable réalisé à l'aide de l'outil **DataLoad**.

---

## 2. PRÉ-REQUIS (Création)

### 2.1 Identification de la nouvelle organisation logistique

**PR1.01** : Identifier le numéro de la nouvelle organisation logistique

```sql
SELECT MAX(organization_code) 
FROM MTL_PARAMETERS_VIEW 
ORDER BY organization_code DESC;
```

➡️ **Action** : Ajouter 1 au résultat pour alimenter la variable « **Inventory Org Num** »

---

### 2.2 Remplissage du fichier de création DataLoad

**Onglet à renseigner** : « **A créer** » (les autres se remplissent automatiquement)

**Récupération depuis l'onglet « INITSOC- Oracle R12 »** :

| Champ | Source |
|-------|--------|
| **Num pour TSA** | Valeur entre parenthèses du champ « Libellé de l'adresse » (onglet TSA CSP) |
| **Numéro & rue** | Colonnes C et D de l'onglet « TSA CSP » |
| **Projet FPS** | Champ « Projet Finance par UO » (onglet Nouveau référentiel R12) |

---

### 2.3 Jeux de valeurs pour GL

#### PR1.02 : GL - Code de regroupement

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Regroupement
- **Jeu de valeurs** : `DAOPCCF_STE`

✅ **Action** : Créer le code de regroupement de la nouvelle société

---

#### PR1.03 : GL - Codes conso pour Vector

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `XDKA_ARGOS_INTERCO`

✅ **Action** : Créer le code conso de la nouvelle société

---

#### PR1.04 : GL - Codes sociétés

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_STE`

✅ **Actions** :
1. Créer le code de la nouvelle société
2. Créer le code de regroupement (Axxx)
3. Pour la valeur **A423** : cocher **Parent** + mettre **Groupe**
4. Cliquer sur « **Définir fourchette Enfant** » et indiquer le code société

---

#### PR1.05 : GL - Codes Interco

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_INTERCO`

✅ **Actions** : Créer **3 valeurs** :

1. **Valeur Société** (coché Parent) : `0423`
   - Cliquer sur « Définir les fourchettes enfants » pour associer DOS0423 et XXX0423

2. **Valeur** : `DOS0423`
   - Segmentation magnitude : **Non** (Mono Région) ou **Oui** (Multi Régions)

3. **Valeur** : `XXX0423`

---

#### PR1.06 : GL - Comptes locaux

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_LOCAL`

✅ **Action** : Créer le compte comptable du compte bancaire

---

#### PR1.07 : GL - Projet Finance

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_PROJETFI`

✅ **Actions** :
1. Créer la valeur **XXXYYYY** (Projet de REFAC)
2. Créer la valeur du **Projet Frais et Produits de Société (FPS)**

---

#### PR1.08 : GL - Règles de validations croisées

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Règles

⚠️ **Filtrer d'abord sur** : `STE%`

✅ **Actions** :
- **STE-REGION** : Inclure la règle de `0` à `ZZZZ`
- **STE-PARTENAIRE** : 
  - Exclure le code partenaire région (ex : `DOS0423`)
  - Exclure le code partenaire XXX (ex : `XXX0423`)

---

#### PR1.09 : GL - Création des adresses

- **Responsabilité** : `DKA PO SAISIE DES EMPLOYES`
- **Navigation** : Lieu

⚠️ **Note** : Les écrans des responsabilités PO comportent un CUF supplémentaire, ils ne sont pas compatibles avec le format DataLoad.

✅ **Actions** : Se positionner sur l'onglet « **Adresses** » du fichier de création

**Adresses à créer** :
1. **Adresse du siège social** : Code = variable « Company Name »
2. **Adresse de facturation** : Code = variable « Code UO »

⚠️ **Surveillance** : Corriger les champs des adresses car le Tab4 DataLoad risque d'être trop rapide (code postal et ville dans le même champ)

---

#### PR1.10 : GL - Table de transco DKA_CONSO_VECTOR

- **Responsabilité** : `Administrateur Exploitation Dalkia`
- **Navigation** : Écran de transco > Lignes
- **Context** : `DKA_CONSO_VECTOR`

✅ **Action** : Code société + région = Code conso

---

#### PR1.11 : GL - Table Transco pour compte Groupe

- **Responsabilité** : `Administrateur Exploitation Dalkia`
- **Navigation** : Écran de transco > Lignes
- **Context** : `MIGR_GROUP_ACCOUNT_CLASS_BILAN`

✅ **Action** : Pour les comptes de banque ⇒ **Compte groupe 17060**

---

### 2.4 Désactivation des règles de validations croisées

**PR1.11** : GL - Règles de validation croisée

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Règles

✅ **Désactiver temporairement** :
- ❌ `BG-BL` : Bilan Analytique - Bilan Local
- ❌ `CE-RG` : Centre - Resultat Compte Analytique
- ❌ `CE-RL` : Centre - Resultat Compte Local
- ❌ `GRP-FLUX` : Gère les combinaisons Cpte Analytique / Flux autorisée
- ❌ `STE-REGION` : Interdit les couples Société/Région inexistant

---

### 2.5 CE Compte bancaire

**PR1.12** : CE - Vérifier l'existence de la banque pour le compte et la créer si besoin

**PR1.13** : CE - Vérifier l'existence de l'agence bancaire pour le compte et la créer si besoin

**PR1.14** : CE - Créer le compte bancaire

---

## 3. TRAITEMENT SOFTAPLAY PHASE 1 (Création)

### 3.1 Chargement des variables dans SoftaPlay

**Étape 1** : Suppression des variables des sociétés créées dans un projet précédent
- Clic droit « **Remove** » ⇒ société par société

**Étape 2** : Charger les variables des sociétés du nouveau projet

⚠️ **IMPORTANT** : Les variables « **Inventory Org Num** » et « **Share capital** » doivent obligatoirement être renseignées sous forme de **texte** (ex : `'346`)

❌ **Sinon** : L'ID ne sera pas traduit correctement ⇒ Erreur « **Organization Already exists** »

**Étape 3** : Passer en mode « Déploiement »
- Clic droit sur le projet « **SVD Création** »
- Choisir « **Monitor Project** »

---

### 3.2 Extraction des données de la société de référence

➀ Sélectionner l'ensemble des composants  
➁ Cliquer sur le bouton « **Extract** »  
➂ Le nombre d'occurrences extraites pour chaque composant est affiché

---

### 3.3 Appliquer les règles aux enregistrements extraits

Cliquer sur le bouton « **Apply** » et choisir la ou les sociétés à traiter.

Le résultat de l'Apply est présenté dans une fenêtre avec des combo-box permettant d'afficher composants et sous-composants.

---

### 3.4 Mettre à jour la période FA

Le calendrier du livre de la société de référence 9999 commençant avec la période **M1R-20**, il est nécessaire de modifier la date de début du Livre FA.

✅ **Action** : Depuis « **View Apply Result** » ⇒ choisir « **Book controls** » et mettre à jour « **Initial Date** »

**Initial Date** : 
- **Format** : DD/MM/YYYY
- **Logique** : 
  - Si le process de clôture mensuelle est entamé (généralement vers le **24 du mois**) ⇒ mettre le **1er jour du mois en cours**
  - Si le process de clôture n'est pas en cours ⇒ mettre le **1er jour du mois précédent**

**Exemple** : Pour une période initiale en novembre 2021, saisir `01/10/2021`

---

### 3.5 Déploiement des règles pour la ou les sociétés

**Étape 1** : Modifier en « **Error** » la valeur de « **Stop when** » de la ligne « **Security rules and assignments** » pour éviter un blocage sur les responsabilités non créées.

**Étape 2** : Vérifier que les nouveaux identifiants des organisations à créer sont bien ceux définis dans le fichier des variables (**Inventory Org Num**)

**Étape 3** : Sélectionner les traitements jusqu'à l'**Inventory Org** avant de lancer « **Deploy** » et « **Load** »

**Étape 4** : Cliquer sur le bouton « **Deploy** » et confirmer

---

### 3.6 Chargement du paramétrage

Le déploiement alimente la colonne « **Waiting** » avec le nombre d'enregistrement à créer (en fonction du nombre de société).

Cliquer sur le bouton « **Load** » et confirmer pour lancer les traitements de chargement du paramétrage.

Le résultat des traitements s'affiche dans les colonnes : **Chargé**, **Passé** et **Rejeté**

---

## 4. PARAMÉTRAGES MANUELS (Création)

### 4.1 Lancement du traitement de duplication des données systèmes

- **Responsabilité** : `Administrateur système`
- **Navigation** : Autres / Lancer
- **Traitement** : `Dupliquer les données système`

✅ **Action** : Pour chaque nouvelle unité opérationnelle créée, lancer ce traitement

---

### 4.2 Création des Profils de sécurité

- **Responsabilité** : `TOUT_FA_ADMINISTRATEUR` ou `TOUT_PA_ADMINISTRATEUR`
- **Navigation** : Configurer / Sécurité / Sécurité OU Configuration / Ressources et organisations / Fondation HR / Sécurité / Profil

⚠️ **Pour les étapes 1 et 2** : utiliser l'onglet « **Profil sécu code UO** » du fichier de création

#### ÉTAPE 1 : Ajouter les UO aux profils de sécurité

✅ **Action** : Ajouter les unités opérationnelles aux profils de sécurité existants

#### ÉTAPE 2 : Ajouter l'UO au profil global

✅ **Actions** :
- Ajouter l'UO au profil `DKA_TOUT`
- Ajouter l'UO au profil `DKA_TOUT + REFERENCE`

#### ÉTAPE 3 : Créer un profil de sécurité pour la nouvelle société

✅ **Action** : Créer le profil de sécurité spécifique à la société

#### ÉTAPE 4 : Créer le profil de sécurité région/société

✅ **Action** : Créer le profil correspondant à l'unité opérationnelle

#### ÉTAPE 5 : Lancer le traitement de mise à jour des listes de sécurité

Ce traitement va mettre à jour les listes de valeurs avec les livres appropriés.

#### ÉTAPE 6 : Lancer « Mise à jour des listes de sécurité »

✅ **Paramètres à utiliser** : (voir document)

#### ÉTAPE 7 : S'assurer qu'ils se terminent normalement

✅ **Vérification** : Contrôler le statut des traitements

---

### 4.3 Création des clients pour PA

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Client > Standard

⚠️ **Ce paramétrage est à réaliser pour chaque région/société (UO) <YYYXXXX> de la nouvelle société**

#### Étapes :

**1. Rechercher le client** : `CLIENT_POUR_PA`

**2. Ouvrir le détail du compte**

**3. Cliquer sur « Créer un site »**

**4. Sélectionner l'unité opérationnelle** pour laquelle le site doit être créé puis cliquer sur « **Continuer** »

**5. Compléter les fonctions économiques et le lieu**, puis cliquer sur « **Terminer** »

**6. Revenir dans les fonctions économiques** pour remplacer dans le champ « **Lieu** » l'ID par un « **.** » puis « **Appliquer** » puis « **Sauvegarder** »

---

## 5. TRAITEMENT SOFTAPLAY PHASE 2 (Création)

### 5.1 Réactiver le type de dépenses

✅ **Action** : Réactiver le type de dépenses avant de lancer la 2ème partie de Softa

**Type de dépense** : `FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)`

---

### 5.2 Déploiement Phase 2

**Étape 1** : Décocher les étapes déjà réalisées (jusqu'à Inventory Org)

**Étape 2** : Faire les actions « **Deploy** » et « **Load** »

**Étape 3** : Modifier en « **Error** » la valeur de « **Stop when** » de la ligne « **Implementation Options** » pour éviter un blocage sur le livre d'immo non créés

---

## 6. POST CRÉATION

### 6.1 GL - Règles de validation croisée

**PCS01** : Réactivation des règles de validation croisées

✅ **Réactiver** :
- ✅ `BG-BL` : Bilan Analytique - Bilan Local
- ✅ `CE-RG` : Centre - Resultat Compte Analytique
- ✅ `CE-RL` : Centre - Resultat Compte Local
- ✅ `GRP-FLUX` : Gère les combinaisons Cpte Analytique / Flux autorisée
- ✅ `STE-REGION` : Interdit les couples Société/Région inexistant

---

### 6.2 Traitements de mise à jour

#### 6.2.1 Définir les options fournisseurs/bénéficiaires

- **Responsabilité** : `Administration Exploitation Dalkia`
- **Traitement** : `DKA : Creation des options fournisseurs et bénéficiaires`
- **Paramètre** : Code UO

---

#### 6.2.2 PO : Attachement des conditions générales d'achat à l'UO

- **Responsabilité** : `Administration Exploitation Dalkia`
- **Traitement** : `DKA : Attachement des CGA`

---

#### 6.2.3 Compte bancaires – Autoriser le livre pour la gestion des banques

- **Connexion** : `Sysadmin` (en anglais)
- **Responsabilité** : `User Management`
- **Navigation** : Roles et Role Inhe

**Étapes** :
1. Cliquer sur **Update**
2. Cliquer sur **Security Wizards**
3. Sur la ligne `CE UMX Security wizard` ⇒ Cliquer sur **Wizard**
4. Ajouter le nouveau Livre : **Add Legal Entities**
5. Choisir le livre dans la liste de valeur et le sélectionner
6. Cliquer sur **Use** et **Maintenance** pour le nouveau Livre
7. Cliquer sur **Apply** pour enregistrer
8. Cliquer de nouveau sur **Apply**

---

### 6.3 Post Création Softa – Module GL

#### 6.3.1 Vérifier le segment équilibrage au niveau Établissement

- **Responsabilité** : `TOUT_GL_OP_ADMINISTRATEUR`
- **Navigation** : Configuration Comptable / Entité Comptable / Établissements

**Étapes** :
1. Cliquer sur **Détails**
2. Cliquer sur **Segment d'équilibrage**
3. Cliquer sur **Mettre à jour**
4. Ajouter le segment d'équilibrage de la société

---

#### 6.3.2 Paramétrage Taxe dans GL

⚠️ **Avant** : Ajouter le nouveau Livre créé dans le jeu de livre **OPERATIONNEL**

- **Responsabilité** : `TOUT GL OP`
- **Navigation** : Configurer / Taxe Options de taxe

**Étapes** :
1. **Retirer la société du Jeu de livres**
2. **Ajouter le nouveau Livre (et UO) dans les jeux de livres** :
   - `OPERATIONNEL`
   - `OPERATIONNEL + REFERENCE`
3. **Et pour la région** (plusieurs jeux de livres possibles)

---

#### 6.3.3 Création du paramétrage Pièce Répétitive (Abonnements GL)

✅ **Actions** : Créer les en-têtes de **2 abonnements** pour le nouveau Livre :
- `YYYY XXX` (Exemple : `0423 DOS`)
- `YYYY XXX IFRS` (Exemple : `0423 DOS IFRS`)

---

#### 6.3.4 Création du paramétrage Pièce Répétitive (Équilibre CDG)

⚠️ **Pour les Multi Régions uniquement**

---

### 6.4 Post Création Softa – Module ETAX

#### 6.4.1 Ajouter le nouveau Livre dans la Configuration Fiscale FR

- **Responsabilité** : `Administration Taxe`
- **Navigation** : Configuration Fiscale / Régimes Fiscaux

**Étapes** :
1. Mettre le code Pays **France** et cliquer sur **Accéder**
2. Cliquer sur **Mettre à jour**
3. Cliquer sur **Continuer**
4. Cliquer sur **Ajouter parties**
5. Chercher le nouveau livre et le sélectionner
6. Cliquer sur **Terminer** (2 fois avec messages + de 300 lignes)

---

#### 6.4.2 Ajouter l'UO dans la partie

- **Navigation** : Partie / Profils fiscaux de partie

**Paramètres** :
- **Type de partie** : `UO`
- **Nom** : `XXXYYYY` (Nom de l'UO, exemple : `DOS0423`)

**Étapes** :
1. Cliquer sur **Accéder**
2. Cliquer sur **Créer un profil Fiscal**
3. ✅ **Cocher** « Utiliser l'abonnement de l'entité juridique »
4. Cliquer sur **Appliquer**

---

### 6.5 Post Création Softa – Module PA

#### 6.5.1 Vérifier le code AFFAIRE sur le modèle de PROJET ORGANIQUE

- **Responsabilité** : `XXXYYY_PA_ADMINISTRATEUR`
- **Action** : Mettre le code AFFAIRE `A00000000A` sur le modèle de projet **ORGANIQUE**

---

#### 6.5.2 Création des modèles ACCORD CADRE

- **Responsabilité** : `XXXYYYY_PA_ADMINISTRATEUR`
- **Navigation** : Configuration / Facturation / Modèle Accord cadre

✅ **Créer 3 modèles** :
1. **OPERATIONNEL**
2. **ORGANIQUE**
3. **REFAC**

**Pour chaque modèle** :
- Compléter les informations
- Cliquer sur **Financement**
- Cliquer sur la **Disquette** pour sauvegarder

---

#### 6.5.3 Création des Modèles de budgets

- **Responsabilité** : `XXXYYY_PA_ADMINISTRATEUR`
- **Navigation** : Menu BUDGETS

✅ **Créer 3 Modèles de Budgets** :
1. **OPERATIONNEL**
2. **ORGANIQUE**
3. **REFAC**

**Pour chaque budget** :
1. Dans le numéro de Projet ⇒ Rechercher le Projet correspondant
2. Saisir la version du Budget
3. Enregistrer sur la **Disquette**
4. Cliquer sur **Budget Provisoire**
5. Cliquer sur **Détail**
6. Cliquer sur la disquette pour enregistrer et fermer
7. Cliquer sur **Soumettre**
8. Cliquer sur **Budget de Référence** (le budget devient **Actuel**)
9. Cliquer sur la disquette pour sauvegarder

---

#### 6.5.4 Création du projet de REFAC

- **Responsabilité** : `XXXYYY_PA_ADMINISTRATEUR`
- **Navigation** : Configurer / Projets / Modèles de projets

**Paramètres** :
- **Numéro du projet** : `XXXYYYY` (ex : `DOS0423`)
- **Nom du projet** : `DOS0423-REFAC`
- **Description** : `DOS0423-REFAC`
- **Centre Fi du projet** : Selon la région (ex : DOS = `B00000001B`)
- **Date de début** : `01/01/1951`

**Étapes** :
1. Se placer sur le modèle **REFAC**
2. Cliquer sur **Copier vers**
3. Remplir les zones
4. Cliquer sur **OK**

---

#### 6.5.5 MAJ de l'organisation

✅ **Action** : Mettre la TF **DIAPASON**

---

### 6.6 Paramétrage sur perso écran AR (Mouvements et Règlements)

#### 6.6.1 Écran de saisie des mouvements AR

- **Responsabilité** : `TOUT_AR_ADMIN`

✅ **Action** : Ajouter **2 responsabilités** et cliquer sur **Enregistrer**

---

#### 6.6.2 Écran de saisie des règlements AR

- **Responsabilité** : `TOUT_AR_ADM`

✅ **Action** : Ajouter **3 responsabilités**

---

### 6.7 Paramétrage Comptes Non Soldés AR et AP

#### 6.7.1 Paramétrages comptes collectifs – Comptes non soldés AR

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Configuration / Comptabilité / Définition des listes de soldes comptes ouverts

**Paramètres** :
- **Code** : `CLIENTS_YYYY` (ex : `CLIENTS_0423`)
- **Nom** : `CLIENTS_YYYY`
- **Description** : `Balances Clients YYYY` (ex : `Balance clients 0423`)
- **Côté du solde** : `Débit`
- **Actif** : `Oui`

---

#### 6.7.2 Paramétrages comptes collectifs – Comptes non soldés AP

- **Responsabilité** : `TOUT_AP_ADMINISTRATEUR`
- **Navigation** : Configurer / Configuration Comptable / Définition des soldes des comptes non ouverts

---

### 6.8 Paramétrage compte bancaire interne Dalkia

#### 6.8.1 Création du compte bancaire

- **Responsabilité** : `TOUT_AP_ADMINISTRATEUR`

**Étapes** :
1. Ajouter la nouvelle UO créée
2. Cliquer sur **TERMINER**
3. Le compte bancaire interne est créé

---

#### 6.8.2 Créer les Titres de paiements

**Navigation** : Cliquer sur « **Gérer les titres de paiements** »

**Étapes** :
1. Cliquer sur **Créer**
2. Créer le compte **585000** pour la nouvelle société
   - Exemple : `0423_DOS_585000`
   - Compte de trésorerie : `0423.DOS.585000.14300.0.0.0.0.0.0.0.0`
   - Banque : `TRESORERIE INTERNE (99999)`
   - Agence : `COMPTE DE LIAISON (99999)`
3. Créer **3 titres de paiements**

---

#### 6.8.3 Créer les Modèles instructions de règlements

---

#### 6.8.4 Côté AR : créer les modes de Règlements AR

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Configurer / Règlements / Classes de règlements

✅ **Créer** : **CHEQUE** et **VIREMENT**

---

### 6.9 Post Création Softa – Création des modes de Règlements AR

#### 6.9.1 Création des modes de règlements VIREMENT sur 51* et 585*

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Configurer / Règlement / Classe de règlement

---

#### 6.9.2 Création des modes de règlements CHEQUE sur 51* et 585*

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Configurer / Règlement / Classe de règlement

---

### 6.10 Affectation des séquences

- **Responsabilité** : `Administration Exploitation Dalkia`
- **Navigation** : Application / Numérotation des pièces / Affecter

✅ **Action** : Affecter les séquences aux livres créés

---

### 6.11 Paramétrage pour intagra groupe AP/AR

- **Responsabilité** : `TOUT AR ADMINISTRATEUR`
- **Navigation** : Configurer / Règlement / Origines de règlements

**Étapes** :
1. Faire **F11** et indiquer l'UO
2. **CTRL F11**
3. Compléter : Le **Mode de règlement** et la **banque**
4. **Sauvegarder**
5. Aller dans : Configurer / Règlement / Interface de règlements / Interface de Règlements
   - Onglet **Règlements**
   - Onglet **Mouvements**

---

### 6.12 Post Création Softa – Ouverture des périodes TOUS MODULES

⚠️ **Pré requis** : Le **LIVRE** doit être présent dans le Jeu de Livre **OPERATIONNEL**

#### Ouverture période GL

- **Responsabilité** : `TOUT_GL_OP_ADMINISTRATEUR`
- **Navigation** : Configurer / Ouvrir – Fermeture

**Étapes** :
1. Indiquer le livre
2. Cliquer sur **Rechercher**
3. **Ouvrir la période**

#### Ouverture autres périodes

✅ **Ouvrir les périodes pour** :
- **PA** (Projects)
- **AP** (Payables)
- **AR** (Receivables)
- **PO** (Purchasing)
- **FA** (Fixed Assets)

---

### 6.13 Post Création Softa – Validation finale

**PCS01** : GL - Règles de validation croisée

✅ **Réactivation des règles de validation croisées** :
- ✅ `CE-RG` : Centre - Resultat Compte Analytique
- ✅ `CE-RL` : Centre - Resultat Compte Local
- ✅ `GRP-FLUX` : Gère les combinaisons Cpte Analytique / Flux autorisée

---

# PARTIE 2 : TRANSFERT D'UNE SVD

## 1. PRÉAMBULE (Transfert)

Cette partie décrit la procédure permettant de **transférer une SVD** lors de son activation à l'aide de l'application **SoftaPlay**.

Lors du transfert, plusieurs informations sont susceptibles d'être modifiées :
- ✅ Raison sociale
- ✅ Nom du livre comptable
- ✅ Nom et détail de l'adresse
- ✅ Détail de l'adresse de facturation
- ✅ Code région
- ✅ Carrying Out Organization
- ✅ CF région
- ✅ Code UO

⚠️ **IMPORTANT** : Les valeurs de « **Company Name** », « **Location Code** » et « **Code UO** » du fichier de variables (Déploiement) doivent être **absolument identiques** à celles des « raison sociale », « nom du livre comptable », « nom de l'adresse » et « code UO » paramétrés dans Oracle.

---

## 2. PRÉ-REQUIS (Transfert)

### 2.1 Recherche de l'ancienne UO (Org_id)

Les identifiants pouvant être différents d'un environnement à un autre (notamment entre **Recette** et **Production**), il est nécessaire d'exécuter la requête suivante en premier lieu :

```sql
SELECT hou.name, mp.organization_code
FROM MTL_PARAMETERS_VIEW mp, 
     HR_ORGANIZATION_UNITS_V hou
WHERE hou.name LIKE '%0485'
  AND mp.organization_id = hou.organization_id;
```

✅ **Action** : L'information `organization_code` est à renseigner dans le champ « **Inventory Org Num** » du fichier de déploiement

---

### 2.2 Remplissage du fichier de création pour DataLoad

**Onglet à renseigner** : « **A créer** » (les autres se remplissent automatiquement)

**Récupération depuis l'onglet « INITSOC- Oracle R12 »** :

| Champ | Source |
|-------|--------|
| **Num pour TSA** | Valeur entre parenthèses du champ « Libellé de l'adresse » (onglet TSA CSP) |
| **Numéro & rue** | Colonnes C et D de l'onglet « TSA CSP » |
| **Projet FPS** | Champ « Projet Finance par UO » (onglet Nouveau référentiel R12) |

---

### 2.3 Chargement des variables dans SoftaPlay

#### Préparation du fichier de variables

Reprendre et modifier le fichier de déploiement ayant servi pour la création de la SVD ou en préparer un avec les mêmes valeurs et y renseigner :
- ✅ Nouveau « **Company name** » (Raison sociale)
- ✅ Nouveau « **Location code** » (nouveau nom du livre comptable et de l'adresse)
- ✅ Nouveau « **Code UO** »
- ✅ « **CF Région** »
- ✅ « **Carrying Out Organization** » (si la région de destination n'est pas DOS)

**Ces trois informations sont récupérables depuis l'onglet « Orga Région » du fichier de création.**

#### Tableau de correspondance Carrying Out Organization / CF région

| Carrying Out Organization | CF région | Code Région |
|---------------------------|-----------|-------------|
| B00001602W | B00000004E | **DCW** |
| B00001428Y | B00000007H | **DEW** |
| B00001046N | B00000006G | **DLS** |
| B00001135P | B00000008J | **DMS** |
| B00001660L | B00000005F | **DNA** |
| B00001916C | B00000001B | **DOS** |
| B00001691X | B00000002C | **DRW** |
| B00001732T | B00000003D | **DSW** |

---

### 2.4 Mise à jour des jeux de valeurs

Le fichier Excel de création permet de préparer le paramétrage des jeux de valeurs. Celui-ci peut être effectué automatiquement dans Oracle à l'aide de l'outil **DataLoad**.

#### MAJ01. XDKA_ARGOS_INTERCO

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `XDKA_ARGOS_INTERCO`

✅ **Actions** :
1. Rechercher le code conso (Valeur du champ « **CODE CONSO VEOLIA** » du fichier INITSOC)
2. **S'il existe** : Modifier uniquement la **description** avec la nouvelle raison sociale
   - Exemple : DK21 est devenu **MONTCHOVET ENERGIE**, DK 22 est devenu **MONTROUGE ENERGIE RENOUVELABLE**
3. **S'il n'existe pas** : Créer une nouvelle ligne pour ce code conso

---

#### MAJ02. DAOPCCF_STE

⚠️ **Il faut faire cette étape en cas de transfert même si l'onglet du fichier de création est vide pour ce jeu de valeurs**

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_STE`

✅ **Actions** :
1. Rechercher le code société
2. Mettre à jour la **description** avec la nouvelle raison sociale
3. Mettre à jour le CUF **Région principale**
4. Supprimer le code conso SVD en DOS
5. Saisir le nouveau code conso en regard de la bonne région

---

#### MAJ03. DAOPCCF_INTERCO

⚠️ **Il faut faire cette étape en cas de transfert même si l'onglet du fichier de création est vide pour ce jeu de valeurs**

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_INTERCO`
- **Recherche** : `%Société%`

✅ **Actions** :
1. **Créer le nouveau code UO** avec la nouvelle raison sociale et le code ARGOS associé
2. **Mettre à jour la description** avec la nouvelle raison sociale pour le code `XXX<numéro de société>` et changer le code Argos si nécessaire
3. **Mettre à jour la description** avec la nouvelle raison sociale pour le code `<numéro de société>` et ajouter le nouveau code UO dans la liste des « enfants »

---

#### MAJ04. DAOPCCF_LOCAL

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_LOCAL`

✅ **Action** : Recherche par compte local et mise à jour de la raison sociale depuis la colonne D de l'onglet DAOPCCF_LOCAL du fichier de création

---

#### MAJ05. DAOPCCF_PROJETFI

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Valeurs
- **Jeu de valeurs** : `DAOPCCF_PROJETFI`

✅ **Actions** :
1. Créer le nouveau code UO
2. Créer la ligne pour le projet
3. Mettre à jour la description avec la nouvelle raison sociale pour le projet de frais et produits de société

⚠️ **Cette étape peut être réalisée par DataLoad, notamment en cas de transferts multiples**

---

#### MAJ06. GL - Table de transco DKA_CONSO_VECTOR

- **Responsabilité** : `Administrateur Exploitation Dalkia`
- **Navigation** : Écran de transco > Lignes
- **Context** : `DKA_CONSO_VECTOR`

✅ **Actions** :
1. Rechercher le code conso
2. Mettre à jour le code région pour ce code conso
3. Code société + région = Code conso
4. Si le code conso n'est pas le même que celui de l'ancienne société, créer une nouvelle ligne (suivre les instructions de l'onglet DKA_CONSO_VECTOR du fichier de création)

⚠️ **Cette étape peut être réalisée par DataLoad, notamment en cas de transferts multiples**

---

### 2.5 Mise à jour des données d'organisation

#### MAJ.07 : PO - Mettre à jour les adresses

- **Responsabilité** : `DKA PO SAISIE DES EMPLOYES`
- **Navigation** : Lieu

⚠️ **Note** : Les écrans des responsabilités PO comportent un CUF supplémentaire, ils ne sont pas compatibles avec le format DataLoad.

Pour chaque SVD, il existe **2 adresses** identifiées :
1. **Adresse du siège** : Identifiée par le nom du livre comptable
2. **Adresse de facturation** : Identifiée par le code UO

##### Adresse du siège

**Étapes** :
1. Se positionner sur l'onglet « **A créer** » du fichier de création
2. Rechercher le nom du livre comptable (**ancien**)
3. Remplacer par le **nouveau nom du livre comptable**
4. Mettre à jour la **description** par la raison sociale
5. Mettre à jour l'**adresse** mentionnée dans l'onglet « A créer »

##### Adresse de facturation

**Étapes** :
1. Se positionner sur l'onglet « **ADRESSES** » du fichier de création
2. Rechercher par le code UO (**l'ancien**)
3. Remplacer le **nom** par le nouveau code UO
4. Remplacer la **description** par la nouvelle raison sociale, suivie du numéro pour TSA (colonne U de l'onglet Adresses)
5. Mettre à jour l'adresse avec le TSA ou la nouvelle adresse si nécessaire
6. Mettre à jour le CUF « **Région** »

⚠️ **Remarques** :
- La mise à jour du CUF Région n'est pas prise en charge par le fichier de création pour DataLoad. Il faut donc le faire **manuellement** et renseigner la nouvelle région dans la colonne AR de l'onglet ADRESSES.
- Vérifier que le **Location code** est identique pour l'adresse entre les fichiers Déploiement et Création, sinon ajuster le location code de l'adresse dans Oracle.

---

#### MAJ.08 : GL - Nom du Ledger

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Gestionnaire de configuration comptable / Configuration comptable

**Étapes** :

##### Onglet « Configuration comptable »
1. Rechercher la SVD par le nom du livre (**ancien**) et « **Accéder** »
2. Cliquer sur « **Mettre à jour les options comptables** »

##### Onglet « Livre principal »
1. Cliquer sur « **Mettre à jour** » la ligne « Définir et mettre à jour les options … »
2. Modifier le **nom du livre** avec le nouveau nom
3. Cliquer sur « **Terminer** »

##### Onglet « Livres secondaires »
1. Cliquer sur « **Mettre à jour** » la ligne « Définir et mettre à jour les options … »
2. Modifier le nom du livre en le préfixant par **R_**
3. Cliquer sur « **Terminer** »

💡 **Astuce** : En préparation de l'étape suivante, copier le nom de l'entité juridique

---

#### MAJ.09 : XLE - Legal Entity

**Étapes** :

##### Onglet « Entité juridique »
1. Rechercher la SVD par la **raison sociale** et « **Accéder** »
2. Cliquer sur « **Voir les détails** » de l'entité juridique

##### Onglet « Général »
1. Cliquer sur « **Mettre à jour** »
2. Modifier le **nom de l'entité juridique** et le **nom de l'organisation** avec la nouvelle raison sociale
3. Cliquer sur « **Appliquer** »

##### Onglet « Enregistrements »
1. Cliquer sur « **Mettre à jour** »
2. Modifier le « **nom enregistré** »
3. Cliquer sur « **Appliquer** »

##### Onglet « Établissements »
1. Cliquer sur « **Voir les détails** »
2. Cliquer sur « **Mettre à jour** »
3. Modifier le « **nom d'établissement** » et le « **nom d'organisation** » avec la nouvelle raison sociale
4. Cliquer sur « **Appliquer** »

##### Retour sur « Entités juridiques »
1. Rechercher la nouvelle raison sociale
2. Cliquer sur « **Voir les détails** » de la ligne « **Établissement** »
3. Choisir l'onglet « **Enregistrement** » puis « **Mettre à jour** »
4. Mettre à jour le « **Nom enregistré** » avec la nouvelle raison sociale
5. **Vérifier/Remplacer** le numéro de **SIRET**
6. Cliquer sur « **Appliquer** »

⚠️ **IMPORTANT** : S'assurer avant d'enregistrer que le **SIRET** est le même que sur le fichier INITSOC car pour certaines sociétés anciennes, il peut avoir été fermé et remplacé par celui de l'INITSOC. Cela génèrerait l'erreur « **Invalid Establishment** » côté Softa.

---

#### MAJ.10 : AP - Code Operating Unit

- **Responsabilité** : `TOUT_PO_ADMINISTRATEUR`
- **Navigation** : Configurer / Organisations / Organisations

##### Étape 1 : Organisation des immobilisations
Rechercher l'organisation des immobilisations par le **nom du livre comptable** et le remplacer.

##### Étape 2 : Organisation correspondant au code UO
1. Rechercher l'organisation correspondant au **code UO**
2. Renommer celle-ci
3. Mettre à jour le **code abrégé** (Unité opérationnelle / Bouton « **Autres** » / Operating Unit Information)

⚠️ **Important** : Enregistrer d'abord avant de pouvoir modifier le code abrégé dans le CUF

---

#### MAJ.11 : INV - Inventory Org

✅ **Pas d'action**

---

#### MAJ.12 : FA - Livre d'immobilisations

✅ **Pas d'action**

---

### 2.6 Désactivation des règles de validations croisées

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Règles

✅ **Désactiver temporairement l'ensemble des règles de validation croisées**

---

### 2.7 Création / modification des Profils de sécurité

- **Responsabilité** : `TOUT_FA_ADMINISTRATEUR` ou `TOUT_PA_ADMINISTRATEUR`
- **Navigation** : Configurer / Sécurité / Sécurité OU Configuration / Ressources et organisations / Fondation HR / Sécurité / Profil

#### ÉTAPE 1 : Ajouter les UO aux profils de sécurité de sa région

**Exemple** : Ajout de la `DRW0506` à la région DRW

---

#### ÉTAPE 2 : Rechercher puis renommer le profil de sécurité existant

Pour qu'il corresponde au nom de l'organisation (unité opérationnelle) de transfert (ici de `DOS0506` à `DRW0506`).

**Recherche** : `%SOCIETE%` (Exemple : `%0506%`)

---

#### ÉTAPE 3 : Création des Profils Sécurités CSP

**Si l'UO est dans le CSP** :
- Ajouter l'UO dans le profil de sécurité CSP correspondant : `CSP-LIL` ou `CSP-LYO` (CF table de transco CENTRE_SERVICE_PARTAGE)
- Ainsi que `CSP_REF_TOUT` et `CSP_TOUT`

**Si l'UO est Hors CSP** :
- Ajouter l'UO dans le profil de Sécurité **HCSP** de la région concernée :
  - `DCWHCSP`, `DEWHCSP`, `DLSHCSP`, `DMSHCSP`, `DNAHCSP`, `DOSHCSP`, `DRWHCSP`, `DSWHCSP`

---

#### ÉTAPE 4 : Lancer le traitement de mise à jour des listes de sécurité

Ce traitement va mettre à jour les listes de valeurs avec les livres appropriés.

---

#### ÉTAPE 5 : Lancer de nouveau le traitement « Mise à jour des listes de sécurité »

Avec les paramètres appropriés.

---

#### ÉTAPE 6 : S'assurer qu'ils se terminent normalement

✅ **Vérification** : Contrôler le statut des traitements

---

### 2.8 Étapes additionnelles pré-Softa

#### PR1.13 : Suppression de la société des jeux de livres

Supprimer la société des jeux de livres :
- ❌ « **OPERATIONNEL** »
- ❌ « **OPERATIONNEL + REFERENCE** »
- ❌ Région d'origine (DOS en général)

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Jeux de livres

⚠️ **Attention** : Sortir de l'écran après avoir sauvegardé pour que la compilation soit lancée automatiquement.

⚠️ **Remarque** : Si l'une de ces trois suppressions est oubliée, le traitement Softaplay tombe automatiquement en erreur (**Too_many_rows**).

---

#### PR1.14 : Vérification des fonctions économiques

Vérifier que le site (**client pour PA**) est bien actif et dispose des fonctions économiques « **Facturation** » et « **Livrer à** »

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Client > Standard

**Étapes** :
1. Rechercher le client « **CLIENT_POUR_PA** »
2. Ouvrir le détail du compte
3. Rechercher l'unité opérationnelle (faire attention au **statut**, si aucun résultat pour le statut Actif, relancer la recherche avec d'autres statuts)
4. Cliquer sur **Détails** puis aller sur l'onglet « **Fonctions économiques** »

**S'il n'y a aucune fonction économique pour cette UO** :
1. Cliquer sur le bouton **Créer** pour créer les deux fonctions « **Facturation** » et « **Livrer à** »
2. Ne pas oublier de cocher la case « **Principal** »
3. Suite à la création des deux fonctions, il y a un ID généré pour le lieu ⇒ **le remplacer par un point** (`.`)

⚠️ **Ne pas oublier de cliquer sur « Sauvegarder »**

---

#### PR1.15 : Réactivation temporaire du type de dépense

- **Responsabilité** : `TOUT_PA_ADMINISTRATEUR`
- **Navigation** : Configuration / Dépenses / Types de dépenses

**Type de dépense** : `FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)`

✅ **Action** : Réactiver momentanément ce type de dépense en **supprimant la date de fin**

---

## 3. TRAITEMENT SOFTAPLAY (Transfert)

### 3.1 RàZ et chargement des variables

#### Rechercher de nouveau l'ID de l'ancienne UO

```sql
SELECT hou.name, mp.organization_code
FROM MTL_PARAMETERS_VIEW mp, 
     HR_ORGANIZATION_UNITS_V hou
WHERE hou.name LIKE '%0450'
  AND mp.organization_id = hou.organization_id;
```

✅ **Action** : Comparer l'information `organization_code` avec la colonne **Inventory Org Num** du fichier de déploiement. S'ils ne sont pas identiques, remplacer cette colonne par l'ID de l'environnement dans lequel le paramétrage est effectué.

---

#### Suppression des variables précédentes

Une fois connecté à SoftaPlay, la première opération doit être la **suppression des variables** correspondantes aux sociétés créées dans un projet précédent. Cette opération (clic droit « **Remove** ») se fait société par société.

---

#### Chargement des nouvelles variables

Charger les variables des sociétés du nouveau projet en cliquant sur l'icône « **Excel tool** » et en sélectionnant le fichier de déploiement (variables).

---

### 3.2 Traitement SoftaPlay phase 1 : LE, Ledger, OU, Inv Org

Pour passer en mode « **Déploiement** », clic droit sur le projet « **Création Société** » puis choisir « **Monitor Project** »

---

#### 3.2.1 Extraction des données de la société de référence

➀ Sélectionner l'ensemble des composants  
➁ Cliquer sur le bouton « **Extract** » et choisir « **Yes** » dans la boîte de dialogue  
➂ Le nombre d'occurrences extraites pour chaque composant est affiché

---

#### 3.2.2 Appliquer les règles aux enregistrements extraits

Cliquer sur le bouton « **Apply** » et choisir la ou les sociétés à traiter.

Le résultat de l'Apply est présenté dans une fenêtre avec des combo-box permettant d'afficher composants et sous-composants.

On peut revoir les résultats du Apply en cliquant sur les **lunettes**.

---

#### 3.2.3 Mise à jour de la période FA

Penser à mettre à jour la période FA comme pour la partie création FULL (en fonction de la période en cours et de la clôture FA) ⇒ dans la partie **BOOKS CONTROL** (Liste déroulante) ⇒ Colonne « **Initial Date** »

**Initial Date** : 
- Si le process de clôture mensuelle est entamé (généralement vers le **24 du mois**) ⇒ mettre le **1er jour du mois en cours**
- Si le process de clôture n'est pas en cours ⇒ mettre le **1er jour du mois précédent**

✅ **Enregistrer les modifications**

---

### 3.3 Déploiement des règles pour la ou les sociétés

Sélectionner **tous les traitements**, puis lancer « **Deploy** » et « **Load** »

Le Deploy renseigne la colonne « **Waiting** » et le Load, la colonne « **Loaded** »

Les traitements de paramétrage SoftaPlay sont alors lancés :
- 🟢 **Pastilles vertes** : Étapes déroulées avec succès
- 🟡 **Pastilles jaunes** : Erreurs
- 🔺 **Triangle** : Étape en cours

Une fois que la correction est effectuée sur une étape, il faut reprendre le chargement à partir de cette étape, en ayant décoché toutes les étapes précédentes pour ne pas refaire le paramétrage déjà réalisé.

---

### 3.4 Traitement des incidents connus pendant l'exécution de SoftaPlay

#### Incident 1 : Erreur "Too_many_rows"

**Cause** : La société n'a pas été supprimée des jeux de livres « OPERATIONNEL », « OPERATIONNEL + REFERENCE », « DOS » (ou région d'origine)

**Solution** :
1. Ajouter une étape avant l'exécution de SoftaPlay sur l'ensemble des composants
2. Étape de suppression puis de l'ajout de la société aux jeux de livres
3. ⚠️ **Attention** : Sortir de l'écran après avoir sauvegardé pour que la compilation soit lancée automatiquement

---

#### Incident 2 : Rejet lié aux anciennes responsabilités IP

**Statut** : Ce rejet n'est **pas bloquant** vu que les responsabilités « Achats » ne sont plus gérées dans Oracle FIN01.

**Action** : Passer outre et reprendre l'exécution de SoftaPlay à partir de l'étape suivante.

---

#### Incident 3 : Erreur lors de la phase « Project template »

**Cause** : Site non actif ou fonctions économiques manquantes

**Solution** :
1. Activation du site (ex : `DMS0408`)
2. Ajout des fonctions économiques « **Facturation** » & « **Livrer à** »

---

#### Incident 4 : Erreur sur un type de dépense pendant l'étape « Project Template »

**Message d'erreur** :
```
Transaction Controls table : 
..Invalid expenditure type
....EXPENDITURE_TYPE (EXPENDITURE_CATEGORY): FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)
```

**Cause** : Le type de dépense a été désactivé au 31/12/2023

**Solution** :
1. Ouvrir l'écran des types de dépenses
2. Réactiver momentanément ce type de dépense en **supprimant la date de fin**
3. Relancer l'exécution SoftaPlay à partir de l'étape de l'erreur
4. Remettre à nouveau la date de fin pour ce type de dépense

---

#### Incident 5 : Erreur "Invalid Establishment"

**Cause** : Le SIRET de l'établissement de l'entité juridique n'est pas à jour

**Solution** :
1. Vérifier au niveau de l'établissement de l'entité juridique, onglet **Enregistrement**, si le SIRET est le même que celui du fichier INITSOC
2. Si différent, actualiser le SIRET

⚠️ **Si le SIRET est identique** : Passer outre et continuer

---

## 4. POST TRANSFERT

### 4.1 Ajouter les livres aux jeux de livres

✅ **Ajouter le livre aux jeux de livres** :
- `OPERATIONNEL`
- `OPERATIONNEL+REFERENCE`
- Nouvelle région

---

### 4.2 Mise à jour du champ Latest_Opened_Period_Name

**Problème** : L'écran de consultation des périodes s'ouvre systématiquement sur la première période ouverte pour la société (ex : MAI-21).

**Origine** : Le champ `Latest_Opened_Period_Name` de la table `GL_LEDGERS` est nul au lieu d'être renseigné avec la dernière période ouverte.

**Solution** : Mise à jour du champ `Latest_Opened_Period_Name`

#### Vérification

```sql
SELECT ledger_id, name, first_ledger_period_name, latest_opened_period_name
FROM gl_ledgers
WHERE name LIKE '%SVD%116%';
```

#### Récupérer le ledger_id puis lancer

```sql
SELECT *
FROM gl_period_statuses
WHERE closing_status = 'O'
  AND application_id = 101
  AND set_of_books_id = #Ledger_id;
```

#### Mise à jour

Récupérer le `Period_name` de la requête précédente :

```sql
UPDATE gl_ledgers
SET latest_opened_period_name = 'AVR-23'  --Period_name récupéré
WHERE name LIKE '%SVD%116%';
```

---

### 4.3 Vérifier la création des nouvelles règles de validation croisée

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Règles

**Étapes** :
1. Rechercher les règles « **STE-PARTENAIRE** » et « **STE-REGION** » (F11 + `STE%`)
2. Sélectionner une règle puis cliquer dans le tableau des conditions de la règle
3. Les segments de la clé comptable flexible s'affichent automatiquement
4. Cliquer sur « **Annuler** » pour revenir à l'écran
5. Rechercher par `%société%`
6. Créer une ligne similaire avec les touches **Shift+F6**
7. Remplacer le segment « **InterCo** » par le nouveau code UO
8. **Enregistrer** les modifications

---

### 4.4 Case « Utiliser l'abonnement de l'entité juridique » non cochée

- **Responsabilité** : `Administrateur des taxes`
- **Navigation** : Configuration fiscale / Régimes fiscaux
- **Onglet** : Parties ⇒ Profils fiscaux de partie

**Recherche avec** :
- **Type de partie** : `Unité opérationnelle propriétaire du contenu de taxe`
- **Nom de la partie** : Code UO

**Étapes** :
1. Cliquer sur « **Accéder** » puis sur « **Voir un profil fiscal** »
2. La case « Utiliser l'abonnement de l'entité juridique » est **non cochée** et **inactive**

#### Requête de diagnostic

```sql
SELECT use_le_as_subscriber_flag 
FROM zx_party_tax_profile 
WHERE party_type_code = 'OU' 
  AND use_le_as_subscriber_flag IS NULL;
```

Si les résultats sont cohérents avec les UOs en cours de transfert :

#### Correction

```sql
UPDATE zx_party_tax_profile
SET use_le_as_subscriber_flag = 'Y'
WHERE party_type_code = 'OU' 
  AND use_le_as_subscriber_flag IS NULL;
```

✅ **Résultat** : La case à cocher est activée

---

### 4.5 Désactiver le type de dépense FORMATION PRLVTS VOLONTAIRES

- **Responsabilité** : `TOUT_PA_ADMINISTRATEUR`
- **Navigation** : Configuration / Dépenses / Types de dépenses

✅ **Action** : Remettre la date de fin au type de dépense `FORMATION PRLVTS VOLONTAIRES`

---

### 4.6 Réactivation de l'ensemble des règles de validation croisées

- **Responsabilité** : `TOUT_GL_OPE_ADMINISTRATEUR`
- **Navigation** : Configurer / Financials / Champ Flexibles / Clé / Règles

✅ **Réactiver l'ensemble des règles de validation croisées**

---

### 4.7 Vérifier l'origine de mouvement SYSTEME_AMONT

- **Responsabilité** : `TOUT_AR_ADMINISTRATEUR`
- **Navigation** : Configuration / Mouvements / Origines

**Vérification** : Rechercher l'unité opérationnelle et l'origine `SYST%` pour l'année en cours ou à venir (ex : `SYSTEME_AMONT_2025`)

⚠️ **Remarque** : Il arrive dans certains cas que cette origine de mouvement ne se crée pas (**Bug Softaplay**).

**Solution** : 
1. La créer manuellement en sélectionnant une existante dans une autre UO
2. Cliquer sur « **Nouvel enregistrement** » puis **Shift+F6**
3. Remplacer les champs **Unité opérationnelle** et **Entité juridique** par les informations de la société créée

---

### 4.8 PARTIE MOA - Traitements de mise à jour

#### 4.8.1 Définir les options fournisseurs/bénéficiaires

- **Responsabilité** : `Administration Exploitation Dalkia`
- **Traitement** : `DKA : Creation des options fournisseurs et beneficiaires`
- **Paramètre** : Code UO

---

#### 4.8.2 PO : Attachement des conditions générales d'achat à l'UO

- **Responsabilité** : `Administration Exploitation Dalkia`
- **Traitement** : `DKA : Attachement des CGA`

---

#### 4.8.3 Compte bancaires – Autoriser le livre pour la gestion des banques

(Même procédure que pour la création - voir section 6.2.3)

---

### 4.9 Post Transfert – Module GL

(Même procédure que pour la création - voir section 6.3)

---

### 4.10 Post Transfert – Module ETAX

(Même procédure que pour la création - voir section 6.4)

---

### 4.11 Post Transfert – Module PA

(Même procédure que pour la création - voir section 6.5)

---

### 4.12 Paramétrage sur perso écran AR

(Même procédure que pour la création - voir section 6.6)

---

### 4.13 Paramétrage Comptes Non Soldés AR et AP

(Même procédure que pour la création - voir section 6.7)

---

### 4.14 Paramétrage compte bancaire interne Dalkia

(Même procédure que pour la création - voir section 6.8)

---

### 4.15 Post Transfert – Création des modes de Règlements AR

(Même procédure que pour la création - voir section 6.9)

---

### 4.16 Post Transfert – Ouverture des périodes TOUS MODULES

(Même procédure que pour la création - voir section 6.12)

---

### 4.17 Post Transfert – Validation finale

**Réactivation des règles de validation croisées** :
- ✅ `CE-RG` : Centre - Resultat Compte Analytique
- ✅ `CE-RL` : Centre - Resultat Compte Local
- ✅ `GRP-FLUX` : Gère les combinaisons Cpte Analytique / Flux autorisée

---

## CHECKLIST FINALE

### ✅ CRÉATION SVD

- [ ] PR1.01 à PR1.14 : Tous les pré-requis complétés
- [ ] SoftaPlay Phase 1 : Extract, Apply, Deploy, Load réussis
- [ ] Paramétrages manuels : Duplication données, profils sécurité, clients PA
- [ ] SoftaPlay Phase 2 : Deploy et Load réussis
- [ ] Post Création : Tous les modules GL, ETAX, PA, AR, AP configurés
- [ ] Règles de validation croisées réactivées
- [ ] Toutes les périodes ouvertes

### ✅ TRANSFERT SVD

- [ ] MAJ01 à MAJ06 : Tous les jeux de valeurs mis à jour
- [ ] MAJ.07 à MAJ.12 : Toutes les données d'organisation mises à jour
- [ ] Profils de sécurité créés/modifiés
- [ ] Société supprimée des jeux de livres (avant SoftaPlay)
- [ ] SoftaPlay : Extract, Apply, Deploy, Load réussis
- [ ] Latest_Opened_Period_Name mis à jour
- [ ] Règles de validation croisée créées
- [ ] Case « Utiliser l'abonnement de l'entité juridique » cochée
- [ ] Origine de mouvement SYSTEME_AMONT créée
- [ ] Tous les modules GL, ETAX, PA, AR, AP configurés
- [ ] Société ajoutée aux jeux de livres (après SoftaPlay)
- [ ] Règles de validation croisées réactivées
- [ ] Toutes les périodes ouvertes

---

**FIN DU GUIDE COMPLET**

**Date de dernière mise à jour** : 28 janvier 2026  
**Version** : 2.1
