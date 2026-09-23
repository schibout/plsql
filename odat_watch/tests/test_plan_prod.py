"""Plan de production : calendrier J-7 … J+16, lecture de la bible, grille et synthèse d'un mois."""
from datetime import date, datetime

import pandas as pd
import pytest

import db
import plan_prod as pp


def _cal(annee, mois):
    cal = pp.calendrier(annee, mois)
    return dict(zip(cal["date"], cal["label_j"])), cal


def test_calendrier_juin_2025_comme_la_bible():
    labels, cal = _cal(2025, 6)
    assert labels[date(2025, 6, 30)] == "J"
    assert labels[date(2025, 6, 20)] == "J-6" and labels[date(2025, 6, 19)] == "J-7"
    assert labels[date(2025, 7, 11)] == "J+9"
    assert labels[date(2025, 7, 14)] == ""                   # 14 juillet : pas de label
    assert labels[date(2025, 7, 15)] == "J+10"
    assert cal["date"].max() == date(2025, 7, 23) and labels[date(2025, 7, 23)] == "J+16"
    ctm = dict(zip(cal["label_j"], cal["label_ctm"]))
    assert ctm["J-6"] == "L7" and ctm["J"] == "L1" and ctm["J+1"] == "D1" and ctm["J+16"] == "D16"


def test_calendrier_mai_2025_saute_ascension_et_pentecote():
    labels, _ = _cal(2025, 5)
    assert labels[date(2025, 5, 30)] == "J"
    assert labels[date(2025, 5, 28)] == "J-1"
    assert labels[date(2025, 5, 29)] == ""                   # Ascension
    assert labels[date(2025, 6, 9)] == "" and labels[date(2025, 6, 10)] == "J+6"   # lundi de Pentecôte


def test_label_d_un_jour_quelconque_prefere_le_j_moins_du_mois():
    assert pp.label_jour(date(2026, 8, 31)) == "J"
    assert pp.label_jour(date(2026, 9, 1)) == "J+1"
    assert pp.label_jour(date(2026, 9, 21)) == "J-7"         # aussi J+15 d'août : on parle du mois qui vient
    assert pp.label_jour(date(2026, 9, 19)) == ""            # samedi


def test_lecture_des_planifications():
    assert pp.lire_planification("lun mar jeu") == ({0, 1, 3}, set())
    assert pp.lire_planification("J-2, J, D4, L3") == (set(), {"J-2", "J", "J+4"})


@pytest.fixture(scope="module")
def bible():
    return pp.lire_bible(pp.BIBLE.read_bytes()).set_index("code")


def test_bible_du_depot(bible):
    assert len(bible) == 137
    assert "FIN PDP" not in bible.index
    r = bible.loc["FINFIN_J23TRT_06_Q"]
    assert r["categorie"] == "Référentiel" and r["jours_reference"].startswith("J-6,sam,dim,J-5")
    assert r["planification"] == "lun mar mer jeu ven sam dim"
    assert bible.loc["FINEXT_J15GEN_06_Q", "categorie"] == "Supprimé"
    assert bible.loc["FINEXT_J15GEN_06_Q", "jours_reference"] == ""


def test_bible_la_regle_ecrite_prime_sur_les_cases(bible):
    assert bible.loc["FINFIN_C13TRT_04_M", "planification"] == "J"
    assert bible.loc["FINFIN_C1STRT_04_M", "planification"] == "J-5, J-4, J-3, J-2, J-1"   # « L6, L5, L4,L3, L2 »
    assert bible.loc["FINEXT_J12GEN_06_H", "planification"] == "J-3, J+6, J+12"            # « L4, D12, D6 »
    assert bible.loc["FINFIN_J11TRT_04_H", "planification"] == "sam"
    assert bible.loc["FINEXT_J21GEN_06_Q", "planification"] == "lun mar mer jeu ven"      # « sauf le we »
    assert "\n" not in bible.loc["FINFIN_C1ITRT_04_M", "description"]


def _runs(lignes):
    df = pd.DataFrame(lignes, columns=["group_name", "job_name", "odate", "status", "snap_time", "description"])
    df["snap_time"] = pd.to_datetime(df["snap_time"])
    return df


def test_grille_garde_le_dernier_etat_et_le_pire_job():
    cal = pp.calendrier(2026, 8)
    j = date(2026, 8, 31)
    df = _runs([
        ("CH", "CH_A", j, "Wait for Event", "2026-08-31 07:00", "a"),
        ("CH", "CH_A", j, "Ended OK", "2026-08-31 13:45", "a"),        # la photo de 13h45 l'emporte
        ("CH", "CH_B", j, "Ended Not OK", "2026-08-31 13:45", "b"),
    ])
    g = pp.grille(df, cal)
    assert g.to_dict("records") == [{"group_name": "CH", "odate": j, "nb_jobs": 2, "statut": "Ended Not OK"}]


def test_synthese_origines_ecarts_et_cellules():
    cal = pp.calendrier(2026, 8)
    j, j1, jm1 = date(2026, 8, 31), date(2026, 9, 1), date(2026, 8, 28)
    df = _runs([
        ("CLO", "CLO_1", j, "Ended OK", "2026-09-01 07:00", "Clôture"),
        ("CLO", "CLO_1", j1, "Ended OK", "2026-09-01 08:00", "Clôture"),
        ("NEW", "NEW_1", j, "Executing", "2026-09-01 07:00", "Nouvelle chaîne"),
        ("VIEILLE", "V_1", date(2026, 5, 4), "Ended OK", "2026-05-04 07:00", "x"),
        ("AUTRE", "A_1", jm1, "Ended OK", "2026-08-28 07:00", "x"),
    ])
    ref = pd.DataFrame([
        dict(code="CLO", description="Clôture AP", categorie="Clôture", planification="J-1, J", statut="bible"),
        dict(code="FANTOME", description="", categorie="Clôture", planification="J", statut="bible"),
        dict(code="VIEILLE", description="", categorie="Périodique", planification="J+2", statut="bible"),
    ])
    s = pp.synthese(df, cal, ref, {}).set_index("chaine")
    assert s.loc["CLO", "origine"] == "Référentiel"
    assert s.loc["CLO", "ecarts"] == "+J+1 −J-1"
    assert s.loc["CLO", "J 31/08"] == "✔ 1" and s.loc["CLO", "J+1 01/09"] == "✔ 1+"
    assert s.loc["CLO", "J-1 28/08"] == pp.NON_OBSERVE           # photo ce jour-là, chaîne absente
    assert s.loc["NEW", "origine"] == "Nouvelle" and s.loc["NEW", "description"] == "Nouvelle chaîne"
    assert s.loc["NEW", "J 31/08"] == "▶ 1"
    assert s.loc["FANTOME", "origine"] == "Jamais vue"
    assert s.loc["VIEILLE", "origine"] == "Plus vue depuis 04/05/2026"
    assert s.loc["VIEILLE", "J+2 02/09"] == pp.PREVU             # après la dernière photo


def test_planification_observee_quotidienne_et_mensuelle():
    jours = pd.bdate_range("2026-03-02", "2026-06-30").date
    lignes = [("QUOT", "Q_1", d, "Ended OK", f"{d} 08:00", "q") for d in jours]
    for a, m in ((2026, 3), (2026, 4), (2026, 5), (2026, 6)):
        lignes.append(("MENS", "M_1", pp.jour_j(a, m), "Ended OK", f"{pp.jour_j(a, m)} 08:00", "m"))
    obs = pp.planification_observee(_runs(lignes))
    assert obs["QUOT"] == "lun mar mer jeu ven"
    assert obs["MENS"] == "J"


def test_import_de_la_bible_garde_les_chaines_ajoutees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    pp.ajouter(con, pd.DataFrame([dict(chaine="FINFIN_J11TEC_04_FJA01_Q", description="Jalon",
                                       planification_observee="lun mar mer jeu ven")]))
    msg = pp.importer_bible(con, "Plan de Production.xlsx", pp.BIBLE.read_bytes())
    assert "137" in msg
    ref = pp.referentiel(con).set_index("code")
    assert len(ref) == 138
    assert ref.loc["FINFIN_J11TEC_04_FJA01_Q", "statut"] == "nouvelle"
    assert ref.loc["FINEXT_J15GEN_06_Q", "statut"] == "supprimee"
    ref.loc["FINFIN_C13TRT_04_M", "commentaire"] = "Clôture AP à surveiller"
    assert pp.enregistrer(con, ref.reset_index()) == 1
    assert pp.referentiel(con).set_index("code").loc["FINFIN_C13TRT_04_M", "maj_le"]
    pp.importer_bible(con, "Plan de Production.xlsx", pp.BIBLE.read_bytes())   # ré-import idempotent
    assert len(pp.referentiel(con)) == 138


def test_mois_disponibles_va_jusqu_au_mois_a_preparer():
    df = _runs([("CH", "CH_1", date(2026, 9, 21), "Ended OK", "2026-09-21 08:00", "x"),
                ("CH", "CH_1", date(2026, 8, 3), "Ended OK", "2026-08-03 08:00", "x")])
    mois = pp.mois_disponibles(df)
    assert mois[-1] == (2026, 10) and (2026, 9) in mois and (2026, 7) in mois


def test_synchronisation_odat_ajuste_le_plan(tmp_path):
    con = db.connect(tmp_path / "t.db")
    ref = pd.DataFrame([dict(chaine=c, description="", planification_observee=p) for c, p in (
        ("MENS", "J+2"),            # tourne en fait à J : planification réalignée
        ("MANU", "J+5"),            # planification saisie à la main : protégée
        ("DISPARUE", "J"),          # plus vue depuis longtemps : supprimée
        ("REVENUE", "J"))])         # supprimée puis revue : réactivée
    pp.ajouter(con, ref)
    con.execute("UPDATE pdp_chaines SET statut='supprimee' WHERE code='REVENUE'")
    con.commit()
    edite = pp.referentiel(con)
    edite.loc[edite["code"] == "MANU", "planification"] = "J+4"
    pp.enregistrer(con, edite)

    lignes = [("FOND", "F_1", d, "Ended OK", f"{d} 08:00", "f")            # une photo chaque jour
              for d in pd.date_range("2026-03-01", "2026-08-31").date]
    for a, m in ((2026, 5), (2026, 6), (2026, 7), (2026, 8)):
        j = pp.jour_j(a, m)
        lignes += [("MENS", "M_1", j, "Ended OK", f"{j} 08:00", "m"), ("MANU", "X_1", j, "Ended OK", f"{j} 08:00", "x")]
    lignes += [("DISPARUE", "D_1", date(2026, 3, 31), "Ended OK", "2026-03-31 08:00", "d"),
               ("REVENUE", "R_1", date(2026, 8, 31), "Ended OK", "2026-08-31 08:00", "r"),
               ("NEUVE", "N_1", date(2026, 8, 31), "Ended OK", "2026-08-31 08:00", "Chaîne neuve")]
    journal = pp.synchroniser(con, _runs(lignes))

    changements = {(r.code, r.changement) for r in journal.itertuples()}
    assert changements == {("MENS", "planification"), ("DISPARUE", "supprimée"), ("REVENUE", "réactivée"),
                           ("NEUVE", "ajoutée"), ("FOND", "ajoutée")}
    fin = pp.referentiel(con).set_index("code")
    assert fin.loc["MENS", "planification"] == "J" and fin.loc["MANU", "planification"] == "J+4"
    assert fin.loc["DISPARUE", "statut"] == "supprimee" and fin.loc["REVENUE", "statut"] == "nouvelle"
    assert fin.loc["NEUVE", "description"] == "Chaîne neuve"
    assert pp.derniere_synchro(con)
    assert pp.synchroniser(con, _runs(lignes)).empty           # une seconde synchro ne change plus rien


def test_planification_observee_hebdo_n_est_pas_prise_pour_des_j():
    vendredis = pd.date_range("2026-03-06", "2026-08-28", freq="W-FRI").date
    obs = pp.planification_observee(_runs([("HEBDO", "H_1", d, "Ended OK", f"{d} 08:00", "h") for d in vendredis]))
    assert obs["HEBDO"] == "ven"
