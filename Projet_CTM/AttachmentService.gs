/**
 * Extrait l'unique CSV attendu parmi les pièces jointes d'un message.
 * Aucun fichier Drive n'est créé tant que la cardinalité n'a pas été validée.
 * @private
 */
function ctmExtractSingleCsv_(message) {
  const attachments = message.getAttachments({
    includeInlineImages: false,
    includeAttachments: true,
  });
  const candidates = [];

  ctmLog_('INFO', 'Pièces jointes détectées.', {
    messageId: message.getId(),
    count: attachments.length,
  });

  attachments.forEach(function(attachment) {
    const attachmentName = attachment.getName() || 'piece_jointe_sans_nom';
    const contentType = attachment.getContentType();

    if (ctmIsZip_(attachmentName, contentType)) {
      ctmLog_('INFO', 'Archive ZIP détectée.', {
        messageId: message.getId(),
        attachment: attachmentName,
      });

      let entries;
      try {
        entries = Utilities.unzip(attachment.copyBlob());
      } catch (error) {
        throw new Error(
          'Archive ZIP illisible "' + attachmentName + '" : ' + ctmErrorMessage_(error)
        );
      }

      entries.forEach(function(entry) {
        const entryName = entry.getName() || '';
        if (!ctmIsCsv_(entryName, entry.getContentType())) {
          ctmLog_('INFO', 'Entrée ZIP ignorée car non CSV.', {
            messageId: message.getId(),
            entry: entryName,
          });
          return;
        }
        candidates.push({
          blob: entry.copyBlob(),
          originalName: entryName,
          sourceAttachment: attachmentName,
        });
      });
      return;
    }

    if (ctmIsCsv_(attachmentName, contentType)) {
      candidates.push({
        blob: attachment.copyBlob(),
        originalName: attachmentName,
        sourceAttachment: attachmentName,
      });
      return;
    }

    ctmLog_('INFO', 'Pièce jointe ignorée car non CSV/ZIP.', {
      messageId: message.getId(),
      attachment: attachmentName,
      contentType: contentType,
    });
  });

  if (candidates.length !== 1) {
    throw new Error(
      'Le message doit contenir exactement un CSV exploitable ; ' +
      candidates.length + ' trouvé(s).'
    );
  }

  candidates[0].originalName = ctmEnsureCsvExtension_(
    ctmSanitizeFileName_(candidates[0].originalName)
  );
  return candidates[0];
}
