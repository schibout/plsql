"""Tâche planifiée Windows : construction de la commande et lecture de l'état, sans appeler schtasks."""
import subprocess

import pytest

import planif_matin as pm


def test_commande_create():
    cmd = pm.commande("07:15", python=r"C:\tmp\odatenv\Scripts\python.exe", script=r"C:\p\controle_matin.py")
    assert cmd[:2] == ["schtasks", "/Create"]
    assert cmd[cmd.index("/TN") + 1] == pm.NOM_TACHE
    assert cmd[cmd.index("/SC") + 1] == "DAILY"
    assert cmd[cmd.index("/ST") + 1] == "07:15"
    assert cmd[cmd.index("/TR") + 1] == r'"C:\tmp\odatenv\Scripts\python.exe" "C:\p\controle_matin.py" --rapport'
    assert "/F" in cmd


def test_commande_heure_invalide():
    with pytest.raises(ValueError):
        pm.commande("7h15")


CSV_FR = ('"Nom de l\'hôte","Nom de la tâche","Prochaine exécution","Statut","Mode d\'ouverture de session",'
          '"Dernière exécution","Dernier résultat","Auteur","Tâche à exécuter"\r\n'
          '"PC01","\\ODATWatch_ControleMatin","20/09/2026 07:15:00","Prêt","Interactif seulement",'
          '"19/09/2026 07:15:00","0","DALKIA\\samir","python controle_matin.py --rapport"\r\n')


def test_parse_etat_csv_par_position():
    e = pm._parse_etat(CSV_FR)
    assert e == {"prochaine": "20/09/2026 07:15:00", "statut": "Prêt",
                 "derniere": "19/09/2026 07:15:00", "dernier_resultat": "0"}


def test_etat_none_si_tache_absente(monkeypatch):
    def faux_run(*a, **k):
        return subprocess.CompletedProcess(a, 1, stdout="", stderr="ERREUR : le système ne trouve pas le fichier spécifié.")
    monkeypatch.setattr(subprocess, "run", faux_run)
    assert pm.etat() is None


def test_creer_leve_si_schtasks_echoue(monkeypatch):
    def faux_run(*a, **k):
        return subprocess.CompletedProcess(a, 1, stdout="", stderr="ERREUR : accès refusé.")
    monkeypatch.setattr(subprocess, "run", faux_run)
    with pytest.raises(RuntimeError, match="accès refusé"):
        pm.creer("07:15")
