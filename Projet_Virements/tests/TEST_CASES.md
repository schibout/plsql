# Cas de recette Apps Script

1. Exécuter `runVirementUnitTests` : tous les tests doivent réussir.
2. Exécuter `diagnoseMailImports` : vérifier un bilan pour `virements_eur`,
   `prelevements_cashcollection` et `prelevements_oracle_edf`, ainsi que
   l'adresse `quartz.messenger@treasury-factory.com` pour `virements_eur`.
3. Exécuter `setupMailImportProject`, puis `processMailImports`.
4. Vérifier qu'aucun sous-dossier n'est créé, que le fichier est placé dans le
   dossier racine sous `DDMMYYYY_nom-original.ext` et que sa description contient
   le marqueur configuré et `MAIL_IMPORT_FLOW=`.
5. Relancer `processMailImports` : aucun doublon ne doit apparaître.
6. Ajouter un nouveau message à une conversation déjà labellisée et relancer :
   le nouveau message doit être traité.
7. Vérifier que chaque profil de prélèvements écrit dans son propre dossier Drive et
   possèdent des libellés, états et marqueurs Drive indépendants.
8. Exécuter `createMailImportTimeDrivenTrigger` deux fois : un seul déclencheur
   horaire compatible doit exister. Un ancien déclencheur de 15 minutes doit
   avoir été remplacé au premier appel.
