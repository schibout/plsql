"""Cas reel du 15/09/2026 : 15 ACK de l'instance 0ab9fb01... envoyes deux fois a la banque."""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from controle_virements import main, collecter_instance
from cv.discovery import discover_instances

RACINE = Path(__file__).resolve().parents[1]
DATE = "15092026"
GUID = "0ab9fb010eba4d98a464464d897f9608"

pytestmark = pytest.mark.skipif(not (RACINE / f"{DATE}_cible" / GUID).is_dir(),
                                reason=f"donnees {DATE} absentes")


def _instance():
    return next(i for i in discover_instances(RACINE, DATE) if i.guid == GUID)


def test_les_ack_orphelins_sont_qualifies_en_doublon():
    fichiers, *_ , acks = collecter_instance(_instance())
    from cv.reconcile import controle_doublons_ack
    doublons = controle_doublons_ack(acks)
    assert len(doublons) == 15
    assert sum(d["nb_virements"] for d in doublons) == 869
    assert sum(d["montant_cts"] for d in doublons) == 17817209


def test_les_ack_orphelins_comptent_dans_les_virements_envoyes():
    *_, cible_virements, acks = collecter_instance(_instance())
    # 30 ACK dans TARGET, tous reellement transmis a la banque
    assert len(acks) == 30
    assert len(cible_virements) == sum(len(a.virements) for _, _, a in acks)


def test_main_rapporte_les_doublons(tmp_path):
    code = main([DATE, "--racine", str(RACINE)])
    assert code == 1
    rapport = RACINE / f"rapport_{DATE}"
    synth = (rapport / "synthese.md").read_text(encoding="utf-8")
    assert "en double" in synth
    assert "178 172,09 EUR" in synth
    fichiers = (rapport / "controle_fichiers.csv").read_text(encoding="utf-8")
    assert fichiers.count(";DOUBLON;") == 15
    assert "ORPHELIN" not in fichiers
    # Le niveau 3 ne doit plus presenter les doublons comme "non envoyes"
    quartz = (rapport / "controle_quartz_ecarts.csv").read_text(encoding="utf-8")
    assert "ABSENT_CIBLE" not in quartz
