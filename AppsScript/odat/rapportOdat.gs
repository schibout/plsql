/**
 * Rapport quotidien Control-M — application FIN-FINANCE.
 *
 * Le rapport Control-M arrive chaque jour par e-mail sous forme d'une archive
 * 'Report_ctm_<AAMMJJ>_13_<Mois_Année>.zip' contenant un unique CSV. Ce CSV couvre une
 * vingtaine d'applications et ~1260 tâches : ce script en isole FIN-FINANCE et n'envoie
 * un e-mail que s'il contient au moins un job en échec.
 *
 * Tout se fait EN MÉMOIRE : aucun fichier n'est écrit sur Drive.
 *
 * Fonctions à exécuter / planifier :
 *   - odat_runReport()   : traitement complet et envoi (fonction du déclencheur).
 *   - odat_dryRun()      : idem mais crée un BROUILLON au lieu d'envoyer, et ne mémorise rien.
 *   - odat_listSenders() : diagnostic, liste les expéditeurs et sujets réels des rapports.
 *   - odat_showState()   : diagnostic, affiche les messages déjà traités.
 *   - odat_resetState()  : purge l'état mémorisé (force un nouveau traitement).
 *
 * Toutes les fonctions sont préfixées 'odat_' : les fichiers .gs d'un même projet Apps Script
 * partagent un scope global, et des noms génériques (getOrCreateLabel_, getFolderByName...)
 * existent déjà dans les autres scripts du projet.
 */

// --- CONFIGURATION ---
const ODAT_CONFIG = {

  /**
   * IMPORTANT : expéditeurs autorisés du rapport Control-M.
   * Tant que la liste est vide, le script refuse de tourner : sans ce contrôle, n'importe qui
   * pouvant envoyer un mail au bon sujet avec la bonne pièce jointe piloterait le rapport.
   * Exécutez odat_listSenders() pour découvrir les expéditeurs réels.
   */
  ALLOWED_SENDERS: ['Indic_CTM@dalkia.fr'],

  /** Sujet attendu du mail Control-M. Laisser vide pour ne pas filtrer sur le sujet. */
  SUBJECT: 'DALKIA / Extract CSV du Suivi Quotidien CTM',

  /**
   * Exiger que le sujet COMMENCE par le texte de SUBJECT. La recherche Gmail 'subject:'
   * étant approximative (ponctuation ignorée, RE:/TR: inclus, 'contient' et non 'commence par'),
   * ce contrôle élimine les faux positifs. Sans effet si SUBJECT est vide.
   */
  STRICT_SUBJECT: true,

  /** Seules les pièces jointes .zip dont le nom commence par ce texte sont retenues. */
  ATTACHMENT_NAME_PREFIX: 'Report_ctm_',

  /** Profondeur de la recherche Gmail, en jours. */
  SEARCH_WINDOW_DAYS: 3,

  /** Application à isoler dans le CSV (colonne 'Application'). */
  APPLICATION: 'FIN-FINANCE',

  /**
   * Types de tâches exclus des compteurs et du détail.
   * Les 'SMART Table' sont les chaînes conteneurs : leur statut ne fait que refléter celui
   * des jobs qu'elles contiennent. Les garder ferait compter deux fois le même incident.
   */
  EXCLUDED_TASK_TYPES: ['SMART Table'],

  /** Statuts considérés comme un échec (colonne 'Status'). */
  FAILED_STATUSES: ['Ended Not OK'],

  /** Destinataires du rapport, séparés par des virgules. */
  RECIPIENTS: 'samir-externe.chibout@dalkia.fr',

  /**
   * Adresse prévenue en cas d'anomalie TECHNIQUE (mail introuvable, ZIP illisible, format du
   * rapport modifié...). Indispensable : comme aucun mail n'est envoyé quand tout va bien,
   * c'est le seul moyen de distinguer « aucun échec » de « le script est cassé ».
   */
  ADMIN_EMAIL: '',

  /** Nom affiché comme expéditeur du rapport. */
  SENDER_NAME: 'Supervision Control-M',

  /** Label posé sur les conversations traitées. Laisser vide pour désactiver. */
  PROCESSED_LABEL: 'z_odat_traite',

  /** Clé d'état dans les propriétés du script. */
  STATE_KEY: 'ODAT_PROCESSED_MESSAGES',

  /** Plafond d'ID mémorisés (les propriétés du script sont limitées à 9 Ko par clé). */
  MAX_PROCESSED_IDS: 50,

  /** Marge de rétention des ID mémorisés, au-delà de la fenêtre de recherche (en jours). */
  PROCESSED_RETENTION_MARGIN_DAYS: 7,

  /** Fenêtre utilisée par odat_listSenders() pour découvrir les expéditeurs. */
  DISCOVERY_WINDOW: 'newer_than:180d',
};
// --- FIN DE LA CONFIGURATION ---


/** Colonnes du CSV dont l'absence empêche de produire le rapport. */
const ODAT_REQUIRED_COLUMNS = [
  'Application', 'Group Name', 'Job Name', 'Odate',
  'Start Time', 'End Time', 'Status', 'Description',
  'Task Type', 'Rerun Counter', 'Hostname', 'Order id',
];


// =====================================================================
// Points d'entrée
// =====================================================================

/**
 * Traitement complet : recherche du mail, extraction du CSV, envoi du rapport.
 * C'est la fonction à planifier via un déclencheur quotidien.
 */
function odat_runReport() {
  odat_process_(false);
}


/**
 * Répétition générale : déroule tout le traitement mais crée un BROUILLON Gmail au lieu
 * d'envoyer le rapport, et ne mémorise ni ne labellise rien. Peut être relancée à volonté.
 */
function odat_dryRun() {
  odat_process_(true);
}


// =====================================================================
// Traitement
// =====================================================================

/**
 * Déroule le traitement de bout en bout.
 * @param {boolean} dryRun Si true : brouillon au lieu d'un envoi, et aucun état modifié.
 */
function odat_process_(dryRun) {
  Logger.log(`=== Rapport Control-M ${ODAT_CONFIG.APPLICATION}${dryRun ? ' (SIMULATION)' : ''} ===`);

  const allowedSenders = odat_normalizeSenders_(ODAT_CONFIG.ALLOWED_SENDERS);
  if (allowedSenders.length === 0) {
    odat_alert_(
      'Rapport Control-M : configuration incomplète',
      "Aucun expéditeur autorisé (ALLOWED_SENDERS est vide) : le traitement est refusé.\n" +
      "Exécutez odat_listSenders() pour identifier l'expéditeur légitime du rapport."
    );
    return;
  }
  if (!ODAT_CONFIG.RECIPIENTS) {
    odat_alert_(
      'Rapport Control-M : configuration incomplète',
      "Aucun destinataire (RECIPIENTS est vide) : le rapport ne peut pas être envoyé."
    );
    return;
  }

  const state = odat_loadState_();

  // En simulation, l'état mémorisé est ignoré : la répétition générale doit rester relançable
  // même après un envoi réel du rapport du jour.
  const selection = odat_findReportMessage_(allowedSenders, dryRun ? { processed: {} } : state);

  if (!selection.message) {
    if (selection.alreadyProcessed > 0) {
      // Cas nominal d'une seconde exécution dans la journée : rien à signaler.
      Logger.log(`Le rapport du jour a déjà été traité (${selection.alreadyProcessed} message(s) mémorisé(s)).`);
      return;
    }
    odat_alert_(
      'Rapport Control-M : aucun rapport exploitable',
      `Aucun message exploitable trouvé sur les ${ODAT_CONFIG.SEARCH_WINDOW_DAYS} derniers jours.\n` +
      `Requête : ${selection.query}\n` +
      `Rejets — expéditeur : ${selection.rejectedSender}, sujet : ${selection.rejectedSubject}, ` +
      `pièce jointe absente : ${selection.rejectedAttachment}.\n\n` +
      "Vérifiez ALLOWED_SENDERS, SUBJECT et ATTACHMENT_NAME_PREFIX (odat_listSenders() aide au diagnostic)."
    );
    return;
  }

  const message = selection.message;
  Logger.log(`Message retenu : "${message.getSubject()}" du ${message.getDate()} (ID ${message.getId()}).`);

  let csvContent;
  try {
    csvContent = odat_extractCsv_(selection.attachment);
  } catch (e) {
    odat_alert_(
      'Rapport Control-M : archive illisible',
      `La pièce jointe "${selection.attachment.getName()}" n'a pas pu être exploitée.\n` +
      `Message du ${message.getDate()} — "${message.getSubject()}".\n\nDétail : ${e.message}`
    );
    return;
  }

  let report;
  try {
    report = odat_buildReport_(csvContent);
  } catch (e) {
    odat_alert_(
      'Rapport Control-M : format du rapport inattendu',
      `Le CSV extrait de "${selection.attachment.getName()}" n'a pas pu être analysé.\n\nDétail : ${e.message}`
    );
    return;
  }

  Logger.log(
    `${report.applicationRows} ligne(s) ${ODAT_CONFIG.APPLICATION} — ` +
    `${report.tasks.length} tâche(s) réelle(s) après exclusion de ${report.excluded} conteneur(s).`
  );
  Object.keys(report.counters).forEach(status => {
    Logger.log(`  ${status} : ${report.counters[status]}`);
  });

  // Une application absente du rapport signale un renommage côté Control-M : sans ce contrôle,
  // le script resterait silencieux pour toujours en laissant croire que tout va bien.
  if (report.applicationRows === 0) {
    odat_alert_(
      'Rapport Control-M : application introuvable',
      `Aucune ligne "${ODAT_CONFIG.APPLICATION}" dans le rapport du ${message.getDate()}, ` +
      `alors que le CSV contient ${report.totalRows} ligne(s).\n` +
      `Applications présentes : ${report.applications.join(', ')}.\n\n` +
      "L'application a probablement été renommée : mettez à jour ODAT_CONFIG.APPLICATION."
    );
    return;
  }

  if (report.failures.length === 0) {
    Logger.log('Aucun job en échec : aucun mail envoyé.');
  } else {
    const subject =
      `[Control-M] ${ODAT_CONFIG.APPLICATION} — ${report.failures.length} job(s) en échec — ${report.odateLabel}`;
    const htmlBody = odat_buildHtml_(report);
    const textBody = odat_buildText_(report);

    if (dryRun) {
      GmailApp.createDraft(ODAT_CONFIG.RECIPIENTS, subject, textBody, {
        htmlBody: htmlBody,
        name: ODAT_CONFIG.SENDER_NAME,
      });
      Logger.log(`SIMULATION : brouillon créé — "${subject}"`);
    } else {
      MailApp.sendEmail({
        to: ODAT_CONFIG.RECIPIENTS,
        subject: subject,
        body: textBody,
        htmlBody: htmlBody,
        name: ODAT_CONFIG.SENDER_NAME,
      });
      Logger.log(`Rapport envoyé à ${ODAT_CONFIG.RECIPIENTS} — "${subject}"`);
    }
  }

  if (dryRun) {
    Logger.log('SIMULATION : le message n\'est ni labellisé ni mémorisé.');
    return;
  }

  // Mémorisation dans TOUS les cas, y compris « aucun échec » : sans cela, la prochaine
  // exécution du jour relirait le même rapport et renverrait le même mail.
  state.processed[message.getId()] = odat_messageTime_(message);
  odat_saveState_(state);

  if (ODAT_CONFIG.PROCESSED_LABEL) {
    const label = odat_getOrCreateLabel_(ODAT_CONFIG.PROCESSED_LABEL);
    if (label) {
      try {
        message.getThread().addLabel(label);
      } catch (e) {
        Logger.log(`  ! Label non posé : ${e.message}`);
      }
    }
  }
}


/**
 * Recherche le message de rapport le plus récent qui n'a pas encore été traité.
 * @param {string[]} allowedSenders Les expéditeurs autorisés, normalisés.
 * @param {Object} state L'état mémorisé.
 * @return {Object} Le message et sa pièce jointe, ou les compteurs de rejet.
 */
function odat_findReportMessage_(allowedSenders, state) {
  const result = {
    message: null,
    attachment: null,
    alreadyProcessed: 0,
    rejectedSender: 0,
    rejectedSubject: 0,
    rejectedAttachment: 0,
    query: '',
  };

  // La syntaxe {a b} signifie 'a OU b'. Ce filtre est une première barrière : il porte
  // aussi sur le nom d'affichage, donc l'adresse réelle est revérifiée à la lecture.
  const clauses = [
    `from:{${allowedSenders.join(' ')}}`,
    'has:attachment',
    `newer_than:${ODAT_CONFIG.SEARCH_WINDOW_DAYS}d`,
  ];
  if (ODAT_CONFIG.SUBJECT) clauses.push(`subject:("${ODAT_CONFIG.SUBJECT}")`);
  result.query = clauses.join(' ');
  Logger.log(`Requête Gmail : ${result.query}`);

  const threads = GmailApp.search(result.query);
  Logger.log(`${threads.length} conversation(s) trouvée(s).`);

  const candidates = [];

  threads.forEach(thread => {
    thread.getMessages().forEach(message => {
      if (message.isInTrash() || message.isDraft()) return;

      if (state.processed[message.getId()]) {
        result.alreadyProcessed++;
        return;
      }

      // Contrôle de l'adresse RÉELLE : GmailApp.search('from:') matche aussi le nom
      // d'affichage, donc un expéditeur externe se nommant « control-m@... » passerait.
      const sender = odat_extractEmail_(message.getFrom());
      if (allowedSenders.indexOf(sender) === -1) {
        result.rejectedSender++;
        Logger.log(`  REJETÉ (expéditeur) : "${sender}" — "${message.getSubject()}".`);
        return;
      }

      const subject = (message.getSubject() || '').trim();
      if (ODAT_CONFIG.SUBJECT && ODAT_CONFIG.STRICT_SUBJECT && !subject.startsWith(ODAT_CONFIG.SUBJECT)) {
        result.rejectedSubject++;
        Logger.log(`  REJETÉ (sujet ne commence pas par le préfixe attendu) : "${subject}".`);
        return;
      }

      const attachment = odat_findZipAttachment_(message);
      if (!attachment) {
        result.rejectedAttachment++;
        Logger.log(`  REJETÉ (pas de ZIP "${ODAT_CONFIG.ATTACHMENT_NAME_PREFIX}*") : "${message.getSubject()}".`);
        return;
      }

      candidates.push({ message: message, attachment: attachment, time: odat_messageTime_(message) });
    });
  });

  if (candidates.length > 0) {
    // Le rapport le plus récent fait foi : s'il y a eu un renvoi, c'est le bon.
    candidates.sort((a, b) => b.time - a.time);
    result.message = candidates[0].message;
    result.attachment = candidates[0].attachment;
    if (candidates.length > 1) {
      Logger.log(`  ${candidates.length} rapports candidats : le plus récent est retenu.`);
    }
  }

  return result;
}


/**
 * Retourne la première pièce jointe ZIP correspondant au préfixe attendu.
 * @param {GmailMessage} message Le message à inspecter.
 * @return {?GmailAttachment} La pièce jointe, ou null.
 */
function odat_findZipAttachment_(message) {
  const prefix = (ODAT_CONFIG.ATTACHMENT_NAME_PREFIX || '').toLowerCase();
  const attachments = message.getAttachments({ includeInlineImages: false });

  for (let i = 0; i < attachments.length; i++) {
    const name = (attachments[i].getName() || '').toLowerCase();
    if (name.slice(-4) === '.zip' && name.indexOf(prefix) === 0) return attachments[i];
  }
  return null;
}


/**
 * Décompresse l'archive en mémoire et retourne le contenu du premier CSV trouvé.
 * @param {GmailAttachment} attachment L'archive ZIP.
 * @return {string} Le contenu du CSV.
 */
function odat_extractCsv_(attachment) {
  const blobs = Utilities.unzip(attachment.copyBlob().setContentType('application/zip'));

  for (let i = 0; i < blobs.length; i++) {
    let name = blobs[i].getName() || '';
    if (name.indexOf('/') !== -1) name = name.split('/').pop(); // ignore les dossiers internes
    if (name.slice(0, 1) === '.' || name.toLowerCase().slice(-4) !== '.csv') continue;

    Logger.log(`  CSV extrait de l'archive : ${name}`);
    // Le rapport Control-M est produit en UTF-8 : le préciser évite que les accents des
    // descriptions ('Concaténer', 'Règlements') ne soient décodés en Latin-1.
    const content = blobs[i].getDataAsString('UTF-8');
    return content.charCodeAt(0) === 0xFEFF ? content.slice(1) : content; // BOM éventuel
  }

  throw new Error(`Aucun fichier .csv dans l'archive (${blobs.length} entrée(s)).`);
}


// =====================================================================
// Analyse du CSV
// =====================================================================

/**
 * Analyse le CSV et produit les données du rapport.
 * @param {string} csvContent Le contenu brut du CSV.
 * @return {Object} Compteurs, échecs regroupés par chaîne, et contexte.
 */
function odat_buildReport_(csvContent) {
  // Utilities.parseCsv, et non split(';') : plusieurs descriptions contiennent un point-virgule
  // entre guillemets (ex. "Archivage des repertoires IN; OUT et OUT_SEPA"), qui décalerait
  // toutes les colonnes suivantes.
  const rows = Utilities.parseCsv(csvContent, ';');
  if (!rows || rows.length < 2) throw new Error('CSV vide ou sans ligne de données.');

  // Colonnes repérées par NOM : l'en-tête se termine par un ';' (colonne finale vide) et
  // l'ordre des colonnes n'est pas garanti d'une version de rapport à l'autre.
  const index = {};
  rows[0].forEach((name, position) => {
    const clean = (name || '').trim();
    if (clean && !(clean in index)) index[clean] = position;
  });

  const missing = ODAT_REQUIRED_COLUMNS.filter(name => !(name in index));
  if (missing.length > 0) {
    throw new Error(
      `Colonnes absentes : ${missing.join(', ')}.\n` +
      `Colonnes présentes : ${Object.keys(index).join(', ')}.`
    );
  }

  const cell = (row, name) => (row[index[name]] || '').trim();
  const dataRows = rows.slice(1).filter(row => row && row.length > 1);

  const applications = {};
  const applicationRows = [];
  dataRows.forEach(row => {
    const application = cell(row, 'Application');
    if (!application) return;
    applications[application] = true;
    if (application === ODAT_CONFIG.APPLICATION) applicationRows.push(row);
  });

  const excludedTypes = ODAT_CONFIG.EXCLUDED_TASK_TYPES || [];
  const tasks = applicationRows.filter(row => excludedTypes.indexOf(cell(row, 'Task Type')) === -1);

  const counters = {};
  tasks.forEach(row => {
    const status = cell(row, 'Status') || '(sans statut)';
    counters[status] = (counters[status] || 0) + 1;
  });

  const failedStatuses = ODAT_CONFIG.FAILED_STATUSES || [];
  const failures = tasks
    .filter(row => failedStatuses.indexOf(cell(row, 'Status')) !== -1)
    .map(row => {
      const start = odat_parseCtmDate_(cell(row, 'Start Time'));
      const end = odat_parseCtmDate_(cell(row, 'End Time'));
      return {
        group: cell(row, 'Group Name'),
        job: cell(row, 'Job Name'),
        description: cell(row, 'Description'),
        status: cell(row, 'Status'),
        member: cell(row, 'Member Name'),
        host: cell(row, 'Hostname'),
        orderId: cell(row, 'Order id'),
        reruns: cell(row, 'Rerun Counter'),
        start: start,
        end: end,
        startLabel: odat_formatTime_(start) || cell(row, 'Start Time') || '—',
        endLabel: odat_formatTime_(end) || cell(row, 'End Time') || '—',
        // La colonne 'Run Time' du rapport est incohérente (valeurs sans lien avec les
        // horodatages) : la durée est recalculée depuis Start Time / End Time.
        duration: odat_formatDuration_(start, end),
      };
    })
    .sort((a, b) => {
      if (a.group !== b.group) return a.group < b.group ? -1 : 1;
      const timeA = a.start ? a.start.getTime() : 0;
      const timeB = b.start ? b.start.getTime() : 0;
      return timeA - timeB;
    });

  // Regroupement par chaîne, en conservant l'ordre du tri.
  const groups = [];
  failures.forEach(failure => {
    let group = groups[groups.length - 1];
    if (!group || group.name !== failure.group) {
      group = { name: failure.group, jobs: [] };
      groups.push(group);
    }
    group.jobs.push(failure);
  });

  const odateRaw = applicationRows.length > 0 ? cell(applicationRows[0], 'Odate') : '';

  return {
    totalRows: dataRows.length,
    applications: Object.keys(applications).sort(),
    applicationRows: applicationRows.length,
    excluded: applicationRows.length - tasks.length,
    tasks: tasks,
    counters: counters,
    failures: failures,
    groups: groups,
    odateRaw: odateRaw,
    odateLabel: odat_formatDay_(odat_parseCtmDate_(odateRaw)) || odateRaw || '(odate inconnue)',
  };
}


// =====================================================================
// Mise en forme du message
// =====================================================================

/** Palette du corps HTML. */
const ODAT_STYLE = {
  text: '#202124',
  muted: '#5f6368',
  border: '#dadce0',
  bandBg: '#fce8e6',
  bandBorder: '#d93025',
  bandText: '#b3261e',
  headerBg: '#f1f3f4',
  groupBg: '#f8f9fa',
  font: "-apple-system, 'Segoe UI', Roboto, Arial, sans-serif",
};

/**
 * Construit le corps HTML du rapport.
 * Les styles sont posés en attributs 'style' inline : Gmail supprime les feuilles de style
 * déclarées dans <head>.
 * @param {Object} report Le résultat de odat_buildReport_.
 * @return {string} Le corps HTML.
 */
function odat_buildHtml_(report) {
  const s = ODAT_STYLE;
  const esc = odat_escapeHtml_;
  const cellStyle = `padding:6px 8px;border-bottom:1px solid ${s.border};vertical-align:top;`;
  const html = [];

  html.push(`<div style="font-family:${s.font};font-size:14px;color:${s.text};max-width:100%;">`);

  html.push(
    `<h2 style="margin:0 0 4px 0;font-size:18px;">${esc(ODAT_CONFIG.APPLICATION)} — Odate ${esc(report.odateLabel)}</h2>`
  );
  html.push(
    `<div style="color:${s.muted};font-size:12px;margin-bottom:16px;">` +
    `Rapport Control-M généré le ${esc(odat_formatTime_(new Date()))}</div>`
  );

  html.push(
    `<div style="background:${s.bandBg};border-left:4px solid ${s.bandBorder};` +
    `padding:10px 12px;margin-bottom:16px;">` +
    `<strong style="color:${s.bandText};font-size:16px;">` +
    `${report.failures.length} job(s) en échec</strong>` +
    `<span style="color:${s.muted};"> sur ${report.groups.length} chaîne(s)</span></div>`
  );

  // Synthèse : compteurs par statut, l'échec en premier puis par effectif décroissant.
  const failedStatuses = ODAT_CONFIG.FAILED_STATUSES || [];
  const statuses = Object.keys(report.counters).sort((a, b) => {
    const failA = failedStatuses.indexOf(a) !== -1;
    const failB = failedStatuses.indexOf(b) !== -1;
    if (failA !== failB) return failA ? -1 : 1;
    return report.counters[b] - report.counters[a];
  });

  html.push(`<table role="presentation" cellpadding="0" cellspacing="0" style="margin-bottom:8px;">`);
  html.push('<tr>');
  statuses.forEach(status => {
    const isFailure = failedStatuses.indexOf(status) !== -1;
    html.push(
      `<td style="padding:0 20px 0 0;">` +
      `<div style="font-size:20px;font-weight:bold;color:${isFailure ? s.bandText : s.text};">` +
      `${report.counters[status]}</div>` +
      `<div style="font-size:12px;color:${s.muted};white-space:nowrap;">${esc(status)}</div></td>`
    );
  });
  html.push('</tr></table>');

  html.push(
    `<div style="color:${s.muted};font-size:12px;margin-bottom:20px;">` +
    `${report.tasks.length} tâche(s) — les ${report.excluded} chaîne(s) conteneur ` +
    `(${esc((ODAT_CONFIG.EXCLUDED_TASK_TYPES || []).join(', '))}) sont exclues des compteurs, ` +
    `leur statut ne faisant que refléter celui de leurs jobs.</div>`
  );

  html.push(`<h3 style="font-size:15px;margin:0 0 8px 0;">Détail des échecs</h3>`);
  html.push(
    `<table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;font-size:13px;` +
    `border:1px solid ${s.border};">`
  );
  html.push(
    `<tr style="background:${s.headerBg};">` +
    ['Job', 'Début', 'Fin', 'Durée', 'Reruns', 'Hôte']
      .map(title =>
        `<th align="left" style="padding:8px;border-bottom:1px solid ${s.border};` +
        `font-weight:600;white-space:nowrap;">${title}</th>`)
      .join('') +
    '</tr>'
  );

  report.groups.forEach(group => {
    html.push(
      `<tr style="background:${s.groupBg};"><td colspan="6" ` +
      `style="padding:8px;border-bottom:1px solid ${s.border};font-weight:600;">` +
      `${esc(group.name)} <span style="color:${s.muted};font-weight:normal;">` +
      `— ${group.jobs.length} job(s)</span></td></tr>`
    );

    group.jobs.forEach(job => {
      html.push('<tr>');
      html.push(
        `<td style="${cellStyle}"><div style="font-family:monospace;">${esc(job.job)}</div>` +
        `<div style="color:${s.muted};font-size:12px;">${esc(job.description)}</div>` +
        (job.member ? `<div style="color:${s.muted};font-size:11px;">${esc(job.member)}</div>` : '') +
        (job.orderId ? `<div style="color:${s.muted};font-size:11px;">Order id ${esc(job.orderId)}</div>` : '') +
        '</td>'
      );
      html.push(`<td style="${cellStyle}white-space:nowrap;">${esc(job.startLabel)}</td>`);
      html.push(`<td style="${cellStyle}white-space:nowrap;">${esc(job.endLabel)}</td>`);
      html.push(`<td style="${cellStyle}white-space:nowrap;">${esc(job.duration)}</td>`);
      html.push(`<td style="${cellStyle}">${esc(job.reruns || '—')}</td>`);
      html.push(`<td style="${cellStyle}">${esc(job.host || '—')}</td>`);
      html.push('</tr>');
    });
  });

  html.push('</table>');
  html.push(
    `<div style="color:${s.muted};font-size:11px;margin-top:16px;">` +
    `Message automatique. Les durées sont recalculées depuis les heures de début et de fin ` +
    `(la colonne « Run Time » du rapport Control-M n'est pas exploitable).</div>`
  );
  html.push('</div>');

  return html.join('');
}


/**
 * Construit la version texte brut du rapport, utilisée par les clients sans HTML.
 * @param {Object} report Le résultat de odat_buildReport_.
 * @return {string} Le corps en texte brut.
 */
function odat_buildText_(report) {
  const lines = [];
  lines.push(`${ODAT_CONFIG.APPLICATION} — Odate ${report.odateLabel}`);
  lines.push(`${report.failures.length} job(s) en échec sur ${report.groups.length} chaîne(s).`);
  lines.push('');

  Object.keys(report.counters).forEach(status => {
    lines.push(`  ${status} : ${report.counters[status]}`);
  });
  lines.push(`  (${report.tasks.length} tâches, ${report.excluded} chaînes conteneur exclues)`);
  lines.push('');

  report.groups.forEach(group => {
    lines.push(`--- ${group.name} — ${group.jobs.length} job(s)`);
    group.jobs.forEach(job => {
      lines.push(`  ${job.job}`);
      lines.push(`    ${job.description}`);
      lines.push(`    ${job.startLabel} -> ${job.endLabel} (${job.duration})` +
                 ` | reruns ${job.reruns || '—'} | ${job.host || '—'} | order id ${job.orderId || '—'}`);
    });
    lines.push('');
  });

  return lines.join('\n');
}


// =====================================================================
// Diagnostic
// =====================================================================

/**
 * Liste les expéditeurs, sujets et pièces jointes des messages porteurs d'une archive
 * de rapport. À exécuter en premier pour renseigner ALLOWED_SENDERS et SUBJECT.
 */
function odat_listSenders() {
  const query = `has:attachment ${ODAT_CONFIG.DISCOVERY_WINDOW}`;
  Logger.log(`=== Découverte des rapports — requête : ${query} ===`);

  const prefix = (ODAT_CONFIG.ATTACHMENT_NAME_PREFIX || '').toLowerCase();
  const seen = {};

  GmailApp.search(query).forEach(thread => {
    thread.getMessages().forEach(message => {
      if (message.isInTrash() || message.isDraft()) return;

      message.getAttachments({ includeInlineImages: false }).forEach(attachment => {
        const name = (attachment.getName() || '').toLowerCase();
        if (name.indexOf(prefix) !== 0) return;

        const key = `${odat_extractEmail_(message.getFrom())} | ${message.getSubject()}`;
        if (!seen[key]) {
          seen[key] = { count: 0, last: message.getDate(), sample: attachment.getName() };
        }
        seen[key].count++;
      });
    });
  });

  const keys = Object.keys(seen);
  if (keys.length === 0) {
    Logger.log(`Aucune pièce jointe commençant par "${ODAT_CONFIG.ATTACHMENT_NAME_PREFIX}" trouvée.`);
    Logger.log('Élargissez DISCOVERY_WINDOW ou vérifiez ATTACHMENT_NAME_PREFIX.');
    return;
  }

  keys.forEach(key => {
    const info = seen[key];
    Logger.log(`\n  ${key}`);
    Logger.log(`    ${info.count} message(s) — dernier le ${info.last}`);
    Logger.log(`    Exemple de pièce jointe : ${info.sample}`);
  });
  Logger.log('\nReportez l\'adresse dans ALLOWED_SENDERS et le sujet dans SUBJECT.');
}


/** Affiche les messages déjà traités. */
function odat_showState() {
  const state = odat_loadState_();
  const ids = Object.keys(state.processed);

  Logger.log(`=== ${ids.length} message(s) mémorisé(s) ===`);
  ids
    .sort((a, b) => state.processed[b] - state.processed[a])
    .forEach(id => Logger.log(`  ${id} — ${new Date(state.processed[id])}`));
}


/** Purge l'état mémorisé : le prochain rapport sera retraité et renvoyé. */
function odat_resetState() {
  PropertiesService.getScriptProperties().deleteProperty(ODAT_CONFIG.STATE_KEY);
  Logger.log('État purgé : le prochain rapport trouvé sera retraité.');
}


// =====================================================================
// Utilitaires
// =====================================================================

/** Correspondance nom de mois anglais → index (le rapport Control-M est en anglais US). */
const ODAT_MONTHS = {
  january: 0, february: 1, march: 2, april: 3, may: 4, june: 5,
  july: 6, august: 7, september: 8, october: 9, november: 10, december: 11,
};

/**
 * Analyse un horodatage du rapport Control-M, de la forme
 * 'August 13, 2026 7:52:56 PM' ou 'August 13, 2026'.
 * new Date(...) n'est pas utilisé : son comportement dépend de la locale du moteur.
 * @param {string} value La valeur brute.
 * @return {?Date} La date, ou null si la valeur est vide ou non reconnue.
 */
function odat_parseCtmDate_(value) {
  const match = /^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})(?:\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM))?$/
    .exec((value || '').trim());
  if (!match) return null;

  const month = ODAT_MONTHS[match[1].toLowerCase()];
  if (month === undefined) return null;

  let hours = match[4] === undefined ? 0 : parseInt(match[4], 10);
  if (match[7]) {
    // 12 AM = minuit, 12 PM = midi : les deux cas échappent au simple '+12'.
    if (match[7].toUpperCase() === 'PM' && hours < 12) hours += 12;
    if (match[7].toUpperCase() === 'AM' && hours === 12) hours = 0;
  }

  return new Date(
    parseInt(match[3], 10), month, parseInt(match[2], 10),
    hours,
    match[5] === undefined ? 0 : parseInt(match[5], 10),
    match[6] === undefined ? 0 : parseInt(match[6], 10)
  );
}


/**
 * Formate une date avec l'heure, dans le fuseau du script.
 * @param {?Date} date La date.
 * @return {string} 'jj/MM/aaaa HH:mm:ss', ou '' si la date est absente.
 */
function odat_formatTime_(date) {
  if (!date) return '';
  return Utilities.formatDate(date, Session.getScriptTimeZone(), 'dd/MM/yyyy HH:mm:ss');
}


/**
 * Formate une date sans l'heure, dans le fuseau du script.
 * @param {?Date} date La date.
 * @return {string} 'jj/MM/aaaa', ou '' si la date est absente.
 */
function odat_formatDay_(date) {
  if (!date) return '';
  return Utilities.formatDate(date, Session.getScriptTimeZone(), 'dd/MM/yyyy');
}


/**
 * Calcule et met en forme la durée séparant deux horodatages. Les horodatages étant complets
 * (date + heure), un traitement à cheval sur minuit est correctement mesuré.
 * @param {?Date} start Le début.
 * @param {?Date} end La fin.
 * @return {string} Une durée lisible, ou '—' si elle n'est pas calculable.
 */
function odat_formatDuration_(start, end) {
  if (!start || !end) return '—';

  let seconds = Math.round((end.getTime() - start.getTime()) / 1000);
  if (seconds < 0) return '—';
  if (seconds < 60) return `${seconds}s`;

  const hours = Math.floor(seconds / 3600);
  seconds -= hours * 3600;
  const minutes = Math.floor(seconds / 60);
  seconds -= minutes * 60;

  const pad = value => (value < 10 ? `0${value}` : `${value}`);
  return hours > 0
    ? `${hours}h ${pad(minutes)}min ${pad(seconds)}s`
    : `${minutes}min ${pad(seconds)}s`;
}


/**
 * Échappe les caractères ayant un sens en HTML. Les descriptions Control-M contiennent
 * des caractères ('&', '<', '>') qui casseraient la mise en page.
 * @param {*} value La valeur à échapper.
 * @return {string} La valeur échappée.
 */
function odat_escapeHtml_(value) {
  return String(value === null || value === undefined ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}


/**
 * Normalise une liste d'adresses (minuscules, sans espaces, sans entrées vides).
 * @param {string[]} senders Les adresses brutes.
 * @return {string[]} Les adresses normalisées.
 */
function odat_normalizeSenders_(senders) {
  return (senders || [])
    .filter(sender => typeof sender === 'string')
    .map(sender => sender.trim().toLowerCase())
    .filter(sender => sender !== '');
}


/**
 * Extrait l'adresse d'un en-tête 'From' de la forme 'Nom <adresse@domaine>'.
 * @param {string} from La valeur brute retournée par GmailMessage.getFrom().
 * @return {string} L'adresse en minuscules.
 */
function odat_extractEmail_(from) {
  const match = /<([^>]+)>/.exec(from || '');
  return (match ? match[1] : (from || '')).trim().toLowerCase();
}


/**
 * Date d'un message en millisecondes, avec repli sur l'instant courant si elle est indisponible.
 * @param {GmailMessage} message Le message.
 * @return {number} L'horodatage en millisecondes.
 */
function odat_messageTime_(message) {
  try {
    const date = message.getDate();
    if (date) return date.getTime();
  } catch (e) {
    // Repli ci-dessous.
  }
  return Date.now();
}


/**
 * Récupère ou crée un label Gmail.
 * @param {string} name Le nom du label.
 * @return {?GmailLabel} Le label, ou null s'il est inaccessible.
 */
function odat_getOrCreateLabel_(name) {
  try {
    let label = GmailApp.getUserLabelByName(name);
    if (!label) {
      label = GmailApp.createLabel(name);
      Logger.log(`  Label Gmail "${name}" créé.`);
    }
    return label;
  } catch (e) {
    Logger.log(`  ! Label "${name}" inaccessible : ${e.message}`);
    return null;
  }
}


/**
 * Lit l'état mémorisé. Un état absent ou corrompu ne doit jamais bloquer le traitement :
 * on repart alors d'un état vierge.
 * @return {{processed: Object}} L'état.
 */
function odat_loadState_() {
  try {
    const raw = PropertiesService.getScriptProperties().getProperty(ODAT_CONFIG.STATE_KEY);
    if (!raw) return { processed: {} };
    return { processed: JSON.parse(raw).processed || {} };
  } catch (e) {
    Logger.log(`  ! État illisible, repart de zéro : ${e.message}`);
    return { processed: {} };
  }
}


/**
 * Enregistre l'état après élagage des ID devenus inutiles (hors fenêtre de recherche, ou
 * au-delà du plafond) : les propriétés du script sont limitées à 9 Ko par clé.
 * @param {Object} state L'état à enregistrer.
 */
function odat_saveState_(state) {
  const dayMs = 24 * 60 * 60 * 1000;
  const retentionDays = ODAT_CONFIG.SEARCH_WINDOW_DAYS + ODAT_CONFIG.PROCESSED_RETENTION_MARGIN_DAYS;
  const cutoff = Date.now() - retentionDays * dayMs;

  const kept = {};
  Object.keys(state.processed)
    .filter(id => state.processed[id] >= cutoff)
    .sort((a, b) => state.processed[b] - state.processed[a])
    .slice(0, ODAT_CONFIG.MAX_PROCESSED_IDS)
    .forEach(id => { kept[id] = state.processed[id]; });

  try {
    PropertiesService.getScriptProperties().setProperty(
      ODAT_CONFIG.STATE_KEY, JSON.stringify({ processed: kept })
    );
  } catch (e) {
    // Sans état, la prochaine exécution risque de renvoyer le rapport : il faut le voir.
    Logger.log(`  ! État non enregistré : ${e.message}`);
  }
}


/**
 * Signale une anomalie technique : journal, puis e-mail si ADMIN_EMAIL est renseigné.
 * @param {string} subject L'objet de l'alerte.
 * @param {string} body Le détail de l'alerte.
 */
function odat_alert_(subject, body) {
  Logger.log(`ALERTE — ${subject}\n${body}`);

  if (!ODAT_CONFIG.ADMIN_EMAIL) return;
  try {
    MailApp.sendEmail(ODAT_CONFIG.ADMIN_EMAIL, subject, body);
  } catch (e) {
    Logger.log(`Échec de l'envoi de l'alerte par e-mail : ${e.message}`);
  }
}
