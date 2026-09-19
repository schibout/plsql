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

    def execute(self, sql, binds=None):
        self.appels.append((sql, dict(binds or {})))
        if "FROM dual" in sql:
            self._rows = [(self.sysdate,)]
        else:
            self._rows = []

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return self._rows


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
    assert b["depuis"] == sysdate - timedelta(days=90)
    con = db.connect(base)
    assert orf.borne_chargement("demandes", con) == sysdate
    con.close()

    cur.appels.clear()
    msg = orf.refresh_requests()
    assert "delta" in msg and "20/09 08:00" in msg
    b = _requetes_binds(cur)[0]
    assert b["depuis"] == sysdate - timedelta(hours=1)          # marge de sécurité d'une heure


def test_sql_delta_utilise_last_update_date():
    assert "last_update_date >= :depuis" in orf.SQL_REQUESTS
    assert ":heures" not in orf.SQL_REQUESTS
    assert "phase_code IN ('P', 'R')" in orf.SQL_REQUESTS


def test_option_complet_et_jours(env):
    cur, base, sysdate = env
    orf.refresh_requests()
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
