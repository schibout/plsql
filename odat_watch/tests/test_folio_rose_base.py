"""Folio Rose : import SQLite, statuts, groupes compensés, rapprochements, contrôle Oracle simulé."""
from datetime import date, datetime
from pathlib import Path

import pandas as pd
import pytest

import db
import folio_rose as fr

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def test_tables_folio_rose(tmp_path):
    con = db.connect(tmp_path / "t.db")
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"fr_exports", "fr_lignes", "fr_oracle", "fr_rapprochements", "fr_rapprochement_lignes"} <= tables
    cols = [r[1] for r in con.execute("PRAGMA table_info(fr_lignes)")]
    for c in ("empreinte", "folio", "type", "fichier_base", "ecart_debit", "age_j"):
        assert c in cols
    con.close()


def _export(tmp_path, nom="ExportCSV-20-08-2026.csv"):
    return fr.lire_export(SAUVEGARDE / nom)


def test_importer_dedoublonne(tmp_path):
    con = db.connect(tmp_path / "t.db")
    e = _export(tmp_path)
    eid = fr.importer(e, con)
    assert eid and e.id == eid
    assert fr.importer(_export(tmp_path), con) is None
    assert con.execute("SELECT COUNT(*) FROM fr_lignes WHERE dernier_export_id=?", (eid,)).fetchone()[0] == len(e.lignes)
    ex = fr.exports(con)
    assert list(ex.columns)[:3] == ["id", "nom_fichier", "date_export"] and len(ex) == 1
    con.close()


def test_lignes_export_sans_controle(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes(con)
    assert "statut" in l.columns and "rapproche" in l.columns
    assert set(l.loc[l["type"] != "AUTRE", "statut"]) == {"—"}
    assert set(l.loc[l["type"] == "AUTRE", "statut"]) <= {"NON CONTROLE"}
    assert (l["type"] == "AUTRE").sum() == 1
    assert not l["rapproche"].any()
    con.close()


def test_importer_valeurs_typees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    row = con.execute("SELECT num, age_j, amont_debit FROM fr_lignes WHERE dernier_export_id = ? LIMIT 1", (eid,)).fetchone()
    num, age_j, amont_debit = row
    assert isinstance(num, int)
    assert age_j is None or isinstance(age_j, int)
    assert isinstance(amont_debit, float)
    con.close()


def _df(*lignes):
    """(empreinte, folio, base, ecart_debit, rapproche[, ecart_credit, ecart_nb]) — crédit = débit et nb = 0 par défaut"""
    rows = [(e, f, b, d, r, *(rest if rest else (d, 0.0))) for e, f, b, d, r, *rest in lignes]
    return pd.DataFrame(rows, columns=["empreinte", "folio", "fichier_base", "ecart_debit", "rapproche", "ecart_credit", "ecart_nb"])


def test_groupes_compenses():
    df = _df(("a", "CYC", "F1", 100.0, False), ("b", "CYC", "F1", -60.0, False), ("c", "CYC", "F1", -40.0, False),
             ("d", "CYC", "F2", 10.0, False), ("e", "GCA", "F1", 5.0, False), ("f", "GCA", "F1", -5.0, True))
    g = fr.groupes_compenses(df)
    assert len(g) == 1
    assert g.iloc[0]["folio"] == "CYC" and g.iloc[0]["nb"] == 3 and abs(g.iloc[0]["somme"]) < fr.TOL
    assert sorted(g.iloc[0]["empreintes"]) == ["a", "b", "c"]


def test_rapprocher_et_annuler(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes(con)
    g = fr.groupes_compenses(l)
    if g.empty:                                         # on fabrique un groupe si l'export n'en a pas
        con.execute("UPDATE fr_lignes SET ecart_debit = -ecart_debit WHERE id = (SELECT MIN(id) FROM fr_lignes)")
        con.commit()
        l = fr.lignes(con); g = fr.groupes_compenses(l)
    empreintes = list(g.iloc[0]["empreintes"]) if not g.empty else []
    if len(empreintes) < 2:
        pytest.skip("aucun groupe compensé exploitable dans cet export")
    rid = fr.rapprocher(empreintes, "test", con)
    l2 = fr.lignes(con)
    assert l2.loc[l2["empreinte"].isin(empreintes), "rapproche"].all()
    assert fr.groupes_compenses(l2).apply(lambda r: set(r["empreintes"]) != set(empreintes), axis=1).all() if not fr.groupes_compenses(l2).empty else True
    with pytest.raises(ValueError):                      # déjà rapprochées
        fr.rapprocher(empreintes, "", con)
    r = fr.rapprochements(con)
    assert len(r) == 1 and r.iloc[0]["nb_lignes"] == len(empreintes) and r.iloc[0]["commentaire"] == "test"
    fr.annuler_rapprochement(rid, con)
    assert not fr.lignes(con)["rapproche"].any()
    assert fr.rapprochements(con).iloc[0]["annule_le"]
    con.close()


def test_rapprocher_refuse_somme_non_nulle(tmp_path):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    l = fr.lignes(con)
    deux = l[l["ecart_debit"] > 0]["empreinte"].head(2).tolist()
    with pytest.raises(ValueError, match="somme"):
        fr.rapprocher(deux, "", con)
    with pytest.raises(ValueError, match="deux"):
        fr.rapprocher(deux[:1], "", con)
    con.close()


def test_somme_selection():
    df = _df(("a", "X", "F", 1.5, False), ("b", "X", "F", -1.5, False), ("c", "X", "F", 2.0, False))
    assert fr.somme_selection(df, ["a", "b"]) == pytest.approx(0.0)
    assert fr.somme_selection(df, ["a", "c"]) == pytest.approx(3.5)
    s = fr.sommes_selection(df, ["a", "b"])
    assert s == {"ecart_debit": pytest.approx(0.0), "ecart_credit": pytest.approx(0.0), "ecart_nb": 0.0}
    assert fr.compensee(s) and not fr.compensee({"ecart_debit": 0, "ecart_credit": 0, "ecart_nb": 1})


def test_groupe_non_compense_si_credit_ou_pieces_differents():
    # débit à zéro mais crédit ou nombre de pièces non compensés : pas proposé
    df = _df(("a", "X", "F", 10.0, False, 10.0, 1.0), ("b", "X", "F", -10.0, False, -5.0, -1.0),
             ("c", "Y", "F", 10.0, False, 10.0, 1.0), ("d", "Y", "F", -10.0, False, -10.0, 0.0),
             ("e", "Z", "F", 10.0, False, 10.0, 1.0), ("f", "Z", "F", -10.0, False, -10.0, -1.0))
    assert list(fr.groupes_compenses(df)["folio"]) == ["Z"]


class _FauxCurseur:
    def __init__(self):
        self.appels = []
    def execute(self, sql, binds):
        self.appels.append((sql, binds))
        if binds["folio"] == "BOOM":
            raise RuntimeError("ORA-00942: table ou vue inexistante")
        self.derniere = (2, 100.0, 2, 100.0)
    def fetchone(self):
        return self.derniere


class _FauxCon:
    def __init__(self): self.cur = _FauxCurseur()
    def cursor(self): return self.cur
    def __enter__(self): return self
    def __exit__(self, *a): return False


def test_controler_oracle_simule(tmp_path, monkeypatch):
    con = db.connect(tmp_path / "t.db")
    eid = fr.importer(_export(tmp_path), con)
    con.execute("UPDATE fr_lignes SET folio = 'BOOM' WHERE id = (SELECT MIN(id) FROM fr_lignes WHERE type <> 'AUTRE')")
    con.commit()
    faux = _FauxCon()
    monkeypatch.setattr(fr, "_connexion_oracle", lambda: (faux, "APPS."))
    resume = fr.controler_oracle(con)
    couples = con.execute("SELECT COUNT(*), SUM(erreur IS NOT NULL) FROM fr_oracle").fetchone()
    assert couples[0] == len(faux.cur.appels) and couples[1] == 1
    assert "1 en erreur" in resume
    sql, binds = faux.cur.appels[0]
    assert "APPS." in sql and set(binds) == {"folio", "base"} and ":v_" not in sql
    l = fr.lignes(con)
    assert set(l.loc[l["type"] != "AUTRE", "statut"]) <= {"OK", "KO", "INDETERMINE"}
    assert (l.loc[l["folio"] == "BOOM", "statut"] == "INDETERMINE").all()
    con.close()


def test_import_successif_met_a_jour_sans_dupliquer(tmp_path):
    """Deux exports successifs : mêmes clés -> mêmes lignes mises à jour, nouvelles clés ajoutées, disparues marquées."""
    con = db.connect(tmp_path / "t.db")
    e1 = fr.lire_export(SAUVEGARDE / "ExportCSV-18-08-2026.csv")
    e2 = fr.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    fr.importer(e1, con)
    n1 = con.execute("SELECT COUNT(*) FROM fr_lignes").fetchone()[0]
    assert n1 == len(e1.lignes)
    communes = set(e1.lignes["empreinte"]) & set(e2.lignes["empreinte"])
    fr.importer(e2, con)
    n2 = con.execute("SELECT COUNT(*) FROM fr_lignes").fetchone()[0]
    assert n2 == len(set(e1.lignes["empreinte"]) | set(e2.lignes["empreinte"]))          # pas de doublon
    l = fr.lignes(con, disparues=True).set_index("empreinte")
    assert (l.loc[list(communes), "dernier_export_id"] == e2.id).all()
    assert (l.loc[list(communes), "premier_export_id"] == e1.id).all()
    disparues = set(e1.lignes["empreinte"]) - set(e2.lignes["empreinte"])
    fin = fr._date_fr(e2.periode_fin)
    for emp in disparues:
        dans_periode = fr._date_fr(l.loc[emp, "date"]) <= fin
        # absente du 19/08 : disparue si sa date est couverte par l'export, sinon toujours présente
        assert bool(l.loc[emp, "present"]) == (not dans_periode)
    assert len(fr.lignes(con)) == len(e2.lignes) + sum(1 for emp in disparues if fr._date_fr(l.loc[emp, "date"]) > fin)


def test_mise_a_jour_des_montants_conserve_le_rapprochement(tmp_path):
    con = db.connect(tmp_path / "t.db")
    e = fr.lire_export(SAUVEGARDE / "ExportCSV-20-08-2026.csv")
    fr.importer(e, con)
    g = fr.groupes_compenses(fr.lignes(con))
    emps = list(g.iloc[0]["empreintes"])
    fr.rapprocher(emps, "avant maj", con)
    # un export ultérieur change le commentaire d'une des lignes : même clé, même rapprochement
    contenu = (SAUVEGARDE / "ExportCSV-20-08-2026.csv").read_bytes().replace(b";non;", b";oui;", 1)
    e2 = fr.lire_export(contenu, "ExportCSV-21-08-2026.csv")
    assert fr.importer(e2, con)
    l = fr.lignes(con).set_index("empreinte")
    assert l.loc[emps, "rapproche"].all()
    con.close()


def test_sommes_par_fichier_comme_le_ps1(tmp_path):
    con = db.connect(tmp_path / "t.db")
    fr.importer(fr.lire_export(SAUVEGARDE / "ExportCSV-20-08-2026.csv"), con)
    l = fr.lignes(con)
    g = l.groupby(["folio", "fichier"])
    assert (l["somme_amont_fichier"] == g["amont_debit"].transform("sum")).all()
    assert (l["somme_ecart_fichier"] == g["ecart_debit"].transform("sum")).all()
    con.close()


def test_couleur_ligne():
    # montant à zéro -> vert ; nb pièces à zéro mais montant non nul -> rose ; sinon jaune
    assert fr.couleur_ligne(0.0, 0.0, 3.0) == "vert"
    assert fr.couleur_ligne(0.004, -0.004, 0.0) == "vert"
    assert fr.couleur_ligne(12.5, 12.5, 0.0) == "rose"
    assert fr.couleur_ligne(12.5, 12.5, -2.0) is None                    # autres écarts : pas de couleur
    assert fr.couleur_ligne(12.5, 12.5, -2.0, None, "vu avec la compta") == "jaune"
    assert fr.couleur_ligne(0.0, 0.0, 0.0, None, "  ") == "vert"           # commentaire vide ignoré
    assert fr.couleur_ligne(0.0, 5.0, 0.0) == "rose"          # crédit non nul : le montant n'est pas à zéro
    assert fr.couleur_ligne(12.5, 12.5, -2.0, "OK") == "bleu"  # le contrôle Oracle OK prime
    assert fr.couleur_ligne(0.0, 0.0, 0.0, "KO") == "vert"
