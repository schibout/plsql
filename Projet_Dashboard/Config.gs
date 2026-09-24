/** Configuration du dashboard. Seul FOLDER_ID est a renseigner. */
const DASHBOARD_CONFIG = Object.freeze({
  // Dossier Drive ou export_csv.bat depose les CSV.
  FOLDER_ID: '1byjNlEtmcAwyF_osxGofM2OrPZfonAuK',
  // Au-dela, un CSV est affiche comme perime (export horaire en retard ou en echec).
  STALE_HOURS: 3,
  // Rafraichissement automatique de la page.
  REFRESH_MINUTES: 15,
  TITLE: 'Controle EBS - Dashboard',
});

/** Fichier de synthese : colonnes ORDRE, KPI, VALEUR, STATUT. */
const DASHBOARD_KPI_FILE = '00_kpi.csv';

/** Tuile cliquee (colonne KPI de 00_kpi.csv) -> sections de detail affichees. */
const DASHBOARD_KPI_LINKS = Object.freeze({
  'Flux DSP': ['01_dsp_flux.csv', '02_dsp_synthese.csv'],
  'Notes de frais': ['03_ndf_notilus.csv'],
  'Factures Xerox': ['04_factures_source.csv', '05_xerox_sans_image.csv', '06_xerox_avec_image.csv'],
  'Factures Tradeshift': ['04_factures_source.csv'],
  'Factures DSP': ['04_factures_source.csv', '02_dsp_synthese.csv'],
  'GL interface': ['09_gl_interface.csv'],
  'Lignes GL creees': ['10_gl_lignes.csv'],
  'Imports RB': ['17_rb_imports.csv'],
  'Traitements nuit': ['11_nuit_synthese.csv', '15_nuit_longs.csv', '16_nuit_en_cours.csv'],
  'Erreurs nuit': ['12_nuit_erreurs_programme.csv', '13_nuit_erreurs_detail.csv'],
  'Avertissements nuit': ['14_nuit_warnings.csv'],
  'Images Xerox manquantes': ['05_xerox_sans_image.csv'],
  'Factures demat en attente': ['18_demat_statut.csv', '19_demat_par_jour.csv', '20_demat_en_attente.csv'],
});

/** Panneau Factures dematerialisees : donut des statuts + arrivees par jour (a la place des tableaux 18 et 19). */
const DASHBOARD_DEMAT = Object.freeze({
  KPI: 'Factures demat en attente',
  STATUT_FILE: '18_demat_statut.csv',
  JOUR_FILE: '19_demat_par_jour.csv',
  // Ordre fixe des statuts (= ordre des couleurs) et libelles affiches.
  STATUTS: [
    {code: 'INSERE', label: 'En attente'},
    {code: 'INTEGREE', label: 'Integree'},
    {code: 'COMPLETED', label: 'Terminee'},
    {code: 'AUTRE', label: 'Autre'},
  ],
});

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
  {file: '18_demat_statut.csv', title: 'Factures demat - Stock par statut', group: 'Demat'},
  {file: '19_demat_par_jour.csv', title: 'Factures demat - Arrivees par jour', group: 'Demat'},
  {file: '20_demat_en_attente.csv', title: 'Factures demat - En attente (INSERE)', group: 'Demat', alertIfRows: true},
]);
