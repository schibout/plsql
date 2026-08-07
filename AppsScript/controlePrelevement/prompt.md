Rôle : Tu es un expert en développement Google Apps Script et en automatisation Google Workspace.

Objectif : Écris un script Google Apps Script (GAS) complet qui analyse ma boîte Gmail pour trouver des e-mails spécifiques, télécharge leurs pièces jointes et les enregistre dans un dossier Google Drive spécifique.

Critères de recherche des e-mails :

Le script doit prendre une date d'entrée (fournie manuellement pour les tests, ou basée sur la date du jour pour l'automatisation) et vérifier les e-mails reçus exactement à cette date moins 3 jours (Date d'entrée - 3 jours).

Il doit rechercher uniquement les e-mails ayant l'un de ces deux objets exacts :

[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection

[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF

Gestion du dossier Google Drive et des pièces jointes :

Le script doit enregistrer les fichiers dans un dossier Google Drive nommé Controle_Transfert (le script doit créer le dossier s'il n'existe pas).

Horodatage : Chaque pièce jointe sauvegardée doit être renommée en y ajoutant un horodatage basé sur l'heure de réception du mail au format AAAAMMJJ_HHMM_NomDuFichier.

Livrables attendus :

Le code Google Apps Script complet, propre et commenté (avec une fonction de test manuel pour saisir une date d'entrée, et une fonction automatique à planifier).

Des explications simples pour savoir comment planifier l'exécution automatique du script chaque jour.