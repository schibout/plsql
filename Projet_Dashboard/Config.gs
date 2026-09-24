/** Configuration du dashboard. Seul FOLDER_ID est a renseigner. */
const DASHBOARD_CONFIG = Object.freeze({
  // Dossier Drive ou export_csv.bat depose les CSV.
  FOLDER_ID: '1kG2s3RLN9IB5_DXgsakhTlY4UL9Td7AInj3zlbSJcGTn1hC9XH1Jp92R',
  // Au-dela, un CSV est affiche comme perime (export horaire en retard ou en echec).
  STALE_HOURS: 3,
  // Rafraichissement automatique de la page.
  REFRESH_MINUTES: 15,
  TITLE: 'Controle EBS - Dashboard',
});

/** Fichier de synthese : colonnes ORDRE, KPI, VALEUR, STATUT. */
const DASHBOARD_KPI_FILE = '00_kpi.csv';

/** Sections affichees, dans l'ordre. Un fichier absent du dossier est signale. */
const DASHBOARD_SECTIONS = Object.freeze([
  {file: '01_dsp_flux.csv', title: 'DSP - Detail des flux', group: 'DSP'},
  {file: '02_dsp_synthese.csv', title: 'DSP - Synthese par jour et type', group: 'DSP'},
  {file: '03_ndf_notilus.csv', title: 'Notilus - Notes de frais', group: 'Factures'},
  {file: '04_factures_source.csv', title: 'Factures - Synthese par source', group: 'Factures'},
  {file: '05_xerox_sans_image.csv', title: 'Xerox - Factures SANS image', group: 'Factures', alertIfRows: true},
  {file: '06_xerox_avec_image.csv', title: 'Xerox - Factures AVEC image', group: 'Factures'},
  {file: '07_fac_ar_recues.csv', title: 'Factures AR - Recues (24 h)', group: 'Factures'},
  {file: '08_fac_ar_rejets.csv', title: 'Factures AR - Rejets AutoInvoice', group: 'Factures', alertIfRows: true},
  {file: '09_gl_interface.csv', title: 'GL - Interface (en attente)', group: 'GL'},
  {file: '10_gl_lignes.csv', title: 'GL - Lignes creees', group: 'GL'},
  {file: '11_nuit_synthese.csv', title: 'Nuit - Synthese par statut', group: 'Nuit'},
  {file: '12_nuit_erreurs_programme.csv', title: 'Nuit - Erreurs par programme', group: 'Nuit', alertIfRows: true},
  {file: '13_nuit_erreurs_detail.csv', title: 'Nuit - Detail des erreurs', group: 'Nuit', alertIfRows: true},
  {file: '14_nuit_warnings.csv', title: 'Nuit - Warnings', group: 'Nuit'},
  {file: '15_nuit_longs.csv', title: 'Nuit - Traitements > 30 min', group: 'Nuit'},
  {file: '16_nuit_en_cours.csv', title: 'Nuit - Traitements en cours', group: 'Nuit'},
  {file: '17_rb_imports.csv', title: 'Rapprochement bancaire - Imports', group: 'RB'},
]);
