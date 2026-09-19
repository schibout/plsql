from datetime import datetime

import pandas as pd

import assistant_nuit
import business_calendar
import calendar_import
import db
import forecast
import night_monitoring


def preview(prefix: str = "A"):
    months = {}
    for i, period in enumerate(("2026-01", "2026-02", "2026-03"), 1):
        months[period] = [calendar_import.CalendarEvent(
            period, "2026-01-30", f"2026-0{i}-20", "J-5", "Nuit",
            f"{prefix} arrêté", f"{prefix} traitement", None, "JANVIER 2026", i + 2)]
    return calendar_import.WorkbookPreview(months, ["Feuil1"], [])


def test_import_calendar_is_atomic_and_versioned(tmp_path):
    con = db.connect(tmp_path / "calendar.db")
    first = preview("A")
    import_id, message = calendar_import.import_workbook(con, "T1.xlsx", b"first", first)
    assert import_id and "3 opération" in message
    assert con.execute("SELECT COUNT(*) FROM calendar_events").fetchone()[0] == 3
    assert calendar_import.import_workbook(con, "T1.xlsx", b"first", first)[0] is None

    second = preview("B")
    calendar_import.import_workbook(con, "T1-corrige.xlsx", b"second", second)
    statuses = [r[0] for r in con.execute("SELECT statut FROM calendar_imports ORDER BY id")]
    assert statuses == ["inactive", "active"]
    found = business_calendar.active_events(con, "2026-01-20", "2026-01-20")
    assert len(found) == 1 and found.iloc[0]["arrete"] == "B arrêté"


def test_assistant_and_monitoring_ne_declarent_pas_un_job_absent_en_erreur():
    plan = pd.DataFrame([{
        "heure_prevue": pd.Timestamp("2026-01-20 20:00"), "job": "JOB_A", "description": "test",
        "statut": "à venir", "duree_min": 10.0, "fiabilite": 95.0, "nb_obs": 12,
        "confiance": "Moyenne", "groupe": "G", "fin_prevue": pd.Timestamp("2026-01-20 20:10"),
    }])
    monitored = night_monitoring.suivi(plan, None, datetime(2026, 1, 20, 22, 0))
    assert monitored.iloc[0]["suivi"] == "Non observé — à vérifier"
    response, selected = assistant_nuit.repondre("quels sont les plus longs ?", plan, "Nuit ordinaire", datetime(2026, 1, 20, 19), datetime(2026, 1, 21, 7))
    assert "durées" in response and len(selected) == 1


def test_prevision_conserve_un_job_qui_chevauche_le_debut_de_plage():
    profile = forecast.Profil("JOB_NUIT", "", "G", "", 10, 10,
                              jours_semaine={0}, heure_mediane=datetime.strptime("18:50", "%H:%M").time(),
                              duree_mediane=30, frequence="Quotidien")
    result = forecast.prevision({profile.job_name: profile}, datetime(2026, 1, 5, 19), datetime(2026, 1, 5, 20))
    assert len(result) == 1
