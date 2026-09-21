"""Historique du contrôle du matin dans SQLite."""
from datetime import datetime

import db


def _cols(con, table):
    return [r[1] for r in con.execute(f"PRAGMA table_info({table})")]


def test_table_controle_matin_histo_creee(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cols = _cols(con, "controle_matin_histo")
    for c in ("date_ctrl", "plage_debut", "plage_fin", "statut_global", "nb_images_manq", "fichier_rapport"):
        assert c in cols
    con.close()


import controle_matin as cm


def _resultat(executed_at, **maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0, nb_fac_ar=15, nb_fac_ar_rejet=0)
    c.update(maj)
    debut, fin = cm.plage_par_defaut(executed_at)
    return cm.Resultat(executed_at=executed_at, debut=debut, fin=fin, nb_jours_histo=3,
                       compteurs=c, statuts=cm.statuts(c), statut_global=cm.statut_global(c, []),
                       sections=[], duree_s=4.2)


def test_enregistrer_histo_et_relire(tmp_path):
    con = db.connect(tmp_path / "t.db")
    r = _resultat(datetime(2026, 9, 19, 7, 30))
    hid = cm.enregistrer_histo(r, con)
    assert r.histo_id == hid
    row = con.execute("SELECT date_ctrl, plage_debut, plage_fin, statut_global, nb_flux_dsp, duree_s "
                      "FROM controle_matin_histo").fetchone()
    assert tuple(row) == ("2026-09-19", "2026-09-18 19:00", "2026-09-19 07:00", "OK", 6, 4.2)
    cm.maj_fichier_rapport(hid, "rapports/Controle_Matin_20260919_0730.html", con)
    assert con.execute("SELECT fichier_rapport FROM controle_matin_histo").fetchone()[0].endswith("0730.html")
    con.close()


def test_delta_veille_compare_a_la_derniere_execution_d_un_jour_anterieur(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 17, 7, 0), nb_erreurs=5), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 7, 0), nb_erreurs=2), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 9, 0), nb_erreurs=1), con)   # relance le même jour
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 19, 7, 0), nb_erreurs=4), con)   # aujourd'hui, ignoré
    auj = _resultat(datetime(2026, 9, 19, 7, 30), nb_erreurs=4)
    d = cm.delta_veille(auj.compteurs, auj.date_ctrl, con)
    assert d["date"] == "2026-09-18"
    assert d["nb_erreurs"] == 3            # 4 - 1 (dernière exécution du 18)
    assert d["nb_flux_dsp"] == 0
    con.close()


def test_delta_veille_sans_historique(tmp_path):
    con = db.connect(tmp_path / "t.db")
    assert cm.delta_veille({"nb_erreurs": 1}, datetime(2026, 9, 19).date(), con) == {}
    con.close()


def test_delta_veille_ignore_un_ancien_matin_rejoue_plus_tard(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 7, 0), nb_erreurs=2), con)
    # le 10/09 est rejoué le 19 au soir : executed_at plus récent, mais date_ctrl plus ancienne
    vieux = _resultat(datetime(2026, 9, 10, 7, 0), nb_erreurs=9)
    vieux.executed_at = datetime(2026, 9, 19, 22, 0)
    cm.enregistrer_histo(vieux, con)
    d = cm.delta_veille({"nb_erreurs": 4}, datetime(2026, 9, 19).date(), con)
    assert d["date"] == "2026-09-18" and d["nb_erreurs"] == 2
    con.close()


def test_historique_une_ligne_par_jour(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 7, 0), nb_erreurs=2), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 18, 9, 0), nb_erreurs=1), con)
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 19, 7, 0), nb_erreurs=0), con)
    h = cm.historique(3650, con)
    assert list(h["date_ctrl"]) == ["2026-09-18", "2026-09-19"]
    assert list(h["nb_erreurs"]) == [1, 0]
    assert list(h["statut_global"]) == ["ALERTE", "OK"]
    con.close()


def test_migration_ajoute_les_colonnes_factures_ar(tmp_path):
    """Une base créée avant l'ajout des compteurs AR reçoit les colonnes à l'ouverture."""
    import sqlite3
    chemin = tmp_path / "ancienne.db"
    con = sqlite3.connect(chemin)
    con.execute("""CREATE TABLE controle_matin_histo (id INTEGER PRIMARY KEY AUTOINCREMENT, date_ctrl TEXT NOT NULL,
        executed_at TEXT NOT NULL, plage_debut TEXT NOT NULL, plage_fin TEXT NOT NULL, statut_global TEXT NOT NULL,
        nb_flux_dsp INTEGER, nb_ndf INTEGER, nb_fac_xerox INTEGER, nb_fac_tradeshift INTEGER, nb_fac_dsp INTEGER,
        nb_gl_interface INTEGER, nb_gl_lignes INTEGER, nb_traitements INTEGER, nb_erreurs INTEGER, nb_warnings INTEGER,
        nb_rb_imports INTEGER, nb_images_manq INTEGER, duree_s REAL, fichier_rapport TEXT)""")
    con.commit(); con.close()
    con = db.connect(chemin)
    cols = _cols(con, "controle_matin_histo")
    assert "nb_fac_ar" in cols and "nb_fac_ar_rejet" in cols
    cm.enregistrer_histo(_resultat(datetime(2026, 9, 21, 7, 30), nb_fac_ar_rejet=2), con)
    assert tuple(con.execute("SELECT nb_fac_ar, nb_fac_ar_rejet FROM controle_matin_histo").fetchone()) == (15, 2)
    con.close()
