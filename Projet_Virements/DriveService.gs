/** @private */
function virementGetDateFolder_(parentFolder, messageDate, flow) {
  const activeFlow = flow || VIREMENT_CONFIG;
  if (!activeFlow.CREATE_DATE_SUBFOLDER) return parentFolder;
  const folderName = virementDateFolderName_(
    messageDate,
    activeFlow.TIME_ZONE,
    activeFlow.SUBFOLDER_DATE_FORMAT
  );
  const existing = parentFolder.getFoldersByName(folderName);
  if (existing.hasNext()) return existing.next();
  const created = parentFolder.createFolder(folderName);
  mailImportFlowLog_(activeFlow, 'INFO', 'Sous-dossier Drive créé.', {
    folderName: folderName,
  });
  return created;
}

/** @private */
function virementSaveAttachment_(folder, attachmentCandidate, message, flow) {
  const activeFlow = flow || VIREMENT_CONFIG;
  const messageId = message.getId();
  const baseName = mailImportBuildOutputFileName_(
    attachmentCandidate.originalName,
    message.getDate(),
    activeFlow
  );
  const marker = activeFlow.DRIVE_MESSAGE_MARKER_PREFIX + messageId;

  for (let collision = 1;
    collision <= MAIL_IMPORT_ENGINE_CONFIG.MAX_FILENAME_COLLISIONS;
    collision++) {
    const candidateName = collision === 1
      ? baseName
      : virementAddCollisionSuffix_(baseName, collision);
    const files = folder.getFilesByName(candidateName);
    let nameAlreadyUsed = false;

    while (files.hasNext()) {
      nameAlreadyUsed = true;
      const existingFile = files.next();
      if (virementFileHasMarker_(existingFile, marker)) {
        return {file: existingFile, fileName: candidateName, created: false};
      }
    }
    if (nameAlreadyUsed) continue;

    const blob = attachmentCandidate.blob.copyBlob().setName(candidateName);
    let createdFile = null;
    try {
      createdFile = folder.createFile(blob);
      createdFile.setDescription([
        marker,
        'MAIL_IMPORT_FLOW=' + activeFlow.ID,
        'MAIL_RECEIVED_AT=' + message.getDate().toISOString(),
        'MAIL_ORIGINAL_NAME=' + attachmentCandidate.originalName,
      ].join('\n'));
      return {file: createdFile, fileName: candidateName, created: true};
    } catch (error) {
      if (createdFile) {
        try {
          createdFile.setTrashed(true);
        } catch (rollbackError) {
          mailImportFlowLog_(
            activeFlow,
            'ERROR',
            'Fichier incomplet à supprimer manuellement.',
            {
              fileId: createdFile.getId(),
              error: virementErrorMessage_(rollbackError),
            }
          );
        }
      }
      throw new Error(
        'Échec de création Drive pour "' + candidateName + '" : ' +
        virementErrorMessage_(error)
      );
    }
  }
  throw new Error(
    'Impossible de générer un nom libre après ' +
    MAIL_IMPORT_ENGINE_CONFIG.MAX_FILENAME_COLLISIONS + ' collisions.'
  );
}

/** @private */
function virementFileHasMarker_(file, marker) {
  try {
    return String(file.getDescription() || '').split(/\r?\n/).indexOf(marker) !== -1;
  } catch (error) {
    virementLog_('WARN', 'Description Drive illisible.', {
      fileId: file.getId(),
      error: virementErrorMessage_(error),
    });
    return false;
  }
}
