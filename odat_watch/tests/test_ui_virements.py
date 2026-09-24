"""Onglet Virements via AppTest : lecture du rapport, tuiles, tables des doublons ; lancement sur le 18/09."""
from pathlib import Path

import pandas as pd
import pytest
from streamlit.testing.v1 import AppTest

import virements as vr

OUTIL = Path(__file__).resolve().parents[2] / "controleVirement"
RACINE = Path(__file__).resolve().parents[2] / "ODAT" / "Virements"
DATE = "18092026"


def _cfg(racine: Path) -> dict:
    return {"outil": OUTIL, "racine": racine, "depot": racine / "import_virement", "oracle": racine / "ORACLE",
            "edf": racine / "EDF", "rejets": racine / "REJETS", "rapports": racine / "RAPPORTS", "historique_jours": 7}


CFG = _cfg(RACINE)
pytestmark = pytest.mark.skipif(not (RACINE / "ORACLE" / DATE).is_dir(), reason="données ODAT/Virements absentes")


def test_dates_disponibles_les_plus_recentes_d_abord():
    dates = vr.dates_disponibles(CFG["oracle"])
    assert DATE in dates and dates == sorted(dates, key=lambda d: d[4:8] + d[2:4] + d[0:2], reverse=True)


def test_lancer_puis_lire_rapport():
    res = vr.lancer(DATE, CFG)
    assert res["ok"] is True and res["nb_instances"] == 2
    rapport = vr.lire_rapport(vr.dossier_rapport(CFG["rapports"], DATE), CFG["rejets"])
    assert rapport is not None and len(rapport["totaux_edf"]) == 46
    r = vr.resume(rapport)
    assert r["ok"] and r["nb_envoyes"] == 205 and round(r["montant_envoye"], 2) == 2667877.07
    assert r["ko"] == 0 and r["ecarts"] == 0 and r["quartz"]   # Quartz lu dans EDF
    assert vr.nb_instances(CFG["oracle"], DATE) == 2


def test_lire_rapport_absent(tmp_path):
    assert vr.lire_rapport(tmp_path / "RAPPORTS" / "rapport_x") is None


def test_resume_compte_ko_et_a_verifier():
    rapport = {c: pd.DataFrame() for c, _, _ in vr.CSV_RAPPORT}
    rapport["synthese"] = "..."
    rapport["doublons_ack"] = pd.DataFrame([{"fichier": "A"}])
    rapport["intra"] = pd.DataFrame([{"gravite": "A_VERIFIER"}, {"gravite": "KO"}])
    rapport["fichiers"] = pd.DataFrame([{"statut": "OK"}, {"statut": "MANQUANT"}, {"statut": "DOUBLON"}])
    r = vr.resume(rapport)
    assert (r["ko"], r["a_verifier"], r["ecarts"], r["ok"]) == (2, 1, 1, False)


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_virements

    def faux_kpi(col, valeur, libelle, ton=""):
        assert ton in {"ok", "warn", "err", "run", "neutral", ""}, ton
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_virements.render(faux_kpi)


def test_onglet_affiche_le_rapport(monkeypatch):
    vr.lancer(DATE, CFG)
    monkeypatch.setattr(vr, "config_virements", lambda: CFG)
    at = AppTest.from_function(_script, default_timeout=120)
    at.run()
    at.selectbox(key="vir_date").set_value(DATE).run()          # d'autres journées plus récentes peuvent exister
    assert not at.exception
    texte ="\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)
    assert "✅ OK résultat global [ok]" in texte and "205 virements envoyés" in texte
    assert "Rapport généré le" in texte
    # 18/09 : un seul point à vérifier (virement déjà payé le 15/09) → expander D5 ouvert, sinon message « Aucun doublon »
    labels = [e.label for e in at.expander]
    assert any("Déjà transmis un jour précédent" in l for l in labels) or any("Aucun doublon" in s.value for s in at.success)
    assert any("Contrôles de forme — 0 constat" in l for l in labels)


def test_dates_disponibles_accepte_les_deux_dispositions(tmp_path):
    for nom in ("18092026", "15092026_cible", "20260901"):
        (tmp_path / "ORACLE" / nom).mkdir(parents=True)
    (tmp_path / "RAPPORTS" / "rapport_18092026").mkdir(parents=True)
    assert vr.dates_disponibles(tmp_path / "ORACLE") == ["18092026", "15092026"]
    (tmp_path / "ORACLE" / "18092026" / "uuid1").mkdir()
    (tmp_path / "ORACLE" / "18092026" / "uuid2").mkdir()
    oracle = tmp_path / "ORACLE"
    assert vr.nb_instances(oracle, "18092026") == 2 and vr.nb_instances(oracle, "15092026") == 0


def test_bouton_import_range_les_instances(monkeypatch, tmp_path):
    """Le dépôt contient une instance datable : le bouton l'importe dans JJMMAAAA et l'onglet la propose."""
    import virements_import as vi
    from test_virements_import import _instance
    racine = tmp_path / "virements"
    _instance(racine / vi.DEPOT, "uuid-x", "20260918")
    cfg = _cfg(racine)
    monkeypatch.setattr(vr, "config_virements", lambda: cfg)
    import ui_virements
    monkeypatch.setattr(ui_virements, "connect", lambda: __import__("db").connect(tmp_path / "t.db"))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    assert any("Aucune journée" in c.value for c in at.caption)
    bouton = at.button(key="vir_import")
    assert "1 élément(s)" in bouton.label
    bouton.click().run()
    assert not at.exception
    assert (racine / "ORACLE" / "18092026" / "uuid-x").is_dir() and not (racine / vi.DEPOT / "uuid-x").exists()
    assert any("1 instance(s), 0 fichier(s) Quartz et 0 fichier(s) de rejets" in s.value for s in at.success)
    assert at.selectbox(key="vir_date").options == ["18/09/2026"]
