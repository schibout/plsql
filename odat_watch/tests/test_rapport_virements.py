"""Rapport HTML Virements : synthèse en haut, tableaux de détail en bas ; texte court pour le mail."""
import rapport_virements as rp
import virements as vr
from test_virements_base import rapport_factice


def _rapport(tmp_path, ok=True):
    return vr.lire_rapport(rapport_factice(tmp_path / "RAPPORTS" / "rapport_18092026", ok=ok), tmp_path / "REJETS")


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


def _rejets(tmp_path):
    import xlwt
    wb = xlwt.Workbook(); sh = wb.add_sheet("Feuil1")
    lignes = [["De: 17/09/2026 à 17/09/2026", "", "", "", "Tri par: Compte"],
              ["Devise de conversion", "", "", "", "Date du cours: 18/09/2026"],
              ["Banque", "Description du compte", "Référence de bout-en-bout", "Montant de saisie", "Devise de saisie",
               "Date de règlement", "Motif", "Description du motif", "Nom du tiers", "Identité bancaire du tiers"],
              ["BNP", "0001 - DALKIA - BNP", "1MAND0007349992MAN0000000DLS", 178.74, "EUR", 46168.0, "AC04",
               "Compte clôturé", "MECHIN ALEXIA", "FR7610278060370002080610144"],
              ["SOGE", "0001 - DALKIA - SG", "1VSEP162885DALKDAL4787720500", 1554.8, "EUR", 46154.0, "MS02",
               "Refus du débiteur", "VEOLIA EAU", "FR7630004008190001272767061"],
              ["", "", "", 1733.54, "EUR"]]
    for r, l in enumerate(lignes):
        for c, v in enumerate(l):
            sh.write(r, c, v)
    (tmp_path / "REJETS").mkdir()
    wb.save(str(tmp_path / "REJETS" / "18092026_Liste des rejets bancaires du jour - Virement.xls"))


def test_rejets_du_jour(tmp_path):
    import pytest
    pytest.importorskip("xlwt")
    _rejets(tmp_path)
    rapport = _rapport(tmp_path)
    assert list(rapport["rejets"]["reference"]) == ["1MAND0007349992MAN0000000DLS", "1VSEP162885DALKDAL4787720500"]
    assert list(rapport["rejets"]["date_operation"]) == ["26/05/2026", "12/05/2026"]
    r = vr.resume(rapport)
    assert r["nb_rejets"] == 2 and round(r["montant_rejets"], 2) == 1733.54
    html = rp.construire(rapport, "18092026")
    assert "Rejets bancaires du jour — 2 virement(s) pour 1 733,54 €" in html and "Compte clôturé" in html
    assert "2 virement(s) rejeté(s) par la banque pour 1 733,54 €" in rp.texte_court(rapport, "18092026")


def test_sans_rejets(tmp_path):
    rapport = _rapport(tmp_path)
    assert rapport["rejets"].empty and vr.resume(rapport)["nb_rejets"] == 0
    assert "Aucun rejet de virement" in rp.construire(rapport, "18092026")


def test_ecrire(tmp_path):
    chemin = rp.ecrire(_rapport(tmp_path), "18092026", tmp_path / "out")
    assert chemin.name.startswith("Virements_18092026_") and chemin.suffix == ".html"
