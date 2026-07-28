# Communication – OASIS & Météo des services

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. Communication OASIS en cas de dégradation ou d’arrêt de service](#2-communication-oasis-en-cas-de-dégradation-ou-darrêt-de-service)
  - [2.1. Types d’événements à communiquer](#21-types-dévénements-à-communiquer)
  - [2.2. Rôles et responsabilités](#22-rôles-et-responsabilités)
  - [2.3. Processus de communication dans OASIS](#23-processus-de-communication-dans-oasis)
  - [2.4. Modèle de message OASIS](#24-modèle-de-message-oasis)
- [3. Météo des services – Guide utilisateur](#3-météo-des-services--guide-utilisateur)
  - [3.1. Objectif de l’outil](#31-objectif-de-loutil)
  - [3.2. Accès à la Météo des services](#32-accès-à-la-météo-des-services)
  - [3.3. Lecture des statuts de service](#33-lecture-des-statuts-de-service)
  - [3.4. Consultation du détail d’un service](#34-consultation-du-détail-dun-service)
- [4. Bonnes pratiques de communication](#4-bonnes-pratiques-de-communication)
- [5. Références](#5-références)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document décrit :

- Comment utiliser **OASIS** pour communiquer sur une **dégradation** ou un **arrêt de service** (ex. Oracle FIN01, PHENIX, TradeShift).
- Comment utiliser l’outil **Météo des services** pour :
  - Suivre l’état des services.
  - Informer les utilisateurs. fileciteturn0file7turn0file13  

---

## 2. Communication OASIS en cas de dégradation ou d’arrêt de service

### 2.1. Types d’événements à communiquer

Les communications sont pertinentes notamment pour :

- **Arrêt complet** d’un service :
  - Oracle FIN01 indisponible.
  - PHENIX inaccessible.
- **Dégradation importante** :
  - Temps de réponse très dégradés.
  - Fonction clé indisponible (ex. validation de factures).
- **Maintenance planifiée** :
  - Interruption prévue (mise à jour, patch).

fileciteturn0file7  

---

### 2.2. Rôles et responsabilités

- **Équipe support / exploitation** :
  - Détecte l’incident.
  - Évalue l’impact.
  - Propose le message à diffuser.

- **Incident manager / Pilote de crise** (le cas échéant) :
  - Valide le contenu du message.
  - Décide de la fréquence des mises à jour.

- **Utilisateurs finaux** :
  - S’informent via OASIS et la Météo des services.
  - Ajustent leurs activités en fonction des informations. fileciteturn0file7turn0file13  

---

### 2.3. Processus de communication dans OASIS

1. **Identification de l’incident** :
   - Ouverture d’un ticket dans OASIS (incident, demande majeure…).
2. **Rédaction du message** :
   - Description claire de l’impact.
   - Identification du service concerné.
   - Indication de la portée (tous utilisateurs, région, etc.).
3. **Diffusion** :
   - Utilisation de la fonction de communication / news OASIS.
   - Lien éventuel vers le ticket d’incident.
4. **Mises à jour régulières** :
   - En fonction de l’avancement :
     - En cours d’analyse.
     - Correctif en cours de déploiement.
     - Retour à la normale.
5. **Clôture** :
   - Mise à jour finale de la communication.
   - Archivage / post-mortem éventuel. fileciteturn0file7  

---

### 2.4. Modèle de message OASIS

Exemple de structure de message :

> **Objet** : [Incident] Dégradation du service Oracle FIN01  
>   
> **Service impacté** : Oracle FIN01  
> **Date / heure de début** : JJ/MM/AAAA HH:MM  
> **Impact utilisateur** :  
> - Connexion impossible / lente.  
> - [Détails supplémentaires]  
>   
> **Actions en cours** :  
> - Analyse par l’équipe exploitation / éditeur.  
>   
> **Prochaine mise à jour** :  
> - HH:MM ou « dès qu’un nouvel élément sera disponible ».  
>   
> **Contact** :  
> - [Équipe / Groupe OASIS]  

fileciteturn0file7  

---

## 3. Météo des services – Guide utilisateur

### 3.1. Objectif de l’outil

L’outil **Météo des services** permet :

- De visualiser rapidement l’**état global** des services SI.
- D’informer les utilisateurs sur :
  - Les indisponibilités.
  - Les dégradations.
  - Les maintenances planifiées.

fileciteturn0file13  

---

### 3.2. Accès à la Météo des services

L’accès se fait généralement via :

- Un **lien intranet**.
- Un lien depuis OASIS / un portail SI.

Une fois connecté :

- L’utilisateur voit une **liste de services** regroupés par domaine (Finance, RH, etc.). fileciteturn0file13  

---

### 3.3. Lecture des statuts de service

Les services sont souvent représentés avec un code couleur :

- **Vert** : fonctionnement normal.
- **Orange** : dégradation partielle.
- **Rouge** : indisponible.
- **Bleu / Gris** : maintenance planifiée ou statut inconnu.

Pour chaque service :

- Un **libellé** explicite (ex. Oracle FIN01, PHENIX, TradeShift).
- Un **statut** actuel.
- Parfois, un lien vers plus de détail (fenêtre / popup). fileciteturn0file13  

---

### 3.4. Consultation du détail d’un service

En cliquant sur un service :

- Affichage d’une fiche détaillée contenant :
  - Description du service.
  - Statut courant.
  - Historique des incidents récents.
  - Éventuelles maintenances planifiées.
- Ce détail complète les communications diffusées via **OASIS**.

fileciteturn0file13turn0file7  

---

## 4. Bonnes pratiques de communication

- **Coherence** entre OASIS et Météo des services :
  - Les deux doivent raconter la même histoire.
- **Clarté** :
  - Utiliser un vocabulaire compréhensible par les métiers.
  - Éviter les acronymes techniques non expliqués.
- **Régularité** :
  - Ne pas laisser un incident « silencieux » trop longtemps.
- **Transparence maîtrisée** :
  - Indiquer l’impact réel.
  - Éviter de communiquer des détails techniques inutiles.

fileciteturn0file7turn0file13  

---

## 5. Références

- **Oasis – Communication pour dégradation ou arrêt de service** fileciteturn0file7  
- **Météo des services – Guide Utilisateur V2** fileciteturn0file13  

---
