function UpdateCloture() {
  var anciennePeriode = 'AVR-26';
  var nouvellePeriode  = 'MAI-26';
  var dossierSource    = '1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl';

  var file_to_create;
  var files = DriveApp.searchFiles('parents in "' + dossierSource + '" and mimeType contains "SQL"');

  var totalFiles = 0;
  var modifiedFiles = 0;

  console.log('=== Début de l\'exécution UpdateCloture ===');
  console.log('Remplacement : "' + anciennePeriode + '" → "' + nouvellePeriode + '"');

  while (files.hasNext()) {
    totalFiles++;
    var file = files.next();
    var file_blob = file.getBlob();
    var text = file_blob.getDataAsString();

    console.log('--- Traitement du fichier #' + totalFiles + ' ---');
    console.log('Nom       : ' + file.getName());
    console.log('ID        : ' + file.getId());
    console.log('Type MIME : ' + file.getMimeType());
    console.log('Taille    : ' + file_blob.getBytes().length + ' octets');

    var occurrences = (text.match(new RegExp(anciennePeriode, 'g')) || []).length;
    console.log('Occurrences "' + anciennePeriode + '" trouvées : ' + occurrences);

    if (occurrences > 0) {
      text = text.split(anciennePeriode).join(nouvellePeriode);
      file_blob.setDataFromString(text);

      file_to_create = Drive.Files.update({
        title: file.getName(), mimeType: file.getMimeType()
      }, file.getId(), file_blob, {supportsAllDrives: true});

      var parents = Drive.Files.get(file.getId(), {supportsAllDrives: true, fields: 'parents'});
      var folderName = '';
      if (parents && parents.parents && parents.parents.length > 0) {
        var folder = DriveApp.getFolderById(parents.parents[0].id);
        folderName = folder.getName();
      }

      modifiedFiles++;
      console.log('✔ Fichier mis à jour : ' + file.getName() + ' | Dossier : ' + folderName);
    } else {
      console.log('⚠ Aucune occurrence trouvée, fichier ignoré : ' + file.getName());
    }
  }

  console.log('=== Fin de l\'exécution ===');
  console.log('Fichiers analysés : ' + totalFiles);
  console.log('Fichiers modifiés : ' + modifiedFiles);
}