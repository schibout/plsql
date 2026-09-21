"""Onglet Profils : fusion profil calculé + référentiel (saisie brute, jobs hors référentiel)."""
import pandas as pd

import ui_profils


def _profils():
    return pd.DataFrame([
        dict(job="A", description="Import", frequence="Q", heure="02:00", lendemain=False, duree_min=3.5, fiabilite=100,
             nb_exec=4, jours="Lu Ma", cyclique=False, script="a.sh", groupe="CH_A"),
        dict(job="B", description="Jalon", frequence="Q", heure="03:00", lendemain=True, duree_min=None, fiabilite=None,
             nb_exec=0, jours="", cyclique=False, script="", groupe="CH_B"),
        dict(job="C", description="Nouveau", frequence="?", heure="?", lendemain=False, duree_min=None, fiabilite=None,
             nb_exec=0, jours="", cyclique=False, script="", groupe="CH_C"),
    ])


def _ref():
    return pd.DataFrame([
        dict(job_name="A", programme_auto="Import", programme_code="DKA_X", programme="Import", application_ora="", commentaire="", source="auto"),
        dict(job_name="B", programme_auto="", programme_code="", programme="PA_JALON", application_ora="PA", commentaire="vu DBA", source="manuel"),
        dict(job_name="Z", programme_auto="", programme_code="", programme="", application_ora="", commentaire="", source="à renseigner"),
    ])


def test_fusion_ajoute_le_referentiel_aux_profils():
    v = ui_profils.fusion(_profils(), _ref()).set_index("job")
    assert list(v.columns) == [c for c in ui_profils.COLONNES if c != "job"]
    assert v.loc["A", "programme_auto"] == "Import" and v.loc["A", "programme"] == ""   # auto : saisie brute vide
    assert v.loc["A", "programme_code"] == "DKA_X"
    assert v.loc["A", "source"] == "auto" and v.loc["A", "heure"] == "02:00"
    assert v.loc["B", "programme"] == "PA_JALON" and v.loc["B", "application_ora"] == "PA" and v.loc["B", "source"] == "manuel"
    assert v.loc["C", "source"] == "à renseigner" and v.loc["C", "programme_auto"] == ""
    assert "Z" not in v.index                                    # le référentiel ne crée pas de profil


def test_fusion_sans_referentiel_ni_profils():
    v = ui_profils.fusion(_profils(), pd.DataFrame())
    assert (v["source"] == "à renseigner").all() and len(v) == 3
    assert ui_profils.fusion(pd.DataFrame(), _ref()).empty


def test_rechercher_par_chaine_source_et_texte():
    v = ui_profils.fusion(_profils(), _ref())
    assert list(ui_profils.rechercher(v, [], ["CH_A"], [], "")["job"]) == ["A"]
    assert list(ui_profils.rechercher(v, [], [], ["manuel"], "")["job"]) == ["B"]
    assert list(ui_profils.rechercher(v, [], [], [], "dba")["job"]) == ["B"]         # commentaire
    assert list(ui_profils.rechercher(v, [], [], [], "dka_x")["job"]) == ["A"]       # programme auto
    assert list(ui_profils.rechercher(v, [], [], [], "nouveau")["job"]) == ["C"]     # description
    assert ui_profils.rechercher(v, [], ["CH_A"], ["manuel"], "").empty
    assert list(ui_profils.rechercher(v, ["Q"], [], [], "")["job"]) == ["A", "B"]   # fréquence
    assert list(ui_profils.rechercher(v, ["?"], [], [], "")["job"]) == ["C"]
