# Risques et plan de validation

Plan proposé à partir des sources locales. Aucune vérification en base effectuée. P1 : fiabilité de l’intégration et de sa preuve ; P2 : robustesse d’exploitation.

## Actions prioritaires

| Priorité | Constat local | Vérification et résultat attendu |
|---|---|---|
| P1 | Reporting AP marqué OK avant résultat APXIIMPT ; voir note AP | Suivre un fichier et une facture jusqu’à AP_INVOICES_ALL ; distinguer staging, dépôt interface, import final et rejet |
| P1 | Doublons et suppressions AR ; voir note AR | En recette, vérifier clés métier, montants, organisations et distributions ; aucune perte ni distribution orpheline |
| P1 | `Projet_Dashboard/sql/12_nuit_erreurs_programme.sql:5-6` : virgule absente | Revue puis validation syntaxique en recette ; CSV d’erreurs produit et daté |
| P1 | `Projet_Dashboard/sql/19_demat_par_jour.sql:9` : incrément de 2 | Recalcul sur statuts connus, autres et NULL ; catégories cohérentes avec le total |
| P1 | `KDFI-2198-ControleFlux/README.md:96-116` et `177-181` : règles de signe contradictoires | Vérifier facture, avoir et annulation d’avoir à chaque étape ; éviter la double inversion |
| P1 | Réinitialisations et corrections directes avec COMMIT ; voir notes AP/AR | Revoir périmètre et frontières transactionnelles ; limiter la reprise au lot visé et définir une compensation |
| P2 | Chemins XLA/RCV divergents ; voir note comptabilité | Réconcilier un même échantillon de distributions, réceptions et commandes sans multiplication de lignes |
| P2 | Copies Xerox et variante ETI1 ; voir note AP | Comparer au code compilé et aux prérequis de chaque environnement ; désigner la version de référence |
| P2 | `ScriptsLanceurCentrale/D2_interface_statuts.sql` contient un manifeste CSV | Vérifier chemins et configuration du lanceur ; faire correspondre chaque contrôle au fichier SQL réel |
| P2 | Documentation historique et cibles image contradictoires | Réconcilier documentation, paramétrage, code de référence et résultat observé |

## Recette de bout en bout

| Cas | Échantillon minimal | Critères de réussite |
|---|---|---|
| AP nominal | XGS, ZCI, DSP ; plusieurs UO ; avec/sans PO | Fichier → staging → interface → requête concurrente → facture finale → reporting rapprochés |
| AP rejeté | Fournisseur/site absent, période fermée, région ou taxe invalide | Cause lisible, absence de faux succès, correction puis reprise traçable |
| Relance | Même fichier deux fois, interruption avant/après COMMIT, import standard en erreur | Aucun doublon métier ; distinguer reliquat en interface et facture déjà créée |
| Dématérialisation | OCR/DMT si variante effectivement déployée | Fichier, source/group_id, statut facture et statut image contrôlés séparément |
| AR | Facture, avoir, annulation ; plusieurs lignes et distributions | Volumes et montants signés cohérents entre staging, interface et transaction finale |
| Doublons AR | Clés identiques, distributions identiques puis différentes | Doublon réel établi ; ligne conservée justifiée et traçabilité préservée |
| Notes de frais | Période fermée puis nouvelle période | Dates métier/comptables, source Notilus et fichier cohérents |
| Images | Facture finale avec image absente ou URL invalide | Résultat image distinct du résultat comptable ; cible de renvoi confirmée |
| Clôture | Réception partielle, facture ultérieure, avoir | Provision et reprise justifiées par commande, réception et comptabilité |
| Supervision | Erreur, avertissement, traitement absent, CSV périmé | Absence d’exécution et fraîcheur détectées en plus du contenu du dernier export |

## Informations à compléter

- Versions déployées des packages, tables, vues et programmes, dont les `.pkb/.pks` référencés hors revue principale.
- Contrat de chaque flux : producteur, format, encodage, clé fichier/facture, date métier, totaux, signe, accusé et rétention.
- Référentiel des sources/folios, correspondances société/UO/région, paramètres concurrents et dépendances Control-M/Talend.
- Définition métier de « facture intégrée » et règles de rapprochement à chaque étape.
- Volumes, seuils, horaires attendus, responsables et délais de résolution.
- Purge des interfaces/historiques, sauvegarde avant correction, relances partielles et gestion de concurrence.

Les responsables et échéances restent à attribuer ; ils ne peuvent pas être déduits des scripts.
