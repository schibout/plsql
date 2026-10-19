# -*- coding: utf-8 -*-
"""
Lanceur Central - execution de PLUSIEURS fichiers SQL decrits dans un CSV.

Chaque ligne du CSV donne un fichier SQL et son fichier de sortie, separes
par ';' :

    C:\\chemin\\requete1.sql;C:\\chemin\\resultat1.csv
    C:\\chemin\\requete2.sql;C:\\chemin\\resultat2.xlsx

Les lignes vides et celles commencant par '#' sont ignorees. Une premiere
ligne d'en-tete (sql;sortie) est toleree. Les chemins relatifs sont resolus
par rapport au dossier du CSV.

Usage :
    py CapAppro_MULTI_SQL.py --csv extractionExecute.csv
    py CapAppro_MULTI_SQL.py --csv extractionExecute.csv --configBDD config_oracle_finance
    py CapAppro_MULTI_SQL.py --csv extractionExecute.csv --env-oracle env_oracle.sh
    py CapAppro_MULTI_SQL.py --csv extractionExecute.csv --arret-sur-erreur

Identifiants, pilote Oracle et format de sortie : identiques a
CapAppro_UN_SQL.py (voir README_UN_SQL.md), en-tete en minuscules compris.
Une seule connexion est ouverte et reutilisee pour toutes les requetes.

Par defaut, une extraction en echec n'arrete pas les suivantes.

Codes retour : 0 toutes les extractions OK, 1 au moins un echec,
2 argument ou CSV invalide.
"""

import argparse
import os
import sys
import time

from capappro_config import Config, log, logDebut, logFin, logSection, masquer
from CapAppro_UN_SQL import (DOSSIER_SCRIPT, enregistrer, executerRequete,
                             lireRequete, ouvrirConnexion, resoudreConnexion)

EXTENSIONS_SORTIE = (".csv", ".xlsx")


# =============================================================================
#   Lecture du CSV des extractions
# =============================================================================

def lireListeExtractions(cheminCsv):
    """Retourne la liste des (numeroLigne, cheminSql, cheminSortie, erreur).

    erreur vaut None si la ligne est exploitable, sinon un message.
    """
    contenu = None
    for enc in ("utf-8-sig", "utf-8", "cp1252", "latin-1"):
        try:
            with open(cheminCsv, "r", encoding=enc) as fp:
                contenu = fp.read()
            break
        except UnicodeDecodeError:
            continue
    if contenu is None:
        raise ValueError("Impossible de decoder le fichier CSV : %s" % cheminCsv)

    dossierCsv = os.path.dirname(os.path.abspath(cheminCsv))
    extractions = []
    for numero, ligne in enumerate(contenu.splitlines(), start=1):
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#"):
            continue
        champs = [c.strip().strip('"').strip() for c in ligne.split(";")]
        champs = [c for c in champs if c]

        if (len(extractions) == 0 and len(champs) == 2
                and not champs[0].lower().endswith(".sql")
                and not os.path.splitext(champs[1])[1].lower() in EXTENSIONS_SORTIE):
            continue  # ligne d'en-tete

        if len(champs) != 2:
            extractions.append((numero, None, None,
                                "attendu 'fichier.sql;sortie.csv', lu : %s" % ligne))
            continue

        cheminSql = os.path.normpath(os.path.join(dossierCsv, champs[0]))
        cheminSortie = os.path.normpath(os.path.join(dossierCsv, champs[1]))
        erreur = None
        if not os.path.isfile(cheminSql):
            erreur = "fichier SQL introuvable : %s" % cheminSql
        elif os.path.splitext(cheminSortie)[1].lower() not in EXTENSIONS_SORTIE:
            erreur = "la sortie doit se terminer par .csv ou .xlsx : %s" % cheminSortie
        extractions.append((numero, cheminSql, cheminSortie, erreur))
    return extractions


# =============================================================================
#   Execution
# =============================================================================

def executerUneExtraction(connexion, cheminSql, cheminSortie, arraysize):
    requete = lireRequete(cheminSql)
    t0 = time.time()
    df = executerRequete(connexion, requete, arraysize)
    duree = time.time() - t0
    enregistrer(df, cheminSortie)
    log("%d ligne(s), %d colonne(s), en %.1f s -> %s (%.1f Ko)"
        % (len(df), len(df.columns), duree, cheminSortie,
           os.path.getsize(cheminSortie) / 1024.0))
    return len(df)


def analyserArguments(argv):
    parseur = argparse.ArgumentParser(
        description="Execute une liste de fichiers SQL Oracle decrite dans un CSV "
                    "(fichier.sql;sortie.csv|xlsx).")
    parseur.add_argument("--csv", required=True,
                         help="fichier CSV : une ligne 'fichier.sql;sortie' par extraction")
    groupe = parseur.add_mutually_exclusive_group()
    groupe.add_argument("--configBDD", help="section [config_...] du fichier .ini")
    groupe.add_argument("--env-oracle", dest="envOracle",
                        help="fichier env_oracle.sh (export ORACLE_USER=..., ...)")
    parseur.add_argument("--arret-sur-erreur", dest="arretSurErreur", action="store_true",
                         help="arreter a la premiere extraction en echec")
    parseur.add_argument("--dry-run", action="store_true",
                         help="verifier le CSV et la connexion resolue sans executer")
    return parseur.parse_args(argv)


def main(argv=None):
    args = analyserArguments(argv)

    cheminCsv = os.path.abspath(args.csv)
    if not os.path.isfile(cheminCsv):
        log("Fichier CSV introuvable : %s" % cheminCsv, niveau="ERROR")
        return 2

    logSection("LANCEUR CENTRAL - EXECUTION DE PLUSIEURS FICHIERS SQL")
    log("Fichier CSV : %s" % cheminCsv)

    try:
        extractions = lireListeExtractions(cheminCsv)
    except Exception as err:
        log("%s : %s" % (type(err).__name__, err), niveau="ERROR")
        return 2
    if not extractions:
        log("Aucune extraction dans le CSV.", niveau="ERROR")
        return 2
    log("%d extraction(s) lue(s)" % len(extractions))

    debut = logDebut("execution de %d extraction(s)" % len(extractions))
    bilan = []  # (numeroLigne, sql, statut, detail)
    connexion = None
    try:
        config = Config(DOSSIER_SCRIPT)
        bdd = resoudreConnexion(config, args.configBDD, args.envOracle)
        arraysize = config.getInt("execution", "ARRAYSIZE", 1000) or 1000
        oracleClientHome = config.get("paths", "ORACLE_CLIENT_HOME", "")
        modeClient = (config.get("connexion", "MODE", "auto") if "connexion" in config
                      else "auto").strip().lower() or "auto"
        clientDir = (config.get("connexion", "CLIENT_DIR", "") if "connexion" in config
                     else "").strip()

        dsn = "%s:%s/%s" % (bdd["BASE_URL"], bdd["BASE_PORT"], bdd["BASE_SERVICE_NAME"])
        log("Connexion Oracle : %s/%s@%s  (identifiants : %s)"
            % (bdd["DB_USER"], masquer(bdd["DB_PASSWORD"]), dsn, bdd.get("ORIGINE", "?")))

        if not args.dry_run and any(e[3] is None for e in extractions):
            connexion = ouvrirConnexion(bdd, oracleClientHome, modeClient, clientDir)

        for rang, (numero, cheminSql, cheminSortie, erreur) in enumerate(extractions, 1):
            nomSql = os.path.basename(cheminSql) if cheminSql else "?"
            logSection("[%d/%d] ligne %d : %s" % (rang, len(extractions), numero, nomSql))
            if erreur:
                log(erreur, niveau="ERROR")
                bilan.append((numero, nomSql, "KO", erreur))
            elif args.dry_run:
                log("SQL    : %s" % cheminSql)
                log("Sortie : %s" % cheminSortie)
                lireRequete(cheminSql)
                bilan.append((numero, nomSql, "DRY-RUN", cheminSortie))
                continue
            else:
                log("SQL    : %s" % cheminSql)
                log("Sortie : %s" % cheminSortie)
                try:
                    nb = executerUneExtraction(connexion, cheminSql, cheminSortie, arraysize)
                    bilan.append((numero, nomSql, "OK", "%d ligne(s)" % nb))
                    continue
                except Exception as err:
                    detail = "%s : %s" % (type(err).__name__, err)
                    log(detail, niveau="ERROR")
                    bilan.append((numero, nomSql, "KO", detail))
            if args.arretSurErreur:
                log("Arret demande a la premiere erreur (--arret-sur-erreur).", niveau="WARN")
                break

    except Exception as err:
        log("%s : %s" % (type(err).__name__, err), niveau="ERROR")
        bilan.append((0, "(connexion)", "KO", str(err)))
    finally:
        if connexion is not None:
            try:
                connexion.close()
            except Exception:
                pass

    logSection("BILAN")
    for numero, nomSql, statut, detail in bilan:
        log("ligne %-4s %-7s %s  %s" % (numero, statut, nomSql, detail),
            niveau="ERROR" if statut == "KO" else "INFO")
    nbKo = sum(1 for b in bilan if b[2] == "KO")
    nbNonTraitees = len(extractions) - sum(1 for b in bilan if b[0])
    log("%d OK / %d KO / %d non traitee(s) sur %d"
        % (sum(1 for b in bilan if b[2] == "OK"), nbKo, nbNonTraitees, len(extractions)))

    if nbKo or nbNonTraitees:
        logFin("execution", debut, "KO")
        return 1
    logFin("execution", debut, "DRY-RUN" if args.dry_run else "OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
