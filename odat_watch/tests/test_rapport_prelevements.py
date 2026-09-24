"""Rapport HTML Prélèvements : pur, construit depuis un rapport relu par prelevements.lire_rapport."""
from datetime import date

import prelevements as pv
import rapport_prelevements as rp
from test_prelevements import _rapport


def _charger(tmp_path, **kw):
    _rapport(tmp_path / "RAPPORTS", "Rapprochement_Cle_Metier_20260914_081400", **kw)
    return pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14))


def test_synthese_en_haut_puis_tableaux(tmp_path):
    html = rp.construire(_charger(tmp_path))
    assert html.startswith("<!DOCTYPE html>")
    assert "Prélèvements Oracle ↔ EDF" in html and "14/09/2026" in html
    # ordre : bandeau, tuiles, synthèse par statut, à faire, puis les tableaux de détail
    i_bandeau, i_synth = html.index('class="bandeau'), html.index("Synthèse par statut")
    i_afaire, i_detail = html.index("À faire aujourd'hui"), html.index("Détail — Justification des écarts")
    assert i_bandeau < i_synth < i_afaire < i_detail
    assert "592" in html and "2 780 519,23 €" in html          # émis / montant
    assert "En attente EDF" in html and "Rapproché" in html
    assert "relancer le contrôle après le prochain état EDF" in html.lower() or "prochain état EDF" in html
    assert "FR76A" in html and "DKA-20260910-1_PCLFRST.txt" in html   # détail présent


def test_bandeau_selon_statut(tmp_path):
    ok = rp.construire(_charger(tmp_path))
    assert 'class="bandeau ok"' in ok and "Statut global : OK" in ok
    deg = rp.construire(_charger(tmp_path, statut_global="DEGRADE", avertissements=["Aucun fichier EDF depuis 2026-09-11"]))
    assert 'class="bandeau warn"' in deg and "Aucun fichier EDF depuis 2026-09-11" in deg
    ano = rp.construire(_charger(tmp_path, statut_global="ANOMALIES"))
    assert 'class="bandeau ko"' in ano


def test_a_faire_liste_doublons_et_ecarts(tmp_path):
    r = _charger(tmp_path, statut_global="ANOMALIES",
                 doublons="DOUBLON;P1;RUM1;FR76A;FR76D;CLIENT X;30/09/2026;100.00;2;f1 + f2;11/09/2026 + 12/09/2026\n")
    html = rp.construire(r)
    afaire = html[html.index("À faire aujourd'hui"):html.index("Détail — Justification des écarts")]
    assert "CLIENT X" in afaire and "émise 2 fois" in afaire
    assert "INEXPLIQUE" in afaire or "inexpliqué" in afaire.lower()
    assert "Détail — Doublons" in html


def test_ecrire_nomme_le_fichier_par_date_de_reference(tmp_path):
    chemin = rp.ecrire(_charger(tmp_path), tmp_path / "out")
    assert chemin.name.startswith("Prelevements_20260914_") and chemin.suffix == ".html"
    assert chemin.read_text(encoding="utf-8").startswith("<!DOCTYPE html>")


def test_texte_court_pour_mail(tmp_path):
    txt = rp.texte_court(_charger(tmp_path))
    assert txt.splitlines()[0].startswith("Prélèvements Oracle ↔ EDF au 14/09/2026 : OK")
    assert "592 prélèvements émis" in txt and "1 clé(s) en attente EDF" in txt
