"""Chargement Oracle : complet la première fois, puis seulement le delta depuis le dernier chargement."""
import configparser
from datetime import datetime, timedelta

import pytest

import db
import oracle_refresh as orf


class _Curseur:
    def __init__(self, sysdate):
        self.sysdate = sysdate
        self.appels = []
        self.arraysize = 100
        self._rows = []
        self.demandes = []

    def execute(self, sql, binds=None):
        self.appels.append((sql, dict(binds or {})))
        if "FROM dual" in sql:
            self._rows = [(self.sysdate,)]
        elif "fnd_concurrent_requests fcr" in sql:
            self._rows = list(self.demandes)
        else:
            self._rows = []

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return self._rows

    def fetchmany(self, n):
        out, self._rows = self._rows[:n], self._rows[n:]
        return out


class _Con:
    def __init__(self, cur): self.cur = cur
    def cursor(self): return self.cur
    def __enter__(self): return self
    def __exit__(self, *a): return False


@pytest.fixture
def env(tmp_path, monkeypatch):
    base = tmp_path / "t.db"
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.read_dict({"database": {"user": "u", "password": "p", "dsn": "d", "schema": "APPS"},
                   "oracle": {"heures_historique": "48", "jours_initial": "90", "filtre_description": "FIN%"}})
    sysdate = datetime(2026, 9, 20, 8, 0, 0)
    cur = _Curseur(sysdate)
    monkeypatch.setattr(orf, "load_config", lambda: cfg)
    monkeypatch.setattr(orf, "_connect_oracle", lambda c: _Con(cur))
    monkeypatch.setattr(orf, "connect", lambda: db.connect(base))
    return cur, base, sysdate


def _requetes_binds(cur):
    return [b for sql, b in cur.appels if "fnd_concurrent_requests fcr" in sql]


def test_premier_chargement_complet_puis_delta(env):
    cur, base, sysdate = env
    msg = orf.refresh_requests()
    assert "initial" in msg and "90 j" in msg
    b = _requetes_binds(cur)[0]
    assert b["depuis"] == sysdate - timedelta(days=90) and b["max_id"] == orf.AUCUN_ID
    con = db.connect(base)
    assert orf.borne_chargement("demandes", con) == sysdate
    con.execute("INSERT INTO ora_requests(request_id) VALUES (4242)"); con.commit()   # une demande déjà chargée
    con.close()

    cur.appels.clear()
    msg = orf.refresh_requests()
    assert "delta" in msg and "20/09 08:00" in msg and "request_id > 4242" in msg
    b = _requetes_binds(cur)[0]
    assert b["depuis"] == sysdate - timedelta(hours=1)          # marge de sécurité d'une heure
    assert b["max_id"] == 4242


def test_sql_delta_utilise_last_update_date():
    assert "last_update_date >= :depuis" in orf.SQL_REQUESTS and "request_id > :max_id" in orf.SQL_REQUESTS
    assert ":heures" not in orf.SQL_REQUESTS
    assert "phase_code IN ('P', 'R')" in orf.SQL_REQUESTS


def test_option_complet_et_jours(env):
    cur, base, sysdate = env
    orf.refresh_requests()
    con = db.connect(base); con.execute("INSERT INTO ora_requests(request_id) VALUES (1)"); con.commit(); con.close()
    cur.appels.clear()
    orf.refresh_requests(complet=True)
    assert _requetes_binds(cur)[0]["depuis"] == sysdate - timedelta(days=90)
    cur.appels.clear()
    orf.refresh_requests(heures=24)
    assert _requetes_binds(cur)[0]["depuis"] == sysdate - timedelta(hours=24)


def test_programmes_delta(env):
    cur, base, sysdate = env
    msg = orf.refresh_programs()
    assert "initial" in msg
    sql, b = [(s, b) for s, b in cur.appels if "fnd_concurrent_programs fcp" in s][0]
    assert b["depuis"] is None
    cur.appels.clear()
    msg = orf.refresh_programs()
    assert "delta" in msg
    sql, b = [(s, b) for s, b in cur.appels if "fnd_concurrent_programs fcp" in s][0]
    assert b["depuis"] == sysdate - timedelta(hours=1)
    assert "last_update_date >= :depuis" in sql


def test_delta_sans_demande_en_base_refait_l_initial(env):
    cur, base, sysdate = env
    orf.refresh_requests()          # borne posée mais 0 demande en base (curseur vide)
    cur.appels.clear()
    assert "initial" in orf.refresh_requests()


def _demande(rid, desc, parent=None, phase="C", statut="C"):
    return (rid, "PROG", "Programme", "DKA", phase, statut, "Terminé", "Normal", "2026-09-19 20:00:00",
            None, None, None, "EXP", "Resp", parent, None, None, "", desc, None, None, None)


def test_les_filles_heritent_du_job_du_lanceur_sur_plusieurs_lots(env, monkeypatch):
    cur, base, sysdate = env
    monkeypatch.setattr(orf, "LOT", 2)
    cur.demandes = [_demande(10, "FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh"),
                    _demande(11, "Programme maître", parent=10),
                    _demande(12, "Import factures", parent=10),          # 2e lot : parent connu via `connus`
                    _demande(13, "Autre chose sans job")]
    msg = orf.refresh_requests()
    assert msg.startswith("4 demandes")
    con = db.connect(base)
    jobs = dict(con.execute("SELECT request_id, job_name FROM ora_requests ORDER BY request_id").fetchall())
    assert jobs == {10: "FINFIN_J18TRT_04_IMP01_Q", 11: "FINFIN_J18TRT_04_IMP01_Q",
                    12: "FINFIN_J18TRT_04_IMP01_Q", 13: None}
    assert con.execute("SELECT program_short FROM job_mapping WHERE job_name='FINFIN_J18TRT_04_IMP01_Q'").fetchone()[0] == "PROG"
    con.close()
