"""Sous-onglet Plan de production via AppTest : bible chargée d'office, grille du mois, filtre des écarts."""
import pytest
from streamlit.testing.v1 import AppTest

import db
import ui_plan_prod


def _script():
    import sys
    from datetime import date
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import pandas as pd
    import forecast
    import ui_plan_prod

    lignes = []
    for d in pd.bdate_range("2026-08-03", "2026-09-04").date:
        lignes.append(("FINEXT_J20GEN_06_Q", "FINEXT_J20GEN_06_EXP01_Q", d, "Ended OK", "Export Datalake"))
    lignes.append(("FINFIN_C13TRT_04_M", "FINFIN_C13TRT_04_WRK01_M", date(2026, 8, 31), "Ended Not OK", "Clôture AP"))
    lignes.append(("FINFIN_J11TEC_04_FJA01_Q", "FINFIN_J11TEC_04_FJA01_Q", date(2026, 8, 31), "Ended OK", "Jalon"))
    df = pd.DataFrame(lignes, columns=["group_name", "job_name", "odate", "status", "description"])
    df["snap_time"] = pd.Timestamp("2026-09-05 08:00")
    df["start_time"] = pd.to_datetime(df["odate"]) + pd.Timedelta(hours=22)
    df["end_time"] = df["start_time"] + pd.Timedelta(minutes=5)
    df["duree_min"] = 5.0
    for c in ("member", "cyclic", "order_id", "rerun", "application", "task_type"):
        df[c] = None
    profs = forecast.profils(df)

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle}")

    ui_plan_prod.render(df, profs, {"FINFIN_C13TRT_04_WRK01_M": "DKA_CLOTURE_AP"}, faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    db.connect(base).close()
    monkeypatch.setattr(ui_plan_prod, "connect", lambda: db.connect(base))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception, at.exception
    return at


def test_bible_chargee_et_mois_d_aout_par_defaut(app):
    assert "Août 2026" in app.selectbox(key="pdp_mois").format_func(app.selectbox(key="pdp_mois").value)
    grille = app.dataframe[1].value            # 0 = bandeau calendrier, 1 = grille des chaînes
    lignes = grille.set_index("chaîne")
    assert lignes.loc["FINFIN_C13TRT_04_M", "J 31/08"] == "✖ 1"
    assert lignes.loc["FINFIN_C13TRT_04_M", "Control-M"] == "L1"
    assert lignes.loc["FINFIN_J11TEC_04_FJA01_Q", "origine"] == "Nouvelle"
    assert lignes.loc["FINFIN_C12TRT_04_M", "origine"] == "Jamais vue"
    assert "FINEXT_J15GEN_06_Q" not in lignes.index            # supprimée dans la bible, masquée par défaut


def test_ecarts_uniquement_reduit_la_grille(app):
    avant = len(app.dataframe[1].value)
    app.checkbox(key="pdp_ecarts").check().run()
    apres = app.dataframe[1].value
    assert 0 < len(apres) < avant
    assert (apres["écarts"] != "").all()


def test_ajout_des_nouvelles_chaines_au_referentiel(app):
    app.button(key="pdp_ajouter").click().run()
    assert not app.exception
    lignes = app.dataframe[1].value.set_index("chaîne")
    assert lignes.loc["FINFIN_J11TEC_04_FJA01_Q", "origine"] == "Ajoutée"


def test_bouton_synchroniser_affiche_le_journal(app):
    app.button(key="pdp_synchro").click().run()
    assert not app.exception
    assert any("Synchronisation ODAT" in e.label for e in app.expander)
