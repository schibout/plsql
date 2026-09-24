"""Test hors Oracle : python tests/test_export_csv.py"""
import csv
import sys
import tempfile
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import export_csv as ex  # noqa: E402


class Curseur:
    def __init__(self, journal):
        self.journal = journal

    def execute(self, sql):
        self.journal.append(sql)
        if "boom" in sql:
            raise RuntimeError("ORA-00942")
        self.description = [("A",), ("B",)]
        self.lignes = [(1, datetime(2026, 9, 24, 7, 5)), (None, "x,y")]

    def __iter__(self):
        return iter(self.lignes)


class Connexion:
    def __init__(self):
        self.journal = []

    def cursor(self):
        return Curseur(self.journal)


# Variables et ';' final.
assert ex.preparer("SELECT &nb_jours_histo, &heure_fermeture / 24 FROM dual;\n") == "SELECT 3, 19 / 24 FROM dual"

with tempfile.TemporaryDirectory() as d:
    d = Path(d)
    (d / "sql").mkdir()
    (d / "sql" / "01_ok.sql").write_text("-- titre\nSELECT 1 FROM dual;", encoding="utf-8")
    (d / "sql" / "02_ko.sql").write_text("SELECT boom FROM dual;", encoding="utf-8")
    (d / "out").mkdir()
    (d / "out" / "02_ko.csv").write_text("ancien", encoding="utf-8")

    con = Connexion()
    assert ex.exporter(con, d / "sql", d / "out") == (2, 1)
    assert not con.journal[0].endswith(";")
    with open(d / "out" / "01_ok.csv", encoding="utf-8", newline="") as f:
        assert list(csv.reader(f)) == [["A", "B"], ["1", "24/09/2026 07:05:00"], ["", "x,y"]]
    # Une requete en echec garde son CSV precedent et ne laisse pas de .tmp.
    assert (d / "out" / "02_ko.csv").read_text(encoding="utf-8") == "ancien"
    assert not list((d / "out").glob("*.tmp"))

# Toutes les requetes livrees passent la preparation sans variable residuelle.
for f in sorted(ex.SQL_DIR.glob("*.sql")):
    sql = ex.preparer(f.read_text(encoding="utf-8"))
    assert "&" not in sql and not sql.endswith(";"), f.name

print("OK - export_csv")
