"""Photos ODAT fusionnées : une ligne par exécution à son dernier état connu."""
import pandas as pd

import forecast as fc


def _photos(lignes):
    return pd.DataFrame(lignes, columns=["job_name", "odate", "order_id", "status", "start_time", "snap_time"])


def test_l_attente_disparait_quand_une_photo_suivante_montre_l_execution():
    d = fc.consolider(_photos([
        ("CLO", "2026-08-31", "3zd7b", "Wait for Event", None, "2026-08-31 13:46"),
        ("CLO", "2026-08-31", "3zd7b", "Wait for Event", None, "2026-08-31 16:46"),
        ("CLO", "2026-08-31", "3zd7b", "Ended OK", "2026-08-31 22:50", "2026-09-01 07:07"),
        ("CLO", "2026-08-31", "3zd7b", "Ended OK", "2026-08-31 22:50", "2026-09-01 08:07"),
        ("AUTRE", "2026-09-01", "x", "Ended OK", "2026-09-01 22:00", "2026-09-02 07:07"),
    ]))
    clo = d[d["job_name"] == "CLO"]
    assert len(clo) == 1 and clo.iloc[0]["status"] == "Ended OK" and clo.iloc[0]["snap_time"] == "2026-09-01 08:07"


def test_une_relance_garde_les_deux_tentatives():
    d = fc.consolider(_photos([
        ("J", "2026-08-31", "o1", "Ended Not OK", "2026-08-31 23:00", "2026-09-01 07:07"),
        ("J", "2026-08-31", "o1", "Ended OK", "2026-09-01 07:20", "2026-09-01 07:37"),
    ]))
    assert list(d["status"]) == ["Ended Not OK", "Ended OK"]


def test_attente_restee_a_la_derniere_photo_d_un_odate_clos_devient_non_lance():
    d = fc.consolider(_photos([
        ("FLUX_B", "2026-09-20", "a", "Wait for Event", None, "2026-09-21 08:07"),
        ("FLUX_B", "2026-09-21", "b", "Wait for Event", None, "2026-09-21 16:46"),   # odate du jour : encore attendu
    ])).set_index("odate")
    assert d.loc["2026-09-20", "status"] == fc.NON_LANCE
    assert d.loc["2026-09-21", "status"] == "Wait for Event"


def test_cyclique_entre_deux_cycles_sur_un_odate_clos_est_termine():
    d = _photos([
        ("CYC", "2026-01-26", "c", "Wait for Event", "2026-01-26 18:45", "2026-01-27 08:07"),
        ("AUTRE", "2026-01-27", "x", "Ended OK", "2026-01-27 22:00", "2026-01-28 07:07"),
    ]).assign(cyclic=["Yes", "No"], end_time=["2026-01-26 18:52", "2026-01-27 22:05"])
    assert fc.consolider(d).set_index("job_name").loc["CYC", "status"] == "Ended OK"
