# Cas de recette Apps Script

1. Exécuter `runVirementUnitTests` : tous les tests doivent réussir.
2. Exécuter `diagnoseMailImports` : vérifier un bilan par profil actif et
   l'adresse `quartz.messenger@treasury-factory.com` pour `virements_eur`.
3. Exécuter `setupMailImportProject`, puis `processMailImports`.
4. Vérifier le sous-dossier Drive `JJMMAAAA`, le nom original du classeur et la
   description contenant le marqueur configuré et `MAIL_IMPORT_FLOW=`.
5. Relancer `processMailImports` : aucun doublon ne doit apparaître.
6. Ajouter un nouveau message à une conversation déjà labellisée et relancer :
   le nouveau message doit être traité.
7. Ajouter un second profil de recette avec un autre état et une autre extension,
   puis vérifier que les deux bilans et destinations restent indépendants.
8. Exécuter `createMailImportTimeDrivenTrigger` deux fois : un seul déclencheur
   horaire compatible doit exister. Un ancien déclencheur de 15 minutes doit
   avoir été remplacé au premier appel.
