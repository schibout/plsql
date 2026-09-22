"""Règles de statut et catalogue du contrôle du matin (mêmes seuils que Controle_Quotidien_Complet.sql)."""
from datetime import datetime

import pandas as pd

import controle_matin as cm


def compteurs_ok(**maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0, nb_fac_ar=15, nb_fac_ar_rejet=0)
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
                      "nb_gl_interface", "nb_gl_lignes", "nb_rb_imports", "nb_fac_ar"}


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


def test_statut_global_images_manquantes_est_un_avertissement():
    """Les images arrivent souvent avec un jour de retard : à surveiller, pas une alerte."""
    assert cm.statut_global(compteurs_ok(nb_images_manq=3), _sections()) == "WARNING"
    assert cm.statut_global(compteurs_ok(nb_images_manq=3, nb_erreurs=1), _sections()) == "ALERTE"


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
    assert len(cles) == 17 and len(set(cles)) == 17
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


# ------------------------------------------------------------------ jours sans intégration

def test_jours_feries_2026():
    from datetime import date
    f = cm.jours_feries(2026)
    assert date(2026, 4, 6) in f          # lundi de Pâques 2026
    assert date(2026, 5, 14) in f         # Ascension
    assert date(2026, 5, 25) in f         # lundi de Pentecôte
    assert {date(2026, 1, 1), date(2026, 5, 1), date(2026, 5, 8), date(2026, 7, 14),
            date(2026, 8, 15), date(2026, 11, 1), date(2026, 11, 11), date(2026, 12, 25)} <= f
    assert len(f) == 11


def test_jour_sans_integration():
    from datetime import date
    assert cm.jour_sans_integration(date(2026, 9, 19)) == "samedi"
    assert cm.jour_sans_integration(date(2026, 9, 20)) == "dimanche"
    assert cm.jour_sans_integration(date(2026, 7, 14)) == "jour férié"
    assert cm.jour_sans_integration(date(2026, 9, 18)) is None


def test_statuts_volumes_na_quand_pas_d_integration():
    s = cm.statuts(compteurs_ok(nb_flux_dsp=0, nb_ndf=0, nb_rb_imports=0), volumes_controles=False)
    assert set(s.values()) == {"N/A"}


def test_statut_global_ignore_les_volumes_sans_integration():
    c = compteurs_ok(nb_flux_dsp=0, nb_ndf=0, nb_fac_xerox=0, nb_fac_tradeshift=0, nb_gl_interface=0,
                     nb_gl_lignes=0, nb_rb_imports=0)
    assert cm.statut_global(c, _sections()) == "WARNING"
    assert cm.statut_global(c, _sections(), volumes_controles=False) == "OK"
    assert cm.statut_global(compteurs_ok(nb_erreurs=1), _sections(), volumes_controles=False) == "ALERTE"
    assert cm.statut_global(compteurs_ok(nb_warnings=1), _sections(), volumes_controles=False) == "WARNING"


# ------------------------------------------------------------------ programmes génériques (lanceur)

def test_requetes_nuit_excluent_les_programmes_generiques():
    for cle, _t, sql, _a in cm.CATALOGUE:
        if cle.startswith("nuit_"):
            assert ":generiques" in sql, cle
    for cles, sql in cm.SYNTHESE:
        if "nb_traitements" in cles:
            assert ":generiques" in sql
    assert cm.regex_generiques(["DKA_SLAUNCHER", "XX_LANCEUR"]) == "^(DKA_SLAUNCHER|XX_LANCEUR)$"
    assert cm.regex_generiques([]) == "^$"


# --- Factures AR (DKA_IARPAFAC_INTERFACE -> AutoInvoice) ---------------------
def test_factures_ar_recues_est_un_volume():
    assert cm.statuts(compteurs_ok(nb_fac_ar=0))["nb_fac_ar"] == "W"
    assert cm.statuts(compteurs_ok(nb_fac_ar=15))["nb_fac_ar"] == "OK"
    assert cm.statuts(compteurs_ok(), volumes_controles=False)["nb_fac_ar"] == "N/A"


def test_factures_ar_rejetees_donne_alerte():
    assert cm.statut_global(compteurs_ok(nb_fac_ar_rejet=2), _sections()) == "ALERTE"
    assert cm.statut_global(compteurs_ok(nb_fac_ar_rejet=0), _sections()) == "OK"


def test_catalogue_et_synthese_factures_ar():
    cles = [c for c, *_ in cm.CATALOGUE]
    assert "fac_ar" in cles and "fac_ar_rejets" in cles
    sql_rejets = next(sql for c, _t, sql, _a in cm.CATALOGUE if c == "fac_ar_rejets")
    assert "ra_interface_lines_all" in sql_rejets and "trx_number" in sql_rejets and "invoice_number" in sql_rejets
    assert next(a for c, _t, _s, a in cm.CATALOGUE if c == "fac_ar_rejets") is True   # lignes = alerte
    cles_synthese = [k for cles_, _ in cm.SYNTHESE for k in cles_]
    assert "nb_fac_ar" in cles_synthese and "nb_fac_ar_rejet" in cles_synthese
    for _cles, sql in cm.SYNTHESE:
        sql.format(s="APPS.")            # aucune accolade résiduelle (cf. régression HORS_GENERIQUES)


def _sql(cle: str) -> str:
    """Requête du catalogue par sa clé (sections) ou par un compteur."""
    for c, _titre, sql, _large in cm.CATALOGUE:
        if c == cle:
            return sql
    for cles, sql in cm.SYNTHESE:
        if cle in cles:
            return sql
    raise KeyError(cle)


def test_warnings_excluent_les_fins_annoncees_normales():
    # une demande en G dont le texte de fin dit « Request Completed Normal » (cas 49094445, Create
    # Accounting) n'est pas un avertissement d'exploitation : ni comptée, ni listée.
    for cle in ("nuit_warnings", "nb_warnings"):
        sql = _sql(cle).upper()
        assert "'REQUEST COMPLETED NORMAL', 'FIN NORMALE'" in sql, cle
        assert "NOT IN" in sql and "NVL(FCR.COMPLETION_TEXT, '-')" in sql, cle


def test_texte_de_fin_vide_reste_un_warning():
    # NVL avant le NOT IN : sans lui, un completion_text NULL rendrait la comparaison NULL et la
    # demande disparaîtrait, alors qu'un texte vide n'annonce pas une fin normale.
    assert "NVL(fcr.completion_text, '-')" in _sql("nuit_warnings")
    assert "NVL(fcr.completion_text, '-')" in _sql("nb_warnings")


def test_erreurs_et_synthese_ne_sont_pas_filtrees():
    # le filtre ne touche que les warnings : erreurs et synthèse par statut restent le reflet d'Oracle
    for cle in ("nuit_err_detail", "nuit_err_prog", "nuit_synthese"):
        assert "FIN NORMALE" not in _sql(cle).upper(), cle
    # le compteur d'erreurs partage la requête des warnings : sa branche 'E' ne regarde pas le texte de fin
    assert "CASE WHEN fcr.status_code = 'E' THEN 1 ELSE 0 END" in _sql("nb_erreurs")
