SOMMAIRE
1	Création d’une SVD	4
1.1	Préambule	4
1.2	Pré requis	4
1.2.1	Identification de la nouvelle organisation logistique	4
1.2.2	Jeux de valeurs pour GL	4
1.2.3	Désactivation des règles de validations croisées	10
1.2.4	CE Compte bancaire	10
1.3	Traitement SoftaPlay phase 1 : LE, Ledger, OU, Inv Org	10
1.3.1	Chargement des variables dans SoftaPlay	10
1.3.2	Extraction des données de la société de référence	11
1.3.3	Appliquer les règles aux enregistrements extraits	11
1.3.4	Mettre à jour la période FA	11
1.3.5	Déploiement des règles pour la ou les sociétés	12
1.3.6	Chargement du paramétrage	13
1.4	Paramétrages et traitements manuels 1	13
1.4.1	Lancement du traitement de duplication des données systèmes	13
1.4.2	Création des Profils de sécurité	14
1.4.3	Création des clients pour PA	17
1.5	Traitements SoftaPlay phase 2	19
1.6	Post Création Softa	20
1.7	Traitements de mise à jour	21
1.7.1	Définir les options fournisseurs/bénéficiaires	21
1.7.2	PO : Attachement des conditions générales d'achat à l'UO	21
1.7.3	Compte bancaires – Autorisés le livre pour la gestion des banques	22
1.8	Post Création Softa – Module GL	24
1.9	Post Création Softa – Module ETAX	28
1.10	Post Création Softa – Module PA	32
1.11	Paramétrage sur perso écran AR (Mouvements et Règlements)	39
1.12	Paramétrage Comptes Non Soldés AR et AP	41
1.13	Paramétrage compte bancaire interne Dalkia	42
1.14	Post Création Softa – Création des modes de Règlements AR	46
1.15	Post Création Softa – Ouverture des périodes TOUS MODULES	51
1.16	Post Création Softa	52
2	Transfert d’une SVD	53
2.1	Préambule	53
2.2	Pré requis	53
2.2.1	Recherche de l’ancienne UO (Org_id)	53
2.2.2	Chargement des variables dans SoftaPlay	54
2.2.3	Mise à jour des jeux de valeurs	54
2.2.4	Mise à jour des données d’organisation	59
2.2.5	Désactivation des règles de validations croisées	74
2.2.6	Création / modification des Profils de sécurité	74
2.2.7	Etapes additionnelles pré-Softa	77
2.3	Traitement SoftaPlay : RàZ et chargement des variables	82
2.4	Traitement SoftaPlay phase 1 : LE, Ledger, OU, Inv Org	82
2.4.1	Extraction des données de la société de référence	83
2.4.2	Appliquer les règles aux enregistrements extraits	83
2.4.3	Mise à jour de la période FA	84
2.5	Déploiement des règles pour la ou les sociétés	84
2.6	Post Création Softa	85
2.7	Ajouter les livres aux jeux de livres OPERATIONNEL, OPERATIONNEL+REFERENCE et sur la nouvelle région	85
2.7.1	Mise à jour du champ Latest_Opened_Period_Name de la table GL_LEDGERS avec la dernière période ouverte	85
2.7.2	Vérifier la création des nouvelles règles de validation croisée	86
2.7.3	Case « Utiliser l'abonnement de l'entité juridique » non cochée	88
2.7.4	Traitement des incidents connus pendant l’exécution de SoftaPlay	90
2.7.5	Réactivation de l’ensemble des règles de validation croisées	93
2.8	Traitements de mise à jour	95
2.8.1	Définir les options fournisseurs/bénéficiaires	95
2.8.2	PO : Attachement des conditions générales d'achat à l'UO	95
2.8.3	Compte bancaires – Autorisés le livre pour la gestion des banques	96
2.9	Post Création Softa – Module GL	98
2.10	Post Création Softa – Module ETAX	102
2.11	Post Création Softa – Module PA	104
2.12	Paramétrage sur perso écran AR (Mouvements et Règlements)	112
2.13	Paramétrage Comptes Non Soldés AR et AP	114
2.14	Paramétrage compte bancaire interne Dalkia	115
2.15	Post Création Softa – Création des modes de Règlements AR	119
2.16	Post Création Softa – Ouverture des périodes TOUS MODULES	124
2.17	Post Création Softa	125


Création d’une SVD
Préambule
Le présent document décrit en première partie la procédure permettant de créer une ou plusieurs SVD dans Oracle FIN01. La procédure de transfert de SVD sera décrite en deuxième partie. 
Ces paramétrages sont réalisés à l’aide de l’application SoftaPlay, avec un chargement préalable réalisé à l’aide de l’outil DataLoad.
Pré requis
Identification de la nouvelle organisation logistique
PR1.01 : Identifier le numéro de la nouvelle organisation logistique pour alimenter la variable « Inventory Org Num » en l’incrémentant de 1.
Ajoutez 1 au résultat de la requête ci-dessous :
select max(organization_code) 
from MTL_PARAMETERS_VIEW 
order by organization_code desc ;
Remplissage du fichier de création pour DataLoad
Seul l’onglet « A créer » est à renseigner. Les autres se remplissent automatiquement.
Récupération de la valeur des champs : Depuis l’onglet « INITSOC- Oracle R12 » (les champs barrés ne sont pas renseignés dans ce cas de création Light)
Champ
Source
Num pour TSA
Valeur entre parenthèses du champ « Libellé de l’adresse » de l’onglet « TSA CSP » du fichier INITSOC
Numéro & rue
Colonnes C et D de l’onglet « TSA CSP » du fichier INITSOC
Projet FPS
Champ « Projet Finance par UO » de l’onglet « Nouveau référentiel R12 » du fichier INITSOC

Jeux de valeurs pour GL

PR1.02 : GL, Code de regroupement
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Regroupement
Jeu de valeurs DAOPCCF_STE : Codes de regroupement de la nouvelle société


PR1.03 : GL, jeu de valeur des codes conso pour Vector XDKA_ARGOS_INTERCO
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : XDKA_ARGOS_INTERCO

Code conso de la nouvelle société
PR1.04 : GL, jeu de valeur des codes sociétés DAOPCCF_STE
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_STE
Code de la nouvelle société
code de regroupement (Axxx) de la nouvelle société
Pour la valeur A423, il faut cocher parent + mettre Groupe 

Cliquer sur Définir fourchette Enfant => Et indiquer le code société


PR1.05 : GL, jeu de valeur des codes Interco DAOPCCF_INTERCO
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_INTERCO
Il faut créer 3 valeurs dans DAOPCCF_INTERCO : 0423, DOS0423 et XXX0423
Valeur Société (coché parent) 0423 

Il faut cliquer sur Définir les fourchettes enfants pour associer DOS0423 et XXX0423
Puis il faut créer DOS0423 et XXX0423


La valeur segmentation magnitude 
Valeur Non quand il s’agit d’une société Mono Région
Valeur Oui quand il s’agit d’une société Multi Régions


PR1.06 : GL, jeu de valeur des comptes locaux DAOPCCF_LOCAL
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_LOCAL
Compte comptable du compte bancaire


PR1.07 : dans Jeu de valeur DAOPCCF_PROJETFI
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_PROJETFI
Création de la valeur XXXYYYY (Projet de REFAC)

Création de la valeur du Projet Frais et Produits de Société (FPS)

PR1.08 : GL, Ajouter la société/région dans les règles de validations croisées
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Règles
FILTRER D’ABORD SUR « STE% »

STE-REGION : Inclure la règle de 0 à ZZZZ
STE-PARTENAIRE : 
Exclure le code partenaire région de la société (ex : DOS0423)
Exclure le code partenaire XXX de la société (ex : XXX0423)
PR1.09 : GL, création des adresses de la société
Responsabilité : DKA PO SAISIE DES EMPLOYES
Navigation : Lieu

Les écrans des responsabilités PO comportent un CUF supplémentaire, ils ne sont pas compatibles avec le format du Dataload.


Se positionner sur l’onglet « Adresses » du fichier de création.
Adresse du siège social (Code = variable « Company Name »
Adresse de facturation (Code = variable « Code UO »)
Surveiller la saisie du DAtaLoad et corriger les champs des adresses des livres « Company name » car le Tab4 risque d’être trop rapide et donc peut mettre le code postal et la ville dans le même champs.
PR1.10 : GL, Table de transco DKA_CONSO_VECTOR
Responsabilité : Administrateur Exploitation Dalkia
Navigation : Ecran de transco : Lignes
Context : DKA_CONSO_VECTOR
Code société + région = Code conso
PR1.11 : GL – MAJ Table Transco pour déterminer le compte Groupe pour le compte de banque (MIGR_GROUP_ACCOUNT_CLASS_BILAN)
Responsabilité : Administrateur Exploitation Dalkia
Navigation : Ecran de transco : Lignes
Context : MIGR_GROUP_ACCOUNT_CLASS_BILAN
Pour les comptes de banque => Compte groupe 17060


Désactivation des règles de validations croisées
PR1. 11 : GL, Règles de validation croisée
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Règles
Désactivation temporaire des règles de validation croisées :
BG-BL : Bilan Analytique - Bilan Local
CE-RG : Centre - Resultat Compte Analytique
CE-RL : Centre - Resultat Compte Local
GRP-FLUX : Gére les combinaisons Cpte Analytique / Flux autorisée
STE-REGION : Interdit les couples Société/Région inexistant
CE Compte bancaire

PR1.12 : CE, vérifier l’existence de la banque pour le compte et la créer si besoin
PR1.13 : CE, vérifier l’existence de l’agence bancaire pour le compte et la créer si besoin
PR1.14 : CE, Créer le compte bancaire
Traitement SoftaPlay phase 1 : LE, Ledger, OU, Inv Org
Chargement des variables dans SoftaPlay
La première opération doit être la suppression des variables correspondantes aux sociétés créées dans un projet précédent. Cette opération (clic droit « Remove ») se fait société par société.

Charger les variables des sociétés du nouveau projet.


Les variables « Inventory Org Num » et « Share capital » doivent obligatoirement être renseignées sous forme de texte (ex ‘346)
Autrement, l’ID ne sera pas traduit correctement et SoftaPlay génèrera l’erreur « Organization Already exists »


Pour passer en mode « Déploiement », clic droit sur le projet « SVD Création » puis choisir « Monitor Project »

Extraction des données de la société de référence
➀ Sélectionner l’ensemble des composants 
➁ Cliquer sur le bouton « Extract » 
➂ A l’issue du traitement, le nombre d’occurrences extraites pour chaque composant est affiché

Appliquer les règles aux enregistrements extraits
Cliquer sur le bouton « Apply » et choisir la ou les sociétés à traiter.

Le résultat de l’Apply est présenté dans une fenêtre avec des combo-box permettant d’afficher composants et sous-composants
Mettre à jour la période FA
Le calendrier du livre de la société de référence 9999 commençant avec la période M1R-20, il est nécessaire de modifier la date de début du Livre FA 
Il faut saisir la date de début de la période précédente sous la forme DD/MM/YYYY. Par exemple, pour une période initiale en novembre 2021, on saisira la date du 01/10/2021.
Depuis « View Apply Result », choisir « Book controls et mettre à jour “Initial Date”

Initial Date : en fonction de la date du jour, on déduit sur quelle période FA on est positionné. Si le process de clôture mensuelle est entamé (généralement vers le 24 du mois), on va mettre le premier jour du mois en cours. Si le process de clôture n’est pas en cours, on met le premier jour du mois précédent.
Déploiement des règles pour la ou les sociétés
Modifier en « Error » la valeur de « Stop when » de la ligne « Securit rules and assignments » pour éviter un blocage sur les responsabilités non crées.

🡺Vérifier que les nouveaux identifiants des organisations à créer sont bien ceux définis dans le fichier des variables (Inventory Org Num)

Sélectionnez les traitements jusqu’à l’Inventory Org avant de lancer « Deploy » et « Load »

Cliquer sur le bouton « Deploy » et confirmer

Chargement du paramétrage
Le déploiement alimente la colonne « Waiting » avec le nombre d’enregistrement à créer (en fonction du nombre de société)
Cliquer sur le bouton « Load » et confirmer pour lancer les traitements de chargement du paramétrage.

Le résultat des traitements s’affiche dans les colonnes : Chargé, passé et rejeté

Paramétrages et traitements manuels 1
Lancement du traitement de duplication des données systèmes
Responsabilité : Administrateur système
Navigation : Autres / Lancer
Traitement : Dupliquer les données système
Pour chaque nouvelle unité opérationnelle créée, il faut lancer sous la responsabilité « Administrateur Système » le traitement « Dupliquer les données système »


Création des Profils de sécurité

Responsabilité : TOUT_FA_ADMINISTRATEUR
Navigation : Configurer / Sécurité / Sécurité
ou
Responsabilité : TOUT_PA_ADMINISTRATEUR
Navigation : Configuration / Ressources et organisations / Fondation HR / Sécurité / Profil
🡺 Pour les étapes 1 et 2, utiliser l’onglet « Profil sécu code UO » du fichier de création 
ETAPE 1 : Ajouter les unités opérationnelles aux profils de sécurité.

ETAPE 2 : Ajouter l’UO au profil global « DKA_TOUT » et « DKA_TOUT + REFERENCE »




ETAPE 3 : Créer un profil de sécurité pour la nouvelle société.

ETAPE 4 : Créer le profil de sécurité correspondant à la région/société (unité opérationnelle) comme suit.

ETAPE 6 : Lancer le traitement de mise à jour des listes de sécurité

Ce traitement va mettre à jour les listes de valeurs avec les livres appropriés.
ETAPE 7 : Lancer le traitement « Mise à jour des listes de sécurité » avec les paramètres suivants.

ETAPE 8 : S’assurer qu’ils se terminent normalement.t


Création des clients pour PA

Responsabilité : TOUT_AR_ADMINISTRATEUR
Navigation : Client > Standard
 Ce paramétrage est à réaliser pour chaque région/société (unité opérationnelle)  <YYYXXXX> de la nouvelle société.
Créer un nouveau site pour le client par défaut paramétré pour PA.
Pour cela :
Rechercher le client « CLIENT_POUR_PA »

Ouvrir le détail du compte


Cliquer sur « Créer un site »

Sélectionner l’unité opérationnelle pour laquelle le site doit être créé puis cliquer sur « Continuer »



Compléter les fonctions économiques et le lieu, puis cliquer sur « Terminer »

Revenir dans les fonctions économique pour remplacer dans le champ « Lieu » l’ID par un « . » puis « Appliquer » puis « Sauvegarder »



Traitements SoftaPlay phase 2
Réactiver le type de dépenses avant de lancer la 2ème partie de Softa
FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)

Décocher les étapes déjà réalisées (jusqu’à Inventory Org) et faire les actions « Deploy » et « Load »

Modifier en « Error » la valeur de « Stop when » de la ligne « Implementation Options » pour éviter un blocage sur le livre d’immo non crées.

Les traitements ci-dessous vont s’exécuter après clic sur Deploy puis Load:

Post Création Softa

PCS01 : GL, Règles de validation croisée
Réactivation des règles de validation croisées :
BG-BL : Bilan Analytique - Bilan Local
CE-RG : Centre - Resultat Compte Analytique
CE-RL : Centre - Resultat Compte Local
GRP-FLUX : Gére les combinaisons Cpte Analytique / Flux autorisée
STE-REGION : Interdit les couples Société/Région inexistant

Traitements de mise à jour
Définir les options fournisseurs/bénéficiaires
Se connecter sur la Responsabilité Administration Exploitation Dalkia
Lancer le traitement : DKA : Creation des options fournisseurs et bénéficiaires
Entrer en paramètre l’UO 


PO : Attachement des conditions générales d'achat à l'UO

Se connecter sur la Responsabilité Admnistration Exploitation Dalkia
Lancer le traitement : DKA : Attachement des CGA



Compte bancaires – Autorisés le livre pour la gestion des banques
Se connecter avec Sysadmin et le mot de passe de Sysadmin (En Anglais)
Responsabilité User Management => Puis Menu Roles et Role Inhe




Puis cliquer sur Update 

Puis cliquer sur Security Wizards

Sur la ligne CE UMX Security wizard  Cliquer sur Wizard

Il faut ajouter le nouveau Livre 
Pour cela cliquer sur Add Legal Entities

Choisir le livre dans la Liste de valeur et le sélectionner

Puis cliquer sur Use et Maintenance pour le nouveau Livre et cliquer sur Apply pour enregistrer

Cliquer de nouveau sur Apply

Post Création Softa – Module GL

Vérifier le segment équilibrage au niuveau Etablissement
Responsabilité TOUT_GL_OP_ADMINISTRATEUR
Menu Configuration Comptable / Entité Comptable / Etablissements

Cliquer sur Détails

Puis cliquer sur Segment d’équilibrage

Puis cliquer sur Mettre à jour et ajouter le segment d’équilibrage de la société 

Paramétrage Taxe dans GL
Avant il faut ajouter le nouveau Livre créé dans le jeu de livre OPERATIONNEL

Responsabilité TOUT GL OP
Menu : Configurer / Taxe Options de taxe

Retirer la société du Jeu de livres


Ajouter le nouveau Livre (et UO) dans les jeu de livres
Pour le livre => Il y a 2 jeu de Livres : 
OPERATIONNEL
OPERATIONNEL + REFERENCE 



Et pour la région 

Attention il existe plusieurs Jeu de Livres :


Création du paramétrage Pièce Répétitive (Abonnements GL)
Il faut créer les En têtes de 2 abonnements pour le nouveau Livre 
YYYY XXX (Exemple 0423 DOS)
YYYY XXX IFRS (Exemple 0423 DOS IFRS)

Et 


Création du paramétrage Pièce Répétitive (Equilibre CDG) pour les Multi Régions

Post Création Softa – Module ETAX

Ajouter le nouveau Livre dans la Configuration Fiscale FR
Depuis la Responsabilité Administration Taxe
Menu Configuration Fiscale / Régimes Fiscaux
Mettre le code Pays France et ensuite cliquer sur Accéder

Cliquer sur Mettre à jour

Puis cliquer sur Continuer

Cliquer sur Ajouter parties
Et chercher le nouveau livre  et sélectionnez le
Puis cliquer sur Terminer (2 fois avec messages + de 300 Lignes)


Ajouter l UO dans la partie
Partie / Profils fiscaux de partie
Type de partine : UO
Nom : XXXYYYY (Nom de l’UO exemple DOS0423)
Puis cliquer sur accéder

Puis clique sur Créer un profil Fiscal


Cocher utiliser l’abonnement de l’entité juridique
Et cliquer sur Appliquer



Post Création Softa – Module PA

Vérifier le code AFFAIRE sur le modèle de PROJET ORGANIQUE :
Se connecter sur la Responsabilité XXXYYY_PA_ADMINISTRATEUR => Mettre le code AFFAIRE ci-dessous le sur modèle de projet ORGANIQUE : A00000000A


Création des modèles ACCORD CADRE
Se connecter depuis la  Responsabilité XXXYYYY_PA_ADMINISTRATEUR
Menu : Confirguation / Facturation / Modele Accord cadre
Il faut créer 3 modèles accords Cadre :
OPERATIONNEL
ORGANIQUE
REFAC
OPERATIONNEL 

Puis cliquer sur Financement

Puis cliquer sur la Disquette pour sauvegarder
ORGANIQUE

Puis cliquer sur Financement

Puis cliquer sur la Disquette pour sauvegarder
REFAC

Puis cliquer sur Financement

Cliquer sur la disquette pour enregistrer

Création des Modèles de budgets
Il faut se connecter depuis la responsabilité XXXYYY_PA_ADMINISTRATEUR
Puis dans le menu BUDGETS
Il faut créer 3 Modèles de Budgets : 
OPERATIONNEL
ORGANIQUE
REFAC
OPERATIONNEL 
Dans le numero de Projet => Rechercher le Projet OPERATIONNEL
Puis Saisissez la version du Budget

Enregistrer sur la Disquette
Puis cliquer sur Budget Provisoire
Puis cliquer sur Détail

Cliquer sur la disquette pour enregistrer et fermer la fenêtre
Cliquer ensuite sur soumettre

Puis cliquer sur Budget de Référence

Le budget devient Actuel
	

Cliquer sur la disquette pour sauvegarder

Il faut faire la même chose pour :
DOS0423.OGRANIQUE 
DOS0423.REFAC






Création du projet de REFAC 
Se connecter sur la Responsabilité XXXYYY_PA_ADMINISTRATEUR
Menu Configurer / Projets / Modèles de projets
Création Manuelle du projet de REFAC, il faut partir du Modèle REFAC et cliquer sur Copier vers
Numéro du projet = XXXYYYY (DOS0423)
Nom du projet :  DOS0423-REFAC
Description du projet :  DOS0423-REFAC
Centre Fi du projet : selon la région (Exemple DOS = B00000001B)
Date de début : 01/01/1951

Se placer sur le modèle et cliquer sur Copier vers
Remplir les zones et cliquer sur OK



MAJ de l’organisation 
Il faut mettre la TF DIAPASON 


Paramétrage sur perso écran AR (Mouvements et Règlements)

Ecran de saisie des mouvements AR 
Il faut aller sur l’écran de saisie des mouvements AR depuis la Responsabilité TOUT_AR_ADMIN

Il faut ajouter 2 responsabilités et cliquer sur Enregistrer puis fermer l’écran


Ecran de saisie des règlements AR

Il faut aller sur l’écran de saisie des règlements AR depuis la responsabilité TOUT_AR_ADM


Et la il faut ajouter les 3 Responsabilités ci-dessous


Paramétrage Comptes Non Soldés AR et AP

Paramétrages comptes collectifs – Comptes non soldés AR

Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configuration / Comptabilité / Définition des listes de soldes comptes ouverts
Code : CLIENTS_YYYY  (Exemple = CLIENTS_0423)
Nom : CLIENTS_YYYY  (Exemple = CLIENTS_0423)
Description : Balances Clients YYYY (Exemple = Balance clients 0423)
Coté du solde : Débit
Actif : oui


Paramétrages comptes collectifs – Comptes non soldés AP
Responsabilité TOUT_AP_ADMINISTRATEUR
Menu : Configurer / Configuration Comptable / Définition des soldes des comptes non ouverts



Paramétrage compte bancaire interne Dalkia

Création du compte bancaire – Resp TOUT_AP_ADMINISTRATEUR





Ajouter la nouvelle UO créée 





Puis cliquer sur TERMINER

Le compte bancaire interne a été créé : 

Ensuite il faut créer les Titres de paiements => Cliquer sur Gérer les titres de paiements

Cliquer sur Créer


Puis créer le compte 585000 pour la nouvelle société 
0423_DOS_585000
Compte de tresorerie = 0423.DOS.585000.14300.0.0.0.0.0.0.0.0
Sur la Banque TRESORERIE INTERNE (99999) et sur l’Agence COMPTE DE LIAISON (99999)

Avec 3 titres de paiements : 

Puis il faut créer les Modèles instructions de règlements 

Puis côté AR, il faut créer les modes de Règlements AR -> CHEQUE ET VIREMENT
Responsabilité TOUT_AR_ADMINISTRATEUR 
Menu Configurer / Règlements / Classes de règlements

Post Création Softa – Création des modes de Règlements AR

Création des modes de règlements VIREMENT sur 51* et 585*
Se connecter sur Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configurer / Règlement / Classe de règlement



Création des modes de règlements CHEQUE sur 51* et 585*
Se connecter sur Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configurer / Règlement / Classe de règlement


Affectation des séquences
Il faut ensuite affecter les séquences aux livres créés
Se connecter sur Administraction Exploitation Dalkia
Menu : Application / Numérotation des pièces / Affecter


Paramétrage pour intagra groupe AP/AR
Se connecter sur la Responsabilité TOUT AR ADMINISTRATEUR
Menu Configurer /  Règlement / Origines de règlements
Faire F11 et indiquer l’UO 

Puis CTRL F11

Il faut compléter : Le Mode de règlement et la banque

Puis Sauvegarder
Puis il faut aller dans Configurer / Règlement / Interface de règlements / Interface de Règlements


Ongle Règlements

Onglets Mouvements


Post Création Softa – Ouverture des périodes TOUS MODULES

Pré requis => Il faut que le LIVRE soit présent dans le Jeu de Livre OPERATIONNEL

Ouverture période GL
Se connecter depuis la Responsabilité TOUT_GL_OP_ADMINISTRATEUR
Menu Configurer / Ouvrir – Fermeture
Indiquer le livre 

Puis cliquer sur Rechercher et Ouvrir la période

Ouverture période PA
Ouverture période AP
Ouverture période AR
Ouverture période PO
Ouverture période FA

Post Création Softa

PCS01 : GL, Règles de validation croisée
Réactivation des règles de validation croisées :
CE-RG : Centre - Resultat Compte Analytique
CE-RL : Centre - Resultat Compte Local
GRP-FLUX : Gére les combinaisons Cpte Analytique / Flux autorisée



Transfert d’une SVD
Préambule
Cette partie du document décrit la procédure permettant de transférer une SVD lors de son activation à l’aide de l’application Softaplay.
Tout comme pour la création, ces paramétrages sont réalisés à l’aide de l’application SoftaPlay et de l’outil DataLoad. Plusieurs ajustements manuels sont néanmoins à prévoir.
Lors du transfert, plusieurs informations sont susceptibles d’être modifiées :
Raison sociale
Nom du livre comptable
Nom et détail de l’adresse
Détail de l’adresse de facturation
Code région
Carrying Out Organization
CF région
Code UO

Les valeurs de « Company Name », « Location Code » et « Code UO » du fichier de variables (Déploiement) doivent être absolument identiques à celles des « raison sociale », « nom du livre comptable », « nom de l’adresse » et « code UO » paramétrés dans Oracle.


Pré requis
Recherche de l’ancienne UO (Org_id)
Les identifiants pouvant être différents d’un environnement à un autre, notamment entre celui de Recette et celui de Production, il est nécessaire d’exécuter la requête suivante en premier lieu :
SELECT  hou.name, mp.organization_code
FROM    MTL_PARAMETERS_VIEW     mp, 
        HR_ORGANIZATION_UNITS_V hou
WHERE   hou.name LIKE '%0485'
        AND mp.organization_id = hou.organization_id
; 

L’information organization_code est à renseigner dans le champ « Inventory Org Num » du fichier de déploiement :


Remplissage du fichier de création pour DataLoad
Seul l’onglet « A créer » est à renseigner. Les autres se remplissent automatiquement.
Récupération de la valeur des champs : Depuis l’onglet « INITSOC- Oracle R12 »
Champ
Source
Num pour TSA
Valeur entre parenthèses du champ « Libellé de l’adresse » de l’onglet « TSA CSP » du fichier INITSOC
Numéro & rue
Colonnes C et D de l’onglet « TSA CSP » du fichier INITSOC
Projet FPS
Champ « Projet Finance par UO » de l’onglet « Nouveau référentiel R12 » du fichier INITSOC


Chargement des variables dans SoftaPlay
Préparation du fichier de variables
Reprendre et modifier le fichier de déploiement ayant servi pour la création de la SVD ou en préparer un avec les mêmes valeurs et y renseigner les nouveaux « Company name » (Raison sociale), « Location code » (nouveau nom du livre comptable et de l’adresse) et « Code UO », « CF Région » et « Carrying Out Organization » si la région de destination n’est pas DOS. 

Ces trois informations sont récupérables depuis l’onglet « Orga Région » du fichier de création.
Carrying Out Organization
CF région
Code Région
B00001602W
B00000004E
DCW
B00001428Y
B00000007H
DEW
B00001046N
B00000006G
DLS
B00001135P
B00000008J
DMS
B00001660L
B00000005F
DNA
B00001916C
B00000001B
DOS
B00001691X
B00000002C
DRW
B00001732T
B00000003D
DSW


Mise à jour des jeux de valeurs
Le fichier Excel de création permet de préparer le paramétrage des jeux de valeurs. Celui-ci peut être effectué automatiquement dans Oracle à l’aide de l’outil DataLoad.
MAJ01. XDKA_ARGOS_INTERCO 
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : XDKA_ARGOS_INTERCO
Rechercher d’abord le code conso (Valeur du champ « CODE CONSO VEOLIA » du fichier INITSOC). S’il existe dans le jeu de valeurs, modifier uniquement la description avec la nouvelle raison sociale. 

Exemple : DK21 est devenu MONTCHOVET ENERGIE, DK 22 est devenu MONTROUGE ENERGIE RENOUVELABLE.
S’il n’existe pas, créer une nouvelle ligne pour ce code conso, avec la nouvelle raison sociale dans la description.

MAJ02. DAOPCCF_STE (Il faut faire cette étape en cas de transfert même si l’onglet du fichier de création est vide pour ce jeu de valeurs)
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_STE
Rechercher le code société puis mettre à jour la description avec la nouvelle raison sociale
Mettre à jour le CUF Région principale
Supprimer le code conso SVD en DOS et saisir le nouveau en regard de la bonne région
Exemple : Avant :

Après : nouvelle région et code conso positionné sur la nouvelle région :

MAJ03. DAOPCCF_INTERCO (Il faut faire cette étape en cas de transfert même si l’onglet du fichier de création est vide pour ce jeu de valeurs)
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_INTERCO
Recherche : % « Société »%
Créer le nouveau code UO avec la nouvelle raison sociale et le code ARGOS associé

Mettre à jour la description avec la nouvelle raison sociale pour le code XXX<numéro de société> et changer le code Argos si nécessaire
Exemple : Avant 

Après :

Mettre à jour la description avec la nouvelle raison sociale pour le code <numéro de société> et ajouter le nouveau code UO dans la liste des « enfants »

MAJ04. DAOPCCF_LOCAL
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_LOCAL
Recherche par compte local et mise à jour de la raison sociale depuis la colonne D de l’onglet DAOPCCF_LOCAL du fichier de création.
Avant :

Après :

MAJ05. DAOPCCF_PROJETFI
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Valeurs
Jeu de valeurs : DAOPCCF_PROJETFI
Créer le nouveau code UO
Créer la ligne pour le projet
Mettre à jour la description avec la nouvelle raison sociale pour le projet de frais et produits de société

Cette étape peut être réalisée par DataLoad, notamment en cas de transferts multiples.
MAJ06. GL, Table de transco DKA_CONSO_VECTOR
Responsabilité : Administrateur Exploitation Dalkia
Navigation : Ecran de transco : Lignes
Rechercher le context « DKA_CONSO_VECTOR »
Rechercher le code conso puis mettre à jour le code région pour ce code conso. Code société + région = Code conso

Mise à jour avec la nouvelle région pour le code conso :

Si le code conso n’est pas le même que celui de l’ancienne société, créer une nouvelle ligne (suivre les instructions de l’onglet DKA_CONSO_VECTOR du fichier de création)

Cette étape peut être réalisée par DataLoad, notamment en cas de transferts multiples.

Mise à jour des données d’organisation
MAJ.07 : PO : Mettre à jour les adresses
Responsabilité : DKA PO SAISIE DES EMPLOYES
Navigation : Lieu

Les écrans des responsabilités PO comportent un CUF supplémentaire, ils ne sont pas compatibles avec le format du Dataload.


Pour chaque SVD, il existe 2 adresses identifiées. L’une par le nom du livre comptable et l’autre par le code UO.
Pour éviter toute ambiguïté, ces adresses doivent être mises à jour manuellement. 
Adresse du siège
Se positionner sur l’onglet « A créer » du fichier de création

Rechercher le nom du livre comptable (ancien)

Remplacer par le nouveau nom du livre comptable et la description par la raison sociale et mettre à jour l’adresse qui est mentionnée dans l’onglet « A créer » :



Nouveau nom du livre et nouvelle adresse :

Adresse de facturation
Se positionner sur l’onglet « ADRESSES » du fichier de création

Rechercher par le code UO (l’ancien)
 
Remplacer le nom par le nouveau code UO et la description par la nouvelle raison sociale, suivie du numéro pour TSA (comme renseigné dans la colonne U de l’onglet Adresses).
Mettre à jour l’adresse avec le TSA ou la nouvelle adresse si nécessaire (en suivant ce qui est renseigné dans l’onglet Adresses du fichier de création).

Mettre à jour le CUF « Région » :

Remarques : 
La mise à jour du CUF Région n’est pas prise en charge par le fichier de création pour DataLoad. Il faut donc le faire manuellement et renseigner la nouvelle région dans la colonne AR de l’onglet ADRESSES.
Vérifier que le Location code est identique pour l’adresse entre les fichiers Déploiement et Création sinon ajuster le location code de l’adresse dans Oracle.
Exemple ci-après de la société L’energie Luneville




MAJ.08 : GL : Nom du Ledger 
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Gestionnaire de configuration comptable / Configuration comptable
Dans l’onglet « Configuration comptable », rechercher la SVD par le nom du livre (ancien) et « Accéder », puis « Mettre à jour les options comptables »

Dans l’onglet « Livre principal », cliquer sur « mettre à jour » la ligne « Définir et mettre à jour les options … »

Modifier le nom du livre avec le nouveau nom du livre puis cliquer sur « Terminer »

Autre exemple : 

Nouveau livre :


Dans l’onglet « Livres secondaires », cliquer sur « mettre à jour » la ligne « Définir et mettre à jour les options … »

Modifier le nom du livre en le préfixant par R_  puis cliquer sur « Terminer »

Autre exemple :

Nouveau livre secondaire :


Après la mise à jour :

Astuce : en préparation de l’étape suivante, copier le nom de l’entité juridique :


MAJ.09 : XLE : Legal Entity
   
Dans l’onglet « Entité juridique », rechercher la SVD par la raison sociale et « Accéder », puis « Voir les détails » de l’entité juridique

Dans l’onglet « Général », cliquer sur « Mettre à jour »

Modifier le nom de l’entité juridique et le nom de l’organisation avec la nouvelle raison sociale puis cliquer sur « Appliquer »

Dans l’onglet « Enregistrements », cliquer sur « Mettre à jour »

Modifier le « nom enregistré », cliquer sur « Appliquer »

Dans l’onglet « Etablissements », cliquer sur « Voir les détails »

Cliquer sur « Mettre à jour »

Modifier le « nom d’établissement » et le « nom d’organisation » avec la nouvelle raison sociale puis cliquer sur « Appliquer »

Cliquer de nouveau sur l’onglet « Entités juridiques » et rechercher la nouvelle raison sociale puis cliquer sur « Voir les détails » de la ligne « Etablissement »

Choisir l’onglet « Enregistrement » puis « Mettre à jour »

Mettre à jour le « Nom enregistré » avec la nouvelle raison sociale et vérifier/remplacer le numéro de SIRET puis cliquer sur « Appliquer »


!!! S’assurer avant d’enregistrer que le Siret est le même que sur le fichier INITSOC car pour certaines sociétés anciennes, il peut avoir été fermé et remplacé par celui de l’INITSOC. Cela génèrerait l’erreur « Invalid Establishment » côté Softa.
       

MAJ.10 : AP : Code Operating Unit
Responsabilité : TOUT_PO_ADMINISTRATEUR
Navigation : Configurer / Organisations / Organisations 
Etape 1 :
Rechercher l’organisation des immobilisations par le nom du livre comptable et remplacer celui-ci.

Exemple : Ancien livre à remplacer :

Nouveau nom du livre :


Etape 2 :
Rechercher l’organisation correspondant au code UO, puis, renommer celle-ci et mettre à jour le code abrégé (Unité opérationnelle / Bouton « Autres » / Operating Unit Information

Exemple : Ancien code UO : DOS0506

Nouveau :

Enregistrer d’abord avant de pouvoir modifier le code abrégé dans le CUF
MAJ.11 : INV : Inventory Org
Pas d’action

MAJ.12 : FA : Livre d’immobilisations
Pas d’action
Désactivation des règles de validations croisées
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Règles
Désactivation temporaire de l’ensemble des règles de validation croisées

Création / modification des Profils de sécurité
Responsabilité : TOUT_FA_ADMINISTRATEUR
Navigation : Configurer / Sécurité / Sécurité
ou
Responsabilité : TOUT_PA_ADMINISTRATEUR
Navigation : Configuration / Ressources et organisations / Fondation HR / Sécurité / Profil
ETAPE 1 : Ajouter les unités opérationnelles aux profils de sécurité de sa région.
Exemple : Ajout de la DRW0506 à la région DRW 

ETAPE 2 : Rechercher puis renommer le profil de sécurité existant pour qu’il corresponde au nom de l’organisation (unité opérationnelle) de transfert (ici de DOS0506 à DRW0506).
Faire une recherche avec %SOCIETE% (Exemple %0506%)

ETAPE 3 : Création des Profils Sécurités CSP
Si l’UO est dans le CSP, il faut ajouter l’UO dans le profil de sécurité CSP correspondant : CSP-LIL ou CSP-LYO (CF table de transco CENTRE_SERVICE_PARTAGE) ainsi que CSP_REF_TOUT et CSP_TOUT :

Si l’UO est Hors CSP, il faut alors l’ajouter dans le profil de Sécurité HCSP de la région concernée (DCWHCSP, DEWHCSP, DLSHCSP, DMSHCSP, DNAHCSP, DOSHCSP, DRWHCSP, DSWHCSP)

ETAPE 4 : Lancer le traitement de mise à jour des listes de sécurité

Ce traitement va mettre à jour les listes de valeurs avec les livres appropriés.
ETAPE 5 : Lancer de nouveau le traitement « Mise à jour des listes de sécurité » avec les paramètres suivants.

ETAPE 6 : S’assurer qu’ils se terminent normalement.


Etapes additionnelles pré-Softa
PR1. 13 : Suppression de la société des jeux de livres
Supprimer la société des jeux de livres « OPERATIONNEL » et « OPERATIONNEL + REFERENCE » et de la région d’origine (DOS en général)

Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Jeux de livres




Attention ! Sortir de l’écran après avoir sauvegardé pour que la compilation soit lancée automatiquement.
Remarque : Si l’une de ces trois suppressions est oubliée, le traitement Softaplay tombe automatiquement en erreur (Too_many_rows).


PR1. 14 : Vérification des fonctions économiques
Vérifier que le site (client pour PA) est bien actif et dispose des fonctions économiques « Facturation » et « Livrer à »
Responsabilité : TOUT_AR_ADMINISTRATEUR
Navigation : Client > Standard
Créer un nouveau site pour le client par défaut paramétré pour PA.
Rechercher le client « CLIENT_POUR_PA »


Ouvrir le détail du compte

Rechercher l’unité opérationnelle (faire attention au statut, si aucun résultat n’est renvoyé pour le statut Actif, relancer la recherche avec d’autres statuts):



Cliquer ensuite sur Détails puis aller sur l’onglet « Fonctions économiques » :

S’il n’y a aucune fonction économique pour cette UO, il faudra cliquer sur le bouton Créer pour créer les deux fonctions « Facturation » et « Livrer à ». Ne pas oublier de cocher la case « Principal » :

Suite à la création des deux fonctions, il y a un id généré pour le lieu, il faut le remplacer par un point :

Remplacer par un Point :

Remarque : 










Ne pas oublier de cliquer sur « Sauvegarder »

PR1. 15 : Réactivation temporaire du type de dépense 
Responsabilité : TOUT_PA_ADMINISTRATEUR
Navigation : Configuration / Dépenses / Types de dépenses
Ouvrir l’écran des types de dépenses et rechercher le type avec la description : FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)

Réactiver momentanément ce type de dépense en supprimant la date de fin :

Traitement SoftaPlay : RàZ et chargement des variables
Rechercher de nouveau l’ID de l’ancienne UO avec cette requête :
SELECT  hou.name, mp.organization_code
FROM    MTL_PARAMETERS_VIEW     mp, 
	HR_ORGANIZATION_UNITS_V hou
WHERE   hou.name LIKE '%0450'
AND mp.organization_id = hou.organization_id
;


Comparer l’information Organization_code avec la colonne Inventory Org Num du fichier de déploiement. S’ils ne sont pas identiques, remplacer cette colonne par l’ID de l’environnement dans lequel le paramétrage est effectué.

Une fois connecté à SoftaPlay, la première opération doit être la suppression des variables correspondantes aux sociétés créées dans un projet précédent. Cette opération (clic droit « Remove ») se fait société par société.


Charger les variables des sociétés du nouveau projet en cliquant sur l’icône « Excel tool » et en sélectionnant le fichier de déploiement (variables)

Traitement SoftaPlay phase 1 : LE, Ledger, OU, Inv Org

Pour passer en mode « Déploiement », clic droit sur le projet « Création Société » puis choisir « Monitor Project »

Extraction des données de la société de référence
➀ Sélectionner l’ensemble des composants 
➁ Cliquer sur le bouton « Extract » et choisir « Yes » dans la boîte de dialogue
➂ A l’issue du traitement, le nombre d’occurrences extraites pour chaque composant est affiché

Appliquer les règles aux enregistrements extraits
Cliquer sur le bouton « Apply » et choisir la ou les sociétés à traiter.

Le résultat de l’Apply est présenté dans une fenêtre avec des combo-box permettant d’afficher composants et sous-composants
On peut revoir les résultats du Apply en cliquant sur les lunettes

Mise à jour de la période FA
Penser à mettre à jour la période FA comme pour la partie création FULL (en fonction de la période en cours et de la clôture FA)🡪 dans la Partie BOOKS CONTROL (Liste déroulante) => Colonne « Initial Date » (Voir copie d’écran above).
Initial Date : en fonction de la date du jour, on déduit sur quelle période FA on est positionné. Si le process de clôture mensuelle est entamé (généralement vers le 24 du mois), on va mettre le premier jour du mois en cours. Si le process de clôture n’est pas en cours, on met le premier jour du mois précédent.
Enregistrer les modifications.

Déploiement des règles pour la ou les sociétés
Sélectionnez tous les traitements, puis lancer « Deploy » et « Load »

Le Deploy renseigne la colonne « Waiting » et le Load, la colonne « Loaded »
Les traitements de paramétrage SoftaPlay sont alors lancés. Les pastilles vertes correspondent à des étapes déroulées avec succès, les jaunes à des erreurs. Le triangle est positionné sur l’étape en cours.

Une fois que la correction est effectuée sur une étape, il faut reprendre le chargement à partir de cette étape, en ayant décoché toutes les étapes précédentes pour ne pas refaire le paramétrage déjà réalisé. Si l’erreur ne nécessite pas de correction, il faut reprendre le chargement à partir de l’étape suivante.


Traitement des incidents connus pendant l’exécution de SoftaPlay

Description Incident
Actions














Ajouter une étape avant l’exécution de SoftaPlay sur l’ensemble des composants ;
Etape de suppression puis de l’ajout de la société aux jeux de livres « OPERATIONNEL », «OPERATIONNEL + REFERENCE », «DOS » (ou région d’origine)
 Attention : Sortir de l’écran après avoir sauvegardé pour que la compilation soit lancée automatiquement.


Résultat :



Rejet lié aux anciennes responsabilités IP :

Ce rejet n’est pas bloquant vu que les responsabilités « Achats » ne sont plus gérées dans Oracle FIN01. Il faudra passer outre et reprendre l’exécution de SoftaPlay à partir de l’étape suivante.





Erreur lors de la phase «Project template »
 









Activation du site DMS0408 et ajout des fonctions économiques « Facturation » & « Livrer à » :






Erreur sur un type de dépense pendant l’étape « Project Template »

Source name       : 61 -1 663
Operating unit    : DCW0450
Template name     : Modèle DCW0450.IMMO

.Project Templates table : 
..No rejection.

.Labor Multipliers table : 
.
.
.
.
.Transaction Controls table : 
..Invalid expenditure type
....EXPENDITURE_TYPE (EXPENDITURE_CATEGORY): FORMATION PRLVTS VOLONTAIRES (NON_SIGNIFICATIF)

Cause : Le type de dépense a été désactivé au 31/12/2023



Ouvrir l’écran des types de dépenses

Réactiver momentanément ce type de dépense en supprimant la date de fin :


Relancer ensuite l’exécution SoftaPlay à partir de l’étape de l’erreur

Remettre à nouveau la date de fin pour ce type de dépense :






Vérifier au niveau de l’établissement de l’entité juridique, onglet Enregistrement si le Siret est le même que celui du fichier INITSOC car souvent il faut l’actualiser.



Si le SIRET est identique, passer outre et continuer


Post Création Softa
Ajouter les livres aux jeux de livres OPERATIONNEL, OPERATIONNEL+REFERENCE et sur la nouvelle région


Mise à jour du champ Latest_Opened_Period_Name de la table GL_LEDGERS avec la dernière période ouverte
Suite aux opérations SoftaPlay, l’écran de consultation des périodes s’ouvre systématiquement sur la première période ouverte pour la société, en l’occurrence MAI-21.
L’origine du problème est que le champ Latest_Opened_Period_Name de la table GL_LEDGERS est nul au lieu d’être renseigné avec la dernière période ouverte.
Solution :
Mise à jour du champ Latest_Opened_Period_Name de la table GL_LEDGERS avec la dernière période ouverte.
Verification :
SELECT ledger_id, name, first_ledger_period_name, latest_opened_period_name
FROM gl_ledgers
where name like '%SVD%116%';

Récupérer le ledger_id puis lancer cette requête :
select *
from gl_period_statuses
where closing_status = 'O'
and application_id = 101
and set_of_books_id = #Ledger_id
;

Mise à jour : Récupérer le Period_name de la requête précédente et l’utiliser dans cette requête :
UPDATE gl_ledgers
SET latest_opened_period_name =  'AVR-23' --Period_name récupéré
WHERE name like '%SVD%116%';


Vérifier la création des nouvelles règles de validation croisée
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Règles
Rechercher les règles « STE-PARTENAIRE » et « STE-REGION » (F11+ « STE% »)

Sélectionner une règle puis cliquer dans le tableau des conditions de la règle, les segments de la clé comptable flexible s’affichent automatiquement.
Cliquer sur « Annuler » pour revenir à l’écran :

Rechercher par « %société% » 

Puis créer une ligne similaire avec les touches Shift+F6.

Remplacer le segment « InterCo » par le nouveau code UO :

Enregistrer les modifications
Case « Utiliser l'abonnement de l'entité juridique » non cochée
Responsabilité : Administrateur des taxes
Navigation : Configuration fiscale / Régimes fiscaux
Onglet Parties => Profils fiscaux de partie
Recherche avec :
« Type de partie » = Unité opérationnelle propriétaire du contenu de taxe
« Nom de la partie » = Code UO

Cliquer sur « Accéder » puis sur « Voir un profil fiscal » : La case « Utiliser l'abonnement de l'entité juridique » est non cochée et inactive

Pour la réactiver, lancer la requête suivante pour s’assurer que seules les UOs en cours de transfert présentent cette anomalie :
select use_le_as_subscriber_flag 
from zx_party_tax_profile 
where party_type_code = 'OU' 
and use_le_as_subscriber_flag is null 
;


Si les résultats sont cohérents avec les UOs en cours de transfert, c’est-à-dire que la requête renvoie autant de lignes qu’il y a d’UO transférées, appliquer cet ordre SQL afin de cocher cette case :
update zx_party_tax_profile
set  use_le_as_subscriber_flag='Y'
where party_type_code = 'OU' 
and use_le_as_subscriber_flag is null ;


La case à cocher est activée :

Désactiver le type de dépense FORMATION PRLVTS VOLONTAIRES
Responsabilité : TOUT_PA_ADMINISTRATEUR
Navigation : Configuration / Dépenses / Types de dépenses
Remettre la date de fin au type de dépense FORMATION PRLVTS VOLONTAIRES


Réactivation de l’ensemble des règles de validation croisées
Responsabilité : TOUT_GL_OPE_ADMINISTRATEUR
Navigation : Configurer / Financials / Champ Flexibles / Clé / Règles
Réactivation de l’ensemble des règles de validation croisées :


2.16 Vérifier que l’origine de mouvement SYSTEME_AMONT_2025 (année en cours ou à venir) est bien créé :
Responsabilité : TOUT_AR_ADMINISTRATEUR
Navigation : Configuration / Mouvements / Origines
Rechercher l’unité opérationnelle et l’origine « SYST% »



Remarque : Il arrive dans certains cas que cette origine de mouvement ne se crée pas (Bug Softaplay). Dans ce cas, il faut la créer manuellement en sélectionnant une existante dans une autre UO puis cliquer sur « Nouvel enregistrement » puis en appuyant sur Shift+F6

Remplacer ensuite les champs Unité opérationnelle et Entité juridique par les informations de la société créée :


PARTIE MOA
Traitements de mise à jour
Définir les options fournisseurs/bénéficiaires
Se connecter sur la Responsabilité Administration Exploitation Dalkia
Lancer le traitement : DKA : Creation des options fournisseurs et beneficiaires
Entrer en paramètre l’UO 


PO : Attachement des conditions générales d'achat à l'UO

Se connecter sur la Responsabilité Admnistration Exploitation Dalkia
Lancer le traitement : DKA : Attachement des CGA


Compte bancaires – Autorisés le livre pour la gestion des banques
Se connecter avec Sysadmin et le mot de passe de Sysadmin (En Anglais)
Responsabilité User Management => Puis Menu Roles et Role Inhe



Puis cliquer sur Update 

Puis cliquer sur Security Wizards

Sur la ligne CE UMX Security wizard  Cliquer sur Wizard

Il faut ajouter le nouveau Livre 
Pour cela cliquer sur Add Legal Entities

Choisir le livre dans la Liste de valeur et le sélectionner

Puis cliquer sur Use et Maintenance pour le nouveau Livre et cliquer sur Apply pour enregistrer

Cliquer de nouveau sur Apply

Post Création Softa – Module GL

Vérifier le segment équilibrage au niveau Etablissement
Responsabilité TOUT_GL_OP_ADMINISTRATEUR
Menu Configuration Comptable / Entité Comptable / Etablissements

Cliquer sur Détails

Puis cliquer sur Segment d’équilibrage

Puis cliquer sur Mettre à jour et ajouter le segment d’équilibrage de la société 

Paramétrage Taxe dans GL
Avant il faut ajouter le nouveau Livre créé dans le jeu de livre OPERATIONNEL

Responsabilité TOUT GL OP
Menu : Configurer / Taxe Options de taxe

Retirer la société du Jeu de livres

Ajouter le nouveau Livre (et UO) dans les jeu de livres
Pour le livre => Il y a 2 jeu de Livres : 
OPERATIONNEL
OPERATIONNEL + REFERENCE 



Et pour la région 

Attention il existe plusieurs Jeu de Livres :


Création du paramétrage Pièce Répétitive (Abonnements GL)
Il faut créer les En têtes de 2 abonnements pour le nouveau Livre 
YYYY XXX (Exemple 0423 DOS)
YYYY XXX IFRS (Exemple 0423 DOS IFRS)

Et 


Création du paramétrage Pièce Répétitive (Equilibre CDG) pour les Multi Régions

Post Création Softa – Module ETAX

Ajouter le nouveau Livre dans la Configuration Fiscale FR
Depuis la Responsabilité Administration Taxe
Menu Configuration Fiscale / Régimes Fiscaux
Mettre le code Pays France et ensuite cliquer sur Accéder

Cliquer sur Mettre à jour

Puis cliquer sur Continuer

Cliquer sur Ajouter parties
Et chercher le nouveau livre  et sélectionnez le
Puis cliquer sur Terminer (2 fois avec messages + de 300 Lignes)


Ajouter l UO dans la partie
Partie / Profils fiscaux de partie
Type de partine : UO
Nom : XXXYYYY (Nom de l’UO exemple DOS0423)
Puis cliquer sur accéder

Puis clique sur Créer un profil Fiscal


Cocher utiliser l’abonnement de l’entité juridique
Et clqiue sur Appliquer


Post Création Softa – Module PA

Vérifier le code AFFAIRE sur le modèle de PROJET ORGANIQUE :
Se connecter sur la Responsabilité XXXYYY_PA_ADMINISTRATEUR => Mettre le code AFFAIRE ci-dessous le sur modèle de projet ORGANIQUE : A00000000A


Création des modèles ACCORD CADRE
Se connecter depuis la  Responsabilité XXXYYYY_PA_ADMINISTRATEUR
Menu : Confirguation / Facturation / Modele Accord cadre
Il faut créer 3 modèles accords Cadre :
OPERATIONNEL
ORGANIQUE
REFAC
OPERATIONNEL 

Puis cliquer sur Financement

Puis cliquer sur la Disquette pour sauvegarder
ORGANIQUE

Puis cliquer sur Financement

Puis cliquer sur la Disquette pour sauvegarder
REFAC

Puis cliquer sur Financement

Cliquer sur la disquette pour enregistrer

Création des Modèles de budgets
Il faut se connecter depuis la responsabilité XXXYYY_PA_ADMINISTRATEUR
Puis dans le menu BUDGETS
Il faut créer 3 Modèles de Budgets : 
OPERATIONNEL
ORGANIQUE
REFAC
OPERATIONNEL 
Dans le numero de Projet => Rechercher le Projet OPERATIONNEL
Puis Saisissez la version du Budget

Enregistrer sur la Disquette
Puis cliquer sur Budget Provisoire
Puis cliquer sur Détail

Cliquer sur la disquette pour enregistrer et fermer la fenêtre
Cliquer ensuite sur soumettre

Puis cliquer sur Budget de Référence

Le budget devient Actuel
	

Cliquer sur la disquette pour sauvegarder

Il faut faire la même chose pour :
DOS0423.OGRANIQUE 
DOS0423.REFAC





Création du projet de REFAC 
Se connecter sur la Responsabilité XXXYYY_PA_ADMINISTRATEUR
Menu Configurer / Projets / Modèles de projets
Création Manuelle du projet de REFAC, il faut partir du Modèle REFAC et cliquer sur Copier vers
Numéro du projet = XXXYYYY (DOS0423)
Nom du projet :  DOS0423-REFAC
Description du projet :  DOS0423-REFAC
Centre Fi du projet : selon la région (Exemple DOS = B00000001B)
Date de début : 01/01/1951

Se placer sur le modèle et cliquer sur Copier vers
Remplir les zones et cliquer sur OK


MAJ de l’organisation 
Il faut mettre la TF DIAPASON 


Paramétrage sur perso écran AR (Mouvements et Règlements)

Ecran de saisie des mouvements AR 
Il faut aller sur l’écran de saisie des mouvements AR depuis la Responsabilité TOUT_AR_ADMIN

Il faut ajouter 2 responsabilités et cliquer sur Enregistrer puis fermer l’écran


Ecran de saisie des règlements AR

Il faut aller sur l’écran de saisie des règlements AR depuis la responsabilité TOUT_AR_ADM


Et la il faut ajouter les 3 Responsabilités ci-dessous


Paramétrage Comptes Non Soldés AR et AP

Paramétrages comptes collectifs – Comptes non soldés AR

Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configuration / Comptabilité / Définition des listes de soldes comptes ouverts
Code : CLIENTS_YYYY  (Exemple = CLIENTS_0423)
Nom : CLIENTS_YYYY  (Exemple = CLIENTS_0423)
Description : Balances Clients YYYY (Exemple = Balance clients 0423)
Coté du solde : Débit
Actif : oui


Paramétrages comptes collectifs – Comptes non soldés AP
Responsabilité TOUT_AP_ADMINISTRATEUR
Menu : Configurer / Configuration Comptable / Définition des soldes des comptes non ouverts


Paramétrage compte bancaire interne Dalkia

Création du compte bancaire – Resp TOUT_AP_ADMINISTRATEUR





Ajouter la nouvelle UO créée 





Puis cliquer sur TERMINER

Le compte bancaire interne a été créé : 

Ensuite il faut créer les Titres de paiements => Cliquer sur Gérer les titres de paiements

Cliquer sur Créer


Puis créer le compte 585000 pour la nouvelle société 
0423_DOS_585000
Compte de trésorerie = 0423.DOS.585000.14300.0.0.0.0.0.0.0.0
Sur la Banque TRESORERIE INTERNE (99999) et sur l’Agence COMPTE DE LIAISON (99999)

Avec 3 titres de paiements : 

Puis il faut créer les Modèles instructions de règlements 

Puis côté AR, il faut créer les modes de Règlements AR -> CHEQUE ET VIREMENT
Responsabilité TOUT_AR_ADMINISTRATEUR 
Menu Configurer / Règlements / Classes de règlements

Post Création Softa – Création des modes de Règlements AR

Création des modes de règlements VIREMENT sur 51* et 585*
Se connecter sur Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configurer / Règlement / Classe de règlement



Création des modes de règlements CHEQUE sur 51* et 585*
Se connecter sur Responsabilité TOUT_AR_ADMINISTRATEUR
Menu : Configurer / Règlement / Classe de règlement


Affectation des séquences
Il faut ensuite affecter les séquences aux livres créés
Se connecter sur Administraction Exploitation Dalkia
Menu : Application / Numérotation des pièces / Affecter


Paramétrage pour intagra groupe AP/AR
Se connecter sur la Responsabilité TOUT AR ADMINISTRATEUR
Menu Configurer /  Règlement / Origines de règlements
Faire F11 et indiquer l’UO 

Puis CTRL F11

Il faut compléter : Le Mode de règlement et la banque

Puis Sauvegarder
Puis il faut aller dans Configurer / Règlement / Interface de règlements / Interface de Règlements


Ongle Règlements

Onglets Mouvements


Post Création Softa – Ouverture des périodes TOUS MODULES

Pré requis => Il faut que le LIVRE soit présent dans le Jeu de Livre OPERATIONNEL

Ouverture période GL
Se connecter depuis la Responsabilité TOUT_GL_OP_ADMINISTRATEUR
Menu Configurer / Ouvrir – Fermeture
Indiquer le livre 

Puis cliquer sur Rechercher et Ouvrir la période

Ouverture période PA
Ouverture période AP
Ouverture période AR
Ouverture période PO
Ouverture période FA

Post Création Softa

PCS01 : GL, Règles de validation croisée
Réactivation des règles de validation croisées :
CE-RG : Centre - Resultat Compte Analytique
CE-RL : Centre - Resultat Compte Local
GRP-FLUX : Gére les combinaisons Cpte Analytique / Flux autorisée
