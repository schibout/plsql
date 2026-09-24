"""Execute chaque requete de sql/ et depose un CSV par requete dans le dossier cible.

Connexion Oracle : celle d'odat_watch (oracle_refresh._connect_oracle + odat_watch/config.ini,
modes thin/thick, client_dir, schema). Une requete en erreur garde son CSV precedent
(le dashboard l'affiche comme perime). Code retour : nombre de requetes en echec.

Usage : python export_csv.py <dossier_csv>
"""
from __future__ import annotations
import csv
import os
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
SQL_DIR = ICI / "sql"
ODAT_DIR = ICI.parent / "odat_watch"

# Valeurs des variables &xxx des requetes (memes que Lancer_Controle_Quotidien.ps1).
VARIABLES = {"nb_jours_histo": "3", "heure_fermeture": "19", "heure_ouverture": "7"}


def preparer(sql: str) -> str:
    """Texte SQL*Plus -> texte executable par oracledb : variables &xxx remplacees, ';' final retire."""
    for nom, valeur in VARIABLES.items():
        sql = sql.replace("&" + nom, valeur)
    return sql.strip().rstrip(";").rstrip()


def cellule(v) -> str:
    if v is None:
        return ""
    if hasattr(v, "strftime"):
        return v.strftime("%d/%m/%Y %H:%M:%S")
    return str(v)


def exporter(con, sql_dir: Path, out_dir: Path) -> tuple[int, int]:
    """Retourne (nombre de requetes, nombre d'echecs)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    fichiers = sorted(sql_dir.glob("*.sql"))
    ko = 0
    for f in fichiers:
        cible = out_dir / (f.stem + ".csv")
        tmp = cible.with_suffix(".tmp")
        try:
            cur = con.cursor()
            cur.execute(preparer(f.read_text(encoding="utf-8")))
            with open(tmp, "w", encoding="utf-8", newline="") as sortie:
                w = csv.writer(sortie)
                w.writerow([d[0] for d in cur.description])
                for ligne in cur:
                    w.writerow([cellule(v) for v in ligne])
            os.replace(tmp, cible)
            print(f"[OK] {f.stem}")
        except Exception as e:  # noqa: BLE001 - une requete en echec n'arrete pas les autres
            ko += 1
            tmp.unlink(missing_ok=True)
            print(f"[KO] {f.stem} : {e}")
    return len(fichiers), ko


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 99
    sys.path.insert(0, str(ODAT_DIR))
    from oracle_refresh import load_config, _connect_oracle, _schema  # noqa: E402

    cfg = load_config()
    with _connect_oracle(cfg) as con:
        schema = _schema(cfg).rstrip(".")
        if schema:
            # Les requetes ne prefixent pas les tables : on se place dans le schema d'odat_watch.
            con.cursor().execute(f'ALTER SESSION SET CURRENT_SCHEMA = "{schema.upper()}"')
        nb, ko = exporter(con, SQL_DIR, Path(sys.argv[1]))
    print(f"{nb} requete(s), {ko} en echec.")
    return ko if nb else 98


if __name__ == "__main__":
    sys.exit(main())
