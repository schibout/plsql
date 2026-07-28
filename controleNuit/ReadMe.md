# Contrôle Quotidien – Mode d’emploi

## Objectif
Ce dossier contient le script de contrôle quotidien exécuté chaque matin pour vérifier :
- Les flux DSP (iValua)
- Les notes de frais (Notilus)
- Les factures (Xerox, Tradeshift, DSP)
- Les écritures GL
- Les traitements concurrents de la nuit
- Le rapprochement bancaire (RB)

## Fichier principal
- Controle_Quotidien_Complet.sql

## Prérequis
- Exécution sous SQL Developer
- Accès aux tables EBS (AP, GL, FND, RB, DKA_*)

## Paramètres à ajuster (Section 1)
Dans le script, modifier si besoin :
- v_nb_jours_histo : nombre de jours d’historique
- v_heure_fermeture : heure de fermeture du service (par défaut 19h)
- v_heure_ouverture : heure d’ouverture (par défaut 7h)

## Mode d’exécution
1. Ouvrir Controle_Quotidien_Complet.sql dans SQL Developer.
2. Exécuter la Section 1 (bloc de paramètres).
3. Lancer le script complet (F5) pour générer le rapport.

## Lecture des résultats
Le script affiche des titres avant chaque requête :
- DSP – Détail des flux
- DSP – Synthèse par jour et type
- NOTILUS – Comptage des notes de frais
- FACTURES – Synthèse par source
- XEROX – Factures sans image / avec image
- GL – Interface et lignes créées
- NUIT – Synthèse, erreurs, warnings, traitements longs, en cours
- RB – Importation des relevés

## Alertes automatiques
Le script affiche des alertes si :
- Flux DSP < 5 jours ouvrés
- Erreurs ou warnings de nuit
- Factures Xerox sans image
- Lundi sans import RB (rappel fichier SG)

## Recommandations d’exploitation
- Exécuter chaque matin avant 9h.
- En cas d’erreur, consulter la section NUIT – Détail des ERREURS.
- Sur anomalies DSP, vérifier les fichiers manquants.
- Sur Xerox sans image, traiter avant validation AP.

## Historique
- 04/02/2026 : Création du script quotidien complet et du présent mode d’emploi.
