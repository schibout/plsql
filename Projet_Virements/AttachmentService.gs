/**
 * Retourne toutes les pièces jointes autorisées par le profil et le nombre de
 * fichiers ignorés. Une absence totale de fichier accepté est une erreur pour permettre une
 * nouvelle tentative ultérieure.
 * @private
 */
function virementExtractAttachments_(message, flow) {
  const activeFlow = flow || VIREMENT_CONFIG;
  const attachments = message.getAttachments({
    includeInlineImages: false,
    includeAttachments: true,
  });
  const candidates = [];
  let skipped = 0;

  attachments.forEach(function(attachment) {
    const originalName = virementSanitizeFileName_(
      attachment.getName() || 'piece_jointe_sans_nom'
    );
    if (!virementIsAllowedAttachment_(
      originalName,
      activeFlow.ALLOWED_EXTENSIONS
    )) {
      skipped++;
      mailImportFlowLog_(activeFlow, 'INFO', 'Pièce jointe ignorée.', {
        messageId: message.getId(),
        fileName: originalName,
      });
      return;
    }
    candidates.push({
      blob: attachment.copyBlob(),
      originalName: originalName,
    });
  });

  if (candidates.length === 0) {
    throw new Error(
      'Le message ne contient aucune pièce jointe autorisée pour le flux "' +
      activeFlow.ID + '" (' + activeFlow.ALLOWED_EXTENSIONS.join(', ') + ').'
    );
  }
  return {candidates: candidates, skipped: skipped};
}

/** Alias historique du flux Virements EUR. @private */
function virementExtractExcelAttachments_(message) {
  return virementExtractAttachments_(message, VIREMENT_CONFIG);
}
