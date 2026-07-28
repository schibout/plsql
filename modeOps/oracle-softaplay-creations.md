# Oracle – SoftaPlay : Création de sociétés et SVD

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. Principes généraux SoftaPlay](#2-principes-généraux-softaplay)
  - [2.1. Rôle de SoftaPlay](#21-rôle-de-softaplay)
  - [2.2. Rôle de DataLoad](#22-rôle-de-dataload)
- [3. Création de société complète (SoftaPlay)](#3-création-de-société-complète-softaplay)
  - [3.1. Pré-requis fonctionnels et techniques](#31-pré-requis-fonctionnels-et-techniques)
  - [3.2. Préparation des fichiers de variables](#32-préparation-des-fichiers-de-variables)
  - [3.3. Chargement des variables dans SoftaPlay](#33-chargement-des-variables-dans-softaplay)
  - [3.4. Exécution des phases SoftaPlay](#34-exécution-des-phases-softaplay)
  - [3.5. Paramétrages et traitements manuels](#35-paramétrages-et-traitements-manuels)
  - [3.6. Post-création : GL, ETAX, PA, AR/AP](#36-post-création--gl-etax-pa-arap)
- [4. Création d’une SVD (Société / entité) via SoftaPlay](#4-création-dune-svd-société--entité-via-softaplay)
  - [4.1. Préambule et pré-requis GL](#41-préambule-et-pré-requis-gl)
  - [4.2. Jeux de valeurs GL à mettre à jour](#42-jeux-de-valeurs-gl-à-mettre-à-jour)
  - [4.3. Désactivation des règles de validation croisées](#43-désactivation-des-règles-de-validation-croisées)
  - [4.4. Phase 1 SoftaPlay : LE, Ledger, OU, Inv Org](#44-phase-1-softaplay--le-ledger-ou-inv-org)
  - [4.5. Paramétrages manuels complémentaires](#45-paramétrages-manuels-complémentaires)
  - [4.6. Phase 2 SoftaPlay et post-création](#46-phase-2-softaplay-et-post-création)
- [5. Transfert d’une SVD](#5-transfert-dune-svd)
  - [5.1. Recherche de l’ancienne UO (Org_id)](#51-recherche-de-lancienne-uo-org_id)
  - [5.2. Mise à jour des jeux de valeurs et tables de transco](#52-mise-à-jour-des-jeux-de-valeurs-et-tables-de-transco)
  - [5.3. Mise à jour des données d’organisation](#53-mise-à-jour-des-données-dorganisation)
  - [5.4. RàZ et rechargement des variables dans SoftaPlay](#54-ràz-et-rechargement-des-variables-dans-softaplay)
  - [5.5. Traitement des incidents connus SoftaPlay](#55-traitement-des-incidents-connus-softaplay)
  - [5.6. Post-transfert : contrôles GL, ETAX, PA, AR/AP](#56-post-transfert--contrôles-gl-etax-pa-arap)
- [6. Bonnes pratiques SoftaPlay](#6-bonnes-pratiques-softaplay)
- [7. Annexes](#7-annexes)
  - [7.1. Exemples de requêtes SQL utiles](#71-exemples-de-requêtes-sql-utiles)
  - [7.2. Références des documents sources](#72-références-des-documents-sources)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document consolide les modes opératoires liés à **SoftaPlay** pour :

- La **création de sociétés complètes** dans Oracle FIN01.
- La **création de SVD** (sociétés / entités via Softa).
- Le **transfert de SVD** d’une région / organisation à une autre. fileciteturn0file11turn0file14  

Il fournit une vision structurée, orientée support et exploitation.

---

## 2. Principes généraux SoftaPlay

### 2.1. Rôle de SoftaPlay

SoftaPlay est utilisé pour :

- Industrialiser la **duplication** et la **création** de paramétrage Oracle (GL, FA, PA, AR/AP, etc.).
- Appliquer des **règles** prédéfinies à partir d’une **société de référence**.
- Créer automatiquement :
  - **Entités juridiques (LE)**.
  - **Livres (Ledgers)**.
  - **Unités opérationnelles (OU)**.
  - **Organisations d’inventaire (Inv Org)**.
  - Et une grande partie du paramétrage financier associé. fileciteturn0file11turn0file14  

---

### 2.2. Rôle de DataLoad

DataLoad intervient en complément pour :

- Charger ou mettre à jour des **jeux de valeurs**.
- Créer des **adresses** (lieux) et autres données structurées qui ne peuvent être gérées directement par SoftaPlay.
- Automatiser certaines mises à jour répétitives en écrans Oracle. fileciteturn0file11turn0file14  

---

## 3. Création de société complète (SoftaPlay)

### 3.1. Pré-requis fonctionnels et techniques

Avant de lancer une création de société :

- Disposer des informations du fichier **INITSOC – Oracle R12** :
  - Code société.
  - Raison sociale.
  - Projet Finance par UO.
  - Codes région, CF région, etc.
- Disposer des informations **TSA** (adresse, codes postaux).
- Disposer des accès :
  - SoftaPlay (projet de création société).
  - Oracle (responsabilités GL, PA, AR, AP, ETAX).
- Planifier une **fenêtre** de travail (création paramétrage).

fileciteturn0file11  

---

### 3.2. Préparation des fichiers de variables

Les fichiers de variables pour SoftaPlay contiennent :

- **Variables société** :
  - `Company Name` (raison sociale).
  - `Location Code` (nom du livre comptable / adresse).
  - `Code UO`.
  - `Inventory Org Num`.
  - `Share capital`, etc.
- **Références** vers la société de référence.

Points d’attention :

- `Inventory Org Num` doit être renseigné **en texte** (ex : `'346`), sinon SoftaPlay peut générer l’erreur *Organization already exists*. fileciteturn0file11turn0file14  

---

### 3.3. Chargement des variables dans SoftaPlay

1. Ouvrir le projet SoftaPlay (ex. `Création Société` ou `SVD Création`).
2. Supprimer les anciennes variables éventuelles (`Remove` société par société).
3. Charger le nouveau fichier de variables (icône **Excel Tool**).
4. Vérifier visuellement :
   - Les **Inventory Org Num**.
   - Les **codes société** et **région**.
   - Les noms de livres et entités juridiques. fileciteturn0file11turn0file14  

---

### 3.4. Exécution des phases SoftaPlay

Les phases principales :

1. **Extraction** depuis la société de référence :
   - Sélectionner tous les composants.
   - Cliquer sur **Extract**.
   - Contrôler le nombre d’occurrences extraites.

2. **Apply** (application des règles) :
   - Cliquer sur **Apply**.
   - Choisir la (ou les) société(s) cible(s).
   - Vérifier le résultat via **View Apply Result**.

3. **Mise à jour de la période FA** :
   - Dans `Book Controls`, renseigner `Initial Date` :
     - Si la clôture FA du mois est entamée → 1er jour du mois en cours.
     - Sinon → 1er jour du mois précédent.

4. **Deploy** :
   - Cochez les étapes jusqu’à `Inventory Org`.
   - Adapter `Stop when` (par ex. mettre `Error` pour `Security rules and assignments` pour éviter un blocage).
   - Cliquer sur **Deploy**.

5. **Load** :
   - Cliquer sur **Load** :
     - Colonne `Waiting` → nombre d’enregistrements à créer.
     - Colonnes `Chargé / Passé / Rejeté` → suivi de l’exécution.

fileciteturn0file11turn0file14  

---

### 3.5. Paramétrages et traitements manuels

Après SoftaPlay, des actions manuelles restent à faire :

- **Duplication des données système** :
  - Traitement `Dupliquer les données système` pour chaque UO.
- **Profils de sécurité** :
  - Ajout des UO dans les profils existants.
  - Création de nouveaux profils pour la société / la région.
  - Mis à jour des listes de sécurité (`Mise à jour des listes de sécurité`).
- **Clients pour PA** :
  - Création des sites pour `CLIENT_POUR_PA`.
  - Ajustement du lieu (remplacement de l’ID par un `.`).

fileciteturn0file11turn0file14  

---

### 3.6. Post-création : GL, ETAX, PA, AR/AP

Par module :

- **GL** :
  - Règles de validation croisées (BG-BL, CE-RG, CE-RL, GRP-FLUX, STE-REGION).
  - Segments d’équilibrage.
  - Jeux de livres `OPERATIONNEL` et `OPERATIONNEL + REFERENCE`.
  - Paramétrage des pièces répétitives (abonnements GL).

- **ETAX** :
  - Ajout du nouveau livre dans la **Configuration fiscale FR**.
  - Création / mise à jour des **profils fiscaux de partie** (type UO).
  - Vérifier que la case **« Utiliser l’abonnement de l’entité juridique »** est cochée.

- **PA** :
  - Modèles de projets (OPERATIONNEL, ORGANIQUE, REFAC).
  - Modèles de budgets (OPERATIONNEL, ORGANIQUE, REFAC).
  - Projet de REFAC (copie du modèle REFAC).

- **AR/AP** :
  - Paramétrage des comptes non soldés.
  - Comptes bancaires internes Dalkia.
  - Modes de règlement (VIREMENT, CHEQUE sur 51* et 585*).
  - Interfaces de règlements (intégration groupe AP/AR).

fileciteturn0file11turn0file14  

---

## 4. Création d’une SVD (Société / entité) via SoftaPlay

### 4.1. Préambule et pré-requis GL

La création de SVD est une déclinaison plus ciblée de la création de société, centrée sur une entité / région.

Pré-requis :

- Identification de la **nouvelle organisation logistique** (`Inventory Org Num`) :
  - Requête :

```sql
SELECT MAX(organization_code)
FROM   MTL_PARAMETERS_VIEW;
```

  - Incrémenter le résultat de 1 pour obtenir la nouvelle valeur.

- Préparation du fichier de création pour DataLoad :
  - Onglet `A créer` à renseigner.
  - Récupération de données depuis `INITSOC – Oracle R12`. fileciteturn0file14  

---

### 4.2. Jeux de valeurs GL à mettre à jour

Jeux de valeurs principaux :

- `DAOPCCF_STE` :
  - Codes de regroupement de la nouvelle société.
- `XDKA_ARGOS_INTERCO` :
  - Codes conso associés.
- `DAOPCCF_INTERCO` :
  - Codes InterCo (0423, DOS0423, XXX0423, etc.).
- `DAOPCCF_LOCAL` :
  - Comptes locaux (ex : comptes bancaires).
- `DAOPCCF_PROJETFI` :
  - Projets de REFAC et Projet Frais & Produits de Société (FPS).

Mise à jour des **règles de validation croisées** pour intégrer la nouvelle société / région (`STE-REGION`, `STE-PARTENAIRE`, etc.). fileciteturn0file14  

---

### 4.3. Désactivation des règles de validation croisées

Avant de lancer SoftaPlay :

- Désactiver temporairement les règles de validation croisées GL :

  - `BG-BL`
  - `CE-RG`
  - `CE-RL`
  - `GRP-FLUX`
  - `STE-REGION`

Objectif : éviter des **blocages** lors de la création des nouvelles combinaisons comptables. fileciteturn0file14  

---

### 4.4. Phase 1 SoftaPlay : LE, Ledger, OU, Inv Org

Étapes principales :

1. **Chargement des variables** (supprimer d’abord les anciennes).
2. **Mode déploiement** (`Monitor Project`).
3. **Extract** sur l’ensemble des composants.
4. **Apply** sur les sociétés cibles.
5. **Mise à jour de la période FA** (`Initial Date`).
6. **Deploy** jusqu’à `Inventory Org`.
7. **Load** pour exécuter les créations.

Contrôles :

- Colonne `Waiting` correctement alimentée.
- Colonnes `Loaded` / `Rejected` cohérentes.
- Les `Inventory Org Num` utilisés correspondent bien aux valeurs prévues. fileciteturn0file14  

---

### 4.5. Paramétrages manuels complémentaires

Après la phase 1 :

- **Dupliquer les données système** pour chaque nouvelle UO.
- **Profils de sécurité** :
  - Ajouter l’UO aux profils globaux (`DKA_TOUT`, `DKA_TOUT + REFERENCE`).
  - Créer les profils de sécurité spécifiques (par région / société).
  - Lancer `Mise à jour des listes de sécurité`.

- **Clients pour PA** :
  - Création des sites `CLIENT_POUR_PA` par UO.
  - Réglage du lieu avec un `.`.

- **Paramétrage compte bancaire interne** :
  - Création du compte bancaire interne.
  - Création du compte 585000 (trésorerie).
  - Paramétrage des titres de paiement et instructions de règlements.

fileciteturn0file14  

---

### 4.6. Phase 2 SoftaPlay et post-création

Phase 2 SoftaPlay :

- Réactivation temporaire de certains **types de dépense** (ex : `FORMATION PRLVTS VOLONTAIRES`).
- Décocher les étapes déjà réalisées (jusqu’à `Inventory Org`).
- `Deploy` et `Load` sur le reste des composants (options d’implémentation, etc.).

Post-création :

- **Réactivation** des règles de validation croisées GL.
- Traitements de mise à jour :
  - Options fournisseurs/bénéficiaires.
  - Attachement des CGA (conditions générales d’achat) aux UO.
  - Autoriser le livre pour la gestion des banques (User Management / CE UMX Security wizard).
- Mise à jour :
  - Segments d’équilibrage.
  - Taxe dans GL.
  - Abonnements GL.
  - Profils ETAX.
  - Paramétrage PA, AR, AP.

fileciteturn0file14  

---

## 5. Transfert d’une SVD

### 5.1. Recherche de l’ancienne UO (Org_id)

Le transfert de SVD suppose de manipuler des identifiants qui peuvent varier selon l’environnement (Recette / Production).

Requête type :

```sql
SELECT hou.name,
       mp.organization_code
FROM   MTL_PARAMETERS_VIEW     mp,
       HR_ORGANIZATION_UNITS_V hou
WHERE  hou.name LIKE '%0485'
AND    mp.organization_id = hou.organization_id;
```

La valeur `organization_code` est à renseigner dans la variable `Inventory Org Num` du fichier de déploiement. fileciteturn0file14  

---

### 5.2. Mise à jour des jeux de valeurs et tables de transco

En cas de **transfert de SVD** :

- Mettre à jour :

  - `XDKA_ARGOS_INTERCO` :
    - Modification des descriptions avec la nouvelle raison sociale.
    - Création de lignes si le code conso n’existe pas.

  - `DAOPCCF_STE` :
    - Mise à jour de la description (nouvelle raison sociale).
    - Mise à jour du **CUF Région principale**.
    - Repositionnement du code conso SVD sur la bonne région.

  - `DAOPCCF_INTERCO` :
    - Création du nouveau code UO pour la nouvelle région.
    - Mise à jour de la description pour `XXX<numéro de société>` et `<numéro de société>`.
    - Ajout de nouveaux enfants dans les fourchettes.

  - `DAOPCCF_LOCAL` :
    - Mise à jour de la raison sociale.

  - `DAOPCCF_PROJETFI` :
    - Création du nouveau code UO.
    - Mise à jour des descriptions des projets.

- **Tables de transco** :
  - `DKA_CONSO_VECTOR` :
    - Mise à jour du **code région** pour le code conso.
    - Création d’une nouvelle ligne si nécessaire.

fileciteturn0file14  

---

### 5.3. Mise à jour des données d’organisation

Points clés :

- **Adresses (PO / Lieux)** :
  - Mise à jour des noms de livres comptables (nouveau nom).
  - Mise à jour des descriptions avec la **nouvelle raison sociale**.
  - Mise à jour du CUF `Région`.

- **Nom du Ledger** :
  - Mise à jour dans la configuration comptable (livre principal et secondaire).
  - Préfixe `R_` pour le livre secondaire.

- **Entité juridique (XLE)** :
  - Mise à jour :
    - Nom d’entité juridique.
    - Nom d’établissement.
    - Nom enregistré.
    - Numéro de SIRET (cohérent avec INITSOC).

- **Code Operating Unit (AP / PO)** :
  - Mise à jour du nom d’organisation.
  - Mise à jour du code abrégé (Operating Unit Information).

fileciteturn0file14  

---

### 5.4. RàZ et rechargement des variables dans SoftaPlay

Dans SoftaPlay :

1. Rechercher à nouveau l’ID de l’ancienne UO (requête sur `organization_code`).
2. S’assurer que la colonne `Inventory Org Num` du fichier de déploiement correspond à l’ID de l’environnement.
3. Supprimer les anciennes variables (clic droit `Remove`).
4. Recharger le fichier de variables mis à jour (nouvelle raison sociale, code UO, CF région, etc.).
5. Lancer la phase 1 SoftaPlay (Extract / Apply / Deploy / Load) pour le transfert.

fileciteturn0file14  

---

### 5.5. Traitement des incidents connus SoftaPlay

Exemples d’incidents :

- **Too_many_rows** :
  - Souvent dû à un oubli de suppression de la société dans un ou plusieurs jeux de livres (`OPERATIONNEL`, `OPERATIONNEL + REFERENCE`, région d’origine).
- **Invalid expenditure type** lors de `Project Template` :
  - Réactiver temporairement le type de dépense concerné (ex : `FORMATION PRLVTS VOLONTAIRES`), relancer, puis remettre la date de fin.
- **Case « Utiliser l’abonnement de l’entité juridique » non cochée** :
  - Contrôler la table `ZX_PARTY_TAX_PROFILE`.
  - Lancer un `UPDATE` pour mettre `use_le_as_subscriber_flag = 'Y'` sur les UO concernées (après vérification).

fileciteturn0file14  

---

### 5.6. Post-transfert : contrôles GL, ETAX, PA, AR/AP

Après le transfert :

- **GL** :
  - Vérifier le segment d’équilibrage au niveau établissement.
  - Vérifier les jeux de livres (`OPERATIONNEL`, `OPERATIONNEL + REFERENCE`).
  - Mettre à jour `latest_opened_period_name` dans `GL_LEDGERS` si nécessaire.

- **ETAX** :
  - Ajouter le nouveau livre dans la configuration fiscale.
  - Créer / mettre à jour les profils fiscaux de partie pour l’UO.

- **PA** :
  - Vérifier le code AFFAIRE sur le modèle de projet organique.
  - Créer / mettre à jour les modèles d’accords cadre et de budgets.

- **AR/AP** :
  - Paramétrer les comptes non soldés.
  - Mettre à jour les modes de règlements et les interfaces de règlements.
  - Ouvrir les périodes pour tous les modules (GL, PA, AP, AR, PO, FA).

fileciteturn0file14  

---

## 6. Bonnes pratiques SoftaPlay

- Travailler sur une **société de référence** à jour et validée.
- Toujours :

  - Sauvegarder et archiver les **fichiers de variables**.
  - Lancer les traitements dans un **ordre contrôlé** (FA, GL, PA, etc.).
  - Maintenir une **check-list** par création / transfert.

- Bien documenter les **exceptions** (traitements manuels, SQL d’ajustement, etc.). fileciteturn0file11turn0file14  

---

## 7. Annexes

### 7.1. Exemples de requêtes SQL utiles

#### 7.1.1. Recherche de la dernière organisation logistique

```sql
SELECT MAX(organization_code)
FROM   MTL_PARAMETERS_VIEW;
```

#### 7.1.2. Recherche de l’Org_id d’une UO

```sql
SELECT hou.name,
       mp.organization_code
FROM   MTL_PARAMETERS_VIEW     mp,
       HR_ORGANIZATION_UNITS_V hou
WHERE  hou.name LIKE '%XXXX'
AND    mp.organization_id = hou.organization_id;
```

fileciteturn0file14  

---

### 7.2. Références des documents sources

- **Création de société complète – V2.0** fileciteturn0file11  
- **Création et transfert de SVD – V2.0** fileciteturn0file14  

---
