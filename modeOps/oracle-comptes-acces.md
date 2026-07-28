# Oracle – Gestion des comptes & accès

<!-- TOC -->
- [1. Objet et périmètre](#1-objet-et-périmètre)
- [2. Vue d’ensemble des types d’accès Oracle](#2-vue-densemble-des-types-daccès-oracle)
  - [2.1. Types de connexion (profil Oracle)](#21-types-de-connexion-profil-oracle)
  - [2.2. Flux SSO / AD / ISIM (rappel)](#22-flux-sso--ad--isim-rappel)
- [3. Réinitialisation du mot de passe Oracle (SSL) pour les internes](#3-réinitialisation-du-mot-de-passe-oracle-ssl-pour-les-internes)
  - [3.1. Pré-requis](#31-pré-requis)
  - [3.2. Étapes détaillées](#32-étapes-détaillées)
  - [3.3. Modèle de réponse dans le ticket](#33-modèle-de-réponse-dans-le-ticket)
- [4. Déblocage / réactivation / synchronisation d’un compte Oracle en SSO](#4-déblocage--réactivation--synchronisation-dun-compte-oracle-en-sso)
  - [4.1. Vérifier le compte dans FND_USER](#41-vérifier-le-compte-dans-fnd_user)
  - [4.2. Gestion des comptes inactifs](#42-gestion-des-comptes-inactifs)
  - [4.3. Réactivation et mise à jour de l’option de profil](#43-réactivation-et-mise-à-jour-de-loption-de-profil)
  - [4.4. Ticket JIRA AD – Extension Attribute1 (synchronisation SSO)](#44-ticket-jira-ad--extension-attribute1-synchronisation-sso)
  - [4.5. Demande de synchronisation ISIM via OASIS](#45-demande-de-synchronisation-isim-via-oasis)
  - [4.6. Mail à ISIM / suivi](#46-mail-à-isim--suivi)
  - [4.7. Information de l’utilisateur et test de connexion](#47-information-de-lutilisateur-et-test-de-connexion)
  - [4.8. Check-list rapide d’investigation](#48-check-list-rapide-dinvestigation)
- [5. Mise à jour des mots de passe sur PHENIX (Oracle 11i)](#5-mise-à-jour-des-mots-de-passe-sur-phenix-oracle-11i)
  - [5.1. Connexion à PHENIX en mode Internet Explorer](#51-connexion-à-phenix-en-mode-internet-explorer)
  - [5.2. Accès à la responsabilité d’administration](#52-accès-à-la-responsabilité-dadministration)
  - [5.3. Ouverture de la console Java et navigation vers les utilisateurs](#53-ouverture-de-la-console-java-et-navigation-vers-les-utilisateurs)
  - [5.4. Recherche de l’utilisateur](#54-recherche-de-lutilisateur)
  - [5.5. Saisie du mot de passe temporaire](#55-saisie-du-mot-de-passe-temporaire)
  - [5.6. Sauvegarde et contrôle](#56-sauvegarde-et-contrôle)
  - [5.7. Mail à l’utilisateur](#57-mail-à-lutilisateur)
- [6. Bonnes pratiques de gestion des comptes et mots de passe](#6-bonnes-pratiques-de-gestion-des-comptes-et-mots-de-passe)
  - [6.1. Conventions sur les mots de passe temporaires](#61-conventions-sur-les-mots-de-passe-temporaires)
  - [6.2. Sécurité et confidentialité](#62-sécurité-et-confidentialité)
  - [6.3. Traces et audit](#63-traces-et-audit)
- [7. Annexes](#7-annexes)
  - [7.1. Requêtes SQL utiles](#71-requêtes-sql-utiles)
  - [7.2. Modèles d’e-mails](#72-modèles-de-mails)
  - [7.3. Références des documents sources](#73-références-des-documents-sources)
<!-- /TOC -->

---

## 1. Objet et périmètre

Ce document décrit de manière détaillée les procédures de **gestion des comptes et des accès Oracle** dans le contexte Dalkia :

- Réinitialisation de mot de passe Oracle pour les internes en connexion SSL.
- Déblocage, réactivation et synchronisation des comptes Oracle utilisés en **SSO** (via AD / ISIM).
- Mise à jour des mots de passe sur **PHENIX (Oracle 11i)** via la responsabilité d’administration. fileciteturn0file0turn0file1turn0file8  

---

## 2. Vue d’ensemble des types d’accès Oracle

### 2.1. Types de connexion (profil Oracle)

Dans Oracle E-Business Suite, le type de connexion de l’utilisateur est piloté par une option de profil, généralement libellée (ou contenant) :

> **« Connexion unique aux applications – Types de connexion »**

Les valeurs typiques sont :

- **Locale**  
  → Authentification gérée directement par Oracle (mot de passe stocké dans FND_USER).

- **SSO / Distante**  
  → Authentification confiée au SSO (Active Directory / ISIM).

- **Les deux**  
  → L’utilisateur peut se connecter en SSO et en mode local (pratique pour les cas de secours ou d’investigation). fileciteturn0file1  

En pratique, pour résoudre des incidents de connexion, on utilise souvent :

- **« Les deux »** ou **« Locale »** le temps du diagnostic et/ou de la bascule.

---

### 2.2. Flux SSO / AD / ISIM (rappel)

Pour les utilisateurs SSO :

1. Le compte est créé dans **Oracle** (table **FND_USER**).
2. Le compte **AD** contient des attributs (extensionAttribute1, matricule, etc.) utilisés pour le mapping.
3. **ISIM** se charge de synchroniser les identités entre AD et Oracle.
4. L’option de profil de type de connexion doit être compatible avec le mode choisi (SSO, Locale, Les deux). fileciteturn0file1  

---

## 3. Réinitialisation du mot de passe Oracle (SSL) pour les internes

Cette procédure couvre le cas où un **interne** ne parvient plus à se connecter à Oracle via la connexion SSL / locale, et nécessite une **réinitialisation de mot de passe**. fileciteturn0file0  

### 3.1. Pré-requis

- Disposer du **matricule** de l’utilisateur.
- Disposer d’une responsabilité / d’un profil avec les droits de :
  - Modifier les **options de profil** de l’utilisateur.
  - Modifier son **mot de passe** (accès à l’écran de gestion des utilisateurs).
- Accéder à l’outil de ticketing (OASIS, JIRA…) pour :
  - Consulter la demande.
  - Répondre à l’utilisateur avec le mot de passe temporaire.

---

### 3.2. Étapes détaillées

1. **Récupérer le matricule de l’utilisateur**  
   - Depuis la demande de support.
   - Ou via Kador / fiche RH / tout référentiel interne.

2. **Modifier l’option de profil “Types de connexion”**
   - Ouvrir la fiche utilisateur dans Oracle.
   - Rechercher l’option de profil (ou chaîne) :  
     > « Connexion unique aux applications – Types de connexion » ou chaîne contenant « Connexion%Type% »
   - Ajouter ou positionner la valeur **« Locale »** (ou « Les deux » si besoin).
   - Sauvegarder les modifications.

3. **Réinitialiser le mot de passe**
   - Saisir un mot de passe temporaire du type :  
     > `Dalkia123`
   - S’assurer qu’il respecte les règles de sécurité en vigueur (politique de mot de passe si appliquée).
   - Valider la nouvelle valeur.

4. **Vérifier l’absence de date de fin de validité**
   - Sur la fiche utilisateur, contrôler qu’il n’existe **pas de date de fin** :
     - Ni sur le compte utilisateur (dates d’activation).
     - Ni sur une éventuelle date de fin de mot de passe, si elle est gérée.
   - Le compte doit être **actif** et **sans date de fin** bloquante.

5. **Sauvegarder**
   - Enregistrer l’ensemble des modifications sur la fiche utilisateur.
   - Faire un contrôle rapide (par ex. déconnexion/reconnexion si compte test).

---

### 3.3. Modèle de réponse dans le ticket

Une fois les opérations techniques réalisées, répondre à l’utilisateur dans le ticket :

> Bonjour,  
>   
> Suite à une intervention technique sur votre compte, votre mot de passe a été réinitialisé.  
>   
> **Nouveau mot de passe temporaire** : `Dalkia123`  
>   
> Merci de bien vouloir le modifier lors de votre prochaine connexion.  
>   
> Cordialement,  
> [Signature / Équipe support]

fileciteturn0file0  

---

## 4. Déblocage / réactivation / synchronisation d’un compte Oracle en SSO

Cette section traite du cas où un utilisateur :

- Ne peut pas (ou plus) se connecter à Oracle en SSO.
- Nécessite une **vérification de son compte Oracle**.
- Nécessite éventuellement une **réactivation** et/ou une **synchronisation** AD / ISIM. fileciteturn0file1  

---

### 4.1. Vérifier le compte dans FND_USER

1. Se connecter à la base Oracle avec un compte ayant accès à **FND_USER**.
2. Lancer une requête de contrôle, par exemple :

```sql
SELECT user_name,
       user_guid,
       start_date,
       end_date,
       description,
       last_update_date
FROM   fnd_user
-- WHERE user_name = '55136Y'
WHERE  UPPER(description) LIKE '%PICHOT%';
```

- `user_name` : le login Oracle (souvent le matricule).  
- `user_guid` :
  - **Vide** pour un utilisateur **non synchronisé** (pas de liaison SSO).
  - Renseigné pour un utilisateur synchronisé via ISIM. fileciteturn0file1  

---

### 4.2. Gestion des comptes inactifs

Si le compte est **inactif** (champ `end_date` renseigné, ou statut inactif côté application) :

1. Effectuer quelques vérifications préalables :
   - Contrôle dans **Kador**.
   - Contrôle de la **fiche employé** / RH.
   - Si doute : envoyer un mail à l’utilisateur (ou à sa hiérarchie) pour lui demander le **motif** du besoin d’accès à Oracle.

2. En fonction du motif :
   - Si l’accès est justifié (poste actif, besoin métier réel) : **réactivation possible**.
   - Sinon : refuser la réactivation et mettre à jour / documenter la demande.

---

### 4.3. Réactivation et mise à jour de l’option de profil

Si le motif est jugé **valable** :

1. **Réactiver le compte Oracle** :
   - Supprimer la date de fin, ou
   - Passer le statut sur **Actif**.

2. **Mettre à jour l’option de profil “Types de connexion”** :
   - Aller sur la fiche utilisateur.
   - Repérer l’option de profil contenant « Connexion%Type% ».
   - La positionner à :
     - **« Les deux »** (recommandé pour la transition / diagnostic), ou
     - **« Locale »** en cas de blocage côté SSO (temporaire).

3. **Sauvegarder** les modifications. fileciteturn0file1  

---

### 4.4. Ticket JIRA AD – Extension Attribute1 (synchronisation SSO)

Lorsque le compte Oracle est correct mais que la synchronisation SSO pose problème, il faut faire vérifier / corriger l’**Extension Attribute1** du compte AD :

1. **Créer un ticket JIRA** auprès de l’équipe AD.
2. Demander la vérification ou la mise à jour de l’**Extension Attribute1** du compte AD de l’employé.
   - Fournir la **valeur matricule**.
3. Prendre exemple sur des tickets existants, par ex. :
   - `AD-2419` pour un **nouvel employé**.
   - `AD-2413` pour un **utilisateur plus ancien**.

> IMPORTANT :  
> Pour les **nouveaux comptes Oracle** créés avec le **DK Code**, il n’est **pas nécessaire** de créer un ticket AD : la partie AD est déjà gérée dans le process de création. fileciteturn0file1  

---

### 4.5. Demande de synchronisation ISIM via OASIS

Une fois le ticket AD traité et validé (**retour OK AD**) :

1. Créer une demande dans **OASIS** à destination d’**ISIM** :
   - Depuis le **Catalogue de travaux ISIM**.
   - Choisir l’option :  
     > **« Lancement d’un traitement à la demande (selon un mode opératoire défini) »**.

2. Dans la demande, préciser :
   - Le matricule ou identifiant Oracle de l’utilisateur.
   - L’objet : **Synchronisation du compte Oracle**.

Exemple de demande : `RITM0272890`. fileciteturn0file1  

---

### 4.6. Mail à ISIM / suivi

En parallèle de la demande OASIS, envoyer un mail à :

- L’équipe **ISIM**.
- Lotfi.
- Latifa.

Objet : demande de **synchronisation du compte** de l’utilisateur.

Contenu minimal recommandé :

> Bonjour,  
>   
> Pouvez-vous procéder à la synchronisation du compte Oracle pour l’utilisateur suivant :  
> - Matricule : [xxxxxx]  
> - Nom / Prénom : [Nom Prénom]  
> - Environnement : [FIN01 / autre]  
>   
> La demande OASIS associée est : RITM0xxxxxx.  
>   
> Merci d’avance,  
> [Signature]

fileciteturn0file1  

---

### 4.7. Information de l’utilisateur et test de connexion

Après **retour OK d’ISIM** :

1. Informer l’utilisateur dans le ticket OASIS / JIRA :
   - Indiquer que la synchronisation a été réalisée.
   - L’inviter à retester sa connexion.

2. Communiquer l’URL de connexion Oracle, par exemple :

> `https://finance.dalkia.net:4443/OA_HTML/AppsLogin`

3. Si le problème persiste :
   - Reprendre la check-list ci-dessous.
   - Éventuellement repasser temporairement le compte en **Locale** pour isoler le problème. fileciteturn0file1  

---

### 4.8. Check-list rapide d’investigation

Avant d’escalader :

- [ ] Compte présent dans **FND_USER**.
- [ ] Compte **actif** (pas de date de fin bloquante).
- [ ] `user_guid` renseigné pour les comptes SSO.
- [ ] Option de profil “Types de connexion” correctement positionnée (Les deux / Locale).
- [ ] Extension Attribute1 correcte côté AD (ticket AD OK).
- [ ] Synchronisation ISIM déclenchée et confirmée.
- [ ] L’utilisateur utilise la bonne URL et le bon contexte.

---

## 5. Mise à jour des mots de passe sur PHENIX (Oracle 11i)

Cette section décrit la procédure de **mise à jour du mot de passe** d’un utilisateur dans **PHENIX (Oracle 11i)** via la responsabilité d’administration. fileciteturn0file8  

---

### 5.1. Connexion à PHENIX en mode Internet Explorer

1. Ouvrir **Microsoft Edge**.
2. Se connecter à l’URL de PHENIX, ou utiliser le **favori PHENIX** présent par défaut dans Edge.
3. **Ne pas** saisir les identifiants dans la page de login.
4. Ouvrir le menu Edge et sélectionner :

> **« Recharger en mode Internet Explorer »**

5. Attendre que la page se recharge en mode IE (nécessaire pour l’applet Java). fileciteturn0file5turn0file8  

*(Les étapes détaillées de connexion en mode IE sont documentées dans la procédure de connexion à Oracle PHENIX 11i et dans le document spécifique Edge → IE Mode.)*  

---

### 5.2. Accès à la responsabilité d’administration

1. Une fois connecté à PHENIX :
   - Saisir les identifiants administrateur si nécessaire.
2. Dans la fenêtre de navigation principale, sélectionner la responsabilité :

> **« Administrateur Exploitation Dalkia »**

Cette responsabilité donne accès aux écrans de gestion des utilisateurs et de sécurité. fileciteturn0file8  

---

### 5.3. Ouverture de la console Java et navigation vers les utilisateurs

1. Au lancement de l’applet **Java**, une popup de sécurité apparaît.
2. Cliquer sur :

> **« Autoriser cette session »**

pour autoriser le chargement de l’applet.

3. Une fois le **navigateur Oracle** chargé (Forms), aller dans le menu :

> **Sécurité → Utilisateur → Définir**

pour ouvrir l’écran de gestion des utilisateurs. fileciteturn0file8  

---

### 5.4. Recherche de l’utilisateur

Dans l’écran **Utilisateur** :

1. Appuyer sur la touche **[F11]** pour passer en mode recherche.
2. Dans le champ **« Nom utilisateur »**, saisir le **matricule** ou le login de l’utilisateur.
3. Appuyer sur **[Ctrl] + [F11]** pour lancer la recherche.
4. Vérifier que la fiche de l’utilisateur s’affiche.

fileciteturn0file8  

---

### 5.5. Saisie du mot de passe temporaire

1. Dans le champ **« Mot de passe »** :
   - Saisir une première fois le **mot de passe temporaire**, par exemple :  
     > `Dalkia123`
2. Appuyer sur **[Entrée]**.
3. Un message s’affiche en bas de l’écran :

> **« Entrez à nouveau votre mot de passe pour vérification »**

4. Saisir **à nouveau** le même mot de passe dans le même champ.
5. Appuyer sur **[Entrée]** pour valider la saisie.

Une fois validé, le champ « Mot de passe » se **vide** (comportement normal : Oracle ne l’affiche pas en clair). fileciteturn0file8  

---

### 5.6. Sauvegarde et contrôle

1. Cliquer sur l’icône **« Sauvegarder »** (disquette) pour enregistrer les modifications.
2. Vérifier :
   - Que **aucun message d’erreur** n’apparaît.
   - Que les autres champs de la fiche utilisateur (dates, statut) sont cohérents.

En cas de doute, il est possible de :

- Fermer et rouvrir la fiche utilisateur pour confirmer la bonne prise en compte.
- Demander à l’utilisateur de **tester sa connexion**.

fileciteturn0file8  

---

### 5.7. Mail à l’utilisateur

Une fois le mot de passe mis à jour dans PHENIX, envoyer un mail à l’utilisateur :

> Bonjour,  
>   
> Votre mot de passe de connexion à PHENIX (Oracle 11i) a été réinitialisé.  
>   
> **Nouveau mot de passe temporaire** : `Dalkia123`  
>   
> Merci de bien vouloir le modifier lors de votre prochaine connexion à PHENIX.  
>   
> Cordialement,  
> [Signature / Équipe support]

fileciteturn0file8  

---

## 6. Bonnes pratiques de gestion des comptes et mots de passe

Cette section complète les procédures par des recommandations générales (enrichissement par bonnes pratiques).

### 6.1. Conventions sur les mots de passe temporaires

- Utiliser une **convention homogène** (par ex. `Dalkia123`) facilite :
  - La communication vers les utilisateurs.
  - La standardisation des procédures.
- Toutefois, pour renforcer la sécurité :
  - Limiter la **durée de vie** des mots de passe temporaires (l’utilisateur doit les modifier rapidement).
  - Envisager des variantes par environnement (ex : suffixe différent pour Recette / Production, si autorisé par la politique interne).

---

### 6.2. Sécurité et confidentialité

- Ne **jamais** :
  - Publier de mot de passe dans des documents partagés sans contrôle.
  - Laisser des mots de passe temporaires dans des tickets non restreints.
- Préférer :
  - Les communications via des canaux internes sécurisés.
  - Les notifications minimales (ne pas rappeler le login si ce n’est pas nécessaire).

---

### 6.3. Traces et audit

- Systématiser :
  - La mise à jour des tickets (OASIS / JIRA) avec :
    - La date et l’heure d’intervention.
    - Les actions réalisées (réinitialisation mdp, changement profil, création ticket AD, demande ISIM, etc.).
  - La mention de l’**URL de test** fournie à l’utilisateur.
- En cas de suspicion d’usage abusif :
  - Informer les équipes sécurité / RSSI selon le process interne.
  - Regarder les journaux applicatifs si cela fait partie du périmètre support.

---

## 7. Annexes

### 7.1. Requêtes SQL utiles

#### 7.1.1. Vérifier un utilisateur Oracle par description (nom / prénom)

```sql
SELECT user_name,
       user_guid,
       start_date,
       end_date,
       description,
       last_update_date
FROM   fnd_user
WHERE  UPPER(description) LIKE '%NOM_UTILISATEUR%';
```

#### 7.1.2. Vérifier un utilisateur Oracle par login (matricule)

```sql
SELECT user_name,
       user_guid,
       start_date,
       end_date,
       description,
       last_update_date
FROM   fnd_user
WHERE  user_name = 'MAT12345';
```

fileciteturn0file1  

---

### 7.2. Modèles de mails

#### 7.2.1. Mail à l’utilisateur – réinitialisation de mot de passe (Oracle / PHENIX)

> Objet : Réinitialisation de votre mot de passe Oracle  
>   
> Bonjour,  
>   
> Suite à votre demande, votre mot de passe a été réinitialisé.  
>   
> **Nouveau mot de passe temporaire** : `Dalkia123`  
>   
> Merci de bien vouloir le modifier lors de votre prochaine connexion.  
>   
> Cordialement,  
> [Signature / Équipe support]

fileciteturn0file0turn0file8  

#### 7.2.2. Mail aux équipes ISIM – synchronisation de compte

> Objet : Demande de synchronisation de compte Oracle – [Matricule]  
>   
> Bonjour,  
>   
> Merci de procéder à la synchronisation du compte Oracle suivant :  
> - Matricule : [xxxxxx]  
> - Nom / Prénom : [Nom Prénom]  
> - Environnement : [FIN01 / autre]  
> - Demande OASIS : RITM0xxxxx  
>   
> Le compte a été vérifié côté Oracle et le ticket AD correspondant a été validé.  
>   
> Cordialement,  
> [Signature]

fileciteturn0file1  

---

### 7.3. Références des documents sources

- **Action à faire pour les internes ayant problème de réinitialisation de mot de passe Oracle avec la connexion SSL** fileciteturn0file0  
- **Étapes à suivre pour débloquer un user Oracle en SSO** fileciteturn0file1  
- **Procédure de mise à jour des mots de passe sur PHENIX (Oracle 11i)** fileciteturn0file8  
- **Procédure de connexion à Oracle PHENIX 11i (Edge / IE Mode)** – utilisée en référence pour la partie connexion fileciteturn0file5  

---
