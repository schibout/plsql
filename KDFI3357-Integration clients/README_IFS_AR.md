# Interface client IFS ➜ Oracle Receivables (AR)

Dossier de spécifications générales de l’interface client entre l’application SIC/IFS et Oracle Receivables (AR).

---

## 1. Contexte et objectifs

L’application **SIC / IFS** est la base de référence des clients du groupe Dalkia.  
Le module **Oracle Receivables (AR)** gère la facturation client, le recouvrement et la comptabilité associée.

Les objectifs de l’interface sont :

- Assurer un **flux quotidien et pérenne** des clients entre SIC/IFS et Oracle AR.  
- Gérer :  
  - la **création** des clients et de leurs adresses,  
  - la **mise à jour** des données clients existants,  
  - la **duplication** des adresses/sites (par société et centre de gestion),  
  - la **gestion des relations payeur / destinataire**,  
  - la prise en compte des **fusions clients** (SIC ➜ AR).
- Mettre les données au **format attendu par Oracle AR** (clients, adresses, sites de facturation, profils, comptes comptables…).
- Centraliser les règles de gestion dans un package PL/SQL dédié.

---

## 2. Vue d’ensemble de la solution

### 2.1. Principe général

1. L’EAI remplace l’ancien ETL et importe les données SIC/IFS dans deux tables spécifiques Oracle :
   - `DKA_ICLIENTIFS_INTERFACE` (données clients et adresses),
   - `DKA_ICLIENTIFS_COLLECTORS` (chargés de recouvrement).
2. Un traitement en 3 phases gère l’interface :
   - **Pré Open Interface (Pre-OI)**  
     - Contrôles de cohérence,  
     - alimentation des tables d’open interface standard.
   - **Open Interface standard AR**  
     - Import ou mise à jour des clients/adresses/sites dans les tables standard AR.
   - **Post Open Interface (Post-OI)**  
     - Gestion payeur/destinataire,  
     - duplication des sites clients,  
     - purge des tables spécifiques.

### 2.2. Périmètre

- Seuls les **clients ayant le rôle “Payeur” ou “Destinataire”** sont interfacés.
- Les **clients individuels** ne sont pas interfacés dans AR comme codes partenaires (GL).
- L’interface porte sur :
  - clients (en-tête),
  - adresses,
  - sites de facturation (lieux, fonctions économiques),
  - profils clients,
  - chargés de recouvrement par centre de gestion,
  - informations de statut (activation / désactivation).

---

## 3. Flux fonctionnels

### 3.1. Création de nouveaux clients et adresses

- Création de tout **nouveau client** ou toute **nouvelle adresse** non encore existante dans AR.  
- Utilisation de l’**open interface client** AR à partir du fichier plat SIC/IFS.  
- Le centre de gestion initial est déterminé à partir du **chargé de recouvrement**.  
- Le client est ensuite **dupliqué** pour l’ensemble des sociétés rattachées au centre de gestion.

### 3.2. Mise à jour des clients et adresses

Sont mis à jour pour tous les couples société / centre de gestion concernés :

Champs modifiables (exemples) :
- Numéro intracom,
- Statut actif/inactif (en-tête et adresse),
- Classe de profil, catégorie,
- Adresse (lignes, ville, code postal, pays),
- Chargé de recouvrement et centre du chargé (par CDG),
- Client destinataire et adresse destinataire.

Champs non modifiables (exemples) :
- Nom du client,
- Numéro client,
- Type de client,
- Code partenaire.

### 3.3. Duplication des adresses / lieux de facturation

- **Automatique** (quotidienne) :
  - Analyse des fichiers plats de facturation.
  - Si une facture fait référence à une adresse client non définie pour le couple société / CDG, la **duplication** de cette adresse est réalisée dans AR.
- **Manuelle** (programme SPE025 – “DKA : Duplication manuelle d'un site client”) :
  - Utilisée pour la **facturation manuelle** lorsque le couple société / CDG n’existe pas encore.
  - Paramètres : client à dupliquer, site de référence, centre de gestion / société de destination.

### 3.4. Gestion des clients payeur / destinataire

- Seuls les **clients payeurs** et **destinataires** sont interfacés.
- Adresses payeur : fonction économique `BILL_TO` active (sites de facturation utilisables).
- Adresses uniquement destinataires :
  - fonction économique `BILL_TO`,
  - site de facturation **désactivé** (empêche la facturation manuelle mais n’empêche pas la relance).
- Les informations de relance (chargé de recouvrement…) sont portées par le **client payeur**, mais les courriers de relance sont envoyés au **client destinataire**.
- Un client peut être **à la fois payeur et destinataire** : dans ce cas, le site de facturation doit être **activé**.

### 3.5. Fusions des clients

- Gérées **manuellement** dans Oracle AR, société par société (unité opérationnelle).
- Deux types de fusion :
  - Fusion de sites de facturation d’un même client,
  - Fusion de deux clients (tous les sites de facturation sont rattachés au client fusionneur).
- Les sites fusionnés sont désactivés, toutes les données (factures, avoirs, règlements, ajustements) sont transférées.
- Les **balances** sont ajustées manuellement dans AX.

---

## 4. Architecture technique

### 4.1. Tables spécifiques

#### 4.1.1. `DKA_ICLIENTIFS_INTERFACE`

Table temporaire des données clients/adresses en provenance d’IFS, utilisée pour alimenter les open interfaces standard.

Principaux éléments :
- Identification client/adresse : `CUSTOMER_NAME`, `CUSTOMER_NUMBER`, `REF_ADDRESS`, `ADDRESS_STATUS`, `CUSTOMER_STATUS`, `CDG`, `SOC`.  
- Informations commerciales et fiscales : `INTRACOM_NUMBER`, `CUSTOMER_CATEGORY`, `CUSTOMER_CLASS`, `PARTNER_CODE`, `NUM_SIRET`, etc.  
- Gestion destinataire : `CODE_CLIENT_DESTINATAIRE`, `ADRESSE_CLIENT_DESTINATAIRE`, `RECIPIENT_ONLY_FLAG`.  
- Comptabilité : `GL_ID_REC`, `GL_ID_REV`, `PARTNER_CODE` pour le segment interco.  
- Statut interface : `OA_STATUS`, `OA_REQUEST_ID`, `ERROR_MESSAGE`.

Contraintes & index :  
- Unicité (par ex.) sur `REF_ADDRESS`, `CDG`, `SOC` pour éviter les doublons d’adresse par société / CDG.

#### 4.1.2. `DKA_ICLIENTIFS_COLLECTORS`

Table des **chargés de recouvrement** par client et centre de gestion.

Champs principaux :
- `CUSTOMER_NUMBER` (obligatoire),  
- `CDG`,  
- `COLLECTOR` (chargé de recouvrement),  
- `OA_STATUS`, `OA_REQUEST_ID`, `ERROR_MESSAGE`.

Utilisations :
- Alimentation de `HZ_CUSTOMER_PROFILES`.
- Détermination du **chargé de recouvrement** lors des duplications.

### 4.2. Table de paramètres `DKA_PARAMETERS`

Paramétrage générique pour éviter le “hard-coding” dans les programmes.

Exemples de paramètres :
- Comptes clients / produits avec ou sans code partenaire (`SEG3_CUST_PARTNER`, `SEG3_CUST`, `SEG3_REV_PARTNER`, `SEG3_REV`…),  
- Société et centre de gestion par défaut (`DEFAULT_SOCIETY`, `DEFAULT_CDG`),  
- Collecteur par défaut (`DEFAULT_COLLECTOR`),  
- Profil groupe, règles de regroupement, jeu de lettres de relance, etc.

Récupération via :  
`dka_tools_pkg.get_parameter(programme, paramètre, valeur_retour, statut, message)`.

### 4.3. Package PL/SQL `DKA_ICLIENTIFS_PKG`

Fonctions et procédures principales :

- `pre_oi` (Public)  
  - Contrôles et alimentation des tables d’open interface.
- `IN_OI` (Public)  
  - Lancement du traitement standard d’import des clients (par unité opérationnelle).
- `post_oi` (Public)  
  - Gestion payeur/destinataire, duplication des sites clients, purge des tables spécifiques.

Fonctions utilitaires (Public/Privées) :
- `address_exists`, `customer_exists`,  
- `get_collector_from_cust_cdg`,  
- `get_gl_id`,  
- `global_control`, `show_rejected_records`, etc.

### 4.4. Programmes concurrents Oracle Applications

Trois programmes simultanés principaux :

1. **DKA : Import des clients : Pre Open Interface**  
   - Exécutable : `DKA_ICLIENTIFS_1`  
   - Type : Procédure stockée PL/SQL  
   - Procédure : `dka_iclientifs_pkg.pre_oi`  
   - Rôle : Contrôles et alimentation des tables d’open interface.

2. **DKA: Import des clients OI**  
   - Exécutable : `DKA_ICLIENTIFS_3`  
   - Procédure : `dka_iclientifs_pkg.IN_OI`  
   - Rôle : Lancement de l’open interface standard AR (par unité opérationnelle).

3. **DKA: Import des clients post OI**  
   - Exécutable : `DKA_ICLIENTIFS_2`  
   - Procédure : `dka_iclientifs_pkg.post_oi`  
   - Rôle : Post-traitement spécifique DKA (liens payeur/destinataire, duplication, purge).

Jeu de traitement associé :  
- **DKA: Import des clients** (enchaînement Pre-OI ➜ OI ➜ Post-OI).

---

## 5. Règles de gestion clés (synthèse RG1–RG30)

Quelques règles essentielles :

- **RG1** : seuls les clients avec rôle **Payeur** ou **Destinataire** sont interfacés.  
- **RG2** : les profils et classes clients doivent exister au préalable dans AR (distinction GROUPE_INTERNE / GROUPE_EXTERNE).  
- **RG3 / RG13** : les chargés de recouvrement doivent exister dans AR, la table `DKA_ICLIENTIFS_COLLECTORS` est la référence.  
- **RG4** : numéros de client et d’adresse différents entre SIC et AR ; les numéros de lieu de facturation AR correspondent aux références d’adresse externes.  
- **RG9 & RG30** :  
  - La désactivation d’un client dans SIC se traduit par la désactivation de ses **adresses** dans AR, pas de l’en-tête client.  
  - Le champ `CUSTOMER_STATUS` inactif entraîne la désactivation des adresses (`ADDRESS_STATUS`) plutôt que du client complet.  
- **RG10 / RG22 / RG23** :  
  - La présence ou non d’un **code partenaire** impacte les combinaisons comptables (segment interco, comptes client/produit).  
  - Les codes partenaires sont de la forme région+société ou `XXX`+société.  
- **RG15** : un client doit obligatoirement être créé avec au moins **une adresse**.  
- **RG16 / RG17** : la duplication par société/CDG est pilotée par les centres de gestion des chargés de recouvrement et les fichiers plats des systèmes amont de facturation.  
- **RG18** : les fusions clients ne sont pas automatisées, elles sont gérées manuellement.  
- **RG21 / RG25–RG27** :  
  - Adresse destinataire utilisée pour déduire le code client destinataire, qui doit exister dans AR.  
  - Si les sites de facturation sont désactivés, l’open interface refuse la mise à jour : ils doivent être réactivés avant import, puis éventuellement désactivés en Post-OI.  
  - Les relations payeur/destinataire sont gérées en Pre-OI et mises à jour dans le panneau Oracle dédié.

---

## 6. Exploitation et supervision

### 6.1. Lancement des traitements

- Jeu de traitement : **DKA: Import des clients**.  
- Responsabilité typique : `TOUT_AR_ADMINISTRATEUR`.  
- La responsabilité de lancement doit être **AR sans Sécurité** pour ne pas bloquer les validations GL.

### 6.2. Périodicité

- Traitement **quotidien**.  
- L’analyse des fichiers plats de facturation est également quotidienne pour déterminer les duplications nécessaires.

### 6.3. Gestion des erreurs et rejets

- Les contrôles Pre-OI et l’open interface peuvent rejeter des lignes (erreurs fonctionnelles ou de paramétrage).  
- Un **état des rejets** est produit en fin de programme, les actions possibles sont :
  - Correction dans SIC/IFS puis réémission des données (et purge des lignes en erreur dans AR),  
  - Correction de paramétrage dans AR (les lignes restent et sont reprises au prochain lancement).  

Exemples d’erreurs :
- Libellés trop longs,  
- Catégories, classes, codes partenaires, sociétés ou centres de gestion inconnus dans AR,  
- Chargés de recouvrement inexistants.

---

## 7. Livrables et scripts

Les composants techniques livrés comprennent notamment :

- Scripts de définition des programmes concurrents et groupes (`DKA_ICLIENTIFS_1.prt`, `DKA_ICLIENTIFS_2.prt`, `DKA_ICLIENTIFS_3.prt`, `DKA_ICLIENTIFS.ldt`, etc.).  
- Scripts SQL de création de la table spécifique et du package (`DKA_ICLIENTIFS_INTERFACE.tab`, `DKA_ICLIENTIFS_COLLECTORS.tab`, `DKA_ICLIENTIFS_PKG.pks/pkb`).  
- Scripts d’installation et d’automatisation (Shell & SQL) pour le serveur d’intégration.

---

## 8. Historique des versions

Les principales évolutions du document couvrent :

- Création initiale de l’interface,  
- Révisions générales et évolutions fonctionnelles (duplication manuelle, DQM, passage en R12, enrichissement HELIOS),  
- Ajout des spécifications techniques et architecture,  
- Adaptations sur la duplication automatique des sites clients,  
- Dernière évolution : gestion du champ `CUSTOMER_STATUS` pour éviter la désactivation erronée de codes clients (désactivation ciblée des adresses).
