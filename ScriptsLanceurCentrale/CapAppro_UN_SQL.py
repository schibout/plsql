# -*- coding: utf-8 -*-
"""
Lanceur Central - execution d'UN SEUL fichier SQL vers un fichier de sortie.

Usage :
    py CapAppro_UN_SQL.py --sql requete.sql --sortie resultat.csv
    py CapAppro_UN_SQL.py --sql requete.sql --sortie resultat.xlsx --configBDD config_oracle_finance
    py CapAppro_UN_SQL.py --sql requete.sql --sortie resultat.csv --env-oracle env_oracle.sh

Identifiants de connexion, par ordre de priorite :
    1. --configBDD <section>   : section [config_...] de config_lanceur_central.ini
                                 (surcharge possible par CAPAPPRO_<SECTION>_<CLE>)
    2. --env-oracle <fichier>  : fichier env_oracle.sh (export ORACLE_USER=..., etc.)
    3. sans option             : section [connexion] DEFAUT_CONFIG_BDD du .ini,
                                 sinon env_oracle.sh a cote du script,
                                 sinon variables d'environnement ORACLE_USER /
                                 ORACLE_PASSWORD / ORACLE_HOST / ORACLE_PORT /
                                 ORACLE_SERVICE deja presentes dans la session.

Le format de sortie est deduit de l'extension : .csv (separateur ';',
UTF-8 BOM, memes options que le worker) ou .xlsx.

Codes retour : 0 succes, 1 echec d'execution, 2 argument invalide.
"""

import argparse
import os
import re
import sys
import time

from capappro_config import (Config, cheminConfig, log, logDebut, logFin,
                             logSection, masquer)

DOSSIER_SCRIPT = os.path.dirname(os.path.abspath(__file__))
NOM_ENV_ORACLE = "env_oracle.sh"


# =============================================================================
#   Identifiants de connexion
# =============================================================================

def lireEnvOracle(chemin):
    """Lit un fichier env_oracle.sh (lignes 'export CLE=VALEUR').

    Les references ${AUTRE_CLE} sont resolues avec les valeurs deja lues,
    puis avec l'environnement courant. Les guillemets entourant la valeur
    sont retires.
    """
    valeurs = {}
    motif = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$')
    with open(chemin, "r", encoding="utf-8", errors="replace") as fp:
        for ligne in fp:
            ligne = ligne.strip()
            if not ligne or ligne.startswith("#"):
                continue
            m = motif.match(ligne)
            if not m:
                continue
            cle, valeur = m.group(1), m.group(2)
            if len(valeur) >= 2 and valeur[0] == valeur[-1] and valeur[0] in "\"'":
                valeur = valeur[1:-1]

            def remplacer(mm):
                nom = mm.group(1) or mm.group(2)
                return valeurs.get(nom, os.environ.get(nom, ""))

            valeur = re.sub(r'\$\{([A-Za-z0-9_]+)\}|\$([A-Za-z0-9_]+)', remplacer, valeur)
            valeurs[cle] = valeur
    return valeurs


def connexionDepuisEnv(valeurs, origine):
    """Construit le dictionnaire de connexion a partir de variables ORACLE_*."""
    manquantes = [c for c in ("ORACLE_USER", "ORACLE_PASSWORD", "ORACLE_HOST",
                              "ORACLE_SERVICE") if not valeurs.get(c)]
    if manquantes:
        raise KeyError("Variables manquantes dans %s : %s"
                       % (origine, ", ".join(manquantes)))
    return {
        "BASE_URL": valeurs["ORACLE_HOST"],
        "BASE_PORT": valeurs.get("ORACLE_PORT", "1521") or "1521",
        "BASE_SERVICE_NAME": valeurs["ORACLE_SERVICE"],
        "TYPE": "ORACLE",
        "DB_USER": valeurs["ORACLE_USER"],
        "DB_PASSWORD": valeurs["ORACLE_PASSWORD"],
        "NLS_LANG": valeurs.get("NLS_LANG", ""),
        "NLS_DATE_FORMAT": valeurs.get("NLS_DATE_FORMAT", ""),
        "ORIGINE": origine,
    }


def resoudreConnexion(config, configBDD=None, envOracle=None):
    """Determine les identifiants selon l'ordre de priorite decrit en tete."""
    if configBDD:
        bdd = config.sectionBDD(configBDD)
        bdd["ORIGINE"] = "[%s] de %s" % (configBDD, os.path.basename(cheminConfig(DOSSIER_SCRIPT)))
        return bdd

    if envOracle:
        chemin = config.resoudreChemin(envOracle)
        if not os.path.isfile(chemin):
            raise FileNotFoundError("Fichier env_oracle introuvable : %s" % chemin)
        return connexionDepuisEnv(lireEnvOracle(chemin), chemin)

    defaut = config.get("connexion", "DEFAUT_CONFIG_BDD", "") if "connexion" in config else ""
    if defaut and defaut.strip():
        return resoudreConnexion(config, configBDD=defaut.strip())

    cheminEnv = os.path.join(DOSSIER_SCRIPT, NOM_ENV_ORACLE)
    if os.path.isfile(cheminEnv):
        return connexionDepuisEnv(lireEnvOracle(cheminEnv), cheminEnv)

    return connexionDepuisEnv(dict(os.environ), "l'environnement de la session")


# =============================================================================
#   Oracle
# =============================================================================

def ouvrirConnexion(bdd, oracleClientHome):
    """Ouvre une connexion Oracle.

    Prefere python-oracledb (mode thin, sans client Oracle) s'il est installe,
    sinon cx_Oracle avec le client indique par [paths] ORACLE_CLIENT_HOME.
    """
    for cle in ("NLS_LANG", "NLS_DATE_FORMAT"):
        if bdd.get(cle) and cle not in os.environ:
            os.environ[cle] = bdd[cle]

    dsn = "%s:%s/%s" % (bdd["BASE_URL"], bdd["BASE_PORT"], bdd["BASE_SERVICE_NAME"])

    try:
        import oracledb
        log("Pilote : python-oracledb (mode thin)")
        return oracledb.connect(user=bdd["DB_USER"], password=bdd["DB_PASSWORD"], dsn=dsn)
    except ImportError:
        pass

    import cx_Oracle
    if oracleClientHome:
        libDir = os.path.join(oracleClientHome, "bin")
        if os.path.isdir(libDir):
            try:
                cx_Oracle.init_oracle_client(lib_dir=libDir)
            except cx_Oracle.ProgrammingError:
                pass  # deja initialise
    log("Pilote : cx_Oracle")
    dsnCx = cx_Oracle.makedsn(bdd["BASE_URL"], int(bdd["BASE_PORT"]),
                              service_name=bdd["BASE_SERVICE_NAME"])
    return cx_Oracle.connect(bdd["DB_USER"], bdd["DB_PASSWORD"], dsnCx)


def lireRequete(cheminSql):
    """Lit le fichier SQL et retire le ';' ou '/' final que refuse le pilote."""
    encodages = ("utf-8-sig", "utf-8", "cp1252", "latin-1")
    contenu = None
    for enc in encodages:
        try:
            with open(cheminSql, "r", encoding=enc) as fp:
                contenu = fp.read()
            break
        except UnicodeDecodeError:
            continue
    if contenu is None:
        raise ValueError("Impossible de decoder le fichier SQL : %s" % cheminSql)

    requete = contenu.strip()
    while requete.endswith((";", "/")):
        requete = requete[:-1].rstrip()
    if not requete:
        raise ValueError("Le fichier SQL est vide : %s" % cheminSql)
    return requete


def executerRequete(connexion, requete, arraysize):
    import pandas as pd
    curseur = connexion.cursor()
    curseur.arraysize = arraysize
    curseur.execute(requete)
    colonnes = [c[0] for c in curseur.description]
    lignes = curseur.fetchall()
    curseur.close()
    return pd.DataFrame.from_records(lignes, columns=colonnes)


# =============================================================================
#   Export
# =============================================================================

def enregistrer(df, cheminSortie):
    import csv
    extension = os.path.splitext(cheminSortie)[1].lower().lstrip(".")
    dossier = os.path.dirname(os.path.abspath(cheminSortie))
    if dossier and not os.path.isdir(dossier):
        os.makedirs(dossier)

    if extension == "csv":
        df.to_csv(cheminSortie, index=None, sep=";", quoting=csv.QUOTE_NONNUMERIC,
                  encoding="utf-8-sig", date_format="%d/%m/%Y %H:%M:%S",
                  float_format="%.5f")
    elif extension == "xlsx":
        import pandas as pd
        with pd.ExcelWriter(cheminSortie, engine="xlsxwriter",
                            datetime_format="dd/mm/yyyy hh:mm:ss",
                            date_format="dd/mm/yyyy") as writer:
            df.to_excel(writer, sheet_name="Sheet1", index=False)
    else:
        raise ValueError("Extension de sortie non reconnue ('%s') : attendu csv ou xlsx"
                         % extension)


# =============================================================================
#   Point d'entree
# =============================================================================

def analyserArguments(argv):
    parseur = argparse.ArgumentParser(
        description="Execute un fichier SQL Oracle et enregistre le resultat (csv|xlsx).")
    parseur.add_argument("--sql", required=True, help="fichier .sql a executer")
    parseur.add_argument("--sortie", required=True, help="fichier de sortie .csv ou .xlsx")
    groupe = parseur.add_mutually_exclusive_group()
    groupe.add_argument("--configBDD", help="section [config_...] du fichier .ini")
    groupe.add_argument("--env-oracle", dest="envOracle",
                        help="fichier env_oracle.sh (export ORACLE_USER=..., ...)")
    parseur.add_argument("--dry-run", action="store_true",
                         help="afficher la requete et la connexion sans executer")
    return parseur.parse_args(argv)


def main(argv=None):
    args = analyserArguments(argv)

    cheminSql = os.path.abspath(args.sql)
    cheminSortie = os.path.abspath(args.sortie)
    if not os.path.isfile(cheminSql):
        log("Fichier SQL introuvable : %s" % cheminSql, niveau="ERROR")
        return 2
    if os.path.splitext(cheminSortie)[1].lower() not in (".csv", ".xlsx"):
        log("Le fichier de sortie doit se terminer par .csv ou .xlsx : %s"
            % cheminSortie, niveau="ERROR")
        return 2

    logSection("LANCEUR CENTRAL - EXECUTION D'UN FICHIER SQL")
    log("Fichier SQL    : %s" % cheminSql)
    log("Fichier sortie : %s" % cheminSortie)

    debut = logDebut("execution %s" % os.path.basename(cheminSql))
    connexion = None
    try:
        config = Config(DOSSIER_SCRIPT)
        bdd = resoudreConnexion(config, args.configBDD, args.envOracle)
        arraysize = config.getInt("execution", "ARRAYSIZE", 1000) or 1000
        oracleClientHome = config.get("paths", "ORACLE_CLIENT_HOME", "")

        dsn = "%s:%s/%s" % (bdd["BASE_URL"], bdd["BASE_PORT"], bdd["BASE_SERVICE_NAME"])
        log("Connexion Oracle : %s/%s@%s  (identifiants : %s)"
            % (bdd["DB_USER"], masquer(bdd["DB_PASSWORD"]), dsn, bdd.get("ORIGINE", "?")))

        requete = lireRequete(cheminSql)
        log("Requete (%d caracteres) :" % len(requete))
        for ligne in requete.splitlines():
            log("    | " + ligne)

        if args.dry_run:
            log("Mode --dry-run : rien n'est execute.")
            logFin("execution", debut, "DRY-RUN")
            return 0

        connexion = ouvrirConnexion(bdd, oracleClientHome)

        t0 = time.time()
        df = executerRequete(connexion, requete, arraysize)
        log("Requete executee : %d ligne(s), %d colonne(s), en %.1f s"
            % (len(df), len(df.columns), time.time() - t0))

        enregistrer(df, cheminSortie)
        taille = os.path.getsize(cheminSortie)
        log("Fichier enregistre : %s (%.1f Ko)" % (cheminSortie, taille / 1024.0))

        logFin("execution", debut, "OK")
        return 0

    except Exception as err:
        log("%s : %s" % (type(err).__name__, err), niveau="ERROR")
        logFin("execution", debut, "KO")
        return 1
    finally:
        if connexion is not None:
            try:
                connexion.close()
            except Exception:
                pass


if __name__ == "__main__":
    sys.exit(main())
