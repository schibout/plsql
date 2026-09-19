/**
 * Enregistre un CSV dans Drive sans écrasement et avec une métadonnée permettant
 * de reconnaître le même message après une relance.
 * @private
 */
function ctmSaveCsv_(folder, csvCandidate, message) {
  const messageId = message.getId();
  const baseName = ctmBuildFileName_(
    message.getDate(),
    csvCandidate.originalName,
    CTM_CONFIG.TIME_ZONE
  );
  const marker = CTM_CONFIG.DRIVE_MESSAGE_MARKER_PREFIX + messageId;

  for (let collision = 1; collision <= CTM_CONFIG.MAX_FILENAME_COLLISIONS; collision++) {
    const candidateName = collision === 1
      ? baseName
      : ctmAddCollisionSuffix_(baseName, collision);
    const files = folder.getFilesByName(candidateName);
    let nameAlreadyUsed = false;

    while (files.hasNext()) {
      nameAlreadyUsed = true;
      const existingFile = files.next();
      if (ctmFileHasMessageMarker_(existingFile, marker)) {
        ctmLog_('INFO', 'Fichier déjà créé pour ce message, réutilisé.', {
          messageId: messageId,
          fileName: candidateName,
          fileId: existingFile.getId(),
        });
        return {
          file: existingFile,
          fileName: candidateName,
          created: false,
        };
      }
    }

    if (nameAlreadyUsed) continue;

    const blob = csvCandidate.blob.copyBlob().setName(candidateName);
    let createdFile = null;
    try {
      createdFile = folder.createFile(blob);
      createdFile.setDescription([
        marker,
        'CTM_RECEIVED_AT=' + message.getDate().toISOString(),
        'CTM_ORIGINAL_NAME=' + csvCandidate.originalName,
      ].join('\n'));

      ctmLog_('INFO', 'CSV sauvegardé dans Drive.', {
        messageId: messageId,
        fileName: candidateName,
        fileId: createdFile.getId(),
      });
      return {
        file: createdFile,
        fileName: candidateName,
        created: true,
      };
    } catch (error) {
      // Si la création a réussi mais pas l'écriture de la métadonnée, on retire
      // le fichier incomplet afin qu'une relance ne produise pas un faux doublon.
      if (createdFile) {
        try {
          createdFile.setTrashed(true);
        } catch (rollbackError) {
          ctmLog_('ERROR', 'Impossible de placer le fichier incomplet dans la corbeille.', {
            fileId: createdFile.getId(),
            error: ctmErrorMessage_(rollbackError),
          });
        }
      }
      throw new Error(
        'Échec de création Drive pour "' + candidateName + '" : ' + ctmErrorMessage_(error)
      );
    }
  }

  throw new Error(
    'Impossible de générer un nom libre après ' +
    CTM_CONFIG.MAX_FILENAME_COLLISIONS + ' collisions.'
  );
}

/** @private */
function ctmFileHasMessageMarker_(file, marker) {
  try {
    return String(file.getDescription() || '')
      .split(/\r?\n/)
      .indexOf(marker) !== -1;
  } catch (error) {
    ctmLog_('WARN', 'Description Drive illisible pendant le contrôle de doublon.', {
      fileId: file.getId(),
      error: ctmErrorMessage_(error),
    });
    return false;
  }
}
