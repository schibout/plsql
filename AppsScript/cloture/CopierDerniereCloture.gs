// ============================================================
//  CopierDerniereCloture.gs
//  Copie les fichiers du dossier "derniere cloture" (toutes
//  variantes orthographiques) vers un dossier cible.
// ============================================================

// --- Paramètres à modifier avant l'exécution ----------------
var ROOT_FOLDER_ID     = '1ga5GhqT5xKyRrn3jz9ufDPMoRQH9bMrE'; // ID du dossier racine Drive
var TARGET_FOLDER_NAME = '202605';              // Nom du dossier cible à créer/utiliser

// Liste des éditeurs à qui partager chaque fichier copié (adresses Gmail)
var EDITORS = [
  'compta-generale-CE-MED@dalkia.fr', 'dsin-rpa@dalkia.fr', 'lionel.jove@dalkia.fr',
  'soraya.coux@dalkia.fr', 'luc.lepinette@dalkia.fr', 'sophie.jarlaud@dalkia.fr',
  'mathieu.tiablikoff@dalkia.fr', 'dimitri.stoppani@dalkia.fr', 'sandrine.peneau@dalkia.fr',
  'danielle.bialais@dalkia.fr', 'emmanuelle.gerhards@dalkia.fr', 'antoine.bocquillon@dalkia.fr',
  'amelie.fricot@dalkia.fr', 'veronique.varrier@dalkia.fr', 'melisa.debourgogne@dalkia.fr',
  'mickael.bernard@dalkia.fr', 'celine.magnoni@dalkia.fr', 'emmanuelle.biessy@dalkia.fr',
  'catherine.carre@dalkia.fr', 'louis-vianney.le-lezec@dalkia.fr', 'solene.beck@dalkia.fr',
  'leticia.bouassa@dalkia.fr', 'remi.marceau@dalkia.fr', 'alexandre.joly-vaucher@dalkia.fr',
  'celine.chaumarat@dalkia.fr', 'elodie.frenois@dalkia.fr', 'compta.gene-idf@dalkia.fr',
  'helene.serre-prospere@dalkia.fr', 'cedric.cezard@dalkia.fr', 'stephanie.ameye-pasbecq@dalkia.fr',
  'laurence.gardiman@dalkia.fr', 'laury.compan@dalkia.fr', 'aurelie.vazquez@dalkia.fr',
  'lea.robalo@dalkia.fr', 'fabienne.pellerin@dalkia.fr', 'fabrice.zarcone@dalkia.fr',
  'marc.mosser@dalkia.fr', 'lucie.jaegle@dalkia.fr', 'murielle.vitalis@dalkia.fr',
  'cecile.clavier@dalkia.fr', 'marjorie.lamant@dalkia.fr', 'catherine.everard@dalkia.fr',
  'support-metier-finance@dalkia.fr', 'catherine.bonhomme@dalkia.fr', 'compta-siege@dalkia.fr',
  'leonia.mondon@dalkia.fr', 'virginie.michel@dalkia.fr', 'florence.basirico@dalkia.fr',
  'marion.coue@dalkia.fr', 'christine.walraet@dalkia.fr', 'olivier-externe.delehouze@dalkia.fr',
  'olivier.deshayes@dalkia.fr', 'dsin-rpa-robot1@dalkia.fr', 'virginie.barre@dalkia.fr',
  'veronique.deforge@dalkia.fr', 'isabelle.deshayes@dalkia.fr', 'oliva.rakotoson@dalkia.fr',
  'william.nguyen-van-phu@dalkia.fr', 'genevieve.rocca@dalkia.fr', 'aline.detraye@dalkia.fr',
  'david.bertin@dalkia.fr', 'compta-merignac@dalkia.fr', 'marjorie.bouden@dalkia.fr',
  'franck.stagnitto@dalkia.fr', 'stephane.duchesne@dalkia.fr', 'lucas.cecillon@dalkia.fr',
  'bruno.hertner@dalkia.fr', 'julien.pelloille@dalkia.fr', 'murielle.coquelet@dalkia.fr',
  'julien-externe.michoux@dalkia.fr', 'valerie.bar@dalkia.fr', 'nathalie.nicolas@dalkia.fr',
  'christophe.drouin@dalkia.fr', 'lou.pannier@dalkia.fr', 'comptabilite-centre-ouest@dalkia.fr',
  'meriam.cherif@dalkia.fr', 'rachel.brochard@dalkia.fr', 'bruno.oppenot@dalkia.fr',
  'sophie.grandjean@dalkia.fr', 'jean-noel.morin@dalkia.fr', 'julien.bocahut@dalkia.fr',
  'christophe.casella@dalkia.fr', 'gontran.guillebert@dalkia.fr', 'emma.giraudeau@dalkia.fr',
  'beatrice.beltran-quiros@dalkia.fr', 'brigitte.david@dalkia.fr', 'anne-catherine.baheux@dalkia.fr',
  'comptabilite-nordouest@dalkia.fr', 'thomas-externe.beal@dalkia.fr', 'carole.gandouin@dalkia.fr',
  'cecile.antunovic@dalkia.fr', 'catherine.roguin@dalkia.fr', 'vincent.ruckebusch@dalkia.fr',
  'stephanie.thiry@dalkia.fr', 'jose.camba@dalkia.fr', 'emilie.angier@dalkia.fr',
  'philippe-externe.grall@dalkia.fr', 'sylvain.ricordeau@dalkia.fr', 'nicolas.dassonneville@dalkia.fr',
  'arnaud.malezieux@dalkia.fr', 'nathalie.lequarre@dalkia.fr', 'veronique.longuepe@dalkia.fr',
  'elodie.massa@dalkia.fr', 'flavia.pinto@dalkia.fr', 'lionel.brand@dalkia.fr',
  'emmanuel.compain@dalkia.fr', 'laurent.jourdy@dalkia.fr', 'julie.vieville@dalkia.fr',
  'cathy.sanchez@dalkia.fr', 'boubkar.aitaliobrahim@dalkia.fr', 'compta-societe-est@dalkia.fr',
  'frederic.dujardin@dalkia.fr', 'adrien.mannent@dalkia.fr', 'hogban.lawson@dalkia.fr',
  'christophe.lion@dalkia.fr', 'virginie.juge@dalkia.fr', 'benjamin.bonvalet@dalkia.fr',
  'vadim-externe.palierne@dalkia.fr', 'frederic.vidaud@dalkia.fr', 'amelie.delsart@dalkia.fr',
  'cathy.singre@dalkia.fr', 'lidia.szafryna@dalkia.fr', 'carol.nonin-guerenneur@dalkia.fr',
  'richard.roux@dalkia.fr', 'magali.kalwajtys@dalkia.fr', 'daphne.baumer@dalkia.fr',
  'geoffroy.henquenet@dalkia.fr', 'beatrice.mazuyt@e2s.fr', 'kevin.demeyer@dalkia.fr',
  'aubert.roux@dalkia.fr', 'aline.perette@dalkia.fr', 'claude-henri-externe.marguerite@dalkia.fr',
  'emmanuelle.jeuland@dalkia.fr', 'christel.chognard@dalkia.fr', 'angelique.delattre@dalkia.fr',
  'claudine.quilliou@dalkia.fr', 'jennifer.mahoudeaux@dalkia.fr'
];
// ------------------------------------------------------------

/**
 * Normalise une chaîne : minuscules, sans accents, sans espaces/tirets/underscores.
 * Permet de comparer les noms de dossiers de façon souple.
 */
function normaliser(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .toLowerCase()
    .normalize('NFD')                    // décompose les caractères accentués
    .replace(/[\u0300-\u036f]/g, '')     // supprime les diacritiques
    .replace(/[\s\-_]/g, '');           // supprime espaces, tirets, underscores
}

/** Valeur de référence après normalisation */
var CIBLE_NORMALISEE = 'dernièrecloture'; // sera normalisée aussi → "dernièrecloture" → "dernièrecloture"

/**
 * Recherche récursivement dans 'folder' tous les sous-dossiers
 * dont le nom normalisé correspond à "dernièrecloture".
 * Remplit le tableau 'resultats' avec les objets { folder, path }.
 */
function chercherDossierSource(folder, cheminActuel, resultats) {
  var sousDossiers = folder.getFolders();

  while (sousDossiers.hasNext()) {
    var sousD = sousDossiers.next();
    var nomNormalise = normaliser(sousD.getName());
    var chemin = cheminActuel + '/' + sousD.getName();

    if (nomNormalise === normaliser('derniere cloture')) {
      resultats.push({ folder: sousD, path: chemin });
      Logger.log('✔ Dossier source trouvé : ' + chemin);
    }

    // Descente récursive dans les sous-dossiers
    chercherDossierSource(sousD, chemin, resultats);
  }
}

/**
 * Retourne le dossier cible dans 'rootFolder'.
 * Le crée s'il n'existe pas encore.
 */
function obtenirOuCreerDossierCible(rootFolder, nomCible) {
  var iter = rootFolder.getFoldersByName(nomCible);
  if (iter.hasNext()) {
    var dossier = iter.next();
    Logger.log('Dossier cible existant trouvé : ' + nomCible);
    return dossier;
  }
  var nouveau = rootFolder.createFolder(nomCible);
  Logger.log('Dossier cible créé : ' + nomCible);
  return nouveau;
}

/**
 * Fonction principale — à lancer manuellement depuis Apps Script.
 */
function copierDerniereCloture() {
  Logger.log('=== Début de copierDerniereCloture ===');
  Logger.log('Dossier racine ID  : ' + ROOT_FOLDER_ID);
  Logger.log('Dossier cible      : ' + TARGET_FOLDER_NAME);

  // 1. Récupération du dossier racine
  var rootFolder;
  try {
    rootFolder = DriveApp.getFolderById(ROOT_FOLDER_ID);
  } catch (e) {
    Logger.log('ERREUR : Impossible d\'accéder au dossier racine. Vérifiez ROOT_FOLDER_ID. Détail : ' + e.message);
    return;
  }
  Logger.log('Dossier racine     : ' + rootFolder.getName());

  // 2. Recherche récursive du/des dossier(s) source
  var resultats = [];
  chercherDossierSource(rootFolder, rootFolder.getName(), resultats);

  if (resultats.length === 0) {
    Logger.log('ERREUR : Aucun dossier "derniere cloture" trouvé sous ' + rootFolder.getName());
    return;
  }

  if (resultats.length > 1) {
    Logger.log('ERREUR : Plusieurs dossiers source trouvés (' + resultats.length + '). Ambiguïté impossible à résoudre automatiquement.');
    resultats.forEach(function(r) { Logger.log('  → ' + r.path); });
    return;
  }

  var dossierSource = resultats[0].folder;
  Logger.log('Dossier source retenu : ' + resultats[0].path);

  // 3. Obtenir ou créer le dossier cible
  var dossierCible = obtenirOuCreerDossierCible(rootFolder, TARGET_FOLDER_NAME);

  // 4. Inventaire des fichiers déjà présents dans la cible (anti-doublons)
  var fichiersExistants = {};
  var iterCible = dossierCible.getFiles();
  while (iterCible.hasNext()) {
    var f = iterCible.next();
    fichiersExistants[f.getName()] = true;
  }

  // 5. Copie des fichiers source → cible
  var totalFichiers = 0;
  var fichiersCopies = 0;
  var fichiersIgnores = 0;

  var iterSource = dossierSource.getFiles();
  while (iterSource.hasNext()) {
    totalFichiers++;
    var fichier = iterSource.next();
    var nom = fichier.getName();

    if (fichiersExistants[nom]) {
      fichiersIgnores++;
      Logger.log('⚠ Ignoré (doublon) : ' + nom);
    } else {
      var copie = fichier.makeCopy(nom, dossierCible);

      // Partage du fichier copié avec chaque éditeur
      EDITORS.forEach(function(email) {
        try {
          copie.addEditor(email);
          Logger.log('   → Partagé avec : ' + email);
        } catch (e) {
          Logger.log('   ⚠ Échec partage avec ' + email + ' : ' + e.message);
        }
      });

      fichiersCopies++;
      Logger.log('✔ Copié : ' + nom);
    }
  }

  // 6. Récapitulatif
  Logger.log('=== Fin de copierDerniereCloture ===');
  Logger.log('Fichiers trouvés dans la source : ' + totalFichiers);
  Logger.log('Fichiers copiés                 : ' + fichiersCopies);
  Logger.log('Fichiers ignorés (doublons)     : ' + fichiersIgnores);
}
