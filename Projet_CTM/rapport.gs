/**
 * SCRIPT GLOBAL AUTOMATISÉ CONTROL-M, PLAN DE PRODUCTION, SYSOUTS ET CLÔTURE FINANCE
 * FIXATION DÉFINITIVE DE L'ASSOCIATION PDP/CTM ET DU FILTRAGE DES ERREURS DANS LA WEB APP
 * 
 * - ID Dossier Google Drive Rapports CTM : 1RN3MK9b5aFwKyNcD6W3PNDuT39U25dBp
 * - ID Dossier Google Drive Sysout Logs  : 1m7mbC01IPscDzRZj8Dc1APasf13JwNk5
 * - ID Dossier Google Drive Plannings PDP: 1dMp7lc9HsaO-aOhQ1l5jOZEZ3i01saWZ
 * - Destinataire Mail                     : lionel.jove@dalkia.fr
 */

const FOLDER_REPORTS_ID = "1RN3MK9b5aFwKyNcD6W3PNDuT39U25dBp";
const FOLDER_LOGS_ID = "1m7mbC01IPscDzRZj8Dc1APasf13JwNk5";
const FOLDER_PLANNING_ID = "1dMp7lc9HsaO-aOhQ1l5jOZEZ3i01saWZ";

const RECIPIENT_EMAIL = "dsin-finance-support@dalkia.fr";

const WEB_APP_URL = "https://script.google.com/a/macros/dalkia.fr/s/AKfycbzuo_5GmG6Ey9qRThiGePBJsJ1ODotzGZGFnyOffo_zbuP4YKbcMZSdlY4YMv4cugs/exec";

/* ==========================================================================
   MODULE 0 : SERVICE WEB APP ET EXPLORATEUR INTERACTIF CHAÎNES / JOBS
   ========================================================================== */

function doGet(e) {
  let tousLesJobsPdp = [];
  const ctmJobsList = [];
  const ctmDetailsMap = {};

  // 1. Indexation des logs Sysout depuis Drive
  let logsMapDrive = {};
  try {
    const folderLogs = DriveApp.getFolderById(FOLDER_LOGS_ID);
    if (folderLogs) logsMapDrive = extraireIndexContenuLogsSysout(folderLogs);
  } catch (eLogs) {
    Logger.log("Avertissement chargement logs : " + eLogs.toString());
  }

  // 2. Lecture du rapport CTM (ZIP/CSV) avec heures et logs
  try {
    const folderReports = DriveApp.getFolderById(FOLDER_REPORTS_ID);
    if (folderReports) {
      const dernierRapport = obtenirDernierFichierRapportDrive(folderReports);
      if (dernierRapport) {
        let csvContent = "";
        const name = dernierRapport.getName().toLowerCase();

        if (name.endsWith(".zip")) {
          const blobs = Utilities.unzip(dernierRapport.getBlob());
          blobs.forEach(b => {
            const bName = b.getName().toLowerCase();
            if (bName.endsWith(".csv") || bName.endsWith(".txt")) {
              csvContent += b.getDataAsString() + "\n";
            }
          });
        } else {
          csvContent = dernierRapport.getBlob().getDataAsString();
        }

        const lines = csvContent.split(/\r?\n/);
        if (lines.length > 1) {
          const separator = lines[0].includes(";") ? ";" : ",";
          for (let i = 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const cols = parseCsvLigneRFC4180(line, separator);
            if (cols.length >= 8) {
              const app = cols[0] ? cols[0].toUpperCase().trim() : "";
              if (app.includes("FINANCE") || app.includes("FIN-FINANCE")) {
                const jName = cols[2] ? cols[2].trim() : "";
                const stRaw = cols[7] ? cols[7].toUpperCase().trim() : "";
                const descCol = cols[8] ? cols[8].replace(/"/g, '').trim() : "-";

                const fullDateTimeRegex = /(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}\s+\d{1,2}:\d{2}:\d{2}\s+(?:AM|PM)|\d{1,2}\/\d{1,2}\/\d{4}\s+\d{1,2}:\d{2}:\d{2}(?:\s*(?:AM|PM))?/gi;
                const timeMatches = line.match(fullDateTimeRegex) || [];
                const startTime = formaterHeureFr(timeMatches[0] || (cols[4] ? cols[4].trim() : "-"));
                const endTime = formaterHeureFr(timeMatches[1] || (cols[5] ? cols[5].trim() : "-"));

                let st = "Ended Not OK";
                if (stRaw.includes("ENDED OK") || stRaw.includes("ENDED_OK") || stRaw.includes("SUCCESS") || stRaw === "OK") st = "Ended OK";
                else if (stRaw.includes("WAIT") || stRaw.includes("EVENT")) st = "Wait for Event";
                else if (stRaw.includes("EXEC") || stRaw.includes("RUNNING")) st = "Executing";
                else st = "Ended Not OK";

                let errorMsg = "";
                if (st === "Ended Not OK") {
                  errorMsg = chercherLogPourJob(jName, logsMapDrive);
                }

                if (jName) {
                  const jobData = {
                    status: st,
                    description: descCol,
                    startTime: startTime,
                    endTime: endTime,
                    errorMessage: errorMsg
                  };
                  ctmDetailsMap[jName.toUpperCase().trim()] = jobData;

                  ctmJobsList.push({
                    jobName: jName,
                    typeChaine: cols[1] || "GÉNÉRALE",
                    description: descCol,
                    script: "-",
                    status: st,
                    startTime: startTime,
                    endTime: endTime,
                    errorMessage: errorMsg
                  });
                }
              }
            }
          }
        }
      }
    }
  } catch (errCTM) {
    Logger.log("Avertissement CTM WebApp : " + errCTM.toString());
  }

  // 3. Chargement du PDP
  try {
    const pdpFile = obtenirFichierPlanDeProduction();
    if (pdpFile) {
      const spreadsheet = SpreadsheetApp.open(pdpFile);
      const sheet = spreadsheet.getSheets()[0];
      const data = sheet.getDataRange().getValues();

      for (let i = 1; i < data.length; i++) {
        const row = data[i];
        const jobName = row[2] ? row[2].toString().trim() : "";
        const desc = row[3] ? row[3].toString().trim() : "";
        const typeChaine = row[8] ? row[8].toString().trim() : "GÉNÉRALE";
        const script = row[19] ? row[19].toString().trim() : "";

        if (jobName) {
          const jobUpper = jobName.toUpperCase().trim();
          const ctmInfo = ctmDetailsMap[jobUpper] || {};

          tousLesJobsPdp.push({
            jobName: jobName,
            description: desc || ctmInfo.description || "-",
            typeChaine: typeChaine || "GÉNÉRALE",
            script: script || "-",
            status: ctmInfo.status || "Wait for Event",
            startTime: ctmInfo.startTime || "-",
            endTime: ctmInfo.endTime || "-",
            errorMessage: ctmInfo.errorMessage || ""
          });
        }
      }
    }
  } catch (errPDP) {
    Logger.log("Info PDP Fallback : " + errPDP.toString());
  }

  const jobsAffiches = (tousLesJobsPdp.length > 0) ? tousLesJobsPdp : ctmJobsList;

  const htmlContent = genererPageHTMLPleinEcran("FIN-FINANCE", jobsAffiches);
  return HtmlService.createHtmlOutput(htmlContent)
    .setTitle("Explorateur Détaillé - FINANCE")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function genererPageHTMLPleinEcran(nomDomaine, jobsList) {
  const jobsJson = JSON.stringify(jobsList);

  return `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <title>Explorateur Détaillé - ${nomDomaine}</title>
      <style>
        body { margin: 0; padding: 0; background-color: #0b1120; color: #f8fafc; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; overflow: hidden; }
        .header { height: 50px; background-color: #0f172a; border-bottom: 1px solid #1e293b; display: flex; justify-content: space-between; align-items: center; padding: 0 20px; }
        .title { font-weight: bold; font-size: 16px; color: #38bdf8; display: flex; align-items: center; gap: 8px; }
        
        .legend { font-size: 12px; display: flex; gap: 10px; align-items: center; }
        .filter-btn { 
          display: flex; align-items: center; gap: 6px; padding: 4px 12px; border-radius: 15px; 
          background: #1e293b; border: 1px solid #334155; cursor: pointer; user-select: none; transition: all 0.2s ease;
          font-weight: 500; font-size: 12px; color: #f8fafc;
        }
        .filter-btn:hover { border-color: #38bdf8; background: #334155; }
        .filter-btn.inactive { opacity: 0.3; filter: grayscale(100%); }
        .filter-btn-all { padding: 4px 12px; border-radius: 15px; background: #0284c7; color: white; border: none; cursor: pointer; font-size: 11px; font-weight: bold; }

        .dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
        .dot-ok { background-color: #22c55e; }
        .dot-err { background-color: #ef4444; }
        .dot-wait { background-color: #eab308; }
        .dot-run { background-color: #3b82f6; }
        
        #svg-container { width: 100vw; height: calc(100vh - 50px); cursor: grab; position: relative; }
        #svg-container:active { cursor: grabbing; }

        .modal-backdrop {
          position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
          background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(4px);
          display: none; justify-content: center; align-items: center; z-index: 1000;
        }
        .modal-card {
          background: #1e293b; border: 1px solid #38bdf8; border-radius: 10px;
          width: 90%; max-width: 650px; padding: 24px; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
          color: #f8fafc; font-size: 13px; position: relative; max-height: 85vh; overflow-y: auto;
        }
        .modal-header { font-size: 18px; font-weight: bold; color: #38bdf8; border-bottom: 1px solid #334155; padding-bottom: 10px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }
        .modal-close { cursor: pointer; color: #94a3b8; font-size: 20px; font-weight: bold; }
        .modal-close:hover { color: #f8fafc; }
        .modal-row { margin-bottom: 12px; line-height: 1.5; }
        .modal-label { color: #94a3b8; font-weight: bold; }
        .status-badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-weight: bold; font-size: 11px; color: white; }
        .badge-ok { background-color: #22c55e; }
        .badge-err { background-color: #ef4444; }
        .badge-wait { background-color: #eab308; color: #0f172a; }
        .badge-run { background-color: #3b82f6; }
        .error-box { background: #0f172a; border: 1px solid #ef4444; border-radius: 6px; padding: 12px; font-family: monospace; font-size: 11px; color: #fca5a5; overflow-x: auto; white-space: pre-wrap; max-height: 200px; }

        .controls { position: absolute; bottom: 20px; right: 20px; display: flex; gap: 10px; z-index: 50; }
        .btn { background: #1e293b; border: 1px solid #334155; color: #f8fafc; padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; }
        .btn:hover { background: #334155; }
      </style>
    </head>
    <body>

      <div class="header">
        <div class="title">● Explorateur Détaillé - ${nomDomaine}</div>
        <div class="legend">
          <span style="color: #64748b; font-size: 11px; margin-right: 5px;">Filtrer :</span>
          <div class="filter-btn" id="f-ok" onclick="toggleCategory('OK')">
            <span class="dot dot-ok"></span> OK
          </div>
          <div class="filter-btn" id="f-err" onclick="toggleCategory('NOK')">
            <span class="dot dot-err"></span> Erreur
          </div>
          <div class="filter-btn" id="f-wait" onclick="toggleCategory('WAIT')">
            <span class="dot dot-wait"></span> En attente
          </div>
          <div class="filter-btn" id="f-run" onclick="toggleCategory('RUN')">
            <span class="dot dot-run"></span> En cours
          </div>
          <button class="filter-btn-all" onclick="showAllCategories()">Tous</button>
        </div>
      </div>

      <div id="svg-container">
        <svg id="viewport" width="100%" height="100%"></svg>
      </div>

      <div id="job-modal" class="modal-backdrop" onclick="closeModal(event)">
        <div class="modal-card" onclick="event.stopPropagation()">
          <div class="modal-header">
            <span id="m-jobname">JOB_NAME</span>
            <span class="modal-close" onclick="closeModalDirect()">&times;</span>
          </div>
          <div class="modal-row"><span class="modal-label">Statut :</span> <span id="m-status"></span></div>
          <div class="modal-row"><span class="modal-label">Description Fonctionnelle :</span> <div id="m-desc" style="margin-top:4px; color:#f8fafc;"></div></div>
          <div class="modal-row" style="display:flex; gap:30px;">
            <div><span class="modal-label">Heure Début :</span> <span id="m-start" style="color:#f8fafc; font-family:monospace;"></span></div>
            <div><span class="modal-label">Heure Fin :</span> <span id="m-end" style="color:#f8fafc; font-family:monospace;"></span></div>
          </div>
          <div class="modal-row" id="m-err-container" style="display:none; margin-top:15px;">
            <span class="modal-label" style="color:#ef4444;">Extrait Log Sysout / Message d'erreur :</span>
            <div id="m-err" class="error-box" style="margin-top:6px;"></div>
          </div>
        </div>
      </div>

      <div class="controls">
        <button class="btn" onclick="resetZoom()">Réinitialiser la vue</button>
      </div>

      <script>
        const rawJobs = ${jobsJson};
        const svg = document.getElementById('viewport');

        let enabledCats = { "OK": true, "NOK": true, "WAIT": true, "RUN": true };
        let expandedChains = new Set();

        let zoom = 1;
        let panX = 50;
        let panY = 50;
        let isDragging = false;
        let startX, startY;

        // DÉTECTION HARMONISÉE ET ULTRA-STRICTE DE LA CATÉGORIE
        function getCategory(stStr) {
          const st = (stStr || "").toUpperCase().trim();
          if (st.includes("NOT") || st.includes("NOK") || st.includes("FAIL") || st.includes("ERR")) return "NOK";
          if (st.includes("ENDED OK") || st.includes("SUCCESS") || st === "OK") return "OK";
          if (st.includes("EXEC") || st.includes("RUN")) return "RUN";
          return "WAIT";
        }

        const chainesMap = {};
        rawJobs.forEach(j => {
          const cName = j.typeChaine || "GÉNÉRALE";
          if (!chainesMap[cName]) {
            chainesMap[cName] = { chaineName: cName, jobs: [] };
            expandedChains.add(cName);
          }
          chainesMap[cName].jobs.push(j);
        });

        function toggleCategory(cat) {
          enabledCats[cat] = !enabledCats[cat];
          document.getElementById('f-ok').classList.toggle('inactive', !enabledCats["OK"]);
          document.getElementById('f-err').classList.toggle('inactive', !enabledCats["NOK"]);
          document.getElementById('f-wait').classList.toggle('inactive', !enabledCats["WAIT"]);
          document.getElementById('f-run').classList.toggle('inactive', !enabledCats["RUN"]);
          renderTree();
        }

        function showAllCategories() {
          enabledCats = { "OK": true, "NOK": true, "WAIT": true, "RUN": true };
          document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('inactive'));
          renderTree();
        }

        function toggleChainExpand(cName) {
          if (expandedChains.has(cName)) expandedChains.delete(cName);
          else expandedChains.add(cName);
          renderTree();
        }

        function renderTree() {
          const activeChaines = [];
          let totalVisibleNodes = 0;

          Object.values(chainesMap).forEach(cObj => {
            const filteredJobs = cObj.jobs.filter(j => enabledCats[getCategory(j.status)]);
            if (filteredJobs.length > 0) {
              let cCat = "OK";
              if (filteredJobs.some(j => getCategory(j.status) === "NOK")) cCat = "NOK";
              else if (filteredJobs.some(j => getCategory(j.status) === "RUN")) cCat = "RUN";
              else if (filteredJobs.some(j => getCategory(j.status) === "WAIT")) cCat = "WAIT";

              activeChaines.push({
                chaineName: cObj.chaineName,
                category: cCat,
                isExpanded: expandedChains.has(cObj.chaineName),
                jobs: filteredJobs
              });

              totalVisibleNodes += 1 + (expandedChains.has(cObj.chaineName) ? filteredJobs.length : 0);
            }
          });

          const height = Math.max(800, totalVisibleNodes * 28);
          const rootX = 80, rootY = height / 2;
          const chaineX = 350;
          const jobX = 680;

          let content = \`<g id="map-group" transform="translate(\${panX}, \${panY}) scale(\${zoom})">\`;

          content += \`
            <rect x="0" y="\${rootY - 16}" width="120" height="32" rx="16" fill="#1e293b" stroke="#38bdf8" stroke-width="2"/>
            <text x="60" y="\${rootY + 5}" fill="#f8fafc" font-size="12" font-weight="bold" text-anchor="middle">${nomDomaine}</text>
          \`;

          if (activeChaines.length === 0) {
            content += \`<text x="220" y="\${rootY}" fill="#64748b" font-size="13">Aucun job ne correspond aux filtres sélectionnés.</text>\`;
          } else {
            const chaineStep = (height - 80) / Math.max(1, activeChaines.length - 1);

            activeChaines.forEach((c, cIdx) => {
              const chaineY = 40 + (cIdx * chaineStep);

              let cColor = "#eab308";
              if (c.category === "OK") cColor = "#22c55e";
              if (c.category === "NOK") cColor = "#ef4444";
              if (c.category === "RUN") cColor = "#3b82f6";

              content += \`<path d="M 120 \${rootY} C 200 \${rootY}, 200 \${chaineY}, \${chaineX} \${chaineY}" fill="none" stroke="#334155" stroke-width="1.5"/>\`;

              content += \`
                <g onclick="toggleChainExpand('\${c.chaineName.replace(/'/g, "\\\\'")}')" style="cursor:pointer;">
                  <circle cx="\${chaineX}" cy="\${chaineY}" r="7" fill="\${cColor}" stroke="#0f172a" stroke-width="1.5"/>
                  <text x="\${chaineX + 15}" y="\${chaineY + 4}" fill="#f8fafc" font-size="12" font-weight="bold">\${c.chaineName} (\${c.jobs.length})</text>
                </g>
              \`;

              if (c.isExpanded && c.jobs.length > 0) {
                const jobSpread = Math.min(180, c.jobs.length * 22);
                const startJobY = chaineY - (jobSpread / 2);
                const jobStep = jobSpread / Math.max(1, c.jobs.length - 1);

                c.jobs.forEach((j, jIdx) => {
                  const jY = (c.jobs.length === 1) ? chaineY : startJobY + (jIdx * jobStep);

                  const jCat = getCategory(j.status);
                  let jColor = "#eab308";
                  if (jCat === "OK") jColor = "#22c55e";
                  if (jCat === "NOK") jColor = "#ef4444";
                  if (jCat === "RUN") jColor = "#3b82f6";

                  content += \`<path d="M \${chaineX} \${chaineY} C \${chaineX + 100} \${chaineY}, \${jobX - 100} \${jY}, \${jobX} \${jY}" fill="none" stroke="#1e293b" stroke-width="1"/>\`;

                  content += \`
                    <g onclick="openJobModal(\${j.globalIndex})" style="cursor:pointer;">
                      <circle cx="\${jobX}" cy="\${jY}" r="5" fill="\${jColor}"/>
                      <text x="\${jobX + 12}" y="\${jY + 4}" fill="#94a3b8" font-size="11" font-family="monospace">\${j.jobName}</text>
                    </g>
                  \`;
                });
              }
            });
          }

          content += \`</g>\`;
          svg.innerHTML = content;
        }

        rawJobs.forEach((j, idx) => j.globalIndex = idx);

        function openJobModal(globalIdx) {
          const job = rawJobs[globalIdx];
          if (!job) return;

          document.getElementById('m-jobname').innerText = job.jobName;
          
          const cat = getCategory(job.status);
          let badgeHtml = '<span class="status-badge badge-wait">En attente</span>';
          if (cat === "OK") badgeHtml = '<span class="status-badge badge-ok">Ended OK</span>';
          if (cat === "NOK") badgeHtml = '<span class="status-badge badge-err">Ended Not OK</span>';
          if (cat === "RUN") badgeHtml = '<span class="status-badge badge-run">Executing</span>';
          document.getElementById('m-status').innerHTML = badgeHtml;

          document.getElementById('m-desc').innerText = job.description || "-";
          document.getElementById('m-start').innerText = job.startTime || "-";
          document.getElementById('m-end').innerText = job.endTime || "-";

          const errContainer = document.getElementById('m-err-container');
          if (cat === "NOK" && job.errorMessage) {
            document.getElementById('m-err').innerText = job.errorMessage;
            errContainer.style.display = "block";
          } else {
            errContainer.style.display = "none";
          }

          document.getElementById('job-modal').style.display = "flex";
        }

        function closeModalDirect() {
          document.getElementById('job-modal').style.display = "none";
        }

        function closeModal(e) {
          if (e.target.id === "job-modal") closeModalDirect();
        }

        const container = document.getElementById('svg-container');
        container.addEventListener('mousedown', e => { isDragging = true; startX = e.clientX - panX; startY = e.clientY - panY; });
        window.addEventListener('mouseup', () => isDragging = false);
        container.addEventListener('mousemove', e => {
          if (!isDragging) return;
          panX = e.clientX - startX;
          panY = e.clientY - startY;
          renderTree();
        });

        container.addEventListener('wheel', e => {
          e.preventDefault();
          zoom += e.deltaY * -0.001;
          zoom = Math.min(Math.max(0.3, zoom), 3);
          renderTree();
        });

        function resetZoom() { zoom = 1; panX = 50; panY = 50; renderTree(); }

        renderTree();
      </script>
    </body>
    </html>
  `;
}

/* ==========================================================================
   MODULE 1 : CONTRÔLE DU PLAN DE PRODUCTION DU JOUR ET INTÉGRATION MAIL
   ========================================================================== */

function lancerControlePdpDuJour() {
  Logger.log("==================================================================");
  Logger.log("=== DÉBUT ACQUISITION ET CONTRÔLE DU PLAN DE PRODUCTION DU JOUR ===");
  Logger.log("==================================================================");

  const folderPlanning = obtenirDossierSecurise(FOLDER_PLANNING_ID, "Plannings PDP");
  const pdpFileRecupere = rechercherPlanDeProductionDepuisEmail();
  if (pdpFileRecupere) {
    Logger.log("✔ [ACQUISITION PDP] Fichier PDP récupéré et prêt sur Drive : " + pdpFileRecupere.getName());
  }

  const folderLogs = obtenirDossierSecurise(FOLDER_LOGS_ID, "Sysout Logs");
  if (folderLogs) {
    recupererLogsSysoutDepuisGmail(folderLogs, "");
  }

  controlerEtEnvoyerPlanDeProductionDuJour();
}

function controlerEtEnvoyerPlanDeProductionDuJour() {
  const pdpFile = obtenirFichierPlanDeProduction();
  if (!pdpFile) {
    Logger.log("ERREUR BLOQUANTE : Impossible de trouver le Plan de Production du jour.");
    return;
  }

  Logger.log(">>> [ANALYSE PDP] Traitement du fichier : " + pdpFile.getName() + " (Dernière modif : " + pdpFile.getLastUpdated() + ")");

  let spreadsheet = SpreadsheetApp.open(pdpFile);
  const sheet = spreadsheet.getSheets()[0];
  const data = sheet.getDataRange().getValues();

  const dateDuJourFr = Utilities.formatDate(new Date(), "Europe/Paris", "dd/MM/yyyy");

  let totalJobs = 0;
  const repartitionChaines = {};
  const jobsCloturePrevus = [];
  const tousLesJobsPdp = [];
  const anomaliesSaisie = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const jobName = row[2] ? row[2].toString().trim() : "";
    const desc = row[3] ? row[3].toString().trim() : "";
    const typeChaine = row[8] ? row[8].toString().trim() : "Non Spécifié";
    const planif = row[9] ? row[9].toString().trim() : "-";
    const script = row[19] ? row[19].toString().trim() : "";

    if (!jobName) continue;
    totalJobs++;

    if (!repartitionChaines[typeChaine]) {
      repartitionChaines[typeChaine] = 0;
    }
    repartitionChaines[typeChaine]++;

    const isCloture = typeChaine.toLowerCase().includes("clôture") || typeChaine.toLowerCase().includes("cloture");
    
    const jobItem = {
      jobName: jobName,
      description: desc || "-",
      planification: planif,
      script: script || "-",
      typeChaine: typeChaine,
      isCloture: isCloture,
      status: "En attente"
    };

    tousLesJobsPdp.push(jobItem);

    if (isCloture) {
      jobsCloturePrevus.push(jobItem);
      if (!script) {
        anomaliesSaisie.push("Job " + jobName + " : Script fonctionnel (.sh) manquant dans le PDP");
      }
    }
  }

  let webAppUrl = (typeof WEB_APP_URL !== "undefined" && WEB_APP_URL && !WEB_APP_URL.includes("VOTRE_ID")) 
    ? WEB_APP_URL 
    : ScriptApp.getService().getUrl();

  const schemaApercuHtml = genererApercuAbreApercuMail("FIN-FINANCE", tousLesJobsPdp, webAppUrl);

  envoyerMailCompteRenduPdpDuJour(RECIPIENT_EMAIL, dateDuJourFr, pdpFile.getName(), totalJobs, repartitionChaines, jobsCloturePrevus, anomaliesSaisie, schemaApercuHtml, webAppUrl);
}

function genererApercuAbreApercuMail(nomDomaine, jobsList, webAppUrl) {
  let html = "<div style='margin-top: 8px; margin-bottom: 20px; font-size: 12px; color: #333;'>";
  html += "🔗 <a href='" + webAppUrl + "' target='_blank' style='color: #0284c7; font-weight: bold; text-decoration: underline;'>Ouvrir la Cartographie d'Ordonnancement interactive (" + jobsList.length + " jobs) — " + nomDomaine + "</a>";
  html += "</div>";
  return html;
}

function envoyerMailCompteRenduPdpDuJour(recipient, dateFr, fileName, totalJobs, repartitionChaines, jobsCloture, anomalies, schemaHtml, webAppUrl) {
  const subject = "[Plan de Production] Contrôle et Synthèse du PDP / " + dateFr;

  const hasAnomalies = anomalies.length > 0;
  const headerBg = hasAnomalies ? "#d97706" : "#0284c7";

  let htmlBody = "<div style='font-family: Arial, sans-serif; color: #333; max-width: 950px; margin: 0 auto;'>";

  htmlBody += "<div style='background-color: " + headerBg + "; color: #ffffff; text-align: center; padding: 15px; border-radius: 4px 4px 0 0;'>";
  htmlBody += "<h2 style='margin: 0; font-size: 18px; text-transform: uppercase;'>COMPTE-RENDU DE CONTRÔLE DU PLAN DE PRODUCTION</h2>";
  htmlBody += "<div style='font-size: 13px; font-weight: bold; margin-top: 5px;'>ANALYSE DU FICHIER : " + fileName + " (" + dateFr + ")</div>";
  htmlBody += "</div>";

  htmlBody += "<div style='background-color: #f4f6f8; display: table; width: 100%; border-bottom: 1px solid #ccc; font-size: 12px;'>";
  htmlBody += "<div style='display: table-cell; width: 33%; text-align: center; padding: 10px; border-right: 1px solid #e0e0e0;'>";
  htmlBody += "<div style='color: #666; font-size: 11px; text-transform: uppercase;'>TOTAL JOBS PDP</div>";
  htmlBody += "<div style='color: #003366; font-weight: bold; font-size: 16px; margin-top: 2px;'>" + totalJobs + "</div>";
  htmlBody += "</div>";

  htmlBody += "<div style='display: table-cell; width: 33%; text-align: center; padding: 10px; border-right: 1px solid #e0e0e0;'>";
  htmlBody += "<div style='color: #666; font-size: 11px; text-transform: uppercase;'>JOBS DE CLÔTURE</div>";
  htmlBody += "<div style='color: #2d7d32; font-weight: bold; font-size: 16px; margin-top: 2px;'>" + jobsCloture.length + "</div>";
  htmlBody += "</div>";

  htmlBody += "<div style='display: table-cell; width: 34%; text-align: center; padding: 10px;'>";
  htmlBody += "<div style='color: #666; font-size: 11px; text-transform: uppercase;'>CONFORMITÉ PDP</div>";
  htmlBody += "<div style='color: " + (hasAnomalies ? "#d97706" : "#2d7d32") + "; font-weight: bold; font-size: 14px; margin-top: 2px;'>" + (hasAnomalies ? "AVERTISSEMENT" : "CONFORME") + "</div>";
  htmlBody += "</div>";
  htmlBody += "</div>";

  if (hasAnomalies) {
    htmlBody += "<div style='margin-top: 20px; background-color: #fef3c7; border-left: 4px solid #d97706; padding: 12px; border-radius: 4px;'>";
    htmlBody += "<h4 style='margin: 0 0 5px 0; color: #92400e;'>Points d'attention détectés lors du contrôle :</h4>";
    htmlBody += "<ul style='margin: 0; padding-left: 20px; font-size: 12px; color: #78350f;'>";
    anomalies.forEach(a => htmlBody += "<li>" + a + "</li>");
    htmlBody += "</ul></div>";
  }

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>1. Cartographie d'Ordonnancement :</h3>";
  htmlBody += schemaHtml;

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>2. Volumétrie par Type de Chaîne :</h3>";
  htmlBody += "<table style='width: 60%; border-collapse: collapse; font-size: 11px;'>";
  htmlBody += "<tr style='background-color: #0f4c81; color: white; font-weight: bold;'>";
  htmlBody += "<th style='padding: 6px; border: 1px solid #ddd; text-align: left;'>Type de Chaîne</th>";
  htmlBody += "<th style='padding: 6px; border: 1px solid #ddd; text-align: center;'>Nombre de Jobs</th>";
  htmlBody += "</tr>";

  for (const t in repartitionChaines) {
    htmlBody += "<tr>";
    htmlBody += "<td style='padding: 6px; border: 1px solid #ddd;'>" + t + "</td>";
    htmlBody += "<td style='padding: 6px; border: 1px solid #ddd; text-align: center; font-weight: bold;'>" + repartitionChaines[t] + "</td>";
    htmlBody += "</tr>";
  }
  htmlBody += "</table>";

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>3. Jobs de Clôture prévus au Plan de Production :</h3>";
  htmlBody += "<table style='width: 100%; border-collapse: collapse; font-size: 11px;'>";
  htmlBody += "<tr style='background-color: #0f4c81; color: white; font-weight: bold;'>";
  htmlBody += "<th style='padding: 8px; border: 1px solid #ddd;'>Nom du Job</th>";
  htmlBody += "<th style='padding: 8px; border: 1px solid #ddd;'>Description Fonctionnelle</th>";
  htmlBody += "<th style='padding: 8px; border: 1px solid #ddd; text-align: center;'>Planification</th>";
  htmlBody += "<th style='padding: 8px; border: 1px solid #ddd;'>Script Fonctionnel (.sh)</th>";
  htmlBody += "</tr>";

  jobsCloture.forEach(item => {
    htmlBody += "<tr style='border-bottom: 1px solid #eee;'>";
    htmlBody += "<td style='padding: 8px; border: 1px solid #ddd; font-family: monospace; font-weight: bold; color: #0d47a1;'>" + item.jobName + "</td>";
    htmlBody += "<td style='padding: 8px; border: 1px solid #ddd;'>" + item.description + "</td>";
    htmlBody += "<td style='padding: 8px; border: 1px solid #ddd; text-align: center; color: #555;'>" + item.planification + "</td>";
    htmlBody += "<td style='padding: 8px; border: 1px solid #ddd; font-family: monospace; color: #444;'>" + item.script + "</td>";
    htmlBody += "</tr>";
  });

  htmlBody += "</table>";
  htmlBody += "<p style='font-size: 12px; color: #666; margin-top: 20px;'>Ce compte-rendu est généré automatiquement par analyse du fichier Plan de Production du " + dateFr + ".</p>";
  htmlBody += "</div>";

  MailApp.sendEmail({
    to: recipient,
    subject: subject,
    htmlBody: htmlBody
  });

  Logger.log(">>> [EMAIL PDP] Compte-rendu du Plan de Production envoyé avec succès à " + recipient);
}

/* ==========================================================================
   MODULE 2 : SUIVI ET CONTRÔLE DE CLÔTURE DU MATIN
   ========================================================================== */

function lancerControleClotureParPdp() {
  traiterControleClotureParPdp();
}

function traiterControleClotureParPdp(odatCible) {
  const reportsFolder = obtenirDossierSecurise(FOLDER_REPORTS_ID, "Rapports CTM");
  if (!reportsFolder) return;

  let odatRef = odatCible;
  if (!odatRef || typeof odatRef !== 'string') {
    const hier = new Date();
    hier.setDate(hier.getDate() - 1);
    odatRef = Utilities.formatDate(hier, "Europe/Paris", "dd/MM/yyyy");
  }

  let fichierRapportNuit = recupererRapportCtmDepuisGmail(reportsFolder, odatRef) || trouverFichierRapportParDate(reportsFolder, odatRef);
  if (!fichierRapportNuit) return;

  const pdpClotureJobs = lireJobsCloturePdpStrict();
  if (pdpClotureJobs.length === 0) return;

  const pdpJobsMap = {};
  pdpClotureJobs.forEach(j => pdpJobsMap[j.jobName.toUpperCase().trim()] = j);

  const ctmExecutions = lireLignesRapportCtmAvecLogs(fichierRapportNuit, pdpJobsMap);
  const jobsExecutesCloture = [];
  let odatFrDétectee = "";

  ctmExecutions.forEach(ctmExec => {
    const jobKey = ctmExec.jobName.toUpperCase().trim();
    if (pdpJobsMap[jobKey]) {
      const pdpJob = pdpJobsMap[jobKey];
      if (!odatFrDétectee && ctmExec.odatFr) odatFrDétectee = ctmExec.odatFr;

      jobsExecutesCloture.push({
        jobName: pdpJob.jobName,
        description: pdpJob.description || ctmExec.description || "-",
        planification: pdpJob.planification || "-",
        script: pdpJob.script || "-",
        status: ctmExec.status,
        startTime: formaterHeureFr(ctmExec.startTimeRaw),
        endTime: formaterHeureFr(ctmExec.endTimeRaw),
        duree: calculerDureeExecution(ctmExec.startTimeRaw, ctmExec.endTimeRaw)
      });
    }
  });

  envoyerEmailSyntheseCloturePdp(RECIPIENT_EMAIL, odatFrDétectee || odatRef, jobsExecutesCloture);
}

/* ==========================================================================
   MODULE 3 : SYNTHÈSE DE LA DERNIÈRE NUIT APPLICATIVE (AVEC BASCULE À 19H)
   ========================================================================== */

function traiterSyntheseEtLogsControlM() {
  sauvegarderDernierRapportCTM();
  const folderReports = obtenirDossierSecurise(FOLDER_REPORTS_ID, "Rapports CTM");
  if (!folderReports) return;

  const folderLogs = obtenirDossierSecurise(FOLDER_LOGS_ID, "Sysout Logs");
  if (folderLogs) recupererLogsSysoutDepuisGmail(folderLogs, "");

  const maintenant = new Date();
  const heureActuelle = maintenant.getHours();
  
  const dateOdatCible = new Date();
  if (heureActuelle < 19) {
    dateOdatCible.setDate(dateOdatCible.getDate() - 1);
  }

  const odatFrCible = Utilities.formatDate(dateOdatCible, "Europe/Paris", "dd/MM/yyyy");
  Logger.log(">>> [SYNTHÈSE NUIT CTM] Heure actuelle : " + heureActuelle + "h | Analyse de la nuit ODAT : " + odatFrCible);

  const fichierRapportRecent = obtenirDernierFichierRapportDrive(folderReports, odatFrCible);
  if (!fichierRapportRecent) return;

  Logger.log(">>> [SYNTHÈSE NUIT CTM] Analyse du fichier ZIP/CSV : " + fichierRapportRecent.getName());

  let csvContent = "";
  const name = fichierRapportRecent.getName().toLowerCase();

  if (name.endsWith(".zip")) {
    const blobs = Utilities.unzip(fichierRapportRecent.getBlob());
    blobs.forEach(b => {
      if (b.getName().toLowerCase().endsWith(".csv") || b.getName().toLowerCase().endsWith(".txt")) {
        csvContent += b.getDataAsString() + "\n";
      }
    });
  } else {
    csvContent = fileBlobAsString(fichierRapportRecent);
  }

  const lines = csvContent.split(/\r?\n/);
  if (lines.length <= 1) return;

  const separator = lines[0].includes(";") ? ";" : ",";
  const statsNuitRecent = { "Wait for Event": 0, "Executing": 0, "Ended OK": 0, "Ended Not OK": 0, "Total": 0 };
  const jobsInErrorDerniereNuit = [];
  let odatFrRecent = odatFrCible;
  let totalJobsDerniereNuit = 0;

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const cols = parseCsvLigneRFC4180(line, separator);
    if (cols.length < 4) continue;

    const application = cols[0] ? cols[0].toUpperCase().replace(/"/g, '').trim() : "";
    if (!application.includes("FINANCE") && !application.includes("FIN-FINANCE")) continue;

    const jobName = cols[2] ? cols[2].replace(/"/g, '').trim() : "";
    const odatRaw = cols[3] ? cols[3].replace(/"/g, '').trim() : "";

    const odatFrParsed = convertirDateTexteVersFr(odatRaw) || odatRaw;
    if (odatFrParsed) {
      odatFrRecent = odatFrParsed;
    }

    const fullDateTimeRegex = /(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}\s+\d{1,2}:\d{2}:\d{2}\s+(?:AM|PM)|\d{1,2}\/\d{1,2}\/\d{4}\s+\d{1,2}:\d{2}:\d{2}(?:\s*(?:AM|PM))?/gi;
    const timeMatches = line.match(fullDateTimeRegex) || [];
    const startTimeRaw = timeMatches[0] || (cols[4] ? cols[4].trim() : "-");
    const endTimeRaw = timeMatches[1] || (cols[5] ? cols[5].trim() : "-");

    const statusRaw = cols[7] ? cols[7].replace(/"/g, '').toUpperCase().trim() : "";
    let cat = "Ended Not OK";
    if (statusRaw.includes("WAIT") || statusRaw.includes("EVENT")) cat = "Wait for Event";
    else if (statusRaw.includes("EXEC") || statusRaw.includes("RUNNING")) cat = "Executing";
    else if (statusRaw.includes("ENDED OK") || statusRaw.includes("ENDED_OK") || statusRaw.includes("SUCCESS") || statusRaw === "OK") cat = "Ended OK";
    else {
      cat = "Ended Not OK";

      const descFonctionnelle = cols[8] ? cols[8].replace(/"/g, '').trim() : "-";

      jobsInErrorDerniereNuit.push({
        jobName: jobName,
        application: application,
        groupName: cols[1] ? cols[1].replace(/"/g, '').trim() : "-",
        odatFr: odatFrRecent,
        description: descFonctionnelle,
        startTime: formaterHeureFr(startTimeRaw),
        endTime: formaterHeureFr(endTimeRaw),
        duree: calculerDureeExecution(startTimeRaw, endTimeRaw)
      });
    }

    statsNuitRecent[cat]++;
    statsNuitRecent["Total"]++;
    totalJobsDerniereNuit++;
  }

  let excelAttachment = null;
  if (jobsInErrorDerniereNuit.length > 0) {
    const logsMapDrive = extraireIndexContenuLogsSysout(folderLogs);
    const echecsDetails = jobsInErrorDerniereNuit.map(item => ({
      ...item,
      status: "Ended Not OK",
      logSysout: chercherLogPourJob(item.jobName, logsMapDrive)
    }));
    excelAttachment = genererFichierExcelAnomaliesLogs(odatFrRecent, echecsDetails);
  }

  let webAppUrl = (typeof WEB_APP_URL !== "undefined" && WEB_APP_URL && !WEB_APP_URL.includes("VOTRE_ID")) 
    ? WEB_APP_URL 
    : ScriptApp.getService().getUrl();

  envoyerEmailSyntheseDerniereNuit(RECIPIENT_EMAIL, totalJobsDerniereNuit, statsNuitRecent, odatFrRecent, jobsInErrorDerniereNuit, excelAttachment, webAppUrl);
}

function normaliserNomJob(jobName) {
  if (!jobName) return "";
  return jobName.toUpperCase().trim().replace(/_[Q|M]$/i, "");
}

function chercherLogPourJob(jobName, logsMapDrive) {
  if (!jobName || !logsMapDrive) return "Aucun log sysout trouvé dans le dossier Sysout.";

  const jobKeyNorm = normaliserNomJob(jobName);
  const jobKeyUpper = jobName.toUpperCase().trim();

  if (logsMapDrive[jobKeyUpper]) return logsMapDrive[jobKeyUpper];
  if (logsMapDrive[jobKeyNorm]) return logsMapDrive[jobKeyNorm];

  for (const k in logsMapDrive) {
    if (k.includes(jobKeyNorm) || jobKeyNorm.includes(k)) {
      return logsMapDrive[k];
    }
  }

  return "Aucun log sysout correspondant trouvé.";
}

function envoyerEmailSyntheseDerniereNuit(recipient, totalJobs, statsNuit, odatFr, jobsInError, excelAttachment, webAppUrl) {
  const dateStr = Utilities.formatDate(new Date(), "Europe/Paris", "dd/MM/yyyy HH:mm");
  const subject = "[Control-M] [FINANCE] Rapport du " + dateStr;

  const isConforme = statsNuit["Ended Not OK"] === 0;
  const headerBg = isConforme ? "#2e7d32" : "#b02a37";

  let htmlBody = "<div style='font-family: Arial, sans-serif; max-width: 950px; margin: 0 auto;'>";
  
  htmlBody += "<div style='background-color: " + headerBg + "; color: white; text-align: center; padding: 15px; border-radius: 4px 4px 0 0;'>";
  htmlBody += "<h2 style='margin:0; text-transform: uppercase;'>SYNTHÈSE DE LA NUIT APPLICATIVE (FIN-FINANCE)</h2>";
  htmlBody += "<div style='font-weight: bold; margin-top: 5px;'>" + (isConforme ? "TOUS LES JOBS SONT CONFORMES" : "ANOMALIES DÉTECTÉES SUR LA NUIT DU " + odatFr) + "</div></div>";

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>1. Statuts des Jobs pour la Nuit Applicative du " + odatFr + " :</h3>";
  htmlBody += "<table style='width: 100%; border-collapse: collapse; text-align: center; font-size: 11px;' border='1' borderColor='#ddd'>";
  htmlBody += "<tr style='background-color: #0f4c81; color: white; font-weight: bold;'><th>ODAT</th><th>Wait</th><th>Executing</th><th>Ended OK</th><th>Ended Not OK</th><th>Total</th><th>Statut</th></tr>";
  htmlBody += "<tr><td style='font-weight: bold; color: #0d47a1; padding: 6px;'>" + (odatFr || "-") + "</td><td>" + statsNuit["Wait for Event"] + "</td><td>" + statsNuit["Executing"] + "</td><td>" + statsNuit["Ended OK"] + "</td><td style='font-weight: bold; color: " + (statsNuit["Ended Not OK"] > 0 ? "#b02a37" : "#333") + ";'>" + statsNuit["Ended Not OK"] + "</td><td>" + totalJobs + "</td><td><span style='background-color: " + (isConforme ? "#198754" : "#dc3545") + "; color: white; padding: 2px 8px; border-radius: 3px; font-weight: bold;'>" + (isConforme ? "OK" : "NOK") + "</span></td></tr>";
  htmlBody += "</table>";

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>2. Cartographie d'Ordonnancement :</h3>";
  htmlBody += "<div style='margin-top: 8px; margin-bottom: 20px; font-size: 12px; color: #333;'>";
  htmlBody += "🔗 <a href='" + webAppUrl + "' target='_blank' style='color: #0284c7; font-weight: bold; text-decoration: underline;'>Ouvrir la Cartographie d'Ordonnancement interactive (" + totalJobs + " jobs) — FIN-FINANCE</a>";
  htmlBody += "</div>";

  htmlBody += "<h3 style='color: #0d47a1; font-size: 14px; margin-top: 25px; margin-bottom: 10px;'>3. Liste des Jobs en Erreur (Détails d'Exécution) :</h3>";
  
  if (!isConforme && jobsInError && jobsInError.length > 0) {
    htmlBody += "<table style='width: 100%; border-collapse: collapse; font-size: 11px; text-align: center;' border='1' borderColor='#ddd'>";
    htmlBody += "<tr style='background-color: #b02a37; color: white; font-weight: bold;'>";
    htmlBody += "<th style='padding: 8px;'>Nom du Job</th>";
    htmlBody += "<th style='padding: 8px;'>Description Fonctionnelle</th>";
    htmlBody += "<th style='padding: 8px;'>Heure Début</th>";
    htmlBody += "<th style='padding: 8px;'>Heure Fin</th>";
    htmlBody += "<th style='padding: 8px;'>Durée</th>";
    htmlBody += "<th style='padding: 8px;'>Statut</th>";
    htmlBody += "</tr>";

    jobsInError.forEach(item => {
      htmlBody += "<tr style='border-bottom: 1px solid #eee;'>";
      htmlBody += "<td style='padding: 8px; font-family: monospace; font-weight: bold; color: #b02a37;'>" + (item.jobName || "-") + "</td>";
      htmlBody += "<td style='padding: 8px; text-align: left;'>" + (item.description || "-") + "</td>";
      htmlBody += "<td style='padding: 8px;'>" + (item.startTime || "-") + "</td>";
      htmlBody += "<td style='padding: 8px;'>" + (item.endTime || "-") + "</td>";
      htmlBody += "<td style='padding: 8px; font-weight: bold;'>" + (item.duree || "-") + "</td>";
      htmlBody += "<td style='padding: 8px;'><span style='background-color: #dc3545; color: white; padding: 2px 6px; border-radius: 3px; font-weight: bold;'>Ended Not OK</span></td>";
      htmlBody += "</tr>";
    });

    htmlBody += "</table>";
  } else {
    htmlBody += "<div style='background-color: #f4f6f8; border: 1px solid #ddd; padding: 12px; font-size: 12px; color: #2e7d32; font-weight: bold; text-align: center;'>";
    htmlBody += "✔ Aucun job en erreur lors de cette nuit applicative.";
    htmlBody += "</div>";
  }

  if (excelAttachment) {
    htmlBody += "<p style='font-size: 12px; color: #b02a37; font-weight: bold; margin-top: 15px;'>📎 Un fichier Excel/CSV est joint à cet e-mail avec le détail des échecs et le contenu de leurs logs SYSOUT.</p>";
  }

  htmlBody += "</div>";

  const options = { to: recipient, subject: subject, htmlBody: htmlBody };
  if (excelAttachment) options.attachments = [excelAttachment];
  MailApp.sendEmail(options);
}

/* ==========================================================================
   MODULES ANNEXES ET UTILITAIRES DE SUPPORT
   ========================================================================== */

function fileBlobAsString(file) {
  return file.getBlob().getDataAsString();
}

function obtenirDernierFichierRapportDrive(folder, odatFrCible) {
  if (!folder) return null;

  const files = folder.getFiles();
  let latestFileMatch = null;
  let latestFileFallback = null;
  let maxDateMatch = new Date(0);
  let maxDateFallback = new Date(0);

  let patternOdat = "";
  if (odatFrCible) {
    const parts = odatFrCible.split("/");
    if (parts.length === 3) {
      patternOdat = parts[2].substring(2) + parts[1] + parts[0];
    }
  }

  while (files.hasNext()) {
    const file = files.next();
    if (file.isTrashed()) continue;

    const fName = file.getName();
    const lastModif = file.getLastUpdated();

    if (patternOdat && fName.includes(patternOdat)) {
      if (lastModif > maxDateMatch) {
        maxDateMatch = lastModif;
        latestFileMatch = file;
      }
    }

    if (lastModif > maxDateFallback) {
      maxDateFallback = lastModif;
      latestFileFallback = file;
    }
  }

  if (latestFileMatch) {
    Logger.log("✔ [RAPPORT CTM CIBLÉ ODAT] Fichier sélectionné pour ODAT=" + odatFrCible + " : " + latestFileMatch.getName());
    return latestFileMatch;
  }

  return latestFileFallback;
}

function extraireIndexContenuLogsSysout(folderLogs) {
  const indexLogs = {};
  if (!folderLogs) return indexLogs;
  const files = folderLogs.getFiles();

  while (files.hasNext()) {
    const file = files.next();
    if (file.isTrashed()) continue;
    const name = file.getName().toLowerCase();

    if (name.endsWith(".zip")) {
      try {
        Utilities.unzip(file.getBlob()).forEach(b => {
          const rawName = b.getName().replace(/\.[^/.]+$/, "").toUpperCase().trim();
          const normName = normaliserNomJob(rawName);
          const content = b.getDataAsString();

          indexLogs[rawName] = content;
          indexLogs[normName] = content;
        });
      } catch (e) {
        Logger.log("Avertissement Unzip Sysout : " + e.toString());
      }
    } else if (name.endsWith(".log") || name.endsWith(".txt") || name.endsWith(".out")) {
      const rawName = file.getName().replace(/\.[^/.]+$/, "").toUpperCase().trim();
      const normName = normaliserNomJob(rawName);
      const content = file.getBlob().getDataAsString();

      indexLogs[rawName] = content;
      indexLogs[normName] = content;
    }
  }

  return indexLogs;
}

function genererFichierExcelAnomaliesLogs(odatFr, echecsDetails) {
  let csvContent = "\uFEFFJob Name;Application;Groupe;ODAT;Statut CTM;Contenu Log Sysout\n";

  echecsDetails.forEach(item => {
    const logPropre = (item.logSysout || "")
      .replace(/"/g, '""')
      .replace(/\r?\n/g, " | ");

    csvContent += '"' + item.jobName + '";"' + item.application + '";"' + item.groupName + '";"' + item.odatFr + '";"' + item.status + '";"' + logPropre + '"\n';
  });

  return Utilities.newBlob(csvContent, "text/csv; charset=utf-8", "Anomalies_ControlM_Derniere_Nuit_" + odatFr.replace(/\//g, "-") + ".csv");
}

function sauvegarderDernierRapportCTM() {
  const folder = obtenirDossierSecurise(FOLDER_REPORTS_ID, "Rapports CTM");
  if (!folder) return;

  const SEARCH_QUERY = 'subject:("Extract CSV du Suivi Quotidien CTM" OR "Report_ctm") (filename:zip OR filename:csv)';
  const threads = GmailApp.search(SEARCH_QUERY, 0, 10);

  threads.forEach(thread => {
    thread.getMessages().forEach(msg => {
      msg.getAttachments().forEach(att => {
        const name = att.getName();
        if (name.toLowerCase().endsWith(".zip") || name.toLowerCase().endsWith(".csv")) {
          if (!folder.getFilesByName(name).hasNext()) {
            const newFile = folder.createFile(att.copyBlob());
            Logger.log("✔ [RAPPORT CTM SAUVEGARDÉ DRIVE] Fichier ZIP/CSV : " + newFile.getName());
          }
        }
      });
    });
  });
}

function recupererRapportCtmDepuisGmail(targetFolder, odatFr) {
  const files = targetFolder ? targetFolder.getFiles() : [];
  return files.hasNext() ? files.next() : null;
}

function recupererLogsSysoutDepuisGmail(targetFolder, odatFr) {
  try {
    const folder = targetFolder || obtenirDossierSecurise(FOLDER_LOGS_ID, "Sysout Logs");
    if (!folder) return;

    const query = 'subject:("Sysout" OR "Log CTM" OR "LOG" OR "Output" OR "Control-M Log") (filename:log OR filename:txt OR filename:out OR filename:zip)';
    const threads = GmailApp.search(query, 0, 10);

    threads.forEach(thread => {
      thread.getMessages().forEach(msg => {
        msg.getAttachments().forEach(att => {
          const name = att.getName();
          const nameLower = name.toLowerCase();
          if (nameLower.endsWith(".log") || nameLower.endsWith(".txt") || nameLower.endsWith(".out") || nameLower.endsWith(".zip")) {
            if (!folder.getFilesByName(name).hasNext()) {
              folder.createFile(att.copyBlob());
            }
          }
        });
      });
    });
  } catch (e) {
    Logger.log("Avertissement récupération Gmail Sysout : " + e.toString());
  }
}

function traiterLogsSysoutControlM(odatCible) { return []; }

function lireJobsCloturePdpStrict() {
  const pdpFile = obtenirFichierPlanDeProduction();
  if (!pdpFile) return [];
  const spreadsheet = SpreadsheetApp.open(pdpFile);
  const data = spreadsheet.getSheets()[0].getDataRange().getValues();
  const list = [];
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const jobName = row[2] ? row[2].toString().trim() : "";
    const typeChaine = row[8] ? row[8].toString().trim() : "";
    if (jobName && (typeChaine.toLowerCase().includes("clôture") || typeChaine.toLowerCase().includes("cloture"))) {
      list.push({ jobName: jobName, description: row[3] || "-", typeChaine: typeChaine, planification: row[9] || "-", script: row[19] || "-" });
    }
  }
  return list;
}

function obtenirFichierPlanDeProduction() {
  const fichierEmail = rechercherPlanDeProductionDepuisEmail();
  if (fichierEmail) {
    Logger.log("✔ [PDP OBTENU GMAIL] Fichier Excel : " + fichierEmail.getName() + " (Modifié le " + fichierEmail.getLastUpdated() + ")");
    return fichierEmail;
  }

  Logger.log("ℹ [PDP OBTENU DRIVE] Fallback sur le dernier fichier Excel valide du Drive...");
  return rechercherDernierPlanDeProductionDrive();
}

function rechercherPlanDeProductionDepuisEmail() {
  try {
    const dateSeptJours = new Date();
    dateSeptJours.setDate(dateSeptJours.getDate() - 7);
    const dateQueryStr = Utilities.formatDate(dateSeptJours, "GMT", "yyyy/MM/dd");

    const query = 'subject:("Plan de production" OR "Plan de prod" OR "PDP" OR "Planning") after:' + dateQueryStr + ' (filename:xlsx OR filename:xls)';
    Logger.log(">>> [RECHERCHE GMAIL PDP] Requête ciblée Excel : " + query);

    const threads = GmailApp.search(query, 0, 15);

    let dernierMessage = null;
    let dernierePieceJointe = null;
    let datePlusRecente = new Date(0);

    for (let i = 0; i < threads.length; i++) {
      const messages = threads[i].getMessages();
      for (let j = 0; j < messages.length; j++) {
        const msg = messages[j];
        const msgDate = msg.getDate();

        if (msgDate > datePlusRecente) {
          const attachments = msg.getAttachments();
          for (let k = 0; k < attachments.length; k++) {
            const att = attachments[k];
            const attName = att.getName().toLowerCase();

            if ((attName.endsWith(".xlsx") || attName.endsWith(".xls")) && 
                (attName.includes("plan") || attName.includes("pdp") || attName.includes("prod") || attName.includes("planning"))) {
              datePlusRecente = msgDate;
              dernierMessage = msg;
              dernierePieceJointe = att;
            }
          }
        }
      }
    }

    if (dernierePieceJointe) {
      const folder = obtenirDossierSecurise(FOLDER_PLANNING_ID, "Plannings PDP") || DriveApp.getRootFolder();
      const fileName = dernierePieceJointe.getName();

      Logger.log("✔ [PDP EXCEL GMAIL DÉTECTÉ] Fichier : " + fileName + " (Mail du : " + Utilities.formatDate(datePlusRecente, "Europe/Paris", "dd/MM/yyyy HH:mm:ss") + ")");

      const existing = folder.getFilesByName(fileName);
      if (existing.hasNext()) {
        return existing.next();
      }

      const newFile = folder.createFile(dernierePieceJointe.copyBlob());
      return newFile;
    } else {
      Logger.log("ℹ [GMAIL PDP] Aucun e-mail avec pièce jointe Excel PDP (.xlsx) trouvé sur les 7 derniers jours.");
    }
  } catch (e) {
    Logger.log("Avertissement recherche Gmail PDP : " + e.toString());
  }

  return null;
}

function rechercherDernierPlanDeProductionDrive() {
  const foldersToSearch = [
    obtenirDossierSecurise(FOLDER_PLANNING_ID, "Plannings"),
    obtenirDossierSecurise(FOLDER_REPORTS_ID, "Rapports")
  ];

  let latestFile = null;
  let latestDate = new Date(0);

  foldersToSearch.forEach(folder => {
    if (!folder) return;
    const files = folder.getFiles();
    while (files.hasNext()) {
      const file = files.next();
      const nameLower = file.getName().toLowerCase();

      if (nameLower.includes("210523")) {
        continue;
      }

      if ((nameLower.includes("plan") || nameLower.includes("pdp") || nameLower.includes("prod")) && (nameLower.endsWith(".xlsx") || nameLower.endsWith(".xls"))) {
        if (file.getLastUpdated() > latestDate) {
          latestDate = file.getLastUpdated();
          latestFile = file;
        }
      }
    }
  });

  return latestFile;
}

function trouverFichierRapportParDate(folder, odatFr) {
  const files = folder.getFiles();
  return files.hasNext() ? files.next() : null;
}

function lireLignesRapportCtmAvecLogs(file, pdpJobsMap) {
  let csvContent = "";
  if (file.getName().toLowerCase().endsWith(".zip")) {
    Utilities.unzip(file.getBlob()).forEach(b => csvContent += b.getDataAsString() + "\n");
  } else {
    csvContent = file.getBlob().getDataAsString();
  }
  const lines = csvContent.split(/\r?\n/);
  const list = [];
  if (lines.length <= 1) return list;
  const separator = lines[0].includes(";") ? ";" : ",";

  for (let i = 1; i < lines.length; i++) {
    const cols = parseCsvLigneRFC4180(lines[i], separator);
    if (cols.length < 3) continue;
    const jobKey = cols[2] ? cols[2].toUpperCase().trim() : "";
    if (pdpJobsMap[jobKey]) {
      const fullDateTimeRegex = /(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}\s+\d{1,2}:\d{2}:\d{2}\s+(?:AM|PM)|\d{1,2}\/\d{1,2}\/\d{4}\s+\d{1,2}:\d{2}:\d{2}(?:\s*(?:AM|PM))?/gi;
      const timeMatches = lines[i].match(fullDateTimeRegex) || [];
      const lineUpper = lines[i].toUpperCase();

      list.push({
        jobName: cols[2],
        odatFr: cols[3] || "",
        startTimeRaw: timeMatches[0] || "-",
        endTimeRaw: timeMatches[1] || "-",
        status: (lineUpper.includes("ENDED OK") || lineUpper.includes("SUCCESS")) ? "Ended OK" : "Not OK",
        description: cols[8] ? cols[8].replace(/"/g, '').trim() : "-"
      });
    }
  }
  return list;
}

function parseCsvLigneRFC4180(line, separator) {
  const result = [];
  let cur = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') { cur += '"'; i++; }
      else inQuotes = !inQuotes;
    } else if (char === separator && !inQuotes) {
      result.push(cur.trim()); cur = '';
    } else cur += char;
  }
  result.push(cur.trim());
  return result.map(c => c.replace(/^"|"$/g, '').trim());
}

function formaterHeureFr(heureStr) {
  if (!heureStr || heureStr === "-") return "-";
  const ampmMatch = heureStr.match(/(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)/i);
  if (ampmMatch) {
    let h = parseInt(ampmMatch[1], 10);
    if (ampmMatch[4].toUpperCase() === "PM" && h < 12) h += 12;
    if (ampmMatch[4].toUpperCase() === "AM" && h === 12) h = 0;
    return (h < 10 ? '0' + h : h) + ":" + ampmMatch[2] + ":" + ampmMatch[3];
  }
  return heureStr;
}

function calculerDureeExecution(startStr, endStr) {
  if (!startStr || !endStr || startStr === "-" || endStr === "-") return "-";
  const toSec = (str) => {
    const p = formaterHeureFr(str).split(':').map(Number);
    return p.length === 3 ? p[0] * 3600 + p[1] * 60 + p[2] : 0;
  };
  let diffSec = toSec(endStr) - toSec(startStr);
  if (diffSec < 0) diffSec += 86400;
  const h = Math.floor(diffSec / 3600), m = Math.floor((diffSec % 3600) / 60), s = diffSec % 60;
  return (h > 0 ? h + "h " : "") + m + "m " + s + "s";
}

function convertirDateTexteVersFr(dateStr) {
  if (!dateStr) return "";
  const frMatch = dateStr.match(/(\d{2})\/(\d{2})\/(\d{4})/);
  if (frMatch) return frMatch[0];
  return dateStr;
}

function obtenirDossierSecurise(folderId, nomLog) {
  if (!folderId) return null;
  try { return DriveApp.getFolderById(folderId); }
  catch (e) { return null; }
}

function envoyerEmailSyntheseCloturePdp(recipient, odatFr, jobsData) {
  let htmlBody = "<div style='font-family: Arial; max-width: 950px;'><h2>RAPPORT D'EXÉCUTION DES JOBS DE CLÔTURE — NUIT DU " + odatFr + "</h2>";
  htmlBody += "<table border='1' style='width:100%; border-collapse:collapse; text-align:center;'>";
  htmlBody += "<tr style='background:#0f4c81; color:white;'><th>Job</th><th>Description</th><th>Planification</th><th>Script</th><th>Statut</th><th>Début</th><th>Fin</th><th>Durée</th></tr>";

  jobsData.forEach(item => {
    htmlBody += "<tr><td>" + item.jobName + "</td><td>" + item.description + "</td><td>" + item.planification + "</td><td>" + item.script + "</td><td>" + item.status + "</td><td>" + item.startTime + "</td><td>" + item.endTime + "</td><td>" + item.duree + "</td></tr>";
  });

  htmlBody += "</table></div>";
  MailApp.sendEmail({ to: recipient, subject: "[Clôture T3] Suivi des Jobs de Clôture / Nuit du " + odatFr, htmlBody: htmlBody });
}