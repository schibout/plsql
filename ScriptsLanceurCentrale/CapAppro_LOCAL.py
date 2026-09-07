# -*- coding: utf-8 -*-
"""
L A N C E U R   L O C A L   C A P A P P R O

Version de mise au point, a lancer depuis un poste de developpement.

Difference avec CapAppro_CENTRAL.py :
  - une seule ligne est traitee, celle dont l'IdExec est demande ;
  - un seul parametre est demande : l'identifiant d'execution.
    Tous les autres arguments du worker sont retrouves dans le fichier Excel.

La commande envoyee au worker reste strictement identique a celle de
l'ordonnanceur : memes 9 arguments, memes valeurs brutes, meme quoting.

Utilisation :
    py CapAppro_LOCAL.py 39
    py CapAppro_LOCAL.py 39,40
    py CapAppro_LOCAL.py 39 --dry-run     (affiche la commande sans l'exécuter)
    py CapAppro_LOCAL.py --list           (liste les IdExec disponibles)
    py CapAppro_LOCAL.py 39 --local       (force la copie locale du classeur)

Le plan d'execution est lu par defaut sur le Drive, comme le fait
l'ordonnanceur central : les valeurs sont donc toujours a jour. Une copie
locale peut servir de repli hors ligne ([local] FICHIER_ORDONNANCEUR).

ATTENTION : le worker exécuté est le vrai worker. Il se connecte à la base,
écrit sur le Drive, envoie les mails de la ListeDeDiffusion et ajoute une
ligne dans l'onglet HistoExec. Utiliser --dry-run pour vérifier avant de
lancer, et de préférence une ligne de test (IdExec 40) ou une configBDD
pointant vers l'environnement de test.
"""

import logging
import os
import sys
from datetime import datetime

import numpy as np
import pandas as pd

from capappro_config import (Config, lancerCommande, log, logDebut,
                             logFin, logSection)

# =============================================================================
#   CONFIGURATION
# =============================================================================
DOSSIER_SCRIPT = os.path.dirname(os.path.abspath(__file__))
config = Config(DOSSIER_SCRIPT)

WORKER_SCRIPT = config.get("paths", "WORKER_SCRIPT")
SOURCE_PLAN = config.get("local", "SOURCE", "drive").strip().lower()
FICHIER_ORDONNANCEUR = config.get("local", "FICHIER_ORDONNANCEUR", "")
ONGLET_ORDONNANCEUR = config.get("local", "ONGLET_ORDONNANCEUR")
RESPECTER_COLONNE_EXECUTION = config.get(
    "local", "RESPECTER_COLONNE_EXECUTION", "non").strip().lower() == "oui"
TIMEOUT_PROJET = config.getInt("execution", "TIMEOUT_PROJET_SECONDES", 0)

DRIVE_ROOT_ID = config.get("ordonnanceur", "DRIVE_ROOT_ID")
SPREADSHEET_ID = config.get("ordonnanceur", "SPREADSHEET_ID")
GDRIVE_TOKEN = config.get("ordonnanceur", "GDRIVE_TOKEN")

COLONNES_ATTENDUES = [
    "IdExec", "ProjectName", "Exécution", "DownloadDossier_drive_id",
    "UploadDossier_drive_id", "Copiedataviz", "filenameLanceur",
    "ListeDeDiffusion", "Date_expiration_requête", "config",
]


def is_NaN(txt):
    try:
        return bool(np.isnan(txt))
    except Exception:
        return False


def resoudreChemin(chemin):
    """Un chemin relatif est interprete par rapport au dossier du script."""
    if os.path.isabs(chemin):
        return chemin
    return os.path.join(DOSSIER_SCRIPT, chemin)


def lireArguments(argv):
    """Analyse la ligne de commande : ids, --dry-run, --list, source."""
    ids = []
    dryRun = False
    lister = False
    source = None
    for element in argv:
        if element in ("--dry-run", "--dryrun", "-n"):
            dryRun = True
        elif element in ("--list", "-l"):
            lister = True
        elif element == "--local":
            source = "local"
        elif element == "--drive":
            source = "drive"
        elif element.startswith("--idExec="):
            element = element.split("=", 1)[1]
            ids.extend(p.strip() for p in element.split(",") if p.strip())
        elif element.startswith("-"):
            log("Option inconnue ignorée : %s" % element, niveau="WARN")
        else:
            ids.extend(p.strip() for p in element.split(",") if p.strip())
    return ids, dryRun, lister, source


def chargerDepuisDrive():
    """Lit le classeur d'ordonnancement directement sur le Drive.

    C'est la meme source que l'ordonnanceur central : les valeurs sont donc
    a jour et arrivent sous la meme forme (des chaines de caracteres).
    L'import de gdrive est fait ici pour que le script reste utilisable sur
    un poste ou la librairie maison n'est pas installee.
    """
    libraryPath = config.getDossier("paths", "LIBRARY_PATH")
    if libraryPath and libraryPath not in sys.path:
        sys.path.append(libraryPath)
    from gdrive import gdrive

    log("Lecture du plan d'exécution sur le Drive : classeur %s (onglet '%s')"
        % (SPREADSHEET_ID, ONGLET_ORDONNANCEUR))
    gdriveLanceur = gdrive(DRIVE_ROOT_ID, token=GDRIVE_TOKEN)
    return gdriveLanceur.exportGsheetToDataFrame(
        SPREADSHEET_ID, ONGLET_ORDONNANCEUR)


def chargerDepuisFichier():
    """Repli hors ligne : lit une copie locale du classeur."""
    if not FICHIER_ORDONNANCEUR:
        raise FileNotFoundError(
            "Aucune copie locale configurée : renseigner "
            "[local] FICHIER_ORDONNANCEUR dans config_lanceur_central.ini.")
    chemin = resoudreChemin(FICHIER_ORDONNANCEUR)
    if not os.path.isfile(chemin):
        raise FileNotFoundError(
            "Fichier d'ordonnancement introuvable : %s" % chemin)

    log("Lecture du plan d'exécution local : %s (onglet '%s')"
        % (chemin, ONGLET_ORDONNANCEUR))
    return pd.read_excel(chemin, sheet_name=ONGLET_ORDONNANCEUR)


def chargerOrdonnanceur(source=None):
    source = (source or SOURCE_PLAN).lower()

    if source == "local":
        df = chargerDepuisFichier()
    else:
        try:
            df = chargerDepuisDrive()
        except Exception as Err:
            log("Lecture du Drive impossible (%s)" % Err, niveau="WARN")
            if not FICHIER_ORDONNANCEUR:
                raise
            log("Repli sur la copie locale.", niveau="WARN")
            df = chargerDepuisFichier()

    absentes = [c for c in COLONNES_ATTENDUES if c not in df.columns]
    if absentes:
        raise KeyError(
            "Colonnes absentes du fichier d'ordonnancement : %s"
            % ", ".join(absentes))

    df = df[df["IdExec"].notna()].copy()
    df["IdExec"] = df["IdExec"].astype("int")
    log("Plan d'exécution chargé : %d ligne(s)" % df.shape[0])
    return df


def construireArguments(row):
    """Construit la chaine d'arguments du worker.

    Identique a celle de l'ordonnanceur : memes 9 arguments dans le meme
    ordre, valeurs brutes issues du fichier (le worker sait deja traiter
    les valeurs 'nan').
    """
    idExec = row['IdExec']
    projectName = row['ProjectName']
    DownloadDossier_drive_id = row['DownloadDossier_drive_id']
    filenameLanceur = row['filenameLanceur']
    config_bdd = row['config']

    UploadDossier_drive_id = row['UploadDossier_drive_id']
    copiedataviz = row['Copiedataviz']
    if copiedataviz != "" and not is_NaN(copiedataviz):
        if copiedataviz[-1] != "\\":
            copiedataviz = rf"{copiedataviz}\\"

    ListeDeDiffusion = row['ListeDeDiffusion']
    # pandas convertit la colonne date en datetime ; le Google Sheet, lui,
    # renvoie du texte au format JJ/MM/AAAA. On reproduit ce format pour que
    # le worker recoive exactement la meme valeur que depuis l'ordonnanceur.
    DateExpirationRequetes = row['Date_expiration_requête']
    if isinstance(DateExpirationRequetes, (pd.Timestamp, datetime)):
        DateExpirationRequetes = DateExpirationRequetes.strftime("%d/%m/%Y")

    manquants = [nom for nom, valeur in (
        ("IdExec", idExec),
        ("ProjectName", projectName),
        ("DownloadDossier_drive_id", DownloadDossier_drive_id),
        ("filenameLanceur", filenameLanceur),
        ("config", config_bdd),
    ) if is_NaN(valeur)]
    if manquants:
        raise ValueError(
            "Paramètres obligatoires manquants : %s" % ", ".join(manquants))

    if is_NaN(UploadDossier_drive_id) and is_NaN(copiedataviz):
        raise ValueError(
            "Au moins un des paramètres UploadDossier_drive_id ou "
            "Copiedataviz doit être renseigné.")

    return f' --idExec "{idExec}" --ProjectName "{projectName}" --DownloadDossier_drive_id "{DownloadDossier_drive_id}" --filenameLanceur "{filenameLanceur}" --UploadDossier_drive_id "{UploadDossier_drive_id}" --ListeDeDiffusion "{ListeDeDiffusion}" --requestExpirationDate "{DateExpirationRequetes}" --configBDD "{config_bdd}" --copiedataviz "{copiedataviz}"'


def afficherListe(df):
    logSection("LIGNES DISPONIBLES DANS %s" % FICHIER_ORDONNANCEUR)
    for _, row in df.iterrows():
        log("  %-5s %-8s %-45s %s" % (
            row["IdExec"],
            str(row["Exécution"]).lower(),
            str(row["ProjectName"])[:45],
            row["config"]))


def main():
    ids, dryRun, lister, source = lireArguments(sys.argv[1:])
    df = chargerOrdonnanceur(source)

    if lister or not ids:
        afficherListe(df)
        if not ids:
            log("Aucun IdExec fourni. Exemple : py CapAppro_LOCAL.py 39",
                niveau="WARN")
            return 0
        return 0

    try:
        idsDemandes = [int(valeur) for valeur in ids]
    except ValueError:
        log("Identifiants d'exécution invalides : %s" % ids, niveau="ERROR")
        return 2

    introuvables = [i for i in idsDemandes if i not in set(df["IdExec"])]
    if introuvables:
        log("IdExec introuvable(s) dans le fichier : %s" % introuvables,
            niveau="ERROR")
        afficherListe(df)
        return 2

    if RESPECTER_COLONNE_EXECUTION:
        avant = set(idsDemandes)
        df = df[df["Exécution"].astype(str).str.lower() == "oui"]
        ignores = avant - set(df["IdExec"])
        if ignores:
            log("Ignoré(s) car Exécution != 'oui' : %s" % sorted(ignores),
                niveau="WARN")

    selection = df[df["IdExec"].isin(idsDemandes)]
    logSection("LANCEUR LOCAL - %d ligne(s) à traiter" % selection.shape[0])

    codeSortie = 0
    numProjet = 0
    total = selection.shape[0]

    for _, row in selection.iterrows():
        numProjet += 1
        libelle = "PROJET [%d/%d] IdExec %s - %s" % (
            numProjet, total, row["IdExec"], row["ProjectName"])

        if str(row["Exécution"]).lower() != "oui":
            log("Note : cette ligne est marquée Exécution='%s' dans le "
                "fichier, elle est lancée quand même car son IdExec a été "
                "demandé explicitement." % row["Exécution"], niveau="WARN")

        try:
            args = construireArguments(row)
        except ValueError as Err:
            log("%s : %s" % (libelle, Err), niveau="ERROR")
            codeSortie = 1
            continue

        commande = 'py "%s" %s' % (WORKER_SCRIPT, args)

        if dryRun:
            log("[DRY-RUN] %s" % libelle)
            log("[DRY-RUN] %s" % commande)
            continue

        debut = logDebut(libelle)
        statut = "OK"
        try:
            resultat = lancerCommande(
                commande, timeoutSeconds=TIMEOUT_PROJET or None)
            if resultat is None:
                statut = "KO"
                codeSortie = 1
                log("Le lancement de la commande a échoué.", niveau="ERROR")
            elif resultat[0] != 0:
                statut = "KO"
                codeSortie = 1
                log("Code retour %s" % resultat[0], niveau="ERROR")
                if resultat[2]:
                    log("Sortie d'erreur :\n%s" % resultat[2], niveau="ERROR")
        finally:
            logFin(libelle, debut, statut)

    logSection("FIN DU LANCEUR LOCAL - code retour %d" % codeSortie)
    return codeSortie


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    sys.exit(main())
