# Oracle – Flux financiers (Virements & relevés bancaires)

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. Flux FIN01.VIREMENT – Virements fournisseurs EDF](#2-flux-fin01virement--virements-fournisseurs-edf)
  - [2.1. Contexte fonctionnel](#21-contexte-fonctionnel)
  - [2.2. Architecture du flux](#22-architecture-du-flux)
  - [2.3. Localisation des fichiers d’instance](#23-localisation-des-fichiers-dinstance)
  - [2.4. Lecture et analyse du fichier d’erreurs](#24-lecture-et-analyse-du-fichier-derreurs)
  - [2.5. Correction des erreurs et préparation du rerun](#25-correction-des-erreurs-et-préparation-du-rerun)
  - [2.6. Demande de rejouage du flux](#26-demande-de-rejouage-du-flux)
  - [2.7. Check-list d’investigation rapide](#27-check-list-dinvestigation-rapide)
- [3. Import de relevés bancaires à la demande (RB)](#3-import-de-relevés-bancaires-à-la-demande-rb)
  - [3.1. Contexte et responsabilisation](#31-contexte-et-responsabilisation)
  - [3.2. Préparation du fichier AFB120](#32-préparation-du-fichier-afb120)
  - [3.3. Copie du fichier sur le serveur](#33-copie-du-fichier-sur-le-serveur)
  - [3.4. Lancement du traitement d’import dans Oracle](#34-lancement-du-traitement-dimport-dans-oracle)
  - [3.5. Contrôles post-import](#35-contrôles-post-import)
  - [3.6. Gestion des erreurs et rejets](#36-gestion-des-erreurs-et-rejets)
- [4. Bonnes pratiques et points de vigilance](#4-bonnes-pratiques-et-points-de-vigilance)
  - [4.1. Organisation des dossiers et archives](#41-organisation-des-dossiers-et-archives)
  - [4.2. Traçabilité fonctionnelle et technique](#42-traçabilité-fonctionnelle-et-technique)
  - [4.3. Coordination avec la trésorerie et l’exploitation](#43-coordination-avec-la-trésorerie-et-lexploitation)
- [5. Annexes](#5-annexes)
  - [5.1. Exemple de chemin technique FIN01.VIREMENT](#51-exemple-de-chemin-technique-fin01virement)
  - [5.2. Exemple de commandes Unix](#52-exemple-de-commandes-unix)
  - [5.3. Références des documents sources](#53-références-des-documents-sources)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document regroupe les procédures opérationnelles relatives aux **flux financiers Oracle** dans le contexte Dalkia :

- Gestion des **virements fournisseurs EDF** via le flux `FIN01.VIREMENT`.
- **Import manuel de relevés bancaires** (AFB120) dans Oracle. fileciteturn0file4turn0file10  

Il est destiné :

- Aux équipes support applicatif Oracle.
- Aux exploitants en charge des relances de flux.
- Aux interlocuteurs financiers (trésorerie, comptabilité) impliqués dans les contrôles.

---

## 2. Flux FIN01.VIREMENT – Virements fournisseurs EDF

### 2.1. Contexte fonctionnel

Le flux `FIN01.VIREMENT` est utilisé pour le **traitement des virements fournisseurs**, notamment les virements **EDF**.

- Source : un système amont (par ex. outil de paiement / trésorerie) fournit un fichier de virements.
- Cible : Oracle E-Business Suite, qui intègre les virements et met à jour la comptabilité et les règlements fournisseurs.

En cas de problème (erreurs dans le fichier, incohérences, etc.), les virements peuvent être **rejetés** et recommuniqués sous forme de **fichier d’erreurs**. fileciteturn0file4  

---

### 2.2. Architecture du flux

Le flux s’exécute typiquement sous forme de **traitement batch** :

1. Réception d’un fichier d’entrée (généralement CSV) dans un répertoire d’instances.
2. Traitement par un moteur d’intégration / interface.
3. Production :
   - D’un **fichier d’erreurs** listant les enregistrements non intégrés.
   - D’un **compte-rendu** d’exécution (log technique / fonctionnel).

Les erreurs peuvent être liées à :

- La **structure** du fichier.
- Les **données** (RIB, montants, codes fournisseurs, etc.).
- Des incohérences avec des référentiels Oracle.

---

### 2.3. Localisation des fichiers d’instance

Les fichiers relatifs au flux `FIN01.VIREMENT` sont organisés par **instance** (batch) sur le serveur, dans des répertoires du type :

```text
/chemin/de/base/FIN01.VIREMENT/INSTANCES/<nom_instance>/<sous-répertoires>
```

Exemple (à adapter selon l’infra réelle) :

```text
/data/interf/FIN01.VIREMENT/INSTANCES/FIN01.VIREMENT_20250425_01/TARGET/
```

Dans le dossier `TARGET` se trouve notamment un :

- **Fichier CSV d’erreurs** listant les enregistrements KO, en général :
  - Une ligne = un virement.
  - Un indicateur d’erreur par ligne.
  - Parfois, le **numéro de ligne** de la source.

fileciteturn0file4  

---

### 2.4. Lecture et analyse du fichier d’erreurs

Étapes recommandées :

1. Se connecter sur le serveur (via SSH) avec un compte autorisé.
2. Se rendre dans le répertoire `TARGET` de l’instance concernée :

```bash
cd /data/interf/FIN01.VIREMENT/INSTANCES/FIN01.VIREMENT_YYYYMMDD_nn/TARGET
ls -ltr
```

3. Identifier le **fichier CSV d’erreurs**, par exemple :

```text
FIN01.VIREMENT_YYYYMMDD_nn_errors.csv
```

4. Le consulter :

```bash
more FIN01.VIREMENT_YYYYMMDD_nn_errors.csv
# ou
head -50 FIN01.VIREMENT_YYYYMMDD_nn_errors.csv
```

5. Pour chaque enregistrement en erreur :
   - Comprendre la **cause** :
     - Donnée manquante / incorrecte (RIB, IBAN, BIC, code fournisseur).
     - Format non conforme.
     - Conflit avec Oracle (fournisseur inexistant, facture déjà payée, etc.).
   - Noter les **numéros de ligne** ou identifiants métiers utiles pour les équipes fonctionnelles.

fileciteturn0file4  

---

### 2.5. Correction des erreurs et préparation du rerun

La correction se fait généralement **en coordination avec les équipes métiers** (trésorerie / comptabilité) :

1. **Transmettre la liste des erreurs** au métier :
   - Sous forme de fichier CSV annoté.
   - Ou sous forme de tableau (Excel) avec commentaires.

2. Demander les corrections :
   - Rectification des RIB / IBAN.
   - Correction des montants ou dates.
   - Validation que certains virements doivent être ignorés ou annulés.

3. Préparer un **nouveau fichier d’entrée** pour le rerun :
   - Soit en fournissant uniquement les lignes corrigées.
   - Soit en fournissant un fichier complet filtré (selon les règles du flux).

4. S’assurer que le fichier est **conforme** aux spécifications du flux :
   - Séparateur (`,` ou `;`).
   - Encodage (UTF-8, ISO-8859-1, etc.).
   - Format des dates et montants.

---

### 2.6. Demande de rejouage du flux

Le rerun du flux `FIN01.VIREMENT` est généralement opéré par :

- L’équipe d’exploitation.
- Ou une équipe d’intégration / middleware.

Pour lancer un rerun :

1. **Créer un ticket** auprès de l’exploitation (ou de l’équipe en charge du flux) avec :
   - L’**identifiant de l’instance** initiale (nom du dossier d’instance).
   - Le **fichier corrigé** à utiliser.
   - Le **contexte** (Production / Recette).
   - Un **résumé** des corrections apportées.

2. Joindre si possible :
   - Le fichier d’erreurs initial.
   - Le CR d’exécution.

3. Demander :
   - Soit un **rejeu complet**.
   - Soit un **rejeu partiel** (uniquement certains enregistrements), selon ce que permet le flux.

---

### 2.7. Check-list d’investigation rapide

Avant de demander un rerun :

- [ ] Vérifier le **chemin de l’instance** et la présence du fichier d’erreurs.
- [ ] Contrôler que le **fichier d’entrée d’origine** est archivé.
- [ ] S’assurer que le **fonctionnel** a bien validé les corrections à apporter.
- [ ] Vérifier le **format** du nouveau fichier à rejouer.
- [ ] S’assurer que les **référentiels Oracle** concernés (fournisseurs, banques, etc.) sont à jour.

fileciteturn0file4  

---

## 3. Import de relevés bancaires à la demande (RB)

### 3.1. Contexte et responsabilisation

Le processus décrit ici permet d’**importer des relevés bancaires** dans Oracle à la demande, en utilisant des fichiers au format **AFB120** ou assimilé.

- Le fichier source est fourni par la **trésorerie**.
- L’import dans Oracle permet :
  - La mise à jour des positions bancaires.
  - La réconciliation avec les écritures comptables.

fileciteturn0file10  

---

### 3.2. Préparation du fichier AFB120

1. Récupérer le fichier de relevé bancaire transmis par la trésorerie.
2. Vérifier :
   - Le **format** (AFB120 ou autre format attendu).
   - La **cohérence** :
     - Banque / compte.
     - Date de valeur / date d’opération.
     - Totaux.

3. Renommer le fichier selon la convention attendue par l’interface, par exemple :

```text
AFB120.txt
```

(Le nom exact est à adapter à la convention en place, voir le document détaillé d’import RB.) fileciteturn0file10  

---

### 3.3. Copie du fichier sur le serveur

1. Se connecter au serveur Oracle (Unix / Linux) avec un compte ayant accès au répertoire d’entrée des relevés.

2. Copier le fichier :

```bash
scp AFB120.txt <user>@<serveur>:/chemin/dentree/releves/
```

3. Sur le serveur, vérifier la présence du fichier :

```bash
cd /chemin/dentree/releves/
ls -ltr AFB120.txt
```

4. Si nécessaire, ajuster les droits :

```bash
chmod 664 AFB120.txt
```

Cela garantit que l’utilisateur / le process Oracle peut lire le fichier. fileciteturn0file10  

---

### 3.4. Lancement du traitement d’import dans Oracle

Dans Oracle E-Business Suite :

1. Se connecter avec une responsabilité permettant de lancer l’import des relevés (par ex. **Administration Exploitation Dalkia** ou une responsabilité bancaire dédiée).

2. Aller dans le menu :

> **Autres / Lancer**  
> ou  
> **Traitements / Lancer un traitement**

3. Sélectionner le traitement correspondant, par exemple :

> **RB – Import des relevés bancaires**

4. Renseigner les **paramètres** :
   - Banque / compte.
   - Période / date du relevé.
   - Nom du fichier `AFB120.txt` (ou identifiant associé).

5. Soumettre le traitement.

6. Noter le **Request ID** (identifiant de demande concurrente) pour le suivi. fileciteturn0file10  

---

### 3.5. Contrôles post-import

Après l’exécution du traitement :

1. Consulter le **compte-rendu** du traitement via l’écran de suivi des traitements :

   - Vérifier le **statut** : doit être **Terminé – Normal**.
   - Vérifier les **compteurs** :
     - Nombre de lignes lues.
     - Nombre de lignes intégrées.
     - Nombre de lignes en erreur.

2. En cas de statut autre que *Normal* ou si des erreurs sont signalées :

   - Ouvrir le **log** et le **output** du traitement.
   - Identifier la ou les **causes** (format, données, référence bancaire manquante, etc.).

3. Fonctionnellement, demander à la trésorerie ou au service concerné de :

   - Vérifier les relevés dans Oracle.
   - Contrôler les soldes / écritures.

fileciteturn0file10  

---

### 3.6. Gestion des erreurs et rejets

En cas d’erreurs pendant l’import :

1. Analyser le log pour repérer :
   - La **ligne du fichier** posant problème.
   - Le **motif** :
     - Format de montant incorrect.
     - Code opération non reconnu.
     - Référence de compte inconnue, etc.

2. En fonction de la cause :

   - **Correction manuelle** dans Oracle :
     - Si l’erreur ne bloque pas l’ensemble du relevé.
   - **Correction du fichier source** :
     - En coordination avec la trésorerie.
     - Puis nouveau traitement d’import.

3. Documenter les actions dans le ticket de suivi :

   - Date / heure de l’import.
   - Statut (OK / KO).
   - Corrections effectuées.
   - Décision métier (rejouer / abandonner certaines lignes).

fileciteturn0file10  

---

## 4. Bonnes pratiques et points de vigilance

### 4.1. Organisation des dossiers et archives

- Conserver :
  - Les fichiers d’entrée.
  - Les fichiers d’erreurs.
  - Les fichiers retravaillés pour rerun.
- Structurer les répertoires par :
  - Date (`YYYYMMDD`).
  - Type de flux (`FIN01.VIREMENT`, `RB`).
  - Instance / numéro de run.

Cela facilite les analyses ultérieures et les audits.

---

### 4.2. Traçabilité fonctionnelle et technique

- Documenter systématiquement dans les tickets :
  - Les **chemins** des fichiers traités.
  - Les **Request ID** Oracle des traitements.
  - Les **résumés fonctionnels** (nombre de virements / relevés concernés).
- Garder une trace des :
  - Décisions métiers (acceptation / rejet d’écritures).
  - Corrections ponctuelles effectuées dans Oracle.

---

### 4.3. Coordination avec la trésorerie et l’exploitation

- Établir un **canal de communication clair** :
  - Qui fournit les fichiers (trésorerie) ?
  - Qui les copie sur le serveur ?
  - Qui lance les traitements ?
  - Qui valide fonctionnellement les résultats ?
- En cas de rerun d’un flux de paiement (comme **FIN01.VIREMENT**) :
  - S’assurer que la trésorerie a bien identifié les virements à rejouer.
  - Éviter les **doublons** (virements rejoués deux fois).

---

## 5. Annexes

### 5.1. Exemple de chemin technique FIN01.VIREMENT

```text
/data/interf/FIN01.VIREMENT/INSTANCES/FIN01.VIREMENT_20250425_01/SOURCE/
  -> Fichier d’entrée initial

/data/interf/FIN01.VIREMENT/INSTANCES/FIN01.VIREMENT_20250425_01/TARGET/
  -> Fichier d’erreurs CSV
  -> CR technique
```

(Arborescence indicative, à adapter selon l’environnement réel.) fileciteturn0file4  

---

### 5.2. Exemple de commandes Unix

```bash
# Lister les instances les plus récentes
cd /data/interf/FIN01.VIREMENT/INSTANCES
ls -ltr

# Aller dans le dossier TARGET d’une instance
cd FIN01.VIREMENT_20250425_01/TARGET
ls -ltr

# Visualiser les premières lignes d’un CSV d’erreurs
head -50 FIN01.VIREMENT_20250425_01_errors.csv
```

Pour les relevés bancaires :

```bash
# Vérifier la présence du fichier AFB120
cd /chemin/dentree/releves
ls -ltr AFB120.txt

# Modifier les droits si nécessaire
chmod 664 AFB120.txt
```

fileciteturn0file4turn0file10  

---

### 5.3. Références des documents sources

- **Notes VIREMENTS Fournisseurs – Rattrapage du 25 avril 2025** fileciteturn0file4  
- **RB – Import de relevés bancaires à la demande v1.0** fileciteturn0file10  

---
