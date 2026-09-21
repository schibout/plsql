"""Rapport HTML Virements : synthèse en haut, tableaux de détail en bas ; texte court pour le mail."""
import rapport_virements as rp
import virements as vr
from test_virements_base import rapport_factice


def _rapport(tmp_path, ok=True):
    return vr.lire_rapport(rapport_factice(tmp_path / "rapport_18092026", ok=ok))


def test_synthese_puis_details(tmp_path):
    html = rp.construire(_rapport(tmp_path), "18092026")
    assert html.startswith("<!DOCTYPE html>") and "journée du 18/09/2026" in html
    i_bandeau, i_synth = html.index('class="bandeau ok"'), html.index("<h2>Synthèse</h2>")
    i_dbl, i_forme, i_niv = html.index("Détail — Doublons"), html.index("Détail — Contrôles de forme"), html.index("Détail — Présence des fichiers")
    assert i_bandeau < i_synth < i_dbl < i_forme < i_niv
    assert "205" in html and "2 667 877,07 €" in html
    assert "<b>205 virements</b>" in html                     # markdown de la synthèse rendu
    assert "Aucun doublon" in html and "CDPG.NC4.IMPORT_ACK.A" in html


def test_bandeau_anomalies_et_doublons(tmp_path):
    html = rp.construire(_rapport(tmp_path, ok=False), "18092026")
    assert 'class="bandeau ko"' in html and "Résultat : Anomalies" in html
    assert "Envois transmis en double (D1)" in html and 'pill ko">1 famille(s)' in html


def test_texte_court(tmp_path):
    txt = rp.texte_court(_rapport(tmp_path, ok=False), "18092026")
    lignes = txt.splitlines()
    assert lignes[0] == "Contrôle des virements du 18/09/2026 : Anomalies"
    assert "205 virements transmis" in lignes[1]
    assert any("1 envoi(s) transmis en double" in l for l in lignes) and not any("Transmis à la banque" in l for l in lignes)


def test_ecrire(tmp_path):
    chemin = rp.ecrire(_rapport(tmp_path), "18092026", tmp_path / "out")
    assert chemin.name.startswith("Virements_18092026_") and chemin.suffix == ".html"
