"""Onglet Matin rendu sans Oracle via streamlit.testing.v1 AppTest : résultats, rapport, garde-fous."""
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
import pytest
from streamlit.testing.v1 import AppTest

import controle_matin as cm
import db
import planif_matin as pm
import rapport_matin as rm
import ui_matin


def _script():
    # AppTest exécute la fonction dans un espace de noms neuf ; sys.modules est partagé,
    # donc les modules déjà monkeypatchés sont réutilisés.
    import sys
    from datetime import datetime
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_matin

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_matin.render(datetime.now(), faux_kpi)


def _faux_resultat(now):
    deb, fin = cm.plage_par_defaut(now)
    compteurs = {k: 10 for k in cm.COMPTEURS}
    compteurs.update(nb_erreurs=2, nb_images_manq=1, nb_flux_dsp=6, nb_fac_dsp=0)
    sections = []
    for i, (cle, titre, _sql, _alerte) in enumerate(cm.CATALOGUE):
        sec = cm.Section(cle=cle, titre=titre, df=pd.DataFrame())
        if i == 0:
            sec.df = pd.DataFrame({"REQ_ID": [1, 2], "JOB_CTM": ["JOB_A", "JOB_B"], "MSG": ["boom", "bang"]})
            sec.alerte = True
        elif i == 1:
            sec.df, sec.erreur = None, "ORA-00942: table or view does not exist"
        sections.append(sec)
    return cm.Resultat(executed_at=now, debut=deb, fin=fin, nb_jours_histo=3, compteurs=compteurs,
                       statuts=cm.statuts(compteurs), statut_global="ALERTE", sections=sections, duree_s=3.1)


@pytest.fixture
def app(tmp_path, monkeypatch):
    now = datetime.now()
    base = tmp_path / "odat.db"
    rapports = tmp_path / "rapports"
    con = db.connect(base)
    for i in (3, 2, 1):   # historique antérieur : delta veille + tendance
        c = {k: 10 for k in cm.COMPTEURS} | {"nb_erreurs": 0, "nb_images_manq": 0, "nb_flux_dsp": 6}
        deb, fin = cm.plage_par_defaut(now - timedelta(days=i))
        cm.enregistrer_histo(cm.Resultat(executed_at=now - timedelta(days=i), debut=deb, fin=fin, nb_jours_histo=3,
                                         compteurs=c, statuts=cm.statuts(c), statut_global="OK"), con)
    con.close()
    monkeypatch.setattr(ui_matin, "CONFIG", Path(__file__))          # existe
    monkeypatch.setattr(ui_matin, "connect", lambda: db.connect(base))
    monkeypatch.setattr(pm, "etat", lambda: None)
    monkeypatch.setattr(rm, "DOSSIER_RAPPORTS", rapports)
    monkeypatch.setattr(rm.ecrire, "__defaults__", (rapports,))      # défaut lié à la définition
    monkeypatch.setattr(cm, "executer", lambda debut, fin, histo: _faux_resultat(now))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, rapports


def _bouton(at, prefixe):
    return next(b for b in at.button if b.label.startswith(prefixe))


def test_sans_execution(app):
    at, _ = app
    assert any("Aucune exécution" in c.value for c in at.caption)
    assert any("Tendance 30 jours" in m.value for m in at.markdown)
    assert not any(b.label.startswith("📄") for b in at.button)


def test_resultats(app):
    at, _ = app
    _bouton(at, "▶").click().run()
    assert not at.exception
    erreurs = [e.value for e in at.error]
    assert any("Statut global : ALERTE" in e for e in erreurs)
    assert "ORA-00942: table or view does not exist" in erreurs
    tuiles = [m.value for m in at.markdown]
    assert any(m.startswith("2 Erreurs") and "+2 vs" in m and m.endswith("[err]") for m in tuiles)
    assert any("Images manquantes" in m and m.endswith("[err]") for m in tuiles)
    labels = [x.label for x in at.expander]
    assert len(labels) == len(cm.CATALOGUE) == 15
    assert labels[0].startswith("⚠️") and labels[0].endswith("2 ligne(s)")
    assert labels[1].startswith("🔴")
    assert len(at.dataframe) == 1


def test_rapport(app):
    at, rapports = app
    _bouton(at, "▶").click().run()
    _bouton(at, "📄").click().run()
    assert not at.exception
    fichiers = list(rapports.glob("Controle_Matin_*.html"))
    assert len(fichiers) == 1
    assert any("Rapport écrit" in c.value for c in at.caption)
    cles = {d.key for d in at.get("download_button")}
    assert cles == {"dl_courant", f"dl_{fichiers[0].stem}"}
    assert any(x.label.startswith("Rapports précédents (1)") for x in at.expander)


def test_plage_invalide(app):
    at, _ = app
    at.session_state["m_jf"] = at.session_state["m_jd"] - timedelta(days=1)
    _bouton(at, "▶").click().run()
    assert not at.exception
    assert any("doit être après" in e.value for e in at.error)
    assert "matin" not in at.session_state


def test_systemexit_affiche(app, monkeypatch):
    at, _ = app
    def boom(*a):
        raise SystemExit("Fichier config.ini absent")
    monkeypatch.setattr(cm, "executer", boom)
    _bouton(at, "▶").click().run()
    assert not at.exception
    assert any("Contrôle impossible : Fichier config.ini absent" in e.value for e in at.error)
