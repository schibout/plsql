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
    py CapAppro_LOCAL.py --check          (diagnostic de l'environnement)
    py CapAppro_LOCAL.py 39 --local       (force la copie locale du classeur)

Le plan d'execution est lu SUR LE DRIVE, comme le fait l'ordonnanceur
central : c'est la source de reference. Si le Drive est injoignable, le
script s'arrete au lieu de basculer silencieusement sur une copie locale
qui pourrait etre perimee. Le repli doit etre demande explicitement, avec
--local ou [local] AUTORISER_REPLI_LOCAL = oui.

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
AUTORISER_REPLI_LOCAL = config.get(
    "local", "AUTORISER_REPLI_LOCAL", "non").strip().lower() == "oui"
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
    verifier = False
    for element in argv:
        if element in ("--dry-run", "--dryrun", "-n"):
            dryRun = True
        elif element in ("--list", "-l"):
            lister = True
        elif element == "--local":
            source = "local"
        elif element == "--drive":
            source = "drive"
        elif element in ("--check", "--diag"):
            verifier = True
        elif element.startswith("--idExec="):
            element = element.split("=", 1)[1]
            ids.extend(p.strip() for p in element.split(",") if p.strip())
        elif element.startswith("-"):
            log("Option inconnue ignorée : %s" % element, niveau="WARN")
        else:
            ids.extend(p.strip() for p in element.split(",") if p.strip())
    return ids, dryRun, lister, source, verifier


MESSAGE_LIB_MANQUANTE = """
Les librairies maison sont introuvables : le Drive n'est pas accessible.

  Dossier attendu : {dossier}
  Module manquant : {module}

Le classeur d'ordonnancement doit être lu sur le Drive. Pour cela, copier
depuis la machine RPA le dossier complet des librairies maison :

    C:\\RPA\\python-libraries\\      (gdrive, pylibrary, gmail)

ainsi que le fichier de jeton OAuth utilisé par gdrive(token="{token}"),
puis renseigner son emplacement dans [paths] LIBRARY_PATH du fichier
config_lanceur_central.ini.

Diagnostic complet de l'environnement : py CapAppro_LOCAL.py --check
"""


def chargerDepuisDrive():
    """Lit le classeur d'ordonnancement directement sur le Drive.

    C'est la meme source que l'ordonnanceur central : les valeurs sont donc
    a jour et arrivent sous la meme forme (des chaines de caracteres).
    """
    libraryPath = config.getDossier("paths", "LIBRARY_PATH")
    if libraryPath and libraryPath not in sys.path:
        sys.path.append(libraryPath)
    try:
        from gdrive import gdrive
    except ImportError as Err:
        raise RuntimeError(MESSAGE_LIB_MANQUANTE.format(
            dossier=libraryPath or "(non renseigné)",
            module=Err.name or "gdrive",
            token=GDRIVE_TOKEN))

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
        log("Source forcée : copie locale du classeur (option --local).",
            niveau="WARN")
        df = chargerDepuisFichier()
    else:
        try:
            df = chargerDepuisDrive()
        except Exception as Err:
            # Le classeur du Drive est la source de reference : on ne bascule
            # pas silencieusement sur une copie locale, qui serait peut-etre
            # perimee. Le repli doit etre demande explicitement.
            log("Lecture du Drive impossible.", niveau="ERROR")
            for ligne in str(Err).strip().splitlines():
                log("  " + ligne, niveau="ERROR")
            if not AUTORISER_REPLI_LOCAL:
                raise RuntimeError(
                    "Arrêt : le plan d'exécution doit être lu sur le Drive.\n"
                    "Pour travailler malgré tout sur une copie locale "
                    "(données potentiellement périmées), relancer avec "
                    "--local, ou passer [local] AUTORISER_REPLI_LOCAL à 'oui'.")
            log("Repli sur la copie locale (AUTORISER_REPLI_LOCAL=oui). "
                "Les données peuvent être périmées.", niveau="WARN")
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


def verifierEnvironnement():
    """Inventaire de ce qui est present ou manquant sur le poste."""
    logSection("DIAGNOSTIC DE L'ENVIRONNEMENT LOCAL")
    manquants = []

    log("Python  : %s" % sys.version.split()[0])
    log("Exécutable : %s" % sys.executable)
    log("")

    log("--- Paquets nécessaires au lanceur local ---")
    for module in ("pandas", "numpy"):
        try:
            __import__(module)
            log("  OK       %s" % module)
        except ImportError:
            log("  MANQUANT %s" % module, niveau="ERROR")
            manquants.append("pip install " + module)

    log("")
    log("--- Paquets nécessaires au worker (l'extraction elle-même) ---")
    for module, paquet in (("fire", "fire"),
                           ("magic", "python-magic-bin"),
                           ("dateutil", "python-dateutil"),
                           ("openpyxl", "openpyxl"),
                           ("xlsxwriter", "XlsxWriter"),
                           ("sqlalchemy", "SQLAlchemy"),
                           ("cx_Oracle", "cx_Oracle")):
        try:
            __import__(module)
            log("  OK       %s" % module)
        except ImportError:
            log("  MANQUANT %s   ->  pip install %s" % (module, paquet),
                niveau="ERROR")
            manquants.append("pip install " + paquet)

    log("")
    log("--- Librairies maison (indispensables pour le Drive) ---")
    libraryPath = config.getDossier("paths", "LIBRARY_PATH")
    log("  LIBRARY_PATH configuré : %s" % (libraryPath or "(vide)"))
    if libraryPath and os.path.isdir(libraryPath):
        log("  OK       le dossier existe")
        if libraryPath not in sys.path:
            sys.path.append(libraryPath)
    else:
        log("  MANQUANT le dossier n'existe pas", niveau="ERROR")
        manquants.append(r"copier C:\RPA\python-libraries\ depuis la machine RPA")

    for module in ("gdrive", "pylibrary", "gmail"):
        try:
            __import__(module)
            log("  OK       %s" % module)
        except ImportError:
            log("  MANQUANT %s" % module, niveau="ERROR")

    log("")
    log("--- Client Oracle ---")
    oracleHome = config.get("paths", "ORACLE_CLIENT_HOME", "")
    log("  ORACLE_CLIENT_HOME : %s" % (oracleHome or "(vide)"))
    if oracleHome and os.path.isdir(oracleHome):
        log("  OK       le dossier existe")
    else:
        log("  MANQUANT le dossier n'existe pas", niveau="ERROR")
        manquants.append("installer le client Oracle (ou Instant Client)")

    log("")
    logSection("RÉSULTAT")
    if not manquants:
        log("Environnement complet : le lanceur local peut fonctionner.")
        return 0
    log("%d élément(s) à régler :" % len(manquants), niveau="ERROR")
    for element in manquants:
        log("  - %s" % element, niveau="ERROR")
    return 1


def main():
    ids, dryRun, lister, source, verifier = lireArguments(sys.argv[1:])

    if verifier:
        return verifierEnvironnement()

    try:
        df = chargerOrdonnanceur(source)
    except Exception as Err:
        # Message lisible plutot qu'une trace d'exception : l'utilisateur a
        # besoin de savoir quoi faire, pas ou le code s'est arrete.
        for ligne in str(Err).strip().splitlines():
            log(ligne, niveau="ERROR")
        return 2

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
