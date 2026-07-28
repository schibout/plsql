# Oracle – Outils utilisateurs (WebADI, PHENIX, Java)

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. WebADI – Lancement et utilisation](#2-webadi--lancement-et-utilisation)
  - [2.1. Pré-requis](#21-pré-requis)
  - [2.2. Lancement de WebADI depuis Oracle](#22-lancement-de-webadi-depuis-oracle)
  - [2.3. Génération et ouverture du modèle Excel](#23-génération-et-ouverture-du-modèle-excel)
  - [2.4. Saisie, validation et upload des données](#24-saisie-validation-et-upload-des-données)
- [3. Connexion à Oracle PHENIX 11i (Edge / IE Mode)](#3-connexion-à-oracle-phenix-11i-edge--ie-mode)
  - [3.1. Contexte et contraintes techniques](#31-contexte-et-contraintes-techniques)
  - [3.2. Utilisation d’Edge en mode Internet Explorer](#32-utilisation-dedge-en-mode-internet-explorer)
  - [3.3. Conseils en cas de problème de connexion](#33-conseils-en-cas-de-problème-de-connexion)
- [4. Java – Vider le cache pour Oracle Forms](#4-java--vider-le-cache-pour-oracle-forms)
  - [4.1. Pourquoi vider le cache Java ?](#41-pourquoi-vider-le-cache-java-)
  - [4.2. Étapes détaillées pour vider le cache](#42-étapes-détaillées-pour-vider-le-cache)
  - [4.3. Bonnes pratiques](#43-bonnes-pratiques)
- [5. Références](#5-références)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document regroupe des procédures **orientées utilisateurs** autour de trois outils mis en œuvre avec Oracle :

- **WebADI** : création / import de données via Excel.
- **Connexion PHENIX (Oracle 11i)** via Microsoft Edge en mode Internet Explorer.
- **Gestion du cache Java** pour le bon fonctionnement d’Oracle Forms. fileciteturn0file2turn0file5turn0file12  

---

## 2. WebADI – Lancement et utilisation

### 2.1. Pré-requis

- Poste utilisateur avec :
  - Microsoft **Excel** installé.
  - Les compléments WebADI autorisés (paramétrage interne).
- Accès Oracle avec une responsabilité permettant d’utiliser **WebADI** (ex. GL ou AP selon le type d’import).
- Droits réseau suffisants (accès aux URL Oracle). fileciteturn0file2  

---

### 2.2. Lancement de WebADI depuis Oracle

1. Se connecter à Oracle E-Business Suite.
2. Choisir la responsabilité adaptée (par ex. **GL** pour un import de journaux).
3. Accéder au menu **WebADI** ou au menu spécifique (ex. `Journaux via WebADI`, `Import AP via WebADI`).
4. Sélectionner :
   - Le **type d’intégrateur** (GL, AP, etc.).
   - Le **style de layout / document** (modèle de feuille Excel).
5. Valider pour déclencher la génération du modèle WebADI. fileciteturn0file2  

---

### 2.3. Génération et ouverture du modèle Excel

1. Oracle propose le téléchargement d’un fichier Excel **pré-paramétré** :
   - Une ligne = un enregistrement (journal, facture, etc.).
   - Des colonnes dédiées (date, compte, montant, description…).
2. Ouvrir le fichier dans **Excel** :
   - Accepter l’activation des **macros / compléments** si demandé.
3. Vérifier la présence des menus / rubans WebADI dans Excel (selon la configuration). fileciteturn0file2  

---

### 2.4. Saisie, validation et upload des données

1. **Saisir les données** dans les lignes du modèle :
   - Respecter les formats demandés (dates, montants).
   - Utiliser les listes de valeurs WebADI si disponibles.
2. Utiliser les fonctionnalités de **validation** (si disponibles) :
   - Pré-validation des comptes.
   - Contrôle des dates.
3. Une fois les lignes prêtes :
   - Lancer l’**upload** vers Oracle via le menu WebADI (ex. `Upload` / `Publish`).
   - Fournir les paramètres demandés (journal, période, etc.).
4. Contrôler le **compte-rendu** d’upload dans Oracle :
   - Vérifier le statut des demandes concurrentes.
   - Corriger les rejets si nécessaire (puis relancer l’upload). fileciteturn0file2  

---

## 3. Connexion à Oracle PHENIX 11i (Edge / IE Mode)

### 3.1. Contexte et contraintes techniques

Oracle PHENIX 11i utilise des **applets Java** et a été conçu initialement pour fonctionner avec **Internet Explorer**.

Du fait de la disparition d’IE, Microsoft Edge propose un **mode compatibilité Internet Explorer (IE Mode)** permettant :

- Le chargement des applets Java.
- L’utilisation des formulaires Oracle (Forms). fileciteturn0file5turn0file8  

---

### 3.2. Utilisation d’Edge en mode Internet Explorer

Étapes générales :

1. Ouvrir **Microsoft Edge**.
2. Accéder à l’URL de PHENIX (ou utiliser le favori **PHENIX**).
3. Dans Edge :
   - Ouvrir le menu (…).
   - Cliquer sur **« Recharger en mode Internet Explorer »**.
4. Attendre le rechargement de la page :
   - Les applets Java doivent alors se lancer.
   - Une fenêtre de sécurité Java peut s’ouvrir :
     - Cliquer sur **« Autoriser cette session »**.

En cas d’échec de chargement :

- Vérifier que le poste est autorisé à utiliser IE Mode (GPO, configuration IT).
- Vérifier la présence d’une version compatible de Java sur le poste. fileciteturn0file5turn0file8  

---

### 3.3. Conseils en cas de problème de connexion

- Effacer le cache de **Edge** (mais en général c’est surtout le cache Java qui pose problème).
- Vérifier les **proxy / filtrages réseau**.
- Si PHENIX ne se lance pas après passage en IE Mode :
  - Vérifier le **cache Java** (cf. section suivante).
  - Contacter le support poste de travail si le mode IE n’est pas disponible. fileciteturn0file5turn0file12turn0file8  

---

## 4. Java – Vider le cache pour Oracle Forms

### 4.1. Pourquoi vider le cache Java ?

L’applet Oracle Forms (PHENIX) s’appuie sur le **cache Java** du poste.

Avec le temps, ou après des changements de version, le cache peut contenir :

- Des fichiers obsolètes.
- Des fragments de téléchargements interrompus.

Effets possibles :

- Applets qui ne se chargent pas.
- Écrans Oracle qui restent blancs.
- Messages d’erreur Java.

Vider le cache Java permet souvent de **résoudre ces anomalies**. fileciteturn0file12  

---

### 4.2. Étapes détaillées pour vider le cache

1. Ouvrir le **Panneau de configuration Java** :
   - Via le menu Démarrer (Recherche `Java` → `Configurer Java`).
   - Ou via le Panneau de configuration Windows (icône Java).

2. Dans l’onglet **Général** :
   - Repérer la section **Fichiers Internet temporaires**.
   - Cliquer sur **« Paramètres… »**.

3. Dans la fenêtre qui s’ouvre :
   - Cliquer sur **« Supprimer les fichiers… »**.

4. Choisir les options :
   - Application et applets téléchargés.
   - Traces et fichiers journaux.
   - (Selon version Java, les libellés peuvent varier légèrement).

5. Valider la suppression :
   - Cliquer sur **OK**.
   - Attendre la fin de l’opération.

6. Fermer toutes les fenêtres Java, puis relancer la connexion à PHENIX (Edge en IE Mode). fileciteturn0file12turn0file5turn0file8  

---

### 4.3. Bonnes pratiques

- Vider le cache Java en priorité lorsque :
  - Un écran Oracle ne s’ouvre plus.
  - Des messages Java indiquent des conflits de versions.
- Éviter d’avoir plusieurs versions de Java actives sur le même poste, sauf si c’est géré par l’IT.
- Ne pas supprimer à la main les dossiers Java dans le système de fichiers sans validation de l’IT.

---

## 5. Références

- **Lancement de WebADI** fileciteturn0file2  
- **Procédure de connexion à Oracle PHENIX 11i** fileciteturn0file5turn0file8  
- **Vider son cache JAVA** fileciteturn0file12  

---
