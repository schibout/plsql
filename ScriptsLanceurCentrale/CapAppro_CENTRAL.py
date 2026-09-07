# -*- coding: utf-8 -*-
"""
Created on Tue Dec  5 12:08:13 2023
@author: jguedes
V2.0

O R D O N N A N C E U R   C E N T R A L

Lit le Google Sheet d'ordonnancement, puis lance un worker
(CapAppro_GENERIQUE_EXECUTION.py) par projet a executer.

Historique V2.0 :
  - toutes les constantes sont sorties dans config_lanceur_central.ini
  - la sortie du worker est relayee EN DIRECT (plus de bufferisation)
  - marqueurs DEBUT / FIN horodates autour de chaque projet
  - timeout par projet
  - correction du double appel a communicate() qui perdait stderr
  - decodage UTF-8 (les accents n'etaient plus lisibles)
  - suppression du code mort situe apres sys.exit()
"""

import logging
import os
import sys

import numpy as np
import pandas as pd

from capappro_config import (Config, lancerCommande, log, logDebut,
                             logFin, logSection)

# =============================================================================
#   CONFIGURATION
# =============================================================================
DOSSIER_SCRIPT = os.path.dirname(os.path.abspath(__file__))
config = Config(DOSSIER_SCRIPT)

# Librairies maison (gdrive / pylibrary / gmail)
libraryPath = config.getDossier("paths", "LIBRARY_PATH")
if libraryPath and libraryPath not in sys.path:
    sys.path.append(libraryPath)
from pylibrary import libraries
from gmail import Mail
from gdrive import gdrive

SCRIPT_FOLDER = config.dossierScripts()
WORKER_SCRIPT = config.get("paths", "WORKER_SCRIPT")

DRIVE_ROOT_ID = config.get("ordonnanceur", "DRIVE_ROOT_ID")
SPREADSHEET_ID = config.get("ordonnanceur", "SPREADSHEET_ID")
ONGLET_LANCEUR = config.get("ordonnanceur", "ONGLET_LANCEUR")
GDRIVE_TOKEN = config.get("ordonnanceur", "GDRIVE_TOKEN")

MSG_TO = config.get("mail", "MSG_TO_CENTRAL")
NOM_ROBOT = config.get("mail", "NOM_ROBOT_CENTRAL")

TIMEOUT_PROJET = config.getInt("execution", "TIMEOUT_PROJET_SECONDES", 0)
ENVIRONNEMENT = config.get("env", "environnement", "run")

utils = libraries()
mail = Mail()

errorMessage = ""
hasFailure = False


# =============================================================================
#   OUTILS
# =============================================================================
def is_NaN(txt):
    try:
        return bool(np.isnan(txt))
    except Exception:
        return False


def launchCmd(cmd, args=None, logInfo=None, timeoutSeconds=None):
    """Lance le worker et relaie sa sortie ligne par ligne, en direct.

    La commande construite est strictement identique a celle de la version
    precedente (meme programme, memes arguments, meme quoting) : seule la
    facon de lire la sortie change.
    """
    if args is None:
        commande = "py \"" + cmd + "\""
    else:
        commande = "py \"" + cmd + "\" " + args

    log("Lancement de la commande")
    log(commande)
    if logInfo is not None:
        log(utils.cptStart(logInfo))
        logging.info(utils.cptStart(logInfo))

    return lancerCommande(commande, timeoutSeconds=timeoutSeconds)


# =============================================================================
#   1 - LECTURE DU PLAN D'EXECUTION
# =============================================================================
logSection("ORDONNANCEUR CENTRAL - environnement '%s'" % ENVIRONNEMENT)

gdriveLanceur = gdrive(DRIVE_ROOT_ID, token=GDRIVE_TOKEN)
dfRequestLists = gdriveLanceur.exportGsheetToDataFrame(
    SPREADSHEET_ID, ONGLET_LANCEUR)
dfRequestLists["IdExec"] = dfRequestLists["IdExec"].astype("int")
log("Plan d'exécution chargé : %d ligne(s)" % dfRequestLists.shape[0])

# Filtre eventuel pose par Rundeck (option IDEXEC)
oneRowExecution = os.environ.get("RD_OPTION_IDEXEC") or None
if not oneRowExecution:
    log("Pas de filtre d'exécution : toutes les lignes actives seront traitées.")

dfRequestsFolders = dfRequestLists.loc[
    dfRequestLists["Exécution"].str.lower() == "oui"]

if oneRowExecution:
    try:
        myExecutionsList = [int(valeur.strip())
                            for valeur in oneRowExecution.split(",")
                            if valeur.strip()]
    except Exception:
        log("Identifiants d'exécution illisibles : '%s'" % oneRowExecution,
            niveau="ERROR")
        raise Exception("Arrêt du script : option IDEXEC invalide")
    log("Filtre d'exécution demandé : %s" % myExecutionsList)
    dfRequestsFolders = dfRequestsFolders[
        dfRequestsFolders["IdExec"].isin(myExecutionsList)]

log("Projets retenus : %d" % dfRequestsFolders.shape[0])

# =============================================================================
#   2 - CONSTRUCTION DES COMMANDES
# =============================================================================
cmdListToExecute = []
numRow = 0

for index, row in dfRequestsFolders.iterrows():
    numRow += 1

    log("CONTROLE %d" % numRow)

    # OBLIGATOIRES
    idExec = row['IdExec']
    projectName = row['ProjectName']
    execution = row['Exécution']
    DownloadDossier_drive_id = row['DownloadDossier_drive_id']
    filenameLanceur = row['filenameLanceur']
    config = row['config']

    # OPTIONNELS
    UploadDossier_drive_id = row['UploadDossier_drive_id']
    copiedataviz = row['Copiedataviz']
    log("copiedataviz :: %s" % copiedataviz)
    # Le test 'not is_NaN' est le seul ajout : sans lui une cellule vide lue
    # depuis un .xlsx (valeur NaN, un flottant) fait echouer copiedataviz[-1]
    # avec une TypeError non rattrapee qui interrompt tout l'ordonnanceur.
    # Comportement inchange pour les valeurs venant du Google Sheet.
    if copiedataviz != "" and not is_NaN(copiedataviz):
        if copiedataviz[-1] != "\\":
            copiedataviz = rf"{copiedataviz}\\"

    ListeDeDiffusion = row['ListeDeDiffusion']
    DateExpirationRequetes = row['Date_expiration_requête']

    # =========================================================================
    #  contrôle sur les valeurs nan
    # =========================================================================
    if is_NaN(idExec) or is_NaN(projectName) or is_NaN(execution) \
            or is_NaN(DownloadDossier_drive_id) or is_NaN(filenameLanceur) \
            or is_NaN(config):
        log(">>> La ligne ne peut pas être exécutée. "
            "Paramètres obligatoires manquants", niveau="ERROR")
        errorMessage += f"""
                    pour la ligne suivante, des données obligatoires sont manquantes :
                    "idExec : " {idExec}
                    "projectName : " {projectName}
                    "execution : " {execution}
                    "DownloadDossier_drive_id : " {DownloadDossier_drive_id}
                    "filenameLanceur : " {filenameLanceur}
                    """
        continue
    elif is_NaN(UploadDossier_drive_id) and is_NaN(copiedataviz):
        log(">>> La ligne ne peut pas être exécutée. Au moins un des "
            "paramètres optionnels doit être présent", niveau="ERROR")
        errorMessage += f"""
                    pour la ligne suivante, des données optionnelles sont manquantes :
                    "copiedataviz : " {copiedataviz}
                    "UploadDossier_drive_id : " {UploadDossier_drive_id}
                    """
        continue
    else:
        log(">>> On peut lancer la commande")

    # Commande strictement identique a la version precedente : memes
    # arguments, memes valeurs brutes, meme quoting.
    cmdLine = f'"{WORKER_SCRIPT}"'
    args = f' --idExec "{idExec}" --ProjectName "{projectName}" --DownloadDossier_drive_id "{DownloadDossier_drive_id}" --filenameLanceur "{filenameLanceur}" --UploadDossier_drive_id "{UploadDossier_drive_id}" --ListeDeDiffusion "{ListeDeDiffusion}" --requestExpirationDate "{DateExpirationRequetes}" --configBDD "{config}" --copiedataviz "{copiedataviz}"'

    cmdListToExecute.append({
        "IdExec": idExec,
        "ProjectName": projectName,
        "cmdLine": cmdLine,
        "args": args,
    })

# =============================================================================
#   3 - EXECUTION
# =============================================================================
log("%d projet(s) à lancer." % len(cmdListToExecute))
if TIMEOUT_PROJET:
    log("Timeout par projet : %d s" % TIMEOUT_PROJET)
else:
    log("Aucun timeout configuré (execution.TIMEOUT_PROJET_SECONDES = 0)",
        niveau="WARN")

numProjet = 0
for commande in cmdListToExecute:
    numProjet += 1
    libelle = "PROJET [%d/%d] IdExec %s - %s" % (
        numProjet, len(cmdListToExecute),
        commande["IdExec"], commande["ProjectName"])

    debut = logDebut(libelle)
    statut = "OK"
    try:
        outputExec = launchCmd(commande["cmdLine"],
                               commande["args"],
                               timeoutSeconds=TIMEOUT_PROJET or None)

        if outputExec is None:
            statut = "KO"
            hasFailure = True
            log("Le lancement de la commande a échoué.", niveau="ERROR")
            errorMessage += (
                "<br><b>Error</b> : le lancement du projet <b>%s</b> "
                "(IdExec %s) a échoué.<br>"
                % (commande["ProjectName"], commande["IdExec"]))
        elif outputExec[0] == 0:
            log("Traitement terminé sans erreur.")
        else:
            statut = "KO"
            hasFailure = True
            log("Le traitement s'est terminé en erreur (code %s)"
                % outputExec[0], niveau="ERROR")
            if outputExec[2]:
                log("Sortie d'erreur :\n%s" % outputExec[2], niveau="ERROR")
            errorMessage += (
                "<br><b>Error</b> : projet <b>%s</b> (IdExec %s), "
                "code retour %s.<br><pre>%s</pre><br>"
                % (commande["ProjectName"], commande["IdExec"],
                   outputExec[0], outputExec[2] or "(pas de détail)"))
    except Exception as Err:
        statut = "KO"
        hasFailure = True
        log("Exception pendant l'exécution : %s" % Err, niveau="ERROR")
        errorMessage += (
            "<br><b>Error</b> : exception sur le projet <b>%s</b> "
            "(IdExec %s)<br>%s<br>"
            % (commande["ProjectName"], commande["IdExec"], Err))
    finally:
        logFin(libelle, debut, statut)

# =============================================================================
#   4 - RESTITUTION
# =============================================================================
logSection("FIN DE L'ORDONNANCEUR")

if errorMessage:
    log("Envoi du mail d'incident à %s" % MSG_TO, niveau="ERROR")
    mail.ErreurRobot(nomRobot=NOM_ROBOT,
                     subjectMail="%s - Incident(s) rencontré(s)" % NOM_ROBOT,
                     msgTo=MSG_TO,
                     msgError=errorMessage)
    hasFailure = True

if hasFailure:
    # Code retour non nul : Rundeck doit voir le job en echec.
    raise Exception("Des erreurs ont été rencontrées, voir le détail ci-dessus.")

log("Toutes les exécutions se sont terminées correctement.")
sys.exit(0)
