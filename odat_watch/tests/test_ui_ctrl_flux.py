"""Onglet Ctrl Flux via AppTest : import, somme de la sélection, rapprochement."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import ctrl_flux as cf
import gdr as gd
import ui_ctrl_flux

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_ctrl_flux

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_ctrl_flux.render(faux_kpi)


def _gdr_pour(ligne, dossier: Path) -> Path:
    """Export GDR forgé : une pièce rejetée du montant de l'écart débit, sur le fichier et le folio de la ligne."""
    dossier.mkdir(parents=True, exist_ok=True)
    entete = ("Code Rejet;Libelle rejet;Fichier Source;Appli Source;Folio;Region;Societe;Numero piece;"
              "Date piece comptable;Compte local;Sous compte;Montant debit;Montant credit;Centre finance;TF;"
              "Quantite;Type depense;Type evenement;Type TVA;Devise;Date Arrete comptable;Description ligne;"
              "Date creation GDR;Fichier SRC technique;ID GDR;Line GDR")
    corps = (f"OAE036;projet invalide;{ligne['fichier']};CELERIS;{ligne['folio']} - libelle du folio;B0 - REGION;"
             f"0691;02606001162;25/06/2026;602218;0;{ligne['ecart_debit']:.6f};0.000000;B0;GL1;0.00001;DEB;;YES;EUR;"
             "25/06/2026;DESCRIPTION;26/06/2026;SRC_TECHNIQUE;900001;9000010")
    chemin = dossier / "29062026_Synthese_des_rejets_GL_au_29-06-2026.csv"
    chemin.write_text("﻿" + entete + "\n" + corps + "\n", encoding="utf-8")
    return chemin


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    e = cf.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    cf.importer(e, con)
    con.close()
    monkeypatch.setattr(ui_ctrl_flux, "connect", lambda: db.connect(base))
    # dossier GDR vide par défaut : les tests qui veulent des rejets y déposent un export
    monkeypatch.setattr(gd, "config_gdr", lambda: {"racine": tmp_path / "gdr"})
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, base


def test_affichage(app):
    at, _ = app
    assert any("lignes [neutral]" in m.value for m in at.markdown)
    assert at.dataframe
    assert any("Cochez des lignes" in c.value for c in at.caption)


def test_selection_et_rapprochement(app):
    at, base = app
    con = db.connect(base)
    lignes = cf.lignes(con)
    # deux lignes du même folio dont on force la compensation
    a, b = lignes.index[:2]
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=100, ecart_credit=100, ecart_nb=1 WHERE empreinte=?", (lignes.loc[a, "empreinte"],))
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=-100, ecart_credit=-100, ecart_nb=-1 WHERE empreinte=?", (lignes.loc[b, "empreinte"],))
    con.commit()
    at.session_state["cf_folios"] = ["ZZZ"]
    at.run()
    assert not at.exception
    assert any("Groupes compensés en attente (1)" in m.value for m in at.markdown)
    # la sélection de lignes dans st.dataframe n'est pas pilotable par AppTest : on rapproche le groupe
    at.button(key="cf_grp_0").click().run()
    assert not at.exception
    assert cf.lignes(con)["rapproche"].sum() == 2
    assert any("Groupes compensés en attente (0)" in m.value for m in at.markdown)
    con.close()


def test_generer_le_rapport(app, tmp_path, monkeypatch):
    import rapport_ctrl_flux as rm
    at, base = app
    monkeypatch.setattr(rm, "DOSSIER_RAPPORTS", tmp_path / "r")
    monkeypatch.setattr(rm.ecrire, "__defaults__", (tmp_path / "r",))
    at.button(key="cf_btn_rapport").click().run()
    assert not at.exception
    assert list((tmp_path / "r").glob("Ctrl_Flux_*.html"))


def test_import_remplace_l_etat(app, monkeypatch):
    # un nouvel import vide l'état courant : seules les lignes du dernier lot restent
    at, base = app
    fichiers = sorted(SAUVEGARDE.glob("ExportCSV-*.csv"))
    assert len(fichiers) >= 2
    autre = [f for f in fichiers if f.name != "ExportCSV-19-08-2026.csv"][0]
    msgs = ui_ctrl_flux._importer_fichiers([autre])
    assert "vidé" in msgs[0] and "importées" in msgs[1]
    con = db.connect(base)
    assert con.execute("SELECT COUNT(*) FROM fr_exports").fetchone()[0] == 1
    assert cf.exports(con).iloc[0]["nom_fichier"] == autre.name
    assert (cf.lignes(con, disparues=True)["dernier_export"] == autre.name).all()
    con.close()


def test_colonne_gdr_et_tuile(app, tmp_path):
    # une pièce rejetée du montant exact de l'écart : la ligne est signalée « dans la GDR »
    at, base = app
    con = db.connect(base)
    l = cf.lignes(con)
    ligne = l[l["ecart_debit"].abs() > 1].iloc[0]
    con.close()
    _gdr_pour(ligne, tmp_path / "gdr")
    del at.session_state["cf_gdr_log"]          # force un nouveau balayage du dossier GDR
    at.session_state["cf_folios"] = [ligne["folio"]]
    at.run()
    assert not at.exception
    assert any("1 lignes vues en GDR" in m.value for m in at.markdown)
    assert any("Imports GDR" in str(e.label) for e in at.expander)


def test_gdr_absente_n_empeche_rien(app):
    # dossier GDR vide : l'onglet fonctionne, aucune ligne signalée
    at, _ = app
    assert any("0 lignes vues en GDR" in m.value for m in at.markdown)


def _entetes(at):
    """Libellés des colonnes du tableau principal."""
    return list(at.dataframe[0].value.columns)


def test_choix_des_colonnes(app):
    # par défaut : les deux cumuls par fichier sont masqués, le commentaire est en dernier
    at, _ = app
    cols = _entetes(at)
    assert "Somme Amont Fichier" not in cols and "Somme Écart Fichier" not in cols
    assert cols[-1] == "Commentaire" and "GDR (rejets)" in cols
    # choix explicite : seules les colonnes retenues restent, dans l'ordre du tableau
    at.session_state["cf_colonnes"] = ["Commentaire", "Folio", "Écarts Débit", "Somme Amont Fichier"]
    at.run()
    assert not at.exception
    assert _entetes(at) == ["Folio", "Écarts Débit", "Somme Amont Fichier", "Commentaire"]


def test_couleurs_independantes_des_colonnes(app, tmp_path):
    # la couleur d'une ligne est calculée sur les données complètes, même colonnes masquées
    at, base = app
    con = db.connect(base)
    vue = cf.lignes(con)
    con.close()
    styles = ui_ctrl_flux._styles_lignes(vue)
    assert len(styles) == len(vue) and any(s for s in styles)
    at.session_state["cf_colonnes"] = ["Folio"]
    at.run()
    assert not at.exception
    assert _entetes(at) == ["Folio"]
