# -*- coding: utf-8 -*-
"""
Lanceur Central - execution de fichiers SQL, ecriture EN FLUX par lots.

Variante optimisee de CapAppro_UN_SQL.py / CapAppro_MULTI_SQL.py pour les
grosses extractions : les lignes sont lues par lots (fetchmany) et ecrites au
fur et a mesure, sans tout charger en memoire et sans pandas. La memoire
reste constante quel que soit le volume.

Deux modes :
  --csv liste.csv             une ou plusieurs extractions, une par ligne :
                                  requete.sql;resultat.csv
                                  requete2.sql;resultat2.xlsx
                              ligne d'en-tete (requete;resultat), lignes vides
                              et lignes '#' ignorees ; chemins relatifs
                              resolus depuis le dossier du CSV.
  --sql r.sql --sortie s.csv  une seule extraction.

Usage :
    py CapAppro_UN_SQL_FLUX.py --csv query_execute.csv
    py CapAppro_UN_SQL_FLUX.py --csv query_execute.csv --lot 200 --arret-sur-erreur
    py CapAppro_UN_SQL_FLUX.py --sql requete.sql --sortie resultat.csv --configBDD config_oracle_finance

Taille de lot, par ordre de priorite : --lot N, puis [execution] TAILLE_LOT
du .ini, puis 500. Une seule connexion Oracle sert a toutes les extractions ;
par defaut, une extraction en echec n'arrete pas les suivantes.

Identifiants et pilote Oracle : identiques a CapAppro_UN_SQL.py (voir
doc/README_UN_SQL.md). Les fonctions de connexion et de lecture du CSV sont
importees de CapAppro_UN_SQL.py et CapAppro_MULTI_SQL.py, pas recopiees.

Format de sortie : le meme que CapAppro_UN_SQL.py (CSV ';' UTF-8 BOM,
guillemets sur les non-numeriques, dates dd/mm/yyyy hh:mm:ss, decimaux sur 5
decimales ; XLSX feuille Sheet1), avec une difference voulue : un entier est
toujours ecrit comme un entier. pandas, lui, ecrit "1.00000" quand la
colonne contient aussi un vide ou un decimal, ce qui n'est pas connaissable
avant d'avoir lu toute la colonne.

Ecriture atomique : chaque resultat est ecrit dans <sortie>.tmp puis renomme
a la fin. Un echec laisse l'ancien fichier de sortie intact et supprime le .tmp.

Codes retour : 0 tout OK, 1 au moins une extraction en echec,
2 argument ou CSV invalide.
"""

import argparse
import csv
import datetime
import os
import sys
import time

from capappro_config import Config, log, logDebut, logFin, logSection, masquer
from CapAppro_UN_SQL import (DOSSIER_SCRIPT, lireRequete, ouvrirConnexion,
                             resoudreConnexion)
from CapAppro_MULTI_SQL import lireListeExtractions

TAILLE_LOT_DEFAUT = 500
INTERVALLE_LOG_SECONDES = 5.0      # au plus une ligne de progression par intervalle
FORMAT_DATE_CSV = "%d/%m/%Y %H:%M:%S"
FORMAT_DECIMAL_CSV = "%.5f"
MAX_LIGNES_XLSX = 1048576          # limite Excel, en-tete compris
EXTENSIONS_SORTIE = (".csv", ".xlsx")


# =============================================================================
#   Conversion des valeurs
# =============================================================================

def _lireLob(valeur):
    """CLOB/BLOB : le pilote renvoie un objet LOB, on lit son contenu."""
    contenu = valeur.read()
    if isinstance(contenu, bytes):
        return contenu.hex()
    return contenu


def valeurCsv(valeur):
    """Convertit une valeur Oracle comme le faisait pandas.to_csv.

    - None / NaN        -> ""            (ecrit "" par QUOTE_NONNUMERIC)
    - int, bool, Decimal -> inchange      (ecrit sans guillemets)
    - float             -> "%.5f"        (texte, donc entre guillemets)
    - date / datetime   -> dd/mm/yyyy hh:mm:ss
    - texte             -> inchange      (entre guillemets, " double)
    """
    if valeur is None:
        return ""
    if isinstance(valeur, float):
        if valeur != valeur:  # NaN
            return ""
        return FORMAT_DECIMAL_CSV % valeur
    if isinstance(valeur, (int, str)):
        return valeur
    if isinstance(valeur, datetime.date):  # datetime herite de date
        return valeur.strftime(FORMAT_DATE_CSV)
    if hasattr(valeur, "read"):
        return _lireLob(valeur)
    if isinstance(valeur, bytes):
        return valeur.hex()
    return valeur  # Decimal et autres numeriques : laisses au module csv


# =============================================================================
#   Ecrivains de sortie
# =============================================================================

class EcrivainCsv(object):
    """CSV ecrit ligne a ligne, memes options que CapAppro_UN_SQL.py."""

    def __init__(self, chemin, colonnes):
        # newline='' + lineterminator=os.linesep : meme fin de ligne que pandas
        self.fp = open(chemin, "w", encoding="utf-8-sig", newline="")
        self.ecrivain = csv.writer(self.fp, delimiter=";",
                                   quoting=csv.QUOTE_NONNUMERIC,
                                   lineterminator=os.linesep)
        self.ecrivain.writerow(colonnes)

    def ecrireLot(self, lignes):
        conv = valeurCsv
        self.ecrivain.writerows([[conv(v) for v in ligne] for ligne in lignes])
        self.fp.flush()  # le .tmp grossit visiblement apres chaque lot

    def fermer(self):
        self.fp.close()


class EcrivainXlsx(object):
    """XLSX ecrit ligne a ligne (xlsxwriter constant_memory).

    Le fichier n'est lisible qu'apres fermeture : c'est le format zip d'Excel.
    En-tete au style pandas (gras, bordure, centre) pour rester identique a
    CapAppro_UN_SQL.py.
    """

    def __init__(self, chemin, colonnes):
        import xlsxwriter
        self.classeur = xlsxwriter.Workbook(chemin, {"constant_memory": True})
        self.feuille = self.classeur.add_worksheet("Sheet1")
        self.fmtDateHeure = self.classeur.add_format({"num_format": "dd/mm/yyyy hh:mm:ss"})
        self.fmtDate = self.classeur.add_format({"num_format": "dd/mm/yyyy"})
        fmtEntete = self.classeur.add_format({"bold": True, "border": 1,
                                              "align": "center", "valign": "top"})
        for c, nom in enumerate(colonnes):
            self.feuille.write_string(0, c, nom, fmtEntete)
        self.ligne = 1

    def ecrireLot(self, lignes):
        if self.ligne + len(lignes) > MAX_LIGNES_XLSX:
            raise ValueError("Plus de %d lignes : limite Excel depassee, utiliser une "
                             "sortie .csv" % (MAX_LIGNES_XLSX - 1))
        f = self.feuille
        for ligne in lignes:
            r = self.ligne
            for c, v in enumerate(ligne):
                if v is None:
                    continue
                if hasattr(v, "read"):
                    v = _lireLob(v)
                if isinstance(v, bool):
                    f.write_boolean(r, c, v)
                elif isinstance(v, (int, float)):
                    if v == v:  # NaN laisse vide
                        f.write_number(r, c, v)
                elif isinstance(v, datetime.datetime):
                    f.write_datetime(r, c, v, self.fmtDateHeure)
                elif isinstance(v, datetime.date):
                    f.write_datetime(r, c, v, self.fmtDate)
                elif isinstance(v, str):
                    f.write_string(r, c, v)  # jamais interprete comme formule
                elif isinstance(v, bytes):
                    f.write_string(r, c, v.hex())
                else:
                    try:
                        f.write_number(r, c, float(v))  # Decimal
                    except (TypeError, ValueError):
                        f.write_string(r, c, str(v))
            self.ligne += 1

    def fermer(self):
        self.classeur.close()


def creerEcrivain(chemin, extension, colonnes):
    if extension == ".csv":
        return EcrivainCsv(chemin, colonnes)
    return EcrivainXlsx(chemin, colonnes)


# =============================================================================
#   Execution en flux
# =============================================================================

def exporterEnFlux(connexion, requete, cheminSortie, arraysize, tailleLot):
    """Execute la requete et ecrit le resultat lot par lot.

    Retourne (nombre de lignes, nombre de colonnes).
    """
    extension = os.path.splitext(cheminSortie)[1].lower()
    dossier = os.path.dirname(cheminSortie)
    if dossier and not os.path.isdir(dossier):
        os.makedirs(dossier)
    cheminTmp = cheminSortie + ".tmp"

    curseur = connexion.cursor()
    ecrivain = None
    try:
        # arraysize regle les allers-retours reseau, tailleLot le rythme d'ecriture
        curseur.arraysize = max(arraysize, tailleLot)
        curseur.execute(requete)
        if curseur.description is None:
            raise ValueError("La requete ne renvoie aucun resultat (pas un SELECT ?)")
        colonnes = [c[0].lower() for c in curseur.description]  # en-tete en minuscules

        ecrivain = creerEcrivain(cheminTmp, extension, colonnes)
        total = 0
        t0 = dernierLog = time.time()
        while True:
            lignes = curseur.fetchmany(tailleLot)
            if not lignes:
                break
            ecrivain.ecrireLot(lignes)
            total += len(lignes)
            maintenant = time.time()
            if maintenant - dernierLog >= INTERVALLE_LOG_SECONDES:
                log("    ... %d ligne(s) ecrite(s) (%.0f lignes/s)"
                    % (total, total / max(maintenant - t0, 1e-6)))
                dernierLog = maintenant

        ecrivain.fermer()
        ecrivain = None
        os.replace(cheminTmp, cheminSortie)
        return total, len(colonnes)
    except BaseException:
        if ecrivain is not None:
            try:
                ecrivain.fermer()
            except Exception:
                pass
        if os.path.exists(cheminTmp):
            try:
                os.remove(cheminTmp)
            except OSError:
                log("Fichier temporaire non supprime : %s" % cheminTmp, niveau="WARN")
        raise
    finally:
        try:
            curseur.close()
        except Exception:
            pass


# =============================================================================
#   Point d'entree
# =============================================================================

def analyserArguments(argv):
    parseur = argparse.ArgumentParser(
        description="Execute un ou plusieurs fichiers SQL Oracle et ecrit chaque "
                    "resultat en flux par lots (csv|xlsx).")
    source = parseur.add_mutually_exclusive_group(required=True)
    source.add_argument("--csv",
                        help="liste des extractions : une ligne 'requete.sql;resultat.csv' "
                             "par extraction")
    source.add_argument("--sql", help="un seul fichier .sql a executer (avec --sortie)")
    parseur.add_argument("--sortie", help="fichier de sortie .csv ou .xlsx (avec --sql)")
    parseur.add_argument("--lot", type=int, default=None,
                         help="nombre de lignes lues et ecrites par lot "
                              "(defaut : [execution] TAILLE_LOT, sinon %d)"
                              % TAILLE_LOT_DEFAUT)
    groupe = parseur.add_mutually_exclusive_group()
    groupe.add_argument("--configBDD", help="section [config_...] du fichier .ini")
    groupe.add_argument("--env-oracle", dest="envOracle",
                        help="fichier env_oracle.sh (export ORACLE_USER=..., ...)")
    parseur.add_argument("--arret-sur-erreur", dest="arretSurErreur", action="store_true",
                         help="avec --csv : arreter a la premiere extraction en echec")
    parseur.add_argument("--dry-run", action="store_true",
                         help="afficher les extractions et la connexion sans executer")
    args = parseur.parse_args(argv)
    if args.sql and not args.sortie:
        parseur.error("--sql demande aussi --sortie")
    if args.csv and args.sortie:
        parseur.error("--sortie ne s'utilise qu'avec --sql ; avec --csv, "
                      "les sorties sont dans le fichier CSV")
    return args


def listerExtractions(args):
    """Retourne [(numeroLigne, cheminSql, cheminSortie, erreur)] selon le mode.

    erreur vaut None si l'extraction est exploitable. Leve ValueError si la
    liste est inexploitable dans son ensemble.
    """
    if args.csv:
        cheminCsv = os.path.abspath(args.csv)
        if not os.path.isfile(cheminCsv):
            raise ValueError("Fichier CSV introuvable : %s" % cheminCsv)
        log("Fichier CSV : %s" % cheminCsv)
        extractions = lireListeExtractions(cheminCsv)
        if not extractions:
            raise ValueError("Aucune extraction dans le CSV : %s" % cheminCsv)
        return extractions

    cheminSql = os.path.abspath(args.sql)
    cheminSortie = os.path.abspath(args.sortie)
    if not os.path.isfile(cheminSql):
        raise ValueError("Fichier SQL introuvable : %s" % cheminSql)
    if os.path.splitext(cheminSortie)[1].lower() not in EXTENSIONS_SORTIE:
        raise ValueError("Le fichier de sortie doit se terminer par .csv ou .xlsx : %s"
                         % cheminSortie)
    return [(0, cheminSql, cheminSortie, None)]


def executerUneExtraction(connexion, cheminSql, cheminSortie, arraysize, tailleLot):
    requete = lireRequete(cheminSql)
    t0 = time.time()
    total, nbColonnes = exporterEnFlux(connexion, requete, cheminSortie,
                                       arraysize, tailleLot)
    log("%d ligne(s), %d colonne(s), en %.1f s -> %s (%.1f Ko)"
        % (total, nbColonnes, time.time() - t0, cheminSortie,
           os.path.getsize(cheminSortie) / 1024.0))
    return total


def main(argv=None):
    args = analyserArguments(argv)
    if args.lot is not None and args.lot <= 0:
        log("--lot doit etre un entier positif : %s" % args.lot, niveau="ERROR")
        return 2

    logSection("LANCEUR CENTRAL - EXECUTION SQL EN FLUX PAR LOTS")
    try:
        extractions = listerExtractions(args)
    except Exception as err:
        log("%s : %s" % (type(err).__name__, err), niveau="ERROR")
        return 2
    log("%d extraction(s) a traiter" % len(extractions))

    debut = logDebut("execution de %d extraction(s)" % len(extractions))
    bilan = []  # (rang, numeroLigne, nomSql, statut, detail)
    connexion = None
    try:
        config = Config(DOSSIER_SCRIPT)
        bdd = resoudreConnexion(config, args.configBDD, args.envOracle)
        arraysize = config.getInt("execution", "ARRAYSIZE", 1000) or 1000
        tailleLot = args.lot or config.getInt("execution", "TAILLE_LOT",
                                              TAILLE_LOT_DEFAUT) or TAILLE_LOT_DEFAUT
        if tailleLot <= 0:
            tailleLot = TAILLE_LOT_DEFAUT
        oracleClientHome = config.get("paths", "ORACLE_CLIENT_HOME", "")
        modeClient = (config.get("connexion", "MODE", "auto") if "connexion" in config
                      else "auto").strip().lower() or "auto"
        clientDir = (config.get("connexion", "CLIENT_DIR", "") if "connexion" in config
                     else "").strip()

        dsn = "%s:%s/%s" % (bdd["BASE_URL"], bdd["BASE_PORT"], bdd["BASE_SERVICE_NAME"])
        log("Connexion Oracle : %s/%s@%s  (identifiants : %s)"
            % (bdd["DB_USER"], masquer(bdd["DB_PASSWORD"]), dsn, bdd.get("ORIGINE", "?")))
        log("Taille de lot : %d ligne(s) ; arraysize : %d"
            % (tailleLot, max(arraysize, tailleLot)))

        # une seule connexion, reutilisee pour toutes les extractions
        if not args.dry_run and any(e[3] is None for e in extractions):
            connexion = ouvrirConnexion(bdd, oracleClientHome, modeClient, clientDir)

        for rang, (numero, cheminSql, cheminSortie, erreur) in enumerate(extractions, 1):
            nomSql = os.path.basename(cheminSql) if cheminSql else "?"
            logSection("[%d/%d] %s%s" % (rang, len(extractions),
                                         "ligne %d : " % numero if numero else "", nomSql))
            if erreur:
                log(erreur, niveau="ERROR")
                bilan.append((rang, numero, nomSql, "KO", erreur))
            else:
                log("SQL    : %s" % cheminSql)
                log("Sortie : %s" % cheminSortie)
                try:
                    if args.dry_run:
                        requete = lireRequete(cheminSql)
                        log("Requete lue (%d caracteres), non executee (--dry-run)"
                            % len(requete))
                        bilan.append((rang, numero, nomSql, "DRY-RUN", cheminSortie))
                    else:
                        nb = executerUneExtraction(connexion, cheminSql, cheminSortie,
                                                   arraysize, tailleLot)
                        bilan.append((rang, numero, nomSql, "OK", "%d ligne(s)" % nb))
                    continue
                except Exception as err:
                    detail = "%s : %s" % (type(err).__name__, err)
                    log(detail, niveau="ERROR")
                    bilan.append((rang, numero, nomSql, "KO", detail))
            if args.arretSurErreur:
                log("Arret demande a la premiere erreur (--arret-sur-erreur).", niveau="WARN")
                break

    except Exception as err:
        log("%s : %s" % (type(err).__name__, err), niveau="ERROR")
        bilan.append((0, 0, "(connexion)", "KO", str(err)))
    finally:
        if connexion is not None:
            try:
                connexion.close()
            except Exception:
                pass

    logSection("BILAN")
    for rang, numero, nomSql, statut, detail in bilan:
        log("%-9s %-7s %s  %s" % ("ligne %d" % numero if numero else "-", statut,
                                  nomSql, detail),
            niveau="ERROR" if statut == "KO" else "INFO")
    nbOk = sum(1 for b in bilan if b[3] in ("OK", "DRY-RUN"))
    nbKo = sum(1 for b in bilan if b[3] == "KO")
    nbNonTraitees = len(extractions) - sum(1 for b in bilan if b[0])
    log("%d OK / %d KO / %d non traitee(s) sur %d"
        % (nbOk, nbKo, nbNonTraitees, len(extractions)))

    if nbKo or nbNonTraitees:
        logFin("execution", debut, "KO")
        return 1
    logFin("execution", debut, "DRY-RUN" if args.dry_run else "OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
