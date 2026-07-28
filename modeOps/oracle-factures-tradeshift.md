# Oracle – Factures TradeShift (rattrapage et supervision)

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. Vue d’ensemble du flux TradeShift → Oracle](#2-vue-densemble-du-flux-tradeshift--oracle)
  - [2.1. Acteurs du flux](#21-acteurs-du-flux)
  - [2.2. Chaîne de traitement simplifiée](#22-chaîne-de-traitement-simplifiée)
- [3. Typologie des incidents TradeShift](#3-typologie-des-incidents-tradeshift)
  - [3.1. Incidents côté TradeShift](#31-incidents-côté-tradeshift)
  - [3.2. Incidents côté Xerox / middleware](#32-incidents-côté-xerox--middleware)
  - [3.3. Incidents côté Oracle](#33-incidents-côté-oracle)
- [4. Procédure de rattrapage d’une facture TradeShift](#4-procédure-de-rattrapage-dune-facture-tradeshift)
  - [4.1. Identification de la facture et collecte des informations](#41-identification-de-la-facture-et-collecte-des-informations)
  - [4.2. Vérifications préalables dans Oracle](#42-vérifications-préalables-dans-oracle)
  - [4.3. Relance / rattrapage via le flux](#43-relance--rattrapage-via-le-flux)
  - [4.4. Intégration manuelle exceptionnelle](#44-intégration-manuelle-exceptionnelle)
- [5. Contrôles post-rattrapage](#5-contrôles-post-rattrapage)
- [6. Bonnes pratiques et recommandations](#6-bonnes-pratiques-et-recommandations)
- [7. Annexes](#7-annexes)
  - [7.1. Exemples de critères de recherche dans Oracle](#71-exemples-de-critères-de-recherche-dans-oracle)
  - [7.2. Références des documents sources](#72-références-des-documents-sources)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document décrit les règles et les étapes de **rattrapage de l’intégration des factures TradeShift** dans Oracle, ainsi que les contrôles à effectuer avant et après le rattrapage. fileciteturn0file6  

Il couvre :

- Les principaux acteurs du flux (TradeShift, Xerox, Oracle).
- Les types d’incidents rencontrés.
- Les étapes de rattrapage et de contrôle.
- Les bonnes pratiques de coordination entre équipes.

---

## 2. Vue d’ensemble du flux TradeShift → Oracle

### 2.1. Acteurs du flux

Le flux de factures fournisseurs implique généralement :

- **TradeShift**  
  Plateforme de dématérialisation et de réception des factures fournisseurs.

- **Xerox** / outil de dématérialisation intermédiaire  
  Gestion de la numérisation, OCR et mise au format intermédiaire.

- **Oracle E-Business Suite**  
  Intégration des factures dans les modules **AP** (comptes fournisseurs) et/ou éventuellement dans le référentiel achats.

- **Outils de supervision internes**  
  Pour le suivi des statuts de traitement, des erreurs et des rejets. fileciteturn0file6  

---

### 2.2. Chaîne de traitement simplifiée

1. Le fournisseur envoie sa facture via **TradeShift**.
2. TradeShift met la facture à disposition dans un format standardisé.
3. La facture est traitée par la chaîne d’intégration (Xerox / middleware) et transmise vers Oracle.
4. Oracle tente de créer :
   - Une **facture fournisseur**.
   - Des **lignes** associées (dépense, imputation, TVA, etc.).
5. En cas d’erreur, la facture se retrouve :
   - En **erreur** dans un journal d’interface.
   - Ou rejetée dans une file dédiée.

Le rattrapage consiste à **réduire / corriger ces erreurs** pour assurer l’intégration correcte de la facture. fileciteturn0file6  

---

## 3. Typologie des incidents TradeShift

### 3.1. Incidents côté TradeShift

Exemples d’incidents en amont :

- Facture **non transmise** à la chaîne d’intégration (statut bloqué côté TradeShift).
- Métadonnées **incomplètes** :
  - Absence de code fournisseur.
  - Absence de numéro de commande.
- Duplicats détectés par TradeShift.

Dans ces cas, il faut généralement :

- Vérifier le **statut** de la facture dans TradeShift.
- Contacter le support TradeShift ou le fournisseur pour correction. fileciteturn0file6  

---

### 3.2. Incidents côté Xerox / middleware

Les problèmes peuvent inclure :

- Format de fichier incorrect.
- Erreurs de mapping entre les champs TradeShift et la structure attendue par Oracle.
- Problèmes techniques (job planté, serveur indisponible, etc.).

Le support technique **Xerox / middleware** est alors sollicité pour :

- Relancer le job.
- Corriger les mappings si nécessaire.
- Rejouer la facture. fileciteturn0file6  

---

### 3.3. Incidents côté Oracle

Côté EBS, les incidents les plus fréquents concernent :

- **Fournisseur inconnu** ou non paramétré.
- **Commande d’achat introuvable** ou clôturée.
- Problèmes de **TVA** / règles ETAX.
- Imputations comptables invalides.

Ils sont visibles :

- Dans les **interfaces AP**.
- Dans les **rapports de rejet** d’import de factures.
- Dans des **tables d’interface** spécifiques (selon le design local). fileciteturn0file6  

---

## 4. Procédure de rattrapage d’une facture TradeShift

### 4.1. Identification de la facture et collecte des informations

1. Récupérer l’identifiant de la facture dans le ticket :
   - Numéro de facture fournisseur.
   - Fournisseur.
   - Montant TTC.
   - Date de facture.

2. Identifier si la facture est **attendue** :
   - Existe-t-il une commande d’achat associée ?
   - La facture a-t-elle déjà été intégrée (risque de doublon) ?

3. Vérifier le **statut** dans :
   - TradeShift.
   - Eventuellement dans l’outil Xerox / pipeline.
   - Oracle (AP / écran de recherche de facture). fileciteturn0file6  

---

### 4.2. Vérifications préalables dans Oracle

Avant toute action de rattrapage :

1. Rechercher la facture dans Oracle AP (factures fournisseurs) par :

   - `Numéro de facture`.
   - `Fournisseur`.
   - `Montant`.
   - `Date`.

2. Si la facture **est déjà présente** et validée :
   - Mettre à jour le ticket en indiquant qu’aucune action de rattrapage n’est nécessaire.
   - Eventuellement informer le métier.

3. Si la facture n’est **pas présente** :

   - Vérifier les **fournisseurs** : le fournisseur est-il bien paramétré ?
   - Vérifier les **commandes d’achat** :
     - Numéro correct.
     - Commande non clôturée / annulée.
   - Vérifier les **règles de TVA** pour le type de facture concerné.

fileciteturn0file6  

---

### 4.3. Relance / rattrapage via le flux

Lorsque les prérequis sont satisfaits :

1. Demander au support **TradeShift / Xerox** :
   - De vérifier l’état de la facture dans leur système.
   - De procéder à une **relance du flux** vers Oracle si nécessaire.

2. Fournir dans la demande :
   - Identifiants de la facture.
   - Informations sur l’environnement (Recette / Production).
   - Résumé des contrôles effectués côté Oracle.

3. Suivre l’exécution :
   - Attendre la confirmation de la relance.
   - Contrôler à nouveau la présence de la facture dans Oracle AP.

fileciteturn0file6  

---

### 4.4. Intégration manuelle exceptionnelle

En dernier recours, si :

- La facture ne peut pas être rejouée automatiquement.
- Les métiers valident une **intégration manuelle**.

Alors :

1. Créer la facture directement dans Oracle AP, en respectant :
   - Le fournisseur.
   - La commande d’achat.
   - Les montants HT / TVA / TTC.
   - Les centres de coûts / imputations.

2. Documenter l’opération dans le ticket :

   - Motif du recours au manuel.
   - Références de la facture créée (numéro interne Oracle).

3. Informer la trésorerie / comptabilité si nécessaire.

fileciteturn0file6  

---

## 5. Contrôles post-rattrapage

Après rattrapage (automatique ou manuel) :

- Vérifier dans Oracle :

  - Que la facture apparaît bien avec le bon **statut** (Validée / Approuvée / En attente).
  - Que les **montants** sont corrects.
  - Que la **TVA** et les imputations sont cohérentes.

- Vérifier côté flux :

  - Qu’il n’y a pas de nouvelle erreur liée à la même facture.
  - Que la facture n’est plus en file d’attente d’erreurs.

- Mettre à jour le ticket :

  - Date et heure du rattrapage.
  - Mode de rattrapage (flux / manuel).
  - Résultats des contrôles.

fileciteturn0file6  

---

## 6. Bonnes pratiques et recommandations

- Toujours **vérifier la présence** de la facture dans Oracle avant de demander un rerun.
- Limiter le nombre de **manipulations manuelles** :
  - Préférer le rerun fluide via le flux.
- Maintenir une **communication claire** avec :
  - Le métier (comptabilité fournisseurs).
  - Le support TradeShift / Xerox.
- Consolider les incidents **répétitifs** pour identifier les causes racines :
  - Mappings incorrects.
  - Paramétrages insuffisants dans Oracle.

fileciteturn0file6  

---

## 7. Annexes

### 7.1. Exemples de critères de recherche dans Oracle

- Recherche facture :

  - Par `Numéro de facture fournisseur`.
  - Par `Fournisseur`.
  - Par `Montant`.
  - Par `Date de facture`.

- Recherche dans les interfaces (selon design local) :

  - Par identifiant externe (TradeShift / Xerox).
  - Par statut d’interface.

fileciteturn0file6  

---

### 7.2. Références des documents sources

- **Rattrapage de l’intégration des factures TradeShift** fileciteturn0file6  

---
