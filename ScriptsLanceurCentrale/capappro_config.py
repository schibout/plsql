# -*- coding: utf-8 -*-
"""
Configuration partagee et journalisation du lanceur centralise CapAppro.

Ce module est importe par :
  - CapAppro_CENTRAL.py             (ordonnanceur)
  - CapAppro_GENERIQUE_EXECUTION.py (worker)

Il porte trois responsabilites :
  1. localiser et charger config_lanceur_central.ini ;
  2. exposer les valeurs de configuration (avec surcharge par variables
     d'environnement CAPAPPRO_<SECTION>_<CLE>) ;
  3. fournir une journalisation horodatee et non bufferisee, pour que la
     progression soit visible en direct dans Rundeck et pas seulement a la fin.
"""

import os
import sys
import threading
import time
from configparser import ConfigParser, ExtendedInterpolation
from datetime import datetime
from subprocess import PIPE, Popen, TimeoutExpired

NOM_FICHIER_CONFIG = "config_lanceur_central.ini"

# =============================================================================
#   Sortie non bufferisee et en UTF-8.
#   Sans cela Python bufferise son stdout quand il est redirige dans un pipe :
#   toute la sortie n'apparait qu'a la fin du process (parfois 12 minutes plus
#   tard), ce qui rend un traitement bloque indetectable.
# =============================================================================


def activerSortieDirecte():
    for flux in (sys.stdout, sys.stderr):
        try:
            flux.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
        except Exception:
            pass


activerSortieDirecte()


# =============================================================================
#   Journalisation
# =============================================================================

def horodatage():
    return datetime.now().strftime("%H:%M:%S")


def log(message, niveau="INFO"):
    """Affiche un message horodate et le pousse immediatement dans le pipe."""
    print("%s [%s] %s" % (horodatage(), niveau, message), flush=True)


def logDebut(libelle):
    """Marque le debut d'une etape et retourne son instant de depart."""
    log(">>> DEBUT  %s" % libelle)
    return time.time()


def logFin(libelle, debut, statut="OK"):
    """Marque la fin d'une etape en rappelant sa duree et son statut."""
    duree = time.strftime("%H:%M:%S", time.gmtime(max(0, time.time() - debut)))
    log("<<< FIN    %s | statut=%s | duree=%s" % (libelle, statut, duree))
    return duree


def logSection(titre):
    log("=" * 70)
    log(titre)
    log("=" * 70)


# =============================================================================
#   Chargement de la configuration
# =============================================================================

def cheminConfig(dossierScript=None):
    """Chemin du .ini : variable d'environnement, sinon a cote du script."""
    surcharge = os.environ.get("CAPAPPRO_CONFIG")
    if surcharge:
        return surcharge
    if dossierScript is None:
        dossierScript = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(dossierScript, NOM_FICHIER_CONFIG)


def chargerConfig(dossierScript=None):
    chemin = cheminConfig(dossierScript)
    cfg = ConfigParser(interpolation=ExtendedInterpolation())
    if not cfg.read(chemin, encoding="utf-8"):
        raise FileNotFoundError(
            "Fichier de configuration introuvable ou illisible : %s" % chemin)
    log("Configuration chargée depuis %s" % chemin)
    return cfg


class Config(object):
    """Acces aux valeurs du .ini, avec surcharge par variable d'environnement.

    Toute cle peut etre surchargee sans modifier le fichier, via une variable
    d'environnement nommee CAPAPPRO_<SECTION>_<CLE> en majuscules. Cela permet
    notamment de sortir les mots de passe du fichier versionne.
    """

    def __init__(self, dossierScript=None):
        self.cfg = chargerConfig(dossierScript)
        self.dossierScript = dossierScript or os.path.dirname(
            os.path.abspath(__file__))

    def __contains__(self, section):
        return section in self.cfg

    def get(self, section, cle, defaut=None):
        nomVariable = ("CAPAPPRO_%s_%s" % (section, cle)).upper()
        if nomVariable in os.environ:
            return os.environ[nomVariable]
        try:
            return self.cfg[section][cle]
        except KeyError:
            if defaut is None:
                raise KeyError(
                    "Clé de configuration manquante : [%s] %s" % (section, cle))
            return defaut

    def getInt(self, section, cle, defaut=None):
        valeur = self.get(section, cle, defaut)
        try:
            return int(str(valeur).strip())
        except (TypeError, ValueError):
            return defaut

    def getListe(self, section, cle, defaut=None, separateur=","):
        valeur = self.get(section, cle, defaut)
        if not valeur:
            return []
        return [element.strip() for element in valeur.split(separateur)
                if element.strip()]

    def getDossier(self, section, cle, defaut=None):
        """Retourne un chemin de dossier normalise, toujours termine par \\."""
        valeur = self.get(section, cle, defaut)
        if not valeur:
            return ""
        valeur = valeur.strip()
        if not valeur.endswith(("\\", "/")):
            valeur += "\\"
        return valeur

    def sectionBDD(self, nomSection):
        """Parametres de connexion d'une base, avec controle de completude."""
        if nomSection not in self.cfg:
            raise KeyError(
                "Section de base de données absente du fichier de "
                "configuration : [%s]. Sections disponibles : %s"
                % (nomSection, ", ".join(
                    s for s in self.cfg.sections() if s.startswith("config_"))))
        attendues = ["BASE_URL", "BASE_PORT", "BASE_SERVICE_NAME",
                     "TYPE", "DB_USER", "DB_PASSWORD"]
        return {cle: self.get(nomSection, cle) for cle in attendues}

    def dossierScripts(self):
        """Dossier des scripts : valeur du .ini, sinon dossier du script."""
        valeur = self.get("paths", "SCRIPT_FOLDER", "")
        if valeur and valeur.strip():
            return self.getDossier("paths", "SCRIPT_FOLDER")
        return os.path.join(self.dossierScript, "")


# =============================================================================
#   Lancement d'un sous-processus avec sortie relayee en direct
# =============================================================================

def _lireFlux(flux, destination):
    """Vide un flux dans une liste, sans bloquer le flux principal."""
    try:
        for ligne in iter(flux.readline, ""):
            destination.append(ligne)
    except Exception:
        pass
    finally:
        try:
            flux.close()
        except Exception:
            pass


def lancerCommande(commande, timeoutSeconds=None, prefixe="    | "):
    """Execute une commande et relaie sa sortie ligne par ligne, en direct.

    Retourne [code_retour, sortie_standard, sortie_erreur], ou None si le
    lancement lui-meme a echoue.

    Deux points importants :
      - PYTHONUNBUFFERED empeche le process fils de bufferiser sa propre
        sortie des lors qu'elle est redirigee dans un pipe. Sans cela, rien
        n'apparait avant la fin du traitement, meme en lisant ligne a ligne.
      - communicate() n'est appele qu'une seule fois (le double appel de la
        version precedente faisait perdre systematiquement stderr).
    """
    lignesSortie = []
    lignesErreur = []

    environnement = os.environ.copy()
    environnement["PYTHONUNBUFFERED"] = "1"
    environnement["PYTHONIOENCODING"] = "utf-8"

    try:
        with Popen(commande,
                   stdout=PIPE,
                   stderr=PIPE,
                   shell=True,
                   env=environnement,
                   universal_newlines=True,
                   encoding="utf-8",
                   errors="replace",
                   bufsize=1) as process:

            lecteurErreur = threading.Thread(
                target=_lireFlux, args=(process.stderr, lignesErreur))
            lecteurErreur.daemon = True
            lecteurErreur.start()

            for ligne in iter(process.stdout.readline, ""):
                ligne = ligne.rstrip("\r\n")
                lignesSortie.append(ligne)
                print("%s%s" % (prefixe, ligne), flush=True)

            try:
                process.stdout.close()
            except Exception:
                pass

            try:
                codeRetour = process.wait(
                    timeout=timeoutSeconds if timeoutSeconds else None)
            except TimeoutExpired:
                log("TIMEOUT : dépassement de %s s, arrêt forcé du processus."
                    % timeoutSeconds, niveau="ERROR")
                process.kill()
                process.wait()
                lignesErreur.append(
                    "Timeout dépassé (%s secondes) : traitement interrompu.\n"
                    % timeoutSeconds)
                codeRetour = 124

            lecteurErreur.join(timeout=5)

        return [codeRetour, "\n".join(lignesSortie), "".join(lignesErreur)]

    except Exception as Err:
        log("Erreur au lancement de la commande : %s" % Err, niveau="ERROR")
        return None


def masquer(valeur):
    """Masque un secret pour l'affichage dans les logs."""
    if not valeur:
        return "(vide)"
    valeur = str(valeur)
    if len(valeur) <= 2:
        return "*" * len(valeur)
    return valeur[0] + "*" * (len(valeur) - 2) + valeur[-1]
