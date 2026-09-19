"""Règles de statut et catalogue du contrôle du matin (mêmes seuils que Controle_Quotidien_Complet.sql)."""
from datetime import datetime

import pandas as pd

import controle_matin as cm


def compteurs_ok(**maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0)
    c.update(maj)
    return c


def test_plage_par_defaut_hier_19h_aujourdhui_7h():
    debut, fin = cm.plage_par_defaut(datetime(2026, 9, 21, 8, 42))
    assert debut == datetime(2026, 9, 20, 19, 0)
    assert fin == datetime(2026, 9, 21, 7, 0)


def test_statuts_tout_ok():
    s = cm.statuts(compteurs_ok())
    assert set(s.values()) == {"OK"}
    assert set(s) == {"nb_flux_dsp", "nb_ndf", "nb_fac_xerox", "nb_fac_tradeshift", "nb_fac_dsp",
                      "nb_gl_interface", "nb_gl_lignes", "nb_rb_imports"}


def test_statuts_seuil_dsp_et_factures_dsp():
    s = cm.statuts(compteurs_ok(nb_flux_dsp=4))
    assert s["nb_flux_dsp"] == "W"
    assert s["nb_fac_dsp"] == "W"          # dépend du seuil DSP
    s = cm.statuts(compteurs_ok(nb_fac_dsp=2))
    assert s["nb_fac_dsp"] == "W"          # une facture DSP = anomalie


def test_statuts_compteur_absent_est_w():
    assert cm.statuts(compteurs_ok(nb_ndf=None))["nb_ndf"] == "W"


def _sections(**erreur_ou_lignes):
    out = []
    for cle, titre, _sql, alerte_si_lignes in cm.CATALOGUE:
        sec = cm.Section(cle=cle, titre=titre, df=pd.DataFrame())
        if cle in erreur_ou_lignes:
            v = erreur_ou_lignes[cle]
            if isinstance(v, str):
                sec.erreur = v
            else:
                sec.df = pd.DataFrame({"REQ_ID": list(range(v))})
                sec.alerte = alerte_si_lignes and v > 0
        out.append(sec)
    return out


def test_statut_global_ok():
    assert cm.statut_global(compteurs_ok(), _sections()) == "OK"


def test_statut_global_warning_sur_seuil():
    assert cm.statut_global(compteurs_ok(nb_flux_dsp=2), _sections()) == "WARNING"


def test_statut_global_warning_sur_warnings_nuit():
    assert cm.statut_global(compteurs_ok(nb_warnings=1), _sections()) == "WARNING"


def test_statut_global_warning_sur_traitement_en_cours():
    assert cm.statut_global(compteurs_ok(), _sections(nuit_en_cours=1)) == "WARNING"


def test_statut_global_alerte_erreurs():
    assert cm.statut_global(compteurs_ok(nb_erreurs=1), _sections()) == "ALERTE"


def test_statut_global_alerte_images_manquantes():
    assert cm.statut_global(compteurs_ok(nb_images_manq=3), _sections()) == "ALERTE"


def test_statut_global_erreur_si_section_en_echec():
    assert cm.statut_global(compteurs_ok(), _sections(rb="ORA-00942: table ou vue inexistante")) == "ERREUR"


def test_statut_global_erreur_si_compteur_indisponible():
    assert cm.statut_global(compteurs_ok(nb_rb_imports=None), _sections()) == "ERREUR"


def test_binds_ne_garde_que_les_variables_presentes():
    sql = "SELECT 1 FROM dual WHERE :histo > 0 AND CAST(:fin AS DATE) > SYSDATE"
    d, f = datetime(2026, 9, 18, 19), datetime(2026, 9, 19, 7)
    assert cm._binds(sql, {"histo": 3, "debut": d, "fin": f}) == {"histo": 3, "fin": f}


def test_catalogue_15_sections_sans_sysdate_de_fenetre():
    cles = [c[0] for c in cm.CATALOGUE]
    assert len(cles) == 15 and len(set(cles)) == 15
    assert cles[0] == "dsp_detail" and cles[-1] == "rb"
    for cle, _t, sql, _a in cm.CATALOGUE:
        if cle != "nuit_en_cours":      # seule la durée des traitements en cours lit l'horloge
            assert "SYSDATE" not in sql, cle
    for _cles, sql in cm.SYNTHESE:
        assert "SYSDATE" not in sql


def test_binds_ignore_les_prefixes_et_les_doubles_deux_points():
    sql = "SELECT :histo, :finale FROM dual WHERE x = 'a::b'"
    assert cm._binds(sql, {"histo": 3, "fin": 1, "b": 2}) == {"histo": 3}


def test_enrichir_job_ajoute_le_job_controlm(tmp_path):
    import db
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO ora_requests(request_id, job_name) VALUES (101, 'FINFIN_J18TRT_04_IMP01_Q')")
    con.commit()
    df = pd.DataFrame({"REQ_ID": [101, 102], "PROGRAMME": ["A", "B"]})
    out = cm.enrichir_job(df, con)
    assert list(out.columns)[:2] == ["REQ_ID", "JOB_CTM"]
    assert out.loc[0, "JOB_CTM"] == "FINFIN_J18TRT_04_IMP01_Q"
    assert out.loc[1, "JOB_CTM"] == ""
    con.close()


def test_enrichir_job_sans_colonne_req_id_ne_change_rien(tmp_path):
    import db
    con = db.connect(tmp_path / "t.db")
    df = pd.DataFrame({"SOURCE": ["X"]})
    assert cm.enrichir_job(df, con).equals(df)
    con.close()
