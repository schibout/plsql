"""Suivi de nuit : la dernière photo Control-M ne couvre qu'une odate ; il faut le dire quand la plage choisie n'est pas couverte."""
from datetime import date

import pandas as pd

import night_monitoring as nm


def _photo(odate):
    p = pd.DataFrame([{"job_name": "J1", "status": "Ended OK"}])
    p.attrs["odate"] = odate
    return p


def test_couverture_ok_quand_odate_de_la_photo_dans_le_plan():
    plan = pd.DataFrame({"job": ["J1", "J2"], "odate": [date(2026, 9, 20), date(2026, 9, 20)]})
    assert nm.couverture(plan, _photo("2026-09-20")) == (True, date(2026, 9, 20))


def test_couverture_absente_quand_plan_dans_le_futur():
    plan = pd.DataFrame({"job": ["J1"], "odate": [date(2026, 9, 21)]})
    assert nm.couverture(plan, _photo("2026-09-20")) == (False, date(2026, 9, 20))


def test_couverture_sans_photo():
    plan = pd.DataFrame({"job": ["J1"], "odate": [date(2026, 9, 21)]})
    assert nm.couverture(plan, None) == (False, None)
    assert nm.couverture(pd.DataFrame(), _photo("2026-09-20")) == (False, date(2026, 9, 20))
